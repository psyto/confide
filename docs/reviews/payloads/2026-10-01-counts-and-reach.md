# Review request — the account count, the six-mint scope, and the auditor's reach, 2026-10-01

Three corrections, all to public-facing surfaces (README, the published site's source, the YouTube
description, the CWF form draft, docs, script comments), plus two checks.

1. **"Three have asked" → two.** web/usage.json (2026-09-28) records 2 configured, 0 approved; one of
   three earlier accounts was closed (STATUS 0bn/934). README's table said 3 ("two on NVDAx") too.
2. **The six-mint sample stretched to all mints.** usage-scan.sh counts six mints, two per issuer.
   "No issuer has signed ... there is no incumbent here", "On every one of the 1,992 real mints that is
   impossible ... none has", "On mainnet it cannot be done" are scoped to the mints counted now.
3. **The auditor key "decrypts everyone's everything, forever".** It can decrypt the amount of every
   confidential transfer made while it is set, for every holder; it does not see a whole balance or
   transfers before it was set (brief §1). Fixed on live surfaces; recorded narration/captions are
   pinned as published.
4. Checks: THE ACCOUNT SCAN now reads "N have asked/configured/tried" (digit or word, table cell or
   prose); new THE AUDITOR'S REACH bans the overstated phrasings outside sha-pinned published files.
   Five deliberate breakages each failed.

Also: while regenerating the YouTube paste I copied an EMPTY temp file over youtube-paste.txt after the
generator failed on the 5,000-char limit; caught before commit, restored from git, redone with an
exit-code and size guard. Said here so it is judged, not hidden.

Questions:
1. Does any rewrite now underclaim or introduce a new overclaim? Especially README's "where we looked
   there is no incumbent", the site's "Two have asked; no issuer has approved one", ISSUANCE-RUNS'
   rewrite, and the YouTube line "no account we counted is approved for one".
2. Are there live surfaces still saying three, or generalising the six-mint count, or overstating the
   auditor key, that these checks miss? Grep yourself.
3. Is the ACCOUNT SCAN pattern too loose (false positives) or too narrow?

## Diff
```diff
diff --git a/DESIGN.md b/DESIGN.md
index 4a4273f..4b87256 100644
--- a/DESIGN.md
+++ b/DESIGN.md
@@ -59,8 +59,8 @@ this project is not about sandwiching. They do nothing about the **settled balan
 permanent public record of what you hold. Different axis entirely.
 
 **"Use Token-2022 confidential balances."** Confidential-balance primitives hide the amount from
-*everyone, forever*, and ship only a crude global-auditor model: one key that decrypts everything,
-for all time. That is not a 13F. That is all-or-nothing. The regulatory shape you need —
+*everyone, forever*, and ship only a crude mint-wide auditor model: one key that can decrypt the
+amount of every confidential transfer made while it is set, for every holder. That is not a 13F. That is all-or-nothing. The regulatory shape you need —
 *the auditor sees now, the public sees at T* — is not expressible.
 
 **"Trade through a custodian / a fresh wallet each time."** An omnibus custodian is today's
diff --git a/README.md b/README.md
index 2e83a94..71e8934 100644
--- a/README.md
+++ b/README.md
@@ -87,12 +87,13 @@ the price it implies.
 |---|---|
 | **1,992** | tokenized stocks ship confidential balances — every one of them |
 | **518,744** | live token accounts across Apple, NVIDIA, SpaceX, Anthropic and AMC |
-| **3** | have asked for a confidential balance — two on `NVDAx`, one on `AAPLx` |
+| **2** | have asked for a confidential balance — one on `NVDAx`, one on `AAPLx` |
 | **0** | have been approved. **Nobody is through the gate.** |
 
-Counted from mainnet by `./scripts/usage-scan.sh`. The feature is shipped on every mint and gated
-on every mint, and no issuer has signed for an account yet — **so there is no incumbent here and
-nothing to be late to.**
+Counted from mainnet by `./scripts/usage-scan.sh`, on six mints — two per issuer — on 2026-09-28. The
+feature is shipped and gated on every mint in the list; on the six counted, no issuer has approved an
+account yet — **so where we looked there is no incumbent and nothing to be late to.** The other mints
+in the list have not been counted.
 
 ## Go and do it yourself — two minutes, devnet, nobody's permission
 
@@ -238,8 +239,9 @@ $ ./scripts/usage-scan.sh
   518744 token accounts across 6 mints, 2 configured for confidential transfers, 0 approved by an issuer
 ```
 
