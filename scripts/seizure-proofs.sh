#!/usr/bin/env bash
# Build the three proofs a confidential transfer needs — at origination, for a seizure the borrower
# will not be around to authorise — and have Solana's live ZK ElGamal Proof Program check all three.
#
#   ./scripts/seizure-proofs.sh                                  # a throwaway escrow; no keys needed
#   ./scripts/seizure-proofs.sh <token_account> <amount|all> [keys.json]
#
# The first form settles the question this step exists to settle: do the three proofs compose, and
# does the live program accept them? That is a fact about the proof system, so a throwaway escrow
# answers it. The second form is the same proofs over a real account's own on-chain ciphertext, and
# needs the holder's keys — which is the point of confidential balances and is not a limitation.
#
# See docs/SEIZURE.md.
set -euo pipefail
cd "$(dirname "$0")/.."
RPC="${RPC:-https://api.devnet.solana.com}"

rpc() { curl -s "$RPC" -H 'Content-Type: application/json' -d "$1"; }

if [ $# -eq 0 ]; then
  KEYS="synthetic:17300000000000"   # 173,000 units at 8 decimals — the README's position
  DEC="-"; AVAIL="-"; AMOUNT="all"
  echo "  escrow : generated for this run — no account, no keys, no funding"
else
  ACC="${1:?usage: seizure-proofs.sh [<token_account> <amount|all> [keys.json]]}"
  AMOUNT="${2:?amount in base units, or 'all'}"
  KEYS="${3:-account-keys.json}"
  [ -f "$KEYS" ] || { echo "  $KEYS not found — a real escrow needs the holder's keys" >&2; exit 1; }
  read -r DEC AVAIL < <(rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getAccountInfo\",\"params\":[\"$ACC\",{\"encoding\":\"jsonParsed\",\"commitment\":\"confirmed\"}]}" \
  | python3 -c "
import sys, json
i = json.load(sys.stdin)['result']['value']['data']['parsed']['info']
ct = next(e['state'] for e in i['extensions'] if e['extension'] == 'confidentialTransferAccount')
print(ct['decryptableAvailableBalance'], ct['availableBalance'])
")
  echo "  escrow : $ACC  (ciphertexts read from chain)"
fi

# The lender's key and the mint's auditor key. A real loan registers the first and reads the second
# off the mint; `rand` generates them here so both handles in the validity proof are genuine keys.
LENDER="${LENDER:-rand}"
AUDITOR="${AUDITOR:-rand}"

PAYER=$(rpc '{"jsonrpc":"2.0","id":1,"method":"getVoteAccounts","params":[{"keepUnstakedDelinquents":false}]}' \
  | python3 -c "import sys,json;print(json.load(sys.stdin)['result']['current'][0]['nodePubkey'])")

TMP=$(mktemp)
cargo run --quiet -p confide-ct --bin build-seizure-proofs -- \
  "$KEYS" "$DEC" "$AVAIL" "$LENDER" "$AUDITOR" "$AMOUNT" "$PAYER" > "$TMP"
TX_EQ=$(sed -n '1p' "$TMP"); TX_VA=$(sed -n '2p' "$TMP"); TX_RP=$(sed -n '3p' "$TMP"); rm -f "$TMP"

names=("ciphertext-commitment equality — the remaining balance the range proof is over is the account's" \
       "batched grouped ciphertext validity, 3 handles — source, lender AND auditor can each read the amount" \
       "batched range u128 — remaining balance non-negative, both amount halves in range")
ok=0
for i in 0 1 2; do
  case $i in 0) TX="$TX_EQ";; 1) TX="$TX_VA";; 2) TX="$TX_RP";; esac
  printf '\n  %s\n' "${names[$i]}"
  rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"simulateTransaction\",\"params\":[\"$TX\",{\"sigVerify\":false,\"replaceRecentBlockhash\":true,\"encoding\":\"base64\"}]}" \
  | python3 -c "
import sys, json
v = json.load(sys.stdin)['result']['value']
print('    err   :', v['err'])
print('    units :', v['unitsConsumed'])
for l in (v['logs'] or []):
    if 'Verify' in l or 'success' in l or 'failed' in l: print('   ', l)
raise SystemExit(0 if v['err'] is None else 1)
" && ok=$((ok+1)) || true
done

echo
if [ "$ok" -eq 3 ]; then
  echo "  all three accepted by the live ZK program. These are the proofs a seizure needs, built"
  echo "  while the borrower cooperates; docs/SEIZURE.md section 2 is what fires them later."
else
  echo "  $ok of 3 accepted"; exit 1
fi
