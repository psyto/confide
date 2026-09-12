#!/usr/bin/env bash
# Bind a disclosure subject to a REAL Token-2022 confidential account on devnet, then read the
# account back and confirm the binding still matches.
#
#   ./scripts/bind-account.sh [token_account_address]
#
# The default is the account this repo provisioned: public balance 0, confidential balance real.
set -euo pipefail
cd "$(dirname "$0")/.."
RPC="${RPC:-https://api.devnet.solana.com}"
ACC="${1:-A1AMyEf1FQYmvdEWSejtHHU6ZKuBh74MRM9LzGfMGWT6}"

read -r AMOUNT ELGAMAL BALANCE < <(curl -s "$RPC" -H 'Content-Type: application/json' \
  -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getAccountInfo\",\"params\":[\"$ACC\",{\"encoding\":\"jsonParsed\",\"commitment\":\"confirmed\"}]}" \
| python3 -c "
import sys, json
v = json.load(sys.stdin)['result']['value']
if not v: print('MISSING MISSING MISSING'); raise SystemExit
i = v['data']['parsed']['info']
ct = next((e['state'] for e in i.get('extensions', []) if e['extension'] == 'confidentialTransferAccount'), None)
if ct is None: print('NOCONF NOCONF NOCONF'); raise SystemExit
print(i['tokenAmount']['uiAmountString'], ct['elgamalPubkey'], ct['availableBalance'])
")

if [ "$ELGAMAL" = "MISSING" ] || [ "$ELGAMAL" = "NOCONF" ]; then
  echo "  no confidential account at $ACC"; exit 1
fi

echo "  read from devnet, just now:"
cargo run --quiet -p mora-onchain --bin bind-account -- "$ACC" "$ELGAMAL" "$BALANCE" "$AMOUNT"

echo "  explorer           https://explorer.solana.com/address/$ACC?cluster=devnet"
echo
echo "  --- read it again and check the binding holds ---"
read -r A2 E2 B2 < <(curl -s "$RPC" -H 'Content-Type: application/json' \
  -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getAccountInfo\",\"params\":[\"$ACC\",{\"encoding\":\"jsonParsed\",\"commitment\":\"confirmed\"}]}" \
| python3 -c "
import sys, json
i = json.load(sys.stdin)['result']['value']['data']['parsed']['info']
ct = next(e['state'] for e in i['extensions'] if e['extension'] == 'confidentialTransferAccount')
print(i['tokenAmount']['uiAmountString'], ct['elgamalPubkey'], ct['availableBalance'])
")
if [ "$E2" = "$ELGAMAL" ] && [ "$B2" = "$BALANCE" ]; then
  echo "  elgamal pubkey     matches"
  echo "  ciphertext         matches"
  echo "  public balance     $A2  — still nothing, to anyone who looks"
else
  echo "  MISMATCH — the account moved between reads"; exit 1
fi
