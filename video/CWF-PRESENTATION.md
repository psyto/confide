# The submission presentation — structure and script

**Rough cut. Not for publication.** Its only job is to find out whether the story holds before the
week the video has to exist. If a scene cannot be shown with something that already runs, the
problem is the story, not the footage — and this is the cheap moment to learn that.

Target **~170 s**, inside the 2–3 minute allowance, so there is room to slow down rather than cut.
Pacing budget is words over clip length minus 0.6 s of tail, the convention
[`segments/LINES.md`](segments/LINES.md) already uses. Anything over 180 wpm is reading without
pauses.

**This is not the weekly check-in.** That is one minute, Colosseum asks for it, and the first
opens 09-18. See [`../docs/27-DAYS.md`](../docs/27-DAYS.md).

## What this learned from the published cut

The first draft of this script was better argued and worse told than
[`voiceover.md`](voiceover.md), the narration for the Stocklana video. Four things that one does
and the draft did not:

- **It speaks to the viewer.** *"If you hold tokenized stocks on Solana, everyone can see your
  position."* The draft opened on a statistic — a fact about the world rather than about the person
  watching.
- **It reframes in seven words.** *"Nobody attacked anything. The chain simply publishes it."* The
  draft had no equivalent, and without one the opening reads as an accusation nobody made.
- **It shows before it counts.** A fund buying NVIDIA across a quarter, watched; *then* the 1,869
  lands as a reveal. The draft spent its statistics before the viewer had felt anything.
- **It has one moment.** *"The chain says it holds nothing."* — pause — *"It holds a hundred and
  seventy-three thousand shares."* The draft put an abstraction in that slot.

And one rule it states that the draft broke: **the narration does not read the screen.** The draft's
second scene recited numbers the table already showed.

What the draft had that the published cut does not, and which stays: conceding that Kamino's
refusal is correct, and saying out loud what is missing. Those are worth more here than they were
there, because **viability and traction are judged at this hackathon and were not at the last one.**

## The shape

Four of the seven judging criteria are non-engineering and get read first, so the order is: **the
market before the mechanism, the citation before the claim, and the gaps out loud before anyone
has to find them.** Confide's mechanism is scene 5 of 8, not scene 1.

| | scene | seconds (+ silence) | words | pace | what it shows |
|---|---|---|---|---|---|
| 1 | your position | 12 + 2 | 26 | 137 | a position climbing across a quarter, watched |
| 2 | this account | 11 + 5 | 23 | 133 | `spl-token balance` says 0; the confidential balance says 173,000 |
| 3 | already shipped | 20 + 2 | 45 | 139 | the mint scan finishing, the auditor slot empty |
| 4 | whose money | 19 | 43 | 140 | the 19 Kamino reserves, live |
| 5 | the refusal | 21 | 47 | 138 | `constraints.rs` on screen |
| 6 | what runs | 25 | 55 | 135 | the proofs accepted by Solana's ZK program; the seizure on devnet |
| 7 | what does not | 30 | 66 | 135 | the three missing pieces, as text |
| 8 | what you can run | 19 | 41 | 134 | `./scripts/packet.sh NVDAx`, then the page URL |
| | | **166 s** | **346** | | |

## The script

### 1 — your position · +2 s silence

> If you hold tokenized stocks on Solana, everyone can see what you hold. Nobody attacked anything.
> The chain simply publishes it, the moment each purchase settles.

*Shows:* a position climbing across a quarter, watched. **Second person, and the second sentence is
the one that has to land** — this is the default behaviour, not an incident.

### 2 — this account · +5 s silence

> This is a real account on Solana, right now. The chain says it holds nothing.
>
> It holds a hundred and seventy-three thousand shares.

*Shows:* `spl-token balance` returning `0`, then the confidential balance. **Leave the gap.** This
is the strongest ten seconds available and it is borrowed from the published cut on purpose.

### 3 — already shipped · +2 s silence

> Solana already built this. Eighteen hundred and sixty-nine tokenized stocks have confidential
> transfers switched on, from two issuers with nothing to do with each other. And every one of them
> leaves the auditor key empty, because the only key on offer reads everyone's everything, forever.

*Shows:* the scan finishing, the slot empty. **Two issuers arriving independently at the same dead
end is the line** — one company being careful is a story about that company.

