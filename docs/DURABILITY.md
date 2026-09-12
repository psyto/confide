# Durability

Submissions close 18 September; judging runs to **2 October**. Everything this project puts on
devnet can be gone before a judge opens it — this repo has already been bitten once, when a payer
address inherited from another harness simply stopped existing and the faucet refused to replace it.

**`./scripts/healthcheck.sh` checks every live claim and exits non-zero on the first thing that has
died.** Run it before pointing anyone at a link.

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
./scripts/provision-account.sh 173000            # writes account-keys.json
./scripts/set-auditor.sh <the new mint>

# the proofs the page serves
./scripts/prove-collateral.sh <new account> 100000 account-keys.json
#   -> regenerate web/proofs.json with the new txs AND the new available_balance,
#      then push to the gh-pages branch

./scripts/healthcheck.sh                 # back to all clear
```

Deploying the program costs ~1.5 SOL of devnet rent; the airdrop faucet refuses small accounts, so
keep the funded keypair (`~/.config/solana/id.json`, 130+ SOL at time of writing) rather than
expecting to top up on demand.

## The recorded evidence

Devnet can take the accounts; it cannot take the transcript. These were observed and are cited
throughout `docs/ONCHAIN.md`:

| what | value |
|---|---|
| receipts program | `6a1Kd8Yo5U9wMXUtMnU1PZF8xy6wJ6zWyMr7uKNAHytv` |
| confidential account | `6Wn7zAaV56yGaAduNvTxsjEiVS1UDxi9whUMje9mG16V` |
| mint with the auditor slot filled | `EbfBr1ZcVQFy7JN68fDoFw6NUyonBGYXEXPRKUrv7trH` |
| auditor key set on it | `ut5cP19Fy+AHW+nVkj0BfUANqd3w+722Mi30dj0eBC8=` |
| receipt anchored | slot 497,199,572, 147 bytes, commitment matched on read-back |
| equality proof | accepted, 6,400 CU, `VerifyCiphertextCommitmentEquality` |
| range proof | accepted, 111,000 CU, `VerifyBatchedRangeProofU64` |

The 83-second video in [`video/`](../video) records the same runs, and `video/record.js` refuses to
record when a command stops producing the line that carries its claim — so a video that exists is a
video whose claims were true when it was made.
