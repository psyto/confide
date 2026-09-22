# CWF submission form — paste text, field by field

**Every field below is written to be pasted.** Character limits are the form's own and are checked
by `./scripts/cwf-form.sh`, which counts them rather than trusting a number typed here.

**The form currently holds a stale Brief description.** As found 2026-09-21 it said *"All 1,869
tokenized stocks … two issuers"*. 1,869 is the count from **before a third issuer existed** and it
was sitting in a **Public** field — the same figure that rotted in Stocklana's short description
(`_submission/short-alternatives.txt`). It also pitched the disclosure product, which
[`GTM.md`](../docs/cwf-2026/GTM.md) decided not to lead with, and does not mention the swap at all.

---

## Project name · Public

```
Confide
```

## Brief description · Public · ≤500

```
Two parties settle tokenized stock against a stablecoin in one Solana transaction, and neither publishes what moved. Delivery versus payment with nobody in the middle: the transaction is the clearing house. Every tokenized stock on Solana already ships confidential balances — all 1,992, three unrelated issuers, auditor slot empty on every one. So I counted the accounts actually using it. Across 465,520 live accounts on Apple, NVIDIA, SpaceX, Anthropic and AMC: zero. Shipped, gated, unused.
```

## Project website · Public

```
https://psyto.github.io/confide/
```

## What are you building, and who is it for? · ≤1000

```
A confidential settlement layer for tokenized equity. Two holders agree a price off chain; Confide builds the zero-knowledge proofs Solana will not assemble, lets each side decrypt the other's amount out of the verified proof context before signing, and settles both legs in one transaction. Either both move or neither does.

Devnet today: 50,000 shares against $8,750,000, two signatures. All four accounts are ordinary associated token accounts and all four still read a public balance of 0. A second trade settles against a mint shaped like PayPal's PYUSD, which charges a fee — that leg needs a different instruction, five proofs instead of three, and one proof too large to fit a transaction, staged through a record account. Two rule sets, settled atomically.

For a desk accumulating or unwinding size: every on-chain purchase assembles the position in public and moves the price against it. Then securities lending, where lending your book is how you publish it.
```

## Why did you decide to build this, and why build it now? · ≤1000

```
I set out to build a loan against tokenized stock and hit one wall every time. Collateral needs a third party to hold it, that party needs a confidential account, and autoApproveNewAccounts is false on all 1,992 mints. No issuer will approve one. A trade needs no third party, because a Solana transaction cannot half-happen. That was the decision.

Why now is not my timing. On 17 September the SEC granted two five-year exemptions for tokenized NMS stock. The relief covers AMM-executed trading only; a venue must publish every fill's price, size, time and direction within ten minutes, and a Tier 1 name is capped at 0.25% of daily volume. The sanctioned venue publishes the size by regulation, and size cannot go there anyway.

A pool could never be confidential: its reserves are public and a trade moves them by exactly the traded amount. That was my structural finding. It is now a written condition of the only US venue that may legally operate. The lit venue exists. Nobody built the block.
```

## How does your product use these chains? · ≤500

```
Solana only. No bridge, no second chain.

Token-2022 confidential transfers hold the position; the trade is two of its instructions in one transaction, with Solana's atomicity where a clearing house would be. The proofs are verified by Solana's own ZK ElGamal Proof Program into context accounts and cited by address, so nobody trusts our arithmetic. One proof exceeds the 1232-byte transaction limit and is staged through spl-record. Mint findings read from mainnet-beta; trades run on devnet.
```

## What technologies are you using or integrating with? · ≤500

```
Rust; Solana native programs, no Anchor.
- Token-2022 confidential transfers
- Solana's ZK ElGamal Proof Program - equality, validity and range proofs into context accounts
- spl-record - stages the oversized proof
- Confide's seizure program, native, on devnet
- Kamino Lend - read-only at a pinned commit, no contact
- aperture-core, aperture-receipts - my earlier work, disclosed
- Solana CLI, cargo, Python, Puppeteer, ffmpeg
- AI: Claude to build, Codex to review; both logged in docs/reviews/
```

