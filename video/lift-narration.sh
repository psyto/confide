#!/usr/bin/env bash
# Put the recorded voice back onto freshly rendered clips.
#
#   ./video/lift-narration.sh [narrated-composite.mp4]
#
# The takes were never kept separately - the voice exists only inside a composite. Whenever the
# video is re-rendered (a new account, a corrected figure, a changed scene), the pictures move and
# that composite goes stale, but the narration usually does not. This cuts the composite at the
# scene boundaries in segments/manifest.json and muxes each piece onto the current clip.
#
# Every boundary is checked to land inside a detected silence before anything is written, so a cut
# cannot land mid-word. If one does not, this stops rather than producing eight clips that sound
# almost right.
set -euo pipefail
cd "$(dirname "$0")/.."
FF="${FFMPEG_PATH:-/opt/homebrew/bin/ffmpeg}"
PROBE="${FFPROBE_PATH:-/opt/homebrew/bin/ffprobe}"
SRC="${1:-video/Confide_Stocklana_20260914.mp4}"
SEG=video/segments
OUT="$SEG/narrated"

[ -f "$SRC" ] || { echo "missing $SRC - the recorded voice is only in there" >&2; exit 1; }
mkdir -p "$OUT"

# Refuse before writing, not after. A cut through a word is not visible in any duration check.
SRC="$SRC" python3 - <<'PY' || exit 1
import json, os, re, subprocess
src = os.environ['SRC']
out = subprocess.run(['/opt/homebrew/bin/ffmpeg','-hide_banner','-i',src,
                      '-af','silencedetect=noise=-40dB:d=0.2','-f','null','-'],
                     capture_output=True, text=True).stderr
ev = [(m.group(1), float(m.group(2))) for m in re.finditer(r'silence_(start|end): ([0-9.]+)', out)]
regions, cur = [], None
for k, v in ev:
    if k == 'start': cur = v
    elif cur is not None: regions.append((cur, v)); cur = None
dur = float(subprocess.run(['/opt/homebrew/bin/ffprobe','-v','error','-show_entries','format=duration',
                            '-of','csv=p=0',src], capture_output=True, text=True).stdout)
if cur is not None: regions.append((cur, dur))

man = json.load(open('video/segments/manifest.json'))
t, bad = 0.0, []
for e in man[:-1]:
    t += e['seconds']
    if not any(a <= t <= b for a, b in regions):
        bad.append(t)
if bad:
    print('  refusing: these boundaries fall mid-speech in %s' % src)
    for b in bad: print('    %.2fs' % b)
    print('  the composite does not match segments/manifest.json - re-record or re-cut')
    raise SystemExit(1)
print('  all %d boundaries land in silence' % (len(man) - 1))
PY

python3 -c "
import json
t=0.0
for e in json.load(open('$SEG/manifest.json')):
    print(e['file'], t); t+=e['seconds']
" | while read -r name start; do
  vid="$SEG/$name"
  len=$("$PROBE" -v error -show_entries format=duration -of csv=p=0 "$vid")
  "$FF" -v error -ss "$start" -t "$len" -i "$SRC" -i "$vid" \
        -map 1:v:0 -map 0:a:0 -c:v copy -c:a aac -b:a 192k -shortest "$OUT/$name" -y
  got=$("$PROBE" -v error -show_entries format=duration -of csv=p=0 "$OUT/$name")
  a=$("$PROBE" -v error -select_streams a -show_entries stream=codec_name -of csv=p=0 "$OUT/$name")
  ok=$(python3 -c "print('ok' if abs($got-$len)<0.05 and '$a' else 'BAD')")
  printf '  %-20s %6.2fs  audio=%-5s %s\n' "$name" "$got" "${a:-none}" "$ok"
done

echo
echo "  -> $OUT   then: ./video/join.sh"
