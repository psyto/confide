#!/usr/bin/env bash
# Two holders exchange confidential positions in ONE transaction. No program, no escrow, no lender.
#
#   ./scripts/swap-e2e.sh            two equity wrappers, stock for stock
#   MODE=dvp ./scripts/swap-e2e.sh   stock for CASH — delivery versus payment, neither size public
#
# Everything else here is a loan, and a loan needs a third thing holding the collateral because it
# has to survive one party refusing to cooperate. That third thing is what ran into both walls:
# the escrow needs the issuer's approval, and an associated token account can never become one.
#
# A swap needs no third thing. Both legs are in one transaction, so either both settle or neither
# does — Solana's atomicity IS the escrow. So:
#
#   * no program is deployed, and none is called. Two Token-2022 instructions.
#   * NOTHING changes hands ownership-wise, so **associated token accounts work**, which is what
#     wallets create and what made the loan unreachable for most holders.
#   * no issuer approval beyond the one each account already needed to exist.
#
# The danger a swap does have is that the amounts are encrypted: a party could be asked to sign a
# transaction whose other leg sends far less than was agreed. That is answered before signing, by
# each side decrypting the other's amount straight out of the verified proof context — see
# `swap-check` below. It is the step this demonstration exists to show.
set -euo pipefail
cd "$(dirname "$0")/.."
R="${RPC:-https://api.devnet.solana.com}"
. "$(dirname "$0")/lib/chain.sh"
W="${WORK:-$(mktemp -d)}"; mkdir -p "$W"

# MODE=dvp makes the second mint a mirror of PYUSD instead of a second equity wrapper, so the
# demonstration is a block trade settling delivery-versus-payment rather than a stock-for-stock
# exchange. Stock-for-stock is rare; stock-for-cash is every block trade ever done, and settling it
# atomically is the thing TradFi needs a clearing house and a day for.
#
# The mirror is exact, measured off mainnet 2026-09-20 (docs/cwf-2026/COMPOSITION.md): 6 decimals,
# autoApproveNewAccounts false, auditor slot EMPTY, a zero-rate transfer fee config, a permanent
# delegate and a freeze authority — the last two mean the cash issuer can seize or freeze any
# account, which is what settling in PYUSD costs and is mirrored rather than quietly dropped.
MODE="${MODE:-swap}"
DECIMALS="${DECIMALS:-8}"      # the equity wrapper's
CASH_DECIMALS=6                # PYUSD's and USDG's
A_UNITS="${A_UNITS:-173000}"   # whole tokens Alice holds of X
A_SEND="${A_SEND:-50000}"      # what Alice sends
if [ "$MODE" = dvp ]; then
  B_UNITS="${B_UNITS:-9000000}"  # dollars Bob holds
  B_SEND="${B_SEND:-8750000}"    # $8.75m for 50,000 shares — $175 a share, agreed off chain
  DEC_Y=$CASH_DECIMALS
else
  B_UNITS="${B_UNITS:-91000}"
  B_SEND="${B_SEND:-40000}"
  DEC_Y="$DECIMALS"
fi
DEC_X="$DECIMALS"
bold=$'\033[1m'; dim=$'\033[2m'; grn=$'\033[32m'; off=$'\033[0m'

base() { python3 -c "print($1 * 10**$2)"; }
elgamal() { python3 -c "import json;print(json.load(open('$1'))['elgamal_pubkey_b64'])"; }
# provision <step> <payer.json> <mint> <account> <amount> <keys.json>
# The fee flag is read off the mint rather than passed in: the cash mirror carries a zero-rate
# transferFeeConfig exactly as PYUSD does, and a confidential account on a fee-bearing mint needs
# room for ConfidentialTransferFeeAmount whether the rate is zero or not.
prov() { go "$1" "$(cargo run --quiet -p confide-ct --bin provision -- "$1" "$2" "$3" "$4" "$5" "$(bh)" "$6" "$(mint_charges_fee "$3")" "$7" 2>/dev/null)"; }
ata()  { spl-token -C "$1" address --token "$2" --verbose 2>&1 \
         | grep -oE 'Associated token address: *[1-9A-HJ-NP-Za-km-z]{32,44}' | awk '{print $NF}'; }

