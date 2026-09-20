//! `seizure-client <subcommand> ...` — the client half of `confide-seizure`.
//!
//! Four things the borrower and the seizer need that no CLI has:
//!
//!   `pda <program> <escrow>`            the loan account's address, seeds = [b"loan", escrow]
//!   `approve <authority> <acct> <mint> <bh>`  the issuer approving one account, because the mirror
//!                                       mint gates new accounts exactly as NVDAx does
//!   `handover <kp> <escrow> <pda> <bh>` SetAuthority(AccountOwner) — the borrower gives up the
//!                                       escrow. After this they cannot move it and the program
//!                                       can, and the ElGamal secret stops mattering because
//!                                       everything it was needed for is already built.
//!   `originate <kp> <program> <ctx.json> <escrow> <dest> <mint> <oracle> <q_min> <principal>
//!              <ratio_bps> <bh>`        record the loan; refuse if the proofs are still closable
//!   `seize <kp> <program> <ctx.json> <escrow> <dest> <mint> <oracle.json> <price> <bh>`
//!                                       the predicate, then the Transfer the borrower cannot stop

use base64::Engine;
use solana_address::Address;
use solana_hash::Hash;
use solana_instruction::{AccountMeta, Instruction};
use solana_keypair::Keypair;
use solana_message::Message;
use solana_signer::Signer;
use solana_transaction::Transaction;
use std::str::FromStr;

const TOKEN_2022: &str = "TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb";
const SYSTEM: &str = "11111111111111111111111111111111";

