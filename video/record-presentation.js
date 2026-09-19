// Records presentation.mp4 — the CWF submission presentation, eight scenes, silent.
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
// Every terminal pane is the stdout of a command run moments before the recording starts, four of
// them reaching mainnet or devnet, and each is guarded on the line that carries its claim. A video
// that still renders after the thing it demonstrates stopped working is the failure worth
// engineering against — which is not hypothetical here: scene 5's claim is a quotation from
// someone else's repository, and they can change it without telling us.
import path from "node:path";
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { execFileSync } from "node:child_process";
import puppeteer from "puppeteer";
import { PuppeteerScreenRecorder } from "puppeteer-screen-recorder";

const dir = path.dirname(fileURLToPath(import.meta.url));
const repo = path.join(dir, "..");
const outFile = path.join(dir, "presentation.mp4");
const segDir = path.join(dir, "segments-presentation");
const FFMPEG = process.env.FFMPEG_PATH || "/opt/homebrew/bin/ffmpeg";
const KEYS = process.env.CONFIDE_KEYS || path.join(repo, "account-keys.json");
const ACCOUNT = process.env.CONFIDE_ACCOUNT || JSON.parse(readFileSync(KEYS, "utf8")).account;

// ── the holds, from the script ───────────────────────────────────────────────────────────────────
const md = readFileSync(path.join(dir, "CWF-PRESENTATION.md"), "utf8");
const rows = [...md.matchAll(/^\| (\d) \| [^|]+\| ([\d]+)(?: \+ ([\d.]+))? \|/gm)];
if (rows.length !== 8) throw new Error(`CWF-PRESENTATION.md: expected 8 timing rows, found ${rows.length}`);
const HOLD = rows.map((m) => parseInt(m[2], 10) + (m[3] ? parseFloat(m[3]) : 0));
process.stderr.write(`• scene holds from CWF-PRESENTATION.md: ${HOLD.join(" / ")} s\n`);

