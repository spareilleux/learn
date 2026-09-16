// Lesson 19: the Vite dev server and build for the TypeScript frontend in frontend/,
// adapted from https://v2.tauri.app/start/frontend/vite/, and Vitest for lesson 21
import { defineConfig } from "vitest/config";

export default defineConfig({
  root: "frontend",
  // Keep Cargo's output visible when tauri dev runs Vite
  clearScreen: false,
  server: {
    // Must match build.devUrl in src-tauri/tauri.vite.conf.json
    port: 5173,
    strictPort: true,
    watch: {
      // Rust changes are watched by the Tauri CLI, not by Vite
      ignored: ["**/src-tauri/**", "**/target/**"],
    },
  },
  build: {
    outDir: "dist",
    emptyOutDir: true,
    // WebView2 is Chromium; WKWebView and WebKitGTK are WebKit (targets from the Tauri guide)
    target: process.env.TAURI_ENV_PLATFORM === "windows" ? "chrome105" : "safari13",
    minify: !process.env.TAURI_ENV_DEBUG,
    sourcemap: !!process.env.TAURI_ENV_DEBUG,
  },
  test: {
    // A simulated DOM: no webview and no Rust, invoke is answered by mockIPC
    environment: "jsdom",
    include: ["src/**/*.test.ts"],
  },
});
