# Collateral admission packets

**Two of these carry the argument, and they carry different halves of it.**

| | why it is here | what it has | what it lacks |
|---|---|---|---|
| [`NVDAx`](NVDAx.md) — **the control** | shows what a market that *works* looks like | a live price, real deposits, borrowing happening now, and authorities split across four keys | nothing; it is the case where every number is real |
| [`SPCX.US`](SPCX.US.md) — **the blocked case** | shows where the motive is undeniable: pre-IPO exposure nobody wants broadcast | the clearest reason a holder would refuse to publish | a price, any deposits, and five authorities sit in one key |

Leading with SpaceX alone would trade the strongest evidence for the strongest motive. Leading
with NVDA alone would do the reverse. **The market is the aggregate below; SpaceX is why anyone
would care; NVDA is the one where it already demonstrably matters** — and it is also the mint
the devnet mechanism runs against, so the proof and the market point at the same asset.

One per tokenized stock that **already has a Kamino reserve**. Generated from mainnet by
`./scripts/packet.sh --all`, so a document here disagrees with the chain only when something
changed. The question each one asks is the same:

> A holder who will not post this collateral publicly — what would it take to let them post it
> at all?

Across all of them: **$21,125,233 deposited**, **$81,634,727 of borrowing already authorised** by these caps
and LTVs, and **$0 of it reachable while a position stays confidential**. See
[`../KAMINO.md`](../KAMINO.md) for why, and `./scripts/capacity.sh` to recompute.

| | issuer | LTV | cap | reserves | authorised |
|---|---|---|---|---|---|
| [`AAPLx`](AAPLx.md) | Backed | 40 % | 2,000 | 1 | $270,554 |
| [`CRCLx`](CRCLx.md) | Backed | 30 % | 50,000 | 1 | $1,276,125 |
| [`GOOGLx`](GOOGLx.md) | Backed | 60 % | 12,000 | 1 | $2,506,937 |
| [`HOODx`](HOODx.md) | Backed | 30 % | 12,000 | 1 | $395,280 |
| [`METAx`](METAx.md) | Backed | 35 % | 0 | 1 | *no price* |
| [`MSTRx`](MSTRx.md) | Backed | 30 % | 90,000 | 1 | $3,571,020 |
| [`MU.US`](MU.US.md) | Backpack | 40 % | 2,500 | 1 | *no price* |
| [`NVDAx`](NVDAx.md) | Backed | 55 % | 18,000 | 2 | $16,069,819 |
| [`QQQx`](QQQx.md) | Backed | 70 % | 16,000 | 3 | $24,752,655 |
| [`SKHY.US`](SKHY.US.md) | Backpack | 40 % | 15,000 | 1 | *no price* |
| [`SPCX.US`](SPCX.US.md) | Backpack | 40 % | 15,000 | 1 | *no price* |
| [`SPYx`](SPYx.md) | Backed | 73 % | 20,000 | 3 | $29,031,675 |
| [`STRCx`](STRCx.md) | Backed | 50 % | 20,000 | 1 | $1,065,825 |
| [`TSLAx`](TSLAx.md) | Backed | 55 % | 20,000 | 1 | $4,026,440 |

*`cap` and `LTV` are the largest reserve's, where a symbol has more than one. `authorised` is
summed across all of a symbol's reserves at each one's own price; a reserve that has never been
refreshed carries no price and is left out rather than guessed.*
