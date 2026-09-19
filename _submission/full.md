## The privacy is shipped. Nobody uses it.

Read a tokenized stock on Solana right now, no key or wallet: Token-2022, confidential transfers
**ON**, auditor key **empty**. **1,992 of them**, three unrelated issuers — two tokenize listed
equity, one tokenizes companies with no public market. Every mint checked, not sampled.

One issuer would be a quirk. **Three, independently at the same dead end, is the problem** — and the
slot is empty because **no setting of it is correct.** The one model on offer is a global key
decrypting everyone's everything forever: fill it and every holder is readable by one party for
good, leave it null and no holder can prove anything to anyone.

## What Confide gives a holder

Your position reads as zero on-chain. A lender can check it covers their loan without seeing it,
and take it on default. Your auditor and LPs read what they are owed, when —
last quarter's number sealed on the reporting date over your own ciphertext, opened on the deadline
by a committee you do not control. You choose **who**, **how much**, and **when**.

## Who uses this first

**The lender — the money is already there.** Kamino runs 19 live markets in tokenized stock: at
their own prices, **$22.0m deposited**, **$83.0m their caps authorise**. SPYx 73% LTV, NVDAx 55%. Every position is public, and that is the only way in — Kamino's program
refuses a deposit from an account holding value confidentially (`constraints.rs:187`, via
`lending_checks.rs:186`). **$0 of that $83.0m is reachable without publishing what you hold**
(`./scripts/capacity.sh`).

**The issuer is a gate, not the buyer** — reversed 2026-09-16, in the open. A business whose revenue
is issuing and selling has no reason to adopt a disclosure model, and none has been asked. What they
are asked is narrow: these mints do not auto-approve, so the issuer signs per escrow — **and that is
the field Kamino requires.** `constraints.rs:131` refuses a mint that *does*, so the setting
admitting the token is the setting putting the issuer in the path. **1,992 of 1,992 are on the
gated side** (`./scripts/slot-scan.sh`). No ticker escapes it, and **no new issuer would either** —
the other setting frees their holders and gets the mint refused.

**Traction is zero.** No pilot, interview, design partner or user — a mechanism that runs and a
market you can measure.

## Try it — no wallet, no install

**https://psyto.github.io/confide/kamino.html** — pick any of the 1,992; your browser reads it from
mainnet against Kamino's rules. Walkthrough: youtu.be/p1aQuEnzhQk


## What runs

| | evidence |
|---|---|
| A position that reads as zero | `Cgv2eDN…BrX1P`: `spl-token balance` `0`, confidential 173,000 |
| **"This account holds at least X"**, over its *own* ciphertext | two proofs accepted by the live ZK program: `VerifyCiphertextCommitmentEquality`, `VerifyBatchedRangeProofU64` |
| The auditor slot, filled | one `UpdateMint` on a mirror of NVDAx's confidential setup |
| A disclosure bound to a date | 147 bytes over **that account's own ciphertext**; a figure restated later will not open it |
| Opening on schedule without the holder | five processes; the holder's exited in September, the rest open it |
| Surviving a stock split | 11 live actions: 8 restate exactly, 3 have no whole ratio, refused |
| **Both exits from the escrow**, devnet, 173,000 confidential either way | `./scripts/seizure-e2e.sh` — on default a transfer authorised at origination fires without the borrower; loan `26QJWCRw…` reads `seized`. `MODE=release` — the borrower arms a return route, their own attempt is refused, the lender signs; loan `9yfKfFD5…` reads `released` |

96 tests, 39 over the seizure program. `./scripts/healthcheck.sh` re-checks every row against the
chain and exits with the number that died — judging runs weeks, devnet resets.

## What is not built

- **On the live mints.** The issuer signs per escrow, as above. On the mirror that approval is a
  step you can watch; on `NVDAx` it is a conversation nobody has had yet.
- **A loan.** Seizure and release run; interest, a liquidation engine and an oracle do not. Release
  is **attested, not repayment** — no principal moves through the program, so the lender attests it.
  It buys a lender who cannot redirect the collateral, not one who cannot refuse to sign. The floor
  is **proved on chain** against the escrow's own ciphertext; the price is asserted by the loan's
  named oracle. Confide enforces a default someone else defines.
- **No claim to discharge any filing.** xStocks are Swiss-issued, own ISIN, not Section 13(f);
  Backpack's carry US CUSIPs, called security entitlements — **counsel's question, not mine**. What
  Confide serves is the report a GP owes its LPs.

## Built on

Original work except where declared: `aperture-core`, `aperture-receipts` (Apache-2.0, my own
pre-existing engine), `spl-token-2022-interface`. The embargo, k-of-n sharing, equity layer,
seizure program, proofs and demo are new. github.com/psyto/confide