### 4 — whose money

> Which would be a curiosity, except that people are already lending against these. Twenty-one
> million dollars of tokenized stock is sitting in Kamino reserves right now, and the caps
> authorise eighty-one million of borrowing against it. Every one of those positions is public.

*Shows:* the reserve table, live, with the two totals. **Two numbers and the last sentence** — the
table carries the rest. Confide is not in this scene, and the figures are Kamino's own caps, LTVs
and prices, computed by `./scripts/capacity.sh`.

### 5 — the refusal

> Kamino is not ignoring confidentiality. Its program names it, and requires it switched off before
> a deposit will land. That is not an oversight. A lender who cannot read a balance cannot price it,
> and refusing what you cannot value is how underwriting is supposed to work.

*Shows:* `constraints.rs` on screen. **Conceding the refusal is correct is what makes everything
after it credible.**

### 6 — what runs

> So prove what a lender needs without showing the balance. This NVIDIA account holds at least the
> collateral — checked by Solana's own zero-knowledge program, not by us. And if the loan defaults,
> the collateral moves, because the escrow belongs to a program rather than to the borrower. Both of
> those run on devnet today.

*Shows:* the proofs accepted, then the seizure and its explorer link. **"Checked by Solana's own"
is the point** — everything before it is setup.

### 7 — what does not

> Three things are missing, and I would rather say them than have you find them. A floor proved once
> is only true once — re-proving is not built. The seizure has to happen inside Kamino's liquidation,
> not beside it — not built. And the issuer has to approve each account, because these mints do not
> approve them automatically. That last one is nobody's decision but theirs.

*Shows:* three lines of text. **The scene most likely to be cut for time by someone who has
forgotten why it is here.**

### 8 — what you can run

> One command builds the whole admission packet for any of those mints, from live chain data, with
> every unknown capped at zero instead of guessed. Nobody outside this repository has used any of
> it yet. You can check every number yourself.

*Shows:* `./scripts/packet.sh NVDAx` — the control, where every figure is real — then the page URL. **Traction is stated as part of the
close rather than as its own scene** — it is honest either way, and a scene of its own made the
ending apologetic.

## What this needs to become a cut

`record.js` renders the Stocklana video's scenes and none of these. The rough cut needs its own
page and its own scene marks; the pipeline around it —
`record` → `split.sh` → per-clip voice → `join.sh` — works unchanged and is documented in
[`README.md`](README.md).

**Do not reuse the published cut's clips.** Two of its scenes make claims this script deliberately
does not.

## What the rough cut is for

To find out, before the last week, whether:

- scene 2 lands without Confide in it, or whether the argument collapses when the mechanism is
  withheld for a minute;
- scene 3 survives conceding that Kamino is right, or whether the project only sounds interesting
  when a protocol is made to look careless;
- scene 5 can be delivered without the video feeling like a retraction;
- 150 seconds is enough for seven scenes, or whether one has to go — and if so, which, decided on
  purpose rather than in a hurry on 10-11.

## What the rough cut found — 2026-09-18

**Cut, and the length question is settled.** The render holds every scene's scripted duration to the
second, because the page derives them from this script's own table rather than from a hold typed
next to each scene. Eight scenes stand; nothing has to go for time.

The structural questions — whether scene 2 lands without Confide in it, whether scene 5 can concede
that Kamino is right without sounding like a retraction — need the voice on it, and the voice is
founder-only. `segments-presentation/LINES.md` pairs each clip with the line that goes on it.

**What it found instead was in the pictures.** The pane carrying the strongest ten seconds — *the
chain says it holds nothing* — was highlighting **every zero inside `17300000000000`** and leaving
`173000 units`, the number the narration actually says, unmarked. The published Stocklana cut has
the same frame and the same defect, already uploaded. The cause was in the emphasis painter: it
marked one string at a time, so the first pass threaded marker characters through the text the
second pass was looking for. Fixed in `demo.html`.

**No check could have caught it.** Every guard in the recorders is on the *text* of a pane, and the
text was correct — the fault was in the paint. It was found by extracting a frame and looking at it,
which is the only thing that would have. The published upload is left as it is, since the argument
in it is unaffected; a re-render now paints the right number.
