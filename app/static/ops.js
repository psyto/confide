// Confide — settlement operations view. Renders checkpoints; decides nothing (docs/cwf-2026/DEMO-APP.md).
// Same event stream and same rules as app.js: every value arrives from the server's sanitised stream
// and is inserted as text. No trade value or outcome is shown here that the run did not produce. The one
// exception is labelled on screen: the "who would read this trade's amount elsewhere" card is sourced
// research (docs/cwf-2026/COMPARABLES.md), and only its DEX row's figures -- this trade's -- come from the run.
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
  document.getElementById("elsewhere").hidden = true;
  document.getElementById("ledger-note").hidden = false;
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
// atomicity is Solana's, and reading public state back is an RPC read (Codex, 2026-09-30, corrected
// both: the settlement had left Solana out, and the read-back had been credited to Token-2022). Confide builds the proofs, checks before signing, pins terms, binds the
// transaction and assembles it. The refusals are Token-2022's and Solana's, and are labelled so.
const BY = {
  proofs: "CONFIDE", check: "CONFIDE", gate: "TOKEN-2022", approve: "TOKEN-2022", sig1: "SOLANA", settle: "CONFIDE + TOKEN-2022 + SOLANA",
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
  // the server's record that a step was taken: on a replay it follows that step's "waiting"
  advanced(e) { next(null); status("working on devnet: " + (STEPS[e.step] ? STEPS[e.step][1] : e.step)); },
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
    if (e.act === "2") { S.t2.stages.settle = "ok"; S.t2.sig = e.sig; t2(); blot("bilateral trade", "SETTLED · 2/2", "ok", link("tx", e.sig), "INVESTOR · HOLDER 2", "CONFIDE + TOKEN-2022 + SOLANA");
      did("dvp2", "assembled the holders' trade as one transaction"); return; }
    Object.assign(S.t1, { sig: e.sig, cu: e.cu, shares: e.shares || S.t1.shares, cash: e.cash || S.t1.cash });
    S.t1.stages.sig1 = S.t1.stages.sig1 || "ok"; S.t1.stages.settle = "ok"; t1();
    blot("allocation", "SETTLED · 2/2", "ok", link("tx", e.sig), "ISSUER · INVESTOR", "CONFIDE + TOKEN-2022 + SOLANA");
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
    renderLedger(); blot("public balances read back", "ALL ZERO", "ok", null, "ANYONE", "SOLANA RPC");
    // The comparison appears only once the run has read its own public balances back, and the
    // DEX row's figures are this trade's, from the run's own checkpoints -- nothing typed here.
    const t = e.act === "2" ? S.t2 : S.t1;
    if (t.shares && t.cash && bals.every((b) => b === "0")) {
      document.getElementById("ew-dex").textContent = `${n(t.shares)} shares · $${n(t.cash)}`;
      document.getElementById("elsewhere").hidden = false;
      document.getElementById("ledger-note").hidden = true;   // its content is the block's last line
    }
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
