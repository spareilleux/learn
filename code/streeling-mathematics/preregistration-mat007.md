# MAT-007 lab — pre-registration

Written on 2026-09-28, before any code of this lab was compiled or run. Its SHA-256 is recorded in the Learn progress receipt at the moment of writing. A later edit would be a new file with its own date, not a silent correction.

## Where the predictions come from

The predictions below are those of **§6 "Proposed Experiment (Not Yet Run)"** of the Streeling module MAT-007, *Least Squares, Regularisation and Identifiability*. They were published before this lab existed, in [Demerzel `8c14336`](https://github.com/GuitarAlchemist/Demerzel/blob/8c14336ecd9601615e08c20dca696cd0e021563e/state/streeling/courses/mathematics/en/mat-007-least-squares-regularisation.md), and are quoted here without change. This file adds only what the module leaves open:
- how each prediction is judged;
- the negative controls;
- what the lab does not cover.

Where the module says "about", the band is set here, before the run, and not after.

## What is measured

- **Library under test:** IX, pinned at `e35138b9d4c707d48f802649a7fcb3f7fc94934d`, the same commit as the MAT-003 lab and the module. It is read with `git show`, never from a working tree.
  - `ix-supervised` is added to the lab at that commit; `ix-math` is already there.
- **Precision:** IEEE 754 binary64 (`f64`).
- **Anchors at the pin:**

  | Anchor | What it is |
  |---|---|
  | `crates/ix-supervised/src/linear_regression.rs:57` | `LinearRegression::fit`: it appends a ones column, forms XᵀX and Xᵀy, and multiplies by `inverse(XᵀX)`. |
  | `linear_regression.rs:68` | `.expect("X^T X is singular")`: a `Singular` answer from `inverse` becomes a panic. |
  | `crates/ix-math/src/linalg.rs:110` | `inverse` answers `Singular` when the largest remaining pivot is `< 1e-12`, an absolute threshold. |
  | `crates/ix-math/src/svd.rs:73` | `SvdResult::pseudo_inverse(tol)`: V·diag(1/s)·Uᵀ over the singular values `s > tol`. |

- **The fitted parameters** are read from the public fields `weights` and `bias` after `fit`.
- **Panics** are caught in the lab with `std::panic::catch_unwind`, and the panic message is recorded.

## Predictions, quoted from the module

**Step 1, the offset sweep.** For c = 10^0, 10^1, …, 10^7, `fit` receives x = c + (0, 1, 2) and y = 2x + 1. Every value is an integer below 2^53, so the inputs are exact.
- **M7-P1a.** "The slope is within 10^-9 of 2 for c ≤ 10^3."
  - Judged as |slope − 2| < 1e-9 for c = 10^0 … 10^3.
- **M7-P1b.** "At c = 10^5 the slope is 2 − 2^-18 and the bias 1.5."
  - Judged bit for bit: slope == 2 − 2^-18, and bias == 1.5.
- **M7-P1c.** "At c = 10^6 the slope is 2 + 2^-11 and the bias 0." The §5 exercise adds that "the fitted values at the data are then off by about 487, with no error raised".
  - Judged bit for bit: slope == 2 + 2^-11 = 2.00048828125, and bias == 0.
  - `fit` returns without a panic.
  - The largest |fitted − y| over the three points lies in [486, 489].
- **M7-P1d.** "At c = 10^7 `fit` panics with 'X^T X is singular'."
  - Judged as: the panic is caught, and its message contains `X^T X is singular`.
- **M7-P1e.** "On the centered feature (−1, 0, 1), the same data give the slope exactly 2 and the bias 2c + 3, the fitted value at x̄, within a relative 10^-15, at every c."
  - Judged as slope == 2 bit for bit, and |bias − (2c + 3)| ≤ 1e-15 · (2c + 3), for every c.
- c = 10^4 has no prediction in the module. It is measured and printed, and no claim is made about it.

**Step 2, normal equations against the SVD.** x₁ = N · (1, 2, 3, 4), x₂ = x₁ + (1, −1, −1, 1), y = x₁ + x₂ + 1. The exact weights are (1, 1) and the exact bias is 1. N = 10^0, …, 10^7.
- **The SVD route.** The design D is the 4 × 3 matrix [x₁ x₂ 1], with the ones column last, as `fit` builds it. The route computes `svd(D)` and then `pseudo_inverse(tol)` with tol = max(4, 3) · σ₁ · `f64::EPSILON` = 4 · σ₁ · 2^-52, the tolerance of MAT-006. The answer is the pseudo-inverse times y.
- **The error** of a route is the largest of |w₁ − 1|, |w₂ − 1| and |bias − 1|.
- **M7-P2a.** "The largest weight error of `fit` is below 10^-9 for N ≤ 10^3."
- **M7-P2b.** It is "about 3 · 10^-5 at N = 10^5".
  - "About" is judged here as within a factor of 10, that is in [3e-6, 3e-4]. The module calls these "orders of magnitude from the rule of thumb of MAT-003, not bounds".
- **M7-P2c.** It is "about 0.25 at N = 10^7, with no error raised".
  - Judged as: `fit` returns without a panic, and the error lies in [0.025, 2.5].
- **M7-P2d.** "The SVD route stays below 10^-7 at every N."
  - Judged as an error < 1e-7 for N = 10^0 … 10^7.
- The fixture's κ₂, from IX's `svd` (σ₁/σ₃), is printed. The module's "κ₂ grows like 10 N" is an estimate: it is printed, not asserted.

## Negative controls

Each one shows that a check can fail:
- **Weight-error check.** Applied to the wrong weights (1, 1, 0), it reports an error ≥ 1.
- **Bit-exact comparator.** It tells 2 − 2^-18 from 2.
- **Panic catcher.** It reports "no panic" for c = 10^0 and "panic" for a closure that panics.

## What would not be claimed

- **The MCP server and the schema, steps 3 and 4 of §6, are not run.** They need `ix-agent` and a disposable `ix-mcp` process, which is outside this slice. Their predictions stay "proposed".
- Nothing about other data, other models, or IX commits other than `e35138b9`.
- **Platforms.** The expected file is produced on Windows x86-64. CI runs `check.sh` on Linux, Windows and macOS: a diff there would be a measured cross-platform difference, not something to update away.
- **Printed output is for display only.** Every claim above is checked by an assertion in `tests/mat007.rs`.
- **A refuted prediction is a result.** It is recorded in the test and the README, not tuned away.
