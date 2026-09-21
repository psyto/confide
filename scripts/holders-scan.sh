#!/usr/bin/env bash
# How many accounts hold a MEANINGFUL position, not just a balance.
#
#   ./scripts/holders-scan.sh          # a sample across all three issuers
#   ./scripts/holders-scan.sh --last   # reprint the stored result
#
# WHY THIS EXISTS, AND WHY IT IS SEPARATE FROM usage-scan.sh. That one answers "has anyone been
# through the gate" and the answer is no. This one answers a question the founder raised on
# 2026-09-21: an investor who buys tokenized stock — does the position end up in their own on-chain
# account, or as a book entry inside an exchange?
#
# The account count cannot answer it. 96-99% of accounts with any balance hold less than one share,
# and the median NVDAx holder owns 0.0046 of one. Counting accounts counts dust.
#
# WHAT IT IS FOR: this is a BASELINE, not a verdict. The structure it describes is today's and is
# not permanent — the founder's correction, and the reason this is a script rather than a sentence
# in a document. If self-custody at size ever becomes viable, the ">= 1 share" column is where it
# shows up first, and a number nobody recorded cannot be seen to move.
#
# Needs an endpoint that serves getProgramAccounts. The founder's Alchemy plan refuses it; the
# public mainnet endpoint answers it, and truncates often enough that this retries.
set -euo pipefail
cd "$(dirname "$0")/.."
R="${RPC:-https://api.mainnet-beta.solana.com}"
OUT="${OUT:-web/holders.json}"
T22=TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb

if [ "${1:-}" = "--last" ]; then
  [ -f "$OUT" ] || { echo "  $OUT is missing — run ./scripts/holders-scan.sh" >&2; exit 1; }
  OUT="$OUT" python3 - <<'PY'
import json, os
d = json.load(open(os.environ["OUT"]))
B, DIM, OFF = "\033[1m", "\033[2m", "\033[0m"
print(f"\n  {B}WHO ACTUALLY HOLDS ONE{OFF}  {DIM}measured {d['generated_utc']}{OFF}\n")
print("    %-10s %-10s %9s %10s %8s %8s" % ("mint", "issuer", "accounts", ">=1 share", ">=10", ">=100"))
for r in d["mints"]:
    print("    %-10s %-10s %9d %10d %8d %8d"
          % (r["symbol"], r["issuer"], r["accounts"], r["at_least_1"], r["at_least_10"], r["at_least_100"]))
t = d["total"]
print("    %-21s %9d %10d %8d %8d"
      % ("total", t["accounts"], t["at_least_1"], t["at_least_10"], t["at_least_100"]))
print(f"\n  {B}{t['at_least_1']:,}{OFF} of {t['accounts']:,} accounts hold a whole share or more "
      f"({100*t['at_least_1']/t['accounts']:.3f}%). {B}{t['at_least_100']}{OFF} hold a hundred.\n")
PY
  exit 0
fi

MINTS=("$@")
if [ ${#MINTS[@]} -eq 0 ]; then
  # SPCX.US is in the list because scripts/lib/gpa.py can now read it. It was absent while it was
  # unreadable, which made the most traded tokenized equity on Solana the one this repository could
  # not measure.
  MINTS=(Xsc9qvGR1efVDFGLrVsmkzv3qi45LTBjeUKSPmx9qEh \
         XsbEhLAtcf6HdfpFZ5xEMdqW8nfAvcsP5bdudRLJzJp \
         Pren1FvFX6J3E4kXhJuCiAD5aDmGEb7qJRncwA8Lkhw \
         PreANxuXjsy2pvisWWMNB6YaJNzr7681wJJr2rHsfTh \
         AMC1qwR9KhiyrQBRPrxnfo4JfMeMZqEBvt5tgTytNNoc \
         SPCXxcqXj6e5dJDVNovHN8744zkbhM2bYudU45BimGb)
fi

RPC="$R" T22="$T22" OUT="$OUT" python3 - "${MINTS[@]}" <<'PY'
import base64, json, os, struct, subprocess, sys, time
RPC, T22, OUT = os.environ["RPC"], os.environ["T22"], os.environ["OUT"]
SYMS = {m["mint"]: (m["symbol"], m["issuer"]) for m in json.load(open("web/mints.json"))}
B, DIM, OFF = "\033[1m", "\033[2m", "\033[0m"

sys.path.insert(0, "scripts/lib")
from gpa import token_accounts      # noqa: E402 -- partitions a mint too large to answer at once

print(f"\n  {B}WHO ACTUALLY HOLDS ONE{OFF} {DIM}a balance is not a position{OFF}\n")
print("    %-10s %-10s %9s %10s %8s %8s" % ("mint", "issuer", "accounts", ">=1 share", ">=10", ">=100"))
DEC = {}
for i in range(0, len(sys.argv[1:]), 100):
    batch = sys.argv[1:][i:i + 100]
    out = subprocess.run(["curl", "-s", "--max-time", "60", RPC, "-H", "content-type: application/json",
                          "-d", json.dumps({"jsonrpc": "2.0", "id": 1, "method": "getMultipleAccounts",
                                            "params": [batch, {"encoding": "jsonParsed"}]})],
                         capture_output=True).stdout
    for m, v in zip(batch, json.loads(out)["result"]["value"]):
        DEC[m] = v["data"]["parsed"]["info"]["decimals"] if v else 8

rows, tot = [], dict(accounts=0, at_least_1=0, at_least_10=0, at_least_100=0)
for mint in sys.argv[1:]:
    sym, iss = SYMS.get(mint, ("?", "?"))
    try:
        res = token_accounts(RPC, mint, offset=64, length=8)
    except RuntimeError as e:
        print("    %-10s %-10s  %s" % (sym, iss, e)); sys.exit(1)
    v = [struct.unpack("<Q", a["data"])[0] for a in res]
    # Decimals are read per mint, not assumed. The first version of this script hardcoded 8 with
    # a comment saying every tokenized-equity mint uses it -- SPCX.US, the most traded one on
    # Solana, uses 6, and the script would have reported its holders as a hundredth of their size.
    one = 10 ** DEC[mint]
    c = dict(accounts=len(v),
             at_least_1=sum(1 for a in v if a >= one),
             at_least_10=sum(1 for a in v if a >= 10 * one),
             at_least_100=sum(1 for a in v if a >= 100 * one))
    for k in tot:
        tot[k] += c[k]
    rows.append(dict(mint=mint, symbol=sym, issuer=iss, **c))
    print("    %-10s %-10s %9d %10d %8d %8d"
          % (sym, iss, c["accounts"], c["at_least_1"], c["at_least_10"], c["at_least_100"]))
print("    %-21s %9d %10d %8d %8d"
      % ("total", tot["accounts"], tot["at_least_1"], tot["at_least_10"], tot["at_least_100"]))
print(f"\n  {B}{tot['at_least_1']:,}{OFF} of {tot['accounts']:,} accounts hold a whole share or more "
      f"({100*tot['at_least_1']/tot['accounts']:.3f}%). {B}{tot['at_least_100']}{OFF} hold a hundred.")
print(f"  {DIM}This is a baseline. If self-custody at size ever becomes viable, this column moves "
      f"first.{OFF}\n")
json.dump({"generated_utc": time.strftime("%Y-%m-%d %H:%M:%S UTC", time.gmtime()),
           "note": "Accounts holding a meaningful position, not merely a balance. A baseline: the "
                   "structure it describes is today's and is not permanent.",
           "rpc": RPC, "mints": rows, "total": tot}, open(OUT, "w"), indent=1)
print(f"  written to {OUT}\n")
PY
