# Review request — the direction, after a measurement that broke one of our own claims

Working tree at `04e911a`, plus one untracked file (`docs/cwf-2026/CLAUDE-CODE-BRIEF.md`, written by
the founder this morning). **15 days to the CWF submission (2026-10-12). Check-in 2 closes tomorrow,
2026-09-28 08:00 PDT.** Read the repository directly; every file path below is real.

The founder asked me for a direction for the project. I produced one. **I am asking you to break it**,
and to tell me which parts of my reasoning are wrong before any of it reaches a submission.

## Declare my interest

- **I produced the measurements this argument rests on, today, in this session.** A reviewer
  weighing his own fresh evidence overweights it. Discount accordingly.
- **I criticised the founder's brief this morning** (`docs/cwf-2026/CLAUDE-CODE-BRIEF.md`) and my
  proposal partly replaces it. That is a motive to find its framing insufficient.
- **I was wrong twice in this same session.** (a) I wrote a retry loop whose success test read only
  the first 20 bytes of the response and reported an HTTP 429 as SUCCESS. (b) I said the
  program-wide account scan needed the founder's private endpoint; `scripts/usage-scan.sh:16-17`
  already documented the opposite — the private Alchemy plan refuses `getProgramAccounts`, and the
  public endpoint serves it. Both were caught in-session, but they are the error rate you are
  reviewing against.

## What was measured today, with its limits

**Method.** `getProgramAccounts` is unavailable on every endpoint we have: Alchemy (private) refuses
the method entirely — 429 in 0.18 s even for the empty Memo program, while `getSlot` returns 200;
`solana-rpc.publicnode.com` requires a paid token for indexed requests; `api.mainnet-beta.solana.com`
serves a mint-filtered `gPA` (offset 0, indexed) but returns 403 for any query filtered on offset 165
(the mint/account-type discriminator), including when partitioned into 256 slices the way
`scripts/usage-scan.sh` partitions by owner byte. So the population could not be enumerated from the
program. Instead: candidate mints from Jupiter's verified list (3,702 tokens, 2,062 on Token-2022),
**every fact then read from chain** via `getMultipleAccounts`. The TLV parser was validated against
the RPC's own `jsonParsed` decoder on 6 real mints (6/6) and deliberately truncated below the
extension to confirm it reports truncation instead of silently reporting "no extension".

**Results.**

1. **1,669 mints carry `ConfidentialTransferMint`. `autoApproveNewAccounts = true` on 0 of them.
   An auditor key is set on 0 of them.**
2. **768 of those are not in `web/mints.json`.** Grouped by mint authority (base58 confirmed by the
   RPC's own decoder, and Backed's key matches the one already recorded at `docs/packets/AAPLx.md:38`):
   - `9foMHsSDq7nMg4WPusSz9eY7tyxyukqborA8GyU5cUxD` — **450 mints, "Tesla (Ondo Tokenized)" etc. A
     fourth tokenized-equity issuer this repository does not know about.** `TSLAon` read on its own:
     `CT=True, autoApprove=False, auditor=EMPTY`.
   - `7pt9tkctJPK7PPNQJ77GKg8ZffSF6QxoMiCFYHxrtaCj` — **298 mints under Backed's own authority**, not
     returned by the `api.xstocks.fi` product API that `scripts/refresh-mints.sh` reads. Two distinct
     mints are both "TEFx / Telefónica xStock", suggesting redeployments.
   - `WV9PJN7XTmTLVwbutCLFxp8TyePee6Xq5mRq6Fti5Wc` — 1 more PreStocks mint (`XAI`).
   - ~20 others: PYUSD, USDG, PAXG, AUSD, USDP, USDPT, USDGO, CASH, XO Cash, USDv, Shift leveraged
     products (SPX3L, TSL2L, SPCX2L…), Bullish Ordinary Shares.
3. **Extension profiles differ across issuers while the CT configuration does not:**
   ```
   AAPLx (Backed)  CT, defaultAccountState, pausable, permanentDelegate, scaledUiAmount, transferHook
   TSLAon (Ondo)   CT, defaultAccountState, pausable,                    scaledUiAmount, transferHook
   PYUSD (PayPal)  CT, confidentialTransferFee, mintCloseAuthority, permanentDelegate, transferFee, transferHook
   USDG  (Paxos)   CT, confidentialTransferFee, mintCloseAuthority, permanentDelegate, transferFee, transferHook
   ```
4. **`auto_approve_new_accounts` and `auditor_elgamal_pubkey` are required fields of
   `InitializeMintData`** — `spl-token-2022-interface-3.1.1/src/extension/confidential_transfer/instruction.rs`
   (`pub auto_approve_new_accounts: Bool`, `pub auditor_elgamal_pubkey: MaybeNull<PodElGamalPubkey>`).
   There is no default; the values were passed explicitly at every mint creation.

**The limit that matters.** Jupiter's verified list contains only **901 of the 1,992 mints this
repository already knows (45.2%)**. So 768 is a *lower bound* and the true population is still
unknown. Nothing here supports "every Token-2022 mint on Solana"; it is a liquid-token sample.

