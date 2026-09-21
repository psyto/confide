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

### The shareholder-rights condition — corrected 2026-09-21, and the correction is the finding

**What this section said until 2026-09-21 was wrong, and it was load-bearing.** It read:

> *"You cannot pay a dividend pro rata to a holder whose balance you cannot read."*

**Measured, and false — but the first correction was itself wrong about the mechanism, and Codex
caught it** ([review](reviews/2026-09-22-tokenized-equity-structure.md)). This section said *"a
confidential balance rebases exactly like a public one."* **It does not rebase at all.**

`scaledUiAmountConfig::amount_to_ui_amount(amount: u64, decimals, timestamp) -> Option<String>`
takes a **public u64** and returns a **formatted string**. Read in
`spl-token-2022-interface-2.1.0/src/extension/scaled_ui_amount/mod.rs:74`. It never touches
`base.amount`, never touches a ciphertext, mints nothing and proves nothing. **It is a display
conversion.**

**What survives of the correction, and it is what mattered:** if one raw token is defined as a
time-varying quantity of economic exposure, **that conversion is published globally and no
individual balance is read to deliver it.** So the original claim — *you cannot pay a dividend pro
rata to a holder whose balance you cannot read* — is still not safe. But the mechanism is a
**legal and product interpretation of what a token means**, not an on-chain distribution, and the
measured multiplier below is evidence of a multiplier changing and of **nothing else**:

| mint | multiplier | next multiplier, already scheduled |
|---|---|---|
| NVDAx | **1.0009180758490996** | 1.001701196801074 |
| AAPLx | **1.0026642075893797** | 1.0032690125398187 |
| SPCX.US | 1 | — (SpaceX pays no dividend) |

**It is not evidence that a custodian bought shares, that a dividend was paid, or that any balance
moved.** Calling a multiplier change a dividend requires the terms, which this repository does not
have. What can be said is the narrow thing: **a global conversion factor delivers proportional
economics without reading anybody's balance**, so dividends are not a safe argument for scoped
disclosure — and this document claimed they were for four days, then explained it wrongly for one.

### What survives is narrower, and better

**Voting.** The order requires *"a right to exercise the same voting rights"*. **There is no scalar
for a vote.** A tally proportional to holdings requires knowing the holdings, and no multiplier
trick removes that. That is a genuine, compelled need for disclosure scoped to one recipient, one
purpose, one moment — the record date.

**And the same condition may be a problem for the issuers themselves.** Backed's tokens are
*tracker notes*: a senior claim against a Jersey SPV for economic value, with the share register
showing the custodian or the SPV, so **token holders typically have no vote at all**. The order
requires one. Backpack Securities' structure is different — a security entitlement, *"redeemable
1:1 for the real underlying share"*, convertible in both directions — and is closer to what the
order asks for.

**Corrected again 2026-09-22, and this is the second time this argument has been wrong.** The
founder's first answer was that Backpack's tokens carry voting rights. The precise answer:

> **Held on chain, they do not vote.** The register shows the broker. To vote you **redeem the
> token back into the security entitlement**, and then vote through the traditional proxy rails.

So confidentiality does not collide with voting, because **voting was never on chain**. The claim
before this one said it did. It is wrong for the same reason the dividend claim was wrong: these
are tracker and entitlement structures whose legal layer sits off chain, and on-chain
confidentiality cannot collide with a legal right that is not exercised on chain.

**Twice in two days this document reached for "regulation compels disclosure" and twice the
structure routed around it.** The pattern is worth naming, because a third attempt in the same
direction would be a fourth error.

---

## Where the size actually gets published — the door, not the right

Backpack's headline feature is a **two-way door**: a US share bought in the brokerage converts 1:1
to an on-chain token, and the token burns back into the entitlement whenever you want.

**Every passage through that door publishes its size.** Minting in raises supply by the amount;
redeeming out burns it and lowers supply by the amount. A mint's supply is public state, so the
size is recoverable by subtracting two consecutive public states — **the identical argument this
repository already makes about pool reserves**, arriving at the same place from the other side.

And the door is not optional for anything that matters:

| you want to | you must | which publishes |
|---|---|---|
| **vote** | redeem to the entitlement | the size of your position |
| **move brokers** (ACATS) | redeem first | the size |
| **exit at NAV** rather than into a pool | redeem | the size |
| **enter at size** without moving a pool | mint in | the size |

**So the argument is not about a shareholder right at all. It is about the plumbing between two
layers**, and the plumbing is the one place a holder has no alternative.

