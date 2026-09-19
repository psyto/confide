# Composing with other people's programs — what tokenized equity actually unlocks

Asked 2026-09-20: existing on-chain schemes — flash loans and the rest — applied to tokenized
equity as a new asset class, composed across programs in one transaction.

This is the survey, with each item marked by whether it can be built or is blocked, and by what.
The measurements are dated and repeatable; the reasoning is labelled as reasoning.

## The constraint that decides most of it

**Confidentiality and pooled liquidity are mutually exclusive, and not by anyone's choice.**

An AMM's reserves are public state. A swap changes them by exactly the traded amount, so the amount
is recoverable by subtracting two consecutive public states. An order book publishes fills. A
lending reserve publishes its totals. **Any composition whose counterparty is a *pool* publishes the
size**, whatever the token's extensions say — and Kamino does not even get that far, refusing an
account that holds confidential value at all (`constraints.rs:187/194/201`, measured by
`./scripts/kamino-verdict.sh`).

So the frontier is not "compose Confide with Jupiter or Kamino". It is:

> **Confidential composition only works where the counterparty is a party, not a pool.**

Which is the bilateral case — and the bilateral case is what is already built and running: the loan
(`seizure-e2e.sh`) and the swap ([`THE-SWAP.md`](THE-SWAP.md)).

**Corollary worth stating because it sounds like a loss and is not:** what Confide hides is the
**stock**, not the **flow**. A position that is confidential before and after a public trade still
never publishes its size; only that one trade's size is seen. That is what an equity desk actually
wants — prints are public everywhere, books are not.

## Why a *confidential* flash loan is blocked, precisely

A flash loan works because the lending program re-reads a balance at the end of the transaction and
reverts unless it was repaid. **A program cannot read a confidential balance**, so repayment would
have to be proved: a range proof over the post-state ciphertext, verified in the same transaction.

Solana's ZK program can verify such a proof inline — but the proof must then travel in the
transaction. This repository has measured that a `BatchedRangeProofU128` is **~1,000 bytes of
instruction data**, and that the verify transaction *alone* reaches **1,237 bytes against a
1,232-byte limit** (`seizure_ctx.rs`). Adding the flash loan's own instructions is not close.

The usual escape — verify into a context account first — **is exactly what a flash loan cannot
do**, because that is a second transaction and the whole guarantee is that there is only one.

> **A confidential flash loan is blocked by transaction size, not by cryptography.** That is a
> different sentence from "it is impossible", and it will stop being true if inline proofs shrink
> or the limit rises.

**Flash loans over *public* tokenized equity work today** — collateral rotation without unwinding,
self-deleveraging to dodge a liquidation penalty, one-transaction leveraged entry. They are real and
useful and **Confide adds nothing to them**, which is why they are not this project's.

## What is genuinely different about this asset

Four things, and every opportunity below comes from one of them.

1. **The underlying market closes; the token does not.** Roughly 70% of the hours in a week there is
   no authoritative price and no way to hedge or redeem.
2. **The same underlying is wrapped by several issuers and the wrappers are not fungible with each
   other.** Backed's NVDAx is not Backpack's.
3. **Size is information.** In equities, showing your book moves the price against you. This is the
   only asset class in crypto where that is the *normal* assumption rather than a preference.
4. **Settlement is the institution.** TradFi does T+1 delivery-versus-payment with a clearing house,
   margin and members. On chain, DvP is a property of the transaction and needs none of them.

## The schemes

| | what it is | buildable? |
|---|---|---|
| **A. Confidential DvP, stock ↔ cash** | a block trade settling in one transaction, neither leg's size published | **the stock↔stock half runs today.** The cash leg is newly measured possible — see below |
| **B. Atomic securities lending** | lend stock against collateral, both confidential, no custodian | **yes** — the loan and the swap already hold every piece |
| **C. Closed-market products** | a loan that cannot be liquidated while the underlying market is shut; weekend gap-risk transfer | **yes**, and nobody has it. Needs a clock and a calendar, not cryptography |
| **D. Cross-issuer relative value** | Backed's wrapper for Backpack's, directly | **settlement runs today** ([`THE-SWAP.md`](THE-SWAP.md)); price and matching are not solved |
| **E. Flash-loan schemes over public positions** | rotation, deleveraging, looping | yes, and **Confide adds nothing** — listed so it is not claimed |
| **F. Anything against a pool, confidentially** | — | **no**, and not for a fixable reason. See the constraint above |

## The measurement that opens A — 2026-09-20, mainnet

A confidential stock-for-cash trade needs a **cash** token that can move confidentially. USDC and
USDT cannot: they are legacy SPL with no extensions at all. **Two can.**

```
PYUSD  2b1kV6DkPAnxd5ixfnxCpjxmKwqjjaYmCZfHsFu24GXo   Token-2022, confidentialTransferMint
USDG   2u1tszSeqZ3qBWF3uNGPFc8TzMk2tdiwknnRMWGWjGWH   Token-2022, confidentialTransferMint
USDC   EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v   legacy SPL, no extensions
USDT   Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB   legacy SPL, no extensions
USDS   USDSwr9ApdHk5bvJKMjzff41FfuX8bSxdKcR81vTwcA    legacy SPL, no extensions
```

And the settings on both are the ones this repository has spent a month describing:

```
                          PYUSD            USDG
autoApproveNewAccounts    False            False
auditorElgamalPubkey      EMPTY            EMPTY
transfer fee              0 bps            0 bps
transfer hook             none set         none set
confidential authority    2apBGMsS6ti9…    2apBGMsS6ti9…   ← the same key
permanentDelegate         2apBGMsS6ti9…    2apBGMsS6ti9…
freezeAuthority           2apBGMsS6ti9…    2apBGMsS6ti9…
```

**This generalises the project's central finding past equities.** It has been *"1,992 tokenized
equity mints ship a privacy feature nobody can use"*, which reads as two companies' decision. It is
not: **PayPal's dollar and Paxos's Global Dollar ship the same feature with the same gate and the
same empty auditor slot.** A regulated Token-2022 issuer, whatever they are issuing, arrives at this
configuration — which is the substrate argument, now with a third and fourth independent witness.

**What it means for A, plainly:** a confidential stock-for-cash swap is possible on mainnet as a
mechanism, and needs **two** issuers' approvals rather than one — the equity issuer for the stock
account and Paxos for the cash account. Zero fees and no transfer hook mean nothing else
complicates it.

**Not measured:** whether anybody holds a confidential PYUSD or USDG balance at all. The
`getProgramAccounts` scan that would answer it exceeds the endpoint's capacity, and it is left
unanswered rather than guessed.

## What to build next, and why

**A — the cash leg of the swap.** The reasons, in order:

1. **The hard half already runs.** `swap-e2e.sh` settles two confidential legs in one transaction,
   29,417 compute units, 1,006 bytes. A stock↔cash swap is the same transaction with a different
   mint on one side.
2. **It is the trade that actually exists.** Stock-for-stock swaps are rare; stock-for-cash is every
   block trade ever done. DvP without a clearing house is the claim that is true *because* this is
   on chain and false everywhere else.
3. **It needs no venue, no oracle and no lender** — the three things that have blocked everything
   else in this repository.
4. **It is demonstrable end to end on devnet this week**, with a mirror of PYUSD's exact
   configuration, the way the equity mint is already mirrored.

**C is the one to keep in view afterwards.** "This loan cannot be liquidated while the New York
Stock Exchange is closed" is a sentence no existing on-chain lender can say and no TradFi lender
needs to. It comes from difference (1) and costs a clock.
