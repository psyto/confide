# 27 days — the plan, and the bet inside it

Written 2026-09-16, with 27 days to Crypto World's Fair. Three strategy reviews sit in
[`reviews/`](reviews/): a conservative one, an aggressive one, and the stress test that broke both.
This is what survived them.

## The bet

Confide is strong where it is judged last and weak where it is judged first. Insight, product and
execution are genuinely good; **potential market size, viability and traction are the four-sevenths
of the score that get read before any of it**, and traction is zero.

Twenty-seven days of more mechanism does not move that.

> **Corrected 2026-09-19. The paragraph above is wrong and it is left standing because the whole
> plan below was built on it.** Both criteria lists were finally read —
> [`cwf-2026/CRITERIA.md`](cwf-2026/CRITERIA.md), with sources. **Traction is listed last of the
> seven and does not appear in the Official Rules at all.** Of the four, only Founder + Market Fit
> is listed above the engineering criteria; market size is fourth and viability sixth. Insight is
> second, Product + Execution third, and §8 opens on functionality and code quality.
>
> Neither list carries weights or a stated reading order, so *"read first"* was never a fact in
> either direction. What the page does say is that **the two-to-three-minute presentation video is
> one of the first resources judges review.**
>
> **What survives:** traction is zero and will be reported as zero, and Founder + Market Fit is
> listed first and is absent from every surface here. **What does not:** the premise that more
> engineering cannot move the score. §8(d) asks about UX for downstream users and §8(e) about how
> well the work composes with other primitives, and nothing here was built for either.

The first version of this plan bet on a reply: get one named risk owner to write down "if this
establishes X we would take that collateral at N% LLTV up to a cap of C." **That bet was retired on
2026-09-16, by the founder, for the right reason** — a reply inside a fixed window cannot be
planned. It depends on a stranger's calendar, and no amount of work on this side makes it
arrive. Four of the seven criteria were hostage to it, and they are the four read first.

So the bet is the one thing that is entirely within reach:

> **Make the number computable by anyone, from live chain data, without asking anyone's
> permission.** For a named mint and a named market: the collateral capacity that exists today and
> why it is what it is, the specific condition that caps it, and what removing it is worth — every
> input traceable, and the removal itself running.
>
> **A page, not a command.** A command is tryable by a developer. The constraint says *without
> calling their engineers*, and a risk owner is not going to clone a repository. The CLI stays,
> because it is what makes the page checkable; the artifact is the URL.

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

> **Reversed 2026-09-19, and this section is left standing because the month was built on it.**
> The buyer below is a vault curator, and reaching one needs a venue-side integration that the
> [pincer](cwf-2026/THE-PINCER.md) says nobody can do without the issuer. **But the issuer gate is
> per account, not per loan** — `SetAuthority` moves an already-approved confidential account to a
> loan PDA and leaves the approval in place, verified on devnet.
>
> So **a holder who already holds a position confidentially can pledge it today, bilaterally, with
> nobody's permission.** That is one borrower and one lender, which is what
> `./scripts/seizure-e2e.sh` has demonstrated since it was written and what nobody read it as. The
> first customer is a counterparty, not a protocol; the curator is the second.
>
> The capacity number keeps its job and loses a different one: **$23.2 m deposited and $84.0 m
> authorised is the size of the problem, not a pipeline.** See [`cwf-2026/GTM.md`](cwf-2026/GTM.md).

Not "a lending protocol". A **vault curator or market creator with capital to allocate** —
markets may be permissionless, but the decision that matters is whether anyone supplies. Oracle and
LLTV are fixed per market and bad debt lands on lenders, which is exactly why the decision is
careful and exactly why a number from one of them means something.

**The named case is SpaceX exposure on Kamino** (decided 2026-09-16). The hope was that Confide
could create a reason to do this on Kamino *rather than* Morpho. **Checked on 2026-09-16, and in
its strong form that reason is false:** "we require a disclosure fact before we admit or allocate"
is expressible on both — Kamino through a reserve whose risk parameters its market owner can
change, Morpho through a curator deciding whether to supply a permissionlessly created market whose
own parameters are immutable. Kamino's real advantages are native Solana settlement, operational
risk parameters that can move after admission, and a risk-governance surface with a name on it.
Those are good reasons. **Logical exclusivity is not one, and claiming it would not have survived
the first person who knows both systems.**

What is genuinely open, and is the week-1 gate:

