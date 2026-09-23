#!/usr/bin/env bash
# PRIMARY ISSUANCE, CONFIDENTIALLY — and the gate as an error code rather than a diagram.
#
#   RPC=<endpoint> ./scripts/issue-e2e.sh
#
# The swap this repository already settles needs two holders whose confidential accounts BOTH
# already exist. On every one of the 1,992 real mints that is impossible: `autoApproveNewAccounts`
# is false, so an account cannot exist until the issuer signs for it, and none has. The demonstration
# that settles a block trade therefore cannot happen on a real mint — the hole is not in the
# cryptography, it is in who is standing at the door.
#
# **Issuance closes that hole, because the party who can open the door is one of the two parties.**
# The issuer allocates to an investor; the issuer is also the one who approves the investor's
# account. No matching, no third party, and no confidential account has to exist beforehand.
#
# WHAT THIS SHOWS THAT THE SWAP CANNOT. One transaction is built, sent, and REFUSED —
# `ConfidentialTransferAccountNotApproved`, the error Token-2022 returns when a confidential
# transfer names a destination the issuer has not signed for. The issuer then signs. **The same
# transaction is sent again and settles.** Nothing about it changed; the gate did.
#
# AND THE AUDITOR SLOT STAYS EMPTY, exactly as it is on all 1,992. That is not a shortcut: in
# primary issuance the issuer IS the sender, so they can already read what they sent and need no
# auditor key to see it. The empty slot blocks the SECONDARY market, not this one — which is why
# this is the flow that runs today on a mint configured the way the real ones are.
set -euo pipefail
cd "$(dirname "$0")/.."
. "$(dirname "$0")/lib/chain.sh"
. "$(dirname "$0")/lib/swap.sh"
R="${RPC:-https://api.devnet.solana.com}"
W="${WORK:-$(mktemp -d)}"; mkdir -p "$W"
DEC_X="${DECIMALS:-8}"          # the equity wrapper's
DEC_Y=6                         # PYUSD's
TREASURY="${TREASURY:-500000}"  # what the issuer holds to allocate from
ALLOC="${ALLOC:-20000}"         # shares allocated in this subscription
CASH="${CASH:-5000000}"         # dollars the investor holds
PAY="${PAY:-3500000}"           # $3.5m for 20,000 shares — $175 a share, agreed off chain
bold=$'\033[1m'; dim=$'\033[2m'; grn=$'\033[32m'; red=$'\033[31m'; off=$'\033[0m'

ata() { spl-token -C "$1" address --token "$2" --verbose 2>&1 \
        | grep -oE 'Associated token address: *[1-9A-HJ-NP-Za-km-z]{32,44}' | awk '{print $NF}'; }
prov() { go "$1" "$(cargo run --quiet -p confide-ct --bin provision -- "$1" "$2" "$3" "$4" "$5" \
         "$(bh)" "$6" "$(mint_charges_fee "$3")" "$7" 2>/dev/null)"; }

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
done

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
}

echo
echo "  ${bold}--- the issuer's treasury, and the investor's cash ---${off}"
open issuer   X "$MINT_X" "$TREASURY" "$DEC_X" yes
open investor Y "$MINT_Y" "$CASH"     "$DEC_Y" yes
open issuer   Y "$MINT_Y" 0           "$DEC_Y" yes

echo
echo "  ${bold}--- the investor opens an account for the stock. This is the gate ---${off}"
open investor X "$MINT_X" 0 "$DEC_X" no

echo
echo "  ${bold}--- both legs' proofs, built before anybody knows whether it will be allowed ---${off}"
swap_leg issuer   "$W/issuer.json"   "$W/issuer-X-keys.json"   "$MINT_X" "$issuer_X"   "$investor_X" \
  "$(swap_elgamal "$W/investor-X-keys.json")" "$ALLOC" "$DEC_X" "$W/issuer-ctx.json"
swap_leg investor "$W/investor.json" "$W/investor-Y-keys.json" "$MINT_Y" "$investor_Y" "$issuer_Y" \
  "$(swap_elgamal "$W/issuer-Y-keys.json")" "$PAY" "$DEC_Y" "$W/investor-ctx.json"

echo
echo "  ${bold}--- before signing, the investor reads the allocation addressed to them ---${off}"
swap_look "$W/investor-X-keys.json" "$W/issuer-ctx.json"

build() {
  cargo run --quiet -p confide-ct --bin swap-tx -- "$W/issuer.json" "$(bh)" \
    "$W/issuer.json"   "$W/issuer-ctx.json"   "$issuer_X"   "$investor_X" "$MINT_X" \
    "$W/investor.json" "$W/investor-ctx.json" "$investor_Y" "$issuer_Y"   "$MINT_Y" \
    >"$W/issue.b64" 2>"$W/issue.size"
}

