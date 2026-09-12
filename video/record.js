// Records mora.mp4.
//
// The terminal in this video is not a transcription. Every pane is the stdout of a command run
// moments before the recording starts, and if a command does not produce the line it is supposed
// to, this refuses to record rather than shipping a video that claims something the code did not
// do. The devnet panes really do hit devnet.
import path from "node:path";
import { fileURLToPath } from "node:url";
import { execFileSync } from "node:child_process";
import puppeteer from "puppeteer";
import { PuppeteerScreenRecorder } from "puppeteer-screen-recorder";

const dir = path.dirname(fileURLToPath(import.meta.url));
const repo = path.join(dir, "..");
const outFile = path.join(dir, "mora.mp4");

function run(cmd, args, label) {
  process.stderr.write(`• ${label} …\n`);
  return execFileSync(cmd, args, {
    cwd: repo,
    encoding: "utf8",
    maxBuffer: 8 * 1024 * 1024,
    env: { ...process.env, FORCE_COLOR: "1" },
  }).replace(/\s+$/, "");
}

/** Lines from the first line matching `from` through the first later line matching `to`. */
function slice(text, from, to) {
  const lines = text.split("\n");
  const a = lines.findIndex((l) => from.test(l));
  if (a < 0) throw new Error(`slice: no line matched ${from}`);
  const b = lines.slice(a).findIndex((l) => to.test(l));
  if (b < 0) throw new Error(`slice: no line matched ${to} after ${from}`);
  return lines.slice(a, a + b + 1).join("\n").replace(/^\s*\n/, "").replace(/\n\s*$/, "");
}

// ── the real runs ────────────────────────────────────────────────────────────────────────────────
const twoLane = run("cargo", ["run", "-q", "-p", "mora-demo", "--bin", "two-lane"], "two lanes");
const mints = run("bash", ["scripts/onchain-check.sh"], "reading the xStock mints on mainnet");
const zk = run("bash", ["scripts/devnet-verify.sh"], "submitting the proof to devnet");

// ── guards: refuse to record a misleading video ──────────────────────────────────────────────────
const must = [
  [twoLane, /LANE A/, "two-lane is missing the comparison table"],
  [twoLane, /REFUSED/, "two-lane did not catch the post-hoc swap"],
  [twoLane, /LANE B is now public/, "two-lane never opened the obligation"],
  [twoLane, /173,000 NVDAx/, "two-lane did not print the position"],
  [mints, /NVDAx.*Token-2022.*None/, "NVDAx no longer reads as Token-2022 with an empty auditor slot"],
  [mints, /AAPLx.*None/, "the mint sweep is incomplete"],
  [zk, /err\s*:\s*None/, "the devnet proof submission did not come back clean"],
  [zk, /VerifyBatchedRangeProofU64/, "the ZK program did not run the range proof"],
  [zk, /success/, "the ZK program did not report success"],
];
for (const [text, re, why] of must) {
  if (!re.test(text)) throw new Error(`refusing to record — ${why}`);
}
const auditorSlots = (mints.match(/None\s*$/gm) || []).length;
if (auditorSlots < 4) throw new Error(`refusing to record — expected 4 empty auditor slots, saw ${auditorSlots}`);

// ── the cut ──────────────────────────────────────────────────────────────────────────────────────
const scenes = [
  { kind: "title", hold: 7 },
  {
    kind: "pane",
    label: "Fund A accumulates NVDAx over one quarter. Same buys, two lanes.",
    body: slice(twoLane, /day\s+LANE A/, /The chain simply published it\./),
    hold: 15,
  },
  {
    kind: "pane",
    label: "Quarter end. The position of record is sealed and anchored.",
    body: slice(twoLane, /30 Sep · quarter end/, /cannot revise what is inside it\./),
    hold: 11,
  },
  {
    kind: "pane",
    label: "Six weeks later, the fund would like to have held less.",
    body: slice(twoLane, /2 Nov · the fund has second thoughts/, /REFUSED/),
    emphasis: ["REFUSED"],
    hold: 10,
  },
  {
    kind: "pane",
    label: "The deadline. The fund is not asked.",
    body: slice(twoLane, /14 Nov · the obligation comes due/, /LANE B is now public/),
    emphasis: ["173,000 NVDAx"],
    hold: 12,
  },
  {
    kind: "pane",
    label: "Why this is a Solana problem: every xStock has the feature on and no way to use it.",
    body: mints,
    emphasis: ["None"],
    hold: 12,
  },
  {
    kind: "pane",
    label: "And the covenant the LP checked, verified by Solana's live ZK program.",
    body: zk,
    emphasis: ["err   : None", "success"],
    hold: 11,
  },
  { kind: "close", hold: 8 },
];

// ── record ───────────────────────────────────────────────────────────────────────────────────────
const browser = await puppeteer.launch({
  headless: "new",
  defaultViewport: { width: 1280, height: 720, deviceScaleFactor: 1 },
  args: ["--no-sandbox", "--hide-scrollbars", "--window-size=1280,720", "--force-device-scale-factor=1"],
});
const page = await browser.newPage();
page.on("console", (m) => {
  if (m.text().startsWith("MORA_")) process.stderr.write(`• page: ${m.text()}\n`);
});
await page.goto("file://" + path.join(dir, "demo.html"), { waitUntil: "load" });
await page.evaluate((s) => window.__load(s), scenes);

const recorder = new PuppeteerScreenRecorder(page, {
  fps: 30,
  videoFrame: { width: 1280, height: 720 },
  aspectRatio: "16:9",
  ffmpeg_Path: process.env.FFMPEG_PATH || "/opt/homebrew/bin/ffmpeg",
});
await recorder.start(outFile);
const seconds = await page.evaluate(() => window.__play());
await recorder.stop();
await browser.close();
process.stderr.write(`\n✓ ${outFile}  (${seconds.toFixed(1)}s)\n`);
