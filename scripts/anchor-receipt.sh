#!/usr/bin/env bash
# Anchor a sealed obligation's commitment on Solana devnet, then read it back off the chain.
#
# This is t0 — the reporting date. What lands on-chain is 32 content-blind bytes and the date the
# obligation comes due. No position, no portfolio, nothing about the fund's holdings.
#
#   ./scripts/anchor-receipt.sh [keypair.json]
#
# Requires a devnet-funded keypair (default ~/.config/solana/id.json).
set -euo pipefail
cd "$(dirname "$0")/.."
RPC="${RPC:-https://api.devnet.solana.com}"
KP="${1:-$HOME/.config/solana/id.json}"
PROGRAM=6a1Kd8Yo5U9wMXUtMnU1PZF8xy6wJ6zWyMr7uKNAHytv

rpc() { curl -s "$RPC" -H 'Content-Type: application/json' -d "$1"; }

BLOCKHASH=$(rpc '{"jsonrpc":"2.0","id":1,"method":"getLatestBlockhash","params":[{"commitment":"finalized"}]}' \
  | python3 -c "import sys,json;print(json.load(sys.stdin)['result']['value']['blockhash'])")

echo "  program     $PROGRAM  (aperture-receipts on devnet)"

# ONE run. Each run seals a fresh obligation under fresh keys, so running it twice would give a
# transaction and a PDA that belong to different obligations — and the read-back below would look
# for a receipt that was never written.
INFO=$(mktemp)
TX=$(cargo run --quiet -p confide-onchain --bin anchor-receipt -- "$KP" "$BLOCKHASH" 2>"$INFO")
cat "$INFO"
PDA=$(awk '/receipt PDA/{print $3}' "$INFO")
SEALED=$(awk '/commitment/{print $2}' "$INFO")
rm -f "$INFO"

SIG=$(rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"sendTransaction\",\"params\":[\"$TX\",{\"encoding\":\"base64\",\"skipPreflight\":false}]}" \
  | python3 -c "
import sys,json
r=json.load(sys.stdin)
if 'error' in r:
    print('SEND FAILED:', json.dumps(r['error'])[:400]); raise SystemExit(1)
print(r['result'])")
echo "  signature   $SIG"
echo "  explorer    https://explorer.solana.com/tx/$SIG?cluster=devnet"

printf '  confirming  '
for _ in $(seq 1 30); do
  ok=$(rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getSignatureStatuses\",\"params\":[[\"$SIG\"]]}" \
    | python3 -c "import sys,json;v=json.load(sys.stdin)['result']['value'][0];print('' if v is None else (v.get('confirmationStatus') or ''))")
  case "$ok" in confirmed|finalized) echo "$ok"; break;; esac
  printf '.'; sleep 2
done

echo
echo "  --- now read it back off the chain, and check it against the sealed artifact ---"
rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getAccountInfo\",\"params\":[\"$PDA\",{\"encoding\":\"base64\",\"commitment\":\"confirmed\"}]}" \
| python3 -c "
import sys, json, base64, datetime
v = json.load(sys.stdin)['result']['value']
if not v:
    print('  receipt account not found — the anchor did not land'); raise SystemExit(1)
d = base64.b64decode(v['data'][0])
# [0] tag | [1..33] issuer | [33..65] recipient | [65..97] commitment | [97..129] grant_id
# | [129..137] issued_slot u64 | [137..145] expiry i64 | [145] revoked | [146] bump
assert d[0] == 1, 'not an initialised receipt'
commitment = d[65:97].hex()
slot = int.from_bytes(d[129:137], 'little')
opens = int.from_bytes(d[137:145], 'little', signed=True)
sealed = '''$SEALED'''
print('  stored commitment  %s' % commitment)
print('  matches the sealed artifact: %s' % ('YES' if commitment == sealed else 'NO  <-- ' + sealed))
print('  anchored at slot   %d' % slot)
print('  opens at           %d  (%s)' % (opens, datetime.datetime.utcfromtimestamp(opens).strftime('%Y-%m-%d')))
print('  revoked            %s' % bool(d[145]))
print('  bytes on chain     %d  — a hash and two dates. No position, no portfolio.' % len(d))
"
