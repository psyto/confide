Independent adversarial review of TWO edits another agent (Claude) just made to this repository.
You are at the Confide repo root. FALSIFY; do not agree. Cite file:line. Budget your reading:
do NOT read target/, node_modules/, video/*.mp4, or web/ assets.

The edits are uncommitted. `git diff` shows both.

================================================================================
EDIT 1 — docs/cwf-2026/FOUNDER-MARKET-FIT.md, a new "### 4." section
================================================================================
That document's own rules are in its "## What not to claim" section: no prior career in RWA,
lending, custody or brokerage; no relationship with Backed, Backpack, Kamino or any curator; no
users. Its stated standard is "Nothing here claims market proximity that does not exist."

§4 lists four public repositories (psyto/aperture, openhl-solana, solinv, princeps-solana) and
states where aperture sits: consumed arm's-length at tag v0.5.1 by five crates (confide-onchain,
confide-embargo, confide-equity, confide-committee, confide-demo), 20 use sites, supplying
disclosure package types, the policy model, Token-2022 issuance calls and the verifier — and that
confide-ct, the crate running the trade the submission leads with, has NO aperture dependency and
zero use sites. It withholds "public since" dates for solinv and princeps-solana on the grounds
that only GitHub's last-updated was available, and it refuses to cite psyto/limen because it is
private.

E1a. VERIFY THE FACTS. Are the five crates, the ~20 use sites, and the claim that confide-ct has
     no aperture dependency all true? Check the manifests and the sources. Report any number that
     is wrong.
E1b. Does §4 breach "What not to claim"? Does listing repositories imply market proximity,
     industry access, or users, by placement or by tone?
E1c. Is §4 PADDING? The criterion is "does the team have the right skills and experience to
     succeed in this market." Does §4 move that, or is it a list of side projects dressed up? If
     it is padding, say so and say what should be cut.
E1d. Is anything in §4 unverifiable by a judge, or sourced to something that is not in the repo?
     In particular: is the 2026-09-12 aperture date actually supported by STATUS.md?
E1e. Does §4 contradict anything else in this repository — DESIGN.md's reuse table, STATUS.md's
     disclosure table, README's "Built on" section?

================================================================================
EDIT 2 — video/CWF-PRESENTATION.md, a dated correction prepended to the header
================================================================================
The header said "Restructured 2026-09-22, and the delivered video no longer matches it",
naming Confide_Stocklana_20260920.mp4. Claude added a dated block saying that file no longer
exists, that ./scripts/spoken-check.sh video/Confide_Stocklana_20260923.mp4 run on 2026-09-29
reports 8 of 10 scenes reading the current script at 95.7-100%, that scene 3 is at 88.6% with the
checker reporting the project's own name "never spoken anywhere in the film", and that scene 5
(57.3s-78.2s) could not be checked because the transcriber dropped it while the voice is present.
He kept the original paragraph and called it "an overstatement".

E2a. Read scripts/spoken-check.sh. Does an 8/10 result actually license the word "overstatement",
     or does a single scene not reading the current script make the original paragraph correct as
     written? Be strict.
E2b. The checker reports "never spoken anywhere in the film: confide". Claude wrote this is "a
     thing to listen to, not yet a confirmed defect" because ASR mishears proper nouns. Does the
     script's own evidence support that hedge, or is he softening a real finding? Check what the
     repo already records about this ASR's behaviour.
E2c. Is prepending a correction to a founder-voiced script document appropriate under CLAUDE.md's
     "founder しか動かせないもの", or did Claude edit something he should have left alone?

================================================================================
OUTPUT
================================================================================
Markdown, under 700 words. BLOCKER / MAJOR / MINOR with file:line and the specific wrong sentence
quoted. Then "What should be cut" as a list of exact sentences, if any. End with exactly one line:
VERDICT: KEEP AS IS   or   VERDICT: CHANGES
