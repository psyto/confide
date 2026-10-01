// Records checkin-<n>.mp4 — the weekly one-minute update, three scenes, silent.
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
// THE SCRIPT WAS PARAMETERISED AND THE OUTPUT WAS NOT. This was `checkin-1.mp4` while DOC
// below already honoured CHECKIN_DOC, so recording check-in 2 would have overwritten the cut
// submitted in week 1 and still left `checkin-2.mp4` missing -- which is the exact pairing
// docs-consistency.sh checks. Both now come from the same number.
const NUM = (process.env.CHECKIN_DOC || "CHECKIN-1.md").match(/(\d+)/)[1];
const outFile = path.join(dir, `checkin-${NUM}.mp4`);
const FFMPEG = process.env.FFMPEG_PATH || "/opt/homebrew/bin/ffmpeg";
const PORT = 8791;

// Seconds per scene, read out of the script rather than repeated here — the one place they are
// decided is the narration, and pace.py derives them from its word counts.
// Which check-in is being recorded is passed in, not compiled in -- CHECKIN_DOC=CHECKIN-2.md.
// The default is CHECKIN-1.md so the command that produced the submitted cut still reproduces it.
const DOC = process.env.CHECKIN_DOC ? path.basename(process.env.CHECKIN_DOC) : "CHECKIN-1.md";
const md = readFileSync(path.join(dir, DOC), "utf8");
const rows = [...md.matchAll(/^\| (\d) \| [^|]+\| ([\d]+)(?: \+ ([\d.]+))? \|/gm)];
if (rows.length !== 3) throw new Error(`${DOC}: expected 3 timing rows, found ${rows.length}`);
const HOLD = rows.map((m) => parseInt(m[2], 10) + (m[3] ? parseFloat(m[3]) : 0));
process.stderr.write(`• scene holds from ${DOC}: ${HOLD.join(" / ")} s\n`);
// SCENE 1 CAN BE FOOTAGE OF THE PRODUCT instead of the page being driven live. A check-in whose
// script carries `<!-- footage: video/x.mp4 a-b c-d e- -->` gets scene 1 cut from that file, those
// stretches in that order, the last one running until the scene's hold is filled. The ranges live in
// the script, beside the words they are timed to, and nowhere else.
const FOOT = md.match(/<!-- footage: (\S+) ([\d.\- ]+?) -->/);
const FOOTAGE = FOOT && {
  src: path.join(repo, FOOT[1]),
  ranges: FOOT[2].trim().split(/\s+/).map((r) => r.split("-").map((x) => (x === "" ? null : parseFloat(x)))),
};
if (FOOTAGE) process.stderr.write(`• scene 1 is footage: ${FOOT[1]} ${FOOT[2]}\n`);

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
const slots = JSON.parse(readFileSync(path.join(repo, "web/slots.json"), "utf8"));
// THE CLAIM MOVED FROM ONE COUNT TO THE NEXT, and this guard did not. It required zero CONFIGURED
// accounts; on 2026-09-22 two configured one and neither was approved, so it would have refused to
// record a check-in whose narration already says exactly that. What every current script claims is
// that nobody is THROUGH the gate — that is the approved count, and that is what is guarded.
if (usage.total_approved_accounts !== 0)
  throw new Error(`an issuer has approved ${usage.total_approved_accounts} account(s) — the gate is `
    + `open and every script that says it is shut is now wrong`);
process.stderr.write(`• gate: ${usage.total_confidential_accounts} configured, `
  + `${usage.total_approved_accounts} approved (${usage.generated_utc})\n`);

// ── serve web/ so scene 1 drives the same files the site publishes ───────────────────────────────
const server = FOOTAGE ? null : spawn("python3", ["-m", "http.server", String(PORT)], {
  cwd: path.join(repo, "web"), stdio: "ignore",
});
const stop = () => { try { server && server.kill(); } catch {} };
process.on("exit", stop);
if (server) await sleep(900);

