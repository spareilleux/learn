# MAT-004 lab — pre-registration

Written on 2026-09-28, before any code of this part of the lab was compiled or run. Its SHA-256 is recorded in the Learn progress receipt at the moment of writing. A later edit would be a new file with its own date, not a silent correction.

## Where the predictions come from

Most predictions below are those of **§7 "Proposed Experiment (Not Yet Run)"** of the Streeling module MAT-004, *Vectors, Matrices, Norms and Linear Maps*, together with the §6 exercise and two readings in §6. They were published before this lab existed, in [Demerzel `d451c90`](https://github.com/GuitarAlchemist/Demerzel/blob/d451c909f69d9774901bdd99195ead8444098320/state/streeling/courses/mathematics/en/mat-004-vectors-matrices-norms.md). The file is unchanged on Demerzel's `master` at the time of writing (same blob, `674ecf4`). They are quoted here without change.

This file adds:
- how each prediction is judged;
- one hypothesis of the lab's own, **M4-L1**, marked as such;
- the negative controls;
- what the lab does not cover.

Where the module says "roughly" or leaves a choice open, the band or the choice is set here, before the run.

## What is measured

- **Library under test:** IX `ix-math`, pinned at `e35138b9d4c707d48f802649a7fcb3f7fc94934d`, the same commit as the module and the other labs.
- **Anchors at the pin:**

  | Anchor | What it is |
  |---|---|
  | `ix-math/src/distance.rs:18` `euclidean` | √(Σ (xᵢ − yᵢ)²), with `powi(2)` |
  | `distance.rs:37` `manhattan` | Σ \|xᵢ − yᵢ\| |
  | `distance.rs:46` `minkowski` | rejects p < 1 with `InvalidParameter("p must be >= 1")`, then (Σ \|xᵢ − yᵢ\|^p)^(1/p) with `powf` |
  | `distance.rs:72` `cosine_distance` | 1 − cos θ |
  | `distance.rs:77` `chebyshev` | maxᵢ \|xᵢ − yᵢ\| |
  | `linalg.rs:8` `matmul`, `linalg.rs:35` `determinant`, `:43` `det_recursive` | the product, and the cofactor expansion along the first row, direct at n = 2 |

## Predictions, quoted from the module, and how they are judged

**Step 1, the triangle inequality on a grid.**
- **M4-P1.** "For the 25 points of R² with integer coordinates from −2 to 2, check d(x, z) ≤ d(x, y) + d(y, z) over all 15,625 triples for `manhattan`, `euclidean`, `chebyshev` and `minkowski` with p = 3. Prediction: no violation larger than 10^-12."
  - Judged: for each distance and each triple, d(x, z) − (d(x, y) + d(y, z)) ≤ 1e-12.
  - The largest value of that difference is printed, as is the number of triples where it is strictly positive. No prediction is made for that number.

**Step 2, p below 1.**
- **M4-P2.** "Call `minkowski` with p = 1/2 on the points of the §5 exercise. Prediction: `InvalidParameter("p must be >= 1")`."
  - The points are x = (0, 0), y = (1, 0) and z = (1, 1).
  - Judged on the three pairs (x, y), (y, z) and (x, z): each returns `Err(MathError::InvalidParameter(m))` with m equal to "p must be >= 1".

**Step 3, p = ∞.**
- **M4-P3.** "Call `minkowski` with p = `f64::INFINITY` on (0, 0) and (0, 0), and on (0, 0) and (3, 4). Prediction: 1 for both, against 0 and 4 from `chebyshev`."
  - Judged with f64 `==`: `Ok(1.0)` twice, then `chebyshev` gives `Ok(0.0)` and `Ok(4.0)`.

**Step 4, large p.**
- **M4-P4.** "Call `minkowski` with p = 1000 on (0, 0) and (3, 4). Prediction: ∞."
  - Judged: `Ok(f64::INFINITY)`.

**Step 5, the cost of cofactor expansion.**
- **M4-P5a.** "Time `determinant` for n = 2 to 11 on fixed matrices … from n = 3 on, each step multiplies the time by roughly n."
  - The fixed matrices are chosen here: F_n[i][j] = ((i + 2j) mod 5) − 2, for i, j from 0 to n − 1.
  - Each n is timed as the minimum over 5 runs. Each run makes k calls, with k = max(1, ⌈10^6 / (n!/2)⌉), and the time per call is the elapsed time divided by k.
  - "Roughly n" is judged as t(n)/t(n − 1) in [n/2, 2n], for n = 3 … 11.
  - Timings depend on the machine, so this step is **not** in `expected/` and not asserted in CI. It runs only when `MAT004_TIMING` is set, and is reported with the machine it ran on.
- **M4-P5b.** "Check det(AB) = det A · det B on 3 × 3 matrices with small integer entries. Prediction: … the product rule holds exactly."
  - The matrices are chosen here: 1,000 pairs, whose entries in −3 … 3 are drawn in row order, A then B, from the 64-bit generator x ← 6364136223846793005 · x + 1442695040888963407 (mod 2^64), started at x = 0. Each entry is ((x >> 33) mod 7) − 3.
  - AB is computed with IX's `matmul`.
  - Judged with f64 `==` for every pair.

**Two readings in §6.**
- **M4-P6.** "[`cosine_distance`] does not satisfy the triangle inequality: for x = (1, 0), y = (1, 1) and z = (0, 1), it gives d(x, z) = 1, but d(x, y) + d(y, z) = 2 − √2 ≈ 0.59."
  - Judged within 1e-12 of 1 and of 2 − √2.
- **M4-P7.** The guard "lets two non-finite values through, though: `f64::NAN`, because every comparison with NaN is false, after which the powers return NaN in general, which is not a distance".
  - Judged: `minkowski` with p = NaN returns `Ok` with a NaN value, on (0, 0) and (3, 4), and on (0, 0) and (0, 0).

## A hypothesis of the lab's own

**M4-L1.** This hypothesis is not in the module, and is written here before any run. "In general" has an exception. IEEE 754 and C99 Annex F define pow(1, y) = 1 for every y, NaN included. For the one-dimensional points [0] and [1], the single term is 1^NaN = 1, the sum is 1, and 1^(1/NaN) = 1 again.
- Prediction: `minkowski([0], [1], NaN)` returns `Ok(1.0)`, a finite value and not NaN, although p is not a number.
- `powf` goes to each platform's math library, so a difference between the three CI systems would be a measured result.

## Negative controls

- **The triangle checker** reports the violation 4 > 2 of the p = 1/2 formula of the §5 exercise, computed here by hand without IX.
- **The product-rule checker** reports a failure when det A + det B replaces det A · det B, for at least one of the 1,000 pairs.
- **The NaN test** tells a NaN apart from every finite value and from ∞.

## What would not be claimed

- **Step 5's ratios** are one machine's timings, reported as such.
- The grid check is exhaustive on 25 points only. It proves nothing about R², as the §7 exercise says.
- Nothing about other inputs, or about IX commits other than `e35138b9`.
- **Platforms.** The expected file is produced on Windows x86-64. CI runs `check.sh` on Linux, Windows and macOS: a diff there would be a measured cross-platform difference.
- **A refuted prediction is a result.** It is recorded in the test and the README, not tuned away.
