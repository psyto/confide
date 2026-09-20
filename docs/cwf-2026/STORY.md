# The story

The one place the narrative lives. The submission text and the video narration both draw from here,
so they cannot drift from each other — and every figure below is in a file that a stranger can
recompute.

---

## 1. A privacy feature that nobody can use

Tokenized equity on Solana is built on Token-2022, and Token-2022 can hide a balance. Every
tokenized-equity mint in existence ships that capability.

**All 1,992 of them ship it switched off in the same way.** The auditor slot — the one mechanism
for showing a balance to someone who needs to see it — is empty on every single mint. And
`autoApproveNewAccounts` is `false` on every single mint, so no holder can open a confidential
account without the issuer signing for it.

Backed, Backpack and PreStocks each arrived at that configuration independently. Measured, not
assumed: `./scripts/slot-scan.sh`, over the whole population rather than a sample.

So the feature exists, and it is unusable. That is where this project started.

## 2. A month of walls, and every one of them was a pool

The obvious use is collateral. A fund holding tokenized NVDA wants to borrow against it without
publishing how much it holds, because in equities the size *is* the information.

**Wall one: the venue.** Kamino lends against these tokens today — $22.0m deposited, $83.0m of
borrowing authorised. Its own source refuses any account that holds confidential value at all.
**$0 of that $83m is reachable confidentially**, and no amount of engineering on this side changes
it.

**Wall two: the escrow.** So build the loan bilaterally instead — two parties, one escrow held by a
program, a floor proved over a ciphertext by Solana's own ZK program, seizure on a priced default
that the borrower cannot refuse. It works. Two loans sit on devnet: one seized, one released, both
readable by anyone.

But an escrow is a *new* confidential account, and new confidential accounts are wall one again,
wearing a different hat.

**Wall three: the wallet.** Hand over an account you already have, then. Except that a wallet
creates an *associated* token account, an ATA carries `ImmutableOwner`, and `SetAuthority` on one
fails by design. The ordinary holder was unreachable.

That third wall fell this week, by inverting the order: the **lender** opens the escrow, gets it
approved, and hands it to the loan program while it is still empty; the holder then moves their
position in with the ordinary CLI. It runs on devnet. **And it costs the proof** — the escrow's
keys are now the lender's, so the floor becomes the lender's assertion rather than something the
chain verified.

**And underneath all three, the flaw that was always there:** the loan program moves no money.
`principal` is an input to the default test and nothing is ever disbursed. "Did the lender pay?"
and "did the borrower repay?" are not questions the chain can answer. A mechanism that settles the
collateral perfectly and leaves the money on a handshake.

## 3. The turn

The founder asked a different question: could two holders exchange positions atomically — one
transaction, flash-loan style, no counterparty risk?

Working it out produced a structural fact before it produced a product.

> **Confidentiality and pooled liquidity are mutually exclusive, and not by anyone's choice.**
> A pool's reserves are public state. A trade moves them by exactly the traded amount, so the
> amount is recoverable by subtracting two consecutive public states. An order book publishes
> fills. A lending reserve publishes its totals.

That reads like a limitation. It is the opposite: **it explains the whole month in one sentence.**
Every wall was a pool. And it says exactly where the buildable ground is — **confidential
composition works wherever the counterparty is a party rather than a pool.**

Then the second realisation, which is smaller and does more work:

> **A swap needs no escrow at all.**
>
> A loan needs a third thing holding the collateral because it has to survive one party refusing
> to cooperate *over time*. A trade happens at an instant. On Solana, an instant is atomic — so
> the transaction *is* the escrow.

Every wall goes at once. No program to deploy or audit. No approval beyond what each account
already needed to exist. `ImmutableOwner` becomes irrelevant, because nothing changes hands.
**And nothing is left outside the transaction to be promised.**

## 4. What that let us build, and what it cost to find out

**A confidential atomic swap.** Two holders, two mints, one transaction — 29,417 compute units,
1,006 bytes, and four associated token accounts that all still read a public balance of **0**.

The one danger a confidential swap has is its own: the amounts are encrypted, so a party could sign
a transaction whose other leg sends far less than was agreed. **It is answerable before signing, by
the recipient alone.** A confidential transfer encrypts the amount under three keys at once — the
sender's, the **recipient's**, and the auditor's — and that ciphertext is what the proof context
holds. So each side decrypts the other's amount straight out of the already-verified context:

