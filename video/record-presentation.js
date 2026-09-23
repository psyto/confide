// Records presentation.mp4 — the CWF submission presentation, ten scenes, silent.
//
// The rough cut. Its job is to find out whether the story in CWF-PRESENTATION.md holds before the
// week the video has to exist, so it is deliberately cheap: no voice, no colour grade, the same
// renderer the published cut uses.
//
//   node video/record-presentation.js
//
// Scene durations are read out of video/CWF-PRESENTATION.md, whose table pace.py derives from the
// narration's own word counts. They are not repeated here — two places holding the same number is
// how the Stocklana cut ended up with a manifest describing a different edit.
//
// The cut draws conclusions as cards and prints the output it concluded from underneath them. Every
// figure on screen comes from a command run moments before the recording starts — four of them
// reaching mainnet or devnet — or from a file checked against one, and each is guarded on the line
// that carries its claim. Scene 9 is the one scene with no measurement in it, because its claim is
// arithmetic; it is drawn in letters and says so. A video that still renders after the thing it
// demonstrates stopped working is the failure worth engineering against — which is not hypothetical here: scene 5's claim is a quotation from
// someone else's repository, and they can change it without telling us.
import path from "node:path";
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { execFileSync } from "node:child_process";
import puppeteer from "puppeteer";
import { PuppeteerScreenRecorder } from "puppeteer-screen-recorder";

const dir = path.dirname(fileURLToPath(import.meta.url));
const repo = path.join(dir, "..");
// ONE NAME. The visual pass wrote presentation-improved.mp4 while split.sh and
// docs-consistency.sh both read presentation.mp4, and the file the founder was handed was called
// a third thing -- so re-running the recorder and then splitting would have cut the OLD film.
// This is staged under .presentation-render and only moved into place once every check has run.
const outFile = path.join(dir, "presentation.mp4");
const stagedFile = path.join(dir, ".presentation-render", "staged.mp4");
const segDir = path.join(dir, "segments-presentation");
const renderDir = path.join(dir, ".presentation-render");
const FFMPEG = process.env.FFMPEG_PATH || "/opt/homebrew/bin/ffmpeg";
const FFPROBE = process.env.FFPROBE_PATH || FFMPEG.replace(/ffmpeg$/, "ffprobe");
const KEYS = process.env.CONFIDE_KEYS || path.join(repo, "account-keys.json");
const ACCOUNT = process.env.CONFIDE_ACCOUNT || JSON.parse(readFileSync(KEYS, "utf8")).account;

// ── the holds, from the script ───────────────────────────────────────────────────────────────────
const md = readFileSync(path.join(dir, "CWF-PRESENTATION.md"), "utf8");
// `(\d+)` and not `(\d)`. A single digit read nine of the ten rows and the tenth scene silently
// had no hold — which the count check caught, and only because the count is checked.
const rows = [...md.matchAll(/^\| (\d+) \| [^|]+\| ([\d]+)(?: \+ ([\d.]+))? \|/gm)];
if (rows.length !== 10) throw new Error(`CWF-PRESENTATION.md: expected 10 timing rows, found ${rows.length}`);
const HOLD = rows.map((m) => parseInt(m[2], 10) + (m[3] ? parseFloat(m[3]) : 0));
process.stderr.write(`• scene holds from CWF-PRESENTATION.md: ${HOLD.join(" / ")} s\n`);

