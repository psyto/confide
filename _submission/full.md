## The privacy is shipped. Nobody uses it.

Read a tokenized stock on Solana right now, no key and no wallet: Token-2022, confidential
transfers **ON**, auditor key **empty**. **1,869 of them**, from two issuers with nothing to do with
each other, every mint checked rather than sampled (`./scripts/slot-scan.sh`).

One issuer would be a quirk. **Two, independently at the same dead end, is the problem** — and the
slot is empty because **no setting of it is correct.** Token-2022 offers one disclosure model: a
global key that decrypts everyone's everything, forever. Fill it and every holder is readable by one
party for good. Leave it null and no holder can prove anything to anyone.

## What Confide gives a holder

Your position reads as zero on-chain. A lender can check that it covers their loan without seeing
it, and take it on default. Your auditor and LPs read what they are owed, when they are owed it —
last quarter's number sealed on the reporting date over your account's own ciphertext, opened on
the deadline by a committee you do not control. You choose **who**, **how much**, and **when**.

## Who uses this first

**The lender — the money is already there.** Kamino runs 19 live markets in tokenized stock: at
their own prices, **$21.1m deposited** and **$81.6m of borrowing their caps authorise**. SPYx at
73% LTV, NVDAx at 55%, SpaceX at 40%. Every position is public, and that is the only way in —
Kamino's own program refuses a deposit from an account holding value confidentially
(`constraints.rs:187`, via `lending_checks.rs:186`). **$0 of that $81.6m is reachable without
publishing what you hold.** Recompute it: `./scripts/capacity.sh`.

**The issuer is a gate, not the buyer** — reversed 2026-09-16, in the open. A business whose revenue
is issuing and selling has no reason to adopt a disclosure model, and none has been asked. What they
are asked is narrow: these mints do not auto-approve, so the issuer signs per escrow.

**Traction is zero.** No pilot, no interview, no design partner, no user. What exists is a mechanism
that runs and a market you can measure.

## Try it — no wallet, no install

**https://psyto.github.io/confide/kamino.html** — pick any of the 1,869; your browser reads it from
mainnet against Kamino's rules. Walkthrough: https://youtu.be/p1aQuEnzhQk

It reads the mints from mainnet in your browser, shows real wallets publishing their positions as
they settle, and has Solana's ZK program check the collateral proof on a button press.


## What runs

| | evidence |
|---|---|
| A position that reads as zero | devnet `Cgv2eDN…BrX1P`: `spl-token balance` is `0`; the confidential balance holds 173,000 |
| **"This account holds at least X"**, over the account's *own* ciphertext | two proofs accepted by the live ZK program — `VerifyCiphertextCommitmentEquality` 6,400 CU, `VerifyBatchedRangeProofU64` 111,000 CU |
| The auditor slot, filled | one `UpdateMint` on a mirror of NVDAx's confidential-transfer configuration, not of the whole mint |
| A disclosure bound to a date | 147 bytes on devnet over **that account's own ciphertext**; a figure restated later will not open it |
| Opening on schedule without the holder | five processes; the holder's exited in September, and what they publish opens the seal |
| Surviving a stock split | 11 live actions: 8 restate exactly, 3 have no whole ratio and are refused |
| **Taking that collateral on default** | `./scripts/seizure-e2e.sh` on devnet: a transfer authorised at origination fires without the borrower, 173,000 moving confidentially on both sides — the [loan account](https://explorer.solana.com/address/26QJWCRwvPd1dLwvgH4Drb8D5F4ga2RPMdS8PrbRw4Hj?cluster=devnet) still reads `seized` |

88 tests, 33 over the seizure program. `./scripts/healthcheck.sh` re-checks every row against the chain
and exits with the number that died — judging runs three weeks and devnet resets.

## What is not built

- **On the live mints.** Both issuers set `autoApproveNewAccounts: false`, so opening a confidential
  account there needs the issuer to sign. On the mirror that approval is a step you can watch; on
  `NVDAx` it is a conversation nobody has had yet.
- **A loan.** Seizure runs; origination, interest, a liquidation engine and an oracle do not. The
  floor is recorded rather than verified on chain and the price is asserted by the loan's named
  oracle. Confide enforces a default someone else defines.
- **No claim to discharge any filing.** xStocks are Swiss-issued with their own ISIN and are not
  Section 13(f) securities; Backpack's carry US CUSIPs and are called security entitlements, **a
  question for counsel, not for me**. What Confide serves is the report a GP owes its LPs.

## Built on

Original work except where declared: `aperture-core` and `aperture-receipts` (Apache-2.0, my own
pre-existing engine) and `spl-token-2022-interface`. The embargo, the k-of-n sharing, the equity
layer, the seizure program, the proofs and the demo are new. github.com/psyto/confide

