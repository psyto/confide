# Review request — the demo narration and the ops view's claims, 2026-09-30

The CWF demo video will be `video/demo-ops.mp4` with the narration in `video/DEMO.md`. The screen
is `app/static/ops.{html,js}`; it attributes each stage to CONFIDE / TOKEN-2022 / SOLANA and lists
"Confide in this run". Binding context: `docs/cwf-2026/CLAUDE-CODE-BRIEF.md` §1 boundaries, `STORY.md`.

Please be adversarial about **public claims**, which will be heard by judges:
1. Any sentence in DEMO.md's narration (the `>` blocks) that overclaims or is false against the code
   and STATUS.md 09-30 (12)–(15)? E.g. "configured like every tokenized stock we measured", "Only the
   issuer's key opens this gate", "Solana rejects it", "Confide pins those terms on each side before any
   proof exists", "its key cannot read the amounts", "Confide decrypts the investor's leg".
2. Is the CONFIDE / TOKEN-2022 / SOLANA attribution in ops.js (the BY map and each blot() call) right?
   Is anything credited to Confide that the chain does, or the reverse (underclaim)?
3. The "Confide in this run" ticks: is each written only after the checkpoint that justifies it?
4. Anything the brief's §1 boundaries require that the video/narration omits or contradicts?
5. The fast-forward edit: is the badge + manifest disclosure sufficient, or should the video also say
   it in narration/title?

## video/DEMO.md
# The demo video — ≤3 minutes, the live product

**The form asks for the live product, not a slide deck.** The picture is
[`demo-ops.mp4`](demo-ops.mp4): the settlement-operations view (`/ops`) of the local demo app driving
`scripts/issue-e2e.sh` on **devnet**, recorded in Chromium by [`record-app.js`](record-app.js). Every
refusal, check and settlement on screen is a checkpoint the script wrote after its own check. The
story it follows is [`docs/cwf-2026/STORY.md`](../docs/cwf-2026/STORY.md) §4.

**One edit, and it is on screen.** [`cut-app.js`](cut-app.js) plays the middle of each devnet wait
faster and shows a badge with the real duration while it does; nothing is removed or reordered.
Every shortened stretch is in [`demo-ops.manifest.json`](demo-ops.manifest.json).

**The narration draws the same line the screen does.** Token-2022 and Solana enforce the rules —
the refusals are theirs, and the narration says so. Confide does the work around them: it builds the
proofs, checks the amount before signing, pins the terms, verifies the transaction, and assembles
both legs into one. Nothing of Confide's runs inside the trade.

This replaces the 2026-09-30 script for the terminal demo, which followed `issue-e2e.sh`'s output and
had no act 2. The timestamps under each scene are where that scene sits in `demo-ops.mp4` as cut on
2026-09-30; if the video is re-recorded they move, and so must these.

## Length

Derived by `python3 video/pace.py` from the words below. **Do not edit this table by hand** — it is
rewritten with `--write`, and it drifted from the words within minutes of both being written the one
time it was maintained any other way.

**The voice has to fit under the picture: 175.7 seconds.** The figure below is a prediction at 137
words a minute, and check-in 2 came out about four per cent long (`STATUS.md`, 0i), so the script is
held about 4% under the video rather than at it.

