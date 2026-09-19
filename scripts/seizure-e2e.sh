#!/usr/bin/env bash
# Seize confidential collateral, end to end, on a validator that is not pretending.
#
#   solana-test-validator --reset --quiet --url https://api.devnet.solana.com \
#     --clone-upgradeable-program TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb
#   ./scripts/seizure-e2e.sh
#
# The clone is not optional. solana-test-validator bundles an older Token-2022 whose confidential
# transfer instructions this repository's encoding is rejected by — `Deposit` comes back
# InvalidInstructionData, which reads like a client bug and is not one.
#
# What this demonstrates, in order: a borrower holds 173,000 tokens that read as zero in public;
# they build the three transfer proofs while they still hold the key and park them on chain under
# an authority they do not control; they hand the escrow to a program; the price falls; anyone
# fires the seizure; the lender ends up holding the position, still confidential. The borrower
# signs nothing after the handover and no key is ever reconstructed. docs/SEIZURE.md is the design.
set -euo pipefail
cd "$(dirname "$0")/.."
R="${RPC:-http://127.0.0.1:8899}"
W="${WORK:-$(mktemp -d)}"
UNITS="${UNITS:-173000}"
Q_MIN="${Q_MIN:-100000}"        # whole tokens the borrower PROVED, not what they hold
DECIMALS="${DECIMALS:-8}"       # the mirror mint's, below; the program reads the real one off chain
FLOOR_BASE=$(python3 -c "print($Q_MIN * 10**$DECIMALS)")   # what the floor proof is actually over
PRINCIPAL="${PRINCIPAL:-5000000}"  # cents — a $50,000 loan
RATIO_BPS="${RATIO_BPS:-20000}"    # 200 % collateralisation
PRICE_OK="${PRICE_OK:-100}"        # cents per token: exactly covers it
PRICE_BAD="${PRICE_BAD:-99}"       # one cent under, and the loan is in default
# Which exit to demonstrate. Same loan, same setup, two endings: `seize` is the lender taking it on
# default, `release` is the holder getting it back. One script, because the twenty steps before the
# branch are the same twenty steps and a second copy of them would drift within a week.
#   open     — originate and stop, leaving a loan a lender can actually check and lend against
MODE="${MODE:-seize}"

. "$(dirname "$0")/lib/chain.sh"

prov() { go "$1" "$(cargo run --quiet -p confide-ct --bin provision -- "$1" "$2" "$MINT" "$3" "$4" "$(bh)" "$5" "$FEE" 2>/dev/null)"; }

# The bundled Token-2022 is older than the one on devnet and silently refuses current instructions.
SZ=$(rpc '{"jsonrpc":"2.0","id":1,"method":"getAccountInfo","params":["DoU57AYuPFu2QU514RktNPG22QhApEjnKxnBcu4BHDTY",{"encoding":"base64","dataSlice":{"offset":0,"length":0}}]}' \
  | python3 -c "import sys,json;v=json.load(sys.stdin)['result']['value'];print(v['space'] if v else 0)")
[ "$SZ" -ge 700000 ] || { echo "  Token-2022 on $R is $SZ bytes — the bundled build, not the real one."; echo "  Start the validator with --clone-upgradeable-program TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb"; exit 1; }

echo "  --- parties ---"
# The faucet only answers on a local validator. Anywhere else, FUNDER pays the two parties in —
# naming the keypair rather than trusting `solana config`, which on this machine points at another
# project's key entirely. See docs/DURABILITY.md.
FUNDER="${FUNDER:-$HOME/.config/solana/id.json}"
for k in borrower lender; do
  solana-keygen new --no-bip39-passphrase --silent --force -o "$W/$k.json" >/dev/null
  case "$R" in
    *127.0.0.1*|*localhost*) solana -u "$R" airdrop 50 "$(solana-keygen pubkey "$W/$k.json")" >/dev/null;;
    *) solana -u "$R" -k "$FUNDER" transfer --allow-unfunded-recipient \
         "$(solana-keygen pubkey "$W/$k.json")" 0.5 >/dev/null;;
  esac
  printf 'json_rpc_url: %s\nwebsocket_url: ""\nkeypair_path: %s\ncommitment: confirmed\n' "$R" "$W/$k.json" > "$W/$k.yml"
