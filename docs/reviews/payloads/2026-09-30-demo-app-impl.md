# Review request — the demo app, implemented, 2026-09-30

Design (already reviewed by you): `docs/cwf-2026/DEMO-APP.md` and your review
`docs/reviews/2026-09-30-story-and-app.md`. This is the implementation. **Nothing here has touched a
chain** — no RPC in this session. The page was rendered in a browser against a throwaway fake script
(not committed, so it cannot be recorded as a demo).

Files: `app/server.py`, `app/static/{index.html,app.js,app.css}`, `app/test_app.py` (9 tests,
all pass; 6 deliberate breakages each failed a test), and the hooks in `scripts/lib/chain.sh`
(`ev`, `pause_open`, `pause`, `GO_SIG`), `scripts/issue-e2e.sh` (pause before each step,
checkpoint after each assertion, act 2), `scripts/swap-sign.sh` (one checkpoint after `go`).

## Questions — adversarial

1. **Is any checkpoint written before the assertion it reports, or on a path where the assertion
   could have failed without exiting?** Read every `ev` call in issue-e2e.sh and swap-sign.sh
   against the lines above it. In particular: `ev account ... approved="$appr"` (is "yes" true only
   after the approval confirmed?), `ev checked` after `swap_look | tee` (pipefail), the act-2
   `ev checked ... against=pin` written after swap-settle.sh / swap-sign.sh returned 0 — does exit 0
   really imply the pin comparison passed?
2. **Did the instrumentation change the terminal behaviour?** `show()` was rewritten; `swap_look`
   now pipes through `tee`; `go` sets `GO_SIG`; `pause_open` does `exec 9<>` on a FIFO. Any
   difference in output, exit status or failure modes when the variables are unset?
3. **Server**: find a way for the browser (or another web page) to do anything other than start a
   run or advance the waited-on step; to read the RPC URL, a key, the work directory or raw logs;
   to make the proxy read an id this run did not report; or to make the page show a refusal or
   settlement the script did not write. Check the FIFO handling (O_NONBLOCK writer, the script's
   O_RDWR fd 9), the SSE reader (byte offsets, partial lines, run replacement), cleanup on SIGTERM,
   the process-group kill, and the sanitiser's allowed-character set.
4. **Page**: any path where untrusted text becomes HTML? Anything on screen that overclaims —
   e.g. "Checked against my own pinned terms" in act 2, the observer's "confidential: encrypted", or
   labels that imply separate wallets?
5. DEMO-APP.md's "Implemented / Not yet implemented" split — accurate?

## Script diff

