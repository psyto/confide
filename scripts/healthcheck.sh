#!/usr/bin/env bash
# Check every live claim this submission makes, and say which ones are still true.
#
# Judging runs to 2 October and devnet gets reset — this repo has already been bitten by that once,
# when a payer address inherited from another harness simply stopped existing. Run this before
# pointing anyone at the links.
#
#   ./scripts/healthcheck.sh
#
# Exit code is the number of failed checks.
set -uo pipefail
cd "$(dirname "$0")/.."
MAINNET="${MAINNET:-https://api.mainnet-beta.solana.com}"
DEVNET="${DEVNET:-https://api.devnet.solana.com}"
PAGE="${PAGE:-https://psyto.github.io/confide}"
VIDEO="${VIDEO:-p1aQuEnzhQk}"

RECEIPTS=6a1Kd8Yo5U9wMXUtMnU1PZF8xy6wJ6zWyMr7uKNAHytv
ACCOUNT=Cgv2eDNUUrgRVhkZ8mBE5UkQmkqLh3Aj3poLiqBBrX1P
# The receipt anchored over that account's own ciphertext, 2026-09-15.
RECEIPT_PDA=HM2HLUxv5KMyuSoiNeH1mMCVfd7Kpr4TVmzBu7BHbqUb
RECEIPT_COMMITMENT=f3a58aaa296c622e75eb1fabde041a5d15d1a6d9b63f07c9d95ceeeadbdae2ba
AUDITED_MINT=5jszdY3yd8fq37DBEqECtBQdvwnyXtA9vexJFefVKWzb
# The seizure: the program, and the loan it settled. docs/SEIZURE.md.
SEIZURE_PROGRAM=Gn3rzw8ULVo676ebnxX6qK3YEQP9T8NHtFVetXW8QduN
SEIZED_LOAN=HbbvY8hYbit4BRwVsu6Fj4tvCCfJqoHFZkWWmhZDLomH
SEIZED_ESCROW=AdgKdUhv8w8XddZxSS9p4jABGkq4tk78sU9avjEt4one
NVDAX=Xsc9qvGR1efVDFGLrVsmkzv3qi45LTBjeUKSPmx9qEh

fail=0
ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; }
bad()  { printf '  \033[31m✗\033[0m %s\n' "$1"; fail=$((fail+1)); }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; }
rpc()  { curl -s --max-time 25 "$1" -H 'Content-Type: application/json' -d "$2"; }
acct() { rpc "$1" "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getAccountInfo\",\"params\":[\"$2\",{\"encoding\":\"jsonParsed\",\"commitment\":\"confirmed\"}]}"; }

echo
echo "  MAINNET — durable; this does not reset"
r=$(acct "$MAINNET" "$NVDAX")
if echo "$r" | grep -q '"confidentialTransferMint"'; then
  if echo "$r" | python3 -c "
import sys,json
i=json.load(sys.stdin)['result']['value']['data']['parsed']['info']
ct=next(e['state'] for e in i['extensions'] if e['extension']=='confidentialTransferMint')
raise SystemExit(0 if ct.get('auditorElgamalPubkey') is None else 1)"; then
    ok "NVDAx still has confidential transfers on and the auditor slot empty"
  else
    warn "NVDAx now HAS an auditor key — the core finding has changed; update the docs"
  fi
else
  bad "could not read NVDAx from mainnet"
fi

echo
echo "  DEVNET — resets; everything below is at risk"
if acct "$DEVNET" "$RECEIPTS" | grep -q '"executable":true'; then
  ok "aperture-receipts program is deployed  ($RECEIPTS)"
else
  bad "receipts program is gone — redeploy: cd ../aperture/programs/aperture-receipts && cargo build-sbf && solana program deploy ..."
fi

if acct "$DEVNET" "$SEIZURE_PROGRAM" | grep -q '"executable":true'; then
  ok "confide-seizure program is deployed  ($SEIZURE_PROGRAM)"
