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
had no act 2. The timestamps under each scene are where that scene sits in `demo-ops.mp4` as cut on
2026-09-30; if the video is re-recorded they move, and so must these.

## Length

Derived by `python3 video/pace.py` from the words below. **Do not edit this table by hand** — it is
rewritten with `--write`, and it drifted from the words within minutes of both being written the one
time it was maintained any other way.

**The voice has to fit under the picture: 175.7 seconds.** The figure below is a prediction at 137
words a minute, and check-in 2 came out about four per cent long (`STATUS.md`, 0i), so the script is
held about 4% under the video rather than at it.

| | scene | seconds (+ silence) | words | pace | what it shows |
|---|---|---|---|---|---|
| 1 | a stock shut the way the real ones are | 21 | 47 | 138 | 0:00–0:23 — both mints appear under MINT POLICY with `APPROVAL REQUIRED · auditor: none`; the investor's cash account is approved and funded, then its stock account lands in the approval queue as `PENDING`. The blotter's `done by` column reads `TOKEN-2022` for all of it |
| 2 | Confide builds the proofs and checks the amount | 12 | 26 | 137 | 0:23–0:36 — the Act 1 ticket appears (20,000 shares ⇄ $3,500,000), `PROOFS BUILT · CHAIN-VERIFIED` and `PRE-SIGN CHECK` turn green with `CONFIDE` beside them, and the first two lines of CONFIDE IN THIS RUN tick |
| 3 | the gate holds | 15 | 33 | 138 | 0:36–0:51 — `SENT BEFORE APPROVAL · TOKEN-2022` turns red; the blotter shows `REFUSED · Custom(24)` with its signature, then `REFUSED · not the authority`; the queue marks the account `SELF-APPROVAL REFUSED` |
| 4 | approval, then one transaction | 20 | 44 | 136 | 0:51–1:13 — `ISSUER APPROVES` green, `ONE SIGNATURE ONLY · SOLANA` red, then `BOTH SIGNATURES · SETTLED · CONFIDE + TOKEN-2022` with the settlement signature and its compute units |
| 5 | what anyone can see | 8 | 16 | 130 | 1:13–1:21 — the public ledger, every account `0` and `ENCRYPTED`; beside it, each holder's position read with its own key, labelled as shown together only because one presenter holds every key |
| 6 | two approved holders trade | 31 | 70 | 138 | 1:21–1:53 — the Act 2 ticket (5,000 ⇄ $875,000): `TERMS PINNED` on both sides, `INVESTOR CHECK`, `HOLDER 2 CHECK + BINDING`, then `BOTH SIGNATURES · SETTLED`, every stage marked `CONFIDE` |
| 7 | the short-delivery control | 26 + 12 | 58 | 137 | 1:53–2:34 — a fresh run's setup, fast-forwarded with its badge (the silence sits here, before "Before any signature exists"), then `PRE-SIGN CHECK · CONFIDE` turns red and the ticket reads `investor decrypted 2,000 shares · agreed 20,000 → REFUSED, nothing signed` |
| 8 | what Confide did | 20 | 45 | 139 | 2:34–2:56 — the final frame held: CONFIDE IN THIS RUN with its ticks, the red pre-sign check, the blotter reading `SHORT · REFUSED — CONFIDE` |
| | | **165 s** | **339** | | |

## The script

### 1 — a stock shut the way the real ones are

> This is Confide, running on devnet. The issuer creates a tokenized stock and a cash token,
> configured like every tokenized stock we measured: confidential transfers on, new accounts need
> the issuer's approval, no auditor key. An investor opens a confidential account. It sits in the
> queue, pending.

*Shows:* 0:00–0:23 — both mints appear under MINT POLICY with `APPROVAL REQUIRED · auditor: none`;
the investor's cash account is approved and funded, then its stock account lands in the approval
queue as `PENDING`. The blotter's `done by` column reads `TOKEN-2022` for all of it.

### 2 — Confide builds the proofs and checks the amount

> Confide builds both legs' zero-knowledge proofs, and the chain verifies them. Before signing, the
> investor's side decrypts its own amount and compares it with the deal.

