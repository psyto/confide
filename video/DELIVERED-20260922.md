# What the published Stocklana cut says — frozen 2026-09-22

**`Confide_Stocklana_20260922.mp4`.** The narration the voice was given, copied out of
[`CWF-PRESENTATION.md`](CWF-PRESENTATION.md) at the commit it was recorded from.

**It exists because the script moves and the delivered file does not.** One file cannot be both what
the published cut says and what the next cut should say; the moment those diverge the repository
loses the first. `scripts/video-chapters.sh` takes its TITLES from here, so the chapters in
[`../_submission/youtube.md`](../_submission/youtube.md) describe the file a judge opens.

**Frozen.** Do not edit it to match a new script. When the cut is re-recorded, replace this file with
the narration that was actually delivered, the same way — which is what happened to its predecessor,
`DELIVERED-20260920.md`, on the day this one was cut.

## The script

### 1 — the tape

> Last week the SEC gave tokenized stock five years of relief. Then you read the conditions. It
> only covers trading through an automated market maker — where every trade you make is published.
> The size. The direction. Within ten minutes. Nobody attacked anything. That is the deal.

*Shows:* the order's condition at reading size, wrapped, with the cap beside it and `sec.gov` on
the badge. **Relief, then the catch — and the numbers stay on the card.** The first version read
out the conditions in order, which is accurate and is not a story: a viewer who does not already
know what a TSV is has nothing to hold on to. The voice carries the turn and the screen carries
0.25% and ten minutes, so neither has to do both. **Two scenes became one.** The first cut spent thirty seconds on regulation text before
anything moved, in a monospace pane that ran off the right edge mid-word — a document rendered as
if it were terminal output. The rule earns one scene, not two.

### 2 — the block · +2 s silence

> Block trades have always settled away from the tape.
>
> The SEC has now built the tape for tokenized equity. Nobody has built the block. Confide has.

*Shows:* the name, and under it what this actually is — *tokenized stock against a stablecoin, one
transaction, neither amount published.* **That sentence was in the published cut and the
restructure dropped it**, so for the first fifty seconds the only statement of what Confide does
was the word *block*, which is trade jargon, over a diagram captioned *cash*. The narration says
the gap and the screen says what fills it, which is the rule this file already has.
**This is also where the product is named, so it comes before the picture of it** — and the voice
now says the name here rather than leaving it to the screen. *"Nobody has built the block. Confide
has."* is two words added to make the answer land while the name is the largest thing on the frame;
a viewer listening without watching used to hear the gap stated and the name withheld for another
fourteen seconds. The first cut put the diagram here and the title card after — so
*"nobody has built the block"* landed on a viewer who had just watched one settle, and the name
arrived third. The gap has to be open before anything fills it.

### 3 — the trade

> So here is one. Confide builds the proofs the chain will not assemble for you, and lets each side
> check the other before signing — with nobody in the middle. Fifty thousand tokenized shares
> against eight point seven five million in stablecoin, in a single transaction.

*Shows:* the sentence that says what Confide does — **spoken and on screen, which the rule above
otherwise forbids** — over the delivery-versus-payment diagram, both sides moving, sealed, and the
four zeroes the chain shows everyone else. One exception in 177 seconds, because a judge skimming
with the sound off would otherwise take away the outcome and never the product. **This is where the film says what Confide does, and it used to say it
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

> The proofs do not fit in one transaction. On a mint that charges a fee there are five, and one is
> too large to send at all — it goes on chain in a record account first. Four files, two machines,
> neither side ever holding the other's key.

*Shows:* the four commands, then the settled transaction and four balances reading `0`. **The
product arrives ninety seconds in, as the answer to a question the viewer already has.**

### 10 — what I got wrong, and what nobody has used

> I called that last step the safety step. A review found it was signing something it had never
> looked at. The fix compares the two, byte for byte — and caught a bug of mine on its first run.
> Nobody outside this repository has used any of this.

*Shows:* the check refusing, then passing. **Ending on a defect I did not find myself.** Traction is
the weakest fact and the first a judge checks, so it costs five seconds and buys the rest.

