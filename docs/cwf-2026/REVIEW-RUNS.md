# Review runs — `./scripts/review.sh`, end to end, re-read by an observer

One command runs the whole flow on devnet — the issuer's gate refusing and then opening, the
allocation, two approved holders settling, and the short-delivery control — and then
`scripts/observe-run.py` re-reads every signature and account the run cites, holding no key. The
receipts below are its output, copied from the run directory with only their headings demoted.

## 2026-10-02 00:08 UTC — passed, on the code as committed

483 seconds from preflight to receipt, the build already warm. The funder's balance fell by
0.143 SOL (31.7863 → 31.6434); the rest of what the run's throwaway wallets were lent was swept
back. Rent in the mints, accounts, proof contexts and lookup tables stays on chain — those
accounts are what the receipt links to.

The sixth run of the day, and the one this file keeps. Run 1 passed; run 2 stopped on
`BlockhashNotFound` (a load-balanced node behind the endpoint had not seen the hash yet) and run 3 on
a forty-minute RPC outage — both handled in `scripts/lib/chain.sh` since. Run 4 passed. Codex then
found the observer did not bind signatures to accounts or look at inner instructions, and the run
directory kept the endpoint in its spl-token configs; run 5 passed with both fixed, and run 6 with the
last change, a retry on the final allocation (`STATUS.md` 0cc–0ce).

### Receipt — normal mode

Re-read from devnet by `scripts/observe-run.py`, which holds no key and trusts nothing the run
said except which signatures and addresses to look up.

| | step | what the chain says | look it up |
|---|---|---|---|
| ok | 1 · issuer policy | mint X: approval required, auditor empty | [explorer](https://explorer.solana.com/address/44tuhPczJjifWno7sAP69LcWz13EmpZ1buGC9SiA93Zx?cluster=devnet) |
| ok | 1 · issuer policy | mint Y: approval required, auditor empty | [explorer](https://explorer.solana.com/address/DtLdx8nkavrho4j9Fa35xXucJaToncS5zyurjqmNuYkS?cluster=devnet) |
| ok | 3 · gate refuses | allocation landed and failed: {"Custom": 24} | [explorer](https://explorer.solana.com/tx/28xhC695DvqXhSfiBgkUxe4TPsHyTWZhiqX1eZRzt1jWKPAXgt7hYmW9JYSS6zPAn2bdX5M8gHLTsqgnxjqiREDo?cluster=devnet) |
| ok | 3 · only the issuer can approve | self_approval landed and failed: "MissingRequiredSignature" | [explorer](https://explorer.solana.com/tx/ZTZp6Zu4cLNvGCf52p1NkGY4LxX3wa5WjHbMmEZdTtsom8vyf5uJNeNd9J1HgrRVfuAXAGxk4LwHPmQ2iR3kAUD?cluster=devnet) |
| ok | 4 · issuer approves that account | approved CTomZ4rP… | [explorer](https://explorer.solana.com/tx/feEjphXdT4V8PhzQtu9aVXBPKPBqncF6ALZtSsV5jmCYvk1AFttzQtSnXFoybCj9m8arVpY6pJSRDk1X3YWowoe?cluster=devnet) |
| -- | 6 · two signatures needed | half_signed: refused in RPC preflight, never entered a block -- nothing to look up |  |
| ok | 5 · issuer allocates | act 1: succeeded, 2 signatures, 2 Token-2022 instructions and nothing else (top level or inner), touching the 4 accounts below | [explorer](https://explorer.solana.com/tx/38MGRJJHW2BrdQFvThegrD2ws8yWDCnefR5zjfsC9HaYi3HJBpsSdXhbhCHUTsFQWJqEQhj9X98xnoXfY4EhbCQS?cluster=devnet) |
| ok | 7 · observer, act 1 | p1WnEjco…: public balance 0, balance encrypted | [explorer](https://explorer.solana.com/address/p1WnEjcoK9exQs6uWxDWqj1w6EV5cAsutDgvGFNtAQN?cluster=devnet) |
| ok | 7 · observer, act 1 | CTomZ4rP…: public balance 0, balance encrypted | [explorer](https://explorer.solana.com/address/CTomZ4rPrV728YgknUZ6pC5jn6DH3C1jnk6hdMoAjgHT?cluster=devnet) |
| ok | 7 · observer, act 1 | YaHL1mJc…: public balance 0, balance encrypted | [explorer](https://explorer.solana.com/address/YaHL1mJcG3pSVX2oQUMQGvCN2vyUvXHwn1Z3p5rJwvf?cluster=devnet) |
| ok | 7 · observer, act 1 | Cgv9SJGg…: public balance 0, balance encrypted | [explorer](https://explorer.solana.com/address/Cgv9SJGgTU1zBGtuhL33TV6VekB9m4PFzKbZMzR4g2oq?cluster=devnet) |
| ok | 6 · two holders settle | act 2: succeeded, 2 signatures, 2 Token-2022 instructions and nothing else (top level or inner), touching the 4 accounts below | [explorer](https://explorer.solana.com/tx/2SmguhmjJNDfRLEeYCxrqPZZwALjMvARNqCZ5vrvYUsUtioVk3VTLbgAF5HAQy4jAHxgkqkppQTakZLw9MeiVps?cluster=devnet) |
| ok | 7 · observer, act 2 | CTomZ4rP…: public balance 0, balance encrypted | [explorer](https://explorer.solana.com/address/CTomZ4rPrV728YgknUZ6pC5jn6DH3C1jnk6hdMoAjgHT?cluster=devnet) |
| ok | 7 · observer, act 2 | YaHL1mJc…: public balance 0, balance encrypted | [explorer](https://explorer.solana.com/address/YaHL1mJcG3pSVX2oQUMQGvCN2vyUvXHwn1Z3p5rJwvf?cluster=devnet) |
| ok | 7 · observer, act 2 | HJC7n8uk…: public balance 0, balance encrypted | [explorer](https://explorer.solana.com/address/HJC7n8uk2oKuhjHDcr3b3S2CT6hFSKb1QAmbvVYFVmwY?cluster=devnet) |
| ok | 7 · observer, act 2 | ALK3krnv…: public balance 0, balance encrypted | [explorer](https://explorer.solana.com/address/ALK3krnvPsgT1Y6jPzqdMdiRaJuWdJpuMyPAbrvnxmTy?cluster=devnet) |

**Every check held.**

### Receipt — short mode

Re-read from devnet by `scripts/observe-run.py`, which holds no key and trusts nothing the run
said except which signatures and addresses to look up.

| | step | what the chain says | look it up |
|---|---|---|---|
| ok | 1 · issuer policy | mint X: approval required, auditor empty | [explorer](https://explorer.solana.com/address/9c74HRPcJ9sdqFCvP6XaeBwAJnE72HPbGepvcUHX3F6J?cluster=devnet) |
| ok | 1 · issuer policy | mint Y: approval required, auditor empty | [explorer](https://explorer.solana.com/address/HreJEGi1D7Hyu146mfxw9aWYymKY3yzxLVvkpDJ6jXgU?cluster=devnet) |
| -- | 6 · amount checked before signing | short leg refused by the signer's own check (agreed 20000) -- local, no transaction, so the chain cannot confirm it: reported by the run |  |

**Every check held.**

