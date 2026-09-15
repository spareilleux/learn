---
title: Journal
description: Dated progress notes for the Advanced TypeScript course — the course project on TypeScript 7.0.2, the checker's limits measured, the predictions that the type tests proved wrong, the C# and Java side, bundle sizes, what the lessons found in GuitarAlchemist/ga, and items to verify.
sidebar:
  order: 99
---

## Progress

- [x] The course project: TypeScript 7.0.2, Zod 4.6.5, Valibot 1.5.0, ArkType 2.2.3 and esbuild 0.28.2 pinned in its own `package.json` and lock file
- [x] `check.sh`: type tests, error snippets, examples and solutions run with Node.js 24.21.0, bundle sizes, C# and Java comparisons, all compared with `expected/`
- [ ] CI on Linux, Windows and macOS
- [x] Lesson 1: type-level programming
- [x] Lesson 2: variance and assignability
- [x] Lesson 3: modeling with types
- [x] Lesson 4: runtime borders
- [ ] Lesson 5: declaration files

## 2026-09-15 — The course project

- The course has its own [`package.json`](https://github.com/spareilleux/learn/blob/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/package.json), separate from the base course's, with the same TypeScript and Node.js versions: 7.0.2 and 24.21.0. The [`tsconfig.json`](https://github.com/spareilleux/learn/blob/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/tsconfig.json) adds `exactOptionalPropertyTypes` and `noUncheckedIndexedAccess` to `strict`, since lesson 2 depends on the first, and keeps `erasableSyntaxOnly` so that Node.js runs every example directly, without a build step.
- The type tests live in the examples: `type _1 = Expect<Equal<…>>` lines that `tsc` checks with the whole project. A wrong prediction fails `check.sh` before anything runs, which happened several times while writing lessons 1 to 3, as listed below.
- `check.sh` is the base course's script with two additions: [`bundle-size.mjs`](https://github.com/spareilleux/learn/blob/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/bundle-size.mjs), whose output is compared like any other, and C# comparisons that reference ASP.NET Core with `#:sdk Microsoft.NET.Sdk.Web`.
- GA's repository doesn't check out completely on Windows: Playwright's `test-results/` folders are committed, with paths longer than 260 characters. A sparse clone of the folders the lessons use, with `git config core.longpaths true`, works.

## 2026-09-15 — The checker's limits, measured

- The limits are constants in [`internal/checker/checker.go`](https://github.com/microsoft/typescript-go/blob/2bd066d87f5bafd315be9f40889d0a60b9e58e0b/internal/checker/checker.go): 100 nested instantiations and 5,000,000 in one expression, 1,000 steps of a tail-recursive conditional type, and 100,000 members for a union built by a cross product.
- The measures match: a tail-recursive tuple builder reaches 999 elements and fails at 1,000 with `TS2589`; a union of five digit positions, 100,000 strings, fails with `TS2590`.
- A non-tail-recursive `Reverse` is harder to predict. Alone in its file, 48 elements pass and 49 fail. With `Reverse` of 40 elements evaluated first in the same file, 80 elements pass: instantiations are cached, and the second evaluation starts from the first one's results. A type-level limit measured in one file isn't a limit for another file.

## 2026-09-15 — Predictions the type tests proved wrong

- I expected `satisfies Record<GovernanceHealthStatus, HexColor>`, where `HexColor` is a template literal type, to widen the colors to `string`. It keeps the literal types: a template literal type as contextual type counts as a literal context, and only a contextual type such as `string` widens them.
- I expected a `const` type parameter with a mutable array constraint to fall back to `string[]`. That was the behavior of 5.0 to 5.2; since 5.3 it infers a mutable tuple. I checked with `npx -p typescript@5.0.4`, `5.2.2` and `5.3.3`.
- I expected `in out T` on a type that only reads `T` to be refused. It is accepted: `in out` makes a type invariant, which is always safe, and only an annotation that contradicts the structure, such as `in` on a type that returns `T`, is an error (`TS2636`).
- In the first version of lesson 3's state machine, a `stopFrom` function used `as` to make `send(state, 'stop')` compile for any state. The type test that I added afterwards showed that `EventOf<LiveState>` is `never`: the assertion hid that the `stopped` state has no `stop` event. The function now takes `Exclude<LiveState, 'stopped'>`, with no assertion.
- An object literal asserted with `as` to a type it lacks properties of isn't always accepted: directly, `tsc` reports `TS2352`; through a variable, the types are comparable and it compiles. Lesson 2 shows the second form, which is the one found in real code.

## 2026-09-15 — The C# and Java side

- `dotnet run file.cs` on a file that serializes an anonymous type failed with "Reflection-based serialization has been disabled for this application". File-based apps are published with native AOT by default, and that setting also disables reflection-based JSON at run time; `#:property PublishAot=false` in the file restores it.
- `JsonHubProtocol` can be used without a server: `WriteMessage` on an `InvocationMessage` gives the exact text that SignalR sends, which settled what GA's hub puts on the wire without starting it.
- `System.Text.Json`'s `RespectNullableAnnotations` and `RespectRequiredConstructorParameters`, both .NET 9, are off by default; with them, the C# record is a schema.

## 2026-09-15 — Bundle sizes

- The same Zod schema, bundled by esbuild, is 442.7 kB minified with `import { z } from 'zod'` and 87.4 kB with `import * as z from 'zod'`. The difference is tree shaking: `z` is an object that references every function. Lesson 4 keeps the namespace form, which is also the documentation's.
- Valibot, 4.8 kB minified, is about 18 times smaller than Zod for this schema, and `zod/mini` about 5 times.
- The sizes are measured on Windows. esbuild's output doesn't depend on the OS, and the CI compares them on Linux and macOS (*to verify* once the workflow has run).

## 2026-09-15 — What the lessons found in GuitarAlchemist/ga

At commit [`32f143c`](https://github.com/GuitarAlchemist/ga/tree/32f143c866c126338b332e384e4a615cd4b44381), in `ReactComponents/ga-react-components` and `Apps/ga-server/GaApi/Hubs`:

- **A lost `NodeChanged` update** (lesson 4). The hub sends `nodeId`; the client asserts the message to be a `GovernanceNode`, whose key is `id`; `updateNodeHealth` looks the node up by `id` and silently drops the update. A code search finds no caller of `BroadcastNodeChanged`, so the bug is latent.
- **No shared contract between the hub and the client** (lesson 1). The hub derives from `Hub`, not `Hub<T>`, and sends method names as strings; the client registers ten handlers with strings. The hub's documentation comment lists a `HealthUpdate` event that it never sends, and the client's option `onScreenshotRequest` handles the event `RequestScreenshot`.
- **`ViewerInfo.displayName`** (lesson 2) is declared `displayName?: string` in TypeScript and sent as `null` by the C# record; the code works because every read uses `?.` or `??`.
- **Two string numberings** (lesson 3): four interfaces named `FretboardPosition`, all with `string: number`; `InstrumentConfig.ts` and `GuitarFretboard.tsx` count strings from 0, while `VexTabViewer.tsx` and `InverseKinematics.tsx` take string numbers from 1.
- **The voice state of `ChatWidget.tsx`** (lesson 3): `isListening` and `voiceState` can disagree; `startListening` reads `voiceState` without listing it in its `useCallback` dependencies, so its `voiceState === 'listening'` checks see a stale value; `sendMessage(…).then(…)` has no `catch`, and a failed request can leave the state at `'processing'`.
- **Unchecked borders** (lesson 4): 42 `JSON.parse` calls, 55 lines that assert `response.json()` with `as`, and 34 `as unknown as`, outside tests.

I haven't reported these to the GA repository; they are listed here as found.

## To verify

- The `NodeChanged` path on a running server, if something starts calling `BroadcastNodeChanged`.
- The stale `voiceState` in `ChatWidget.tsx`, in a browser with speech recognition: an error while listening should leave the indicator on `'listening'`.
- The course's outputs on Linux and macOS, once the CI workflow runs.
