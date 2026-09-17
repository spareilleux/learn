---
title: Journal
description: Dated progress notes for the three.js course — pinning three.js r186, Vite 8.3, Playwright 1.63, React Three Fiber 9, Rapier 0.20 and IWER, measuring WebGPU pages in headless Chromium on three OSes, what the CI runners really render with, surprises in @types/three and DRACOLoader, what the course found in GuitarAlchemist/ga's 3D code, and items to verify.
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
- [x] Lesson 5: interaction, `Raycaster` and camera controls
- [x] Lesson 6: TSL and node materials
- [x] Lesson 7: post-processing with `RenderPipeline`
- [x] Lesson 8: performance, measured
- [x] Lesson 9: React Three Fiber and drei
- [x] Lesson 10: physics with Rapier in WebAssembly
- [x] Lesson 11: WebXR, emulated
- [x] Lesson 12: tests and CI
- [x] Lesson 13: project, GuitarAlchemist's 3D guitar neck
- [x] Course complete
- [x] Live demos: every lesson page and five complete scenes, published under the site with a *Try it* panel

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
- `Experiments/ThreeJS-BSP-Loader` imports `WebGPURenderer` from a path removed in r167; the dashboard's embedding viewer removes a resize listener with a new `bind`, which removes nothing.
- `ThreeHeadstock.tsx` adds a click listener to the same canvas on each run of its effect and never removes it; `TonalOrbit.tsx` and `MinimalThreeInstrument.tsx` raycast on every mouse event, the second with a new `Raycaster` each time; Prime Radiant's `InteractionHandler.ts` does it the lesson's way; 4 of the 25 files with `OrbitControls` never dispose them (lesson 5).
- The GLSL sky of `Sunburst3D.tsx`, copied in `ImmersiveMusicalWorld.tsx`, can't run on `WebGPURenderer`; `FresnelGlowTSL.ts` bakes its corona's intensity and color into the shader as constants; `MoebiusPassTSL.ts` is a GLSL `ShaderPass` despite its name (lesson 6).
- `Ocean.tsx` and `LunarLanderEngine.ts` use `PostProcessing`, renamed `RenderPipeline` in r183, and `Ocean.tsx` never disposes the pipeline or its nodes; `ForceRadiant.tsx` runs on `WebGPURenderer` without the bloom and `ShaderPass` effects of its WebGL path, a "follow-up task"; the 10 files with `EffectComposer` use it correctly for WebGL (lesson 7).
- `ThreeFretboard.tsx` creates a geometry and a material per fret and per marker, rebuilds its scene whenever its `positions` prop is a new array, including the default `[]`, and doesn't dispose its 29 sprites; `NodeInstancer.ts` instances its nodes well, with culling turned off; GA uses neither `BatchedMesh` nor `THREE.LOD` (lesson 8).

## 2026-09-16 — Lessons 5 to 8: pointers, shaders, effects, counts

