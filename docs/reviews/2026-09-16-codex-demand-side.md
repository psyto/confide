Plan B is better than plan A as a discovery strategy, but it is not a credible 27-day traction strategy if “traction” means a public demand-side commitment. I would price **no public “we would use this” statement at 85–95%**, not 75%.

The new failure point is not issuer indifference; it is that a risk owner cannot safely endorse a generic disclosure standard. They must underwrite a specific collateral market, with an oracle, liquidation path, legal eligibility, and a loss limit. A public statement creates reputational and possibly governance liability. With no network, a private technical response is plausible; a public commitment is not.

## 1. Does it work?

It works as a way to find the real gating information and the real buyer. It fails if treated as a campaign whose output must be a public quote.

The useful target is not “a lending protocol” in the abstract. On Morpho, it is a **vault curator / market creator with capital allocated to the market**. Markets can be created permissionlessly, but the economically meaningful decision is whether someone will supply capital or allocate a vault to it. The market’s oracle and LLTV are immutable, and bad debt falls on lenders. [Morpho market design](https://docs.morpho.org/learn/concepts/blue/), [Morpho risk documentation](https://docs.morpho.org/learn/resources/risks/)

That leaves a tighter Day-27 objective: obtain a **written, attributable conditional decision** from one curator or risk owner:

> “If the packet establishes X, Y, and Z, we would consider collateral `A` at no more than `N%` LLTV and `C` cap.”

That is meaningful. Requiring them to say it publicly is an unnecessary extra failure condition.

## 2. Demand-side pain, ranked

| Rank | Buyer | Pain already priced as | Why CDP could matter |
|---|---|---|---|
| 1 | Vault curator / lender risk owner | bad debt, collateral cap, LLTV, utilization, withdrawal liquidity, supplier APR | Disclosure uncertainty becomes an explicit haircut: lower LLTV, lower cap, or no allocation. |
| 2 | Market maker / liquidity provider | inventory VaR, expected shortfall, hedge cost, bid–ask spread, inventory age, capital tied up | Better evidence can reduce the issuer/custody/redemption component of their spread—but only if it changes their ability to exit or hedge. |
| 3 | Fund administrator / fund operations owner | NAV exceptions, reconciliation breaks, reporting turnaround, audit support cost, stale-price exceptions | The pain is real and recurring, but disclosure infrastructure is usually a workflow improvement, not a direct revenue unlock. |
| 4 | Fund portfolio/risk owner | exposure limits, concentration limits, liquidity buckets, redemption risk | They care, but usually cannot adopt a protocol artifact without the administrator, custodian, and legal chain agreeing. |

The first is the sharpest buyer because its number is directly governed on-chain: `LLTV × cap × utilization` determines how much loss can be created. Morpho itself frames oracle failure, counterparty control—including blacklist risk—and liquidation delay as lender-loss risks. [Morpho risks](https://docs.morpho.org/learn/resources/risks/)

## 3. The minimum artifact

Not a specification. Not merely a working contract integration. The minimum is a **protocol-specific collateral admission packet**, with a runnable reference implementation.

It must answer, for one named token and one named market:

- exact token, chain, issuer/SPV, custody, legal claim, redemption path, jurisdiction and transfer-eligibility constraints;
- all token authorities: pause, blacklist, seizure, upgrade, mint/burn, and who controls each;
- reserve evidence: source, signer, freshness, coverage, failure states, and what is independently verifiable;
- executable oracle path: proposed feeds, fallback, staleness/deviation rules, and fork tests;
- liquidation path: who may receive the asset, who may redeem it, expected exit venue/depth, and what happens if a liquidator is ineligible;
- a proposed `LLTV`, cap, liquidation incentive, monitoring triggers, and the loss assumption behind each;
- cost-to-integrate: contracts changed, audit surface, operations runbook, and owner-hours;
- a machine-verifiable CDP record plus conformance-vector result.

The decisive question becomes answerable:

> “Given these assumptions, would you allocate up to `$C` at `N%` LLTV?”

A generic registry cannot answer that.

## 4. The registry must change shape

Yes. An issuer-facing registry is an activation queue. A demand-side registry must be a **collateral decision surface**.

For each asset, it should show:

- `usable / conditional / blocked / unknown`, separately for each protocol and chain;
- evidence provenance and expiry—not just a green check;
- authority and legal-transfer map;
- oracle, liquidity, and liquidation coverage;
- proposed and observed risk parameters: LLTV, cap, supply, borrow, utilization, bad debt, oracle staleness;
- the missing condition and its economic consequence: e.g. “no issuer-attested redemption-status feed → proposed cap $0,” rather than “issuer has not signed”;
- clear separation of facts, issuer assertions, third-party attestations, and CDP’s own inference.

Do not claim a number for “what this costs holders” unless it is computed from public market data with a disclosed method. Otherwise show the actual constraint: unavailable collateral capacity, lower LLTV, wider quoted spread, or manual-reporting exception.

## 5. Is the leverage theory sound?

It is plausible, not established.

It becomes true when all three conditions hold:

1. A demand-side actor can name material capital they would allocate or business they would route.
2. The issuer can attribute that demand to its product and capture the resulting issuance, AUM, spread, or redemption revenue.
3. The requested activation is cheaper and less risky than leaving the demand unmet.

It is false when the issuer sees no incremental issuance, demand is fragmented, the asset can be used through an alternate venue, or activation expands regulatory/custody liability more than it improves distribution.

There is some support for the direction: Morpho and Backed explicitly described active lending markets as important for RWA adoption and positioned bToken collateral as a demand unlock. [Morpho’s Backed market announcement](https://morpho.org/blog/lending-markets-for-backed-btokens-live-on-morpho-blue) But that was coordinated supply-side integration, not evidence that public downstream pressure caused an issuer to act.

There is also a weakening fact: Backed already deployed proof-of-reserves infrastructure using an issuer-provided attestation API and Chainlink, specifically to let third parties build mechanisms around its assets. [Backed PoR description](https://backed.fi/news-updates/chainlink-proof-of-reserve-is-now-active) That shows issuer-supplied data can enable composability. It does not show a registry can induce it.

So: use demand-side conditional interest as evidence to approach an issuer later, but do not model it as leverage until a buyer attaches a number.

## 6. The wrapper, reconsidered

The lender being the adopter changes the conclusion from “reject” to “possible alternate product path.”

A lender can recognize a wrapper as collateral. But the wrapper creates a new asset with new risks:

- wrapper custody and smart-contract risk;
- the wrapper’s legal claim versus the bToken holder’s claim;
- whether the wrapper itself, liquidators, and redeemers satisfy issuer eligibility restrictions;
- whether a freeze, blacklist, redemption suspension, or transfer restriction traps collateral;
- added audit, governance, and liquidity fragmentation.

For Backed specifically, the legal structure and transfer/restriction regime are part of the asset, not implementation details; bTokens are structured products with jurisdictional restrictions, and the prior Morpho example involved a permissioned wrapped bToken. [Backed product structure](https://assets.backed.fi/structure), [Morpho’s wbIB01 example](https://morpho.org/blog/lending-markets-for-backed-btokens-live-on-morpho-blue)

A wrapper can make a lender’s policy programmable. It cannot make issuer reserve, redemption, or legal-status facts true or observable. It is therefore a separate collateral product, not a shortcut to CDP adoption—and too large for the 27-day test.

## 7. Honest failure mode

If no demand-side party says anything public by Day 27, the project has:

- a reusable collateral-admission packet;
- an evidence-grounded registry of where live assets are usable, conditionally usable, or ununderwritable;
- conformance vectors and a reference integration path;
- a documented map of the exact issuer facts that block collateral capacity.

It does **not** have traction, a validated buyer, proof of willingness to integrate, or proof that demand-side pressure moves issuers.

That is still a useful research and due-diligence asset. It is not yet a company signal.