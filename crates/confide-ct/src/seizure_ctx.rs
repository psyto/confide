//! `seizure-ctx <payer.json> <keys.json|synthetic:N> <dec_b64|-> <avail_b64|-> <lender_pk|rand>
//!  <auditor_pk|none|rand> <amount|all> <blockhash> <out.json> <authority> <keys_dir> <alt|none>
//!  <floor_base_units>`
//!
//! Put the **five** proofs a seizure needs on chain, already verified, in context state accounts
//! the borrower cannot close: three for the transfer, and two more establishing that the escrow
//! held at least the floor at the moment the loan was written.
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
use solana_message::{v0, AddressLookupTableAccount, Message, VersionedMessage};
use solana_signer::Signer;
use solana_transaction::versioned::VersionedTransaction;
use solana_transaction::Transaction;
use solana_zk_elgamal_proof_interface::instruction::{ContextStateInfo, ProofInstruction};
use solana_zk_elgamal_proof_interface::proof_data::{
    batched_grouped_ciphertext_validity::{
        BatchedGroupedCiphertext3HandlesValidityProofContext,
        BatchedGroupedCiphertext3HandlesValidityProofData,
    },
    batched_range_proof::{BatchedRangeProofContext, BatchedRangeProofU128Data, BatchedRangeProofU64Data},
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
    let keys_dir = a.next().expect("directory for the context account keypairs");
    // The range proof's verify transaction does not fit a legacy message once the context
    // authority is its own account — 1,237 bytes against a 1,232 limit. An address lookup table
    // holding that account and the authority moves both out of the static keys and buys back 62
    // bytes for 37. Pass `none` to see the overflow rather than avoid it.
    let alt = a.next().expect("address lookup table | none");
    // The floor the loan is written against, in base units. `originate` refuses without proofs of
    // it; before this argument existed the program required two accounts nothing produced.
    //
    // `none` builds the three TRANSFER proofs and stops. An atomic swap needs no floor: each side
    // reads the other's validity context and decrypts the amount itself, because the amount is
    // encrypted to the recipient. A floor is what you prove to somebody who must lend against a
    // balance they will never see — nobody in a swap is in that position.
    let floor_arg = a.next().expect("floor in base units | none");
    let floor: Option<u64> = if floor_arg == "none" {
        None
    } else {
        Some(floor_arg.parse().expect("floor must be a number or `none`"))
    };

    let payer = confide_ct_keypair(&payer_path);
    let zk = solana_zk_elgamal_proof_interface::id();

    let s = confide_ct::build_for(&keys, &dec, &avail, &lender, &auditor, &amount);

    // One account per proof, each sized for the context it will hold. Loaded from disk when they
    // are already there: the lookup table has to be built around the range account's address, so
    // that address must be known before the proofs that go into it exist.
    let accounts = [
        load_or_create(&keys_dir, "ctx-equality.json"),
        load_or_create(&keys_dir, "ctx-validity.json"),
        load_or_create(&keys_dir, "ctx-range.json"),
        load_or_create(&keys_dir, "ctx-floor-equality.json"),
        load_or_create(&keys_dir, "ctx-floor-range.json"),
    ];
    let sizes = [
        std::mem::size_of::<ProofContextState<CiphertextCommitmentEqualityProofContext>>(),
        std::mem::size_of::<ProofContextState<BatchedGroupedCiphertext3HandlesValidityProofContext>>(),
        std::mem::size_of::<ProofContextState<BatchedRangeProofContext>>(),
        std::mem::size_of::<ProofContextState<CiphertextCommitmentEqualityProofContext>>(),
        std::mem::size_of::<ProofContextState<BatchedRangeProofContext>>(),
    ];

    // The floor is proved over the escrow's own ciphertext, the same one the transfer proofs are
    // about, so it is built from the same opened keys rather than from a second read.
    let f = floor.map(|q| confide_ct::build_floor(&confide_ct::open_escrow(&keys, &dec, &avail), q));

    let mut verify = vec![
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
    if let Some(f) = f.as_ref() {
        verify.push(
            ProofInstruction::VerifyCiphertextCommitmentEquality
                .encode_verify_proof::<CiphertextCommitmentEqualityProofData, CiphertextCommitmentEqualityProofContext>(
                    Some(ContextStateInfo { context_state_account: &accounts[3].pubkey(), context_state_authority: &authority }),
                    &f.equality,
                ),
        );
        verify.push(
            ProofInstruction::VerifyBatchedRangeProofU64
                .encode_verify_proof::<BatchedRangeProofU64Data, BatchedRangeProofContext>(
                    Some(ContextStateInfo { context_state_account: &accounts[4].pubkey(), context_state_authority: &authority }),
                    &f.range,
                ),
        );
    }

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
        println!("{}", b64tx(&bincode::serialize(&create_tx).unwrap()));

        // The range proof is the only one that needs the table, and only because the authority is
        // a separate account. Routing the small two through it as well would work and would hide
        // which one the limit actually bites.
        let (bytes, how) = if i == 2 && alt != "none" {
            let table = AddressLookupTableAccount {
                key: Address::from_str(&alt).expect("lookup table address"),
                addresses: vec![accounts[2].pubkey(), authority],
            };
            let msg = v0::Message::try_compile(&payer.pubkey(), &[ix], &[table], blockhash)
                .expect("compile v0 message against the lookup table");
            let tx = VersionedTransaction::try_new(VersionedMessage::V0(msg), &[&payer])
                .expect("sign versioned transaction");
            (bincode::serialize(&tx).unwrap(), "v0 + lookup table")
        } else {
            let tx = Transaction::new(&[&payer], Message::new(&[ix], Some(&payer.pubkey())), blockhash);
            (bincode::serialize(&tx).unwrap(), "legacy")
        };
        let n = bytes.len();
        eprintln!(
            "  verify tx {}        {n} bytes, {how}{}",
            i + 1,
            if n > 1232 { "   <- OVER the 1,232-byte limit" } else { "" }
        );
        println!("{}", b64tx(&bytes));
    }

    std::fs::write(
        &out,
        serde_json::to_vec_pretty(&serde_json::json!({
            "equality":  accounts[0].pubkey().to_string(),
            "validity":  accounts[1].pubkey().to_string(),
            "range":     accounts[2].pubkey().to_string(),
            "floor_equality": floor.map(|_| accounts[3].pubkey().to_string()),
            "floor_range":    floor.map(|_| accounts[4].pubkey().to_string()),
            "floor":          floor,
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

    eprintln!("  transfer contexts  {} / {} / {}", accounts[0].pubkey(), accounts[1].pubkey(), accounts[2].pubkey());
    match floor {
        Some(q) => {
            eprintln!("  floor contexts     {} / {}", accounts[3].pubkey(), accounts[4].pubkey());
            eprintln!("  floor              {q} base units, proved over the escrow's own ciphertext");
        }
        None => eprintln!("  floor              none — a swap proves no floor; each side decrypts the other's amount"),
    }
    eprintln!("  sizes              {} bytes", verify_sizes(&sizes, floor.is_some()));
    eprintln!("  authority          {authority}   <- the loan PDA; the borrower cannot close these");
    eprintln!("  lookup table       {alt}");
    eprintln!("  artifact           {out}");
}

fn b64tx(bytes: &[u8]) -> String {
    base64::engine::general_purpose::STANDARD.encode(bytes)
}

/// Context account keypairs are throwaway — they exist to hold one proof each — but they must
/// survive between the run that names them and the run that fills them.
fn load_or_create(dir: &str, name: &str) -> Keypair {
    let path = format!("{dir}/{name}");
    if let Ok(bytes) = std::fs::read(&path) {
        let v: Vec<u8> = serde_json::from_slice(&bytes).unwrap();
        return Keypair::try_from(&v[..]).unwrap();
    }
    let kp = Keypair::new();
    std::fs::create_dir_all(dir).unwrap();
    std::fs::write(&path, serde_json::to_vec(&kp.to_bytes().to_vec()).unwrap()).unwrap();
    kp
}

fn confide_ct_keypair(path: &str) -> Keypair {
    let bytes: Vec<u8> = serde_json::from_slice(&std::fs::read(path).unwrap()).unwrap();
    Keypair::try_from(&bytes[..]).unwrap()
}

/// The context sizes actually used, so the line does not report two accounts a swap never creates.
fn verify_sizes(sizes: &[usize], with_floor: bool) -> String {
    let n = if with_floor { 5 } else { 3 };
    sizes[..n].iter().map(|s| s.to_string()).collect::<Vec<_>>().join(" / ")
}
