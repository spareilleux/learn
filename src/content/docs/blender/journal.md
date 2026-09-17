---
title: Journal
description: Dated progress notes for the Blender course — pinning Blender 5.2.2 LTS, a portable install, scripts run in the background and compared in CI on three OSes, a Cycles render with the same pixels on Windows, Linux and macOS, a color-space bug in a generated texture, what the glTF exporter drops or skips by default, two Hunyuan3D models from ComfyUI cleaned in Blender with what failed, and items to verify.
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
- [x] A cleanup pipeline for `.glb` models generated in ComfyUI, tried on two Hunyuan3D models
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

## 2026-09-17 — Models generated in ComfyUI, cleaned in Blender

The request: real 3D models from ComfyUI, brought into Blender and shown here with what went wrong. Atlas, another working session of this project, generated a metronome and a gramophone with ComfyUI (see the [ComfyUI course](../../comfyui/)), in two steps:

1. [SDXL base 1.0](https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0) drew each object alone on a white background, seen three-quarters from slightly above: 1024 × 1024 px, 30 steps, CFG 6.5, `dpmpp_2m` with the `karras` scheduler, seeds 5101 (metronome) and 5110 (gramophone).
2. [Hunyuan3D 2.0](https://github.com/Tencent-Hunyuan/Hunyuan3D-2), with the fp16 weights repackaged by Comfy-Org ([`hunyuan3d-dit-v2_fp16`](https://huggingface.co/Comfy-Org/hunyuan3D_2.0_repackaged)) and ComfyUI's native nodes ([Comfy's tutorial](https://docs.comfy.org/tutorials/3d/hunyuan3D-2)), turned each image into a mesh: `ImageOnlyCheckpointLoader` → `CLIPVisionEncode` (crop `center`) → `Hunyuan3Dv2Conditioning` → `EmptyLatentHunyuan3Dv2` (resolution 3072) → `KSampler` (30 steps, CFG 5, `euler`/`normal`, seed 7) → `VAEDecodeHunyuan3D` (8000 chunks, octree resolution 380) → `VoxelToMesh` (surface net, threshold 0.6) → `SaveGLB`. ComfyUI v0.36.0.

The Hunyuan3D 2.0 license states that it doesn't apply in the European Union, the United Kingdom and South Korea. Only renders of the models are published here; the `.glb` files stay out of the repository.

Blender then ran [`scripts/glb_pipeline.py`](https://github.com/spareilleux/learn/blob/9480173/code/blender/scripts/glb_pipeline.py) in the background on each file. It merges vertices by distance, removes floating parts, recalculates normals, scales to a real size, decimates, reports the mesh before and after, renders a Cycles turntable, exports a `.glb` with modifiers applied, and reads it back. CI runs it on a small pick built in `bpy`, with the flaws of a generated mesh (`scripts/pipeline_check.py`), with and without a voxel remesh: the reports, remesh included, were identical on the three runners.

![Metronome, left to right: the SDXL image; the mesh after the first cleanup, with the dial and pendulum turned into relief and a rough surface; after a 1.2 mm voxel remesh, smoother, with the same relief; the back after remeshing, a flat face the image never showed](../../../assets/blender/comfy3d-metronome.webp)

![Gramophone, left to right: the SDXL image, with a floor line under the cabinet; the mesh after the first cleanup, its horn full of torn triangles and a slab under the cabinet; after a 3 mm voxel remesh, a closed horn, with a few fragments of the slab left on the ground; the side view after remeshing](../../../assets/blender/comfy3d-gramophone.webp)

What the reports said:

| | Metronome | Gramophone |
|---|---|---|
| Hunyuan3D `.glb` | 15,944,172 bytes | 17,421,112 bytes |
| Vertices, triangles | 438,348, 890,140 | 433,806, 1,017,760 |
| Non-manifold edges | 19,084 | 189,748 |
| Loose parts | 86 | 20 |
| UVs, textures | none, none | none, none |
| Decimate to 20,000 triangles | 882,644 → 43,302, target missed | 1,004,809 → 317,253, target missed |
| Cleaned `.glb`, without remesh | 632,484 bytes | 5,835,300 bytes |
| Voxel remesh, then Decimate | 1.2 mm: 223,100 → 20,000 | 3 mm: 195,848 → 20,000 |
| After remesh: non-manifold edges, loose parts | 0, 1 | 0, 3 |
| Cleaned `.glb`, with remesh | 361,100 bytes | 361,000 bytes |

- **No texture, so no baked lighting.** The planned failure, lighting painted into the texture, didn't happen: this workflow outputs shape only, with one empty material and no UV map. The wood, the brass and the dial of the SDXL images are lost; colors and materials have to be made in Blender.
- **Topology.** A surface net builds its surface on a voxel grid. Where a wall is thinner than a voxel, like the gramophone's horn, both sides probably fall on the same edges: the report counted 189,748 non-manifold edges there, against 19,084 on the solid metronome. [Decimate](https://docs.blender.org/manual/en/5.2/modeling/modifiers/generate/decimate.html) in Collapse mode stopped far above its target on both models, and the first version of the pipeline printed only the ratio it had asked for. The report now prints the triangles obtained and says when the target is missed.
- **Voxel remesh.** The [Remesh modifier](https://docs.blender.org/manual/en/5.2/modeling/modifiers/generate/remesh.html) in Voxel mode rebuilds a closed surface. After it, Decimate reached 20,000 triangles exactly, and both meshes had no boundary and no non-manifold edges. Its cost: detail smaller than the voxel is lost, and thin walls break into crumbs. The pipeline now runs its floater filter a second time after the remesh; it removed 22 crumbs from the metronome and 2 from the gramophone. The two gramophone fragments that remain hold more than 1% of the faces.
- **Invented back.** The metronome's back and sides, which the image doesn't show, came out as flat, plausible faces. The engraved dial, the scale markings and the pendulum of the image became relief on the front face: Hunyuan3D reads painted detail as shape.
- **The background.** The line where the white floor meets the white wall under the gramophone became a slab under the cabinet. The floater filter kept it, and the remesh only broke it into fragments. The fix belongs before the 3D step, in the cutout of the image.
- **Small things.** The metronome held one vertex without any face: glTF drops it, so the size read back was smaller than the size written. The pipeline now deletes such vertices. The origin is put back at the bottom after the remesh without scaling again, so the remeshed metronome is 22.98 cm tall instead of 23.
- **Time, on the author's machine.** 17 to 29 s per model for the whole pipeline, including import and export; 0.15 to 0.36 s per turntable frame at 512 × 512 px and 32 samples, Cycles on the CPU. The real sizes (23 cm and 60 cm tall) are choices for this test, not measurements.

## To verify

- Installing with winget, Snap and Flathub, and the versions they carry.
- The PowerShell download and extraction commands of lesson 1, as written.
- The interface under WSLg.
- EEVEE on a machine without a GPU, and whether EEVEE's faster later starts come from a shader cache on disk.
- Whether GPU renders with a fixed seed are reproducible, across runs and across GPUs.
