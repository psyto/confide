# Codex review — the judging rubric, 2026-09-15

Adversarial read against Stocklana's one question. Run read-only with no network egress, so
its healthcheck failures are an artefact of the sandbox, not of the chain — it says so itself.

Verified independently before acting: the test count (26, not 21), `anchor.rs` building its
position from `ElGamalKeypair::new_rand()` and a hard-coded 173,000, `XSTOCKS` being four
constants, the page's hard-coded 173,000, `postTokenBalances` being historical, and
`healthcheck.sh` accumulating failures rather than stopping at the first.

One citation is wrong: `_submission/full.md:221` does not exist — the file is 82 lines. The
claim it was attached to (that a test would catch the premise failing) lives in a doc comment
in `crates/confide-equity/src/lib.rs`, not in the submission copy. The point stands; the
pointer did not.

---

## Rubric verdicts

1. **REAL USER AND PROBLEM — FAILS**

The on-chain observation is interesting, not demand evidence. The copy asserts “all 1,869” mints have the empty slot, then infers “the issuer is the customer” without any issuer, GP, lender, administrator, interview, pilot, permission, or inbound signal. [_submission/full.md:3](/Users/hiroyusai/src/confide/_submission/full.md:3) [_submission/full.md:65](/Users/hiroyusai/src/confide/_submission/full.md:65)

A judge is likely to read this as a solution in search of a user: an empty configuration field does not establish that issuers want recipient-scoped disclosure, that funds hold these assets privately, or that LP reporting is the buying trigger.

Cheapest meaningful change before September 18: obtain one named issuer, GP, fund administrator, or lender as a design partner—with a concrete statement of the workflow they would run and, ideally, approval for a confidential-account pilot. A waitlist or anonymous survey will not change this verdict.

2. **WORKING END-TO-END DEMO — FAILS**

The discrete crypto proof is real enough to be interesting. `prove-collateral.sh` fetches the live account ciphertext, and the Rust prover uses that ciphertext in the equality proof. [scripts/prove-collateral.sh:16](/Users/hiroyusai/src/confide/scripts/prove-collateral.sh:16) [prove_collateral.rs:70](/Users/hiroyusai/src/confide/crates/confide-ct/src/prove_collateral.rs:70)

But the actual product claim—an irreversible scheduled disclosure of the holder’s real tokenized-stock position—is simulated. The anchoring code creates a fresh random “fund” key, hard-codes 173,000 NVDAx shares, and issues a disclosure from that synthetic value. It never reads or incorporates the live confidential account shown on the page. [anchor.rs:84](/Users/hiroyusai/src/confide/crates/confide-onchain/src/anchor.rs:84) [anchor.rs:89](/Users/hiroyusai/src/confide/crates/confide-onchain/src/anchor.rs:89) [anchor.rs:91](/Users/hiroyusai/src/confide/crates/confide-onchain/src/anchor.rs:91) The project itself admits the two-lane demo “simulates the accumulation rather than holding a confidential balance on a mirrored mint.” [DESIGN.md:193](/Users/hiroyusai/src/confide/DESIGN.md:193)

The stale-proof protection is incomplete:

- It correctly compares the account’s `availableBalance` against the ciphertext pinned with the pre-generated proofs. [web/index.html:235](/Users/hiroyusai/src/confide/web/index.html:235)
- The page explicitly warns that the ZK program itself does not read the account. [web/index.html:282](/Users/hiroyusai/src/confide/web/index.html:282)
- But it snapshots that check once, then later only replays static proof transactions. It does not re-read the account at click time, and does not compare the account’s ElGamal public key or mint. [web/index.html:238](/Users/hiroyusai/src/confide/web/index.html:238) [web/index.html:264](/Users/hiroyusai/src/confide/web/index.html:264)

So: after a reload with a changed ciphertext, it will not falsely claim success. After the account changes after page load, it can still render green. This is a time-of-check/time-of-use gap, not a live account attestation.

`healthcheck.sh` does not prove what it claims. The submission says it checks “every claim” and exits on the first dead one, but it checks only NVDAx on mainnet, not the 1,869-mint premise; simulates two static transactions; and tests URLs only for HTTP 200. [scripts/healthcheck.sh:31](/Users/hiroyusai/src/confide/scripts/healthcheck.sh:31) [scripts/healthcheck.sh:79](/Users/hiroyusai/src/confide/scripts/healthcheck.sh:79) [scripts/healthcheck.sh:95](/Users/hiroyusai/src/confide/scripts/healthcheck.sh:95) It accumulates failures and exits with their count, rather than stopping at the first. [scripts/healthcheck.sh:22](/Users/hiroyusai/src/confide/scripts/healthcheck.sh:22) [scripts/healthcheck.sh:106](/Users/hiroyusai/src/confide/scripts/healthcheck.sh:106)

I ran it here; network egress is blocked in this environment, so its eight failures cannot establish current chain failure. They do establish that this script is not a sufficient verifier of the stated claims.

3. **WHY SOLANA — ADEQUATE**

