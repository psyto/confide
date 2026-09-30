# Review request — the pre-signing check compared nothing, 2026-09-30 (second review today)

You reviewed the population correction earlier today
(`docs/reviews/2026-09-30-the-population.md`) and found four live surfaces both my first pass and my
own new checker walked past. **Assume the same is true here.** Everything below is in the working
tree, uncommitted; `git diff` shows all of it.

The founder's instruction was to stop chasing paste/form updates — they have to be redone at
submission time anyway — and prioritise implementation. So I read the flow before planning, and the
plan changed.

---

## 1. What I expected to find, and did not

`docs/cwf-2026/CLAUDE-CODE-BRIEF.md` §2 asks for an issuance-first flow a reviewer can follow in
order, 1→7, with a meaningful refusal. **`scripts/issue-e2e.sh` already does all seven in one
script**: manual-approval policy, holder configures a confidential account, **on-chain refusal
before approval** (`Custom(24)`, `ConfidentialTransferAccountNotApproved`, sent with preflight off
so the refusal has a citable signature), issuer approves that account, confidential DvP allocation,
recipient decrypts their own leg before signing, public balances printed as zero.

So I did not build a driver. **Tell me if that reading of `issue-e2e.sh` is wrong.**

## 2. What was actually broken

`crates/confide-ct/src/swap_check.rs` — the step every surface in this repository calls "the check
that makes a confidential swap safe" — **took two arguments and compared nothing.** It decrypted the
recipient's amount out of the verified context, printed it, and printed
*"If that is not the amount you agreed, do not sign."*

All four callers ignored the result and signed: `issue-e2e.sh:115`, `swap-e2e.sh:171`,
`swap-sign.sh:42`, `swap-settle.sh:52`. `swap_look` in `scripts/lib/swap.sh` also had `2>/dev/null`
on the invocation, so had it ever failed, the reason would have been discarded.

**There were no tests over `swap_check.rs` at all**, and `docs/cwf-2026/THE-SWAP.md` said the
refusals were *"checked to refuse both ways it should."*

## 3. What I changed

1. **`swap-check` takes an optional third argument, the agreed amount**, and the comparison is the
   exit code. Over- and under-payment both fail. Without the argument it behaves as before and says
   explicitly that nothing was compared.
2. **`swap_look <keys> <ctx> [units] [decimals]`** — units and decimals rather than base units,
   because that is the pair every caller already holds for `swap_leg`, and converting at the call
   site is where a factor of 10^8 gets introduced. One helper, `swap_base_units`, now does the
   conversion for both `swap_leg` and `swap_look`; it was inline in `swap_leg` before.
3. **`2>/dev/null` removed** from the `swap-check` invocation, since the refusal arrives on stderr.
4. **Local terms pinning, and this is the part I most want attacked.** The agreed units travel
   inside the offer JSON, which is handed back and forth. A counterparty who wants to send less can
   lower the leg *and* the stated units in the same file, and a check fed from that file passes
   while looking like verification — the same shape you found on 2026-09-22. So `swap-offer.sh`
   generates an `id` (`secrets.token_hex(8)`), and `swap-offer.sh` and `swap-accept.sh` each write
   `$W/terms-<id>.json` recording what **that** party agreed to receive, **before any proof is
   built**. Steps 3 and 4 call `swap_look_pinned`, which refuses if the returned file restates the
   units or names a different mint, and falls back — **loudly, in red** — to the counterparty's own
   figure when no pin exists (offers predating the id, or a different machine).
5. **`SHORT=<units>` on `issue-e2e.sh`** — the issuer builds its leg for fewer shares than agreed,
   nothing else differs, and the check refuses before signing. If it ever passes, the script exits
   non-zero saying that is the finding rather than the demonstration.
6. **`_submission/full.md`'s test-count check** rewritten — see §6.
7. **`scripts/kamino-verdict.sh`** — unrelated, found while running the suite: its klend clone cache
   lives under `$TMPDIR`, macOS had purged `.git/` down to an empty `hooks/` and `info/`, and the
   guard was `[ ! -d "$SRC/.git" ]`. So it passed and every git call after it died with exit 128.
   **That check had been unrunnable for days and nothing said so.** Now it asks
   `git rev-parse --git-dir`. Re-run afterwards: 12/12 green, pinned lines unmoved, verdict
   unchanged.

## 4. What I could not do, stated plainly

**There is no RPC endpoint in this session.** CLAUDE.md says the public devnet endpoint rate-limits
real work, and the founder's Alchemy URL is an environment variable that is not set here. So:

- `SHORT=2000 ./scripts/issue-e2e.sh` **has never been run.** The refusal is proved against a
  synthetic context in Rust and against stubs in shell, not on devnet.
- Nothing in `swap-offer/accept/settle/sign` has been run end to end since the change. They are
  syntax-checked (`bash -n`) and their new helpers are unit-tested offline.

