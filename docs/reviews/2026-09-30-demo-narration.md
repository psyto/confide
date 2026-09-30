The core story is defensible, but I would fix four public-facing ambiguities before judges see it.

1. Tighten narration

- Scene 4: “Solana rejects it” is broadly right, but it was rejected in RPC preflight and never entered a block. Say: “With only the issuer’s signature, RPC preflight rejects it for the missing signature; it never enters a block.”

- Scene 5 currently understates the privacy boundary. Replace it with something like: “The accounts, mint, and fact of these transactions are public. Their public balances are zero; confidential balances and transfer amounts are encrypted.” This matches the brief’s required distinction.

- Scene 6: “its key cannot read the amounts” is too loose and clashes with the local-demo fact that one machine holds all keys. For the holder-to-holder trade, say: “These mints have no mint-wide auditor key, so the issuer’s approval authority is not a reader of this trade’s amounts.” Also add “They agreed these terms off chain” to avoid any hint of matching or price discovery.

- Scene 7: “Confide decrypts the investor’s leg” makes Confide sound custodial. The code uses the investor’s confidential-account key. Say: “Before any signature, the investor’s Confide client decrypts the amount addressed to the investor, finds two thousand where twenty thousand was agreed, and refuses.”

“Configured like every tokenized stock we measured” is supported by the stated 1,992-mint measurement, but is unnecessarily broad when spoken over both a stock and cash mint. Prefer: “configured with the two settings we found on all 1,992 measured tokenized-equity mints: issuer approval required and no mint-wide auditor key.”

“Only the issuer’s key opens this gate” is true for this demo, but more exact as “Only the mint’s configured confidential-transfer authority—the issuer key in this demo—can approve this account.”

2. Attribution

Most labels follow the intended boundary: Confide builds proofs, checks and pins locally, binds the second signer’s transaction, and assembles; Token-2022 applies approval and transfer rules; Solana/RPC catches the missing signature.

Two rows should change:

- `public balances read back` is credited to `TOKEN-2022` in [ops.js](/Users/hiroyusai/src/confide/app/static/ops.js:237). That is an observer/RPC read of chain state, not an action performed by Token-2022. Use `SOLANA (RPC)` or make the column “evidence from” rather than “done by.”

- Both settled rows say `CONFIDE + TOKEN-2022` ([ops.js](/Users/hiroyusai/src/confide/app/static/ops.js:223), [ops.js](/Users/hiroyusai/src/confide/app/static/ops.js:227)). If “done by” denotes the whole claimed result, this undercredits Solana: Solana supplies single-transaction atomicity. Best label: `CONFIDE (assembled) + TOKEN-2022 (transfers) + SOLANA (atomic transaction)`. The current wording is defensible only if the column is explicitly about non-runtime workstream ownership.

The proof row is acceptable because it says `VERIFIED ON CHAIN` while crediting Confide for building the proofs; I would not change it.

3. “Confide in this run” ticks

They are not premature. Each is added after its checkpoint:

- proof tick after both proof legs complete;
- normal and short pre-sign ticks after the comparison/verdict;
- pin ticks after the local pin is written;
- holder-2 binding tick after the full transaction-message verification, before its signature;
- DvP ticks only after confirmed settlement.

This is especially sound for the short control: the refusal event is emitted only on the specific verified-mismatch exit path, not on any failed check.

4. Brief-boundary gaps

The screen itself contains useful qualifiers—local/devnet/all keys on one machine, positions shown together only because of that, and “agreed off chain.” But the narration should carry the important ones because small UI text is easy to miss:

- terms are agreed off chain; Confide is not a matching venue;
- accounts, mint, and transaction participation remain public;
- the displayed multi-party positions are a single-presenter local-demo view, not separate wallets;
- “no auditor key” means no mint-wide transfer-auditor key, not selective disclosure.

The existing final “no real issuer has used it” is good and consistent with the brief.

5. Fast-forward

Badge plus manifest is auditable, but not sufficient as a judge-facing disclosure: the status record notes some badges appear for about one second. Add one short opening title card or one spoken clause:

> “Devnet waits are fast-forwarded; each badge shows the real elapsed time.”

You do not need to narrate every fast-forward segment. The manifest’s “nothing removed or reordered” statement is strong supporting evidence, but should not be the only disclosure a video viewer receives.