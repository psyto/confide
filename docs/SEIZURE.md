# Seizure — taking confidential collateral on default

> **Seizure.** A lender can now verify collateral without the borrower publishing it, and still has
> no way to take that collateral on default. That is the gap between this and lending, and it is not
> a small one.
>
> — [README.md](../README.md#what-it-does-not-do), before this document

`prove-collateral.sh` ends one sentence short of a loan. The lender learns *this account holds at
least X* and cannot act on it, so the position is provable and not pledgeable. This is the design
that closes it. **It is a design, not a shipped claim** — what is built is marked as built, and
every assumption that still needs a devnet transaction to confirm is marked as an assumption.

## 1. Why Token-2022 has no seizure, precisely

Not an oversight, and not fixable by finding the right instruction. A confidential transfer moves
value the sender cannot merely authorise — it must **prove** what it moved:

| proof | what it establishes |
|---|---|
| ciphertext-commitment equality | the declared amount matches the source's own `availableBalance` |
| batched grouped ciphertext validity, 3 handles | the amount re-encrypts correctly under **source, destination and auditor** keys |
| batched range proof U128 | neither the amount nor the remaining balance underflows |

Building all three requires the **source account's ElGamal secret key**. A Solana program cannot
hold one: its state is public, so a key in it is a published key, and the proving is off-chain work
besides. So the usual seizure story — *the protocol takes the collateral* — cannot be written the
usual way. The protocol cannot prove what it is taking.

This splits into two problems that look like one and are not:

1. **Authorisation** — who may sign the move. Token-2022 already solves this: `Transfer` accepts a
   *single owner/delegate* or a *multisignature owner/delegate*, and an owner may be a PDA.
2. **Proof construction** — who can produce the three proofs. Token-2022 solves this for nobody but
   the holder of the source ElGamal secret.

Every seizure design is an answer to **2**. The rest of this document is that answer.

## 2. The answer: prove at origination, fire at default

The borrower knows the amount and holds the key **at origination**, when they are cooperative,
because they want the loan. Default is exactly when they stop being cooperative. So the proofs are
built while cooperation is free, and **pre-verified into on-chain context state accounts** — which
Token-2022 explicitly supports:

> "These instructions can be accompanied in the same transaction or can be pre-verified into a
> context state account, in which case, only their context state account addresses need to be
> provided."
>
> — `spl-token-2022-interface`, `ConfidentialTransferInstruction::Transfer`

`ProofLocation::ContextStateAccount(&Pubkey)` is the variant that consumes them. The proofs sit on
chain, already verified, addressed by pubkey, waiting.

```
ORIGINATION — the borrower cooperates            DEFAULT — the borrower does not
──────────────────────────────────────           ──────────────────────────────────
1. escrow E, owner = PDA of the seizure          6. anyone calls seize(loan)
   program. The borrower funds it and
   cannot withdraw: they do not own it           7. the program checks the predicate
                                                    — a public price against a public
2. credits disabled on E, so the balance            floor, section 4
   ciphertext can never move again
   └ DisableConfidentialCredits                  8. it CPIs Transfer with invoke_signed,
     DisableNonConfidentialCredits                  passing the three context state
                                                    account addresses from step 3
3. the borrower builds the three transfer           └ no key is reconstructed
   proofs for E → lender, full balance,            └ no committee is asked
   and verifies them into context state            └ nobody learns the amount
   accounts
   └ the key is used here and never again         9. the collateral is the lender's
                                                     — and is still confidential
4. the program checks those contexts bind
   to E, to the lender, and to E's current
   ciphertext — section 3

5. the borrower proves E >= Q_min with the
   existing prove-collateral. The lender
   underwrites against that one bit
```

The borrower's ElGamal secret is used once, at origination, by the borrower, on their own machine.
**It is never shared, never split, never reconstructed, and never held by anyone else.** The amount
is not learned by the program, the lender, or any third party at any point in the loan's life.

## 3. What the program must check at origination — less than this document first claimed

**Corrected after writing the program.** The table below originally listed four checks. Three of
them Token-2022 already performs, and re-implementing them in `confide-seizure` would have been
theatre that read as rigour:

> The processor recomputes the source's new available balance from the account and the transfer's
> own ciphertexts, and rejects a `Transfer` whose equality context does not match it. It checks the
> validity proof's second handle against the **destination account's** ElGamal pubkey, and the
> third against the **mint's** auditor. A proof set that is stale, points at a different account, or
> was built for a different destination fails at transfer time without this program's help.

What Token-2022 has no opinion about is **who may close the proofs**, so that is the check the
program actually makes, and the only one:

| check | against | what it stops |
|---|---|---|
| each context state account's authority | the loan PDA | the borrower closing the accounts and withdrawing the proofs the day before default — the one attack the token program cannot see |
| each context's proof type | the type that slot must hold | a valid proof of the wrong kind in the right position |
| every account the transfer touches | the addresses recorded in the loan | a caller redirecting a seizure by passing different accounts |

The original table's other rows are not wrong about what must be true. They were wrong about who
has to establish it.

## 3a. The escrow never needs a PDA to configure it

Also found by building it. `ConfigureAccount` requires the account owner's signature, so an escrow
owned by a PDA from birth would need the program to configure it — which is why assumption 1 below
was written. It is avoidable.

The borrower configures and funds the escrow **while they still own it**, which they must anyway:
building the proofs needs the ElGamal secret, and holding the account is how they have it. Then
`SetAuthority(AccountOwner)` hands the account to the loan PDA. After that the borrower cannot move
it and the program can — and **the ElGamal secret stops mattering entirely**, because everything it
was needed for has already been built. A key that no longer opens anything anyone needs is the
cleanest possible answer to "who holds it".

Whether Token-2022 permits that ownership change on an account with a non-zero confidential balance
is **not confirmed** — the instruction's own documentation says nothing either way, and the
restriction, if any, is in the processor rather than the interface. It replaces assumption 1 with a
narrower one rather than removing it.

## 3b. What the program must check at origination, or the design is worthless

A pre-verified proof is only as good as its binding. The borrower builds these proofs, and a
borrower who could point them somewhere else would have built an escape hatch. Each proof's context
is readable from its context state account, so the program checks rather than trusts:

| check | against | what it stops |
|---|---|---|
| equality context's source ElGamal pubkey and ciphertext | E's own, re-read from E | proofs about some other account, or about E at a different balance |
| validity context's destination handle | the lender's registered ElGamal pubkey | the borrower seizing to themselves |
| validity context's auditor handle | the mint's `auditorElgamalPubkey` | a transfer the auditor cannot read — the slot this whole project is about |
| context state authority | the program's PDA | the borrower closing the accounts and withdrawing the proofs the day before default |

That last row is the one an attacker reaches for. Context state accounts are closable **by their
authority**; if that authority is the borrower, seizure can be disarmed at will. The authority must
be the program.

## 4. Underwriting a quantity nobody can see

A lender needs loan-to-value, and value is quantity × price. Price is public — it is an equity. The
quantity is exactly what Confide is for. This is where the existing machinery already fits:

`prove-collateral.sh` proves **E holds at least Q_min**, over E's own on-chain ciphertext, revealing
one bit. The loan is written against `Q_min`, not against the true balance:

```
default when   Q_min × price(t)   <   principal × required_ratio
                 │        │              └ public, in the loan account
                 │        └ public, an oracle
                 └ public, proven at origination and no more than the truth
```

Every term is public, so the predicate is computable on chain and by anyone, and the borrower's
actual position stays confidential. **The lender is over-collateralised by construction** — the
borrower proved a floor, and holds at least it. A borrower who pledges 173,000 NVDAx and proves
100,000 is underwritten on 100,000 and is not required to say so.

This is the same predicate as the NAV floor in `confide-equity`, with the threshold moved — which
is what the README already claimed about liquidation, now with the seizure it needed to be useful.

## 5. What this costs, stated before anyone discovers it

- **Full seizure only.** The proofs fix the amount at origination, so v1 seizes the whole escrow.
  Partial liquidation needs a pre-built ladder of amounts (10 % / 25 % / 50 % / 100 %) with a proof
  set each, and the program picking one. That is more rent and more origination work, not a new
  mechanism, and it is not in v1.
- **The escrow is frozen.** Credits are disabled so the ciphertext the proofs bind to cannot move.
  The borrower cannot top up, cannot partially withdraw, and cannot add collateral without
  unwinding the loan and re-originating. A real cost, and the direct price of not having a
  committee.
- **Repayment is a second proof set.** Returning the collateral is a transfer out of E to the
  borrower, and needs its own pre-verified proofs, built at origination alongside the seizure set.
  Two destinations, two ladders, one escrow.
- **The oracle is the remaining trust.** Price is public but someone names it. This design does not
  improve on any other lending protocol here and does not claim to.
- **Q_min leaks a bound.** The lender learns a floor, permanently and publicly. That is strictly
  less than today, where the whole position is public, and it is not nothing.

## 6. What is built, and what is assumed

**Built, and already running in this repository:**

| | |
|---|---|
| the three-proof vocabulary, and both proofs going to Solana's live ZK program | `./scripts/prove-collateral.sh`, `./scripts/devnet-verify.sh` |
| proving over an account's **own** on-chain ciphertext rather than an invented one | `crates/confide-ct/src/prove_collateral.rs` |
| generating and holding an account's ElGamal key, so proofs can be about it | `./scripts/provision-account.sh` |
| the auditor slot filled on a mint configured like NVDAx | `./scripts/set-auditor.sh` |
| the floor predicate and the corporate-action restatement it must survive | `cargo test -p confide-equity` |

**Settled since this document was written**, by `./scripts/seizure-proofs.sh`:

> The three proofs compose, and Solana's live ZK ElGamal Proof Program accepts all three. Measured
> on devnet, one instruction each, with the compute limit raised so the numbers are costs rather
> than ceilings:
>
> | proof | compute units |
> |---|---|
> | ciphertext-commitment equality | 6,400 |
> | batched grouped ciphertext validity, 3 handles | 16,400 |
> | batched range proof U128 | 200,000 |
>
> **All of it is paid at origination.** The seizure transaction cites the context state accounts and
> re-verifies nothing, so the ~223k units above never recur — which is the second reason to
> pre-verify, after the borrower not being there to help.

Five invariants hold it down — `cargo test -p confide-ct`, and they are claims rather than coverage:
the remaining-balance ciphertext is *computed* homomorphically and opens to the remaining balance
(S1); the **auditor's** handle opens the seized amount, so a seizure is not a hole in the disclosure
this project argues for (S2); the batched bit lengths sum to the 128 they claim (S3); an amount too
large for the 48-bit transfer encoding is refused rather than truncated (S4); and a full drain
leaves a ciphertext that opens to exactly zero (S5).

**Still assumed, and each one is a devnet transaction away.** Listed because a design whose
assumptions are buried is a pitch:

1. A **PDA can own a confidential token account holding a balance** — reached by `SetAuthority`
   after the borrower funds it, per section 3a, so the PDA never configures anything. Whether the
   processor allows that ownership change with a live confidential balance is the open half.
2. A **context state account survives** from origination to default and is consumable by a CPI'd
   `Transfer` weeks later. The instruction documents the mechanism and `build-seizure-proofs` emits
   the writing transactions; the lifetime is untested here.
3. `DisableConfidentialCredits` **freezes the ciphertext** against every path that could move it.
4. The processor accepts a **PDA authority** for `Transfer` via `invoke_signed` with proofs supplied
   as context state accounts.

**What is not yet shown, stated plainly:** the run above is over a throwaway escrow, not over a live
account's own on-chain ciphertext. That is a fact about the proof system and does not depend on
which account the ciphertext came from — but the stronger form, the one `prove-collateral.sh`
already meets, needs the holder's keys and is `./scripts/seizure-proofs.sh <account> all keys.json`.

Any one of these failing changes the design rather than the goal, and the fallback is the committee
this design was written to avoid: `confide-embargo`'s k-of-n already splits a secret, and could
split E's ElGamal key instead. That version works for certain and is strictly worse — k colluding
agents could read the collateral and steal it, where here nobody can.

## 7. Why this needs no committee, when the embargo does

Worth stating, because the two mechanisms sit in one repository and look like they should share a
solution.

The embargo opens at a time nobody may bring forward and the holder may not prevent, over content
that must stay sealed **until** then. Something must hold the seal across that interval, and in the
absence of a cryptographic clock that something is people — `k = 3, n = 5`, with the trade between
I1 and I2 that cannot be minimised on both sides.

Seizure has no such interval. What the transfer does is fully determined **at origination**, so it
can be committed then and left on chain in a form that is already verified. There is nothing to
keep secret between origination and default, because the proofs reveal nothing: they are proofs.
**A mechanism whose outcome is known in advance does not need a quorum to remember it.**

## 8. Build order

1. ~~`confide-ct/src/build_seizure_proofs.rs`~~ — **done.** The three transfer proofs, accepted by
   the live ZK program, with the context-state writing transactions emitted. Section 6.
2. ~~`confide-seizure` program~~ — **written and building to SBF** (99,592 bytes), with five
   invariants over the account layout and the default predicate: `cd programs/confide-seizure &&
   cargo test`. It is a standalone crate, excluded from the workspace the way `aperture` excludes
   its own programs, so the root `cargo test` does not cover it. **Not yet deployed:** the devnet
   keypair holds 0.62 SOL against the ~1.5 SOL a deployment costs, and the faucet refuses small
   accounts. A local validator is the route that does not need funding.
3. `scripts/escrow-account.sh` — stand up a PDA-owned confidential escrow. Settles assumption 1.
4. `scripts/seize.sh` — default, then seizure, on devnet, end to end, with the balances read before
   and after.
5. Invariants in `tests/`, in the style of `confide-embargo/tests/invariants.rs`: seizure is
   impossible before the predicate holds, guaranteed after it, and reveals no amount either way.
