# The pitch video — ≤2 minutes, the founder on camera

**The form, read 2026-10-02:** *"Separate from the demo video — introduce yourselves, tell us what
you're building, and tell us why you're the people to build it. Nothing fancy required. We're
interested in how you think and communicate. YouTube, Loom, or Vimeo. Up to 2 minutes."* **Public.**

**This one is the founder's, start to finish.** The camera, the voice, and three facts nobody else
can supply are marked `[FOUNDER: …]`. Nothing here invents a background:
[`../docs/cwf-2026/FOUNDER-MARKET-FIT.md`](../docs/cwf-2026/FOUNDER-MARKET-FIT.md) says what not to
claim, and it applies here first.

**The full comparison lives here.** The demo form asks for *"the live product, not a slide deck"*, so
the demo carries only a short sourced card inside the product's PUBLIC LEDGER panel. The pitch
is where *"how you think"* is asked for, and the one idea worth getting across is a single question
asked of every way to trade size: **who reads the amount?** Each answer is sourced in
[`../docs/cwf-2026/COMPARABLES.md`](../docs/cwf-2026/COMPARABLES.md).

**Held well under two minutes.** The table below predicts at 137 words a minute; a speaker on camera,
pausing to think, runs slower, and check-in 2 already came out four per cent long. The founder's
three lines will add words. **Time a read-through before recording**; if it runs over 1:50, cut scene
4's second sentence first.

<!-- pace.py owns the table below. Do not hand-edit it: `python3 video/pace.py --write`. -->

| | scene | seconds (+ silence) | words | pace | what it shows |
|---|---|---|---|---|---|
| 1 | who | 9 | 19 | 136 | the founder, on camera |
| 2 | who reads the amount | 25 | 56 | 138 | the founder; optionally the five-row comparison from COMPARABLES.md as a still behind or beside them |
| 3 | what Confide is | 26 | 59 | 139 | the founder; optionally two seconds of the demo's PUBLIC LEDGER panel |
| 4 | what is true today | 22 | 48 | 135 | the founder |
| 5 | why me | 17 | 38 | 139 | the founder |
| | | **99 s** | **220** | | |

## The script

### 1 — who

> I'm [FOUNDER: name], building Confide alone, from Japan. [FOUNDER: one sentence — what you did
> before, true and checkable.]

*Shows:* the founder, on camera.

### 2 — who reads the amount

> When a fund trades a large block of a tokenized stock, someone reads the size. On a DEX, everyone
> does. On an exchange, the exchange does, and it holds the asset. In a dark pool, the operator
> does. Even a US dark-pool trade in a listed stock is generally reported, size and price, within
> ten seconds.

*Shows:* the founder; optionally the five-row comparison from COMPARABLES.md as a still behind or
beside them.

### 3 — what Confide is

> Confide is the privacy layer for issuer-approved tokenized stocks on Solana. The issuer approves
> each account before it can hold privately. Two approved holders agree a price, each checks what it
> will receive before signing, and stock and stablecoin settle in one transaction. Everyone else
> sees that a trade happened; on mints with no auditor key, not how much.

*Shows:* the founder; optionally two seconds of the demo's PUBLIC LEDGER panel.

### 4 — what is true today

> Every mint in three issuers' tokenized-stock catalogues already has this switched on. Across the
> six mints I counted, no account has been approved to use it. Confide runs end to end on devnet, in one command,
> re-checked from the chain. No issuer uses it yet; traction is zero.

*Shows:* the founder.

### 5 — why me

> I build by measuring what is actually deployed, and I write down when I was wrong, including about
> who the customer is. [FOUNDER: one sentence — why this problem, for you.] Next is one conversation
> with an issuer.

*Shows:* the founder.

## Every claim, and where it stands

| line | evidence |
|---|---|
| DEX / exchange / dark pool / ten seconds | [`COMPARABLES.md`](../docs/cwf-2026/COMPARABLES.md) — FINRA Rule 6380A, *"no later than 10 seconds after execution"*, for reportable off-exchange trades in NMS stocks while the reporting facility is open; hence "generally" |
| the issuer approves exactly which accounts | [`CLAIMS.md`](../docs/cwf-2026/CLAIMS.md) M3, D1–D3 |
| each checks before signing; one transaction | CLAIMS L1, D5, D7 |
| a trade happened; with no auditor key, not how much | CLAIMS P1, P2 — accounts and the fact of the trade are public; a mint-wide auditor key, where set, reads transfer amounts |
| every mint in three catalogues has it on | CLAIMS M1 — a catalogue, not a census of the chain |
| six mints counted, none approved | CLAIMS M4 |
| end to end, one command, re-checked | [`REVIEW-RUNS.md`](../docs/cwf-2026/REVIEW-RUNS.md) |
| wrong about the customer | FOUNDER-MARKET-FIT §2 — the dated reversal |
| traction is zero | CLAIMS A1 |
