#!/usr/bin/env python3
"""getProgramAccounts for one token mint, including the mints whose answer is too big to send.

    from gpa import token_accounts
    accs = token_accounts(rpc, mint, offset=64, length=8)

WHY THIS EXISTS. `SPCX.US` is the most traded tokenized equity on Solana and was the one mint this
repository could not measure. Its account list is large enough that the public endpoint truncates
the response every time -- a partial body parses as nothing, so the scan saw an error rather than a
number -- and Alchemy refuses `getProgramAccounts` outright on the founder's plan. So the most
important mint was absent from the headline, and the absence was invisible.

HOW IT IS SOLVED. `getProgramAccounts` has no cursor, but it takes `memcmp` filters, and a token
account's OWNER sits at offset 32 and is a uniformly distributed public key. Filtering on its first
byte splits the answer into 256 disjoint slices of a few hundred accounts each. Every account has
exactly one first byte, so the union is the whole set and nothing is counted twice.

The whole-set call is tried first and the partition is a fallback, because one request beats 256
whenever the server will answer it.
"""
import base64
import json
import subprocess
import time

try:
    import base58
except ImportError as e:                      # pragma: no cover
    raise SystemExit("gpa.py needs base58: pip install base58") from e

T22 = "TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb"
OWNER_OFFSET = 32


def _call(rpc, filters, offset, length, timeout, tries):
    body = {"jsonrpc": "2.0", "id": 1, "method": "getProgramAccounts", "params": [T22, {
        "encoding": "base64", "dataSlice": {"offset": offset, "length": length},
        "filters": filters}]}
    for attempt in range(tries):
        out = subprocess.run(["curl", "-s", "--max-time", str(timeout), rpc,
                              "-H", "content-type: application/json", "-d", json.dumps(body)],
                             capture_output=True).stdout
        try:
            r = json.loads(out)
            if "result" in r:
                return r["result"]
            err = r.get("error", {}).get("message", "")
        except Exception:
            # A truncated multi-megabyte body lands here. It is not an error from the server and
            # must not be reported as one -- it is the signal to partition.
            err = "truncated at %d bytes" % len(out)
        time.sleep(2 * (attempt + 1))
    return None


def token_accounts(rpc, mint, offset=64, length=8, timeout=150, tries=3, log=None):
    """Every token account of `mint`, as a list of {"pubkey", "data", "space"}.

    `space` is the account's full size and is kept even when `length=0` asks for no data: it is how
    usage-scan.sh finds the accounts big enough to carry a ConfidentialTransferAccount, and
    dropping it silently made that filter match nothing.

    Raises RuntimeError if a slice cannot be read. A partial answer is never returned: a scan that
    silently loses a slice reports a smaller number and looks like a measurement.
    """
    mint_filter = {"memcmp": {"offset": 0, "bytes": mint}}

    whole = _call(rpc, [mint_filter], offset, length, timeout, tries)
    if whole is not None:
        return [{"pubkey": a["pubkey"], "space": a["account"].get("space"),
                 "data": base64.b64decode(a["account"]["data"][0])} for a in whole]

    if log:
        log("the whole set did not come back — partitioning by owner[0] into 256 slices")
    out, seen = [], set()
    for b in range(256):
        f = [mint_filter, {"memcmp": {"offset": OWNER_OFFSET,
                                      "bytes": base58.b58encode(bytes([b])).decode()}}]
        part = _call(rpc, f, offset, length, timeout, tries)
        if part is None:
            raise RuntimeError("slice owner[0]=%d could not be read after %d tries; refusing to "
                               "return a partial count" % (b, tries))
        for a in part:
            # Disjoint by construction, but checked rather than assumed: a duplicate would inflate
            # the very total this exists to get right.
            if a["pubkey"] in seen:
                continue
            seen.add(a["pubkey"])
            out.append({"pubkey": a["pubkey"], "space": a["account"].get("space"),
                        "data": base64.b64decode(a["account"]["data"][0])})
        if log and (b + 1) % 32 == 0:
            log("  %3d/256 slices, %d accounts so far" % (b + 1, len(out)))
    return out
