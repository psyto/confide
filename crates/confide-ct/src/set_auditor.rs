//! `set-auditor <keypair.json> <mint> <blockhash> [auditor_secret.json]`
//!
//! Fills the slot every xStock leaves empty — on a mint we control, because Backed's mints are not
//! ours to configure. One instruction: `ConfidentialTransferInstruction::UpdateMint`.
//!
//! The point is not that setting a key is hard. It is that setting it is the *only* lever
//! Token-2022 gives you, and it is all-or-nothing: whoever holds this key reads every holder's
//! every transfer, forever. That is why the live mints leave it null. Confide exists so the key can
//! be held by something that discloses on terms instead of unconditionally.

use base64::Engine;
use solana_address::Address;
use solana_hash::Hash;
use solana_keypair::Keypair;
use solana_message::Message;
use solana_signer::Signer;
use solana_transaction::Transaction;
use solana_zk_sdk::encryption::elgamal::ElGamalKeypair;
use spl_token_2022_interface::extension::confidential_transfer::instruction::update_mint;
use solana_zk_sdk_pod::encryption::elgamal::PodElGamalPubkey;
use std::str::FromStr;

const TOKEN_2022: &str = "TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb";

fn main() {
    let mut a = std::env::args().skip(1);
    let kp_path = a.next().expect("usage: set-auditor <keypair.json> <mint> <blockhash> [out.json]");
    let mint = a.next().expect("mint");
    let blockhash = a.next().expect("blockhash");
    let out = a.next().unwrap_or_else(|| "auditor-key.json".into());

    let authority = read_keypair(&kp_path);

    // The auditor key. Generated here and written out, so the demo can read the books with it.
    let auditor = ElGamalKeypair::new_rand();
    let pod = PodElGamalPubkey::from(*auditor.pubkey());
    std::fs::write(
        &out,
        serde_json::to_vec(&serde_json::json!({
            "elgamal_pubkey_b64": b64(&auditor.pubkey().to_bytes()),
            "elgamal_secret_b64": b64(auditor.secret().as_bytes()),
            "mint": mint,
        }))
        .unwrap(),
    )
    .unwrap();

    let ix = update_mint(
        &Address::from_str(TOKEN_2022).unwrap(),
        &Address::from_str(&mint).unwrap(),
        &authority.pubkey(),
        &[],
        // Keep the gate closed. `update_mint` rewrites both fields, so passing true here would
        // silently undo the `manual` the mint was created with and leave the mirror differing from
        // NVDAx in two fields while the copy claims one. It did exactly that until 09-15.
        false,
        Some(pod),
    )
    .expect("update_mint");

    let tx = Transaction::new(
        &[&authority],
        Message::new(&[ix], Some(&authority.pubkey())),
        Hash::from_str(&blockhash).expect("blockhash"),
    );

    eprintln!("  mint            {mint}");
    eprintln!("  auditor pubkey  {}", b64(&auditor.pubkey().to_bytes()));
    eprintln!("  secret written  {out}");
    println!("{}", base64::engine::general_purpose::STANDARD.encode(bincode::serialize(&tx).unwrap()));
}

fn b64(b: &[u8]) -> String {
    base64::engine::general_purpose::STANDARD.encode(b)
}

fn read_keypair(path: &str) -> Keypair {
    let bytes: Vec<u8> = serde_json::from_str(&std::fs::read_to_string(path).unwrap()).unwrap();
    Keypair::try_from(&bytes[..]).unwrap()
}
