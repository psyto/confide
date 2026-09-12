//! Emit an unsigned transaction that hands Mora's **own** NAV-floor proof to Solana's live
//! ZK ElGamal Proof Program (`ZkE1Gama1Proof11111111111111111111111111111`).
//!
//! The point is which proof this is. These are not freshly minted bytes for a demo: they are read
//! straight back out of the `ProofEnvelope` inside the disclosure package that
//! `mora-equity::nav_floor_disclosure` produced, the same package the embargo seals. So
//! what the chain accepts is the artifact, not a lookalike.
//!
//! Run it through `scripts/devnet-verify.sh`, which feeds the output to devnet
//! `simulateTransaction` — no signature, no fee, no funded account required.

use base64::Engine;
use mora_equity::{nav_floor_disclosure, Position, DEFAULT_NAV_FLOOR_CENTS, NVDAX, SPYX, TSLAX};
use solana_address::Address;
use solana_message::Message;
use solana_transaction::Transaction;
use solana_zk_elgamal_proof_interface::{
    instruction::ProofInstruction,
    proof_data::batched_range_proof::{BatchedRangeProofContext, BatchedRangeProofU64Data},
};
use solana_zk_sdk::encryption::elgamal::ElGamalKeypair;
use std::str::FromStr;

/// Any devnet account that exists; simulation loads the fee payer but charges nothing.
const DEFAULT_PAYER: &str = "BjKr5GrbtX4saPvirVaW1QhjspaY9hgBFEzYvQaeRk1m";

fn main() {
    let fund = ElGamalKeypair::new_rand();
    let portfolio = vec![
        Position::from_shares(NVDAX, 173, 18_450),
        Position::from_shares(TSLAX, 900, 42_100),
        Position::from_shares(SPYX, 1_100, 66_800),
    ];

    let attestation = nav_floor_disclosure(&fund, &portfolio, DEFAULT_NAV_FLOOR_CENTS)
        .or_else(|| nav_floor_disclosure(&fund, &portfolio, 1_000_00))
        .expect("a portfolio above some floor");

    // Read the proof back out of the disclosure package — same bytes, not a re-generation.
    let proof: BatchedRangeProofU64Data = bytemuck::pod_read_unaligned(&attestation.proof.bytes);

    let ix = ProofInstruction::VerifyBatchedRangeProofU64
        .encode_verify_proof::<BatchedRangeProofU64Data, BatchedRangeProofContext>(None, &proof);

    let payer_str = std::env::args().nth(1).unwrap_or_else(|| DEFAULT_PAYER.to_string());
    let payer = Address::from_str(&payer_str).expect("valid base58 devnet pubkey");
    let tx = Transaction::new_unsigned(Message::new(&[ix], Some(&payer)));

    let bytes = bincode::serialize(&tx).expect("serialize transaction");
    println!("{}", base64::engine::general_purpose::STANDARD.encode(bytes));
}
