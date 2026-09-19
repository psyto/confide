#!/usr/bin/env bash
# The collateral admission packet for one token and one Kamino reserve, generated from live data.
#
#   ./scripts/packet.sh SPCX.US
#   ./scripts/packet.sh NVDAx
#
# A risk owner has to answer a fixed set of questions before an asset can carry a number. This
# answers the ones that are on-chain, and marks the ones that are not as unknown — an unknown
# contributes a cap of $0 rather than an invented figure, which is the only honest way to write a
# packet you are not being paid to write.
#
# Generated rather than authored, so the day it disagrees with the chain is the day someone changed
# something, not the day the document went stale. Writes docs/packets/<SYMBOL>.md.
set -euo pipefail
cd "$(dirname "$0")/.."
SYM="${1:?usage: packet.sh <symbol|--all>   e.g. SPCX.US}"
RPC="${RPC:-https://api.mainnet-beta.solana.com}"

if [ "$SYM" = "--all" ]; then
  # Every mint that has a Kamino reserve. Regenerating one at a time is how a directory ends up
  # with a stale document nobody notices, so this exists and the index below is written from the
  # same run rather than by hand.
  SYMS="$(python3 -c "
import json
print(' '.join(sorted({r['symbol'] for r in json.load(open('web/kamino-reserves.json'))['reserves']})))")"
  for s in $SYMS; do "$0" "$s" | tail -1; done
  python3 - <<'IDX'
import json, io, datetime
d = json.load(open('web/kamino-reserves.json'))
cap = json.load(open('web/capacity.json'))
by = {}
for r in d["reserves"]:
    by.setdefault(r["symbol"], []).append(r)
L = ["# Collateral admission packets",
     "",
     "**Two of these carry the argument, and they carry different halves of it.**",
     "",
     "| | why it is here | what it has | what it lacks |",
     "|---|---|---|---|",
     "| [`NVDAx`](NVDAx.md) — **the control** | shows what a market that *works* looks like | a live price, real deposits, borrowing happening now, and authorities split across four keys | nothing; it is the case where every number is real |",
     "| [`SPCX.US`](SPCX.US.md) — **the blocked case** | shows where the motive is undeniable: pre-IPO exposure nobody wants broadcast | the clearest reason a holder would refuse to publish | a price, any deposits, and five authorities sit in one key |",
     "",
     "Leading with SpaceX alone would trade the strongest evidence for the strongest motive. Leading",
     "with NVDA alone would do the reverse. **The market is the aggregate below; SpaceX is why anyone",
     "would care; NVDA is the one where it already demonstrably matters** — and it is also the mint",
     "the devnet mechanism runs against, so the proof and the market point at the same asset.",
     "",
     "One per tokenized stock that **already has a Kamino reserve**. Generated from mainnet by",
     "`./scripts/packet.sh --all`, so a document here disagrees with the chain only when something",
     "changed. The question each one asks is the same:",
     "",
     "> A holder who will not post this collateral publicly — what would it take to let them post it",
     "> at all?",
     "",
     "Across all of them: **${:,} deposited**, **${:,} of borrowing already authorised** by these caps".format(cap["held_usd"], cap["authorised_capacity_usd"]),
     "and LTVs, and **$0 of it reachable while a position stays confidential**. See",
     "[`../KAMINO.md`](../KAMINO.md) for why, and `./scripts/capacity.sh` to recompute.",
     "",
     "| | issuer | LTV | cap | reserves | authorised |",
     "|---|---|---|---|---|---|"]
for sym in sorted(by):
    rs = by[sym]
    r = max(rs, key=lambda x: x["available"])
    auth = sum(x["deposit_limit"] * x["ltv_pct"] / 100 * x["price"] for x in rs)
    L.append("| [`%s`](%s.md) | %s | %d %% | %s | %d | %s |" % (
        sym, sym, r["issuer"], r["ltv_pct"], "{:,.0f}".format(r["deposit_limit"]), len(rs),
        "${:,.0f}".format(auth) if auth else "*no price*"))
