//! `confide-seal <dir>` — the holder's last act.
//!
//! Seals the position of record, writes the public artifact, hands one share to each agent, and
//! exits. After this process ends the holder has no lever: the ciphertext is in the open and the
//! key exists only as shares held by other parties.

use confide_embargo::seal;
use std::fs;
use std::path::PathBuf;

fn main() {
    let dir = PathBuf::from(std::env::args().nth(1).unwrap_or_else(|| "committee".into()));
    fs::create_dir_all(&dir).expect("create committee dir");

    let (obligation, open_at) = confide_committee::quarter_end_obligation();
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
    println!("  commitment  {}", hex(&commitment));
    println!("  opens at    {open_at}");
    println!("  committee   {:?}", sealed.trust);
    println!();
    println!("  shares handed to 5 agents; this process is about to exit and the holder");
    println!("  keeps none of them. What opens at T opens without it.");
}

fn hex(b: &[u8]) -> String {
    b.iter().map(|x| format!("{x:02x}")).collect()
}
