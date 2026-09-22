# The submission presentation — structure and script

**This is the script the published cut's voice was given** — `scripts/fix-captions.sh` checks the
delivered captions against this file, not against [`voiceover.md`](voiceover.md), which belongs to
the deleted 09-15 cut. The header used to say *"rough cut, not for publication"*, written before it
was published and left standing afterwards.

**Restructured 2026-09-22, and the delivered video no longer matches it.** `Confide_Stocklana_20260920.mp4`
speaks the previous order and one figure the chain has since moved past. Re-recording needs the
founder's voice, so until that happens the published file and this script say different things, and
the file is what a judge sees.

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

## The shape — restructured 2026-09-22, the market first, against a recorded decision

**The third restructure, and it reverses the second, so the reason is written down rather than
assumed.** The founder's call, 2026-09-22: the narrative had changed and the strongest facts were
not being pitched. Two were missing from the cut entirely — **the SEC order**, and **a defect in my
own work found by somebody else.**

**The counter-argument, which is real and is in this repository already.** The 09-20 reorder put the
product first on the grounds recorded below: §8 of the Official Rules opens on **Functionality**,
and traction is last of the web seven and absent from the Rules. That still holds. What it does not
support is *market last* — [`CRITERIA.md`](../docs/cwf-2026/CRITERIA.md) says in its own words
**"No weights. No stated reading order."**, and the web list's first two are **Founder + Market Fit**
and **Insight**. Both orders are defensible from the same two lists.

**What decided it was not the criteria but what is now true.** On 2026-09-17 a regulator built the
lit venue for tokenized equity and left the block trade outside it. That is the strongest external
fact this project will ever get, it dates the opportunity, and it was one sentence in scene 3 of a
ten-scene cut. Functionality did not lose its place — it is scene 9 and the whole evidence table in
[`../_submission/full.md`](../_submission/full.md); it lost only the claim to go first.

### The reasoning the 09-20 reorder rested on, kept because it is still true

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
| 1 | the tape | 21 | 47 | 138 | the order's condition at reading size, wrapped, with the cap beside it and `sec.gov` on the badge |
| 2 | the block | 11 + 2 | 24 | 138 | the name, and under it what this actually is — *tokenized stock against a stablecoin, one transaction, neither amount published.* |
| 3 | the trade | 21 | 46 | 135 | the delivery-versus-payment diagram, both sides moving, sealed, and the four zeroes the chain shows everyone else |
| 4 | this account | 11 + 5 | 23 | 133 | `spl-token balance` returning `0`, then the confidential balance |
| 5 | already solved, already switched off | 19 | 42 | 137 | the slot scan, the empty auditor column |
| 6 | so I counted | 10 + 2 | 21 | 134 | the scan running to its total, then `0` |
| 7 | and it is not only equities | 11 | 24 | 138 | PYUSD and USDG on the identical configuration |
| 8 | why not just use an exchange | 19 | 41 | 134 | reserves moving by the traded amount |
| 9 | why it is hard | 23 | 51 | 137 | the four commands, then the settled transaction and four balances reading `0` |
| 10 | what I got wrong, and what nobody has used | 22 | 48 | 135 | the check refusing, then passing |
| | | **177 s** | **367** | | |

## The script

### 1 — the tape

> Last week the SEC opened the market for tokenized stock. Its venue publishes the size and
> direction of every trade you make within ten minutes, and a quarter of one percent of a day's
> volume is all you may trade. Nobody attacked anything. That is the rule.

*Shows:* the order's condition at reading size, wrapped, with the cap beside it and `sec.gov` on
the badge. **Two scenes became one.** The first cut spent thirty seconds on regulation text before
anything moved, in a monospace pane that ran off the right edge mid-word — a document rendered as
if it were terminal output. The rule earns one scene, not two.

### 2 — the block · +2 s silence

> Block trades have always settled away from the tape.
>
> The SEC has now built the tape for tokenized equity. Nobody has built the block.

