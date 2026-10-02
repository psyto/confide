# Review — "who reads the amount" in the demo, and the pitch script, 2026-10-02

Codex (`codex exec -s read-only`), payload [`payloads/2026-10-02-comparison-and-pitch.md`](payloads/2026-10-02-comparison-and-pitch.md).
Verbatim below. **Each finding was checked against the files before it was taken.**

| finding | taken? |
|---|---|
| "exchange" → "centralized exchange"; "which holds the assets" is not sourced in COMPARABLES | yes — both |
| "dark pool — its operator or relayer" conflates Renegade and a US ATS | yes — "Renegade dark pool — its relayer" |
| "the same trade elsewhere" implies those venues could execute an issuer-gated trade | yes — "who would read this trade's amount elsewhere" |
| "only the two parties" needs the no-auditor scope, and P1 is run-scoped | yes — panel: "Confide, no auditor key … public balance 0 in this run"; narration: "every balance here", "the two parties' keys" |
| "public DEX swap", not every DEX design | yes |
| the ten-second line is too broad | yes — the pitch says "generally"; the evidence row gives the rule's scope. Notice 26-07's overnight exception was not re-fetched here; the narrower wording holds either way |
| pitch: approval, "never how much", "where I counted" over-scoped | yes — "each account before it can hold privately", "on mints with no auditor key", "across the six mints I counted" |
| PITCH.md contradicts itself about where the comparison lives | yes |
| static research in a panel whose rule is "nothing the run did not produce" | yes — the card is labelled "sourced comparison — not a run result"; the rule in ops.js now names the one exception |
| the server test does not prove `advanced` precedes the next `waiting` | yes — asserted between the two |
| no page-level replay test | yes — `video/test-ops-replay.mjs`, both views; removing either handler fails it |
| scene 1 applied the measured settings to the cash mirror too | yes — "the stock mint carries" |
| scene 6 lost "mint-wide" | yes — restored |
| scene 4 "RPC preflight" less precise | not changed: "the RPC rejects it; it never enters a block" is true, and the window has no room |

---

Verdict: the replay fix addresses the recorded failure, but I would tighten the comparison claims before publishing.

1. Comparison / pitch claims

- “Exchange” must be “centralized exchange.” A DEX is also an exchange. “Which holds the assets” is not directly sourced in `COMPARABLES.md`; either cite a CEX custody source or drop that clause.
- “Dark pool — its operator or relayer” conflates different systems. For Renegade, the primary source supports “its relayer sees plaintext orders.” For a US ATS, the relevant public reader is the tape. Name the example: `Renegade dark pool — its relayer`, rather than making a generic dark-pool claim.
- “The same trade elsewhere” implies these venues could execute this issuer-gated trade. Safer heading: “WHO WOULD READ THIS TRADE’S AMOUNT ELSEWHERE?”
- “Only the two parties can” needs the configuration qualifier and clashes slightly with the local-demo disclosure that one machine holds all keys. Prefer: “On these no-auditor mints, the amounts are encrypted to the counterparties’ keys.” Also say “in this run, every public balance reads zero”; P1 is run-scoped.
- The DEX row should say `ordinary public Solana DEX swap — everyone`, since “everyone” is not true of every conceivable DEX design.

The ten-second pitch line is too broad. FINRA’s rule covers reportable OTC/NMS-stock trades during TRF operating hours, not “US markets” generally. It has excluded transaction classes and, since March 2026, a limited overnight exception; FINRA also acknowledges some manual reports can miss ten seconds. There is not a special large-block aggregation exemption—individual executions may not be aggregated. [FINRA Rule 6380A](https://www.finra.org/rules-guidance/rulebooks/finra-rules/6380a), [FINRA Regulatory Notice 26-07](https://www.finra.org/sites/default/files/2026-03/Regulation-Notice-26-07.pdf)

Use:

> For reportable off-exchange NMS-stock trades while FINRA’s reporting facility is open, the last-sale report—including shares and price—is due as soon as practicable, no later than ten seconds after execution.

That is supported by FINRA’s own ATS/OTC explanation. [FINRA trade-reporting notice](https://www.finra.org/sites/default/files/notice_doc_file_ref/Trade-Reporting-Notice-120516.pdf)

Other pitch-line scope fixes:

- “The issuer approves exactly which accounts may hold privately” → “The mint’s approval authority approves newly configured accounts before they can receive confidential transfers.”
- “Everyone else sees … never how much” → scope it to the demonstrated no-auditor configuration.
- “Where I counted, nobody has been approved” → “Across the six mints I counted, I found no approved confidential accounts.”
- Founder identity/background placeholders remain correctly unverified.
- `PITCH.md` says “The comparison lives here, not in the demo,” then says the demo contains it. That is internally contradictory.

2. Is it still a live-product demo?

Yes. It is product UI, appears only after an actual public-chain read-back, and the displayed quantity/cash values come from run checkpoints. It does not become a slide deck merely because it contains static explanatory copy.

The page’s “no price, instrument or market data … not produced by the run” rule is not literally breached by venue-category labels. But the static comparative assertions are external research, not run output. Make that distinction explicit—e.g. label the card “SOURCED COMPARISON — not a run result”—or narrow the rule to *displayed trade values and outcomes*. The plain-text `Sources: docs/...` is useful for an artifact, but is not a usable viewer citation in a video.

3. Replay fix

The server-side ordering is sound: `advance()` holds `self.lock`, appends `advanced`, and a later `waiting` cannot be noted until that lock is released. Thus a replay gives the client `waiting(old)` then `advanced(old)` before it can receive `waiting(next)`.

Both views hide the button correctly. Leaving `waitingFor` unchanged in `app.js` is intentional enough: the next `waiting` marks it done, and `done` handles the final one.

Two gaps remain:

- The new server test only proves that an `advanced` event occurs somewhere after the first `waiting`; it does not prove it occurs before the next `waiting`. Assert that ordering explicitly.
- There is no browser/UI regression test that replays `waiting → advanced → waiting` and verifies the old button is absent and the new button remains. The server test alone cannot prove either renderer handles it.

The recording guard is a useful backstop.

4. Earlier narration corrections

Most survived: the investor’s own Confide client decrypts in scene 7; off-chain terms and no matching remain; scene 4 retains the RPC/no-block distinction.

Two details regressed slightly:

- Scene 1 again applies the measured tokenized-equity configuration to both demo mints, including the cash mirror. Say the *stock mint* mirrors those measured settings, or say both demo mints are configured that way without implying the cash claim was measured.
- Scene 6 lost “mint-wide”: restore “no mint-wide auditor key.” That is the important distinction from selective disclosure.

I would also restore “RPC preflight rejects it for the missing signature” in scene 4; the current wording is not false, just less precise.