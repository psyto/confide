# YouTube

For `Confide_Stocklana_20260923.mp4` — the narrated presentation, 2:32.

**The chapters are generated, not typed.** `SRT=video/captions-20260923.srt TITLES=video/CWF-PRESENTATION.md
./scripts/video-chapters.sh video/Confide_Stocklana_20260923.mp4` reads them off the delivered
file by locating each scene's opening words in its own caption track, because the voice paces
differently from the silent master and the recorder's plan is never the file. The published
Stocklana cut once carried chapter times belonging to a different edit for exactly that reason.

**Upload `video/captions-20260923.srt` as the caption track.** The embedded one is ASR, and this
time it did worse than mishear: it **dropped the whole of scene 5**, 57.3s to 78.2s, with the voice
present at -21.4 dB throughout. `fix-captions.sh` corrects the words and `caption-gap.py` writes the
missing scene back from the script.

## Title — 86 / 100 characters

```
Confide — swap tokenized stocks for stablecoins on Solana, without publishing the size
```

## Description — 4993 / 5000 characters

```
Confide settles a tokenized-stock trade against stablecoins in ONE Solana transaction, and neither side publishes what moved. On devnet today.

A real Solana account reports a balance of zero. It holds 173,000 shares of tokenized stock — and nobody has been allowed to open one.

On 17 September the SEC gave tokenized stock five years of relief, and set the conditions: AMM-executed trading only, every fill's size, time and direction published within ten minutes, a Tier 1 name capped at 0.25% of daily volume. Block trades have always settled away from that tape. Nobody had built the block. Confide is not a venue, so the exemption neither covers it nor is needed.

▶ Decode the trades in a browser: https://psyto.github.io/confide/
▶ Code, Apache-2.0: https://github.com/psyto/confide

━━━━━━━━━━━━━━━━━━━━━━

CHAPTERS

0:00 This account
0:10 And nobody has been allowed one
0:28 Confide
0:43 The trade
0:57 Why the door is shut
1:18 Why now
1:36 So the first trade is an issuance
1:45 The gate, both ways
1:57 Why not just use an exchange
2:11 What I got wrong, and what you can run

━━━━━━━━━━━━━━━━━━━━━━

THE MEASUREMENT NOBODY HAD MADE

All 1,992 tokenized-equity mints on Solana, from three unrelated issuers, run Token-2022 with confidential transfers ON and the auditor key EMPTY. Every mint checked, not sampled.

They did not miss it. The same 1,992 carry permanentDelegate, pausableConfig and a transfer hook — the issuer can freeze a transfer, seize a holder's tokens, run their own code. Token-2022's only disclosure model is mint-wide: one auditor key, reading every transfer while it is set, scoped to nobody. Everybody readable, or nobody. So every issuer left it empty.

Then the half nobody counted: has anybody USED it? 490,673 live token accounts across Apple, NVIDIA, SpaceX and AMC. THREE have configured a confidential account — two on NVDAx, one on AAPLx. ZERO are approved — none until an issuer signs.

Not only equities: PYUSD and USDG land on the same configuration.

WHICH MAKES THE FIRST TRADE AN ISSUANCE

The party who can open a confidential account is one of the two parties to the trade — so the first trade through that gate is not a swap between holders. It is an issuance.

On devnet today: an issuer allocates 20,000 shares against $3,500,000 of stablecoin. Sent before the issuer had signed for the account, the chain REFUSED it — Custom(24), "Account not approved for confidential transfers". One instruction later, the same transaction SETTLED.

Then between two strangers sharing nothing but public keys: 50,000 shares against $8,750,000, one transaction. Neither published the size, the price it implies, or that they held anything. All four accounts still read zero.

WHAT CONFIDE ACTUALLY DOES

Delivery versus payment is what a clearing house exists for: neither side goes first, so finance inserts a central counterparty, margin and a day of lag. A Solana transaction is all-or-nothing, so the transaction IS the clearing house, and Confide holds nobody's assets.

The work is around that. Confidential transfers need zero-knowledge proofs too large for a transaction, so they are verified into context accounts first and cited by address; on a fee-charging mint that leg takes a different instruction and five proofs instead of three, one staged through a record account. Before signing, each side decrypts the other's amount out of the verified context, rebuilds the transaction and compares it byte for byte.

WHY NOT AN EXCHANGE, AND WHAT I GOT WRONG

You cannot use one. A pool's reserves are public state and a trade moves them by exactly the amount traded — subtract two states and you have the size, whatever the token can do. It has to be two parties, directly. The SEC wrote the same down.

I also called one of these checks the safety step. A review found it was signing an object it had never compared to the one it showed you. The rebuild-and-compare is the fix, and caught a second bug on its first run. Every review is committed under docs/reviews/.

GO AND DO IT YOURSELF

A standing devnet issuer is gated exactly as all 1,992 are, its approval key published. So you can open a confidential position and hold something the chain reads as zero:

  git clone https://github.com/psyto/confide
  ./scripts/testbed-join.sh

Needs the Solana CLI, Rust and some devnet SOL.

WHAT IS NOT BUILT

The gate on a real mint: the demo's issuer is a testbed whose approval key is mine. Matching is unsolved — settlement is done, finding the counterparty is not, and that is the exchange definition at Rule 3b-16, so it stays off. Price is agreed off chain. No pilot, no user, no issuer asked.

Every figure came off the chain, and one command reproduces each. Devnet resets; healthcheck.sh re-checks them.

BUILT ON

Original work except where declared: aperture-core and aperture-receipts (Apache-2.0, my pre-existing engine) and spl-token-2022-interface. The swap, the seizure program, the proofs, the equity layer and the demo are new.
```

