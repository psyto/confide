# The SEC built the tape for tokenized equity. Nobody built the block.

**Private block trades for tokenized stocks: a confidential stock-to-stablecoin swap that settles in
one Solana transaction, with neither side publishing what moved.** Confide builds the proofs the
chain will not assemble and lets each side check the other before signing, with nobody in the middle.

**Block trades have always settled away from the tape.** On **2026-09-17** the SEC gave tokenized
stock five years of relief — then set the conditions. It covers trading **executed by an AMM**,
where every fill's **size**, time and direction is published **within ten minutes**, and a Tier 1
name is capped at **0.25% of average daily volume**.

**A desk cannot go there.** Confide settles that trade off the tape. Delivery versus payment is what
a clearing house is for — neither party goes first, so finance inserts a central counterparty,
margin and a day of lag. A Solana transaction is all-or-nothing, so **the transaction is the
clearing house**. Not a venue, so the exemption neither covers it nor is needed.

## Why nobody has built it

Every tokenized stock on Solana already ships the feature this needs: **all 1,992** run Token-2022
with confidential transfers **on** and the auditor slot **empty** — every mint checked, not sampled.

**They did not miss it** — the same 1,992 run `permanentDelegate`, `pausableConfig` and a transfer
hook. Token-2022's only disclosure model is **mint-wide**: an auditor key reads every transfer made
while it is set, and cannot be scoped to one holder, one counterparty or one amount. **Fill it and
everybody is readable; leave it null and the chain offers nothing.**

So I counted accounts — **490,673 across the six mints that have holders. Three have configured a
confidential account. Zero are approved** (`./scripts/usage-scan.sh`, 24 September) — two on
`NVDAx`, one new on `AAPLx`. **None can receive one until an issuer approves it.**

**Which makes the first trade through that gate an issuance, not a swap between two holders** — the
party who can open the account is one of the two. These mints are issued outside the US and are not
NMS stock; the order is about the market being built, not them.

## Working end-to-end, devnet, today

| | |
|---|---|
| **Issuance, and the gate both ways** | 20,000 shares against **$3,500,000**. Sent before the issuer signed it was **refused on chain** — `Custom(24)`, *Account not approved for confidential transfers*; one instruction from the issuer and the same transaction **settled**. Auditor slot **empty** throughout: the issuer is the sender and needs no key to read what they sent. `./scripts/issue-e2e.sh` |
| **Then between two strangers** | `swap-offer` → `swap-accept` → `swap-settle` → `swap-sign`, two machines sharing nothing but public keys. 50,000 shares ↔ **$8,750,000**. `4t6HxA36…` |
| **Against a mint shaped like PYUSD** | it charges a fee, so that leg takes a *different instruction*, five proofs not three, one too large for a transaction — staged in a record. `5ZrJPGRL…` |
| **Nothing published, nobody trusted** | every account is an ordinary ATA and still reads `0`; each side decrypts the other's amount out of the verified context, then **rebuilds the transaction and compares it byte for byte** before signing |

104 tests, 44 over the seizure program. `./scripts/healthcheck.sh` re-checks every claim against the
chain — judging runs weeks and devnet resets.

## The claim I got wrong, and how you can tell

I called that last check the safety step. **An adversarial review found it was signing an object it
had never compared to the one it showed you.** The rebuild is the fix and caught a second bug on its
first run. Every review request and reply is committed: [`docs/reviews/`](docs/reviews/).

## What is not built

- **The gate on a real mint.** The demo's issuer is a devnet testbed whose approval key is mine. On
  `NVDAx` two accounts have asked and none is approved.
- **Matching.** Settlement is done; finding the other side is not — bringing buyers and sellers
  together is the exchange definition at Rule 3b-16, so it stays off.
- **The lending half is parked.** Kamino runs 19 live markets in these tokens — **$24.1m deposited,
  $85.5m authorised, $0 reachable confidentially** (`constraints.rs:187`). A lender who cannot read
  a balance cannot price it.
- **Traction is zero.** No pilot, no user, no issuer asked.

## Try it — two minutes, nothing needed from me

**https://psyto.github.io/confide/** decodes the six devnet trades in your own browser. Then open a
confidential position yourself, on a devnet issuer gated as all 1,992 are, its approval key
published: `git clone https://github.com/psyto/confide && ./scripts/testbed-join.sh`

## Built on

Original work except where declared: `aperture-core`, `aperture-receipts` (Apache-2.0, my
pre-existing engine), `spl-token-2022-interface`. The swap, the seizure program, the proofs, the
equity layer and the demo are new.
