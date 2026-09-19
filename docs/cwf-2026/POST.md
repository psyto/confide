# The public post — ready to publish, founder posts

Drafted 2026-09-19. **No individual outreach** (founder ruling, 2026-09-18): this is written once,
has no addressee, and asks for nothing.

**Run `./scripts/reach.sh` before posting.** It establishes the baseline; without one, whatever
arrives afterwards cannot be told apart from what was already there.

**Every number below is timestamped and recomputable.** Re-run `./scripts/capacity.sh` and
`./scripts/slot-scan.sh` before posting and update the figures from their output — they move, and a
post quoting a number the page contradicts is worse than no post. Current reading:
**$22.0 m / $83.0 m, 2026-09-19 02:01:46 UTC.**

---

## Long form

> **Every tokenized stock on Solana ships a privacy feature nobody can use. Here is exactly what it
> costs, in someone else's numbers.**
>
> All 1,992 tokenized-equity mints on Solana have Token-2022 confidential transfers switched on, and
> **every single one leaves the auditor key empty.** Backed 828, Backpack 1,156, PreStocks 8 —
> **three issuers with nothing to do with each other**, and not even the same product: Backed and
> Backpack tokenize listed equity, PreStocks tokenizes companies with no public market at all
> (SpaceX, OpenAI, Anthropic, Neuralink). Three of them arriving independently at the same
> configuration, across two different asset classes, makes it a property of the substrate rather
> than a choice by any of them. The reason is that the only disclosure model on offer is a global
> key that reads everyone's everything, forever: fill it and every holder is readable by one party
> for good, leave it null and no holder can prove anything to anyone.
>
> (Not every issuer even gets that far. Tessera's T-SpaceX, T-OpenAI and T-Kalshi are Token-2022
> with **no confidential-transfer extension at all** — there is nothing to leave empty, and no way
> to hold them privately in the first place.)
>
> That would be a curiosity, except people are already lending against these tokens. Kamino has 19
> tokenized-equity reserves live right now. **$22.0 m deposited, $83.0 m of borrowing that their own
> caps and LTVs already authorise** (read 2026-09-19 02:01 UTC; recompute with
> `./scripts/capacity.sh`). **$0 of it is reachable if you would rather your position were not
> public.**
>
> **Kamino's refusal is correct underwriting, not an oversight.** A lender who cannot read a balance
> cannot price it, and refusing what you cannot value is how this is supposed to work. Their program
> names the confidential-transfer extensions explicitly and requires them switched off — on the
> depositor's own account, at deposit. `constraints.rs:187`, `:194`, `:201`, and
> `lending_checks.rs:186`, at release/v1.25.0.
>
> What I did not expect is that the last of those lines is a pincer. `constraints.rs:131` refuses a
> mint whose `autoApproveNewAccounts` is *true* — a mint anyone could open a confidential account on
> without asking the issuer. So the setting Kamino requires is the setting that puts the issuer in
> the path of every escrow. **They are the same field read from two sides**, and satisfying either
> forces the other.
>
> Which side is the market on? **1,992 of 1,992.** Zero auto-approve. There is no mint on the
> ungated side, so this is not solved by picking a different ticker, and no amount of engineering
> outside Kamino or the issuers removes it.
>
> I have been building the part that does not need anyone's permission: proving a balance clears a
> floor without revealing it — checked by Solana's own ZK program, not by me — and settling
> collateral on default, and back to the holder, without the holder signing again. It runs end to
> end on devnet. **It is a reference implementation, not a product, and it does not make the pincer
> go away.**
>
> Everything above is checkable without taking my word for it. The decision page reads any of the
> 1,992 from mainnet in your browser: https://psyto.github.io/confide/kamino.html
> Code, scripts and the fourteen generated admission packets: https://github.com/psyto/confide
>
> **If I have read Kamino's source wrong, I would rather find out from you than from a judge.**

---

## Short form

> Every tokenized stock on Solana — all 1,992, from three unrelated issuers, listed equity and
> pre-IPO alike — ships confidential transfers with the auditor key empty.
>
> Kamino lends against them: $22.0 m deposited, $83.0 m authorised (19/09 02:01 UTC).
> $0 of it is reachable if you want your position private.
>
> Their refusal is correct underwriting. But the line that enforces it —
> `constraints.rs:131`, auto-approve must be false — is the same line that makes the issuer
> approve every escrow. Same field, two sides.
>
> 1,992 of 1,992 are on the gated side. Not solvable by picking another ticker.
>
> Check it yourself: psyto.github.io/confide/kamino.html

---

## Why it is written this way

- **It leads with the finding, not the project.** The first paragraph is about the market; Confide
  appears in the second half and is described as a reference implementation that *does not solve
  the problem it found.*
- **Kamino is conceded as correct, twice, before anything is said about the gap.** A post that reads
  as an attack on a protocol with $22 m in it gets answered as an attack, and the framing freezes
  before anyone looks at the evidence.
- **Nobody is asked for anything.** No meeting, no reply, no LLTV. The only invitation is to prove
  me wrong, which costs the reader nothing and is the one response worth more than silence.
- **Every number carries a timestamp and the command that produces it.** The chain moved $21.1 m →
  $22.0 m in three days while this was being written; a post is a fixed artifact and the market is
  not.
- **No claim of traction.** Nothing here says anyone uses this, because nobody does.

## What is deliberately not in it

**The transfer-fee finding.** Eight live mints are in a Token-2022 combination the platform cannot
execute ([`PRE-IPO.md`](PRE-IPO.md)), and it is **not** in this post and should not be added to it
without a decision. Three reasons:

- The post has one finding and it is the Kamino pincer. A second one halves both.
- Those eight mints belong to a company **sponsoring the event this is being submitted to**. A
  public note about their product's behaviour, from someone with no relationship to them, is a
  different act from a note about a boundary in Kamino's source — and Kamino's is framed as
  *correct underwriting*, which this one cannot be.
- **They have not been told.** That comes first, and it is the founder's to do or not.

## What not to do afterwards

- **Do not DM anyone the link.** That is individual outreach under another name, and it was ruled
  out on 2026-09-18.
- **Do not argue with a refusal.** Record it exactly as received, reasons included. A reason is
  information about the market; a won argument is not.
- **Do not report arrivals as traction**, in the submission or in a check-in. See
  [`REACH.md`](REACH.md).
