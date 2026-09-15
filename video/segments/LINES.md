# The cut, clip by clip

Nine clips in `segments/`, **silent**, cut from `confide.mp4` at the boundaries the page logged
during the render — `segments/manifest.json` is written by `record.js` from those marks, so it
describes the cut that exists rather than the one that was asked for.

Each clip carries one narration block. Generate the voice per clip and lay it back in order; the
clip length is the budget, and the delivery should finish a little before the picture does — about
0.6s of tail is what the earlier recording used, so a line never runs into the next scene.

**`segments/narrated/` is the previous cut.** Those clips carry the recorded human voice over the
eight-scene version with no seizure in it. Nothing here regenerates them; ignore them, or run
`./video/lift-narration.sh` if you want that voice on the new pictures.

| clip | length | words | pace |
|---|---|---|---|
| `01-title.mp4` | 9.6s | 20 | 133 wpm |
| `02-leak.mp4` | 12.5s | 30 | 151 wpm |
| `03-empty-slot.mp4` | 22.8s | 50 | 135 wpm |
| `04-four-views.mp4` | 15.1s | 33 | 137 wpm |
| `05-benefits.mp4` | 19.0s | 47 | 153 wpm |
| `06-live-account.mp4` | 10.6s | 21 | 126 wpm |
| `07-proofs.mp4` | 14.1s | 33 | 147 wpm |
| `08-seizure.mp4` | 14.5s | 29 | 125 wpm |
| `09-close.mp4` | 9.2s | 20 | 140 wpm |

Pace is words over the clip minus 0.6s of tail. Anything much over 180 wpm is reading without
pauses; if a line needs air, raise that scene's `hold` in `record.js` and re-render rather than
speeding up the delivery — one `hold` moves one scene and leaves the others where they are.

---

### `01-title.mp4` — 9.6s · title

> If you hold tokenized stocks on Solana, everyone can see your position. Nobody attacked anything. The chain simply publishes it.

### `02-leak.mp4` — 12.5s · the position climbing, eyes accumulating

> Here is a fund buying NVIDIA through one quarter. Every purchase readable the moment it settles — not after the position is built, but while it is still being built.

### `03-empty-slot.mp4` — 22.8s · four mints, two issuers, auditor key EMPTY

> Solana already shipped the fix. Every tokenized stock here has confidential transfers switched on — eighteen hundred and sixty-nine of them, from two issuers with nothing to do with each other. And every single one leaves the auditor key empty, because the only key on offer reads everyone's everything, forever.

### `04-four-views.mp4` — 15.1s · four columns — the market, a lender, your auditor, you

> Confide fills that slot properly. The market sees nothing. A lender learns one bit: the collateral covers the loan. Your auditor sees the position in full. You choose who, how much, and when.

### `05-benefits.mp4` — 19.0s · five benefits

> Your position stops being public, and you can still prove what you need to. Last quarter's number cannot be tidied afterwards — it is sealed on the reporting date and opened by people you do not control. A stock split does not corrupt what you already disclosed.

### `06-live-account.mp4` — 10.6s · a live devnet account

> This is a real account, right now. The chain says it holds nothing. It holds a hundred and seventy-three thousand shares.

### `07-proofs.mp4` — 14.1s · both proofs accepted

> And this is the lender's check, running on Solana's zero-knowledge program. Two proofs, both accepted — the chain confirmed the collateral covers the loan without ever being told what is in the account.

### `08-seizure.mp4` — 14.5s · and on default, the lender takes it

> And when the loan goes bad, the lender takes it. The borrower signs nothing, no key is reconstructed, nobody is asked — and neither account ever shows what moved.

### `09-close.mp4` — 9.2s · close

> Your position is yours. And you can still prove what you must. Try it yourself — no wallet, no install.

---

## What the narration must not claim

Seizure exists and the script says so. Still off limits:

- **Confide is not a lending protocol.** It takes collateral on a default someone else defines —
  no origination, no interest, no liquidation engine.
- **This is a mirror mint, not `NVDAx`.** Identically configured and one field apart; saying
  otherwise claims an approval from Backed that nobody has given.
- **Devnet, not mainnet.** The picture says so; the voice must not round it up.