done
echo "    borrower  $(solana-keygen pubkey "$W/borrower.json")"
echo "    lender    $(solana-keygen pubkey "$W/lender.json")"

echo "  --- the mint, configured the way NVDAx is ---"
# FEE_BPS mirrors a PreStocks mint instead of an xStock one. PreStocks charges 50 bps on every
# transfer, confidential ones included, and Confide builds the plain confidential `Transfer` rather
# than `TransferWithFee`. Rather than assert what that does, run it: `FEE_BPS=50 ./scripts/seizure-e2e.sh`.
FEE_BPS="${FEE_BPS:-0}"
# Expanded as ${FEE_ARGS[@]+...} below: bash 3.2 treats an empty array as unbound under `set -u`,
# so the plain "${FEE_ARGS[@]}" broke the default path and only the default path.
FEE_ARGS=()
[ "$FEE_BPS" = 0 ] || FEE_ARGS=(--transfer-fee-basis-points "$FEE_BPS" --transfer-fee-maximum-fee 18446744073709551615)
MINT=$(spl-token -C "$W/borrower.yml" create-token --program-2022 --decimals "$DECIMALS" \
  ${FEE_ARGS[@]+"${FEE_ARGS[@]}"} --enable-confidential-transfers auto 2>&1 \
  | grep -oE 'Address:  *[1-9A-HJ-NP-Za-km-z]{32,44}' | awk '{print $2}')
go "auditor slot filled" "$(cargo run --quiet -p confide-ct --bin set-auditor -- "$W/borrower.json" "$MINT" "$(bh)" "$W/auditor.json" 2>/dev/null)"
FEE=$(mint_charges_fee "$MINT")
echo "    mint      $MINT   (auditor set, autoApproveNewAccounts false — as on NVDAx; $FEE)"

echo "  --- the escrow. NOT an associated account: an ATA carries ImmutableOwner and can never be handed over ---"
solana-keygen new --no-bip39-passphrase --silent --force -o "$W/escrow.json" >/dev/null
spl-token -C "$W/borrower.yml" create-account "$MINT" "$W/escrow.json" >/dev/null
ESCROW=$(solana-keygen pubkey "$W/escrow.json")
spl-token -C "$W/borrower.yml" mint "$MINT" "$UNITS" "$ESCROW" >/dev/null
prov configure "$W/borrower.json" "$ESCROW" "$UNITS" "$W/escrow-keys.json"
go "issuer approves it" "$(cargo run --quiet -p confide-ct --bin seizure-client -- approve "$W/borrower.json" "$ESCROW" "$MINT" "$(bh)")"
prov deposit "$W/borrower.json" "$ESCROW" "$UNITS" "$W/escrow-keys.json"
prov apply   "$W/borrower.json" "$ESCROW" "$UNITS" "$W/escrow-keys.json"

echo "  --- the lender's account ---"
spl-token -C "$W/lender.yml" create-account "$MINT" >/dev/null
DEST=$(spl-token -C "$W/lender.yml" address --token "$MINT" --verbose 2>&1 \
  | grep -oE 'Associated token address: *[1-9A-HJ-NP-Za-km-z]{32,44}' | awk '{print $NF}')
prov configure "$W/lender.json" "$DEST" 0 "$W/lender-keys.json"
go "issuer approves it" "$(cargo run --quiet -p confide-ct --bin seizure-client -- approve "$W/borrower.json" "$DEST" "$MINT" "$(bh)")"

echo "  --- the program ---"
PROGRAM="${PROGRAM:-}"
if [ -z "$PROGRAM" ]; then
  ( cd programs/confide-seizure && cargo build-sbf --arch v3 >/dev/null 2>&1 )
  solana -u "$R" -k "$W/borrower.json" program deploy \
    programs/confide-seizure/target/deploy/confide_seizure.so \
    --program-id programs/confide-seizure/target/deploy/confide_seizure-keypair.json >/dev/null
  PROGRAM=$(solana-keygen pubkey programs/confide-seizure/target/deploy/confide_seizure-keypair.json)
