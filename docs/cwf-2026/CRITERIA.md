# What this contest actually judges

Established 2026-09-18, because the plan had been arranged around a claim with no source under it.

**There are two lists and they are not the same list.** Both apply. Nothing here is a summary of a
summary: §8 was read out of [`../Crypto World's Fair Hackathon Rules.pdf`](../Crypto%20World's%20Fair%20Hackathon%20Rules.pdf)
directly. The web criteria came through a fetch of `colosseum.com/hackathon` and **should be
confirmed by a human opening that page** — a fetched summary is a derived artifact, and this
repository has been wrong before by trusting one.

## The seven on the web page, in the order the page lists them

| | criterion | the question it asks |
|---|---|---|
| 1 | **Founder + Market Fit** | does the team have the right skills and experience to succeed in this market |
| 2 | **Insight** | does the founding team have a unique insight from deep understanding |
| 3 | **Product + Execution** | how well does the product work, how does it compare to competition |
| 4 | **Potential Market Size** | how big is the total addressable market |
| 5 | **Founder Communication** | are the founders communicating the vision clearly |
| 6 | **Viability** | can this become a scalable, sustainable business |
| 7 | **Traction** | does the product already have demand or revenue |

**No weights. No stated reading order.** The page does not say judges read them top to bottom, and
this file does not claim it does.

## The six in Official Rules §8, read from the PDF

> Each Project Submission will be judged by Colosseum and a panel of judges determined by
> Administrator in accordance with the following criteria:

| | criterion | the question it asks |
|---|---|---|
| a | **Functionality** | how well does it work? what is the quality of the code? |
| b | **Potential Impact** | total addressable market, **and impact on the broader crypto ecosystem** |
| c | **Novelty** | how unique is the concept |
| d | **UX** | how well does it use blockchain to create great UX **for downstream users** |
| e | **Open-source** | is it open-source? **how well does it compose with other primitives** |
| f | **Business Plan** | is there a viable business? how adept is the team at executing the vision |

## What the repository had wrong

`STATUS.md` and `docs/27-DAYS.md` both said that **four non-engineering criteria — market size,
viability, traction, founder + market fit — are read before any of the engineering**, and the
27-day plan was built on it: *"Twenty-seven days of more mechanism does not move that."*

Against the two real lists:

- **Traction is listed last of the seven, and does not appear in §8 at all.** There is no traction
  criterion in the Official Rules. The thing the plan treated as the first thing a judge checks is
  the last thing on one list and absent from the other.
- Of the four, **only Founder + Market Fit is listed above the engineering criteria.** Market size
  is fourth, viability sixth.
- **Insight is second and Product + Execution is third** — and §8 opens on Functionality and code
  quality. Those are the strongest things here.
- **Two criteria nobody has been building for.** §8(d) asks about **UX for downstream users**, and
  §8(e) asks how well the work **composes with other primitives** — not merely whether it is
  open-source. Both are answerable.

**This does not make the gaps unimportant.** Founder + Market Fit is listed first and is absent from
every surface in this repository; traction is still zero and will still be reported as zero. What it
removes is the premise that engineering work cannot move the score, which is a different claim and
was never sourced.

## The one thing the page does say about what comes first

> a two-to-three-minute presentation video — *"one of the first resources judges review"*

Not the repository, not the page, not the form. **The presentation video is the first artifact.**

## What the form requires

Read off the same page, so the same caveat applies — confirm before filling.

| | have it? |
|---|---|
| product name and brief description | ✅ registered |
| blockchains and tools integrated | ✅ derivable |
| all teammates, with background and experience | ⬜ **founder-only** |
| team location | ⬜ **founder-only** |
| product logo or graphic | ⬜ **does not exist** |
| GitHub repository link | ✅ `github.com/psyto/confide` |
| 2–3 minute presentation video | ⬜ rough cut only, silent |
| product demo video, ≤3 minutes | ⬜ **does not exist** |
| go-to-market, demand validation, distribution | ⬜ **does not exist** |
| disclosure of all relevant past development work | ⬜ drafted from [`../WORK-WINDOW.md`](../WORK-WINDOW.md), not yet written as form text |
