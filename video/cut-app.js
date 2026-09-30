// Cuts video/.demo-render/raw.mp4 into video/demo-app.mp4, using the marks record-app.js wrote.
//
//   node video/cut-app.js
//
// ONE KIND OF EDIT, AND IT IS LABELLED. Between pressing a button and the next one appearing,
// devnet is doing the work: proofs built and verified, transactions confirmed. Some of those
// stretches are minutes long. The first and last WINDOW seconds of each are kept at real speed, so
// the press and the result are seen as they happened; the middle is played faster, and while it is,
// a badge on screen says so and gives the stretch's real duration. Nothing is cut out, reordered or
// replaced. demo-app.manifest.json lists every stretch that was shortened, with its real length.
import path from "node:path";
import { readFileSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { execFileSync } from "node:child_process";
import puppeteer from "puppeteer";

const dir = path.dirname(fileURLToPath(import.meta.url));
const UI = process.env.CONFIDE_UI === "ops" ? "ops" : "app";
const R = path.join(dir, UI === "ops" ? ".demo-render-ops" : ".demo-render");
const NAME = UI === "ops" ? "demo-ops" : "demo-app";
const FFMPEG = process.env.FFMPEG_PATH || "/opt/homebrew/bin/ffmpeg";
const FFPROBE = FFMPEG.replace(/ffmpeg$/, "ffprobe");
// Tuned so the cut fits the CWF limit of 3:00 without touching the reading pauses -- only devnet waits
// are shortened. Overridable, and whatever is used is written to the manifest.
const WINDOW = +(process.env.CUT_WINDOW || 0.4);          // seconds kept at real speed at each end of a wait
const SHORTEN_OVER = +(process.env.CUT_SHORTEN_OVER || 3); // waits no longer than this are left alone
const FF_SECONDS = +(process.env.CUT_FF_SECONDS || 1.1);   // what the middle of a long wait is played in
const raw = path.join(R, "raw.mp4");
const { marks, end, normal, short } = JSON.parse(readFileSync(path.join(R, "marks.json"), "utf8"));
// A recording that did not end the way the demo says it does is not cut, and gets no manifest
// calling it a devnet run.
if (normal !== "done" || !/short leg was refused/.test(short || "")) {
  throw new Error(`marks.json does not record a completed run (normal: ${normal}, short: ${short}) -- not cutting`);
}
const rawLen = parseFloat(execFileSync(FFPROBE, ["-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", raw], { encoding: "utf8" }));

// WALL CLOCK -> VIDEO CLOCK. The recorder drops frames under load, so the video comes out shorter
// than the time that passed (111 s of video for 115 s of wall clock in the first trial). The marks
// are wall clock. Scaled linearly to the video's own length so a badge lands on the stretch it
// describes; the factor is written to the manifest.
const clock = rawLen / end;
for (const m of marks) m.t = m.t * clock;

// The waits: from each button press to the next "ready".
const waits = [];
for (let i = 0; i < marks.length; i++) {
  const m = marks[i];
  if (m.kind !== "click" && m.kind !== "start") continue;
  const next = marks.slice(i + 1).find((x) => x.kind === "ready");
  if (next) waits.push({ from: m.t, to: next.t, after: m.step || `start (${m.mode})` });
}

// The timeline, in order: real-speed pieces and shortened ones.
const pieces = [];
let cursor = 0;
for (const w of waits) {
  const len = w.to - w.from;          // video seconds
  const realLen = len / clock;         // wall seconds, for the badge
  if (len <= SHORTEN_OVER) continue;
  const a = w.from + WINDOW, b = w.to - WINDOW;
  if (a > cursor) pieces.push({ start: cursor, end: a, speed: 1 });
  const speed = (b - a) / FF_SECONDS;
  pieces.push({ start: a, end: b, speed, real: realLen, after: w.after });
  cursor = b;
}
pieces.push({ start: cursor, end: rawLen, speed: 1 });

// One badge per shortened stretch, drawn by the browser (this ffmpeg has no text filter).
const fmt = (s) => `${Math.floor(s / 60)}:${String(Math.round(s % 60)).padStart(2, "0")}`;
const browser = await puppeteer.launch({ headless: "new", args: ["--no-sandbox"] });
const page = await browser.newPage();
await page.setViewport({ width: 760, height: 64, deviceScaleFactor: 1 });
const badges = [];
for (const [i, p] of pieces.entries()) {
  if (p.speed === 1) continue;
  const f = path.join(R, `badge-${i}.png`);
  await page.setContent(`<html><body style="margin:0;background:transparent">
    <div style="font:600 26px -apple-system,Helvetica,sans-serif;color:#0b0f14;background:#e3b341;
      border-radius:10px;padding:14px 22px;display:inline-block;white-space:nowrap">
      ▶▶ fast-forward ×${Math.round(p.speed)} &nbsp;·&nbsp; waiting on devnet &nbsp;·&nbsp; real time ${fmt(p.real)}
    </div></body></html>`);
  const el = await page.$("div");
  await el.screenshot({ path: f, omitBackground: true });
  badges.push({ piece: i, file: f });
}
await browser.close();

// ffmpeg: trim each piece, retime the shortened ones, overlay their badges, concatenate.
const args = ["-v", "error", "-y", "-i", raw];
for (const b of badges) args.push("-i", b.file);
const parts = [];
let fc = "";
pieces.forEach((p, i) => {
  fc += `[0:v]trim=start=${p.start.toFixed(3)}:end=${p.end.toFixed(3)},setpts=(PTS-STARTPTS)/${p.speed.toFixed(4)}`;
  const b = badges.findIndex((x) => x.piece === i);
  if (b >= 0) {
    fc += `[p${i}];[p${i}][${b + 1}:v]overlay=x=W-w-36:y=36[v${i}];`;
  } else {
    fc += `[v${i}];`;
  }
  parts.push(`[v${i}]`);
});
fc += `${parts.join("")}concat=n=${parts.length}:v=1:a=0,fps=30,scale=in_range=full:out_range=tv,format=yuv420p[out]`;
const out = path.join(dir, NAME + ".mp4");
args.push("-filter_complex", fc, "-map", "[out]",
  "-c:v", "libx264", "-profile:v", "high", "-level", "4.0", "-crf", "20", "-preset", "slow",
  "-color_range", "tv", "-colorspace", "bt709", "-color_primaries", "bt709", "-color_trc", "bt709",
  "-movflags", "+faststart", out);
execFileSync(FFMPEG, args, { maxBuffer: 64 * 1024 * 1024 });
const len = parseFloat(execFileSync(FFPROBE, ["-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", out], { encoding: "utf8" }));

writeFileSync(path.join(dir, NAME + ".manifest.json"), JSON.stringify({
  note: `${NAME}.mp4 is ${path.basename(R)}/raw.mp4 (an unedited devnet run through the app, "${UI}" view) with the ` +
        "middle of each long wait played faster. Every shortened stretch carries an on-screen badge " +
        "with its real duration, and is listed here. Nothing is removed or reordered.",
  raw_seconds: +rawLen.toFixed(1),
  wall_seconds: +end.toFixed(1),
  video_per_wall_second: +clock.toFixed(4),
  settings: { window_seconds: WINDOW, shorten_over_seconds: SHORTEN_OVER, fast_forward_seconds: FF_SECONDS },
  cut_seconds: +len.toFixed(1),
  // Where each press and each result landed in the CUT, so the narration's scene times are derived
  // from this file (video/demo-times.py) rather than typed.
  timeline: marks.map((m) => {
    let out = 0, at = null;
    for (const p of pieces) {
      if (m.t >= p.start && m.t <= p.end) { at = out + (m.t - p.start) / p.speed; break; }
      out += (p.end - p.start) / p.speed;
    }
    return { mode: m.mode, kind: m.kind, step: m.step || m.done || "", cut_seconds: at === null ? null : +at.toFixed(1) };
  }),
  shortened: pieces.filter((p) => p.speed !== 1).map((p) => ({
    raw_from: +p.start.toFixed(2), raw_to: +p.end.toFixed(2), real_wait_seconds: +p.real.toFixed(1),
    speed: +p.speed.toFixed(1), while_waiting_after: p.after,
  })),
}, null, 1));
process.stderr.write(`• ${rawLen.toFixed(0)}s raw -> ${len.toFixed(1)}s cut, ${badges.length} stretches shortened -> ${out}\n`);
if (len > 180) process.stderr.write(`  ! over three minutes: the CWF demo limit is 3:00\n`);
