# Check-in 1 — 2026-09-18

**One minute. Colosseum asks for it weekly; this is the first of four** (09-18, 09-25, 10-02,
10-09). Not the submission presentation — that is
[`CWF-PRESENTATION.md`](CWF-PRESENTATION.md), two to three minutes, due 10-12.

The form asks three things: *what changed*, *what did you learn — share a test, conversation or
decision*, and *what is next*. Written **after** the week's work rather than before it, so it
reports rather than promises.

A minute is about 137 words at the pace the earlier recording held. Three answers inside that is
tight, which is the point: it forces one thing per question.

| | scene | seconds (+ silence) | words | pace | what it shows |
|---|---|---|---|---|---|
| 1 | what changed | 15 | 33 | 138 | the commit log for the week |
| 2 | what I learned | 25 + 1 | 56 | 138 | the Kamino reserve table, live |
| 3 | what is next | 19 | 43 | 140 | the three missing pieces, as text |
| | | **60 s** | **132** | | |

## The script

### 1 — what changed

> I stopped adding to the mechanism, and went and read a lending protocol's source code instead.
> Kamino's. Forty minutes of reading told me more than the four days of building I had planned.

*Shows:* the week's commits. **The answer is a decision, not a feature** — which is what the
question is for, and the harder thing to say.

### 2 — what I learned · +1 s silence

> Kamino already lends against tokenized stocks. Nineteen live markets, twenty-one million dollars
> deposited, eighty-one million of borrowing their caps authorise.
>
> And its own program refuses a deposit from an account holding value confidentially. Four lines.
> So the market is there, the money is in it, and none of it is reachable without publishing what
> you hold.

*Shows:* the reserve table, live, then `constraints.rs` on screen. **The pause is before "and its
own program"** — the first half is someone else's success, the second is the wall. Both are read
off the chain and out of a public repository, so **nobody had to agree to anything for either
number to exist.**

### 3 — what is next

> Three pieces are missing and I can name them. Re-proving the floor, the liquidation hand-off, and
> the issuer approving each escrow. Next week they get specified rather than described. Traction is
> still zero, and I would rather say it than have it found.

*Shows:* three lines of text. **Ending on traction is deliberate.** It is the weakest fact and the
first one a judge checks; saying it costs five seconds and buys the rest of the minute.

## What this deliberately leaves out

- **The correction.** A review found that a repair I had reported as done — requiring the proof
  context accounts to be owned by the ZK program — was a claim and not a check, and without it the
  binding around it was decoration. It is fixed, tested and redeployed. It is the most interesting
  thing that happened this week and it does not fit in sixty seconds without crowding out the
  finding. **Check-in 2 or the submission presentation, where there is room to land it properly.**
- **The packets, the decision page, the capacity script.** Artefacts, and the question asked for a
  decision.
- **Any number that needed someone to agree to it.** There are none this week, which is the part
  worth noticing.
