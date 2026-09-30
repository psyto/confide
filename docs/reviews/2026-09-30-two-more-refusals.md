Verdict: request changes before relying on the new half-signature control.

1. `-32003` is no longer the expected current behavior. Current Agave tests show preflight returning `-32002`, with `error.data.err == "SignatureFailure"` and message “Transaction simulation failed: Transaction did not pass signature verification.” `-32003` remains a legacy-compatible case. The `ERR*[Ss]ignature*` fallback is too loose: it can pass an unrelated signature-themed failure. Parse the JSON and accept only:

   - `code == -32002 && data.err == "SignatureFailure"`; or
   - legacy `code == -32003 && message == "Transaction signature verification failure"`.

   [Current Agave RPC test](https://github.com/anza-xyz/agave/blob/master/rpc/src/rpc.rs#L6794-L6829), [change note](https://github.com/anza-xyz/agave-runtime/blob/master/CHANGELOG.md#L468-L469).

2. The half-signed control does not assert that it is actually “1 of 2.” The `grep ... || true` is display-only. A builder/signing regression yielding 0/2 or 1/3 could still pass the broad RPC-error match. Make `1 of 2` mandatory, and ideally assert the issuer’s slot is populated and the investor’s is empty.

   The two builder paths are structurally equivalent today: both derive the same two instructions through shared `instruction()` logic, with identical payer and owners; the meaningful difference is blockhash/signatures. But that equivalence is not demonstrated by the script. Strongest version: build once, issuer-sign it, exercise the refusal, then add the investor signature to that exact `half.b64` and send it. That conclusively isolates the missing signature.

3. The wrong-authority expectation is right for the current Token-2022 source: after validating account/mint/extension/authority existence, `ApproveAccount` returns `MissingRequiredSignature` when the supplied signed authority key differs from the mint’s confidential-transfer authority. The current project-status page says all clusters run the latest Token-2022 program. [Processor source](https://github.com/solana-program/token-2022/blob/main/program/src/extension/confidential_transfer/processor.rs#L289-L318), [deployment status](https://www.solana-program.com/docs/token-2022/status).

   I could not directly attest the live devnet binary from this sandbox because DNS/RPC access is blocked. Also, reword “the ISSUER’s signature is what is missing”: the issuer is not an omitted transaction signer; the transaction supplies a signed but wrong authority account, and the program uses `MissingRequiredSignature` as its error. Your printed line is better: “the signer is not the mint’s approval authority.”

4. The `landed()` refactor looks functionally sound. A failed/empty process substitution leads to the existing empty-error branches and fails rather than passes. The stale Custom(24) comment is now inaccurate, though: spaces are stripped before matching, and both spaced/unspaced patterns are retained. Remove or update it.

5. “the account still reads approved: false” is supported by the explicit chain read. “Never entered a block” is also accurate for an invalid required signature. But the observed event is RPC preflight refusal, not a directly observed network/validator rejection; print “REFUSED in RPC preflight” rather than “by the network.”

6. The broader P0 diagnostics are still incomplete: the script does not assert the public balances are zero—it only prints them—and it does not print successful transaction signatures or compute units. The brief explicitly asks for those reviewer artifacts. [Brief](docs/cwf-2026/CLAUDE-CODE-BRIEF.md:100)

I ran `bash -n` and `git diff --check`; both pass.