# Check-in 1 — rewritten 2026-09-21

**One minute.** The form asks three things: *what changed*, *what did you learn — share a test,
conversation or decision*, and *what is next*. Written **after** the week's work rather than before
it, so it reports rather than promises.

**Rewritten, and the 09-16 recording is superseded.** `video/Confide_CWF_Checkin1_20260916.mp4`
answered a different week: it said "eighteen hundred" mints when the count is now 1,992, quoted
$21.1m / $81.6m when the chain reads $23.2m / $84.0m, and led with the Kamino verdict page —
which was the week's change on 09-16 and is not the week's change now. **The swap runs.** Posting
the old cut would put four stale figures in front of a judge to report work that has been
superseded by better work.

**The schedule, from Colosseum's own dashboard (read 2026-09-21).** Submissions open during the
last three days of each week, at 08:00 PDT:

| week | opens | due | due, JST |
|---|---|---|---|
| 1 | 09-18 | **09-21 08:00 PDT** — submitted 09-20 19:17 PDT | — |
| 2 | 09-25 | **09-28 08:00 PDT** | 09-29 00:00 |
| 3 | 10-02 | **10-05 08:00 PDT** | 10-06 00:00 |
| 4 | 10-09 | **10-12 08:00 PDT** | 10-13 00:00 |

**The dates this file used to assert were not wrong; they were mislabelled.** 09-18 / 09-25 /
10-02 / 10-09 are the days each window *opens*, written here as though they were the days it
closes — which is the more dangerous of the two errors, because it reads as three days of slack
that do not exist on the far end.

The Official Rules still contain **no check-in clause at all**, and neither judging list names one
([`../docs/cwf-2026/CRITERIA.md`](../docs/cwf-2026/CRITERIA.md)). This is a platform request, and
the dashboard is its only source.

**No figure that moves is spoken as an exact number.** The account count is "more than three
hundred thousand" and the dollar figures are absent entirely. The Stocklana narration says "three
hundred and twenty-nine thousand" and was wrong four days later by the chain simply moving; that
rule is in [`../STATUS.md`](../STATUS.md) and this is the first script written under it.

<!-- pace.py owns the table below. Do not hand-edit it: `python3 video/pace.py --write`. -->

| | scene | seconds (+ silence) | words | pace | what it shows |
|---|---|---|---|---|---|
| 1 | what changed | 19 | 41 | 134 | the swap decoded in the browser, both balances reading `0` |
| 2 | what I learned | 18 + 1 | 39 | 134 | the gate, then the scan running to its total |
| 3 | what is next | 20 | 45 | 139 | two things next, and the line under them that is not |
| | | **58 s** | **125** | | |

## The script

### 1 — what changed

> Confide was a loan against tokenized stock. This week it became delivery versus payment. Fifty
> thousand shares against eight point seven five million dollars, one Solana transaction, neither
> side publishing what moved. Every account still reports a public balance of zero.

*Shows:* the swap decoded in the browser, both balances reading `0`. **The change is the pivot, and
the evidence is under it in the same breath.** An earlier draft of this scene described the swap as
a thing that exists, which answers "what is it" and not "what changed" — the question actually
asked.

### 2 — what I learned · +1 s silence

> The loan kept hitting one wall: collateral needs a third party, and no issuer will approve
> that account. So I counted how many ever have. Across more than three hundred thousand
> live accounts — zero. A trade needs none.

*Shows:* the gate, then the scan running to its total. **The pause is before "so I counted"** —
the first half is a month spent on the wrong shape, the second is the measurement that says nobody
else got the right one either. The form asks for a test, a conversation or a decision; this is the
decision, with the test as the evidence it was right.

### 3 — what is next

> Making the swap runnable by a stranger. Then the gate on a real mint — a conversation
> nobody has had. Not matching: bringing buyers and sellers together is what makes an exchange.
> Traction is zero, and I would rather say it than have it found.

*Shows:* two things next, and the line under them that is not. **Ending on traction is deliberate**, and is kept from the previous
version: it is the weakest fact and the first one a judge checks, so saying it costs five seconds
and buys the rest of the minute.

## What this deliberately leaves out

- **The SEC's Innovation Exemption**, issued 2026-09-17 and pinned in
  [`../docs/SEC-EXEMPTION.md`](../docs/SEC-EXEMPTION.md). It is the strongest external fact
  available and it does not fit in sixty seconds without crowding out the week's own work. It
  belongs in the submission presentation, where the AMM-only scope and the 0.25% volume cap can be
  landed properly.
- **The record-account path** for the fee-bearing leg. An implementation note, not a finding.
- **The dollar figures.** $23.2m deposited and $84.0m authorised are real and checkable, but they
  moved $1.17m in a single day this week. A recording cannot be re-cut every time the chain moves.
- **How any of it was found out.** The method earns a beat on screen and no words.