```diff
diff --git a/scripts/issue-e2e.sh b/scripts/issue-e2e.sh
index e05ba78..3ace89d 100755
--- a/scripts/issue-e2e.sh
+++ b/scripts/issue-e2e.sh
@@ -54,6 +54,9 @@ cd "$(dirname "$0")/.."
 . "$(dirname "$0")/lib/swap.sh"
 R="${RPC:-https://api.devnet.solana.com}"
 W="${WORK:-$(mktemp -d)}"; mkdir -p "$W"
+# The demo app's hooks (docs/cwf-2026/DEMO-APP.md). Both inert without CONFIDE_EVENTS / CONFIDE_PAUSE.
+pause_open
+ev run mode="$([ -n "${SHORT:-}" ] && echo short || echo normal)"
 DEC_X="${DECIMALS:-8}"          # the equity wrapper's
 DEC_Y=6                         # PYUSD's
 TREASURY="${TREASURY:-500000}"  # what the issuer holds to allocate from
@@ -70,6 +73,7 @@ ata() { spl-token -C "$1" address --token "$2" --verbose 2>&1 \
 prov() { go "$1" "$(cargo run --quiet -p confide-ct --bin provision -- "$1" "$2" "$3" "$4" "$5" \
          "$(bh)" "$6" "$(mint_charges_fee "$3")" "$7" 2>/dev/null)"; }
 
+pause parties
 echo
 echo "  ${bold}--- two parties: the issuer, and somebody subscribing ---${off}"
 FUNDER="${FUNDER:-$HOME/.config/solana/id.json}"
@@ -80,8 +84,10 @@ for k in issuer investor; do
   printf 'json_rpc_url: %s\nwebsocket_url: ""\nkeypair_path: %s\ncommitment: confirmed\n' \
     "$R" "$W/$k.json" > "$W/$k.yml"
   echo "    $k   $(solana-keygen pubkey "$W/$k.json")"
+  ev party who="$k" pubkey="$(solana-keygen pubkey "$W/$k.json")"
 done
 
+pause mints
 echo
 echo "  ${bold}--- the stock, gated and auditor-EMPTY exactly as all 1,992 are ---${off}"
 mk() { # mk <letter> <decimals> <auditor|none> [flags...]
@@ -95,6 +101,7 @@ mk() { # mk <letter> <decimals> <auditor|none> [flags...]
   eval "MINT_$ml=$mint"
   printf '    mint %s   %s   %s(%s decimals, autoApproveNewAccounts false, auditor %s)%s\n' \
     "$ml" "$mint" "$dim" "$dec" "$([ "$aud" = none ] && echo EMPTY || echo set)" "$off"
+  ev mint asset="$ml" mint="$mint" decimals="$dec" auditor="$([ "$aud" = none ] && echo empty || echo set)"
 }
 mk X "$DEC_X" none
 mk Y "$DEC_Y" none --enable-permanent-delegate --enable-close --enable-freeze \
@@ -120,24 +127,32 @@ open() {
     prov apply   "$W/$who.json" "$mint" "$acct" "$units" "$W/$who-$ml-keys.json" "$dec"
   fi
   eval "${who}_${ml}=$acct"
+  # After the approval (if any) has confirmed -- `go` exits the script under set -e otherwise.
+  ev account who="$who" asset="$ml" account="$acct" approved="$appr" funded="$units"
 }
 
+pause holdings
 echo
 echo "  ${bold}--- the issuer's treasury, and the investor's cash ---${off}"
 open issuer   X "$MINT_X" "$TREASURY" "$DEC_X" yes
 open investor Y "$MINT_Y" "$CASH"     "$DEC_Y" yes
 open issuer   Y "$MINT_Y" 0           "$DEC_Y" yes
 
+pause investor_opens
 echo
 echo "  ${bold}--- the investor opens an account for the stock. This is the gate ---${off}"
 open investor X "$MINT_X" 0 "$DEC_X" no
 
+pause proofs
 echo
 echo "  ${bold}--- both legs' proofs, built before anybody knows whether it will be allowed ---${off}"
 swap_leg issuer   "$W/issuer.json"   "$W/issuer-X-keys.json"   "$MINT_X" "$issuer_X"   "$investor_X" \
   "$(swap_elgamal "$W/investor-X-keys.json")" "$SEND_X" "$DEC_X" "$W/issuer-ctx.json"
 swap_leg investor "$W/investor.json" "$W/investor-Y-keys.json" "$MINT_Y" "$investor_Y" "$issuer_Y" \
   "$(swap_elgamal "$W/issuer-Y-keys.json")" "$PAY" "$DEC_Y" "$W/investor-ctx.json"
+ev proofs legs=2
+
+pause check
 
 echo
 echo "  ${bold}--- before signing, the investor CHECKS the allocation addressed to them ---${off}"
@@ -151,7 +166,9 @@ if [ -n "${SHORT:-}" ]; then
   # and nothing else, which is the whole point of the control, so it must not borrow the gate's story.
   printf '    %sNothing else differs. The proofs are valid, and the amount is the only thing wrong.%s\n' \
     "$dim" "$off"
-  if swap_look "$W/investor-X-keys.json" "$W/issuer-ctx.json" "$ALLOC" "$DEC_X"; then
+  # tee only COPIES the checker's output so the app can show the decrypted figure. The verdict is the
+  # checker's exit status, which pipefail carries through the pipe unchanged.
+  if swap_look "$W/investor-X-keys.json" "$W/issuer-ctx.json" "$ALLOC" "$DEC_X" | tee "$W/check.out"; then
     echo >&2
     echo "  A SHORT LEG PASSED THE CHECK. The investor would have signed for $ALLOC shares and" >&2
     echo "  received $SHORT. That is the finding, not this script." >&2
@@ -165,11 +182,16 @@ if [ -n "${SHORT:-}" ]; then
   printf '  %sThe proof contexts are on chain and hold nothing readable; the transfer does not exist.%s\n' \
     "$dim" "$off"
   printf '  %sThe gate refusal is the other control: run without SHORT.%s\n' "$dim" "$off"
+  ev refused source=pre_sign_check what=allocation agreed="$ALLOC" decimals="$DEC_X" \
+     decrypted_base="$(grep -aoE 'this leg moves [0-9]+' "$W/check.out" | grep -oE '[0-9]+$' | head -1)"
+  ev done mode=short
   echo
   echo "    work dir  $W"
   exit 0
 fi
-swap_look "$W/investor-X-keys.json" "$W/issuer-ctx.json" "$ALLOC" "$DEC_X"
+swap_look "$W/investor-X-keys.json" "$W/issuer-ctx.json" "$ALLOC" "$DEC_X" | tee "$W/check.out"
+ev checked source=pre_sign_check who=investor agreed="$ALLOC" decimals="$DEC_X" \
+   decrypted_base="$(grep -aoE 'it will move [0-9]+' "$W/check.out" | grep -oE '[0-9]+$' | head -1)"
 
 build() {
   cargo run --quiet -p confide-ct --bin swap-tx -- "$W/issuer.json" "$(bh)" \
@@ -214,6 +236,7 @@ s=next(e['state'] for e in i['extensions'] if e['extension']=='confidentialTrans
 print('true' if s['approved'] else 'false')"
 }
 
+pause send_allocation
 echo
 echo "  ${bold}--- the allocation, sent while the account is unapproved ---${off}"
 build
@@ -228,7 +251,8 @@ case "$err" in
   *'"Custom": 24'*|*'"Custom":24'*|*"Custom(24)"*)
     printf '    %sREFUSED on chain — Custom(24), ConfidentialTransferAccountNotApproved%s\n' "$red" "$off"
     printf '    %s%s%s\n' "$dim" "$REFUSED_SIG" "$off"
-    printf '    %sthe proofs are valid, the amounts are right, and the issuer has not signed.%s\n' "$dim" "$off";;
+    printf '    %sthe proofs are valid, the amounts are right, and the issuer has not signed.%s\n' "$dim" "$off"
+    ev refused source=on_chain what=allocation sig="$REFUSED_SIG" err="Custom(24)";;
   null)
     echo "    IT SETTLED. The destination was approved when it should not have been — the gate" >&2
     echo "    this repository is about did not hold, and that is the finding, not this script." >&2
@@ -239,6 +263,7 @@ case "$err" in
     echo "    refused, but not for the reason this demonstrates: $err" >&2; exit 1;;
 esac
 
+pause self_approve
 echo
 echo "  ${bold}--- the investor tries to approve their own account ---${off}"
 # THE GATE HAS A KEYHOLE, NOT JUST A DOOR. The refusal above shows an unapproved account cannot
@@ -269,14 +294,19 @@ esac
 # And the account is still shut. Read from the chain, not concluded from the error.
 [ "$(approved "$investor_X")" = false ] || { echo "    the account reads approved after a refused approval" >&2; exit 1; }
 printf '    %sthe account still reads approved: false%s\n' "$dim" "$off"
+ev refused source=on_chain what=self_approval sig="$WRONG_SIG" err="MissingRequiredSignature"
+ev approval account="$investor_X" approved=false
 
+pause issuer_approves
 echo
 echo "  ${bold}--- the issuer signs for the account. One instruction ---${off}"
 go "the issuer approves it" "$(cargo run --quiet -p confide-ct --bin seizure-client -- approve \
   "$W/issuer.json" "$investor_X" "$MINT_X" "$(bh)")"
 
 [ "$(approved "$investor_X")" = true ] || { echo "    the approval confirmed but the account does not read approved" >&2; exit 1; }
+ev approval account="$investor_X" approved=true sig="$GO_SIG"
 
+pause issuer_signs_alone
 echo
 echo "  ${bold}--- the issuer signs the allocation alone ---${off}"
 # ONE SIGNATURE OF TWO. The gate is open now, the proofs are valid and the amounts are right, so the
@@ -321,7 +351,8 @@ case "$verdict" in
   SIGFAIL*)
     printf '    %sREFUSED in RPC preflight — %s%s\n' "$red" "${verdict#SIGFAIL }" "$off"
     printf '    %sit never entered a block, so there is nothing on chain to cite. The next step adds the\n' "$dim"
-    printf '    investor'"'"'s signature to THIS transaction and sends it%s\n' "$off";;
+    printf '    investor'"'"'s signature to THIS transaction and sends it%s\n' "$off"
+    ev refused source=rpc_preflight what=half_signed signatures="1 of 2" message="${verdict#SIGFAIL }";;
   OTHER)
     echo "    refused, but not for the reason this demonstrates: $half" >&2; exit 1;;
   *)
@@ -330,6 +361,7 @@ case "$verdict" in
     exit 1;;
 esac
 
+pause investor_signs
 echo
 echo "  ${bold}--- the investor adds their signature to that same transaction ---${off}"
 # Not rebuilt. The only difference between what was refused a moment ago and what is sent now is one
@@ -344,14 +376,19 @@ confirm "$ALLOC_SIG" || exit 1
 CU=$(rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getTransaction\",\"params\":[\"$ALLOC_SIG\",{\"commitment\":\"confirmed\",\"maxSupportedTransactionVersion\":0}]}" \
   | python3 -c "import sys,json;r=json.load(sys.stdin).get('result');print(r['meta'].get('computeUnitsConsumed','?') if r else '?')")
 printf '    %-22s ok   %s%s   %s compute units%s\n' "the allocation" "$dim" "$ALLOC_SIG" "$CU" "$off"
+ev settled act=1 sig="$ALLOC_SIG" cu="$CU" shares="$ALLOC" cash="$PAY" signatures="2 of 2"
 
+pause observe
 echo
 echo "  ${bold}--- what moved ---${off}"
 prov apply "$W/investor.json" "$MINT_X" "$investor_X" "$ALLOC" "$W/investor-X-keys.json" "$DEC_X" >/dev/null
 prov apply "$W/issuer.json"   "$MINT_Y" "$issuer_Y"   "$PAY"   "$W/issuer-Y-keys.json"   "$DEC_Y" >/dev/null
-show() { local d a p o; read -r d a p o < <(ct "$2"); printf '    %-34s ' "$1"
-  cargo run --quiet -p confide-ct --bin read-balance -- "$3" "$d" "$a" "$4" 2>/dev/null \
-  | sed -n '3p' | sed 's/^ *//'; }
+show() { local d a p o line; read -r d a p o < <(ct "$2")
+  line=$(cargo run --quiet -p confide-ct --bin read-balance -- "$3" "$d" "$a" "$4" 2>/dev/null \
+         | sed -n '3p' | sed 's/^ *//')
+  printf '    %-34s %s\n' "$1" "$line"
+  # What the OWNER reads with their own key. The app shows it in that owner's view only.
+  ev holding label="$1" account="$2" view="$line"; }
 show "issuer, treasury (allocated from)" "$issuer_X"   "$W/issuer-X-keys.json"   "$DEC_X"
 show "investor, stock (received)"        "$investor_X" "$W/investor-X-keys.json" "$DEC_X"
 show "investor, cash (paid)"             "$investor_Y" "$W/investor-Y-keys.json" "$DEC_Y"
@@ -366,6 +403,7 @@ printf '    %spublic balances: issuer stock %s, investor stock %s, investor cash
 for v in $PUBS; do
   [ "$v" = 0 ] || { echo "    a public balance is $v, not 0 -- an amount is visible to anyone" >&2; exit 1; }
 done
+ev public act=1 accounts="$issuer_X,$investor_X,$investor_Y,$issuer_Y" balances="$(echo $PUBS | tr ' ' ',')"
 echo
 echo "  ${grn}${bold}An allocation was refused, the investor could not approve themselves, a half-signed"
 echo "  allocation was refused, the issuer signed, and the same allocation settled with both signatures."
@@ -391,6 +429,7 @@ if [ "${ACT2:-1}" = 1 ]; then
   SELL_PAY="${SELL_PAY:-875000}" # $875,000 — the same $175 a share, agreed off chain
   CASH_B="${CASH_B:-1000000}"   # what the second holder holds
 
+  pause act2_accounts
   echo
   echo "  ${bold}=== ACT 2 — the investor sells $SELL shares to a second approved holder ===${off}"
   solana-keygen new --no-bip39-passphrase --silent --force -o "$W/buyer.json" >/dev/null
@@ -399,6 +438,7 @@ if [ "${ACT2:-1}" = 1 ]; then
   printf 'json_rpc_url: %s\nwebsocket_url: ""\nkeypair_path: %s\ncommitment: confirmed\n' \
     "$R" "$W/buyer.json" > "$W/buyer.yml"
   echo "    buyer   $(solana-keygen pubkey "$W/buyer.json")"
+  ev party who=buyer pubkey="$(solana-keygen pubkey "$W/buyer.json")"
   # The issuer approves both of the buyer's accounts. The refusal before approval was act 1's point
   # and is not repeated.
   open buyer X "$MINT_X" 0        "$DEC_X" yes
@@ -415,19 +455,30 @@ if [ "${ACT2:-1}" = 1 ]; then
   }
   WA=$(party investor); WB=$(party buyer)
 
+  pause offer
   echo
   echo "  ${bold}--- 1 of 4: the investor offers $SELL shares for \$$SELL_PAY, and pins those terms ---${off}"
   WORK="$WA" RPC="$R" ./scripts/swap-offer.sh "$W/investor.json" \
     --give "$MINT_X" "$SELL" --want "$MINT_Y" "$SELL_PAY" > "$W/offer.json"
+  ev offer id="$(python3 -c "import json;print(json.load(open('$W/offer.json'))['id'])")" shares="$SELL" cash="$SELL_PAY" pinned_by=investor
+  pause accept
   echo
   echo "  ${bold}--- 2 of 4: the buyer reads the offer, pins it, and builds the cash leg's proofs ---${off}"
   WORK="$WB" RPC="$R" ./scripts/swap-accept.sh "$W/buyer.json" "$W/offer.json" > "$W/accept.json"
+  ev accepted pinned_by=buyer
+  pause settle
   echo
   echo "  ${bold}--- 3 of 4: the investor checks the cash against the pin, builds the stock leg, signs once ---${off}"
   WORK="$WA" RPC="$R" ./scripts/swap-settle.sh "$W/investor.json" "$W/accept.json" > "$W/settle.json"
+  # swap-settle exits non-zero unless every pinned field matched and the incoming cash equalled the pin.
+  ev checked source=pre_sign_check who=investor act=2 against=pin signatures="1 of 2"
+  pause sign
   echo
   echo "  ${bold}--- 4 of 4: the buyer checks the shares against the pin, adds the second signature ---${off}"
   WORK="$WB" RPC="$R" ./scripts/swap-sign.sh "$W/buyer.json" "$W/settle.json"
+  ev checked source=pre_sign_check who=buyer act=2 against=pin
+
+  pause observe2
 
   echo
   echo "  ${bold}--- what moved in act 2 ---${off}"
@@ -443,10 +494,12 @@ if [ "${ACT2:-1}" = 1 ]; then
   for v in $PUBS2; do
     [ "$v" = 0 ] || { echo "    a public balance is $v, not 0 -- an amount is visible to anyone" >&2; exit 1; }
   done
+  ev public act=2 accounts="$investor_X,$investor_Y,$buyer_X,$buyer_Y" balances="$(echo $PUBS2 | tr ' ' ',')"
   echo
   echo "  ${grn}${bold}Two approved holders agreed terms off chain, each checked what they would receive"
   echo "  against their own pinned copy of those terms, and stock and cash settled in one transaction."
   echo "  The issuer approved the accounts and did not see the amounts.${off}"
 fi
+ev done mode=normal
 echo
 echo "    work dir  $W"
diff --git a/scripts/lib/chain.sh b/scripts/lib/chain.sh
index 15dbd8e..1822ce3 100644
--- a/scripts/lib/chain.sh
+++ b/scripts/lib/chain.sh
@@ -53,7 +53,36 @@ import sys,json
 v=json.load(sys.stdin)['result']['value'][0]
 print('pending' if v is None else ('FAILED '+json.dumps(v['err'])[:250] if v.get('err') else (v.get('confirmationStatus') or 'pending')))"); \
   case "$st" in confirmed|finalized) return 0;; FAILED*) echo "    $st"; return 1;; esac; sleep 1; done; echo "    timeout"; return 1; }
-go() { local label="$1"; shift; local sig; sig=$(send "$1"); case "$sig" in ERR*) echo "    $label: $sig"; return 1;; esac; confirm "$sig" && printf '    %-22s ok\n' "$label"; }
+# GO_SIG keeps the last signature `go` sent, so a caller can cite it (the demo app shows it). Set
+# only after the send returned a signature; a failed send leaves it empty.
+go() { local label="$1"; shift; local sig; GO_SIG=""; sig=$(send "$1"); case "$sig" in ERR*) echo "    $label: $sig"; return 1;; esac; GO_SIG="$sig"; confirm "$sig" && printf '    %-22s ok\n' "$label"; }
+
+# ev <name> [key=value …] — one typed checkpoint for the demo app (docs/cwf-2026/DEMO-APP.md).
+# Inert unless CONFIDE_EVENTS is set, so a terminal run is unchanged. CALL IT ONLY AFTER the thing
+# it reports has been asserted: the app shows refusals and settlements from these lines and from
+# nothing else, so a checkpoint written early is a display that lies.
+ev() {
+  [ -n "${CONFIDE_EVENTS:-}" ] || return 0
+  python3 - "$@" >> "$CONFIDE_EVENTS" <<'PYEV'
+import json, sys
+d = {"ev": sys.argv[1]}
+for kv in sys.argv[2:]:
+    k, _, v = kv.partition("=")
+    d[k] = v
+print(json.dumps(d), flush=True)
+PYEV
+}
+
+# pause <next-step> — wait for the app's "advance" before the next step. Inert unless CONFIDE_PAUSE
+# names a FIFO. The line read is an advance token and nothing else: it is never executed, echoed or
+# interpolated. The FIFO is held open read-write on fd 9 (opened once, by pause_open), so the app's
+# non-blocking write finds a reader and a reader never blocks on open.
+pause_open() { [ -n "${CONFIDE_PAUSE:-}" ] || return 0; exec 9<>"$CONFIDE_PAUSE"; }
+pause() {
+  [ -n "${CONFIDE_PAUSE:-}" ] || return 0
+  ev waiting next="$1"
+  local _token; read -r _token <&9
+}
 ct() { rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getAccountInfo\",\"params\":[\"$1\",{\"encoding\":\"jsonParsed\",\"commitment\":\"confirmed\"}]}" \
   | python3 -c "
 import sys,json
diff --git a/scripts/swap-sign.sh b/scripts/swap-sign.sh
index 941f69e..ad3f969 100755
--- a/scripts/swap-sign.sh
+++ b/scripts/swap-sign.sh
@@ -89,6 +89,8 @@ grep -aE "signatures present" "$S/sign2.err" || true
 echo
 echo "  ${bold}--- ONE transaction, two confidential transfers, two signatures ---${off}"
 go "the swap" "$(cat "$S/full.b64")"
+# For the demo app only (inert without CONFIDE_EVENTS): written after `go` confirmed, or never.
+ev settled act=2 sig="$GO_SIG" signatures="2 of 2"
 echo
 printf '  %sDelivery and payment happened in the same transaction. Neither could occur without the\n' "$grn"
 printf '  other, and nothing stood between you. Apply the incoming balance with your own key:%s\n' "$off"
```

