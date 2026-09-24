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
VIDEO="${VIDEO:-du0Twt_c9wQ}"

RECEIPTS=6a1Kd8Yo5U9wMXUtMnU1PZF8xy6wJ6zWyMr7uKNAHytv
ACCOUNT=Cgv2eDNUUrgRVhkZ8mBE5UkQmkqLh3Aj3poLiqBBrX1P
# The receipt anchored over that account's own ciphertext, 2026-09-15.
RECEIPT_PDA=HM2HLUxv5KMyuSoiNeH1mMCVfd7Kpr4TVmzBu7BHbqUb
RECEIPT_COMMITMENT=f3a58aaa296c622e75eb1fabde041a5d15d1a6d9b63f07c9d95ceeeadbdae2ba
AUDITED_MINT=5jszdY3yd8fq37DBEqECtBQdvwnyXtA9vexJFefVKWzb
# The seizure: the program, and the loan it settled. docs/SEIZURE.md.
SEIZURE_PROGRAM=Gn3rzw8ULVo676ebnxX6qK3YEQP9T8NHtFVetXW8QduN
SEIZED_LOAN=26QJWCRwvPd1dLwvgH4Drb8D5F4ga2RPMdS8PrbRw4Hj
SEIZED_ESCROW=HfdcgCmfMaWEu9ycjGEu12Mm9cAuxM8RxHQnELMimNx5
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
# The standing testbed's whole claim is that the gate is shut and operated. A published approval
# key can also open the gate, so it is watched rather than trusted.
if [ -f web/testbed.json ]; then
  echo "  THE STANDING TESTBED"
  if ./scripts/testbed-up.sh --check >/dev/null 2>&1; then
    ok "the devnet testbed is as published (gate shut, auditor empty, approval key ours)"
  else
    bad "the devnet testbed has been changed — ./scripts/testbed-up.sh --check"
  fi
  echo
fi

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

# The English captions must be the corrected track, not YouTube's transcription. On 2026-09-21 the
# founder uploaded a Japanese track and left English on ASR, and nothing noticed: scripts/
# fix-captions.sh holds fourteen corrections that only exist in video/captions-*.srt, including
# "Camino" -> "Kamino" (a protocol this submission argues about by source line) and "confide" ->
# "Confide" (the project's own name, uncapitalised in its own video).
#
# Three outcomes, kept apart on purpose. A check that cannot read the page must say so rather than
# pass -- this repository has shipped a green tick over an unreadable source before.
#
# WHAT THIS DOES NOT CHECK, so nobody reads more into the tick than is in it: the CONTENT. YouTube's
# timedtext endpoint refuses the track body to this fetch, tried on 2026-09-21 against both the ASR
# and the uploaded track, so whether the uploaded file is the corrected one is not verified here.
# It says a human uploaded something, not that they uploaded the right thing.
cc=$(curl -s --max-time 30 -A "Mozilla/5.0" "https://www.youtube.com/watch?v=$VIDEO" \
     | python3 -c '
import json, re, sys
h = sys.stdin.read()
m = re.search(r"\"captionTracks\":(\[.*?\])(?=,\"audioTracks\"|,\"translationLanguages\"|\})", h)
if not m:
    print("UNREADABLE"); raise SystemExit
try:
    tr = json.loads(m.group(1))
except Exception:
    print("UNREADABLE"); raise SystemExit
en = [x for x in tr if x.get("languageCode") == "en"]
asr = [x for x in en if x.get("kind") == "asr"]
# BOTH is not UPLOADED. On 2026-09-22 this said UPLOADED while YouTube kept its own transcript
# listed beside the uploaded one -- and that transcript was the one missing sixteen seconds of the
# film. The default served is the uploaded track, so a viewer is fine; someone who opens the caption
# menu is not. "Which track is default" and "which tracks exist" are two questions.
if not en:                print("NONE")
elif len(asr) == len(en): print("ASR")
elif asr:                 print("BOTH")
else:                     print("UPLOADED")
' 2>/dev/null)
# BOTH ASKED FOR SOMETHING THAT DOES NOT STICK. It failed with "delete it in Subtitles", and on
# 2026-09-24 the founder did: the track came back, and the next read of the watch page found
# `a.en` listed again beside the uploaded `.en`. YouTube re-derives its own transcript; a video
# owner cannot refuse it. A red that no action can clear is a red that teaches everyone to skip
# reds, so this reports rather than fails -- and the failing half is kept, because the thing that
# IS controllable is whether a human-uploaded English track exists at all, which is what carries
# fix-captions.sh's corrections and the sixteen seconds the machine dropped. ASR and NONE still
# fail. The measurement did not get weaker: "an uploaded track exists" is still required, and what
# stopped being required is the absence of something nobody can remove.
case "$cc" in
  UPLOADED) ok "the English captions are the uploaded track, not YouTube's transcription" ;;
  ASR)      bad "the English captions are YouTube's ASR — upload video/captions-*.srt; fix-captions.sh's corrections are not live" ;;
  BOTH)     ok "the uploaded English track is live; YouTube lists its own auto-generated one beside it, which regenerates after deletion (tried 2026-09-24) and is not an action item" ;;
  NONE)     bad "the video has no English caption track at all" ;;
  *)        warn "could not read the caption tracks — YouTube's page shape may have changed" ;;
