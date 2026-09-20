# The story

The one place the narrative lives. The submission text and the video narration both draw from here,
so they cannot drift from each other — and every figure below is in a file that a stranger can
recompute.

**The shape of the argument, before the argument:** a specific thing runs today; the obstacles
between it and a real market are not unknowns but **named conditions with numbers attached**; and
it was built on the far side of those conditions deliberately, because when a named condition
clears, the difference between "we should build this" and "this already settles" is the whole
opportunity.

---

## 1. What runs today

**Two parties exchange confidential positions in one transaction.** Nothing of ours runs *inside*
the trade — two Token-2022 instructions and two signatures. **What Confide does is everything around it**: the zero-knowledge proofs the chain will not assemble for you, verified on chain and citable by address, and the check that lets each side read the other's amount before signing.

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

The last line is the one worth pausing on. **Two assets whose rules do not match, settled
atomically**: the stock takes the plain confidential transfer, the cash takes `TransferWithFee`
because its mint carries a fee config, and one transaction carries both. That is composition across
rules, not just across programs.

**And the safety property a confidential trade needs, which is not obvious.** The amounts are
encrypted, so a party could be asked to sign a transaction whose other leg sends far less than was
agreed. It is answerable **before signing, by the recipient alone**: a confidential transfer
encrypts the amount under the recipient's key too, so each side decrypts the other's amount out of
the already-verified proof context.

```
✓ it is addressed to your key
✓ it will move 8750000000000 base units to you
    decrypted from the verified context, by you, without anyone's cooperation

If that is not the amount you agreed, do not sign. Nothing has happened yet.
```

No trust, no third party, no floor proof, and nothing revealed to anyone else.

## 2. Who can use it today, and the measurement that decides it

A confidential position needs a confidential account, and a confidential account needs the issuer's
signature. `autoApproveNewAccounts` is `false` on **all 1,992** tokenized-equity mints — Backed,
Backpack and PreStocks each arrived there independently — and the auditor slot, the one mechanism
for showing a balance to somebody who needs to see it, is empty on every one of them.

So the honest answer is: **today, nobody.** And the second measurement says that is not a
disadvantage.

> **329,536 token accounts across five mints that have holders — Apple and NVIDIA from Backed,
> SpaceX and Anthropic from PreStocks. Zero are configured for confidential transfers.**
> `./scripts/usage-scan.sh`, written for this question because no such count existed.

Not "few". Zero. The first scan found seven large accounts on Apple xStock and every one was large
for `pausableAccount` and `transferHookAccount` instead — size is suggestive, the extension list
decides, and the check reads the extension list.

**The gate has never been opened by anyone.** There is no incumbent, no first mover, and nobody
this is late to.

**And it is not an equities story.** A stock-for-cash trade needs cash that can move
confidentially: USDC, USDT and USDS cannot — legacy SPL, no extensions at all. **PYUSD and USDG
can**, and they arrive at the *identical* configuration: gate closed, auditor slot empty, and the
same key on both (`2apBGMsS6ti9…`) as confidential authority, permanent delegate and freeze
authority. That the two are one issuer's is an inference from the shared key; that the
configuration matches every equity mint is a reading.

> PayPal's dollar ships the same unusable privacy feature behind the same gate. **Every regulated
> Token-2022 issuer arrives here, whatever they are issuing** — four independent witnesses now,
> across two asset classes.

## 3. Every remaining obstacle is a named condition, not an unknown

This is the whole of the forward-looking case, and it is a table rather than a paragraph because
each row can be checked by somebody who doesn't believe it.

