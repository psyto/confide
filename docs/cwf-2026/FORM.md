# The submission form — what can be entered now, and what cannot

Field list from [`CRITERIA.md`](CRITERIA.md). Registration already took product name, category
(RWA), description and team. **The rest appears at submission**, so some of this is text held ready
rather than text that can be pasted today; each row says which.

Everything below is derived from files in this repository and was checked against them on
2026-09-19. **Nothing here is remembered.**

| field | state |
|---|---|
| product name, brief description | ✅ entered at registration |
| GitHub repository link | ✅ `https://github.com/psyto/confide` |
| **blockchains and tools integrated** | ✅ **ready — §1 below** |
| **disclosure of past development work** | ✅ **ready — §2 below. Rules requirement.** |
| teammates, backgrounds, team location | ⬜ founder-only |
| product logo or graphic | ⬜ does not exist |
| 2–3 min presentation video | ⬜ rough cut only, silent |
| demo video, ≤3 min | ⬜ does not exist |
| go-to-market, demand validation, distribution | ⬜ not written |

---

## 1. Blockchains and tools integrated

Solana only. No bridge, no second chain, nothing on another network.

**Read from `Cargo.toml` files and running scripts, not from memory.**

| | what | where it is used |
|---|---|---|
| **Solana** | mainnet-beta (read) and devnet (deployed) | the finding is read from mainnet; the mechanism runs on devnet |
| **Token-2022 confidential transfers** | `spl-token-2022-interface` 3, `spl-token-confidential-transfer-proof-extraction` 0.6 | the confidential balance a position is held in |
| **Solana's ZK ElGamal Proof Program** | `solana-zk-elgamal-proof-interface` 0.1.3, `solana-zk-sdk` 7 — program `ZkE1Gama1Proof11111111111111111111111111111` | **the collateral floor is checked by Solana itself, not by us**: ciphertext-commitment equality and a batched u64 range proof |
| **Confide's seizure program** | native Solana program, `Gn3rzw8ULVo676ebnxX6qK3YEQP9T8NHtFVetXW8QduN`, live on devnet | default settlement — collateral moves without the borrower signing again |
| **`aperture-receipts`** | pre-existing program from `psyto/aperture` v0.5.1, deployed to devnet | content-blind on-chain receipt. **Disclosed in §2** |
| **Kamino Lend** | read-only, at pinned commit `a0876097` (release/v1.25.0) | the compatibility verdict quotes its source; **no integration, no deployment, nothing asked of them** |

**What composes with what** — this is Official Rules §8(e), which asks how well the work composes
with other primitives and not only whether it is open-source:

> Confide adds no trust of its own where an existing primitive will do. The floor is proved by
> **Solana's own ZK program**, so a lender is not asked to trust Confide's arithmetic. The position
> lives in **Token-2022's** confidential balance rather than a wrapper mint, so no new issuer and no
> new redemption path is invented. The admission rules are **Kamino's own**, read out of their
> published source at a pinned commit. Apache-2.0 throughout.

---

## 2. Disclosure of past development work

> *"Builders may use pre-existing code, but teams must disclose all relevant past development work
> in the submission form."*

**Being written in the repository is not disclosure.** This text exists to be pasted into the form.

### Paste text

> **Pre-existing work, disclosed in full.**
>
> Confide depends on one pre-existing project by the same author, `psyto/aperture` (Apache-2.0,
> public at `https://github.com/psyto/aperture`), consumed at the released tag **v0.5.1** in two
> distinct ways:
>
> 1. **`aperture-core`** — a versioned Cargo dependency, referenced at arm's length
>    (`{ git = "https://github.com/psyto/aperture", tag = "v0.5.1" }`), not vendored and not
>    modified. It provides Token-2022 confidential balance handling, the disclosure package, the
>    policy layer and the auditor. Used by `confide-committee`, `confide-embargo`, `confide-equity`,
>    `confide-onchain` and `confide-demo`.
> 2. **`aperture-receipts`** — a pre-existing native Solana program, **already deployed to devnet**
>    and called by Confide rather than compiled into it. It anchors a content-blind on-chain
>    receipt.
>
> Everything else is Confide's own work in this repository: the embargo mechanism, the k-of-n
> secret sharing (`crates/confide-embargo/src/shamir.rs`, GF(256), no dependency), the tokenized
> equity layer, the seizure program deployed at
> `Gn3rzw8ULVo676ebnxX6qK3YEQP9T8NHtFVetXW8QduN`, the Kamino compatibility verdict and capacity
> computation, the admission packets, the decision page and the demo.
>
> **On the contest window specifically.** This repository predates the Crypto World's Fair window.
> The last commit before the window opened is `765b8bc`, committed 2026-09-14 07:37:41 UTC —
> **5 h 22 min before** the window opened at 13:00 UTC. Work completed inside the window is
> therefore `cwf-2026-baseline..HEAD` and nothing before it. The boundary, the commands that
> establish it and the rules it is measured against are recorded in `docs/WORK-WINDOW.md`, and the
> Official Rules PDF is committed byte-identical to what was served, because §4(g) permits the
> published rules to be changed at any time.
>
> Confide was also submitted to a separate hackathon (Stocklana, filed 2026-09-15, judged to
> 2026-10-02) from the same repository. That is disclosed here rather than left to be discovered.

### Why it is worded that way

- **Two forms of reuse, named separately.** One is a crate dependency, the other a deployed program
  Confide calls. Collapsing them into "we use aperture" would understate one and overstate the other.
- **The window is volunteered rather than waited for.** `README.md` already says Confide is new work
  for Stocklana, which is true for *that* window and false for this one. A judge reading the same
  public repository will see that sentence. Better it is explained in the form than found.
- **The other hackathon is named.** Official Rules §7 limits an Entrant to one Team and one Project
  Submission *in this contest*; it contains no exclusivity clause against other contests. Saying so
  costs nothing and not saying it looks like concealment if it surfaces later.
