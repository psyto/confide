#!/usr/bin/env bash
# Correct the auto-generated caption track against the script, without touching the audio.
#
#   ./scripts/fix-captions.sh video/Confide_Stocklana_20260915.mp4 > video/captions.srt
#   ./scripts/fix-captions.sh video/Confide_CWF_Chech-in-1_20260921.mp4 > video/checkin-1-20260921.srt
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
    # 2026-09-21: the check-in's track heard one Solana transaction as one salon a transaction.
    # The rule above covers the ASR mishearing a single word; this is it splitting one into two.
    # Note the doubled backslashes -- this whole block lives inside python3 -c '' in a shell
    # double-quoted string, so a single backslash is eaten and an inner double quote ends the
    # string. Both mistakes were made adding this rule.
    (r'\\bsalon\\s+a\\s+transaction\\b', 'Solana transaction'),
    (r'\\bSalon\\s+a\\s+transaction\\b', 'Solana transaction'),
    # The check-in's transcript heard the protocol's name as a Spanish road. It is the subject of
    # the whole minute, so this is the one that matters most and the one nobody would query.
    (r'\\bCamino\\b', 'Kamino'),
    (r'\\bCaminos\\b', 'Kamino'),
    (r'zero\\s+knowledge', 'zero-knowledge'),
    (r'confidential(\\s+)transfer(\\s+)switched', r'confidential\\1transfers\\2switched'),
    (r'Nvidia', 'NVIDIA'),
    # 2026-09-20, from the presentation's own track. Each was read off the delivered file and
    # checked against video/CWF-PRESENTATION.md, which is what the voice was given.
    #
    # NOTE ON QUOTING: this whole block lives inside a double-quoted shell string, so a pattern
    # containing an apostrophe must use escaped double quotes. Writing it the obvious way ended
    # the shell string mid-rule and the file would not parse.
    (r'stable\s+coin', 'stablecoin'),
    # \"Everyone leaves the auditor key empty\" is a sentence about people. The line is about MINTS
    # -- every one of them -- and the transcript quietly changed the subject of the finding.
    (r'Everyone(\s+)leaves', r'Every one\1leaves'),
    # This phrase straddles a cue boundary -- \"and everyone\" ends one cue and \"needs the issuer\"
    # opens the next -- so a pattern spanning the two never matches: an SRT index and a timestamp
    # sit between them. Anchored to the end of a line instead, which is where it actually is.
    (r'(?m)and(\s+)everyone$', r'and\1every one'),
    (r'issuer(\s+)signature', r\"issuer's\1signature\"),
    (r'others(\s+)amount', r\"the other's\1amount\"),
    # The screen says 329,536 and the voice rounds, which is right for speech. A caption writing a
    # DIFFERENT numeral beside that screen reads as an error, so it spells the rounding out.
    (r'\b329,000\b', 'three hundred and twenty-nine thousand'),
]
for bad, good in fixes:
    s = re.sub(bad, good, s)
# The project's name, only where the transcript lowercased it at the start of a sentence.
s = re.sub(r'(?m)^(\s*)confide\b', r'\1Confide', s)
s = re.sub(r'(?<=[.!?] )confide\b', 'Confide', s)
# The ASR track separates words with two spaces. That is fine for a machine and wrong on a screen,
# so runs of spaces collapse to one -- AFTER every rule above, because those are written against
# the doubled form and match on \\s+ deliberately. Only spaces: timecode lines use single spaces
# around their arrow and cue separation is blank lines, so neither is touched.
s = re.sub(r'[ \\t]{2,}', ' ', s)
sys.stdout.write(s)
"
