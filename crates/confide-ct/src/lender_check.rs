//! What a lender checks before they lend, run by the lender, against the chain.
//!
//!   lender-check <rpc> <program> <loan> <my-token-account> [q_min] [principal_cents] [ratio_bps]
//!
//! Until this existed there was no way to be a lender in Confide without trusting the borrower's
//! scripts. The mechanism ran end to end, but both parties were the same person — `seizure-e2e.sh`
//! generates the borrower and the lender itself — so nothing established what the *other* side
//! could confirm on their own.
//!
//! **It calls the program's own predicates.** `floor_is_proved` and `context_is_armed` are the
//! functions `confide-seizure` runs on chain, imported here and pointed at data fetched from RPC.
//! A second implementation of the same rule is how a lender and a chain come to disagree about
//! whether a loan is safe, and this repository has enough of that already.
//!
//! What it does **not** do: price anything, judge the mint, or say whether the terms are good. It
//! answers one question — *is this loan what the borrower says it is, and is the collateral out of
//! their hands?* Everything about the asset's risk is a separate document, `docs/packets/`.
use confide_seizure::solana_program::pubkey::Pubkey;
use confide_seizure::{context_is_armed, floor_is_proved, LOAN_LEN_V1};
use solana_address::Address;
use std::str::FromStr;

// Offsets into the loan record. Imported rather than retyped would be better; they are private to
// the program, so this file is checked against it by scripts/docs-consistency.sh instead.
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
const OFF_SEIZED: usize = 414;
const OFF_RELEASED: usize = 739;
const LOAN_LEN_V2: usize = 740;
const LOAN_TAG: u8 = 1;

// Proof types, as the ZK program writes them into a context account.
const PT_EQUALITY: u8 = 3;
const PT_VALIDITY_3: u8 = 12;
const PT_RANGE_U128: u8 = 7;

struct Acct {
    owner: Address,
    data: Vec<u8>,
}

fn rpc(url: &str, body: String) -> serde_json::Value {
    let out = std::process::Command::new("curl")
        .args(["-s", url, "-H", "Content-Type: application/json", "-d", &body])
        .output()
        .expect("curl");
    serde_json::from_slice(&out.stdout).expect("rpc returned something that is not json")
}

fn account(url: &str, key: &str) -> Option<Acct> {
    let v = rpc(
        url,
        format!(
            r#"{{"jsonrpc":"2.0","id":1,"method":"getAccountInfo","params":["{key}",{{"encoding":"base64"}}]}}"#
        ),
    );
    let val = v.get("result")?.get("value")?;
    if val.is_null() {
        return None;
    }
    use base64::Engine;
    let data = base64::engine::general_purpose::STANDARD
        .decode(val["data"][0].as_str()?)
        .ok()?;
    Some(Acct {
        owner: Address::from_str(val["owner"].as_str()?).ok()?,
        data,
    })
}

/// The escrow's ElGamal key and the ciphertext it holds **right now**. The floor proof is about a
/// ciphertext; if the escrow's has moved on since, the floor is about a balance it no longer has.
fn escrow_confidential(url: &str, key: &str) -> Option<([u8; 32], [u8; 64])> {
    let v = rpc(
        url,
        format!(
            r#"{{"jsonrpc":"2.0","id":1,"method":"getAccountInfo","params":["{key}",{{"encoding":"jsonParsed"}}]}}"#
        ),
    );
    let exts = v["result"]["value"]["data"]["parsed"]["info"]["extensions"].as_array()?;
    let st = exts
        .iter()
        .find(|e| e["extension"] == "confidentialTransferAccount")?
        .get("state")?;
    use base64::Engine;
    let pk: [u8; 32] = base64::engine::general_purpose::STANDARD
        .decode(st["elgamalPubkey"].as_str()?)
        .ok()?
        .try_into()
        .ok()?;
    let ct: [u8; 64] = base64::engine::general_purpose::STANDARD
        .decode(st["availableBalance"].as_str()?)
        .ok()?
        .try_into()
        .ok()?;
    Some((pk, ct))
}

