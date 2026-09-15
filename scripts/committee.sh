#!/usr/bin/env bash
# The committee as actual processes. A committee inside one process is not a committee.
#
# The holder seals and exits. Five agents run as their own processes and answer on their own.
# Someone who is neither the holder nor an agent opens the result.
set -uo pipefail
cd "$(dirname "$0")/.."
DIR="${1:-$(mktemp -d)/committee}"
KEYS="${KEYS:-account-keys.json}"
RPC="${RPC:-https://api.devnet.solana.com}"
DUE=1794614400          # 2026-11-14, the reporting deadline
EARLY=$((DUE - 86400))  # one day short

# Seal the live account's position when its keys are here, a throwaway one when they are not. The
# committee mechanism is the same either way; what changes is whether the sealed figure is about an
# account that exists, and the run prints which.
LIVE=""
if [ -f "$KEYS" ]; then
  ACC=$(python3 -c "import json;print(json.load(open('$KEYS'))['account'])")
  read -r DEC AVAIL < <(curl -s "$RPC" -H 'Content-Type: application/json' \
    -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getAccountInfo\",\"params\":[\"$ACC\",{\"encoding\":\"jsonParsed\",\"commitment\":\"confirmed\"}]}" \
  | python3 -c "
import sys, json
v = json.load(sys.stdin)['result']['value']
if not v: print('- -'); raise SystemExit(0)
i = v['data']['parsed']['info']
ct = next(e['state'] for e in i['extensions'] if e['extension'] == 'confidentialTransferAccount')
print(ct['decryptableAvailableBalance'], ct['availableBalance'])
")
  [ "$DEC" != "-" ] && LIVE="$KEYS $DEC $AVAIL"
fi

B() { cargo run --quiet -p confide-committee --bin "$@"; }
rule() { printf '\n  \033[2m────────────────────────────────────────────────────────────────\033[0m\n  \033[1m%s\033[0m\n\n' "$1"; }

rule "30 Sep · the holder seals the position of record, and exits"
B confide-seal "$DIR" $LIVE

rule "13 Nov · someone asks the committee one day early"
fail=0
for i in 1 2 3 4 5; do
  B confide-agent "$DIR/agent-$i.share" "$DIR/sealed.json" "$EARLY" || fail=$((fail+1))
done
printf '\n  %d of 5 refused. No share exists to collect.\n' "$fail"
B confide-open "$DIR/sealed.json" || true

rule "14 Nov · the obligation comes due"
for i in 2 4 5; do
  B confide-agent "$DIR/agent-$i.share" "$DIR/sealed.json" "$DUE"
done
echo
B confide-open "$DIR/sealed.json" "$DIR"/agent-{2,4,5}.share.published

printf '  \033[2mThe holder has not run since the first block. It was not asked, and could\n  not have been.\033[0m\n\n'
