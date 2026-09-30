#!/usr/bin/env bash
# PRIMARY ISSUANCE, CONFIDENTIALLY — and the gate as an error code rather than a diagram.
#
#   RPC=<endpoint> ./scripts/issue-e2e.sh
#   RPC=<endpoint> SHORT=2000 ./scripts/issue-e2e.sh    # the issuer short-delivers; the check refuses
#   RPC=<endpoint> ACT2=0 ./scripts/issue-e2e.sh        # stop after the allocation (act 1)
#
# Two acts. Act 1: the issuer allocates to an investor through the gate. Act 2: the investor sells
# part of that allocation to a second approved holder through the four-step bilateral protocol.
#
# The swap this repository already settles needs two holders whose confidential accounts BOTH
# already exist and be approved. On the 1,992 real mints that is the issuer's call:
# `autoApproveNewAccounts` is false, so a confidential account is unusable until the issuer approves
# it, and on the six mints whose accounts were counted none has been (usage-scan.sh). The demonstration
# that settles a block trade therefore cannot happen on a real mint — the hole is not in the
# cryptography, it is in who is standing at the door.
#
# **Issuance closes that hole, because the party who can open the door is one of the two parties.**
# The issuer allocates to an investor; the issuer is also the one who approves the investor's
# account. No matching, no third party, and no confidential account has to exist beforehand.
#
# WHAT THIS SHOWS THAT THE SWAP CANNOT. One transaction is built, sent, and REFUSED —
# `ConfidentialTransferAccountNotApproved`, the error Token-2022 returns when a confidential
# transfer names a destination the issuer has not signed for. The issuer then signs, and **the same
# allocation settles: same proof contexts, same accounts, same amounts, one approval later.**
#
# Not the same BYTES. It is rebuilt against a fresh blockhash, because the first one is minutes older
# by then and a stale blockhash is a different failure that would muddle the demonstration. Saying
# "the identical transaction" would be a claim anybody can check and find false -- Codex, 2026-09-30.
# What is identical is everything the refusal was about.
#
# THE SECOND REFUSAL, and it needs no gate at all. SHORT=<units> builds the issuer's leg for fewer
# shares than were agreed while the agreed figure stays what it was, and the investor's pre-signing
# check refuses it. That is the one danger a confidential swap has that a public one does not: the
# amounts are encrypted, so a party could be asked to sign a transaction whose other leg sends far
# less than agreed. Until 2026-09-30 this repository answered that with a printed number and a
# sentence telling the reader to compare it themselves, and then signed.
#
# TWO MORE, BOTH IN THE DEFAULT RUN, because the gate refusal alone leaves two questions open.
#   - Can somebody else open the gate? The investor sends ApproveAccount for their own account and
#     is refused on chain (MissingRequiredSignature, anchored), and the account still reads unapproved.
#   - Does an open gate let one party settle alone? After approval the issuer signs the allocation
#     by itself; the network refuses it at signature verification. That one never lands, so it has no
#     signature to cite, and the script says so rather than implying one.
#
# AND THE AUDITOR SLOT STAYS EMPTY, exactly as it is on all 1,992. That is not a shortcut: in
# primary issuance the issuer IS the sender, so they can already read what they sent and need no
# auditor key to see it. In the SECONDARY market -- investor to investor -- nobody but the two
# parties could read an amount. Whether an issuer would accept that is unasked; it is a question for
# the founder's conversations (brief §3 P1), not something this script shows. What this script
# shows is the flow that runs today on a mint configured the way the real ones are.
set -euo pipefail
cd "$(dirname "$0")/.."
. "$(dirname "$0")/lib/chain.sh"
. "$(dirname "$0")/lib/swap.sh"
R="${RPC:-https://api.devnet.solana.com}"
W="${WORK:-$(mktemp -d)}"; mkdir -p "$W"
# The demo app's hooks (docs/cwf-2026/DEMO-APP.md). Both inert without CONFIDE_EVENTS / CONFIDE_PAUSE.
pause_open
ev run mode="$([ -n "${SHORT:-}" ] && echo short || echo normal)"
DEC_X="${DECIMALS:-8}"          # the equity wrapper's
DEC_Y=6                         # PYUSD's
TREASURY="${TREASURY:-500000}"  # what the issuer holds to allocate from
ALLOC="${ALLOC:-20000}"         # shares allocated in this subscription
CASH="${CASH:-5000000}"         # dollars the investor holds
PAY="${PAY:-3500000}"           # $3.5m for 20,000 shares — $175 a share, agreed off chain
# What the issuer actually BUILDS its leg for. Equal to the agreed figure unless SHORT says
# otherwise, which is the whole negative control: one number diverges and nothing else changes.
SEND_X="${SHORT:-$ALLOC}"
bold=$'\033[1m'; dim=$'\033[2m'; grn=$'\033[32m'; red=$'\033[31m'; off=$'\033[0m'

