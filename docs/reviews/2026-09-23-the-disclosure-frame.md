# Codex on the disclosure frame — 2026-09-23

Request: [`payloads/2026-09-23-the-disclosure-frame.md`](payloads/2026-09-23-the-disclosure-frame.md).
Asked because the founder wanted to take the week's findings into the CWF plan, and because the
first version of that plan — mine — pulled `confide-embargo` back into a pitch that GTM.md had
deliberately kept it out of. I caught that one myself and withdrew it before sending.

**Verdict: freeze Stocklana except for factual corrections; reject the CWF frame as specified.**

## What was verified against the real files before any of it was acted on

| finding | checked | verdict |
|---|---|---|
| **The two recorders refuse to render** with `total_confidential_accounts = 2` | `video/record-checkin.js` threw on `!== 0`; `record-presentation.js`'s regex wanted `.*0.* configured` | **right, and a release blocker** — the founder could not have recorded check-in 2 on 09-25 |
| **"forever" is wrong** | `crates/confide-ct/src/set_auditor.rs` calls `update_mint` | **right.** The key is replaceable; what is permanent is what it already read |
| **"nobody can prove anything" is contradicted by this repository** | `prove-collateral.sh` proves a floor with the slot null | **right** |
| **`prove-collateral.sh` is simulation** | line 40: `simulateTransaction` with `"sigVerify": false` | **right.** The live program executes and the proof verifies; nothing lands |
| **`set-auditor.sh` installs a MINT-WIDE auditor** | it is `update_mint` on the mint | **right, and it undoes the frame** — that script demonstrates the thing being replaced |
| **The scan is six mints, not 1,992** | `web/usage.json` has 6 entries; `full.md` said "469,477 of them" after "all 1,992" | **right, and it was in a submitted field** |

**Nothing in the review was found to be wrong.** That is not the usual outcome and is worth saying.

## What was changed because of it

- **Both recorders now guard `total_approved_accounts`**, not the configured count — the claim every
  current script makes is that nobody is *through* the gate. Broken on purpose: setting approved to
  1 makes both refuse and say the gate is open.
- **`full.md`**: the mint-wide wording replaces "forever" and "nobody can prove anything"; the count
  is "across the six mints that have holders"; "somebody is knocking" and "Backed has not answered"
  are gone — the first asserts intent two unattributed transactions do not establish, the second
  anthropomorphises a chain state. 4,998 / 5,000.

## What is still open, and is the founder's to decide

Codex's counter-proposal is **bounded confidential issuance** — investor configures, issuer
approves, issuer transfers an allocation against confidential cash, investor checks the received leg
before signing, read back independently — with a **five-day stop**: if it does not meet those five
conditions in five days, stop and make the polished DvP video instead. And **no redemption**,
because its supply-leak claim is configuration-dependent and this repository already lists the
counterexamples.

---

Verdict: freeze Stocklana except for factual corrections. Reject the CWF frame as currently specified. It has a good problem insight, but its proposed “recipient” demo demonstrates the bad native option, not Confide’s replacement.

1. Diagnosis: useful, but overstated.

The measurements support: all 1,992 mints in `web/mints.json` share the configuration; the auditor field is null; and the six-mint account scan found two configured, zero approved.

They do not establish deliberate refusal. Exact 100% uniformity is at least as consistent with a shared deployment template, SDK, or issuance provider as with three independent decisions. In fact, lack of variance makes intent harder to infer.

Also, “forever” is technically wrong. Token-2022 exposes `UpdateMint`, and your own [`set_auditor.rs`](/Users/hiroyusai/src/confide/crates/confide-ct/src/set_auditor.rs:26) uses it to replace the auditor key. A more defensible claim is:

> Token-2022 provides no holder-, recipient-, purpose-, or amount-scoped native disclosure. A mint-wide auditor can decrypt transfers made while its key is configured; rotating the key does not make prior ciphertext unreadable to the old key.

