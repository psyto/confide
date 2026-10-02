// The Confide demo page. It renders checkpoints; it decides nothing (docs/cwf-2026/DEMO-APP.md).
// Every value shown arrives from the server's sanitised event stream and is inserted as text.
"use strict";

const CSRF = document.querySelector('meta[name="confide-csrf"]').content;
const EXPLORER = (kind, id) => `https://explorer.solana.com/${kind}/${id}?cluster=devnet`;

// The script's step names -> who acts, and the words on the button.
const STEPS = [
  ["parties",            "issuer",   "Set up the issuer and an investor"],
  ["mints",              "issuer",   "Create the stock — gate shut, auditor empty"],
  ["holdings",           "issuer",   "Fund the treasury and the investor's cash"],
  ["investor_opens",     "investor", "Open a confidential account for the stock"],
  ["proofs",             "issuer",   "Build both legs' proofs"],
  ["check",              "investor", "Check the allocation before signing"],
  ["send_allocation",    "issuer",   "Send the allocation (account not approved yet)"],
  ["self_approve",       "investor", "Try to approve my own account"],
  ["issuer_approves",    "issuer",   "Approve exactly this account"],
  ["issuer_signs_alone", "issuer",   "Send with the issuer's signature only"],
  ["investor_signs",     "investor", "Add my signature — settle"],
  ["observe",            "observer", "Look from outside"],
  ["act2_accounts",      "issuer",   "Act 2 — approve a second holder"],
  ["offer",              "investor", "Offer 5,000 shares for $875,000"],
  ["accept",             "buyer",    "Read the offer, pin it, build the cash leg"],
  ["settle",             "investor", "Check the cash against my pin, sign once"],
  ["sign",               "buyer",    "Check the shares against my pin, add the second signature"],
  ["observe2",           "observer", "Look from outside"],
];
const STEP = Object.fromEntries(STEPS.map(([k, who, label]) => [k, { who, label }]));

const el = (tag, cls, text) => {
  const e = document.createElement(tag);
  if (cls) e.className = cls;
  if (text !== undefined) e.textContent = text;
  return e;
};
const short = (s) => (s && s.length > 16 ? s.slice(0, 8) + "…" + s.slice(-4) : s || "");
const link = (kind, id) => {
  const a = el("a", "sig", short(id));
  a.href = EXPLORER(kind, id);
  a.target = "_blank";
  a.rel = "noreferrer noopener";
  return a;
};
const units = (base, decimals) => {
  if (!base || !/^\d+$/.test(base)) return "—";
  const d = Number(decimals || 0);
  const s = base.padStart(d + 1, "0");
  const whole = s.slice(0, s.length - d).replace(/\B(?=(\d{3})+(?!\d))/g, ",");
  return d ? whole : whole;
};

function card(pane, kind, title, lines, extra) {
  const c = el("div", "card " + kind);
  c.appendChild(el("div", "title", title));
  for (const l of lines || []) c.appendChild(el("div", "line", l));
  if (extra) c.appendChild(extra);
  document.getElementById("log-" + pane).prepend(c);
  return c;
}
// offerer / acceptor are the bilateral scripts' own words; in act 2 they are the investor and the buyer.
const paneOf = (who) => ({ issuer: "issuer", investor: "investor", buyer: "buyer",
                           offerer: "investor", acceptor: "buyer" }[who] || "observer");

// ---- the observer reads the chain itself (through the server's allowlisted proxy) ----
const watched = new Map(); // account -> row
async function observe(account, label) {
  if (!watched.has(account)) {
    const row = el("div", "obs-row");
    row.appendChild(el("span", "obs-label", label));
    row.appendChild(link("address", account));
    row.appendChild(el("span", "obs-val", "…"));
    document.getElementById("act-observer").appendChild(row);
    watched.set(account, row);
  }
  const row = watched.get(account);
  try {
    const r = await fetch("/chain/account/" + account);
    if (!r.ok) throw 0;
    const a = await r.json();
    row.lastChild.textContent = a.exists
      ? `public balance ${a.public_balance}` + (a.confidential ? ` · confidential-transfer fields encrypted${a.approved ? "" : " · not approved"}` : "")
      : "not found";
  } catch (_) {
    row.lastChild.textContent = "read failed";
  }
}
async function txLine(sig, what) {
  const line = el("div", "line");
  line.appendChild(el("span", null, what + " "));
  line.appendChild(link("tx", sig));
  const cu = el("span", "dim", "");
  line.appendChild(cu);
  try {
    const r = await fetch("/chain/tx/" + sig);
    if (r.ok) {
      const t = await r.json();
      if (t.found) cu.textContent = ` · ${t.err ? "failed on chain" : "succeeded"} · ${t.compute_units ?? "?"} CU · ${t.signatures} signatures`;
    }
  } catch (_) {}
  return line;
}

