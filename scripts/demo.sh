#!/usr/bin/env bash
# The whole thing, in order: the two lanes, then the same proof going to Solana.
set -euo pipefail
cd "$(dirname "$0")/.."
cargo run --quiet -p mora-demo --bin two-lane
printf '\n  \033[1mand the predicate the regulator checked — on devnet, live\033[0m\n\n'
./scripts/devnet-verify.sh | sed 's/^/  /'
