# Claim ledger

Every public statement Confide makes, the file or run that establishes it, where it was measured,
and what it does **not** say. Written 2026-10-01 for the brief's §3 P0, and corrected the same day
on review ([`../reviews/2026-10-01-claim-ledger.md`](../reviews/2026-10-01-claim-ledger.md)).

**No measured figure is copied into this file.** A figure appears as a reference —
`web/usage.json#total_accounts` — and `scripts/docs-consistency.sh` (THE CLAIM LEDGER) resolves
every one against the file. The prose surfaces that *do* quote the figures are checked by the
sections in capitals in the last column.

**What THE CLAIM LEDGER checks, and what it does not.** That every cited path, JSON field, binary and
check section exists; that each row's *kind* carries the evidence that kind needs (below); that no
figure is pasted in. **It does not check that a claim's wording is true of its evidence** — that is
what review is for, and the first review of this file found six rows that said more than their
evidence.

**Kinds.**

| kind | means | must cite |
|---|---|---|
| `measured` | read from a chain and stored | a `file.json#field` |
| `printed` | read from a chain by a script that stores nothing | the script — **a gap: nothing to re-check against** |
| `run` | happened on devnet and was recorded | a record: a `.json` or `.md` that holds the signatures or the result |
| `local` | runs with no chain | the test or script |
| `source` | what code or a primary document says | the file |
| `inference` | follows from other rows | the rows, by id |
| `absence` | nothing has happened | where the absence is stated |
| `hypothesis` | nobody has measured it | where it is stated as one |

**Cluster words are used strictly.** *mainnet* = read from mainnet-beta; nothing of Confide's runs
there. *devnet* = ran on devnet with mints Confide created. *testbed* = the standing devnet issuer in
`docs/TESTBED.md`. *local* = no chain at all.

In **Re-checked by**, a dash means nothing re-checks the claim — a gap, recorded rather than hidden.
A capitalised name is a `docs-consistency.sh` section, and the parenthesis says how little it may do.

---

## Measured on mainnet

| # | Kind | Claim | Evidence | Scope | Does **not** say | Re-checked by |
|---|---|---|---|---|---|---|
| M1 | measured | Every mint in three issuers' tokenized-equity catalogues ships Token-2022 confidential transfers. | `web/mints.json` (the list), `web/slots.json#mints`, from `scripts/slot-scan.sh` | mainnet; `web/slots.json#generated_utc` | Anything about mints outside those catalogues — a catalogue, not a census of the chain (`docs/cwf-2026/THE-POPULATION.md`) | `scripts/healthcheck.sh` (re-reads NVDAx only; nothing re-scans the catalogue) |
| M2 | measured | On all of them the auditor slot is empty. | `web/slots.json#auditor_empty` | as M1 | *Why* it is empty — an empty slot is also the zero-initialised default (`docs/cwf-2026/THE-PINCER.md`) | `scripts/healthcheck.sh` (NVDAx only) |
| M3 | measured | On all of them a **newly configured** confidential account cannot receive a confidential transfer until the mint's approval authority approves it. | `web/slots.json#gated`, `web/slots.json#auto_approve` | as M1 | That an account once approved needs approval again (it does not, `docs/cwf-2026/THE-PINCER.md`). That issuers would refuse — nobody has asked one. | — (THE UNASKED QUESTION only bars predicting an issuer) |
| M4 | measured | Of the token accounts on six mints, this many have configured a confidential balance and this many are approved. | `web/usage.json#total_accounts`, `web/usage.json#total_confidential_accounts`, `web/usage.json#total_approved_accounts`, per mint `web/usage.json#mints`, from `scripts/usage-scan.sh` | mainnet; six mints, two per issuer; `web/usage.json#generated_utc` | Anything about the other mints in M1. That nobody wants the feature — nobody has been able to use it. | THE ACCOUNT SCAN, CONFIGURED IS NOT APPROVED (prose against the file; nothing re-scans) |
| M5 | measured | Kamino's ordinary deposit path refuses a depositor account carrying confidential value. | `scripts/kamino-verdict.sh` (the pinned klend lines), `web/capacity.json#reachable_confidentially_usd`, `web/capacity.json#authorised_capacity_usd`, from `scripts/capacity.sh` | mainnet, read-only, klend at a pinned commit; `web/capacity.json#generated_at` | That a deposit was attempted against each reserve — the constraint is read from code. That Kamino is wrong to; it is correct underwriting. No contact with Kamino. | `scripts/kamino-verdict.sh` (the pinned lines still say it) |
| M6 | measured | The same mints also carry a permanent delegate, a pause configuration and a transfer hook. | `web/slots.json#extensions`, rendered by `scripts/slot-roles.sh` | as M1 | What any issuer uses them for. | THE EXTENSION INVENTORY (the table is what the file says) |
| M7 | printed | Of the large dollar stablecoins, USDC, USDT and USDS cannot move confidentially (legacy SPL); PYUSD and USDG can. | `scripts/cash-scan.sh`; stated in `docs/cwf-2026/STORY.md` §2 | mainnet; when it was last run is not stored | That PYUSD or USDG holders use it. | — (the script stores nothing) |

