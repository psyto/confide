## Verdict: do not ship the bilateral pinning yet

Two bypasses remain.

1. **A counterparty can remove or change the id and force the successful “NOT PINNED” path.** In [`swap_look_pinned`](/Users/hiroyusai/src/confide/scripts/lib/swap.sh:63), a missing/unreadable pin falls through to comparing against `echoed`, which came from the returned JSON. So an attacker can return `id: "-"`, lower `offerer.want.units`, and provide a context for that lower amount. Step 3 or 4 then compares attacker-controlled values and signs. The red warning recreates the original “notice the number” control; it is not a refusal.

2. **The offerer’s outgoing amount is not pinned.** The pin contains only `want` ([`swap_pin_terms`](/Users/hiroyusai/src/confide/scripts/lib/swap.sh:37)). But step 3 takes `O_GIVE_UNITS` from the returned `accept.json` and uses it to build the offerer’s leg ([`swap-settle.sh`](/Users/hiroyusai/src/confide/scripts/swap-settle.sh:24), [`swap-settle.sh`](/Users/hiroyusai/src/confide/scripts/swap-settle.sh:50)). An acceptor can change `offerer.give.units` from 100 to 1,000 while sending the correctly pinned payment. The received-leg check passes; the offerer signs a 1,000-unit delivery.

Pin the complete canonical terms—both legs’ mint, account, and units, parties, and id—and reject any mismatch. For newly created offers, missing, malformed, unknown, or unreadable pins must be hard failures. Compatibility with legacy/different-machine offers needs an explicit unsafe override, not a successful default.

## Answers to the specific questions

- **`read -r` additions:** the ordinary field counts are correct, and `-` prevents the absent-id shift. But the transport is still whitespace-delimited JSON values. A malicious value containing whitespace silently changes field parsing; no schema validation occurs before use. Emit a structured format or NUL-delimited fields, then validate exact field count, id (`[0-9a-f]{16}`), base58 addresses, and bounded integer amounts at the parser boundary.

- **`$W`:** terms ids have negligible accidental 64-bit collision risk, but the workdir is not offer-isolated. `accept-ctx.json`, `their-ctx.json`, `settle-ctx.json`, `half.b64`, and `unsigned.b64` are all shared fixed names. Concurrent or resumed offers overwrite one another. Make an offer/session directory keyed by the locally selected id, not just a keyed terms file. Also, `chmod 700 "$W"` errors are suppressed and pin writes are non-atomic.

- **Test-count check:** this is the right change. `_submission/full.md`’s SHA-256 currently matches its entry in [`pasted.json`](/Users/hiroyusai/src/confide/_submission/pasted.json:24), and the later submitted-field check verifies it ([`docs-consistency.sh`](/Users/hiroyusai/src/confide/scripts/docs-consistency.sh:692)). Allowing a frozen record to understate while rejecting overstatement is sound; it is not self-serving weakening.

- **No devnet run:** offline tests are enough to justify an implementation patch only after the two bypasses above are fixed. They are not enough to claim the `SHORT` negative control or bilateral wiring works live. A devnet run should be a release/demo gate, especially because the risk is exactly message parsing, context persistence, and transaction wiring.

- **Synthetic Rust context:** fair for `compare()` and high/low recombination, but not for the Token-2022 byte layout: the fixture writes the reader’s own offsets. Add an SDK-built/serialized proof-context fixture or an integration test from the actual proof builder. The old devnet record establishes historical compatibility, not regression coverage.

## Other verified corrections

- The issuance script does implement the brief’s technical 1→7 flow in order. Its “same transaction” wording is not literal: it calls `build` again after approval, so the fresh blockhash makes it a different transaction byte sequence ([`issue-e2e.sh`](/Users/hiroyusai/src/confide/scripts/issue-e2e.sh:152), [`issue-e2e.sh`](/Users/hiroyusai/src/confide/scripts/issue-e2e.sh:208)). In `SHORT` mode, it also says “the gate is open” before the approval occurs ([line 131](/Users/hiroyusai/src/confide/scripts/issue-e2e.sh:131)).

- “All four callers ignored the result” is imprecise. They honored nonzero exits through `set -e`; the defect was that a valid-but-wrong amount exited zero, so they ignored a display rather than an exit result.

- The shell checker has **15** checks, not 14.

- The README still documents the two-argument manual invocation and its old display-only output ([README.md:156](/Users/hiroyusai/src/confide/README.md:156)). That is a live safety surface that now teaches a non-comparison invocation.

- The Kamino repair introduces an unrelated destructive bug: `KLEND_DIR` is caller-controlled, and an unreadable/non-git directory is recursively deleted ([`kamino-verdict.sh:29`](/Users/hiroyusai/src/confide/scripts/kamino-verdict.sh:29)). `KLEND_DIR=/some/valuable/path` is enough. Never delete an override path; only replace a validated default cache path, or clone into a fresh temporary directory.

I verified the diff is whitespace-clean and all affected shell files pass `bash -n`. I could not independently rerun the Rust/shell suites or devnet controls in this read-only review environment.