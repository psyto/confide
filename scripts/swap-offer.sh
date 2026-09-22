#!/usr/bin/env bash
# STEP 1 of 4 — you offer a confidential trade to somebody you have already agreed a price with.
#
#   ./scripts/swap-offer.sh <your-keypair.json> \
#       --give <mint> <units> --want <mint> <units> > offer.json
#
# Hand `offer.json` to your counterparty however you like. It contains no secret: your two account
# addresses, the ElGamal PUBLIC key on the account that will receive, and the two amounts. The key
# is the only thing they need from you, and it is what lets them encrypt an amount that YOU can
# read and nobody else can.
#
# WHAT THIS IS NOT. It is not matching. This assumes you already know who you are trading with and
# at what price -- finding them is deliberately not built, because bringing multiple buyers and
# sellers together by non-discretionary methods is the exchange definition at Rule 3b-16
# (docs/SEC-EXEMPTION.md). This settles a trade two people have made.
#
# You need an account on BOTH mints, each already through the issuer's gate. On the standing devnet
# testbed that is `./scripts/testbed-join.sh`; on a real mint it is a conversation nobody has had.
set -euo pipefail
cd "$(dirname "$0")/.."
. "$(dirname "$0")/lib/chain.sh"
. "$(dirname "$0")/lib/swap.sh"
R="${RPC:-https://api.devnet.solana.com}"
W="${WORK:-$(swap_workdir)}"; mkdir -p "$W"; chmod 700 "$W" 2>/dev/null || true

KEY="${1:?usage: swap-offer.sh <keypair.json> --give <mint> <units> --want <mint> <units>}"; shift
GIVE_MINT= GIVE_UNITS= WANT_MINT= WANT_UNITS=
while [ $# -gt 0 ]; do
  case "$1" in
    --give) GIVE_MINT="$2"; GIVE_UNITS="$3"; shift 3 ;;
    --want) WANT_MINT="$2"; WANT_UNITS="$3"; shift 3 ;;
    *) echo "  unknown argument: $1" >&2; exit 2 ;;
  esac
done
[ -n "$GIVE_MINT" ] && [ -n "$WANT_MINT" ] || { echo "  --give and --want are both required" >&2; exit 2; }

ME=$(solana-keygen pubkey "$KEY")
ata_of() { spl-token -u "$R" address --token "$1" --owner "$2" --verbose 2>/dev/null \
           | grep -oE 'Associated token address: [1-9A-HJ-NP-Za-km-z]{32,44}' | awk '{print $NF}'; }
GIVE_ACC=$(ata_of "$GIVE_MINT" "$ME")
WANT_ACC=$(ata_of "$WANT_MINT" "$ME")

# The receiving account must already be configured for confidential transfers, because its ElGamal
# key is what the counterparty encrypts to. An unconfigured account cannot be the far end of a
# confidential transfer at all, and finding that out after they have built five proofs is worse
# than finding it out now.
for pair in "$GIVE_ACC:giving" "$WANT_ACC:receiving"; do
  acc="${pair%%:*}"; role="${pair##*:}"
  ok=$(rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getAccountInfo\",\"params\":[\"$acc\",{\"encoding\":\"jsonParsed\",\"commitment\":\"confirmed\"}]}" \
       | python3 -c "
import sys,json
v=json.load(sys.stdin).get('result',{}).get('value')
if not v: print('missing'); raise SystemExit
e={x['extension'] for x in v['data']['parsed']['info'].get('extensions',[])}
print('ok' if 'confidentialTransferAccount' in e else 'not-configured')")
  case "$ok" in
    ok) ;;
    missing) echo "  your $role account $acc does not exist — ./scripts/testbed-join.sh" >&2; exit 1 ;;
    *) echo "  your $role account $acc is not configured for confidential transfers." >&2
       echo "  It cannot be one end of a confidential swap. ./scripts/testbed-join.sh" >&2; exit 1 ;;
  esac
done

# The key file holding the ElGamal keypair for the RECEIVING account. testbed-join.sh writes one per
# mint; without it you could receive but never read what you received.
KEYS="$W/$(echo "$WANT_MINT" | cut -c1-8)-keys.json"
[ -f "$KEYS" ] || { echo "  no ElGamal key file for $WANT_MINT at $KEYS." >&2
                    echo "  It is written by ./scripts/testbed-join.sh and is how you read what arrives." >&2
                    exit 1; }

python3 - "$ME" "$GIVE_MINT" "$GIVE_ACC" "$GIVE_UNITS" "$WANT_MINT" "$WANT_ACC" "$WANT_UNITS" \
            "$(swap_elgamal "$KEYS")" "$R" <<'PY'
import json, sys, time
me, gm, ga, gu, wm, wa, wu, elg, rpc = sys.argv[1:10]
print(json.dumps({
    "kind": "confide-swap-offer", "version": 1,
    "generated_utc": time.strftime("%Y-%m-%d %H:%M:%S UTC", time.gmtime()),
    "rpc_hint": "devnet" if "devnet" in rpc else "unknown",
    "note": "No secret is in this file. The ElGamal key is public and is what lets your "
            "counterparty encrypt an amount only you can read.",
    "offerer": {
        "payer": me,
        "give": {"mint": gm, "account": ga, "units": gu},
        "want": {"mint": wm, "account": wa, "units": wu, "elgamal_pubkey_b64": elg},
    },
}, indent=1))
PY
echo "  offer written — hand it to your counterparty, then wait for their accept.json" >&2
echo "  they run: ./scripts/swap-accept.sh <their-keypair.json> offer.json > accept.json" >&2
