//! `build-seizure-proofs <keys.json|synthetic:N> <dec_b64|-> <avail_b64|-> <lender_pk|rand>
//!  <auditor_pk|none|rand> <amount|all> <payer>`
//!
//! Builds the three proofs a **confidential transfer** needs, at origination, for a transfer the
//! borrower will not be around to authorise — and emits them for the live ZK program to judge.
//!
//! This is the step [`docs/SEIZURE.md`](../../../docs/SEIZURE.md) turns on. A lender can already
//! check a floor over the borrower's own ciphertext (`prove_collateral.rs`) and still cannot take
//! the collateral, because a confidential transfer must *prove* what it moves and the proofs need
//! the source account's ElGamal secret — which no program can hold. So the proofs are built while
//! the borrower is cooperative, which is the one thing default is defined as not being.
//!
//! Three proofs, and each is load-bearing:
//!
//!   1. **batched grouped ciphertext validity, 3 handles** — the amount re-encrypts correctly under
//!      source, destination **and auditor**. The auditor handle is why a seizure is still readable
//!      by the party the mint names, rather than a hole in the disclosure.
//!   2. **batched range proof U128** — four commitments in one: the remaining balance is a
//!      non-negative 64-bit value, the amount's 16-bit low and 32-bit high halves are in range, and
//!      a 16-bit commitment to zero pads the batch to the power of two the proof system needs.
//!   3. **ciphertext-commitment equality** — the homomorphically computed remaining-balance
//!      ciphertext and the Pedersen commitment the range proof is actually over are the same value.
//!
//! Nothing here is stored. `seizure-ctx` is the one that writes these into context state accounts,
//! which is what lets `Transfer` cite them by address months later.

use base64::Engine;
use confide_ct::build_for;
use solana_address::Address;
use solana_instruction::Instruction;
use solana_message::Message;
use solana_transaction::Transaction;
use solana_zk_elgamal_proof_interface::instruction::ProofInstruction;
use solana_zk_elgamal_proof_interface::proof_data::{
    batched_grouped_ciphertext_validity::{
        BatchedGroupedCiphertext3HandlesValidityProofContext,
        BatchedGroupedCiphertext3HandlesValidityProofData,
    },
    batched_range_proof::{BatchedRangeProofContext, BatchedRangeProofU128Data},
    ciphertext_commitment_equality::{
        CiphertextCommitmentEqualityProofContext, CiphertextCommitmentEqualityProofData,
    },
};
use std::str::FromStr;

/// A batched U128 range proof costs more than the 200k default, and a transaction that silently
/// runs out reports the cap rather than the cost. Raising it is what makes the numbers real.
const COMPUTE_UNIT_LIMIT: u32 = 500_000;

fn main() {
    let a: Vec<String> = std::env::args().skip(1).collect();
    let [keys, dec, avail, lender, auditor, amount, payer]: [String; 7] =
        a.try_into().expect("seven arguments; see the module docs");
    let payer = Address::from_str(&payer).expect("payer address");

    let built = build_for(&keys, &dec, &avail, &lender, &auditor, &amount);

    // Built by hand rather than pulling in the compute-budget crate: the instruction is a
    // discriminator and a u32.
    let compute_budget = Instruction {
        program_id: Address::from_str("ComputeBudget111111111111111111111111111111").unwrap(),
        accounts: vec![],
        data: {
            let mut d = vec![0x02];
            d.extend_from_slice(&COMPUTE_UNIT_LIMIT.to_le_bytes());
            d
        },
    };
    let tx = |ix| {
        base64::engine::general_purpose::STANDARD.encode(
            bincode::serialize(&Transaction::new_unsigned(Message::new(
                &[compute_budget.clone(), ix],
                Some(&payer),
            )))
            .unwrap(),
        )
    };

    eprintln!("  escrow             {}", built.account_label);
    eprintln!("  seizing            {} base units", built.amount);
    eprintln!("  remaining          {}", built.remaining);
    eprintln!(
        "  auditor            {}",
        if built.auditor_present { "set, and reads the seizure" } else { "none — the slot every live xStock leaves empty" }
    );
    eprintln!("  new decryptable    {}   <- Transfer's new_source_decryptable_available_balance", built.new_decryptable_b64);

    println!("{}", tx(ProofInstruction::VerifyCiphertextCommitmentEquality
        .encode_verify_proof::<CiphertextCommitmentEqualityProofData, CiphertextCommitmentEqualityProofContext>(None, &built.equality)));
    println!("{}", tx(ProofInstruction::VerifyBatchedGroupedCiphertext3HandlesValidity
        .encode_verify_proof::<BatchedGroupedCiphertext3HandlesValidityProofData, BatchedGroupedCiphertext3HandlesValidityProofContext>(None, &built.validity)));
    println!("{}", tx(ProofInstruction::VerifyBatchedRangeProofU128
        .encode_verify_proof::<BatchedRangeProofU128Data, BatchedRangeProofContext>(None, &built.range)));
}
