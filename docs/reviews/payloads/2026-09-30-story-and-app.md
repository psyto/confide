# Review request — the agreed story, and the demo-app design, 2026-09-30

The founder agreed today to: (1) one story order — measured problem → what is and is not known about
why → what Confide is → what runs → boundaries; (2) the demo opens on **issuance** (issuer →
investor), not holder-to-holder; (3) the demo is shown through a **local web app** (issuer console,
investor wallet, observer), web only, proofs and keys on a local server. Recommendations the founder
did not explicitly rule on, which I have written in as such: the "issuer is the first buyer" claim is
stated as an untested hypothesis (the brief names the issuer as first buyer; THE-PINCER records the
opposite reading from 09-16); the secondary market is "technically runs, issuer acceptance unknown".

Binding context: `docs/cwf-2026/CLAUDE-CODE-BRIEF.md` (the founder's positioning brief, untracked
but authoritative), `CLAUDE.md`, `STATUS.md` (latest sections 09-30 (7) and (8)).

## Files

- `docs/cwf-2026/STORY.md` — rewritten (diff below). Old §1 (the swap) moved into §4 as "also runs";
  new §2 separates known from not known; new §3 is the brief's product sentence; §4 is the
  issuance demo in script order; the named-conditions table gains a row for "what the issuer needs
  to see"; §8 adds the buyer hypothesis, devnet/local-keys, and the unknowns; §9 is the brief's
  discovery questions. TESTBED.md and testbed-up.sh referenced "STORY §3" by number; now by heading.
- `docs/cwf-2026/DEMO-APP.md` — new design (full text below).

## Questions — adversarial

1. **Does STORY.md now say anything the evidence does not support, or understate something it does?**
   Check each figure and claim against the files it names. In particular §1 "A tokenized-stock
   position on Solana is public", §2's auditor description, §3's "What stays public", and §4's
   claim that steps other than 5 and 7 have run on devnet (see STATUS 09-30 (5)).
2. Does the new order serve the brief's six judgments (§6 of the brief)? Is anything a judge needs
   missing, or anything present that the brief says to defer?
3. Is the §8 treatment of the buyer question right, given the brief is the founder's later word
   (09-27) and THE-PINCER's reversal is 09-16? Is "hypothesis" an underclaim of the founder's
   decision, or the honest reading?
4. **DEMO-APP.md**: is "the app runs issue-e2e.sh and only displays" actually achievable with the two
   hooks described (events file, FIFO pause)? Where could the app still end up deciding something —
   e.g. inferring "refused" from the event stream rather than the script's exit code? Is the
   falsification check (compare terminal output with and without CONFIDE_EVENTS) sufficient?
5. Security of the local server as designed: RPC key exposure, work-directory exposure, the observer
   read proxy, 127.0.0.1 binding, FIFO handling. Anything missing?
6. Anything in the web-app plan that conflicts with the 27-DAYS refused list or the brief's
   "do not" list, or that would overclaim on screen?

## STORY / reference diff

