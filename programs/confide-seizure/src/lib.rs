//! Confide Seizure — take confidential collateral on default.
//!
//! A confidential transfer must *prove* what it moves, and building those proofs needs the source
//! account's ElGamal secret. No program can hold one: its state is public. So a lending protocol
//! cannot seize confidential collateral the usual way — it cannot prove what it is taking.
//!
//! This takes the other route. At origination the borrower is cooperative by definition, holds the
//! key, and the transfer is already fully determined. So the proofs are built **then** and
//! pre-verified into context state accounts, which `Transfer` accepts by address alone. Default
//! fires a CPI from the program that owns the escrow. Nothing is reconstructed, nobody is asked,
//! and no party learns the amount.
//!
//! What this program does **not** check, because Token-2022 already does and re-checking it here
//! would be theatre: that the proofs bind to the escrow's own ciphertext, and that the destination
//! handle is the destination account's key. The processor recomputes the source's new balance and
//! rejects a `Transfer` whose proofs do not match. What it cannot know, and this program must
//! enforce, is **who may close the proofs** — a borrower holding the context state authority can
//! disarm the seizure the day before default.
//!
//! Instructions:
//!   0 Originate — record the loan, and refuse unless the proofs are already beyond the borrower's
//!     reach. Creates the loan PDA: seeds = [b"loan", escrow].
//!   1 Seize — the predicate, then the transfer. Callable by anyone: default is a public fact.

use solana_program::{
    account_info::{next_account_info, AccountInfo},
    entrypoint,
    entrypoint::ProgramResult,
    msg,
    program::invoke_signed,
    program_error::ProgramError,
    pubkey::Pubkey,
    rent::Rent,
    system_instruction,
    sysvar::Sysvar,
};

/// Marks an initialised loan.
pub const LOAN_TAG: u8 = 1;

/// Loan layout (bytes). Fixed offsets rather than a serialisation crate: the account is written
/// once and read once, and a hand-checked table is easier to audit than a derive.
///
/// ```text
///   [0]        tag
///   [1..33]    escrow token account
///   [33..65]   destination — the lender's token account
///   [65..97]   mint
///   [97..129]  context state: equality
///   [129..161] context state: ciphertext validity
///   [161..193] context state: range
///   [193..225] oracle — the only party that may assert a price
///   [225..233] q_min, base units: the floor the borrower PROVED, not what they hold
///   [233..241] principal, cents
///   [241..249] required ratio, basis points
///   [249..285] new_source_decryptable_available_balance (36)
///   [285..349] auditor ciphertext lo (64)
///   [349..413] auditor ciphertext hi (64)
///   [413]      bump
///   [414]      seized
/// ```
pub const LOAN_LEN: usize = 415;

const OFF_ESCROW: usize = 1;
const OFF_DESTINATION: usize = 33;
const OFF_MINT: usize = 65;
const OFF_CTX_EQUALITY: usize = 97;
const OFF_CTX_VALIDITY: usize = 129;
const OFF_CTX_RANGE: usize = 161;
const OFF_ORACLE: usize = 193;
const OFF_Q_MIN: usize = 225;
const OFF_PRINCIPAL: usize = 233;
const OFF_RATIO_BPS: usize = 241;
const OFF_NEW_DECRYPTABLE: usize = 249;
const OFF_AUDITOR_LO: usize = 285;
const OFF_AUDITOR_HI: usize = 349;
const OFF_BUMP: usize = 413;
const OFF_SEIZED: usize = 414;

/// A context state account is `[authority(32) | proof_type(1) | context]`.
const CTX_AUTHORITY: usize = 0;
const CTX_PROOF_TYPE: usize = 32;

/// `ProofType` discriminants, from the ZK ElGamal Proof Program's own ordering.
const PROOF_TYPE_EQUALITY: u8 = 2;
const PROOF_TYPE_BATCHED_RANGE_U128: u8 = 6;
const PROOF_TYPE_BATCHED_VALIDITY_3: u8 = 9;

solana_program::declare_id!("SeiZure111111111111111111111111111111111111");

entrypoint!(process);

