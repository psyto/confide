# The public post — ready to publish, founder posts

Rewritten 2026-09-20. **No individual outreach** (founder ruling, 2026-09-18): this is written
once, has no addressee, and asks for no meeting, no reply and no favour.

**What changed from the 09-19 draft, so the change is a decision rather than a drift:**

- The headline is no longer the Kamino pincer. It is a measurement nobody had made — **469,477
  token accounts, and not one of them confidential.** The pincer is why, and is now support.
- The draft said *"it does not make the pincer go away"* and that was true of a **loan**. A loan
  needs a third party to hold collateral, and that third party is what the gate bites. **A trade
  does not**, so the swap runs where the loan could not.
- **It now asks for one thing**, and the previous draft asked for nothing. See the reasoning below,
  because that is the substantive change and it deserves an argument rather than a shrug.

**Run `./scripts/reach.sh` before posting.** It establishes the baseline; without one, whatever
arrives afterwards cannot be told apart from what was already there.

**Every number below is recomputable, and they move.** Re-run `./scripts/usage-scan.sh`,
`./scripts/capacity.sh` and `./scripts/slot-scan.sh` before posting and update from their output —
a post quoting a figure the page contradicts is worse than no post. Current readings:
**469,477 accounts / 0 confidential**, and
**$24.0 m / $86.2 m**.

---

## Long form

> **Solana shipped confidential balances for tokenized stocks. I counted the accounts. Nobody has
> ever opened one.**
>
> Every tokenized-equity mint on Solana — **all 1,992**, from three issuers with nothing to do with
> each other — runs Token-2022 with confidential transfers switched **on** and the auditor key
> **empty**. That much has been written about. What I could not find anywhere was the other half:
> has anyone actually used it?
>
> So I counted. **469,477 token accounts across Apple, NVIDIA, SpaceX, Anthropic and AMC.
> 0 are configured for confidential transfers.** Not few. Zero.
> (`./scripts/usage-scan.sh` — and the first pass found seven accounts large enough to be one, every
> one of which was large for an unrelated extension, so the check reads the extension list rather
> than the size.)
>
> The reason is one field. `autoApproveNewAccounts` is **false on 1,992 of 1,992**, so a
> confidential account cannot exist until the issuer signs for it, and no issuer has. And the only
> disclosure model on offer is a single global auditor key that reads everyone's everything
> forever — fill it and every holder is permanently readable by one party, leave it null and no
> holder can prove anything to anyone. So it sits null, on every mint, at every issuer.
>
> **It is not an equities story.** USDC and USDT cannot move confidentially at all — legacy SPL, no
> extensions. **PYUSD and USDG can**, and they land on the *identical* configuration: gate closed,
> auditor slot empty, the same key holding confidential authority, permanent delegate and freeze
> authority on both. PayPal's dollar ships the same unusable privacy feature behind the same door.
> Four issuers, two asset classes, one dead end — **a property of the substrate, not a choice any of
> them made.**
>
> This matters because people already lend against these tokens. Kamino runs 19 tokenized-equity
> reserves: **$24.0 m deposited, $86.2 m of borrowing their own caps authorise, and $0 of it
> reachable if you would rather your position were not public.**
>
> **Kamino's refusal is correct underwriting, not an oversight.** A lender who cannot read a balance
> cannot price it. Their program names the confidential-transfer extensions and requires them
> switched off, on the depositor's own account, at deposit — `constraints.rs:187`, `:194`, `:201`,
> `lending_checks.rs:186`, at release/v1.25.0. And `constraints.rs:131` refuses a mint whose
> `autoApproveNewAccounts` is *true*, so **the setting Kamino requires is the setting that puts the
> issuer in the path.** Same field, read from two sides.
>
> I spent a month building for that and hit the gate every time, because **a loan needs a third
> party to hold the collateral** and a third party needs an account. Then the obvious thing: a
> **trade** needs no third party at all. Both legs go in one transaction, so either both settle or
> neither does — Solana's atomicity is the escrow.
>
> So it runs. **50,000 shares for $8,750,000 in a single transaction**, delivery against payment,
> and neither side publishes the size or the price it implies. Both accounts are ordinary
> associated token accounts and both still read a public balance of `0`. A second one carries a
> plain confidential transfer *and* a with-fee confidential transfer together, because the cash leg
> is shaped like PYUSD and PYUSD charges a fee — two assets whose rules do not match, settled
> atomically.
>
> Delivery versus payment is what a clearing house is *for*: neither side will go first, so finance
> inserts a central counterparty, membership, margin and a day of lag. **None of that is needed when
> the transaction cannot half-happen** — and the confidential version means neither party publishes
> the size a clearing house would have been told anyway.
>
> **What this does not do:** it does not make a real xStock pledgeable, it does not open Kamino's
> $86.2 m, and nobody outside my own repository has used any of it. The `$0` stands.
>
> **One thing you can do, and it is the point of this post.** I stood up an issuer on devnet whose
> gate is shut exactly as all 1,992 are — `autoApproveNewAccounts: false`, auditor slot empty — and
> then published the key that opens it. So you can open a confidential position yourself, in one
> command, and hold something the chain reports as zero:
>
> ```
> git clone https://github.com/psyto/confide && ./scripts/testbed-join.sh
> ```
>
> It is devnet and the tokens represent nothing. You will need the Solana CLI, a Rust toolchain and
> a little devnet SOL — the script tries the airdrop and tells you what to do when it is throttled,
> which it usually is. **It is the thing 469,477 live accounts have never done.** Mint
> `7MEQEiy1…`; the approval key is in `keys/` and cannot mint, which is checked rather than claimed.
>
> Everything above is checkable without taking my word for it:
> https://psyto.github.io/confide/ reads the mints from mainnet in your browser and decodes the
> devnet trades. Code: https://github.com/psyto/confide
>
> **And if I have read Kamino's source wrong, or the account scan is wrong, I would much rather
> hear it from you than from a judge.**

