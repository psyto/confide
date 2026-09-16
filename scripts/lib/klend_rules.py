"""Kamino Lend's mint-level admissibility rules, in one place.

Transcribed from klend `a087609` (release/v1.25.0, 2026-08-18),
`programs/klend/src/utils/constraints.rs`. Every rule carries the line it came from, so that
`./scripts/kamino-verdict.sh` can fail loudly when one of those lines moves — a transcription is
only as good as the check that it still matches.

Two scripts ask this question (one mint in detail, 1,869 in bulk). They ask it here, once.
"""

# constraints.rs:42-54, SUPPORTED_LIQUIDITY_MINT_TOKEN_EXTENSIONS, keyed by the spelling
# `getAccountInfo` with `jsonParsed` uses rather than the Rust enum name.
ALLOWED_MINT_EXTENSIONS = {
    "confidentialTransferFeeConfig",
    "confidentialTransferMint",
    "mintCloseAuthority",
    "metadataPointer",
    "permanentDelegate",
    "transferFeeConfig",
    "tokenMetadata",
    "transferHook",
    "defaultAccountState",
    "scaledUiAmountConfig",
    "pausableConfig",
}

# The account-level rules are not evaluated here: they are about a *holder's* account, and the
# whole point of the verdict is that no confidential holder can satisfy them. They are
# constraints.rs:187, :194 and :201, and docs/KAMINO.md states them.

KLEND_PIN = "a08760976f51a3a58c4a0c6ea27b4a0e565bca79"
KLEND_TAG = "release/v1.25.0"


def evaluate_mint(info):
    """Would klend accept this mint as a reserve's liquidity mint?

    `info` is the `data.parsed.info` object from `getAccountInfo(..., jsonParsed)`.
    Returns `(admissible, reasons, extensions)`. `reasons` is empty when admissible.
    """
    exts = {e["extension"]: e.get("state") for e in info.get("extensions", [])}
    why = []

    for name in exts:
        if name not in ALLOWED_MINT_EXTENSIONS:
            why.append("%s is not on the allow-list (constraints.rs:42)" % name)

    # klend does NOT require the confidential-transfer extension to be present -- a legacy SPL mint
    # returns Ok immediately, and a Token-2022 mint only needs its extensions to be supported. An
    # earlier version of this function rejected a mint without it, which invented a condition the
    # source does not have. Whether the extension is present is reported separately, because it is
    # what decides if the confidentiality question arises at all, not whether klend would take it.
    ct = exts.get("confidentialTransferMint")
    if ct is not None and ct.get("autoApproveNewAccounts"):
        why.append("autoApproveNewAccounts is true (constraints.rs:131)")

    hook = exts.get("transferHook")
    if hook and hook.get("programId"):
        why.append("a transfer hook program is set (constraints.rs:121)")

    das = exts.get("defaultAccountState")
    if das and das.get("accountState") not in ("initialized", "frozen"):
        why.append("defaultAccountState is %r (constraints.rs:139)" % das.get("accountState"))

    pause = exts.get("pausableConfig")
    if pause and pause.get("paused"):
        why.append("the mint is paused (constraints.rs:152)")

    fee = exts.get("transferFeeConfig")
    if fee:
        for k in ("olderTransferFee", "newerTransferFee"):
            bps = (fee.get(k) or {}).get("transferFeeBasisPoints", 0)
            if int(bps or 0):
                why.append("the transfer fee is %s bps, not 0 (constraints.rs:107)" % bps)
                break

    return (not why), why, sorted(exts)


def has_confidential_transfers(info):
    """Separate from admissibility: does the confidentiality question even arise for this mint?"""
    return any(e["extension"] == "confidentialTransferMint" for e in info.get("extensions", []))


# ---------------------------------------------------------------------------
# Reserve layout.
#
# Derived from `programs/klend/src/state/reserve.rs` at the pin above, and then *checked against
# mainnet* rather than trusted: the first derivation put `mint_decimals` eight bytes late because
# it assumed `u128` aligns to 16. On BPF it aligns to 8. The offsets below are the ones that make
# a real reserve decode to values that are already known independently — the liquidity mint at 128
# matching the account it was fetched for, `mint_decimals` matching the mint's own decimals, and
# `borrow_factor_pct` landing on 150 rather than on 4,294,967,306,000.
#
# `scripts/kamino-reserves.sh` re-checks the mint and the decimals on every run, so a layout change
# shows up as a failure and not as a plausible wrong number.

