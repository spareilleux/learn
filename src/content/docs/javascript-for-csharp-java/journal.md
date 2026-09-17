---
title: Journal
description: Dated progress notes for the JavaScript course — installing Node.js 24.21.0, the CI on three OSes, surprises in Node.js and npm, what GuitarAlchemist/ga's front end showed, and items to verify.
sidebar:
  order: 99
---

## Progress

- [x] Node.js 24.21.0 installed on Windows, and in CI on Linux, Windows and macOS with .NET 10 and Java 25
- [x] CI: examples, error snippets, solutions and the C# and Java comparisons compared with their expected output on three OSes
- [x] Lesson 1: Node.js, npm and modules
- [x] Lesson 2: values and types
- [x] Lesson 3: functions, scope, closures and `this`
- [x] Lesson 4: objects, prototypes and classes
- [ ] Lesson 5: arrays, iteration and collections

## 2026-09-14 — Installing Node.js 24.21.0

- The [release index](https://nodejs.org/dist/index.json) lists 24.21.0, published on 2026-09-07, as the latest LTS release, and 26.8.2 as the latest current release. Node.js 26 becomes LTS on 2026-10-28, according to the [schedule](https://github.com/nodejs/Release/blob/72fdab20216c5f04e0a0fe72a225c2504e9f2b42/schedule.json).
- My machine already had a global Node.js 24.12.0. I left it alone, downloaded `node-v24.21.0-win-x64.zip` into a folder of its own, checked its SHA-256 against `SHASUMS256.txt`, and put that folder first on the `PATH` of the shells that capture the lessons' outputs. `node -p process.versions.v8` prints `13.6.233.17-node.53`; the bundled npm is 11.19.0.
- The PowerShell commands of lesson 1 downloaded, checked and expanded the archive in 22 seconds, in a scratch folder.
- `winget show OpenJS.NodeJS.LTS` offered 24.19.0, two releases behind nodejs.org.

## 2026-09-14 — The CI

- [`javascript-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/javascript-examples.yml) installs Node.js 24.21.0 with `actions/setup-node@v7`, .NET 10 and Java 25, and runs [`check.sh`](https://github.com/spareilleux/learn/blob/main/code/javascript-for-csharp-java/check.sh). The first push passed on the three OSes in 1 minute 28 seconds: the 52 outputs captured on Windows are identical on Linux and macOS.
- Node.js prints absolute paths in its errors, as a file URL, a Windows path, or even a Windows path with the `\\?\` long-path prefix, as in the message about `package.json` in lesson 1. [`normalize.mjs`](https://github.com/spareilleux/learn/blob/main/code/javascript-for-csharp-java/normalize.mjs) makes them relative to the course folder, removes the stack frames and replaces process IDs.
- The C# comparison first printed `1.0 / 0` as `∞`, the infinity symbol of my culture's number format; it now sets `CultureInfo.InvariantCulture`, which prints `Infinity` on every machine. Java printed the guitar emoji as `?` in the Windows console, so the comparison programs print only ASCII.
- The CI also installs `@esbuild/win32-x64@0.25.12` as a development dependency on each OS, for lesson 1: npm installs it on Windows and stops with `EBADPLATFORM` on Linux and macOS.

## 2026-09-14 — Surprises while writing lessons 1-4

**Node.js's "Did you mean to import" hint depends on the current folder.** An ES module import without its extension fails with `ERR_MODULE_NOT_FOUND`, and Node.js adds a hint with the right path, but only when the command runs from a folder where that relative path also exists. `resolveAsCommonJS` creates a CommonJS parent module whose file name is never set ([`resolve.js`, lines 888-895](https://github.com/nodejs/node/blob/v24.21.0/lib/internal/modules/esm/resolve.js#L888-L895)), and for a parent without a file name the CommonJS resolver looks from `'.'` ([`loader.js`, lines 1021-1028](https://github.com/nodejs/node/blob/v24.21.0/lib/internal/modules/cjs/loader.js#L1021-L1028)). The code is the same on Node.js's `main` branch. I found no issue about it with a search for "Did you mean to import" in nodejs/node. `check.sh` runs the error snippets from their own folder, and runs this one a second time from the course folder, without the hint.

**A duplicate function is an error at the top of a module only.** Two `function describe` declarations in the same ES module are a `SyntaxError` before anything runs; the same two declarations inside a function body, or at the top of a CommonJS file, are accepted, and the second one wins. I had written the duplicate at the top level of the lesson 3 example to show the silent replacement, and got the error instead.

**`[1, 2, 3].map(multiply)` prints `[ 0, 2, 6 ]`.** I passed `multiply` to `map` as a harmless example that functions are values, and `map` passed the index as the second argument. The example stayed in lesson 3, as the trap it is, next to `['1', '2', '3'].map(parseInt)`.

**`npm init -y` writes `"type": "commonjs"`.** npm 11.19 adds the field explicitly; older templates left it out, which made `.js` files CommonJS by default all the same.

**A `.cjs` file with `import` gets advice that doesn't apply.** Node.js prints `Warning: Failed to load the ES module … Make sure to set "type": "module" in the nearest package.json file or use the .mjs extension`, then the `SyntaxError`. The `"type"` field can't help a `.cjs` file: its extension wins.

**`require` of an ES module works without a warning.** Node.js 24.21.0 loads `modern.mjs` from `from-cjs.cjs` silently; the [documentation](https://nodejs.org/docs/latest-v24.x/api/modules.html#loading-ecmascript-modules-using-require) says the feature stopped being experimental in 24.15.0. With a top-level `await` in the module, `require` throws `ERR_REQUIRE_ASYNC_MODULE`, which I checked for the solution of exercise 1.

**pnpm doesn't check the platform of a direct dependency.** In a scratch project on Windows, `npx pnpm@10 add -D @esbuild/linux-x64@0.25.12` installed the Linux package without a warning (pnpm 10.34.5), where npm refuses it with `EBADPLATFORM`.

## 2026-09-14 — What GuitarAlchemist/ga's front end showed (a826864)

I read [`ReactComponents/ga-react-components`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components) and [`Apps/ga-client`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/ga-client) at commit [`a826864`](https://github.com/GuitarAlchemist/ga/commit/a826864f3a012cad88e415954bf57eca0ce12aa6), looking for the traps of lessons 1 to 4.

- **Two lock files.** `Apps/ga-client` has a `package-lock.json` and a `pnpm-lock.yaml`; nothing keeps the two resolutions in agreement.
- **A Windows-only package in `devDependencies`.** [`ga-react-components/package.json`, line 71](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/package.json#L71) lists `@esbuild/win32-x64`. The course's CI shows that npm refuses that exact package on Linux and macOS; the folder only has a `pnpm-lock.yaml`, and pnpm installed a foreign platform package without complaint on my machine, so the project probably installs with pnpm everywhere (*to verify* on Linux).
- **A saved state that beats the URL.** In [`SceneOptions.tsx`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/PrimeRadiant/SceneOptions.tsx#L57-L80), the URL parameters are applied before `Object.assign` merges the preferences saved in `localStorage`, and every toggle saves every key. After the first toggle, `?tower`, `?constellations`, `?weather`, `?skybox` and `?splats` no longer change anything. The merge also keeps unknown keys and values of the wrong type, and a `__proto__` key replaces the state object's prototype. Lesson 4 reproduces the three, and its exercise 3 fixes them. This looks like a bug worth an issue.
- **`|| 0.5` where `??` is meant.** [`BSPDoomExplorer.tsx`, line 4895](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/BSP/BSPDoomExplorer.tsx#L4895) would turn a rotation speed of 0 into 0.5. No sample gets a speed of 0 today, so it is latent. [Line 5386](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/BSP/BSPDoomExplorer.tsx#L5386) works because `NaN` is falsy, not because of the grouping it seems to have.
- **Event listeners are right.** The seven `addEventListener` calls of the two front ends that pass a `this.…` handler use either a function bound once and stored, or an arrow function stored in a field, and none binds inline; lesson 3 runs the three patterns.
- **Loose equality only for `null`.** The TypeScript sources use `==` and `!=` only as `== null` and `!= null`; the other matches are GLSL shader code in strings. Their ESLint configurations extend `js.configs.recommended`, which doesn't enable `eqeqeq`.
- **`parseInt` without a radix**, in [`BSPDoomExplorer.tsx`, line 2421](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/BSP/BSPDoomExplorer.tsx#L2421) and [`MusicRoomLoader.ts`, lines 209-211](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/BSP/MusicRoomLoader.ts#L209-L211). The inputs are decimal digits from a name or a regular expression match, so it is harmless there.

## To verify

- The installation commands I haven't run: `winget install OpenJS.NodeJS.LTS`, nvm on Linux, and Homebrew's `node@24` on macOS.
- Whether `pnpm install` of `ga-react-components` succeeds on Linux and macOS with `@esbuild/win32-x64` in its development dependencies.
