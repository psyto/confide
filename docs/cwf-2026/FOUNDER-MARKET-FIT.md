# Founder + market fit — the honest version

Listed **first** of the seven web criteria ([`CRITERIA.md`](CRITERIA.md)) and absent from every
other surface in this repository until 2026-09-19.

Two observations from the founder, 2026-09-19, are the whole of the raw material:

> **Tokenized equity has only just started, and everything around it is immature.**
>
> **The issuer itself gains little from changing the current arrangement.**

Everything below is built from those two and from what is already in the repository. **Nothing here
claims market proximity that does not exist**, because the first reader who checks would find it,
and because the second observation is itself a correction the founder made in public — inventing a
background would throw away the only thing that makes the correction worth anything.

## What not to claim

- **No prior career in RWA, lending, custody or brokerage.** Do not imply one. The submission does
  not need it to be true; it needs whatever is true to be checkable.
- **No relationship with Backed, Backpack, Kamino, or any curator.** Nobody here has been contacted,
  by decision (2026-09-18) and not by omission.
- **No users.** Traction is zero and is reported as zero.

## What is actually true, and is unusual

### 1. The insight is structural, and it is the kind a newcomer can have

Both observations are about **a market too young to have built its own plumbing yet**, and they fit
together into one claim:

> The disclosure primitive tokenized equity will need is missing, and **the party best placed to add
> it has no reason to.** An issuer whose revenue is issuing and selling gains nothing from a
> disclosure model; it is a cost and a liability to them. So the gap does not close by waiting.

This is not a claim that requires having worked in the industry. It requires reading what is on
chain, and it is **falsifiable, which is why it is worth stating**: if an issuer shipped a
disclosure model tomorrow, the claim would be dead. Instead, every mint says the opposite —
**1,992 tokenized-equity mints with confidential transfers switched on and the auditor slot empty,
from three issuers with nothing to do with each other** (`./scripts/slot-scan.sh`, mainnet). One
issuer leaving it empty is a story about that issuer. Two, independently, is the market.

### 2. The founder changed their mind about the customer, in public, with a date on it

The Stocklana submission — **already filed, still judged until 2026-10-02, and linked from this
repository** — says *"the issuer is the customer, not the obstacle."*

The current reading is the opposite: **the issuer is a gate on eligibility, not a buyer.** That
reversal was recorded on 2026-09-16 as a dated change of view rather than edited away, and the
evidence that drove it is not an argument but someone else's source code —
Kamino refuses a deposit from an account holding value confidentially, on **the depositor's own
account** (`constraints.rs:187`, `:194`, `:201`, `:131`; `lending_checks.rs:186`, `:188`, verified
against the pinned commit). Collateral that cannot enter cannot be borrowed against or liquidated.

So the buyer moved from the issuer to the lender side, because the chain said so.

**This is the substance of the founder + market fit answer.** Not "I know this market" but: *this
market is young enough that the useful move is to test beliefs against it quickly and say so when
one breaks.* The repository is a record of that happening — the reversal above, the retired bet
(2026-09-16), the retired outreach plan (2026-09-18), a claimed check that was not in the code and
was corrected the day it was found (2026-09-16), and a defect in the published video's own frame
found and fixed by looking at it (2026-09-18).

### 3. The thing built is the thing the observation implies

If the primitive is missing and the issuer will not add it, then what is worth building is the part
that does not need the issuer's permission to be true:

- **the compatibility verdict**, reproducible from someone else's pinned source
- **the capacity computation** — $22.0m deposited and $83.0m of borrowing already authorised across
  Kamino's tokenized-equity reserves, **$0 of it reachable while a position stays confidential** —
  computed from Kamino's own caps, LTVs and prices, with nobody's agreement required
- **the mechanism that removes one of the blocking conditions**, running end to end on devnet
- and **the three that are still missing, named** — re-proving the floor, the liquidation hand-off,
  and the issuer approving each escrow, *which is the one thing the observation says will not come*

## The four questions, answered

Phrased for the form. Each is checkable against the repository.

**What firsthand observation led to this problem?**
That tokenized equity is new enough that the layer around it has not been built, and that the gap is
visible on chain: 1,992 mints ship a privacy feature with its only key left empty, because the one
disclosure model on offer — a global key reading everyone's everything, forever — is one no holder
should accept and no issuer should hold.

**What makes this founder credible in this market?**
Not prior access to it. What can be shown is the work: an argument whose every number is recomputable
from live chain data by a stranger, a mechanism running end to end, and a documented habit of
retiring beliefs that failed — including the one about who the customer is, which was reversed
mid-contest with the evidence attached.

**Why is the wedge risk admission rather than privacy?**
Because "privacy" is not a number anyone underwrites. A lender's units are LLTV, cap, bad debt and
utilisation, and disclosure uncertainty already shows up there as a haircut. The claim is not that
Confide is clever — it is that **the haircut has a cause, the cause is a specific refusal in a
specific program, and it is removable.**

**What did the issuer-to-lender reversal teach?**
That the party who *can* fix something and the party who *wants it fixed* are often not the same,
and that asking which is which is cheaper than building for the wrong one. It also set the order of
operations: the packet's first ask was never going to be a price, because a risk owner asked to
price an asset whose custody and liquidation path is unproven is right to refuse.

## Still founder-only

Team location, teammates and their backgrounds, and the product logo. None can be drafted here.
