# Review request — removing "why the auditor slot is empty" from live surfaces, 2026-09-30

## Background

On 2026-09-27 this repository retracted the reading that the issuers *chose* the empty auditor slot
and shut approval gate: `false`/`null` are the zero value of the confidential-transfer mint struct,
so a shared template yields them with nobody deciding (`docs/cwf-2026/THE-PINCER.md`, section
"And the uniformity is not evidence of a decision — 2026-09-27"). Commit `e64abe5` (09-29) says it
removed the reading from nine surfaces. It added no check.

Today, while answering the founder, **I (Claude) cited `WHY-THE-SLOT-IS-EMPTY.md:40-59` as
circumstantial evidence of issuer intent** — the file still carried the retracted reading in its body.
A sweep then found it in: README ("They did not miss it … So every issuer left it empty"), the live
YouTube description, `ONCHAIN.md` §8 ("not an oversight … the only available choice"), the CWF
form draft, `FOUNDER-MARKET-FIT.md` ("empty, because …"), a Rust doc comment, `slot-scan.sh`'s
**runtime output** ("N issuers, independently, reaching the same dead end"), `refresh-mints.sh`,
`video/demo.html` (twice), and `x-post.tmpl`. Separately, `ISSUANCE-RUNS.md:55` and
`issue-e2e.sh:43` said "the empty slot blocks the secondary market" — an asserted issuer need that
nobody asked about (technically the investor-to-investor swap settles: `swap-e2e.sh`).

## What changed

- Each live surface: measurement kept, motive dropped, "why is not measured; empty is also the
  default" where a sentence was needed, pointing at THE-PINCER.
- `WHY-THE-SLOT-IS-EMPTY.md`: title no longer claims the why; a dated correction; the intent
  paragraphs rewritten; "What this repository has NOT measured" gains "why the slot is empty".
- `ISSUANCE-RUNS.md`: dated correction; secondary market stated as settling technically, issuer
  acceptance as unknown (a founder discovery question, brief §3 P1).
- New check **THE MOTIVE** in `scripts/docs-consistency.sh`: git-listed files, paragraph-level
  (narration wraps a clause across lines), .srt read as one stream (cues split sentences), quoted
  spans are citations, "not an oversight" flagged only near issuer/auditor/slot words and not near
  Kamino/underwriting/lender/instruction, allowlist with a reason per entry that fails when it expires.
- Allowlisted (published/frozen, not edited): x-post.txt, Stocklana `_submission/full.md`,
  `video/voiceover.md` + `video/captions.srt` (published Stocklana cut),
  `video/DELIVERED-20260922.md` + `captions-20260922.srt`, and the recorded CWF presentation
  narration (`CWF-PRESENTATION.md`, `captions-20260923.srt`, `segments-presentation/LINES.md`,
  `manifest.json`: "No setting shows one balance to one regulator — so every issuer left it empty").
  Re-recording is the founder's call.
- Broken on purpose, each seen failing: one line, wrapped blockquote, .srt split across cues,
  "not an oversight" about an issuer, "independent issuers", "empty, because the only key…",
  allowlist expiry. Quoted citation and the Kamino sense pass.
- `youtube-paste.txt` regenerated into a temp file, checked, then copied (the generator refused the
  first draft at 5,034 chars). `youtube.md`'s hand-typed heading count updated 4981 → 4986.
  CWF form field back under 1,000. The YouTube description and the CWF form now differ from what was
  pasted — the founder must re-paste; the existing check reports that.

## Questions — adversarial, please

1. **Did I over-correct into underclaim?** On 09-29 you found a fix for overclaim that became
   underclaim. Is anything true now stated too weakly — e.g. the disclosure-model fact (Token-2022
   offers only a mint-wide key) or the Kamino finding — or is the "why is not measured" line now
   repeated so often it reads as hedging on measured facts?
2. Is any rewritten sentence still a motive or causal claim in disguise? Read README "Why nobody has
   built it" — does the heading itself now overclaim, since the paragraph no longer says why?
3. `WHY-THE-SLOT-IS-EMPTY.md` new line: "The control extensions show that these mints were
   configured with more than defaults somewhere." Is that supported, or is it the same inference in
   a smaller coat?
4. Are there live surfaces the check misses? (`web/index.html` passed; check phrasing shapes I did
   not think of.) Is any allowlist entry wrong — e.g. is `FOUNDER-MARKET-FIT.md` or any other file
   already pasted somewhere and so should be frozen rather than edited?
5. The check's false-positive/negative design: paragraph joining, the Kamino exclusion, the .srt
   stream. Can a real claim hide behind the exclusion words?
6. The CWF presentation narration is allowlisted as published. Should the repo recommend
   re-recording that one clause before 10-12, given CWF judges will watch it?

## The diff

