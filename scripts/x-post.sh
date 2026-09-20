#!/usr/bin/env bash
# The post, with its two figures read rather than typed.
#
#   ./scripts/x-post.sh > docs/cwf-2026/x-post.txt
#
# The Stocklana short description sat in a submitted field saying "1,869 tokenized stocks" for days
# after a third issuer appeared, because it was typed once and nothing read it again. A post is
# worse: it cannot be edited after it goes out.
set -euo pipefail
cd "$(dirname "$0")/.."
python3 - <<'PY'
import json
mints = len(json.load(open("web/mints.json")))
acc = json.load(open("web/usage.json"))["total_accounts"]
conf = json.load(open("web/usage.json"))["total_confidential_accounts"]
assert conf == 0, "somebody has opened a confidential account — the post's first line is wrong"
print(open("docs/cwf-2026/x-post.tmpl", encoding="utf-8").read()
      .replace("{MINTS}", f"{mints:,}").replace("{ACCOUNTS}", f"{acc:,}").rstrip())
PY
