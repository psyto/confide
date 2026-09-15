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
PRINCIPAL="${PRINCIPAL:-5000000}"  # cents — a $50,000 loan
RATIO_BPS="${RATIO_BPS:-20000}"    # 200 % collateralisation
PRICE_OK="${PRICE_OK:-100}"        # cents per token: exactly covers it
PRICE_BAD="${PRICE_BAD:-99}"       # one cent under, and the loan is in default

rpc() { curl -s "$R" -H 'Content-Type: application/json' -d "$1"; }
bh() { rpc '{"jsonrpc":"2.0","id":1,"method":"getLatestBlockhash","params":[{"commitment":"confirmed"}]}' \
  | python3 -c "import sys,json;print(json.load(sys.stdin)['result']['value']['blockhash'])"; }
send() { rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"sendTransaction\",\"params\":[\"$1\",{\"encoding\":\"base64\",\"preflightCommitment\":\"confirmed\"}]}" \
  | python3 -c "
import sys,json
r=json.load(sys.stdin)
print('ERR '+json.dumps(r['error'])[:300] if 'error' in r else r['result'])"; }
confirm() { for _ in $(seq 1 40); do st=$(rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getSignatureStatuses\",\"params\":[[\"$1\"],{\"searchTransactionHistory\":true}]}" \
  | python3 -c "
import sys,json
v=json.load(sys.stdin)['result']['value'][0]
print('pending' if v is None else ('FAILED '+json.dumps(v['err'])[:250] if v.get('err') else (v.get('confirmationStatus') or 'pending')))"); \
  case "$st" in confirmed|finalized) return 0;; FAILED*) echo "    $st"; return 1;; esac; sleep 1; done; echo "    timeout"; return 1; }
go() { local label="$1"; shift; local sig; sig=$(send "$1"); case "$sig" in ERR*) echo "    $label: $sig"; return 1;; esac; confirm "$sig" && printf '    %-22s ok\n' "$label"; }
ct() { rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getAccountInfo\",\"params\":[\"$1\",{\"encoding\":\"jsonParsed\",\"commitment\":\"confirmed\"}]}" \
  | python3 -c "
import sys,json
i=json.load(sys.stdin)['result']['value']['data']['parsed']['info']
s=next(e['state'] for e in i['extensions'] if e['extension']=='confidentialTransferAccount')
print(s['decryptableAvailableBalance'], s['availableBalance'], i['tokenAmount']['uiAmountString'], i['owner'])"; }
prov() { go "$1" "$(cargo run --quiet -p confide-ct --bin provision -- "$1" "$2" "$MINT" "$3" "$4" "$(bh)" "$5" 2>/dev/null)"; }

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
MINT=$(spl-token -C "$W/borrower.yml" create-token --program-2022 --decimals 8 --enable-confidential-transfers auto 2>&1 \
  | grep -oE 'Address:  *[1-9A-HJ-NP-Za-km-z]{32,44}' | awk '{print $2}')
go "auditor slot filled" "$(cargo run --quiet -p confide-ct --bin set-auditor -- "$W/borrower.json" "$MINT" "$(bh)" "$W/auditor.json" 2>/dev/null)"
echo "    mint      $MINT   (auditor set, autoApproveNewAccounts false — as on NVDAx)"

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
  "$DEC" "$AVAIL" "$LENDER_PK" "$AUDITOR_PK" all "$(bh)" "$W/ctx.json" "$LOAN" "$W/keys" "$1"; }
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
cargo run --quiet -p confide-ct --bin seizure-client -- originate "$W/borrower.json" "$PROGRAM" "$W/ctx.json" \
  "$ESCROW" "$DEST" "$MINT" "$(solana-keygen pubkey "$W/lender.json")" \
  "$Q_MIN" "$PRINCIPAL" "$RATIO_BPS" "$(bh)" > "$W/orig.txt" 2>/dev/null
go "originate" "$(cat "$W/orig.txt")"
echo "    proved floor $Q_MIN tokens against a \$$((PRINCIPAL/100)) loan at $((RATIO_BPS/100))%"

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
