# The submission presentation — structure and script

**Rough cut. Not for publication.** Its only job is to find out whether the story holds before the
week the video has to exist. If a scene cannot be shown with something that already runs, the
problem is the story, not the footage — and this is the cheap moment to learn that.

Target **150 s**, against a 2–3 minute allowance, so there is room to slow down rather than cut.
Pacing budget is words over clip length minus 0.6 s of tail, the convention
[`segments/LINES.md`](segments/LINES.md) already uses. Anything over 180 wpm is reading without
pauses.

**This is not the weekly check-in.** That is one minute, Colosseum asks for it, and the first
opens 09-18. See [`../docs/27-DAYS.md`](../docs/27-DAYS.md).

## The shape

Four of the seven judging criteria are non-engineering and get read first, so the order is: **the
market before the mechanism, the citation before the claim, and the gaps out loud before anyone
has to find them.** Confide's mechanism is good and it is scene 4 of 7, not scene 1.

| | scene | seconds | words | pace | what it shows |
|---|---|---|---|---|---|
| 1 | the fact | 17 | 38 | 139 | the 1,869 count, live from mainnet |
| 2 | whose money | 25 | 56 | 138 | the 19 Kamino reserves, LTVs and balances |
| 3 | the refusal | 22 | 48 | 135 | `constraints.rs` on screen, the four conditions |
| 4 | what runs | 30 | 66 | 135 | the floor proof accepted by Solana's ZK program; the seizure on devnet |
| 5 | what does not | 27 | 61 | 139 | the three missing pieces, as text |
| 6 | what you can run | 18 | 39 | 134 | `./scripts/packet.sh SPCX.US` and its output |
| 7 | the close | 12 | 26 | 137 | traction, stated |
| | | **151 s** | **334** | | |

## The script

### 1 — the fact · 18 s · 40 words

> One thousand eight hundred and sixty-nine tokenized stocks trade on Solana today. Every one of
> them has confidential transfers switched on. Every one has the auditor key empty. The privacy is
> already shipped, and nobody can use it.

*Shows:* the mint scan finishing. This is the finding the project has had from the start, and it is
still the right opening because it is checkable in one RPC call.

### 2 — whose money · 28 s · 63 words

> Kamino lends against nineteen of them right now. Real markets — loan-to-value from thirty to
> seventy-three percent, picked by the people who own those markets. Thirteen hold more than a seed.
> Four are being borrowed against today. SpaceX has a reserve: forty percent, fifteen thousand cap.
> And every position in every one of them is public.

*Shows:* the reserve table. **This scene is why the project is worth looking at**, and it is not
about Confide at all. Someone else already underwrote this asset class with their own money; the
privacy question arrives on top of a market that exists.

### 3 — the refusal · 26 s · 58 words

> Kamino is not ignoring confidentiality. Its program names the confidential-transfer extensions,
> and requires them to be switched off before a deposit will land. That is not an oversight. A
> reserve that cannot read a balance cannot mark a position, and refusing what you cannot value is
> correct underwriting.

*Shows:* `constraints.rs` lines 187 and 201, then `lending_checks.rs:186` passing the depositor's
own account. **Conceding that the refusal is correct is what makes the rest credible** — the
alternative framing, that a protocol overlooked something, is both wrong and the kind of wrong a
judge who reads code will catch.

### 4 — what runs · 30 s · 68 words

> So prove the thing a lender needs without revealing the balance. A floor — this account holds at
> least X — computed over the account's own on-chain ciphertext, and checked by Solana's ZK
> program, not by us. Then custody that outlives the borrower: the escrow belongs to a program, and
> origination refuses to record anything until it verifies that. Both run, end to end, on devnet.

*Shows:* `prove-collateral.sh` output with the ZK program's acceptance, then the seizure on devnet
with the explorer link. **Nothing here is a diagram of a thing that might work.**

### 5 — what does not · 24 s · 54 words

> Three pieces are missing, and they are named rather than hidden. A floor proved once is a floor at
> one moment — re-proving is not built. The seizure has to sit inside Kamino's liquidation path, not
> beside it — not built. And the issuer must approve each escrow, because these mints do not
> auto-approve. That one is nobody's decision but theirs.

*Shows:* plain text, three lines. **This scene exists because the packet has it and the video must
not be the softer version of the document.** It is also the scene most likely to be cut for time by
someone who has forgotten why it is there.

### 6 — what you can run · 16 s · 36 words

> One command builds the whole admission packet for any of the eighteen hundred, from live chain
> data. Every authority and who holds it. The oracle path. The numbers someone already chose. Every
> unknown capped at zero instead of guessed.

*Shows:* `./scripts/packet.sh SPCX.US` running, then the generated document scrolling.

### 7 — the close · 10 s · 22 words

> Traction is zero. Nobody outside this repository has used any of it. What exists is a mechanism
> that runs, and a gap you can check yourself.

*Shows:* the page URL. **Ending on the weakest fact is deliberate** — it is the first thing a judge
will test, and saying it first is worth more than the twenty seconds it costs.

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