```diff
diff --git a/docs/TESTBED.md b/docs/TESTBED.md
index b4c72a7..8718171 100644
--- a/docs/TESTBED.md
+++ b/docs/TESTBED.md
@@ -19,7 +19,7 @@ nothing. Nothing here makes a real xStock pledgeable, and the `$0` reachable con
 Kamino's `$85.5m` of authorised borrowing is unchanged.
 
 **What it is:** the demonstration that **the issuer gate is an operations decision rather than a
-protocol problem.** [`cwf-2026/STORY.md`](cwf-2026/STORY.md) §3 lists that as the first of the
+protocol problem.** [`cwf-2026/STORY.md`](cwf-2026/STORY.md) (*Every remaining obstacle is a named condition*) lists that as the first of the
 named conditions standing between what runs and a market. This runs it.
 
 The mints keep `autoApproveNewAccounts: false` — exactly what **all 1,992** live tokenized-equity
diff --git a/docs/cwf-2026/STORY.md b/docs/cwf-2026/STORY.md
index 87fc1ac..e92be6a 100644
--- a/docs/cwf-2026/STORY.md
+++ b/docs/cwf-2026/STORY.md
@@ -1,8 +1,16 @@
 # The story
 
-The one place the narrative lives. The submission text and the video narration both draw from here,
-so they cannot drift from each other — and every figure below is in a file that a stranger can
-recompute.
+The one place the narrative lives. The submission text, the two videos and the demo app all draw
+from here, so they cannot drift from each other — and every figure below is in a file that a
+stranger can recompute.
+
+> **Agreed with the founder, 2026-09-30.** The order below — measured problem, what is and is not
+> known about why, what Confide is, what runs, then the boundaries — is the order every surface
+> follows. The demo opens on **issuance** (the issuer allocating to an investor), not on a swap
+> between two holders, because issuance is where the issuer's gate can be shown refusing and then
+> opening. It is shown through **a local web app** — an issuer console, an investor wallet and an
+> observer — driving the same code the scripts run. The previous version of this file opened on the
+> holder-to-holder swap; that swap still runs and is in §4.
 
 **The shape of the argument, before the argument:** a specific thing runs today; the obstacles
 between it and a real market are not unknowns but **named conditions with numbers attached**; and
@@ -12,54 +20,14 @@ opportunity.
 
 ---
 
-## 1. What runs today
+## 1. What is happening — measured
 
-**A stock-to-stablecoin swap in one transaction, with neither side publishing what moved.**
-Nothing of ours runs *inside* the trade — two Token-2022 instructions and two signatures. **What Confide does is everything around it**: the zero-knowledge proofs the chain will not assemble for you, verified on chain and citable by address, and the check that lets each side read the other's amount before signing.
-
-```
-stock for stock   2RksP5AM…   29,417 compute units   1,006 bytes
-stock for cash    4gzku3FW…   29,849 compute units   1,006 bytes
-    50,000 shares ↔ $8,750,000 — $175 a share, agreed off chain
-with a fee-bearing cash mint
-                  5ZrJPGRL…   59,804 compute units   1,074 bytes
-    confidentialTransfer AND confidentialTransferWithFee, same transaction
-```
-
-All four accounts in every run are **associated token accounts** — what a wallet creates — and all
-four still read a **public balance of 0**. Nobody watching the chain learns the size of the trade
-or the price it implies.
-
-The last line is the one worth pausing on. **Two assets whose rules do not match, settled
-atomically**: the stock takes the plain confidential transfer, the cash takes `TransferWithFee`
-because its mint carries a fee config, and one transaction carries both. That is composition across
-rules, not just across programs.
-
-**And the safety property a confidential trade needs, which is not obvious.** The amounts are
-encrypted, so a party could be asked to sign a transaction whose other leg sends far less than was
-agreed. It is answerable **before signing, by the recipient alone**: a confidential transfer
-encrypts the amount under the recipient's key too, so each side decrypts the other's amount out of
-the already-verified proof context.
+**A tokenized-stock position on Solana is public.** Any token account's balance can be read by
+anyone, so the size of a holding, and of every trade that moves it, is published.
 
-```
-✓ it is addressed to your key
-✓ it will move 8750000000000 base units to you
-    decrypted from the verified context, by you, without anyone's cooperation
-
-If that is not the amount you agreed, do not sign. Nothing has happened yet.
-```
-
-No trust, no third party, no floor proof, and nothing revealed to anyone else.
-
-## 2. Who can use it today, and the measurement that decides it
-
-A confidential position needs a confidential account, and a confidential account needs the issuer's
-signature. `autoApproveNewAccounts` is `false` on **all 1,992** tokenized-equity mints — Backed,
-Backpack and PreStocks alike — and the auditor slot, the one mechanism
-for showing a balance to somebody who needs to see it, is empty on every one of them.
-
-So the honest answer is: **today, nobody.** And the second measurement says that is not a
-disadvantage.
+Token-2022 already has the fix switched on. Every one of the **1,992** tokenized-equity mints in
+three issuers' catalogues carries the confidential-transfer extension
+([the list is a catalogue, not a census](THE-POPULATION.md)). **Nobody is using it:**
 
 > **518,744 token accounts. Two have configured a confidential account — one on NVDAx, one on
 > AAPLx — and zero
@@ -73,6 +41,22 @@ decides, and the check reads the extension list.
 **The gate has never been opened by anyone.** There is no incumbent, no first mover, and nobody
 this is late to.
 
+## 2. Why it has not opened — what is known, and what is not
+
+**Known, because it is on chain:**
+
+- **A confidential account needs the issuer's signature.** `autoApproveNewAccounts` is `false` on
+  **all 1,992** — Backed, Backpack and PreStocks alike. Until the issuer sends `ApproveAccount` for
+  that account, a confidential transfer to it is refused (`Custom(24)`; §4 shows one).
+- **The only disclosure Token-2022 offers is one mint-wide auditor key.** It can decrypt the amount
+  of every confidential transfer made while it is set, for every holder, and cannot be scoped to one
+  holder, one reader or one occasion. It is empty on every one of the 1,992. With it empty, no
+  holder can show anything to anyone.
+
+**Not known:** why the slot is empty and why no account has been approved. `false` and `null` are
+also what a zero-initialised mint gets, so the configuration says what ships, not why
+([`THE-PINCER.md`](THE-PINCER.md), 2026-09-27). Nobody has asked an issuer.
+
 **And it is not an equities story.** A stock-for-cash trade needs cash that can move
 confidentially: USDC, USDT and USDS cannot — legacy SPL, no extensions at all. **PYUSD and USDG
 can**, and they arrive at the *identical* configuration: gate closed, auditor slot empty, and the
@@ -84,14 +68,99 @@ configuration matches every equity mint is a reading.
 > asset classes, one configuration** — which is also the default a new mint gets, so it says what
 > ships, not why.
 
-## 3. Every remaining obstacle is a named condition, not an unknown
+## 3. What Confide is
+
+> **Confide lets a tokenized-asset issuer preserve its eligibility controls while approved holders
+> settle bilateral stock-for-stablecoin trades without publishing their balances, trade sizes, or
+> implied prices.**
+
+It is the **privacy activation layer** for issuer-approved tokenized assets: it joins four things
+that exist separately today into one flow.
+
+1. **Issuer approval** — the issuer signs for exactly the account it has found eligible. The
+   eligibility decision itself (KYC, whatever the issuer requires) happens off chain; Confide does
+   not make it and does not bypass it.
+2. **Holder onboarding** — the holder configures a confidential account with their own keys.
+3. **Checking before signing** — the amounts are encrypted, so a party could be asked to sign a
+   transaction whose other leg sends less than agreed. Each side decrypts the amount addressed to it
+   out of the already-verified proof context and **compares it with what was agreed; a mismatch
+   stops the flow before a signature exists.** A comparison, not a display — until 2026-09-30 it
+   was a display, and that was a defect.
+4. **Atomic delivery versus payment** — stock and cash in one transaction, both legs or neither.
+
+**What stays public, said as plainly as what does not:** account addresses, the mint, and the fact
+that a transaction happened are public. **Amounts and balances are not.** If a mint sets an
+auditor key, that key can read transfer amounts made while it is set; it does not move funds.
+
+**What Confide is not:** a matching venue, an AMM, a lending protocol, investment advice, or a way
+around the issuer.
+
+## 4. What runs
+
+### Issuance, through the gate — the demo
+
+`./scripts/issue-e2e.sh`, on devnet, on a mint configured the way the real ones are (gate shut,
+auditor slot empty). The web app drives these same steps.
+
+1. The issuer creates the stock with the gate shut.
+2. An investor opens a confidential account for it. No permission is needed for that.
+3. Both legs' proofs are built — 20,000 shares against $3,500,000 — and the investor **checks the
+   amount addressed to them against what was agreed** before anything is signed. In a separate run,
+   `SHORT=`, the issuer builds its leg for fewer shares and the check **refuses here, before any
+   signature exists.**
+4. The issuer sends the allocation and it is **refused on chain**, `Custom(24)`, with a signature
+   anybody can look up. The proofs are valid, the amounts are right; the issuer has not approved the
+   account.
+5. The investor tries to approve their own account — **refused on chain**
+   (`MissingRequiredSignature`); the account still reads unapproved.
+6. The issuer approves that one account. One instruction.
+7. The issuer signs the allocation alone — **refused**; a transaction missing a required signature
+   never enters a block.
+8. The investor adds their signature to that same transaction and it **settles**: delivery and
+   payment, or neither.
+9. **Public balances on all four accounts: 0.** Asserted by the script, not just printed.
+
+Steps 5 and 7 were added on 2026-09-30 and have not yet been run on devnet (`STATUS.md`). Every other
+step has.
+
+In primary issuance the issuer is the sender, so it can read what it sent without an auditor key —
+which is why this flow runs today on a mint whose auditor slot is empty.
+
+### Between two holders — also runs
+
+**A stock-to-stablecoin swap in one transaction, with neither side publishing what moved.**
+Nothing of ours runs *inside* the trade — two Token-2022 instructions and two signatures. **What Confide does is everything around it**: the zero-knowledge proofs the chain will not assemble for you, verified on chain and citable by address, and the check that lets each side read the other's amount before signing.
+
+```
+stock for stock   2RksP5AM…   29,417 compute units   1,006 bytes
+stock for cash    4gzku3FW…   29,849 compute units   1,006 bytes
+    50,000 shares ↔ $8,750,000 — $175 a share, agreed off chain
+with a fee-bearing cash mint
+                  5ZrJPGRL…   59,804 compute units   1,074 bytes
+    confidentialTransfer AND confidentialTransferWithFee, same transaction
+```
+
+All four accounts in every run are **associated token accounts** — what a wallet creates — and all
+four still read a **public balance of 0**. Nobody watching the chain learns the size of the trade
+or the price it implies.
+
+**Two assets whose rules do not match, settled atomically**: the stock takes the plain confidential
+transfer, the cash takes `TransferWithFee` because its mint carries a fee config, and one
+transaction carries both. That is composition across rules, not just across programs.
+
+**Whether an issuer would accept holder-to-holder trades it cannot read the amounts of is not
+known.** Technically nothing stops them once both accounts are approved. Whether an issuer needs to
+see those amounts is a question for an issuer, and nobody has asked (§8, §9).
+
+## 5. Every remaining obstacle is a named condition, not an unknown
 
 This is the whole of the forward-looking case, and it is a table rather than a paragraph because
 each row can be checked by somebody who doesn't believe it.
 
 | what blocks it | **the exact condition that clears it** | what runs the moment it does |
 |---|---|---|
-| **The issuer gate** — no confidential account without the issuer | an issuer approving accounts. Not a protocol change: `ApproveAccount` is an instruction they already have and the plumbing they already shipped | **everything in §1, unchanged and with no new code.** The demonstrations already include the issuer's approval step, because the mirror mints are configured exactly this way |
+| **The issuer gate** — no confidential account without the issuer | an issuer approving accounts. Not a protocol change: `ApproveAccount` is an instruction they already have and the plumbing they already shipped | **everything in §4, unchanged and with no new code.** The demonstrations already include the issuer's approval step, because the mirror mints are configured exactly this way |
+| **What the issuer needs to see** — unknown | an issuer saying whether amounts it cannot read are acceptable, and what record it must keep | issuance runs either way (the issuer is the sender); holder-to-holder trades may need scoped disclosure that Token-2022 does not have |
 | **Venues refuse confidential collateral** — `$0` of Kamino's `$85.5m` of authorised borrowing is reachable | a reserve able to value a balance it cannot read, and to recover collateral at default without the holder | **the proved floor already exists**, verified by Solana's own ZK program, and settlement without the holder's signature is demonstrated on devnet — two loans, one seized, one released. `./scripts/kamino-verdict.sh` names what a reserve would need; two of the three are built |
 | **Confidential flash loans** — a program cannot read a confidential balance, so repayment must be proved *inline* | one number: the range proof's verify transaction is **1,269 bytes against a 1,232-byte limit**. Either the limit rises or the proof shrinks | the five-proof machinery is already written and running — the same path that settles the fee-bearing leg today |
 | **Matching** — somebody must want the other side | an indication-of-interest or request-for-quote layer. Nobody's permission required; simply not built | settlement, which is the part that is hard to get right, is done |
@@ -102,7 +171,7 @@ That last row is in the table on purpose. **The structural limit is stated as pl
 solvable ones**, because a forward-looking claim is only worth something if the same document is
 willing to say where the road ends.
 
-## 4. Why build it before the conditions clear
+## 6. Why build it before the conditions clear
 
 Three reasons, in the order they matter.
 
@@ -122,36 +191,58 @@ layout to get around it, a compute budget the default does not cover, a blockhas
 live long enough for fourteen transactions. **None of that depends on who approves an account.** It
 is done, measured, and will still be true when the conditions change.
 
-## 5. What it becomes, one condition at a time
+## 7. What it becomes, one condition at a time
 
-- **Today** — bilateral confidential settlement. Delivery versus payment between two parties, in
-  one transaction, with neither size published.
-- **The issuer approves accounts** — the same thing, with real assets. Block trades that do not
-  move the price against the seller; securities lending where lending your book does not publish
-  your book.
+- **Today** — confidential issuance through the issuer's gate, and bilateral confidential
+  settlement: delivery versus payment between two parties, in one transaction, with neither size
+  published.
+- **The issuer approves accounts** — the same thing, with real assets. Allocations and block trades
+  that do not publish their size; securities lending where lending your book does not publish your
+  book.
 - **A venue can read a proof instead of a balance** — confidential collateral inside a lending
   market. That is the `$85.5m` that is currently `$0`.
 - **Composition beyond one asset pair** — a loan that cannot be liquidated while the underlying
   market is closed (the stock market is shut about 70% of the hours in a week; no on-chain lender
   can say that sentence today); rotation between issuers' wrappers without selling.
 
-## 6. What is not true, said here rather than found later
+## 8. What is not true, said here rather than found later
 
 - **Traction is zero.** Nobody outside this repository has used any of it. No pilot, no design
   partner, no letter of intent. The 518,744-account scan measures a market, not a customer.
 - **No issuer has been asked.** The gate is described, not negotiated. Individual outreach was
   retired as a decision, with its cost written down where it was made.
+- **"The issuer is the first buyer" is a hypothesis.** The founder's brief names an issuer as the
+  first buyer; on 2026-09-16 this repository recorded the opposite reading — an issuer whose business
+  is issuing and selling is a gate, not a buyer ([`THE-PINCER.md`](THE-PINCER.md)). Neither has been
+  tested. It is the first thing to ask.
+- **Why the auditor slot is empty is not known**, and neither is whether an issuer would accept
+  holder-to-holder trades it cannot read (§2, §4).
+- **Everything runs on devnet.** The demo app is local: it holds throwaway devnet keys on the
+  machine it runs on. It is not a wallet, and mainstream wallets do not support confidential
+  transfers.
 - **Price is off chain.** Nothing here says 50,000 shares are worth $8.75m. That is what the two
   parties are for.
 - **Matching is unsolved**, and it is the same two-sided problem as finding a lender. The only
   differences are that both sides are holders and neither has to underwrite anything.
-- **Anything against a pool stays impossible**, permanently, for the reason in §3.
+- **Anything against a pool stays impossible**, permanently, for the reason in §5.
 - **The loan still cannot do both at once**: a proved floor and an ordinary holder remain
   alternatives.
-- **"The conditions will clear" is not a measurement.** §3 says what each one is and how to check
+- **"The conditions will clear" is not a measurement.** §5 says what each one is and how to check
   it; it does not claim to know when, or that any of them will.
 
-## 7. Why us
+## 9. The next step: one issuer conversation
+
+Not a partnership and not a pilot — questions, from the founder's brief (§3 P1):
+
+- Who is allowed to approve an account, and what event (KYC, a subscription) permits it?
+- Is a mint-wide auditor key acceptable, or is that exactly the problem?
+- Which allocation or block-trade workflow is painful today?
+- What record must the issuer retain of trades between its holders?
+
+Nothing in this repository answers these. They are why the next step is a conversation rather than
+more code.
+
+## 10. Why us
 
 The project did not find this by being clever about markets. It found it by **measuring what is
 actually deployed, repeatedly, and writing down the corrections.** The auditor slots, the approval
diff --git a/scripts/testbed-up.sh b/scripts/testbed-up.sh
index 4e78435..708df78 100755
--- a/scripts/testbed-up.sh
+++ b/scripts/testbed-up.sh
@@ -16,7 +16,7 @@
 #   * It is NOT traction. Standing it up is not usage. Usage is somebody else opening an account
 #     on it, and that is counted separately.
 #   * What it IS: proof that **the issuer gate is an operations decision rather than a protocol
-#     problem** — `docs/cwf-2026/STORY.md` §3 argues that, and this runs it. The mints keep
+#     problem** — `docs/cwf-2026/STORY.md` (*Every remaining obstacle is a named condition*) argues that, and this runs it. The mints keep
 #     `autoApproveNewAccounts: false`, exactly as all 1,992 live mints do, and the issuer simply
 #     **operates** the gate instead of leaving it shut.
 #
```

