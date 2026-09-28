# Check-in 2 — written 2026-09-22, rewritten 2026-09-27

**One minute.** The form asks three things: *what changed*, *what did you learn — share a test,
conversation or decision*, and *what is next*.

**Drafted before the window opened and rewritten inside it.** The 09-22 draft told the story of an
outside reply and two configured accounts. **Both halves of that scene are now wrong**, and the way
they became wrong is the better check-in:

- The population was wrong. `scripts/refresh-mints.sh` builds `web/mints.json` from **three
  issuers' own product catalogues**, while `scripts/slot-scan.sh:3` calls the result *"every
  tokenized-equity mint on Solana. Not a sample."* Those are not the same claim, and the second one
  is the one that reached every surface.
- The count was wrong. The draft says *"two accounts"*; `web/usage.json` read **three** on 09-24
  and **two** on 09-27. **An account that had configured a confidential balance was closed.**

**Re-run `./scripts/usage-scan.sh` immediately before recording.** The spoken lines below name a
*direction* rather than a level for exactly this reason, but scene 3 still describes a closure, and
a second closure or a new configuration changes what is true on screen.

**The schedule, from Colosseum's own dashboard (read 2026-09-21).** Submissions open during the
last three days of each week, at 08:00 PDT:

| week | opens | due | due, JST |
|---|---|---|---|
| 1 | 09-18 | **09-21 08:00 PDT** — submitted 09-20 19:17 PDT | — |
| 2 | 09-25 | **09-28 08:00 PDT** | 09-29 00:00 |
| 3 | 10-02 | **10-05 08:00 PDT** | 10-06 00:00 |
| 4 | 10-09 | **10-12 08:00 PDT** | 10-13 00:00 |

**Scene 1 answers scene 3 of last week, in its own words.** Check-in 1 ended with "making the swap
runnable by a stranger" as the next thing. That is the whole reason this check-in opens by quoting
it: a judge watching two in a row should see one of them close.

**Scene 2 is a correction of my own claim, found by widening a measurement.** It is deliberately
*not* the more flattering version of the week. The scan I had been quoting as a census of Solana
was a read of three issuers' catalogues; widening it past that list is what showed the difference.
The scene names the mistake and the method, and **it does not quote the wider scan's own numbers**:
that run has no committed parser, no candidate snapshot and no stored output yet, so it is not
evidence this repository can hand a judge. **A correction can be reported before its replacement is
provable. A new number cannot.**

**Scene 3 ends on the fact that weakens the pitch.** Somebody configured a confidential account,
waited, and closed it. That is the first movement *away* from the gate that this repository has
measured, and it is said before a judge finds it.

> **Superseded 2026-09-27, kept because the caution still applies.** The 09-22 scene 2 was the
> external reply that *"no issuer will approve one"* is a prediction, not a measurement
> ([`../docs/reviews/2026-09-22-external-no-issuer-will-approve.md`](../docs/reviews/2026-09-22-external-no-issuer-will-approve.md)).
> Its rule was: **the reply came about twenty-two hours before those accounts appeared, and in sixty
> seconds that lands as cause.** No date was spoken between the two halves. The same rule governs
> the closure in scene 3 now — **nothing here can see a motive**, so the scene says what the chain
> did and stops.

**No figure that moves is spoken as an exact number**, the rule from [`../STATUS.md`](../STATUS.md).
Scene 3 says the count *went down* and that the open ones are *empty*; it does not say two. The
exact figures — 507,908 token accounts, 2 configured, 0 approved, measured 2026-09-27 06:57 UTC —
belong on screen, where they can be re-cut, and in [`../web/usage.json`](../web/usage.json), where
they carry their own timestamp.

<!-- pace.py owns the table below. Do not hand-edit it: `python3 video/pace.py --write`. -->

| | scene | seconds (+ silence) | words | pace | what it shows |
|---|---|---|---|---|---|
| 1 | what changed | 21 | 47 | 138 | the published page decoding the devnet swaps from the chain, every account involved still reporting a public balance of 0 — the recorder waits for mainnet to answer rather than filming a still |
| 2 | what I learned | 18 + 1 | 39 | 134 | `refresh-mints.sh`'s three issuer catalogues beside `slot-scan.sh`'s own claim of a census, and the claim struck through during the pause |
| 3 | what is next | 18 | 39 | 134 | the account scan's own output, then `configured 3 → 2` and the line that says one account was configured, waited, and was closed |
| | | **58 s** | **125** | | |

## The script

### 1 — what changed

> Last week I said the next thing was the swap working between strangers. It does — four
> messages, two machines, neither holding the other's key. A review then found the step I called
> the safety step was signing something it had never read. It compares them now.

*Shows:* the published page decoding the devnet swaps from the chain, every account involved still
reporting a public balance of 0 — the recorder waits for mainnet to answer rather than filming a
still. **Two beats in one scene, because the week's real subject is the next one.** The delivered
promise and the defect found in it belong together: the thing works, and the part I was proudest of
was wrong.

### 2 — what I learned · +1 s silence

> My mint list comes from three issuers' own catalogues. I had been calling it every tokenized
> stock on Solana.
>
> It is not. I found that by widening the scan past my own list — nobody had to tell me.

*Shows:* `refresh-mints.sh`'s three issuer catalogues beside `slot-scan.sh`'s own claim of a census,
and the claim struck through during the pause. **The two files in one frame are the whole finding** — a collector and a claim
that do not match, both written here, neither caught by any check, because every check in this
repository compares files to files and none of them reads the token program. The pause is before
"It is not."

### 3 — what is next

> Since Thursday the count went down. Someone configured a confidential account, waited, and closed
> it. The ones still open are empty, and no issuer has approved any of them. Next: make the
> issuance path something a stranger can run.

*Shows:* the account scan's own output, then `configured 3 → 2` and the line that says one account
was configured, waited, and was closed. **The scan prints that line itself**; it reads the previous run before
overwriting it, so the movement is measured rather than remembered. Ending on somebody leaving is
the same move as check-in 1 ending on traction: the fact that most weakens the pitch, said first.

## What this deliberately leaves out

- **The wider scan's numbers.** Widening the population past the three catalogues found confidential
  mints this repository had never counted, including under a fourth equity issuer. **None of it is
  committed** — no parser, no candidate-list snapshot, no stored output — so none of it is spoken.
  It is next week's check-in if it survives being made reproducible.
- **Why the account was closed.** Rent recovery, a mistake, a decision, a test — nothing on chain
  distinguishes them, and sixty seconds turns a guess into a claim.
- **That none of the mints carries `ConfidentialMintBurn`.** A balance can be hidden on every one of
  them, and supply on none. It sharpens the submission rather than the check-in.
- **The holder distribution.** Under six thousand accounts hold even one share
  ([`../docs/cwf-2026/WHERE-THE-POSITIONS-ARE.md`](../docs/cwf-2026/WHERE-THE-POSITIONS-ARE.md)).
  It was scene 3 in the 09-22 draft and lost the slot to something that happened this week.
- **The SEC's Innovation Exemption.** Still the strongest external fact and still too large for
  sixty seconds ([`../docs/SEC-EXEMPTION.md`](../docs/SEC-EXEMPTION.md)).