## Ran on devnet, and recorded

| # | Kind | Claim | Evidence | Scope | Does **not** say | Re-checked by |
|---|---|---|---|---|---|---|
| D1 | run | An allocation to a configured but unapproved account is refused by Token-2022 (`Custom(24)`), and the refusal is on chain. | `scripts/issue-e2e.sh`; signatures in `docs/cwf-2026/ISSUANCE-RUNS.md` (2026-09-23) and `STATUS.md` 0bn (2026-09-30) | devnet, mints Confide created with the real mints' gate and empty auditor | That a real issuer runs this flow. The refusal is Token-2022's, not Confide's. | `python3 app/test_app.py` (the script reports it only from the landed error; no chain) |
| D2 | run | A key that is not the mint's approval authority cannot approve an account; the program answers `MissingRequiredSignature`, on chain, and the account still reads unapproved. | `scripts/issue-e2e.sh` (the self-approval step); signature in `STATUS.md` 0bn | devnet | That a signature was left off. The signer signed; it is not the authority, and that is how the program names the case. Who should hold the authority is the issuer's decision. | `python3 app/test_app.py` (refuses to report it if the account then reads approved; no chain) |
| D3 | run | After the issuer approves exactly that account, the same allocation settles in one transaction. | `scripts/issue-e2e.sh`; signatures in `docs/cwf-2026/ISSUANCE-RUNS.md` and `STATUS.md` 0bn | devnet | That the allocation is a regulated issuance. It is a token transfer. | — (re-running needs an RPC endpoint) |
| D4 | run | An allocation carrying the issuer's signature but not the investor's is refused before it reaches a block. | `scripts/issue-e2e.sh` (RPC preflight, `-32002` / `SignatureFailure`); recorded in `STATUS.md` 0bn | devnet | That the chain recorded a refusal. Nothing landed: the RPC node's signature verification refused it, so there is no signature to cite. | `python3 app/test_app.py` (a recorded real `-32002` answer is parsed in full) |
| D5 | run | Two approved holders settle stock for stablecoin in one transaction; each side decrypts its own receive amount from the verified proof context before signing. | `web/dvp.json` (what each side read), `web/swaps.json#swaps` (the page decodes each from the chain), `scripts/swap-e2e.sh` | devnet | Matching, price discovery or a venue. Terms are agreed off chain. | — (THE DEVNET TRADES counts prose mentions only) |
| D6 | run | One leg can be a fee-charging mint shaped like PYUSD, which needs a different instruction and a proof staged through a record account. | `scripts/swap-e2e.sh`, `web/swaps.json#swaps` | devnet | That PYUSD itself was used. The mint is Confide's, shaped like it. | — |
| D7 | source | No Confide program runs inside the trade: two Token-2022 instructions, two signatures, Solana's atomicity. Confide builds the proofs and assembles and checks the transaction. | `README.md` (*Why there is nothing in the middle*), `scripts/lib/swap.sh` | devnet | That Confide holds no keys anywhere. The demo app holds throwaway devnet keys on the machine it runs on (`docs/cwf-2026/STORY.md` §8). | — |
| D8 | run | The testbed's published approval key can approve accounts and cannot mint. | `docs/TESTBED.md` (the refusal `OwnerMismatch`, recorded by hand) | testbed | — | — (`scripts/testbed-up.sh --check` verifies the approval authority, gate and auditor; it does not compare the mint authority) |
| D9 | run | A confidential position can be held as loan collateral on devnet: a floor proved over the escrow's ciphertext, a default seized without the borrower, and a release back to the holder. | `docs/SEIZURE.md`, `scripts/seizure-e2e.sh`, `web/loans.json` | devnet; the swap does not depend on it | Repayment — the release is attested, not repaid. That any lender would accept it. | `scripts/healthcheck.sh` (the program is deployed and the seized loan still reads seized) |

