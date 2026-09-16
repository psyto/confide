## Verdict: block

The new floor check is not sound as an on-chain collateral assertion, and de-shield does not let a permissionless liquidator take collateral. It makes the asset public in an account still owned by the loan PDA, then marks the loan settled.

- **Floor check — unsound.** The byte offsets are correct: equality commitment at `33 + 32 + 64 = 129`, range commitment at `33`; `q_min` is correctly encoded as a 32-byte little-endian scalar; and `PEDERSEN_G` matches Token-2022’s subtraction basepoint. For genuine, correctly scoped ZK context accounts, `C - q_min·G` range-proved to 64 bits establishes `balance >= q_min`.

  But the program never verifies that either floor account is owned by the ZK proof program, nor that equality’s pubkey/ciphertext equals the escrow’s current confidential-transfer extension. It merely reads attacker-controlled bytes and checks a header byte plus authority bytes. [originate](/Users/hiroyusai/src/confide/programs/confide-seizure/src/lib.rs:152) and [floor_is_proved](/Users/hiroyusai/src/confide/programs/confide-seizure/src/lib.rs:330).

  A borrower with actual balance below `q_min` can supply accounts owned by an attacker program containing:
  - an equality “commitment” `C = Commit(q_min + 1, r)`;
  - a range “commitment” `C - q_min·G = Commit(1, r)`;
  - the expected PDA authority and proof-type bytes.

  The check passes. No proof need have been verified, and even a genuine proof can concern an unrelated high-balance ciphertext. `EQ_PUBKEY` and `EQ_CIPHERTEXT` are defined but unused. This directly defeats the pooled-market claim.

  It also has a unit bug: the record and default predicate call `q_min` “whole tokens,” but floor verification compares it directly to Token-2022 base units. [layout](/Users/hiroyusai/src/confide/programs/confide-seizure/src/lib.rs:54), [floor scalar](/Users/hiroyusai/src/confide/programs/confide-seizure/src/lib.rs:349), [default math](/Users/hiroyusai/src/confide/programs/confide-seizure/src/lib.rs:407).

- **Zero-opening substitution — correct in the locked implementation.** For valid ciphertexts it is byte-identical, not merely algebraically equivalent. Token-2022 computes `(C - amount·G, handle)`; `encrypt_with(amount, zero_opening)` is `(amount·G, identity)`, so subtracting it produces the same two compressed components. [client construction](/Users/hiroyusai/src/confide/crates/confide-ct/src/lib.rs:281), [runtime subtraction](/Users/hiroyusai/.cargo/registry/src/index.crates.io-1949cf8c6b5b557f/spl-token-confidential-transfer-ciphertext-arithmetic-0.5.1/src/lib.rs:171).

  The current tests only show decryptability and client-side arithmetic, not equality with Token-2022’s serialized runtime result. Add a fixture/property test against `ciphertext_arithmetic::subtract_from`, including zero, max `u64`, and randomized valid ciphertexts.

- **Mode B — key separation is real; “no issuer signature” is false.** An ElGamal secret alone cannot sign as the token-account owner, freeze, or transfer. Token-2022 validates the account owner for both confidential withdrawal and transfer. It can decrypt ciphertexts addressed to that escrow key, including its available/pending balances; it does not reveal unrelated accounts unless that same ElGamal key is reused.

  But for `SPCX` / `SPCXx`, `autoApproveNewAccounts: false` means the newly configured auxiliary escrow must be approved by the confidential-transfer mint authority before it can be funded. Approval explicitly requires that authority’s signature. The document itself already records this contradiction. [approval processor](/Users/hiroyusai/.cargo/registry/src/index.crates.io-1949cf8c6b5b557f/spl-token-2022-9.0.0/src/extension/confidential_transfer/processor.rs:297), [document admission](/Users/hiroyusai/src/confide/docs/SEIZURE.md:460).

- **“One escrow, one loan” — false as enforced.** `originate` never parses the escrow Token-2022 account or verifies its owner is the derived loan PDA. It records whatever address was supplied. A borrower can originate against an account they still own, then move it or pledge it elsewhere; later seizure simply fails. [origination](/Users/hiroyusai/src/confide/programs/confide-seizure/src/lib.rs:121).

  The PDA construction would prevent ordinary outbound transfers only after a verified handover. It is not an across-protocol guarantee unless origin enforces Token-2022 ownership, mint, account state, and relevant extension policy.

- **De-shield — critical custody failure.** `Withdraw` credits the escrow’s own public `base.amount`; it does not change the escrow owner. The escrow remains owned by the loan PDA. An ordinary SPL transfer out still needs the PDA’s signature, which only this program can produce. This program has no post-default public-transfer instruction. Therefore a permissionless caller can de-shield and permanently strand the collateral after `seized = 1`. [deshield](/Users/hiroyusai/src/confide/programs/confide-seizure/src/lib.rs:483), [Token-2022 owner validation](/Users/hiroyusai/.cargo/registry/src/index.crates.io-1949cf8c6b5b557f/spl-token-2022-9.0.0/src/extension/confidential_transfer/processor.rs:545).

- **`may_settle` only shares some guards.** It correctly centralizes: initialized/unsettled loan, recorded escrow/mint/oracle, oracle signature, and floor-price predicate. [may_settle](/Users/hiroyusai/src/confide/programs/confide-seizure/src/lib.rs:452).

  De-shield does not bind or record its two proof context accounts at all, and does not require their authority to be the PDA. Thus it cannot promise proof availability from origination in mode A; the borrower can withhold or close them. Mode B can rebuild them only while the lender retains the escrow secret. The prose claim that both paths reject every unrecorded account is false: de-shield accepts arbitrary proof-context addresses. [deshield inputs](/Users/hiroyusai/src/confide/programs/confide-seizure/src/lib.rs:499).

The prose overclaims in sections 4/4b/4c/4d: “no trust” for the floor, cross-protocol one-escrow protection, no issuer involvement, “anything can move it afterwards,” unchanged liquidation integration, and equal account binding across both settlement paths. The section 3b table additionally claims origin checks source ciphertext/pubkey and destination/auditor bindings that this implementation does not perform.