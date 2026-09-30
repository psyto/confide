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
W="${WORK:-$(swap_workdir)}"; mkdir -p "$W"; chmod 700 "$W" 2>/dev/null || true
bold=$'\033[1m'; dim=$'\033[2m'; grn=$'\033[32m'; red=$'\033[31m'; off=$'\033[0m'

KEY="${1:?usage: swap-sign.sh <keypair.json> settle.json}"
SET="${2:?usage: swap-sign.sh <keypair.json> settle.json}"
ME=$(solana-keygen pubkey "$KEY")

read -r A_PAYER A_WANT_MINT A_WANT_ACC O_PAYER O_GIVE_ACC O_GIVE_MINT O_WANT_ACC A_GIVE_ACC A_GIVE_MINT A_WANT_UNITS OFFER_ID < <(
python3 scripts/lib/swapjson.py "$SET" confide-swap-settle \
  acceptor.payer acceptor.want.mint acceptor.want.account \
  offerer.payer offerer.give.account offerer.give.mint \
  offerer.want.account acceptor.give.account acceptor.give.mint \
  acceptor.want.units id
) || exit 1

# The two files the old inline block wrote on its way past. Kept explicit: a reader should be able to
# see that the context and the half-signed transaction come out of the file they were handed.
S=$(swap_session "$OFFER_ID" create)
python3 - "$SET" "$S" <<'PY'
import json, sys
d = json.load(open(sys.argv[1])); S = sys.argv[2]
json.dump(d["offerer"]["context"], open(S + "/their-ctx.json", "w"))
open(S + "/half.b64", "w").write(d["transaction"]["half_signed_base64"])
PY
[ "$A_PAYER" = "$ME" ] || { echo "  this was accepted by $A_PAYER, not by you" >&2; exit 2; }
KEYS_RECV="$W/$(echo "$A_WANT_MINT" | cut -c1-8)-keys.json"
[ -f "$S/accept-ctx.json" ] || { echo "  $S/accept-ctx.json is missing — this is not the machine that ran swap-accept.sh" >&2; exit 1; }

echo
echo "  ${bold}THE LEG YOU ARE BEING ASKED TO SIGN${off}"
# This is the irreversible step, so the expectation must not come from the file the offerer handed
# back. It comes from the pin swap-accept.sh wrote on this machine before any proof existed.
# "give" because the acceptor receives what the offerer gives. The canonical terms are the offerer's
# two legs, pinned at accept time from the offer that was inspected; this compares every field of
# them against the settle.json that came back before reading the expected amount out of the pin.
swap_look_pinned "$KEYS_RECV" "$S/their-ctx.json" "$OFFER_ID" "$SET" give
echo

# THE BINDING. Without this the step above was theatre: it decrypted an amount out of a context
# named in a file, then signed an opaque blob, with nothing connecting the two. The offerer could
# show a real context and hand over a different transaction. Codex, 2026-09-22.
#
# So rebuild the transaction from what you trust -- YOUR leg, which you built, and the context you
# just decrypted -- and compare the whole message. Anything else refuses.
echo "  ${bold}IS IT THE TRANSACTION YOU JUST CHECKED?${off}"
cargo run --quiet -p confide-ct --bin swap-tx -- verify "$S/half.b64" "$O_PAYER" \
  "$O_PAYER" "$S/their-ctx.json"  "$O_GIVE_ACC" "$A_WANT_ACC" "$O_GIVE_MINT" \
  "$ME"      "$S/accept-ctx.json" "$A_GIVE_ACC" "$O_WANT_ACC" "$A_GIVE_MINT" \
  2>"$S/verify.err" || { cat "$S/verify.err"; echo
      echo "  ${red}Nothing has been signed. Nothing has happened.${off}"; exit 1; }
cat "$S/verify.err"

# And that the blockhash has not expired. A stale one is a failed send rather than a theft, but
# finding out here beats finding out from the cluster.
#
# Taken from `verify`'s own output rather than parsed out of the bytes. The first version walked
# the message by hand and got the offset wrong -- recent_blockhash sits after the account-key
# array, not after the header -- which would have read 32 bytes of a pubkey and called it a
# blockhash. Two parsers of one format is one too many.
BHX=$(grep -aoE 'blockhash [1-9A-HJ-NP-Za-km-z]{32,44}' "$S/verify.err" | awk '{print $2}' | head -1)
if [ -n "$BHX" ]; then
  VALID=$(rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"isBlockhashValid\",\"params\":[\"$BHX\",{\"commitment\":\"confirmed\"}]}" \
          | python3 -c "import sys,json;print(json.load(sys.stdin).get('result',{}).get('value'))" 2>/dev/null)
  [ "$VALID" = "True" ] && echo "  ${dim}blockhash still valid${off}" \
                        || echo "  ${dim}blockhash reports valid=$VALID — the send may fail; ask them to redo step 3${off}"
fi
echo

# For the demo app (inert without CONFIDE_EVENTS): the amount check and the transaction binding have
# both passed by here, and nothing of ours is signed yet.
ev checked source=pre_sign_check who=acceptor act=2 bound=yes \
   against="$([ "${CONFIDE_UNPINNED:-}" = 1 ] && echo their-file || echo pin)"
cargo run --quiet -p confide-ct --bin swap-tx -- sign "$S/half.b64" "$KEY" \
  > "$S/full.b64" 2>"$S/sign2.err"
grep -aE "signatures present" "$S/sign2.err" || true

echo
echo "  ${bold}--- ONE transaction, two confidential transfers, two signatures ---${off}"
go "the swap" "$(cat "$S/full.b64")"
# For the demo app only (inert without CONFIDE_EVENTS): written after `go` confirmed, or never.
ev settled act=2 sig="$GO_SIG"
echo
printf '  %sDelivery and payment happened in the same transaction. Neither could occur without the\n' "$grn"
printf '  other, and nothing stood between you. Apply the incoming balance with your own key:%s\n' "$off"
printf '    %sspl-token apply-pending-balance --address <your receiving account>%s\n' "$dim" "$off"
