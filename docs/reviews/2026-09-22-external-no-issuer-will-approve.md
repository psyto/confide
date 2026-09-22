# The first correction from outside this repository — 2026-09-22

The X post of 2026-09-21 drew a reply from **@KirProzorov**:

> "No issuer will approve one" is a bit early if you haven't asked any issuers yet.

**They are right, and the post ends by asking for exactly this** — *"If I have read Kamino's source
wrong, or the count is wrong, I would much rather hear it from you than from a judge."* Nine reviews
so far have been ones this project commissioned. This one was not, and it cost a stranger nothing to
be right about.

## What was measured, and what was asserted

| | |
|---|---|
| **Measured** | `autoApproveNewAccounts` is **false on 1,992 of 1,992** mints, and of **465,520** live token accounts **none** carries `ConfidentialTransferAccount`. Both re-run by `./scripts/slot-scan.sh` and `./scripts/usage-scan.sh` |
| **Asserted** | that an issuer **will not** approve one |

The measurement says **nobody has been through that door**. The assertion says **the door is
locked**, and nothing in this repository establishes it — because **nobody has asked an issuer.**
It is the repository's own recorded failure, in its purest form: *a claim with no command under it.*

**The worst part is that the right wording already existed.** `_submission/full.md` has said, since
before the post, *"on `NVDAx` it is a conversation nobody has had"* — and *"the gate needs the
issuer's signature to open one and nobody has asked"*. The honest sentence was written, and four
other surfaces carried the overclaim anyway.

## Where it was, and what could be done about each

| surface | state |
|---|---|
| `_submission/cwf-form.md` | **corrected** — the field now separates the two, 970/1000 |
| `_submission/youtube-checkin1.md` | **corrected** — the check-in video's description is editable |
| `docs/cwf-2026/x-post.txt` | **frozen.** It records what was posted; rewriting it would erase the thing that was corrected |
| `video/CHECKIN-1.md` and its clips | **cannot be changed.** Check-in 1's window closed 09-21 08:00 PDT. The recording says it and will keep saying it |

**Two of the four are permanent.** That is the cost, and it is worth writing down: the claim went
into a submitted video and a posted thread before anybody checked whether it was a measurement.

## The wording now

> `autoApproveNewAccounts` is false on all 1,992 mints — so a confidential account exists only if an
> issuer signs for one, and across 465,520 live accounts none has. **I have not asked an issuer, so
> I cannot say they would refuse; what is measured is that nobody has been through that door.**

It is shorter on claim and longer on evidence, which is the trade this repository says it wants.

`scripts/docs-consistency.sh` now fails on *"no issuer will approve"* and its variants across every
submission surface, and was broken on purpose to prove it.

## What this does not change

The gate is still shut, the count is still zero, and the argument that there is **no incumbent** is
untouched — it rests on nobody having done it, not on nobody being able to. **Asking an issuer is
now a thing worth doing rather than a thing assumed answered**, and it is already the first item
under *what is not built*.

---

## Eight hours later, somebody configured one

**2026-09-22 08:26, re-measured before a paste.** Of **469,477** live token accounts, **two** now
carry `ConfidentialTransferAccount` — both on `NVDAx`, and **neither is approved.**

| | |
|---|---|
| `5jkuoj8UcgRCVgJo2TGXxDRDxL4DAioCbmhkTugaAxW2` | configured 2026-09-19 |
| `8P31wJSdNfNyVYCSG4dLUJknJi6EWZyYjCVFDhPJKNEu` | configured **2026-09-21 23:01 UTC**, after two attempts that failed with `IncorrectProgramId` |

The second appeared **after the 09-21 22:18 scan that read zero.** The post went out 09-21 00:37
UTC; that is a sequence and not a cause, and this file will not claim otherwise.

