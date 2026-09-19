//! Does the U256 range-proof verify transaction fit?
//!
//! The fee-free U128 one already runs at 1,211 bytes against the 1,232-byte limit, with a lookup
//! table holding the context account and its authority. U256 is 64 bytes more, and nothing else in
//! that transaction can move into a table — its only other static keys are the fee payer and the
//! ZK program id, and a v0 message may not source a program id from a lookup table.
//!
//! So this measures rather than argues, and the measurement says it does not fit — by 37 bytes in
//! its smallest form. That is why Confide settles nothing on a fee-bearing mint, and it is not a
//! Confide limitation: the official `spl-token` CLI fails on the same mint with
//! `ConfidentialTransferInstruction::Transfer / InvalidInstructionData`, because it builds the
//! fee-free instruction too.
//!
//! **This test exists to notice if that ever changes.** If Solana raises the packet limit or the
//! proof shrinks, the assertion below starts failing and the with-fee settlement path becomes
//! reachable.
use solana_zk_sdk::encryption::{auth_encryption::AeKey, elgamal::ElGamalKeypair};
use spl_token_confidential_transfer_proof_generation::transfer_with_fee::transfer_with_fee_split_proof_data;

#[test]
fn the_u256_verify_transaction_fits_or_it_does_not() {
    let source = ElGamalKeypair::new_rand();
    let ae = AeKey::new_rand();
    let dest = ElGamalKeypair::new_rand();
    let auditor = ElGamalKeypair::new_rand();
    let withheld = ElGamalKeypair::new_rand();

    let balance: u64 = 17_300_000_000_000;
    let current = source.pubkey().encrypt(balance);
    let decryptable = ae.encrypt(balance);

    let d = transfer_with_fee_split_proof_data(
        &current, &decryptable, balance, &source, &ae,
        dest.pubkey(), Some(auditor.pubkey()), withheld.pubkey(),
        50, u64::MAX,
    )
    .expect("with-fee proof set");

    println!("equality  {}", std::mem::size_of_val(&d.equality_proof_data));
    println!("validity3 {}", std::mem::size_of_val(
        &d.transfer_amount_ciphertext_validity_proof_data_with_ciphertext.proof_data));
    println!("pct+cap   {}", std::mem::size_of_val(&d.percentage_with_cap_proof_data));
    println!("validity2 {}", std::mem::size_of_val(&d.fee_ciphertext_validity_proof_data));
    println!("range256  {}", std::mem::size_of_val(&d.range_proof_data));
}

