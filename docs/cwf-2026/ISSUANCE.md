# Confidential issuance and redemption — evaluated, 2026-09-21

Asked by the founder: is *Confidential Issuance & Redemption DvP* the strongest next use case for
Confide, and what is wrong with it. Implementation deliberately not started.

**Facts and hypotheses are separated throughout.** This repository has been wrong by reading a
derived artifact and believing it was the real one, so what follows names which is which.

---

## What is already true, checked in the repository today

| | evidence |
|---|---|
| **The issuer already approves an investor's account, on devnet, in one command** | `scripts/testbed-join.sh:80` — *"the ISSUER approves it"*, signed with the published approval authority, on a mint whose `autoApproveNewAccounts` is false |
| **Asset against cash settles in one transaction, both legs confidential** | `MODE=dvp ./scripts/swap-e2e.sh`; `swap-check` decrypts the counterparty's leg **before** signing |
| **The cash leg survives a fee-bearing mint** | five proofs instead of three, one staged through `spl-record` |
| **The gate is universal** | `autoApproveNewAccounts` false on **1,992 of 1,992** |
| **`deshield` is disabled** | `docs/27-DAYS.md:323`. Nothing in this repository takes a confidential balance back to a public one |

**So step 1 of the proposal is not a plan. It runs.** That is the single strongest thing about it
and it should be said first in any pitch: the issuer-approves-investor step, which is the wall
everywhere else, is the part already demonstrated.

---

## The strongest argument for the proposal

**It converts this project's largest admitted gap into a non-problem, and its blocker into
workflow.**

- *Matching* is listed under **what is not built** in `README.md` and `_submission/full.md`, and is
  deliberately not being built ([`../SEC-EXEMPTION.md`](../SEC-EXEMPTION.md): Rule 3b-16). In
  issuance **there is nothing to match.** The issuer is the counterparty by construction.
- The issuer gate is the reason 330,266 accounts hold nothing confidentially. In issuance,
  **approving the investor's account is already the issuer's job** — it is allocation and
  eligibility, work they do anyway. Confide stops fighting the gate and starts standing on it.

That is a structural fit, not a repositioning. It is the best thing in the proposal.

---

## The objection that decides it

**In primary issuance both parties already know each other and the amount.** The issuer must know
the investor — that is what eligibility means — and both know the size because they agreed it.

So the claim compresses:

> from **"neither side publishes what moved"**
> to **"the public cannot see the allocation."**

Both are true. The second is a **smaller and much less surprising** claim, and a judge with finance
background will ask the obvious question: *in a permissioned offering where the issuer does the KYC,
who is being protected from whom?*

**There is an answer and it must be said in this exact form, not as "confidential DvP":**

> **The other investors in the same offering, and the market.** Allocation size is the book. It
> reveals who got what, and by inference the demand curve the issuer faced. In a bond, a fund
> interest or private credit that is competitive information on both sides of the table, and today
> putting it on a public chain publishes it to everyone forever.

If the pitch cannot land that sentence, the issuance framing is weaker than the block-trade framing
it replaces, because the block trade's *"neither side publishes"* needs no such explanation.

---

## The hypothesis to test before committing — redemption may leak the amount

**HYPOTHESIS, NOT MEASURED.** *"Redemption is the arrow reversed"* may be false.

A token redeemed is normally **burned**. A mint's `supply` is public state. If the issuer burns on
redemption, **supply falls by exactly the redeemed amount**, and the size is recoverable by
subtracting two consecutive public states.

**That is the identical argument this repository already makes about pool reserves**, in
`README.md` §*why not a pool, ever*:

> a pool's reserves are public state and a trade moves them by exactly the traded amount, so the
> size is recoverable by subtracting two consecutive public states

If it holds, the issuance leg is confidential and the redemption leg is not, and a pitch that says
*"redemption is the same thing reversed"* has a hole a judge can put a finger through.

**Escape hatches worth testing, each of which changes the claim:**

1. **The issuer does not burn.** It holds the token in treasury and re-offers it. Supply is
   constant, nothing leaks — but this is a **buyback**, not a redemption, and it means the issuer
   carries the asset.
2. **Burns are batched.** Individual redemptions are not separable from a periodic supply change.
   Real, and it makes redemption *delayed* rather than atomic, which costs the thing Confide sells.
3. **`deshield` first.** Taking a confidential balance back to public in order to burn it publishes
   the amount by construction. `deshield` is disabled here, and this is a reason to be careful about
   finishing it rather than a reason to hurry.

**This is the cheapest and highest-value work available this week.** It is a measurement, it is the
kind this repository is good at, and the answer is worth having either way — a confirmed leak is a
finding, and a clean escape hatch is the pitch's missing paragraph.

---

## The other weaknesses, stated plainly

- **"The issuer is the customer" was retracted in this repository on 2026-09-16** and the
  retraction is in `README.md`, which every judge reads. The new claim is genuinely narrower — the
  issuer as *economic counterparty at the moment of sale*, not as *buyer of a privacy product* —
  but **a reader will not make that distinction for you.** If issuance leads, the correction block
  has to be rewritten to say which claim survived and which did not.