ata() { spl-token -C "$1" address --token "$2" --verbose 2>&1 \
        | grep -oE 'Associated token address: *[1-9A-HJ-NP-Za-km-z]{32,44}' | awk '{print $NF}'; }
prov() { go "$1" "$(cargo run --quiet -p confide-ct --bin provision -- "$1" "$2" "$3" "$4" "$5" \
         "$(bh)" "$6" "$(mint_charges_fee "$3")" "$7" 2>/dev/null)"; }

pause parties
echo
echo "  ${bold}--- two parties: the issuer, and somebody subscribing ---${off}"
FUNDER="${FUNDER:-$HOME/.config/solana/id.json}"
for k in issuer investor; do
  solana-keygen new --no-bip39-passphrase --silent --force -o "$W/$k.json" >/dev/null
  solana -u "$R" -k "$FUNDER" transfer --allow-unfunded-recipient \
    "$(solana-keygen pubkey "$W/$k.json")" 0.7 >/dev/null
  printf 'json_rpc_url: %s\nwebsocket_url: ""\nkeypair_path: %s\ncommitment: confirmed\n' \
    "$R" "$W/$k.json" > "$W/$k.yml"
  echo "    $k   $(solana-keygen pubkey "$W/$k.json")"
  ev party who="$k" pubkey="$(solana-keygen pubkey "$W/$k.json")"
done

pause mints
echo
echo "  ${bold}--- the stock, gated and auditor-EMPTY exactly as all 1,992 are ---${off}"
mk() { # mk <letter> <decimals> <auditor|none> [flags...]
  local ml="$1" dec="$2" aud="$3"; shift 3
  local mint
  mint=$(spl-token -C "$W/issuer.yml" create-token --program-2022 --decimals "$dec" \
    --enable-confidential-transfers auto "$@" 2>&1 \
    | grep -oE 'Address:  *[1-9A-HJ-NP-Za-km-z]{32,44}' | awk '{print $2}')
  go "mint $ml: gate closed" "$(cargo run --quiet -p confide-ct --bin set-auditor -- \
    "$W/issuer.json" "$mint" "$(bh)" "$W/auditor-$ml.json" "$aud" 2>/dev/null)"
  eval "MINT_$ml=$mint"
  printf '    mint %s   %s   %s(%s decimals, autoApproveNewAccounts false, auditor %s)%s\n' \
    "$ml" "$mint" "$dim" "$dec" "$([ "$aud" = none ] && echo EMPTY || echo set)" "$off"
  ev mint asset="$ml" mint="$mint" decimals="$dec" auditor="$([ "$aud" = none ] && echo empty || echo set)"
}
mk X "$DEC_X" none
mk Y "$DEC_Y" none --enable-permanent-delegate --enable-close --enable-freeze \
     --transfer-fee-basis-points 0 --transfer-fee-maximum-fee 0

# open <who> <letter> <mint> <units> <decimals> <approve?>
# `approve` is a PARAMETER here, which is the whole point: the investor's equity account is opened
# without it, so the allocation below has somewhere to be refused.
open() {
  local who="$1" ml="$2" mint="$3" units="$4" dec="$5" appr="$6" acct
  spl-token -C "$W/$who.yml" create-account "$mint" >/dev/null 2>&1 || true
  acct=$(ata "$W/$who.yml" "$mint")
  [ "$units" = 0 ] || spl-token -C "$W/issuer.yml" mint "$mint" "$units" "$acct" >/dev/null
  prov configure "$W/$who.json" "$mint" "$acct" "$units" "$W/$who-$ml-keys.json" "$dec"
  if [ "$appr" = yes ]; then
    go "the issuer approves it" "$(cargo run --quiet -p confide-ct --bin seizure-client -- approve \
      "$W/issuer.json" "$acct" "$mint" "$(bh)")"
  else
    printf '    %sNOT approved — the issuer has not signed for this one%s\n' "$red" "$off"
  fi
  if [ "$units" != 0 ]; then
    prov deposit "$W/$who.json" "$mint" "$acct" "$units" "$W/$who-$ml-keys.json" "$dec"
    prov apply   "$W/$who.json" "$mint" "$acct" "$units" "$W/$who-$ml-keys.json" "$dec"
  fi
  eval "${who}_${ml}=$acct"
  # After the approval (if any) has confirmed -- `go` exits the script under set -e otherwise.
  ev account who="$who" asset="$ml" account="$acct" approved="$appr" funded="$units"
}

