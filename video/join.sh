#!/usr/bin/env bash
# Reassemble the narrated segments into one file.
#
#   ./video/join.sh [outfile]
#
# Put your narrated versions in video/segments/narrated/ using the SAME filenames as
# video/segments/*.mp4. Anything missing falls back to the silent original, so you can record one
# segment at a time and rejoin after each.
set -euo pipefail
cd "$(dirname "$0")/.."
FF="${FFMPEG_PATH:-/opt/homebrew/bin/ffmpeg}"
OUT="${1:-video/confide-narrated.mp4}"
SEG=video/segments
NAR="$SEG/narrated"
list=$(mktemp); missing=0

for f in 01-title 02-leak 03-empty-slot 04-four-views 05-benefits 06-live-account 07-proofs 08-close; do
  if [ -f "$NAR/$f.mp4" ]; then src="$NAR/$f.mp4"; mark="narrated"
  else src="$SEG/$f.mp4"; mark="silent"; missing=$((missing+1)); fi
  printf '  %-18s %s\n' "$f" "$mark"
  # Every part needs an audio track or concat drops audio for the whole file; silent parts get one.
  if "${FFMPEG_PATH:-/opt/homebrew/bin/ffprobe}" >/dev/null 2>&1; then :; fi
  has_audio=$(/opt/homebrew/bin/ffprobe -v error -select_streams a -show_entries stream=index \
              -of csv=p=0 "$src" | wc -l | tr -d ' ')
  tmp="$SEG/.join-$f.mp4"
  if [ "$has_audio" = "0" ]; then
    "$FF" -v error -i "$src" -f lavfi -i anullsrc=r=48000:cl=stereo -shortest \
      -c:v copy -c:a aac -b:a 128k "$tmp" -y
  else
    "$FF" -v error -i "$src" -c:v copy -c:a aac -b:a 128k "$tmp" -y
  fi
  echo "file '$(cd "$(dirname "$tmp")" && pwd)/$(basename "$tmp")'" >> "$list"
done

"$FF" -v error -f concat -safe 0 -i "$list" -c copy -movflags +faststart "$OUT" -y
rm -f "$list" "$SEG"/.join-*.mp4

d=$(/opt/homebrew/bin/ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$OUT")
printf '\n  %s  %.1fs' "$OUT" "$d"
[ "$missing" -gt 0 ] && printf '  (%d segment(s) still silent)' "$missing"
printf '\n'
