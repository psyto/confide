# Collateral admission packets

One per tokenized stock that **already has a Kamino reserve**. Generated from mainnet by
`./scripts/packet.sh --all`, so a document here disagrees with the chain only when something
changed. The question each one asks is the same:

> A holder who will not post this collateral publicly — what would it take to let them post it
> at all?

Across all of them: **$21,102,146 deposited**, **$81,634,727 of borrowing already authorised** by these caps
and LTVs, and **$0 of it reachable while a position stays confidential**. See
[`../KAMINO.md`](../KAMINO.md) for why, and `./scripts/capacity.sh` to recompute.

| | issuer | LTV | cap | reserves | authorised |
|---|---|---|---|---|---|
| [`AAPLx`](AAPLx.md) | Backed | 40 % | 2,000 | 1 | $265,906 |
| [`CRCLx`](CRCLx.md) | Backed | 30 % | 50,000 | 1 | $1,294,950 |
| [`GOOGLx`](GOOGLx.md) | Backed | 60 % | 12,000 | 1 | $2,489,833 |
| [`HOODx`](HOODx.md) | Backed | 30 % | 12,000 | 1 | $397,602 |
| [`METAx`](METAx.md) | Backed | 35 % | 0 | 1 | *no price* |
| [`MSTRx`](MSTRx.md) | Backed | 30 % | 90,000 | 1 | $3,500,550 |
| [`MU.US`](MU.US.md) | Backpack | 40 % | 2,500 | 1 | *no price* |
| [`NVDAx`](NVDAx.md) | Backed | 55 % | 18,000 | 2 | $15,544,147 |
| [`QQQx`](QQQx.md) | Backed | 70 % | 16,000 | 3 | $24,332,205 |
| [`SKHY.US`](SKHY.US.md) | Backpack | 40 % | 15,000 | 1 | *no price* |
| [`SPCX.US`](SPCX.US.md) | Backpack | 40 % | 15,000 | 1 | *no price* |
| [`SPYx`](SPYx.md) | Backed | 73 % | 20,000 | 3 | $28,829,891 |
| [`STRCx`](STRCx.md) | Backed | 50 % | 20,000 | 1 | $1,055,722 |
| [`TSLAx`](TSLAx.md) | Backed | 55 % | 20,000 | 1 | $3,923,920 |

*`cap` and `LTV` are the largest reserve's, where a symbol has more than one. `authorised` is
summed across all of a symbol's reserves at each one's own price; a reserve that has never been
refreshed carries no price and is left out rather than guessed.*
