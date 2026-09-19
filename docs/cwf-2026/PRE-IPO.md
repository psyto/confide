# Pre-IPO — does Confide reduce the risk, or only hide it?

Asked by the founder 2026-09-19: lending against unlisted shares is riskier than against listed
ones, so **does Confide help with that risk, or is it beside the point?** Worth answering carefully,
because "privacy makes risky collateral safer" is the kind of sentence that sounds good and is
usually false.

Everything measured below was read off mainnet on 2026-09-19. Everything argued is marked as
argument.

## Measured first

### The three SpaceX tokens are not the same asset, and the differences are on chain

| | issuer | what the holder has | authority keys | transfer fee |
|---|---|---|---|---|
| `SPCXx` | Backed | a tracker certificate, not the share | **3** (4 / 2 / 1 powers) | none |
| `SPCX.US` | Backpack | convertible to a securities entitlement | **2** (6 / 1 powers) | none |
| `SPACEX` | PreStocks | **1:1 SPV exposure tracking the private company** | **1 — nine powers** | **50 bps, active** |

**PreStocks concentrates nine powers in one key**, `WV9PJN7XTmTL…`: freeze, permanent delegate,
pausable, transfer hook, transfer-fee config, withheld-fee withdrawal, the confidential-transfer
mint authority, the confidential-transfer fee authority, and the metadata pointer. Backpack splits
the same surface across two keys and Backed across three.

For a lender this is the dominant counterparty risk in the row, and **Confide does not reduce it by
one basis point.** What Confide does is put it on the page where a risk owner meets it before they
price anything — which is worth something, and is not risk reduction.

### And Confide cannot touch these tokens today

Not an opinion. `FEE_BPS=50 ./scripts/seizure-e2e.sh` mirrors a PreStocks mint on devnet and fails
**before any transfer is attempted**:

```
--- the escrow ---
  configure: ERR "Error processing Instruction 1: invalid account data for instruction"
                 InstructionError: [1, "InvalidAccountData"]
```

Cause, named rather than guessed: `crates/confide-ct/src/provision.rs` grows the token account for
`ExtensionType::ConfidentialTransferAccount` and nothing else. A mint with a transfer-fee config
also needs `ConfidentialTransferFeeAmount` on every account, so `ConfigureAccount` has nowhere to
write. And downstream of that, `transfer_instruction` builds the plain confidential `Transfer`,
where a fee-bearing mint needs `TransferWithFee` and its extra proofs.

**Two known changes, neither of them research.** They are simply not done, and until they are, every
sentence below is about a token Confide cannot hold.

### The fee is live

`transferFeeBasisPoints: 50`, `maximumFee: u64::MAX`, effective from epoch 1032. The chain is on
epoch 1037. **Uncapped 0.5 % on every transfer, including a seizure**, which means the collateral
that arrives at default is smaller than the collateral that was proved — a thing a floor proof
currently does not account for.

## Now the argument, and it is argument

### Why the fit may be better here than for listed equity

The founder's instinct looks right, for a reason that inverts how this repository has been framing
SpaceX. [`27-DAYS.md`](../27-DAYS.md) calls it *"the hardest first asset, not the most compelling
one"* — pre-IPO, no continuous price, redemption through a broker. That is true about **admission**.
It may be backwards about **fit**:

> **Lending against an unlisted asset is underwritten on quantity, not on continuous price.** There
> is no market to mark against and nothing to liquidate into intraday, so the lender's protection is
> holding far more units than the loan needs and being able to take them. That is a *floor*, and a
> floor proved over a ciphertext — **"this account holds at least X"** — is the exact shape of that
> assurance.
>
> For a listed stock the lender can read a price and a public balance, so confidentiality is pure
> cost to them. **For a pre-IPO name the lender is already underwriting on a floor**, and Confide
> lets the floor be established without the position being published.

Two more, weaker but real:

- **A visible pledged position in an illiquid name is itself a hazard.** Everyone can see what will
  be dumped and roughly when. The forced sale is predictable and front-runnable, which worsens
  recovery **for the lender**, not only privacy for the borrower. That risk scales with illiquidity,
  so it is larger here than in listed equity.
- **Non-cooperative seizure matters more without an exchange.** The lender needs the asset in hand,
  not a market order. Confide's seizure is possession without the borrower's signature, which is
  what recovery looks like when there is nowhere to sell.

### What it does not fix, stated so nobody has to find it

- **No price.** PreStocks publishes `markPrice` and `tokenPrice` through its own API. That is the
  issuer's mark, not a market, and any LTV rests entirely on it. Confide creates no feed and the
  price refusal in [`27-DAYS.md`](../27-DAYS.md) still stands.