```
✓ it is addressed to your key
✓ it will move 8750000000000 base units to you
    decrypted from the verified context, by you, without anyone's cooperation

If that is not the amount you agreed, do not sign. Nothing has happened yet.
```

No trust, no floor proof, no third party, nothing revealed to anyone else.

**Then the measurement that widened the whole thesis.** A stock-for-cash trade needs cash that can
move confidentially. USDC, USDT and USDS cannot — legacy SPL, no extensions at all. **PYUSD and
USDG can**, and they arrive at the *identical* configuration: gate closed, auditor slot empty, and
**the same key on both** — `2apBGMsS6ti9…` — as confidential authority, permanent delegate and
freeze authority. That the two are one issuer's is an inference from the shared key; that the
configuration is identical is a reading.

> **So this was never a story about two equity issuers making a poor choice.** PayPal's dollar
> ships the same unusable privacy feature behind the same gate. Every regulated Token-2022 issuer
> arrives here, whatever they are issuing. It is a property of the substrate, with four independent
> witnesses.

**So: delivery versus payment.** 50,000 shares for $8,750,000 — $175 a share — in one transaction,
with neither size nor the price it implies published to anyone.

And then the last piece, which is the one worth showing. PYUSD carries a transfer fee config, and a
mint that carries one refuses the plain confidential transfer outright — at **0 bps**. So the cash
leg needs `TransferWithFee`: **five** proofs instead of three, and a range proof too large to
verify from instruction data at all (1,269 bytes against a 1,232 limit), which has to be written
into a record account and cited by offset.

The result is a single transaction carrying `confidentialTransfer` **and**
`confidentialTransferWithFee` together:

```
5ZrJPGRLHKzzR1us4KF3kf9z5hSgvQLabHKQbkMmCSkGEGXAkC8QA7JtnMhsVBsCJzrW5a75s9LJsxaaKsqesZug
  2 signatures · 2 instructions · 59,804 compute units · 1,074 bytes · no error
```

**Two assets whose rules do not match, settled atomically, neither size published.**

## 5. What it is

A clearing house exists because neither side of a trade wants to go first. Traditional finance
answers that with a central counterparty, membership, margin, and a day of settlement lag —
institutions built to stand between two people who cannot both act at the same instant.

**Delivery versus payment is now a property of a transaction.** And the confidential version means
neither side has to publish what the clearing house would have been told anyway.

That is the product: **settlement for tokenized equity that needs no venue, no custodian, no
clearing member, and no disclosure of size.**

## 6. What is not true, said here rather than found later

- **Traction is zero.** Nobody outside this repository has used any of it. No pilot, no design
  partner, no letter of intent.
- **The issuer gate is unchanged.** A confidential position in either asset still needs its
  issuer's approval, so a real trade needs the equity issuer *and* Paxos. Every wall above was
  removed except the first one.
- **Matching is unsolved**, and it is the same two-sided problem as finding a lender. The
  difference is only that both sides are holders and neither has to underwrite anything.
- **Price is off chain.** Nothing here says 50,000 shares are worth $8.75m. That is what the two
  parties are for.
- **Anything against a pool stays impossible**, and not for a fixable reason — §3 is the proof.
- **The loan still cannot do both at once**: a proved floor and an ordinary holder are, for now,
  alternatives.
- **A confidential flash loan is blocked** — a program cannot read a confidential balance, so
  repayment would have to be proved inline, and the proof does not fit in the transaction. Blocked
  by transaction size, not by cryptography, and that distinction is the honest way to say it.

## 7. Why us

The project did not find this by being clever about markets. It found it by **measuring what is
actually deployed, repeatedly, and by writing down the corrections.** The auditor slots, the
approval gate, Kamino's refusal at a pinned commit, `ImmutableOwner`, the transaction sizes, the
compute budget, the stablecoins — all read off chain, all recomputable, several of them overturning
something this repository had already claimed in public.

**104 tests, 44 of them over the on-chain program. Every headline number is generated, and a
consistency check fails the build when prose and measurement disagree** — today it reported two
disagreements, correctly, and both times it was the prose that was wrong.

The strongest thing here is not the transaction. It is that everything above can be run again by
somebody who does not believe it.
