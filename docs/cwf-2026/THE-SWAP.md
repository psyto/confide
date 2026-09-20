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

---

# Delivery versus payment — stock for cash, 2026-09-20

`MODE=dvp ./scripts/swap-e2e.sh`. The same transaction as above with a different mint on one side,
and it is the trade that actually exists: stock-for-stock is rare, **stock-for-cash is every block
trade ever done.**

Delivery versus payment is what a clearing house is *for*. TradFi solves "neither side wants to go
first" with a central counterparty, membership, margin and a day of settlement lag. Here it is a
property of the transaction, and there is nothing in the middle.

## The run

```
stock mint  4MhK9tTL3zfMgGi1xMxE7R7VBc89JsNqWCu4wiJEw6os   8 decimals, gated, auditor set
cash  mint  FwKTA33WPwqtJK2c6vPSLYNmT4zortKxwmFgFMmA8wGb   6 decimals, gated, auditor EMPTY,
                                                           permanent delegate + freeze authority

alice  6sGtxuaRrBhnph9Y8CyX428HstztBwJBX62wacHBsNwq   173,000 → 123,000 shares   delivered 50,000
bob    BbqCriFfNGgy966GYpecUPfajKp6Hq7oMN4n1H5BqETm         0 →  50,000 shares
bob    4Bu93JSs17wTrX6xFWzcNPrxq4rdLB7VYpCfFtJiekHR   $9,000,000 → $250,000     paid $8,750,000
alice  Bz9HdL72NyFjn2sdvPqrgxfuP7wk4EfMV7ZbocqPFJ9u           $0 → $8,750,000
```

$8.75m for 50,000 shares is **$175 a share**, agreed off chain. All four accounts are ATAs
(`immutableOwner: true`) and all four still read a **public balance of 0** — so the chain does not
publish the size, the price, or the fact that $175 was the level.

```
4gzku3FWoRzhNr24gUTBquxEPwq9L5nqZrmtrCHWjzMBjaDyiapTj6zrBtGLTcRvzPzhexuJfdgxdqafu5Jhhovs

  signatures    2
  instructions  2, both Token-2022 confidentialTransfer
  compute used  29,849
  size          1,006 bytes
```

Each side still checked the other before signing: Alice decrypted $8,750,000 out of Bob's verified
proof context, Bob decrypted 50,000 shares out of Alice's.

## The cash mint is a mirror of PYUSD, and one thing is missing from it

The mirror is built from the mainnet reading in [`COMPOSITION.md`](COMPOSITION.md): 6 decimals,
`autoApproveNewAccounts: false`, an **empty** auditor slot, a permanent delegate and a freeze
authority — the last two mirrored deliberately, because they mean the cash issuer can seize or
freeze any account and that is what settling in PYUSD costs.

**What is missing is PYUSD's zero-rate `transferFeeConfig`, and it is the remaining blocker.**

A mint carrying a transfer fee config rejects the plain confidential `Transfer` outright, at **0
bps**, with `InvalidInstructionData`. That was isolated by running the variants rather than by
reading the processor:

| run | auditor | transfer fee config | result |
|---|---|---|---|
| stock↔stock | set | absent | **swap ok** |
| dvp | EMPTY | present, 0 bps | `InvalidInstructionData` on the cash leg |
| dvp | **set** | present, 0 bps | **the same failure** — so the empty auditor is not the cause |
| dvp | EMPTY | absent | **swap ok** — the run above |

So the fee config is the cause and the empty auditor slot is fine.

## What the fee-bearing path costs, measured before it is attempted

Token-2022 has a separate instruction, `TransferWithFee`, taking **five** proofs instead of three —
the extra two are a percentage-with-cap sigma proof and a 2-handle fee validity proof, and the
range proof widens from `U128` to `U256`.

`crates/confide-ct/tests/fee_tx_size.rs` already measured how those have to be submitted, and four
of the five are ordinary:

```
equality     legacy   557   v0+ALT   531   FITS
validity3    legacy   781   v0+ALT   755   FITS
pct+cap      legacy   597   v0+ALT   571   FITS
validity2    legacy   653   v0+ALT   627   FITS
range256     legacy  1301   v0+ALT  1275   OVER the 1,232-byte limit
```

