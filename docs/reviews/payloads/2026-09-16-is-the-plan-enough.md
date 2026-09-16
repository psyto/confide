# Is the 27-day plan enough to win, and is it the right shape?

Read these in the repository, do not rely on this summary:

- `docs/27-DAYS.md` — the plan under review. **I wrote it, so I am not a safe judge of it.**
- `docs/reviews/2026-09-16-codex-conservative-plan.md`, `-aggressive-plan.md`, `-demand-side.md` —
  your three earlier passes. The plan is what survived them.
- `STATUS.md` — the two-hackathon split, the open founder-only items, the judging criteria note.
- `README.md`, `docs/SEIZURE.md` — what actually exists and runs today.
- `docs/reviews/2026-09-16-codex-implementation-block.md` — your block verdict on the seizure
  implementation. Three of the four findings are repaired (commit `334fe5b`); `deshield` is
  disabled and returns an error because the loan record has no room for the withdraw proof
  contexts and the amount.

## Context that is not yet in the documents

Two decisions were made after the plan was written and are **not recorded anywhere yet**:

1. **Kamino, not Morpho**, as the venue. The founder's words: *"Morpho ではなく、Kamino でやる
   Reason を Confide が作り出せたら最高"* — the aspiration is that Confide **creates the reason**
   to do this on Kamino specifically rather than on Morpho.
2. **SPCX (SpaceX exposure)** as the named asset.

The founder has also stated a hard constraint: **the buyer must understand the benefit easily and
must be able to try it easily.**

## The question

The founder read the plan and said: *"やることリストは少なすぎませんか？これでハッカソンに勝てるか
心配です"* — the to-do list looks too short, and they are worried it does not win.

My own reading is that the list is **not too short in hours, but too narrow in what it can win**:
nearly all of its scoring upside is conditional on an external party replying, and replies are the
one input not under our control. If nobody replies, traction stays 0 and market size / viability
remain arguments rather than evidence — four of the seven criteria, and they are read first.

Attack that reading. Specifically:

1. **Is my diagnosis right?** Or is the founder's plain reading right — that the plan is simply
   too small, and a month of this produces too little to place?
2. **What work scores regardless of whether anyone replies?** Name it concretely. It must not be
   more mechanism; the refuse list in `27-DAYS.md` exists because more mechanism was found not to
   move the four criteria read first. If you think that finding was wrong, say so.
3. **Is the Kamino wedge real?** Is there something about Kamino's market structure — curated
   markets, risk council, whatever it actually is; check, do not assume — that makes a
   disclosure-conditioned collateral admission *expressible there and not on Morpho*? Or is
   "Kamino rather than Morpho" a preference with no mechanism behind it? If it is real, it is the
   strongest thing in the plan and it is currently not written down. If it is not, say so plainly
   and the founder will hear it.
4. **SPCX as the named asset** — is it a good choice for this argument, or does a
   pre-IPO/SPV-backed exposure carry structural problems (redemption, eligibility, price
   discovery, oracle) that make it the hardest possible first case rather than the most
   compelling one?
5. **Outreach shape.** The plan names one buyer type and no numbers. Your conservative pass asked
   for 30 contacts / 6 conversations. Should the plan carry counts, and what is the honest
   conversion expectation with no network, starting 09-16, for a written conditional decision?
6. **Sequencing risk.** The submission videos sit in week 4. The first artifact a judge sees is a
   2–3 minute presentation. Is leaving the narrative untested until the last week a mistake?
7. **The seizure repair.** `deshield` is disabled. Finishing it costs roughly a day. Does it
   belong in this month at all, or is a disabled instruction with an honest note the correct
   end state for the submission, given the refuse list?

Be concrete and be willing to say the plan is wrong. Cite files and lines. If the honest answer is
that this plan does not win and something else does, say what that something else is and what it
costs.
