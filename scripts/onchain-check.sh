#!/usr/bin/env bash
# Reproduce the on-chain claims in docs/ONCHAIN.md. No key, no account, no auth — just mainnet.
set -euo pipefail
RPC="${RPC:-https://api.mainnet-beta.solana.com}"

# xStocks mints (the "Xs" prefix is the issuer's vanity). Resolve any of them yourself with:
#   curl -s "https://lite-api.jup.ag/tokens/v2/search?query=NVDAx"
declare -a MINTS=(
  "NVDAx Xsc9qvGR1efVDFGLrVsmkzv3qi45LTBjeUKSPmx9qEh"
  "TSLAx XsDoVfqeBukxuZHWhdvWHBhgEHjGNst4MLodqsJHzoB"
  "SPYx  XsoCS1TfEyfFhfvj8EtZ528L3CaKBDBRqRapnBbDF2W"
  "AAPLx XsbEhLAtcf6HdfpFZ5xEMdqW8nfAvcsP5bdudRLJzJp"
)

printf '%-7s %-46s %-12s %s\n' SYMBOL MINT PROGRAM 'confidentialTransferMint.auditorElgamalPubkey'
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
print('%-7s %-46s %-12s %s' % ('$sym', '$mint', prog, aud))
"
done
