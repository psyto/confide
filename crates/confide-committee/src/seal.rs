//! `confide-seal <dir> [keys.json] [decryptable_b64] [available_b64]` — the holder's last act.
//!
//! Seals the position of record, writes the public artifact, hands one share to each agent, and
//! exits. After this process ends the holder has no lever: the ciphertext is in the open and the
//! key exists only as shares held by other parties.
//!
//! Given the account's keys and its two on-chain ciphertexts, what is sealed is *that account's*
//! position. Given nothing, a throwaway account is stood up so the demo runs offline — and the run
//! says which it did, because a demo that cannot tell you whether it touched the chain is a demo
//! you cannot quote.

use base64::Engine;
use confide_committee::LiveAccount;
use confide_embargo::seal;
use std::fs;
use std::path::PathBuf;

fn main() {
    let dir = PathBuf::from(std::env::args().nth(1).unwrap_or_else(|| "committee".into()));
    fs::create_dir_all(&dir).expect("create committee dir");

    let mut a = std::env::args().skip(2);
    let keys_path = a.next();
    let dec = a.next().map(|s| d64(&s));
    let avail = a.next().map(|s| d64(&s));
    let live = match (&keys_path, &dec, &avail) {
        (Some(k), Some(d), Some(v)) => {
            Some(LiveAccount { keys_path: k, decryptable: d, available: v })
        }
        _ => None,
    };
    let (obligation, open_at, account) = confide_committee::quarter_end_obligation(live);
    let commitment = obligation.commitment();
    let (sealed, agents) = seal(&obligation, open_at, confide_committee::ANCHOR_SLOT, 3, 5);

    fs::write(dir.join("sealed.json"), serde_json::to_vec_pretty(&sealed).unwrap()).unwrap();
    for a in &agents {
        fs::write(
            dir.join(format!("agent-{}.share", a.index)),
            serde_json::to_vec_pretty(a).unwrap(),
        )
        .unwrap();
    }

    println!("  sealed      {}", dir.join("sealed.json").display());
    println!("  about       {account}");
    println!("  commitment  {}", hex(&commitment));
    println!("  opens at    {open_at}");
    println!("  committee   {:?}", sealed.trust);
    println!();
    println!("  shares handed to 5 agents; this process is about to exit and the holder");
    println!("  keeps none of them. What opens at T opens without it.");
}

fn d64(s: &str) -> Vec<u8> {
    base64::engine::general_purpose::STANDARD.decode(s).expect("base64")
}

fn hex(b: &[u8]) -> String {
    b.iter().map(|x| format!("{x:02x}")).collect()
}