## app/server.py

```python
#!/usr/bin/env python3
"""The Confide demo app's local server. Design and the reasons: docs/cwf-2026/DEMO-APP.md.

    RPC=<devnet endpoint> python3 app/server.py [--port 8787]

It runs scripts/issue-e2e.sh and shows what the script reports. It does NOT build a transaction,
compare an amount, or decide that anything was refused: every outcome on the page comes from a
typed checkpoint the script wrote after its own assertion (`ev` in scripts/lib/chain.sh). The
process exit code means only "completed" or "failed" -- both the normal and the SHORT run exit 0,
so it cannot tell the expected refusals apart, and nothing here tries to.

What the browser can do: start a run (normal or SHORT), and advance the step the script is waiting
on. Nothing else it sends is used -- no environment, path, address, RPC method or command.
"""
import argparse
import http.server
import json
import os
import re
import secrets
import shutil
import signal
import subprocess
import sys
import tempfile
import threading
import time
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STATIC = os.path.join(ROOT, "app", "static")
SCRIPT = os.path.join(ROOT, "scripts", "issue-e2e.sh")
RUN_TIMEOUT_S = 45 * 60
SHORT_UNITS = "2000"  # fixed here; never taken from the client

# The checkpoint vocabulary. Anything the script writes that is not in here -- an unknown event, an
# unknown key, an over-long or oddly-charactered value -- is dropped rather than forwarded.
SCHEMA = {
    "run": {"mode"},
    "waiting": {"next"},
    "party": {"who", "pubkey"},
    "mint": {"asset", "mint", "decimals", "auditor"},
    "account": {"who", "asset", "account", "approved", "funded"},
    "proofs": {"legs"},
    "checked": {"source", "who", "agreed", "decimals", "decrypted_base", "act", "against", "signatures"},
    "refused": {"source", "what", "sig", "err", "agreed", "decimals", "decrypted_base", "signatures", "message"},
    "approval": {"account", "approved", "sig"},
    "settled": {"act", "sig", "cu", "shares", "cash", "signatures"},
    "holding": {"label", "account", "view"},
    "public": {"act", "accounts", "balances"},
    "offer": {"id", "shares", "cash", "pinned_by"},
    "accepted": {"pinned_by"},
    "done": {"mode"},
}
VALUE_OK = re.compile(r"^[A-Za-z0-9 _.,:;()/\-+$'=%—·]{0,300}$")
B58 = re.compile(r"^[1-9A-HJ-NP-Za-km-z]{32,88}$")


def sanitize(line, secret):
    """One raw event line -> a clean dict, or None. The RPC endpoint must never reach the page."""
    try:
        d = json.loads(line)
    except ValueError:
        return None
    if not isinstance(d, dict):
        return None
    name = d.get("ev")
    keys = SCHEMA.get(name)
    if keys is None:
        return None
    out = {"ev": name}
    for k, v in d.items():
        if k == "ev" or k not in keys or not isinstance(v, str):
            continue
        if secret and secret in v:
            continue
        if not VALUE_OK.match(v):
            continue
        out[k] = v
    return out


class Run:
    """One run of the script. The server holds at most one."""

    def __init__(self, mode, rpc):
        os.umask(0o077)
        self.dir = tempfile.mkdtemp(prefix="confide-app-")  # 0700 by construction
        self.events = os.path.join(self.dir, "events.jsonl")
        self.fifo = os.path.join(self.dir, "advance.fifo")
        self.work = os.path.join(self.dir, "work")
        os.mkdir(self.work, 0o700)
        open(self.events, "w").close()
        os.chmod(self.events, 0o600)
        os.mkfifo(self.fifo, 0o600)
        self.mode = mode
        self.expected = None  # the step the script is waiting on, per its own "waiting" checkpoint
        self.state = "running"
        self.lock = threading.Lock()
        self.seen = set()  # public keys and signatures this run has reported -- the proxy allowlist
        env = {
            "PATH": os.environ.get("PATH", "/usr/bin:/bin"),
            "HOME": os.environ.get("HOME", ""),
            "RPC": rpc,
            "WORK": self.work,
            "CONFIDE_EVENTS": self.events,
            "CONFIDE_PAUSE": self.fifo,
        }
        for k in ("CARGO_HOME", "RUSTUP_HOME", "FUNDER", "TMPDIR"):
            if os.environ.get(k):
                env[k] = os.environ[k]
        if mode == "short":
            env["SHORT"] = SHORT_UNITS
        self.log = open(os.path.join(self.dir, "log.txt"), "wb")  # never served
        self.proc = subprocess.Popen(["bash", SCRIPT], cwd=ROOT, env=env, stdin=subprocess.DEVNULL,
                                     stdout=self.log, stderr=subprocess.STDOUT, start_new_session=True)
        self.started = time.time()
        threading.Thread(target=self._reap, daemon=True).start()

    def _reap(self):
        try:
            code = self.proc.wait(timeout=RUN_TIMEOUT_S)
            self.state = "completed" if code == 0 else "failed"
        except subprocess.TimeoutExpired:
            self.kill()
            self.state = "timed out"
        self.expected = None

    def kill(self):
        try:
            os.killpg(self.proc.pid, signal.SIGTERM)
        except ProcessLookupError:
            pass

    def note(self, ev):
        """Track what the script is waiting for, and which public ids it has reported."""
        if ev["ev"] == "waiting":
            with self.lock:
                self.expected = ev.get("next")
        for k in ("pubkey", "mint", "account", "sig"):
            v = ev.get(k, "")
            if B58.match(v):
                self.seen.add(v)
        for v in ev.get("accounts", "").split(","):
            if B58.match(v):
                self.seen.add(v)

    def advance(self, step):
        """Release exactly the step the script says it is waiting on. One token, then nothing until
        the script asks again -- no queued or repeated advances."""
        with self.lock:
            if self.state != "running" or not step or step != self.expected:
                return False
            try:
                fd = os.open(self.fifo, os.O_WRONLY | os.O_NONBLOCK)
            except OSError:
                return False
            try:
                os.write(fd, b"go\n")
            finally:
                os.close(fd)
            self.expected = None
            return True

    def cleanup(self):
        self.kill()
        try:
            self.log.close()
        except Exception:
            pass
        shutil.rmtree(self.dir, ignore_errors=True)


class App:
    def __init__(self, rpc, port):
        self.rpc = rpc
        self.port = port
        self.csrf = secrets.token_urlsafe(32)
        self.run = None
        self.lock = threading.Lock()
        self.reads = []  # timestamps, for the proxy's rate limit

    def start(self, mode):
        with self.lock:
            if self.run and self.run.state == "running":
                return False
            if self.run:
                self.run.cleanup()
            self.run = Run(mode, self.rpc)
            return True

    def rpc_call(self, method, params):
        body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
        req = urllib.request.Request(self.rpc, data=body, headers={"Content-Type": "application/json"})
        with urllib.request.urlopen(req, timeout=20) as r:
            return json.loads(r.read(2_000_000))

    def public_account(self, key):
        """Only what anybody can read, and only the fields the observer pane shows."""
        v = self.rpc_call("getAccountInfo", [key, {"encoding": "jsonParsed", "commitment": "confirmed"}])
        v = (v.get("result") or {}).get("value")
        if not v:
            return {"exists": False}
        info = ((v.get("data") or {}).get("parsed") or {}).get("info") or {}
        ct = next((e.get("state") for e in info.get("extensions", [])
                   if e.get("extension") == "confidentialTransferAccount"), None)
        return {
            "exists": True,
            "owner": info.get("owner"),
            "mint": info.get("mint"),
            "public_balance": (info.get("tokenAmount") or {}).get("uiAmountString"),
            "confidential": ct is not None,
            "approved": bool(ct and ct.get("approved")),
            "pending_and_available": "encrypted" if ct else None,
        }

    def public_tx(self, sig):
        v = self.rpc_call("getTransaction", [sig, {"commitment": "confirmed", "maxSupportedTransactionVersion": 0}])
        r = v.get("result")
        if not r:
            return {"found": False}
        meta = r.get("meta") or {}
        return {
            "found": True,
            "slot": r.get("slot"),
            "err": meta.get("err"),
            "compute_units": meta.get("computeUnitsConsumed"),
            "signatures": len((r.get("transaction") or {}).get("signatures") or []),
        }

    def rate_ok(self):
        now = time.time()
        self.reads = [t for t in self.reads if now - t < 10]
        if len(self.reads) >= 30:
            return False
        self.reads.append(now)
        return True


CSP = ("default-src 'none'; script-src 'self'; style-src 'self'; connect-src 'self'; "
       "img-src 'self' data:; font-src 'self'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'")


def handler_for(app):
    class H(http.server.BaseHTTPRequestHandler):
        server_version = "confide-demo"
        sys_version = ""

        def log_message(self, *a):  # quiet: nothing about the run is logged to the terminal
            pass

        def _host_ok(self):
            return self.headers.get("Host") in (f"127.0.0.1:{app.port}", f"localhost:{app.port}")

        def _send(self, code, body=b"", ctype="application/json", extra=None):
            self.send_response(code)
            self.send_header("Content-Type", ctype)
            self.send_header("Content-Security-Policy", CSP)
            self.send_header("X-Content-Type-Options", "nosniff")
            self.send_header("Referrer-Policy", "no-referrer")
            self.send_header("Cache-Control", "no-store")
            for k, v in (extra or {}).items():
                self.send_header(k, v)
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def _json(self, code, obj):
            self._send(code, json.dumps(obj).encode())

        def do_GET(self):
            if not self._host_ok():
                return self._send(421, b"")
            path = self.path.split("?", 1)[0]
            if path == "/":
                with open(os.path.join(STATIC, "index.html"), encoding="utf-8") as f:
                    html = f.read()
                return self._send(200, html.replace("{{CSRF}}", app.csrf).encode(), "text/html; charset=utf-8")
            if path in ("/app.js", "/app.css"):
                ctype = "text/javascript" if path.endswith(".js") else "text/css"
                with open(os.path.join(STATIC, path[1:]), "rb") as f:
                    return self._send(200, f.read(), ctype + "; charset=utf-8")
            if path == "/events":
                return self._events()
            m = re.match(r"^/chain/(account|tx)/([1-9A-HJ-NP-Za-km-z]{32,88})$", path)
            if m:
                return self._chain(m.group(1), m.group(2))
            return self._send(404, b"")

        def do_POST(self):
            if not self._host_ok():
                return self._send(421, b"")
            if self.headers.get("X-Confide-CSRF") != app.csrf:
                return self._send(403, b"")
            origin = self.headers.get("Origin")
            if origin and origin not in (f"http://127.0.0.1:{app.port}", f"http://localhost:{app.port}"):
                return self._send(403, b"")
            if self.headers.get("Content-Type", "").split(";")[0] != "application/json":
                return self._send(415, b"")
            n = int(self.headers.get("Content-Length") or 0)
            if n > 256:
                return self._send(413, b"")
            try:
                body = json.loads(self.rfile.read(n) or b"{}")
            except ValueError:
                return self._send(400, b"")
            if self.path == "/run":
                mode = "short" if body.get("mode") == "short" else "normal"
                return self._json(200 if app.start(mode) else 409, {"started": mode})
            if self.path == "/advance":
                ok = bool(app.run) and app.run.advance(str(body.get("step", "")))
                return self._json(200 if ok else 409, {"advanced": ok})
            return self._send(404, b"")

        def _events(self):
            self.send_response(200)
            self.send_header("Content-Type", "text/event-stream")
            self.send_header("Cache-Control", "no-store")
            self.send_header("Content-Security-Policy", CSP)
            self.end_headers()
            run, pos, last_state = None, 0, None
            try:
                while True:
                    if app.run is not run:
                        run, pos, last_state = app.run, 0, None
                        self.wfile.write(b"event: reset\ndata: {}\n\n")
                    if run:
                        try:
                            with open(run.events, "rb") as f:
                                f.seek(pos)
                                chunk = f.read()
                        except FileNotFoundError:
                            # the run was cleaned up under us; the next poll picks up the new one
                            time.sleep(0.4)
                            continue
                        # only whole lines; a partial last line waits for the next poll
                        upto = chunk.rfind(b"\n") + 1
                        pos += upto
                        for line in chunk[:upto].decode("utf-8", "replace").splitlines():
                            ev = sanitize(line, app.rpc)
                            if ev:
                                run.note(ev)
                                self.wfile.write(("data: " + json.dumps(ev) + "\n\n").encode())
                        if run.state != last_state:
                            last_state = run.state
                            # the process state, labelled as such -- never a financial outcome
                            self.wfile.write(("data: " + json.dumps({"ev": "process", "state": run.state}) + "\n\n").encode())
                    self.wfile.flush()
                    time.sleep(0.4)
            except (BrokenPipeError, ConnectionResetError):
                return

        def _chain(self, kind, ident):
            run = app.run
            if not run or ident not in run.seen:
                return self._send(404, b"")
            if not app.rate_ok():
                return self._send(429, b"")
            try:
                obj = app.public_account(ident) if kind == "account" else app.public_tx(ident)
            except Exception:
                # no endpoint, no error text: either could carry the RPC URL
                return self._json(502, {"error": "read failed"})
            return self._json(200, obj)

    return H


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", type=int, default=8787)
    a = ap.parse_args()
    rpc = os.environ.get("RPC", "")
    if not rpc.startswith("http"):
        print("  RPC is not set. Pass your devnet endpoint as an environment variable:\n"
              "    RPC=$CONFIDE_RPC python3 app/server.py\n"
              "  The public devnet endpoint stops this script on slot skew (STATUS 2026-09-30 (4)).",
              file=sys.stderr)
        sys.exit(2)
    app = App(rpc, a.port)
    srv = http.server.ThreadingHTTPServer(("127.0.0.1", a.port), handler_for(app))
    print(f"  Confide demo — http://127.0.0.1:{a.port}/   (devnet · local · Ctrl-C to stop)")
    # SIGTERM too, so a killed server still removes its run directory (keys live there).
    signal.signal(signal.SIGTERM, lambda *_: (_ for _ in ()).throw(KeyboardInterrupt()))
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        if app.run:
            app.run.cleanup()


if __name__ == "__main__":
    main()
```

