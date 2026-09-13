# segments

`confide.mp4` cut at the measured scene boundaries, one clip per narration block in
[`../voiceover.md`](../voiceover.md). Durations sum to 83.10s exactly — the cuts are frame-accurate
re-encodes, not `-c copy`, which would have snapped to keyframes and drifted.

| clip | in the cut | length | words | wpm |
|---|---|---|---|---|
| `01-title.mp4` | 0:00 | 7.50s | 20 | 160 |
| `02-leak.mp4` | 0:07 | 10.00s | 30 | 180 |
| `03-empty-slot.mp4` | 0:17 | 10.70s | 37 | **207** |
| `04-four-views.mp4` | 0:28 | 10.80s | 33 | 183 |
| `05-benefits.mp4` | 0:39 | 13.70s | 47 | **205** |
| `06-live-account.mp4` | 0:52 | 10.00s | 21 | 126 |
| `07-proofs.mp4` | 1:02 | 12.00s | 33 | 165 |
| `08-close.mp4` | 1:14 | 8.40s | 20 | 142 |

**Two of these are too fast to narrate comfortably.** Unhurried delivery is 140–165 wpm; `03` and
`05` sit above 200, which means reading without pauses. Either shorten those two lines, or give the
scenes more room — `hold` in `../record.js` lengthens one scene without moving the others. Bringing
both to ~165 wpm needs about +2.8s on `03` and +3.4s on `05`, taking the cut to roughly 89s.

`manifest.json` carries the same table plus each line, for anything that wants to read it.

## Recording

Record against each clip and save the narrated version into `narrated/` under the **same filename**.
Then:

```bash
./video/join.sh              # -> video/confide-narrated.mp4
```

Missing files fall back to the silent original, so you can do one segment at a time and rejoin after
each to hear it in place. Silent parts get an empty audio track first, because `concat` drops audio
for the whole file if any part lacks one.
