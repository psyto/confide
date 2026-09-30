Verdict: the repositioning is right, but I would not treat `STORY.md` as claim-ready or start the app unchanged. There are two material evidence-scope errors and one brief conflict.

- The **518,744 / two / zero** result is a scan of six named, non-empty mints—two per issuer—not of the 1,992-mint catalogue. The script calls it a sample and names its selection rule. It was measured 2026-09-28. Therefore “Nobody is using it,” “the gate has never been opened by anyone,” and “no incumbent / first mover” are unsupported market-wide claims. Scope it explicitly. [usage-scan.sh](/Users/hiroyusai/src/confide/scripts/usage-scan.sh:4) [STORY.md](/Users/hiroyusai/src/confide/docs/cwf-2026/STORY.md:28)

- “A confidential account needs the issuer’s signature” is contradicted by the next flow step: an investor can configure one without permission. What needs approval is an account’s ability to receive/use confidential transfers. This is not wording pedantry; the two observed accounts are configured but unapproved. [STORY.md](/Users/hiroyusai/src/confide/docs/cwf-2026/STORY.md:48) [STORY.md](/Users/hiroyusai/src/confide/docs/cwf-2026/STORY.md:105)

- “Any token account’s balance … [reveals] the size of a holding” is too universal: a Confidential Balance account publicly reads as zero while holding a confidential balance. Say that ordinary public-balance positions expose the holding, then show Confidential Balances as the exception. [ONCHAIN.md](/Users/hiroyusai/src/confide/docs/ONCHAIN.md:139)

- The auditor description is mostly corrected and matches the brief: it can decrypt transfer amounts while configured, not a complete balance. But “with it empty, no holder can show anything to anyone” overreaches. Say: “Token-2022 provides no mint-configured third-party disclosure path in between.” A holder can voluntarily disclose information; that is not what the empty auditor field proves. [STORY.md](/Users/hiroyusai/src/confide/docs/cwf-2026/STORY.md:51)

- §3’s public/private boundary is aligned with the brief. Make it explicitly “confidential transfer amounts and confidential balances,” and retain identities, mint, and transaction participation as public. This avoids implying that every amount relating to the mint—for example supply—is hidden. [CLAUDE-CODE-BRIEF.md](/Users/hiroyusai/src/confide/docs/cwf-2026/CLAUDE-CODE-BRIEF.md:44)

- §4 is too strong about devnet status. 09-30(5) ran the earlier successful issuance path and `SHORT`; 09-30(7) added the wrong-authority and half-signature checks, then explicitly says the integrated current script is unrun on devnet. Say that steps 1–4, 6, 8–9 have prior devnet evidence, while the current integrated default path awaits one devnet run. [STATUS.md](/Users/hiroyusai/src/confide/STATUS.md:1219) [STATUS.md](/Users/hiroyusai/src/confide/STATUS.md:1308)

Other factual cleanup: §10 says “104 tests,” while README says 70 + 44 = 114. Do not hand-maintain this count. [STORY.md](/Users/hiroyusai/src/confide/docs/cwf-2026/STORY.md:253) [README.md](/Users/hiroyusai/src/confide/README.md:387) Also, “issuer plumbing they already shipped” is not established by a mint extension and authority field; `ApproveAccount` exists, but an issuer-operated workflow is exactly what remains untested.

The order serves judgments 1, 2, 4, and 5 well. It can serve judgment 3 only if the screen makes the issuance settlement visibly DvP: 20,000 shares versus $3.5m, both legs in one transaction, both signatures, then the observer’s four zero public balances.

There is a direct unresolved conflict: the brief requires the reviewer to see a later two-approved-holder bilateral settlement, whereas `DEMO-APP.md` excludes a holder-to-holder swap screen. “Opens on issuance” does not itself supersede that requirement. Either obtain and record an explicit founder override, or include a compact second act showing the already-run secondary DvP. [CLAUDE-CODE-BRIEF.md](/Users/hiroyusai/src/confide/docs/cwf-2026/CLAUDE-CODE-BRIEF.md:58) [DEMO-APP.md](/Users/hiroyusai/src/confide/docs/cwf-2026/DEMO-APP.md:73)

