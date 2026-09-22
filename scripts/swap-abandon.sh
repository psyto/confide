#!/usr/bin/env bash
# THE WAY OUT — reclaim the rent when a swap does not happen.
#
#   ./scripts/swap-abandon.sh <your-keypair.json> [accept-ctx.json]
#
# Whoever accepts a two-party swap pays first. They build their own proofs and put them on chain
# BEFORE either signature exists, because the other side has to be able to read the amount before
# agreeing to it. If the offerer then goes quiet, the trade never happens and that rent is stranded.
#
# Measured on devnet, one leg is three context accounts of 161, 297 and 385 bytes:
#
#     0.008539 SOL per abandoned attempt.
#
# Small, and nobody profits from it — but it was unrecoverable, and worse, the context accounts
# already existed, so a second attempt with the same keys could not create them and simply failed.
# Codex raised both halves, 2026-09-22.
#
# Run this and the rent comes back to you. It is safe to run on a swap that DID settle: Token-2022
# consumes the proofs but does not close the accounts, so the rent is sitting there either way.
set -euo pipefail
cd "$(dirname "$0")/.."
. "$(dirname "$0")/lib/chain.sh"
. "$(dirname "$0")/lib/swap.sh"
R="${RPC:-https://api.devnet.solana.com}"
W="${WORK:-$(swap_workdir)}"
bold=$'\033[1m'; dim=$'\033[2m'; off=$'\033[0m'

KEY="${1:?usage: swap-abandon.sh <keypair.json> [ctx.json]}"
CTX="${2:-$W/accept-ctx.json}"
[ -f "$CTX" ] || { echo "  $CTX is not there — pass the ctx.json of the leg you built" >&2; exit 1; }
ME=$(solana-keygen pubkey "$KEY")

echo
echo "  ${bold}RECLAIMING THE RENT FROM AN UNSETTLED SWAP${off}"
echo "  ${dim}$CTX${off}"

before=$(rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getBalance\",\"params\":[\"$ME\",{\"commitment\":\"confirmed\"}]}" \
  | python3 -c "import sys,json;print(json.load(sys.stdin)['result']['value'])")

TX=$(cargo run --quiet -p confide-ct --bin swap-close -- "$KEY" "$CTX" "$(bh)")
go "the contexts" "$TX"

after=$(rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getBalance\",\"params\":[\"$ME\",{\"commitment\":\"confirmed\"}]}" \
  | python3 -c "import sys,json;print(json.load(sys.stdin)['result']['value'])")

# The recovered figure is printed, not asserted, because the fee for this very transaction comes out
# of the same balance -- so the number is always a little under the rent that was freed. Saying which
# is which beats printing a round number that does not reconcile.
python3 - "$before" "$after" <<'PY'
import sys
b, a = int(sys.argv[1]), int(sys.argv[2])
print("    rent recovered   %.6f SOL   \033[2m(net of this transaction's fee)\033[0m" % ((a - b) / 1e9))
PY
echo
echo "  ${dim}The address lookup table the proofs were sent through still holds its own rent. Closing one"
echo "  takes a deactivate and roughly 500 slots of cooling off, so it is not done here:${off}"
python3 -c "
import json,sys
d=json.load(open('$CTX'))
print('    solana -u \$RPC address-lookup-table deactivate %s' % d['alt']) if d.get('alt') else print('    this leg did not record its table, so that rent stays where it is')
"
