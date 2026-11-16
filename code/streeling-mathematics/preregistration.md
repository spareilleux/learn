# MAT-003 lab — pre-registration

Written before any code of this lab was compiled or run. Its SHA-256 is recorded in the Learn progress receipt at the moment of writing; any later edit is a new file with its own date, not a silent correction.

## What is measured

- **Library under test:** IX `ix-math`, pinned at `e35138b9d4c707d48f802649a7fcb3f7fc94934d`. Read with `git show`, never from a working tree.
- **Precision:** IEEE 754 binary64 (`f64`). The unit roundoff is u = 2⁻⁵³ ≈ 1.11e-16, and `f64::EPSILON` = 2⁻⁵² = 2u.
- **Anchors at the pin:**

  | Anchor | What it is |
  |---|---|
  | `crates/ix-math/src/linalg.rs:83` | `inverse`: Gauss-Jordan with partial pivoting. |
  | `linalg.rs:110` | `inverse` returns `Err(MathError::Singular)` when the largest remaining pivot magnitude is `< 1e-12`. The threshold is **absolute**: it is not scaled by the size of the matrix. |
  | `crates/ix-math/src/svd.rs:100` | `svd`: one-sided Jacobi, 50 sweeps, `tol = 1e-12`. Its rotation test (`:136`) and stopping test (`:174`) are relative. |
  | `svd.rs:67` | `rank(tol)`: counts the singular values `> tol`. |
  | `svd.rs:73` | `pseudo_inverse(tol)`: V·diag(1/s)·Uᵀ over the singular values `s > tol`. |
  | `crates/ix-agent/src/handlers.rs:639` | The MCP `ix_svd` rank tolerance, σ₁·1e-10. |

- **Matrices:**
  - Hilbert matrices, H_n[i][j] = 1/(i+j-1), for n = 2…16, built in `f64`. The matrix IX receives is therefore fl(H_n), not H_n.
  - H_n scaled by 2²⁰ and by 2⁻²⁰.
  - The identity scaled by 2⁻³⁹ and by 2⁻⁴⁰.
  - The singular matrix [[1,2],[2,4]].
- **Oracle, independent of IX:** the exact inverse of H_n, from the closed form with integer entries (Choi 1983):

  (H_n⁻¹)ᵢⱼ = (-1)^(i+j) (i+j-1) C(n+i-1, n-j) C(n+j-1, n-i) C(i+j-2, i-1)²

  It is computed in `i128`, so it is exact for n ≤ 16, and rounded to `f64` only for comparison. From it: κ∞(H_n) = ‖H_n‖∞·‖H_n⁻¹‖∞.
- **Norms:** ∞-norm (maximum absolute row sum) unless stated.
- **Measured quantities:**
  - κ₂ = σmax/σmin, from IX `svd`;
  - the verdict of `inverse`, Ok or Singular;
  - the forward error e = ‖X − H⁻¹‖∞/‖H⁻¹‖∞;
  - the residual r = ‖H·X − I‖∞;
  - `rank` and the residual of `pseudo_inverse` at tol = σ₁·1e-10, and at tol = 0.

## Predictions, written before running

Each prediction is labelled with its source: **theorem**, **code** (read at the pin), or **estimate**, and says what would refute it.

- **P0. The oracle is correct** (theorem, and a check).
  - H_n × (exact inverse) = I, in exact integer arithmetic, for n ≤ 10.
  - H₃⁻¹ = [[9,-36,30],[-36,192,-180],[30,-180,180]], and κ∞(H₃) = 748 exactly.
  - Negative control: the same check fails when one entry of the oracle has its sign flipped.
- **P1. The κ₂ band** (theorem: for a symmetric A, κ∞/n ≤ κ₂ ≤ κ∞).
  - IX's κ₂ lies in the band while its computed σmin is accurate.
  - Predicted: the band holds for n = 2…11. It fails for at least one n in 12…16, because there true κ₂ > 1/u, so the rounding of the input (about u·‖H‖) exceeds σmin, and the computed σmin is noise.
  - Literal: κ₂(H₃) = 524.0567775860644 (literature value), expected within a relative 1e-9.
- **P2. Forward error** (estimate from Higham's bounds for inversion). For every n that `inverse` accepts, e ≤ n·κ∞·u.
  - A violation would mean that either the constant is too small or the algorithm is less accurate than the bound says. It would be recorded, not tuned away.
- **P3. The refusal boundary** (code, and a closed form). Without pivoting, the last pivot of H_n is exactly 1/((2n-1)·C(2n-1,n-1)²): 6.2e-12 at n = 10 and 3.8e-13 at n = 11.
  - Predicted: `inverse(H_n)` first returns Singular at **n = 11**. Partial pivoting and rounding may move this by one, so 10–12 is consistent; outside it refutes the reasoning.
  - Untested hypothesis: once it refuses, it refuses for every larger n up to 16.
- **P4. The refusal measures scale, not conditioning** (code: the threshold is absolute).
  - I·2⁻⁴⁰ (≈ 9.1e-13, κ = 1) is refused as Singular.
  - I·2⁻³⁹ (≈ 1.8e-12) is accepted, and its inverse is exactly I·2³⁹.
  - H_n·2⁻²⁰ is first refused at **n = 6** (5–7 consistent): its pivot 4.3e-7·2⁻²⁰ < 1e-12, although κ₂(H₆) ≈ 1.5e7 leaves about 9 correct digits.
  - H_n·2²⁰ is first refused later than n = 11. Predicted: there is an accepted n whose forward error e > 1, meaning no correct digit, returned without an error.
- **P5. Exact scaling** (theorem: multiplying by a power of two is exact in binary floating point, barring overflow and underflow).
  - Where both are accepted, `inverse(2ᵏ·H)` equals `inverse(H)`·2⁻ᵏ **bit for bit**, for k = ±20.
  - Hypothesis from reading the code: `svd` is scale-equivariant too, so κ₂ is bit-identical for H, 2²⁰H and 2⁻²⁰H.
- **P6. Pseudo-inverse at the MCP tolerance** (theorem: when r < n singular values are kept, H·P = U_r U_rᵀ is a projector, and ‖H·P − I‖₂ = 1).
  - `rank(σ₁·1e-10)` first drops below n at **n = 8**, estimated from κ₂(H₈) ≈ 1.5e10 > 1e10 in the literature; 7–9 is consistent.
  - Below that n, the residual of P is small (≤ n·κ∞·u).
  - From that n on, the residual is of order 1 (≥ 0.5 in the ∞-norm), and ‖P‖₂ ≤ 1/tol always holds. P is then a bounded, regularised answer, not an inverse.
- **P7. The checker can fail** (negative control). The residual check, applied to a wrong inverse (I in place of H₃⁻¹), reports a residual ≥ 1.
- **P8. Cross-platform** (hypothesis, untested here). The run is pure IEEE arithmetic with no fused multiply-add emitted by `rustc`, so the raw bits are identical on Windows x86-64, Linux x86-64 and macOS arm64. A digest of all raw `f64` bits is printed so that CI can refute this.
  - If CI refutes it, the expected file switches to tolerance-based comparison, and the refutation is recorded.

## What would not be claimed

- Nothing about matrices other than these fixtures.
- Nothing about IX's other solvers.
- No platform is covered until hosted CI passes on it.
- Rounded printed output is display only: every claim above is checked by an assertion with an explicit bound, in `tests/`.