pause holdings
echo
echo "  ${bold}--- the issuer's treasury, and the investor's cash ---${off}"
open issuer   X "$MINT_X" "$TREASURY" "$DEC_X" yes
open investor Y "$MINT_Y" "$CASH"     "$DEC_Y" yes
open issuer   Y "$MINT_Y" 0           "$DEC_Y" yes

pause investor_opens
echo
echo "  ${bold}--- the investor opens an account for the stock. This is the gate ---${off}"
open investor X "$MINT_X" 0 "$DEC_X" no

pause proofs
echo
echo "  ${bold}--- both legs' proofs, built before anybody knows whether it will be allowed ---${off}"
swap_leg issuer   "$W/issuer.json"   "$W/issuer-X-keys.json"   "$MINT_X" "$issuer_X"   "$investor_X" \
  "$(swap_elgamal "$W/investor-X-keys.json")" "$SEND_X" "$DEC_X" "$W/issuer-ctx.json"
swap_leg investor "$W/investor.json" "$W/investor-Y-keys.json" "$MINT_Y" "$investor_Y" "$issuer_Y" \
  "$(swap_elgamal "$W/issuer-Y-keys.json")" "$PAY" "$DEC_Y" "$W/investor-ctx.json"
# The terms agreed off chain -- what the legs were meant to carry, not what was built (SHORT differs).
ev proofs legs=2 shares="$ALLOC" cash="$PAY"

pause check
# The checker's output is copied to a file ONLY for the demo app, which shows the decrypted figure.
# A terminal run writes nothing extra (Codex, 2026-09-30: a decrypted amount on disk is a new
# artifact, and tee a new way to fail). The verdict is always the checker's exit status.
# The figure the checker decrypted, for display only. Its colour codes are stripped first: the number
# sits after an ESC[1m, and a digit-hunting pattern would otherwise read the "1" in the escape.
decrypted() { sed $'s/\x1b\\[[0-9;]*m//g' "$W/check.out" 2>/dev/null \
  | grep -aoE 'it will move [0-9]+' | grep -oE '[0-9]+$' | head -1; }
look() {
  if [ -n "${CONFIDE_EVENTS:-}" ]; then
    local st
    swap_look "$1" "$2" "$3" "$4" | tee "$W/check.out"; st=("${PIPESTATUS[@]}")
    # the copy failing is a failure of the run, never a verdict: return 1, not the checker's 3
    [ "${st[1]}" = 0 ] || { echo "  could not copy the checker's output for the app" >&2; return 1; }
    return "${st[0]}"
  fi
  swap_look "$1" "$2" "$3" "$4"
}

echo
echo "  ${bold}--- before signing, the investor CHECKS the allocation addressed to them ---${off}"
# "$ALLOC" is what was agreed off chain, and passing it is what makes this a check rather than a
# display: swap-check compares and exits non-zero, and `set -e` is on.
if [ -n "${SHORT:-}" ]; then
  printf '    %sSHORT=%s — the issuer built this leg for %s shares while %s was agreed.%s\n' \
    "$red" "$SHORT" "$SHORT" "$ALLOC" "$off"
  # NOT "the gate is open": at this point in the run it is still shut -- the approval happens after
  # the check, and in SHORT mode the script never gets there. The refusal below is about the amount
  # and nothing else, which is the whole point of the control, so it must not borrow the gate's story.
  printf '    %sNothing else differs. The proofs are valid, and the amount is the only thing wrong.%s\n' \
    "$dim" "$off"
  # THREE OUTCOMES, NOT TWO. swap-check exits 3 only for a verified mismatch; anything else non-zero
  # means the check never completed -- a proof context not on chain, a key that does not open it.
  # Reporting those as "refused before signing" would be a refusal nobody established.
  set +e; look "$W/investor-X-keys.json" "$W/issuer-ctx.json" "$ALLOC" "$DEC_X"; st=$?; set -e
  case "$st" in
    0) echo >&2
       echo "  A SHORT LEG PASSED THE CHECK. The investor would have signed for $ALLOC shares and" >&2
       echo "  received $SHORT. That is the finding, not this script." >&2
       exit 1;;
    3) ;;
    *) echo "  the check did not complete (exit $st) — this is NOT a refusal of the amount" >&2
       exit 1;;
  esac
  echo
  printf '  %s%sREFUSED BEFORE SIGNING.%s %s\n' "$grn" "$bold" "$off"     "No transaction was built, so none was signed and none was sent."
  # Said precisely, because "nothing is on chain" would be false. swap_leg wrote proof contexts,
  # which are public, immutable and contain no amount anyone but the two parties can read. What does
  # not exist is a transfer.
  printf '  %sThe proof contexts are on chain and hold nothing readable; the transfer does not exist.%s\n' \
    "$dim" "$off"
  printf '  %sThe gate refusal is the other control: run without SHORT.%s\n' "$dim" "$off"
  ev refused source=pre_sign_check what=allocation agreed="$ALLOC" decimals="$DEC_X" \
     decrypted_base="$(decrypted)"
  ev done mode=short
  echo
  echo "    work dir  $W"
  exit 0
