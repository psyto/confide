## The privacy is shipped. Nobody uses it.

Read any tokenized stock on Solana right now, no key and no wallet: Token-2022, confidential
transfers **ON**, auditor key **empty**. **All 1,869 of them** — 732 from Backed (xStocks) and 1,137
from Backpack Securities — every mint checked, not sampled (`./scripts/slot-scan.sh`).

One issuer would be a quirk. **Two, independently at the same dead end, is the problem.** The ZK
ElGamal Proof Program came back at epoch 982 in June: the substrate works, and usage is near zero.

The slot is empty because **no setting of it is correct.** Token-2022 offers one disclosure model: a
single global key that decrypts everyone's everything, forever. Fill it and every holder is readable
by one party for good. Leave it null and no holder can prove anything to anyone.

So a fund holding NVDAx broadcasts its position instead — not a choice about publicity, but the
only option under which it can still answer a question.

## What Confide gives a holder

- **Your position stops being public.** It sits on-chain and reads as zero to anyone looking.
- **A lender can check your collateral without seeing it.** Prove the position covers the loan and
  reveal one bit — not the value, not the composition. (Proving works; *seizure does not exist
  here*, so this is not lending yet.)
- **Your auditor and LPs are unaffected.** They read what they are owed, when they are owed.
- **Last quarter's number cannot be tidied.** Sealed on the reporting date, opened on the deadline
  by a committee you do not control.
- **A stock split does not corrupt what you disclosed.** Restatement reads the issuer's published
  schedule — one source today — and refuses rather than guessing when an action has no ratio.

You choose **who**, **how much**, and **when**.

## Try it — no wallet, no API key, no install

**https://psyto.github.io/confide/** · walkthrough: https://youtu.be/ZuhLvH5MFgE

It reads the mints from mainnet in your browser, pulls real wallets out of recent NVDAx transactions
with the balance each one published as it settled, shows a Confide account on devnet whose public
balance is zero — and on a button press has Solana's ZK program verify the collateral proof while
you watch.


## What runs

| | evidence |
|---|---|
| A position on-chain that reads as zero | devnet `6Wn7zAa…mG16V`: `spl-token balance` says `0`, the confidential balance holds 173,000 |
| **Prove "this account holds at least X"** over the account's *own* ciphertext | two proofs accepted by the live ZK program: `VerifyCiphertextCommitmentEquality` 6,400 CU, `VerifyBatchedRangeProofU64` 111,000 CU |
| The auditor slot, filled | one `UpdateMint` on a mirrored mint — NVDAx's config, one field apart |
| A disclosure bound to a date, unrevisable | 147 bytes anchored on devnet, commitment matched on read-back — over its own position, not the account above |
| Opening on schedule without the holder | five separate processes; the holder's exited in Sept |
| Surviving a stock split | 11 actions on the live schedule: 8 restate exactly, 3 have no whole ratio and are reported, not guessed |

26 tests. `./scripts/healthcheck.sh` re-checks the rows above against the chain and exits with the
number that died — judging runs three weeks and devnet resets.

## Why two proofs, not one

An account's ciphertext carries no Pedersen opening we hold, so it cannot be range-proved directly.
Equality binds a commitment we *can* open to it; the range proof runs on the surplus under the same
opening, so a verifier reaches it by subtracting `threshold·G`, not our word.

## What is not built

- **Seizure.** A lender can verify the collateral and still cannot take it on default — the
  distance between this and lending, and it is not small.
- **One chain, not yet.** The devnet account, the proof over its ciphertext and the sealed
  disclosure are each real but not one artifact: the seal covers its own position, not that
  account.
- **On the live mints.** Both issuers set `autoApproveNewAccounts: false`, so opening a confidential
  account needs their approval — a signal, not a wall. They built the feature, configured it, gated
  it, and left the key slot empty: companies that mean to enable this and have no disclosure model
  to enable it *with*. **The issuer is the customer here, not the obstacle.**
- **No claim to discharge any filing.** xStocks are not Section 13(f) securities — Swiss-issued,
  own ISIN. Backpack's carry US CUSIPs and are called security entitlements, a different category
  and **a question for counsel, not for me**. What Confide serves today is contractual: the
  quarterly report a GP owes its LPs.

## Built on

Original work, in-window, except where declared: `aperture-core` and `aperture-receipts`
(Apache-2.0, my own pre-existing engine) and `spl-token-2022-interface`. The embargo, the k-of-n
sharing, the equity layer, the proofs and the demo are new.

github.com/psyto/confide · github.com/psyto/aperture