echo
echo "  ${bold}--- three parties: an issuer, and two holders ---${off}"
FUNDER="${FUNDER:-$HOME/.config/solana/id.json}"
for k in issuer alice bob; do
  solana-keygen new --no-bip39-passphrase --silent --force -o "$W/$k.json" >/dev/null
  solana -u "$R" -k "$FUNDER" transfer --allow-unfunded-recipient \
    "$(solana-keygen pubkey "$W/$k.json")" 0.6 >/dev/null
  printf 'json_rpc_url: %s\nwebsocket_url: ""\nkeypair_path: %s\ncommitment: confirmed\n' "$R" "$W/$k.json" > "$W/$k.yml"
done
echo "    issuer    $(solana-keygen pubkey "$W/issuer.json")"
echo "    alice     $(solana-keygen pubkey "$W/alice.json")"
echo "    bob       $(solana-keygen pubkey "$W/bob.json")"

echo
if [ "$MODE" = dvp ]; then
  echo "  ${bold}--- the stock, and a mirror of PYUSD for the cash ---${off}"
else
  echo "  ${bold}--- two mints, both configured the way NVDAx is ---${off}"
fi
mk() { # mk <letter> <decimals> <auditor|none> [extra create-token flags...]
  local ml="$1" dec="$2" aud="$3"; shift 3
  local mint
  mint=$(spl-token -C "$W/issuer.yml" create-token --program-2022 --decimals "$dec" \
    --enable-confidential-transfers auto "$@" 2>&1 \
    | grep -oE 'Address:  *[1-9A-HJ-NP-Za-km-z]{32,44}' | awk '{print $2}')
  go "mint $ml: gate closed" "$(cargo run --quiet -p confide-ct --bin set-auditor -- \
    "$W/issuer.json" "$mint" "$(bh)" "$W/auditor-$ml.json" "$aud" 2>/dev/null)"
  eval "MINT_$ml=$mint"
  printf '    mint %s    %s   %s(%s decimals, autoApproveNewAccounts false, auditor %s, %s)%s\n' \
    "$ml" "$mint" "$dim" "$dec" "$([ "$aud" = none ] && echo EMPTY || echo set)" \
    "$(mint_charges_fee "$mint")" "$off"
}
mk X "$DEC_X" set
if [ "$MODE" = dvp ]; then
  # Every flag here is something PYUSD actually has on mainnet. The permanent delegate and the
  # freeze authority are the uncomfortable ones and are mirrored deliberately: whoever settles in
  # this cash is trusting an issuer who can take it back.
  # CASH_FEE and CASH_AUDITOR exist to split the mirror apart when it fails. PYUSD has both a
  # zero-rate fee config and an empty auditor slot, and if a plain confidential Transfer is
  # refused, one of those two is why. Guessing which would be the mistake this repository keeps
  # making; running it with one changed at a time is not.
  CASH_FEE="${CASH_FEE:-1}"; CASH_AUDITOR="${CASH_AUDITOR:-none}"
  # --enable-freeze because PYUSD names a freeze authority. It changes nothing about a transfer
  # between unfrozen accounts, and leaving it off would have made the mirror flattering.
  CASH_ARGS=(--enable-permanent-delegate --enable-close --enable-freeze)
  [ "$CASH_FEE" = 0 ] || CASH_ARGS+=(--transfer-fee-basis-points 0 --transfer-fee-maximum-fee 0)
  mk Y "$DEC_Y" "$CASH_AUDITOR" ${CASH_ARGS[@]+"${CASH_ARGS[@]}"}
else
  mk Y "$DEC_Y" set
fi