RESERVE_DISCRIMINATOR = bytes.fromhex("2bf2ccca1af73b7f")  # sha256("account:Reserve")[:8]
RESERVE_LEN = 8624   # filtered on as well as the discriminator: a collision is implausible, but a
                     # size filter costs nothing and makes a wrong decode impossible rather than
                     # unlikely.

OFF_LENDING_MARKET = 32
OFF_LIQUIDITY = 128
OFF_LIQ_MINT = OFF_LIQUIDITY + 0
OFF_LIQ_AVAILABLE = OFF_LIQUIDITY + 96
OFF_LIQ_BORROWED_SF = OFF_LIQUIDITY + 104     # u128, scaled by 2**60
OFF_LIQ_PRICE_SF = OFF_LIQUIDITY + 120        # u128, scaled by 2**60
OFF_LIQ_DECIMALS = OFF_LIQUIDITY + 144

OFF_CONFIG = 4856                              # liquidity 1232 + pad 1200 + collateral 1096 + pad 1200
OFF_CFG_STATUS = OFF_CONFIG + 0                # 0 Active, 1 Obsolete, 2 Hidden
OFF_CFG_LTV_PCT = OFF_CONFIG + 16
OFF_CFG_LIQ_THRESHOLD_PCT = OFF_CONFIG + 17
OFF_CFG_MIN_LIQ_BONUS_BPS = OFF_CONFIG + 18
OFF_CFG_MAX_LIQ_BONUS_BPS = OFF_CONFIG + 20
OFF_CFG_BORROW_FACTOR_PCT = OFF_CONFIG + 152   # + 24 hdr + 24 fees + 88 curve
OFF_CFG_DEPOSIT_LIMIT = OFF_CONFIG + 160
OFF_CFG_BORROW_LIMIT = OFF_CONFIG + 168

SF = 2 ** 60
RESERVE_STATUS = {0: "Active", 1: "Obsolete", 2: "Hidden"}


def decode_reserve(data):
    """Decode the fields a collateral decision turns on. `data` is the raw account."""
    import struct
    u64 = lambda o: struct.unpack_from("<Q", data, o)[0]
    u16 = lambda o: struct.unpack_from("<H", data, o)[0]
    u128 = lambda o: int.from_bytes(data[o:o + 16], "little")
    dec = u64(OFF_LIQ_DECIMALS)
    unit = 10 ** dec if dec < 30 else 1
    return {
        "lending_market_raw": data[OFF_LENDING_MARKET:OFF_LENDING_MARKET + 32],
        "mint_raw": data[OFF_LIQ_MINT:OFF_LIQ_MINT + 32],
        "decimals": dec,
        "status": RESERVE_STATUS.get(data[OFF_CFG_STATUS], "unknown(%d)" % data[OFF_CFG_STATUS]),
        "ltv_pct": data[OFF_CFG_LTV_PCT],
        "liquidation_threshold_pct": data[OFF_CFG_LIQ_THRESHOLD_PCT],
        "liquidation_bonus_bps": [u16(OFF_CFG_MIN_LIQ_BONUS_BPS), u16(OFF_CFG_MAX_LIQ_BONUS_BPS)],
        "borrow_factor_pct": u64(OFF_CFG_BORROW_FACTOR_PCT),
        "deposit_limit": u64(OFF_CFG_DEPOSIT_LIMIT) / unit,
        "borrow_limit": u64(OFF_CFG_BORROW_LIMIT) / unit,
        # `total_available_amount` is the liquidity sitting in the vault, NOT what was supplied.
        # klend's own total is available + borrowed - accumulated fees, so calling this "deposited"
        # understated it by whatever is currently lent out. Both are reported, separately named.
        "available": u64(OFF_LIQ_AVAILABLE) / unit,
        "borrowed": u128(OFF_LIQ_BORROWED_SF) / SF / unit,
        "price": u128(OFF_LIQ_PRICE_SF) / SF,
    }
