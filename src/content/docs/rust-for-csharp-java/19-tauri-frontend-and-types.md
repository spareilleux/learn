---
title: 19. The Tauri frontend, Vite and types generated from Rust
description: A TypeScript frontend bundled by Vite next to lessons 16 to 18's plain JavaScript, hot reload under tauri dev, and TypeScript types generated from the Rust structs with ts-rs — what they check, the u128 that became a bigint, and what tauri-specta adds — compared with OpenAPI clients generated for ASP.NET Core and Spring.
sidebar:
  order: 19
---

Full example: [`l16-tauri/frontend/`](https://github.com/spareilleux/learn/tree/main/code/rust-for-csharp-java/l16-tauri/frontend), [`vite.config.ts`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/l16-tauri/vite.config.ts) and [`src-tauri/tauri.vite.conf.json`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/l16-tauri/src-tauri/tauri.vite.conf.json).

Lessons 16 to 18 used a page with no build step: `ui/main.js` reads `window.__TAURI__` and calls `invoke("spell_chord", { symbol })`. Nothing checks that name, that argument, or the shape of what comes back. Lesson 17 showed the consequence: `invoke("spell_chrod")` runs, and rejects only when the user clicks.

This lesson keeps the Rust side unchanged and gives the same explorer a second frontend, in TypeScript, bundled by [Vite](https://vite.dev/), with types generated from the Rust structs.

## What you already know

| Need | Tauri | ASP.NET Core | Spring | Electron |
|---|---|---|---|---|
| Frontend toolchain | any bundler; [Vite](https://v2.tauri.app/start/frontend/vite/) is the documented default | the [SPA templates](https://learn.microsoft.com/aspnet/core/client-side/spa/intro) (Vite for React and Vue) | a separate frontend project | [Electron Forge](https://www.electronforge.io/) with Vite or webpack |
| Dev server + reload | `tauri dev` starts Vite, then the app on `devUrl` | the SPA proxy | `npm run dev` + a proxy | `electron-forge start` |
| Types shared with the backend | [ts-rs](https://docs.rs/ts-rs/12.0.1/ts_rs/) or [tauri-specta](https://docs.rs/tauri-specta/2.0.0-rc.25/tauri_specta/) | [NSwag](https://learn.microsoft.com/aspnet/core/tutorials/getting-started-with-nswag) or a client generated from [OpenAPI](https://learn.microsoft.com/aspnet/core/fundamentals/openapi/overview) | [OpenAPI Generator](https://openapi-generator.tech/) | imported directly: both processes are TypeScript or JavaScript |

The difference with OpenAPI: there is no HTTP contract in the middle. The generator reads the Rust types directly, at `cargo test` time.

## Two frontends, one Rust core

The React course sets up a Vite project from scratch ([React (Vite), lesson 1](../../react-vite/01-vite-project/)); here Vite only needs to agree with Tauri on three things: the dev server's address, the build's output folder, and which commands produce them.

The course keeps `ui/` as it is and adds `frontend/`. Rather than editing `tauri.conf.json`, a second file overrides its `build` section; `tauri dev` and `tauri build` merge a file given with [`--config`](https://v2.tauri.app/reference/cli/#dev) over the main configuration (from [`src-tauri/tauri.vite.conf.json`, lines 1-11](https://github.com/spareilleux/learn/blob/2ce5e72/code/rust-for-csharp-java/l16-tauri/src-tauri/tauri.vite.conf.json#L1-L11)):

```json
{
  "build": {
    "devUrl": "http://localhost:5173",
    "frontendDist": "../frontend/dist",
    "beforeDevCommand": "npm run web:dev",
    "beforeBuildCommand": "npm run web:build"
  },
  "app": {
    "withGlobalTauri": false
  }
}
```

- `devUrl`: during `tauri dev`, the window loads the Vite dev server instead of files;
- `frontendDist`: what `tauri build` embeds in the binary, Vite's output;
- `beforeDevCommand` and `beforeBuildCommand`: the Tauri CLI runs them first, so one command starts everything;
- `withGlobalTauri: false`: no more `window.__TAURI__`. The TypeScript imports [`@tauri-apps/api`](https://www.npmjs.com/package/@tauri-apps/api), and Vite bundles only what it uses.

The `package.json` scripts give each frontend its command: `npx tauri dev` still opens `ui/`, `npm run dev:vite` runs `tauri dev --config src-tauri/tauri.vite.conf.json`.

The Vite side follows the [Tauri guide](https://v2.tauri.app/start/frontend/vite/) (from [`vite.config.ts`, lines 5-25](https://github.com/spareilleux/learn/blob/2ce5e72/code/rust-for-csharp-java/l16-tauri/vite.config.ts#L5-L25)):

```ts
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
```

`strictPort` matters: if 5173 is taken, Vite would silently pick 5174 and the window would load nothing. The `TAURI_ENV_*` variables are set by the Tauri CLI when it runs `beforeBuildCommand`, so the bundle targets the webview of the platform being built: the Windows build can use features that WebView2 has and Safari 13 does not.

The build runs `tsc` first, then Vite. Here `tauri build` ran it on Windows, so `TAURI_ENV_PLATFORM` was `windows`:

```text
> chord-explorer@0.1.0 web:build
> tsc && vite build

vite v8.3.0 building client environment for production...
transforming...
✓ 12 modules transformed.
rendering chunks...
computing gzip size...
frontend/dist/index.html                 2.41 kB │ gzip: 0.81 kB
frontend/dist/assets/index-Ctb_ps3-.css  1.34 kB │ gzip: 0.66 kB
frontend/dist/assets/index-MdGAJN8k.js   7.61 kB │ gzip: 3.10 kB

✓ built in 182ms
```

7.61 kB of JavaScript for the whole page, the Tauri API included: that is what gets embedded in the binary. On the Ubuntu CI runner, the same build targeted `safari13` and gave `index-CXi5Pk96.js   7.67 kB │ gzip: 3.13 kB`: another target, another bundle.

## `tauri dev` and hot reload

`npm run dev:vite` starts Vite, waits for it, then compiles and runs the app:

```text
     Running BeforeDevCommand (`npm run web:dev`)

> chord-explorer@0.1.0 web:dev
> vite

  VITE v8.3.0  ready in 202 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
     Running DevCommand (`cargo  run --no-default-features --color always --`)
        Info Watching C:\Users\spare\source\repos\learn\code\rust-for-csharp-java\l16-tauri\src-tauri for changes...
        Info Watching C:\Users\spare\source\repos\learn\code\rust-for-csharp-java\l16-tauri\theory for changes...
```

Two watchers run side by side, and what happens on a change depends on which one sees it. Measured with the window open, a chord typed in the input, and a favourite added:

| Edited file | Watcher | What happened | Kept |
|---|---|---|---|
| `frontend/src/styles.css` | Vite | `[vite] (client) hmr update /src/styles.css`: the new style applied without a reload | the page's state (the typed chord) and the Rust state |
| `frontend/src/main.ts` | Vite | `[vite] (client) page reload src/main.ts`: the page reloaded | only the Rust state: the favourites were still there, the input was back to its default |
| `src-tauri/capabilities/export.json` | Tauri CLI | `File src-tauri\capabilities\export.json changed. Rebuilding application...`, a compilation (9.73 s) and a restart | nothing in memory |

The second row is the one to remember. A module without an HMR handler, like `main.ts`, reloads the page; frameworks such as React add handlers that keep component state ([React (Vite), lesson 1](../../react-vite/01-vite-project/#hot-module-replacement-and-fast-refresh)). The Rust process does not restart, so its managed state survives: a Tauri app naturally keeps the data that matters on the Rust side.

## Types generated from Rust

[ts-rs](https://github.com/Aleph-Alpha/ts-rs) (12.0.1, MIT) adds a `TS` derive. Next to `Serialize`, it describes the same struct in TypeScript (from [`src-tauri/src/commands.rs`, lines 9-13](https://github.com/spareilleux/learn/blob/2ce5e72/code/rust-for-csharp-java/l16-tauri/src-tauri/src/commands.rs#L9-L13)):

```rust
/// A chord as the frontend receives it: strings ready to display.
#[derive(Debug, Serialize, TS)]
#[serde(rename_all = "camelCase")]
#[ts(export)]
pub struct ChordView {
```

`#[ts(export)]` generates a test, `export_bindings_chordview`, that writes the file when `cargo test` runs. The folder comes from an environment variable that Cargo sets for the whole workspace (from [`.cargo/config.toml`, lines 1-3](https://github.com/spareilleux/learn/blob/2ce5e72/code/rust-for-csharp-java/l16-tauri/.cargo/config.toml#L1-L3)):

```toml
# ts-rs writes the TypeScript declarations here when `cargo test` runs its export tests
[env]
TS_RS_EXPORT_DIR = { value = "frontend/src/bindings", relative = true }
```

```text
test commands::export_bindings_chordview ... ok
test commands::export_bindings_qualityview ... ok
test commands::export_bindings_commanderror ... ok
test state::export_bindings_searchevent ... ok
test commands::export_bindings_scalemode ... ok
test result: ok. 5 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.04s
```

The result reads serde's attributes, `rename_all` included (from [`frontend/src/bindings/ChordView.ts`, lines 1-6](https://github.com/spareilleux/learn/blob/2ce5e72/code/rust-for-csharp-java/l16-tauri/frontend/src/bindings/ChordView.ts#L1-L6)):

```ts
// This file was generated by [ts-rs](https://github.com/Aleph-Alpha/ts-rs). Do not edit this file manually.

/**
 * A chord as the frontend receives it: strings ready to display.
 */
export type ChordView = { symbol: string, qualityName: string, notes: Array<string>, intervals: Array<string>, };
```

The doc comment became JSDoc, so the editor shows it on hover. Lesson 18's `SearchEvent`, an enum with `tag` and `content`, becomes a discriminated union (from [`frontend/src/bindings/SearchEvent.ts`, line 6](https://github.com/spareilleux/learn/blob/2ce5e72/code/rust-for-csharp-java/l16-tauri/frontend/src/bindings/SearchEvent.ts#L6)):

```ts
export type SearchEvent = { "event": "voicings", "data": { frets: Array<string>, } } | { "event": "progress", "data": { done: number, total: number, } } | { "event": "finished", "data": { found: number, elapsedMs: number, cancelled: boolean, } };
```

and a `switch` on `event` narrows `data` in each branch, as a `switch` on a sealed hierarchy does in C# or Java (from [`frontend/src/main.ts`, lines 120-132](https://github.com/spareilleux/learn/blob/2ce5e72/code/rust-for-csharp-java/l16-tauri/frontend/src/main.ts#L120-L132)):

```ts
      switch (message.event) {
        case "voicings":
          for (const frets of message.data.frets) {
            if (list.children.length < MAX_LISTED) {
              const item = document.createElement("li");
              item.textContent = frets;
              list.append(item);
            }
          }
          break;
        case "progress":
          progress.value = message.data.done / message.data.total;
          break;
```

The generated files are committed. The frontend then builds without Rust, and CI runs `cargo test` and then fails if `git status` shows a changed binding: a Rust change that forgets to regenerate cannot be merged.

### What the types catch

A file with three mistakes:

```ts
import * as api from "./api";
import type { SearchEvent } from "./bindings/SearchEvent";

const chord = await api.spellChord("Am7");
console.log(chord.quality);

await api.diatonicChords("C", "dorian");

export function count(message: SearchEvent) {
  return message.event === "progress" ? message.data.frets.length : 0;
}
```

```text
frontend/src/mistakes.ts(5,19): error TS2339: Property 'quality' does not exist on type 'ChordView'.
frontend/src/mistakes.ts(7,31): error TS2345: Argument of type '"dorian"' is not assignable to parameter of type 'ScaleMode'.
frontend/src/mistakes.ts(10,54): error TS2339: Property 'frets' does not exist on type '{ done: number; total: number; }'.
```

The second error comes from a Rust enum: `ScaleMode` has two variants, so its TypeScript type is `"major" | "minor"`.

### The `u128` that became a `bigint`

The first generated `SearchEvent` did not say `elapsedMs: number`, it said `elapsedMs: bigint`. In Rust the field is a `u128`, from [`Duration::as_millis`](https://doc.rust-lang.org/std/time/struct.Duration.html#method.as_millis), and ts-rs maps `i64`, `u64`, `i128` and `u128` to `bigint` by default. A computation on it then fails to compile:

```ts
import type { SearchEvent } from "./bindings/SearchEvent";

export function seconds(message: SearchEvent) {
  if (message.event === "finished") {
    return message.data.elapsedMs / 1000;
  }
  return 0;
}
```

```text
frontend/src/pitfall.ts(5,12): error TS2365: Operator '/' cannot be applied to types 'bigint' and 'number'.
```

The type was wrong, not the code: [serde_json](https://docs.rs/serde_json/) writes a `u128` as a plain JSON number, and `JSON.parse` gives a `number`, never a `bigint`. The generated type described a value that never arrives. Two fixes: `TS_RS_LARGE_INT = "number"` in the `[env]` section for every large integer, or an override on the field, which the course uses (from [`src-tauri/src/state.rs`, lines 76-82](https://github.com/spareilleux/learn/blob/2ce5e72/code/rust-for-csharp-java/l16-tauri/src-tauri/src/state.rs#L76-L82)):

```rust
    Finished {
        found: usize,
        // ts-rs maps u128 to `bigint`, but serde_json writes a plain JSON number
        #[ts(type = "number")]
        elapsed_ms: u128,
        cancelled: bool,
    },
```

A `number` is exact up to 2<sup>53</sup> − 1, which is plenty for milliseconds. For identifiers or amounts that can go beyond, serialize them as strings on the Rust side and type them `string`.

The lesson generalizes: a generator translates types, not the serializer's behaviour. Whenever a generated type and a serde attribute disagree, trust the JSON and check the type.

## What ts-rs does not check

ts-rs describes values, not commands. The name `"spell_chord"` and the argument name `symbol` are still strings. The course gathers them in one module, one typed function per command, so a typo can live in only one place (from [`frontend/src/api.ts`, lines 11-19](https://github.com/spareilleux/learn/blob/2ce5e72/code/rust-for-csharp-java/l16-tauri/frontend/src/api.ts#L11-L19)):

```ts
export const chordQualities = () => invoke<QualityView[]>("chord_qualities");

export const spellChord = (symbol: string) => invoke<ChordView>("spell_chord", { symbol });

export const transposeChord = (symbol: string, semitones: number) =>
  invoke<ChordView>("transpose_chord", { symbol, semitones });

export const diatonicChords = (tonicNote: string, mode: ScaleMode) =>
  invoke<ChordView[]>("diatonic_chords", { tonicNote, mode });
```

`invoke<ChordView>` is a cast: TypeScript trusts it. If `spell_chord` returned something else, or were renamed, `tsc` would still pass. Lesson 21's end-to-end tests are what catch that.

[tauri-specta](https://github.com/specta-rs/tauri-specta) closes the gap: a `#[specta::specta]` attribute next to `#[tauri::command]`, and it generates the command functions themselves, with their names and argument types, as well as typed events. Where it stands on 2026-09-16:

| | ts-rs | tauri-specta |
|---|---|---|
| Version | 12.0.1, stable (2026-01-31) | 2.0.0-rc.25 (2026-05-08); release candidates since 2.0.0-rc.1 in October 2023 |
| Tauri | independent of Tauri | v2 needs specta 2, also a release candidate; the stable 1.x supports only Tauri v1 |
| Generates | types | types, command wrappers, events |
| When | `cargo test` | when Rust code calls its exporter, for example at startup in debug builds (*to verify*) |
| Stars on GitHub | 1,878 | 797 |

The course uses ts-rs because it is stable and does not touch the command registration. tauri-specta is the stronger check, and it was not tried on this project (*to verify*): a release candidate that has lasted almost three years is a decision to make knowingly, not a default.

## Key takeaways

- A second frontend needs no change on the Rust side: `--config` merges a file over `tauri.conf.json`, here `devUrl`, `frontendDist` and the two `before*Command`s.
- `tauri dev` runs two watchers: Vite reloads or hot-updates the page, and the Tauri CLI recompiles and restarts the app. A page reload keeps the Rust state.
- ts-rs derives TypeScript types from the Rust structs, serde attributes included; commit them and let CI check that they are current.
- A generated type can be wrong: ts-rs's default `bigint` for 64 and 128-bit integers does not match what serde_json sends.
- Types do not check command names and argument names: keep the `invoke` calls in one module, or use tauri-specta and accept a release candidate.

## Exercises

1. `QualityView` has two fields, `suffix` and `name`. Add `interval_count: u64` on the Rust side, run `cargo test`, and predict the TypeScript type of `intervalCount` before opening the file. Then make it a `number` without an attribute on the field.

<details>
<summary>Solution</summary>

ts-rs writes `interval_count: bigint`. Two surprises in one line: `u64` is one of the large integers that default to `bigint`, and the name keeps its underscore, because `QualityView` has no `#[serde(rename_all = "camelCase")]` and ts-rs follows serde.

Without touching the field, change the default for the whole workspace in `.cargo/config.toml`:

```toml
[env]
TS_RS_EXPORT_DIR = { value = "frontend/src/bindings", relative = true }
TS_RS_LARGE_INT = "number"
```

Then `cargo test` writes `interval_count: number`. The type is honest only while the value stays below 2<sup>53</sup>, which a count of intervals does.

</details>

2. A colleague renames the Rust command `spell_chord` to `spell` and updates `generate_handler!`. Which of these fail: `cargo test`, `tsc`, the Vitest tests with `mockIPC`, the application when clicking *Spell*?

<details>
<summary>Solution</summary>

- `cargo test`: fails only if a Rust test calls `spell_chord` by name, like the course's IPC tests in `src-tauri/tests/`; otherwise it passes.
- `tsc`: passes. `invoke<ChordView>("spell_chord", …)` is a string and a cast.
- Vitest with `mockIPC`: passes, since the mock answers whatever name it is given (lesson 21).
- The application: rejects with `Command spell_chord not found`.

Only a test that runs the real app, or tauri-specta's generated wrappers, would catch the rename before a user does.

</details>

3. Why does the course commit `frontend/src/bindings/` instead of ignoring it and generating it before each build?

<details>
<summary>Solution</summary>

- The frontend can then be built, type-checked and tested without a Rust toolchain: `npm run web:build` needs only Node.
- A pull request shows the TypeScript change next to the Rust change, so a reviewer sees what the frontend will receive.
- The cost is keeping them in sync, which CI enforces: after `cargo test`, a changed file in `frontend/src/bindings` fails the job.

</details>

## Sources

- [Tauri 2 — Vite](https://v2.tauri.app/start/frontend/vite/) and [Frontend configuration](https://v2.tauri.app/start/frontend/)
- [Tauri 2 — CLI reference, `dev` and `build`](https://v2.tauri.app/reference/cli/): the `--config` option
- [Tauri JavaScript API — `core`](https://v2.tauri.app/reference/javascript/api/namespacecore/)
- [Vite — Configuring Vite](https://vite.dev/config/) and [HMR API](https://vite.dev/guide/api-hmr)
- [ts-rs 12.0.1 documentation](https://docs.rs/ts-rs/12.0.1/ts_rs/): `TS_RS_EXPORT_DIR`, `TS_RS_LARGE_INT`, `#[ts(type = "…")]`
- [tauri-specta](https://github.com/specta-rs/tauri-specta) and its [2.0.0-rc.25 documentation](https://docs.rs/tauri-specta/2.0.0-rc.25/tauri_specta/)
- [MDN — `Number.MAX_SAFE_INTEGER`](https://developer.mozilla.org/docs/Web/JavaScript/Reference/Global_Objects/Number/MAX_SAFE_INTEGER)