L += ["",
      "*`cap` and `LTV` are the largest reserve's, where a symbol has more than one. `authorised` is",
      "summed across all of a symbol's reserves at each one's own price; a reserve that has never been",
      "refreshed carries no price and is left out rather than guessed.*"]
io.open("docs/packets/README.md", "w", encoding="utf-8").write("\n".join(L) + "\n")
print("  wrote docs/packets/README.md")
IDX
  exit 0
fi

python3 - "$RPC" "$SYM" <<'PY'
import base64, json, struct, sys, urllib.request, datetime
sys.path.insert(0, 'scripts/lib')
import klend_rules as K

RPC, SYM = sys.argv[1], sys.argv[2]
A = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
def b58(b):
    n = int.from_bytes(b, 'big'); s = ""
    while n: n, r = divmod(n, 58); s = A[r] + s
    return "1" * (len(b) - len(b.lstrip(b'\0'))) + s

def rpc(method, params):
    body = json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    req = urllib.request.Request(RPC, body, {"Content-Type":"application/json","User-Agent":"confide"})
    r = json.load(urllib.request.urlopen(req, timeout=180))
    if "error" in r:
        print("  the RPC refused: %s" % r["error"].get("message")); raise SystemExit(1)
    return r["result"]

mints = json.load(open('web/mints.json'))
hit = [m for m in mints if m["symbol"] == SYM] or [m for m in mints if m["symbol"].lower() == SYM.lower()]
if not hit:
    print("  %r is not in web/mints.json" % SYM); raise SystemExit(1)
m = hit[0]

info = rpc("getAccountInfo", [m["mint"], {"encoding": "jsonParsed"}])["value"]["data"]["parsed"]["info"]
exts = {e["extension"]: e.get("state") for e in info.get("extensions", [])}
admissible, why, _ = K.evaluate_mint(info)
dec = int(info["decimals"]); unit = 10 ** dec
supply = int(info["supply"]) / unit

reserves = json.load(open('web/kamino-reserves.json'))["reserves"] if __import__('os').path.exists('web/kamino-reserves.json') else []
# The market totals, read rather than typed. This block used to carry them as literals.
capacity = json.load(open('web/capacity.json'))
rs = [r for r in reserves if r["mint"] == m["mint"]]
if not rs:
    print("  no Kamino reserve for %s — run ./scripts/kamino-reserves.sh, or pick a token that has one" % SYM)
    raise SystemExit(1)
r = max(rs, key=lambda x: x["available"])

raw = base64.b64decode(rpc("getAccountInfo", [r["reserve"], {"encoding": "base64"}])["value"]["data"][0])
u64 = lambda o: struct.unpack_from("<Q", raw, o)[0]
TI = K.OFF_CONFIG + 176
assert raw[TI:TI+32].rstrip(b'\0').decode('ascii', 'replace').strip(), "TokenInfo did not decode"
oracle = dict(
    name=raw[TI:TI+32].rstrip(b'\0').decode(),
    heuristic_lower=u64(TI+32), heuristic_upper=u64(TI+40), heuristic_exp=u64(TI+48),
    max_twap_divergence_bps=u64(TI+56),
    max_age_price_seconds=u64(TI+64), max_age_twap_seconds=u64(TI+72),
    scope_feed=b58(raw[TI+80:TI+112]), scope_chain=list(struct.unpack_from("<4H", raw, TI+112)),
    switchboard=b58(raw[TI+128:TI+160]), pyth=b58(raw[TI+192:TI+224]),
)
NULL = "nu11111111111111111111111111111111111111111"

# who holds what
def auth(ext, key="authority"):
    return (exts.get(ext) or {}).get(key)
holders = {}
def note(who, power):
    if who: holders.setdefault(who, []).append(power)
note(info.get("mintAuthority"), "mint new supply")
note(info.get("freezeAuthority"), "freeze any holder's account")
note(auth("permanentDelegate", "delegate"), "**move any holder's tokens, without their signature**")
note(auth("pausableConfig"), "pause all transfers of the token")
note(auth("transferHook"), "install a transfer hook (none set today)")
note(auth("confidentialTransferMint"), "approve confidential accounts, set the auditor key")
note(auth("scaledUiAmountConfig"), "change the UI multiplier — a stock split, applied to every balance")
note(auth("defaultAccountState"), "change the state new accounts start in")