## DEMO-APP.md

# The demo app — design

**Decided with the founder, 2026-09-30:** the demo is shown through a web app, not a terminal; web
only, no mobile; the proofs and the keys stay on a local server; the demo opens on issuance.
The story it tells is [`STORY.md`](STORY.md) §4, in that order.

## The one rule: the app does not implement anything

Every check, refusal and transaction in the demo already exists in `scripts/issue-e2e.sh`, and most
of them have been run on devnet. **The app runs that script and shows what it does.** It does not
build a transaction, compare an amount, or decide that something was refused. If it did, there would
be two implementations of the demo, and this repository has recorded what happens to two copies of
anything: they drift, and the one that is shown is the one that is wrong.

So the pre-signing check stays an exit code inside the script. The app can display that the check
refused; it cannot make it pass. That is the lesson of 2026-09-30 (a "check" that was a display)
applied to the new surface before it is built.

## Shape

```
browser (127.0.0.1 only)                 local server (Python, stdlib)          devnet
┌─────────────┬──────────────┬─────────┐   ┌──────────────────────────┐
│ ISSUER      │ INVESTOR     │ OBSERVER│   │ runs issue-e2e.sh         │──── RPC from $RPC,
│ console     │ wallet       │         │◀──│ streams its events (SSE)  │     never sent to the browser
│ [create]    │ [open acct]  │ public  │──▶│ releases the next step    │
│ [allocate]  │ check result │ balances│   │ serves public reads only  │
│ [approve]   │ [try approve]│ + sigs  │   └──────────────────────────┘
│ [sign]      │ [sign]       │         │
└─────────────┴──────────────┴─────────┘
```

