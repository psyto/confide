//! `mora-agent <share-file> <sealed.json> <now>` — one release agent, as its own process.
//!
//! Exits 0 and prints its share when the obligation is due. Exits 1 and prints the refusal when it
//! is not. The holder is not an argument, cannot be one, and has no way to change the answer.

use mora_embargo::{ReleaseAgent, SealedDisclosure};
use std::fs;

fn main() {
    let mut a = std::env::args().skip(1);
    let share_file = a.next().expect("usage: mora-agent <share> <sealed.json> <now>");
    let sealed_file = a.next().expect("usage: mora-agent <share> <sealed.json> <now>");
    let now: i64 = a.next().expect("usage: mora-agent <share> <sealed.json> <now>").parse().unwrap();

    let agent: ReleaseAgent = serde_json::from_slice(&fs::read(&share_file).unwrap()).unwrap();
    let sealed: SealedDisclosure = serde_json::from_slice(&fs::read(&sealed_file).unwrap()).unwrap();

    match agent.publish(&sealed, now) {
        Ok(share) => {
            let out = format!("{share_file}.published");
            fs::write(&out, serde_json::to_vec_pretty(&share).unwrap()).unwrap();
            eprintln!("  agent {}  publishes  -> {out}", agent.index);
        }
        Err(e) => {
            eprintln!("  agent {}  refuses    {e}", agent.index);
            std::process::exit(1);
        }
    }
}
