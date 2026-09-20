//! Building blocks shared by every tool that puts a proof on chain.
//!
//! These lived inside `seizure_ctx.rs` and were about to be typed a second time into the with-fee
//! path. Two copies of a rent formula is how this repository has broken things before, so they are
//! here instead.

use base64::Engine;
use solana_address::Address;
use solana_instruction::{AccountMeta, Instruction};
use solana_keypair::Keypair;
use std::str::FromStr;

pub const SYSTEM: &str = "11111111111111111111111111111111";
pub const COMPUTE_BUDGET: &str = "ComputeBudget111111111111111111111111111111";
/// The reference record program, deployed on devnet and mainnet alike. It exists here for one
/// reason: the with-fee range proof is too large to verify from instruction data, so it has to be
/// written into an account and cited by offset.
pub const SPL_RECORD: &str = "recr1L3PCGKLbckBqMNcJhuuyU1zgo8nBhfLVsJNwr5";
/// `RecordData` is a version byte and a 32-byte authority, then the bytes. The ZK program is given
/// an offset into the account's raw data, so this is the offset a proof written at the start of
/// the writable area lives at.
pub const RECORD_WRITABLE_START: u32 = 33;

/// Rent exemption, computed rather than fetched: `(overhead + size) * lamports_per_byte_year *
/// exemption_years`, the constants the runtime has used since genesis.
const ACCOUNT_STORAGE_OVERHEAD: u64 = 128;
const LAMPORTS_PER_BYTE_YEAR: u64 = 3_480;
const EXEMPTION_YEARS: u64 = 2;

pub fn rent_exempt(size: usize) -> u64 {
    (ACCOUNT_STORAGE_OVERHEAD + size as u64) * LAMPORTS_PER_BYTE_YEAR * EXEMPTION_YEARS
}

/// `SystemInstruction::CreateAccount` — hand-encoded so this crate keeps its small dependency set.
pub fn create_account(
    from: &Address,
    to: &Address,
    lamports: u64,
    space: u64,
    owner: &Address,
) -> Instruction {
    let mut data = vec![0u8; 4];
    data.extend_from_slice(&lamports.to_le_bytes());
    data.extend_from_slice(&space.to_le_bytes());
    data.extend_from_slice(&owner.to_bytes());
    Instruction {
        program_id: Address::from_str(SYSTEM).unwrap(),
        accounts: vec![AccountMeta::new(*from, true), AccountMeta::new(*to, true)],
        data,
    }
}

/// `RecordInstruction::Initialize` — borsh variant 0, no fields.
/// Accounts: the record account, then the authority it will answer to.
pub fn record_initialize(record: &Address, authority: &Address) -> Instruction {
    Instruction {
        program_id: Address::from_str(SPL_RECORD).unwrap(),
        accounts: vec![
            AccountMeta::new(*record, false),
            AccountMeta::new_readonly(*authority, false),
        ],
        data: vec![0u8],
    }
}

/// `RecordInstruction::Write { offset, data }` — borsh variant 1, a u64 offset relative to the
/// writable area, then the bytes with borsh's u32 length prefix.
pub fn record_write(record: &Address, authority: &Address, offset: u64, bytes: &[u8]) -> Instruction {
    let mut data = vec![1u8];
    data.extend_from_slice(&offset.to_le_bytes());
    data.extend_from_slice(&(bytes.len() as u32).to_le_bytes());
    data.extend_from_slice(bytes);
    Instruction {
        program_id: Address::from_str(SPL_RECORD).unwrap(),
        accounts: vec![
            AccountMeta::new(*record, false),
            AccountMeta::new_readonly(*authority, true),
        ],
        data,
    }
}

/// `ComputeBudgetInstruction::SetComputeUnitLimit` — discriminant 2, then a `u32` of units.
///
/// Needed for exactly one thing here: verifying the with-fee `BatchedRangeProofU256`. It is a
/// bulletproof over six commitments and it does not fit the 200,000-unit default — measured, by
/// watching it fail with `ComputationalBudgetExceeded`. The ceiling is 1,400,000.
pub fn compute_unit_limit(units: u32) -> Instruction {
    let mut data = vec![2u8];
    data.extend_from_slice(&units.to_le_bytes());
    Instruction {
        program_id: Address::from_str(COMPUTE_BUDGET).unwrap(),
        accounts: vec![],
        data,
    }
}

pub fn b64tx(bytes: &[u8]) -> String {
    base64::engine::general_purpose::STANDARD.encode(bytes)
}

/// Context account keypairs are throwaway — they exist to hold one proof each — but they must
/// survive between the run that names them and the run that fills them.
pub fn load_or_create(dir: &str, name: &str) -> Keypair {
    let path = format!("{dir}/{name}");
    if let Ok(bytes) = std::fs::read(&path) {
        let v: Vec<u8> = serde_json::from_slice(&bytes).unwrap();
        return Keypair::try_from(&v[..]).unwrap();
    }
    let kp = Keypair::new();
    std::fs::create_dir_all(dir).unwrap();
    std::fs::write(&path, serde_json::to_vec(&kp.to_bytes().to_vec()).unwrap()).unwrap();
    kp
}

pub fn read_keypair(path: &str) -> Keypair {
    let bytes: Vec<u8> = serde_json::from_slice(&std::fs::read(path).unwrap()).unwrap();
    Keypair::try_from(&bytes[..]).unwrap()
}

#[cfg(test)]
mod tests {
    use super::*;
    use solana_signer::Signer;

    #[test]
    fn a_record_write_carries_its_length() {
        let r = Keypair::new().pubkey();
        let a = Keypair::new().pubkey();
        let ix = record_write(&r, &a, 0, &[7u8; 900]);
        assert_eq!(ix.data[0], 1, "Write is borsh variant 1");
        assert_eq!(&ix.data[1..9], &0u64.to_le_bytes(), "offset first");
        assert_eq!(&ix.data[9..13], &900u32.to_le_bytes(), "then a u32 length");
        assert_eq!(ix.data.len(), 1 + 8 + 4 + 900);
        assert!(ix.accounts[1].is_signer, "the authority signs its own writes");
    }

    #[test]
    fn a_compute_budget_request_is_five_bytes() {
        let ix = compute_unit_limit(600_000);
        assert_eq!(ix.data, vec![2, 0xc0, 0x27, 0x09, 0x00], "discriminant then u32 LE");
        assert!(ix.accounts.is_empty(), "it names no accounts");
    }

    #[test]
    fn rent_is_the_genesis_formula() {
        assert_eq!(rent_exempt(0), 128 * 3_480 * 2);
        assert_eq!(rent_exempt(1_097), (128 + 1_097) * 3_480 * 2);
    }
}