**Is shipping the change in that state defensible, or does it have to wait for a devnet run?** My
reading: the comparison and the refusals are deterministic and covered offline, and the risk is in
the wiring — argument order, the `read -r` field additions, `$W` scoping. Say if you think the
wiring risk is high enough to hold it.

## 5. The tests, and the holes they had

**`cargo test -p confide-ct --bin swap-check` — 10 tests** over a synthetic 3-handle validity
context. The synthetic context writes the offsets `swap_check.rs` reads; it does **not** re-derive
Token-2022's layout from the SDK, so it tests the decode and the comparison and not the layout. The
layout is established by the devnet runs in `THE-SWAP.md`. **Is that a fair boundary, or is a test
built from the reader's own constants worth less than I think?**

Deliberately broken: removing the comparison fails 3 tests
(`a_short_leg_is_refused`, `one_base_unit_short_is_refused`, `an_overpayment_is_refused_too`);
dropping the high half of the amount fails `reads_an_amount_that_needs_both_halves`.

**`./scripts/swap-pin-check.sh` — 14 assertions, no chain.** Broken five ways, each confirmed to
fail: the terms-changed refusal removed, the wrong-mint refusal removed, the pinned path consulting
the chain instead of the pin, the units validation removed (the Python-injection case you found on
09-22 reappears), the unpinned warning removed.

**It fell into two of its own holes and both are worth your attention because I only found them by
re-checking rather than by reading its output:**

- The stub recorded "did this reach the signing path?" in a **shell variable**, and every case that
  captured output with `$(...)` ran it in a subshell. The variable was always empty in the parent,
  so **two refusal tests were passing vacuously.** Now a file.
- `swap_mint_decimals` was stubbed to return 8 — the same value as the pin — so **"did it use the
  pin or ask the chain?" was unobservable.** Stubbed to 99 now, which makes the two paths distinct;
  re-breaking the pinned path fails as it should.

One guarantee I could **not** make independently observable, and I would rather say so than fake it:
whether `swap_look_pinned` passes the pinned units or the handed-back units is unobservable at that
line, because the terms-changed refusal above it forces them equal. Substituting one for the other
changes nothing. What protects it is that refusal, and removing the refusal does fail the file.

## 6. A frozen surface went red, and I changed the check rather than the document

Adding ten tests took the count from 60 to 70, and `docs-consistency.sh` required
`_submission/full.md` — **Stocklana's submitted text, edit window shut 2026-09-25 16:00 ET** — to
state today's total. That red could only ever be cleared by never writing another test.
`scripts/healthcheck.sh:239` already says a red no action can clear is a red that teaches everyone
to skip.

So the check now allows the frozen submission to **understate** — the same ruling `pasted.json`
records for the posted x-post (*"the post understates, which is the safe direction, and it stays as
posted"*) — and fails if it **overstates**, or stops stating a count. Broken three ways, all
confirmed. `README.md` (editable) went 60 → 70.

**Is that the right call, or did I just weaken a check because my own change tripped it?** That is
the reading I am least sure of, and it is exactly the shape of self-serving repair.

## 7. What I have not done

- Two of the five negative controls in the brief's §3 P0 are still missing: **wrong approval
  authority**, and **missing second signature**. `issue-e2e.sh` covers the unapproved account, and
  the public-observer-sees-zero case is printed at the end of both e2e scripts.
- The **claim ledger** (brief §3 P0 item 4) is not written.
- Week-3 coverage from `docs/27-DAYS.md` is deliberately not done; your 09-27 answer said the
  measurement apparatus is evidence infrastructure and not a co-equal deliverable.

## 8. What I am asking

1. **Where is the wiring wrong?** Specifically the `read -r` field additions in `swap-accept.sh`,
   `swap-settle.sh` and `swap-sign.sh` — I added fields to the end of each `print()` and to each
   `read -r`. An offer with no `id` prints `-` rather than an empty field, because an empty field
   would shift every value left and the acceptor would pin terms for the wrong mint. **Did I miss a
   place where that shift still happens?**
2. **Is the local pin actually sound?** The offerer pins its own `want` at offer time; the acceptor
   pins its own `want` at accept time, from the offer it inspected. Is there an ordering or a file
   the counterparty controls that I have missed?
3. **`$W` is `swap_workdir()` — `~/.config/confide/swap/<cluster>` — shared across offers.** Terms
   are keyed by offer id. Is there a collision, a stale-pin or a permissions problem there?
4. **§6: did I weaken a check to suit my own change?**
5. **§4: is shipping without a devnet run defensible?**
6. **What is the most likely error here that I have not listed?** Assume there is one.

Verify every claim above against the real files before accepting it. Several of my statements about
this repository have been wrong today in exactly the way that reads plausibly.
