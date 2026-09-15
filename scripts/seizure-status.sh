#!/usr/bin/env bash
# Read the seizure back off devnet. No keys, no account, no wallet.
#
#   ./scripts/seizure-status.sh
#
# Everything below is public state anyone can fetch. What it does not show is the amount — that is
# the point of the thing. The escrow and the lender both read zero in public; what moved between
# them is a ciphertext, and only the lender can open it.
set -uo pipefail
cd "$(dirname "$0")/.."
R="${RPC:-https://api.devnet.solana.com}"

PROGRAM=Gn3rzw8ULVo676ebnxX6qK3YEQP9T8NHtFVetXW8QduN
LOAN=Bu6HviMHncufhC3didbMUgZZHbtvZpKTWGWLBtk8UdfX
ESCROW=8dbUaPA1kQy8DLWq3jJhJ8rZqxG4STY1QZ7gxNYuaaaG
LENDER=GxtqwznSGEMCpM62Tg6d63WvUfKpKQomnmW94M1vhLhr

acct() { curl -s --max-time 25 "$R" -H 'Content-Type: application/json' \
  -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getAccountInfo\",\"params\":[\"$1\",{\"encoding\":\"$2\",\"commitment\":\"confirmed\"}]}"; }

echo "SEIZURE — devnet, read just now"
echo

acct "$PROGRAM" base64 | python3 -c "
import sys, json
v = json.load(sys.stdin)['result']['value']
print('  program   $PROGRAM')
print('            %s' % ('executable' if v and v['executable'] else 'MISSING'))"

acct "$LOAN" base64 | python3 -c "
import sys, json, base64
v = json.load(sys.stdin)['result']['value']
d = base64.b64decode(v['data'][0])
print('  loan      $LOAN')
print('            seized: %s' % ('yes' if d[414] == 1 else 'no'))"

for pair in "escrow    $ESCROW" "lender    $LENDER"; do
  name=${pair%% *}; addr=${pair##* }
  acct "$addr" jsonParsed | python3 -c "
import sys, json
i = json.load(sys.stdin)['result']['value']['data']['parsed']['info']
s = next(e['state'] for e in i['extensions'] if e['extension'] == 'confidentialTransferAccount')
print('  $name    $addr')
print('            owner %s' % i['owner'])
print('            public balance %s   ciphertext %d bytes' % (i['tokenAmount']['uiAmountString'], len(s['availableBalance'])))"
done

echo
echo "  the collateral moved; both accounts still read zero to everyone"
