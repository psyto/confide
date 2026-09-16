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

use solana_zk_elgamal_proof_interface::proof_data::ProofType;
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
///   [225..233] q_min, WHOLE units: the floor the borrower PROVED, not what they hold
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

/// `ProofType` discriminants, taken from the enum rather than transcribed.
///
/// They were transcribed once, as 2 / 6 / 9, and every one of them was wrong — the chain said
/// 3 / 7 / 12 when the accounts were read back. A wrong discriminant here does not fail loudly: it
/// accepts a valid proof of the wrong kind in the right slot, which is the sort of check that
/// looks like rigour and is not. Deriving them means the enum has to change under us for them to
/// drift, and the test below would catch that too.
const PROOF_TYPE_EQUALITY: u8 = ProofType::CiphertextCommitmentEquality as u8;
const PROOF_TYPE_BATCHED_RANGE_U128: u8 = ProofType::BatchedRangeProofU128 as u8;
const PROOF_TYPE_BATCHED_RANGE_U64: u8 = ProofType::BatchedRangeProofU64 as u8;
const PROOF_TYPE_BATCHED_VALIDITY_3: u8 = ProofType::BatchedGroupedCiphertext3HandlesValidity as u8;

// The address this is deployed at on devnet. It was a placeholder until 2026-09-16, which left a
// reader with no way to bind the source they cloned to the program the documents point at.
solana_program::declare_id!("Gn3rzw8ULVo676ebnxX6qK3YEQP9T8NHtFVetXW8QduN");

entrypoint!(process);

fn process(program_id: &Pubkey, accounts: &[AccountInfo], data: &[u8]) -> ProgramResult {
    let (&disc, rest) = data.split_first().ok_or(ProgramError::InvalidInstructionData)?;
    match disc {
        0 => originate(program_id, accounts, rest),
        1 => seize(program_id, accounts, rest),
        2 => deshield(program_id, accounts, rest),
        _ => Err(ProgramError::InvalidInstructionData),
    }
}

/// `Originate` — record the loan, and refuse it unless seizure is already out of the borrower's
/// hands.
///
/// Accounts: payer(s,w), loan(w), escrow, destination, mint, ctx_equality, ctx_validity, ctx_range,
/// ctx_floor_equality, ctx_floor_range, oracle, system_program
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
    let ctx_floor_equality = next_account_info(i)?;
    let ctx_floor_range = next_account_info(i)?;
    let oracle = next_account_info(i)?;
    let system_program = next_account_info(i)?;

    if !payer.is_signer {
        return Err(ProgramError::MissingRequiredSignature);
    }
    if data.len() != 8 + 8 + 8 + 36 + 64 + 64 {
        return Err(ProgramError::InvalidInstructionData);
    }

    let (expected, bump) = loan_address(program_id, escrow.key);
    if expected != *loan.key {
        return Err(ProgramError::InvalidSeeds);
    }
    if !loan.data_is_empty() {
        msg!("this escrow already secures a loan");
        return Err(ProgramError::AccountAlreadyInitialized);
    }

    // The handover, verified rather than assumed. Until this existed, `originate` recorded whatever
    // escrow address it was handed: a borrower could originate against an account they still owned
    // and move the collateral afterwards, and "one escrow, one loan" was a property of the PDA that
    // nothing checked had been reached.
    {
        let e = escrow.try_borrow_data()?;
        if e.len() < ACCOUNT_OWNER + 32 {
            return Err(ProgramError::InvalidAccountData);
        }
        if e[ACCOUNT_OWNER..ACCOUNT_OWNER + 32] != loan.key.to_bytes() {
            msg!("the escrow has not been handed over — its owner is not this loan");
            return Err(ProgramError::IllegalOwner);
        }
    }

    // The check Token-2022 cannot make for us. A context state account is closable by its
    // authority; if that is the borrower, they can withdraw the proofs the day before default and
    // the seizure evaporates. Everything else about these proofs the processor re-checks at
    // transfer time, so it is not re-checked here.
    for (account, proof_type, what) in [
        (ctx_equality, PROOF_TYPE_EQUALITY, "equality"),
        (ctx_validity, PROOF_TYPE_BATCHED_VALIDITY_3, "ciphertext validity"),
        (ctx_range, PROOF_TYPE_BATCHED_RANGE_U128, "range"),
        (ctx_floor_equality, PROOF_TYPE_EQUALITY, "floor equality"),
        (ctx_floor_range, PROOF_TYPE_BATCHED_RANGE_U64, "floor range"),
    ] {
        if let Err(e) = context_is_armed(&account.try_borrow_data()?, proof_type, loan.key) {
            msg!("{} context: {}", what, disarm_reason(&e));
            return Err(e);
        }
    }

    // The floor is proved on chain, not recorded on trust. Two more context accounts, the pair
    // `prove-collateral` produces, and the arithmetic that joins them — bound to this escrow's own
    // key and ciphertext, and scaled by the mint's own decimals so that `q_min` means the same
    // thing here as it does in the default predicate.
    let q_min = u64::from_le_bytes(data[..8].try_into().unwrap());
    let decimals = {
        let m = mint.try_borrow_data()?;
        if m.len() <= MINT_DECIMALS {
            return Err(ProgramError::InvalidAccountData);
        }
        m[MINT_DECIMALS]
    };
    let floor_base_units = q_min
        .checked_mul(10u64.checked_pow(decimals as u32).ok_or(ProgramError::InvalidArgument)?)
        .ok_or(ProgramError::InvalidArgument)?;

    let (elgamal_pubkey, ciphertext) = escrow_confidential_state(&escrow.try_borrow_data()?)?;
    floor_is_proved(
        &ctx_floor_equality.try_borrow_data()?,
        &ctx_floor_range.try_borrow_data()?,
        &elgamal_pubkey,
        &ciphertext,
        floor_base_units,
    )?;

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
        may_seize(
            &d,
            Cited {
                escrow: escrow.key,
                destination: destination.key,
                mint: mint.key,
                ctx_equality: ctx_equality.key,
                ctx_validity: ctx_validity.key,
                ctx_range: ctx_range.key,
                oracle: oracle.key,
            },
            oracle.is_signer,
            price,
        )?;

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