The buyer wording is correct as a hypothesis, not an underclaim. The later brief sets a first-buyer target under “Document, but do not claim solved”; it is not evidence of willingness to buy. THE-PINCER also explicitly labels issuer benefit untested. I would call it the “working first-buyer hypothesis” to distinguish founder prioritization from market validation. [CLAUDE-CODE-BRIEF.md](/Users/hiroyusai/src/confide/docs/cwf-2026/CLAUDE-CODE-BRIEF.md:108) [THE-PINCER.md](/Users/hiroyusai/src/confide/docs/cwf-2026/THE-PINCER.md:54)

For the app, the design is achievable if “does not implement anything” is narrowed to “does not implement a second proof, transaction, or policy engine.” It necessarily implements orchestration, authorization, UI state, SSE, and a read proxy.

The authoritative model should be:

- The script emits a typed checkpoint only after it has performed and checked the relevant operation.
- An expected refusal is displayed only from that explicit script-emitted checkpoint, with its source (`on_chain`, `rpc_preflight`, or `pre_sign_check`) and evidence.
- Child exit status means only `completed` or `unexpected script failure`; it cannot identify the expected refusals because the normal run and the intentional `SHORT` refusal both exit zero.
- The server must never infer “refused” from a timeout, an absent event, raw terminal text, or a missing settlement event.

The proposed transcript comparison is necessary but insufficient. Equal human-readable output does not prove equivalent transactions, event ordering, exit semantics, or that the event was emitted after the actual assertion. Add a deterministic test harness that records invoked commands/transaction semantics with and without instrumentation, asserts the exact event sequence, and deliberately breaks each source assertion to prove the success/refusal event is absent or the run fails.

The biggest screen-level privacy trap is SSE: the proposed event includes `agreed` and `decrypted`, but the observer pane lives in the same browser client. Hidden UI is not access control; the observer can inspect the event stream. Either use separate role sessions with server-side event projection, or label the three panes honestly as a single-presenter visualization, not three security-isolated roles. I would rename “investor wallet” to “investor view,” since the server holds every key and executes every action.

For local-server security, add these requirements before implementation:

- Create a per-run, server-chosen directory and FIFO with `0700` directory / `0600` files, `umask 077`, no client-supplied paths, no symlinks, cleanup on exit, and a process-group kill/timeout path.
- Pass a fixed `SHORT=2000`; never accept browser-controlled environment variables, shell fragments, paths, RPC methods, addresses, or FIFO contents as commands.
- The FIFO should be only an advance token. The server maintains the expected next checkpoint; it must prevent queued/multiple advances and report a timeout as “paused/failed,” never as a financial outcome.
- Keep the RPC credential out of events, logs, errors, HTML, screenshots, and inherited diagnostic output. Do not stream raw child stderr or the work-directory path to the page.
- Make the read proxy a server-side per-run allowlist of exact event-derived public keys/signatures, fixed RPC methods and parameter shapes, response filtering, size/rate limits, and no arbitrary URL or JSON-RPC forwarding.
- `127.0.0.1` limits network exposure; it is not an authentication boundary against other local processes or hostile webpages. Require same-origin POST controls with CSRF protection, Host validation, no CORS, CSP, and no third-party scripts. Treat same-user compromise as out of scope rather than implying the local server protects against it.

The app itself does not conflict with the refused list if it remains devnet-only and does not add pricing, matching, a public venue, lending lifecycle, or mainnet deployment. The main risk is narrative drift: the stablecoin breadth and Kamino/loan futures are useful appendices, but they should not displace the issuer-operated allocation—the brief’s expressly chosen first integration.