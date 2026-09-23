# Codex on the visual upgrade — 2026-09-23

**Request:** [`payloads/2026-09-23-the-visual-upgrade.md`](payloads/2026-09-23-the-visual-upgrade.md).
Codex built `video/presentation-visual-upgrade.mp4`; this is Codex reviewing its own diff against my
five objections, with my interest in the outcome declared in the request.

**All five confirmed.** One correction to me: **scene 9 was never stdout** — its old `missing`
renderer was hand-authored text too, so "five scenes stopped being command output" is four. The
invented-pool finding is unaffected: the old scene had *no* numbers and the new one has three.

**One Codex found and I did not:** the retained per-scene clips total **179.967 s** against the
script's 170. Each clip carries about a second of recorder tail, which passes the per-clip 2 s drift
check and accumulates across ten. Verified: 16.0 / 19.97 / 16.0 / 16.0 / 20.0 / 22.0 / 15.0 / 13.0 /
21.0 / 21.0. So the recorder as it stands would write its file and then fail its own aggregate
check — and the delivered 170.1 s file **cannot have come from those clips**. Sampled the delivered
file: its scene 1 ends at 15 s, the clip on disk is 16 s. The cut on the founder's disk is not
reproducible from the artifacts on the founder's disk.

**And one neither of us had, which came from measuring the file instead of probing it.** Codex wrote
that "both final MP4s probe cleanly". They do. But mean frame luminance at each clip boundary:

| | 15.0 | 34.0 | 49.0 | 64.0 | 83.0 | 104.0 | 118.0 | 130.1 | 150.1 |
|---|---|---|---|---|---|---|---|---|---|
| **visual-upgrade** | **255** | **255** | 12 | **255** | **255** | 12 | **255** | 9 | **255** |
| continuous render | 7 | 7 | 7 | 7 | 7 | 7 | 7 | 7 | 7 |

**Seven pure-white frames**, against a film whose background sits at 12. Six of the nine scene cuts
flash white. The per-scene recorder starts each capture before the page has painted, and `concat`
keeps the frame. The continuous recording has none. `ffprobe` cannot see this; it is not a container
property. **Look at the frames.**

---

Your concerns are materially right. The visual direction should stay; the current delivery path and evidence framing should not.

| Finding | Verdict |
|---|---|
| 1. Invented AMM numbers | Confirmed — blocker. [The scene](file:///Users/hiroyusai/src/confide/video/demo.html:498) presents 1,000,000 / 50,000 / 950,000 as factual pool state, without a source or illustrative label. I would not retain realistic invented figures. Use `reserve R → R − q` and label it “Illustrative arithmetic — not an observed pool,” while retaining the SEC-backed publication-condition source. |
| 2. Scene 1 reveal is gone | Confirmed. The public card appears at about 0.9 s, the private card at about 1.3 s, and both finish their fade by roughly 1.8 s. At 3 s, the reveal is long over; the old second-pane switch was after six seconds. The current headline also closely paraphrases the opening narration, creating the “voice reads screen” shape you identified. |
| 3. Loss of stdout evidence | Partly confirmed. Scenes 1, 2, 8, and 10 did replace `slice(stdout, …)` with cards. Scene 9 did not: its prior `missing` renderer was already hand-authored text, not stdout. Your larger point stands: scene 8’s “20,000-share allocation” is now an unguarded literal, and the important `2 configured` result is visually demoted. A compact, verbatim evidence strip under the cards would improve credibility without reverting to terminal-pane composition. |
| 4. Pipeline disconnect / duplicate renderer | Confirmed. The recorder writes [`presentation-improved.mp4`](/Users/hiroyusai/src/confide/video/record-presentation.js:27), while [`split.sh`](/Users/hiroyusai/src/confide/video/split.sh:23) and [`docs-consistency.sh`](/Users/hiroyusai/src/confide/scripts/docs-consistency.sh:530) use `presentation.mp4`; the delivered file is a third name. The standalone renderer duplicates all scene data and bypasses every live guard and `secMust`. Its header calls it “validated,” but it is not. `.presentation-render/` is also entirely unignored and untracked. I see no evidence it is temporary scaffolding; its implementation and header present it as a supported workflow. |
| 5. Claimed Chromium/H.264 failure | Confirmed as an evidence problem. I found no failing artifact or committed history supporting the statement. The current retained raw and encoded scene files, plus both final MP4s, probe cleanly. The clean 12:39 `presentation.mp4` is 171.07 s; the visual-upgrade file is 170.10 s. Keep per-scene recovery, but change the comment to describe it as an isolation/recovery design, not an established host property. |

One additional release blocker is more urgent than any of the five: the retained per-scene encoded clips total **179.967 s**, versus the script’s **170 s** and the visual-upgrade file’s **170.100 s**. Each scene is allowed up to two seconds of drift, so the roughly one-second recorder tail per clip passes individually and accumulates across ten clips. The current recorder would write `presentation-improved.mp4`, then fail its final aggregate drift check, and never write a new manifest. The 170.10 s visual-upgrade file therefore cannot have been assembled from the currently retained clips.

Other misses in the current diff:

- Scene 8 no longer verifies that the shown refusal, approval transition, or 20,000 amount is present. The old `slice(issued, …)` inherently guarded those lines; `issued` is now run but unused.
- Scene 10’s “compares the two values byte for byte” is also an unguarded display claim. Its remaining guard only establishes that the testbed is still published.
- The introductory comment in [`record-presentation.js`](/Users/hiroyusai/src/confide/video/record-presentation.js:12) still says every pane is guarded stdout; that is no longer true.
- [`CWF-PRESENTATION.md`](/Users/hiroyusai/src/confide/video/CWF-PRESENTATION.md:93) still specifies terminal evidence for scenes 1, 2, 8, and 10. The renderer/script mismatch is not checked.
- Both overlap guards are conceptually good, but they fire after the final MP4 has already been promoted. They prevent manifest publication, not production of a misleading “final” file.

On `4586faa`:

- Keep the wordmark. It gives an early-exiting or muted viewer the identity and proposition, and `body.hero` correctly suppresses it when the full title appears.
- Keep `CONFIDE_OVERLAP`, but stage the output as temporary until that check passes.
- Keep “Look it up. The chain will tell you this account is empty.” on screen. It is a useful viewer instruction, not narration duplication. The current visual diff replaces it with wording that does duplicate the voice; restore the original intent.
- The `10 + 5 s` scene-1 structure is sound only if the private number remains withheld until the spoken reveal.

Repair order:

1. Before the founder records audio: remove the pseudo-measured AMM figures; restore the timed scene-1 reveal; add direct guards for scene 8 and scene 10 claims; make scene 2’s `2 configured` legible; add concise stdout evidence strips.
2. Make one canonical scene definition and one guarded renderer. Delete the standalone renderer unless it is refactored to call the guarded path rather than duplicate it.
3. Fix per-scene timing by trimming/re-encoding each clip to the page-measured duration, then verify both every clip and their concatenation equal the 170-second contract. Use one canonical output name: `video/presentation.mp4`.
4. Only promote the final MP4 and manifest after all guards, overlap checks, duration checks, splitting, and docs consistency pass. Ignore and clean `.presentation-render/`.
5. Hand the locked script and silent verified cut to the founder for audio immediately; then do the final automated assembly and validation.

I ran syntax checks on both changed JS files and `git diff --check`; both pass.
