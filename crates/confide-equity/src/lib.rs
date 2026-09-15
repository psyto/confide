//! The equity layer — what makes this about stocks rather than about balances.
//!
//! Two things live here:
//!
//! 1. [`XStock`] — the tokenized equities this is actually about, as they are configured on
//!    mainnet today. Not illustrative constants: every field was read from the chain and is
//!    reproducible with `scripts/onchain-check.sh`.
//! 2. [`nav_floor_disclosure`] — the other half of a quarterly report. An LPA does not only ask
//!    "what do you hold"; it also carries covenants of the form *"the fund is at or above X"*,
//!    which must be answerable **before** the position itself is disclosable. It is a predicate,
//!    it reveals no position, and its proof verifies against Solana's live ZK ElGamal Proof
//!    Program.

pub mod actions;

use aperture_core::package::{Claim, ProofEnvelope, SubjectAccount};
use aperture_core::token2022::issue_range_disclosure;
use solana_zk_sdk::encryption::elgamal::ElGamalKeypair;

/// A tokenized equity, as configured on Solana mainnet.
///
/// `auditor_elgamal_pubkey` is `None` on every one of them. That is the whole problem: the mint
/// has confidential transfers switched on and the only disclosure model it offers — a single
/// global key that decrypts everything forever — has no correct setting, so the slot sits empty
/// and the feature goes unused.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct XStock {
    pub symbol: &'static str,
    pub name: &'static str,
    /// Token-2022 mint. The `Xs` prefix is the issuer's vanity.
    pub mint: &'static str,
    pub decimals: u8,
    /// The `confidentialTransferMint` extension is present on the mint.
    pub confidential_transfers: bool,
    /// `confidentialTransferMint.auditorElgamalPubkey`, as read from mainnet.
    pub auditor_elgamal_pubkey: Option<&'static str>,
    /// `confidentialTransferMint.autoApproveNewAccounts` — the issuer gates who may hold a
    /// confidential balance, which is why this repo demonstrates against a mirrored mint rather
    /// than opening a confidential account on the live one.
    pub auto_approve_new_accounts: bool,
}

/// Read from `api.mainnet-beta.solana.com` on 2026-09-12. See `docs/ONCHAIN.md`.
pub const NVDAX: XStock = XStock {
    symbol: "NVDAx",
    name: "NVIDIA xStock",
    mint: "Xsc9qvGR1efVDFGLrVsmkzv3qi45LTBjeUKSPmx9qEh",
    decimals: 8,
    confidential_transfers: true,
    auditor_elgamal_pubkey: None,
    auto_approve_new_accounts: false,
};

pub const TSLAX: XStock = XStock {
    symbol: "TSLAx",
    name: "Tesla xStock",
    mint: "XsDoVfqeBukxuZHWhdvWHBhgEHjGNst4MLodqsJHzoB",
    decimals: 8,
    confidential_transfers: true,
    auditor_elgamal_pubkey: None,
    auto_approve_new_accounts: false,
};

pub const SPYX: XStock = XStock {
    symbol: "SPYx",
    name: "SP500 xStock",
    mint: "XsoCS1TfEyfFhfvj8EtZ528L3CaKBDBRqRapnBbDF2W",
    decimals: 8,
    confidential_transfers: true,
    auditor_elgamal_pubkey: None,
    auto_approve_new_accounts: false,
};

pub const AAPLX: XStock = XStock {
    symbol: "AAPLx",
    name: "Apple xStock",
    mint: "XsbEhLAtcf6HdfpFZ5xEMdqW8nfAvcsP5bdudRLJzJp",
    decimals: 8,
    confidential_transfers: true,
    auditor_elgamal_pubkey: None,
    auto_approve_new_accounts: false,
};

pub const XSTOCKS: [XStock; 4] = [NVDAX, TSLAX, SPYX, AAPLX];

/// A holding, in the mint's base units.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Position {
    pub stock: XStock,
    /// Base units, i.e. shares × 10^decimals.
    pub base_units: u64,
    /// Reference price per share, in cents. A pinned input, **not an oracle** — pricing is a
    /// non-goal here, and a real report would take marks from the fund's administrator.
    pub price_cents: u64,
}

impl Position {
    pub fn from_shares(stock: XStock, shares: u64, price_cents: u64) -> Self {
        Position { stock, base_units: shares * 10u64.pow(stock.decimals as u32), price_cents }
    }

    pub fn shares(&self) -> u64 {
        self.base_units / 10u64.pow(self.stock.decimals as u32)
    }