esac

# The check-in. A second upload with its own deadline and its own link, submitted to a form that
# cannot be edited afterwards, so "is it still watchable" is worth asking every run rather than
# assumed from the day it went up.
CHECKIN="${CHECKIN:-mbE8HMwG0S4}"
if curl -s -o /dev/null -w "%{http_code}" --max-time 20 \
   "https://www.youtube.com/oembed?url=https://youtu.be/$CHECKIN&format=json" | grep -q 200; then
  ok "https://youtu.be/$CHECKIN  (check-in 1, public and embeddable)"
else
  bad "https://youtu.be/$CHECKIN  — the check-in is private, deleted, or no longer embeddable"
fi

# The superseded uploads. video/README.md carried "unlist them rather than leaving three answers to
# one question" as a standing instruction; the founder deleted all three on 2026-09-21. STATUS.md
# had warned the opposite way -- that an old URL still returned 200, so a mis-paste would not look
# broken -- and that warning is now false. It is checked instead of written down, because the
# reason it was written down is that it changed.
#
# A stray 11-character token that is not a video id answers 404 and passes, so over-matching here
# is harmless; only a superseded id that is actually LIVE fails.
old=$(grep -oE 'youtu\.be/[A-Za-z0-9_-]{11}|`[A-Za-z0-9_-]{11}`' video/README.md 2>/dev/null \
      | grep -oE '[A-Za-z0-9_-]{11}' | sort -u | grep -v "^$VIDEO$" | grep -v "^$CHECKIN$" || true)
live=""
for id in $old; do
  c=$(curl -s -o /dev/null -w "%{http_code}" --max-time 20 \
      "https://www.youtube.com/oembed?url=https://youtu.be/$id&format=json")
  [ "$c" = 200 ] && live="$live $id"
done
if [ -z "$live" ]; then
  ok "every superseded upload is gone — $VIDEO is the only live answer"
else
  bad "a superseded upload is still public:$live — two answers to one question"
fi

# Every file the page fetches, because a 200 on the page says nothing about them. `loans.json` was
# 404 on the live site while `index.html` returned 200, so the panel promising to read two loans
# off the chain showed a missing-file message to anybody who scrolled that far.
for f in "" mints.json proofs.json loans.json usage.json slots.json swaps.json capacity.json; do
  u="$PAGE/$f"
  c=$(curl -s -o /dev/null -w "%{http_code}" --max-time 20 "$u")
  [ "$c" = "200" ] && ok "$u" || bad "$u  (http $c)"
done

# And whether what is published is what this repository has. gh-pages is a separate branch and
# nothing moves files to it automatically; on 2026-09-20 the live page was 391 lines to the
# repository's 543, said "1,869 mints" in five places, and had no loans panel at all. It had been
# stale for days and every check passed, because they all read the files here.
live=$(curl -s --max-time 30 "$PAGE/index.html" | shasum | cut -d" " -f1)
here=$(shasum web/index.html | cut -d" " -f1)
if [ "$live" = "$here" ]; then
  ok "the published page is the one in web/"
else
  bad "the published page is NOT web/index.html — run ./scripts/publish-site.sh --push"
fi

echo
if [ "$fail" -eq 0 ]; then
  printf '  \033[32mall clear\033[0m — every check above is live\n\n'
else
  printf '  \033[31m%d check(s) failed\033[0m — see docs/DURABILITY.md\n\n' "$fail"
fi
exit "$fail"
