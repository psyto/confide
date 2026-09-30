#!/usr/bin/env python3
"""Does the demo app decide anything it should not? No chain needed.

    python3 app/test_app.py

Three things, from docs/cwf-2026/DEMO-APP.md and the review that shaped it:

1. THE SERVER passes on only typed checkpoints, advances only the step the script is waiting on,
   refuses requests without the CSRF token or with a foreign Host, reads the chain only for ids this
   run reported, and never lets the RPC endpoint reach the page. Tested against a fake script and a
   fake RPC.
2. THE SCRIPT writes a refusal or settlement checkpoint only AFTER the check that justifies it. Each
   assertion block is lifted out of scripts/issue-e2e.sh and run against stubbed chain calls; when
   the stub makes the check fail, the checkpoint must be absent.
3. THE HOOKS are inert: without CONFIDE_EVENTS / CONFIDE_PAUSE, `ev` writes nothing and `pause`
   does not wait.
"""
import http.client
import http.server
import json
import os
import re
import socket
import subprocess
import sys
import tempfile
import textwrap
import threading
import time
import unittest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "app"))
import server  # noqa: E402

SECRET_RPC = "http://127.0.0.1:{port}/secret-key-abc123"
PUB = "9yfKfFD5aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"   # base58-looking, 44 chars
SIG = "5cYPobHEEpECCX9QhsPfquyW4cvhP6NmGD2Vd9jayyF7dU55ivYJDe6aLGYXCqcAE4aQXWmfQs24fZMQdYEdkVUT"


def free_port():
    s = socket.socket()
    s.bind(("127.0.0.1", 0))
    p = s.getsockname()[1]
    s.close()
    return p


class FakeRPC(http.server.BaseHTTPRequestHandler):
    calls = []

    def log_message(self, *a):
        pass

    def do_POST(self):
        body = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
        FakeRPC.calls.append(body["method"])
        if body["method"] == "getAccountInfo":
            res = {"result": {"value": {"data": {"parsed": {"info": {
                "owner": PUB, "mint": PUB, "tokenAmount": {"uiAmountString": "0"},
                "extensions": [{"extension": "confidentialTransferAccount", "state": {"approved": True}}]}}}}}}
        else:
            res = {"result": {"slot": 1, "meta": {"err": None, "computeUnitsConsumed": 30000},
                              "transaction": {"signatures": ["a", "b"]}}}
        out = json.dumps(res).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(out)))
        self.end_headers()
        self.wfile.write(out)


# A stand-in for issue-e2e.sh: the real hooks from scripts/lib/chain.sh, and events that include
# everything the sanitiser must drop.
FAKE_SCRIPT = textwrap.dedent(r'''
    set -euo pipefail
    . "{root}/scripts/lib/chain.sh"
    pause_open
    ev run mode=normal
    pause first
    ev party who=issuer pubkey={pub}
    ev refused source=on_chain what=allocation sig={sig} err="Custom(24)"
    ev not_a_real_event x=1
    ev party who=investor pubkey="$RPC"
    ev party who=investor pubkey="<img src=x onerror=alert(1)>"
    ev party who=investor extra_key=should_be_dropped pubkey={pub}
    ev checked source=pre_sign_check who=acceptor act=2 against=pin bound=yes
    pause second
    ev done mode=normal
''')


class ServerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.rpc_port = free_port()
        cls.rpc_srv = http.server.ThreadingHTTPServer(("127.0.0.1", cls.rpc_port), FakeRPC)
        threading.Thread(target=cls.rpc_srv.serve_forever, daemon=True).start()
        cls.rpc = SECRET_RPC.format(port=cls.rpc_port)
        cls.tmp = tempfile.mkdtemp()
        cls.script = os.path.join(cls.tmp, "fake.sh")
        open(cls.script, "w").write(FAKE_SCRIPT.format(root=ROOT, pub=PUB, sig=SIG))
        server.SCRIPT = cls.script
        cls.port = free_port()
        cls.app = server.App(cls.rpc, cls.port)
        cls.srv = http.server.ThreadingHTTPServer(("127.0.0.1", cls.port), server.handler_for(cls.app))
        threading.Thread(target=cls.srv.serve_forever, daemon=True).start()

    @classmethod
    def tearDownClass(cls):
        if cls.app.run:
            cls.app.run.cleanup()
        cls.srv.shutdown()
        cls.rpc_srv.shutdown()

    def req(self, method, path, body=None, headers=None, host=None):
        c = http.client.HTTPConnection("127.0.0.1", self.port, timeout=10)
        h = {"Host": host or f"127.0.0.1:{self.port}"}
        h.update(headers or {})
        c.request(method, path, body=json.dumps(body) if body is not None else None, headers=h)
        r = c.getresponse()
        return r.status, r.read()

    def post(self, path, body, csrf=True, **kw):
        h = {"Content-Type": "application/json"}
        if csrf:
            h["X-Confide-CSRF"] = self.app.csrf
        return self.req("POST", path, body, h, **kw)

    def events(self, until, timeout=10):
        """Read the SSE stream until `until(ev)` is true; return every data event seen."""
        c = http.client.HTTPConnection("127.0.0.1", self.port, timeout=timeout)
        c.request("GET", "/events", headers={"Host": f"127.0.0.1:{self.port}"})
        r = c.getresponse()
        seen, t0 = [], time.time()
        while time.time() - t0 < timeout:
            line = r.fp.readline().decode()
            if line.startswith("data: "):
                ev = json.loads(line[6:])
                if "ev" not in ev:
                    continue
                seen.append(ev)
                if until(ev):
                    break
        c.close()
        return seen

    def test_1_foreign_host_and_missing_csrf_are_refused(self):
        self.assertEqual(self.req("GET", "/", host="evil.example:80")[0], 421)
        self.assertEqual(self.post("/run", {"mode": "normal"}, csrf=False)[0], 403)
        self.assertEqual(self.req("POST", "/run", {"mode": "normal"},
                                  {"Content-Type": "text/plain", "X-Confide-CSRF": self.app.csrf})[0], 415)

    def test_2_the_page_carries_the_token_and_a_strict_csp(self):
        c = http.client.HTTPConnection("127.0.0.1", self.port, timeout=10)
        c.request("GET", "/", headers={"Host": f"127.0.0.1:{self.port}"})
        r = c.getresponse()
        html = r.read().decode()
        self.assertIn(self.app.csrf, html)
        self.assertIn("default-src 'none'", r.getheader("Content-Security-Policy"))
        self.assertIsNone(r.getheader("Access-Control-Allow-Origin"))

    def test_3_run_advance_sanitise_proxy(self):
        if not (self.app.run and self.app.run.state == "running"):
            self.assertEqual(self.post("/run", {"mode": "normal"})[0], 200)
        # a second start while running is refused
        self.assertEqual(self.post("/run", {"mode": "short"})[0], 409)
        seen = self.events(lambda e: e.get("ev") == "waiting" and e.get("next") == "first")
        # advancing a step the script is not waiting on does nothing
        self.assertEqual(self.post("/advance", {"step": "second"})[0], 409)
        self.assertEqual(self.post("/advance", {"step": "first"})[0], 200)
        # ... and the same step twice is not queued
        self.assertEqual(self.post("/advance", {"step": "first"})[0], 409)
        seen = self.events(lambda e: e.get("ev") == "waiting" and e.get("next") == "second")
        names = [e["ev"] for e in seen]
        self.assertNotIn("not_a_real_event", names)
        blob = json.dumps(seen)
        self.assertNotIn("secret-key-abc123", blob, "the RPC endpoint reached the page")
        self.assertNotIn("<img", blob)
        self.assertNotIn("extra_key", blob)
        self.assertIn(SIG, blob)
        self.assertTrue(any(e.get("bound") == "yes" for e in seen), "bound=yes was dropped on the way")
        self.assertTrue(all(e.get("r") == self.app.run.serial for e in seen), "an event without its run serial")
        # the proxy reads only ids this run reported
        self.assertEqual(self.req("GET", "/chain/account/" + PUB)[0], 200)
        self.assertEqual(self.req("GET", "/chain/tx/" + SIG)[0], 200)
        other = "7" * 44
        self.assertEqual(self.req("GET", "/chain/account/" + other)[0], 404)
        self.assertEqual(self.req("GET", "/chain/account/not-base58!")[0], 404)
        body = self.req("GET", "/chain/account/" + PUB)[1].decode()
        self.assertNotIn("secret-key", body)
        self.assertEqual(set(FakeRPC.calls), {"getAccountInfo", "getTransaction"})
        # an account id is not accepted where a signature is expected
        self.assertEqual(self.req("GET", "/chain/tx/" + PUB)[0], 404)
        self.assertEqual(self.post("/advance", {"step": "second"})[0], 200)
        # a fresh connection replays the history; it must not re-arm an advanced step
        self.events(lambda e: e.get("ev") == "done", timeout=5)
        self.assertEqual(self.post("/advance", {"step": "second"})[0], 409)
        self.assertEqual(self.post("/advance", {"step": "first"})[0], 409)
        seen = self.events(lambda e: e.get("ev") == "process" and e.get("state") != "running")
        self.assertIn("completed", [e.get("state") for e in seen if e.get("ev") == "process"])
        # when a run ends its directory -- keys, work files, raw log -- is gone; the events stay
        for _ in range(50):
            if not os.path.exists(self.app.run.dir):
                break
            time.sleep(0.2)
        self.assertFalse(os.path.exists(self.app.run.dir), "the finished run left its directory behind")
        self.assertTrue(self.app.run.evlist, "the sanitised events should survive cleanup")
        old = self.app.run
        # a new run can start, and the old run's ids are no longer readable through the proxy
        self.assertEqual(self.post("/run", {"mode": "normal"})[0], 200)
        self.assertIsNot(self.app.run, old)
        self.assertEqual(self.req("GET", "/chain/tx/" + SIG)[0], 404)


