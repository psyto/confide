//! The two-lane demo: one quarter, one position, built in public and built under Confide.
//!
//! Run: `cargo run -p confide-demo --bin two-lane`

use aperture_core::package::{ChainAnchor, DisclosurePackage, SubstrateId};
use aperture_core::token2022::{issue_exact_disclosure, Token2022Substrate};
use aperture_core::verifier::verify_package;
use confide_embargo::{open, seal, Obligation, OpenError, ReleaseShare, SealedDisclosure};
use confide_equity::{nav_floor_disclosure, Position, DEFAULT_NAV_FLOOR_CENTS, NVDAX, SPYX, TSLAX};
use solana_zk_sdk::encryption::elgamal::{ElGamalCiphertext, ElGamalKeypair, ElGamalSecretKey};

const DIM: &str = "\x1b[2m";
const BOLD: &str = "\x1b[1m";
const RED: &str = "\x1b[31m";
const GRN: &str = "\x1b[32m";
const YEL: &str = "\x1b[33m";
const CYN: &str = "\x1b[36m";
const OFF: &str = "\x1b[0m";

const DAY: i64 = 86_400;
const QUARTER_END: i64 = 1_790_726_400; // t0 — 2026-09-30 00:00 UTC, the position of record
const DUE: i64 = QUARTER_END + 45 * DAY; // T — 45 days later, the reporting deadline
const ANCHOR_SLOT: u64 = 340_112_045;

/// (day of quarter, shares bought). A fund whose LPs are owed a quarterly report holds size, so
/// these are the numbers that make the obligation real — and the leak in Lane A expensive.
const BUYS: [(u32, u64); 7] = [
    (3, 42_000),
    (11, 54_000),
    (19, 31_000),
    (27, 18_000),
    (34, 12_000),
    (41, 9_000),
    (58, 7_000),
];