echo
if [ "$MODE" = dvp ]; then
  echo "  ${bold}--- four ASSOCIATED token accounts: Alice holds stock, Bob holds cash ---${off}"
else
  echo "  ${bold}--- four ASSOCIATED token accounts. The loan could never use these ---${off}"
fi
# The whole reason this path exists. An ATA carries ImmutableOwner, so it can never be handed to a
# loan PDA — docs/cwf-2026/THE-PINCER.md. A swap never hands anything over, so the extension is
# simply irrelevant here.
setup() { # setup <who> <mint-letter> <mint> <units> <decimals>
  local who="$1" ml="$2" mint="$3" units="$4" dec_n="$5" acct
  spl-token -C "$W/$who.yml" create-account "$mint" >/dev/null 2>&1 || true
  acct=$(ata "$W/$who.yml" "$mint")
  [ "$units" = 0 ] || spl-token -C "$W/issuer.yml" mint "$mint" "$units" "$acct" >/dev/null
  prov configure "$W/$who.json" "$mint" "$acct" "$units" "$W/$who-$ml-keys.json" "$dec_n"
  go "issuer approves it" "$(cargo run --quiet -p confide-ct --bin seizure-client -- approve \
    "$W/issuer.json" "$acct" "$mint" "$(bh)")"
  if [ "$units" != 0 ]; then
    prov deposit "$W/$who.json" "$mint" "$acct" "$units" "$W/$who-$ml-keys.json" "$dec_n"
    prov apply   "$W/$who.json" "$mint" "$acct" "$units" "$W/$who-$ml-keys.json" "$dec_n"
  fi
  eval "${who}_${ml}=$acct"
  echo "    $who's $ml   $acct   ${dim}(ATA, holding $units)${off}"
}
setup alice X "$MINT_X" "$A_UNITS" "$DEC_X"
setup bob   X "$MINT_X" 0 "$DEC_X"
setup bob   Y "$MINT_Y" "$B_UNITS" "$DEC_Y"
setup alice Y "$MINT_Y" 0 "$DEC_Y"

