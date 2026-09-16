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
  return execFileSync(cmd, args, {
    cwd: repo, encoding: "utf8", maxBuffer: 8 * 1024 * 1024,
    env: { ...process.env, FORCE_COLOR: "0" },
  }).replace(/\s+$/, "");
}
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// ── the real runs ────────────────────────────────────────────────────────────────────────────────
const reserves = run("bash", ["scripts/kamino-reserves.sh"], "reading every Kamino reserve on mainnet");
const table = (() => {
  const lines = reserves.split("\n");
  const a = lines.findIndex((l) => /SYMBOL\s+ISSUER/.test(l));
  if (a < 0) throw new Error("kamino-reserves.sh printed no table — the finding changed");
  return lines.slice(a, a + 20).join("\n");   // header + 19 reserves
})();
const cap = JSON.parse(readFileSync(path.join(repo, "web/capacity.json"), "utf8"));
const usd = (n) => "$" + (n / 1e6).toFixed(1) + "m";

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
await page.goto(`http://127.0.0.1:${PORT}/kamino.html`, { waitUntil: "networkidle2" });
// Start on the picker so the first frame is the thing being used, not the page's masthead.
await page.evaluate(() => document.getElementById("q").scrollIntoView({ block: "center" }));

const recorder = new PuppeteerScreenRecorder(page, {
  fps: 30, videoFrame: { width: 1920, height: 1080 }, aspectRatio: "16:9", ffmpeg_Path: FFMPEG,
});
const marks = [];
await recorder.start(outFile);
const t0 = Date.now();
const mark = () => marks.push((Date.now() - t0) / 1000);

// ── scene 1 — the page, operated ─────────────────────────────────────────────────────────────────
mark();
await sleep(1500);
await page.click("#q", { clickCount: 3 });
await page.type("#q", "NVDAx", { delay: 190 });
// The verdict arrives from mainnet. Waiting for it is the point: a screenshot would prove nothing.
await page.waitForFunction(
  () => /NVDAx/.test(document.querySelector("#out")?.textContent || "") &&
        /REQUIRES INTEGRATION|INADMISSIBLE|NOT THIS PROBLEM/.test(document.querySelector("#out").textContent),
  { timeout: 30000 },
);
process.stderr.write("• the page answered from mainnet\n");
await page.evaluate(() => document.querySelector("#out").scrollIntoView({ block: "start", behavior: "smooth" }));
await sleep(5200);
// Then down to the part a holder is actually deciding on: the reserve that already exists, its
// LTV and its cap. The extension dump above it is there to be paused on, not held on.
await page.evaluate(() => {
  const h = [...document.querySelectorAll("#out h3")].find((e) => /already has a reserve/.test(e.textContent));
  (h || document.querySelector("#out")).scrollIntoView({ block: "center", behavior: "smooth" });
});
await sleep(Math.max(0, HOLD[0] * 1000 - (Date.now() - t0)));

// ── scenes 2 and 3 — authored, over real output ──────────────────────────────────────────────────
await page.goto("file://" + path.join(dir, "checkin.html"), { waitUntil: "load" });
await page.evaluate((d) => window.__data(d), {
  table, held: usd(cap.held_usd), cap: usd(cap.authorised_capacity_usd),
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
