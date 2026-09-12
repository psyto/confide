## The privacy is already shipped. Nobody can use it.

Read any tokenized stock on Solana right now — no key, no wallet:

`NVDAx`, `TSLAx`, `SPYx`, `AAPLx` — Token-2022, confidential transfers **ON**, auditor key
**empty**. **All 732 of them**: every xStock on Solana, checked rather than sampled
(`./scripts/slot-scan.sh`). The ZK ElGamal Proof Program came back at epoch 982 in June, so the
substrate works. Usage is near zero.

That slot is empty because **no setting of it is correct.** Token-2022 offers one disclosure model:
a single global key that decrypts everyone's everything, forever. Fill it and every holder is
permanently readable by one party. Leave it null and no holder can demonstrate anything to anyone —
so anyone who might be asked to prove something transacts in the clear instead.

That is why a fund holding NVDAx broadcasts its position to the whole market. Not a choice about
publicity — the only option under which it can still answer a question.

## What Confide gives a holder

- **Your position stops being public.** It sits on-chain and reads as zero to anyone who looks.
- **A lender can check your collateral without seeing it.** Prove the position covers the loan and
  reveal one bit — not the value, not the composition. (Proving works; *seizure on default does
  not exist here*, so this is not lending yet. See below.)
- **Your auditor and your LPs are unaffected.** They read what they are owed, when they are owed it.
- **Last quarter's number cannot be tidied.** Sealed on the reporting date, opened on the deadline
  by a committee you do not control.
- **A stock split does not corrupt what you disclosed.** Restatement is a deterministic function of
  the issuer's published schedule — one source today — and refuses rather than guessing when an
  action has no whole-number ratio.

You choose **who**, **how much**, and **when**.

## Try it — no wallet, no API key, no install

**https://psyto.github.io/confide/**

It reads the mints from mainnet in your browser, pulls real wallets out of recent NVDAx transactions
with what they hold, shows a Confide account on devnet whose public balance is zero — and on a
button press has Solana's ZK program verify the collateral proof while you watch.

## What runs

| | evidence |
|---|---|
| A position held on-chain that reads as zero | devnet `6Wn7zAa…mG16V`: `spl-token balance` says `0`, the confidential balance holds 173,000 |
| **Prove "this account holds at least X"** over the account's *own* ciphertext, revealing one bit | two proofs accepted by the live ZK program: `VerifyCiphertextCommitmentEquality` 6,400 CU, `VerifyBatchedRangeProofU64` 111,000 CU |
| The auditor slot, filled | one `UpdateMint` on a mirrored mint — NVDAx's config, one field different |
| A disclosure bound to a date and unrevisable | 147 bytes anchored on devnet; commitment matched on read-back |
| Opening on schedule without the holder | five separate processes; the holder's exited in September |
| Surviving a stock split | 11 unit-changing events are queued on the live schedule; restatement refuses rather than rounding |

21 tests. `./scripts/healthcheck.sh` checks every claim above against the chain and exits non-zero
on the first that has died — judging runs three weeks and devnet resets.

## Why two proofs, not one

An account's ciphertext carries no Pedersen opening we hold, so it cannot be range-proved directly.
Equality binds a commitment we *can* open to it; the range proof then runs on the surplus under the
same opening, so a verifier reaches it by subtracting `threshold·G` rather than taking our word.
Below the threshold it refuses — without printing the balance.

## What is not built

- **Seizure.** A lender can verify the collateral and still cannot take it on default. That is the
  distance between this and lending, and it is not small.
- **On the live mints.** The blocker is not the empty auditor key — the disclosure layer never
  needed it. It is `autoApproveNewAccounts: false`: opening a confidential account on NVDAx requires
  Backed to approve it. They gate a feature nobody can use, which reads like intent to enable it
  selectively. The accounts here are on a mint with the same configuration.
- **No claim to discharge any filing.** xStocks are not Section 13(f) securities — Swiss-issued
  (`NVDAx` = `CH1436219195`, NVDA = `US67066G1040`), and the SEC's 28 January 2026 joint statement
  separates issuer-sponsored tokenization from third-party products. What Confide serves today is
  contractual: the quarterly report a GP owes its LPs.

## Built on

Original work, written in-window, except where declared: `aperture-core` and `aperture-receipts`
(Apache-2.0, my own pre-existing engine — confidential balances, disclosure packages, the on-chain
receipt) and `spl-token-2022-interface`. The embargo mechanism, the k-of-n sharing, the equity
layer, the collateral proofs and the demo are new.

github.com/psyto/confide · engine: github.com/psyto/aperture · Apache-2.0
