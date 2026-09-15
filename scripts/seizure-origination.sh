#!/usr/bin/env bash
# Put a seizure's three proofs on chain, verified, under an authority the borrower does not hold.
#
#   ./scripts/seizure-origination.sh                    # against a local validator
#   RPC=https://api.devnet.solana.com PAYER=~/.config/solana/id.json ./scripts/seizure-origination.sh
#
# This is origination, the step where the borrower is still cooperative. Afterwards `Transfer` can
# cite these three accounts by address alone, from a CPI the borrower is not party to — see
# docs/SEIZURE.md.
#
# The interesting part is the third proof. A U128 range proof is 1,000 bytes, and once the context
# authority is its own account the verify transaction reaches 1,237 bytes against a 1,232 limit.
# An address lookup table moves that account and the authority out of the static keys, which is why
# this script builds one before it builds the proofs: the table has to name the range context
# account, so that account's address must exist before the proof that goes into it does.
set -euo pipefail
cd "$(dirname "$0")/.."
RPC="${RPC:-http://127.0.0.1:8899}"
PAYER="${PAYER:-}"
BALANCE="${BALANCE:-17300000000000}"           # 173,000 units at 8 decimals — the README's position
AUTHORITY="${AUTHORITY:-SeiZure111111111111111111111111111111111111}"   # stands in for the loan PDA
WORK="${WORK:-$(mktemp -d)}"

rpc() { curl -s "$RPC" -H 'Content-Type: application/json' -d "$1"; }
blockhash() { rpc '{"jsonrpc":"2.0","id":1,"method":"getLatestBlockhash","params":[{"commitment":"confirmed"}]}' \
  | python3 -c "import sys,json;print(json.load(sys.stdin)['result']['value']['blockhash'])"; }

if [ -z "$PAYER" ]; then
  PAYER="$WORK/payer.json"
  solana-keygen new --no-bip39-passphrase --silent --force -o "$PAYER" >/dev/null
  case "$RPC" in *127.0.0.1*|*localhost*) solana -u "$RPC" airdrop 10 "$(solana-keygen pubkey "$PAYER")" >/dev/null;;
    *) echo "  PAYER is unset and $RPC is not local — pass a funded keypair" >&2; exit 1;; esac
fi
echo "  rpc        $RPC"
echo "  payer      $(solana-keygen pubkey "$PAYER")"
echo "  authority  $AUTHORITY   <- whoever holds this can close the proofs; it must not be the borrower"

# Pass one names the context accounts. The proofs it builds are thrown away: the table cannot be
# built until the range account has an address, and the proofs cannot be sent until the table is.
echo
echo "  --- naming the context accounts ---"
cargo run --quiet -p confide-ct --bin seizure-ctx -- \
  "$PAYER" "synthetic:$BALANCE" - - rand rand all "$(blockhash)" "$WORK/ctx.json" \
  "$AUTHORITY" "$WORK/keys" none >/dev/null 2>"$WORK/pass1.err"
grep -E "verify tx 3" "$WORK/pass1.err" | sed 's/^/  /'
RANGE=$(python3 -c "import json;print(json.load(open('$WORK/ctx.json'))['range'])")

echo
echo "  --- the lookup table that buys back the overflow ---"
ALT=$(solana -u "$RPC" -k "$PAYER" address-lookup-table create --authority "$(solana-keygen pubkey "$PAYER")" \
  | grep -oE 'Lookup Table Address: [1-9A-HJ-NP-Za-km-z]{32,44}' | awk '{print $NF}')
solana -u "$RPC" -k "$PAYER" address-lookup-table extend "$ALT" --addresses "$RANGE,$AUTHORITY" >/dev/null
echo "  table      $ALT"
# A table is only usable from a later slot than the one that extended it.
sleep 3

echo
echo "  --- building the proofs and sending them ---"
cargo run --quiet -p confide-ct --bin seizure-ctx -- \
  "$PAYER" "synthetic:$BALANCE" - - rand rand all "$(blockhash)" "$WORK/ctx.json" \
  "$AUTHORITY" "$WORK/keys" "$ALT" > "$WORK/txs.txt" 2>"$WORK/pass2.err"
grep -E "verify tx" "$WORK/pass2.err" | sed 's/^/  /'

# A returned signature means the transaction was accepted, not that it executed. Confirming each
# one is the difference between "sent six transactions" and "six transactions happened".
confirm() {
  for _ in $(seq 1 30); do
    st=$(rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getSignatureStatuses\",\"params\":[[\"$1\"],{\"searchTransactionHistory\":true}]}" \
      | python3 -c "
import sys, json
v = json.load(sys.stdin)['result']['value'][0]
if v is None: print('pending')
elif v.get('err'): print('FAILED ' + json.dumps(v['err'])[:200])
else: print(v.get('confirmationStatus') or 'pending')")
    case "$st" in confirmed|finalized) return 0;; FAILED*) echo "  $st"; return 1;; esac
    sleep 1
  done
  echo "  never confirmed: $1"; return 1
}

n=0
while read -r TX; do
  n=$((n+1))
  SIG=$(rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"sendTransaction\",\"params\":[\"$TX\",{\"encoding\":\"base64\",\"preflightCommitment\":\"confirmed\"}]}" \
  | python3 -c "
import sys, json
r = json.load(sys.stdin)
if 'error' in r:
    print('REJECTED ' + json.dumps(r['error'])[:300]); raise SystemExit(0)
print(r['result'])")
  case "$SIG" in REJECTED*) echo "  tx $n $SIG"; exit 1;; esac
  confirm "$SIG" || { echo "  tx $n did not execute"; exit 1; }
done < "$WORK/txs.txt"
echo "  sent       $n transactions, all confirmed"

echo
echo "  --- read back off the chain, because emitting a transaction is not landing one ---"
python3 - "$WORK/ctx.json" "$RPC" <<'PY'
import json, sys, base64, urllib.request
ALPH = b"123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
def b58(b):
    n = int.from_bytes(b, "big"); out = b""
    while n: n, r = divmod(n, 58); out = ALPH[r:r+1] + out
    return "1" * (len(b) - len(b.lstrip(b"\0"))) + out.decode()
ctx, rpc = json.load(open(sys.argv[1])), sys.argv[2]
def get(a):
    req = urllib.request.Request(rpc, json.dumps({"jsonrpc":"2.0","id":1,"method":"getAccountInfo",
        "params":[a,{"encoding":"base64","commitment":"confirmed"}]}).encode(), {"Content-Type":"application/json"})
    return json.load(urllib.request.urlopen(req))["result"]["value"]
rows = [("equality","ciphertext-commitment equality",3),
        ("validity","grouped ciphertext validity, 3 handles",12),
        ("range","batched range proof U128",7)]
ok = True
for key, label, want in rows:
    v = get(ctx[key])
    if not v:
        print(f"  {label:40} ABSENT"); ok = False; continue
    d = base64.b64decode(v["data"][0])
    good = d[32] == want and b58(d[:32]) == ctx["authority"]
    ok &= good
    print(f"  {label:40} {len(d):4}B  type={d[32]:2}  authority={'as recorded' if b58(d[:32])==ctx['authority'] else 'MISMATCH'}  {'ok' if good else 'BAD'}")
print()
if ok:
    print("  three verified proofs on chain, none of them closable by the borrower.")
    print("  A seizure can now be fired by citing these addresses — no key, no committee, no")
    print("  cooperation. What is left is the Transfer that cites them: docs/SEIZURE.md section 8.")
else:
    print("  SOMETHING IS WRONG"); raise SystemExit(1)
PY