-Not "few". **Zero.** Every mint needs the issuer's signature to open a confidential account, and
-no issuer has signed. There is no incumbent here and nothing to be late to.
+Not "few". **Zero.** A holder can configure a confidential account, but only the issuer's approval
+makes it usable, and on the six mints counted no issuer has approved one. Where we looked there is no
+incumbent and nothing to be late to.
 
 The feature is shipped, configured, and **inert**. Token-2022 offers exactly one disclosure model —
 a single mint-wide auditor key that can decrypt the amount of **every confidential transfer made
diff --git a/_submission/cwf-form.md b/_submission/cwf-form.md
index 50a96d6..6abb0b3 100644
--- a/_submission/cwf-form.md
+++ b/_submission/cwf-form.md
@@ -20,7 +20,7 @@ Confide
 ## Brief description · Public · ≤500
 
 ```
-Confidential delivery-versus-payment for tokenized stocks on Solana: a stock-to-stablecoin swap in one transaction, with neither side publishing what moved. Confide builds the proofs the chain will not assemble and lets each side check the other before signing, with nobody in the middle. All 1,992 tokenized stocks from three issuers' catalogues already ship confidential balances. Of 518,744 live accounts, two have configured one and zero are approved — no issuer has signed.
+Confidential delivery-versus-payment for tokenized stocks on Solana: a stock-to-stablecoin swap in one transaction, with neither side publishing what moved. Confide builds the proofs the chain will not assemble and lets each side check the other before signing, with nobody in the middle. All 1,992 tokenized stocks from three issuers' catalogues already ship confidential balances. Of 518,744 live accounts, two have configured one and zero are approved by an issuer.
 ```
 
 ## Project website · Public
diff --git a/_submission/youtube-paste.txt b/_submission/youtube-paste.txt
index 73cd915..ec41e7f 100644
--- a/_submission/youtube-paste.txt
+++ b/_submission/youtube-paste.txt
@@ -7,7 +7,7 @@ DESCRIPTION
 ===========
 Confide settles a tokenized-stock trade against stablecoins in ONE Solana transaction, and neither side publishes what moved. On devnet today.
 
-A real Solana account reports a balance of zero. It holds 173,000 shares of tokenized stock — and nobody has been allowed to open one.
+A real Solana account reports a balance of zero. It holds 173,000 shares of tokenized stock — and no account we counted is approved for one.
 
 On 17 September the SEC gave tokenized stock five years of relief, and set the conditions: AMM-executed trading only, every fill's size, time and direction published within ten minutes, a Tier 1 name capped at 0.25% of daily volume. Block trades have always settled away from that tape. Nobody had built the block. Confide is not a venue, so the exemption neither covers it nor is needed.
 
@@ -37,7 +37,7 @@ All 1,992 tokenized-equity mints from three issuers' catalogues run Token-2022 w
 
 The same 1,992 carry permanentDelegate, pausableConfig and a transfer hook — the issuer can freeze a transfer, seize a holder's tokens, run their own code. Token-2022's only disclosure model is mint-wide: one auditor key, reading every transfer while it is set, scoped to nobody. Everybody readable, or nobody. Why it is empty is unmeasured: empty is also the default.
 
-Then the half nobody counted: has anybody USED it? 518,744 live token accounts across Apple, NVIDIA, SpaceX and AMC. TWO have configured a confidential account — one on NVDAx, one on AAPLx. ZERO are approved — none until an issuer signs.
+Then the half nobody counted: has anybody USED it? 518,744 live token accounts across six mints. TWO have configured a confidential account — one on NVDAx, one on AAPLx. ZERO are approved — none until an issuer signs.
 
 Not only equities: PYUSD and USDG land on the same configuration.
 
