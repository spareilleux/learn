# Streeling mathematics — executable experiments

Experiments behind the Streeling mathematics modules, run against IX `ix-math`, which is pinned in `Cargo.toml` to commit [`e35138b9`](https://github.com/GuitarAlchemist/ix/commit/e35138b9d4c707d48f802649a7fcb3f7fc94934d). Numbers in the module text come from `expected/`, and nowhere else.

```bash
bash check.sh          # fmt, clippy, tests, then each example's output compared with expected/
UPDATE=1 bash check.sh # rewrite expected/ after a deliberate change
```

## MAT-003 · Floating-point arithmetic and conditioning

- `preregistration.md`: the predictions P0–P8, written and hashed before the first run.
- `examples/mat003_conditioning.rs`: Hilbert matrices H_n, n = 2…16, and the same matrices scaled by 2^±20. For each it prints κ∞ (from the exact inverse), IX's κ₂ (from `svd`), the verdict of `inverse`, its forward error and residual, and the rank and residual of the pseudo-inverse at the MCP tolerance σ₁·1e-10.
- `tests/mat003.rs`: one test per prediction. Each is judged against a bound, such as the theorem band κ∞/n ≤ κ₂ ≤ κ∞ or e ≤ n·κ∞·u, or against exact bits. It is not judged against the printed digits.
- The oracle is the exact integer inverse of H_n (`src/lib.rs`), computed without IX.

Two predictions were refuted on the first run, and the tests keep them visible:
- **P1:** IX's κ₂ leaves the theorem band at n = 10, not after n = 11.
- **P5b:** `svd` is not scale-equivariant: κ₂ changes when H is multiplied by a power of two.

**Note, 2026-09-27, after review.** The band κ∞/n ≤ κ₂ ≤ κ∞ holds for one matrix. Here κ∞ comes from the exact rational H_n, while IX computes κ₂ on fl(H_n), the matrix stored in binary64: two different inputs. So P1 records a measurement, IX's κ₂ against the band of the exact H_n. **It does not prove that IX's `svd` is wrong.** That would need a same-input oracle, meaning κ of fl(H_n) itself in higher precision, or a checked perturbation bound. The P1 test name and comment say "underestimates"; read them as "falls below the band of the exact matrix".

**Update, later on 2026-09-27.** The P1 test is renamed `p1_ix_kappa_2_of_fl_h_is_inside_the_exact_h_band_up_to_9_and_below_it_from_10`. Its comment, P5's comment and the doc of `band_holds` now say the same thing. No assertion, expected value or preregistration changed.

P5b does not depend on the band. 2^±20·fl(H) are exact multiples of fl(H), so their κ₂ are equal in exact arithmetic, and three different answers mean at least two are not κ₂ of the input. That still does not say which one is right.

The expected file was produced on Windows x86-64. CI runs `check.sh` on Linux, Windows and macOS: a diff there would be a measured cross-platform difference.

## MAT-007 · Least squares, regularisation and identifiability

This part also uses IX `ix-supervised`, pinned to the same commit.

- `preregistration-mat007.md` quotes the predictions of the module's §6, steps 1 and 2 ([Demerzel `8c14336`](https://github.com/GuitarAlchemist/Demerzel/blob/8c14336ecd9601615e08c20dca696cd0e021563e/state/streeling/courses/mathematics/en/mat-007-least-squares-regularisation.md)), and sets how each is judged. It was committed on its own, before any code of this part existed, with SHA-256 `58d4570e…0ab8a5`.
- `src/mat007.rs` holds the fixtures, whose exact answers are known in closed form, and three routes:
  - IX's `LinearRegression::fit`, with its panic caught;
  - the same fit on the centered feature;
  - the SVD route: `pseudo_inverse` of [x | 1] at 4·σ₁·ε, times y.
- `examples/mat007_least_squares.rs` prints the offset sweep for c = 10^0…10^7, the centered fit, and the normal equations against the SVD for N = 10^0…10^7.
- `tests/mat007.rs` has one test per prediction, M7-P1a to M7-P2d, and the negative controls. Among them, a NaN weight or bias must fail every check: the errors are folded with `max_or_nan`, because `f64::max` drops a NaN operand.

All nine predictions held on the first run, including the ones stated bit for bit:
- **Offset sweep:** at c = 10^5, `fit` returns the slope 2 − 2^-18 and the bias 1.5. At c = 10^6, it returns the slope 2 + 2^-11 and the bias 0, with no error and a largest miss of 487.3. At c = 10^7, it panics with "X^T X is singular".
- **Normal equations:** the error is 3.05e-5 at N = 10^5 and 0.250 at N = 10^7, and no error is raised. The SVD route stays at or below 1.5e-8.

Two things were measured without a prediction, and are only reported:
- **c = 10^4:** the slope is 2 + 2^-24, the bias 1 − 2^-11, and the largest miss 1.08e-4.
- **The SVD route's error:** at N = 10^2 it is 1.29e-10, about 1,200 times κ₂·u (κ₂ = 949, u = 2^-53, so κ₂·u ≈ 1.05e-13). There it is larger than the normal equations' error, 2.05e-11. From N = 10^2 to 10^5 it stays between 8.0e-11 and 2.4e-10. The cause is not established here.

Steps 3 and 4 of §6, the MCP server after a panic and the input schema, are not run: they need `ix-agent` and a disposable `ix-mcp` process.

## MAT-006 · The SVD and low-rank approximation

- `preregistration-mat006.md` quotes the predictions of the module's §7 and of its §6 exercise ([Demerzel `0b13b9d`](https://github.com/GuitarAlchemist/Demerzel/blob/0b13b9d56cc4b657cde6f3ce958c162610065c2f/state/streeling/courses/mathematics/en/mat-006-svd-low-rank-approximation.md)), and sets how each is judged. It was committed on its own, before any code of this part existed, with SHA-256 `3937cc1a…f7a4d3`.
- `src/mat006.rs` holds the two matrices of IX's tests, A = [[1, 2], [3, 4], [5, 6]] and M = [[1, 2, 3], [4, 5, 6], [7, 8, 10]], and the checks. Norms and errors are plain loops, without IX. Powers of ten are parsed from text, and powers of two are built from their bits.
- `examples/mat006_svd.rs` prints steps 1, 2, 4, 5 and 6, and the negative controls. Step 3 is timing: it prints to stderr, and only when `MAT006_TIMING` is set, so it never enters `expected/`.
- `tests/mat006.rs` has one test per prediction, M6-P1 to M6-P6 except P3, and the negative controls.

Eight predictions held on the first run:
- **Eckart–Young (P1):** for A and M, at every k, the error of `truncated_svd` equals the tail of the singular values within 4.8e-15.
- **Scale sweep, A (P2a–P2c):** the singular values stay within 1.1e-15 at every scale from 10^-14 to 10^12. The error of `reconstruct` is below 6e-16 from 10^-11 up, 0.0539 at 10^-12, and exactly 1 at 10^-13 and 10^-14, where both columns of U are zero.
- **Scale sweep, M (P2d):** the singular values stay within 6.6e-15 from 10^-10 up. At 10^-13 and below, the worst is off by 196%.
- **Rank (P5):** for 10^-12·I₃, `rank(1e-10)` is 0 and `rank(3·σ₁·ε)` is 3.
- **The bound of IX's test (P6):** the rank-1 truncation of A has the relative error 0.053913, against the 0.10 the test accepts.
- **Cost of scale (P3), one machine:** 20,000 calls of `svd` on 10^6·A take 10.10 times as long as on A; the ratio is 8.77 for M. Measured once, with the fastest of 5 runs, on an Intel Core Ultra 9 285K under Windows 11 Pro. CI does not time anything.

One prediction was partly refuted, and the test keeps it visible:
- **MAT-003's puzzle (P4):** capped at k sweeps, the singular values of `svd_with_opts(2^20·fl(H_n), k, 1e-12)`, divided by 2^20, equal bit for bit those of `svd(fl(H_n))`, and those of `svd(2^-20·fl(H_n))` divided by 2^-20, for every n from 2 to 16, as the module's explanation needs. Only the singular values are compared, not U or V. For n = 6 to 16, the smallest such k is the predicted one. For n = 2 to 5, it is lower: 1 and 1 for n = 2, 2 and 2 for n = 3, 3 and 3 for n = 4 and 5.

Measured without a prediction, and only reported:
- **Post hoc, P4:** at the predicted k, the capped singular values also equal both results, for every n. For n = 2 to 5, the sweeps after the first matching k change no bit. This is consistent with the module's sweep counts but does not verify them: the lab does not count the sweeps the uncapped calls execute, and several caps give the same bits.
- **Scale 1 against scale down:** the singular values differ for 11 of the 15 sizes. MAT-003 had reported that κ₂ changes for 10 of 15 across three scales, a different measure.
- **M at 10^-12 and 10^-11:** the singular values are off by 3.4e-9, neither accurate nor wrong by 100%. The error of `reconstruct` is 0.0515 at 10^-13 and 10^-12.
- **Step 1 at full rank:** the tail of an empty list of singular values prints as `-0.000000e0`. Rust's `f64` sum of nothing is −0.0, and its square root is −0.0.

The `ix_svd` half of step 5 is not run: it goes through the MCP server.

## MAT-005 · Symmetric eigenproblems

This part also uses IX `ix-unsupervised`, pinned to the same commit.

- `preregistration-mat005.md` quotes the predictions of the module's §8 ([Demerzel `8bd026f`](https://github.com/GuitarAlchemist/Demerzel/blob/8bd026f9e48065c482faeae5cacf8e4808fff4cc/state/streeling/courses/mathematics/en/mat-005-symmetric-eigenproblems.md)), of its §7 and §8 exercises and of one §7 reading, and sets how each is judged. It adds one hypothesis of the lab's own, M5-L1, from reading `eigen.rs:82`. It was committed on its own, before any code of this part existed, with SHA-256 `7acea840…90afd28`.
- `src/mat005.rs` holds the matrices, the six points of §7 and the checks. Residuals and products are plain loops, without IX.
- `examples/mat005_eigen.rs` prints steps 1 to 4 of §8, the §7 reading, the scale sweep of M5-L1 and the negative controls.
- `tests/mat005.rs` has one test per prediction, M5-P1 to M5-P5 and M5-L1a to M5-L1c, and the negative controls.

All the module's predictions held on the first run:
- **Invariants (P1):** on B = [[5, 2], [2, 2]], on IX's 3 × 3 test matrix and on I + J of sizes 3 and 4, the largest entry of A v − λ v, VᵀV − I and V Λ Vᵀ − A is 1.8e-15. The eigenvalues are 6 and 1, 4, 1, 1, and 5, 1, 1, 1, as predicted.
- **The eigenspace (P2):** for I + J of size 3, uuᵀ + wwᵀ equals I − J/3 within 2.2e-16.
- **Asymmetric input (P3):** `symmetric_eigen([[1, 2], [3, 4]])` returns `Ok` and exactly (5, 0), the eigenvalues of [[1, 2], [2, 4]]. The vector for 5 is (1, 2)/√5, and ‖A v − 5 v‖ = 1/√5.
- **PCA's blind spot (P4):** both components are (1, 1)/√2, with the variances 0.4 and 0, the ratios 1 and 0, and a dot product of 1. On the same covariance, `symmetric_eigen` finds 1.2 and 0.4. The components miss 0.75 of the variance.
- **The identity test (P5):** the eigenvectors of I₄ are I₄ bit for bit; those of I + J of size 4 are not.

The lab's own hypothesis held too:
- **M5-L1, the absolute stopping test:** for s·B with s = 10^-14 and 10^-13, `symmetric_eigen` returns `Ok`, the diagonal (5s, 2s) bit for bit and V = I. It rotates nothing, and the smaller eigenvalue is off by 100%. From s = 10^-12 to 10^12, the eigenvalues divided by s are within a relative 1.5e-16 of (6, 1).
- **The check of IX's tests passes on that wrong answer:** at s = 10^-13, the largest entry of A v − λ v is 2.0e-13, within the absolute 1e-9.

Measured without a prediction, and only reported:
- **The same check fails on right answers at large scale.** From s = 10^7 up, the eigenvalues are right, but the largest entry of A v − λ v exceeds 1e-9. It is 7.5e-9 at 10^7 and 1.8e-4 at 10^12, which is about 3e-17 of 6s. An absolute tolerance is too loose below one scale and too strict above another.

The `ix_eigen` half of step 3 is not run: it goes through the MCP server.

## MAT-004 · Vectors, matrices, norms and linear maps

- `preregistration-mat004.md` quotes the predictions of the module's §7 ([Demerzel `d451c90`](https://github.com/GuitarAlchemist/Demerzel/blob/d451c909f69d9774901bdd99195ead8444098320/state/streeling/courses/mathematics/en/mat-004-vectors-matrices-norms.md)), of its §6 exercise and of two §6 readings, and sets how each is judged. It also fixes, before the run, the choices the module leaves open: the matrices, the generator and the band for "roughly n". It adds one hypothesis of the lab's own, M4-L1. It was committed on its own, before any code of this part existed, with SHA-256 `5b1d5821…fa87e3`.
- `src/mat004.rs` holds the grid, the fixtures, the product-rule pairs and the checks.
- `examples/mat004_norms.rs` prints steps 1 to 5, the §6 readings, M4-L1 and the negative controls. Step 5's timing prints to stderr, and only when `MAT004_TIMING` is set.
- `tests/mat004.rs` has one test per prediction, M4-P1 to M4-P7 except the timing, M4-L1, and the negative controls.

Every prediction asserted in CI held on the first run:
- **Triangle inequality (P1):** on the 15,625 triples of the grid, no violation larger than 10^-12 for `manhattan`, `euclidean`, `chebyshev` or `minkowski` with p = 3.
- **p = 1/2 (P2):** `minkowski` refuses it on the three pairs of the §5 exercise, with "p must be >= 1".
- **p = ∞ (P3):** `minkowski` returns 1 for (0, 0)-(0, 0) and for (0, 0)-(3, 4), where `chebyshev` returns 0 and 4.
- **p = 1000 (P4):** `minkowski` returns ∞ for (0, 0)-(3, 4), the pair the module names. No other pair was tested.
- **The product rule (P5b):** det(AB) equals det A · det B exactly for all 1,000 pairs. 144 pairs have a singular factor, and the largest |det(AB)| is 2,940.
- **`cosine_distance` (P6):** d(x, z) = 1, against d(x, y) + d(y, z) = 2 − √2.
- **p = NaN (P7):** the guard lets it through, and `minkowski` returns `Ok(NaN)` on (0, 0)-(3, 4) and on (0, 0)-(0, 0).

The lab's own hypothesis held too:
- **M4-L1:** `minkowski([0], [1], NaN)` returns `Ok(1.0)`, since 1^NaN = 1. A p that is not a number yields a finite answer.

One prediction was partly refuted:
- **The cost of cofactor expansion (P5a), one machine.** From n = 4 to 11, each step multiplies the time by 5.3 to 11.0, within the band [n/2, 2n]; from n = 6 on, by 6.1, 7.0, 8.0, 9.0, 10.0 and 11.0, close to n itself. From n = 2 to 3, the time grows by 38. The band there is [1.5, 6], so "from n = 3 on" is refuted at its first step. At n = 2, `det_recursive` returns ad − bc directly. At n = 3, it builds three minor matrices, each a new allocation, which the count n!/2 of 2 × 2 determinants leaves out. That this explains the jump is a reading of the code, not a measurement. Measured once in the release profile, the profile of MAT-006's timing, with the fastest of 5 runs, on an Intel Core Ultra 9 285K under Windows 11 Pro. The pre-registration did not fix the profile. In the debug profile, the step to n = 3 is 18.8, also outside the band, and the steps from n = 4 to 11 are 5.3 to 11.1, inside it. CI does not time anything.

Measured without a prediction, and only reported:
- **Last-bit violations:** `euclidean` exceeds the triangle inequality in 8 of the 15,625 triples, by at most 8.9e-16. These are the "last bits" the module expects where the exact values are equal. The other three distances show none.

Nothing in §7 needs MCP, so every step ran.

## MAT-002 · Counterexamples, witnesses and exhaustive checks

This part uses IX `ix-bracelet`, with `ix-search`, and `ix-petri`, all three pinned to the same commit.

- `preregistration-mat002.md` quotes the predictions of the module's §7 ([Demerzel `a3a07df`](https://github.com/GuitarAlchemist/Demerzel/blob/a3a07df103c1f13a4dec45514fe775bfd4f76e77/state/streeling/courses/mathematics/en/mat-002-counterexamples-and-exhaustive-checks.md)) and of two readings, in §4 and §6. It sets how each is judged and adds one hypothesis of the lab's own, M2-L1. It was committed on its own, before any code of this part existed, with SHA-256 `be884e1a…4e82c7`.
- `src/mat002.rs` holds the product rules and the checks:
  - IX's `compose`;
  - the faults S and F of the §4 and §6 exercises;
  - Z, without the sign flip;
  - two controls;
  - IX's two D12 tests, restated as checks A and B of any product rule;
  - the Petri net of IX's witness test.
- `examples/mat002_checks.rs` prints every step. All its values are integers or sets, so it needs no bits digest.
- `tests/mat002.rs` has one test per prediction, M2-P1 to M2-P6 and M2-L1, and the controls.

All the module's predictions held:
- **Associativity (P1):** IX's `compose` fails on none of the 13,824 triples.
- **Negative controls (P2):** rule S fails on 8,640 triples, and rule F on 90. Each set of failures includes the triple found by hand.
- **What IX's tests detect (P3):** IX's `compose` passes checks A and B. Rule F passes A and fails B. Rule S fails both, and A fails first at e · g = g, for g = (1, 1), with (11, 1).
- **The Petri witness (P4):** deadlock freedom is `Fails`, the witness is `a_short`, and replaying it with `fire` reaches the reported marking, `end=1`.
- **The triad (P5):** the 24 images of {0, 4, 7} are distinct. The rotations give the 12 major triads, and the reflections give the 12 minor triads.
- **No sign flip (P6):** rule Z fails on none of the 13,824 triples. Yet (s · r) · s is (1, 0) under Z, not r⁻¹ = (11, 0), which IX's `compose` returns.

The lab's own hypothesis held too:
- **M2-L1:** check B catches rule F on exactly 5 of the 5,184 (pair, set) combinations. All five are on the pair ((1, 1), (2, 1)), with the sets {0, 4, 7}, {0, 3, 7}, the C major scale, {0, 1, 4, 6} and {0}. The four sets that rotation by 6 fixes never show the fault. IX's action test catches a one-entry fault through five of its nine sample sets.

A test corrected before it was committed:
- **The P5 test.** Its first version compared the 12 images by the reflections with the transpositions of {0, 3, 7} index by index, and failed at (0, 1). The pre-registration says the 12 images "are the transpositions", a comparison of sets. (0, 1) sends {0, 4, 7} to {0, 5, 8}, which is {0, 3, 7} transposed by 5. The test now compares sets, as pre-registered. The measured images did not change: they are printed in `expected/`.

Measured without a prediction, and only reported:
- **Failure counts:** rule S fails on 8,640 triples and rule F on 90. Rules S and Z each fail check B on 1,392 of the 5,184 combinations.
- **Rule Z and check A:** rule Z also fails check A, first at g · g⁻¹ = e for g = (1, 1), where it returns (2, 0). Check A uses IX's `inverse`, which is the inverse for the true product, not for Z's.
- **The identity rule:** it fails check A first at e · g = g, for g = (1, 0).