> **Can a Kamino reserve take confidential Token-2022 collateral at all, without a Kamino-side
> integration — and can its existing liquidation path recover it?**

Generic Token-2022 support is not confidential-transfer support. Confide's own demo shows a
confidential account whose *public* balance is zero while it holds value, and an ordinary reserve
that reads the public balance sees nothing. So the honest outputs are `PASS`, `BLOCKED`, or
`REQUIRES INTEGRATION`, and `BLOCKED: requires a Kamino-native confidential reserve` is a real
research result rather than a failure. **What it is not is an admission product, and the plan says
which one it has.**

Ranked by how directly the pain is already a number they track:

| | who | the number it already shows up in |
|---|---|---|
| 1 | vault curator / lender risk owner | bad debt, cap, LLTV, utilization, supplier APR |
| 2 | market maker | inventory VaR, hedge cost, spread, capital tied up |
| 3 | fund administrator | NAV exceptions, reconciliation breaks, reporting turnaround |

## What gets built

**0. The compatibility verdict** — **done, 2026-09-16: [`REQUIRES INTEGRATION`](KAMINO.md)**,
reproducible with `./scripts/kamino-verdict.sh`. Kamino names the confidential-transfer extensions
on its allow-lists and requires them to be inert, on the *user's* account as well as its own vault,
on deposit, borrow and both sides of liquidation. Both SpaceX mints clear every other condition, so
the gap is confidentiality. **That is the gate the packet had to pass before proposing an LLTV for
anything**, and it is now a citation rather than an argument.

**Corrected the same day, after review:** the first version of this said the four lines gate
deposit, borrowing and both sides of liquidation. They gate **the deposit path**, on the
depositor's own account, and the rest follows from collateral being unable to enter. *"Only four
lines stop a confidential position"* also died: closing it needs a floor that is re-proved, a
liquidation hand-off, **and the issuer approving each escrow** — which is not Kamino's decision.

**1. The collateral admission packet** — **first version generated, 2026-09-16**:
[`packets/`](packets/) — **all fourteen mints that have a Kamino reserve**, not one.
`./scripts/packet.sh --all`, which also writes the index, because generating them one at a time is
how a directory acquires a stale document nobody notices.

**Generated rather than authored**, which is the part that matters: the day it disagrees with the
chain is the day someone changed something, not the day the document went stale. It answers what is
on-chain — every authority and who holds it, the oracle path with its staleness and its price band,
the parameters already chosen — and **marks what is not as unknown, where an unknown produces a cap
of `$0` on its own line** instead of an invented number.

It also surfaces things nobody wrote down. Backpack concentrates five powers in one key — freeze,
permanent delegate, pause, transfer hook, confidential-transfer authority — where Backed splits the
same powers across four. **A permanent delegate can move collateral a lender cannot see**, and the
packet says so in the section about why this should be refused rather than in a footnote.

**2. The registry, as a decision surface rather than an activation queue.** Per asset, per protocol:
`usable / conditional / blocked / unknown`, with provenance and expiry on every fact, and the
missing condition stated as its economic consequence — *"no issuer-attested redemption feed →
proposed cap $0"*, never *"the issuer has not signed"*. Facts, issuer assertions, third-party
attestations and our own inference kept visibly apart.

**3. The decision page** — **first version live, 2026-09-16**:
[`web/kamino.html`](../web/kamino.html). Pick any of the 1,992 mints, and the browser reads it from
mainnet and applies Kamino's rules: the facts with their provenance and their expiry, the verdict,
and the missing condition **stated as its economic consequence** — *proposed cap $0, at any LLTV,
not because the asset is risky but because the position cannot enter*. Facts, Kamino's rules and
Confide's inference are three visually separate lanes. The commands stay underneath, because they
are what make the page checkable rather than a claim about live data.

**4. The market evidence map** — **done, 2026-09-16**. The bet said *make the number computable by
anyone, from live chain data, without asking anyone's permission.* `./scripts/capacity.sh`:

> **$23.2 m** of tokenized stock deposited across Kamino's reserves, and **$84.0 m** of borrowing
> their caps and LTVs already authorise. **$0 of it reachable while a position stays confidential.**

Computed from Kamino's own caps, LTVs and prices. Nobody had to agree to anything. And sharper than
expected in both directions:

