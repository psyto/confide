//! The three claims Mora makes, written so they can be run rather than believed.
//!
//! A fund accumulates NVDAx. The obligation is: *this position becomes public at T, and until
//! then only the auditor sees it.* Each test below is one sentence from DESIGN.md §3, executable.

use aperture_core::package::{ChainAnchor, DisclosurePackage, SubstrateId};
use aperture_core::policy::{AuthzDecision, Granularity, Grant, Recipient, Trigger, Validity};
use aperture_core::token2022::{issue_exact_disclosure, Token2022Substrate};
use aperture_core::verifier::verify_package;
use mora_embargo::{open, seal, Obligation, OpenError, ReleaseTrustModel};
use solana_zk_sdk::encryption::elgamal::{ElGamalCiphertext, ElGamalKeypair, ElGamalSecretKey};
use std::collections::HashSet;

const T0_SLOT: u64 = 340_000_000; // the position is still being built
const T: i64 = 1_772_323_200; // when the obligation comes due
const BEFORE_T: i64 = T - 43 * 86_400; // mid-accumulation, 43 days early
const NVDAX_SHARES: u64 = 173;

/// The fund's exact NVDAx position, sealed as an obligation addressed to `recipient`.
///
/// The reader key is generated here and its secret goes into the obligation — so what opens at `T`
/// is a position someone can actually read, not merely verify.
fn position(fund: &ElGamalKeypair, shares: u64, recipient: &str, pkg_id: &str) -> (Obligation, ElGamalKeypair) {
    let reader = ElGamalKeypair::new_rand();
    let (claim, proof, subject) = issue_exact_disclosure(fund, reader.pubkey(), shares, "fund-A-nvdax");
    let mut pkg = DisclosurePackage {
        package_id: pkg_id.into(),
        grant_id: "obligation-13f-q3".into(),
        substrate: SubstrateId::Token2022,
        issuer: "fund-A".into(),
        recipient: recipient.into(),
        issued_at: BEFORE_T,
        expiry: None,
        anchor: ChainAnchor { cluster: "mainnet-beta".into(), slot: T0_SLOT },
        subject: vec![subject],
        claim,
        proof,
        receipt_commitment: vec![],
        issuer_signature: vec![],
    };
    pkg.receipt_commitment = pkg.derive_receipt_commitment().to_vec();

    // The out-of-band material: the position re-encrypted under the reader key, then that key's
    // secret. Together these are exactly what a reader needs and what the seal must transport.
    let mut reader_payload = reader.pubkey().encrypt(shares).to_bytes().to_vec();
    reader_payload.extend_from_slice(reader.secret().as_bytes());

    (Obligation { package: pkg, reader_payload }, reader)
}

/// Read a position out of an opened obligation, the way any member of the public would at `T`.
fn read_position(ob: &Obligation) -> u64 {
    let (ct_bytes, secret_bytes) = ob.reader_payload.split_at(64);
    let ct = ElGamalCiphertext::from_bytes(ct_bytes).expect("ciphertext");
    let secret = ElGamalSecretKey::try_from(secret_bytes).expect("reader secret");
    secret.decrypt_u32(&ct).expect("the opened position is readable")
}

/// **I1 — unopenable before T.**
///
/// Every agent refuses, so no share is published, so there is nothing to reconstruct from. Note
/// what is *not* claimed: the seal does not become mathematically harder before T. The refusal is
/// the agents', and `ReleaseTrustModel` says so on the artifact itself.
#[test]
fn i1_before_t_no_agent_will_publish_and_nothing_opens() {
    let fund = ElGamalKeypair::new_rand();
    let (ob, _) = position(&fund, NVDAX_SHARES, "public", "pkg-q3");
    let (sealed, agents) = seal(&ob, T, T0_SLOT, 3, 5);

    for agent in &agents {
        let refusal = agent.publish(&sealed, BEFORE_T).expect_err("agent published early");
        assert_eq!(refusal.opens_at, T);
    }

    assert_eq!(open(&sealed, &[]), Err(OpenError::CannotReconstruct));

    // The assumption I1 rests on is stated on the artifact, not left to the reader.
    assert_eq!(sealed.trust, ReleaseTrustModel::ThresholdCommittee { k: 3, n: 5 });
}

/// **I1, threshold actually binds.** k-1 agents at T still cannot open.
#[test]
fn i1_k_minus_one_agents_cannot_open_even_at_t() {
    let fund = ElGamalKeypair::new_rand();
    let (ob, _) = position(&fund, NVDAX_SHARES, "public", "pkg-q3");
    let (sealed, agents) = seal(&ob, T, T0_SLOT, 3, 5);

    let two: Vec<_> = agents[..2].iter().map(|a| a.publish(&sealed, T).unwrap()).collect();
    assert!(matches!(
        open(&sealed, &two),
        Err(OpenError::WrongKey) | Err(OpenError::CannotReconstruct)
    ));
}