fi
LOAN=$(cargo run --quiet -p confide-ct --bin seizure-client -- pda "$PROGRAM" "$ESCROW")
echo "    program   $PROGRAM"
echo "    loan pda  $LOAN"

echo "  --- what the borrower holds, and what anyone can see ---"
read -r DEC AVAIL PUB OWNER < <(ct "$ESCROW")
echo "    public    $PUB"
cargo run --quiet -p confide-ct --bin read-balance -- "$W/escrow-keys.json" "$DEC" "$AVAIL" 2>/dev/null | sed -n '3p' | sed 's/^ */    /'

echo "  --- the proofs, built while the borrower still wants the loan ---"
LENDER_PK=$(python3 -c "import json;print(json.load(open('$W/lender-keys.json'))['elgamal_pubkey_b64'])")
AUDITOR_PK=$(python3 -c "import json;print(json.load(open('$W/auditor.json'))['elgamal_pubkey_b64'])")
ctx() { cargo run --quiet -p confide-ct --bin seizure-ctx -- "$W/borrower.json" "$W/escrow-keys.json" \
  "$DEC" "$AVAIL" "$LENDER_PK" "$AUDITOR_PK" all "$(bh)" "$W/ctx.json" "$LOAN" "$W/keys" "$1" \
  "$FLOOR_BASE"; }
ctx none >/dev/null 2>"$W/pass1.err"
RANGE=$(python3 -c "import json;print(json.load(open('$W/ctx.json'))['range'])")
ALT=$(solana -u "$R" -k "$W/borrower.json" address-lookup-table create --authority "$(solana-keygen pubkey "$W/borrower.json")" \
  | grep -oE 'Lookup Table Address: [1-9A-HJ-NP-Za-km-z]{32,44}' | awk '{print $NF}')
solana -u "$R" -k "$W/borrower.json" address-lookup-table extend "$ALT" --addresses "$RANGE,$LOAN" >/dev/null
sleep 3
ctx "$ALT" > "$W/txs.txt" 2>"$W/pass2.err"
grep -E "verify tx" "$W/pass2.err" | sed 's/^ */    /'
n=0; while read -r TX; do n=$((n+1)); go "context tx $n" "$TX" >/dev/null || exit 1; done < "$W/txs.txt"
echo "    $n context transactions confirmed, authority is the loan PDA"

echo "  --- the handover: the borrower gives up the escrow, balance and all ---"
go "SetAuthority" "$(cargo run --quiet -p confide-ct --bin seizure-client -- handover "$W/borrower.json" "$ESCROW" "$LOAN" "$(bh)")"
read -r DEC AVAIL PUB OWNER < <(ct "$ESCROW")
echo "    owner is now $OWNER"
[ "$OWNER" = "$LOAN" ] || { echo "    the escrow did not change hands"; exit 1; }

echo "  --- the loan ---"
# The last argument is the release authority: who may hand the collateral back. Recorded here,
# while both sides are present, because the borrower arms the destination later and must not also
# be able to choose the trigger. It is the lender, and it is the same key that signs the oracle
# price — a separate key would be more realistic and would demonstrate nothing extra.
cargo run --quiet -p confide-ct --bin seizure-client -- originate "$W/borrower.json" "$PROGRAM" "$W/ctx.json" \
  "$ESCROW" "$DEST" "$MINT" "$(solana-keygen pubkey "$W/lender.json")" \
  "$Q_MIN" "$PRINCIPAL" "$RATIO_BPS" "$(solana-keygen pubkey "$W/lender.json")" "$(bh)" > "$W/orig.txt" 2>/dev/null
go "originate" "$(cat "$W/orig.txt")"
echo "    proved floor $Q_MIN tokens against a \$$((PRINCIPAL/100)) loan at $((RATIO_BPS/100))%"

