#!/usr/bin/env bash
# Every tokenized-equity mint on Solana, against Kamino's own admissibility rules.
#
#   ./scripts/kamino-admissible.sh
#
# The whole-population scan says how many of these tokens have confidential transfers switched on. That
# is incidence. It is not the number that matters to a lender, which is how many of them a Kamino
# reserve could hold at all — a different question with a different answer, and until now they were
# the same number in this repository.
#
# Rules: scripts/lib/klend_rules.py, transcribed from klend and checked by ./scripts/kamino-verdict.sh.
# Writes web/kamino.json. Takes a few minutes and needs no key.
set -euo pipefail
cd "$(dirname "$0")/.."
RPC="${RPC:-https://solana-rpc.publicnode.com}"

python3 - "$RPC" <<'PY'
import json, sys, time, urllib.request, concurrent.futures as cf
from collections import Counter
sys.path.insert(0, 'scripts/lib')
import klend_rules as K

rpc = sys.argv[1]
mints = json.load(open('web/mints.json'))

def check(m):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": "getAccountInfo",
                       "params": [m['mint'], {"encoding": "jsonParsed"}]}).encode()
    req = urllib.request.Request(rpc, body,
                                 {"Content-Type": "application/json", "User-Agent": "confide"})
    for attempt in range(6):
        try:
            v = json.load(urllib.request.urlopen(req, timeout=30)).get('result', {}).get('value')
            if not v:
                return dict(m, verdict='NO_ACCOUNT', why=['the mint account does not exist'], extensions=[])
            ok, why, exts = K.evaluate_mint(v['data']['parsed']['info'])
            return dict(m, verdict='ADMISSIBLE' if ok else 'INADMISSIBLE', why=why, extensions=exts)
        except Exception:
            time.sleep(0.6 * (attempt + 1))
    return dict(m, verdict='ERROR', why=['the RPC did not answer in six tries'], extensions=[])

with cf.ThreadPoolExecutor(max_workers=4) as ex:
    rows = list(ex.map(check, mints))

errs = [r for r in rows if r['verdict'] == 'ERROR']
if errs:
    print('  %d mints could not be read — a rate limit is not a finding; re-run' % len(errs))
    raise SystemExit(1)

by = Counter((r.get('issuer', '?'), r['verdict']) for r in rows)
adm = [r for r in rows if r['verdict'] == 'ADMISSIBLE']
print('  %d tokenized-equity mints, against klend %s' % (len(rows), K.KLEND_TAG))
for (issuer, verdict), n in sorted(by.items()):
    print('    %-10s %-14s %d' % (issuer, verdict, n))

print()
print('  ADMISSIBLE means MINT-EXTENSION COMPATIBLE: every extension on the mint is on klend\'s')
print('  allow-list and every conditional one passes. That is one gate of several — it says nothing')
print('  about oracle, liquidity, legal eligibility or whether anyone would supply the market.')
print('  It especially does NOT mean a confidential position is usable: the ordinary deposit path')
print('  refuses an account carrying confidential value. See docs/KAMINO.md.')

if len(adm) != len(rows):
    print()
    print('  why the rest are not:')
    for reason, n in Counter(w for r in rows if r['verdict'] != 'ADMISSIBLE' for w in r['why']).most_common():
        print('    %-4d %s' % (n, reason))

json.dump({
    'generated_from': 'scripts/kamino-admissible.sh',
    'klend': {'pin': K.KLEND_PIN, 'tag': K.KLEND_TAG},
    'counts': {'total': len(rows), 'admissible': len(adm)},
    'mints': rows,
}, open('web/kamino.json', 'w'), indent=1)
json.dump({'klend': {'pin': K.KLEND_PIN, 'tag': K.KLEND_TAG},
           'counts': {'total': len(rows), 'admissible': len(adm)}},
          open('web/kamino-summary.json', 'w'), indent=1)
print('\n  wrote web/kamino.json (full, for the repository) and web/kamino-summary.json (for the page)')
PY
