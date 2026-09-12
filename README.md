# Confide

### → [**Try it live**](https://psyto.github.io/confide/) · [83s video](video/confide.mp4) · no wallet, no API key, no install

**Every tokenized stock on Solana has confidential transfers switched on. Not one of them can be
used.** Read the mints yourself — `./scripts/onchain-check.sh`, no key, no account:

```
SYMBOL  MINT                                          PROGRAM      confidentialTransferMint.auditorElgamalPubkey
NVDAx   Xsc9qvGR1efVDFGLrVsmkzv3qi45LTBjeUKSPmx9qEh   Token-2022   None
TSLAx   XsDoVfqeBukxuZHWhdvWHBhgEHjGNst4MLodqsJHzoB   Token-2022   None
SPYx    XsoCS1TfEyfFhfvj8EtZ528L3CaKBDBRqRapnBbDF2W   Token-2022   None
AAPLx   XsbEhLAtcf6HdfpFZ5xEMdqW8nfAvcsP5bdudRLJzJp   Token-2022   None
```

The feature is shipped, configured, and **inert**. Token-2022 offers exactly one disclosure model —
a single global auditor key that decrypts **everything, for everyone, forever** — and for a
regulated equity issuer no setting of that key is correct. Fill it and every holder is permanently
readable by one party. Leave it null and no holder can demonstrate anything to anyone. So it sits
empty, and the privacy nobody can use is why a fund holding NVDAx broadcasts its position to the
whole market instead.

**Confide is what makes that slot usable**: disclosure scoped by recipient, by granularity, and — the
part nothing else has — **by schedule**. The auditor reads now. The counterparty learns one bit. The
public reads at `T`, and the holder can move neither date.

```
day      LANE A · a public wallet       LANE B · Confide
         what anyone can see            what anyone can see   the auditor
────────────────────────────────────────────────────────────────────────────
  3        42,000 NVDAx · +42,000        —                   42,000 NVDAx
 11        96,000 NVDAx · +54,000        —                   96,000 NVDAx
 ...
 58       173,000 NVDAx · +7,000         —                  173,000 NVDAx

Lane A leaked the position continuously, from day 3, mid-accumulation.
Nobody attacked anything. The chain simply published it.
```

```
 1 Oct · the LP asks

auditor reads the position    173,000 NVDAx   44 days before the public can
is the fund above its floor?  YES   floor $100M — and that is all this reveals
(the portfolio is $106M across NVDAx/TSLAx/SPYx — the LP is not told that)

14 Nov · the obligation comes due

agents 1, 2, 3 publish their shares  · the fund is not asked, and cannot object
reconstructed  ✓   commitment matches slot 340112045  ✓

LANE B is now public: 173,000 NVDAx, held by Fund A as of 30 Sep.
```

And that predicate is not only checkable off-chain. The same proof bytes out of the same sealed
package go to Solana's live ZK ElGamal Proof Program:

```
$ ./scripts/devnet-verify.sh
err   : None
units : 111000
logs  :
    Program ZkE1Gama1Proof11111111111111111111111111111 invoke [1]
    VerifyBatchedRangeProofU64
    Program ZkE1Gama1Proof11111111111111111111111111111 success
```

## What a usable auditor slot is worth

Split by whether it runs, not by which repository it came from — a reader of this gets the whole
stack, and the reuse declaration below is for eligibility, not for discounting what works.

**Demonstrated here. Every line of this runs; the on-chain ones reach Solana.**

