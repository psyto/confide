# Talking to a Solana RPC from bash, once.
#
# These were defined inside seizure-e2e.sh and nothing else could use them, so the borrower's and
# the lender's halves would each have grown a copy. Sourced rather than duplicated:
#
#   R="$RPC" . scripts/lib/chain.sh
#
# `R` is the RPC url and must be set before sourcing. Every function here reads it.
#
#   bh        latest blockhash
#   send      submit a base64 transaction, print the signature or `ERR …`
#   confirm   wait for a signature, print the failure if it fails
#   go        send + confirm + a labelled line, non-zero if either step fails
#   ct        a confidential token account: decryptable, available, public amount, owner

rpc() { curl -s "$R" -H 'Content-Type: application/json' -d "$1"; }
bh() { rpc '{"jsonrpc":"2.0","id":1,"method":"getLatestBlockhash","params":[{"commitment":"confirmed"}]}' \
  | python3 -c "import sys,json;print(json.load(sys.stdin)['result']['value']['blockhash'])"; }
send() { rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"sendTransaction\",\"params\":[\"$1\",{\"encoding\":\"base64\",\"preflightCommitment\":\"confirmed\"}]}" \
  | python3 -c "
import sys,json
r=json.load(sys.stdin)
print('ERR '+json.dumps(r['error'])[:300] if 'error' in r else r['result'])"; }
confirm() { for _ in $(seq 1 40); do st=$(rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getSignatureStatuses\",\"params\":[[\"$1\"],{\"searchTransactionHistory\":true}]}" \
  | python3 -c "
import sys,json
v=json.load(sys.stdin)['result']['value'][0]
print('pending' if v is None else ('FAILED '+json.dumps(v['err'])[:250] if v.get('err') else (v.get('confirmationStatus') or 'pending')))"); \
  case "$st" in confirmed|finalized) return 0;; FAILED*) echo "    $st"; return 1;; esac; sleep 1; done; echo "    timeout"; return 1; }
go() { local label="$1"; shift; local sig; sig=$(send "$1"); case "$sig" in ERR*) echo "    $label: $sig"; return 1;; esac; confirm "$sig" && printf '    %-22s ok\n' "$label"; }
ct() { rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getAccountInfo\",\"params\":[\"$1\",{\"encoding\":\"jsonParsed\",\"commitment\":\"confirmed\"}]}" \
  | python3 -c "
import sys,json
i=json.load(sys.stdin)['result']['value']['data']['parsed']['info']
s=next(e['state'] for e in i['extensions'] if e['extension']=='confidentialTransferAccount')
print(s['decryptableAvailableBalance'], s['availableBalance'], i['tokenAmount']['uiAmountString'], i['owner'])"; }
# FEE is read off the mint rather than inferred from FEE_BPS, so this also tells the truth when a
# PROGRAM and MINT from a previous run are reused. A confidential account on a fee-bearing mint
# needs room for ConfidentialTransferFeeAmount, and without it ConfigureAccount fails three
# instructions away from anything that mentions fees.
mint_charges_fee() {
  rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getAccountInfo\",\"params\":[\"$1\",{\"encoding\":\"jsonParsed\"}]}" \
  | python3 -c "
import sys,json
v=json.load(sys.stdin)['result']['value']
ex=v['data']['parsed']['info'].get('extensions',[]) if v else []
print('fee' if any(e['extension']=='transferFeeConfig' for e in ex) else 'nofee')"
}