*Shows:* the name, and under it what this actually is — *tokenized stock against a stablecoin, one
transaction, neither amount published.* **That sentence was in the published cut and the
restructure dropped it**, so for the first fifty seconds the only statement of what Confide does
was the word *block*, which is trade jargon, over a diagram captioned *cash*. The narration says
the gap and the screen says what fills it, which is the rule this file already has.
**This is also where the product is named, so it comes before the picture of it.** The first cut put the diagram here and the title card after — so
*"nobody has built the block"* landed on a viewer who had just watched one settle, and the name
arrived third. The gap has to be open before anything fills it.

### 3 — the trade

> So here is one. Confide builds the proofs the chain will not assemble for you, and lets each side
> check the other before signing — with nobody in the middle. Fifty thousand tokenized shares
> against eight point seven five million in stablecoin, in a single transaction.

*Shows:* the delivery-versus-payment diagram, both sides moving, sealed, and the four zeroes the
chain shows everyone else. **This is where the film says what Confide does, and it used to say it
at scene 9** — two minutes in, by which point a viewer knew the outcome and not the product. The
answer to *"nobody has built the block"* has to be the picture and the product together.
**The answer to the sentence before it**, and the one picture that
carries the product without a word of explanation. It was dropped in the 09-22 restructure as
collateral damage rather than by any decision.

### 4 — this account · +5 s silence

> This is a real account on Solana, right now. The chain says it holds nothing.
>
> It holds a hundred and seventy-three thousand shares.

*Shows:* `spl-token balance` returning `0`, then the confidential balance. **Leave the gap.** The
strongest ten seconds available, and still is — unchanged from the published cut, which earned it.

### 5 — already solved, already switched off

> Solana already shipped what that needs. Nearly two thousand tokenized stocks, three issuers with
> nothing to do with each other, confidential transfers switched on. Every one leaves the auditor
> key empty, and every one needs the issuer's signature to open an account.

*Shows:* the slot scan, the empty auditor column. **Two issuers arriving independently at the same
dead end is not caution, it is the substrate** — the line the published cut found, kept.

### 6 — so I counted · +2 s silence

> So I stopped reading the settings and counted. Nearly half a million accounts, across Apple,
> NVIDIA, SpaceX and Anthropic.
>
> Not one.

*Shows:* the scan running to its total, then `0`. **Not an exact figure, deliberately.** The
published cut says "three hundred and twenty-nine thousand" and was wrong four days later by the
chain simply growing.

### 7 — and it is not only equities

> PayPal's dollar has the same empty auditor slot and the same locked door. Four issuers, two asset
> classes, one dead end. Nobody chose this.

*Shows:* PYUSD and USDG on the identical configuration. **Ten seconds, and it moves the finding
from an equities story to a substrate one.**

### 8 — why not just use an exchange

> You cannot do this on one, and now that is written down. A pool's reserves are public, and a trade
> moves them by exactly the amount traded — so anything settled against one publishes the size. The
> exemption requires an AMM.

*Shows:* reserves moving by the traded amount. **The structural argument, and the order agrees with
it** — the scene used to make this case alone and now has the rule standing behind it.

### 9 — why it is hard

> The proofs do not fit in one transaction. On a mint that charges a fee there are five of them, and
> one is too large to send at all — it goes on chain in a record account first. Four files, two
> machines, and neither side ever holds the other's key.

*Shows:* the four commands, then the settled transaction and four balances reading `0`. **The
product arrives ninety seconds in, as the answer to a question the viewer already has.**

### 10 — what I got wrong, and what nobody has used

> I called that last step the safety step. A review found it was signing something it had never
> looked at. The fix compares the two, byte for byte — and caught a bug of mine on its first run.
> Nobody outside this repository has used any of this.

*Shows:* the check refusing, then passing. **Ending on a defect I did not find myself.** Traction is
the weakest fact and the first a judge checks, so it costs five seconds and buys the rest.

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
