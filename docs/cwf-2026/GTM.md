# Go to market, demand validation, distribution

A required field on the submission form ([`CRITERIA.md`](CRITERIA.md)) and unwritten until
2026-09-19. Everything here is answerable from what runs; where it is not, it says so.

**Traction is zero.** Nobody outside this repository has used any of it. That is the first sentence
because it is the one a reader will otherwise spend the whole document looking for.

## Superseded 2026-09-20 by the pivot, and kept rather than deleted

**Everything below is about selling a loan.** Confide stopped being a loan on 2026-09-20: a loan
needs a third party to hold the collateral, that party needs a confidential account, and
`autoApproveNewAccounts` is false on 1,992 of 1,992 mints. A **trade** needs no third party, because
a Solana transaction cannot half-happen — so the swap runs where the loan could not, and the product
is confidential delivery versus payment.

**What that does to the go-to-market:**

| | before | now |
|---|---|---|
| first user | the lender, then the issuer as a gate | **a desk accumulating or unwinding size** — every purchase settles on chain, so the position is assembled in public and the price moves against it the whole way |
| what blocks it | the issuer's gate on the escrow's account | **nothing structural.** Both sides are ordinary associated token accounts. What is missing is matching and price, and matching is deliberately not being built |
| second user | — | **securities lending**, where lending your book is how you publish your book |
| the $0 | the whole argument | **still true and still measured**, but it is the collateral half. That half waits on a venue; the swap waits on nobody |

**And the timing changed under it, 2026-09-17.** The SEC exempted tokenized-stock venues for five
years, covering AMM-executed trading only, requiring every fill's size published within ten minutes,
and capping a Tier 1 name at 0.25% of average daily volume. The sanctioned venue publishes the size
by rule and cannot carry size anyway — [`../SEC-EXEMPTION.md`](../SEC-EXEMPTION.md).

**The analysis below is kept because it is still correct about the lender**, and because the
paid-path section at the end never depended on which half sells first. It is history, not a plan.

## The beachhead is not a protocol integration

This changed today, and it inverts what the month had assumed.

The month treated **Kamino as the first customer** and the pincer as the thing blocking the sale.
But the issuer gate turns out to be **per account and one-time, not per loan**
([`THE-PINCER.md`](THE-PINCER.md)): `SetAuthority` moves an already-approved confidential account
to a loan PDA and leaves the approval in place. So:

> **A holder whose confidential position sits in a token account with its own keypair can pledge it
> today, to anyone, without asking the issuer, Kamino, or us.** They hand the account over, a floor
> is proved over its ciphertext by Solana's own ZK program, and the collateral moves to the lender
> on a priced default or back to them on an attested release.
>
> **Corrected later the same day, and it costs most of the beachhead.** An *associated* token
> account carries `ImmutableOwner` and cannot be handed over at all — `SetAuthority` fails with
> `TokenError::ImmutableOwner`, measured by running it. Wallets create ATAs, so the reachable
> holder is the one whose position happens to sit elsewhere, and everyone else is back behind the
> issuer gate. See [`THE-PINCER.md`](THE-PINCER.md).

That is not a protocol integration. **It is a bilateral loan**, and it is exactly what
`./scripts/seizure-e2e.sh` has been demonstrating since it was written — one borrower, one lender,
one escrow, both endings.

**That is the beachhead.** Two parties who want a loan against a position neither of them wants
published, and who need no venue to exist.

### Why bilateral rather than a venue, in the buyer's terms

- **It is how illiquid collateral is actually lent against.** There is no continuous market for
  pre-IPO exposure and thin ones for most tokenized equity. Lending happens between two parties who
  agree terms, not on a book.
- **It needs no permission, so it can happen this week.** A venue needs a reserve, parameters, a
  risk owner, and a governance decision. A bilateral loan needs two signatures.
- **The unit of the product is the loan, not the integration**, so the first user can be one person.

### And why the venue work was not wasted

The capacity computation — **$23.2 m deposited and $84.0 m of borrowing authorised across Kamino's
tokenized-equity reserves, $0 of it reachable confidentially** — is not a sales pipeline. It is the
**size of the problem**, computed from someone else's numbers, and it is what makes a bilateral loan
worth building a primitive for rather than a contract. The packets are what a venue needs *later*.

**Stated plainly so it is not overclaimed:** nothing here gets a confidential position into a
Kamino reserve. The `$0` stands.

## Who the first users are, ranked by how little has to change for them

| | who | what they already have | what they still need |
|---|---|---|---|
| 1 | a holder whose approved position is in a **non-ATA** account | the account, already approved and pledgeable | a lender who will underwrite on a proved floor |
| 1b | a holder whose position is in an **ATA** — the common case | the position, and `spl-token transfer --confidential` | a lender willing to open the escrow and attest the floor |
| 2 | a **fund or desk** wanting a loan without publishing its book | the position, publicly held | to configure confidentially — one issuer approval |
| 3 | a **vault curator** | capital and a mandate | everything in [`THE-PINCER.md`](THE-PINCER.md): a venue-side integration |

