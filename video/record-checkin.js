// Records checkin-1.mp4 — the weekly one-minute update, three scenes, silent.
//
// Scene 1 is the published page actually being operated, not a picture of it: the recorder drives
// the same URL a judge would open, types a symbol, and waits for the verdict to arrive from
// mainnet. If the page does not answer, this throws rather than recording a still of a page that
// no longer works.
//
// Scenes 2 and 3 are authored, and scene 2's table is the stdout of ./scripts/kamino-reserves.sh
// run moments earlier — the same discipline record.js uses.
//
//   node video/record-checkin.js
//
// Durations come from video/CHECKIN-1.md, whose table pace.py derives from the narration.
import path from "node:path";
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { execFileSync, spawn } from "node:child_process";
import puppeteer from "puppeteer";
import { PuppeteerScreenRecorder } from "puppeteer-screen-recorder";

const dir = path.dirname(fileURLToPath(import.meta.url));
const repo = path.join(dir, "..");
const outFile = path.join(dir, "checkin-1.mp4");
const FFMPEG = process.env.FFMPEG_PATH || "/opt/homebrew/bin/ffmpeg";
const PORT = 8791;

// Seconds per scene, read out of the script rather than repeated here — the one place they are
// decided is the narration, and pace.py derives them from its word counts.
const md = readFileSync(path.join(dir, "CHECKIN-1.md"), "utf8");
const rows = [...md.matchAll(/^\| (\d) \| [^|]+\| ([\d]+)(?: \+ ([\d.]+))? \|/gm)];
if (rows.length !== 3) throw new Error(`CHECKIN-1.md: expected 3 timing rows, found ${rows.length}`);
const HOLD = rows.map((m) => parseInt(m[2], 10) + (m[3] ? parseFloat(m[3]) : 0));
process.stderr.write(`• scene holds from CHECKIN-1.md: ${HOLD.join(" / ")} s\n`);

