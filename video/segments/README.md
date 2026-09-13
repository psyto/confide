# segments

`confide.mp4` cut at the scene boundaries, one clip per narration block in
[`../voiceover.md`](../voiceover.md). Frame-accurate re-encodes, not `-c copy`, which snaps to
keyframes and drifts.

**These are sized to the recorded narration, not to a guess.** The first cut ran 83.10s against
101.93s of voice, so every scene ended before its line did and the assembly showed white between
them. The shortfall per scene was measured off those white frames — `signalstats` over
`Confide_Stocklana_20260913.mp4`, looking for runs where average luma jumped from ~24 to ~235 —
and the `hold` values in `../record.js` were set from that.

| clip | at | length | narration | headroom |
|---|---|---|---|---|
| `01-title.mp4` | 0:00 | 9.60s | 9.03s | 0.57s |
| `02-leak.mp4` | 0:09 | 12.50s | 11.93s | 0.57s |
| `03-empty-slot.mp4` | 0:22 | 16.60s | 16.07s | 0.53s |
| `04-four-views.mp4` | 0:38 | 15.10s | 14.43s | 0.67s |
| `05-benefits.mp4` | 0:53 | 19.00s | 18.43s | 0.57s |
| `06-live-account.mp4` | 1:12 | 10.60s | 10.00s | 0.60s |
| `07-proofs.mp4` | 1:23 | 14.10s | 13.47s | 0.63s |
| `08-close.mp4` | 1:37 | 9.20s | 8.57s | 0.63s |

Total **106.70s** of picture against **101.93s** of voice. Roughly 0.6s of tail per scene, so the
image settles after the last syllable instead of cutting on it.

`manifest.json` carries the same table plus each line.

## Putting it together

Narrated versions go in `narrated/` under the **same filenames**, then:

```bash
./video/join.sh              # -> video/confide-narrated.mp4
```

Missing files fall back to the silent original, so you can do one at a time and rejoin after each.
Silent parts get an empty audio track first, because `concat` drops audio for the whole file if any
part lacks one.

## If the narration changes

Re-time rather than re-guess: the page logs `CONFIDE_SCENE <kind> <seconds>` during a run, and each
scene's length is `hold` in `../record.js` plus a fixed animation cost (1.0–5.0s depending on the
scene). Raising one `hold` lengthens that scene alone.
