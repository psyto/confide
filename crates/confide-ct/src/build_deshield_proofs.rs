//! `build-deshield-proofs <keys.json|synthetic:N> <dec_b64|-> <avail_b64|-> <amount|all> <payer>`
//!
//! The two proofs a **de-shield** needs, built at origination for a default nobody will be around
//! to help with.
//!
//! `Withdraw` moves a confidential balance into the account's **own public balance**. It takes no
//! destination — and that is the property this exists for. A seizure has to name its recipient at
//! origination, because the transfer proofs bind to that recipient's key; a de-shield names nobody.
//! Once the collateral is public, moving it is an ordinary SPL transfer that needs no proof and no
//! foresight, so **a liquidation path that did not exist at origination can still pick it up**.
//!
//! Two proofs rather than three: equality, that the ciphertext left behind is the balance the range
//! proof is over; and a u64 range proof, that it did not underflow. No validity proof, because
//! there is no destination handle to prove anything about.

use base64::Engine;
use confide_ct::{compose_deshield, d64, BuiltKeys};
use solana_address::Address;
use solana_instruction::Instruction;
use solana_message::Message;
use solana_transaction::Transaction;
use solana_zk_elgamal_proof_interface::instruction::ProofInstruction;
use solana_zk_elgamal_proof_interface::proof_data::{
    batched_range_proof::{BatchedRangeProofContext, BatchedRangeProofU64Data},
    ciphertext_commitment_equality::{
        CiphertextCommitmentEqualityProofContext, CiphertextCommitmentEqualityProofData,
    },
};
use std::str::FromStr;

fn main() {
    let a: Vec<String> = std::env::args().skip(1).collect();
    let [keys, dec, avail, amount, payer]: [String; 5] =
        a.try_into().expect("five arguments; see the module docs");
    let payer = Address::from_str(&payer).expect("payer address");

    let BuiltKeys { source, ae, balance, current_ct, label } =
        confide_ct::open_escrow(&keys, &dec, &avail);
    let amount = match amount.as_str() {
        "all" => balance,
        s => s.parse().expect("amount in base units"),
    };

    let d = compose_deshield(&source, &ae, &current_ct, balance, amount);

    let cb = Instruction {
        program_id: Address::from_str("ComputeBudget111111111111111111111111111111").unwrap(),
        accounts: vec![],
        data: {
            let mut v = vec![0x02];
            v.extend_from_slice(&300_000u32.to_le_bytes());
            v
        },
    };
    let tx = |ix| {
        base64::engine::general_purpose::STANDARD.encode(
            bincode::serialize(&Transaction::new_unsigned(Message::new(
                &[cb.clone(), ix],
                Some(&payer),
            )))
            .unwrap(),
        )
    };

    eprintln!("  escrow             {label}");
    eprintln!("  de-shielding       {amount} of {balance} base units");
    eprintln!("  remaining          {}", d.remaining);
    eprintln!("  destination        none — Withdraw has no recipient, which is the point");
    eprintln!("  new decryptable    {}", d.new_decryptable_b64);

    println!("{}", ProofInstruction::VerifyCiphertextCommitmentEquality
        .encode_verify_proof::<CiphertextCommitmentEqualityProofData, CiphertextCommitmentEqualityProofContext>(None, &d.equality)
        .pipe(tx));
    println!("{}", ProofInstruction::VerifyBatchedRangeProofU64
        .encode_verify_proof::<BatchedRangeProofU64Data, BatchedRangeProofContext>(None, &d.range)
        .pipe(tx));
    let _ = d64;
}

trait Pipe: Sized {
    fn pipe<R>(self, f: impl FnOnce(Self) -> R) -> R { f(self) }
}
impl Pipe for Instruction {}
