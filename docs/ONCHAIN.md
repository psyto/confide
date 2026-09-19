# What the chain says today

**Read on 2026-09-12 from `api.mainnet-beta.solana.com`. Reproduce with
[`scripts/onchain-check.sh`](../scripts/onchain-check.sh)** — no key, no account, no API token.

## 1. xStocks are Token-2022, and confidential transfers are already switched on

**Every tokenized-equity mint on Solana carries the extension with `auditorElgamalPubkey` null —
all 1,992 of them, across three issuers that have nothing to do with each other:**

*Scope, because the number invites a bigger reading than it earns:* `scripts/refresh-mints.sh`
builds the mint list from **Backed's and Backpack's own asset APIs**. The scan is exhaustive over
what those three issuers publish and checked rather than sampled. It is not a census of every equity
token on Solana, and a third issuer would not appear in it.


```
Backed     EMPTY   732      xStocks — Swiss-issued, own ISIN, a third-party product
Backpack   EMPTY   1137     US CUSIP, "a bona fide security entitlement" by the issuer's own words
```

One issuer leaving the slot empty is a quirk. **Two, independently, is the shape of the problem** —
and Backpack's are the closer thing to the underlying security, so it is not that the weaker
instrument cut a corner. `./scripts/slot-scan.sh` checks all of them and exits non-zero the day that
stops being true. Four in detail:

```
SYMBOL  MINT                                          PROGRAM      confidentialTransferMint.auditorElgamalPubkey
NVDAx   Xsc9qvGR1efVDFGLrVsmkzv3qi45LTBjeUKSPmx9qEh   Token-2022   None
TSLAx   XsDoVfqeBukxuZHWhdvWHBhgEHjGNst4MLodqsJHzoB   Token-2022   None
SPYx    XsoCS1TfEyfFhfvj8EtZ528L3CaKBDBRqRapnBbDF2W   Token-2022   None
AAPLx   XsbEhLAtcf6HdfpFZ5xEMdqW8nfAvcsP5bdudRLJzJp   Token-2022   None
```

NVDAx in full — a heavily compliance-configured institutional mint:

```
owner program : TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb   (Token-2022)
decimals      : 8
supply        : 32127998734914
extensions    : metadataPointer, permanentDelegate, defaultAccountState,
                scaledUiAmountConfig, pausableConfig, confidentialTransferMint,
                transferHook, tokenMetadata

confidentialTransferMint:
  authority             5aMNNLQJwAEeoemTEMkv5NVjqKwvvefRYCQ5Z67HFvEq
  autoApproveNewAccounts false
  auditorElgamalPubkey  null        <-- the empty slot this project is about
```

## 2. The substrate is live again

Confidential transfers were disabled on 2025-06-11 after the ZK ElGamal Proof program bug. The
feature gate re-enabling that program **activated at the start of epoch 982, early June 2026**, and
Token-2022 was redeployed with the confidential instructions about two weeks later. It is enabled
on mainnet and devnet today — and **usage is close to zero**.

## 3. Confide's own proof, accepted by the live program

A quarterly reporting obligation has two halves. The position is disclosed at `T`; but the
covenants around it — *"the fund is at or above X"* — must be answerable **before** the position
itself is disclosable. That half is a predicate, and it verifies on-chain.

```
$ ./scripts/devnet-verify.sh
payer : FDQHfbqgSUk94XKFKWu6E8qidL7bwGEXDPzAoTVTXEDm  (a live devnet validator identity)
err   : None
units : 111000
logs  :
    Program ZkE1Gama1Proof11111111111111111111111111111 invoke [1]
    VerifyBatchedRangeProofU64
    Program ZkE1Gama1Proof11111111111111111111111111111 success
```

`err: None` with a `VerifyBatchedRangeProofU64 → success` log is the reactivated ZK ElGamal Proof
Program accepting the proof. **Which proof matters**: these bytes are read back out of the
`ProofEnvelope` inside the disclosure package that `confide-equity::nav_floor_disclosure`
produced — the same package the embargo seals. Not a lookalike generated for the occasion.

No signature, no fee, no funded account: `simulateTransaction` with `sigVerify=false` and
`replaceRecentBlockhash=true`. The fee payer only has to exist, so the script asks the cluster for
a validator identity rather than hardcoding an address devnet will reset away.

The LP learns one bit — the covenant holds. It learns no position, no portfolio value, no
composition.

## 4. The commitment really is on-chain, at t0

`aperture-receipts` — the content-blind Receipt Registry from `psyto/aperture` — is deployed to
devnet at **`6a1Kd8Yo5U9wMXUtMnU1PZF8xy6wJ6zWyMr7uKNAHytv`**. `scripts/anchor-receipt.sh` seals an
obligation, anchors its commitment, and then reads the account back off the chain to check the
stored bytes against the sealed artifact:

