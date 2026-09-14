#!/usr/bin/env bash
# Lift the reusable narration out of the 2026-09-13 narrated composite.
#
#   ./video/lift-narration.sh
#
# The recorded voice for seven of the eight scenes exists only inside
# video/Confide_Stocklana_20260913.mp4 - it was never kept as separate takes. Backpack Securities
# turned out to be a second issuer, so scene 03 was re-cut (16.60s -> 22.80s) and its line no longer
# matches; the other seven scenes are visually identical to the takes that voice was recorded
# against, so their audio still fits and only 03 needs re-recording.
#
# This cuts that composite at the OLD scene boundaries and muxes each piece onto the CURRENT silent
# clip, writing video/segments/narrated/. Every boundary was checked to fall inside a detected
# silence region with at least 0.36s of margin on both sides, so no word is cut.
#
# 03 is deliberately not produced. Record it, drop it in as 03-empty-slot.mp4, then ./video/join.sh.
set -euo pipefail
cd "$(dirname "$0")/.."
FF="${FFMPEG_PATH:-/opt/homebrew/bin/ffmpeg}"
PROBE="${FFPROBE_PATH:-/opt/homebrew/bin/ffprobe}"
SRC=video/Confide_Stocklana_20260913.mp4
SEG=video/segments
OUT="$SEG/narrated"

[ -f "$SRC" ] || { echo "missing $SRC - the recorded voice is only in there" >&2; exit 1; }
mkdir -p "$OUT"

# name                start-in-composite (old cut)
rows="01-title:0.00
02-leak:9.60
04-four-views:38.70
05-benefits:53.80
06-live-account:72.80
07-proofs:83.40
08-close:97.50"

fail=0
echo "$rows" | while IFS=: read -r name start; do
  vid="$SEG/$name.mp4"
  # Take exactly as much audio as the current clip is long. 07-proofs is 0.10s shorter after the
  # re-cut; that 0.10s is trailing silence, its line ends well before.
  len=$("$PROBE" -v error -show_entries format=duration -of csv=p=0 "$vid")
  "$FF" -v error -ss "$start" -t "$len" -i "$SRC" -i "$vid" \
        -map 1:v:0 -map 0:a:0 -c:v copy -c:a aac -b:a 192k -shortest "$OUT/$name.mp4" -y
  got=$("$PROBE" -v error -show_entries format=duration -of csv=p=0 "$OUT/$name.mp4")
  a=$("$PROBE" -v error -select_streams a -show_entries stream=codec_name -of csv=p=0 "$OUT/$name.mp4")
  # An output with no audio stream, or one that drifted from the clip, is a silent failure - the
  # kind that still plays and still looks finished.
  ok=$(python3 -c "print('ok' if abs($got-$len)<0.05 and '$a' else 'BAD')")
  printf '  %-18s %6.2fs  audio=%-5s %s\n' "$name" "$got" "${a:-none}" "$ok"
done

echo
echo "  03-empty-slot      not produced - its line changed, record it into $OUT/"
