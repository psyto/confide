#!/usr/bin/env bash
# Stand up a STANDING issuer on devnet, so that a stranger can use the mechanism without asking us.
#
#   ./scripts/testbed-up.sh            # create it (once)
#   ./scripts/testbed-up.sh --check    # verify the one that exists
#
# Everything else here creates a throwaway issuer per run: `swap-e2e.sh` mints, configures,
# approves and trades, then the mints are never touched again. That demonstrates the mechanism and
# leaves **no way for anybody else to touch it**, which is the difference between a demo and a
# thing people can use.
#
# What this is for, precisely, because it is easy to read as more than it is:
#
#   * It is **devnet**, and the tokens represent nothing. No security is involved, no license is
#     implicated, and nothing here makes a real xStock pledgeable. The `$0` on mainnet stands.
#   * It is NOT traction. Standing it up is not usage. Usage is somebody else opening an account
#     on it, and that is counted separately.
#   * What it IS: proof that **the issuer gate is an operations decision rather than a protocol
#     problem** — `docs/cwf-2026/STORY.md` §3 argues that, and this runs it. The mints keep
#     `autoApproveNewAccounts: false`, exactly as all 1,992 live mints do, and the issuer simply
#     **operates** the gate instead of leaving it shut.
#
# How it operates the gate without a server: the confidential-transfer authority is a keypair whose
# SECRET IS PUBLISHED IN THIS REPOSITORY, under `keys/`. Anyone can therefore approve their own
# account. It cannot mint — the mint authority is separate and is not published — so the supply is
# still the issuer's. See docs/TESTBED.md.
set -euo pipefail
cd "$(dirname "$0")/.."
R="${RPC:-https://api.devnet.solana.com}"
. "$(dirname "$0")/lib/chain.sh"
FUNDER="${FUNDER:-$HOME/.config/solana/id.json}"
OUT=web/testbed.json
KEYS=keys
# Published on purpose: keys/. Never published: this, which defaults outside the working tree.
PRIVATE="${CONFIDE_PRIVATE_KEYS:-$HOME/.config/confide}"
MINTKEY="$PRIVATE/issuer-mint-authority.json"
bold=$'\033[1m'; dim=$'\033[2m'; grn=$'\033[32m'; red=$'\033[31m'; off=$'\033[0m'
ok()  { printf '  %s✓%s %s\n' "$grn" "$off" "$1"; }
bad() { printf '  %s✗%s %s\n' "$red" "$off" "$1"; FAIL=$((FAIL+1)); }
FAIL=0