**The U256 range proof cannot be verified with its proof in instruction data at all** — 1,269 bytes
at the very best, and there is nothing left to move into a lookup table. It has to go through the
ZK program's fourth instruction layout, which reads the proof **from an account**: written into an
`spl-record` account in chunks first, then cited by offset.

That is the work the cash leg still needs, and it is routing rather than cryptography — the proof
generation crate ships `transfer_with_fee_split_proof_data` and produces all five in one call.

**Stated plainly so the result is not read as more than it is:** delivery-versus-payment runs, in
one transaction, against a mint that matches PYUSD in every respect but one. The one is a zero-rate
fee extension, and clearing it is a known, measured piece of work rather than an open question.

> **Cleared the same day. The section below is the fee-bearing run.**

---

# The fee-bearing mirror — the whole of PYUSD's configuration, 2026-09-20

`MODE=dvp ./scripts/swap-e2e.sh` with the transfer fee config left in. The cash mint now carries
everything PYUSD carries: 6 decimals, the gate, an empty auditor slot, a permanent delegate, a
freeze authority, a mint close authority, **and the zero-rate `transferFeeConfig` with its
`confidentialTransferFeeConfig`.**

```
5ZrJPGRLHKzzR1us4KF3kf9z5hSgvQLabHKQbkMmCSkGEGXAkC8QA7JtnMhsVBsCJzrW5a75s9LJsxaaKsqesZug

  signatures    2
  instructions  2 — confidentialTransfer  +  confidentialTransferWithFee
  compute used  59,804
  size          1,074 bytes against 1,232

  cash mint  CBDqHhHCACZC21aCs8PnX5dGwMzPszgeSHLZYDn9mTT5
             mintCloseAuthority, permanentDelegate, transferFeeConfig,
             confidentialTransferMint, confidentialTransferFeeConfig
```

**The two legs are different instructions in the same transaction.** The stock has no fee config
and takes the plain `Transfer`; the cash has one and takes `TransferWithFee`. Atomicity does not
care that they differ, which is the point — one transaction can compose two assets whose rules do
not match.

All four accounts are still ATAs with a public balance of 0, and the two cash accounts now carry
the `ConfidentialTransferFeeAmount` extension that a fee-bearing mint requires.

## What it took

Five proofs on the cash leg instead of three, and **fourteen setup transactions instead of six**:

```
create ctx 0 … verify ctx 3        8 transactions   equality, validity3, percentage+cap, validity2
create record                      1                1,097 bytes, owned by spl-record
init record                        1
write proof 1/2, 2/2               2                1,064 bytes of range proof, in 800-byte chunks
create ctx 4                       1
verify ctx 4 from account          1                215 bytes of transaction, 5 of instruction data
```

The last line is the whole trick. The U256 range proof cannot be verified from instruction data —
1,269 bytes at best against 1,232 — so it goes into an `spl-record` account and the verify
instruction cites it by offset. **Five bytes of instruction data: a discriminant and a `u32`.**

## Three things that only appear when you run it

**A blockhash does not live long enough for fourteen transactions.** The thirteenth came back
`BlockhashNotFound`. Regenerating with a fresh one would produce *different* proofs for the same
context accounts, so the proof set is now generated once, cached as bytes, and re-signed — the
builder takes a `skip` count and the script sends in batches.

**The U256 verification does not fit the compute budget.** `ComputationalBudgetExceeded` at the
200,000-unit default. It needs a `SetComputeUnitLimit`, which costs 40 bytes on a 215-byte
transaction.

**A swallowed error cost a run.** The script sent `go`'s output to `/dev/null`, so a rejection
surfaced as `exit 1` with the reason already discarded. Fixed before the cause was found, which is
the order it should have been in.

## What is left

The mirror still lacks PYUSD's `metadataPointer` and `tokenMetadata`, which do not touch a
transfer, and its `transferHook` slot — which PYUSD leaves unset. **Nothing in the settlement path
now differs.**

The remaining gap is not technical: a confidential position in either asset needs its issuer's
approval, so a real trade needs the equity issuer and Paxos. That is the gate this repository has
been measuring since the beginning, and it is unchanged.
