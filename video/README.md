# video

`confide.mp4` — 83s, rendered headlessly (Puppeteer → Chromium → ffmpeg). No screen recording, no
narration track, no external assets, no stock footage: the diagrams are SVG and CSS in the page.

It leads with what a holder gets, not with how the mechanism works. The terminal is demoted to
evidence at the end, stamped *real output, just now*, because a video made of terminal panes reads
as a research artifact rather than a product — which is the wrong thing to be, for a question that
asks whether people would use this.

```bash
npm install
npm run record        # -> confide.mp4   (needs ffmpeg; FFMPEG_PATH overrides /opt/homebrew/bin/ffmpeg)
```

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
