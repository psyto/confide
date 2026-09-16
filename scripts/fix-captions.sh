#!/usr/bin/env bash
# Correct the auto-generated caption track against the script, without touching the audio.
#
#   ./scripts/fix-captions.sh video/Confide_Stocklana_20260915.mp4 > video/captions.srt
#   ./scripts/fix-captions.sh video/Confide_CWF_Checkin1_20260916.mp4 > video/checkin-1.srt
#
# The captions in the delivered file are ASR: they hear the voice and write what they heard. The
# voice is right and the transcript is not — "Salana" for Solana, lowercase "confide" for the
# project's own name. Cue timings come from the file and are left alone; only the words change.
# Upload the result to YouTube as the caption track, which overrides whatever it generated.
set -euo pipefail
cd "$(dirname "$0")/.."
SRC="${1:-video/Confide_Stocklana_20260915.mp4}"
"${FFMPEG_PATH:-/opt/homebrew/bin/ffmpeg}" -nostdin -v error -i "$SRC" -map 0:s:0 -f srt - \
| python3 -c "
import sys, re
s = sys.stdin.read()
# Ordered: longer phrases first so a shorter rule cannot eat part of one.
# The cue text separates words with two spaces, so match on \\s+ rather than a literal space —
# a single-space pattern silently misses half of these and reports success.
fixes = [
    (r'Salana', 'Solana'),
    # The check-in's transcript heard the protocol's name as a Spanish road. It is the subject of
    # the whole minute, so this is the one that matters most and the one nobody would query.
    (r'\\bCamino\\b', 'Kamino'),
    (r'\\bCaminos\\b', 'Kamino'),
    (r'zero\\s+knowledge', 'zero-knowledge'),
    (r'confidential(\\s+)transfer(\\s+)switched', r'confidential\\1transfers\\2switched'),
    (r'Nvidia', 'NVIDIA'),
]
for bad, good in fixes:
    s = re.sub(bad, good, s)
# The project's name, only where the transcript lowercased it at the start of a sentence.
s = re.sub(r'(?m)^(\s*)confide\b', r'\1Confide', s)
s = re.sub(r'(?<=[.!?] )confide\b', 'Confide', s)
sys.stdout.write(s)
"