> **1,992 of 1,992** tokenized-equity mints could be held by a Kamino reserve today.
> **0** of them can be held while the position is confidential.
>
> And the admission question is not hypothetical: **19 tokenized-equity reserves are live on
> Kamino**, thirteen holding more than a seed — ≈89,192 tokens available, ≈230 borrowed — at LTVs
> from 30 % to 73 %. **SpaceX has one already** — `SPCX.US`, Active, 40 % LTV, 15,000 cap. Every one of those
> deposited positions is public.

The first number is admissibility, the second is usability, and until now this repository had one
number doing both jobs. `./scripts/kamino-admissible.sh` produces them; `web/kamino.json` carries
the per-mint result.

## Twenty-seven days

| | date | beat |
|---|---|---|
| **Week 1** | → 09-22 | ✅ The Kamino gate answered, reproducibly. ✅ The packet generated against `SPCX.US` and its live reserve. ✅ The registry reads live authority and reserve facts. ✅ The presentation's structure and script written — [`video/CWF-PRESENTATION.md`](../video/CWF-PRESENTATION.md), market before mechanism; its length is in its own table, which `pace.py` derives, and is not restated here. ✅ Cut it — [`video/presentation.mp4`](../video/presentation.mp4), eight scenes, silent, rendered from the published cut's own page rather than a second copy of it. ✅ **Check-in 1 scripted and recorded** — [`video/CHECKIN-1.md`](../video/CHECKIN-1.md), written after the work rather than before it. ✅ **Check-in 1 submitted** — https://youtu.be/mbE8HMwG0S4, receipt 2026-09-20 19:17 PDT, 12 h 43 m before the 09-21 08:00 PDT deadline. The cut that went out is not the one scripted on 09-16: that one reported a week the pivot had already superseded, with four stale figures. Rewritten and re-rendered on 09-21. |
| **Week 2** | → 09-29 | The one command works end to end for a stranger, and **prints the number**. The three-minute narrative is drafted and tested against the artifact now, not in week 4. First approaches go out with the packet attached — upside, off the critical path. **Check-in 2 (09-25): the number the command prints, and the first thing an outside reader got wrong about it.** |
| **Week 3** | → 10-06 | Coverage: the command runs over **every** live tokenized-equity mint, not one, so any row is checkable by a stranger. Any reply that did arrive is worked in; anything a reader called unanswerable is answered or recorded as unanswerable. **Check-in 3 (10-02): what the coverage run found that the single case hid.** |
| **Week 4** | → 10-12 | Submission videos cut against the week-2 narrative, evidence frozen, links and disclosures checked. **Check-in 4 (10-09): the finished artifact, and traction stated as zero if it is zero.** |

### Two videos, not one

They get confused because both are short and both are due soon, so they are separated here.

| | the weekly check-in | the submission presentation |
|---|---|---|
| length | **1 minute** | 2–3 minutes (plus a ≤3 minute demo) |
| who asks for it | **Colosseum**, weekly — the first opens 09-18 | the submission form, 10-12 |
| content | 01 what changed · 02 what you learned, *one* test, conversation or decision · 03 what is next | the whole argument |
| this month | four of them: 09-18, 09-25, 10-02, 10-09 | one rough cut early, the real one in week 4 |

**The rough cut is nobody's requirement.** It exists because the first artifact a judge sees is the
presentation, and discovering in week 4 that the story does not hold leaves no time to change what
was built. It is a throwaway whose only job is to test the structure.

**Each check-in is written after the week's work, not before it** — it reports what happened, and a
check-in drafted first becomes a plan the week then has to live up to.

**Point of no return: 09-29.** After the packet is out with a named asset and named market, the
framing is public and reverting to "a disclosure primitive looking for a home" costs more than
continuing. It is a framing commitment, not a bet on anyone else's behaviour.

### "SPCX" is not a decision object

There are **two** SpaceX mints in `web/mints.json` and they are different legal and risk assets:

| | issuer | mint | what the holder has |
|---|---|---|---|
| `SPCXx` | Backed | `Xs3oZwbHvqis4NYcf4YKWmEia2eC84wSiVrcYcTqpH8` | a tracker certificate — **not** ownership of the underlying share |
| `SPCX.US` | Backpack | `SPCXxcqXj6e5dJDVNovHN8744zkbhM2bYudU45BimGb` | convertible through Backpack Securities to a securities entitlement |

Plus two leveraged SPCX ETFs that are neither. **Every sentence names the issuer and the mint**, or
it is not saying anything a risk owner can act on.