fn main() {
    let a: Vec<String> = std::env::args().skip(1).collect();
    match a[0].as_str() {
        "pda" => {
            let (loan, _) = loan_pda(&addr(&a[1]), &addr(&a[2]));
            println!("{loan}");
        }
        // The mirror mint carries `autoApproveNewAccounts: false`, the same as NVDAx, so a new
        // confidential account is inert until the issuer approves it. That is not a detour around
        // the design — it is the issuer being the gatekeeper this project says they are.
        "approve" => {
            let authority = keypair(&a[1]);
            let ix = spl_token_2022_interface::extension::confidential_transfer::instruction::approve_account(
                &addr(TOKEN_2022),
                &addr(&a[2]),
                &addr(&a[3]),
                &authority.pubkey(),
                &[],
            )
            .expect("approve_account");
            emit(&[ix], &authority, &[], &a[4]);
        }
        // Hand the approval role to another key. `ApproveAccount` is signed by the
        // confidential-transfer mint authority, which is a DIFFERENT authority from the one that
        // mints — so this separates "may let accounts in" from "may print tokens", and the
        // devnet testbed publishes the first while keeping the second.
        "set-ct-authority" => {
            let authority = keypair(&a[1]);
            let mint = addr(&a[2]);
            let new_authority = addr(&a[3]);
            let ix = spl_token_2022_interface::instruction::set_authority(
                &addr(TOKEN_2022),
                &mint,
                Some(&new_authority),
                spl_token_2022_interface::instruction::AuthorityType::ConfidentialTransferMint,
                &authority.pubkey(),
                &[],
            )
            .expect("set_authority");
            emit(&[ix], &authority, &[], &a[4]);
        }
        "handover" => {
            let owner = keypair(&a[1]);
            let escrow = addr(&a[2]);
            let new_owner = addr(&a[3]);
            let ix = spl_token_2022_interface::instruction::set_authority(
                &addr(TOKEN_2022),
                &escrow,
                Some(&new_owner),
                spl_token_2022_interface::instruction::AuthorityType::AccountOwner,
                &owner.pubkey(),
                &[],
            )
            .expect("set_authority");
            emit(&[ix], &owner, &[], &a[4]);
        }
        "originate" => {
            let payer = keypair(&a[1]);
            let program = addr(&a[2]);
            let ctx = artifact(&a[3]);
            let (escrow, dest, mint, oracle) = (addr(&a[4]), addr(&a[5]), addr(&a[6]), addr(&a[7]));
            let (loan, _) = loan_pda(&program, &escrow);

            let mut data = vec![0u8];
            for n in [&a[8], &a[9], &a[10]] {
                data.extend_from_slice(&n.parse::<u64>().expect("u64").to_le_bytes());
            }
            for k in ["new_decryptable_b64", "auditor_lo_b64", "auditor_hi_b64"] {
                data.extend_from_slice(&d64(ctx[k].as_str().unwrap()));
            }
            // Who may hand the collateral back. Recorded now, while both sides are present, because
            // the borrower arms the destination later and must not also choose the trigger.
            data.extend_from_slice(addr(&a[11]).as_ref());

            let ix = Instruction {
                program_id: program,
                accounts: vec![
                    AccountMeta::new(payer.pubkey(), true),
                    AccountMeta::new(loan, false),
                    AccountMeta::new_readonly(escrow, false),
                    AccountMeta::new_readonly(dest, false),
                    AccountMeta::new_readonly(mint, false),
                    AccountMeta::new_readonly(addr(ctx["equality"].as_str().unwrap()), false),
                    AccountMeta::new_readonly(addr(ctx["validity"].as_str().unwrap()), false),
                    AccountMeta::new_readonly(addr(ctx["range"].as_str().unwrap()), false),
                    AccountMeta::new_readonly(addr(ctx["floor_equality"].as_str().unwrap()), false),
                    AccountMeta::new_readonly(addr(ctx["floor_range"].as_str().unwrap()), false),
                    AccountMeta::new_readonly(oracle, false),
                    AccountMeta::new_readonly(addr(SYSTEM), false),
                ],
                data,
            };
            eprintln!("  loan account       {loan}");
            emit(&[ix], &payer, &[], &a[12]);
        }
        "seize" => {
            let payer = keypair(&a[1]);
            let program = addr(&a[2]);
            let ctx = artifact(&a[3]);
            let (escrow, dest, mint) = (addr(&a[4]), addr(&a[5]), addr(&a[6]));
            let oracle = keypair(&a[7]);
            let (loan, _) = loan_pda(&program, &escrow);

            let mut data = vec![1u8];
            data.extend_from_slice(&a[8].parse::<u64>().expect("price in cents").to_le_bytes());

            // Compute budget: the Transfer re-reads three proof contexts and rewrites two
            // confidential accounts. The default 200k is not enough and the failure reads as a
            // proof problem rather than a budget one.
            let cb = Instruction {
                program_id: addr("ComputeBudget111111111111111111111111111111"),
                accounts: vec![],
                data: {
                    let mut d = vec![0x02];
                    d.extend_from_slice(&700_000u32.to_le_bytes());
                    d
                },
            };
            let ix = Instruction {
                program_id: program,
                accounts: vec![
                    AccountMeta::new(loan, false),
                    AccountMeta::new(escrow, false),
                    AccountMeta::new_readonly(mint, false),
                    AccountMeta::new(dest, false),
                    AccountMeta::new_readonly(addr(ctx["equality"].as_str().unwrap()), false),
                    AccountMeta::new_readonly(addr(ctx["validity"].as_str().unwrap()), false),
                    AccountMeta::new_readonly(addr(ctx["range"].as_str().unwrap()), false),
                    AccountMeta::new_readonly(oracle.pubkey(), true),
                    AccountMeta::new_readonly(addr(TOKEN_2022), false),
                ],
                data,
            };
            emit(&[cb, ix], &payer, &[&oracle], &a[9]);
        }
        // The way back. `arm-release` is the borrower recording where their position should land;
        // `release` is the recorded authority signing to send it there. Two steps, two signers, and
        // neither can do the other's half.
        "arm-release" => {
            let payer = keypair(&a[1]);
            let program = addr(&a[2]);
            let ctx = artifact(&a[3]);
            let (escrow, dest) = (addr(&a[4]), addr(&a[5]));
            let (loan, _) = loan_pda(&program, &escrow);

            let mut data = vec![3u8];
            for k in ["new_decryptable_b64", "auditor_lo_b64", "auditor_hi_b64"] {
                data.extend_from_slice(&d64(ctx[k].as_str().unwrap()));
            }

            let ix = Instruction {
                program_id: program,
                accounts: vec![
                    AccountMeta::new_readonly(payer.pubkey(), true),
                    AccountMeta::new(loan, false),
                    AccountMeta::new_readonly(escrow, false),
                    AccountMeta::new_readonly(dest, false),
                    AccountMeta::new_readonly(addr(ctx["equality"].as_str().unwrap()), false),
                    AccountMeta::new_readonly(addr(ctx["validity"].as_str().unwrap()), false),
                    AccountMeta::new_readonly(addr(ctx["range"].as_str().unwrap()), false),
                ],
                data,
            };
            emit(&[ix], &payer, &[], &a[6]);
        }
        "release" => {
            let payer = keypair(&a[1]);
            let program = addr(&a[2]);
            let ctx = artifact(&a[3]);
            let (escrow, dest, mint) = (addr(&a[4]), addr(&a[5]), addr(&a[6]));
            let authority = keypair(&a[7]);
            let (loan, _) = loan_pda(&program, &escrow);

            // Same budget as seize, and for the same reason: one Transfer, three proof contexts,
            // two confidential accounts rewritten.
            let cb = Instruction {
                program_id: addr("ComputeBudget111111111111111111111111111111"),
                accounts: vec![],
                data: {
                    let mut d = vec![0x02];
                    d.extend_from_slice(&700_000u32.to_le_bytes());
                    d
                },
            };
            let ix = Instruction {
                program_id: program,
                accounts: vec![
                    AccountMeta::new(loan, false),
                    AccountMeta::new(escrow, false),
                    AccountMeta::new_readonly(mint, false),
                    AccountMeta::new(dest, false),
                    AccountMeta::new_readonly(addr(ctx["equality"].as_str().unwrap()), false),
                    AccountMeta::new_readonly(addr(ctx["validity"].as_str().unwrap()), false),
                    AccountMeta::new_readonly(addr(ctx["range"].as_str().unwrap()), false),
                    AccountMeta::new_readonly(authority.pubkey(), true),
                    AccountMeta::new_readonly(addr(TOKEN_2022), false),
                ],
                data: vec![4u8],
            };
            emit(&[cb, ix], &payer, &[&authority], &a[8]);
        }
        // Mode B origination: the lender holds the escrow's keys, read the balance themselves and
        // signs for the floor. No floor proofs are cited because none exist — the record carries a
        // byte saying so, which is what stops an asserted floor being read as a proved one.
        "originate-attested" => {
            let payer = keypair(&a[1]);
            let program = addr(&a[2]);
            let ctx = artifact(&a[3]);
            let (escrow, dest, mint, oracle) = (addr(&a[4]), addr(&a[5]), addr(&a[6]), addr(&a[7]));
            let authority = keypair(&a[11]);
            let (loan, _) = loan_pda(&program, &escrow);

            let mut data = vec![6u8];
            for n in [&a[8], &a[9], &a[10]] {
                data.extend_from_slice(&n.parse::<u64>().expect("u64").to_le_bytes());
            }
            for k in ["new_decryptable_b64", "auditor_lo_b64", "auditor_hi_b64"] {
                data.extend_from_slice(&d64(ctx[k].as_str().unwrap()));
            }

            let ix = Instruction {
                program_id: program,
                accounts: vec![
                    AccountMeta::new(payer.pubkey(), true),
                    AccountMeta::new(loan, false),
                    AccountMeta::new_readonly(escrow, false),
                    AccountMeta::new_readonly(dest, false),
                    AccountMeta::new_readonly(mint, false),
                    AccountMeta::new_readonly(addr(ctx["equality"].as_str().unwrap()), false),
                    AccountMeta::new_readonly(addr(ctx["validity"].as_str().unwrap()), false),
                    AccountMeta::new_readonly(addr(ctx["range"].as_str().unwrap()), false),
                    AccountMeta::new_readonly(oracle, false),
                    AccountMeta::new_readonly(authority.pubkey(), true),
                    AccountMeta::new_readonly(addr(SYSTEM), false),
                ],
                data,
            };
            eprintln!("  loan account       {loan}");
            emit(&[ix], &payer, &[&authority], &a[12]);
        }
        // Settle a confidential credit into an escrow the loan PDA already owns, before any loan
        // exists over it. This is the step that lets a holder whose position sits in an ATA take
        // part: an ATA cannot be handed over, so they transfer into somebody else's escrow, and
        // the credit lands in pending under an authority nobody but the program can sign for.
        "apply-pending" => {
            let payer = keypair(&a[1]);
            let program = addr(&a[2]);
            let (escrow, mint) = (addr(&a[3]), addr(&a[4]));
            let counter: u64 = a[5].parse().expect("expected pending credit counter");
            let (loan, _) = loan_pda(&program, &escrow);

            let mut data = vec![5u8];
            data.extend_from_slice(&counter.to_le_bytes());
            data.extend_from_slice(&d64(&a[6]));   // new decryptable available balance, 36 bytes

            let ix = Instruction {
                program_id: program,
                accounts: vec![
                    AccountMeta::new_readonly(payer.pubkey(), true),
                    AccountMeta::new(loan, false),
                    AccountMeta::new(escrow, false),
                    AccountMeta::new_readonly(mint, false),
                    AccountMeta::new_readonly(addr(TOKEN_2022), false),
                ],
                data,
            };
            emit(&[ix], &payer, &[], &a[7]);
        }
        other => panic!("unknown subcommand {other}"),
    }
}