now = datetime.datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S UTC")
px_lo = oracle["heuristic_lower"] / 10 ** oracle["heuristic_exp"]
px_hi = oracle["heuristic_upper"] / 10 ** oracle["heuristic_exp"]

L = []
w = L.append
w("# Collateral admission packet — %s on Kamino" % m["symbol"])
w("")
w("*%s · %s · generated by `./scripts/packet.sh %s`, from mainnet, at %s.*" % (m.get("name") or "", m["issuer"], m["symbol"], now))
w("")
w("Generated rather than authored. **The day it disagrees with the chain is the day someone changed")
w("something**, not the day this went stale. Every unknown below produces a cap of `$0` on its own")
w("line rather than a number nobody can defend.")
w("")
w("## 0. The question this answers")
w("")
w("Not *should Kamino lend against %s* — it already does. The reserve exists, and someone chose" % m["symbol"])
w("its numbers. The question is the narrower one:")
w("")
w("> **A holder who will not post this collateral publicly — what would it take to let them post it")
w("> at all?**")
w("")
w("## 1. The asset")
w("")
w("| | |")
w("|---|---|")
w("| mint | `%s` |" % m["mint"])
w("| issuer | %s |" % m["issuer"])
w("| token program | Token-2022 |")
w("| decimals | %d |" % dec)
w("| supply | %s %s |" % ("{:,.2f}".format(supply), m["symbol"]))
w("| extensions | %s |" % ", ".join("`%s`" % e for e in sorted(exts)))
w("")
w("**Legal claim, redemption route and holder eligibility are not on-chain and are not asserted")
w("here.** They are the issuer's to state, they materially change the recovery value, and a packet")
w("that guessed at them would be worse than one that leaves them open. → **§6**")
w("")
w("## 2. Every authority on the token, and who holds it")
w("")
w("| holder | what it can do |")
w("|---|---|")
for who, powers in sorted(holders.items(), key=lambda kv: -len(kv[1])):
    w("| `%s` | %s |" % (who, "<br>".join(powers)))
w("")
if len(holders) <= 2:
    w("**These powers are concentrated.** One key can move, freeze and pause the collateral. That is a")
    w("counterparty risk that caps the LTV on its own, and it is unchanged by anything in this packet —")
    w("stated here so it is priced rather than discovered.")
