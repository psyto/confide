#!/usr/bin/env bash
# One delivery-versus-payment, from the three points of view that exist.
#
#   ./scripts/dvp-show.sh
#
# The transaction is public and the amounts are not, which is the whole product and is also why a
# pane listing instruction names does not show a trade. What a viewer has to see is **who can read
# what**: the chain shows four accounts holding nothing, and each side reads only its own side of
# the exchange. Nobody, this repository included, can recover those figures from the chain — they
# were written down by the parties at the time, into web/dvp.json.
set -euo pipefail
cd "$(dirname "$0")/.."
R="${RPC:-https://api.devnet.solana.com}"
[ -f web/dvp.json ] || { echo "  web/dvp.json is missing — run MODE=dvp ./scripts/swap-e2e.sh" >&2; exit 1; }
RPC="$R" python3 - <<'PY'
import json, os, subprocess
d = json.load(open("web/dvp.json"))
R = os.environ["RPC"]
G, A, DIM, OFF, B = "\033[32m", "\033[33m", "\033[2m", "\033[0m", "\033[1m"
def pub(acct):
    body = json.dumps({"jsonrpc":"2.0","id":1,"method":"getAccountInfo",
                       "params":[acct,{"encoding":"jsonParsed"}]})
    v = json.loads(subprocess.run(["curl","-s","--max-time","60",R,
        "-H","content-type: application/json","-d",body],capture_output=True).stdout)["result"]["value"]
    return None if not v else v["data"]["parsed"]["info"]["tokenAmount"]["uiAmountString"]

accts = d["seller"]["accounts"] + d["buyer"]["accounts"]
pubs = [pub(a) for a in accts]
n = sum(1 for p in pubs if p == "0")
s, b = d["seller"], d["buyer"]
print(f"\n  {B}ONE TRANSACTION. NEITHER SIDE COULD HAPPEN WITHOUT THE OTHER.{OFF}\n")
print(f"  {B}what anyone watching sees{OFF}   {DIM}read off devnet just now{OFF}")
print(f"    {n} of {len(accts)} accounts   public balance {G}0{OFF}")
print(f"    and two confidential transfers that settled together\n")
# Two columns of the same width, because the whole point is that they mirror each other and a
# ragged right edge makes a viewer read them as two lists instead of one exchange.
def col(label, before, after, money=False):
    f = (lambda v: "$" + format(v, ",")) if money else (lambda v: format(v, ","))
    return f"{label:6}{f(before):>11} → {A}{f(after):<11}{OFF}"
print(f"  {B}{'what the SELLER can read':<38}{OFF}{B}what the BUYER can read{OFF}")
print("    " + col("stock", s["stock_before"], s["stock_after"])
      + "   " + col("stock", b["stock_before"], b["stock_after"]))
print("    " + col("cash", s["cash_before"], s["cash_after"], True)
      + "   " + col("cash", b["cash_before"], b["cash_after"], True))
print(f"\n    delivered {A}{d['delivered_units']:,} shares{OFF}   against   "
      f"{A}${d['paid_units']:,}{OFF}   =  ${d['price_per_share']:,.0f} a share")
print(f"\n  {DIM}Agreed off chain. Settled on it. Published to nobody.{OFF}")
print(f"  {DIM}The two columns were written by the parties at the time — nothing on chain can")
print(f"  recover them, which is the point.{OFF}\n")
PY
