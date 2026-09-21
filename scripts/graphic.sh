#!/usr/bin/env bash
# Make the CWF project graphic submission-ready, and show it at the size a card shows it.
#
#   ./scripts/graphic.sh
#
# SOURCE: web/confide-solana-dvp-graphic.png, commissioned by the founder 2026-09-21. The form
# stores at 0.5 MB and the original is 1.6 MB, so the compression is chosen here rather than left
# to whatever the form does to a gradient.
#
# WHY JPEG AND NOT A QUANTISED PNG. The light draft this replaced was flat enough to take 192
# colours cleanly. This one is a dark gradient, and quantising it -- even at 256 colours, even with
# Sierra dithering -- speckles the whole background; the crop at /tmp/graphic-card.png makes it
# obvious. JPEG at q2 is 123 KB against the PNG's 475 KB and has neither banding nor speckle. The
# format follows the image, not a preference.
#
# WHAT THIS REPLACED, THREE TIMES. A crop of web/poster.jpg -- a real frame of the delivered video,
# honest and unreadable, because at card size a panel of small terminal type is texture. Then a
# page built here: legible, and indistinguishable from any other RWA project. Then a light
# commissioned draft, whose only signal for CONFIDENTIAL was a purple ellipsis that read as
# "loading". This one puts an opaque lens in the middle of the exchange: you can see something is
# behind it and not what, which is the product.
#
# THE CHECK THAT MATTERS: render it at 360px and LOOK. A built version had the exchange mark as
# U+21C4 at 44px between two 72px figures; at card size it collapsed into a not-equals sign and the
# headline read "50,000 shares NOT $8,750,000" -- the opposite of the claim. Nothing but looking
# catches a mark that inverts when small, so this writes the small one every run.
set -euo pipefail
cd "$(dirname "$0")/.."
FF="${FFMPEG_PATH:-/opt/homebrew/bin/ffmpeg}"
SRC=web/confide-solana-dvp-graphic.png
OUT=_submission/graphic.jpg
CARD=/tmp/graphic-card.png
[ -f "$SRC" ] || { echo "  $SRC is missing" >&2; exit 1; }
"$FF" -loglevel error -y -i "$SRC" -vf scale=1024:1024 -q:v 2 "$OUT"
"$FF" -loglevel error -y -i "$OUT" -vf scale=360:-1 "$CARD"
bytes=$(wc -c < "$OUT" | tr -d ' ')
printf '  %s - %d KB (source %d KB), and %s at the size a card shows it\n' \
       "$OUT" "$((bytes / 1024))" "$(($(wc -c < "$SRC") / 1024))" "$CARD"
[ "$bytes" -le 512000 ] || { echo "  over the 0.5 MB the form stores" >&2; exit 1; }
