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

P5b does not depend on the band. 2^±20·fl(H) are exact multiples of fl(H), so their κ₂ are equal in exact arithmetic, and three different answers mean at least two are not κ₂ of the input. That still does not say which one is right.

The expected file was produced on Windows x86-64. CI runs `check.sh` on Linux, Windows and macOS: a diff there would be a measured cross-platform difference.