## app/static/app.js

```js
// The Confide demo page. It renders checkpoints; it decides nothing (docs/cwf-2026/DEMO-APP.md).
// Every value shown arrives from the server's sanitised event stream and is inserted as text.
"use strict";

const CSRF = document.querySelector('meta[name="confide-csrf"]').content;
const EXPLORER = (kind, id) => `https://explorer.solana.com/${kind}/${id}?cluster=devnet`;

// The script's step names -> who acts, and the words on the button.
const STEPS = [
  ["parties",            "issuer",   "Set up the issuer and an investor"],
  ["mints",              "issuer",   "Create the stock — gate shut, auditor empty"],
  ["holdings",           "issuer",   "Fund the treasury and the investor's cash"],
  ["investor_opens",     "investor", "Open a confidential account for the stock"],
  ["proofs",             "issuer",   "Build both legs' proofs"],
  ["check",              "investor", "Check the allocation before signing"],
  ["send_allocation",    "issuer",   "Send the allocation (account not approved yet)"],
  ["self_approve",       "investor", "Try to approve my own account"],
  ["issuer_approves",    "issuer",   "Approve exactly this account"],
  ["issuer_signs_alone", "issuer",   "Send with the issuer's signature only"],
  ["investor_signs",     "investor", "Add my signature — settle"],
  ["observe",            "observer", "Look from outside"],
  ["act2_accounts",      "issuer",   "Act 2 — approve a second holder"],
  ["offer",              "investor", "Offer 5,000 shares for $875,000"],
  ["accept",             "buyer",    "Read the offer, pin it, build the cash leg"],
  ["settle",             "investor", "Check the cash against my pin, sign once"],
  ["sign",               "buyer",    "Check the shares against my pin, add the second signature"],
  ["observe2",           "observer", "Look from outside"],
];
const STEP = Object.fromEntries(STEPS.map(([k, who, label]) => [k, { who, label }]));