fn main() {
    banner();

    let fund = ElGamalKeypair::new_rand();

    // ── The quarter ────────────────────────────────────────────────────────────────────────────
    println!(
        "  {BOLD}Fund A accumulates NVDAx over Q3. Same buys, two lanes.{OFF}\n"
    );
    println!(
        "  {DIM}day      LANE A · a public wallet       LANE B · Confide                      {OFF}"
    );
    println!(
        "  {DIM}         what anyone can see            what anyone can see   the auditor {OFF}"
    );
    println!("  {DIM}────────────────────────────────────────────────────────────────────────────{OFF}");

    let mut position = 0u64;
    for (day, qty) in BUYS {
        position += qty;
        let (held, bought) = (commas(position), commas(qty));
        println!(
            "  {DIM}{day:>3}{OFF}      {RED}{held:>9} NVDAx{OFF} {DIM}·{OFF} {RED}+{bought}{OFF}\
             {pad}{DIM}—{OFF}                {GRN}{held:>9} NVDAx{OFF}",
            pad = " ".repeat(14usize.saturating_sub(bought.len() + 1)),
        );
    }
    println!(
        "\n  {RED}Lane A leaked the position continuously, from day 3, mid-accumulation.{OFF}"
    );
    println!("  {DIM}Nobody attacked anything. The chain simply published it.{OFF}\n");

    // ── t0: quarter end. Seal and anchor. ──────────────────────────────────────────────────────
    let (obligation, _) = position_of_record(&fund, position, "public", "q3-report-fund-A");
    let (sealed, agents) = seal(&obligation, DUE, ANCHOR_SLOT, 3, 5);

    rule("30 Sep · quarter end — the position of record is sealed and anchored");
    println!(
        "  commitment  {CYN}{}{OFF}  {DIM}(content-blind — reveals nothing){OFF}",
        hex12(&sealed.commitment)
    );
    println!("  anchored    slot {ANCHOR_SLOT} {DIM}· mainnet-beta{OFF}");
    println!("  due         {BOLD}14 Nov{OFF} {DIM}· 45 days, the reporting deadline{OFF}");
    println!("  committee   {DIM}{:?}{OFF}", sealed.trust);
    println!(
        "\n  {DIM}From here the fund can do nothing. It cannot open this early, cannot stop it{OFF}"
    );
    println!("  {DIM}opening, and cannot revise what is inside it.{OFF}\n");

    // ── The auditor is never delayed. ──────────────────────────────────────────────────────────
    let (to_auditor, _) = position_of_record(&fund, position, "auditor", "q3-report-auditor");
    let report = verify_package(&to_auditor.package, &Token2022Substrate, QUARTER_END, "auditor");
    rule("1 Oct · the LP asks");
    println!(
        "  auditor verifies the package  {}  {DIM}({}){OFF}",
        pass(report.passed()),
        report.notes.iter().find(|n| n.starts_with("trust_model")).cloned().unwrap_or_default()
    );
    println!(
        "  auditor reads the position    {GRN}{} NVDAx{OFF}   {DIM}44 days before the public can{OFF}",
        commas(read(&to_auditor))
    );

    // The other half of a quarterly report: does the covenant hold? A predicate, answerable
    // before the position itself is disclosable.
    let portfolio = vec![
        Position::from_shares(NVDAX, position, 18_450), // $184.50
        Position::from_shares(TSLAX, 90_000, 42_100),   // $421.00
        Position::from_shares(SPYX, 55_000, 66_800),    // $668.00
    ];
    let portfolio_musd = portfolio.iter().map(Position::value_cents).sum::<u64>() / 100_000_000;
    let ok = nav_floor_disclosure(&fund, &portfolio, DEFAULT_NAV_FLOOR_CENTS);
    println!(
        "  is the fund above its floor?  {}   {DIM}floor ${}M — and that is all this reveals{OFF}",
        if ok.is_some() { format!("{GRN}YES{OFF}") } else { format!("{YEL}NO{OFF}") },
        DEFAULT_NAV_FLOOR_CENTS / 100_000_000
    );
    println!(
        "  {DIM}(the portfolio is ${portfolio_musd}M across NVDAx/TSLAx/SPYx — the LP is not told that){OFF}"
    );
    if let Some(att) = &ok {
        println!(
            "  {DIM}the predicate's proof is {} bytes of BatchedRangeProofU64, and the live{OFF}",
            att.proof.bytes.len()
        );
        println!(
            "  {DIM}ZK ElGamal Proof Program accepts it on devnet:{OFF} {CYN}./scripts/devnet-verify.sh{OFF}"
        );
    }
    println!();

    // ── The fund tries to revise. ──────────────────────────────────────────────────────────────
    rule("2 Nov · the fund has second thoughts");
    let (flattering, _) = position_of_record(&fund, 5, "public", "q3-report-revised");
    let (sealed_lie, lie_agents) = seal(&flattering, DUE, ANCHOR_SLOT, 3, 5);
    let spliced = SealedDisclosure {
        ciphertext: sealed_lie.ciphertext,
        nonce: sealed_lie.nonce,
        ..sealed.clone()
    };
    let lie_shares = publish_all(&lie_agents, &spliced, DUE);
    println!("  {DIM}It seals a smaller position and splices it under the anchored commitment.{OFF}");
    match open(&spliced, &lie_shares) {
        Err(OpenError::CommitmentMismatch { .. }) => println!(
            "  {GRN}REFUSED{OFF}  the package inside is not the one committed to on 30 Sep\n"
        ),
        other => println!("  {RED}the swap was not caught: {other:?}{OFF}\n"),
    }

    // ── Before T. ──────────────────────────────────────────────────────────────────────────────
    rule("13 Nov · one day early");
    let early = DUE - DAY;
    for agent in &agents {
        if let Err(e) = agent.publish(&sealed, early) {
            println!("  agent {} {YEL}refuses{OFF}  {DIM}{e}{OFF}", agent.index);
        }
    }
    println!(
        "  open(sealed, no shares)  {YEL}{}{OFF}\n",
        open(&sealed, &[]).unwrap_err()
    );

    // ── T. The holder is not asked. ────────────────────────────────────────────────────────────
    rule("14 Nov · the obligation comes due");
    let published = publish_all(&agents[..3], &sealed, DUE);
    println!(
        "  agents {} publish their shares  {DIM}· the fund is not asked, and cannot object{OFF}",
        published.iter().map(|s| s.agent_index.to_string()).collect::<Vec<_>>().join(", ")
    );
    let opened = open(&sealed, &published).expect("the obligation opens");
    println!(
        "  reconstructed  {}   commitment matches slot {ANCHOR_SLOT}  {}",
        pass(true),
        pass(opened.commitment() == sealed.commitment)
    );
    println!(
        "\n  {BOLD}LANE B is now public: {GRN}{} NVDAx{OFF}{BOLD}, held by {} as of 30 Sep.{OFF}\n",
        commas(read(&opened)),
        opened.package.issuer
    );

    // ── The line. ──────────────────────────────────────────────────────────────────────────────
    println!("  {DIM}────────────────────────────────────────────────────────────────────────────{OFF}");
    println!("  {RED}Lane A{OFF}  readable from day 3, by anyone, while the position was being built.");
    println!(
        "  {GRN}Lane B{OFF}  readable exactly on schedule — and provably the position actually held."
    );
    println!();
}

