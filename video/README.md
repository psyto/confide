# video

`confide.mp4` — 97s, rendered headlessly (Puppeteer → Chromium → ffmpeg). No screen recording, no
narration track, no external assets.

```bash
npm install
npm run record        # -> confide.mp4   (needs ffmpeg; FFMPEG_PATH overrides /opt/homebrew/bin/ffmpeg)
```

## The terminal in it is not a transcription

Every pane is the stdout of a command run moments before the recording starts:

| pane | command | reaches |
|---|---|---|
| the two lanes, the seal, the refusal, the opening | `cargo run -p confide-demo --bin two-lane` | local |
| every xStock mint and its empty auditor slot | `scripts/onchain-check.sh` | **mainnet** |
| the covenant proof accepted by the ZK program | `scripts/devnet-verify.sh` | **devnet** |

`record.js` asserts on the lines that carry the claims — `REFUSED`, `LANE B is now public`,
`173,000 NVDAx`, four empty auditor slots, `err: None`, `VerifyBatchedRangeProofU64`, `success` —
and **throws rather than recording** if any of them is missing. A video that says something the code
did not do is worse than no video, and the failure mode it guards against is the quiet one: a demo
that still renders after the thing it demonstrates stopped working.

`puppeteer` is pinned to `19.0.0` because `puppeteer-screen-recorder@3.0.6` requires exactly that.