fn loan_pda(program: &Address, escrow: &Address) -> (Address, u8) {
    Address::find_program_address(&[b"loan", escrow.as_ref()], program)
}

fn emit(ixs: &[Instruction], payer: &Keypair, extra: &[&Keypair], blockhash: &str) {
    let msg = Message::new(ixs, Some(&payer.pubkey()));
    let bh = Hash::from_str(blockhash).expect("blockhash");
    let mut signers: Vec<&Keypair> = vec![payer];
    signers.extend(extra);
    let tx = Transaction::new(&signers, msg, bh);
    println!(
        "{}",
        base64::engine::general_purpose::STANDARD.encode(bincode::serialize(&tx).unwrap())
    );
}

fn artifact(path: &str) -> serde_json::Value {
    serde_json::from_slice(&std::fs::read(path).unwrap()).unwrap()
}

fn addr(s: &str) -> Address {
    Address::from_str(s).expect("address")
}

fn keypair(path: &str) -> Keypair {
    let v: Vec<u8> = serde_json::from_slice(&std::fs::read(path).unwrap()).unwrap();
    Keypair::try_from(&v[..]).unwrap()
}

fn d64(s: &str) -> Vec<u8> {
    base64::engine::general_purpose::STANDARD.decode(s).unwrap()
}
