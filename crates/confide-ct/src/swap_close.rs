//! `swap-close <authority.json> <ctx.json> <blockhash>`
//!
//! Give the acceptor their rent back.
//!
//! An acceptor of a two-party swap pays first: they build their own proofs and put them on chain in
//! context state accounts BEFORE either signature exists. If the offerer then walks away, the trade
//! never happens and those accounts sit there holding rent. Measured on devnet, one leg's three
//! contexts are 161, 297 and 385 bytes, so **0.008539 SOL** is stranded per abandoned attempt.
//!
//! That is not a theft — the offerer gains nothing by it — but it is a cost the abandoned side
//! should not have to eat, and the scripts had no way to undo it. Codex raised it, 2026-09-22.
//!
//! The recovery works because `swap_leg` makes the acceptor themselves the context authority, and a
//! context state account is closable by its authority. The same property is what the LOAN design
//! deliberately gives away: there the authority is the loan PDA, precisely so the borrower cannot
//! close the proofs before default. Here nobody needs to be bound after the fact, so the acceptor
//! keeps the key, and gets the rent back.
//!
//! Every context named in `ctx.json` is closed in one transaction, rent to the authority. Contexts
//! already gone are skipped rather than failing the run: an abandoned swap is exactly the situation
//! where you do not know which creates landed.

use solana_address::Address;
use solana_hash::Hash;
use solana_keypair::Keypair;
use solana_message::Message;
use solana_signer::Signer;
use solana_transaction::Transaction;
use solana_zk_elgamal_proof_interface::instruction::{close_context_state, ContextStateInfo};
use std::str::FromStr;

fn read_keypair(path: &str) -> Keypair {
    let bytes: Vec<u8> = serde_json::from_str(&std::fs::read_to_string(path).unwrap()).unwrap();
    Keypair::try_from(&bytes[..]).unwrap()
}

fn main() {
    let a: Vec<String> = std::env::args().collect();
    if a.len() < 4 {
        eprintln!("usage: swap-close <authority.json> <ctx.json> <blockhash>");
        std::process::exit(2);
    }
    let authority = read_keypair(&a[1]);
    let ctx: serde_json::Value = serde_json::from_str(&std::fs::read_to_string(&a[2]).unwrap()).unwrap();
    let blockhash = Hash::from_str(&a[3]).unwrap();

    // The authority in the file is the one the proofs were verified under. If the keypair handed in
    // is a different one, every close would fail on chain for a reason the error would not explain,
    // so say it here instead.
    if let Some(want) = ctx.get("authority").and_then(|v| v.as_str()) {
        if want != authority.pubkey().to_string() {
            eprintln!("  these contexts answer to {want}, not to {}", authority.pubkey());
            std::process::exit(1);
        }
    }

    let me = Address::from(authority.pubkey().to_bytes());
    // `floor_*` belong to the loan path and are null in a swap; reading them anyway costs nothing
    // and means one binary closes either kind.
    let names = ["equality", "range", "validity", "floor_equality", "floor_range"];
    let mut ixs = Vec::new();
    let mut closing = Vec::new();
    for n in names {
        if let Some(s) = ctx.get(n).and_then(|v| v.as_str()) {
            let acc = match Address::from_str(s) {
                Ok(x) => x,
                Err(_) => {
                    eprintln!("  {n} is not an address: {s}");
                    std::process::exit(1);
                }
            };
            ixs.push(close_context_state(
                ContextStateInfo { context_state_account: &acc, context_state_authority: &me },
                &me,
            ));
            closing.push(format!("{n} {s}"));
        }
    }
    if ixs.is_empty() {
        eprintln!("  ctx.json names no context accounts — nothing to close");
        std::process::exit(1);
    }

    let msg = Message::new(&ixs, Some(&authority.pubkey()));
    let mut tx = Transaction::new_unsigned(msg);
    tx.sign(&[&authority], blockhash);
    for c in &closing {
        eprintln!("    closing  {c}");
    }
    println!(
        "{}",
        base64::Engine::encode(
            &base64::engine::general_purpose::STANDARD,
            bincode::serialize(&tx).unwrap()
        )
    );
}
