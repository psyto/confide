//! `mora-open <sealed.json> <share.published>...` — anyone, at T.
//!
//! Not the holder, not an agent: whoever picks up the published shares. Takes no clock and no
//! identity. If enough shares are out, the position is public.

use mora_embargo::{open, ReleaseShare, SealedDisclosure};
use std::fs;

fn main() {
    let mut a = std::env::args().skip(1);
    let sealed_file = a.next().expect("usage: mora-open <sealed.json> <share.published>...");
    let sealed: SealedDisclosure = serde_json::from_slice(&fs::read(&sealed_file).unwrap()).unwrap();

    let shares: Vec<ReleaseShare> = a
        .map(|f| serde_json::from_slice(&fs::read(&f).unwrap()).unwrap())
        .collect();
    println!("  collected   {} published share(s)", shares.len());

    match open(&sealed, &shares) {
        Ok(ob) => {
            println!("  commitment  matches the anchor at slot {}", sealed.anchored_slot);
            println!(
                "\n  {} held {} NVDAx as of the reporting date.\n",
                ob.package.issuer,
                mora_committee::commas(mora_committee::read_position(&ob))
            );
        }
        Err(e) => {
            println!("  still shut  {e}");
            std::process::exit(1);
        }
    }
}
