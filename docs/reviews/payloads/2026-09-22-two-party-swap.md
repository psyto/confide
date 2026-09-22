# Review request — the two-party confidential swap, built and settled today

**Adversarial review wanted, on a protocol that moves value.** This settled on devnet this morning
between two keypairs that shared nothing but public keys. If it has a hole, it has it now, and
finding it here costs nothing.

You have the repository at `/Users/hiroyusai/src/confide` read-only. Read the real files rather than
this description where they disagree — and say so if they do.

## What was built

| | |
|---|---|
| `crates/confide-ct/src/swap_tx.rs` | split into `build` (assemble UNSIGNED from pubkeys) and `sign` (add exactly one signature via `partial_sign`), keeping the original both-keys-on-one-machine path |
| `scripts/lib/swap.sh` | `swap_leg` (build one leg's proof contexts) and `swap_look` (decrypt the counterparty's amount), extracted from `scripts/swap-e2e.sh` |
| `scripts/swap-offer.sh` | step 1 — publish accounts, the RECEIVING ElGamal pubkey, and the two amounts |
| `scripts/swap-accept.sh` | step 2 — counterparty builds THEIR leg's proofs |
| `scripts/swap-settle.sh` | step 3 — offerer builds theirs, decrypts the acceptor's amount, adds signature 1 of 2 |
| `scripts/swap-sign.sh` | step 4 — acceptor decrypts the offerer's amount, adds signature 2, sends |
| `scripts/testbed-join.sh` | ElGamal key files made durable and per-mint |

## The claimed safety property, which is the thing to attack

> **Each party decrypts the amount the other will actually send, out of a proof context the chain
> has already verified, before signing — without the other's cooperation, and without revealing it
> to anyone else. A transaction carrying one of two signatures cannot execute.**

## Questions, hardest first

1. **Between step 3 and step 4 the acceptor holds a half-signed transaction.** Can they do anything
   with it other than sign and send? Substitute an instruction, reorder, change an account, replay
   it later, or hold it and send it at a moment that advantages them? What bounds the window?

2. **Can the offerer build a transaction whose second leg is not the one the acceptor proved?**
   They assemble it in step 3 from `accept.json`. `swap_tx.rs` cites contexts by address and the
   header claims Token-2022 re-checks that each context describes that source and destination.
   **Verify that claim against `spl-token-2022-interface` rather than taking it.** If it is false,
   the acceptor is signing something they did not build.

3. **What exactly does each side verify, and is it enough?** `swap-check`
   (`crates/confide-ct/src/swap_check.rs`) reads a validity context and checks the recipient handle
   against the reader's ElGamal pubkey, then decrypts lo/hi. Does it bind to the SOURCE, the MINT,
   or the transaction it will be cited in? A context that is addressed to me for the right amount
   on the wrong mint would pass a check that only looks at handle and amount.

4. **Does the four-message ordering have a first-mover disadvantage?** The acceptor builds proofs
   in step 2 before anyone has signed, spending real fees and rent. Can the offerer abandon and
   leave them holding useless contexts? Is that recoverable, and does anything say so?

5. **`partial_sign` and the blockhash.** `swap-tx sign` re-signs against
   `tx.message.recent_blockhash`, taken from the transaction itself. Is that safe, or does it let a
   stale or attacker-chosen blockhash through? The blockhash is set in step 3 by the offerer.

6. **The extraction.** `swap_leg` differs from the original `build()` in one way: it takes the
   counterparty's ElGamal pubkey as a string where the original read it from their key FILE. Check
   the extraction did not change anything else — argument order, the fee-path branch, the batching
   loop and its `skip` counter, the address-lookup-table handling.

7. **`testbed-join.sh` key files.** Named `<mint first 8 chars>-keys.json` under
   `~/.config/confide/swap`. I have checked: no two of the 1,992 mints share their first 8
   characters. Is the scheme wrong for another reason — two clusters, an account re-joined with a
   fresh key silently overwriting the old one, permissions on a directory holding an ElGamal secret?

8. **Anything in the four scripts that reads as safe and is not.** Shell quoting around addresses
   and amounts, `read -r` splitting, an error path that exits 0, a check whose failure is a warning.

## What is NOT wanted

Style, naming, or "consider adding tests". If the protocol is sound, say so in one line and spend
the rest on the sharpest thing you did find.
