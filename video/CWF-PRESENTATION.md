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
- **It shows before it counts.** A fund buying NVIDIA across a quarter, watched; *then* the 1,992
  lands as a reveal. The draft spent its statistics before the viewer had felt anything.
- **It has one moment.** *"The chain says it holds nothing."* — pause — *"It holds a hundred and
  seventy-three thousand shares."* The draft put an abstraction in that slot.

And one rule it states that the draft broke: **the narration does not read the screen.** The draft's
second scene recited numbers the table already showed.

What the draft had that the published cut does not, and which stays: conceding that Kamino's
refusal is correct, and saying out loud what is missing. Those are worth more here than they were
there, because **viability and traction are judged at this hackathon and were not at the last one.**

## The shape — rewritten 2026-09-20

The script this replaces argued that a lender should be able to price a balance it cannot read. It
was true and it ended on what was missing. **What changed is that the thing being demonstrated
changed**: a loan needs a third party to hold collateral, and that third party is what ran into
every wall. A trade needs no third party, because a Solana transaction is all-or-nothing, and the
swap runs today where the loan could not.

And one measurement arrived that the old script could not have had: **nobody has ever opened a
confidential account on any of these mints.** That moves the strongest statistic from "the feature
is switched off" to "nobody is ahead of you", which is a different and better thing to tell a judge.

So the order is: **the viewer's problem, the moment, the market, the reveal, the turn, what runs,
what it cost to build, what is missing.** The mechanism is still late — scene 6 of 9 — because four
of the seven judging criteria are non-engineering and get read first.

**A title card, restored 2026-09-20.** The first draft of this cut opened straight into the
position climbing, and the founder said the entry was abrupt against the published Stocklana video.
They were right, and the diff says why: that cut spends nine seconds on a hero card before it shows
anything. What the card buys is not decoration — it is **the claim landing before the picture that
illustrates it**, and a viewer who has been told what they are about to see reads the next scene
instead of decoding it.

So scene 1 states the finding and scene 5 earns it. That costs ten seconds, and ten seconds come
back out of scenes 4, 5 and 10, which were each saying something the card now says once.

**The craft rules from the published cut still hold, and are the reason this reads the way it does:**
speak to the viewer; reframe in seven words; show before you count; leave one gap; and the narration
never reads the screen.

| | scene | seconds (+ silence) | words | pace | what it shows |
|---|---|---|---|---|---|
| 1 | the claim | 7 + 1.5 | 15 | 130 | the title card — Confide, and the claim |
| 2 | your position | 12 + 2 | 26 | 137 | a position climbing across a quarter, watched |
| 3 | this account | 11 + 5 | 23 | 133 | `spl-token balance` says 0; the confidential balance says 173,000 |
| 4 | already solved, already switched off | 17 | 37 | 135 | the mint scan finishing, the auditor slot empty |
| 5 | so I counted | 10 + 2 | 22 | 140 | `./scripts/usage-scan.sh` running to its total: 329,536 accounts, 0 |
| 6 | the turn | 22 | 50 | 140 | the escrow in the diagram, then gone |
| 7 | what runs | 23 | 51 | 137 | the exchange as a diagram: two parties, two arrows, an empty middle |
| 8 | the part that was hard | 22 | 48 | 135 | both instruction names in one transaction; the record account |
| 9 | and it is not only equities | 15 | 32 | 133 | PYUSD and USDG beside a tokenized stock, the matching fields lit |
| 10 | what is missing | 22 | 48 | 135 | the conditions table, then a command and the page URL |
| | | **172 s** | **352** | | |

## The script

### 1 — the claim · +1.5 s silence

> Every tokenized stock on Solana can hold a confidential balance. Not one holder ever has.

*Shows:* the title card. **No gap after it** — the one gap in this film belongs to scene 3, and a
second one here would spend it twice. The card states the finding; scene 5 is where it is earned.

### 2 — your position · +2 s silence

> If you hold tokenized stocks on Solana, everyone can see what you hold. Nobody attacked anything.
> The chain simply publishes it, the moment each purchase settles.

*Shows:* a position climbing across a quarter, watched. **Second person, and the second sentence is
the one that has to land** — this is the default behaviour, not an incident. Unchanged from the
previous script, because it is the best opening the project has.