const el = (tag, cls, text) => {
  const e = document.createElement(tag);
  if (cls) e.className = cls;
  if (text !== undefined) e.textContent = text;
  return e;
};
const short = (s) => (s && s.length > 16 ? s.slice(0, 8) + "…" + s.slice(-4) : s || "");
const link = (kind, id) => {
  const a = el("a", "sig", short(id));
  a.href = EXPLORER(kind, id);
  a.target = "_blank";
  a.rel = "noreferrer noopener";
  return a;
};
const units = (base, decimals) => {
  if (!base || !/^\d+$/.test(base)) return "—";
  const d = Number(decimals || 0);
  const s = base.padStart(d + 1, "0");
  const whole = s.slice(0, s.length - d).replace(/\B(?=(\d{3})+(?!\d))/g, ",");
  return d ? whole : whole;
};

function card(pane, kind, title, lines, extra) {
  const c = el("div", "card " + kind);
  c.appendChild(el("div", "title", title));
  for (const l of lines || []) c.appendChild(el("div", "line", l));
  if (extra) c.appendChild(extra);
  document.getElementById("log-" + pane).prepend(c);
  return c;
}
const paneOf = (who) => ({ issuer: "issuer", investor: "investor", buyer: "buyer" }[who] || "observer");

// ---- the observer reads the chain itself (through the server's allowlisted proxy) ----
const watched = new Map(); // account -> row
async function observe(account, label) {
  if (!watched.has(account)) {
    const row = el("div", "obs-row");
    row.appendChild(el("span", "obs-label", label));
    row.appendChild(link("address", account));
    row.appendChild(el("span", "obs-val", "…"));
    document.getElementById("act-observer").appendChild(row);
    watched.set(account, row);
  }
  const row = watched.get(account);
  try {
    const r = await fetch("/chain/account/" + account);
    if (!r.ok) throw 0;
    const a = await r.json();
    row.lastChild.textContent = a.exists
      ? `public balance ${a.public_balance}` + (a.confidential ? ` · confidential: encrypted${a.approved ? "" : " · not approved"}` : "")
      : "not found";
  } catch (_) {
    row.lastChild.textContent = "read failed";
  }
}
async function txLine(sig, what) {
  const line = el("div", "line");
  line.appendChild(el("span", null, what + " "));
  line.appendChild(link("tx", sig));
  const cu = el("span", "dim", "");
  line.appendChild(cu);
  try {
    const r = await fetch("/chain/tx/" + sig);
    if (r.ok) {
      const t = await r.json();
      if (t.found) cu.textContent = ` · ${t.err ? "failed on chain" : "succeeded"} · ${t.compute_units ?? "?"} CU · ${t.signatures} signatures`;
    }
  } catch (_) {}
  return line;
}

