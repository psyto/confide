# The swing — 2026-09-19

Written because the founder asked for the fundamental move rather than the next task, and said
plainly that they will take risk to be far ahead. This is the case for changing what Confide *is*
for the remaining 23 days, the case against it, and what it costs if it fails.

**It is a proposal, not a decision.** It went to review before anything was built, and
**the review took it apart.** Read [the verdict at the bottom](#the-verdict--2026-09-19) first; the
body above it is left standing because the correction only makes sense against what it corrects.

## The thing that changed today

`docs/27-DAYS.md` opens on this:

> **potential market size, viability and traction are the four-sevenths of the score that get read
> before any of it**, and traction is zero.
>
> Twenty-seven days of more mechanism does not move that.

That sentence set the direction of the whole month: stop building, build a business story instead.
**Its premise was read today for the first time and it is false** ([`CRITERIA.md`](CRITERIA.md)).
Traction is listed *last* of the seven and **does not exist as a criterion in the Official Rules at
all.** §8 opens on *Functionality — how well does this work? what is the quality of the code?*
Product + Execution is third on the web list. Insight is second.

So the plan traded away the strongest hand in the deck to cover a criterion that is either last or
absent, on a premise nobody had checked.

**That is the fundamental error, and it is bigger than any single task.**

## What Confide actually is right now

Not a product. **A report about someone else's limitation, with a partial mechanism attached.**

The flagship verdict on the flagship question is `REQUIRES INTEGRATION`. Read plainly by a judge,
that says: *this does not work with the thing it needs to work with.* The page is excellent, the
finding is real, the capacity number is recomputable by a stranger — and the takeaway is still
**"someone else must act before any of this matters."**

That is the weakest possible business shape. The TAM is gated by another protocol's roadmap, and
the pitch ends on a request.

## What is already built, which is more than the plan credits

Checked in the source, not remembered:

| | |
|---|---|
| `originate` | records a loan and **refuses it unless seizure is already out of the borrower's hands** — the escrow is PDA-owned |
| floor proof | `q_min` proved over the account's own ciphertext, **verified by Solana's own ZK program**, not by us |
| `in_default(q_min, price, principal, ratio_bps)` | a real LTV test against an **oracle-signed price** |
| `seize` | collateral moves to the lender on undisputed default, **borrower never signs again**, both sides stay confidential |
| end to end | `./scripts/seizure-e2e.sh`, and it has run on devnet — program `Gn3rzw8U…`, loan `26QJWCRw…` reads `seized` |

**This is not a toy.** It is a confidential-collateral loan with oracle-priced LTV default and
non-cooperative recovery, running on a public chain. What it is not is a *lifecycle*: a loan can be
opened and it can be seized, and nothing in between exists.

## The swing

> **Stop being the report about the blockage. Be the thing that removes it.**
>
> Ship the **complete confidential-collateral loan lifecycle** on devnet — originate, re-prove,
> repay, default, liquidate — and put it behind a page where a judge does it themselves in under a
> minute. Then the `REQUIRES INTEGRATION` verdict stops being the conclusion and becomes the
> *setup*: we asked whether existing venues can take this, they cannot for four specific lines of
> their own source, **so here is the venue that can, and here is the diff they would need.**

### What has to be built

Two instructions and a schedule. Both are variants of machinery that already works.

1. **`reprove`** — *"a floor proved once is only true once"* is the repository's own sentence, and
   it is the honest reason a lender could not rely on this. The loan gains a floor expiry; a new
   floor proof against the same escrow refreshes it; a stale floor is a default condition on its
   own. The proving machinery exists (`prove-collateral.sh`, the context accounts, the ZK program).
   **This is the one that turns a snapshot into a position.**
2. **`repay`** — currently on the refused list. It is the same shape as `seize`: a confidential
   transfer out of a PDA-owned escrow, authorised by the program. Different destination, different
   precondition. Without it there is no lifecycle, only a foreclosure.

Then the page: a visitor picks a position, watches it borrowed against, watches the floor
re-proved, and chooses whether it repays or defaults — **on devnet, live, with explorer links.**

### Why this is not "more mechanism" in the sense the plan refused

The plan refused mechanism that *"establishes no demand"*. This is different in kind: it is the
difference between **a component and a product**, and it is the first time the work answers *could
this be a real app that people will actually use* with a demonstration instead of an argument.

It moves, specifically:

| criterion | from | to |
|---|---|---|
| §8(a) Functionality | components work | **a complete lifecycle works** |
| §8(c) Novelty | a finding about Kamino | **first working confidential-collateral loan on Solana** |
| §8(d) UX — *downstream users* | nobody built for this | **a page where a non-developer does it** |
| §8(b) Potential Impact | $81.6m named | $81.6m **plus every confidential market after it** |
| §8(f) Business Plan | "someone should integrate us" | **the valuation and settlement layer, with a reference venue** |
| web 3 — Product + Execution | strong | **much stronger** |

### The positioning that keeps it honest

**Not "we are building a lending protocol."** That is crowded, and it would be a claim this cannot
support. The line is:

> We are not trying to be Kamino. We built the smallest venue that proves the primitive works, so
> that any venue can adopt it. It runs on devnet. It is not a product you can put money in.

Every existing claim stays true and nothing already published gets rewritten.

## The case against, stated properly

1. **23 days, and two of those instructions touch confidential transfers and a ZK program.** The
   `deshield` history says exactly how this goes wrong: a public balance in a PDA-owned account is
   not movable by an ordinary transfer, which was a **design** error and not a coding one. `repay`
   could hit the same wall.
2. **The required deliverables do not move.** Presentation video, demo video, logo, form text, GTM.
   If the build eats them, the submission is worse than doing nothing — **a judge cannot score what
   was not submitted.** These must be finished first or in parallel, never after.
3. **It is still zero traction.** A working lifecycle nobody uses is a better demo, not a business.
   The criterion is last and absent from §8, but *Viability* is sixth and real.
4. **Repayment is on the refused list**, and the reason given was that *"a release path that does
   not end at a real venue is the same shape of unfinished as `deshield`."* **If the venue is ours,
   that reason no longer holds** — but this is the founder's refusal to lift, not mine.
5. **It could read as scope creep to a judge who liked the discipline.** The repository's whole
   character is refusing to overclaim. Building a venue to escape a `BLOCKED` verdict must not look
   like escaping the verdict.

## What goes out in parallel, because it needs lead time

**The public post.** Authorised 2026-09-18, and it is the only path from traction zero that does not
require contacting anyone. The link-worthy sentence already exists and is verifiable:

> $21.1m of tokenized stock sits in Kamino reserves. $81.6m of borrowing is already authorised
> against it. **$0 of it is reachable if you would rather your position were not public** — and here
> are the four lines of Kamino's own source that decide it.

It names no villain, asks for nothing, and every number can be recomputed by the reader. **It should
go out early**, because arrivals need time and a post on 10-11 reaches nobody before judging.

## The order, if this is taken

| | | why |
|---|---|---|
| 1 | **presentation video**, narrated | the page says it is among the first things judges open. It is the highest-leverage artifact and it is founder-gated on voice |
| 2 | **the public post** | lead time is the only thing that cannot be bought later |
| 3 | **`reprove`** | turns a snapshot into a position; the honest gap the repository named itself |
| 4 | **`repay`** | completes the lifecycle |
| 5 | **the lifecycle page + demo video** | §8(d), and the demo video is a required field |
| 6 | form text, logo, GTM | must not be last, but must not be first either |

**If the build slips, it slips — 1, 2, 5 and 6 still ship.** That is the condition on which this is
worth attempting at all.

---

## The verdict — 2026-09-19

Reviewed by Codex ([`../reviews/2026-09-19-codex-the-swing.md`](../reviews/2026-09-19-codex-the-swing.md)),
and **three technical findings against this proposal are correct.** Checked in the source before
being accepted, the way yesterday's review was checked before being rejected.

### What I got wrong

**1. This is not a loan, so "complete the lifecycle" was the wrong sentence.**
`principal` is a `u64` at `OFF_PRINCIPAL` that feeds `in_default`, and nothing else. The loan
record — `LOAN_LEN = 415` — has **no loan-asset mint, no disbursement, no repayment accounting and
no maturity**. No money reaches the borrower at origination. What exists is **custody plus
conditional settlement**, and calling it a loan lifecycle would have been the kind of overclaim this
repository exists to refuse.

**2. `reprove` adds close to nothing here, and the repository already said so.**
[`../KAMINO.md`](../KAMINO.md) line 178: *"`originate` verifies the escrow's SPL owner is the loan
PDA before it records anything, **so the floor holds because the holder no longer controls the
account**."* A balance that cannot be reduced does not need its floor re-proved. The same file
lists re-proving as an open question two paragraphs later — **and that gap belongs to the
integrated design**, where collateral sits in the borrower's own account, not to this one. The
proposal aimed an instruction at the wrong design.

**3. A release path is not one instruction.** `deshield` already exists and refuses, and its own
comment says why: *"the withdraw proof contexts and the amount are not recorded … **The loan record
has no room for them.**"* The record carries **one** destination and **one** context triple — the
seizure route. A second route needs its own destination, its own contexts and freshly built
ciphertexts. That is a change to the record layout, not an added entry point.

### What survives, and is the better swing

Smaller than proposed, and honest without a lending story attached:

> **The escrow is a one-way door.** Collateral goes in, and the only way out is seizure. A holder
> whose obligation is settled **has no way to get their position back.** That is a real deficiency
> in what is already built, independent of any venue, and it is what `deshield` was for.

So the bounded piece of work is **the release path**: extend the loan record to carry a second
settlement route, and make release reachable. Then the custody claim is complete — a position can be
locked, proved, taken on default, **or returned** — and nothing has to be said about lending at all.

**Time-boxed to 3–4 days with a kill criterion**, after the required deliverables, not before them.
If it does not land, what ships is coherent instead of half-built.

### The framing, which is Codex's and is better than mine

> **Confide Reference — a devnet executable specification for confidential collateral custody and
> settlement.** Not a lending protocol, not a pool, not a Kamino integration.

`REQUIRES INTEGRATION` **stays as the conclusion about Kamino.** Nothing claims we escaped it by
building our own venue, and the "diff Kamino would need" is not presented as something Kamino asked
for. A reference implementation can prove where the interface boundary is. It cannot prove adoption.

### The order

1. **narrated presentation video** — the one artifact the page says judges open first
2. **submission answers** — founder + market fit, GTM, distribution, demand validation, prior-work
   disclosure, traction stated as zero
3. **demo video, from what already works**
4. **the public post, and instrument the page** — reported as distribution learning, never traction
5. **logo** — cheap, early, not a day
6. **then** the release spike, 3–4 days, killable

The post is drafted here and posted by the founder, so it costs no engineering day and should go out
as soon as its text is right. Lead with **Kamino's refusal being correct underwriting**, timestamp
every number, link the recomputation. The risk is not being scooped — the evidence is already
public — it is freezing an adversarial, stale framing.

### On the reviewer

Yesterday's review led with a finding that was wrong, and it was rejected after checking. Today's
led with three that are right, and they were accepted after checking. **The procedure is the same
either way**, which is the only reason either outcome means anything.

---

## The spike landed — 2026-09-19

**Kill criterion met, six days early.** `MODE=release ./scripts/seizure-e2e.sh`, on devnet:

```
  --- the borrower arms the way back; the lender still has to sign ---
    arm-release            ok
  --- the borrower cannot release it themselves ---
    the program refuses — the authority is the lender's, recorded at origination
  --- the lender signs, and it goes back ---
    release                ok
  --- where the position ended up ---
    escrow    confidential       0 base units  = 0 units
    borrower  confidential       17300000000000 base units  = 173000 units
```

Loan `9yfKfFD5ixUeoEGZxN3fxAwRW2rzWB74R5sexzsYiMJo` reads 740 bytes, `seized = 0`,
`released = 1`, off the chain. **The one-way door has a second exit**, and the seizure path still
works — `MODE=seize` was re-run on the same deployment and the collateral still goes to the lender
on default.

**The old evidence survived the upgrade**, which was the part most likely to break silently. The
loan the published video points at is 415 bytes; `may_settle` checks against `LOAN_LEN_V1`, so it is
still readable and still seizable by the program that grew past it.

### What cost the most, and it was not the cryptography

`seizure-ctx` compiles the range proof's v0 message against a lookup table it assumes holds
`[range_account, authority]` at indices 0 and 1. Extending the *existing* table for the release
proofs put the new range account at index 2, so the message resolved index 0 to the **seizure
set's** range account — already initialised. The chain reported `AccountAlreadyInitialized` on a
*create* instruction, three steps away from the cause. The fix is a second table.

**That is a real hazard and it is now a comment in the script**, because the next person to add a
third proof set will extend the table again.

### What this does not become

Not a lending venue, and the framing does not move: **a devnet executable specification for
confidential collateral custody and settlement.** `REQUIRES INTEGRATION` stays as the conclusion
about Kamino, and [the pincer](THE-PINCER.md) is why that conclusion does not depend on which asset
anyone picks.
