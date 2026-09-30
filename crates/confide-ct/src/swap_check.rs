//! What the receiving side of a swap checks BEFORE it signs.
//!
//!   swap-check <my-keys.json> <validity-context-account-base64> [agreed-base-units]
//!
//! **Pass the agreed amount.** Without it this only DISPLAYS the decrypted figure and tells you to
//! compare it yourself, which is not a check -- it is a number on a screen next to a sentence, and
//! a wrong amount exited ZERO, so every caller went on to sign. They honoured a failure; there was
//! no failure to honour. With the agreed amount the comparison IS the exit code, and a leg that
//! moves anything else fails here, before a signature exists. Added 2026-09-30.
//!
//! An atomic swap of two confidential positions has one danger, and it is not the atomicity:
//! **the amounts are encrypted, so a party could sign a transaction whose other leg sends far less
//! than was agreed.** Both legs settle, and the loss is discovered afterwards by decrypting a
//! balance.
//!
//! It is answerable without trusting anyone, because of how a confidential transfer is built. The
//! amount is encrypted once under three keys at once — the sender's, the RECEIVER's, and the
//! auditor's — and that grouped ciphertext is what the validity proof is verified over and what
//! sits in the context state account. So the receiver can decrypt, from the pre-verified context,
//! the exact amount the transfer will move to them. No proof of a floor and no third party.
//!
//! This reads that context and reports three things: whether the transfer is addressed to this
//! key at all, how much it moves, and who sent it. Anything else in the transaction is visible in
//! the transaction itself.
//!
//! The context is already VERIFIED when this runs — the ZK ElGamal Proof Program checked it, and
//! the account is immutable afterwards. So the amount read here is the amount the transfer will
//! carry: Token-2022 will cite this same account by address and re-check it against the transfer's
//! source and destination.

use base64::Engine;
use solana_zk_sdk::encryption::elgamal::{ElGamalCiphertext, ElGamalSecretKey};
use solana_zk_sdk_pod::encryption::elgamal::{PodElGamalCiphertext, PodElGamalPubkey};

/// `ProofContextState`: authority(32) | proof_type(1) | context
const CONTEXT: usize = 33;
/// `BatchedGroupedCiphertext3HandlesValidityProofContext`: three keys, then two grouped ciphertexts
const KEYS: usize = 32 * 3;
const GROUPED: usize = 32 * 4; // commitment, then one decryption handle per key
/// The keyset order is fixed at construction: source, recipient, auditor.
const HANDLE_RECIPIENT: usize = 2; // commitment(0), source handle(1), recipient handle(2)
const AMOUNT_LO_BITS: u32 = 16;
const PROOF_TYPE_BATCHED_VALIDITY_3: u8 = 12;

/// The three keys named by the context, and what the leg moves to the recipient.
#[cfg_attr(test, derive(Debug))]
struct Leg {
    from: String,
    to: String,
    auditor: String,
    amount: u64,
}

