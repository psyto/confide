// Records confide.mp4.
//
// The graphical panes are authored; every terminal pane is the stdout of a command run moments
// before the recording starts, and two of those reach mainnet and devnet. If a command does not
// produce the line that carries its claim, this throws instead of recording — a video that still
// renders after the thing it demonstrates broke is the failure worth engineering against.
import path from "node:path";
import { readFileSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { execFileSync } from "node:child_process";
import puppeteer from "puppeteer";
import { PuppeteerScreenRecorder } from "puppeteer-screen-recorder";

const dir = path.dirname(fileURLToPath(import.meta.url));
const repo = path.join(dir, "..");
const outFile = path.join(dir, "confide.mp4");
const KEYS = process.env.CONFIDE_KEYS || path.join(repo, "account-keys.json");
// Read from account-keys.json rather than pinned here. The account was pinned as a literal until
// 2026-09-15, and when it was re-provisioned the video kept showing the dead one on screen while
// the page and the README showed the live one. A default that goes stale silently is worse than
// none: every scene still rendered, and nothing failed.
const ACCOUNT = process.env.CONFIDE_ACCOUNT || JSON.parse(readFileSync(KEYS, "utf8")).account;

function run(cmd, args, label) {
  process.stderr.write(`• ${label} …\n`);
  return execFileSync(cmd, args, {
    cwd: repo, encoding: "utf8", maxBuffer: 8 * 1024 * 1024,
    env: { ...process.env, FORCE_COLOR: "1" },
  }).replace(/\s+$/, "");
}
function slice(text, from, to) {
  const lines = text.split("\n");
  const a = lines.findIndex((l) => from.test(l));
  if (a < 0) throw new Error(`slice: no line matched ${from}`);
  const b = lines.slice(a).findIndex((l) => to.test(l));
  if (b < 0) throw new Error(`slice: no line matched ${to} after ${from}`);
  return lines.slice(a, a + b + 1).join("\n").replace(/^\s*\n/, "").replace(/\n\s*$/, "");
}

// ── the real runs ────────────────────────────────────────────────────────────────────────────────
const mints = run("bash", ["scripts/onchain-check.sh"], "reading the xStock mints on mainnet");
const balance = run("bash", ["scripts/read-balance.sh", ACCOUNT, KEYS], "opening our own confidential balance");
const collateral = run("bash", ["scripts/prove-collateral.sh", ACCOUNT, "100000", KEYS], "proving the account clears a threshold, on devnet");
// Reads public state only. The seizure already happened; this is the chain being asked whether it
// still says so, which is the half a viewer can check for themselves afterwards.
const seizure = run("bash", ["scripts/seizure-status.sh"], "reading the seizure back off devnet");

// ── guards ───────────────────────────────────────────────────────────────────────────────────────
for (const [text, re, why] of [
  [mints, /NVDAx.*Token-2022.*None/, "NVDAx no longer reads as Token-2022 with an empty auditor slot"],
  [mints, /NVDA\.US.*Token-2022.*None/, "Backpack's NVDA.US no longer reads the same way"],
  [mints, /AAPL\.US.*None/, "the mint sweep is incomplete"],
  [balance, /public balance\s+0/, "the account's public balance is no longer zero"],
  [balance, /173000 units/, "the confidential balance did not open to the expected position"],
  [collateral, /VerifyCiphertextCommitmentEquality/, "the equality proof never ran"],
  [collateral, /VerifyBatchedRangeProofU64/, "the range proof never ran"],
  [collateral, /both accepted/, "the chain did not accept both proofs"],
  [seizure, /seized: yes/, "the loan on devnet no longer reads as seized"],
  [seizure, /program.*Gn3rzw8/s, "the seizure program is not the one the loan was settled by"],
  [seizure, /still read zero/, "the seizure pane stopped saying both accounts read zero"],
]) {
  if (!re.test(text)) throw new Error(`refusing to record — ${why}`);
}
if ((mints.match(/None\s*$/gm) || []).length < 4) throw new Error("refusing to record — expected 4 empty auditor slots");
if ((collateral.match(/err\s*:\s*None/g) || []).length < 2) throw new Error("refusing to record — a proof came back with an error");

const manifestPath = path.join(dir, "segments", "manifest.json");

// ── the cut ──────────────────────────────────────────────────────────────────────────────────────
// The mint count and issuer count are read at render time, not written into the page. The slot
// scene said "All 1,869" and "Two, independently" as literals until 2026-09-19, when a third
// issuer appeared and neither the page nor any test noticed.
const MINTS = JSON.parse(readFileSync(path.join(repo, "web/mints.json"), "utf8"));
const MINT_COUNT = MINTS.length.toLocaleString("en-US");
const ISSUERS = new Set(MINTS.map((m) => m.issuer)).size;

const scenes = [
  {
    file: "01-title.mp4",
    kind: "hero",
    lede: "You hold tokenized stocks on Solana.<br><b>So does everyone watching.</b>",
    hold: 8.1,
  },
  { file: "02-leak.mp4", kind: "leak", hold: 7.5 },
  { file: "03-empty-slot.mp4", kind: "slot", mints: MINT_COUNT, issuers: ISSUERS, hold: 21.0 },
  { file: "04-four-views.mp4", kind: "views", hold: 13.2 },
  {
    file: "05-benefits.mp4",
    kind: "benefits",
    label: "What you get.",
    items: [
      ["hide", "Your position stops being public.",
       "It sits on-chain and reads as zero to anyone who looks."],
      ["prove", "A lender can check your collateral without seeing it.",
       "Prove the position covers the loan and reveal one bit \u2014 not the value, not the composition."],
      ["share", "Your auditor and your LPs are unaffected.",
       "They read exactly what they are owed, on the schedule they are owed it."],
      ["lock", "Last quarter's number cannot be tidied.",
       "Sealed on the reporting date, opened on the deadline by people you do not control."],
      ["split", "A stock split does not corrupt what you disclosed.",
       "Restatement is a function of public data, and says so when it cannot be computed."],
    ],
    hold: 16.3,
  },
  {
    file: "06-live-account.mp4",
    kind: "evidence",
    label: "A live account on devnet.",
    body: slice(balance, /account\s+/, /elgamal ciphertext/),
    // Not a bare "0": it matches every zero inside 17300000000000 as well as the balance, which
    // is what the published upload shows. See the note on ansi() in demo.html.
    emphasis: ["public balance     0", "173000 units"],
    hold: 9.6,
  },
  {
    file: "07-proofs.mp4",
    kind: "evidence",
    label: "And the lender's check, run by Solana's ZK program.",
    body: slice(collateral, /ciphertext-commitment equality/, /both accepted/),
    emphasis: ["err   : None", "success", "both accepted"],
    hold: 13.1,
  },
  {
    file: "08-seizure.mp4",
    line: "And on default, the lender takes it — a transfer the borrower authorised at origination and cannot now refuse. No key is reconstructed, nobody is asked, and neither account ever shows what moved.",
    kind: "evidence",
    label: "And on default, the lender takes it.",
    body: slice(seizure, /loan\s+/, /still read zero/),
    emphasis: ["seized: yes", "public balance 0"],
    hold: 13.6,
  },
  {
    file: "09-close.mp4",
    line: "Your position is yours. And you can still prove what you must. Try it yourself — no wallet, no install.",
    kind: "close",
    hold: 7.8,
  },
];

// ── record ───────────────────────────────────────────────────────────────────────────────────────
const browser = await puppeteer.launch({
  headless: "new",
  // 1280x720 of layout at 1.5x device pixels, so the output is a true 1920x1080 rather than an
  // upscale. Nearly every frame is text, and 720p was costing it visibly once YouTube re-encoded.
  // Changing the viewport instead would have reflowed every scene; the scale factor does not.
  defaultViewport: { width: 1280, height: 720, deviceScaleFactor: 1.5 },
  args: ["--no-sandbox", "--hide-scrollbars", "--window-size=1280,720", "--force-device-scale-factor=1.5"],
});
const page = await browser.newPage();
// The page is the only thing that knows where the scenes actually landed. Nothing used to write
// these down, so segments/manifest.json was maintained by hand and split.sh cut a changed render
// against the previous cut's boundaries — silently, producing a clip named for one scene and
// containing another. Recording them here is what makes the manifest a product of the render.
const marks = [];
const overlaps = [];
page.on("console", (m) => {
  const t = m.text();
  if (!t.startsWith("CONFIDE_")) return;
  process.stderr.write(`• page: ${t}\n`);
  const scene = t.match(/^CONFIDE_SCENE \S+ ([0-9.]+)/);
  if (scene) marks.push(parseFloat(scene[1]));
  const total = t.match(/^CONFIDE_SECONDS ([0-9.]+)/);
  if (total) marks.push(parseFloat(total[1]));
  // demo.html gained a fixed wordmark, and this cut draws on the same page. A pane that grows up
  // underneath it overprints silently, so the page says so and both recorders refuse.
  const over = t.match(/^CONFIDE_OVERLAP (.+) (\d+)$/);
  if (over) overlaps.push(`"${over[1]}" reaches ${over[2]}px into the wordmark`);
});
await page.goto("file://" + path.join(dir, "demo.html"), { waitUntil: "load" });
await page.evaluate((s) => window.__load(s), scenes);

const recorder = new PuppeteerScreenRecorder(page, {
  fps: 30,
  videoFrame: { width: 1920, height: 1080 },
  aspectRatio: "16:9",
  ffmpeg_Path: process.env.FFMPEG_PATH || "/opt/homebrew/bin/ffmpeg",
});
await recorder.start(outFile);
const seconds = await page.evaluate(() => window.__play());
await recorder.stop();
await browser.close();

// Two things the recorder leaves in a state browsers will not play. The moov atom goes last, so
// playback cannot start until the whole file has arrived; and the frames come out yuvj420p, the
// full-range variant, which Chrome stalls on inside an mp4. Re-encode to limited-range yuv420p
// with the index at the front. Both were found by embedding the file and watching it spin at 0:00.
process.stderr.write("• re-encoding for the web …\n");
execFileSync(process.env.FFMPEG_PATH || "/opt/homebrew/bin/ffmpeg", [
  "-v", "error", "-i", outFile,
  "-vf", "scale=in_range=full:out_range=tv,format=yuv420p",
  "-c:v", "libx264", "-profile:v", "high", "-level", "4.0", "-crf", "20", "-preset", "slow",
  "-color_range", "tv", "-colorspace", "bt709", "-color_primaries", "bt709", "-color_trc", "bt709",
  "-movflags", "+faststart", outFile + ".tmp.mp4", "-y",
]);
execFileSync("mv", [outFile + ".tmp.mp4", outFile]);
// The manifest the cutting and narration scripts read. Written from where the scenes landed, not
// from where they were asked to.
if (overlaps.length) {
  throw new Error(`a scene has grown up underneath the wordmark:\n    ` + overlaps.join("\n    "));
}
if (marks.length !== scenes.length + 1) {
  throw new Error(`expected ${scenes.length + 1} scene marks, got ${marks.length}`);
}
const prior = Object.fromEntries(
  (() => { try { return JSON.parse(readFileSync(manifestPath, "utf8")); } catch { return []; } })()
    .map((e) => [e.file, e]),
);
const manifest = scenes.map((sc, i) => {
  const start = marks[i], end = marks[i + 1];
  const was = prior[sc.file] || {};
  return {
    file: sc.file,
    start: +start.toFixed(2),
    end: +end.toFixed(2),
    seconds: +(end - start).toFixed(2),
    ...(was.narration_seconds ? { narration_seconds: was.narration_seconds } : {}),
    audio: was.line && was.line === sc.line ? was.audio || "reuse" : "re-record",
    ...(sc.line ? { line: sc.line } : was.line ? { line: was.line } : {}),
  };
});
writeFileSync(manifestPath, JSON.stringify(manifest, null, 1) + "\n");
process.stderr.write(`• wrote ${manifestPath}\n`);

process.stderr.write(`\n✓ ${outFile}  (${seconds.toFixed(1)}s)\n`);