// ── helpers ────────────────────────────────────────────────────────────────────────────────────

fn position_of_record(
    fund: &ElGamalKeypair,
    shares: u64,
    recipient: &str,
    pkg_id: &str,
) -> (Obligation, ElGamalKeypair) {
    let reader = ElGamalKeypair::new_rand();
    let (claim, proof, subject) = issue_exact_disclosure(fund, reader.pubkey(), shares, "fund-A-nvdax");
    let mut package = DisclosurePackage {
        package_id: pkg_id.into(),
        grant_id: "obligation-q3-lp-report".into(),
        substrate: SubstrateId::Token2022,
        issuer: "Fund A".into(),
        recipient: recipient.into(),
        issued_at: QUARTER_END,
        expiry: None,
        anchor: ChainAnchor { cluster: "mainnet-beta".into(), slot: ANCHOR_SLOT },
        subject: vec![subject],
        claim,
        proof,
        receipt_commitment: vec![],
        issuer_signature: vec![],
    };
    package.receipt_commitment = package.derive_receipt_commitment().to_vec();

    let mut reader_payload = reader.pubkey().encrypt(shares).to_bytes().to_vec();
    reader_payload.extend_from_slice(reader.secret().as_bytes());
    (Obligation { package, reader_payload }, reader)
}

fn read(ob: &Obligation) -> u64 {
    let (ct, secret) = ob.reader_payload.split_at(64);
    ElGamalSecretKey::try_from(secret)
        .ok()
        .and_then(|s| ElGamalCiphertext::from_bytes(ct).and_then(|c| s.decrypt_u32(&c)))
        .expect("an opened position is readable")
}

fn publish_all(
    agents: &[confide_embargo::ReleaseAgent],
    sealed: &SealedDisclosure,
    now: i64,
) -> Vec<ReleaseShare> {
    agents.iter().filter_map(|a| a.publish(sealed, now).ok()).collect()
}

/// 173000 -> "173,000". Position sizes are the point; they should be readable at a glance.
fn commas(n: u64) -> String {
    let s = n.to_string();
    let mut out = String::new();
    for (i, c) in s.chars().enumerate() {
        if i > 0 && (s.len() - i) % 3 == 0 {
            out.push(',');
        }
        out.push(c);
    }
    out
}

fn hex12(b: &[u8; 32]) -> String {
    b[..6].iter().map(|x| format!("{x:02x}")).collect::<String>() + "…"
}

fn pass(ok: bool) -> String {
    if ok { format!("{GRN}✓{OFF}") } else { format!("{RED}✗{OFF}") }
}

fn rule(title: &str) {
    println!("  {DIM}────────────────────────────────────────────────────────────────────────────{OFF}");
    println!("  {BOLD}{title}{OFF}");
    println!();
}

fn banner() {
    println!();
    println!("  {BOLD}CONFIDE{OFF} {DIM}· lawful delay for tokenized equity positions{OFF}");
    println!(
        "  {DIM}A fund owes its LPs a quarterly position report. On-chain it owes the market a{OFF}"
    );
    println!("  {DIM}continuous one it never agreed to.{OFF}");
    println!();
}
