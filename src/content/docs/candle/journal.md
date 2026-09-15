---
title: Journal
description: Dated progress notes — Candle 0.11.0 pinned, the course code and how it is checked, the measurements, whether GA, IX and TARS use Candle, sixteen findings about Candle, its documentation and IX's, and items to verify.
sidebar:
  order: 99
---

## Progress

- [x] Candle read at the tag `0.11.0`, commit `31f35b1`; the course code depends on `candle-core` and `candle-nn` 0.11.0
- [x] Course code: examples, `expected/` outputs, seven `compile_fail` doctests, `check.sh`
- [x] Same outputs on Windows and on Linux (a `rust:1.94.0` container)
- [ ] CI on GitHub: the workflow is written, not pushed yet
- [x] Lesson 1: why Candle
- [x] Lesson 2: tensors
- [x] Lesson 3: CPU compute and performance
- [x] Lesson 4: automatic differentiation
- [ ] Lessons 5 to 12
- [x] French and Spanish translations of lessons 1 to 4

## 2026-09-15 — Candle, pinned

- The latest version on crates.io is **0.11.0**, published on June 26, 2026. Its sources are the tag `0.11.0`, commit [`31f35b147389700ed2a178ee66a91c3cc25cc80d`](https://github.com/huggingface/candle/commit/31f35b147389700ed2a178ee66a91c3cc25cc80d), cloned apart from this repository. `main` was at [`ddf1b87`](https://github.com/huggingface/candle/commit/ddf1b879dc3a1760cbcb3f3c4a7c6467850cec4a) on the same day.
- The workspace lists ten members, among them the WebAssembly examples, and keeps six more crates apart (the GPU kernels, `candle-onnx`, the book); `candle-transformers` has 125 entries under `models/` and `candle-examples` 111 examples.
- The course pins `=0.11.0` in `Cargo.toml` and commits `Cargo.lock`, rather than following `main` as the Candle book's `cargo add --git` does.
- The code uses the CPU only: no Cargo feature is switched on, no model is downloaded in this batch.

## 2026-09-15 — The course code

- [`code/candle`](https://github.com/spareilleux/learn/tree/c45b150/code/candle) is a workspace with one crate, `candle-course`: 13 examples, and `src/lib.rs` with the helpers `show` (rounds every value, so that the three systems print the same digits), `outcome` and `caught` (prints a panic's message), and the seven `compile_fail` doctests.
- [`check.sh`](https://github.com/spareilleux/learn/blob/c45b150/code/candle/check.sh) runs `cargo fmt --check`, `clippy --release --all-targets -D warnings`, `cargo test --release`, then each example, and compares its output and exit code with `expected/`. `l01_machine` and `l03_bench` depend on the machine: they run without comparison.
- Stable `rustdoc` checks that a `compile_fail` snippet fails, not with which error. One doctest first claimed `E0369` for `Result<Tensor> - f64`; compiling the snippet gave `E0277`. The workflow adds a nightly `cargo test --doc` on Linux, which checks the codes.
- The first release build compiled 128 crates in 73 seconds with `-j 4`. 72 of the 119 crates behind `candle-core` come from `tokenizers`.
- `data/builds.csv` is a copy of the IX course's file, from commit `d9ef7fb`, so that lesson 4 trains on the same 52 builds.
- `ix-autograd` comes from Git at IX commit `490c395`, the commit of the IX course, as a dev-dependency.
- On Linux, `check.sh` ran in Docker Desktop 29.2.1 (`rust:1.94.0`, `--cpus 4`): every compared output was identical to Windows.

## 2026-09-15 — The CI

- `.github/workflows/candle-examples.yml` is written: `check.sh` on `ubuntu-latest`, `windows-latest` and `macos-latest`, a cache of the Cargo registry, the Git checkouts and `target/`, keyed on `Cargo.lock`, and the nightly doctest step on Linux.
- It isn't pushed: the token this session pushes with can't create files under `.github/workflows/` without the `workflow` scope. Until it runs, macOS (ARM, NEON) is *to verify*, in particular the `f32` sums of lesson 4, which could round differently.

## 2026-09-15 — The measurements

- Intel Core Ultra 9 285K (24 cores, no hyper-threading), 64 GB, Windows 11 Pro, Rust 1.94.0. The machine ran other work at the same time; the lesson says so and treats differences under about 20% as noise.
- The first version of the forward-pass benchmark ran plain tensors, then `Var`s, once each, and showed the graph 35% faster. Running two alternating rounds showed a warm-up effect; the lesson shows the alternating version and says why.
- `target-cpu=native` built in 65 seconds in a separate target directory and changed nothing beyond the noise. `gemm` already picks AVX2 and FMA kernels at run time.
- In a container limited to 4 CPUs, Candle still counts 24 physical cores and starts 24 threads: the small network took 168 ms against 44 ms with `RAYON_NUM_THREADS=1`.

## 2026-09-15 — GA, IX and TARS

Commits read: GA [`32f143c`](https://github.com/GuitarAlchemist/ga/tree/32f143c866c126338b332e384e4a615cd4b44381), IX [`a7e5fbc`](https://github.com/GuitarAlchemist/ix/tree/a7e5fbce3d4a7a9d15bb9638b3bcba7c08c2941a) (with `ix-autograd` unchanged since `490c395`), TARS [`87464ce`](https://github.com/GuitarAlchemist/tars/tree/87464ce583c42cd11c3d76836e05842377455b24).

- None of the three depends on Candle. GA (C#) and TARS (F#) run their models with ONNX Runtime and `Microsoft.ML.Tokenizers`.
- IX wrote its own automatic differentiation, `ix-autograd`, over `ndarray`, and keeps a place for a Candle backend. Lesson 4 shows that its gradient and Candle's agree to `1e-9` on the IX course's regression.
- Where Candle could serve: GA's embeddings (lesson 7 compares), and an `ix-autograd` backend if IX needs more operations or a GPU. These are notes for later lessons, not proposals made to the projects.

## 2026-09-15 — Findings

Sixteen things this batch found, each shown by compiled code in the course unless marked. Nothing is filed as an issue or a pull request.

1. **A C compiler for `candle-core` 0.11.0.** It depends on `tokenizers` with the `onig` feature, which builds Oniguruma from C sources, for one file, the GGUF tokenizer ([lesson 1](../01-why-candle/)). `main` switched to `fancy-regex` in pure Rust; the next release should drop the requirement (*to verify*).
2. **`from_vec` and `from_slice` don't check the element count** when the shape has no hole: five values with a `(2, 3)` shape are accepted and panic later ([lesson 2](../02-tensors/)). [Issue #3812](https://github.com/huggingface/candle/issues/3812), fixed on `main` by [#3813](https://github.com/huggingface/candle/pull/3813) on August 13, 2026, after 0.11.0.
3. **Float functions on integer tensors panic** with `todo!("no unary function for u32")` instead of returning an error ([lesson 2](../02-tensors/)). Still the case on `main` at `ddf1b87`; no issue found about it.
4. **The CPU random generator can't be seeded**: `Device::Cpu.set_seed(42)` returns an error, so `rand` and `randn` aren't reproducible on the CPU ([lesson 2](../02-tensors/)).
5. **The README's cheat sheet doesn't compile**: `tensor.to_dtype(&DType::F16)?` passes a reference where `to_dtype` takes a `DType` ([lesson 1](../01-why-candle/), a doctest).
6. **`copy()` clones the whole storage**, not the view's elements: a 1000-element row of a 4 MB tensor still holds 4 MB after `copy()`; `force_contiguous` holds 4 KB ([lesson 3](../03-cpu-performance/)).
7. **A confusing message for one index too many**: `m.i((0, 0, 0))` on a matrix says "dimension index 0 out of range for shape []" ([lesson 2](../02-tensors/)).
8. **`squeeze` on a dimension whose size isn't 1 succeeds silently** and returns the tensor unchanged, like PyTorch ([lesson 2](../02-tensors/)).
9. **Gradients also go to plain tensors** that are direct inputs of recorded operations: the regression of lesson 4 computes gradients for its data ([lesson 4](../04-autodiff/)). Correct but extra work.
10. **`backward` on a non-scalar is seeded with ones without a warning**, where PyTorch refuses ([lesson 4](../04-autodiff/)).
11. **The default thread count ignores container CPU limits**: 24 threads under `--cpus 4`, four times slower on a small network than one thread ([lesson 3](../03-cpu-performance/)).
12. **`target-cpu=native` brought no measurable gain** for matrix products, element-wise operations or a small network on this machine; Candle's own `.cargo/config.toml` sets it for its examples ([lesson 3](../03-cpu-performance/)).
13. **`f16` matrix products aren't faster than `f32` on a CPU**: `gemm-f16` converts to `f32` blocks ([lesson 3](../03-cpu-performance/)).
14. **IX's documentation describes Candle as using "cuTENSOR"** ([`code-analysis-tools.md`, line 129](https://github.com/GuitarAlchemist/ix/blob/a7e5fbce3d4a7a9d15bb9638b3bcba7c08c2941a/docs/guides/code-analysis-tools.md?plain=1#L129)); Candle's CUDA features use cuBLAS, cuBLASLt, cuRAND, NVRTC and optionally cuDNN ([lesson 1](../01-why-candle/)). Read in the sources, not run.
15. **`hf-hub`**: Candle 0.11.0's workspace asks for `hf-hub` 0.5.0 while crates.io's latest is 1.0.0. For lesson 6 (*to verify* what changed).
16. **The Candle book installs from Git**: `cargo add --git https://github.com/huggingface/candle.git candle-core` follows `main`, so a book example can depend on code that isn't released ([lesson 1](../01-why-candle/)).

## To verify

- The workflow's first run on the three systems, and the `f32` outputs on macOS ARM.
- The C compiler requirement after the next Candle release.
- `default_num_threads` on Apple Silicon, which counts performance cores only.
- `CANDLE_GRAD_DO_NOT_DETACH` and second derivatives.
- Why contiguous element-wise operations take half the time on Linux as on Windows, on the same processor (allocation, by hypothesis).
