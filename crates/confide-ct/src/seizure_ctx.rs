//! `seizure-ctx <payer.json> <keys.json|synthetic:N> <dec_b64|-> <avail_b64|-> <lender_pk|rand>
//!  <auditor_pk|none|rand> <amount|all> <blockhash> <out.json>`
//!
//! Put the three seizure proofs **on chain, already verified**, in context state accounts the
//! borrower cannot close.
//!
//! This is the step the whole design turns on. `build-seizure-proofs` shows the proofs are accepted;
//! this makes them durable — `Transfer` will later cite them by address alone, from a CPI the
//! borrower is not party to and cannot refuse. Each transaction creates the account and verifies
//! into it, so a created-but-empty context never exists for anyone to race.
//!
//! The context state **authority** is passed as the loan PDA. That is the one binding Token-2022
//! does not check for us: a context account is closable by its authority, so a borrower holding it
//! could withdraw the proofs the day before default and walk the collateral back out.

use base64::Engine;
use solana_address::Address;
use solana_hash::Hash;
use solana_instruction::{AccountMeta, Instruction};
use solana_keypair::Keypair;
use solana_message::Message;
use solana_signer::Signer;
use solana_transaction::Transaction;
use solana_zk_elgamal_proof_interface::instruction::{ContextStateInfo, ProofInstruction};
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
use solana_zk_elgamal_proof_interface::state::ProofContextState;
use std::str::FromStr;

const SYSTEM: &str = "11111111111111111111111111111111";
/// Rent exemption, computed rather than fetched: `(overhead + size) * lamports_per_byte_year *
/// exemption_years`, the constants the runtime has used since genesis.
const ACCOUNT_STORAGE_OVERHEAD: u64 = 128;
const LAMPORTS_PER_BYTE_YEAR: u64 = 3_480;
const EXEMPTION_YEARS: u64 = 2;

fn rent_exempt(size: usize) -> u64 {
    (ACCOUNT_STORAGE_OVERHEAD + size as u64) * LAMPORTS_PER_BYTE_YEAR * EXEMPTION_YEARS
}

/// `SystemInstruction::CreateAccount` — hand-encoded so this crate keeps its small dependency set.
fn create_account(from: &Address, to: &Address, lamports: u64, space: u64, owner: &Address) -> Instruction {
    let mut data = vec![0u8; 4];
    data.extend_from_slice(&lamports.to_le_bytes());
    data.extend_from_slice(&space.to_le_bytes());
    data.extend_from_slice(&owner.to_bytes());
    Instruction {
        program_id: Address::from_str(SYSTEM).unwrap(),
        accounts: vec![AccountMeta::new(*from, true), AccountMeta::new(*to, true)],
        data,
    }
}

