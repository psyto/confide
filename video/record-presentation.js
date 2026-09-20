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
const feeSwap = run("bash", ["scripts/swap-status.sh", "fee"], "reading the with-fee swap back off devnet", DEVNET);
const cash = run("bash", ["scripts/cash-scan.sh"], "reading the stablecoins on mainnet", MAINNET);
const testbed = run("bash", ["scripts/testbed-up.sh", "--check"], "checking the standing devnet issuer", DEVNET);

// ── guards ───────────────────────────────────────────────────────────────────────────────────────
for (const [text, re, why] of [
  [mints, /NVDAx.*Token-2022.*None/, "NVDAx no longer reads as Token-2022 with an empty auditor slot"],
  [mints, /NVDA\.US.*Token-2022.*None/, "Backpack's NVDA.US no longer reads the same way"],
  [balance, /public balance\s+0/, "the account's public balance is no longer zero"],
  [balance, /173000 units/, "the confidential balance did not open to the expected position"],
  // Scene 4 is the whole reveal, and it says zero. If anybody has opened a confidential account
  // since the scan, the scene is wrong and the right response is to rescan, not to record.
  [usage, /329,536 token accounts, .*0.* configured for confidential/, "the account scan no longer reads 329,536 / zero — rerun ./scripts/usage-scan.sh"],
  [swaps, /confidentialTransfer, confidentialTransfer/, "the plain swap no longer carries two confidential transfers"],
  [swaps, /public balance 0 on every one/, "a swap account's public balance is no longer zero"],
  [feeSwap, /confidentialTransfer, confidentialTransferWithFee/, "the with-fee swap no longer carries both instruction kinds — scene 7 is about exactly that"],
  [feeSwap, /every swap still reads as recorded/, "the with-fee swap did not read back clean"],
  [cash, /PYUSD.*Token-2022/, "PYUSD is no longer Token-2022"],
  [cash, /USDC.*Token \(legacy\)/, "USDC is no longer legacy SPL — scene 8 contrasts them"],
  [cash, /the same key holds the confidential authority on both/, "PYUSD and USDG no longer share one authority, and scene 8 says they do"],
  [testbed, /the testbed is as published/, "the standing devnet issuer has been changed — scene 9 points people at it"],
]) {
  if (!re.test(plain(text))) throw new Error(`refusing to record — ${why}`);
}

// ── the cut ──────────────────────────────────────────────────────────────────────────────────────
// One entry per scene of CWF-PRESENTATION.md, in its order, with its hold. `line` is the narration,
// carried into the manifest so LINES.md can pair each clip with what goes on it.
const script = [...md.matchAll(/^### (\d+) — ([^·\n]+?)\s*(?:·[^\n]*)?$\n\n((?:^> ?.*\n)+)/gm)]
  .map((m) => m[3].replace(/^> ?/gm, "").trim().replace(/\n+/g, " "));
if (script.length !== 10) throw new Error(`CWF-PRESENTATION.md: expected 10 scripted scenes, found ${script.length}`);

// The mint count and issuer count are read at render time, not written into the page. The slot
// scene said "All 1,869" and "Two, independently" as literals until 2026-09-19, when a third
// issuer appeared and neither the page nor any test noticed.
const MINTS = JSON.parse(readFileSync(path.join(repo, "web/mints.json"), "utf8"));
const MINT_COUNT = MINTS.length.toLocaleString("en-US");
const ISSUERS = new Set(MINTS.map((m) => m.issuer)).size;

const scenes = [
  // The card. Added after the founder said the entry was abrupt against the published cut, which
  // spends nine seconds here before it shows anything — and the nine seconds buy the claim landing
  // before the picture that illustrates it. The screen carries the numbers; the voice does not
  // read them.
  {
    file: "01-the-claim.mp4", kind: "hero",
    sub: "settle a position without publishing what moved",
    lede: "Nearly two thousand tokenized stocks can hide a balance.<br><b>Zero accounts do.</b>",
    total: HOLD[0],
  },
  { file: "02-your-position.mp4", kind: "leak", total: HOLD[1] },
  {
    file: "03-this-account.mp4", kind: "evidence",
    label: "A real account on Solana, right now.",
    body: slice(balance, /public balance/, /public balance/),
    emphasis: ["0"],
    then: {
      at: 6,
      body: slice(balance, /confidential\s+\d/, /confidential\s+\d/),
      emphasis: ["173000 units"],
      label: "The same account. This is what it holds.",
    },
    total: HOLD[2],
  },
  { file: "04-already-shipped.mp4", kind: "slot", mints: MINT_COUNT, issuers: ISSUERS, total: HOLD[3] },
  {
    file: "05-so-i-counted.mp4", kind: "evidence",
    label: "So I stopped reading the settings and counted the accounts.",
    // Not "just now", and the badge says so. Every other pane in this cut is a command run
    // moments before the recording; this scan reads every token account of every mint and takes
    // minutes, so it is the stored measurement and the screen carries its date.
    stamp: "measured " + JSON.parse(readFileSync(path.join(repo, "web/usage.json"), "utf8")).generated_utc,
    body: slice(usage, /AAPLx/, /token accounts,/),
    emphasis: ["329,536", "0 configured for confidential transfers"],
    total: HOLD[4],
  },
  {
    file: "06-the-turn.mp4", kind: "missing",
    label: "Which told me I had been building the wrong shape.",
    items: [
      "A <b>loan</b> needs somebody to hold the collateral, because it has to survive one side refusing to cooperate for months.",
      "A <b>trade</b> does not. It happens at one instant.",
      "And on Solana, an instant is all or nothing — so the transaction <b>is</b> the escrow.",
    ],
    lead: 3.5, step: 5,
    total: HOLD[5],
  },
  {
    file: "07-what-runs.mp4", kind: "evidence",
    label: "Fifty thousand shares, for eight and three quarter million dollars.",
    body: slice(swaps, /stock for cash/, /the 4 accounts/),
    emphasis: ["confidentialTransfer, confidentialTransfer", "public balance 0 on every one"],
    total: HOLD[6],
  },
  {
    file: "08-the-hard-part.mp4", kind: "evidence",
    label: "The cash is shaped like PayPal's dollar, and PayPal's dollar charges a fee.",
    body: slice(feeSwap, /stock for cash, on a mint/, /the 4 accounts/),
    emphasis: ["confidentialTransferWithFee"],
    total: HOLD[7],
  },
  {
    file: "09-not-only-equities.mp4", kind: "evidence",
    label: "And it was never a story about tokenized stocks.",
    body: slice(cash, /program\s+confidential/, /Four issuers/),
    emphasis: ["PYUSD", "USDG", "EMPTY"],
    total: HOLD[8],
  },
  {
    file: "10-what-is-missing.mp4", kind: "runnable",
    label: "Nobody outside this repository has used any of it. What is left is not unknown.",
    command: "./scripts/testbed-join.sh",
    body: slice(testbed, /THE STANDING TESTBED/, /the testbed is as published/),
    emphasis: ["autoApproveNewAccounts is still false", "the testbed is as published"],
    url: "github.com/psyto/confide",
    note: "The gate is shut, as it is on all " + MINT_COUNT + ". The key that opens it is published.",
    total: HOLD[9],
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
