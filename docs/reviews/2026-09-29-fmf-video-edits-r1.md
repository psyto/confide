# Codex adversarial review, 2026-09-29 — two edits by Claude to FOUNDER-MARKET-FIT and CWF-PRESENTATION

Run read-only against this repository. Payload: `payloads/2026-09-29-fmf-video-edits.md`.

## What was done in response, so a later reader does not have to reconstruct it

**All three MAJORs were verified against the source and accepted in full.**

| finding | response |
|---|---|
| "Confide is not built on aperture" is false — `README.md:627`, `DESIGN.md:206`, `STATUS.md:20` all call `aperture-core` a pre-existing Confide component | **The whole of §4 was deleted** and the amended credibility answer reverted. `FOUNDER-MARKET-FIT.md` is back to its pre-edit state, byte for byte |
| "overstatement" is not licensed — `spoken-check.sh:124-141` exits nonzero when any readable scene fails, and one does | The word was removed. The header now reads *"The paragraph below still stands; only the file it names is stale"* |
| "scene 3 is not reading the current script" cannot be established — `scripts/lib/spoken.py:11-14` records that this ASR hears *Confide* as **confined** | Replaced with an unresolved finding that cites **both** `spoken.py:11-14` (the mishearing) and `:16-19` (*"an absent distinctive word still means something"*), which point opposite ways |

**On "§4 is résumé padding" (MINOR, and correct):** once the rows Codex listed were cut, the only
surviving content was a single measurement — that `confide-ct` has no `aperture` dependency. That
is a disclosure fact, not a founder fact, so it was moved to `README.md`'s reuse table instead of
being kept as a gutted section.

---

## BLOCKER

None.

## MAJOR

- [FOUNDER-MARKET-FIT.md:105](docs/cwf-2026/FOUNDER-MARKET-FIT.md:105): “**not** *‘Confide is built on it’*. The second would be found false by anyone reading the manifests.” This is false/misleading. Five direct manifests depend on `aperture-core`, and the repository’s own reuse tables call it a pre-existing Confide component: [DESIGN.md:206](DESIGN.md:206), [README.md:627](README.md:627), [STATUS.md:20](STATUS.md:20). “It does not underpin the settlement wedge” is supportable; “Confide is not built on it” is not.

- [CWF-PRESENTATION.md:8](video/CWF-PRESENTATION.md:8): “The paragraph below … is now an overstatement.” The checker does not license this. It exits nonzero when any readable scene fails ([spoken-check.sh:124](scripts/spoken-check.sh:124)-[spoken-check.sh:141](scripts/spoken-check.sh:141)); it reports one failing scene and one unreadable scene. Thus the old claim that the delivered video does not match the script has not been falsified—only its reference to the deleted 09-20 file is stale.

- [CWF-PRESENTATION.md:15](video/CWF-PRESENTATION.md:15): “**scene 3 is not reading the current script**.” The tool cannot establish that. Its own shared logic records that the ASR hears “Confide” as “confined” and that the 88.6% scene is plainly present ([spoken.py:11](scripts/lib/spoken.py:11)-[spoken.py:19](scripts/lib/spoken.py:19), [spoken.py:91](scripts/lib/spoken.py:91)-[spoken.py:94](scripts/lib/spoken.py:94)). The subsequent hedge is correct; the preceding assertion is not.

## MINOR

- The five-crate count, 20 `aperture_core::` source-use lines, and zero `confide-ct` uses/dependency are correct. `confide-ct`’s dependency list contains no aperture entry ([Cargo.toml:68](crates/confide-ct/Cargo.toml:68)); the other five manifests do.

- §4 does not literally claim users, relationships, or a prior industry career. But the unrelated repository table is resume padding: it establishes general Solana work, not fit for this tokenized-equity/lending market. “Prime-broker sandbox” especially risks the brokerage implication the document says to avoid.

- The 2026-09-12 aperture date is supported by the repository’s own assertion ([STATUS.md:54](STATUS.md:54)-[STATUS.md:57](STATUS.md:57)), not independent evidence. The existence, public status, and descriptions of all four external repositories are otherwise outside this repo and uncited.

- The ASR hedge is warranted, not softening: the repo explicitly documents “Salana” and “confined” errors ([fix-captions.sh:7](scripts/fix-captions.sh:7)-[fix-captions.sh:10](scripts/fix-captions.sh:10), [fix-captions.sh:34](scripts/fix-captions.sh:34)-[fix-captions.sh:39](scripts/fix-captions.sh:39)).

- Editing the Markdown script is not founder-only. CLAUDE restricts audio generation and posting, not document corrections ([CLAUDE.md:58](CLAUDE.md:58)-[CLAUDE.md:60](CLAUDE.md:60)).

## What should be cut

- “The Solana work predates this contest, is public, and is dated”
- “The criterion asks whether the team has *‘the right skills and experience to succeed in this market’*; §1–§3 answer it only from inside this repository, which is the weaker half of the question.”
- The `openhl-solana`, `solinv`, and `princeps-solana` table rows.
- “No ‘public since’ date is given for `solinv` or `princeps-solana`…”
- “`psyto/limen` is **private** and is therefore not cited at all…”

VERDICT: CHANGES