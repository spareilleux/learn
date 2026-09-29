# MAT-006 lab — pre-registration

Written on 2026-09-28, before any code of this part of the lab was compiled or run. Its SHA-256 is recorded in the Learn progress receipt at the moment of writing. A later edit would be a new file with its own date, not a silent correction.

## Where the predictions come from

The predictions below are those of **§7 "Proposed Experiment (Not Yet Run)"** and of the §6 exercise of the Streeling module MAT-006, *Singular Value Decomposition and Low-Rank Approximation*. They were published before this lab existed, in [Demerzel `0b13b9d`](https://github.com/GuitarAlchemist/Demerzel/blob/0b13b9d56cc4b657cde6f3ce958c162610065c2f/state/streeling/courses/mathematics/en/mat-006-svd-low-rank-approximation.md), and the file is unchanged on Demerzel's `master` at the time of writing. They are quoted here without change. This file adds only:
- how each prediction is judged;
- the negative controls;
- what the lab does not cover.

Where the module says "about", "up to rounding" or "several", the band is set here, before the run.

## What is measured

- **Library under test:** IX `ix-math`, pinned at `e35138b9d4c707d48f802649a7fcb3f7fc94934d`, the same commit as the module and the MAT-003 lab.
- **Anchors at the pin** (`crates/ix-math/src/svd.rs`):

  | Anchor | What it is |
  |---|---|
  | `:100` `svd` | `svd_with_opts(a, 50, 1e-12)` |
  | `:105` `svd_with_opts` | one-sided Jacobi with at most `max_sweeps` sweeps; stopping test `off_diag_sum_sq < tol * tol * a_frob_sq` (`:174`) |
  | `:195`–`:207` | a column of U is filled only when its singular value exceeds `tol`, the absolute 1e-12 |
  | `:49` `reconstruct` | U · diag(s) · Vᵀ over the kept singular values |
  | `:67` `rank(tol)`, `:223` `truncated_svd(a, k)` | as the module describes |

- **Matrices:**
  - A = [[1, 2], [3, 4], [5, 6]];
  - M = [[1, 2, 3], [4, 5, 6], [7, 8, 10]];
  - fl(H_n), the Hilbert matrices of the MAT-003 lab, for n = 2 … 16;
  - 10^-12 · I₃.
- **Norms:** the Frobenius norm ‖·‖_F, computed here with plain loops, without IX.
- **"The relative error of `reconstruct`"** is ‖`svd(B).reconstruct()` − B‖_F / ‖B‖_F.

## Predictions, quoted from the module, and how they are judged

**Step 1, Eckart–Young for every k.** On A and on M, ‖X − X_k‖_F is computed with `truncated_svd` for every k, and compared with √(σₖ₊₁² + …) computed from `svd`.
- **M6-P1.** The two are "equal within 10^-9 · ‖A‖_F, decreasing in k, and 0 up to rounding at k = rank A".
  - Judged for k = 0 … n, with n the number of columns: |difference| ≤ 1e-9 · ‖X‖_F.
  - The error does not increase from one k to the next.
  - At k = n, which is the rank of both matrices (det M = −3), it is ≤ 1e-12 · ‖X‖_F. This is the band chosen for "0 up to rounding".

**Step 2, a scale sweep.** For s = 10^-14, 10^-13, …, 10^12, the singular values of s · X divided by s are compared with those of `svd(X)`, together with the relative error of `reconstruct`.
- **M6-P2a (A).** "The singular values match those of A within a relative 10^-12 at every scale."
- **M6-P2b (A).** "The relative error is below 10^-12 for s ≥ 10^-11, about 0.054 for s = 10^-12, and exactly 1 for s ≤ 10^-13."
  - "About 0.054" is judged as lying in [0.0535, 0.0545].
  - "Exactly 1" is judged as == 1.0.
- **M6-P2c (A, from the §6 exercise).**
  - "Both columns of U stay zero" at s = 10^-13 (judged at every s ≤ 10^-13).
  - At s = 10^-12, the second column of U is zero and the first is not.
- **M6-P2d (M).** "The singular values match within a relative 10^-12 for s ≥ 10^-10; for s ≤ 10^-13 … at least one of them is wrong by more than 100%."
  - Judged as a relative error > 1 for at least one singular value, at each s ≤ 10^-13.
  - s = 10^-12 and 10^-11 have no prediction for M: they are printed only.

**Step 3, the cost of scale.** "The scaled calls take several times longer, since they run all 50 sweeps."
- **M6-P3.** "Several" is judged here as a ratio ≥ 3 between the time of `svd(10^6 · X)` and that of `svd(X)`, for X = A and X = M.
- Timings depend on the machine, so this step is **not** in `expected/` and not asserted in CI.
- It runs only when `MAT006_TIMING` is set.
  - Each call is repeated 20,000 times, and the minimum over 5 repetitions is kept.
  - The result is reported with the machine it ran on.

**Step 4, MAT-003's puzzle.** For n = 2 … 16, three computations are compared:
- `svd_with_opts(2^20 · fl(H_n), k, 10^-12)` for k = 1 … 6, its singular values divided by 2^20;
- the singular values of `svd(fl(H_n))`;
- those of `svd(2^-20 · fl(H_n))`, divided by 2^-20.

All these multiplications by powers of two are exact.
- **M6-P4.** The capped result "reproduces bit for bit the singular values of `svd(fl(H_n))` for a first value of k, and those of `svd(2^-20 · fl(H_n))` divided by 2^-20 for a second one: k = 2 and 2 for n = 2, 4 and 3 for n = 3 to 6, 5 and 4 for n = 7 to 14, and 6 and 4 for n = 15 and 16."
  - Judged as: for each n, the smallest k in 1 … 6 whose capped result equals `svd(fl(H_n))` bit for bit is the first value, and the smallest k equal to the 2^-20 result is the second.
  - If no k up to 6 matches, the prediction is refuted for that n.

**Step 5, rank conventions**, in part.
- **M6-P5.** "Call `rank` with the tolerance 10^-10 on the SVD of 10^-12 · I₃. Prediction: 0, against 3 with the relative convention of §4."
  - The relative convention is judged at tol = max(m, n) · σ₁ · ε = 3 · σ₁ · 2^-52.
- The other half of step 5, `ix_svd` on [[1, 2], [2, 4]], is an MCP call. **It is not run** (see below).

**Step 6, the test's bound.**
- **M6-P6.** "The relative error of the rank-1 truncation of the test matrix" A is "0.054 to three decimal places, against the bound 0.10 that the test checks".
  - Judged as lying in [0.0535, 0.0545), with `truncated_svd(A, 1).reconstruct()`.

## Negative controls

- **The Eckart–Young check** reports a failure when the tail sum leaves out one singular value.
- **The bit comparator** tells apart `svd(fl(H_n))` from `svd(2^-20 · fl(H_n))` / 2^-20 for at least one n. MAT-003 measured that they differ for 10 of the 15 sizes.
- **The relative error** is 0 for a matrix against itself, and exactly 1 for the zero matrix against a nonzero one.

## What would not be claimed

- **Not run:** the `ix_svd` MCP call of step 5, which needs `ix-agent`.
- **Step 3's ratios** are one machine's timings, reported as such.
- Nothing about other matrices, or about IX commits other than `e35138b9`.
- **Platforms.** The expected file is produced on Windows x86-64. CI runs `check.sh` on Linux, Windows and macOS: a diff there would be a measured cross-platform difference.
- **A refuted prediction is a result.** It is recorded in the test and the README, not tuned away.