diff --git a/_submission/youtube.md b/_submission/youtube.md
index 95d1a43..df788f8 100644
--- a/_submission/youtube.md
+++ b/_submission/youtube.md
@@ -19,12 +19,12 @@ missing scene back from the script.
 Confide — private block trades for tokenized stocks, settled in one Solana transaction
 ```
 
-## Description — 4986 / 5000 characters
+## Description — 4972 / 5000 characters
 
 ```
 Confide settles a tokenized-stock trade against stablecoins in ONE Solana transaction, and neither side publishes what moved. On devnet today.
 
-A real Solana account reports a balance of zero. It holds 173,000 shares of tokenized stock — and nobody has been allowed to open one.
+A real Solana account reports a balance of zero. It holds 173,000 shares of tokenized stock — and no account we counted is approved for one.
 
 On 17 September the SEC gave tokenized stock five years of relief, and set the conditions: AMM-executed trading only, every fill's size, time and direction published within ten minutes, a Tier 1 name capped at 0.25% of daily volume. Block trades have always settled away from that tape. Nobody had built the block. Confide is not a venue, so the exemption neither covers it nor is needed.
 
@@ -54,7 +54,7 @@ All 1,992 tokenized-equity mints from three issuers' catalogues run Token-2022 w
 
 The same 1,992 carry permanentDelegate, pausableConfig and a transfer hook — the issuer can freeze a transfer, seize a holder's tokens, run their own code. Token-2022's only disclosure model is mint-wide: one auditor key, reading every transfer while it is set, scoped to nobody. Everybody readable, or nobody. Why it is empty is unmeasured: empty is also the default.
 
-Then the half nobody counted: has anybody USED it? 518,744 live token accounts across Apple, NVIDIA, SpaceX and AMC. TWO have configured a confidential account — one on NVDAx, one on AAPLx. ZERO are approved — none until an issuer signs.
+Then the half nobody counted: has anybody USED it? 518,744 live token accounts across six mints. TWO have configured a confidential account — one on NVDAx, one on AAPLx. ZERO are approved — none until an issuer signs.
 
 Not only equities: PYUSD and USDG land on the same configuration.
 
diff --git a/docs/SEC-EXEMPTION.md b/docs/SEC-EXEMPTION.md
index 4a2699d..40865ab 100644
--- a/docs/SEC-EXEMPTION.md
+++ b/docs/SEC-EXEMPTION.md
@@ -166,8 +166,8 @@ individual burn instruction was not captured**: the last forty signatures on the
 transfers only. So the movement is inferred from differencing, which is the weaker of the two
 observations Codex names — the instruction itself would be direct.
 
-Token-2022 still offers exactly two disclosure settings — a global auditor key that reads everyone
-forever, or null — and all 1,992 are null. **The primitive for a third exists in this repository.
+Token-2022 still offers exactly two disclosure settings — a mint-wide auditor key that can decrypt
+every holder's confidential transfer amounts while it is set, or null — and all 1,992 are null. **The primitive for a third exists in this repository.
 The registrar application does not**, and saying otherwise would be the kind of claim
 `scripts/docs-consistency.sh` exists to prevent.
 
diff --git a/docs/cwf-2026/ISSUANCE-RUNS.md b/docs/cwf-2026/ISSUANCE-RUNS.md
index a176927..2d742e9 100644
--- a/docs/cwf-2026/ISSUANCE-RUNS.md
+++ b/docs/cwf-2026/ISSUANCE-RUNS.md
@@ -6,10 +6,11 @@ ask for.
 
 ## Why this exists when the swap already settles
 
-**On a real mint the swap cannot happen.** It needs two holders whose confidential accounts both
-already exist, and `autoApproveNewAccounts` is false on all 1,992 — an account cannot exist until
-the issuer signs for it, and across 469,477 live accounts **two have configured one and zero are
-approved.** The hole is not in the cryptography. It is in who is standing at the door.
+**On a real mint the swap waits on the issuer.** It needs two holders whose confidential accounts are
+both approved, and `autoApproveNewAccounts` is false on all 1,992 — a holder can configure an
+account, but cannot use it until the issuer approves it. On the six mints counted (2026-09-28),
+across 518,744 live accounts **two have configured one and zero are approved.** The hole is not in
+the cryptography. It is in who is standing at the door.
 
 **Issuance closes it, because the party who opens the door is one of the two parties.** The issuer
 allocates to an investor and also approves the investor's account. No matching — which is