echo
echo "  ${bold}--- the allocation, sent while the account is unapproved ---${off}"
build
grep -a "one transaction" "$W/issue.size" || true
# THE POINT OF THE WHOLE SCRIPT, and it is sent with preflight OFF on purpose. With preflight on,
# the RPC node simulates, returns the error and nothing lands — the refusal is then reproducible but
# not anchored, and "run it yourself" is weaker than a signature anybody can look up. Skipping
# preflight costs one fee and puts the refused transaction on chain with its error attached.
REFUSED_SIG=$(rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"sendTransaction\",\"params\":[\"$(cat "$W/issue.b64")\",{\"encoding\":\"base64\",\"skipPreflight\":true}]}" \
  | python3 -c "
import sys, json
r = json.load(sys.stdin)
print('ERR ' + json.dumps(r['error'])[:300] if 'error' in r else r['result'])")
case "$REFUSED_SIG" in ERR*) echo "    could not even send it: $REFUSED_SIG" >&2; exit 1;; esac
# Read the LANDED error back rather than trusting the send. A transaction that fails in preflight
# and one that fails on chain are different artifacts and only the second can be cited.
err=""
for _ in $(seq 1 40); do
  err=$(rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getTransaction\",\"params\":[\"$REFUSED_SIG\",{\"maxSupportedTransactionVersion\":0}]}" \
    | python3 -c "
import sys, json
r = json.load(sys.stdin).get('result')
print('' if not r else json.dumps(r['meta']['err']))")
  [ -n "$err" ] && break
  sleep 2
done
# json.dumps puts a space after the colon: {"InstructionError": [0, {"Custom": 24}]}. Matching
# without it reported the right refusal as the wrong one, which is worse than not matching at all.
case "$err" in
  *'"Custom": 24'*|*'"Custom":24'*|*"Custom(24)"*)
    printf '    %sREFUSED on chain — Custom(24), ConfidentialTransferAccountNotApproved%s\n' "$red" "$off"
    printf '    %s%s%s\n' "$dim" "$REFUSED_SIG" "$off"
    printf '    %sthe proofs are valid, the amounts are right, and the issuer has not signed.%s\n' "$dim" "$off";;
  null)
    echo "    IT SETTLED. The destination was approved when it should not have been — the gate" >&2
    echo "    this repository is about did not hold, and that is the finding, not this script." >&2
    exit 1;;
  "")
    echo "    the refused transaction never landed — nothing to cite" >&2; exit 1;;
  *)
    echo "    refused, but not for the reason this demonstrates: $err" >&2; exit 1;;
esac

echo
echo "  ${bold}--- the issuer signs for the account. One instruction ---${off}"
go "the issuer approves it" "$(cargo run --quiet -p confide-ct --bin seizure-client -- approve \
  "$W/issuer.json" "$investor_X" "$MINT_X" "$(bh)")"

echo
echo "  ${bold}--- the same allocation, sent again ---${off}"
build
go "the allocation" "$(cat "$W/issue.b64")"

echo
echo "  ${bold}--- what moved ---${off}"
prov apply "$W/investor.json" "$MINT_X" "$investor_X" "$ALLOC" "$W/investor-X-keys.json" "$DEC_X" >/dev/null
prov apply "$W/issuer.json"   "$MINT_Y" "$issuer_Y"   "$PAY"   "$W/issuer-Y-keys.json"   "$DEC_Y" >/dev/null
show() { local d a p o; read -r d a p o < <(ct "$2"); printf '    %-34s ' "$1"
  cargo run --quiet -p confide-ct --bin read-balance -- "$3" "$d" "$a" "$4" 2>/dev/null \
  | sed -n '3p' | sed 's/^ *//'; }
show "issuer, treasury (allocated from)" "$issuer_X"   "$W/issuer-X-keys.json"   "$DEC_X"
show "investor, stock (received)"        "$investor_X" "$W/investor-X-keys.json" "$DEC_X"
show "investor, cash (paid)"             "$investor_Y" "$W/investor-Y-keys.json" "$DEC_Y"
show "issuer, cash (received)"           "$issuer_Y"   "$W/issuer-Y-keys.json"   "$DEC_Y"

echo
pub() { local d a p o; read -r d a p o < <(ct "$1"); echo "$p"; }
printf '    %spublic balances: issuer stock %s, investor stock %s, investor cash %s, issuer cash %s%s\n' \
  "$dim" "$(pub "$issuer_X")" "$(pub "$investor_X")" "$(pub "$investor_Y")" "$(pub "$issuer_Y")" "$off"
echo
echo "  ${grn}${bold}An allocation was refused, the issuer signed, and the identical transaction settled."
echo "  The auditor slot was empty throughout — as it is on all 1,992 — because in primary issuance"
echo "  the issuer is the sender and needs no key to read what they sent.${off}"
echo
echo "    work dir  $W"