# ---- the script: a checkpoint only after its check ----

SCRIPT_SRC = open(os.path.join(ROOT, "scripts", "issue-e2e.sh"), encoding="utf-8").read()


def block(start, end):
    a = SCRIPT_SRC.index(start)
    return SCRIPT_SRC[a:SCRIPT_SRC.index(end, a)]


RUN_LOG = []


def run_block(src, stubs, extra=""):
    """Run one lifted block with stubbed chain calls; return (exit code, events written)."""
    d = tempfile.mkdtemp()
    evf = os.path.join(d, "ev.jsonl")
    open(evf, "w").close()
    prog = textwrap.dedent(f'''
        set -euo pipefail
        . "{ROOT}/scripts/lib/chain.sh"
        CONFIDE_EVENTS="{evf}"
        red=; dim=; off=; grn=; bold=; W="{d}"
        investor_X=ACCTX; MINT_X=MINTX; MINT_Y=MINTY; issuer_X=IX; investor_Y=IY; issuer_Y=IY2
        ALLOC=20000; PAY=3500000; DEC_X=8; GO_SIG=GOSIG
        cargo() {{ cat >/dev/null 2>&1 || true; echo tx; }}
        bh() {{ :; }}
        solana-keygen() {{ case "$*" in *issuer*) echo ISS;; *) echo INV;; esac; }}
        {extra}
        {stubs}
    ''') + src
    p = subprocess.run(["bash", "-c", prog], capture_output=True, text=True, timeout=60,
                       stdin=subprocess.DEVNULL)
    RUN_LOG.append(p.stderr)
    with open(evf) as f:
        evs = [json.loads(l) for l in f if l.strip()]
    return p.returncode, evs


GATE = block('read -r REFUSED_SIG err < <(landed', 'pause self_approve')
WRONG = block('read -r WRONG_SIG werr < <(landed', 'pause issuer_approves')
HALF = block('ISSUER=$(solana-keygen pubkey "$W/issuer.json")', 'pause investor_signs')
PUBLIC_1 = block('PUBS="$(pub "$issuer_X")', 'if [ "${ACT2:-1}" = 1 ]')
SHORT_B = block('  set +e; look "$W/investor-X-keys.json"', '  echo\n  echo "    work dir  $W"\n  exit 0\nfi')
SETTLE_1 = block('cargo run --quiet -p confide-ct --bin swap-tx -- sign "$W/half.b64" "$W/investor.json"', 'pause observe')
CHECK_OK = block('look "$W/investor-X-keys.json" "$W/issuer-ctx.json" "$ALLOC" "$DEC_X"\nev checked', 'build() {')
LOOK = block('decrypted() {', 'if [ -n "${SHORT:-}" ]; then')


def names(evs):
    return [(e["ev"], e.get("what", e.get("source", ""))) for e in evs]


