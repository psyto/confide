# Can Kamino take confidential collateral?

**`REQUIRES INTEGRATION`** — and the integration is one specific thing, not a list.

Reproduce it: `./scripts/kamino-verdict.sh`. It reads Kamino Lend at a pinned release and the two
SpaceX mints live from mainnet, and fails if any line it depends on has moved.

This was week 1's gate, and the answer had to be allowed to be unwelcome. It is not. It is sharper
than either outcome the plan anticipated.

## What was expected, and why it was wrong

The expectation was that Kamino would be indifferent to confidential transfers — that an ordinary
reserve reads a public balance, a confidential account's public balance is zero, and the collateral
would simply appear to be worth nothing. That reasoning is intact but it is not what happens,
because Kamino does not reach it. **It refuses the account first, deliberately, by name.**

## What the source says

Kamino Lend is open source. Everything below is `klend` at `a087609`, `release/v1.25.0`,
2026-08-18.

**The confidential-transfer extensions are on the allow-lists**, not absent from them:

| | |
|---|---|
| `constraints.rs:44` | `ExtensionType::ConfidentialTransferMint` — a supported liquidity-mint extension |
| `constraints.rs:61` | `ExtensionType::ConfidentialTransferAccount` — a supported liquidity-account extension |

**And every one of them is required to be inert:**

| | the condition | what it refuses |
|---|---|---|
| `constraints.rs:131` | `auto_approve_new_accounts` must be false | a mint that lets anyone open a confidential account without the issuer |
| `constraints.rs:187` | `allow_confidential_credits` must be false | an account that can *receive* value confidentially |
| `constraints.rs:194` | `allow_non_confidential_credits` must be true | an account that can only be paid confidentially |
| `constraints.rs:201` | `closable()` must succeed | an account holding **any** confidential balance — `closable()` requires `pending_lo`, `pending_hi` and `available` to all be the zero ciphertext |

**And the deposit check runs on the user's own account, not only on the reserve's vault** —
`lending_checks.rs:186` passes `accounts.user_source_liquidity`. That is what makes it a gate on
the counterparty rather than on the protocol's own bookkeeping, and it is the whole finding:

> **Kamino's ordinary deposit path rejects a token account carrying confidential value.**

Collateral that cannot get in cannot be borrowed against or liquidated, so those follow. **They do
not follow from separate checks on the holder's collateral account, and an earlier version of this
document said they did.**

> **Corrected 2026-09-16, same day, after review.** The claim here was that the same four lines
> gate deposit, borrowing and both sides of liquidation on the holder's collateral account. Reading
> the arguments rather than the call sites: **borrow** checks `user_destination_liquidity`, the
> account receiving the *borrowed* asset (`lending_checks.rs:60`); **liquidation** checks the
> *liquidator's* repay source and receiving account (`:255`, `:260`), not the borrower's collateral.
> Three citations were doing the work of one, and the one is enough.
>
> **The checks are also not uniform across every value-moving path.**
> `flash_repay_reserve_liquidity_checks` omits the extension check entirely while its handler
> transfers `user_source_liquidity → reserve_destination_liquidity`. In practice a flash repay must
> pair with a flash borrow, and *that* is checked on the receiving account — but "every path is
> checked" was never true and is not claimed here.
>
> Found by [the week-1 review](reviews/2026-09-16-codex-week-1.md). Its own line numbers for
> `constraints.rs` were wrong — it could not clone the repository and inferred them — and the ones
> in this document were verified against the file at the pin. The substance of the finding stands
> regardless.

**Two handlers do not run the check, and that was worth confirming rather than assuming.**
`deposit_obligation_collateral` and `withdraw_obligation_collateral` move the *collateral* token —
the cToken a reserve mints against a deposit — not the tokenized stock. That mint is created by
klend itself and its accounts are declared `Program<'info, Token>`, the **legacy SPL Token
program**, which has no extensions to carry. The check is correctly absent, and the cToken is
unreachable without first passing `deposit_reserve_liquidity`, which is checked.

