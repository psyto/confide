# Review the implementation, not the strategy

Four changes went in today, all written by one author with no second reader. Review them
adversarially. `git diff 5a8142e..HEAD -- programs crates` is the range; `docs/SEIZURE.md`
sections 4b, 4c, 4d and the `## 4. mode A` section state what they are supposed to mean.

The buyer these were built for is a **vault curator on Kamino** — the venue holding 82.6% of
tokenized-stock lending on Solana, which already takes xStocks as collateral with every position
public. The asset in front is `SPCX` / `SPCXx`, tokenized SpaceX, issued by both Backpack and
Backed, both with `auditorElgamalPubkey: null` and `autoApproveNewAccounts: false`.

## What was changed and why

1. **One escrow, one loan** (`loan_address`, `mod pledging`). Claim: confidential collateral does
   not reintroduce double-pledge risk, because the escrow is *held* by a PDA derived from the escrow
   rather than merely hidden.
2. **Two key-holding modes** (`docs/SEIZURE.md` 4c, documentation only). Claim: the lender may hold
   the escrow's ElGamal key and thereby read the balance continuously **without being able to move
   it**, because Token-2022 authorises a transfer with the owner's signature while the ElGamal key
   only decrypts and builds proofs. Claim: this needs no auditor slot and no issuer signature.
3. **De-shield** (`compose_deshield`, `mod deshielding`, program instruction 2, `withdraw_instruction`).
   Claim: `Withdraw` has no recipient, so the proofs bind to no destination, so a permissionless
   liquidator who did not exist at origination can take the collateral with an ordinary SPL
   transfer. `ElGamal::encode` is crate-private in zk-sdk 7, so the withdrawn amount is encoded
   with a **zero Pedersen opening** instead.
4. **On-chain floor verification** (`floor_is_proved`, `mod floor`). Claim: the program now
   establishes that the escrow holds at least `q_min`, by checking that the range proof's commitment
   equals the equality proof's commitment minus `q_min·G`, using two curve25519 syscalls. Before
   this, `q_min` was copied out of instruction data and believed.

Plus a refactor: `deshield` first duplicated the settlement preconditions; both paths now share
`may_settle`.

## What I want

1. **Is the floor check sound?** Offsets into the two proof contexts, the scalar encoding of
   `q_min`, the choice of `G`, whether equality-plus-range-minus-`q_min·G` actually establishes
   `balance >= q_min`, and what it does **not** establish. Is there an input for which it passes and
   the balance is below the floor?
2. **Is the zero-opening substitution correct?** Is `pubkey.encrypt_with(amount, &default_opening)`
   byte-identical to what Token-2022 subtracts internally during `Withdraw`, or merely equal under
   some conditions? If the program builds a proof over a ciphertext the token program computes
   differently, it fails at default, which is the worst possible moment.
3. **Is claim 2 true?** Can a party holding only the escrow's ElGamal secret move funds, freeze
   them, or learn anything beyond that escrow? Is "no issuer signature required" actually true for
   mode B end to end, including funding the escrow on a mint with `autoApproveNewAccounts: false`?
4. **Is claim 1 true across protocols**, or only within this program? What could let the same
   collateral back two loans?
5. **Does `may_settle` actually cover both paths**, and is anything the transfer path checks and the
   de-shield path needs now missing?
6. **What is overclaimed in the prose**, in `docs/SEIZURE.md` or the commit messages.

A cryptographic or serialisation flaw here collapses the whole authority claim, so weigh accordingly.
Do not review the 27-day plan. Do not praise.
