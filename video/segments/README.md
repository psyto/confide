# segments

`confide.mp4` cut at the scene boundaries, one clip per narration block in
[`../voiceover.md`](../voiceover.md). Frame-accurate re-encodes, not `-c copy`.

**The clip table lives in [`LINES.md`](LINES.md), and only there.** It used to be repeated here,
and when the cut gained a ninth scene this file went on describing the eight-scene one — the same
way `manifest.json` went on describing it until `record.js` started writing it. One place per fact.

**Nine clips, 2:07.** The ninth is `08-seizure`, between the lender's check and the close: a lender
can now take the collateral, so the cut says so. Adding it renamed the close from `08-` to `09-`.

**Every clip needs new audio.** The previous recording was made against the eight-scene cut, and
while seven of those clips are visually unchanged, this cut is being voiced elsewhere rather than
re-using takes. `LINES.md` carries the line, the length and the pace for each.

## Putting it together

Compositing happens in Google Vids, not here — import the clips in order and lay the narration over
them. [`LINES.md`](LINES.md) is the recording sheet: one line per clip with its length and slack.

`narrated/` holds clips from the **eight-scene cut** with the original voice on them, recovered from
a published render by `../lift-narration.sh` (the takes were never kept separately). They do not
match this cut — the filenames alone disagree, since `08` is the seizure here and the close there.
Kept because they are the only copy of that voice outside the published video; ignore them unless
you are going back to that cut.

`../join.sh` stitches `narrated/` back together offline, falling back to the silent original for
anything missing. It was marked untrusted here on 09-15 after the joined audio looked misaligned;
that was a measurement error on my side - `-ss` before `-i` snaps to a keyframe, and a raw PCM dump
with DTS warnings is not a clock. Measured properly, the rejoined file has the same 32 silence
regions as the source composite, drifting monotonically from 0 to 0.114s across 113 seconds. That is
the AAC encoder priming delay, about 14ms per segment, against at least 0.33s of lead-in silence in
every scene. The individual clips in `narrated/` were each
verified on their own and are fine; it is the concatenation that is unverified.

## If the narration changes again

The page logs `CONFIDE_SCENE <kind> <seconds>` during a run, and each scene's length is `hold` in
`../record.js` plus a fixed animation cost. Raising one `hold` lengthens that scene alone — which is
exactly what happened here, and why seven of the eight takes survived.
