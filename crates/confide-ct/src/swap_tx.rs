//! Build the ONE transaction that swaps two confidential positions.
//!
//!   swap-tx <payer.json> <blockhash> \
//!           <a-owner.json> <a-ctx.json> <a-source> <a-dest> <a-mint> \
//!           <b-owner.json> <b-ctx.json> <b-source> <b-dest> <b-mint>
//!
//! **There is no program here, and that is the point.** Everything else in this repository needed
//! `confide-seizure` because a loan has to survive one party refusing to cooperate, and that
//! requires a third thing holding the collateral. A swap does not: both legs are in one
//! transaction, so either both settle or neither does. Solana's atomicity is the whole escrow.
//!
//! So there is no program to deploy, no upgrade authority, no account for anyone to seize, no
//! oracle and no default. Two Token-2022 `ConfidentialTransfer` instructions, two signatures.
//!
//! The proofs are NOT here either — they were verified into context state accounts beforehand,
//! which is what makes the exchange small enough to be one transaction at all. Each leg cites
//! three of them by address, and Token-2022 re-checks that they describe this source and this
//! destination, so a context built for a different transfer cannot be substituted.

use base64::Engine;
use solana_address::Address;
use solana_hash::Hash;
use solana_keypair::Keypair;
use solana_message::Message;
use solana_signer::Signer;
use solana_transaction::Transaction;
use spl_token_2022_interface::extension::confidential_transfer::instruction::{
    inner_transfer, inner_transfer_with_fee,
};
use spl_token_confidential_transfer_proof_extraction::instruction::ProofLocation;
use std::str::FromStr;

const TOKEN_2022: &str = "TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb";
const LIMIT: usize = 1232;

struct Leg {
    /// The OWNER'S PUBKEY, not their key. A leg can be assembled by someone who cannot sign it,
    /// which is the whole difference between a demonstration and a two-party trade: in a real one
    /// neither side ever holds the other's keypair.
    owner: Address,
    ctx: serde_json::Value,
    source: Address,
    destination: Address,
    mint: Address,
}

const USAGE: &str = "\
swap-tx <payer.json> <bh> <a-owner.json> <a-ctx> <a-src> <a-dst> <a-mint> <b-owner.json> ...
    one machine holding both keys. The demonstration.

swap-tx build <payer-pubkey> <bh> <a-owner-pubkey> <a-ctx> <a-src> <a-dst> <a-mint> <b-...>
    assemble UNSIGNED from pubkeys. Neither party needs the other's key.

swap-tx sign <tx.b64|-> <keypair.json>
    add one signature and print the result. Run once per party.";

fn main() {
    let a: Vec<String> = std::env::args().skip(1).collect();
    match a.first().map(String::as_str) {
        Some("build") => build_unsigned(&a[1..]),
        Some("sign") => add_signature(&a[1..]),
        _ => both_keys_here(&a),
    }
}

/// Assemble the transaction from PUBLIC keys only and sign nothing.
///
/// This is what makes a two-party swap possible at all. The legacy path below needs both keypairs
/// on one machine, which is fine for a demonstration and is not a trade: in a real one neither
/// side ever sees the other's key, so somebody has to be able to build the thing they will both
/// sign without being able to sign it for them.
fn build_unsigned(a: &[String]) {
    if a.len() < 12 {
        eprintln!("{USAGE}");
        std::process::exit(2);
    }
    let payer = addr(&a[0]);
    let blockhash = Hash::from_str(&a[1]).expect("blockhash");
    let legs = [leg_pub(&a[2..7]), leg_pub(&a[7..12])];
    let ixs: Vec<_> = legs.iter().map(instruction).collect();
    let tx = Transaction::new_unsigned(Message::new(&ixs, Some(&payer)));
    let mut tx = tx;
    tx.message.recent_blockhash = blockhash;
    report(&tx);
    println!("{}", base64::engine::general_purpose::STANDARD.encode(bincode::serialize(&tx).unwrap()));
}

/// Add exactly one signature. Run once by each party, on a transaction they have inspected.
///
/// `partial_sign` rather than `sign`: the whole point is that the transaction is incomplete until
/// both have looked at it. A party who dislikes the other leg simply never runs this, and nothing
/// has happened.
fn add_signature(a: &[String]) {
    if a.len() < 2 {
        eprintln!("{USAGE}");
        std::process::exit(2);
    }
    let raw = if a[0] == "-" {
        let mut s = String::new();
        std::io::Read::read_to_string(&mut std::io::stdin(), &mut s).expect("stdin");
        s
    } else {
        std::fs::read_to_string(&a[0]).expect("tx file")
    };
    let bytes = base64::engine::general_purpose::STANDARD
        .decode(raw.trim())
        .expect("base64");
    let mut tx: Transaction = bincode::deserialize(&bytes).expect("transaction");
    let kp = keypair(&a[1]);
    let bh = tx.message.recent_blockhash;
    tx.partial_sign(&[&kp], bh);
    let signed = tx.signatures.iter().filter(|s| **s != Default::default()).count();
    eprintln!(
        "  signed by {}   {} of {} signatures present",
        kp.pubkey(),
        signed,
        tx.signatures.len()
    );
    println!("{}", base64::engine::general_purpose::STANDARD.encode(bincode::serialize(&tx).unwrap()));
}