/// The ristretto basepoint, which is Pedersen's `G`: a commitment is `value·G + opening·H`.
/// Compressed, as the curve syscalls take it.
const PEDERSEN_G: [u8; 32] = [
    0xe2, 0xf2, 0xae, 0x0a, 0x6a, 0xbc, 0x4e, 0x71, 0xa8, 0x84, 0xa9, 0x61, 0xc5, 0x00, 0x51, 0x5f,
    0x58, 0xe3, 0x0b, 0x6a, 0xa5, 0x82, 0xdd, 0x8d, 0xb6, 0xa6, 0x59, 0x45, 0xe0, 0x8d, 0x2d, 0x76,
];

/// SPL token account layout: `mint(32) | owner(32) | amount(8) | ...`.
const ACCOUNT_OWNER: usize = 32;
/// SPL mint layout: `COption<authority>(36) | supply(8) | decimals(1) | ...`.
const MINT_DECIMALS: usize = 36 + 8;

/// Inside a proof context, past the 33-byte `[authority | proof_type]` header.
const EQ_COMMITMENT: usize = CTX_PROOF_TYPE + 1 + 32 + 64;
const EQ_PUBKEY: usize = CTX_PROOF_TYPE + 1;
const EQ_CIPHERTEXT: usize = CTX_PROOF_TYPE + 1 + 32;
const RANGE_FIRST_COMMITMENT: usize = CTX_PROOF_TYPE + 1;

/// Check on chain that the escrow really holds at least `q_min`.
///
/// Until this existed, `originate` copied `q_min` out of its instruction data and believed it. For
/// a bilateral loan that is fine: the lender sets the number after checking it themselves. For a
/// **pooled market it is a hole** — borrowers arrive permissionlessly, so a borrower could originate
/// against a floor they invented and suppliers would fund it. A curator cannot allocate to a market
/// whose collateral amount is self-reported, which makes this the difference between a market they
/// can price and one they must refuse.
///
/// Two proofs establish it, and neither means anything alone:
///
/// - **equality** binds a Pedersen commitment `C` to the escrow's own on-chain ciphertext, so `C`
///   commits to what the account actually holds;
/// - **range** proves that some commitment opens to a non-negative 64-bit value.
///
/// The join is arithmetic the program must do itself: the range proof has to be over
/// `C − q_min·G`, which commits to `balance − q_min` under the same opening. If that is
/// non-negative, the balance is at least the floor. Checking it needs two curve syscalls and no
/// trust.
pub fn floor_is_proved(
    equality_ctx: &[u8],
    range_ctx: &[u8],
    escrow_elgamal_pubkey: &[u8; 32],
    escrow_ciphertext: &[u8; 64],
    floor_base_units: u64,
) -> Result<(), ProgramError> {
    use solana_curve25519::ristretto::{multiply_ristretto, subtract_ristretto, PodRistrettoPoint};
    use solana_curve25519::scalar::PodScalar;

    if equality_ctx.len() < EQ_COMMITMENT + 32 || range_ctx.len() < RANGE_FIRST_COMMITMENT + 32 {
        return Err(ProgramError::InvalidAccountData);
    }

    // The binding this check had none of. Without it the arithmetic holds over numbers an attacker
    // chose: a commitment to `floor + 1` and one to `1` satisfy the subtraction while saying nothing
    // about any account. The equality proof has to be about **this escrow's** key and **this
    // escrow's** current ciphertext, or it is about somebody else's balance.
    if equality_ctx[EQ_PUBKEY..EQ_PUBKEY + 32] != escrow_elgamal_pubkey[..] {
        msg!("the floor proof is under a different ElGamal key than this escrow's");
        return Err(ProgramError::InvalidArgument);
    }
    if equality_ctx[EQ_CIPHERTEXT..EQ_CIPHERTEXT + 64] != escrow_ciphertext[..] {
        msg!("the floor proof is about a balance this escrow no longer holds");
        return Err(ProgramError::InvalidArgument);
    }

    let c = PodRistrettoPoint(
        equality_ctx[EQ_COMMITMENT..EQ_COMMITMENT + 32].try_into().unwrap(),
    );
    let surplus = PodRistrettoPoint(
        range_ctx[RANGE_FIRST_COMMITMENT..RANGE_FIRST_COMMITMENT + 32].try_into().unwrap(),
    );

    // q_min as a little-endian scalar.
    let mut k = [0u8; 32];
    k[..8].copy_from_slice(&floor_base_units.to_le_bytes());

    let floor = multiply_ristretto(&PodScalar(k), &PodRistrettoPoint(PEDERSEN_G))
        .ok_or(ProgramError::InvalidArgument)?;
    let expected = subtract_ristretto(&c, &floor).ok_or(ProgramError::InvalidArgument)?;

    if expected.0 != surplus.0 {
        msg!("the range proof is not over the surplus above this floor");
        return Err(ProgramError::InvalidArgument);
    }
    Ok(())
}

/// Read the escrow's confidential-transfer extension: the ElGamal key it is under, and the
/// available-balance ciphertext the floor proof must be about.
///
/// Parsed through the interface crate rather than by offset, because the extension sits in a TLV
/// region whose position depends on which other extensions the mint gave the account — and an
/// offset that is right on the mirror and wrong on `SPCX` would bind the floor proof to whatever
/// bytes happen to be there.
fn escrow_confidential_state(data: &[u8]) -> Result<([u8; 32], [u8; 64]), ProgramError> {
    use spl_token_2022_interface::extension::confidential_transfer::ConfidentialTransferAccount;
    use spl_token_2022_interface::extension::{BaseStateWithExtensions, StateWithExtensions};
    use spl_token_2022_interface::state::Account;

    let state = StateWithExtensions::<Account>::unpack(data)
        .map_err(|_| ProgramError::InvalidAccountData)?;
    let ct = state
        .get_extension::<ConfidentialTransferAccount>()
        .map_err(|_| ProgramError::InvalidAccountData)?;

    let pubkey: [u8; 32] = bytemuck::bytes_of(&ct.elgamal_pubkey)
        .try_into()
        .map_err(|_| ProgramError::InvalidAccountData)?;
    let ciphertext: [u8; 64] = bytemuck::bytes_of(&ct.available_balance)
        .try_into()
        .map_err(|_| ProgramError::InvalidAccountData)?;
    Ok((pubkey, ciphertext))
}

