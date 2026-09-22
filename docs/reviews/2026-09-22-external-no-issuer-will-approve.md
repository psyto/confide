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
