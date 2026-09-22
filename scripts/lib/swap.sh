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
  # Passed as ARGV, never interpolated. argv is data; a -c string is code.
  local base_units
  base_units=$(python3 -c 'import sys;print(int(sys.argv[1])*10**int(sys.argv[2]))' "$send" "$dec_n")
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

# swap_look <my-receiving-keys.json> <their-ctx.json>
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
  cargo run --quiet -p confide-ct --bin swap-check -- "$1" "$data" 2>/dev/null
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
