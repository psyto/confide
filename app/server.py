#!/usr/bin/env python3
"""The Confide demo app's local server. Design and the reasons: docs/cwf-2026/DEMO-APP.md.

    RPC=<devnet endpoint> python3 app/server.py [--port 8787]

It runs scripts/issue-e2e.sh and shows what the script reports. It does NOT build a transaction,
compare an amount, or decide that anything was refused: every outcome on the page comes from a
typed checkpoint the script wrote after its own assertion (`ev` in scripts/lib/chain.sh). The
process exit code means only "completed" or "failed" -- both the normal and the SHORT run exit 0,
so it cannot tell the expected refusals apart, and nothing here tries to.

What the browser can do: start a run (normal or SHORT), and advance the step the script is waiting
on. Nothing else it sends is used -- no environment, path, address, RPC method or command.
"""
import argparse
import http.server
import json
import os
import re
import secrets
import shutil
import signal
import subprocess
import sys
import tempfile
import threading
import time
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STATIC = os.path.join(ROOT, "app", "static")
SCRIPT = os.path.join(ROOT, "scripts", "issue-e2e.sh")
RUN_TIMEOUT_S = 45 * 60
MAX_SSE = 4              # a web page can open connections it cannot read; each one is a thread
SSE_LIFETIME_S = 600     # then the browser's EventSource reconnects on its own
SHORT_UNITS = "2000"  # fixed here; never taken from the client
SERIAL = __import__("itertools").count(1)

# The checkpoint vocabulary. Anything the script writes that is not in here -- an unknown event, an
# unknown key, an over-long or oddly-charactered value -- is dropped rather than forwarded.
SCHEMA = {
    "run": {"mode"},
    "waiting": {"next"},
    "party": {"who", "pubkey"},
    "mint": {"asset", "mint", "decimals", "auditor"},
    "account": {"who", "asset", "account", "approved", "funded"},
    "proofs": {"legs", "shares", "cash"},
    "checked": {"source", "who", "agreed", "decimals", "decrypted_base", "act", "against", "bound"},
    "refused": {"source", "what", "sig", "err", "agreed", "decimals", "decrypted_base", "signatures", "message"},
    "approval": {"account", "approved", "sig"},
    "settled": {"act", "sig", "cu", "shares", "cash", "signatures"},
    "holding": {"label", "account", "view"},
    "public": {"act", "accounts", "balances"},
    "offer": {"id", "shares", "cash", "pinned_by"},
    "accepted": {"pinned_by"},
    "done": {"mode"},
}
VALUE_OK = re.compile(r"^[A-Za-z0-9 _.,:;()/\-+$'=%—·]{0,300}$")
B58 = re.compile(r"^[1-9A-HJ-NP-Za-km-z]{32,88}$")


def sanitize(line, secret):
    """One raw event line -> a clean dict, or None. The RPC endpoint must never reach the page."""
    try:
        d = json.loads(line)
    except ValueError:
        return None
    if not isinstance(d, dict):
        return None
    name = d.get("ev")
    keys = SCHEMA.get(name)
    if keys is None:
        return None
    out = {"ev": name}
    for k, v in d.items():
        if k == "ev" or k not in keys or not isinstance(v, str):
            continue
        if secret and secret in v:
            continue
        if not VALUE_OK.match(v):
            continue
        out[k] = v
    return out


