#!/usr/bin/env bash
# What is on the table, in dollars, and how much of it a confidential holder can reach.
#
#   ./scripts/capacity.sh
#
# The plan's bet was to make the number computable by anyone from live chain data, without asking
# anyone's permission. This is that number. It uses each reserve's own price, its own cap and its
# own LTV -- all figures Kamino's market owners chose and this repository only reads.
#
# Needs web/kamino-reserves.json; run ./scripts/kamino-reserves.sh first.
set -euo pipefail
cd "$(dirname "$0")/.."

python3 - <<'PY'
import json, sys, datetime
sys.path.insert(0, 'scripts/lib')
import klend_rules as K

d = json.load(open('web/kamino-reserves.json'))
rows = d["reserves"]
priced   = [r for r in rows if r["price"] > 0]
unpriced = [r for r in rows if r["price"] == 0]

g = lambda n: "${:,.0f}".format(n)
bold = "\033[1m"; off = "\033[0m"; dim = "\033[2m"; red = "\033[31m"

held = sum(r["available"] * r["price"] for r in priced)
borrowed = sum(r["borrowed"] * r["price"] for r in priced)
capacity = sum(r["deposit_limit"] * r["ltv_pct"] / 100 * r["price"] for r in priced)

print()
print("  %sTOKENIZED STOCK SITTING IN KAMINO RESERVES%s  — %d of %d reserves carry a price" %
      (bold, off, len(priced), len(rows)))
print("    %-9s %-8s %5s %14s %16s" % ("SYMBOL", "ISSUER", "LTV", "HELD", "CAP × LTV × PRICE"))
for r in sorted(priced, key=lambda r: -r["deposit_limit"] * r["ltv_pct"] * r["price"]):
    print("    %-9s %-8s %4d%% %14s %16s" % (
        r["symbol"], r["issuer"], r["ltv_pct"],
        g(r["available"] * r["price"]),
        g(r["deposit_limit"] * r["ltv_pct"] / 100 * r["price"])))
print("    %-9s %-8s %5s %14s %16s" % ("", "", "", g(held), g(capacity)))
print()
print("  %s%s of tokenized stock is deposited in these reserves.%s" % (bold, g(held), off))
print("  %s%s of borrowing is what their caps and LTVs already authorise.%s" % (bold, g(capacity), off))
print("  %s%s of either is reachable while your position stays confidential.%s" % (red + bold, "$0", off))
print()
print("  %sEvery one of those positions is public. That is not a side effect of using Kamino —" % dim)
print("  it is the only way in. The ordinary deposit path refuses an account carrying")
print("  confidential value, so a holder who will not publish has one option, and it is to")
print("  stay out.%s" % off)
print()
print("  %sWhat these numbers are, exactly:%s" % (bold, off))
print("    · HELD is available liquidity × the reserve's own price. It is a snapshot, not a flow,")
print("      and %s of it is currently borrowed against." % g(borrowed))
print("    · CAP × LTV × PRICE is authorised capacity, not utilisation. Nobody is obliged to use it.")
print("    · The price is klend's `market_price_sf`, refreshed when someone last touched the")
print("      reserve. %d reserves read zero and are excluded entirely: %s." % (
          len(unpriced), ", ".join(sorted({r["symbol"] for r in unpriced}))))
print("    · The unit is not decoded from the market's quote currency. It is almost certainly USD —")
print("      the values land on %s for AAPLx and %s for SPYx — but that is evidence, not a decode." % (
          g([r for r in priced if r['symbol']=='AAPLx'][0]["price"]),
          g([r for r in priced if r['symbol']=='SPYx'][0]["price"])))

spcx = [r for r in rows if r["symbol"] == "SPCX.US"]
if spcx:
    r = spcx[0]
    lo, hi = 60.0, 200.0   # the reserve's own price heuristic band; see docs/packets/SPCX.US.md
    print()
    print("  %sTHE NAMED CASE — SpaceX%s" % (bold, off))
    print("    Its reserve has never been refreshed, so it has no price to read and is not in the")
    print("    totals above. Bounding it by the band the reserve itself will accept:")
    print("      %d cap × %d%% LTV × $%.0f–$%.0f  =  %s – %s of authorised borrowing," % (
        r["deposit_limit"], r["ltv_pct"], lo, hi,
        g(r["deposit_limit"] * r["ltv_pct"] / 100 * lo),
        g(r["deposit_limit"] * r["ltv_pct"] / 100 * hi)))
    print("      and $0 of it reachable without publishing the position.")

# Every number here is a reading of a chain that moves. Undated, it is a claim; dated, it is a
# measurement somebody can repeat and disagree with.
json.dump({"generated_from": "scripts/capacity.sh",
           "generated_at": __import__("datetime").datetime.now(__import__("datetime").timezone.utc)
                             .strftime("%Y-%m-%d %H:%M:%S UTC"),
           "held_usd": round(held), "borrowed_usd": round(borrowed),
           "authorised_capacity_usd": round(capacity),
           "reachable_confidentially_usd": 0,
           "reserves_priced": len(priced), "reserves_total": len(rows),
           "unpriced": sorted({r["symbol"] for r in unpriced})},
          open("web/capacity.json", "w"), indent=1)
print("\n  wrote web/capacity.json")
PY
