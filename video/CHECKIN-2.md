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

**Scene 2 is the week, and it changed on 2026-09-22.** It used to be the Codex review of my own
swap — a defect in my work found by somebody I asked. That moved into scene 1, because something
better happened: **a stranger corrected a claim, and then the chain settled it.**

A reader replied to the post that *"no issuer will approve one"* was a prediction and not a
measurement. They were right; nobody had been asked. Re-measuring found **two accounts had
configured a confidential one and zero were approved** — the corrected sentence, proved, by someone
who is not me and was not asked.

The form wants a test, a conversation or a decision. This is a conversation that produced a test.

**The one thing the scene refuses to do is put the two in order out loud.** The reply came about
twenty-two hours before those accounts appeared. In sixty seconds that lands as cause, and nothing
here can see a motive — the last claim that outran its evidence cost two artifacts that can never be
corrected. The pause carries the turn; no date does.

**No figure that moves is spoken as an exact number**, the rule from
[`../STATUS.md`](../STATUS.md). "Nearly half a million" and "under six thousand" are 465,498 and
5,755 as measured 2026-09-21 ([`../web/holders.json`](../web/holders.json)); both are stated in a
direction that stays true as the chain grows. The exact figures belong on screen, where they can be
re-cut, and in [`../docs/cwf-2026/WHERE-THE-POSITIONS-ARE.md`](../docs/cwf-2026/WHERE-THE-POSITIONS-ARE.md),
where they are dated.

<!-- pace.py owns the table below. Do not hand-edit it: `python3 video/pace.py --write`. -->

| | scene | seconds (+ silence) | words | pace | what it shows |
|---|---|---|---|---|---|
| 1 | what changed | 22 | 49 | 137 | two terminals side by side, then the check refusing a transaction and passing the honest one |
| 2 | what I learned | 19 + 1 | 41 | 134 | the reply, then the scan printing `2 configured 0 approved` |
| 3 | what is next | 17 | 38 | 139 | the holder table, the `≥1 share` column |
| | | **59 s** | **128** | | |

## The script

### 1 — what changed

> Last week I said the next thing was making the swap work between strangers. It does — four
> messages, two machines, neither holding the other's key. A review then found the step I called
> the safety step was signing something it had never looked at. It compares them now.

*Shows:* two terminals side by side, then the check refusing a transaction and passing the honest
one. **Two beats in one scene, because the week's real subject is the next one.** The delivered
promise and the defect found in it belong together: the thing works, and the part I was proudest of
was wrong.

### 2 — what I learned · +1 s silence

> Someone replied to my post. "No issuer will approve one" is a prediction, not a measurement. They
> were right — I had never asked one.
>
> So I measured again. Two accounts have configured a confidential one. Forty-nine minutes apart.
> Zero approved.

*Shows:* the reply, then the scan printing `2 configured   0 approved`. **The first correction from
outside this repository, and the chain agreeing with the corrector.** The pause is before "so I
measured again" — the first half is a stranger telling me a claim outran its evidence, the second is
what the corrected claim turned out to be worth. **No date is spoken between the two.** The reply
came twenty-two hours before those accounts appeared, and in sixty seconds that lands as cause. It
is a sequence; the script will not pretend otherwise
([`../docs/reviews/2026-09-22-external-no-issuer-will-approve.md`](../docs/reviews/2026-09-22-external-no-issuer-will-approve.md)).

### 3 — what is next

> The gate on a real mint — and somebody other than me is pushing on it now. Of nearly half a
> million accounts, under six thousand hold even one share. That is the market, smaller than it
> looks.

*Shows:* the holder table, the `≥1 share` column. **"A conversation nobody has had" had to go**: two
people have now had it with the chain instead, and the issuer has not answered. Ending on the
smaller number is the same move as check-in 1 ending on traction — the fact that most weakens the
pitch, said before a judge finds it.

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
- **Whether the order explains the two accounts.** It cannot be tested here: every account scan in
  this repository postdates 2026-09-17, so there is no *before*. `usage-scan.sh` now reads the
  previous run before overwriting it, so the question is answered by the count moving or not
  moving rather than by anybody arguing about it.
