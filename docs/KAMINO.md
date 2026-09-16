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

**And the check runs on the user's own account, not only on the reserve's vault.** That is what
makes it a gate on the counterparty rather than on the protocol's own bookkeeping:

`lending_checks.rs:186` deposit · `:102` withdraw · `:60` borrow · `:255` and `:260` liquidation,
both sides · `handler_init_reserve.rs:65` reserve creation.

So the rule is uniform: **a holder whose position is confidential cannot deposit it, cannot borrow
against it, and cannot be liquidated out of it.** The same four lines decide all three.

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
| deposited across them | **≈89,195 tokens** |
| LTVs, chosen by whoever owns those markets | **30 % – 73 %** |
| held confidentially | **0** |

`SPYx` at 73 % LTV against a 20,000 cap with 5,221 deposited. `GOOGLx` at 60 % with 8,010 of
12,000. `MSTRx` at 30 % with 29,660 of 90,000. These are underwriting decisions someone already
made, with real money behind them.

**And SpaceX has a reserve already.** Backpack's `SPCX.US`:

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

**Every one of those 89,195 deposited tokens is a public position.** A holder who does not want
that has exactly one option today, and it is not to post the collateral.

## What this establishes, and what it does not

**Established.** The conditions are exact, they are in production code, they are citable, and they
are checkable by anyone in about ten seconds. The asset clears everything else. The gap is
confidentiality alone.

**Not established, and not to be claimed:**

- **That the empty SPCX reserve is empty because of confidentiality.** It holds 0.1 tokens; so do
  the other two Backpack reserves, while Backed's thirteen hold real balances. The likeliest
  explanation is that Backpack's tokenized stocks are newer and thinner, not that privacy is the
  binding constraint. **Nothing here should be read as "demand is being suppressed"** — that is a
  hypothesis this repository cannot test.
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
