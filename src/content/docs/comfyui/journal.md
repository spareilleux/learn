---
title: Journal
description: Dated progress notes for the ComfyUI course — pinning ComfyUI v0.36.0 and SDXL base 1.0, running a portable build with its own base directory, two images from one seed, the server's set-ordered outputs and validation errors, zlib sizes that differ by OS, CPU-only CI on three OSes, and items to verify.
sidebar:
  order: 99
---

## Progress

- [x] ComfyUI v0.36.0 (commit `ee71d5c`), frontend 1.52.7, SDXL base 1.0 pinned by file hash
- [x] `check.sh`: offline workflow checks, UI-to-API conversion compared with the frontend's export, the C# and Java clients against ComfyUI on the CPU
- [x] CI on Ubuntu, Windows and macOS, without a GPU or a model
- [x] Lesson 1: the node graph, installing, and a first image
- [x] Lesson 2: diffusion, and what makes an image reproducible
- [x] Lesson 3: workflows as JSON
- [x] Lesson 4: the HTTP and WebSocket API from C# and Java
- [x] French and Spanish translations
- [ ] Lesson 5: img2img, inpainting and outpainting

## 2026-09-16 — Versions and setup

- ComfyUI v0.36.0 was released the day before, on 15 September 2026, and is the latest release; its tag points at commit [`ee71d5c`](https://github.com/Comfy-Org/ComfyUI/commit/ee71d5c4993f29086b27fde1629a945ae48425bf). The Windows portable build for NVIDIA is 1,917,442,353 bytes and ships Python 3.13.14 and PyTorch 2.13.0 for CUDA 13.0.
- The course reuses a portable build already installed on the machine, and never writes into it: the server starts with `--base-directory` pointing elsewhere, `--models-directory` pointing at the install's models, and `--database-url sqlite:///:memory:`.
- A fresh base directory made the server stop at startup with `FileNotFoundError`, because it lists `custom_nodes` before creating anything. `server.sh` creates the empty folder.
- `sd_xl_base_1.0.safetensors` on the machine has the SHA-256 that Hugging Face lists, `31e35c80…7e5b`.
- The documentation's getting-started pages and API examples use Stable Diffusion 1.5 at 512 × 512, not SDXL. The manual install page uses conda; `venv` only appears on the comfy-cli page. The text-to-image tutorial says `EmptyLatentImage` makes a noise latent; it makes zeros, and `KSampler` makes the noise.

## 2026-09-16 — First renders

- The first SDXL render took 14.71 seconds, of which about 4 were the 25 sampling steps at 6.4 steps per second. With the models loaded, a new seed took 4.6 seconds.
- The prompt asked for a brass metronome; seed 42 drew something like an hourglass. Seed 43 came closer.
- `nvidia-smi` showed about 7 GB more in use during rendering. The log staged 1,560 MB for the text encoders, 4,896 MB for the UNet, and 159 MB for the VAE.
- The latent previews of `--preview-method taesd` slowed sampling from 6.4 to 4.9 steps per second.

## 2026-09-16 — One seed, two images

- The same workflow and seed gave `698e7867…` on a freshly started server, again after restarts, and `5374ac40…` whenever the negative prompt was encoded again with the UNet already loaded. The two images differ by a mean of 0.92 levels, and 2.63 % of the pixels differ by more than 8.
- `--disable-dynamic-vram` gave `5374ac40…` on the first run too. `--deterministic` changed neither result. I haven't found which operation differs.
- The first image of a batch of two differed from the single image with the same seed (mean 0.74), and the second image of the batch isn't seed 43's.
- A seed-43 render by the Java client, on another server start 20 minutes later, had the same pixels as the first seed-43 render.

## 2026-09-16 — The JSON formats and the API

- Loading the API file in the frontend and calling `app.graphToPrompt()` gave a UI file and an API export. The C# converter, which reads widget names from `/object_info`'s `input_order` and skips the seed's control widget, produces the export byte for byte.
- A PNG queued from the browser recorded seed 42 in its `workflow` chunk, and the frontend changed the seed to 140956311522585 right after queuing, because its `control_after_generate` widget was set to `randomize`.
- The server wrote `"cfg": 7.0` into the PNG's prompt for a frontend that sent `7`: validation converts `FLOAT` inputs with `float()` and writes them back.
- A link to a missing node made the server's validation raise a `KeyError` outside its `try` block. The server reported two errors where the offline check found five; one was filed under node 3 with node 8's input name, `samples`, and a traceback that includes the server's installation path.
- `check.sh` failed on its second run: the two `SaveImage` nodes ran in the other order. The server keeps validated outputs in a Python set, and string hashes are randomized at each start. `server.sh` now sets `PYTHONHASHSEED=0`.
- A fully cached run still sends `executed` for each output node, with the first run's file names, and writes nothing.
- The first CI run failed on Ubuntu only: the same 64 × 48 PNG compressed to 84 bytes there and to 88 on Windows and macOS. `png-info` now prints the inflated size.
- The Python API example in ComfyUI's repository waits for `executing` with a `null` node. The server sends it after the history is written; the clients stop on `execution_success`, `execution_error` or `execution_interrupted` instead.
- The documentation doesn't list the `/api/jobs` routes, the `/api` prefix on every route, or the binary preview messages.

## To verify

- SDXL on Linux with CUDA, and on Apple Silicon with MPS: the course's GPU machine runs Windows; CI only installs the CPU builds.
- Which operation makes the text encoders give different results depending on whether the UNet is loaded, and whether it happens with other GPUs or drivers.
- Whether an ancestral sampler gives the same image on the CPU and on the GPU for a seed: its step noise is drawn on the device.
- Whether a perceptual hash would be stable across the cases of lesson 2.
- `execution_error` and `execution_interrupted` as the clients print them, `POST /interrupt` with a prompt id, and deleting a queued prompt: no run has produced them yet.
