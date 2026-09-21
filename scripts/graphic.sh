#!/usr/bin/env bash
# The project graphic the CWF form asks for, rendered from video/graphic.html.
#
#   ./scripts/graphic.sh
#
# WHY IT IS NOT A VIDEO FRAME ANY MORE. The first version cropped web/poster.jpg, a real frame of
# the delivered cut. Honest, and unreadable: the form shows this as a card among many projects, and
# at ~360px wide a 1920x640 panel of small type is texture. This page is built for that size --
# one trade, one sentence, four zeros.
#
# WHAT TO CHECK AFTER CHANGING IT. Render, downscale to 360px, and LOOK. The exchange mark was
# U+21C4 at 44px between two 72px figures; at card size it collapsed into a not-equals sign, so the
# headline read 50,000 shares NOT $8,750,000. Nothing but looking catches that.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT=_submission/graphic.jpg
node video/shot.mjs
"${FFMPEG_PATH:-/opt/homebrew/bin/ffmpeg}" -loglevel error -y -i /tmp/graphic.png -q:v 3 "$OUT"
"${FFMPEG_PATH:-/opt/homebrew/bin/ffmpeg}" -loglevel error -y -i "$OUT" -vf scale=360:-1 /tmp/graphic-card.png
bytes=$(wc -c < "$OUT" | tr -d ' ')
printf '  wrote %s \u2014 %d KB, and /tmp/graphic-card.png at the size a card shows it\n' "$OUT" "$((bytes / 1024))"
[ "$bytes" -le 512000 ] || { echo "  over the 0.5 MB the form stores" >&2; exit 1; }
