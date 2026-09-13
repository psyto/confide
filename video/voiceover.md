# Voiceover — confide.mp4 (1:52)

Timecodes are measured, not estimated: `demo.html` logs each scene's start, and the run is
reproducible with `npm run record`. Word budgets assume ~150 wpm and deliberately fill about 80% of
each scene, so the delivery has room to breathe and the on-screen text has a beat to land.

**The narration does not read the screen.** Everything visible is already written; the voice is
there for the part the picture cannot carry — why it matters, and what just happened.

---

### 0:00 – 0:09 · title

> If you hold tokenized stocks on Solana, everyone can see your position.
> Nobody attacked anything. The chain simply publishes it.

*17 words · flat, unhurried. The second sentence is the one that should land — this is not a hack,
it is the default.*

### 0:09 – 0:22 · the position climbing, eyes accumulating

> Here is a fund buying NVIDIA through one quarter.
> Every purchase readable the moment it settles — not after the position is built, but while it is
> still being built.

*31 words · let the counter climb under "every purchase". Pause before "while it is still being
built."*

### 0:22 – 0:44 · four mints, two issuers, auditor key EMPTY

> Solana already shipped the fix.
> Every tokenized stock here has confidential transfers switched on — eighteen hundred and sixty-nine
> of them, from two issuers with nothing to do with each other.
> And every single one leaves the auditor key empty, because the only key on offer reads everyone's
> everything, forever.

*49 words · this is the reveal, and the longest single stretch. "Two issuers with nothing to do with
each other" is the line that does the work — one company being cautious is a story, two arriving
independently at the same dead end is not. Take the pause before it.*

**This is the only block that changed after the first recording.** Everything else is unchanged, so
only `03-empty-slot` needs a new take.

### 0:44 – 1:00 · four columns — the market, a lender, your auditor, you

> Confide fills that slot properly.
> The market sees nothing. A lender learns one bit: the collateral covers the loan.
> Your auditor sees the position in full.
> You choose who, how much, and when.

*36 words · land one clause per column as it appears. The last line is the thesis — slow down.*

### 1:00 – 1:19 · five benefits

> Your position stops being public, and you can still prove what you need to.
> Last quarter's number cannot be tidied afterwards — it is sealed on the reporting date and opened
> by people you do not control.
> A stock split does not corrupt what you already disclosed.

*46 words · the longest stretch. Do not rush to cover all five; three of them is enough.*

### 1:19 – 1:29 · a live devnet account

> This is a real account, right now.
> The chain says it holds nothing.
> It holds a hundred and seventy-three thousand shares.

*22 words · leave the gap before the last line. That contrast is the whole product.*

### 1:29 – 1:43 · both proofs accepted

> And this is the lender's check, running on Solana's zero-knowledge program.
> Two proofs, both accepted — the chain confirmed the collateral covers the loan without ever being
> told what is in the account.

*35 words · "without ever being told" is the point; everything before it is setup.*

### 1:43 – 1:52 · close

> Your position is yours.
> And you can still prove what you must.
> Try it yourself — no wallet, no install.

*21 words · full stops between all three. Let the URL sit on screen after the voice ends.*

---

## Pace

Settled. The first cut was sized before the narration existed and ran 83.1s against 101.9s of
voice — two scenes needed over 200 wpm to fit, which is reading without pauses. The scenes are now
cut from the recorded audio instead: every one covers its line with about 0.6s of tail.

If you re-record a line longer than before, raise that scene's `hold` in `record.js` rather than
speeding up the delivery. One `hold` moves one scene.

## If you re-record

Scene lengths are the `hold` values in `record.js`. Raising one lengthens that scene without
touching the others, so a line that needs air can have it without slowing the whole cut. The scene
boundaries above come from the `CONFIDE_SCENE` console lines the page emits during a run — re-read
them after any change rather than assuming these still hold.

## What the narration must not claim

The script says a lender *checks* collateral, never that you can *borrow*. Seizure on default does
not exist in this build, so borrowing does not either — the earlier cut of this video said "you can
still borrow against it" and that was wrong.
