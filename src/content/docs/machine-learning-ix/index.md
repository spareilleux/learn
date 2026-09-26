---
title: "Machine learning, as applied in IX — Mission"
description: "Learn machine learning from the algebra up — splitting and scoring, regression, classification, clustering, principal components, ensembles, neural networks, optimization and the rest — by writing each algorithm by hand in Rust, then reading and running the same algorithm in the IX crates, on the CI history of this site."
sidebar:
  label: Mission
  order: 0
---

:::note[How this course is tested]
Every result in this course is printed by a program in [`code/machine-learning-ix`](https://github.com/spareilleux/learn/tree/main/code/machine-learning-ix): a Cargo project that depends on the IX crates at commit [`490c395`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2). [`.github/workflows/ml-ix-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/ml-ix-examples.yml) runs `cargo fmt`, `clippy`, the unit tests and every example on Linux, Windows and macOS, and compares each output with the file in `expected/`. On Linux only, the same workflow recomputes the results that don't depend on IX with [numpy](https://numpy.org/doc/stable/) 2.4.2 and [scikit-learn](https://scikit-learn.org/stable/) 1.8.0, and compares them too. The outputs in the lessons were captured with Rust 1.94 on Windows in September 2026, and are the same on the three systems.
:::

## Why I'm learning this

[IX](https://github.com/GuitarAlchemist/ix) is a Rust workspace of machine learning and math algorithms that Claude Code can call as tools: k-means, decision trees, gradient descent, and about eighty crates more. When a tool answers "3 clusters, silhouette 0.50", I want to know what was computed, whether it's right, and what a better answer would look like.

The way I learn an algorithm is to write it. Each lesson writes an algorithm in a few dozen lines, runs it and IX's version on the same data, and compares the two to the last printed digit. When they differ, one of the two is wrong, and finding out which is where I learn the most: this is what the [journal](journal/) records, lesson by lesson.

## Who this course is for

You write C# or Java. You're comfortable with high-school algebra: a straight line `y = w·x + b`, a sum `Σ`, a square root, a derivative. You don't need to know any machine learning. You don't need to know Rust well either: the code uses loops, closures and the matrices of [ndarray](https://docs.rs/ndarray/0.17/ndarray/), and the [Rust course](../rust-for-csharp-java/) covers the rest.

If you've used [ML.NET](https://learn.microsoft.com/dotnet/machine-learning/), [Tribuo](https://tribuo.org/) or [Deeplearning4j](https://deeplearning4j.konduit.ai/), each lesson maps what you know to what IX does.

## IX, ML.NET and Tribuo in one table

| | ML.NET | Tribuo | IX |
|---|---|---|---|
| Language | C#, F# | Java | Rust |
| A data set | `IDataView`, typed columns | `Dataset<T>` of `Example<T>` | two `ndarray` matrices: `Array2<f64>` features, `Array1` labels |
| A model | `IEstimator.Fit` returns an `ITransformer` | `Trainer.train` returns a `Model` | a struct with `fit` and `predict` (traits `Regressor`, `Classifier`, `Clusterer`) |
| Preprocessing | `NormalizeMeanVariance`, fitted like a model | `TransformationMap` | `StandardScaler::fit`, then `transform` |
| From an AI assistant | — | — | MCP tools such as `ix_kmeans` and `ix_ml_pipeline` |

Sources: [ML.NET tasks and trainers](https://learn.microsoft.com/dotnet/machine-learning/resources/tasks), [Tribuo clustering](https://tribuo.org/learn/4.3/javadoc/org/tribuo/clustering/package-summary.html), [IX README](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/README.md).

## The data

No downloaded data set: both files come from this repository, and [`data/extract.py`](https://github.com/spareilleux/learn/blob/15cde435d825d3c392307e7c6f9ee2e085d0e2bc/code/machine-learning-ix/data/extract.py) rebuilds them from the CI history the [DuckDB course](../duckdb/) exported on 2026-09-14 (`runs.json` and `jobs.json`) and from Git:

- [`builds.csv`](https://github.com/spareilleux/learn/blob/15cde435d825d3c392307e7c6f9ee2e085d0e2bc/code/machine-learning-ix/data/builds.csv), for regression: the 65 successful builds of this site, in commit order, with the number of Markdown pages at that commit (18 to 289) and the seconds of the step that builds them (10 to 48). Does the build time grow with the number of pages?
- [`jobs.csv`](https://github.com/spareilleux/learn/blob/15cde435d825d3c392307e7c6f9ee2e085d0e2bc/code/machine-learning-ix/data/jobs.csv), for classification, clustering and everything after: 186 CI jobs, each with five timings in whole seconds (waiting in the queue, setting up the job, checking out the repository, cleaning up the checkout, completing the job) and the OS of the runner: 121 Ubuntu, 34 Windows, 31 macOS. Can the timings tell which OS ran a job?

## IX, pinned

The course uses seven IX crates so far: `ix-math` (statistics, scaling, splitting, calculus), `ix-supervised` (regression, classification, metrics, cross-validation), `ix-optimize` (gradient descent, annealing, particle swarm), `ix-unsupervised` (k-means, DBSCAN, Gaussian mixtures, PCA), `ix-ensemble` (random forests, gradient boosting), `ix-nn` (layers, losses, attention) and `ix-voicings` (the silhouette score and the clustering of guitar voicings). [`Cargo.toml`](https://github.com/spareilleux/learn/blob/37b8830/code/machine-learning-ix/Cargo.toml) takes them from Git, pinned to one commit, as the [Cargo reference](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html) describes:

```toml
ix-supervised = { git = "https://github.com/GuitarAlchemist/ix", rev = "490c39533627d296bf9f8f050e6fafc14d7a20c2" }
```

Every link to IX code in the lessons points to that commit, so the line numbers stay right when IX changes.

## By the end of this course, I will be able to

- split data for training and testing, pick a baseline, and score a model with the metric that fits the question;
- fit a straight line two ways, by the closed form and by gradient descent, and say why descent diverges;
- train and compare logistic regression, k nearest neighbours and a decision tree, with cross-validation;
- group data without labels with k-means, DBSCAN and a Gaussian mixture, and judge the groups;
- reduce five dimensions to two, and say exactly what the reduction cost;
- combine weak models by bagging and by boosting, and know which of the two forgives a bad setting;
- differentiate a network by hand and check the answer against finite differences;
- choose an update rule, and recognize a run that diverged from one that converged;
- read an algorithm in IX, check it against a hand-written version and scikit-learn, and describe a difference precisely.

## Outline

Lessons 1 to 9 are written. The rest is the plan, one lesson per family of algorithms IX implements, and each will be published with its code and its cross-check like the others.

| # | Lesson | IX crates | If you know ML.NET |
|---|---|---|---|
| 1 | [Data, features and evaluation](01-data-and-evaluation/) | `ix-math` | `IDataView`, `TrainTestSplit`, `RegressionMetrics` |
| 2 | [Linear regression and gradient descent](02-linear-regression/) | `ix-supervised`, `ix-optimize` | `Ols`, `OnlineGradientDescent` |
| 3 | [Classification: logistic regression, k nearest neighbours, decision trees](03-classification/) | `ix-supervised` | `LbfgsLogisticRegression`, `FastTree`, `CrossValidate` |
| 4 | [Clustering: k-means, DBSCAN, Gaussian mixtures](04-clustering/) | `ix-unsupervised`, `ix-voicings` | `KMeansTrainer` |
| 5 | [Principal components, and what a variance ratio means](05-dimensionality-reduction/) | `ix-unsupervised` | `ProjectToPrincipalComponents` |
| 6 | [Ensembles: bagging, random forests and gradient boosting](06-ensembles/) | `ix-ensemble` | `FastForest`, `LightGbm` |
| 7 | [Neural networks, and finite differences as the judge](07-neural-networks/) | `ix-nn` | — |
| 8 | [Optimization: descent, momentum, Adam, and searches without a gradient](08-optimization/) | `ix-optimize`, `ix-math` | — |
| 9 | [The other reducers: MDS, kernel PCA, NMF, LDA, t-SNE](09-other-reducers/) | `ix-unsupervised` | — |
| 10 | Sequences: Markov chains, hidden Markov models and Viterbi | `ix-graph` | — |
| 11 | Counting without counting: Bloom filters, HyperLogLog, count-min, cuckoo | `ix-probabilistic` | — |
| 12 | Automatic differentiation: the Wengert tape | `ix-autograd` | — |
| 13 | Attention, layer normalization and a transformer block | `ix-nn` | — |
| 14 | Reinforcement learning: bandits and Q-learning | `ix-rl` | — |
| 15 | Signals: the Fourier transform, wavelets, filters and Kalman | `ix-signal` | — |
| 16 | Search: A\*, Monte-Carlo tree search, local search | `ix-search`, `ix-graph` | — |
| 17 | Evolution: genetic algorithms, differential evolution, Pareto fronts | `ix-evolution` | — |
| 18 | Adversarial examples, poisoning and the defences | `ix-adversarial` | — |
| 19 | The shape of data: persistent homology | `ix-topo`, `ix-manifold` | — |
| 20 | On the GPU: matrix products, distances and k nearest neighbours in WGSL | `ix-gpu` | — |
| 21 | Pipelines end to end, and the MCP tools an assistant calls | `ix-pipeline`, `ix-agent` | `MLContext` |
| — | [Every crate and every public function](api-map/) | the 80 with a public surface | — |
| — | [Journal](journal/) | | |

## Resources

- [IX at commit `490c395`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2), and its [`docs/`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2/docs) folder of tutorials
- [scikit-learn user guide](https://scikit-learn.org/stable/), the reference the cross-check uses, and its page on [common pitfalls](https://scikit-learn.org/stable/common_pitfalls.html)
- [ML.NET documentation](https://learn.microsoft.com/dotnet/machine-learning/) and [Tribuo documentation](https://tribuo.org/)
- *[An Introduction to Statistical Learning](https://www.statlearning.com/)*, by James, Witten, Hastie, Tibshirani and Taylor: free online, the book behind most of the formulas here
- *[Deep Learning](https://www.deeplearningbook.org/)*, by Goodfellow, Bengio and Courville, for lessons 7, 8 and 12 to 14
- [ndarray](https://docs.rs/ndarray/0.17/ndarray/), the matrix crate IX and this course share
