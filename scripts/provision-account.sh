#!/usr/bin/env bash
# Stand up a Token-2022 confidential account whose ElGamal key we generate and keep.
#
#   ./scripts/provision-account.sh [amount] [keypair.json]
#
# spl-token derives that key from a wallet signature with a KDF this SDK version does not
# reproduce, so an account the CLI configures is one we can read on chain and cannot prove anything
# about. Generating it here is what lets a range proof be over the account's own availableBalance.
set -euo pipefail
cd "$(dirname "$0")/.."
RPC="${RPC:-https://api.devnet.solana.com}"
AMOUNT="${1:-173000}"
KP="${2:-$HOME/.config/solana/id.json}"
KEYS="${KEYS:-account-keys.json}"
# spl-token wants a .yml path, and we keep the user's global config untouched.
CFG="$(mktemp -d)/solana-config.yml"
printf 'json_rpc_url: %s\nwebsocket_url: ""\nkeypair_path: %s\ncommitment: confirmed\naddress_labels:\n  "11111111111111111111111111111111": System Program\n' "$RPC" "$KP" > "$CFG"

blockhash() {
  curl -s "$RPC" -H 'Content-Type: application/json' \
    -d '{"jsonrpc":"2.0","id":1,"method":"getLatestBlockhash","params":[{"commitment":"finalized"}]}' \
  | python3 -c "import sys,json;print(json.load(sys.stdin)['result']['value']['blockhash'])"
}
send() {
  curl -s "$RPC" -H 'Content-Type: application/json' \
    -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"sendTransaction\",\"params\":[\"$1\",{\"encoding\":\"base64\"}]}" \
  | python3 -c "
import sys, json
r = json.load(sys.stdin)
if 'error' in r:
    print('FAILED:', json.dumps(r['error'])[:400]); raise SystemExit(1)
print(r['result'])"
}
confirm() {
  for _ in $(seq 1 40); do
    st=$(curl -s "$RPC" -H 'Content-Type: application/json' \
      -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getSignatureStatuses\",\"params\":[[\"$1\"]]}" \
      | python3 -c "import sys,json;v=json.load(sys.stdin)['result']['value'][0];print('' if v is None else (v.get('confirmationStatus') or ''))")
    case "$st" in confirmed|finalized) return 0;; esac
    sleep 2
  done
  echo "  not confirmed: $1"; return 1
}
step() {
  local name="$1" tx sig
  tx=$(cargo run --quiet -p mora-ct --bin provision -- "$name" "$KP" "$MINT" "$ACC" "$AMOUNT" "$(blockhash)" "$KEYS")
  sig=$(send "$tx"); confirm "$sig"
  printf '  %-10s %s\n' "$name" "$sig"
  # Each step reads the state the previous one wrote, and "confirmed" is not yet visible to every
  # node the next send might land on.
  sleep 6
}

echo "  --- mint and account, via the CLI (no ZK key involved) ---"
MINT=$(spl-token -C "$CFG" create-token --program-2022 --decimals 8 --enable-confidential-transfers auto 2>&1 \
  | grep -oE 'Address:  *[1-9A-HJ-NP-Za-km-z]{32,44}' | awk '{print $2}')
echo "  mint       $MINT"
spl-token -C "$CFG" create-account "$MINT" >/dev/null
ACC=$(spl-token -C "$CFG" address --token "$MINT" --verbose 2>&1 \
  | grep -oE 'Associated token address: *[1-9A-HJ-NP-Za-km-z]{32,44}' | awk '{print $NF}')
echo "  account    $ACC"
spl-token -C "$CFG" mint "$MINT" "$AMOUNT" >/dev/null
rm -f "$CFG"

echo
echo "  --- configure, deposit, apply: our instructions, our key ---"
step configure
step deposit
step apply

echo
echo "  --- what the chain shows now ---"
curl -s "$RPC" -H 'Content-Type: application/json' \
  -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getAccountInfo\",\"params\":[\"$ACC\",{\"encoding\":\"jsonParsed\",\"commitment\":\"confirmed\"}]}" \
| python3 -c "
import sys, json
i = json.load(sys.stdin)['result']['value']['data']['parsed']['info']
ct = next(e['state'] for e in i['extensions'] if e['extension'] == 'confidentialTransferAccount')
print('  public amount          %s' % i['tokenAmount']['uiAmountString'])
print('  elgamal pubkey         %s' % ct['elgamalPubkey'])
print('  available balance      %s…' % ct['availableBalance'][:44])
"
echo "  keys                   $KEYS  (ours — this is the whole point)"
echo "  explorer               https://explorer.solana.com/address/$ACC?cluster=devnet"