// ---- state ----
const accounts = {}; // "investor-X" -> address
let decimals = {};   // "X" -> decimals
let waitingFor = null;

function resetUI() {
  for (const p of ["issuer", "investor", "buyer", "observer"]) {
    document.getElementById("log-" + p).textContent = "";
    document.getElementById("act-" + p).textContent = "";
  }
  watched.clear();
  decimals = {};
  waitingFor = null;
  doneSteps.clear();
  renderSteps();
}

function renderSteps(done) {
  const ol = document.getElementById("steps");
  ol.textContent = "";
  let reached = true;
  for (const [k, who, label] of STEPS) {
    const li = el("li", "step " + who, label);
    if (k === waitingFor) { li.classList.add("now"); reached = false; }
    else if (reached && done && done.has(k)) li.classList.add("done");
    ol.appendChild(li);
  }
}
const doneSteps = new Set();

function showNext(step) {
  for (const p of ["issuer", "investor", "buyer"]) {
    const act = document.getElementById("act-" + p);
    act.querySelectorAll("button").forEach((b) => b.remove());
  }
  document.querySelectorAll("#act-observer button").forEach((b) => b.remove());
  if (!step || !STEP[step]) return;
  const { who, label } = STEP[step];
  const b = el("button", "next", label);
  b.type = "button";
  b.addEventListener("click", async () => {
    b.disabled = true;
    const r = await post("/advance", { step });
    if (!r.ok) { b.disabled = false; setStatus("the script was not waiting for that step"); return; }
    // Between this press and the next checkpoint, the script is doing the step on devnet.
    setStatus("working on devnet: " + label);
  });
  const target = document.getElementById("act-" + (who === "observer" ? "observer" : who));
  target.prepend(b);
}

async function post(path, body) {
  return fetch(path, {
    method: "POST",
    headers: { "Content-Type": "application/json", "X-Confide-CSRF": CSRF },
    body: JSON.stringify(body),
  });
}
const setStatus = (t) => { document.getElementById("status").textContent = t; };