The strongest positive case is structural: Token-2022 confidential balances and Solana’s ZK ElGamal Proof Program are actually used in the collateral primitive, rather than being decorative. [prove_collateral.rs:26](/Users/hiroyusai/src/confide/crates/confide-ct/src/prove_collateral.rs:26) [prove_collateral.rs:74](/Users/hiroyusai/src/confide/crates/confide-ct/src/prove_collateral.rs:74)

The strongest objection is that the core scheduled-disclosure product is chain-agnostic threshold encryption plus a hash receipt. Since its “position of record” is a locally invented number under a random key, the shipped centerpiece could be rebuilt on an EVM chain with a receipt contract and different confidential-balance plumbing. Solana is essential to the best low-level prototype, but not yet to a demonstrated real application.

4. **QUALITY OF EXECUTION — WEAK**

There is genuine technical work: the collateral construction, the corporate-action handling, and explicit statements of limitations are better than ordinary hackathon theater. I ran `cargo test --workspace`: 26 tests passed.

But the depth is concentrated in isolated primitives. The thinnest part is the integration boundary between:

1. a real devnet confidential account,
2. a real proof about that account, and
3. the sealed, anchored, scheduled disclosure.

Those are not one end-to-end artifact. The binding script merely prints a `SubjectAccount`; it does not feed the anchor flow. [scripts/bind-account.sh:31](/Users/hiroyusai/src/confide/scripts/bind-account.sh:31) The anchor independently creates its own package and position.

Also, the claimed “every xStock” test is only a loop over four hard-coded constants, not 1,869 mainnet mints. [lib.rs:84](/Users/hiroyusai/src/confide/crates/confide-equity/src/lib.rs:84) [lib.rs:164](/Users/hiroyusai/src/confide/crates/confide-equity/src/lib.rs:164)

## Strongest sinking objection

**Confide does not demonstrate that a scheduled disclosure is bound to a real tokenized-stock account or position.** It demonstrates a real confidential-account proof separately, and a scheduled disclosure of a fabricated position separately. That sinks the “working end-to-end demo” criterion.

This is not fully answerable before the deadline without outside cooperation. A code-only patch can connect the flow to the project’s own devnet mirror. It cannot establish a real app for tokenized stocks without issuer approval to open a confidential account on a live mint and a real user/workflow. The submission itself says live issuer approval is required. [_submission/full.md:65](/Users/hiroyusai/src/confide/_submission/full.md:65)

I would **not advance it past a first round**. The crypto work is credible, but the rubric is about a real app people will use. There is neither demand evidence nor a demonstrated product integration on an actual tokenized-stock position.

## Claims that are wrong or unsupported

- “21 tests” is wrong in the current workspace: `cargo test --workspace` runs 26. The README says 26; the submission says 21. [_submission/full.md:52](/Users/hiroyusai/src/confide/_submission/full.md:52) [README.md:157](/Users/hiroyusai/src/confide/README.md:157)

- “Everything on this page is read live from the chain” is false. The page loads static `mints.json` and `proofs.json`, displays a hard-coded 173,000 position, and replays static transactions. [web/index.html:59](/Users/hiroyusai/src/confide/web/index.html:59) [web/index.html:156](/Users/hiroyusai/src/confide/web/index.html:156) [web/index.html:242](/Users/hiroyusai/src/confide/web/index.html:242)

- The page says recent wallets are shown “with what they hold,” but it displays `postTokenBalances` from historical transactions, not current balances. [web/index.html:100](/Users/hiroyusai/src/confide/web/index.html:100) [web/index.html:181](/Users/hiroyusai/src/confide/web/index.html:181) This also makes the submission’s “pulls real wallets … with what they hold” claim overstated. [_submission/full.md:36](/Users/hiroyusai/src/confide/_submission/full.md:36)

- “Every tokenized stock on Solana” is not established by the repository. The scan checks a pinned list sourced from Backed’s and Backpack’s APIs, not a chain-wide discovery of every tokenized stock or issuer. [scripts/refresh-mints.sh:22](/Users/hiroyusai/src/confide/scripts/refresh-mints.sh:22) [scripts/refresh-mints.sh:38](/Users/hiroyusai/src/confide/scripts/refresh-mints.sh:38)

- The assertion that the `every_xstock...` test will catch failure of the 1,869-mint premise is false; it tests four constants. [_submission/full.md:221](/Users/hiroyusai/src/confide/_submission/full.md:221) [lib.rs:167](/Users/hiroyusai/src/confide/crates/confide-equity/src/lib.rs:167)

- “A disclosure bound to a date, unrevisable” is only true for the synthetic package. It is not bound to the displayed confidential account, so the implied claim about a real holder’s position of record is unsupported. [_submission/full.md:48](/Users/hiroyusai/src/confide/_submission/full.md:48) [anchor.rs:89](/Users/hiroyusai/src/confide/crates/confide-onchain/src/anchor.rs:89)

If the video’s “732 mints, one issuer” remains unfixed, it is not necessarily formal disqualification, but it is catastrophic credibility damage: the submission’s central factual premise visibly contradicts itself in under two minutes.