```diff
diff --git a/README.md b/README.md
index c6953f3..c63e6b4 100644
--- a/README.md
+++ b/README.md
@@ -27,11 +27,13 @@ off it — and is **not a venue**, so the exemption neither covers it nor is nee
 
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
 
diff --git a/_submission/cwf-form.md b/_submission/cwf-form.md
index a5147d8..4a0cc57 100644
--- a/_submission/cwf-form.md
+++ b/_submission/cwf-form.md
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
diff --git a/docs/ONCHAIN.md b/docs/ONCHAIN.md
index b5e61d4..2be9604 100644
--- a/docs/ONCHAIN.md
+++ b/docs/ONCHAIN.md
@@ -269,14 +269,15 @@ The issuer turned confidential transfers **on** for tokenized equities, gated ne
 accounts behind its own approval (`autoApproveNewAccounts: false`) — and left the auditor slot
 **empty**.
 
-That is not an oversight. It is the only available choice. Token-2022's disclosure model is a single
-global auditor key: **one key that decrypts everything, forever.** For a regulated equity issuer
-there is no setting of that key that is correct. Fill it and every holder's position is permanently
-readable by one party. Leave it null and no holder can demonstrate anything to anyone — so no
-regulated holder can use the feature at all.
-
-So the feature is shipped, configured, and unused. Not because it is immature; because the only
-disclosure it offers is all-or-nothing.
+**Why it is empty is not measured.** `false` and `null` are also what a zero-initialised mint gets,
+so a shared template produces this configuration with nobody deciding anything
+([`THE-PINCER.md`](cwf-2026/THE-PINCER.md), 2026-09-27). What is measured is the substrate:
+Token-2022's disclosure model is a single global auditor key — **one key that decrypts every
+transfer made while it is set.** Fill it and every holder's transfers are readable by one party.
+Leave it null and no holder can demonstrate anything to anyone. There is no setting in between.
+
+So the feature is shipped and unused, and the only disclosure it offers is all-or-nothing. Whether
+the second is the reason for the first is a question for an issuer, and nobody has asked one.
 
 **Confide is what makes that slot usable**: disclosure scoped by recipient, by granularity, and — the
 part nothing else has — **by schedule**. The auditor reads now. The public reads at `T`. The holder
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
 
diff --git a/docs/cwf-2026/WHY-THE-SLOT-IS-EMPTY.md b/docs/cwf-2026/WHY-THE-SLOT-IS-EMPTY.md
index c4e77a8..f9bdc37 100644
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
+**What can be said without a motive.** The control extensions show that these mints were configured
+with more than defaults somewhere. They do not show that anyone looked at the auditor slot, and
+nothing here can tell a decision from a default. Provenance could: cluster the mint-creation
+transactions by signer and deploying program. Nobody has.
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
+below, and it holds whatever the reason the slot is empty on 1,992 of 1,992. Whether a regulated
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
index d13cce7..91a83cd 100755
--- a/scripts/docs-consistency.sh
+++ b/scripts/docs-consistency.sh
@@ -616,6 +616,112 @@ for b in bad[:10]:
 sys.exit(1 if bad else 0)
 PY
 
+echo
+echo "  THE MOTIVE — what the issuers configured, never why"
+python3 - <<'PY' && ok "no live surface says why the auditor slot is empty" || bad "a surface claims a motive — docs/cwf-2026/THE-PINCER.md, 2026-09-27"
+import re, subprocess, sys, pathlib
+
+# The empty auditor slot and the shut gate are also the ZERO VALUE of the mint's confidential-transfer
+# struct, so a shared template produces them with nobody deciding (THE-PINCER.md, 2026-09-27). The
+# 2026-09-29 sweep fixed nine surfaces by hand and added no check; on 09-30 the body of the file
+# named after the question still carried the retracted reading, the README and the YouTube
+# description still said why, and slot-scan.sh PRINTED it on every run. This is that check.
+#
+# The shapes are described rather than spelled, for the reason THE POPULATION gives: the first run
+# of that check matched its own comment.
+pats = [
+    # independence: "N independent issuers", "issuers ... independently", "arriving independently"
+    re.compile(r"\bindependent(?:ly)?\s+(?:issuers|parties)\b|\bissuers?\b[^.]{0,50}\bindependently\b"
+               r"|\barriv\w*\s+independently", re.I),
+    # the retracted phrasings, each seen live at least once
+    re.compile(r"picked null|declin\w* exactly one|configured deliberately|looking like neglect"
+               r"|what the substrate (?:forces|does)|nobody chose this|only available choice"
+               r"|did not miss it|who thought about it carefully|have not noticed Token-2022", re.I),
+    # a cause attached to the empty slot: "... so every issuer left it empty"
+    re.compile(r"\bso (?:every|all|each)\b[^.]{0,40}\bleft it (?:empty|null)"
+               r"|\bempty,?\s+because\s+(?:filling|the only|the one)\b", re.I),
+    # the secondary-market claim, which asserted an issuer need nobody had asked about
+    re.compile(r"blocks the \W*secondary", re.I),
+]
+# "not an oversight" is fine about Kamino's code, where the decision is written down, and wrong
+# about an issuer's configuration, where it is not. Judged per paragraph.
+oversight = re.compile(r"not an oversight", re.I)
+about_issuer = re.compile(r"issuer|auditor|slot|autoApprove|auto_approve", re.I)
+about_code = re.compile(r"Kamino|underwrit|lender|instruction", re.I)
+
+# Each of these still says it, on purpose. The reason is the entry, as in THE POPULATION.
+allowed = {
+    "docs/cwf-2026/THE-PINCER.md":             "the retraction, which has to name what it retracts",
+    "docs/cwf-2026/x-post.txt":                "posted and uneditable; the .tmpl it came from is corrected",
+    "video/DELIVERED-20260922.md":             "the record of a cut that was delivered",
+    "video/captions-20260922.srt":             "the caption track of that delivered cut",
+    "video/CWF-PRESENTATION.md":               "recorded and published narration; re-recording is the founder's call",
+    "video/captions-20260923.srt":             "the caption track uploaded with that narration",
+    "video/segments-presentation/LINES.md":    "recorded and published narration; re-recording is the founder's call",
+    "video/segments-presentation/manifest.json": "recorded and published narration; re-recording is the founder's call",
+    "video/voiceover.md":                      "narration of the published Stocklana cut",
+    "video/captions.srt":                      "the caption track of that published cut",
+    "_submission/full.md":                     "Stocklana's submitted text; the edit window shut 2026-09-25",
+}
+skip = re.compile(r"^docs/reviews/|^STATUS\.md$|^scripts/docs-consistency\.sh$")
+
+# Same citation rule as THE POPULATION: a quoted span is a citation, not a claim, so a correction
+# can print what it corrects. Not in JSON, where quotes are syntax.
+QUOTED = re.compile(
+    r'&ldquo;.{0,300}?&rdquo;'
+    r'|`[^`]{0,300}?`'
+    r'|["“”「」][^"“”「」]{0,300}?'
+    r'["“”「」]', re.S)
+
+files = subprocess.run(["git", "ls-files", "--cached", "--others", "--exclude-standard"],
+                       capture_output=True, text=True).stdout.split()
+found, bad = set(), []
+for f in files:
+    if skip.match(f):
+        continue
+    p = pathlib.Path(f)
+    if p.suffix in (".png", ".jpg", ".jpeg", ".mp4", ".ico", ".pdf") or not p.exists():
+        continue
+    try:
+        lines = p.read_text(encoding="utf-8").splitlines()
+    except (UnicodeDecodeError, OSError):
+        continue
+    # PARAGRAPHS, not lines. The narration this was written against wraps its clause across two
+    # lines -- "... so every issuer left it" / "> empty." -- and a line-based check walks past it.
+    paras, cur, start = [], [], 1
+    # A caption track splits one sentence across cues -- "to one regulator — so every" / "issuer left
+    # it empty." -- so its text is read as one stream, cue numbers and timecodes dropped.
+    if p.suffix == ".srt":
+        lines = [" ".join(l for l in lines if l.strip() and not re.match(r"^\d+$|^\d\d:\d\d", l.strip()))]
+    for i, l in enumerate(lines + [""], 1):
+        if l.strip() in ("", ">"):
+            if cur:
+                paras.append((start, " ".join(cur)))
+            cur = []
+            continue
+        if not cur:
+            start = i
+        cur.append(re.sub(r"^\s*(?:>\s*|#+\s*|//\s*|\*\s+)", "", l).strip())
+    for n, text in paras:
+        t = QUOTED.sub(" ", text) if p.suffix != ".json" else text
+        hit = any(x.search(t) for x in pats)
+        if not hit and oversight.search(t) and about_issuer.search(t) and not about_code.search(t):
+            hit = True
+        if hit:
+            found.add(f)
+            if f not in allowed:
+                bad.append("%s:%d says why: %s" % (f, n, t[:90]))
+
+# An entry that no longer carries the claim means the file was re-cut or corrected and the reason
+# has expired.
+for f, why in sorted(allowed.items()):
+    if f not in found:
+        bad.append("%s no longer says it — drop the allowlist entry (%s)" % (f, why))
+for b in bad[:12]:
+    print("      " + b)
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
index f740608..ad8f8da 100755
--- a/scripts/refresh-mints.sh
+++ b/scripts/refresh-mints.sh
@@ -11,9 +11,10 @@
 #
 # PreStocks matters more than its eight mints suggest. Backed and Backpack both tokenize LISTED
 # equity; PreStocks tokenizes companies with no public market at all — SpaceX, OpenAI, Anthropic,
-# Neuralink. A third issuer, arriving independently at the same confidential-transfer configuration
-# in a different asset class, is what turns "two issuers did the same thing" into a property of the
-# substrate rather than a coincidence between two companies.
+# Neuralink. A third issuer carrying the same confidential-transfer configuration in a different
+# asset class widens what the measurement covers. It does not show the three arrived there
+# independently: the configuration is also the struct's zero value, so a shared template or SDK
+# would produce it with nobody deciding (docs/cwf-2026/THE-PINCER.md, 2026-09-27).
 #
 # Tessera is deliberately NOT here and its absence is the point: its T-SpaceX, T-OpenAI and
 # T-Kalshi are Token-2022 with no confidential-transfer extension at all, so there is nothing to
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
```
