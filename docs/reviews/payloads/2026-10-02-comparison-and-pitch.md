# Review request — "who reads the amount" in the demo and a pitch script, 2026-10-02

The founder asked to make the videos clearer by comparison with similar services. Form text confirmed
2026-10-02: demo "Up to 3 minutes. Should show the live product, not a slide deck, not a code
walkthrough"; pitch "introduce yourselves... why you're the people... Up to 2 minutes", Public.

Done:
1. docs/cwf-2026/COMPARABLES.md (committed f670c28) — DEX / CEX / Renegade / Arcium / US ATS / Confide,
   from primary sources; Renegade README and FINRA 6380A re-fetched by hand.
2. Demo: not a slide. The /ops PUBLIC LEDGER panel shows "THE SAME TRADE ELSEWHERE — who reads the amount"
   only after the run's own public read-back with all balances 0; the DEX row carries the trade's own
   shares/cash from the run's checkpoints. Narration scene 5 adds the comparison; scenes 1,2,3,6,8 trimmed
   to fit. record-app.js holds the first "Look from outside" 15.5 s (default read 2.6→2.2 s); cut-app.js
   fast-forward 1.1→1.0 s. demo-ops.mp4 re-recorded on devnet: 172.7 s.
3. App bug found while recording: SSE connections end every 600 s and the page replays all events; the
   replay of an already-advanced "waiting" redrew a live button. Two recordings pressed "Build both legs'
   proofs" 19+ times (409 each) in the short run. Fix: server appends {"ev":"advanced","step"} on a
   successful advance; both views clear the button on it. New assertion in app/test_app.py; removing the
   append makes it fail. record-app.js now aborts if a pressed step is offered again.
4. video/PITCH.md — 92 s draft, founder facts left as [FOUNDER: ...].