// ---- state ----
const accounts = {}; // "investor-X" -> address
let decimals = {};   // "X" -> decimals
let waitingFor = null;

function resetUI() {
  for (const p of ["issuer", "investor", "buyer", "observer"]) {
    document.getElementById("log-" + p).textContent = "";
    document.getElementById("act-" + p).textContent = "";
  }
  watched.clear();
  decimals = {};
  waitingFor = null;
  renderSteps();
}

function renderSteps(done) {
  const ol = document.getElementById("steps");
  ol.textContent = "";
  let reached = true;
  for (const [k, who, label] of STEPS) {
    const li = el("li", "step " + who, label);
    if (k === waitingFor) { li.classList.add("now"); reached = false; }
    else if (reached && done && done.has(k)) li.classList.add("done");
    ol.appendChild(li);
  }
}
const doneSteps = new Set();

function showNext(step) {
  for (const p of ["issuer", "investor", "buyer"]) {
    const act = document.getElementById("act-" + p);
    act.querySelectorAll("button").forEach((b) => b.remove());
  }
  document.querySelectorAll("#act-observer button").forEach((b) => b.remove());
  if (!step || !STEP[step]) return;
  const { who, label } = STEP[step];
  const b = el("button", "next", label);
  b.type = "button";
  b.addEventListener("click", async () => {
    b.disabled = true;
    const r = await post("/advance", { step });
    if (!r.ok) { b.disabled = false; setStatus("the script was not waiting for that step"); }
  });
  const target = document.getElementById("act-" + (who === "observer" ? "observer" : who));
  target.prepend(b);
}

async function post(path, body) {
  return fetch(path, {
    method: "POST",
    headers: { "Content-Type": "application/json", "X-Confide-CSRF": CSRF },
    body: JSON.stringify(body),
  });
}
const setStatus = (t) => { document.getElementById("status").textContent = t; };

// ---- one handler per checkpoint type ----
const H = {
  run(e) { setStatus(e.mode === "short" ? "running — short-delivery control" : "running"); },
  waiting(e) {
    if (waitingFor) doneSteps.add(waitingFor);
    waitingFor = e.next;
    renderSteps(doneSteps);
    showNext(e.next);
    setStatus("waiting for: " + (STEP[e.next] ? STEP[e.next].label : e.next));
  },
  party(e) { card(paneOf(e.who), "info", "Keypair", [e.pubkey]); },
  mint(e) {
    decimals[e.asset] = e.decimals;
    const name = e.asset === "X" ? "Stock (equity wrapper mirror)" : "Cash (PYUSD mirror)";
    card("issuer", "info", name + " created", [
      "autoApproveNewAccounts: false — the gate is shut",
      "auditor key: " + e.auditor,
    ], link("address", e.mint));
  },
  account(e) {
    accounts[e.who + "-" + e.asset] = e.account;
    const asset = e.asset === "X" ? "stock" : "cash";
    const approved = e.approved === "yes";
    card(paneOf(e.who), approved ? "ok" : "warn",
      `Confidential ${asset} account ${approved ? "— approved by the issuer" : "— NOT approved"}`,
      e.funded && e.funded !== "0" ? ["funded confidentially"] : [], link("address", e.account));
    observe(e.account, `${e.who} ${asset}`);
  },
  proofs() { card("issuer", "info", "Proofs built and verified on chain", ["both legs, before anyone knows whether it will be allowed"]); },
  checked(e) {
    const pane = paneOf(e.who);
    if (e.against === "pin") {
      card(pane, "ok", "✓ Checked against my own pinned terms", ["every field matched; the amount coming to me is what I agreed", e.signatures ? "signatures: " + e.signatures : ""].filter(Boolean));
      return;
    }
    card(pane, "ok", "✓ Checked before signing", [
      `decrypted from the verified proof, by me: ${units(e.decrypted_base, e.decimals)} shares`,
      `agreed: ${Number(e.agreed).toLocaleString("en-US")} shares`,
    ]);
  },
  refused(e) {
    const src = { on_chain: "refused on chain", rpc_preflight: "refused in RPC preflight", pre_sign_check: "refused before signing" }[e.source] || e.source;
    const titles = {
      allocation: e.source === "pre_sign_check" ? "✗ Short delivery — refused before any signature" : "✗ Allocation refused — account not approved",
      self_approval: "✗ I cannot approve my own account",
      half_signed: "✗ One signature of two — refused",
    };
    const pane = e.what === "self_approval" || e.source === "pre_sign_check" ? "investor" : "issuer";
    const lines = [src + (e.err ? " · " + e.err : "")];
    if (e.source === "pre_sign_check") lines.push(`agreed ${Number(e.agreed).toLocaleString("en-US")} shares · this leg moves ${units(e.decrypted_base, e.decimals)}`);
    if (e.message) lines.push(e.message);
    if (e.signatures) lines.push("signatures present: " + e.signatures);
    if (e.source === "rpc_preflight") lines.push("it never entered a block, so there is no signature to cite");
    card(pane, "bad", titles[e.what] || "✗ Refused", lines, e.sig ? link("tx", e.sig) : null);
    if (e.sig) txLine(e.sig, "refused:").then((l) => card("observer", "bad", "A refused transaction, on chain", [], l));
  },
  approval(e) {
    card("issuer", e.approved === "true" ? "ok" : "warn",
      e.approved === "true" ? "✓ Approved exactly this account" : "Account still reads: not approved",
      [], e.sig ? link("tx", e.sig) : link("address", e.account));
    observe(e.account, "investor stock");
  },
  settled(e) {
    const act2 = e.act === "2";
    const lines = act2
      ? ["5,000 shares ⇄ $875,000 between two approved holders", "one transaction · " + (e.signatures || "")]
      : [`${Number(e.shares).toLocaleString("en-US")} shares ⇄ $${Number(e.cash).toLocaleString("en-US")}`, "delivery and payment in one transaction · " + (e.signatures || "")];
    for (const p of act2 ? ["investor", "buyer"] : ["issuer", "investor"]) card(p, "ok", "✓ Settled", lines, link("tx", e.sig));
    txLine(e.sig, "settled:").then((l) => card("observer", "ok", "A settlement — the amounts are not in it", [], l));
  },
  holding(e) {
    const who = e.label.split(",")[0];
    card(paneOf(who), "info", "My balance, read with my own key", [e.label.replace(/^[^,]+,\s*/, ""), e.view]);
  },
  public(e) {
    const accs = e.accounts.split(",");
    const bals = e.balances.split(",");
    card("observer", "ok", "What anyone can read: public balances", accs.map((a, i) => `${short(a)}  →  ${bals[i]}`));
    accs.forEach((a) => observe(a, "account"));
  },
  offer(e) { card("investor", "info", "Offer sent — terms pinned on my side", [`${Number(e.shares).toLocaleString("en-US")} shares for $${Number(e.cash).toLocaleString("en-US")}`, "id " + e.id]); },
  accepted() { card("buyer", "info", "Offer accepted — terms pinned on my side", ["cash leg's proofs built and verified on chain"]); },
  done(e) { waitingFor = null; showNext(null); doneSteps.clear(); setStatus(e.mode === "short" ? "done — the short leg was refused" : "done"); renderSteps(); },
  process(e) {
    if (e.state === "failed" || e.state === "timed out") setStatus("the script " + e.state + " — see the terminal log; nothing on this page is inferred from that");
  },
};

