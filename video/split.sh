#!/usr/bin/env bash
# Cut confide.mp4 into one clip per narration block.
#
#   ./video/split.sh
#
# Boundaries come from the CONFIDE_SCENE lines the page logs during a recording, not from a guess,
# and are kept in segments/manifest.json. Frame-accurate re-encodes rather than `-c copy`, because
# a copy cut lands on the nearest keyframe and the first frames of a clip would belong to the one
# before it.
#
# Written 2026-09-15. The segments had been cut by hand until then, which is why re-rendering the
# video after the account changed did not obviously imply re-cutting them.
set -euo pipefail
cd "$(dirname "$0")/.."
FF="${FFMPEG_PATH:-/opt/homebrew/bin/ffmpeg}"
PROBE="${FFPROBE_PATH:-/opt/homebrew/bin/ffprobe}"
SRC=video/confide.mp4
SEG=video/segments

[ -f "$SRC" ] || { echo "missing $SRC — run: cd video && npm run record" >&2; exit 1; }

python3 -c "import json;print('\n'.join(f\"{e['file']} {e['seconds']}\" for e in json.load(open('$SEG/manifest.json'))))" \
| { start=0
    while read -r name secs; do
      "$FF" -v error -ss "$start" -t "$secs" -i "$SRC" \
            -c:v libx264 -preset veryfast -crf 20 -pix_fmt yuv420p -movflags +faststart \
            -an "$SEG/$name" -y
      got=$("$PROBE" -v error -show_entries format=duration -of csv=p=0 "$SEG/$name")
      ok=$(python3 -c "print('ok' if abs($got-$secs)<0.05 else 'DRIFTED')")
      printf '  %-20s %6.2fs  %s\n' "$name" "$got" "$ok"
      start=$(python3 -c "print($start+$secs)")
    done
    echo
    echo "  narrated/ is not touched. Those clips carry the recorded voice over the PREVIOUS render;"
    echo "  re-run ./video/lift-narration.sh to put that voice back onto these." ; }