Likewise, “leave it null and nobody can prove anything” is contradicted by Confide’s own collateral proof. Say “Token-2022 provides no native scoped disclosure,” not “nobody can prove anything.”

To test the intent inference, collect provenance rather than more extension counts:

- Cluster each issuer’s mint-creation transactions, authorities, transfer-hook program IDs, and deployment dates.
- Inspect public issuance SDKs/templates and test whether this configuration is their default.
- Find whether `UpdateMint` was ever called after initialization.
- Ask the issuers one precise question: “Was the empty auditor key a deliberate policy decision, and why?” That is the only evidence that can establish intent.

Until then, call it a repeated configuration, not a deliberate refusal.

2. The new frame becomes an essay unless the demo is real.

“Native disclosure is global; Confide is scoped” is a strong opening. But the proposed table does not substantiate it:

- [`set-auditor.sh`](/Users/hiroyusai/src/confide/scripts/set-auditor.sh:1) installs a mint-wide auditor. It is the baseline you are replacing, not recipient-scoped disclosure.
- [`prove-collateral.sh`](/Users/hiroyusai/src/confide/scripts/prove-collateral.sh:40) performs RPC simulation with signature verification disabled. That is meaningful live-program execution, but it is not a persisted, recipient-bound disclosure artifact.

So recipient + granularity is not yet one demonstrated product flow. It is a global auditor demonstration plus a public predicate-proof demonstration. Do not pitch that as “here is the correct setting.”

3. Choose bounded confidential issuance, not issuance + redemption, and cap it.

Your existing DvP should remain the visual proof of Functionality. The best additional build is a narrowly real issuance flow:

1. Investor configures an account.
2. Issuer approves it.
3. Issuer transfers an allocation against confidential cash.
4. The investor checks the received leg before signing.
5. The final transaction and public-zero balances are independently read back.

That is not just renaming Bob “issuer”: it makes the gate part of the workflow, eliminates matching, and gives the existing DvP a credible first user.

Do not build redemption in this window. Its public-supply leak remains configuration-dependent, and the current repository correctly lists treasury transfer, batching, reissuance, and `ConfidentialMintBurn` as counterexamples. A partially proven “issuance/redemption lifecycle” would be a third avoidable claim.

If the issuance flow cannot meet the five conditions above in five days, stop. Make the polished DvP video instead. That is lower variance than trying to turn the current recipient/granularity components into a product at the end.

4. “Somebody knocked” is usable only as a dated observation, not traction.

Keep it in Check-in 2 because the correction-to-measurement sequence is genuinely interesting. Remove it from the CWF pitch and form’s main argument.

Three wording corrections matter:

- The scan is six selected mints, not all 1,992. Say “across the six monitored mints,” not “of all live token accounts.”
- “Somebody knocked” implies intent/demand. Two unknown configure transactions do not establish either.
- “Backed has not answered” anthropomorphizes a chain state. The supportable version is: “As of the scan, neither configured account was approved.”

There is also a concrete release blocker: the current CWF renderer still requires zero configured accounts and will refuse to render with the committed `usage.json` value of two: [`record-presentation.js`](/Users/hiroyusai/src/confide/video/record-presentation.js:120) and [`record-checkin.js`](/Users/hiroyusai/src/confide/video/record-checkin.js:63). Fix that before recording anything.

5. Keep these out of CWF videos.

- Embargo/schedule: right buyer mismatch, plus its committee is explicitly trust-dependent.
- Seizure, Kamino, lending, and collateral liquidation: parked wedge, different buyer.
- Global-auditor setup presented as Confide’s recipient-scoped solution.
- Redemption, corporate actions, voting, or regulatory-compliance claims.
- “Somebody knocked,” SEC causality, or any adoption implication.
- “Solana leads,” market-size extrapolation from 469,477 accounts, or the dust-holder theory as causation.
- A long self-critique montage. One sentence on the signing fix can signal rigor; it should not be the product story.

For Stocklana, use the remaining characters to replace “everyone’s everything, forever,” “asked,” and “Backed has not answered.” Those are corrections, not expansion.