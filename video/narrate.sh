#!/usr/bin/env bash
# Put a recorded narration onto the current render, without cutting anything up.
#
#   ./video/narrate.sh [narrated-composite.mp4] [out.mp4]
#
# The recorded voice lives inside an older composite. Its audio is one continuous track on the same
# timeline as the render, so it can be muxed straight on: one video stream in, one out, no concat.
#
# That matters. Building the deliverable by cutting eight clips and concatenating them is how a
# video went black from 0:45 to 1:30 on 2026-09-15 — four clips had silently stayed at the previous
# resolution, and players stop decoding where the resolution changes while the audio plays on. ffmpeg
# still produced frames from it, so every automated check passed. This path cannot fail that way.
#
# split.sh / lift-narration.sh / join.sh still exist for working on one scene at a time.
set -euo pipefail
cd "$(dirname "$0")/.."
FF="${FFMPEG_PATH:-/opt/homebrew/bin/ffmpeg}"
PROBE="${FFPROBE_PATH:-/opt/homebrew/bin/ffprobe}"
VID=video/confide.mp4
SRC="${1:-video/Confide_Stocklana_20260914.mp4}"
OUT="${2:-video/confide-narrated.mp4}"

[ -f "$VID" ] || { echo "missing $VID — run: cd video && npm run record" >&2; exit 1; }
[ -f "$SRC" ] || { echo "missing $SRC — the recorded voice is only in there" >&2; exit 1; }

# The render logs its own scene boundaries; the narration was written to them. If the voice no
# longer falls silent at each one, the two are from different cuts and muxing would put the wrong
# line over the wrong picture — quietly, since nothing about the file would look wrong.
SRC="$SRC" python3 - <<'PY' || exit 1
import json, os, re, subprocess
src = os.environ['SRC']
out = subprocess.run(['/opt/homebrew/bin/ffmpeg','-nostdin','-hide_banner','-i',src,
                      '-af','silencedetect=noise=-40dB:d=0.2','-f','null','-'],
                     capture_output=True, text=True).stderr
ev = [(m.group(1), float(m.group(2))) for m in re.finditer(r'silence_(start|end): ([0-9.]+)', out)]
regions, cur = [], None
for k, v in ev:
    if k == 'start': cur = v
    elif cur is not None: regions.append((cur, v)); cur = None
man = json.load(open('video/segments/manifest.json'))
t, bad = 0.0, []
for e in man[:-1]:
    t += e['seconds']
    if not any(a <= t <= b for a, b in regions): bad.append(t)
if bad:
    print('  refusing: the narration does not fall silent at these scene boundaries:')
    for b in bad: print('    %.2fs' % b)
    raise SystemExit(1)
print('  narration lines up with all %d scene boundaries' % (len(man) - 1))
PY

# The recorder captures about a second past the last scene. Trimming to the scene total keeps the
# file from ending on a blank frame.
END=$(python3 -c "
import json
print(round(sum(e['seconds'] for e in json.load(open('video/segments/manifest.json'))) + 0.1, 2))")

SUBS=$(mktemp).srt
if "$PROBE" -v error -select_streams s -show_entries stream=index -of csv=p=0 "$SRC" | grep -q .; then
  "$FF" -nostdin -v error -y -i "$SRC" -map 0:s:0 "$SUBS"
  "$FF" -nostdin -v error -y -i "$VID" -i "$SRC" -i "$SUBS" \
        -map 0:v:0 -map 1:a:0 -map 2 -t "$END" \
        -c:v copy -c:a aac -b:a 192k -c:s mov_text -movflags +faststart "$OUT"
else
  "$FF" -nostdin -v error -y -i "$VID" -i "$SRC" \
        -map 0:v:0 -map 1:a:0 -t "$END" \
        -c:v copy -c:a aac -b:a 192k -movflags +faststart "$OUT"
fi
rm -f "$SUBS"

d=$("$PROBE" -v error -show_entries format=duration -of csv=p=0 "$OUT")
s=$("$PROBE" -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "$OUT")
printf '\n  %s  %.2fs  %s\n' "$OUT" "$d" "$s"
