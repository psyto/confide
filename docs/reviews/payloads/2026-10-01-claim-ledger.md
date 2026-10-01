# Review request — the claim ledger, 2026-10-01

The founder's brief (docs/cwf-2026/CLAUDE-CODE-BRIEF.md §3 P0, item 4) asks for "a concise claim
ledger: each public statement, its exact evidence path, and its boundary. Especially cover the account
scan, issuer approval, what Confidential Balances hide, auditor scope, and the live/devnet distinction."

New: docs/cwf-2026/CLAIMS.md (18 rows) and a docs-consistency.sh section THE CLAIM LEDGER. The ledger
copies no measured figure; it cites `file.json#field`, and the check resolves every one, checks every
cited path and `--bin` exists, that every check section named in the last column exists, that ids are
unique and rows have 6 cells, and that no comma-grouped number or $-figure appears. Six deliberate
breakages each failed (bad field, bad path, bad section, duplicate id, copied figure, bad bin).

Also in this change:
- STATUS.md: the 2026-10-01 record quoted the retracted line "Nobody has ever opened one" and
  CONFIGURED IS NOT APPROVED failed on it — the last commit (fa9378b) went in red. Fixed by putting the
  record's arrow on that line (the check's existing exemption for correction records), not by
  widening the check.
- My first M1 boundary said "That this is every tokenized stock on Solana" (a negation); THE POPULATION
  flagged the phrase shape and I reworded it rather than allowlisting.

Things I know are weak, said so it is judged:
- The "Re-checked by" column was first written with attributions I had not verified (e.g. healthcheck
  for the issuance signatures; it does not read them). I corrected it after grepping; a dash now means
  nothing re-checks the claim. D3, D6, P1, A1, A2, H1 have dashes.
- The check verifies that references resolve, not that each claim's wording is true of the evidence.
- Remaining reds are founder-only: the CWF form and YouTube description changed since pasted, and
  the GitHub About differs from ./scripts/github-about.sh.

Questions:
1. Is any row an overclaim or an underclaim against the evidence it cites? Read the cited files.
   Especially D2 (MissingRequiredSignature meaning), D4 (preflight, not on chain), L1, P1, P2, M5.
2. Which public statements on live surfaces (README.md, web/index.html, _submission/cwf-form.md,
   docs/cwf-2026/STORY.md, video/DEMO.md) are NOT in the ledger and should be? Grep yourself.
3. Is the check too weak in a way that lets the ledger point at nothing? E.g. section-name regex,
   path regex roots, json field resolution.
4. Does any "Re-checked by" entry claim more than the named check does?

--- docs/cwf-2026/CLAIMS.md ---
# Claim ledger

Every public statement Confide makes, the file or run that establishes it, where it was measured,
and what it does **not** say. Written 2026-10-01 for the brief's §3 P0.

**No measured figure is copied into this file.** A figure appears as a reference —
`web/usage.json#total_accounts` — and `scripts/docs-consistency.sh` (THE CLAIM LEDGER) resolves
every one against the file, and checks that every path cited here exists. The prose surfaces that
*do* quote the figures are checked by the `docs-consistency.sh` sections in capitals in the last
column; a script there re-derives the evidence itself. **A dash means nothing re-checks it** —
that is a gap, recorded rather than hidden.

**Cluster words are used strictly.** *mainnet* = read from mainnet-beta, nothing of ours runs
there. *devnet* = ran on devnet with mints we created. *testbed* = the standing devnet issuer in
`docs/TESTBED.md`. *local* = no chain at all. *hypothesis* = nobody has measured it.

---

## What is measured on mainnet

