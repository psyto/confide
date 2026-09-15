# Strategy request — what to do with 27 days

You reviewed this repository's documents on 2026-09-15 and found, among other things, that the
seizure demo claimed a proven collateral floor and a market price and had neither. That is fixed:
section 4 of `docs/SEIZURE.md` now states which two of the three predicate terms are taken on trust,
and every surface repeats it. Read the repo as it stands, not as you last saw it.

**I do not want validation of a plan. I want the plan.** Tell me what to spend 27 days on, and be
willing to say that the obvious answer is wrong.

## Where things stand

- **Crypto World's Fair closes 2026-10-12 23:59 PT.** 27 days.
- **Judged on seven criteria**, four of them non-engineering: founder + market fit, insight,
  product + execution, **potential market size, founder communication, viability, traction**. The
  legal rules add a second list: functionality, potential impact, novelty, UX, open-source,
  business plan.
- **Only in-window work is judged.** The boundary is the tag `cwf-2026-baseline`;
  `git log cwf-2026-baseline..HEAD` is everything that counts, and it is currently ~50 commits,
  mostly the seizure mechanism and a documentation-integrity pass.
- **A one-minute check-in video is due weekly** — 09-18, 09-25, 10-02, 10-09 — asking what changed,
  what was learned (a test, conversation, or decision), and what is next. Judges see the sequence.
- **Two submission videos at the end**: a 2–3 minute presentation and a demo under 3 minutes.
- **Traction is zero and the submission says so in those words.** No issuer approval, no pilot, no
  customer interview, no design partner, no user outside this repository.

## The thing I am most unsure about

Four of seven criteria are non-engineering and the project is strong on mechanism and empty on
market evidence. A sister project of mine was withdrawn from this same hackathon because three
independent readings said the same thing: the mechanism was strong and "who pays for this, and why
now" was thin, which loses in a short judging pass.

So: **is more engineering the wrong move entirely?** If the honest answer is that 27 days of code
cannot fix a traction score and the time should go somewhere else, say so and say where.

## What I want from you

1. **A ranked list of what to do, with what each is worth against which criterion.** Not a wish
   list — a plan for 27 days and one person, with the weekly check-in cadence as a constraint that
   rewards visible weekly progress.
2. **What to refuse.** Name the tempting work that would not move the verdict. Be specific about
   things already half-built here.
3. **The non-engineering moves.** If traction is the gap, what is actually achievable in 27 days by
   one person with no company, no budget and no network in this market? Concrete asks, concrete
   artifacts. If the honest answer is "nearly nothing, so optimise the other six criteria", say it.
4. **The strongest technical move, if there is one.** `docs/SEIZURE.md` lists what is not built:
   the floor is recorded rather than verified on chain, the price is one oracle's assertion, there
   is no partial seizure, no repayment path, and none of it is on mainnet. Which of those, if any,
   changes how a judge reads the project rather than how an engineer does?
5. **The risk of building the wrong thing.** What would make this project look worse in four weeks
   than it looks today?

Rank by what changes a verdict. Do not summarise the project back to me. Do not praise.