**Row 1 needs nobody's permission and is rarer than it sounds. Row 1b is most holders, and as of
2026-09-19 it runs** — the lender opens the escrow, hands it to the loan PDA empty, and the holder
moves the position in with the ordinary CLI ([`THE-PINCER.md`](THE-PINCER.md)). **Row 3 needs a
protocol's roadmap.** The month was written for row 3 and the mechanism was always row 1.

**Row 1b costs the proved floor**, and that is the whole of what it costs: the escrow's keys are
the lender's, so the floor is attested by the lender rather than verified by the chain. For a
lender pricing their own risk that is no loss. It means such a loan cannot be shown to a third
party, and `lender-check.sh` prints that rather than hiding it. **The bilateral buyer is unaffected;
the syndication buyer is not reachable this way.**

## Demand validation — what has been done, and it is very little

**Done:** the problem is measured rather than asserted. 1,992 mints across three issuers ship
confidential transfers with the auditor key empty; 19 Kamino reserves lend against these tokens
today; `$0` of that is reachable confidentially. Every figure recomputable by a stranger from live
chain data.

**Not done:** nobody has been asked whether they want it. No pilot, no interview, no design partner,
no letter of intent. **The measurement establishes that a gap exists, not that anyone will pay to
close it**, and those are different claims.

**Why no interviews:** individual outreach was retired on 2026-09-18 by the founder. That is a
decision with a cost, written down where it was made ([`../27-DAYS.md`](../27-DAYS.md)): a public
post produces silence or arrivals, never a refusal with a reason attached, and a reason is the more
useful of the two.

**What would count**, so the bar cannot move later:

- somebody outside this repository runs `./scripts/packet.sh` or opens the decision page **and then
  does something with the answer** — cites it, disputes it, asks for a mint it does not cover
- a holder pledges a real position bilaterally
- a risk owner or issuer responds to the compatibility verdict, in either direction
- **a refusal with a reason** — information; silence is not

None has happened. If none has by 10-12, the submission says zero.

## Distribution

One channel, by decision rather than by default.

**Public, one-way, no addressee.** The artifact is a URL anyone can open —
`psyto.github.io/confide/kamino.html` — reading any of the 1,992 mints from mainnet in the reader's
own browser. The post that carries it is drafted in [`POST.md`](POST.md), leads with the Kamino
pincer, concedes their refusal is correct underwriting before saying anything about the gap, and
asks for nothing.

**No individual outreach**, including DMs of the link, which is the same act under another name.

**Measured as distribution learning, never as traction.** `./scripts/reach.sh` snapshots GitHub
traffic into a committed file, because GitHub keeps fourteen days and judging runs past that. The
decision page itself is deliberately uninstrumented, and [`REACH.md`](REACH.md) says why: counting
its readers means publishing them to a third party, which is a small version of the thing the page
argues against.

**Forecast, so the result can be wrong rather than reinterpreted:** one post, no network, no
amplification. A handful of readers, most of whom will not open the page. **A reply that engages
with the compatibility verdict is the outcome worth having**, and its probability is not high.

## The paid path, and the honest state of it

**There is no revenue and no price has been tested.** The candidates, in the order their buyers
already pay for something of that shape:

1. **The decision surface as risk tooling.** Venues and curators already pay for data and risk
   analytics. The packets and the registry are that shape, and unlike the mechanism they need no
   integration to be useful.
2. **Integration of the settlement primitive**, paid as work, when a venue wants confidential
   collateral to be admissible. This is the largest and the furthest away — it is row 3.
3. **A fee on settlement.** Listed last deliberately: it requires volume that requires row 1 to
   work at scale, and a fee on a primitive nobody yet uses is a spreadsheet, not a business.

**Which of these is real is exactly what has not been validated**, and no number in this document
depends on one of them being chosen.

## Scope: one wedge, and what stays out of it

Stocklana's own instruction is *"pick one wedge and make it excellent."* The wedge is **collateral —
proving, holding and settling a position without publishing it.**

So `confide-embargo` stays out of the pitch, and this is a decision rather than an oversight. It is
the other half of what is built: a disclosure sealed now and opened at a fixed time by a committee
the holder cannot stop, bound to the position actually held. It serves a different buyer — a fund
reporting to its LPs — and putting two products in one submission halves both.

**It appears once, and only as evidence of the one thing it is evidence of:** that the underlying
capability is *disclosure scoped by recipient, by granularity and by schedule*, and that the
collateral wedge uses two of those three. **A primitive with a second demonstrated use is a
different claim from a trick with one**, and it costs a sentence to make.