---

## Short form

> Every tokenized stock on Solana ships confidential balances. All 1,992, three issuers, auditor key
> empty on every one.
>
> I counted the accounts. **469,477 of them across Apple, NVIDIA, SpaceX, Anthropic, AMC.
> 0 are confidential.** Nobody has ever opened one — the issuer has
> to sign, and none has.
>
> Same story outside equities: PYUSD and USDG, same gate, same empty slot.
>
> So a loan is out — collateral needs a third party, a third party needs an account. A **trade**
> does not: 50,000 shares for $8.75 m in one transaction, neither size published, no clearing house.
>
> You can open one yourself on devnet — the issuer's gate is shut there too, and I published the
> key that opens it: github.com/psyto/confide → `./scripts/testbed-join.sh`

---

## For X — one long post, founder has Premium

**Attach `video/Confide_Stocklana_20260920.mp4` natively.** Not the YouTube link: X carries the
file itself further than it carries a link off-platform, and 2:22 is inside Premium's limit. The
YouTube upload stays where it is for the submission forms.

**2,036 characters**, against Premium's 25,000 (draft A was 2,377). The reason a single post beats a thread
here is that the argument has one shape and a thread invites replying to one post of it.

**The first 131 characters are what a reader sees before X folds the rest behind *Show more*,**
so they have to stand alone. They are the count and nothing else:

```
Every tokenized stock on Solana ships confidential balances.

All 1,992 of them.

I counted the accounts actually using one.

Zero.
```

The full text is generated into [`x-post.txt`](x-post.txt) by `./scripts/x-post.sh`, which reads
the two figures out of `web/mints.json` and `web/usage.json` rather than letting them be typed —
the short description sat in a submitted field saying 1,869 for days because it was typed once.

**A normal post, not an X Article.** Asked 2026-09-21; checked rather than assumed, because X's
behaviour changed in Q1 2026:

- **An Article is treated like an external link.** The Article itself gets no wide organic
  distribution — a preview post does the distribution work, so publishing as one means writing two
  pieces of content and still relying on a post. This post already puts its single link last
  *because a link costs reach*; an Article applies that cost to the whole thing.
- **A long single post beats a thread**, which is the choice already made here for a different
  reason. Each post in a thread is scored on its own and a weak first one buries the rest; a
  long-form post is scored as one unit with **dwell time aggregated**, so length that is actually
  read is an asset rather than a penalty. 2,377 characters is not too long for this surface.
