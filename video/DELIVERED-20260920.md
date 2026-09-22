# What the published Stocklana cut actually says — frozen 2026-09-22

**`Confide_Stocklana_20260920.mp4`, published as `gilIzns5joM`.** This is the narration the voice was
given, copied out of [`CWF-PRESENTATION.md`](CWF-PRESENTATION.md) at the commit before that file was
restructured on 2026-09-22.

**It exists because the script moved and the video did not.** Until 09-22 there was one file serving
two jobs — what the published cut says, and what the next cut should say — and the moment those
diverged the repository lost any record of the first. `scripts/video-chapters.sh` reads the delivered
file's own scene boundaries and takes the TITLES from here, so the chapters in
[`../_submission/youtube.md`](../_submission/youtube.md) keep describing the file a judge can open.

**Frozen.** Do not edit it to match a new script. When the cut is re-recorded, replace this file with
the narration that was actually delivered, the same way.

**One figure in it is already stale by design:** scene 6 says *"three hundred and twenty-nine
thousand accounts"*, measured 2026-09-17 and 465,520 four days later. The documents were all
updated; the video was deliberately not, because it is a dated artifact and the voice is the
founder's to regenerate. See [`../STATUS.md`](../STATUS.md).

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


