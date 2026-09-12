#!/usr/bin/env bash
# Check the auditor slot on EVERY xStock mint on Solana, not a sample.
#
#   ./scripts/slot-scan.sh
#
# Takes a couple of minutes and needs no key. The claim "all of them" is worth checking rather than
# inferring from four.
set -euo pipefail
cd "$(dirname "$0")/.."
RPC="${RPC:-https://solana-rpc.publicnode.com}"

python3 - "$RPC" <<'PY'
import json, sys, urllib.request, concurrent.futures as cf
from collections import Counter

rpc = sys.argv[1]
mints = json.load(open('web/mints.json'))

def check(m):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": "getAccountInfo",
                       "params": [m['mint'], {"encoding": "jsonParsed"}]}).encode()
    req = urllib.request.Request(rpc, body,
                                 {"Content-Type": "application/json", "User-Agent": "confide"})
    for _ in range(3):
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
            continue
    return (m['symbol'], 'ERROR')

with cf.ThreadPoolExecutor(max_workers=8) as ex:
    res = list(ex.map(check, mints))

c = Counter(s for _, s in res)
print('  checked  %d xStock mints on Solana' % len(res))
for k, v in c.most_common():
    print('    %-16s %d' % (k, v))
odd = [r for r in res if r[1] != 'EMPTY']
if odd:
    print('\n  not empty:', odd[:12])
    print('  the finding has changed — update the docs before citing it')
    raise SystemExit(1)
print('\n  every one of them has confidential transfers on and no auditor key')
PY
