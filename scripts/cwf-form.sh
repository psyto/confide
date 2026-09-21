#!/usr/bin/env bash
# Count every CWF form field against the limit the form itself states.
#
#   ./scripts/cwf-form.sh
#
# The CWF form was found on 2026-09-21 still holding "All 1,869 tokenized stocks ... two issuers"
# in its PUBLIC brief description -- a count from before a third issuer existed, the same figure
# that rotted in Stocklana's short description. A form field is the one artifact this repository
# cannot read back, so what is checked is the file that gets pasted into it.
set -euo pipefail
cd "$(dirname "$0")/.."
python3 - <<'PY'
import json, re, sys, pathlib
t = pathlib.Path("_submission/cwf-form.md").read_text(encoding="utf-8")
secs = re.findall(r"^## (.+?)\n\n```\n(.*?)\n```", t, re.S | re.M)
if not secs:
    print("  no fields found — the file's shape changed"); sys.exit(1)
mints = "{:,}".format(len(json.load(open("web/mints.json"))))
u = json.load(open("web/usage.json"))
acc, conf = "{:,}".format(u["total_accounts"]), u["total_confidential_accounts"]
bad = []
G, R, OFF = "\033[32m", "\033[31m", "\033[0m"
for head, body in secs:
    name, b = head.split(" ·")[0], body.strip()
    m = re.search(r"≤(\d+)", head)
    if m and len(b) > int(m.group(1)):
        bad.append("%s is %d characters, the form allows %s" % (name, len(b), m.group(1)))
        print("  %s✗%s %-46s %5d / %s" % (R, OFF, name, len(b), m.group(1)))
    else:
        print("  %s✓%s %-46s %5d%s" % (G, OFF, name, len(b), " / " + m.group(1) if m else ""))
    # Only figures that could be a MISREAD of the two counts. A blanket "any big number" rule
    # flagged 50,000 shares and the year 2026 and would have taught this to be ignored. The real
    # failure was 1,869 sitting where 1,992 belongs -- a number in the right shape and wrong.
    for n in re.findall(r"(?<![\d,])(\d{1,3}(?:,\d{3})+)(?![\d,])", b):
        v = int(n.replace(",", ""))
        if 1000 <= v <= 9999 and n != mints:
            bad.append("%s says %s where the mint count is %s" % (name, n, mints))
        elif 100000 <= v <= 999999 and n != acc:
            bad.append("%s says %s where the account count is %s" % (name, n, acc))
if conf != 0:
    bad.append("a confidential account now exists; the brief description says zero")
print()
for b in bad:
    print("  " + b)
sys.exit(1 if bad else 0)
PY
