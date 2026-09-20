//! The five proofs a confidential transfer needs on a mint that charges a transfer fee, put on
//! chain and made citable by address.
//!
//!   swap-ctx-fee <payer.json> <keys.json> <dec_b64> <avail_b64> <recipient_pk_b64>
//!                <auditor_pk_b64|none> <withheld_pk_b64> <fee_bps> <max_fee> <amount_base>
//!                <blockhash> <out.json> <authority> <keys_dir> <alt|none> [skip]
//!
//! **The proofs are generated once and kept.** Fourteen transactions do not fit inside the life of
//! one blockhash — the thirteenth was rejected with `BlockhashNotFound` — so the caller has to come
//! back with a fresh one, and regenerating would produce different proofs in different context
//! accounts. So the proof set is written to `<keys_dir>` on the first run and reloaded after, and
//! `skip` says how many transactions have already landed.
//!
//! **Why this exists separately from `seizure-ctx`.** A fee-free confidential transfer takes three
//! proofs. A fee-bearing one takes five: the extra two are a percentage-with-cap sigma proof (the
//! fee really is `rate × amount`, capped) and a 2-handle validity proof over the fee ciphertext,
//! and the range proof widens from `U128` to `U256` because it now covers six commitments.
//!
//! **And why one of them cannot be submitted the ordinary way.** `crates/confide-ct/tests/
//! fee_tx_size.rs` measures it: the U256 range proof's verify transaction is 1,269 bytes at its
//! very best against a 1,232-byte limit, and there is nothing left to move into a lookup table —
//! the only remaining static keys are the fee payer and a program id, and a v0 message may not
//! source a program id from a table.
//!
//! So that one goes through the ZK program's **fourth** instruction layout, which reads the proof
//! from an account at a `u32` offset instead of from instruction data. The proof is written into
//! an `spl-record` account in chunks first. Four transactions to stage a proof, and then a verify
//! instruction of five bytes.
//!
//! Everything printed on stdout is a base64 transaction, in the order it must be sent.

use base64::Engine;
use confide_ct::staging::{
    b64tx, compute_unit_limit, create_account, load_or_create, read_keypair, record_initialize,
    record_write, rent_exempt, RECORD_WRITABLE_START, SPL_RECORD,
};
use solana_address::Address;
use solana_hash::Hash;
use solana_keypair::Keypair;
use solana_message::{v0, AddressLookupTableAccount, Message, VersionedMessage};
use solana_signer::Signer;
use solana_transaction::versioned::VersionedTransaction;
use solana_transaction::Transaction;
use solana_zk_elgamal_proof_interface::instruction::{ContextStateInfo, ProofInstruction};
use solana_zk_elgamal_proof_interface::proof_data::{
    batched_grouped_ciphertext_validity::{
        BatchedGroupedCiphertext2HandlesValidityProofContext,
        BatchedGroupedCiphertext2HandlesValidityProofData,
        BatchedGroupedCiphertext3HandlesValidityProofContext,
        BatchedGroupedCiphertext3HandlesValidityProofData,
    },
    batched_range_proof::{BatchedRangeProofContext, BatchedRangeProofU256Data},
    ciphertext_commitment_equality::{
        CiphertextCommitmentEqualityProofContext, CiphertextCommitmentEqualityProofData,
    },
    percentage_with_cap::{PercentageWithCapProofContext, PercentageWithCapProofData},
};
use solana_zk_elgamal_proof_interface::state::ProofContextState;
use solana_zk_sdk::encryption::auth_encryption::{AeCiphertext, AeKey};
use solana_zk_sdk::encryption::elgamal::{ElGamalKeypair, ElGamalPubkey, ElGamalSecretKey};
use solana_zk_sdk_pod::encryption::elgamal::PodElGamalCiphertext;
use spl_token_confidential_transfer_proof_generation::transfer_with_fee::transfer_with_fee_split_proof_data;
use std::str::FromStr;

/// How much of a record write fits in one transaction. The write instruction carries a one-byte
/// discriminant, an eight-byte offset and a four-byte length beside the payload, and the message
/// carries three accounts and a signature — 800 leaves room and keeps the arithmetic obvious.
const CHUNK: usize = 800;

