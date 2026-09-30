# The story

The one place the narrative lives. The submission text, the two videos and the demo app all draw
from here, so they cannot drift from each other — and every figure below is in a file that a
stranger can recompute.

> **Agreed with the founder, 2026-09-30.** The order below — measured problem, what is and is not
> known about why, what Confide is, what runs, then the boundaries — is the order every surface
> follows. The demo opens on **issuance** (the issuer allocating to an investor), not on a swap
> between two holders, because issuance is where the issuer's gate can be shown refusing and then
> opening. It is shown through **a local web app** — an issuer console, an investor wallet and an
> observer — driving the same code the scripts run. The previous version of this file opened on the
> holder-to-holder swap; that swap still runs and is in §4.

**The shape of the argument, before the argument:** a specific thing runs today; the obstacles
between it and a real market are not unknowns but **named conditions with numbers attached**; and
it was built on the far side of those conditions deliberately, because when a named condition
clears, the difference between "we should build this" and "this already settles" is the whole
opportunity.

---

## 1. What is happening — measured

**A tokenized-stock position held the ordinary way is public.** An ordinary token account's
balance can be read by anyone, so the size of a holding, and of every trade that moves it, is
published. A Confidential Balance account is the exception — it reads as zero publicly — and that
is the capability this is about.

Token-2022 already has it switched on. Every one of the **1,992** tokenized-equity mints in three
issuers' catalogues carries the confidential-transfer extension
([the list is a catalogue, not a census](THE-POPULATION.md)). **On the mints where accounts were
counted, nobody is using it:**

> **518,744 token accounts. Two have configured a confidential account — one on NVDAx, one on
> AAPLx — and zero
> are approved — the issuer has not signed.**
> `./scripts/usage-scan.sh`, written for this question because no such count existed: six mints,
> two per issuer, 2026-09-28. The other 1,986 mints have not been counted.

Not "few". Zero. The first scan found seven large accounts on Apple xStock and every one was large
for `pausableAccount` and `transferHookAccount` instead — size is suggestive, the extension list
decides, and the check reads the extension list.

**On those six mints the gate has never been opened.** No incumbent turned up where we looked;
the scan does not reach the rest of the catalogue, so this is not a claim about the whole market.

## 2. Why it has not opened — what is known, and what is not

**Known, because it is on chain:**

- **A holder can configure a confidential account; only the issuer can make it usable.**
  `autoApproveNewAccounts` is `false` on **all 1,992** — Backed, Backpack and PreStocks alike.
  Until the issuer sends `ApproveAccount` for that account, a confidential transfer to it is refused
  (`Custom(24)`; §4 shows one). The two accounts counted above are exactly this: configured,
  unapproved.
- **The only disclosure Token-2022 offers is one mint-wide auditor key.** It can decrypt the amount
  of every confidential transfer made while it is set, for every holder, and cannot be scoped to one
  holder, one reader or one occasion. It is empty on every one of the 1,992. Token-2022 provides no
  mint-configured disclosure path in between. (A holder can always choose to show someone their own
  data; that is not something the mint provides.)

**Not known:** why the slot is empty and why no account has been approved. `false` and `null` are
also what a zero-initialised mint gets, so the configuration says what ships, not why
([`THE-PINCER.md`](THE-PINCER.md), 2026-09-27). Nobody has asked an issuer.

**And it is not an equities story.** A stock-for-cash trade needs cash that can move
confidentially: USDC, USDT and USDS cannot — legacy SPL, no extensions at all. **PYUSD and USDG
can**, and they arrive at the *identical* configuration: gate closed, auditor slot empty, and the
same key on both (`2apBGMsS6ti9…`) as confidential authority, permanent delegate and freeze
authority. That the two are one issuer's is an inference from the shared key; that the
configuration matches every equity mint is a reading.

> PayPal's dollar ships the same unusable privacy feature behind the same gate. **Four issuers, two
> asset classes, one configuration** — which is also the default a new mint gets, so it says what
> ships, not why.