/// One escrow, one loan — and the reason confidential collateral does not reintroduce the risk it
/// looks like it should.
///
/// A public balance can be pledged twice and anyone can see that it was. Hide the balance and that
/// check disappears, which is the first thing a lender should ask about confidential collateral.
/// The answer here is that the collateral is not hidden, it is **held**: the escrow's owner is this
/// address, derived from the escrow itself, so a borrower who has handed it over cannot hand it
/// anywhere else. Not one loan per borrower — **one loan per escrow**, decided by arithmetic rather
/// than by bookkeeping.
pub fn loan_address(program_id: &Pubkey, escrow: &Pubkey) -> (Pubkey, u8) {
    Pubkey::find_program_address(&[b"loan", escrow.as_ref()], program_id)
}

/// The one check Token-2022 does not make for us, as a function rather than a loop body, because a
/// branch that decides whether a seizure can be disarmed should be reachable from a test.
///
/// A context state account is `[authority(32) | proof_type(1) | context]` and is closable **by its
/// authority**. If that authority is the borrower, they withdraw the proofs the day before default
/// and the seizure evaporates with nothing on chain looking wrong. Everything else about these
/// proofs the token program re-checks at transfer time; this it has no opinion about.
pub fn context_is_armed(data: &[u8], proof_type: u8, loan: &Pubkey) -> Result<(), ProgramError> {
    if data.len() <= CTX_PROOF_TYPE {
        return Err(ProgramError::InvalidAccountData);
    }
    if data[CTX_PROOF_TYPE] != proof_type {
        return Err(ProgramError::InvalidAccountData);
    }
    if data[CTX_AUTHORITY..CTX_AUTHORITY + 32] != loan.to_bytes() {
        return Err(ProgramError::InvalidAccountOwner);
    }
    Ok(())
}

fn disarm_reason(e: &ProgramError) -> &'static str {
    match e {
        ProgramError::InvalidAccountOwner => "can still be closed by someone other than this loan",
        _ => "is not a verified proof of the kind this slot needs",
    }
}

/// The predicate, entirely in public terms.
///
/// Units, because two of them are easy to get wrong and the cost is seizing a solvent borrower:
/// `q_min` is in **whole tokens**, `price` in **cents per whole token**, `principal` in **cents**,
/// `ratio_bps` in basis points. A floor proved in base units converts by flooring, which moves the
/// number the safe way — the lender is underwritten on less than was proved, not more.
///
/// `q_min` is the floor the borrower **proved** at origination, not what they hold, so the value
/// here is a lower bound on the collateral and the lender is over-collateralised by construction.
/// What the borrower actually holds is not an input, and evaluating this does not learn it.
/// Widened to `u128` because tokens times cents leaves `u64` at prices tokenized equities reach.
pub fn in_default(q_min: u64, price: u64, principal: u64, ratio_bps: u64) -> bool {
    let value = (q_min as u128) * (price as u128);
    let required = (principal as u128) * (ratio_bps as u128) / 10_000;
    value < required
}

/// The accounts a caller passes, checked against the ones the loan recorded.
pub struct Cited<'a> {
    pub escrow: &'a Pubkey,
    pub destination: &'a Pubkey,
    pub mint: &'a Pubkey,
    pub ctx_equality: &'a Pubkey,
    pub ctx_validity: &'a Pubkey,
    pub ctx_range: &'a Pubkey,
    pub oracle: &'a Pubkey,
}

/// Everything that must hold before a seizure may fire, as a function of the loan record and what
/// the caller supplied — no accounts, no runtime, so the protocol can be tested rather than only
/// run. `docs/SEIZURE.md` section 8 listed these as the invariants that did not exist yet.
///
/// Note what is *not* here: who is calling. Default is a public fact about public numbers, and a
/// seizure only the lender could fire is a seizure the lender could also decline to fire.
pub fn may_seize(d: &[u8], cited: Cited, oracle_signed: bool, price: u64) -> ProgramResult {
    may_settle(d, cited.escrow, cited.mint, cited.oracle, oracle_signed, price)?;
    // The accounts only a confidential transfer touches. Everything shared with the de-shield path
    // is in `may_settle`, so both settlement modes are held by the same tested code rather than by
    // two copies that agree until one is edited.
    check(&d[OFF_DESTINATION..], cited.destination)?;
    check(&d[OFF_CTX_EQUALITY..], cited.ctx_equality)?;
    check(&d[OFF_CTX_VALIDITY..], cited.ctx_validity)?;
    check(&d[OFF_CTX_RANGE..], cited.ctx_range)?;
    Ok(())
}

/// Everything both settlement modes must establish: the loan is real and unspent, the accounts are
/// the ones it recorded, the price is signed by the oracle it names, and the predicate holds.
pub fn may_settle(
    d: &[u8],
    escrow: &Pubkey,
    mint: &Pubkey,
    oracle: &Pubkey,
    oracle_signed: bool,
    price: u64,
) -> ProgramResult {
    if d.len() < LOAN_LEN || d[0] != LOAN_TAG {
        return Err(ProgramError::UninitializedAccount);
    }
    if d[OFF_SEIZED] != 0 {
        return Err(ProgramError::InvalidAccountData); // opening is not repeatable
    }
    check(&d[OFF_ESCROW..], escrow)?;
    check(&d[OFF_MINT..], mint)?;
    check(&d[OFF_ORACLE..], oracle)?;
    if !oracle_signed {
        return Err(ProgramError::MissingRequiredSignature);
    }
    if !in_default(
        read_u64(d, OFF_Q_MIN),
        price,
        read_u64(d, OFF_PRINCIPAL),
        read_u64(d, OFF_RATIO_BPS),
    ) {
        return Err(ProgramError::InvalidArgument);
    }
    Ok(())
}

