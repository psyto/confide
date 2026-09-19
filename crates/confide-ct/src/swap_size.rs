//! Does a two-leg confidential swap fit in ONE Solana transaction?
//!
//! The question the whole design rests on. A confidential transfer needs three zero-knowledge
//! proofs, and those do not fit in a transaction — which is why every proof in this repository is
//! verified into a *context state account* first, across ten transactions. That work is setup and
//! happens before the swap.
//!
//! What has to be atomic is the exchange itself: leg A→B and leg B→A, both or neither. This
//! measures that transaction by building it and serialising it, rather than adding up field sizes.
//! Solana's limit is 1232 bytes (PACKET_DATA_SIZE).
//!
//! Nothing here touches the chain and nothing is signed with a key that owns anything: the
//! addresses are arbitrary, because size depends on the *shape* of the transaction and not on
//! which accounts it names. What is real is the instruction construction — it goes through the
//! same `inner_transfer` the program uses to settle a seizure.
//!
//!   cargo run -p confide-ct --bin swap-size

use base64::Engine;
use solana_address::Address;
use solana_hash::Hash;
use solana_keypair::Keypair;
use solana_message::{v0, AddressLookupTableAccount, Message, VersionedMessage};
use solana_signer::Signer;
use solana_transaction::versioned::VersionedTransaction;
use solana_transaction::Transaction;
use spl_token_2022_interface::extension::confidential_transfer::instruction::inner_transfer;
use spl_token_confidential_transfer_proof_extraction::instruction::ProofLocation;

const TOKEN_2022: &str = "TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb";
const LIMIT: usize = 1232;

/// One side of the swap: an owner sending from their own account to the other party's account,
/// citing three proof contexts that were verified earlier.
struct Leg {
    owner: Keypair,
    source: Address,
    mint: Address,
    destination: Address,
    ctx: [Address; 3],
}

impl Leg {
    fn new() -> Self {
        Leg {
            owner: Keypair::new(),
            source: Keypair::new().pubkey(),
            mint: Keypair::new().pubkey(),
            destination: Keypair::new().pubkey(),
            ctx: [
                Keypair::new().pubkey(),
                Keypair::new().pubkey(),
                Keypair::new().pubkey(),
            ],
        }
    }

    fn instruction(&self) -> solana_instruction::Instruction {
        let token = Address::try_from(TOKEN_2022).unwrap();
        // The three ciphertexts a transfer carries regardless of where its proofs live: the new
        // decryptable balance of the SENDER, and the amount's low and high halves under the
        // auditor's key. Zeroed here because their sizes are fixed and only sizes are in question.
        let new_decryptable = [0u8; 36];
        let auditor_lo = [0u8; 64];
        let auditor_hi = [0u8; 64];
        inner_transfer(
            &token,
            &self.source,
            &self.mint,
            &self.destination,
            bytemuck::from_bytes(&new_decryptable),
            bytemuck::from_bytes(&auditor_lo),
            bytemuck::from_bytes(&auditor_hi),
            &self.owner.pubkey(),
            &[],
            ProofLocation::ContextStateAccount(&self.ctx[0]),
            ProofLocation::ContextStateAccount(&self.ctx[1]),
            ProofLocation::ContextStateAccount(&self.ctx[2]),
        )
        .expect("inner_transfer")
    }
}

fn main() {
    let (a, b) = (Leg::new(), Leg::new());
    let ixs = [a.instruction(), b.instruction()];
    let blockhash = Hash::new_unique();

    println!();
    println!("  ONE TRANSACTION, TWO CONFIDENTIAL TRANSFERS");
    println!("    limit                {LIMIT} bytes (PACKET_DATA_SIZE)");
    for (n, ix) in ixs.iter().enumerate() {
        println!(
            "    leg {} instruction    {} accounts, {} bytes of data",
            n + 1,
            ix.accounts.len(),
            ix.data.len()
        );
    }

    // Both owners sign: each leg is authorised by the account it sends from. That is what makes
    // the swap safe without an escrow — neither side can be made to send without signing.
    let payer = &a.owner;
    let msg = Message::new(&ixs, Some(&payer.pubkey()));
    let signers: Vec<&Keypair> = vec![&a.owner, &b.owner];
    let legacy = bincode::serialize(&Transaction::new(&signers, msg, blockhash)).unwrap();
    verdict("legacy, every account inline", legacy.len());

    // And the same thing once the six context accounts live in a lookup table, which they can,
    // because they are created at setup time and are known before the swap is assembled.
    let table = AddressLookupTableAccount {
        key: Keypair::new().pubkey(),
        addresses: [a.ctx.to_vec(), b.ctx.to_vec()].concat(),
    };
    let v0msg = v0::Message::try_compile(&payer.pubkey(), &ixs, &[table], blockhash)
        .expect("compile v0 against the lookup table");
    let v0tx = VersionedTransaction::try_new(VersionedMessage::V0(v0msg), &signers[..])
        .expect("sign v0");
    let v0bytes = bincode::serialize(&v0tx).unwrap();
    verdict("v0, six proof contexts in a lookup table", v0bytes.len());

    // Printed so the measurement can be repeated against a real cluster by anyone who doubts it:
    // this is exactly what would be submitted, minus real addresses.
    println!();
    println!("    the legacy transaction, base64:");
    println!("    {}", base64::engine::general_purpose::STANDARD.encode(&legacy));
    println!();
}

fn verdict(what: &str, size: usize) {
    let (mark, note) = if size <= LIMIT {
        ("\x1b[32m✓\x1b[0m", format!("{} bytes to spare", LIMIT - size))
    } else {
        ("\x1b[31m✗\x1b[0m", format!("{} bytes OVER", size - LIMIT))
    };
    println!("  {mark} {what}\n      \x1b[2m{size} bytes — {note}\x1b[0m");
}
