---
title: Journal
description: Dated progress notes for the TypeScript course — installing TypeScript 7.0.2, the CI on three OSes, surprises in tsc, Node.js and dotnet, what tsc found in GuitarAlchemist/ga's front ends and in this site, and items to verify.
sidebar:
  order: 99
---

## Progress

- [x] TypeScript 7.0.2 pinned in the course's own `package.json` and lock file, with `@types/node` 24.13.4 and tsx 4.23.13
- [x] CI: `tsc` on the project and on each error snippet, every example and solution run with Node.js 24.21.0, the C# and Java comparisons compiled and run, all compared with their expected output on three OSes
- [x] Lesson 1: the compiler and the tooling
- [x] Lesson 2: structural typing
- [x] Lesson 3: unions and narrowing
- [x] Lesson 4: generics
- [ ] Lesson 5: type-level programming

## 2026-09-14 — Installing TypeScript 7.0.2

- `npm view typescript version` gives 7.0.2, the Go port, published on 2026-07-08. The `typescript` package is now small: npm installs the compiler as one package per platform, `@typescript/typescript-win32-x64` on my machine, and the CI's info step lists `typescript-linux-x64` on Linux and `typescript-darwin-arm64` on macOS. The lock file lists all twenty platform packages as optional dependencies, so `npm ci` works on the three OSes from the one lock file written on Windows.
- TypeScript 7.0 has no programmatic API yet. Tools that load the compiler as a library can use `@typescript/typescript6`, a compatibility package that provides TypeScript 6.0 with a `tsc6` command; I didn't need it for the course.
- The course pins its versions in [`code/typescript-for-csharp-java/package.json`](https://github.com/spareilleux/learn/blob/main/code/typescript-for-csharp-java/package.json), not in the site's: the site itself has no `typescript` dependency.
- npm 11.19 no longer runs install scripts by default. Installing tsx printed `npm warn install-scripts esbuild@0.28.2 (postinstall: node install.js)`, and tsx works anyway, on the three OSes: esbuild's binary comes from a platform package installed as an optional dependency.

## 2026-09-14 — The CI

- [`typescript-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/typescript-examples.yml) installs Node.js 24.21.0, .NET 10 and Java 25, runs `npm ci` in the course folder, then [`check.sh`](https://github.com/spareilleux/learn/blob/main/code/typescript-for-csharp-java/check.sh) with `REQUIRE_COMPARE=1`, so that a missing `dotnet` or `java` fails the run instead of skipping the comparisons.
- `check.sh` runs `tsc` once on the whole project, which must pass, and once per error snippet, with a generated `tsconfig` that extends the course's and lists that one file; a snippet can ask for extra options with a `// tsc options:` comment, as lesson 2's `noUncheckedIndexedAccess` does. [`normalize.mjs`](https://github.com/spareilleux/learn/blob/main/code/typescript-for-csharp-java/normalize.mjs), adapted from the JavaScript course, makes paths relative and removes stack frames and process IDs.
- The first run failed on the three OSes, on two files only, and for the same reason: the C# warnings `CS8602` and `CS8509` were in the CI's output and not in mine. `dotnet run file.cs` builds a file-based program incrementally, and a second run with an unchanged source doesn't call the compiler, so its warnings are printed only once. `check.sh` now runs `dotnet clean` on the file before `dotnet run --no-cache`, and the outputs captured on Windows match on Linux and macOS. The next run passed on the three OSes in 2 minutes 41 seconds, Windows being the slowest job.

## 2026-09-15 — Surprises while writing lessons 1-4

**`tsc`'s exit code changed between 6.0 and 7.0.** With `--noEmit` and errors, `tsc` 6.0.3 returns 2, and 7.0.2 returns 1. In 7.0.2, 1 means that errors prevented the output, with `noEmit` or `noEmitOnError`, and 2 that the output was written despite errors, which lesson 1 shows with `l01-emit`. A CI step that tests `$? -eq 2` would break on the upgrade; test for a non-zero code.

**`tsc file.ts` next to a `tsconfig.json` is an error since 6.0.** `TS5112` refuses to ignore the configuration silently, as older versions did; `--ignoreConfig` restores the old behavior. `check.sh` builds a small `tsconfig` for each error snippet instead.

**Union members don't print in declaration order.** The same comparison in GA's `ForceRadiant.tsx` prints `"warning" | "error" | "unknown" | "contradictory"` with 5.9.3 and `"contradictory" | "error" | "unknown" | "warning"` with 7.0.2. The [6.0 release notes](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-6-0.html#the---stabletypeordering-flag) explain it: TypeScript 7 sorts types by content so that parallel checkers agree. Lesson 3's expected outputs are those of 7.0.2 only.

**A wrong `out` annotation compiles.** I wrote `interface Mislabeled<out T> { accept(value: T): void }` for lesson 4's error snippet, expecting an error, and `tsc` 7.0.2 accepted it: `accept` is a method, method parameters are bivariant, and `T` in that position satisfies both annotations. C# reports the same interface with `CS1961`. The snippet now uses the mistake that `tsc` does catch, `in T` on a method that returns `T` (`TS2636`).

**`Array.isArray` brings `any` back.** In the solution of lesson 2's second exercise, the value was `unknown`, and `Array.isArray(value)` narrowed it to `any[]`: `item.name` compiled without a check. The solution's `typeof` checks make it correct; `tsc` didn't ask for them. Lesson 2 points it out.

**Node.js prints the stripped line.** When a `.ts` file fails at run time, the source line in Node.js's message has spaces where the types were, as in lesson 4's `const guitarSource                 = instrumentSource;`. That is how type stripping keeps line and column numbers.

**`module.stripTypeScriptTypes` still prints an `ExperimentalWarning` in 24.21.0**, although type stripping itself is stable and silent; lesson 1 shows the warning.

## 2026-09-15 — What tsc found in GuitarAlchemist/ga (a826864)

I cloned [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga) at [`a826864`](https://github.com/GuitarAlchemist/ga/commit/a826864f3a012cad88e415954bf57eca0ce12aa6) into a scratch folder, installed the two front ends, and ran `tsc` with 5.9.3, the version that the component library's `pnpm-lock.yaml` resolves, and with 7.0.2.

- **Names used and never defined.** [`Apps/ga-client/src/components/Chat/ChatInterface.tsx`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/ga-client/src/components/Chat/ChatInterface.tsx#L219) uses `VIRTUALIZATION_THRESHOLD` (lines 69 and 219) and `VirtualizedMessageList` (lines 254 and 255), and nothing defines or imports them: `TS2304`. The `/ai-copilot` route of [`App.tsx`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/ga-client/src/App.tsx#L105) loads that component, so the page should throw a `ReferenceError` when it renders (*to verify* in a browser). Reproduction: `cd Apps/ga-client && npm ci && npx tsc -b --pretty false | grep ChatInterface`. This looks like a bug worth an issue.
- **Type errors don't fail the build.** Both front ends build with `vite build`, which strips types without checking them; `ga-client` reports 346 errors with `tsc -b` (165 of them `TS6133`, unused variables), and `ga-react-components` 186. A `tsc --noEmit` step in CI would have caught the missing names.
- **A stale lock file.** In `ReactComponents/ga-react-components`, `pnpm install --frozen-lockfile` fails with `ERR_PNPM_OUTDATED_LOCKFILE`: 21 dependencies of `package.json` are missing from `pnpm-lock.yaml`, and the versions of `@react-three/drei` and `@react-three/fiber` differ. I installed without `--frozen-lockfile`, so the component library's error counts may depend on the versions I got.
- **Statuses that the type rules out.** [`ForceRadiant.tsx`, lines 721 and 725](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/PrimeRadiant/ForceRadiant.tsx#L720-L729), compares a `GovernanceHealthStatus` with `'ok'` and `'critical'`, which the union doesn't contain (`TS2367`), and [`DataLoader.ts`, lines 276-278](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/PrimeRadiant/DataLoader.ts#L276-L278), passes a SignalR message's `healthStatus: string` through `as unknown as GovernanceNode`. Either the union is missing two statuses or the comparisons are dead code (*to verify* in GA's hub). Line 1464 of the same file compares a signal severity, `'info' | 'warning' | 'emergency'`, with `'critical'`. Lesson 3 reduces the first case.
- **`noImplicitAny: false` next to `strict: true`** in [`ga-react-components/tsconfig.app.json`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/tsconfig.app.json#L17-L20). Turning it back on adds only four errors, in `BSPDoomExplorer.tsx` and `IxqlFormPanel.tsx`; lesson 2 lists them.
- **Unchecked data.** The component library has 34 `as unknown as`, 42 calls to `JSON.parse` and 18 `as any`. The camera is restored from `localStorage` with `JSON.parse(saved) as { px: number; … }` ([`ForceRadiant.tsx`, line 3558](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/PrimeRadiant/ForceRadiant.tsx#L3555-L3561)), `loadQueue<T>` returns `JSON.parse` as a `T[]` ([`CourseViewer.tsx`, line 152](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/PrimeRadiant/CourseViewer.tsx#L152-L159)), and `ga-client`'s `isApiResponse<T>` checks two property names before promising an `ApiResponse<T>`, with `json as T` as its fallback ([`musicService.ts`, lines 17-49](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/ga-client/src/services/musicService.ts#L17-L49)). Lessons 3 and 4 and their exercises write the checked versions.
- **TypeScript 7 finds more.** `tsc -p tsconfig.app.json` on the component library gives 180 errors in 14.7 seconds with 5.9.3 and 197 in 1.9 seconds with 7.0.2. The new errors are Node.js names in two scripts (`TS2591`, because `types` now defaults to `[]`), `TS2871` ("this expression is always nullish") in `BrainstormPanel.tsx` line 40 and `GitHubPollingManager.ts` line 48, and `TS2550` for `.at()` in `ChatWidget.tsx` line 1254, with `lib` set to ES2020; 5.9.3 reported neither code.
- **Small things.** `ga-client/tsconfig.json` has `"sourceMaps": true` at its top level, where `tsc` ignores it; the option is `sourceMap`, inside `compilerOptions`. `src/components/PrimeRadiant/index.ts` in the component library exports `RemediationAction` twice (`TS2300`, lines 101 and 129), and `ThreeFretboard.tsx` line 780 uses a `GuitarModelStyle` type that doesn't exist. `ga-client`'s `ShowcasePanel.test.tsx` uses Node.js's `global`, which the browser project's types don't declare.

## 2026-09-15 — What tsc found in this site (8ba378e)

`npx -p typescript@7.0.2 tsc --noEmit` at commit [`8ba378e`](https://github.com/spareilleux/learn/commit/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3), with the site's `tsconfig.json`, reports three errors, the same with 6.0.3. None breaks the site.

- `astro.config.mjs`, line 146: the sidebar imported from `src/streeling-sidebar.json` doesn't match Starlight's `SidebarItemUserConfig`, because the inferred union of its entries adds `fr?: undefined` to the entry that has only a Spanish translation. Lesson 3 explains the inference.
- `code/javascript-for-csharp-java/errors/l04_private_outside.js`: the site's `tsconfig.json` includes `**/*`, so `tsc` checks the course code, including an error snippet that is wrong on purpose. The TypeScript course's `errors/*.ts` will be picked up the same way; excluding `code/` in the site's `tsconfig.json` would keep editors and `tsc` on the site's own files.
- `src/content.config.ts`: `astro:content` is declared only after `astro sync`.

## To verify

- The `ReferenceError` on GA's `/ai-copilot` page, in a browser.
- Whether GA's governance hub sends `ok` and `critical` as health statuses.
- What GA's `ForceRadiant` does with a saved camera that lacks a coordinate.
- `new[] { 1, "two", null }` in C#, quoted in lesson 2 as refused for lack of a best common type.
- The installation commands of lesson 1 on Linux and macOS outside CI.
