#!/usr/bin/env bash
# Two holders exchange confidential positions in ONE transaction. No program, no escrow, no lender.
#
#   ./scripts/swap-e2e.sh
#   RPC=<endpoint> ./scripts/swap-e2e.sh
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

DECIMALS="${DECIMALS:-8}"
A_UNITS="${A_UNITS:-173000}"   # whole tokens Alice holds of X
B_UNITS="${B_UNITS:-91000}"    # whole tokens Bob holds of Y
A_SEND="${A_SEND:-50000}"      # what Alice sends
B_SEND="${B_SEND:-40000}"      # what Bob sends
bold=$'\033[1m'; dim=$'\033[2m'; grn=$'\033[32m'; off=$'\033[0m'

base() { python3 -c "print($1 * 10**$DECIMALS)"; }
elgamal() { python3 -c "import json;print(json.load(open('$1'))['elgamal_pubkey_b64'])"; }
# provision <step> <payer.json> <mint> <account> <amount> <keys.json>
prov() { go "$1" "$(cargo run --quiet -p confide-ct --bin provision -- "$1" "$2" "$3" "$4" "$5" "$(bh)" "$6" nofee 2>/dev/null)"; }
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
echo "  ${bold}--- two mints, both configured the way NVDAx is ---${off}"
for m in X Y; do
  MINT=$(spl-token -C "$W/issuer.yml" create-token --program-2022 --decimals "$DECIMALS" \
    --enable-confidential-transfers auto 2>&1 \
    | grep -oE 'Address:  *[1-9A-HJ-NP-Za-km-z]{32,44}' | awk '{print $2}')
  go "mint $m: auditor slot filled" "$(cargo run --quiet -p confide-ct --bin set-auditor -- \
    "$W/issuer.json" "$MINT" "$(bh)" "$W/auditor-$m.json" 2>/dev/null)"
  eval "MINT_$m=$MINT"
  echo "    mint $m    $MINT   ${dim}(auditor set, autoApproveNewAccounts false)${off}"
done

echo
echo "  ${bold}--- four ASSOCIATED token accounts. The loan could never use these ---${off}"
# The whole reason this path exists. An ATA carries ImmutableOwner, so it can never be handed to a
# loan PDA — docs/cwf-2026/THE-PINCER.md. A swap never hands anything over, so the extension is
# simply irrelevant here.
setup() { # setup <who> <mint-letter> <mint> <units>
  local who="$1" ml="$2" mint="$3" units="$4" acct
  spl-token -C "$W/$who.yml" create-account "$mint" >/dev/null 2>&1 || true
  acct=$(ata "$W/$who.yml" "$mint")
  [ "$units" = 0 ] || spl-token -C "$W/issuer.yml" mint "$mint" "$units" "$acct" >/dev/null
  prov configure "$W/$who.json" "$mint" "$acct" "$units" "$W/$who-$ml-keys.json"
  go "issuer approves it" "$(cargo run --quiet -p confide-ct --bin seizure-client -- approve \
    "$W/issuer.json" "$acct" "$mint" "$(bh)")"
  if [ "$units" != 0 ]; then
    prov deposit "$W/$who.json" "$mint" "$acct" "$units" "$W/$who-$ml-keys.json"
    prov apply   "$W/$who.json" "$mint" "$acct" "$units" "$W/$who-$ml-keys.json"
  fi
  eval "${who}_${ml}=$acct"
  echo "    $who's $ml   $acct   ${dim}(ATA, holding $units)${off}"
}
setup alice X "$MINT_X" "$A_UNITS"
setup bob   X "$MINT_X" 0
setup bob   Y "$MINT_Y" "$B_UNITS"
setup alice Y "$MINT_Y" 0

echo
echo "  ${bold}--- each side builds the proofs for their own leg ---${off}"
# Three proofs per leg, verified into context state accounts. This is the expensive, multi-
# transaction part, and it happens BEFORE the swap — which is exactly why the exchange itself is
# small enough to be one transaction.
build() { # build <who> <mint-letter> <mint> <source> <dest> <dest-keys> <send-units>
  local who="$1" ml="$2" mint="$3" src="$4" dst="$5" dkeys="$6" send="$7"
  local dec avail pub owner aud alt range
  read -r dec avail pub owner < <(ct "$src")
  aud=$(python3 -c "import json;print(json.load(open('$W/auditor-$ml.json'))['elgamal_pubkey_b64'])")
  local ctxf="$W/$who-ctx.json"
  cx() { cargo run --quiet -p confide-ct --bin seizure-ctx -- "$W/$who.json" "$W/$who-$ml-keys.json" \
    "$dec" "$avail" "$(elgamal "$dkeys")" "$aud" "$(base "$send")" "$(bh)" "$ctxf" \
    "$(solana-keygen pubkey "$W/$who.json")" "$W/$who-keys" "$1" none; }
  cx none >/dev/null 2>"$W/$who-pass1.err" || { cat "$W/$who-pass1.err" >&2; exit 1; }
  range=$(python3 -c "import json;print(json.load(open('$ctxf'))['range'])")
  alt=$(solana -u "$R" -k "$W/$who.json" address-lookup-table create \
        --authority "$(solana-keygen pubkey "$W/$who.json")" \
        | grep -oE 'Lookup Table Address: [1-9A-HJ-NP-Za-km-z]{32,44}' | awk '{print $NF}')
  solana -u "$R" -k "$W/$who.json" address-lookup-table extend "$alt" \
    --addresses "$range,$(solana-keygen pubkey "$W/$who.json")" >/dev/null
  sleep 3
  cx "$alt" > "$W/$who-txs.txt" 2>"$W/$who-pass2.err"
  local n=0; while read -r TX; do n=$((n+1)); go "$who proof tx $n" "$TX" >/dev/null || exit 1; done < "$W/$who-txs.txt"
  echo "    $who  $n transactions, three contexts, authority is $who themselves"
}
build alice X "$MINT_X" "$alice_X" "$bob_X"   "$W/bob-X-keys.json"   "$A_SEND"
build bob   Y "$MINT_Y" "$bob_Y"   "$alice_Y" "$W/alice-Y-keys.json" "$B_SEND"

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
prov apply "$W/bob.json"   "$MINT_X" "$bob_X"   "$A_SEND" "$W/bob-X-keys.json"   >/dev/null
prov apply "$W/alice.json" "$MINT_Y" "$alice_Y" "$B_SEND" "$W/alice-Y-keys.json" >/dev/null
show() { local d a p o; read -r d a p o < <(ct "$2"); printf '    %-22s ' "$1"
  cargo run --quiet -p confide-ct --bin read-balance -- "$3" "$d" "$a" 2>/dev/null | sed -n '3p' | sed 's/^ *//'; }
show "alice, mint X (sent)"     "$alice_X" "$W/alice-X-keys.json"
show "bob, mint X (received)"   "$bob_X"   "$W/bob-X-keys.json"
show "bob, mint Y (sent)"       "$bob_Y"   "$W/bob-Y-keys.json"
show "alice, mint Y (received)" "$alice_Y" "$W/alice-Y-keys.json"

echo
printf '  %sBoth positions moved, in one transaction, and the public balance of every one of those\n' "$grn"
printf '  four accounts is still 0. Nobody watching the chain learns either amount.%s\n\n' "$off"
echo "    work dir  $W"
echo
