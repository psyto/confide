# Recording sheet

Eight silent clips in this folder, in order. One line each. Lengths are the clip's actual
duration; the narration figure is how long that line took in the first recording.

**Only `03-empty-slot` needs a new take.** Backpack Securities turned out to be a second issuer
leaving the same slot empty, so that scene was re-cut (16.60s to 22.80s) and now says 1,869 across
two issuers instead of 732. Every other clip is visually identical to the take its line was
recorded against — checked by comparing frames, not assumed.

`narrated/` holds those seven clips with the original voice already on them, lifted out of
`../Confide_Stocklana_20260913.mp4` by `../lift-narration.sh`. Each was checked individually: the
cut points fall inside silence with at least 0.36s of margin, so no word is clipped.

---

### 0:00 · `01-title.mp4` · 9.60s

> If you hold tokenized stocks on Solana, everyone can see your position. Nobody attacked anything. The chain simply publishes it.

*9.03s measured · 0.57s tail · audio reusable*

### 0:09 · `02-leak.mp4` · 12.50s

> Here is a fund buying NVIDIA through one quarter. Every purchase readable the moment it settles — not after the position is built, but while it is still being built.

*11.93s measured · 0.57s tail · audio reusable*

### 0:22 · `03-empty-slot.mp4` · 22.80s — **RE-RECORD**

> Solana already shipped the fix. Every tokenized stock here has confidential transfers switched on — eighteen hundred and sixty-nine of them, from two issuers with nothing to do with each other. And every single one leaves the auditor key empty, because the only key on offer reads everyone's everything, forever.

*Previous take ran 16.07s in a 16.60s clip. The new clip is 22.80s and the line is
longer; 21.13s is the estimate at the rate the first recording actually ran
(142 wpm), leaving 1.67s of slack. Long is a beat of silence,
short is a white gap.*

### 0:44 · `04-four-views.mp4` · 15.10s

> Confide fills that slot properly. The market sees nothing. A lender learns one bit: the collateral covers the loan. Your auditor sees the position in full. You choose who, how much, and when.

*14.43s measured · 0.67s tail · audio reusable*

### 1:00 · `05-benefits.mp4` · 19.00s

> Your position stops being public, and you can still prove what you need to. Last quarter's number cannot be tidied afterwards — it is sealed on the reporting date and opened by people you do not control. A stock split does not corrupt what you already disclosed.

*18.43s measured · 0.57s tail · audio reusable*

### 1:19 · `06-live-account.mp4` · 10.60s

> This is a real account, right now. The chain says it holds nothing. It holds a hundred and seventy-three thousand shares.

*10.00s measured · 0.60s tail · audio reusable*

### 1:29 · `07-proofs.mp4` · 14.00s

> And this is the lender's check, running on Solana's zero-knowledge program. Two proofs, both accepted — the chain confirmed the collateral covers the loan without ever being told what is in the account.

*13.47s measured · 0.53s tail · audio reusable*

### 1:43 · `08-close.mp4` · 9.20s

> Your position is yours. And you can still prove what you must. Try it yourself — no wallet, no install.

*8.57s measured · 0.63s tail · audio reusable*

---

Total **1:52**. Direction for each line — where to pause, what to let land — is in
[`../voiceover.md`](../voiceover.md).

The narration must never say you can *borrow* against the position, only that a lender can
*check* it. Seizure on default does not exist in this build. The published cut said "you can still
borrow against it" and that was wrong.