**This is the reply's point arriving as a measurement.** *"No issuer will approve one"* was a
prediction. What the chain now shows is somebody pressing on the door — twice failing, then getting
the account configured — and the door not opening. `approved: false` on both: neither can receive a
confidential transfer until Backed signs, and Backed has not.

**The headline moved from one count to the next.** It was *"zero are confidential"*. It is now
**"two have configured one, zero are approved"** — weaker on nothing, and better evidence that the
gate is real, because somebody other than the author is now standing at it.

`usage-scan.sh` counts both numbers separately from today, because a script that counted only the
extension would have reported the finding as broken on the day it was actually confirmed.

---

## "They appeared after the SEC order — does that mean something?"

The founder's question, and the answer starts with what cannot be answered.

### The hypothesis cannot be tested with this repository's measurements

**Every account scan here postdates the order.** The SEC published on **2026-09-17**; the earliest
scan committed is **2026-09-20 01:00 UTC**. There is no *before* to compare a *after* against.

| scan | accounts | configured |
|---|---|---|
| 2026-09-20 01:00 | 329,536 | 0 |
| 2026-09-20 11:40 | 330,266 | 0 |
| 2026-09-21 22:03 | 384,181 | 0 |
| 2026-09-21 22:18 | 465,520 | 0 |
| **2026-09-22 08:26** | **469,477** | **2** |

The counts climb because the scan's reach grew, not because the chain did — `SPCX.US` became
readable on 09-22 and the sample was corrected on the way. **What is comparable across all five is
the confidential column**, and `NVDAx` held **28 accounts over 400 bytes** in every scan up to
09-21 22:18 and **30** on 09-22.

### What the chain gives instead, and it is tighter than days

Both accounts were configured **on the same night, 49 minutes apart**:

| | |
|---|---|
| `8P31wJSd…` | **2026-09-21 23:01 UTC**, after attempts at 21:56 and 22:39 that failed `IncorrectProgramId` |
| `5jkuoj8…` | **2026-09-21 23:50 UTC** — the account itself dates from 09-19, but the `ConfigureAccount` is that night |

The scan that read **zero** ran at **22:18**, forty-three minutes before the first of them.

**Four days of nothing and then two inside an hour is not the shape of a market reading a
regulation.** A rule that changes what firms do changes it over weeks, through different issuers and
different mints. This is one evening on one mint.

### Who did it

- **Two distinct wallets**, both active since **2024** — 389 and 114 transactions. Not fresh keys.
- **Each paid its own fee.** Nothing forces them to be one person and nothing rules it out.
- **Both transactions ran through the same program**, `L2TExMFKdjpN9kozasaurPirfHy9P8sbXoAN1qA3S95`
  — which turns out to be **generic infrastructure**, not confidential-transfer tooling: sampled
  transactions of it do Withdraw, Sell, Claim, Wormhole `InitEncodedVaa` and ORE, and it handled
  **1,000 transactions in eight minutes** on the morning this was written. Two people using the same
  relayer is two people using the same wallet app.

### The nearest event in time is not the order

The post went out **2026-09-21 00:37 UTC**, **about 22 and a half hours** before the first
configure, and it names the exact thing these two accounts did. **That is a sequence. This file does
not call it a cause**, for the same reason it does not call the SEC one: nothing here can see a
motive, and the last claim that outran its evidence cost two artifacts that can never be corrected.

### The test, and it runs itself

> **If the order is the cause, the count keeps climbing** — over weeks, across other mints and other
> issuers, from wallets with nothing in common.
>
> **If one prompt reached two people on one night, it stops at two.**

`usage-scan.sh` stamps every run, and from today counts **configured** and **approved** separately.
The question is therefore not settled by argument but by re-running it — the shape the founder asked
for when they said a measurement is a baseline and not a verdict.

**And the column that decides the project is still the second one.** Two knocked; `approved` is
**0**. If that ever becomes non-zero, `cwf-form.sh` fails loudly and every surface has to be rewritten,
because that is the day the gate opens and the argument genuinely changes.
