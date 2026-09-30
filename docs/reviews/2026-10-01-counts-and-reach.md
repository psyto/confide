Not ready to call fully corrected. The new six-mint wording is mostly sound, but several active claims and both checks still miss material cases.

- The published page still says “On NVDAx, two accounts have asked”; the scan says one NVDAx and one AAPLx. [web/index.html](/Users/hiroyusai/src/confide/web/index.html:378)
- README still generalises the sample: “1,992 … Nobody has ever used one.” [README.md](/Users/hiroyusai/src/confide/README.md:207) The six-mint scan cannot support that.
- The page repeats the same unscoped conclusion: “a confidential account cannot receive … and none has.” [web/index.html](/Users/hiroyusai/src/confide/web/index.html:271)
- The CWF draft remains unscoped in several places, including “Of 518,744 live accounts…” and “none has”; it also says the sample “proves the feature is unused.” [cwf-form.md](/Users/hiroyusai/src/confide/_submission/cwf-form.md:23) [cwf-form.md](/Users/hiroyusai/src/confide/_submission/cwf-form.md:301)
- The ready-to-publish post has current counts but retains “Nobody has ever opened one” and “no issuer has” across all 1,992. [POST.md](/Users/hiroyusai/src/confide/docs/cwf-2026/POST.md:29) [POST.md](/Users/hiroyusai/src/confide/docs/cwf-2026/POST.md:44)

“Where we looked” is a valid correction, but “no incumbent / nothing to be late to” should be explicitly limited to an approved confidential account or on-chain user in the sampled mints—not a broader product-competition claim. ISSUANCE-RUNS is substantially better scoped, though “the swap waits on the issuer” should be conditional: it waits unless both counterparties already have approved accounts. The YouTube opening is defensible in context, but “no account in the six-mint scan is approved for confidential transfers” is clearer.

Auditor overstatements still remain outside pinned recordings:

- README and the YouTube source say “Everybody readable, or nobody,” losing both the “amount” and “while set” limits. [README.md](/Users/hiroyusai/src/confide/README.md:33) [youtube.md](/Users/hiroyusai/src/confide/_submission/youtube.md:55)
- THE-PINCER still says an auditor key “reads everything.” [THE-PINCER.md](/Users/hiroyusai/src/confide/docs/cwf-2026/THE-PINCER.md:220)
- SEIZURE says the lender-as-auditor could read every transfer “by everyone, forever,” which contradicts the before-key boundary. [SEIZURE.md](/Users/hiroyusai/src/confide/docs/SEIZURE.md:262)
- The demo’s “every transfer, or none” likewise omits both amount and time scope. [demo.html](/Users/hiroyusai/src/confide/video/demo.html:543)
- ONCHAIN still calls it a “global” key. [ONCHAIN.md](/Users/hiroyusai/src/confide/docs/ONCHAIN.md:274)

The new auditor check misses all of those: it looks for `reads everyone`, not `reads everything` or `Everybody readable`; and it does not catch “by everyone, forever” or “every transfer, or none.”

No mutable surface I found says “three have asked.” However, the frozen Stocklana submission still says three configured, as expected for a historical submitted artifact. [full.md](/Users/hiroyusai/src/confide/_submission/full.md:27) Also, the local CWF and YouTube files no longer match their recorded pasted hashes in `_submission/pasted.json`; they are drafts until the founder repastes them.

The ACCOUNT SCAN regex is not notably too loose within its short allowlist, but it is too narrow operationally:

- It excludes the CWF form, ISSUANCE-RUNS, DESIGN, ONCHAIN, and most public docs.
- It only recognizes a number immediately followed by `have`; it misses forms such as “2 accounts have configured…”.
- Digit support stops at ten when written as a word.
- It does not validate the per-mint distribution, so it missed the stale “two on NVDAx.”
- It has no scope assertion tying 518,744 to “six mints / two per issuer.”

Finally, the stated YouTube overwrite guard is not present in the checked-in generator: it still documents unsafe direct redirection, which truncates the destination before the generator’s size assertion runs. [youtube-paste.sh](/Users/hiroyusai/src/confide/scripts/youtube-paste.sh:4) The consistency script repeats that unsafe command. [docs-consistency.sh](/Users/hiroyusai/src/confide/scripts/docs-consistency.sh:191)

`git diff --check` passed. I could not obtain a meaningful full `docs-consistency.sh` result here because this read-only environment forbids its temporary files.