/// **I2 — unstoppable at T, including by the holder.**
///
/// The holder is destroyed after sealing: the package and the fund's keypair are dropped, and
/// nothing derived from them is in scope below. The position still becomes public, from the
/// published artifact and the agents alone.
#[test]
fn i2_the_holder_is_gone_and_the_position_opens_anyway() {
    let (sealed, agents) = {
        let fund = ElGamalKeypair::new_rand();
        let (ob, _reader) = position(&fund, NVDAX_SHARES, "public", "pkg-q3");
        seal(&ob, T, T0_SLOT, 3, 5)
        // `fund`, `ob` and the reader keypair all drop here. The holder no longer exists.
    };

    let published: Vec<_> = agents[..3].iter().map(|a| a.publish(&sealed, T).unwrap()).collect();
    let opened = open(&sealed, &published).expect("the obligation came due and nothing could stop it");

    assert_eq!(opened.package.issuer, "fund-A");
    assert_eq!(opened.package.anchor.slot, T0_SLOT);
    // ...and it is readable, not merely verifiable. This is the number on the demo screen.
    assert_eq!(read_position(&opened), NVDAX_SHARES);
    // Any 3 of the 5 will do — the committee cannot be deadlocked by picking the wrong three.
    let other: Vec<_> = [0usize, 2, 4].iter().map(|&i| agents[i].publish(&sealed, T).unwrap()).collect();
    assert_eq!(open(&sealed, &other).unwrap(), opened);
}

/// **I3 — bound to the position actually held.**
///
/// The fund tries to substitute a flattering position for the one it committed to at `t0`: it
/// seals a second package and splices it under the first commitment. The swap is caught, because
/// the commitment was anchored while the position was still being built.
#[test]
fn i3_a_position_swapped_in_after_the_fact_is_caught() {
    let fund = ElGamalKeypair::new_rand();

    let (truth, _) = position(&fund, NVDAX_SHARES, "public", "pkg-q3");
    let (sealed_truth, _) = seal(&truth, T, T0_SLOT, 3, 5);

    let (flattering, _) = position(&fund, 5, "public", "pkg-q3-revised");
    let (sealed_lie, lie_agents) = seal(&flattering, T, T0_SLOT, 3, 5);

    // Keep the anchored commitment; swap in the other package's sealed bytes.
    let spliced = mora_embargo::SealedDisclosure {
        commitment: sealed_truth.commitment,
        ciphertext: sealed_lie.ciphertext,
        nonce: sealed_lie.nonce,
        ..sealed_truth.clone()
    };

    let published: Vec<_> = lie_agents[..3].iter().map(|a| a.publish(&spliced, T).unwrap()).collect();
    match open(&spliced, &published) {
        Err(OpenError::CommitmentMismatch { anchored, found }) => {
            assert_eq!(anchored, sealed_truth.commitment);
            assert_ne!(found, anchored);
        }
        other => panic!("a post-hoc position swap was not caught: {other:?}"),
    }
}

/// **I4 — the auditor reads continuously, before T.**
///
/// Compliance is never delayed; only *public* disclosure is. This is the confidential-treatment
/// shape — the regulator already holds the position while the market does not.
#[test]
fn i4_the_auditor_sees_the_position_while_the_public_seal_is_still_shut() {
    let fund = ElGamalKeypair::new_rand();

    let (public_ob, _) = position(&fund, NVDAX_SHARES, "public", "pkg-q3");
    let (sealed, agents) = seal(&public_ob, T, T0_SLOT, 3, 5);
    assert!(agents[0].publish(&sealed, BEFORE_T).is_err(), "public must still be shut");

    // Same position, disclosed to the auditor now, under a standing grant.
    let grant = Grant {
        id: "grant-auditor-standing".into(),
        recipient: Recipient { name: "auditor".into(), verifier_key: vec![] },
        granularity: Granularity::Exact,
        trigger: Trigger::OnRequest,
        validity: Validity { not_after: None, revocable: true },
    };
    assert_eq!(grant.authorize_new_disclosure(BEFORE_T, &HashSet::new()), AuthzDecision::Allowed);

    let (to_auditor, _) = position(&fund, NVDAX_SHARES, "auditor", "pkg-q3-auditor");
    let report = verify_package(&to_auditor.package, &Token2022Substrate, BEFORE_T, "auditor");
    assert!(report.passed(), "auditor could not verify the position: {report:?}");
    // The auditor reads the exact position now, 43 days before the public can.
    assert_eq!(read_position(&to_auditor), NVDAX_SHARES);
}

/// **I5 — opening is irreversible.**
///
/// From `aperture::policy`: *revocation is not clawback.* Revoking the standing grant stops future
/// disclosures. It has no effect on a sealed obligation whose shares are already public — which is
/// the correct behaviour, since an obligation you can revoke is not an obligation.
#[test]
fn i5_revoking_the_grant_does_not_unopen_what_is_already_open() {
    let fund = ElGamalKeypair::new_rand();
    let (ob, _) = position(&fund, NVDAX_SHARES, "public", "pkg-q3");
    let (sealed, agents) = seal(&ob, T, T0_SLOT, 3, 5);

    let published: Vec<_> = agents[..3].iter().map(|a| a.publish(&sealed, T).unwrap()).collect();
    let opened = open(&sealed, &published).expect("opens at T");

    let mut revoked = HashSet::new();
    revoked.insert("obligation-13f-q3".to_string());
    let grant = Grant {
        id: "obligation-13f-q3".into(),
        recipient: Recipient { name: "public".into(), verifier_key: vec![] },
        granularity: Granularity::Exact,
        trigger: Trigger::Periodic,
        validity: Validity { not_after: None, revocable: true },
    };
    assert_eq!(grant.authorize_new_disclosure(T + 1, &revoked), AuthzDecision::Revoked);

    // ...and the already-published shares still open the seal. Nothing was clawed back.
    assert_eq!(open(&sealed, &published).unwrap(), opened);
}
