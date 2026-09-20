#!/usr/bin/env bash
# Who, outside this repository, has actually looked at it.
#
#   ./scripts/reach.sh          # merge today's reading into web/reach.json
#   ./scripts/reach.sh --show   # print what has been recorded, and nothing else
#
# **This is distribution learning, not traction.** Nobody has used Confide for anything of their
# own. A visitor count is evidence that a link travelled; it is not evidence that anyone wanted
# what was at the end of it, and the submission says zero either way.
#
# WHY A SNAPSHOT AT ALL: GitHub keeps fourteen days of traffic and then drops it. A post that goes
# out on 09-20 and is read on 09-24 is invisible by 10-08, which is before judging. Recording it as
# it passes is the only way the number survives to be quoted — and quoting a number nobody can
# re-derive is the thing this repository refuses everywhere else, so what is quoted is a file with
# dates in it rather than a memory.
#
# WHAT THIS DOES NOT MEASURE: the decision page. `psyto.github.io` is static hosting with no server
# and no log we can read, so counting page views would mean sending every visitor to a third party.
# That is a decision the founder makes, not a default this script takes — see docs/cwf-2026/REACH.md.
set -euo pipefail
cd "$(dirname "$0")/.."
REPO="${REPO:-psyto/confide}"
OUT="${OUT:-web/reach.json}"

green=$'\033[32m'; red=$'\033[31m'; dim=$'\033[2m'; bold=$'\033[1m'; off=$'\033[0m'

show() {
  python3 - "$OUT" <<'PY'
import json, sys
try:
    d = json.load(open(sys.argv[1]))
except FileNotFoundError:
    print("  nothing recorded yet"); raise SystemExit(0)
days = d.get("days", {})
if not days:
    print("  nothing recorded yet"); raise SystemExit(0)
print("  %-12s %8s %8s %8s %8s" % ("date", "views", "unique", "clones", "cloners"))
for k in sorted(days):
    v = days[k]
    print("  %-12s %8d %8d %8d %8s" % (k, v.get("views", 0), v.get("uniques", 0),
          v.get("clones", 0), v.get("clone_uniques", "-")))
print()
# Views and clones are events and add up. Uniques are PEOPLE, and GitHub dedupes them only inside
# one fourteen-day window, so a sum across days counts a returning visitor once per day. It is an
# upper bound and is printed as one — the deduplicated figure for the last window follows.
print("  %-12s %8d %8s %8d %8s" % ("total",
      sum(v.get("views", 0) for v in days.values()),
      "\u2264%d" % sum(v.get("uniques", 0) for v in days.values()),
      sum(v.get("clones", 0) for v in days.values()),
      "\u2264%d" % sum(v.get("clone_uniques", 0) for v in days.values())))
for w in d.get("windows", [])[-1:]:
    print("  %-12s %8d %8d %8d %8d   deduplicated by GitHub, 14 days to that read"
          % ("window " + w["read"][5:], w["views"], w["view_uniques"],
             w["clones"], w["clone_uniques"]))
print("  first recorded %s, last %s" % (min(days), max(days)))
# A public repository is cloned by machines that never read it. Saying so here, computed, keeps the
# largest number on the page from being the one quoted — it is the least meaningful one present.
tv = sum(v.get("views", 0) for v in days.values())
tc = sum(v.get("clones", 0) for v in days.values())
if tc > 10 * max(tv, 1):
    print("\n  clones exceed views %dx. A public repo is mirrored by machines that never read it;" % (tc // max(tv, 1)))
    w = (d.get("windows") or [{}])[-1]
    print("  the number that means a person arrived is `unique`, which is %s."
          % w.get("view_uniques", "not recorded"))
ref = d.get("referrers", {})
if ref:
    print("\n  where they came from, last seen")
    for k, v in sorted(ref.items(), key=lambda x: -x[1]["uniques"]):
        print("    %-28s %5d unique" % (k, v["uniques"]))
PY
}

if [ "${1:-}" = "--show" ]; then show; exit 0; fi

if ! gh api "repos/$REPO/traffic/views" >/dev/null 2>&1; then
  printf '  %s✗%s no traffic access to %s\n' "$red" "$off" "$REPO"
  printf '      %sThe traffic API needs push access. `gh auth status` is %s.%s\n' \
         "$dim" "$(gh auth status 2>&1 | grep -oE 'account [a-zA-Z0-9_-]+' | head -1 || echo 'unknown')" "$off"
  printf '      %sSwitching GitHub accounts is founder-only. Nothing was recorded.%s\n' "$dim" "$off"
  exit 1
fi

V=$(gh api "repos/$REPO/traffic/views")
C=$(gh api "repos/$REPO/traffic/clones")
R=$(gh api "repos/$REPO/traffic/popular/referrers")

OUT="$OUT" python3 - "$V" "$C" "$R" <<'PY'
import json, os, sys, datetime
out = os.environ["OUT"]
views, clones, refs = (json.loads(a) for a in sys.argv[1:4])
try:
    d = json.load(open(out))
except FileNotFoundError:
    d = {}
d.setdefault("what_this_is", "GitHub traffic on the repository, snapshotted because GitHub keeps "
                             "only fourteen days. Distribution learning, not traction.")
days = d.setdefault("days", {})
def day(ts): return ts[:10]
# Merge rather than replace: every run keeps whatever earlier runs saw, so a gap longer than the
# fourteen-day window loses history instead of silently rewriting it to zero.
for e in views.get("views", []):
    days.setdefault(day(e["timestamp"]), {}).update(views=e["count"], uniques=e["uniques"])
# `uniques` in a day object is VIEW uniques, which is GitHub's own naming under /traffic/views.
# Clone uniques are recorded under their own key rather than sharing it, because the two sit in one
# object and a reader pairing `clones` with `uniques` would be reading two different populations.
for e in clones.get("clones", []):
    days.setdefault(day(e["timestamp"]), {}).update(
        clones=e["count"], clone_uniques=e["uniques"])
# GitHub's deduplicated totals for the window it just served. The merged day table cannot
# reproduce these — dedupe needs the raw visitors, which the API never hands over — so the only way
# to have a true unique count later is to keep the one GitHub computed at read time.
w = {"read": datetime.date.today().isoformat(),
     "views": views.get("count", 0), "view_uniques": views.get("uniques", 0),
     "clones": clones.get("count", 0), "clone_uniques": clones.get("uniques", 0)}
ws = [x for x in d.get("windows", []) if x["read"] != w["read"]] + [w]
d["windows"] = sorted(ws, key=lambda x: x["read"])
d["referrers"] = {r["referrer"]: {"count": r["count"], "uniques": r["uniques"]} for r in refs}
d["last_read"] = datetime.date.today().isoformat()
json.dump(d, open(out, "w"), indent=1, sort_keys=True)
print("  recorded %d day(s); %d now on file" % (len(views.get("views", [])), len(days)))
PY
echo
show
echo
printf '  %sThis is distribution learning. Traction is zero until somebody outside this repository\n' "$bold"
printf '  uses it for something of their own, and the submission says zero.%s\n' "$off"
