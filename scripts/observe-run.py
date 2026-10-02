#!/usr/bin/env python3
"""Re-read a run from the chain, as somebody who was not there.

    RPC=<devnet endpoint> python3 scripts/observe-run.py <events.jsonl> [--receipt out.md]

issue-e2e.sh judges its own steps: it sends, reads the answer, and decides. That is a run grading
itself. This reads the run's event log only for WHAT TO LOOK UP -- the signatures and addresses it
cites -- and asks the chain, through an RPC of the caller's choosing, whether each is what the run
said. It holds no key and builds nothing; everything it checks, anybody with the addresses can check.

What it asserts, per event:

  mint                    autoApproveNewAccounts false and the auditor slot empty, as the real mints
  refused on_chain        the transaction LANDED and failed with exactly the cited error:
                            allocation    -> InstructionError {Custom: 24}
                            self_approval -> InstructionError MissingRequiredSignature
  refused rpc_preflight   nothing to look up -- it never entered a block. Reported, not verified.
  approval approved=true  succeeded, and is a Token-2022 instruction naming that account
  settled                 succeeded, carries two signatures, ran Token-2022 and nothing else (top level
                          and by CPI), and touches every account that act's observer row reads
  refused allocation      also names those same act-1 accounts -- the refusal and the settlement are
                          about the same accounts
  public                  each account reads a public token balance of 0, carries a confidential
                          balance, and reads approved

A short-delivery run (mode=short) must contain a pre-signing refusal and NO settlement. The refusal
itself is local -- no transaction exists -- so it is reported as the run's word, never marked ok.

WHAT THIS IS NOT. It is a separate process with no keys, but it is in the same repository, reads the
run's event log for what to look up, and by default uses the same RPC (OBSERVE_RPC overrides). It
reads mint and account state as it is NOW, not at each transaction's slot. Amounts are encrypted, so
it cannot see that the legs carried the agreed figures -- only the parties' keys can.

Exit 0 only if every check holds. The RPC endpoint is never printed.
"""
import json, sys, time, urllib.request

TOKEN_2022 = "TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb"
EXPLORER = "https://explorer.solana.com/{kind}/{key}?cluster=devnet"
EXPECTED_ERR = {
    "allocation": {"Custom": 24},
    "self_approval": "MissingRequiredSignature",
}


def rpc(url, method, params):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    for attempt in range(6):
        try:
            req = urllib.request.Request(url, body, {"Content-Type": "application/json"})
            with urllib.request.urlopen(req, timeout=30) as r:
                out = json.load(r)
            if "error" in out:
                raise RuntimeError(out["error"].get("message", "rpc error"))
            return out["result"]
        except Exception as e:  # 429s and resets on public endpoints: back off, never print the URL
            if attempt == 5:
                raise RuntimeError(f"{method} failed after retries: {type(e).__name__}") from None
            time.sleep(1.5 * (attempt + 1))


def tx(url, sig):
    # A just-confirmed transaction can take a moment to be served by getTransaction.
    for _ in range(10):
        r = rpc(url, "getTransaction", [sig, {"encoding": "jsonParsed", "commitment": "confirmed",
                                              "maxSupportedTransactionVersion": 0}])
        if r:
            return r
        time.sleep(2)
    return None


def account(url, key):
    r = rpc(url, "getAccountInfo", [key, {"encoding": "jsonParsed", "commitment": "confirmed"}])
    v = r and r.get("value")
    return v and v["data"]["parsed"]["info"]


def ext(info, name):
    return next((e["state"] for e in info.get("extensions", []) if e["extension"] == name), None)


def keys(t):
    return {k["pubkey"] if isinstance(k, dict) else k for k in t["transaction"]["message"]["accountKeys"]}


def programs(t):
    """Every program the transaction ran: top level AND by CPI. Top level alone would let a program
    of anybody's invoke another inside the trade and still read as 'Token-2022 only'."""
    top = [i.get("programId") for i in t["transaction"]["message"]["instructions"]]
    inner = [i.get("programId") for g in ((t.get("meta") or {}).get("innerInstructions") or [])
             for i in g["instructions"]]
    return top, inner


