// Lesson 21: WebdriverIO drives the real app, built with `npm run build:e2e`.
// The `webdriver` feature compiles a W3C WebDriver server into the app
// (tauri-plugin-wdio-webdriver), so no msedgedriver, WebKitWebDriver or tauri-driver
// is needed: the tests start the binary, then talk to its server on port 4445.
import { type ChildProcess, spawn } from "node:child_process";
import path from "node:path";

const port = 4445;
const binary = path.join(
  import.meta.dirname,
  "..",
  "target",
  "release",
  process.platform === "win32" ? "chord-explorer.exe" : "chord-explorer",
);
let app: ChildProcess | undefined;

async function serverReady() {
  for (let attempt = 0; attempt < 100; attempt++) {
    try {
      if ((await fetch(`http://127.0.0.1:${port}/status`)).ok) return;
    } catch {
      // not listening yet
    }
    await new Promise((resolve) => setTimeout(resolve, 200));
  }
  throw new Error(`no WebDriver server on port ${port}: was the app built with --features webdriver?`);
}

export const config: WebdriverIO.Config = {
  runner: "local",
  specs: ["./*.e2e.ts"],
  maxInstances: 1,
  hostname: "127.0.0.1",
  port,
  capabilities: [{}],
  framework: "mocha",
  reporters: ["spec"],
  logLevel: "warn",
  waitforTimeout: 10000,
  mochaOpts: { timeout: 60000 },

  async onPrepare() {
    app = spawn(binary, [], { env: { ...process.env, TAURI_WEBDRIVER_PORT: String(port) }, stdio: "inherit" });
    await serverReady();
  },
  onComplete() {
    app?.kill();
  },
};