```
$ ./scripts/anchor-receipt.sh
  commitment  b6651e3d4ca8b5f4877bacd964646946c40a198590d6d49e2ed681b32d7e4103
  receipt PDA 75AjRKc2TV1BCTP79rmCUcz2VunxJgmxBZAUk7zEGduS
  signature   6tGDZ6P5g3CeVM7uZMdAVN48qAqZAyS3SKNWKkDk6B2mvPYuoBp9kFyGMad56HpzBgSo7qne8pY18TG2uyoqVQA
  confirming  confirmed

  --- now read it back off the chain, and check it against the sealed artifact ---
  stored commitment  b6651e3d4ca8b5f4877bacd964646946c40a198590d6d49e2ed681b32d7e4103
  matches the sealed artifact: YES
  anchored at slot   497199572
  opens at           1794614400  (2026-11-14)
  bytes on chain     147  — a hash and two dates. No position, no portfolio.
```

147 bytes is the whole footprint of a fund's quarterly disclosure obligation: a hash, the date it
was made, and the date it comes due. The chain learns that Fund A committed to something and when
it opens. It does not learn what.

One honest note on the layout: the registry's last field is named `expiry` and Confide writes
`open_at` into it. The registry is content-blind and never interprets the value, so nothing is
wrong on-chain — but a registry designed for obligations rather than grants would name that field
for what it is.

Requires a devnet-funded keypair (`~/.config/solana/id.json` by default); the other two scripts
need nothing at all.

## 5. A position that is held, on-chain, and invisible

The mints above cannot be used for this — `autoApproveNewAccounts: false` means Backed decides who
may open a confidential account on NVDAx, and it has not decided in our favour. So this repo
provisioned a Token-2022 mint on devnet with the same extension and ran the real flow through
`spl-token`: `create-token --enable-confidential-transfers`, `configure-confidential-transfer-account`,
`mint`, `deposit-confidential-tokens`, `apply-pending-balance`.

The result is an account anyone can read:

```
account            A1AMyEf1FQYmvdEWSejtHHU6ZKuBh74MRM9LzGfMGWT6
mint               4MfE9MTHMHVFFosc6y1XXoQ8iBiAW5jmFtgspMd5W5UG
public balance     0                    <- the chain says the wallet holds nothing
elgamal pubkey     32 bytes             <- the account's own key
available balance  64 bytes ciphertext  <- 173,000 units, and nobody can read it
```

`spl-token balance` returns `0`. The holder has 173,000. Both are true, and both are public.

**This account is superseded, and worth keeping in the record.** It proved the asymmetry is real,
and it is the one that showed why a CLI-made account is not enough: `spl-token` derives its ElGamal
key with a KDF this SDK version does not reproduce, so we can read this account on the chain and
cannot prove anything about it. The account the demo, the proofs and the live page are about is
`Cgv2eDNUUrgRVhkZ8mBE5UkQmkqLh3Aj3poLiqBBrX1P` — provisioned from our own instructions in §7.

`./scripts/bind-account.sh` builds a disclosure subject out of those real fields and then re-reads
the account to confirm the binding still matches. Before this, `SubjectAccount` carried an address
string nobody checked and an **empty** ElGamal pubkey — `aperture`'s skeleton — so nothing tied a
sealed position to a wallet a counterparty could go and look at.

**What is still open, precisely.** The range proof is generated over a ciphertext of our own, not
over the account's `availableBalance`. Closing that needs the account's ElGamal *secret*, and
`spl-token` derives it with a KDF this SDK version does not reproduce — eight combinations of
derivation and seed were tried against the on-chain pubkey and none matched. The binding is real and
checkable; the proof is not yet over the bound ciphertext. That is the next correctness step, and it
means provisioning the account from our own code rather than from the CLI.

## 6. The slot, filled

Backed's mints are not ours to configure, so this repo provisioned one with the same extension and
filled the slot `ConfidentialTransferInstruction::UpdateMint` exists for:

```
mint                    5jszdY3yd8fq37DBEqECtBQdvwnyXtA9vexJFefVKWzb
auditorElgamalPubkey    nF3pvomToJfTyKL5fZkf0UsP5bF3iOOHy1JTKU/AFXE=
autoApproveNewAccounts  false                    <- as NVDAx has it
account                 Cgv2eDNUUrgRVhkZ8mBE5UkQmkqLh3Aj3poLiqBBrX1P
public amount           0
```

`./scripts/set-auditor.sh <mint>` does it and reads the mint back. Field by field this mint and
NVDAx differ in the auditor key and the mint authority, and in nothing else.

`update_mint` rewrites `auto_approve_new_accounts` as well as the auditor key, and this script
passed `true` until 2026-09-15 — quietly undoing the `manual` the mint was created with and leaving
a mirror that differed from NVDAx in two fields while the copy claimed one. `healthcheck.sh` now
checks that field rather than trusting this paragraph.

