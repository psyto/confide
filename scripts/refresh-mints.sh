#!/usr/bin/env bash
# Re-pull every tokenized-equity mint on Solana into web/mints.json.
#
# Three issuers, not one, and they do not have the same product:
#   Backed Finance (xStocks)      — Swiss-issued, own ISIN, third-party product
#   Backpack Securities           — US CUSIP, described by the issuer as a security entitlement
#   PreStocks                     — pre-IPO private companies, added 2026-09-19
#
# PreStocks matters more than its eight mints suggest. Backed and Backpack both tokenize LISTED
# equity; PreStocks tokenizes companies with no public market at all — SpaceX, OpenAI, Anthropic,
# Neuralink. A third issuer, arriving independently at the same confidential-transfer configuration
# in a different asset class, is what turns "two issuers did the same thing" into a property of the
# substrate rather than a coincidence between two companies.
#
# Tessera is deliberately NOT here and its absence is the point: its T-SpaceX, T-OpenAI and
# T-Kalshi are Token-2022 with no confidential-transfer extension at all, so there is nothing to
# leave empty and nothing Confide can say about them. Checked on mainnet 2026-09-19. Not every
# issuer enables this — which is why the claim is about the ones that do.
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

# --- PreStocks: a flat list, mint under `mint` ---
for a in get("https://prestocks.com/api/prestocks"):
    m = a.get("contract_address")
    if not m:
        continue
    rows[m] = {"symbol": a.get("symbol"), "name": a.get("name") or a.get("symbol"),
               "mint": m, "underlying": a.get("symbol"), "issuer": "PreStocks"}

out = sorted(rows.values(), key=lambda r: (r["issuer"], r["symbol"]))
json.dump(out, open("web/mints.json", "w"), indent=1)

from collections import Counter
c = Counter(r["issuer"] for r in out)
print("%d mints -> web/mints.json   (%s)" % (len(out), ", ".join("%s %d" % kv for kv in c.items())))
for s in ("NVDAx", "TSLAx", "SPYx", "AAPLx", "NVDA.US", "AAPL.US", "SPACEX", "OPENAI"):
    assert any(r["symbol"] == s for r in out), s + " missing — the fetch is incomplete"
print("the symbols the page watches are all present")
PY
