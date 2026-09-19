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

# Retried, because the public devnet RPC intermittently fails in ways that do not stay local: a
# `getAccountInfo` that came back empty made `spl-token` fall back to the legacy token program and
# the run died four steps later on `IncorrectProgramId`, with nothing to connect it to. Retry here
# rather than debug that again.
#
# Two kinds of non-answer, and both were seen. A body that is not JSON at all (a 429 page), and a
# JSON-RPC error that is about the endpoint rather than the request — those are retried. An error
# about the request itself, a failed simulation above all, is the endpoint answering correctly and
# is passed straight through: retrying it would hide a real failure five times over.
RPC_TRANSIENT='-32005 -32004 -32014 -32603 429'
rpc() {
  local i=0 out
  while [ $i -lt 5 ]; do
    out=$(curl -s --max-time 30 "$R" -H 'Content-Type: application/json' -d "$1")
    case "$(printf '%s' "$out" | python3 -c "
import sys,json
try: d=json.load(sys.stdin)
except Exception: print('retry'); raise SystemExit
if 'result' in d: print('ok')
elif 'error' in d: print('retry' if str(d['error'].get('code')) in '$RPC_TRANSIENT'.split() else 'ok')
else: print('retry')" 2>/dev/null)" in
      ok) printf '%s' "$out"; return 0;;
    esac
    i=$((i+1)); sleep $i
  done
  printf '%s' "$out"; return 1
}
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

# Wait until an account is visible at `finalized`. `go` confirms at `confirmed`, and a lender
# reading the chain conservatively reads at `finalized` — so a check run straight after a
# confirmation sees nothing and says so. This is the gap, waited out explicitly rather than slept
# through.
finalized() {
  local key="$1" i=0 body seen
  body="{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getAccountInfo\",\"params\":[\"$key\",{\"encoding\":\"base64\",\"commitment\":\"finalized\"}]}"
  while [ "$i" -lt 60 ]; do
    seen=$(rpc "$body" | python3 -c "import sys,json;print('no' if json.load(sys.stdin)['result']['value'] is None else 'yes')" 2>/dev/null)
    [ "$seen" = yes ] && return 0
    i=$((i+1)); sleep 2
  done
  return 1
}