And that one field is the whole argument. Filling it is a single instruction — the difficulty was
never the mechanics. The difficulty is that this key, once set, reads **every holder's every
transfer, forever**, and cannot be scoped, delegated for a quarter, or pointed at one counterparty.
That is why the live mints leave it null, and why filling it is only useful if something above it
decides who sees what and when.

## 7. An account whose key is ours

`spl-token` derives an account's ElGamal key from a wallet signature using a KDF this SDK version
does not reproduce — eight derivation/seed combinations were tried against a CLI-provisioned
account and none matched. So an account the CLI configures is one we can *read on the chain* and
cannot *prove anything about*. `./scripts/provision-account.sh` stands one up from our own
instructions instead: `Reallocate`, `ConfigureAccount` carrying a `PubkeyValidityProof` we generate,
`ApproveAccount`, `Deposit`, `ApplyPendingBalance`.

`ApproveAccount` is there because the mint gates accounts the way the real ones do. Backed and
Backpack both ship `autoApproveNewAccounts: false`, so a holder cannot open a confidential account
without the issuer signing for it. Mirroring that with `auto` would have made provisioning simpler
and the comparison false. Here the mint authority is us, so the approval is a transaction; on a
live mint it is a conversation with the issuer, and it is the one step in this repository that
cannot be done without them.

```
account                    Cgv2eDNUUrgRVhkZ8mBE5UkQmkqLh3Aj3poLiqBBrX1P
public balance             0                  <- what the chain shows anyone
elgamalPubkey              6v2J2Au46e16utqZB4Tt4QttMurm2uemWbbSjrQ0334=   <- ours
approved                   true               <- the issuer signed for it
availableBalance           64 bytes of ElGamal ciphertext
decryptableAvailableBalance  opens to 17,300,000,000,000 base units = 173,000
```

`./scripts/read-balance.sh` opens it. The public balance is zero to everyone, including us; the
confidential balance is 173,000 to us and to nobody else.

Two things that cost an attempt each, recorded so the next person skips them. `ConfigureAccount`
fails with `InvalidAccountData` on an account created by `create-account`, because the extension
needs space the account does not have — a `Reallocate` has to come first. And `UpdateMint` fails
with `OwnerMismatch` unless the signer is the mint's confidential-transfer authority, which is
whatever keypair the CLI was configured with at creation time, not necessarily the one you think.

## 8. A proof about that account, checked by Solana

An account's ElGamal ciphertext has no Pedersen opening we hold, so it cannot be range-proved
directly. Two proofs do what one cannot:

1. **ciphertext-commitment equality** — the account's ciphertext and a commitment `C` whose opening
   we *do* hold encrypt the same value.
2. **batched range u64** — `C − threshold·G` commits a non-negative value.

A verifier recomputes `C − threshold·G` and checks the range proof is over it. Together they say
*this account holds at least the threshold*; separately, neither is about anything.

```
$ ./scripts/prove-collateral.sh Cgv2eDNUUrgRVhkZ8mBE5UkQmkqLh3Aj3poLiqBBrX1P 100000

  ciphertext-commitment equality — the commitment and the account hold the same value
    err   : None
    units : 6400
    VerifyCiphertextCommitmentEquality
    Program ZkE1Gama1Proof11111111111111111111111111111 success

  batched range u64 — the surplus over the threshold is non-negative
    err   : None
    units : 111000
    VerifyBatchedRangeProofU64
    Program ZkE1Gama1Proof11111111111111111111111111111 success
```

Below the threshold it refuses rather than proving a false statement, and refuses without printing
the balance — a tool that reveals your position in its error messages is a habit worth not forming.

**What this is now.** A lender can be shown that the account securing a loan clears its requirement,
on-chain, without the borrower publishing what the account holds — and can **take** it on default,
which `./scripts/seizure-e2e.sh` does on devnet and `docs/SEIZURE.md` explains. **What it is still
not:** a loan. Origination, interest, a liquidation engine and an oracle are all somebody else's,
and Confide seizes on a default it does not itself define.

## 8. What these facts say together

The issuer turned confidential transfers **on** for tokenized equities, gated new confidential
accounts behind its own approval (`autoApproveNewAccounts: false`) — and left the auditor slot
**empty**.

That is not an oversight. It is the only available choice. Token-2022's disclosure model is a single
global auditor key: **one key that decrypts everything, forever.** For a regulated equity issuer
there is no setting of that key that is correct. Fill it and every holder's position is permanently
readable by one party. Leave it null and no holder can demonstrate anything to anyone — so no
regulated holder can use the feature at all.

So the feature is shipped, configured, and unused. Not because it is immature; because the only
disclosure it offers is all-or-nothing.

**Confide is what makes that slot usable**: disclosure scoped by recipient, by granularity, and — the
part nothing else has — **by schedule**. The auditor reads now. The public reads at `T`. The holder
cannot move either date.