| | scene | seconds (+ silence) | words | pace | what it shows |
|---|---|---|---|---|---|
| 1 | a stock shut the way the real ones are | 21 | 47 | 138 | 0:00–0:23 — both mints appear under MINT POLICY with `APPROVAL REQUIRED · auditor: none`; the investor's cash account is approved and funded, then its stock account lands in the approval queue as `PENDING`. The blotter's `done by` column reads `TOKEN-2022` for all of it |
| 2 | Confide builds the proofs and checks the amount | 12 | 26 | 137 | 0:23–0:36 — the Act 1 ticket appears (20,000 shares ⇄ $3,500,000), `PROOFS BUILT · CHAIN-VERIFIED` and `PRE-SIGN CHECK` turn green with `CONFIDE` beside them, and the first two lines of CONFIDE IN THIS RUN tick |
| 3 | the gate holds | 15 | 33 | 138 | 0:36–0:51 — `SENT BEFORE APPROVAL · TOKEN-2022` turns red; the blotter shows `REFUSED · Custom(24)` with its signature, then `REFUSED · not the authority`; the queue marks the account `SELF-APPROVAL REFUSED` |
| 4 | approval, then one transaction | 20 | 44 | 136 | 0:51–1:13 — `ISSUER APPROVES` green, `ONE SIGNATURE ONLY · SOLANA` red, then `BOTH SIGNATURES · SETTLED · CONFIDE + TOKEN-2022` with the settlement signature and its compute units |
| 5 | what anyone can see | 8 | 16 | 130 | 1:13–1:21 — the public ledger, every account `0` and `ENCRYPTED`; beside it, each holder's position read with its own key, labelled as shown together only because one presenter holds every key |
| 6 | two approved holders trade | 31 | 70 | 138 | 1:21–1:53 — the Act 2 ticket (5,000 ⇄ $875,000): `TERMS PINNED` on both sides, `INVESTOR CHECK`, `HOLDER 2 CHECK + BINDING`, then `BOTH SIGNATURES · SETTLED`, every stage marked `CONFIDE` |
| 7 | the short-delivery control | 26 + 12 | 58 | 137 | 1:53–2:34 — a fresh run's setup, fast-forwarded with its badge (the silence sits here, before "Before any signature exists"), then `PRE-SIGN CHECK · CONFIDE` turns red and the ticket reads `investor decrypted 2,000 shares · agreed 20,000 → REFUSED, nothing signed` |
| 8 | what Confide did | 20 | 45 | 139 | 2:34–2:56 — the final frame held: CONFIDE IN THIS RUN with its ticks, the red pre-sign check, the blotter reading `SHORT · REFUSED — CONFIDE` |
| | | **165 s** | **339** | | |

## The script

### 1 — a stock shut the way the real ones are

> This is Confide, running on devnet. The issuer creates a tokenized stock and a cash token,
> configured like every tokenized stock we measured: confidential transfers on, new accounts need
> the issuer's approval, no auditor key. An investor opens a confidential account. It sits in the
> queue, pending.

*Shows:* 0:00–0:23 — both mints appear under MINT POLICY with `APPROVAL REQUIRED · auditor: none`;
the investor's cash account is approved and funded, then its stock account lands in the approval
queue as `PENDING`. The blotter's `done by` column reads `TOKEN-2022` for all of it.

### 2 — Confide builds the proofs and checks the amount

> Confide builds both legs' zero-knowledge proofs, and the chain verifies them. Before signing, the
> investor's side decrypts its own amount and compares it with the deal.

*Shows:* 0:23–0:36 — the Act 1 ticket appears (20,000 shares ⇄ $3,500,000), `PROOFS BUILT ·
CHAIN-VERIFIED` and `PRE-SIGN CHECK` turn green with `CONFIDE` beside them, and the first two lines
of CONFIDE IN THIS RUN tick.

### 3 — the gate holds

> The issuer sends the allocation. Token-2022 refuses it: the account isn't approved. The investor
> tries approving itself — refused. Only the issuer's key opens this gate. Confide works through it,
> not around it.

*Shows:* 0:36–0:51 — `SENT BEFORE APPROVAL · TOKEN-2022` turns red; the blotter shows `REFUSED ·
Custom(24)` with its signature, then `REFUSED · not the authority`; the queue marks the account
`SELF-APPROVAL REFUSED`.

### 4 — approval, then one transaction

> The issuer approves exactly this account. Sent with only the issuer's signature, Solana rejects it.
> With the investor's signature added to that same transaction, it settles: twenty thousand shares
> against three and a half million dollars, both legs in one transaction, assembled by Confide.

*Shows:* 0:51–1:13 — `ISSUER APPROVES` green, `ONE SIGNATURE ONLY · SOLANA` red, then `BOTH
SIGNATURES · SETTLED · CONFIDE + TOKEN-2022` with the settlement signature and its compute units.