## 3. What Confide is

> **Confide lets a tokenized-asset issuer preserve its eligibility controls while approved holders
> settle bilateral stock-for-stablecoin trades without publishing their balances, trade sizes, or
> implied prices.**

It is the **privacy activation layer** for issuer-approved tokenized assets: it joins four things
that exist separately today into one flow.

1. **Issuer approval** — the issuer signs for exactly the account it has found eligible. The
   eligibility decision itself (KYC, whatever the issuer requires) happens off chain; Confide does
   not make it and does not bypass it.
2. **Holder onboarding** — the holder configures a confidential account with their own keys.
3. **Checking before signing** — the amounts are encrypted, so a party could be asked to sign a
   transaction whose other leg sends less than agreed. Each side decrypts the amount addressed to it
   out of the already-verified proof context and **compares it with what was agreed; a mismatch
   stops the flow before a signature exists.** A comparison, not a display — until 2026-09-30 it
   was a display, and that was a defect.
4. **Atomic delivery versus payment** — stock and cash in one transaction, both legs or neither.

**What stays public, said as plainly as what does not:** account addresses, the mint, and the fact
that a transaction happened are public, and so are mint-level figures such as supply.
**Confidential transfer amounts and confidential balances are not.** If a mint sets an auditor key,
that key can read transfer amounts made while it is set; it does not see a whole balance and does
not move funds.

**What Confide is not:** a matching venue, an AMM, a lending protocol, investment advice, or a way
around the issuer.

## 4. What runs

### Issuance, through the gate — the demo

`./scripts/issue-e2e.sh`, on devnet, on a mint configured the way the real ones are (gate shut,
auditor slot empty). The web app drives these same steps.

1. The issuer creates the stock with the gate shut.
2. An investor opens a confidential account for it. No permission is needed for that.
3. Both legs' proofs are built — 20,000 shares against $3,500,000 — and the investor **checks the
   amount addressed to them against what was agreed** before anything is signed. In a separate run,
   `SHORT=`, the issuer builds its leg for fewer shares and the check **refuses here, before any
   signature exists.**
4. The issuer sends the allocation and it is **refused on chain**, `Custom(24)`, with a signature
   anybody can look up. The proofs are valid, the amounts are right; the issuer has not approved the
   account.
5. The investor tries to approve their own account — **refused on chain**
   (`MissingRequiredSignature`); the account still reads unapproved.
6. The issuer approves that one account. One instruction.
7. The issuer signs the allocation alone — **refused**; a transaction missing a required signature
   never enters a block.
8. The investor adds their signature to that same transaction and it **settles**: delivery and
   payment, or neither.
9. **Public balances on all four accounts: 0.** Asserted by the script, not just printed.

**Devnet status.** Steps 1–4, 6, 8 and 9, and the `SHORT=` refusal, have devnet evidence from the
earlier version of the script (`STATUS.md`, 2026-09-30 (5)). Steps 5 and 7 were added afterwards
(2026-09-30 (7)), and step 8 now settles the same half-signed transaction rather than a rebuilt one;
**the current script, as a whole, is waiting for one devnet run.**

In primary issuance the issuer is the sender, so it can read what it sent without an auditor key —
which is why this flow runs today on a mint whose auditor slot is empty.

### Act 2 — two approved holders trade

The same script continues (`ACT2=0` stops before it). The issuer approves a second holder's
accounts; the investor then sells 5,000 of the allocated shares to that holder for $875,000 through
the four-step bilateral protocol — `swap-offer`, `swap-accept`, `swap-settle`, `swap-sign` — each
party in its own work directory, each pinning the agreed terms on its own side before any proof
exists and checking what it will receive against that pin before signing. Stock and cash settle in
one transaction; the four public balances are asserted to be 0. **This path has not yet been run on
devnet** — the bilateral pinning was built and checked without a chain (`swap-pin-check.sh`,
`STATUS.md` 2026-09-30 (3)).

### Between two holders — also runs

