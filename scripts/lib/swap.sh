# Building one leg of a confidential swap, and reading the other.
#
# Sourced by scripts/swap-e2e.sh (both legs on one machine, the demonstration) and by
# scripts/swap-offer.sh / swap-accept.sh / swap-settle.sh (one leg each, two machines, the trade).
#
# Requires: scripts/lib/chain.sh already sourced, and $W (work dir) and $R (RPC) set.
#
# WHY IT MOVED HERE. These were functions inside swap-e2e.sh, which meant the only way to build a
# leg was to run the demonstration -- and the demonstration holds both parties' keys. A trade never
# does. One difference matters and is the whole reason this is not a copy: `swap_leg` takes the
# counterparty's ElGamal PUBKEY as a string, where the original read it out of their key FILE. In a
# real swap you have their public key and nothing else.

# swap_mint_decimals <mint> -- off the mint, not off a file.
swap_mint_decimals() {
  rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getAccountInfo\",\"params\":[\"$1\",{\"encoding\":\"jsonParsed\"}]}" \
    | python3 -c "import sys,json;print(json.load(sys.stdin)['result']['value']['data']['parsed']['info']['decimals'])"
}

# swap_session <offer-id> [create] -- the per-offer directory.
#
# It does NOT create unless asked. swap-abandon.sh only resolves a path to read, and the first
# version made a directory as a side effect of being asked where one would be -- so looking for a
# session created an empty one.
#
# ONE DIRECTORY PER OFFER. accept-ctx.json, their-ctx.json, settle-ctx.json, half.b64 and
# unsigned.b64 all lived at fixed names under $W, which is ~/.config/confide/swap/<cluster> and is
# shared by every offer this machine touches. Two offers in flight, or one resumed after another was
# started, overwrote each other's proof contexts and half-signed transactions -- and the thing that
# gets overwritten is what the next step signs. Codex, 2026-09-30. The same shape as the context-key
# collision it found on 09-22, one level up.
#
# An offer with no id gets the old shared directory, which is what it had before; that path now
# refuses at the terms check unless CONFIDE_UNPINNED=1, so nothing silently relies on it.
swap_session() {
  case "${1:-}" in
    ''|-|*[!0-9a-f]*) printf '%s' "$W"; return 0 ;;
  esac
  if [ "${2:-}" = create ]; then
    mkdir -p "$W/offer-$1" || return 1
    chmod 700 "$W/offer-$1" 2>/dev/null || true
  fi
  printf '%s' "$W/offer-$1"
}

# swap_pin_terms  <offer-id> <offer.json> <give-decimals> <want-decimals>
# swap_read_terms <offer-id>                     -> the pin's JSON path, or nothing
# swap_verify_terms <offer-id> <returned.json>   -> refuses if any canonical field moved
#
# THE WHOLE DEAL, RECORDED ON YOUR OWN MACHINE AT THE MOMENT YOU AGREED IT.
#
# Both legs, both accounts, both unit counts, the offerer's payer and the id. Not just what you
# expect to receive -- that was the first version of this, on 2026-09-30, and Codex found two ways
# through it the same day:
#
#   1. THE OFFERER'S OUTGOING LEG WAS NEVER PINNED. swap-settle.sh takes `offerer.give.units` out of
#      the accept.json the acceptor hands back and builds the offerer's own leg from it. An acceptor
#      can raise it from 100 to 1,000 while paying exactly the pinned amount: the received-leg check
#      passes and the offerer signs away ten times the asset. Checking what arrives is half a trade.
#
#   2. STRIPPING THE ID FORCED THE UNPINNED PATH. The id was read from the returned file, and a
#      missing pin fell through to comparing against that same file's numbers with a red warning.
#      So the attacker deleted the id, lowered the units, and the "check" compared its own values.
#      A warning is the control this was built to remove: notice the number.
#
# So the pin is the canonical terms, a missing pin is a REFUSAL, and CONFIDE_UNPINNED=1 is the only
# way past it -- named, so that taking it is a decision somebody made rather than a default.
swap_pin_terms() {
  case "$1" in ''|*[!0-9a-f]*) echo "  not an offer id: $1" >&2; return 2;; esac
  [ -f "$2" ] || { echo "  no such offer file: $2" >&2; return 2; }
  case "$3" in ''|*[!0-9]*) echo "  give-decimals must be a number, got: $3" >&2; return 2;; esac
  case "$4" in ''|*[!0-9]*) echo "  want-decimals must be a number, got: $4" >&2; return 2;; esac
  # Written to a temporary name and renamed, so an interrupted write cannot leave a half-pin that
  # the next step reads as the terms.
  python3 - "$W/terms-$1.json" "$1" "$2" "$3" "$4" <<'PY'
