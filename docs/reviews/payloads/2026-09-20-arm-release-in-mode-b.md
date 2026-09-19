# Does mode B break `arm_release`'s security assumption?

You are reviewing a Solana program in this repository, `programs/confide-seizure/src/lib.rs`.
Read the real files. Do not infer line contents from this document — it may be wrong, and this
repository has twice accepted a Codex finding that turned out to cite the wrong lines, and twice
shipped a claim of its own that the source did not support.

## What the program is for

A bilateral loan against a Token-2022 **confidential** position. The collateral sits in an escrow
token account whose owner is a PDA of this program (`["loan", escrow]`). The program is the only
party that can sign for that escrow. It has exactly two exits:

- **seizure** — `seize` (discriminant 1), gated by `may_seize` → `may_settle`: a recorded oracle
  key must sign, and `in_default(q_min, price, principal, ratio_bps)` must hold.
- **release** — `arm_release` (3) records a return route, then `release` (4), gated by
  `may_release`: the recorded release authority must sign, and the destination and the three proof
  context accounts cited must equal the ones that were armed.

**No principal ever moves through the program.** `principal` is only an input to `in_default`.

## The two modes

- **Mode A** (`originate`, discriminant 0, `FLOOR_PROVED`): the **borrower** holds the escrow's
  ElGamal secret. The floor is proved on chain by Solana's ZK ElGamal Proof Program.
- **Mode B** (`originate_attested`, discriminant 6, `FLOOR_ATTESTED`): added 2026-09-19 so that a
  holder whose position is in an **associated** token account can pledge — an ATA carries
  `ImmutableOwner` and can never be handed over, so instead the **lender** opens the escrow, has
  the issuer approve it, and hands *it* to the loan PDA while it is empty. The holder then moves
  the position in with `spl-token transfer --confidential`. Consequence: **in mode B the LENDER
  holds the escrow's ElGamal secret**, and the floor is the lender's assertion rather than a proof.
  `scripts/seizure-e2e.sh`, `MODE=ata`, runs this end to end on devnet.

## The thing to judge

`arm_release` requires only `payer.is_signer` — **any** signer. It does not check the caller
against anything recorded in the loan, and it **overwrites** an already-armed route. Its own doc
comment says both that this is deliberate:

> *The borrower calls it, because they hold the escrow's ElGamal secret and so they are the only
> party who can build a transfer out of it. They may call it again while the loan is open; a
> release citing a route that no longer matches the record fails rather than redirecting.*

and, in the `msg!` it emits, something that reads as a guarantee to the borrower:

> *release armed; the lender still has to sign, and can no longer redirect it*

The claim I want tested is this:

> **`arm_release`'s safety rests on "only the borrower can build a transfer out of the escrow",
> which is true in mode A and false in mode B.** In mode B the lender holds the escrow's ElGamal
> secret and is also, in the demo, the recorded release authority. So the lender can call
> `arm_release` with a destination and context accounts of their own, then call `release` and
> signing as the release authority, and take the collateral **without any default, without the
> oracle, and without the holder's cooperation** — defeating the point of the escrow.

## What I want from you

1. **Is the claim true?** Trace it in the real source. In particular satisfy yourself about whether
   a party who does NOT hold the escrow's ElGamal secret can produce the three proof contexts that
   `release` → Token-2022 will accept (my belief: no, because the equality proof and the range
   proof over the remaining balance need the source's secret — but I have not proved this and it is
   the whole of mode A's defence).
2. **Is mode A actually safe, or only accidentally so?** If its only defence is the proof
   requirement rather than a check, say so plainly.
3. **Is there anything else in mode B that I have not noticed?** In the demo (`seizure-e2e.sh:143`
   and the `MODE=ata` branch) the **same lender key** is the oracle AND the release authority, so
   the lender can already declare a default against themselves. I consider that a demo
   simplification rather than a program defect — tell me if that is wrong.
4. **Argue the other side.** The doc comment says re-arming is intentional. Is there a legitimate
   reason a route would need re-arming while the loan is open, given that the escrow's balance
   cannot change (PDA-owned, and `may_apply` refuses `apply_pending` once a loan record exists)?
   If re-arming is load-bearing, single-shot arming is the wrong fix.
5. **What is the smallest correct fix**, if one is needed? My candidate is single-shot arming —
   refuse when `OFF_RELEASE_DESTINATION` is already non-zero — which would make the `msg!` true.
   An alternative is recording the pledging holder at origination and requiring their signature,
   but in mode B the holder never signs any instruction of this program and is not recorded
   anywhere, so there is no key to require. Say if you see a third option.
6. **Is anything else I have claimed here wrong?** Including the framing of mode B itself.

Relevant offsets and constants are at the top of `lib.rs`. The record is 741 bytes (v3); v1 is 415
and v2 is 740, and old records must stay readable — `may_settle` deliberately tests `LOAN_LEN_V1`
because a 415-byte loan from a published demo video is still on devnet.

Answer with findings, each one either CONFIRMED with the file and line you read, or refuted.
