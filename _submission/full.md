## The privacy is shipped. Nobody uses it.

Read any tokenized stock Backed or Backpack issues on Solana, no key and no wallet: Token-2022,
confidential transfers **ON**, auditor key **empty**. **All 1,869** — 732 and 1,137 — every mint
they list checked rather than sampled (`./scripts/slot-scan.sh`).

One issuer would be a quirk. **Two, independently at the same dead end, is the problem** — and the
slot is empty because **no setting of it is correct.** Token-2022 offers one disclosure model: a single
global key that decrypts everyone's everything, forever. Fill it and every holder is readable by one
party for good. Leave it null and no holder can prove anything to anyone.

So a fund holding NVDAx broadcasts its position instead — not a choice about publicity, but the
only setting under which it can answer a question.

## What Confide gives a holder

Your position reads as zero on-chain. A lender can check that it covers their loan without seeing
it, and take it on default. Your auditor and LPs read what they are owed, when they are owed it.
Last quarter's number is sealed on the reporting date over your account's own ciphertext and opened
on the deadline by a committee you do not control — a stock split in between restates it rather
than corrupting it. You choose **who**, **how much**, and **when**.

## Who uses this first

**The issuer.** Backed and Backpack each switched confidential transfers on, gated who may open an
account, and left the auditor key null: companies that mean to enable this and have no disclosure
model to enable it *with*. Confide is that model. **They are the customer, not the obstacle.**

**The fund.** A GP holding NVDAx owes its LPs a quarterly report and broadcasts the position
continuously instead. That is what it pays to stop.

**The lender.** Jupiter Lend already takes SPYx, QQQx and NVDAx as collateral, and the position
securing the loan is public today. Both halves they need now run: the check, and the seizure.

**Traction is zero.** No issuer approval, no pilot, no customer interview, no design partner, no
user. What exists is a mechanism that runs and a finding checkable in one RPC call.

## Try it — no wallet, no install

**https://psyto.github.io/confide/** · walkthrough: https://youtu.be/KQsRwP8HTs0

It reads the mints from mainnet in your browser, shows real wallets publishing their positions as
they settle, and has Solana's ZK program check the collateral proof on a button press.


## What runs

| | evidence |
|---|---|
| A position that reads as zero | devnet `Cgv2eDN…BrX1P`: `spl-token balance` is `0`, the confidential balance holds 173,000 |
| **"This account holds at least X"**, over the account's *own* ciphertext | two proofs accepted by the live ZK program — `VerifyCiphertextCommitmentEquality` 6,400 CU, `VerifyBatchedRangeProofU64` 111,000 CU |
| The auditor slot, filled | one `UpdateMint` on a mirror carrying NVDAx's confidential-transfer configuration — not a replica of the whole mint |
| A disclosure bound to a date | 147 bytes on devnet over **that account's own ciphertext**; a figure restated later does not open it |
| Opening on schedule without the holder | five processes; the holder's exited in September, and what they publish opens the sealed commitment |
| Surviving a stock split | 11 live actions: 8 restate exactly, 3 have no whole ratio and are refused rather than guessed |
| **Taking that collateral on default** | `./scripts/seizure-e2e.sh` on devnet: a transfer authorised at origination fires without the borrower, 173,000 moving confidentially on both sides. The [loan account](https://explorer.solana.com/address/Bu6HviMHncufhC3didbMUgZZHbtvZpKTWGWLBtk8UdfX?cluster=devnet) still reads `seized` |

29 tests. `./scripts/healthcheck.sh` re-checks every row above against the chain and exits with the
number that died — judging runs three weeks and devnet resets.

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