## What this breaks

`scripts/slot-scan.sh:3` says *"over **every** tokenized-equity mint on Solana. Not a sample."*
**That is false today.** The 1,992 figure propagates to 25+ surfaces including `README.md`, the
GitHub About line, `web/index.html`, `video/segments-presentation/LINES.md` and `manifest.json` (the
published film), `docs/cwf-2026/x-post.txt` (already posted), `video/CHECKIN-1.md` (already
submitted), and `_submission/` (Stocklana's edit window **closed 2026-09-25**; judging runs to
10-02). `scripts/docs-consistency.sh` cannot catch this class of error: it compares files to files,
and no check reads the token program.

## The direction I proposed

**Core claim: the product is not confidential trading, it is operating the gate.** The condition that
closes this market is isolated and it is operational, not cryptographic — per-account issuer
approval, granted 0 times. The auditor slot is empty on 1,669 mints because the only native
disclosure is a mint-wide master key, i.e. there is no usable scoped disclosure. Confide's existing
ZK assets (floor proofs, receipts, k-of-n) are shaped like that gap.

Three pillars: **(1)** keep one product, issuance-first bilateral settlement, unchanged; **(2)**
promote the measurement apparatus from evidence to deliverable — it needs no counterparty, a judge
can run it, it found a fourth issuer today, and it converts outreach into a fact about the
recipient's own deployment; **(3)** strip intent from every claim and state mechanism only.

Stop: Kamino/lending as *first integration* (keep as evidence — it is the basis of the `$0`);
permissionless composability (structurally impossible — an AMM must read the amount; answer §8(e)
with the one verified path, `SetAuthority` onto a PDA preserving approval, `THE-PINCER.md`).

Post-CWF: the buyer is one of ~12 nameable entities (Backed, Backpack, PreStocks, Ondo, PayPal,
Paxos, Bullish, Shift). **This re-reverses the founder's 2026-09-16 ruling** that an issuer is "a
gate on eligibility, not a buyer". My argument for re-reversing: that ruling assumed issuers had
declined disclosure as a cost; the measurement says there was no usable disclosure to decline.

## Material against my proposal — stated so you can see I did not remove it

- **Traction is zero. No issuer, holder, venue or customer has been contacted.** Contact is
  founder-only (`CLAUDE.md`) and outside the window. The buyer claim cannot be tested by 10-12.
- **You already rejected an adjacent frame on 2026-09-23** (`docs/reviews/2026-09-23-the-disclosure-frame.md`),
  specifically the inference of deliberate refusal: *"exact 100% uniformity is at least as consistent
  with a shared deployment template, SDK, or issuance provider."* I claim items 3 and 4 above weaken
  that, but **they do not prove a policy decision** — a wrapper or a docs example could carry `false`.
- **`docs/27-DAYS.md:361` refuses "more documentation-integrity work beyond final claim checks."**
  Fixing the population is exactly that work, and my plan spends scarce days on it.
- **`docs/27-DAYS.md:241` sets Week 3 as coverage over every live mint.** My proposal changes what
  "every" means mid-flight and the founder's brief drops coverage entirely.
- **The 09-16 ruling I want to re-reverse had a stated reason** (incentive: a disclosure model is a
  cost to an issuer). I am overturning a founder ruling on the strength of one day's measurement.
- **The correction cannot reach Stocklana.** Its form froze 09-25 and its judges read this repo
  through a submission that contains the overstated claim.
- **"Not a sample" cannot be restored** without an endpoint that serves unindexed `gPA` (Helius,
  Triton, QuickNode, or a paid Alchemy tier) — a purchase, i.e. a founder decision.
- **Check-in 2 closes tomorrow 08:00 PDT.** `video/CHECKIN-2.md` is 59 s / 128 words and full; its
  spoken lines never say "1,992", so recording it unchanged states nothing false.

## What I am asking

1. **Is "the product is operating the gate" a defensible reframing, or is it a third pivot in eleven
   days with no new demand evidence?** (09-16 issuer-is-not-a-buyer → 09-20 loan-to-trade → this.)
2. **Do items 3 and 4 actually answer your 09-23 objection, or am I overclaiming again?** What is the
   strongest remaining non-intent explanation, and what measurement would separate them?
3. **Population: widen (add Ondo, re-derive every dependent number, repaste the CWF form) or narrow
   the wording ("every mint the issuers' product APIs list")?** Given 15 days and a frozen Stocklana
   submission, which costs less and which is more honest?
4. **Should the measurement apparatus be a first-class deliverable**, against `27-DAYS.md`'s refusal
   list and the Week 3 coverage beat?
5. **Is re-reversing the 09-16 ruling justified** by "they did not decline disclosure; there was no
   usable disclosure to decline"?
6. **Check-in 2, due in under a day: include today's correction, or record the existing script?**
7. **What in this direction is most likely to be wrong, that I have not listed above?**

Verify against the files. If any measurement above is wrong, that matters more than the strategy.