### 5 — what anyone can see

> From outside: every account, every transaction, and a public balance of zero. The amounts are
> encrypted.

*Shows:* 1:13–1:21 — the public ledger, every account `0` and `ENCRYPTED`; beside it, each holder's
position read with its own key, labelled as shown together only because one presenter holds every
key.

### 6 — two approved holders trade

> The issuer approves a second holder. The investor offers five thousand shares for eight hundred and
> seventy-five thousand dollars. Confide pins those terms on each side before any proof exists. Each
> side checks what it will receive against its own pin, and the second signer confirms the
> transaction is exactly the one it checked. It settles in one transaction. The issuer approved the
> accounts; its key cannot read the amounts.

*Shows:* 1:21–1:53 — the Act 2 ticket (5,000 ⇄ $875,000): `TERMS PINNED` on both sides, `INVESTOR
CHECK`, `HOLDER 2 CHECK + BINDING`, then `BOTH SIGNATURES · SETTLED`, every stage marked `CONFIDE`.

### 7 — the short-delivery control · + 12 s silence

> Now the control. The same allocation, except the issuer builds its leg for two thousand shares
> instead of twenty thousand. The proofs are valid; only the amount is wrong, and the amount is
> encrypted. Before any signature exists, Confide decrypts the investor's leg, finds two thousand
> where twenty thousand was agreed, and refuses. Nothing is signed. Nothing moves.

*Shows:* 1:53–2:34 — a fresh run's setup, fast-forwarded with its badge (the silence sits here, before
"Before any signature exists"), then `PRE-SIGN CHECK · CONFIDE` turns red and the ticket reads
`investor decrypted 2,000 shares · agreed 20,000 → REFUSED, nothing signed`.

### 8 — what Confide did

> Token-2022 and Solana enforce the rules. Confide does the work around them: it builds the proofs,
> checks before signing, pins the terms, and assembles delivery and payment into one transaction.
> This is devnet, and no real issuer has used it yet. That conversation is next.

*Shows:* 2:34–2:56 — the final frame held: CONFIDE IN THIS RUN with its ticks, the red pre-sign check,
the blotter reading `SHORT · REFUSED — CONFIDE`.

## What this video does not claim

Named here so the narration does not have to carry it, and so a reviewer can see the boundary was
drawn on purpose:

- **Devnet, and a local demo.** Every key is held by the machine running it; the panes are one
  presenter's view, not separate wallets. No mainnet deployment exists, deliberately —
  [`docs/27-DAYS.md`](../docs/27-DAYS.md) refuses it under *Refused*, with the reason.
- **No real issuer has approved anything.** The issuer here is a keypair this repository holds.
  Nobody has been through that door on the mints whose accounts were counted, and nobody has asked
  an issuer.
- **The refusals are Token-2022's and Solana's**, not Confide's, and the screen labels them so.
- **Confidential balances hide amounts, not identities.** Accounts, the mint and the fact of a
  transfer are public — scene 5 shows exactly that.
- **"No auditor key" is not selective disclosure.** It means no mint-wide transfer auditor is set.
  Token-2022 offers one global key or none.
- **The price is agreed off chain.** $175.00 a share is cash over shares, labelled so on screen; no
  market data exists in the demo.
- **Fast-forwarded stretches are devnet waiting**, badged with their real length, and listed in the
  manifest.

## app/static/ops.js
```js
// Confide — settlement operations view. Renders checkpoints; decides nothing (docs/cwf-2026/DEMO-APP.md).
// Same event stream and same rules as app.js: every value arrives from the server's sanitised stream
// and is inserted as text. No price, instrument or market data exists here that the run did not produce.
"use strict";

const REPLAY = !!window.CONFIDE_REPLAY;               // the mock harness feeds saved events; never set live
const CSRF = (document.querySelector('meta[name="confide-csrf"]') || {}).content || "";
const EXPLORER = (kind, id) => `https://explorer.solana.com/${kind}/${id}?cluster=devnet`;