- Premium carries a scoring bonus on top, and the gap widened in Q1 2026.

Sources: [Sprout Social](https://sproutsocial.com/insights/twitter-algorithm/),
[Socialync on Articles](https://www.socialync.io/blog/x-twitter-articles-strategy-2026),
[SMMNut on Premium](https://smmnut.com/blog/does-x-premium-give-real-algorithm-advantages-2026/).
Second-hand analyses of a ranking system nobody outside X can run, so they are cited rather than
treated as fact — but three of them agree on the Article/link point, which is the one that decides
this.

**One thing to check in the compose box, which no source can answer.** The 131-character figure
below is for a post with no media. **Attaching the video may shorten what shows before *Show
more*.** If it does, the first line carries it alone — "Every tokenized stock on Solana ships
confidential balances." — but look at the preview with the video attached before sending.

**One link, in the last block.** `psyto.github.io/confide`. A link in the opening lines costs
reach, and the post has to earn the click before it offers one.

**Amended 2026-09-21:** it is no longer the final line. B closes on *"I would much rather hear it
from you than from a judge"*, because a bare URL is a weak last beat and an invitation to correct
draws replies, which the ranking counts. The rule was "not in the opening lines"; ending on the
link was never the part doing the work.

### Naming the hackathons — a self-reply, not the post

Asked by the founder, 2026-09-21: does the video or the post have to say this is a Stocklana entry?

**Nothing requires it.** The CWF Official Rules carry no publicity or announcement clause, and the
one disclosure obligation they do impose — past development work — is placed **in the submission
form**, not in the repository and not in public (`docs/WORK-WINDOW.md:109`). Stocklana's page, as
read, asks for nothing of the kind either.

So it is a question of whether it helps, and the answer differs by surface.

**Not in the YouTube description.** Two reasons, the second one load-bearing. It has 38 characters
spare, and a judge arriving from the form already knows. More importantly **the same video serves
both contests**, and STATUS.md is explicit that the two framings are not interchangeable: Stocklana
can be told "all of this was written for this contest" and CWF cannot, because 48 commits sit
outside its window. Stamping one contest's name onto the artifact both of them watch is how that
distinction starts to blur. Contest-neutral is safer, not merely tidier.

**Not in the post body either — in a reply under it.** The post works because it is a measurement
with no addressee and no ask. "This is my hackathon entry" turns a finding into a pitch, and hands
a reader the licence to file it under *demo* rather than *this runs*. But the founder's actual
problem is distribution — 7 unique visitors on the baseline — and contest tags do bring the
organiser's audience.

A self-reply gets both. The first post keeps its fold and its framing; the reply carries the
context for anyone who wants it:

```
Context, since a few have asked: this is entered in the Stocklana hackathon, and in
Colosseum's Crypto World's Fair.

Nothing above depends on that. Every figure has the command that produces it, and the
devnet issuer is standing whether anyone is judging or not.
```

**What that reply must not say.** Not *built for* either contest — that is a work-window claim and
it is true of one and false of the other. Not a request to look, vote or share. It states where the
project is entered and then gets out of the way.

### Draft B — written 2026-09-21, **adopted the same day**

The founder asked whether the post reads as something that would travel. The 09-20 draft did not,
and was not written to: the design below buys credibility and spends reach. B spends less of the
reach and **the founder chose it on 2026-09-21 — "B の方がわかりやすい"**. B is now the post;
the 09-20 version is kept as draft A.

Render either through the generator, never as a second finished file, so a superseded draft cannot
sit here quoting a count from the week it was written: `./scripts/x-post.sh` for the post,
`./scripts/x-post.sh a` for the one it replaced. The zero-guard covers both — neither renders if a
confidential account ever exists.

**What B changes.**

- **Backticks and the indented code block are gone.** X renders no markdown, so `autoApproveNewAccounts`
  and the two-line command were going to appear with their punctuation showing. That part is a
  display defect rather than a preference, and it should be fixed in whichever draft ships.
- **The built thing moves to the second block**, from line 23 of 44. A read diagnosis, diagnosis,
  diagnosis, result.
- **One line is isolated so it can be quoted alone:** *"A loan needs somebody in the middle. A trade
  needs nobody — the transaction is the clearing house."* A has no sentence that survives being cut
  out of it, and a post travels by the line somebody screenshots.
- **The month of failure now explains the shape** instead of standing as its own episode, because
  it follows the result rather than preceding it.

**What B keeps, deliberately.** The Kamino concession and the zero-traction admission, both
promoted to their own block. They are where the credibility is; a shorter post that drops them is
a different post.

**One cost was listed and then recovered.** The first B shrank the stablecoin comparison to a
single sentence and lost *"four issuers, two asset classes, one dead end"*. The founder pushed back
on losing it, and was right: what was long in A was the **enumeration** of matching fields, not the
conclusion. Dropping the enumeration and keeping the conclusion puts the fact back in less space
than A used — and standing alone as its own paragraph it became **a second quotable line**, which
is the thing B was written to get. 2,036 → 2,218 characters, still under A's 2,377.

**What B still costs, said plainly.**

- **Five dividers where A has four** — which contradicts the criticism that prompted it, that this
  reads as an essay rather than a post. Isolating the quotable line was judged worth it. That is a
  judgement, not a finding.
- **It still will not travel.** The baseline is 7 unique visitors. That is a cold-start problem, not
  a copy problem, and B is easier to read rather than differently distributed.

## Why it is written this way

- **It leads with a measurement nobody else has made.** "The feature is unused" is an assertion
  until somebody counts; the count is the contribution, and it is cheap for a reader to repeat.
- **Kamino is conceded as correct before anything is said about the gap.** A post that reads as an
  attack on a protocol with $24.0 m in it gets answered as an attack, and the framing freezes before
  anyone looks at the evidence.
- **The failure is told as a failure.** A month of building the wrong shape, said plainly, is what
  earns the sentence after it.
- **Every number carries the command that produces it.** The chain moved $21.1 m → $22.0 m while
  the previous draft was being written, and $22.0 m → $23.2 m in the single day between the
  account rescan and this one. A figure typed into a post is wrong within a week.
- **No claim of traction.** Nothing here says anyone uses this, because nobody does.

### The ask, which the previous draft did not have

The 09-19 draft asked for nothing, on the grounds that the only invitation worth making is *prove
me wrong* — which costs the reader nothing and is worth more than silence. **That is still in the
last line.** What changed is that there is now something a reader can *do* that is equally costless
and strictly more informative:

- It is **not a request for a meeting, a reply, or a favour**, so it does not cross the outreach
  ruling. It has no addressee.
- It **demonstrates the finding rather than repeating it.** A reader who runs it feels the gate
  open, on a mint configured exactly like the ones where it never has.
- It is the **only measurable response available.** A new account on that mint is a fact with a
  timestamp. Silence is also a fact, and a clearer one than a post nobody could act on.
- It costs the reader nothing at risk — devnet, no wallet connection, no value. It is **not**
  frictionless, and the post says so: it needs the Solana CLI, Rust, and devnet SOL from a faucet
  that is usually throttled. The first version of the script hid that by falling back to a keypair
  only the author has, so "one command" was true for exactly one person.

**It is still not traction until somebody does it.** See [`REACH.md`](REACH.md).

## What is deliberately not in it

**The transfer-fee material.** The previous draft excluded it because there was no finding — the
with-fee path works, it just routes the oversized range proof through a record account. That is now
**implemented and running**, which makes it even less of a finding and more of an implementation
note. It appears in the post only as the one clause about two rule sets in one transaction.

Two reasons outlive the change:

- The post has one finding. A second halves both, and a second that turns out to be wrong destroys
  the first.
- Those eight pre-IPO mints belong to a company **sponsoring the event this is submitted to**. Even
  a correct note about a live product, from a stranger, during their event, is a different act from
  a note about a boundary in Kamino's source — and Kamino's is framed as *correct underwriting*.

## What not to do afterwards

- **Do not DM anyone the link.** That is individual outreach under another name, and it was ruled
  out on 2026-09-18.
- **Do not argue with a refusal.** Record it exactly as received, reasons included. A reason is
  information about the market; a won argument is not.
- **Do not report arrivals as traction**, in the submission or in a check-in. An account opened on
  the devnet testbed is the first thing that would count, and it is counted as what it is: somebody
  exercised the mechanism on a token representing nothing.
