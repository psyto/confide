//! Confide's confidential-transfer work, as a library rather than four copies.
//!
//! The seizure composition lives here because two binaries need it and a proof built twice is two
//! proofs. `build-seizure-proofs` shows the ZK program accepts them; `seizure-ctx` puts them on
//! chain in context state accounts. Same bytes, same code path.

use base64::Engine;
use solana_zk_sdk::encryption::auth_encryption::{AeCiphertext, AeKey};
use solana_zk_sdk::encryption::elgamal::{
    ElGamalCiphertext, ElGamalKeypair, ElGamalPubkey, ElGamalSecretKey,
};
use solana_zk_sdk::encryption::grouped_elgamal::GroupedElGamal;
use solana_zk_sdk::encryption::pedersen::{Pedersen, PedersenOpening};
use solana_zk_elgamal_proof_interface::proof_data::{
    batched_grouped_ciphertext_validity::BatchedGroupedCiphertext3HandlesValidityProofData,
    batched_range_proof::BatchedRangeProofU128Data,
    ciphertext_commitment_equality::CiphertextCommitmentEqualityProofData,
};
use solana_zk_sdk::zk_elgamal_proof_program::{
    batched_grouped_ciphertext_validity::build_batched_grouped_ciphertext_3_handles_validity_proof_data,
    batched_range_proof::build_batched_range_proof_u128_data,
    ciphertext_commitment_equality::build_ciphertext_commitment_equality_proof_data,
};

/// Token-2022 splits a transfer amount into a 16-bit low half and a 32-bit high half so that
/// decryption stays a small discrete log rather than a 64-bit one.
const AMOUNT_LO_BITS: usize = 16;
const AMOUNT_HI_BITS: usize = 32;
/// The source's remaining balance, proved non-negative over its full width.
const REMAINING_BALANCE_BITS: usize = 64;
/// 64 + 16 + 32 = 112, and a batched range proof's bit lengths must sum to a power of two.
const PADDING_BITS: usize = 16;

/// What a seizure needs, composed. Returned rather than printed so the invariants below can look
/// at it: an assertion about bytes that only `main` ever sees is not an assertion.
pub struct Seizure {
    pub equality: CiphertextCommitmentEqualityProofData,
    pub validity: BatchedGroupedCiphertext3HandlesValidityProofData,
    pub range: BatchedRangeProofU128Data,
    /// The source's balance after the transfer, computed on ciphertexts rather than asserted.
    pub remaining_ct: ElGamalCiphertext,
    pub remaining: u64,
    pub grouped_lo: solana_zk_sdk::encryption::grouped_elgamal::GroupedElGamalCiphertext<3>,
    pub grouped_hi: solana_zk_sdk::encryption::grouped_elgamal::GroupedElGamalCiphertext<3>,
}

/// Split a transfer amount the way Token-2022 does: a 16-bit low half and a 32-bit high half, so
/// that decrypting it is a small discrete log rather than a 64-bit one. `None` if it does not fit.
pub fn split_amount(amount: u64) -> Option<(u64, u64)> {
    let lo = amount & ((1u64 << AMOUNT_LO_BITS) - 1);
    let hi = amount >> AMOUNT_LO_BITS;
    (hi < 1u64 << AMOUNT_HI_BITS).then_some((lo, hi))
}

/// Build the three proofs. `balance` must be what `current_ct` encrypts; the caller holds the key
/// that establishes it, which is the whole reason this runs at origination and not at default.
pub fn compose(
    source: &ElGamalKeypair,
    current_ct: &ElGamalCiphertext,
    balance: u64,
    amount: u64,
    lender_pk: &ElGamalPubkey,
    auditor_pk: &ElGamalPubkey,
) -> Seizure {
    let (amount_lo, amount_hi) = split_amount(amount).expect("amount fits the transfer encoding");

    // Each half is encrypted once, under all three keys at once, under one opening. Sharing the
    // opening is what lets the same commitment appear in the validity proof and the range proof.
    let opening_lo = PedersenOpening::new_rand();
    let opening_hi = PedersenOpening::new_rand();
    let keyset = [source.pubkey(), lender_pk, auditor_pk];
    let grouped_lo = GroupedElGamal::<3>::encrypt_with(keyset, amount_lo, &opening_lo);
    let grouped_hi = GroupedElGamal::<3>::encrypt_with(keyset, amount_hi, &opening_hi);

    // What the source is left with, computed on ciphertexts rather than asserted: the transfer's
    // own source-side ciphertext is subtracted from the balance the chain holds.
    let sent_lo = grouped_lo.to_elgamal_ciphertext(0).expect("source handle");
    let sent_hi = grouped_hi.to_elgamal_ciphertext(0).expect("source handle");
    let sent = &sent_lo + &(&sent_hi * &(1u64 << AMOUNT_LO_BITS));
    let remaining_ct = current_ct - &sent;
    let remaining = balance - amount;

    // The commitment the range proof is over, and the equality proof ties it to `remaining_ct`.
    let (remaining_commitment, remaining_opening) = Pedersen::new(remaining);

    let equality = build_ciphertext_commitment_equality_proof_data(
        source,
        &remaining_ct,
        &remaining_commitment,
        &remaining_opening,
        remaining,
    )
    .expect("equality proof");

    let validity = build_batched_grouped_ciphertext_3_handles_validity_proof_data(
        source.pubkey(),
        lender_pk,
        auditor_pk,
        &grouped_lo,
        &grouped_hi,
        amount_lo,
        amount_hi,
        &opening_lo,
        &opening_hi,
    )
    .expect("ciphertext validity proof");

    let (padding_commitment, padding_opening) = Pedersen::new(0u64);
    let range = build_batched_range_proof_u128_data(
        vec![
            &remaining_commitment,
            &grouped_lo.commitment,
            &grouped_hi.commitment,
            &padding_commitment,
        ],
        vec![remaining, amount_lo, amount_hi, 0],
        vec![
            REMAINING_BALANCE_BITS,
            AMOUNT_LO_BITS,
            AMOUNT_HI_BITS,
            PADDING_BITS,
        ],
        vec![
            &remaining_opening,
            &opening_lo,
            &opening_hi,
            &padding_opening,
        ],
    )
    .expect("range proof");

    Seizure { equality, validity, range, remaining_ct, remaining, grouped_lo, grouped_hi }
}


