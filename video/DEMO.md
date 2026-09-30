# The demo video — ≤3 minutes, the live product

**The form asks for the live product, not a slide deck.** So this is one terminal and one browser,
and everything on screen is the output of a command the viewer can run. Nothing is drawn.

    RPC=<devnet endpoint> ./scripts/issue-e2e.sh
    RPC=<devnet endpoint> SHORT=2000 ./scripts/issue-e2e.sh

It is **devnet**, and the script says so out loud in scene 1. The mint is configured exactly as the
live tokenized-equity mints are — `autoApproveNewAccounts: false`, auditor slot empty — which is
what makes the refusal in scene 3 the real thing rather than a staged one. It is not a real security
and nothing here makes one pledgeable.

**Why this flow and not the swap.** [`docs/27-DAYS.md`](../docs/27-DAYS.md) named `swap-e2e.sh` for
this video, before the founder's brief of 09-27 put issuance first. Issuance is the one flow that
runs today on a mint gated the way the real ones are, because the party who can open the gate is one
of the two parties. The swap needs two approved accounts and nobody has one.

**Two numbers on screen are worth knowing are not props.** The refused transaction prints a
signature that anybody can look up, and the four public balances at the end are read back off the
chain rather than asserted. Both are in `web/swaps.json`, which the site fetches live — including
the refused one, carried with `expect_err` so the page shows the chain disagreeing on purpose.

## Length

Derived by `python3 video/pace.py` from the words below. **Do not edit this table by hand** — it is
rewritten with `--write`, and it drifted from the words within minutes of both being written the one
time it was maintained any other way.

**Script to about 165 seconds, not to 179.** The cap is three minutes and the figure below is a
prediction at 137 words a minute. Check-in 2 was scripted at 58 seconds and the first export measured
**60.2** — about four per cent long ([`../STATUS.md`](../STATUS.md), 0i) — and the check reads
ffprobe rather than the prediction, so a script that fits on paper can fail on delivery.

| | scene | seconds (+ silence) | words | pace | what it shows |
|---|---|---|---|---|---|
| 1 | a mint that is shut, exactly as the real ones are | 22 | 49 | 137 | `./scripts/issue-e2e.sh` from the top — two keypairs funded, then both mints created with `autoApproveNewAccounts false, auditor EMPTY` printed beside each address |
| 2 | somebody subscribes, and opens an account for the shares | 16 | 36 | 140 | the treasury and the investor's cash being configured, approved and funded, then the investor's stock account being configured — and the red line underneath it: `NOT approved — the issuer has not signed for this one` |
| 3 | the allocation is refused, on chain, with a signature | 28 | 62 | 136 | both legs building — `issuer 6 transactions, 3 contexts` and `investor 14 transactions, 5 contexts` — then one transaction of 1,074 bytes sent and `REFUSED on chain — Custom(24), ConfidentialTransferAccountNotApproved` with the signature under it |
| 4 | the issuer signs for that one account | 19 | 41 | 134 | `the issuer approves it ok`, a single line, immediately after the refusal |
| 5 | the same allocation settles | 24 | 54 | 138 | `the same allocation, rebuilt against a fresh blockhash, sent again` then `the allocation ok`, and the four balances read back: treasury 480,000, investor 20,000 shares, investor cash 1,500,000, issuer cash 3,500,000 |
| 6 | and the buyer checked before signing | 27 | 61 | 139 | the check from the first run — `it will move 2000000000000 base units to you` and `and 2000000000000 is what you agreed, compared here, not left to your eye` — then the `SHORT=2000` run ending on `short by 1800000000000` and `REFUSED BEFORE SIGNING` |
| 7 | what anybody else can see | 20 + 2 | 45 | 139 | the site reading each signature live from devnet — `psyto.github.io/confide` — with the four public balances at 0 and the refused transaction listed beside the settled one |
| | | **158 s** | **348** | | |

## The script

### 1 — a mint that is shut, exactly as the real ones are

> This is devnet, and a tokenized stock mint I just created. It carries the two settings every real
> one carries: confidential transfers on, and the gate shut. No account can hold a confidential
> balance until the issuer signs for that account. The auditor slot is empty, and stays empty.