**Every limit here was found by hitting it, not read off the form.** The technologies field shows
no limit and took exactly 500 characters before cutting mid-word, so the first list — 1,467
characters — went in as a third of itself. **Any field whose limit this file does not state has not
been tested yet.** When one refuses text, measure what it accepted and put the number in the
heading; `./scripts/cwf-form.sh` enforces whatever the heading says.

**The limit is 500 and the form does not say so.** The founder hit it: the first version was 1,467 characters and the field accepted exactly 500 before cutting mid-word. Measured from what it took, not guessed.

**The form asks for AI tools by name.** Answering straight costs nothing and the evidence is
already committed: every review payload sits in `docs/reviews/payloads/` beside its result.

## Which chains · select

```
Solana   (only — no other chain is integrated)
```

## Category · Public

```
Real World Assets (RWA)
```

**Kept after the pivot, asked by the founder 2026-09-21.** The turn from a loan to delivery versus
payment changed the mechanism, not the asset class. Confide exists because tokenized equity exists:
the finding is *1,992 tokenized-equity mints, all gated*, which is a fact about this asset on this
chain and not about lending or about privacy in general. The loan and the swap were always two ways
at the same asset.

Three reasons it is also the better place to be judged from:

- **The measurement is unique here.** Nobody else has counted the accounts. Under a DeFi or privacy
  heading, confidential transfers are a well-worn topic and this becomes one entry among many.
- **The SEC's 17 September exemption is an RWA event** — it is about tokenized NMS stock
  specifically. Sitting in RWA puts this beside the year's largest development in its own category
  rather than adjacent to it.
- **A trading heading would invite the wrong comparison.** Confide is deliberately not a venue, and
  `docs/SEC-EXEMPTION.md` records why not building matching is what keeps it clear of Rule 3b-16.
  Being judged against order books and AMMs is being judged as the thing it refuses to be.

**If the category list has an option this file has not seen, that is worth re-asking** — the
options were never pasted, so this is reasoning about the one that is selected rather than a
comparison against the full list.

## Is your project a mobile-focused dApp?

```
No
```

## Where is your team primarily based? · Public

```
Japan
```

## Team Telegram contact · founder enters directly — NOT recorded here

**Deliberately absent.** The form does not mark this field Public, and it is used for prize
distribution and accelerator interviews. **This repository is public**, so writing the handle here
would expose it more widely than the form does. The founder holds it and types it in; what is
recorded is that the field is filled, never the value.

## Accelerator application · founder decided to apply, 2026-09-21

**Include it.** The application opens fields this file has not seen — paste them and they get the
same treatment as the rest: written here, counted against the form's own limits, and checked for
figures the chain does not report.

## Notes for judges — anyone not listed who did meaningful work · ≤600

```
No. Confide is one person's work. Code review during the window was done by OpenAI's Codex against payloads committed alongside the results in docs/reviews/, and the drafting assistant was Anthropic's Claude; every finding either produced was verified against the real files before being acted on, and several were rejected as wrong. The narration is the founder's own voice. No collaborator, contractor or teammate contributed.
```

## Anything else judges should know · ≤500

```
Pre-existing work, disclosed: Confide depends on psyto/aperture (Apache-2.0, public) at tag v0.5.1 — aperture-core as an unmodified git dependency, and aperture-receipts as a devnet program Confide calls rather than compiles. Everything else here is new.

This repository predates the CWF window. Work inside it is cwf-2026-baseline..HEAD, from 765b8bc — see docs/WORK-WINDOW.md.

Also submitted to Stocklana on 2026-09-15, from the same repository.

Traction is zero.
```

---

# Media and code

## Project logo or graphic · Public · required

```
_submission/graphic.jpg   (1024x1024, 123 KB — ./scripts/graphic.sh)
```

From `web/confide-solana-dvp-graphic.png`, commissioned by the founder 2026-09-21.

**Fourth attempt, and the first where the differentiator is the strongest thing in the frame.**

| | why it was dropped |
|---|---|
| a crop of the video's own poster frame | honest, and at 360px a panel of small terminal type is texture |
| a page built in this repository | legible, and indistinguishable from any other RWA project |
| a light commissioned draft | good eye-catch; its only signal for *confidential* was a purple ellipsis that read as "loading" |
| **this one** | **an opaque lens sits in the middle of the exchange — something is visibly behind it and unreadable, which is exactly what the product does** |

