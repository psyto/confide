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

## The reframe the measurements force — and a correction to how it was stated

**Checked against the actual surfaces on 2026-09-22, and this section was partly attacking a straw
man.** The top-line framing was already transactional: README and `full.md` both open on *"neither
side publishing what **moved**"*, *"in one **transaction**"*. There was no holding-first pitch to
replace.

**What was genuinely holding-framed was the call to action**, on four live surfaces: *"open a
confidential position and **hold** something the chain reports as zero"*. And that was not merely
mis-framed, it was **understated** — as of 2026-09-22 a stranger can do the trade, not only hold.
All four now offer the trade, with the four commands and the point that steps 3 and 4 each decrypt
the other side's amount before signing.

**The delivered video is holding-framed** — *"if you hold tokenized stocks on Solana, everyone can
see what you hold"* — and stays that way, the same exemption the account count has. The week-4
presentation is where the transaction framing lands in a recording.

**The argument below still holds and is worth keeping**, because it is why the CTA was wrong:

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

**Scanned all 1,992 on 2026-09-22. The answer is zero.**

```
1992 of 1992   confidentialTransferMint      shipped, and 0 accounts use it
   0 of 1992   confidentialMintBurn          not adopted at all
```

So the finding is no longer about one extension:

> **Token-2022 ships two confidential capabilities. Every tokenized stock on Solana carries the
> first and uses none of it; not one carries the second.**

**And the same scan shows what they do adopt**, which makes the abstention deliberate rather than
inattentive — these are not issuers who ignored the extension list:

| extension | mints |
|---|---|
| `metadataPointer`, `permanentDelegate`, `defaultAccountState`, `scaledUiAmountConfig`, `pausableConfig`, `transferHook`, `tokenMetadata` | **1,992 — all of them** |
| **`confidentialTransferMint`** | **1,992 — all of them, gate shut, auditor null** |
| `transferFeeConfig`, `confidentialTransferFeeConfig` | 8 |
| **`confidentialMintBurn`** | **0** |

**Seven extensions on every single mint, configured deliberately.** The eighth is switched on and
walled off, and the ninth was never turned on. That is a much harder thing to explain away than a
count of unused accounts.

---

## What it does to the submission

**The numbers are safe.** Every figure in the submitted text survived. What needs a pass is
framing, and one undercount:

1. **`usage-scan.sh` samples two dead Backpack mints.** `AAPL.US` and `TSLA.US` have zero accounts,
   so Backpack contributes **0** to the 465,520 headline while its live mints hold tens of
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

---

# Does any of it touch confidential DvP itself?

Asked by the founder. **The mechanism is untouched. The moment it applies to is narrower than the
pitch assumed, and one part of the issuance thesis has a hole in it.**

## Untouched

Nothing measured this week contradicts the mechanism. The proofs the chain will not assemble, the
counterparty's amount decrypted out of the verified context before signing, the fee-bearing leg
staged through a record account, both legs settling or neither — **all of it still runs, and none
of the four dead claims was about any of it.**

And one thing got stronger: **a pool cannot be confidential** was this repository's own structural
finding, and since 2026-09-17 it is a written condition of the only US venue that may legally
operate.

## The hole: the conversion door is not atomic DvP as it is actually operated

The issuance thesis rests on the issuer being the natural counterparty. But read what the door
actually does:

> a token is deposited with Backpack and **burns back into a security entitlement** — a brokerage
> position, off chain.

**The payment leg is off chain.** An on-chain burn and an off-chain credit **cannot be atomic**,
so the door as operated is not delivery versus payment at all. It is delivery, then a promise.

**Confide's claim is atomicity.** It has nothing to offer a leg that leaves the chain.

**What would close it:** the issuer paying in stablecoin, on chain, in the same transaction. Then
it is DvP and Confide's mechanism applies exactly. **Whether any issuer does that is unverified**
and is the single most valuable thing to find out before building on this thesis.

## The tension nobody has stated: atomicity and confidentiality want different counterparties

| | worth most when | worth least when |
|---|---|---|
| **atomicity** — neither side goes first | the counterparty is **a stranger** | the counterparty is a regulated broker holding your custody already |
| **confidentiality** — neither side publishes | the counterparty is **where the size is**, i.e. the issuer | — |

**The two halves of the pitch point at different people.** Against the issuer, atomicity buys
little: they are creditworthy, regulated, and already hold your assets. Against a stranger,
confidentiality is worth most but there is nobody to match with.

**This is not fatal and it is not hidden.** It is the honest shape of a bilateral settlement
primitive, and naming it is better than having a judge find it.

## What the measurements actually did for DvP — the strongest version

The binding constraint was never the mechanism. It was **whether there is anybody to trade with on
chain**, and until this week the answer looked like *no*.

**`SPCX.US` answers it.** $439M in its first week. Ordinary wallets holding a thousand shares. A
real, distributed holder base with real size.

**And they are all routed through pools**, because that is the only route that exists — and a pool
publishes the size by construction, which is the finding this repository started from.

> **The counterparties exist. They are trading through the one venue that cannot keep a size
> quiet. Confide is the other route.**

That sentence was an assumption a week ago. It is measured now.
