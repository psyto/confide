// Records the demo from the running app, on devnet, unedited.
//
//   RPC="$CONFIDE_RPC" python3 app/server.py &      # the endpoint stays in the server's environment
//   node video/record-app.js                          # -> video/.demo-render/raw.mp4 + marks.json
//   node video/cut-app.js                             # -> video/demo-app.mp4 + demo-app.manifest.json
//
// Nothing on screen is staged. The page shows checkpoints that scripts/issue-e2e.sh wrote after its
// own checks against devnet (docs/cwf-2026/DEMO-APP.md); this script only presses the button the
// script is waiting on, and pauses so a viewer can read what came back. It records the normal run
// (both acts) and then the short-delivery control.
//
// It writes down when each button was pressed and when the next one appeared. The interval between
// is devnet doing the work -- proofs verified, transactions confirmed -- and cut-app.js is the only
// place that shortens it, visibly, with the real duration on screen.
import path from "node:path";
import { mkdirSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import puppeteer from "puppeteer";
import { PuppeteerScreenRecorder } from "puppeteer-screen-recorder";

const dir = path.dirname(fileURLToPath(import.meta.url));
// Two views of the same run: the role panes ("app", at /) and the settlement-operations layout ("ops",
// at /ops). Each gets its own render directory and its own cut; recording one never touches the other.
const UI = process.env.CONFIDE_UI === "ops" ? "ops" : "app";
const OUT = path.join(dir, UI === "ops" ? ".demo-render-ops" : ".demo-render");
mkdirSync(OUT, { recursive: true });
const APP = process.env.CONFIDE_APP || (UI === "ops" ? "http://127.0.0.1:8787/ops" : "http://127.0.0.1:8787/");
const FFMPEG = process.env.FFMPEG_PATH || "/opt/homebrew/bin/ffmpeg";
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// How long to hold on what a step produced before pressing the next button. The steps whose result
// IS the demo -- a refusal, a check, a settlement, the public view -- get longer.
const READ = {
  "Check the allocation before signing": 5500,
  "Send the allocation (account not approved yet)": 6000,
  "Try to approve my own account": 6000,
  "Approve exactly this account": 4500,
  "Send with the issuer's signature only": 6000,
  "Add my signature — settle": 6500,
  "Look from outside": 6500,
  "Check the cash against my pin, sign once": 5500,
  "Check the shares against my pin, add the second signature": 6500,
};
const DEFAULT_READ = 2600;

const browser = await puppeteer.launch({
  headless: "new",
  // 1600x900 of layout at 1.2 device pixels -> a true 1920x1080. Four panes need the width.
  defaultViewport: { width: 1600, height: 900, deviceScaleFactor: 1.2 },
  args: ["--no-sandbox", "--hide-scrollbars", "--window-size=1600,900", "--force-device-scale-factor=1.2"],
});
const page = await browser.newPage();
await page.goto(APP, { waitUntil: "load" });
// Refuse to record anything that is not the app, on devnet, saying so.
const banner = await page.$eval(".banner, .env", (e) => e.textContent).catch(() => "");
if (!/devnet/i.test(banner) || !/not a wallet/i.test(banner)) {
  throw new Error(`the page at ${APP} is not the demo app with its devnet banner: ${JSON.stringify(banner)}`);
}

const recorder = new PuppeteerScreenRecorder(page, {
  fps: 30, videoFrame: { width: 1920, height: 1080 }, aspectRatio: "16:9", ffmpeg_Path: FFMPEG,
});
const raw = path.join(OUT, "raw.mp4");
await recorder.start(raw);
const t0 = Date.now();
const now = () => (Date.now() - t0) / 1000;
const marks = [];
const mark = (m) => { marks.push({ t: +now().toFixed(3), ...m }); process.stderr.write(`• ${now().toFixed(1)}s ${JSON.stringify(m)}\n`); };

async function run(button, mode) {
  await sleep(2500);
  mark({ kind: "start", mode });
  await page.click(button);
  // The status line still says the previous run's "done" until the new run reports in.
  await page.waitForFunction(() => /^(running|waiting)/i.test(document.getElementById("status").textContent),
                             { timeout: 60000, polling: 100 });
  let shown = null; // the label of the step whose result is now on screen
  for (;;) {
    const h = await page.waitForFunction(() => {
      const st = document.getElementById("status").textContent;
      if (/^done/i.test(st)) return { done: st.toLowerCase() };
      if (/failed|timed out/i.test(st)) return { fail: st };
      const b = document.querySelector("button.next");
      // the ops view prefixes its buttons with "NEXT ▸ "; the step is the same either way
      return b && !b.disabled ? { step: b.textContent.replace(/^NEXT ▸ /, "") } : false;
    }, { timeout: 25 * 60 * 1000, polling: 200 });
    const v = await h.jsonValue();
    mark({ kind: "ready", mode, ...v });
    if (v.fail) throw new Error(`the run failed on screen: ${v.fail}`);
    await sleep((shown && READ[shown]) || DEFAULT_READ);
    if (v.done) return v.done;
    mark({ kind: "click", mode, step: v.step });
    await page.click("button.next");
    shown = v.step;
  }
}

let normal, short;
try {
  normal = await run("#start", "normal");
  await sleep(4000);
  short = await run("#short", "short");
  await sleep(3000);
} finally {
  await recorder.stop();
  writeFileSync(path.join(OUT, "marks.json"), JSON.stringify({ ui: UI, app: APP, normal, short, end: +now().toFixed(3), marks }, null, 1));
  await browser.close();
}
// The recording is only worth cutting if both runs ended the way the demo says they do.
if (normal !== "done") throw new Error(`the normal run ended on "${normal}", not "done"`);
if (!/short leg was refused/.test(short || "")) throw new Error(`the SHORT run ended on "${short}"`);
process.stderr.write(`• recorded ${now().toFixed(0)}s of real time -> ${raw}\n`);
