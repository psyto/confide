#!/usr/bin/env bash
# Can a Kamino reserve take confidential Token-2022 collateral, without a Kamino-side change?
#
#   ./scripts/kamino-verdict.sh
#
# The answer is not an opinion. Kamino Lend is open source, and it names the confidential-transfer
# extensions explicitly. This reads the six lines that decide it, out of the pinned release, and
# fails loudly if any of them has moved — because then the verdict has moved too.
#
# Nothing here is built or run. It clones one repository and reads it.
set -euo pipefail
cd "$(dirname "$0")/.."

REPO="https://github.com/Kamino-Finance/klend.git"
PIN="a08760976f51a3a58c4a0c6ea27b4a0e565bca79"   # release/v1.25.0, 2026-08-18
SRC="${KLEND_DIR:-${TMPDIR:-/tmp}/klend-$PIN}"
C="$SRC/programs/klend/src/utils/constraints.rs"
K="$SRC/programs/klend/src/lending_market/lending_checks.rs"

bold=$'\033[1m'; green=$'\033[32m'; red=$'\033[31m'; dim=$'\033[2m'; off=$'\033[0m'
fail=0

if [ ! -d "$SRC/.git" ]; then
  echo "  cloning Kamino Lend at $PIN"
  git clone -q "$REPO" "$SRC"
  git -C "$SRC" checkout -q "$PIN"
else
  git -C "$SRC" checkout -q "$PIN"
fi
echo "  klend $(git -C "$SRC" log -1 --format='%h %ad' --date=short)  $(git -C "$SRC" describe --tags 2>/dev/null || echo release/v1.25.0)"
echo

# expect <file> <line> <fragment> <what it means>
expect() {
  local f="$1" n="$2" frag="$3" what="$4" got
  got="$(sed -n "${n}p" "$f")"
  if [[ "$got" == *"$frag"* ]]; then
    printf '  %s✓%s %s\n' "$green" "$off" "$what"
    printf '      %s%s:%s  %s%s\n' "$dim" "${f#$SRC/}" "$n" "$(echo "$got" | sed 's/^ *//')" "$off"
  else
    printf '  %s✗%s %s\n' "$red" "$off" "$what"
    printf '      %s%s:%s no longer reads %s — got: %s%s\n' "$dim" "${f#$SRC/}" "$n" "$frag" "$(echo "$got" | sed 's/^ *//')" "$off"
    fail=$((fail+1))
  fi
}

echo "${bold}KAMINO KNOWS ABOUT CONFIDENTIAL TRANSFERS${off} — they are on the allow-lists, not absent"
expect "$C" 44  "ExtensionType::ConfidentialTransferMint,"    "the mint extension is a supported liquidity-mint extension"
expect "$C" 61  "ExtensionType::ConfidentialTransferAccount," "the account extension is a supported liquidity-account extension"
echo

echo "${bold}AND REQUIRES THEM TO BE INERT${off} — allowed to exist, not allowed to do anything"
expect "$C" 131 "auto_approve_new_accounts"     "a mint that auto-approves confidential accounts is refused"
expect "$C" 187 "allow_confidential_credits"    "a token account that can receive confidential credits is refused"
expect "$C" 194 "allow_non_confidential_credits" "a token account that cannot receive public credits is refused"
expect "$C" 201 "closable().is_err()"           "a token account holding any confidential balance is refused"
echo

echo "${bold}ON THE DEPOSITOR'S OWN ACCOUNT${off} — which is the whole finding"
expect "$K" 186 "check_only_supported_liquidity_token_extensions" "deposit checks the account the tokens come FROM"
expect "$K" 188 "user_source_liquidity" "  …and that account is the user's, not the vault"
echo
echo "${bold}AND NOT ELSEWHERE, WHICH IS WORTH KNOWING${off} — these check a different account"
expect "$K" 61  "borrow_reserve_liquidity_mint" "borrow checks the account receiving the BORROWED asset"
expect "$K" 256 "repay_reserve_liquidity_mint" "liquidation checks the LIQUIDATOR's repay source"
expect "$K" 261 "withdraw_reserve_liquidity_mint" "liquidation checks the LIQUIDATOR's destination"
printf '      %sso "cannot borrow against it" and "cannot be liquidated out of it" follow from the\n' "$dim"
printf '      deposit refusal, not from these. flash_repay_reserve_liquidity_checks omits the\n'
printf '      check entirely. "Every path is checked" is not true and is not claimed.%s\n' "$off"
echo

