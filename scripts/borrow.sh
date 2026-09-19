#!/usr/bin/env bash
# Pledge a confidential position you ALREADY hold, as collateral for a loan.
#
#   ./scripts/borrow.sh <your-keypair> <your-account> <your-keys.json> \
#                       <lender-elgamal-pubkey-b64> <lender-token-account> <oracle-pubkey> \
#                       [q_min] [principal_cents] [ratio_bps]
#
# Everything else in this repository creates both sides of a loan. `seizure-e2e.sh` generates the
# borrower AND the lender, mints a mirror token and configures the account from nothing, which
# demonstrates the mechanism and leaves no way for a real holder to use it.
#
# **This is the borrower's half, starting from what a holder already has.** No mint is created, no
# account is configured, and no issuer is asked for anything: the gate on
# `autoApproveNewAccounts: false` is per account and was paid when this account was opened.
# `SetAuthority` moves it to the loan PDA and leaves the approval in place — verified on devnet
# 2026-09-19, see docs/cwf-2026/THE-PINCER.md.
#
# WHAT IT COSTS YOU, before you run it:
#
#   * **You hand over the whole account.** Not part of the balance — the account. Afterwards the
#     loan PDA owns it and you cannot move, close or spend from it. The only ways out are the
#     lender seizing it on a priced default, or the lender signing a release back to you.
#   * **The lender chooses neither.** They cannot redirect the collateral: the seizure route is
#     armed here, now, to the account they nominated, and a seizure citing anything else fails.
#   * **Pledging part of a position needs a second account**, and a second account needs the issuer.
#
# The lender gives you two things first: their **ElGamal public key** (so the collateral can be
# transferred to them confidentially) and their **token account**. Those, plus the terms, are the
# whole negotiation.
set -euo pipefail
cd "$(dirname "$0")/.."
R="${RPC:-https://api.devnet.solana.com}"
. "$(dirname "$0")/lib/chain.sh"
PROGRAM="${PROGRAM:-Gn3rzw8ULVo676ebnxX6qK3YEQP9T8NHtFVetXW8QduN}"
W="${WORK:-$(mktemp -d)}"; mkdir -p "$W"   # a caller-supplied WORK may not exist yet

bold=$'\033[1m'; dim=$'\033[2m'; red=$'\033[31m'; grn=$'\033[32m'; off=$'\033[0m'
die() { printf '  %s✗%s %s\n' "$red" "$off" "$1" >&2; exit 1; }

