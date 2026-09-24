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

The repository already computed that **$24.1m is deposited across Kamino's tokenized-equity
reserves and $85.5m of borrowing is authorised against it, of which $0 is reachable confidentially.**
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

---

## Narrowed again, the other way — 2026-09-19, later the same day

Building the borrower's half found the limit the section above missed. **An associated token
account cannot be handed over**, and an ATA is what a wallet creates.

`SetAuthority` on one fails with `TokenError::ImmutableOwner` (0x22). The extension exists
precisely to stop an ATA changing hands, and the handover is exactly that. Measured on devnet, by
running it:

```
THE HANDOVER
  SetAuthority: ERR custom program error: 0x22   → TokenError::ImmutableOwner
```

The account had `extensions: ['immutableOwner', 'confidentialTransferAccount']`. This repository
already knew the fact and had written it down for the *escrow* — `seizure-e2e.sh` says *"NOT an
associated account: an ATA carries ImmutableOwner and can never be handed over"* — and did not
carry it across to the holder's side when the handover became a way to pledge.

### The statement, third version and narrower than the second

| the holder's position sits in… | can they pledge it today? |
|---|---|
| a token account with its own keypair, already approved | **yes** — handover works, no issuer involved |
| an **associated token account**, already approved | **no** — `ImmutableOwner`. They need another account, and another account needs the issuer |

**The second row is the ordinary case.** Wallets create ATAs. So the gate bites most holders after
all, and the morning's "a holder can pledge today, without asking anyone" is true of a minority and
was written as though it were true of everyone.

### What it would take to reach an ATA holder

Not a fix on this side. The position would have to move into a pledgeable account, and opening one
on a mint with `autoApproveNewAccounts: false` is the gate. An escrow pre-approved and handed to a
loan PDA *before* the holder funds it would need the PDA to apply a pending balance, which the
program has no instruction for. **Recorded as unsolved rather than as an idea.**

> **Solved and run — 2026-09-19, later still.** The missing instruction is the whole of it. The
> program now has `apply_pending` (discriminant 5), and `MODE=ata ./scripts/seizure-e2e.sh` runs
> the ATA holder end to end on devnet. See the next section.

---

## Would a better issuer fix it? — asked 2026-09-19, and the answer is no

The founder asked whether to build a competing tokenized-equity service that configures its mints
correctly. Working out what "correctly" could mean is what produced the strongest form of this
finding, so the question earned its answer even though the answer is no.

**A new issuer has exactly two settings to choose between, and neither works.**

| `autoApproveNewAccounts` | can a holder open an account unaided? | will Kamino admit the mint? |
|---|---|---|
| **`true`** | **yes — the gate disappears** | **no.** `constraints.rs:131` refuses the *mint*: *"Auto approve new accounts must be false for liquidity tokens"* |
| **`false`** | no — the same gate everyone else has | yes |

**There is no configuration that gives both.** Ungated accounts cost you the venue; venue
admissibility costs your holders the gate. Both halves are measured: the refusal is in Kamino's
pinned source, and 1,992 of 1,992 live mints sit on the `false` side.

And the auditor slot offers no third option either. Token-2022 gives one disclosure model — a
global key that decrypts everyone's everything forever — so *every* issuer's choice is between a
key no holder should accept and a null that lets no holder prove anything. **A new issuer chooses
from the same two.**

### What that changes about the claim

This repository's flagship result has been *"1,992 mints ship a privacy feature nobody can use"*,
which reads as an observation about two companies' decisions. It is not:

> **Backed and Backpack did not choose badly. There is no good choice available.** Anybody issuing
> a tokenized stock on Solana today picks between an ungated token no venue will lend against and a
> venue-admissible token whose every account needs their signature — and, separately, between an
> auditor key that reads everything and one that reads nothing.

That is a property of the substrate, and it is why the answer to "build a competitor" is no. **A
new issuer would hit both walls on its first day.**

### And it is why this project is a layer rather than a competitor

An issuer who genuinely wanted to fix it would have to ship the missing disclosure mechanism
alongside the token. That mechanism is what this repository is. **Confide is what Backed or
Backpack would adopt, not what would replace them** — and a twenty-three-day project claiming to
compete with regulated issuers, with no custody, prospectus or licence behind it, would be read as
naive by anyone who looked.

---

## The ATA holder, reached — 2026-09-19, run on devnet

The section above recorded the ATA case as unsolved and named what was missing: a PDA-owned escrow
cannot apply its own pending balance, because a program holds no keys and `ApplyPendingBalance`
needs the account's owner to sign. That is one instruction, and it now exists.

**The order is inverted.** Instead of the holder handing over an account they cannot hand over, the
**lender** opens an escrow, has it approved, and hands *that* to the loan PDA while it is still
empty. The holder then moves the position in with `spl-token transfer --confidential` — the
ordinary CLI, nothing from this repository — and it lands in the escrow's **pending** balance,
where it is stuck, because the owner is a program. `apply_pending` is the program signing for its
own escrow, and it refuses if a loan record already exists over that escrow, so it cannot be used
to move the balance out from under proofs that were built against it.

Run on devnet, every address readable:

```
holder ATA   F3cAsGnqFda7VrK7qMCVqGX65R5YccfhGupoRzBKB4L8   immutableOwner — never pledgeable
escrow       5vrhLBsyqMybiuH5555cmK15BpA22e8SpbSgY9y9cCku   opened by the LENDER, handed over empty
loan PDA     7aveKFCE3Fr6HvJDQRqSN6RicTJqnxTFuKs7vKt76CZB   741 bytes, v3, floor mode ATTESTED
```

### The statement, fourth version

| the holder's position sits in… | can they pledge it? | who asks the issuer | the floor is |
|---|---|---|---|
| a token account with its own keypair | **yes** | nobody — already approved | **proved** |
| an **associated token account** — the ordinary case | **yes, via the lender's escrow** | the **lender**, once per loan | **attested** |

**What changed is who stands at the gate, not whether the gate is there.** Somebody still asks the
issuer to approve the escrow. But it is now the lender — a repeat counterparty with a relationship,
asking for the accounts they will use — instead of every holder individually, one at a time, to
borrow once. That is the difference between a gate a business walks through and a gate a retail
holder gives up at.

### What it costs, said before anybody reads it as free

**The floor stops being proved.** The escrow's ElGamal key is the lender's, so the lender reads the
balance and signs for it: mode B, `FLOOR_ATTESTED`. For the lender's own book that is no loss —
they are attesting to a number they themselves decrypted, with their own money at risk. **For
anyone else it is worth nothing**, and `lender-check.sh` says so in those words rather than passing
the check quietly:

> *this floor was ASSERTED, not proved — Nothing on chain verified 100000. … If it is not you, this
> record proves nothing about the collateral's size.*

So a loan made this way cannot be sold on, syndicated, or used as evidence to a third party. **The
proved floor and the reachable holder are, for now, alternatives.** Closing that gap means the PDA
proving a floor over a balance whose key it does not hold, and that is not built.
