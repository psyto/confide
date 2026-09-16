# Confide

### → [**Try it live**](https://psyto.github.io/confide/) · [**Watch**](https://youtu.be/p1aQuEnzhQk) · no wallet, no API key, no install

**1,869 tokenized stocks on Solana have confidential transfers switched on. Not one of them can be
used.** Two independent issuers, every mint they publish checked rather than sampled —
`./scripts/slot-scan.sh`:

```
checked  1869 tokenized-equity mints on Solana
  Backed     EMPTY   732      Swiss-issued, own ISIN (xStocks)
  Backpack   EMPTY   1137     US CUSIP, a security entitlement by the issuer's own description
```

*The list comes from both issuers' own asset APIs (`scripts/refresh-mints.sh`), so the scan is
exhaustive over what Backed and Backpack publish and is not an issuer census of Solana.*

One issuer would be a quirk. Two, arriving independently at the same dead end, is the shape of the
problem. Four of them mint by mint, with no key and no account: `./scripts/onchain-check.sh`, and
[docs/ONCHAIN.md](docs/ONCHAIN.md) for every reading behind it.

The feature is shipped, configured, and **inert**. Token-2022 offers exactly one disclosure model —
a single global auditor key that decrypts **everything, for everyone, forever** — and for a
regulated equity issuer no setting of that key is correct. Fill it and every holder is permanently
readable by one party. Leave it null and no holder can demonstrate anything to anyone. So it sits
empty, and the privacy nobody can use is why a fund holding NVDAx broadcasts its position to the
whole market instead.

**Confide is what makes that slot usable**: disclosure scoped by recipient, by granularity, and — the
part nothing else has — **by schedule**. The auditor reads now. The counterparty learns one bit. The
public reads at `T`, and the holder can move neither date.

```
day      LANE A · a public wallet       LANE B · Confide
         what anyone can see            what anyone can see   the auditor
────────────────────────────────────────────────────────────────────────────
  3        42,000 NVDAx · +42,000        —                   42,000 NVDAx
 11        96,000 NVDAx · +54,000        —                   96,000 NVDAx
 ...
 58       173,000 NVDAx · +7,000         —                  173,000 NVDAx

Lane A leaked the position continuously, from day 3, mid-accumulation.
Nobody attacked anything. The chain simply published it.
```

```
 1 Oct · the LP asks

auditor reads the position    173,000 NVDAx   44 days before the public can
is the fund above its floor?  YES   floor $100M — and that is all this reveals
(the portfolio is $106M across NVDAx/TSLAx/SPYx — the LP is not told that)

14 Nov · the obligation comes due

agents 1, 2, 3 publish their shares  · the fund is not asked, and cannot object
reconstructed  ✓   commitment matches slot 340112045  ✓

LANE B is now public: 173,000 NVDAx, held by Fund A as of 30 Sep.
```

And that predicate is not only checkable off-chain. The same proof bytes out of the same sealed
package go to Solana's live ZK ElGamal Proof Program:

```
$ ./scripts/devnet-verify.sh
err   : None
units : 111000
logs  :
    Program ZkE1Gama1Proof11111111111111111111111111111 invoke [1]
    VerifyBatchedRangeProofU64
    Program ZkE1Gama1Proof11111111111111111111111111111 success
```

## Who uses this first

**The issuer.** Backed and Backpack each switched confidential transfers on, gated who may open an
account, and left the auditor key null — companies that mean to enable this and have no disclosure
model to enable it *with*. Confide is that model, and nothing reaches a live mint without them.
**The issuer is the customer here, not the obstacle** — Kraken included, having acquired Backed in
December 2025.

**The fund holding the position.** A GP with NVDAx owes its LPs a quarterly report and broadcasts
the position continuously instead. Stopping that is what it pays for.

**The lender.** Jupiter Lend already takes SPYx, QQQx and NVDAx as collateral, and the position
securing the loan is public today. Both halves a lender needs now run on devnet — the check, and
the seizure.

