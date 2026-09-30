# The population — what 1,992 is, and what it is not

**Written 2026-09-30, because the sentence this repository says most often was false.** Reviewed the
same day: [`../reviews/2026-09-30-the-population.md`](../reviews/2026-09-30-the-population.md).
Codex found four live surfaces the first pass and its own new check both walked past, including the
published site and the generator behind fourteen tracked packets.

The scan behind the number reads `web/mints.json`, and `web/mints.json` is built by
[`scripts/refresh-mints.sh`](../../scripts/refresh-mints.sh) from **three issuers' own asset APIs**.
It is a product catalogue, not a census. The scan is exhaustive over the catalogue and says nothing
about what is outside it.

**Thirty-eight files said some form of it, in forty-five places** — counted at `HEAD` with the
check's own final patterns, not counting the review records that were pointing it out. **Thirty-one
are repaired here and seven are left standing on purpose.** The first count of this was twenty-four,
made with a narrower pattern that missed the published site, the README headline, the scan's own
printed output line and the generator behind fourteen tracked packets. **The count had inherited the
blind spot it was measuring.**

## The wording, and there are exactly two forms

Codex's finding: the first pass produced three paraphrases — *"the three issuer catalogues
publish"*, *"these three issuers list"*, *"in `web/mints.json`"* — which is the same drift starting
again. So: **two forms, and any third is the drift.**

| where | the form |
|---|---|
| code, headers, generated artifacts | **`every mint in web/mints.json`** — names the file a reader can open |
| prose a stranger reads | **`from three issuers' catalogues`** — no verb, because *publish* and *list* are present tense and a September snapshot cannot establish a catalogue's state today |

**"Not a sample" is kept only in the bounded form** — *"every entry in `web/mints.json`, not a
sample of that file."* Codex is right that standing alone it invites exactly the wrong reading:
*not a sample* sounds like *not a subset*, and it is a subset. The bare phrase is gone.

## What the number is

| | |
|---|---|
| **1,992** | the entries in `web/mints.json` — Backed 828, Backpack 1,156, PreStocks 8 |
| **committed** | **2026-09-19**, from `git log -1 --format=%cs -- web/mints.json`. **Not "retrieved"** — the generator recorded no time, so the commit date is the closest honest word and it does not prove when the APIs answered |
| **read** | one mint account at a time, live from mainnet, by [`scripts/slot-scan.sh`](../../scripts/slot-scan.sh) — `web/slots.json` carries the date of that run, 2026-09-21 |
| **exhaustive over** | that file. The check fails if a single entry disagrees |
| **not** | a census of Solana. The list is what three APIs return |

`refresh-mints.sh` now writes `web/mints-source.json` beside it — `generated_utc`, the three source
URLs, and a sha256 of the exact bytes — so the next refresh dates itself instead of borrowing a date
from git. Per-issuer counts are **not** copied into it; they are derivable from `mints.json`.

## The catalogue has already moved, and that is not repaired here

`DRY=1 ./scripts/refresh-mints.sh` on 2026-09-30 returns **2,193** — Backed 1,025, Backpack 1,160,
PreStocks 8. **+201 since the committed list.**

It is not refreshed, and the reason is the point of this document: `slot-scan.sh` has never read the
201 new mints. Refreshing alone would restate the headline count in forty surfaces while the
measurement behind it covered 1,992 — **swapping a scoped true number for a wider unmeasured one**,
which is the failure this document exists to record. Re-measuring wants the founder's private RPC
endpoint; the public one rate-limits at this volume. Until then the sayable number is 1,992,
measured, with its date.

## How it broke

**Codex said this on 2026-09-15**, in
[`../reviews/2026-09-15-codex-docs-quality.md`](../reviews/2026-09-15-codex-docs-quality.md):

> `slot-scan.sh` checks every mint in `web/mints.json`; it does not discover the universe. […] That
> supports: "all 1,869 issuer-listed Solana equity mints returned by these two APIs at refresh
> time." It does not support: "every tokenized stock on Solana."

