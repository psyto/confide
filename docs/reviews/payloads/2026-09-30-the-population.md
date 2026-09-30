# Review request — narrowing the population claim, 2026-09-30

You reviewed this repository on 2026-09-15 and on 2026-09-27. Both times you said the same thing
about one sentence. This is the attempt to actually fix it. **Your 09-15 finding was acted on badly
and I want to know whether today's version is any better, or whether it repeats the shape.**

Everything below is in the working tree, uncommitted. `git diff` shows it all.

---

## 1. What you said, twice

**2026-09-15**, `docs/reviews/2026-09-15-codex-docs-quality.md:27-31`:

> **"Every tokenized stock on Solana" is not established.** `slot-scan.sh` checks every mint in
> `web/mints.json`; it does not discover the universe. `refresh-mints.sh` builds that file from two
> issuer APIs only […] That supports: "all 1,869 issuer-listed Solana equity mints returned by these
> two APIs at refresh time." It does not support: "every tokenized stock on Solana."

**2026-09-27**, `docs/reviews/2026-09-27-the-direction.md`, answer 3: *"Narrow now. […] Replace
universal wording with: 'the 1,992 mints in `web/mints.json`, obtained from three issuer
catalogues,' dated to the retrieval."*

**What happened in between, and this is the part I want judged.** After 09-15 a scope paragraph was
added to `docs/ONCHAIN.md` — *"It is not a census of every equity token on Solana"* — and it was
placed **three lines below a headline that still said it was**. The headline survived. So did the
same sentence in twenty-three other files, including `scripts/slot-scan.sh:3`, which every other
surface was citing as the measurement. Nothing compared the headline to the caveat under it. The
claim outlived its own retraction by fifteen days.

## 2. What the measurement actually supports

- `web/mints.json` — 1,992 entries, built by `scripts/refresh-mints.sh` from three issuers' own
  asset APIs (Backed/xStocks 828, Backpack 1,156, PreStocks 8).
- Last written **2026-09-19**. That date is derived from `git log -1 --format=%cs -- web/mints.json`,
  **not recorded in the file** — the file has no provenance or retrieval timestamp of its own. I did
  not add one. **Tell me if that is a mistake.**
- `scripts/slot-scan.sh` reads each of those 1,992 mint accounts live from mainnet and writes
  `web/slots.json` (`generated_utc` 2026-09-21).
- On 2026-09-27 a wider scan found confidential-transfer mints **not** in `web/mints.json`,
  including a fourth issuer. You ruled those numbers non-evidence (no committed parser, snapshot or
  run output). **I have not quoted them anywhere in today's change.** They appear in
  `docs/cwf-2026/THE-POPULATION.md` only as "the catalogue is not the universe", with no figures.

## 3. What I counted

Derived, not estimated — a regex over `git ls-files` at `HEAD`, excluding `docs/reviews/`:

```
HEAD: 24 files, 29 occurrences
```

- **16 files repaired.**
- **8 left standing on purpose:** `STATUS.md` (records the defect), `_submission/full.md`,
  `docs/cwf-2026/x-post.txt`, `video/CWF-PRESENTATION.md`, `video/captions-20260923.srt`,
  `video/segments-presentation/{LINES.md,manifest.json}`, `video/checkin-2.html`.

## 4. The wording I chose

| was | is |
|---|---|
| every tokenized-equity mint **on Solana** | every tokenized-equity mint **the three issuer catalogues publish** / **in `web/mints.json`** |
| Every tokenized stock **on Solana** ships confidential balances | Every tokenized stock **these three issuers list** ships confidential balances |
| `slot-scan.sh` header: *EVERY tokenized-equity mint on Solana, across both issuers, not a sample* | *every tokenized-equity mint in web/mints.json — every mint three issuer catalogues publish, not a sample of them* |

**I kept "not a sample" and I want that challenged.** My reasoning: it is a separate and still-true
claim — every mint in the list was read, one at a time, and the check fails if one disagrees. But a
reader may hear "not a sample" as "not a subset", which is exactly the wrong reading.

One new document holds the reasoning: `docs/cwf-2026/THE-POPULATION.md`. Nothing else restates it.

## 5. Why the frozen four are not edited

This is a judgment call and it may be wrong.

