# The submission presentation — structure and script

**This is the script the published cut's voice was given** — `scripts/fix-captions.sh` checks the
delivered captions against this file, not against [`voiceover.md`](voiceover.md), which belongs to
the deleted 09-15 cut. The header used to say *"rough cut, not for publication"*, written before it
was published and left standing afterwards.

**Restructured 2026-09-22, and the delivered video no longer matches it.** `Confide_Stocklana_20260920.mp4`
speaks the previous order and one figure the chain has since moved past. Re-recording needs the
founder's voice, so until that happens the published file and this script say different things, and
the file is what a judge sees.

Target **~175 s**, inside the 2–3 minute allowance, so there is room to slow down rather than cut.
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
| 1 | this account | 10 | 22 | 140 | two cards — what the chain shows, and what the holder can open — with `spl-token balance`'s own line printed under the first, and the confidential line held back and printed under the second when it arrives |
| 2 | and nobody has been allowed one | 19 | 43 | 140 | three figures at one size — the mints, the accounts that have asked, the accounts an issuer has approved — over the scan's own total line |
| 3 | Confide | 17 | 38 | 139 | the name, and a plain definition under it |
| 4 | the trade | 15 | 34 | 142 | the delivery-versus-payment diagram, both sides moving, sealed, and the four zeroes the chain shows everyone else |
| 5 | why the door is shut | 20 | 45 | 139 | the slot scan, the empty auditor column |
| 6 | why now | 21 | 47 | 138 | the order's condition at reading size, with the cap beside it and `sec.gov` on the badge |
| 7 | so the first trade is an issuance | 14 | 30 | 134 | the sentence, alone — |
| 8 | the gate, both ways | 12 | 25 | 132 | refused and settled side by side, with `swap-status.sh`'s own two error lines under them — `{'Custom': 24} (expected)` and `none`. The size in the title is read out of the record of the run, not typed |
| 9 | why not just use an exchange | 17 | 37 | 135 |  |
| 10 | what I got wrong, and what you can run | 25 | 55 | 135 | the assumption that failed beside the repair, the command, and the line of `scripts/swap-sign.sh` that performs it |
| | | **170 s** | **376** | | |

## The script

### 1 — this account

> A real account on Solana. The chain says it holds nothing.
>
> It holds a hundred and seventy-three thousand shares of tokenized stock.

*Shows:* two cards — what the chain shows, and what the holder can open — with `spl-token
balance`'s own line printed under the first, and the confidential line held back and printed under
the second when it arrives. **The five seconds of silence are gone, by the founder's decision on
2026-09-23.** The scene used to hold for five seconds after the last word so the reveal could land
in the quiet; it now ends when the narration does. **The reveal itself stays** — it is a picture
beat rather than dead air, and the green card still waits until the voice reaches it. This opens
the film because it is the one thing in it that needs no vocabulary at all — no tape, no block
trade, no delivery-versus-payment. A judge who has never heard of any of this knows from the
opening scene what is being claimed, and can check it.

### 2 — and nobody has been allowed one

> Every tokenized stock on Solana can do that. All 1,992 of them, from three issuers with nothing to
> do with each other. So I counted the accounts actually using it. Across nearly half a million: two
> have tried, and none has been allowed.

*Shows:* three figures at one size — the mints, the accounts that have asked, the accounts an
issuer has approved — over the scan's own total line. **`2 asked` and `0 approved` are the same
size**: somebody tried and still nobody is through, and that is the whole scene. **The scene that has to come second.**
Opening on the account alone invites *"that is just Token-2022"* — and it would be right. This says
so first, and turns it into the finding: the capability is everywhere and nobody is through.

### 3 — Confide

> That is what Confide is for: confidential delivery-versus-payment for tokenized stocks. It builds
> the zero-knowledge proofs the chain will not assemble for you, and lets each side read the other's
> amount before signing. Nobody stands in the middle.

*Shows:* the name, and a plain definition under it. **The one place the narration reads the screen,
and the second deliberate exception in the film.** Checked across all ten scenes on 2026-09-23: the
words *confidential*, *delivery-versus-payment* and *stablecoin* were spoken **nowhere in 170
seconds**. The mechanism was fully narrated and the category was not, so a judge listening while
skimming heard a good explanation of a thing that was never named — the name lived only in a 19px
corner mark. It is said once, here, where the screen already says it, and the plain-English sentence
that follows earns it. **The hero carried "issuance first — the only
trade the gate lets through", and that was written when it sat after the gate scene.** Here the
viewer has not met the gate yet, so the sentence would be about something they have not been shown.
The ordering claim moves to scene 7, where it is earned.

### 4 — the trade

> Two holders exchange a position for stablecoins in a single transaction. Either both sides settle
> or neither does. Nobody watching learns the size, the price it implies, or that either of them held
> anything.

*Shows:* the delivery-versus-payment diagram, both sides moving, sealed, and the four zeroes the
chain shows everyone else. **After the name, never before it** — the correction from 09-22 stands:
this is Confide's own trade, and a picture of the product before the product is named leaves a
viewer asking whose it is.

### 5 — why the door is shut