function connect() {
  const es = new EventSource("/events");
  es.addEventListener("reset", resetUI);
  es.onmessage = (m) => {
    let e;
    try { e = JSON.parse(m.data); } catch (_) { return; }
    if (H[e.ev]) H[e.ev](e);
  };
}

document.getElementById("start").addEventListener("click", async () => {
  const r = await post("/run", { mode: "normal" });
  if (!r.ok) setStatus("a run is already in progress");
});
document.getElementById("short").addEventListener("click", async () => {
  const r = await post("/run", { mode: "short" });
  if (!r.ok) setStatus("a run is already in progress");
});
renderSteps();
connect();
```

## app/test_app.py

```python
#!/usr/bin/env python3
"""Does the demo app decide anything it should not? No chain needed.

    python3 app/test_app.py

Three things, from docs/cwf-2026/DEMO-APP.md and the review that shaped it:

1. THE SERVER passes on only typed checkpoints, advances only the step the script is waiting on,
   refuses requests without the CSRF token or with a foreign Host, reads the chain only for ids this
   run reported, and never lets the RPC endpoint reach the page. Tested against a fake script and a
   fake RPC.
2. THE SCRIPT writes a refusal or settlement checkpoint only AFTER the check that justifies it. Each
   assertion block is lifted out of scripts/issue-e2e.sh and run against stubbed chain calls; when
   the stub makes the check fail, the checkpoint must be absent.
3. THE HOOKS are inert: without CONFIDE_EVENTS / CONFIDE_PAUSE, `ev` writes nothing and `pause`
   does not wait.
"""
import http.client
import http.server
import json
import os
import re
import socket
import subprocess
import sys
import tempfile
import textwrap
import threading
import time
import unittest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "app"))
import server  # noqa: E402

SECRET_RPC = "http://127.0.0.1:{port}/secret-key-abc123"
PUB = "9yfKfFD5aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"   # base58-looking, 44 chars
SIG = "5cYPobHEEpECCX9QhsPfquyW4cvhP6NmGD2Vd9jayyF7dU55ivYJDe6aLGYXCqcAE4aQXWmfQs24fZMQdYEdkVUT"


def free_port():
    s = socket.socket()
    s.bind(("127.0.0.1", 0))
    p = s.getsockname()[1]
    s.close()
    return p


class FakeRPC(http.server.BaseHTTPRequestHandler):
    calls = []

    def log_message(self, *a):
        pass

    def do_POST(self):
        body = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
        FakeRPC.calls.append(body["method"])
        if body["method"] == "getAccountInfo":
            res = {"result": {"value": {"data": {"parsed": {"info": {
                "owner": PUB, "mint": PUB, "tokenAmount": {"uiAmountString": "0"},
                "extensions": [{"extension": "confidentialTransferAccount", "state": {"approved": True}}]}}}}}}
        else:
            res = {"result": {"slot": 1, "meta": {"err": None, "computeUnitsConsumed": 30000},
                              "transaction": {"signatures": ["a", "b"]}}}
        out = json.dumps(res).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(out)))
        self.end_headers()
        self.wfile.write(out)


# A stand-in for issue-e2e.sh: the real hooks from scripts/lib/chain.sh, and events that include
# everything the sanitiser must drop.
FAKE_SCRIPT = textwrap.dedent(r'''
    set -euo pipefail
    . "{root}/scripts/lib/chain.sh"
    pause_open
    ev run mode=normal
    pause first
    ev party who=issuer pubkey={pub}
    ev refused source=on_chain what=allocation sig={sig} err="Custom(24)"
    ev not_a_real_event x=1
    ev party who=investor pubkey="$RPC"
    ev party who=investor pubkey="<img src=x onerror=alert(1)>"
    ev party who=investor extra_key=should_be_dropped pubkey={pub}
    pause second
    ev done mode=normal
''')


class ServerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.rpc_port = free_port()
        cls.rpc_srv = http.server.ThreadingHTTPServer(("127.0.0.1", cls.rpc_port), FakeRPC)
        threading.Thread(target=cls.rpc_srv.serve_forever, daemon=True).start()
        cls.rpc = SECRET_RPC.format(port=cls.rpc_port)
        cls.tmp = tempfile.mkdtemp()
        cls.script = os.path.join(cls.tmp, "fake.sh")
        open(cls.script, "w").write(FAKE_SCRIPT.format(root=ROOT, pub=PUB, sig=SIG))
        server.SCRIPT = cls.script
        cls.port = free_port()
        cls.app = server.App(cls.rpc, cls.port)
        cls.srv = http.server.ThreadingHTTPServer(("127.0.0.1", cls.port), server.handler_for(cls.app))
        threading.Thread(target=cls.srv.serve_forever, daemon=True).start()

    @classmethod
    def tearDownClass(cls):
        if cls.app.run:
            cls.app.run.cleanup()
        cls.srv.shutdown()
        cls.rpc_srv.shutdown()

    def req(self, method, path, body=None, headers=None, host=None):
        c = http.client.HTTPConnection("127.0.0.1", self.port, timeout=10)
        h = {"Host": host or f"127.0.0.1:{self.port}"}
        h.update(headers or {})
        c.request(method, path, body=json.dumps(body) if body is not None else None, headers=h)
        r = c.getresponse()
        return r.status, r.read()

    def post(self, path, body, csrf=True, **kw):
        h = {"Content-Type": "application/json"}
        if csrf:
            h["X-Confide-CSRF"] = self.app.csrf
        return self.req("POST", path, body, h, **kw)

    def events(self, until, timeout=10):
        """Read the SSE stream until `until(ev)` is true; return every data event seen."""
        c = http.client.HTTPConnection("127.0.0.1", self.port, timeout=timeout)
        c.request("GET", "/events", headers={"Host": f"127.0.0.1:{self.port}"})
        r = c.getresponse()
        seen, t0 = [], time.time()
        while time.time() - t0 < timeout:
            line = r.fp.readline().decode()
            if line.startswith("data: "):
                ev = json.loads(line[6:])
                if "ev" not in ev:
                    continue
                seen.append(ev)
                if until(ev):
                    break
        c.close()
        return seen

    def test_1_foreign_host_and_missing_csrf_are_refused(self):
        self.assertEqual(self.req("GET", "/", host="evil.example:80")[0], 421)
        self.assertEqual(self.post("/run", {"mode": "normal"}, csrf=False)[0], 403)
        self.assertEqual(self.req("POST", "/run", {"mode": "normal"},
                                  {"Content-Type": "text/plain", "X-Confide-CSRF": self.app.csrf})[0], 415)

    def test_2_the_page_carries_the_token_and_a_strict_csp(self):
        c = http.client.HTTPConnection("127.0.0.1", self.port, timeout=10)
        c.request("GET", "/", headers={"Host": f"127.0.0.1:{self.port}"})
        r = c.getresponse()
        html = r.read().decode()
        self.assertIn(self.app.csrf, html)
        self.assertIn("default-src 'none'", r.getheader("Content-Security-Policy"))
        self.assertIsNone(r.getheader("Access-Control-Allow-Origin"))

    def test_3_run_advance_sanitise_proxy(self):
        if not (self.app.run and self.app.run.state == "running"):
            self.assertEqual(self.post("/run", {"mode": "normal"})[0], 200)
        # a second start while running is refused
        self.assertEqual(self.post("/run", {"mode": "short"})[0], 409)
        seen = self.events(lambda e: e.get("ev") == "waiting" and e.get("next") == "first")
        # advancing a step the script is not waiting on does nothing
        self.assertEqual(self.post("/advance", {"step": "second"})[0], 409)
        self.assertEqual(self.post("/advance", {"step": "first"})[0], 200)
        # ... and the same step twice is not queued
        self.assertEqual(self.post("/advance", {"step": "first"})[0], 409)
        seen = self.events(lambda e: e.get("ev") == "waiting" and e.get("next") == "second")
        names = [e["ev"] for e in seen]
        self.assertNotIn("not_a_real_event", names)
        blob = json.dumps(seen)
        self.assertNotIn("secret-key-abc123", blob, "the RPC endpoint reached the page")
        self.assertNotIn("<img", blob)
        self.assertNotIn("extra_key", blob)
        self.assertIn(SIG, blob)
        # the proxy reads only ids this run reported
        self.assertEqual(self.req("GET", "/chain/account/" + PUB)[0], 200)
        self.assertEqual(self.req("GET", "/chain/tx/" + SIG)[0], 200)
        other = "7" * 44
        self.assertEqual(self.req("GET", "/chain/account/" + other)[0], 404)
        self.assertEqual(self.req("GET", "/chain/account/not-base58!")[0], 404)
        body = self.req("GET", "/chain/account/" + PUB)[1].decode()
        self.assertNotIn("secret-key", body)
        self.assertEqual(set(FakeRPC.calls), {"getAccountInfo", "getTransaction"})
        self.assertEqual(self.post("/advance", {"step": "second"})[0], 200)
        seen = self.events(lambda e: e.get("ev") == "process" and e.get("state") != "running")
        self.assertIn({"ev": "process", "state": "completed"}, seen)