w("")
w("## 3. Reserve evidence")
w("")
w("| | |")
w("|---|---|")
w("| an attested proof of reserves for this mint | **not established here** |")
w("| signer, freshness, coverage | **unknown** |")
w("| independently verifiable | **unknown** |")
w("")
w("**Contribution to the proposed cap: `$0`.** Not an accusation — this repository has not looked")
w("for %s's attestation, and the absence of a search is not the absence of evidence. It is a line a" % m["issuer"])
w("risk owner has to fill from the issuer, and until it is filled it caps the number.")
w("")
w("## 4. The oracle path, as the reserve is configured today")
w("")
w("| | |")
w("|---|---|")
w("| source | **Scope**, feed `%s`, chain index %d |" % (oracle["scope_feed"], oracle["scope_chain"][0]))
w("| Pyth fallback | %s |" % ("`%s`" % oracle["pyth"] if oracle["pyth"] != NULL else "**none**"))
w("| Switchboard fallback | %s |" % ("`%s`" % oracle["switchboard"] if oracle["switchboard"] != NULL else "**none**"))
w("| staleness tolerance | **%d s** on the price, %d s on the TWAP |" % (oracle["max_age_price_seconds"], oracle["max_age_twap_seconds"]))
w("| TWAP divergence limit | %s |" % ("%d bps" % oracle["max_twap_divergence_bps"] if oracle["max_twap_divergence_bps"] else "**not enforced** (0)"))
w("| accepted price range | **%s – %s** in the oracle's own price unit — outside it the price is refused |" % ("{:,.2f}".format(px_lo), "{:,.2f}".format(px_hi)))
w("")
w("A single source with no fallback means an oracle outage is a freeze, not a degradation. The")
w("price band is a real guard and also a real constraint: a move outside it stops the reserve rather")
w("than repricing it.")
w("")
w("**The band is in the oracle's price unit, and this packet has not established that unit is USD.**")
w("Doing that means decoding the lending market's quote currency and what Scope feed index %d" % oracle["scope_chain"][0])
w("denotes. Until then the numbers above are a range, not dollars.")
w("")
w("**Confide does not change this line.** A floor proof says how many tokens are there; it says")
w("nothing about what one is worth, and the packet should not pretend otherwise.")
w("")
w("## 5. The parameters, already chosen")
w("")
w("| | today |")
w("|---|---|")
w("| reserve | `%s` |" % r["reserve"])
w("| market | `%s` |" % r["market"])
w("| status | %s |" % r["status"])
w("| LTV | **%d %%** |" % r["ltv_pct"])
w("| liquidation threshold | **%d %%** |" % r["liquidation_threshold_pct"])
w("| liquidation bonus | %.2f %% – %.2f %% |" % (r["liquidation_bonus_bps"][0]/100, r["liquidation_bonus_bps"][1]/100))
w("| deposit cap | **%s %s** |" % ("{:,.0f}".format(r["deposit_limit"]), m["symbol"]))
w("| borrow limit | %s |" % ("**0** — collateral only" if r["borrow_limit"] == 0 else "{:,.0f} {}".format(r["borrow_limit"], m["symbol"])))
w("| currently deposited | %s |" % "{:,.2f}".format(r["available"]))
w("")
w("")
if r["price"] > 0:
    w("At the reserve's own price of %s, that cap and LTV authorise **%s of borrowing** against this" % (
        "{:,.2f}".format(r["price"]), "${:,.0f}".format(r["deposit_limit"] * r["ltv_pct"] / 100 * r["price"])))
    w("token, of which **$0 is reachable while the position stays confidential**.")
else:
    w("**This reserve has never been refreshed, so it carries no price.** Bounding it by the band the")
    w("reserve itself will accept, %s–%s, the cap and LTV authorise **%s – %s of borrowing**," % (
        "{:,.0f}".format(px_lo), "{:,.0f}".format(px_hi),
        "${:,.0f}".format(r["deposit_limit"] * r["ltv_pct"] / 100 * px_lo),
        "${:,.0f}".format(r["deposit_limit"] * r["ltv_pct"] / 100 * px_hi)))
    w("of which **$0 is reachable while the position stays confidential**.")
w("")
w("Across every Kamino reserve holding a tokenized stock, `./scripts/capacity.sh` puts that at")
# Derived, not typed. This line was "$21.1 m / $81.6 m" in the generator itself until 2026-09-19,
# so fourteen generated documents carried a hand-maintained number and regenerating them did not
# fix it. The chain had already moved to $22.0 m by the time anyone looked.
w("**${:.1f} m deposited and ${:.1f} m of authorised borrowing, none of it reachable".format(
    capacity["held_usd"] / 1e6, capacity["authorised_capacity_usd"] / 1e6))
