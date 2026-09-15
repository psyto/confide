# Seizure — taking confidential collateral on default

> **Seizure.** A lender can now verify collateral without the borrower publishing it, and still has
> no way to take that collateral on default. That is the gap between this and lending, and it is not
> a small one.
>
> — README.md, as it read before any of this was built. The sentence is gone from it now;
> section 6 is what replaced it.

`prove-collateral.sh` ends one sentence short of a loan. The lender learns *this account holds at
least X* and cannot act on it, so the position is provable and not pledgeable. This is the design
that closes it, **and it runs on devnet** — section 6. Read section 4 before believing more of that
than is true: the mechanism is real and two of its inputs are asserted rather than proved.

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
owned by a PDA from birth would need the program to configure it. That is avoidable.

The borrower configures and funds the escrow **while they still own it**, which they must anyway:
building the proofs needs the ElGamal secret, and holding the account is how they have it. Then
`SetAuthority(AccountOwner)` hands the account to the loan PDA. After that the borrower cannot move
it and the program can — and **the ElGamal secret stops mattering entirely**, because everything it
was needed for has already been built. A key that no longer opens anything anyone needs is the
cleanest possible answer to "who holds it".

Token-2022 permits that ownership change over a live confidential balance — **confirmed on devnet**:
173,000 moved hands with the escrow and the balance was intact afterwards. It does **not** permit it
on an associated token account, which carries `ImmutableOwner` and fails with error 34 forever, so
the escrow has to be an auxiliary account created against its own keypair. Section 6.

## 3b. What the program must check at origination

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

## 4. Underwriting a quantity nobody can see — mode A

A lender needs loan-to-value, and value is quantity × price. Price is public — it is an equity. The
quantity is exactly what Confide is for. This is where the existing machinery already fits:

`prove-collateral.sh` proves **E holds at least Q_min**, over E's own on-chain ciphertext, revealing
one bit. The loan is written against `Q_min`, not against the true balance:

```
default when   Q_min × price(t)   <   principal × required_ratio
                 │        │              └ in the loan account
                 │        └ asserted by the oracle the loan names
                 └ recorded at origination, NOT verified on chain
```

The borrower's actual position stays confidential, and a borrower who pledges 173,000 and is
underwritten on 100,000 is not required to say so.

**Two of those three terms are taken on trust, and the program says so rather than the prose
hiding it.**

- **`q_min` is recorded, not proved.** `originate` copies it out of the instruction data. It
  receives no proof account and checks nothing. The floor is established **off chain**: the lender
  runs `prove-collateral.sh` against the escrow before agreeing, sees the one bit, and then agrees
  to a number. A program that verified the floor itself would need the equality and range proofs
  re-pointed at a threshold rather than at a transfer, and that is not built.
- **`price` is asserted, not observed.** `seize` takes the price as an argument and requires the
  signature of the one oracle account the loan names. There is no price feed, no oracle state read,
  and nothing binding that number to a market. In `scripts/seizure-e2e.sh` the lender *is* the
  oracle and submits `99` themselves, which is why the run proves the mechanism and not the
  economics.

So the honest sentence for what the e2e demonstrates is: **a transfer the borrower authorised at
origination, executed later by a program, on a condition the loan's named oracle asserted.** The
confidential part is real and complete — nobody learns the amount, the borrower cannot stop it, no
key is reconstructed. The *underwriting* around it is a trusted-oracle loan like any other, and
pointing a real feed at it is integration work rather than research.

This is the same predicate as the NAV floor in `confide-equity`, with the threshold moved — which
is what the README already claimed about liquidation, now with the seizure it needed to be useful.

## 4b. The risk confidential collateral looks like it introduces, and does not

A lender asked to accept collateral they cannot see should ask first whether it can be pledged
twice. With public balances, double pledging is visible to anyone; hide the balance and the check
that would catch it disappears. It is the correct first objection and it is worth answering before
it is raised.

