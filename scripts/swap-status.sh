#!/usr/bin/env bash
# Read the devnet swaps back off the chain, for a pane that has to be true when it is recorded.
#
#   ./scripts/swap-status.sh          # all of them
#   ./scripts/swap-status.sh fee      # only the with-fee one
#
# Same job as seizure-status.sh: the video and the page both claim these settled, and a claim that
# outlives the thing it describes is the failure worth engineering against. Devnet resets.
set -euo pipefail
cd "$(dirname "$0")/.."
R="${RPC:-https://api.devnet.solana.com}"
WHICH="${1:-all}"
python3 - "$R" "$WHICH" <<'PY'
import json, subprocess, sys
R, WHICH = sys.argv[1], sys.argv[2]
cfg = json.load(open("web/swaps.json"))
def rpc(m, p):
    b = json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p})
    return json.loads(subprocess.run(["curl","-s","--max-time","60",R,
        "-H","content-type: application/json","-d",b],capture_output=True).stdout).get("result")
G, RED, DIM, OFF, B = "\033[32m", "\033[31m", "\033[2m", "\033[0m", "\033[1m"
bad = 0
for s in cfg["swaps"]:
    if WHICH == "fee" and "PYUSD" not in s["label"]: continue
    if WHICH == "plain" and "PYUSD" in s["label"]: continue
    t = rpc("getTransaction", [s["signature"], {"encoding":"jsonParsed","maxSupportedTransactionVersion":0}])
    print(f"\n  {B}{s['label']}{OFF}")
    if not t:
        print(f"  {RED}gone{OFF} — devnet reset. {s['signature'][:8]}…"); bad += 1; continue
    m = t["transaction"]["message"]
    kinds = [i.get("parsed",{}).get("type","?") for i in m["instructions"]]
    progs = {i["programId"] for i in m["instructions"]}
    print(f"    signature      {s['signature'][:8]}…")
    print(f"    instructions   {len(kinds)}  {', '.join(kinds)}")
    print(f"    programs       {', '.join(p[:8]+'…' for p in progs)}")
    print(f"    compute units  {t['meta']['computeUnitsConsumed']:,}")
    # ONE ENTRY IS SUPPOSED TO HAVE FAILED. The issuance pair is the same allocation sent before and
    # after the issuer signed, and the refusal IS the finding: it must still fail with Custom(24).
    # Counting it as a problem said "the swaps no longer read the way the page says" about the one
    # that reads exactly as it should.
    err = t["meta"]["err"]
    if s.get("expect_err"):
        want = '"Custom": 24' in json.dumps(err) if err else False
        print(f"    error          {RED}{err}{OFF}  {'(expected)' if want else '(NOT the expected one)'}")
        if not want: bad += 1
    else:
        print(f"    error          {err or 'none'}")
        if err: bad += 1
    zero, ata = True, True
    for a in s["accounts"]:
        v = rpc("getAccountInfo", [a, {"encoding":"jsonParsed"}])
        if not v or not v.get("value"): zero = False; continue
        i = v["value"]["data"]["parsed"]["info"]
        if i["tokenAmount"]["uiAmountString"] != "0": zero = False
        if not any(e["extension"] == "immutableOwner" for e in i.get("extensions", [])): ata = False
    print(f"    the 4 accounts {'all associated' if ata else 'NOT all associated'}, "
          f"{'public balance 0 on every one' if zero else 'a public balance is not 0'}")
    if not (zero and ata): bad += 1
print()
if bad:
    print(f"  {RED}{bad} problem(s){OFF} — the swaps no longer read the way the video and the page say")
    sys.exit(1)
print(f"  {G}every swap still reads as recorded{OFF}\n")
PY
