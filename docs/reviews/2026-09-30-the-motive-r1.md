## Verdict

This is not ready to call complete: the new check would pass several current, unallowlisted motive claims.

- [web/index.html](/Users/hiroyusai/src/confide/web/index.html:240) still says every issuer leaves the slot empty “because” the native key is unsuitable.
- [README.md](/Users/hiroyusai/src/confide/README.md:244) still gives the old causal story; [line 589](/Users/hiroyusai/src/confide/README.md:589) explicitly says why the field is null.
- [ONCHAIN.md](/Users/hiroyusai/src/confide/docs/ONCHAIN.md:189) says “That is why the live mints leave it null,” contradicting its corrected section at line 272.
- [DESIGN.md](/Users/hiroyusai/src/confide/DESIGN.md:25) and [line 287](/Users/hiroyusai/src/confide/DESIGN.md:287), plus [confide-equity’s doc comment](/Users/hiroyusai/src/confide/crates/confide-equity/src/lib.rs:22), retain the whole retracted inference.
- [STORY.md](/Users/hiroyusai/src/confide/docs/cwf-2026/STORY.md:56) says the issuers “arrived there independently”; [COMPOSITION.md](/Users/hiroyusai/src/confide/docs/cwf-2026/COMPOSITION.md:104) calls them “independent witness[es]”; [WHAT-THE-WEEK-CHANGED.md](/Users/hiroyusai/src/confide/docs/cwf-2026/WHAT-THE-WEEK-CHANGED.md:101) says the extension inventory makes abstention deliberate.

The existing regex misses all of those exact phrasings.

## Answers

1. No under-correction on the central fact. Keep the strong, narrow claim: “Token-2022 has a mint-wide native transfer auditor; it has no native per-recipient disclosure setting.” The caveat does not hedge that fact.

   Do tighten “decrypts everything / every holder / anyone” to “can decrypt confidential transfer amounts” unless the precise broader claim is demonstrated. The repository itself distinguishes a transfer-amount auditor from a master balance-disclosure key.

2. Yes: “Why nobody has built it” now overclaims. The scan establishes a configuration and a missing native capability, not why nobody built anything. Rename it “The measured configuration” or “What Token-2022 does not natively provide.” The frozen `_submission/full.md` can retain its historical heading only as an explicitly frozen artifact.

3. “Configured with more than defaults somewhere” is safer than attributing intent to issuers, but it is still an unnecessary inference and vague provenance claim. Replace it with the directly measured fact:

   “All 1,992 mints contain these control extensions. That does not show who chose their values, whether a template supplied them, or whether anyone considered the auditor field.”

   If you want to claim specific non-default values, validate and name those values rather than inferring from extension presence.

4. `FOUNDER-MARKET-FIT.md` is not listed by `pasted.sh` and I found no evidence it is a submitted/published artifact, so do not freeze it. `_submission/cwf-form.md` is a pasted-field candidate and correctly needs repasting after this edit.

   The published-video allowlist is reasonable as a record, but it does not make the claim acceptable to a new CWF audience.

5. The check has good paragraph and SRT handling, but its negative design is too narrow.

   - “Arrived there independently,” “independent witnesses,” “abstention deliberate,” and “the reason the field stays null” evade it.
   - Any paragraph mentioning “Kamino,” “lender,” or “instruction” suppresses an issuer-side “not an oversight” claim.
   - Removing all quoted text lets a new unsupported claim hide inside quotation marks.
   - The expiry rule proves only that some pattern remains in an allowlisted file, not that the frozen artifact is unchanged. Use a SHA-256/content fingerprint for frozen artifacts.
   - Use `git ls-files -z` rather than whitespace splitting for robustness.

   Prefer a small set of explicit semantic bans plus regression fixtures for the missed phrases above. Treat “Kamino correct underwriting” as a separately scoped claim, not as a blanket exclusion.

6. Yes—recommend re-recording the CWF clause before 10-12. It is a central evidentiary statement, was already used to support a false attribution, and judges will hear it. If re-recording is impractical, add a clear correction before the clause and on the presentation landing surface; an allowlist is not a correction for viewers.

I could not run the complete consistency script successfully because this read-only environment prevents its temporary-file writes; the reported script failures were sandbox effects, not repository test results.