**The collateral is not hidden. It is held.** The escrow's owner, after the handover in section 3a,
is a program address derived from the escrow itself — `[b"loan", escrow]`. A borrower who has handed
it over cannot hand it anywhere else, to this protocol or any other, because they no longer own it.
And because the address is a function of the escrow rather than of the borrower, a second loan
against the same escrow *is the same account*, which `originate` refuses on sight.

So the property is **one escrow, one loan**, decided by arithmetic rather than by bookkeeping, and
it holds across protocols rather than only within this one. Four tests in `mod pledging` hold it
down, including that the recorded bump reproduces the address and that a second deployment of this
program derives elsewhere.

What this does *not* cover: a borrower with two positions can pledge each separately, exactly as
they could in the open. The claim is about one escrow not being spent twice, not about a borrower's
total leverage — which is the lender's own concentration question and is not made harder or easier
by confidentiality.

## 4c. Two modes, and who holds which key

Section 4 gives a lender a floor and one bit. That is the most a borrower can disclose and still be
underwritten, and it is not always what a lender will accept — because it leaves the second
objection unanswered: **how do I monitor the collateral while the loan is open?** A position that
becomes unobservable between origination and default is one a risk owner cannot size.

There are two arrangements, and the difference between them is a single question: **who holds the
escrow's ElGamal key.**

| | mode A — the borrower holds it | mode B — the lender holds it |
|---|---|---|
| lender learns | a floor, proved: `>= Q_min` | the exact balance, continuously |
| ongoing cooperation | the borrower must re-prove | none |
| who builds the seizure proofs | the borrower, at origination | the lender, at origination |
| suits | a borrower who will not disclose size | a lender who will not underwrite what they cannot watch |

Both are the same mechanism with the key in a different hand, which is what *disclosure scoped by
recipient and granularity* means when it stops being a phrase. Section 4 is mode A. The rest of this
section is mode B, because it is the one a lending market is likely to require.

The obvious way to build mode B is the wrong one. Putting the lender's key in the mint's **auditor** slot would
let them read their borrowers' collateral — and every other transfer of that mint, by everyone,
forever. That is the exact power this project exists because nobody can correctly hold. Moving it
from the issuer to the lender changes who holds it and not what it is.

**The escrow's own ElGamal key is the right key.**

| | held by | can |
|---|---|---|
| the escrow's **ElGamal secret** | **the lender** | read the balance. **Not move it** |
| the escrow's **ownership** | the loan PDA | move it. **Not read it** — a program cannot hold a secret |

Token-2022 separates these cleanly: a confidential transfer is authorised by the **account owner's
signature**, while the ElGamal key only decrypts and builds proofs. So reading and spending land on
different parties by construction rather than by agreement.

What this buys, in the order a risk owner asks for it:

- **Continuous visibility of exactly their own collateral**, and nothing else. There is no privacy
  cost: the borrower pledged that position to that lender. The market still sees nothing, which is
  the confidentiality that was ever being claimed — against the public, never against the
  counterparty.
- **No auditor slot, no issuer signature, no mint change.** The whole arrangement is between a
  borrower, a lender and a program, on a mint configured exactly as it already is. An issuer whose
  business is issuing and selling is not asked for anything.
- **The borrower's cooperation is needed once.** Section 2 builds the proofs while the borrower is
  cooperative because the borrower held the key. With the lender holding it, the lender builds
  them, and the only borrower action the design depends on is funding the escrow — which they do
  because they want the loan.

The cost is stated plainly: **the lender learns the exact collateral balance, continuously.** Not a
floor, not a bit — the number. For collateral pledged to that lender this is the normal state of
affairs and is less than a public chain discloses today. It is still strictly more than section 4's
`Q_min` reveals, and a borrower who wants to pledge without the counterparty knowing the size is
not served by this arrangement and should be told so.

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

## 6. What runs, and what running it taught

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

### What a local validator settled, and what it broke

`solana-test-validator` has both the ZK ElGamal Proof Program and Token-2022 as builtins, so the
mechanism can be run without spending devnet rent on every iteration. Three results, two of them
corrections:

