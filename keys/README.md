# Published keys — devnet only, worth nothing, published deliberately

These are secrets, in a public repository, on purpose. Read `../docs/TESTBED.md` before assuming
that is a mistake.

| file | is | may |
|---|---|---|
| `devnet-approval-authority.json` | the standing testbed's confidential-transfer mint authority | approve accounts through the gate, and `UpdateMint` |
| `devnet-faucet.json` | the owner of the faucet token accounts | hand out a devnet balance |

**Neither is the mint authority.** Minting with the approval key failed with `Error: owner does not
match` when it was tried by hand; no script re-checks it (`testbed-up.sh --check` does not compare the
mint authority). The mint authority is not here and is not in this repository —
`scripts/testbed-up.sh` writes it to `$CONFIDE_PRIVATE_KEYS`, outside the working tree, because
the first run of that script put it in this directory and it would have been committed.

**Nothing here touches mainnet, and no key here has ever held anything of value.**
