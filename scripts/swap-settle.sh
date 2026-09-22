#!/usr/bin/env bash
# STEP 3 of 4 — you build your leg, CHECK what they will actually send you, and sign.
#
#   ./scripts/swap-settle.sh <your-keypair.json> accept.json > settle.json
#
# The check is the point of this whole repository. Their amount is encrypted to YOUR receiving key
# as well as their own, so you decrypt it straight out of the proof context the chain has already
# verified -- without their cooperation, and without revealing it to anyone else.
#
# **If the number it prints is not the number you agreed, stop.** Nothing has happened. A proof is
# not a transfer, and an unsigned transaction is not a transfer either.
set -euo pipefail
cd "$(dirname "$0")/.."
. "$(dirname "$0")/lib/chain.sh"
. "$(dirname "$0")/lib/swap.sh"
R="${RPC:-https://api.devnet.solana.com}"
W="${WORK:-$HOME/.config/confide/swap}"; mkdir -p "$W"
bold=$'\033[1m'; dim=$'\033[2m'; red=$'\033[31m'; off=$'\033[0m'

KEY="${1:?usage: swap-settle.sh <keypair.json> accept.json}"
ACC="${2:?usage: swap-settle.sh <keypair.json> accept.json}"
ME=$(solana-keygen pubkey "$KEY")

read -r O_PAYER O_GIVE_MINT O_GIVE_ACC O_GIVE_UNITS O_WANT_MINT O_WANT_ACC A_PAYER A_GIVE_ACC A_WANT_ACC A_ELG < <(
python3 - "$ACC" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
assert d.get("kind") == "confide-swap-accept", "not an accepted offer"
o, a = d["offerer"], d["acceptor"]
print(o["payer"], o["give"]["mint"], o["give"]["account"], o["give"]["units"],
      o["want"]["mint"], o["want"]["account"],
      a["payer"], a["give"]["account"], a["want"]["account"],
      a["want"]["elgamal_pubkey_b64"])
PY
)
[ "$O_PAYER" = "$ME" ] || { echo "  this offer was made by $O_PAYER, not by you" >&2; exit 2; }
python3 -c "
import json;d=json.load(open('$ACC'));json.dump(d['acceptor']['context'],open('$W/their-ctx.json','w'))"

DEC=$(rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getAccountInfo\",\"params\":[\"$O_GIVE_MINT\",{\"encoding\":\"jsonParsed\"}]}" \
      | python3 -c "import sys,json;print(json.load(sys.stdin)['result']['value']['data']['parsed']['info']['decimals'])")
KEYS_SEND="$W/$(echo "$O_GIVE_MINT" | cut -c1-8)-keys.json"
KEYS_RECV="$W/$(echo "$O_WANT_MINT" | cut -c1-8)-keys.json"

echo "  building your leg — several transactions, a few minutes, nothing moves" >&2
swap_leg settle "$KEY" "$KEYS_SEND" "$O_GIVE_MINT" "$O_GIVE_ACC" "$A_WANT_ACC" \
         "$A_ELG" "$O_GIVE_UNITS" "$DEC" "$W/settle-ctx.json" >&2

{
  echo
  echo "  ${bold}THE LEG YOU ARE BEING ASKED TO SIGN${off}"
  swap_look "$KEYS_RECV" "$W/their-ctx.json"
} >&2

BH=$(bh)
cargo run --quiet -p confide-ct --bin swap-tx -- build "$ME" "$BH" \
  "$ME"      "$W/settle-ctx.json" "$O_GIVE_ACC"  "$A_WANT_ACC" "$O_GIVE_MINT" \
  "$A_PAYER" "$W/their-ctx.json"  "$A_GIVE_ACC"  "$O_WANT_ACC" "$O_WANT_MINT" \
  > "$W/unsigned.b64" 2>"$W/build.err"
grep -a "one transaction" "$W/build.err" >&2 || true
cargo run --quiet -p confide-ct --bin swap-tx -- sign "$W/unsigned.b64" "$KEY" \
  > "$W/half.b64" 2>"$W/sign.err"
grep -aE "signatures present" "$W/sign.err" >&2 || true

python3 - "$ACC" "$W/settle-ctx.json" "$W/half.b64" "$BH" <<'PY'
import json, sys, time
acc, ctxf, txf, bh = sys.argv[1:5]
d = json.load(open(acc))
d["kind"] = "confide-swap-settle"
d["settled_utc"] = time.strftime("%Y-%m-%d %H:%M:%S UTC", time.gmtime())
d["offerer"]["context"] = json.load(open(ctxf))
d["transaction"] = {
    "blockhash": bh,
    "half_signed_base64": open(txf).read().strip(),
    "note": "One signature of two. It cannot execute until the acceptor adds theirs, and they "
            "should decrypt the offerer's amount out of the context above before they do.",
}
print(json.dumps(d, indent=1))
PY
echo >&2
echo "  half-signed — hand settle.json back. It CANNOT execute with one signature." >&2
echo "  they run: ./scripts/swap-sign.sh <their-keypair.json> settle.json" >&2
