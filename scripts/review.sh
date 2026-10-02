#!/usr/bin/env bash
# The whole flow, end to end, in one command — and then checked by something that was not in it.
#
#   RPC=<devnet endpoint> ./scripts/review.sh
#   RPC=<devnet endpoint> FUNDER=<keypair.json> ./scripts/review.sh
#
# What runs, in order (the founder's brief §2, steps 1–7):
#   0. preflight — the tools, the cluster, the funding, and the build, before anything is spent
#   1. ./scripts/issue-e2e.sh, both acts: a mint gated like the real ones; a holder configures an
#      account; the allocation is REFUSED on chain; the holder cannot approve themselves; the issuer
#      approves exactly that account; a half-signed send is refused; the allocation settles; then two
#      approved holders agree terms off chain, each checks what it will receive, and settle
#   2. the same with SHORT — the issuer under-delivers, and the investor's check refuses to sign
#   3. scripts/observe-run.py re-reads every signature and account each run cites, from the chain,
#      holding no key, and writes a receipt with an explorer link per step
#   4. the SOL handed to the run's throwaway keys goes back to the funder — on success AND on failure
#
# The run's keys and logs are kept in ~/.config/confide/review/<time>/, outside the repository. They
# are devnet keys that hold nothing of value; they are kept so the run can be inspected afterwards.
#
# THE ENDPOINT IS NEVER PRINTED. The public devnet RPC rate-limits hard (429), so a private
# endpoint is strongly advised; output from every step is passed through a filter that replaces
# the endpoint with <rpc> before it reaches the terminal or the log, and the spl-token configs the
# flow writes into the run directory -- which must hold it while the flow runs -- are scrubbed by
# the sweep. Exact-string replacement only: do not run this under `set -x`.
set -uo pipefail
cd "$(dirname "$0")/.."
R="${RPC:-https://api.devnet.solana.com}"
export RPC="$R"
FUNDER="${FUNDER:-$HOME/.config/solana/id.json}"
NEED_SOL="${NEED_SOL:-2.3}"
DEVNET_GENESIS=EtWTRABZaYq6iMfeYKouRu166VU2xqa1wcaWoxPkrZBG
bold=$'\033[1m'; dim=$'\033[2m'; grn=$'\033[32m'; red=$'\033[31m'; off=$'\033[0m'

redact() { python3 -u -c '
import sys, os
u = os.environ.get("RPC", "")
for line in sys.stdin:
    sys.stdout.write(line.replace(u, "<rpc>") if u else line)
    sys.stdout.flush()'; }
die() { printf '\n  %s%s%s\n\n' "$red" "$*" "$off" | redact >&2; exit 1; }
rpc1() { curl -s --max-time 20 "$R" -H 'Content-Type: application/json' \
         -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"$1\",\"params\":${2:-[]}}"; }

echo
echo "  ${bold}=== 0. preflight ===${off}"
for c in solana solana-keygen spl-token cargo python3 curl; do
  command -v "$c" >/dev/null || die "missing: $c — the Solana CLI, a Rust toolchain and python3 are required"
done
printf '    tools                %s\n' "$(solana --version | awk '{print $1, $2}')"
case "$R" in
  *api.devnet.solana.com*)
    printf '    %sendpoint             the public devnet RPC — it rate-limits; a private endpoint is advised%s\n' "$dim" "$off";;
  *) printf '    endpoint             private (not shown)\n';;
esac
G=$(rpc1 getGenesisHash | python3 -c "import sys,json;print(json.load(sys.stdin).get('result',''))" 2>/dev/null)
[ "$G" = "$DEVNET_GENESIS" ] || die "the endpoint is not devnet (or did not answer). This spends real keys only on devnet."
printf '    cluster              devnet\n'
[ -f "$FUNDER" ] || die "no funding keypair at $FUNDER — set FUNDER=<keypair.json> holding about $NEED_SOL devnet SOL"
FUNDER_PUB=$(solana-keygen pubkey "$FUNDER")
lam() { rpc1 getBalance "[\"$1\"]" | python3 -c "import sys,json;print(json.load(sys.stdin)['result']['value'])"; }
HAVE=$(lam "$FUNDER_PUB") || die "could not read the funder's balance"
python3 -c "import sys;sys.exit(0 if $HAVE >= $NEED_SOL*1e9 else 1)" || die "the funder $FUNDER_PUB has $(python3 -c "print($HAVE/1e9)") SOL; a run needs about $NEED_SOL.
  Most of it comes back at the end. Top up at https://faucet.solana.com, or: solana airdrop 1 $FUNDER_PUB -u devnet"
printf '    funder               %s   %s SOL\n' "$FUNDER_PUB" "$(python3 -c "print(round($HAVE/1e9,4))")"
RUN="${REVIEW_DIR:-$HOME/.config/confide/review/$(date -u +%Y%m%dT%H%M%SZ)}"
mkdir -p "$RUN"; chmod 700 "$RUN"
printf '    run directory        %s\n' "$RUN"
# Built here, visibly, rather than inside the first `cargo run --quiet` of the flow, where a
# first-time compile of several minutes looks exactly like a hang.
#
# Warnings are silenced for this run only. Cargo replays a workspace crate's warnings on every
# `cargo run`, so the on-chain seizure program's 23 (unused variables, deprecated curve25519 paths)
# landed in the middle of the flow's output. They are the program's, and the program is not changed
# here: its deployed devnet binary has to keep matching its source. The flags are the same for the
# build and the run, so nothing is compiled twice.
export RUSTFLAGS="${RUSTFLAGS:+$RUSTFLAGS }-A warnings"
printf '    build                '
cargo build --quiet -p confide-ct --bins > "$RUN/build.log" 2>&1 \
  || { tail -20 "$RUN/build.log" | redact >&2; die "the build failed — $RUN/build.log"; }