/// Decode the context and decrypt the recipient's half. Every failure is a refusal to sign, so
/// each one comes back as a message rather than a default.
fn read_leg(secret: &ElGamalSecretKey, my_pubkey: &[u8], d: &[u8]) -> Result<Leg, String> {
    if d.len() < CONTEXT + KEYS + GROUPED * 2 {
        return Err("that account is too small to be a 3-handle validity context".into());
    }
    if d[32] != PROOF_TYPE_BATCHED_VALIDITY_3 {
        return Err(format!(
            "that context holds proof type {}, not the ciphertext validity proof a transfer's amount lives in",
            d[32]
        ));
    }
    let key = |n: usize| -> String {
        let mut k = [0u8; 32];
        k.copy_from_slice(&d[CONTEXT + 32 * n..CONTEXT + 32 * (n + 1)]);
        PodElGamalPubkey(k).to_string()
    };
    // Compare the raw bytes rather than two spellings of them: the context holds 32 bytes and the
    // keys file holds the same 32 in base64.
    if d[CONTEXT + 32..CONTEXT + 64] != *my_pubkey {
        return Err("this transfer is NOT addressed to you".into());
    }
    let base = CONTEXT + KEYS;
    // Same opening, so both halves share a commitment layout; the recipient's half of each is a
    // plain ElGamal ciphertext once the right handle is picked out.
    let half = |off: usize| -> Result<ElGamalCiphertext, String> {
        let mut ct = [0u8; 64];
        ct[..32].copy_from_slice(&d[off..off + 32]); // the commitment
        ct[32..].copy_from_slice(&d[off + 32 * HANDLE_RECIPIENT..off + 32 * (HANDLE_RECIPIENT + 1)]);
        ElGamalCiphertext::try_from(PodElGamalCiphertext(ct))
            .map_err(|_| "the recipient's ciphertext does not decode".to_string())
    };
    let (lo, hi) = (
        secret.decrypt_u32(&half(base)?),
        secret.decrypt_u32(&half(base + GROUPED)?),
    );
    match (lo, hi) {
        (Some(lo), Some(hi)) => Ok(Leg {
            from: key(0),
            to: key(1),
            auditor: key(2),
            amount: lo as u64 + ((hi as u64) << AMOUNT_LO_BITS),
        }),
        _ => Err("the amount did not decrypt — this context was not built for your key".into()),
    }
}

/// The comparison, and it is the whole point of the third argument. `None` is the old behaviour and
/// is reported as such, because "nothing was compared" is a different result from "it matched".
fn compare(amount: u64, agreed: Option<u64>) -> Result<Option<u64>, String> {
    match agreed {
        None => Ok(None),
        Some(want) if want == amount => Ok(Some(want)),
        // Printed with the difference because "3500000 is not 3499999" is read wrong at a glance,
        // and the size of the shortfall is what says whether it was a typo or a theft.
        Some(want) => Err(format!(
            "you agreed \x1b[1m{want}\x1b[0m and this leg moves \x1b[1m{amount}\x1b[0m — \
             short by {short}.\n      \x1b[2mDO NOT SIGN. Nothing has happened yet: no signature \
             of yours exists and the swap cannot settle without it.\x1b[0m",
            short = want as i128 - amount as i128
        )),
    }
}

fn main() {
    let mut a = std::env::args().skip(1);
    let keys_path = a.next().expect("my-keys.json");
    let data_b64 = a.next().expect("the validity context account's data, base64");
    // Parsed before anything is read from the chain: an unparseable agreed amount must not be
    // silently treated as "no amount given", because that downgrades a check into a display.
    let agreed: Option<u64> = match a.next() {
        None => None,
        Some(s) => match s.trim().parse::<u64>() {
            Ok(n) => Some(n),
            Err(_) => die(&format!(
                "{s:?} is not a base-unit amount. Pass the agreed amount as an integer, or pass \
                 nothing at all -- but then nothing is compared and you are checking by eye"
            )),
        },
    };

    let keys: serde_json::Value =
        serde_json::from_slice(&std::fs::read(&keys_path).expect("keys.json")).unwrap();
    // The secret alone; the account's public key is recorded beside it and is what the context
    // names as the recipient.
    let secret = ElGamalSecretKey::try_from(
        &b64(keys["elgamal_secret_b64"].as_str().expect("elgamal_secret_b64"))[..],
    )
    .expect("my elgamal secret");
    let my_pubkey_b64 = keys["elgamal_pubkey_b64"]
        .as_str()
        .expect("elgamal_pubkey_b64")
        .to_string();

    let leg = match read_leg(&secret, &b64(&my_pubkey_b64), &b64(&data_b64)) {
        Ok(l) => l,
        Err(e) => {
            println!();
            println!("  \x1b[1mTHE LEG YOU ARE BEING ASKED TO SIGN\x1b[0m");
            die(&format!("{e}\n      \x1b[2myour key is {my_pubkey_b64}\x1b[0m"))
        }
    };

    println!();
    println!("  \x1b[1mTHE LEG YOU ARE BEING ASKED TO SIGN\x1b[0m");
    println!("      from ElGamal key   {}", leg.from);
    println!("      to   ElGamal key   {}", leg.to);
    println!("      auditor            {}", leg.auditor);
    println!("  \x1b[32m✓\x1b[0m it is addressed to your key");
    println!(
        "  \x1b[32m✓\x1b[0m it will move \x1b[1m{}\x1b[0m base units to you\n      \x1b[2mdecrypted from the verified context, by you, without anyone's cooperation\x1b[0m",
        leg.amount
    );
    match compare(leg.amount, agreed) {
        Ok(Some(want)) => println!(
            "  \x1b[32m✓\x1b[0m and {want} is what you agreed\n      \x1b[2mcompared here, not left to your eye\x1b[0m\n"
        ),
        Ok(None) => println!(
            "\n  \x1b[2mNo agreed amount was passed, so nothing was compared. If that is not the \
             amount you agreed, do not sign.\x1b[0m\n"
        ),
        // EXIT 3, AND ONLY HERE. "The amount is not what you agreed" is a verified result; every other
        // failure (a context that is not ours, an unreadable key, a bad argument) is "nothing was
        // established" and exits 1. The SHORT control reports a refusal only on 3 -- before
        // 2026-09-30 it reported one on any non-zero, including a missing proof context (Codex).
        Err(e) => {
            println!();
            eprintln!("  \x1b[31m✗\x1b[0m {e}");
            std::process::exit(MISMATCH)
        }
    }
}