| what blocks it | **the exact condition that clears it** | what runs the moment it does |
|---|---|---|
| **The issuer gate** — no confidential account without the issuer | an issuer approving accounts. Not a protocol change: `ApproveAccount` is an instruction they already have and the plumbing they already shipped | **everything in §1, unchanged and with no new code.** The demonstrations already include the issuer's approval step, because the mirror mints are configured exactly this way |
| **Venues refuse confidential collateral** — `$0` of Kamino's `$83.0m` of authorised borrowing is reachable | a reserve able to value a balance it cannot read, and to recover collateral at default without the holder | **the proved floor already exists**, verified by Solana's own ZK program, and settlement without the holder's signature is demonstrated on devnet — two loans, one seized, one released. `./scripts/kamino-verdict.sh` names what a reserve would need; two of the three are built |
| **Confidential flash loans** — a program cannot read a confidential balance, so repayment must be proved *inline* | one number: the range proof's verify transaction is **1,269 bytes against a 1,232-byte limit**. Either the limit rises or the proof shrinks | the five-proof machinery is already written and running — the same path that settles the fee-bearing leg today |
| **Matching** — somebody must want the other side | an indication-of-interest or request-for-quote layer. Nobody's permission required; simply not built | settlement, which is the part that is hard to get right, is done |
| **A proved floor *and* an ordinary holder** — currently alternatives | the loan PDA proving a floor over a balance whose key it does not hold | recorded as a known direction, not as a claim |
| **Anything against a pool** | **never.** A pool's reserves are public and a trade moves them by exactly the traded amount | — |

That last row is in the table on purpose. **The structural limit is stated as plainly as the
solvable ones**, because a forward-looking claim is only worth something if the same document is
willing to say where the road ends.

## 4. Why build it before the conditions clear

Three reasons, in the order they matter.

**Because a named condition clears suddenly.** An issuer deciding to approve accounts is an
operations decision, not a roadmap item — and on the day it happens, "somebody should build
confidential settlement for this" is six months away and "this already settles, here are the
transaction signatures" is the same afternoon.

**Because the measurement says the seat is empty.** 329,536 accounts, zero confidential. Building
after the gate opens means building against whoever built before it.

**Because the hard part is the part that does not change.** What took the work was not the business
logic — it was the cryptography and the transaction shapes: five proofs instead of three, a range
proof too large to verify from instruction data at all, a record account and a fourth instruction
layout to get around it, a compute budget the default does not cover, a blockhash that does not
live long enough for fourteen transactions. **None of that depends on who approves an account.** It
is done, measured, and will still be true when the conditions change.

## 5. What it becomes, one condition at a time

- **Today** — bilateral confidential settlement. Delivery versus payment between two parties, in
  one transaction, with neither size published.
- **The issuer approves accounts** — the same thing, with real assets. Block trades that do not
  move the price against the seller; securities lending where lending your book does not publish
  your book.
- **A venue can read a proof instead of a balance** — confidential collateral inside a lending
  market. That is the `$83.0m` that is currently `$0`.
- **Composition beyond one asset pair** — a loan that cannot be liquidated while the underlying
  market is closed (the stock market is shut about 70% of the hours in a week; no on-chain lender
  can say that sentence today); rotation between issuers' wrappers without selling.

## 6. What is not true, said here rather than found later

- **Traction is zero.** Nobody outside this repository has used any of it. No pilot, no design
  partner, no letter of intent. The 329,536-account scan measures a market, not a customer.
- **No issuer has been asked.** The gate is described, not negotiated. Individual outreach was
  retired as a decision, with its cost written down where it was made.
- **Price is off chain.** Nothing here says 50,000 shares are worth $8.75m. That is what the two
  parties are for.
- **Matching is unsolved**, and it is the same two-sided problem as finding a lender. The only
  differences are that both sides are holders and neither has to underwrite anything.
- **Anything against a pool stays impossible**, permanently, for the reason in §3.
- **The loan still cannot do both at once**: a proved floor and an ordinary holder remain
  alternatives.
- **"The conditions will clear" is not a measurement.** §3 says what each one is and how to check
  it; it does not claim to know when, or that any of them will.

## 7. Why us

The project did not find this by being clever about markets. It found it by **measuring what is
actually deployed, repeatedly, and writing down the corrections.** The auditor slots, the approval
gate, Kamino's refusal at a pinned commit, `ImmutableOwner`, the transaction sizes, the compute
budget, the stablecoins, and now the account scan — all read off chain, all recomputable, several
of them overturning something this repository had already claimed in public.

**104 tests, 44 of them over the on-chain program. Every headline number is generated, and a
consistency check fails the build when prose and measurement disagree** — today it reported two
disagreements, correctly, and both times it was the prose that was wrong.

The strongest thing here is not the transaction. It is that everything above can be run again by
somebody who does not believe it.