## Refused by Confide's client, with no chain

| # | Kind | Claim | Evidence | Scope | Does **not** say | Re-checked by |
|---|---|---|---|---|---|---|
| L1 | local | Before signing, each side compares the proof context with the amount *it agreed*, not with the figure the counterparty's file states; one unit short or over is refused. | `cargo test -p confide-ct --bin swap-check`, `scripts/swap-pin-check.sh`; on devnet `SHORT=<units> scripts/issue-e2e.sh` (`STATUS.md` 0bn) | local; devnet for `SHORT` | That the chain enforces the price. It enforces both legs or neither; the amount check is the signer's. | `scripts/swap-pin-check.sh` |

## What is private and what is not

| # | Kind | Claim | Evidence | Scope | Does **not** say | Re-checked by |
|---|---|---|---|---|---|---|
| P1 | run | In the recorded runs, every account in the settled transaction read a public balance of zero while the confidential transfer succeeded. | `docs/cwf-2026/ISSUANCE-RUNS.md` (2026-09-23), `STATUS.md` 0bn (2026-09-30); read from the chain by `scripts/issue-e2e.sh` and `scripts/read-balance.sh` | devnet, the named runs | That the trade is invisible. Accounts, mints, and participation in the transaction are public. | — (read at run time, not re-checked later) |
| P2 | source | Token-2022's only mint-configured disclosure is one mint-wide auditor key, under which each confidential transfer's amount is also encrypted while the key is set. | Confide's own transfer builder encrypts the amount's two halves to the auditor key (`crates/confide-ct/src/lib.rs`, `auditor_lo_b64` / `auditor_hi_b64`), against `spl-token-2022-interface` as locked in `Cargo.lock` | protocol | That the key reads whole balances, transfers made before it was set, or can move funds. Selective auditor visibility is not built. | — (THE AUDITOR'S REACH only bars overstated wording) |

## Inferences and boundaries

| # | Kind | Claim | Evidence | Scope | Does **not** say | Re-checked by |
|---|---|---|---|---|---|---|
| I1 | inference | So the first confidential trade on such a mint is an issuance: the party who can open the account is one of the two parties to the trade. | M3, M4 | — | That issuers will do it. | — |
| I2 | inference | An AMM cannot settle a confidential trade: a pool's reserves are public, and a trade moves them by exactly the amount traded. | `web/index.html` (*Why not just use an exchange?*) | — | That no other venue design could. Only that a pool cannot. | — |
| B1 | source | The eligibility decision (KYC, whatever the issuer requires) happens off chain; Confide neither makes it nor bypasses it. | `docs/cwf-2026/STORY.md` §3 | — | That Confide performs or attests KYC. | — |
| X1 | source | The SEC's 2026-09-17 exemption covers AMM-executed trading, with every fill published and a per-name volume cap. | `docs/SEC-EXEMPTION.md` (primary source, quoted) | regulatory text | Anything about Confide's legal status. Confide is not a venue and makes no regulatory claim. | THE SEC ORDER (pinned literals and forbidden phrasings only) |

## What is absent

| # | Kind | Claim | Evidence | Scope | Does **not** say | Re-checked by |
|---|---|---|---|---|---|---|
| A1 | absence | Traction is zero: no user, pilot, design partner or issuer has used or agreed to use Confide. No issuer has been contacted. | `docs/cwf-2026/STORY.md` §8; `docs/cwf-2026/REACH.md` (what can be counted) | — | Anything about demand, either way. | — (changes only by a founder action) |
| A2 | absence | Nothing of Confide's runs on mainnet. Mainnet is only read. | `docs/cwf-2026/STORY.md` §8; `docs/DURABILITY.md` (what resets and what does not) | — | — | — |
| H1 | hypothesis | The first buyer is an issuer that wants eligibility control without publishing holders' positions; a later integration is a venue or custodian consuming a proof of a condition. | `docs/cwf-2026/STORY.md` §8 (a priority set by the founder's brief) | — | That anyone has said so. The opposite reading — an issuer is a gate, not a buyer — is also on record (`docs/cwf-2026/THE-PINCER.md`). Neither is tested. | — |