// The script's step names -> who acts, and the words on the button.
const STEPS = {
  parties: ["issuer", "Set up the issuer and an investor"],
  mints: ["issuer", "Create the stock — gate shut, auditor empty"],
  holdings: ["issuer", "Fund the treasury and the investor's cash"],
  investor_opens: ["investor", "Open a confidential account for the stock"],
  proofs: ["issuer", "Build both legs' proofs"],
  check: ["investor", "Check the allocation before signing"],
  send_allocation: ["issuer", "Send the allocation (account not approved yet)"],
  self_approve: ["investor", "Try to approve my own account"],
  issuer_approves: ["issuer", "Approve exactly this account"],
  issuer_signs_alone: ["issuer", "Send with the issuer's signature only"],
  investor_signs: ["investor", "Add my signature — settle"],
  observe: ["observer", "Look from outside"],
  act2_accounts: ["issuer", "Act 2 — approve a second holder"],
  offer: ["investor", "Offer 5,000 shares for $875,000"],
  accept: ["buyer", "Read the offer, pin it, build the cash leg"],
  settle: ["investor", "Check the cash against my pin, sign once"],
  sign: ["buyer", "Check the shares against my pin, add the second signature"],
  observe2: ["observer", "Look from outside"],
};
const HOLDER = { issuer: "ISSUER", investor: "INVESTOR", buyer: "HOLDER 2", offerer: "INVESTOR", acceptor: "HOLDER 2" };
const ASSET = { X: "STOCK", Y: "CASH" };

// ---- tiny DOM helpers (text only) ----
const el = (tag, cls, text) => { const e = document.createElement(tag); if (cls) e.className = cls; if (text !== undefined) e.textContent = text; return e; };
const short = (s) => (s && s.length > 16 ? s.slice(0, 6) + "…" + s.slice(-4) : s || "");
const link = (kind, id) => { const a = el("a", null, short(id)); a.href = EXPLORER(kind, id); a.target = "_blank"; a.rel = "noreferrer noopener"; return a; };
const tag = (cls, text) => el("span", "tag " + cls, text);
const n = (x) => Number(x).toLocaleString("en-US");
const baseToUnits = (b, d) => (b && /^\d+$/.test(b) ? n(Number(BigInt(b) / 10n ** BigInt(d || 0))) : "—");
const row = (cells) => { const tr = el("tr"); for (const c of cells) { const td = el("td", c && c.cls); if (c && c.node) td.appendChild(c.node); else td.textContent = c && c.text !== undefined ? c.text : (c ?? ""); tr.appendChild(td); } return tr; };

// ---- state ----
let S;
function reset() {
  document.getElementById("did").textContent = "";
  S = { did: new Set(), parties: {}, mints: {}, accounts: {}, order: [], positions: {}, seq: 0, act: 1, short: false,
        t1: { stages: {}, lines: [], shares: null, cash: null, built: null, sig: null, cu: null },
        t2: { stages: {}, lines: [], shares: null, cash: null, sig: null } };
  for (const id of ["queue", "mints", "public", "positions", "blotter"]) document.querySelector(`#${id} tbody`).textContent = "";
  for (const id of ["ticket-1", "ticket-2"]) { const t = document.getElementById(id); t.textContent = ""; t.className = "ticket idle"; }
  document.getElementById("placeholder").style.display = "";
  next(null);
}

