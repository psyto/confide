#!/usr/bin/env bash
# Make the CWF project graphic submission-ready, and show it at the size a card shows it.
#
#   ./scripts/graphic.sh
#
# SOURCE: web/confide-dvp-public-graphic.png, commissioned by the founder 2026-09-21. The form
# stores at 0.5 MB and the original is 1.2 MB, so it is quantised rather than left for whatever
# the form's own compressor does to a gradient.
#
# WHAT THIS REPLACED, TWICE. First a crop of web/poster.jpg -- a real frame of the delivered video,
# honest and unreadable, because at card size a panel of small terminal type is texture. Then a
# page built here, readable but generic. The founder's is the one that is both legible and
# distinct at 360px.
#
# THE CHECK THAT MATTERS: render it at 360px and LOOK. A built version had the exchange mark as
# U+21C4 at 44px between two 72px figures; at card size it collapsed into a not-equals sign and the
# headline read "50,000 shares NOT $8,750,000" -- the opposite of the claim. Nothing but looking
# catches a mark that inverts when small, so this writes the small one every run.
set -euo pipefail
cd "$(dirname "$0")/.."
FF="${FFMPEG_PATH:-/opt/homebrew/bin/ffmpeg}"
SRC=web/confide-dvp-public-graphic.png
OUT=_submission/graphic.png
CARD=/tmp/graphic-card.png
[ -f "$SRC" ] || { echo "  $SRC is missing" >&2; exit 1; }
"$FF" -loglevel error -y -i "$SRC" -vf "scale=1024:1024,palettegen=max_colors=192" /tmp/graphic-pal.png
"$FF" -loglevel error -y -i "$SRC" -i /tmp/graphic-pal.png \
      -lavfi "scale=1024:1024[x];[x][1:v]paletteuse" "$OUT"
"$FF" -loglevel error -y -i "$OUT" -vf scale=360:-1 "$CARD"
bytes=$(wc -c < "$OUT" | tr -d ' ')
printf '  %s - %d KB (source %d KB), and %s at the size a card shows it\n' \
       "$OUT" "$((bytes / 1024))" "$(($(wc -c < "$SRC") / 1024))" "$CARD"
[ "$bytes" -le 512000 ] || { echo "  over the 0.5 MB the form stores" >&2; exit 1; }