**A stock-to-stablecoin swap in one transaction, with neither side publishing what moved.**
Nothing of ours runs *inside* the trade — two Token-2022 instructions and two signatures. **What Confide does is everything around it**: the zero-knowledge proofs the chain will not assemble for you, verified on chain and citable by address, and the check that lets each side read the other's amount before signing.

```
stock for stock   2RksP5AM…   29,417 compute units   1,006 bytes
stock for cash    4gzku3FW…   29,849 compute units   1,006 bytes
    50,000 shares ↔ $8,750,000 — $175 a share, agreed off chain
with a fee-bearing cash mint
                  5ZrJPGRL…   59,804 compute units   1,074 bytes
    confidentialTransfer AND confidentialTransferWithFee, same transaction
```

All four accounts in every run are **associated token accounts** — what a wallet creates — and all
four still read a **public balance of 0**. Nobody watching the chain learns the size of the trade
or the price it implies.

**Two assets whose rules do not match, settled atomically**: the stock takes the plain confidential
transfer, the cash takes `TransferWithFee` because its mint carries a fee config, and one
transaction carries both. That is composition across rules, not just across programs.

**Whether an issuer would accept holder-to-holder trades it cannot read the amounts of is not
known.** Technically nothing stops them once both accounts are approved. Whether an issuer needs to
see those amounts is a question for an issuer, and nobody has asked (§8, §9).

## 5. Every remaining obstacle is a named condition, not an unknown

This is the whole of the forward-looking case, and it is a table rather than a paragraph because
each row can be checked by somebody who doesn't believe it.

| what blocks it | **the exact condition that clears it** | what runs the moment it does |
|---|---|---|
| **The issuer gate** — no usable confidential account without the issuer | an issuer approving accounts. Not a protocol change: `ApproveAccount` is an instruction the mint's authority already has. The issuer-operated workflow around it is exactly what is untested | **everything in §4, unchanged and with no new code.** The demonstrations already include the issuer's approval step, because the mirror mints are configured exactly this way |
| **What the issuer needs to see** — unknown | an issuer saying whether amounts it cannot read are acceptable, and what record it must keep | issuance runs either way (the issuer is the sender); holder-to-holder trades may need scoped disclosure that Token-2022 does not have |
| **Venues refuse confidential collateral** — `$0` of Kamino's `$85.5m` of authorised borrowing is reachable | a reserve able to value a balance it cannot read, and to recover collateral at default without the holder | **the proved floor already exists**, verified by Solana's own ZK program, and settlement without the holder's signature is demonstrated on devnet — two loans, one seized, one released. `./scripts/kamino-verdict.sh` names what a reserve would need; two of the three are built |
| **Confidential flash loans** — a program cannot read a confidential balance, so repayment must be proved *inline* | one number: the range proof's verify transaction is **1,269 bytes against a 1,232-byte limit**. Either the limit rises or the proof shrinks | the five-proof machinery is already written and running — the same path that settles the fee-bearing leg today |
| **Matching** — somebody must want the other side | an indication-of-interest or request-for-quote layer. Nobody's permission required; simply not built | settlement, which is the part that is hard to get right, is done |
| **A proved floor *and* an ordinary holder** — currently alternatives | the loan PDA proving a floor over a balance whose key it does not hold | recorded as a known direction, not as a claim |
| **Anything against a pool** | **never.** A pool's reserves are public and a trade moves them by exactly the traded amount | — |

That last row is in the table on purpose. **The structural limit is stated as plainly as the
solvable ones**, because a forward-looking claim is only worth something if the same document is
willing to say where the road ends.

## 6. Why build it before the conditions clear

Three reasons, in the order they matter.

**Because a named condition clears suddenly.** An issuer deciding to approve accounts is an
operations decision, not a roadmap item — and on the day it happens, "somebody should build
confidential settlement for this" is six months away and "this already settles, here are the
transaction signatures" is the same afternoon.