fn main() {
    let a: Vec<String> = std::env::args().skip(1).collect();
    if a.len() < 15 {
        eprintln!("{}", &include_str!("swap_ctx_fee.rs")[..0]);
        eprintln!("swap-ctx-fee <payer.json> <keys.json> <dec_b64> <avail_b64> <recipient_pk_b64> \\");
        eprintln!("             <auditor_pk_b64|none> <withheld_pk_b64> <fee_bps> <max_fee> \\");
        eprintln!("             <amount_base> <blockhash> <out.json> <authority> <keys_dir> <alt|none>");
        std::process::exit(2);
    }
    let payer = read_keypair(&a[0]);
    let keys: serde_json::Value =
        serde_json::from_slice(&std::fs::read(&a[1]).expect("keys.json")).unwrap();
    let ae = AeKey::try_from(&d64(keys["ae_key_b64"].as_str().unwrap())[..]).expect("ae key");
    let source = ElGamalKeypair::new(
        ElGamalSecretKey::try_from(&d64(keys["elgamal_secret_b64"].as_str().unwrap())[..])
            .expect("elgamal secret"),
    );
    let current_dec = AeCiphertext::from_bytes(&d64(&a[2])).expect("decryptable balance");
    let balance = ae.decrypt(&current_dec).expect("our key opens our balance");
    let current_avail = solana_zk_sdk::encryption::elgamal::ElGamalCiphertext::from_bytes(&d64(&a[3]))
        .expect("available balance ciphertext");
    let recipient = pubkey(&a[4]);
    let auditor = (a[5] != "none").then(|| pubkey(&a[5]));
    let withheld = pubkey(&a[6]);
    let fee_bps: u16 = a[7].parse().expect("fee basis points");
    let max_fee: u64 = a[8].parse().expect("maximum fee");
    let amount: u64 = a[9].parse().expect("amount in base units");
    let blockhash = Hash::from_str(&a[10]).expect("blockhash");
    let out = &a[11];
    let authority = Address::from_str(&a[12]).expect("context state authority");
    let keys_dir = &a[13];
    let alt = &a[14];
    let skip: usize = a.get(15).map(|s| s.parse().expect("skip must be a number")).unwrap_or(0);

    // The whole of the cryptography, in one call. Hand-rolling a percentage-with-cap sigma proof
    // would be inventing something this crate already ships and gets audited for.
    //
    // Generated once and cached: see the note at the top. Every proof here is `Pod`, so the cache
    // is the bytes and nothing else — no format to drift.
    let cache = format!("{keys_dir}/fee-proofs.bin");
    let proofs: Proofs = match std::fs::read(&cache) {
        Ok(bytes) if bytes.len() == std::mem::size_of::<Proofs>() => {
            eprintln!("  proofs             reloaded from {cache}");
            *bytemuck::from_bytes(&bytes)
        }
        _ => {
            let d = transfer_with_fee_split_proof_data(
                &current_avail,
                &current_dec,
                amount,
                &source,
                &ae,
                &recipient,
                auditor.as_ref(),
                &withheld,
                fee_bps,
                max_fee,
            )
            .expect("with-fee proof set");
            let v = &d.transfer_amount_ciphertext_validity_proof_data_with_ciphertext;
            let p = Proofs {
                equality: d.equality_proof_data,
                validity3: v.proof_data,
                percentage: d.percentage_with_cap_proof_data,
                fee_validity: d.fee_ciphertext_validity_proof_data,
                range: d.range_proof_data,
                auditor_lo: PodElGamalCiphertext::from(v.ciphertext_lo),
                auditor_hi: PodElGamalCiphertext::from(v.ciphertext_hi),
            };
            std::fs::create_dir_all(keys_dir).unwrap();
            std::fs::write(&cache, bytemuck::bytes_of(&p)).unwrap();
            p
        }
    };
    let d = &proofs;

    let accounts = [
        load_or_create(keys_dir, "fee-ctx-equality.json"),
        load_or_create(keys_dir, "fee-ctx-validity.json"),
        load_or_create(keys_dir, "fee-ctx-percentage.json"),
        load_or_create(keys_dir, "fee-ctx-fee-validity.json"),
        load_or_create(keys_dir, "fee-ctx-range.json"),
    ];
    let sizes = [
        std::mem::size_of::<ProofContextState<CiphertextCommitmentEqualityProofContext>>(),
        std::mem::size_of::<ProofContextState<BatchedGroupedCiphertext3HandlesValidityProofContext>>(),
        std::mem::size_of::<ProofContextState<PercentageWithCapProofContext>>(),
        std::mem::size_of::<ProofContextState<BatchedGroupedCiphertext2HandlesValidityProofContext>>(),
        std::mem::size_of::<ProofContextState<BatchedRangeProofContext>>(),
    ];
    let zk = solana_zk_elgamal_proof_interface::id();
    // Held in their own array first. `ContextStateInfo` borrows its addresses, and pointing it at
    // a temporary produced by `accounts[n].pubkey()` is a dangling reference — this file had that,
    // behind an `unsafe`, for exactly as long as it took to read back.
    let ctx_keys: Vec<Address> = accounts.iter().map(|k| k.pubkey()).collect();
    let info = |n: usize| ContextStateInfo {
        context_state_account: &ctx_keys[n],
        context_state_authority: &authority,
    };

    let mut txs: Vec<(String, String, usize)> = Vec::new();
    let mut emit = |label: &str, bytes: Vec<u8>, how: &str| {
        let n = bytes.len();
        txs.push((b64tx(&bytes), format!("{label} ({how})"), n));
    };
    let legacy = |ix, signers: &[&Keypair]| {
        bincode::serialize(&Transaction::new(
            signers,
            Message::new(&[ix], Some(&payer.pubkey())),
            blockhash,
        ))
        .unwrap()
    };

    // ── the four that go the ordinary way ────────────────────────────────────────────────────────
    let ordinary: [(usize, solana_instruction::Instruction); 4] = [
        (0, ProofInstruction::VerifyCiphertextCommitmentEquality
            .encode_verify_proof::<CiphertextCommitmentEqualityProofData, CiphertextCommitmentEqualityProofContext>(
                Some(info(0)), &d.equality)),
        (1, ProofInstruction::VerifyBatchedGroupedCiphertext3HandlesValidity
            .encode_verify_proof::<BatchedGroupedCiphertext3HandlesValidityProofData, BatchedGroupedCiphertext3HandlesValidityProofContext>(
                Some(info(1)), &d.validity3)),
        (2, ProofInstruction::VerifyPercentageWithCap
            .encode_verify_proof::<PercentageWithCapProofData, PercentageWithCapProofContext>(
                Some(info(2)), &d.percentage)),
        (3, ProofInstruction::VerifyBatchedGroupedCiphertext2HandlesValidity
            .encode_verify_proof::<BatchedGroupedCiphertext2HandlesValidityProofData, BatchedGroupedCiphertext2HandlesValidityProofContext>(
                Some(info(3)), &d.fee_validity)),
    ];
    for (n, ix) in ordinary {
        emit(
            &format!("create ctx {n}"),
            legacy(
                create_account(&payer.pubkey(), &accounts[n].pubkey(), rent_exempt(sizes[n]), sizes[n] as u64, &zk),
                &[&payer, &accounts[n]],
            ),
            "legacy",
        );
        emit(&format!("verify ctx {n}"), legacy(ix, &[&payer]), "legacy");
    }

    // ── and the range proof, which cannot ────────────────────────────────────────────────────────
    let proof_bytes = bytemuck::bytes_of(&d.range).to_vec();
    let record = load_or_create(keys_dir, "fee-record.json");
    let record_space = RECORD_WRITABLE_START as usize + proof_bytes.len();
    emit(
        "create record",
        legacy(
            create_account(
                &payer.pubkey(),
                &record.pubkey(),
                rent_exempt(record_space),
                record_space as u64,
                &Address::from_str(SPL_RECORD).unwrap(),
            ),
            &[&payer, &record],
        ),
        "legacy",
    );
    emit(
        "init record",
        legacy(record_initialize(&record.pubkey(), &payer.pubkey()), &[&payer]),
        "legacy",
    );
    for (i, chunk) in proof_bytes.chunks(CHUNK).enumerate() {
        emit(
            &format!("write proof {}/{}", i + 1, proof_bytes.len().div_ceil(CHUNK)),
            legacy(
                record_write(&record.pubkey(), &payer.pubkey(), (i * CHUNK) as u64, chunk),
                &[&payer],
            ),
            "legacy",
        );
    }
    emit(
        "create ctx 4",
        legacy(
            create_account(&payer.pubkey(), &accounts[4].pubkey(), rent_exempt(sizes[4]), sizes[4] as u64, &zk),
            &[&payer, &accounts[4]],
        ),
        "legacy",
    );
    // Five bytes of instruction data, and the 1,064-byte proof read out of the account beside it.
    let verify_from_account = ProofInstruction::VerifyBatchedRangeProofU256
        .encode_verify_proof_from_account(Some(info(4)), &record.pubkey(), RECORD_WRITABLE_START);
    // A U256 range proof does not verify inside the 200,000-unit default — it failed with
    // `ComputationalBudgetExceeded` before this line existed. Asking for the ceiling costs 40
    // bytes on a 215-byte transaction, and the proof only has to verify once.
    let ixs = [compute_unit_limit(1_400_000), verify_from_account];
    let bytes = if alt != "none" {
        let table = AddressLookupTableAccount {
            key: Address::from_str(alt).expect("lookup table address"),
            addresses: vec![accounts[4].pubkey(), authority, record.pubkey()],
        };
        let msg = v0::Message::try_compile(&payer.pubkey(), &ixs, &[table], blockhash)
            .expect("compile v0");
        bincode::serialize(&VersionedTransaction::try_new(VersionedMessage::V0(msg), &[&payer]).unwrap())
            .unwrap()
    } else {
        bincode::serialize(&Transaction::new(
            &[&payer],
            Message::new(&ixs, Some(&payer.pubkey())),
            blockhash,
        ))
        .unwrap()
    };
    let how = if alt != "none" { "v0 + lookup table" } else { "legacy" };
    emit("verify ctx 4 from account", bytes, how);

    // `skip` transactions have already landed. Printed as skipped rather than dropped silently,
    // because a miscounted skip would resend a create and fail with AccountAlreadyInitialized.
    for (i, (b64, label, n)) in txs.iter().enumerate() {
        if i < skip {
            eprintln!("  {label:34} {n:5} bytes   (already sent)");
            continue;
        }
        eprintln!("  {label:34} {n:5} bytes{}", if *n > 1232 { "   <- OVER" } else { "" });
        println!("{b64}");
    }
    eprintln!("  transactions       {} in all, {skip} already sent", txs.len());

    std::fs::write(
        out,
        serde_json::to_vec_pretty(&serde_json::json!({
            "equality":     accounts[0].pubkey().to_string(),
            "validity":     accounts[1].pubkey().to_string(),
            "percentage":   accounts[2].pubkey().to_string(),
            "fee_validity": accounts[3].pubkey().to_string(),
            "range":        accounts[4].pubkey().to_string(),
            "record":       record.pubkey().to_string(),
            "with_fee":     true,
            "authority":    authority.to_string(),
            "amount":       amount,
            "remaining":    balance - amount,
            // The source's balance after the transfer. The fee is withheld from the destination,
            // so the sender is debited the whole amount and nothing else.
            "new_decryptable_b64": b64(&ae.encrypt(balance - amount).to_bytes()),
            "auditor_lo_b64": b64(&d.auditor_lo.0),
            "auditor_hi_b64": b64(&d.auditor_hi.0),
        }))
        .unwrap(),
    )
    .unwrap();

    eprintln!("  proofs             5 (equality, validity3, percentage+cap, validity2, range256)");
    eprintln!("  range proof        {} bytes, staged through record {}", proof_bytes.len(), record.pubkey());
    eprintln!("  fee                {fee_bps} bps, max {max_fee}");
    eprintln!("  artifact           {out}");
}

fn d64(s: &str) -> Vec<u8> {
    base64::engine::general_purpose::STANDARD.decode(s).expect("base64")
}
fn b64(b: &[u8]) -> String {
    base64::engine::general_purpose::STANDARD.encode(b)
}
fn pubkey(s: &str) -> ElGamalPubkey {
    ElGamalPubkey::try_from(&d64(s)[..]).expect("elgamal pubkey")
}

/// The five proofs plus the two auditor ciphertexts, as one block of bytes. Every field is `Pod`,
/// so this is a layout rather than a format.
#[repr(C)]
#[derive(Clone, Copy, bytemuck::Pod, bytemuck::Zeroable)]
struct Proofs {
    equality: CiphertextCommitmentEqualityProofData,
    validity3: BatchedGroupedCiphertext3HandlesValidityProofData,
    percentage: PercentageWithCapProofData,
    fee_validity: BatchedGroupedCiphertext2HandlesValidityProofData,
    range: BatchedRangeProofU256Data,
    auditor_lo: PodElGamalCiphertext,
    auditor_hi: PodElGamalCiphertext,
}
