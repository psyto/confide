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
W="${WORK:-$(swap_workdir)}"; mkdir -p "$W"; chmod 700 "$W" 2>/dev/null || true
bold=$'\033[1m'; dim=$'\033[2m'; red=$'\033[31m'; off=$'\033[0m'

KEY="${1:?usage: swap-settle.sh <keypair.json> accept.json}"
ACC="${2:?usage: swap-settle.sh <keypair.json> accept.json}"
ME=$(solana-keygen pubkey "$KEY")

read -r O_PAYER O_GIVE_MINT O_GIVE_ACC O_GIVE_UNITS O_WANT_MINT O_WANT_ACC A_PAYER A_GIVE_ACC A_WANT_ACC A_ELG O_WANT_UNITS OFFER_ID < <(
python3 scripts/lib/swapjson.py "$ACC" confide-swap-accept \
  offerer.payer offerer.give.mint offerer.give.account offerer.give.units \
  offerer.want.mint offerer.want.account \
  acceptor.payer acceptor.give.account acceptor.want.account \
  acceptor.want.elgamal_pubkey_b64 offerer.want.units id
) || exit 1
[ "$O_PAYER" = "$ME" ] || { echo "  this offer was made by $O_PAYER, not by you" >&2; exit 2; }
S=$(swap_session "$OFFER_ID" create)
python3 -c "
import json,sys;d=json.load(open(sys.argv[1]));json.dump(d['acceptor']['context'],open(sys.argv[2],'w'))" \
  "$ACC" "$S/their-ctx.json"

# THE TERMS, BEFORE ANYTHING IS BUILT FROM THEM.
#
# What you GIVE is not a detail of their reply. `O_GIVE_UNITS` above came out of the accept.json the
# acceptor handed back, and the leg below is built from it: an acceptor who changes
# offerer.give.units from 100 to 1,000 while paying exactly the agreed amount gets a correct
# received-leg check and ten times the asset. Checking what arrives is half a trade. Codex,
# 2026-09-30.
#
# So every canonical field is compared against the pin first, and what is given is then read OUT of
# the pin rather than out of their file.
if PIN=$(swap_read_terms "$OFFER_ID"); then
  swap_verify_terms "$OFFER_ID" "$ACC" || { echo "  Nothing has been signed." >&2; exit 1; }
  read -r O_GIVE_UNITS DEC < <(python3 -c "
import json,sys
g=json.load(open(sys.argv[1]))['offerer']['give']
print(g['units'], g['decimals'])" "$PIN")
  echo "  terms match the pin at $PIN — giving $O_GIVE_UNITS, read from your own record" >&2
elif [ "${CONFIDE_UNPINNED:-}" = 1 ]; then
  echo "  ${red}!${off} CONFIDE_UNPINNED=1 — the amount you are about to GIVE ($O_GIVE_UNITS) comes" >&2
  echo "    from the file they handed back, not from a record this machine wrote." >&2
  DEC=$(swap_mint_decimals "$O_GIVE_MINT")
else
  echo "  ${red}✗${off} NO PINNED TERMS for offer id '$OFFER_ID'." >&2
  echo "    Both the amount you would give and the amount you would receive would come from the" >&2
  echo "    file your counterparty handed back. Run step 1 on this machine, or set" >&2
  echo "    CONFIDE_UNPINNED=1 to proceed unprotected. Nothing has been signed." >&2
  exit 1
fi
KEYS_SEND="$W/$(echo "$O_GIVE_MINT" | cut -c1-8)-keys.json"
KEYS_RECV="$W/$(echo "$O_WANT_MINT" | cut -c1-8)-keys.json"

echo "  building your leg — several transactions, a few minutes, nothing moves" >&2
swap_leg settle "$KEY" "$KEYS_SEND" "$O_GIVE_MINT" "$O_GIVE_ACC" "$A_WANT_ACC" \
         "$A_ELG" "$O_GIVE_UNITS" "$DEC" "$S/settle-ctx.json" >&2

{
  echo
  echo "  ${bold}THE LEG YOU ARE BEING ASKED TO SIGN${off}"
  # Against the terms this machine pinned when the offer was made, not against the figure inside the
  # file that came back. `set -e` is on: a short leg, or altered terms, stops here unsigned.
  swap_look_pinned "$KEYS_RECV" "$S/their-ctx.json" "$OFFER_ID" "$ACC" want
} >&2
# For the demo app (inert without CONFIDE_EVENTS). After the check, before anything is signed. Says
# what it was compared against: under CONFIDE_UNPINNED=1 that is the counterparty's file, not a pin.
ev checked source=pre_sign_check who=offerer act=2 \
   against="$([ "${CONFIDE_UNPINNED:-}" = 1 ] && echo their-file || echo pin)"

BH=$(bh)
cargo run --quiet -p confide-ct --bin swap-tx -- build "$ME" "$BH" \
  "$ME"      "$S/settle-ctx.json" "$O_GIVE_ACC"  "$A_WANT_ACC" "$O_GIVE_MINT" \
  "$A_PAYER" "$S/their-ctx.json"  "$A_GIVE_ACC"  "$O_WANT_ACC" "$O_WANT_MINT" \
  > "$S/unsigned.b64" 2>"$S/build.err"
grep -a "one transaction" "$S/build.err" >&2 || true
cargo run --quiet -p confide-ct --bin swap-tx -- sign "$S/unsigned.b64" "$KEY" \
  > "$S/half.b64" 2>"$S/sign.err"
grep -aE "signatures present" "$S/sign.err" >&2 || true

python3 - "$ACC" "$S/settle-ctx.json" "$S/half.b64" "$BH" <<'PY'
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
