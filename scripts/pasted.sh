#!/usr/bin/env bash
# Record that a submitted field was pasted, so the repository can tell when it has drifted from it.
#
#   ./scripts/pasted.sh stocklana-full stocklana-short     # stamp these fields as pasted now
#   URL=https://x.com/... ./scripts/pasted.sh x-post      # stamp it, and keep where it went
#   ./scripts/pasted.sh --show                             # what is on file
#
# WHY THIS EXISTS. A submitted field is the one artifact this repository cannot read back. The
# short description sat in the Stocklana form saying "1,869 tokenized stocks" for days after the
# count was 1,992, because it had been typed once and nothing compared it to anything. Every check
# here reads files; none of them could see the form.
#
# So the form is not checked. What is checked is whether the FILE has changed since the founder
# said they pasted it — which is the same question from the side this repository can actually
# answer, and it is answered by a hash rather than by memory.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="_submission/pasted.json"

# A case statement, not an associative array: `declare -A` needs bash 4 and /usr/bin/env bash here
# is 3.2. This repository has already shipped one script that only ran in the author's shell.
field_file() {
  case "$1" in
    stocklana-full)      echo "_submission/full.md" ;;
    stocklana-short)     echo "_submission/short.txt" ;;
    youtube-description) echo "_submission/youtube-paste.txt" ;;
    x-post)              echo "docs/cwf-2026/x-post.txt" ;;
    cwf-checkin1)        echo "_submission/youtube-checkin1-paste.txt" ;;
    cwf-form)            echo "_submission/cwf-form.md" ;;
    cwf-graphic)         echo "_submission/graphic.jpg" ;;
    *)                   echo "" ;;
  esac
}
FIELDS="stocklana-full stocklana-short youtube-description x-post cwf-checkin1 cwf-form cwf-graphic"

show() {
  python3 - "$OUT" <<'PY'
import json, sys, hashlib, os
try:
    d = json.load(open(sys.argv[1]))
except FileNotFoundError:
    print("  nothing recorded yet"); raise SystemExit(0)
for k in sorted(d):
    v = d[k]
    f = v["file"]
    now = hashlib.sha256(open(f, "rb").read()).hexdigest() if os.path.exists(f) else "MISSING"
    state = "current" if now == v["sha256"] else "FILE HAS CHANGED SINCE"
    print("  %-20s %-32s pasted %s  %s" % (k, f, v["pasted_utc"][:16], state))
    if v.get("url"):
        print("  %-20s %s" % ("", v["url"]))
PY
}

[ "${1:-}" = "--show" ] && { show; exit 0; }
[ $# -gt 0 ] || { echo "  usage: ./scripts/pasted.sh <field>… | --show" >&2; exit 2; }

for k in "$@"; do
  [ -n "$(field_file "$k")" ] || { echo "  unknown field: $k (have: $FIELDS)" >&2; exit 2; }
done

for k in "$@"; do
  OUT="$OUT" K="$k" F="$(field_file "$k")" URL="${URL:-}" python3 - <<'PY'
import json, os, hashlib, datetime


def _is_text(b):
    try:
        b.decode("utf-8"); return True
    except UnicodeDecodeError:
        return False
out, k, f = os.environ["OUT"], os.environ["K"], os.environ["F"]
try:
    d = json.load(open(out))
except FileNotFoundError:
    d = {}
b = open(f, "rb").read()
d[k] = {"file": f,
        "sha256": hashlib.sha256(b).hexdigest(),
        # An uploaded image belongs here as much as a pasted field does -- it is the same question,
        # has the artifact moved since it went in -- so this records bytes when the file is not text
        # rather than refusing to record it at all.
        **({"characters": len(b.decode("utf-8"))} if _is_text(b) else {"bytes": len(b)}),
        "pasted_utc": datetime.datetime.now(datetime.timezone.utc)
                      .strftime("%Y-%m-%d %H:%M:%S UTC"),
        "note": "Reported by the founder. Nothing here read the form; this records what the file "
                "was at the moment they said they had pasted it."}
if os.environ.get("URL"):
    d[k]["url"] = os.environ["URL"]
json.dump(d, open(out, "w"), indent=1, sort_keys=True)
print("  recorded %s <- %s" % (k, f))
PY
done
echo
show
