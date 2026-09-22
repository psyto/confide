# video

## `Confide_Stocklana_20260922.mp4` — **published: https://youtu.be/C86U3R0IgiU**

The delivered cut is **2:28**, 1920x1080, AAC stereo, with a caption track. The founder generated the voice and
recomposited to it, so the file is 148.6s against the silent master's 177.1s — the two clocks
disagree by design and the delivered file is the authority.

Checked against the delivered file rather than assumed:

| | |
|---|---|
| every line present | all ten scenes, in order — **verified from the audio, not the transcript** |
| **the reveal survives** | the picture holds `public balance 0` through 55.0s and reads `173000 units` by 55.8s, with a 0.57s gap in the voice at 53.8s. Same structure as the cut that shipped, whose gap there was 0.62s. The script budgets five seconds of silence; a delivery paced to the voice has never had them, in either cut |
| no dropped line | the longest silence is **1.44s at 98.5s**, between *"Nobody chose this"* and *"You cannot do this on one"*. Longer than any pause in the 09-20 cut, which had none over a second, and far short of the five a missing line would leave |
| every claim still live | `swap-status.sh`, `testbed-up.sh --check`, `usage-scan.sh --last`, `healthcheck.sh` |

**The ASR track lost sixteen seconds.** It has no cues at all between 83.4s and 99.8s — the whole of
*and it is not only equities*. The audio is there: that window measures **-24.1 dB mean**, against
-23.1 dB in the scene before it, with the short breaths of speech in it, and the picture is the
stablecoin table. So the voice said it and the transcriber lost it.

`fix-captions.sh` corrects words and never moves a cue, which is the right contract and the reason
filling a hole is a separate step: [`../scripts/caption-gap.py`](../scripts/caption-gap.py) writes
the missing cues from the script, and refuses unless the gap is over six seconds, the audio inside
it is not silent, and **exactly one** scene of the script is absent from the transcript. Both
together produce [`captions-20260922.srt`](captions-20260922.srt) — 68 cues, all ten scenes.

Five word-level corrections were needed, and two of them were rules that already existed and had
missed: `confidential transfer switched` was lowercase-only and the line now opens a sentence, and
`and everyone` was anchored to the end of a line and now sits mid-line. **A rule is not a fix until
the file is read again.** The new ones: *bite for bite* for **byte for byte**, which is the entire
claim of the check that scene describes, and *let's* for *lets*.

**The caption tracks on the upload, read off the watch page 2026-09-22:** an uploaded `en`, an
uploaded `ja`, **and YouTube's own `en kind=asr` still listed beside them.** That is different from
the 09-20 upload, where uploading the English track made the ASR one disappear. `healthcheck.sh`
confirms the default English track is the uploaded one, so a viewer gets the corrected captions —
but the machine transcript is still reachable, and it is the one missing sixteen seconds.

**What is still not verified, and the reason is the same as last time:** YouTube's `timedtext`
returns no body to this fetch, so nothing here has read either track's words. That a file was
uploaded is measurable; that it is the right file is not. **The sixteen seconds this cut recovered
are at 1:27–1:39 on the upload — worth one look with captions on.**

**Superseded 2026-09-22: `Confide_Stocklana_20260920.mp4`** — 2:22, published as `gilIzns5joM`. It
speaks the order the restructure replaced and says *"three hundred and twenty-nine thousand
accounts"*, measured 09-17 and 465,520 four days later. Its narration was frozen in
`DELIVERED-20260920.md`, which this cut's `DELIVERED-20260922.md` replaces, the way that file said
it should be.

**Uploaded 2026-09-22 as `C86U3R0IgiU`**, and every surface that names the current video was moved
to it: `README.md`, `web/index.html`, `docs/DURABILITY.md`, `scripts/healthcheck.sh` and `STATUS.md`.
`web/poster.jpg` is a frame from this file rather than from the old one, and the caption under it
stopped calling it "the earlier walkthrough".

**Check-in 1 is a second live upload: `mbE8HMwG0S4`**, `Confide_CWF_Check-in-1_20260921.mp4`,
0:55, with `checkin-1-20260921.srt` as its English track. It is not a version of the presentation
and does not supersede anything — `scripts/healthcheck.sh` watches both links and excludes both
from the superseded scan below.

