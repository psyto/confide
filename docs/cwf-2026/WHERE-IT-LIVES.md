# Where tokenized equity actually lives — 2026-09-19

The founder asked whether Confide could let people outside Solana buy or borrow Solana's tokenized
stocks, and said the premise was that most issuance and circulation is on Solana.

**Measured, because the first two framings I built on this were wrong.** What survives is the
founder's original premise, with numbers under it — and it is not what I was about to write.

## Issuance is not concentrated. Circulation is.

Backed deploys **all 828 assets to ten chains**, natively, with the same ISIN. Solana is one of ten.
So "issued mostly on Solana" is false.

Supply of `NVDAx`, by chain:

| | supply | |
|---|---|---|
| Solana | 321,277 | 49.8% |
| Arbitrum | 108,045 | 16.8% |
| Ink | 104,812 | 16.3% |
| BinanceSmartChain | 41,194 | 6.4% |
| Mantle | 40,958 | 6.4% |
| Optimism | 28,274 | 4.4% |

*(Ethereum unreachable; the percentages are of the chains that answered.)*

**On that table I was about to write that 213,000 NVDAx sits on chains with no lending market.**
Then the holders were checked:

| | who holds it |
|---|---|
| **Arbitrum** | **108,039 of 108,045 — 99.99% — in one address**, `0x5F7A4c11…` |
| **Ink** | **96,614 of 104,812 — 92% — in the same address** |
| **Solana** | the largest is `Sk6YCd1S…` at **53.3%**, owned by `S7vYFFWH…` — **Backed's own key**, which holds `scaledUiAmountConfig.authority` on AAPLx, NVDAx, SPCXx and TSLAx. A second account with the same owner adds 2.5%. |

So:

> **Off Solana, the supply is one entity's inventory.** Arbitrum is 99.99% a single address.
>
> **On Solana, about 56% is the issuer's own inventory and about 44% is in other hands** — a long
> tail of accounts holding 1–5% each, ordinary wallets rather than pools.

**44% against 0.01%.** The founder's premise holds on circulation even though it is false on
issuance, and the difference is the whole point.

## And the credit only exists in one place

Morpho creates markets permissionlessly — anyone could open one for `NVDAx` on Arbitrum today.
Across **all 828 xStocks on every chain Morpho covers**:

```
Morpho markets taking ANY xStock as collateral, on ANY chain: 5
   Ethereum  SPYx  LLTV 86%  loan USDC
   Ethereum  SPYx  LLTV 62%  loan AUSD   (×3 more)
```

**One underlying.** Kamino, on Solana, has **19 reserves across 14 underlyings**.

## What this is evidence for

Not a new project. It answers one criterion Stocklana judges explicitly — *a reason it belongs on
Solana* — with a measurement instead of a feature list:

> **The issuer put this asset on ten chains. It is only held on one, and only lent against on one.**
> Confide's finding is about the place where the market actually formed, not the place where the
> code happens to run.

## What it is not evidence for

- **Not demand for confidential collateral.** Nobody has been asked. Traction is zero.
- **Not "stranded holders".** That framing died with the Arbitrum holder check.
- **Not a complete lending census.** Morpho only — Aave and Compound are governance-gated and would
  not list these, but Silo, Euler, Fluid and Fraxlend were not checked.
- **Not retail distribution on Solana either.** 1–5% positions are desks and funds, not individuals.

## The tool

`RPC=<endpoint> ./scripts/holders.sh <SYMBOL>` — supply, the largest accounts, and **which of them
are the issuer's own keys**, separated. Its first version did not separate them and called 88.5% in
twenty accounts "distributed", which is how a claim about holders nearly reached the submission on
the strength of a supply figure.
