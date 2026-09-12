# Mora — lawful delay for tokenized equity positions

*mora* (Latin): delay. In law, the period during which performance is not yet due.

---

## 1. The gap

A fund's limited partners are owed a position report every quarter. That obligation is contractual,
it is universal — it sits in essentially every LPA — and today an LP has no way to check it. The GP
reports a quarter-end number weeks after the quarter ended, and nothing binds the GP to what it
actually held on the date. The LP takes the number on trust, and the lag between the date and the
report is exactly the window in which a number can be tidied.

On-chain, the same fund has the opposite problem. Solana's tokenized equities now do ~$5.8B of spot
DEX volume per quarter (Q2 2026), and a wallet accumulating NVDAx is readable by anyone, in real
time, **while the position is still being built** — not after it is complete. Everyone sees the
position except the party entitled to a report, who still only gets a number in an email.

So a fund on-chain today gets the worst of both: **continuous disclosure to the market, and
unverifiable disclosure to its LPs.**

TradFi solved the first half by legislating a lag. A US manager with discretion over $100M+ of
Section 13(f) securities files Form 13F **45 days after quarter end** — late enough that the
position is built, early enough that the market learns it. That lag is the design this borrows;
§3a says precisely what it does and does not apply to here.

**Mora gives the position a lawful delay and a proof at the same time**: sealed on the reporting
date, opened on the reporting deadline by a committee the holder does not control, provably
unrevised in between.

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

## 3a. What the law actually says, so this is not mistaken for a compliance claim

**xStocks are not Section 13(f) securities, and holding them does not create a Form 13F
obligation.** Section 13(f) securities are registered securities trading on US national exchanges,
identified by CUSIP on an official SEC list. An xStock is issued by Backed Finance AG under Swiss
law and carries its own Swiss ISIN — `NVDAx` is `CH1436219195`, while NVDA itself is
`US67066G1040`. Those are two securities, and the issuer's own API says so.

The SEC's **joint statement of 28 January 2026** (Corporation Finance, Investment Management, and
Trading and Markets) draws the line directly: federal securities laws apply to tokenized securities
whether ownership is recorded on-chain or off, and **issuer-sponsored tokenization conveying true
equity ownership is a different thing from third-party products conveying synthetic exposure or a
custodial entitlement.** xStocks are the second kind.

So the obligation Mora serves **today is contractual, not regulatory**: the quarterly position
report a GP owes its LPs. The mechanism does not change by a line — an obligation is an obligation —
but the party on the other end is an LP, not the SEC, and this document does not pretend otherwise.

**The regulatory version is filed, not hypothetical.** Nasdaq has a proposed rule change before the
SEC to trade securities in tokenized form on the exchange, with the same rights, the same order
books and DTC clearing. Tokens under that model *are* the security. On the day that settles, the
45-day lag becomes a legal requirement for on-chain positions — and there is no mechanism on a
public chain that satisfies it. That is the case Mora is built for. The LP case is the one that
exists now.

## 3. What a disclosure obligation actually requires

`aperture::policy::Grant` is **permissive**: a standing authorization for the holder to produce
future disclosures, expiring at `not_after` — a window that **closes**. A disclosure obligation is
**mandatory**, and its window **opens**. It is not a grant with the sign flipped. It needs three
properties, and the middle one is the hard one:

- **I1 — unopenable before T.** Otherwise the embargo means nothing.
- **I2 — unstoppable at T, including by the holder.** Otherwise it is a promise, not a disclosure.
- **I3 — bound to the position of record.** The commitment is anchored at quarter end, so the 45
  days before anyone can read it are 45 days in which the fund cannot revise what it held. Today a
  quarterly report — to an LP, or on a 13F — is prepared weeks after the fact with nothing binding
  the manager to the position as of the reporting date; Mora anchors it on the date itself.

Two further properties are inherited rather than invented:

- **I4 — the auditor reads continuously, before T.** The fund administrator and auditor are never
  delayed; only the *wider* disclosure is. This is the shape of a confidential-treatment request,
  not an evasion of one.
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
2. ~~`mora-equity`~~ — done. The xStocks as mainnet configures them, the corporate-action
   restatement, and the NAV-floor predicate whose proof the live ZK ElGamal Proof Program accepts
   (`mora-onchain`).
3. ~~On-chain anchoring~~ — done. `aperture-receipts` on devnet at
   `6a1Kd8Yo5U9wMXUtMnU1PZF8xy6wJ6zWyMr7uKNAHytv`; 147 bytes per obligation.
4. ~~The committee as real processes~~ — done. `scripts/committee.sh`. A committee inside one
   process is not a committee.
5. `mora-demo` — the two-lane runner. Done, but still simulates the accumulation rather than
   holding a confidential balance on a mirrored mint.
6. **Video.**

Non-goals, stated so they are not mistaken for omissions: no ATS, no order matching, no MEV
protection (§2), no custody, no mainnet deployment, and no claim to discharge any regulatory
filing (§3a).

Two limits that are **not** non-goals — they are gaps, and the next work:

- **The committee is the trust.** No stake, no slashing, no cryptographic clock. Both I1 and I2 rest
  on it, in opposite directions, on the same agents. `ReleaseTrustModel::TimeLockPuzzle` names the
  fix. Note that slashing is only half available even if built: failure to publish at `T` is
  observable on-chain and therefore punishable, while an early leak is not attributable at all.
- **The commitment is not bound to a live account.** `SubjectAccount` carries an address string and
  an empty ElGamal pubkey (`aperture`'s skeleton gap), so nothing proves the sealed position
  concerns the fund's actual wallet. Everything downstream is sound; the anchor to reality is not
  yet driven in.