- `_submission/full.md` — Stocklana's submitted text. **Edit window closed 2026-09-25 16:00 ET.**
  `_submission/pasted.json` records its sha256 as pasted; editing it makes the repository's own
  check red against a form nobody can re-open. Judging runs to 10-02 and commits reach those judges
  without a re-paste. You said on 09-27: *"Frozen Stocklana should receive a visible correction note
  in the current repo; it cannot be silently repaired."* **The note I wrote is in
  `THE-POPULATION.md`, not next to `full.md`. Is that sufficient, or does the correction have to be
  reachable from where a Stocklana judge would land, i.e. `README.md`?**
- `docs/cwf-2026/x-post.txt` — posted; `pasted.json` marks it `immutable`. **I corrected the two
  `.tmpl` files it is generated from**, so the template and the frozen record now disagree by
  design. Is that divergence acceptable, or does `x-post.sh` now silently produce a post that
  contradicts the published one in a way that matters?
- `video/CWF-PRESENTATION.md` scene 2, `video/captions-20260923.srt`,
  `video/segments-presentation/{LINES.md,manifest.json}` — the narration and captions of the
  published video `du0Twt_c9wQ`. `scripts/spoken-check.sh` compares the delivered audio to these
  lines; editing them reports a fault in a file that is faithful to what was said. **So the video
  says a false sentence to every judge who watches it, and I have left it saying that.** CWF needs
  two new videos anyway (≤2 min pitch, ≤3 min demo, neither exists). **Is leaving it defensible for
  the twelve days to 10-12, or is the right move to make `docs-consistency.sh` red now so the
  re-record is forced?**

## 6. The check I added

`scripts/docs-consistency.sh`, section `THE POPULATION`. Design decisions:

1. File list from `git ls-files --cached --others --exclude-standard` — **tracked and
   untracked-but-not-ignored** — so a new document cannot arrive carrying the claim and be invisible
   until someone commits it.
2. The allowlist maps **path → reason**, not a bare path or a directory glob.
3. **A stale allowlist entry fails too**: if an allowlisted file stops carrying the claim (re-cut,
   re-pasted), the check reports that the entry has expired.
4. `docs/reviews/` is skipped entirely — what a reviewer said and what they were sent.

**It fell into two of its own holes and I am reporting both because they are the interesting part:**

- **Its own explanatory comment matched its own regex.** The first run failed on
  `scripts/docs-consistency.sh` itself. I rewrote the comment rather than exempting the file,
  because an exemption would have been the same self-blinding.
- **It skipped `.srt` by file extension**, so `video/captions-20260923.srt` — the caption track
  actually uploaded to YouTube — carried the claim and **the check could not see it**. It surfaced
  only when I counted the 24 files by hand-written script rather than trusting the check's own
  output. `.srt` is now scanned and the file is allowlisted with its reason.

Broken on purpose, four ways, each confirmed to fail and then pass again: re-introduce it in a live
file; delete it from an allowlisted file; put it in a brand-new untracked file; change the line in
the delivered caption track.

## 7. Collateral change

`_submission/youtube.md` description went 4991 → 4982 characters, so the hand-written
`## Description — 4991` heading was updated and `_submission/youtube-paste.txt` was **regenerated**
with `./scripts/youtube-paste.sh`. My first attempt hand-edited both, which is the duplication this
repository forbids; that was reverted. `youtube-description` was already red against `pasted.json`
before today, so no green check was broken to do this.

`web/slots.json`'s `note` field was hand-edited to match the string `slot-scan.sh` now emits,
because re-running the scan needs a private RPC endpoint. **I verified the two strings are byte
identical.** The rest of `slots.json` is untouched.

## 8. What I am asking

1. **Does today's change repeat the 09-15 failure in a new shape?** The specific worry: I put the
   reasoning in one new document and corrected the surfaces, but the surfaces now each carry their
   own paraphrase — "the three issuer catalogues publish", "these three issuers list", "in
   `web/mints.json`". Three phrasings, not one. Is that the same drift starting again?
2. **Is "not a sample" defensible, or does it have to go?**
3. **Is the frozen-four judgment right**, especially the published video?
4. **Does the missing retrieval timestamp in `web/mints.json` undermine the dated claim?** The date
   comes from git, not from the file. Nothing enforces that the file was written by the script.
5. **What is the most likely error in this change that I have not listed?** Assume there is one.
6. Anything in `docs/cwf-2026/THE-POPULATION.md` that overstates, understates, or invents.

Verify every claim above against the real files before accepting it. Several of my previous
statements about this repository were wrong in exactly the way that reads plausibly.