def instruction_error(t):
    err = (t.get("meta") or {}).get("err")
    if isinstance(err, dict) and "InstructionError" in err:
        return err["InstructionError"][1]
    return err


def observe(url, events):
    rows, bad = [], []

    def ok(step, what, link=""):
        rows.append(("ok", step, what, link))

    def fail(step, what, link=""):
        rows.append(("FAIL", step, what, link))
        bad.append(f"{step}: {what}")

    mode = next((e.get("mode") for e in events if e["ev"] == "run"), "normal")
    # What each act's settlement must have touched: the accounts the run says the observer read.
    # Binding a signature to those accounts is what stops a run citing some other successful
    # transaction as its settlement.
    act_accounts = {e.get("act"): set(e["accounts"].split(",")) for e in events if e["ev"] == "public"}
    for e in events:
        k = e["ev"]
        if k == "mint":
            info = account(url, e["mint"])
            c = info and ext(info, "confidentialTransferMint")
            link = EXPLORER.format(kind="address", key=e["mint"])
            if not c:
                fail("mint", f"{e['asset']}: no confidential-transfer extension", link)
            elif c.get("autoApproveNewAccounts") is not False or c.get("auditorElgamalPubkey"):
                fail("mint", f"{e['asset']}: gate open or auditor set", link)
            else:
                ok("1 · issuer policy", f"mint {e['asset']}: approval required, auditor empty", link)
        elif k == "refused" and e.get("source") == "on_chain":
            sig, what = e.get("sig", ""), e.get("what", "")
            t = tx(url, sig) if sig else None
            link = EXPLORER.format(kind="tx", key=sig)
            want = EXPECTED_ERR.get(what)
            if not t:
                fail("refusal", f"{what}: transaction not found on chain", link)
            elif want is None or instruction_error(t) != want:
                fail("refusal", f"{what}: chain says {instruction_error(t)!r}, expected {want!r}", link)
            elif what == "allocation" and not act_accounts.get("1", set()) <= keys(t):
                fail("refusal", "the refused allocation does not name the accounts act 1 settled between", link)
            elif what == "self_approval" and not ({e2["account"] for e2 in events
                     if e2["ev"] == "approval"} & keys(t)):
                fail("refusal", "the refused self-approval does not name the account that was later approved", link)
            else:
                step = "3 · gate refuses" if what == "allocation" else "3 · only the issuer can approve"
                ok(step, f"{what} landed and failed: {json.dumps(want)}", link)
        elif k == "refused" and e.get("source") == "rpc_preflight":
            rows.append(("--", "6 · two signatures needed",
                         f"{e.get('what')}: refused in RPC preflight, never entered a block -- nothing to look up", ""))
        elif k == "refused" and e.get("source") == "pre_sign_check":
            rows.append(("--", "6 · amount checked before signing",
                         f"short leg refused by the signer's own check (agreed {e.get('agreed')}) -- local, "
                         f"no transaction, so the chain cannot confirm it: reported by the run", ""))
        elif k == "approval" and e.get("approved") == "true" and e.get("sig"):
            t = tx(url, e["sig"])
            link = EXPLORER.format(kind="tx", key=e["sig"])
            if not t or (t.get("meta") or {}).get("err") is not None:
                fail("approval", "the issuer's approval did not succeed on chain", link)
            elif e["account"] not in keys(t) or set(programs(t)[0]) != {TOKEN_2022}:
                fail("approval", "the cited approval is not a Token-2022 instruction on that account", link)
            else:
                ok("4 · issuer approves that account", f"approved {e['account'][:8]}…", link)
        elif k == "settled":
            sig = e.get("sig", "")
            t = tx(url, sig) if sig else None
            link = EXPLORER.format(kind="tx", key=sig)
            if not t:
                fail("settlement", f"act {e.get('act')}: transaction not found", link); continue
            progs, inner = programs(t)
            nsig = len(t["transaction"]["signatures"])
            want_accts = act_accounts.get(e.get("act"), set())
            if (t.get("meta") or {}).get("err") is not None:
                fail("settlement", f"act {e.get('act')}: failed on chain: {t['meta']['err']}", link)
            elif nsig != 2:
                fail("settlement", f"act {e.get('act')}: {nsig} signatures, expected 2", link)
            elif not progs or any(p != TOKEN_2022 for p in progs + inner):
                fail("settlement", f"act {e.get('act')}: a program other than Token-2022 ran: {progs + inner}", link)
            elif not want_accts or not want_accts <= keys(t):
                fail("settlement", f"act {e.get('act')}: does not touch the accounts the observer reads", link)
            else:
                step = "5 · issuer allocates" if e.get("act") == "1" else "6 · two holders settle"
                ok(step, f"act {e.get('act')}: succeeded, 2 signatures, {len(progs)} Token-2022 instructions and "
                         f"nothing else (top level or inner), touching the {len(want_accts)} accounts below", link)
        elif k == "public":
            for a in e["accounts"].split(","):
                info = account(url, a)
                link = EXPLORER.format(kind="address", key=a)
                c = info and ext(info, "confidentialTransferAccount")
                if not info:
                    fail("observer", f"{a[:8]}…: account not found", link)
                elif info["tokenAmount"]["amount"] != "0":
                    fail("observer", f"{a[:8]}…: public balance {info['tokenAmount']['uiAmountString']}", link)
                elif not c or not c.get("approved"):
                    fail("observer", f"{a[:8]}…: not an approved confidential account", link)
                else:
                    ok(f"7 · observer, act {e.get('act')}", f"{a[:8]}…: public balance 0, balance encrypted", link)

    settled = [e for e in events if e["ev"] == "settled"]
    if mode == "short":
        if settled:
            fail("short control", "a short-delivery run settled something")
        if not any(e["ev"] == "refused" and e.get("source") == "pre_sign_check" for e in events):
            fail("short control", "a short-delivery run recorded no pre-signing refusal")
    else:
        for need, label in (("allocation", "the gate refusal"), ("self_approval", "the wrong-key refusal")):
            if not any(e["ev"] == "refused" and e.get("what") == need for e in events):
                fail("coverage", f"{label} is missing from the run")
        acts = {e.get("act") for e in settled}
        for a in ("1", "2"):
            if a not in acts:
                fail("coverage", f"act {a} did not settle")
            if a not in act_accounts:
                fail("coverage", f"no observer reading was recorded for act {a}")
        if sum(e["ev"] == "mint" for e in events) < 2:
            fail("coverage", "fewer than two mints were recorded")
        if not any(e["ev"] == "approval" and e.get("approved") == "true" and e.get("sig") for e in events):
            fail("coverage", "the issuer's approval is missing")
        if not any(e["ev"] == "refused" and e.get("source") == "rpc_preflight" for e in events):
            fail("coverage", "the half-signed control is missing")
    if not any(e["ev"] == "done" for e in events):
        fail("coverage", "the run did not finish")
    return mode, rows, bad


