//! Shared pieces for the committee binaries.

use aperture_core::package::{
    ChainAnchor, Claim, DisclosurePackage, ProofEnvelope, SubjectAccount, SubstrateId, TrustModel,
};
use confide_ct::{bind_position, opens_sealed_position};
use confide_embargo::Obligation;
use confide_equity::{Position, NVDAX};
use solana_zk_sdk::encryption::auth_encryption::AeKey;
use solana_zk_sdk::encryption::elgamal::{ElGamalKeypair, ElGamalSecretKey};
use solana_zk_sdk::encryption::pedersen::PedersenOpening;

pub const QUARTER_END: i64 = 1_790_726_400; // 2026-09-30 00:00 UTC
pub const DUE: i64 = QUARTER_END + 45 * 86_400; // 2026-11-14 — the reporting deadline
pub const ANCHOR_SLOT: u64 = 497_199_572;

/// The account whose position is being sealed, read off the chain by the caller.
pub struct LiveAccount<'a> {
    pub keys_path: &'a str,
    /// `confidentialTransferAccount.decryptableAvailableBalance`, base64-decoded.
    pub decryptable: &'a [u8],
    /// `confidentialTransferAccount.availableBalance`, base64-decoded.
    pub available: &'a [u8],
}

/// The position of record at quarter end, sealed as an obligation. Returns it, its due date, and a
/// line saying which account it is about.
///
/// With `Some(live)` the seal is bound to that account's own ciphertext: the commitment anchored on
/// the reporting date is about *that* account, and a figure restated later cannot open it. With
/// `None` a throwaway account is stood up so the committee demo runs with no network and no keys —
/// the construction is identical, which is the point of having one code path, but the account is
/// invented and the caller is told so rather than left to assume.
pub fn quarter_end_obligation(live: Option<LiveAccount>) -> (Obligation, i64, String) {
    let (ae, fund, decryptable, available, account) = match live {
        Some(l) => {
            let keys: serde_json::Value =
                serde_json::from_slice(&std::fs::read(l.keys_path).expect("read keys.json")).unwrap();
            let ae = AeKey::try_from(&d64(keys["ae_key_b64"].as_str().unwrap())[..]).expect("ae key");
            let secret =
                ElGamalSecretKey::try_from(&d64(keys["elgamal_secret_b64"].as_str().unwrap())[..])
                    .expect("elgamal secret");
            let account = keys["account"].as_str().expect("keys.json has an account").to_string();
            (ae, ElGamalKeypair::new(secret), l.decryptable.to_vec(), l.available.to_vec(), account)
        }
        None => {
            let ae = AeKey::new_rand();
            let fund = ElGamalKeypair::new_rand();
            let shares = Position::from_shares(NVDAX, 173_000, 18_450).shares();
            let dec = ae.encrypt(shares).to_bytes().to_vec();
            let avail = fund.pubkey().encrypt(shares).to_bytes().to_vec();
            (ae, fund, dec, avail, "(a throwaway account, no keys given)".to_string())
        }
    };

    let bound = bind_position(&ae, &fund, &decryptable, &available);

    let subject = SubjectAccount {
        address: account.clone(),
        elgamal_pubkey: fund.pubkey().to_bytes().to_vec(),
        ciphertext_commitment: bound.commitment.clone(),
    };
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
        claim: Claim::Exact,
        proof: ProofEnvelope {
            system_id: "t22-ciphertext-commitment-equality-v1".into(),
            trust_model: TrustModel::NativeZero,
            bytes: bytemuck::bytes_of(&bound.equality).to_vec(),
        },
        receipt_commitment: vec![],
        issuer_signature: vec![],
    };
    package.receipt_commitment = package.derive_receipt_commitment().to_vec();

    // What the committee releases at T: the number, and the opening that ties it to the sealed
    // commitment. Either alone proves nothing.
    let mut reader_payload = bound.balance.to_le_bytes().to_vec();
    reader_payload.extend_from_slice(bound.opening.as_bytes());
    (Obligation { package, reader_payload }, DUE, account)
}

/// Read the position out of an opened obligation, the way any member of the public would — and
/// check it against what was sealed rather than taking it on faith.
///
/// Returns the position and whether it opens the commitment the receipt anchored on the reporting
/// date. A `false` here is the interesting case: it means the number being published is not the
/// number that was sealed.
pub fn read_position(ob: &Obligation) -> (u64, bool) {
    let (value, opening) = ob.reader_payload.split_at(8);
    let base_units = u64::from_le_bytes(value.try_into().expect("8-byte position"));
    let opening = PedersenOpening::from_bytes(opening).expect("32-byte opening");
    let sealed = &ob.package.subject[0].ciphertext_commitment;
    // The commitment is over what the account actually holds, which Token-2022 counts in base
    // units. Shares are that divided by the mint's decimals — a presentation detail, so the check
    // happens on the committed figure and the division only after it passes.
    let opens = opens_sealed_position(sealed, base_units, &opening);
    (base_units / 10u64.pow(NVDAX.decimals as u32), opens)
}

fn d64(s: &str) -> Vec<u8> {
    use base64::Engine;
    base64::engine::general_purpose::STANDARD.decode(s).expect("base64")
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
