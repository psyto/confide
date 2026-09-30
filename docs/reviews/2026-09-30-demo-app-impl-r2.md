Request changes before calling this fully closed. The original financial blocker is fixed, but two implementation defects remain.

1. The SHORT status split is correct at the checker boundary.

`swap-check` has one explicit exit-3 route: `compare(...) -> Err`, then `process::exit(MISMATCH)`. Its deliberate operational failures use `die(...)=1`; ordinary Rust panics normally exit 101. Cargo propagates the binary’s exit status, so a completed, verified mismatch reaches `swap_look` as 3, not 1. [swap_check.rs](/Users/hiroyusai/src/confide/crates/confide-ct/src/swap_check.rs:167)

The SHORT `set +e; look …; st=$?; set -e` is correct. With events enabled, `return "${PIPESTATUS[0]}"` expands before `return` overwrites `PIPESTATUS`, so `st` is the upstream `swap_look` result. With events disabled, it is directly `swap_look`’s result. [issue-e2e.sh](/Users/hiroyusai/src/confide/scripts/issue-e2e.sh:163)

One caveat: it intentionally ignores `tee`’s status. If `swap_look` succeeds but `tee` cannot write, normal mode can continue and emit `checked` with an empty decrypted figure; if the checker returns 3, SHORT can still report refusal despite capture failure. This does not turn an operational checker failure into a mismatch, but it makes the app’s evidence capture unreliable. Treat a nonzero `tee` as a run failure, or explicitly make the UI tolerate/label unavailable captured output.

2. Round-1 items are otherwise substantively fixed.

- SHORT no longer turns checker failure into a refusal.
- Terminal runs no longer create `check.out`; `show()` prints its label first; `GO_SIG` is output-inert.
- Act-2 `checked` events are now before signing, and act-2 settlement is after confirmation.
- The wrapper’s call sites are checked.
- One tail thread prevents reconnects from re-arming `expected`.
- Account/signature allowlists are separate.
- Page copy now accurately distinguishes encrypted confidential-transfer fields and simulated roles.

But `bound=yes` is silently discarded: the UI explicitly supports it, yet `SCHEMA["checked"]` omits `bound`. Therefore the buyer never sees “the transaction is exactly the one checked.” [server.py](/Users/hiroyusai/src/confide/app/server.py:47) [app.js](/Users/hiroyusai/src/confide/app/static/app.js:196)

3. Server concurrency is improved, not fully atomic.

The advance/reconnect bug is fixed: only `_tail` calls `note`, and `advance` clears `expected` under the run lock.

Remaining races/availability issues:

- `App.start()` holds `app.lock` throughout `cleanup()` and its up-to-15-second kill path. This blocks new SSE admission and its final decrement, as well as other starts. [server.py](/Users/hiroyusai/src/confide/app/server.py:160) [server.py](/Users/hiroyusai/src/confide/app/server.py:366)
- Existing SSE handlers read `app.run` without that lock. A handler can emit old-run events after replacement, then send `reset` on the next iteration. The reset eventually repairs the UI, but replacement is not an atomic stream boundary.
- `/chain` snapshots the old `run`, checks its allowlist, and can query it after a replacement. That violates the strict “this run reported” claim during a start race. [server.py](/Users/hiroyusai/src/confide/app/server.py:399)
- The 10-minute SSE lifetime is not absolute: a blocking `wfile.write()` to a non-reading client can prevent the loop from reaching its timeout.

4. DEMO-APP.md is still inaccurate on sensitive-file lifecycle.

It says the per-run directory is “removed on exit.” [DEMO-APP.md](/Users/hiroyusai/src/confide/docs/cwf-2026/DEMO-APP.md:82) In reality, a completed or failed run only changes state in `_reap`; cleanup occurs on replacement or server shutdown. The directory retains keys, work files, `check.out`, and the raw log after a normal completed run. [server.py](/Users/hiroyusai/src/confide/app/server.py:151)

That is the most material remaining documentation/implementation mismatch. Preserve only the sanitized in-memory event history after completion, then close and remove the sensitive run artifacts; or revise the document and UI lifecycle honestly.

I did not run the test suite or devnet: this workspace is read-only, while the test suite creates temporary files and loopback servers.