- **No liquidity.** Nothing here makes an unlisted share sellable.
- **No relief from the pincer.** PreStocks sets `autoApproveNewAccounts: false` like everyone else,
  so the issuer gates every escrow — **the same key that holds the other eight powers.**
- **The nine-in-one key.** Surfaced, not reduced.

## The honest one-line answer

> **Confide is a better fit for pre-IPO collateral than for listed collateral, and it currently does
> not work on it at all.** The fit is an argument; the not-working is measured.

## What would have to happen

Ranked, and none of it is speculative:

1. `provision.rs` allocates `ConfidentialTransferFeeAmount` when the mint carries a fee config.
2. `transfer_instruction` builds `TransferWithFee` on a fee-bearing mint, with the fee sigma proof.
   **The seizure's floor arithmetic then has to account for the fee**, or the lender receives less
   than the amount that was proved.
3. An admission packet for an asset **with no reserve anywhere** — which is the pre-IPO case, and
   which `packet.sh` currently refuses (`no Kamino reserve for %s`). The useful document for an
   unlisted asset is *"no venue has admitted this; here is what admission would require"*, and that
   is a different shape from the fourteen that exist.

## On the bounty — declined 2026-09-19

Two reasons, either of which is enough.

**The eligibility clause.** *"Projects that integrate any non-PreStocks pre-IPO tokens will be
ineligible."* Confide's page and packets cover Backed's `SPCXx` and Backpack's `SPCX.US`, both
pre-IPO. **Dropping them to qualify is refused** — the Clawpump reasoning in
[`../../STATUS.md`](../../STATUS.md): retracting a written judgement for a prize, where a judge
reading both notices the retraction more than the prize.

**And the ask does not match what this is.** The bounty wants ideas that *"drive value for
PreStocks"* and offers an ecosystem listing to projects that continue afterwards. A submission whose
most interesting result is that a feature on their mints does not execute is not that, however
carefully it is worded and however true it is. **Entering it would be asking a sponsor to fund a
report on their own product.**

The work was still worth doing. Step 1 is in and every analysis surface is honest across all 1,992
mints — that is the return, and it does not need a prize attached.

---

## Step 1 is done — 2026-09-19

`provision` now allocates `ConfidentialTransferFeeAmount` when the mint carries a fee config, and
the flag is **required** rather than defaulted, because a default of "no fee" is wrong precisely on
the mints where being wrong costs most, and wrong silently. The scripts read the mint and say which.

Measured on devnet with a 50 bps mirror, `FEE_BPS=50 ./scripts/seizure-e2e.sh`:

```
configure ok · approve ok · deposit ok · apply ok · 10 context txs ok
handover ok · originate ok — proved floor 100000 tokens against a $50000 loan at 200%
seize at 99c: ERR InstructionError [1, "InvalidInstructionData"]
```

**So a PreStocks token can now be held confidentially and have a floor proved over its ciphertext.**
The analysis half — the decision page, the packets, the capacity computation — works on all 1,992.
What still fails is settlement, and it fails in exactly one place: the confidential `Transfer`.

A regression caught by re-running the ordinary path: `"${FEE_ARGS[@]}"` on an empty array is unbound
under `set -u` in bash 3.2, so the change broke the **default** route and only the default route.

## Step 2, sized properly

`inner_transfer_with_fee` needs **five** proof contexts where `inner_transfer` needs three: the
equality and 3-handle validity proofs are the same, and it adds a **percentage-with-cap fee sigma
proof**, a **2-handle fee ciphertext validity proof**, and moves the range proof from **U128 to
U256**.

The wall this looked like it would hit is smaller than feared. Measured with `size_of`:

| | bytes |
|---|---|
| `BatchedRangeProofU128Data` | 1,000 |
| `BatchedRangeProofU256Data` | **1,064** — 64 more, not double |

The U128 verify transaction already runs at **1,211 bytes against the 1,232 limit** with a lookup
table. Sixty-four more is **1,275 — over by 43**, which is a packing problem and not a research one:
two more addresses in the lookup table buy back about sixty.

So step 2 is roughly a day or two of careful work, not a wall:

1. `seizure-ctx` builds five transfer contexts instead of three, and the lookup table takes two more
   addresses so the U256 verify transaction fits.
2. The loan record grows by two context pubkeys **per route**, so 740 bytes becomes 868 — appended
   again, so a v1 and a v2 loan both stay readable.
3. `transfer_instruction` calls `inner_transfer_with_fee` when the mint charges one.
4. **The underwriting change, which is the part that is not plumbing.** See below.

