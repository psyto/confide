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
# `.` must not cross a newline in the HEADING. With re.S it did, so a section with no code block
# let its heading swallow the prose under it and claim the NEXT section's block -- the Telegram
# field reported 428/600, which was the judge-notes field, and the judge-notes field vanished from
# the listing entirely. A checker that silently stops counting a field is worse than none.
secs = re.findall(r"^## ([^\n]+)\n\n```\n(.*?)\n```", t, re.S | re.M)
# The count itself is checked. A field whose code fence is broken simply stops being listed, and a
# listing that is one row shorter reads exactly like a listing that is complete.
EXPECTED = 28   # 13 Project details, 8 Media and code, 7 Accelerator
if len(secs) != EXPECTED:
    print("  %d fields found, expected %d — a code fence is broken or a field was added"
          % (len(secs), EXPECTED))
    sys.exit(1)
mints = "{:,}".format(len(json.load(open("web/mints.json"))))
u = json.load(open("web/usage.json"))
acc, conf = "{:,}".format(u["total_accounts"]), u["total_confidential_accounts"]
appr = u["total_approved_accounts"]
bad = []
G, R, OFF = "\033[32m", "\033[31m", "\033[0m"
for head, body in secs:
    name, b = head.split(" ·")[0], body.strip()
    # "≤3 min" is a duration, not a character limit. Without the guard the demo video field was
    # reported as 66 characters against an allowance of 3.
    m = re.search(r"≤(\d+)(?!\s*min)", head)
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
# THE CLAIM MOVED FROM ONE COUNT TO THE NEXT. This fired whenever ANY account had configured a
# confidential account, on the assumption that the brief description would then be saying "zero"
# about the wrong thing. On 2026-09-22 two did, and the honest headline became "two configured,
# zero approved" -- so the guard now asks what the form actually says against both numbers, and
# only the approved count is allowed to be the zero.
#
# THE WORD WAS HARD-CODED. Written on the day the count was two, it accepted `two|<conf>` -- so it
# would have gone on passing a form that still said "two" forever, and on 2026-09-24, when a third
# account configured one on AAPLx, it REJECTED the corrected word "three". A check that passes the
# stale text and fails the current one is worse than no check. The accepted spellings are now
# derived from the count itself.
WORDS = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"]
def spellings(n):
    s = {str(n)}
    if n < len(WORDS):
        s.add(WORDS[n])
    return s
brief = next((b.strip() for h, b in secs if h.startswith("Brief description")), "")
if brief:
    if appr == 0 and not re.search(r"zero are approved|0 are approved|none (?:is|are) approved", brief, re.I):
        bad.append("no account is approved and the brief description does not say so")
    if conf and not re.search(r"\b(%s)\b[^.]{0,40}configured"
                              % "|".join(sorted(spellings(conf))), brief, re.I):
        bad.append("%d accounts have configured one; the brief description does not say how many" % conf)
    if appr != 0:
        bad.append("%d accounts are APPROVED — the gate has been opened, and every surface says it has not" % appr)
print()
for b in bad:
    print("  " + b)
sys.exit(1 if bad else 0)
PY
