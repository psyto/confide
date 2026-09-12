//! # Confide — a self-opening embargo
//!
//! A disclosure obligation is not a grant. `aperture::policy::Grant` is *permissive*: a standing
//! authorization for the holder to produce future disclosures, expiring at `not_after` — a window
//! that **closes**. An obligation is *mandatory*, and its window **opens**:
//!
//! - **I1** — unopenable before `T`.
//! - **I2** — unstoppable at `T` by the holder *as a party to the protocol*. See
//!   [`ReleaseTrustModel`] for what it still costs: a holder who captures `n - k + 1` agents stops
//!   it anyway, and no signature here prevents that.
//! - **I3** — bound to the position actually held, committed before the position was complete.
//!
//! I2 is why this is a mechanism and not a policy field. No schema expresses "the holder cannot
//! stop this". Here it is expressed structurally: **the holder is not a parameter of any function
//! on the opening path.** Look at [`ReleaseAgent::publish`] and [`open`] — neither can name them.
//!
//! ## What actually enforces the clock (read this before trusting I1)
//!
//! Shamir shares carry no clock. Once `k` agents hold shares, nothing in mathematics stops them
//! from combining early; what stops them is that they are separate parties who are not supposed to.
//! So [`open`] takes **no `now` argument** — it would be a lie, implying a check that cryptography
//! is not doing. The clock lives in [`ReleaseAgent::publish`], where the party that actually holds
//! it can refuse.
//!
//! The assumption is named in the type system rather than hidden, the same way `aperture` surfaces
//! `TrustModel` per substrate: see [`ReleaseTrustModel`].

pub mod shamir;

use aperture_core::package::DisclosurePackage;
use chacha20poly1305::{
    aead::{Aead, AeadCore, KeyInit, OsRng},
    XChaCha20Poly1305, XNonce,
};
use serde::{Deserialize, Serialize};

pub type UnixTime = i64;

/// What an observer must assume about the committee. **Both I1 and I2 rest on this** — a correction
/// to an earlier version of this comment, which claimed I2 was unconditional. It is not.
///
/// With `k` of `n`:
/// - **I1 fails if `k` agents collude to open early.** Shares carry no clock; nothing in the
///   mathematics stops them.
/// - **I2 fails if `n - k + 1` agents withhold at `T`.** The holder is not a *parameter* of the
///   opening path, which is what the signatures guarantee; that is not the same as the holder being
///   unable to *capture* agents. A holder who controls enough of the committee — by owning it, by
///   paying it, or by injuncting it — stops the disclosure, and no code here prevents that.
/// - **Only I3 is unconditional.** It is a hash comparison and depends on no one's behaviour.
///
/// Choosing `k` therefore trades the two risks against each other and cannot minimise both:
/// `k = 3, n = 5` tolerates 2 early colluders and 2 withholders. Confide ships `ThresholdCommittee`
/// and says so on the artifact, because an embargo whose assumption is unstated is
/// indistinguishable from one that has none.
#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize)]
pub enum ReleaseTrustModel {
    /// `k` of `n` release agents: fewer than `k` collude early, and at least `k` remain willing
    /// at `T`. No cryptographic time barrier, and no economic stake — an agent that withholds
    /// loses nothing today.
    ThresholdCommittee { k: u8, n: u8 },
    /// A cryptographic time barrier (a time-lock puzzle, a VDF, or a public randomness beacon
    /// with timelock encryption): **I1 holds with no committee at all**, and I2 needs only the
    /// ciphertext to be public — which it already is from `t0`.
    ///
    /// Not implemented, and named here so the upgrade path is legible rather than mistaken for
    /// shipped. This is the one change that would make both I1 and I2 unconditional.
    TimeLockPuzzle,
}

