# Review request — is the new frame right, and what should the last 19 days build?

You re-estimated this project on 2026-09-22: Stocklana **31%** (top prize 10%), CWF **4.8%**
(Grand 0.4%). Your priority was: *Stocklana — do not expand, show the existing DvP evidence short
and sharp; CWF — if Confidential Issuance / Redemption gets built, make it the star of the CWF
video, and that takes CWF to 6–8%.*

**Two things happened since, and one of them changes the argument.** I want you to tell me whether
the direction below is right, and where it is wrong. Be adversarial. Four claims died in this
repository in two days last week and two of them were mine.

---

## 1. What was measured since your estimate

### The diagnosis: why the auditor slot is empty

`web/slots.json`, from `./scripts/slot-scan.sh`, across all **1,992** tokenized-equity mints on
Solana (Backed, Backpack, PreStocks):

| extension | mints |
|---|---|
| `permanentDelegate` — the issuer can move any holder's tokens | **1,992** |
| `pausableConfig` — the issuer can stop every transfer at once | **1,992** |
| `transferHook` — issuer code runs on every single transfer | **1,992** |
| `defaultAccountState` — a new account starts restricted | **1,992** |
| `scaledUiAmountConfig` — dividends and splits | **1,992** |
| `confidentialTransferMint` | **1,992**, auditor slot **empty** on all, `autoApproveNewAccounts` **false** on all |
| `confidentialMintBurn` | **0** |

The argument I drew from it: **issuers are not under-using Token-2022.** They run four control
extensions on every mint — a configuration entirely about seeing and reaching. They declined
exactly one thing, and it is the one whose only disclosure model is a single global auditor key
that decrypts everything, for everyone, forever. Fill it and every holder is permanently readable
by one party; leave it null and no holder can demonstrate anything to anyone. **For a regulated
equity issuer no setting is correct**, which is why three unrelated issuers reached the same
configuration.

Written up: `docs/cwf-2026/WHY-THE-SLOT-IS-EMPTY.md`.

### The event: somebody knocked

`./scripts/usage-scan.sh`, 2026-09-22 08:26 UTC: of **469,477** live token accounts, **2** now
carry `ConfidentialTransferAccount` and **0** are approved. Both on `NVDAx`, both `approved: false`.

- `8P31wJSd…` configured **2026-09-21 23:01 UTC**, after attempts at 21:56 and 22:39 that failed
  `IncorrectProgramId`.
- `5jkuoj8…` configured **2026-09-21 23:50 UTC** (the account itself dates from 09-19).
- The scan **43 minutes earlier** read **0**.
- Two distinct wallets, active since 2024 (389 and 114 transactions), each paying its own fee. Both
  transactions ran through the same program, which turned out to be **generic relayer
  infrastructure** (Withdraw, Sell, Wormhole VAAs, ORE; ~1,000 transactions in eight minutes), not
  confidential-transfer tooling.

**What cannot be concluded, and I want you to check I have not cheated here:**

- **The SEC hypothesis is untestable with this data.** Every account scan in the repository
  postdates the 2026-09-17 order; the earliest is 09-20 01:00 and already reads 0. There is no
  *before*.
- The X post went out 2026-09-21 00:37 UTC, about **22.5 hours** before the first configure, and it
  names the exact thing those two accounts did. The repository records that as a sequence and
  explicitly refuses to call it a cause.
- Two accounts is two. It may stop at two. `usage-scan.sh` now reads the previous run before
  overwriting it and prints whether the count moved, so this is settled by re-running rather than
  by argument.

### An outside correction, which is why the wording changed

A reader (@KirProzorov) replied to the post: *"'No issuer will approve one' is a bit early if you
haven't asked any issuers yet."* They were right — it was a prediction, not a measurement, and
nobody had been asked. Two surfaces were corrected; **two could not be**: the posted thread is
frozen and check-in 1's video window closed 09-21, so a submitted video will keep saying it.
`docs/reviews/2026-09-22-external-no-issuer-will-approve.md`.

---

## 2. The direction I am proposing