*Shows:* `./scripts/issue-e2e.sh` from the top — two keypairs funded, then both mints created with
`autoApproveNewAccounts false, auditor EMPTY` printed beside each address. **The first thing on
screen is the configuration, because everything after it is a consequence of those two fields.**

### 2 — somebody subscribes, and opens an account for the shares

> An investor wants twenty thousand shares and has the cash to pay for them. They open a
> confidential account for the stock themselves. No permission is needed for that part, and nothing
> about it is unusual.

*Shows:* the treasury and the investor's cash being configured, approved and funded, then the
investor's stock account being configured — and the red line underneath it: `NOT approved — the
issuer has not signed for this one`.

### 3 — the allocation is refused, on chain, with a signature

> Now the issuer allocates. Eight zero-knowledge proofs are built and verified by Solana's own proof
> program before anything is sent. The proofs are valid, the amounts are right, and the transaction
> is refused. Here is its signature. The destination account has not been approved. That is the
> issuer's control boundary holding, and it is why this market has not opened by itself.

*Shows:* both legs building — `issuer 6 transactions, 3 contexts` and `investor 14 transactions, 5
contexts` — then one transaction of 1,074 bytes sent and `REFUSED on chain — Custom(24),
ConfidentialTransferAccountNotApproved` with the signature under it.

### 4 — the issuer signs for that one account

> The issuer approves this account. One instruction, naming that account and no other. This is the
> whole product: eligibility is checked off chain, once, by whoever is allowed to check it, and what
> it buys is the right to settle confidentially.

*Shows:* `the issuer approves it ok`, a single line, immediately after the refusal.

### 5 — the same allocation settles

> The same allocation goes again. Same proofs, same accounts, same amounts — rebuilt against a fresh
> blockhash, because the first one is minutes old by now. Twenty thousand shares out of the
> treasury, against three and a half million dollars, at a hundred and seventy-five a share. One
> transaction. Delivery and payment, or neither.

*Shows:* `the same allocation, rebuilt against a fresh blockhash, sent again` then `the allocation
ok`, and the four balances read back: treasury 480,000, investor 20,000 shares, investor cash
1,500,000, issuer cash 3,500,000.

### 6 — and the buyer checked before signing

> One thing had to happen before that signature. The amounts are encrypted, so the investor could
> have been asked to sign for less than agreed. They decrypted their own leg out of the verified
> proof context — nobody's cooperation, nothing revealed — and compared it. Run it again with the
> issuer short-delivering, and it stops there, refused, before any signature exists.

*Shows:* the check from the first run — `it will move 2000000000000 base units to you` and `and
2000000000000 is what you agreed, compared here, not left to your eye` — then the `SHORT=2000` run
ending on `short by 1800000000000` and `REFUSED BEFORE SIGNING`.

### 7 — what anybody else can see · + 2.0 s silence

> Four accounts. All four are ordinary associated token accounts, the kind a wallet makes. Here is
> what their public balances say, after three and a half million dollars changed hands.
>
> Zero. All four. The transactions are public, the accounts are public, the sizes are not.

*Shows:* the site reading each signature live from devnet — `psyto.github.io/confide` — with the
four public balances at 0 and the refused transaction listed beside the settled one. **The silence
is before "zero", not after it.** The number is the end of the film and the pause is what makes a
viewer read it.

## What this video does not claim

Named here so the narration does not have to carry it, and so a reviewer can see the boundary was
drawn on purpose:

- **Devnet.** No mainnet deployment exists, deliberately — [`docs/27-DAYS.md`](../docs/27-DAYS.md)
  refuses it under *Refused*, with the reason.
- **No real issuer has approved anything.** The issuer here is a keypair this repository holds. What
  is measured about the real ones is that **nobody has been through that door**, not that they would
  refuse — nobody has asked them.
- **Confidential balances hide amounts, not identities.** The accounts, the mint and the fact of a
  transfer are all public and visible in scene 7. That is the point of scene 7.
- **The auditor slot being empty is not selective disclosure.** It means no mint-wide transfer
  auditor is configured. Token-2022 offers one global key or none.
- **The bilateral path is not in this video.** `swap-offer` through `swap-sign` works and is
  checked, but it has not been run end to end on devnet since 2026-09-30, and a demo should not
  show a path whose wiring has not been exercised.
