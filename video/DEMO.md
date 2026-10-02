# The demo video — ≤3 minutes, the live product

**The form asks for the live product, not a slide deck.** The picture is
[`demo-ops.mp4`](demo-ops.mp4): the settlement-operations view (`/ops`) of the local demo app driving
`scripts/issue-e2e.sh` on **devnet**, recorded in Chromium by [`record-app.js`](record-app.js). Every
refusal, check and settlement on screen is a checkpoint the script wrote after its own check. The
story it follows is [`docs/cwf-2026/STORY.md`](../docs/cwf-2026/STORY.md) §4.

**One edit, and it is on screen.** [`cut-app.js`](cut-app.js) plays the middle of each devnet wait
faster and shows a badge with the real duration while it does; nothing is removed or reordered.
Every shortened stretch is in [`demo-ops.manifest.json`](demo-ops.manifest.json).

**The narration draws the same line the screen does.** Token-2022 and Solana enforce the rules —
the refusals are theirs, and the narration says so. Confide does the work around them: it builds the
proofs, checks the amount before signing, pins the terms, verifies the transaction, and assembles
both legs into one. Nothing of Confide's runs inside the trade.

This replaces the 2026-09-30 script for the terminal demo, which followed `issue-e2e.sh`'s output and
had no act 2. The time range under each scene is where it sits in `demo-ops.mp4`, written by
`python3 video/demo-times.py` from the manifest — re-run it after any re-cut.

## Length

Derived by `python3 video/pace.py` from the words below. **Do not edit this table by hand** — it is
rewritten with `--write`, and it drifted from the words within minutes of both being written the one
time it was maintained any other way.

**The voice has to fit under the picture** — `cut_seconds` in `demo-ops.manifest.json`, and each scene
under its own range, which `python3 video/demo-times.py` writes from the same file. The figure below is a prediction at 137
words a minute, and check-in 2 came out about four per cent long (`STATUS.md`, 0i), so the script is
held about 4% under the video rather than at it.

| | scene | seconds (+ silence) | words | pace | what it shows |
|---|---|---|---|---|---|
| 1 | a stock shut the way the real ones are | 20 | 44 | 136 | 0:00–0:21 — both mints appear under MINT POLICY with `APPROVAL REQUIRED · auditor: none`; the investor's cash account is approved and funded, then its stock account lands in the approval queue as `PENDING`. The blotter's `done by` column reads `TOKEN-2022` for all of it |
| 2 | Confide builds the proofs and checks the amount | 11 | 24 | 138 | 0:21–0:33 — the Act 1 ticket appears (20,000 shares ⇄ $3,500,000), `PROOFS BUILT · CHAIN-VERIFIED` and `PRE-SIGN CHECK` turn green with `CONFIDE` beside them, and the first two lines of CONFIDE IN THIS RUN tick |
| 3 | the gate holds | 14 | 30 | 134 | 0:33–0:49 — `SENT BEFORE APPROVAL · TOKEN-2022` turns red; the blotter shows `REFUSED · Custom(24)` with its signature, then `REFUSED · not the authority`; the queue marks the account `SELF-APPROVAL REFUSED` |
| 4 | approval, then one transaction | 20 | 45 | 139 | 0:49–1:11 — `ISSUER APPROVES` green, `ONE SIGNATURE ONLY · SOLANA` red, then `BOTH SIGNATURES · SETTLED · CONFIDE + TOKEN-2022` with the settlement signature and its compute units |
| 5 | what anyone can see | 15 | 34 | 142 | 1:11–1:28 — the public ledger, every account `0` and `ENCRYPTED`, and under it WHO WOULD READ THIS TRADE'S AMOUNT ELSEWHERE, labelled a sourced comparison and not a run result: a public DEX swap read by everyone, with this trade's own 20,000 shares · $3,500,000; a centralized exchange read by the exchange; Renegade's dark pool read by its relayer; Confide with no auditor key, the two parties' keys and a public balance of 0 in this run. Each row is sourced in `docs/cwf-2026/COMPARABLES.md` |
| 6 | two approved holders trade | 28 | 63 | 138 | 1:28–1:58 — the Act 2 ticket (5,000 ⇄ $875,000): `TERMS PINNED` on both sides, `INVESTOR CHECK`, `HOLDER 2 CHECK + BINDING`, then `BOTH SIGNATURES · SETTLED`, every stage marked `CONFIDE` |
| 7 | the short-delivery control | 24 + 12 | 54 | 138 | 1:58–2:36 — a fresh run's setup, fast-forwarded with its badge (the silence sits here, before "Before any signature exists"), then `PRE-SIGN CHECK · CONFIDE` turns red and the ticket reads `investor decrypted 2,000 shares · agreed 20,000 → REFUSED, nothing signed` |
| 8 | what Confide did | 14 | 31 | 139 | 2:36–2:51 — the final frame held: CONFIDE IN THIS RUN with its ticks, the red pre-sign check, the blotter reading `SHORT · REFUSED — CONFIDE` |
| | | **158 s** | **325** | | |

## The script

### 1 — a stock shut the way the real ones are

> This is Confide on devnet, in a local demo where one presenter holds every key; chain waits are
> fast-forwarded, real time on the badge. The stock mint carries the two settings we found on all
> 1,992 measured equity mints: approval required, no auditor key.

*Shows:* 0:00–0:21 — both mints appear under MINT POLICY with `APPROVAL REQUIRED · auditor: none`;
the investor's cash account is approved and funded, then its stock account lands in the approval
queue as `PENDING`. The blotter's `done by` column reads `TOKEN-2022` for all of it.