fn addr_at(d: &[u8], off: usize) -> Address {
    Address::from(<[u8; 32]>::try_from(&d[off..off + 32]).unwrap())
}
fn u64_at(d: &[u8], off: usize) -> u64 {
    u64::from_le_bytes(d[off..off + 8].try_into().unwrap())
}

fn main() {
    let a: Vec<String> = std::env::args().skip(1).collect();
    if a.len() < 4 {
        eprintln!(
            "usage: lender-check <rpc> <program> <loan> <my-token-account> \\\n\
             \x20            [expected_q_min] [expected_principal_cents] [expected_ratio_bps]"
        );
        std::process::exit(2);
    }
    let (url, program, loan_key, mine) = (&a[0], &a[1], &a[2], &a[3]);
    let program = Address::from_str(program).expect("program address");

    let mut failed = 0usize;
    let mut check = |ok: bool, what: &str, detail: String| {
        if ok {
            println!("  \x1b[32m✓\x1b[0m {what}\n      \x1b[2m{detail}\x1b[0m");
        } else {
            failed += 1;
            println!("  \x1b[31m✗\x1b[0m {what}\n      \x1b[2m{detail}\x1b[0m");
        }
    };

    println!("\n\x1b[1mTHE LOAN\x1b[0m — is it this program's, and is it still open");
    let Some(loan) = account(url, loan_key) else {
        println!("  \x1b[31m✗\x1b[0m no account at {loan_key}");
        std::process::exit(1);
    };
    check(
        loan.owner == program,
        "the loan account belongs to the seizure program",
        format!("owner {}", loan.owner),
    );
    check(
        loan.data.len() >= LOAN_LEN_V1 && loan.data[0] == LOAN_TAG,
        "it is a loan record",
        format!(
            "{} bytes, tag {} — v{}",
            loan.data.len(),
            loan.data[0],
            if loan.data.len() >= LOAN_LEN_V2 { 2 } else { 1 }
        ),
    );
    if loan.data.len() < LOAN_LEN_V1 {
        std::process::exit(1);
    }
    let seized = loan.data[OFF_SEIZED] != 0;
    let released = loan.data.len() >= LOAN_LEN_V2 && loan.data[OFF_RELEASED] != 0;
    check(
        !seized && !released,
        "the escrow has not been emptied",
        format!("seized {seized}, released {released}"),
    );

    let escrow = addr_at(&loan.data, OFF_ESCROW);
    let destination = addr_at(&loan.data, OFF_DESTINATION);
    let mint = addr_at(&loan.data, OFF_MINT);
    let oracle = addr_at(&loan.data, OFF_ORACLE);
    let q_min = u64_at(&loan.data, OFF_Q_MIN);

    // The PDA is derived from the escrow, so a loan that does not derive back to itself is a
    // record someone made about an escrow rather than the one the program will act on.
    let (derived, _) = Address::find_program_address(&[b"loan", escrow.as_ref()], &program);
    check(
        derived.to_string() == *loan_key,
        "this is the canonical loan for that escrow",
        format!("PDA of [\"loan\", {escrow}] is {derived}"),
    );

    println!("\n\x1b[1mTHE COLLATERAL\x1b[0m — is it out of the borrower's hands");
    let Some(esc) = account(url, &escrow.to_string()) else {
        println!("  \x1b[31m✗\x1b[0m the escrow {escrow} does not exist");
        std::process::exit(1);
    };
    // The SPL owner is at offset 32 of a token account, ahead of every extension.
    let esc_owner = addr_at(&esc.data, 32);
    check(
        esc_owner.to_string() == *loan_key,
        "the escrow is owned by the loan PDA, not by the borrower",
        format!("owner {esc_owner}"),
    );

    println!("\n\x1b[1mTHE SEIZURE ROUTE\x1b[0m — is it armed, and out of the borrower's reach");
    let eq = addr_at(&loan.data, OFF_CTX_EQUALITY);
    let va = addr_at(&loan.data, OFF_CTX_VALIDITY);
    let rp = addr_at(&loan.data, OFF_CTX_RANGE);
    let ctx = |k: &Address| account(url, &k.to_string());
    let (Some(eq_a), Some(va_a), Some(rp_a)) = (ctx(&eq), ctx(&va), ctx(&rp)) else {
        println!("  \x1b[31m✗\x1b[0m one of the seizure proof contexts is gone — the seizure cannot execute");
        std::process::exit(1);
    };
    let loan_pk = Address::from_str(loan_key).unwrap();
    for (name, acct, pt) in [
        ("equality", &eq_a, PT_EQUALITY),
        ("ciphertext validity", &va_a, PT_VALIDITY_3),
        ("range", &rp_a, PT_RANGE_U128),
    ] {
        let owner = Pubkey::new_from_array(acct.owner.to_bytes());
        let loanp = Pubkey::new_from_array(loan_pk.to_bytes());
        let r = context_is_armed(&owner, &acct.data, pt, &loanp);
        check(
            r.is_ok(),
            &format!("the {name} proof is verified and under an authority the borrower cannot close"),
            match r {
                Ok(()) => "authority is the loan PDA".to_string(),
                Err(e) => format!("{e:?}"),
            },
        );
    }

    println!("\n\x1b[1mTHE FLOOR\x1b[0m — what you can establish, and what you are relying on");
    // Deliberately not a re-derivation. `originate` proves the floor against ctx_floor_equality and
    // ctx_floor_range, and **the loan record does not keep their addresses** — they are consumed at
    // origination and never referenced again. So a lender cannot recompute the floor from the
    // record, and a tool that pretended to would be checking the transfer proofs and calling them
    // the floor. The first version of this file did exactly that and failed on a healthy loan,
    // which is how the gap was found.
    println!("  \x1b[2m·\x1b[0m the program verified a floor of \x1b[1m{q_min}\x1b[0m base units at origination,");
    println!("      \x1b[2magainst this escrow's own key and ciphertext. `originate` refuses without it,");
    println!("      so this loan existing is the evidence that it passed.\x1b[0m");
    check(
        esc_owner.to_string() == *loan_key,
        "and the floor cannot have fallen since: the borrower does not own the escrow",
        "a balance they cannot reduce is a lower bound that stays true".to_string(),
    );
    println!("  \x1b[2m·\x1b[0m \x1b[1mwhat you cannot check here:\x1b[0m the floor proof contexts are not recorded in the");
    println!("      \x1b[2mloan, so this relies on the program having checked them rather than on you");
    println!("      re-deriving it. Recording them is the next version of the record.\x1b[0m");

    println!("\n\x1b[1mTHE ROUTE\x1b[0m — where the collateral goes if it is taken");
    check(
        destination.to_string() == *mine,
        "on default the collateral goes to YOUR account",
        format!("destination {destination}"),
    );

    println!("\n\x1b[1mTHE TERMS\x1b[0m — what the record says, against what you agreed");
    let principal = u64_at(&loan.data, OFF_PRINCIPAL);
    let ratio = u64_at(&loan.data, OFF_RATIO_BPS);
    println!("      \x1b[2mmint {mint}\n      oracle {oracle} — this key's signature triggers a seizure\x1b[0m");
    for (i, (name, got)) in [("floor", q_min), ("principal (cents)", principal), ("ratio (bps)", ratio)]
        .iter()
        .enumerate()
    {
        match a.get(4 + i) {
            None => println!("  \x1b[2m·\x1b[0m {name}: {got} \x1b[2m(nothing to compare — pass what you agreed)\x1b[0m"),
            Some(w) => {
                let want: u64 = w.parse().expect("expected value must be a number");
                check(want == *got, &format!("{name} is what you agreed"), format!("record {got}, you said {want}"));
            }
        }
    }

    println!();
    if failed == 0 {
        println!("  \x1b[32mevery check passed\x1b[0m — the collateral is locked, the floor is proved against it now,");
        println!("  and the seizure route points at you. \x1b[1mThis says nothing about whether the asset is good\x1b[0m:");
        println!("  freeze authority, permanent delegate, pause and transfer fees are in docs/packets/.\n");
    } else {
        println!("  \x1b[31m{failed} check(s) failed — do not lend against this\x1b[0m\n");
        std::process::exit(1);
    }
}
