# segments

`confide.mp4` cut at the scene boundaries, one clip per narration block in
[`../voiceover.md`](../voiceover.md). Frame-accurate re-encodes, not `-c copy`.

**Only `03-empty-slot` changed.** Backpack Securities turned out to be a second issuer leaving the
same slot empty, so that scene now shows two issuers and says 1,869 instead of 732 — and its line
is longer, 16.60s to 22.80s. Every other clip is visually identical to the take the narration was
recorded against (checked by comparing frames, not by assuming), so **its recorded audio still
fits**. The one wrinkle: `07-proofs` came out 0.10s shorter than before, 14.10s to 14.00s, which
its 13.47s line still clears.

| clip | at | length | narration | headroom | audio |
|---|---|---|---|---|---|
| `01-title.mp4` | 0:00 | 9.60s | 9.03s | 0.57s | **reuse** |
| `02-leak.mp4` | 0:09 | 12.50s | 11.93s | 0.57s | **reuse** |
| `03-empty-slot.mp4` | 0:22 | 22.80s | 21.13s | 1.67s | **re-record** |
| `04-four-views.mp4` | 0:44 | 15.10s | 14.43s | 0.67s | **reuse** |
| `05-benefits.mp4` | 1:00 | 19.00s | 18.43s | 0.57s | **reuse** |
| `06-live-account.mp4` | 1:19 | 10.60s | 10.00s | 0.60s | **reuse** |
| `07-proofs.mp4` | 1:29 | 14.00s | 13.47s | 0.53s | **reuse** |
| `08-close.mp4` | 1:43 | 9.20s | 8.57s | 0.63s | **reuse** |

Total **1:52**. The `narration_seconds` for the seven unchanged clips are measured from the first
recording. `03` is an estimate at 142 wpm — the rate that recording actually ran at — with 1.7s of
slack, because an over-long scene is a beat of silence and a short one is white.

## Putting it together

Compositing happens in Google Vids, not here — import the clips in order and lay the narration over
them. [`LINES.md`](LINES.md) is the recording sheet: one line per clip with its length and slack.

`narrated/` holds seven of the eight clips with the original voice already on them, recovered from
`../Confide_Stocklana_20260913.mp4` by `../lift-narration.sh` (the takes were never kept separately).
Import those and only `03` needs recording.

`../join.sh` still exists and stitches `narrated/` back together offline, falling back to the silent
original for anything missing. **Its output is not currently trusted:** the joined file measured
longer than the sum of its parts and the audio appeared to start late in one scene, and I stopped
investigating when compositing moved to Google Vids. The individual clips in `narrated/` were each
verified on their own and are fine; it is the concatenation that is unverified.

## If the narration changes again

The page logs `CONFIDE_SCENE <kind> <seconds>` during a run, and each scene's length is `hold` in
`../record.js` plus a fixed animation cost. Raising one `hold` lengthens that scene alone — which is
exactly what happened here, and why seven of the eight takes survived.