/// Everything a caller needs to finish a seizure, including the bytes `Transfer` carries in its
/// instruction data and cannot obtain at default time.
pub struct Built {
    pub seizure: Seizure,
    pub amount: u64,
    pub remaining: u64,
    pub account_label: String,
    pub auditor_present: bool,
    /// `Transfer`'s `new_source_decryptable_available_balance`: the source's balance after the
    /// move, under the source's AE key. At default nobody has that key, so it is made now.
    pub new_decryptable_b64: String,
    pub auditor_lo_b64: String,
    pub auditor_hi_b64: String,
    pub lender_pk_b64: String,
}

impl std::ops::Deref for Built {
    type Target = Seizure;
    fn deref(&self) -> &Seizure {
        &self.seizure
    }
}

/// Resolve the arguments both binaries share — a real escrow or a throwaway one — and compose.
///
/// `synthetic:<balance>` stands up a throwaway escrow instead of reading one. What that supports is
/// a claim about the proof system, which does not depend on whose ciphertext it is. Every claim
/// that IS about a particular account needs the real keys, and says so.
pub fn build_for(
    keys_path: &str,
    decryptable: &str,
    available: &str,
    lender_arg: &str,
    auditor_arg: &str,
    amount_arg: &str,
) -> Built {
    let (source, ae, balance, current_ct, account_label) = match keys_path.strip_prefix("synthetic:")
    {
        Some(bal) => {
            let balance: u64 = bal.parse().expect("synthetic:<balance in base units>");
            let source = ElGamalKeypair::new_rand();
            let ae = AeKey::new_rand();
            let ct = source.pubkey().encrypt(balance);
            (source, ae, balance, ct, "a throwaway escrow, generated for this run".to_string())
        }
        None => {
            let keys: serde_json::Value =
                serde_json::from_slice(&std::fs::read(keys_path).unwrap()).unwrap();
            let ae = AeKey::try_from(&d64(keys["ae_key_b64"].as_str().unwrap())[..]).unwrap();
            let secret =
                ElGamalSecretKey::try_from(&d64(keys["elgamal_secret_b64"].as_str().unwrap())[..])
                    .unwrap();
            let source = ElGamalKeypair::new(secret);
            let balance = ae
                .decrypt(&AeCiphertext::from_bytes(&d64(decryptable)).expect("ae ciphertext"))
                .expect("our key opens our balance");
            let ct = ElGamalCiphertext::from_bytes(&d64(available)).expect("elgamal ciphertext");
            let label = keys["account"].as_str().unwrap_or("?").to_string();
            (source, ae, balance, ct, label)
        }
    };

    // `rand` generates one. A real loan registers the lender's key at origination; generating it
    // here keeps the destination handle a genuine key rather than a placeholder.
    let lender_pk = match lender_arg {
        "rand" => *ElGamalKeypair::new_rand().pubkey(),
        s => pubkey(s),
    };
    // An absent auditor is a real configuration — it is the one every live xStock mint is in.
    let auditor_pk = match auditor_arg {
        "none" => ElGamalPubkey::default(),
        "rand" => *ElGamalKeypair::new_rand().pubkey(),
        s => pubkey(s),
    };

    let amount = match amount_arg {
        "all" => balance,
        s => s.parse().expect("amount in base units"),
    };
    assert!(amount <= balance, "cannot seize more than the escrow holds");
    assert!(split_amount(amount).is_some(), "amount exceeds the transfer encoding");

    let seizure = compose(&source, &current_ct, balance, amount, &lender_pk, &auditor_pk);
    let remaining = seizure.remaining;

    Built {
        auditor_lo_b64: b64(&seizure.grouped_lo.to_elgamal_ciphertext(2).unwrap().to_bytes()),
        auditor_hi_b64: b64(&seizure.grouped_hi.to_elgamal_ciphertext(2).unwrap().to_bytes()),
        new_decryptable_b64: b64(&ae.encrypt(remaining).to_bytes()),
        lender_pk_b64: b64(&lender_pk.to_bytes()),
        auditor_present: auditor_arg != "none",
        seizure,
        amount,
        remaining,
        account_label,
    }
}

