#!/usr/bin/env bash
# Re-pull every tokenized-equity mint on Solana into web/mints.json.
#
# Two issuers, not one:
#   Backed Finance (xStocks)      — Swiss-issued, own ISIN, third-party product
#   Backpack Securities           — US CUSIP, described by the issuer as a security entitlement
#
# Both paginate or bury the mint in a nested field, and taking the first page of either gives you a
# confident, wrong answer.
set -euo pipefail
cd "$(dirname "$0")/.."

python3 - <<'PY'
import json, urllib.request

def get(url):
    return json.load(urllib.request.urlopen(
        urllib.request.Request(url, headers={"User-Agent": "confide"}), timeout=90))

rows = {}

# --- Backed / xStocks: paginated; page one is 100 alphabetically-early symbols and omits NVDAx ---
for pg in range(1, 13):
    d = get("https://api.xstocks.fi/api/v2/public/assets?pageSize=100&page=%d" % pg)
    nodes = d.get("nodes", [])
    if not nodes:
        break
    for a in nodes:
        for dep in a.get("deployments", []) or []:
            if dep.get("network") == "Solana" and dep.get("address", "").startswith("Xs"):
                rows[dep["address"]] = {"symbol": a["symbol"], "name": a.get("name"),
                                        "mint": dep["address"], "underlying": a.get("underlyingSymbol"),
                                        "issuer": "Backed"}
                break

# --- Backpack Securities: the mint hides under tokens[].contractAddress; securities[] says which
#     assets are equities and carries the CUSIP ---
cusip = {s["asset"]: s.get("cusip") for s in get("https://api.backpack.exchange/api/v1/securities")}
for a in get("https://api.backpack.exchange/api/v1/assets"):
    sym = a.get("symbol")
    if sym not in cusip:
        continue
    for t in a.get("tokens", []):
        if t.get("blockchain") == "Solana" and t.get("contractAddress"):
            rows[t["contractAddress"]] = {"symbol": sym, "name": a.get("displayName") or sym,
                                          "mint": t["contractAddress"], "underlying": sym.split(".")[0],
                                          "issuer": "Backpack", "cusip": cusip[sym]}
            break

out = sorted(rows.values(), key=lambda r: (r["issuer"], r["symbol"]))
json.dump(out, open("web/mints.json", "w"), indent=1)

from collections import Counter
c = Counter(r["issuer"] for r in out)
print("%d mints -> web/mints.json   (%s)" % (len(out), ", ".join("%s %d" % kv for kv in c.items())))
for s in ("NVDAx", "TSLAx", "SPYx", "AAPLx", "NVDA.US", "AAPL.US"):
    assert any(r["symbol"] == s for r in out), s + " missing — the fetch is incomplete"
print("the symbols the page watches are all present")
PY
