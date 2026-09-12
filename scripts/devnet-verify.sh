#!/usr/bin/env bash
# Hand Mora's own NAV-floor proof to the live ZK ElGamal Proof Program on Solana devnet.
#
# No signature, no fee, no funded account: simulateTransaction with sigVerify=false and
# replaceRecentBlockhash=true. The fee payer only has to EXIST, because the simulator loads it.
#
#   ./scripts/devnet-verify.sh [devnet_pubkey]     # payer is discovered if omitted
#
# Success = err: None, non-zero units, and a VerifyBatchedRangeProofU64 -> success log.
set -euo pipefail
RPC="${RPC:-https://api.devnet.solana.com}"

# The simulator loads the fee payer, so it must EXIST — but it never signs and is never charged.
# Rather than hardcode an address that devnet resets away (and the faucet now refuses), ask the
# cluster for a validator identity, which by construction exists and holds lamports.
PAYER="${1:-}"
if [ -z "$PAYER" ]; then
  PAYER=$(curl -s "$RPC" -H 'Content-Type: application/json' \
    -d '{"jsonrpc":"2.0","id":1,"method":"getVoteAccounts","params":[{"keepUnstakedDelinquents":false}]}' \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['result']['current'][0]['nodePubkey'])")
  echo "payer : $PAYER  (a live devnet validator identity — pays nothing, signs nothing)"
fi

TX=$(cargo run --quiet -p mora-onchain --bin devnet-verify -- "$PAYER")
curl -s -X POST "$RPC" -H 'Content-Type: application/json' \
  -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"simulateTransaction\",\"params\":[\"$TX\",{\"sigVerify\":false,\"replaceRecentBlockhash\":true,\"encoding\":\"base64\"}]}" \
| python3 -c "
import sys, json
r = json.load(sys.stdin)
if 'error' in r:
    print('RPC error:', r['error']); raise SystemExit(1)
v = r['result']['value']
print('err   :', v['err'])
print('units :', v['unitsConsumed'])
print('logs  :')
for l in (v['logs'] or []): print('   ', l)
raise SystemExit(0 if v['err'] is None else 1)
"