> Token-2022 gives the issuer plenty: freeze a transfer, seize a holder's tokens, run their own
> code. Its confidential-transfer extension has exactly one auditor key, and that key reads
> everybody or nobody. No setting shows one balance to one regulator — so all left it empty.

*Shows:* the slot scan, the empty auditor column. **Rewritten 2026-09-23, for two reasons.** It
opened on *"Not an oversight"* — an oversight of what? The thing it referred back to was three
scenes earlier, and the viewer had been shown the product and a trade since. And *"the one thing
they left off reads everyone's balance"* parses as though the thing does the reading, which is true
only if it is set. **The founder dropped "1,992" from the last clause when recording on 2026-09-23**, and the script
follows the delivered audio rather than the other way round — but note what it costs: *"so all left
it empty"* leaves **all** with nothing to point at in the voice. The number is still on the card
and in the headline, so a watching judge has it; a listening one does not. *"So every issuer left
it empty"* would carry the antecedent without a number to read aloud.

**This is also the only place the technology can be named.** Checked across the
whole script on 2026-09-23: *Token-2022* and *confidential transfer* were spoken **nowhere in the
film** — and the strongest measured fact in this submission is a Token-2022 fact. A Solana judge
who never hears the name cannot place the work, and the mints scene is where the name is earned. **The diagnosis, and it answers the question
scene 2 raises** — why would three unrelated issuers all decline the same thing?

### 6 — why now

> Last week the SEC gave tokenized stock five years of relief in the United States. Then you read
> the conditions: trading only through an automated market maker, where the size and direction of
> every trade you make is published within ten minutes. A desk cannot go there.

*Shows:* the order's condition at reading size, with the cap beside it and `sec.gov` on the badge.
**This used to open the film.** It is the strongest external fact available and the wrong thing to
lead with: it is about the world rather than about what is on screen, it costs the most vocabulary,
and the order concerns US NMS stock while the 1,992 measured above are issued outside it. As the
sixth scene it answers *why now* for a viewer who already knows what *this* is.

### 7 — so the first trade is an issuance

> So the first trade through that door is not a swap between two holders. It is an issuance —
> because the issuer is the one who can open the account.

*Shows:* the sentence, alone — **not the title card.** This scene borrowed the hero renderer, which
always prints the project's name, so "Confide" appeared a second time forty-five seconds in and the
film looked like it had restarted.

### 8 — the gate, both ways

> An issuer allocates twenty thousand shares. Sent before the issuer signed for the account, the
> chain refuses it. One instruction later, the same transaction settles.

*Shows:* refused and settled side by side, with `swap-status.sh`'s own two error lines under
them — `{'Custom': 24}  (expected)` and `none`. The size in the title is read out of the record of
the run, not typed. **The gate had
been described all film and never once shown stopping anything.** Both transactions are on chain
([`../docs/cwf-2026/ISSUANCE-RUNS.md`](../docs/cwf-2026/ISSUANCE-RUNS.md)).

### 9 — why not just use an exchange

> And you cannot do this on an exchange. The exemption covers trading executed by an automated
> market maker, where every fill's size goes on a public tape within ten minutes. That is the
> venue, not one pool.

*Shows:* **the line opened *"You cannot do this on one"*, and "one" was an exchange the sentence
had not mentioned yet** — the same referent problem as scenes 5 and 10, found while fixing those.
The reserve as **R**, the fill as **q**, the state after as **R − q**, on a dashed card
that says it is arithmetic and not an observed pool. **No pool is invented** — a drawn number would
sit in the same type as the measured ones and a judge could not tell them apart. **The
regulatory leg leads.** Blockworks measured that over 60% of Backpack's Solana volume goes through
proprietary AMMs, which quote from external stock data rather than from reserves — so the
structural leg lands on the minority case
([`../docs/cwf-2026/THIRD-PARTY-MEASUREMENTS.md`](../docs/cwf-2026/THIRD-PARTY-MEASUREMENTS.md)).

### 10 — what I got wrong, and what you can run

> One thing I got wrong: a review found the check I called the safety step was signing something it
> had never compared. It is fixed, and every review is committed. This is all devnet, and you can
> run it yourself: one command opens a confidential position on an issuer gated exactly as all
> 1,992 are.

*Shows:* the assumption that failed beside the repair, the command, and the line of
`scripts/swap-sign.sh` that performs it. **The ending changed on 2026-09-23.** It closed on *"nobody
outside this repository has used any of this"* — true, disclosed, and the last thing a judge heard
before writing their note. *"One of those checks"* also referred to a set of checks the film had
never established, and *"compares the two"* to two things it had never named.

**The honesty stays and moves off the end.** The correction is still the first half of the scene,
and the traction disclosure is now **on the screen**, in the card, where it is read rather than
left ringing: the voice invites, the screen discloses. The film ends on the one thing a judge can
do without asking anybody: `./scripts/testbed-join.sh`, on a standing devnet issuer whose approval
key is published and whose gate is shut exactly as it is on all 1,992. **Ending on a defect I did not find myself**, and on the
weakest fact, which is the first one a judge checks.

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
