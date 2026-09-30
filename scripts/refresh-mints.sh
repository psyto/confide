#!/usr/bin/env bash
# Re-pull every tokenized-equity mint from three issuers' catalogues into web/mints.json.
#
# This is a product catalogue, not a census. Everything downstream inherits that scope, and for
# fifteen days it did not say so -- docs/cwf-2026/THE-POPULATION.md.
#
# Three issuers, not one, and they do not have the same product:
#   Backed Finance (xStocks)      — Swiss-issued, own ISIN, third-party product
#   Backpack Securities           — US CUSIP, described by the issuer as a security entitlement
#   PreStocks                     — pre-IPO private companies, added 2026-09-19
#
# PreStocks matters more than its eight mints suggest. Backed and Backpack both tokenize LISTED
# equity; PreStocks tokenizes companies with no public market at all — SpaceX, OpenAI, Anthropic,
# Neuralink. A third issuer carrying the same confidential-transfer configuration in a different
# asset class widens what the measurement covers. It does not show how the three got there: the
# configuration is also the struct's zero value, so a shared template or SDK
# would produce it with nobody deciding (docs/cwf-2026/THE-PINCER.md, 2026-09-27).
#
# Tessera is left out on purpose and its absence is the point: its T-SpaceX, T-OpenAI and
# T-Kalshi are Token-2022 with no confidential-transfer extension at all, so there is nothing to
# leave empty and nothing Confide can say about them. Checked on mainnet 2026-09-19. Not every
# issuer enables this — which is why the claim is about the ones that do.
#
# Both paginate or bury the mint in a nested field, and taking the first page of either gives you a
# confident, wrong answer.
set -euo pipefail
cd "$(dirname "$0")/.."

python3 - <<'PY'
import hashlib, json, os, time, urllib.request

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

# CHECK BEFORE WRITING. These eight asserts used to run AFTER json.dump, so a partial fetch --
# one issuer's API returning an empty page, which is the failure this script was written for --
# overwrote web/mints.json first and complained second. open(...,"w") truncates at that moment.
for s in ("NVDAx", "TSLAx", "SPYx", "AAPLx", "NVDA.US", "AAPL.US", "SPACEX", "OPENAI"):
    assert any(r["symbol"] == s for r in out), s + " missing — the fetch is incomplete"

from collections import Counter
c = Counter(r["issuer"] for r in out)
assert len(c) == 3, "expected three issuers, got %r — the list would silently narrow" % dict(c)

blob = json.dumps(out, indent=1)

# DRY=1 answers "has the catalogue moved?" without touching the measured file. It exists because on
# 2026-09-30 the only way to ask that question was to overwrite web/mints.json, and the answer was
# 1,992 -> 2,193: a refresh would have restated the headline count in forty surfaces while
# slot-scan.sh had never read the 201 new mints. Asking must be cheaper than committing.
if os.environ.get("DRY"):
    print("%d mints (DRY -- nothing written)   (%s)"
          % (len(out), ", ".join("%s %d" % kv for kv in c.items())))
    have = json.load(open("web/mints.json"))
    print("   web/mints.json on disk holds %d" % len(have))
    if len(have) != len(out):
        print("   the catalogue has moved by %+d. Re-running slot-scan.sh over the new list is what"
              % (len(out) - len(have)))
        print("   makes the new count sayable; refreshing alone only makes the old one wrong.")
    raise SystemExit(0)

# Provenance, because the list is a product catalogue and every claim downstream inherits that.
# Until 2026-09-30 the only record of WHEN this ran was the commit date of web/mints.json, so the
# repository was dating a measurement from git metadata and calling it a retrieval time.
source = {
    "generated_utc": time.strftime("%Y-%m-%d %H:%M:%S UTC", time.gmtime()),
    "note": "web/mints.json is every Solana mint these three APIs return. It is a catalogue, not a "
            "census of Solana -- see docs/cwf-2026/THE-POPULATION.md.",
    "sources": [
        {"issuer": "Backed",    "api": "https://api.xstocks.fi/api/v2/public/assets"},
        {"issuer": "Backpack",  "api": "https://api.backpack.exchange/api/v1/assets"},
        {"issuer": "PreStocks", "api": "https://prestocks.com/api/prestocks"},
    ],
    # Per-issuer counts are derivable from mints.json and are NOT copied here. The hash is not:
    # it is what ties this record to the exact bytes that were written.
    "mints_sha256": hashlib.sha256(blob.encode()).hexdigest(),
}

open("web/mints.json", "w").write(blob)
json.dump(source, open("web/mints-source.json", "w"), indent=1, sort_keys=True)
print("%d mints -> web/mints.json   (%s)" % (len(out), ", ".join("%s %d" % kv for kv in c.items())))
print("   provenance -> web/mints-source.json   %s" % source["generated_utc"])
print("the symbols the page watches are all present")
PY
