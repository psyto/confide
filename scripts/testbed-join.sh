#!/usr/bin/env bash
# Open a confidential position on the standing devnet issuer. **You need nothing from us.**
#
#   ./scripts/testbed-join.sh [your-keypair.json]
#
# This is the thing 329,536 live token accounts have never done — `./scripts/usage-scan.sh`. On
# mainnet it cannot be done, because a confidential account needs the issuer's signature and no
# issuer has given one. Here the issuer has published the key that gives it, so the gate is shut
# exactly as it is on all 1,992 real mints and **you can operate it yourself**.
#
# What you end up with: a token account whose public balance reads 0 and which holds a real
# confidential balance only you can read. Then `MODE=dvp ./scripts/swap-e2e.sh` is the trade, and
# docs/TESTBED.md says how two of you do it against each other.
#
# It is devnet. The tokens represent nothing and are worth nothing.
set -euo pipefail
cd "$(dirname "$0")/.."
R="${RPC:-https://api.devnet.solana.com}"
. "$(dirname "$0")/lib/chain.sh"
T=web/testbed.json
UNITS="${UNITS:-5000}"
bold=$'\033[1m'; dim=$'\033[2m'; grn=$'\033[32m'; off=$'\033[0m'
[ -f "$T" ] || { echo "  $T is missing — the testbed has not been stood up"; exit 1; }

ROLE="${ROLE:-equity}"
read -r MINT DEC FAUCET < <(python3 -c "
import json;d=json.load(open('$T'))['mints']['$ROLE'];print(d['mint'],d['decimals'],d['faucet_account'])")
APPROVAL=$(python3 -c "import json;print(json.load(open('$T'))['approval_secret'])")
FAUCETKEY=$(python3 -c "import json;print(json.load(open('$T'))['faucet_secret'])")

W="${WORK:-$(mktemp -d)}"; mkdir -p "$W"
KP="${1:-$W/you.json}"
[ -f "$KP" ] || { solana-keygen new --no-bip39-passphrase --silent --force -o "$KP" >/dev/null
                  solana -u "$R" airdrop 1 "$(solana-keygen pubkey "$KP")" >/dev/null 2>&1 \
                  || solana -u "$R" -k "${FUNDER:-$HOME/.config/solana/id.json}" transfer \
                       --allow-unfunded-recipient "$(solana-keygen pubkey "$KP")" 0.4 >/dev/null; }
YOU=$(solana-keygen pubkey "$KP")
printf 'json_rpc_url: %s\nwebsocket_url: ""\nkeypair_path: %s\ncommitment: confirmed\n' "$R" "$KP" > "$W/you.yml"

echo
echo "  ${bold}--- you ---${off}"
echo "    wallet   $YOU"
echo "    mint     $MINT   ${dim}($ROLE, $DEC decimals, autoApproveNewAccounts false)${off}"

echo
echo "  ${bold}--- an ordinary associated token account, and a balance from the faucet ---${off}"
spl-token -C "$W/you.yml" create-account "$MINT" >/dev/null 2>&1 || true
ACC=$(spl-token -C "$W/you.yml" address --token "$MINT" --verbose 2>&1 \
      | grep -oE 'Associated token address: *[1-9A-HJ-NP-Za-km-z]{32,44}' | awk '{print $NF}')
printf 'json_rpc_url: %s\nwebsocket_url: ""\nkeypair_path: %s\ncommitment: confirmed\n' "$R" "$PWD/$FAUCETKEY" > "$W/faucet.yml"
spl-token -C "$W/faucet.yml" transfer "$MINT" "$UNITS" "$ACC" --allow-unfunded-recipient >/dev/null
echo "    account  $ACC   ${dim}(public balance $UNITS — visible to everyone, for now)${off}"

echo
echo "  ${bold}--- the gate. It is shut, and you open it yourself ---${off}"
cargo run --quiet -p confide-ct --bin provision -- configure "$KP" "$MINT" "$ACC" 0 "$(bh)" "$W/keys.json" \
  "$(mint_charges_fee "$MINT")" "$DEC" > "$W/cfg.txt" 2>/dev/null
go "you configure the account" "$(cat "$W/cfg.txt")"
go "the ISSUER approves it" "$(cargo run --quiet -p confide-ct --bin seizure-client -- approve \
  "$APPROVAL" "$ACC" "$MINT" "$(bh)")"
printf '    %ssigned with keys/devnet-approval-authority.json — published, and it cannot mint.%s\n' "$dim" "$off"

echo
echo "  ${bold}--- and the position goes dark ---${off}"
prov() { go "$1" "$(cargo run --quiet -p confide-ct --bin provision -- "$1" "$KP" "$MINT" "$ACC" "$UNITS" "$(bh)" "$W/keys.json" "$(mint_charges_fee "$MINT")" "$DEC" 2>/dev/null)"; }
prov deposit
prov apply
read -r DECB AVAIL PUB OWNER < <(ct "$ACC")
echo
echo "    public balance   $PUB   ${dim}<- what the chain shows anyone, from here on${off}"
printf '    '; cargo run --quiet -p confide-ct --bin read-balance -- "$W/keys.json" "$DECB" "$AVAIL" "$DEC" 2>/dev/null | sed -n '3p' | sed 's/^ *//'
echo
printf '  %sYou are the first kind of account that does not exist on mainnet.%s\n' "$grn" "$off"
echo "    explorer  https://explorer.solana.com/address/$ACC?cluster=devnet"
echo "    keys      $W/keys.json   ${dim}(your ElGamal secret — lose it and the balance is unreadable)${off}"
echo "    trade     docs/TESTBED.md"
echo
