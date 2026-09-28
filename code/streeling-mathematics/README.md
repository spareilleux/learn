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
- **MAT-003's puzzle (P4):** capped at k sweeps, `svd_with_opts(2^20·fl(H_n), k, 1e-12)` reproduces bit for bit both `svd(fl(H_n))` and `svd(2^-20·fl(H_n))`, for every n from 2 to 16, as the module's explanation needs. For n = 6 to 16, the smallest such k is the predicted one. For n = 2 to 5, it is lower: 1 and 1 for n = 2, 2 and 2 for n = 3, 3 and 3 for n = 4 and 5.

Measured without a prediction, and only reported:
- **Post hoc, P4:** at the predicted k, the capped result also reproduces both results, for every n. So the module's sweep counts hold. For n = 2 to 5, the extra sweeps change no bit.
- **Scale 1 against scale down:** the singular values differ for 11 of the 15 sizes. MAT-003 had reported that κ₂ changes for 10 of 15 across three scales, a different measure.
- **M at 10^-12 and 10^-11:** the singular values are off by 3.4e-9, neither accurate nor wrong by 100%. The error of `reconstruct` is 0.0515 at 10^-13 and 10^-12.
- **Step 1 at full rank:** the tail of an empty list of singular values prints as `-0.000000e0`. Rust's `f64` sum of nothing is −0.0, and its square root is −0.0.

The `ix_svd` half of step 5 is not run: it goes through the MCP server.
