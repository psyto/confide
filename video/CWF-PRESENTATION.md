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

## The shape — reordered 2026-09-20, and this is the second restructure today

The founder asked why the product does not appear until halfway, and whether a judge should be
assumed to reach it. **They should not**, and the order this replaces was resting on a premise this
repository had already retracted.

That order came from *"four of the seven judging criteria are non-engineering and get read first,
so: the market before the mechanism."* [`CRITERIA.md`](CRITERIA.md) took that apart on 2026-09-19:
**traction is last of the seven and does not appear in the Official Rules at all**, §8 opens on
**Functionality — how well does it work?**, and **§8(e) asks how well the work composes with other
primitives**, which is the one scene that was buried deepest. The script never followed its own
correction.

So: **what it is, then it working, and only then why anyone needs it.** The product lands inside
the first thirty seconds and everything after it is depth a judge can stop watching at any point
without losing the claim.

| | |
|---|---|
| 0:00 – 0:32 | what this is, and the trade itself |
| 0:32 – 1:23 | why anybody wants it — the leak, the moment, the gate, the count |
| 1:23 – 2:22 | why it is not only equities, why a trade and not a loan, and what it cost to build |
| 2:22 – 2:52 | what is missing, and the one thing a viewer can go and do |

**The craft rules from the published cut still hold, and are the reason this reads the way it does:**
speak to the viewer; reframe in seven words; show before you count; leave one gap; and the narration
never reads the screen.

| | scene | seconds (+ silence) | words | pace | what it shows |
|---|---|---|---|---|---|
| 1 | what this is | 8 | 17 | 138 | the title card — Confide, and what it does |
| 2 | the trade | 23 | 52 | 139 | the exchange as a diagram: two parties, two arrows, an empty middle |
| 3 | why anyone would bother | 14 + 2 | 31 | 139 | a position climbing across a quarter, watched |
| 4 | this account | 11 + 5 | 23 | 133 | `spl-token balance` says 0; the confidential balance says 173,000 |
| 5 | already solved, already switched off | 15 | 33 | 138 | the mint scan finishing, the auditor slot empty |
| 6 | so I counted | 10 + 2 | 22 | 140 | `./scripts/usage-scan.sh` running to its total: 329,536 accounts, 0 |
| 7 | and it is not only equities | 15 | 32 | 133 | PYUSD and USDG beside a tokenized stock, the matching fields lit |
| 8 | why not just use an exchange | 26 | 58 | 137 | three steps: public state, moved by the amount, subtracted |
| 9 | so what Confide actually is | 25 | 55 | 135 | both instruction names in one transaction; the record account |
| 10 | what is missing | 19 | 41 | 134 | the conditions table, then a command and the page URL |
| | | **175 s** | **364** | | |

## The script

### 1 — what this is

> Confide settles tokenized stock against a stablecoin in a single transaction, and neither side
> publishes what moved.

*Shows:* the title card. **The product, not the problem.** The card this replaces stated a finding —
that nobody has ever opened one of these accounts — and a viewer who stops after ten seconds took
away a fact about somebody else rather than a thing that exists.

### 2 — the trade

> Delivery, and payment, in one transaction — and the only people who can read either number are
> the two making the trade. Neither side could have happened without the other, which is the only
> thing a clearing house is for, and there isn't one. Confide holds nobody's assets and stands
> between nobody.

*Shows:* the exchange **inside a sealed container** — two parties, stock crossing one way and cash
the other, an empty middle, and the four zeroes the chain shows everybody else **outside** it.

**The first version of this scene drew a trade that looked entirely public.** Every figure was in
plain sight and confidentiality was one small line underneath, which is backwards: those numbers
are exactly what nobody outside is supposed to have. The picture has to show them **enclosed**, so
it does — and the narration now says it too, because it did not.

**This scene used to be ninety seconds in.** It was first a list of instruction names, which shows
that two transfers happened and not that a trade did; then a table, which showed the trade but read
as output; and now a picture, at the front.

**And the line under it said the wrong thing.** It read *"no venue, no custodian, no clearing house
— and no program of ours"*, which was meant as *nobody stands in the middle* and reads as *we built
nothing.* A judge could close the tab there and be right to. The empty middle is what Confide
**removes**; scene 9 is what it **is**.

### 3 — why anyone would bother · +2 s silence

> So why hide it. If you hold tokenized stocks on Solana, everyone can see what you hold. Nobody
> attacked anything — the chain simply publishes it, the moment each purchase settles.

*Shows:* a position climbing across a quarter, watched. **Second person, and the second sentence is
the one that has to land** — this is the default behaviour, not an incident.

### 4 — this account · +5 s silence

> This is a real account on Solana, right now. The chain says it holds nothing.
>
> It holds a hundred and seventy-three thousand shares.

*Shows:* `spl-token balance` returning `0`, then the confidential balance. **Leave the gap.** The
strongest ten seconds available, and still is.

### 5 — already solved, already switched off

> Nearly two thousand of them, from three issuers with nothing to do with each other. Every one
> leaves the auditor key empty, and every one needs the issuer's signature to open an account.

*Shows:* the mint scan finishing; the auditor slot empty. **Three independent issuers reaching the
same dead end is the line** — one company being careful is a story about that company.

### 6 — so I counted · +2 s silence

> So I stopped reading the settings and counted. Three hundred and twenty-nine thousand accounts,
> across Apple, NVIDIA, SpaceX and Anthropic.
>
> Not one.

*Shows:* the account scan running to its total. **The reveal** — every other measurement in this
project is about how the mints are configured. This one is about whether anybody got through, and
the answer is that the door has never been opened.

### 7 — and it is not only equities

> That dollar has the same empty auditor slot and the same locked door. Two regulated issuers, two
> different asset classes, the same dead end. This was never a story about tokenized stocks.

*Shows:* PYUSD's and USDG's configuration next to a tokenized stock's, the matching fields lit.
**Market size, argued by evidence rather than asserted.**

### 8 — why not just use an exchange

> You cannot do this on one. A pool's reserves are public, and a trade moves them by exactly the
> amount traded — so anything settled against a pool publishes the size, whatever the token can do.
> It has to be two parties, directly. That is not a gap here; it is why this is shaped as it is.

*Shows:* the argument in three steps — public state, moved by exactly the traded amount,
subtracted. **No numbers, because none are needed and inventing a pool to illustrate it would be
the one thing this repository does not do.**

**The question a Solana judge asks first, and the film did not answer it.** This slot used to hold
the project's own history — a month spent on a loan before the trade — which is insight about the
builder and not about the product. A structural limit that explains the shape is worth more than a
confession, and [`../docs/cwf-2026/COMPOSITION.md`](../docs/cwf-2026/COMPOSITION.md) is where it
is derived.

### 9 — so what Confide actually is

> The chain will not assemble that trade for you. The proofs do not fit in a transaction, and on a
> mint that charges a fee one of them does not fit at all. Confide builds them, puts them on chain,
> and hands each side the other's amount to decrypt before signing. That is the product.

*Shows:* the two instruction names in one transaction, then the record account the oversized proof
had to be staged through.

**The founder asked what Confide does, what it makes possible and why it is needed, and the film
answered only the middle one.** This scene used to present the engineering as a curiosity — *look
how awkward this was* — when it is the answer to the first question. It is also the scene for
§8(a), functionality, and §8(e), how the work composes with other primitives.

### 10 — what is missing

> Nobody outside this repository has used any of it. But what is left is not unknown: each obstacle
> is a condition you can check, and for the two that decide the market, the work on the far side is
> already running.

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
