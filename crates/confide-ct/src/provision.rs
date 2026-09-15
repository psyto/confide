//! `provision <step> <keypair.json> <mint> <account> <amount> <blockhash> <keys.json>`
//!
//! Stands up a Token-2022 confidential account **whose ElGamal key we generate and keep**.
//!
//! `spl-token` derives that key from a wallet signature with a KDF this SDK version does not
//! reproduce, so an account the CLI configures is one we can read on the chain and cannot prove
//! anything about. Generating the key here is what lets the range proof be over the account's own
//! `availableBalance` instead of over a ciphertext invented for the occasion.
//!
//! Steps, each one transaction: `configure` (writes the keys file), `approve`, `deposit`, `apply`.
//!
//! `approve` exists because the mirror is configured the way the real mints are. Backed and
//! Backpack both set `autoApproveNewAccounts: false`, so a holder cannot open a confidential
//! account without the issuer signing for it. Mirroring that with `auto` would have made the demo
//! easier and the claim false — the mirror would have differed from NVDAx in two fields, not one.
//! Here the mint authority is us, so the approval is a transaction we send; for a real holder it is
//! a conversation with the issuer. That gap is the point, and it is better shown than described.

use base64::Engine;
use solana_address::Address;
use solana_hash::Hash;
use solana_keypair::Keypair;
use solana_message::Message;
use solana_signer::Signer;
use solana_transaction::Transaction;
use solana_zk_sdk::encryption::auth_encryption::AeKey;
use solana_zk_sdk::encryption::elgamal::ElGamalKeypair;
use solana_zk_sdk::zk_elgamal_proof_program::pubkey_validity::build_pubkey_validity_proof_data;
use solana_zk_sdk_pod::encryption::auth_encryption::PodAeCiphertext;
use spl_token_2022_interface::extension::confidential_transfer::instruction::{
    apply_pending_balance, approve_account, configure_account, deposit,
};
use spl_token_2022_interface::extension::ExtensionType;
use spl_token_2022_interface::instruction::reallocate;
use spl_token_confidential_transfer_proof_extraction::instruction::ProofLocation;
use std::num::NonZeroI8;
use std::str::FromStr;

const TOKEN_2022: &str = "TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb";
const DECIMALS: u8 = 8;

fn main() {
    let mut a = std::env::args().skip(1);
    let step = a.next().expect("step: configure | approve | deposit | apply");
    let owner = read_keypair(&a.next().expect("keypair"));
    let mint = Address::from_str(&a.next().expect("mint")).unwrap();
    let account = Address::from_str(&a.next().expect("account")).unwrap();
    let amount: u64 = a.next().expect("amount").parse().unwrap();
    let blockhash = Hash::from_str(&a.next().expect("blockhash")).unwrap();
    let keys_path = a.next().expect("keys.json");

    let program = Address::from_str(TOKEN_2022).unwrap();
    let base = amount * 10u64.pow(DECIMALS as u32);

    let ixs = match step.as_str() {
        "configure" => {
            // The key this whole step exists for.
            let elgamal = ElGamalKeypair::new_rand();
            let ae = AeKey::new_rand();
            std::fs::write(
                &keys_path,
                serde_json::to_vec_pretty(&serde_json::json!({
                    "account": account.to_string(),
                    "mint": mint.to_string(),
                    "elgamal_pubkey_b64": b64(&elgamal.pubkey().to_bytes()),
                    "elgamal_secret_b64": b64(elgamal.secret().as_bytes()),
                    "ae_key_b64": b64(&<[u8; 16]>::from(&ae)[..]),
                }))
                .unwrap(),
            )
            .unwrap();
            eprintln!("  keys written    {keys_path}");
            eprintln!("  elgamal pubkey  {}", b64(&elgamal.pubkey().to_bytes()));

            let proof = build_pubkey_validity_proof_data(&elgamal).expect("pubkey validity proof");
            let zero: PodAeCiphertext = ae.encrypt(0).into();

            // A token account created by `create-account` has no room for the extension, and
            // ConfigureAccount fails with InvalidAccountData rather than growing it for you.
            let mut ixs = vec![reallocate(
                &program,
                &account,
                &owner.pubkey(),
                &owner.pubkey(),
                &[],
                &[ExtensionType::ConfidentialTransferAccount],
            )
            .expect("reallocate")];
            ixs.extend(configure_account(
                &program,
                &account,
                &mint,
                &zero,
                65_536,
                &owner.pubkey(),
                &[],
                ProofLocation::InstructionOffset(NonZeroI8::new(1).unwrap(), &proof),
            )
            .expect("configure_account"));
            ixs
        }
        // The issuer's signature on this account. On a mint with autoApproveNewAccounts false, the
        // confidential extension stays unapproved and every later instruction fails without it.
        "approve" => vec![approve_account(&program, &account, &mint, &owner.pubkey(), &[])
            .expect("approve_account")],
        "deposit" => vec![deposit(&program, &account, &mint, base, DECIMALS, &owner.pubkey(), &[])
            .expect("deposit")],
        "apply" => {
            let keys: serde_json::Value =
                serde_json::from_slice(&std::fs::read(&keys_path).unwrap()).unwrap();
            let ae = AeKey::try_from(
                &d64(keys["ae_key_b64"].as_str().unwrap())[..],
            )
            .expect("ae key");
            // Everything deposited lands in available once applied.
            let new_available: PodAeCiphertext = ae.encrypt(base).into();
            vec![apply_pending_balance(&program, &account, 1, &new_available, &owner.pubkey(), &[])
                .expect("apply_pending_balance")]
        }
        other => panic!("unknown step {other}"),
    };

    let tx = Transaction::new(&[&owner], Message::new(&ixs, Some(&owner.pubkey())), blockhash);
    println!("{}", base64::engine::general_purpose::STANDARD.encode(bincode::serialize(&tx).unwrap()));
}

fn b64(b: &[u8]) -> String {
    base64::engine::general_purpose::STANDARD.encode(b)
}
fn d64(s: &str) -> Vec<u8> {
    base64::engine::general_purpose::STANDARD.decode(s).unwrap()
}
fn read_keypair(path: &str) -> Keypair {
    let bytes: Vec<u8> = serde_json::from_str(&std::fs::read_to_string(path).unwrap()).unwrap();
    Keypair::try_from(&bytes[..]).unwrap()
}