fn process(program_id: &Pubkey, accounts: &[AccountInfo], data: &[u8]) -> ProgramResult {
    let (&disc, rest) = data.split_first().ok_or(ProgramError::InvalidInstructionData)?;
    match disc {
        0 => originate(program_id, accounts, rest),
        1 => seize(program_id, accounts, rest),
        _ => Err(ProgramError::InvalidInstructionData),
    }
}

/// `Originate` — record the loan, and refuse it unless seizure is already out of the borrower's
/// hands.
///
/// Accounts: payer(s,w), loan(w), escrow, destination, mint, ctx_equality, ctx_validity, ctx_range,
/// oracle, system_program
///
/// Data: q_min u64 | principal u64 | ratio_bps u64 | new_decryptable[36] | auditor_lo[64] |
/// auditor_hi[64]
fn originate(program_id: &Pubkey, accounts: &[AccountInfo], data: &[u8]) -> ProgramResult {
    let i = &mut accounts.iter();
    let payer = next_account_info(i)?;
    let loan = next_account_info(i)?;
    let escrow = next_account_info(i)?;
    let destination = next_account_info(i)?;
    let mint = next_account_info(i)?;
    let ctx_equality = next_account_info(i)?;
    let ctx_validity = next_account_info(i)?;
    let ctx_range = next_account_info(i)?;
    let oracle = next_account_info(i)?;
    let system_program = next_account_info(i)?;

    if !payer.is_signer {
        return Err(ProgramError::MissingRequiredSignature);
    }
    if data.len() != 8 + 8 + 8 + 36 + 64 + 64 {
        return Err(ProgramError::InvalidInstructionData);
    }

    let (expected, bump) = Pubkey::find_program_address(&[b"loan", escrow.key.as_ref()], program_id);
    if expected != *loan.key {
        return Err(ProgramError::InvalidSeeds);
    }
    if !loan.data_is_empty() {
        msg!("this escrow already secures a loan");
        return Err(ProgramError::AccountAlreadyInitialized);
    }

    // The check Token-2022 cannot make for us. A context state account is closable by its
    // authority; if that is the borrower, they can withdraw the proofs the day before default and
    // the seizure evaporates. Everything else about these proofs the processor re-checks at
    // transfer time, so it is not re-checked here.
    for (account, proof_type, what) in [
        (ctx_equality, PROOF_TYPE_EQUALITY, "equality"),
        (ctx_validity, PROOF_TYPE_BATCHED_VALIDITY_3, "ciphertext validity"),
        (ctx_range, PROOF_TYPE_BATCHED_RANGE_U128, "range"),
    ] {
        let d = account.try_borrow_data()?;
        if d.len() <= CTX_PROOF_TYPE {
            msg!("{} context is not a proof context", what);
            return Err(ProgramError::InvalidAccountData);
        }
        if d[CTX_PROOF_TYPE] != proof_type {
            msg!("{} context holds the wrong kind of proof", what);
            return Err(ProgramError::InvalidAccountData);
        }
        if d[CTX_AUTHORITY..CTX_AUTHORITY + 32] != loan.key.to_bytes() {
            msg!("{} context can still be closed by someone other than this loan", what);
            return Err(ProgramError::InvalidAccountOwner);
        }
    }

    let rent = Rent::get()?.minimum_balance(LOAN_LEN);
    invoke_signed(
        &system_instruction::create_account(payer.key, loan.key, rent, LOAN_LEN as u64, program_id),
        &[payer.clone(), loan.clone(), system_program.clone()],
        &[&[b"loan", escrow.key.as_ref(), &[bump]]],
    )?;

    let mut d = loan.try_borrow_mut_data()?;
    d[0] = LOAN_TAG;
    d[OFF_ESCROW..OFF_ESCROW + 32].copy_from_slice(&escrow.key.to_bytes());
    d[OFF_DESTINATION..OFF_DESTINATION + 32].copy_from_slice(&destination.key.to_bytes());
    d[OFF_MINT..OFF_MINT + 32].copy_from_slice(&mint.key.to_bytes());
    d[OFF_CTX_EQUALITY..OFF_CTX_EQUALITY + 32].copy_from_slice(&ctx_equality.key.to_bytes());
    d[OFF_CTX_VALIDITY..OFF_CTX_VALIDITY + 32].copy_from_slice(&ctx_validity.key.to_bytes());
    d[OFF_CTX_RANGE..OFF_CTX_RANGE + 32].copy_from_slice(&ctx_range.key.to_bytes());
    d[OFF_ORACLE..OFF_ORACLE + 32].copy_from_slice(&oracle.key.to_bytes());
    d[OFF_Q_MIN..OFF_NEW_DECRYPTABLE].copy_from_slice(&data[..24]);
    d[OFF_NEW_DECRYPTABLE..OFF_BUMP].copy_from_slice(&data[24..]);
    d[OFF_BUMP] = bump;
    d[OFF_SEIZED] = 0;

    msg!("loan originated; seizure is armed and the borrower cannot disarm it");
    Ok(())
}

