# Reach — what can be counted, what cannot, and the one decision left

Written 2026-09-19, after the founder ruled out individual outreach (2026-09-18) and asked for the
public page to be instrumented.

**Nothing here is traction.** Traction is somebody outside this repository using Confide for
something of their own. A visitor count says a link travelled; it does not say anyone wanted what
was at the end of it. The submission says zero either way, and everything below belongs under
*demand validation*, never under *traction*.

## What is instrumented — `./scripts/reach.sh`

GitHub's traffic API: views, unique visitors, clones and referrers on `psyto/confide`.

**Why a script rather than a dashboard.** GitHub keeps **fourteen days** and then drops it. A post
that goes out on 09-20 and is read on 09-24 is invisible by 10-08, which is before judging ends. The
script merges each reading into `web/reach.json` keyed by date, so a gap longer than the window
loses nothing and no run silently rewrites history to zero. What gets quoted is then a committed
file with dates in it, which anyone can diff — rather than a number remembered from a dashboard.

**It needs push access, and `gh` here is authenticated as a different account.** Switching GitHub
accounts is founder-only, so the script refuses with that message instead of recording nothing
quietly. Run it **before the post goes out** to establish a baseline, and weekly after.

**The baseline was taken 2026-09-20, before the post.** It is `web/reach.json`, committed, and no
figure from it is retyped here — read it with `./scripts/reach.sh --show`.

### Two numbers in it that do not mean what they look like

Both were found while taking the baseline, and both would have been quoted wrong.

- **Clones are not readers.** A public repository is mirrored by machines. The baseline window
  holds more than forty clones for every page view, on days with one human visitor. The script now
  says so in its own output, computed from the ratio rather than asserted, so the largest number
  on the screen is not the one that gets repeated.
- **Unique visitors do not add up.** GitHub deduplicates uniques only *within* one fourteen-day
  window, so summing the daily column counts a returning visitor once per day — for the baseline
  it gives 11 where GitHub's own figure for the same fourteen days is 7. The merged table cannot
  recover the true count, because dedupe needs the raw visitors and the API never hands them over.
  So each read now also stores the deduplicated totals GitHub computed at that moment, under
  `windows`, and the summed column is printed with a `≤`.

## What is not instrumented, and why it is a decision rather than an oversight

**The decision page.** `psyto.github.io/confide/kamino.html` is static hosting. There is no server
and no log anyone here can read, so counting page views means **sending every visitor to a third
party**.

That is worth stating plainly rather than defaulting:

> This project's entire argument is that disclosure should be scoped to a recipient and a purpose,
> and that a global key which reads everyone's everything forever is the wrong shape. **Putting a
> third-party tracker on the page publishes every reader to a company none of them chose**, which
> is a smaller version of the thing the page is about.

A judge who notices would be right to notice. So:

| option | what it costs |
|---|---|
| **nothing on the page** *(current)* | no page-level number at all. Repo traffic and referrers only. Consistent with what the page argues. |
| a cookieless counter (GoatCounter or similar) | a real per-page number. Visitor requests reach a third party; no cookies, no stored IP, but the requests happen. Needs a founder account. |
| self-hosted counter | same number, nobody else sees it. Needs a server this project does not have and should not acquire for this. |

**Recommendation: leave the page uninstrumented and quote repo traffic.** The number a page counter
would add is small, unverifiable by a reader, and belongs under demand validation where it is worth
little — and the cost is a visible inconsistency with the argument. If the founder wants the page
number anyway, the cookieless option is the one to take, and it should be disclosed on the page
itself rather than hidden, which is the only version of it this project can defend.

**This is the founder's call, not the agent's.** It is recorded here undecided.

## What would actually count

Stated so the bar does not move later:

- somebody outside this repository runs `./scripts/packet.sh` or opens the decision page **and then
  does something with the answer** — cites it, disputes it, asks for a mint it does not cover
- an issuer or a risk owner responds to the compatibility verdict, in either direction
- a refusal with a reason attached, which is information; silence is not

**None of these has happened.** If none has by 10-12, the submission says traction: zero.
