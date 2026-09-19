//! What the receiving side of a swap checks BEFORE it signs.
//!
//!   swap-check <my-keys.json> <validity-context-account-base64>
//!
//! An atomic swap of two confidential positions has one danger, and it is not the atomicity:
//! **the amounts are encrypted, so a party could sign a transaction whose other leg sends far less
//! than was agreed.** Both legs settle, and the loss is discovered afterwards by decrypting a
//! balance.
//!
//! It is answerable without trusting anyone, because of how a confidential transfer is built. The
//! amount is encrypted once under three keys at once — the sender's, the RECEIVER's, and the
//! auditor's — and that grouped ciphertext is what the validity proof is verified over and what
//! sits in the context state account. So the receiver can decrypt, from the pre-verified context,
//! the exact amount the transfer will move to them. No proof of a floor and no third party.
//!
//! This reads that context and reports three things: whether the transfer is addressed to this
//! key at all, how much it moves, and who sent it. Anything else in the transaction is visible in
//! the transaction itself.
//!
//! The context is already VERIFIED when this runs — the ZK ElGamal Proof Program checked it, and
//! the account is immutable afterwards. So the amount read here is the amount the transfer will
//! carry: Token-2022 will cite this same account by address and re-check it against the transfer's
//! source and destination.

use base64::Engine;
use solana_zk_sdk::encryption::elgamal::{ElGamalCiphertext, ElGamalSecretKey};
use solana_zk_sdk_pod::encryption::elgamal::{PodElGamalCiphertext, PodElGamalPubkey};

/// `ProofContextState`: authority(32) | proof_type(1) | context
const CONTEXT: usize = 33;
/// `BatchedGroupedCiphertext3HandlesValidityProofContext`: three keys, then two grouped ciphertexts
const KEYS: usize = 32 * 3;
const GROUPED: usize = 32 * 4; // commitment, then one decryption handle per key
/// The keyset order is fixed at construction: source, recipient, auditor.
const HANDLE_RECIPIENT: usize = 2; // commitment(0), source handle(1), recipient handle(2)
const AMOUNT_LO_BITS: u32 = 16;
const PROOF_TYPE_BATCHED_VALIDITY_3: u8 = 12;

fn main() {
    let mut a = std::env::args().skip(1);
    let keys_path = a.next().expect("my-keys.json");
    let data_b64 = a.next().expect("the validity context account's data, base64");

    let keys: serde_json::Value =
        serde_json::from_slice(&std::fs::read(&keys_path).expect("keys.json")).unwrap();
    // The secret alone; the account's public key is recorded beside it and is what the context
    // names as the recipient.
    let mine = ElGamalSecretKey::try_from(
        &b64(keys["elgamal_secret_b64"].as_str().expect("elgamal_secret_b64"))[..],
    )
    .expect("my elgamal secret");
    let my_pubkey = keys["elgamal_pubkey_b64"]
        .as_str()
        .expect("elgamal_pubkey_b64")
        .to_string();

    let d = b64(&data_b64);
    if d.len() < CONTEXT + KEYS + GROUPED * 2 {
        die("that account is too small to be a 3-handle validity context");
    }
    if d[32] != PROOF_TYPE_BATCHED_VALIDITY_3 {
        die(&format!(
            "that context holds proof type {}, not the ciphertext validity proof a transfer's amount lives in",
            d[32]
        ));
    }

    let key = |n: usize| -> String {
        let mut k = [0u8; 32];
        k.copy_from_slice(&d[CONTEXT + 32 * n..CONTEXT + 32 * (n + 1)]);
        PodElGamalPubkey(k).to_string()
    };
    let base = CONTEXT + KEYS;
    // Same opening, so both halves share a commitment layout; the recipient's half of each is a
    // plain ElGamal ciphertext once the right handle is picked out.
    let half = |off: usize| -> ElGamalCiphertext {
        let mut ct = [0u8; 64];
        ct[..32].copy_from_slice(&d[off..off + 32]); // the commitment
        ct[32..].copy_from_slice(&d[off + 32 * HANDLE_RECIPIENT..off + 32 * (HANDLE_RECIPIENT + 1)]);
        ElGamalCiphertext::try_from(PodElGamalCiphertext(ct)).expect("recipient ciphertext")
    };

    // Compare the raw bytes rather than two spellings of them: the context holds 32 bytes and the
    // keys file holds the same 32 in base64.
    let addressed_to_me = d[CONTEXT + 32..CONTEXT + 64] == b64(&my_pubkey)[..];
    println!();
    println!("  \x1b[1mTHE LEG YOU ARE BEING ASKED TO SIGN\x1b[0m");
    println!("      from ElGamal key   {}", key(0));
    println!("      to   ElGamal key   {}", key(1));
    println!("      auditor            {}", key(2));
    if !addressed_to_me {
        println!(
            "  \x1b[31m✗\x1b[0m this transfer is NOT addressed to you\n      \x1b[2myour key is {}\x1b[0m",
            my_pubkey
        );
        std::process::exit(1);
    }
    println!("  \x1b[32m✓\x1b[0m it is addressed to your key");

    let (lo, hi) = (
        mine.decrypt_u32(&half(base)),
        mine.decrypt_u32(&half(base + GROUPED)),
    );
    match (lo, hi) {
        (Some(lo), Some(hi)) => {
            let amount = lo as u64 + ((hi as u64) << AMOUNT_LO_BITS);
            println!(
                "  \x1b[32m✓\x1b[0m it will move \x1b[1m{amount}\x1b[0m base units to you\n      \x1b[2mdecrypted from the verified context, by you, without anyone's cooperation\x1b[0m"
            );
            println!("\n  \x1b[2mIf that is not the amount you agreed, do not sign. Nothing has happened yet.\x1b[0m\n");
        }
        _ => die("the amount did not decrypt — this context was not built for your key"),
    }
}

fn b64(s: &str) -> Vec<u8> {
    base64::engine::general_purpose::STANDARD
        .decode(s)
        .expect("base64")
}

fn die(m: &str) -> ! {
    eprintln!("  \x1b[31m✗\x1b[0m {m}");
    std::process::exit(1)
}
