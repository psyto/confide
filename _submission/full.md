# Stock-to-stablecoin swaps, in one transaction, with neither side publishing what moved.

## What Confide does

**Two parties settle tokenized stock against cash in one transaction, and neither publishes what
moved.** Confide builds the zero-knowledge proofs the chain will not assemble, and lets
each side check the other's amount before signing — **with nobody in the middle**.

Delivery versus payment is what a clearing house exists for: neither side goes first, so finance
inserts a central counterparty, margin and a day of lag. A Solana transaction is all-or-nothing,
so **the transaction is the clearing house**.

## Working end-to-end, devnet, today — `./scripts/swap-e2e.sh`

| | |
|---|---|
| **Stock for cash, one transaction** | 50,000 shares ↔ **$8,750,000** — $175/share, agreed off chain. `4gzku3FW…`, 2 signatures, 29,849 compute units |
| **Against a mint shaped like PYUSD** | it charges a fee, so that leg takes a *different instruction*, five proofs not three, and one too large to fit a transaction — staged through a record account. `5ZrJPGRL…` carries `confidentialTransfer` **and** `confidentialTransferWithFee` together |
| **Neither size published** | all four accounts are ordinary ATAs, and all four still read `0` |
| **Nobody is trusted** | before signing, each side decrypts the other's amount out of the verified proof context — the amount is encrypted to the *recipient* too, so an underpaying leg cannot be signed by mistake |
| **Nobody in the middle** | two Token-2022 instructions, two signatures: no escrow, no custodian, no oracle |

104 tests, 44 over the seizure program. `./scripts/healthcheck.sh` re-checks every claim against the
chain — judging runs weeks and devnet resets.

## Why anybody wants it

Every tokenized stock on Solana runs Token-2022 with confidential transfers **on** and the auditor
key **empty** — **all 1,992**, three unrelated issuers, every mint checked rather than sampled.

So I stopped reading settings and counted accounts. **330,266 across Apple, NVIDIA, SpaceX and
Anthropic. Zero are confidential** (`./scripts/usage-scan.sh`). Not "few" — zero. Every mint needs
the issuer's signature to open one and nobody has asked, **so there is no incumbent here and nothing
to be late to.** The US market opened on **17 September**, when the SEC exempted tokenized-stock
venues for five years. I counted three days later.

## It is not only equities

USDC, USDT and USDS cannot move confidentially — legacy SPL, no extensions. **PYUSD and USDG can**,
and land on the *identical* configuration: gate closed, auditor slot empty, permanent delegate and
freeze authority. **PayPal's dollar ships the same unusable privacy feature behind the same door.**
Four issuers, two asset classes, one dead end — the substrate, not somebody's choice.

## Who uses it first

**A desk accumulating or unwinding size.** Every purchase settles on chain, so the position is
assembled in public and the price moves against it the whole way. **The SEC's authorised venue
publishes every fill's size within ten minutes and caps a Tier 1 name at 0.25% of daily volume** —
size cannot go there. This publishes nothing: not the quantity, not the price it implies, not that
either party held anything. Then **securities lending**, where lending your book is how you publish
it.

## What is not built

- **The gate.** A confidential account needs the issuer's signature. On the mirror mints that step
  is in the demo; on `NVDAx` it is a conversation nobody has had.
- **Matching.** Settlement is done; finding the other side is not.
- **Price.** Nothing here says 50,000 shares are worth $8.75m. The two parties do.
- **Pools, ever.** A pool's reserves are public and a trade moves them by exactly the traded amount,
  so anything settled against one publishes the size. Structural, not a roadmap item.
- **Traction is zero.** No pilot, no user, no issuer asked.

## The collateral half also runs

Kamino runs 19 live markets in these tokens: **$23.2m deposited, $84.0m authorised, $0 reachable
confidentially** — its program refuses a deposit from an account holding value confidentially
(`constraints.rs:187`). Confide proves a floor over an escrow's own ciphertext and settles a default
without the borrower, on devnet. But a lender who cannot read a balance still cannot price it, **so
that half waits on a venue and the swap waits on nobody.**

## Try it — two minutes, nothing needed from me

**https://psyto.github.io/confide/** decodes the three devnet trades in your own browser. Then open
a confidential position yourself, on a devnet issuer whose gate is shut as all 1,992 are,
its approval key published:
`git clone https://github.com/psyto/confide && ./scripts/testbed-join.sh`

## Built on

Original work except where declared: `aperture-core`, `aperture-receipts` (Apache-2.0, my own
pre-existing engine), `spl-token-2022-interface`. The swap, the seizure program, the proofs, the
equity layer and the demo are new.