if [ "$MODE" = open ]; then
  # Stop here. Everything above is the borrower's half: the collateral is locked under the loan PDA,
  # the floor is proved against the escrow's current ciphertext, and the seizure route is armed to
  # the lender's account. Nothing after this point is the borrower's to do.
  echo
  echo "  --- the loan is open. What the lender checks, and how ---"
  echo
  echo "    ./scripts/lender-check.sh \\"
  echo "      $LOAN \\"
  echo "      $DEST \\"
  echo "      $Q_MIN $PRINCIPAL $RATIO_BPS"
  echo
  echo "  The lender runs that themselves, against the chain, and it calls the program's own"
  echo "  predicates rather than a second copy of them. It answers whether the collateral is out of"
  echo "  the borrower's hands and whether the floor is about the balance the escrow holds now."
  echo "  It says nothing about whether the asset is worth lending against — docs/packets/."
  exit 0
fi

if [ "$MODE" = release ]; then
  # ── the way back ───────────────────────────────────────────────────────────────────────────────
  # Everything above is the same loan. What differs is which exit fires. The escrow used to have
  # one, and it was the one the holder does not want.
  echo "  --- the borrower's return account, configured the way the lender's was ---"
  spl-token -C "$W/borrower.yml" create-account "$MINT" >/dev/null
  BACK=$(spl-token -C "$W/borrower.yml" address --token "$MINT" --verbose 2>&1 \
    | grep -oE 'Associated token address: *[1-9A-HJ-NP-Za-km-z]{32,44}' | awk '{print $NF}')
  prov configure "$W/borrower.json" "$BACK" 0 "$W/back-keys.json"
  go "issuer approves it" "$(cargo run --quiet -p confide-ct --bin seizure-client -- approve "$W/borrower.json" "$BACK" "$MINT" "$(bh)")"
  echo "    back      $BACK"

  echo "  --- a second set of proofs, over the same escrow ciphertext, to a different recipient ---"
  # The escrow's balance cannot change while the loan PDA owns it, so both exits can be proved
  # against the same source state and exactly one of them will ever fire.
  BACK_PK=$(python3 -c "import json;print(json.load(open('$W/back-keys.json'))['elgamal_pubkey_b64'])")
  read -r DEC AVAIL PUB OWNER < <(ct "$ESCROW")
  rctx() { cargo run --quiet -p confide-ct --bin seizure-ctx -- "$W/borrower.json" "$W/escrow-keys.json" \
    "$DEC" "$AVAIL" "$BACK_PK" "$AUDITOR_PK" all "$(bh)" "$W/rctx.json" "$LOAN" "$W/keys-release" "$1" \
    "$FLOOR_BASE"; }
  rctx none >/dev/null 2>"$W/rpass1.err"
  RRANGE=$(python3 -c "import json;print(json.load(open('$W/rctx.json'))['range'])")
  # A SECOND table, not an extension of the first. seizure-ctx compiles the v0 message against
  # `[range_account, authority]` at indices 0 and 1, so extending the existing table put this
  # range account at index 2 and the message resolved index 0 to the seizure set's range account —
  # which is already initialised. The failure read as AccountAlreadyInitialized on a create, three
  # steps away from the cause.
  RALT=$(solana -u "$R" -k "$W/borrower.json" address-lookup-table create --authority "$(solana-keygen pubkey "$W/borrower.json")" \
    | grep -oE 'Lookup Table Address: [1-9A-HJ-NP-Za-km-z]{32,44}' | awk '{print $NF}')
  solana -u "$R" -k "$W/borrower.json" address-lookup-table extend "$RALT" --addresses "$RRANGE,$LOAN" >/dev/null
  sleep 3
  rctx "$RALT" > "$W/rtxs.txt" 2>"$W/rpass2.err"
  n=0; while read -r TX; do n=$((n+1)); go "release context tx $n" "$TX" || exit 1; done < "$W/rtxs.txt"
  echo "    $n context transactions confirmed"

  echo "  --- the borrower arms the way back; the lender still has to sign ---"
  go "arm-release" "$(cargo run --quiet -p confide-ct --bin seizure-client -- arm-release "$W/borrower.json" "$PROGRAM" "$W/rctx.json" \
    "$ESCROW" "$BACK" "$(bh)")"

  echo "  --- the borrower cannot release it themselves ---"
  SIG=$(send "$(cargo run --quiet -p confide-ct --bin seizure-client -- release "$W/borrower.json" "$PROGRAM" "$W/rctx.json" \
    "$ESCROW" "$BACK" "$MINT" "$W/borrower.json" "$(bh)")")
  case "$SIG" in ERR*) echo "    the program refuses — the authority is the lender's, recorded at origination";;
    *) echo "    the borrower released their own collateral, and should not have been able to"; exit 1;; esac

  echo "  --- the lender signs, and it goes back ---"
  go "release" "$(cargo run --quiet -p confide-ct --bin seizure-client -- release "$W/borrower.json" "$PROGRAM" "$W/rctx.json" \
    "$ESCROW" "$BACK" "$MINT" "$W/lender.json" "$(bh)")"

  echo "  --- where the position ended up ---"
  read -r DEC AVAIL PUB OWNER < <(ct "$ESCROW")
  printf '    escrow    '; cargo run --quiet -p confide-ct --bin read-balance -- "$W/escrow-keys.json" "$DEC" "$AVAIL" 2>/dev/null | sed -n '3p' | sed 's/^ *//'
  prov apply "$W/borrower.json" "$BACK" "$UNITS" "$W/back-keys.json" >/dev/null
  read -r DEC AVAIL PUB OWNER < <(ct "$BACK")
  printf '    borrower  '; cargo run --quiet -p confide-ct --bin read-balance -- "$W/back-keys.json" "$DEC" "$AVAIL" 2>/dev/null | sed -n '3p' | sed 's/^ *//'
  echo
  echo "  The lender could not send it anywhere but the account the borrower armed, and could not"
  echo "  make the borrower sign again. What they could have done is refuse to sign at all: this is"
  echo "  an attested release, not a repayment, and no principal moves through this program."
  exit 0
