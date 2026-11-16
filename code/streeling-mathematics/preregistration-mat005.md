# MAT-005 lab — pre-registration

Written on 2026-09-28, before any code of this part of the lab was compiled or run. Its SHA-256 is recorded in the Learn progress receipt at the moment of writing. A later edit would be a new file with its own date, not a silent correction.

## Where the predictions come from

Most predictions below are those of **§8 "Proposed Experiment (Not Yet Run)"** of the Streeling module MAT-005, *Symmetric Eigenproblems*, together with the §7 exercise, the §8 exercise and one reading in §7. They were published before this lab existed, in [Demerzel `8bd026f`](https://github.com/GuitarAlchemist/Demerzel/blob/8bd026f9e48065c482faeae5cacf8e4808fff4cc/state/streeling/courses/mathematics/en/mat-005-symmetric-eigenproblems.md), and the file is unchanged on Demerzel's `master` at the time of writing (same blob, `ebb902a`). They are quoted here without change. This file adds:
- how each prediction is judged;
- one hypothesis of the lab's own, **M5-L1**, from reading the pinned code, marked as such;
- the negative controls;
- what the lab does not cover.

Where the module says "up to rounding" or "close to", the band is set here, before the run.

## What is measured

- **Libraries under test:** IX `ix-math` and `ix-unsupervised`, pinned at `e35138b9d4c707d48f802649a7fcb3f7fc94934d`, the same commit as the module and the other labs.
- **Anchors at the pin:**

  | Anchor | What it is |
  |---|---|
  | `ix-math/src/eigen.rs:46` `symmetric_eigen` | `symmetric_eigen_with_opts(a, 100, 1e-12)` |
  | `eigen.rs:74`–`:84` | the sweep loop; it stops when √(sum of the squares above the diagonal) < `tol`, an absolute test (`:82`) |
  | `eigen.rs:89` | a pair is skipped when \|a_pq\| < 1e-15, an absolute test |
  | `eigen.rs:151` | `Ok` whether or not the tolerance was reached |
  | `ix-unsupervised/src/pca.rs:103` `power_iteration` | start vector (1, …, 1)/√n; stops when the norm of M·v is below 1e-15 (`:120`) or the Rayleigh estimate changes by less than `tol` |
  | `pca.rs:141` `deflate`, `:153` `fit`, `:176` | M' = M − λ v vᵀ; `fit` calls `power_iteration(&current_cov, 1000, 1e-10)` |
  | `pca.rs:47` `explained_variance_ratio` | each returned variance divided by the sum of the returned variances |

- **Matrices:**
  - B = [[5, 2], [2, 2]];
  - T = [[4, 1, 2], [1, 3, 0.5], [2, 0.5, 5]], the matrix of IX's `test_eigenvectors_are_orthonormal` and `test_reconstruction`, which §7 calls "one 3 × 3 matrix" and §8 "the 3 × 3 matrix of IX's own tests";
  - I + J of sizes 3 and 4, J being the matrix of ones;
  - N = [[1, 2], [3, 4]];
  - the six points (1, −1), (−1, 1), (1, 0), (−1, 0), (0, 1), (0, −1), and their covariance C = [[4, −2], [−2, 4]]/5.

## Predictions, quoted from the module, and how they are judged

**Step 1, invariants.**
- **M5-P1.** "Call `symmetric_eigen` on [[5, 2], [2, 2]], on the 3 × 3 matrix of IX's own tests, and on I + J of sizes 3 and 4. Check A v = λ v, VᵀV = I and A = V Λ Vᵀ entry by entry within 10^-9, the tolerance of IX's tests. Prediction: all hold, with the eigenvalues 6 and 1, then 4, 1, 1, then 5, 1, 1, 1."
  - Judged: each entry of A vᵢ − λᵢ vᵢ, for every i, of VᵀV − I and of V Λ Vᵀ − A is at most 1e-9 in absolute value, for the four matrices.
  - Reading of the eigenvalue lists: the module gives three lists for four matrices. They are read as B → (6, 1), I + J of size 3 → (4, 1, 1), I + J of size 4 → (5, 1, 1, 1), each judged within 1e-9 in descending order. No eigenvalue is predicted for T: they are printed only.

**Step 2, the eigenspace.**
- **M5-P2.** "For I + J of size 3, build uuᵀ + wwᵀ from the two returned eigenvectors for the eigenvalue 1, and compare it with I − J/3. Prediction: equal within 10^-9, whichever vectors the solver chose."
  - u and w are the returned columns whose eigenvalues are within 1e-9 of 1. There must be exactly two.
  - Judged entry by entry, within 1e-9.

**Step 3, asymmetric input**, in part.
- **M5-P3a.** "Call `symmetric_eigen` on [[1, 2], [3, 4]]. Prediction: exactly (5, 0), with no error."
  - Judged as `Ok`, with eigenvalues equal to 5.0 and 0.0 under f64 `==`. The sign of a zero is not judged; the bits are printed.
- **M5-P3b (from the §7 exercise).** "For λ = 5 the returned vector is v = (1, 2)/√5, and A v = (5, 11)/√5 ≠ 5 v = (5, 10)/√5: the residual A v − λ v = (0, 1)/√5 is far from 0."
  - Judged: the returned vector for 5 is within 1e-12 of (1, 2)/√5, entry by entry, up to sign.
  - The residual's Euclidean norm is within 1e-12 of 1/√5.
- The other half of step 3, `ix_eigen` on the same matrix, is an MCP call. **It is not run** (see below).

**Step 4, PCA's blind spot.** `PCA::new(2)` is fitted on the six points.
- **M5-P4a.** "Both components equal (1, 1)/√2 up to sign and rounding."
  - Judged: each component is within 1e-12 of (1, 1)/√2, entry by entry, up to sign.
- **M5-P4b.** "The variances are close to 2/5 and 0."
  - Judged: the first within 1e-9 of 0.4, the second in [0, 1e-9].
- **M5-P4c.** "`explained_variance_ratio` reports 1 and 0."
  - Judged: the first within 1e-9 of 1, the second within 1e-9 of 0.
- **M5-P4d.** "For comparison, `symmetric_eigen` on the same covariance matrix returns 6/5 and 2/5."
  - C is built here as [[4, −2], [−2, 4]] / 5. The data are small integers, so the product XᵀX is exact and C is the matrix that `fit` computes.
  - Judged within 1e-9, in descending order.
- **M5-P4e (from the §8 exercise).** "The total variance is the trace of the covariance matrix … 4/5 + 4/5 = 8/5. The returned variances add up to 2/5, so 6/5 of the variance, three quarters of it, is unaccounted for."
  - Judged: (trace C − sum of the returned variances) / trace C is within 1e-9 of 0.75.

**A reading in §7.**
- **M5-P5.** `test_repeated_eigenvalues` "uses the 4 × 4 identity: its off-diagonal part is already zero, so the loop stops before the first rotation and returns the identity it started from … a matrix such as the I + J of §5 would force rotations."
  - Judged: `symmetric_eigen(I₄)` returns eigenvectors equal to I₄ bit for bit.
  - The eigenvectors of I + J of size 4 are not I₄.

## A hypothesis of the lab's own

**M5-L1.** This hypothesis is not in the module. It comes from reading `eigen.rs:82` at the pin, and is written here before any run. The stopping test compares √(sum of the squares above the diagonal) with the absolute 1e-12, before any rotation. For s · B with s = 10^e and e = −14 … 12, this is 2s:
- **M5-L1a.** For e ≤ −13, 2s < 1e-12, so the loop stops before any rotation. `symmetric_eigen(s · B)` returns `Ok`, the eigenvalues fl(5s) and fl(2s), bit for bit the diagonal of s · B, and V = I bit for bit. The smaller eigenvalue is then off by 100%: 2s instead of s.
- **M5-L1b.** For e ≥ −12, the eigenvalues divided by s are within a relative 1e-12 of (6, 1).
- **M5-L1c.** At e = −13, the check that IX's tests use, A v = λ v entry by entry within the absolute 1e-9, still passes on that wrong answer.

## Negative controls

- **The invariant checker** fails when two eigenvalues of B are swapped.
- **The eigenspace check** fails when the eigenvector for 4 replaces one of the two for 1.
- **The "same axis" check** tells (1, 1)/√2 apart from (1, −1)/√2.
- **The bit comparator** tells I₄ apart from the eigenvectors of I + J.

## What would not be claimed

- **Not run:** `ix_eigen` over MCP, which needs `ix-agent`.
- **Not measured:** the comment of `symmetric_eigen_with_opts` against its loop, and whether IX's own tests pass at the pin. That reading of §7 stays the module's.
- Nothing about other matrices, or about IX commits other than `e35138b9`.
- **Platforms.** The expected file is produced on Windows x86-64. CI runs `check.sh` on Linux, Windows and macOS: a diff there would be a measured cross-platform difference.
- **A refuted prediction is a result.** It is recorded in the test and the README, not tuned away.