def main():
    import os
    args = sys.argv[1:]
    receipt = None
    if "--receipt" in args:
        i = args.index("--receipt"); receipt = args[i + 1]; del args[i:i + 2]
    if len(args) != 1:
        print(__doc__); sys.exit(2)
    url = os.environ.get("OBSERVE_RPC") or os.environ.get("RPC") or "https://api.devnet.solana.com"
    events = [json.loads(l) for l in open(args[0], encoding="utf-8") if l.strip()]
    mode, rows, bad = observe(url, events)
    for st, step, what, link in rows:
        print(f"  {st:4}  {step:34} {what}")
    lines = [f"# Run receipt — {mode} mode", "",
             "Re-read from devnet by `scripts/observe-run.py`, which holds no key and trusts nothing the run",
             "said except which signatures and addresses to look up.", "",
             "| | step | what the chain says | look it up |", "|---|---|---|---|"]
    lines += [f"| {st} | {step} | {what} | {('[explorer](' + link + ')') if link else ''} |" for st, step, what, link in rows]
    lines += ["", ("**Every check held.**" if not bad else f"**{len(bad)} check(s) failed.**")]
    if receipt:
        tmp = receipt + ".tmp"
        with open(tmp, "w", encoding="utf-8") as f:
            f.write("\n".join(lines) + "\n")
        os.replace(tmp, receipt)
    if bad:
        print(f"\n  {len(bad)} check(s) failed")
        sys.exit(1)
    print(f"\n  every check held ({len(rows)} rows)")


if __name__ == "__main__":
    main()