import json, os, sys, time
out, oid, offer, gdec, wdec = sys.argv[1:6]
d = json.load(open(offer))
o = d["offerer"]
if d.get("id") != oid:
    sys.exit("  the offer file's id is %r, not %r" % (d.get("id"), oid))
terms = {
    "note": "The whole deal, as YOU agreed it, written by your own machine before any proof or "
            "signature existed. swap-settle.sh and swap-sign.sh compare the file their counterparty "
            "hands back against this, field by field, and refuse on any difference.",
    "pinned_utc": time.strftime("%Y-%m-%d %H:%M:%S UTC", time.gmtime()),
    "id": oid,
    "offerer": {
        "payer": o["payer"],
        "give": {"mint": o["give"]["mint"], "account": o["give"]["account"],
                 "units": int(o["give"]["units"]), "decimals": int(gdec)},
        "want": {"mint": o["want"]["mint"], "account": o["want"]["account"],
                 "units": int(o["want"]["units"]), "decimals": int(wdec)},
    },
}
tmp = out + ".tmp"
with open(tmp, "w") as f:
    json.dump(terms, f, indent=1, sort_keys=True)
os.replace(tmp, out)
PY
}

swap_read_terms() {
  case "$1" in ''|*[!0-9a-f]*) return 1;; esac
  local f="$W/terms-$1.json"
  [ -f "$f" ] || return 1
  python3 -c "import json,sys;json.load(open(sys.argv[1]))" "$f" 2>/dev/null || return 1
  printf '%s' "$f"
}

# swap_verify_terms <offer-id> <returned.json>
#
# Every canonical field, not the one you happen to be receiving. Prints each difference and refuses.
swap_verify_terms() {
  local f
  f=$(swap_read_terms "$1") || return 1
  python3 - "$f" "$2" <<'PY'
import json, sys
pin = json.load(open(sys.argv[1]))
got = json.load(open(sys.argv[2]))
p, g = pin["offerer"], got.get("offerer", {})
bad = []
if got.get("id") != pin["id"]:
    bad.append("the id: you pinned %r and the file says %r" % (pin["id"], got.get("id")))
if g.get("payer") != p["payer"]:
    bad.append("the offerer: %s -> %s" % (p["payer"], g.get("payer")))
for side in ("give", "want"):
    for field in ("mint", "account", "units"):
        want = p[side][field]
        have = g.get(side, {}).get(field)
        if field == "units":
            try:
                have = int(have)
            except (TypeError, ValueError):
                pass
        if have != want:
            bad.append("offerer.%s.%s: you agreed %r and the file says %r" % (side, field, want, have))
if bad:
    print("  \x1b[31m✗\x1b[0m THE TERMS WERE CHANGED. Nothing has been signed. Do not sign.",
          file=sys.stderr)
    for b in bad:
        print("      " + b, file=sys.stderr)
    sys.exit(1)
PY
}

