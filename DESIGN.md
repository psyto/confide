# Mora — lawful delay for tokenized equity positions

*mora* (Latin): delay. In law, the period during which performance is not yet due.

---

## 1. The gap

In TradFi, an institutional manager with discretion over $100M+ of US equities files Form 13F
**within 45 days after the end of the quarter**. The delay is not an accident of paperwork. It is
legislated. Disclosure informs the market; the lag preserves the manager's ability to build a
position without being front-run by everyone who can read the filing. Where even 45 days is too
short, a confidential-treatment request holds the position back from the public while the regulator
already has it.

On Solana, tokenized equities now do ~$5.8B of spot DEX volume per quarter (Q2 2026). And the delay
is **zero**. A wallet accumulating NVDAx is readable by anyone, in real time, mid-accumulation,
forever. Not after the position is built — *while* it is being built.

This is the one axis on which owning stocks on-chain is not merely different from a brokerage
account but strictly worse, and it is the axis the law cares about most.

**Mora restores the delay as a mechanism rather than a promise.**

## 2. Why the obvious answers do not close it

**"Jupiter MEV Protect / Ultra / JupiterZ RFQ."** These protect the transaction *in flight* —
obfuscated routing, private order flow, searcher auctions. They are good, and they are the reason
this project is not about sandwiching. They do nothing about the **settled balance**, which is the
permanent public record of what you hold. Different axis entirely.

**"Use Token-2022 confidential balances."** Confidential-balance primitives hide the amount from
*everyone, forever*, and ship only a crude global-auditor model: one key that decrypts everything,
for all time. That is not a 13F. That is all-or-nothing. The regulatory shape you need —
*the auditor sees now, the public sees at T* — is not expressible.

**"Trade through a custodian / a fresh wallet each time."** An omnibus custodian is today's
brokerage; it forfeits the reason to be on-chain at all. Wallet hygiene moves the trust and
creates no schedule.

**"Just publish your position at T."** A promise, not a mechanism. If the holder declines at T,
nothing happens — and nothing can be proven about what they held.

## 3. What a disclosure obligation actually requires

`aperture::policy::Grant` is **permissive**: a standing authorization for the holder to produce
future disclosures, expiring at `not_after` — a window that **closes**. A disclosure obligation is
**mandatory**, and its window **opens**. It is not a grant with the sign flipped. It needs three
properties, and the middle one is the hard one:

- **I1 — unopenable before T.** Otherwise the embargo means nothing.
- **I2 — unstoppable at T, including by the holder.** Otherwise it is a promise, not a disclosure.
- **I3 — bound to the position of record.** The commitment is anchored at quarter end, so the 45
  days before anyone can read it are 45 days in which the fund cannot revise what it held. Today a
  13F is prepared and filed weeks after the fact with nothing binding the manager to the position
  as of the reporting date; Mora anchors it on the date itself.

Two further properties are inherited rather than invented:

- **I4 — the auditor reads continuously, before T.** Compliance is never delayed; only *public*
  disclosure is. This is the confidential-treatment shape, not an evasion of it.
- **I5 — opening is irreversible.** From `aperture::policy`: *revocation is not clawback.* Revoking
  a standing grant stops future disclosures; it cannot un-disclose a delivered package.

**I2 is why this is a mechanism and not a policy field.** No amount of schema expresses "the holder
cannot stop this."

## 4. Mechanism

Everything happens at **accumulation time**. Nothing is required of the holder at T.

```
  ACCUMULATION (t0)                                    OPENING (T)
  ─────────────────                                    ───────────
  THE QUARTER                          t0 = QUARTER END              T = t0 + 45d
  ───────────                          ───────────────              ────────────
  buy xStock in Token-2022             2. seal the position of      5. any k of N agents
  confidential balances                   record: an aperture          publish their shares
  └ aperture token2022 adapter            Exact package + the         └ the holder is not
    (grouped ElGamal,                     material needed to             an input, and is
     [source,dest,auditor])                read it                       not asked
  └ nothing leaks while the            └ threshold-split the
    position is being built               seal key across N         6. anyone reconstructs,
                                          agents, k-of-n               checks it against the
  1. the auditor reads it all          └ mora-embargo::shamir          commitment anchored
     along ─────────────────────────►                                   at t0
                                       3. anchor the content-        └ I3: no revision was
                                          blind commitment + T         possible in between
                                          on-chain
                                       └ aperture-receipts          7. the position is public,
                                         (native Solana program)       on schedule

                                       4. publish the ciphertext
                                          itself — in the open,
                                          useless without k shares
                                       └ this is what makes it
                                         unstoppable (I2)

  the auditor reads the position throughout ───────────────────────────────►  (I4)
```

The holder's only act is at t0. That is precisely what makes the disclosure at T a disclosure.

## 5. Reuse and original work

Stocklana eligibility: *original work. Open-source components are fine if you say so.* So it is
said here, explicitly.

| Component | Origin | License | Role |
|---|---|---|---|
| `aperture-core` | `psyto/aperture` — pre-existing, 20 tests green | Apache-2.0 | confidential balances, disclosure package, policy, auditor |
| `aperture-receipts` | `psyto/aperture` — pre-existing | Apache-2.0 | content-blind on-chain receipt (native Solana program) |
| **Mora** | **this repository, written in-window** | Apache-2.0 | **the embargo mechanism (I1–I3), the k-of-n sharing, the equity layer, the demo** |

Mora is the part that did not exist: a **self-opening embargo** that the holder can neither
accelerate nor prevent, bound to a position commitment, over tokenized equities. The k-of-n sharing
under it is Mora's own too — `crates/mora-embargo/src/shamir.rs`, GF(256), no dependency. An earlier
project of mine does threshold encryption for DEX order flow; none of its code is here, and it is
listed nowhere above because listing it would overstate the reuse.

## 6. The demo

Two lanes, one accumulation of NVDAx, side by side.

**Lane A — today.** A public wallet buys. A *watcher* pane, given nothing but the public chain,
prints the position as it grows: `42 NVDAx … 96 … 173 …`, live, mid-accumulation.

**Lane B — Mora.** Same buys, confidential. The watcher pane prints nothing. An *auditor* pane,
holding the auditor key, prints the full position the entire time. The clock advances to T. k of N
shares are released. The watcher pane now prints the position — and verifies it against the
commitment anchored at t0.

The line on screen at the end:

> Public lane: readable 43 days early, by anyone.
> Mora lane: readable exactly on schedule — and provably the position that was actually held.

## 7. What ships

Minimum that makes §6 true and §3 testable. In order:

1. ~~`mora-embargo`~~ — done. Threshold-seal, anchor, open from k shares, verify against the
   commitment. I1–I5 are executable claims in `tests/invariants.rs`.
2. ~~`mora-equity`~~ — done. The xStocks as mainnet configures them, and the $100M filing-threshold
   predicate, whose proof the live ZK ElGamal Proof Program accepts (`mora-onchain`).
3. ~~On-chain anchoring~~ — done. `aperture-receipts` on devnet at
   `6a1Kd8Yo5U9wMXUtMnU1PZF8xy6wJ6zWyMr7uKNAHytv`; 147 bytes per obligation.
4. ~~The committee as real processes~~ — done. `scripts/committee.sh`. A committee inside one
   process is not a committee.
5. `mora-demo` — the two-lane runner. Done, but still simulates the accumulation rather than
   holding a confidential balance on a mirrored mint.
6. **Video.**

Non-goals, stated so they are not mistaken for omissions: no ATS, no order matching, no MEV
protection (§2), no custody, no mainnet deployment, no real Form 13F filing.
