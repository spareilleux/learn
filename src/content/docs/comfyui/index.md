---
title: ComfyUI, from beginner to expert — Mission
description: 'Learn ComfyUI, the node-based application for diffusion models, from a first image to production — the node graph, diffusion and reproducibility, workflows as JSON, the HTTP and WebSocket API from C# and Java, image editing, ControlNet, LoRA, recent models and their licenses, upscaling and textures, video, custom nodes and their security, and running it as a service — with renders measured on one GPU and the rest checked in CI without one.'
sidebar:
  label: Mission
  order: 0
---

:::note[How this course is tested]
The course's code is in [`code/comfyui`](https://github.com/spareilleux/learn/tree/main/code/comfyui): workflows in both JSON formats, a C# tool and a Java client. `check.sh` checks what runs without a GPU or a model: it validates and converts the workflows, starts [ComfyUI](https://github.com/Comfy-Org/ComfyUI) **v0.36.0** with `--cpu`, runs the C# and Java clients against it on a workflow that needs no model, and compares every output with the files in `expected/`. A workflow, `comfyui-examples.yml`, runs it on Linux, Windows and macOS. The renders, timings and pixel hashes in the lessons come from one machine: Windows 11, an NVIDIA GeForce RTX 5080 with 16 GB, and the ComfyUI portable build, in September 2026. Nothing about another GPU, driver or OS was measured, and the lessons say so where it matters.
:::

## Why I'm learning this

The site's other machine learning courses load models from code: [Candle](../candle/) in Rust, and ONNX Runtime in [GA's AI course](../ga-ai/). ComfyUI is the other way round. It is an application where you wire models together in a graph, in a browser, and its template library covers images, video, audio and 3D models.

I want to know how it works under the graph, what makes an image reproducible, and how a C# or Java service can use it as a render engine: for instance to generate textures for this site and for GuitarAlchemist, which is the project of the last lesson.

## Who this course is for

You write C# or Java. You know HTTP, JSON and asynchronous code. You don't need to know Python, PyTorch, or how diffusion models work: lesson 2 explains what you need, and links to the papers. The lessons' images were rendered on a 16 GB NVIDIA GPU, and SDXL used about 7 GB of it; how the later models fit on smaller cards is lesson 8's subject. Without a GPU, you can still follow the JSON and API lessons with the CPU workflow that CI uses.

## By the end of this course, I will be able to

- install ComfyUI on Windows, Linux or macOS, and run a text-to-image graph;
- explain what the checkpoint's networks, the seed, steps, CFG, sampler and scheduler do, and what makes a render reproducible;
- read, convert, validate and diff workflows in both JSON formats;
- queue workflows and follow them from C# and Java through the HTTP and WebSocket API;
- edit images with img2img, inpainting and outpainting, and control them with ControlNet and LoRA;
- choose a recent model for a machine and a use, read its license, and fit it in VRAM with quantized weights;
- upscale images and make seamless textures, and generate short videos;
- judge a custom node's code before installing it;
- run ComfyUI as a service behind an API of my own.

## Outline

| # | Lesson | In C# or Java terms |
|---|---|---|
| 1 | [The node graph, installing, and a first image](01-install-first-image/) | a dataflow graph, like TPL Dataflow blocks |
| 2 | [Diffusion, and what makes an image reproducible](02-diffusion-reproducibility/) | `new Random(seed)`, and floating-point determinism |
| 3 | [Workflows as JSON: the UI format, the API format, and diffs](03-workflow-json/) | `System.Text.Json`, Jackson, a schema |
| 4 | [The HTTP and WebSocket API from C# and Java](04-http-websocket-api/) | `HttpClient`, `ClientWebSocket`, `java.net.http` |
| 5 | [Img2img, inpainting and outpainting](05-img2img-inpainting/) | — |
| 6 | [ControlNet: edges and depth](06-controlnet/) | — |
| 7 | [LoRA: loading, stacking, and what training one involves](07-lora/) | a plugin that patches weights |
| 8 | [Recent models and their licenses, quantization and VRAM](08-recent-models-quantization/) | choosing a dependency and its license |
| 9 | Upscaling, seamless textures and HDR | — |
| 10 | Video | — |
| 11 | Custom nodes, and their security | NuGet or Maven packages that run code at install |
| 12 | ComfyUI in production: a service, a queue, several GPUs | a worker behind a job queue |
| 13 | Project: textures for this site and for GuitarAlchemist | — |
| — | [Journal](journal/) | |

Lessons 5 to 13 are the plan; they will change as the first ones teach me what matters.

## Models and images

The course starts with [Stable Diffusion XL base 1.0](https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0), under the CreativeML Open RAIL++-M License, and adds models lesson by lesson. Each lesson gives each model's license and download size. No model file is in the repository. Every image in the course has a caption with its model, seed and workflow, and no image shows a real person or a brand.

## Resources

- [ComfyUI documentation](https://docs.comfy.org/), and the [source at v0.36.0](https://github.com/Comfy-Org/ComfyUI/tree/ee71d5c4993f29086b27fde1629a945ae48425bf).
- [ComfyUI examples](https://comfyanonymous.github.io/ComfyUI_examples/), by ComfyUI's original author.
- [Hugging Face model hub](https://huggingface.co/models), where the models and their cards are published.
- R. Rombach et al., [High-Resolution Image Synthesis with Latent Diffusion Models](https://arxiv.org/abs/2112.10752), 2021, the paper behind Stable Diffusion.
