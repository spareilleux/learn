---
title: "9. Five other reducers: MDS, kernel PCA, NMF, LDA and t-SNE"
description: "Recover a square from distances by hand and with IX, find which kernel-PCA axis separates two rings, factor CI timings, project labeled runner jobs, and test what IX's t-SNE transform actually does."
sidebar:
  order: 9
---

Lesson 5 used [PCA](../05-dimensionality-reduction/) to keep directions of high variance. That is one question, not a universal definition of a useful projection. Here are five different questions, each answered by a reducer in IX's pinned [`ix-unsupervised`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised). The runnable experiment is [`l09_reducers.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/examples/l09_reducers.rs); [`crosscheck.py`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/crosscheck/crosscheck.py) checks the corresponding properties independently with numpy and scikit-learn 1.8.0. The [journal](../journal/#2026-09-24--five-reducers-three-inputs) records what was measured and what remains uncertain.

| Question | Method | Input | What the output means |
|---|---|---|---|
| Can I preserve given distances without even having feature vectors? | Classical MDS | Pairwise distance matrix | Coordinates reproducing Euclidean distances, when possible |
| Can a nonlinear similarity reveal structure a straight axis misses? | Kernel PCA | Features and a chosen kernel | Axes of variance in the kernel feature space |
| Can I express nonnegative measurements as additive parts? | NMF | Nonnegative feature matrix | Nonnegative loadings and components whose product approximates the input |
| Which directions separate *known* classes? | Linear discriminant analysis (LDA) | Features **and** labels | At most `classes - 1` discriminant axes |
| Which points are local neighbours for a visualization? | t-SNE | Feature matrix | A fitted arrangement; distances and cluster areas are not calibrated measurements |

This **LDA** means *linear discriminant analysis*, not the unrelated *latent Dirichlet allocation*. None of these methods replaces a held-out evaluation of the downstream task.

## 1. MDS: start with distances, not features