# ---- the script: a checkpoint only after its check ----

SCRIPT_SRC = open(os.path.join(ROOT, "scripts", "issue-e2e.sh"), encoding="utf-8").read()


def block(start, end):
    a = SCRIPT_SRC.index(start)
    return SCRIPT_SRC[a:SCRIPT_SRC.index(end, a)]


RUN_LOG = []


def run_block(src, stubs, extra=""):
    """Run one lifted block with stubbed chain calls; return (exit code, events written)."""
    d = tempfile.mkdtemp()
    evf = os.path.join(d, "ev.jsonl")
    open(evf, "w").close()
    prog = textwrap.dedent(f'''
        set -euo pipefail
        . "{ROOT}/scripts/lib/chain.sh"
        CONFIDE_EVENTS="{evf}"
        red=; dim=; off=; grn=; bold=; W="{d}"
        investor_X=ACCTX; MINT_X=MINTX; MINT_Y=MINTY; issuer_X=IX; investor_Y=IY; issuer_Y=IY2
        ALLOC=20000; PAY=3500000; DEC_X=8; GO_SIG=GOSIG
        cargo() {{ cat >/dev/null 2>&1 || true; echo tx; }}
        bh() {{ :; }}
        solana-keygen() {{ case "$*" in *issuer*) echo ISS;; *) echo INV;; esac; }}
        {extra}
        {stubs}
    ''') + src
    p = subprocess.run(["bash", "-c", prog], capture_output=True, text=True, timeout=60,
                       stdin=subprocess.DEVNULL)
    RUN_LOG.append(p.stderr)
    with open(evf) as f:
        evs = [json.loads(l) for l in f if l.strip()]
    return p.returncode, evs


GATE = block('read -r REFUSED_SIG err < <(landed', 'pause self_approve')
WRONG = block('read -r WRONG_SIG werr < <(landed', 'pause issuer_approves')
HALF = block('ISSUER=$(solana-keygen pubkey "$W/issuer.json")', 'pause investor_signs')
PUBLIC_1 = block('PUBS="$(pub "$issuer_X")', 'if [ "${ACT2:-1}" = 1 ]')
CHECK_OK = block('swap_look "$W/investor-X-keys.json" "$W/issuer-ctx.json" "$ALLOC" "$DEC_X" | tee "$W/check.out"\nev checked',
                 'build() {')


def names(evs):
    return [(e["ev"], e.get("what", e.get("source", ""))) for e in evs]


class ScriptCheckpointTests(unittest.TestCase):
    def test_gate_refusal_only_when_custom_24(self):
        ok, evs = run_block(GATE, 'landed(){ echo \'SIG {"InstructionError":[0,{"Custom":24}]}\'; }')
        self.assertEqual(ok, 0)
        self.assertIn(("refused", "allocation"), names(evs))
        for bad in ('landed(){ echo SIG null; }', 'landed(){ echo \'SIG {"InstructionError":[0,{"Custom":4}]}\'; }',
                    'landed(){ echo NOSEND x; }', 'landed(){ echo SIG; }'):
            code, evs = run_block(GATE, bad)
            self.assertNotEqual(code, 0, bad)
            self.assertNotIn("refused", [e["ev"] for e in evs], bad)

    def test_wrong_key_refusal_only_when_missing_signature_and_still_unapproved(self):
        good = 'landed(){ echo \'SIG {"InstructionError":[0,"MissingRequiredSignature"]}\'; }; approved(){ echo false; }'
        code, evs = run_block(WRONG, good)
        self.assertEqual(code, 0)
        self.assertIn(("refused", "self_approval"), names(evs))
        for bad in ('landed(){ echo SIG null; }; approved(){ echo true; }',
                    'landed(){ echo \'SIG {"InstructionError":[0,"MissingRequiredSignature"]}\'; }; approved(){ echo true; }',
                    'landed(){ echo \'SIG {"InstructionError":[0,{"Custom":4}]}\'; }; approved(){ echo false; }'):
            code, evs = run_block(WRONG, bad)
            self.assertNotEqual(code, 0, bad)
            self.assertNotIn("refused", [e["ev"] for e in evs], bad)

    def test_half_signed_refusal_only_for_a_signature_failure_on_one_of_two(self):
        sigfail = 'send(){ echo "ERR {\\"code\\": -32003, \\"message\\": \\"Transaction signature verification failure\\"}"; }'
        cargo_ok = 'cargo(){ if [ "$8" = sign ]; then cat >/dev/null; echo "  signed by ISS   1 of 2 signatures present" >&2; fi; echo tx; }'
        code, evs = run_block(HALF, sigfail, cargo_ok)
        self.assertEqual(code, 0)
        self.assertIn(("refused", "half_signed"), names(evs))
        for extra, stub in (
            ('cargo(){ if [ "$8" = sign ]; then cat >/dev/null; echo "  signed by ISS   1 of 3 signatures present" >&2; fi; echo tx; }', sigfail),
            (cargo_ok, 'send(){ echo "ERR {\\"code\\": -32002, \\"message\\": \\"sim failed\\"}"; }'),
            (cargo_ok, 'send(){ echo SIGACCEPTED; }; confirm(){ return 0; }'),
        ):
            code, evs = run_block(HALF, stub, extra)
            self.assertNotEqual(code, 0, stub)
            self.assertNotIn("refused", [e["ev"] for e in evs], stub)

    def test_public_checkpoint_only_when_every_balance_is_zero(self):
        code, evs = run_block(PUBLIC_1, 'pub(){ echo 0; }')
        self.assertEqual(code, 0)
        self.assertIn("public", [e["ev"] for e in evs])
        code, evs = run_block(PUBLIC_1, 'pub(){ case "$1" in IY) echo 5;; *) echo 0;; esac; }')
        self.assertNotEqual(code, 0)
        self.assertNotIn("public", [e["ev"] for e in evs])

    def test_checked_only_when_the_checker_passes(self):
        code, evs = run_block(CHECK_OK, 'swap_look(){ echo "  ✓ it will move 2000000000000 base units to you"; }')
        self.assertEqual(code, 0)
        c = [e for e in evs if e["ev"] == "checked"]
        self.assertEqual(c[0]["decrypted_base"], "2000000000000")
        code, evs = run_block(CHECK_OK, 'swap_look(){ echo "  ✗ short"; return 1; }')
        self.assertNotEqual(code, 0)
        self.assertNotIn("checked", [e["ev"] for e in evs])


class HookInertTests(unittest.TestCase):
    def test_hooks_do_nothing_without_the_variables(self):
        p = subprocess.run(["bash", "-c", f'set -euo pipefail; unset CONFIDE_EVENTS CONFIDE_PAUSE; '
                            f'. "{ROOT}/scripts/lib/chain.sh"; pause_open; ev x a=1; pause step; echo fine'],
                           capture_output=True, text=True, timeout=10)
        self.assertEqual(p.returncode, 0)
        self.assertEqual(p.stdout.strip(), "fine")


if __name__ == "__main__":
    unittest.main(verbosity=2)
```
