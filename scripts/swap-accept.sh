#!/usr/bin/env bash
# STEP 2 of 4 — you accept an offer, and build YOUR leg's proofs.
#
#   ./scripts/swap-accept.sh <your-keypair.json> offer.json > accept.json
#
# You can build now because the offer carries their receiving ElGamal key, and that is the only
# thing you needed from them. They cannot build yet, because they do not have yours -- which is why
# this is a four-message protocol and not a two-message one.
#
# This is the expensive step: three proofs, or five on a mint that charges a transfer fee, verified
# on chain into context accounts you own. It takes several transactions and a few minutes. NOTHING
# has been transferred when it finishes, and nothing can be: the proofs authorise a transfer that
# does not exist until both parties sign one transaction.
#
# Read the offer before running this. The amounts in it are the trade.
set -euo pipefail
cd "$(dirname "$0")/.."
. "$(dirname "$0")/lib/chain.sh"
. "$(dirname "$0")/lib/swap.sh"
R="${RPC:-https://api.devnet.solana.com}"
W="${WORK:-$HOME/.config/confide/swap}"; mkdir -p "$W"

KEY="${1:?usage: swap-accept.sh <keypair.json> offer.json}"
OFFER="${2:?usage: swap-accept.sh <keypair.json> offer.json}"
ME=$(solana-keygen pubkey "$KEY")

read -r O_PAYER O_GIVE_MINT O_GIVE_ACC O_GIVE_UNITS O_WANT_MINT O_WANT_ACC O_WANT_UNITS O_ELG < <(
python3 - "$OFFER" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
assert d.get("kind") == "confide-swap-offer", "not a confide swap offer"
o = d["offerer"]
print(o["payer"], o["give"]["mint"], o["give"]["account"], o["give"]["units"],
      o["want"]["mint"], o["want"]["account"], o["want"]["units"],
      o["want"]["elgamal_pubkey_b64"])
PY
)
[ "$O_PAYER" != "$ME" ] || { echo "  that is your own offer" >&2; exit 2; }

ata_of() { spl-token -u "$R" address --token "$1" --owner "$2" --verbose 2>/dev/null \
           | grep -oE 'Associated token address: [1-9A-HJ-NP-Za-km-z]{32,44}' | awk '{print $NF}'; }
# You give what they want, and receive what they give. Stated the long way because getting it
# backwards builds a proof for the wrong direction and the error arrives five transactions later.
MY_GIVE_MINT="$O_WANT_MINT"; MY_GIVE_ACC=$(ata_of "$MY_GIVE_MINT" "$ME"); MY_GIVE_UNITS="$O_WANT_UNITS"
MY_WANT_MINT="$O_GIVE_MINT"; MY_WANT_ACC=$(ata_of "$MY_WANT_MINT" "$ME"); MY_WANT_UNITS="$O_GIVE_UNITS"

DEC=$(rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getAccountInfo\",\"params\":[\"$MY_GIVE_MINT\",{\"encoding\":\"jsonParsed\"}]}" \
      | python3 -c "import sys,json;print(json.load(sys.stdin)['result']['value']['data']['parsed']['info']['decimals'])")
KEYS_RECV="$W/$(echo "$MY_WANT_MINT" | cut -c1-8)-keys.json"
KEYS_SEND="$W/$(echo "$MY_GIVE_MINT" | cut -c1-8)-keys.json"
for f in "$KEYS_RECV" "$KEYS_SEND"; do
  [ -f "$f" ] || { echo "  missing ElGamal key file $f — ./scripts/testbed-join.sh" >&2; exit 1; }
done

{
  echo "  you give   $MY_GIVE_UNITS of $MY_GIVE_MINT   from $MY_GIVE_ACC"
  echo "  you get    $MY_WANT_UNITS of $MY_WANT_MINT   into $MY_WANT_ACC"
  echo "  building your leg — several transactions, a few minutes, nothing moves"
} >&2

swap_leg accept "$KEY" "$KEYS_SEND" "$MY_GIVE_MINT" "$MY_GIVE_ACC" "$O_WANT_ACC" \
         "$O_ELG" "$MY_GIVE_UNITS" "$DEC" "$W/accept-ctx.json" >&2

python3 - "$OFFER" "$ME" "$MY_GIVE_ACC" "$MY_WANT_ACC" "$(swap_elgamal "$KEYS_RECV")" \
            "$W/accept-ctx.json" <<'PY'
import json, sys, time
offer, me, give_acc, want_acc, elg, ctxf = sys.argv[1:7]
d = json.load(open(offer))
d["kind"] = "confide-swap-accept"
d["accepted_utc"] = time.strftime("%Y-%m-%d %H:%M:%S UTC", time.gmtime())
d["acceptor"] = {
    "payer": me,
    "give": {"mint": d["offerer"]["want"]["mint"], "account": give_acc,
             "units": d["offerer"]["want"]["units"]},
    "want": {"mint": d["offerer"]["give"]["mint"], "account": want_acc,
             "units": d["offerer"]["give"]["units"], "elgamal_pubkey_b64": elg},
    # The context addresses, so the offerer can cite them in the transaction and decrypt the
    # amount out of them before signing. They are on chain and public; what is in them is not.
    "context": json.load(open(ctxf)),
}
print(json.dumps(d, indent=1))
PY
echo "  accept written — hand it back. Nothing has moved." >&2
echo "  they run: ./scripts/swap-settle.sh <their-keypair.json> accept.json > settle.json" >&2
