# Voiceover — confide.mp4 (83.1s)

Timecodes are measured, not estimated: `demo.html` logs each scene's start, and the run is
reproducible with `npm run record`. Word budgets assume ~150 wpm and deliberately fill about 80% of
each scene, so the delivery has room to breathe and the on-screen text has a beat to land.

**The narration does not read the screen.** Everything visible is already written; the voice is
there for the part the picture cannot carry — why it matters, and what just happened.

---

### 0:00 – 0:07 · title

> If you hold tokenized stocks on Solana, everyone can see your position.
> Nobody attacked anything. The chain simply publishes it.

*17 words · flat, unhurried. The second sentence is the one that should land — this is not a hack,
it is the default.*

### 0:07 – 0:17 · the position climbing, eyes accumulating

> Here is a fund buying NVIDIA through one quarter.
> Every purchase readable the moment it settles — not after the position is built, but while it is
> still being built.

*31 words · let the counter climb under "every purchase". Pause before "while it is still being
built."*

### 0:17 – 0:28 · four mints, auditor key EMPTY

> Solana already shipped the fix.
> All seven hundred and thirty-two tokenized stocks have confidential transfers switched on — and
> every one of them leaves the auditor key empty.
> The only key on offer reads everyone's everything, forever.

*38 words · slightly faster, this is the reveal. "Forever" takes the weight.*

### 0:28 – 0:39 · four columns — the market, a lender, your auditor, you

> Confide fills that slot properly.
> The market sees nothing. A lender learns one bit: the collateral covers the loan.
> Your auditor sees the position in full.
> You choose who, how much, and when.

*36 words · land one clause per column as it appears. The last line is the thesis — slow down.*

### 0:39 – 0:53 · five benefits

> Your position stops being public, and you can still prove what you need to.
> Last quarter's number cannot be tidied afterwards — it is sealed on the reporting date and opened
> by people you do not control.
> A stock split does not corrupt what you already disclosed.

*46 words · the longest stretch. Do not rush to cover all five; three of them is enough.*

### 0:53 – 1:03 · a live devnet account

> This is a real account, right now.
> The chain says it holds nothing.
> It holds a hundred and seventy-three thousand shares.

*22 words · leave the gap before the last line. That contrast is the whole product.*

### 1:03 – 1:15 · both proofs accepted

> And this is the lender's check, running on Solana's zero-knowledge program.
> Two proofs, both accepted — the chain confirmed the collateral covers the loan without ever being
> told what is in the account.

*35 words · "without ever being told" is the point; everything before it is setup.*

### 1:15 – 1:23 · close

> Your position is yours.
> And you can still prove what you must.
> Try it yourself — no wallet, no install.

*21 words · full stops between all three. Let the URL sit on screen after the voice ends.*

---

## Pace

**241 words over 83.1 seconds ≈ 174 wpm overall — but the average hides the problem.** Per segment:

| | wpm | |
|---|---|---|
| 0:00 title | 160 | fine |
| 0:07 leak | 180 | brisk |
| **0:17 empty slot** | **207** | **too fast to read unhurried** |
| 0:28 four views | 183 | brisk |
| **0:39 benefits** | **205** | **too fast to read unhurried** |
| 0:52 live account | 126 | comfortable |
| 1:02 proofs | 165 | good |
| 1:14 close | 142 | good |

Unhurried delivery is 140–165 wpm. Two segments sit above 200, which means reading them without
pauses. Two ways out: shorten those lines, or give the scenes room — `hold` in `record.js`
lengthens one scene without moving the others, and +2.8s on the slot and +3.4s on the benefits
brings both to about 165, taking the cut to roughly 89 seconds. If you would rather cut than
re-record, do it in this order:

1. the third sentence of 0:17 ("The only key on offer…") — the screen already says it
2. the second sentence of 0:39 — the longest, and the list is visible anyway
3. "in full" at 0:28

**Do not cut 0:53 or 1:03.** Those two carry the demonstration; everything before them is argument.

## If you re-record

Scene lengths are the `hold` values in `record.js`. Raising one lengthens that scene without
touching the others, so a line that needs air can have it without slowing the whole cut. The scene
boundaries above come from the `CONFIDE_SCENE` console lines the page emits during a run — re-read
them after any change rather than assuming these still hold.

## What the narration must not claim

The script says a lender *checks* collateral, never that you can *borrow*. Seizure on default does
not exist in this build, so borrowing does not either — the earlier cut of this video said "you can
still borrow against it" and that was wrong.
