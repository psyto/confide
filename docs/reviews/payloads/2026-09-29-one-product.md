Independent adversarial review of the Confide repository (you are at its root). FALSIFY the
claims below; do not agree with them. Cite file:line for everything. The source is
authoritative — every assertion below was written by another agent and may be wrong.

Budget your reading. Do NOT read target/, node_modules/, video/, or web/ assets.

================================================================================
Q1 — Is this repository selling ONE product or TWO?
================================================================================
Claim: DESIGN.md sells **scheduled, unretractable, scoped disclosure** (§1, §2, §4: Token-2022
offers only one disclosure model — one global auditor key = everyone-forever, or null =
nobody-ever — so Confide builds disclosure scoped by recipient, granularity and SCHEDULE).
README.md, since 2026-09-24, sells **private block trades / confidential atomic DvP**.
Claim: these are different products with different buyers.

Q1a. Split or not? Decide from the CODE. Map each of confide-embargo, confide-committee,
     confide-equity, confide-ct, confide-onchain, programs/confide-seizure to which claim it
     serves.
Q1b. Which claim is more completely IMPLEMENTED and RUNNABLE end to end TODAY? Name the exact
     scripts in scripts/ that run each, and name what is design-only prose with no code behind it.
Q1c. If it is one product, give the one sentence that contains both without lying.

================================================================================
Q2 — Is "at T the holder is not an input, so the disclosure cannot be stopped" TRUE?
================================================================================
DESIGN.md §4 describes: seal the position at t0, threshold-split the seal key k-of-n across
"agents", anchor a content-blind commitment plus T on-chain, publish the ciphertext openly; at
T any k agents publish shares and anyone reconstructs and checks against the t0 commitment.
Labelled I2 ("unstoppable") and I3 ("no revision was possible in between").

Another agent wants to make this the CENTREPIECE of the competition demo. Before that happens:

Q2a. WHO are the k-of-n agents in the IMPLEMENTATION? If the holder selects, funds, runs, or
     can collude with them, I2 is false and this is a trusted committee — the very thing
     DESIGN.md §2 rejects when it dismisses custodians. Quote confide-committee and
     confide-embargo.
Q2b. Is I3 enforced ON-CHAIN, and by what code? Or is it a property of an off-chain document?
Q2c. What makes a holder seal at t0 at all? If sealing is opt-in and unsealing is impossible,
     what exactly does an LP get that a promise does not give them? Answer concretely.
Q2d. Does the demo sequence "holder refuses to cooperate at T, disclosure happens anyway,
     output matches the t0 commitment" RUN TODAY with existing scripts? If not, name the
     precise gap — file by file.

================================================================================
OUTPUT
================================================================================
Markdown, under 900 words. Findings as BLOCKER / MAJOR / MINOR with file:line and a concrete
failing sequence or a named missing artifact. Then "What is actually implemented" as a short
table. Then "What is still unmeasured" as a list. End with exactly one line:
VERDICT: ONE PRODUCT — <which>   or   VERDICT: TWO PRODUCTS
