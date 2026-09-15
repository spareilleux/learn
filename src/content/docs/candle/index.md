---
title: Candle, Hugging Face's machine learning in Rust — Mission
description: Learn Candle, Hugging Face's machine learning framework in Rust, from its tensors to serving models — tensors, CPU performance, autodiff, candle-nn, safetensors and the Hub, transformers, quantized LLMs, deployment and interop with C# and Java — with every output printed by pinned, compiled code.
sidebar:
  label: Mission
  order: 0
---

:::note[How this course is tested]
Every result in this course is printed by a program in [`code/candle`](https://github.com/spareilleux/learn/tree/main/code/candle): a Cargo workspace that depends on `candle-core` and `candle-nn` **0.11.0**, pinned with `=`, on the CPU only. `check.sh` runs `cargo fmt`, `clippy`, the tests (with a `compile_fail` doctest for each snippet a lesson shows being rejected) and every example, and compares each output with the file in `expected/`. The outputs in the lessons were captured with Rust 1.94.0 on Windows 11 in September 2026, and `check.sh` gave the same outputs on Linux, in a `rust:1.94.0` container. A workflow, `candle-examples.yml`, runs the same script on Linux, Windows and macOS; it isn't on GitHub yet, so macOS is *to verify*.
:::

## Why I'm learning this

The [IX course](../machine-learning-ix/) wrote machine learning algorithms by hand in Rust, and the [GA AI course](../ga-ai/) followed embeddings computed in C# by ONNX Runtime. Between the two sits the question this course answers: can a Rust program load a published model, run it, and even train a small one, with no Python and no native runtime next to it?

[Candle](https://github.com/huggingface/candle) is Hugging Face's answer. It is a tensor library with automatic differentiation, a set of layers, and implementations of well-known models, from BERT to quantized LLMs, all compiled into your binary. I want to know what it does under the tensors, what it costs on a CPU, where its edges are, and how a C# or Java service would use it.

## Who this course is for

You write C# or Java, and you know the basics of Rust from the [Rust course](../rust-for-csharp-java/): ownership, `Result` and `?`, traits, Cargo. You know the machine learning notions of the [IX course](../machine-learning-ix/): a loss, a gradient, gradient descent, training and test sets. This course doesn't explain them again; it links to them.

You don't need Python or PyTorch. Where PyTorch's way of doing something helps, a lesson shows it next to Candle's, since most model code you'll read is written in it.

## Candle, TorchSharp and DJL in one table

| | TorchSharp (C#) | DJL (Java) | Candle (Rust) |
|---|---|---|---|
| A tensor | `torch.Tensor`, over libtorch | `NDArray`, over the engine you choose | `candle_core::Tensor`, pure Rust on the CPU |
| An error | an exception | an exception | a `Result` from every operation |
| Broadcasting | implicit | implicit | explicit: `broadcast_add` |
| Gradients | `requires_grad`, `.grad` accumulates | `GradientCollector` | `Var`, `backward` returns a new `GradStore` |
| Model files | its own format, and TorchScript | the engine's format | `safetensors`, GGUF |
| What you ship | .NET app plus libtorch packages | JVM app plus the engine's native libraries | one binary, or a WebAssembly module |

Sources: [TorchSharp README](https://github.com/dotnet/TorchSharp/blob/8f4def03b641b6753f18076aa5438f8eaaef2d30/README.md), [DJL README](https://github.com/deepjavalibrary/djl/blob/f3782179ff48a1bd31382667dbfae1f568891a55/README.md), [Candle README](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/README.md), and lessons 1 to 4 for the Candle column.

## Candle, pinned

The course uses the latest version on crates.io, [**0.11.0**](https://crates.io/crates/candle-core/0.11.0), published on June 26, 2026. Its sources are the tag `0.11.0`, commit [`31f35b1`](https://github.com/huggingface/candle/tree/31f35b147389700ed2a178ee66a91c3cc25cc80d), and every link to Candle's code points there, so the line numbers stay right when `main` moves. [`Cargo.toml`](https://github.com/spareilleux/learn/blob/c45b150/code/candle/Cargo.toml) pins the crates:

```toml
[workspace.dependencies]
candle-core = "=0.11.0"
candle-nn = "=0.11.0"
```

When `main` has already fixed something the lessons meet, they say so, with the commit.

## By the end of this course, I will be able to

- create, reshape, index and combine tensors, and read Candle's run-time errors;
- tell a view from a copy, and measure and tune what an operation costs on a CPU;
- compute gradients with `Var` and `backward`, check them, and train a model with them;
- build and train a network with `candle-nn`, and save and load its weights with `safetensors`;
- download a model from the Hugging Face Hub at a pinned revision, compute embeddings, and run a quantized LLM;
- serve a model over HTTP, in a container and in the browser, and call it from C# and Java;
- port a small PyTorch model to Candle and check that both give the same outputs.

## Outline

| # | Lesson | If you know PyTorch |
|---|---|---|
| 1 | [Why Candle](01-why-candle/) | `pip install torch`, `torch.cuda.is_available()` |
| 2 | [Tensors](02-tensors/) | `torch.tensor`, `view`, indexing, broadcasting |
| 3 | [CPU compute and performance](03-cpu-performance/) | `contiguous()`, `torch.set_num_threads` |
| 4 | [Automatic differentiation](04-autodiff/) | `requires_grad`, `backward()`, `.grad` |
| 5 | `candle-nn`: modules, layers, optimizers, a small network trained on a public data set | `nn.Module`, `nn.Linear`, `torch.optim` |
| 6 | Formats and the Hub: `safetensors`, `VarBuilder`, `hf-hub`, the cache, model licences | `torch.load`, `from_pretrained` |
| 7 | Transformers for inference: an embedding model, tokenizers, similarity, compared with GA's embeddings | `transformers.AutoModel` |
| 8 | Quantized LLMs: GGUF, quantized tensors, a small model, sampling | `llama.cpp`, `bitsandbytes` |
| 9 | GPUs: the CUDA and Metal features, in theory, *to verify* | `.to("cuda")` |
| 10 | Deployment: an HTTP service with axum, a single binary, a container, WebAssembly in the browser | TorchServe |
| 11 | Interop: calling a Candle model from C# and from Java | TorchSharp, DJL |
| 12 | Writing your own model: port a small PyTorch model and compare the outputs | — |
| — | [Journal](journal/) | |

Lessons 5 to 12 are the plan; they'll change as the first ones teach me what matters. Lesson 9 stays theoretical because the GPU of the machine this course is written on is reserved for other work.

## Resources

- [Candle at `31f35b1`](https://github.com/huggingface/candle/tree/31f35b147389700ed2a178ee66a91c3cc25cc80d), its [examples](https://github.com/huggingface/candle/tree/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-examples/examples) and the [Candle book](https://huggingface.github.io/candle/)
- On docs.rs: [`candle-core`](https://docs.rs/candle-core/0.11.0/candle_core/), [`candle-nn`](https://docs.rs/candle-nn/0.11.0/candle_nn/), [`candle-transformers`](https://docs.rs/candle-transformers/0.11.0/candle_transformers/)
- [Hugging Face Hub documentation](https://huggingface.co/docs/hub/index) and [`safetensors`](https://huggingface.co/docs/safetensors)
- [PyTorch documentation](https://docs.pytorch.org/docs/stable/index.html), the reference most model code is written against
- The [Rust course](../rust-for-csharp-java/) and the [IX course](../machine-learning-ix/), this course's prerequisites
