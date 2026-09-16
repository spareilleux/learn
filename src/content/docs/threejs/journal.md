---
title: Journal
description: Dated progress notes for the three.js course — pinning three.js r186, Vite 8.3 and Playwright 1.63, measuring WebGPU pages in headless Chromium on three OSes, what the CI runners really render with, surprises in @types/three and DRACOLoader, what the course found in GuitarAlchemist/ga's 3D code, and items to verify.
sidebar:
  order: 99
---

## Progress

- [x] three 0.186.0, `@types/three` 0.186.0, Vite 8.3.0, TypeScript 7.0.2, Playwright 1.63.0 and glTF Transform 4.5.0 pinned in the course's own `package.json` and lock file
- [x] `check.sh`: type-checking, the Node.js scripts, every lesson page probed in headless Chromium, the production build, compared with `expected/`
- [x] CI on Ubuntu, Windows and macOS
- [x] Lesson 1: scene, camera, renderer
- [x] Lesson 2: geometries, materials, lights and shadows
- [x] Lesson 3: color, tone mapping and HDR environments
- [x] Lesson 4: glTF models and animations
- [ ] Lesson 5: interaction, `Raycaster` and camera controls

## 2026-09-16 — Versions

- `npm view three` gives 0.186.0, released on 8 September 2026, and `@types/three` 0.186.0. The course pins them exactly in [`code/threejs/package.json`](https://github.com/spareilleux/learn/blob/8e8f303/code/threejs/package.json), with Vite 8.3.0, TypeScript 7.0.2, Playwright 1.63.0 and its Chromium 153, glTF Transform 4.5.0, `draco3dgltf` 1.5.7, `meshoptimizer` 1.2.0 and `pngjs` 7.0.0, on Node.js 24.21.0 in CI.
- Release r186 is the npm version `0.186.0`. The lessons cite the source at the `r186` tag of [mrdoob/three.js](https://github.com/mrdoob/three.js/tree/r186).
- `require('three/package.json')` fails: the package's `exports` map doesn't list it. The version check in `check.sh` reads the file with `fs` instead.
- The documentation pages are at `https://threejs.org/docs/pages/<Class>.html` and `https://threejs.org/manual/pages/<page>.html`; the lessons link those URLs, all checked.

## 2026-09-16 — Measuring pages in a headless browser

- Each lesson page reports what the renderer did through a `window.probe` promise, and [`scripts/probe.mjs`](https://github.com/spareilleux/learn/blob/8e8f303/code/threejs/scripts/probe.mjs) starts Vite, opens the page with Playwright at 800 by 450 pixels and a pixel ratio of 1, and prints the report. Pages that animate use fixed steps when probed, so the third frame is the same on every machine.
- My first probe hung on the `WebGLRenderer` page: the page replaced `window.probe` after `page.evaluate` had started to wait for the old promise. The pages now resolve a promise created once, in [`src/probe.ts`](https://github.com/spareilleux/learn/blob/8e8f303/code/threejs/src/probe.ts), and `probe.mjs` gives up after 30 seconds.
- Colors are read from the screenshot, at the positions the page reports.
- Playwright's default headless mode on Windows gives WebGPU on the author's RTX 5080 ("nvidia, blackwell"). `chromium-headless-shell`, the lighter build, has no WebGPU adapter: `WebGPURenderer` falls back to WebGL 2, on SwiftShader. `check.sh` runs lesson 1 in both.

## 2026-09-16 — What the CI runners render with

- The first CI run, [35114590607](https://github.com/spareilleux/learn/actions/runs/35114590607), failed on all three OSes, for three reasons: the `coordinateSystem` reported by the page follows the backend; a few colors differ by one from the author's GPU; and on macOS, Vite's warning, on stderr, came before its stdout lines. The probes now filter the backend-dependent lines, [`compare.mjs`](https://github.com/spareilleux/learn/blob/8e8f303/code/threejs/scripts/compare.mjs) accepts a difference of 2 per channel in colors, and the build's stderr is printed after its stdout.
- Run [35115118564](https://github.com/spareilleux/learn/actions/runs/35115118564) passed. Its logs show what each runner draws with. `ubuntu-24.04` and `windows-2025-vs2026` have no GPU: WebGPU is unavailable, and both `WebGPURenderer` and `forceWebGL` run WebGL 2 on SwiftShader (Subzero). `macos-26-arm64` has WebGPU, on an "apple" adapter, and WebGL 2 on "ANGLE Metal Renderer: Apple Paravirtual device"; its headless shell uses SwiftShader (LLVM 10.0.0).
- Two colors differ by one on the runners: ACES maps linear 0.18 to 127 on the author's GPU and 128 in CI, and Neutral maps 0.05 to 33 and 34.
- So a green CI run proves that the scenes build, load, and produce the same counts and colors, within 2, on a software rasterizer and on Apple's GPU. It doesn't prove anything about WebGPU on Windows or Linux.

## 2026-09-16 — Surprises

- **`WebGPURenderer` counts one more draw call than the scene has.** With tone mapping, or with an output color space different from the working space, it renders the scene into a target and draws the result in an output pass: 2 draw calls and 13 triangles for one cube. `WebGLRenderer` converts in each shader and reports 1. The two renderers' `info` objects also have different shapes.
- **`@types/three` describes `toJSON()` wrongly.** In 0.186.0, `Object3DJSON` declares `children` as strings and has no `geometries` or `materials`, while the runtime writes objects and both arrays. Lesson 1 keeps the compiler errors in [`errors/l01_tojson_types.ts`](https://github.com/spareilleux/learn/blob/8e8f303/code/threejs/errors/l01_tojson_types.ts). I haven't looked for an existing issue in three-types/three-ts-types, and haven't opened one.
- **The shadow camera's box is read once by `WebGPURenderer`.** `ShadowNode` calls `updateProjectionMatrix()` when it builds the shadow; a change after that needs your own call.
- **`PCFSoftShadowMap` is gone from `WebGPURenderer` in r186** and warns. GA's `LunarLanderEngine.ts` and `MinimalThreeInstrument.tsx` still use it with `WebGPURenderer`.
- **A point light of 800 lumens is 63.66 candela, and a spot light of 800 lumens 254.65**: `SpotLight.power` uses π, not 4π, and doesn't change with the cone's angle.
- **The PMREM costs 17 renders** for a 256 by 128 environment: 1 into the first level, then 2 for each of the 8 others. It happens even when `scene.environment` is a plain equirectangular texture.
- **Since r185, `DRACOLoader` finds its decoders with `import.meta.url`**, which r184 didn't. Vite then copies all five decoder files into the build, 1.31 MB, when a browser loads two. The build also warns that `three.webgpu` is over 500 kB.
- **Draco and meshopt drop vertices.** Both drop the two pole vertices that `SphereGeometry` creates and no triangle uses; Draco's `weld()` also merges the non-indexed body's corners.
- glTF Transform's `meshopt()` prints `prune: Removed types... Accessor` lines on stdout; they are in `expected/` as they are.

## 2026-09-16 — GuitarAlchemist/ga

The course reads GA at commit [`05c8eda`](https://github.com/GuitarAlchemist/ga/tree/05c8eda013f2a4d11efaa52c4ca94674521ee684), which uses three 0.180. 139 files under `src` directories import three; 33 of them call `requestAnimationFrame`, 3 `setAnimationLoop`; 29 create a `WebGLRenderer` and 8 a `WebGPURenderer`; 15 use `Clock`, deprecated in r183. Nothing below has been reported to GA.

- `ThreeFretboard.tsx` expects `WebGPURenderer` to throw when WebGPU is missing, and says "Using WebGPU renderer" on every machine, since the renderer falls back to WebGL 2 instead (lesson 1). Its shadows are enabled only for a `WebGLRenderer`, so the fallback path gets none (lesson 2).
- `ThreeFretboard.tsx` asks for `samples: 8`; the WebGPU specification allows 1 or 4 samples for a texture. What r180 does with 8 on each backend is *to verify*.
- Its point light of 0.6 cd with `distance: 20` gives about 5 % of the main light where it is closest to the neck (lesson 2), and a single canvas texture serves as color, roughness, normal and bump map.
- Its wood texture has no `colorSpace`, so it shows lighter than painted, and its environment is an 8-bit gradient whose PMREM the renderer builds anyway (lesson 3). How much the wood color differs on screen is *to verify* in a browser.
- `Guitar3D.tsx` builds a black environment with `fromScene` on a scene that holds only an ambient light, and announces KTX2 and meshopt support without setting either decoder (lessons 3 and 4).
- `Ocean.tsx` loads Draco's decoders from gstatic.com; `DemerzelFaceOverlay.tsx` hides KTX2 errors by replacing `console.error` during a load; `HandAnimationTest.tsx` updates an `AnimationMixer` that has no action (lesson 4).
- For later lessons: `Ocean.tsx` uses `PostProcessing`, renamed `RenderPipeline` in r183; 16 files use `ShaderMaterial` or GLSL, and 10 use `EffectComposer`, which `WebGPURenderer` doesn't support; `Experiments/ThreeJS-BSP-Loader` imports `WebGPURenderer` from a path removed in r167; the dashboard's embedding viewer removes a resize listener with a new `bind`, which removes nothing.

## To verify

- Whether a scene modeled in centimeters needs lights 10,000 times stronger to look the same as in meters (lesson 2).
- KTX2 textures: loading, GPU formats chosen on each OS, memory (lesson 8).
- Draco against meshopt on a large model and on many small ones, over a real network (lesson 4, exercise 3).
- WebGPU on a Linux or Windows machine with a GPU, outside the author's.