**`p1aQuEnzhQk` was deleted by the founder on 2026-09-21**, along with the two before it. The
occurrences left in this file are history and belong here; they are written as bare ids rather than
links, because the URLs now 404 and a reader should not be handed one to click.
`scripts/healthcheck.sh` checks that every id named here is gone and that the current one is not,
so "one answer to one question" is measured rather than remembered.


**Superseded 2026-09-20, deleted 2026-09-21: `p1aQuEnzhQk`** — `Confide_Stocklana_20260915.mp4`, uploaded 2026-09-15:
the current render at 1920x1080, the recorded narration, and the subtitle track. It says 1,869 mints
across two issuers and shows the confidential account the page and the README point at.

Superseded uploads, in order: `ZuhLvH5MFgE` (732 mints, one issuer, an account that no longer
exists) and `KQsRwP8HTs0` (the same nine scenes, before the captions carried the seizure). Both
were deleted on 2026-09-21. Nothing links to either.

**Two clocks, and they do not agree.** `presentation.mp4` is the silent master at the recorder's
pacing, 2:57; the delivered cut is 2:28, because the voice is generated externally and paces
differently, and the clips were recomposited to it. The published file is the authority for
anything a viewer sees — chapters especially, which come from its own subtitle track and not from
`record.js` holds.

`confide.mp4` — 2:07 silent master, rendered headlessly (Puppeteer → Chromium → ffmpeg). No screen recording, no
narration track, no external assets, no stock footage: the diagrams are SVG and CSS in the page.

```bash
npm run record      # -> confide.mp4, reading the account out of account-keys.json
./narrate.sh        # -> confide-narrated.mp4, the recorded voice muxed straight on
```

`narrate.sh` is the whole path for a re-render. The voice is one continuous track on the same
timeline, so it needs no cutting; the script refuses unless the narration still falls silent at
every scene boundary, and trims the second of blank the recorder captures past the last scene.

The per-scene tools are for working on one line at a time:

```bash
./split.sh            # -> segments/
./lift-narration.sh   # -> segments/narrated/
./join.sh             # -> confide-narrated.mp4
```

**Prefer `narrate.sh` for anything you are going to publish.** On 2026-09-15 the concat path
produced a file that was black from 0:45 to 1:30: `split.sh` let ffmpeg read the stdin its own loop
was reading from, a filename arrived with its leading character missing, four clips silently stayed
at the previous resolution, and players stop decoding where the resolution changes while the audio
plays on. ffmpeg decoded it fine, so every check I had passed. `split.sh` now passes `-nostdin` and
asserts one resolution across the set, but the path with no concatenation in it cannot fail that way
at all.

Re-rendering moves the pictures and leaves the narration alone, which is why those last two steps
exist. The account address is on screen in one scene, so a re-provision makes the published video
wrong in a way no test catches.

It leads with what a holder gets, not with how the mechanism works. The terminal is demoted to
evidence at the end, stamped *real output, just now*, because a video made of terminal panes reads
as a research artifact rather than a product — which is the wrong thing to be, for a question that
asks whether people would use this.

```bash
npm install
npm run record        # -> confide.mp4   (needs ffmpeg; FFMPEG_PATH overrides /opt/homebrew/bin/ffmpeg)
```

## Narration

[`voiceover.md`](voiceover.md) — timed to the measured scene boundaries, not to a guess. The page
logs `CONFIDE_SCENE <kind> <seconds>` during a run; re-read those after changing any `hold` rather
than trusting the timecodes in the script.

## Recording narration

[`segments/`](segments) has the cut split at the scene boundaries, one clip per narration block, and
[`join.sh`](join.sh) puts it back together once you have recorded them. Record one at a time and
rejoin after each — missing segments fall back to the silent original.

## The terminal in it is not a transcription

Every pane is the stdout of a command run moments before the recording starts:

| pane | command | reaches |
|---|---|---|
| every xStock mint and its empty auditor slot | `scripts/onchain-check.sh` | **mainnet** |
| a position that reads as zero and opens to 173,000 | `scripts/read-balance.sh` | **devnet** |
| the lender's check, both proofs accepted | `scripts/prove-collateral.sh` | **devnet** |