/// The measurement the whole with-fee path depends on.
#[test]
fn the_verify_transaction_for_each_proof() {
    use solana_address::Address;
    use solana_hash::Hash;
    use solana_keypair::Keypair;
    use solana_message::{v0, AddressLookupTableAccount, Message, VersionedMessage};
    use solana_signer::Signer;
    use solana_transaction::versioned::VersionedTransaction;
    use solana_transaction::Transaction;
    use solana_zk_elgamal_proof_interface::instruction::{ContextStateInfo, ProofInstruction};
    use solana_zk_elgamal_proof_interface::proof_data::*;

    let source = ElGamalKeypair::new_rand();
    let ae = AeKey::new_rand();
    let dest = ElGamalKeypair::new_rand();
    let auditor = ElGamalKeypair::new_rand();
    let withheld = ElGamalKeypair::new_rand();
    let balance: u64 = 17_300_000_000_000;
    let current = source.pubkey().encrypt(balance);
    let decryptable = ae.encrypt(balance);
    let d = transfer_with_fee_split_proof_data(
        &current, &decryptable, balance, &source, &ae,
        dest.pubkey(), Some(auditor.pubkey()), withheld.pubkey(), 50, u64::MAX,
    ).expect("with-fee proof set");

    let payer = Keypair::new();
    let ctx = Address::from(Keypair::new().pubkey());
    let authority = Address::from(Keypair::new().pubkey());
    let blockhash = Hash::default();

    let mut worst = 0usize;
    let mut report = |name: &str, ix: solana_instruction::Instruction| {
        let legacy = Transaction::new(
            &[&payer], Message::new(&[ix.clone()], Some(&payer.pubkey())), blockhash);
        let legacy_len = bincode::serialize(&legacy).unwrap().len();
        let table = AddressLookupTableAccount { key: Address::from(Keypair::new().pubkey()), addresses: vec![ctx, authority] };
        let v0len = v0::Message::try_compile(&payer.pubkey(), &[ix], &[table], blockhash)
            .ok()
            .and_then(|m| VersionedTransaction::try_new(VersionedMessage::V0(m), &[&payer]).ok())
            .map(|t| bincode::serialize(&t).unwrap().len());
        let best = v0len.unwrap_or(legacy_len).min(legacy_len);
        if best > worst { worst = best }
        println!("{name:<12} legacy {legacy_len:>5}   v0+ALT {:>5}   limit 1232 -> {}",
                 v0len.map(|n| n.to_string()).unwrap_or("-".into()),
                 if best <= 1232 { "FITS" } else { "OVER" });
    };

    report("equality", ProofInstruction::VerifyCiphertextCommitmentEquality
        .encode_verify_proof::<CiphertextCommitmentEqualityProofData, CiphertextCommitmentEqualityProofContext>(
            Some(ContextStateInfo { context_state_account: &ctx, context_state_authority: &authority }), &d.equality_proof_data));
    report("validity3", ProofInstruction::VerifyBatchedGroupedCiphertext3HandlesValidity
        .encode_verify_proof::<BatchedGroupedCiphertext3HandlesValidityProofData, BatchedGroupedCiphertext3HandlesValidityProofContext>(
            Some(ContextStateInfo { context_state_account: &ctx, context_state_authority: &authority }), &d.transfer_amount_ciphertext_validity_proof_data_with_ciphertext.proof_data));
    report("pct+cap", ProofInstruction::VerifyPercentageWithCap
        .encode_verify_proof::<PercentageWithCapProofData, PercentageWithCapProofContext>(
            Some(ContextStateInfo { context_state_account: &ctx, context_state_authority: &authority }), &d.percentage_with_cap_proof_data));
    report("validity2", ProofInstruction::VerifyBatchedGroupedCiphertext2HandlesValidity
        .encode_verify_proof::<BatchedGroupedCiphertext2HandlesValidityProofData, BatchedGroupedCiphertext2HandlesValidityProofContext>(
            Some(ContextStateInfo { context_state_account: &ctx, context_state_authority: &authority }), &d.fee_ciphertext_validity_proof_data));
    report("range256", ProofInstruction::VerifyBatchedRangeProofU256
        .encode_verify_proof::<BatchedRangeProofU256Data, BatchedRangeProofContext>(
            Some(ContextStateInfo { context_state_account: &ctx, context_state_authority: &authority }), &d.range_proof_data));
    println!("\nworst case {worst} bytes against 1232");
    assert!(worst > 1232,
            "the with-fee proof set now fits in a transaction ({worst} bytes) — \
             confidential settlement on a fee-bearing mint has become possible, \
             and docs/cwf-2026/PRE-IPO.md says it is not");

    // The same range proof with the context authority set to the fee payer. Confide deliberately
    // makes the authority the loan PDA so the borrower cannot close the context accounts; this
    // measures what that choice costs, so the constraint is understood rather than guessed at.
    let ix = ProofInstruction::VerifyBatchedRangeProofU256
        .encode_verify_proof::<BatchedRangeProofU256Data, BatchedRangeProofContext>(
            Some(ContextStateInfo { context_state_account: &ctx, context_state_authority: &Address::from(payer.pubkey()) }),
            &d.range_proof_data);
    let legacy = Transaction::new(&[&payer], Message::new(&[ix.clone()], Some(&payer.pubkey())), blockhash);
    println!("range256, authority = payer:   legacy {}", bincode::serialize(&legacy).unwrap().len());
    let table = AddressLookupTableAccount { key: Address::from(Keypair::new().pubkey()), addresses: vec![ctx] };
    if let Ok(m) = v0::Message::try_compile(&payer.pubkey(), &[ix], &[table], blockhash) {
        if let Ok(t) = VersionedTransaction::try_new(VersionedMessage::V0(m), &[&payer]) {
            println!("range256, authority = payer:   v0+ALT {}", bincode::serialize(&t).unwrap().len());
        }
    }
}