Two composite handlers were also worth following: `deposit_and_withdraw` and
`repay_and_withdraw_redeem` do not call the check directly, they call the underlying handlers'
`process_impl`. The check lives **inside** `process_impl` rather than in the outer `process`, so
they inherit it. **"Every path is checked" would have been the wrong claim; this is the right
one.**

## What the asset says

Both SpaceX mints are Token-2022 with the confidential-transfer extension, read live from mainnet:

| | mint | decimals |
|---|---|---|
| Backed `SPCXx` | `Xs3oZwbHvqis4NYcf4YKWmEia2eC84wSiVrcYcTqpH8` | 8 |
| Backpack `SPCX.US` | `SPCXxcqXj6e5dJDVNovHN8744zkbhM2bYudU45BimGb` | 6 |

Each carries eight extensions. **All eight are on Kamino's allow-list, and every conditional one
passes**: `autoApproveNewAccounts` is false, the transfer hook has no program set, the default
account state is `initialized`, the mint is not paused, and there is no transfer fee.

**So Kamino could open a reserve for either of these mints today.** Nothing about the asset blocks
it. The gap is not Token-2022 support, not the issuer, not the extension set — it is the four
account-level lines, and only those.

That is a narrower and more useful statement than "tokenized equity is not lendable."

## Kamino is already lending against tokenized stocks

This was the assumption that most needed checking, and it turned out to be understated. Reading
every reserve the lending program holds — 591 of them across 172 markets — **19 have a tokenized
stock as their liquidity mint**, and they are not placeholders. `./scripts/kamino-reserves.sh`.

| | |
|---|---|
| live reserves for tokenized equity | **19** |
| of those, holding a real balance rather than a seed | **13**, all Backed's xStocks |
| available liquidity across them | **≈89,192 tokens**, plus ≈230 borrowed |
| LTVs, chosen by whoever owns those markets | **30 % – 73 %** |
| held confidentially | **0** |

`SPYx` at 73 % LTV against a 20,000 cap with 5,221 available and 121 borrowed. `GOOGLx` at 60 %
with 8,010 of 12,000. `MSTRx` at 30 % with 29,658 of 90,000. These are underwriting decisions
someone already made, and four of the rows have some of the **stock itself** borrowed out of them.

> **Corrected 2026-09-19.** This sentence read *"four of the rows are being borrowed against right
> now"*, which is a different trade: a reserve's `borrowed` field counts the token lent **out**, not
> stablecoin drawn **against** it. What has been borrowed against this collateral is the debt side
> of the same markets, and it is much larger — `./scripts/debt-side.sh`.

**"Available" is what sits in the vault at this snapshot, not what was supplied** — klend's own
total is available plus borrowed minus accumulated fees. Neither figure is a flow.

**And SpaceX has a reserve already** — though it is the blocked case rather than the control. Its
reserve holds 0.1 tokens and has never been refreshed, so it carries no price; the case where every
figure is real is [`NVDAx`](packets/NVDAx.md), which is also the mint the devnet mechanism mirrors.
SpaceX is here because **pre-IPO exposure is where a holder's reason not to publish is undeniable**,
not because its numbers are the strongest. Backpack's `SPCX.US`:

| | |
|---|---|
| reserve | `GrtBFz6BSky1PiyVBL7jy3w4Z1hKz2wvSjT4vd2iouC3` |
| market | `4iRHKGsTq3e4uut6e4PfyV9AEbNuXaMu9JaSP378p9qy` |
| status | Active |
| LTV / liquidation threshold | **40 % / 60 %** |
| liquidation bonus | 5 % – 10 % |
| deposit cap | **15,000 SPCX** |
| borrow limit | **0** — collateral only: deposit it, borrow something else against it |
| currently deposited | 0.1 |