echo "${bold}THE ASSET, AGAINST THOSE CONDITIONS${off} — read live from mainnet, not from a table here"
RPC="${RPC:-https://api.mainnet-beta.solana.com}"
for PAIR in "Backed SPCXx Xs3oZwbHvqis4NYcf4YKWmEia2eC84wSiVrcYcTqpH8" \
            "Backpack SPCX.US SPCXxcqXj6e5dJDVNovHN8744zkbhM2bYudU45BimGb"; do
  set -- $PAIR; ISSUER=$1; SYM=$2; MINT=$3
  OUT="$(curl -s "$RPC" -H 'Content-Type: application/json' \
    -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getAccountInfo\",\"params\":[\"$MINT\",{\"encoding\":\"jsonParsed\"}]}" \
    | ISSUER="$ISSUER" SYM="$SYM" MINT="$MINT" python3 -c '
import sys, json, os
sys.path.insert(0, "scripts/lib")
import klend_rules as K              # the rules live in one place; the lines above check they still match
v = json.load(sys.stdin).get("result", {}).get("value")
sym, issuer, mint = os.environ["SYM"], os.environ["ISSUER"], os.environ["MINT"]
if not v:
    print("BAD|%s|%s|%s|the mint account does not exist" % (issuer, sym, mint)); raise SystemExit
ok, why, _ = K.evaluate_mint(v["data"]["parsed"]["info"])
print("%s|%s|%s|%s|%s" % ("OK" if ok else "BAD", issuer, sym, mint,
                          "; ".join(why) or "every mint-level condition met"))
')"
  STATUS="${OUT%%|*}"; REST="${OUT#*|}"
  I="${REST%%|*}"; REST="${REST#*|}"; S="${REST%%|*}"; REST="${REST#*|}"
  M="${REST%%|*}"; WHY="${REST#*|}"
  if [ "$STATUS" = "OK" ]; then
    printf '  %s✓%s %s %s — %s\n' "$green" "$off" "$I" "$S" "$WHY"
  else
    printf '  %s✗%s %s %s — %s\n' "$red" "$off" "$I" "$S" "$WHY"; fail=$((fail+1))
  fi
  printf '      %s%s%s\n' "$dim" "$M" "$off"
done
echo

if [ "$fail" -eq 0 ]; then
  cat <<'VERDICT'
  REQUIRES INTEGRATION

  Not "Kamino rejects Token-2022" — it supports it. Not "Kamino has not considered
  confidential transfers" — it names them on both allow-lists. Kamino permits the
  extension to exist on the mint and requires it to be switched off on every account
  it touches: no confidential credits, public credits mandatory, and a confidential
  balance of exactly zero.

  So collateral must be public by the time it reaches Kamino. The ordinary deposit
  path refuses an account carrying confidential value, and collateral that cannot
  get in cannot be borrowed against or liquidated either — as a consequence of the
  deposit refusal, not because those paths check the holder's collateral account.
  They do not; see the lines above.

  Both SpaceX mints pass every mint-level condition today. Kamino could open a
  reserve for either one now, and the reason it cannot take a confidential position
  in them is neither the asset nor Token-2022 support. It is the account-level rule,
  and nothing else.

  What is missing is not one thing. A reserve would need to value a balance it cannot
  read -- a proved floor, re-proved on some schedule -- and recover the collateral at
  default without the holder's cooperation, inside its own liquidation path. And the
  issuer has to approve each confidential escrow, because these mints set
  autoApproveNewAccounts to false. That last one is not Kamino's decision at all.
VERDICT
else
  printf '  %sthe pinned lines have moved in %d place(s) — re-read the source before trusting the verdict%s\n' "$red" "$fail" "$off"
fi
exit "$fail"