fi
look "$W/investor-X-keys.json" "$W/issuer-ctx.json" "$ALLOC" "$DEC_X"
ev checked source=pre_sign_check who=investor agreed="$ALLOC" decimals="$DEC_X" \
   decrypted_base="$(decrypted)"

build() {
  cargo run --quiet -p confide-ct --bin swap-tx -- "$W/issuer.json" "$(bh)" \
    "$W/issuer.json"   "$W/issuer-ctx.json"   "$issuer_X"   "$investor_X" "$MINT_X" \
    "$W/investor.json" "$W/investor-ctx.json" "$investor_Y" "$issuer_Y"   "$MINT_Y" \
    >"$W/issue.b64" 2>"$W/issue.size"
}

# landed <b64>  ->  "<signature> <landed error as JSON>"
# Sent with preflight OFF on purpose. With preflight on, the RPC node simulates, returns the error
# and nothing lands — the refusal is then reproducible but not anchored, and "run it yourself" is
# weaker than a signature anybody can look up. Skipping preflight costs one fee and puts the refused
# transaction on chain with its error attached. The error is READ BACK from the landed transaction
# rather than trusted from the send: one that fails in preflight and one that fails on chain are
# different artifacts, and only the second can be cited.
landed() {
  local sig err=""
  sig=$(rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"sendTransaction\",\"params\":[\"$1\",{\"encoding\":\"base64\",\"skipPreflight\":true}]}" \
    | python3 -c "
import sys, json
r = json.load(sys.stdin)
print('NOSEND ' + json.dumps(r['error']).replace(' ', '')[:300] if 'error' in r else r['result'])")
  case "$sig" in NOSEND*) echo "$sig"; return 0;; esac
  for _ in $(seq 1 40); do
    err=$(rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getTransaction\",\"params\":[\"$sig\",{\"maxSupportedTransactionVersion\":0}]}" \
      | python3 -c "
import sys, json
r = json.load(sys.stdin).get('result')
print('' if not r else json.dumps(r['meta']['err']).replace(' ', ''))")
    [ -n "$err" ] && break
    sleep 2
  done
  echo "$sig ${err:-}"
}
# approved <account>  ->  true | false, read from the chain rather than inferred from what was sent
approved() {
  rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getAccountInfo\",\"params\":[\"$1\",{\"encoding\":\"jsonParsed\",\"commitment\":\"confirmed\"}]}" \
  | python3 -c "
import sys,json
i=json.load(sys.stdin)['result']['value']['data']['parsed']['info']
s=next(e['state'] for e in i['extensions'] if e['extension']=='confidentialTransferAccount')
print('true' if s['approved'] else 'false')"
}

pause send_allocation
echo
echo "  ${bold}--- the allocation, sent while the account is unapproved ---${off}"
build
grep -a "one transaction" "$W/issue.size" || true
# THE POINT OF THE WHOLE SCRIPT. Anchored, not simulated -- see `landed`.
read -r REFUSED_SIG err < <(landed "$(cat "$W/issue.b64")")
[ "$REFUSED_SIG" = NOSEND ] && { echo "    could not even send it: $err" >&2; exit 1; }
# `landed` strips the spaces json.dumps puts after colons. Before it did, matching without the space
# reported the right refusal as the wrong one, which is worse than not matching at all; both
# spellings are kept so the match does not depend on that normalisation surviving.
case "$err" in
  *'"Custom": 24'*|*'"Custom":24'*|*"Custom(24)"*)
    printf '    %sREFUSED on chain — Custom(24), ConfidentialTransferAccountNotApproved%s\n' "$red" "$off"
    printf '    %s%s%s\n' "$dim" "$REFUSED_SIG" "$off"
    printf '    %sthe proofs are valid, the amounts are right, and the issuer has not signed.%s\n' "$dim" "$off"
    ev refused source=on_chain what=allocation sig="$REFUSED_SIG" err="Custom(24)";;
  null)
    echo "    IT SETTLED. The destination was approved when it should not have been — the gate" >&2
    echo "    this repository is about did not hold, and that is the finding, not this script." >&2
    exit 1;;
  "")
    echo "    the refused transaction never landed — nothing to cite" >&2; exit 1;;
  *)
    echo "    refused, but not for the reason this demonstrates: $err" >&2; exit 1;;