So the packet is not asking anyone to consider a new asset class, or to pick an LTV for SpaceX.
**Both were chosen already.** The question it asks is narrower and much easier to answer: *the
holder who will not post this collateral publicly — what would it take to let them post it at all?*

**Every position in those reserves is public.** A holder who does not want that has exactly one
option today, and it is not to post the collateral.

## What this establishes, and what it does not

**Established.** The conditions are exact, they are in production code, they are citable, and they
are checkable by anyone in about ten seconds. The asset clears everything else. The gap is
confidentiality alone.

**Not established, and not to be claimed:**

- **Anything about *why* the SPCX reserve is nearly empty.** The disciplined statement is the
  observation and nothing else: at this snapshot all three Backpack rows hold seed-scale liquidity
  while thirteen Backed rows exceed one token. **"Privacy is the binding constraint" is untestable
  here — and so is "Backpack's tokens are newer and thinner", which an earlier version of this
  document asserted as the likely explanation.** Deciding between them needs reserve age, flows,
  holders, market-making and eligibility evidence, none of which is in this repository.
- **That Kamino wants to relax it.** Nobody at Kamino has been asked. These conditions are a
  reasonable design: a reserve that cannot read a balance cannot mark a position, and refusing what
  you cannot value is correct underwriting, not an oversight.
- **That this was read rather than run.** This is source at a pinned commit plus live mint state.
  No transaction was sent to Kamino. An executed test — a local validator with the Kamino program
  cloned, a confidential account, a deposit that fails with `UnsupportedTokenExtension` — would
  confirm the checks fire as read. It is the obvious next increment and it has not been done.
- **That Confide closes it.** See below: the shape fits, and the open questions are real.

## What the integration would be

A reserve that can value a balance it cannot read needs two things, and Confide has parts of both.

**A floor, proved.** Not the balance — a lower bound on it. `confide-seizure` already checks that
`C − q_min·G` range-proves to 64 bits against the escrow's own ciphertext, which establishes
`balance ≥ q_min` without revealing the balance. A reserve would value the position at
`q_min × price` and ignore everything above it. That is conservative by construction, and
conservative is what a risk owner wants.

**Custody that survives the holder.** A proved floor is worthless if the holder can withdraw below
it afterwards. Confide's `originate` verifies the escrow's SPL owner is the loan PDA before it
records anything, so the floor holds because the holder no longer controls the account.

**The open questions, stated rather than skipped:**

- **Re-proving.** A floor proved once is a floor at one moment. A reserve marks continuously.
  Either the floor is re-proved on a schedule the reserve enforces, or the position is valued at
  the last proved floor and the liquidation trigger accounts for the staleness. Neither is built.
- **Liquidation hand-off.** `deshield` is disabled, and finishing it is not the work — the work is
  that the destination has to be a Kamino liquidator, which means the seizure has to fit inside
  Kamino's liquidation instruction rather than beside it.
- **Whose account is the counterparty.** The escrow is PDA-owned and confidential, so it fails
  `constraints.rs:187` and `:201` by design. An integration either exempts a reserve-recognised
  escrow from those lines, or moves the value into a public account at deposit — which gives up
  the entire point.

**None of this is a claim that Kamino should do it.** It is the answer to "what would it take",
which is the question the packet exists to answer.

## Kamino rather than Morpho

The hope was that Confide could create a reason to do this on Kamino specifically. In its strong
form — *"a disclosure-conditioned admission is expressible on Kamino and not on Morpho"* — that was
[checked and found false](reviews/2026-09-16-codex-is-the-plan-enough.md): a curator declining to
supply a Morpho market expresses the same condition.

What is true after reading the source is narrower and better: **Kamino's program names the
confidential-transfer extensions and states the exact conditions under which it will not touch
them.** Morpho is EVM, where the extension does not exist, so the question cannot be asked of it —
that is an asymmetry in the asset class, not a verdict on Morpho's design.

**The reason to do this on Kamino is that Kamino is where the refusal is written down.** A gap you
can cite four line numbers for is a different object from a gap you have to argue exists.