class Run:
    """One run of the script. The server holds at most one."""

    def __init__(self, mode, rpc):
        self.rpc = rpc
        os.umask(0o077)
        self.dir = tempfile.mkdtemp(prefix="confide-app-")  # 0700 by construction
        self.events = os.path.join(self.dir, "events.jsonl")
        self.fifo = os.path.join(self.dir, "advance.fifo")
        self.work = os.path.join(self.dir, "work")
        os.mkdir(self.work, 0o700)
        open(self.events, "w").close()
        os.chmod(self.events, 0o600)
        os.mkfifo(self.fifo, 0o600)
        self.mode = mode
        self.expected = None  # the step the script is waiting on, per its own "waiting" checkpoint
        self.state = "running"
        self.lock = threading.Lock()
        # What this run has reported, split by kind -- the proxy's allowlists. An account id is not
        # accepted where a signature is expected, or the reverse.
        self.seen_accounts = set()
        self.seen_sigs = set()
        # ONE reader per run. Events are read, sanitised and noted exactly once, here, and every
        # browser connection streams from this list. Reading per connection would replay "waiting"
        # on every reconnect and put an already-advanced step back into `expected` (Codex, 09-30).
        self.evlist = []
        self.pos = 0
        env = {
            "PATH": os.environ.get("PATH", "/usr/bin:/bin"),
            "HOME": os.environ.get("HOME", ""),
            "RPC": rpc,
            "WORK": self.work,
            "CONFIDE_EVENTS": self.events,
            "CONFIDE_PAUSE": self.fifo,
        }
        for k in ("CARGO_HOME", "RUSTUP_HOME", "FUNDER", "TMPDIR"):
            if os.environ.get(k):
                env[k] = os.environ[k]
        if mode == "short":
            env["SHORT"] = SHORT_UNITS
        self.log = open(os.path.join(self.dir, "log.txt"), "wb")  # never served
        self.proc = subprocess.Popen(["bash", SCRIPT], cwd=ROOT, env=env, stdin=subprocess.DEVNULL,
                                     stdout=self.log, stderr=subprocess.STDOUT, start_new_session=True)
        self.started = time.time()
        self.serial = next(SERIAL)  # tags every streamed event, so a page drops a replaced run's
        self.tail = threading.Thread(target=self._tail, daemon=True)
        self.tail.start()
        threading.Thread(target=self._reap, daemon=True).start()

    def _tail(self):
        while True:
            try:
                with open(self.events, "rb") as f:
                    f.seek(self.pos)
                    chunk = f.read()
            except FileNotFoundError:
                return  # cleaned up
            upto = chunk.rfind(b"\n") + 1  # only whole lines; a partial one waits for the next poll
            self.pos += upto
            for line in chunk[:upto].decode("utf-8", "replace").splitlines():
                ev = sanitize(line, self.rpc)
                if ev:
                    self.note(ev)
                    self.evlist.append(ev)
            if self.state != "running" and not upto:
                return
            time.sleep(0.3)

    def _reap(self):
        try:
            code = self.proc.wait(timeout=RUN_TIMEOUT_S)
            final = "completed" if code == 0 else "failed"
        except subprocess.TimeoutExpired:
            final = "timed out"
        with self.lock:
            self.expected = None
        # WHEN THE RUN ENDS, ITS SECRETS GO. Leftover children are stopped, every event the script
        # wrote is read, and then the directory -- keys, work files, the decrypted copy, the raw log
        # -- is removed. Only the sanitised event list stays, in memory. (Until Codex's second
        # review this happened only when the NEXT run started, while the design said "on exit".)
        self.kill()
        self.state = final          # the tail thread stops once it has drained after this
        self.tail.join(timeout=10)
        self.cleanup()

    def kill(self):
        """TERM the whole process group, wait, then KILL whatever is left, and reap. A replacement
        run must not start while children of this one still hold its key files open."""
        for sig, wait in ((signal.SIGTERM, 5), (signal.SIGKILL, 5)):
            try:
                os.killpg(self.proc.pid, sig)
            except ProcessLookupError:
                break
            t0 = time.time()
            while time.time() - t0 < wait:
                try:
                    os.killpg(self.proc.pid, 0)
                except ProcessLookupError:
                    break
                time.sleep(0.1)
            else:
                continue
            break
        try:
            self.proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            pass

    def note(self, ev):
        """Track what the script is waiting for, and which public ids it has reported."""
        if ev["ev"] == "waiting":
            with self.lock:
                self.expected = ev.get("next")
        for k in ("pubkey", "mint", "account"):
            v = ev.get(k, "")
            if B58.match(v):
                self.seen_accounts.add(v)
        for v in ev.get("accounts", "").split(","):
            if B58.match(v):
                self.seen_accounts.add(v)
        if B58.match(ev.get("sig", "")):
            self.seen_sigs.add(ev["sig"])

    def advance(self, step):
        """Release exactly the step the script says it is waiting on. One token, then nothing until
        the script asks again -- no queued or repeated advances."""
        with self.lock:
            if self.state != "running" or not step or step != self.expected:
                return False
            try:
                fd = os.open(self.fifo, os.O_WRONLY | os.O_NONBLOCK)
            except OSError:
                return False
            try:
                os.write(fd, b"go\n")
            finally:
                os.close(fd)
            self.expected = None
            # RECORDED IN THE STREAM, so a page that reconnects -- every SSE_LIFETIME_S, or after a
            # dropped connection -- replays "waiting X" FOLLOWED BY "advanced X" and does not redraw
            # a button for a step already taken. Without it, the 2026-10-02 recordings reconnected at
            # 600 s mid-step and pressed "Build both legs' proofs" twenty more times. Written by the
            # server, about the server's own action; never a financial outcome.
            self.evlist.append({"ev": "advanced", "step": step})
            return True

    def cleanup(self):
        if self.proc.poll() is None:
            self.kill()
        try:
            self.log.close()
        except Exception:
            pass
        shutil.rmtree(self.dir, ignore_errors=True)


