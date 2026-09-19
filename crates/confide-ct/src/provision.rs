//! `provision <step> <keypair.json> <mint> <account> <amount> <blockhash> <keys.json>`
//!
//! Stands up a Token-2022 confidential account **whose ElGamal key we generate and keep**.
//!
//! `spl-token` derives that key from a wallet signature with a KDF this SDK version does not
//! reproduce, so an account the CLI configures is one we can read on the chain and cannot prove
//! anything about. Generating the key here is what lets the range proof be over the account's own
//! `availableBalance` instead of over a ciphertext invented for the occasion.
//!
//! Steps, each one transaction: `configure` (writes the keys file), `approve`, `deposit`, `apply`.
//!
//! `approve` exists because the mirror is configured the way the real mints are. Backed and
//! Backpack both set `autoApproveNewAccounts: false`, so a holder cannot open a confidential
//! account without the issuer signing for it. Mirroring that with `auto` would have made the demo
//! easier and the claim false — the mirror would have differed from NVDAx in two fields, not one.
//! Here the mint authority is us, so the approval is a transaction we send; for a real holder it is
//! a conversation with the issuer. That gap is the point, and it is better shown than described.

use base64::Engine;
use solana_address::Address;
use solana_instruction::Instruction;
use solana_zk_elgamal_proof_interface::proof_data::pubkey_validity::PubkeyValidityProofData;
use solana_hash::Hash;
use solana_keypair::Keypair;
use solana_message::Message;
use solana_signer::Signer;
use solana_transaction::Transaction;
use solana_zk_sdk::encryption::auth_encryption::AeKey;
use solana_zk_sdk::encryption::elgamal::ElGamalKeypair;
use solana_zk_sdk::zk_elgamal_proof_program::pubkey_validity::build_pubkey_validity_proof_data;
use solana_zk_sdk_pod::encryption::auth_encryption::PodAeCiphertext;
use spl_token_2022_interface::extension::confidential_transfer::instruction::{
    apply_pending_balance, approve_account, configure_account, deposit,
};
use spl_token_2022_interface::extension::ExtensionType;
use spl_token_2022_interface::instruction::reallocate;
use spl_token_confidential_transfer_proof_extraction::instruction::ProofLocation;
use std::num::NonZeroI8;
use std::str::FromStr;

const TOKEN_2022: &str = "TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb";
const DECIMALS: u8 = 8;

/// Grow the account, then configure it — in that order, and with the proof where the instruction
/// says it is.
///
/// A token account from `create-account` has no room for the confidential extension, and
/// `ConfigureAccount` fails with `InvalidAccountData` rather than growing it for you. The proof is
/// cited as `InstructionOffset(1)`, meaning *the next instruction*; reordering these silently
/// points that offset at the wrong one, which the runtime reports as a bad proof rather than as a
/// bad order.
///
/// `charges_fee` is not a PreStocks special case. `TransferFeeConfig` is a standard Token-2022
/// extension and a mint that carries one requires `ConfidentialTransferFeeAmount` on every account
/// that holds it confidentially. Without that room `ConfigureAccount` fails the same way it fails
/// without room for the confidential extension itself — `InvalidAccountData`, three instructions
/// away from anything that mentions fees.
///
/// One issuer already switched a fee on mid-flight: PreStocks' older config was 0 bps at epoch 848
/// and its newer one is 50 bps from epoch 1032. **Any issuer can do that to any mint at any time**,
/// so this is not support for one token — it is the difference between working and silently not.
pub fn configure_instructions(
    program: &Address,
    account: &Address,
    mint: &Address,
    owner: &Address,
    zero: &PodAeCiphertext,
    proof: &PubkeyValidityProofData,
    charges_fee: bool,
) -> Vec<Instruction> {
    let mut extensions = vec![ExtensionType::ConfidentialTransferAccount];
    if charges_fee {
        extensions.push(ExtensionType::ConfidentialTransferFeeAmount);
    }
    let mut ixs = vec![reallocate(
        program,
        account,
        owner,
        owner,
        &[],
        &extensions,
    )
    .expect("reallocate")];
    ixs.extend(
        configure_account(
            program,
            account,
            mint,
            zero,
            MAX_PENDING_BALANCE_CREDITS,
            owner,
            &[],
            ProofLocation::InstructionOffset(NonZeroI8::new(1).unwrap(), proof),
        )
        .expect("configure_account"),
    );
    ixs
}