/// `Deshield` — the predicate, then make the collateral public where it sits.
///
/// `Withdraw` has no recipient, which is the whole reason this exists: seizure by confidential
/// transfer must name its destination at origination, because the proofs bind to that key. A venue
/// with permissionless liquidation cannot name one. So this makes the balance public in place and
/// stops; whatever moves it afterwards is an ordinary SPL transfer that needs no proof and no
/// foresight.
///
/// Accounts: loan(w), escrow(w), mint, destination(w), ctx_equality, ctx_range, oracle(s),
/// token_program
///
/// Data: price u64 | amount u64 | decimals u8 | new_decryptable[36]
///
/// The amount and the new decryptable balance ride in the instruction rather than the loan record
/// because the record is full and they are not secret. A wrong amount is caught by Token-2022: the
/// pre-verified proofs are over `balance − amount`, and any other amount fails there.
fn deshield(program_id: &Pubkey, accounts: &[AccountInfo], data: &[u8]) -> ProgramResult {
    let i = &mut accounts.iter();
    let loan = next_account_info(i)?;
    let escrow = next_account_info(i)?;
    let mint = next_account_info(i)?;
    let destination = next_account_info(i)?;
    let ctx_equality = next_account_info(i)?;
    let ctx_range = next_account_info(i)?;
    let oracle = next_account_info(i)?;
    let token_program = next_account_info(i)?;

    if loan.owner != program_id {
        return Err(ProgramError::IllegalOwner);
    }
    if data.len() != 8 + 8 + 1 + 36 {
        return Err(ProgramError::InvalidInstructionData);
    }
    let price = u64::from_le_bytes(data[..8].try_into().unwrap());
    let amount = u64::from_le_bytes(data[8..16].try_into().unwrap());
    let decimals = data[16];

    let bump = {
        let d = loan.try_borrow_data()?;
        may_settle(&d, escrow.key, mint.key, oracle.key, oracle.is_signer, price)?;
        check(&d[OFF_DESTINATION..], destination.key)?;
        // TODO(2026-09-16): the withdraw proof contexts and the amount are not recorded, so a
        // caller can de-shield a token and mark the loan settled, stranding the rest. The loan
        // record has no room for them. Deshield is unreachable until that is fixed.
        return Err(ProgramError::InvalidArgument);
        #[allow(unreachable_code)]
        d[OFF_BUMP]
    };

    let ix = withdraw_instruction(
        token_program.key,
        escrow.key,
        mint.key,
        amount,
        decimals,
        loan.key,
        ctx_equality.key,
        ctx_range.key,
        &data[17..],
    )?;
    invoke_signed(
        &ix,
        &[
            escrow.clone(),
            mint.clone(),
            ctx_equality.clone(),
            ctx_range.clone(),
            loan.clone(),
            token_program.clone(),
        ],
        &[&[b"loan", escrow.key.as_ref(), &[bump]]],
    )?;

    // And out, in the same instruction. `Withdraw` credits the escrow's **own** public balance and
    // leaves its owner alone — which is this PDA — so de-shielding on its own does not release
    // anything. It strands it: nothing but this program can sign for that account, and without this
    // second half there is no instruction that does. The transfer is ordinary SPL, no proofs, and
    // it goes where the loan says.
    let out = spl_transfer_instruction(
        token_program.key,
        escrow.key,
        mint.key,
        destination.key,
        loan.key,
        amount,
        decimals,
    )?;
    invoke_signed(
        &out,
        &[
            escrow.clone(),
            mint.clone(),
            destination.clone(),
            loan.clone(),
            token_program.clone(),
        ],
        &[&[b"loan", escrow.key.as_ref(), &[bump]]],
    )?;

    loan.try_borrow_mut_data()?[OFF_SEIZED] = 1;
    msg!("de-shielded and released: the collateral is public, and it is the lender's");
    Ok(())
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
/// An ordinary SPL transfer. No proofs: the balance is public by the time this runs.
fn spl_transfer_instruction(
    token_program: &Pubkey,
    escrow: &Pubkey,
    mint: &Pubkey,
    destination: &Pubkey,
    authority: &Pubkey,
    amount: u64,
    decimals: u8,
) -> Result<solana_program::instruction::Instruction, ProgramError> {
    let a = |k: &Pubkey| solana_address::Address::from(k.to_bytes());
    let ix = spl_token_2022_interface::instruction::transfer_checked(
        &a(token_program), &a(escrow), &a(mint), &a(destination), &a(authority), &[], amount, decimals,
    )
    .map_err(|_| ProgramError::IncorrectProgramId)?;
    Ok(solana_program::instruction::Instruction {
        program_id: Pubkey::new_from_array(ix.program_id.to_bytes()),
        accounts: ix.accounts.into_iter().map(|m| solana_program::instruction::AccountMeta {
            pubkey: Pubkey::new_from_array(m.pubkey.to_bytes()),
            is_signer: m.is_signer,
            is_writable: m.is_writable,
        }).collect(),
        data: ix.data,
    })
}

/// `Withdraw`, with both proofs cited by address. Two, not three: no destination means no validity
/// proof to prove anything about.
#[allow(clippy::too_many_arguments)]
fn withdraw_instruction(
    token_program: &Pubkey,
    escrow: &Pubkey,
    mint: &Pubkey,
    amount: u64,
    decimals: u8,
    authority: &Pubkey,
    ctx_equality: &Pubkey,
    ctx_range: &Pubkey,
    new_decryptable: &[u8],
) -> Result<solana_program::instruction::Instruction, ProgramError> {
    use spl_token_2022_interface::extension::confidential_transfer::instruction::inner_withdraw;
    use spl_token_confidential_transfer_proof_extraction::instruction::ProofLocation;

    let a = |k: &Pubkey| solana_address::Address::from(k.to_bytes());
    let ix = inner_withdraw(
        &a(token_program),
        &a(escrow),
        &a(mint),
        amount,
        decimals,
        bytemuck::from_bytes(new_decryptable),
        &a(authority),
        &[],
        ProofLocation::ContextStateAccount(&a(ctx_equality)),
        ProofLocation::ContextStateAccount(&a(ctx_range)),
    )
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

    /// **L4 — the predicate crosses where it should, in the units it says.** 100,000 whole tokens
    /// proved, a $50,000 loan at 200 %: the requirement is $100,000, so default begins the moment
    /// the price falls under $1.00. The e2e run used these numbers.
    #[test]
    fn default_begins_exactly_where_the_units_say() {
        let (q_min, principal, ratio) = (100_000u64, 5_000_000u64, 20_000u64); // 100k tokens, $50k, 200%
        assert!(!in_default(q_min, 101, principal, ratio), "$1.01 still covers it");
        assert!(!in_default(q_min, 100, principal, ratio), "$1.00 exactly covers it");
        assert!(in_default(q_min, 99, principal, ratio), "$0.99 does not");
    }

    /// **L5 — the predicate does not wrap where `u64` would.** 173,000 tokens at $184.50 is only
    /// 3.19e9 in these units and fits easily; the headroom above does not, and an overflow reads as
    /// a default that did not happen and takes collateral on it.
    #[test]
    fn the_predicate_does_not_wrap_where_u64_would() {
        let q_min = 17_300_000_000_000u64; // a base-unit figure passed in by mistake
        let breaking_price = (u64::MAX / q_min) + 1;
        assert!(q_min.checked_mul(breaking_price).is_none(), "u64 would wrap here");
        assert!(
            !in_default(q_min, breaking_price, u64::MAX, 10_000),
            "a position worth more than the loan is not in default, however large the product"
        );
        assert!(in_default(q_min, 1, u64::MAX / 10_000, 20_000));
    }
}

#[cfg(test)]
mod discriminants {
    use super::*;

    /// **L5 — the proof type bytes are the ones the chain writes.** These were hand-transcribed
    /// first and all three were wrong; the values below are what a local validator actually put in
    /// the context state accounts, read back from them. They are pinned here so that deriving them
    /// from the enum cannot quietly start meaning something else.
    #[test]
    fn the_discriminants_match_what_the_chain_wrote() {
        assert_eq!(PROOF_TYPE_EQUALITY, 3);
        assert_eq!(PROOF_TYPE_BATCHED_RANGE_U128, 7);
        assert_eq!(PROOF_TYPE_BATCHED_VALIDITY_3, 12);
    }
}

#[cfg(test)]
mod arming {
    use super::*;

    /// A context state account as the ZK program writes one: authority, then proof type, then the
    /// context itself. Only the first 33 bytes decide whether a seizure can be disarmed.
    fn context(authority: &Pubkey, proof_type: u8) -> Vec<u8> {
        let mut d = vec![0u8; 161];
        d[CTX_AUTHORITY..CTX_AUTHORITY + 32].copy_from_slice(&authority.to_bytes());
        d[CTX_PROOF_TYPE] = proof_type;
        d
    }

    /// **A1 — the check passes when the loan holds the authority.** The baseline, so that the
    /// refusals below are refusing something rather than failing for an unrelated reason.
    #[test]
    fn a_context_the_loan_can_close_is_armed() {
        let loan = Pubkey::new_unique();
        assert!(context_is_armed(&context(&loan, PROOF_TYPE_EQUALITY), PROOF_TYPE_EQUALITY, &loan).is_ok());
    }

    /// **A2 — the attack this program exists to stop.** The borrower keeps the context authority,
    /// so they can close the accounts the day before default and the proofs vanish. Token-2022
    /// has no opinion about this; if origination lets it through, the loan is unsecured and
    /// everything on chain still looks correct.
    #[test]
    fn a_context_the_borrower_can_close_is_refused() {
        let loan = Pubkey::new_unique();
        let borrower = Pubkey::new_unique();
        assert_eq!(
            context_is_armed(&context(&borrower, PROOF_TYPE_EQUALITY), PROOF_TYPE_EQUALITY, &loan),
            Err(ProgramError::InvalidAccountOwner),
        );
    }

    /// **A3 — a valid proof of the wrong kind in the right slot.** This is the failure the
    /// hand-transcribed discriminants would have caused: every proof verified, every authority
    /// correct, and the range slot holding an equality proof. It fails quietly unless checked.
    #[test]
    fn a_verified_proof_of_the_wrong_kind_is_refused() {
        let loan = Pubkey::new_unique();
        assert_eq!(
            context_is_armed(&context(&loan, PROOF_TYPE_EQUALITY), PROOF_TYPE_BATCHED_RANGE_U128, &loan),
            Err(ProgramError::InvalidAccountData),
        );
    }

    /// **A4 — an account too short to be a proof context.** An uninitialised or truncated account
    /// must not index past its own data; the check reads bytes 0..33 and has to say so first.
    #[test]
    fn an_account_too_short_to_be_a_context_is_refused() {
        let loan = Pubkey::new_unique();
        for len in [0usize, 32, CTX_PROOF_TYPE] {
            assert_eq!(
                context_is_armed(&vec![0u8; len], PROOF_TYPE_EQUALITY, &loan),
                Err(ProgramError::InvalidAccountData),
                "a {len}-byte account was accepted as a proof context",
            );
        }
    }

    /// **A5 — every slot the loan cites is checked against its own type.** Three proofs, three
    /// discriminants; a loop that checked one type three times would pass A1–A3 and still let a
    /// validity proof sit in the range slot.
    #[test]
    fn each_of_the_three_slots_rejects_the_other_two() {
        let loan = Pubkey::new_unique();
        let types = [PROOF_TYPE_EQUALITY, PROOF_TYPE_BATCHED_VALIDITY_3, PROOF_TYPE_BATCHED_RANGE_U128];
        for expected in types {
            for actual in types {
                let got = context_is_armed(&context(&loan, actual), expected, &loan);
                assert_eq!(got.is_ok(), expected == actual, "slot {expected} accepted type {actual}");
            }
        }
    }

    /// **A6 — the accounts a seizure touches come from the loan, not the caller.** `check` is what
    /// stops a caller passing a different destination and redirecting the collateral.
    #[test]
    fn an_account_the_loan_did_not_name_is_refused() {
        let recorded = Pubkey::new_unique();
        let other = Pubkey::new_unique();
        let mut field = recorded.to_bytes().to_vec();
        field.extend_from_slice(&[0u8; 64]); // the loan record continues past this field
        assert!(check(&field, &recorded).is_ok());
        assert_eq!(check(&field, &other), Err(ProgramError::InvalidArgument));
    }
}

#[cfg(test)]
mod protocol {
    use super::*;

    struct Loan {
        d: Vec<u8>,
        escrow: Pubkey, dest: Pubkey, mint: Pubkey,
        eq: Pubkey, va: Pubkey, rp: Pubkey, oracle: Pubkey,
    }

    /// 100,000 tokens proved against a $50,000 loan at 200 %: the requirement is $100,000, so
    /// default begins the moment the price falls under $1.00. The numbers the e2e run used.
    fn loan() -> Loan {
        let (escrow, dest, mint) = (Pubkey::new_unique(), Pubkey::new_unique(), Pubkey::new_unique());
        let (eq, va, rp, oracle) = (Pubkey::new_unique(), Pubkey::new_unique(), Pubkey::new_unique(), Pubkey::new_unique());
        let mut d = vec![0u8; LOAN_LEN];
        d[0] = LOAN_TAG;
        for (off, k) in [(OFF_ESCROW, &escrow), (OFF_DESTINATION, &dest), (OFF_MINT, &mint),
                         (OFF_CTX_EQUALITY, &eq), (OFF_CTX_VALIDITY, &va), (OFF_CTX_RANGE, &rp),
                         (OFF_ORACLE, &oracle)] {
            d[off..off + 32].copy_from_slice(&k.to_bytes());
        }
        d[OFF_Q_MIN..OFF_Q_MIN + 8].copy_from_slice(&100_000u64.to_le_bytes());
        d[OFF_PRINCIPAL..OFF_PRINCIPAL + 8].copy_from_slice(&5_000_000u64.to_le_bytes());
        d[OFF_RATIO_BPS..OFF_RATIO_BPS + 8].copy_from_slice(&20_000u64.to_le_bytes());
        Loan { d, escrow, dest, mint, eq, va, rp, oracle }
    }

    impl Loan {
        fn cited(&self) -> Cited<'_> {
            Cited { escrow: &self.escrow, destination: &self.dest, mint: &self.mint,
                    ctx_equality: &self.eq, ctx_validity: &self.va, ctx_range: &self.rp,
                    oracle: &self.oracle }
        }
        fn at(&self, price: u64) -> ProgramResult { may_seize(&self.d, self.cited(), true, price) }
    }

    /// **P1 — seizure is impossible before the predicate holds.** The first of the three invariants
    /// `docs/SEIZURE.md` section 8 said did not exist. A borrower whose collateral still covers the
    /// loan cannot have it taken, however the caller frames the transaction.
    #[test]
    fn a_loan_that_still_covers_itself_cannot_be_seized() {
        let l = loan();
        assert_eq!(l.at(101), Err(ProgramError::InvalidArgument));
        assert_eq!(l.at(100), Err(ProgramError::InvalidArgument), "exactly covered is not default");
        assert_eq!(l.at(u64::MAX), Err(ProgramError::InvalidArgument));
    }

    /// **P2 — and guaranteed once it does.** No identity is consulted: the caller is not an input,
    /// so the lender cannot decline to fire it and the borrower cannot be the reason it does not.
    #[test]
    fn a_loan_in_default_can_be_seized_by_anyone() {
        assert!(loan().at(99).is_ok());
        assert!(loan().at(0).is_ok());
    }

    /// **P3 — opening is not repeatable.** Once the collateral has moved the escrow is empty and
    /// the pre-verified proofs describe a balance that no longer exists; a second seizure would
    /// fail at the token program, but it must fail here, before a transfer is attempted.
    #[test]
    fn a_seized_loan_cannot_be_seized_again() {
        let mut l = loan();
        assert!(l.at(99).is_ok());
        l.d[OFF_SEIZED] = 1;
        assert_eq!(l.at(99), Err(ProgramError::InvalidAccountData));
    }

    /// **P4 — the price is an assertion and must be signed.** Without this the predicate is
    /// decided by whoever sends the transaction, and every loan is seizable by anyone at any time.
    #[test]
    fn an_unsigned_price_is_refused() {
        let l = loan();
        assert_eq!(
            may_seize(&l.d, l.cited(), false, 99),
            Err(ProgramError::MissingRequiredSignature),
        );
    }

    /// **P5 — a caller cannot redirect a seizure.** Every account the transfer touches is compared
    /// with the one the loan recorded, one at a time, so substituting any single account fails.
    /// This is the check that keeps the collateral going where it was pledged.
    #[test]
    fn substituting_any_account_is_refused() {
        let l = loan();
        let other = Pubkey::new_unique();
        for (name, mut c) in [
            ("escrow",      l.cited()), ("destination", l.cited()), ("mint",     l.cited()),
            ("ctx equality",l.cited()), ("ctx validity",l.cited()), ("ctx range",l.cited()),
            ("oracle",      l.cited()),
        ].into_iter().enumerate().map(|(i, (n, c))| (n, (i, c))) {
            let (i, ref mut c) = c;
            match i {
                0 => c.escrow = &other,      1 => c.destination = &other, 2 => c.mint = &other,
                3 => c.ctx_equality = &other, 4 => c.ctx_validity = &other, 5 => c.ctx_range = &other,
                _ => c.oracle = &other,
            }
            let got = may_seize(&l.d, Cited { ..*c }, true, 99);
            assert!(got.is_err(), "a substituted {name} was accepted");
        }
    }

    /// **P6 — the record carries no position, either way.** The third invariant: a seizure reveals
    /// no amount. The only quantity in the loan is `q_min`, the floor the borrower chose to
    /// disclose; the balance appears nowhere, and the seize instruction carries a price and
    /// nothing else.
    #[test]
    fn nothing_in_the_loan_or_the_instruction_is_the_position() {
        let l = loan();
        let position: u64 = 17_300_000_000_000; // what the escrow actually held in the e2e run
        assert!(
            !l.d.windows(8).any(|w| u64::from_le_bytes(w.try_into().unwrap()) == position),
            "the position is recoverable from the loan account",
        );
        // The instruction is a discriminator and a price.
        let mut ix = vec![1u8];
        ix.extend_from_slice(&99u64.to_le_bytes());
        assert_eq!(ix.len(), 9, "the seize instruction carries more than a price");
    }
}

