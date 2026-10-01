# Review — the claim ledger, 2026-10-01

Codex (`codex exec -s read-only`), payload [`payloads/2026-10-01-claim-ledger.md`](payloads/2026-10-01-claim-ledger.md).
The verdict and findings are below verbatim. **Each was checked against the files before it was
taken**; what was done with it is in the table first.

| finding | checked against | taken? |
|---|---|---|
| M3 overclaims — the gate is on *new* accounts, and "issuer" goes beyond the field | `docs/cwf-2026/THE-PINCER.md` *Narrowed — 2026-09-19* says exactly this | yes — "newly configured", "the mint's approval authority" |
| D2 cites a script, not a record that it landed | the signature is in `STATUS.md` 0bn and nowhere in the ledger | yes — and every `run` row must now cite a record, enforced |
| D4 says "trade"; it is a half-signed allocation | `scripts/issue-e2e.sh` *the issuer signs the allocation alone* | yes |
| P1 generalises to every settled trade | `read-balance.sh` reads one account; the zeros are recorded only for the named runs | yes — scoped to the runs in `ISSUANCE-RUNS.md` and `STATUS.md` 0bn |
| P2 cites no exact source | correct | partly — cites Confide's builder encrypting both halves to the auditor key, and the locked interface crate. No positive check exists; the row says so |
| M5 "reserves refuse" | `kamino-verdict.sh` reads pinned code; no deposit is attempted | yes — "ordinary deposit path", and the boundary says no deposit was attempted |
| eight public claims missing | each found on the named surface | yes — M6, M7, D7, D8, D9, I1, I2, B1 |
| checker: `--bin` matches any `name =` | correct (`Cargo.toml` names packages too) | yes — `[[bin]]` targets only |
| checker: malformed ids drop out | correct | yes — a malformed id is a finding |
| checker: section name matched anywhere | correct | yes — only `echo "  NAME —` headings |
| checker: ungrouped figures pass | correct | yes — bare numbers of four digits or more fail |
| checker: a file reference proves only existence | correct | not fixable by a lint — stated in the ledger's head as what the check does not do; kinds now say what each row must cite |
| M1/M2, M3, D5, P2, X1 "re-checked by" overstated | `slot-roles.sh`, the UNASKED QUESTION, DEVNET TRADES, AUDITOR'S REACH and SEC ORDER sections, `wire-check.sh` | yes — each now says how little it does, or is a dash |

**Found while taking D8:** `docs/TESTBED.md` says the published key's inability to mint "is checked
rather than asserted". No script checks it — `testbed-up.sh --check` compares the approval
authority, the gate and the auditor, not the mint authority. It was observed once by hand. The
ledger records it as a dash; adding it to `--check` needs a devnet run this session could not make.

---

I would not sign off on the ledger as “every public statement” yet. Its core rows are mostly carefully bounded, but several claims are either broader than their cited artifact or not actually re-checked by the named section.

### 1. Claim/evidence review

Material findings:

- **M3 overclaims slightly.** `autoApproveNewAccounts: false` establishes that a *new* confidential account needs the mint’s confidential-transfer approval authority before it can receive confidential transfers; it does not mean every existing confidential account perpetually needs issuer approval. “Issuer” is also an attribution beyond the field itself. Use “new account” and “mint’s approval authority.” [THE-PINCER.md](/Users/hiroyusai/src/confide/docs/cwf-2026/THE-PINCER.md:105)

- **D2’s meaning is right; its evidence path is incomplete.** The script explicitly explains the unusual `MissingRequiredSignature` meaning and verifies that the account remains unapproved. But a script is not a record that this particular event landed on devnet. Cite the recorded signature/run alongside the script. [issue-e2e.sh](/Users/hiroyusai/src/confide/scripts/issue-e2e.sh:292)

- **D4’s boundary is excellent, but “trade” is imprecise.** It is a half-signed *allocation*, rejected by the RPC’s signature-verification preflight—not a transaction recorded or executed by the chain. The script itself says exactly this. [issue-e2e.sh](/Users/hiroyusai/src/confide/scripts/issue-e2e.sh:335)

- **L1 is well stated.** The pin check covers both a lowered receive leg and a raised outgoing leg, rather than merely comparing a display. [swap-pin-check.sh](/Users/hiroyusai/src/confide/scripts/swap-pin-check.sh:131)

- **P1 is too broad for its sources.** `read-balance.sh` reads one caller-supplied account; `dvp.json` records party-provided amounts and account IDs, but neither is a durable assertion that *every account in a settled trade* has public zero. Scope it to the four named accounts in a named run, or point to a generated artifact that records the zero assertions/signature. [read-balance.sh](/Users/hiroyusai/src/confide/scripts/read-balance.sh:7) [refresh-swaps.sh](/Users/hiroyusai/src/confide/scripts/refresh-swaps.sh:10)

