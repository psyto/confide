# Mora

**A fund on-chain discloses continuously to the market and unverifiably to its LPs.**
Everyone can watch a wallet accumulate NVDAx in real time; the party actually owed a quarterly
report still gets a number in an email, weeks late, with nothing binding it to the date.

Mora gives the position a lawful delay and a proof at the same time: sealed on the reporting date,
opened on the deadline by a committee the holder does not control, provably unrevised in between.

```
day      LANE A · a public wallet       LANE B · Mora
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

LANE B is now public: 173 NVDAx, held by Fund A as of 30 Sep.
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

## The empty slot this is aimed at

Every tokenized-equity mint on mainnet — `NVDAx`, `TSLAx`, `SPYx`, `AAPLx` — is Token-2022 with
`confidentialTransferMint` **enabled** and `auditorElgamalPubkey` **null**. Confidential transfers
were re-enabled at epoch 982 (June 2026), so the substrate works. Usage is close to zero.

Shipped, configured, unused — because the only disclosure Token-2022 offers is a single global key
that decrypts everything forever, and for a regulated equity issuer no setting of it is correct.
Fill it and every holder is permanently readable by one party; leave it null and no holder can
demonstrate anything to anyone.

Reproduce that reading yourself with [`scripts/onchain-check.sh`](scripts/onchain-check.sh) — no
key, no account, no API token. Details in [docs/ONCHAIN.md](docs/ONCHAIN.md).

## Why this and not MEV protection

Jupiter already ships Ultra / MEV Protect / JupiterZ RFQ, and they are good. They protect the
transaction **in flight**. Mora is about the **settled balance** — the permanent public record of
what you hold, which no relay touches. Different axis. See [DESIGN.md §2](DESIGN.md).

In TradFi a manager with discretion over $100M+ of Section 13(f) securities files Form 13F **45
days after quarter end**. That lag is legislated, for exactly the harm that real-time position
disclosure causes. On Solana, tokenized equities did ~$5.8B of spot DEX volume in Q2 2026 and the
lag is **zero**.

**What this is not.** xStocks are *not* Section 13(f) securities and holding them creates no Form
13F obligation — they are issued by Backed Finance AG under Swiss law with their own Swiss ISIN
(`NVDAx` = `CH1436219195`; NVDA itself = `US67066G1040`), and the SEC's joint statement of 28
January 2026 separates issuer-sponsored tokenization conveying true ownership from third-party
products conveying a custodial entitlement. The obligation Mora serves today is **contractual** —
the quarterly report a GP owes its LPs. 13F is the design this borrows and the requirement that
arrives when Nasdaq's filed tokenized-form rule settles. [DESIGN.md §3a](DESIGN.md) says all of
this in full rather than leaving it implied.

## Run it

```bash
./scripts/demo.sh             # everything: the two lanes, then the proof going to Solana
./scripts/onchain-check.sh    # read the xStock mints yourself
./scripts/devnet-verify.sh    # hand Mora's proof to the live ZK ElGamal Proof Program
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
[`crates/mora-embargo/tests/invariants.rs`](crates/mora-embargo/tests/invariants.rs).

| | |
|---|---|
| **I1** | unopenable before `T` — **if fewer than `k` agents collude.** Shares carry no clock; the assumption is stamped on the artifact (`ReleaseTrustModel`), not implied |
| **I2** | unstoppable at `T` by the holder *as a party to the protocol* — it is not a parameter of any function on the opening path, and in `scripts/committee.sh` it is a process that exited in September. **A holder that captures `n − k + 1` agents stops it anyway**, and nothing here prevents that |
| **I3** | bound to the position of record — a post-hoc revision is refused. **The only one that depends on no one's behaviour**: it is a hash comparison |
| **I4** | the auditor reads throughout; only *public* disclosure is delayed |
| **I5** | opening is irreversible — revocation is not clawback |

## The split problem

A quarterly report states holdings **as of the reporting date**. Mora seals at quarter end and opens 45 days
later. If a split lands in between, the number that opens is quoted in units that no longer exist —
the disclosure is correct and unreadable at the same time.

This is not hypothetical. The live xStocks schedule read on 2026-09-12 has **eight unit-changing
events** in the pipeline, including `PPLTx` 1→10 and a `HONx` 2→1 reverse sharing its date with a
spin-off ([`fixtures/corporate-actions.json`](crates/mora-equity/fixtures/corporate-actions.json),
refreshable with `scripts/refresh-actions.sh`).

The fix is not to re-seal — the commitment must not move, that is the whole point. It is to restate
at read time, and restatement is a **deterministic function of public data**: the holder gains
nothing by staying quiet about a split, because anyone can recompute it and everyone gets the same
answer. `mora-open` prints both numbers, and refuses rather than rounding when a ratio cannot be
applied exactly.

## And the other half of a quarterly report

An LPA does not only ask *what do you hold*; it carries covenants of the form *"the fund is at or
above X"*, which must be answerable before the position itself is disclosable. `mora-equity` proves
that as a predicate: the LP learns one bit and no position, and the proof goes to the live ZK
program. `every_xstock_has_confidential_transfers_and_an_empty_auditor_slot` is the test that will
say so if the premise above ever stops being true.

## Built on

Stocklana's rules: *original work. Open-source components are fine if you say so.* So, said plainly:

| Component | Origin | License | Role |
|---|---|---|---|
| `aperture-core` | `psyto/aperture`, pre-existing | Apache-2.0 | Token-2022 confidential balances, disclosure package, policy, auditor |
| `aperture-receipts` | `psyto/aperture`, pre-existing | Apache-2.0 | content-blind on-chain receipt, native Solana program |
| **Mora** | **this repository, written in-window** | Apache-2.0 | **the embargo mechanism (I1–I3), the k-of-n sharing, the equity layer, the demo** |

The secret sharing is Mora's own — `crates/mora-embargo/src/shamir.rs`, GF(256), no dependency.

## What it does not do

Stated because a reader should find the limits here rather than discover them:

- **The committee is the trust.** `k = 3, n = 5` tolerates 2 early colluders and 2 withholders, and
  those are the *same* agents — choosing `k` trades I1 against I2 and cannot minimise both. There is
  no stake to slash and no cryptographic clock. A public-randomness timelock (`TimeLockPuzzle` in
  `ReleaseTrustModel`) is the one change that would make both unconditional; it is named, not built.
- **The commitment is not bound to a live account.** The disclosure package carries a subject
  address as a string and an empty ElGamal pubkey — `aperture`'s own skeleton gap — so nothing here
  proves the sealed position is about the fund's actual wallet rather than some other one. Tying it
  to a real Token-2022 confidential account is the next correctness step, not a detail.
- **Not built, deliberately:** no ATS, no order matching, no MEV protection, no custody, no mainnet
  deployment, and no claim to discharge any regulatory filing.