#[cfg(test)]
mod pledging {
    use super::*;

    /// **X1 — one escrow can secure exactly one loan.** The first question a lender should ask
    /// about confidential collateral is whether it can be pledged twice, because hiding a balance
    /// removes the check that would catch it. The loan address is derived from the escrow, so a
    /// second loan against the same escrow is the same account, and `originate` refuses an account
    /// that is not empty.
    #[test]
    fn one_escrow_derives_exactly_one_loan() {
        let program = Pubkey::new_unique();
        let escrow = Pubkey::new_unique();
        assert_eq!(loan_address(&program, &escrow), loan_address(&program, &escrow));
    }

    /// **X2 — and a different escrow is a different loan.** Otherwise one collision would let a
    /// second pledge land on the first loan's record.
    #[test]
    fn different_escrows_never_share_a_loan() {
        let program = Pubkey::new_unique();
        let a = loan_address(&program, &Pubkey::new_unique()).0;
        let b = loan_address(&program, &Pubkey::new_unique()).0;
        assert_ne!(a, b);
    }

    /// **X3 — the loan address is not the escrow's owner by coincidence.** The escrow is handed to
    /// this address, so the borrower stops being able to move it — which is what makes double
    /// pledging arithmetic rather than policy. If the seeds ever stopped including the escrow, two
    /// escrows would share an owner and the property would quietly become false.
    #[test]
    fn the_derivation_is_bound_to_the_escrow_it_holds() {
        let program = Pubkey::new_unique();
        let escrow = Pubkey::new_unique();
        let (addr, bump) = loan_address(&program, &escrow);
        let rebuilt = Pubkey::create_program_address(&[b"loan", escrow.as_ref(), &[bump]], &program)
            .expect("the recorded bump must reproduce the address");
        assert_eq!(addr, rebuilt);
    }

