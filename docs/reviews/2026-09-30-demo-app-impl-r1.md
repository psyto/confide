I would request changes before treating this as a trustworthy demo. The core normal-path checkpoints are mostly well placed, but the SHORT control can report a financial refusal on an operational error, and act 2 presents the buyer’s check after settlement.

1. Checkpoint ordering

- `account … approved=yes` is written only after `go` has sent and confirmed the approval. For the key investor-X approval, it is also followed by an explicit chain read before the event. The initial `open` calls do not independently reread each account’s approval state, though. [issue-e2e.sh](/Users/hiroyusai/src/confide/scripts/issue-e2e.sh:127)

- Normal act-1 `checked`, both on-chain refusals, the post-refusal false approval, the true approval, act-1 settlement, and both public-zero checkpoints are after their relevant checks. A failed normal `swap_look | tee` exits before `ev checked`. [issue-e2e.sh](/Users/hiroyusai/src/confide/scripts/issue-e2e.sh:192)

- **Blocker:** the SHORT branch treats *any* non-zero result from `swap_look | tee` as “short delivery refused,” then exits zero. That includes an unavailable proof context, RPC/checker failure, or `tee`/disk failure—not only a verified amount mismatch. It therefore emits a refusal checkpoint when the claimed assertion may not have been established. [issue-e2e.sh](/Users/hiroyusai/src/confide/scripts/issue-e2e.sh:171)

  This needs a typed checker result that distinguishes “amount differs” from operational failure. `PIPESTATUS` alone is insufficient if `swap_look` uses the same non-zero status for mismatch and error.

- Narrowly, an exit-zero `swap-settle.sh` does imply its pinned-term comparison ran successfully, and an exit-zero `swap-sign.sh` implies both its pinned-term comparison and transaction binding check ran before `go`. [swap-settle.sh](/Users/hiroyusai/src/confide/scripts/swap-settle.sh:77) [swap-sign.sh](/Users/hiroyusai/src/confide/scripts/swap-sign.sh:52)

  But the buyer’s parent-level `checked` event is emitted only after `swap-sign.sh` returns—after that script has already emitted `settled`. The page can therefore show settlement before “Checked against my own pinned terms.” [swap-sign.sh](/Users/hiroyusai/src/confide/scripts/swap-sign.sh:91) [issue-e2e.sh](/Users/hiroyusai/src/confide/scripts/issue-e2e.sh:478)

- The hard-coded act-2 `signatures="1 of 2"` and `"2 of 2"` fields are not assertions in those scripts: both signature-output greps are explicitly `|| true`. Omit those fields or assert them before reporting them. [swap-settle.sh](/Users/hiroyusai/src/confide/scripts/swap-settle.sh:88) [swap-sign.sh](/Users/hiroyusai/src/confide/scripts/swap-sign.sh:87)

2. Instrumentation changes terminal behavior

The hooks themselves are inert when `CONFIDE_EVENTS` and `CONFIDE_PAUSE` are unset: no fd 9, no wait, no event write. The FIFO design is sound: script-owned O_RDWR keeps a reader/writer present, and the server’s nonblocking literal write cannot execute input. [chain.sh](/Users/hiroyusai/src/confide/scripts/lib/chain.sh:80)

But “a terminal run is unchanged” is not true:

- `tee` always runs and writes the decrypted checker output to `$W/check.out`, even without app variables. This adds a persistent sensitive artifact and a new disk/I/O failure mode. [issue-e2e.sh](/Users/hiroyusai/src/confide/scripts/issue-e2e.sh:192)
- Reworked `show()` now delays its label until the balance command succeeds. On failure, the old version printed the label prefix; the new one prints nothing. [issue-e2e.sh](/Users/hiroyusai/src/confide/scripts/issue-e2e.sh:386)
- `go` now clears/clobbers caller-visible `GO_SIG` even in an ordinary terminal run. Its successful output and return status remain equivalent. [chain.sh](/Users/hiroyusai/src/confide/scripts/lib/chain.sh:58)

3. Server audit

I found no browser-origin path to select an RPC URL, command, work path, raw log, arbitrary RPC method, or an unreported id. Dynamic content is emitted as JSON and rendered as text nodes; the proxy has fixed methods; and the exact RPC URL is not returned on failures.

Two operational issues remain:

- **Run cleanup is not complete before replacement.** `cleanup()` sends SIGTERM then immediately closes/removes the directory; it never waits, escalates to SIGKILL, or reaps. After timeout especially, a replacement run can start while children from the old process group are still alive. This breaks “one run at a time” and can leave a child using deleted-but-open key/work files. [server.py](/Users/hiroyusai/src/confide/app/server.py:120) [server.py](/Users/hiroyusai/src/confide/app/server.py:165) [server.py](/Users/hiroyusai/src/confide/app/server.py:183)

- Any web page can create unlimited GET `/events` connections; CORS prevents reading them but does not prevent issuing them. `ThreadingHTTPServer` gives each one an indefinite thread. This is a local availability DoS. Cap SSE clients/per-IP connections and give idle connections a lifetime.

Minor hardening: keep separate allowlists for account keys and transaction signatures—the current shared `seen` set accepts a reported account in `/chain/tx/...` and vice versa. It does not expose an unreported id, but it is looser than the stated parameter shapes. [server.py](/Users/hiroyusai/src/confide/app/server.py:135) [server.py](/Users/hiroyusai/src/confide/app/server.py:353)

4. Page claims

No untrusted text reaches HTML: the rendering helpers use `textContent`, and Explorer links have a fixed origin. The allowed-character sanitiser is defense in depth, not the XSS boundary.

Claims to tighten:

- “Checked against my own pinned terms” is displayed after settlement for the buyer, as above.
- “confidential: encrypted” currently means only “the confidential-transfer extension exists.” Say “confidential-transfer fields are encrypted” rather than implying a nonzero confidential balance or a privacy result from extension presence alone. [server.py](/Users/hiroyusai/src/confide/app/server.py:207)
- “Amounts and balances are not” is too broad alongside the displayed public token balance. Prefer: “Confidential transfer amounts and confidential balances are encrypted; public token balance remains visible.”
- The footer adequately says these are views, not wallets. The pane copy (“reads only what is encrypted to them”, “by me”, “my own”) should explicitly be presented as a simulated role perspective, since the one browser receives every event.

5. Documentation/test split

The “Not yet implemented” section is accurate about whole-script equivalence and exact event sequences. The “Implemented” section is overstated: the tests cover three refusals, normal act-1 checking, and public-zero—not either settlement checkpoint, the SHORT refusal branch, either act-2 pin checkpoint, act-2 settlement, or act-2 public-zero. [test_app.py](/Users/hiroyusai/src/confide/app/test_app.py:246) [DEMO-APP.md](/Users/hiroyusai/src/confide/docs/cwf-2026/DEMO-APP.md:97)

The hook test also proves only `ev`/`pause` inertness; it does not cover the always-on `tee`, `show`, or `GO_SIG` changes. [test_app.py](/Users/hiroyusai/src/confide/app/test_app.py:302)

I attempted `python3 app/test_app.py`, but this review environment forbids temporary-file creation and loopback binds, so it produced six infrastructure errors rather than exercising the suite. That does not contradict your local passing result.