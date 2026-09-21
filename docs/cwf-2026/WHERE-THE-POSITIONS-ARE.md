# Where tokenized equity actually sits — measured 2026-09-21

The founder asked whether an investor who buys tokenized stock ends up holding it in their own
on-chain account, or as a book entry inside an issuer's or custodian's bulk account.

**Measured, not reasoned.** Every figure below is one `getProgramAccounts` call against mainnet and
is reproducible.

---

## The answer: there is almost no on-chain holder base

| mint | issuer | accounts with a balance | median holding | **hold < 1 token** | top 1% hold |
|---|---|---|---|---|---|
| NVDAx | Backed | 99,028 | **0.0046** | **98.0%** | — |
| AAPLx | Backed | 35,754 | **0.0013** | **98.6%** | **99.4%** |
| ANTHROPIC | PreStocks | 37,719 | **0.0067** | **95.7%** | **92.0%** |
| AMC.US | Backpack | 4,236 | **0.0014** | **98.8%** | **84.9%** |

**The median NVDAx holder owns 0.0046 of a share.** At roughly $180 a share that is about
**eighty cents**. The 90th percentile is 0.05 of a share. Across four mints from three unrelated
issuers, **96–99% of accounts with any balance hold less than one share**, and the top 1% holds
85–99% of everything.

**The account count is dust.** 330,266 is a real number and it is not a population of investors.

---

## Where the real size is

| | |
|---|---|
| **The issuer** | one address holds **52.4% of NVDAx** and **74.8% of AAPLx**. On AAPLx it is a mint authority; on NVDAx it holds the `scaledUiAmountConfig` authority, which only an issuer has |
| **DEX pools** | on Backpack's live mints the largest holders are program-owned. One is `CAMMCzo5…`, Raydium's concentrated-liquidity program. Orca's `whirL…` appears in the NVDAx sample too |
| **A long tail of dust** | 95,721 unique owners on NVDAx. Sampled at random, 42% are funded self-custody wallets, 51% are addresses that have never held SOL, 7% are DeFi programs — and all of it is a rounding error on the total |

**So the founder's instinct is right, and the evidence for it is an absence.** If investors held
their purchases on chain, there would be a distribution of real positions. There is not one. The
positions exist — people have bought these — and the chain cannot see them, which means they are
inside an exchange or a custodian as book entries.

**What is NOT established.** No specific custodian is identified here. Two of the program owners on
Backpack's mints (`Archer8kgi…`, `DNL1tgEj…`) were not identified and are not guessed at.

---

## What this does to the pitch — the uncomfortable half first

**It guts "a holder who would rather their position were not public."** On chain, that holder
barely exists. The people with real exposure are already invisible, because they are inside a
custodian.

**It weakens the market-size reading of the headline**, though not the finding. *The capability is
shipped and unused* survives intact and is now confirmed on a fourth mint and a third issuer. But
if a judge asks *how many people would use this today*, the honest answer from this data is **very
few, on chain**. The submission must not imply that 330,266 is a market.

---

## And the stronger framing it hands over, which the old one did not have

The measurement suggests a reason the on-chain holder base is dust, and it is not apathy:

> **Today you can have self-custody or privacy. Not both.**
>
> Hold it yourself and every position, every purchase and every sale is public forever. Hold it at
> a custodian and nothing is public — but it is not yours, you have a claim on a balance sheet, and
> the entire argument for tokenizing it has been given back.
>
> **Everybody chose privacy.** That is what the dust is: the on-chain accounts are what is left
> when the real positions went somewhere the chain cannot see.

**This is a hypothesis about cause and is labelled one.** People also use custodians for fiat
rails, for convenience, and because that is where they bought. The correlation is measured; the
causation is not, and saying otherwise would be the kind of claim this repository refuses.

**But it reframes the product from a feature into a missing third option**, and unlike the previous
framing it is *consistent with* the measurement rather than embarrassed by it.

---

## What it does to the issuance thesis

**It strengthens it, substantially.**

[`ISSUANCE.md`](ISSUANCE.md) argued that the issuer is the natural counterparty because there is
nothing to match. This measurement says something stronger: **the issuer is where the size actually
is.** Half of NVDAx and three quarters of AAPLx sit in one issuer-controlled address. Any
transaction that moves real size either involves that address or a pool — and a pool cannot be
confidential, which this repository has argued from first principles and the SEC wrote down on
2026-09-17.

**So the only confidential transaction with real size on the other side is one with the issuer.**
That is the issuance and redemption rail, and it is no longer a hypothesis about workflow — it is
where the tokens are.

---

## Reproduce it

```
# per-mint balances, straight from mainnet
curl -s https://api.mainnet-beta.solana.com -H 'content-type: application/json' -d '{
  "jsonrpc":"2.0","id":1,"method":"getProgramAccounts","params":["TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb",
  {"encoding":"base64","dataSlice":{"offset":64,"length":8},
   "filters":[{"memcmp":{"offset":0,"bytes":"Xsc9qvGR1efVDFGLrVsmkzv3qi45LTBjeUKSPmx9qEh"}}]}]}'
```

The owner of each account is at offset 32, the amount at offset 64.

**This is not yet a script.** It was run by hand to answer a question, and a claim in a submission
should not rest on that — `./scripts/usage-scan.sh` is the pattern to follow if any of these
figures is going to be quoted.
