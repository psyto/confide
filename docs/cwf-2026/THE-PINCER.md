# The pincer — why this market cannot open itself

Measured 2026-09-19 with `./scripts/slot-scan.sh`, over **every** tokenized-equity mint on Solana.
Not a sample. The repository has had to correct that exact shortcut once already.

## The two halves

**Kamino refuses a liquidity mint that auto-approves confidential accounts.** Its own words, at
`constraints.rs:131` in the pinned release:

> `Auto approve new accounts must be false for liquidity tokens`

**On a mint where it is false, every new confidential account needs the issuer's approval** —
Confide's escrow included. That is what the flag means.

So the setting Kamino *requires* is the setting that puts the issuer *in the path*. **They are the
same field, read from two sides.**

| | issuer approval needed per escrow | Kamino accepts the mint |
|---|---|---|
| `autoApproveNewAccounts = false` | **yes** | ✅ |
| `autoApproveNewAccounts = true` | no | ❌ refused at `constraints.rs:131` |

## Which side is the market on

**All of it. 1,992 of 1,992.**

```
  THE APPROVAL GATE — the same field Kamino reads at constraints.rs:131
    1992 of 1992 set autoApproveNewAccounts = false
    0 auto-approve, so 0 can hold a confidential position without the issuer
```

All three issuers, independently, on every mint they have ever shipped: Backed 828, Backpack 1,156, PreStocks 8.
**There is no mint in the population that escapes the gate**, so there is no version of this that
is solved by picking a different ticker.

## What this makes true

The repository already computed that **$22.0m is deposited across Kamino's tokenized-equity
reserves and $83.0m of borrowing is authorised against it, of which $0 is reachable confidentially.**
Until today that `$0` was a *demonstration* — here is a rule, here is an account, watch it fail.

**It is now a result.** Every mint in the asset class sits on the gated side of a fork whose other
side Kamino refuses by name. The $0 does not depend on which asset, which reserve, or which
parameters: it is a property of the configuration the whole market shares.

**No amount of engineering on this side removes it.** Confide can prove a floor without revealing a
balance, lock collateral so the holder cannot reduce it, and settle on default without the holder's
signature — all of which it does — and the position still cannot exist, because the account it
would live in cannot be opened without the issuer.

## The part that is a hypothesis, and is labelled as one

**The issuer is the gate, and may also be the beneficiary.** That is a third position, and it is
not yet evidence.

- The submission filed to Stocklana says *"the issuer is the customer, not the obstacle."*
- That was reversed on 2026-09-16: *an issuer whose business is issuing and selling is a gate on
  eligibility, not a buyer.* The founder's own reading, and the reason was incentive — a disclosure
  model is a cost to them.
- **What the pincer adds** is that the incentive may not be about disclosure at all. An issuer whose
  token cannot be used as collateral by anyone unwilling to publish their position is leaving a
  **quantified** amount of lending demand unreachable. That is an argument in their units — token
  utility — and it does not ask them to care about privacy.

**Nobody has been asked, so this is untested.** It is recorded as a hypothesis with a date, the way
the two positions before it were.

## What it does not fix

Traction is zero and is reported as zero. A structural result about why a market is closed is
insight, not demand.

---

## Narrowed — 2026-09-19, and it should have been stated this way first

The founder asked whether Confide had run out of room to extend. Checking rather than answering
found that **this page overstates its own finding.**

`autoApproveNewAccounts: false` gates **opening a new confidential account.** It does not gate an
account that is already open and already approved. And `SetAuthority` — the handover that turns a
holder's account into a loan escrow — **does not touch the approval.**

Read off devnet from the escrow of today's release run, now owned by the loan PDA:

```
owner now           9yfKfFD5ixUeoEGZxN3fxAwRW2rzWB74R5sexzsYiMJo   (the loan PDA)
approved            True
allowConfCredits    True
```

The issuer approved it while the borrower still owned it. The handover changed the owner and left
the approval in place. **Confide's own end-to-end run has been demonstrating this all along, in the
order `approve` → `handover`, and nobody read it that way.**

### So the honest statement

| | needs the issuer? |
|---|---|
| opening a **new** confidential account on any of the 1,992 | **yes, every time** |
| handing over an account **already open and approved** | **no** |
| pledging **part** of a position — which needs a second account | **yes**, back to row one |

**The gate is per account and one-time, not per loan**, and it is paid by whoever configured the
account rather than by Confide or by a lender. A holder who already holds their position
confidentially can pledge it today without anyone's permission — they give up the whole account,
which is the real cost, and it is a different cost from "the issuer must sign".

### What does not change

**The `$0` stands**, because it never rested on this. It rests on Kamino refusing a deposit from an
account holding value confidentially — `constraints.rs:187`, `:194`, `:201` via
`lending_checks.rs:186` — and that refusal is about the depositor's account, not about who approved
it. Nothing above lets a confidential position into a Kamino reserve.

What narrows is the claim about **Confide's own escrow**: it is not true that every loan needs a
fresh approval from the issuer. It is true that every *new account* does.