// ---- one handler per checkpoint type ----
const H = {
  run(e) { setStatus(e.mode === "short" ? "running — short-delivery control" : "running"); },
  waiting(e) {
    if (waitingFor) doneSteps.add(waitingFor);
    waitingFor = e.next;
    renderSteps(doneSteps);
    showNext(e.next);
    setStatus("waiting for: " + (STEP[e.next] ? STEP[e.next].label : e.next));
  },
  // the server's record that a step was taken: on a replay it follows that step's "waiting"
  advanced(e) { showNext(null); setStatus("working on devnet: " + (STEP[e.step] ? STEP[e.step].label : e.step)); },
  party(e) { card(paneOf(e.who), "info", "Keypair", [e.pubkey]); },
  mint(e) {
    decimals[e.asset] = e.decimals;
    const name = e.asset === "X" ? "Stock (equity wrapper mirror)" : "Cash (PYUSD mirror)";
    card("issuer", "info", name + " created", [
      "autoApproveNewAccounts: false — the gate is shut",
      "auditor key: " + e.auditor,
    ], link("address", e.mint));
  },
  account(e) {
    accounts[e.who + "-" + e.asset] = e.account;
    const asset = e.asset === "X" ? "stock" : "cash";
    const approved = e.approved === "yes";
    card(paneOf(e.who), approved ? "ok" : "warn",
      `Confidential ${asset} account ${approved ? "— approved by the issuer" : "— NOT approved"}`,
      e.funded && e.funded !== "0" ? ["funded confidentially"] : [], link("address", e.account));
    observe(e.account, `${e.who} ${asset}`);
  },
  proofs() { card("issuer", "info", "Proofs built and verified on chain", ["both legs, before anyone knows whether it will be allowed"]); },
  checked(e) {
    const pane = paneOf(e.who);
    if (e.against) {
      const lines = e.against === "pin"
        ? ["compared with the terms pinned on this side when the offer was made", "the amount coming in is the amount agreed; nothing is signed yet"]
        : ["compared with the counterparty's file, NOT a pin (CONFIDE_UNPINNED=1)"];
      if (e.bound === "yes") lines.push("the transaction is exactly the one that was checked");
      card(pane, e.against === "pin" ? "ok" : "warn",
           e.against === "pin" ? "✓ Checked before signing, against my pinned terms" : "Checked against their file only", lines);
      return;
    }
    card(pane, "ok", "✓ Checked before signing", [
      `decrypted from the verified proof, by me: ${units(e.decrypted_base, e.decimals)} shares`,
      `agreed: ${Number(e.agreed).toLocaleString("en-US")} shares`,
    ]);
  },
  refused(e) {
    const src = { on_chain: "refused on chain", rpc_preflight: "refused in RPC preflight", pre_sign_check: "refused before signing" }[e.source] || e.source;
    const titles = {
      allocation: e.source === "pre_sign_check" ? "✗ Short delivery — refused before any signature" : "✗ Allocation refused — account not approved",
      self_approval: "✗ I cannot approve my own account",
      half_signed: "✗ One signature of two — refused",
    };
    const pane = e.what === "self_approval" || e.source === "pre_sign_check" ? "investor" : "issuer";
    const lines = [src + (e.err ? " · " + e.err : "")];
    if (e.source === "pre_sign_check") lines.push(`agreed ${Number(e.agreed).toLocaleString("en-US")} shares · this leg moves ${units(e.decrypted_base, e.decimals)}`);
    if (e.message) lines.push(e.message);
    if (e.signatures) lines.push("signatures present: " + e.signatures);
    if (e.source === "rpc_preflight") lines.push("it never entered a block, so there is no signature to cite");
    card(pane, "bad", titles[e.what] || "✗ Refused", lines, e.sig ? link("tx", e.sig) : null);
    if (e.sig) txLine(e.sig, "refused:").then((l) => card("observer", "bad", "A refused transaction, on chain", [], l));
  },
  approval(e) {
    card("issuer", e.approved === "true" ? "ok" : "warn",
      e.approved === "true" ? "✓ Approved exactly this account" : "Account still reads: not approved",
      [], e.sig ? link("tx", e.sig) : link("address", e.account));
    observe(e.account, "investor stock");
  },
  settled(e) {
    const act2 = e.act === "2";
    const lines = act2
      ? ["5,000 shares ⇄ $875,000 between two approved holders", "one transaction"]
      : [`${Number(e.shares).toLocaleString("en-US")} shares ⇄ $${Number(e.cash).toLocaleString("en-US")}`, "delivery and payment in one transaction · " + (e.signatures || "")];
    for (const p of act2 ? ["investor", "buyer"] : ["issuer", "investor"]) card(p, "ok", "✓ Settled", lines, link("tx", e.sig));
    txLine(e.sig, "settled:").then((l) => card("observer", "ok", "A settlement — the amounts are not in it", [], l));
  },
  holding(e) {
    const who = e.label.split(",")[0];
    card(paneOf(who), "info", "My balance, read with my own key", [e.label.replace(/^[^,]+,\s*/, ""), e.view]);
  },
  public(e) {
    const accs = e.accounts.split(",");
    const bals = e.balances.split(",");
    card("observer", "ok", "What anyone can read: public balances", accs.map((a, i) => `${short(a)}  →  ${bals[i]}`));
    accs.forEach((a) => observe(a, "account"));
  },
  offer(e) { card("investor", "info", "Offer sent — terms pinned on my side", [`${Number(e.shares).toLocaleString("en-US")} shares for $${Number(e.cash).toLocaleString("en-US")}`, "id " + e.id]); },
  accepted() { card("buyer", "info", "Offer accepted — terms pinned on my side", ["cash leg's proofs built and verified on chain"]); },
  done(e) {
    // the last step the script waited on is complete too; the run's own steps are marked, nothing more
    if (waitingFor) doneSteps.add(waitingFor);
    waitingFor = null; showNext(null);
    setStatus(e.mode === "short" ? "done — the short leg was refused" : "done");
    renderSteps(doneSteps);
  },
  process(e) {
    if (e.state === "failed" || e.state === "timed out") setStatus("the script " + e.state + " — see the terminal log; nothing on this page is inferred from that");
  },
};

let currentRun = null;
function connect() {
  const es = new EventSource("/events");
  es.addEventListener("reset", (m) => {
    try { currentRun = JSON.parse(m.data).r; } catch (_) { currentRun = null; }
    resetUI();
  });
  es.onmessage = (m) => {
    let e;
    try { e = JSON.parse(m.data); } catch (_) { return; }
    if (e.r !== currentRun) return;   // a line from a run this page is no longer showing
    if (H[e.ev]) H[e.ev](e);
  };
}

document.getElementById("start").addEventListener("click", async () => {
  const r = await post("/run", { mode: "normal" });
  if (!r.ok) setStatus("a run is already in progress");
});
document.getElementById("short").addEventListener("click", async () => {
  const r = await post("/run", { mode: "short" });
  if (!r.ok) setStatus("a run is already in progress");
});
// The same test hook ops.js has: video/test-ops-replay.mjs feeds events straight to the handlers.
// CONFIDE_REPLAY is never set by the server, so a live page always connects.
window.__apply = (e) => { if (H[e.ev]) H[e.ev](e); };
renderSteps();
if (!window.CONFIDE_REPLAY) connect();