Questions:
1. Overclaim/underclaim in the panel rows ("dark pool — its operator or relayer"; "exchange — the
   exchange, which holds the assets"), the scene-5 narration, and every pitch line. Check against
   COMPARABLES.md's sources. Is "a block's size reaches the public tape within ten seconds" right for US
   markets generally (are there exceptions, e.g. delayed/aggregated reporting for large blocks)?
2. Is the in-product comparison still "the live product, not a slide deck"? Is the static text in the
   panel (not produced by the run) a problem for the page's own rule "No price, instrument or market
   data exists here that the run did not produce"?
3. The advanced-event fix: correct and complete? Other replay hazards (app.js waitingFor/doneSteps)?
4. Anything in the narration trims that lost a correction made in earlier reviews
   (docs/reviews/2026-09-30-demo-narration.md)?

--- git diff ---
diff --git a/app/server.py b/app/server.py
index deb9184..b1dafe5 100644
--- a/app/server.py
+++ b/app/server.py
@@ -221,6 +221,12 @@ class Run:
             finally:
                 os.close(fd)
             self.expected = None
+            # RECORDED IN THE STREAM, so a page that reconnects -- every SSE_LIFETIME_S, or after a
+            # dropped connection -- replays "waiting X" FOLLOWED BY "advanced X" and does not redraw
+            # a button for a step already taken. Without it, the 2026-10-02 recordings reconnected at
+            # 600 s mid-step and pressed "Build both legs' proofs" twenty more times. Written by the
+            # server, about the server's own action; never a financial outcome.
+            self.evlist.append({"ev": "advanced", "step": step})
             return True
 
     def cleanup(self):
diff --git a/app/static/app.js b/app/static/app.js
index e85f429..f90d065 100644
--- a/app/static/app.js
+++ b/app/static/app.js
@@ -171,6 +171,8 @@ const H = {
     showNext(e.next);
     setStatus("waiting for: " + (STEP[e.next] ? STEP[e.next].label : e.next));
   },
+  // the server's record that a step was taken: on a replay it follows that step's "waiting"
+  advanced(e) { showNext(null); setStatus("working on devnet: " + (STEP[e.step] ? STEP[e.step].label : e.step)); },
   party(e) { card(paneOf(e.who), "info", "Keypair", [e.pubkey]); },
   mint(e) {
     decimals[e.asset] = e.decimals;
diff --git a/app/static/ops.css b/app/static/ops.css
index 0b5466d..0c02326 100644
--- a/app/static/ops.css
+++ b/app/static/ops.css
@@ -98,3 +98,13 @@ h3.cf { color: var(--accent); }
 .did { font-size: 12.5px; }
 .did li { padding: 2px 0; }
 #mints td { padding: 3px 6px; }
+
+/* the same trade elsewhere — shown only after the run's own public read-back */
+.elsewhere{margin-top:6px;border-top:1px solid var(--line);padding-top:6px;font-size:14.5px}
+.elsewhere h3{color:#f0c05a}
+.elsewhere h3{margin:0 0 4px}
+.elsewhere .ew{display:grid;grid-template-columns:86px 1fr;gap:8px;padding:2px 0;border-bottom:1px solid var(--line)}
+.elsewhere .ew span:first-child{color:#8b95a7}
+.elsewhere .warnc{color:#f0c05a} .elsewhere .okc{color:#63cf83}
+.elsewhere .here{font-weight:600}
+.elsewhere .fine{margin-top:4px}
diff --git a/app/static/ops.html b/app/static/ops.html
index 56fe22a..0096e03 100644
--- a/app/static/ops.html
+++ b/app/static/ops.html
@@ -49,8 +49,17 @@
       <thead><tr><th>account</th><th>public bal</th><th>confidential</th><th>approved</th></tr></thead>
       <tbody></tbody>
     </table>
-    <p class="fine">Accounts, transactions and public token balances are visible. Confidential transfer
+    <p class="fine" id="ledger-note">Accounts, transactions and public token balances are visible. Confidential transfer
       amounts and confidential balances are encrypted.</p>
+    <div id="elsewhere" class="elsewhere" hidden>
+      <h3>THE SAME TRADE ELSEWHERE <em>who reads the amount</em></h3>
+      <div class="ew"><span>DEX swap</span><span class="warnc">everyone · <b id="ew-dex"></b></span></div>
+      <div class="ew"><span>exchange</span><span>the exchange, which holds the assets</span></div>
+      <div class="ew"><span>dark pool</span><span>its operator or relayer</span></div>
+      <div class="ew here"><span>Confide</span><span class="okc">the two parties · public balance 0</span></div>
+      <p class="fine">Here the amounts and balances are encrypted; still public are the accounts, the
+        mints, and that the trade happened. Sources: docs/cwf-2026/COMPARABLES.md</p>
+    </div>
     <h3>POSITIONS <em>each read with its holder's own key</em></h3>
     <table class="tbl" id="positions">
       <thead><tr><th>holder</th><th>asset</th><th class="num">units</th></tr></thead>
diff --git a/app/static/ops.js b/app/static/ops.js
index ef91b5c..7377cb1 100644
--- a/app/static/ops.js
+++ b/app/static/ops.js
@@ -50,6 +50,8 @@ function reset() {
   for (const id of ["queue", "mints", "public", "positions", "blotter"]) document.querySelector(`#${id} tbody`).textContent = "";
   for (const id of ["ticket-1", "ticket-2"]) { const t = document.getElementById(id); t.textContent = ""; t.className = "ticket idle"; }
   document.getElementById("placeholder").style.display = "";
+  document.getElementById("elsewhere").hidden = true;
+  document.getElementById("ledger-note").hidden = false;
   next(null);
 }
 
@@ -170,6 +172,8 @@ async function readPublic(a) {
 const H = {
   run(e) { S.short = e.mode === "short"; status(S.short ? "running · short-delivery control" : "running"); },
   waiting(e) { next(e.next); status("waiting for: " + (STEPS[e.next] ? STEPS[e.next][1] : e.next)); },
+  // the server's record that a step was taken: on a replay it follows that step's "waiting"
+  advanced(e) { next(null); status("working on devnet: " + (STEPS[e.step] ? STEPS[e.step][1] : e.step)); },
   party(e) { S.parties[e.who] = e.pubkey; },
   mint(e) { S.mints[e.asset] = e; renderMints(); blot(ASSET[e.asset] + " mint created", "GATE SHUT", "warn", link("address", e.mint), "ISSUER", "TOKEN-2022"); },
   account(e) {
@@ -239,6 +243,14 @@ const H = {
     const accs = e.accounts.split(","), bals = e.balances.split(",");
     accs.forEach((a, i) => { if (S.accounts[a]) S.accounts[a].pub = bals[i]; });
     renderLedger(); blot("public balances read back", "ALL ZERO", "ok", null, "ANYONE", "SOLANA RPC");
+    // The comparison appears only once the run has read its own public balances back, and the
+    // DEX row's figures are this trade's, from the run's own checkpoints -- nothing typed here.
+    const t = e.act === "2" ? S.t2 : S.t1;
+    if (t.shares && t.cash && bals.every((b) => b === "0")) {
+      document.getElementById("ew-dex").textContent = `${n(t.shares)} shares · $${n(t.cash)}`;
+      document.getElementById("elsewhere").hidden = false;
+      document.getElementById("ledger-note").hidden = true;   // its content is the block's last line
+    }
   },
   offer(e) {
     S.act = 2; S.t2.shares = e.shares; S.t2.cash = e.cash; S.t2.stages.pin1 = "ok";
diff --git a/app/test_app.py b/app/test_app.py
index b1acfa9..cbfee55 100644
--- a/app/test_app.py
+++ b/app/test_app.py
@@ -185,6 +185,14 @@ class ServerTests(unittest.TestCase):
         self.assertEqual(self.post("/advance", {"step": "first"})[0], 409)
         seen = self.events(lambda e: e.get("ev") == "waiting" and e.get("next") == "second")
         names = [e["ev"] for e in seen]
+        # A FRESH CONNECTION REPLAYS FROM THE START, and the page draws a button for every "waiting".
+        # The step already taken must be followed by the server's "advanced", or the page redraws a
+        # live button for it -- the 2026-10-02 recordings pressed one twenty times after a reconnect.
+        w = names.index("waiting")
+        self.assertEqual(seen[w].get("next"), "first")
+        self.assertIn({"ev": "advanced", "step": "first"},
+                      [{k: e[k] for k in ("ev", "step")} for e in seen[w + 1:] if e["ev"] == "advanced"],
+                      "a replay re-offers a step that was already advanced")
         self.assertNotIn("not_a_real_event", names)
         blob = json.dumps(seen)
         self.assertNotIn("secret-key-abc123", blob, "the RPC endpoint reached the page")
diff --git a/video/DEMO.md b/video/DEMO.md
index 4cced3d..df79f47 100644
--- a/video/DEMO.md
+++ b/video/DEMO.md
@@ -32,44 +32,44 @@ held about 4% under the video rather than at it.
 
 | | scene | seconds (+ silence) | words | pace | what it shows |
 |---|---|---|---|---|---|
-| 1 | a stock shut the way the real ones are | 22 | 49 | 137 | 0:00–0:24 — both mints appear under MINT POLICY with `APPROVAL REQUIRED · auditor: none`; the investor's cash account is approved and funded, then its stock account lands in the approval queue as `PENDING`. The blotter's `done by` column reads `TOKEN-2022` for all of it |
-| 2 | Confide builds the proofs and checks the amount | 12 | 25 | 132 | 0:24–0:36 — the Act 1 ticket appears (20,000 shares ⇄ $3,500,000), `PROOFS BUILT · CHAIN-VERIFIED` and `PRE-SIGN CHECK` turn green with `CONFIDE` beside them, and the first two lines of CONFIDE IN THIS RUN tick |
-| 3 | the gate holds | 15 | 34 | 142 | 0:36–0:52 — `SENT BEFORE APPROVAL · TOKEN-2022` turns red; the blotter shows `REFUSED · Custom(24)` with its signature, then `REFUSED · not the authority`; the queue marks the account `SELF-APPROVAL REFUSED` |
-| 4 | approval, then one transaction | 20 | 45 | 139 | 0:52–1:14 — `ISSUER APPROVES` green, `ONE SIGNATURE ONLY · SOLANA` red, then `BOTH SIGNATURES · SETTLED · CONFIDE + TOKEN-2022` with the settlement signature and its compute units |
-| 5 | what anyone can see | 7 | 14 | 131 | 1:14–1:22 — the public ledger, every account `0` and `ENCRYPTED`; beside it, each holder's position read with its own key, labelled as shown together only because one presenter holds every key |
-| 6 | two approved holders trade | 30 | 66 | 135 | 1:22–1:53 — the Act 2 ticket (5,000 ⇄ $875,000): `TERMS PINNED` on both sides, `INVESTOR CHECK`, `HOLDER 2 CHECK + BINDING`, then `BOTH SIGNATURES · SETTLED`, every stage marked `CONFIDE` |
-| 7 | the short-delivery control | 24 + 12 | 54 | 138 | 1:53–2:34 — a fresh run's setup, fast-forwarded with its badge (the silence sits here, before "Before any signature exists"), then `PRE-SIGN CHECK · CONFIDE` turns red and the ticket reads `investor decrypted 2,000 shares · agreed 20,000 → REFUSED, nothing signed` |
-| 8 | what Confide did | 20 | 44 | 136 | 2:34–2:55 — the final frame held: CONFIDE IN THIS RUN with its ticks, the red pre-sign check, the blotter reading `SHORT · REFUSED — CONFIDE` |
-| | | **162 s** | **331** | | |
+| 1 | a stock shut the way the real ones are | 20 | 44 | 136 | 0:00–0:21 — both mints appear under MINT POLICY with `APPROVAL REQUIRED · auditor: none`; the investor's cash account is approved and funded, then its stock account lands in the approval queue as `PENDING`. The blotter's `done by` column reads `TOKEN-2022` for all of it |
+| 2 | Confide builds the proofs and checks the amount | 11 | 24 | 138 | 0:21–0:33 — the Act 1 ticket appears (20,000 shares ⇄ $3,500,000), `PROOFS BUILT · CHAIN-VERIFIED` and `PRE-SIGN CHECK` turn green with `CONFIDE` beside them, and the first two lines of CONFIDE IN THIS RUN tick |
+| 3 | the gate holds | 14 | 30 | 134 | 0:33–0:48 — `SENT BEFORE APPROVAL · TOKEN-2022` turns red; the blotter shows `REFUSED · Custom(24)` with its signature, then `REFUSED · not the authority`; the queue marks the account `SELF-APPROVAL REFUSED` |
+| 4 | approval, then one transaction | 20 | 45 | 139 | 0:48–1:11 — `ISSUER APPROVES` green, `ONE SIGNATURE ONLY · SOLANA` red, then `BOTH SIGNATURES · SETTLED · CONFIDE + TOKEN-2022` with the settlement signature and its compute units |
+| 5 | what anyone can see | 16 | 36 | 140 | 1:11–1:28 — the public ledger, every account `0` and `ENCRYPTED`, and under it THE SAME TRADE ELSEWHERE: a DEX swap read by everyone, with this trade's own 20,000 shares · $3,500,000; an exchange and a dark pool read by their operator; Confide, the two parties and a public balance of 0. Each row is sourced in `docs/cwf-2026/COMPARABLES.md` |
+| 6 | two approved holders trade | 28 | 62 | 136 | 1:28–1:58 — the Act 2 ticket (5,000 ⇄ $875,000): `TERMS PINNED` on both sides, `INVESTOR CHECK`, `HOLDER 2 CHECK + BINDING`, then `BOTH SIGNATURES · SETTLED`, every stage marked `CONFIDE` |
+| 7 | the short-delivery control | 24 + 12 | 54 | 138 | 1:58–2:37 — a fresh run's setup, fast-forwarded with its badge (the silence sits here, before "Before any signature exists"), then `PRE-SIGN CHECK · CONFIDE` turns red and the ticket reads `investor decrypted 2,000 shares · agreed 20,000 → REFUSED, nothing signed` |
+| 8 | what Confide did | 15 | 34 | 142 | 2:37–2:53 — the final frame held: CONFIDE IN THIS RUN with its ticks, the red pre-sign check, the blotter reading `SHORT · REFUSED — CONFIDE` |
+| | | **160 s** | **329** | | |
 
 ## The script
 
 ### 1 — a stock shut the way the real ones are
 
-> This is Confide on devnet, in a local demo where one presenter holds every key; waits on the chain
-> are fast-forwarded, with the real time on the badge. The issuer's mints carry the two settings we
-> found on all 1,992 measured equity mints: issuer approval required, no auditor key.
+> This is Confide on devnet, in a local demo where one presenter holds every key; chain waits are
+> fast-forwarded, real time on the badge. The issuer's mints carry the two settings we found on all
+> 1,992 measured equity mints: approval required, no auditor key.
 
-*Shows:* 0:00–0:24 — both mints appear under MINT POLICY with `APPROVAL REQUIRED · auditor: none`;
+*Shows:* 0:00–0:21 — both mints appear under MINT POLICY with `APPROVAL REQUIRED · auditor: none`;
 the investor's cash account is approved and funded, then its stock account lands in the approval
 queue as `PENDING`. The blotter's `done by` column reads `TOKEN-2022` for all of it.
 
 ### 2 — Confide builds the proofs and checks the amount
 
-> An investor's new account waits for approval. Confide builds both legs' proofs, the chain verifies
-> them, and the investor's client checks the amount before signing.
+> A new investor account waits for approval. Confide builds both legs' proofs, the chain verifies
+> them, and the investor checks the amount before signing.
 
-*Shows:* 0:24–0:36 — the Act 1 ticket appears (20,000 shares ⇄ $3,500,000), `PROOFS BUILT ·
+*Shows:* 0:21–0:33 — the Act 1 ticket appears (20,000 shares ⇄ $3,500,000), `PROOFS BUILT ·
 CHAIN-VERIFIED` and `PRE-SIGN CHECK` turn green with `CONFIDE` beside them, and the first two lines
 of CONFIDE IN THIS RUN tick.
 
 ### 3 — the gate holds
 
-> The issuer sends the allocation; Token-2022 refuses it, because the account isn't approved. The
-> investor tries approving itself: refused. Only the mint's approval authority — here, the issuer's
-> key — can open this account.
+> The issuer sends the allocation; Token-2022 refuses it: the account isn't approved. The investor
+> tries approving itself: refused. Only the mint's approval authority, here the issuer's key, can
+> open it.
 
-*Shows:* 0:36–0:52 — `SENT BEFORE APPROVAL · TOKEN-2022` turns red; the blotter shows `REFUSED ·
+*Shows:* 0:33–0:48 — `SENT BEFORE APPROVAL · TOKEN-2022` turns red; the blotter shows `REFUSED ·
 Custom(24)` with its signature, then `REFUSED · not the authority`; the queue marks the account
 `SELF-APPROVAL REFUSED`.
 
@@ -80,27 +80,29 @@ Custom(24)` with its signature, then `REFUSED · not the authority`; the queue m
 > thousand shares for three and a half million dollars, one atomic transaction that Confide
 > assembled.
 
-*Shows:* 0:52–1:14 — `ISSUER APPROVES` green, `ONE SIGNATURE ONLY · SOLANA` red, then `BOTH
+*Shows:* 0:48–1:11 — `ISSUER APPROVES` green, `ONE SIGNATURE ONLY · SOLANA` red, then `BOTH
 SIGNATURES · SETTLED · CONFIDE + TOKEN-2022` with the settlement signature and its compute units.
 
 ### 5 — what anyone can see
 
-> The mint, accounts and transactions stay public. Public balances read zero; amounts are
-> encrypted.
+> The mint, accounts and transactions stay public; every balance reads zero. Through a DEX, everyone
+> would read this trade's size; through an exchange or a dark pool, the operator would. Here, only the
+> two parties can.
 
-*Shows:* 1:14–1:22 — the public ledger, every account `0` and `ENCRYPTED`; beside it, each holder's
-position read with its own key, labelled as shown together only because one presenter holds every
-key.
+*Shows:* 1:11–1:28 — the public ledger, every account `0` and `ENCRYPTED`, and under it THE SAME TRADE
+ELSEWHERE: a DEX swap read by everyone, with this trade's own 20,000 shares · $3,500,000; an exchange
+and a dark pool read by their operator; Confide, the two parties and a public balance of 0. Each row
+is sourced in `docs/cwf-2026/COMPARABLES.md`.
 
 ### 6 — two approved holders trade
 
 > The investor offers five thousand shares for eight hundred
 > seventy-five thousand dollars, terms agreed off chain. Confide pins them on each side before any
-> proof exists; each side checks what it receives against its own pin, and the second signer
-> verifies the exact transaction. It settles atomically. With no auditor key on these mints, the
+> proof exists; each side checks what it receives against its pin, and the second signer
+> verifies the exact transaction. It settles atomically. With no auditor key, the
 > issuer's approval does not make it a reader of the amounts.
 
-*Shows:* 1:22–1:53 — the Act 2 ticket (5,000 ⇄ $875,000): `TERMS PINNED` on both sides, `INVESTOR
+*Shows:* 1:28–1:58 — the Act 2 ticket (5,000 ⇄ $875,000): `TERMS PINNED` on both sides, `INVESTOR
 CHECK`, `HOLDER 2 CHECK + BINDING`, then `BOTH SIGNATURES · SETTLED`, every stage marked `CONFIDE`.
 
 ### 7 — the short-delivery control · + 12 s silence
@@ -110,17 +112,17 @@ CHECK`, `HOLDER 2 CHECK + BINDING`, then `BOTH SIGNATURES · SETTLED`, every sta
 > client decrypts the amount addressed to it, finds two thousand where twenty thousand was agreed,
 > and refuses. Nothing is signed. Nothing moves.
 
-*Shows:* 1:53–2:34 — a fresh run's setup, fast-forwarded with its badge (the silence sits here, before
+*Shows:* 1:58–2:37 — a fresh run's setup, fast-forwarded with its badge (the silence sits here, before
 "Before any signature exists"), then `PRE-SIGN CHECK · CONFIDE` turns red and the ticket reads
 `investor decrypted 2,000 shares · agreed 20,000 → REFUSED, nothing signed`.
 
 ### 8 — what Confide did
 
-> Token-2022 and Solana enforce the rules. Confide does the work around them: proofs, checks before
-> signing, pinned terms, and one transaction for delivery and payment. It is not a venue and does no
-> matching. This is devnet; no real issuer has used it yet.
+> Token-2022 and Solana enforce the rules; Confide does the work around them: proofs, checks before
+> signing, pinned terms, one transaction. Not a venue, no matching. This is devnet; no real issuer
+> uses it yet.
 
-*Shows:* 2:34–2:55 — the final frame held: CONFIDE IN THIS RUN with its ticks, the red pre-sign check,
+*Shows:* 2:37–2:53 — the final frame held: CONFIDE IN THIS RUN with its ticks, the red pre-sign check,
 the blotter reading `SHORT · REFUSED — CONFIDE`.
 
 ## What this video does not claim
diff --git a/video/cut-app.js b/video/cut-app.js
index e4b992c..83b1505 100644
--- a/video/cut-app.js
+++ b/video/cut-app.js
@@ -24,7 +24,7 @@ const FFPROBE = FFMPEG.replace(/ffmpeg$/, "ffprobe");
 // are shortened. Overridable, and whatever is used is written to the manifest.
 const WINDOW = +(process.env.CUT_WINDOW || 0.4);          // seconds kept at real speed at each end of a wait
 const SHORTEN_OVER = +(process.env.CUT_SHORTEN_OVER || 3); // waits no longer than this are left alone
-const FF_SECONDS = +(process.env.CUT_FF_SECONDS || 1.1);   // what the middle of a long wait is played in
+const FF_SECONDS = +(process.env.CUT_FF_SECONDS || 1.0);   // what the middle of a long wait is played in (1.1 until 2026-10-02: the comparison scene needed 2 s)
 const raw = path.join(R, "raw.mp4");
 const { marks, end, normal, short } = JSON.parse(readFileSync(path.join(R, "marks.json"), "utf8"));
 // A recording that did not end the way the demo says it does is not cut, and gets no manifest
diff --git a/video/record-app.js b/video/record-app.js
index 1803456..dc9d364 100644
--- a/video/record-app.js
+++ b/video/record-app.js
@@ -41,7 +41,11 @@ const READ = {
   "Check the cash against my pin, sign once": 5500,
   "Check the shares against my pin, add the second signature": 6500,
 };
-const DEFAULT_READ = 2600;
+const DEFAULT_READ = 2200;
+// The FIRST public view holds longer: it is where the panel shows the same trade elsewhere -- who
+// would read the amount on a DEX, an exchange, a dark pool -- and the narration compares them
+// (video/DEMO.md scene 5). The time comes out of DEFAULT_READ above, so the cut stays under 3:00.
+const FIRST_LOOK = 15500;
 
 const browser = await puppeteer.launch({
   headless: "new",
@@ -67,6 +71,7 @@ const now = () => (Date.now() - t0) / 1000;
 const marks = [];
 const mark = (m) => { marks.push({ t: +now().toFixed(3), ...m }); process.stderr.write(`• ${now().toFixed(1)}s ${JSON.stringify(m)}\n`); };
 
+let looked = false;
 async function run(button, mode) {
   await sleep(2500);
   mark({ kind: "start", mode });
@@ -75,6 +80,7 @@ async function run(button, mode) {
   await page.waitForFunction(() => /^(running|waiting)/i.test(document.getElementById("status").textContent),
                              { timeout: 60000, polling: 100 });
   let shown = null; // the label of the step whose result is now on screen
+  let clicked = null; // the last step pressed -- it must not be offered again straight away
   for (;;) {
     const h = await page.waitForFunction(() => {
       const st = document.getElementById("status").textContent;
@@ -87,11 +93,20 @@ async function run(button, mode) {
     const v = await h.jsonValue();
     mark({ kind: "ready", mode, ...v });
     if (v.fail) throw new Error(`the run failed on screen: ${v.fail}`);
-    await sleep((shown && READ[shown]) || DEFAULT_READ);
+    const firstLook = shown === "Look from outside" && mode === "normal" && !looked;
+    if (firstLook) looked = true;
+    await sleep(firstLook ? FIRST_LOOK : (shown && READ[shown]) || DEFAULT_READ);
     if (v.done) return v.done;
+    // A STEP OFFERED AGAIN AFTER ITS CLICK IS A BROKEN RECORDING, NOT A SLOW ONE. On 2026-10-02 the
+    // SHORT run's "Build both legs' proofs" button came back after its click and was pressed 19 more
+    // times -- every press refused by the server (409, not the step the script awaited) and re-enabled
+    // by the page -- and the cut that followed ran 3:21. Stop instead of filming it.
+    if (v.step && v.step === clicked && v.step !== "Look from outside") {
+      throw new Error(`"${v.step}" was offered again after it was pressed -- the page and the script disagree`);
+    }
     mark({ kind: "click", mode, step: v.step });
     await page.click("button.next");
-    shown = v.step;
+    shown = v.step; clicked = v.step;
   }
 }
 

--- video/PITCH.md ---
# The pitch video — ≤2 minutes, the founder on camera

**The form, read 2026-10-02:** *"Separate from the demo video — introduce yourselves, tell us what
you're building, and tell us why you're the people to build it. Nothing fancy required. We're
interested in how you think and communicate. YouTube, Loom, or Vimeo. Up to 2 minutes."* **Public.**

**This one is the founder's, start to finish.** The camera, the voice, and three facts nobody else
can supply are marked `[FOUNDER: …]`. Nothing here invents a background:
[`../docs/cwf-2026/FOUNDER-MARKET-FIT.md`](../docs/cwf-2026/FOUNDER-MARKET-FIT.md) says what not to
claim, and it applies here first.

**The comparison lives here, not in the demo.** The demo form asks for *"the live product, not a slide
deck"*, so the demo shows the comparison only inside the product (the PUBLIC LEDGER panel). The pitch
is where *"how you think"* is asked for, and the one idea worth getting across is a single question
asked of every way to trade size: **who reads the amount?** Each answer is sourced in
[`../docs/cwf-2026/COMPARABLES.md`](../docs/cwf-2026/COMPARABLES.md).

**Held well under two minutes.** The table below predicts at 137 words a minute; a speaker on camera,
pausing to think, runs slower, and check-in 2 already came out four per cent long. The founder's
three lines will add words. **Time a read-through before recording**; if it runs over 1:50, cut scene
4's second sentence first.

<!-- pace.py owns the table below. Do not hand-edit it: `python3 video/pace.py --write`. -->

| | scene | seconds (+ silence) | words | pace | what it shows |
|---|---|---|---|---|---|
| 1 | who | 9 | 19 | 136 | the founder, on camera |
| 2 | who reads the amount | 23 | 52 | 139 | the founder; optionally the five-row comparison from COMPARABLES.md as a still behind or beside them |
| 3 | what Confide is | 23 | 52 | 139 | the founder; optionally two seconds of the demo's PUBLIC LEDGER panel |
| 4 | what is true today | 20 | 44 | 136 | the founder |
| 5 | why me | 17 | 38 | 139 | the founder |
| | | **92 s** | **205** | | |

## The script

### 1 — who

> I'm [FOUNDER: name], building Confide alone, from Japan. [FOUNDER: one sentence — what you did
> before, true and checkable.]

*Shows:* the founder, on camera.

### 2 — who reads the amount

> When a fund trades a large block of a tokenized stock, someone reads the size. On a DEX, everyone
> does. On an exchange, the exchange does, and it holds the asset. In a dark pool, the operator
> does. Even in US markets, a block's size reaches the public tape within ten seconds.

*Shows:* the founder; optionally the five-row comparison from COMPARABLES.md as a still behind or
beside them.

### 3 — what Confide is

> Confide is the privacy layer for issuer-approved tokenized stocks on Solana. The issuer approves
> exactly which accounts may hold privately. Two approved holders agree a price, each checks what it
> will receive before signing, and stock and stablecoin settle in one transaction. Everyone else
> sees that a trade happened, never how much.

*Shows:* the founder; optionally two seconds of the demo's PUBLIC LEDGER panel.

### 4 — what is true today

> Every mint in three issuers' tokenized-stock catalogues already has this switched on. Where I
> counted, nobody has been approved to use it. Confide runs end to end on devnet, in one command,
> re-checked from the chain. No issuer uses it yet; traction is zero.

*Shows:* the founder.

### 5 — why me

> I build by measuring what is actually deployed, and I write down when I was wrong, including about
> who the customer is. [FOUNDER: one sentence — why this problem, for you.] Next is one conversation
> with an issuer.

*Shows:* the founder.

## Every claim, and where it stands

| line | evidence |
|---|---|
| DEX / exchange / dark pool / ten seconds | [`COMPARABLES.md`](../docs/cwf-2026/COMPARABLES.md) — FINRA Rule 6380A, *"no later than 10 seconds after execution"* |
| the issuer approves exactly which accounts | [`CLAIMS.md`](../docs/cwf-2026/CLAIMS.md) M3, D1–D3 |
| each checks before signing; one transaction | CLAIMS L1, D5, D7 |
| a trade happened, never how much | CLAIMS P1 — accounts and the fact of the trade are public |
| every mint in three catalogues has it on | CLAIMS M1 — a catalogue, not a census of the chain |
| where I counted, nobody approved | CLAIMS M4 — six mints |
| end to end, one command, re-checked | [`REVIEW-RUNS.md`](../docs/cwf-2026/REVIEW-RUNS.md) |
| wrong about the customer | FOUNDER-MARKET-FIT §2 — the dated reversal |
| traction is zero | CLAIMS A1 |

--- docs/cwf-2026/COMPARABLES.md ---
# How size trades in tokenized stocks happen today — and who sees them

Researched 2026-10-02 for the videos, from primary sources where they exist. Two claims were
re-checked by hand against the source the same day (marked ✓). **Anything not traced to a primary
source is marked UNVERIFIED and must not be spoken.**

The question each row answers is the one Confide is built around: **when somebody trades size, who
can see how much?**

| | who can see the amount | in the middle | settles atomically on chain | the issuer's approval gate |
|---|---|---|---|---|
| **Solana DEX** — Raydium, Jupiter, Kamino Swap | **everyone** — an ordinary public swap | a pool | yes | not applicable |
| **Centralized exchange** — Kraken, Bybit spot xStocks | **the exchange** | the exchange, holding the assets | no — its own ledger | not applicable |
| **On-chain dark pool** — Renegade (Arbitrum, Base) | **the relayer**, in plaintext ✓ | relayer + MPC matching | yes ("atomic settlement") | not stated |
| **Encrypted compute** — Arcium (Solana) | no single node; all but one must collude | a permissioned MPC cluster (Mainnet Alpha) | not stated | not stated |
| **US equity dark pool (ATS)** | **the public tape, within 10 seconds of execution** ✓ — size and price; the venue's name is published weeks later | the operator / broker | not on chain | not applicable |
| **Confide** | **the two parties only** — every other reader sees a public balance of 0 | **nobody** | **yes — one transaction, two signatures** | **kept**: an unapproved account is refused by Token-2022 |

**What Confide does NOT hide, said next to the table, never after it.** The accounts, the mints, and
the fact that a transaction happened are public. A US dark pool is the mirror image: the size is on
the tape and the counterparties are not. So the claim is **"the amount stays private"**, never "more
private than traditional markets".

**What this table does not say.** That the others are wrong. Each is built for something else —
continuous matching, custody, general private computation. No live product doing confidential,
issuer-gated delivery-versus-payment for tokenized stocks on Solana was found; that is the result
of a search, not proof of absence, and is to be said as "we did not find one" if at all.

## Sources

**Solana DEX.** Backed, 2025-06-30: *"Raydium is the liquidity hub for tokenized equities on
Solana"*; available *"on Kamino… through Kamino Swap"*; Jupiter integrated.
https://backed.fi/news-updates/xstocks-are-going-live-tokenized-stocks-for-the-defi-era — that these
swaps are public follows from how a Solana token swap works; no source says it in one sentence.

**Centralized exchange.** Same Backed page: Kraken *"listing xStocks on its Spot platform on day
one"*; Bybit in the xStocks Alliance. Custody and an internal ledger are what a centralized exchange
is, not separately sourced. OTC block desks *for xStocks specifically*: UNVERIFIED.

**Renegade.** Site: *"an on-chain dark pool"*, *"Live today on Arbitrum and Base"*, *"Trade any
ERC-20"* — https://renegade.fi/ . ✓ README: *"Each relayer maintains some set of plaintext orders
known only to the relayer."* — https://github.com/renegade-fi/renegade . Help center (search snippet;
the page did not fetch): wallets connect to a relayer *"which can view their orders and balances in
plaintext"*. Atomic settlement: zkSecurity audit, https://reports.zksecurity.xyz/reports/renegade-atomic-settlement

**Arcium.** Mainnet Alpha, 2026-02-04: independent node operators in a *"permissioned configuration"*
— https://arcium.substack.com/p/arcium-mainnet-alpha-is-live . Docs: inputs *"hidden from any single
node"* — https://docs.arcium.com/ . Cerberus: secure while *"all but one of the n parties may be
corrupted"* — https://www.arcium.com/research/cerberus . A live Arcium dark pool for tokenized
stocks: not found.

**US ATS.** ✓ FINRA Rule 6380A: reported *"as soon as practicable but no later than 10 seconds after
execution"* — https://www.finra.org/rules-guidance/rulebooks/finra-rules/6380a . Tape reports go *"to a
TRF for public dissemination"* — https://www.finra.org/filing-reporting/market-transparency-reporting/trade-reporting-faq .
ATS volume by venue: published after *"two weeks for Tier 1 NMS stocks to four weeks for OTC
equities"* — https://www.finra.org/rules-guidance/notices/19-22

**Not in the table, and why.** Penumbra — Penumbra Labs *"is winding down operations"*
(https://penumbralabs.xyz/), its own chain. Railgun — a shielded pool on Ethereum, BSC, Polygon and
Arbitrum (https://docs.railgun.org/wiki); swap visibility through external venues UNVERIFIED.
Elusiv — rebranded to Arcium (https://x.com/elusivprivacy/status/1787962124800569603). Light
Protocol — acquired by Helius to build a privacy layer not yet shipped
(https://www.helius.dev/blog/light-protocol-acquisition). GoDark — secondary sources only.

**Confide's own row** is evidence in this repository: `docs/cwf-2026/CLAIMS.md` D1, D3, D5, D7, P1;
the passing run in `docs/cwf-2026/REVIEW-RUNS.md`.
