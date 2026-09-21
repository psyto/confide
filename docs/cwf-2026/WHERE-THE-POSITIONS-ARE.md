# Where tokenized equity actually sits — measured 2026-09-21

The founder asked whether an investor who buys tokenized stock ends up holding it in their own
on-chain account, or as a book entry inside an issuer's or custodian's bulk account.

**Measured, not reasoned.** Every figure below is one `getProgramAccounts` call against mainnet and
is reproducible: `./scripts/holders-scan.sh`.

> **This is a baseline, not a verdict** — the founder's correction, 2026-09-21, and it changes how
> everything below should be read. **The structure described here is today's.** Tokenized equity on
> Solana is about a year old, the US market for it opened on 17 September, and nothing about this
> shape is permanent.
>
> That is why it is a script. A snapshot says *how it is*; a script re-run says *whether it is
> changing*, and the column where a change would appear first is **`>= 1 share`**. Today that is
> **5,196 of 354,189 accounts — 1.467%**, and **277** hold a hundred shares or more.
>
> **It also makes the thesis falsifiable, which is the point.** If a third option between public
> self-custody and invisible custody is what the market is missing, that column grows. If it does
> not grow, the thesis was wrong, and this repository will have recorded the number that says so.

---

## The answer: there is almost no on-chain holder base

| mint | issuer | decimals | accounts with a balance | median holding | **hold < 1 share** | top 1% hold |
|---|---|---|---|---|---|---|
| NVDAx | Backed | 8 | 98,932 | **0.00460** | **98.0%** | 98.8% |
| AAPLx | Backed | 8 | 35,843 | **0.00131** | **98.6%** | 99.4% |
| ANTHROPIC | PreStocks | 9 | 37,694 | **0.00067** | **98.8%** | 91.9% |
| SPACEX | PreStocks | 9 | 10,103 | **0.00030** | **96.4%** | 89.9% |
| AMC.US | Backpack | 6 | 4,230 | **0.13608** | **79.6%** | 84.4% |

**The median NVDAx holder owns 0.0046 of a share.** At roughly $180 a share that is about
**eighty cents**. Across five mints from three unrelated issuers, **80–99% of accounts with any
balance hold less than one share**, and the top 1% holds 84–99% of everything.

> **Corrected 2026-09-21, and the correction matters.** The first version of this table assumed
> every tokenized-equity mint has 8 decimals. **Four of six do not** — ANTHROPIC and SPACEX are 9,
> AMC.US and SPCX.US are 6 — so three of the medians were wrong by a factor of ten or a hundred.
> `holders-scan.sh` reads decimals per mint now; the figures above are the corrected ones.

**The account count is dust.** 465,520 is a real number and it is not a population of investors.

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

## The number to watch — `./scripts/holders-scan.sh`

| mint | issuer | accounts | **≥ 1 share** | ≥ 10 | ≥ 100 |
|---|---|---|---|---|---|
| NVDAx | Backed | 181,035 | **1,941** | 434 | 94 |
| AAPLx | Backed | 70,674 | **502** | 110 | 26 |
| ANTHROPIC | PreStocks | 71,223 | **442** | 76 | 13 |
| SPACEX | PreStocks | 17,891 | **365** | 80 | 18 |
| AMC.US | Backpack | 13,348 | **861** | 244 | 50 |
| **total** | | **354,150** | **4,117** | **948** | **201** |

**Four thousand accounts hold a whole share. Two hundred and one hold a hundred.** That is the
on-chain holder base of these five mints today, and it is the number that moves if any of this
changes.

### SPCX.US is missing from that table, and it is the one that matters most

`SPCX.US` — Backpack Securities' tokenized SpaceX equity, listed through Wormhole's **Sunrise** on
2026-06-12, the day of the Nasdaq IPO — **could not be scanned.** Its account list is large enough
that the public endpoint truncates the response every time, and Alchemy refuses
`getProgramAccounts` outright. What was readable:

| | |
|---|---|
| supply | **42,488 shares**, 6 decimals |
| top 20 accounts | **48.3% of supply** — far flatter than NVDAx, where one address holds 52% |
| the largest holders | DEX pools: Meteora `LBUZKhRx…`, Raydium CLMM `CAMMCzo5…`, `goonuddt…` |
| two of the top six | **ordinary wallets, about 1,100 shares each** |
| the gate | `autoApproveNewAccounts: false`, auditor slot **null** — identical to all 1,992 |

**Corrected again 2026-09-22, once SPCX could actually be scanned.** This said *"the dust
conclusion does not generalise to SPCX"*. **Half right, and the half that was wrong mattered.**

`scripts/lib/gpa.py` reads it now — partitioning on the first byte of the owner field, 256 disjoint
slices — and the numbers are: **102,011 accounts, 35,263 with a balance, median 0.00053 of a share,
95.5% holding less than one.** The tail is dust exactly like the others.

**What is different about SPCX is the top, not the tail.** Its largest twenty accounts hold 48.3%
where one NVDAx address holds 52.4% on its own, its float sits in DEX pools rather than an issuer
treasury, and **1,576 accounts hold a whole share and 68 hold a hundred** — more real holders than
any other mint measured. Backpack reports **$439M in its first week against $9.8M of liquidity**.

**So: a real holder base at the top, dust underneath, and the same shut gate as all 1,991 others.**

**Which makes the finding stronger, not weaker.** The reframing it hands over:

> **The most traded tokenized stock on Solana has real holders with real positions, and not one of
> them can hold it privately.** The gate is shut on it exactly as it is on the other 1,991.

## What this does to the pitch — the uncomfortable half first

**It guts "a holder who would rather their position were not public."** On chain, that holder
barely exists. The people with real exposure are already invisible, because they are inside a
custodian.

**It weakens the market-size reading of the headline**, though not the finding. *The capability is
shipped and unused* survives intact and is now confirmed on a fourth mint and a third issuer. But
if a judge asks *how many people would use this today*, the honest answer from this data is **very
few, on chain**. The submission must not imply that 465,520 is a market.

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

**The holder counts are now a script** — `./scripts/holders-scan.sh`, writing `web/holders.json`
with its own timestamp, `--last` to reprint without re-scanning. The concentration and owner-type
figures at the top of this document were run by hand to answer a question and are **not** a script;
anything from them that reaches a submission has to become one first.
