#!/usr/bin/env bash
# The project graphic the CWF form asks for, cropped out of the video's own poster frame.
#
#   ./scripts/graphic.sh
#
# Generated rather than exported by hand, so it cannot drift from the cut it came from. The source
# is web/poster.jpg, which is itself a real frame of the delivered video rather than a mock — the
# same rule the video render follows.
#
# The crop exists because the frame is 16:9 with a quarter of its height empty top and bottom. On a
# project card that becomes letterboxing and unreadable text; cropped to the content band, the
# whole product reads at tile size: two parties, the two legs, nobody in the middle, and what the
# chain shows everyone else.
set -euo pipefail
cd "$(dirname "$0")/.."
SRC=web/poster.jpg
OUT=_submission/graphic.jpg
[ -f "$SRC" ] || { echo "  $SRC is missing — it is published by ./scripts/publish-site.sh" >&2; exit 1; }
ffmpeg -loglevel error -y -i "$SRC" -vf "crop=1920:640:0:230" -q:v 3 "$OUT"
bytes=$(wc -c < "$OUT" | tr -d ' ')
printf '  wrote %s — %d KB\n' "$OUT" "$((bytes / 1024))"
# The form stores at 0.5 MB and accepts 20 MB before compression. Only the stored figure can bite.
[ "$bytes" -le 512000 ] || { echo "  over the 0.5 MB the form stores" >&2; exit 1; }
