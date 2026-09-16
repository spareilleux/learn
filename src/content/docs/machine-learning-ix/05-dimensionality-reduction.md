---
title: "5. Principal components, and what a variance ratio means"
description: "Five CI timings pressed into two, by diagonalizing their covariance matrix — Jacobi rotations by hand against IX's power iteration, the explained-variance ratio IX normalizes over the components it kept rather than over the data, and a cloud whose principal axis power iteration never finds because its starting vector is orthogonal to it."
sidebar:
  order: 5
---

Lessons 3 and 4 both worked on the same five numbers: the seconds a CI job spends waiting, setting up, checking out, cleaning up and finishing. Five numbers are already too many to draw, and two of them — `checkout_s` and `post_checkout_s` — carry almost the same information. **Dimensionality reduction** asks for fewer numbers that lose as little as possible.

The oldest answer is **principal component analysis**: find the direction along which the data varies most, then the direction of largest remaining variation at right angles to it, and so on. Keep the first two and you can draw the data; keep all of them and you have only rotated it.

| | ML.NET | Tribuo | scikit-learn | IX |
|---|---|---|---|---|
| PCA | [`ProjectToPrincipalComponents`](https://learn.microsoft.com/dotnet/api/microsoft.ml.pcacatalog.projecttoprincipalcomponents) | [`PCA`](https://tribuo.org/learn/4.3/javadoc/org/tribuo/util/infotheory/example/package-summary.html) via `TransformationMap` | [`PCA`](https://scikit-learn.org/stable/modules/generated/sklearn.decomposition.PCA.html) | `ix_unsupervised::pca::PCA` |
| How the axes are found | randomized SVD | SVD | SVD, `svd_flip` for the signs | power iteration with deflation |
| Variance explained | `Eigenvalues` | — | `explained_variance_ratio_` | `explained_variance_ratio()` |
| Others in the crate | — | — | `KernelPCA`, `NMF`, `TSNE`, `MDS`, `LDA` | `kernel_pca`, `nmf`, `tsne`, `mds`, `lda` |

The program of this lesson is [`examples/l05_reduction.rs`](https://github.com/spareilleux/learn/blob/37b8830/code/machine-learning-ix/examples/l05_reduction.rs). It works on the 186 jobs, standardized as in lesson 4, so that a second of queueing counts as much as a second of checkout.

## Variance along a direction

Take a unit vector **u**. Project every centred row onto it, and the projections have a variance. Written with the **covariance matrix** **C** — the matrix whose entry `i, j` is the covariance of feature `i` with feature `j` — that variance is exactly `uᵀ C u`.

So "the direction of largest variance" is "the unit vector that maximizes `uᵀ C u`", and linear algebra answers that in one line: it is the **eigenvector** of **C** with the largest **eigenvalue**, and that eigenvalue *is* the variance along it. The second direction is the next eigenvector, the third the next, and because **C** is symmetric they are all at right angles to each other.

Standardized columns make **C** easy to read: every diagonal entry is 1, and every other entry is a correlation.

```text
== covariance matrix of the standardized features
  [1.005, -0.083, 0.048, 0.030, 0.516]
  [-0.083, 1.005, -0.201, -0.276, 0.095]
  [0.048, -0.201, 1.005, 0.794, 0.084]
  [0.030, -0.276, 0.794, 1.005, 0.040]
  [0.516, 0.095, 0.084, 0.040, 1.005]
trace (total variance): 5.027
```

The diagonal is 1.005 rather than 1 because the scaler divides by `n` and the covariance by `n - 1`. Two pairs stand out: `checkout_s` with `post_checkout_s` at 0.794 — cleaning up a checkout takes as long as the checkout deserved — and `queue_s` with `complete_s` at 0.516. Five features, but fewer than five independent things going on.

## Two ways to diagonalize

IX finds one eigenvector at a time by **power iteration**: multiply a starting vector by **C** over and over, and it turns towards the eigenvector with the largest eigenvalue. Then it **deflates** — subtracts that eigenpair from the matrix — and repeats ([`pca.rs`, lines 103-151](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/pca.rs#L103-L151)):

```rust
let mut v = Array1::from_elem(n, 1.0 / (n as f64).sqrt());
// …
let v_new = matrix.dot(&v);
let new_eigenvalue = v.dot(&v_new);
```

This lesson uses the other classical method, **Jacobi's**: repeatedly pick the largest off-diagonal entry and rotate it away. Each rotation is a change of basis that keeps the eigenvalues; when nothing off the diagonal is left, the diagonal holds every eigenvalue and the accumulated rotations hold every eigenvector ([`src/reduce.rs`, lines 34-93](https://github.com/spareilleux/learn/blob/37b8830/code/machine-learning-ix/src/reduce.rs#L34-L93)):

```rust
// The angle that zeroes m[p][q]: cot(2θ) = (m[p][p] - m[q][q]) / (2 m[p][q])
let theta = 0.5 * (2.0 * m[[p, q]]).atan2(m[[p, p]] - m[[q, q]]);
let (c, s) = (theta.cos(), theta.sin());
```

An eigenvector has no natural sign: **u** and **-u** describe the same axis. scikit-learn settles it by making the largest-magnitude entry of each component positive, and the hand version copies that rule so the two can be compared entry by entry.

```text
== all five components, by hand (Jacobi)
  component 1: variance 1.9441, ratio 0.3867, cumulative 0.3867, [0.161, -0.331, 0.645, 0.654, 0.140]
  component 2: variance 1.5060, ratio 0.2996, cumulative 0.6863, [0.679, 0.142, -0.102, -0.144, 0.699]
  component 3: variance 0.9183, ratio 0.1827, cumulative 0.8690, [-0.251, 0.891, 0.291, 0.194, 0.146]
  component 4: variance 0.4517, ratio 0.0899, cumulative 0.9588, [-0.671, -0.269, -0.063, -0.057, 0.686]
  component 5: variance 0.2070, ratio 0.0412, cumulative 1.0000, [0.005, 0.069, -0.696, 0.714, 0.027]
sum of the five ratios: 1.0000
```

The first component is `0.645 · checkout_s + 0.654 · post_checkout_s` with small contributions from the rest: the checkout axis, exactly the pair that correlated at 0.794. The second is `0.679 · queue_s + 0.699 · complete_s`: the waiting axis. Two axes out of five explain 69 % of everything the five timings do.

The five eigenvalues add up to 5.027, the trace of the covariance matrix. That is not a coincidence: rotating the data cannot create or destroy variance, only redistribute it between axes.

## IX finds the same axes

```text
== ix_unsupervised::pca::PCA, five components
  ix   variance [1.9441, 1.5060, 0.9183, 0.4517, 0.2070]
  hand variance [1.9441, 1.5060, 0.9183, 0.4517, 0.2070]
  largest difference: 1.28e-10
  component 1: ix [0.161, -0.331, 0.645, 0.654, 0.140] same direction as the hand version
  component 2: ix [0.679, 0.142, -0.102, -0.144, 0.699] same direction as the hand version
  component 3: ix [-0.251, 0.891, 0.291, 0.194, 0.146] same direction as the hand version
  component 4: ix [0.671, 0.269, 0.063, 0.057, -0.686] opposite direction to the hand version
  component 5: ix [0.005, 0.069, -0.696, 0.714, 0.027] same direction as the hand version
```

The variances agree to ten decimals, and scikit-learn prints the same five. Component 4 points the other way, which changes nothing about the subspace or the reconstruction — power iteration simply has no sign convention, and whichever way its starting vector leans is the way the answer comes out. Code that compares two runs of PCA has to compare axes, not vectors.

The scores agree as well, since the sign of component 4 does not enter the first two:

```text
== first three jobs in two dimensions
  job 0 on ubuntu  hand [-1.2345, 1.7418] ix [-1.2345, 1.7418]
  job 1 on ubuntu  hand [-1.9498, -0.1172] ix [-1.9498, -0.1172]
  job 2 on ubuntu  hand [-0.5102, -0.6465] ix [-0.5102, -0.6465]
```

## The ratio that is always 1

Ask for two components instead of five and the two libraries stop agreeing:

```text
== keeping two of the five components
  hand ratio [0.3867, 0.2996] sum 0.6863
  ix   ratio [0.5635, 0.4365] sum 1.0000
```

`explained_variance_ratio` divides each kept eigenvalue by the sum of the **kept** eigenvalues ([`pca.rs`, lines 46-57](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/pca.rs#L46-L57)):

```rust
self.explained_variance.as_ref().map(|ev| {
    let total = ev.sum();
    if total > 0.0 { ev / total } else { ev.clone() }
})
```

`ev` only ever holds the `n_components` eigenvalues the model kept, so the ratios sum to 1 whatever you ask for, and the doc comment — "proportion of total variance per component" — is true only when you keep every component. The number a reader wants is 0.3867: the share of the *data's* variance. IX reports 0.5635, the share of the part it decided to keep, which cannot be used to decide how much to keep. The exercise below shows the consequence: the usual "how many components do I need for 90 %?" question always answers "one".

The raw variances would settle it, but `explained_variance` is a private field; `save_state()` is the only way to read them out of a fitted model.

:::note[Confirmed independently]
scikit-learn's `PCA(n_components=2)` on the same matrix reports `[0.3867, 0.2996]` summing to 0.6863 — the hand version, not IX's. See the `== lesson 5` section of [`crosscheck/crosscheck.py`](https://github.com/spareilleux/learn/blob/37b8830/code/machine-learning-ix/crosscheck/crosscheck.py).
:::

## What is lost

Keeping `k` components and mapping back gives the best rank-`k` approximation of the data. The error it leaves is exactly the variance thrown away:

```text
== mean squared reconstruction error, and the variance kept
  k 1: error 0.6133, variance kept 0.3867
  k 2: error 0.3137, variance kept 0.6863
  k 3: error 0.1310, variance kept 0.8690
  k 4: error 0.0412, variance kept 0.9588
  k 5: error 0.0000, variance kept 1.0000
```

The two columns add up to 1.0000 on every line, and not by luck: standardized features have a mean square of 1 per cell, so the error left by `k` components is exactly the share of the variance the other components carried. That identity is the reason the ratio matters — it is the one number that says what a reduction costs, which is also why a ratio that always reads 1.0000 says nothing.

## A cloud power iteration cannot see

Power iteration starts from the same vector every time — `(1, 1, …, 1)/√n`, every coordinate equal ([`pca.rs`, line 107](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/pca.rs#L107)). Multiplying by **C** turns that vector towards the dominant eigenvector — unless it is already an eigenvector itself, in which case it never moves.

Six points make such a cloud. They stretch along `(1, -1)`, with a little spread along `(1, 1)`:

```text
== a cloud stretched along (1, -1)
  covariance [2.4, -1.6, -1.6, 2.4]
  hand eigenvalues [4.0000, 0.8000] first eigenvector [0.7071, -0.7071]
  ix PCA(1): variance [0.8000] component [0.7071, 0.7071]
  ix PCA(2): variance [0.8000, 0.0000] components [0.7071, 0.7071] [0.7071, 0.7071]
  ix PCA(1) scores [0.0000, 0.0000, 0.0000, 0.0000, 1.4142, -1.4142]
```

The principal axis carries variance 4.0 along `(1, -1)`. `PCA::new(1)` returns the other one: variance 0.8 along `(1, 1)`, the *minor* axis. The starting vector is that minor eigenvector, so `C·v = 0.8·v`, the Rayleigh quotient stops changing on the second pass, and the loop exits satisfied.

`PCA::new(2)` is worse. Deflation removes the 0.8 axis, leaving a matrix whose only direction is `(1, -1)`; power iteration starts again from `(1, 1)/√2`, which that matrix sends to zero, the `norm < 1e-15` guard fires, and the starting vector is returned unchanged. The model ends up with the same component twice and a variance of 0, describing a two-dimensional cloud with one repeated axis.

The scores show what this costs: four of the six points project to exactly 0, so the reduction that was supposed to keep the most informative direction has flattened the data along it.

This is a knife-edge case — it needs the two features to have exactly equal variance — and on the CI jobs IX and Jacobi agree to ten decimals. But it is the shape of the failure, not its rarity, that matters: power iteration from a fixed start has no guarantee, and nothing in `PCA`'s output says which case you are in. scikit-learn's SVD has no such starting vector, and returns variance 4.0 along `(0.7071, -0.7071)`.

## What to do with this

- To decide how many components to keep, compute the ratio yourself from `save_state().explained_variance`, dividing by the sum over *all* the components — which means fitting `PCA::new(n_features)` once.
- Before trusting a first component, fit with every component and check the variances come out in decreasing order. Power iteration plus deflation cannot guarantee it, and the `ix_ml_pipeline` tool turns PCA on with `normalize`.
- Comparing two PCA runs means comparing subspaces or absolute values, never signed vectors.

## Exercises

1. How many components does it take to keep 90 % of the variance, and what does `explained_variance_ratio()` say for each count?
2. **Whiten** the two-component scores — divide each column by its own standard deviation — and show the result has an identity covariance matrix.
3. Rebuild job 0 from 1, 2, 3, 4 and 5 components and watch it converge on the true row.

<details>
<summary>Solutions</summary>

They are in [`examples/l05_exercises.rs`](https://github.com/spareilleux/learn/blob/37b8830/code/machine-learning-ix/examples/l05_exercises.rs).

**1.** Four components are needed. IX answers the question with 1.0000 whatever you ask for, so the question cannot be asked of it:

```text
== components needed for a share of the variance
  k 1: really kept 0.3867, ix reports 1.0000
  k 2: really kept 0.6863, ix reports 1.0000
  k 3: really kept 0.8690, ix reports 1.0000
  k 4: really kept 0.9588, ix reports 1.0000
  k 5: really kept 1.0000, ix reports 1.0000
  4 components pass 0.90; IX reports 1.0000 for every k
```

**2.** The scores are already uncorrelated — that is what "at right angles" buys — so their covariance matrix is diagonal, holding the two eigenvalues. Dividing each column by the square root of its eigenvalue makes both variances 1:

```text
== whitening the two-component scores
  covariance of the raw scores
    [1.944062, 0.000000]
    [0.000000, 1.505963]
  covariance of the whitened scores
    [1.000000, 0.000000]
    [0.000000, 1.000000]
```

Whitening is what a distance-based method wants before it starts: after it, Euclidean distance in the score space is Mahalanobis distance in the original space.

**3.** One component puts job 0 near the middle of everything; the fifth restores it exactly:

```text
== job 0 rebuilt, one component at a time
  true      [-0.091, 1.785, -0.596, -0.796, 1.968]
  k 1       [-0.198, 0.409, -0.797, -0.808, -0.173]
  k 2       [0.984, 0.655, -0.975, -1.059, 1.043]
  k 3       [0.589, 2.056, -0.517, -0.754, 1.273]
  k 4       [-0.091, 1.783, -0.581, -0.811, 1.968]
  k 5       [-0.091, 1.785, -0.596, -0.796, 1.968]
```

Job 0 is unusual — 1.785 standard deviations of setup and 1.968 of completion — so the first component, which is about checkout, gets it wrong; the third, the setup axis, is the one that finds it.

</details>

## Sources

- James, Witten, Hastie, Tibshirani, Taylor, *[An Introduction to Statistical Learning](https://www.statlearning.com/)*, chapter 12
- Golub and Van Loan, *Matrix Computations*, chapter 8, for Jacobi's method and the convergence of power iteration
- [scikit-learn: decomposing signals in components](https://scikit-learn.org/stable/modules/decomposition.html) and [`svd_flip`](https://scikit-learn.org/stable/modules/generated/sklearn.utils.extmath.svd_flip.html)
- IX at `490c395`: [`ix-unsupervised/src/pca.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/pca.rs), and the other reducers in the same crate — [`tsne.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/tsne.rs), [`mds.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/mds.rs), [`kernel_pca.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/kernel_pca.rs), [`nmf.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/nmf.rs), [`lda.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/lda.rs)
