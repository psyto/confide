# The work window — Crypto World's Fair

Colosseum judges this submission on what was built inside the contest window, not on what the
repository already contained when the window opened. Confide existed before it. So the boundary is
recorded here, with the commands that establish it, rather than asserted later from memory.

> "Teams may begin development before the hackathon, but products are judged only on the work
> completed between the competition's start and end dates."
>
> — [colosseum.com/hackathon](https://colosseum.com/hackathon), read 2026-09-15

## The boundary

```
765b8bc440a8383d529fa5af9d7100d4022dc8ca    the last commit before the window opened
tree 36c1ed285017f1153acd90f2bee4a17a14ec485f
youtube: stop the last chapter sitting exactly on the ten-second floor
```

| | |
|---|---|
| **Baseline commit** | `765b8bc` — authored and committed 2026-09-14 **16:37:41 JST** (07:37:41 UTC, 00:37:41 PT) |
| **Window opens** | 2026-09-14 **06:00 PT** = 13:00 UTC = 22:00 JST |
| **Window closes** | 2026-10-12 **23:59 PT** |
| **Margin** | the baseline predates the window by **5 h 22 min 19 s** |
| **Commits inside the window at time of recording** | **0** |

The window times are quoted from the Official Rules, which are the governing document:

> "5. Timing. The Contest Period starts at 6:00am PT on September 14, 2026 and ends at 11:59pm
> PT on October 12, 2026."
>
> — [Crypto World's Fair Hackathon Rules](https://colosseum.com/legal/Crypto%20World's%20Fair%20Hackathon%20Rules.pdf) §5, read 2026-09-15

Three different times are in circulation and only the one above governs. `colosseum.com/worldsfair`
lists a **kickoff event** at 10:00 PT on September 15 — that is a livestream, and it is 28 hours
after the Contest Period starts. The window is the rules' window.

## Everything in the window, and nothing else

```bash
git log --reverse --format='%h %ad %s' --date=iso-local 765b8bc..HEAD   # the work being judged
git diff 765b8bc..HEAD                                                 # the whole of it, as a diff
```

Both are exact because `765b8bc` is a commit, not a date filter: no clock skew, no rewritten author
date, and no judgement call about which commit landed first.

## Evidence this boundary is uncontaminated

Run against the repository at the moment this file was written — 2026-09-15 08:43 JST, before the
commit that adds it:

```
$ git rev-parse HEAD
765b8bc440a8383d529fa5af9d7100d4022dc8ca

$ git rev-list --count --since='2026-09-14T13:00:00Z' HEAD      # commits at or after the window opened
0

$ TZ=UTC git log -3 --date=iso-local --format='%h %cd %s'
765b8bc 2026-09-14 07:37:41 +0000 youtube: stop the last chapter sitting exactly on the ten-second floor
6c722e1 2026-09-14 07:23:38 +0000 video: hand off the clips and lines for compositing elsewhere
f93b580 2026-09-14 07:16:48 +0000 video docs: say which cut is published, and stop claiming seven clips are byte-identical

$ git rev-parse origin/main                                     # the published history agrees
765b8bc440a8383d529fa5af9d7100d4022dc8ca
```

`765b8bc` was the 48th commit. All 48 are pre-window and none of them are claimed as contest work.

The same commit is tagged, so the boundary survives a `git log` that nobody reads:

```bash
git show cwf-2026-baseline
```

The tag was written after the window opened — it records the boundary, it does not predate it. The
commit that adds this file is the first commit inside the window, which is what makes the record
worth anything: it was the first thing done, not a reconstruction after the fact.

**Working tree when the window opened**, for completeness — two video files, neither of them source,
both predating the window: `video/Confide_Stocklana_20260913.mp4` deleted, and
`video/Confide_Stocklana_20260914.mp4` untracked (written 2026-09-14 16:33 JST).

## What this file does not do

- **It does not discharge the disclosure.** The rules put that in the submission form, not in the
  repository: *"Builders may use pre-existing code, but teams must disclose all relevant past
  development work in the submission form."* That field has to be filled in by hand, and this file
  is the source it should be filled in from — not a substitute for it.
- **It does not narrow the product to the window.** What is submitted is Confide entire, pre-window
  work included; the rule governs what is *judged*, and the disclosure is what makes the rest
  admissible. The reuse table in [README.md](../README.md#built-on) covers the third-party and
  pre-existing components.
- **It is deliberately conservative.** Anything ambiguous is assigned to the pre-window side. Had
  the window opened earlier in the day than the rules say, the three commits listed above would fall
  inside it and are still not claimed.
