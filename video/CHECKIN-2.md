# Check-in 2 — written 2026-09-22

**One minute.** The form asks three things: *what changed*, *what did you learn — share a test,
conversation or decision*, and *what is next*.

**Written before the window opens, which is the opposite of how check-in 1 was written.** Week 2's
submission window is 09-25 to **09-28 08:00 PDT**; this was drafted on 09-22 from work already
finished, so it reports rather than promises — but three days of the week remain. **Re-read this on
09-25 before recording.** If anything landed in between, it belongs in scene 1 and something here
has to give way.

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

**Scene 2 reports a defect in my own work, found by someone else.** It is the strongest thing in
the minute and the least comfortable. The form asks for a test, a conversation or a decision; this
is all three, and the decision is the general one — have the part you are most confident about read
by someone who is not you.

**No figure that moves is spoken as an exact number**, the rule from
[`../STATUS.md`](../STATUS.md). "Nearly half a million" and "under six thousand" are 465,498 and
5,755 as measured 2026-09-21 ([`../web/holders.json`](../web/holders.json)); both are stated in a
direction that stays true as the chain grows. The exact figures belong on screen, where they can be
re-cut, and in [`../docs/cwf-2026/WHERE-THE-POSITIONS-ARE.md`](../docs/cwf-2026/WHERE-THE-POSITIONS-ARE.md),
where they are dated.

<!-- pace.py owns the table below. Do not hand-edit it: `python3 video/pace.py --write`. -->

| | scene | seconds (+ silence) | words | pace | what it shows |
|---|---|---|---|---|---|
| 1 | what changed | 19 | 41 | 134 | two terminals side by side, offer to accept to settle to sign, and the decrypted amount appearing on the machine that did not create it |
| 2 | what I learned | 19 + 1 | 43 | 140 | the check refusing a transaction, then passing the honest one |
| 3 | what is next | 19 | 43 | 140 | the holder table, the `≥1 share` column |
| | | **58 s** | **127** | | |

## The script

### 1 — what changed

> Last week I said the next thing was making the swap work between strangers. It does. Four
> messages, two machines, neither holding the other's key. Each decrypts what the other will send
> before signing, and until both sign, nothing has happened.

*Shows:* two terminals side by side, offer to accept to settle to sign, and the decrypted amount
appearing on the machine that did not create it. **The picture is the two machines**, because that
is the claim: not that a swap works, which last week already showed, but that it works without the
two parties sharing anything.

### 2 — what I learned · +1 s silence

> I had it reviewed. The step I called the safety step was signing something it never looked at —
> it decrypted one thing and signed another. Now it compares them byte for byte. It caught a bug
> of mine on its first run.

*Shows:* the check refusing a transaction, then passing the honest one. **The pause is before "That
check caught a bug of mine"** — the first half is the review's finding, the second is what the fix
found immediately, which is the part that says the fix is real rather than announced.

### 3 — what is next

> Next, the gate on a real mint — a conversation nobody has had. I also measured who actually
> holds one. Of nearly half a million accounts, under six thousand hold even a single share. That
> is the market, smaller than the count says.

*Shows:* the holder table, the `≥1 share` column. **Ending on the smaller number is the same move
as check-in 1 ending on traction**: it is the fact that most weakens the pitch, and a judge who
finds it themselves reads everything before it differently.

## What this deliberately leaves out

- **That none of the 1,992 mints carries `ConfidentialMintBurn`.** Measured this week and real: a
  balance can be hidden on every one of them, and supply on none. It is a finding about what
  issuers *cannot* do, which takes longer than ten seconds to make land, and it sharpens the
  submission rather than the check-in.
- **`SPCX.US` becoming scannable at all.** A public RPC refuses to page 354,189 accounts; the scan
  now partitions by the first byte of the owner field into 256 disjoint slices. Method, not finding.
- **The rent recovery.** An acceptor's stranded 0.008539 SOL, and the retry that could not happen
  until the context keys were namespaced per attempt. Both were defects; neither is news.
- **The SEC's Innovation Exemption.** Still the strongest external fact and still too large for
  sixty seconds ([`../docs/SEC-EXEMPTION.md`](../docs/SEC-EXEMPTION.md)).
