#!/usr/bin/env bash
# Does the pre-signing check compare against what YOU agreed, or against what you were handed?
#
#   ./scripts/swap-pin-check.sh
#
# No chain, no keys, no RPC. Every case below is a refusal that has to happen before anything is
# signed, so all of them are reachable without a cluster — which is the point: the safety of the
# bilateral swap should not need devnet to be demonstrated.
#
# WHY THIS EXISTS. Until 2026-09-30 `swap-check` printed the decrypted amount next to the sentence
# "if that is not the amount you agreed, do not sign" and EXITED ZERO whatever the amount was, so
# all four callers went on to sign. They honoured non-zero exits; there was no non-zero exit. The
# safety of the whole flow was a human reading a number.
#
# Passing the agreed amount made it an exit code. Pinning the whole deal locally made the exit code
# mean something: the units travel inside the file the counterparty hands back, so a check fed from
# that file compares their number with their number.
#
# The cases here are the ones that do not need a proof context. The comparison itself — a leg that
# moves the wrong amount — is covered by `cargo test -p confide-ct --bin swap-check`, against a
# synthetic context, for the same reason.
set -uo pipefail
cd "$(dirname "$0")/.."
. "$(dirname "$0")/lib/chain.sh"
. "$(dirname "$0")/lib/swap.sh"

grn=$'\033[32m'; red=$'\033[31m'; dim=$'\033[2m'; bold=$'\033[1m'; off=$'\033[0m'
fail=0
ok()  { printf '  %s✓%s %s\n' "$grn" "$off" "$1"; }
bad() { printf '  %s✗%s %s\n' "$red" "$off" "$1"; fail=$((fail + 1)); }

W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
MINT_A=Xsc9qvGR1efVDFGLrVsmkzv3qi45LTBjeUKSPmx9qEh
MINT_B=SPCXxcqXj6e5dJDVNovHN8744zkbhM2bYudU45BimGb

# swap_look is where the chain would be touched. Reaching it means the refusals above it did not
# fire, so it is stubbed to record the call rather than to be exercised.
#
# TO A FILE, NOT A VARIABLE. The first version of this assigned a shell variable, and every case
# that captured output with $(...) ran the stub in a subshell — so the variable was always empty in
# the parent and "did this reach the signing path?" could not fail. Two of the refusal tests were
# passing vacuously. A file crosses the subshell boundary; a variable does not.
swap_look() { printf '%s' "$*" > "$W/reached"; return 0; }
reached() { cat "$W/reached" 2>/dev/null || true; }
arm()     { rm -f "$W/reached"; }
# DELIBERATELY WRONG, and that is what makes the two paths tell apart. The pinned path must take
# decimals from the pin (8); only the unpinned path may ask the mint. Stubbing this to 8 as well --
# which the first version did -- made "did it use the pin?" unobservable, because every route
# produced the same answer.
#
# The other half of that guarantee, whether the pinned UNITS are used rather than the handed-back
# ones, is not independently observable here and should not be faked: the terms-changed refusal
# above forces the two to be equal before this line is reached, so substituting one for the other
# changes nothing. What protects it is that refusal, and removing the refusal DOES fail this file.
swap_mint_decimals() { echo 99; }

echo
echo "  ${bold}UNITS TO BASE UNITS — one conversion, because two would disagree${off}"
[ "$(swap_base_units 20000 8)" = 2000000000000 ] \
  && ok "20,000 at 8 decimals is 2,000,000,000,000" \
  || bad "20,000 at 8 decimals came out as $(swap_base_units 20000 8)"
[ "$(swap_base_units 3500000 6)" = 3500000000000 ] \
  && ok "3,500,000 at 6 decimals is 3,500,000,000,000" \
  || bad "3,500,000 at 6 decimals came out as $(swap_base_units 3500000 6)"
# The injection this repository actually had: an offer whose units field was Python.
swap_base_units '1)+__import__("os").system("touch '"$W"'/pwned")#' 8 >/dev/null 2>&1
[ -f "$W/pwned" ] && bad "a units field executed code" || ok "a units field that is code is refused, not run"
swap_base_units "-5" 8 >/dev/null 2>&1 && bad "a negative unit count was accepted" \
                                       || ok "a negative unit count is refused"
swap_base_units "" 8 >/dev/null 2>&1 && bad "an empty unit count was accepted" \
                                     || ok "an empty unit count is refused"

