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

    ct = exts.get("confidentialTransferMint")
    if ct is None:
        why.append("no confidentialTransferMint — nothing here to keep confidential")
    elif ct.get("autoApproveNewAccounts"):
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
