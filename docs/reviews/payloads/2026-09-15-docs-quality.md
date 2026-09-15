# Review request — the documents, adversarially

You are reviewing **Confide**, a Solana project entered in two hackathons. Review the **documents**,
not primarily the code. Be hostile. Politeness costs us the competition.

## What the project claims to be

Every tokenized stock on Solana (1,869 mints, two issuers) runs Token-2022 with confidential
transfers enabled and the auditor key slot empty. Confide makes that slot usable: disclosure scoped
by recipient, by granularity, and by schedule. It also now seizes confidential collateral on
default, end to end, on devnet.

## What is being judged, and by whom

- **Stocklana** (deadline 2026-09-19): one question — *could this be a real app that people will
  actually use?*
- **Crypto World's Fair / Colosseum** (deadline 2026-10-12): seven criteria, four of them
  non-engineering — market size, viability, traction, founder+market fit — plus insight, product +
  execution, founder communication. The legal rules add a second list: functionality, potential
  impact, novelty, UX, open-source, business plan.

## Read these

- `README.md` — the entry point, the thing judges open first
- `DESIGN.md` — the architecture argument
- `docs/SEIZURE.md`, `docs/ONCHAIN.md`, `docs/DURABILITY.md`, `docs/WORK-WINDOW.md`
- `_submission/full.md` (pasted into the form, 5,000 char cap), `_submission/short.txt`,
  `_submission/youtube.md` (the published video description)
- `web/index.html` — the live demo page at psyto.github.io/confide
- `video/voiceover.md`, `video/segments/LINES.md` — the narration
- `STATUS.md` — internal, but read it to see what the team believes

## The failure mode we already have

A capability (seizure) landed, and **eleven separate places went on saying it had not**. One
paragraph in README contradicted itself: it opened "still has no way to take that collateral on
default" and closed "it now runs end to end". A file that is actually pasted into YouTube was never
updated at all. Two documents described the same directory and disagreed.

Assume there are more of these. Assume the author (me) is bad at finding them, because I wrote them.

## What I want from you

1. **Every false, contradictory, stale or self-undermining claim.** Quote it, say why, cite the
   file and line. Cross-check documents against each other and against the code — if README says a
   script does X, open the script.
2. **Overclaiming.** Anywhere the writing is doing work the evidence does not support. This project
   sells itself on "every line of this runs"; one sentence that does not survive checking costs
   more than ten good ones earn.
3. **Underclaiming and omission.** Things that are true, load-bearing for the judging criteria
   above, and not being said. `DESIGN.md` for instance does not describe the seizure mechanism at
   all. What else is missing?
4. **Structure.** Does `README.md` answer *could this be a real app people will use* in its first
   screen? Is the order right? What should be cut? Be specific: name the sections.
5. **The non-engineering criteria.** Market size, viability, traction, founder+market fit. The
   documents are strong on mechanism and thin here. Say concretely what to add and where — and say
   if you think the honest answer is that we cannot claim it.
6. **Anything that reads as a research artifact rather than a product.** That is the failure mode
   this project has been warned about before.

Rank findings by what would most change a judge's verdict. Do not summarise the project back to me.
Do not praise. If a document is good, say nothing about it and spend the space on one that is not.
