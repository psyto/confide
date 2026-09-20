# The SEC's Innovation Exemption — 2026-09-17, and what it does to this project

**Pinned from the primary source, not from coverage.** The repository already had to learn this
once: `docs/cwf-2026/CRITERIA.md` exists because a rule was copied out of a news page and rotted.
What follows is the SEC's own release and one law-firm memo, both linked, with the conditions
quoted rather than paraphrased.

- SEC press release 2026-90, 2026-09-17 —
  https://www.sec.gov/newsroom/press-releases/2026-90-sec-issues-innovation-exemption-facilitate-trading-tokenized-nms-stock-request-comment
- Sullivan & Cromwell memo, 2026-09 —
  https://www.sullcrom.com/insights/memo/2026/September/SEC-Issues-Innovation-Exemption-for-Tokenized-Securities

## What it actually is

Two conditional exemptions under Exchange Act §36(a)(1), **published 2026-09-17, expiring
2026-09-17 + 5 years = 2031-09-17**:

1. **Tokenized Securities Venues (TSVs) are exempted from the definition of "exchange"** so they
   may trade tokenized NMS stock **through automated market makers and liquidity pools**.
2. **Liquidity providers into those AMM pools are exempted from dealer registration.**

### The conditions that matter here

| condition | the SEC's wording |
|---|---|
| **The venue is an AMM** | the relief "only covers trading of Tokenized NMS Stock executed by an AMM". **Bilateral off-venue trades fall outside the exemption entirely.** |
| **Every trade's size is published** | a TSV must make transaction data "freely and publicly available in machine-readable format", **within 10 minutes**, carrying "transaction price, the transaction size, the transaction time and the transaction direction", plus pool size per pair |
| **Size is capped** | Tier 1 (S&P 500 / Russell 1000): **75 symbols, 0.25% of average daily share volume.** Tier 2: 250 symbols, 2.5% of ADV. Exceed it twice and trading in that symbol **pauses for three months** |
| **The code is public** | "Smart contracts used by a TSV must be auditable, public, and deployed on a public, permissionless distributed ledger" |
| **Shares must carry shareholder rights** | the same interest, "a right to receive the same dividends", "a right to exercise the same voting rights", the same residual claim — and the tokenizer must distribute "any related proxy materials or other issuer communications at no cost" |
| **The underlying issuer may object** | before listing a stock tokenized by an unaffiliated third party, the TSV must give the issuer of the underlying stock "written notice and an opportunity to object" |
| **Privacy** | **not addressed.** No confidentiality provision, and no carve-out either. The order is silent |

## What it changes for Confide

**The sanctioned US venue publishes the size of every trade within ten minutes, by regulation.**
This repository's structural finding was that a pool cannot be confidential because its reserves
are public and a trade moves them by exactly the traded amount. That was a property of AMMs. As of
2026-09-17 it is also **a condition of the only US venue that may legally operate**, written down.

**And size cannot go there anyway.** 0.25% of average daily volume, on the Tier 1 names — Apple,
NVIDIA — is not a block. A desk accumulating or unwinding is capped out before it starts, and
whatever does get through is on a public tape in ten minutes with its direction attached.

`_submission/full.md` named that desk as the first user before this order existed. The order did
not create the need; it **priced it**, by building the lit venue and leaving the block trade
outside it. Block trades have always settled away from the tape. **The SEC has now built the tape
for tokenized equity. Nobody has built the block.**

**Bilateral settlement needs no exemption.** Two holders trading directly were never an exchange,
so being outside the relief is not a gap to close — Confide is not a TSV, is not seeking to be
one, and the exemption is not a licence it lacks.

### The shareholder-rights condition is the harder and more interesting one

A tokenized share must now carry dividends, votes, and proxy material delivery. **You cannot pay a
dividend pro rata to a holder whose balance you cannot read.** So a confidential tokenized share
needs the registrar to learn one number, for one purpose, at one time.

Token-2022 today offers exactly two settings, and the mint scan says every issuer picked the same
one: **a single global auditor key that reads everyone's everything forever, or null.** Filling it
makes every holder permanently readable by one party; leaving it null means no holder can prove
anything to anyone. All 1,992 are null.

**This order makes null harder to defend and the global key no easier.** What it argues for is
disclosure scoped to a recipient and a purpose — which is the shape this repository already
builds: a proof over your own ciphertext, anchored on chain, and an amount encrypted to a named
recipient so the counterparty can check it before signing.

**That primitive exists here. The registrar application does not.** Saying otherwise would be the
kind of claim `scripts/docs-consistency.sh` exists to prevent.

## What it does not change — say these out loud

- **Traction is still zero.** No pilot, no user, no issuer asked. An SEC order is not a customer.
- **The gate is still shut.** `autoApproveNewAccounts` is false on 1,992 of 1,992, measured
  2026-09-20 at 11:54 UTC, three days after the order. The scan ran *after* the news and found
  **330,266 accounts and 0 confidential.**
- **The two issuers are different parties.** The order's veto belongs to the **company whose stock
  is tokenized** (Apple). Confide's gate belongs to the **token issuer** (Backed, Backpack,
  PreStocks) who holds confidential-transfer approval authority. Do not merge them in any
  document. They now stack — a confidential position would need both — but they are not the same
  consent and one does not imply the other.
- **The existing 1,992 mints are not covered.** Backed and Backpack issue outside the US; this
  relief is about US venues trading tokenized **NMS** stock. Nothing here retroactively applies to
  an xStock.
- **Kamino still refuses confidential collateral** (`constraints.rs:187`). The order says nothing
  about lending.
- **It does not make a real xStock pledgeable.**

## The objection a judge will raise, and the answer

> *"The regulator required the smart contracts to be auditable and public, and required every
> trade size on the tape. You are building the opposite."*

The condition is that **the code** be auditable and public. Confide's is — it is a public
repository, the programs are deployed on a public permissionless ledger, the page decodes the
trades in the reader's own browser, and the counterparty decrypts the amount out of the verified
proof context before signing. **What is confidential is the position, not the mechanism.**

Audited venues and confidential block trades have coexisted in every equity market for decades.
The order builds the first. It does not prohibit the second; it is silent, and it placed the
second outside its own scope by covering AMMs only.