echo
echo "  ${bold}THE PIN — the whole deal, written by your own machine${off}"
mkoffer() { # mkoffer <out> <id> <give-units> <want-units>
  python3 - "$1" "$2" "$3" "$4" "$MINT_A" "$MINT_B" <<'PY'
import json, sys
out, oid, gu, wu, ma, mb = sys.argv[1:7]
d = {"kind": "confide-swap-offer", "version": 1, "id": (None if oid == "-" else oid),
     "offerer": {"payer": "9ofErEr11111111111111111111111111111111111",
                 "give": {"mint": ma, "account": "9giVe111111111111111111111111111111111111", "units": int(gu)},
                 "want": {"mint": mb, "account": "9waNt111111111111111111111111111111111111", "units": int(wu),
                          "elgamal_pubkey_b64": "AA=="}}}
if oid == "-":
    del d["id"]
json.dump(d, open(out, "w"), indent=1)
PY
}

ID=deadbeefdeadbeef
mkoffer "$W/offer.json" "$ID" 100 17500
swap_pin_terms "$ID" "$W/offer.json" 8 6 >/dev/null 2>&1 \
  && ok "the whole deal pins from the offer file" \
  || bad "a well-formed pin was refused"
swap_read_terms "$ID" >/dev/null 2>&1 \
  && ok "and it reads back" \
  || bad "the pin does not read back"
swap_read_terms 0000000000000000 >/dev/null 2>&1 \
  && bad "an unpinned offer id reported terms" \
  || ok "an unpinned offer id reports nothing rather than zero"
swap_pin_terms "../../etc/whatever" "$W/offer.json" 8 6 >/dev/null 2>&1 \
  && bad "an offer id containing a path was accepted" \
  || ok "an offer id that is a path is refused"
# The pin must describe the offer it claims to, not whichever file was handy.
mkoffer "$W/other.json" cafebabecafebabe 100 17500
swap_pin_terms "$ID" "$W/other.json" 8 6 >/dev/null 2>&1 \
  && bad "a pin was written from an offer with a different id" \
  || ok "a pin whose id disagrees with the offer file is refused"
# and it must be written whole or not at all
[ -f "$W/terms-$ID.json.tmp" ] && bad "a half-written pin was left behind" \
                               || ok "no partial pin is left behind"

echo
echo "  ${bold}STEP 3 AND 4 — the two bypasses Codex found, as tests${off}"
arm; out=$(swap_look_pinned /dev/null /dev/null "$ID" "$W/offer.json" want 2>&1)
[ "$(reached)" = "/dev/null /dev/null 17500 6" ] \
  && ok "matching terms: units AND decimals come from the pin, not from the chain or the file" \
  || bad "the pinned path did not use the pin: '$(reached)'"

# BYPASS 1 — strip the id and the old code fell through to a warning and a pass.
mkoffer "$W/noid.json" "-" 100 17500
arm; out=$(swap_look_pinned /dev/null /dev/null "-" "$W/noid.json" want 2>&1)
if [ -n "$(reached)" ]; then
  bad "AN OFFER WITH THE ID STRIPPED REACHED THE SIGNING PATH"
elif printf '%s' "$out" | grep -q "NO PINNED TERMS"; then
  ok "stripping the id is a REFUSAL, not a warning"
else
  bad "a stripped id was refused without saying why: $out"
fi

# BYPASS 2 — raise what the OFFERER GIVES while paying the agreed amount.
mkoffer "$W/greedy.json" "$ID" 1000 17500
arm; out=$(swap_look_pinned /dev/null /dev/null "$ID" "$W/greedy.json" want 2>&1)
if [ -n "$(reached)" ]; then
  bad "A RAISED OUTGOING LEG REACHED THE SIGNING PATH — pinned 100, file said 1,000"
elif printf '%s' "$out" | grep -q "offerer.give.units"; then
  ok "raising what you GIVE is refused, even though what you receive is correct"
else
  bad "a raised give leg was refused without naming the field: $out"
fi

# and the received side, which is the case the first version covered
mkoffer "$W/short.json" "$ID" 100 1750
arm; out=$(swap_look_pinned /dev/null /dev/null "$ID" "$W/short.json" want 2>&1)
if [ -n "$(reached)" ]; then
  bad "ALTERED RECEIVE TERMS REACHED THE SIGNING PATH"
elif printf '%s' "$out" | grep -q "offerer.want.units"; then
  ok "lowering what you RECEIVE is refused"
