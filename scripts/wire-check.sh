#!/usr/bin/env bash
# Does the client hand the program the accounts the program asks for?
#
#   ./scripts/wire-check.sh
#
# On 2026-09-16 a repair made `originate` require two proof context accounts and nothing built
# them. The program's 32 tests passed throughout, because they exercise the checking functions and
# never the wire. The e2e would have caught it and does not run in CI; nothing else looked.
#
# This counts, per instruction, the accounts the program reads and the accounts the client sends.
# It is a shape check and not a type check -- it cannot tell you the order is right -- but the
# failure it exists for is a count that silently drifted.
set -euo pipefail
cd "$(dirname "$0")/.."

P=programs/confide-seizure/src/lib.rs
C=crates/confide-ct/src/seizure_client.rs
green=$'\033[32m'; red=$'\033[31m'; dim=$'\033[2m'; off=$'\033[0m'
fail=0

# The program reads its accounts with next_account_info, in one run per instruction handler.
prog() { awk "/fn $1\(/,/^}/" "$P" | grep -c "next_account_info"; }
# The client builds them as an AccountMeta vec inside the arm named for the instruction.
clnt() { awk "/\"$1\" => \{/,/^        \}/" "$C" | grep -c "AccountMeta::"; }

echo
for ix in originate seize; do
  p=$(prog "$ix"); c=$(clnt "$ix")
  if [ "$p" = "$c" ]; then
    printf '  %s✓%s %-10s program reads %s accounts, client sends %s\n' "$green" "$off" "$ix" "$p" "$c"
  else
    printf '  %s✗%s %-10s program reads %s accounts, client sends %s\n' "$red" "$off" "$ix" "$p" "$c"
    printf '      %sone of them changed without the other. This is the bug that shipped on 09-16.%s\n' "$dim" "$off"
    fail=$((fail+1))
  fi
done
echo
[ "$fail" -eq 0 ] || printf '  %s%d instruction(s) out of step%s\n\n' "$red" "$fail" "$off"
exit "$fail"
