#!/usr/bin/env bash
# What has actually been borrowed AGAINST tokenized equity, and what is left to borrow.
#
#   ./scripts/debt-side.sh
#   RPC=<endpoint> ./scripts/debt-side.sh     # getProgramAccounts; some public RPCs refuse it
#
# `capacity.sh` reports the collateral. It says nothing about the other side of those markets, and
# for a while it mislabelled a reserve's `borrowed` field — which counts the stock lent OUT — as
# the stock being "borrowed against". They are different trades and the numbers differ by an order
# of magnitude.
#
# The question this answers is the one a lender actually asks: **is there anything to lend, and is
# anyone taking it?** On 2026-09-19 the answer was that the main tokenized-equity market's USDC was
# 87 % drawn while another market held ten cents, which is a different picture from either
# "unused" or "full".
set -euo pipefail
cd "$(dirname "$0")/.."
RPC="${RPC:-https://api.mainnet-beta.solana.com}"

RPC="$RPC" python3 - <<'PY'
import base64, json, os, sys, urllib.request
sys.path.insert(0, "scripts/lib")
import klend_rules as K

RPC = os.environ["RPC"]
KLEND = "KLend2g3cP87fffoy8q1mQqGKjrxjC8boSyAYavgmjD"
NAMES = {"EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v": "USDC",
         "2u1tszSeqZ3qBWF3uNGPFc8TzMk2tdiwknnRMWGWjGWH": "USDG",
         "2b1kV6DkPAnxd5ixfnxCpjxmKwqjjaYmCZfHsFu24GXo": "PYUSD",
         "cbbtcf3aa214zXHbiAZQwf4122FBYbraNdFqgw4iMij": "cbBTC"}

def b58(b):
    A = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    n = int.from_bytes(b, "big"); s = ""
    while n: n, r = divmod(n, 58); s = A[r] + s
    return "1" * (len(b) - len(b.lstrip(b"\0"))) + s

def rpc(method, params):
    b = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    r = urllib.request.Request(RPC, b, {"Content-Type": "application/json", "User-Agent": "confide"})
    try:
        d = json.load(urllib.request.urlopen(r, timeout=180))
    except urllib.error.HTTPError as e:
        raise SystemExit("  HTTP %d — this endpoint will not serve getProgramAccounts; pass RPC=" % e.code)
    if "error" in d:
        raise SystemExit("  rpc: %s" % json.dumps(d["error"])[:200])
    return d["result"]

equity = {m["mint"] for m in json.load(open("web/mints.json"))}
mine = {r["market"] for r in json.load(open("web/kamino-reserves.json"))["reserves"]}

accs = rpc("getProgramAccounts", [KLEND, {"encoding": "base64", "commitment": "confirmed",
    "filters": [{"dataSize": K.RESERVE_LEN},
                {"memcmp": {"offset": 0, "bytes": b58(K.RESERVE_DISCRIMINATOR)}}]}])

markets = {}
for a in accs:
    data = base64.b64decode(a["account"]["data"][0])
    mkt = b58(data[32:64])
    if mkt not in mine:
        continue
    mint = b58(data[K.OFF_LIQ_MINT:K.OFF_LIQ_MINT + 32])
    r = K.decode_reserve(data)
    r.pop("mint_raw", None); r.pop("lending_market_raw", None)
    markets.setdefault(mkt, []).append((mint, r))

bold = "\033[1m"; off = "\033[0m"; dim = "\033[2m"; red = "\033[31m"
print("\n  %sWHAT CAN BE BORROWED AGAINST TOKENIZED EQUITY%s — the debt side of the same markets\n" % (bold, off))
tot_b = tot_a = 0.0
for mkt, rs in sorted(markets.items(), key=lambda kv: -len(kv[1])):
    eq = [x for x in rs if x[0] in equity]
    debt = [x for x in rs if x[0] not in equity]
    print("  market %s…  %d tokenized-equity reserve(s)" % (mkt[:10], len(eq)))
    if not debt:
        print("      %sno borrowable asset in this market at all%s\n" % (red, off))
        continue
    for mint, r in sorted(debt, key=lambda x: -(x[1].get("borrowed") or 0)):
        av = float(r.get("available") or 0); bo = float(r.get("borrowed") or 0)
        tot_b += bo; tot_a += av
        util = 100 * bo / (av + bo) if (av + bo) else 0
        flag = ("  %s← %.0f%% drawn%s" % (bold, util, off)) if util > 80 else (
               ("  %s← nothing supplied%s" % (red, off)) if av + bo < 1 else "")
        print("      %-6s borrowed %14s   available %14s   %5.0f%% utilised%s" % (
            NAMES.get(mint, mint[:8] + "…"), "{:,.2f}".format(bo), "{:,.2f}".format(av), util, flag))
    print()
print("  %sacross these markets: %s borrowed, %s left to borrow%s" % (
    bold, "{:,.0f}".format(tot_b), "{:,.0f}".format(tot_a), off))
print("  %sUnits are each asset's own, not dollars — they are stablecoins except where noted.%s" % (dim, off))
print()
print("  This is the constraint a lender meets, and it is not the collateral: where the debt asset")
print("  is there it gets drawn, and where it is not the reserve is decorative.")
PY
