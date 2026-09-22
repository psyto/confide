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
const FFPROBE = process.env.FFPROBE_PATH || FFMPEG.replace(/ffmpeg$/, "ffprobe");
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
// Scene 7 is the whole claim, and it used to be a list of instruction names — which shows that two
// transfers happened and not that a trade did. This pane carries the exchange: the public view
// read live, and beside it the two columns the parties wrote down at the time, because the amounts
// are confidential and nothing on chain can recover them afterwards.
const dvp = run("bash", ["scripts/dvp-show.sh"], "reading the delivery-versus-payment", DEVNET);
const feeSwap = run("bash", ["scripts/swap-status.sh", "fee"], "reading the with-fee swap back off devnet", DEVNET);
const cash = run("bash", ["scripts/cash-scan.sh"], "reading the stablecoins on mainnet", MAINNET);
const testbed = run("bash", ["scripts/testbed-up.sh", "--check"], "checking the standing devnet issuer", DEVNET);

// The private half of the trade, written by the parties at the moment it settled — the only
// moment those figures exist, because nothing on chain can recover them afterwards.
const DVP = JSON.parse(readFileSync(path.join(repo, "web/dvp.json"), "utf8"));

// ── guards ───────────────────────────────────────────────────────────────────────────────────────
// The order's own conditions, read out of the file that was pinned from the SEC's release. The
// first three scenes are about a regulation, so the only honest picture is the text of it — and
// typing that text into this file would be the copy this repository keeps making.
const SEC = readFileSync(path.join(repo, "docs/SEC-EXEMPTION.md"), "utf8");
// The card paraphrases for legibility, so every value on it is checked against the pinned row here.
// Without this the scene would be typed text about a regulation, which is the copy this repository
// keeps making -- and this one would be quoted back at a judge.
function secMust(name, phrases) {
  const row = secRow(name);
  for (const p of phrases) {
    if (!row.includes(p)) throw new Error(`the "${name}" condition no longer says "${p}" — docs/SEC-EXEMPTION.md`);
  }
}
function secRow(name) {
  const m = SEC.match(new RegExp(`^\\| \\*\\*${name}\\*\\* \\| (.+?) \\|$`, "m"));
  if (!m) throw new Error(`docs/SEC-EXEMPTION.md no longer has the "${name}" condition`);
  return m[1].replace(/\*\*/g, "").replace(/"/g, '"').replace(/\s+/g, " ").trim();
}

const USAGE = JSON.parse(readFileSync(path.join(repo, "web/usage.json"), "utf8"));
const ACCOUNTS = USAGE.total_accounts.toLocaleString("en-US");

for (const [text, re, why] of [
  [mints, /NVDAx.*Token-2022.*None/, "NVDAx no longer reads as Token-2022 with an empty auditor slot"],
  [mints, /NVDA\.US.*Token-2022.*None/, "Backpack's NVDA.US no longer reads the same way"],
  [balance, /public balance\s+0/, "the account's public balance is no longer zero"],
  [balance, /173000 units/, "the confidential balance did not open to the expected position"],
  // Scene 4 is the whole reveal, and it says zero. If anybody has opened a confidential account
  // since the scan, the scene is wrong and the right response is to rescan, not to record.
  // TYPED IN TWICE, AND STALE BOTH TIMES. This said 329,536 — correct on 2026-09-17 and 465,520 four
  // days later — so the render refused on a guard that was itself out of date. The count is read
  // from the file that computes it, exactly as MINT_COUNT already was.
  [usage, new RegExp(`${ACCOUNTS} token accounts, .*0.* configured for confidential`),
   `the account scan no longer reads ${ACCOUNTS} / zero — rerun ./scripts/usage-scan.sh`],
  [swaps, /confidentialTransfer, confidentialTransfer/, "the plain swap no longer carries two confidential transfers"],
  [swaps, /public balance 0 on every one/, "a swap account's public balance is no longer zero"],
  [dvp, /4 of 4 accounts/, "one of the four accounts in the recorded trade has gone, or stopped reading zero"],
  [dvp, /50,000 shares.*\$8,750,000/, "the recorded trade is no longer 50,000 shares against $8,750,000"],
  // The picture is drawn from web/dvp.json and the guard above reads the chain, so the two have to
  // agree or the scene is drawing a trade that did not happen.
  [String(DVP.delivered_units), /^50000$/, "web/dvp.json no longer describes the trade this scene draws"],
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
const matched = [...md.matchAll(/^### (\d+) — ([^·\n]+?)\s*(?:·[^\n]*)?$\n\n((?:^> ?.*\n)+)/gm)];
const script = matched.map((m) => m[3].replace(/^> ?/gm, "").trim().replace(/\n+/g, " "));
const TITLES = matched.map((m) => m[2].trim());
if (script.length !== 10) throw new Error(`CWF-PRESENTATION.md: expected 10 scripted scenes, found ${script.length}`);

// The mint count and issuer count are read at render time, not written into the page. The slot
// scene said "All 1,869" and "Two, independently" as literals until 2026-09-19, when a third
// issuer appeared and neither the page nor any test noticed.
const MINTS = JSON.parse(readFileSync(path.join(repo, "web/mints.json"), "utf8"));
const MINT_COUNT = MINTS.length.toLocaleString("en-US");
const ISSUERS = new Set(MINTS.map((m) => m.issuer)).size;

// `for` is the script heading each scene is footage FOR, and it is checked below. The pairing used
// to be by array index alone — and the 2026-09-22 restructure kept the count at ten while replacing
// the first three scenes, so a render would have laid "the SEC opened the market" over the old title
// card and reported success. An index is not a binding.
secMust("Every trade's size is published", ["within 10 minutes", "the transaction size",
                                            "the transaction time", "the transaction direction"]);
secMust("Size is capped", ["0.25% of average daily share volume", "three months"]);

const scenes = [
  // The product, then the product working, inside the first thirty seconds. The order this
  // replaces put the trade ninety seconds in, on a premise CRITERIA.md retracted on 2026-09-19:
  // traction is last of the seven and absent from the Official Rules, §8 opens on Functionality,
  // and §8(e) asks how the work composes with other primitives — which was the buried scene.
  {
    // The condition, at reading size. It used to be poured into the `pre` pane -- 13.5px monospace,
    // white-space:pre -- so an English sentence ran off the right edge and was cut mid-word. The
    // words on screen are short; every value in them is checked against the pinned order below.
    file: "01-the-tape.mp4", for: "the tape", kind: "order",
    label: "The SEC's order, 17 September 2026.",
    stamp: "sec.gov — press release 2026-90",
    quote: 'A venue must publish <em>the size, the time and the direction</em> of every trade it '
         + 'executes — <em>within ten minutes</em>, free, and machine-readable.',
    rule: ["0.25%", "of average daily volume is all you may trade in a Tier 1 name. "
                  + "<b>Exceed it twice and the symbol pauses for three months.</b>"],
    total: HOLD[0],
  },
  {
    // The title card, and it comes BEFORE the diagram. The first cut had it third: "nobody has built
    // the block" landed on a viewer who had just watched one settle, and the product was not named
    // until after its own picture. The gap is opened here and filled in the next scene.
    file: "02-the-block.mp4", for: "the block", kind: "hero",
    // THE PLAIN SENTENCE, PUT BACK. The published cut opened with "Confide settles tokenized stock
    // against a stablecoin in a single transaction, and neither side publishes what moved" and the
    // restructure dropped it without replacing it -- so for fifty seconds the only statement of what
    // this IS was the word "block", which is trade jargon, and a diagram captioned "cash".
    //
    // The narration says the gap; the screen says what fills it. Neither reads the other.
    sub: "confidential delivery-versus-payment for tokenized stocks on Solana",
    lede: "A stock-to-stablecoin swap in <b>one transaction</b>,<br>with <b>neither side publishing what moved</b>.",
    total: HOLD[1],
  },
  {
    // RESTORED. Dropped as collateral damage in the 2026-09-22 restructure rather than by any
    // decision -- and it is the only picture that carries the product without a word of explanation.
    file: "03-the-trade.mp4", for: "the trade", kind: "dvp",
    label: "So here is one.",
    seller: DVP.seller, buyer: DVP.buyer,
    delivered: DVP.delivered_units, paid: DVP.paid_units,
    total: HOLD[2],
  },
  {
    file: "04-this-account.mp4", for: "this account", kind: "evidence",
    label: "A real account on Solana, right now.",
    body: slice(balance, /public balance/, /public balance/),
    emphasis: ["0"],
    then: {
      at: 6,
      body: slice(balance, /confidential\s+\d/, /confidential\s+\d/),
      emphasis: ["173000 units"],
      label: "The same account. This is what it holds.",
    },
    total: HOLD[3],
  },
  { file: "05-already-shipped.mp4", for: "already solved, already switched off", kind: "slot", mints: MINT_COUNT, issuers: ISSUERS, total: HOLD[4] },
  {
    file: "06-so-i-counted.mp4", for: "so I counted", kind: "evidence",
    label: "So I stopped reading the settings and counted the accounts.",
    // Not "just now", and the badge says so. Every other pane in this cut is a command run
    // moments before the recording; this scan reads every token account of every mint and takes
    // minutes, so it is the stored measurement and the screen carries its date.
    stamp: "measured " + JSON.parse(readFileSync(path.join(repo, "web/usage.json"), "utf8")).generated_utc,
    body: slice(usage, /AAPLx/, /token accounts,/),
    emphasis: [ACCOUNTS, "0 configured for confidential transfers"],
    total: HOLD[5],
  },
  {
    file: "07-not-only-equities.mp4", for: "and it is not only equities", kind: "evidence",
    label: "And it was never a story about tokenized stocks.",
    body: slice(cash, /program\s+confidential/, /Four issuers/),
    emphasis: ["PYUSD", "USDG", "EMPTY"],
    total: HOLD[6],
  },
  {
    // Why not an exchange — the question a Solana judge asks first, and the film had no answer.
    // Three steps and no numbers: inventing a pool to illustrate it would be the one thing this
    // repository does not do.
    file: "08-why-not-an-exchange.mp4", for: "why not just use an exchange", kind: "missing",
    label: "So why not just trade it on an exchange?",
    items: [
      "A pool's reserves are <b>public state</b>.",
      "A trade moves them by <b>exactly the amount traded</b>.",
      "Subtract two consecutive states and you have the size. <b>Every time, whatever the token can do.</b>",
      "And the exemption <b>requires an AMM</b> — the only US venue that may operate is built this way.",
    ],
    // step was 6 and four items then ran 28 s against the script's 24 — the picture was deciding the
    // length. The script decides it: 4 x 5 + 3.5 lead lands inside the hold pace.py derived.
    lead: 3.5, step: 5,
    total: HOLD[7],
  },
  {
    file: "09-why-it-is-hard.mp4", for: "why it is hard", kind: "evidence",
    label: "The proofs do not fit in one transaction.",
    body: slice(feeSwap, /stock for cash, on a mint/, /the 4 accounts/),
    emphasis: ["confidentialTransferWithFee"],
    total: HOLD[8],
  },
  {
    file: "10-what-i-got-wrong.mp4", for: "what I got wrong, and what nobody has used", kind: "runnable",
    label: "A review found the safety step was not checking. Nobody outside this repository has used any of it.",
    command: "./scripts/testbed-join.sh",
    body: slice(testbed, /THE STANDING TESTBED/, /the testbed is as published/),
    emphasis: ["autoApproveNewAccounts is still false", "the testbed is as published"],
    url: "github.com/psyto/confide",
    note: "The gate is shut, as it is on all " + MINT_COUNT + ". The key that opens it is published.",
    total: HOLD[9],
  },
].map((s, i) => ({ ...s, line: script[i] }));

// THE BINDING between narration and footage. Names, not positions.
scenes.forEach((s, i) => {
  if (s.for !== TITLES[i]) {
    throw new Error(
      `scene ${i + 1} of the script is "${TITLES[i]}" and the footage here is for "${s.for}" — ` +
      `CWF-PRESENTATION.md was restructured and this scene has no picture yet`);
  }
});

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

// The marks are the PAGE's clock and the cuts are made against the FILE's. They agree only while
// the recorder keeps up, and on a loaded machine it does not: one render came out 296s for 171.6s
// of page time, so every boundary in the manifest pointed at the wrong scene and split.sh
// cheerfully produced ten clips paired with ten wrong lines. Nothing noticed, because nothing was
// comparing the two clocks.
const probed = parseFloat(
  execFileSync(FFPROBE, ["-v", "error", "-show_entries", "format=duration",
                         "-of", "csv=p=0", outFile], { encoding: "utf8" }).trim(),
);
const drift = Math.abs(probed - seconds);
process.stderr.write(`• page clock ${seconds.toFixed(1)}s, file ${probed.toFixed(1)}s\n`);
if (drift > 2) {
  throw new Error(
    `refusing to write a manifest — the file is ${probed.toFixed(1)}s and the page took ` +
    `${seconds.toFixed(1)}s. The recorder could not keep up, so every cut would land in the ` +
    `wrong scene. Close what else is running and record again.`,
  );
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
