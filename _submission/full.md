# Stock for cash, in one transaction, and neither side publishes what moved.

## What Confide does

**Two parties settle tokenized stock against cash in one transaction, and neither publishes what
moved.** Confide builds the zero-knowledge proofs the chain will not assemble for you, and lets
each side check the other's amount before signing — **with nobody in the middle**.

Delivery versus payment is what a clearing house exists for: neither side goes first, so finance
inserts a central counterparty, membership, margin and a day of lag. A Solana transaction is
all-or-nothing, so **the transaction is the clearing house**.

## Working end-to-end, devnet, today — `./scripts/swap-e2e.sh`

| | |
|---|---|
| **Stock for cash, one transaction** | 50,000 shares ↔ **$8,750,000** — $175/share, agreed off chain. `4gzku3FW…`, 2 signatures, 29,849 compute units |
| **Against a mint shaped like PayPal's PYUSD** | it charges a fee, so that leg needs a *different instruction*, five proofs not three, and one proof too large to fit a transaction at all — staged through a record account. `5ZrJPGRL…` carries `confidentialTransfer` **and** `confidentialTransferWithFee` in one transaction |
| **Neither size published** | all four accounts are ordinary ATAs — what a wallet makes — and all four still read `0` |
| **Nobody is trusted** | before signing, each side decrypts the other's amount straight out of the verified proof context. The amount is encrypted to the *recipient* too, so a leg that underpays cannot be signed by mistake |
| **Nobody in the middle** | two Token-2022 instructions, two signatures: no escrow, no custodian, no oracle. The hard part is the proofs — one does not fit in a transaction at all |

104 tests, 44 over the seizure program. `./scripts/healthcheck.sh` re-checks every claim against the
chain and exits with the number that died — judging runs weeks and devnet resets.

## Why anybody wants it

Read any tokenized stock on Solana right now, no wallet: Token-2022, confidential transfers **ON**,
auditor key **empty**. **1,992 of them**, three unrelated issuers. Every mint checked, not sampled.

So I stopped reading settings and counted accounts. **329,536 token accounts across Apple, NVIDIA,
SpaceX and Anthropic. Zero are configured for confidential transfers** (`./scripts/usage-scan.sh`).

Not "few". Zero — every mint needs the issuer's signature to open one, and nobody has asked.
**There is no incumbent here and nothing to be late to.**

## It is not only equities

USDC, USDT and USDS cannot move confidentially — legacy SPL, no extensions. **PYUSD and USDG can**,
and land on the *identical* configuration: gate closed, auditor slot empty, one key as confidential
authority, permanent delegate and freeze authority. **PayPal's dollar ships the same unusable
privacy feature behind the same door.** Four issuers, two asset classes, one dead end — the
substrate, not somebody's choice.

## Who uses it first

**A desk accumulating or unwinding size.** Every purchase settles on chain, so the position is
assembled in public and the price moves against it the whole way — and selling on a book publishes
the size a second time. This publishes nothing: not the quantity, not the price it implies, not
that either party held anything at all.

Then **securities lending**, where lending your book is how you publish your book.

## What is not built

- **The gate.** A confidential account needs the issuer's signature. On the mirror mints that step
  is in the demo; on `NVDAx` it is a conversation nobody has had.
- **Matching.** Settlement is done; finding the other side is not.
- **Price.** Nothing here says 50,000 shares are worth $8.75m. The two parties do.
- **Pools, ever.** A pool's reserves are public and a trade moves them by exactly the traded amount,
  so anything settled against one publishes the size. Structural, not a roadmap item.
- **Traction is zero.** No pilot, no user, no issuer asked.

## The collateral half also runs

Kamino runs 19 live markets in these tokens: **$22.0m deposited**, **$83.0m authorised**, **$0
reachable confidentially** — its program refuses a deposit from an account holding value
confidentially (`constraints.rs:187`). Confide proves a floor over an escrow's own ciphertext and
settles a default without the borrower: devnet loan `26QJWCRw…` reads `seized`, `9yfKfFD5…` reads
`released`. A lender who cannot read a balance still cannot price it — so that half waits on a
venue, and the swap does not wait on anyone.

## Try it — no wallet, no install

**https://psyto.github.io/confide/kamino.html** — pick any of the 1,992; your browser reads it from
mainnet against Kamino's own rules. Walkthrough: youtu.be/p1aQuEnzhQk

## Built on

Original work except where declared: `aperture-core`, `aperture-receipts` (Apache-2.0, my own
pre-existing engine), `spl-token-2022-interface`. The swap, the seizure program, the proofs, the
equity layer and the demo are new. github.com/psyto/confide
