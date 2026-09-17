---
title: three.js for C#/Java developers — Mission
description: Real-time 3D in the browser with three.js r186, WebGPURenderer and its WebGL 2 fallback, TSL node materials, glTF and React Three Fiber, for developers who know C# or Java and TypeScript — every scene measured in headless Chromium and every number compared in CI on Windows, Linux and macOS.
sidebar:
  label: Mission
  order: 0
---

:::note[Version studied]
[three.js](https://threejs.org/) **r186** (the npm package `three` 0.186.0, released on 8 September 2026), with [`@types/three`](https://www.npmjs.com/package/@types/three) 0.186.0, served and built by [Vite](https://vite.dev/) 8.3.0, checked with [TypeScript](https://www.typescriptlang.org/) 7.0.2, and measured in headless Chromium with [Playwright](https://playwright.dev/) 1.63.0 on [Node.js](https://nodejs.org/) 24. The course's scenes and scripts are in [`code/threejs`](https://github.com/spareilleux/learn/tree/eeca669/code/threejs), with a `package.json` and lock file that also pin [glTF Transform](https://gltf-transform.dev/) 4.5.0, and for lessons 9 to 13 [React](https://react.dev/) 19.2.8, [React Three Fiber](https://r3f.docs.pmnd.rs/) 9.7.0, [drei](https://drei.docs.pmnd.rs/) 10.7.8, [Rapier](https://rapier.rs/) 0.20.0, [IWER](https://github.com/meta-quest/immersive-web-emulation-runtime) 2.4.0, [Vitest](https://vitest.dev/) 5.0.1 and [pixelmatch](https://github.com/mapbox/pixelmatch) 7.2.0. [`.github/workflows/threejs-examples.yml`](https://github.com/spareilleux/learn/blob/eeca669/.github/workflows/threejs-examples.yml) runs [`check.sh`](https://github.com/spareilleux/learn/blob/eeca669/code/threejs/check.sh) on Linux, Windows and macOS: it type-checks everything, runs the Node.js scripts and the component tests, opens every lesson page in headless Chromium, builds the pages, and compares the outputs with the ones pasted in the lessons.
:::

## Why I'm learning this

[Guitar Alchemist](https://github.com/GuitarAlchemist/ga) draws a guitar neck in 3D, an ocean, a solar system and a few dozen other scenes with three.js. Some of them use the new `WebGPURenderer` and its shading language, TSL; most still use `WebGLRenderer` and hand-written GLSL. As a C# developer, I know WPF's `Viewport3D` and a little MonoGame. three.js looks like both at first: a scene graph, a camera, meshes and lights. Then the details differ: the renderer can pick WebGPU or WebGL behind my back, a hex color is not the number the shader receives, a light's intensity is in candela, and a model arrives as a glTF file that needs its own decoders.

This course learns three.js as it is in September 2026, not as most tutorials show it: `WebGPURenderer` first, `setAnimationLoop` instead of `requestAnimationFrame`, TSL instead of `ShaderMaterial`, `three/addons` imports, `Timer` instead of `Clock`, `HDRLoader` instead of `RGBELoader`.

## Who this course is for

You are comfortable with C# or Java, and you have followed [JavaScript for C#/Java developers](../javascript-for-csharp-java/) and [TypeScript for C#/Java developers](../typescript-for-csharp-java/), or know their content: ES modules and npm, `async` and `await`, classes, structural types. Lesson 9 uses React; the [React (Vite) course](../react-vite/) covers what it needs. No prior 3D experience is required, but if you have used [WPF 3D](https://learn.microsoft.com/dotnet/desktop/wpf/graphics-multimedia/3-d-graphics-overview), [MonoGame](https://monogame.net/) or [JavaFX 3D](https://openjfx.io/javadoc/25/javafx.graphics/javafx/scene/SubScene.html), each lesson says what carries over.

## three.js in one table

| | WPF 3D | MonoGame | JavaFX 3D | three.js |
|---|---|---|---|---|
| Where it draws | a `Viewport3D` element | the game window | a `SubScene` | a `<canvas>` created by the renderer |
| Scene graph | `ModelVisual3D`, `Model3DGroup` | none: you draw each model | `Group`, `MeshView` | `Scene`, `Group`, `Mesh` |
| Axes | right-handed, Y up | right-handed matrices, Y up | Y down | right-handed, Y up |
| Geometry | `MeshGeometry3D` | vertex and index buffers | `TriangleMesh` | `BufferGeometry` |
| Materials | `DiffuseMaterial`, `SpecularMaterial` | `BasicEffect`, custom effects | `PhongMaterial` | physically based: `MeshStandardMaterial`, node materials |
| The loop | retained: WPF renders when something changes | `Update` and `Draw`, called by `Game` | `AnimationTimer` | `renderer.setAnimationLoop(callback)` |
| GPU API | Direct3D 9 | DirectX or OpenGL | Direct3D or OpenGL, through Prism | WebGPU, or WebGL 2 as a fallback |
| Shaders | none | HLSL effects | none | TSL, compiled to WGSL or GLSL |
| Model files | none built in | the content pipeline (FBX, X) | none built in | glTF 2.0 with `GLTFLoader` |

## The data

The course's own scenes are small and deterministic: a cube, a piece of guitar neck made of primitives, color patches, ten spheres in an HDR studio, a metronome written as a glTF file by a script, a fretboard to point at, a vibrating string, glowing inlays, and 10,000 note markers. Each page reports what the renderer did, and a Playwright script reads it, so the numbers in the lessons come from a run, not from memory.

The real code is [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga) at commit [`05c8eda`](https://github.com/GuitarAlchemist/ga/commit/05c8eda013f2a4d11efaa52c4ca94674521ee684), mainly [`ThreeFretboard.tsx`](https://github.com/GuitarAlchemist/ga/blob/05c8eda013f2a4d11efaa52c4ca94674521ee684/ReactComponents/ga-react-components/src/components/ThreeFretboard.tsx), its 3D guitar neck. GA's React components ask for three.js 0.180, six releases behind this course. The lessons quote GA's code where it shows a point well, including what changed since r180; the findings are in the [journal](journal/).

## Live demos

Every lesson page runs on this site, under a folded frame below its screenshot, with a *Try it* panel that sets the page's parameters, the ones the exercises use. Five complete scenes put the lessons together on a whole guitar modeled in code: a [guitar to play](../threejs-demos/demos/guitar.html) (lesson 5), [chord voicings](../threejs-demos/demos/voicing.html) on GA's fretboard (lesson 13), a [studio](../threejs-demos/demos/studio.html) with shadows, an HDR environment and bloom (lesson 7), [picks thrown on the guitar](../threejs-demos/demos/physics.html) with Rapier (lesson 10), and the [guitar in VR](../threejs-demos/demos/xr.html?emulate) (lesson 11). A frame loads nothing until it is unfolded. The whole build weighs 9.4 MB, most of it Rapier's two builds in WebAssembly.

## By the end of this course, I will be able to

- set up a three.js project with Vite and TypeScript, and explain what `WebGPURenderer` does when WebGPU is missing;
- build scenes from geometries, physically based materials and lights, with shadows, and read `renderer.info` to know what the GPU was asked to do;
- keep colors right from texture to screen: color spaces, tone mapping and HDR environments;
- load glTF models with their animations, and choose between Draco, meshopt and KTX2 compression;
- pick objects and move the camera, write materials and effects in TSL, and post-process a scene;
- draw thousands of objects with instancing, `BatchedMesh` and levels of detail, and measure the result;
- write the same scenes with React Three Fiber, add physics with Rapier and a WebXR mode;
- test 3D code in CI, and know what a headless browser without a GPU can and cannot check.

## Outline

| # | Lesson | You already know |
|---|---|---|
| 1 | [Scene, camera, renderer](01-scene-camera-renderer/) | WPF's `Viewport3D` and `PerspectiveCamera`, MonoGame's `Game` loop, JavaFX's `SubScene` |
| 2 | [Geometries, materials, lights and shadows](02-geometries-materials-lights/) | `MeshGeometry3D`, `DiffuseMaterial`, `BasicEffect`, directional and point lights |
| 3 | [Color, tone mapping and HDR environments](03-color-tone-mapping-environments/) | sRGB, `Color` in WPF or JavaFX, HDR photos |
| 4 | [Loading glTF models and animations](04-gltf-models-and-animations/) | MonoGame's content pipeline, WPF storyboards, `AnimationTimer` |
| 5 | [Interaction, `Raycaster` and camera controls](05-interaction-raycaster-controls/) | hit testing in WPF, `VisualTreeHelper.HitTest`, JavaFX `PickResult` |
| 6 | [TSL and node materials](06-tsl-node-materials/) | HLSL effects, shader graphs |
| 7 | [Post-processing with `RenderPipeline`](07-post-processing-renderpipeline/) | render targets, pixel shaders |
| 8 | [Performance, measured: instancing, `BatchedMesh`, LOD, frustum culling](08-performance-instancing-batching-lod/) | instanced drawing, profilers |
| 9 | [React Three Fiber and drei](09-react-three-fiber-drei/) | WPF data binding, Blazor or React components |
| 10 | [Physics with Rapier in WebAssembly](10-physics-rapier-wasm/) | BEPUphysics, physics engines in games |
| 11 | [WebXR](11-webxr/) | Windows Mixed Reality, OpenXR |
| 12 | [Tests and CI: headless rendering, compared screenshots, and their limits](12-tests-and-ci/) | UI automation, snapshot tests |
| 13 | [Project: GuitarAlchemist's 3D guitar neck, ported to WebGPU](13-project-ga-fretboard/) | the lessons before it |
| — | [Journal](journal/) | |

The course is complete: all 13 lessons were written and checked on 16 September 2026. What remains to try on real hardware, a VR headset, a phone, WebGPU on Linux, is listed in the journal.

## Resources

- [three.js manual](https://threejs.org/manual/), [documentation](https://threejs.org/docs/), [examples](https://threejs.org/examples/), and the [migration guide](https://github.com/mrdoob/three.js/wiki/Migration-Guide)
- [WebGPURenderer](https://threejs.org/manual/pages/webgpurenderer.html) in the manual, and the [TSL documentation](https://threejs.org/docs/pages/TSL.html)
- The source at the release tag: [mrdoob/three.js@r186](https://github.com/mrdoob/three.js/tree/r186)
- [WebGPU](https://gpuweb.github.io/gpuweb/) and [WGSL](https://gpuweb.github.io/gpuweb/wgsl/) specifications, W3C
- [glTF 2.0 specification](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html), Khronos
- [React Three Fiber](https://r3f.docs.pmnd.rs/) and [drei](https://drei.docs.pmnd.rs/)
- [Rapier's JavaScript guide](https://rapier.rs/docs/user_guides/javascript/getting_started_js/)
- [WebXR Device API](https://www.w3.org/TR/webxr/), W3C, and Meta's [Immersive Web Emulation Runtime](https://github.com/meta-quest/immersive-web-emulation-runtime)