esac

pause self_approve
echo
echo "  ${bold}--- the investor tries to approve their own account ---${off}"
# THE GATE HAS A KEYHOLE, NOT JUST A DOOR. The refusal above shows an unapproved account cannot
# receive; it does not show that only the issuer can change that. If any signer could approve, the
# gate would be a formality the holder clears themselves. So the investor -- who owns the account,
# pays the fee and signs -- sends the same one-instruction ApproveAccount the issuer is about to send.
#
# Token-2022 approves only when the signer IS the mint's confidential-transfer authority, and
# otherwise returns MissingRequiredSignature (spl-token-2022 8.0.1,
# extension/confidential_transfer/processor.rs, process_approve_account). The name reads oddly: the
# transaction carries a valid signature from the key it names as authority, and that key is not the
# mint's approval authority. The program reports that case with this error; it is the program's word,
# not a claim that some other signature was left off.
read -r WRONG_SIG werr < <(landed "$(cargo run --quiet -p confide-ct --bin seizure-client -- approve \
  "$W/investor.json" "$investor_X" "$MINT_X" "$(bh)")")
[ "$WRONG_SIG" = NOSEND ] && { echo "    could not even send it: $werr" >&2; exit 1; }
case "$werr" in
  *MissingRequiredSignature*)
    printf '    %sREFUSED on chain — MissingRequiredSignature: the signer is not the mint'"'"'s approval authority%s\n' "$red" "$off"
    printf '    %s%s%s\n' "$dim" "$WRONG_SIG" "$off";;
  null)
    echo "    THE INVESTOR APPROVED THEIR OWN ACCOUNT. The gate is not the issuer's, and that is" >&2
    echo "    the finding, not this script." >&2
    exit 1;;
  "") echo "    the wrong-key approval never landed — nothing to cite" >&2; exit 1;;
  *)  echo "    refused, but not for the reason this demonstrates: $werr" >&2; exit 1;;
esac
# And the account is still shut. Read from the chain, not concluded from the error.
[ "$(approved "$investor_X")" = false ] || { echo "    the account reads approved after a refused approval" >&2; exit 1; }
printf '    %sthe account still reads approved: false%s\n' "$dim" "$off"
ev refused source=on_chain what=self_approval sig="$WRONG_SIG" err="MissingRequiredSignature"
ev approval account="$investor_X" approved=false

pause issuer_approves
echo
echo "  ${bold}--- the issuer signs for the account. One instruction ---${off}"
go "the issuer approves it" "$(cargo run --quiet -p confide-ct --bin seizure-client -- approve \
  "$W/issuer.json" "$investor_X" "$MINT_X" "$(bh)")"

[ "$(approved "$investor_X")" = true ] || { echo "    the approval confirmed but the account does not read approved" >&2; exit 1; }
ev approval account="$investor_X" approved=true sig="$GO_SIG"

pause issuer_signs_alone
echo
echo "  ${bold}--- the issuer signs the allocation alone ---${off}"
# ONE SIGNATURE OF TWO. The gate is open now, the proofs are valid and the amounts are right, so the
# only thing this transaction lacks is the investor's signature on their own payment leg. It is
# assembled from public keys (`swap-tx build`, the same path the bilateral protocol uses) and signed
# by the issuer only.
#
# This refusal CANNOT be anchored the way the two above are, and saying otherwise would be false: a
# transaction missing a required signature never enters a block, so there is no signature of it to
# look up. It is sent with preflight ON and the RPC node's signature verification refuses it. If it
# is ever accepted, the script waits to see whether it landed and fails loudly either way.
ISSUER=$(solana-keygen pubkey "$W/issuer.json"); INVESTOR=$(solana-keygen pubkey "$W/investor.json")
cargo run --quiet -p confide-ct --bin swap-tx -- build "$ISSUER" "$(bh)" \
  "$ISSUER"   "$W/issuer-ctx.json"   "$issuer_X"   "$investor_X" "$MINT_X" \
  "$INVESTOR" "$W/investor-ctx.json" "$investor_Y" "$issuer_Y"   "$MINT_Y" \
  2>/dev/null | cargo run --quiet -p confide-ct --bin swap-tx -- sign - "$W/issuer.json" \
  >"$W/half.b64" 2>"$W/half.err"