### 3 — this account · +5 s silence

> This is a real account on Solana, right now. The chain says it holds nothing.
>
> It holds a hundred and seventy-three thousand shares.

*Shows:* `spl-token balance` returning `0`, then the confidential balance. **Leave the gap.** The
strongest ten seconds available, and still is.

### 4 — already solved, already switched off

> Nearly two thousand of them, from three issuers with nothing to do with each other. Every one
> leaves the auditor key empty, and every one needs the issuer's signature before you can open an
> account at all.

*Shows:* the mint scan finishing; the auditor slot empty. **Three independent issuers reaching the
same dead end is the line** — one company being careful is a story about that company.

### 5 — so I counted · +2 s silence

> So I stopped reading the settings and counted. Three hundred and twenty-nine thousand accounts,
> across Apple, NVIDIA, SpaceX and Anthropic.
>
> Not one.

*Shows:* `./scripts/usage-scan.sh` running to its total. **The reveal, and it is new** — every other
measurement in this project is about how the mints are configured. This one is about whether anybody
got through, and the answer is that the door has never been opened.

### 6 — the turn

> Which told me I had been building the wrong shape. A loan needs somebody to hold the collateral,
> because it has to survive one side refusing to cooperate for months. A trade does not. A trade
> happens at one instant — and on Solana, an instant is all or nothing.

*Shows:* the escrow diagram, then it disappearing. **"The wrong shape" is the seven-word reframe**,
and admitting it is what earns the next scene.

### 7 — what runs

> Neither side of that could have happened without the other, and that is the only thing a clearing
> house is for. There isn't one. Confide is not a venue and holds nobody's assets — it is what the
> two of them use to settle, and there is nothing in the middle.

*Shows:* the exchange as a diagram — two parties, stock crossing one way and cash the other, and
**an empty middle**. Drawn from figures the parties wrote down at the time; the four zeroes
underneath are what anybody watching gets.

**Twice corrected, and the second correction is the one that matters.** This scene was first a list
of instruction names, which shows that two transfers happened and not that a trade did. Then it was
a table, which showed the trade but still read as output. **The founder asked what Confide actually
is, and the honest answer turned out to be a shape**: the empty middle is the product. So the
picture says where a clearing house would be and that nothing is there, and the voice names it —
*not a venue, holds nobody's assets, nothing in the middle*. It is the only place in the film that
positions the project, and it had none.

### 8 — the part that was hard

> The cash in that trade is shaped like PayPal's dollar. PayPal's dollar charges a fee — so it needs
> a different instruction, five zero-knowledge proofs instead of three, and one proof too large to
> fit in a Solana transaction at all. One transaction carries both sets of rules.

*Shows:* the two instruction names side by side in the same transaction, then the record account the
oversized proof had to be staged through. **This is the scene for the engineering criterion**, and
it is the only place the video is allowed to sound technical.

### 9 — and it is not only equities

> That dollar has the same empty auditor slot and the same locked door. Two regulated issuers, two
> different asset classes, the same dead end. This was never a story about tokenized stocks.

*Shows:* PYUSD's and USDG's configuration next to a tokenized stock's, the matching fields lit.
**Market size, argued by evidence rather than asserted.**

### 10 — what is missing

> Nobody outside this repository has used any of it. But what is left is not unknown: each
> obstacle is a condition you can check, and for the two that decide the market, the work on the far
> side is already running. Every figure here came off the chain.

*Shows:* the conditions table, then a command and the page URL. **Traction is stated inside the
close rather than given a scene** — honest either way, and a scene of its own made the ending
apologetic.

**Two words were corrected here before this was ever spoken.** The draft said *"every obstacle has
a number on it"*, and the issuer gate does not — it is an operations decision, not a threshold. And
it said the work on the far side of *each* obstacle is done, which is true of the issuer gate and
of the venue and **not** of matching or of proving a floor for an ordinary holder. A line a judge
can push over is worse than a weaker line that holds.

## The sections below describe the SUPERSEDED cut

Kept rather than deleted: the rough cut they report on was rendered from the eight-scene script that
ended on the loan, and the defect one of them found is still the most useful thing in this file.
**None of the scene numbers below refer to the script above.**

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
