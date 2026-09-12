#!/usr/bin/env bash
# The committee as actual processes. A committee inside one process is not a committee.
#
# The holder seals and exits. Five agents run as their own processes and answer on their own.
# Someone who is neither the holder nor an agent opens the result.
set -uo pipefail
cd "$(dirname "$0")/.."
DIR="${1:-$(mktemp -d)/committee}"
DUE=1794614400          # 2026-11-14, the 13F deadline
EARLY=$((DUE - 86400))  # one day short

B() { cargo run --quiet -p mora-committee --bin "$@"; }
rule() { printf '\n  \033[2m────────────────────────────────────────────────────────────────\033[0m\n  \033[1m%s\033[0m\n\n' "$1"; }

rule "30 Sep · the holder seals the position of record, and exits"
B mora-seal "$DIR"

rule "13 Nov · someone asks the committee one day early"
fail=0
for i in 1 2 3 4 5; do
  B mora-agent "$DIR/agent-$i.share" "$DIR/sealed.json" "$EARLY" || fail=$((fail+1))
done
printf '\n  %d of 5 refused. No share exists to collect.\n' "$fail"
B mora-open "$DIR/sealed.json" || true

rule "14 Nov · the obligation comes due"
for i in 2 4 5; do
  B mora-agent "$DIR/agent-$i.share" "$DIR/sealed.json" "$DUE"
done
echo
B mora-open "$DIR/sealed.json" "$DIR"/agent-{2,4,5}.share.published

printf '  \033[2mThe holder has not run since the first block. It was not asked, and could\n  not have been.\033[0m\n\n'