// ---- panels ----
function renderQueue() {
  const tb = document.querySelector("#queue tbody"); tb.textContent = "";
  for (const a of S.order) {
    const x = S.accounts[a]; if (x.who === "issuer") continue;
    const st = x.approved === "yes" ? tag("ok", "APPROVED") : x.refused ? tag("bad", "SELF-APPROVAL REFUSED") : tag("warn", "PENDING");
    tb.appendChild(row([{ text: HOLDER[x.who] }, { text: ASSET[x.asset] }, { node: link("address", a) }, { node: st }]));
  }
}
function renderMints() {
  const tb = document.querySelector("#mints tbody"); tb.textContent = "";
  for (const k of ["X", "Y"]) {
    const m = S.mints[k]; if (!m) continue;
    const pol = el("span"); pol.appendChild(tag("warn", "APPROVAL REQUIRED")); pol.appendChild(el("span", "dim", "  auditor: " + (m.auditor === "empty" ? "none" : m.auditor)));
    tb.appendChild(row([{ text: ASSET[k] }, { node: link("address", m.mint) }, { node: pol }]));
  }
}
function renderLedger() {
  const tb = document.querySelector("#public tbody"); tb.textContent = "";
  for (const a of S.order) {
    const x = S.accounts[a];
    tb.appendChild(row([
      { node: link("address", a) },
      { text: x.pub ?? "—", cls: "num" + (x.pub === "0" ? " ok" : "") },
      { node: tag("dim", "ENCRYPTED") },
      { node: x.approved === "yes" ? tag("ok", "YES") : tag("warn", "NO") },
    ]));
  }
}
function renderPositions() {
  const tb = document.querySelector("#positions tbody"); tb.textContent = "";
  for (const [k, p] of Object.entries(S.positions)) tb.appendChild(row([{ text: p.holder }, { text: p.asset }, { text: p.units, cls: "num" }]));
}
function blot(evt, result, cls, evidence, party, who) {
  S.seq += 1;
  const tb = document.querySelector("#blotter tbody");
  for (const r of tb.querySelectorAll("tr.fresh")) r.classList.remove("fresh");
  const b = el("span", "by " + (who || "").split(" ")[0].toLowerCase().replace(/[^a-z0-9]/g, ""), who || "");
  const tr = row([{ text: String(S.seq), cls: "num" }, { text: String(S.act) }, { text: party || "" }, { text: evt },
                  { node: tag(cls, result) }, { node: b }, evidence ? { node: evidence } : { text: "" }]);
  tr.classList.add("fresh");
  tb.prepend(tr);
  while (tb.children.length > 8) tb.lastChild.remove();
}

// ---- what Confide did, listed as it happens (only from checkpoints; nothing is pre-filled) ----
function did(key, text) {
  if (S.did.has(key)) return;
  S.did.add(key);
  const li = el("li", null, text);
  li.prepend(el("span", "tick", "✓ "));
  document.getElementById("did").appendChild(li);
}

// ---- tickets ----
// Stage names say what happened at that stage, so the row reads as the story: refused, then approved.
const T1 = [["proofs", "PROOFS BUILT · CHAIN-VERIFIED"], ["check", "PRE-SIGN CHECK"], ["gate", "SENT BEFORE APPROVAL"], ["approve", "ISSUER APPROVES"],
            ["sig1", "ONE SIGNATURE ONLY"], ["settle", "BOTH SIGNATURES · SETTLED"]];
const T2 = [["pin1", "TERMS PINNED · INVESTOR"], ["pin2", "TERMS PINNED · HOLDER 2"], ["chk1", "INVESTOR CHECK"],
            ["chk2", "HOLDER 2 CHECK + BINDING"], ["settle", "BOTH SIGNATURES · SETTLED"]];
