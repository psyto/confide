# Confidential issuance, and the gate as an error code — 2026-09-23

`./scripts/issue-e2e.sh`. Built to Codex's five conditions
([review](../reviews/2026-09-23-the-disclosure-frame.md)), which it meets, and to one it did not
ask for.

## Why this exists when the swap already settles

**On a real mint the swap cannot happen.** It needs two holders whose confidential accounts both
already exist, and `autoApproveNewAccounts` is false on all 1,992 — an account cannot exist until
the issuer signs for it, and across 469,477 live accounts **two have configured one and zero are
approved.** The hole is not in the cryptography. It is in who is standing at the door.

**Issuance closes it, because the party who opens the door is one of the two parties.** The issuer
allocates to an investor and also approves the investor's account. No matching — which is
deliberately not built and is the exchange definition at Rule 3b-16 — and no confidential account
has to exist beforehand.

## The run

| | |
|---|---|
| the investor opens an account | configured, **not approved** |
| the investor reads the allocation | 20,000 shares, decrypted out of the verified proof context, before signing |
| **the allocation is sent** | **REFUSED on chain** — `Custom(24)`, *Account not approved for confidential transfers* |
| the issuer signs for the account | one instruction |
| **the same allocation is sent again** | **settles** — `Transfer` + `TransferWithFee`, 2 signatures, 59,804 compute units |
| what moved | treasury 500,000 → 480,000; investor 0 → 20,000; investor cash 5,000,000 → 1,500,000; issuer cash 0 → 3,500,000 |
| what anybody else sees | **all four public balances `0`** |

**Both are on chain and either can be looked up:**

| | |
|---|---|
| refused | `5fqZLgbj3Sijft68iT9U3N8MNEitte4aLrPU6VdcQVytxAb389ZJSJMfHs68tLNYDwaUqSuA11agG7sXmP2HEV5G` |
| settled | `29coq95v2k4G2PBdcf42EtraqppMC4nk7QFsgHvMc9gbeCNPjPTYnM6kpza3EkeoeLuugUuPjaW32HefgNWCgxCf` |

The refusal is sent with **preflight off on purpose.** With preflight on, the RPC node simulates, returns
the error, and nothing lands — the refusal is then reproducible but not citable, and "run it yourself"
is weaker than a signature. Skipping preflight costs one fee and puts the refused transaction on chain
with its log attached:

```
Program log: ConfidentialTransferInstruction::Transfer
Program log: Error: Account not approved for confidential transfers
Program TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb failed: custom program error: 0x18
```

## The auditor slot is empty throughout

Both mints are created with **auditor `none`** — the configuration all 1,992 real mints carry. That
is not a shortcut around the disclosure problem, it is the reason this particular flow works today:

> **In primary issuance the issuer is the sender.** They can already read what they sent, so they
> need no auditor key to see it. The empty slot blocks the **secondary** market, not this one.

It follows that the flow which runs unchanged on a mint configured the way the real ones are is
**issuance**, and the flow that needs a disclosure mode Token-2022 does not have is **everything
after it**.

## What this does not show

- **The issuer here is a devnet testbed whose approval key this repository holds.** On `NVDAx` it
  would be Backed, and nobody has asked them.
- **No new cryptography.** The settlement is the existing four-message swap with the issuer as one
  party; what is new is that approval is inside the flow rather than assumed before it.
- **It does not solve scoped disclosure.** It sidesteps it — correctly, for this one flow.
- **Redemption is not built**, on Codex's advice: its supply-leak claim is configuration-dependent
  and this repository already lists the counterexamples in
  [`ISSUANCE.md`](ISSUANCE.md). A half-proved lifecycle would be a third claim that outran its
  evidence.

## The guard that keeps this honest

If the investor's account were approved before the allocation, the refusal would not happen and the
script would be demonstrating nothing while looking identical. So it **checks the landed error**, and
**exits 1** if the transaction settles when it should not have — saying that the gate not holding is
the finding, and not this script. Verified by flipping the approval on and watching it refuse to pass.

`refresh-swaps.sh` pins both transactions and asserts the refused one **still fails with
`Custom(24)`**. The day it starts succeeding is the day the gate stopped holding, and that should
arrive as a red line rather than as silence.