**Because the measurement says the seat is empty where we looked.** On six mints, 518,744 accounts,
two configured and none approved. Building
after the gate opens means building against whoever built before it.

**Because the hard part is the part that does not change.** What took the work was not the business
logic — it was the cryptography and the transaction shapes: five proofs instead of three, a range
proof too large to verify from instruction data at all, a record account and a fourth instruction
layout to get around it, a compute budget the default does not cover, a blockhash that does not
live long enough for fourteen transactions. **None of that depends on who approves an account.** It
is done, measured, and will still be true when the conditions change.

## 7. What it becomes, one condition at a time

- **Today** — confidential issuance through the issuer's gate, and bilateral confidential
  settlement: delivery versus payment between two parties, in one transaction, with neither size
  published.
- **The issuer approves accounts** — the same thing, with real assets. Allocations and block trades
  that do not publish their size; securities lending where lending your book does not publish your
  book.
- **A venue can read a proof instead of a balance** — confidential collateral inside a lending
  market. That is the `$85.5m` that is currently `$0`.
- **Composition beyond one asset pair** — a loan that cannot be liquidated while the underlying
  market is closed (the stock market is shut about 70% of the hours in a week; no on-chain lender
  can say that sentence today); rotation between issuers' wrappers without selling.

## 8. What is not true, said here rather than found later

- **Traction is zero.** Nobody outside this repository has used any of it. No pilot, no design
  partner, no letter of intent. The 518,744-account scan measures a market, not a customer.
- **No issuer has been asked.** The gate is described, not negotiated. Individual outreach was
  retired as a decision, with its cost written down where it was made.
- **"The issuer is the first buyer" is the working hypothesis, not a finding.** The founder's brief
  (2026-09-27) sets an issuer as the first buyer to pursue — a priority, not evidence of willingness
  to buy; on 2026-09-16 this repository recorded the opposite reading — an issuer whose business
  is issuing and selling is a gate, not a buyer ([`THE-PINCER.md`](THE-PINCER.md)). Neither has been
  tested. It is the first thing to ask.
- **Why the auditor slot is empty is not known**, and neither is whether an issuer would accept
  holder-to-holder trades it cannot read (§2, §4).
- **Everything runs on devnet.** The demo app is local: it holds throwaway devnet keys on the
  machine it runs on. It is not a wallet, and mainstream wallets do not support confidential
  transfers.
- **Price is off chain.** Nothing here says 50,000 shares are worth $8.75m. That is what the two
  parties are for.
- **Matching is unsolved**, and it is the same two-sided problem as finding a lender. The only
  differences are that both sides are holders and neither has to underwrite anything.
- **Anything against a pool stays impossible**, permanently, for the reason in §5.
- **The loan still cannot do both at once**: a proved floor and an ordinary holder remain
  alternatives.
- **"The conditions will clear" is not a measurement.** §5 says what each one is and how to check
  it; it does not claim to know when, or that any of them will.

## 9. The next step: one issuer conversation

Not a partnership and not a pilot — questions, from the founder's brief (§3 P1):

- Who is allowed to approve an account, and what event (KYC, a subscription) permits it?
- Is a mint-wide auditor key acceptable, or is that exactly the problem?
- Which allocation or block-trade workflow is painful today?
- What record must the issuer retain of trades between its holders?

Nothing in this repository answers these. They are why the next step is a conversation rather than
more code.

## 10. Why us

The project did not find this by being clever about markets. It found it by **measuring what is
actually deployed, repeatedly, and writing down the corrections.** The auditor slots, the approval
gate, Kamino's refusal at a pinned commit, `ImmutableOwner`, the transaction sizes, the compute
budget, the stablecoins, and now the account scan — all read off chain, all recomputable, several
of them overturning something this repository had already claimed in public.

**Every headline number is generated, and a consistency check fails the build when prose and
measurement disagree** — today it reported two
disagreements, correctly, and both times it was the prose that was wrong.

The strongest thing here is not the transaction. It is that everything above can be run again by
somebody who does not believe it.