### Stocklana (freezes 2026-09-25 13:00 PDT — 2 days)

**Do not expand.** Your instruction, unchanged. `_submission/full.md` is 4,980/5,000 and the
diagnosis went in as **one paragraph** inside the section already titled *"Why nobody has built
it"* — a section that, until yesterday, never said why. One line was also corrected from *"on NVDAx
it is a conversation nobody has had"* to *"two accounts have now asked and Backed has not
answered"*, which was stale rather than weak.

### CWF (2026-10-12 — 19 days)

You said the ceiling is the missing narrated presentation and demo video. My proposal is **not** to
build Confidential Issuance / Redemption, but to build those videos around the diagnosis:

> **no setting of that key is correct → here is a setting that is.**

and to demonstrate it with **what already runs and has never been shown in a pitch**:

| disclosure axis | what implements it | status |
|---|---|---|
| **recipient** — who can read it | `./scripts/set-auditor.sh` | runs, devnet |
| **granularity** — prove "≥ X" over the account's own on-chain ciphertext, two proofs | `./scripts/prove-collateral.sh` | runs, both proofs accepted by Solana's live ZK ElGamal Proof Program |
| **schedule** — sealed now, opened at T by a committee the holder cannot stop | `./scripts/anchor-receipt.sh`, `./scripts/committee.sh`, `crates/confide-embargo` | runs, devnet |

**And the constraint I have already caught myself breaking once:** `docs/cwf-2026/GTM.md` decided
that `confide-embargo` stays out of the pitch because it serves a different buyer — a fund
reporting to its LPs, not a desk moving size — and *"putting two products in one submission halves
both."* The **schedule** axis IS embargo. So the proposal is **recipient + granularity only**, with
schedule left where GTM.md put it: one sentence as evidence that the primitive has a second
demonstrated use. I proposed the wider version first and withdrew it.

---

## 3. What I want from you

1. **Is the diagnosis sound, or am I over-reading a configuration?** Four control extensions at 100%
   is a fact; *"therefore the empty auditor slot is a deliberate refusal rather than neglect"* is an
   inference. Is there a cheaper explanation — copied deployment templates, a shared issuance SDK,
   defaults in someone's tooling — that I have not ruled out? **How would I rule it out?**
2. **Does the frame actually strengthen the wedge, or does it move the submission from a product to
   an essay?** A judge who wants Functionality (§8a) may not care why issuers declined.
3. **Recipient + granularity, or Confidential Issuance / Redemption?** You put Issuance at 6–8% for
   CWF. My claim is that filming what already runs is lower-variance than implementing and filming
   something new in 19 days. **Say if that is wrong.**
4. **Is "somebody knocked" usable at all**, given I cannot attribute it and it may stop at two? It
   is currently in `full.md`, in check-in 2's script, and in the CWF form.
5. **What should NOT be in the CWF videos** that is in the repository today.

## 4. The unfavourable material, so you are not choosing between edited options

- **Traction is zero.** No pilot, no user, no issuer contacted — including now, when two strangers
  have asked the chain and Backed has not answered. Asking Backed is a founder action, not taken.
- **The addressable set is small and measured.** Of 465,498 accounts across six mints, **5,755**
  hold ≥1 share and **268** hold ≥100 (`web/holders.json`, 2026-09-21). The submission says so.
- **"Solana leads in tokenized equity" has never been measured here.** Every scan reads Solana and
  only Solana. The founder's framing assumed it; the write-up says it is unmeasured and no
  submission may lean on it.
- **The lending half is parked** — Kamino refuses a confidential deposit (`constraints.rs:187`) and
  is right to.
- **Check-in 1 is submitted and cannot be edited**, and it says the thing that was corrected.
- **The week's engineering was found wanting by review**, not by tests: the four-message swap's
  step 4 was a blind signing oracle and a counterparty's JSON reached `python3 -c`. Both fixed and
  re-demonstrated on devnet; both were mine.
- **Two claims died last week for outrunning their evidence**, which is the failure mode this
  review is meant to catch a third time.
