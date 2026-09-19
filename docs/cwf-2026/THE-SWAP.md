# The swap — two confidential positions exchanged in one transaction

Run on devnet 2026-09-20 with `./scripts/swap-e2e.sh`. Every address below is readable by anyone.

## Why this exists

Every other mechanism in this repository is a **loan**, and a loan needs a third thing holding the
collateral, because it has to survive one party refusing to cooperate. That third thing — the
escrow — is what ran into both of the walls this project spent a month measuring:

- an escrow is a new confidential account, and **every** tokenized-equity mint gates those behind
  the issuer ([`THE-PINCER.md`](THE-PINCER.md))
- an **associated** token account carries `ImmutableOwner` and can never become one, and an ATA is
  what a wallet creates

**A swap needs no third thing.** Both legs are in one transaction, so either both settle or neither
does. Solana's atomicity is the entire escrow.

## What that removes

| | the loan | the swap |
|---|---|---|
| a program to deploy, audit and hold an upgrade authority | required | **none — two Token-2022 instructions** |
| the issuer's approval for an escrow | required, per loan | **none beyond what each account already needed** |
| `ImmutableOwner` | fatal — an ATA can never be pledged | **irrelevant — all four accounts below are ATAs** |
| an oracle, a price, a default | required | **none** |
| a promise kept off chain (principal out, repayment in) | both | **none — everything promised happens in the transaction** |

That last row is the one that matters most. The loan's weakest point was that the program moves no
money: `principal` is only an input to the default test, so "did the lender pay?" and "did the
borrower repay?" live entirely outside it. **A swap has nothing outside it.**

## The danger a swap does have, and how it is answered

The amounts are encrypted. So a party could be asked to sign a transaction whose *other* leg sends
far less than was agreed, and discover it afterwards by decrypting their own balance.

**It is answerable before signing, by the recipient alone.** A confidential transfer encrypts the
amount once under three keys at once — the sender's, the **recipient's**, and the auditor's — and
that grouped ciphertext is what the validity proof is verified over and what sits in the proof
context account. So the recipient decrypts the exact amount straight out of the verified context:

```
THE LEG YOU ARE BEING ASKED TO SIGN
  ✓ it is addressed to your key
  ✓ it will move 4000000000000 base units to you
      decrypted from the verified context, by you, without anyone's cooperation

  If that is not the amount you agreed, do not sign. Nothing has happened yet.
```

No floor proof, no third party, no trust. `crates/confide-ct/src/swap_check.rs`; checked to refuse
both ways it should — a context addressed to somebody else, and a context that is not a validity
proof at all.

## The run

```
mint X   HWgDM5gEFPjtcepJSvA9GD8XqWA42RZNJEhJ37wGrV5e   auditor set, autoApproveNewAccounts false
mint Y   BGJTwfx4MWXtaeE7xyosoKnXK4kignsXi8ruMSk8dvgU   the same

alice's X  3SssY73ryeThZqCrTaU1A1r4wBZjhW4baFPnJH1nhAvy   173,000 → 123,000   sent 50,000
bob's   X  811gaATgkHRnAjTSg1NwyDBX8tn1KSfR5RVCxaUcQqAM         0 →  50,000
bob's   Y  EXUjDC8LUwQFnbBKyC7K7CnKGEtpKTEyRargSsgUjq19    91,000 →  51,000   sent 40,000
alice's Y  Gaa5chxjVWhRbCbjR45YhaS2J1tpq6jJct95TSs4SNA5         0 →  40,000
```

**All four are associated token accounts** — `immutableOwner: true`, read back off the chain — and
**all four still show a public balance of 0.** Nobody watching learns either amount.

The swap itself:

```
2RksP5AMcdvucLvPeXteVZm8SXL8xn6B9j4wtWJEw6kY2tfRfesQcuMP8bjugcdTKVdr6LdPK8XkG6QkEPk82Uk9

  signatures    2
  instructions  2, both Token-2022 confidentialTransfer
  compute used  29,417
  size          1,006 bytes against a 1,232-byte limit
```

## What was measured rather than assumed

Two things could have killed this, and both were open questions when it was proposed.

**Size.** A confidential transfer's proofs do not fit in a transaction — that is why this
repository verifies every proof into a *context state account* first, across ten transactions for a
loan. That work is setup and happens before the swap; the exchange cites the contexts by address.
`cargo run -p confide-ct --bin swap-size` builds the transaction and serialises it: **1,006 bytes
legacy, 856 with the six contexts in a lookup table.** The measured live transaction agrees at
1,006.

**Compute.** Two confidential transfers in one transaction could have exceeded the 200,000-unit
default and needed a `ComputeBudget` instruction. **29,417 units — a seventh of the default.** No
budget instruction, and the headroom is not close.

## What this does not solve

**Matching.** A swap needs somebody who wants the opposite trade. That is the same two-sided
problem as finding a lender, and no amount of cryptography answers it. Two differences are worth
stating and no more: both sides are **holders**, which is the population this repository has
measured and knows exists, and neither side has to underwrite anything.

**Price.** The ratio is agreed off chain. Nothing here says 50,000 of X is worth 40,000 of Y, and
nothing here should — that is what the two parties are for.

**Traction is still zero.** Nobody outside this repository has swapped anything.

## What it is for

- **A block trade that does not move the price against you.** Selling size on a book publishes the
  size. This publishes nothing.
- **Moving between issuers without selling.** Backed's NVDAx for Backpack's NVDAx, directly,
  without paying a round trip of spread or showing anyone how much moved.