# swap_look_pinned <my-receiving-keys.json> <their-ctx.json> <offer-id> <returned.json> <side>
#
# <side> is which half of the canonical terms you are RECEIVING: "want" for the offerer (step 3),
# "give" for the acceptor (step 4), because the acceptor receives what the offerer gives.
swap_look_pinned() {
  local keys="$1" ctx="$2" id="$3" file="$4" side="$5" f
  if ! f=$(swap_read_terms "$id"); then
    if [ "${CONFIDE_UNPINNED:-}" = 1 ]; then
      echo "  \033[31m!\033[0m CONFIDE_UNPINNED=1 — no local record of what you agreed exists for" >&2
      echo "    offer id '${id:-<none>}', so the figure below is your COUNTERPARTY'S OWN CLAIM." >&2
      echo "    Compare it against what you agreed, yourself, from outside this machine." >&2
      local u m
      u=$(python3 -c "
import json,sys
print(json.load(open(sys.argv[1]))['offerer'][sys.argv[2]]['units'])" "$file" "$side")
      m=$(python3 -c "
import json,sys
print(json.load(open(sys.argv[1]))['offerer'][sys.argv[2]]['mint'])" "$file" "$side")
      swap_look "$keys" "$ctx" "$u" "$(swap_mint_decimals "$m")"
      return
    fi
    echo "  \033[31m✗\033[0m NO PINNED TERMS for offer id '${id:-<none>}'." >&2
    echo "    This machine has no record of what you agreed, so there is nothing to compare the" >&2
    echo "    encrypted amount against, and the only figures available are your counterparty's." >&2
    echo "    That is what an attacker arranges: strip the id, lower the amount, let the check" >&2
    echo "    compare their number with their number." >&2
    echo "    Run steps 1-2 on this machine, or set CONFIDE_UNPINNED=1 to proceed unprotected." >&2
    return 1
  fi
  swap_verify_terms "$id" "$file" || return 1
  local u d
  read -r u d < <(python3 -c "
import json,sys
s=json.load(open(sys.argv[1]))['offerer'][sys.argv[2]]
print(s['units'], s['decimals'])" "$f" "$side")
  swap_look "$keys" "$ctx" "$u" "$d"
}

# swap_base_units <units> <decimals> -- display units to the integer the chain moves.
#
# ONE PLACE. swap_leg builds a leg from this and swap_look compares against it; if the two ever
# computed it differently the check would pass a leg that moves the wrong amount, or fail one that
# is correct, and both readings would look like a cryptography problem.
#
# Passed as ARGV, never interpolated. argv is data; a -c string is code -- an offer whose "units"
# field was a fragment of Python once ran arbitrary code here (Codex, 2026-09-22).
swap_base_units() {
  case "$1" in ''|*[!0-9]*) echo "  units must be a whole number, got: $1" >&2; return 2;; esac
  case "$2" in ''|*[!0-9]*) echo "  decimals must be a number, got: $2" >&2; return 2;; esac
  python3 -c 'import sys;print(int(sys.argv[1])*10**int(sys.argv[2]))' "$1" "$2"
}

# swap_leg <who> <payer.json> <my-keys.json> <mint> <source> <dest> <their-elgamal-b64> \
#          <send-units> <decimals> <ctx-out.json>
#
# Three proofs, or five on a mint that charges a transfer fee, verified into context state accounts
# that this party owns. Expensive and multi-transaction, and it happens BEFORE the swap -- which is
# exactly what makes the exchange itself small enough to be one transaction.
swap_leg() {
  local who="$1" payer="$2" mykeys="$3" mint="$4" src="$5" dst="$6" their_elg="$7"
  local send="$8" dec_n="$9" ctxf="${10}"

  # ONE DIRECTORY PER ATTEMPT. The context keypairs used to live at a fixed `$W/<who>-keys`, and the
  # accept and settle steps both passed a constant `who`. So a second attempt generated the same
  # context addresses, found them already on chain, and died on the create -- the failure mode was
  # "this swap can never be retried", which is the worst possible one to hit when the first attempt
  # was abandoned. Codex, 2026-09-22.
  #
  # The suffix has to be stable ACROSS the batch loop below, which re-enters `cx` against a fresh
  # blockhash and must address the same contexts, and different BETWEEN invocations. Computed once,
  # here, and recorded in ctx.json so swap-abandon.sh can find the keys and reclaim the rent.
  local kdir="$W/$who-keys-$(date -u +%Y%m%dT%H%M%S)-$$"
  mkdir -p "$kdir"; chmod 700 "$kdir" 2>/dev/null || true

  # EVERY ONE OF THESE COMES FROM A COUNTERPARTY'S FILE. The first version interpolated the unit
  # count straight into a `python3 -c` string, so an offer whose "units" field was a fragment of
  # Python ran arbitrary code on the victim's machine before anything was signed. Demonstrated,
  # not theorised -- Codex found it, docs/reviews/2026-09-22-two-party-swap.md.
  #
  # So: validate shape here, at the boundary, and never build code out of a value again. Addresses
  # are base58 and amounts are decimal integers; anything else is refused before it is used.
  case "$send"  in ''|*[!0-9]*) echo "  units must be a whole number, got: $send" >&2; return 2;; esac
  case "$dec_n" in ''|*[!0-9]*) echo "  decimals must be a number, got: $dec_n" >&2; return 2;; esac
  local a
  for a in "$mint" "$src" "$dst"; do
    case "$a" in
      ""|*[!1-9A-HJ-NP-Za-km-z]*) echo "  not a base58 address: $a" >&2; return 2;;
    esac
    [ ${#a} -ge 32 ] && [ ${#a} -le 44 ] || { echo "  address is the wrong length: $a" >&2; return 2; }
  done
  case "$their_elg" in
    ""|*[!A-Za-z0-9+/=]*) echo "  not a base64 ElGamal key: $their_elg" >&2; return 2;;
  esac
  local base_units
  base_units=$(swap_base_units "$send" "$dec_n") || return 2
  local dec avail pub owner aud alt range me
  read -r dec avail pub owner < <(ct "$src")
  me=$(solana-keygen pubkey "$payer")

  # READ THE AUDITOR OFF THE MINT, not off a file. The extracted version looked for
  # $W/auditor-$who.json, which the demonstration happened to create and the bilateral scripts
  # never do -- so a bilateral swap on a mint that DOES name an auditor would have silently proved
  # `none` and been rejected by Token-2022. It works today only because all 1,992 tokenized-equity
  # mints leave the slot null, which is the finding this repository is built on and a poor thing to
  # depend on. Codex found it, 2026-09-22.
  #
  # The mint is the authority on its own auditor. A file cannot be stale if it is not consulted.
  aud=$(rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getAccountInfo\",\"params\":[\"$mint\",{\"encoding\":\"jsonParsed\"}]}" \
        | python3 -c "
import sys, json
v = json.load(sys.stdin).get('result', {}).get('value')
e = {x['extension']: x.get('state', {}) for x in v['data']['parsed']['info'].get('extensions', [])}
k = e.get('confidentialTransferMint', {}).get('auditorElgamalPubkey')
print(k if k else 'none')")
  [ -n "$aud" ] || aud=none

  # Five proofs on a fee-bearing mint, three otherwise, and the MINT decides rather than a flag: a
  # transferFeeConfig makes Token-2022 refuse the plain Transfer even at 0 bps.
  if [ "$(mint_charges_fee "$mint")" = fee ]; then
    local wh bps maxf
    read -r wh bps maxf < <(rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getAccountInfo\",\"params\":[\"$mint\",{\"encoding\":\"jsonParsed\"}]}" \
      | python3 -c "
import sys,json
i=json.load(sys.stdin)['result']['value']['data']['parsed']['info']
e={x['extension']:x.get('state',{}) for x in i.get('extensions',[])}
f=e['transferFeeConfig']['newerTransferFee']
print(e['confidentialTransferFeeConfig']['withdrawWithheldAuthorityElgamalPubkey'],
      f['transferFeeBasisPoints'], f['maximumFee'])")
    cx() { cargo run --quiet -p confide-ct --bin swap-ctx-fee -- "$payer" "$mykeys" \
      "$dec" "$avail" "$their_elg" "$aud" "$wh" "$bps" "$maxf" \
      "$base_units" "$(bh)" "$ctxf" "$me" "$kdir" "$1" "${2:-0}"; }
  else
    cx() { cargo run --quiet -p confide-ct --bin seizure-ctx -- "$payer" "$mykeys" \
      "$dec" "$avail" "$their_elg" "$aud" \
      "$base_units" "$(bh)" "$ctxf" "$me" "$kdir" "$1" none; }
  fi

  cx none >/dev/null 2>"$W/$who-pass1.err" || { cat "$W/$who-pass1.err" >&2; return 1; }
  range=$(python3 -c "import json;print(json.load(open('$ctxf'))['range'])")
  alt=$(solana -u "$R" -k "$payer" address-lookup-table create --authority "$me" \
        | grep -oE 'Lookup Table Address: [1-9A-HJ-NP-Za-km-z]{32,44}' | awk '{print $NF}')
  # The with-fee range proof is verified FROM an account, so the record holding it goes in the
  # table too. A missing address there is not an error -- it is an account resolved the long way.
  local rec; rec=$(python3 -c "import json;d=json.load(open('$ctxf'));print(d.get('record',''))")
  solana -u "$R" -k "$payer" address-lookup-table extend "$alt" \
    --addresses "$range,$me${rec:+,$rec}" >/dev/null
  sleep 3
  cx "$alt" > "$W/$who-txs.txt" 2>"$W/$who-pass2.err"

  # Sent in batches, because a blockhash does not live long enough for fourteen of them -- the
  # thirteenth came back BlockhashNotFound. Each batch is rebuilt against a fresh blockhash; the
  # proofs are cached on disk, so rebuilding re-signs rather than re-proves, and `skip` keeps the
  # already-landed creates from being sent twice.
  #
  # Only the with-fee path is rebuilt between batches, because only it caches. Running seizure-ctx
  # again would generate DIFFERENT proofs for the same context accounts.
  local n=0 out sent=0 batch=99
  [ "$(python3 -c "import json;print(1 if json.load(open('$ctxf')).get('with_fee') else 0)")" = 1 ] && batch=5
  while :; do
    local inbatch=0
    while read -r TX; do
      [ "$inbatch" -lt "$batch" ] || break
      n=$((n+1)); inbatch=$((inbatch+1))
      out=$(go "$who proof tx $n" "$TX") || { printf '%s\n' "$out" >&2; return 1; }
    done < "$W/$who-txs.txt"
    sent=$((sent+inbatch))
    [ "$inbatch" -eq "$batch" ] || break
    cx "$alt" "$sent" > "$W/$who-txs.txt" 2>"$W/$who-pass2.err"
    [ -s "$W/$who-txs.txt" ] || break
  done
  # The table and the key directory go into ctx.json because they are the only record of them, and
  # without it the rent they hold is unrecoverable -- swap-abandon.sh had to say "this leg did not
  # record its table" the first time it ran. Written with json.dump rather than appended as text, so
  # a re-run rewrites rather than corrupts.
  ALT="$alt" KDIR="$kdir" python3 -c "
import json, os, sys
f = sys.argv[1]
d = json.load(open(f))
d['alt'] = os.environ['ALT']
d['keys_dir'] = os.environ['KDIR']
json.dump(d, open(f, 'w'), indent=2, sort_keys=True)" "$ctxf"

  local nctx; nctx=$(python3 -c "import json;d=json.load(open('$ctxf'));print(5 if d.get('with_fee') else 3)")
  echo "    $who  $n transactions, $nctx contexts, authority is $who themselves"
}

# swap_look <my-receiving-keys.json> <their-ctx.json> [agreed-units] [decimals]
#
# PASS THE AGREED AMOUNT. Until 2026-09-30 this took two arguments and swap-check exited ZERO on a
# wrong amount -- it printed the figure beside "if that is not the amount you agreed, do not sign"
# and returned success. The callers were not ignoring a failure; there was no failure to ignore.
# The safety of the whole flow rested on a human reading a number off a terminal. With units and
# decimals it is an exit code, and `set -e` in all four callers stops them dead.
#
# Units and decimals rather than base units, because that is the pair every caller already holds for
# swap_leg, and converting at the call site is where a factor of 10^8 gets introduced.
#
# The step that makes a confidential swap safe without trusting anyone. The amount is encrypted to
# the RECIPIENT as well as the sender, so the recipient reads it straight out of the proof context
# the chain has already verified -- no cooperation from the sender, and nothing revealed to anyone
# else.
swap_look() {
  local v; v=$(python3 -c "import json;print(json.load(open('$2'))['validity'])")
  # AT `confirmed`, AND RETRIED. The first version read with the default commitment, which is
  # finalized, immediately after the proof transactions had been confirmed -- so the context
  # account existed and the read said it did not, and the caller died on a null with
  # "'NoneType' object is not subscriptable". This repository has had that exact bug before, in
  # lender-check, and the note about it is in docs/: read at the commitment you wrote at.
  local data i
  for i in 1 2 3 4 5 6 7 8; do
    data=$(rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getAccountInfo\",\"params\":[\"$v\",{\"encoding\":\"base64\",\"commitment\":\"confirmed\"}]}" \
      | python3 -c "
import sys, json
v = json.load(sys.stdin).get('result', {}).get('value')
print(v['data'][0] if v else '')")
    [ -n "$data" ] && break
    sleep 2
  done
  # An absent context is not a zero amount. Saying so beats printing nothing and letting the caller
  # decide it looked fine.
  [ -n "$data" ] || { echo "    the proof context $v is not on chain — nothing to check, do not sign" >&2; return 1; }
  local agreed=""
  if [ -n "${3:-}" ]; then
    agreed=$(swap_base_units "$3" "${4:?swap_look: decimals are required when an agreed amount is given}") \
      || return 2
  fi
  # STDERR IS NOT DISCARDED. It used to be `2>/dev/null`, which was harmless while this only printed
  # a number -- and is not, now that the refusal itself arrives on stderr. A check whose reason is
  # thrown away exits non-zero with no explanation, which is the one thing worse than not checking.
  cargo run --quiet -p confide-ct --bin swap-check -- "$1" "$data" $agreed
}

# swap_workdir -- the directory holding your ElGamal secrets, namespaced BY CLUSTER.
#
# The filename is <mint first 8>-keys.json, and a mint address is the same string on devnet and
# mainnet, so one flat directory would have the two colliding. Namespacing the directory rather
# than the filename keeps the name readable and puts the separation where a mistake is obvious.
# An unrecognised endpoint gets "unknown" rather than being assumed to be mainnet.
swap_workdir() {
  local c
  case "${R:-}" in
    *devnet*)  c=devnet ;;
    *testnet*) c=testnet ;;
    *localhost*|*127.0.0.1*) c=local ;;
    *mainnet*|*publicnode*)  c=mainnet ;;
    *) c=unknown ;;
  esac
  echo "$HOME/.config/confide/swap/$c"
}

# swap_elgamal <keys.json> -- the ElGamal pubkey to hand a counterparty. It is the only thing they
# need from you to encrypt an amount you will be able to read.
swap_elgamal() { python3 -c "import json;print(json.load(open('$1'))['elgamal_pubkey_b64'])"; }
