---
title: "20. On the GPU: IX's WGSL shaders, their limits and their speed-ups"
description: "IX's ix-gpu runs WGSL compute shaders through wgpu 28, tested with eight predictions written before the first run; all eight held. naga rejects the dot product's shader for a reserved word, and the function panics. The kNN shader keeps one candidate per thread and loses neighbours in 135 of 1,000 queries, close to the 125 a birthday-style count predicts. The cosine functions use two different thresholds, and similarity_matrix returns 1 on the CPU where it returns 0 on the GPU. The default limits make the guide's own example panic. The GPU's matrix product equals the CPU loop once multiply-adds are fused. It beats the guide's speed-ups at large sizes and loses at 64³."
sidebar:
  order: 20
---

A GPU runs one small program, a *compute shader*, on thousands of threads at once. IX's pinned [`ix-gpu`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu) crate writes its shaders in [WGSL](https://www.w3.org/TR/WGSL/), the shading language of WebGPU. It runs them through [wgpu](https://wgpu.rs/) 28, which checks each one with its [naga](https://docs.rs/naga/28.0.0/naga/) front end and validator before handing it to Vulkan, DX12 or Metal.

A few terms first:
- threads come in *workgroups*, here of 256;
- a workgroup can share a small memory declared `var<workgroup>`;
- a *dispatch* launches a grid of workgroups;
- data goes in and out through *storage buffers*.

Every GPU function of the crate takes a `GpuContext`, which holds wgpu's device and queue. Most functions have a CPU twin. `ix-nn` relies on one of them: its attention calls `matmul_gpu` for its two matrix products when it is given a context ([`attention.rs` 419-494](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/attention.rs#L419-L494)). This is the attention of the transformer that [lesson 13](../13-transformer/) studied on the CPU.