- **Nobody has been asked.** No issuer, no investor. The proposal's entire value hypothesis is
  untested, and `traction is zero` does not change.
- **Issuance is more regulated, not less.** Allocation, accreditation, transfer restrictions and a
  transfer agent all sit in this workflow, and Confide does none of them. *"How does this interact
  with the transfer agent?"* has no answer today and will be asked.
- **The incumbents' answer is "permissioned".** Securitize, BUIDL and Ondo run allowlists, and
  their implicit position is that a small known participant set makes public amounts tolerable.
  Confide's differentiator has to be sharper than *amounts hidden*, because inside an allowlist
  hiding from the public is less urgent than hiding from a counterparty — and issuance has no
  hostile counterparty.
- **The demo is nearly the current demo.** That is a strength for building it and a risk for
  novelty: a judge who saw `swap-e2e.sh` will ask what changed, and *"one of the two parties is now
  called the issuer"* is a thin answer unless the allocation-secrecy sentence above carries it.

---

## A stronger claim sits next to it, and it is compelled rather than elective

The SEC's 17 September exemption requires tokenized NMS stock to convey **the same dividends and
the same voting rights** as the underlying, and requires the tokenizer to deliver proxy material
([`../SEC-EXEMPTION.md`](../SEC-EXEMPTION.md)).

**You cannot pay a dividend pro rata to a holder whose balance you cannot read.**

So a confidential tokenized share creates a need for **one party to learn one number, for one
purpose, at one time** — the registrar, at the record date. Token-2022 offers a global auditor key
that reads everyone forever, or null. Every issuer picked null.

| | |
|---|---|
| **issuance** | the better **demo**: buildable now, solves matching by construction, and the first step already runs |
| **corporate actions** | the better **argument**: the need is created by regulation dated three weeks before judging, and neither of Token-2022's two options can serve it |

**They are the same product.** Issuance opens the account and moves the first position; corporate
actions are why that position has to be able to prove something later. A pitch that has only the
first is a settlement rail; one that has both is a lifecycle.

---

## Priority, and what to build before 10-12

| | verdict |
|---|---|
| **1. Two-party settlement as commands** | **BUILD THIS WEEK.** `swap-offer` / `swap-accept`. **Issuance is a two-party trade where one party is the issuer**, so this is not a competing item — building it builds issuance, and it is also what makes check-in 1's *"runnable by a stranger"* true rather than half true |
| **2. Issuance as the demo narrative** | **BUILD THE SCRIPT, NOT THE VIDEO.** `docs/27-DAYS.md` week 2 already says the narrative gets drafted and tested against the artifact now rather than in week 4. Test whether the allocation-secrecy sentence survives contact with the thing |
| **3. Redemption** | **MEASURE FIRST, CLAIM NOTHING.** See the hypothesis above. Do not put *"redemption is the arrow reversed"* in a video until the supply question is answered |
| **4. Direct confidential RFQ** | **ROADMAP ONLY**, and say in the same breath that **discovery is not solved**. Two parties who already know each other quoting confidentially is settlement with extra steps; the moment it helps them *find* each other it is Rule 3b-16 |
| **5. Arcium or any external matching** | **NO**, and the founder's reason is the right one. It reintroduces the party whose absence is the entire finding |

---

## Other chains

**Recommendation: stay on Solana, and say why rather than leave it implied.**

Confide is Token-2022 confidential transfers plus Solana's ZK ElGamal Proof Program. **Neither
exists anywhere else.** A port is not an integration, it is rebuilding the cryptographic layer,
which is the project. Official Rules §8(e) asks how well the work **composes with other
primitives** — depth on two primitives nobody else has composed is a better answer to that
criterion than presence on five chains.

The one honest adjacency, and it is research rather than a track entry: **the measurement travels
even where the mechanism does not.** *"A privacy feature shipped and unused"* is a question askable
of any chain, and nobody has asked it of any. Worth a sentence, not a quarter.

---

## Positioning

> *"Confide is the confidential settlement layer for the lifecycle of regulated tokenized assets —
> issuance, redemption, and block trades."*

**Three problems.** *Lifecycle* is a category word and says nothing. *Regulated* is a claim the
repository does not back — Confide discharges no filing and says so. And a list of three is what a
pitch says when it has not chosen.

**Sharper, and falsifiable:**

> **Confide settles tokenized assets against cash in one transaction. The chain records that it
> happened, not how much.**

**For the issuance framing specifically**, the sentence that carries the whole argument:

> **Your allocation is not the market's business.**

---

## The three things to build this week

1. **Measure the redemption leak.** A day at most. It decides whether the proposal's second half is
   real, and it is a finding either way.
2. **`swap-offer` / `swap-accept`.** The two-party rail. It is the issuance rail, and it turns a
   half-true sentence in a submitted video into a true one.
3. **Draft the issuance narrative against the artifact.** Not the video. Find out this week whether
   *"your allocation is not the market's business"* survives being said next to what actually runs.

**Not this week:** the pitch and demo videos (founder: final week), the key rotation, RFQ, any
second chain.