[Classical multidimensional scaling](https://scikit-learn.org/stable/modules/manifold.html#multidimensional-scaling) begins with an `n × n` matrix `D`, not with the original features. Square every distance, subtract its row and column means and add its grand mean:

```text
Bᵢⱼ = -½ (D²ᵢⱼ - row_meanᵢ - column_meanⱼ + grand_mean)
```

That is the compact identity `B = -½ J D² J`, with `J = I - 11ᵀ/n`. If the distances come from Euclidean points, `B` is their centered Gram matrix: its top eigenvectors, scaled by the square roots of their eigenvalues, are coordinates. The hand version in the example reuses lesson 5's Jacobi eigensolver; IX's [`classical_mds`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/mds.rs) uses `ix-math`'s symmetric eigensolver. On a unit square, both recover all six nonzero pairwise distances within `1e-10`:

```text
== classical MDS: square from distances alone
  hand and IX recover all six distances: true
```

We compare *distances*, not coordinates: a reflection or rotation changes coordinates but not the answer. A non-Euclidean distance matrix may have negative eigenvalues; clipping them to zero gives an approximation, not a proof that the original distances were embedded exactly. IX implements **classical** MDS here, not iterative stress minimization.

## 2. Kernel PCA: a nonlinear similarity is a choice

[Kernel PCA](https://scikit-learn.org/stable/modules/decomposition.html#kernel-pca) replaces PCA's covariance matrix with a centered kernel matrix `Kᵢⱼ = k(xᵢ, xⱼ)`. IX's [`Kernel`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/kernel_pca.rs) is an enum with linear, polynomial and Gaussian RBF variants. The RBF value is `exp(-γ ||xᵢ-xⱼ||²)`: its `γ` changes which separations count as near.

Eight points lie on two concentric rings. Each ring's mean is `(0, 0)`, so a **linear** first axis cannot separate their means. An exploratory expectation that the **first RBF axis** would do it was also wrong. With `γ = 0.5`, the radial contrast is on **axis 4**:

```text
== kernel PCA: concentric rings
  mean gap on linear axis: 0.0000
  mean gap on RBF axis 1: 0.0000
  mean gap on RBF axis 4: 0.5798
  linear axis separates ring means: false
  fourth RBF axis separates ring means: true
```

Keeping only the top two components would discard the feature we hoped to expose. This is not a defect in IX: maximizing variance in the kernel space is still not the same objective as separating the two rings. Axis signs are arbitrary; the experiment uses the absolute gap between the inner and outer means.

## 3. NMF: additive parts require nonnegative data

[Nonnegative matrix factorization](https://scikit-learn.org/stable/modules/decomposition.html#nmf) seeks `V ≈ W H`, with every entry of `V`, `W` and `H` nonnegative. IX's [`NonNegativeMatrixFactorization`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/nmf.rs) uses multiplicative updates. The course's 186 CI jobs have five nonnegative timings in seconds, so they make a legitimate input. Rank two, 300 iterations and seed 42 give a reconstruction mean squared error of `0.505` seconds squared per cell:

```text
== NMF: CI timings, 186 jobs x 5 features
  rank 2 reconstruction MSE: 0.505
  standardized input rejected: true
```

Standardizing the same columns subtracts their means and creates negative values: IX rejects that matrix. Use the raw nonnegative timings for NMF, but do **not** call the two factors meaningful “workload archetypes” from the reconstruction error alone. Compare seeds, inspect `H`, and test a held-out reconstruction before giving the components names. Unlike PCA, NMF is not an orthogonal projection and its factors are not unique.

## 4. LDA: the labels decide what matters

[Linear discriminant analysis](https://scikit-learn.org/stable/modules/lda_qda.html#dimensionality-reduction-using-linear-discriminant-analysis) contrasts between-class scatter with within-class scatter. We know each CI job's runner OS: Ubuntu, Windows or macOS. IX's [`LinearDiscriminantAnalysis`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/lda.rs) fits two axes on standardized timings:

```text
== LDA: runner OS labels
  three OS classes allow at most two axes: true
  projection finite: true
```

Three classes allow at most `3 - 1 = 2` discriminant axes, regardless of the five input columns. This example fits and projects the **same** 186 rows to demonstrate the API; it reports no test accuracy. To test whether the timings predict OS, split first, fit the scaler and LDA on training rows only, transform test rows, then train and score a classifier. Otherwise the labels of the test rows leak into the projection.

## 5. t-SNE: a picture of local neighbourhoods, not a reusable scaler

[t-SNE](https://scikit-learn.org/stable/modules/manifold.html#t-sne) converts distances into neighbourhood probabilities in the input and in a low-dimensional arrangement, then moves the displayed points to reduce their mismatch. The *perplexity* controls a neighbourhood scale, not the number of clusters. The plot can be valuable, but its global distances and apparent cluster sizes are not calibrated: use it to ask questions of the original data, not to certify an effect.

IX's [`TSNE`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/tsne.rs) takes a seed. We fit just twelve standardized jobs, with perplexity 3 and 300 iterations. The module header says “Barnes-Hut approximation”, but the pinned implementation loops over every pair in `compute_q` and again in the gradient; for this version, budget quadratic pairwise work, not Barnes-Hut scaling. More importantly, `transform` ignores its argument and returns the stored fitted arrangement:

```text
== t-SNE: first 12 standardized jobs
  12 x 2 finite embedding: true
  transform ignores its input: true
```

Passing a thirteenth job to `transform` does **not** place it on that map. Refitting with the new point changes the optimization problem and may move every point. If the task requires a reusable projection for future jobs, start with PCA or fitted kernel PCA; do not present IX's t-SNE as a production transformer.

## What to use for our repositories

- **IX/GA voicing geometry:** start with PCA and a task-specific retrieval metric; use kernel PCA or t-SNE as exploratory views, never as evidence that apparent islands are musical classes.
- **Gaia or CI history:** classical MDS makes sense when the object is a measured distance between runs or traces, not a numeric feature vector. Check whether the distances are Euclidean before promising an exact low-dimensional map.
- **CI timing signatures:** NMF may expose additive patterns in nonnegative durations, but its components need stability and held-out checks. LDA uses known runner labels to ask a different, supervised question.

## Exercises

1. Why does the square experiment compare six distances rather than four pairs of coordinates? What would you conclude if the maximum distance error were `0.2`?
2. Why does the first RBF component fail to separate the rings even though the fourth succeeds? What happens if you keep only two components?
3. Why does NMF reject the standardized CI jobs? What must you fit only on training rows before estimating whether runner OS is predictable from LDA coordinates?
4. Can IX's t-SNE place a new job using `transform`? Which single line of its pinned source settles the question?

<details>
<summary>Solutions</summary>

1. Eigenvector signs and rotations are not identifiable; pairwise distances are. An error of `0.2` means this two-dimensional embedding does **not** reproduce the requested geometry exactly.
2. The top axes maximize kernel-space variance, not ring separation; the radial contrast is fourth here. Two components discard it. Changing `γ` or the data can change the order, so inspect the fitted axes rather than memorizing “fourth”.
3. Centering produces negative entries, forbidden by NMF. For a supervised estimate, split before fitting both the scaler and LDA, and score on untouched test rows.
4. No. In the [`DimensionReducer` implementation](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/tsne.rs#L249-L253), `fn transform(&self, _x: &Array2<f64>)` returns `self.embedding.clone()`; `_x` is never read.

</details>

## Sources

- IX at pinned commit `490c395`: [MDS](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/mds.rs), [kernel PCA](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/kernel_pca.rs), [NMF](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/nmf.rs), [LDA](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/lda.rs), [t-SNE](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/tsne.rs).
- [scikit-learn's manifold-learning guide](https://scikit-learn.org/stable/modules/manifold.html), [decomposition guide](https://scikit-learn.org/stable/modules/decomposition.html) and [LDA guide](https://scikit-learn.org/stable/modules/lda_qda.html).
