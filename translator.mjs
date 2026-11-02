import fs from "node:fs";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const overlaySource = fs.readFileSync(path.join(scriptDir, "overlay.js"), "utf8");
const portIndex = process.argv.indexOf("--port");
const port = Number(portIndex >= 0 ? process.argv[portIndex + 1] : 9337);
const endpoint = `http://127.0.0.1:${port}`;

function log(message) {
  console.log(`[${new Date().toISOString()}] ${message}`);
}

function findPlaywright() {
  const runtimeRoot = path.join(
    process.env.LOCALAPPDATA || "",
    "OpenAI",
    "Codex",
    "runtimes",
    "cua_node",
  );
  if (!fs.existsSync(runtimeRoot)) return null;

  for (const versionDir of fs.readdirSync(runtimeRoot)) {
    const candidate = path.join(
      runtimeRoot,
      versionDir,
      "bin",
      "node_modules",
      "playwright-core",
      "index.js",
    );
    if (fs.existsSync(candidate)) return candidate;
  }
  return null;
}

const playwrightPath = findPlaywright();
if (!playwrightPath) {
  throw new Error("Codex runtime Playwright package was not found.");
}

const playwrightModule = await import(pathToFileURL(playwrightPath).href);
const chromium = playwrightModule.chromium ?? playwrightModule.default?.chromium;
if (!chromium) throw new Error("Playwright Chromium API was not found.");

let browser = null;
const instrumented = new WeakSet();
let closedByUser = false;

async function attachPages() {
  if (!browser) return;
  for (const context of browser.contexts()) {
    for (const page of context.pages()) {
      if (instrumented.has(page)) continue;
      try {
        await page.addInitScript(overlaySource);
        await page.evaluate(overlaySource);
        instrumented.add(page);
        log(`已注入页面：${page.url()}`);
        page.on("close", () => instrumented.delete(page));
      } catch (error) {
        log(`注入失败：${error.message}`);
      }
    }
  }
}

async function connect() {
  try {
    browser = await chromium.connectOverCDP(endpoint);
    log(`已连接 Codex 调试端口 ${port}`);
    browser.on("disconnected", () => {
      browser = null;
      if (!closedByUser) log("调试连接已断开，正在等待 Codex 重新启动");
    });
    await attachPages();
  } catch {
    browser = null;
  }
}

async function refresh() {
  if (!browser) {
    await connect();
    return;
  }
  await attachPages();
}

async function shutdown() {
  closedByUser = true;
  browser = null;
  process.exit(0);
}

process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);

log(`汉化辅助器已启动，调试端口 ${port}`);
await refresh();
setInterval(refresh, 1500);