## What the fee means for underwriting, and why this is the answer to the original question

`MAX_FEE_BASIS_POINTS` is **10,000 — one hundred per cent.** The `transferFeeConfigAuthority` on
PreStocks' mints is `WV9PJN7XTmTL…`, the same key that holds the other eight powers.

> **The issuer can set the transfer fee to 100 %, and a seizure then delivers the lender nothing.**
> Not a rounding error on 50 bps — a power to make pledged collateral worthless, held by one key,
> exercisable with a two-epoch delay.

`in_default` today computes `q_min × price` and compares it to the required cover. On a fee-bearing
mint the lender does not receive `q_min`; they receive `q_min × (1 − fee)`. So the design is:

- the loan records **`max_fee_bps`**, the fee the lender underwrote at origination
- `seize` reads the **live** fee off the mint, which is already passed into the instruction
- the recoverable amount is netted: `q_min × (10,000 − fee_bps) / 10,000`
- and **"the issuer raised the fee above what we underwrote" becomes a default condition of its
  own** — the collateral has been devalued by a third party, which is exactly when a lender wants
  out

**That is the answer to the founder's question, and it is not "privacy makes risky collateral
safer".** It is narrower and it is real: an unbounded, invisible issuer power becomes a **bounded,
monitored loan parameter**. Confide does not reduce the issuer's power. It makes exercising that
power trip the loan instead of silently emptying it.

---

## Step 2 — wrong twice, and the second correction is the founder's — 2026-09-19

### What I claimed

That `TransferWithFee` is **unreachable on Solana**: its range proof is `BatchedRangeProofU256`,
whose verify transaction is 1,269 bytes in its smallest form against a 1,232-byte limit, with
nothing left to move into a lookup table. I had the official `spl-token` CLI failing on the same
mint as corroboration, and I proposed recording it as a platform finding.

### Why it is wrong

**The founder asked whether this should be reported to the people who build Token-2022.** Checking
whether it was already known is what found the mistake, before anything was sent anywhere.

The ZK ElGamal Proof Program's verify instructions accept **four** account layouts, not two. I had
read `ProofLocation` in the *extraction* crate — which says where **Token-2022** finds the proof
*context* — and taken it for the whole story. The proof program's own documentation says:

> **4. Proof in account, with context state:**
> — `[]` Account to read the proof from
> — `[writable]` The proof context account to create
> — `[]` The proof context account owner
>
> The instruction expects either: i. the proof data if provided as instruction data, or
> **ii. a `u32` byte offset if the proof is provided as an account**

**The proof does not have to travel in the transaction.** It is written into an account first — the
reference client uses `spl-record` and chunks it across several transactions
(`confidential_transfer_create_record_account`, `generate_split_transfer_with_fee_proof_data`) —
and the verify instruction then carries four bytes.

### What survives

The measurements were right; the conclusion drawn from them was not. They now explain **why the
record-account path exists** rather than pretending nothing does:

| proof | verify tx, proof in instruction data | fits in 1,232 |
|---|---|---|
| equality / 3-handle validity / percentage-with-cap / 2-handle validity | 531–755 | yes |
| **`BatchedRangeProofU256`** | **1,269 at best** | **no** |

So on a fee-bearing mint the range proof **must** go through a record account. That is a real extra
step and it is why this is more than swapping one instruction for another.

And the CLI observation stands as what it is: `spl-token transfer --confidential` builds the
fee-free instruction and fails on a fee mint. That is a **known CLI gap**, tracked as
`solana-program/token-2022#861`, not evidence of impossibility.

### Nothing gets reported

There is nothing to report. The behaviour is designed for, documented in the proof program's own
instruction docs, and implemented in the reference client. **A finding about someone else's
platform, drawn from two measurements and an unread third page, would have been wrong in public** —
and it would have been sent to the people who wrote the page I had not read.

### So step 2 is open again, and larger than first sized

1. `seizure-ctx` builds five transfer contexts instead of three.
2. The range proof goes into a record account in chunks, then a verify instruction reads it by
   offset. **New machinery: a record account per proof, its lifecycle, and its rent.**
3. The loan record grows by two context pubkeys per route.
4. `transfer_instruction` calls `inner_transfer_with_fee` when the mint charges one.
5. The fee is netted from the recoverable amount, and `max_fee_bps` comes back — a seizure on a
   fee-bearing mint delivers less than the floor that was proved.

**Not a day or two.** Whether it is worth it against 23 days and the unbuilt submission deliverables
is the founder's call, and the honest input is that step 1 already made every analysis surface true
across all 1,992 mints, while step 5 is the only part that changes what a lender is protected from.