const browser = await puppeteer.launch({
  headless: "new",
  defaultViewport: { width: 1280, height: 720, deviceScaleFactor: 1.5 },
  args: ["--no-sandbox", "--hide-scrollbars", "--window-size=1280,720", "--force-device-scale-factor=1.5"],
});
const page = await browser.newPage();
if (!FOOTAGE) {
  await page.goto(`http://127.0.0.1:${PORT}/index.html`, { waitUntil: "networkidle2" });
  await page.evaluate(() => document.getElementById("swaps").scrollIntoView({ block: "center" }));
}
// With footage, the browser records scenes 2 and 3 only, into a file of their own; scene 1 is cut
// from the footage afterwards and the two are joined.
const recFile = FOOTAGE ? outFile + ".slides.mp4" : outFile;
const SLIDES = NUM === "1" ? "checkin.html" : `checkin-${NUM}.html`;
if (FOOTAGE) await page.goto("file://" + path.join(dir, SLIDES), { waitUntil: "load" });

const recorder = new PuppeteerScreenRecorder(page, {
  fps: 30, videoFrame: { width: 1920, height: 1080 }, aspectRatio: "16:9", ffmpeg_Path: FFMPEG,
});
const marks = [];
await recorder.start(recFile);
const t0 = Date.now();
const mark = () => marks.push((Date.now() - t0) / 1000);
if (!FOOTAGE) {

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
}

// ── scenes 2 and 3 — authored, over real output ──────────────────────────────────────────────────
// Scenes 2 and 3 are this week's, not last week's. checkin.html stays exactly as it was so the
// command that produced the submitted week-1 cut still reproduces it.
if (!FOOTAGE) await page.goto("file://" + path.join(dir, SLIDES), { waitUntil: "load" });
await page.evaluate((d) => window.__data(d), {
  table,
  accounts: usage.total_accounts.toLocaleString("en-US"),
  mints: mints.length.toLocaleString("en-US"),
  configured: usage.total_confidential_accounts,
  approved: usage.total_approved_accounts,
  usage_mints: usage.mints.length,
  usage_utc: usage.generated_utc,
  gated: slots.gated.toLocaleString("en-US"),
  auditor_empty: slots.auditor_empty.toLocaleString("en-US"),
  slots_utc: slots.generated_utc,
});
mark();
await page.evaluate((s) => window.__scene2(s), HOLD[1]);
mark();
await page.evaluate((s) => window.__scene3(s), HOLD[2]);
mark();

await recorder.stop();
await browser.close();
stop();

// ── scene 1 from footage, joined in front of the recorded slides ──────────────────────────────────
if (FOOTAGE) {
  // Each stretch is trimmed from the source as it is; the last runs open-ended and the whole is
  // cut to the hold. Nothing is sped up or slowed: the only edits are the cuts the script lists.
  const parts = FOOTAGE.ranges.map(([a, b], i) =>
    `[0:v]trim=start=${a}${b == null ? "" : `:end=${b}`},setpts=PTS-STARTPTS,fps=30,`
    + `scale=1920:1080,setsar=1,format=yuv420p[f${i}]`);
  const n = FOOTAGE.ranges.length;
  const graph = parts.join(";") + ";"
    + FOOTAGE.ranges.map((_, i) => `[f${i}]`).join("") + `concat=n=${n}:v=1:a=0,`
    + `trim=duration=${HOLD[0]},setpts=PTS-STARTPTS[s1];`
    + `[1:v]fps=30,scale=1920:1080,setsar=1,format=yuv420p,setpts=PTS-STARTPTS[s2];[s1][s2]concat=n=2:v=1:a=0[v]`;
  execFileSync(FFMPEG, ["-v", "error", "-i", FOOTAGE.src, "-i", recFile,
    "-filter_complex", graph, "-map", "[v]", "-c:v", "libx264", "-crf", "16", "-preset", "fast",
    outFile, "-y"]);
  execFileSync("rm", ["-f", recFile]);
  // The slides' marks were taken from their own start; scene 1 now sits in front of them.
  marks.splice(0, marks.length, 0, ...marks.map((m) => m + HOLD[0]));
}

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
// AND PER CHECK-IN, for the same reason outFile is: this wrote week 2's marks over week 1's
// manifest while week 1's clips stayed on disk, leaving a manifest that described a cut its own
// clips were not from. split.sh maps `checkin` to checkin-1.mp4, so that directory stays week 1's.
const segDir = path.join(dir, NUM === "1" ? "segments-checkin" : `segments-checkin-${NUM}`);
mkdirSync(segDir, { recursive: true });
writeFileSync(path.join(segDir, "manifest.json"), JSON.stringify(manifest, null, 1) + "\n");
process.stderr.write(`\n✓ ${outFile}  (${marks[3].toFixed(1)}s)\n`);
for (const m of manifest) process.stderr.write(`   ${m.file}  ${m.seconds}s\n`);
