---
title: Journal
description: 'Dated progress notes for the ComfyUI course — pinning ComfyUI v0.36.0 and SDXL base 1.0, running a portable build with its own base directory, two images from one seed, the server''s set-ordered outputs and validation errors, zlib sizes that differ by OS, CPU-only CI on three OSes, the models of lessons 5 to 8 and their licenses, Canny edges that differ by machine, quantized files measured in 16 GB, and items to verify.'
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
- [x] French and Spanish translations of lessons 1 to 4
- [x] Lesson 5: img2img, inpainting and outpainting
- [x] Lesson 6: ControlNet, edges and depth
- [x] Lesson 7: LoRA
- [x] Lesson 8: recent models, licenses, quantization and VRAM
- [x] French and Spanish translations of lessons 5 to 8
- [x] Lesson 9: upscaling, seamless textures and HDR
- [ ] Lesson 10: video
- [x] Lesson 11: custom nodes, and their security

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

![A brass object on an old wooden workbench, lit by morning sun through a dusty window. It looks more like an ornate hourglass than a metronome: a tall glass body with a narrow waist, held in a brass frame on a round base.](../../../assets/comfyui/l01-metronome.webp)

*The first render. ComfyUI v0.36.0: Stable Diffusion XL base 1.0, seed 42, 25 steps, `euler`, `normal`, CFG 7, 1024 × 1024, workflow [`01-txt2img.api.json`](https://github.com/spareilleux/learn/blob/a1a9bffadaa7156b91ca9c2c2b8885e9e9862dd5/code/comfyui/workflows/01-txt2img.api.json).*

## 2026-09-16 — One seed, two images

- The same workflow and seed gave `698e7867…` on a freshly started server, again after restarts, and `5374ac40…` whenever the negative prompt was encoded again with the UNet already loaded. The two images differ by a mean of 0.92 levels, and 2.63 % of the pixels differ by more than 8.
- `--disable-dynamic-vram` gave `5374ac40…` on the first run too. `--deterministic` changed neither result. I haven't found which operation differs.
- The first image of a batch of two differed from the single image with the same seed (mean 0.74), and the second image of the batch isn't seed 43's.
- A seed-43 render by the Java client, on another server start 20 minutes later, had the same pixels as the first seed-43 render.

![Three panels. The first two are the two seed-42 renders, which look the same at this size. The third is a white image with dark lines where they differ, amplified eight times: the outline of the brass object, its glass, the tools on the bench and the window frame.](../../../assets/comfyui/l02-cold-warm.webp)

*The two seed-42 images. ComfyUI v0.36.0: Stable Diffusion XL base 1.0, seed 42, 25 steps, `euler`, `normal`, CFG 7, workflow [`01-txt2img.api.json`](https://github.com/spareilleux/learn/blob/a1a9bffadaa7156b91ca9c2c2b8885e9e9862dd5/code/comfyui/workflows/01-txt2img.api.json). Left: first run after starting the server. Middle: the same graph after the negative prompt was encoded again. Right: where they differ, amplified eight times.*

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

## 2026-09-16 — Models for lessons 5 to 8

- The disk of the course's machine was nearly full, so the new model files went to another drive, declared to ComfyUI with `--extra-model-paths-config`. Each file was downloaded from a pinned Hugging Face revision and checked against the SHA-256 that Hugging Face lists, and its license was read on the model card at the time.
- Pixel Art XL is under CreativeML Open RAIL-M, not the RAIL++-M of SDXL. Its card says no trigger word is needed, and its metadata sets `instance_prompt: pixel art`.
- The LCM-LoRA's metadata says rank 1 and alpha 1, and its title `sdxl_LCM_lora_rank1`; its tensors have rank 64 and alpha 8.
- The Qwen3 4B text encoder has the same SHA-256 in Comfy-Org's Z-Image-Turbo and FLUX.2 klein repositories.

## 2026-09-16 — Img2img, inpainting, ControlNet and LoRA

- `denoise` didn't change the number of steps: 25 steps ran for every value from 0.3 to 0.9, in 4.6 to 5.1 seconds.
- Uploading identical bytes under a taken name returned the existing name; different bytes got `name (1).png`. Neither is documented.
- `VAEEncodeForInpaint` grays the masked pixels, which the tutorial doesn't say. With `denoise` 0.5, the result was a flat gray ellipse.

![Three crops of the front of the workbench. First: a flat gray ellipse with faint shading where the objects were. Second: a sharp ellipse of pale, rough wood with a dark rim along its top. Third: two new wooden objects on the bench, with no visible edge.](../../../assets/comfyui/journal-l05-failures.webp)

*Two inpainting failures and the fix, before pasting back. ComfyUI v0.36.0: Stable Diffusion XL base 1.0, seed 42, 25 steps, CFG 7, `euler`, `normal`. From left to right: [`05-inpaint-vaeencode.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-inpaint-vaeencode.api.json) with `denoise` 0.5; the same workflow with `denoise` 1 and a mask with a 24-pixel soft edge; [`05-inpaint-model.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-inpaint-model.api.json), the SD-XL inpainting 0.1 UNet with `denoise` 0.99, on the same soft mask.*

- The SD-XL inpainting card says to keep `strength` below 1.0; 1.0 and 0.99 gave nearly the same image here (0.01 % of the pixels differ by more than 8).
- The decoded inpainting result changed 6.2 % of the pixels outside the mask by more than 8 levels; pasting it back with `ImageCompositeMasked` left them identical.
- The documentation page of `SetUnionControlNetType` lists 13 types; the node has 8.
- The first CI run of the `Canny` node failed on all three OSes: four machines gave four pixel hashes. The three runners found 467 edge pixels, the author's machine 464. CI now prints them as information.

![White edge lines on black, drawn in blocky pixels: a honeycomb of wavy cells drawn from the course's test pattern.](../../../assets/comfyui/journal-canny-ci.webp)

*The `Canny` node's output on the author's machine, pixel hash `77af5cb1b7e93a5c`, 464 edge pixels, enlarged four times without smoothing. ComfyUI v0.36.0 on the CPU, no model, thresholds 0.05 and 0.15, workflow [`05-masks.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-masks.api.json). The three CI runners each drew 467 edge pixels, with three other hashes.*

- With `end_percent` 0.3, the ControlNet guided 8 of 25 steps, and the image was almost the same as with it on for every step.
- A LoRA costs time before the first step, not during sampling: switching LoRAs took 4 to 5 seconds more, and a 4-step LCM-LoRA image then took 1.16 seconds.

## 2026-09-16 — Recent models and quantization

- Z-Image-Turbo in bf16 with its bf16 text encoder, 19.4 GB of weights, ran on the 16 GB GPU with dynamic VRAM: 63.93 seconds for the first render, then 5.93 seconds at 1.5 steps per second. int8 with the fp8 text encoder ran at 3.1 steps per second, nvfp4 at 3.7 to 4.1.
- `nvidia-smi` showed 12.5 to 15.3 GB in use for every configuration: dynamic VRAM uses what is free. The staged sizes in the log are the useful numbers.
- int8 images stayed close to bf16's (9 to 15 % of the pixels differ by more than 8); nvfp4 images showed the same scene arranged differently (62 to 74 %).

![Four renders side by side, each a gold and black pyramid metronome on a worn wooden workbench in front of a window. The first two are nearly the same; the last two show the same scene with the objects arranged differently.](../../../assets/comfyui/l08-quantized.webp)

*ComfyUI v0.36.0: Z-Image-Turbo, seed 42, 8 steps, CFG 1, `res_multistep`, `simple`, workflow [`08-z-image-turbo.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/08-z-image-turbo.api.json). From left to right: bf16 with the bf16 text encoder, int8 with fp8, nvfp4 with fp4, nvfp4 with bf16.*

- `qwen_3_4b_fp8_mixed` has 12 nvfp4 layers, and `qwen_3_4b_fp4_mixed` has 58 fp8 layers. The nvfp4 Z-Image file keeps its four refiner blocks in bf16.
- With `--disable-dynamic-vram`, the first bf16 render took 78.87 seconds and gave the same pixels as with dynamic VRAM. The second render was stopped when the machine, shared with other work, ran short of RAM. An earlier bf16 batch had been stopped the same way: the server held 14.5 GB of RAM. Each server now starts only when the configuration's weights, plus a margin, fit in free RAM.
- FLUX.2 klein 4B drew a brass stand, not a metronome, with seeds 42, 43 and 44; Z-Image-Turbo drew a metronome each time.

![Four renders side by side. First, Z-Image-Turbo's pyramid metronome on a workbench. Then three FLUX.2 klein 4B renders of a dusty workshop, each with a brass stand with a crank or arms on a worn bench instead of a metronome.](../../../assets/comfyui/l08-z-image-klein.webp)

*ComfyUI v0.36.0. First: Z-Image-Turbo bf16, seed 43, workflow [`08-z-image-turbo.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/08-z-image-turbo.api.json). Then: FLUX.2 klein 4B, seeds 42, 43 and 44, 4 steps, CFG 1, `euler`, workflow [`08-flux2-klein.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/08-flux2-klein.api.json).*

## 2026-09-16 — Custom nodes and their security

- ComfyUI v0.36.0 imports each pack with `exec_module` before it reads `NODE_CLASS_MAPPINGS`; `prestartup_script.py` runs earlier, and `WEB_DIRECTORY` JavaScript runs in the browser. `hook_breaker_ac10a0.py` restores one function after the packs load; nothing else stands between a pack and the process.
- ComfyUI-Manager is now the pip package `comfyui_manager==4.2.2`, pinned in `manager_requirements.txt`. The 42 `.py`, `.json` and `.md` files of its PyPI wheel are identical to the `4.2.2` tag, commit `bd4ede22`. It gates installs by security level, listener and two new flags, and looks for known bad package names at startup; nothing reads a pack's code.
- The Guitar Alchemist pack (GA Chord Diagram, GA Fretboard Control Map, GA Scale Prompt) computes from GA's tuning and scale tables at `a826864f`, draws with Pillow without fonts, and passes 11 unit tests with only NumPy and Pillow. Loaded into a throwaway base directory with the portable build's Python on the CPU, it imported in 0.0 s, ran in 0.06 s, and `SaveImage` wrote the same pixels as the test's expected PNG. `--disable-all-custom-nodes`, `--whitelist-custom-nodes ga` and a `.disabled` folder behaved as the source says.
- The audit script ran on six packs pinned on 16 September 2026: ComfyUI-GGUF, comfyui_controlnet_aux, ComfyUI-Impact-Pack, ComfyUI-VideoHelperSuite, rgthree-comfy and ComfyUI_essentials. None of the findings suggests bad intent. Impact-Pack installs `onnxruntime` with pip the first time an ONNX detector runs, and its `install.py` downloads a SAM `.pth`. rgthree-comfy sends a model file's SHA-256 to Civitai when the interface asks for its information. comfyui_controlnet_aux has 72 `torch.load` calls without `weights_only`, safe by default only on PyTorch 2.6 or later.
- A pickle whose payload calls `print` ran with `pickle.loads` and with `torch.load(weights_only=False)`; `torch.load(weights_only=True)` refused it on PyTorch 2.13.

## 2026-09-16 — Models for lessons 9 and 10

- Downloaded to the models drive and checked against the SHA-256 of the Hugging Face tree API: `RealESRGAN_x4plus.safetensors` (66,857,836 bytes, BSD-3-Clause), `film_net_fp16.safetensors` (68,882,302 bytes), and for Wan 2.2 TI2V 5B, under Apache 2.0, `wan2.2_ti2v_5B_fp16.safetensors` (9,999,658,848 bytes), `umt5_xxl_fp8_e4m3fn_scaled.safetensors` (6,735,906,897 bytes) and `wan2.2_vae.safetensors` (1,409,400,960 bytes). The 18.1 GB of Wan took 10 minutes.
- Comfy-Org's repackage has no fp8 file of TI2V 5B, only fp16.

## 2026-09-16 — Upscaling, seamless textures and HDR

- The RAM rule chose the model at each server start: Z-Image-Turbo nvfp4 with 22 GB of free RAM, int8 with 24 GB. Free RAM fell to 9 GB during the int8 renders.
- A sampling step took about 0.3 seconds at 1024 × 1024 and 2.2 to 2.8 seconds at 2048 × 2048.
- A plain `VAEDecode` of the 2048 × 2048 latent fit on the GPU; its image differs from `VAEDecodeTiled`'s by 0.93 levels on average.
- The latent upscale left a noisy grain and doubled strings at denoise 0.3.
- `SaveImageAdvanced`'s 16-bit PNG of an 8-bit render has 256 levels per channel, and its EXR has no value above 1.0. The C# client stopped at the first 16-bit PNG: it now decodes them, and lists EXR and AVIF files by size.
- The first seamless attempt, with a 160-pixel cross, 64 pixels of feather and denoise 0.7, halved the seams (13.4 to 5.2 levels at the middle row) but left a speckled line and a step in tone. Denoise 0.9 didn't help; a 384-pixel cross with 128 pixels of feather did.
- "Pale maple" drew maple leaves carved in the wood. "Pale maple wood, a planed board" drew a board.

![Three panels. A 2 × 2 repeat of a rosewood texture, with faint horizontal and vertical lines across each tile. A crop of the middle of that texture, where a row of dark speckles runs across the grain and the lower half is lighter. A 2 × 2 repeat of pale wood with a large carved maple leaf in each tile.](../../../assets/comfyui/journal-l09-seamless-failures.webp)

*Failures, before the fix. ComfyUI v0.36.0: Z-Image-Turbo nvfp4 with Qwen3 4B fp4 mixed, seed 42, 8 steps, CFG 1, `res_multistep`, `simple`, workflow [`09-seamless.api.json`](https://github.com/spareilleux/learn/blob/d16b4d70b565257067309b7b8d7f51408cb81741/code/comfyui/workflows/09-seamless.api.json) with its cross set to 160 pixels, 64 of feather and denoise 0.7. From left to right: rosewood repeated 2 × 2; the middle 512 × 512 pixels of the rosewood; the prompt "flat top-down photograph of pale maple, subtle straight grain, even soft lighting, no shadows, wood texture", repeated 2 × 2.*

## To verify

- SDXL on Linux with CUDA, and on Apple Silicon with MPS: the course's GPU machine runs Windows; CI only installs the CPU builds.
- Which operation makes the text encoders give different results depending on whether the UNet is loaded, and whether it happens with other GPUs or drivers.
- Whether an ancestral sampler gives the same image on the CPU and on the GPU for a seed: its step noise is drawn on the device.
- Whether a perceptual hash would be stable across the cases of lesson 2.
- ControlNet chains, `start_percent`, and the exact step where a percent's noise level falls, which the lesson computed but didn't render.
- Kornia's `canny`: which step makes the edges differ between machines.
- Training a LoRA with ComfyUI's experimental nodes, and how much of 16 GB it takes for SDXL.
- Stacked LoRAs in the other order: same image, and same pixel hash or not.
- The emulated path for nvfp4 and fp8 on a GPU without their kernels; the course's machine has an RTX 50 series GPU only.
- Why the nvfp4 Z-Image network sampled faster with the bf16 text encoder than with the fp4 one.
- Sampling tiles from `SplitImageToTileList` and merging them with `ImageMergeTileList`: whether seams show at a low denoise.
- Whether `LoadImage` lists `.exr` files on Linux and macOS, and whether three.js's `EXRLoader` reads ComfyUI's uncompressed EXR in a browser.
- How browsers show the HLG AVIF of `SaveImageAdvanced`.
- What the `convrot` option of int8 does in comfy-kitchen's kernels.
- Warm render times with `--disable-dynamic-vram`, on a machine with enough free RAM.
- `execution_error` and `execution_interrupted` as the clients print them, `POST /interrupt` with a prompt id, and deleting a queued prompt: no run has produced them yet.