diff --git a/docs/cwf-2026/REACH.md b/docs/cwf-2026/REACH.md
index cf36501..68cd465 100644
--- a/docs/cwf-2026/REACH.md
+++ b/docs/cwf-2026/REACH.md
@@ -49,7 +49,7 @@ party**.
 That is worth stating plainly rather than defaulting:
 
 > This project's entire argument is that disclosure should be scoped to a recipient and a purpose,
-> and that a global key which reads everyone's everything forever is the wrong shape. **Putting a
+> and that a mint-wide key which can decrypt every holder's transfer amounts is the wrong shape. **Putting a
 > third-party tracker on the page publishes every reader to a company none of them chose**, which
 > is a smaller version of the thing the page is about.
 
diff --git a/docs/cwf-2026/THE-PINCER.md b/docs/cwf-2026/THE-PINCER.md
index cf305d8..733dfb0 100644
--- a/docs/cwf-2026/THE-PINCER.md
+++ b/docs/cwf-2026/THE-PINCER.md
@@ -204,7 +204,8 @@ admissibility costs your holders the gate. Both halves are measured: the refusal
 pinned source, and 1,992 of 1,992 live mints sit on the `false` side.
 
 And the auditor slot offers no third option either. Token-2022 gives one disclosure model — a
-global key that decrypts everyone's everything forever — so *every* issuer's choice is between a
+mint-wide key that can decrypt every holder's confidential transfer amounts while it is set — so
+*every* issuer's choice is between a
 key no holder should accept and a null that lets no holder prove anything. **A new issuer chooses
 from the same two.**
 
diff --git a/scripts/docs-consistency.sh b/scripts/docs-consistency.sh
index 752e152..c2ec730 100755
--- a/scripts/docs-consistency.sh
+++ b/scripts/docs-consistency.sh
@@ -419,6 +419,18 @@ for f in files:
     for m in re.finditer(r"(\d+) (?:of them )?configured for confidential", t):
         if int(m.group(1)) != conf:
             bad.append(f"{f}: says {m.group(1)} configured, web/usage.json says {conf}")
+    # "THREE HAVE ASKED" -- the site's hero panel and README's table said three for days after a
+    # scan found two (one account was closed), because this check only knew "N configured for
+    # confidential". Word or digit, with or without a table cell between (2026-10-01).
+    WORDS = {"one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6, "seven": 7, "eight": 8,
+             "nine": 9, "ten": 10}
+    # STATUS.md is a dated log and quotes the old wording when it records the fix; it is exempt here.
+    for m in re.finditer(r"(?i)(?:\*\*)?\b(\d+|one|two|three|four|five|six|seven|eight|nine|ten)\b(?:\*\*)?"
+                         r"\s*(?:\|\s*)?have (?:asked|configured|tried)\b", t if f != "STATUS.md" else ""):
+        k = m.group(1).lower()
+        v = int(k) if k.isdigit() else WORDS[k]
+        if v != conf:
+            bad.append(f"{f}: says {m.group(0).strip()!r}, web/usage.json says {conf} configured")
     # CONFIGURED IS NO LONGER THE HEADLINE. On 2026-09-22 two NVDAx accounts configured one and
     # neither was approved, so "zero" moved from the first number to the second. Both are checked.
     for m in re.finditer(r"(\d+) approved by an issuer", t):
@@ -1280,6 +1292,52 @@ python3 video/demo-times.py --check >/dev/null 2>&1 \
   && ok "every scene's time range in video/DEMO.md matches demo-ops.manifest.json" \
   || bad "video/DEMO.md scene times differ from the cut — python3 video/demo-times.py"
 
