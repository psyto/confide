//! `confide-open <sealed.json> <share.published>...` — anyone, at T.
//!
//! Not the holder, not an agent: whoever picks up the published shares. Takes no clock and no
//! identity. If enough shares are out, the position is public.

use confide_embargo::{open, ReleaseShare, SealedDisclosure};
use confide_equity::actions::{restate, scheduled};
use std::fs;

const DIM: &str = "\x1b[2m";
const YEL: &str = "\x1b[33m";
const OFF: &str = "\x1b[0m";

fn main() {
    let mut a = std::env::args().skip(1);
    let sealed_file = a.next().expect("usage: confide-open <sealed.json> <share.published>...");
    let sealed: SealedDisclosure = serde_json::from_slice(&fs::read(&sealed_file).unwrap()).unwrap();

    let shares: Vec<ReleaseShare> = a
        .map(|f| serde_json::from_slice(&fs::read(&f).unwrap()).unwrap())
        .collect();
    println!("  collected   {} published share(s)", shares.len());

    match open(&sealed, &shares) {
        Ok(ob) => {
            println!("  commitment  matches the anchor at slot {}", sealed.anchored_slot);
            let units = confide_committee::read_position(&ob);
            let as_of = ob.package.issued_at;
            println!(
                "\n  {} held {} NVDAx as of the reporting date.",
                ob.package.issuer,
                confide_committee::commas(units)
            );

            // A number sealed in September is quoted in September's units. If a split landed in
            // between, saying only that number is correct and unreadable at the same time.
            match restate(units, "NVDAx", &scheduled(), as_of, sealed.open_at) {
                Some(r) if r.unchanged() => println!(
                    "  {DIM}No corporate action between the reporting date and today, so that\n  number reads as-is.{OFF}\n"
                ),
                Some(r) => {
                    if !r.applied.is_empty() {
                        println!("  {DIM}Restated into today's units:{OFF}");
                        for a in &r.applied {
                            println!(
                                "    {} {} on {}  ({} -> {})",
                                a.symbol,
                                a.ca_type,
                                &a.effective_utc[..10],
                                a.from_units.as_deref().unwrap_or("?"),
                                a.to_units.as_deref().unwrap_or("?")
                            );
                        }
                    }
                    if r.fully_resolved() {
                        println!(
                            "  = {} NVDAx today. The sealed number did not move; the units it is quoted in did.\n",
                            confide_committee::commas(r.current_units)
                        );
                    } else {
                        // Saying nothing here would let a reader treat the number as current.
                        println!("  {YEL}Not fully restatable.{OFF} {DIM}Also in this window:{OFF}");
                        for a in &r.unresolved {
                            println!("    {} {} on {}", a.symbol, a.ca_type, &a.effective_utc[..10]);
                        }
                        println!(
                            "  {DIM}These change the holding without a unit ratio, so no single number\n                               is today's position. The sealed one still stands for the reporting date.{OFF}\n"
                        );
                    }
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
