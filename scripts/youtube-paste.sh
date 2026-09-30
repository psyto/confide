#!/usr/bin/env bash
# Flatten _submission/youtube.md into the two fields YouTube asks for.
#
#   ./scripts/youtube-paste.sh --write             # -> _submission/youtube-paste.txt
#   ./scripts/youtube-paste.sh checkin1 --write    # -> _submission/youtube-checkin1-paste.txt
#   ./scripts/youtube-paste.sh [checkin1]          # print only
#
# --write, NOT `> file`. A shell redirect truncates the file before this runs, so when the 5,000-
# character assertion below fails the pasted file is left EMPTY. That happened on 2026-10-01 and was
# caught only by reading the byte count. --write prints to a temporary file, and replaces the real one
# only if this exited 0 with output.
#
# There used to be two hand-maintained copies of this description. They drifted, and the copy that
# was actually pasted kept a sentence saying seizure was unwritten for a day after it ran on devnet.
# One source now; this derives the other.
set -euo pipefail
cd "$(dirname "$0")/.."
if [ "${@: -1}" = "--write" ] 2>/dev/null; then
  set -- "${@:1:$(($# - 1))}"
  out=_submission/youtube-paste.txt
  [ "${1:-main}" = checkin1 ] && out=_submission/youtube-checkin1-paste.txt
  tmp=$(mktemp)
  if "$0" "$@" > "$tmp" && [ -s "$tmp" ]; then
    mv "$tmp" "$out"; echo "  wrote $out ($(wc -c < "$out" | tr -d ' ') bytes)" >&2
  else
    rm -f "$tmp"; echo "  NOT written: the generator failed or printed nothing; $out is unchanged" >&2; exit 1
  fi
  exit 0
fi
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
