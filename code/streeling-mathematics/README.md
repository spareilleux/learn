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

The expected file was produced on Windows x86-64. CI runs `check.sh` on Linux, Windows and macOS: a diff there would be a measured cross-platform difference.