/// The original form: both keypairs on one machine. Kept because `swap-e2e.sh` is a demonstration
/// and demonstrating it end to end on one box is the point of that script.
fn both_keys_here(a: &[String]) {
    if a.len() < 12 {
        eprintln!("{USAGE}");
        std::process::exit(2);
    }
    let payer = keypair(&a[0]);
    let blockhash = Hash::from_str(&a[1]).expect("blockhash");
    let owners = [keypair(&a[2]), keypair(&a[7])];
    let legs = [
        leg_with(owners[0].pubkey(), &a[3..7]),
        leg_with(owners[1].pubkey(), &a[8..12]),
    ];
    let ixs: Vec<_> = legs.iter().map(instruction).collect();
    // Both owners sign, each authorising only their own leg. Neither can move the other's tokens,
    // and neither can be made to move their own — a party who dislikes the other leg simply does
    // not sign, and nothing has happened.
    let signers: Vec<&Keypair> = vec![&payer, &owners[0], &owners[1]];
    let tx = Transaction::new(
        &dedup(&signers),
        Message::new(&ixs, Some(&payer.pubkey())),
        blockhash,
    );
    report(&tx);
    println!("{}", base64::engine::general_purpose::STANDARD.encode(bincode::serialize(&tx).unwrap()));
}

fn report(tx: &Transaction) {
    let bytes = bincode::serialize(tx).unwrap();
    eprintln!(
        "  one transaction    {} bytes{}",
        bytes.len(),
        if bytes.len() > LIMIT { "   <- OVER the 1,232-byte limit" } else { "" }
    );
}

fn leg_pub(a: &[String]) -> Leg {
    leg_with(addr(&a[0]), &a[1..5])
}

fn leg_with(owner: Address, a: &[String]) -> Leg {
    Leg {
        owner,
        ctx: serde_json::from_slice(&std::fs::read(&a[0]).expect("ctx.json")).unwrap(),
        source: addr(&a[1]),
        destination: addr(&a[2]),
        mint: addr(&a[3]),
    }
}

/// A leg is built from whatever its `ctx.json` says it is. A mint that charges a transfer fee —
/// PYUSD charges 0 bps and still has the extension — refuses the plain `Transfer` outright with
/// `InvalidInstructionData`, so the two are not interchangeable and the artifact decides.
fn instruction(l: &Leg) -> solana_instruction::Instruction {
    let g = |k: &str| d64(l.ctx[k].as_str().unwrap_or_else(|| panic!("{k} missing from ctx.json")));
    let (dec, lo, hi) = (
        g("new_decryptable_b64"),
        g("auditor_lo_b64"),
        g("auditor_hi_b64"),
    );
    let ctx = |k: &str| addr(l.ctx[k].as_str().unwrap_or_else(|| panic!("{k} missing from ctx.json")));
    let token = addr(TOKEN_2022);
    if l.ctx["with_fee"].as_bool().unwrap_or(false) {
        inner_transfer_with_fee(
            &token,
            &l.source,
            &l.mint,
            &l.destination,
            bytemuck::from_bytes(&dec),
            bytemuck::from_bytes(&lo),
            bytemuck::from_bytes(&hi),
            &l.owner,
            &[],
            ProofLocation::ContextStateAccount(&ctx("equality")),
            ProofLocation::ContextStateAccount(&ctx("validity")),
            ProofLocation::ContextStateAccount(&ctx("percentage")),
            ProofLocation::ContextStateAccount(&ctx("fee_validity")),
            ProofLocation::ContextStateAccount(&ctx("range")),
        )
        .expect("inner_transfer_with_fee")
    } else {
        inner_transfer(
            &token,
            &l.source,
            &l.mint,
            &l.destination,
            bytemuck::from_bytes(&dec),
            bytemuck::from_bytes(&lo),
            bytemuck::from_bytes(&hi),
            &l.owner,
            &[],
            ProofLocation::ContextStateAccount(&ctx("equality")),
            ProofLocation::ContextStateAccount(&ctx("validity")),
            ProofLocation::ContextStateAccount(&ctx("range")),
        )
        .expect("inner_transfer")
    }
}

/// The payer is usually one of the two owners, and signing the same key twice is an error.
fn dedup<'a>(s: &[&'a Keypair]) -> Vec<&'a Keypair> {
    let mut seen = Vec::new();
    let mut out = Vec::new();
    for k in s {
        if !seen.contains(&k.pubkey()) {
            seen.push(k.pubkey());
            out.push(*k);
        }
    }
    out
}

fn keypair(path: &str) -> Keypair {
    let v: Vec<u8> = serde_json::from_slice(&std::fs::read(path).expect("keypair file")).unwrap();
    Keypair::try_from(&v[..]).expect("64-byte keypair")
}

fn addr(s: &str) -> Address {
    Address::from_str(s).expect("address")
}

fn d64(s: &str) -> Vec<u8> {
    base64::engine::general_purpose::STANDARD.decode(s).expect("base64")
}