[ $# -ge 6 ] || { sed -n '3,6p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }
KP="$1"; ACC="$2"; KEYS="$3"; LENDER_PK="$4"; DEST="$5"; ORACLE="$6"
Q_MIN="${7:-100000}"; PRINCIPAL="${8:-5000000}"; RATIO_BPS="${9:-20000}"

[ -f "$KP" ]   || die "no keypair at $KP"
[ -f "$KEYS" ] || die "no keys file at $KEYS — that is the ElGamal secret this account was configured with"

echo
echo "  ${bold}WHAT YOU ARE ABOUT TO DO${off}"
echo "    hand over  $ACC"
echo "    to         a loan PDA derived from it, owned by $PROGRAM"
echo "    in return  a loan of \$$((PRINCIPAL/100)) at $((RATIO_BPS/100))% collateralisation"
echo "    proving    at least $Q_MIN units are in it, without revealing how many"
echo "    seizable   by $ORACLE signing a price that puts it in default"
echo "    landing at $DEST"
echo
printf '    %sThis is one way. After the handover you cannot move or close that account.%s\n' "$dim" "$off"
echo

# ── what the account actually is, before anything is signed ──────────────────────────────────────
read -r DEC AVAIL PUB OWNER < <(ct "$ACC") || die "$ACC is not a confidential token account on $R"
MINT=$(rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getAccountInfo\",\"params\":[\"$ACC\",{\"encoding\":\"jsonParsed\"}]}" \
  | python3 -c "import sys,json;print(json.load(sys.stdin)['result']['value']['data']['parsed']['info']['mint'])")
APPROVED=$(rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getAccountInfo\",\"params\":[\"$ACC\",{\"encoding\":\"jsonParsed\"}]}" \
  | python3 -c "
import sys,json
i=json.load(sys.stdin)['result']['value']['data']['parsed']['info']
s=next(e['state'] for e in i['extensions'] if e['extension']=='confidentialTransferAccount')
print('yes' if s.get('approved') else 'no')")
# An associated token account carries ImmutableOwner, and SetAuthority on one fails with
# TokenError::ImmutableOwner (0x22). Checked HERE, before ten proof transactions are paid for, and
# not discovered at the handover. This is the common case: wallets create ATAs.
IMMUTABLE=$(rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getAccountInfo\",\"params\":[\"$ACC\",{\"encoding\":\"jsonParsed\"}]}" \
  | python3 -c "
import sys,json
i=json.load(sys.stdin)['result']['value']['data']['parsed']['info']
print('yes' if any(e['extension']=='immutableOwner' for e in i.get('extensions',[])) else 'no')")
MINE=$(solana-keygen pubkey "$KP")

echo "  ${bold}THE ACCOUNT${off}"
echo "    mint           $MINT"
echo "    owner          $OWNER"
echo "    approved       $APPROVED   ${dim}(the issuer gate, already paid when this was opened)${off}"
echo "    public balance $PUB   ${dim}(what anyone reading the chain sees)${off}"
echo "    immutableOwner $IMMUTABLE   ${dim}(an associated token account has this, and cannot be handed over)${off}"
[ "$APPROVED" = yes ] || die "this account is not approved for confidential transfers — the issuer has to approve it, and that is the one thing nobody here can do for you"
[ "$OWNER" = "$MINE" ] || die "$MINE does not own this account; $OWNER does"
if [ "$IMMUTABLE" = yes ]; then
  printf '  %s✗%s this account cannot be pledged, and it is not a mistake you made
' "$red" "$off" >&2
  cat >&2 <<'WHY'

      It carries the ImmutableOwner extension, which every associated token account has. That
      extension exists to stop an ATA changing hands, and the handover is exactly that, so
      SetAuthority on it fails with TokenError::ImmutableOwner. A wallet creating a token account
      for you creates an ATA, so this is the ordinary case rather than an unlucky one.

      What it would take: the position has to sit in a token account created with its own keypair.
      Opening one on a mint with autoApproveNewAccounts false means asking the issuer to approve
      it — which is the gate in docs/cwf-2026/THE-PINCER.md, and it is the whole of what this
      script was meant to avoid.

WHY
  exit 1
fi

DECIMALS=$(rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getAccountInfo\",\"params\":[\"$MINT\",{\"encoding\":\"jsonParsed\"}]}" \
  | python3 -c "import sys,json;print(json.load(sys.stdin)['result']['value']['data']['parsed']['info']['decimals'])")
FLOOR_BASE=$(python3 -c "print($Q_MIN * 10**$DECIMALS)")
LOAN=$(cargo run --quiet -p confide-ct --bin seizure-client -- pda "$PROGRAM" "$ACC" 2>/dev/null)
echo "    loan will be   $LOAN"
echo

# ── the proofs, while you still want the loan ────────────────────────────────────────────────────
# Built before the handover on purpose: afterwards you no longer own the account, and these are the
# only reason a seizure can happen later without you.
echo "  ${bold}THE PROOFS${off} ${dim}— built now, because after the handover you are not a party to anything${off}"
AUDITOR_PK=$(rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getAccountInfo\",\"params\":[\"$MINT\",{\"encoding\":\"jsonParsed\"}]}" \
  | python3 -c "
import sys,json
i=json.load(sys.stdin)['result']['value']['data']['parsed']['info']
e=[x for x in i.get('extensions',[]) if x['extension']=='confidentialTransferMint']
k=e[0]['state'].get('auditorElgamalPubkey') if e else None
print(k or 'none')")
ctx() { cargo run --quiet -p confide-ct --bin seizure-ctx -- "$KP" "$KEYS" \
  "$DEC" "$AVAIL" "$LENDER_PK" "$AUDITOR_PK" all "$(bh)" "$W/ctx.json" "$LOAN" "$W/keys" "$1" \
  "$FLOOR_BASE"; }
ctx none >/dev/null 2>"$W/pass1.err" || { cat "$W/pass1.err" >&2; die "could not build the proofs"; }
RANGE=$(python3 -c "import json;print(json.load(open('$W/ctx.json'))['range'])")
ALT=$(solana -u "$R" -k "$KP" address-lookup-table create --authority "$MINE" \
  | grep -oE 'Lookup Table Address: [1-9A-HJ-NP-Za-km-z]{32,44}' | awk '{print $NF}')
solana -u "$R" -k "$KP" address-lookup-table extend "$ALT" --addresses "$RANGE,$LOAN" >/dev/null
sleep 3
ctx "$ALT" > "$W/txs.txt" 2>"$W/pass2.err"
n=0; while read -r TX; do n=$((n+1)); go "proof tx $n" "$TX" >/dev/null || die "a proof transaction failed — see $W/pass2.err"; done < "$W/txs.txt"
echo "    $n transactions confirmed; the proof contexts are under the loan PDA, not under you"
echo

# ── the point of no return ───────────────────────────────────────────────────────────────────────
echo "  ${bold}THE HANDOVER${off} ${dim}— this is the irreversible step${off}"
go "SetAuthority" "$(cargo run --quiet -p confide-ct --bin seizure-client -- handover "$KP" "$ACC" "$LOAN" "$(bh)" 2>/dev/null)" \
  || die "the handover failed; nothing has changed hands"
read -r DEC AVAIL PUB OWNER < <(ct "$ACC")
[ "$OWNER" = "$LOAN" ] || die "the account did not change hands"
echo "    owner is now   $OWNER"
echo

echo "  ${bold}THE LOAN${off}"
cargo run --quiet -p confide-ct --bin seizure-client -- originate "$KP" "$PROGRAM" "$W/ctx.json" \
  "$ACC" "$DEST" "$MINT" "$ORACLE" "$Q_MIN" "$PRINCIPAL" "$RATIO_BPS" "$ORACLE" "$(bh)" \
  > "$W/orig.txt" 2>/dev/null
go "originate" "$(cat "$W/orig.txt")" || die "origination failed — the account is handed over and the loan is not recorded. See docs/DURABILITY.md"
echo

printf '  %severy step is on chain. Send the lender this line and let them check it themselves:%s\n\n' "$grn" "$off"
echo "    ./scripts/lender-check.sh \\"
echo "      $LOAN \\"
echo "      $DEST \\"
echo "      $Q_MIN $PRINCIPAL $RATIO_BPS"
echo
printf '  %sIt calls the program'"'"'s own predicates against the chain. It will not tell them whether\n' "$dim"
printf '  the asset is worth lending against — that is docs/packets/.%s\n\n' "$off"