**The context state accounts work — all three.** Created and verified into, in six transactions,
and read back from chain: 161 / 385 / 297 bytes, owned by the ZK program, each holding the right
proof context under an authority that is not the borrower — the proofs survive their transaction and
are addressable afterwards, which is the whole premise.

```
ciphertext-commitment equality            161B  type= 3  authority=as recorded  ok
grouped ciphertext validity, 3 handles    385B  type=12  authority=as recorded  ok
batched range proof U128                  297B  type= 7  authority=as recorded  ok
```

A returned signature is not an executed transaction, and the first version of this read the
accounts back before the last one had confirmed — reporting six sent and one uninitialised. The
script confirms each signature now, which is why the table above is evidence rather than optimism.

**The proof type discriminants in the program were all three wrong.** They had been transcribed as
2 / 6 / 9; the chain wrote **3 / 7 / 12**. Reading the accounts back is what caught it. A wrong
discriminant does not fail loudly — it accepts a valid proof of the *wrong kind* in the right slot,
which is the shape of check that reads as rigour and is not. The program now derives them from
`ProofType` rather than transcribing, and pins the three bytes the chain actually wrote.

**A U128 range proof does not fit a legacy transaction once the authority is a separate account.**
Measured, not estimated:

| | bytes |
|---|---|
| verify equality | 557 |
| verify ciphertext validity | 781 |
| verify range U128, authority = fee payer | 1,205 |
| **verify range U128, authority = the loan PDA** | **1,237** |
| the limit | **1,232** |

Over by five. And the authority *must* be the loan PDA — that is the one check section 3 leaves to
this program. Creating the account in its own transaction already bought back what it could.

**Fixed, with an address lookup table.** Not the ZK program id, which cannot be moved: a program a
transaction invokes has to stay in the static account keys. The two that can move are the range
context account and the authority, and moving both costs 37 bytes of table reference to save 64:

| | bytes |
|---|---|
| verify range U128, legacy, authority = the loan PDA | 1,237 — rejected |
| **verify range U128, v0 + lookup table** | **1,211 — lands** |

21 bytes of headroom. `./scripts/seizure-origination.sh` runs the whole of it, and the ordering is
the part worth noticing: the table has to name the range context account, so that account's address
must exist **before** the proof that goes into it does. The script names the accounts in one pass,
builds the table around them, and only then builds the proofs.

The record-account alternative — stage the 1,000 bytes and verify with `VerifyProofFromAccount` —
would also work and is not built. It needs a program willing to write arbitrary bytes into an
account, which is a surface this does not otherwise have.

**Deployment needs `--arch v3`.** The default `cargo build-sbf` target is rejected by the runtime as
an sbpf version that is not enabled.

**Nothing is assumed any more.** `./scripts/seizure-e2e.sh` runs the whole of it against a real
runtime: a borrower holds 173,000 tokens that read as zero in public, builds the three proofs while
they still hold the key, parks them on chain under an authority they do not control, hands the
escrow to the program, and the price falls. Anyone fires the seizure. The lender ends up holding
the position, still confidential.

```
a price that does not trigger it
  at 100c the program refuses — correct
and one that does
  seize at 99c           ok
where the position ended up
  escrow    confidential       0 base units  = 0 units
  lender    confidential       17300000000000 base units  = 173000 units
```

The borrower signs nothing after the handover, no key is reconstructed, no committee is asked, and
the position is confidential on both sides of the transfer the whole way.

**Four things had to be learned by running it, and three of them are not in any documentation.**

1. **The escrow cannot be an associated token account.** An ATA on Token-2022 carries the
   `ImmutableOwner` extension, and `SetAuthority(AccountOwner)` on one fails with error 34 —
   permanently, by design. The escrow has to be an auxiliary account created against its own
   keypair. Section 3a's handover works, and it works only there.
2. **`solana-test-validator` bundles an older Token-2022** — 506,941 bytes against devnet's
   711,053 — and it rejects current confidential-transfer instructions. `Deposit` returns
   `InvalidInstructionData`, which reads as a client bug and is not one. The validator has to be
   started with `--clone-upgradeable-program TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb`.
