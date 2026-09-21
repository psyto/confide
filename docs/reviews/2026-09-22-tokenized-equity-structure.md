The dividend retraction is not justified. `scaledUiAmountConfig` is a UI conversion factor, not a rebase of Token-2022 balances—public or confidential. The repository should withdraw the statement that “a confidential balance rebases exactly like a public one,” and downgrade the voting and supply conclusions to conditional claims pending primary documentation and transaction evidence.

## The decisive technical point: multiplier ≠ balance rebase

`scaledUiAmountConfig` stores a mint-level multiplier, and its implementation takes a caller-supplied public `u64` raw amount and returns a formatted UI string. It does not receive a token account, alter `base.amount`, alter any confidential ciphertext, mint tokens, or run a ZK proof. [Extension implementation](/Users/hiroyusai/.cargo/registry/src/index.crates.io-1949cf8c6b5b557f/spl-token-2022-interface-3.1.1/src/extension/scaled_ui_amount/mod.rs:53) [Processor](/Users/hiroyusai/.cargo/registry/src/index.crates.io-1949cf8c6b5b557f/spl-token-2022-11.0.0/src/processor.rs:1548)

So:

- A public raw balance can be *displayed* at a scaled UI value.
- A confidential balance is encrypted, not a `u64` available to that converter. Its owner could decrypt it locally and apply the same arithmetic for display, but the protocol has not changed the ciphertext or credited anything.
- The extensions are compatible; that only means a mint may have both. It does not mean the multiplier operates on confidential state. [Compatibility checks](/Users/hiroyusai/.cargo/registry/src/index.crates.io-1949cf8c6b5b557f/spl-token-2022-interface-3.1.1/src/extension/mod.rs:1325)

A contract could define one raw token as a time-varying quantity of economic exposure, and a multiplier could publish that conversion globally without reading holders’ balances. That is a legal/product interpretation requiring terms. It is not an on-chain dividend distribution, nor evidence that a custodian bought additional shares.

Thus §2a’s statement “the multiplier is raised so every holder’s quantity increases” is technically wrong if “quantity” means token balance. Only the UI representation changes.

## Claims triage

| §2 claim | Triage | Review |
|---|---|---|
| Backed Assets (JE) Limited; Jersey SPV; tracker; senior economic claim, not shares | **B/C** | Identity and instrument terms need the prospectus/terms. “Senior claim” and legal classification are conclusions, not chain facts. |
| InCore Bank and Apex Clearing; segregated bankruptcy-remote custody; tri-party Account Control Agreement | **B** | Needs the custody agreement or issuer disclosure. This is the strongest reconstruction smell. |
| Fiat/stablecoin → issuer buys share → custodian → 1:1 mint | **B**, with a narrow **A** component | Individual mints are observable; payment, purchase, custody, and 1:1 backing are not. |
| Dividends via custodian reinvestment and multiplier | **A/B** | Multiplier updates are on-chain. The dividend/reinvestment explanation needs primary terms, and the asserted balance rebase is false. |
| Splits handled the same way | **A/B** | A multiplier update is observable; calling it a split and specifying its legal effect needs terms. |
| Continuous Chainlink proof of reserves | **A/B** | Feed contracts and update history can be checked on-chain; linkage to reserves, scope, and “continuous” operation needs documentation. On-chain publication is discrete, never literally continuous. |
| No token-holder vote; register is custodian/SPV | **B/C** | Needs governing terms, transfer-agent/proxy procedure, and legal analysis. |
| Backpack holding is a UCC Article 8 security entitlement | **B/C** | A broker agreement may say this; whether Article 8 applies is ultimately a legal characterization. |
| Two-way 1:1 token/entitlement conversion | **B**, with a narrow **A** component | Particular mints/burns can be observed; the standing right, eligibility, and 1:1 policy need primary terms. |
| No voting on-chain; redeem to vote; redeem for ACATS | **B/C** | Exact proxy and ACATS procedures need broker documentation. The categorical “requires redemption” is not established by a mint snapshot. |
| Dividends auto-reinvested as additional Backpack tokens | **B**, with a narrow **A** component | A visible mint/distribution can be observed, but its cause and entitlement require corporate-action terms. |