class App:
    def __init__(self, rpc, port):
        self.rpc = rpc
        self.port = port
        self.csrf = secrets.token_urlsafe(32)
        self.run = None
        self.lock = threading.Lock()
        self.reads = []  # timestamps, for the proxy's rate limit
        self.sse_clients = 0
        self.sse_lock = threading.Lock()

    def start(self, mode):
        # A finished run has already removed its directory (Run._reap), so replacing it is quick and
        # the lock is not held across a kill.
        with self.lock:
            if self.run and (self.run.state == "running" or os.path.exists(self.run.dir)):
                return False
            self.run = Run(mode, self.rpc)
            return True

    def rpc_call(self, method, params):
        body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
        req = urllib.request.Request(self.rpc, data=body, headers={"Content-Type": "application/json"})
        with urllib.request.urlopen(req, timeout=20) as r:
            return json.loads(r.read(2_000_000))

    def public_account(self, key):
        """Only what anybody can read, and only the fields the observer pane shows."""
        v = self.rpc_call("getAccountInfo", [key, {"encoding": "jsonParsed", "commitment": "confirmed"}])
        v = (v.get("result") or {}).get("value")
        if not v:
            return {"exists": False}
        info = ((v.get("data") or {}).get("parsed") or {}).get("info") or {}
        ct = next((e.get("state") for e in info.get("extensions", [])
                   if e.get("extension") == "confidentialTransferAccount"), None)
        return {
            "exists": True,
            "owner": info.get("owner"),
            "mint": info.get("mint"),
            "public_balance": (info.get("tokenAmount") or {}).get("uiAmountString"),
            "confidential": ct is not None,
            "approved": bool(ct and ct.get("approved")),
            "pending_and_available": "encrypted" if ct else None,
        }

    def public_tx(self, sig):
        v = self.rpc_call("getTransaction", [sig, {"commitment": "confirmed", "maxSupportedTransactionVersion": 0}])
        r = v.get("result")
        if not r:
            return {"found": False}
        meta = r.get("meta") or {}
        return {
            "found": True,
            "slot": r.get("slot"),
            "err": meta.get("err"),
            "compute_units": meta.get("computeUnitsConsumed"),
            "signatures": len((r.get("transaction") or {}).get("signatures") or []),
        }

    def rate_ok(self):
        now = time.time()
        self.reads = [t for t in self.reads if now - t < 10]
        if len(self.reads) >= 30:
            return False
        self.reads.append(now)
        return True


CSP = ("default-src 'none'; script-src 'self'; style-src 'self'; connect-src 'self'; "
       "img-src 'self' data:; font-src 'self'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'")


