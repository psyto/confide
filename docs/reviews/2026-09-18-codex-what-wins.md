The replacement bet is worth keeping, but only as evidence of insight and execution—not as a substitute for market size, viability, or traction.

First, fix one newly material credibility failure. The public page, packet generator, and “fail-loud” verifier still cite Kamino lines that do not contain the claimed checks: e.g. [`kamino-verdict.sh`](/Users/hiroyusai/src/confide/scripts/kamino-verdict.sh:53), [`kamino.html`](/Users/hiroyusai/src/confide/web/kamino.html:82), and every generated packet, e.g. [`NVDAx.md`](/Users/hiroyusai/src/confide/docs/packets/NVDAx.md:102). Direct inspection of the pinned source confirms the substance—the ordinary deposit path checks the depositor’s account and rejects confidential value—but not those line citations. The relevant branches are in the `ConfidentialTransferMint` and `ConfidentialTransferAccount` blocks, and the deposit helper invocation is in `deposit_reserve_liquidity_checks`, not at the claimed locations. [Pinned Kamino constraints source](https://github.com/Kamino-Finance/klend/blob/a08760976f51a3a58c4a0c6ea27b4a0e565bca79/programs/klend/src/utils/constraints.rs#L110-L195), [deposit checks](https://github.com/Kamino-Finance/klend/blob/a08760976f51a3a58c4a0c6ea27b4a0e565bca79/programs/klend/src/lending_market/lending_checks.rs#L145-L245)

This is not “more documentation integrity work.” It is a one-ticket repair to the claim on which the page’s authority rests. Do it before directing another person to the page. Do not turn it into a broad audit.

The premise that four non-engineering criteria are literally read before engineering is not verified. The live Colosseum page lists seven factors without weights or a read order; it explicitly calls the presentation one of the first resources judges review, asks for GTM, demand validation, distribution, team background, and says it evaluates a startup holistically. [Colosseum’s current submission and judging FAQ](https://colosseum.com/hackathon) The Official Rules instead list six factors, with functionality first and no traction criterion. :codex-file-citation{path="/Users/hiroyusai/src/confide/docs/Crypto World's Fair Hackathon Rules.pdf" purpose="source"}

That does not make the non-engineering gaps unimportant. It means “four-sevenths read first” should not drive a false choice between a credible product and a credible business story.

On the replacement bet:

- The $21.1m / $81.6m computation is strong evidence of a real beachhead and a concrete impact surface. It is not TAM. It measures a snapshot of existing liquidity and an authorization ceiling, not demand for confidential collateral or revenue available to Confide.
- It improves viability only indirectly: it shows a legible buyer and a tractable integration boundary. It also proves three material pieces are absent—continuous re-proving, liquidation hand-off, issuer approval. That is excellent honesty, but it is not yet a scalable-business explanation.
- So the correct claim is: “a judge can independently verify the problem, the immediate wedge, and our technical ability.” Do not claim it answers market size and viability by itself.

Traction is zero. Existing live reserves are market evidence; the 1,869 mints are ecosystem/supply evidence; devnet use is functionality. None is Confide traction.

Instrumentation is worth at most a small, transparent implementation. “Eleven people opened a public page” is not traction and should never be presented as it. It becomes useful only as distribution learning: “X targeted invitations, Y unique decision-page visitors, Z packet downloads / mint lookups, dates, and any qualitative response.” Even then it belongs under demand-validation progress, not traction. Twenty-four days is enough to learn something, but not enough to manufacture a non-embarrassing adoption number. Instrument only if the founder will distribute the link and preserve the denominator; otherwise cut it.

Founder-market fit is a form-and-story problem first, not an evidence-building project. The repository demonstrates unusually strong technical fit, but it does not establish why this founder should win this market. The CWF submission needs truthful answers to:

- What firsthand observation led to this specific problem?
- What relevant prior experience, network, or repeated work makes the founder credible with RWA issuers, lenders, or Solana privacy infrastructure?
- Why is the chosen wedge risk admission, rather than generic privacy?
- What did the issuer-to-lender reversal teach about prioritization?

If the honest answer lacks direct market proximity, say so; demonstrate learning velocity and technical execution rather than inventing proximity.

My ranking of remaining work:

1. Targeted citation/claim repair. It protects every other score.
2. A canonical CWF submission draft mapped to the actual form: founder story, GTM, demand validation, distribution, viable paid path, prior-work disclosure, and honest traction.
3. Final narrated 2–3 minute presentation. The 167-second rough cut proves pacing, but its script has no founder narrative or sustainable-business answer yet.
4. Separate ≤3-minute demo. It should demonstrate one precise claim and its boundary—not repeat the pitch.
5. A two-sided control only if it is real: “public path passes; confidential source path requires integration,” ideally through the same executable path. A bare mint-extension `PASS` is weak and risks proving only that Kamino already works without Confide.
6. Minimal instrumentation, conditional on real targeted distribution.
7. Weekly check-ins, time-boxed. The current site says they are strongly recommended, not mandatory; use them to report a real decision or test, never to narrate a plan.
8. Full admission packets for every one of 1,869 mints: cut. The page already evaluates 1,869 mint-extension cases, while the 14 reserve-backed packets are the economically relevant set. More rows do not strengthen the business case.

Theatre to cut:

- Treating anonymous pageviews as traction.
- Expanding coverage merely to make the number larger.
- Polishing the silent rough cut instead of completing the actual two submission videos.
- A `PASS` control that does not exercise the distinction central to Confide.
- Check-ins with no new falsification, decision, or externally observable learning.
- Any new mechanism from the refusal list. I would keep all five refusals: price feed, repayment, `deshield`, mainnet, and wrapper token. None repairs the scoring gap; several would worsen the honesty boundary.

One genuinely different move: apply to the Colosseum SF Builder Station if attending San Francisco from September 28 to October 12 is genuinely feasible. It is a selected CWF-founder program; accepted builders receive workspace access and an automatic accelerator interview. It does not create customer traction and should not displace the submission, but it is a direct founder/accelerator channel rather than another artifact or curator cold approach. [Colosseum’s Builder Station announcement](https://blog.colosseum.com/builder-station-sbpfv3-solana-resilience/)

I could not verify the outreach count, any external page use, founder background, live chain numbers, actual submission-form fields after registration, or partner-prize details beyond the public ecosystem-track material. I also did not execute a Kamino deposit or visually/audibly review the rough-cut video; I verified its duration is 167 seconds and reviewed its script.
---

## Verified against the repository, 2026-09-18

Checked before anything here was acted on, because `CLAUDE.md` says Codex's findings are verified
against real files first — on 2026-09-16 it estimated four line numbers from GitHub URLs and missed
all four.

**Finding 1 — the line citations — is wrong. All eight are correct.** Read with `sed -n "${n}p"`
out of the clone at the pinned commit `a08760976f51a3a58c4a0c6ea27b4a0e565bca79`, not from a URL:

| cited | what is actually on that line | enclosing function |
|---|---|---|
| `constraints.rs:44` | `ExtensionType::ConfidentialTransferMint,` | `mod token_2022` allow-list |
| `constraints.rs:61` | `ExtensionType::ConfidentialTransferAccount,` | `mod token_2022` allow-list |
| `constraints.rs:131` | `if bool::from(ext.auto_approve_new_accounts) {` | `check_only_supported_extensions_on_liquidity_mint` |
| `constraints.rs:187` | `if bool::from(token_acc_ext.allow_confidential_credits) {` | `check_only_supported_extensions_on_liquidity_ta` |
| `constraints.rs:194` | `if !bool::from(token_acc_ext.allow_non_confidential_credits) {` | `check_only_supported_extensions_on_liquidity_ta` |
| `constraints.rs:201` | `if token_acc_ext.closable().is_err() {` | `check_only_supported_extensions_on_liquidity_ta` |
| `lending_checks.rs:186` | `constraints::token_2022::check_only_supported_liquidity_token_extensions(` | `deposit_reserve_liquidity_checks` |
| `lending_checks.rs:188` | `&accounts.user_source_liquidity.to_account_info(),` | `deposit_reserve_liquidity_checks` |

The review's own evidence contradicts its conclusion twice. The ranges it links —
`constraints.rs#L110-L195` and `lending_checks.rs#L145-L245` — **contain** the cited lines, and it
names `deposit_reserve_liquidity_checks` as where the deposit helper "should" be, which is the
function line 186 is in. **Same failure mode as 2026-09-16, now twice.** Nothing was repaired,
because nothing was broken.

**The rest is taken.** Four things survive and one of them is load-bearing:

1. **"Four of seven read first" is an unverified premise that shaped the whole plan.** `STATUS.md`
   and this file both assert it. Neither cites anything. Codex reports the live Colosseum page lists
   seven factors with no weights and no stated read order, and calls the *presentation* one of the
   first things judges open. It could not be verified from here either. **Treat the ordering claim
   as unsourced until somebody reads the page**, and stop using it to justify trading product
   credibility for business narrative.
2. **$21.1m / $81.6m is not market size.** It is a snapshot of deposited liquidity and an
   authorisation ceiling — not demand for confidential collateral, and not revenue available to
   Confide. The honest claim is that a judge can independently verify the problem, the wedge and
   the technical ability. It should not be presented as answering *potential market size* on its own.
3. **Founder + market fit is a story problem, and it is absent from every surface here.** Four
   questions worth answering truthfully in the submission: what firsthand observation led to this
   problem; what prior experience or network makes this founder credible with issuers, lenders or
   Solana privacy work; why the wedge is risk admission rather than privacy; what the
   issuer-to-lender reversal taught. If there is no direct market proximity, say so.
4. **Two things the plan schedules should be cut.** Week 3's packets for all 1,869 mints — the page
   already evaluates all of them and the fourteen reserve-backed ones are the economically relevant
   set, so more rows make the number larger without making the case stronger. And a bare `PASS`
   control that only proves Kamino already works without Confide; a control is worth cutting unless
   it exercises the public-path/confidential-path distinction through the same executable route.

All five refusals are kept — price feed, repayment, `deshield`, mainnet, wrapper token.

One item is founder-only and outside this repository: the Colosseum SF Builder Station, which needs
being in San Francisco 09-28 to 10-12.

**Minor.** The rough cut is 167.0 s as a file and 166 s as a narration budget; `pace.py` generates
the second from the script's words and the recorder holds each scene to it, with the difference
being the closing fade. Both numbers are true of different things and nothing in the repository
claims the file is 166 s.