pub fn b64(b: &[u8]) -> String {
    base64::engine::general_purpose::STANDARD.encode(b)
}

pub fn d64(s: &str) -> Vec<u8> {
    base64::engine::general_purpose::STANDARD.decode(s).unwrap()
}

fn pubkey(s: &str) -> ElGamalPubkey {
    ElGamalPubkey::try_from(&d64(s)[..]).expect("elgamal pubkey")
}

#[cfg(test)]
mod invariants {
    use super::*;

    fn escrow(balance: u64) -> (ElGamalKeypair, ElGamalCiphertext) {
        let k = ElGamalKeypair::new_rand();
        let ct = k.pubkey().encrypt(balance);
        (k, ct)
    }

    /// **S1 — the remaining balance is computed, not claimed.** The equality proof is only worth
    /// anything if the ciphertext it binds to really is the account minus what left it. This
    /// recomputes it homomorphically and opens it with the source key.
    #[test]
    fn what_is_left_behind_is_what_the_arithmetic_says() {
        let (source, current) = escrow(173_000);
        let lender = ElGamalKeypair::new_rand();
        let auditor = ElGamalKeypair::new_rand();

        let s = compose(&source, &current, 173_000, 100_000, lender.pubkey(), auditor.pubkey());

        assert_eq!(s.remaining, 73_000);
        assert_eq!(
            source.secret().decrypt_u32(&s.remaining_ct),
            Some(73_000),
            "the ciphertext left on the account must open to the balance left on it"
        );
    }

    /// **S2 — a seizure is readable by the auditor.** The whole project is about a slot that is
    /// empty because filling it discloses everything to one party forever. A seizure that the
    /// auditor could not read would be a hole in exactly the disclosure Confide argues for, so the
    /// third handle is checked rather than assumed to be wired up.
    #[test]
    fn the_auditor_can_read_what_was_seized() {
        let (source, current) = escrow(173_000);
        let lender = ElGamalKeypair::new_rand();
        let auditor = ElGamalKeypair::new_rand();

        let s = compose(&source, &current, 173_000, 100_000, lender.pubkey(), auditor.pubkey());

        let (lo, hi) = split_amount(100_000).unwrap();
        for (grouped, half) in [(&s.grouped_lo, lo), (&s.grouped_hi, hi)] {
            // Handle 2 is the auditor's, by the order the proof is built in.
            let ct = grouped.to_elgamal_ciphertext(2).expect("auditor handle");
            assert_eq!(
                auditor.secret().decrypt_u32(&ct),
                Some(half),
                "the auditor's handle must open the amount it is a handle for"
            );
        }

        // And the lender's, for the same reason: a destination that cannot decrypt has been sent
        // nothing it can use.
        let ct = s.grouped_lo.to_elgamal_ciphertext(1).expect("lender handle");
        assert_eq!(lender.secret().decrypt_u32(&ct), Some(lo));
    }

    /// **S3 — the range proof covers exactly 128 bits.** The batch is padded with a commitment to
    /// zero for one reason: the bit lengths must sum to a power of two. Getting this wrong builds a
    /// proof the program rejects, which is a slow way to learn it.
    #[test]
    fn the_batched_bit_lengths_sum_to_the_width_they_claim() {
        assert_eq!(
            REMAINING_BALANCE_BITS + AMOUNT_LO_BITS + AMOUNT_HI_BITS + PADDING_BITS,
            128
        );
    }

    /// **S4 — an amount that will not fit is refused rather than truncated.** The transfer encoding
    /// carries 48 bits; silently wrapping a larger one would seize the wrong number.
    #[test]
    fn an_amount_too_large_for_the_encoding_is_refused() {
        assert_eq!(split_amount(0), Some((0, 0)));
        assert_eq!(split_amount(100_000), Some((34_464, 1)));
        assert_eq!(split_amount((1 << 48) - 1), Some((65_535, (1 << 32) - 1)));
        assert_eq!(split_amount(1 << 48), None, "48 bits is the ceiling, and it is enforced");
    }

    /// **S5 — seizing everything leaves a ciphertext that opens to zero.** The v1 case, and the one
    /// where an off-by-one would be least visible: a full drain must not leave dust the borrower
    /// still owns or an underflow the proof system rejects.
    #[test]
    fn a_full_seizure_leaves_exactly_nothing() {
        let (source, current) = escrow(17_300_000_000_000);
        let lender = ElGamalKeypair::new_rand();
        let auditor = ElGamalKeypair::new_rand();

        let s = compose(
            &source,
            &current,
            17_300_000_000_000,
            17_300_000_000_000,
            lender.pubkey(),
            auditor.pubkey(),
        );

        assert_eq!(s.remaining, 0);
        assert_eq!(source.secret().decrypt_u32(&s.remaining_ct), Some(0));
    }
}