/// `Seize` — the predicate, then the transfer.
///
/// Anyone may call it. Default is a public fact about public numbers, and a seizure that only the
/// lender could trigger would be a seizure the lender could also decline to trigger.
///
/// Accounts: loan(w), escrow(w), mint, destination(w), ctx_equality, ctx_validity, ctx_range,
/// oracle(s), token_program
///
/// Data: price u64, cents per unit
fn seize(program_id: &Pubkey, accounts: &[AccountInfo], data: &[u8]) -> ProgramResult {
    let i = &mut accounts.iter();
    let loan = next_account_info(i)?;
    let escrow = next_account_info(i)?;
    let mint = next_account_info(i)?;
    let destination = next_account_info(i)?;
    let ctx_equality = next_account_info(i)?;
    let ctx_validity = next_account_info(i)?;
    let ctx_range = next_account_info(i)?;
    let oracle = next_account_info(i)?;
    let token_program = next_account_info(i)?;

    if loan.owner != program_id {
        return Err(ProgramError::IllegalOwner);
    }
    let price = u64::from_le_bytes(
        data.get(..8)
            .ok_or(ProgramError::InvalidInstructionData)?
            .try_into()
            .unwrap(),
    );

    let (escrow_key, destination_key, new_decryptable, auditor_lo, auditor_hi, bump) = {
        let d = loan.try_borrow_data()?;
        if d[0] != LOAN_TAG {
            return Err(ProgramError::UninitializedAccount);
        }
        if d[OFF_SEIZED] != 0 {
            msg!("already seized; opening is not repeatable");
            return Err(ProgramError::InvalidAccountData);
        }
        // Every account the transfer touches comes from the loan record, not from the caller, so a
        // caller cannot redirect a seizure by passing different accounts.
        check(&d[OFF_ESCROW..], escrow.key)?;
        check(&d[OFF_DESTINATION..], destination.key)?;
        check(&d[OFF_MINT..], mint.key)?;
        check(&d[OFF_CTX_EQUALITY..], ctx_equality.key)?;
        check(&d[OFF_CTX_VALIDITY..], ctx_validity.key)?;
        check(&d[OFF_CTX_RANGE..], ctx_range.key)?;
        check(&d[OFF_ORACLE..], oracle.key)?;
        if !oracle.is_signer {
            msg!("the price is an assertion and must be signed by the oracle this loan names");
            return Err(ProgramError::MissingRequiredSignature);
        }

        let q_min = read_u64(&d, OFF_Q_MIN);
        let principal = read_u64(&d, OFF_PRINCIPAL);
        let ratio_bps = read_u64(&d, OFF_RATIO_BPS);

        if !in_default(q_min, price, principal, ratio_bps) {
            msg!("not in default: collateral floor still clears the requirement");
            return Err(ProgramError::InvalidArgument);
        }

        (
            Pubkey::new_from_array(slice32(&d, OFF_ESCROW)),
            Pubkey::new_from_array(slice32(&d, OFF_DESTINATION)),
            d[OFF_NEW_DECRYPTABLE..OFF_AUDITOR_LO].to_vec(),
            d[OFF_AUDITOR_LO..OFF_AUDITOR_HI].to_vec(),
            d[OFF_AUDITOR_HI..OFF_BUMP].to_vec(),
            d[OFF_BUMP],
        )
    };

    let ix = transfer_instruction(
        token_program.key,
        &escrow_key,
        mint.key,
        &destination_key,
        loan.key,
        ctx_equality.key,
        ctx_validity.key,
        ctx_range.key,
        &new_decryptable,
        &auditor_lo,
        &auditor_hi,
    )?;

    // The signature the borrower cannot produce and the program can. Token-2022 re-verifies that
    // the pre-verified proofs describe this escrow and this destination, so a stale or redirected
    // proof set fails here rather than moving the wrong tokens.
    invoke_signed(
        &ix,
        &[
            escrow.clone(),
            mint.clone(),
            destination.clone(),
            ctx_equality.clone(),
            ctx_validity.clone(),
            ctx_range.clone(),
            loan.clone(),
            token_program.clone(),
        ],
        &[&[b"loan", escrow_key.as_ref(), &[bump]]],
    )?;

    loan.try_borrow_mut_data()?[OFF_SEIZED] = 1;
    msg!("seized: the collateral is the lender's, and is still confidential");
    Ok(())
}