3. **The issuer has to approve each account, because the mirror mint is configured like NVDAx.**
   `set-auditor` deliberately leaves `autoApproveNewAccounts` false, so a freshly configured
   account is inert until approved and `Deposit` returns `ConfidentialTransferAccountNotApproved`.
   That is not an obstacle to route around — it is the issuer being the gatekeeper this project
   says they are, appearing in the flow exactly where the README says they would.
4. **The lender's decryptable balance is theirs to set.** A confidential transfer credits the
   destination's *pending* balance and carries no AE ciphertext for the receiver, so the lender
   applies the pending credit themselves. A seizure delivers value, not bookkeeping.

**And it runs on devnet.** The same script, `RPC=` pointed at a devnet endpoint:

| | |
|---|---|
| the program | [`Gn3rzw8…QduN`](https://explorer.solana.com/address/Gn3rzw8ULVo676ebnxX6qK3YEQP9T8NHtFVetXW8QduN?cluster=devnet) — 92,032 bytes, 0.4684 SOL |
| the escrow, now the loan's | [`8dbUaPA…aaaG`](https://explorer.solana.com/address/8dbUaPA1kQy8DLWq3jJhJ8rZqxG4STY1QZ7gxNYuaaaG?cluster=devnet) — public balance 0, confidential balance 0 |
| the lender's account | [`Gxtqwzn…hLhr`](https://explorer.solana.com/address/GxtqwznSGEMCpM62Tg6d63WvUfKpKQomnmW94M1vhLhr?cluster=devnet) — public balance 0, holding 173,000 |
| the loan | [`Bu6HviM…UdfX`](https://explorer.solana.com/address/Bu6HviMHncufhC3didbMUgZZHbtvZpKTWGWLBtk8UdfX?cluster=devnet) — 415 bytes, `seized = 1` |

**This document said, for one day, that the deployment was blocked by funding.** It was not. The
balance being read belonged to another project's keypair, because `solana balance` reads whatever
`solana config` points at and on that machine it pointed elsewhere; the funded keypair had 134 SOL
the whole time. The cost was overstated too — 0.936 SOL at the default, 0.489 with `--max-len`,
against a figure of ~1.5 carried over from a different program. What actually delayed this was a
public RPC rate-limiting a 92 KB upload, which a dedicated endpoint fixes.

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

## 8. What is built, and what is next

Everything below the line runs today: `./scripts/seizure-e2e.sh` against devnet, the program at
`Gn3rzw8ULVo676ebnxX6qK3YEQP9T8NHtFVetXW8QduN`, nineteen tests under `cd programs/confide-seizure && cargo test` (a standalone crate, excluded from the workspace the way `aperture` excludes its own
programs, so the root `cargo test` does not cover it), and `./scripts/seizure-status.sh` to read the
settled loan back with no keys.

What is not built, in the order it matters:

1. **The floor the program trusts.** `originate` records `q_min` and verifies nothing, per section
   4. Verifying it on chain means a second proof set pointed at a threshold instead of a transfer.
   Until then the lender establishes the floor off chain and the program takes their word.
2. **The price the program trusts.** One named oracle's signature stands in for a feed. Pointing
   this at a real one is integration, not research, and it is still not done.
3. **Partial seizure.** The proofs fix the amount at origination, so v1 takes the whole escrow. A
   ladder of pre-built amounts is more rent and more origination work, not a new mechanism.
4. **Repayment.** Returning the collateral needs its own pre-verified proof set, built at
   origination alongside the seizure one. Two destinations, one escrow.
5. ~~Invariants in the style of `confide-embargo/tests/invariants.rs`~~ — **done.** Nineteen tests
   over the program, six of them the protocol itself: a loan that still covers itself cannot be
   seized at any price, one in default can be seized by anyone because the caller is not an input,
   opening is not repeatable, an unsigned price is refused, substituting any single account the
   loan recorded is refused, and neither the loan record nor the seize instruction carries the
   position. Each was mutation-checked — deleting the guard turns exactly its own test red.