| # | Claim | Evidence | Scope | Does **not** say | Re-checked by |
|---|---|---|---|---|---|
| M1 | Every tokenized-equity mint in three issuers' catalogues ships Token-2022 confidential transfers. | `web/mints.json` (the list), `web/slots.json#mints`, produced by `scripts/slot-scan.sh` | mainnet; `web/slots.json#generated_utc` | Anything about mints outside those catalogues — it is a catalogue, not a census of the chain (`docs/cwf-2026/THE-POPULATION.md`) | THE EXTENSION INVENTORY; `scripts/healthcheck.sh` re-reads one mint (NVDAx) |
| M2 | On all of them the auditor slot is empty. | `web/slots.json#auditor_empty` | as M1 | *Why* it is empty — an empty slot is also the zero-initialised default (`docs/cwf-2026/THE-PINCER.md`) | THE EXTENSION INVENTORY |
| M3 | On all of them a confidential account needs the issuer's approval. | `web/slots.json#gated`, `web/slots.json#auto_approve` | as M1 | That issuers would refuse. Nobody has asked one. | THE UNASKED QUESTION (no surface predicts an issuer) |
| M4 | Of the live token accounts on six mints, this many have configured a confidential balance, and this many are approved. | `web/usage.json#total_accounts`, `web/usage.json#total_confidential_accounts`, `web/usage.json#total_approved_accounts`, per mint in `web/usage.json#mints`, produced by `scripts/usage-scan.sh` | mainnet; six mints, two per issuer; `web/usage.json#generated_utc` | Anything about the other mints in M1. That nobody wants the feature — nobody has been able to use it. | THE ACCOUNT SCAN, CONFIGURED IS NOT APPROVED |
| M5 | Kamino's tokenized-equity reserves refuse an account carrying confidential value at deposit. | `scripts/kamino-verdict.sh` (the pinned lines of klend), `web/capacity.json#reachable_confidentially_usd`, `web/capacity.json#authorised_capacity_usd`, produced by `scripts/capacity.sh` | mainnet, read-only; `web/capacity.json#generated_at` | That Kamino is wrong to. It is correct underwriting. No contact with Kamino. | `scripts/kamino-verdict.sh` |

## What runs on devnet

| # | Claim | Evidence | Scope | Does **not** say | Re-checked by |
|---|---|---|---|---|---|
| D1 | An allocation to a configured but unapproved account is refused by Token-2022 (`Custom(24)`), on chain. | `scripts/issue-e2e.sh`; signatures in `docs/cwf-2026/ISSUANCE-RUNS.md` | devnet, mints we created with the real mints' gate and empty auditor | That a real issuer runs this flow. The refusal is Token-2022's, not Confide's. | `python3 app/test_app.py` (the script reports it only after reading the landed error; no chain). Re-running needs an RPC endpoint |
| D2 | A key that is not the mint's approval authority cannot approve an account (`MissingRequiredSignature`), on chain. | `scripts/issue-e2e.sh` (the self-approval step) | devnet | Who should hold the authority. That is the issuer's decision. | `python3 app/test_app.py` (refuses to report it if the account then reads approved; no chain) |
| D3 | After the issuer approves exactly that account, the same allocation settles in one transaction. | `scripts/issue-e2e.sh`; signatures in `docs/cwf-2026/ISSUANCE-RUNS.md` | devnet | That the allocation is a regulated issuance. It is a token transfer. | — (re-running `scripts/issue-e2e.sh` needs an RPC endpoint) |
| D4 | A trade with one of its two signatures is refused before it reaches a block. | `scripts/issue-e2e.sh` (RPC preflight, `-32002` / `SignatureFailure`) | devnet | That the chain recorded a refusal. Nothing landed; the RPC node refused it. | `python3 app/test_app.py` (a recorded real `-32002` answer is parsed in full) |
| D5 | Two approved holders settle stock for stablecoin atomically; each side decrypts its own receive amount from the verified proof context before signing. | `web/dvp.json`, `web/swaps.json#confirmed_when_written`, `scripts/swap-e2e.sh` | devnet | Matching, price discovery or a venue. Terms are agreed off chain. | THE DEVNET TRADES, `scripts/wire-check.sh` |
| D6 | One leg can be a fee-charging mint (shaped like PYUSD), which needs a different instruction and a proof staged through a record account. | `scripts/swap-e2e.sh`, `web/swaps.json` | devnet | That PYUSD itself was used. The mint is ours, shaped like it. | — |

## What Confide's client refuses (local, no chain)

| # | Claim | Evidence | Scope | Does **not** say | Re-checked by |
|---|---|---|---|---|---|
| L1 | Before signing, each side compares the proof context with the amount *it agreed*, not with the figure the counterparty's file states; one unit short or over is refused. | `cargo test -p confide-ct --bin swap-check`, `scripts/swap-pin-check.sh`; on devnet `SHORT=<units> scripts/issue-e2e.sh` | local; devnet for `SHORT` | That the chain enforces the price. It enforces both legs or neither; the amount check is the signer's. | `scripts/swap-pin-check.sh` |

## What is private and what is not

| # | Claim | Evidence | Scope | Does **not** say | Re-checked by |
|---|---|---|---|---|---|
| P1 | Amounts and balances are encrypted; every account in a settled trade reads a public balance of zero. | `scripts/read-balance.sh` (reads the chain), `web/dvp.json` | devnet | That the trade is invisible. Accounts, mint, and participation in the transaction are public. | — (the zero is read from the chain by the script at run time, not re-checked later) |
| P2 | Token-2022's only mint-configured disclosure is one mint-wide auditor key, which can decrypt the amount of every confidential transfer made while it is set. | Token-2022 confidential-transfer extension; `docs/cwf-2026/THE-PINCER.md` | protocol | That it reads whole balances, transfers made before it was set, or can move funds. Selective auditor visibility is not built. | THE AUDITOR'S REACH |

