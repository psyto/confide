#!/usr/bin/env bash
# Open a confidential balance with the key we generated for the account.
#   ./scripts/read-balance.sh <token_account> [keys.json]
set -euo pipefail
cd "$(dirname "$0")/.."
RPC="${RPC:-https://api.devnet.solana.com}"
ACC="${1:?usage: read-balance.sh <token_account> [keys.json]}"
KEYS="${2:-account-keys.json}"

# One read gives both ciphertexts, the public amount and the mint's decimals. The decimals were not
# passed until 2026-09-30, so a 6-decimal cash account was reported in 8-decimal units.
read -r DEC AVAIL PUB DECIMALS < <(curl -s "$RPC" -H 'Content-Type: application/json' \
  -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getAccountInfo\",\"params\":[\"$ACC\",{\"encoding\":\"jsonParsed\",\"commitment\":\"confirmed\"}]}" \
| python3 -c "
import sys, json
i = json.load(sys.stdin)['result']['value']['data']['parsed']['info']
ct = next(e['state'] for e in i['extensions'] if e['extension'] == 'confidentialTransferAccount')
print(ct['decryptableAvailableBalance'], ct['availableBalance'], i['tokenAmount']['uiAmountString'], i['tokenAmount']['decimals'])
")
cargo run --quiet -p confide-ct --bin read-balance -- "$KEYS" "$DEC" "$AVAIL" "$DECIMALS" "$PUB"
echo "  explorer           https://explorer.solana.com/address/$ACC?cluster=devnet"
