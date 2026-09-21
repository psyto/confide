#!/usr/bin/env bash
# The post, with its two figures read rather than typed.
#
#   ./scripts/x-post.sh > docs/cwf-2026/x-post.txt   # the post in use
#   ./scripts/x-post.sh b                             # the alternative draft, to read and compare
#
# A draft is rendered through here rather than kept as a second finished file, so a rejected
# alternative cannot sit in the repository quoting a count from the week it was written -- which is
# the failure this script exists to prevent, arriving by the back door.
#
# The Stocklana short description sat in a submitted field saying "1,869 tokenized stocks" for days
# after a third issuer appeared, because it was typed once and nothing read it again. A post is
# worse: it cannot be edited after it goes out.
set -euo pipefail
cd "$(dirname "$0")/.."
case "${1:-}" in
  "")  TMPL=docs/cwf-2026/x-post.tmpl ;;
  b)   TMPL=docs/cwf-2026/x-post-b.tmpl ;;
  *)   echo "  unknown draft: $1 (have: b)" >&2; exit 2 ;;
esac
TMPL="$TMPL" python3 - <<'PY'
import json
mints = len(json.load(open("web/mints.json")))
acc = json.load(open("web/usage.json"))["total_accounts"]
conf = json.load(open("web/usage.json"))["total_confidential_accounts"]
assert conf == 0, "somebody has opened a confidential account — the post's first line is wrong"
import os
print(open(os.environ["TMPL"], encoding="utf-8").read()
      .replace("{MINTS}", f"{mints:,}").replace("{ACCOUNTS}", f"{acc:,}").rstrip())
PY