## Notes

- **The product was below the fold.** The description opened on the account that reads zero and
  did not name Confide until **character 418 of 4,999** — and YouTube collapses the description at
  about 157, so what a judge scanning a list actually saw was a hook and half a sentence about the
  SEC. When the name did arrive it was in a clause saying what Confide *is not*: *"not a venue, so
  the exemption neither covers it nor is needed."*

  **This is the hero-at-38-seconds problem in text**, and it was fixed in the film a day earlier by
  putting the wordmark on the first frame. The first line now states the product and fits inside
  the fold with room to spare; the account hook is the second line, where it still does its work.
  A description is skimmed by somebody deciding whether to press play.

- **Rewritten 2026-09-23 for the restructured cut.** The previous copy was written for
  `Confide_Stocklana_20260920.mp4` and had gone stale in the way that is hardest to notice: every
  sentence in it was still true. What had changed was the *order* — and the chapter list, which is
  the one part a reader uses as a map, named ten scenes that no longer exist.

- **The issuance was missing entirely.** The description carried the two-party swap and the
  measurement, and said nothing about the gate refusing on chain — which is the newest work in the
  submission and the only place a viewer sees the thing the film is about actually stop something.

- **The title has failed twice in the same way, and the second time was mine.** The first read
  *"50,000 shares for $8.75m in one transaction, and the chain shows zero"* — zero *what*, to
  somebody who has not seen the video? The 09-23 draft read *"the SEC opened tokenized stock.
  Nobody can trade size on a tape that publishes it"*, which leads with the argument and asks a
  stranger to already hold two pieces of desk language: **trade size** as a verb phrase, and **the
  tape**. The description has room to set those up and a title does not. It also never said what
  Confide does.

  This one names the product, both assets, the chain and the claim, in words that need nothing
  before them. **A title is read by somebody scanning a list, not by somebody who has watched the
  film.**

- The description says **zero** about traction because there is none, and says so plainly.
- It names what cannot be done as plainly as what can: the real gate, matching, price, and pools.
- The chapter titles are the script's own scene names, so a viewer scanning them reads the
  argument in order.