The eight predictions this lesson tests were [written in the journal](../journal/#2026-09-30--lesson-20-predicted-before-measuring) and committed before any of its code existed. [The results](../journal/#2026-09-30--lesson-20-measured) follow them.

The CI runners have no GPU the course can count on, so the code splits in two:
- **Runs anywhere.** [`gpu.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/src/gpu.rs) holds this part: naga on the five shaders, a port of the kNN shader's loop, the thresholds and the limits. The shaders are copied byte for byte from the pinned commit into [`shaders.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/src/gpu/shaders.rs). [`l20_wgsl.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/examples/l20_wgsl.rs) prints the results, and CI compares its output on Windows, Linux and macOS.
- **Needs an adapter.** CI doesn't run [`l20_on_gpu.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/src/bin/l20_on_gpu.rs). The lesson quotes one run on the author's machine, kept in [`local/l20_on_gpu.txt`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/local/l20_on_gpu.txt). The ignored tests of [`tests/l20_gpu.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/tests/l20_gpu.rs) check the same predictions: `cargo test --release --test l20_gpu -- --ignored --test-threads=1`.

[`crosscheck.py`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/crosscheck/crosscheck.py) replays the kNN loop, the thresholds and the limits in [NumPy](https://numpy.org/doc/stable/) float32, and finds the same numbers.

## 1. What runs where

`GpuContext::new()` asks wgpu for a high-performance adapter, then for a device with `Limits::default()` ([`context.rs` 24-58](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/context.rs#L24-L58)). The program prints what it got:

```text
== the adapter
  NVIDIA GeForce RTX 5080 (Vulkan); GpuContext::new() took 532 ms
```

IX's French guide says that `GpuContext::new()` takes 10 to 100 ms ([`introduction-calcul-gpu.md` 166](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/docs/fr/calcul-gpu/introduction-calcul-gpu.md?plain=1#L166)). It took 532 ms in this run, and 1,316 ms in the first. After the first run, the program was changed to create three more contexts in the same process, and their median time was 274 ms. The guide's advice holds: create one context and keep it. But budget a quarter of a second or more for it, not a tenth.

## 2. A reserved word

`dot_product_gpu` reduces a product in workgroup memory declared as `var<workgroup> shared: array<f32, 256>;` ([`similarity.rs` 81](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/similarity.rs#L81)). `shared` is one of WGSL's [reserved words](https://www.w3.org/TR/WGSL/#reserved-words): the specification keeps it for later use, so a shader may not name anything `shared`. The lesson gives the five shaders of the crate that it studies to naga's WGSL front end, then to its validator, and counts the variables in the workgroup address space:

```text
== P1, naga 28 on five shaders of ix-gpu, copied from the pinned commit
  cosine: parses; validates: yes; workgroup variables: 3
  dot product: parse error: name `shared` is a reserved keyword
  dot product, `shared` renamed: parses; validates: yes; workgroup variables: 1
  distance matrix: parses; validates: yes; workgroup variables: 0
  kNN: parses; validates: yes; workgroup variables: 0
  matrix product: parses; validates: yes; workgroup variables: 0
```

The cosine shader is the same reduction under other names, and it passes. Renamed, the dot product passes too.

On a GPU, the parse error surfaces when `create_shader_module` runs. wgpu hands an error that nobody captured to a default handler, and that handler panics ([`wgpu_core.rs` 694-697](https://docs.rs/wgpu/28.0.0/src/wgpu/backend/wgpu_core.rs.html#694-697)). `ix-gpu` captures none. Its `GpuError::ShaderCompilation` and `GpuError::BufferMapping` are declared and never built ([`context.rs` 158-163](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/context.rs#L158-L163)). A panic in a library call takes the caller's thread down with it. That is why the program makes every call that can panic in a child process of its own, `l20_on_gpu probe …`, spawned with [`std::process::Command`](https://doc.rust-lang.org/std/process/struct.Command.html):

```text
== P1 on the GPU
  dot_product_gpu, in a process of its own: returns: no; message starts with "wgpu error": yes; contains naga's "name `shared` is a reserved keyword": yes
  cosine_similarity_gpu against cosine_similarity_cpu, 1000 components: gap 3.7e-9
```

So at this commit, with wgpu 28, `dot_product_gpu` can't return. The crate's own tests don't reach the GPU either: the GPU tests of `knn.rs` and `distance.rs` are commented out, under "GPU tests require hardware" ([`knn.rs` 367-376](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/knn.rs#L367-L376), [`distance.rs` 242](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/distance.rs#L242)).

The last line of the naga output contradicts a doc comment. `matmul.rs` says its shader "Uses tiled approach with shared memory for better cache behavior" ([`matmul.rs` 11](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/matmul.rs#L11)). But the module declares no workgroup variable: each thread computes one output element straight from global memory. The matrix product guide admits as much and calls the current shader a simple per-element approach ([`multiplication-matricielle-gpu.md` 226](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/docs/fr/calcul-gpu/multiplication-matricielle-gpu.md?plain=1#L226)). The similarity guide still sends its reader to "le compute shader tuilé sous le capot" ([`recherche-de-similarite.md` 231](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/docs/fr/calcul-gpu/recherche-de-similarite.md?plain=1#L231)). One more doc comment is off: `euclidean_distance_cpu`'s reads "Euclidean distance on GPU (via compute shader)" ([`similarity.rs` 249](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/similarity.rs#L249)).

## 3. One candidate per thread

`batch_knn_gpu` runs one workgroup of 256 threads per query ([`knn.rs` 34-229](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/knn.rs#L34-L229)):
1. Thread t scans the references t, t + 256, t + 512, … and keeps only the nearest one.
2. The CPU sorts the 256 candidates and keeps the first k.

The doc comment describes something else: "a parallel selection of the k smallest", with "k limited to 32 (stored in shared memory per thread)" ([`knn.rs` 27-33](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/knn.rs#L27-L33)). The shader has no workgroup variable, and k is not limited.

Call the references whose index is congruent to t modulo 256 *class t*. The k nearest come out right if and only if they fall in k different classes. If two of them share a class, that class's thread keeps only one of them, and a farther reference takes the lost one's place.

For references and a query that are independent and identically distributed, the set of the k nearest indices is a uniform k-subset of {0, …, N − 1}. So P(right) = e_k(s₀, …, s₂₅₅)/C(N, k), where s_t is the size of class t and e_k the k-th elementary symmetric polynomial. It is the birthday problem with classes of unequal size. With N = 1,000 there are 232 classes of 4 and 24 of 3, and for k = 10 the formula gives P(wrong) = 0.1253. The prediction was 90 to 160 wrong queries out of 1,000, around 125.3 with a standard deviation of 10.5.

`knn_shader_port` ports the loop to Rust, in f32, with the same order of operations. This program compares it with `batch_knn_cpu`, IX's CPU twin, which sorts every reference:

```text
== P2, the kNN shader's loop ported to Rust: 1000 references and 1000 queries uniform in [0, 1)^8, k = 10
  P(two of the 10 nearest share a class modulo 256) = 1 - e_10(class sizes) / C(1000, 10) = 0.1253
  queries whose 10 nearest differ from batch_knn_cpu's: 135; with k = 1: 0; with the first 256 references: 0
  true neighbours the port returns: 9855 of 10000
```

The port loses neighbours in 135 queries: 145 of the 10,000 true neighbours, so a few queries lose two. It never fails for k = 1, and never when each class holds a single reference. A unit test adds the control: with at most 256 references, the port equals `batch_knn_cpu` for k = 1, 5, 200 and 250. NumPy's float32 replay finds the same 135 and the same 9,855.

The port stands in for the shader only if the GPU does the same thing, and P6 checks that on the author's adapter:

```text
== P6, batch_knn_gpu on P2's data, k = 10
  queries whose 10 indices equal the port's, in order: 1000 of 1000; largest distance gap 1.2e-7
  queries whose 10 nearest differ from batch_knn_cpu's: GPU 135, port 135
  the first 256 of the 1000 references: equal to batch_knn_cpu's, in order, for 1000 of 1000
```

The loss does not shrink with more data. After the first run, the formula was also evaluated at other sizes:

```text
== exploratory
  P(some of the 10 nearest lost): N = 2000 0.1444, N = 10000 0.1593; N = 1000 with k = 5 0.0291, with k = 20 0.4371
```

As N grows, the classes even out, and P(wrong) tends to the plain birthday problem with 256 days, 1 − (256 · 255 ⋯ 247)/256¹⁰ ≈ 0.1631. It grows fast with k. Exact k-selection on a GPU keeps k candidates per thread, then merges them. [Johnson, Douze and Jégou (2021)](https://doi.org/10.1109/TBDATA.2019.2921572) describe how Faiss does this in registers.

## 4. Two thresholds and a diagonal

Three functions decide in two different ways when a norm is too small for a cosine:
- `cosine_similarity_cpu` returns 0 when either norm is below 10⁻¹⁰ ([`similarity.rs` 235-247](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/similarity.rs#L235-L247));
- `similarity_matrix_gpu` and `batch_top_k` return 0 when the product of the two norms is at most 10⁻¹⁰ ([`batch.rs` 73](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/batch.rs#L73), [157](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/batch.rs#L157)).

Separately, `similarity_matrix_cpu` writes 1 on the diagonal without computing it ([`batch.rs` 23-37](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/batch.rs#L23-L37)). Two vectors a and b = 2a point the same way, with norms 3·10⁻⁶ and 6·10⁻⁶:

```text
== P3, a = (1e-6, 2e-6, 2e-6), b = 2a, z = 0, in f32
  cosine_similarity_cpu(a, b) 1.000000; similarity_matrix(None, [a, b])[0][1] 1.000000; batch_top_k(None, [a], [b], 1) 0.000000
  similarity_matrix(None, [z, b])[0][0] 1.000000; cosine_similarity_cpu(z, z) 0.000000
```

`batch_top_k` gives them a similarity of 0: the product of their norms, 1.8·10⁻¹¹, is below its threshold. The zero vector z is fully similar to itself in the matrix, and not at all in `cosine_similarity_cpu`.

After the first run, the same vectors went through `similarity_matrix` with a context:

```text
  P3's vectors with a context: similarity_matrix(Some(&ctx), [a, b])[0][1] 0.000000; similarity_matrix(Some(&ctx), [z, b])[0][0] 0.000000
```

The doc comment of `similarity_matrix` reads "Uses GPU if context is provided, otherwise CPU fallback" ([`batch.rs` 12](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/batch.rs#L12)). The fallback doesn't compute the same thing. A zero vector is ordinary data (an empty document, a padding row), and it scores 1 or 0 depending on whether a GPU was found.

## 5. The skill's imports

The `ix-gpu` skill page shows three imports: `use ix_gpu::similarity::GpuCosineSimilarity;`, `use ix_gpu::matmul::GpuMatMul;` and `use ix_gpu::distance::GpuDistanceMatrix;` ([`SKILL.md` 28-31](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/.claude/skills/ix-gpu/SKILL.md?plain=1#L28-L31)). The crate's only public struct is `GpuContext`, and its modules export functions. P4 keeps each of the three lines as a `compile_fail` doctest, which fails with E0432, unresolved import. The page's fourth line, `use ix_gpu::context::GpuContext;`, is kept as a doctest that compiles.

## 6. The limits

`Limits::default()` allows the following ([`limits.rs` 363-396](https://docs.rs/wgpu-types/28.0.0/src/wgpu_types/limits.rs.html#363-396)):
- storage bindings of at most 128 MiB;
- buffers of at most 256 MiB;
- at most 65,535 workgroups per dimension of a dispatch.

wgpu describes them as the limits "guaranteed to work on all modern backends" ([`limits.rs` 93-94](https://docs.rs/wgpu-types/28.0.0/src/wgpu_types/limits.rs.html#93-94)). An adapter may offer more, but `ix-gpu` never asks for more. `similarity_matrix_gpu` binds the n × n result of `matmul_gpu` as one storage buffer ([`batch.rs` 43-82](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/batch.rs#L43-L82)). `batch_knn_gpu` dispatches one workgroup per query along one dimension. The arithmetic runs on CI:

```text
== P5, wgpu::Limits::default()
  max_storage_buffer_binding_size 134217728, max_buffer_size 268435456, max_compute_workgroups_per_dimension 65535
  largest n whose n x n f32 matrix fits in one binding: 5792 (134189056 bytes); 5793 needs 134235396
  the guide's 10000 embeddings compared pairwise: 400000000 bytes, above max_buffer_size: yes
```

The GPU side runs each call in a process of its own:

```text
== P5 on the GPU, each call in a process of its own
  similarity_matrix, 5792 vectors of dimension 8: returned
  similarity_matrix, 5793 vectors of dimension 8: panics; "wgpu error": yes; last line: Buffer binding 2 range 134235396 exceeds `max_*_buffer_binding_size` limit 134217728
  similarity_matrix, 10000 vectors of dimension 768: panics; "wgpu error": yes; last line: Buffer size 400000000 is greater than the maximum buffer size (268435456)
  batch_knn_gpu, 65535 queries: returned
  batch_knn_gpu, 65536 queries: panics; "wgpu error": yes; last line: Each current dispatch group size dimension ([65536, 1, 1]) must be less or equal to 65535
```

The guide's opening example, 10,000 embeddings of dimension 768 ([`introduction-calcul-gpu.md` 5](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/docs/fr/calcul-gpu/introduction-calcul-gpu.md?plain=1#L5)), doesn't return: it panics. So does the similarity guide's "10 000+" row, which promises a 10-100x speed-up ([`recherche-de-similarite.md` 197](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/docs/fr/calcul-gpu/recherche-de-similarite.md?plain=1#L197)). The error is a panic, not a `Result`, so a caller can't even fall back to the CPU.

By reading the code, not by a run: `batch_top_k` also sends its queries × corpus product through `matmul_gpu`. The same 128 MiB therefore bounds queries × corpus × 4 bytes.

## 7. The same sums, almost

`matmul_gpu` and `matmul_cpu` add their K products in the same order ([`matmul.rs` 36-41](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/matmul.rs#L36-L41), [141-156](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/matmul.rs#L141-L156)). So do `pairwise_distance_gpu` and `pairwise_distance_cpu` over the dimensions ([`distance.rs` 46-53](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/distance.rs#L46-L53), [133-153](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/distance.rs#L133-L153)). The same order doesn't mean the same rounding:
- WGSL lets an implementation fuse a multiply and an add into one operation with a single rounding, when the result is at least as accurate ([§ 15.7.5](https://www.w3.org/TR/WGSL/#reassociation-and-fusion));
- WGSL takes the accuracy of `sqrt` from `1.0 / inverseSqrt(x)` ([§ 15.7.4.1](https://www.w3.org/TR/WGSL/#concrete-float-accuracy));
- Rust rounds every operation.

Two products of 256 × 256 matrices with entries in [−1, 1), and the distances between P2's 1,000 references:

```text
== P7, the GPU's sums against the CPU's
  matmul 256 x 256 x 256: elements that differ 53438 of 65536, largest gap 5.7e-6
  pairwise distances of the 1000 references: elements that differ 264496 of 1000000, largest gap 2.4e-7, zero diagonal: yes
```

82% of the product's elements differ, all in the last bits. The entries have a standard deviation of about 5.3, so a gap of 5.7·10⁻⁶ is about one part in a million.

After the first run, the program also ran the two CPU loops with [`f32::mul_add`](https://doc.rust-lang.org/std/primitive.f32.html#method.mul_add), which fuses each multiply-add into one rounding:

```text
  P7's loops on the CPU with fused multiply-adds: matmul elements that differ from the GPU 0 of 65536; distances 168810 of 1000000
```

The matrix product then matches bit for bit: this driver fused every multiply-add of the shader. For the distances, fusing brings the count from 264,496 down to 168,810, and the rest is not explained here. One candidate is the square root, whose accuracy WGSL doesn't pin to correct rounding, but this lesson doesn't test it. Another adapter or backend may fuse differently, so compare a GPU result with a CPU one within a tolerance, never bit for bit.

## 8. The promised speed-ups

The matrix product guide gives a table of the gain to expect at four sizes ([`multiplication-matricielle-gpu.md` 180-184](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/docs/fr/calcul-gpu/multiplication-matricielle-gpu.md?plain=1#L180-L184)):

| Size | Gain the guide promises |
|---|---|
| 10 × 10 × 10 | none |
| 64 × 64 × 64 | marginal |
| 256 × 768 × 1024 | 5-20x |
| 1024 × 1024 × 1024 | 20-100x |

P8 predicted only the two ends. The two middle sizes were measured without a prediction. Each time is the median of 5 calls after one untimed warm-up, with one context throughout:

```text
== P8, matmul_cpu against matmul_gpu, median of 5 calls after a warm-up
  10 x 10 x 10: cpu 0.001 ms, gpu 0.490 ms, gpu faster by 0.0x
  64 x 64 x 64: cpu 0.086 ms, gpu 0.448 ms, gpu faster by 0.2x
  256 x 768 x 1024: cpu 179.753 ms, gpu 2.908 ms, gpu faster by 61.8x
  1024 x 1024 x 1024: cpu 2133.655 ms, gpu 8.722 ms, gpu faster by 244.6x
```

The first run gave 54.0x and 137.1x at the two large sizes. The GPU's time at 1024³ barely moved between the runs, from 8.456 to 8.722 ms. The CPU's went from 1,160 to 2,134 ms, and the lesson doesn't know why.

Both runs beat the guide at the large sizes. Both lose at 64³, where the "marginal" gain is in fact a GPU five times slower. Three things explain the pattern:
- **The CPU baseline is weak.** `matmul_cpu` is the textbook triple loop on one thread without SIMD, which the guide itself says ([`multiplication-matricielle-gpu.md` 191](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/docs/fr/calcul-gpu/multiplication-matricielle-gpu.md?plain=1#L191)). At 1024³ it takes 1 to 2 ns per product. So the speed-ups measure that loop as much as the GPU. A blocked, vectorised or multithreaded CPU product would shrink them; the lesson didn't measure one.
- **The GPU does far less than it could.** 2 × 1024³ operations in 8.7 ms is about 250 GFLOP/s, from a shader with no tiling. [Volkov and Demmel (2008)](https://doi.org/10.1109/SC.2008.5214359) show what tiles in workgroup memory bring.
- **Every GPU call pays a fixed cost.** Up to 64³, a call costs about half a millisecond whatever its size. `matmul_gpu` creates its buffers, its shader module and its pipeline at every call ([`matmul.rs` 60-138](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/matmul.rs#L60-L138)), then submits and reads back. The guide lists an initialisation cost of about 1 ms "premier appel : compilation shader" ([`multiplication-matricielle-gpu.md` 192](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/docs/fr/calcul-gpu/multiplication-matricielle-gpu.md?plain=1#L192)). The similarity guide adds that later calls reuse the compiled pipeline ([`recherche-de-similarite.md` 223](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/docs/fr/calcul-gpu/recherche-de-similarite.md?plain=1#L223)). Nothing in `ix-gpu` keeps a pipeline between calls. The driver may cache the compiled shader, but this lesson doesn't measure that.

The introduction guide puts the crossover at 1,000 to 10,000 elements ([`introduction-calcul-gpu.md` 149](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/docs/fr/calcul-gpu/introduction-calcul-gpu.md?plain=1#L149)). A 64 × 64 matrix holds 4,096 elements, inside that range, and the GPU is five times slower there.

## 9. The predictions, scored

| | Prediction, written before the first run | Measured | Verdict |
|---|---|---|---|
| P1 | naga rejects the dot product with "name `shared` is a reserved keyword", validates it once renamed and validates the four others; no workgroup variable in the matrix product; on the GPU, `dot_product_gpu` panics with "wgpu error" and naga's message, and the cosine agrees within 10⁻⁶ | As predicted; cosine gap 3.7·10⁻⁹ | Confirmed |
| P2 | The port's 10 nearest differ from `batch_knn_cpu`'s for 90 to 160 of 1,000 queries; for none with k = 1 or with the first 256 references | 135; 0 and 0 | Confirmed |
| P3 | `cosine_similarity_cpu(a, b)` and the matrix's [0][1] equal to 1 within 10⁻⁶, `batch_top_k` 0; the zero vector's diagonal entry 1; `cosine_similarity_cpu(z, z)` 0 | 1, 1 and 0; 1; 0 | Confirmed |
| P4 | The skill's three imports fail with E0432; `use ix_gpu::context::GpuContext;` compiles | As predicted | Confirmed |
| P5 | 5,792 vectors fit and 5,793 don't; the guide's example needs 400,000,000 bytes, above the buffer limit; on the GPU, 5,792 returns, 5,793 and 10,000 × 768 panic, 65,535 queries return, 65,536 panic | As predicted | Confirmed |
| P6 | The GPU returns the port's indices, in order, for 1,000 of 1,000 queries, distances within 10⁻⁶; with the first 256 references, `batch_knn_cpu`'s for every query | 1,000; 1.2·10⁻⁷; 1,000 | Confirmed |
| P7 | `matmul_gpu` differs from `matmul_cpu` in at least one element and by at most 10⁻⁴; distances within 10⁻⁵, zero diagonal | 53,438 elements, 5.7·10⁻⁶; 2.4·10⁻⁷, zero | Confirmed |
| P8 | At 1024³, `matmul_gpu` at least 20 times faster; at 10³, `matmul_cpu` faster | 244.6x (137.1x in the first run); 0.001 against 0.490 ms | Confirmed |

All eight held on the first run, and no interval was changed afterwards. Some intervals were wide: 10⁻⁴ in P7 and 20x in P8 leave room, and a prediction that can hardly fail teaches less. The controls show that the checks can fail:
- the renamed dot product validates, so the naga check doesn't reject everything;
- the port equals `batch_knn_cpu` whenever each class holds one reference;
- 5,792 vectors and 65,535 queries do return.

Everything the lesson labels as coming after the first run was chosen after seeing its result: the fused loops, `similarity_matrix` with a context, the extra contexts and the formula at other sizes.

## What to use for our repositories

- **Errors.** A `GpuContext`'s device is public. To keep a wgpu error from panicking, wrap the calls in [`Device::push_error_scope`](https://docs.rs/wgpu/28.0.0/wgpu/struct.Device.html#method.push_error_scope), or install [`Device::on_uncaptured_error`](https://docs.rs/wgpu/28.0.0/wgpu/struct.Device.html#method.on_uncaptured_error), and fall back to the CPU twin. The lesson didn't test either; *to verify*.
- **`dot_product_gpu`:** it can't run. Use `cosine_similarity_gpu`'s pattern, or the CPU.
- **`batch_knn_gpu`:** use it only if a query can afford to lose neighbours: with 1,000 references, 13% of queries lose some at k = 10 and 44% at k = 20. For exact neighbours, use `batch_knn_cpu`, or, for up to 256 references, the GPU.
- **`similarity_matrix`:** don't trust its result on a zero vector or on vectors of tiny norm. Normalise the vectors yourself and handle the zero vector explicitly, the same way on both paths. For more than 5,792 vectors, cut the matrix into blocks.
- **`batch_knn_gpu` beyond 65,535 queries:** split the batch.
- **`matmul_gpu`:** worth it at 256 × 768 × 1024 and above on this machine, not at 64³. Compare its results within a tolerance.
- **The `ix-gpu` skill:** import functions, such as `use ix_gpu::matmul::matmul_gpu;`, and `ix_gpu::context::GpuContext`.

## Exercises

1. Compute P(wrong) for k = 2 and N = 1,000 by hand, then explain why it is exactly 0 for k = 1.
2. Why does P(wrong) tend to 1 − (256 · 255 ⋯ 247)/256¹⁰ as N grows, for k = 10?
3. Change the kNN shader so that it returns the exact k nearest for k ≤ 16. What does each thread keep, and what does the CPU do with it?
4. Rewrite the thresholds of `cosine_similarity_cpu` and `batch_top_k` so that they give the same answer for a and b of section 4, and for every positive multiple of them. What should the zero vector get?
5. With `Limits::default()`, how would you compute the similarities of the guide's 10,000 embeddings of dimension 768 with `matmul_gpu`, without a single call that panics?

<details>
<summary>Solutions</summary>

1. With k = 2, the answer is wrong exactly when the 2 nearest share a class. That is Σ C(s_t, 2)/C(1,000, 2) = (232 × 6 + 24 × 3)/499,500 = 1,464/499,500 ≈ 0.00293, or about 3 queries in 1,000. For k = 1, the nearest reference is the nearest of its own class, so its thread keeps it, and it is the smallest of the 256 candidates.
2. As N grows, every class holds about N/256 references, and the 10 nearest are a uniform 10-subset. Each index falls in a class with probability close to 1/256, independently of the others, since drawing without replacement from large classes behaves like drawing with replacement. They land in 10 different classes with probability (256/256) · (255/256) ⋯ (247/256): the birthday problem with 256 days and 10 people.
3. Each thread keeps its k nearest in a small sorted array, in registers, inserting each new distance by shifting the larger ones. The CPU, or a second pass on the GPU, then merges the 256 sorted lists and keeps the first k. The true k nearest are among them, because each is among the k nearest of its own class. This is the scheme of Johnson, Douze and Jégou, with a merge instead of their warp-level sort.
4. The cosine doesn't change when a vector is scaled by a positive factor, so a fixed threshold on a norm, or on a product of norms, can't be right for every scale. Test the norms against zero, `norm_a > 0.0 && norm_b > 0.0`, and divide by each norm separately, `dot / norm_a / norm_b`, so that the product of two small norms can't underflow in f32. The zero vector has no direction, so its cosine is undefined. Return 0, or `None`, on both paths, and never a hard-coded 1 on the diagonal.
5. Normalise the vectors on the CPU first, so that a dot product is a cosine. Then split the 10,000 vectors into blocks of at most 5,792 rows, for instance two blocks of 5,000. Each product of a block with the transpose of another is 5,000 × 5,000 × 4 = 100,000,000 bytes, below the 128 MiB binding limit. Four products give the whole matrix, and three are enough, since it is symmetric. The inputs also have to fit: 5,000 × 768 × 4 = 15,360,000 bytes per block.

</details>

## Sources

- IX at pinned commit `490c395`: [`similarity.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/similarity.rs), [`knn.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/knn.rs), [`batch.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/batch.rs), [`matmul.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/matmul.rs), [`distance.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/distance.rs), [`context.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/context.rs), [the `ix-gpu` skill](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/.claude/skills/ix-gpu/SKILL.md), and the French guides [`introduction-calcul-gpu.md`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/docs/fr/calcul-gpu/introduction-calcul-gpu.md), [`multiplication-matricielle-gpu.md`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/docs/fr/calcul-gpu/multiplication-matricielle-gpu.md) and [`recherche-de-similarite.md`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/docs/fr/calcul-gpu/recherche-de-similarite.md).
- W3C, [WebGPU Shading Language](https://www.w3.org/TR/WGSL/): [reserved words](https://www.w3.org/TR/WGSL/#reserved-words), [reassociation and fusion](https://www.w3.org/TR/WGSL/#reassociation-and-fusion), [accuracy of concrete floating-point expressions](https://www.w3.org/TR/WGSL/#concrete-float-accuracy).
- [wgpu](https://wgpu.rs/) 28: [`Limits::default`](https://docs.rs/wgpu-types/28.0.0/src/wgpu_types/limits.rs.html#363-396), [the default error handler](https://docs.rs/wgpu/28.0.0/src/wgpu/backend/wgpu_core.rs.html#694-697), [`Device`](https://docs.rs/wgpu/28.0.0/wgpu/struct.Device.html). [naga](https://docs.rs/naga/28.0.0/naga/) 28: [the reserved-word check](https://docs.rs/naga/28.0.0/src/naga/front/wgsl/parse/lexer.rs.html#495-497).
- V. Garcia, E. Debreuve and M. Barlaud, ["Fast k nearest neighbor search using GPU"](https://doi.org/10.1109/CVPRW.2008.4563100), CVPR Workshops, 2008.
- J. Johnson, M. Douze and H. Jégou, ["Billion-scale similarity search with GPUs"](https://doi.org/10.1109/TBDATA.2019.2921572), IEEE Transactions on Big Data 7, 2021.
- V. Volkov and J. W. Demmel, ["Benchmarking GPUs to tune dense linear algebra"](https://doi.org/10.1109/SC.2008.5214359), SC 2008.
- Rust: [`f32::mul_add`](https://doc.rust-lang.org/std/primitive.f32.html#method.mul_add), [`std::process::Command`](https://doc.rust-lang.org/std/process/struct.Command.html). [NumPy](https://numpy.org/doc/stable/).