else
  bad "seizure program is gone — redeploy: cd programs/confide-seizure && cargo build-sbf --arch v3 && solana program deploy target/deploy/confide_seizure.so --program-id target/deploy/confide_seizure-keypair.json -k ~/.config/solana/id.json -u devnet"
fi

# A loan whose byte 414 is 1 is one the program settled. Checking the flag rather than the balance
# is deliberate: the balance is a ciphertext, and a seizure that moved nothing would still leave
# two accounts reading zero in public.
if acct "$DEVNET" "$SEIZED_LOAN" | python3 -c "
import sys, json, base64
v = json.load(sys.stdin).get('result', {}).get('value')
raise SystemExit(0 if v and base64.b64decode(v['data'][0])[414] == 1 else 1)
" 2>/dev/null; then
  ok "the seized loan still says so  ($SEIZED_LOAN)"
else
  bad "the seized loan is gone or unset — rerun: RPC=<devnet> ./scripts/seizure-e2e.sh"
fi

r=$(acct "$DEVNET" "$ACCOUNT")
if echo "$r" | grep -q '"confidentialTransferAccount"'; then
  echo "$r" | python3 -c "
import sys,json
i=json.load(sys.stdin)['result']['value']['data']['parsed']['info']
ct=next(e['state'] for e in i['extensions'] if e['extension']=='confidentialTransferAccount')
print('    public balance %s, ciphertext %d bytes' % (i['tokenAmount']['uiAmountString'], len(ct['availableBalance'])))"
  ok "the confidential account is alive  ($ACCOUNT)"
else
  bad "the confidential account is gone — re-run: ./scripts/provision-account.sh"
fi

if acct "$DEVNET" "$AUDITED_MINT" | python3 -c "
import sys,json
v=json.load(sys.stdin)['result']['value']
if not v: raise SystemExit(1)
i=v['data']['parsed']['info']
ct=next(e['state'] for e in i['extensions'] if e['extension']=='confidentialTransferMint')
raise SystemExit(0 if ct.get('auditorElgamalPubkey') else 1)" 2>/dev/null; then
  ok "the mirrored mint still has its auditor slot filled  ($AUDITED_MINT)"
else
  bad "the audited mint is gone or its slot emptied — re-run: ./scripts/set-auditor.sh <mint>"
fi

# The mirror is only "NVDAx's config, one field apart" while it gates accounts the same way. It did
# not, until 09-15: update_mint rewrites both fields and set-auditor was passing true, silently
# undoing the `manual` the mint was created with.
if acct "$DEVNET" "$AUDITED_MINT" | python3 -c "
import sys,json
v=json.load(sys.stdin)['result']['value']
if not v: raise SystemExit(1)
ct=next(e['state'] for e in v['data']['parsed']['info']['extensions'] if e['extension']=='confidentialTransferMint')
raise SystemExit(0 if ct.get('autoApproveNewAccounts') is False else 1)" 2>/dev/null; then
  ok "and still gates new accounts the way NVDAx does (autoApproveNewAccounts false)"
else
  bad "the mirror auto-approves accounts — it now differs from NVDAx in two fields, not one"
fi

# The anchored receipt from the run recorded in docs/ONCHAIN.md. Content-blind by construction, so
# what is checkable is that it is there, holds that commitment, and opens on the reporting deadline.
r=$(rpc "$DEVNET" "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getAccountInfo\",\"params\":[\"$RECEIPT_PDA\",{\"encoding\":\"base64\",\"commitment\":\"confirmed\"}]}")
if echo "$r" | RECEIPT_COMMITMENT="$RECEIPT_COMMITMENT" python3 -c "
import sys, json, base64, os
v = json.load(sys.stdin)['result']['value']
if not v: raise SystemExit(1)
d = base64.b64decode(v['data'][0])
raise SystemExit(0 if d[0] == 1 and d[65:97].hex() == os.environ['RECEIPT_COMMITMENT'] else 1)" 2>/dev/null; then
  ok "the anchored disclosure is still on chain, commitment unchanged  ($RECEIPT_PDA)"
