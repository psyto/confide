//! Anchor a sealed obligation's commitment on-chain, at `t0`.
//!
//! This is the step that makes I3 mean anything outside this process. The commitment is
//! content-blind — a 32-byte hash that reveals no position — and once the Receipt Registry holds
//! it, the fund has a dated, public, non-repudiable record of *what it will disclose at T*, made
//! on the reporting date rather than 45 days later.
//!
//! Emits a signed transaction in base64. `scripts/anchor-receipt.sh` sends it and then reads the
//! receipt back off the chain to check the stored commitment against the sealed artifact.

use base64::Engine;
use confide_embargo::{seal, Obligation};
use confide_equity::{Position, NVDAX};
use solana_address::Address;
use solana_hash::Hash;
use solana_instruction::{AccountMeta, Instruction};
use solana_keypair::Keypair;
use solana_message::Message;
use solana_signer::Signer;
use solana_transaction::Transaction;
use solana_zk_sdk::encryption::elgamal::ElGamalKeypair;
use std::str::FromStr;

/// aperture-receipts, deployed to devnet from `psyto/aperture` @ v0.5.1.
const RECEIPTS_PROGRAM: &str = "6a1Kd8Yo5U9wMXUtMnU1PZF8xy6wJ6zWyMr7uKNAHytv";
const SYSTEM_PROGRAM: &str = "11111111111111111111111111111111";

/// `RecordDisclosure`.
const IX_RECORD: u8 = 0;

fn main() {
    let mut args = std::env::args().skip(1);
    let keypair_path = args.next().expect("usage: anchor-receipt <keypair.json> <blockhash>");
    let blockhash = args.next().expect("usage: anchor-receipt <keypair.json> <blockhash>");

    let issuer = read_keypair(&keypair_path);
    let program = Address::from_str(RECEIPTS_PROGRAM).unwrap();

    // The obligation Confide will open at T. Only its commitment goes on-chain.
    let (obligation, open_at) = quarter_end_obligation();
    let commitment = obligation.commitment();

    let (receipt, _bump) = Address::find_program_address(
        &[b"receipt", issuer.pubkey().as_ref(), &commitment],
        &program,
    );

    // data = [disc][commitment:32][recipient:32][grant_id:32][expiry i64 LE]
    //
    // The registry stores that last field as `expiry` and never interprets it — it is
    // content-blind. Confide puts `open_at` there: for an obligation the meaningful date is when it
    // OPENS, not when it lapses. A registry built for Confide would name the field for what it is.
    let mut data = Vec::with_capacity(1 + 32 * 3 + 8);
    data.push(IX_RECORD);
    data.extend_from_slice(&commitment);
    data.extend_from_slice(&hash32(b"public")); // recipient: everyone, at T
    data.extend_from_slice(&hash32(obligation.package.grant_id.as_bytes()));
    data.extend_from_slice(&open_at.to_le_bytes());

    let ix = Instruction {
        program_id: program,
        accounts: vec![
            AccountMeta::new(issuer.pubkey(), true),
            AccountMeta::new(receipt, false),
            AccountMeta::new_readonly(Address::from_str(SYSTEM_PROGRAM).unwrap(), false),
        ],
        data,
    };

    let msg = Message::new(&[ix], Some(&issuer.pubkey()));
    let tx = Transaction::new(&[&issuer], msg, Hash::from_str(&blockhash).expect("blockhash"));

    // stdout line 1: the transaction. stderr: what a human needs to check it.
    eprintln!("  issuer      {}", issuer.pubkey());
    eprintln!("  commitment  {}", hex(&commitment));
    eprintln!("  receipt PDA {receipt}");
    eprintln!("  opens at    {open_at}");
    println!(
        "{}",
        base64::engine::general_purpose::STANDARD.encode(bincode::serialize(&tx).unwrap())
    );
}

/// The position of record at quarter end, sealed. Mirrors `confide-demo`.
fn quarter_end_obligation() -> (Obligation, i64) {
    const QUARTER_END: i64 = 1_790_726_400; // 2026-09-30 00:00 UTC
    const DUE: i64 = QUARTER_END + 45 * 86_400;

    let fund = ElGamalKeypair::new_rand();
    let reader = ElGamalKeypair::new_rand();
    let shares = Position::from_shares(NVDAX, 173_000, 18_450).shares();

    let (claim, proof, subject) = aperture_core::token2022::issue_exact_disclosure(
        &fund,
        reader.pubkey(),
        shares,
        "fund-A-nvdax",
    );
    let mut package = aperture_core::package::DisclosurePackage {
        package_id: "q3-report-fund-A".into(),
        grant_id: "obligation-q3-lp-report".into(),
        substrate: aperture_core::package::SubstrateId::Token2022,
        issuer: "Fund A".into(),
        recipient: "public".into(),
        issued_at: QUARTER_END,
        expiry: None,
        anchor: aperture_core::package::ChainAnchor {
            cluster: "devnet".into(),
            slot: 0,
        },
        subject: vec![subject],
        claim,
        proof,
        receipt_commitment: vec![],
        issuer_signature: vec![],
    };
    package.receipt_commitment = package.derive_receipt_commitment().to_vec();

    let mut reader_payload = reader.pubkey().encrypt(shares).to_bytes().to_vec();
    reader_payload.extend_from_slice(reader.secret().as_bytes());
    let obligation = Obligation { package, reader_payload };

    // Sealing here is what fixes the commitment; the shares go to the release committee.
    let _ = seal(&obligation, DUE, 0, 3, 5);
    (obligation, DUE)
}

fn read_keypair(path: &str) -> Keypair {
    let json = std::fs::read_to_string(path).expect("read keypair file");
    let bytes: Vec<u8> = serde_json::from_str(&json).expect("keypair json is a byte array");
    Keypair::try_from(&bytes[..]).expect("64-byte keypair")
}

fn hash32(b: &[u8]) -> [u8; 32] {
    aperture_core::package::hash32(b)
}

fn hex(b: &[u8]) -> String {
    b.iter().map(|x| format!("{x:02x}")).collect()
}
