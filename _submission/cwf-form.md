# CWF submission form — paste text, field by field

**Every field below is written to be pasted.** Character limits are the form's own and are checked
by `./scripts/cwf-form.sh`, which counts them rather than trusting a number typed here.

**The form currently holds a stale Brief description.** As found 2026-09-21 it said *"All 1,869
tokenized stocks … two issuers"*. 1,869 is the count from **before a third issuer existed** and it
was sitting in a **Public** field — the same figure that rotted in Stocklana's short description
(`_submission/short-alternatives.txt`). It also pitched the disclosure product, which
[`GTM.md`](../docs/cwf-2026/GTM.md) decided not to lead with, and does not mention the swap at all.

---

## Project name · Public

```
Confide
```

## Brief description · Public · ≤500

```
Two parties settle tokenized stock against a stablecoin in one Solana transaction, and neither publishes what moved. Delivery versus payment with nobody in the middle: the transaction is the clearing house. Every tokenized stock on Solana already ships confidential balances — all 1,992 of them, three unrelated issuers, auditor slot empty on every one. So I counted the accounts actually using it. Across 330,266 live accounts on Apple, NVIDIA, SpaceX and Anthropic: zero. Shipped, gated, unused.
```

## Project website · Public

```
https://psyto.github.io/confide/
```

## What are you building, and who is it for? · ≤1000

```
A confidential settlement layer for tokenized equity. Two holders agree a price off chain; Confide builds the zero-knowledge proofs Solana will not assemble, lets each side decrypt the other's amount out of the verified proof context before signing, and settles both legs in one transaction. Either both move or neither does.

Devnet today: 50,000 shares against $8,750,000, two signatures. All four accounts are ordinary associated token accounts and all four still read a public balance of 0. A second trade settles against a mint shaped like PayPal's PYUSD, which charges a fee — that leg needs a different instruction, five proofs instead of three, and one proof too large to fit a transaction, staged through a record account. Two rule sets, settled atomically.

For a desk accumulating or unwinding size: every on-chain purchase assembles the position in public and moves the price against it. Then securities lending, where lending your book is how you publish it.
```

## Why did you decide to build this, and why build it now? · ≤1000

```
I set out to build a loan against tokenized stock and hit one wall every time. Collateral needs a third party to hold it, that party needs a confidential account, and autoApproveNewAccounts is false on all 1,992 mints. No issuer will approve one. A trade needs no third party, because a Solana transaction cannot half-happen. That was the decision.

Why now is not my timing. On 17 September the SEC granted two five-year exemptions for tokenized NMS stock. The relief covers AMM-executed trading only; a venue must publish every fill's price, size, time and direction within ten minutes, and a Tier 1 name is capped at 0.25% of daily volume. The sanctioned venue publishes the size by regulation, and size cannot go there anyway.

A pool could never be confidential: its reserves are public and a trade moves them by exactly the traded amount. That was my structural finding. It is now a written condition of the only US venue that may legally operate. The lit venue exists. Nobody built the block.
```

## How does your product use these chains? · ≤500

```
Solana only. No bridge, no second chain.

Token-2022 confidential transfers hold the position; the trade is two of its instructions in one transaction, with Solana's atomicity where a clearing house would be. The proofs are verified by Solana's own ZK ElGamal Proof Program into context accounts and cited by address, so nobody trusts our arithmetic. One proof exceeds the 1232-byte transaction limit and is staged through spl-record. Mint findings read from mainnet-beta; trades run on devnet.
```

## What technologies are you using or integrating with? · no limit shown

```
Rust, and Solana native programs — no Anchor.

On chain: Token-2022 confidential transfers (spl-token-2022-interface, spl-token-confidential-transfer-proof-extraction) for the balances; Solana's ZK ElGamal Proof Program (solana-zk-sdk, solana-zk-elgamal-proof-interface) verifying ciphertext-commitment equality, grouped-ciphertext validity and batched range proofs into context accounts; spl-record to stage the one proof that exceeds the 1232-byte transaction limit; address lookup tables; ComputeBudget. Confide's own seizure program is a native Solana program deployed to devnet.

Read-only integrations: Kamino Lend, decoded from its published source at a pinned commit — no deployment and nothing asked of them. Mint and account findings are read from mainnet-beta by scripts in this repository.

Reused from my own earlier work, disclosed: aperture-core as an unmodified git dependency, and aperture-receipts as a devnet program Confide calls.

Tooling: Solana CLI and spl-token, cargo, Python for the scan and consistency scripts, Puppeteer and ffmpeg to render the video from the live page rather than a mock of it.

AI tools: Anthropic's Claude for drafting and implementation, and OpenAI's Codex for adversarial review — every review request and its result are committed together in docs/reviews/, and several findings from both were rejected after being checked against the real files.
```

**The form asks for AI tools by name.** Answering straight costs nothing and the evidence is
already committed: every review payload sits in `docs/reviews/payloads/` beside its result.

## Which chains · select

```
Solana   (only — no other chain is integrated)
```

## Category · Public

```
Real World Assets (RWA)
```

## Is your project a mobile-focused dApp?

```
No
```

## Where is your team primarily based? · Public

```
Japan
```

## Team Telegram contact · founder enters directly — NOT recorded here

**Deliberately absent.** The form does not mark this field Public, and it is used for prize
distribution and accelerator interviews. **This repository is public**, so writing the handle here
would expose it more widely than the form does. The founder holds it and types it in; what is
recorded is that the field is filled, never the value.

## Accelerator application · founder decided to apply, 2026-09-21

**Include it.** The application opens fields this file has not seen — paste them and they get the
same treatment as the rest: written here, counted against the form's own limits, and checked for
figures the chain does not report.

## Notes for judges — anyone not listed who did meaningful work · ≤600

```
No. Confide is one person's work. Code review during the window was done by OpenAI's Codex against payloads committed alongside the results in docs/reviews/, and the drafting assistant was Anthropic's Claude; every finding either produced was verified against the real files before being acted on, and several were rejected as wrong. The narration is the founder's own voice. No collaborator, contractor or teammate contributed.
```

## Anything else judges should know · ≤500

```
Pre-existing work, disclosed: Confide depends on psyto/aperture (Apache-2.0, public) at tag v0.5.1 — aperture-core as an unmodified git dependency, and aperture-receipts as a devnet program Confide calls rather than compiles. Everything else here is new.

This repository predates the CWF window. Work inside it is cwf-2026-baseline..HEAD, from 765b8bc — see docs/WORK-WINDOW.md.

Also submitted to Stocklana on 2026-09-15, from the same repository.

Traction is zero.
```
