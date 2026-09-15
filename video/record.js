// Records confide.mp4.
//
// The graphical panes are authored; every terminal pane is the stdout of a command run moments
// before the recording starts, and two of those reach mainnet and devnet. If a command does not
// produce the line that carries its claim, this throws instead of recording — a video that still
// renders after the thing it demonstrates broke is the failure worth engineering against.
import path from "node:path";
import { readFileSync } from "node:fs";
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
]) {
  if (!re.test(text)) throw new Error(`refusing to record — ${why}`);
}
if ((mints.match(/None\s*$/gm) || []).length < 4) throw new Error("refusing to record — expected 4 empty auditor slots");
if ((collateral.match(/err\s*:\s*None/g) || []).length < 2) throw new Error("refusing to record — a proof came back with an error");

// ── the cut ──────────────────────────────────────────────────────────────────────────────────────
const scenes = [
  {
    kind: "hero",
    lede: "You hold tokenized stocks on Solana.<br><b>So does everyone watching.</b>",
    hold: 8.1,
  },
  { kind: "leak", hold: 7.5 },
  { kind: "slot", hold: 21.0 },
  { kind: "views", hold: 13.2 },
  {
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
    kind: "evidence",
    label: "A live account on devnet.",
    body: slice(balance, /account\s+/, /elgamal ciphertext/),
    emphasis: ["0", "173000 units"],
    hold: 9.6,
  },
  {
    kind: "evidence",
    label: "And the lender's check, run by Solana's ZK program.",
    body: slice(collateral, /ciphertext-commitment equality/, /both accepted/),
    emphasis: ["err   : None", "success", "both accepted"],
    hold: 13.1,
  },
  { kind: "close", hold: 7.8 },
];

// ── record ───────────────────────────────────────────────────────────────────────────────────────
const browser = await puppeteer.launch({
  headless: "new",
  defaultViewport: { width: 1280, height: 720, deviceScaleFactor: 1 },
  args: ["--no-sandbox", "--hide-scrollbars", "--window-size=1280,720", "--force-device-scale-factor=1"],
});
const page = await browser.newPage();
page.on("console", (m) => {
  if (m.text().startsWith("CONFIDE_")) process.stderr.write(`• page: ${m.text()}\n`);
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
process.stderr.write(`\n✓ ${outFile}  (${seconds.toFixed(1)}s)\n`);