/// The exit status for a verified amount mismatch. Distinct from 1, which means the check could not
/// be completed.
const MISMATCH: i32 = 3;

fn b64(s: &str) -> Vec<u8> {
    base64::engine::general_purpose::STANDARD
        .decode(s)
        .expect("base64")
}

fn die(m: &str) -> ! {
    eprintln!("  \x1b[31m✗\x1b[0m {m}");
    std::process::exit(1)
}

#[cfg(test)]
mod tests {
    use super::*;
    use solana_zk_sdk::encryption::elgamal::ElGamalKeypair;

    /// A context blob shaped like the real one, with `amount` encrypted to `to`.
    ///
    /// This does NOT re-derive Token-2022's layout from the SDK -- it writes the same offsets this
    /// file reads, so it tests the decode and the comparison rather than the byte layout. The
    /// layout itself is established by the devnet runs recorded in docs/cwf-2026/THE-SWAP.md; what
    /// was untested until 2026-09-30, and what these cover, is whether a leg that moves the wrong
    /// amount is REFUSED. It was not: nothing compared anything.
    fn context(from: &ElGamalKeypair, to: &ElGamalKeypair, aud: &[u8; 32], amount: u64) -> Vec<u8> {
        let mut d = vec![0u8; CONTEXT + KEYS + GROUPED * 2];
        d[32] = PROOF_TYPE_BATCHED_VALIDITY_3;
        let pk = |kp: &ElGamalKeypair| -> [u8; 32] {
            let mut b = [0u8; 32];
            b.copy_from_slice(&PodElGamalPubkey::from(*kp.pubkey()).0);
            b
        };
        d[CONTEXT..CONTEXT + 32].copy_from_slice(&pk(from));
        d[CONTEXT + 32..CONTEXT + 64].copy_from_slice(&pk(to));
        d[CONTEXT + 64..CONTEXT + 96].copy_from_slice(aud);
        // lo is the bottom 16 bits and hi the rest, which is how the reader recombines them.
        let lo = (amount & 0xFFFF) as u32;
        let hi = (amount >> AMOUNT_LO_BITS) as u32;
        for (n, part) in [lo, hi].into_iter().enumerate() {
            let ct = PodElGamalCiphertext::from(to.pubkey().encrypt(part as u64)).0;
            let off = CONTEXT + KEYS + GROUPED * n;
            d[off..off + 32].copy_from_slice(&ct[..32]); // commitment
            // the source handle is not read by the recipient; the recipient's is slot 2
            let r = off + 32 * HANDLE_RECIPIENT;
            d[r..r + 32].copy_from_slice(&ct[32..]);
        }
        d
    }