function run(cmd, args, label) {
  process.stderr.write(`• ${label} …\n`);
  return execFileSync(cmd, args, {
    cwd: repo, encoding: "utf8", maxBuffer: 8 * 1024 * 1024,
    env: { ...process.env, FORCE_COLOR: "1" },
  }).replace(/\s+$/, "");
}
const plain = (t) => t.replace(/\x1b\[[0-9;]*m/g, "");
function slice(text, from, to) {
  const lines = text.split("\n");
  const a = lines.findIndex((l) => from.test(plain(l)));
  if (a < 0) throw new Error(`slice: no line matched ${from}`);
  const b = lines.slice(a).findIndex((l) => to.test(plain(l)));
  if (b < 0) throw new Error(`slice: no line matched ${to} after ${from}`);
  return lines.slice(a, a + b + 1).join("\n").replace(/^\s*\n/, "").replace(/\n\s*$/, "");
}

// ── the real runs ────────────────────────────────────────────────────────────────────────────────
const mints = run("bash", ["scripts/onchain-check.sh"], "reading the xStock mints on mainnet");
const balance = run("bash", ["scripts/read-balance.sh", ACCOUNT, KEYS], "opening our own confidential balance");
const reserves = run("bash", ["scripts/kamino-reserves.sh"], "reading every Kamino reserve on mainnet");
// Reads someone else's source at a pinned commit and fails if any pinned line has moved. Scene 5
// is a quotation; this is what keeps it one.
const verdict = run("bash", ["scripts/kamino-verdict.sh"], "re-reading Kamino's pinned constraint lines");
const collateral = run("bash", ["scripts/prove-collateral.sh", ACCOUNT, "100000", KEYS], "proving the account clears a threshold, on devnet");
const seizure = run("bash", ["scripts/seizure-status.sh"], "reading the seizure back off devnet");
const packet = run("bash", ["scripts/packet.sh", "NVDAx"], "building the admission packet for the control asset");

// ── guards ───────────────────────────────────────────────────────────────────────────────────────
for (const [text, re, why] of [
  [mints, /NVDAx.*Token-2022.*None/, "NVDAx no longer reads as Token-2022 with an empty auditor slot"],
  [mints, /NVDA\.US.*Token-2022.*None/, "Backpack's NVDA.US no longer reads the same way"],
  [balance, /public balance\s+0/, "the account's public balance is no longer zero"],
  [balance, /173000 units/, "the confidential balance did not open to the expected position"],
  [reserves, /19 of them are tokenized stocks/, "Kamino no longer has 19 tokenized-stock reserves — scene 4 says 19"],
  [reserves, /SPCX\.US/, "SPCX.US has left the reserve list"],
  [verdict, /allow_confidential_credits/, "the line that refuses a confidential-credit account has moved"],
  [verdict, /check_only_supported_liquidity_token_extensions/, "the deposit-path check has moved"],
  [verdict, /user_source_liquidity/, "the check no longer reads the depositor's own account — the finding has changed"],
  [collateral, /VerifyCiphertextCommitmentEquality/, "the equality proof never ran"],
  [collateral, /VerifyBatchedRangeProofU64/, "the range proof never ran"],
  [collateral, /both accepted/, "the chain did not accept both proofs"],
  [seizure, /seized: yes/, "the loan on devnet no longer reads as seized"],
  [seizure, /still read zero/, "the seizure pane stopped saying both accounts read zero"],
  [packet, /wrote docs\/packets\/NVDAx\.md/, "the packet was not written"],
]) {
  if (!re.test(plain(text))) throw new Error(`refusing to record — ${why}`);
}
if ((plain(collateral).match(/err\s*:\s*None/g) || []).length < 2) {
  throw new Error("refusing to record — a proof came back with an error");
}
// Scene 5 concedes that Kamino is right, and that concession is only worth anything while every
// pinned line still reads the way the verdict says. kamino-verdict.sh exits non-zero if one moved,
// so reaching here means all of them held — but say so out loud rather than trusting the exit code
// silently, because a script that stops printing ✗ is indistinguishable from one that passes.
if (plain(verdict).includes("✗")) throw new Error("refusing to record — a pinned Kamino line has moved");

const cap = JSON.parse(readFileSync(path.join(repo, "web/capacity.json"), "utf8"));
const usd = (n) => "$" + (n / 1e6).toFixed(1) + "m";

// The reserve table, header plus its 19 rows. Counted rather than taken to the end of the block:
// an earlier take of the check-in clipped the last three, which were the Backpack ones the
// argument is partly about.
const table = (() => {
  const lines = reserves.split("\n");
  const a = lines.findIndex((l) => /SYMBOL\s+ISSUER/.test(plain(l)));
  if (a < 0) throw new Error("kamino-reserves.sh printed no table — the finding changed");
  const rows = lines.slice(a + 1, a + 20);
  if (rows.some((l) => !/^\s{4}\S/.test(plain(l)))) throw new Error("the reserve table is shorter than 19 rows");
  return [lines[a], ...rows].join("\n");
})();

// ── the cut ──────────────────────────────────────────────────────────────────────────────────────
// One entry per scene of CWF-PRESENTATION.md, in its order, with its hold. `line` is the narration,
// carried into the manifest so LINES.md can pair each clip with what goes on it.
const script = [...md.matchAll(/^### (\d+) — ([^·\n]+?)\s*(?:·[^\n]*)?$\n\n((?:^> ?.*\n)+)/gm)]
  .map((m) => m[3].replace(/^> ?/gm, "").trim().replace(/\n+/g, " "));
if (script.length !== 8) throw new Error(`CWF-PRESENTATION.md: expected 8 scripted scenes, found ${script.length}`);

// The mint count and issuer count are read at render time, not written into the page. The slot
// scene said "All 1,869" and "Two, independently" as literals until 2026-09-19, when a third
// issuer appeared and neither the page nor any test noticed.
const MINTS = JSON.parse(readFileSync(path.join(repo, "web/mints.json"), "utf8"));
const MINT_COUNT = MINTS.length.toLocaleString("en-US");
const ISSUERS = new Set(MINTS.map((m) => m.issuer)).size;

const scenes = [
  { file: "01-your-position.mp4", kind: "leak", total: HOLD[0] },
  {
    file: "02-this-account.mp4", kind: "evidence",
    label: "A real account on Solana. Read just now.",
    body: slice(balance, /account\s+/, /public balance/),
    emphasis: ["public balance     0"],
    // The whole scene is the gap. The public balance sits alone for five seconds, and the
    // confidential line arrives into the same frame rather than onto a new one.
    then: { at: 6.5, body: slice(balance, /account\s+/, /173000 units/),
            emphasis: ["public balance     0", "173000 units"] },
    total: HOLD[1],
  },
  { file: "03-already-shipped.mp4", kind: "slot", mints: MINT_COUNT, issuers: ISSUERS, total: HOLD[2] },
  {
    file: "04-whose-money.mp4", kind: "reserves",
    label: "Kamino, read just now.",
    body: table,
    figures: [
      [usd(cap.held_usd), "of tokenized stock deposited in Kamino reserves"],
      [usd(cap.authorised_capacity_usd), "of borrowing their caps and LTVs already authorise"],
    ],
    figuresAt: 7, figuresStep: 2.4,
    total: HOLD[3],
  },
  {
    file: "05-the-refusal.mp4", kind: "evidence",
    label: "Kamino Lend, release/v1.25.0 — read at a pinned commit.",
    body: slice(verdict, /AND REQUIRES THEM TO BE INERT/, /closable\(\)\.is_err\(\)/),
    emphasis: ["allow_confidential_credits", "auto_approve_new_accounts"],
    then: {
      at: 11,
      label: "And on the depositor's own account — which is the whole finding.",
      body: slice(verdict, /ON THE DEPOSITOR'S OWN ACCOUNT/, /user_source_liquidity/),
      emphasis: ["user_source_liquidity"],
    },
    total: HOLD[4],
  },
  {
    file: "06-what-runs.mp4", kind: "evidence",
    label: "The lender's check, run by Solana's own ZK program.",
    body: slice(collateral, /ciphertext-commitment equality/, /both accepted/),
    emphasis: ["err   : None", "success", "both accepted"],
    then: {
      at: 13,
      label: "And on default, the collateral moves.",
      body: slice(seizure, /loan\s+/, /still read zero/),
      emphasis: ["seized: yes", "public balance 0"],
    },
    total: HOLD[5],
  },
  {
    file: "07-what-does-not.mp4", kind: "missing",
    label: "What is missing",
    items: [
      "A floor proved once is only true once. <em>Re-proving is not built.</em>",
      "The seizure has to happen inside Kamino's liquidation, not beside it. <em>Not built.</em>",
      "The issuer has to approve each account. <em>Nobody's decision but theirs.</em>",
    ],
    lead: 5, step: 8,
    total: HOLD[6],
  },
  {
    file: "08-what-you-can-run.mp4", kind: "runnable",
    label: "One command, live chain data, every unknown capped at zero.",
    command: "./scripts/packet.sh NVDAx",
    body: slice(packet, /wrote docs/, /LTV/),
    emphasis: ["NVDAx"],
    url: "psyto.github.io/confide/kamino.html",
    note: "Nobody outside this repository has used any of it yet. Every number above is checkable.",
    total: HOLD[7],
  },
].map((s, i) => ({ ...s, line: script[i] }));

// ── record ───────────────────────────────────────────────────────────────────────────────────────
const browser = await puppeteer.launch({
  headless: "new",
  defaultViewport: { width: 1280, height: 720, deviceScaleFactor: 1.5 },
  args: ["--no-sandbox", "--hide-scrollbars", "--window-size=1280,720", "--force-device-scale-factor=1.5"],
});
const page = await browser.newPage();
const marks = [];
page.on("console", (m) => {
  const t = m.text();
  if (!t.startsWith("CONFIDE_")) return;
  process.stderr.write(`• page: ${t}\n`);
  const scene = t.match(/^CONFIDE_SCENE \S+ ([0-9.]+)/);
  if (scene) marks.push(parseFloat(scene[1]));
  const total = t.match(/^CONFIDE_SECONDS ([0-9.]+)/);
  if (total) marks.push(parseFloat(total[1]));
});
page.on("pageerror", (e) => { throw e; });
await page.goto("file://" + path.join(dir, "demo.html"), { waitUntil: "load" });
await page.evaluate((s) => window.__load(s), scenes);

const recorder = new PuppeteerScreenRecorder(page, {
  fps: 30, videoFrame: { width: 1920, height: 1080 }, aspectRatio: "16:9", ffmpeg_Path: FFMPEG,
});
await recorder.start(outFile);
const seconds = await page.evaluate(() => window.__play());
await recorder.stop();
await browser.close();

process.stderr.write("• re-encoding for the web …\n");
execFileSync(FFMPEG, [
  "-v", "error", "-i", outFile,
  "-vf", "scale=in_range=full:out_range=tv,format=yuv420p",
  "-c:v", "libx264", "-profile:v", "high", "-level", "4.0", "-crf", "20", "-preset", "slow",
  "-color_range", "tv", "-colorspace", "bt709", "-color_primaries", "bt709", "-color_trc", "bt709",
  "-movflags", "+faststart", outFile + ".tmp.mp4", "-y",
]);
execFileSync("mv", [outFile + ".tmp.mp4", outFile]);

if (marks.length !== scenes.length + 1) {
  throw new Error(`expected ${scenes.length + 1} scene marks, got ${marks.length}`);
}
// Where the scenes actually landed, not where they were asked to. split.sh reads this.
const manifest = scenes.map((sc, i) => ({
  file: sc.file,
  start: +marks[i].toFixed(2),
  end: +marks[i + 1].toFixed(2),
  seconds: +(marks[i + 1] - marks[i]).toFixed(2),
  line: sc.line,
}));
mkdirSync(segDir, { recursive: true });
writeFileSync(path.join(segDir, "manifest.json"), JSON.stringify(manifest, null, 1) + "\n");

process.stderr.write(`\n✓ ${outFile}  (${seconds.toFixed(1)}s)\n`);
const asked = HOLD.reduce((a, b) => a + b, 0);
process.stderr.write(`  the script asks for ${asked}s; the render held ${seconds.toFixed(1)}s\n`);
for (const m of manifest) process.stderr.write(`   ${m.file}  ${m.seconds}s\n`);