The wordmark survives the downscale, the two arrows read as an exchange rather than collapsing, and
the purple-to-green gradient is Solana's palette without borrowing its mark.

**JPEG, not a quantised PNG.** The light draft was flat enough to take 192 colours cleanly; this is
a dark gradient and quantising it speckles the background even at 256 colours with dithering. 123 KB
against 475 KB, and no banding. The format follows the image.

**It claims nothing**, which is a feature: no figure, no number, nothing to defend. This repository
argues its numbers are checkable, and an image that overstated would cost more than it won.

**`web/confide-dvp-public-graphic.png` is the light draft**, kept as the rejected alternative with
its reason above rather than deleted — the same treatment `_submission/short-alternatives.txt` gets.
Neither file is published: `scripts/publish-site.sh` names what it serves.

**Check any replacement the same way:** `./scripts/graphic.sh`, then look at `/tmp/graphic-card.png`.
A built version once had its exchange mark collapse into a not-equals sign at 360px, which made the
headline say the opposite of the claim. Only looking catches that.

## GitHub link · Public · required

```
https://github.com/psyto/confide
```

## Important context about the repo · ≤500

```
One repository, and it carries more than this submission.

It predates this contest. Work inside the window is cwf-2026-baseline..HEAD, from 765b8bc, committed 5h22m before it opened; docs/WORK-WINDOW.md records the boundary and the commands that establish it. It was also submitted to Stocklana on 2026-09-15.

It holds a collateral and seizure half the swap does not depend on, and aperture-core and aperture-receipts, my own earlier work used as a dependency and a deployed program.
```

## Demo video · ≤3 min · required

```
NOT YET MADE — see below. Do not paste the 2:22 presentation here.
```

## Live product link

```
https://psyto.github.io/confide/
```

## Access instructions

```
Nothing to log into. The page reads mainnet in your browser and decodes the devnet trades - no wallet, no account, no key.

To hold a confidential position yourself, on a devnet issuer whose gate is shut exactly as all 1,992 real ones are and whose approval key is published:

git clone https://github.com/psyto/confide && ./scripts/testbed-join.sh

And with a counterparty, to do the trade itself - four commands, four files, and each of you decrypts the other's amount before signing:

swap-offer.sh -> swap-accept.sh -> swap-settle.sh -> swap-sign.sh   (docs/TESTBED.md)

Needs the Solana CLI, a Rust toolchain and a little devnet SOL. The script tries the airdrop and tells you what to do when it is throttled, which it usually is.
```

## Pitch video · Public · ≤2 min · required

```
DOES NOT EXIST — see below.
```

## X profile · Public

```
@psyto
```

---

## The two required things that do not exist

**The form asks for two videos and they are different.** Reading its own words:

| | what it asks for |
|---|---|
| **Demo** | *"Should show the live product, not a slide deck, not a code walkthrough."* Up to 3 min |
| **Pitch** | *"introduce yourselves, tell us what you're building, and tell us why you're the people to build it."* Up to 2 min, **Public** |

**`Confide_Stocklana_20260920.mp4` is neither, and pasting it into Demo is a risk worth naming.**
It is 2:22 and it does carry real footage — the account scan running, the mint configuration, the
balances reading zero. But scenes 2, 3 and 8 are diagrams, and a judge applying *"not a slide
deck"* strictly has grounds. It was built to win an argument, not to show a product working.

**The demo that should exist**, and the material for it is already here: `./scripts/swap-e2e.sh`
running end to end in a terminal, then the same signature decoded at `psyto.github.io/confide` in a
browser. No narration needed. That is the live product doing the thing, and it answers *Product +
Execution* and *Functionality* directly rather than by argument.

**The pitch video has no substitute in this repository.** It is the founder on camera for two
minutes, it is **Public**, and criterion 5 is *Founder Communication* — this is the field that
criterion reads. Nothing here can stand in for it.

**Both are founder work.** Recording and voice are founder-only.

---

# Accelerator application

**Private to organizers and the Colosseum team.** Which is a reason to be more exact, not less: a
field nobody outside sees is where an unverifiable claim survives longest.

