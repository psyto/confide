// The page side of the replay fix, in a real browser. No chain, no server: the static files are
// served from app/static and the event handlers are fed directly.
//
//   node video/test-ops-replay.mjs
//
// A reconnecting page replays every event from the start. "waiting X" then "advanced X" must leave
// no button for X; a following "waiting Y" must offer Y. Both views. Exits non-zero on any failure.
import puppeteer from "puppeteer";
import http from "node:http";
import { readFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.join(path.dirname(fileURLToPath(import.meta.url)), "..", "app", "static");
const srv = http.createServer((q, r) => {
  try { const f = readFileSync(path.join(root, q.url.split("?")[0].replace(/^\/$/, "/index.html")));
        r.writeHead(200, { "Content-Type": q.url.endsWith(".css") ? "text/css" : q.url.endsWith(".js") ? "text/javascript" : "text/html" }); r.end(f); }
  catch { r.writeHead(404); r.end(); }
}).listen(0);
const port = srv.address().port;
const browser = await puppeteer.launch({ headless: "new" });
let failed = 0;
const check = (ok, what) => { console.log((ok ? "  ok    " : "  FAIL  ") + what); if (!ok) failed++; };
for (const page of ["ops.html", "index.html"]) {
  const p = await browser.newPage();
  await p.evaluateOnNewDocument(() => { window.CONFIDE_REPLAY = true; });
  await p.goto(`http://127.0.0.1:${port}/${page}`, { waitUntil: "load" });
  const feed = (e) => p.evaluate((x) => window.__apply(x), e);
  const buttons = () => p.$$eval("button.next", (bs) => bs.map((b) => b.textContent));
  await feed({ ev: "run", mode: "short" });
  await feed({ ev: "waiting", next: "proofs" });
  check((await buttons()).some((t) => /proofs/i.test(t)), `${page}: "waiting proofs" offers the proofs step`);
  await feed({ ev: "advanced", step: "proofs" });
  check((await buttons()).length === 0, `${page}: "advanced proofs" leaves no button`);
  await feed({ ev: "waiting", next: "check" });
  const b = await buttons();
  check(b.length === 1 && /check/i.test(b[0]), `${page}: the next "waiting" offers the check step, and only it`);
  await p.close();
}
await browser.close(); srv.close();
process.exit(failed ? 1 : 0);
