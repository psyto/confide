#!/usr/bin/env bash
# Write web/loans.json: which devnet loans the page should read, and what each one demonstrates.
#
#   ./scripts/refresh-loans.sh [loan ...]
#
# The page does NOT trust this file for the outcome. It reads each loan account off devnet in the
# visitor's browser and decodes the flags itself — this file only says which accounts to look at
# and what they were meant to show. If a run here disagrees with what the chain says, the page
# shows the chain and this file is what was wrong.
#
# Two loans, because the escrow has two exits and one loan can only take one of them:
#   26QJWCRw…  the lender took the collateral on an undisputed default
#   9yfKfFD5…  the holder got it back on an attested release
set -euo pipefail
cd "$(dirname "$0")/.."
RPC="${RPC:-https://api.devnet.solana.com}"
PROGRAM="${PROGRAM:-Gn3rzw8ULVo676ebnxX6qK3YEQP9T8NHtFVetXW8QduN}"
LOANS=("${@:-26QJWCRwvPd1dLwvgH4Drb8D5F4ga2RPMdS8PrbRw4Hj 9yfKfFD5ixUeoEGZxN3fxAwRW2rzWB74R5sexzsYiMJo}")

RPC="$RPC" PROGRAM="$PROGRAM" python3 - ${LOANS[@]} <<'PY'
import base64, json, os, sys, urllib.request, datetime

rpc, program = os.environ["RPC"], os.environ["PROGRAM"]
# Mirrors programs/confide-seizure/src/lib.rs. Kept here rather than in the page so the browser
# reads offsets that came from one place; docs-consistency checks them against the Rust.
OFF = {"escrow": 1, "destination": 33, "mint": 65, "oracle": 193,
       "q_min": 225, "principal": 233, "ratio_bps": 241,
       "seized": 414, "release_destination": 447, "released": 739}
V1, V2 = 415, 740

def get(a):
    b = json.dumps({"jsonrpc": "2.0", "id": 1, "method": "getAccountInfo",
                    "params": [a, {"encoding": "base64"}]}).encode()
    r = urllib.request.Request(rpc, b, {"Content-Type": "application/json"})
    return json.load(urllib.request.urlopen(r, timeout=30))["result"]["value"]

out = []
for loan in sys.argv[1:]:
    v = get(loan)
    if not v:
        print("  %s — no account on %s" % (loan, rpc)); raise SystemExit(1)
    d = base64.b64decode(v["data"][0])
    if len(d) < V1:
        print("  %s — %d bytes, shorter than a loan record" % (loan, len(d))); raise SystemExit(1)
    b58 = lambda off: __import__("base58").b58encode(d[off:off+32]).decode() if False else None
    # base58 without a dependency: the addresses are already known to the RPC, so ask it instead of
    # re-implementing an encoder that would be one more thing to get subtly wrong.
    import struct
    def addr(off):
        raw = d[off:off+32]
        alphabet = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
        n = int.from_bytes(raw, "big"); s = ""
        while n: n, r = divmod(n, 58); s = alphabet[r] + s
        return "1" * len(raw[:len(raw) - len(raw.lstrip(b"\0"))]) + s
    u64 = lambda off: struct.unpack_from("<Q", d, off)[0]
    seized = d[OFF["seized"]] != 0
    released = len(d) >= V2 and d[OFF["released"]] != 0
    out.append({
        "loan": loan, "bytes": len(d), "version": 2 if len(d) >= V2 else 1,
        "escrow": addr(OFF["escrow"]), "mint": addr(OFF["mint"]),
        "lender_destination": addr(OFF["destination"]),
        "holder_destination": addr(OFF["release_destination"]) if len(d) >= V2 else None,
        "q_min": u64(OFF["q_min"]), "principal_cents": u64(OFF["principal"]),
        "ratio_bps": u64(OFF["ratio_bps"]),
        "seized": seized, "released": released,
        "outcome": "seized" if seized else "released" if released else "open",
    })
    print("  %s  %d bytes  %s" % (loan[:12] + "…", len(d), out[-1]["outcome"]))

json.dump({"program": program,
           "generated_utc": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC"),
           "offsets": OFF, "len_v1": V1, "len_v2": V2,
           "note": "Which devnet loans the page reads. The page decodes the flags off the chain "
                   "itself; this file does not decide the outcome.",
           "loans": out},
          open("web/loans.json", "w"), indent=1)
print("  wrote web/loans.json")
PY
