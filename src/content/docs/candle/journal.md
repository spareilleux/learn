---
title: Journal
description: Dated progress notes — Candle 0.11.0 pinned, the course code and how it is checked, the measurements, whether GA, IX and TARS use Candle, sixteen findings about Candle, its documentation and IX's, lesson 5's predictions, results and QA table, and items to verify.
sidebar:
  order: 99
---

## Progress

- [x] Candle read at the tag `0.11.0`, commit `31f35b1`; the course code depends on `candle-core` and `candle-nn` 0.11.0
- [x] Course code: examples, `expected/` outputs, nine `compile_fail` doctests, `check.sh`
- [x] Same outputs on Windows and on Linux (a `rust:1.94.0` container)
- [x] CI on GitHub: Linux, Windows and macOS ARM, first run on 2026-09-16
- [x] Lesson 1: why Candle
- [x] Lesson 2: tensors
- [x] Lesson 3: CPU compute and performance
- [x] Lesson 4: automatic differentiation
- [x] Lesson 5: a first network with `candle-nn`
- [ ] Lessons 6 to 12
- [x] French and Spanish translations of lessons 1 to 5

## QA

What the course found in Candle from lesson 5 on; findings 1 to 16 are listed in the [2026-09-15 entry](#2026-09-15--findings). Links point to Candle `0.11.0`, commit `31f35b1`; `main` was read at [`5ba5d5b`](https://github.com/huggingface/candle/tree/5ba5d5b468b5b1df40e82dd3d556987bedeea041) (September 28, 2026).

| # | Expected | What happens | Where | Measurement | Status |
|---|---|---|---|---|---|
| 17 | `binary_cross_entropy_with_logit` gives a finite loss and gradient for any logit | It takes the sigmoid, then `log p` and `log(1 − p)`: NaN when a confident prediction is right, infinity when it is wrong, a NaN gradient in both cases | [`loss.rs:64-74`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-nn/src/loss.rs#L64-L74) | `f32`: logit 17, target 1 → NaN (16 → `1.192e-7`); −100, target 0 → NaN. `f64`: 37 → NaN (36 → `2.220e-16`). The stable form is finite in all eight cases ([lesson 5](../05-candle-nn/)) | Reproduced; reported upstream as [issue #2561](https://github.com/huggingface/candle/issues/2561) (October 14, 2024, open); same code on `main` |
| 18 | The target type the documentation gives works | The documentation of `binary_cross_entropy_with_logit` calls the target "a tensor of u32"; `u32` targets fail | [`loss.rs:60`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-nn/src/loss.rs#L60) | `dtype mismatch in mul, lhs: U32, rhs: F32` | Reproduced; same text on `main`; not reported |
| 19 | An error about an index type names the index type | `gather` reports the type of the tensor it reads from | [`cpu_backend/mod.rs:2883-2890`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/cpu_backend/mod.rs#L2883-L2890); `index_select`, `scatter`, `scatter_add`, `index_add` at lines 2879, 2905, 2924, 2973 (read, not run) | `f32` targets for `f64` logits: `unsupported dtype F64 for op gather` | Reproduced for `gather`; same code on `main`; no issue found |
| 20 | `cross_entropy` rejects a target of `u32::MAX`, or documents what it does | `gather` writes 0 for its type's maximum, a rule since [PR #2940](https://github.com/huggingface/candle/pull/2940): the row adds nothing, but `nll` still divides by the batch size. Neither documentation says so | [`cpu_backend/mod.rs:623-626`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/cpu_backend/mod.rs#L623-L626), [`loss.rs:14-30`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-nn/src/loss.rs#L14-L30) | `0.1725049744` = (row 1 + row 3) / 3; PyTorch's `ignore_index` averages over the other rows: `0.2587574616` | Reproduced; not reported |
| 21 | `linear` initializes like PyTorch's `nn.Linear` | A Kaiming normal, standard deviation `√(2 / in)`: `√6 ≈ 2.449` times `nn.Linear`'s | [`linear.rs:84-94`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-nn/src/linear.rs#L84-L94), [`init.rs:105-109`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-nn/src/init.rs#L105-L109) | 512 × 512: standard deviation within 1% of 0.0625, 4.55% of the weights beyond two standard deviations | Confirmed; a design choice, not a defect, to know when porting a model |
| 22 | An optimizer given a variable it won't update says so | Non-float variables are dropped and variables without a gradient skipped, without an error | [`optim.rs:44-47`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-nn/src/optim.rs#L44-L47), [`optim.rs:123`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-nn/src/optim.rs#L123), [`optim.rs:58-65`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-nn/src/optim.rs#L58-L65) | `SGD::new` with a `U32` and an `F32` variable keeps 1; a variable outside the loss stays unchanged | Reproduced; by design, not documented |

## Experiments

| Question | Hypothesis, written on 2026-09-30 before the code | Result | Verdict | Entry, code |
|---|---|---|---|---|
| How does `linear` initialize? | Weight standard deviation within 1% of 0.0625 on 512 → 512, `√6` times PyTorch's; biases within ±0.0442 | Within 1%; ratio 2.449; every bias within ±0.0442; 4.55% beyond two standard deviations, as a normal distribution | Confirmed | [2026-10-01](#2026-10-01--lesson-5-results-against-the-predictions), [`l05_modules.rs`](https://github.com/spareilleux/learn/blob/40470dc/code/candle/course/examples/l05_modules.rs#L94-L125) |
| Are two `VarMap`s filled by the same calls equal? | No, the CPU generator can't be seeded | Different; equal after `reseed(…, 5)` | Confirmed | [2026-10-01](#2026-10-01--lesson-5-results-against-the-predictions), [`l05_modules.rs`](https://github.com/spareilleux/learn/blob/40470dc/code/candle/course/examples/l05_modules.rs#L127-L152) |
| Does `cross_entropy` match the formula and survive large logits? | Equal to `1e-12` in `f64`; finite at 1000 where naive softmax-then-log gives NaN | `0.2458859914` both ways; 0, 1000 and 2000 for logits 1000, 0, −1000; naive: `[NaN, -inf, -inf]` | Confirmed | [2026-10-01](#2026-10-01--lesson-5-results-against-the-predictions), [`l05_losses.rs`](https://github.com/spareilleux/learn/blob/40470dc/code/candle/course/examples/l05_losses.rs#L32-L68) |
| Where does `binary_cross_entropy_with_logit` break? | NaN at `f32` logit 17 (16 finite), at −100 for target 0, at `f64` logit 37 (36 finite); stable form finite | Exactly those thresholds; a confident wrong prediction gives infinity; the gradient is NaN in all six failing cases | Confirmed | [2026-10-01](#2026-10-01--lesson-5-results-against-the-predictions), [`l05_losses.rs`](https://github.com/spareilleux/learn/blob/40470dc/code/candle/course/examples/l05_losses.rs#L93-L137) |
| Do `SGD` and `AdamW` match their algorithms? | SGD bit for bit; three AdamW steps to `1e-12` in `f64` | SGD bit for bit; AdamW bit for bit too, at each of the three steps | Confirmed, beyond the hypothesis | [2026-10-01](#2026-10-01--lesson-5-results-against-the-predictions), [`l05_optimizers.rs`](https://github.com/spareilleux/learn/blob/40470dc/code/candle/course/examples/l05_optimizers.rs#L19-L72) |
| What does an optimizer do with a `u32` variable? | `SGD` built from a `u32` and an `f32` `Var` holds one | Holds 1; `AdamW::new` accepts both without an error | Confirmed | [2026-10-01](#2026-10-01--lesson-5-results-against-the-predictions), [`l05_optimizers.rs`](https://github.com/spareilleux/learn/blob/40470dc/code/candle/course/examples/l05_optimizers.rs#L74-L95) |
| How well does 4 → 16 → 3 classify Iris? | At least 28 of 30 test flowers after 300 AdamW epochs at 0.01; errors only between versicolor and virginica | 29 of 30; the error is a virginica (row 120) taken for a versicolor; training 118 of 120 | Confirmed | [2026-10-01](#2026-10-01--lesson-5-results-against-the-predictions), [`l05_iris.rs`](https://github.com/spareilleux/learn/blob/40470dc/code/candle/course/examples/l05_iris.rs#L52-L98) |
| Does `f32` change the result? | Same 30 test predictions; final loss within `1e-4` of `f64` | Same predictions; same loss to four decimals at all six reported epochs | Confirmed | [2026-10-01](#2026-10-01--lesson-5-results-against-the-predictions), [`l05_iris.rs`](https://github.com/spareilleux/learn/blob/40470dc/code/candle/course/examples/l05_iris.rs#L100-L112) |
| SGD at 0.1 against AdamW at 0.01? | SGD ends with a higher training loss | 0.0846 against 0.0355, same 29 of 30; SGD was ahead at epoch 10 (0.6089 against 0.9078) | Confirmed | [2026-10-01](#2026-10-01--lesson-5-results-against-the-predictions), [`l05_iris.rs`](https://github.com/spareilleux/learn/blob/40470dc/code/candle/course/examples/l05_iris.rs#L114-L126) |

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

## 2026-09-30 — Lesson 5: predictions before the first run

Written from `candle-nn` 0.11.0's sources, before the lesson's code existed; the results entry will quote each one against what the programs print. The data set is Iris, from the UCI Machine Learning Repository (Fisher, 1936, [doi:10.24432/C56C76](https://doi.org/10.24432/C56C76), CC BY 4.0), in its corrected version `bezdekIris.data`; the archive also holds `iris.data`, whose rows 35 and 38 differ from Fisher's paper.

1. **Initialization.** [`linear`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-nn/src/linear.rs#L84-L94) draws its weights from a normal distribution of standard deviation √(2 / in), Kaiming with the ReLU gain ([`init.rs`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-nn/src/init.rs#L105-L109)), and its biases uniformly in ±1/√in. On a 512 → 512 layer, the measured weight standard deviation should be within 1 % of 0.0625, √6 ≈ 2.45 times PyTorch's default for `nn.Linear` (uniform in ±1/√in, standard deviation 1/√(3 · in)), and every bias within ±0.0442, as in PyTorch.
2. **Reproducibility.** Two `VarMap`s filled by the same `linear` calls get different weights, because the CPU generator can't be seeded (finding 4). The course will overwrite every variable with values from its own seeded generator.
3. **Cross-entropy.** `loss::cross_entropy` should equal the mean of −log softmax at the target, computed by hand, to 1e-12 in `f64`, and stay finite for logits of 1000, where softmax-then-log written naively (without subtracting the maximum) gives NaN.
4. **Binary cross-entropy with logits.** [`binary_cross_entropy_with_logit`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-nn/src/loss.rs#L64-L74) takes the sigmoid, then logarithms of `p` and `1 − p`, so a confident and *correct* prediction should give NaN: in `f32`, a logit of 17 with target 1 (16 stays finite) and a logit of −100 with target 0; in `f64`, a logit of 37 with target 1 (36 stays finite). The stable form `max(x, 0) − x·y + log(1 + e^−|x|)` stays finite everywhere. [Issue #2561](https://github.com/huggingface/candle/issues/2561) has reported the instability since 2024.
5. **Optimizers.** An [`SGD`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-nn/src/optim.rs#L31-L70) step equals `θ − lr · g` bit for bit (there is no momentum). Three [`AdamW`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-nn/src/optim.rs#L117-L183) steps equal PyTorch's AdamW algorithm written by hand (decoupled decay `θ · (1 − lr · λ)`, bias-corrected moments, ε outside the square root) to 1e-12 in `f64`.
6. **Integer variables.** Both optimizers silently drop variables whose type isn't a float: an `SGD` built from a `u32` `Var` and an `f32` `Var` holds one variable.
7. **Iris.** A 4 → 16 → 3 network with ReLU, trained on 120 rows (40 per species, standardized with the training set's means and deviations) for 300 full-batch epochs of `AdamW` with a learning rate of 0.01, classifies at least 28 of the 30 held-out rows correctly, and any errors are between versicolor and virginica, none on setosa.
8. **`f32` against `f64`.** The same training in `f32` gives the same 30 test predictions, and a final training loss within 1e-4 of the `f64` one.
9. **`SGD` against `AdamW`.** Plain `SGD` with a learning rate of 0.1, from the same weights for the same 300 epochs, ends with a higher training loss than `AdamW` at 0.01.

## 2026-10-01 — Lesson 5: results against the predictions

The five examples ran on Windows 11 with Rust 1.94.0; `check.sh` passed (formatting, clippy, 9 doctests, 18 examples, the 11 outputs compared before this lesson unchanged), and the nightly doctests (1.97.0) confirmed `E0599` for the two new `compile_fail` snippets. The code is commit [`40470dc`](https://github.com/spareilleux/learn/tree/40470dc/code/candle).

1. **Initialization**: confirmed. On 262,144 weights, the standard deviation is within 1% of 0.0625 and 4.55% of the weights lie beyond two standard deviations, as for a normal distribution; ratio to PyTorch's `nn.Linear`, 2.449; every bias within ±0.0442. The program prints checks, not the random values.
2. **Reproducibility**: confirmed. Two `VarMap`s differ; `reseed` makes them equal, with uniform draws whose standard deviation matches `linear`'s.
3. **Cross-entropy**: confirmed, `0.2458859914` by Candle and by hand. Logits of 1000 give 0, 1000 and 2000; the naive version gives `[NaN, -inf, -inf]`.
4. **Binary cross-entropy with logits**: confirmed at every threshold predicted. Not predicted: a confident *wrong* prediction gives infinity rather than NaN, and the gradient is NaN in all six failing cases.
5. **Optimizers**: confirmed, and more: the three AdamW steps match the transcription bit for bit, not only to `1e-12`, because it repeats `optim.rs`'s order of operations. PyTorch 2.14 orders them differently ([`adam.py`, lines 533-546](https://github.com/pytorch/pytorch/blob/v2.14.0/torch/optim/adam.py#L533-L546)).
6. **Integer variables**: confirmed, `SGD` keeps 1 of 2. A variable outside the loss is also left alone without an error.
7. **Iris**: confirmed, 29 of 30 held-out flowers. The error is row 120 of `bezdekIris.data`, a virginica of 6.0, 2.2, 5.0 and 1.5 cm taken for a versicolor; no setosa error.
8. **`f32`**: confirmed, the same 30 predictions and the same losses to four decimals.
9. **SGD**: confirmed at the end, 0.0846 against 0.0355. Not predicted: SGD was ahead at epoch 10.

All nine hypotheses held. Most were read from `candle-nn`'s sources, so the run mostly confirmed the reading; the findings came from what wasn't predicted, rows 18 to 20 of the QA table: the documented `u32` target that fails, the error that names the wrong type, and the `u32::MAX` target that is skipped but counted. The CI that ran on 2026-09-16 ([run 35096038472](https://github.com/spareilleux/learn/actions/runs/35096038472), commit `f922f5d`) passed on Linux, Windows and macOS on an `arm64` image, which settles the earlier *to verify* about `f32` on macOS ARM for lessons 1 to 4. The CI of lesson 5's pull request is *to verify*.

## 2026-10-02 — Lesson 5 on CI

The pull request's CI ([run 36865098140](https://github.com/spareilleux/learn/actions/runs/36865098140), commit `fd3359e`, October 1) passed on the three systems: on Ubuntu 24.04, on Windows (image `windows-2025-vs2026`) and on macOS on an `arm64` image (`macos-26-arm64`), the five lesson 5 examples matched the outputs in `expected/` line for line, the 11 outputs compared before them too, and the nine doctests passed; on Linux, the nightly toolchain also confirmed `E0599` for the two new `compile_fail` snippets. The outputs that could have depended on the platform held: the losses to four decimals, the `f32` training, the subnormal gradient printed `4e-44`, the seeded weights and the initialization checks. This settles the *to verify* above.

## To verify

- Whether training on `iris.data` instead of `bezdekIris.data` changes the lesson 5 results (row 35 is a test flower).
- PyTorch's AdamW against the lesson 5 numbers: equal to rounding, by hypothesis, not to the bit.
- The C compiler requirement after the next Candle release.
- `default_num_threads` on Apple Silicon, which counts performance cores only.
- `CANDLE_GRAD_DO_NOT_DETACH` and second derivatives.
- Why contiguous element-wise operations take half the time on Linux as on Windows, on the same processor (allocation, by hypothesis).