class ScriptCheckpointTests(unittest.TestCase):
    def test_gate_refusal_only_when_custom_24(self):
        ok, evs = run_block(GATE, 'landed(){ echo \'SIG {"InstructionError":[0,{"Custom":24}]}\'; }')
        self.assertEqual(ok, 0)
        self.assertIn(("refused", "allocation"), names(evs))
        for bad in ('landed(){ echo SIG null; }', 'landed(){ echo \'SIG {"InstructionError":[0,{"Custom":4}]}\'; }',
                    'landed(){ echo NOSEND x; }', 'landed(){ echo SIG; }'):
            code, evs = run_block(GATE, bad)
            self.assertNotEqual(code, 0, bad)
            self.assertNotIn("refused", [e["ev"] for e in evs], bad)

    def test_wrong_key_refusal_only_when_missing_signature_and_still_unapproved(self):
        good = 'landed(){ echo \'SIG {"InstructionError":[0,"MissingRequiredSignature"]}\'; }; approved(){ echo false; }'
        code, evs = run_block(WRONG, good)
        self.assertEqual(code, 0)
        self.assertIn(("refused", "self_approval"), names(evs))
        for bad in ('landed(){ echo SIG null; }; approved(){ echo true; }',
                    'landed(){ echo \'SIG {"InstructionError":[0,"MissingRequiredSignature"]}\'; }; approved(){ echo true; }',
                    'landed(){ echo \'SIG {"InstructionError":[0,{"Custom":4}]}\'; }; approved(){ echo false; }'):
            code, evs = run_block(WRONG, bad)
            self.assertNotEqual(code, 0, bad)
            self.assertNotIn("refused", [e["ev"] for e in evs], bad)

    def test_half_signed_refusal_only_for_a_signature_failure_on_one_of_two(self):
        sigfail = "rpc(){ echo '{\"jsonrpc\":\"2.0\",\"error\":{\"code\":-32003,\"message\":\"Transaction signature verification failure\"}}'; }"
        # the answer devnet actually gave on 2026-09-30: well over 300 characters, which `send` cut
        # into unparseable JSON
        real = json.dumps({"jsonrpc": "2.0", "id": 1, "error": {"code": -32002,
            "message": "Transaction simulation failed: Transaction did not pass signature verification",
            "data": {"accounts": None, "err": "SignatureFailure", "fee": None, "innerInstructions": None,
                     "loadedAccountsDataSize": 0, "loadedAddresses": None, "logs": [], "postBalances": None,
                     "postTokenBalances": None, "preBalances": None, "preTokenBalances": None,
                     "replacementBlockhash": None, "returnData": None, "unitsConsumed": 0}}})
        self.assertGreater(len(real), 300)
        realstub = "rpc(){ cat <<'JSON'\n" + real + "\nJSON\n}"
        cargo_ok = 'cargo(){ if [ "$8" = sign ]; then cat >/dev/null; echo "  signed by ISS   1 of 2 signatures present" >&2; fi; echo tx; }'
        for stub in (sigfail, realstub):
            code, evs = run_block(HALF, stub, cargo_ok)
            self.assertEqual(code, 0, RUN_LOG[-1][-400:])
            self.assertIn(("refused", "half_signed"), names(evs))
        for extra, stub in (
            ('cargo(){ if [ "$8" = sign ]; then cat >/dev/null; echo "  signed by ISS   1 of 3 signatures present" >&2; fi; echo tx; }', sigfail),
            (cargo_ok, "rpc(){ echo '{\"error\":{\"code\":-32002,\"message\":\"sim failed\",\"data\":{\"err\":{\"InstructionError\":[0,\"MissingRequiredSignature\"]}}}}'; }"),
            (cargo_ok, "rpc(){ echo '{\"result\":\"SIGACCEPTED\"}'; }; confirm(){ return 0; }"),
        ):
            code, evs = run_block(HALF, stub, extra)
            self.assertNotEqual(code, 0, stub)
            self.assertNotIn("refused", [e["ev"] for e in evs], stub)

    def test_public_checkpoint_only_when_every_balance_is_zero(self):
        code, evs = run_block(PUBLIC_1, 'pub(){ echo 0; }')
        self.assertEqual(code, 0)
        self.assertIn("public", [e["ev"] for e in evs])
        code, evs = run_block(PUBLIC_1, 'pub(){ case "$1" in IY) echo 5;; *) echo 0;; esac; }')
        self.assertNotEqual(code, 0)
        self.assertNotIn("public", [e["ev"] for e in evs])

    def test_short_refusal_only_on_a_verified_mismatch(self):
        mismatch = 'swap_look(){ printf "  it will move \\033[1m200000000000\\033[0m base units\\n"; return 3; }'
        code, evs = run_block(LOOK + SHORT_B, mismatch, 'SHORT=2000')
        self.assertEqual(code, 0)
        r = [e for e in evs if e["ev"] == "refused"]
        self.assertEqual(r[0]["source"], "pre_sign_check")
        self.assertEqual(r[0]["decrypted_base"], "200000000000")
        # a check that never completed is not a refusal
        code, evs = run_block(LOOK + SHORT_B, 'swap_look(){ echo "context not on chain" >&2; return 1; }', 'SHORT=2000')
        self.assertNotEqual(code, 0)
        self.assertNotIn("refused", [e["ev"] for e in evs])
        # a short leg that passes is the finding, and fails loudly
        code, evs = run_block(LOOK + SHORT_B, 'swap_look(){ return 0; }', 'SHORT=2000')
        self.assertNotEqual(code, 0)
        self.assertNotIn("refused", [e["ev"] for e in evs])

    def test_a_failed_copy_is_a_failed_run_not_a_refusal(self):
        # the checker says "mismatch" (3), but the app's copy of its output cannot be written
        code, evs = run_block(LOOK + SHORT_B, 'swap_look(){ echo "it will move 1 base units"; return 3; }',
                              'SHORT=2000; W=/nonexistent-confide-dir')
        self.assertNotEqual(code, 0)
        self.assertNotIn("refused", [e["ev"] for e in evs])

    def test_settlement_only_after_two_of_two_and_confirmation(self):
        ok_sign = 'cargo(){ if [ "$8" = sign ]; then echo "  signed by INV   2 of 2 signatures present" >&2; fi; echo tx; }'
        rpc_cu = "rpc(){ echo '{\"result\":{\"meta\":{\"computeUnitsConsumed\":59804}}}'; }"
        base = 'INVESTOR=INV; send(){ echo SIGOK; }; ' + rpc_cu
        code, evs = run_block(SETTLE_1, base + '; confirm(){ return 0; }', ok_sign)
        self.assertEqual(code, 0)
        st = [e for e in evs if e["ev"] == "settled"]
        self.assertEqual((st[0]["sig"], st[0]["cu"]), ("SIGOK", "59804"))
        for extra, stub in (
            ('cargo(){ if [ "$8" = sign ]; then echo "  signed by INV   1 of 2 signatures present" >&2; fi; echo tx; }',
             base + '; confirm(){ return 0; }'),
            (ok_sign, base + '; confirm(){ return 1; }'),
            (ok_sign, 'INVESTOR=INV; send(){ echo "ERR {}"; }; ' + rpc_cu),
        ):
            code, evs = run_block(SETTLE_1, stub, extra)
            self.assertNotEqual(code, 0, stub)
            self.assertNotIn("settled", [e["ev"] for e in evs], stub)

    def test_act2_checks_are_written_before_anything_is_signed(self):
        with open(os.path.join(ROOT, "scripts", "swap-settle.sh"), encoding="utf-8") as f:
            settle = f.read()
        self.assertLess(settle.index("swap_look_pinned"), settle.index("ev checked"))
        self.assertLess(settle.index("ev checked"), settle.index("swap-tx -- sign"))
        with open(os.path.join(ROOT, "scripts", "swap-sign.sh"), encoding="utf-8") as f:
            sign = f.read()
        self.assertLess(sign.index("swap_look_pinned"), sign.index("ev checked"))
        self.assertLess(sign.index("swap-tx -- verify"), sign.index("ev checked"))
        self.assertLess(sign.index("ev checked"), sign.index("swap-tx -- sign"))
        self.assertLess(sign.index('go "the swap"'), sign.index("ev settled"))
        # nothing in act 2 reports a signature count it did not assert
        self.assertNotIn('signatures="', settle + sign)

    def test_checked_only_when_the_checker_passes(self):
        code, evs = run_block(LOOK + CHECK_OK, 'swap_look(){ echo "  ✓ it will move 2000000000000 base units to you"; }')
        self.assertEqual(code, 0)
        c = [e for e in evs if e["ev"] == "checked"]
        self.assertEqual(c[0]["decrypted_base"], "2000000000000")
        code, evs = run_block(LOOK + CHECK_OK, 'swap_look(){ echo "  ✗ short"; return 3; }')
        self.assertNotEqual(code, 0)
        self.assertNotIn("checked", [e["ev"] for e in evs])


class HookInertTests(unittest.TestCase):
    def test_a_terminal_run_writes_no_decrypted_copy(self):
        d = tempfile.mkdtemp()
        p = subprocess.run(["bash", "-c", f'set -euo pipefail; unset CONFIDE_EVENTS; W="{d}"; bold=; off=; red=; dim=; grn=; '
                            f'swap_look(){{ echo "it will move 5 base units"; }}; ' + LOOK +
                            '\nlook a b c d >/dev/null; ls "$W"'], capture_output=True, text=True, timeout=10,
                           stdin=subprocess.DEVNULL)
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertNotIn("check.out", p.stdout)

    def test_hooks_do_nothing_without_the_variables(self):
        p = subprocess.run(["bash", "-c", f'set -euo pipefail; unset CONFIDE_EVENTS CONFIDE_PAUSE; '
                            f'. "{ROOT}/scripts/lib/chain.sh"; pause_open; ev x a=1; pause step; echo fine'],
                           capture_output=True, text=True, timeout=10)
        self.assertEqual(p.returncode, 0)
        self.assertEqual(p.stdout.strip(), "fine")


if __name__ == "__main__":
    unittest.main(verbosity=2)
