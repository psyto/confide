#!/usr/bin/env bash
# STEP 4 of 4 — you CHECK what they will send you, add the second signature, and the trade settles.
#
#   ./scripts/swap-sign.sh <your-keypair.json> settle.json
#
# Same check as step 3, from the other side. Their amount is encrypted to your receiving key, so
# you read it out of the verified context yourself.
#
# **This is the irreversible step.** Until you run it the transaction has one of two signatures and
# cannot execute. After it, delivery and payment have both happened, in the same transaction,
# and neither could have happened without the other.
set -euo pipefail
cd "$(dirname "$0")/.."
. "$(dirname "$0")/lib/chain.sh"
. "$(dirname "$0")/lib/swap.sh"
R="${RPC:-https://api.devnet.solana.com}"
W="${WORK:-$HOME/.config/confide/swap}"; mkdir -p "$W"
bold=$'\033[1m'; dim=$'\033[2m'; grn=$'\033[32m'; off=$'\033[0m'

KEY="${1:?usage: swap-sign.sh <keypair.json> settle.json}"
SET="${2:?usage: swap-sign.sh <keypair.json> settle.json}"
ME=$(solana-keygen pubkey "$KEY")

read -r A_PAYER A_WANT_MINT < <(python3 - "$SET" "$W" <<'PY'
import json, sys
d = json.load(open(sys.argv[1])); W = sys.argv[2]
assert d.get("kind") == "confide-swap-settle", "not a half-signed settle"
json.dump(d["offerer"]["context"], open(W + "/their-ctx.json", "w"))
open(W + "/half.b64", "w").write(d["transaction"]["half_signed_base64"])
print(d["acceptor"]["payer"], d["acceptor"]["want"]["mint"])
PY
)
[ "$A_PAYER" = "$ME" ] || { echo "  this was accepted by $A_PAYER, not by you" >&2; exit 2; }
KEYS_RECV="$W/$(echo "$A_WANT_MINT" | cut -c1-8)-keys.json"

echo
echo "  ${bold}THE LEG YOU ARE BEING ASKED TO SIGN${off}"
swap_look "$KEYS_RECV" "$W/their-ctx.json"
echo

cargo run --quiet -p confide-ct --bin swap-tx -- sign "$W/half.b64" "$KEY" \
  > "$W/full.b64" 2>"$W/sign2.err"
grep -aE "signatures present" "$W/sign2.err" || true

echo
echo "  ${bold}--- ONE transaction, two confidential transfers, two signatures ---${off}"
go "the swap" "$(cat "$W/full.b64")"
echo
printf '  %sDelivery and payment happened in the same transaction. Neither could occur without the\n' "$grn"
printf '  other, and nothing stood between you. Apply the incoming balance with your own key:%s\n' "$off"
printf '    %sspl-token apply-pending-balance --address <your receiving account>%s\n' "$dim" "$off"
