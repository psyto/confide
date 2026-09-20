//! `read-balance <keys.json> <decryptable_b64> <available_b64> [decimals]`
//!
//! Decrypts an account's confidential balance with the key we generated for it. The public balance
//! on that account reads `0`; this is what the holder sees, and nobody else.
//!
//! Both ciphertexts come off the chain. The AE one is symmetric and opens instantly; the ElGamal
//! one is the value a disclosure has to be *about*, which is why holding its key is the difference
//! between a proof about a number and a proof about this account.

use base64::Engine;
use solana_zk_sdk::encryption::auth_encryption::{AeCiphertext, AeKey};
use solana_zk_sdk::encryption::elgamal::{ElGamalCiphertext, ElGamalSecretKey};

fn main() {
    let mut a = std::env::args().skip(1);
    let keys_path = a.next().expect("usage: read-balance <keys.json> <decryptable_b64> <available_b64>");
    let decryptable = d64(&a.next().expect("decryptable"));
    let available = d64(&a.next().expect("available"));
    // The mint's, not a constant. This printed a cash balance of $8,750,000 as "87500 units" for
    // exactly one run, because 8 was written into the line below — the same hardcoded-decimals bug
    // `provision` had, in the one place whose whole job is reporting a number to a human.
    let decimals: u32 = a
        .next()
        .map(|d| d.parse().expect("decimals must be a number"))
        .unwrap_or(8);

    let keys: serde_json::Value = serde_json::from_slice(&std::fs::read(&keys_path).unwrap()).unwrap();
    let ae = AeKey::try_from(&d64(keys["ae_key_b64"].as_str().unwrap())[..]).expect("ae key");
    let secret =
        ElGamalSecretKey::try_from(&d64(keys["elgamal_secret_b64"].as_str().unwrap())[..]).expect("secret");

    let ct = AeCiphertext::from_bytes(&decryptable).expect("ae ciphertext");
    let base = ae.decrypt(&ct).expect("our key opens our balance");

    println!("  account            {}", keys["account"].as_str().unwrap_or("?"));
    println!("  public balance     0            <- what the chain shows anyone");
    let whole = 10u64.pow(decimals);
    println!(
        "  confidential       {} base units  = {} units  ({} decimals)",
        base,
        base / whole,
        decimals
    );
    println!();

    // The ElGamal side is the one a disclosure must be about. Full u64 balances are held as a
    // lo/hi split precisely because discrete log only recovers small values, so this reports what
    // it can rather than pretending to recover the whole number from one ciphertext.
    match ElGamalCiphertext::from_bytes(&available) {
        Some(el) => {
            print!("  elgamal ciphertext {} bytes, ours to prove over", available.len());
            match secret.decrypt_u32(&el) {
                Some(v) => println!("  (decrypts directly: {v})"),
                None => println!("  (beyond direct discrete log — the lo/hi split is what an auditor reads)"),
            }
        }
        None => println!("  elgamal ciphertext unreadable"),
    }
}

fn d64(s: &str) -> Vec<u8> {
    base64::engine::general_purpose::STANDARD.decode(s).unwrap()
}
