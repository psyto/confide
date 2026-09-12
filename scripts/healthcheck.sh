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
PAGE="${PAGE:-https://psyto.github.io/confide/}"

RECEIPTS=6a1Kd8Yo5U9wMXUtMnU1PZF8xy6wJ6zWyMr7uKNAHytv
ACCOUNT=6Wn7zAaV56yGaAduNvTxsjEiVS1UDxi9whUMje9mG16V
AUDITED_MINT=EbfBr1ZcVQFy7JN68fDoFw6NUyonBGYXEXPRKUrv7trH
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
for u in "$PAGE" "$PAGE/mints.json" "$PAGE/proofs.json"; do
  c=$(curl -s -o /dev/null -w "%{http_code}" --max-time 20 "$u")
  [ "$c" = "200" ] && ok "$u" || bad "$u  (http $c)"
done

echo
if [ "$fail" -eq 0 ]; then
  printf '  \033[32mall clear\033[0m — every claim in the submission is live\n\n'
else
  printf '  \033[31m%d check(s) failed\033[0m — see docs/DURABILITY.md\n\n' "$fail"
fi
exit "$fail"
