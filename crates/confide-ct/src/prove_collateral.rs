//! `prove-collateral <keys.json> <decryptable_b64> <available_b64> <threshold_base_units> <blockhash> <payer>`
//!
//! Proves **this account holds at least X** — over the account's own on-chain ciphertext, and
//! without revealing what it holds.
//!
//! Every earlier proof in this repository was about a number we had just encrypted ourselves. A
//! lender cannot use that: a proof that *some* balance clears a threshold says nothing about the
//! balance securing their loan. This one is about the ciphertext sitting in
//! `confidentialTransferAccount.availableBalance`, which anyone can fetch.
//!
//! Two proofs, because one does not exist. The account's ElGamal ciphertext has no Pedersen opening
//! we hold, so it cannot be range-proved directly:
//!
//!   1. **ciphertext-commitment equality** — the account's ciphertext and a Pedersen commitment `C`
//!      whose opening we *do* hold encrypt the same value.
//!   2. **range** — `C - threshold·G` commits a non-negative 64-bit value.
//!
//! Together: the account holds at least the threshold. Separately, neither claim is about anything.
//! The verifier recomputes `C - threshold·G` and checks the range proof is over it.

use base64::Engine;
use solana_address::Address;
use solana_hash::Hash;
use solana_message::Message;
use solana_transaction::Transaction;
use solana_zk_elgamal_proof_interface::instruction::ProofInstruction;
use solana_zk_elgamal_proof_interface::proof_data::{
    batched_range_proof::{BatchedRangeProofContext, BatchedRangeProofU64Data},
    ciphertext_commitment_equality::{
        CiphertextCommitmentEqualityProofContext, CiphertextCommitmentEqualityProofData,
    },
};
use solana_zk_sdk::encryption::auth_encryption::{AeCiphertext, AeKey};
use solana_zk_sdk::encryption::elgamal::{ElGamalCiphertext, ElGamalKeypair, ElGamalSecretKey};
use solana_zk_sdk::encryption::pedersen::{Pedersen, PedersenOpening};
use solana_zk_sdk::zk_elgamal_proof_program::{
    batched_range_proof::build_batched_range_proof_u64_data,
    ciphertext_commitment_equality::build_ciphertext_commitment_equality_proof_data,
};
use std::str::FromStr;

fn main() {
    let mut a = std::env::args().skip(1);
    let keys_path = a.next().expect("keys.json");
    let decryptable = d64(&a.next().expect("decryptable_b64"));
    let available = d64(&a.next().expect("available_b64"));
    let threshold: u64 = a.next().expect("threshold").parse().unwrap();
    // Kept in the interface even though simulation replaces it, so the caller passes the same
    // arguments as the signing paths do.
    let _blockhash = Hash::from_str(&a.next().expect("blockhash")).unwrap();
    let payer = Address::from_str(&a.next().expect("payer")).unwrap();

    let keys: serde_json::Value = serde_json::from_slice(&std::fs::read(&keys_path).unwrap()).unwrap();
    let ae = AeKey::try_from(&d64(keys["ae_key_b64"].as_str().unwrap())[..]).unwrap();
    let secret = ElGamalSecretKey::try_from(&d64(keys["elgamal_secret_b64"].as_str().unwrap())[..]).unwrap();
    let elgamal = ElGamalKeypair::new(secret);

    let balance = ae
        .decrypt(&AeCiphertext::from_bytes(&decryptable).expect("ae ciphertext"))
        .expect("our key opens our balance");
    let ct = ElGamalCiphertext::from_bytes(&available).expect("elgamal ciphertext");

    // Refuse rather than prove a false statement — and say so without printing the balance. A
    // tool that reveals your position in its error messages is a habit worth not forming.
    if balance < threshold {
        eprintln!("  refusing: this account does not clear a threshold of {threshold} base units");
        std::process::exit(1);
    }

    // 1. A commitment to the same value, with an opening we keep.
    let opening = PedersenOpening::new_rand();
    let commitment = Pedersen::with(balance, &opening);
    let equality =
        build_ciphertext_commitment_equality_proof_data(&elgamal, &ct, &commitment, &opening, balance)
            .expect("equality proof");

    // 2. The surplus over the threshold, committed under the SAME opening, so the verifier can
    //    reach it from `commitment` by subtracting threshold·G rather than taking our word.
    let delta = balance - threshold;
    let delta_commitment = Pedersen::with(delta, &opening);
    let range = build_batched_range_proof_u64_data(
        vec![&delta_commitment],
        vec![delta],
        vec![64],
        vec![&opening],
    )
    .expect("range proof");

    let tx = |ix| {
        base64::engine::general_purpose::STANDARD
            .encode(bincode::serialize(&Transaction::new_unsigned(Message::new(&[ix], Some(&payer)))).unwrap())
    };

    eprintln!("  account            {}", keys["account"].as_str().unwrap_or("?"));
    eprintln!("  threshold          {threshold} base units");
    eprintln!("  proving            balance >= threshold, over the account's own ciphertext");
    eprintln!("  revealed           nothing but that one bit");

    println!("{}", tx(ProofInstruction::VerifyCiphertextCommitmentEquality
        .encode_verify_proof::<CiphertextCommitmentEqualityProofData, CiphertextCommitmentEqualityProofContext>(None, &equality)));
    println!("{}", tx(ProofInstruction::VerifyBatchedRangeProofU64
        .encode_verify_proof::<BatchedRangeProofU64Data, BatchedRangeProofContext>(None, &range)));
}

fn d64(s: &str) -> Vec<u8> {
    base64::engine::general_purpose::STANDARD.decode(s).unwrap()
}