def handler_for(app):
    class H(http.server.BaseHTTPRequestHandler):
        server_version = "confide-demo"
        sys_version = ""

        def log_message(self, *a):  # quiet: nothing about the run is logged to the terminal
            pass

        def _host_ok(self):
            return self.headers.get("Host") in (f"127.0.0.1:{app.port}", f"localhost:{app.port}")

        def _send(self, code, body=b"", ctype="application/json", extra=None):
            self.send_response(code)
            self.send_header("Content-Type", ctype)
            self.send_header("Content-Security-Policy", CSP)
            self.send_header("X-Content-Type-Options", "nosniff")
            self.send_header("Referrer-Policy", "no-referrer")
            self.send_header("Cache-Control", "no-store")
            for k, v in (extra or {}).items():
                self.send_header(k, v)
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def _json(self, code, obj):
            self._send(code, json.dumps(obj).encode())

        def do_GET(self):
            if not self._host_ok():
                return self._send(421, b"")
            path = self.path.split("?", 1)[0]
            # Two views of the same run: "/" is the first (role panes), "/ops" the settlement-operations
            # layout. Both render the same checkpoints and neither decides anything.
            if path in ("/", "/ops"):
                page = "index.html" if path == "/" else "ops.html"
                with open(os.path.join(STATIC, page), encoding="utf-8") as f:
                    html = f.read()
                return self._send(200, html.replace("{{CSRF}}", app.csrf).encode(), "text/html; charset=utf-8")
            if path in ("/app.js", "/app.css", "/ops.js", "/ops.css"):
                ctype = "text/javascript" if path.endswith(".js") else "text/css"
                with open(os.path.join(STATIC, path[1:]), "rb") as f:
                    return self._send(200, f.read(), ctype + "; charset=utf-8")
            if path == "/events":
                return self._events()
            m = re.match(r"^/chain/(account|tx)/([1-9A-HJ-NP-Za-km-z]{32,88})$", path)
            if m:
                return self._chain(m.group(1), m.group(2))
            return self._send(404, b"")

        def do_POST(self):
            if not self._host_ok():
                return self._send(421, b"")
            if self.headers.get("X-Confide-CSRF") != app.csrf:
                return self._send(403, b"")
            origin = self.headers.get("Origin")
            if origin and origin not in (f"http://127.0.0.1:{app.port}", f"http://localhost:{app.port}"):
                return self._send(403, b"")
            if self.headers.get("Content-Type", "").split(";")[0] != "application/json":
                return self._send(415, b"")
            n = int(self.headers.get("Content-Length") or 0)
            if n > 256:
                return self._send(413, b"")
            try:
                body = json.loads(self.rfile.read(n) or b"{}")
            except ValueError:
                return self._send(400, b"")
            if self.path == "/run":
                mode = "short" if body.get("mode") == "short" else "normal"
                return self._json(200 if app.start(mode) else 409, {"started": mode})
            if self.path == "/advance":
                ok = bool(app.run) and app.run.advance(str(body.get("step", "")))
                return self._json(200 if ok else 409, {"advanced": ok})
            return self._send(404, b"")

        def _events(self):
            with app.sse_lock:
                if app.sse_clients >= MAX_SSE:
                    return self._send(503, b"")
                app.sse_clients += 1
            # a client that stops reading must not hold a thread past the lifetime
            self.connection.settimeout(30)
            try:
                self.send_response(200)
                self.send_header("Content-Type", "text/event-stream")
                self.send_header("Cache-Control", "no-store")
                self.send_header("Content-Security-Policy", CSP)
                self.end_headers()
                run, i, last_state, t0 = None, 0, None, time.time()
                while time.time() - t0 < SSE_LIFETIME_S:
                    if app.run is not run:
                        run, i, last_state = app.run, 0, None
                        self.wfile.write(("event: reset\ndata: " + json.dumps({"r": run.serial if run else 0}) + "\n\n").encode())
                    if run:
                        new = run.evlist[i:]
                        i += len(new)
                        # every line carries its run's serial; the page drops any that is not the
                        # run it was last reset to, so a replacement is a clean boundary
                        for ev in new:
                            self.wfile.write(("data: " + json.dumps(dict(ev, r=run.serial)) + "\n\n").encode())
                        if run.state != last_state:
                            last_state = run.state
                            # the process state, labelled as such -- never a financial outcome
                            self.wfile.write(("data: " + json.dumps({"ev": "process", "state": run.state, "r": run.serial}) + "\n\n").encode())
                    self.wfile.flush()
                    time.sleep(0.4)
            except (BrokenPipeError, ConnectionResetError, TimeoutError, OSError):
                pass
            finally:
                with app.sse_lock:
                    app.sse_clients -= 1

        def _chain(self, kind, ident):
            run = app.run
            allowed = run.seen_accounts if (run and kind == "account") else (run.seen_sigs if run else set())
            if ident not in allowed:
                return self._send(404, b"")
            if run is not app.run:
                return self._send(409, b"")
            if not app.rate_ok():
                return self._send(429, b"")
            try:
                obj = app.public_account(ident) if kind == "account" else app.public_tx(ident)
            except Exception:
                # no endpoint, no error text: either could carry the RPC URL
                return self._json(502, {"error": "read failed"})
            return self._json(200, obj)

    return H


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", type=int, default=8787)
    a = ap.parse_args()
    rpc = os.environ.get("RPC", "")
    if not rpc.startswith("http"):
        print("  RPC is not set. Pass your devnet endpoint as an environment variable:\n"
              "    RPC=$CONFIDE_RPC python3 app/server.py\n"
              "  The public devnet endpoint stops this script on slot skew (STATUS 2026-09-30 (4)).",
              file=sys.stderr)
        sys.exit(2)
    app = App(rpc, a.port)
    srv = http.server.ThreadingHTTPServer(("127.0.0.1", a.port), handler_for(app))
    print(f"  Confide demo — http://127.0.0.1:{a.port}/   (devnet · local · Ctrl-C to stop)")
    # SIGTERM too, so a killed server still removes its run directory (keys live there).
    signal.signal(signal.SIGTERM, lambda *_: (_ for _ in ()).throw(KeyboardInterrupt()))
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        if app.run:
            app.run.cleanup()


if __name__ == "__main__":
    main()
