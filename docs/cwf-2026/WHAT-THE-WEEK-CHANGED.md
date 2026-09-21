# What two days of measurement did to Confide — 2026-09-22

Four claims died between 09-20 and 09-22. This is what is left, what it is worth, and what to do
about it.

---

## The four that died, and the shape they shared

| claim | killed by |
|---|---|
| *"You cannot pay a dividend pro rata to a holder whose balance you cannot read"* | a mint-level multiplier running on mainnet — and then the mechanism was explained wrongly here too, and Codex caught that |
| *"A confidential holder cannot be counted in a vote"* | voting is not on chain. You redeem first, then vote through the broker |
| *"Every passage through the conversion door publishes its size"* | true only where redemption is an ordinary `Burn`. Treasury transfer, batching, reissuance and `ConfidentialMintBurn` each defeat it |
| *"The account count is dust"* | holds for four mints and **not for `SPCX.US`**, the one with the volume |

**They share a shape.** Three of the four were arguments that **a rule or a right compels
disclosure**. Every one was routed around, because these are tracker and entitlement structures
whose legal layer sits off chain — a right not exercised on chain cannot collide with on-chain
confidentiality.

**What survived is every claim that was a measurement rather than an argument.** That is the
lesson, and it is not a small one for a project whose entire credibility rests on being checkable.

---

## What still stands, all measured

| | |
|---|---|
| **1,992 of 1,992** tokenized-equity mints: confidential transfers on, `autoApproveNewAccounts` false, auditor slot null | `slot-scan.sh` |
| **0 confidential accounts**, now across six mints and three issuers | `usage-scan.sh` |
| **Kamino: $23.2m deposited, $84.0m authorised, $0 reachable confidentially** | `capacity.sh` |
| **A pool cannot be confidential** — and since 2026-09-17 that is also a written condition of the only US venue that may legally operate | first principles, then the SEC |
| **`SPCX.US` has real holders** and cannot hold confidentially — $439M in its first week, gate shut | `holders-scan.sh` and direct reads |
| **Backed's largest holder is issuer-side**, 52.4% of NVDAx and 74.8% of AAPLx | direct reads |
| **None of the six mints carries `ConfidentialMintBurn`** | direct reads |

**The swap still settles.** Nothing measured this week touched the mechanism.

---

## The reframe the measurements force, and it is an improvement

**The pitch has been about a holding.** *A holder who would rather their position were not public.*

**The measurements say that holder barely exists on chain** — and where they do exist, at size, on
`SPCX.US`, they cannot be confidential anyway. Worse, the people with real exposure are already
invisible, inside a broker.

**The product is not about a holding. It is about a transaction.**

- A holding at rest reveals size to anyone who looks — but almost nobody holds at rest on chain.
- A **transaction** reveals size at the moment it matters most: when you are accumulating, exiting,
  or converting.
- And **every route out publishes it.** Into a pool: the reserves move by exactly the traded
  amount. Through the conversion door: as these mints are configured, supply moves by exactly the
  redeemed amount.

> **Confide is not privacy for what you hold. It is confidentiality for what you do.**

That is what `swap-e2e.sh` actually demonstrates. The balance reading `0` is a consequence of the
mechanism, not the product.

---

## A new instance of the core finding, worth one command

Codex surfaced `ConfidentialMintBurn` — a Token-2022 extension whose `current_supply` is a
ciphertext, so an issuer can mint and burn without moving public supply.

**None of the six mints checked has it.** If that holds across all 1,992, the finding widens from

> *the confidential transfer capability is shipped and unused*

to

> **every confidential capability Token-2022 ships is shipped and unused.**

That is the same claim, a size larger, at the cost of one scan. **It is the highest-value thing
available this week** and it is the kind this repository is built for.

---

## What it does to the submission

**The numbers are safe.** Every figure in the submitted text survived. What needs a pass is
framing, and one undercount:

1. **`usage-scan.sh` samples two dead Backpack mints.** `AAPL.US` and `TSLA.US` have zero accounts,
   so Backpack contributes **0** to the 330,266 headline while its live mints hold tens of
   thousands. The headline understates — safe in direction, wrong in fact.
2. **Do not present the account count as a market.** It is a measure of an unused capability, not
   of demand. A judge who reads the distribution will find 98% of it under one share.
3. **`SPCX.US` is the strongest single sentence available** and is in none of the submissions:
   *the most traded tokenized stock on Solana, $439M in its first week, and nobody can hold it
   privately.*

---

## The three things to build this week, revised

1. **Scan all 1,992 for `ConfidentialMintBurn`**, and fix the Backpack sampling while the scan is
   open. One measurement, two results, and the finding gets larger.
2. **`swap-offer` / `swap-accept`** — unchanged by any of this. It makes *runnable by a stranger*
   true, and it is the issuance rail.
3. **Re-frame around the transaction rather than the holding**, in the script first and the video
   in week 4. Test it against the artifact now, which is week 2's own beat.

**Not this week:** the pitch and demo videos, the key rotation, RFQ, any second chain.