### 2 — Confide builds the proofs and checks the amount

> A new investor account waits for approval. Confide builds both legs' proofs, the chain verifies
> them, and the investor checks the amount before signing.

*Shows:* 0:21–0:33 — the Act 1 ticket appears (20,000 shares ⇄ $3,500,000), `PROOFS BUILT ·
CHAIN-VERIFIED` and `PRE-SIGN CHECK` turn green with `CONFIDE` beside them, and the first two lines
of CONFIDE IN THIS RUN tick.

### 3 — the gate holds

> The issuer sends the allocation; Token-2022 refuses it: the account isn't approved. The investor
> tries approving itself: refused. Only the mint's approval authority, here the issuer's key, can
> open it.

*Shows:* 0:33–0:49 — `SENT BEFORE APPROVAL · TOKEN-2022` turns red; the blotter shows `REFUSED ·
Custom(24)` with its signature, then `REFUSED · not the authority`; the queue marks the account
`SELF-APPROVAL REFUSED`.

### 4 — approval, then one transaction

> The issuer approves exactly this account. With only the issuer's signature, the RPC rejects it; it
> never enters a block. With the investor's signature added, the same transaction settles: twenty
> thousand shares for three and a half million dollars, one atomic transaction that Confide
> assembled.

*Shows:* 0:49–1:11 — `ISSUER APPROVES` green, `ONE SIGNATURE ONLY · SOLANA` red, then `BOTH
SIGNATURES · SETTLED · CONFIDE + TOKEN-2022` with the settlement signature and its compute units.

### 5 — what anyone can see

> Accounts and transactions stay public; every balance here reads zero. On a public DEX, everyone
> would read this size; on a centralized exchange, the exchange would. Here, only the two parties'
> keys open it.

*Shows:* 1:11–1:28 — the public ledger, every account `0` and `ENCRYPTED`, and under it WHO WOULD READ THIS
TRADE'S AMOUNT ELSEWHERE, labelled a sourced comparison and not a run result: a public DEX swap read by everyone,
with this trade's own 20,000 shares · $3,500,000; a centralized exchange read by the exchange;
Renegade's dark pool read by its relayer; Confide with no auditor key, the two parties' keys and a
public balance of 0 in this run. Each row is sourced in `docs/cwf-2026/COMPARABLES.md`.

### 6 — two approved holders trade

> The investor offers five thousand shares for eight hundred
> seventy-five thousand dollars, terms agreed off chain. Confide pins them on each side before any
> proof exists; each side checks what it receives against its pin, and the second signer
> verifies the exact transaction. It settles atomically. With no mint-wide auditor key, the
> issuer's approval does not make it a reader of the amounts.

*Shows:* 1:28–1:58 — the Act 2 ticket (5,000 ⇄ $875,000): `TERMS PINNED` on both sides, `INVESTOR
CHECK`, `HOLDER 2 CHECK + BINDING`, then `BOTH SIGNATURES · SETTLED`, every stage marked `CONFIDE`.

### 7 — the short-delivery control · + 12 s silence

> Now the control. The issuer builds its leg for two thousand shares instead of twenty thousand; the
> proofs are valid, only the encrypted amount is wrong. Before any signature, the investor's Confide
> client decrypts the amount addressed to it, finds two thousand where twenty thousand was agreed,
> and refuses. Nothing is signed. Nothing moves.

*Shows:* 1:58–2:36 — a fresh run's setup, fast-forwarded with its badge (the silence sits here, before
"Before any signature exists"), then `PRE-SIGN CHECK · CONFIDE` turns red and the ticket reads
`investor decrypted 2,000 shares · agreed 20,000 → REFUSED, nothing signed`.

### 8 — what Confide did

> Token-2022 and Solana enforce the rules; Confide builds the proofs, checks before signing, pins the
> terms, and assembles one transaction. Not a venue, no matching. Devnet only; no real issuer yet.

*Shows:* 2:36–2:51 — the final frame held: CONFIDE IN THIS RUN with its ticks, the red pre-sign check,
the blotter reading `SHORT · REFUSED — CONFIDE`.

## What this video does not claim

Named here so the narration does not have to carry it, and so a reviewer can see the boundary was
drawn on purpose:

- **Devnet, and a local demo.** Every key is held by the machine running it; the panes are one
  presenter's view, not separate wallets. No mainnet deployment exists, deliberately —
  [`docs/27-DAYS.md`](../docs/27-DAYS.md) refuses it under *Refused*, with the reason.
- **No real issuer has approved anything.** The issuer here is a keypair this repository holds.
  Nobody has been through that door on the mints whose accounts were counted, and nobody has asked
  an issuer.
- **The refusals are Token-2022's and Solana's**, not Confide's, and the screen labels them so. The
  one-signature refusal is an RPC preflight rejection; that transaction never entered a block.
- **Confidential balances hide amounts, not identities.** Accounts, the mint and the fact of a
  transfer are public — scene 5 shows exactly that.
- **"No auditor key" is not selective disclosure.** It means no mint-wide transfer auditor is set.
  Token-2022 offers one mint-wide key or none.
- **The price is agreed off chain.** $175.00 a share is cash over shares, labelled so on screen; no
  market data exists in the demo.
- **Fast-forwarded stretches are devnet waiting**, badged with their real length, said aloud in scene
  1, and listed in the manifest.