## The context the pitch leans on

| # | Claim | Evidence | Scope | Does **not** say | Re-checked by |
|---|---|---|---|---|---|
| X1 | The SEC's 2026-09-17 exemption covers AMM-executed trading with published fills and a per-name volume cap. | `docs/SEC-EXEMPTION.md` (primary source, quoted) | regulatory text | Anything about Confide's legal status. Confide is not a venue and makes no regulatory claim. | THE SEC ORDER |

## What is absent

| # | Claim | Evidence | Scope | Does **not** say | Re-checked by |
|---|---|---|---|---|---|
| A1 | Traction is zero: no user, pilot, design partner or issuer has used or agreed to use Confide. No issuer has been contacted. | `docs/cwf-2026/STORY.md` §8; `docs/cwf-2026/REACH.md` records what can be counted | — | Anything about demand, either way. | — (an absence; it changes only by a founder action) |
| A2 | Nothing of Confide's runs on mainnet. Mainnet is only read. | `docs/cwf-2026/STORY.md` §8; `docs/DURABILITY.md` (what resets and what does not) | — | — | — |
| H1 | *Hypothesis:* the first buyer is an issuer that wants eligibility control without publishing holders' positions; a later integration is a venue or custodian consuming a proof of a condition. | `docs/cwf-2026/STORY.md` §8 (a priority set by the founder's brief) | hypothesis | That anyone has said so. The opposite reading — an issuer is a gate, not a buyer — is also on record (`docs/cwf-2026/THE-PINCER.md`). Neither is tested. | — |

--- scripts/docs-consistency.sh, THE CLAIM LEDGER ---
echo "  THE CLAIM LEDGER — every reference in docs/cwf-2026/CLAIMS.md resolves"
# The ledger is only worth having if what it points at is there. It copies no figure: a number is
# written as file.json#field and resolved here, so the ledger cannot go stale the way prose did.
# A path that was renamed, a field a producer stopped writing, a check section that was retitled,
# or a figure pasted in where a reference belongs -- each is a ledger that reads as evidence and
# points at nothing.
python3 - <<'PYCL' && ok "every path, field and check the claim ledger cites exists, and it copies no figure" \
                  || bad "the claim ledger cites something that is not there, or copies a figure"
import glob, json, re, sys, pathlib
L = pathlib.Path("docs/cwf-2026/CLAIMS.md")
if not L.exists():
    print("      docs/cwf-2026/CLAIMS.md is gone"); sys.exit(1)
t = L.read_text(encoding="utf-8")
bad = []
for tok in re.findall(r"`([^`]+)`", t):
    for m in re.finditer(r"((?:web|scripts|docs|app|video|_submission|crates)/[\w./-]*\w)(?:#([\w.]+))?", tok):
        path, field = m.group(1), m.group(2)
        if not pathlib.Path(path).exists():
            bad.append(f"no such file: {path}"); continue
        if field:
            try:
                v = json.loads(pathlib.Path(path).read_text())
                for k in field.split("."):
                    v = v[k]
            except (KeyError, TypeError, ValueError):
                bad.append(f"{path} has no field {field}")
    for b in re.findall(r"--bin ([\w-]+)", tok):
        if not any(re.search(r'name = "%s"' % re.escape(b), pathlib.Path(c).read_text())
                   for c in glob.glob("crates/*/Cargo.toml")):
            bad.append(f"no binary named {b}")
script = pathlib.Path("scripts/docs-consistency.sh").read_text()
rows = [r for r in t.splitlines() if re.match(r"\|\s*[A-Z]\d+\s*\|", r)]
ids = [r.split("|")[1].strip() for r in rows]
for i in sorted({i for i in ids if ids.count(i) > 1}):
    bad.append(f"claim id {i} is used twice")
for r in rows:
    cells = r.strip().strip("|").split("|")
    if len(cells) != 6:
        bad.append(f"{cells[0].strip()}: {len(cells)} cells, not 6"); continue
    for sec in re.findall(r"\b(?:[A-Z][A-Z']+ ){1,5}[A-Z][A-Z']+\b", cells[5]):
        if f'echo "  {sec}' not in script:
            bad.append(f"{cells[0].strip()}: no check section called {sec}")
for m in re.finditer(r"\b\d{1,3}(?:,\d{3})+\b|\$\d[\d,.]*", t):
    bad.append(f"a copied figure: {m.group(0)} -- cite the file#field it comes from")
for b in bad:
    print("      " + b)
sys.exit(1 if bad else 0)
PYCL
