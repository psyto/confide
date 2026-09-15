//! Anchor a sealed obligation's commitment on-chain, at `t0`.
//!
//! This is the step that makes I3 mean anything outside this process. The commitment is
//! content-blind — a 32-byte hash that reveals no position — and once the Receipt Registry holds
//! it, the fund has a dated, public, non-repudiable record of *what it will disclose at T*, made
//! on the reporting date rather than 45 days later.
//!
//! Emits a signed transaction in base64. `scripts/anchor-receipt.sh` sends it and then reads the
//! receipt back off the chain to check the stored commitment against the sealed artifact.
//!
//! **What is sealed is the live account's position.** Until 2026-09-15 this binary invented one: a
//! fresh `ElGamalKeypair::new_rand()` and a hard-coded 173,000, sealed and anchored. Every step was
//! real and none of it was about the account the demo displays, so the three things this project
//! shows — a confidential account, a proof over its ciphertext, and a dated irrevocable disclosure
//! — were three things rather than one. It now reads the account's own ciphertexts and binds the
//! commitment to them (`confide_ct::bind_position`), so the commitment on chain is about that
//! account and a number restated later cannot open it.

use base64::Engine;
use confide_ct::{bind_position, BoundPosition};
use confide_embargo::{seal, Obligation};
use solana_address::Address;
use solana_hash::Hash;
use solana_instruction::{AccountMeta, Instruction};
use solana_keypair::Keypair;
use solana_message::Message;
use solana_signer::Signer;
use solana_transaction::Transaction;
use solana_zk_sdk::encryption::auth_encryption::AeKey;
use solana_zk_sdk::encryption::elgamal::{ElGamalKeypair, ElGamalSecretKey};
use std::str::FromStr;

/// aperture-receipts, deployed to devnet from `psyto/aperture` @ v0.5.1.
const RECEIPTS_PROGRAM: &str = "6a1Kd8Yo5U9wMXUtMnU1PZF8xy6wJ6zWyMr7uKNAHytv";
const SYSTEM_PROGRAM: &str = "11111111111111111111111111111111";

/// `RecordDisclosure`.
const IX_RECORD: u8 = 0;

const USAGE: &str =
    "usage: anchor-receipt <keypair.json> <blockhash> <keys.json> <decryptable_b64> <available_b64>";

/// The bytes the receipt registry stores: `[disc][commitment:32][recipient:32][grant_id:32][i64]`.
///
/// The registry keeps that last field as `expiry` and never interprets it — it is content-blind.
/// Confide puts `open_at` there, because for an obligation the meaningful date is when it OPENS,
/// not when it lapses. A registry built for Confide would name the field for what it is.
///
/// Hashes rather than values, all the way across: the chain learns that *a* disclosure of *a*
/// commitment to *a* recipient exists, and nothing about what was disclosed.
pub fn record_data(commitment: &[u8; 32], grant_id: &[u8], open_at: i64) -> Vec<u8> {
    let mut data = Vec::with_capacity(1 + 32 * 3 + 8);
    data.push(IX_RECORD);
    data.extend_from_slice(commitment);
    data.extend_from_slice(&hash32(b"public")); // recipient: everyone, at T
    data.extend_from_slice(&hash32(grant_id));
    data.extend_from_slice(&open_at.to_le_bytes());
    data
}

fn main() {
    let mut args = std::env::args().skip(1);
    let keypair_path = args.next().expect(USAGE);
    let blockhash = args.next().expect(USAGE);
    let keys_path = args.next().expect(USAGE);
    let decryptable = d64(&args.next().expect(USAGE));
    let available = d64(&args.next().expect(USAGE));

    let issuer = read_keypair(&keypair_path);
    let program = Address::from_str(RECEIPTS_PROGRAM).unwrap();

    // The obligation Confide will open at T. Only its commitment goes on-chain.
    let (obligation, open_at, bound, account) =
        quarter_end_obligation(&keys_path, &decryptable, &available);
    let commitment = obligation.commitment();

    let (receipt, _bump) = Address::find_program_address(
        &[b"receipt", issuer.pubkey().as_ref(), &commitment],
        &program,
    );

    let data = record_data(&commitment, obligation.package.grant_id.as_bytes(), open_at);

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
    eprintln!("  account     {account}");
    eprintln!("  bound to    availableBalance {}…", b64(&bound.account_ciphertext)[..44].to_string());
    eprintln!("  commitment  {}", hex(&commitment));
    eprintln!("  receipt PDA {receipt}");
    eprintln!("  opens at    {open_at}");
    println!(
        "{}",
        base64::engine::general_purpose::STANDARD.encode(bincode::serialize(&tx).unwrap())
    );
}

