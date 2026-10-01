# Check-in 3 — written 2026-10-02

**One minute.** The form, read 2026-10-02 from Colosseum's page: *"Show what you built, share what
you learned, and explain what you'll work on next."* Opens **10-02 08:00 PDT**, due **10-05 08:00
PDT** (10-06 00:00 JST). **"Submitted links cannot be changed or deleted"** — so the cut is checked
before the link is pasted, not after.

**Week 2 was missed** (`STATUS.md` 0h). This one covers both weeks and says so in its first
sentence. A judge who sees a gap in the list should hear about it from the video, not infer it.

**Scene 1 is the product, not a picture of it.** It is cut from `video/demo-ops.mp4`, the real
devnet run through the app (2026-09-30), whose fast-forwarded waits already carry an on-screen badge
with their real duration. **Four stretches of it, in order, with three cuts.** The first two cuts
drop only the wait between one result and the next action, so each result lands on the words that
describe it (refusal 0:41, self-approval refused 0:49, approval 0:58 in the source). **The third
cut also drops a step**: the half-signed send and its preflight refusal. Its `REFUSED · preflight`
row is in the blotter of the last stretch, but the step itself is not shown. The banner across the
top of every frame says what the run is: devnet, a local demo, every key held by one machine. The source ranges
are below, read by the recorder, and nowhere else.

<!-- footage: video/demo-ops.mp4 33.0-42.5 45.0-50.5 55.5-59.0 72.0- -->

**Scene 2 is a correction of my own claim.** Not the catalogue-versus-census correction that
check-in 2 was going to carry — that one has since reached every surface in writing. This is the
newer one: the configuration I had been reading as a choice is the struct's zero value
(`docs/cwf-2026/THE-PINCER.md`, *And the uniformity is not evidence of a decision*). The source line
is shown, not paraphrased.

**Scene 3 ends on traction being zero**, as check-in 1 did, and names one next thing — one this
repository can finish by 10-12 without anybody else: the testbed path on a fresh machine, recorded.
Not "from nothing": `testbed-join.sh` needs the Solana CLI, Rust and devnet SOL.

**"I'm taking that claim out", not "I took it out".** The repository copy of the form lost it on
2026-09-29 (`e64abe5`); the form itself was last pasted 2026-09-22 and **still carries it** until the
founder repastes. The slide says so.

**No figure that moves is spoken.** Scene 3 says *where I count*, not how many; the counts are on
screen from `web/usage.json` with its own timestamp. **Re-run `./scripts/usage-scan.sh` before
recording** — the recorder refuses if an account has been approved.

<!-- pace.py owns the table below. Do not hand-edit it: `python3 video/pace.py --write`. -->

| | scene | seconds (+ silence) | words | pace | what it shows |
|---|---|---|---|---|---|
| 1 | what I built | 22 + 2 | 50 | 140 | the devnet run: the allocation refused on chain with `Custom(24)`, the investor's own approval refused, the issuer approving that one account, then the settled row and all four public balances reading 0 |
| 2 | what I learned | 19 + 1 | 42 | 137 | the mint's two fields beside `InitializeMintData`'s `Pod, Zeroable` derive, and the sentence that a zeroed struct yields exactly them. The pause is before "It's the default." |
| 3 | what is next | 11 | 23 | 133 | the account scan's configured and approved counts with their date, traction zero, and the one next item |
| | | **55 s** | **115** | | |

## The script

### 1 — what I built · +2 s silence

> I missed last week's check-in, so this covers two. I built the issuance path, here on devnet. An
> allocation to an unapproved account: Token-2022 refuses it on chain. The investor can't approve
> themselves. The issuer approves that one account, the same allocation settles, and all four
> public balances read zero.

*Shows:* the devnet run: the allocation refused on chain with `Custom(24)`, the investor's own
approval refused, the issuer approving that one account, then the settled row and all four public
balances reading 0. **The refusals are the chain's, and the screen says so** — each blotter row
names who did it (`TOKEN-2022`, `SOLANA`, `CONFIDE`).

### 2 — what I learned · +1 s silence

> Every mint I've measured ships with the gate shut and the auditor slot empty. I'd told that as
> issuers deciding.
>
> It's the default. A zeroed struct gives exactly those values, so they're no evidence of a choice.
> I'm taking that claim out.

*Shows:* the mint's two fields beside `InitializeMintData`'s `Pod, Zeroable` derive, and the sentence
that a zeroed struct yields exactly them. The pause is before "It's the default."

### 3 — what is next

> Where I count, no account is approved, and traction is zero. Next: the public testbed path, run
> on a fresh machine and recorded.

*Shows:* the account scan's configured and approved counts with their date, traction zero, and the
one next item.

## What this deliberately leaves out

- **The second act** — two approved holders trading, each checking its pin. It is in the demo
  video; one minute holds one flow.
- **Why the slot is empty.** The scene says the configuration cannot show a choice, and stops
  there. Only the provenance of the mint-creation transactions could settle it, and nobody has read it.
- **The wider scan beyond the three catalogues.** Still uncommitted (`STATUS.md` 0k), so not spoken.
