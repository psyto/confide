# Review request, round 2 — the motive sweep after your round-1 findings, 2026-09-30

Round 1: `docs/reviews/payloads/2026-09-30-the-motive.md` → your answer
`docs/reviews/2026-09-30-the-motive-r1.md` ("not ready: the check would pass several current,
unallowlisted motive claims"). All nine surfaces you named were verified in the real files and were
live, including the published `web/index.html`.

## What was done with each round-1 finding

- **The nine missed surfaces**: rewritten — web/index.html, README (both), ONCHAIN:189, DESIGN:25 and
  :287, confide-equity doc comment, STORY:56, COMPOSITION:104, WHAT-THE-WEEK-CHANGED:101.
- **The new check then found more** that neither of us had named: STORY:83 ("four independent
  witnesses", plus "every regulated Token-2022 issuer arrives here" — a universal from four issuers),
  POST.md:44 (unposted draft, "So it sits null"), `set_auditor.rs` ("That is why the live mints leave
  it null"), and the CWF form's "a constraint nobody chose" — which referred to Kamino's own
  `constraints.rs:187`, a rule somebody did choose. I treated "nobody chose" as the mirror-image
  overclaim of "chose": a default does not prove nobody decided either.
- **Q1 (auditor scope)**: in every sentence rewritten, "decrypts everything, for everyone, forever"
  became "can decrypt the amount of every confidential transfer made while it is set". **Not swept
  repo-wide** — `video/demo.html` and others still say "everyone's everything, forever". That is a
  separate overclaim class and I have left it as the next item rather than half-do it here.
- **Q2**: README heading → "What is on chain, and what Token-2022 does not provide".
- **Q3**: replaced with your sentence verbatim, attributed.
- **Q5 (check design)**: rewritten as shapes, per SENTENCE with adjacent-pair rules: CAUSE (a reason
  attached to empty/null/inert: "because" with the slot/feature named; "that is why/which is why/the
  reason … leave/stays … null"; "so … sits/left … empty"; strong verdicts standalone; "not an
  oversight" next to an empty slot), INDEPENDENCE (not "independently verifiable/of"), INTENT,
  SECONDARY. Exemptions are per sentence: Kamino's code, and OUR OWN mirror/testbed mints.
  Frozen artifacts pinned by sha256 prefix; the retraction (THE-PINCER) must still name what it
  retracts. `git ls-files -z`. **Self-test fixtures**: 17 MUST_FLAG sentences (the live ones from
  today) and 10 MUST_PASS; the run fails if any fixture misbehaves. Each rule was removed in turn
  (8 weakenings) and each removal failed the run; frozen-file change, retraction removal, reverting
  the site sentence, and a new untracked file all failed. Quote-stripping kept (corrections must
  quote); noted as the accepted gap.
- **Q6**: recorded as a founder recommendation (re-record the CWF presentation clause before 10-12);
  the narration files stay pinned as published.

## Questions

1. Is any rewrite now an underclaim, or a new overclaim? In particular DESIGN.md "So a fund holding
   NVDAx today holds it in the clear: on the mints scanned, no confidential account has been
   approved, so there is no other way to hold it." and README "a fund holding NVDAx has nowhere to
   hold it except in the clear". Are those supported by `web/usage.json` (6 mints, 0 approved)?
2. Is treating "nobody chose" as an overclaim right, or is it over-correction?
3. Can you construct live-looking sentences that still evade the check? Try, and say which rule
   should catch them. Are any exemptions (mirror/testbed/"our own"/"we control") a hiding place?
4. Any surface still carrying a motive claim — grep the tree yourself; do not trust my check.
5. Anything in the diff that breaks a generator, a pasted-file record, a character limit, or a
   check elsewhere in docs-consistency.sh?

## Full diff against HEAD

```diff
diff --git a/DESIGN.md b/DESIGN.md
index 087dfb8..4a4273f 100644
--- a/DESIGN.md
+++ b/DESIGN.md
@@ -22,14 +22,16 @@ unauthenticated RPC call. The ZK ElGamal Proof Program was re-enabled at epoch 9
 the substrate works. What the scan measures is narrower and enough: **not one of the 1,992 mints
 has an auditor key set**, so no holder of any of them can demonstrate a balance to anyone.
 
-Shipped, configured, inert. Not because it is immature: because Token-2022 offers exactly one
-disclosure model, a single global auditor key that decrypts everything for everyone forever, and
-**no setting of that key is correct for a regulated equity issuer.** Fill it and every holder's
-position is permanently readable by one party. Leave it null and no holder can demonstrate anything
-to anyone — which means no holder who is ever asked to prove something can use the feature at all.
+Shipped, configured, inert. Why is not measured: null is also the default a new mint gets
+([`THE-PINCER.md`](docs/cwf-2026/THE-PINCER.md), 2026-09-27). What is measured is the substrate:
+Token-2022 offers exactly one disclosure model, a single mint-wide auditor key that can decrypt the
+amount of every confidential transfer made while it is set. **No setting of it shows one number to
+one party.** Fill it and one party reads every holder's transfers. Leave it null and no holder can
+demonstrate anything to anyone — which means no holder who is ever asked to prove something can use
+the feature at all.
 
-That is why a fund holding NVDAx transacts in the clear. It is not choosing publicity; it is
-choosing the only option under which it can still answer a question.
+So a fund holding NVDAx today holds it in the clear: on the mints scanned, no confidential account
+has been approved, so there is no other way to hold it.
 
 And the questions are real and constant. An LP is owed a position report every quarter — contractual,
 universal, in essentially every LPA — and today the LP has no way to check it: the GP reports a
@@ -284,9 +286,8 @@ Two limits that are **not** non-goals — they are gaps, and the next work:
   the figure with the opening, and `confide-open` checks it opens the sealed commitment before
   printing it. A number restated in between does not.
 
-- **The issuer is the customer, not the obstacle.** `autoApproveNewAccounts: false` on the live
-  mints means Backed decides who may hold a confidential balance. They built the feature,
-  configured it, gated it, and left the key slot empty — a company that means to enable this and
-  has no disclosure model to enable it *with*. Wrapping into a mint of our own would dodge the
+- **The issuer holds the gate, and Confide works through it.** `autoApproveNewAccounts: false` on
+  the live mints means Backed decides who may hold a confidential balance. Why its key slot is empty
+  is not measured. Wrapping into a mint of our own would dodge the
   approval and is the wrong trade: a wrapped token is not what lenders take as collateral, and
   holding the backing would make us the single trusted party this layer removes.
diff --git a/README.md b/README.md
index c6953f3..1f4230c 100644
--- a/README.md
+++ b/README.md
@@ -23,15 +23,17 @@ ten minutes**, a Tier 1 name capped at **0.25% of average daily volume**. Block
 settled away from that tape, and a desk cannot go where every fill is published. Confide settles
 off it — and is **not a venue**, so the exemption neither covers it nor is needed.
 
-### Why nobody has built it
+### What is on chain, and what Token-2022 does not provide
 
 **All 1,992** tokenized-equity mints from three issuers' catalogues already run Token-2022 with
 confidential transfers **on** and the auditor slot **empty** — every mint in the list checked, not
-sampled, and [the list is a catalogue rather than a census](docs/cwf-2026/THE-POPULATION.md). They did not miss it: the
+sampled, and [the list is a catalogue rather than a census](docs/cwf-2026/THE-POPULATION.md). The
 same 1,992 carry `permanentDelegate`, `pausableConfig` and a transfer hook. Token-2022's only
 disclosure model is **mint-wide** — one auditor key, reading every transfer made while it is set,
-scoped to nobody. Everybody readable, or nobody. **So every issuer left it empty** — and a
-confidential account cannot receive anything until its issuer signs for it.
+scoped to nobody. Everybody readable, or nobody; **there is no setting in between.** Why the slot is
+empty is not measured — an empty slot is also what a zero-initialised mint gets by default
+([THE-PINCER.md](docs/cwf-2026/THE-PINCER.md#and-the-uniformity-is-not-evidence-of-a-decision--2026-09-27)).
+And a confidential account cannot receive anything until its issuer signs for it.
 
 ### Which makes the first trade an issuance
 
@@ -240,11 +242,11 @@ Not "few". **Zero.** Every mint needs the issuer's signature to open a confident
 no issuer has signed. There is no incumbent here and nothing to be late to.
 
 The feature is shipped, configured, and **inert**. Token-2022 offers exactly one disclosure model —
-a single global auditor key that decrypts **everything, for everyone, forever** — and for a
-regulated equity issuer no setting of that key is correct. Fill it and every holder is permanently
-readable by one party. Leave it null and no holder can demonstrate anything to anyone. So it sits
-empty, and the privacy nobody can use is why a fund holding NVDAx broadcasts its position to the
-whole market instead.
+a single mint-wide auditor key that can decrypt the amount of **every confidential transfer made
+while it is set**, and cannot be scoped to one holder or one reader. Fill it and one party reads
+every holder's transfers. Leave it null and no holder can demonstrate anything to anyone. It is null
+on every mint in the list — why is not measured, since null is also the default — and with no
+confidential account approved, a fund holding NVDAx has nowhere to hold it except in the clear.
 
 **Confide is what makes that slot usable**, and
 [the trade above](#what-runs-today--a-trade-that-settles-without-publishing-either-side) is the
@@ -584,7 +586,7 @@ stack, and the reuse declaration below is for eligibility, not for discounting w
 |---|---|
 | **Hold a position on-chain that reads as zero.** A live devnet account: `spl-token balance` says `0`, the confidential balance holds 173,000. Both public, both true. | `./scripts/bind-account.sh` — [explorer](https://explorer.solana.com/address/Cgv2eDNUUrgRVhkZ8mBE5UkQmkqLh3Aj3poLiqBBrX1P?cluster=devnet) |
 | **Bind a disclosure to that account**, not to a string — its own ElGamal key and its own ciphertext, re-read from chain to confirm. | `./scripts/bind-account.sh` |
-| **Fill the auditor slot.** The mirror gates new accounts exactly as NVDAx does — `autoApproveNewAccounts: false` — so the issuer has to sign for the confidential account before it can hold anything, and the demo does that rather than describing it. One field then separates the two mints, and the reason that field stays null everywhere else is that the key it holds cannot be scoped. | `./scripts/set-auditor.sh` — devnet |
+| **Fill the auditor slot.** The mirror gates new accounts exactly as NVDAx does — `autoApproveNewAccounts: false` — so the issuer has to sign for the confidential account before it can hold anything, and the demo does that rather than describing it. One field then separates the two mints: the key it holds cannot be scoped, and it is null on every live mint. | `./scripts/set-auditor.sh` — devnet |
 | **Let only chosen parties read it.** The auditor reads throughout; the market never does. | `cargo test` — I4 |
 | **Prove "this account holds at least X" — over the account's own on-chain ciphertext.** The counterparty learns one bit: not the value, not the composition, not any holding. Two proofs, because one does not exist: equality binds a commitment we can open to the account's ciphertext, then the range proof runs on the surplus. | `./scripts/prove-collateral.sh` — both accepted by Solana's live ZK ElGamal Proof Program |
 | **Bind a disclosure to a date and make it unrevisable.** The commitment is over the account's own on-chain ciphertext, so the 45 days are not merely a promise: a figure restated afterwards does not open it. | `./scripts/anchor-receipt.sh` — 147 bytes on devnet |
diff --git a/_submission/cwf-form.md b/_submission/cwf-form.md
index a5147d8..ddffe76 100644
--- a/_submission/cwf-form.md
+++ b/_submission/cwf-form.md
@@ -296,7 +296,7 @@ error the rest of this repository is built to prevent.
 ```
 Honestly: I do not know yet, and the measurements I have say something narrower than "people want this".
 
-What I can show. Kamino runs 19 live reserves in tokenized equity: $24.1m deposited, $85.5m of borrowing its own market owners authorised, and $0 of that reachable by a holder who will not publish what they hold — the deposit path refuses an account carrying confidential value (constraints.rs:187). Money already committed, under a constraint nobody chose.
+What I can show. Kamino runs 19 live reserves in tokenized equity: $24.1m deposited, $85.5m of borrowing its own market owners authorised, and $0 of that reachable by a holder who will not publish what they hold — the deposit path refuses an account carrying confidential value (constraints.rs:187). Money already committed, under a rule in Kamino's own code.
 
 What it does not show. 518,744 live accounts and two configured proves the feature is unused. It does not prove anyone wants it: the issuer must sign for each account and none has, so nobody has had the chance to want it.
 
@@ -320,7 +320,7 @@ Nothing is on mainnet. Nobody outside the repository has run any of it.
 ```
 Mostly they are not getting it wrong, and I would rather say so than manufacture a villain.
 
-Backed, Backpack and PreStocks ship tokenized equity on Token-2022 with confidential transfers on — 1,992 mints — and all leave autoApproveNewAccounts false. Not an oversight: turning it on lets anyone open an account they cannot see into.
+Backed, Backpack and PreStocks ship tokenized equity on Token-2022 with confidential transfers on — 1,992 mints — and all leave autoApproveNewAccounts false — the default, and sound: turning it on lets anyone open an account they cannot see into.
 
 Kamino refuses confidential collateral and is right to: a lender who cannot read a balance cannot price it. Their program requires the extensions inactive at deposit. Correct underwriting.
 
diff --git a/_submission/youtube-paste.txt b/_submission/youtube-paste.txt
index 6f512c4..73cd915 100644
--- a/_submission/youtube-paste.txt
+++ b/_submission/youtube-paste.txt
@@ -35,7 +35,7 @@ THE MEASUREMENT NOBODY HAD MADE
 
 All 1,992 tokenized-equity mints from three issuers' catalogues run Token-2022 with confidential transfers ON and the auditor key EMPTY. Every mint checked, not sampled.
 
-They did not miss it. The same 1,992 carry permanentDelegate, pausableConfig and a transfer hook — the issuer can freeze a transfer, seize a holder's tokens, run their own code. Token-2022's only disclosure model is mint-wide: one auditor key, reading every transfer while it is set, scoped to nobody. Everybody readable, or nobody. So every issuer left it empty.
+The same 1,992 carry permanentDelegate, pausableConfig and a transfer hook — the issuer can freeze a transfer, seize a holder's tokens, run their own code. Token-2022's only disclosure model is mint-wide: one auditor key, reading every transfer while it is set, scoped to nobody. Everybody readable, or nobody. Why it is empty is unmeasured: empty is also the default.
 
 Then the half nobody counted: has anybody USED it? 518,744 live token accounts across Apple, NVIDIA, SpaceX and AMC. TWO have configured a confidential account — one on NVDAx, one on AAPLx. ZERO are approved — none until an issuer signs.
 
diff --git a/_submission/youtube.md b/_submission/youtube.md
index a6f4b4b..95d1a43 100644
--- a/_submission/youtube.md
+++ b/_submission/youtube.md
@@ -19,7 +19,7 @@ missing scene back from the script.
 Confide — private block trades for tokenized stocks, settled in one Solana transaction
 ```
 
-## Description — 4981 / 5000 characters
+## Description — 4986 / 5000 characters
 
 ```
 Confide settles a tokenized-stock trade against stablecoins in ONE Solana transaction, and neither side publishes what moved. On devnet today.
@@ -52,7 +52,7 @@ THE MEASUREMENT NOBODY HAD MADE
 
 All 1,992 tokenized-equity mints from three issuers' catalogues run Token-2022 with confidential transfers ON and the auditor key EMPTY. Every mint checked, not sampled.
 
-They did not miss it. The same 1,992 carry permanentDelegate, pausableConfig and a transfer hook — the issuer can freeze a transfer, seize a holder's tokens, run their own code. Token-2022's only disclosure model is mint-wide: one auditor key, reading every transfer while it is set, scoped to nobody. Everybody readable, or nobody. So every issuer left it empty.
+The same 1,992 carry permanentDelegate, pausableConfig and a transfer hook — the issuer can freeze a transfer, seize a holder's tokens, run their own code. Token-2022's only disclosure model is mint-wide: one auditor key, reading every transfer while it is set, scoped to nobody. Everybody readable, or nobody. Why it is empty is unmeasured: empty is also the default.
 
 Then the half nobody counted: has anybody USED it? 518,744 live token accounts across Apple, NVIDIA, SpaceX and AMC. TWO have configured a confidential account — one on NVDAx, one on AAPLx. ZERO are approved — none until an issuer signs.
 
diff --git a/crates/confide-ct/src/lib.rs b/crates/confide-ct/src/lib.rs
index 7573748..7e5f3b2 100644
--- a/crates/confide-ct/src/lib.rs
+++ b/crates/confide-ct/src/lib.rs
@@ -379,8 +379,8 @@ mod invariants {
         );
     }
 
-    /// **S2 — a seizure is readable by the auditor.** The whole project is about a slot that is
-    /// empty because filling it discloses everything to one party forever. A seizure that the
+    /// **S2 — a seizure is readable by the auditor.** The whole project is about a slot whose only
+    /// setting other than empty discloses every transfer to one party. A seizure that the
     /// auditor could not read would be a hole in exactly the disclosure Confide argues for, so the
     /// third handle is checked rather than assumed to be wired up.
     #[test]
diff --git a/crates/confide-ct/src/set_auditor.rs b/crates/confide-ct/src/set_auditor.rs
index 801ef92..c821f79 100644
--- a/crates/confide-ct/src/set_auditor.rs
+++ b/crates/confide-ct/src/set_auditor.rs
@@ -4,8 +4,9 @@
 //! ours to configure. One instruction: `ConfidentialTransferInstruction::UpdateMint`.
 //!
 //! The point is not that setting a key is hard. It is that setting it is the *only* lever
-//! Token-2022 gives you, and it is all-or-nothing: whoever holds this key reads every holder's
-//! every transfer, forever. That is why the live mints leave it null. Confide exists so the key can
+//! Token-2022 gives you, and it is all-or-nothing: whoever holds this key can decrypt every holder's
+//! confidential transfers made while it is set. It is null on every live mint; why is not measured
+//! (docs/cwf-2026/THE-PINCER.md, 2026-09-27). Confide exists so the key can
 //! be held by something that discloses on terms instead of unconditionally.
 
 use base64::Engine;
diff --git a/crates/confide-equity/src/lib.rs b/crates/confide-equity/src/lib.rs
index 11cfbf6..26beae0 100644
--- a/crates/confide-equity/src/lib.rs
+++ b/crates/confide-equity/src/lib.rs
@@ -20,9 +20,9 @@ use solana_zk_sdk::encryption::elgamal::ElGamalKeypair;
 /// A tokenized equity, as configured on Solana mainnet.
 ///
 /// `auditor_elgamal_pubkey` is `None` on every one of them. That is the whole problem: the mint
-/// has confidential transfers switched on and the only disclosure model it offers — a single
-/// global key that decrypts everything forever — has no correct setting, so the slot sits empty
-/// and the feature goes unused.
+/// has confidential transfers switched on, the only disclosure model it offers is one mint-wide key
+/// that can decrypt every confidential transfer made while it is set, and with the slot empty no
+/// holder can show anything to anyone. Why it is empty is not measured; `None` is also the default.
 #[derive(Clone, Copy, Debug, PartialEq, Eq)]
 pub struct XStock {
     pub symbol: &'static str,
diff --git a/docs/ONCHAIN.md b/docs/ONCHAIN.md
index b5e61d4..18f47fb 100644
--- a/docs/ONCHAIN.md
+++ b/docs/ONCHAIN.md
@@ -187,10 +187,10 @@ a mirror that differed from NVDAx in two fields while the copy claimed one. `hea
 checks that field rather than trusting this paragraph.
 
 And that one field is the whole argument. Filling it is a single instruction — the difficulty was
-never the mechanics. The difficulty is that this key, once set, reads **every holder's every
-transfer, forever**, and cannot be scoped, delegated for a quarter, or pointed at one counterparty.
-That is why the live mints leave it null, and why filling it is only useful if something above it
-decides who sees what and when.
+never the mechanics. The difficulty is that this key, once set, can decrypt **every holder's every
+confidential transfer made while it is set**, and cannot be scoped, delegated for a quarter, or
+pointed at one counterparty. It is null on every live mint (why is not measured — see §8), and
+filling it is only useful if something above it decides who sees what and when.
 
 ## 7. An account whose key is ours
 
@@ -269,14 +269,15 @@ The issuer turned confidential transfers **on** for tokenized equities, gated ne
 accounts behind its own approval (`autoApproveNewAccounts: false`) — and left the auditor slot
 **empty**.
 
-That is not an oversight. It is the only available choice. Token-2022's disclosure model is a single
-global auditor key: **one key that decrypts everything, forever.** For a regulated equity issuer
-there is no setting of that key that is correct. Fill it and every holder's position is permanently
-readable by one party. Leave it null and no holder can demonstrate anything to anyone — so no
-regulated holder can use the feature at all.
+**Why it is empty is not measured.** `false` and `null` are also what a zero-initialised mint gets,
+so a shared template produces this configuration with nobody deciding anything
+([`THE-PINCER.md`](cwf-2026/THE-PINCER.md), 2026-09-27). What is measured is the substrate:
+Token-2022's disclosure model is a single global auditor key — **one key that decrypts every
+transfer made while it is set.** Fill it and every holder's transfers are readable by one party.
+Leave it null and no holder can demonstrate anything to anyone. There is no setting in between.
 
-So the feature is shipped, configured, and unused. Not because it is immature; because the only
-disclosure it offers is all-or-nothing.
+So the feature is shipped and unused, and the only disclosure it offers is all-or-nothing. Whether
+the second is the reason for the first is a question for an issuer, and nobody has asked one.
 
 **Confide is what makes that slot usable**: disclosure scoped by recipient, by granularity, and — the
 part nothing else has — **by schedule**. The auditor reads now. The public reads at `T`. The holder
diff --git a/docs/cwf-2026/COMPOSITION.md b/docs/cwf-2026/COMPOSITION.md
index 87fea3c..beac85e 100644
--- a/docs/cwf-2026/COMPOSITION.md
+++ b/docs/cwf-2026/COMPOSITION.md
@@ -102,10 +102,10 @@ freezeAuthority           2apBGMsS6ti9…    2apBGMsS6ti9…
 ```
 
 **This generalises the project's central finding past equities.** It has been *"1,992 tokenized
-equity mints ship a privacy feature nobody can use"*, which reads as two companies' decision. It is
-not: **PayPal's dollar and Paxos's Global Dollar ship the same feature with the same gate and the
-same empty auditor slot.** A regulated Token-2022 issuer, whatever they are issuing, arrives at this
-configuration — which is the substrate argument, now with a third and fourth independent witness.
+equity mints ship a privacy feature nobody can use"*. It is broader than equities: **PayPal's dollar
+and Paxos's Global Dollar ship the same feature with the same gate and the same empty auditor
+slot.** That widens what the measurement covers. It does not show why — the configuration is also
+the zero value of the mint struct ([`THE-PINCER.md`](THE-PINCER.md), 2026-09-27).
 
 **What it means for A, plainly:** a confidential stock-for-cash swap is possible on mainnet as a
 mechanism, and needs **two** issuers' approvals rather than one — the equity issuer for the stock
diff --git a/docs/cwf-2026/FOUNDER-MARKET-FIT.md b/docs/cwf-2026/FOUNDER-MARKET-FIT.md
index 8083b8e..d5613f1 100644
--- a/docs/cwf-2026/FOUNDER-MARKET-FIT.md
+++ b/docs/cwf-2026/FOUNDER-MARKET-FIT.md
@@ -87,9 +87,9 @@ Phrased for the form. Each is checkable against the repository.
 
 **What firsthand observation led to this problem?**
 That tokenized equity is new enough that the layer around it has not been built, and that the gap is
-visible on chain: 1,992 mints ship a privacy feature with its only key left empty, because the one
-disclosure model on offer — a global key reading everyone's everything, forever — is one no holder
-should accept and no issuer should hold.
+visible on chain: 1,992 mints ship a privacy feature with its only key left empty, and the one
+disclosure model on offer — a global key reading every transfer while it is set — has no setting
+between everyone and no one. Why the key is empty is not measured; empty is also the default.
 
 **What makes this founder credible in this market?**
 Not prior access to it. What can be shown is the work: an argument whose every number is recomputable
diff --git a/docs/cwf-2026/ISSUANCE-RUNS.md b/docs/cwf-2026/ISSUANCE-RUNS.md
index 1dce243..a176927 100644
--- a/docs/cwf-2026/ISSUANCE-RUNS.md
+++ b/docs/cwf-2026/ISSUANCE-RUNS.md
@@ -52,11 +52,21 @@ Both mints are created with **auditor `none`** — the configuration all 1,992 r
 is not a shortcut around the disclosure problem, it is the reason this particular flow works today:
 
 > **In primary issuance the issuer is the sender.** They can already read what they sent, so they
-> need no auditor key to see it. The empty slot blocks the **secondary** market, not this one.
+> need no auditor key to see it.
 
-It follows that the flow which runs unchanged on a mint configured the way the real ones are is
-**issuance**, and the flow that needs a disclosure mode Token-2022 does not have is **everything
-after it**.
+In the **secondary** market — investor to investor — the same empty slot means nobody but the two
+parties can read an amount, the issuer included. **Whether an issuer would accept that is not
+known**; nobody has been asked, and it is one of the founder's discovery questions
+(`CLAUDE-CODE-BRIEF.md` §3 P1). Technically the trade settles: `swap-e2e.sh` runs one between two
+approved holders.
+
+> **Corrected 2026-09-30.** This paragraph said *"the empty slot blocks the secondary market"*, and
+> that *"everything after [issuance]"* needs a disclosure mode Token-2022 does not have. Neither was
+> measured: nothing blocks the trade, and whether an issuer needs to see its amounts is a guess
+> about an issuer nobody asked.
+
+What does follow is narrower: **issuance** is the flow that runs unchanged on a mint configured the
+way the real ones are, *and* needs no answer to that question — the issuer is the sender.
 
 ## What this does not show
 
diff --git a/docs/cwf-2026/POST.md b/docs/cwf-2026/POST.md
index 3ad018a..e29f7cb 100644
--- a/docs/cwf-2026/POST.md
+++ b/docs/cwf-2026/POST.md
@@ -43,9 +43,10 @@ a post quoting a figure the page contradicts is worse than no post. Current read
 >
 > The reason is one field. `autoApproveNewAccounts` is **false on 1,992 of 1,992**, so a
 > confidential account cannot exist until the issuer signs for it, and no issuer has. And the only
-> disclosure model on offer is a single global auditor key that reads everyone's everything
-> forever — fill it and every holder is permanently readable by one party, leave it null and no
-> holder can prove anything to anyone. So it sits null, on every mint, at every issuer.
+> disclosure model on offer is a single mint-wide auditor key that can decrypt every confidential
+> transfer made while it is set — fill it and one party reads every holder's transfers, leave it
+> null and no holder can prove anything to anyone. It is null on every mint, at every issuer; why
+> is not measured, since null is also the default.
 >
 > **It is not an equities story.** USDC and USDT cannot move confidentially at all — legacy SPL, no
 > extensions. **PYUSD and USDG can**, and they land on the *identical* configuration: gate closed,
diff --git a/docs/cwf-2026/STORY.md b/docs/cwf-2026/STORY.md
index 6907bae..87fc1ac 100644
--- a/docs/cwf-2026/STORY.md
+++ b/docs/cwf-2026/STORY.md
@@ -55,7 +55,7 @@ No trust, no third party, no floor proof, and nothing revealed to anyone else.
 
 A confidential position needs a confidential account, and a confidential account needs the issuer's
 signature. `autoApproveNewAccounts` is `false` on **all 1,992** tokenized-equity mints — Backed,
-Backpack and PreStocks each arrived there independently — and the auditor slot, the one mechanism
+Backpack and PreStocks alike — and the auditor slot, the one mechanism
 for showing a balance to somebody who needs to see it, is empty on every one of them.
 
 So the honest answer is: **today, nobody.** And the second measurement says that is not a
@@ -80,9 +80,9 @@ same key on both (`2apBGMsS6ti9…`) as confidential authority, permanent delega
 authority. That the two are one issuer's is an inference from the shared key; that the
 configuration matches every equity mint is a reading.
 
-> PayPal's dollar ships the same unusable privacy feature behind the same gate. **Every regulated
-> Token-2022 issuer arrives here, whatever they are issuing** — four independent witnesses now,
-> across two asset classes.
+> PayPal's dollar ships the same unusable privacy feature behind the same gate. **Four issuers, two
+> asset classes, one configuration** — which is also the default a new mint gets, so it says what
+> ships, not why.
 
 ## 3. Every remaining obstacle is a named condition, not an unknown
 
diff --git a/docs/cwf-2026/WHAT-THE-WEEK-CHANGED.md b/docs/cwf-2026/WHAT-THE-WEEK-CHANGED.md
index 93908e9..a8ba02b 100644
--- a/docs/cwf-2026/WHAT-THE-WEEK-CHANGED.md
+++ b/docs/cwf-2026/WHAT-THE-WEEK-CHANGED.md
@@ -98,8 +98,8 @@ So the finding is no longer about one extension:
 > **Token-2022 ships two confidential capabilities. Every tokenized stock from three issuers'
 > catalogues carries the first and uses none of it; not one carries the second.**
 
-**And the same scan shows what they do adopt**, which makes the abstention deliberate rather than
-inattentive — these are not issuers who ignored the extension list:
+**And the same scan shows what else is on them.** It does not show who chose any of it, or whether
+anyone considered the auditor field ([`THE-PINCER.md`](THE-PINCER.md), 2026-09-27):
 
 | extension | mints |
 |---|---|
@@ -109,8 +109,8 @@ inattentive — these are not issuers who ignored the extension list:
 | **`confidentialMintBurn`** | **0** |
 
 **Seven extensions on every single mint.** The eighth is switched on and
-walled off, and the ninth was never turned on. That is a much harder thing to explain away than a
-count of unused accounts.
+walled off, and the ninth was never turned on. That is a stronger measurement than a count of unused
+accounts. It is still not a motive.
 
 ---
 
diff --git a/docs/cwf-2026/WHY-THE-SLOT-IS-EMPTY.md b/docs/cwf-2026/WHY-THE-SLOT-IS-EMPTY.md
index c4e77a8..a5eddf9 100644
--- a/docs/cwf-2026/WHY-THE-SLOT-IS-EMPTY.md
+++ b/docs/cwf-2026/WHY-THE-SLOT-IS-EMPTY.md
@@ -1,11 +1,12 @@
-# Why the auditor slot is empty — and why "use Token-2022 more" is the wrong ask
+# The empty auditor slot — and why "use Token-2022 more" is the wrong ask
 
 **The founder's question, 2026-09-22:** tokenized stock is booming on Solana, the custodian is off
 chain, confidential transfers are not really used — so for Solana to stay ahead, shouldn't issuers
 make better use of Token-2022?
 
-**The observation is right and the diagnosis is backwards.** Issuers are not under-using
-Token-2022. They are using almost all of it, on every mint, and exactly one thing is left off.
+**The observation is right; "under-using" does not fit what is on chain.** These mints carry almost
+every Token-2022 extension there is, and the one thing that is on but inert is the confidential
+balance. *Why* it is inert is not measured — see the correction below.
 
 ## What every tokenized stock from three issuers' catalogues actually has switched on
 
@@ -27,23 +28,32 @@ Generated by `./scripts/slot-roles.sh` from `web/slots.json`; re-run `./scripts/
 **Four control extensions on 1,992 of 1,992.** The issuer can move any holder's tokens
 (`permanentDelegate`), stop every transfer at once (`pausableConfig`), run its own code on every
 single transfer (`transferHook`), and decide that a new account starts restricted
-(`defaultAccountState`). Add `scaledUiAmountConfig` for dividends and splits and that is a mint
-configured by somebody who thought about it carefully.
+(`defaultAccountState`). Add `scaledUiAmountConfig` for dividends and splits.
 
-**These are not the settings of people who have not noticed Token-2022.**
+**That is a long way from "not using Token-2022".** It is not evidence of what anyone decided about
+the auditor slot.
 
-## And then the one they did not use
+## And then the one that is on and inert
 
 `confidentialTransferMint` is on all 1,992 too — and on all 1,992 the **auditor slot is empty** and
 **`autoApproveNewAccounts` is false**. Shipped, and inert.
 
-**Read it against the other four and it stops looking like neglect.** An issuer who wants a hook on
-every transfer and a delegate over every balance is an issuer whose whole configuration is about
-*seeing* and *reaching*. Confidential transfers with an empty auditor give the opposite: nobody sees
-anything, including them.
+> **Corrected 2026-09-30.** This section read the four control extensions as evidence of intent —
+> *"it stops looking like neglect"*, an issuer whose configuration is *"about seeing and reaching"* —
+> and closed on three issuers *"reaching the same configuration"* as something the substrate forces.
+> That is the reading this repository retracted on 2026-09-27
+> ([`THE-PINCER.md`](THE-PINCER.md#and-the-uniformity-is-not-evidence-of-a-decision--2026-09-27)):
+> an empty slot and a shut gate are also the **zero value** of the mint's confidential-transfer
+> struct, so a shared template or SDK produces them with nobody deciding. The 09-29 sweep that
+> removed the reading elsewhere missed the body of this file.
 
-So the question is not why they did not turn it on. It is **what they would have had to accept to
-turn it on.**
+**What can be said without a motive.** All 1,992 mints contain these control extensions. That does
+not show who chose their values, whether a template supplied them, or whether anyone considered the
+auditor field (Codex, 2026-09-30). Provenance could: cluster the mint-creation transactions by
+signer and deploying program. Nobody has.
+
+So the question this file asks is not why they left it empty. It is **what anyone would have had to
+accept to fill it** — which is a property of Token-2022, and is measurable.
 
 ## Token-2022 offers exactly one disclosure model
 
@@ -54,25 +64,28 @@ A single global auditor key that decrypts **everything, for everyone, forever.**
 | **fill the key** | every holder is permanently readable by whoever holds it. A transfer agent, a custodian, and anyone who ever compromises that key |
 | **leave it null** | no holder can demonstrate anything to anyone — not a balance to a lender, not a position to an auditor, not a holding to a counterparty |
 
-**For a regulated equity issuer there is no correct value.** So it sits empty, on 1,992 of 1,992,
-across three issuers with nothing to do with each other. Three independent parties reaching the same
-configuration is not an oversight; it is what the substrate forces.
+**Neither value lets one holder show one number to one party.** That is the construction problem
+below, and it holds however the slot came to be empty on 1,992 of 1,992. Whether a regulated
+issuer would find either value acceptable is a question for an issuer; nobody has been asked.
 
 ## Why that changes what the work is
 
 > **"Solana should use Token-2022 better" is a persuasion problem.**
-> **"The extension has no disclosure mode a regulated issuer can accept" is a construction problem.**
+> **"The extension has no disclosure mode between everyone and no one" is a construction problem.**
 
 The first depends on convincing issuers to adopt something. The second does not depend on anybody
 agreeing with anything: the missing piece is **disclosure scoped by recipient, by amount, and by
-occasion** — show *this* number to *that* party *once* — and until it exists the slot stays empty no
-matter how much anybody advocates.
+occasion** — show *this* number to *that* party *once* — and it does not exist today, however much
+anybody advocates.
 
 That is the position this repository is already in, and it is a stronger one than the question
 assumes, because it does not need an issuer to change their mind first. It needs the thing to exist.
 
 ## What this repository has NOT measured
 
+**Why the slot is empty.** Decision and default produce the same bytes, and nothing here tells them
+apart. Every sentence above is meant to hold under either.
+
 **That Solana leads in tokenized equity.** Every scan here reads Solana and only Solana. The premise
 that it is the pioneer, and the question of whether it stays one, are outside anything measured in
 this repository, and no submission should lean on them. Two claims already died this week for
diff --git a/docs/cwf-2026/x-post.tmpl b/docs/cwf-2026/x-post.tmpl
index 25a24dd..a816cfd 100644
--- a/docs/cwf-2026/x-post.tmpl
+++ b/docs/cwf-2026/x-post.tmpl
@@ -26,7 +26,7 @@ No issuer will approve one. autoApproveNewAccounts is false on {MINTS} of {MINTS
 
 Not an equities story either. PYUSD and USDG land on the identical configuration: gate shut, auditor slot empty. PayPal's dollar ships the same unusable privacy feature behind the same door.
 
-Four issuers, two asset classes, one dead end. Nobody chose this — it is what the substrate does.
+Four issuers, two asset classes, one configuration — and it is also the default a new mint gets, so it says what ships, not why.
 
 And no, you cannot just use a pool. Its reserves are public, and a trade moves them by exactly the amount traded — so anything settled against one publishes the size, whatever the token can do.
 
diff --git a/scripts/docs-consistency.sh b/scripts/docs-consistency.sh
index d13cce7..9ac1a51 100755
--- a/scripts/docs-consistency.sh
+++ b/scripts/docs-consistency.sh
@@ -616,6 +616,211 @@ for b in bad[:10]:
 sys.exit(1 if bad else 0)
 PY
 
+echo
+echo "  THE MOTIVE — what the issuers configured, never why"
+python3 - <<'PY' && ok "no live surface says why the auditor slot is empty" || bad "a surface claims a motive — docs/cwf-2026/THE-PINCER.md, 2026-09-27"
+import hashlib, re, subprocess, sys, pathlib
+
+# The empty auditor slot and the shut gate are also the ZERO VALUE of the mint's confidential-transfer
+# struct, so a shared template produces them with nobody deciding (THE-PINCER.md, 2026-09-27). The
+# 2026-09-29 sweep fixed nine surfaces by hand and added no check. On 09-30 the reading was still in
+# the published site, README, DESIGN, STORY, two crates' doc comments, the YouTube description, and
+# slot-scan.sh's own OUTPUT.
+#
+# The first version of this check listed phrasings, and Codex walked eleven live claims past it the
+# same day -- "each arrived there independently", "that is why the live mints leave it null",
+# "makes the abstention deliberate". A list of phrasings catches the phrasings its author thought
+# of. So the rules below are SHAPES of a claim, judged per paragraph:
+#
+#   CAUSE        the slot/key/field is empty or null, and the same paragraph gives a reason for it
+#   INDEPENDENCE "independent" said of the issuers, the mints, or a witness to the configuration
+#   INTENT       the configuration called deliberate, meant, or hard to explain away
+#   SECONDARY    the empty slot said to block the secondary market -- an issuer need nobody asked about
+#
+# The shapes are described rather than spelled where possible; THE POPULATION's first run matched
+# its own comment.
+SLOT = re.compile(r"auditor|slot|\bkey\b|\bfield\b|auditorElgamalPubkey|auditor_elgamal_pubkey", re.I)
+EMPTY = r"(?:empty|null|None|unset|inert)"
+# A reason attached to the emptiness, in the grammatical shapes it has actually taken here.
+# "... empty — because ...": needs the slot, the feature or Token-2022 named in the sentence, since
+# plenty of true sentences say an ACCOUNT is empty because of something.
+CAUSE_BECAUSE = re.compile(EMPTY + r"\b[^.]{0,80}?\bbecause\b", re.I)
+NAMES_IT = re.compile(SLOT.pattern + r"|feature|extension|Token-2022", re.I)
+# "that is why they leave it null", "so it sits empty": the shape alone is the claim, whatever "it" is.
+CAUSE_SHAPE = re.compile(
+    r"\b(?:that is why|which is why|the reason)\b[^.]{0,80}?\b(?:leave|leaves|left|stays?|sits?|keeps?)\b[^.]{0,30}?" + EMPTY +
+    r"|\bso\b(?![^.]{0,20}\bnothing\b)[^.]{0,40}?\b(?:sits?|left|leaves?|stays?|keeps?)\b[^.]{0,20}?" + EMPTY, re.I)
+# Verdicts. The strong ones are claims on their own; "not an oversight" only next to an empty slot.
+VERDICT_STRONG = re.compile(r"what the substrate (?:forces|does)|nobody chose|only available choice", re.I)
+VERDICT = re.compile(r"not an oversight", re.I)
+INDEPENDENCE = re.compile(r"\bindependent(?:ly)?\b(?!\s+(?:verifiab|verifi|checkab|of\b))", re.I)
+ABOUT_ISSUERS = re.compile(r"\bissuers?\b|\bparties\b|\bwitness|\barriv", re.I)
+INTENT = re.compile(
+    r"\bdeliberate(?:ly)?\b[^.]{0,60}\b(?:abstention|empty|null|configur|left|slot)"
+    r"|\b(?:abstention|configuration|slot)\b[^.]{0,60}\bdeliberate"
+    r"|picked null|declin\w* exactly one|looking like neglect|explain away|means to enable"
+    r"|did not miss it|thought about it carefully|have not noticed Token-2022", re.I)
+SECONDARY = re.compile(r"blocks? the \W*secondary", re.I)
+# Exempt per SENTENCE, never per paragraph -- a paragraph that mentions Kamino once must not excuse an
+# issuer claim three sentences later (Codex, 2026-09-30). Two exemptions: Kamino's code, where the
+# decision is written in the source; and OUR OWN mints (the mirror, the testbed), where the reason is
+# ours to state.
+EXEMPT = re.compile(r"Kamino|klend|underwrit|\blender\b|\bmirror|\btestbed\b|we control|not ours|our own", re.I)
+
+
+def sentences(t):
+    return [x for x in re.split(r"(?<=[.!?])\s+", t) if x]
+
+
+def claims(t):
+    out = []
+    ss = [x for x in sentences(t) if not EXEMPT.search(x)]
+    for x in ss:
+        if NAMES_IT.search(x) and CAUSE_BECAUSE.search(x):
+            out.append("CAUSE")
+        if CAUSE_SHAPE.search(x) or VERDICT_STRONG.search(x):
+            out.append("CAUSE")
+        if SLOT.search(x) and re.search(EMPTY, x) and VERDICT.search(x):
+            out.append("CAUSE")
+        if INDEPENDENCE.search(x) and ABOUT_ISSUERS.search(x):
+            out.append("INDEPENDENCE")
+        if INTENT.search(x):
+            out.append("INTENT")
+        if SECONDARY.search(x):
+            out.append("SECONDARY")
+    # A verdict in the sentence after the one naming the empty slot: "... left the slot empty. That
+    # is not an oversight." Also "So it sits null." after a sentence about the key.
+    for x, y in zip(ss, ss[1:]):
+        if SLOT.search(x) and re.search(EMPTY, x + " " + y) and VERDICT.search(y):
+            out.append("CAUSE")
+        # "Shipped, configured, inert. Not because it is immature: because ..."
+        if re.search(EMPTY, x) and NAMES_IT.search(x + " " + y) and re.match(r"(?:not\s+)?because\b", y, re.I):
+            out.append("CAUSE")
+    return out
+
+
+# THE CHECK'S OWN REGRESSION FIXTURES. Every MUST_FLAG line is a sentence that was live in this
+# repository on 2026-09-30, most of them after the first version of this check called the tree clean.
+# Every MUST_PASS line is a true sentence a looser rule would have silenced. A rule change that lets
+# one through fails the run here, before it can fail silently on the tree.
+MUST_FLAG = [
+    "Every one of them leaves the auditor key empty — because the only key on offer reads everyone's everything.",
+    "That is why the live mints leave it null, and why filling it is only useful if something decides.",
+    "One field then separates the two mints, and the reason that field stays null everywhere else is that the key cannot be scoped.",
+    "Backed, Backpack and PreStocks each arrived there independently — and the auditor slot is empty.",
+    "A regulated issuer arrives at this configuration, now with a third and fourth independent witness.",
+    "And the same scan shows what they do adopt, which makes the abstention deliberate rather than inattentive.",
+    "The only model has no correct setting, so the slot sits empty and the feature goes unused.",
+    "Leave it null and no holder can prove anything. So it sits null, on every mint, at every issuer.",
+    "No setting shows one balance to one regulator — so every issuer left it empty.",
+    "The issuer left the auditor slot empty. That is not an oversight.",
+    "Four issuers, two asset classes, one dead end. Nobody chose this — it is what the substrate does.",
+    "Three independent issuers, one configuration.",
+    "The empty slot blocks the secondary market, not this one.",
+    "Shipped, configured, inert. Not because it is immature: because Token-2022 offers one model.",
+    "The issuer left the auditor slot empty. That is not an oversight. It is the only available choice.",
+    "Four issuers, two asset classes, one configuration. It is what the substrate forces.",
+    "Leaving the auditor key null was the only available choice.",
+]
+MUST_PASS = [
+    "Kamino's refusal is correct underwriting, not an oversight.",
+    "It is null on every mint in the list — why is not measured, since null is also the default.",
+    "Fills the slot every xStock leaves empty — on a mint we control, because Backed's are not ours.",
+    "It works today only because all 1,992 tokenized-equity mints leave the slot null.",
+    "| independently verifiable | unknown |",
+    "BOTH auditor slots empty, matching all 1,992 live mints.",
+    "Token-2022 offers exactly one disclosure model, a single mint-wide auditor key.",
+    "The offsets decode to values already known independently — the liquidity mint at 128.",
+    "Token-2022 with no confidential-transfer extension at all, so there is nothing to leave empty.",
+    "Money already committed, under a rule in Kamino's own code.",
+]
+fx = [("should flag", l) for l in MUST_FLAG if not claims(l)] + \
+     [("should pass", l) for l in MUST_PASS if claims(l)]
+if fx:
+    for why, l in fx:
+        print("      the check itself is broken — %s: %s" % (why, l[:80]))
+    sys.exit(1)
+
+
+# FROZEN: published or submitted, so the claim stays and the file must not move. Pinned by content,
+# not by "still matches a pattern" -- a re-cut that changed the text would otherwise keep its
+# exemption (Codex, 2026-09-30). If one of these moves, re-read it and re-pin.
+frozen = {
+    "docs/cwf-2026/x-post.txt":                  ("52303ff47ccc00e4", "posted; the .tmpl it came from is corrected"),
+    "video/DELIVERED-20260922.md":               ("144770c310b02dae", "the record of a delivered cut"),
+    "video/captions-20260922.srt":               ("06f5db0a7a32a7af", "the caption track of that cut"),
+    "video/CWF-PRESENTATION.md":                 ("3629f0a2190a69a7", "recorded, published narration; re-recording is the founder's call"),
+    "video/captions-20260923.srt":               ("b5a4a3c6ea0d626d", "the caption track uploaded with that narration"),
+    "video/segments-presentation/LINES.md":      ("8417644637e94849", "recorded, published narration"),
+    "video/segments-presentation/manifest.json": ("76afa0a5da4f6138", "recorded, published narration"),
+    "video/voiceover.md":                        ("687f4e4e55aa7604", "narration of the published Stocklana cut"),
+    "video/captions.srt":                        ("fbe229c6d5a88c5f", "the caption track of that cut"),
+    "_submission/full.md":                       ("209a546f3d04c2dd", "Stocklana's submitted text; the edit window shut 2026-09-25"),
+}
+# The retraction itself has to name what it retracts, and it is a live document, so it is not pinned.
+retraction = "docs/cwf-2026/THE-PINCER.md"
+skip = re.compile(r"^docs/reviews/|^STATUS\.md$|^scripts/docs-consistency\.sh$")
+
+# Same citation rule as THE POPULATION: a quoted span is a citation, not a claim, so a correction can
+# print what it corrects. Not in JSON, where quotes are syntax. Codex noted a claim can hide in quotes;
+# that is the price of letting corrections quote, and the pinned files above are where it matters.
+QUOTED = re.compile(
+    r'&ldquo;.{0,300}?&rdquo;'
+    r'|`[^`]{0,300}?`'
+    r'|["\u201c\u201d\u300c\u300d][^"\u201c\u201d\u300c\u300d]{0,300}?'
+    r'["\u201c\u201d\u300c\u300d]', re.S)
+
+files = subprocess.run(["git", "ls-files", "-z", "--cached", "--others", "--exclude-standard"],
+                       capture_output=True, text=True).stdout.split("\0")
+bad = []
+for f in filter(None, files):
+    if skip.match(f):
+        continue
+    p = pathlib.Path(f)
+    if p.suffix in (".png", ".jpg", ".jpeg", ".mp4", ".ico", ".pdf") or not p.exists():
+        continue
+    if f in frozen:
+        h = hashlib.sha256(p.read_bytes()).hexdigest()[:16]
+        if h != frozen[f][0]:
+            bad.append("%s is pinned as frozen (%s) and has changed — re-read it, then re-pin" % (f, frozen[f][1]))
+        continue
+    try:
+        lines = p.read_text(encoding="utf-8").splitlines()
+    except (UnicodeDecodeError, OSError):
+        continue
+    # PARAGRAPHS, not lines: narration wraps a clause across two lines. A caption track splits one
+    # sentence across cues, so its text is read as one stream with cue numbers and timecodes dropped.
+    if p.suffix == ".srt":
+        lines = [" ".join(l for l in lines if l.strip() and not re.match(r"^\d+$|^\d\d:\d\d", l.strip()))]
+    paras, cur, start = [], [], 1
+    for i, l in enumerate(lines + [""], 1):
+        if l.strip() in ("", ">"):
+            if cur:
+                paras.append((start, " ".join(cur)))
+            cur = []
+            continue
+        if not cur:
+            start = i
+        cur.append(re.sub(r"^\s*(?:>\s*|#+\s*|//+!?\s*|///?\s*|\*\s+|-\s+)", "", l).strip())
+    hits = []
+    for n, text in paras:
+        t = QUOTED.sub(" ", text) if p.suffix != ".json" else text
+        c = claims(t)
+        if c:
+            hits.append((n, c[0], t))
+    if f == retraction:
+        if not hits:
+            bad.append("%s no longer names what it retracts — was the retraction removed?" % f)
+        continue
+    for n, kind, t in hits:
+        bad.append("%s:%d %s: %s" % (f, n, kind, t[:80]))
+for b in bad[:15]:
+    print("      " + b)
+if len(bad) > 15:
+    print("      ... and %d more" % (len(bad) - 15))
+sys.exit(1 if bad else 0)
+PY
+
 echo
 echo "  THE MARKET TOTALS — prose against the file that computes them"
 python3 - <<'PY' && ok "every quoted \$m figure matches web/capacity.json" || bad "a quoted \$m figure has drifted from web/capacity.json — ./scripts/capacity.sh, then fix the prose"
diff --git a/scripts/issue-e2e.sh b/scripts/issue-e2e.sh
index a9016b5..a1b4722 100755
--- a/scripts/issue-e2e.sh
+++ b/scripts/issue-e2e.sh
@@ -40,8 +40,10 @@
 #
 # AND THE AUDITOR SLOT STAYS EMPTY, exactly as it is on all 1,992. That is not a shortcut: in
 # primary issuance the issuer IS the sender, so they can already read what they sent and need no
-# auditor key to see it. The empty slot blocks the SECONDARY market, not this one — which is why
-# this is the flow that runs today on a mint configured the way the real ones are.
+# auditor key to see it. In the SECONDARY market -- investor to investor -- nobody but the two
+# parties could read an amount. Whether an issuer would accept that is unasked; it is a question for
+# the founder's conversations (brief §3 P1), not something this script shows. What this script
+# shows is the flow that runs today on a mint configured the way the real ones are.
 set -euo pipefail
 cd "$(dirname "$0")/.."
 . "$(dirname "$0")/lib/chain.sh"
diff --git a/scripts/refresh-mints.sh b/scripts/refresh-mints.sh
index f740608..652d499 100755
--- a/scripts/refresh-mints.sh
+++ b/scripts/refresh-mints.sh
@@ -11,11 +11,12 @@
 #
 # PreStocks matters more than its eight mints suggest. Backed and Backpack both tokenize LISTED
 # equity; PreStocks tokenizes companies with no public market at all — SpaceX, OpenAI, Anthropic,
-# Neuralink. A third issuer, arriving independently at the same confidential-transfer configuration
-# in a different asset class, is what turns "two issuers did the same thing" into a property of the
-# substrate rather than a coincidence between two companies.
+# Neuralink. A third issuer carrying the same confidential-transfer configuration in a different
+# asset class widens what the measurement covers. It does not show how the three got there: the
+# configuration is also the struct's zero value, so a shared template or SDK
+# would produce it with nobody deciding (docs/cwf-2026/THE-PINCER.md, 2026-09-27).
 #
-# Tessera is deliberately NOT here and its absence is the point: its T-SpaceX, T-OpenAI and
+# Tessera is left out on purpose and its absence is the point: its T-SpaceX, T-OpenAI and
 # T-Kalshi are Token-2022 with no confidential-transfer extension at all, so there is nothing to
 # leave empty and nothing Confide can say about them. Checked on mainnet 2026-09-19. Not every
 # issuer enables this — which is why the claim is about the ones that do.
diff --git a/scripts/slot-scan.sh b/scripts/slot-scan.sh
index 90d7520..06fd50a 100755
--- a/scripts/slot-scan.sh
+++ b/scripts/slot-scan.sh
@@ -6,7 +6,10 @@
 #   Backed Finance (xStocks)  — Swiss-issued, own ISIN
 #   Backpack Securities       — US CUSIP, a security entitlement by the issuer's own description
 #
-# Two independent issuers reaching the same configuration is the finding. One would be a quirk.
+# Every issuer in the list carrying the same configuration is the finding. It is NOT evidence that
+# each one decided it: the empty slot and the shut gate are also the zero value of the mint's
+# confidential-transfer struct, so a shared template produces them with nobody choosing
+# (docs/cwf-2026/THE-PINCER.md, 2026-09-27).
 #
 #   ./scripts/slot-scan.sh
 #
@@ -67,7 +70,7 @@ print('\n  every one of them: confidential transfers on, no auditor key.')
 # Derived. It said "Two issuers" for as long as there were two, and PreStocks made it wrong
 # without making it fail — the exact shape of every other stale number in this repository.
 n_iss = len({m.get('issuer', '?') for m in mints})
-print('  %d issuers, independently, reaching the same dead end.' % n_iss)
+print('  %d issuers, the same configuration. Why is not measured: it is also the default.' % n_iss)
 
 # The approval gate, which is the other half of the pincer.
 #
diff --git a/scripts/testbed-up.sh b/scripts/testbed-up.sh
index c8289e7..4e78435 100755
--- a/scripts/testbed-up.sh
+++ b/scripts/testbed-up.sh
@@ -112,7 +112,7 @@ mk() { # mk <role> <decimals> <auditor set|none> [extra flags…]
 }
 echo
 echo "  ${bold}--- two mints, configured as the live ones are ---${off}"
-# BOTH auditor slots empty, because that is what all 1,992 live mints do. The first run of this
+# BOTH auditor slots empty, matching all 1,992 live mints. The first run of this
 # filled the equity one — copying Confide's own demo mint, which fills it deliberately to show what
 # a usable slot is worth, rather than copying the thing being mirrored. `--check` caught it.
 mk equity 8 none
diff --git a/video/demo.html b/video/demo.html
index ca4aa52..1f98336 100644
--- a/video/demo.html
+++ b/video/demo.html
@@ -353,8 +353,8 @@ async function slot(s){
    +'<div class="lede fade" style="margin-top:30px;font-size:22px">'
    +'<b>All '+(s.mints||'1,869')+' of them.</b> The privacy is already shipped and nobody can use it &mdash; '
    +'the only key on offer reads <span class="hl">everyone\'s everything, forever</span>.</div>'
-   +'<div class="cap fade" style="margin:14px 0 0">One issuer would be a quirk. '
-   +((s.issuers||2)>2?'Three':'Two')+', independently, is the problem.</div></div>');
+   +'<div class="cap fade" style="margin:14px 0 0">'
+   +((s.issuers||2)>2?'Three':'Two')+' issuers, one configuration &mdash; which is also the default.</div></div>');
   await sleep(80); await reveal(els,180); await out(rest(s,t0));
 }
 async function views(s){
@@ -543,7 +543,7 @@ async function privacyGap(s){
     +'<div class="missing-key fade"><div class="keyhole">⌁</div><b>NO SELECTIVE AUDIT KEY</b><span>all balances, or none</span></div>'
     +'<div class="capability fade"><div class="tiny">holder choice</div><strong>Show a lender enough<br>Show an auditor enough<br>Keep the market blind</strong></div></div>'
     +'<div class="source fade">Token-2022 confidential transfers · the same empty auditor slot across '
-    +s.issuers+' independent issuers</div></div>');
+    +s.issuers+' issuers</div></div>');
   await sleep(80); await reveal(els,340); await out(rest(s,t0));
 }
 async function issuerGate(s){
diff --git a/web/index.html b/web/index.html
index b65a622..2d91202 100644
--- a/web/index.html
+++ b/web/index.html
@@ -239,9 +239,10 @@ b.bad{color:var(--red)}b.good{color:var(--grn)}
   <section>
     <h2>Why no issuer's mint escapes it</h2>
     <div class="lede">1,992 tokenized stocks from three issuers' catalogues run on Token-2022 with confidential transfers
-    <b>switched on</b>. Every one of them leaves the auditor key <b>empty</b> — because the only key
-    on offer reads everyone's everything, forever, and no setting of that is correct for a regulated
-    issuer.</div>
+    <b>switched on</b>, and every one of them leaves the auditor key <b>empty</b>. The only key on
+    offer is mint-wide: it can decrypt the amount of every confidential transfer made while it is set,
+    and cannot be pointed at one holder or one reader. Why the slots are empty is not measured &mdash;
+    empty is also the default a new mint gets.</div>
     <div class="cards" id="slots"></div>
     <div class="note">Read from mainnet, just now, by your browser. <b>NVDAx</b> and <b>TSLAx</b> are
     Backed's; <b>NVDA.US</b> and <b>AAPL.US</b> are Backpack Securities'. Three issuers, the same empty
```
