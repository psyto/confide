#!/usr/bin/env bash
# The GitHub About line, generated from the measurements rather than typed.
#
#   ./scripts/github-about.sh              # print it
#   ./scripts/github-about.sh --apply      # print it and set it on the repository
#
# It is the most-read sentence about this project -- the repository page, search results, every
# link preview -- and it sat outside every check in here, because no check reads GitHub. On
# 2026-09-23 it still said "Of 329,536 live accounts, zero are confidential": an account count from
# 17 September, two measurements stale, beside a claim that had been false since the 22nd. Both
# numbers now come off web/usage.json and web/slots.json, and docs-consistency.sh compares the
# live About against what this prints.
#
# GitHub allows 350 characters and silently truncates beyond it, so the length is asserted here
# rather than discovered by looking at the rendered page.
set -euo pipefail
cd "$(dirname "$0")/.."
REPO="${REPO:-psyto/confide}"

DESC=$(python3 - <<'PY'
import json
u = json.load(open("web/usage.json"))
s = json.load(open("web/slots.json"))
conf, appr = u["total_confidential_accounts"], u["total_approved_accounts"]
asked = f"{conf} have asked" if conf != 1 else "1 has asked"
# "0 is approved" is not English, and the day this reads "1 is approved" the sentence is wrong in a
# way no character count would catch -- so the approved clause is written from the number.
if appr == 0:
    through = "none is approved"
elif appr == 1:
    through = "one is approved"
else:
    through = f"{appr:,} are approved"
d = ("Confidential delivery-versus-payment for tokenized stocks on Solana: a stock-to-stablecoin "
     "swap in one transaction, with neither side publishing what moved. All {m:,} tokenized-equity "
     "mints ship it, auditor slot empty; of {a:,} live accounts {asked} for one "
     "and {through} — so the first trade is an issuance.").format(
        m=s["mints"], a=u["total_accounts"], asked=asked, through=through)
# 350 is GitHub's limit; the margin is deliberate. The first version came out at exactly 350 and
# would have failed the day any of these numbers gained a digit.
assert len(d) <= 335, f"the About line is {len(d)} characters; keep it under 335 of GitHub's 350"
print(d)
PY
)

printf '%s\n' "$DESC"

if [ "${1:-}" = "--apply" ]; then
  printf '\n  setting it on %s …\n' "$REPO" >&2
  gh repo edit "$REPO" --description "$DESC"
  printf '  done. %d characters.\n' "${#DESC}" >&2
fi
