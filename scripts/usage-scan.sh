#!/usr/bin/env bash
# Is the confidential-transfer capability actually USED on any of these mints?
#
#   ./scripts/usage-scan.sh                 # a sample across all three issuers
#   ./scripts/usage-scan.sh <mint> [mint…]  # named mints
#
# Every other measurement in this repository is about how the MINTS are configured. This one is
# about the ACCOUNTS, and it answers a question the configuration cannot: the feature is shipped on
# 1,992 mints and gated on all of them — has anybody got through the gate?
#
# Method: every token account for the mint, size only. A Token-2022 account is 165 bytes plus its
# extensions, and `ConfidentialTransferAccount` is 286 bytes on its own, so nothing under ~456
# bytes can be one. The large ones are then read properly, because size is suggestive and the
# extension list is not — the first run found seven large accounts on Apple xStock and every one of
# them was large for `pausableAccount` and `transferHookAccount` instead.
#
# Needs an endpoint that serves getProgramAccounts. The founder's Alchemy plan refuses it on
# compute units; the public mainnet endpoint answers it.
set -euo pipefail
cd "$(dirname "$0")/.."
R="${RPC:-https://api.mainnet-beta.solana.com}"
T22=TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb
OUT="${OUT:-web/usage.json}"

# `--last` reprints the stored result instead of re-scanning. The scan reads every token account
# of every mint and takes minutes, which is fine for a weekly measurement and wrong for a video
# render that runs it eight times an evening. The stored file carries its own timestamp, so the
# pane says when it was measured rather than implying it was measured now.
if [ "${1:-}" = "--last" ]; then
  [ -f "$OUT" ] || { echo "  $OUT is missing — run ./scripts/usage-scan.sh" >&2; exit 1; }
  python3 - <<'PY'
import json
u = json.load(open("web/usage.json"))
G, DIM, OFF, B = "\033[32m", "\033[2m", "\033[0m", "\033[1m"
print(f"\n  {B}IS ANYBODY THROUGH THE GATE?{OFF}  {DIM}measured {u['generated_utc']}{OFF}\n")
for m in u["mints"]:
    if not m["accounts"]:
        print(f"  {m['symbol']:10} {m['issuer']:10} {DIM}no token accounts — nothing was ever minted{OFF}")
        continue
    print(f"  {m['symbol']:10} {m['issuer']:10} {m['accounts']:>7,} accounts   "
          f"{G}{m['confidential_accounts']}{OFF} confidential")
print(f"\n  {u['total_accounts']:,} token accounts, "
      f"{B}{u['total_confidential_accounts']}{OFF} configured for confidential transfers\n")
PY
  exit 0
fi

MINTS=("$@")
if [ ${#MINTS[@]} -eq 0 ]; then
  # Two per issuer, chosen to have holders rather than alphabetically. The first sample took the
  # first Backpack mints by name and both had ZERO token accounts — a mint with no holders cannot
  # answer a question about holders, and it would have padded the total with nothing.
  MINTS=(XsbEhLAtcf6HdfpFZ5xEMdqW8nfAvcsP5bdudRLJzJp \
         Xsc9qvGR1efVDFGLrVsmkzv3qi45LTBjeUKSPmx9qEh \
         AAPLEDt8RpzPgXyhvFzkMBofvFSQw9gpeMCoUdPdLnB8 \
         TSLAqBbv4CNCnzWFeB7LmydAyEiNMJtve7DYKLpdK4S \
         PreANxuXjsy2pvisWWMNB6YaJNzr7681wJJr2rHsfTh \
         Pren1FvFX6J3E4kXhJuCiAD5aDmGEb7qJRncwA8Lkhw)
fi

RPC="$R" T22="$T22" OUT="$OUT" python3 - "${MINTS[@]}" <<'PY'
import json, os, subprocess, sys, time
RPC, T22, OUT = os.environ["RPC"], os.environ["T22"], os.environ["OUT"]
SYMS = {m["mint"]: (m["symbol"], m["issuer"]) for m in json.load(open("web/mints.json"))}
GREEN, RED, DIM, OFF = "\033[32m", "\033[31m", "\033[2m", "\033[0m"

def rpc(body):
    out = subprocess.run(["curl", "-s", "--max-time", "180", RPC,
                          "-H", "content-type: application/json", "-d", json.dumps(body)],
                         capture_output=True).stdout
    try:
        return json.loads(out)
    except Exception:
        return {"error": {"message": out[:120].decode("utf8", "replace")}}

rows, total_accounts, total_conf = [], 0, 0
print(f"\n  \033[1mIS ANYBODY THROUGH THE GATE?\033[0m {DIM}accounts, not mints{OFF}\n")
for mint in sys.argv[1:]:
    sym, issuer = SYMS.get(mint, ("?", "?"))
    r = rpc({"jsonrpc": "2.0", "id": 1, "method": "getProgramAccounts", "params": [T22, {
        "encoding": "base64", "dataSlice": {"offset": 0, "length": 0},
        "filters": [{"memcmp": {"offset": 0, "bytes": mint}}]}]})
    if "error" in r:
        print(f"  {sym:10} {RED}error{OFF} {r['error'].get('message','')[:70]}")
        sys.exit(1)
    accs = r["result"]
    # 456 is the floor for an account carrying ConfidentialTransferAccount: 165 base, an account
    # type byte, a 4-byte TLV header and 286 bytes of extension. 400 is under it on purpose.
    big = [a["pubkey"] for a in accs if a["account"]["space"] >= 400]
    conf = []
    for key in big:
        d = rpc({"jsonrpc": "2.0", "id": 1, "method": "getAccountInfo",
                 "params": [key, {"encoding": "jsonParsed"}]})["result"]["value"]["data"]["parsed"]["info"]
        if any(e["extension"] == "confidentialTransferAccount" for e in d.get("extensions", [])):
            conf.append(key)
        time.sleep(0.4)
    total_accounts += len(accs)
    total_conf += len(conf)
    mark = f"{RED}{len(conf)}{OFF}" if conf else f"{GREEN}0{OFF}"
    print(f"  {sym:10} {issuer:10} {len(accs):7} accounts   {len(big):3} over 400 bytes   "
          f"{mark} confidential")
    rows.append({"mint": mint, "symbol": sym, "issuer": issuer,
                 "accounts": len(accs), "over_400_bytes": len(big),
                 "confidential_accounts": len(conf), "confidential": conf})
    time.sleep(1)

print(f"\n  {total_accounts} token accounts across {len(rows)} mints, "
      f"\033[1m{total_conf}\033[0m configured for confidential transfers\n")
json.dump({"generated_utc": time.strftime("%Y-%m-%d %H:%M:%S UTC", time.gmtime()),
           "note": "Accounts, not mints. Counts token accounts per mint and how many carry the "
                   "ConfidentialTransferAccount extension. Size is the cheap filter; the extension "
                   "list is what decides.",
           "rpc": RPC, "total_accounts": total_accounts,
           "total_confidential_accounts": total_conf, "mints": rows},
          open(OUT, "w"), indent=1)
print(f"  written to {OUT}\n")
PY
