# Review request — claims about how Backed/xStocks and Backpack Securities are structured

**Provenance matters here and is the reason for this review.** Everything in §2 was produced by
Google's Gemini in conversation with the founder and **has not been verified against any primary
source**. It has already been used to correct two arguments in this repository, so if it is wrong,
the corrections are wrong too.

**You cannot browse and your knowledge has a cutoff. That is understood.** Do not guess at facts
about the world. What is wanted is narrower and you are well placed for it:

1. **Internal contradictions** in §2 — places where the account cannot be true of itself.
2. **Conflicts with §1**, which is measured on-chain and is ground truth.
3. **A triage**: for each claim, say whether it is (a) checkable on-chain, (b) checkable only in a
   primary document, or (c) an interpretation that no document will settle.
4. **Anything that smells like an LLM reconstructing a plausible structure** rather than reporting
   one — specific names, specific legal forms and specific counterparties are where that shows.

---

## §1 — Measured on-chain by this repository, 2026-09-21/22. Ground truth.

| | |
|---|---|
| `NVDAx` `scaledUiAmountConfig` | `multiplier` **1.0009180758490996**, `newMultiplier` **1.001701196801074**, effective ts 1789000200. Authority `S7vYFFWH6BjJyEsdrPQpqpYTqLTrPRK6KW3VwsJuRaS` |
| `AAPLx` same extension | multiplier **1.0026642075893797**, next **1.0032690125398187** |
| That same authority | **holds 52.4% of all NVDAx** in one token account |
| `AAPLx` largest holder | **74.8%**, and it is one of the mint's authorities |
| `SPCX.US` (Backpack Securities) | supply **42,488.081216**, **6 decimals**, top 20 accounts = **48.3%**, largest holders are Meteora and Raydium pools, two of the top six are ordinary wallets with ~1,100 shares |
| Every mint checked, all three issuers | `confidentialTransfer` present, `autoApproveNewAccounts: false`, auditor slot **null**. 1,992 of 1,992 |
| Decimals | NVDAx 8, AAPLx 8, ANTHROPIC 9, SPACEX 9, AMC.US 6, SPCX.US 6 |

## §2 — Unverified, from Gemini. The claims to review.

### 2a. Backed / xStocks

- Issuer is **Backed Assets (JE) Limited**, a **Jersey SPV**, issuing "tracker tokens" under a
  prospectus; holders get a **senior claim for economic value**, not share ownership.
- Custody with **licensed banks/brokers, named as InCore Bank and Apex Clearing**, in segregated,
  bankruptcy-remote accounts under a **tri-party Account Control Agreement**.
- Mint flow: accredited investor pays fiat or stablecoin → issuer buys the real share through a
  broker → share goes to the custodian → tokens minted 1:1.
- **Dividends are paid by rebase**: the custodian receives cash (net of withholding), buys more
  shares, and the on-chain **multiplier is raised** so every holder's quantity increases.
- Splits handled the same way.
- **Proof of Reserves** published continuously via an oracle network, Chainlink named.
- **Token holders typically have no vote**; the register shows the custodian or the SPV.

### 2b. Backpack Securities

- Holding is a **security entitlement under UCC Article 8** at the broker layer.
- **Two-way 1:1 conversion**: a share bought in the brokerage mints to an on-chain token; the token
  burns back into the entitlement on demand.
- **Held on chain the token cannot vote.** To vote you redeem into the entitlement and vote through
  traditional proxy rails; ACATS transfer likewise requires redeeming first.
- Dividends on-chain are auto-reinvested as additional tokens.

---

## §3 — What this repository concluded from §2, which is what is at risk

1. **A dividend argument was retracted.** This repository had claimed *"you cannot pay a dividend
   pro rata to a holder whose balance you cannot read"*. §2a's rebase mechanism contradicts it, and
   §1's live multiplier confirms the mechanism. **Is the retraction correct?** Specifically: does a
   `scaledUiAmountConfig` multiplier apply to a **confidential** Token-2022 balance the same way it
   applies to a public one, or is there a reason it would not?
2. **A voting argument was then retracted too**, on §2b's account that on-chain tokens do not vote.
3. **What replaced both**: that the **conversion door itself publishes size** — minting raises a
   public `supply`, redeeming lowers it by exactly the redeemed amount, so the size is recoverable
   by differencing two public states. **Is that sound?** Is there a way an issuer redeems without
   moving public supply, or batches it so individual redemptions are not separable?

---

## §4 — The questions

1. Which claims in §2 do you believe are **wrong**? Name them and say why.
2. Which are **plausible but unsourced in a way that matters** — where being wrong would change a
   submission?
3. Do any of them **conflict with §1**?
4. Answer §3.1 concretely: **multiplier extension against a confidential balance.** This is the one
   with a real technical answer and it decides whether the retraction was right.
5. Answer §3.3: **is the supply-differencing argument sound**, and what would defeat it?
6. Is there a claim in §2 that reads like a **reconstruction** rather than a report? The named
   entities are the obvious place to look.

Be specific. "Plausible" is not useful; a named claim and a named reason is.
