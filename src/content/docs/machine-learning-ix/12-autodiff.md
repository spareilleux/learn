---
title: "12. Automatic differentiation: the Wengert tape"
description: "Forward and reverse mode written by hand, then IX's ix-autograd tape checked against closed forms, central differences and numpy, with eight predictions written before the first run: all eight held. Its gradients match the closed forms below 10⁻¹², its FFT backward is right, and IX's own training example reports PASS on parameters its data cannot identify."
sidebar:
  order: 12
---

Lessons 2, 7 and 8 trained models with gradients derived by hand, and lesson 7 found one derived wrong: IX's `Dense::backward` divides by the batch size twice (finding 15). Automatic differentiation computes the gradient from the program that computes the loss, so there is nothing to derive. IX's pinned [`ix-autograd`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd) crate does it with a Wengert tape. This lesson writes both modes of automatic differentiation by hand, reads IX's tape, and checks it three ways: against closed forms, against central differences and against numpy.

The eight predictions this lesson tests were [written in the journal](../journal/#2026-09-29--lesson-12-predicted-before-measuring) and committed before any of its code existed. [The results](../journal/#2026-09-30--lesson-12-measured) follow them. The experiments are in [`autodiff.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/src/autodiff.rs), one test per prediction. [`l12_autodiff.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/examples/l12_autodiff.rs) prints what they measure. [`crosscheck.py`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/crosscheck/crosscheck.py) recomputes the linear regression, its conditioning and the FFT gradient with numpy.

| Method | What it gives | Cost for n inputs and one output | Error |
|---|---|---|---|
| Symbolic | A formula for the derivative | Expressions that can grow much larger than f | Exact |
| Central differences | (f(x + εeᵢ) − f(x − εeᵢ)) / 2ε | 2n evaluations of f | Truncation and rounding |
| Forward mode | The derivative with respect to one input per pass | n passes | Rounding only |
| Reverse mode | The derivatives with respect to every input | One forward pass and one backward walk | Rounding only |

## 1. Forward and reverse mode, by hand

Automatic differentiation breaks a program into elementary operations, each with a known derivative, and applies the chain rule to them. The list of those operations, one intermediate value per line, is a Wengert list. [Baydin et al.](https://jmlr.org/papers/v18/17-468.html) use f(x₁, x₂) = ln(x₁) + x₁x₂ − sin(x₂) at (2, 5) as their running example: v₁ = ln x₁, v₂ = x₁x₂, v₃ = sin x₂, v₄ = v₁ + v₂, and f = v₄ − v₃.

**Forward mode** carries a derivative alongside each value. A dual number v + dε, with ε² = 0, does it with plain arithmetic: (a + bε)(c + dε) = ac + (ad + bc)ε, so the ε part of the result is the product rule. Start with d = 1 on x₁ and d = 0 on x₂, run f, and the ε part of the result is ∂f/∂x₁. Getting ∂f/∂x₂ takes a second pass, with the seeds swapped. `Dual` in `autodiff.rs` implements addition, subtraction, multiplication, `ln` and `sin`.

**Reverse mode** records the list first, then walks it backwards. It keeps an adjoint v̄ᵢ = ∂f/∂vᵢ for each entry, starts with f̄ = 1, and each entry adds its adjoint times its local derivative to its operands' adjoints. One walk gives every input's derivative. `Tape` in `autodiff.rs` does this for scalars:

```text
== f(x1, x2) = ln(x1) + x1*x2 - sin(x2) at (2, 5)
  forward mode, one pass per input:  f = 11.6521, df/dx1 = 5.5000, df/dx2 = 1.7163
  reverse mode, one backward walk:   f = 11.6521, df/dx1 = 5.5000, df/dx2 = 1.7163
  entry 0: Input      value   2.0000   adjoint  5.5000
  entry 1: Input      value   5.0000   adjoint  1.7163
  entry 2: Ln(0)      value   0.6931   adjoint  1.0000
  entry 3: Mul(0, 1)  value  10.0000   adjoint  1.0000
  entry 4: Sin(1)     value  -0.9589   adjoint -1.0000
  entry 5: Add(2, 3)  value  10.6931   adjoint  1.0000
  entry 6: Sub(5, 4)  value  11.6521   adjoint  1.0000
```

Entry 4 gets adjoint −1 from the subtraction. Entry 1, x₂, collects two contributions: 1 × x₁ = 2 through the product, and −1 × cos 5 = −0.2837 through the sine, 1.7163 in all. These are Baydin et al.'s values: 11.652, 5.5 and 1.716.

A training loss has one output and many inputs, which is the case reverse mode is built for. It gives all n partial derivatives for a small constant multiple of the cost of f, whatever n is: Griewank and Walther's cheap gradient principle. Forward mode would need n passes, and central differences 2n evaluations.

## 2. IX's tape

In `ix-autograd`, a `DiffContext` holds a `Tape`, a vector of `TapeNode`s. Each op computes its value with [ndarray](https://docs.rs/ndarray/0.17.2/ndarray/struct.ArrayBase.html), pushes a node holding its name, its input handles and its value, and returns the new node's handle. [`DiffContext::backward`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd/src/ops.rs#L382-L454) walks the indices from the output down to 0 and dispatches on the op's name. The walk order is valid because the tape is append-only: an op's inputs always have smaller indices than the op. The gradients accumulate in a map from handle to array, with `+=`, so a handle used twice collects both contributions.

The nodes hold whole tensors, so `LinearRegressionTool::build_graph` records ten of them where the scalar tape above needs 265 entries for the same loss. The data are those of IX's own training example, [`minimize_linreg_mse`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd/examples/minimize_linreg_mse.rs), rebuilt line for line: 20 rows and 3 features. The closed forms, with r = ŷ − y, are ∂L/∂w = (2/n)xᵀr, ∂L/∂b = (2/n)Σr and ∂L/∂x = (2/n)r wᵀ:

```text
== IX's tape for the linear regression of `minimize_linreg_mse` (20 rows, 3 features)
  10 nodes: input, input, input, input, matmul, add, sub, mul, sum, div_scalar
  ops::variance adds 6: sum, div_scalar, sub, mul, sum, div_scalar
  w = 0, b = 0: loss 0.724417, dL/dw [-0.959694, 0.656138, -0.961510], dL/db -0.032640
    largest difference from the closed forms: w < 1e-12, b < 1e-12, x < 1e-12
    hand-written scalar tape, 265 entries: loss < 1e-12, w < 1e-12, b < 1e-12
  random w, b : loss 0.312636, dL/dw [-0.439221, 0.390372, -0.475970], dL/db -0.662593
    largest difference from the closed forms: w < 1e-12, b < 1e-12, x < 1e-12
    hand-written scalar tape, 265 entries: loss < 1e-12, w < 1e-12, b < 1e-12
```

The bias b has shape [1, 1] and is broadcast over the 20 rows by `add`. Its backward sums the incoming gradient over the broadcast axis, which `unbroadcast` does, so ∂L/∂b is a sum over rows. The `mul(residual, residual)` node lists the same handle twice, and the map adds both contributions: 2r, as in the hand-written tape. Every gradient agrees with its closed form below 10⁻¹², at w = 0 and at a random point (P1, P2).

The op set is `add`, `sub`, `mul`, `sum`, `matmul`, `div_scalar`, `mean` and `variance`, plus `rfft_magnitude` behind a feature. It has no `exp`, `log`, `tanh` or ReLU yet. At this commit the tape can train a linear model on a squared error, but not a logistic regression or a network with a nonlinearity.

## 3. What the tape does not check

`Tensor` carries a `requires_grad` flag, and its doc asks target data to set it to false ([`tensor.rs` 28-32](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd/src/tensor.rs#L28-L32)). No op and not the reverse walk reads it, so the walk computes a gradient for every leaf on the path to the loss (finding 29):

```text
== What the tape does not check
  y has requires_grad = false, and backward returned a gradient for it; largest difference from -(2/n)r: < 1e-12
  x, also built with requires_grad = false, gets one too: true
  add on [2, 3] and [3, 2]: Panic("called `Result::unwrap()` on an `Err` value: ShapeError/IncompatibleShape: incompatible shapes")
  sub on [2, 3] and [3, 2]: Panic("called `Result::unwrap()` on an `Err` value: ShapeError/IncompatibleShape: incompatible shapes")
  mul on [2, 3] and [3, 2]: Panic("called `Result::unwrap()` on an `Err` value: ShapeError/IncompatibleShape: incompatible shapes")
```

`LinearRegressionTool::backward` drops y's gradient by hand, and its comment says the walker computes one anyway. A caller using the ops directly gets them all, including the 20 × 3 gradient for x, which nobody trains. In [PyTorch](https://docs.pytorch.org/docs/stable/notes/autograd.html), the backward computation is never performed in subgraphs where no tensor requires a gradient.

`add`, `sub` and `mul` return a `Result`, and `add`'s comment says ndarray "errors if incompatible" ([`ops.rs` 78](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd/src/ops.rs#L78)). ndarray 0.17's `&a + &b` panics instead when the shapes do not broadcast, so these ops never return `ShapeMismatch` (finding 30). A pipeline cannot catch the error through the `Result`. `MseLossTool` avoids it by comparing the shapes itself before building its graph ([`mse_loss.rs` 86-92](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd/src/tools/mse_loss.rs#L86-L92)).

## 4. Checking a gradient with central differences

A central difference (f(x + εe) − f(x − εe))/2ε has two errors. Truncation, from the Taylor series, is about f‴ε²/6. Rounding is about u|f|/ε, where u = 1.1 × 10⁻¹⁶: each evaluation of f is off by a few units in its last place, and the division by ε magnifies that. The total is smallest near ε = (3u|f|/|f‴|)^(1/3), about 10⁻⁵ when f and f‴ are of order 1 ([Nocedal and Wright](https://doi.org/10.1007/978-0-387-40065-5), section 8.1).

A quadratic has f‴ = 0, so only rounding is left (P5). The second loss, L = Σ c_k |Y_k| where Y is the FFT of a 64-sample signal and the c_k are random weights, has both errors (P6):

```text
== Central differences against the tape
  mean squared error at w = 0 (quadratic in w), worst of the 3 components of dL/dw:
    eps 1e-1: < 1e-12
    eps 1e-2: < 1e-12
    eps 1e-3: < 1e-12
    eps 1e-4: < 1e-12
    eps 1e-5: < 1e-12
    eps 1e-6: 6e-11
    eps 1e-7: 8e-10
    eps 1e-8: 2e-8
    eps 1e-9: 7e-8
    eps 1e-10: 6e-7
    eps 1e-11: 7e-6
    eps 1e-12: 6e-5
  L = sum c_k |FFT(x)_k|, 64 samples, worst of the 64 components of dL/dx:
    eps 1e-1: 5e-3
    eps 1e-2: 5e-5
    eps 1e-3: 5e-7
    eps 1e-4: 6e-9
    eps 1e-5: 4e-9
    eps 1e-6: 1e-8 to 1e-7
    eps 1e-7: 1e-7 to 1e-6
    eps 1e-8: 1e-6 to 1e-5
    eps 1e-9: 1e-5 to 1e-4
    eps 1e-10: 1e-4 to 1e-3
  IX's dL/dx, first four components: [-4.429396, -6.277916, -0.459292, -5.058516]
  smallest at eps 1e-5; eps 1e-1 is 1e6 times that; eps 1e-1 and 1e-10 both at least 100 times: true
```

On the quadratic, every ε from 10⁻¹ down to 10⁻⁵ is exact to 10⁻¹², and below that the error grows about tenfold per decade: rounding alone. On the FFT loss, the error falls a hundredfold per decade down to 10⁻⁴, the ε² of truncation, and rises tenfold per decade below 10⁻⁵, the 1/ε of rounding. A smaller ε is not a safer one. The central differences of the mean squared error use a copy of the loss written as plain loops in a fixed order, so the rounding noise in the table is the same on every OS. The FFT loss is not: IX's FFT takes one `cos` and one `sin` per stage from the platform's maths library, and to the right of the minimum the table shows their last bits. On the first CI run, Linux and macOS printed 4e-6, 7e-5 and 4e-4 for the last three rows where Windows printed 6e-6, 5e-5 and 5e-4 ([journal](../journal/#2026-09-30--lesson-12-measured)). On that side the table therefore prints only the decade, and P6's two conditions as one check.

IX's own verifier, [`tests/finite_diff.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd/tests/finite_diff.rs), uses ε = 10⁻⁶ and checks each op under `sum`, which weighs every output alike. A random weight per output, as c_k does here, also checks that each output's gradient reaches the right inputs.

## 5. The FFT backward

`rfft_magnitude` returns |Y| where Y = FFT(x). Its backward follows from ∂|Y_k|/∂Y_k = Y_k/|Y_k|: the incoming gradient g becomes a complex gradient g_k Y_k/|Y_k| on the spectrum, and the FFT is linear, so that gradient goes back through an inverse FFT: ∂L/∂x = N · Re(ifft(g ⊙ Y/|Y|)). The module doc warns that `ix_signal::fft::rfft` returns all N bins, not the N/2 + 1 of numpy's [`rfft`](https://numpy.org/doc/stable/reference/routines.fft.html), so no Hermitian mirroring is needed ([`ops_fft.rs` 5-15](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd/src/ops_fft.rs#L5-L15)). In a half spectrum, bins 1 to N/2 − 1 each stand for two bins, k and N − k, and a backward through it must count them twice, except the DC and Nyquist bins: that is the mirroring the module doc means.

The crate keeps this op behind the `fft-autograd` feature, off by default, "until cross-checked against JAX rfft grad". Here it is checked against central differences on 20 signals, each with its own weights (P7):

```text
== IX's FFT-magnitude backward (feature fft-autograd)
  20 signals of 64 samples, each with its own weights, eps 1e-5: worst error over 1280 components below 1e-7: true
```

The worst error was 8·10⁻⁹ on Windows and 9·10⁻⁹ on Linux and macOS, rounding again, so the line prints a bound. numpy's own FFT, through the same formula, gives the same first four components, −4.429396, −6.277916, −0.459292 and −5.058516, and agrees with numpy's central differences below 10⁻⁶. That is a check against finite differences and numpy, not the JAX comparison the crate asks for. A bin whose magnitude is below 10⁻¹⁵ gets a zero gradient, a valid choice where |·| has a kink; this lesson did not test a signal with such a bin.

## 6. IX's own example, replayed

`minimize_linreg_mse` builds 20 rows of 3 features from a hash of the index, sets y = x · [0.5, −0.3, 0.8] + 0.1 + noise, and trains w and b with [Adam](https://arxiv.org/abs/1412.6980) for 200 steps. `ix_example_adam` in `autodiff.rs` replays it line for line. The example itself, compiled from the pinned commit in a scratch crate, prints the same numbers: loss 0.010101 at step 30, first below 0.01 at step 31, final w [0.64994, −0.30000, 0.65006], b 0.09832, and "R7 Day 3 go/no-go: PASS".

```text
== IX's `minimize_linreg_mse`, replayed
  k in the noise -0.01 + k*0.02/32767, rows 0 to 19: 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 2 2 2
  x[i, 2] - x[i, 0] over the 20 rows: min 0.055422, max 0.055483
  least squares: w [0.499818, -0.300000, 0.800182], b 0.089990, w0 + w2 = 1.300000, mean squared error < 1e-12
  Adam step   1: loss 7.24e-1
  Adam step  10: loss 4.97e-2
  Adam step  20: loss 4.70e-2
  Adam step  30: loss 1.01e-2
  Adam step  40: loss 4.38e-3
  Adam step  50: loss 1.26e-3
  Adam step  60: loss 9.15e-4
  Adam step  70: loss 4.99e-5
  Adam step  80: loss 1.38e-4
  Adam step  90: loss 1.07e-5
  Adam step 100: loss 9.91e-6
  Adam step 110: loss 5.94e-6
  Adam step 120: loss 2.67e-7
  Adam step 130: loss 4.22e-7
  Adam step 140: loss 2.88e-7
  Adam step 150: loss 3.74e-8
  Adam step 160: loss 5.52e-9
  Adam step 170: loss 9.65e-9
  Adam step 180: loss 4.55e-9
  Adam step 190: loss 6.52e-10
  Adam step 200: loss 2.35e-11
  after 200 steps: w [0.649940, -0.300002, 0.650065], b 0.098315, w0 + w2 = 1.300005, loss 2.35e-11
  loss below 0.01 first at step 31; the example prints 7500 / 31 = 242x as its speedup over a genetic algorithm
```

**The noise is a constant.** The example adds "tiny deterministic noise" so that the final loss is not zero. For rows 0 to 19, `(i·7919 + 31) >> 16` is 0, 1 or 2, so the noise is −0.01 plus at most 1.2 × 10⁻⁶. The intercept absorbs it: least squares gives b = 0.089990 and a mean squared error below 10⁻¹², and Adam reaches 2.35 × 10⁻¹¹ (P8, finding 32).

**Two of the three features are one.** Moving two indices on advances the hash by 2 × 1103515245, which is 33,676.6 × 2¹⁶. After `>> 16` and `& 0x7fff`, the value moves by +908 or +909, and dividing by 32,767 and doubling makes that 0.05542 or 0.05548. None of the 20 rows wraps around, so column 2 is column 0 plus 0.0554, give or take one step of 6 × 10⁻⁵. numpy puts the smallest singular value of [x 1] at 8.9 × 10⁻⁵, a condition number of 51,251. The data determine w₀ + w₂ = 1.3 and b, and the split between w₀ and w₂ only through that jitter.

- **Least squares** uses the jitter and lands near the truth, at [0.499818, −0.300000, 0.800182].
- **Adam** starts from zero, where the two columns give w₀ and w₂ almost the same gradient at every step. Adam scales each coordinate's step by its own gradient history, so the two take almost the same steps and end at 0.650 each.

Both reach a loss near 10⁻¹¹. The example prints the final w next to the true w, 0.21 apart, then "PASS": its criterion is the loss alone (finding 31). The speedup it reports is 7500 divided by the step count, where 7500 is the midpoint of "~5000-10000 fitness evaluations" that a genetic algorithm "typically" needs. The example never runs one (finding 33).

## 7. The predictions, scored

| | Prediction, written before the first run | Measured | Verdict |
|---|---|---|---|
| P1 | Linear regression records 10 nodes, in a stated order; `variance` adds 6 | 10 and 6, in that order | Confirmed |
| P2 | Gradients equal the closed forms within 10⁻¹², at w = 0 and at a random point; the hand tape agrees | Below 10⁻¹² for w, b and x, both points | Confirmed |
| P3 | y, with `requires_grad` false, still gets a gradient, equal to −(2/n)r | It does, below 10⁻¹² | Confirmed |
| P4 | `add`, `sub` and `mul` panic on [2, 3] and [3, 2] | All three panic | Confirmed |
| P5 | Quadratic: error at most 10⁻¹² at ε = 0.1, at least 10⁻⁹ at ε = 10⁻¹⁰ | Below 10⁻¹²; 6 × 10⁻⁷ | Confirmed |
| P6 | FFT loss: the best ε is in [10⁻⁶, 10⁻³], and ε = 10⁻¹ and 10⁻¹⁰ are each at least 100 times worse | 10⁻⁵; 10⁶ and 10⁵ times worse | Confirmed |
| P7 | FFT backward within 10⁻⁶ of central differences at ε = 10⁻⁵, 20 signals | 8 × 10⁻⁹ on Windows, 9 × 10⁻⁹ on Linux and macOS | Confirmed |
| P8 | Least squares on the example's data: b in [0.0899, 0.0901], mean squared error below 10⁻¹¹ | 0.089990; below 10⁻¹² | Confirmed |

All eight predictions held on the first run, and none was adjusted afterwards. P3, P4 and P8 were written to catch a gap between IX's documentation and its code, found by reading it first, and all three found one. The collinear features, the result that matters most here, were not predicted: P8 explained the intercept and missed the weights. The journal records them as exploratory.

## What to use for our repositories

- **Reverse mode** for a scalar loss over many parameters. **Forward mode**, with dual numbers, for few inputs, or for one directional derivative to check.
- **IX's `ix-autograd`:** its gradients are exact for the ops it has, which cover linear models, squared errors, variances and FFT magnitudes. Don't rely on `requires_grad`. Check shapes before calling `add`, `sub` or `mul`, since a mismatch panics.
- **A new backward:** check it against central differences at ε near 10⁻⁵, with a random weight per output, at a point away from kinks.
- **Before reading fitted parameters,** check that the data determine them: the condition number of the design matrix, or two optimizers that should agree. A low loss says nothing about which minimum was found.

## Exercises

1. Run forward mode by hand on g(x₁, x₂) = x₁x₂ + sin(x₁) at (0, 3): write the value and the ε part of each intermediate, for both passes.
2. IX's reverse walk visits nodes by decreasing index. Why does no node get visited before a node that uses it? What would break if an op could overwrite an existing node, as an in-place update does?
3. At ε = 10⁻¹⁰ the quadratic's error is 6 × 10⁻⁷. Estimate it from rounding alone: the loss is 0.724, and each evaluation is off by about one unit in its last place.
4. Write the backward rule of an `exp` op for IX's tape: what does it need from the forward pass, and what does it return?

<details>
<summary>Solutions</summary>

1. First pass, seeding x₁: x₁ = 0 + 1ε, x₂ = 3 + 0ε, x₁x₂ = 0 + 3ε, sin x₁ = 0 + cos(0)ε = 0 + 1ε, g = 0 + 4ε, so ∂g/∂x₁ = x₂ + cos x₁ = 4. Second pass, seeding x₂: x₁x₂ = 0 + 0ε, since the ε part is x₁ × 1 = 0, and sin x₁ = 0 + 0ε, so ∂g/∂x₂ = x₁ = 0.
2. The tape is append-only: an op is pushed after its inputs exist, so every node that uses a given node has a larger index, and a walk by decreasing index reaches all of them first. An in-place op would give a node a new value after other nodes had read the old one. Their backward rules would then read the wrong value, and the index order would no longer match the order of use.
3. The difference of two evaluations of 0.724 is off by about 2 × 0.724 × 1.1 × 10⁻¹⁶ ≈ 1.6 × 10⁻¹⁶. Divided by 2ε = 2 × 10⁻¹⁰, that is about 8 × 10⁻⁷, close to the 6 × 10⁻⁷ measured.
4. The derivative of eᵃ is eᵃ, which is the op's own output, so the node's value is all the backward needs. It returns g ⊙ value for its single input, with no `unbroadcast`, because the op keeps the shape.

</details>

## Sources

- IX at pinned commit `490c395`: [`ops.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd/src/ops.rs), [`tape.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd/src/tape.rs), [`tensor.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd/src/tensor.rs), [`ops_fft.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd/src/ops_fft.rs), [`linear_regression.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd/src/tools/linear_regression.rs), [`minimize_linreg_mse.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd/examples/minimize_linreg_mse.rs) and [`finite_diff.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd/tests/finite_diff.rs).
- R. E. Wengert, ["A simple automatic derivative evaluation program"](https://doi.org/10.1145/355586.364791), *Communications of the ACM* 7(8), 1964.
- A. G. Baydin, B. A. Pearlmutter, A. A. Radul and J. M. Siskind, ["Automatic differentiation in machine learning: a survey"](https://jmlr.org/papers/v18/17-468.html), *Journal of Machine Learning Research* 18, 2018: the running example, forward and reverse mode.
- A. Griewank and A. Walther, [*Evaluating Derivatives*](https://doi.org/10.1137/1.9780898717761), 2nd edition, SIAM, 2008: the tape and the cheap gradient principle.
- J. Nocedal and S. J. Wright, [*Numerical Optimization*](https://doi.org/10.1007/978-0-387-40065-5), 2nd edition, Springer, 2006, section 8.1: the error of finite differences.
- D. P. Kingma and J. Ba, ["Adam: a method for stochastic optimization"](https://arxiv.org/abs/1412.6980), ICLR 2015.
