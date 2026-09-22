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
  local dec avail pub owner aud alt range me
  read -r dec avail pub owner < <(ct "$src")
  me=$(solana-keygen pubkey "$payer")

  # An empty auditor slot is what PYUSD ships and what all 1,992 tokenized-equity mints ship, so
  # there is usually no key to name. `none` is what the context builders have always taken.
  aud=none
  if [ -f "$W/auditor-$who.json" ]; then
    aud=$(python3 -c "import json;print(json.load(open('$W/auditor-$who.json'))['elgamal_pubkey_b64'])")
  fi

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
      "$(python3 -c "print($send * 10**$dec_n)")" "$(bh)" "$ctxf" "$me" "$W/$who-keys" "$1" "${2:-0}"; }
  else
    cx() { cargo run --quiet -p confide-ct --bin seizure-ctx -- "$payer" "$mykeys" \
      "$dec" "$avail" "$their_elg" "$aud" \
      "$(python3 -c "print($send * 10**$dec_n)")" "$(bh)" "$ctxf" "$me" "$W/$who-keys" "$1" none; }
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
  local data; data=$(rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getAccountInfo\",\"params\":[\"$v\",{\"encoding\":\"base64\"}]}" \
    | python3 -c "import sys,json;print(json.load(sys.stdin)['result']['value']['data'][0])")
  cargo run --quiet -p confide-ct --bin swap-check -- "$1" "$data" 2>/dev/null
}

# swap_elgamal <keys.json> -- the ElGamal pubkey to hand a counterparty. It is the only thing they
# need from you to encrypt an amount you will be able to read.
swap_elgamal() { python3 -c "import json;print(json.load(open('$1'))['elgamal_pubkey_b64'])"; }