# Asserted, not displayed. A builder or signer regression that produced 0 of 2, or 1 of 3, would
# otherwise reach the RPC and be refused for a reason this is not about. "signed by the issuer, 1 of
# 2" means the issuer's slot is filled and the only other one -- the investor's -- is empty.
grep -aqE "signed by $ISSUER +1 of 2 signatures present" "$W/half.err" \
  || { echo "    the half-signed allocation is not 'issuer only, 1 of 2':" >&2; cat "$W/half.err" >&2; exit 1; }
printf '    %ssigned by the issuer only — 1 of 2 signatures present%s\n' "$dim" "$off"
# NOT `send`: it cuts the error to 300 characters, and the -32002 answer carries a `data` object long
# enough that the cut JSON no longer parses -- which the verdict below then called "refused for another
# reason" on the first devnet run (2026-09-30). The whole body is read here.
half=$(rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"sendTransaction\",\"params\":[\"$(cat "$W/half.b64")\",{\"encoding\":\"base64\",\"preflightCommitment\":\"confirmed\"}]}" \
  | python3 -c "
import sys, json
r = json.load(sys.stdin)
print('ERR ' + json.dumps(r['error']) if 'error' in r else r['result'])")
# Exactly two shapes are accepted, both of which mean "a signature failed verification", and nothing
# looser: an earlier `*Signature*` pattern would have passed any refusal that happened to use the word.
#   current Agave:  -32002, simulation failed, data.err == "SignatureFailure"
#   older nodes:    -32003, "Transaction signature verification failure"
# (Codex, 2026-09-30, against agave rpc/src/rpc.rs; which one a given endpoint returns is not
# something this repository has observed yet.)
verdict=$(printf '%s' "$half" | python3 -c "
import sys, json
t = sys.stdin.read()
if not t.startswith('ERR '): print('ACCEPTED'); raise SystemExit
try: e = json.loads(t[4:])
except Exception: print('OTHER'); raise SystemExit
d = e.get('data') if isinstance(e.get('data'), dict) else {}
if e.get('code') == -32002 and d.get('err') == 'SignatureFailure': print('SIGFAIL ' + e.get('message', ''))
elif e.get('code') == -32003 and e.get('message') == 'Transaction signature verification failure': print('SIGFAIL ' + e['message'])
else: print('OTHER')")
case "$verdict" in
  SIGFAIL*)
    printf '    %sREFUSED in RPC preflight — %s%s\n' "$red" "${verdict#SIGFAIL }" "$off"
    printf '    %sit never entered a block, so there is nothing on chain to cite. The next step adds the\n' "$dim"
    printf '    investor'"'"'s signature to THIS transaction and sends it%s\n' "$off"
    ev refused source=rpc_preflight what=half_signed signatures="1 of 2" message="${verdict#SIGFAIL }";;
  OTHER)
    echo "    refused, but not for the reason this demonstrates: $half" >&2; exit 1;;
  *)
    echo "    A HALF-SIGNED ALLOCATION WAS ACCEPTED by the RPC: $half" >&2
    confirm "$half" >&2 && echo "    AND IT SETTLED. That is the finding, not this script." >&2
    exit 1;;
esac

pause investor_signs
echo
echo "  ${bold}--- the investor adds their signature to that same transaction ---${off}"
# Not rebuilt. The only difference between what was refused a moment ago and what is sent now is one
# signature, so the refusal above cannot have been about anything else.
cargo run --quiet -p confide-ct --bin swap-tx -- sign "$W/half.b64" "$W/investor.json" \
  >"$W/full.b64" 2>"$W/full.err"
grep -aqE "signed by $INVESTOR +2 of 2 signatures present" "$W/full.err" \
  || { echo "    the completed allocation is not '2 of 2':" >&2; cat "$W/full.err" >&2; exit 1; }
ALLOC_SIG=$(send "$(cat "$W/full.b64")")
case "$ALLOC_SIG" in ERR*) echo "    the allocation: $ALLOC_SIG" >&2; exit 1;; esac
confirm "$ALLOC_SIG" || exit 1
CU=$(rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getTransaction\",\"params\":[\"$ALLOC_SIG\",{\"commitment\":\"confirmed\",\"maxSupportedTransactionVersion\":0}]}" \
  | python3 -c "import sys,json;r=json.load(sys.stdin).get('result');print(r['meta'].get('computeUnitsConsumed','?') if r else '?')")
