# The demo app — design

**Decided with the founder, 2026-09-30:** the demo is shown through a web app, not a terminal; web
only, no mobile; the proofs and the keys stay on a local server; the demo opens on issuance; and it
has a **second act** in which two approved holders trade (the brief's §2 step 6 — the founder chose
to keep it). The story it tells is [`STORY.md`](STORY.md) §4, in that order.

Reviewed before implementation: [`docs/reviews/2026-09-30-story-and-app.md`](../reviews/2026-09-30-story-and-app.md).

## The rule: no second engine

The app **does not implement a second proof, transaction, or policy engine.** Every check, refusal
and transaction already exists in `scripts/issue-e2e.sh` (act 1) and the four bilateral scripts it
calls in act 2. The app runs that script. It does implement orchestration, UI state, an event
stream and a read proxy — and those are exactly where it could start deciding things, so:

- **The script emits a typed checkpoint only after it has performed and checked the operation.**
  `{"ev":"refused","source":"on_chain","sig":"…","err":"Custom(24)"}` is written after the landed
  error has been read back and matched — never before, never on the strength of a send.
- **A refusal is shown only from such a checkpoint**, with its source — `on_chain`,
  `rpc_preflight` or `pre_sign_check` — and its evidence (a signature, or the RPC's error text).
- **The process exit code means only "completed" or "unexpected failure".** It cannot tell the
  expected refusals apart: the normal run and the `SHORT` run both exit 0.
- **The server never infers an outcome** from a timeout, a missing event, raw terminal text, or the
  absence of a settlement. A timeout is shown as *paused / failed*, never as a financial result.

So the pre-signing check stays an exit code inside the script. The app can display that it refused;
it cannot make it pass.

## Shape

```
browser (127.0.0.1)                        local server (Python stdlib)        devnet
┌────────────┬────────────┬────────────┐   ┌───────────────────────────┐
│ ISSUER     │ INVESTOR   │ OBSERVER   │   │ runs issue-e2e.sh         │── RPC from $RPC,
│ view       │ view  (+ act 2: BUYER)  │◀──│ streams typed checkpoints │   never to the browser
│            │            │ public     │──▶│ advances one step per     │
│            │            │ balances,  │   │ click                     │
│            │            │ signatures │   │ read proxy: allowlisted   │
└────────────┴────────────┴────────────┘   └───────────────────────────┘
```

**The panes are a single-presenter visualization, not isolated roles.** Every key is on the server,
every action is the server's, and every pane is in one browser that can read the whole event stream,
including the amounts decrypted for the investor. So the panes are labelled *views*, not wallets,
and the banner on every one says: *devnet · local demo · every key is held by this machine · not a
wallet*. Mainstream wallets do not support confidential transfers.

**The settlement has to look like delivery versus payment**: 20,000 shares one way and $3,500,000
the other, both legs in one transaction, both signatures shown, then the observer's four public
balances at 0. Act 2 the same, with 5,000 shares and $875,000.

## What changes in the script

Both inert unless the app sets them, so a terminal run behaves as it does today:

1. **`CONFIDE_EVENTS=<file>`** — one JSON line per checkpoint, written at the point the script has
   already asserted the thing the line reports.
2. **`CONFIDE_PAUSE=<fifo>`** — before each step, the script reads one line. The line is an advance
   token only; its contents are never executed or interpolated.

`SHORT=` is a separate run started by its own button, with `SHORT=2000` fixed on the server, exactly
as the terminal does it.

## Local server requirements

- binds **127.0.0.1**; validates `Host`; no CORS; same-origin POST with a CSRF token; a strict CSP;
  no third-party scripts. 127.0.0.1 limits network exposure; it is **not** protection against other
  processes of the same user, and that is out of scope rather than claimed.
- **the browser controls nothing but "advance" and "start run / start SHORT run".** No environment
  variables, paths, shell fragments, RPC methods, addresses or FIFO contents come from the client.
- per-run directory and FIFO chosen by the server: `umask 077`, directory `0700`, files `0600`, no
  symlinks followed, removed on exit; one run at a time; the child in its own process group with a
  timeout and a kill path.
- the server holds the **expected next checkpoint** and accepts exactly one advance for it —
  no queued or repeated advances.
- the RPC endpoint never appears in events, logs, errors, HTML or anything streamed; **raw child
  stdout/stderr and the work-directory path are not sent to the page** — only typed checkpoints.
- the observer's read proxy forwards only `getAccountInfo` / `getTransaction`, only for public keys
  and signatures that appeared in this run's checkpoints, with response filtering and size and rate
  limits. No arbitrary JSON-RPC, no arbitrary URL.

## What would show the app has diverged

A harness, written with the app, that runs the script with a stubbed chain (the same stubbing used
for the 09-30 negative controls):

- with and without `CONFIDE_EVENTS`, records the commands invoked and the transactions built, and
  requires them to be identical;
- asserts the exact checkpoint sequence for the normal run, the `SHORT` run, and act 2;
- breaks each source assertion in turn (the Custom(24) match, the wrong-key match, the signature
  count, the pre-signing comparison, the public-zero assertion) and requires that the corresponding
  success or refusal checkpoint is **absent** or the run fails.

Comparing terminal output alone is not enough: equal text does not prove equal transactions,
ordering, or that a checkpoint followed the assertion it reports.

## Not in scope

In-browser proof generation (the Rust ZK SDK compiled to WebAssembly — untested here), mobile,
mainnet, pricing, matching, and any lending lifecycle.
