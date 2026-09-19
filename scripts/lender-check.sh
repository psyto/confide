#!/usr/bin/env bash
# What a lender checks before they lend. Run by the lender, against the chain.
#
#   ./scripts/lender-check.sh <loan> <my-token-account> [q_min] [principal_cents] [ratio_bps]
#
# A wrapper so the answer is not buried under cargo's build output. The work is in
# crates/confide-ct/src/lender_check.rs, which calls confide-seizure's OWN predicates — the same
# functions the chain runs — rather than a second implementation that could disagree with it.
set -euo pipefail
cd "$(dirname "$0")/.."
RPC="${RPC:-https://api.devnet.solana.com}"
PROGRAM="${PROGRAM:-Gn3rzw8ULVo676ebnxX6qK3YEQP9T8NHtFVetXW8QduN}"
[ $# -ge 2 ] || { echo "usage: lender-check.sh <loan> <my-token-account> [q_min] [principal_cents] [ratio_bps]" >&2; exit 2; }
cargo build --quiet -p confide-ct --bin lender-check 2>/dev/null
exec ./target/debug/lender-check "$RPC" "$PROGRAM" "$@"