## Conflicts with §1

There is no direct contradiction between §1 and the broad legal claims. §1 cannot establish issuer identity, custody, beneficial ownership, voting, redemption, or Article 8 status.

There are two important qualifications:

1. §1 confirms that Backed’s mints have a scaled-UI extension and changing multipliers. It does **not** confirm dividends, reinvestment, reserve purchases, or token-balance rebasing. The present repository claim overreads the measured field. [Current overclaim](/Users/hiroyusai/src/confide/docs/cwf-2026/ISSUANCE.md:138)

2. The 52.4% NVDAx and 74.8% AAPLx authority-linked inventories mean the universal mint-flow story is at least incomplete. They are consistent with treasury/inventory/market-making accounts, but not evidence that every outstanding token was minted only after an end investor paid and a corresponding share was purchased.

Nothing in §1 conflicts with Backpack’s alleged two-way door. A public supply snapshot cannot prove that door exists.

## Supply differencing

The proposition is sound only under a narrow condition:

> If a redemption uses the ordinary Token-2022 `Burn` instruction, then public mint `supply` falls by the public burn amount. The amount is observable—usually directly in the instruction, not merely by two snapshots.

It is not sound as the unconditional claim that “every passage through the door publishes its size.”

Ways it can fail:

- **Treasury transfer / repurchase:** holder transfers tokens to issuer inventory, possibly confidentially; issuer gives the off-chain entitlement or cash; public supply is unchanged.
- **Batching/netting:** a supply delta can aggregate many redemptions and mints, revealing at most a net change.
- **Reissuance:** the issuer can redeem into treasury and later redistribute the same units.
- **Confidential Mint-Burn extension:** Token-2022 has a separate `ConfidentialMintBurn` extension. Its confidential mint and burn instructions update encrypted supply and do not update the ordinary public `mint.supply`; pending confidential burns are aggregated into encrypted supply. [Confidential mint](/Users/hiroyusai/.cargo/registry/src/index.crates.io-1949cf8c6b5b557f/spl-token-2022-11.0.0/src/extension/confidential_mint_burn/processor.rs:274) [Confidential burn](/Users/hiroyusai/.cargo/registry/src/index.crates.io-1949cf8c6b5b557f/spl-token-2022-11.0.0/src/extension/confidential_mint_burn/processor.rs:470)

I cannot infer from §1 whether `SPCX.US` has that latter extension; §1 establishes `confidentialTransfer`, not explicitly the absence of `confidentialMintBurn`. That extension inventory is the on-chain check needed before making a protocol-level supply-leak claim.

For a mint without `ConfidentialMintBurn`, burning confidential value normally requires first withdrawing it to the account’s public balance, which itself makes the amount public. But even then, a product can choose issuer-treasury transfer rather than burn.

Accordingly, these sentences in `ISSUANCE.md` should be conditional, not marked “upgraded … to structure”: [lines 71–81](/Users/hiroyusai/src/confide/docs/cwf-2026/ISSUANCE.md:71) and [152–159](/Users/hiroyusai/src/confide/docs/cwf-2026/ISSUANCE.md:152).

## Reconstruction smells

I would not call any named legal fact false without primary sources. I would flag these as likely LLM-style reconstruction until sourced:

- “InCore Bank and Apex Clearing” combined with “segregated, bankruptcy-remote accounts” and a “tri-party Account Control Agreement.”
- “Senior claim for economic value.”
- “Accredited investor pays fiat or stablecoin” as a universal operational flow.
- “Proof of Reserves published continuously via an oracle network, Chainlink named.”
- “ACATS transfer likewise requires redeeming first.”
- “Dividends on-chain are auto-reinvested as additional tokens.”

They have the characteristic form of stitching together plausible industry components into a fully specified operating model. Each may contain true fragments; none should support a submission claim unless it is tied to the precise prospectus, broker agreement, custody disclosure, corporate-action policy, or named on-chain transaction/feed.

The voting retraction has the same provenance problem. “Tokens do not vote on-chain” may be true as product policy, but the chain does not impose it. Until Backpack’s primary materials establish the proxy and redemption procedure, it cannot safely replace the original argument.