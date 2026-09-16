#!/usr/bin/env bash
# Which tokenized stocks does Kamino already lend against, and on what terms?
#
#   ./scripts/kamino-reserves.sh
#
# The admission question is not hypothetical. Kamino has live reserves for tokenized equity today,
# with an LTV, a liquidation threshold and a cap already chosen by whoever owns those markets. This
# reads every reserve the program holds, keeps the ones whose liquidity mint is a tokenized stock,
# and decodes the fields a collateral decision turns on.
#
# Layout: scripts/lib/klend_rules.py. Every row re-checks that the decoded mint is the one asked
# for and that the decimals match the mint's own, so a layout change fails instead of quietly
# producing a plausible wrong number.
#
# Writes web/kamino-reserves.json. No key needed.
set -euo pipefail
cd "$(dirname "$0")/.."
RPC="${RPC:-https://api.mainnet-beta.solana.com}"

python3 - "$RPC" <<'PY'
import base64, json, sys, urllib.request
sys.path.insert(0, 'scripts/lib')
import klend_rules as K

RPC = sys.argv[1]
KLEND = "KLend2g3cP87fffoy8q1mQqGKjrxjC8boSyAYavgmjD"
A = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

def b58(b):
    n = int.from_bytes(b, 'big'); s = ""
    while n:
        n, r = divmod(n, 58); s = A[r] + s
    return "1" * (len(b) - len(b.lstrip(b'\0'))) + s

def rpc(method, params):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(RPC, body, {"Content-Type": "application/json", "User-Agent": "confide"})
    r = json.load(urllib.request.urlopen(req, timeout=180))
    if "error" in r:
        print("  the RPC refused: %s" % r["error"].get("message")); raise SystemExit(1)
    return r["result"]

mints = {m["mint"]: m for m in json.load(open("web/mints.json"))}

print("  reading every Kamino reserve…")
accs = rpc("getProgramAccounts", [KLEND, {
    "encoding": "base64", "commitment": "confirmed",
    "filters": [{"memcmp": {"offset": 0, "bytes": b58(K.RESERVE_DISCRIMINATOR)}}]}])
print("  %d reserves across %d markets" % (
    len(accs), len({a["account"]["data"][0][:1] and b58(base64.b64decode(a["account"]["data"][0])[32:64]) for a in accs})))

rows = []
for a in accs:
    data = base64.b64decode(a["account"]["data"][0])
    mint = b58(data[K.OFF_LIQ_MINT:K.OFF_LIQ_MINT + 32])
    if mint not in mints:
        continue
    r = K.decode_reserve(data)
    if b58(r.pop("mint_raw")) != mint:
        print("  the layout moved: the mint did not decode where it was read"); raise SystemExit(1)
    market = b58(r.pop("lending_market_raw"))
    m = mints[mint]
    rows.append(dict(symbol=m["symbol"], issuer=m["issuer"], name=m.get("name"), mint=mint,
                     reserve=a["pubkey"], market=market, **r))

rows.sort(key=lambda r: (r["issuer"], r["symbol"]))
print("\n  %d of them are tokenized stocks — Kamino already lends against these:\n" % len(rows))
print("    %-9s %-9s %4s %4s %10s %10s  %s" % ("SYMBOL", "ISSUER", "LTV", "LIQ", "CAP", "DEPOSITED", "STATUS"))
for r in rows:
    print("    %-9s %-9s %3d%% %3d%% %10s %10s  %s" % (
        r["symbol"], r["issuer"], r["ltv_pct"], r["liquidation_threshold_pct"],
        ("%.0f" % r["deposit_limit"]), ("%.4g" % r["available"]), r["status"]))

from collections import Counter
used = [r for r in rows if r["available"] > 1]
by_issuer = Counter(r["issuer"] for r in used)
print("\n  %d of the %d hold a real balance rather than a seed:" % (len(used), len(rows)))
for iss, n in sorted(by_issuer.items()):
    tot = sum(r["available"] for r in used if r["issuer"] == iss)
    print("    %-9s %2d reserves, %.0f tokens deposited" % (iss, n, tot))
print("\n  So this is not a proposal to lend against tokenized equity. Kamino already does, at LTVs")
print("  its market owners chose. Borrow limit 0 means collateral-only: deposit it, borrow")
print("  something else against it.")
print("\n  And every one of those deposited positions is public. A holder who does not want that has")
print("  one option today, which is not to post the collateral at all — constraints.rs:187 refuses")
print("  the other one.")

json.dump({"generated_from": "scripts/kamino-reserves.sh",
           "klend": {"pin": K.KLEND_PIN, "tag": K.KLEND_TAG},
           "reserves": rows}, open("web/kamino-reserves.json", "w"), indent=1)
print("\n  wrote web/kamino-reserves.json")
PY