/// The predicate, entirely in public terms.
///
/// `q_min` is the floor the borrower **proved** at origination, not what they hold — so the value
/// computed here is a lower bound on the collateral and the lender is over-collateralised by
/// construction. What the borrower actually holds is not an input, and evaluating this does not
/// learn it. Widened to `u128` because base units times cents overflows `u64` at realistic sizes.
pub fn in_default(q_min: u64, price: u64, principal: u64, ratio_bps: u64) -> bool {
    let value = (q_min as u128) * (price as u128);
    let required = (principal as u128) * (ratio_bps as u128) / 10_000;
    value < required
}

fn check(field: &[u8], key: &Pubkey) -> ProgramResult {
    if field[..32] != key.to_bytes() {
        return Err(ProgramError::InvalidArgument);
    }
    Ok(())
}

fn read_u64(d: &[u8], at: usize) -> u64 {
    u64::from_le_bytes(d[at..at + 8].try_into().unwrap())
}

fn slice32(d: &[u8], at: usize) -> [u8; 32] {
    d[at..at + 32].try_into().unwrap()
}

/// Build the `Transfer` instruction with all three proofs cited by address.
///
/// `ProofLocation::ContextStateAccount` is the variant this design turns on: the proofs were
/// verified once, at origination, and this names them rather than carrying them.
#[allow(clippy::too_many_arguments)]
fn transfer_instruction(
    token_program: &Pubkey,
    escrow: &Pubkey,
    mint: &Pubkey,
    destination: &Pubkey,
    authority: &Pubkey,
    ctx_equality: &Pubkey,
    ctx_validity: &Pubkey,
    ctx_range: &Pubkey,
    new_decryptable: &[u8],
    auditor_lo: &[u8],
    auditor_hi: &[u8],
) -> Result<solana_program::instruction::Instruction, ProgramError> {
    use spl_token_2022_interface::extension::confidential_transfer::instruction::inner_transfer;
    use spl_token_confidential_transfer_proof_extraction::instruction::ProofLocation;

    let a = |k: &Pubkey| solana_address::Address::from(k.to_bytes());
    let ix = inner_transfer(
        &a(token_program),
        &a(escrow),
        &a(mint),
        &a(destination),
        bytemuck::from_bytes(new_decryptable),
        bytemuck::from_bytes(auditor_lo),
        bytemuck::from_bytes(auditor_hi),
        &a(authority),
        &[],
        ProofLocation::ContextStateAccount(&a(ctx_equality)),
        ProofLocation::ContextStateAccount(&a(ctx_validity)),
        ProofLocation::ContextStateAccount(&a(ctx_range)),
    )
    // The interface crate carries its own `ProgramError`; only one thing can go wrong here (a
    // token program id that is not Token-2022) and it is worth naming rather than forwarding.
    .map_err(|_| ProgramError::IncorrectProgramId)?;

    Ok(solana_program::instruction::Instruction {
        program_id: Pubkey::new_from_array(ix.program_id.to_bytes()),
        accounts: ix
            .accounts
            .into_iter()
            .map(|m| solana_program::instruction::AccountMeta {
                pubkey: Pubkey::new_from_array(m.pubkey.to_bytes()),
                is_signer: m.is_signer,
                is_writable: m.is_writable,
            })
            .collect(),
        data: ix.data,
    })
}