**Four of these are founder facts and are marked as such.** The agent does not know whether an
entity exists or whether the work was full time, and inventing either here would be the one kind of
error the rest of this repository is built to prevent.

## How do you know people actually need, or will need this product? · ≤1000

```
Honestly: I do not know yet, and the measurements I have say something narrower than "people want this".

What I can show. Kamino runs 19 live reserves in tokenized equity: $23.2m deposited, $84.0m of borrowing its own market owners authorised, and $0 of that reachable by a holder who will not publish what they hold — the deposit path refuses an account carrying confidential value (constraints.rs:187). Money already committed, under a constraint nobody chose.

What it does not show. 465,520 live accounts and zero confidential proves the feature is unused. It does not prove anyone wants it: the issuer must sign for each account and none has, so nobody has had the chance to want it.

What would settle it. Somebody outside my repository opening a confidential position on the devnet issuer whose key I published, or a desk saying what it would pay to move size unpublished. Neither has happened. Until one does this is an argument, not evidence.
```

## How far along are you? Do you have users? · ≤1000

```
No users. No pilot, no design partner, no letter of intent, no issuer approached. Traction is zero and I would rather say it than have you find it.

What runs. A confidential stock-for-stablecoin swap settles on devnet in one transaction: 50,000 shares against $8,750,000, two signatures, all four accounts still reporting a public balance of 0. A second settles against a mint shaped like PYUSD, which charges a fee — that leg needs a different instruction, five proofs not three, and one proof too large to fit a transaction, staged through a record account. The collateral half runs too: a floor proved over an escrow's own ciphertext, a default settled without the borrower.

104 tests. Every figure is read off the chain by a script here, and ./scripts/healthcheck.sh re-checks each claim against devnet, because judging runs weeks and devnet resets.

Nothing is on mainnet. Nobody outside the repository has run any of it.
```

## Who else is building in this space, and what are they getting wrong? · ≤1000

```
Mostly they are not getting it wrong, and I would rather say so than manufacture a villain.

Backed, Backpack and PreStocks ship tokenized equity on Token-2022 with confidential transfers on — 1,992 mints — and all leave autoApproveNewAccounts false. Not an oversight: turning it on lets anyone open an account they cannot see into.

Kamino refuses confidential collateral and is right to: a lender who cannot read a balance cannot price it. Their program requires the extensions inactive at deposit. Correct underwriting.

What is wrong is upstream of them all. Token-2022 offers one disclosure model: a single auditor key that decrypts everything, for everyone, forever — or null. Fill it and every holder is permanently readable by one party; leave it null and nobody can prove anything to anyone. Every issuer picked null. Every decision downstream is locally correct inside a design with no third option.

Confide builds the third option: disclosure scoped to a recipient and a purpose.
```

## How do you make money, or how do you plan to? · ≤500

```
No revenue, no price tested. Three candidates, ordered by whether the buyer already pays for something of that shape:

1. The decision surface as risk tooling. Venues and curators already buy risk analytics; the compatibility packets are that shape and need no integration.
2. Integration work, when a venue wants confidential collateral admitted.
3. A fee on settlement. Last deliberately: a fee on a primitive nobody uses is a spreadsheet, not a business.

Which is real is what I have not tested.
```

## How long have you each been working on this? Full time? · ≤500

```
FOUNDER TO ANSWER. What the repository can evidence: the first commit is 2026-09-12 and there are 238 of them, so Confide as it stands is about ten days of work. It builds on aperture, an earlier Apache-2.0 project of mine, used as a dependency rather than copied.

Whether that was full time, and what came before 09-12, is the founder's to state. The agent does not know and will not guess.
```

## Where is each member based? Do you work in-person? · ≤500

```
One person, based in Japan. There is no team to be co-located, so the in-person question does not arise, and funding would not change where the work happens unless the founder decides to hire — which is the founder's answer to give, not the repository's.
```

## Legal entity / investment / fundraising / live token

```
Live token: No. Confide has no token, and nothing in it depends on one existing.

Legal entity, investment taken, currently fundraising: FOUNDER TO ANSWER. The repository holds no evidence either way and a guess here is a misrepresentation to an investor.
```