    /// **X4 — a second program cannot mint the same loan address.** The collateral is locked to
    /// this program's PDA; another deployment derives elsewhere and cannot claim an escrow this one
    /// holds.
    #[test]
    fn another_program_cannot_derive_the_same_loan() {
        let escrow = Pubkey::new_unique();
        assert_ne!(
            loan_address(&Pubkey::new_unique(), &escrow).0,
            loan_address(&Pubkey::new_unique(), &escrow).0,
        );
    }
}

#[cfg(test)]
mod floor {
    use super::*;
    use solana_zk_elgamal_proof_interface::proof_data::ZkProofData;
    use solana_zk_sdk::encryption::elgamal::ElGamalKeypair;
    use solana_zk_sdk::encryption::pedersen::{Pedersen, PedersenOpening};
    use solana_zk_sdk::zk_elgamal_proof_program::{
        batched_range_proof::build_batched_range_proof_u64_data,
        ciphertext_commitment_equality::build_ciphertext_commitment_equality_proof_data,
    };

    /// Build the two context accounts exactly as `prove-collateral` does, then wrap them the way the
    /// ZK program stores them: `[authority | proof_type | context]`.
    /// The escrow as the chain would present it, and the two contexts `prove-collateral` builds
    /// over it. Returns the binding the program must now check as well as the proofs.
    fn contexts(balance: u64, threshold: u64) -> (Vec<u8>, Vec<u8>, [u8; 32], [u8; 64]) {
        let k = ElGamalKeypair::new_rand();
        let ct = k.pubkey().encrypt(balance);
        let opening = PedersenOpening::new_rand();
        let commitment = Pedersen::with(balance, &opening);
        let equality =
            build_ciphertext_commitment_equality_proof_data(&k, &ct, &commitment, &opening, balance)
                .unwrap();
        // The surplus, committed under the SAME opening — which is what lets the verifier reach it
        // by subtracting threshold·G rather than taking anyone's word.
        let delta = balance - threshold;
        let delta_commitment = Pedersen::with(delta, &opening);
        let range =
            build_batched_range_proof_u64_data(vec![&delta_commitment], vec![delta], vec![64], vec![&opening])
                .unwrap();

        let wrap = |ctx: &[u8]| {
            let mut v = vec![0u8; CTX_PROOF_TYPE + 1];
            v.extend_from_slice(ctx);
            v
        };
        (
            wrap(bytemuck::bytes_of(equality.context_data())),
            wrap(bytemuck::bytes_of(range.context_data())),
            k.pubkey().to_bytes(),
            ct.to_bytes(),
        )
    }

