//! `bind-account <address> <elgamal_pubkey_b64> <available_balance_b64> <public_amount>`
//!
//! Builds the subject of a disclosure package out of a **real Token-2022 confidential account**,
//! read from the chain, instead of the placeholder `aperture` ships in its skeleton.
//!
//! This is the difference between a proof about *a number* and a proof about *this account*.
//! Until now `SubjectAccount` carried an address string nobody checked and an empty ElGamal pubkey,
//! so nothing tied a sealed position to a wallet a counterparty could go and look at. Now the
//! subject carries the account's own key and its own on-chain ciphertext, and
//! `scripts/bind-account.sh` re-reads both from devnet afterwards to confirm they still match.
//!
//! What this does **not** yet do: the range proof is still generated over a ciphertext of our own
//! rather than over the account's `availableBalance`. Closing that needs the account's ElGamal
//! secret, and `spl-token` derives it with a KDF this SDK version does not reproduce — see
//! DESIGN.md. The binding is real; the proof is not yet over the bound ciphertext.

use aperture_core::package::SubjectAccount;
use base64::Engine;

fn main() {
    let mut a = std::env::args().skip(1);
    let address = a.next().expect("usage: bind-account <address> <elgamal_b64> <balance_b64> <amount>");
    let elgamal_b64 = a.next().expect("elgamal pubkey");
    let balance_b64 = a.next().expect("available balance ciphertext");
    let public_amount = a.next().unwrap_or_else(|| "?".into());

    let d = |s: &str| base64::engine::general_purpose::STANDARD.decode(s).expect("base64");
    let elgamal = d(&elgamal_b64);
    let ciphertext = d(&balance_b64);

    let subject = SubjectAccount {
        address: address.clone(),
        elgamal_pubkey: elgamal.clone(),
        ciphertext_commitment: ciphertext.clone(),
    };

    println!("  account            {}", subject.address);
    println!("  public balance     {public_amount}   {}",
        if public_amount == "0" { "<- the chain says the wallet holds nothing" } else { "" });
    println!("  elgamal pubkey     {} bytes  {}", elgamal.len(),
        if elgamal.is_empty() { "EMPTY — not bound" } else { "read from the account itself" });
    println!("  available balance  {} bytes of ciphertext", ciphertext.len());
    println!();
    println!("  subject bound to a live account, not to a string:");
    println!("    {}", serde_json::to_string(&subject).unwrap().chars().take(150).collect::<String>());
}
