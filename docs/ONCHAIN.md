# What the chain says today

**Read on 2026-09-12 from `api.mainnet-beta.solana.com`. Reproduce with
[`scripts/onchain-check.sh`](../scripts/onchain-check.sh)** — no key, no account, no API token.

## 1. xStocks are Token-2022, and confidential transfers are already switched on

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

## 3. Mora's own proof, accepted by the live program

The 13F obligation has two halves. The position is disclosed at `T`; but *whether a filing is owed
at all* — discretionary holdings at or above **$100M** — is a question that must be answerable
**before** the position is disclosable. That half is a predicate, and it verifies on-chain.

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
`ProofEnvelope` inside the disclosure package that `mora-equity::filing_threshold_disclosure`
produced — the same package the embargo seals. Not a lookalike generated for the occasion.

No signature, no fee, no funded account: `simulateTransaction` with `sigVerify=false` and
`replaceRecentBlockhash=true`. The fee payer only has to exist, so the script asks the cluster for
a validator identity rather than hardcoding an address devnet will reset away.

The regulator learns one bit — a filing is owed. It learns no position, no portfolio value, no
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

One honest note on the layout: the registry's last field is named `expiry` and Mora writes
`open_at` into it. The registry is content-blind and never interprets the value, so nothing is
wrong on-chain — but a registry designed for obligations rather than grants would name that field
for what it is.

Requires a devnet-funded keypair (`~/.config/solana/id.json` by default); the other two scripts
need nothing at all.

## 5. What these facts say together

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

**Mora is what makes that slot usable**: disclosure scoped by recipient, by granularity, and — the
part nothing else has — **by schedule**. The auditor reads now. The public reads at `T`. The holder
cannot move either date.
