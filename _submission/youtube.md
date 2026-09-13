# YouTube

## Title — 68 / 100 characters

```
Confide — Every Tokenized Stock on Solana Has Privacy Nobody Can Use
```

## Description — 3776 / 5000 characters

```
All 1,869 tokenized stocks on Solana run on Token-2022 with confidential transfers switched ON — and every single one leaves the auditor key EMPTY. Two issuers, arriving there independently. The feature is shipped, configured, and unusable. Confide is what makes that slot usable.

▶ Try it live (no wallet, no API key, no install): https://psyto.github.io/confide/
▶ Code (Apache-2.0): https://github.com/psyto/confide

━━━━━━━━━━━━━━━━━━━━━━

CHAPTERS

0:00 Your position is public, and nobody attacked anything
0:22 1,869 mints, two issuers, every auditor key empty
0:44 The same position, seen four ways
1:00 What you actually get
1:19 A live account that reads as zero
1:29 The lender's check, verified by Solana

TWO ISSUERS, NOT ONE

Backed Finance issues xStocks — Swiss, with their own ISIN, a third-party product. Backpack Securities issues CUSIP-identified tokens the company calls bona fide security entitlements, which is the closer thing to the underlying share. They have nothing to do with each other.

Both run Token-2022 with confidential transfers on. Both gate who may open a confidential account. Both leave the auditor key null. 732 mints and 1,137 mints, checked rather than sampled.

One issuer leaving the slot empty is caution you could explain away. Two, independently — and the one with the stronger instrument arriving there too — is a missing piece.

WHY THE SLOT IS EMPTY

Token-2022 offers exactly one disclosure model: a single global auditor key that decrypts everyone's everything, forever. Fill it and every holder is permanently readable by one party. Leave it null and no holder can demonstrate anything to anyone.

So no setting of that key is correct — and a fund holding NVDAx broadcasts its position to the whole market instead. Not a choice about publicity. The only option under which it can still answer a question.

WHAT CONFIDE DOES

Disclosure scoped by recipient, by granularity, and — the part nothing else has — by schedule. The market sees nothing. A lender learns one bit: the collateral covers the loan. Your auditor sees the position. You choose who, how much, and when.

WHAT RUNS, ALL OF IT ON CHAIN

• A confidential position on devnet: spl-token balance returns 0, the account holds 173,000
• "This account holds at least X" proved over the account's OWN ciphertext — two proofs accepted by Solana's live ZK ElGamal Proof Program (VerifyCiphertextCommitmentEquality 6,400 CU, VerifyBatchedRangeProofU64 111,000 CU)
• The auditor slot filled by one UpdateMint on a mirrored mint
• A disclosure bound to a date: 147 bytes anchored, commitment matched on read-back
• Opening on schedule without the holder — five separate processes
• Restatement across a stock split that refuses rather than guessing

Every terminal pane in this video is the stdout of a command run moments before recording. Two of them reach mainnet and devnet. The recorder throws instead of recording when a command stops producing the line that carries its claim.

WHAT IS NOT BUILT

• Seizure. A lender can verify the collateral and still cannot take it on default. That is the distance between this and lending, and it is not small.
• On the live mints: both issuers set autoApproveNewAccounts to false, so opening a confidential account needs their approval. The accounts here are on a mint with the same configuration.
• No claim to discharge any filing. Whether CUSIP-identified entitlements change that is a question for counsel, not for me.

BUILT ON

Original work except where declared: aperture-core and aperture-receipts (Apache-2.0, my own pre-existing disclosure engine — https://github.com/psyto/aperture) and spl-token-2022-interface.

Built for Stocklana 2026.

#Solana #TokenizedStocks #RWA #ZeroKnowledge #Token2022 #DeFi #xStocks
```

## Notes

**Chapters are six, not eight, and the timestamps moved.** YouTube requires every chapter to run at
least ten seconds and **silently renders none at all** if one falls short — the title scene (9.6s)
and the close (9.2s) are each merged with a neighbour. Shortest chapter is now 10.6s. Timestamps
come from the measured scene boundaries of the current cut (1:52), not the previous one.

**The first two lines are what shows before "…more".** They carry the finding and the live link.

# Title alternatives, with what each trades away

CHOSEN (68 chars) — names the project and carries the finding
Confide — Every Tokenized Stock on Solana Has Privacy Nobody Can Use

A (75) — strongest hook, but the project name never appears
Every Tokenized Stock on Solana Has Privacy Switched On. Nobody Can Use It.

B (77) — most searchable, least arresting
Confide: Hold Tokenized Stocks on Solana Without Publishing Your Position

C (72) — leads on the number; risks reading as a data post, not a product
1,869 Tokenized Stocks on Solana. Not One Auditor Key Among Them.