And SpaceX exposure is the *hardest* first asset, not the most compelling one: pre-IPO, no
continuous price, a redemption path that runs through a broker, eligibility restrictions on who may
hold it. That makes it an excellent demonstration of why *price × LTV* is not an admission
decision. It makes it a bad thing to promise an LLTV for. **So it is the flagship blocked case, and
a continuously priced listed equity is the control case that shows what a passing one looks like.**

> **That rule was written on 09-16 and then not followed** — SpaceX became the named case
> everywhere and no control was designated, which the founder caught the same day. SpaceX's reserve
> holds 0.1 tokens and carries no price, so leading with it alone trades the strongest evidence for
> the strongest motive.
>
> **The control is `NVDAx`**: a live price, $2.37 m deposited, borrowing happening now, and the
> issuer's authorities split across four keys rather than concentrated in one. It is also the mint
> the devnet mechanism already mirrors, **so the proof and the market point at the same asset** —
> which is why reconfiguring that mirror to SpaceX, briefly considered, would have been backwards.
>
> Both roles are stated in [`packets/README.md`](packets/) rather than left for a reader to infer.

### Outreach — retired 2026-09-18 by the founder

The forecast that stood here — 30 personalised contacts by 09-18, two follow-ups each, 3–6 replies,
1–3 substantive conversations — **is withdrawn. There will be no individual outreach.** Recorded as a
dated reversal rather than deleted, because the plan was built on top of it and the next reader needs
to know it was a decision and not an oversight.

This is the second thing in this plan to be retired for the same underlying reason. The first bet
depended on a stranger replying; this one depended on a stranger being written to. Neither is work
that can be finished by doing more of it.

**What replaces it is one-way and public.** Written once, no addressee, no reply obligation, no
follow-up schedule: the artifact and what it computes, posted where the people who would care
already are. The founder posts; the agent drafts and contacts nobody, as before.

**What this costs, stated rather than absorbed.** The first ask was going to be twenty minutes to
falsify the compatibility verdict — a refusal with a reason is information, and silence is not. A
public post does not produce refusals with reasons. It produces silence or it produces people who
arrive on their own, and **the second is the only one that can ever become traction.**

So the denominator now matters more than it did. If a post goes out and the page is instrumented,
the honest sentence is *"one post, N people opened the decision page, M ran a verdict, here are the
dates"* — and that sentence belongs under demand validation, **never under traction**. Traction is
zero until somebody outside this repository uses this for something of their own.

## The one piece of unfinished mechanism

`deshield` is disabled and returns an error. Three of the four findings from the implementation
review are repaired (`334fe5b`); this is the fourth, and **it stays disabled this month.**

The reason is not time. A repaired generic de-shield does not establish anything this plan needs:
the repair has to transfer to a recorded destination, and connecting that destination to a Kamino
reserve, obligation and liquidation lifecycle is the actual integration — weeks and a counterparty,
not a one-day fix. Doing the day of work would produce a working instruction that no argument here
depends on.

What did need doing, and is done, is the **claim boundary**. Three places said or implied that
de-shielding runs and that the asset is freely movable afterwards: the README's script list, the
script's own header, and §4d of [`SEIZURE.md`](SEIZURE.md). It does not run, and a public balance in
a PDA-owned account is **not** movable by an ordinary transfer — that was the error in the original
design, not just in the prose. All three now say so. **That is not polish; a false claim next to the
seizure path is what makes a judge doubt the seizure path.**

## Refused

Named so the temptation is on the record rather than in the head:

- **On-chain verification of `q_min`** — repairs an engineering boundary already disclosed honestly;
  establishes no demand.
- **A price feed** — decided 2026-09-16 rather than deferred to a buyer who is not in the plan.
  It stays out: a generic oracle makes the demo look financial and proves no underwriting policy,
  and the packet's job is to state *which* feed a venue would need and what its staleness and
  deviation rules must be, which is the useful half and does not require wiring one.
- **Partial seizure, interest, liquidation engines** — a more elaborate prototype, not a more
  credible business.
- **Repayment** — same decision, same date, and this one is closer. It stays out because the
  argument is about admission, not about the loan lifecycle, and a release path that does not end
  at a real venue is the same shape of unfinished as `deshield`.
- **Finishing `deshield`** — a working instruction no argument here depends on. See above.
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