fi

echo "  --- a price that does not trigger it ---"
SIG=$(send "$(cargo run --quiet -p confide-ct --bin seizure-client -- seize "$W/borrower.json" "$PROGRAM" "$W/ctx.json" \
  "$ESCROW" "$DEST" "$MINT" "$W/lender.json" "$PRICE_OK" "$(bh)")")
case "$SIG" in ERR*) echo "    at ${PRICE_OK}c the program refuses — correct";; *) echo "    at ${PRICE_OK}c the seizure went through, and should not have"; exit 1;; esac

echo "  --- and one that does ---"
go "seize at ${PRICE_BAD}c" "$(cargo run --quiet -p confide-ct --bin seizure-client -- seize "$W/borrower.json" "$PROGRAM" "$W/ctx.json" \
  "$ESCROW" "$DEST" "$MINT" "$W/lender.json" "$PRICE_BAD" "$(bh)")"

echo "  --- where the position ended up ---"
read -r DEC AVAIL PUB OWNER < <(ct "$ESCROW")
printf '    escrow    '; cargo run --quiet -p confide-ct --bin read-balance -- "$W/escrow-keys.json" "$DEC" "$AVAIL" 2>/dev/null | sed -n '3p' | sed 's/^ *//'
prov apply "$W/lender.json" "$DEST" "$UNITS" "$W/lender-keys.json" >/dev/null
read -r DEC AVAIL PUB OWNER < <(ct "$DEST")
printf '    lender    '; cargo run --quiet -p confide-ct --bin read-balance -- "$W/lender-keys.json" "$DEC" "$AVAIL" 2>/dev/null | sed -n '3p' | sed 's/^ *//'
echo
echo "  The borrower signed nothing after the handover. No key was reconstructed, no committee was"
echo "  asked, and the position was confidential on both sides of the transfer the whole way."
