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
            // Base units, not shares. Token-2022 counts base units and `read_position` divides by
            // the mint's decimals to present shares; encrypting shares here made the keyless demo
            // seal 173,000 base units and read back 0 NVDAx — a commitment that opened correctly
            // onto the wrong number, which is the failure mode this whole project is against.
            let base_units = Position::from_shares(NVDAX, 173_000, 18_450).base_units;
            let dec = ae.encrypt(base_units).to_bytes().to_vec();
            let avail = fund.pubkey().encrypt(base_units).to_bytes().to_vec();
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

#[cfg(test)]
mod tests {
    use super::*;

    /// **C1 — what the committee publishes opens what it sealed.** The round trip nothing tested:
    /// `quarter_end_obligation` builds the commitment and `read_position` is the public reading it
    /// back. If these two ever stopped agreeing, `scripts/committee.sh` would print a position and
    /// a green tick over a commitment it does not open.
    #[test]
    fn the_published_number_opens_the_sealed_commitment() {
        let (ob, _due, _account) = quarter_end_obligation(None);
        let (shares, opens) = read_position(&ob);
        assert!(opens, "the payload the committee releases does not open its own commitment");
        assert_eq!(shares, 173_000, "the position read back is not the position sealed");
    }

    /// **C2 — the case the doc comment calls the interesting one, and the one I3 is about.** A
    /// number substituted after the seal must not open it. Without this, `read_position`'s second
    /// return value is decoration: it would be `true` for anything.
    #[test]
    fn a_number_swapped_in_after_the_seal_does_not_open_it() {
        let (mut ob, _due, _account) = quarter_end_obligation(None);
        let sealed = u64::from_le_bytes(ob.reader_payload[..8].try_into().unwrap());

        // One share more than was sealed, and everything else — the opening, the commitment, the
        // package — left exactly as it was. This is what tidying a quarterly number looks like.
        let tidied = (sealed + 10u64.pow(NVDAX.decimals as u32)).to_le_bytes();
        ob.reader_payload[..8].copy_from_slice(&tidied);

        let (_shares, opens) = read_position(&ob);
        assert!(!opens, "a position restated after the seal opened the commitment anyway");
    }

    /// **C3 — the opening is load-bearing too.** Keeping the sealed number but substituting a
    /// different opening must also fail: the check has to be over the pair, not over either half.
    #[test]
    fn the_right_number_with_the_wrong_opening_does_not_open_it() {
        let (mut ob, _due, _account) = quarter_end_obligation(None);
        let other = PedersenOpening::new_rand();
        ob.reader_payload[8..].copy_from_slice(other.as_bytes());
        let (_shares, opens) = read_position(&ob);
        assert!(!opens, "the sealed number opened the commitment under an opening it was not sealed with");
    }

    /// **C4 — the seal is dated, and the opening is 45 days after it.** The lag is the product; an
    /// off-by-one in the constant would ship a disclosure schedule that is quietly wrong.
    #[test]
    fn the_obligation_comes_due_forty_five_days_after_the_reporting_date() {
        let (_ob, due, _account) = quarter_end_obligation(None);
        assert_eq!(due - QUARTER_END, 45 * 24 * 60 * 60, "the embargo is not 45 days long");
    }

    /// **C5 — grouping, at the boundaries where it goes wrong.** It is printed next to every
    /// figure the demo shows.
    #[test]
    fn thousands_are_grouped_where_they_should_be() {
        for (n, want) in [(0u64, "0"), (1, "1"), (999, "999"), (1_000, "1,000"),
                          (10_000, "10,000"), (173_000, "173,000"), (1_000_000, "1,000,000")] {
            assert_eq!(commas(n), want, "commas({n})");
        }
    }
}