**Traction is zero, and the sentence has no second half.** No issuer approval, no pilot, no customer
interview, no design partner, nobody outside this repository has used any of it. What exists is a
mechanism that runs and a finding you can check in one RPC call. Everything below is the second
kind of evidence, and none of it is the first.

## What a usable auditor slot is worth

Split by whether it runs, not by which repository it came from — a reader of this gets the whole
stack, and the reuse declaration below is for eligibility, not for discounting what works.

**Demonstrated here. Every line of this runs; the on-chain ones reach Solana.**

| | |
|---|---|
| **Hold a position on-chain that reads as zero.** A live devnet account: `spl-token balance` says `0`, the confidential balance holds 173,000. Both public, both true. | `./scripts/bind-account.sh` — [explorer](https://explorer.solana.com/address/Cgv2eDNUUrgRVhkZ8mBE5UkQmkqLh3Aj3poLiqBBrX1P?cluster=devnet) |
| **Bind a disclosure to that account**, not to a string — its own ElGamal key and its own ciphertext, re-read from chain to confirm. | `./scripts/bind-account.sh` |
| **Fill the auditor slot.** The mirror gates new accounts exactly as NVDAx does — `autoApproveNewAccounts: false` — so the issuer has to sign for the confidential account before it can hold anything, and the demo does that rather than describing it. One field then separates the two mints, and the reason that field stays null everywhere else is that the key it holds cannot be scoped. | `./scripts/set-auditor.sh` — devnet |
| **Let only chosen parties read it.** The auditor reads throughout; the market never does. | `cargo test` — I4 |
| **Prove "this account holds at least X" — over the account's own on-chain ciphertext.** The counterparty learns one bit: not the value, not the composition, not any holding. Two proofs, because one does not exist: equality binds a commitment we can open to the account's ciphertext, then the range proof runs on the surplus. | `./scripts/prove-collateral.sh` — both accepted by Solana's live ZK ElGamal Proof Program |
| **Bind a disclosure to a date and make it unrevisable.** The commitment is over the account's own on-chain ciphertext, so the 45 days are not merely a promise: a figure restated afterwards does not open it. | `./scripts/anchor-receipt.sh` — 147 bytes on devnet |
| **Open on schedule without the holder.** Five separate processes; the holder exited in September. What they publish is checked against the commitment sealed that day before it is read out. | `./scripts/committee.sh` |
| **Take that collateral on default.** A transfer the borrower authorises at origination and cannot later refuse: the proofs are parked on chain under an authority they cannot close, and fired by a program that owns the escrow. No key is reconstructed, no committee is asked, and neither account ever shows what moved. **The floor and the price are the loan's to establish, not the chain's** — [SEIZURE.md §4](docs/SEIZURE.md). | `./scripts/seizure-e2e.sh` — on devnet; `./scripts/seizure-status.sh` reads it back |
| **Survive a stock split.** A number sealed in September is quoted in September's units. Eleven actions are queued on the live schedule: eight restate exactly, three have no whole ratio and are reported, not guessed. | `cargo test -p confide-equity` |

**The same primitive, pointed elsewhere. Not built here, and not claimed as working.**

- **Borrowing against stock without publishing the collateral.** Jupiter Lend already takes SPYx,
  QQQx, NVDAx as collateral, and today the position securing the loan is public. Both halves a
  lender needs now run on devnet — the check, and the seizure (above). What is missing is the
  lending itself: origination, interest, and a liquidation engine. Confide takes collateral on a
  default someone else defines, and is not a lending protocol.
- **Liquidation as a predicate.** *Is this account underwater* is the same claim with the threshold
  moved, and the program evaluates it — from a floor it records rather than verifies and a price one
  named oracle asserts. Both are the loan's to get right; the chain only enforces the consequence.
- **An issuer filling the slot on the live mints.** `./scripts/set-auditor.sh` fills it on a mint
  we control — one `UpdateMint`, readable on devnet. On `NVDAx` it is Backed's call, which is the
  point: see *What it does not do*.
- **Standing grants per counterparty, revocable.** The policy layer expresses it; there is no
  product surface on top of it here.

Details and the full mint readings: [docs/ONCHAIN.md](docs/ONCHAIN.md).

**On devnet outliving the judging window:** the finding above is on mainnet and does not reset; the
account, the program and the mirrored mint are on devnet and can. `./scripts/healthcheck.sh` checks
every live claim, and [docs/DURABILITY.md](docs/DURABILITY.md) has the recovery steps and the
recorded evidence. The collateral proofs are self-contained and would keep verifying after a reset
wiped the account they are about — so the page compares the live ciphertext before treating a pass
as meaningful, rather than showing a green that means nothing.

## Run it

The live page reads the mints from mainnet in your browser, pulls real wallets out of recent NVDAx
transactions with the balance each published as it settled, shows the Confide account on devnet
reading zero, and — on a button press — has Solana's ZK program verify the lender's proof while you
watch. Source in
[`web/`](web/).

**Nothing required — no key, no account, no funding:**

```bash
./scripts/slot-scan.sh        # every tokenized-equity mint on Solana — all 1,869, both issuers
./scripts/onchain-check.sh    # four of them in detail
./scripts/bind-account.sh     # bind a disclosure to a live account, re-read to confirm
./scripts/devnet-verify.sh    # the NAV-floor proof, checked by Solana's ZK program
./scripts/committee.sh        # the release committee as five actual processes
./scripts/demo.sh             # the two lanes, then the proof going to Solana
./scripts/deshield-proofs.sh  # make the collateral public on default, naming no recipient
./scripts/seizure-status.sh   # read the seizure back off devnet — no keys, no wallet
./scripts/seizure-proofs.sh   # the three proofs a seizure needs, checked by Solana's ZK program
./scripts/healthcheck.sh      # every live claim above; exits with the number that died
cargo test                    # 55 tests
cd programs/confide-seizure && cargo test    # 32 more, over the seizure program
```

`healthcheck.sh` covers the mainnet finding on NVDAx, the devnet program, account, mirror mint and
its account gate, the anchored disclosure, the keys quoted in `docs/ONCHAIN.md`, and the four
published links. **It is not a proof that every sentence here is true** — the 1,869-mint premise is
`slot-scan.sh`, and prose it does not know about can still rot. It is the set of claims worth
failing loudly.

**Needs the account's keys** — `account-keys.json`, written by `provision-account.sh`. Reading a
confidential balance and proving over it are things only the holder can do; that is the point.

```bash
./scripts/read-balance.sh <account> account-keys.json
./scripts/prove-collateral.sh <account> 100000 account-keys.json
./scripts/refresh-proofs.sh <account> 100000    # rewrite the page's proofs for a new account
```

**Needs a devnet-funded keypair:**

```bash
./scripts/provision-account.sh    # stand up a confidential account we hold the key to
./scripts/set-auditor.sh <mint>   # fill the auditor slot — one UpdateMint
./scripts/anchor-receipt.sh       # seal this account's position and anchor its commitment
```

`anchor-receipt.sh` needs `account-keys.json` as well, because what it seals is read out of the
account rather than invented for the occasion.

`anchor-receipt.sh` writes through
[`6a1Kd8…AHytv`](https://explorer.solana.com/address/6a1Kd8Yo5U9wMXUtMnU1PZF8xy6wJ6zWyMr7uKNAHytv?cluster=devnet)
and reads it back to check the stored bytes against the artifact. **147 bytes land on-chain: a hash
and two dates.** Deploying a program costs devnet rent proportional to its size, and the faucet
refuses — see [docs/DURABILITY.md](docs/DURABILITY.md) for the figures and for which keypair pays.

Data the repo pins rather than fetching at runtime is refreshable:
`./scripts/refresh-mints.sh` (the 1,869 mints) and `./scripts/refresh-actions.sh` (the corporate-action
schedule). Both assert on what they must contain rather than writing whatever came back.

The invariants are written as claims you can run, not prose:
[`crates/confide-embargo/tests/invariants.rs`](crates/confide-embargo/tests/invariants.rs).

| | |
|---|---|
| **I1** | unopenable before `T` — **if fewer than `k` agents collude.** Shares carry no clock; the assumption is stamped on the artifact (`ReleaseTrustModel`), not implied |
| **I2** | unstoppable at `T` by the holder *as a party to the protocol* — it is not a parameter of any function on the opening path, and in `scripts/committee.sh` it is a process that exited in September. **A holder that captures `n − k + 1` agents stops it anyway**, and nothing here prevents that |
| **I3** | bound to the position of record — a post-hoc revision is refused. The commitment is over the account's *own* on-chain ciphertext, so the figure released at `T` has to open it. **The only one that depends on no one's behaviour**: it is a comparison, not a promise |
| **I4** | the auditor reads throughout; only *public* disclosure is delayed |
| **I5** | opening is irreversible — revocation is not clawback |

## What it does not do

Stated because a reader should find the limits here rather than discover them:

- **The committee is the trust.** `k = 3, n = 5` tolerates 2 early colluders and 2 withholders, and
  those are the *same* agents — choosing `k` trades I1 against I2 and cannot minimise both. There is
  no stake to slash and no cryptographic clock. A public-randomness timelock (`TimeLockPuzzle` in
  `ReleaseTrustModel`) is the one change that would make both unconditional; it is named, not built.
- **Lending.** Seizure runs — that row is above, and
  [docs/SEIZURE.md](docs/SEIZURE.md) is how. What is still missing is everything around it:
  origination, interest, a liquidation engine, and an oracle anyone should trust. Confide takes
  collateral on a default someone else defines. **The escrow is also frozen while the loan lives** —
  the proofs bind to a ciphertext that must not move, so a borrower cannot top up or partially
  withdraw without unwinding and re-originating.
- **One mint, ours.** The accounts here are on a mint this repo provisioned with **NVDAx's
  confidential-transfer configuration** — the auditor slot and `autoApproveNewAccounts: false`. It is
  not an NVDAx replica: the live mint also carries a permanent delegate, a transfer hook, a
  default-account-state, a scaled-UI-amount config, a pausable config and metadata, and none of
  those are here. Doing it on `NVDAx` needs Backed's approval, which is why they are the first
  customer rather than an obstacle — see *Who uses this first*.

  Wrapping xStocks into a mint of our own would dodge the approval and is the wrong trade twice
  over. A wrapped token is not the one lenders take as collateral, so the clearest use case dies on
  contact. And holding the backing would make us the single trusted party this layer exists to
  remove.
- **Custody, in the one sense that counts.** Confide holds nobody's keys and never sees a balance,
  but the seizure escrow is a token account a program owns, and while a loan is open the borrower
  cannot move what is in it. The same custody every lending protocol takes, named here rather than
  left inside a word used elsewhere to mean something else.
- **Not built, deliberately:** no ATS, no order matching, no MEV protection, no mainnet deployment,
  and no claim to discharge any regulatory filing.

## Why this and not MEV protection

Jupiter already ships Ultra / MEV Protect / JupiterZ RFQ, and they are good. They protect the
transaction **in flight**. Confide is about the **settled balance** — the permanent public record of
what you hold, which no relay touches. Different axis. See [DESIGN.md §2](DESIGN.md).

In TradFi a manager with discretion over $100M+ of Section 13(f) securities files Form 13F **45
days after quarter end**. That lag is legislated, for exactly the harm that real-time position
disclosure causes. On Solana, tokenized equities did ~$5.8B of spot DEX volume in Q2 2026 ([Crypto Briefing, Q2 2026](https://cryptobriefing.com/solana-dex-tokenized-stocks-volume/)) and the
lag is **zero**.

**What this is not.** xStocks are *not* Section 13(f) securities and holding them creates no Form
13F obligation — they are issued by Backed Finance AG under Swiss law with their own Swiss ISIN
(`NVDAx` = `CH1436219195`; NVDA itself = `US67066G1040`), and the SEC's joint statement of 28
January 2026 separates issuer-sponsored tokenization conveying true ownership from third-party
products conveying a custodial entitlement. The obligation Confide serves today is **contractual** —
the quarterly report a GP owes its LPs. 13F is the design this borrows and the requirement that
arrives with instruments like the tokenized-form trading the SEC approved for Nasdaq on 2026-03-18. [DESIGN.md §3a](DESIGN.md) says all of
this in full rather than leaving it implied.

## The split problem

A quarterly report states holdings **as of the reporting date**. Confide seals at quarter end and opens 45 days
later. If a split lands in between, the number that opens is quoted in units that no longer exist —
the disclosure is correct and unreadable at the same time.

This is not hypothetical. The live xStocks schedule has **eleven actions queued** that move what a
holder holds — including `PPLTx` 1→10 and a `HONx` 2→1 reverse sharing its date with a spin-off.
**Eight of them restate exactly. Three have no whole-number ratio** — the spin-off and two
fractional stock dividends — **and are reported rather than guessed**
([`fixtures/corporate-actions.json`](crates/confide-equity/fixtures/corporate-actions.json),
refreshable with `scripts/refresh-actions.sh`).

The fix is not to re-seal — the commitment must not move, that is the whole point. It is to restate
at read time. Restatement reads the issuer's published schedule — one source today — and is
**deterministic**, so the holder gains nothing by staying quiet about a split: anyone can recompute
it and everyone gets the same answer. `confide-open` prints both numbers, separates *nothing
happened* from *something happened I cannot compute*, and refuses rather than rounding.

## And the other half of a quarterly report

An LPA does not only ask *what do you hold*; it carries covenants of the form *"the fund is at or
above X"*, which must be answerable before the position itself is disclosable. `confide-equity` proves
that as a predicate: the LP learns one bit and no position, and the proof goes to the live ZK
program.

The premise itself — every auditor slot still empty — is checked by `./scripts/slot-scan.sh` against
mainnet and by `./scripts/healthcheck.sh` on the four mints this repo pins. The unit test named
`every_xstock_has_confidential_transfers_and_an_empty_auditor_slot` guards those four constants and
would stay green if Backed filled a key on any of the other 1,865. Its own doc comment says so; this
sentence used to claim the opposite.

## Built on

Stocklana's rules: *original work. Open-source components are fine if you say so.* So, said plainly:

| Component | Origin | License | Role |
|---|---|---|---|
| `aperture-core` | `psyto/aperture`, pre-existing | Apache-2.0 | Token-2022 confidential balances, disclosure package, policy, auditor |
| `aperture-receipts` | `psyto/aperture`, pre-existing | Apache-2.0 | content-blind on-chain receipt, native Solana program |
| **Confide** | **this repository** | Apache-2.0 | **the embargo mechanism (I1–I3), the k-of-n sharing, the equity layer, the seizure program, the demo** |

**Which window, because the two events do not share one.** For Stocklana, Confide is new work
start to finish — the first commit is inside its window. For Crypto World's Fair the window opened
2026-09-14 06:00 PT, when 48 commits already existed, so what that contest judges is
`cwf-2026-baseline..HEAD` and nothing before it. The boundary is a tag, recorded with the commands
that establish it, in [docs/WORK-WINDOW.md](docs/WORK-WINDOW.md). Saying "in-window" without saying
which window is how a true sentence becomes a false declaration.


The secret sharing is Confide's own — `crates/confide-embargo/src/shamir.rs`, GF(256), no dependency.

