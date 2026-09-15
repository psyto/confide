## Verdict-changing failures

1. **The “default” demo does not prove a real default or a proven collateral floor.** This is the most serious overclaim.

   `docs/SEIZURE.md` says the borrower proves `E >= Q_min` and the program evaluates default from that proven floor ([lines 78-80](</Users/hiroyusai/src/confide/docs/SEIZURE.md:78>), [151-164](</Users/hiroyusai/src/confide/docs/SEIZURE.md:151>)); README repeats that the program evaluates “from a proven floor” ([line 105](</Users/hiroyusai/src/confide/README.md:105>)). It does not.

   The on-chain `originate` instruction accepts `q_min` as caller-supplied bytes and copies it into the loan record; it receives no floor-proof account and verifies no floor proof ([program lines 112-188](</Users/hiroyusai/src/confide/programs/confide-seizure/src/lib.rs:112>)). The e2e script never runs `prove-collateral.sh`.

   Worse, “price falls” is invented by the signer. `seize` accepts a caller-supplied `price` and merely requires the recorded oracle account to sign ([lines 203-255](</Users/hiroyusai/src/confide/programs/confide-seizure/src/lib.rs:203>)). In the e2e, the lender is that oracle and submits `99` itself ([e2e lines 137-150](</Users/hiroyusai/src/confide/scripts/seizure-e2e.sh:137>)). There is no price-feed account, no oracle state read, and no attestation binding the price to a market.

   The honest claim is: “a pre-authorized confidential transfer executed after the demo’s trusted lender/oracle signed a chosen price.” It is not yet “seizure on a proven collateral default.” This affects README [94](</Users/hiroyusai/src/confide/README.md:94>), web [131-136](</Users/hiroyusai/src/confide/web/index.html:131>), full submission [50](</Users/hiroyusai/src/confide/_submission/full.md:50>), YouTube [55](</Users/hiroyusai/src/confide/_submission/youtube.md:55>), and the video narration [80-85](</Users/hiroyusai/src/confide/video/voiceover.md:80>).

2. **The repository’s declared published video is not the current cut described by the documents.**

   `video/README.md` says `Confide_Stocklana_20260915.mp4` is the published “current render” ([lines 3-5](</Users/hiroyusai/src/confide/video/README.md:3>)). I inspected that file: it is **112.52 seconds**. The current silent master and nine-clip manifest are **128.43 seconds / 2:07**. The YouTube description says its chapters come from the “current cut (2:07)” ([YouTube lines 76-85](</Users/hiroyusai/src/confide/_submission/youtube.md:76>)); those chapter times are therefore wrong for the file the repo says was uploaded.

   This is not cosmetic. The published file’s subtitle track puts the seizure narration around 1:33–1:45, while the pasted description calls the seizure chapter 1:43 and implies a 2:07 cut. `narrate.sh` also defaults to that old 112-second source while calling itself the path for the current render ([lines 19-28](</Users/hiroyusai/src/confide/video/narrate.sh:19>)). `join.sh` still assembles the old eight filenames and omits both `08-seizure` and `09-close` ([lines 17-20](</Users/hiroyusai/src/confide/video/join.sh:17>)).

   Treat the current YouTube metadata, local “published” asset, narration sheet, and source master as four divergent releases until one is selected, rendered, uploaded, and checked by duration and captions.

3. **The CWF eligibility statement is publicly ambiguous at best and false in its ordinary reading.**

   README and DESIGN call Confide “written in-window” ([README 247](</Users/hiroyusai/src/confide/README.md:247>); [DESIGN 155](</Users/hiroyusai/src/confide/DESIGN.md:155>)); the full submission says “Original work, in-window” ([68-70](</Users/hiroyusai/src/confide/_submission/full.md:68>)). `STATUS.md` admits this is false for CWF because the 48 existing commits predate the CWF window ([122-126](</Users/hiroyusai/src/confide/STATUS.md:122>)); `WORK-WINDOW.md` says Confide already existed when that window opened ([3-5](</Users/hiroyusai/src/confide/docs/WORK-WINDOW.md:3>)).

   It may be true for Stocklana. None of the public copy says that. A CWF judge can reasonably read this as a false contest-work declaration. Put the CWF baseline and explicit past-work disclosure where the judge actually lands, not in an internal appendix.

