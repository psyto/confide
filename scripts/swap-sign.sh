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

read -r A_PAYER A_WANT_MINT A_WANT_ACC O_PAYER O_GIVE_ACC O_GIVE_MINT O_WANT_ACC A_GIVE_ACC A_GIVE_MINT < <(python3 - "$SET" "$W" <<'PY'
import json, sys
d = json.load(open(sys.argv[1])); W = sys.argv[2]
assert d.get("kind") == "confide-swap-settle", "not a half-signed settle"
o, a = d["offerer"], d["acceptor"]
json.dump(o["context"], open(W + "/their-ctx.json", "w"))
open(W + "/half.b64", "w").write(d["transaction"]["half_signed_base64"])
print(a["payer"], a["want"]["mint"], a["want"]["account"],
      o["payer"], o["give"]["account"], o["give"]["mint"],
      o["want"]["account"], a["give"]["account"], a["give"]["mint"])
PY
)
[ "$A_PAYER" = "$ME" ] || { echo "  this was accepted by $A_PAYER, not by you" >&2; exit 2; }
KEYS_RECV="$W/$(echo "$A_WANT_MINT" | cut -c1-8)-keys.json"
[ -f "$W/accept-ctx.json" ] || { echo "  $W/accept-ctx.json is missing — this is not the machine that ran swap-accept.sh" >&2; exit 1; }

echo
echo "  ${bold}THE LEG YOU ARE BEING ASKED TO SIGN${off}"
swap_look "$KEYS_RECV" "$W/their-ctx.json"
echo

# THE BINDING. Without this the step above was theatre: it decrypted an amount out of a context
# named in a file, then signed an opaque blob, with nothing connecting the two. The offerer could
# show a real context and hand over a different transaction. Codex, 2026-09-22.
#
# So rebuild the transaction from what you trust -- YOUR leg, which you built, and the context you
# just decrypted -- and compare the whole message. Anything else refuses.
echo "  ${bold}IS IT THE TRANSACTION YOU JUST CHECKED?${off}"
cargo run --quiet -p confide-ct --bin swap-tx -- verify "$W/half.b64" "$O_PAYER" \
  "$O_PAYER" "$W/their-ctx.json"  "$O_GIVE_ACC" "$A_WANT_ACC" "$O_GIVE_MINT" \
  "$ME"      "$W/accept-ctx.json" "$A_GIVE_ACC" "$O_WANT_ACC" "$A_GIVE_MINT" \
  2>"$W/verify.err" || { cat "$W/verify.err"; echo
      echo "  ${red}Nothing has been signed. Nothing has happened.${off}"; exit 1; }
cat "$W/verify.err"

# And that the blockhash has not expired. A stale one is a failed send rather than a theft, but
# finding out here beats finding out from the cluster.
#
# Taken from `verify`'s own output rather than parsed out of the bytes. The first version walked
# the message by hand and got the offset wrong -- recent_blockhash sits after the account-key
# array, not after the header -- which would have read 32 bytes of a pubkey and called it a
# blockhash. Two parsers of one format is one too many.
BHX=$(grep -aoE 'blockhash [1-9A-HJ-NP-Za-km-z]{32,44}' "$W/verify.err" | awk '{print $2}' | head -1)
if [ -n "$BHX" ]; then
  VALID=$(rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"isBlockhashValid\",\"params\":[\"$BHX\",{\"commitment\":\"confirmed\"}]}" \
          | python3 -c "import sys,json;print(json.load(sys.stdin).get('result',{}).get('value'))" 2>/dev/null)
  [ "$VALID" = "True" ] && echo "  ${dim}blockhash still valid${off}" \
                        || echo "  ${dim}blockhash reports valid=$VALID — the send may fail; ask them to redo step 3${off}"
fi
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
