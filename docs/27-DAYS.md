# 27 days — the plan, and the bet inside it

Written 2026-09-16, with 27 days to Crypto World's Fair. Three strategy reviews sit in
[`reviews/`](reviews/): a conservative one, an aggressive one, and the stress test that broke both.
This is what survived them.

## The bet

Confide is strong where it is judged last and weak where it is judged first. Insight, product and
execution are genuinely good; **potential market size, viability and traction are the four-sevenths
of the score that get read before any of it**, and traction is zero.

Twenty-seven days of more mechanism does not move that. So the bet is:

> **Make one named risk owner able to say, in writing, "if this establishes X, we would take that
> collateral at N% LLTV up to a cap of C."**

Not a partnership. Not a public endorsement — a risk owner underwrites a specific market and a
public statement is governance liability, which is why asking for one prices at 85–95% against.
A written conditional decision with a number in it is achievable, and it is the first evidence this
project has ever had that someone with capital would act.

## The constraint that shapes everything

**The buyer must understand the benefit in their own units, and must be able to try it without
calling their engineers.** Anything that fails either test is not the artifact, however correct it
is.

- **Their units, not ours.** Not "privacy" or "selective disclosure". *LLTV, cap, bad debt,
  utilization, supplier APR.* Disclosure uncertainty already costs them something; it shows up as a
  haircut. The claim is not that Confide is clever — it is that **the haircut has a cause, and the
  cause is removable**.
- **Tryable in one command.** A curator runs one thing and gets the packet for a named asset, filled
  in from live chain data. No contract to deploy, no integration, no permission. A decision aid they
  can run in five minutes, not a product they have to adopt.

## The other constraint: this is additive

Stocklana judging runs to 2026-10-02 and its submission links this repository. Commits reach those
judges without a re-paste — which cuts both ways. **Nothing already claimed gets rewritten to make
room for the new direction.** The finding, the embargo, the seizure, the evidence list: all stay,
all stay true.

One thing changes and it changes as a recorded reversal, the way every reversal here is handled:
the submission says **"the issuer is the customer, not the obstacle."** Testing that view is what
this month is for, and the current reading is that an issuer whose business is issuing and selling
is a **gate on eligibility, not a buyer**. That is a change of view with a date on it, not a silent
edit, and it is the substance of one of the weekly check-ins.

## The buyer

Not "a lending protocol". A **vault curator or market creator with capital to allocate** — on
Morpho, markets are permissionless but the decision that matters is whether anyone supplies. Oracle
and LLTV are immutable per market and bad debt lands on lenders, which is exactly why the decision
is careful and exactly why a number from one of them means something.

Ranked by how directly the pain is already a number they track:

| | who | the number it already shows up in |
|---|---|---|
| 1 | vault curator / lender risk owner | bad debt, cap, LLTV, utilization, supplier APR |
| 2 | market maker | inventory VaR, hedge cost, spread, capital tied up |
| 3 | fund administrator | NAV exceptions, reconciliation breaks, reporting turnaround |

## What gets built

**1. The collateral admission packet** — for one named token and one named market, answering what a
risk owner must answer anyway:

- every authority on the token: pause, blacklist, seize, upgrade, mint/burn, and who holds each
- reserve evidence: source, signer, freshness, coverage, what is independently verifiable
- the oracle path, its fallback, and its staleness and deviation rules
- the liquidation path, including what happens when a liquidator is not eligible to hold the asset
- a proposed LLTV, cap and liquidation incentive, **each with the loss assumption behind it**
- cost to integrate: contracts touched, audit surface, operations runbook, owner-hours
- what Confide changes, expressed as a change in those parameters

**2. The registry, as a decision surface rather than an activation queue.** Per asset, per protocol:
`usable / conditional / blocked / unknown`, with provenance and expiry on every fact, and the
missing condition stated as its economic consequence — *"no issuer-attested redemption feed →
proposed cap $0"*, never *"the issuer has not signed"*. Facts, issuer assertions, third-party
attestations and our own inference kept visibly apart.

**3. One command that produces both**, run against live chain data by someone who has never seen
this repository.

## Twenty-seven days

| | date | beat |
|---|---|---|
| **Week 1** | → 09-22 | Packet schema frozen against one named asset and one named market. The registry reads live authority and reserve facts. **Check-in 1 (09-18): the decision to stop expanding mechanism, and why the issuer is a gate rather than a buyer.** |
| **Week 2** | → 09-29 | The one command works end to end for a stranger. First approaches go out — a 20-minute ask with the packet attached, not a pitch. **Check-in 2 (09-25): the packet, and the first thing an outside reader got wrong about it.** |
| **Week 3** | → 10-06 | Replies worked into the packet; whatever a risk owner said is unanswerable gets answered or recorded as unanswerable. **Check-in 3 (10-02): what the conversations killed.** |
| **Week 4** | → 10-12 | Submission videos, evidence frozen, links and disclosures checked. **Check-in 4 (10-09): the conditional decision if it exists, and plainly its absence if it does not.** |

**Point of no return: 09-29.** After the packet is out with a named asset and named market, the
framing is public and reverting to "a disclosure primitive looking for a home" costs more than
continuing.

## Refused

Named so the temptation is on the record rather than in the head:

- **On-chain verification of `q_min`** — repairs an engineering boundary already disclosed honestly;
  establishes no demand.
- **A price feed**, unless a specific risk owner names the feed and the acceptance condition. A
  generic oracle makes the demo look financial and proves no underwriting policy.
- **Partial seizure, repayment, interest, liquidation engines** — a more elaborate prototype, not a
  more credible business. Repayment re-enters only if a conversation asks for it.
- **Mainnet deployment** — custody, security and legal exposure with no user and no approval, and
  actively bad if it is used to imply production readiness.
- **A wrapper token** — it can make a lender's policy programmable and it cannot make issuer
  reserve, redemption or legal-status facts true. A separate product, too large for this window.
- **More documentation-integrity work** beyond final claim checks, and any polishing of test counts
  or terminal panes before the buyer evidence exists.

## What this leaves if nobody answers

Stated now, while it is still a forecast rather than an excuse. If no risk owner replies by 10-12:

- a reusable collateral-admission packet, and a registry saying where live assets are usable,
  conditionally usable, or not underwritable at all, with provenance on every fact
- a documented map of exactly which issuer-controlled facts cap collateral capacity, and at what
- everything that already runs, untouched

That is a due-diligence asset and a research result. **It is not traction, and it will not be
described as traction.** The wager is that one number from one risk owner is worth more than
twenty-seven more days of mechanism, and the wager can be lost.