4. **“Every tokenized stock on Solana” is not established.**

   This is the central claim in README [5-7](</Users/hiroyusai/src/confide/README.md:5>), DESIGN [9-12](</Users/hiroyusai/src/confide/DESIGN.md:9>), ONCHAIN [8-19](</Users/hiroyusai/src/confide/docs/ONCHAIN.md:8>), web [90-98](</Users/hiroyusai/src/confide/web/index.html:90>), submission [3-5](</Users/hiroyusai/src/confide/_submission/full.md:3>), and video.

   `slot-scan.sh` checks every mint in `web/mints.json`; it does not discover the universe. `refresh-mints.sh` builds that file from two issuer APIs only: Backed and Backpack ([22-47](</Users/hiroyusai/src/confide/scripts/refresh-mints.sh:22>)). That supports: “all 1,869 issuer-listed Solana equity mints returned by these two APIs at refresh time.” It does not support: “every tokenized stock on Solana,” “two issuers” as an exhaustive issuer census, or the absence of another issuer.

5. **Recipient/granularity choice is sold as a shipped product but demonstrated only as public release plus public proof.**

   “You choose who, how much, and when” appears in README [33-35](</Users/hiroyusai/src/confide/README.md:33>), web [57-61](</Users/hiroyusai/src/confide/web/index.html:57>), full submission [28](</Users/hiroyusai/src/confide/_submission/full.md:28>), and YouTube [45](</Users/hiroyusai/src/confide/_submission/youtube.md:45>).

   The shown scheduled package hard-codes `recipient: "public"` ([committee lines 63-73](</Users/hiroyusai/src/confide/crates/confide-committee/src/lib.rs:63>)); anchoring hashes `"public"` as recipient ([anchor lines 64-74](</Users/hiroyusai/src/confide/crates/confide-onchain/src/anchor.rs:64>)). The lender proof is served in public `web/proofs.json`, and the seizure document itself says `Q_min` leaks “permanently and publicly” ([SEIZURE 184-185](</Users/hiroyusai/src/confide/docs/SEIZURE.md:184>)). README admits standing per-counterparty grants have no product surface ([110-111](</Users/hiroyusai/src/confide/README.md:110>)).

   Do not market recipient-scoped private disclosure as demonstrated. The demo shows global auditor access, a public scheduled opening, and a publicly replayable threshold proof.

6. **“Identically configured / one field apart” is false.**

   The mirror only demonstrates the relevant confidential-transfer setting: `autoApproveNewAccounts: false`. It is not an NVDAx-equivalent mint one field apart.

   NVDAx has metadata pointer, permanent delegate, default account state, scaled UI amount, pausable config, transfer hook, and token metadata in addition to confidential transfer ([ONCHAIN 35-42](</Users/hiroyusai/src/confide/docs/ONCHAIN.md:35>)). The mirror is created with only `create-token --enable-confidential-transfers manual` ([provision 54-58](</Users/hiroyusai/src/confide/scripts/provision-account.sh:54>)).

   Correct all instances: README [89](</Users/hiroyusai/src/confide/README.md:89>), ONCHAIN [166-172](</Users/hiroyusai/src/confide/docs/ONCHAIN.md:166>), full submission [46](</Users/hiroyusai/src/confide/_submission/full.md:46>), voiceover [124-125](</Users/hiroyusai/src/confide/video/voiceover.md:124>), and LINES [77-78](</Users/hiroyusai/src/confide/video/segments/LINES.md:77>).

## Direct stale contradictions

- `docs/SEIZURE.md` opens by saying seizure “is a design, not a shipped claim” ([10-13](</Users/hiroyusai/src/confide/docs/SEIZURE.md:10>)), then says it runs end-to-end ([284-301](</Users/hiroyusai/src/confide/docs/SEIZURE.md:284>)). Its build order still says “not yet deployed” and names unimplemented `escrow-account.sh` and `seize.sh` ([353-368](</Users/hiroyusai/src/confide/docs/SEIZURE.md:353>)). This is exactly the failure mode you described, still present.

- The same file says ownership transfer with a nonzero confidential balance is “not confirmed” ([124-127](</Users/hiroyusai/src/confide/docs/SEIZURE.md:124>)), then says “Nothing is assumed any more” ([284](</Users/hiroyusai/src/confide/docs/SEIZURE.md:284>)). It needs a single current-state rewrite, not historical assertions embedded as present tense.

- `docs/ONCHAIN.md` says the proof is not yet over the bound ciphertext ([146-151](</Users/hiroyusai/src/confide/docs/ONCHAIN.md:146>)), then later says it is over the account’s own ciphertext ([214-247](</Users/hiroyusai/src/confide/docs/ONCHAIN.md:214>)). The stale claim is also still in `bind.rs` ([12-15](</Users/hiroyusai/src/confide/crates/confide-onchain/src/bind.rs:12>)). The document’s opening date “Read on 2026-09-12” ([3-4](</Users/hiroyusai/src/confide/docs/ONCHAIN.md:3>)) cannot describe its September-15 account, anchor, and seizure additions.

