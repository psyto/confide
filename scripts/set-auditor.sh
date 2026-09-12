#!/usr/bin/env bash
# Fill the slot every xStock leaves empty — on a mint we control, since Backed's are not ours.
#
#   ./scripts/set-auditor.sh <mint> [keypair.json]
#
# Writes the auditor's ElGamal secret next to you, because a key nobody holds discloses nothing.
set -euo pipefail
cd "$(dirname "$0")/.."
RPC="${RPC:-https://api.devnet.solana.com}"
MINT="${1:?usage: set-auditor.sh <mint> [keypair.json]}"
KP="${2:-$HOME/.config/solana/id.json}"
OUT="${AUDITOR_OUT:-auditor-key.json}"

BH=$(curl -s "$RPC" -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","id":1,"method":"getLatestBlockhash","params":[{"commitment":"finalized"}]}' \
  | python3 -c "import sys,json;print(json.load(sys.stdin)['result']['value']['blockhash'])")

TX=$(cargo run --quiet -p mora-ct --bin set-auditor -- "$KP" "$MINT" "$BH" "$OUT")
SIG=$(curl -s "$RPC" -H 'Content-Type: application/json' \
  -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"sendTransaction\",\"params\":[\"$TX\",{\"encoding\":\"base64\"}]}" \
| python3 -c "
import sys, json
r = json.load(sys.stdin)
if 'error' in r:
    print('SEND FAILED:', json.dumps(r['error'])[:300]); raise SystemExit(1)
print(r['result'])")
echo "  signature       $SIG"

printf '  confirming      '
for _ in $(seq 1 30); do
  st=$(curl -s "$RPC" -H 'Content-Type: application/json' \
    -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getSignatureStatuses\",\"params\":[[\"$SIG\"]]}" \
    | python3 -c "import sys,json;v=json.load(sys.stdin)['result']['value'][0];print('' if v is None else (v.get('confirmationStatus') or ''))")
  case "$st" in confirmed|finalized) echo "$st"; break;; esac
  printf '.'; sleep 2
done

echo
echo "  --- read the mint back ---"
curl -s "$RPC" -H 'Content-Type: application/json' \
  -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getAccountInfo\",\"params\":[\"$MINT\",{\"encoding\":\"jsonParsed\",\"commitment\":\"confirmed\"}]}" \
| python3 -c "
import sys, json
i = json.load(sys.stdin)['result']['value']['data']['parsed']['info']
ct = next(e['state'] for e in i['extensions'] if e['extension'] == 'confidentialTransferMint')
k = ct.get('auditorElgamalPubkey')
print('  auditorElgamalPubkey   %s' % (k or 'None'))
print('  %s' % ('the slot every live xStock leaves empty is filled on this mint'
                if k else 'still empty — the update did not take'))
"