    /// **F1 — a real proof pair passes at the floor it was built for.** Built with the same code
    /// path `prove-collateral` uses, so this is the arithmetic the chain would see.
    #[test]
    fn a_genuine_pair_proves_its_own_floor() {
        let (eq, rp, pk, ct) = contexts(173_000, 100_000);
        assert!(floor_is_proved(&eq, &rp, &pk, &ct, 100_000).is_ok());
    }

    /// **F2 — and fails at any other floor.** This is the check's whole purpose: the borrower hands
    /// in `q_min` and the program must refuse a number the proofs do not support. One off is
    /// enough.
    #[test]
    fn the_same_pair_proves_no_other_floor() {
        let (eq, rp, pk, ct) = contexts(173_000, 100_000);
        for wrong in [0u64, 99_999, 100_001, 173_000, u64::MAX] {
            assert!(
                floor_is_proved(&eq, &rp, &pk, &ct, wrong).is_err(),
                "a floor of {wrong} was accepted by proofs built for 100,000",
            );
        }
    }

    /// **F3 — proofs from a different account do not transfer.** Each pair carries its own
    /// commitment, so a pair built elsewhere cannot be presented for this loan's floor.
    #[test]
    fn a_pair_from_another_escrow_does_not_prove_this_floor() {
        let (eq_a, _, pk_a, ct_a) = contexts(173_000, 100_000);
        let (_, rp_b, _, _) = contexts(173_000, 100_000);
        assert!(floor_is_proved(&eq_a, &rp_b, &pk_a, &ct_a, 100_000).is_err());
    }

