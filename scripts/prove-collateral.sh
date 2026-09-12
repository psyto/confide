#!/usr/bin/env bash
# Prove a live confidential account holds at least a threshold — over the account's OWN on-chain
# ciphertext, revealing nothing else — and have Solana's ZK program check both proofs.
#
#   ./scripts/prove-collateral.sh <token_account> <threshold_units> [keys.json]
set -euo pipefail
cd "$(dirname "$0")/.."
RPC="${RPC:-https://api.devnet.solana.com}"
ACC="${1:?usage: prove-collateral.sh <token_account> <threshold_units> [keys.json]}"
UNITS="${2:?threshold in whole units}"
KEYS="${3:-account-keys.json}"
THRESHOLD=$(( UNITS * 100000000 ))

rpc() { curl -s "$RPC" -H 'Content-Type: application/json' -d "$1"; }

read -r DEC AVAIL < <(rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getAccountInfo\",\"params\":[\"$ACC\",{\"encoding\":\"jsonParsed\",\"commitment\":\"confirmed\"}]}" \
| python3 -c "
import sys, json
i = json.load(sys.stdin)['result']['value']['data']['parsed']['info']
ct = next(e['state'] for e in i['extensions'] if e['extension'] == 'confidentialTransferAccount')
print(ct['decryptableAvailableBalance'], ct['availableBalance'])
")

PAYER=$(rpc '{"jsonrpc":"2.0","id":1,"method":"getVoteAccounts","params":[{"keepUnstakedDelinquents":false}]}' \
  | python3 -c "import sys,json;print(json.load(sys.stdin)['result']['current'][0]['nodePubkey'])")
BH=$(rpc '{"jsonrpc":"2.0","id":1,"method":"getLatestBlockhash","params":[{"commitment":"finalized"}]}' \
  | python3 -c "import sys,json;print(json.load(sys.stdin)['result']['value']['blockhash'])")

# bash 3.2 on macOS has no mapfile.
TMP=$(mktemp)
cargo run --quiet -p confide-ct --bin prove-collateral -- "$KEYS" "$DEC" "$AVAIL" "$THRESHOLD" "$BH" "$PAYER" > "$TMP"
TX_EQ=$(sed -n '1p' "$TMP"); TX_RANGE=$(sed -n '2p' "$TMP"); rm -f "$TMP"

names=("ciphertext-commitment equality — the commitment and the account hold the same value" \
       "batched range u64 — the surplus over the threshold is non-negative")
ok=0
for i in 0 1; do
  [ "$i" -eq 0 ] && TX="$TX_EQ" || TX="$TX_RANGE"
  printf '\n  %s\n' "${names[$i]}"
  rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"simulateTransaction\",\"params\":[\"$TX\",{\"sigVerify\":false,\"replaceRecentBlockhash\":true,\"encoding\":\"base64\"}]}" \
  | python3 -c "
import sys, json
v = json.load(sys.stdin)['result']['value']
print('    err   :', v['err'])
print('    units :', v['unitsConsumed'])
for l in (v['logs'] or []):
    if 'Program log' in l or 'success' in l or 'Verify' in l: print('   ', l)
raise SystemExit(0 if v['err'] is None else 1)
" && ok=$((ok+1)) || true
done

echo
if [ "$ok" -eq 2 ]; then
  echo "  both accepted. The account holds at least $UNITS units, and the chain checked it"
  echo "  without learning what it holds."
else
  echo "  $ok of 2 accepted"; exit 1
fi