**Three panes, one per role.** The issuer console and the investor wallet show that role's own
buttons and what that role can see (the investor sees the amount decrypted for them; the issuer sees
what it sent). The observer pane shows only what anybody can read: accounts, transaction signatures
with explorer links, public balances.

## What changes in the script

Two additions, both inert unless the app sets them, so a terminal run is byte-for-byte the same
behaviour as today:

1. **`CONFIDE_EVENTS=<file>`** — at each point where the script already prints a result, it also
   appends one JSON line: `{"step":"refused","sig":"…","err":"Custom(24)"}`,
   `{"step":"check","ok":true,"agreed":…,"decrypted":…}`, `{"step":"public","balances":[0,0,0,0]}`,
   and so on. The human-readable output does not change.
2. **`CONFIDE_PAUSE=<fifo>`** — before each step the script waits for one line on the FIFO. The
   app's buttons write that line. Without the variable, there is no wait.

`SHORT=` is a second button that starts a **separate run** with `SHORT` set, exactly as the terminal
does — it is not a toggle on the running demo.

## What the server does, and does not

- binds **127.0.0.1** only;
- takes the RPC endpoint from `$RPC` and never sends it to the browser (the page's observer reads go
  through the server, which forwards only `getAccountInfo` / `getTransaction` for addresses and
  signatures that appeared in the event stream);
- **never serves the work directory** — the keypairs live there;
- starts one run at a time.

## What is shown on screen, said plainly

A banner on every pane: *devnet · local demo · keys held by this machine · not a wallet*. Mainstream
wallets do not support confidential transfers, and the app does not claim to be one.

## What would falsify "the app runs the same code"

A check, to be written with the app: run `issue-e2e.sh` with `CONFIDE_EVENTS` and without, and
compare the human-readable output (minus addresses and signatures, which are fresh each run). Any
difference beyond the event file means the app path has diverged.

## Not in scope

In-browser proof generation (the Rust ZK SDK compiled to WebAssembly — untested here), a
holder-to-holder swap screen, mobile, and anything on mainnet.
