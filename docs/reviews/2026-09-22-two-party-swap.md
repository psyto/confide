# Codex on the two-party swap — 2026-09-22

Request: `docs/reviews/payloads/2026-09-22-two-party-swap.md`. Asked before writing the check-in, and
before any of it was committed, because the four-message protocol was new and I wrote all of it.

**It found two ways to lose money and one way to lose a key, and the critical one was in the step I
had described as the safety step.** Ninth review; the fifth to find something I could not.

## The critical one: step 4 was a blind signing oracle

`swap-sign.sh` decrypted the offerer's amount out of a proof context named in their JSON, printed it,
and then signed `transaction.half_signed_base64` — **a different object, never compared to the thing
just checked.** An offerer could show a genuine, correctly proved context for the display and hand
over any message they liked for the signature.

> "it fails at the missing binding between the human-visible checked context and the opaque message
> being signed"

Token-2022 does bind a proof to the accounts, but by **ElGamal key, not by address**, and it binds
nothing to the transaction. And `swap-check` never established that the context it decrypted was one
the transaction cites at all. So the display was theatre.

**Fixed** by `swap-tx verify`: rebuild the expected message from what the signer already trusts —
their own leg, which they built, and the context they just decrypted — and compare the serialised
message **byte for byte** before signing. Anything else refuses and exits 1.

The fix then immediately caught a bug of mine that no test had: the offerer's leg destination was
wired to `$A_GIVE_ACC` where it should have been `$A_WANT_ACC`. The check found it on its first run,
against the honest path.

## Arbitrary code execution from a counterparty's file

    python3 -c "print($send * 10**$dec_n)"

`send` comes from the counterparty's `units` field. **Demonstrated, not theorised** — a crafted offer
printed `INJECTED uid=502` on my machine before anything was signed.

**Fixed** at the boundary: every field arriving from a counterparty is shape-checked before use —
amounts are decimal integers, addresses are base58 of the right length, ElGamal keys are base64 — and
no value is ever interpolated into source again.

## The abandoned acceptor

Whoever accepts pays first: they put their proofs on chain **before either signature exists**, because
the other side has to read the amount before agreeing to it. Two consequences, both real:

- The rent was stranded. Measured on devnet, one leg is contexts of 161, 297 and 385 bytes —
  **0.008539 SOL**. Nobody profits from it, so it is a nuisance rather than a theft.
- Worse: the context keypairs lived at a fixed `$W/<who>-keys`, and `seizure-ctx` **loads** existing
  keys rather than generating. A second attempt therefore addressed the same context accounts, found
  them already on chain, and failed the create. **An abandoned swap could not be retried** — the
  worst moment for that to be true.

**Fixed** both ways. The key directory is now per attempt, and recorded in `ctx.json` along with the
address lookup table, because that file was the only possible record of either. `swap-abandon.sh`
closes the contexts and returns the rent: run against a real stranded leg it recovered
**0.008535 SOL**, which is the measured rent less the 0.000005 fee for the closing transaction, and
the three accounts then read back `gone`.

The lookup table is not closed — that needs a deactivate and about 500 slots of cooling off — so the
script prints the command instead of pretending to have finished.

## The auditor was silently dropped

The old single-file wrapper linked each mint's auditor into `auditor-$who.json`; the new bilateral
scripts never did, so **a bilateral swap on a mint that names an auditor would have sent `none`** and
been refused by Token-2022.

**Fixed** by reading it from the mint over RPC instead of from a file. Verified on the stock-for-stock
path, where the two mints name *different* auditors: both legs now carry a non-empty auditor, the two
differ, and Token-2022 accepted the transaction — which is the only proof that the key read was right.

## The ElGamal secret

Re-running `testbed-join.sh` on an already-configured account **wrote a fresh ElGamal secret before**
the on-chain `ConfigureAccount` failed, making the existing confidential balance permanently
unreadable. The file was also `0644` under a normal umask, and unnamespaced by cluster.

**Fixed**: `provision configure` refuses outright if the keys file exists, and sets `0600` after
writing; the directory is now cluster-scoped and `0700`.

## Where Codex corrected me rather than the code

- I had implied an indefinite replay window. It is roughly **60–90 seconds**, 151 blocks — the signed
  transaction is replay-protected and expires. The blind-signing attack was the real problem, and it
  did not need a long window.
- "The proof describes this source and destination" was imprecise: a proof context holds **ElGamal
  public keys**, not token-account addresses or a mint. Key-bound, not address-bound.
- `spl-token-2022-interface` is a client builder, not the verifier. The binding I was crediting to it
  lives in the **processor**.

## What I did not change

`partial_sign` still signs whatever blockhash is embedded; it does not validate one. With the
rebuild-and-compare in place the signer is no longer choosing between opaque messages, and
`swap-sign.sh` additionally asks `isBlockhashValid` about the hash `verify` reports. A durable-nonce
message would now fail the comparison, because the expected message is rebuilt with a recent hash.
