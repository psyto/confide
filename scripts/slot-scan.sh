#!/usr/bin/env bash
# Check the auditor slot AND the approval gate on EVERY tokenized-equity mint on Solana, across
# both issuers, not a sample. Both fields come out of the same `confidentialTransferMint` state, so
# the second one is free.
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
    # Two thousand mints is enough volume to get rate-limited; back off rather than reporting a limit as
    # a finding, which is what an unretried error looks like in the output.
    for attempt in range(6):
        try:
            v = json.load(urllib.request.urlopen(req, timeout=30)).get('result', {}).get('value')
            if not v:
                return (m['symbol'], 'NO_ACCOUNT', None, [])
            all_ext = [e['extension'] for e in v['data']['parsed']['info'].get('extensions', [])]
            ext = [e for e in v['data']['parsed']['info'].get('extensions', [])
                   if e['extension'] == 'confidentialTransferMint']
            if not ext:
                return (m['symbol'], 'NO_CT_EXTENSION', None, all_ext)
            st = ext[0]['state']
            k = st.get('auditorElgamalPubkey')
            return (m['symbol'], 'EMPTY' if k is None else 'KEY',
                    st.get('autoApproveNewAccounts'), all_ext)
        except Exception:
            time.sleep(0.6 * (attempt + 1))
            continue
    return (m['symbol'], 'ERROR', None, [])

with cf.ThreadPoolExecutor(max_workers=4) as ex:
    res = list(ex.map(check, mints))

by_issuer = Counter()
for m, (_, st, _auto, _ex) in zip(mints, res):
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
# Derived. It said "Two issuers" for as long as there were two, and PreStocks made it wrong
# without making it fail — the exact shape of every other stale number in this repository.
n_iss = len({m.get('issuer', '?') for m in mints})
print('  %d issuers, independently, reaching the same dead end.' % n_iss)

# The approval gate, which is the other half of the pincer.
#
# Kamino refuses a liquidity mint whose `auto_approve_new_accounts` is true
# (constraints.rs:131 — "Auto approve new accounts must be false for liquidity tokens"). On a mint
# where it is false, every new confidential account — Confide's escrow included — needs the
# issuer's explicit approval. So the setting Kamino requires is the setting that puts the issuer in
# the path, and the two are the same field read from two sides.
auto = [r for r in res if r[2] is True]
gated = [r for r in res if r[2] is False]
print()
print('  THE APPROVAL GATE — the same field Kamino reads at constraints.rs:131')
print('    %d of %d set autoApproveNewAccounts = false' % (len(gated), len(res)))
print('    %d auto-approve, so %d can hold a confidential position without the issuer' % (len(auto), len(auto)))
if auto:
    print('\n  some mint auto-approves now:', auto[:12])
    print('  the pincer has a hole in it — that is a finding, and the docs say there is none')
    raise SystemExit(1)
# The other confidential capability Token-2022 ships, and the second question this same fetch can
# answer for free. ConfidentialMintBurn keeps the SUPPLY encrypted -- current_supply is a
# PodElGamalCiphertext -- so an issuer can mint and burn without moving the public figure. Codex
# surfaced it on 2026-09-22 while reviewing a claim that redemption always publishes its size.
#
# If this is zero too, the finding is not "the confidential transfer capability is unused". It is
# "every confidential capability Token-2022 ships is unused" -- the same claim one size up, for no
# extra scan.
ext_count = Counter()
for r in res:
    for e in r[3]:
        ext_count[e] += 1
cmb = ext_count.get('confidentialMintBurn', 0)
print()
print('  THE OTHER CONFIDENTIAL CAPABILITY')
print('    %d of %d carry confidentialMintBurn - an ENCRYPTED supply' % (cmb, len(res)))
if cmb == 0:
    print('    So a redemption that burns moves a public figure by exactly the redeemed amount,')
    print('    on every one of them. Configuration, not protocol: one instruction changes it.')
print()
print('  Every mint Kamino would accept is a mint whose issuer must approve each escrow.')
print('  No amount of engineering on this side removes that.')

# Written down, because the README carried a COPY of the table above and the copy went stale: it
# said 732 Backed and 1,137 Backpack long after the real counts were 828 and 1,156, it never
# learned that a third issuer existed, and its two numbers did not even add up to the 1,992 in the
# sentence beside them. The script had already been fixed to derive the issuer count. The paste
# had not, and nothing checked it. So the table is an artifact now and prose is checked against it.
import json as _json, time as _time, os as _os
_os.makedirs('web', exist_ok=True)
_json.dump({
    'generated_utc': _time.strftime('%Y-%m-%d %H:%M:%S UTC', _time.gmtime()),
    # NOT the endpoint. This file is committed and published to the site, and the founder's
    # private RPC carries its key in the URL — writing it here would leak it, which this wrote on
    # its first run. Only whether it was the private one, which is all a reader needs to know.
    'endpoint': 'private' if 'api.mainnet-beta' not in rpc and 'publicnode' not in rpc else 'public',
    'note': 'Every tokenized-equity mint on Solana, read one at a time. Not a sample.',
    'mints': len(res),
    'issuers': sorted({m.get('issuer', '?') for m in mints}),
    'by_issuer': [{'issuer': i, 'auditor': st, 'mints': v}
                  for (i, st), v in sorted(by_issuer.items())],
    'confidential_mint_burn': cmb,
    'extensions': dict(sorted(ext_count.items(), key=lambda x: -x[1])),
    'auditor_empty': sum(1 for r in res if r[1] == 'EMPTY'),
    'gated': len(gated),
    'auto_approve': len(auto),
}, open('web/slots.json', 'w'), indent=1)
print()
print('  written to web/slots.json')
PY
