# Review request — two more negative controls in issue-e2e.sh, 2026-09-30

Brief `docs/cwf-2026/CLAUDE-CODE-BRIEF.md` §3 P0 asks for negative controls for: unapproved account,
**wrong approval authority**, incorrect amount/leg, **missing second signature**, and a public
observer seeing zero public balance. Before today the script had the first, the third (`SHORT=`) and
the fifth. This change adds the two in bold to the default run of `scripts/issue-e2e.sh`.
Everything is in the working tree, uncommitted; the full diff is at the end.

## What was added

1. **The investor sends ApproveAccount for their own account** (after the Custom(24) refusal, before
   the issuer approves). Sent with preflight off, landed error read back, expected
   `MissingRequiredSignature`. The expectation comes from
   `~/.cargo/registry/src/*/spl-token-2022-8.0.1/src/extension/confidential_transfer/processor.rs`
   `process_approve_account` (line ~321): approves only if `authority_info.is_signer && key == ct mint
   authority`, else `ProgramError::MissingRequiredSignature`. Then the account's `approved` flag is
   read from jsonParsed and must be false.
2. **After approval, the issuer signs the allocation alone** (`swap-tx build` from pubkeys, then
   `swap-tx sign` with the issuer key only → "1 of 2 signatures present"). Sent with preflight ON;
   expected the RPC's signature-verification error (-32003). The script states this refusal is NOT
   anchored on chain, because a transaction missing a required signature never enters a block.
3. The inline "send with skipPreflight, poll getTransaction" code was factored into `landed()` and is
   now used by both the Custom(24) refusal and control 1. The landed error JSON now has spaces
   stripped. `approved()` reads the flag from the chain.

## What was verified, and what was not

- **Not run on devnet.** No RPC endpoint in this session. Nothing here has touched a chain.
- `bash -n` passes; `cargo build` of swap-tx / seizure-client passes (no Rust change).
- `swap-tx build | swap-tx sign - issuer.json` on synthetic contexts prints "1 of 2 signatures present".
- The three case blocks (gate, wrong key, half-signed) were extracted and run with stubbed `landed`,
  `approved`, `send`, `confirm`: expected refusal → 0; approval succeeded / wrong error / never
  landed / could not send / refused-but-reads-approved → 1; sigverify refusal → 0; other preflight
  error → 1; half-signed accepted → 1. Custom(24) block: Custom(24) → 0; null / other / NOSEND /
  not landed → 1.
- `swap-pin-check.sh` and `wire-check.sh` green. `docs-consistency.sh` has the same 2 pre-existing
  reds (a re-paste and the GitHub About), both founder-only.

## Questions — please be adversarial

1. Is the `MissingRequiredSignature` expectation right for the Token-2022 program **deployed on
   devnet today**, not just crate 8.0.1? Could a newer program return a different error (e.g.
   OwnerMismatch / InvalidAuthority) such that the script fails on a correct refusal — or, worse,
   could the match accept a refusal for a reason other than "wrong key"? Note the investor is also
   the fee payer and a signer of that transaction.
2. Is it true that with preflight ON the RPC returns -32003 for a missing required signature, rather
   than e.g. forwarding it or returning a simulation error? Is the `ERR*[Ss]ignature*` fallback pattern
   too loose — can it match a failure that is not "a required signature is missing"?
3. Does control 2 actually isolate "missing second signature"? The half-signed transaction is built
   via `swap-tx build` (unsigned path) while the successful one uses the both-keys path. Could the
   two differ in some way (payer, signer order, account order) that makes the refusal about
   something else?
4. Any regression in the refactor of the Custom(24) path (`read -r SIG err < <(landed ...)`, the
   NOSEND branch, the space-stripping)? Any `set -euo pipefail` trap — e.g. a failure inside a
   process substitution that is silently swallowed and turns into a false pass?
5. Does any comment or printed line overclaim — or underclaim — what is shown? In particular,
   "the account still reads approved: false" and "never entered a block, so there is nothing on
   chain to cite".