/// How many confidential credits may pile up before the holder must apply them.
pub const MAX_PENDING_BALANCE_CREDITS: u64 = 65_536;

fn main() {
    let mut a = std::env::args().skip(1);
    let step = a.next().expect("step: configure | approve | deposit | apply");
    let owner = read_keypair(&a.next().expect("keypair"));
    let mint = Address::from_str(&a.next().expect("mint")).unwrap();
    let account = Address::from_str(&a.next().expect("account")).unwrap();
    let amount: u64 = a.next().expect("amount").parse().unwrap();
    let blockhash = Hash::from_str(&a.next().expect("blockhash")).unwrap();
    let keys_path = a.next().expect("keys.json");
    // Required rather than defaulted. A default of "no fee" would be wrong exactly on the mints
    // where being wrong costs the most, and it would be wrong silently — the failure surfaces as
    // InvalidAccountData on a later instruction. The caller has the mint in front of it; let it say.
    let charges_fee = match a.next().as_deref() {
        Some("fee") => true,
        Some("nofee") => false,
        other => panic!("last argument must be `fee` or `nofee`, got {other:?} — read the mint's \
                         transferFeeConfig and say which"),
    };

    let program = Address::from_str(TOKEN_2022).unwrap();
    let base = amount * 10u64.pow(DECIMALS as u32);

    let ixs = match step.as_str() {
        "configure" => {
            // The key this whole step exists for.
            let elgamal = ElGamalKeypair::new_rand();
            let ae = AeKey::new_rand();
            std::fs::write(
                &keys_path,
                serde_json::to_vec_pretty(&serde_json::json!({
                    "account": account.to_string(),
                    "mint": mint.to_string(),
                    "elgamal_pubkey_b64": b64(&elgamal.pubkey().to_bytes()),
                    "elgamal_secret_b64": b64(elgamal.secret().as_bytes()),
                    "ae_key_b64": b64(&<[u8; 16]>::from(&ae)[..]),
                }))
                .unwrap(),
            )
            .unwrap();
            eprintln!("  keys written    {keys_path}");
            eprintln!("  elgamal pubkey  {}", b64(&elgamal.pubkey().to_bytes()));

            let proof = build_pubkey_validity_proof_data(&elgamal).expect("pubkey validity proof");
            let zero: PodAeCiphertext = ae.encrypt(0).into();

            configure_instructions(&program, &account, &mint, &owner.pubkey(), &zero, &proof,
                                   charges_fee)
        }
        // The issuer's signature on this account. On a mint with autoApproveNewAccounts false, the
        // confidential extension stays unapproved and every later instruction fails without it.
        "approve" => vec![approve_account(&program, &account, &mint, &owner.pubkey(), &[])
            .expect("approve_account")],
        "deposit" => vec![deposit(&program, &account, &mint, base, DECIMALS, &owner.pubkey(), &[])
            .expect("deposit")],
        "apply" => {
            let keys: serde_json::Value =
                serde_json::from_slice(&std::fs::read(&keys_path).unwrap()).unwrap();
            let ae = AeKey::try_from(
                &d64(keys["ae_key_b64"].as_str().unwrap())[..],
            )
            .expect("ae key");
            // Everything deposited lands in available once applied.
            let new_available: PodAeCiphertext = ae.encrypt(base).into();
            vec![apply_pending_balance(&program, &account, 1, &new_available, &owner.pubkey(), &[])
                .expect("apply_pending_balance")]
        }
        other => panic!("unknown step {other}"),
    };

    let tx = Transaction::new(&[&owner], Message::new(&ixs, Some(&owner.pubkey())), blockhash);
    println!("{}", base64::engine::general_purpose::STANDARD.encode(bincode::serialize(&tx).unwrap()));
}

