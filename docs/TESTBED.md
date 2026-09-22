# The standing testbed — devnet, and you need nothing from us

```
equity   7MEQEiy11TY4j8wMsFkbgTkvSeAmVQeePU46M9qhZJ7z   8 decimals, shaped like NVDAx
cash     AkwGFZj16C9RR1WFCwBQhUaMmzjkbrBsLkfMGxHSVDhS   6 decimals, shaped like PYUSD
issuer   approval authority 78cT71Ph1Hy9zPPj6LusUfa5LQDexd1AAXpXS4DHvEU2   secret published, see below
```

Stand where a holder stands: `./scripts/testbed-join.sh`. Two minutes, no permission, no account
with anybody.

## What this is, and what it is not

**It is not traction.** Standing this up is not usage. Usage is somebody else opening an account on
it, and that is counted separately and is currently zero.

**It is not a security, and no license is implicated.** These are devnet tokens representing
nothing. Nothing here makes a real xStock pledgeable, and the `$0` reachable confidentially across
Kamino's `$86.2m` of authorised borrowing is unchanged.

**What it is:** the demonstration that **the issuer gate is an operations decision rather than a
protocol problem.** [`cwf-2026/STORY.md`](cwf-2026/STORY.md) §3 lists that as the first of the
named conditions standing between what runs and a market. This runs it.

The mints keep `autoApproveNewAccounts: false` — exactly what **all 1,992** live tokenized-equity
mints do, and exactly what PYUSD and USDG do — and both leave the auditor slot **empty**, which is
also what all of them do. Nothing is made easy by making it unlike the real thing. The only
difference is that this issuer **operates** the gate instead of leaving it shut.

## How it operates the gate with no server and no key custody

`ApproveAccount` is signed by the **confidential-transfer mint authority**, which Token-2022 keeps
separate from the authority that mints. So the two roles split cleanly:

| | key | published? | can do |
|---|---|---|---|
| mint authority | `keys/issuer-mint-authority.json` | **no** | create supply |
| approval authority | `keys/devnet-approval-authority.json` | **yes, on purpose** | let accounts through the gate |

**The published key cannot mint**, and that is checked rather than asserted — minting with it fails
with `Error: owner does not match` (`TokenError::OwnerMismatch`).

A faucet account's owner key is published too (`keys/devnet-faucet.json`), so a balance needs no
introduction either.

### What the published key *can* do, said plainly

It can also `UpdateMint`, which means it can open the gate or fill the auditor slot. Doing either
breaks the demonstration, and `./scripts/testbed-up.sh --check` watches for both — as does
`healthcheck.sh`. On devnet that is vandalism rather than loss: the fix is a new approval key and a
new line in this file.

## Doing a trade

One person can open an account. A **trade needs two**, which is the honest shape of the thing —
this is a bilateral settlement primitive and it cannot pretend otherwise.

```
MODE=dvp ./scripts/swap-e2e.sh
```

runs both sides against throwaway mints and is the fastest way to see the whole thing — but it
holds both parties' keys, which no real trade does.

**To trade against another person, four commands and four files.** Each of you runs
`testbed-join.sh` on BOTH mints first, so you have an account and an ElGamal key on each.

```
you                                                   them
──────────────────────────────────────────────────────────────────────────────────────
swap-offer.sh  you.json --give <mint> N
               --want <mint> M        > offer.json  ──▶
                                                        swap-accept.sh them.json
                                            ◀──────     offer.json > accept.json
swap-settle.sh you.json accept.json
               > settle.json                         ──▶
                                                        swap-sign.sh them.json
                                                        settle.json
```

**Why four and not two.** Each side needs the other's ElGamal public key before it can build its
own proofs, and **each side decrypts the other's amount before signing** — that is what
`swap-check` is for, and it runs inside steps 3 and 4. Cutting a round trip would mean one party
signing before they can see what the other is actually sending.

**Nothing moves until the fourth command.** A proof is not a transfer, and a transaction with one
of two signatures cannot execute. Settled end to end on devnet 2026-09-22 between two keypairs
that never shared anything but public keys: 100 equity against 17,500 cash, one transaction, 1,074
bytes, all four public balances still `0`.

**If you do this, say so.** An account on these mints that this repository did not open is the
first outside use of any of it.

## Keeping it alive

Devnet resets and the faucet can be drained. `./scripts/testbed-up.sh --check` says whether the
mints are still as published; `./scripts/testbed-up.sh` refuses to stand up a second one, because
a second testbed orphans the first and the addresses in this file are the whole point.