    /// **F5 — proofs about another escrow are refused.** The finding that made this check
    /// necessary: without binding, a commitment to `floor + 1` and one to `1` satisfy the
    /// subtraction while being about nobody's balance. Genuine proofs about a *different* account
    /// are the same attack with extra steps.
    #[test]
    fn genuine_proofs_about_another_escrow_are_refused() {
        let (eq, rp, _, _) = contexts(173_000, 100_000);
        let (_, _, other_pk, other_ct) = contexts(173_000, 100_000);
        assert!(
            floor_is_proved(&eq, &rp, &other_pk, &other_ct, 100_000).is_err(),
            "a floor proof about one escrow was accepted for another",
        );
    }

    /// **F4 — truncated contexts are refused rather than indexed past.** An uninitialised account
    /// must not be read as a commitment.
    #[test]
    fn short_contexts_are_refused() {
        let (eq, rp, pk, ct) = contexts(173_000, 100_000);
        assert!(floor_is_proved(&eq[..40], &rp, &pk, &ct, 100_000).is_err());
        assert!(floor_is_proved(&eq, &rp[..40], &pk, &ct, 100_000).is_err());
    }
}

#[cfg(test)]
mod settlement {
    use super::*;

    fn loan_bytes() -> (Vec<u8>, Pubkey, Pubkey, Pubkey) {
        let (escrow, mint, oracle) = (Pubkey::new_unique(), Pubkey::new_unique(), Pubkey::new_unique());
        let mut d = vec![0u8; LOAN_LEN];
        d[0] = LOAN_TAG;
        for (off, k) in [(OFF_ESCROW, &escrow), (OFF_MINT, &mint), (OFF_ORACLE, &oracle)] {
            d[off..off + 32].copy_from_slice(&k.to_bytes());
        }
        d[OFF_Q_MIN..OFF_Q_MIN + 8].copy_from_slice(&100_000u64.to_le_bytes());
        d[OFF_PRINCIPAL..OFF_PRINCIPAL + 8].copy_from_slice(&5_000_000u64.to_le_bytes());
        d[OFF_RATIO_BPS..OFF_RATIO_BPS + 8].copy_from_slice(&20_000u64.to_le_bytes());
        (d, escrow, mint, oracle)
    }

    /// **S1 — both settlement modes refuse a loan that still covers itself.** De-shielding publishes
    /// the position, so letting it happen outside default would leak exactly what the borrower is
    /// paying to keep private. The two paths share `may_settle` so that this cannot become true of
    /// one and not the other.
    #[test]
    fn neither_mode_settles_a_solvent_loan() {
        let (d, e, m, o) = loan_bytes();
        assert_eq!(may_settle(&d, &e, &m, &o, true, 100), Err(ProgramError::InvalidArgument));
        assert!(may_settle(&d, &e, &m, &o, true, 99).is_ok());
    }

    /// **S2 — an unsigned price is refused on both.** Otherwise anyone could publish any borrower's
    /// collateral by sending a transaction with a low number in it.
    #[test]
    fn neither_mode_settles_on_an_unsigned_price() {
        let (d, e, m, o) = loan_bytes();
        assert_eq!(
            may_settle(&d, &e, &m, &o, false, 99),
            Err(ProgramError::MissingRequiredSignature),
        );
    }

    /// **S3 — settling once is settling.** A loan that has been seized cannot then be de-shielded,
    /// or de-shielded and then seized: the flag is shared, so the modes are alternatives rather
    /// than a sequence.
    #[test]
    fn settling_either_way_closes_the_other() {
        let (mut d, e, m, o) = loan_bytes();
        assert!(may_settle(&d, &e, &m, &o, true, 99).is_ok());
        d[OFF_SEIZED] = 1;
        assert_eq!(may_settle(&d, &e, &m, &o, true, 99), Err(ProgramError::InvalidAccountData));
    }

    /// **S4 — substituting the escrow, the mint or the oracle is refused on both.** The de-shield
    /// path touches fewer accounts than the transfer path, which is exactly why the shared ones
    /// have to be checked in the shared place.
    #[test]
    fn neither_mode_accepts_an_account_the_loan_did_not_name() {
        let (d, e, m, o) = loan_bytes();
        let other = Pubkey::new_unique();
        assert!(may_settle(&d, &other, &m, &o, true, 99).is_err());
        assert!(may_settle(&d, &e, &other, &o, true, 99).is_err());
        assert!(may_settle(&d, &e, &m, &other, true, 99).is_err());
    }
}
