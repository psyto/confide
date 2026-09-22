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
  # THE SELECTION RULE, stated because the last one was stated falsely. The comment here used to
  # say "chosen to have holders rather than alphabetically" -- and two of the six, AAPL.US and
  # TSLA.US, had ZERO token accounts. Backpack contributed nothing to the headline for days while
  # its live mints held tens of thousands, and nothing failed, because a mint with no accounts adds
  # zero and zero looks like agreement.
  #
  # The rule now: TWO PER ISSUER, each verified non-empty, preferring names a reader recognises.
  # Recognisability is a real criterion and is admitted as one -- picking by supply instead puts
  # AMBRx and HRZRBx at the top, which measures the same thing and tells a reader nothing.
  #
  #   Backed     AAPLx, NVDAx        Apple and NVIDIA
  #   PreStocks  SPACEX, ANTHROPIC   the two nobody can buy on an exchange
  #   Backpack   AMC.US, SPCX.US     verified non-empty 2026-09-22
  #
  # SPCX.US was absent for exactly as long as it was unreadable, which made the most traded
  # tokenized equity on Solana the one mint this scan could not measure. scripts/lib/gpa.py reads
  # it now by partitioning on the first byte of the owner field. An unreadable mint is still
  # reported rather than counted as zero.
  MINTS=(XsbEhLAtcf6HdfpFZ5xEMdqW8nfAvcsP5bdudRLJzJp \
         Xsc9qvGR1efVDFGLrVsmkzv3qi45LTBjeUKSPmx9qEh \
         PreANxuXjsy2pvisWWMNB6YaJNzr7681wJJr2rHsfTh \
         Pren1FvFX6J3E4kXhJuCiAD5aDmGEb7qJRncwA8Lkhw \
         AMC1qwR9KhiyrQBRPrxnfo4JfMeMZqEBvt5tgTytNNoc \
         SPCXxcqXj6e5dJDVNovHN8744zkbhM2bYudU45BimGb)
fi

RPC="$R" T22="$T22" OUT="$OUT" python3 - "${MINTS[@]}" <<'PY'
import json, os, subprocess, sys, time
sys.path.insert(0, "scripts/lib")
from gpa import token_accounts      # partitions a mint too large to answer in one response
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

rows, total_accounts, total_conf, total_appr, empty = [], 0, 0, 0, []
print(f"\n  \033[1mIS ANYBODY THROUGH THE GATE?\033[0m {DIM}accounts, not mints{OFF}\n")
for mint in sys.argv[1:]:
    sym, issuer = SYMS.get(mint, ("?", "?"))
    # Partitioned when the whole set will not come back -- scripts/lib/gpa.py. SPCX.US is the
    # reason: the most traded tokenized equity on Solana, and the one mint this scan could not read.
    try:
        got = token_accounts(RPC, mint, offset=0, length=0)
    except RuntimeError as e:
        print(f"  {sym:10} {RED}{e}{OFF}")
        sys.exit(1)
    accs = got
    # Zero accounts is not a measurement, it is an absence, and an absence that adds zero to a
    # total is invisible. This is the bug that let two dead Backpack mints sit in the sample.
    if not accs:
        print(f"  {sym:10} {issuer:10} {RED}no token accounts at all{OFF} — it cannot answer a "
              f"question about accounts, and it is not counted as agreement")
        empty.append(sym)
    # 456 is the floor for an account carrying ConfidentialTransferAccount: 165 base, an account
    # type byte, a 4-byte TLV header and 286 bytes of extension. 400 is under it on purpose.
    big = [a["pubkey"] for a in accs if (a["space"] or 0) >= 400]
    # CONFIGURED AND APPROVED ARE NOT THE SAME COUNT, and on 2026-09-22 the difference became the
    # whole finding. Two NVDAx accounts carry the extension and neither is approved, so neither can
    # receive a confidential transfer -- the issuer has not signed. This counted only the extension,
    # so the day somebody configured one it would have reported the headline broken when what had
    # happened was that somebody knocked.
    conf, appr = [], []
    for key in big:
        d = rpc({"jsonrpc": "2.0", "id": 1, "method": "getAccountInfo",
                 "params": [key, {"encoding": "jsonParsed"}]})["result"]["value"]["data"]["parsed"]["info"]
        ct = next((e for e in d.get("extensions", [])
                   if e["extension"] == "confidentialTransferAccount"), None)
        if ct:
            conf.append(key)
            if ct.get("state", {}).get("approved"):
                appr.append(key)
        time.sleep(0.4)
    total_accounts += len(accs)
    total_conf += len(conf)
    total_appr += len(appr)
    mark = f"{RED}{len(conf)}{OFF}" if conf else f"{GREEN}0{OFF}"
    amark = f"{RED}{len(appr)}{OFF}" if appr else f"{GREEN}0{OFF}"
    print(f"  {sym:10} {issuer:10} {len(accs):7} accounts   {len(big):3} over 400 bytes   "
          f"{mark} configured   {amark} approved")
    rows.append({"mint": mint, "symbol": sym, "issuer": issuer,
                 "accounts": len(accs), "over_400_bytes": len(big),
                 "confidential_accounts": len(conf), "confidential": conf,
                 "approved_accounts": len(appr), "approved": appr})
    time.sleep(1)

if empty:
    print(f"\n  {RED}{len(empty)} of the sampled mints are empty: {', '.join(empty)}{OFF}")
    print("  Fix the sample rather than publishing a total that silently excludes an issuer.")
    sys.exit(1)
print(f"\n  {total_accounts} token accounts across {len(rows)} mints, "
      f"\033[1m{total_conf}\033[0m configured for confidential transfers, "
      f"\033[1m{total_appr}\033[0m approved by an issuer\n")
json.dump({"generated_utc": time.strftime("%Y-%m-%d %H:%M:%S UTC", time.gmtime()),
           "note": "Accounts, not mints. Counts token accounts per mint and how many carry the "
                   "ConfidentialTransferAccount extension. Size is the cheap filter; the extension "
                   "list is what decides.",
           "rpc": RPC, "total_accounts": total_accounts,
           "total_confidential_accounts": total_conf,
           "total_approved_accounts": total_appr, "mints": rows},
          open(OUT, "w"), indent=1)
print(f"  written to {OUT}\n")
PY