function run(cmd, args, label) {
  process.stderr.write(`• ${label} …\n`);
  // FORCE_COLOR is not enough: these scripts write the escapes themselves rather than going
  // through a library that honours it, so the first render put "[32m0 [0m confidential" on screen
  // where the finding's zero should have been. Strip them here, where the text is captured.
  return execFileSync(cmd, args, {
    cwd: repo, encoding: "utf8", maxBuffer: 8 * 1024 * 1024,
    env: { ...process.env, FORCE_COLOR: "0", NO_COLOR: "1", TERM: "dumb" },
  }).replace(/\u001b\[[0-9;]*m/g, "").replace(/\s+$/, "");
}
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// ── the real runs ────────────────────────────────────────────────────────────────────────────────
// Scene 2's evidence is the ACCOUNT scan, not the reserve table: the week's finding is that
// nobody has been through the gate. --last reprints the stored result rather than re-scanning a
// third of a million accounts, which takes minutes and would be re-run on every take.
const scan = run("bash", ["scripts/usage-scan.sh", "--last"], "reprinting the account scan");
const table = (() => {
  const lines = scan.split("\n").filter((l) => l.trim() !== "");
  const a = lines.findIndex((l) => /IS ANYBODY THROUGH THE GATE/.test(l));
  if (a < 0) throw new Error("usage-scan.sh --last printed no header — the finding changed");
  return lines.slice(a + 1).join("\n");
})();
const usage = JSON.parse(readFileSync(path.join(repo, "web/usage.json"), "utf8"));
const mints = JSON.parse(readFileSync(path.join(repo, "web/mints.json"), "utf8"));
if (usage.total_confidential_accounts !== 0)
  throw new Error("a confidential account now exists — the narration says zero");

// ── serve web/ so scene 1 drives the same files the site publishes ───────────────────────────────
const server = spawn("python3", ["-m", "http.server", String(PORT)], {
  cwd: path.join(repo, "web"), stdio: "ignore",
});
const stop = () => { try { server.kill(); } catch {} };
process.on("exit", stop);
await sleep(900);

const browser = await puppeteer.launch({
  headless: "new",
  defaultViewport: { width: 1280, height: 720, deviceScaleFactor: 1.5 },
  args: ["--no-sandbox", "--hide-scrollbars", "--window-size=1280,720", "--force-device-scale-factor=1.5"],
});
const page = await browser.newPage();
await page.goto(`http://127.0.0.1:${PORT}/index.html`, { waitUntil: "networkidle2" });
await page.evaluate(() => document.getElementById("swaps").scrollIntoView({ block: "center" }));

const recorder = new PuppeteerScreenRecorder(page, {
  fps: 30, videoFrame: { width: 1920, height: 1080 }, aspectRatio: "16:9", ffmpeg_Path: FFMPEG,
});
const marks = [];
await recorder.start(outFile);
const t0 = Date.now();
const mark = () => marks.push((Date.now() - t0) / 1000);

// ── scene 1 — the swap, decoded from devnet by the page itself ───────────────────────────────────
// The browser fetches the transaction and reads the four balances. Waiting for that is the point:
// a still of the panel would prove the page renders, not that the trade is on chain and the
// accounts read zero. If devnet does not answer, this throws rather than recording a spinner.
mark();
await page.waitForFunction(
  () => {
    const s = document.getElementById("swaps")?.textContent || "";
    return /public balance/.test(s) && /0 on every one/.test(s) && !/reading devnet/.test(s);
  },
  { timeout: 45000 },
);
process.stderr.write("• the page decoded the swaps from devnet\n");
await page.evaluate(() => document.getElementById("swaps").scrollIntoView({ block: "center", behavior: "smooth" }));
await sleep(Math.max(0, HOLD[0] * 1000 - (Date.now() - t0)));

// ── scenes 2 and 3 — authored, over real output ──────────────────────────────────────────────────
await page.goto("file://" + path.join(dir, "checkin.html"), { waitUntil: "load" });
await page.evaluate((d) => window.__data(d), {
  table,
  accounts: usage.total_accounts.toLocaleString("en-US"),
  mints: mints.length.toLocaleString("en-US"),
});
mark();
await page.evaluate((s) => window.__scene2(s), HOLD[1]);
mark();
await page.evaluate((s) => window.__scene3(s), HOLD[2]);
mark();

await recorder.stop();
await browser.close();
stop();

process.stderr.write("• re-encoding for the web …\n");
execFileSync(FFMPEG, [
  "-v", "error", "-i", outFile,
  "-vf", "scale=in_range=full:out_range=tv,format=yuv420p",
  "-c:v", "libx264", "-profile:v", "high", "-level", "4.0", "-crf", "20", "-preset", "slow",
  "-color_range", "tv", "-colorspace", "bt709", "-color_primaries", "bt709", "-color_trc", "bt709",
  "-movflags", "+faststart", outFile + ".tmp.mp4", "-y",
]);
execFileSync("mv", [outFile + ".tmp.mp4", outFile]);

// Where the scenes actually landed, not where they were asked to. split.sh reads this.
const files = ["01-what-changed.mp4", "02-what-i-learned.mp4", "03-what-is-next.mp4"];
const manifest = files.map((file, i) => ({
  file, start: +marks[i].toFixed(2), end: +marks[i + 1].toFixed(2),
  seconds: +(marks[i + 1] - marks[i]).toFixed(2),
}));
// Next to the clips, named the way split.sh expects, so one splitter serves both cuts.
const segDir = path.join(dir, "segments-checkin");
mkdirSync(segDir, { recursive: true });
writeFileSync(path.join(segDir, "manifest.json"), JSON.stringify(manifest, null, 1) + "\n");
process.stderr.write(`\n✓ ${outFile}  (${marks[3].toFixed(1)}s)\n`);
for (const m of manifest) process.stderr.write(`   ${m.file}  ${m.seconds}s\n`);
