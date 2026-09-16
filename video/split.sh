#!/usr/bin/env bash
# Cut a recording into one clip per narration block.
#
#   ./video/split.sh            # confide.mp4      -> segments/
#   ./video/split.sh checkin    # checkin-1.mp4    -> segments-checkin/
#
# One splitter for both cuts rather than a copy per cut. The copy is what this file is guarding
# against everywhere else; it would be odd to make one here.
#
# Boundaries come from the CONFIDE_SCENE lines the page logs during a recording, not from a guess,
# and are kept in segments/manifest.json. Frame-accurate re-encodes rather than `-c copy`, because
# a copy cut lands on the nearest keyframe and the first frames of a clip would belong to the one
# before it.
set -euo pipefail
cd "$(dirname "$0")/.."
FF="${FFMPEG_PATH:-/opt/homebrew/bin/ffmpeg}"
PROBE="${FFPROBE_PATH:-/opt/homebrew/bin/ffprobe}"
case "${1:-main}" in
  main)    SRC=video/confide.mp4;   SEG=video/segments;          MAKE="cd video && npm run record";;
  checkin) SRC=video/checkin-1.mp4; SEG=video/segments-checkin;  MAKE="node video/record-checkin.js";;
  *) echo "usage: split.sh [main|checkin]" >&2; exit 2;;
esac

[ -f "$SRC" ] || { echo "missing $SRC — run: $MAKE" >&2; exit 1; }
[ -f "$SEG/manifest.json" ] || { echo "missing $SEG/manifest.json — run: $MAKE" >&2; exit 1; }

LIST=$(mktemp)
python3 -c "
import json
t=0.0
for e in json.load(open('$SEG/manifest.json')):
    print(e['file'], t, e['seconds']); t+=e['seconds']
" > "$LIST"

while read -r name start secs; do
  # -nostdin, or ffmpeg consumes the script's stdin and a filename can arrive with its leading
  # character missing. On 2026-09-15 that wrote 4-four-views.mp4 next to a stale 04-four-views.mp4,
  # so four clips kept the previous resolution, and the joined video went black wherever the
  # resolution changed. It is timing-dependent — the same script had run correctly an hour earlier.
  "$FF" -nostdin -v error -ss "$start" -t "$secs" -i "$SRC" \
        -c:v libx264 -preset veryfast -crf 20 -pix_fmt yuv420p -movflags +faststart \
        -an "$SEG/$name" -y
  got=$("$PROBE" -v error -show_entries format=duration -of csv=p=0 "$SEG/$name")
  ok=$(python3 -c "print('ok' if abs($got-$secs)<0.05 else 'DRIFTED')")
  printf '  %-20s %6.2fs  %s\n' "$name" "$got" "$ok"
done < "$LIST"
rm -f "$LIST"

# Every clip present, one resolution, nothing else in the directory. A mixed set still decodes in
# ffmpeg and still yields frames; it breaks in players, after upload, where nobody is looking.
SEG="$SEG" python3 - <<'PY' || exit 1
import json, os, subprocess
seg = os.environ['SEG']
want = {e['file'] for e in json.load(open(f'{seg}/manifest.json'))}
have = {f for f in os.listdir(seg) if f.endswith('.mp4')}
sizes = set()
for f in sorted(want & have):
    sizes.add(subprocess.run(['/opt/homebrew/bin/ffprobe','-v','error','-select_streams','v:0',
                              '-show_entries','stream=width,height','-of','csv=p=0',f'{seg}/{f}'],
                             capture_output=True, text=True).stdout.strip())
bad = []
if want - have: bad.append('missing: ' + ', '.join(sorted(want - have)))
if have - want: bad.append('unexpected: ' + ', '.join(sorted(have - want)))
if len(sizes) > 1: bad.append('mixed resolutions: ' + ', '.join(sorted(sizes)))
if bad:
    print('  split produced an inconsistent set:')
    for b in bad: print('   ', b)
    raise SystemExit(1)
print(f'  {len(want)} clips, all {sizes.pop()}')
PY

echo
if [ "$SEG" = video/segments-checkin ]; then
  python3 video/lines.py
fi

if [ "$SEG" = video/segments ]; then
  echo "  narrated/ is not touched. Those clips carry the recorded voice over the PREVIOUS render;"
  echo "  re-run ./video/lift-narration.sh to put that voice back onto these."
fi