else
  bad "altered receive terms were refused without naming the field: $out"
fi

# a swapped mint
python3 -c "
import json,sys
d=json.load(open(sys.argv[1]));d['offerer']['want']['mint']='$MINT_A';json.dump(d,open(sys.argv[1],'w'))" "$W/offer.json"
arm; out=$(swap_look_pinned /dev/null /dev/null "$ID" "$W/offer.json" want 2>&1)
if [ -n "$(reached)" ]; then
  bad "A DIFFERENT MINT REACHED THE SIGNING PATH"
elif printf '%s' "$out" | grep -q "offerer.want.mint"; then
  ok "a different mint than you pinned is refused"
else
  bad "a different mint was refused without naming the field: $out"
fi
mkoffer "$W/offer.json" "$ID" 100 17500

# a moved destination account, which is where a delivery would land
python3 -c "
import json,sys
d=json.load(open(sys.argv[1]))
d['offerer']['give']['account']='9eLsewhere11111111111111111111111111111111'
json.dump(d,open(sys.argv[1],'w'))" "$W/offer.json"
arm; out=$(swap_look_pinned /dev/null /dev/null "$ID" "$W/offer.json" want 2>&1)
printf '%s' "$out" | grep -q "offerer.give.account" && [ -z "$(reached)" ] \
  && ok "a moved account is refused" \
  || bad "a moved account was not refused: $out"
mkoffer "$W/offer.json" "$ID" 100 17500

# The override. It must proceed, and it must say the figure is not yours.
arm; out=$(CONFIDE_UNPINNED=1 swap_look_pinned /dev/null /dev/null "-" "$W/noid.json" want 2>&1)
# 99 is the deliberately-wrong stub: the unpinned path has no pin to take decimals from, so it
# must ask the mint. That it differs from the pin's 6 is what makes the two paths distinguishable.
[ "$(reached)" = "/dev/null /dev/null 17500 99" ] \
  && ok "CONFIDE_UNPINNED=1 proceeds, comparing against the counterparty's own figure" \
  || bad "the override did not compare anything: '$(reached)'"
printf '%s' "$out" | grep -q "COUNTERPARTY'S OWN CLAIM" \
  && ok "and it says whose figure that is" \
  || bad "the override did not say the figure is not yours: $out"

echo
echo "  ${bold}THE CALL SITES — a regression here is silent, so it is read rather than trusted${off}"
# The defect was not in swap-check. It was that every caller ignored what swap-check said. Behaviour
# tests cannot see that: they exercise the function, and the bug lived in the four lines that call
# it. So this reads the call sites, the way wire-check.sh reads account counts instead of running a
# transaction.
python3 - <<'PY'
import pathlib, re, sys

# who is expected to call which form, and with how many arguments
WANT = {
    "scripts/issue-e2e.sh":  ("swap_look",        4),
    "scripts/swap-e2e.sh":   ("swap_look",        4),  # via look(), which forwards $4 $5
    "scripts/swap-settle.sh": ("swap_look_pinned", 5),
    "scripts/swap-sign.sh":  ("swap_look_pinned", 5),
}
bad = []
for f, (fn, argc) in sorted(WANT.items()):
    t = pathlib.Path(f).read_text(encoding="utf-8")
    calls = [(i, l.strip()) for i, l in enumerate(t.splitlines(), 1)
             if re.search(r"^\s*(if\s+)?swap_look(_pinned)?\s", l)]
    if not calls:
        bad.append("%s calls neither swap_look nor swap_look_pinned any more" % f); continue
    for i, l in calls:
        name = "swap_look_pinned" if "swap_look_pinned" in l else "swap_look"
        if name != fn:
            bad.append("%s:%d calls %s; this flow needs %s" % (f, i, name, fn)); continue
        # argv after the function name. Quoted "$X" tokens and bare words both count.
        args = re.sub(r"^\s*(if\s+)?%s\s+" % name, "", l)
        args = re.sub(r";.*$", "", args).strip()
        n = len(re.findall(r'"[^"]*"|\S+', args))
        if n < argc:
            bad.append("%s:%d passes %d arguments to %s, so nothing is compared: %s"
                       % (f, i, n, name, l[:70]))
        if "|| true" in l or "2>/dev/null" in l:
            bad.append("%s:%d discards the result of %s: %s" % (f, i, name, l[:70]))

