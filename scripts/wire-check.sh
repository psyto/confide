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

# The discriminator each side uses. The account count is one way to be out of step; sending the
# wrong leading byte is another, and it was not checked at all — a release that sent a 3 would be
# dispatched as arm_release and quietly rewrite the record instead of moving the collateral.
prog_disc() { grep -oE "^\s+([0-9]+) => $1\(" "$P" | grep -oE "[0-9]+" | head -1; }
clnt_disc() { awk "/\"$1\" => \{/,/^        \}/" "$C" | grep -oE "vec!\[[0-9]+u8" | grep -oE "[0-9]+" | head -1; }

echo
# Program handler, then the client arm that builds it. They are spelled differently on purpose:
# Rust functions use underscores and the CLI subcommands use hyphens.
for pair in originate:originate seize:seize arm_release:arm-release release:release apply_pending:apply-pending originate_attested:originate-attested; do
  ix="${pair%%:*}"; arm="${pair##*:}"
  p=$(prog "$ix"); c=$(clnt "$arm")
  pd=$(prog_disc "$ix"); cd=$(clnt_disc "$arm")
  if [ "$p" = "$c" ] && [ "$pd" = "$cd" ] && [ -n "$pd" ]; then
    printf '  %s✓%s %-12s disc %s · program reads %s accounts, client sends %s\n' \
           "$green" "$off" "$ix" "$pd" "$p" "$c"
  else
    printf '  %s✗%s %-12s disc %s/%s · program reads %s accounts, client sends %s\n' \
           "$red" "$off" "$ix" "${pd:-?}" "${cd:-?}" "$p" "$c"
    printf '      %sone of them changed without the other. This is the bug that shipped on 09-16.%s\n' "$dim" "$off"
    fail=$((fail+1))
  fi
done
echo
[ "$fail" -eq 0 ] || printf '  %s%d instruction(s) out of step%s\n\n' "$red" "$fail" "$off"
exit "$fail"
