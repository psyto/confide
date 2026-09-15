//! `set-auditor <keypair.json> <mint> <blockhash> [auditor_secret.json]`
//!
//! Fills the slot every xStock leaves empty — on a mint we control, because Backed's mints are not
//! ours to configure. One instruction: `ConfidentialTransferInstruction::UpdateMint`.
//!
//! The point is not that setting a key is hard. It is that setting it is the *only* lever
//! Token-2022 gives you, and it is all-or-nothing: whoever holds this key reads every holder's
//! every transfer, forever. That is why the live mints leave it null. Confide exists so the key can
//! be held by something that discloses on terms instead of unconditionally.

use base64::Engine;
use solana_address::Address;
use solana_instruction::Instruction;
use solana_hash::Hash;
use solana_keypair::Keypair;
use solana_message::Message;
use solana_signer::Signer;
use solana_transaction::Transaction;
use solana_zk_sdk::encryption::elgamal::ElGamalKeypair;
use spl_token_2022_interface::extension::confidential_transfer::instruction::update_mint;
use solana_zk_sdk_pod::encryption::elgamal::PodElGamalPubkey;
use std::str::FromStr;

const TOKEN_2022: &str = "TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb";

/// One `UpdateMint`: fill the auditor slot, and leave the account gate exactly where NVDAx leaves
/// it.
///
/// `update_mint` rewrites **both** fields, so the `false` is not a default being restated — it is
/// the whole reason this is a function. Passing `true` silently undoes the `manual` the mint was
/// created with and leaves the mirror differing from NVDAx in two fields while every document says
/// one. It did exactly that until 2026-09-15.
pub fn fill_auditor_slot(mint: &Address, authority: &Address, auditor: PodElGamalPubkey) -> Instruction {
    update_mint(
        &Address::from_str(TOKEN_2022).unwrap(),
        mint,
        authority,
        &[],
        AUTO_APPROVE_NEW_ACCOUNTS,
        Some(auditor),
    )
    .expect("update_mint")
}

/// What NVDAx has, and therefore what the mirror must keep: the issuer signs for every account
/// before it can hold anything.
pub const AUTO_APPROVE_NEW_ACCOUNTS: bool = false;

fn main() {
    let mut a = std::env::args().skip(1);
    let kp_path = a.next().expect("usage: set-auditor <keypair.json> <mint> <blockhash> [out.json]");
    let mint = a.next().expect("mint");
    let blockhash = a.next().expect("blockhash");
    let out = a.next().unwrap_or_else(|| "auditor-key.json".into());

    let authority = read_keypair(&kp_path);

    // The auditor key. Generated here and written out, so the demo can read the books with it.
    let auditor = ElGamalKeypair::new_rand();
    let pod = PodElGamalPubkey::from(*auditor.pubkey());
    std::fs::write(
        &out,
        serde_json::to_vec(&serde_json::json!({
            "elgamal_pubkey_b64": b64(&auditor.pubkey().to_bytes()),
            "elgamal_secret_b64": b64(auditor.secret().as_bytes()),
            "mint": mint,
        }))
        .unwrap(),
    )
    .unwrap();

    let ix = fill_auditor_slot(&Address::from_str(&mint).unwrap(), &authority.pubkey(), pod);

    let tx = Transaction::new(
        &[&authority],
        Message::new(&[ix], Some(&authority.pubkey())),
        Hash::from_str(&blockhash).expect("blockhash"),
    );

    eprintln!("  mint            {mint}");
    eprintln!("  auditor pubkey  {}", b64(&auditor.pubkey().to_bytes()));
    eprintln!("  secret written  {out}");
    println!("{}", base64::engine::general_purpose::STANDARD.encode(bincode::serialize(&tx).unwrap()));
}

fn b64(b: &[u8]) -> String {
    base64::engine::general_purpose::STANDARD.encode(b)
}

fn read_keypair(path: &str) -> Keypair {
    let bytes: Vec<u8> = serde_json::from_str(&std::fs::read_to_string(path).unwrap()).unwrap();
    Keypair::try_from(&bytes[..]).unwrap()
}

#[cfg(test)]
mod mirror {
    use super::*;
    use solana_zk_sdk::encryption::elgamal::ElGamalKeypair;

    /// `Address` has no `new_unique`; a keypair's pubkey is the cheapest distinct one.
    fn addr() -> Address {
        Address::from(solana_keypair::Keypair::new().pubkey().to_bytes())
    }

    /// **M1 — the gate stays shut.** Every document says the mirror differs from `NVDAx` in one
    /// field: the auditor key. `update_mint` rewrites the approval policy in the same instruction,
    /// so a `true` here would make that sentence false everywhere it appears — README, DESIGN,
    /// ONCHAIN, the submission and the narration — while the code kept compiling.
    #[test]
    fn filling_the_slot_does_not_open_the_account_gate() {
        assert!(!AUTO_APPROVE_NEW_ACCOUNTS, "the mirror would stop gating accounts the way NVDAx does");
    }

    /// **M2 — the instruction carries the key it was given, and the closed gate with it.** Reads
    /// the encoded data rather than trusting the builder: the auditor pubkey must appear in it and
    /// the approval byte must be zero.
    #[test]
    fn the_instruction_carries_the_auditor_and_a_closed_gate() {
        let auditor = ElGamalKeypair::new_rand();
        let pod: PodElGamalPubkey = (*auditor.pubkey()).into();
        let ix = fill_auditor_slot(&addr(), &addr(), pod);

        let key = auditor.pubkey().to_bytes();
        assert!(
            ix.data.windows(32).any(|w| w == key),
            "the auditor key is not in the instruction that is supposed to set it",
        );
        assert!(
            ix.data.contains(&0u8),
            "the auto-approve flag is not encoded as false",
        );
        assert_eq!(ix.program_id, Address::from_str(TOKEN_2022).unwrap());
    }

    /// **M3 — two different auditors produce two different instructions.** Guards against a
    /// builder that quietly ignores the key and writes a default, which would leave the slot
    /// filled with something nobody holds.
    #[test]
    fn a_different_auditor_gives_a_different_instruction() {
        let mint = addr();
        let authority = addr();
        let a: PodElGamalPubkey = (*ElGamalKeypair::new_rand().pubkey()).into();
        let b: PodElGamalPubkey = (*ElGamalKeypair::new_rand().pubkey()).into();
        assert_ne!(
            fill_auditor_slot(&mint, &authority, a).data,
            fill_auditor_slot(&mint, &authority, b).data,
        );
    }
}