*Shows:* 0:23–0:36 — the Act 1 ticket appears (20,000 shares ⇄ $3,500,000), `PROOFS BUILT ·
CHAIN-VERIFIED` and `PRE-SIGN CHECK` turn green with `CONFIDE` beside them, and the first two lines
of CONFIDE IN THIS RUN tick.

### 3 — the gate holds

> The issuer sends the allocation. Token-2022 refuses it: the account isn't approved. The investor
> tries approving itself — refused. Only the issuer's key opens this gate. Confide works through it,
> not around it.

*Shows:* 0:36–0:51 — `SENT BEFORE APPROVAL · TOKEN-2022` turns red; the blotter shows `REFUSED ·
Custom(24)` with its signature, then `REFUSED · not the authority`; the queue marks the account
`SELF-APPROVAL REFUSED`.

### 4 — approval, then one transaction

> The issuer approves exactly this account. Sent with only the issuer's signature, Solana rejects it.
> With the investor's signature added to that same transaction, it settles: twenty thousand shares
> against three and a half million dollars, both legs in one transaction, assembled by Confide.

*Shows:* 0:51–1:13 — `ISSUER APPROVES` green, `ONE SIGNATURE ONLY · SOLANA` red, then `BOTH
SIGNATURES · SETTLED · CONFIDE + TOKEN-2022` with the settlement signature and its compute units.

### 5 — what anyone can see

> From outside: every account, every transaction, and a public balance of zero. The amounts are
> encrypted.

*Shows:* 1:13–1:21 — the public ledger, every account `0` and `ENCRYPTED`; beside it, each holder's
position read with its own key, labelled as shown together only because one presenter holds every
key.

### 6 — two approved holders trade

> The issuer approves a second holder. The investor offers five thousand shares for eight hundred and
> seventy-five thousand dollars. Confide pins those terms on each side before any proof exists. Each
> side checks what it will receive against its own pin, and the second signer confirms the
> transaction is exactly the one it checked. It settles in one transaction. The issuer approved the
> accounts; its key cannot read the amounts.

*Shows:* 1:21–1:53 — the Act 2 ticket (5,000 ⇄ $875,000): `TERMS PINNED` on both sides, `INVESTOR
CHECK`, `HOLDER 2 CHECK + BINDING`, then `BOTH SIGNATURES · SETTLED`, every stage marked `CONFIDE`.

### 7 — the short-delivery control · + 12 s silence

> Now the control. The same allocation, except the issuer builds its leg for two thousand shares
> instead of twenty thousand. The proofs are valid; only the amount is wrong, and the amount is
> encrypted. Before any signature exists, Confide decrypts the investor's leg, finds two thousand
> where twenty thousand was agreed, and refuses. Nothing is signed. Nothing moves.

*Shows:* 1:53–2:34 — a fresh run's setup, fast-forwarded with its badge (the silence sits here, before
"Before any signature exists"), then `PRE-SIGN CHECK · CONFIDE` turns red and the ticket reads
`investor decrypted 2,000 shares · agreed 20,000 → REFUSED, nothing signed`.

### 8 — what Confide did

> Token-2022 and Solana enforce the rules. Confide does the work around them: it builds the proofs,
> checks before signing, pins the terms, and assembles delivery and payment into one transaction.
> This is devnet, and no real issuer has used it yet. That conversation is next.

*Shows:* 2:34–2:56 — the final frame held: CONFIDE IN THIS RUN with its ticks, the red pre-sign check,
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
- **The refusals are Token-2022's and Solana's**, not Confide's, and the screen labels them so.
- **Confidential balances hide amounts, not identities.** Accounts, the mint and the fact of a
  transfer are public — scene 5 shows exactly that.
- **"No auditor key" is not selective disclosure.** It means no mint-wide transfer auditor is set.
  Token-2022 offers one global key or none.
- **The price is agreed off chain.** $175.00 a share is cash over shares, labelled so on screen; no
  market data exists in the demo.
- **Fast-forwarded stretches are devnet waiting**, badged with their real length, and listed in the
  manifest.
