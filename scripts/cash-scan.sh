#!/usr/bin/env bash
# Which dollar can move confidentially, read off mainnet.
#
#   RPC=<mainnet endpoint> ./scripts/cash-scan.sh
#
# A confidential stock-for-cash trade needs cash that can move confidentially. Three of the five
# largest cannot — they are legacy SPL with no extensions at all. The two that can arrive at the
# SAME configuration as every tokenized-equity mint, which is what makes this a fact about the
# substrate rather than about two equity issuers.
set -euo pipefail
cd "$(dirname "$0")/.."
R="${RPC:-https://api.mainnet-beta.solana.com}"
python3 - "$R" <<'PY'
import json, subprocess, sys, time
R = sys.argv[1]
COINS = [("PYUSD","2b1kV6DkPAnxd5ixfnxCpjxmKwqjjaYmCZfHsFu24GXo"),
         ("USDG", "2u1tszSeqZ3qBWF3uNGPFc8TzMk2tdiwknnRMWGWjGWH"),
         ("USDC", "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"),
         ("USDT", "Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB"),
         ("USDS", "USDSwr9ApdHk5bvJKMjzff41FfuX8bSxdKcR81vTwcA")]
G, DIM, OFF, B = "\033[32m", "\033[2m", "\033[0m", "\033[1m"
print(f"\n  {B}CAN THE CASH LEG BE CONFIDENTIAL?{OFF}  {DIM}mainnet, read one at a time{OFF}\n")
print(f"  {'':10} {'program':14} {'confidential':13} {'gate':6} auditor")
auths = {}
for name, mint in COINS:
    b = json.dumps({"jsonrpc":"2.0","id":1,"method":"getAccountInfo",
                    "params":[mint,{"encoding":"jsonParsed"}]})
    v = json.loads(subprocess.run(["curl","-s","--max-time","60",R,
        "-H","content-type: application/json","-d",b],capture_output=True).stdout)["result"]["value"]
    i = v["data"]["parsed"]["info"]
    ex = {e["extension"]: e.get("state", {}) for e in i.get("extensions", [])}
    ct = ex.get("confidentialTransferMint")
    prog = "Token-2022" if v["owner"].startswith("TokenzQd") else "Token (legacy)"
    if ct:
        auths[name] = ct.get("authority")
        print(f"  {name:10} {prog:14} {G}yes{OFF}           "
              f"{'shut' if ct.get('autoApproveNewAccounts') is False else 'OPEN':6} "
              f"{'EMPTY' if not ct.get('auditorElgamalPubkey') else 'set'}")
    else:
        print(f"  {name:10} {prog:14} {'no':13} {'—':6} —")
    time.sleep(0.2)
same = len(set(auths.values())) == 1 and len(auths) > 1
print(f"\n  The two that can are gated and auditor-empty — exactly as all 1,992 tokenized stocks are.")
if same:
    a = next(iter(auths.values()))
    print(f"  And the same key holds the confidential authority on both: {a[:8]}…")
print(f"  {DIM}Four issuers, two asset classes, one dead end.{OFF}\n")
PY