fn b64(b: &[u8]) -> String {
    base64::engine::general_purpose::STANDARD.encode(b)
}
fn d64(s: &str) -> Vec<u8> {
    base64::engine::general_purpose::STANDARD.decode(s).unwrap()
}
fn read_keypair(path: &str) -> Keypair {
    let bytes: Vec<u8> = serde_json::from_str(&std::fs::read_to_string(path).unwrap()).unwrap();
    Keypair::try_from(&bytes[..]).unwrap()
}

#[cfg(test)]
mod configuring {
    use super::*;
    use solana_zk_sdk::encryption::auth_encryption::AeKey;

    fn parts() -> (Address, Address, Address, Address, PodAeCiphertext, PubkeyValidityProofData) {
        let a = || Address::from(Keypair::new().pubkey().to_bytes());
        let elgamal = ElGamalKeypair::new_rand();
        (
            Address::from_str(TOKEN_2022).unwrap(), a(), a(), a(),
            AeKey::new_rand().encrypt(0).into(),
            build_pubkey_validity_proof_data(&elgamal).expect("pubkey validity proof"),
        )
    }

    /// **G1 — room before configuration, in that order.** `ConfigureAccount` does not grow the
    /// account; it fails with `InvalidAccountData` on one that has no space for the extension.
    /// Reversing these two is a failure the runtime reports as bad account data, which reads like
    /// a broken account rather than a broken order.
    #[test]
    fn the_account_is_grown_before_it_is_configured() {
        let (program, account, mint, owner, zero, proof) = parts();
        let ixs = configure_instructions(&program, &account, &mint, &owner, &zero, &proof, false);
        assert!(ixs.len() >= 2, "configure produced {} instruction(s)", ixs.len());

        // Compare against the reallocate this should be, not against "addressed to the token
        // program and touching the account" — ConfigureAccount is both of those too, so a weaker
        // assertion passes with the two in either order. It did, until a mutation said so.
        let grow = reallocate(
            &program, &account, &owner, &owner, &[],
            &[ExtensionType::ConfidentialTransferAccount],
        )
        .expect("reallocate");
        assert_eq!(ixs[0].data, grow.data, "the first instruction is not the one that grows the account");
    }

    /// **G2 — the proof is where the offset says it is.** `ConfigureAccount` cites its proof as
    /// `InstructionOffset(1)`: the very next instruction. If the builder ever stopped appending it
    /// there, the runtime would read some other instruction as the proof and report a bad proof —
    /// pointing the reader at the cryptography instead of at the ordering.
    #[test]
    fn the_proof_sits_immediately_after_the_instruction_that_cites_it() {
        let (program, account, mint, owner, zero, proof) = parts();
        let ixs = configure_instructions(&program, &account, &mint, &owner, &zero, &proof, false);
        let configure = ixs.len() - 2;
        assert_eq!(
            ixs[configure + 1].program_id,
            solana_zk_elgamal_proof_interface::id(),
            "the instruction after ConfigureAccount is not the proof it cites at offset 1",
        );
    }

    /// **G3 — the pending-credit ceiling is carried, not defaulted.** It bounds how many
    /// confidential credits may arrive before the holder must apply them; a zero here would make
    /// the account reject the first transfer into it.
    #[test]
    fn the_pending_balance_ceiling_is_not_zero() {
        assert_eq!(MAX_PENDING_BALANCE_CREDITS, 65_536);
        assert!(MAX_PENDING_BALANCE_CREDITS > 0, "the account would refuse its first credit");
    }

    /// **G4 — every instruction is addressed to a program that exists in the flow.** A stray
    /// program id would fail at submission with nothing to say about which builder produced it.
    #[test]
    fn nothing_is_addressed_anywhere_unexpected() {
        let (program, account, mint, owner, zero, proof) = parts();
        let zk = solana_zk_elgamal_proof_interface::id();
        for ix in configure_instructions(&program, &account, &mint, &owner, &zero, &proof, false) {
            assert!(ix.program_id == program || ix.program_id == zk, "unexpected program {}", ix.program_id);
        }
    }
}