+echo
+echo "  THE AUDITOR'S REACH — what the mint-wide key can read, said as it is"
+python3 - <<'PYAR' && ok "no live surface says the auditor key reads everything, forever" || bad "a surface overstates the auditor key — it decrypts transfer amounts made while set"
+import hashlib, re, subprocess, sys, pathlib
+# The key can decrypt the amount of every confidential transfer made while it is set, for every
+# holder. It does not see a whole balance, and it does not read transfers made before it was set.
+# "Decrypts everyone's everything, forever" was on the demo page, DESIGN, SEC-EXEMPTION, REACH and
+# THE-PINCER until 2026-10-01 -- the founder's brief (s1) had already drawn the line.
+BAN = re.compile(r"everything,? (?:for everyone|forever|for all time)|everyone.{0,2}s everything|decrypts everything"
+                 r"|reads everyone|everybody or nobody|all balances, or none|permanently readable", re.I)
+# Published narration and captions keep what was recorded; pinned by content like THE MOTIVE's list.
+frozen = {
+    "video/CWF-PRESENTATION.md":             "3629f0a2190a69a7",
+    "video/captions-20260923.srt":           "b5a4a3c6ea0d626d",
+    "video/segments-presentation/LINES.md":  "8417644637e94849",
+    "video/segments-presentation/manifest.json": "76afa0a5da4f6138",
+    "video/voiceover.md":                    "687f4e4e55aa7604",
+    "video/captions.srt":                    "fbe229c6d5a88c5f",
+}
+skip = re.compile(r"^docs/reviews/|^STATUS\.md$|^scripts/docs-consistency\.sh$")
+bad = []
+for f in filter(None, subprocess.run(["git", "ls-files", "-z", "--cached", "--others", "--exclude-standard"],
+                                     capture_output=True, text=True).stdout.split("\0")):
+    p = pathlib.Path(f)
+    if skip.match(f) or not p.exists() or p.suffix in (".png", ".jpg", ".jpeg", ".mp4", ".ico", ".pdf"):
+        continue
+    if f in frozen:
+        if hashlib.sha256(p.read_bytes()).hexdigest()[:16] != frozen[f]:
+            bad.append(f"{f} is pinned as recorded and has changed -- re-read it, then re-pin")
+        continue
+    try:
+        t = p.read_text(encoding="utf-8")
+    except (UnicodeDecodeError, OSError):
+        continue
+    # captions and wrapped prose split a phrase across lines, so read with line breaks folded
+    flat = re.sub(r"\s*\n\s*(?:>\s*)?", " ", t)
+    for m in BAN.finditer(flat):
+        bad.append(f"{f}: ...{flat[max(0, m.start() - 40):m.end() + 20]}...")
+for f in frozen:
+    if not pathlib.Path(f).exists():
+        bad.append(f"{f} is gone")
+for b in bad[:10]:
+    print("      " + b)
+sys.exit(1 if bad else 0)
+PYAR
+
 echo
 echo "  THE PRIVATE ENDPOINT — it may exist as an environment variable and nowhere else"
 # web/slots.json recorded the founder's Alchemy URL on this script's first run, key and all, into a
diff --git a/scripts/issue-e2e.sh b/scripts/issue-e2e.sh
index 365fa8d..aa18e2f 100755
--- a/scripts/issue-e2e.sh
+++ b/scripts/issue-e2e.sh
@@ -9,8 +9,9 @@
 # part of that allocation to a second approved holder through the four-step bilateral protocol.
 #
 # The swap this repository already settles needs two holders whose confidential accounts BOTH
-# already exist. On every one of the 1,992 real mints that is impossible: `autoApproveNewAccounts`
-# is false, so an account cannot exist until the issuer signs for it, and none has. The demonstration
+# already exist and be approved. On the 1,992 real mints that is the issuer's call:
+# `autoApproveNewAccounts` is false, so a confidential account is unusable until the issuer approves
+# it, and on the six mints whose accounts were counted none has been (usage-scan.sh). The demonstration
 # that settles a block trade therefore cannot happen on a real mint — the hole is not in the
 # cryptography, it is in who is standing at the door.
 #
diff --git a/scripts/testbed-join.sh b/scripts/testbed-join.sh
index b9e15db..aa5e923 100755
--- a/scripts/testbed-join.sh
+++ b/scripts/testbed-join.sh
@@ -3,9 +3,9 @@
 #
 #   ./scripts/testbed-join.sh [your-keypair.json]
 #
-# This is the thing 518,744 live token accounts have never done — `./scripts/usage-scan.sh`. On
-# mainnet it cannot be done, because a confidential account needs the issuer's signature and no
-# issuer has given one. Here the issuer has published the key that gives it, so the gate is shut
+# This is the thing 518,744 live token accounts have never done — `./scripts/usage-scan.sh`, six
+# mints counted. On those mints it has not been done: a confidential account is usable only once the
+# issuer approves it, and none of those accounts has been approved. Here the issuer has published the key that gives it, so the gate is shut
 # exactly as it is on all 1,992 real mints and **you can operate it yourself**.
 #
 # What you end up with: a token account whose public balance reads 0 and which holds a real
