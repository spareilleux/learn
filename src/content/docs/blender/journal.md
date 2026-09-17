---
title: Journal
description: Dated progress notes for the Blender course — pinning Blender 5.2.2 LTS, a portable install, scripts run in the background and compared in CI on three OSes, a Cycles render with the same pixels on Windows, Linux and macOS, a color-space bug in a generated texture, what the glTF exporter drops or skips by default, and items to verify.
sidebar:
  order: 99
---

## Progress

- [x] Blender 5.2.2 LTS (commit `d13f752e3b9c`), installed from the portable archive
- [x] `check.sh`: each lesson's `bpy` script run with `--background --factory-startup`, its report compared with `expected/`
- [x] CI on Ubuntu, Windows and macOS, with Cycles on the CPU
- [x] Lesson 1: the interface, and the .blend file as a database
- [x] Lesson 2: polygonal modeling and modifiers
- [x] Lesson 3: materials, UVs, and what glTF keeps of them
- [x] Lesson 4: lights, cameras, and rendering with EEVEE and Cycles
- [x] French and Spanish translations
- [ ] Lesson 5: scripting with `bpy`

## 2026-09-16 — Versions and setup

- Blender's LTS page lists 5.2.2 and 4.5.14, both released on 15 September 2026. The course pins 5.2.2, tag `v5.2.2`, commit `d13f752e3b9c4f8c261cda552b1021f8bcc0382c`.
- The Windows archive is 404,453,484 bytes, and its SHA-256 matches `blender-5.2.2.sha256`. It is extracted on a separate drive, and nothing is installed in the system.
- winget still offered 5.2.1 on the day of 5.2.2's release. The checksum file lists no Intel build for macOS, only `macos-arm64`.
- The pages of projects.blender.org answer `403` to `curl`, but its API doesn't: `/api/v1/repos/blender/blender/raw/<path>?ref=<sha>` returned the files at the pinned commit. The Python files quoted in the lessons (the glTF exporter, Cycles' properties) are identical to the ones in the installed build, apart from line endings.
- Lesson 1 order: `bpy` comes into every lesson from the first one, instead of waiting for lesson 5; the mission explains why.

## 2026-09-16 — Scripts, CI and what they showed

- The first CI run passed on all three OSes. Each job took about a minute, of which `check.sh` took 25 to 27 s; the rest is the download (about 350 to 400 MB) and unpacking. The 4096-sample reference render of lesson 4 took 13 to 18 s on the runners, against 1.4 s on the author's 24-thread CPU.
- The hash of the 16-sample Cycles render, 8-bit after AgX, was the same on Windows and Linux on x86-64 and on macOS on Apple Silicon. `check.sh` first printed it without comparing; after that run, it compares it.
- The `.blend` file saved by lesson 1 is 96,061 bytes on the author's machine and on the Linux runner, 96,053 on the Windows runner and 96,055 on the macOS one: its size isn't compared.
- The generated rosewood texture was far too dark at first. `Image.pixels` on an 8-bit sRGB image stores the given values as bytes, without conversion, and the script had converted the color to linear first. Lesson 3 tells the story.
- The glTF exporter dropped a Noise Texture connected to the Roughness without a message in its log, leaving glTF's default roughness of 1. It doesn't apply modifiers unless `export_apply` is set. And `export_format="GLTF_EMBEDDED"` is refused unless a preference of the add-on enables it, although the manual documents the format.
- In 5.2, reading `Material.use_nodes` prints a `DeprecationWarning`: it will be removed in 6.0. `RenderSettings.engine`'s enum, read from the class, lists only `BLENDER_EEVEE`, while setting `BLENDER_WORKBENCH` or `CYCLES` works.
- The first lights (12, 3 and 15 W) were far too strong for a scene half a meter wide; the lesson uses 3, 0.6 and 4 W.

## 2026-09-16 — Images

- The renders come from `scripts/render_images.py`: Cycles on the CPU for the lesson images, and Cycles with OptiX and EEVEE for the timings, run under the machine's GPU lock since other work shares the GPU.
- The interface screenshot comes from Blender started with a window and a script that selects the cube, moves the pointer out of the way, and calls `bpy.ops.screen.screenshot` from a timer. With `--factory-startup`, the Quick Setup splash covered the viewport, so the capture used a separate user configuration folder (`BLENDER_USER_CONFIG`) whose preferences turn the splash off. Quitting from the script still wrote `quit.blend` to the system's temporary folder.

## To verify

- Installing with winget, Snap and Flathub, and the versions they carry.
- The PowerShell download and extraction commands of lesson 1, as written.
- The interface under WSLg.
- EEVEE on a machine without a GPU, and whether EEVEE's faster later starts come from a shader cache on disk.
- Whether GPU renders with a fixed seed are reproducible, across runs and across GPUs.
