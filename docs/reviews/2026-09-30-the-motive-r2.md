Not ready. The new check passes, but it still misses live motive claims and has a deletion bypass.

1. The NVDAx rewrite is mostly sound, with two limits:

- `web/usage.json` supports “NVDAx is among six scanned mints and has 0 approved confidential accounts” as of **2026-09-28**, not “today.”
- It does not by itself support “nowhere to hold it except in the clear”; that additionally relies on the Token-2022 rule that an unapproved account cannot receive/use confidential value. The conclusion is reasonable, but cite that rule or phrase it as an inference.

“Fund holding NVDAx” is conditional and fine. I found no underclaim there.

2. Yes: “nobody chose” is an overclaim. The observed bytes cannot distinguish a default/template from an explicit decision. The same is true in reverse: defaults do not prove that nobody chose them.

3. The check has substantial evasion room. These all pass today:

- “Because one auditor sees every transfer, issuers keep the field unset.”  
  Needs CAUSE to catch reason-first syntax and `since/as/therefore/explains/reflects`, not only `empty … because`.

- “Backed, Backpack, and PreStocks made the same choice separately.”  
  Needs INDEPENDENCE to recognize named issuers/configuration, not just the words `issuer`, `party`, `witness`, or `arriv`.

- “The pattern is purposeful.”  
  Needs INTENT coverage for `purposeful`, `decision`, `choice`, `preference`, `signals`, etc.

- “Peer-to-peer confidential settlement remains unavailable.”  
  Needs SECONDARY to cover the substantive claim, not only `blocks the secondary`.

- “Backed’s mints are not ours; their issuer deliberately left the slot empty.”  
  Passes because `not ours` exempts the entire sentence.

- “Kamino shows issuers deliberately chose null.”  
  Passes because mentioning Kamino exempts the entire sentence.

The exemptions are hiding places. Make exemptions structural and narrow: a specific Kamino source citation / code-context pattern, and a specific known testbed or mirror identity—not any sentence containing `Kamino`, `lender`, `mirror`, `testbed`, `not ours`, or `we control`.

Also, deletion defeats the stated frozen/retraction guarantees: [docs-consistency.sh](/Users/hiroyusai/src/confide/scripts/docs-consistency.sh:780) skips every nonexistent path before checking `frozen` or `retraction`. Deleting a frozen file or `THE-PINCER.md` passes this block.

4. Remaining live claims missed by the check:

- [README.md](/Users/hiroyusai/src/confide/README.md:302): “companies that mean to enable this…”
- [FOUNDER-MARKET-FIT.md](/Users/hiroyusai/src/confide/docs/cwf-2026/FOUNDER-MARKET-FIT.md:32): issuer incentive, “has no reason to,” and “no correct configuration.”
- [POST.md](/Users/hiroyusai/src/confide/docs/cwf-2026/POST.md:55): “not a choice any of them made.”
- [WHY-THE-SLOT-IS-EMPTY.md](/Users/hiroyusai/src/confide/docs/cwf-2026/WHY-THE-SLOT-IS-EMPTY.md:99): “Demand moved… It is the shape of the disclosure…” still asserts a cause.
- [ONCHAIN.md](/Users/hiroyusai/src/confide/docs/ONCHAIN.md:8) and [video/demo.html](/Users/hiroyusai/src/confide/video/demo.html:350): “issuers with nothing to do with each other” is an unsupported independence claim.
- [packets README](/Users/hiroyusai/src/confide/docs/packets/README.md:8) and its generator [packet.sh](/Users/hiroyusai/src/confide/scripts/packet.sh:41): “motive is undeniable” / “nobody wants broadcast.”
- The known old auditor-scope language is also still live beyond `video/demo.html`: [WHY-THE-SLOT-IS-EMPTY.md](/Users/hiroyusai/src/confide/docs/cwf-2026/WHY-THE-SLOT-IS-EMPTY.md:60) and [_submission/cwf-form.md](/Users/hiroyusai/src/confide/_submission/cwf-form.md:327). The latter also says “Every decision downstream is locally correct,” which conflicts with the default/no-decision premise.

Separate consistency defects:

- [web/index.html](/Users/hiroyusai/src/confide/web/index.html:164) says “Three have asked,” while `web/usage.json` records **2** configured accounts.
- [ISSUANCE-RUNS.md](/Users/hiroyusai/src/confide/docs/cwf-2026/ISSUANCE-RUNS.md:11) and [WHY-THE-SLOT-IS-EMPTY.md](/Users/hiroyusai/src/confide/docs/cwf-2026/WHY-THE-SLOT-IS-EMPTY.md:96) retain the stale 469,477 account total.
- [issue-e2e.sh](/Users/hiroyusai/src/confide/scripts/issue-e2e.sh:8) and [testbed-join.sh](/Users/hiroyusai/src/confide/scripts/testbed-join.sh:6) incorrectly generalize the six-mint account scan to “every one of the 1,992 real mints.”

5. Mechanical checks:

- `git diff --check` passes.
- All ten frozen artifacts match their pinned SHA-256 prefixes.
- `_submission/youtube-paste.txt` exactly matches its generator; its description is exactly 4,986 characters.
- `_submission/cwf-form.md` still has 28 fenced fields and none exceeds its stated limit.

The full `docs-consistency.sh` cannot complete in this read-only sandbox because its existing checks create temporary files; that is environmental, not a diff regression. The newly added motive block runs clean when isolated.