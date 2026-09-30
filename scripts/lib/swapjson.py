"""Unpack a counterparty's swap JSON into shell variables, validating every field first.

    python3 scripts/lib/swapjson.py <file> <expected-kind> <dotted.path> [...]

Prints the values space-separated, in the order asked for, for `read -r` to consume.

WHY THIS IS NOT INLINE IN THE THREE SCRIPTS ANY MORE. swap-accept.sh, swap-settle.sh and
swap-sign.sh each had their own `python3 - <<PY` block printing a different set of fields into a
`read -r`. Two problems, both found on 2026-09-30:

  * **The transport is whitespace-delimited and nothing validated it.** A value containing a space
    silently shifts every field after it, so a mint address lands in a units variable and an account
    address lands in a mint variable. There is no error: the shell just reads the wrong things, and
    what the offerer then builds a leg from is whatever ended up in that slot. Codex called it, and
    the fix has to be at the boundary rather than after it.

  * **Adding a field meant editing a print() and a `read -r` in three files.** Fields were added to
    all three that day for the terms pin, which is exactly when an off-by-one arrives.

So: every value is checked against what its name says it is before anything is printed, and a value
that cannot be a shell field is a hard failure rather than a shift. Addresses are base58 of the
right length, unit counts are non-negative integers inside u64, ids are sixteen hex characters,
ElGamal keys are base64. Nothing is quoted or escaped on the way out, because nothing that needs
quoting is allowed through.
"""

import json
import re
import sys

BASE58 = re.compile(r"^[1-9A-HJ-NP-Za-km-z]{32,44}$")
HEX16 = re.compile(r"^[0-9a-f]{16}$")
B64 = re.compile(r"^[A-Za-z0-9+/]+={0,2}$")
U64_MAX = 2**64 - 1

# The leaf name decides the rule. "mint", "account" and "payer" are addresses; "units" is a count.
# Keyed on the last path element so a new field cannot arrive unvalidated by being spelled
# differently -- an unknown leaf name is refused rather than passed through.
ADDRESS = {"mint", "account", "payer"}
COUNT = {"units", "decimals"}
OPAQUE_B64 = {"elgamal_pubkey_b64"}
FREE = {"id"}


def die(m):
    sys.exit("  %s" % m)


def dig(d, path):
    """Walk a dotted path. A missing step is a failure, not a None that prints as 'None'."""
    cur = d
    for step in path.split("."):
        if not isinstance(cur, dict) or step not in cur:
            die("%s is missing from this file" % path)
        cur = cur[step]
    return cur


def check(path, v):
    leaf = path.rsplit(".", 1)[-1]
    if leaf in ADDRESS:
        if not isinstance(v, str) or not BASE58.match(v):
            die("%s is not a base58 address: %r" % (path, v))
        return v
    if leaf in COUNT:
        # A float, a bool or a string of digits with a space in it are all refused. bool is a
        # subclass of int in Python, so it is excluded explicitly.
        if isinstance(v, bool) or not isinstance(v, int):
            if not (isinstance(v, str) and v.isdigit()):
                die("%s is not a whole number: %r" % (path, v))
            v = int(v)
        if v < 0 or v > U64_MAX:
            die("%s is outside what the chain can carry: %r" % (path, v))
        return str(v)
    if leaf in OPAQUE_B64:
        if not isinstance(v, str) or not B64.match(v):
            die("%s is not base64: %r" % (path, v))
        return v
    if leaf in FREE:
        # An offer written before ids existed has none, and that must arrive as a value rather than
        # as an empty field -- an empty field shifts everything after it.
        if v is None:
            return "-"
        if not isinstance(v, str) or not HEX16.match(v):
            die("the offer id is not sixteen hex characters: %r" % (v,))
        return v
    die("%s has no validation rule; add one rather than passing it through" % path)


def main():
    if len(sys.argv) < 4:
        die("usage: swapjson.py <file> <expected-kind> <dotted.path> [...]")
    path, kind, wanted = sys.argv[1], sys.argv[2], sys.argv[3:]
    try:
        d = json.load(open(path, encoding="utf-8"))
    except (OSError, ValueError) as e:
        die("%s is not readable JSON: %s" % (path, e))
    if not isinstance(d, dict):
        die("%s is not a swap document" % path)
    if d.get("kind") != kind:
        die("%s says kind=%r; this step needs %r" % (path, d.get("kind"), kind))
    out = []
    for w in wanted:
        # "id" is optional by design; everything else must be present.
        v = d.get("id") if w == "id" else dig(d, w)
        out.append(check(w, v))
    print(" ".join(out))


if __name__ == "__main__":
    main()
