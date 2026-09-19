#!/usr/bin/env bash
# Who actually holds a tokenized stock, per chain — distribution, not supply.
#
#   RPC=<your solana endpoint> ./scripts/holders.sh [SYMBOL]
#
# Supply says how many tokens exist. It does not say whether anyone holds them. On 2026-09-19 that
# difference reversed a conclusion here: NVDAx shows 108,045 on Arbitrum and 104,812 on Ink, which
# reads as a large stranded position until you look at who has it —
#
#   Arbitrum   108,039 of 108,045 (99.99%) in 0x5F7A4c11…
#   Ink         96,614 of 104,812 (92%)    in the SAME 0x5F7A4c11…
#
# One address, two chains: issuer or market-maker inventory, not holders. A claim about "holders
# who cannot borrow" was one step from being written into the submission on the strength of the
# supply figure alone.
#
# **The endpoint is an argument, never a file.** Public Solana RPCs rate-limit this call; pass your
# own with RPC= and do not commit it.
set -euo pipefail
cd "$(dirname "$0")/.."
SYM="${1:-NVDAx}"
: "${RPC:?set RPC to a Solana endpoint — public ones return 429 for getTokenLargestAccounts}"

RPC="$RPC" SYM="$SYM" python3 - <<'PY'
import json, os, urllib.error, urllib.request

rpc, sym = os.environ["RPC"], os.environ["SYM"]
mints = json.load(open("web/mints.json"))
m = next((x for x in mints if x["symbol"] == sym), None)
if not m:
    raise SystemExit("  %s is not in web/mints.json" % sym)

def call(method, params):
    b = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    r = urllib.request.Request(rpc, b, {"Content-Type": "application/json", "User-Agent": "confide"})
    try:
        d = json.load(urllib.request.urlopen(r, timeout=60))
    except urllib.error.HTTPError as e:
        # A traceback here says urllib failed. It does not say the endpoint was a placeholder,
        # which is what actually happened the first time this ran.
        why = {401: "the endpoint rejected the key — check RPC is the full URL and not a "
                    "placeholder like .../v2/...",
               403: "forbidden — this endpoint will not serve this method",
               429: "rate limited — public endpoints refuse getTokenLargestAccounts; use your own"}
        raise SystemExit("  HTTP %d: %s" % (e.code, why.get(e.code, e.reason)))
    except urllib.error.URLError as e:
        raise SystemExit("  could not reach the endpoint: %s" % str(e.reason)[:120])
    if "error" in d:
        raise SystemExit("  rpc error: %s" % json.dumps(d["error"])[:200])
    return d["result"]

info = call("getAccountInfo", [m["mint"], {"encoding": "jsonParsed"}])["value"]["data"]["parsed"]["info"]
total = int(info["supply"]) / 10 ** int(info["decimals"])

# Every key that holds an authority on this mint. A top holder owned by one of them is the issuer
# holding its own inventory, which is a different fact from a holder holding a position — and the
# first version of this script counted them together and called the result "distributed".
authorities = set()
for k in ("mintAuthority", "freezeAuthority"):
    if info.get(k):
        authorities.add(info[k])
for e in info.get("extensions", []):
    st = e.get("state")
    if isinstance(st, dict):
        for key, val in st.items():
            if isinstance(val, str) and len(val) > 30 and ("authority" in key.lower() or key == "delegate"):
                authorities.add(val)

big = call("getTokenLargestAccounts", [m["mint"]])["value"]
owners = {}
for a in big:
    v = call("getAccountInfo", [a["address"], {"encoding": "jsonParsed"}])["value"]
    owners[a["address"]] = v["data"]["parsed"]["info"]["owner"] if v else None

print("\n  %s (%s) on Solana — supply %s\n" % (sym, m["issuer"], f"{total:,.0f}"))
run = issuer = 0.0
for n, a in enumerate(big, 1):
    v = float(a["uiAmountString"]); run += v
    own = owners.get(a["address"])
    mine = own in authorities
    if mine:
        issuer += v
    if n <= 15:
        print("   %2d %14s  %5.1f%%  %s%s" % (n, f"{v:,.2f}", 100 * v / total if total else 0,
              a["address"][:16] + "…", "   \033[1m← the issuer's own key\033[0m" if mine else ""))
other = run - issuer
print("\n   the %d largest accounts hold %s = %.1f%% of supply" % (len(big), f"{run:,.0f}", 100 * run / total if total else 0))
print("      of which the issuer's own keys hold %s = %.1f%%" % (f"{issuer:,.0f}", 100 * issuer / total if total else 0))
print("      and everyone else holds              %s = %.1f%%" % (f"{other:,.0f}", 100 * other / total if total else 0))
print()
share = (other / total) if total else 0
if share < 0.05:
    print("   \033[1mInventory.\033[0m Almost nothing is held by anyone but the issuer. This is a")
    print("   deployment, not a market. Do not describe these as holders.")
else:
    print("   \033[1mHeld.\033[0m %.0f%% of the supply is in hands other than the issuer's." % (100 * share))
    print("   Compare the same token on other chains before calling that a lot.")
PY
