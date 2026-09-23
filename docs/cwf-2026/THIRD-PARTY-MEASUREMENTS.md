# What somebody else measured — Blockworks Research, read 2026-09-23

*Tokenized Equities on Solana: From Issuance to Execution*,
https://app.blockworksresearch.com/research/tokenized-equities-on-solana-from-issuance-to-execution

**Pasted by the founder; nothing here re-derives it.** This file records what it says, what it
confirms, what it narrows, and the one thing it takes away — because a report that only supported
the pitch would not be worth a file.

## What it takes away

> **"Robinhood Chain recently overtook Solana in tokenized-equity volume in August."**

`docs/cwf-2026/WHY-THE-SLOT-IS-EMPTY.md` already says *"That Solana leads in tokenized equity"* has
never been measured here and that **no submission may lean on it.** That instruction was written on
caution; it now has a named counterexample. **The caution was right and stays.**

The report does qualify it — much of Robinhood Chain's flow runs through *"Uniswap
stock-to-memecoin pools rather than direct stablecoin pairs"*, so the headline reflects memecoin
demand as well. That is a reason not to overreact, not a reason to claim the lead.

## What it narrows, and this one was in the film

The old scene 9 led with the structural argument: **a pool's reserves are public and a trade moves
them by exactly the amount traded.** Measured:

> **"Prop AMMs handled over 60% of Backpack volume while barely touching xStocks, where AMM pools
> handled 86% of volume."**

A proprietary AMM quotes *"from live stock-market data and their own short-term view of fair
value"*, not from its reserves. **So the structural leg lands on the minority of the volume that
matters most here** — a judge who has read this report notices immediately.

**The argument has two legs and only one of them was leading.**

| leg | what it covers |
|---|---|
| **structural** — reserves reveal the size | reserve-priced pools only |
| **regulatory** — a TSV must publish every fill's **size** within ten minutes | **everything executed by an AMM, prop AMMs included** |

The regulatory leg does not care how the AMM prices. Scene 9 leads with it now.

**And the gate still applies to a prop AMM.** Quoting off external data does not exempt it from
`autoApproveNewAccounts`: to settle confidentially it would need an approved confidential account
like anybody else, and zero of 469,477 have one.

## What it confirms

| | |
|---|---|
| **Backed was acquired by Kraken** | already in `README.md` — no correction needed |
| **Backpack detokenizes into a brokerage entitlement** | matches what this repository recorded, though the report calls the on-chain leg a **BVI-issued trust receipt** where `ISSUANCE.md` reaches for UCC Article 8. Those describe different layers and the wording here should not harden past what a primary source says |
| **Tokenized equities as collateral is the expected next use** | *"could eventually serve as collateral for both borrowing and equity perp positions"* — the parked half of this repository, named by somebody else |

## The number that helps most, and it is not one of ours

> **"$243M of observed purchase notional had not been resold by the same tracked identity for at
> least a week, including $220M still unmatched after two weeks."**

This repository measures the holder base by **accounts**: of 465,498, **5,755** hold ≥1 share and
**268** hold ≥100 (`web/holders.json`). That framing says the market is small, and the submission
says so.

**Both are true and they are not in tension** — few identities, large notional. Concentrated
holders are exactly the *"desk accumulating or unwinding size"* the submission names as the first
user, and **$220M of two-week-plus inventory is a better description of that desk than a count of
accounts is.**

It is a third party's figure, not a re-derivable one, so it belongs here and not in a submitted
field. But if the account count ever reads as *"the market is too small to matter"*, this is the
measurement that answers it.

## What it says about turnover, which cuts the other way

> *"~85% of purchase notional was resold within one day"*

Most volume is short-horizon. **That is the secondary market, not issuance** — so the film's new
order (issuance first, because it is the only trade the gate lets through) describes how the market
**opens**, not where its volume **is**. The submission does not claim otherwise and should not
start.