# ── --check: the gate is the whole claim, so watch it ────────────────────────────────────────────
if [ "${1:-}" = "--check" ]; then
  [ -f "$OUT" ] || { echo "  $OUT is missing — the testbed has not been stood up"; exit 1; }
  echo
  echo "  ${bold}THE STANDING TESTBED${off} ${dim}— devnet, and the gate is the point${off}"
  for role in equity cash; do
    m=$(python3 -c "import json;print(json.load(open('$OUT'))['mints']['$role']['mint'])")
    read -r AUTO AUD CTAUTH < <(rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getAccountInfo\",\"params\":[\"$m\",{\"encoding\":\"jsonParsed\"}]}" \
      | python3 -c "
import sys,json
v=json.load(sys.stdin)['result']['value']
if not v: print('GONE GONE GONE'); raise SystemExit
e={x['extension']:x.get('state',{}) for x in v['data']['parsed']['info'].get('extensions',[])}
c=e.get('confidentialTransferMint',{})
print(c.get('autoApproveNewAccounts'), c.get('auditorElgamalPubkey') or 'EMPTY', c.get('authority'))")
    printf '    %-7s %s\n' "$role" "$m"
    [ "$AUTO" = False ] && ok "autoApproveNewAccounts is still false — the gate is shut, as on all 1,992" \
                        || bad "autoApproveNewAccounts is $AUTO — somebody opened the gate, and the demonstration is broken"
    want=$(python3 -c "import json;print(json.load(open('$OUT'))['approval_authority'])")
    [ "$CTAUTH" = "$want" ] && ok "the approval authority is the published key" \
                            || bad "the approval authority is $CTAUTH, not the published $want"
    [ "$AUD" = EMPTY ] && ok "the auditor slot is still empty, as on all 1,992" \
                       || bad "an auditor key has appeared: $AUD"
  done
  echo
  [ "$FAIL" -eq 0 ] && printf '  %sthe testbed is as published%s\n\n' "$grn" "$off" \
                    || printf '  %s%d problem(s)%s — see docs/TESTBED.md\n\n' "$red" "$FAIL" "$off"
  exit "$FAIL"
fi

[ -f "$OUT" ] && { echo "  $OUT already exists. Standing up a second testbed would orphan the first."; \
                   echo "  Delete it deliberately if that is what you want."; exit 1; }

mkdir -p "$KEYS" "$PRIVATE"
echo
echo "  ${bold}--- the issuer ---${off}"
# The mint authority is written OUTSIDE the repository, and that is not a precaution — the first
# run of this put it in `keys/` beside the two published ones and it would have been committed.
# A key that must stay secret does not live in a directory whose purpose is publishing keys.
solana-keygen new --no-bip39-passphrase --silent --force -o "$MINTKEY" >/dev/null
# This one IS published. It can approve accounts and it cannot mint.
solana-keygen new --no-bip39-passphrase --silent --force -o "$KEYS/devnet-approval-authority.json" >/dev/null
# And this one holds the supply anyone can help themselves to.
solana-keygen new --no-bip39-passphrase --silent --force -o "$KEYS/devnet-faucet.json" >/dev/null
MINTAUTH=$(solana-keygen pubkey "$MINTKEY")
APPROVAL=$(solana-keygen pubkey "$KEYS/devnet-approval-authority.json")
FAUCET=$(solana-keygen pubkey "$KEYS/devnet-faucet.json")
for k in "$MINTAUTH" "$APPROVAL" "$FAUCET"; do
  solana -u "$R" -k "$FUNDER" transfer --allow-unfunded-recipient "$k" 1 >/dev/null
done
printf 'json_rpc_url: %s\nwebsocket_url: ""\nkeypair_path: %s\ncommitment: confirmed\n' \
  "$R" "$MINTKEY" > "$PRIVATE/issuer.yml"
echo "    mint authority     $MINTAUTH   ${dim}(kept — supply is the issuer's)${off}"
echo "    approval authority $APPROVAL   ${dim}(PUBLISHED — anyone may approve their own account)${off}"
echo "    faucet             $FAUCET"

mk() { # mk <role> <decimals> <auditor set|none> [extra flags…]
  local role="$1" dec="$2" aud="$3"; shift 3
  local mint
  mint=$(spl-token -C "$PRIVATE/issuer.yml" create-token --program-2022 --decimals "$dec" \
    --enable-confidential-transfers auto "$@" 2>&1 \
    | grep -oE 'Address:  *[1-9A-HJ-NP-Za-km-z]{32,44}' | awk '{print $2}')
  go "$role: gate shut, auditor $aud" "$(cargo run --quiet -p confide-ct --bin set-auditor -- \
    "$MINTKEY" "$mint" "$(bh)" "$KEYS/auditor-$role.json" "$aud" 2>/dev/null)"
  # Hand the approval role to the published key. `ApproveAccount` needs the confidential-transfer
  # mint authority and NOT the mint authority, so the two separate cleanly: whoever holds this can
  # let accounts in and can never print a token.
  go "$role: approval authority published" "$(cargo run --quiet -p confide-ct --bin seizure-client -- \
    set-ct-authority "$MINTKEY" "$mint" "$APPROVAL" "$(bh)")"
  eval "MINT_${role}=$mint"
}
echo
echo "  ${bold}--- two mints, configured as the live ones are ---${off}"
# BOTH auditor slots empty, because that is what all 1,992 live mints do. The first run of this
# filled the equity one — copying Confide's own demo mint, which fills it deliberately to show what
# a usable slot is worth, rather than copying the thing being mirrored. `--check` caught it.
mk equity 8 none
mk cash   6 none --enable-permanent-delegate --enable-close --enable-freeze \
                 --transfer-fee-basis-points 0 --transfer-fee-maximum-fee 0
echo "    equity  $MINT_equity   ${dim}(NVDAx's shape: auditor set, gate shut)${off}"
echo "    cash    $MINT_cash   ${dim}(PYUSD's shape: 6 decimals, auditor EMPTY, fee config, delegate, freeze)${off}"

echo
echo "  ${bold}--- the faucet, so nobody has to ask for a balance ---${off}"
for role in equity cash; do
  eval "m=\$MINT_$role"
  spl-token -C "$PRIVATE/issuer.yml" create-account "$m" --owner "$FAUCET" --fee-payer "$MINTKEY" >/dev/null 2>&1 || true
  acct=$(spl-token -C "$PRIVATE/issuer.yml" address --token "$m" --owner "$FAUCET" --verbose 2>&1 \
        | grep -oE 'Associated token address: *[1-9A-HJ-NP-Za-km-z]{32,44}' | awk '{print $NF}')
  spl-token -C "$PRIVATE/issuer.yml" mint "$m" 1000000000 "$acct" >/dev/null
  eval "FAUCET_${role}=$acct"
  echo "    $role  $acct   ${dim}(1,000,000,000 units, owner key published)${off}"
done

python3 - > "$OUT" <<PY
import json, time
print(json.dumps({
 "generated_utc": time.strftime("%Y-%m-%d %H:%M:%S UTC", time.gmtime()),
 "cluster": "devnet",
 "note": "A standing issuer whose gate is shut and operated, so a stranger can use the mechanism "
         "without asking anybody. The tokens represent nothing. Standing this up is not traction; "
         "somebody else opening an account on it would be.",
 "approval_authority": "$APPROVAL",
 "approval_secret": "keys/devnet-approval-authority.json",
 "faucet_secret": "keys/devnet-faucet.json",
 "mints": {
   "equity": {"mint": "$MINT_equity", "decimals": 8, "shape": "NVDAx",
              "faucet_account": "$FAUCET_equity"},
   "cash":   {"mint": "$MINT_cash", "decimals": 6, "shape": "PYUSD",
              "faucet_account": "$FAUCET_cash"},
 },
}, indent=1))
PY
echo
echo "  written to $OUT — now run ./scripts/testbed-up.sh --check"
echo
