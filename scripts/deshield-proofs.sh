#!/usr/bin/env bash
# The two proofs a de-shield needs, checked by Solana's live ZK ElGamal Proof Program.
#
#   ./scripts/deshield-proofs.sh                              # a throwaway escrow; no keys needed
#   ./scripts/deshield-proofs.sh <token_account> <amount|all> [keys.json]
#
# This composes the two proofs and has the live ZK program check them. It does NOT de-shield:
# instruction 2 of the seizure program is disabled and returns an error, because the loan record
# has no room for these proof contexts or the amount, and without them a caller could de-shield
# one token, mark the loan settled and strand the rest.
#
# The design also needs a correction the proofs cannot supply. `Withdraw` makes the balance public
# but does not change the account's owner, which stays the loan PDA — so an ordinary SPL transfer
# CANNOT move it. Releasing the collateral needs this program to transfer it to a recorded
# destination. See docs/SEIZURE.md section 4d.
set -euo pipefail
cd "$(dirname "$0")/.."
RPC="${RPC:-https://api.devnet.solana.com}"
rpc() { curl -s "$RPC" -H 'Content-Type: application/json' -d "$1"; }

if [ $# -eq 0 ]; then
  KEYS="synthetic:17300000000000"; DEC="-"; AVAIL="-"; AMOUNT="all"
  echo "  escrow : generated for this run — no account, no keys, no funding"
else
  ACC="${1:?usage: deshield-proofs.sh [<token_account> <amount|all> [keys.json]]}"
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

PAYER=$(rpc '{"jsonrpc":"2.0","id":1,"method":"getVoteAccounts","params":[{"keepUnstakedDelinquents":false}]}' \
  | python3 -c "import sys,json;print(json.load(sys.stdin)['result']['current'][0]['nodePubkey'])")

TMP=$(mktemp)
cargo run --quiet -p confide-ct --bin build-deshield-proofs -- "$KEYS" "$DEC" "$AVAIL" "$AMOUNT" "$PAYER" > "$TMP"
names=("ciphertext-commitment equality — what is left is the balance the range proof is over" \
       "batched range u64 — the remainder did not underflow")
ok=0
for i in 0 1; do
  TX=$(sed -n "$((i+1))p" "$TMP")
  printf '\n  %s\n' "${names[$i]}"
  rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"simulateTransaction\",\"params\":[\"$TX\",{\"sigVerify\":false,\"replaceRecentBlockhash\":true,\"encoding\":\"base64\"}]}" \
  | python3 -c "
import sys, json
v = json.load(sys.stdin)['result']['value']
print('    err   :', v['err'])
print('    units :', v['unitsConsumed'])
raise SystemExit(0 if v['err'] is None else 1)
" && ok=$((ok+1)) || true
done
rm -f "$TMP"
echo
[ "$ok" -eq 2 ] && echo "  both accepted. The collateral can be made public on default without naming
  who will take it — docs/SEIZURE.md section 4d." || { echo "  $ok of 2 accepted"; exit 1; }