# ...and a WRAPPER's call sites. issue-e2e.sh reaches swap_look through look(), which copies the
# checker's output for the demo app. The wrapper forwarding four arguments proves nothing if a caller
# hands it two, so its call sites are read the same way (added 2026-09-30, when the wrapper was).
WRAPPED = {"scripts/issue-e2e.sh": ("look", 4)}
for f, (fn, argc) in sorted(WRAPPED.items()):
    t = pathlib.Path(f).read_text(encoding="utf-8")
    calls = [(i, l.strip()) for i, l in enumerate(t.splitlines(), 1)
             if re.search(r"(^\s*(if\s+)?|;\s*)%s\s" % fn, l) and not re.search(r"^\s*%s\(\)" % fn, l)]
    if not calls:
        bad.append("%s no longer calls %s" % (f, fn))
    for i, l in calls:
        args = re.sub(r"^.*?\b%s\s+" % fn, "", l)
        args = re.sub(r";.*$", "", args).strip()
        n = len(re.findall(r'"[^"]*"|\S+', args))
        if n < argc:
            bad.append("%s:%d passes %d arguments to %s, so nothing is compared: %s" % (f, i, n, fn, l[:70]))
        if "|| true" in l or "2>/dev/null" in l:
            bad.append("%s:%d discards the result of %s: %s" % (f, i, fn, l[:70]))

# and the library must not throw the refusal away
lib = pathlib.Path("scripts/lib/swap.sh").read_text(encoding="utf-8")
for i, l in enumerate(lib.splitlines(), 1):
    if "bin swap-check" in l and "2>/dev/null" in l:
        bad.append("scripts/lib/swap.sh:%d sends swap-check's refusal to /dev/null" % i)

for b in bad:
    print("      " + b)
sys.exit(1 if bad else 0)
PY
if [ $? -eq 0 ]; then
  ok "all four callers pass an agreed amount and keep the exit code"
else
  bad "a caller of the pre-signing check ignores it — that was the whole defect"
fi

# THE JSON-TO-SHELL HANDOFF. Each of these reads a counterparty's file and hands the values to
# `read -r`. One field added on one side and not the other shifts everything after it, silently and
# by one position: a mint address lands in a units variable. It is now one validated unpacker
# (scripts/lib/swapjson.py) rather than three inline print()s, so what this compares is the number of
# names the shell reads against the number of paths the unpacker was asked for.
python3 - <<'PY'
import pathlib, re, sys
bad = []
for f in ["scripts/swap-accept.sh", "scripts/swap-settle.sh", "scripts/swap-sign.sh"]:
    t = pathlib.Path(f).read_text(encoding="utf-8")
    m = re.search(r"read -r ([A-Za-z_0-9 ]+?)\s*<\s*<\(\n(.*?)\n\)", t, re.S)
    if not m:
        bad.append("%s no longer unpacks a counterparty file into a read -r" % f); continue
    names = m.group(1).split()
    call = m.group(2)
    if "scripts/lib/swapjson.py" not in call:
        bad.append("%s unpacks without the validator — a value with a space in it shifts the fields" % f)
        continue
    # the dotted paths and the bare "id", after the file and the expected kind
    toks = [x for x in re.split(r"\s+|\\\n", call) if x and not x.startswith("#")]
    toks = toks[toks.index("scripts/lib/swapjson.py") + 3:]
    paths = [x for x in toks if re.fullmatch(r"[a-z_]+(\.[a-z_0-9]+)*", x)]
    if len(names) != len(paths):
        bad.append("%s: read -r takes %d names and the unpacker is asked for %d fields — every "
                   "value after the difference lands in the wrong variable"
                   % (f, len(names), len(paths)))
    if "|| exit 1" not in t[t.index(call):t.index(call) + len(call) + 40]:
        bad.append("%s does not stop when the unpacker refuses a field" % f)
for b in bad:
    print("      " + b)
sys.exit(1 if bad else 0)
PY
if [ $? -eq 0 ]; then
  ok "every counterparty file goes through the validator, into as many names as it asks for"
else
  bad "the JSON-to-shell handoff can shift a field"
fi

echo
if [ "$fail" -eq 0 ]; then
  printf '  %s%sthe pre-signing check compares against what you agreed%s\n' "$grn" "$bold" "$off"
  printf '  %sthe comparison itself: cargo test -p confide-ct --bin swap-check%s\n\n' "$dim" "$off"
else
  printf '  %s%s%d disagreements%s\n\n' "$red" "$bold" "$fail" "$off"
fi
exit "$fail"