- `STATUS.md` says e2e is “just short” of completion ([86-87](</Users/hiroyusai/src/confide/STATUS.md:86>)), then immediately records it as complete ([92-93](</Users/hiroyusai/src/confide/STATUS.md:92>)).

- `video/voiceover.md` title narration omits “The chain simply publishes it” ([14-15](</Users/hiroyusai/src/confide/video/voiceover.md:14>)); `LINES.md` and the manifest include it ([35](</Users/hiroyusai/src/confide/video/segments/LINES.md:35>)). That is a real recording mismatch.

- README calls `healthcheck.sh` “eight live checks” ([161](</Users/hiroyusai/src/confide/README.md:161>)); it currently performs fourteen discrete checks, including seizure program, seized-loan flag, proof simulations, and four URLs. `DURABILITY.md` repeats the obsolete count ([8-12](</Users/hiroyusai/src/confide/docs/DURABILITY.md:8>)).

## Legal and market claims that should not survive without correction

- “When Nasdaq’s filed tokenized-form rule settles” is stale in README [139](</Users/hiroyusai/src/confide/README.md:139>) and DESIGN [78-82](</Users/hiroyusai/src/confide/DESIGN.md:78>). The SEC approved SR-NASDAQ-2025-072 on March 18, 2026; it is not pending. More importantly, do not imply its approval newly creates a Form 13F obligation. Form 13F turns on the manager, threshold, and Official List criteria, not merely tokenized trading. [SEC Nasdaq order](https://www.sec.gov/rules-regulations/self-regulatory-organization-rulemaking/sr-nasdaq-2025-072), [SEC Form 13F FAQ](https://www.sec.gov/rules-regulations/staff-guidance/division-investment-management-frequently-asked-questions/frequently-asked-questions-about-form-13f)

- DESIGN calls the January statement “what the law actually says” ([60-76](</Users/hiroyusai/src/confide/DESIGN.md:60>)). The source explicitly says it is staff views, not Commission rule, regulation, or guidance. The document may use it as context; it cannot present its classification of xStocks as settled legal fact. [SEC staff statement](https://www.sec.gov/newsroom/speeches-statements/corp-fin-statement-tokenized-securities-012826-statement-tokenized-securities)

- “Usage is close to zero” / “nobody uses it” ([DESIGN 12](</Users/hiroyusai/src/confide/DESIGN.md:12>), [full submission 7-8](</Users/hiroyusai/src/confide/_submission/full.md:7>)) has no measurement, method, or source. The mint scan cannot establish it. Cut it or define the metric.

- The $5.8B quarterly-volume claim ([README 128-131](</Users/hiroyusai/src/confide/README.md:128>), [DESIGN 30-33](</Users/hiroyusai/src/confide/DESIGN.md:30>)) has no source or methodology in the repo. It may be directionally true, but unsupported market statistics look invented in a judge read.

## What is missing for the non-engineering criteria

The honest answer on traction is currently **zero**; `STATUS.md` says so explicitly ([80-82](</Users/hiroyusai/src/confide/STATUS.md:80>) and [104-109](</Users/hiroyusai/src/confide/STATUS.md:104>)). Do not replace that with rhetoric.

Before evidence exists, add a one-sentence limitation in the README’s first screen and CWF submission: no issuer approval, pilot, customer interview, design partner, or user validation yet. After evidence exists, add only auditable facts:

- named buyer and user: issuer compliance lead, fund administrator, GP, or lender;
- specific workflow and integration point;
- what they confirmed, rejected, or asked for;
- why they would pay and who pays;
- issuer approval status for confidential accounts;
- a dated interview/pilot artifact.

“Kraken included, having acquired Backed” ([README 269-270](</Users/hiroyusai/src/confide/README.md:269>)) is not traction. “Issuer is the customer” is a hypothesis, not a finding.

## Structure: why it still reads as research

README’s first screen is a chain-scan thesis and terminal output ([5-31](</Users/hiroyusai/src/confide/README.md:5>)), not an answer to “could this be a real app people use?” The user, buyer, trigger, integration point, and payment path appear late or not at all.

Move or cut:

- Move **“Why this and not MEV protection,” “The split problem,” “And the other half of a quarterly report,”** and most of **“Built on”** below the proof/evidence section or into DESIGN.
- Cut public postmortem archaeology: old funding mistakes, old account failures, old video failures, and “this document used to say…”. It makes the submission look like lab notes.
- Put the real limitation immediately beside the value proposition: live issuer approval is required; no issuer has given it; no lending protocol/oracle exists.
- Add a short **“Who uses this first”** section before **“What a usable auditor slot is worth.”** If that section cannot contain real evidence, the verdict is already visible.

`DESIGN.md` also omits the newly claimed seizure architecture entirely while README sells it. That is an underclaim in the technical argument and makes the repository look internally unowned.