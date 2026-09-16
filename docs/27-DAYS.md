# 27 days — the plan, and the bet inside it

Written 2026-09-16, with 27 days to Crypto World's Fair. Three strategy reviews sit in
[`reviews/`](reviews/): a conservative one, an aggressive one, and the stress test that broke both.
This is what survived them.

## The bet

Confide is strong where it is judged last and weak where it is judged first. Insight, product and
execution are genuinely good; **potential market size, viability and traction are the four-sevenths
of the score that get read before any of it**, and traction is zero.

Twenty-seven days of more mechanism does not move that.

The first version of this plan bet on a reply: get one named risk owner to write down "if this
establishes X we would take that collateral at N% LLTV up to a cap of C." **That bet was retired on
2026-09-16, by the founder, for the right reason** — a reply inside a fixed window cannot be
planned. It depends on a stranger's calendar, and no amount of work on this side makes it
arrive. Four of the seven criteria were hostage to it, and they are the four read first.

So the bet is the one thing that is entirely within reach:

> **Make the number computable by anyone, from live chain data, without asking anyone's
> permission.** One command, for a named asset and a named market, prints the collateral capacity
> that exists today and why it is what it is, the specific removable fact that caps it, and the
> capacity once that fact is removed — with every input traceable, and the removal itself running.

This answers *potential market size* with a computation instead of a claim, and *viability* with a
cost and a parameter that each carry the loss assumption behind them. **Neither answer needs a
counterparty.** A judge can run it. So can a curator, later, on their own schedule — which is the
better way to reach one anyway.

The loop closes on itself: the registry states a blocking condition in economic terms, and
**Confide is the removal of one of those conditions**, demonstrated end to end on devnet rather
than argued. That is what makes this Confide's packet and not a generic due-diligence tool.

**Outreach still happens, and it is upside, not the plan.** Approaches go out with the packet
attached because the packet is worth reading; whatever comes back is recorded exactly as received,
including refusals with their reasons — a reason is information about the market, silence is not.
**Traction stays zero unless someone external actually uses this, and it will be reported as zero.**

### What this costs

Two of the refusals below were written as *"not unless a specific risk owner names it"* — the price
feed, and repayment. **With no reply in the plan, nobody will name them.** So each is now our own
decision with the assumption written next to it, or it stays out. Deferring to a buyer who was
never going to answer is how a plan quietly does nothing.

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

Not "a lending protocol". A **vault curator or market creator with capital to allocate** —
markets may be permissionless, but the decision that matters is whether anyone supplies. Oracle and
LLTV are fixed per market and bad debt lands on lenders, which is exactly why the decision is
careful and exactly why a number from one of them means something.

**The named case is `SPCX` on Kamino** (decided 2026-09-16). Kamino rather than Morpho is a
deliberate choice, and the reason it is written here is that the aspiration is larger than venue
preference: **that Confide creates the reason to do this on Kamino specifically.** That reason is
not established yet. Either Kamino's market structure can express a collateral admission whose
condition is a disclosure fact — in which case it is the strongest thing in this plan and week 1
is where it gets written down — or it cannot, and then the venue is a preference and should be
called one. **Checking which is week-1 work, and the answer is allowed to be the unwelcome one.**

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
| **Week 1** | → 09-22 | Is the Kamino reason real — answered either way, in writing. Packet schema frozen against `SPCX` and one named Kamino market. The registry reads live authority and reserve facts. **The seizure repair closed out, capped at one day** (below). **Check-in 1 (09-18): the decision to stop expanding mechanism, and why the issuer is a gate rather than a buyer.** |
| **Week 2** | → 09-29 | The one command works end to end for a stranger, and **prints the number**. The three-minute narrative is drafted and tested against the artifact now, not in week 4. First approaches go out with the packet attached — upside, off the critical path. **Check-in 2 (09-25): the number the command prints, and the first thing an outside reader got wrong about it.** |
| **Week 3** | → 10-06 | Coverage: the command runs over **every** live tokenized-equity mint, not one, so any row is checkable by a stranger. Any reply that did arrive is worked in; anything a reader called unanswerable is answered or recorded as unanswerable. **Check-in 3 (10-02): what the coverage run found that the single case hid.** |
| **Week 4** | → 10-12 | Submission videos cut against the week-2 narrative, evidence frozen, links and disclosures checked. **Check-in 4 (10-09): the finished artifact, and traction stated as zero if it is zero.** |

**Point of no return: 09-29.** After the packet is out with a named asset and named market, the
framing is public and reverting to "a disclosure primitive looking for a home" costs more than
continuing. It is a framing commitment, not a bet on anyone else's behaviour.

## The one piece of unfinished mechanism

`deshield` is disabled and returns an error. Releasing seized collateral needs the withdraw proof
contexts and the amount in the loan record, and the record has no room for them; without that a
caller can de-shield one token, mark the loan settled and strand the rest. Three of the four
findings from the implementation review are repaired (`334fe5b`); this is the fourth.

It is **not** new mechanism — it is the repair of something already claimed, which is why it is
here at all and not on the refuse list. **One day, capped.** Resize the loan record, bind the
contexts, re-run the end-to-end script, redeploy, and correct the prose in
[`SEIZURE.md`](SEIZURE.md) that the repair banner currently flags. If it runs over, the honest end
state is a disabled instruction with the note that is already on it — that costs a line in the
video and nothing in the argument, and it is strictly better than a half-finished custody path.

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

Stated plainly, because after 2026-09-16 this is the **expected** case rather than the failure
case. If no risk owner replies by 10-12:

- one command a stranger can run that computes, from live chain data, what confidential tokenized
  equity can be borrowed against today, what caps it, and what removing the cap is worth
- a reusable collateral-admission packet for a named asset and a named market, and a registry
  saying where live assets are usable, conditionally usable, or not underwritable at all, with
  provenance and expiry on every fact
- a documented map of exactly which issuer-controlled facts cap collateral capacity, and at what
- the mechanism that removes one of those facts, running end to end
- everything that already runs, untouched

**That is not traction, and it will not be described as traction.** What changed on 09-16 is that
it is no longer being described as a consolation prize either. The wager is that a number anyone
can recompute beats a number someone agreed to say — and that wager is settled by work, not by a
stranger's calendar.