echo
echo "  ${bold}--- each side builds the proofs for their own leg ---${off}"
# Three proofs per leg, verified into context state accounts. This is the expensive, multi-
# transaction part, and it happens BEFORE the swap — which is exactly why the exchange itself is
# small enough to be one transaction.
build() { # build <who> <mint-letter> <mint> <source> <dest> <dest-keys> <send-units> <decimals>
  local who="$1" ml="$2" mint="$3" src="$4" dst="$5" dkeys="$6" send="$7" dec_n="$8"
  local dec avail pub owner aud alt range
  read -r dec avail pub owner < <(ct "$src")
  # An empty auditor slot is what PYUSD ships, so there is no key file to read. `none` is what
  # seizure-ctx has always taken for a mint that names no auditor.
  if [ -f "$W/auditor-$ml.json" ]; then
    aud=$(python3 -c "import json;print(json.load(open('$W/auditor-$ml.json'))['elgamal_pubkey_b64'])")
  else
    aud=none
  fi
  local ctxf="$W/$who-ctx.json"
  # Five proofs on a fee-bearing mint, three otherwise, and the mint decides rather than a flag:
  # a transferFeeConfig makes Token-2022 refuse the plain Transfer even at 0 bps.
  if [ "$(mint_charges_fee "$mint")" = fee ]; then
    local wh bps maxf
    read -r wh bps maxf < <(rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getAccountInfo\",\"params\":[\"$mint\",{\"encoding\":\"jsonParsed\"}]}" \
      | python3 -c "
import sys,json
i=json.load(sys.stdin)['result']['value']['data']['parsed']['info']
e={x['extension']:x.get('state',{}) for x in i.get('extensions',[])}
f=e['transferFeeConfig']['newerTransferFee']
print(e['confidentialTransferFeeConfig']['withdrawWithheldAuthorityElgamalPubkey'],
      f['transferFeeBasisPoints'], f['maximumFee'])")
    cx() { cargo run --quiet -p confide-ct --bin swap-ctx-fee -- "$W/$who.json" "$W/$who-$ml-keys.json" \
      "$dec" "$avail" "$(elgamal "$dkeys")" "$aud" "$wh" "$bps" "$maxf" \
      "$(base "$send" "$dec_n")" "$(bh)" "$ctxf" \
      "$(solana-keygen pubkey "$W/$who.json")" "$W/$who-keys" "$1" "${2:-0}"; }
  else
    cx() { cargo run --quiet -p confide-ct --bin seizure-ctx -- "$W/$who.json" "$W/$who-$ml-keys.json" \
      "$dec" "$avail" "$(elgamal "$dkeys")" "$aud" "$(base "$send" "$dec_n")" "$(bh)" "$ctxf" \
      "$(solana-keygen pubkey "$W/$who.json")" "$W/$who-keys" "$1" none; }
  fi
  cx none >/dev/null 2>"$W/$who-pass1.err" || { cat "$W/$who-pass1.err" >&2; exit 1; }
  range=$(python3 -c "import json;print(json.load(open('$ctxf'))['range'])")
  alt=$(solana -u "$R" -k "$W/$who.json" address-lookup-table create \
        --authority "$(solana-keygen pubkey "$W/$who.json")" \
        | grep -oE 'Lookup Table Address: [1-9A-HJ-NP-Za-km-z]{32,44}' | awk '{print $NF}')
  # The with-fee range proof is verified FROM an account, so the record holding it goes in the
  # table too. A missing address there is not an error — it is an account resolved the long way.
  local rec; rec=$(python3 -c "
import json;d=json.load(open('$ctxf'));print(d.get('record',''))")
  solana -u "$R" -k "$W/$who.json" address-lookup-table extend "$alt" \
    --addresses "$range,$(solana-keygen pubkey "$W/$who.json")${rec:+,$rec}" >/dev/null
  sleep 3
  cx "$alt" > "$W/$who-txs.txt" 2>"$W/$who-pass2.err"
  # `go` reports a rejection on stdout, and sending that to /dev/null cost a run: the script said
  # only "exit 1" and the reason was already thrown away.
  #
  # And they are sent in batches, because a blockhash does not live long enough for fourteen of
  # them — the thirteenth came back `BlockhashNotFound`. Each batch is rebuilt against a fresh
  # blockhash; the proofs themselves are cached on disk, so rebuilding re-signs rather than
  # re-proves, and `skip` keeps the already-landed creates from being sent twice.
  # Only the with-fee path is rebuilt between batches, because only it caches its proofs. Running
  # `seizure-ctx` a second time would generate DIFFERENT proofs for the same context accounts, so
  # its six transactions go in one batch and inside one blockhash, which is where they fit.
  local n=0 out sent=0 batch=99
  [ "$(python3 -c "
import json;print(1 if json.load(open('$ctxf')).get('with_fee') else 0)")" = 1 ] && batch=5
  while :; do
    local inbatch=0
    while read -r TX; do
      [ "$inbatch" -lt "$batch" ] || break
      n=$((n+1)); inbatch=$((inbatch+1))
      out=$(go "$who proof tx $n" "$TX") || { printf '%s\n' "$out" >&2; exit 1; }
    done < "$W/$who-txs.txt"
    sent=$((sent+inbatch))
    [ "$inbatch" -eq "$batch" ] || break
    cx "$alt" "$sent" > "$W/$who-txs.txt" 2>"$W/$who-pass2.err"
    [ -s "$W/$who-txs.txt" ] || break
  done
  local nctx; nctx=$(python3 -c "
import json;d=json.load(open('$ctxf'));print(5 if d.get('with_fee') else 3)")
  echo "    $who  $n transactions, $nctx contexts, authority is $who themselves"
}
build alice X "$MINT_X" "$alice_X" "$bob_X"   "$W/bob-X-keys.json"   "$A_SEND" "$DEC_X"
build bob   Y "$MINT_Y" "$bob_Y"   "$alice_Y" "$W/alice-Y-keys.json" "$B_SEND" "$DEC_Y"

echo
echo "  ${bold}--- BEFORE SIGNING: each side decrypts what the other will actually send ---${off}"
printf '  %sThis is the step that makes a confidential swap safe. Nobody is trusted and nothing is\n' "$dim"
printf '  revealed to anyone else: the amount is encrypted to the RECIPIENT as well as the sender,\n'
printf '  so the recipient reads it straight out of the already-verified proof context.%s\n' "$off"
look() { # look <who> <their-receiving-keys> <other's ctx.json>
  local v; v=$(python3 -c "import json;print(json.load(open('$3'))['validity'])")
  local data; data=$(rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getAccountInfo\",\"params\":[\"$v\",{\"encoding\":\"base64\"}]}" \
    | python3 -c "import sys,json;print(json.load(sys.stdin)['result']['value']['data'][0])")
  echo "    ${bold}$1 checks the leg addressed to them${off}   ${dim}context $v${off}"
  cargo run --quiet -p confide-ct --bin swap-check -- "$2" "$data" 2>/dev/null
}
look alice "$W/alice-Y-keys.json" "$W/bob-ctx.json"
look bob   "$W/bob-X-keys.json"   "$W/alice-ctx.json"

echo "  ${bold}--- ONE transaction, two confidential transfers, two signatures ---${off}"
cargo run --quiet -p confide-ct --bin swap-tx -- "$W/alice.json" "$(bh)" \
  "$W/alice.json" "$W/alice-ctx.json" "$alice_X" "$bob_X"   "$MINT_X" \
  "$W/bob.json"   "$W/bob-ctx.json"   "$bob_Y"   "$alice_Y" "$MINT_Y" \
  >"$W/swap.b64" 2>"$W/swap.size"
grep -a "one transaction" "$W/swap.size" || true
go "the swap" "$(cat "$W/swap.b64")"

echo
echo "  ${bold}--- what each of them holds now ---${off}"
# Confidential transfers land in the PENDING balance; the owner applies it with their own key.
prov apply "$W/bob.json"   "$MINT_X" "$bob_X"   "$A_SEND" "$W/bob-X-keys.json"   "$DEC_X" >/dev/null
prov apply "$W/alice.json" "$MINT_Y" "$alice_Y" "$B_SEND" "$W/alice-Y-keys.json" "$DEC_Y" >/dev/null
show() { local d a p o; read -r d a p o < <(ct "$2"); printf '    %-24s ' "$1"
  cargo run --quiet -p confide-ct --bin read-balance -- "$3" "$d" "$a" "$4" 2>/dev/null | sed -n '3p' | sed 's/^ *//'; }
if [ "$MODE" = dvp ]; then LX="stock"; LY="cash"; else LX="mint X"; LY="mint Y"; fi
show "alice, $LX (delivered)"  "$alice_X" "$W/alice-X-keys.json" "$DEC_X"
show "bob, $LX (received)"     "$bob_X"   "$W/bob-X-keys.json"   "$DEC_X"
show "bob, $LY (paid)"         "$bob_Y"   "$W/bob-Y-keys.json"   "$DEC_Y"
show "alice, $LY (received)"   "$alice_Y" "$W/alice-Y-keys.json" "$DEC_Y"

echo
if [ "$MODE" = dvp ]; then
  printf '  %sDelivery and payment happened in the same transaction — neither could occur without the\n' "$grn"
  printf '  other, and no clearing house stood between them. The public balance of all four accounts\n'
  printf '  is still 0: nobody watching learns the size of the trade or the price it implies.%s\n\n' "$off"
else
  printf '  %sBoth positions moved, in one transaction, and the public balance of every one of those\n' "$grn"
  printf '  four accounts is still 0. Nobody watching the chain learns either amount.%s\n\n' "$off"
fi
echo "    work dir  $W"
echo
