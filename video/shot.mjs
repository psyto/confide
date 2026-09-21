import puppeteer from "puppeteer";
import path from "node:path";
const b = await puppeteer.launch({ headless: "new",
  defaultViewport: { width: 1200, height: 630, deviceScaleFactor: 2 },
  args: ["--no-sandbox", "--hide-scrollbars"] });
const p = await b.newPage();
await p.goto("file://" + path.resolve("video/graphic.html"), { waitUntil: "load" });
await p.screenshot({ path: "/tmp/graphic.png" });
await b.close();
console.log("shot");
