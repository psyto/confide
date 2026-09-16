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
    batched_range_proof::{BatchedRangeProofU128Data, BatchedRangeProofU64Data},
    ciphertext_commitment_equality::CiphertextCommitmentEqualityProofData,
};
use solana_zk_sdk::zk_elgamal_proof_program::{
    batched_grouped_ciphertext_validity::build_batched_grouped_ciphertext_3_handles_validity_proof_data,
    batched_range_proof::{build_batched_range_proof_u128_data, build_batched_range_proof_u64_data},
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
/// The two proofs that establish **this escrow holds at least `floor`**, over the escrow's own
/// on-chain ciphertext. `prove-collateral` has built these since the beginning and printed them;
/// nothing parked them in context accounts, so `originate` came to require two accounts no tool in
/// this repository produced. That is what this exists to fix.
pub struct Floor {
    pub equality: CiphertextCommitmentEqualityProofData,
    pub range: BatchedRangeProofU64Data,
}

/// `balance >= floor`, proved against `keys`' own account ciphertext and nothing else.
///
/// The surplus is committed under the **same** opening as the equality commitment, so a verifier
/// reaches it by subtracting `floor·G` from that commitment rather than taking the prover's word
/// for which commitment the range proof is about. `programs/confide-seizure`'s `floor_is_proved`
/// is the other half of that subtraction.
pub fn build_floor(keys: &BuiltKeys, floor: u64) -> Floor {
    assert!(
        keys.balance >= floor,
        "refusing to prove a false statement: the escrow does not clear the floor"
    );
    let opening = PedersenOpening::new_rand();
    let commitment = Pedersen::with(keys.balance, &opening);
    let equality = build_ciphertext_commitment_equality_proof_data(
        &keys.source, &keys.current_ct, &commitment, &opening, keys.balance,
    )
    .expect("equality proof over the escrow's own ciphertext");

    let delta = keys.balance - floor;
    let delta_commitment = Pedersen::with(delta, &opening);
    let range = build_batched_range_proof_u64_data(
        vec![&delta_commitment], vec![delta], vec![64], vec![&opening],
    )
    .expect("range proof over the surplus");

    Floor { equality, range }
}

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
/// An escrow opened for proof-building: a real one read from `keys.json` and the chain, or a
/// throwaway one stood up for a claim that is about the proof system rather than about an account.
pub struct BuiltKeys {
    pub source: ElGamalKeypair,
    pub ae: AeKey,
    pub balance: u64,
    pub current_ct: ElGamalCiphertext,
    pub label: String,
}

/// `synthetic:<balance>` stands up a throwaway escrow instead of reading one. What that supports is
/// a claim about the proof system, which does not depend on whose ciphertext it is. Every claim that
/// IS about a particular account needs the real keys, and says so.
pub fn open_escrow(keys_path: &str, decryptable: &str, available: &str) -> BuiltKeys {
    match keys_path.strip_prefix("synthetic:") {
        Some(bal) => {
            let balance: u64 = bal.parse().expect("synthetic:<balance in base units>");
            let source = ElGamalKeypair::new_rand();
            let ae = AeKey::new_rand();
            let current_ct = source.pubkey().encrypt(balance);
            BuiltKeys { source, ae, balance, current_ct,
                        label: "a throwaway escrow, generated for this run".into() }
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
            let current_ct =
                ElGamalCiphertext::from_bytes(&d64(available)).expect("elgamal ciphertext");
            let label = keys["account"].as_str().unwrap_or("?").to_string();
            BuiltKeys { source, ae, balance, current_ct, label }
        }
    }
}

pub fn build_for(
    keys_path: &str,
    decryptable: &str,
    available: &str,
    lender_arg: &str,
    auditor_arg: &str,
    amount_arg: &str,
) -> Built {
    let BuiltKeys { source, ae, balance, current_ct, label: account_label } =
        open_escrow(keys_path, decryptable, available);

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


/// What a de-shield needs: two proofs, and the balance it leaves behind.
///
/// `Withdraw` moves a confidential balance into the account's **own public balance** — it has no
/// destination. That is the property this is built for: once the collateral is public, moving it is
/// an ordinary SPL transfer, so **the destination does not have to be known at origination**. A
/// seizure pre-built for one named lender becomes a de-shield that any liquidation path can pick up.
pub struct Deshield {
    pub equality: CiphertextCommitmentEqualityProofData,
    pub range: BatchedRangeProofU64Data,
    /// The source's balance afterwards. For a full de-shield this is zero.
    pub remaining: u64,
    /// `Withdraw` carries this in its instruction data, and at default nobody has the AE key.
    pub new_decryptable_b64: String,
}

/// Build them. Cheaper than the transfer set in section 2 of docs/SEIZURE.md: no validity proof,
/// because there is no destination handle to prove anything about.
pub fn compose_deshield(
    source: &ElGamalKeypair,
    ae: &AeKey,
    current_ct: &ElGamalCiphertext,
    balance: u64,
    amount: u64,
) -> Deshield {
    let remaining = balance.checked_sub(amount).expect("cannot de-shield more than is held");
    let (commitment, opening) = Pedersen::new(remaining);

    // The ciphertext the account is left holding, computed rather than asserted. Withdrawing is
    // public subtraction: the amount leaves the confidential balance in the clear, so it is encoded
    // with **no randomness** — an opening of zero, which makes the decrypt handle the identity and
    // the ciphertext a plain commitment. `ElGamal::encode` does exactly this and is crate-private,
    // so it is spelled out rather than reached for.
    let public = source.pubkey().encrypt_with(amount, &PedersenOpening::default());
    let remaining_ct = current_ct - &public;

    let equality = build_ciphertext_commitment_equality_proof_data(
        source, &remaining_ct, &commitment, &opening, remaining,
    )
    .expect("equality proof");

    let range = build_batched_range_proof_u64_data(
        vec![&commitment], vec![remaining], vec![REMAINING_BALANCE_BITS], vec![&opening],
    )
    .expect("range proof");

    Deshield { equality, range, remaining, new_decryptable_b64: b64(&ae.encrypt(remaining).to_bytes()) }
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

// ---------------------------------------------------------------------------------------------
// A position of record that is about an account, not about a number.
// ---------------------------------------------------------------------------------------------
//
// Sealing a disclosure is only worth anything if the thing sealed is the holder's actual position.
// Until 2026-09-15 the anchoring path generated a fresh random ElGamal key and a hard-coded share
// count, sealed that, and anchored its commitment — every byte of which was real, and none of which
// was about the live account the demo displayed. A reviewer caught it. This is the fix.
//
// The construction is the one `prove-collateral` already uses, for the same reason: an account's
// ElGamal ciphertext carries no Pedersen opening we hold, so nothing can be proved *about* it
// directly. Bind a commitment we can open to it with a ciphertext-commitment equality proof, and
// the commitment inherits the account. At T the committee publishes the value and the opening;
// anyone recomputes the commitment, checks it against the sealed one, and checks the equality proof
// against the ciphertext that account held on the reporting date.

/// A sealed position, bound to the on-chain ciphertext it was read from.
pub struct BoundPosition {
    /// The account's `availableBalance` as it stood on the reporting date.
    pub account_ciphertext: Vec<u8>,
    /// A Pedersen commitment to the same value.
    pub commitment: Vec<u8>,
    /// Proof that the commitment and that ciphertext hold the same value.
    pub equality: CiphertextCommitmentEqualityProofData,
    /// The position itself. Secret until T; the committee holds the shares.
    pub balance: u64,
    /// Opens `commitment`. Released with `balance`, and useless without it.
    pub opening: PedersenOpening,
}

/// Read the position out of the account and bind a commitment to it.
///
/// `decryptable` and `available` are the two ciphertexts Token-2022 keeps on the account:
/// `decryptableAvailableBalance` (AES, so the holder can read the number) and `availableBalance`
/// (ElGamal, so it can be proved about). Both come straight off `getAccountInfo`.
pub fn bind_position(
    ae: &AeKey,
    elgamal: &ElGamalKeypair,
    decryptable: &[u8],
    available: &[u8],
) -> BoundPosition {
    let balance = ae
        .decrypt(&AeCiphertext::from_bytes(decryptable).expect("ae ciphertext"))
        .expect("our key opens our balance");
    let ct = ElGamalCiphertext::from_bytes(available).expect("elgamal ciphertext");

    let opening = PedersenOpening::new_rand();
    let commitment = Pedersen::with(balance, &opening);
    let equality =
        build_ciphertext_commitment_equality_proof_data(elgamal, &ct, &commitment, &opening, balance)
            .expect("equality proof");

    BoundPosition {
        account_ciphertext: available.to_vec(),
        commitment: commitment.to_bytes().to_vec(),
        equality,
        balance,
        opening,
    }
}

/// The check a reader runs at T, given what the committee published.
///
/// This is deliberately not "does the number look right" — there is nothing to compare it against.
/// It is: does this number, with this opening, produce the commitment that was sealed on the
/// reporting date? A holder who reports a different figure later cannot make one that does.
pub fn opens_sealed_position(commitment: &[u8], balance: u64, opening: &PedersenOpening) -> bool {
    Pedersen::with(balance, opening).to_bytes().as_slice() == commitment
}

#[cfg(test)]
mod bound_position_tests {
    use super::*;

    /// Stand up an account's two ciphertexts the way the chain holds them.
    fn account(balance: u64) -> (AeKey, ElGamalKeypair, Vec<u8>, Vec<u8>) {
        let ae = AeKey::new_rand();
        let elgamal = ElGamalKeypair::new_rand();
        let decryptable = ae.encrypt(balance).to_bytes().to_vec();
        let available = elgamal.pubkey().encrypt(balance).to_bytes().to_vec();
        (ae, elgamal, decryptable, available)
    }

    #[test]
    fn the_sealed_commitment_opens_to_the_position_the_account_held() {
        let (ae, eg, dec, avail) = account(173_000_00000000);
        let b = bind_position(&ae, &eg, &dec, &avail);
        assert_eq!(b.balance, 173_000_00000000);
        assert!(opens_sealed_position(&b.commitment, b.balance, &b.opening));
    }

    /// The whole point of I3: the number cannot be tidied after the fact.
    #[test]
    fn a_restated_number_does_not_open_the_sealed_commitment() {
        let (ae, eg, dec, avail) = account(173_000_00000000);
        let b = bind_position(&ae, &eg, &dec, &avail);
        assert!(!opens_sealed_position(&b.commitment, 200_000_00000000, &b.opening));
        assert!(!opens_sealed_position(&b.commitment, b.balance - 1, &b.opening));
    }

    /// And it is bound to *this* account: the proof carries the ciphertext it was made against.
    #[test]
    fn the_binding_names_the_account_ciphertext_it_was_read_from() {
        let (ae, eg, dec, avail) = account(1_000);
        let b = bind_position(&ae, &eg, &dec, &avail);
        assert_eq!(b.account_ciphertext, avail);
        let (_, _, _, other) = account(1_000);
        assert_ne!(b.account_ciphertext, other, "two accounts holding the same value differ");
    }
}

#[cfg(test)]
mod deshielding {
    use super::*;

    fn escrow(balance: u64) -> (ElGamalKeypair, AeKey, ElGamalCiphertext) {
        let k = ElGamalKeypair::new_rand();
        let ct = k.pubkey().encrypt(balance);
        (k, AeKey::new_rand(), ct)
    }

    /// **W1 — what is left after a full de-shield decrypts to zero.** The whole point: the
    /// confidential balance becomes the account's public balance, and the confidential side is
    /// empty. If the arithmetic were wrong the equality proof would be over a ciphertext that is
    /// not what the account holds, and the token program would reject it at default — the worst
    /// possible time to find out.
    #[test]
    fn a_full_deshield_leaves_a_ciphertext_that_opens_to_zero() {
        let (k, ae, ct) = escrow(17_300_000_000_000);
        let d = compose_deshield(&k, &ae, &ct, 17_300_000_000_000, 17_300_000_000_000);
        assert_eq!(d.remaining, 0);
        let public = k.pubkey().encrypt_with(17_300_000_000_000u64, &PedersenOpening::default());
        assert_eq!(k.secret().decrypt_u32(&(&ct - &public)), Some(0));
    }

    /// **W2 — a partial de-shield leaves the rest readable.** The same arithmetic has to hold when
    /// something stays behind, or the mechanism only works in the one case it was tested in.
    #[test]
    fn a_partial_deshield_leaves_the_remainder() {
        let (k, ae, ct) = escrow(173_000);
        let d = compose_deshield(&k, &ae, &ct, 173_000, 100_000);
        assert_eq!(d.remaining, 73_000);
        let public = k.pubkey().encrypt_with(100_000u64, &PedersenOpening::default());
        assert_eq!(k.secret().decrypt_u32(&(&ct - &public)), Some(73_000));
    }

    /// **W3 — the zero opening really is the public encoding.** `ElGamal::encode` is crate-private,
    /// so this rebuilds it from a zero opening. The property that makes it the right substitute is
    /// that *any* key opens it: it is a commitment in the clear, not an encryption.
    #[test]
    fn the_public_encoding_is_readable_by_any_key() {
        let mine = ElGamalKeypair::new_rand();
        let stranger = ElGamalKeypair::new_rand();
        let encoded = mine.pubkey().encrypt_with(42u64, &PedersenOpening::default());
        assert_eq!(stranger.secret().decrypt_u32(&encoded), Some(42),
                   "a withdrawn amount must be public; if a stranger cannot read it, it is not");
    }

    /// **W4 — the de-shield carries the AE balance `Withdraw` needs.** At default nobody holds the
    /// AE key, so the value has to exist from origination, exactly as with the transfer path.
    #[test]
    fn the_new_decryptable_balance_is_built_at_origination() {
        let (k, ae, ct) = escrow(173_000);
        let d = compose_deshield(&k, &ae, &ct, 173_000, 173_000);
        let raw = d64(&d.new_decryptable_b64);
        assert_eq!(raw.len(), 36, "not an AE ciphertext");
        assert_eq!(ae.decrypt(&AeCiphertext::from_bytes(&raw).unwrap()), Some(0));
    }

    /// **W5 — de-shielding more than is held is refused, not wrapped.** A wrap would compose a
    /// proof over a balance the account does not have.
    #[test]
    #[should_panic(expected = "cannot de-shield more than is held")]
    fn overdrawing_is_refused() {
        let (k, ae, ct) = escrow(100);
        compose_deshield(&k, &ae, &ct, 100, 101);
    }
}