/// The artifact published at **accumulation time** (`t0`), not at `T`.
///
/// Publishing the ciphertext at `t0` is what makes the disclosure unstoppable: after this exists
/// in the open, the holder has no lever left to pull. A sealed disclosure that the holder keeps in
/// a drawer until `T` is a promise, not an obligation.
#[derive(Clone, Debug, Serialize, Deserialize, PartialEq, Eq)]
pub struct SealedDisclosure {
    /// `aperture`'s content-blind receipt commitment for the package inside. Anchored on-chain at
    /// `t0` by the Receipt Registry; reveals nothing about the position.
    pub commitment: [u8; 32],
    /// The slot at which `commitment` was anchored — i.e. *before* the position was complete.
    /// This is what makes I3 mean something: the claim is dated earlier than its own disclosure.
    pub anchored_slot: u64,
    /// `T`. When the obligation comes due.
    pub open_at: UnixTime,
    /// What must be assumed for I1.
    pub trust: ReleaseTrustModel,
    /// The sealed package. Public from `t0` — and useless until `k` shares exist.
    pub ciphertext: Vec<u8>,
    pub nonce: [u8; 24],
}

/// A share published by one release agent once the obligation has come due.
#[derive(Clone, Debug, Serialize, Deserialize, PartialEq, Eq)]
pub struct ReleaseShare {
    pub agent_index: u8,
    pub bytes: Vec<u8>,
}

/// What is actually sealed: the disclosure package **and the material needed to read it**.
///
/// `aperture`'s Exact claim *binds* a value with a ciphertext-ciphertext equality proof but does
/// not transport it — its own doc says the verifier "decrypts the returned value out-of-band".
/// Confide's seal **is** that out-of-band channel. Sealing the package alone would open at `T` into a
/// position that verifies and cannot be read, which is not a disclosure.
#[derive(Clone, Debug, Serialize, Deserialize, PartialEq, Eq)]
pub struct Obligation {
    pub package: DisclosurePackage,
    /// The out-of-band material the `Exact` claim's reader needs: the value re-encrypted under
    /// the reader key, plus that key's secret. Empty for predicate-only claims (`Range` /
    /// `Aggregate`), which reveal no plaintext and need nothing transported.
    pub reader_payload: Vec<u8>,
}

impl Obligation {
    /// The content-blind commitment anchored on-chain at `t0`. Delegates to `aperture` — it binds
    /// the package and never the reader payload, so anchoring it at `t0` leaks nothing.
    pub fn commitment(&self) -> [u8; 32] {
        self.package.derive_receipt_commitment()
    }
}

/// One release agent. Holds a share and a clock; holds no power over the content.
///
/// An agent cannot read the position, cannot alter it, and cannot tell whether the package it is
/// unlocking flatters its holder or ruins them. Its only decision is *when*.
///
/// Serializable because a committee whose members all live in one process is not a committee.
/// `confide-committee` writes one of these per agent and runs each as its own process, so the refusal
/// in [`ReleaseAgent::publish`] is a separate party's refusal rather than a branch in the holder's
/// own program.
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct ReleaseAgent {
    pub index: u8,
    share: Vec<u8>,
}

/// Refusal to publish a share before the obligation is due.
#[derive(Debug, PartialEq, Eq)]
pub struct Embargoed {
    pub now: UnixTime,
    pub opens_at: UnixTime,
}

impl std::fmt::Display for Embargoed {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let left = self.opens_at - self.now;
        let (d, h, m) = (left / 86_400, (left % 86_400) / 3_600, (left % 3_600) / 60);
        if d > 0 {
            write!(f, "embargoed — {d}d {h}h still to run")
        } else if h > 0 {
            write!(f, "embargoed — {h}h {m}m still to run")
        } else {
            write!(f, "embargoed — {m}m still to run")
        }
    }
}

impl ReleaseAgent {
    /// Publish this agent's share — **only once the obligation is due**.
    ///
    /// The holder is not a parameter. An agent does not ask them, and cannot be overridden by
    /// them. That is I2.
    pub fn publish(&self, sealed: &SealedDisclosure, now: UnixTime) -> Result<ReleaseShare, Embargoed> {
        if now < sealed.open_at {
            return Err(Embargoed { now, opens_at: sealed.open_at });
        }
        Ok(ReleaseShare { agent_index: self.index, bytes: self.share.clone() })
    }
}

