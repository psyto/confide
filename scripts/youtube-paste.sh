#!/usr/bin/env bash
# Flatten _submission/youtube.md into the two fields YouTube asks for.
#
#   ./scripts/youtube-paste.sh          > _submission/youtube-paste.txt
#   ./scripts/youtube-paste.sh checkin1 > _submission/youtube-checkin1-paste.txt
#
# There used to be two hand-maintained copies of this description. They drifted, and the copy that
# was actually pasted kept a sentence saying seizure was unwritten for a day after it ran on devnet.
# One source now; this derives the other.
set -euo pipefail
cd "$(dirname "$0")/.."
case "${1:-main}" in
  main)     SRC=_submission/youtube.md ;;
  checkin1) SRC=_submission/youtube-checkin1.md ;;
  *)        echo "  unknown cut: $1 (have: checkin1)" >&2; exit 2 ;;
esac
SRC="$SRC" python3 - <<'PY'
import re
import os
s = open(os.environ["SRC"], encoding="utf-8").read()
blocks = re.findall(r'```\n(.*?)\n```', s, re.S)
title = min(blocks, key=len).strip()
desc = max(blocks, key=len).strip()
assert len(title) <= 100, f"title is {len(title)} characters, YouTube allows 100"
assert len(desc) <= 5000, f"description is {len(desc)} characters, YouTube allows 5000"
print("TITLE")
print("=====")
print(title)
print()
print()
print("DESCRIPTION")
print("===========")
print(desc)
PY