/// The position of record at quarter end — read out of the account, not invented for it.
fn quarter_end_obligation(
    keys_path: &str,
    decryptable: &[u8],
    available: &[u8],
) -> (Obligation, i64, BoundPosition, String) {
    const QUARTER_END: i64 = 1_790_726_400; // 2026-09-30 00:00 UTC
    const DUE: i64 = QUARTER_END + 45 * 86_400;

    let keys: serde_json::Value =
        serde_json::from_slice(&std::fs::read(keys_path).expect("read keys.json")).unwrap();
    let account = keys["account"].as_str().expect("keys.json has an account").to_string();
    let ae = AeKey::try_from(&d64(keys["ae_key_b64"].as_str().unwrap())[..]).expect("ae key");
    let secret =
        ElGamalSecretKey::try_from(&d64(keys["elgamal_secret_b64"].as_str().unwrap())[..])
            .expect("elgamal secret");
    let fund = ElGamalKeypair::new(secret);

    // This is the line that changed. The position comes off the chain.
    let bound = bind_position(&ae, &fund, decryptable, available);

    let subject = aperture_core::package::SubjectAccount {
        address: account.clone(),
        // aperture's own adapter leaves this empty; a subject with no key is a string, and a
        // string does not identify an account.
        elgamal_pubkey: fund.pubkey().to_bytes().to_vec(),
        ciphertext_commitment: bound.commitment.clone(),
    };
    let claim = aperture_core::package::Claim::Exact;
    let proof = aperture_core::package::ProofEnvelope {
        system_id: "t22-ciphertext-commitment-equality-v1".into(),
        trust_model: aperture_core::package::TrustModel::NativeZero,
        bytes: bytemuck::bytes_of(&bound.equality).to_vec(),
    };

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

    // What the committee releases at T: the number, and the opening that ties it to the commitment
    // anchored today. Either alone proves nothing.
    let mut reader_payload = bound.balance.to_le_bytes().to_vec();
    reader_payload.extend_from_slice(bound.opening.as_bytes());
    let obligation = Obligation { package, reader_payload };

    // Sealing here is what fixes the commitment; the shares go to the release committee.
    let _ = seal(&obligation, DUE, 0, 3, 5);
    (obligation, DUE, bound, account)
}

fn read_keypair(path: &str) -> Keypair {
    let json = std::fs::read_to_string(path).expect("read keypair file");
    let bytes: Vec<u8> = serde_json::from_str(&json).expect("keypair json is a byte array");
    Keypair::try_from(&bytes[..]).expect("64-byte keypair")
}

fn hash32(b: &[u8]) -> [u8; 32] {
    aperture_core::package::hash32(b)
}

fn b64(b: &[u8]) -> String {
    base64::engine::general_purpose::STANDARD.encode(b)
}

fn d64(s: &str) -> Vec<u8> {
    base64::engine::general_purpose::STANDARD.decode(s).expect("base64")
}

fn hex(b: &[u8]) -> String {
    b.iter().map(|x| format!("{x:02x}")).collect()
}

#[cfg(test)]
mod anchoring {
    use super::*;

    const C: [u8; 32] = [7u8; 32];

    /// **N1 — the layout the registry reads, byte for byte.** The receipt is written by one
    /// program and read back by `healthcheck.sh` against the sealed artifact; a field that moved
    /// would compare the wrong 32 bytes and still look like a match against itself.
    #[test]
    fn the_record_is_the_layout_the_registry_expects() {
        let d = record_data(&C, b"obligation-q3-lp-report", 1_794_614_400);
        assert_eq!(d.len(), 1 + 32 * 3 + 8, "the receipt payload is not 105 bytes");
        assert_eq!(d[0], IX_RECORD);
        assert_eq!(&d[1..33], &C, "the commitment is not where the registry looks for it");
        assert_eq!(&d[33..65], &hash32(b"public"), "the recipient field is not the public hash");
        assert_eq!(
            i64::from_le_bytes(d[97..105].try_into().unwrap()),
            1_794_614_400,
            "the opening date does not round-trip out of the last field",
        );
    }

    /// **N2 — nothing in the payload is a value.** Every field is a hash or a date. If a grant id
    /// or a recipient ever went on chain in the clear, the anchor would leak the thing it exists
    /// to avoid leaking, and it would leak it permanently.
    #[test]
    fn no_field_carries_anything_readable() {
        let grant = b"obligation-q3-lp-report";
        let d = record_data(&C, grant, 0);
        assert!(!d.windows(grant.len()).any(|w| w == grant), "the grant id went on chain in the clear");
        assert!(!d[33..65].iter().all(|&b| b == 0), "the recipient field is empty rather than hashed");
    }

    /// **N3 — a different position anchors differently.** I3 rests on this: the receipt is derived
    /// from the commitment, so a restated figure cannot be anchored onto the receipt the original
    /// was anchored to. Equal commitments must agree and unequal ones must not.
    #[test]
    fn the_receipt_follows_the_commitment_it_is_about() {
        let other = [9u8; 32];
        assert_eq!(record_data(&C, b"g", 1)[1..33], C);
        assert_ne!(record_data(&C, b"g", 1), record_data(&other, b"g", 1));
        assert_eq!(record_data(&C, b"g", 1), record_data(&C, b"g", 1), "the payload is not deterministic");
    }

    /// **N4 — the date is the only field that is not a hash, and it is signed.** Dates before the
    /// epoch are nonsense here but must not corrupt neighbouring fields if one ever arrives.
    #[test]
    fn a_negative_date_stays_inside_its_own_field() {
        let d = record_data(&C, b"g", -1);
        assert_eq!(i64::from_le_bytes(d[97..105].try_into().unwrap()), -1);
        assert_eq!(&d[1..33], &C, "a negative date disturbed the commitment");
    }
}
