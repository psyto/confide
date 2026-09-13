#!/usr/bin/env bash
# Check the auditor slot on EVERY tokenized-equity mint on Solana, across both issuers, not a sample.
#
#   Backed Finance (xStocks)  — Swiss-issued, own ISIN
#   Backpack Securities       — US CUSIP, a security entitlement by the issuer's own description
#
# Two independent issuers reaching the same configuration is the finding. One would be a quirk.
#
#   ./scripts/slot-scan.sh
#
# Takes a few minutes and needs no key. "All of them" is worth checking rather than inferring from
# four — this repo has already had to correct that exact shortcut once.
set -euo pipefail
cd "$(dirname "$0")/.."
RPC="${RPC:-https://solana-rpc.publicnode.com}"

python3 - "$RPC" <<'PY'
import json, sys, time, urllib.request, concurrent.futures as cf
from collections import Counter

rpc = sys.argv[1]
mints = json.load(open('web/mints.json'))

def check(m):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": "getAccountInfo",
                       "params": [m['mint'], {"encoding": "jsonParsed"}]}).encode()
    req = urllib.request.Request(rpc, body,
                                 {"Content-Type": "application/json", "User-Agent": "confide"})
    # 1,869 mints is enough volume to get rate-limited; back off rather than reporting a limit as
    # a finding, which is what an unretried error looks like in the output.
    for attempt in range(6):
        try:
            v = json.load(urllib.request.urlopen(req, timeout=30)).get('result', {}).get('value')
            if not v:
                return (m['symbol'], 'NO_ACCOUNT')
            ext = [e for e in v['data']['parsed']['info'].get('extensions', [])
                   if e['extension'] == 'confidentialTransferMint']
            if not ext:
                return (m['symbol'], 'NO_CT_EXTENSION')
            k = ext[0]['state'].get('auditorElgamalPubkey')
            return (m['symbol'], 'EMPTY' if k is None else 'KEY')
        except Exception:
            time.sleep(0.6 * (attempt + 1))
            continue
    return (m['symbol'], 'ERROR')

with cf.ThreadPoolExecutor(max_workers=4) as ex:
    res = list(ex.map(check, mints))

by_issuer = Counter()
for m, (_, st) in zip(mints, res):
    by_issuer[(m.get('issuer', '?'), st)] += 1
print('  checked  %d tokenized-equity mints on Solana' % len(res))
for (issuer, st), v in sorted(by_issuer.items()):
    print('    %-10s %-16s %d' % (issuer, st, v))
odd = [r for r in res if r[1] != 'EMPTY']
if odd:
    print('\n  not empty:', odd[:12])
    print('  the finding has changed — update the docs before citing it')
    raise SystemExit(1)
print('\n  every one of them: confidential transfers on, no auditor key.')
print('  Two issuers, independently, reaching the same dead end.')
PY