| | |
|---|---|
| **Hold a position on-chain that reads as zero.** A live devnet account: `spl-token balance` says `0`, the confidential balance holds 173,000. Both public, both true. | `./scripts/bind-account.sh` — [explorer](https://explorer.solana.com/address/A1AMyEf1FQYmvdEWSejtHHU6ZKuBh74MRM9LzGfMGWT6?cluster=devnet) |
| **Bind a disclosure to that account**, not to a string — its own ElGamal key and its own ciphertext, re-read from chain to confirm. | `./scripts/bind-account.sh` |
| **Fill the auditor slot.** Same mint configuration as NVDAx, one field different — and the reason that field stays null everywhere else is that the key it holds cannot be scoped. | `./scripts/set-auditor.sh` — devnet |
| **Let only chosen parties read it.** The auditor reads throughout; the market never does. | `cargo test` — I4 |
| **Prove "this account holds at least X" — over the account's own on-chain ciphertext.** The counterparty learns one bit: not the value, not the composition, not any holding. Two proofs, because one does not exist: equality binds a commitment we can open to the account's ciphertext, then the range proof runs on the surplus. | `./scripts/prove-collateral.sh` — both accepted by Solana's live ZK ElGamal Proof Program |
| **Bind a disclosure to a date and make it unrevisable.** 45 days in which the number cannot be tidied. | `./scripts/anchor-receipt.sh` — 147 bytes on devnet |
| **Open on schedule without the holder.** Five separate processes; the holder exited in September. | `./scripts/committee.sh` |
| **Survive a stock split.** A number sealed in September is quoted in September's units; restatement is a deterministic function of public data, and says so when it cannot be computed. | `cargo test -p confide-equity` |

**The same primitive, pointed elsewhere. Not built here, and not claimed as working.**

- **Borrowing against stock without publishing the collateral.** Jupiter Lend already takes SPYx,
  QQQx, NVDAx as collateral, and today the position securing the loan is public. The check a lender
  needs is built and verifies on-chain (above). What is missing is **seizure**: a lender must be
  able to take confidential collateral on default, and nothing here does that.
- **Liquidation as a predicate.** *Is this account underwater* is the same claim with the threshold
  moved, so it works today — but it is only useful alongside the seizure that does not.
- **An issuer filling the slot on the live mints.** `./scripts/set-auditor.sh` fills it on a mint
  we control — one `UpdateMint` instruction, done, readable on devnet. On `NVDAx` it is Backed's
  call, not ours.
- **Standing grants per counterparty, revocable.** The policy layer expresses it; there is no
  product surface on top of it here.

Details and the full mint readings: [docs/ONCHAIN.md](docs/ONCHAIN.md).

**On devnet outliving the judging window:** the finding above is on mainnet and does not reset; the
account, the program and the mirrored mint are on devnet and can. `./scripts/healthcheck.sh` checks
every live claim, and [docs/DURABILITY.md](docs/DURABILITY.md) has the recovery steps and the
recorded evidence. The collateral proofs are self-contained and would keep verifying after a reset
wiped the account they are about — so the page compares the live ciphertext before treating a pass
as meaningful, rather than showing a green that means nothing.

## Why this and not MEV protection

Jupiter already ships Ultra / MEV Protect / JupiterZ RFQ, and they are good. They protect the
transaction **in flight**. Confide is about the **settled balance** — the permanent public record of
what you hold, which no relay touches. Different axis. See [DESIGN.md §2](DESIGN.md).

In TradFi a manager with discretion over $100M+ of Section 13(f) securities files Form 13F **45
days after quarter end**. That lag is legislated, for exactly the harm that real-time position
disclosure causes. On Solana, tokenized equities did ~$5.8B of spot DEX volume in Q2 2026 and the
lag is **zero**.

**What this is not.** xStocks are *not* Section 13(f) securities and holding them creates no Form
13F obligation — they are issued by Backed Finance AG under Swiss law with their own Swiss ISIN
(`NVDAx` = `CH1436219195`; NVDA itself = `US67066G1040`), and the SEC's joint statement of 28
January 2026 separates issuer-sponsored tokenization conveying true ownership from third-party
products conveying a custodial entitlement. The obligation Confide serves today is **contractual** —
the quarterly report a GP owes its LPs. 13F is the design this borrows and the requirement that
arrives when Nasdaq's filed tokenized-form rule settles. [DESIGN.md §3a](DESIGN.md) says all of
this in full rather than leaving it implied.

## Run it

The live page reads the mints from mainnet in your browser, pulls real wallets out of recent NVDAx
transactions with what they hold, shows the Confide account on devnet reading zero, and — on a
button press — has Solana's ZK program verify the lender's proof while you watch. Source in
[`web/`](web/).

```bash
./scripts/demo.sh             # everything: the two lanes, then the proof going to Solana
./scripts/onchain-check.sh    # read the xStock mints yourself
./scripts/devnet-verify.sh    # hand Confide's proof to the live ZK ElGamal Proof Program
./scripts/committee.sh        # the release committee as five actual processes
./scripts/refresh-actions.sh  # re-pull the xStocks corporate-action schedule
cargo test                    # 19 tests
```

Those three need no key and no account. One more does — `./scripts/anchor-receipt.sh` anchors a
sealed obligation's commitment on devnet through `aperture-receipts`
([`6a1Kd8…AHytv`](https://explorer.solana.com/address/6a1Kd8Yo5U9wMXUtMnU1PZF8xy6wJ6zWyMr7uKNAHytv?cluster=devnet))
and reads it back to check the stored bytes against the artifact. **147 bytes land on-chain: a hash
and two dates.** It needs a devnet-funded keypair.

The invariants are written as claims you can run, not prose:
[`crates/confide-embargo/tests/invariants.rs`](crates/confide-embargo/tests/invariants.rs).

| | |
|---|---|
| **I1** | unopenable before `T` — **if fewer than `k` agents collude.** Shares carry no clock; the assumption is stamped on the artifact (`ReleaseTrustModel`), not implied |
| **I2** | unstoppable at `T` by the holder *as a party to the protocol* — it is not a parameter of any function on the opening path, and in `scripts/committee.sh` it is a process that exited in September. **A holder that captures `n − k + 1` agents stops it anyway**, and nothing here prevents that |
| **I3** | bound to the position of record — a post-hoc revision is refused. **The only one that depends on no one's behaviour**: it is a hash comparison |
| **I4** | the auditor reads throughout; only *public* disclosure is delayed |
| **I5** | opening is irreversible — revocation is not clawback |

## The split problem

A quarterly report states holdings **as of the reporting date**. Confide seals at quarter end and opens 45 days
later. If a split lands in between, the number that opens is quoted in units that no longer exist —
the disclosure is correct and unreadable at the same time.

This is not hypothetical. The live xStocks schedule read on 2026-09-12 has **eight unit-changing
events** in the pipeline, including `PPLTx` 1→10 and a `HONx` 2→1 reverse sharing its date with a
spin-off ([`fixtures/corporate-actions.json`](crates/confide-equity/fixtures/corporate-actions.json),
refreshable with `scripts/refresh-actions.sh`).

The fix is not to re-seal — the commitment must not move, that is the whole point. It is to restate
at read time, and restatement is a **deterministic function of public data**: the holder gains
nothing by staying quiet about a split, because anyone can recompute it and everyone gets the same
answer. `confide-open` prints both numbers, and refuses rather than rounding when a ratio cannot be
applied exactly.

## And the other half of a quarterly report

An LPA does not only ask *what do you hold*; it carries covenants of the form *"the fund is at or
above X"*, which must be answerable before the position itself is disclosable. `confide-equity` proves
that as a predicate: the LP learns one bit and no position, and the proof goes to the live ZK
program. `every_xstock_has_confidential_transfers_and_an_empty_auditor_slot` is the test that will
say so if the premise above ever stops being true.

## Built on

Stocklana's rules: *original work. Open-source components are fine if you say so.* So, said plainly:

| Component | Origin | License | Role |
|---|---|---|---|
| `aperture-core` | `psyto/aperture`, pre-existing | Apache-2.0 | Token-2022 confidential balances, disclosure package, policy, auditor |
| `aperture-receipts` | `psyto/aperture`, pre-existing | Apache-2.0 | content-blind on-chain receipt, native Solana program |
| **Confide** | **this repository, written in-window** | Apache-2.0 | **the embargo mechanism (I1–I3), the k-of-n sharing, the equity layer, the demo** |

The secret sharing is Confide's own — `crates/confide-embargo/src/shamir.rs`, GF(256), no dependency.

## What it does not do

Stated because a reader should find the limits here rather than discover them:

- **The committee is the trust.** `k = 3, n = 5` tolerates 2 early colluders and 2 withholders, and
  those are the *same* agents — choosing `k` trades I1 against I2 and cannot minimise both. There is
  no stake to slash and no cryptographic clock. A public-randomness timelock (`TimeLockPuzzle` in
  `ReleaseTrustModel`) is the one change that would make both unconditional; it is named, not built.
- **Seizure.** A lender can now verify collateral without the borrower publishing it, and still has
  no way to take that collateral on default. That is the gap between this and lending, and it is not
  a small one.
- **One mint, ours.** The accounts here are on a mint this repo provisioned with NVDAx's
  configuration. Doing it on `NVDAx` itself is Backed's call — `autoApproveNewAccounts: false`.
- **Not built, deliberately:** no ATS, no order matching, no MEV protection, no custody, no mainnet
  deployment, and no claim to discharge any regulatory filing.