printf '    %-22s ok   %s%s   %s compute units%s\n' "the allocation" "$dim" "$ALLOC_SIG" "$CU" "$off"
ev settled act=1 sig="$ALLOC_SIG" cu="$CU" shares="$ALLOC" cash="$PAY" signatures="2 of 2"

pause observe
echo
echo "  ${bold}--- what moved ---${off}"
prov apply "$W/investor.json" "$MINT_X" "$investor_X" "$ALLOC" "$W/investor-X-keys.json" "$DEC_X" >/dev/null
prov apply "$W/issuer.json"   "$MINT_Y" "$issuer_Y"   "$PAY"   "$W/issuer-Y-keys.json"   "$DEC_Y" >/dev/null
show() { local d a p o line; read -r d a p o < <(ct "$2"); printf '    %-34s ' "$1"
  line=$(cargo run --quiet -p confide-ct --bin read-balance -- "$3" "$d" "$a" "$4" 2>/dev/null \
         | sed -n '3p' | sed 's/^ *//')
  printf '%s\n' "$line"
  # What the OWNER reads with their own key. The app shows it in that owner's view only.
  ev holding label="$1" account="$2" view="$line"; }
show "issuer, treasury (allocated from)" "$issuer_X"   "$W/issuer-X-keys.json"   "$DEC_X"
show "investor, stock (received)"        "$investor_X" "$W/investor-X-keys.json" "$DEC_X"
show "investor, cash (paid)"             "$investor_Y" "$W/investor-Y-keys.json" "$DEC_Y"
show "issuer, cash (received)"           "$issuer_Y"   "$W/issuer-Y-keys.json"   "$DEC_Y"

echo
pub() { local d a p o; read -r d a p o < <(ct "$1"); echo "$p"; }
PUBS="$(pub "$issuer_X") $(pub "$investor_X") $(pub "$investor_Y") $(pub "$issuer_Y")"
printf '    %spublic balances: issuer stock %s, investor stock %s, investor cash %s, issuer cash %s%s\n' \
  "$dim" $PUBS "$off"
# Asserted, not displayed: this is the observer's view, and the claim is that it shows nothing.
for v in $PUBS; do
  [ "$v" = 0 ] || { echo "    a public balance is $v, not 0 -- an amount is visible to anyone" >&2; exit 1; }
done
ev public act=1 accounts="$issuer_X,$investor_X,$investor_Y,$issuer_Y" balances="$(echo $PUBS | tr ' ' ',')"
echo
echo "  ${grn}${bold}An allocation was refused, the investor could not approve themselves, a half-signed"
echo "  allocation was refused, the issuer signed, and the same allocation settled with both signatures."
echo "  The auditor slot was empty throughout — as it is on all 1,992 — because in primary issuance"
echo "  the issuer is the sender and needs no key to read what they sent.${off}"

