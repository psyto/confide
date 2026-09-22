#!/usr/bin/env bash
# YouTube chapter marks, derived from the delivered file's own scene boundaries.
#
#   ./scripts/video-chapters.sh video/Confide_Stocklana_20260920.mp4
#
# Not typed. The published Stocklana cut once carried chapter times belonging to a different edit
# — the description quoted a 2:07 runtime for a file that was 1:52 — because the numbers were
# copied from the recorder's plan rather than read off the thing that was uploaded. The voice
# paces differently from the silent master, so the plan is never the file.
#
# A scene boundary is a gap between subtitle cues: the narration falls silent between scenes and
# runs continuously within one.
set -euo pipefail
cd "$(dirname "$0")/.."
SRC="${1:-video/Confide_Stocklana_20260922.mp4}"
TITLES="${TITLES:-video/DELIVERED-20260922.md}"
# SRT= reads a CORRECTED track instead of the file's own. The embedded one is ASR, and scene titles
# are placed by matching a scene's opening words: "Salana already shipped" does not match "Solana
# already shipped", so the chapter for that scene could not be placed at all. The corrected track is
# what gets uploaded, so it is what the chapters should be read from.
if [ -n "${SRT:-}" ]; then cat "$SRT"; else
  "${FFMPEG_PATH:-/opt/homebrew/bin/ffmpeg}" -nostdin -v error -i "$SRC" -map 0:s:0 -f srt -
fi \
| TITLES="$TITLES" python3 -c "
import os, re, sys

srt = sys.stdin.read()
cues = re.findall(r'(\d\d:\d\d:\d\d,\d+) --> \d\d:\d\d:\d\d,\d+\n(.*?)(?=\n\n|\Z)', srt, re.S)
def sec(t):
    h, m, rest = t.split(':'); s, ms = rest.split(',')
    return int(h)*3600 + int(m)*60 + int(s) + int(ms)/1000
# The transcript writes spoken numbers as numerals -- the script says 'two thousand' and the track
# says '2,000' -- so numbers are dropped from both sides rather than reconciled. What is left is
# still enough to place a scene, and nothing here depends on the numbers matching.
NUMS = set('one two three four five six seven eight nine ten eleven twelve twenty thirty forty '
           'fifty sixty seventy eighty ninety hundred thousand million'.split())
def norm(t):
    words = re.sub(r'[^a-z0-9 ]', ' ', t.lower()).split()
    return ' '.join(w for w in words if w not in NUMS and not w.isdigit())

# Cue gaps do NOT find scene boundaries: the captioner splits on phrase length and runs straight
# through six of the nine changes. So each scene is located by its own opening words instead,
# which is the one thing the script and the track are guaranteed to share.
src = open(os.environ['TITLES'], encoding='utf-8').read()
scenes = re.findall(r'(?m)^### \d+ — ([^·\n]+?)\s*(?:·[^\n]*)?\$\n\n((?:^> ?.*\n)+)', src, re.M)
if not scenes:
    sys.stderr.write('  no scenes found in the script\n'); raise SystemExit(1)

joined = norm(' '.join(t for _, t in cues))
flat = [(sec(a), norm(t)) for a, t in cues]

out, searched_from = [], 0
for title, block in scenes:
    words = norm(re.sub(r'(?m)^> ?', '', block))[:0] or norm(re.sub(r'(?m)^> ?', '', block))
    key = ' '.join(words.split()[:4])
    # The window has to START with the key, not merely contain it. Containing it matched a window
    # whose first cue was still finishing the previous scene, and every chapter came out four or
    # five seconds early — early enough to look deliberate and be wrong.
    hit = None
    for i in range(searched_from, len(flat)):
        window = ' '.join(t for _, t in flat[i:i+4])
        if window.startswith(key):
            hit = i; break
    if hit is None:
        sys.stderr.write('  could not place scene %r by its opening words %r\n' % (title, key))
        raise SystemExit(1)
    out.append((flat[hit][0], title))
    searched_from = hit + 1

for t, n in out:
    print('%d:%02d %s' % (int(t)//60, int(t)%60, n[0].upper() + n[1:]))
"
