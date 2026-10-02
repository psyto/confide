# How size trades in tokenized stocks happen today — and who sees them

Researched 2026-10-02 for the videos, from primary sources where they exist. Two claims were
re-checked by hand against the source the same day (marked ✓). **Anything not traced to a primary
source is marked UNVERIFIED and must not be spoken.**

The question each row answers is the one Confide is built around: **when somebody trades size, who
can see how much?**

| | who can see the amount | in the middle | settles atomically on chain | the issuer's approval gate |
|---|---|---|---|---|
| **Solana DEX** — Raydium, Jupiter, Kamino Swap | **everyone** — an ordinary public swap | a pool | yes | not applicable |
| **Centralized exchange** — Kraken, Bybit spot xStocks | **the exchange** | the exchange, holding the assets | no — its own ledger | not applicable |
| **On-chain dark pool** — Renegade (Arbitrum, Base) | **the relayer**, in plaintext ✓ | relayer + MPC matching | yes ("atomic settlement") | not stated |
| **Encrypted compute** — Arcium (Solana) | no single node; all but one must collude | a permissioned MPC cluster (Mainnet Alpha) | not stated | not stated |
| **US equity dark pool (ATS)** | **the public tape, within 10 seconds of execution** ✓ — size and price; the venue's name is published weeks later | the operator / broker | not on chain | not applicable |
| **Confide** | **the two parties only** — every other reader sees a public balance of 0 | **nobody** | **yes — one transaction, two signatures** | **kept**: an unapproved account is refused by Token-2022 |

**What Confide does NOT hide, said next to the table, never after it.** The accounts, the mints, and
the fact that a transaction happened are public. A US dark pool is the mirror image: the size is on
the tape and the counterparties are not. So the claim is **"the amount stays private"**, never "more
private than traditional markets".

**What this table does not say.** That the others are wrong. Each is built for something else —
continuous matching, custody, general private computation. No live product doing confidential,
issuer-gated delivery-versus-payment for tokenized stocks on Solana was found; that is the result
of a search, not proof of absence, and is to be said as "we did not find one" if at all.

## Sources

**Solana DEX.** Backed, 2025-06-30: *"Raydium is the liquidity hub for tokenized equities on
Solana"*; available *"on Kamino… through Kamino Swap"*; Jupiter integrated.
https://backed.fi/news-updates/xstocks-are-going-live-tokenized-stocks-for-the-defi-era — that these
swaps are public follows from how a Solana token swap works; no source says it in one sentence.

**Centralized exchange.** Same Backed page: Kraken *"listing xStocks on its Spot platform on day
one"*; Bybit in the xStocks Alliance. Custody and an internal ledger are what a centralized exchange
is, not separately sourced. OTC block desks *for xStocks specifically*: UNVERIFIED.

**Renegade.** Site: *"an on-chain dark pool"*, *"Live today on Arbitrum and Base"*, *"Trade any
ERC-20"* — https://renegade.fi/ . ✓ README: *"Each relayer maintains some set of plaintext orders
known only to the relayer."* — https://github.com/renegade-fi/renegade . Help center (search snippet;
the page did not fetch): wallets connect to a relayer *"which can view their orders and balances in
plaintext"*. Atomic settlement: zkSecurity audit, https://reports.zksecurity.xyz/reports/renegade-atomic-settlement

**Arcium.** Mainnet Alpha, 2026-02-04: independent node operators in a *"permissioned configuration"*
— https://arcium.substack.com/p/arcium-mainnet-alpha-is-live . Docs: inputs *"hidden from any single
node"* — https://docs.arcium.com/ . Cerberus: secure while *"all but one of the n parties may be
corrupted"* — https://www.arcium.com/research/cerberus . A live Arcium dark pool for tokenized
stocks: not found.

**US ATS.** ✓ FINRA Rule 6380A: reported *"as soon as practicable but no later than 10 seconds after
execution"* — https://www.finra.org/rules-guidance/rulebooks/finra-rules/6380a . Tape reports go *"to a
TRF for public dissemination"* — https://www.finra.org/filing-reporting/market-transparency-reporting/trade-reporting-faq .
ATS volume by venue: published after *"two weeks for Tier 1 NMS stocks to four weeks for OTC
equities"* — https://www.finra.org/rules-guidance/notices/19-22

**Not in the table, and why.** Penumbra — Penumbra Labs *"is winding down operations"*
(https://penumbralabs.xyz/), its own chain. Railgun — a shielded pool on Ethereum, BSC, Polygon and
Arbitrum (https://docs.railgun.org/wiki); swap visibility through external venues UNVERIFIED.
Elusiv — rebranded to Arcium (https://x.com/elusivprivacy/status/1787962124800569603). Light
Protocol — acquired by Helius to build a privacy layer not yet shipped
(https://www.helius.dev/blog/light-protocol-acquisition). GoDark — secondary sources only.

**Confide's own row** is evidence in this repository: `docs/cwf-2026/CLAIMS.md` D1, D3, D5, D7, P1;
the passing run in `docs/cwf-2026/REVIEW-RUNS.md`.