- **P2 is the riskiest protocol claim.** Its wording is appropriately bounded (“mint-configured,” transfer amounts while set), but “Token-2022 confidential-transfer extension” is not an exact evidence path, and the cited Pincer document is explanatory rather than the protocol source. Cite the pinned Token-2022 source/version or specification. Also have the checker verify that source, rather than merely banning known bad phrasings. [THE-PINCER.md](/Users/hiroyusai/src/confide/docs/cwf-2026/THE-PINCER.md:206)

- **M5 should say “Kamino’s ordinary deposit path,” not “reserves refuse.”** The cited script establishes generic pinned-code constraints on the depositor account; it does not execute a deposit against each reserve. [kamino-verdict.sh](/Users/hiroyusai/src/confide/scripts/kamino-verdict.sh:73)

The remaining rows are reasonable summaries, but D1/D3/D5/D6 also rely heavily on executable source rather than a durable run record. That is fine if labelled “reproducible behavior”; it is weak for “ran on devnet” unless paired with signatures or generated run data.

### 2. Public claims missing from the ledger

The biggest omissions I found are:

- The **no-program/no-intermediary architecture**: two Token-2022 instructions and two signatures; Confide only builds proofs and assembles/checks the transaction. [README.md](/Users/hiroyusai/src/confide/README.md:139)
- The **testbed authority boundary**: a published devnet key can approve accounts but cannot mint. [README.md](/Users/hiroyusai/src/confide/README.md:127)
- The **AMM/pool impossibility claim**: public reserves reveal the exact trade delta. [web/index.html](/Users/hiroyusai/src/confide/web/index.html:283)
- The **stablecoin compatibility/configuration claims**: USDC/USDT/USDS cannot use these extensions; PYUSD/USDG can; their claimed shared authority/configuration. [STORY.md](/Users/hiroyusai/src/confide/docs/cwf-2026/STORY.md:67)
- The **all-mint control-extension inventory**: permanent delegate, pause configuration, and transfer hook on the catalogue. [README.md](/Users/hiroyusai/src/confide/README.md:28)
- The **devnet collateral, seizure/release, and receipt claims** surfaced in the web page. These are substantial product claims, even if parked in `<details>`. [web/index.html](/Users/hiroyusai/src/confide/web/index.html:326)
- The **off-chain eligibility/KYC boundary**: Confide does not make or bypass the eligibility decision. [STORY.md](/Users/hiroyusai/src/confide/docs/cwf-2026/STORY.md:87)
- The **“first trade is an issuance” inference** should be a ledger row marked as an inference from M3+M4, rather than only appearing in prose. [README.md](/Users/hiroyusai/src/confide/README.md:38)

### 3. Checker weaknesses

Yes—structurally it is useful, but it can still point at essentially nothing.

- It only extracts paths inside backticks. P2’s protocol “source” is therefore unchecked.
- A file reference only proves existence; a script reference proves neither that it contains the asserted behavior nor that it was run.
- JSON resolution proves a key is present, not that it has the expected type, meaning, relation to another field, or non-null value.
- `--bin` can match any `name = "…"` in a Cargo manifest, not necessarily a `[[bin]]` target.
- Row parsing ignores any ledger row whose ID is not exactly `[A-Z]\d+`; malformed/alternate IDs can disappear from uniqueness and six-cell checks.
- The section check only searches for the literal `echo "  SECTION"` anywhere in the shell file. A comment, dead branch, or unrelated echo satisfies it.
- The “no copied figure” rule allows ungrouped figures such as `1992`, `518744`, `0`, and any non-dollar measured value. It enforces only the two chosen textual shapes.

The right next step is a small structured ledger format—or at least machine-readable per-row metadata—where each claim declares `evidence_kind` (`json_field`, `script_behavior`, `run_signature`, `source_excerpt`, `inference`) and a checker validates the appropriate kind.

### 4. “Re-checked by” overstatements

These entries claim more than their named checks establish:

- **M1/M2:** THE EXTENSION INVENTORY only synchronizes an extension-role table with `slots.json`; it does not re-scan the catalogue, and it does not check the auditor-empty total. [slot-roles.sh](/Users/hiroyusai/src/confide/scripts/slot-roles.sh:1)
- **M3:** THE UNASKED QUESTION only bans predictions about issuer behavior. It does not verify gate state or approval authority. [docs-consistency.sh](/Users/hiroyusai/src/confide/scripts/docs-consistency.sh:1160)
- **D5:** THE DEVNET TRADES checks the count of prose mentions; `wire-check.sh` checks seizure-program account counts/discriminants. Neither re-checks approved holders, atomic settlement, decrypting, or pinning. [docs-consistency.sh](/Users/hiroyusai/src/confide/scripts/docs-consistency.sh:1244) [wire-check.sh](/Users/hiroyusai/src/confide/scripts/wire-check.sh:1)
- **P2:** THE AUDITOR’S REACH is a negative wording lint. It does not positively establish the protocol’s sole-disclosure model. [docs-consistency.sh](/Users/hiroyusai/src/confide/scripts/docs-consistency.sh:1319)
- **X1:** THE SEC ORDER checks a few pinned literals and forbidden claims, not the full AMM/public-fill/cap proposition.

D1, D2, D4, and L1 are honestly qualified as local/static re-checks. The dashes are appropriately conservative.