echo "ok"

# THE SOL GOES BACK. issue-e2e.sh funds each throwaway party from FUNDER and, until this script,
# nothing returned it: every run cost 2.1 SOL whether it worked or not. Swept after each run (so the
# funder never carries both runs at once) and again on any exit.
sweep() {
  local k pub bal before after failed=""
  before=$(lam "$FUNDER_PUB" 2>/dev/null || echo 0)
  # EVERY KEYPAIR IN THE RUN DIRECTORY, not a list of role names: a role added to the flow later is
  # swept without anyone remembering to add it here. A keypair file is a JSON array of 64 bytes.
  while IFS= read -r k; do
    python3 -c "import json,sys;d=json.load(open(sys.argv[1]));sys.exit(0 if isinstance(d,list) and len(d)==64 else 1)" "$k" 2>/dev/null || continue
    pub=$(solana-keygen pubkey "$k" 2>/dev/null) || continue
    [ "$pub" != "$FUNDER_PUB" ] || continue
    # Only wallets. Proof-context and table keypairs are keypairs too, but the accounts belong to
    # the ZK and lookup-table programs and their lamports are rent, not something a transfer can move.
    bal=$(rpc1 getAccountInfo "[\"$pub\",{\"encoding\":\"base64\"}]" | python3 -c "
import sys,json
v=json.load(sys.stdin)['result']['value']
print(v['lamports'] if v and v['owner']=='11111111111111111111111111111111' else 0)" 2>/dev/null) \
      || { failed="$failed $pub"; continue; }
    [ "${bal:-0}" -gt 10000 ] || continue
    solana -u "$R" -k "$k" transfer --allow-unfunded-recipient "$FUNDER_PUB" ALL >/dev/null 2>&1 \
      || failed="$failed $pub"
  done < <(find "$RUN" -name '*.json' -type f)
  after=$(lam "$FUNDER_PUB" 2>/dev/null || echo "$before")
  # What came back is measured at the funder, not added up from what was sent: fees come out of it.
  printf '\n    %sthe funder received back %s SOL%s\n' "$dim" "$(python3 -c "print(round(($after-$before)/1e9,4))")" "$off"
  [ -z "$failed" ] || printf '    %scould not sweep:%s — their keys are in %s%s\n' "$red" "$failed" "$RUN" "$off"
  # Rent in the mints, token accounts, proof contexts and lookup tables is NOT recovered; those
  # accounts are the run's evidence and stay on chain.
  # The spl-token configs issue-e2e.sh writes carry the endpoint in json_rpc_url. Scrubbed once
  # the run that needed them is over, so nothing the run leaves behind holds it.
  find "$RUN" -name '*.yml' -type f -exec python3 -c '
import os, sys
u = os.environ.get("RPC", "")
for f in sys.argv[1:]:
    s = open(f).read()
    if u and u in s:
        open(f + ".tmp", "w").write(s.replace(u, "<rpc>")); os.replace(f + ".tmp", f)' {} +
}
trap sweep EXIT

run_flow() { # run_flow <name> [ENV=VAL ...]
  local name="$1"; shift
  mkdir -p "$RUN/$name"
  : > "$RUN/$name.jsonl"
  env "$@" WORK="$RUN/$name" FUNDER="$FUNDER" CONFIDE_EVENTS="$RUN/$name.jsonl" \
    ./scripts/issue-e2e.sh 2>&1 | redact | tee "$RUN/$name.log"
  return "${PIPESTATUS[0]}"
}

echo
echo "  ${bold}=== 1. the flow: issuance through the gate, then two holders trade ===${off}"
run_flow normal || die "the flow stopped — the log is $RUN/normal.log"
sweep

echo
echo "  ${bold}=== 2. the control: the issuer under-delivers ===${off}"
run_flow short SHORT="${SHORT_UNITS:-2000}" ACT2=0 || die "the short-delivery control stopped — $RUN/short.log"

echo
echo "  ${bold}=== 3. an observer re-reads all of it from the chain ===${off}"
ok=0
python3 scripts/observe-run.py "$RUN/normal.jsonl" --receipt "$RUN/receipt-normal.md" 2>&1 | redact || ok=1
python3 scripts/observe-run.py "$RUN/short.jsonl"  --receipt "$RUN/receipt-short.md"  2>&1 | redact || ok=1

echo
if [ "$ok" = 0 ]; then
  echo "  ${grn}${bold}End to end, and independently re-read: every check held.${off}"
else
  echo "  ${red}${bold}The run finished, but the observer disagreed with it. Read the FAIL rows above.${off}"
fi
echo "    receipts  $RUN/receipt-normal.md"
echo "              $RUN/receipt-short.md"
echo "    ${dim}What stays public: the mints, the accounts, and that each transaction happened."
echo "    What does not: every balance and every amount — each account reads a public balance of 0.${off}"
exit "$ok"