#[derive(Debug, PartialEq, Eq)]
pub enum OpenError {
    /// Fewer than `k` shares were supplied, or the supplied shares do not agree.
    CannotReconstruct,
    /// Reconstructed a key, but it does not open this ciphertext.
    WrongKey,
    /// The package inside is not the one committed to at `anchored_slot`. **I3 caught a swap.**
    CommitmentMismatch { anchored: [u8; 32], found: [u8; 32] },
    /// The decrypted bytes are not a disclosure package.
    Malformed(String),
}

impl std::fmt::Display for OpenError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            OpenError::CannotReconstruct => write!(f, "not enough agreeing shares to reconstruct the seal key"),
            OpenError::WrongKey => write!(f, "reconstructed key does not open this seal"),
            OpenError::CommitmentMismatch { .. } => write!(
                f,
                "the package inside is not the one committed to when the position was built"
            ),
            OpenError::Malformed(m) => write!(f, "sealed bytes are not a disclosure package: {m}"),
        }
    }
}

/// Seal a disclosure package under a `k`-of-`n` release committee, due at `open_at`.
///
/// Returns the artifact to publish at `t0` and the shares to hand to the agents. The caller keeps
/// neither the key nor a copy of any share — that is the point.
pub fn seal(
    obligation: &Obligation,
    open_at: UnixTime,
    anchored_slot: u64,
    k: u8,
    n: u8,
) -> (SealedDisclosure, Vec<ReleaseAgent>) {
    let plaintext = serde_json::to_vec(obligation).expect("obligation is serializable");

    let key = XChaCha20Poly1305::generate_key(&mut OsRng);
    let nonce = XChaCha20Poly1305::generate_nonce(&mut OsRng);
    let ciphertext = XChaCha20Poly1305::new(&key)
        .encrypt(&nonce, plaintext.as_ref())
        .expect("sealing a package of known size cannot fail");

    let mut rng = || {
        use rand::RngCore;
        let mut b = [0u8; 1];
        rand::rngs::OsRng.fill_bytes(&mut b);
        b[0]
    };
    let agents = shamir::split(key.as_slice(), k, n, &mut rng)
        .into_iter()
        .map(|(index, share)| ReleaseAgent { index, share })
        .collect();

    let sealed = SealedDisclosure {
        commitment: obligation.commitment(),
        anchored_slot,
        open_at,
        trust: ReleaseTrustModel::ThresholdCommittee { k, n },
        ciphertext,
        nonce: nonce.into(),
    };
    (sealed, agents)
}

/// Open a sealed disclosure from published shares.
///
/// **There is deliberately no `now` parameter.** Once `k` shares are public the embargo is over as
/// a matter of fact, and a clock check here would claim a guarantee that cryptography is not
/// providing. The clock is [`ReleaseAgent::publish`]'s job, and the assumption that agents honour
/// it is named in [`ReleaseTrustModel`].
///
/// There is also no holder parameter, at any point on this path. That is I2.
pub fn open(sealed: &SealedDisclosure, shares: &[ReleaseShare]) -> Result<Obligation, OpenError> {
    if shares.is_empty() {
        return Err(OpenError::CannotReconstruct);
    }
    let pairs: Vec<(u8, Vec<u8>)> = shares.iter().map(|s| (s.agent_index, s.bytes.clone())).collect();
    let key_bytes = shamir::combine(&pairs);
    if key_bytes.len() != 32 {
        return Err(OpenError::CannotReconstruct);
    }

    let cipher = XChaCha20Poly1305::new(key_bytes.as_slice().into());
    let plaintext = cipher
        .decrypt(XNonce::from_slice(&sealed.nonce), sealed.ciphertext.as_ref())
        .map_err(|_| OpenError::WrongKey)?;

    let obligation: Obligation =
        serde_json::from_slice(&plaintext).map_err(|e| OpenError::Malformed(e.to_string()))?;

    // I3 — what opened must be what was committed to at `anchored_slot`, before the position was
    // complete. Without this check the holder could seal a flattering position after the fact.
    let found = obligation.commitment();
    if found != sealed.commitment {
        return Err(OpenError::CommitmentMismatch { anchored: sealed.commitment, found });
    }
    Ok(obligation)
}
