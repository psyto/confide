# The SEC built the tape for tokenized equity. Nobody built the block.

**Confidential delivery-versus-payment for tokenized stocks on Solana: a stock-to-stablecoin swap in
one transaction, with neither side publishing what moved.** Confide builds the proofs the chain will
not assemble for you and lets each side check the other before signing, with nobody in the middle.

**Block trades have always settled away from the tape.** On **2026-09-17** the SEC gave tokenized
stock five years of relief — then set the conditions. It covers trading **executed by an AMM**,
where every fill's **size**, time and direction is published **within ten minutes**, and a Tier 1
name is capped at **0.25% of average daily volume**.

**A desk cannot go there.** Confide settles that trade off the tape instead. Delivery versus
payment is what a clearing house is for — neither party goes first, so finance inserts a
central counterparty, margin and a day of lag. A Solana transaction is all-or-nothing, so **the
transaction is the clearing house**. This is not a venue, so the venue exemption neither covers it
nor is needed.

## Why nobody has built it

Every tokenized stock on Solana already ships the feature this needs: **all 1,992** run Token-2022
with confidential transfers **on** and the auditor slot **empty** — every mint checked, not sampled.

**They did not miss it** — the same 1,992 run `permanentDelegate`, `pausableConfig` and a transfer
hook. Token-2022's only disclosure model is **mint-wide**: an auditor key reads every transfer made
while it is set, and cannot be scoped to one holder, one counterparty or one amount.
**Fill it and everybody is readable; leave it null and the chain offers nothing.**

So I counted accounts — **469,477 across the six mints that have holders. Two have configured a
confidential account. Zero are approved** (`./scripts/usage-scan.sh`, 22 September), both on
`NVDAx`. **Neither can receive a confidential transfer until an issuer approves it, and as of that
scan neither was approved.**

These mints are issued outside the US and are not NMS stock; the order is about the market being
built, not them.

## Working end-to-end, devnet, today

| | |
|---|---|
| **Two strangers, four files** | `swap-offer` → `swap-accept` → `swap-settle` → `swap-sign`, two machines sharing nothing but public keys. `4t6HxA36…`, 2 signatures |
| **Stock for cash, one transaction** | 50,000 shares ↔ **$8,750,000** — $175/share, agreed off chain. `4gzku3FW…`. `./scripts/swap-e2e.sh` |
| **Against a mint shaped like PYUSD** | it charges a fee, so that leg takes a *different instruction*, five proofs not three, one too large for a transaction — staged in a record. `5ZrJPGRL…` |
| **Neither size published** | every account involved is an ordinary ATA and still reads `0` |
| **Nobody is trusted** | each side decrypts the other's amount out of the verified context, then **rebuilds the transaction and compares it byte for byte** before signing |

104 tests, 44 over the seizure program. `./scripts/healthcheck.sh` re-checks every claim against the
chain — judging runs weeks and devnet resets.

## The claim I got wrong, and how you can tell

I called that last row the safety step. **An adversarial review found it was signing an object it had
never compared to the one it showed you.** The rebuild is the fix, and on its first run it caught a
second bug of mine. Every review request and its reply are committed:
[`docs/reviews/`](docs/reviews/).

## What is not built

- **The gate.** A confidential account needs the issuer's signature. On the mirror mints that step
  is in the demo; on `NVDAx` two accounts have now asked and Backed has not answered.
- **Matching.** Settlement is done; finding the other side is not — bringing buyers and sellers
  together is the exchange definition at Rule 3b-16, so it stays off.
- **Pools, ever.** A pool's reserves are public and a trade moves them by exactly the amount traded,
  so anything settled against one publishes the size.
- **The lending half is parked.** Kamino runs 19 live markets in these tokens — **$24.0m deposited,
  $86.2m authorised, $0 reachable confidentially**; its program refuses a deposit from an account
  holding value confidentially (`constraints.rs:187`). A lender who cannot read a balance cannot
  price it, **so that half waits on a venue and the swap waits on nobody.**
- **Traction is zero.** No pilot, no user, no issuer asked.

## Try it — two minutes, nothing needed from me

**https://psyto.github.io/confide/** decodes the four devnet trades in your own browser. Then open a
confidential position yourself, on a devnet issuer gated as all 1,992 are, its approval key
published: `git clone https://github.com/psyto/confide && ./scripts/testbed-join.sh`

## Built on

Original work except where declared: `aperture-core`, `aperture-receipts` (Apache-2.0, my
pre-existing engine), `spl-token-2022-interface`. The swap, the seizure program, the proofs, the
equity layer and the demo are new.
