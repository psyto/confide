# Mora

**Tokenized stocks on Solana publish your position while you are still building it.**
Mora gives that position a lawful delay: sealed at quarter end, opened on the deadline by a
committee the holder does not control, provably unrevised in between.

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
 1 Oct · the regulator asks

auditor reads the position    173,000 NVDAx   44 days before the public can
does Fund A owe a 13F?        YES   threshold $100M — and that is all this reveals
(the portfolio is $106M across NVDAx/TSLAx/SPYx — the regulator is not told that)

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

In TradFi a manager with discretion over $100M+ files Form 13F **45 days after quarter end**. That
lag is legislated, for exactly the harm that real-time position disclosure causes. On Solana,
tokenized equities did ~$5.8B of spot DEX volume in Q2 2026 and the lag is **zero**.

## Run it

```bash
./scripts/demo.sh             # everything: the two lanes, then the proof going to Solana
./scripts/onchain-check.sh    # read the xStock mints yourself
./scripts/devnet-verify.sh    # hand Mora's proof to the live ZK ElGamal Proof Program
./scripts/committee.sh        # the release committee as five actual processes
cargo test                    # 13 tests
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
| **I1** | unopenable before `T` — and the assumption this rests on is stamped on the artifact (`ReleaseTrustModel`), not implied |
| **I2** | unstoppable at `T`, *including by the holder* — who is not a parameter of any function on the opening path, and in `scripts/committee.sh` is a process that exited in September |
| **I3** | bound to the position of record — a post-hoc revision is refused |
| **I4** | the auditor reads throughout; only *public* disclosure is delayed |
| **I5** | opening is irreversible — revocation is not clawback |

`mora-equity` holds the other half: a manager owes a 13F only above **$100M**, so *"is one owed?"*
must be answerable before the position is. It is a predicate, it reveals no position, and
`every_xstock_has_confidential_transfers_and_an_empty_auditor_slot` is the test that will say so if
the premise above ever stops being true.

## Built on

Stocklana's rules: *original work. Open-source components are fine if you say so.* So, said plainly:

| Component | Origin | License | Role |
|---|---|---|---|
| `aperture-core` | `psyto/aperture`, pre-existing | Apache-2.0 | Token-2022 confidential balances, disclosure package, policy, auditor |
| `aperture-receipts` | `psyto/aperture`, pre-existing | Apache-2.0 | content-blind on-chain receipt, native Solana program |
| **Mora** | **this repository, written in-window** | Apache-2.0 | **the embargo mechanism (I1–I3), the k-of-n sharing, the equity layer, the demo** |

The secret sharing is Mora's own — `crates/mora-embargo/src/shamir.rs`, GF(256), no dependency.

Not built here, and deliberately: no ATS, no order matching, no MEV protection, no custody, no
mainnet deployment, no actual Form 13F filing.
