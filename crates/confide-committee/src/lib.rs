//! Shared pieces for the committee binaries.

use aperture_core::package::{ChainAnchor, DisclosurePackage, SubstrateId};
use aperture_core::token2022::issue_exact_disclosure;
use confide_embargo::Obligation;
use confide_equity::{Position, NVDAX};
use solana_zk_sdk::encryption::elgamal::{ElGamalCiphertext, ElGamalKeypair, ElGamalSecretKey};

pub const QUARTER_END: i64 = 1_790_726_400; // 2026-09-30 00:00 UTC
pub const DUE: i64 = QUARTER_END + 45 * 86_400; // 2026-11-14 — the reporting deadline
pub const ANCHOR_SLOT: u64 = 497_199_572;

/// The position of record at quarter end, sealed as an obligation. Returns it with its due date.
pub fn quarter_end_obligation() -> (Obligation, i64) {
    let fund = ElGamalKeypair::new_rand();
    let reader = ElGamalKeypair::new_rand();
    let shares = Position::from_shares(NVDAX, 173_000, 18_450).shares();

    let (claim, proof, subject) =
        issue_exact_disclosure(&fund, reader.pubkey(), shares, "fund-A-nvdax");
    let mut package = DisclosurePackage {
        package_id: "q3-report-fund-A".into(),
        grant_id: "obligation-q3-lp-report".into(),
        substrate: SubstrateId::Token2022,
        issuer: "Fund A".into(),
        recipient: "public".into(),
        issued_at: QUARTER_END,
        expiry: None,
        anchor: ChainAnchor { cluster: "devnet".into(), slot: ANCHOR_SLOT },
        subject: vec![subject],
        claim,
        proof,
        receipt_commitment: vec![],
        issuer_signature: vec![],
    };
    package.receipt_commitment = package.derive_receipt_commitment().to_vec();

    let mut reader_payload = reader.pubkey().encrypt(shares).to_bytes().to_vec();
    reader_payload.extend_from_slice(reader.secret().as_bytes());
    (Obligation { package, reader_payload }, DUE)
}

/// Read the position out of an opened obligation, the way any member of the public would.
pub fn read_position(ob: &Obligation) -> u64 {
    let (ct, secret) = ob.reader_payload.split_at(64);
    ElGamalSecretKey::try_from(secret)
        .ok()
        .and_then(|s| ElGamalCiphertext::from_bytes(ct).and_then(|c| s.decrypt_u32(&c)))
        .expect("an opened position is readable")
}

/// 173000 -> "173,000".
pub fn commas(n: u64) -> String {
    let s = n.to_string();
    let mut out = String::new();
    for (i, c) in s.chars().enumerate() {
        if i > 0 && (s.len() - i) % 3 == 0 {
            out.push(',');
        }
        out.push(c);
    }
    out
}
