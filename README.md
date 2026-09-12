# Mora

**Tokenized stocks on Solana publish your position while you are still building it.**
Mora gives that position a lawful delay: sealed at quarter end, opened on the deadline by a
committee the holder does not control, provably unrevised in between.

```
day      LANE A · a public wallet       LANE B · Mora
         what anyone can see            what anyone can see   the auditor
────────────────────────────────────────────────────────────────────────────
  3        42 NVDAx · +42                —                       42 NVDAx
 11        96 NVDAx · +54                —                       96 NVDAx
 19       127 NVDAx · +31                —                      127 NVDAx
 ...
 58       173 NVDAx · +7                 —                      173 NVDAx

Lane A leaked the position continuously, from day 3, mid-accumulation.
Nobody attacked anything. The chain simply published it.
```

```
14 Nov · the obligation comes due

agents 1, 2, 3 publish their shares  · the fund is not asked, and cannot object
reconstructed  ✓   commitment matches slot 340112045  ✓

LANE B is now public: 173 NVDAx, held by Fund A as of 30 Sep.
```

## Why this and not MEV protection

Jupiter already ships Ultra / MEV Protect / JupiterZ RFQ, and they are good. They protect the
transaction **in flight**. Mora is about the **settled balance** — the permanent public record of
what you hold, which no relay touches. Different axis. See [DESIGN.md §2](DESIGN.md).

In TradFi a manager with discretion over $100M+ files Form 13F **45 days after quarter end**. That
lag is legislated, for exactly the harm that real-time position disclosure causes. On Solana,
tokenized equities did ~$5.8B of spot DEX volume in Q2 2026 and the lag is **zero**.

## Run it

```bash
cargo run -p mora-demo --bin two-lane   # the two lanes, end to end
cargo test                              # 9 tests: I1–I5 plus the sharing primitive
```

The invariants are written as claims you can run, not prose:
[`crates/mora-embargo/tests/invariants.rs`](crates/mora-embargo/tests/invariants.rs).

| | |
|---|---|
| **I1** | unopenable before `T` — and the assumption this rests on is stamped on the artifact (`ReleaseTrustModel`), not implied |
| **I2** | unstoppable at `T`, *including by the holder* — who is not a parameter of any function on the opening path |
| **I3** | bound to the position of record — a post-hoc revision is refused |
| **I4** | the auditor reads throughout; only *public* disclosure is delayed |
| **I5** | opening is irreversible — revocation is not clawback |

## Built on

Stocklana's rules: *original work. Open-source components are fine if you say so.* So, said plainly:

| Component | Origin | License | Role |
|---|---|---|---|
| `aperture-core` | `psyto/aperture`, pre-existing | Apache-2.0 | Token-2022 confidential balances, disclosure package, policy, auditor |
| `aperture-receipts` | `psyto/aperture`, pre-existing | Apache-2.0 | content-blind on-chain receipt, native Solana program |
| `@fabrknt/veil-core`, `@fabrknt/veil-orders` | npm, published | MIT | threshold / secret-sharing prior art |
| **Mora** | **this repository, written in-window** | Apache-2.0 | **the embargo mechanism (I1–I3), the equity layer, the demo** |

Not built here, and deliberately: no ATS, no order matching, no MEV protection, no custody, no
mainnet deployment, no actual Form 13F filing.
