# Codex adversarial review, 2026-09-29 — one product or two, and is I2 real

Run read-only against this repository. Payload: `payloads/2026-09-29-one-product.md`.
Asked because another agent (Claude) claimed the repo sells two products and proposed making
the scheduled-disclosure mechanism the competition demo's centrepiece.

## Adversarial result

**BLOCKER — “unstoppable” is false as a system property.** There are no identified or independent agents: `seal` returns every share to its caller, and `confide-seal` writes all five into one local directory. [`crates/confide-embargo/src/lib.rs:197-235`](/Users/hiroyusai/src/confide/crates/confide-embargo/src/lib.rs:197) [`crates/confide-committee/src/seal.rs:34-42`](/Users/hiroyusai/src/confide/crates/confide-committee/src/seal.rs:34) `committee.sh` then invokes those “agents” itself, sequentially, with files it created. [`scripts/committee.sh:36-52`](/Users/hiroyusai/src/confide/scripts/committee.sh:36) Failing sequence: holder runs sealing, retains/deletes three share files or never runs the later loop; no shares publish, so no disclosure. The code itself says a holder controlling, paying, or injuncting `n-k+1` agents stops I2. [`crates/confide-embargo/src/lib.rs:39-59`](/Users/hiroyusai/src/confide/crates/confide-embargo/src/lib.rs:39)

**BLOCKER — no cryptographic or on-chain clock exists.** An “agent” accepts caller-supplied `now`; it merely compares it with `open_at`. [`crates/confide-committee/src/agent.rs:10-26`](/Users/hiroyusai/src/confide/crates/confide-committee/src/agent.rs:10) Failing sequence: the holder invokes three agents before T but passes `DUE`; they publish. Conversely, nobody invoking them at T means permanent silence. The library explicitly admits Shamir shares have no clock and `TimeLockPuzzle` is unimplemented. [`crates/confide-embargo/src/lib.rs:17-23`](/Users/hiroyusai/src/confide/crates/confide-embargo/src/lib.rs:17) [`crates/confide-embargo/src/lib.rs:61-67`](/Users/hiroyusai/src/confide/crates/confide-embargo/src/lib.rs:61)

**MAJOR — I3 is not enforced on-chain end-to-end.** The receipt transaction records a commitment and date, but `anchor-receipt` creates a seal and discards it; it produces neither the `sealed.json` nor shares consumed by the committee. [`crates/confide-onchain/src/anchor.rs:165-173`](/Users/hiroyusai/src/confide/crates/confide-onchain/src/anchor.rs:165) `confide-open` reads only local JSON and reports the supplied slot; it performs no RPC receipt lookup. [`crates/confide-committee/src/open.rs:14-26`](/Users/hiroyusai/src/confide/crates/confide-committee/src/open.rs:14) The actual mismatch check is local `open()` code. [`crates/confide-embargo/src/lib.rs:246-270`](/Users/hiroyusai/src/confide/crates/confide-embargo/src/lib.rs:246) Failing sequence: run the committee demo, which hard-codes an anchor slot but never calls the anchoring script. [`crates/confide-committee/src/lib.rs:13-15`](/Users/hiroyusai/src/confide/crates/confide-committee/src/lib.rs:13) [`scripts/committee.sh:36-52`](/Users/hiroyusai/src/confide/scripts/committee.sh:36)

**MAJOR — “position at t0” is asserted, not established.** Anchoring reads the account when the script runs, while labelling it with fixed `QUARTER_END`/`DUE` values and an internal anchor slot of zero. [`crates/confide-onchain/src/anchor.rs:110-172`](/Users/hiroyusai/src/confide/crates/confide-onchain/src/anchor.rs:110) Failing sequence: anchor after quarter-end from a revised current balance; the resulting receipt binds that current ciphertext, not a historically proven t0 balance.

**MINOR — the apparent product split is presentation, not two completed products.** DESIGN explicitly calls disclosure/collateral the underlying layer after a pivot to confidential swap as the first product. [`DESIGN.md:3-9`](/Users/hiroyusai/src/confide/DESIGN.md:3) README likewise calls settlement the wedge and scheduled disclosure a second use of the same primitive. [`README.md:232-238`](/Users/hiroyusai/src/confide/README.md:232) The more complete runnable path is DvP; the scheduled path is a prototype/simulation, which DESIGN concedes. [`DESIGN.md:252-255`](/Users/hiroyusai/src/confide/DESIGN.md:252)

| Component | Serves | What actually runs |
|---|---|---|
| `confide-ct` | DvP; shared confidential-account/proof plumbing | `MODE=dvp ./scripts/swap-e2e.sh` builds and submits two confidential-transfer legs. [`scripts/swap-e2e.sh:147-188`](/Users/hiroyusai/src/confide/scripts/swap-e2e.sh:147) |
| `confide-embargo`, `confide-committee` | Scheduled disclosure prototype | `./scripts/committee.sh`; local shares, manual invocation, caller clock. |
| `confide-equity`, `confide-onchain` | Disclosure/NAV predicate and receipt | `./scripts/demo.sh`, `./scripts/anchor-receipt.sh`; receipt is not connected to committee release. |
| `confide-seizure` | Separate collateral-default mechanism | `./scripts/seizure-e2e.sh`; neither DvP nor scheduled release. [`scripts/seizure-e2e.sh:12-16`](/Users/hiroyusai/src/confide/scripts/seizure-e2e.sh:12) |

Design-only or missing artifacts: independent funded agents, persistence/scheduler, a trusted clock/timelock or slashing, compulsory sealing, and a production-mint flow. Per-counterparty standing grants also have “no product surface.” [`README.md:591-592`](/Users/hiroyusai/src/confide/README.md:591)

What is still unmeasured:

- A real holder refusing at T while independent agents disclose.
- One artifact chain-linking t0 receipt, ciphertext, shares, and public opening.
- A historical t0 account balance rather than a current balance labelled t0.
- Production issuer approval and external customers; README records zero outside use. [`README.md:335-338`](/Users/hiroyusai/src/confide/README.md:335)

VERDICT: ONE PRODUCT — confidential Token-2022 settlement, with an incomplete scheduled-disclosure prototype