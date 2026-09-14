---
title: 2. Linear regression and gradient descent
description: A straight line through the build times of this site, by least squares in closed form and by gradient descent — by hand, with IX's normal equation and with IX's SGD, Momentum and Adam optimizers — why descent diverges on raw features, what standardizing changes, and one outlier that decides the slope.
sidebar:
  order: 2
---

Lesson 1 predicted every build with a constant. This lesson lets the prediction depend on one feature, the number of pages, along the oldest model there is: a straight line, `seconds = w · pages + b`. Finding `w` and `b` is **linear regression**. It can be solved exactly, with a formula, or step by step, with **gradient descent**; the second way is how almost every other model in machine learning is trained, so it's worth seeing on a problem where the exact answer is known.

| | ML.NET | Tribuo | scikit-learn | IX |
|---|---|---|---|---|
| Exact least squares | [`Ols`](https://learn.microsoft.com/dotnet/api/microsoft.ml.mklcomponentscatalog.ols) | [`LARSTrainer`](https://tribuo.org/learn/4.3/javadoc/org/tribuo/regression/slm/LARSTrainer.html), least angle regression | [`LinearRegression`](https://scikit-learn.org/stable/modules/generated/sklearn.linear_model.LinearRegression.html) | `ix_supervised::linear_regression::LinearRegression` |
| By gradient descent | [`OnlineGradientDescent`](https://learn.microsoft.com/dotnet/api/microsoft.ml.standardtrainerscatalog.onlinegradientdescent) | [`LinearSGDTrainer`](https://tribuo.org/learn/4.3/javadoc/org/tribuo/regression/sgd/linear/LinearSGDTrainer.html) | [`SGDRegressor`](https://scikit-learn.org/stable/modules/sgd.html) | a loss and `ix_optimize::gradient::minimize` |
| Optimizers | — | [`AdaGrad`](https://tribuo.org/learn/4.3/javadoc/org/tribuo/math/optimisers/AdaGrad.html), [`Adam`](https://tribuo.org/learn/4.3/javadoc/org/tribuo/math/optimisers/Adam.html)… | a `learning_rate` schedule | `SGD`, `Momentum`, `Adam` |

The program of this lesson is [`examples/l02_linear_regression.rs`](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/examples/l02_linear_regression.rs). It trains on the 52 oldest builds and tests on the 13 most recent, the chronological split of lesson 1.

## Least squares

Which line? The one with the smallest mean squared error on the training rows:

```text
L(w, b) = 1/n Σ (w·xᵢ + b - yᵢ)²
```

At the minimum, both partial derivatives of `L` are zero. Solving the two equations gives the closed form, with `x̄` and `ȳ` the means:

```text
w = Σ (xᵢ - x̄)(yᵢ - ȳ) / Σ (xᵢ - x̄)²        b = ȳ - w·x̄
```

`w` is the covariance of pages and seconds divided by the variance of pages ([`src/linear.rs`, lines 5-13](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/src/linear.rs#L5-L13)):

```rust
pub fn fit_closed_form(x: &Array1<f64>, y: &Array1<f64>) -> (f64, f64) {
    let n = x.len() as f64;
    let (mx, my) = (x.sum() / n, y.sum() / n);
    let cov: f64 = x.iter().zip(y).map(|(a, b)| (a - mx) * (b - my)).sum();
    let var: f64 = x.iter().map(|a| (a - mx).powi(2)).sum();
    let w = cov / var;
    (w, my - w * mx)
}
```

With several features, the same reasoning gives the **normal equation**. Add a column of ones to **X** for `b`; the parameters are `θ = (XᵀX)⁻¹ Xᵀy`. That's what [`LinearRegression::fit`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-supervised/src/linear_regression.rs#L57-L79) computes, with a matrix inverse:

```rust
let ones = Array2::ones((n, 1));
let x_aug = ndarray::concatenate(Axis(1), &[x.view(), ones.view()]).unwrap();
let xtx = x_aug.t().dot(&x_aug);
let xty = x_aug.t().dot(y);
let xtx_inv = ix_math::linalg::inverse(&xtx).expect("X^T X is singular");
let w = xtx_inv.dot(&xty);
```

```text
== least squares on the 52 training builds
hand: seconds = 0.041707 * pages + 9.708880
ix:   seconds = 0.041707 * pages + 9.708880
same to 1e-9: true
```

About 10 seconds of fixed cost, plus 0.04 seconds per page, or 24 pages a second. scikit-learn finds the same line in the cross-check. Inverting `XᵀX` is fine for a few features; it fails when two features are exact copies of each other, where `XᵀX` has no inverse and `fit` panics with that message (*to verify* on data), and loses precision when they're nearly so. Libraries like scikit-learn solve the least squares problem without forming the inverse.

## On the test builds

```text
== 13 test builds
line:     rmse 7.952, mae 4.574, r2 -0.180
baseline: rmse 10.344, mae 7.308, r2 -0.996
  93a0ea8 274 pages: actual 23 s, predicted 21.1 s, error +1.9
  a7a6f72 274 pages: actual 21 s, predicted 21.1 s, error -0.1
  fd52d46 277 pages: actual 24 s, predicted 21.3 s, error +2.7
  bd17932 271 pages: actual 24 s, predicted 21.0 s, error +3.0
  3147e64 277 pages: actual 23 s, predicted 21.3 s, error +1.7
  e5254f6 280 pages: actual 25 s, predicted 21.4 s, error +3.6
  b96934a 283 pages: actual 18 s, predicted 21.5 s, error -3.5
  35c2e3e 283 pages: actual 20 s, predicted 21.5 s, error -1.5
  85a8c04 283 pages: actual 19 s, predicted 21.5 s, error -2.5
  b0803c9 283 pages: actual 29 s, predicted 21.5 s, error +7.5
  bcfc3fc 283 pages: actual 26 s, predicted 21.5 s, error +4.5
  849fb18 286 pages: actual 21 s, predicted 21.6 s, error -0.6
  95a3830 289 pages: actual 48 s, predicted 21.8 s, error +26.2
without the 48 s build: rmse 3.336, mae 2.769, r2 -0.234
```

The line beats the baseline: its typical error falls from 10 to 8 seconds, and to 3 without the last build. Its R² is still negative, and gets worse without that build. The test builds all have between 271 and 289 pages, so the line predicts 21 to 22 seconds for all of them; what varies from 18 to 29 seconds is something the number of pages doesn't measure. R² compares the model with the mean of the test set, and on that narrow range, the line has nothing to explain. Metrics answer a precise question: here, "does the page count explain the differences between these 13 builds?", and the answer is no.

The 48-second build is one CI run; I haven't looked for its cause (*to verify*).

## Gradient descent

The closed form exists because the loss is a simple quadratic. For most models there's no formula, and the parameters are found by walking downhill. The **gradient** of `L` points uphill; each step moves the parameters a little in the opposite direction, scaled by the **learning rate** `α`:

```text
∂L/∂w = 2/n Σ (w·xᵢ + b - yᵢ)·xᵢ        ∂L/∂b = 2/n Σ (w·xᵢ + b - yᵢ)
w ← w - α · ∂L/∂w                        b ← b - α · ∂L/∂b
```

[`src/linear.rs`, lines 15-32](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/src/linear.rs#L15-L32):

```rust
let (mut dw, mut db) = (0.0, 0.0);
for (xi, yi) in x.iter().zip(y) {
    let error = w * xi + b - yi;
    dw += 2.0 * error * xi / n;
    db += 2.0 * error / n;
}
(w - learning_rate * dw, b - learning_rate * db)
```

From `w = 0` and `b = 0`, on the page counts as they are, printing the loss after 1, 10, 1,000 and 100,000 steps:

```text
== gradient descent by hand, raw pages
learning rate 3e-5: step 1 loss 4.957e2 step 10 loss 3.373e4 step 1000 loss 4.538e207 step 100000 loss NaN
  -> w NaN, b NaN
learning rate 1e-5: step 1 loss 3.354e1 step 10 loss 1.565e1 step 1000 loss 1.561e1 step 100000 loss 1.235e1
  -> w 0.080177, b 1.813045
```

With `α = 3e-5`, the loss grows with every step until it overflows. With `α = 1e-5`, after 100,000 steps the line is still far from `w = 0.0417, b = 9.71`. The two problems have one cause: the loss is a valley that is very steep in one direction and nearly flat in the other.

The curvature of `L` is its matrix of second derivatives, `2 · [[mean(x²), mean(x)], [mean(x), 1]]`. With the training pages of lesson 1 (mean 184.0, standard deviation 62.5), its eigenvalues are about 75,500 along the steep direction and 0.21 along the flat one. A step overshoots, and the descent diverges, when `α` is larger than 2 divided by the steepest curvature, about 2.6e-5: 3e-5 is above it. Below it, the flat direction shrinks by a factor `1 - α · 0.21` per step: with `α = 1e-5`, 100,000 steps only remove a fifth of the distance.

**Standardizing** the feature makes the valley round. With `z = (pages - μ) / σ`, `mean(z) = 0` and `mean(z²) = 1`, the curvature is `2` in every direction, and `α = 0.1` shrinks the error by a factor 0.8 per step in both. The line found on `z` converts back to pages: `w = ws / σ` and `b = bs - ws · μ / σ`.

```text
== gradient descent by hand, standardized pages, learning rate 0.1
100 steps: ws 2.605694, bs 17.384615 -> w 0.041707, b 9.708880
```

100 steps reach the closed form to six decimals. `bs` is the mean of the training seconds, as it must be when the feature has mean 0.

## IX's optimizers

`ix-optimize` separates the three parts of a descent: a function to minimize, an optimizer that turns a gradient into a step, and a loop. The function implements [`ObjectiveFunction`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-optimize/src/traits.rs#L5-L17): `evaluate` is required; `gradient` has a default that estimates it numerically, from `(f(x + ε) - f(x - ε)) / 2ε` with `ε = 1e-7` for each parameter ([`calculus.rs`, lines 7-21](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-math/src/calculus.rs#L7-L21)). The lesson's `Mse` gives the exact gradient ([lines 16-36](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/examples/l02_linear_regression.rs#L16-L36)); `ClosureObjective` wraps a closure and keeps the default.

The three optimizers, with `g` the gradient ([`gradient.rs`, lines 19-116](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-optimize/src/gradient.rs#L19-L116)):

| Optimizer | Step | Idea |
|---|---|---|
| `SGD(α)` | `θ ← θ - α·g` | the descent above |
| `Momentum(α, β)` | `v ← β·v - α·g`, `θ ← θ + v` | a ball that keeps some of its speed: faster along a long flat valley |
| `Adam(α)` | `m ← β₁·m + (1-β₁)·g`, `s ← β₂·s + (1-β₂)·g²`, `θ ← θ - α·m̂ / (√ŝ + ε)` | each parameter's step divided by the size of its recent gradients |

`m̂` and `ŝ` are `m` and `s` corrected for starting at zero, and IX uses `β₁ = 0.9`, `β₂ = 0.999`. Despite its name, `SGD` here isn't stochastic: `minimize` passes it the gradient over all rows at every step. Stochastic gradient descent, as in ML.NET's `OnlineGradientDescent`, uses one row or a small batch per step.

[`minimize`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-optimize/src/gradient.rs#L124-L168) stops when the length of the gradient falls below the tolerance, and returns the best parameters it has seen:

```text
== ix_optimize::gradient::minimize, from [0, 0]
SGD(0.1), exact gradient       iterations    79, converged true , loss 5.908583, w 0.041707, b 9.708880
SGD(0.1), numerical gradient   iterations    79, converged true , loss 5.908583, w 0.041707, b 9.708880
Adam(0.1), exact gradient      iterations   868, converged true , loss 5.908583, w 0.041707, b 9.708880
closed-form loss on the training builds: 5.908583
```

The numerical gradient changes nothing here: the loss is a quadratic, where a central difference is exact up to rounding. `SGD` stops after 79 iterations, the hand loop after 100, because they stop on different tests: the length of the gradient below 1e-6, and a step that moves less than 1e-9. Adam needs 868: its steps are divided by the recent size of the gradients, so they don't shrink in proportion to the gradient near the minimum, and the gradient takes longer to fall below the tolerance. Adam is built for problems where the gradients of different parameters have very different sizes; after standardizing, this one has none.

## Key takeaways

- Least squares has a closed form, `w = cov(x, y) / var(x)`, and the normal equation for several features. IX computes it with a matrix inverse, and matches the hand version and scikit-learn to 1e-9.
- Gradient descent diverges when the learning rate is larger than 2 divided by the steepest curvature, and crawls along flat directions. Features on different scales make both happen at once; standardizing fixes it.
- A line can beat the baseline and still have a negative R²: check what a metric compares the model with.
- In IX, a model to train is an `ObjectiveFunction`; `minimize` runs the loop with `SGD` (full-batch), `Momentum` or `Adam`, and without a `gradient` method uses a numerical one.

## Exercises

The solutions are in [`examples/l02_exercises.rs`](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/examples/l02_exercises.rs), and their output in `expected/l02_exercises.txt`.

1. Fit the line on all 65 builds. Then fit it 65 times, each time without one build, and print the three builds whose removal changes the slope most.

<details>
<summary>Solution</summary>

[Lines 17-34](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/examples/l02_exercises.rs#L17-L34):

```rust
let (w, b) = fit_closed_form(&pages, seconds);
let mut changes: Vec<(f64, usize)> = (0..pages.len())
    .map(|i| {
        let keep: Vec<usize> = (0..pages.len()).filter(|&j| j != i).collect();
        let (wi, _) = fit_closed_form(&pick(&pages, &keep), &pick(seconds, &keep));
        ((wi - w).abs(), i)
    })
    .collect();
changes.sort_by(|a, c| c.0.total_cmp(&a.0));
```

```text
== exercise 1
all 65 builds: seconds = 0.053333 * pages + 8.0049
without 95a3830 (289 pages, 48 s): slope changes by 0.007328
without b0803c9 (283 pages, 29 s): slope changes by 0.001631
without b96934a (283 pages, 18 s): slope changes by 0.001408
```

One build of 65 moves the slope by 14%, four times more than any other. It has the most pages and the largest error: least squares squares the errors, so a point far from the line and far from the mean pulls the line hardest. This is **influence**; statistics measures it with Cook's distance, and robust losses, like the Huber loss of scikit-learn's `SGDRegressor`, reduce it.

</details>

2. On all 65 builds, standardized, compare IX's `SGD` and `Momentum(0.9)` from `[0, 0]`, with learning rates 0.01 and 0.1. Which needs fewer iterations, and why does the answer change with the learning rate?

<details>
<summary>Solution</summary>

[Lines 36-65](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/examples/l02_exercises.rs#L36-L65):

```rust
for learning_rate in [0.01, 0.1] {
    let plain = minimize(
        &objective,
        &mut SGD::new(learning_rate),
        array![0.0, 0.0],
        &criteria,
    );
    let momentum = minimize(
        &objective,
        &mut Momentum::new(learning_rate, 0.9),
        array![0.0, 0.0],
        &criteria,
    );
    // …
}
```

```text
== exercise 2
learning rate 0.01: SGD 866 iterations (loss 16.315161), Momentum(0.9) 270 iterations (loss 16.315161)
learning rate 0.1: SGD 80 iterations (loss 16.315161), Momentum(0.9) 284 iterations (loss 16.315161)
```

Momentum wins with 0.01 and loses with 0.1. Standardized on its own rows, the loss has curvature 2 in every direction, so plain descent shrinks the error by `1 - 2α` per step: 0.98 with `α = 0.01`, 0.8 with `α = 0.1`. With momentum, the error follows `eₜ₊₁ = (1 + β - 2α)·eₜ - β·eₜ₋₁`; for both learning rates this recurrence oscillates, and its amplitude shrinks by `√β ≈ 0.95` per step. 0.95 beats 0.98, and loses to 0.8. Momentum helps when plain descent is slow, on long flat valleys; on a round bowl with a good learning rate, it only adds overshoot.

</details>

## Sources

- James, Witten, Hastie, Tibshirani, Taylor, *[An Introduction to Statistical Learning](https://www.statlearning.com/)*, chapter 3
- Goodfellow, Bengio, Courville, *[Deep Learning](https://www.deeplearningbook.org/)*, chapter 4 (curvature and the learning rate) and chapter 8 (momentum, Adam)
- [scikit-learn: linear models](https://scikit-learn.org/stable/modules/linear_model.html) and [stochastic gradient descent](https://scikit-learn.org/stable/modules/sgd.html)
- IX at `490c395`: [`ix-supervised/src/linear_regression.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-supervised/src/linear_regression.rs), [`ix-optimize/src/gradient.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-optimize/src/gradient.rs), [`ix-optimize/src/traits.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-optimize/src/traits.rs)