// WHO DID IT. Nothing of Confide's runs inside the trade -- the transfers are Token-2022's, the
// atomicity is Solana's. Confide builds the proofs, checks before signing, pins terms, binds the
// transaction and assembles it. The refusals are Token-2022's and Solana's, and are labelled so.
const BY = {
  proofs: "CONFIDE", check: "CONFIDE", gate: "TOKEN-2022", approve: "TOKEN-2022", sig1: "SOLANA", settle: "CONFIDE + TOKEN-2022",
  pin1: "CONFIDE", pin2: "CONFIDE", chk1: "CONFIDE", chk2: "CONFIDE",
};
const by = (k) => { const s = el("span", "by " + (BY[k] || "").split(" ")[0].toLowerCase().replace(/[^a-z0-9]/g, ""), BY[k] || ""); return s; };
function renderTicket(n_, t, spec, title, sellerWho, buyerWho) {
  document.getElementById("placeholder").style.display = "none";
  const box = document.getElementById("ticket-" + n_);
  box.className = "ticket"; box.textContent = "";
  const hd = el("div", "hd"); hd.appendChild(el("span", null, title)); hd.appendChild(el("span", null, t.sig ? "SETTLED" : "OPEN")); box.appendChild(hd);
  const legs = el("div", "legs");
  const a = el("div", "leg"); a.appendChild(el("div", "who", sellerWho + " delivers")); a.appendChild(el("div", "amt", t.shares ? n(t.shares) : "—")); a.appendChild(el("div", "asset", "STOCK · confidential"));
  const b = el("div", "leg"); b.appendChild(el("div", "who", buyerWho + " pays")); b.appendChild(el("div", "amt", t.cash ? "$" + n(t.cash) : "—")); b.appendChild(el("div", "asset", "CASH · confidential"));
  const mid = el("div"); mid.appendChild(el("div", "swap", "⇄"));
  if (t.shares && t.cash) mid.appendChild(el("div", "px", "$" + (t.cash / t.shares).toFixed(2) + "/sh\nagreed off chain"));
  legs.appendChild(a); legs.appendChild(mid); legs.appendChild(b); box.appendChild(legs);
  const st = el("div", "stages");
  for (const [k, label] of spec) { const s = el("span", "stage " + (t.stages[k] || ""), label); s.appendChild(by(k)); st.appendChild(s); }
  box.appendChild(st);
  if (t.lines.length) box.appendChild(el("div", "detail", t.lines.slice(-2).join("\n")));
  if (t.sig) { const d = el("div", "detail"); d.appendChild(el("span", null, "settlement ")); d.appendChild(link("tx", t.sig)); if (t.cu) d.appendChild(el("span", null, ` · ${n(t.cu)} CU · both legs in one transaction`)); box.appendChild(d); }
}
const t1 = () => renderTicket(1, S.t1, T1, S.short ? "ACT 1 · ALLOCATION · SHORT-DELIVERY CONTROL" : "ACT 1 · PRIMARY ALLOCATION", "ISSUER", "INVESTOR");
const t2 = () => renderTicket(2, S.t2, T2, "ACT 2 · BILATERAL TRADE BETWEEN APPROVED HOLDERS", "INVESTOR", "HOLDER 2");

// ---- next action, in the pane of whoever acts ----
function next(step) {
  for (const id of ["issuer", "investor", "buyer", "observer"]) document.getElementById("next-" + id).textContent = "";
  if (!step || !STEPS[step]) return;
  const [who, label] = STEPS[step];
  const b = el("button", "next", "NEXT ▸ " + label);
  b.type = "button";
  b.addEventListener("click", async () => {
    b.disabled = true;
    const r = await post("/advance", { step });
    if (!r.ok) { b.disabled = false; status("the script was not waiting for that step"); return; }
    status("working on devnet: " + label);
  });
  document.getElementById("next-" + who).appendChild(b);
}
const status = (t) => { document.getElementById("status").textContent = t.toUpperCase(); };
async function post(path, body) {
  return fetch(path, { method: "POST", headers: { "Content-Type": "application/json", "X-Confide-CSRF": CSRF }, body: JSON.stringify(body) });
}
async function readPublic(a) {
  if (REPLAY) return;
  try { const r = await fetch("/chain/account/" + a); if (r.ok) { const j = await r.json(); if (j.exists) { S.accounts[a].pub = j.public_balance; renderLedger(); } } } catch (_) {}
}