// Half these scripts read mainnet and half read devnet, and one RPC for all of them is not a
// configuration — it is a bug that renders. Passing a mainnet endpoint through to
// `read-balance.sh` had it look for a devnet account on mainnet and die inside a Python traceback
// with no indication of which run it was.
const MAINNET = process.env.MAINNET_RPC || process.env.RPC || "https://api.mainnet-beta.solana.com";
const DEVNET = process.env.DEVNET_RPC || "https://api.devnet.solana.com";
function run(cmd, args, label, rpc) {
  process.stderr.write(`• ${label} …\n`);
  return execFileSync(cmd, args, {
    cwd: repo, encoding: "utf8", maxBuffer: 8 * 1024 * 1024,
    env: { ...process.env, FORCE_COLOR: "1", ...(rpc ? { RPC: rpc } : {}) },
  }).replace(/\s+$/, "");
}
const plain = (t) => t.replace(/\x1b\[[0-9;]*m/g, "");
// One line of a pane, verbatim, for the evidence strip under a card. Throws when the line is gone,
// which is the point: the card concludes something and this is the output it concluded from.
function line(text, re, why) {
  const found = text.split("\n").map(plain).find((l) => re.test(l));
  if (!found) throw new Error(`refusing to record — ${why}: no line matched ${re}`);
  return found.replace(/^\s+/, "").replace(/\s+$/, "");
}
function slice(text, from, to) {
  const lines = text.split("\n");
  const a = lines.findIndex((l) => from.test(plain(l)));
  if (a < 0) throw new Error(`slice: no line matched ${from}`);
  const b = lines.slice(a).findIndex((l) => to.test(plain(l)));
  if (b < 0) throw new Error(`slice: no line matched ${to} after ${from}`);
  return lines.slice(a, a + b + 1).join("\n").replace(/^\s*\n/, "").replace(/\n\s*$/, "");
}

// ── the real runs ────────────────────────────────────────────────────────────────────────────────
const mints = run("bash", ["scripts/onchain-check.sh"], "reading the xStock mints on mainnet", MAINNET);
const balance = run("bash", ["scripts/read-balance.sh", ACCOUNT, KEYS], "opening our own confidential balance", DEVNET);
// The account scan takes minutes — it reads every token account of every mint — so the pane is
// the stored result, which carries its own measurement timestamp and says so on screen. Every
// other pane here is a command run moments ago; this one is a command that prints when it ran.
const usage = run("bash", ["scripts/usage-scan.sh", "--last"], "reprinting the account scan");
const swaps = run("bash", ["scripts/swap-status.sh", "plain"], "reading the swaps back off devnet", DEVNET);
// Scene 7 is the whole claim, and it used to be a list of instruction names — which shows that two
// transfers happened and not that a trade did. This pane carries the exchange: the public view
// read live, and beside it the two columns the parties wrote down at the time, because the amounts
// are confidential and nothing on chain can recover them afterwards.
const dvp = run("bash", ["scripts/dvp-show.sh"], "reading the delivery-versus-payment", DEVNET);
const issued = run("bash", ["scripts/swap-status.sh", "plain"], "reading the issuance pair back off devnet", DEVNET);
const feeSwap = run("bash", ["scripts/swap-status.sh", "fee"], "reading the with-fee swap back off devnet", DEVNET);
const cash = run("bash", ["scripts/cash-scan.sh"], "reading the stablecoins on mainnet", MAINNET);
const testbed = run("bash", ["scripts/testbed-up.sh", "--check"], "checking the standing devnet issuer", DEVNET);

// The private half of the trade, written by the parties at the moment it settled — the only
// moment those figures exist, because nothing on chain can recover them afterwards.
const DVP = JSON.parse(readFileSync(path.join(repo, "web/dvp.json"), "utf8"));

// ── guards ───────────────────────────────────────────────────────────────────────────────────────
// The order's own conditions, read out of the file that was pinned from the SEC's release. The
// first three scenes are about a regulation, so the only honest picture is the text of it — and
// typing that text into this file would be the copy this repository keeps making.
const SEC = readFileSync(path.join(repo, "docs/SEC-EXEMPTION.md"), "utf8");
// The card paraphrases for legibility, so every value on it is checked against the pinned row here.
// Without this the scene would be typed text about a regulation, which is the copy this repository
// keeps making -- and this one would be quoted back at a judge.
function secMust(name, phrases) {
  const row = secRow(name);
  for (const p of phrases) {
    if (!row.includes(p)) throw new Error(`the "${name}" condition no longer says "${p}" — docs/SEC-EXEMPTION.md`);
  }
}
function secRow(name) {
  const m = SEC.match(new RegExp(`^\\| \\*\\*${name}\\*\\* \\| (.+?) \\|$`, "m"));
  if (!m) throw new Error(`docs/SEC-EXEMPTION.md no longer has the "${name}" condition`);
  return m[1].replace(/\*\*/g, "").replace(/"/g, '"').replace(/\s+/g, " ").trim();
}

// THE ISSUANCE, out of the record of the run rather than out of a sentence. The visual pass put
// "The same 20,000-share allocation" on screen as a literal: the value was right and nothing
// checked it, which is how every stale number in this repository started.
const ISSUANCE = (() => {
  const swaps = JSON.parse(readFileSync(path.join(repo, "web/swaps.json"), "utf8")).swaps;
  const settled = swaps.find((s) => /issuance: the same allocation/.test(s.label));
  const refused = swaps.find((s) => /issuance: REFUSED/.test(s.label));
  if (!settled || !refused) throw new Error("web/swaps.json no longer records both issuance sends");
  const m = settled.claim.match(/([\d,]+) shares/);
  if (!m) throw new Error(`web/swaps.json's issuance claim no longer gives a size: ${settled.claim}`);
  const custom = refused.err_when_written?.InstructionError?.[1]?.Custom;
  if (custom !== 24) {
    throw new Error(`the refused issuance recorded Custom(${custom}), not Custom(24) — scene 8 `
      + `says the gate refused it for not being approved`);
  }
  return { size: m[1] + "-share", settled: settled.signature, refused: refused.signature };
})();

// Scene 5's three issuer powers, named as the extensions that grant them and counted from the
// inventory rather than asserted. If an issuer drops one of these the scene is wrong, and the
// number beside it is the thing that would say so.
const SLOT_ROLES = (() => {
  const slots = JSON.parse(readFileSync(path.join(repo, "web/slots.json"), "utf8"));
  const want = [["pausableConfig", "freeze a transfer"],
                ["permanentDelegate", "seize a holder's tokens"],
                ["transferHook", "run their own code"]];
  return want.map(([ext, does]) => {
    const n = slots.extensions[ext];
    if (n !== slots.mints) {
      throw new Error(`web/slots.json says ${n} of ${slots.mints} mints carry ${ext} — scene 5 `
        + `says the issuer has all three powers on every one of them`);
    }
    return { ext, does, n: n.toLocaleString("en-US") };
  });
})();

// Scene 10 claims a repair in this repository's own code, which is the claim a judge can check
// fastest. So the claim is read from the file that implements it.
const SIGN = readFileSync(path.join(repo, "scripts/swap-sign.sh"), "utf8");

const USAGE = JSON.parse(readFileSync(path.join(repo, "web/usage.json"), "utf8"));
const ACCOUNTS = USAGE.total_accounts.toLocaleString("en-US");
const CONFIGURED = USAGE.total_confidential_accounts;
const APPROVED = USAGE.total_approved_accounts;
if (APPROVED !== 0) {
  throw new Error(`an issuer has approved ${APPROVED} account(s) — the gate is open and every scene `
    + `that says it is shut is now wrong`);
}

for (const [text, re, why] of [
  [mints, /NVDAx.*Token-2022.*None/, "NVDAx no longer reads as Token-2022 with an empty auditor slot"],
  [mints, /NVDA\.US.*Token-2022.*None/, "Backpack's NVDA.US no longer reads the same way"],
  [balance, /public balance\s+0/, "the account's public balance is no longer zero"],
  [balance, /173000 units/, "the confidential balance did not open to the expected position"],
  // Scene 4 is the whole reveal, and it says zero. If anybody has opened a confidential account
  // since the scan, the scene is wrong and the right response is to rescan, not to record.
  // TYPED IN TWICE, AND STALE BOTH TIMES. This said 329,536 — correct on 2026-09-17 and 465,520 four
  // days later — so the render refused on a guard that was itself out of date. The count is read
  // from the file that computes it, exactly as MINT_COUNT already was.
  // Was `.*0.* configured`, which is the count that moved. The scene's claim is that nobody is
  // THROUGH the gate, so the guard reads the approved count and both numbers come from the file
  // rather than from a pattern that happened to match a zero somewhere in the line.
  [usage, new RegExp(`${ACCOUNTS} token accounts, ${CONFIGURED} configured for confidential`
                     + ` transfers, ${APPROVED} approved`),
   `the scan no longer reads ${ACCOUNTS} / ${CONFIGURED} configured / ${APPROVED} approved`
   + ` — rerun ./scripts/usage-scan.sh`],
  [swaps, /confidentialTransfer, confidentialTransfer/, "the plain swap no longer carries two confidential transfers"],
  [swaps, /public balance 0 on every one/, "a swap account's public balance is no longer zero"],
  [dvp, /4 of 4 accounts/, "one of the four accounts in the recorded trade has gone, or stopped reading zero"],
  [dvp, /50,000 shares.*\$8,750,000/, "the recorded trade is no longer 50,000 shares against $8,750,000"],
  // The picture is drawn from web/dvp.json and the guard above reads the chain, so the two have to
  // agree or the scene is drawing a trade that did not happen.
  [String(DVP.delivered_units), /^50000$/, "web/dvp.json no longer describes the trade this scene draws"],
  [feeSwap, /confidentialTransfer, confidentialTransferWithFee/, "the with-fee swap no longer carries both instruction kinds — scene 7 is about exactly that"],
  [feeSwap, /every swap still reads as recorded/, "the with-fee swap did not read back clean"],
  [cash, /PYUSD.*Token-2022/, "PYUSD is no longer Token-2022"],
  [cash, /USDC.*Token \(legacy\)/, "USDC is no longer legacy SPL — scene 8 contrasts them"],
  [cash, /the same key holds the confidential authority on both/, "PYUSD and USDG no longer share one authority, and scene 8 says they do"],
  [testbed, /the testbed is as published/, "the standing devnet issuer has been changed — scene 9 points people at it"],
  // Scene 8's two cards, against the two transactions read back off devnet.
  [issued, /issuance: REFUSED/, "the refused issuance is no longer on chain — scene 8 shows it refusing"],
  [issued, /'Custom': 24.*\(expected\)/, "the refusal is no longer Custom(24) — scene 8 names that error"],
  [issued, /issuance: the same allocation, after the issuer signed/, "the settled issuance is gone — scene 8 shows the same allocation settling"],
  // Scene 10's card says the repair rebuilds and compares. This is that call.
  [SIGN, /swap-tx -- verify/, "scripts/swap-sign.sh no longer rebuilds and compares — scene 10 says it does"],
]) {
  if (!re.test(plain(text))) throw new Error(`refusing to record — ${why}`);
}

// ── the cut ──────────────────────────────────────────────────────────────────────────────────────
// One entry per scene of CWF-PRESENTATION.md, in its order, with its hold. `line` is the narration,
// carried into the manifest so LINES.md can pair each clip with what goes on it.
const matched = [...md.matchAll(/^### (\d+) — ([^·\n]+?)\s*(?:·[^\n]*)?$\n\n((?:^> ?.*\n)+)/gm)];
const script = matched.map((m) => m[3].replace(/^> ?/gm, "").trim().replace(/\n+/g, " "));
const TITLES = matched.map((m) => m[2].trim());
if (script.length !== 10) throw new Error(`CWF-PRESENTATION.md: expected 10 scripted scenes, found ${script.length}`);

// The mint count and issuer count are read at render time, not written into the page. The slot
// scene said "All 1,869" and "Two, independently" as literals until 2026-09-19, when a third
// issuer appeared and neither the page nor any test noticed.
const MINTS = JSON.parse(readFileSync(path.join(repo, "web/mints.json"), "utf8"));
const MINT_COUNT = MINTS.length.toLocaleString("en-US");
const ISSUERS = new Set(MINTS.map((m) => m.issuer)).size;

// `for` is the script heading each scene is footage FOR, and it is checked below. The pairing used
// to be by array index alone — and the 2026-09-22 restructure kept the count at ten while replacing
// the first three scenes, so a render would have laid "the SEC opened the market" over the old title
// card and reported success. An index is not a binding.
secMust("Every trade's size is published", ["within 10 minutes", "the transaction size",
                                            "the transaction time", "the transaction direction"]);
secMust("Size is capped", ["0.25% of average daily share volume", "three months"]);
// The card also says "five years of relief" and "only through an AMM". Both are the pinned file's,
// so both are checked here rather than trusted to stay true.
secMust("The venue is an AMM", ["only covers trading of Tokenized NMS Stock executed by an AMM"]);
if (!SEC.includes("2031-09-17")) {
  throw new Error("docs/SEC-EXEMPTION.md no longer gives the expiry — the card says five years");
}

const scenes = [
  {
    file: "01-this-account.mp4", for: "this account", kind: "positionReveal",
    label: "A real Solana account. Publicly, it looks empty.",
    account: ACCOUNT,
    units: "173,000",
    // The card is the headline and these two lines are the output it reads. The second is withheld
    // until the narration reaches it -- "It holds a hundred and seventy-three thousand shares"
    // starts about five seconds in, and the picture should arrive with the words rather than
    // after them. The scene used to hold five silent seconds past the last word; the founder cut
    // that on 2026-09-23, so the reveal moved from 6 s to 5 s to stay inside a 10 s scene.
    evidence: line(balance, /public balance/, "the account's public balance"),
    heldEvidence: line(balance, /confidential\s+\d/, "the account's confidential balance"),
    from: "./scripts/read-balance.sh — run moments before this recording",
    at: 5,
    total: HOLD[0],
  },
  {
    file: "02-nobody-allowed.mp4", for: "and nobody has been allowed one", kind: "adoption",
    label: "The capability exists. Adoption does not.",
    stocks: MINT_COUNT,
    issuers: ISSUERS,
    accounts: ACCOUNTS,
    configured: CONFIGURED,
    approved: APPROVED,
    evidence: line(usage, /token accounts,/, "the scan's total"),
    from: "./scripts/usage-scan.sh — every token account of every mint that has holders",
    // The scan reads every token account of every mint and takes minutes, so the date stays on
    // screen even though the display now leads with the conclusion instead of raw terminal rows.
    measured: JSON.parse(readFileSync(path.join(repo, "web/usage.json"), "utf8")).generated_utc,
    total: HOLD[1],
  },
  {
    // THE PLAIN DEFINITION, BACK. It said "Issuance first — the only trade the gate lets through",
    // which was written when this sat after the gate scene. Here the viewer has not met the gate,
    // so that sentence would be about something they have not been shown. The ordering claim is
    // scene 7's job, where it is earned.
    file: "03-confide.mp4", for: "Confide", kind: "hero",
    sub: "confidential delivery-versus-payment for tokenized stocks on Solana",
    lede: "Two holders trade a position for cash in <b>one transaction</b>,<br>"
        + "and <b>neither publishes what moved</b>.",
    total: HOLD[2],
  },
  {
    // RESTORED. Dropped as collateral damage in the 2026-09-22 restructure rather than by any
    // decision -- and it is the only picture that carries the product without a word of explanation.
    file: "04-the-trade.mp4", for: "the trade", kind: "dvp",
    // SPOKEN AND SHOWN, which this file's rules otherwise forbid. It is the sentence that says what
    // Confide does, and a judge skimming with the sound off would otherwise take away the outcome
    // and never the product. One exception in 177 seconds.
    say: true,
    label: "Confide <b>builds the proofs the chain will not assemble</b> for you, and lets "
         + "<b>each side check the other before signing</b>.",
    seller: DVP.seller, buyer: DVP.buyer,
    delivered: DVP.delivered_units, paid: DVP.paid_units,
    total: HOLD[3],
  },
  {
    // THE SCREEN STOPPED REPEATING THE VOICE. The card listed "Freeze a transfer / Move a holder's
    // tokens / Run custom logic" while the narration said the same three things in the same order
    // -- the one thing this file's rules forbid. The voice keeps the plain English; the screen
    // carries the extension names instead, which a Solana judge reads instantly and can check
    // against the mints themselves. Every count below is read from web/slots.json, which
    // ./scripts/slot-roles.sh prints and docs-consistency.sh already checks.
    file: "05-why-shut.mp4", for: "why the door is shut", kind: "privacyGap",
    mints: MINT_COUNT, issuers: ISSUERS, controls: SLOT_ROLES, total: HOLD[4],
  },
  // The product, then the product working, inside the first thirty seconds. The order this
  // replaces put the trade ninety seconds in, on a premise CRITERIA.md retracted on 2026-09-19:
  // traction is last of the seven and absent from the Official Rules, §8 opens on Functionality,
  // and §8(e) asks how the work composes with other primitives — which was the buried scene.
  {
    // The condition, at reading size. It used to be poured into the `pre` pane -- 13.5px monospace,
    // white-space:pre -- so an English sentence ran off the right edge and was cut mid-word. The
    // words on screen are short; every value in them is checked against the pinned order below.
    file: "06-why-now.mp4", for: "why now", kind: "order",
    label: "The SEC's order, 17 September 2026.",
    stamp: "sec.gov — press release 2026-90",
    grant: "Tokenized stock: five years of relief.",
    quote: '<span class="but">But only through an AMM — where</span> <em>every trade you make is '
         + 'published</em>: the size, the direction, <em>within ten minutes</em>.',
    rule: ["0.25%", "of average daily volume is all you may trade in a Tier 1 name. "
                  + "<b>Exceed it twice and the symbol pauses for three months.</b>"],
    total: HOLD[5],
  },
  {
    // THE TURN, and it had no scene. Nine scenes described a shut gate and then showed a trade that
    // needs it open; a judge who knows Token-2022 asks how, and the film had no answer.
    file: "07-the-turn.mp4", for: "so the first trade is an issuance", kind: "statement",
    kicker: "the party who can open the account is one of the two",
    // THE SCREEN IS NOT THE SCRIPT. This carried the narration almost word for word, which this
    // file's own rule forbids — the voice says why, so the screen says only what.
    say: "Not a swap between two holders.<br><b>An issuance.</b>",
    total: HOLD[6],
  },
  {
    // THE GATE, CLOSING AND THEN OPENING. The film described the gate for nine scenes and never
    // showed it stop anything. This is the same allocation twice: refused by the live program, then
    // settled after one instruction. The pane is swap-status.sh's own reading of both transactions,
    // so the refusal on screen is the one anybody can look up rather than a drawing of one.
    file: "08-the-gate.mp4", for: "the gate, both ways", kind: "issuerGate",
    // The size came back as a typed literal — correct, and guarded by nothing. It is read out of
    // the record of the run instead, and ISSUANCE is checked against the chain below.
    label: `The same ${ISSUANCE.size} allocation, before and after issuer approval.`,
    whyRefused: "Custom(24) — the issuer had not signed for the account.",
    evidence: line(issued, /'Custom': 24/, "the refusal") + "\n"
            + line(issued, /error\s+none/, "the settlement"),
    from: "./scripts/swap-status.sh — both transactions read back off devnet",
    total: HOLD[7],
  },
  {
    // Why not an exchange — the question a Solana judge asks first, and the film had no answer.
    // Three steps and no numbers: inventing a pool to illustrate it would be the one thing this
    // repository does not do.
    file: "09-why-not-an-exchange.mp4", for: "why not just use an exchange", kind: "ammLeak",
    label: "Why a public AMM cannot conceal a block trade",
    total: HOLD[8],
  },
  {
    file: "10-what-i-got-wrong.mp4", for: "what I got wrong, and what you can run", kind: "proofCheck",
    label: "A review caught a check that did not inspect what it signed.",
    detail: "Rebuilds the transaction and compares it byte for byte",
    // THE VOICE INVITES AND THE SCREEN DISCLOSES. The film used to end on "nobody outside this
    // repository has used any of this" — true, and the last thing a judge heard before writing
    // their note. The disclosure did not move off the film, it moved off the END: it is here, in
    // type a judge reads, while the narration closes on the command.
    command: "./scripts/testbed-join.sh",
    traction: "No pilot, no user, no issuer asked. Nobody outside this repository has run any of it.",
    // The card claims a repair, so it shows the call that is the repair — checked below, because a
    // claim about this repository's own code is the one a judge can check fastest.
    evidence: line(SIGN, /swap-tx -- verify/, "the rebuild-and-compare call") + "\n"
            + line(testbed, /the testbed is as published/, "the standing devnet issuer"),
    from: "scripts/swap-sign.sh — the step the review found was not checking",
    url: "github.com/psyto/confide",
    total: HOLD[9],
  },

].map((s, i) => ({ ...s, line: script[i] }));

// THE BINDING between narration and footage. Names, not positions.
scenes.forEach((s, i) => {
  if (s.for !== TITLES[i]) {
    throw new Error(
      `scene ${i + 1} of the script is "${TITLES[i]}" and the footage here is for "${s.for}" — ` +
      `CWF-PRESENTATION.md was restructured and this scene has no picture yet`);
  }
});

// ── record ───────────────────────────────────────────────────────────────────────────────────────
const browser = await puppeteer.launch({
  headless: "new",
  defaultViewport: { width: 1280, height: 720, deviceScaleFactor: 1.5 },
  args: ["--no-sandbox", "--hide-scrollbars", "--window-size=1280,720", "--force-device-scale-factor=1.5"],
});
let page = await browser.newPage();
const marks = [];
const overlaps = [];
const figures = [];
const onConsole = (m) => {
  const t = m.text();
  if (!t.startsWith("CONFIDE_")) return;
  process.stderr.write(`• page: ${t}\n`);
  const scene = t.match(/^CONFIDE_SCENE \S+ ([0-9.]+)/);
  if (scene) marks.push(parseFloat(scene[1]));
  const total = t.match(/^CONFIDE_SECONDS ([0-9.]+)/);
  if (total) marks.push(parseFloat(total[1]));
  const over = t.match(/^CONFIDE_OVERLAP (.+) (\d+)$/);
  if (over) overlaps.push(`"${over[1]}" reaches ${over[2]}px into the wordmark`);
  const figs = t.match(/^CONFIDE_FIGURES ([^\t]+)\t(.+)$/);
  if (figs) for (const n of figs[2].split(" ")) figures.push({ scene: figs[1], n });
};
page.on("console", onConsole);
page.on("pageerror", (e) => { throw e; });
await page.goto("file://" + path.join(dir, "demo.html"), { waitUntil: "load" });
await page.evaluate((s) => {
  document.body.classList.add("presentation");
  window.__load(s);
}, scenes);

// Long Chromium recordings intermittently interleave broken H.264 packets on this host. A scene
// is already an intentional editorial boundary, so record and validate each one independently,
// then concatenate the verified clips. This also makes one bad scene recoverable without asking a
// viewer to sit through a new three-minute capture.
// THE FRAMES NOBODY LOOKED AT. Recording each scene separately and concatenating is worth keeping
// -- one bad scene becomes recoverable, and each clip is verified on its own -- but as delivered it
// put SEVEN PURE-WHITE FRAMES into a film whose background sits at luminance 12. Six of the nine
// cuts flashed white. `ffprobe` cannot see that: it is not a container property, and the file
// "probes cleanly". It is visible to anyone watching, at every scene change.
//
// Two causes, both here rather than in the page:
//
//   the flash   the screen recorder emits its first frame before the page has painted the new
//               scene, and concat keeps it. So the first frame of every clip is measured, and
//               dropped when it is white.
//   the drift   each raw capture runs about a second past the page's own clock. That passed the
//               per-clip 2 s check and then ACCUMULATED: ten clips totalling 179.97 s against a
//               170 s script, which the old aggregate check would have caught only after the file
//               had already been written and handed over. Each clip is now cut to the page's
//               measurement exactly, so the sum is the script by construction.
//
// Nothing is promoted to video/presentation.mp4 until every clip, and then the assembly, has been
// measured again from its own frames.
const FPS = 30;
function meanLuma(file, at) {
  const buf = execFileSync(FFMPEG, ["-v", "error", "-ss", String(at), "-i", file, "-frames:v", "1",
    "-vf", "scale=64:36,format=gray", "-f", "rawvideo", "-"], { maxBuffer: 1 << 22 });
  if (!buf.length) return 0;
  let sum = 0;
  for (const b of buf) sum += b;
  return sum / buf.length;
}
// Every frame, not a sample. A single white frame is 1/30 of a second and is exactly what got out.
function whiteFrames(file) {
  const out = execFileSync(FFMPEG, ["-v", "error", "-i", file, "-vf",
    "scale=64:36,signalstats,metadata=print:key=lavfi.signalstats.YAVG:file=-", "-f", "null", "-"],
    { encoding: "utf8", maxBuffer: 1 << 26 });
  const times = [];
  let pts = null;
  for (const l of out.split("\n")) {
    const p = l.match(/pts_time:([0-9.]+)/);
    if (p) { pts = parseFloat(p[1]); continue; }
    const y = l.match(/lavfi\.signalstats\.YAVG=([0-9.]+)/);
    if (y && parseFloat(y[1]) > 200 && pts !== null) times.push(pts);
  }
  return times;
}
function probe(file) {
  return parseFloat(execFileSync(FFPROBE, ["-v", "error", "-show_entries", "format=duration",
    "-of", "csv=p=0", file], { encoding: "utf8" }).trim());
}

mkdirSync(renderDir, { recursive: true });
const durations = [];
for (const scene of scenes) {
  const raw = path.join(renderDir, scene.file + ".raw.mp4");
  const segmentFile = path.join(renderDir, scene.file);
  // THE FAILURE THE PER-SCENE LOOP IS FOR, and it is real: on 2026-09-23 a ten-scene run died at
  // scene 10 with `Protocol error (Runtime.callFunctionOn): Target closed` and the identical rerun
  // finished clean. Intermittent, roughly one run in three here. Recording per scene is what makes
  // it recoverable, so recover from it rather than making the founder re-run three minutes of
  // capture: a fresh page, once, and the scene again.
  let seconds;
  for (let attempt = 1; ; attempt++) {
    try {
      await page.evaluate((s) => window.__load([s]), scene);
      const recorder = new PuppeteerScreenRecorder(page, {
        fps: FPS, videoFrame: { width: 1920, height: 1080 }, aspectRatio: "16:9", ffmpeg_Path: FFMPEG,
      });
      await recorder.start(raw);
      seconds = await page.evaluate(() => window.__play());
      await recorder.stop();
      break;
    } catch (e) {
      if (attempt > 1) throw e;
      process.stderr.write(`  ! ${scene.file}: ${e.message.split("\n")[0]} — new page, once more\n`);
      page = await browser.newPage();
      page.on("console", onConsole);
      page.on("pageerror", (err) => { throw err; });
      await page.goto("file://" + path.join(dir, "demo.html"), { waitUntil: "load" });
      await page.evaluate(() => document.body.classList.add("presentation"));
    }
  }
  const rawLen = probe(raw);
  if (Math.abs(rawLen - seconds) > 2) {
    throw new Error(`${scene.file} captured ${rawLen.toFixed(1)}s for ${seconds.toFixed(1)}s of `
      + `page time — the recorder could not keep up`);
  }
  // Drop the unpainted first frame when there is one, then cut to the page's own measurement.
  const lead = meanLuma(raw, 0) > 200 ? 1 / FPS : 0;
  if (rawLen - lead < seconds - 0.05) {
    throw new Error(`${scene.file} is ${rawLen.toFixed(2)}s and the page held ${seconds.toFixed(2)}s`
      + ` — there is nothing to cut to`);
  }
  execFileSync(FFMPEG, ["-v", "error", "-ss", String(lead), "-i", raw, "-t", seconds.toFixed(3),
    "-vf", "scale=in_range=full:out_range=tv,format=yuv420p",
    "-c:v", "libx264", "-profile:v", "high", "-level", "4.0", "-crf", "20", "-preset", "slow",
    "-color_range", "tv", "-colorspace", "bt709", "-color_primaries", "bt709", "-color_trc", "bt709",
    segmentFile, "-y"]);
  const cut = probe(segmentFile);
  if (Math.abs(cut - seconds) > 0.2) {
    throw new Error(`${scene.file} cut to ${cut.toFixed(2)}s, not the ${seconds.toFixed(2)}s the `
      + `page held`);
  }
  const white = whiteFrames(segmentFile);
  if (white.length) {
    throw new Error(`${scene.file} has ${white.length} white frame(s) at `
      + `${white.map((w) => w.toFixed(2)).join(", ")}s. The film's background is luminance 12; `
      + `these are 255, and they flash at the cut. ${lead ? "The lead frame was already dropped."
        : "The lead frame was not white, so this is not the capture's first frame."}`);
  }
  process.stderr.write(`  ✓ ${scene.file}  ${cut.toFixed(2)}s${lead ? "  (dropped a white lead frame)" : ""}\n`);
  durations.push({ seconds, probed: cut });
}
await browser.close();

const concat = path.join(renderDir, "concat.txt");
writeFileSync(concat, scenes.map((s) => `file '${path.join(renderDir, s.file)}'`).join("\n") + "\n");
process.stderr.write("• assembling verified scenes …\n");
mkdirSync(path.dirname(stagedFile), { recursive: true });
execFileSync(FFMPEG, [
  "-v", "error", "-f", "concat", "-safe", "0", "-i", concat,
  "-vf", "scale=in_range=full:out_range=tv,format=yuv420p",
  "-c:v", "libx264", "-profile:v", "high", "-level", "4.0", "-crf", "20", "-preset", "slow",
  "-color_range", "tv", "-colorspace", "bt709", "-color_primaries", "bt709", "-color_trc", "bt709",
  "-movflags", "+faststart", stagedFile, "-y",
]);

// EVERY CHECK BELOW RUNS ON THE STAGED FILE. The version this replaces promoted the .mp4 first and
// checked afterwards, so a render that failed its own guards still left a finished-looking film on
// disk with the right name — which is how a file nobody could reproduce ended up being the one the
// founder had. Nothing is moved into place until all of this passes.
const seconds = durations.reduce((sum, item) => sum + item.seconds, 0);
const probed = probe(stagedFile);
const asked = HOLD.reduce((a, b) => a + b, 0);
if (Math.abs(probed - asked) > 0.5) {
  throw new Error(`refusing to promote — the assembly is ${probed.toFixed(2)}s and the script asks `
    + `for ${asked}s. The clips are cut to the page's own clock, so a gap here means the concat `
    + `added or lost something.`);
}
// And once more on the whole film, because the flashes were at the JOINS and a per-clip check
// cannot see a join. This is the check that would have caught the seven frames that shipped.
const whiteInFilm = whiteFrames(stagedFile);
if (whiteInFilm.length) {
  throw new Error(`refusing to promote — ${whiteInFilm.length} white frame(s) at `
    + `${whiteInFilm.map((w) => w.toFixed(2)).join(", ")}s. Against a background of luminance 12 `
    + `these flash at the cut, and no container-level probe can see them.`);
}
// WHERE DID THAT NUMBER COME FROM? Each figure the page drew, against everything this render
// actually read: the stdout of the commands above, and the files those commands are checked against.
// A figure that appears in none of them was typed by somebody, and on screen it is indistinguishable
// from a measurement. `1,000,000 shares` and `950,000 shares` shipped this way.
const CORPUS = [mints, balance, usage, swaps, dvp, issued, feeSwap, cash, testbed, SEC,
  readFileSync(path.join(repo, "web/usage.json"), "utf8"),
  readFileSync(path.join(repo, "web/swaps.json"), "utf8"),
  readFileSync(path.join(repo, "web/dvp.json"), "utf8"),
  MINT_COUNT, ACCOUNTS, String(CONFIGURED), String(APPROVED), ISSUANCE.size,
  DVP.delivered_units.toLocaleString("en-US"), DVP.paid_units.toLocaleString("en-US"),
].join("\n");
const unsourced = figures.filter((f) => !CORPUS.includes(f.n));
if (unsourced.length) {
  const by = [...new Set(unsourced.map((f) => `${f.n} (scene "${f.scene}")`))];
  throw new Error(
    `refusing to promote — a figure on screen is in nothing this render read:\n    ` +
    by.join("\n    ") +
    `\n  On screen it sits in the same type as the measured numbers and a judge cannot tell them ` +
    `apart. Either read it from a command, or draw the claim without a number.`,
  );
}

// The wordmark is fixed and the stage is centred, so a pane that grew since the last render puts
// two strings of text in the same pixels and nothing in the browser objects. The page measures it.
if (overlaps.length) {
  throw new Error(
    `refusing to write a manifest — a scene has grown up underneath the wordmark:\n    ` +
    overlaps.join("\n    ") +
    `\n  The pane is longer than it was. Shorten the slice, or move the mark.`,
  );
}

const drift = Math.abs(probed - seconds);
process.stderr.write(`• page clock ${seconds.toFixed(1)}s, file ${probed.toFixed(1)}s\n`);
if (drift > 2) {
  throw new Error(
    `refusing to write a manifest — the file is ${probed.toFixed(1)}s and the page took ` +
    `${seconds.toFixed(1)}s. The recorder could not keep up, so every cut would land in the ` +
    `wrong scene. Close what else is running and record again.`,
  );
}
// Where the scenes actually landed, built from every independently verified clip.
let offset = 0;
const manifest = scenes.map((sc, i) => {
  const start = offset;
  offset += durations[i].probed;
  return ({
  file: sc.file,
  start: +start.toFixed(2),
  end: +offset.toFixed(2),
  seconds: +durations[i].probed.toFixed(2),
  line: sc.line,
  });
});
execFileSync("mv", [stagedFile, outFile]);
mkdirSync(segDir, { recursive: true });
writeFileSync(path.join(segDir, "manifest.json"), JSON.stringify(manifest, null, 1) + "\n");

process.stderr.write(`\n✓ ${outFile}  (${probed.toFixed(1)}s)\n`);
process.stderr.write(`  the script asks for ${asked}s; the assembly is ${probed.toFixed(2)}s\n`);
for (const m of manifest) process.stderr.write(`   ${m.file}  ${m.seconds}s\n`);