#[cfg(test)]
mod invariants {
    use super::*;

    /// **L1 — the layout table in the doc comment is the layout.** Every field is written at a
    /// hand-written offset; an overlap would silently corrupt a neighbour and be found on devnet
    /// rather than here.
    #[test]
    fn the_loan_fields_tile_the_account_without_gaps_or_overlap() {
        let fields: [(usize, usize); 14] = [
            (0, 1),
            (OFF_ESCROW, 32),
            (OFF_DESTINATION, 32),
            (OFF_MINT, 32),
            (OFF_CTX_EQUALITY, 32),
            (OFF_CTX_VALIDITY, 32),
            (OFF_CTX_RANGE, 32),
            (OFF_ORACLE, 32),
            (OFF_Q_MIN, 8),
            (OFF_PRINCIPAL, 8),
            (OFF_RATIO_BPS, 8),
            (OFF_NEW_DECRYPTABLE, 36),
            (OFF_AUDITOR_LO, 64),
            (OFF_AUDITOR_HI, 64),
        ];
        let mut cursor = 0;
        for (at, len) in fields {
            assert_eq!(at, cursor, "field at {at} does not start where the previous one ended");
            cursor += len;
        }
        assert_eq!(cursor, OFF_BUMP, "the fields must run up to the bump");
        assert_eq!(LOAN_LEN, OFF_SEIZED + 1);
    }

    /// **L2 — origination writes exactly the instruction data it was given.** The two bulk copies
    /// split the payload at 24 bytes; if that split moved, the auditor ciphertexts would be written
    /// over the numbers the predicate reads.
    #[test]
    fn the_instruction_payload_splits_where_the_copies_expect() {
        assert_eq!(OFF_NEW_DECRYPTABLE - OFF_Q_MIN, 24, "q_min, principal and ratio are 24 bytes");
        assert_eq!(OFF_BUMP - OFF_NEW_DECRYPTABLE, 36 + 64 + 64);
        assert_eq!(8 + 8 + 8 + 36 + 64 + 64, OFF_BUMP - OFF_Q_MIN);
    }

    /// **L3 — default is a strict crossing.** A loan exactly at its requirement is not in default;
    /// seizing there would take collateral from a borrower who is still good for it.
    #[test]
    fn a_loan_exactly_at_its_requirement_is_not_in_default() {
        // 100,000 base units at 100 cents = 10,000,000. Principal 5,000,000 cents at 200 % = the
        // same 10,000,000.
        assert!(!in_default(100_000, 100, 5_000_000, 20_000));
        assert!(in_default(100_000, 99, 5_000_000, 20_000));
        assert!(!in_default(100_000, 101, 5_000_000, 20_000));
    }

    /// **L4 — the predicate does not wrap.** The README's position — 173,000 NVDAx at eight
    /// decimals, $184.50 — multiplies out to 3.19e17, which still fits `u64`. It is the headroom
    /// above it that does not: a share price over roughly $10,600 overflows the same product, and
    /// tokenized equities include names that trade far above it. An overflow here reads as a
    /// default that did not happen, and takes collateral on it.
    #[test]
    fn the_predicate_does_not_wrap_where_u64_would() {
        let q_min = 17_300_000_000_000u64; // 173,000 units, 8 decimals
        assert!(!in_default(q_min, 18_450, 1_000_000_000, 20_000));

        // The crossing where a u64 product would wrap, and where this one must not.
        let breaking_price = (u64::MAX / q_min) + 1;
        assert!(breaking_price < 1_100_000, "under $11,000 a share — not a hypothetical");
        assert!(q_min.checked_mul(breaking_price).is_none(), "u64 would wrap here");
        assert!(
            !in_default(q_min, breaking_price, u64::MAX, 10_000),
            "a position worth more than the loan is not in default, however large the product"
        );

        // And a genuine default is still detected at the same scale.
        assert!(in_default(q_min, 1, u64::MAX / 10_000, 20_000));
    }
}
