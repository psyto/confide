#!/usr/bin/env bash
# Which devnet swaps the site reads, and what this repository claims about each.
#
#   ./scripts/refresh-swaps.sh
#
# Same contract as refresh-loans.sh: this file names the transactions and states the claim. **It
# does not decide the outcome** — the page fetches each one from devnet and shows what the chain
# says, including when the chain disagrees with the line below.
#
# The accounts are listed so the page can show the thing that is hardest to believe: every one of
# them is an ordinary associated token account, and every one still reports a public balance of 0
# after the trade settled.
set -euo pipefail
cd "$(dirname "$0")/.."
R="${RPC:-https://api.devnet.solana.com}"
OUT=web/swaps.json

python3 - "$R" > "$OUT" <<'PY'
import json, subprocess, sys, time
R = sys.argv[1]

SWAPS = [
 {"label": "stock for stock",
  "signature": "2RksP5AMcdvucLvPeXteVZm8SXL8xn6B9j4wtWJEw6kY2tfRfesQcuMP8bjugcdTKVdr6LdPK8XkG6QkEPk82Uk9",
  "claim": "two holders exchange positions; no program, no escrow",
  "accounts": ["3SssY73ryeThZqCrTaU1A1r4wBZjhW4baFPnJH1nhAvy",
               "811gaATgkHRnAjTSg1NwyDBX8tn1KSfR5RVCxaUcQqAM",
               "EXUjDC8LUwQFnbBKyC7K7CnKGEtpKTEyRargSsgUjq19",
               "Gaa5chxjVWhRbCbjR45YhaS2J1tpq6jJct95TSs4SNA5"]},
 {"label": "stock for cash",
  "signature": "4gzku3FWoRzhNr24gUTBquxEPwq9L5nqZrmtrCHWjzMBjaDyiapTj6zrBtGLTcRvzPzhexuJfdgxdqafu5Jhhovs",
  "claim": "50,000 shares for $8,750,000 — delivery versus payment, one transaction",
  "accounts": ["6sGtxuaRrBhnph9Y8CyX428HstztBwJBX62wacHBsNwq",
               "BbqCriFfNGgy966GYpecUPfajKp6Hq7oMN4n1H5BqETm",
               "4Bu93JSs17wTrX6xFWzcNPrxq4rdLB7VYpCfFtJiekHR",
               "Bz9HdL72NyFjn2sdvPqrgxfuP7wk4EfMV7ZbocqPFJ9u"]},
 {"label": "stock for cash, on a mint shaped like PYUSD",
  "signature": "5ZrJPGRLHKzzR1us4KF3kf9z5hSgvQLabHKQbkMmCSkGEGXAkC8QA7JtnMhsVBsCJzrW5a75s9LJsxaaKsqesZug",
  "claim": "one transaction carrying confidentialTransfer AND confidentialTransferWithFee",
  "accounts": ["44kL6AZYDksPKpUT3rcYWXhZP6evsmDrwe6XjkBEHeXt",
               "DPUAa1hnN7Z3A8ZsYdKGaxPGS8RdVXgdyoWrDfW52wyK",
               "APwvSMw9AwybqnnCJw9BSFbNUadsZxteWQDgNu45WQGQ",
               "7cdR88gdEetn9sYSGbAZhpUqMsKjUFW2z39jujbyxaeV"]},
]

def rpc(method, params):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params})
    out = subprocess.run(["curl", "-s", "--max-time", "60", R,
                          "-H", "content-type: application/json", "-d", body],
                         capture_output=True).stdout
    return json.loads(out).get("result")

# Checked here as well as in the browser, so a signature that has died on a devnet reset is caught
# by the person regenerating the file rather than by a judge opening the page.
alive = 0
for s in SWAPS:
    t = rpc("getTransaction", [s["signature"],
                               {"encoding": "jsonParsed", "maxSupportedTransactionVersion": 0}])
    s["confirmed_when_written"] = bool(t) and t["meta"]["err"] is None
    alive += 1 if s["confirmed_when_written"] else 0
    time.sleep(0.3)

print(json.dumps({
    "generated_utc": time.strftime("%Y-%m-%d %H:%M:%S UTC", time.gmtime()),
    "note": "Which devnet swaps the page reads. The page decodes each from the chain itself; this "
            "file does not decide the outcome.",
    "confirmed_when_written": alive,
    "swaps": SWAPS,
}, indent=1))
PY
python3 -c "
import json; d=json.load(open('$OUT'))
print('  %d of %d confirmed on devnet, written to $OUT' % (d['confirmed_when_written'], len(d['swaps'])))"