diff --git a/video/demo.html b/video/demo.html
index ebf9d45..514bfc4 100644
--- a/video/demo.html
+++ b/video/demo.html
@@ -352,7 +352,7 @@ async function slot(s){
    +'<div class="cards">'+cards+'</div>'
    +'<div class="lede fade" style="margin-top:30px;font-size:22px">'
    +'<b>All '+(s.mints||'1,869')+' of them.</b> The privacy is already shipped and nobody can use it &mdash; '
-   +'the only key on offer reads <span class="hl">everyone\'s everything, forever</span>.</div>'
+   +'the only key on offer is mint-wide: it decrypts <span class="hl">every holder\'s transfer amounts</span>.</div>'
    +'<div class="cap fade" style="margin:14px 0 0">'
    +((s.issuers||2)>2?'Three':'Two')+' issuers, one configuration &mdash; which is also the default.</div></div>');
   await sleep(80); await reveal(els,180); await out(rest(s,t0));
@@ -540,7 +540,7 @@ async function privacyGap(s){
     +'<h2 class="fade">'+s.mints+' tokenized-stock mints have confidential transfers. The privacy setting does not.</h2>'
     +'<div class="gap-stage"><div class="capability fade"><div class="tiny">issuer controls, on every one</div>'
     +'<div class="exts">'+s.controls.map(c=>'<div class="ext"><code>'+c.ext+'</code><span>'+c.n+'</span></div>').join("")+'</div></div>'
-    +'<div class="missing-key fade"><div class="keyhole">⌁</div><b>NO SELECTIVE AUDIT KEY</b><span>all balances, or none</span></div>'
+    +'<div class="missing-key fade"><div class="keyhole">⌁</div><b>NO SELECTIVE AUDIT KEY</b><span>every transfer, or none</span></div>'
     +'<div class="capability fade"><div class="tiny">holder choice</div><strong>Show a lender enough<br>Show an auditor enough<br>Keep the market blind</strong></div></div>'
     +'<div class="source fade">Token-2022 confidential transfers · the same empty auditor slot across '
     +s.issuers+' issuers</div></div>');
diff --git a/web/index.html b/web/index.html
index 2d91202..1f9d900 100644
--- a/web/index.html
+++ b/web/index.html
@@ -161,11 +161,12 @@ b.bad{color:var(--red)}b.good{color:var(--grn)}
       <div class="panel"><div class="big" id="heroAccounts">518,744</div><div class="cap2">live token
       accounts across Apple, NVIDIA, SpaceX, Anthropic and AMC</div></div>
       <div class="panel"><div class="big z">0</div><div class="cap2">have been approved.
-      <b>Three have asked; no issuer has signed.</b></div></div>
+      <b>Two have asked; no issuer has approved one.</b></div></div>
     </div>
-    <div class="note">Read from mainnet and counted by <span class="mono">scripts/usage-scan.sh</span>.
-    The feature is shipped on every mint and gated on every mint, and no issuer has signed for an
-    account yet &mdash; so there is no incumbent here and nothing to be late to.</div>
+    <div class="note">Read from mainnet and counted by <span class="mono">scripts/usage-scan.sh</span>,
+    on six mints, two per issuer. The feature is shipped and gated on every mint in the list; on the six
+    counted, no issuer has approved an account yet &mdash; so where we looked there is no incumbent and
+    nothing to be late to.</div>
   </section>
 
   <section>
@@ -259,7 +260,7 @@ b.bad{color:var(--red)}b.good{color:var(--grn)}
     not by this page — a scan of a third of a million accounts is not something to run in a
     browser tab. Size is only the cheap filter: the first pass found seven large accounts on Apple
     xStock and <b>every one was large for an unrelated extension</b>, so the check reads the
-    extension list. <b>There is no incumbent here and nothing to be late to.</b></div>
+    extension list. <b>On the mints counted, there is no incumbent and nothing to be late to.</b></div>
   </section>
 
   <!-- THE TURN, and the page did not have it. Nine sections described a gate that is shut and then
```
