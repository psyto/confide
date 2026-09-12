//! `mora-open <sealed.json> <share.published>...` — anyone, at T.
//!
//! Not the holder, not an agent: whoever picks up the published shares. Takes no clock and no
//! identity. If enough shares are out, the position is public.

use mora_embargo::{open, ReleaseShare, SealedDisclosure};
use mora_equity::actions::{restate, scheduled};
use std::fs;

const DIM: &str = "\x1b[2m";
const OFF: &str = "\x1b[0m";

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
            let units = mora_committee::read_position(&ob);
            let as_of = ob.package.issued_at;
            println!(
                "\n  {} held {} NVDAx as of the reporting date.",
                ob.package.issuer,
                mora_committee::commas(units)
            );

            // A number sealed in September is quoted in September's units. If a split landed in
            // between, saying only that number is correct and unreadable at the same time.
            match restate(units, "NVDAx", &scheduled(), as_of, sealed.open_at) {
                Some(r) if r.unchanged() => println!(
                    "  {DIM}No unit-changing corporate action between the reporting date\n  and today, so that number reads as-is.{OFF}\n"
                ),
                Some(r) => {
                    println!("  {DIM}Restated into today's units:{OFF}");
                    for a in &r.applied {
                        println!(
                            "    {} {} on {}  ({} -> {})",
                            a.symbol,
                            a.ca_type,
                            &a.effective_utc[..10],
                            a.from_units,
                            a.to_units
                        );
                    }
                    println!(
                        "  = {} NVDAx today. The sealed number did not move; the units it is quoted in did.\n",
                        mora_committee::commas(r.current_units)
                    );
                }
                None => println!(
                    "  {DIM}A corporate action in this window cannot be restated exactly;\n  refusing to quote a number that quietly lost shares.{OFF}\n"
                ),
            }
        }
        Err(e) => {
            println!("  still shut  {e}");
            std::process::exit(1);
        }
    }
}
