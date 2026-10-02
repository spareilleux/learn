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