**This is the strongest form the argument has taken, and it is the one that needs no regulation to
be true.** It is also, exactly, what this repository already built: a bilateral settlement between
a holder and an issuer, in one transaction, with neither side publishing the amount. See
[`cwf-2026/ISSUANCE.md`](cwf-2026/ISSUANCE.md).

### Conditional, not structural — Codex's third correction

**The door publishes its size only if redemption uses an ordinary `Burn`.** Four ways it does not,
from the [review](reviews/2026-09-22-tokenized-equity-structure.md):

| | |
|---|---|
| **treasury transfer** | the holder transfers to issuer inventory and is paid off chain. **Public supply does not move at all**, and the transfer itself can be confidential |
| **batching or netting** | a supply delta aggregates many mints and burns and reveals at most the net |
| **reissuance** | redeem into treasury, redistribute the same units later |
| **`ConfidentialMintBurn`** | a separate Token-2022 extension whose `current_supply` is a `PodElGamalCiphertext` — **an encrypted supply**. Confidential mint and burn do not move the public `mint.supply` at all |

**Measured 2026-09-22: none of the six mints checked carries `ConfidentialMintBurn`** — not NVDAx,
AAPLx, ANTHROPIC, SPACEX, SPCX.US or AMC.US. So on these mints today a `Burn` is public. **That is
a fact about configuration, not about the protocol**, and it is one instruction away from changing.

**And a second reading says supply does move.** `SPCX.US` was **42,488.081216** on 2026-09-21 and
**42,488.076967** on 2026-09-22 — down **0.004249**, a fraction rather than a round batch. **An
individual burn instruction was not captured**: the last forty signatures on the mint carry
transfers only. So the movement is inferred from differencing, which is the weaker of the two
observations Codex names — the instruction itself would be direct.

Token-2022 still offers exactly two disclosure settings — a global auditor key that reads everyone
forever, or null — and all 1,992 are null. **The primitive for a third exists in this repository.
The registrar application does not**, and saying otherwise would be the kind of claim
`scripts/docs-consistency.sh` exists to prevent.

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

## "Confide is bilateral, so it is outside the SEC's purview" — do not write this

Asked by the founder, 2026-09-20. **Half of it is right and the other half would be a gift to a
judge who knows the subject.**

**Right:** Confide is not covered by this exemption, and does not need it. The relief covers
trading *executed by an AMM* on a TSV, and relieves two **intermediary** registrations — venues of
"exchange", liquidity providers of "dealer". Two holders trading their own accounts are neither.
Being outside the relief is not a licence this project lacks.

**Wrong, and load-bearing:** *outside the exemption* is not *outside regulation*. **An exemption is
relief from a rule that otherwise binds you.** Falling outside it means the baseline applies in
full, not that nothing applies. Tokenized stock is a security, and a securities transaction is
regulated with or without a venue:

- **Rule 10b-5** reaches any purchase or sale of a security. No venue is an element of it.
- Insider dealing and manipulation, likewise.
- **Securities Act §5** still asks under what exemption a sale happens. Ordinary secondary trading
  between holders usually rests on §4(a)(1) — but that is an analysis, not a given.

### The live one is matching

`_submission/full.md` lists **Matching** under *what is not built*: "Settlement is done; finding the
other side is not." That line is now doing more work than it was written to do. **Bringing multiple
buyers and sellers together by established, non-discretionary methods is the exchange definition at
Rule 3b-16, and doing it for others is the broker registration at §15(a).** What keeps this project
clear of both today is that it does not do it.

So the roadmap entry stays where it is, and now has a second reason under the engineering one.

### What is accurate to say today

- Confide is **not a venue**. It settles a trade two parties have already agreed between
  themselves.
- The devnet testbed's tokens **represent nothing**. There is no security in it, so there is no
  securities activity in it.
- The 1,992 live mints are issued by Backed, Backpack and PreStocks **outside the US** and are not
  tokenized **NMS** stock, which is what this order is about.

**Say "this is not a venue, so the venue exemption neither covers it nor is needed." Never say
"outside the SEC's purview."** The first is a statement about what the software does. The second is
a legal conclusion, it is wrong as stated, and one line from a judge with a finance background
disposes of it — taking the account scan down with it, which is exactly the failure mode
`docs/cwf-2026/POST.md` already refuses for a second finding.

**And none of this is legal advice.** Nobody in this repository is a lawyer. If a legal conclusion
is going into a submission with the founder's name on it, that is the item to put in front of one.