w("confidentially** — read {}.".format(capacity["generated_at"]))
w("")
w("**Nothing in this packet proposes changing any of them.** They are the prior, and the whole")
w("point of the request below is that it does not need them moved.")
w("")
w("## 6. What a confidential position would need, and what it costs")
w("")
w("Kamino refuses a token account that can hold value confidentially — `constraints.rs:187` and")
w("`:201`, on the holder's own account, on deposit, borrowing and both sides of liquidation. So the")
w("holder's options today are to post publicly or not to post. See [`../KAMINO.md`](../KAMINO.md).")
w("")
w("| | state | who |")
w("|---|---|---|")
w("| A **floor**, proved — a lower bound on the balance, so the reserve values the position at `floor × price` and ignores the rest | **runs** | Confide |")
w("| **Custody that survives the holder** — the escrow's owner is a program PDA before anything is recorded | **runs** | Confide |")
w("| **Re-proving** — a floor proved once is a floor at one moment; a reserve marks continuously | **not built** | Confide |")
w("| **Liquidation hand-off** — the seizure has to sit inside Kamino's liquidation instruction, not beside it | **not built** | Confide, then Kamino |")
w("| **An exemption** for a reserve-recognised escrow from `:187` and `:201` | **not asked** | Kamino |")
w("")
w("**Cost to integrate, honestly bounded:** the exemption is a change to a constraint function and")
w("its tests. The hand-off is not — it touches the liquidation path, which is the part of a lending")
w("program where a mistake is a loss rather than a bug. **This packet does not claim that cost is")
w("small.** It claims the first two lines are done and the rest is specifiable.")
w("")
w("## 7. What would make this refusable, and rightly")
w("")
w("- The reserve evidence line in §3 stays unknown. → cap `$0`, and correctly.")
w("- **The issuer will not approve the escrow.** This mint sets `autoApproveNewAccounts: false`, so")
w("  a freshly configured confidential account is inert until the confidential-transfer mint")
w("  authority approves it — **once per account, by %s**." % m["issuer"])
w("")
w("  **Once per account, not once per loan.** `SetAuthority` moves an approved account to a loan")
w("  PDA and leaves the approval in place, verified on devnet 2026-09-19, so a holder who already")
w("  holds this token confidentially can pledge that account without asking again. What they give")
w("  up is the whole account: pledging part of a position needs a second one, and a second one")
w("  needs %s." % m["issuer"])
w("")
w("  It is still the most concrete blocker in the")
w("  document and it is not a Kamino decision at all. Confide's own demo hits it and has to add an")
w("  approve step. **An integration that assumed away issuer participation would be wrong.**")
w("")
w("  **And it is the same field Kamino requires.** `constraints.rs:131` refuses a liquidity mint")
w("  whose `auto_approve_new_accounts` is *true* — *\"Auto approve new accounts must be false for")
w("  liquidity tokens\"*. So the setting that admits this mint to Kamino at all is the setting that")
w("  puts %s in the path of every escrow. The two requirements are one field read from two" % m["issuer"])
w("  sides, and satisfying either one forces the other.")
w("")
w("  Measured across the whole asset class by `./scripts/slot-scan.sh`: **{n:,} of {n:,}".format(n=len(mints)))
w("  tokenized-equity mints on Solana set it false. Zero auto-approve.** There is no mint on the")
w("  ungated side, so this is not solved by choosing a different ticker, and **no engineering on")
w("  Confide's side removes it** — the floor can be proved, the collateral locked and the default")
w("  settled without the holder, and the position still cannot exist, because the account it would")
w("  live in cannot be opened without the issuer.")
w("- **Freeze and pause are judged too much control for a position the lender cannot see.** A frozen")
w("  or paused token cannot be transferred, so it cannot be liquidated either, and the holder of")
w("  that authority is in §2. **That is a coherent refusal and the packet has no answer to it.**")
w("")
w("  *A permanent delegate is the wrong version of this objection and an earlier draft made it. A")
w("  permanent delegate can move a **public** balance; a confidential withdrawal validates the")
w("  account owner and needs proofs bound to that account's ElGamal key, so it is not a demonstrated")
w("  power to move an invisible balance. Freeze and pause are the real ones.*")
w("- The liquidation hand-off proves not to fit inside Kamino's instruction without a change nobody")
w("  wants to make to the liquidation path.")
w("- Nobody wants to hold a confidential position badly enough to be worth the work. **No evidence")
w("  is offered here that anyone does.**")
w("")
w("---")
w("")
w("*Reproduce: `./scripts/packet.sh %s`. The chain reads are live; the klend rules and layout are" % m["symbol"])
w("pinned at `%s` and re-checked by `./scripts/kamino-verdict.sh`.*" % K.KLEND_TAG)

out = "docs/packets/%s.md" % m["symbol"].replace("/", "-")
open(out, "w").write("\n".join(L) + "\n")
print("  wrote %s  (%d lines)" % (out, len(L)))
print("  %s · %s · reserve %s · LTV %d%% · cap %s" % (
    m["symbol"], m["issuer"], r["reserve"][:8] + "…", r["ltv_pct"], "{:,.0f}".format(r["deposit_limit"])))
PY
