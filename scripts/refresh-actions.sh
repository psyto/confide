#!/usr/bin/env bash
# Re-pull the xStocks corporate-action schedule into the fixture mora-equity compiles in.
#
# Only unit-changing actions are kept (ForwardSplit / ReverseSplit). Cash dividends do not move
# units and are out of scope. No auth, no key.
set -euo pipefail
cd "$(dirname "$0")/.."
API="https://api.xstocks.fi/api/v2/public/corporate-actions/upcoming"
OUT=crates/mora-equity/fixtures/corporate-actions.json

tmp=$(mktemp)
for pg in 1 2 3 4 5 6; do
  curl -s --max-time 30 "$API?pageSize=100&page=$pg" >> "$tmp"
  echo >> "$tmp"
done

python3 - "$tmp" "$OUT" <<'PY'
import json, sys, datetime
src, out = sys.argv[1], sys.argv[2]
rows = []
for line in open(src):
    line = line.strip()
    if not line:
        continue
    for n in json.loads(line)['nodes']:
        if n['caType'] in ('ForwardSplit', 'ReverseSplit') and n.get('status') == 'Scheduled' \
           and n.get('fromUnits') and n.get('toUnits'):
            rows.append({
                'symbol': n['xstockSymbol'], 'isin': n.get('xstockIsin'),
                'caType': n['caType'], 'effectiveTimeUtc': n['effectiveTimeUtc'],
                'fromUnits': n['fromUnits'], 'toUnits': n['toUnits'], 'eventId': n['eventId'],
            })
rows.sort(key=lambda r: r['effectiveTimeUtc'])
json.dump({
    'source': 'https://api.xstocks.fi/api/v2/public/corporate-actions/upcoming',
    'fetchedUtc': datetime.datetime.utcnow().strftime('%Y-%m-%d'),
    'note': 'Unit-changing actions only (ForwardSplit / ReverseSplit, status Scheduled). '
            'Cash dividends do not move units and are out of scope here. '
            'Refresh with scripts/refresh-actions.sh.',
    'nodes': rows,
}, open(out, 'w'), indent=2)
open(out, 'a').write('\n')
print('%d unit-changing events -> %s' % (len(rows), out))
for r in rows:
    print('  %-8s %-14s %s  %s -> %s' % (r['symbol'], r['caType'], r['effectiveTimeUtc'][:10], r['fromUnits'], r['toUnits']))
PY
rm -f "$tmp"
echo
echo "the fixture is compiled in, so rebuild to pick it up:  cargo test -p mora-equity"
