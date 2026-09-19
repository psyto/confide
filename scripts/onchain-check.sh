#!/usr/bin/env bash
# Reproduce the on-chain claims in docs/ONCHAIN.md. No key, no account, no auth — just mainnet.
set -euo pipefail
RPC="${RPC:-https://api.mainnet-beta.solana.com}"

# Two issuers with nothing to do with each other, two mints each. Both use a vanity prefix.
#   Backed / xStocks     — Swiss-issued, own ISIN
#   Backpack Securities  — US CUSIP, "a bona fide security entitlement" in the issuer's own words
# Every mint from both is in web/mints.json; ./scripts/slot-scan.sh checks all of them.
declare -a MINTS=(
  "NVDAx   Xsc9qvGR1efVDFGLrVsmkzv3qi45LTBjeUKSPmx9qEh"
  "TSLAx   XsDoVfqeBukxuZHWhdvWHBhgEHjGNst4MLodqsJHzoB"
  "NVDA.US NVDAVuiB7hwd3m5Wa1JuHNovPaPG6BH1QNztbKFxNjv"
  "AAPL.US AAPLEDt8RpzPgXyhvFzkMBofvFSQw9gpeMCoUdPdLnB8"
)

printf '%-9s %-46s %-12s %s\n' SYMBOL MINT PROGRAM 'confidentialTransferMint.auditorElgamalPubkey'
for row in "${MINTS[@]}"; do
  sym="${row%% *}"; mint="${row##* }"
  curl -s "$RPC" -X POST -H 'Content-Type: application/json' \
    -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getAccountInfo\",\"params\":[\"$mint\",{\"encoding\":\"jsonParsed\"}]}" \
  | python3 -c "
import sys, json
v = json.load(sys.stdin)['result']['value']
info = v['data']['parsed']['info']
prog = 'Token-2022' if v['owner'].startswith('Tokenz') else v['owner']
ct = next((e['state'] for e in info.get('extensions', []) if e['extension'] == 'confidentialTransferMint'), None)
aud = 'extension absent' if ct is None else repr(ct.get('auditorElgamalPubkey'))
print('%-9s %-46s %-12s %s' % ('$sym', '$mint', prog, aud))
"
done
