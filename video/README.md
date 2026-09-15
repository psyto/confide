# video

**Published: https://youtu.be/ZuhLvH5MFgE** — still the cut that says 732 mints and one issuer, on a
confidential account that no longer exists. **`Confide_Stocklana_20260915.mp4` is the replacement**:
the current render, the recorded narration, and the subtitle track carried across. Ready to upload.

`confide.mp4` — 1:52 silent master, rendered headlessly (Puppeteer → Chromium → ffmpeg). No screen recording, no
narration track, no external assets, no stock footage: the diagrams are SVG and CSS in the page.

```bash
npm run record          # -> confide.mp4, reading the account out of account-keys.json
../video/split.sh       # -> segments/, cut at the boundaries the page logged
../video/lift-narration.sh  # -> segments/narrated/, the recorded voice back onto them
../video/join.sh        # -> confide-narrated.mp4
```

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
