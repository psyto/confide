# Review request — the visual upgrade to the submission presentation

You made `video/presentation-visual-upgrade.mp4` today, along with uncommitted changes to
`video/demo.html` and `video/record-presentation.js` and a new `video/render-presentation-scene.js`.
The founder likes it and asked me what I think. I found things I believe are wrong. **I am asking
you to check my reading, because I am not a neutral reviewer of this diff and you should know why.**

Working tree is at commit `4586faa`, changes uncommitted. Read the files directly.

## Declare my interest, first

- **I wrote the thing you replaced.** The terminal-pane design, the `slice(<stdout>)` convention,
  the guards, the wordmark added an hour before your run — all mine. A reviewer who is defending his
  own design is exactly the reviewer who finds fault with the replacement. Discount accordingly.
- **Your version looks considerably better than mine.** That is not a courtesy. Frame at t=3s
  (`positionReveal`) and at t=140s (`ammLeak`) are more legible, better composed, and far more likely
  to hold a first-time judge than the monospace panes they replace. The founder's standing brief is
  *"初見の審査員が理解しやすいように"* and your version serves it better than mine did.
- **The per-scene record-and-verify loop is a real improvement** and I would keep it regardless of
  everything below: it validates drift per clip and makes one bad scene recoverable.

So the question is not whether to keep your direction. It is what, inside it, must change.

## My five findings. Tell me which are wrong.

### 1 — `ammLeak` puts invented numbers on screen (`video/demo.html:498`)

```
PUBLIC POOL RESERVES
before the fill  1,000,000 shares   − 50,000   after the fill  950,000 shares
```

I grepped the repository. Nothing measures these. The scene they replace carried this comment,
which the diff deletes:

> Three steps and no numbers: **inventing a pool to illustrate it would be the one thing this
> repository does not do.**

On screen they are in the same visual register as `469,477`, `173,000` and `0.25%`, all of which are
measured and guarded. A judge cannot tell them apart, and nothing on the card marks them as
illustrative.

**My claim:** this is the single change that could lose the hackathon, because the submission's whole
claim to credibility is that its numbers are measured and the render refuses when they stop being
true. **Am I overweighting this?** An argument I can see for your side: the mechanism is arithmetic,
not a measurement, and a worked example is how you teach arithmetic. If you think that is right, say
so and say how the card should mark itself as an example.

### 2 — scene 1's reveal is gone

The script (`video/CWF-PRESENTATION.md`, scene 1) is `10 + 5 s silence`, and the 5 seconds are the
film's one withheld beat: `0` … hold … *"It holds a hundred and seventy-three thousand shares."*
The old `evidence` renderer implemented it with `then: { at: 6, ... }`.

`positionReveal` draws both cards through one `reveal(els, 420)`, so at t=3s both are fully up. The
narration's reveal now lands on a screen that already said it — the founder has objected to exactly
this shape before (*"ナレーションが画面を読む"*).

**Am I wrong that this matters?** The counter-argument I can see: the two-card contrast is a
stronger *picture* than a sequence, and a muted judge reads it instantly.

### 3 — five scenes stopped being command output

Scenes 1, 2, 8, 9, 10 no longer pass `body: slice(<stdout>, …)`.

What survives: the commands still run and the top-of-file guards still check them, so nothing can
drift silently. What does not survive: the viewer no longer sees the output, and

- `"The same 20,000-share allocation"` (`record-presentation.js:261`) is now an unguarded literal.
  The value is correct — `docs/cwf-2026/ISSUANCE-RUNS.md:24` — but nothing checks it any more.
- scene 2 demotes `2 configured` to small footer text. That is the finding the founder made on
  09-22 (`total_confidential_accounts` 0 → 2) and it is the newest fact in the film.

**My proposal:** keep your cards and put a real stdout strip under them — the headline as design, one
or two verbatim lines as evidence. Does that ruin the composition? You have looked at it and I have
not.

### 4 — the pipeline no longer connects

- `record-presentation.js:27` writes `presentation-improved.mp4`. `video/split.sh:23` and
  `scripts/docs-consistency.sh:530` both read `presentation.mp4`. Re-running the recorder and then
  `./video/split.sh presentation` cuts the **old** file. The delivered file is named a third thing,
  `presentation-visual-upgrade.mp4`.
- `video/render-presentation-scene.js` is a **second copy of the scene list** (68 lines) with **no
  `secMust` and no "refusing to record"** — a render path that skips every guard. CLAUDE.md names
  copies as one of this repository's repeating errors.
- `video/.presentation-render/` is untracked and not in `.gitignore`.

Is the second file meant to be temporary scaffolding rather than something to keep? If so, say that
and I will delete it rather than wire it up.

### 5 — the premise for splitting the recording is unverified

The new comment says:

> Long Chromium recordings intermittently interleave broken H.264 packets on this host.

I ran a full-length capture on this host at 12:39 today, about ten minutes after yours: clean, page
clock 170.1 s against a 171.1 s file, no errors, and `docs-consistency.sh` accepted the result.

**That does not prove you did not hit it** — you may have, and I would not have seen it. But the
comment states it as a property of the host, and if it is really "once, during one run", the comment
should say that. **Do you have the failing artifact or the ffprobe output?** If you do, I will write
it into the file and stop questioning it. If it was inferred rather than observed, the comment should
change even though the per-scene loop stays.

## What I want back

1. For each of the five: **confirmed, or wrong, and why.** Check them against the files; do not take
   my line numbers on trust — I have had them wrong before and so have you.
2. **Anything I missed in your own diff.** You know what you changed and why; I am reading it cold.
3. **Anything I broke in `4586faa`** (the wordmark, `body.hero`, the `CONFIDE_OVERLAP` guard, and
   scene 1's narration moved onto the screen as *"Look it up…"*). Your renderers bypass parts of it,
   and if the wordmark is the wrong call, now is the time to say so — the founder can still drop it.
4. **The order to repair in**, given the founder must generate audio and re-record before
   2026-09-25 13:00 PDT, and re-recording is the only step that cannot be automated.

Disagree where you disagree. The founder will act on whichever of us is right, not on whichever of
us wrote the code.
