#!/usr/bin/env bash
# The extension inventory of every tokenized stock, with what each extension is FOR.
#
#   ./scripts/slot-roles.sh                 # print it
#   ./scripts/slot-roles.sh --check <file>  # fail if that file's table is not this one
#
# The counts come from web/slots.json, which slot-scan.sh writes. The ROLE column is the only typed
# part and it is a description of what the extension does, not a number — the thing this repository
# keeps getting wrong is numbers maintained by hand, and this is how the 7-of-8 argument stops being
# one of them.
set -euo pipefail
cd "$(dirname "$0")/.."
python3 - "$@" <<'PY'
import json, re, sys, pathlib

d = json.load(open("web/slots.json"))
ext, n = d["extensions"], d["mints"]
ROLE = {
    "permanentDelegate":    ("control", "the issuer can move any holder's tokens without them"),
    "defaultAccountState":  ("control", "a new account starts restricted until the issuer allows it"),
    "pausableConfig":       ("control", "the issuer can stop every transfer at once"),
    "transferHook":         ("control", "issuer code runs on every single transfer"),
    "scaledUiAmountConfig": ("corporate action", "a mint-level multiplier — dividends and splits"),
    "metadataPointer":      ("plumbing", "where the token's metadata lives"),
    "tokenMetadata":        ("plumbing", "the metadata itself"),
    "confidentialTransferMint": ("privacy", "balances and amounts encrypted on chain"),
    "transferFeeConfig":    ("fee", "a fee withheld on transfer"),
    "confidentialTransferFeeConfig": ("fee", "the fee's confidential counterpart"),
}
missing = [k for k in ext if k not in ROLE]
if missing:
    sys.exit("  slot-scan found an extension this file has no role for: %s" % ", ".join(missing))

lines = ["| extension | mints | what it is for |", "|---|---|---|"]
for k, v in sorted(ext.items(), key=lambda x: (-x[1], x[0])):
    role, what = ROLE[k]
    lines.append("| `%s` | **%s** | *%s* — %s |" % (k, "{:,}".format(v), role, what))
table = "\n".join(lines)

if "--check" in sys.argv:
    f = sys.argv[sys.argv.index("--check") + 1]
    body = pathlib.Path(f).read_text(encoding="utf-8")
    if table not in body:
        print("  %s does not carry the table ./scripts/slot-roles.sh prints" % f)
        for row in lines:
            if row not in body:
                print("    missing: %s" % row)
        sys.exit(1)
    sys.exit(0)
print(table)
PY