- **Real pointer events in a headless page.** [`scripts/probe.mjs`](https://github.com/spareilleux/learn/blob/8bf126b/code/threejs/scripts/probe.mjs) now performs the moves and drags a page lists, with Playwright's mouse, and asks the page what it saw after each one. Chromium turns them into `pointermove`, `pointerdown` and `pointerup` events, which `OrbitControls` handles as it would a user's: a 120-pixel drag turned the camera by 96°.
- **A camera outside the scene has a stale matrix in a script.** The first version of `l05-raycaster.ts` projected a point to an NDC of −3.6: rendering updates the camera's world matrix, and a Node.js script doesn't render. `camera.updateMatrixWorld()` fixed it.
- **A shared stylesheet is part of every chunk's hash.** Adding lesson 5's layout rules to `page.css` changed the names of all the build's chunks, including the `04-gltf-CCDSPzCq.js` that lesson 4 quotes. Lesson 5 got its own stylesheet, and `check.sh` builds the pages of lessons 1 to 4 alone, with a `PAGES` filter, before building everything: with the pages of lessons 5 to 8, Rolldown names the shared WebGPU chunk `three.tsl` instead of `three.webgpu`.
- **`PostProcessing` is `RenderPipeline` since r183, and `pipeline.dispose()` frees one material.** The bloom's 11 render targets and the scene pass's one stay until the nodes themselves are disposed.
- **`DirectRenderPipeline.render` takes the scene and the camera**, unlike `RenderPipeline.render()`, so TypeScript rejects it in a `RenderPipeline` variable; and it draws a solid background as a sphere of 1,984 triangles.
- **`renderer.info.render` adds up across `render()` calls within one animation frame.** A page that rendered 60 frames in a loop to time them reported 610,061 draw calls; lesson 8 reads the counts first.

## 2026-09-16 — The CI runners and lessons 5 to 8

- Run [35123228046](https://github.com/spareilleux/learn/actions/runs/35123228046) passed on macOS (WebGPU on the "apple" adapter) and failed on Linux and Windows, where `WebGPURenderer` falls back to WebGL 2 on SwiftShader. Four differences, all real:
  - The bloom chains count one more program on WebGL 2: 14 instead of 13, 16 instead of 15.
  - With FXAA, SwiftShader's halo pixel is 135, 176, 197, where the author's GPU gives 132, 174, 195 on both backends: 3 more than `compare.mjs` accepts.
  - A `BatchedMesh` is drawn with `WEBGL_multi_draw` and counted as 2 draw calls, not 10,001.
  - The WebGPU shader file holds GLSL, since the page ran on WebGL 2.
- Lesson 8's pages with 800,000 triangles timed out: the probe result arrived, but Playwright's screenshot waited more than 30 seconds behind the 60 timed frames still queued in the software rasterizer.
- The fix: `check.sh` compares a probe with `expected/<name>.webgl.txt` when that file exists and the page ran on WebGL 2. The five files come from `chromium-headless-shell` on the author's machine, whose SwiftShader gave the same values as the runners. The GLSL line is compared, and the WGSL line only printed. Lesson 8 times 20 frames, and its probes wait up to 240 seconds (`PROBE_TIMEOUT`). Run [35124756498](https://github.com/spareilleux/learn/actions/runs/35124756498) passed on the three OSes.

## 2026-09-16 — Lessons 9 to 13: versions

- React 19.3.0 came out on 9 September 2026, but `@react-three/fiber` 9.7.0 declares `react` `>=19 <19.3`: the course pins React 19.2.8, with drei 10.7.8. R3F 10 and drei 11 are alphas. `@react-three/test-renderer` 9.1.1 and Vitest 5.0.1 test the components.
- Rapier 0.20.0 was published on 8 August 2026. three.js r186's `RapierPhysics` addon still loads 0.17.3 from skypack.dev, and `@react-three/rapier` 2.2.0 pins 0.19.2. The course uses both `@dimforge/rapier3d-compat` and `@dimforge/rapier3d-deterministic-compat`; their classes have private members, so TypeScript refuses one module's type for the other without a cast.
- IWER 2.4.0 emulates a Quest 3; pixelmatch 7.2.0 compares screenshots.

## 2026-09-16 — Lessons 9 to 13: what the pages found

- **R3F 9.7.0 warns on `WebGPURenderer` without being asked.** `<Canvas>`'s `shadows` defaults to `false`, and R3F sets `PCFSoftShadowMap` for any boolean; `WebGPURenderer` resets it with a warning, once per render of `<Canvas>`. Its store also creates a deprecated `THREE.Clock`.
- **drei's `<Text>` draws a blank quad on `WebGPURenderer`**: troika-three-text injects its shader through `onBeforeCompile`, which the node-based renderer never calls.
- **Render counts depend on the machine.** In `chromium-headless-shell`, 10 state updates one frame apart gave 6 renders instead of 11, and a 5-step mouse move fewer renders than on the GPU: React batches updates and the browser coalesces pointer events when frames are slow. The pages use `flushSync`, and report no counts after pointer actions.
- **Chromium on Windows warns that `powerPreference` is ignored** whenever R3F passes it; the other OSes don't. `check.sh` filters the line.
- **The deterministic and standard Rapier builds gave the same state hash on Windows x64**, in Node.js and in the browser. With a variable step between 1/144 and 1/30 s, 16 of 24 picks landed elsewhere and one fell through a 20 cm floor. A fast ball crossed a thin dynamic wall without CCD, but not a fixed one.
- **IWER needs `forceInstall`** in Chromium, which already has a `navigator.xr`, **and `stereoEnabled`**, or the right eye's viewport is 0 pixels wide.
- **The first WebXR probe hung for ten minutes** while holding the shared GPU lock: the WebGL 2 backend threw on every XR frame, the page waited for frames forever, and the run was stopped by hand. The cause is IWER's `XRWebGLLayer.framebuffer`, `null`, used as a `WeakMap` key in `WebGLState.drawBuffers`. The page now catches render errors and bounds its waits, and `probe.mjs` exits on its own after twice its timeout plus 30 seconds.
- **In r186, `WebGPURenderer` enters a WebXR session on WebGPU only with `XRGPUBinding` and the `webgpu` feature**; its error message mentions a `VRButtonGPU` that doesn't exist. `WebGLXRFallback` switches renderers, but the controllers the page took from the first renderer stop receiving events. Only the classic `WebGLRenderer` rendered both eyes with IWER.
- **An `InstancedMesh` ignores `setColorAt` if its first render had no instance colors**: the port's markers showed white until the attribute was allocated up front.
- **`@react-three/test-renderer` needs `IS_REACT_ACT_ENVIRONMENT`**, or React warns on every update and R3F disposes later; its CommonJS build loads `three.cjs` next to the ES module build, without splitting the classes the scene uses.
- **Pixels**: the same page twice gave identical bytes; WebGPU against ANGLE on the same GPU differed in 294 pixels, against SwiftShader in 10,330, none above pixelmatch's default threshold once anti-aliasing is left out.
- **An image imported by a lesson must exist before the page does**: lesson 11 once imported a screenshot not yet converted, and the shared working tree's Astro build failed for the other sessions working in it until the image was added.

## 2026-09-16 — Lessons 9 to 13 on the CI runners

- Run [35175914560](https://github.com/spareilleux/learn/actions/runs/35175914560) passed on all three OSes the first time. The standard Rapier build gave the state hash `68235a2bdba192f1` on Linux x64 and macOS arm64 too, in Node.js and in the browser, the same as the deterministic build: for this scene, and not as a guarantee.
- macOS ran the pages on WebGPU with the "apple" adapter; Linux and Windows on SwiftShader's WebGL 2, where GA's `ThreeFretboard` produced its 253 WebGL error lines and R3F warned 13 times about `PCFSoftShadowMap` instead of 14.
- Before the push, the local check compared lesson 11's fallback page with its WebGL 2 output on the author's GPU: the page ends on WebGL 2 after starting on WebGPU. `check.sh` now uses the WebGL 2 output only when the page ran on WebGL 2 from the start.

## 2026-09-16 — GuitarAlchemist/ga, lessons 9 to 13

Nothing below has been reported to GA.

- GA's React components use R3F 8, drei 9 and React 18, with `WebGLRenderer` in all 6 `<Canvas>` files; `ThreeFretboard.tsx` doesn't use R3F. The BSP explorer sets React state with a cloned camera position on every frame, and `GuitarAlchemistLogo3D.tsx` passes a new object in `args`, rebuilding its geometry on each render (lesson 9).
- No physics library: Cheese Avalanche is hand-written with a variable step clamped to 1/30 s; the lunar lander uses a fixed 1/120 s step with an accumulator (lesson 10).
- No WebXR code (lesson 11).
- 22 Playwright spec files, of which the 7 outside the dashboard suite, 6 of them on 3D pages, run in no CI workflow; 3-second waits for WebGPU; a `toBeTruthy()` on a screenshot buffer; a black-canvas check that calls `getContext('2d')` on a WebGL canvas and can never pass; 13 committed test result files from a failed run (lesson 12).
- `ThreeFretboard.tsx`, reproduced and measured: 69 draw calls and 32 textures for an empty neck; 10 renders of its parent with the same notes rebuild the scene 10 times and leak 29 sprite textures each time; a pixel ratio of up to 6; `samples: 8`, which draws nothing on SwiftShader's WebGL 2; strings twice as thick, since a gauge is used as a radius; and an `onPositionClick` prop that is never called. The port draws the same neck in 6 draw calls with 4 textures, and picks notes (lesson 13).

## 2026-09-17 — Live demos

- The pages are built by a second Vite config, `vite.demos.config.ts`, with the base `/learn/threejs-demos/`, into `public/threejs-demos`, which the site copies as it is. The lesson pages' sources are unchanged, since lessons 4, 8 and 13 quote their build; a plugin of that config adds the *Try it* panel to the built pages only. A page can't be driven from outside, so each control sets a URL parameter and reloads the page. The panel is lil-gui 0.17, the copy that three.js ships in `three/addons/libs`: no new dependency.
- The build weighs 9.4 MB in 75 files. Rapier's standard and deterministic builds, each with its WebAssembly inlined as base64, are 2.9 MB each; `three.tsl` 0.69 MB. `check.sh` builds it again and compares it with the committed copy (`diff -r`, apart from the regenerated models and HDR).
- The frames sit in a closed `<details>`, with `loading="lazy"`: nothing loads until a reader unfolds one.
- The guitar is modeled in code: no glTF guitar with a known license was available. 47,405 triangles in 32 draw calls; instancing for the frets, inlays, pole pieces, saddles, knobs and tuners.
- Rapier's `body.handle` is a float that packs an index and a generation: `handle % 8` is not a palette index; each pick now keeps the color of its throw number. And colors set with `setColorAt` reached the GPU only in a frame of `setAnimationLoop`: a probe that called `render()` itself saw white picks. In r186, `InstanceNode` uploads them in its per-frame update.
- The VR page uses the classic `WebGLRenderer`, as lesson 11 found necessary with IWER. During a session, its `resize` listener must do nothing: `WebGLRenderer` warns "Can't change size while VR device is presenting".
- On a phone-sized page (Playwright's Pixel 7 emulation), the frames first measured 150 pixels tall: the site's styles override the iframe's `height` attribute, so the height is now an inline style, `min(420px, 70vh)`. The panel starts folded in a narrow frame. With a 4× CPU slowdown but the author's desktop GPU, the five scenes held 60 frames per second on WebGPU and with `?webgl`; on a real mid-range phone GPU it is *to verify*.
- The first probe of a page that imports a new dependency failed with "Execution context was destroyed": Vite optimized the dependency and reloaded the page. The second run passed.

## To verify

- The VR demo with a real headset: entering the session, the controller rays, the note and the haptic pulse.
- Whether picks thrown without CCD pass through the frets of the physics demo.
- The five complete scenes on a phone: frame rate, and whether the studio's 2048 × 2048 shadow map and bloom hold up.
- Whether a scene modeled in centimeters needs lights 10,000 times stronger to look the same as in meters (lesson 2).
- KTX2 textures: loading, GPU formats chosen on each OS, memory.
- Whether `ThreeHeadstock.tsx` calls `onTuningPegClick` once per stale listener after its effect reruns (lesson 5).
- Whether `ThreeFretboard.tsx` is rebuilt on every render of its parents in GA's pages (lesson 8).
- GPU time, not only CPU time, with WebGPU's `timestamp-query` (lesson 8).
- Draco against meshopt on a large model and on many small ones, over a real network (lesson 4, exercise 3).
- WebGPU on a Linux or Windows machine with a GPU, outside the author's.
- `XRGPUBinding`: which browsers and headsets offer it, and `WebGPURenderer` in a real WebXR session (lesson 11).
- The WebGL 2 backend and `WebGLXRFallback` on a real headset, whose layer framebuffer isn't `null` (lesson 11).
- Frame rate, foveation and comfort of the WebXR page on a Quest (lesson 11).
- Whether a WebGPU-ready troika-three-text exists for drei's `<Text>` (lesson 9).
- How often GA's parents render `ThreeFretboard` and the BSP explorer in practice, with React's profiler (lessons 9 and 13).
- `samples: 8` on real GPUs' WebGL 2, by `MAX_SAMPLES` (lesson 13).
- Why Rapier stopped a fast ball at a thin fixed wall without CCD (lesson 10).
