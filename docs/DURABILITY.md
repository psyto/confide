# Durability

**Submitted 15 September. Judging runs to 2 October**, which is the part that matters here:
everything this project puts on devnet can be gone before a judge opens it, and there is no second
chance to notice. This repo has already been bitten once, when a payer address inherited from
another harness simply stopped existing and the faucet refused to replace it.

**`./scripts/healthcheck.sh` checks every live claim and exits with the number that died.** Run it
weekly through the judging window, and before pointing anyone at a link. Eight checks: the mainnet
finding, the receipts program, the confidential account, the mirror's auditor slot, the mirror's
account gate, the anchored disclosure, the keys quoted in `docs/ONCHAIN.md`, and the four published
links including the walkthrough.

Two of those exist because prose went stale while the chain moved: the mirror's
`autoApproveNewAccounts` was flipped back to `true` by `set-auditor.sh` without anyone noticing, and
`ONCHAIN.md` kept quoting ElGamal keys from an account that had been replaced. A sentence cannot
fail; an exit code can.

## What survives a reset, and what does not

| | |
|---|---|
| **The core finding** — every xStock has confidential transfers on and the auditor slot empty | **Mainnet. Does not reset.** This is the argument, and it is the durable half |
| Recent wallets and their positions on the live page | **Mainnet.** Read fresh each visit |
| `aperture-receipts` program | devnet — gone on reset |
| The confidential account (public balance 0, position 173,000) | devnet — gone on reset |
| The mirrored mint with its auditor slot filled | devnet — gone on reset |
| The two collateral proofs | **neither.** See below |

## The proofs are the trap

The proofs in `web/proofs.json` are **self-contained**: the ZK ElGamal Proof Program verifies them
without reading the account. So after a reset that wipes the account, **they still come back
`err: null`** — and a page that reported that as "the account holds at least X" would be showing a
green that means nothing.

So `proofs.json` pins the `available_balance` the proofs were generated over, and the page compares
it against the live account before treating a pass as meaningful. When they diverge it says so, in
the panel and again under the proof results, instead of letting the green speak.

That failure path is tested by pointing the page at a deliberately-wrong `available_balance` and
confirming both warnings appear — not by assuming.

## Recovery, in order

```bash
./scripts/healthcheck.sh                 # what actually died

# the program
cd ../aperture/programs/aperture-receipts && cargo build-sbf
solana program deploy target/deploy/aperture_receipts.so -u devnet
#   -> put the new program id in crates/confide-onchain/src/anchor.rs and scripts/healthcheck.sh

# the account, the mint, the auditor slot
./scripts/provision-account.sh 173000            # writes account-keys.json; the mint gates
                                                 # accounts like NVDAx, so this approves its own
./scripts/set-auditor.sh <the new mint>

# the proofs the page serves
./scripts/refresh-proofs.sh <new account> 100000 account-keys.json
#   -> rewrites web/proofs.json with the new txs AND the new available_balance, and refuses to
#      write it at all if either proof is rejected. Push web/ to the gh-pages branch after.

# the anchored disclosure, over the new account's own ciphertext
./scripts/anchor-receipt.sh
#   -> put the new receipt PDA and commitment in scripts/healthcheck.sh

# then the references: the account and mint appear in scripts/healthcheck.sh,
# scripts/bind-account.sh, web/proofs.json, README.md, _submission/full.md and this file.

./scripts/healthcheck.sh                 # back to all clear
```

Deploying the program costs ~1.5 SOL of devnet rent; the airdrop faucet refuses small accounts, so
keep the funded keypair (`~/.config/solana/id.json`) rather than expecting to top up on demand.

**It held 134.38 SOL when checked on 2026-09-15**, which is several redeployments of headroom. An
earlier version of this file said 0.62 SOL and concluded that recovery was blocked at its first
step; that was wrong, and wrong in the direction that stops you trying. Check it rather than trust
either number:

```bash
solana balance -u devnet   # or: getBalance on AmSYugrtHAEZi3TDj3HP7qbjY1hw6uv1df1oFDMxKeb1
```

## The recorded evidence

Devnet can take the accounts; it cannot take the transcript. These were observed and are cited
throughout `docs/ONCHAIN.md`:

| what | value |
|---|---|
| receipts program | `6a1Kd8Yo5U9wMXUtMnU1PZF8xy6wJ6zWyMr7uKNAHytv` |
| confidential account | `Cgv2eDNUUrgRVhkZ8mBE5UkQmkqLh3Aj3poLiqBBrX1P` |
| mint with the auditor slot filled | `5jszdY3yd8fq37DBEqECtBQdvwnyXtA9vexJFefVKWzb` |
| auditor key set on it | `ut5cP19Fy+AHW+nVkj0BfUANqd3w+722Mi30dj0eBC8=` |
| receipt anchored | slot 497,199,572, 147 bytes, commitment matched on read-back |
| equality proof | accepted, 6,400 CU, `VerifyCiphertextCommitmentEquality` |
| range proof | accepted, 111,000 CU, `VerifyBatchedRangeProofU64` |

The walkthrough (https://youtu.be/KQsRwP8HTs0) records the same runs, and `video/record.js` refuses to
record when a command stops producing the line that carries its claim — so a video that exists is a
video whose claims were true when it was made.