6. Anything the brief asked for under these two controls that this still does not do?

## The diff

```diff
diff --git a/scripts/issue-e2e.sh b/scripts/issue-e2e.sh
index 85dd9d8..2d612f8 100755
--- a/scripts/issue-e2e.sh
+++ b/scripts/issue-e2e.sh
@@ -31,6 +31,13 @@
 # less than agreed. Until 2026-09-30 this repository answered that with a printed number and a
 # sentence telling the reader to compare it themselves, and then signed.
 #
+# TWO MORE, BOTH IN THE DEFAULT RUN, because the gate refusal alone leaves two questions open.
+#   - Can somebody else open the gate? The investor sends ApproveAccount for their own account and
+#     is refused on chain (MissingRequiredSignature, anchored), and the account still reads unapproved.
+#   - Does an open gate let one party settle alone? After approval the issuer signs the allocation
+#     by itself; the network refuses it at signature verification. That one never lands, so it has no
+#     signature to cite, and the script says so rather than implying one.
+#
 # AND THE AUDITOR SLOT STAYS EMPTY, exactly as it is on all 1,992. That is not a shortcut: in
 # primary issuance the issuer IS the sender, so they can already read what they sent and need no
 # auditor key to see it. The empty slot blocks the SECONDARY market, not this one — which is why
@@ -165,32 +172,49 @@ build() {
     >"$W/issue.b64" 2>"$W/issue.size"
 }
 
-echo
-echo "  ${bold}--- the allocation, sent while the account is unapproved ---${off}"
-build
-grep -a "one transaction" "$W/issue.size" || true
-# THE POINT OF THE WHOLE SCRIPT, and it is sent with preflight OFF on purpose. With preflight on,
-# the RPC node simulates, returns the error and nothing lands — the refusal is then reproducible but
-# not anchored, and "run it yourself" is weaker than a signature anybody can look up. Skipping
-# preflight costs one fee and puts the refused transaction on chain with its error attached.
-REFUSED_SIG=$(rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"sendTransaction\",\"params\":[\"$(cat "$W/issue.b64")\",{\"encoding\":\"base64\",\"skipPreflight\":true}]}" \
-  | python3 -c "
+# landed <b64>  ->  "<signature> <landed error as JSON>"
+# Sent with preflight OFF on purpose. With preflight on, the RPC node simulates, returns the error
+# and nothing lands — the refusal is then reproducible but not anchored, and "run it yourself" is
+# weaker than a signature anybody can look up. Skipping preflight costs one fee and puts the refused
+# transaction on chain with its error attached. The error is READ BACK from the landed transaction
+# rather than trusted from the send: one that fails in preflight and one that fails on chain are
+# different artifacts, and only the second can be cited.
+landed() {
+  local sig err=""
+  sig=$(rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"sendTransaction\",\"params\":[\"$1\",{\"encoding\":\"base64\",\"skipPreflight\":true}]}" \
+    | python3 -c "
 import sys, json
 r = json.load(sys.stdin)
-print('ERR ' + json.dumps(r['error'])[:300] if 'error' in r else r['result'])")
-case "$REFUSED_SIG" in ERR*) echo "    could not even send it: $REFUSED_SIG" >&2; exit 1;; esac
-# Read the LANDED error back rather than trusting the send. A transaction that fails in preflight
-# and one that fails on chain are different artifacts and only the second can be cited.
-err=""
-for _ in $(seq 1 40); do
-  err=$(rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getTransaction\",\"params\":[\"$REFUSED_SIG\",{\"maxSupportedTransactionVersion\":0}]}" \
-    | python3 -c "
+print('NOSEND ' + json.dumps(r['error']).replace(' ', '')[:300] if 'error' in r else r['result'])")
+  case "$sig" in NOSEND*) echo "$sig"; return 0;; esac
+  for _ in $(seq 1 40); do
+    err=$(rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getTransaction\",\"params\":[\"$sig\",{\"maxSupportedTransactionVersion\":0}]}" \
+      | python3 -c "
 import sys, json
 r = json.load(sys.stdin).get('result')
-print('' if not r else json.dumps(r['meta']['err']))")
-  [ -n "$err" ] && break
-  sleep 2
-done
+print('' if not r else json.dumps(r['meta']['err']).replace(' ', ''))")
+    [ -n "$err" ] && break
+    sleep 2
+  done
+  echo "$sig ${err:-}"
+}
+# approved <account>  ->  true | false, read from the chain rather than inferred from what was sent
+approved() {
+  rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getAccountInfo\",\"params\":[\"$1\",{\"encoding\":\"jsonParsed\",\"commitment\":\"confirmed\"}]}" \
+  | python3 -c "
+import sys,json
+i=json.load(sys.stdin)['result']['value']['data']['parsed']['info']
+s=next(e['state'] for e in i['extensions'] if e['extension']=='confidentialTransferAccount')
+print('true' if s['approved'] else 'false')"
+}
+
+echo
+echo "  ${bold}--- the allocation, sent while the account is unapproved ---${off}"
+build
+grep -a "one transaction" "$W/issue.size" || true
+# THE POINT OF THE WHOLE SCRIPT. Anchored, not simulated -- see `landed`.
+read -r REFUSED_SIG err < <(landed "$(cat "$W/issue.b64")")
+[ "$REFUSED_SIG" = NOSEND ] && { echo "    could not even send it: $err" >&2; exit 1; }
 # json.dumps puts a space after the colon: {"InstructionError": [0, {"Custom": 24}]}. Matching
 # without it reported the right refusal as the wrong one, which is worse than not matching at all.
 case "$err" in
@@ -208,13 +232,78 @@ case "$err" in
     echo "    refused, but not for the reason this demonstrates: $err" >&2; exit 1;;
 esac
 
+echo
+echo "  ${bold}--- the investor tries to approve their own account ---${off}"
+# THE GATE HAS A KEYHOLE, NOT JUST A DOOR. The refusal above shows an unapproved account cannot
+# receive; it does not show that only the issuer can change that. If any signer could approve, the
+# gate would be a formality the holder clears themselves. So the investor -- who owns the account,
+# pays the fee and signs -- sends the same one-instruction ApproveAccount the issuer is about to send.
+#
+# Token-2022 approves only when the signer IS the mint's confidential-transfer authority, and
+# otherwise returns MissingRequiredSignature (spl-token-2022 8.0.1,
+# extension/confidential_transfer/processor.rs, process_approve_account). The name reads oddly for
+# "wrong key", and it is the program's own word: the investor's signature is present, the ISSUER's
+# is what is missing.
+read -r WRONG_SIG werr < <(landed "$(cargo run --quiet -p confide-ct --bin seizure-client -- approve \
+  "$W/investor.json" "$investor_X" "$MINT_X" "$(bh)")")
+[ "$WRONG_SIG" = NOSEND ] && { echo "    could not even send it: $werr" >&2; exit 1; }
+case "$werr" in
+  *MissingRequiredSignature*)
+    printf '    %sREFUSED on chain — MissingRequiredSignature: the signer is not the mint'"'"'s approval authority%s\n' "$red" "$off"
+    printf '    %s%s%s\n' "$dim" "$WRONG_SIG" "$off";;
+  null)
+    echo "    THE INVESTOR APPROVED THEIR OWN ACCOUNT. The gate is not the issuer's, and that is" >&2
+    echo "    the finding, not this script." >&2
+    exit 1;;
+  "") echo "    the wrong-key approval never landed — nothing to cite" >&2; exit 1;;
+  *)  echo "    refused, but not for the reason this demonstrates: $werr" >&2; exit 1;;
+esac
+# And the account is still shut. Read from the chain, not concluded from the error.
+[ "$(approved "$investor_X")" = false ] || { echo "    the account reads approved after a refused approval" >&2; exit 1; }
+printf '    %sthe account still reads approved: false%s\n' "$dim" "$off"
+
 echo
 echo "  ${bold}--- the issuer signs for the account. One instruction ---${off}"
 go "the issuer approves it" "$(cargo run --quiet -p confide-ct --bin seizure-client -- approve \
   "$W/issuer.json" "$investor_X" "$MINT_X" "$(bh)")"
 
+[ "$(approved "$investor_X")" = true ] || { echo "    the approval confirmed but the account does not read approved" >&2; exit 1; }
+
+echo
+echo "  ${bold}--- the issuer signs the allocation alone ---${off}"
+# ONE SIGNATURE OF TWO. The gate is open now, the proofs are valid and the amounts are right, so the
+# only thing this transaction lacks is the investor's signature on their own payment leg. It is
+# assembled from public keys (`swap-tx build`, the same path the bilateral protocol uses) and signed
+# by the issuer only.
+#
+# This refusal CANNOT be anchored the way the two above are, and saying otherwise would be false: a
+# transaction missing a required signature never enters a block, so there is no signature of it to
+# look up. It is sent with preflight ON and the RPC node's signature verification refuses it. If it
+# is ever accepted, the script waits to see whether it landed and fails loudly either way.
+cargo run --quiet -p confide-ct --bin swap-tx -- build "$(solana-keygen pubkey "$W/issuer.json")" "$(bh)" \
+  "$(solana-keygen pubkey "$W/issuer.json")"   "$W/issuer-ctx.json"   "$issuer_X"   "$investor_X" "$MINT_X" \
+  "$(solana-keygen pubkey "$W/investor.json")" "$W/investor-ctx.json" "$investor_Y" "$issuer_Y"   "$MINT_Y" \
+  2>/dev/null | cargo run --quiet -p confide-ct --bin swap-tx -- sign - "$W/issuer.json" \
+  >"$W/half.b64" 2>"$W/half.err"
+grep -aoE '[0-9]+ of [0-9]+ signatures present' "$W/half.err" | sed 's/^/    /' || true
+half=$(send "$(cat "$W/half.b64")")
+case "$half" in
+  ERR*-32003*|ERR*[Ss]ignature*)
+    printf '    %sREFUSED by the network — %s%s\n' "$red" "$(printf '%s' "$half" | python3 -c "
+import sys, json
+print(json.loads(sys.stdin.read()[4:]).get('message', '?'))" 2>/dev/null || echo "$half")" "$off"
+    printf '    %snever entered a block, so there is nothing on chain to cite; the next step is the same\n' "$dim"
+    printf '    transaction with both signatures%s\n' "$off";;
+  ERR*)
+    echo "    refused, but not for the reason this demonstrates: $half" >&2; exit 1;;
+  *)
+    echo "    A HALF-SIGNED ALLOCATION WAS ACCEPTED by the RPC: $half" >&2
+    confirm "$half" >&2 && echo "    AND IT SETTLED. That is the finding, not this script." >&2
+    exit 1;;
+esac
+
 echo
-echo "  ${bold}--- the same allocation, rebuilt against a fresh blockhash, sent again ---${off}"
+echo "  ${bold}--- the same allocation, both signatures, a fresh blockhash ---${off}"
 build
 go "the allocation" "$(cat "$W/issue.b64")"
 
@@ -235,7 +324,8 @@ pub() { local d a p o; read -r d a p o < <(ct "$1"); echo "$p"; }
 printf '    %spublic balances: issuer stock %s, investor stock %s, investor cash %s, issuer cash %s%s\n' \
   "$dim" "$(pub "$issuer_X")" "$(pub "$investor_X")" "$(pub "$investor_Y")" "$(pub "$issuer_Y")" "$off"
 echo
-echo "  ${grn}${bold}An allocation was refused, the issuer signed, and the same allocation settled."
+echo "  ${grn}${bold}An allocation was refused, the investor could not approve themselves, a half-signed"
+echo "  allocation was refused, the issuer signed, and the same allocation settled with both signatures."
 echo "  The auditor slot was empty throughout — as it is on all 1,992 — because in primary issuance"
 echo "  the issuer is the sender and needs no key to read what they sent.${off}"
 echo
```