fn main() {
    let mut a = std::env::args().skip(1);
    let payer_path = a.next().expect("payer.json");
    let keys = a.next().expect("keys.json | synthetic:N");
    let dec = a.next().expect("decryptable_b64 | -");
    let avail = a.next().expect("available_b64 | -");
    let lender = a.next().expect("lender_pk | rand");
    let auditor = a.next().expect("auditor_pk | none | rand");
    let amount = a.next().expect("amount | all");
    let blockhash = Hash::from_str(&a.next().expect("blockhash")).unwrap();
    let out = a.next().expect("out.json");
    let authority = Address::from_str(&a.next().expect("context state authority")).unwrap();

    let payer = confide_ct_keypair(&payer_path);
    let zk = solana_zk_elgamal_proof_interface::id();

    let s = confide_ct::build_for(&keys, &dec, &avail, &lender, &auditor, &amount);

    // One account per proof, each sized for the context it will hold.
    let accounts = [Keypair::new(), Keypair::new(), Keypair::new()];
    let sizes = [
        std::mem::size_of::<ProofContextState<CiphertextCommitmentEqualityProofContext>>(),
        std::mem::size_of::<ProofContextState<BatchedGroupedCiphertext3HandlesValidityProofContext>>(),
        std::mem::size_of::<ProofContextState<BatchedRangeProofContext>>(),
    ];

    let verify = [
        ProofInstruction::VerifyCiphertextCommitmentEquality
            .encode_verify_proof::<CiphertextCommitmentEqualityProofData, CiphertextCommitmentEqualityProofContext>(
                Some(ContextStateInfo { context_state_account: &accounts[0].pubkey(), context_state_authority: &authority }),
                &s.equality,
            ),
        ProofInstruction::VerifyBatchedGroupedCiphertext3HandlesValidity
            .encode_verify_proof::<BatchedGroupedCiphertext3HandlesValidityProofData, BatchedGroupedCiphertext3HandlesValidityProofContext>(
                Some(ContextStateInfo { context_state_account: &accounts[1].pubkey(), context_state_authority: &authority }),
                &s.validity,
            ),
        ProofInstruction::VerifyBatchedRangeProofU128
            .encode_verify_proof::<BatchedRangeProofU128Data, BatchedRangeProofContext>(
                Some(ContextStateInfo { context_state_account: &accounts[2].pubkey(), context_state_authority: &authority }),
                &s.range,
            ),
    ];

    // Create and verify go in separate transactions. Together they do not fit: a U128 range proof
    // is 1,000 bytes of instruction data, and with a context authority distinct from the fee payer
    // the verify transaction alone reaches 1,237 bytes against a 1,232-byte limit — over by five.
    // Splitting buys back the create instruction's account; the size printed below says whether
    // that was enough for this particular authority.
    for (i, ix) in verify.into_iter().enumerate() {
        let create = create_account(
            &payer.pubkey(),
            &accounts[i].pubkey(),
            rent_exempt(sizes[i]),
            sizes[i] as u64,
            &zk,
        );
        let create_tx = Transaction::new(
            &[&payer, &accounts[i]],
            Message::new(&[create], Some(&payer.pubkey())),
            blockhash,
        );
        let verify_tx = Transaction::new(
            &[&payer],
            Message::new(&[ix], Some(&payer.pubkey())),
            blockhash,
        );
        let n = bincode::serialize(&verify_tx).unwrap().len();
        eprintln!(
            "  verify tx {}        {n} bytes{}",
            i + 1,
            if n > 1232 { "   <- OVER the 1,232-byte limit" } else { "" }
        );
        println!("{}", base64::engine::general_purpose::STANDARD.encode(bincode::serialize(&create_tx).unwrap()));
        println!("{}", base64::engine::general_purpose::STANDARD.encode(bincode::serialize(&verify_tx).unwrap()));
    }

    std::fs::write(
        &out,
        serde_json::to_vec_pretty(&serde_json::json!({
            "equality":  accounts[0].pubkey().to_string(),
            "validity":  accounts[1].pubkey().to_string(),
            "range":     accounts[2].pubkey().to_string(),
            "authority": authority.to_string(),
            "amount":    s.amount,
            "remaining": s.remaining,
            "new_decryptable_b64": s.new_decryptable_b64,
            "auditor_lo_b64": s.auditor_lo_b64,
            "auditor_hi_b64": s.auditor_hi_b64,
            "lender_elgamal_pubkey_b64": s.lender_pk_b64,
        }))
        .unwrap(),
    )
    .unwrap();

    eprintln!("  context accounts   {} / {} / {}", accounts[0].pubkey(), accounts[1].pubkey(), accounts[2].pubkey());
    eprintln!("  sizes              {} / {} / {} bytes", sizes[0], sizes[1], sizes[2]);
    eprintln!("  authority          {authority}   <- the loan PDA; the borrower cannot close these");
    eprintln!("  artifact           {out}");
}

fn confide_ct_keypair(path: &str) -> Keypair {
    let bytes: Vec<u8> = serde_json::from_slice(&std::fs::read(path).unwrap()).unwrap();
    Keypair::try_from(&bytes[..]).unwrap()
}