    fn pk_bytes(kp: &ElGamalKeypair) -> Vec<u8> {
        PodElGamalPubkey::from(*kp.pubkey()).0.to_vec()
    }

    #[test]
    fn reads_the_amount_addressed_to_it() {
        let (from, to) = (ElGamalKeypair::new_rand(), ElGamalKeypair::new_rand());
        let d = context(&from, &to, &[7u8; 32], 20_000);
        let leg = read_leg(to.secret(), &pk_bytes(&to), &d).expect("addressed to me");
        assert_eq!(leg.amount, 20_000);
    }

    #[test]
    fn reads_an_amount_that_needs_both_halves() {
        // 3,500,000 base units -- $3.50m at six decimals, the DvP cash leg. hi is 53, so a reader
        // that dropped the high half would report 27,552 and call it agreed.
        let (from, to) = (ElGamalKeypair::new_rand(), ElGamalKeypair::new_rand());
        let d = context(&from, &to, &[0u8; 32], 3_500_000);
        let leg = read_leg(to.secret(), &pk_bytes(&to), &d).expect("addressed to me");
        assert_eq!(leg.amount, 3_500_000);
    }

    #[test]
    fn refuses_a_leg_addressed_to_somebody_else() {
        let (from, to, me) = (
            ElGamalKeypair::new_rand(),
            ElGamalKeypair::new_rand(),
            ElGamalKeypair::new_rand(),
        );
        let d = context(&from, &to, &[0u8; 32], 20_000);
        let e = read_leg(me.secret(), &pk_bytes(&me), &d).expect_err("not mine");
        assert!(e.contains("NOT addressed to you"), "{e}");
    }

    #[test]
    fn refuses_a_context_of_the_wrong_proof_type() {
        let (from, to) = (ElGamalKeypair::new_rand(), ElGamalKeypair::new_rand());
        let mut d = context(&from, &to, &[0u8; 32], 20_000);
        d[32] = PROOF_TYPE_BATCHED_VALIDITY_3 + 1;
        let e = read_leg(to.secret(), &pk_bytes(&to), &d).expect_err("wrong type");
        assert!(e.contains("proof type"), "{e}");
    }

    #[test]
    fn refuses_a_truncated_context() {
        let (from, to) = (ElGamalKeypair::new_rand(), ElGamalKeypair::new_rand());
        let mut d = context(&from, &to, &[0u8; 32], 20_000);
        d.truncate(CONTEXT + KEYS);
        let e = read_leg(to.secret(), &pk_bytes(&to), &d).expect_err("truncated");
        assert!(e.contains("too small"), "{e}");
    }

    // --- the comparison, which is what did not exist ---

    #[test]
    fn matching_amount_passes() {
        assert_eq!(compare(20_000, Some(20_000)).unwrap(), Some(20_000));
    }

    #[test]
    fn a_short_leg_is_refused() {
        let e = compare(2_000, Some(20_000)).expect_err("short by 18,000");
        assert!(e.contains("short by 18000"), "{e}");
        assert!(e.contains("DO NOT SIGN"), "{e}");
    }

    #[test]
    fn one_base_unit_short_is_refused() {
        // The interesting case is not the obvious theft, it is the one a human eye passes over.
        compare(3_499_999, Some(3_500_000)).expect_err("one unit short");
    }

    #[test]
    fn an_overpayment_is_refused_too() {
        // Not "at least what was agreed". A leg moving more than agreed is also not the trade that
        // was agreed, and signing it can be the expensive direction on the other leg.
        let e = compare(21_000, Some(20_000)).expect_err("over");
        assert!(e.contains("short by -1000"), "{e}");
    }

    #[test]
    fn no_agreed_amount_compares_nothing_and_says_so() {
        assert_eq!(compare(20_000, None).unwrap(), None);
    }
}