The proof panes need the account's keys: pass `CONFIDE_KEYS=/path/to/account-keys.json`, from
`scripts/provision-account.sh`. They are devnet keys and they are not in this repository.

`record.js` asserts on the lines that carry the claims — four empty auditor slots, `public balance
0`, `173000 units`, both proof programs by name, two `err: None`, `both accepted` — and **throws
rather than recording** if any of them is missing. A video that says something the code
did not do is worse than no video, and the failure mode it guards against is the quiet one: a demo
that still renders after the thing it demonstrates stopped working.

`puppeteer` is pinned to `19.0.0` because `puppeteer-screen-recorder@3.0.6` requires exactly that.

## The weekly check-in

`checkin-1.mp4` — 61s, three scenes, silent. Script and timings:
[`CHECKIN-1.md`](CHECKIN-1.md), whose table `pace.py` derives from the narration's own word counts.

```bash
node video/record-checkin.js     # -> checkin-1.mp4 + segments-checkin/manifest.json
./video/split.sh checkin         # -> segments-checkin/*.mp4 and LINES.md
```

`split.sh` takes which cut to slice rather than existing twice; `segments-checkin/LINES.md` pairs
each clip with the line that goes on it, generated from the script and the manifest so the pairing
cannot drift from either.

**Scene 1 is the published page actually being operated**, not a picture of it: the recorder opens
the same URL a judge would, types a symbol, and *waits for the verdict to arrive from mainnet*
before holding the frame. If the page stops answering, the recording throws rather than producing
a still of something that no longer works.

Scene 2's table is the stdout of `./scripts/kamino-reserves.sh` run moments earlier — the same rule
`record.js` follows, and the reason the row count is checked: an earlier take clipped the last three
reserves, which were the Backpack ones the argument is partly about.

Scene durations are read out of `CHECKIN-1.md` rather than repeated in the recorder. The narration
decides them; two places holding the same number is how the Stocklana cut ended up with a manifest
that described a different edit.

## The CWF submission presentation

`presentation.mp4` — eight scenes, silent, at the length its script asks for. **The rough cut, and
not for publication**: its only job is to find out whether the story in
[`CWF-PRESENTATION.md`](CWF-PRESENTATION.md) holds before the week the real video has to exist. The
length is in that file's table, which `pace.py` derives from the narration, and is not repeated
here.

```bash
node video/record-presentation.js   # -> presentation.mp4 + segments-presentation/manifest.json
./video/split.sh presentation       # -> segments-presentation/*.mp4 and LINES.md
```

**It renders from `demo.html`, the same page as the published cut.** Five of its scenes use kinds
that page already had (`leak`, `slot`, `evidence`); three kinds are new (`reserves`, `missing`,
`runnable`). A second renderer would have been a copy of the first within a week. What is *not*
reused is the footage: two scenes of the published cut make claims this script deliberately does
not, so nothing is lifted from `segments/`.

Five of the eight scenes are the stdout of a command run moments before the recording — eight panes
across them — and the recorder throws rather than records if any of them stops carrying its claim.
One of those commands reads **somebody else's repository**: `kamino-verdict.sh`, at a pinned commit,
because scene 5 is a quotation from Kamino Lend and they can change it without telling us. When that
happens the recording should fail, not narrate a line that is no longer there.

`evidence` grew a second pane, `then`, which replaces the text inside the same frame partway
through. Two scenes are built on a withheld line — *"the chain says it holds nothing"* … *"it holds
a hundred and seventy-three thousand"* — and cutting to a new scene for the second half throws away
the fact that it is the same account being looked at.

### Two ways of saying how long a scene is

The published cut was timed by watching it: each scene's `hold` is how long it sits still **after**
it has finished arriving, and how long the arrival took was never written down anywhere. The
presentation's durations are derived from the narration's word counts instead, so they have to mean
the whole scene. A scene given `total` subtracts whatever its own animation spent; one given `hold`
behaves exactly as before.

The arithmetic lives in the page, which is the only thing that knows how long its own animations
take. Putting it in the recorder would have meant the recorder holding a second copy of every
scene's lead-in — the drift this repository keeps having, installed deliberately.

**The render is the check.** `LINES.md` computes each clip's pace from the words in the script and
the length the recorder actually logged — two sources that only agree if the render matched the
narration. A scene that had drifted shows up there as a pace nobody could read.