What happened next is the failure worth recording. A scope paragraph was added to
[`../ONCHAIN.md`](../ONCHAIN.md) — *"It is not a census of every equity token on Solana"* — and left
sitting **directly underneath a headline that still said it was**. `README.md` had the same shape: a
scoped italic note three lines below an unscoped bold headline. The correction went into two
paragraphs and the claim stayed in twenty-six other places, including the script header and the
scan's own printed output line, which every other surface was quoting. **A caveat under a false
headline is not a correction**, and nothing checked the headline, so the claim outlived its own
retraction by fifteen days.

A wider scan on 2026-09-27 found confidential-transfer mints that are not in `web/mints.json`. Those
numbers have no committed parser, snapshot or run output, so **they are not cited here and no count
or issuer from them is claimed.** Nothing in that scan is needed anyway: the list is what three APIs
return, which is what makes it not a census.

## What is frozen and still says the old thing

These are **not edited**. Each is a record of what actually went out, and rewriting it would destroy
the only copy of what was said.

| surface | why it cannot be repaired |
|---|---|
| [`../../_submission/full.md`](../../_submission/full.md) | Stocklana's submitted text. **The edit window closed 2026-09-25 16:00 ET.** Changing the file would make `pasted.json` disagree with a form nobody can re-open |
| [`x-post.txt`](x-post.txt) | posted. `pasted.json` marks it `immutable`. Both **templates** are corrected, and `x-post.sh`'s usage line — which used to tell you to redirect output over this file — no longer does |
| [`../../video/CWF-PRESENTATION.md`](../../video/CWF-PRESENTATION.md) scene 2, `video/captions-20260923.srt`, `video/segments-presentation/{LINES.md,manifest.json}` | the **narration and captions of the published video** (`du0Twt_c9wQ`). `spoken-check.sh` compares the delivered audio to these lines, so editing them reports a fault in a file that is faithful. **The caption file was nearly missed**: the check skipped `.srt` by suffix on its first version, so a published surface carrying the claim was invisible rather than accounted for |
| [`../../_submission/short-alternatives.txt`](../../_submission/short-alternatives.txt) | keeps every retired and rejected draft line verbatim, including one that overclaims |
| [`../../video/checkin-2.html`](../../video/checkin-2.html) | **quotes the false sentence on purpose**, as the thing being corrected |

**The video still says it to every judge who watches it.** Codex's answer on what to do: not to make
`docs-consistency.sh` red to force a re-record, but to make the correction **reachable from where a
judge lands** — the README's top video link and the site — and to fix the editable YouTube
description. Those are done. **Pinning a correction comment under the video is the founder's hand**,
and so is the re-record; CWF needs two new videos regardless
([`../../STATUS.md`](../../STATUS.md) 0m).

## The check

`docs-consistency.sh`, section `THE POPULATION`. It matches three shapes, because the first version
knew only one:

1. `every | all | the whole … tokenized stock … on Solana`
2. `<count> tokenized stocks on Solana` — **a number is a quantifier too.** Anchored on the count
   sitting next to the noun, so a date earlier in the line cannot stand in for one
3. `whole asset class` — the packet generator's phrasing, which named no population at all

Files come from `git ls-files --cached --others --exclude-standard`: tracked **and
untracked-but-not-ignored**, so a new document cannot arrive carrying the claim and stay invisible
until someone commits it. `.srt` is scanned. `docs/reviews/` is not — that is what a reviewer said
and what they were sent.

The allowlist is the table above, as **path → reason**, and **a stale entry fails too**: if an
allowlisted file stops carrying the claim, the check says the reason has expired. An allowlist that
grows silently is how the first correction was lost.

It fell into two of its own holes, both found by counting rather than by trusting its output: it
matched **its own explanatory comment**, and it **skipped `.srt` by suffix**. `docs-consistency.sh`
is now the one entry on the allowlist that is there by necessity — a regex cannot avoid containing
what it matches — and the stale-entry rule turns that exemption into an assertion that the patterns
are still present.