    pub fn value_cents(&self) -> u64 {
        self.shares() * self.price_cents
    }
}

/// An example NAV floor: the covenant level a fund reports against each quarter.
///
/// This is a **contract term, not a statute** — LPAs set their own. $100M is used here because it
/// is the level at which the US Form 13F obligation would bite if these were Section 13(f)
/// securities, which they are not (see DESIGN.md §3a). Treat it as a default, not a rule.
pub const DEFAULT_NAV_FLOOR_CENTS: u64 = 100_000_000_00;

#[derive(Debug)]
pub struct ThresholdAttestation {
    pub claim: Claim,
    pub proof: ProofEnvelope,
    pub subject: SubjectAccount,
    /// What the predicate asserts, in cents — the only number this reveals.
    pub threshold_cents: u64,
    /// The one bit the recipient learns.
    pub above_floor: bool,
}

/// Prove *"this portfolio is at or above the floor"* — and nothing else.
///
/// The LP learns whether the covenant holds. It does not learn the portfolio's value, its
/// composition, or any position. The proof this returns is a real `BatchedRangeProofU64Data`;
/// `confide-onchain` submits these same bytes to Solana's live ZK ElGamal Proof Program, so the
/// predicate is not merely checkable off-chain.
///
/// Returns `None` when the portfolio is below the floor — there is nothing to prove, and
/// manufacturing a proof of a false statement is the one thing this must not do.
pub fn nav_floor_disclosure(
    fund: &ElGamalKeypair,
    positions: &[Position],
    threshold_cents: u64,
) -> Option<ThresholdAttestation> {
    let total: u64 = positions.iter().map(Position::value_cents).sum();
    if total < threshold_cents {
        return None;
    }
    let (claim, proof, subject) =
        issue_range_disclosure(fund, total, threshold_cents, "fund-A-portfolio");
    Some(ThresholdAttestation { claim, proof, subject, threshold_cents, above_floor: true })
}

#[cfg(test)]
mod tests {
    use super::*;

    fn portfolio() -> Vec<Position> {
        vec![
            Position::from_shares(NVDAX, 173, 18_450),  // $184.50
            Position::from_shares(TSLAX, 900, 42_100),  // $421.00
            Position::from_shares(SPYX, 1_100, 66_800), // $668.00
        ]
    }

    /// The four mints pinned in this crate have confidential transfers on and no auditor key.
    /// This guards the constants, not the premise: the premise is about all 1,869 mints and only
    /// `scripts/slot-scan.sh` covers those. If Backed fills a key on a mint that is not one of
    /// these four, this test stays green and the scan is what catches it.
    #[test]
    fn every_xstock_has_confidential_transfers_and_an_empty_auditor_slot() {
        for s in XSTOCKS {
            assert!(s.confidential_transfers, "{} has no confidentialTransferMint", s.symbol);
            assert_eq!(s.auditor_elgamal_pubkey, None, "{} has an auditor key now", s.symbol);
            assert!(!s.auto_approve_new_accounts, "{} stopped gating accounts", s.symbol);
        }
    }

    #[test]
    fn shares_round_trip_through_base_units() {
        let p = Position::from_shares(NVDAX, 173, 18_450);
        assert_eq!(p.base_units, 173 * 100_000_000);
        assert_eq!(p.shares(), 173);
        assert_eq!(p.value_cents(), 173 * 18_450);
    }

    /// The LP learns one bit — the covenant holds — and no position.
    #[test]
    fn the_floor_predicate_reveals_only_whether_the_covenant_holds() {
        let fund = ElGamalKeypair::new_rand();
        let att = nav_floor_disclosure(&fund, &portfolio(), 1_000_00)
            .expect("portfolio is above this floor");
        assert!(att.above_floor);
        assert_eq!(att.claim, Claim::Range { min: 1_000_00, max: None });
        // The package carries a commitment, never a plaintext position.
        assert!(!att.subject.ciphertext_commitment.is_empty());
        let total: u64 = portfolio().iter().map(Position::value_cents).sum();
        assert!(!att.proof.bytes.windows(8).any(|w| w == total.to_le_bytes()));
    }

    /// Below the floor there is nothing to prove, and no proof is produced.
    #[test]
    fn a_portfolio_below_the_floor_gets_no_proof() {
        let fund = ElGamalKeypair::new_rand();
        let small = vec![Position::from_shares(NVDAX, 1, 18_450)];
        assert!(nav_floor_disclosure(&fund, &small, DEFAULT_NAV_FLOOR_CENTS).is_none());
    }
}