else
  bad "the anchored receipt is gone or altered — re-run: ./scripts/anchor-receipt.sh"
fi

# docs/ONCHAIN.md quotes the keys the chain held when it was written. Twice now a re-provision has
# moved them and the prose stayed behind, so compare rather than reread: every base64 key in that
# file must be one the chain still reports.
if [ -f docs/ONCHAIN.md ]; then
  acct_key=$(acct "$DEVNET" "$ACCOUNT" | python3 -c "
import sys,json
v=json.load(sys.stdin)['result']['value']
if not v: raise SystemExit(0)
ct=next(e['state'] for e in v['data']['parsed']['info']['extensions'] if e['extension']=='confidentialTransferAccount')
print(ct['elgamalPubkey'])" 2>/dev/null)
  mint_key=$(acct "$DEVNET" "$AUDITED_MINT" | python3 -c "
import sys,json
v=json.load(sys.stdin)['result']['value']
if not v: raise SystemExit(0)
ct=next(e['state'] for e in v['data']['parsed']['info']['extensions'] if e['extension']=='confidentialTransferMint')
print(ct.get('auditorElgamalPubkey') or '')" 2>/dev/null)
  stale=$(ACCT_KEY="$acct_key" MINT_KEY="$mint_key" python3 -c "
import os, re
doc = open('docs/ONCHAIN.md').read()
live = {k for k in (os.environ['ACCT_KEY'], os.environ['MINT_KEY']) if k}
quoted = set(re.findall(r'[A-Za-z0-9+/]{42,43}=', doc))
print(','.join(sorted(quoted - live)))")
  if [ -z "$stale" ]; then
    ok "docs/ONCHAIN.md quotes only keys the chain still reports"
  else
    bad "docs/ONCHAIN.md quotes keys the chain no longer has: $stale"
  fi
fi

echo
echo "  PROOFS — what the live page asks the chain"
if [ -f web/proofs.json ]; then
  n=0
  for k in equality_tx range_tx; do
    tx=$(python3 -c "import json;print(json.load(open('web/proofs.json'))['$k'])")
    if rpc "$DEVNET" "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"simulateTransaction\",\"params\":[\"$tx\",{\"sigVerify\":false,\"replaceRecentBlockhash\":true,\"encoding\":\"base64\"}]}" \
       | grep -q '"err":null'; then n=$((n+1)); fi
  done
  [ "$n" -eq 2 ] && ok "both proofs still accepted by the live ZK program" \
                 || bad "$n of 2 proofs accepted — regenerate: ./scripts/prove-collateral.sh"
else
  bad "web/proofs.json missing"
fi

echo
echo "  LINKS"
# The walkthrough is one of the three links the submission gives judges, and it is the one that
# lives outside this repository. oEmbed answers 404 for a video that is private, deleted or made
# unembeddable, so it checks more than reachability.
if curl -s -o /dev/null -w "%{http_code}" --max-time 20 \
   "https://www.youtube.com/oembed?url=https://youtu.be/$VIDEO&format=json" | grep -q 200; then
  ok "https://youtu.be/$VIDEO  (public and embeddable)"
else
  bad "https://youtu.be/$VIDEO  — private, deleted, or no longer embeddable"
fi

for u in "$PAGE/" "$PAGE/mints.json" "$PAGE/proofs.json"; do
  c=$(curl -s -o /dev/null -w "%{http_code}" --max-time 20 "$u")
  [ "$c" = "200" ] && ok "$u" || bad "$u  (http $c)"
done

echo
if [ "$fail" -eq 0 ]; then
  printf '  \033[32mall clear\033[0m — every check above is live\n\n'
else
  printf '  \033[31m%d check(s) failed\033[0m — see docs/DURABILITY.md\n\n' "$fail"
fi
exit "$fail"