// ---- one handler per checkpoint ----
const H = {
  run(e) { S.short = e.mode === "short"; status(S.short ? "running · short-delivery control" : "running"); },
  waiting(e) { next(e.next); status("waiting for: " + (STEPS[e.next] ? STEPS[e.next][1] : e.next)); },
  party(e) { S.parties[e.who] = e.pubkey; },
  mint(e) { S.mints[e.asset] = e; renderMints(); blot(ASSET[e.asset] + " mint created", "GATE SHUT", "warn", link("address", e.mint), "ISSUER", "TOKEN-2022"); },
  account(e) {
    if (!S.accounts[e.account]) S.order.push(e.account);
    S.accounts[e.account] = { ...(S.accounts[e.account] || {}), who: e.who, asset: e.asset, approved: e.approved };
    renderQueue(); renderLedger(); readPublic(e.account);
    blot(`${ASSET[e.asset].toLowerCase()} account configured`, e.approved === "yes" ? "APPROVED" : "NOT APPROVED",
         e.approved === "yes" ? "ok" : "warn", link("address", e.account), HOLDER[e.who], "TOKEN-2022");
  },
  proofs(e) {
    S.t1.stages.proofs = "ok"; if (e.shares) S.t1.shares = e.shares; if (e.cash) S.t1.cash = e.cash;
    S.t1.lines.push("proofs built and verified by the chain's ZK program, before anyone knows if it will be allowed"); t1();
    blot("both legs' proofs built", "VERIFIED ON CHAIN", "ok", null, "ISSUER · INVESTOR", "CONFIDE");
    did("proofs", "built both legs' ZK proofs — verified by the chain");
  },
  checked(e) {
    if (e.act === "2") {
      const k = e.who === "offerer" ? "chk1" : "chk2";
      S.t2.stages[k] = e.against === "pin" ? "ok" : "bad";
      S.t2.lines.push(`${HOLDER[e.who]}: compared with the terms pinned on its own side${e.bound === "yes" ? "; transaction is exactly the one checked" : ""}`);
      t2(); blot("pre-signing check", e.against === "pin" ? "MATCHES PIN" : "NOT PINNED", e.against === "pin" ? "ok" : "warn", null, HOLDER[e.who], "CONFIDE");
      did("chk2-" + e.who, `${HOLDER[e.who].toLowerCase()} checked what it receives against its pin`);
      if (e.bound === "yes") did("bound", "verified the transaction is exactly the one checked");
      return;
    }
    S.t1.shares = S.t1.shares || e.agreed; S.t1.stages.check = "ok";
    S.t1.lines.push(`investor decrypted ${baseToUnits(e.decrypted_base, e.decimals)} shares from the verified proof · agreed ${n(e.agreed)}`);
    t1(); blot("pre-signing check", "MATCHES AGREED", "ok", null, "INVESTOR", "CONFIDE");
    did("check", "decrypted the incoming amount and compared it with the deal, before signing");
  },
  refused(e) {
    const ev = e.sig ? link("tx", e.sig) : null;
    if (e.source === "pre_sign_check") {
      S.t1.shares = S.t1.shares || e.agreed; S.t1.stages.check = "bad";
      S.t1.lines.push(`investor decrypted ${baseToUnits(e.decrypted_base, e.decimals)} shares · agreed ${n(e.agreed)} → REFUSED, nothing signed`);
      t1(); blot("pre-signing check", "SHORT · REFUSED", "bad", null, "INVESTOR", "CONFIDE");
      did("short", "caught a short delivery before any signature existed"); return;
    }
    if (e.what === "allocation") { S.t1.stages.gate = "bad"; S.t1.lines.push("sent to an unapproved account → refused on chain, Custom(24)"); t1(); blot("allocation sent", "REFUSED · Custom(24)", "bad", ev, "ISSUER", "TOKEN-2022"); return; }
    if (e.what === "self_approval") {
      for (const a of S.order) if (S.accounts[a].who === "investor" && S.accounts[a].asset === "X") S.accounts[a].refused = true;
      renderQueue(); blot("investor approves own account", "REFUSED · not the authority", "bad", ev, "INVESTOR", "TOKEN-2022"); return;
    }
    if (e.what === "half_signed") { S.t1.stages.sig1 = "bad"; S.t1.lines.push("issuer's signature only → refused in RPC preflight; never entered a block"); t1(); blot("sent with 1 of 2 signatures", "REFUSED · preflight", "bad", null, "ISSUER", "SOLANA"); }
  },
  approval(e) {
    const x = S.accounts[e.account]; if (x) x.approved = e.approved === "true" ? "yes" : "no";
    renderQueue(); renderLedger();
    if (e.approved === "true") { S.t1.stages.approve = "ok"; S.t1.lines.push("issuer approved exactly this account"); t1(); blot("issuer approves account", "APPROVED", "ok", e.sig ? link("tx", e.sig) : null, "ISSUER", "TOKEN-2022"); }
  },
  settled(e) {
    if (e.act === "2") { S.t2.stages.settle = "ok"; S.t2.sig = e.sig; t2(); blot("bilateral trade", "SETTLED · 2/2", "ok", link("tx", e.sig), "INVESTOR · HOLDER 2", "CONFIDE + TOKEN-2022");
      did("dvp2", "assembled the holders' trade as one transaction"); return; }
    Object.assign(S.t1, { sig: e.sig, cu: e.cu, shares: e.shares || S.t1.shares, cash: e.cash || S.t1.cash });
    S.t1.stages.sig1 = S.t1.stages.sig1 || "ok"; S.t1.stages.settle = "ok"; t1();
    blot("allocation", "SETTLED · 2/2", "ok", link("tx", e.sig), "ISSUER · INVESTOR", "CONFIDE + TOKEN-2022");
    did("dvp1", "assembled stock + cash as one transaction");
  },
  holding(e) {
    const [who, rest] = e.label.split(/,\s*/);
    const asset = /cash/.test(rest) ? "CASH" : "STOCK";
    const m = e.view.match(/=\s*(\d+)\s*units/);
    S.positions[who + asset] = { holder: HOLDER[who] || who, asset, units: m ? (asset === "CASH" ? "$" : "") + n(m[1]) : "—" };
    renderPositions();
  },
  public(e) {
    const accs = e.accounts.split(","), bals = e.balances.split(",");
    accs.forEach((a, i) => { if (S.accounts[a]) S.accounts[a].pub = bals[i]; });
    renderLedger(); blot("public balances read back", "ALL ZERO", "ok", null, "ANYONE", "TOKEN-2022");
  },
  offer(e) {
    S.act = 2; S.t2.shares = e.shares; S.t2.cash = e.cash; S.t2.stages.pin1 = "ok";
    S.t2.lines.push(`investor offers ${n(e.shares)} shares for $${n(e.cash)} and pins the terms on its side`); t2();
    blot("offer", "TERMS PINNED", "ok", null, "INVESTOR", "CONFIDE");
    did("pin1", "pinned the terms on the investor's side");
  },
  accepted() { S.t2.stages.pin2 = "ok"; S.t2.lines.push("holder 2 reads the offer, pins it, builds the cash leg's proofs"); t2(); blot("accept", "TERMS PINNED", "ok", null, "HOLDER 2", "CONFIDE");
    did("pin2", "pinned them on holder 2's side; built the cash leg"); },
  done(e) { next(null); status(e.mode === "short" ? "done — the short leg was refused" : "done"); },
  process(e) { if (e.state === "failed" || e.state === "timed out") status("the script " + e.state + " — nothing here is inferred from that"); },
};
// act 2 begins when the issuer approves a second holder
const _account = H.account;
H.account = (e) => { if (e.who === "buyer") S.act = 2; _account(e); };

function apply(e) { if (H[e.ev]) H[e.ev](e); }
window.__apply = apply;       // used by the mock harness only
window.__reset = reset;

let currentRun = null;
function connect() {
  const es = new EventSource("/events");
  es.addEventListener("reset", (m) => { try { currentRun = JSON.parse(m.data).r; } catch (_) { currentRun = null; } reset(); });
  es.onmessage = (m) => { let e; try { e = JSON.parse(m.data); } catch (_) { return; } if (e.r !== currentRun) return; apply(e); };
}
document.getElementById("start").addEventListener("click", async () => { const r = await post("/run", { mode: "normal" }); if (!r.ok) status("a run is already in progress"); });
document.getElementById("short").addEventListener("click", async () => { const r = await post("/run", { mode: "short" }); if (!r.ok) status("a run is already in progress"); });
reset();
if (!REPLAY) connect();
```
