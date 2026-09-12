#!/usr/bin/env bash
# Re-pull every xStock's Solana mint into web/mints.json.
#
# The assets endpoint paginates — taking only the first page gives you 100 alphabetically-early
# symbols and silently omits NVDAx, which is the kind of bug that looks like a broken page.
set -euo pipefail
cd "$(dirname "$0")/.."
tmp=$(mktemp)
for pg in $(seq 1 12); do
  curl -s --max-time 40 "https://api.xstocks.fi/api/v2/public/assets?pageSize=100&page=$pg" >> "$tmp"
  echo >> "$tmp"
done
python3 - "$tmp" <<'PY'
import json, sys
out = {}
for line in open(sys.argv[1]):
    line = line.strip()
    if not line:
        continue
    for a in json.loads(line).get('nodes', []):
        for dep in a.get('deployments', []) or []:
            if dep.get('network') == 'Solana' and dep.get('address', '').startswith('Xs'):
                out[a['symbol']] = {'symbol': a['symbol'], 'name': a.get('name'),
                                    'mint': dep['address'], 'underlying': a.get('underlyingSymbol')}
                break
rows = sorted(out.values(), key=lambda x: x['symbol'])
json.dump(rows, open('web/mints.json', 'w'), indent=1)
print('%d Solana mints -> web/mints.json' % len(rows))
for s in ('NVDAx', 'TSLAx', 'SPYx', 'AAPLx'):
    assert any(r['symbol'] == s for r in rows), s + ' missing — the fetch is incomplete'
print('the four the page watches are all present')
PY
rm -f "$tmp"