# ─────────────────────────────────────────────────────────────────────────────────────────────────
# ACT 2 — two approved holders trade between themselves (brief §2 step 6).
#
# The allocation above is delivery versus payment with the issuer as one party. The brief asks for
# more: two APPROVED HOLDERS agreeing terms off chain, each inspecting what they will receive before
# signing, and settling stock against cash atomically. So the investor now sells part of what was
# allocated to a second holder, whose accounts the issuer approves first.
#
# Run through the four-step bilateral protocol, not a one-machine shortcut: swap-offer, swap-accept,
# swap-settle, swap-sign, each party in its OWN work directory standing in for its own machine, so
# neither side's scripts can read the other's keys, and each pins the agreed terms locally before
# any proof exists. That path had not been run on devnet before this act was written (STATUS 09-30).
#
# ACT2=0 stops after act 1.
if [ "${ACT2:-1}" = 1 ]; then
  SELL="${SELL:-5000}"          # shares the investor sells
  SELL_PAY="${SELL_PAY:-875000}" # $875,000 — the same $175 a share, agreed off chain
  CASH_B="${CASH_B:-1000000}"   # what the second holder holds

  pause act2_accounts
  echo
  echo "  ${bold}=== ACT 2 — the investor sells $SELL shares to a second approved holder ===${off}"
  solana-keygen new --no-bip39-passphrase --silent --force -o "$W/buyer.json" >/dev/null
  solana -u "$R" -k "$FUNDER" transfer --allow-unfunded-recipient \
    "$(solana-keygen pubkey "$W/buyer.json")" 0.7 >/dev/null
  printf 'json_rpc_url: %s\nwebsocket_url: ""\nkeypair_path: %s\ncommitment: confirmed\n' \
    "$R" "$W/buyer.json" > "$W/buyer.yml"
  echo "    buyer   $(solana-keygen pubkey "$W/buyer.json")"
  ev party who=buyer pubkey="$(solana-keygen pubkey "$W/buyer.json")"
  # The issuer approves both of the buyer's accounts. The refusal before approval was act 1's point
  # and is not repeated.
  open buyer X "$MINT_X" 0        "$DEC_X" yes
  open buyer Y "$MINT_Y" "$CASH_B" "$DEC_Y" yes

  # One work directory per party. The key files are named the way the bilateral scripts look for
  # them: the mint's first eight characters.
  party() { # party <who> -> its directory, holding only its own keys
    local d="$W/party-$1"
    mkdir -p "$d"; chmod 700 "$d"
    cp "$W/$1-X-keys.json" "$d/$(echo "$MINT_X" | cut -c1-8)-keys.json"
    cp "$W/$1-Y-keys.json" "$d/$(echo "$MINT_Y" | cut -c1-8)-keys.json"
    printf '%s' "$d"
  }
  WA=$(party investor); WB=$(party buyer)

  pause offer
  echo
  echo "  ${bold}--- 1 of 4: the investor offers $SELL shares for \$$SELL_PAY, and pins those terms ---${off}"
  WORK="$WA" RPC="$R" ./scripts/swap-offer.sh "$W/investor.json" \
    --give "$MINT_X" "$SELL" --want "$MINT_Y" "$SELL_PAY" > "$W/offer.json"
  ev offer id="$(python3 -c "import json;print(json.load(open('$W/offer.json'))['id'])")" shares="$SELL" cash="$SELL_PAY" pinned_by=investor
  pause accept
  echo
  echo "  ${bold}--- 2 of 4: the buyer reads the offer, pins it, and builds the cash leg's proofs ---${off}"
  WORK="$WB" RPC="$R" ./scripts/swap-accept.sh "$W/buyer.json" "$W/offer.json" > "$W/accept.json"
  ev accepted pinned_by=buyer
  pause settle
  echo
  echo "  ${bold}--- 3 of 4: the investor checks the cash against the pin, builds the stock leg, signs once ---${off}"
  WORK="$WA" RPC="$R" ./scripts/swap-settle.sh "$W/investor.json" "$W/accept.json" > "$W/settle.json"
  pause sign
  echo
  echo "  ${bold}--- 4 of 4: the buyer checks the shares against the pin, adds the second signature ---${off}"
  WORK="$WB" RPC="$R" ./scripts/swap-sign.sh "$W/buyer.json" "$W/settle.json"

  pause observe2

  echo
  echo "  ${bold}--- what moved in act 2 ---${off}"
  prov apply "$W/buyer.json"    "$MINT_X" "$buyer_X"    "$SELL" "$W/buyer-X-keys.json"    "$DEC_X" >/dev/null
  prov apply "$W/investor.json" "$MINT_Y" "$investor_Y" "$((CASH - PAY + SELL_PAY))" "$W/investor-Y-keys.json" "$DEC_Y" >/dev/null
  show "investor, stock (sold $SELL)"   "$investor_X" "$W/investor-X-keys.json" "$DEC_X"
  show "investor, cash (received)"      "$investor_Y" "$W/investor-Y-keys.json" "$DEC_Y"
  show "buyer, stock (bought)"          "$buyer_X"    "$W/buyer-X-keys.json"    "$DEC_X"
  show "buyer, cash (paid)"             "$buyer_Y"    "$W/buyer-Y-keys.json"    "$DEC_Y"
  PUBS2="$(pub "$investor_X") $(pub "$investor_Y") $(pub "$buyer_X") $(pub "$buyer_Y")"
  printf '    %spublic balances: investor stock %s, investor cash %s, buyer stock %s, buyer cash %s%s\n' \
    "$dim" $PUBS2 "$off"
  for v in $PUBS2; do
    [ "$v" = 0 ] || { echo "    a public balance is $v, not 0 -- an amount is visible to anyone" >&2; exit 1; }
  done
  ev public act=2 accounts="$investor_X,$investor_Y,$buyer_X,$buyer_Y" balances="$(echo $PUBS2 | tr ' ' ',')"
  echo
  echo "  ${grn}${bold}Two approved holders agreed terms off chain, each checked what they would receive"
  echo "  against their own pinned copy of those terms, and stock and cash settled in one transaction."
  echo "  The issuer approved the accounts and did not see the amounts.${off}"
fi
ev done mode=normal
echo
echo "    work dir  $W"
