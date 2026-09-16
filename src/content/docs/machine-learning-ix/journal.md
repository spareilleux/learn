---
title: "Journal"
description: "Dated progress notes — IX pinned at 490c395, the data extracted from this site's CI, the CI of the course code, nineteen places where IX differs from the textbook or scikit-learn, what agreed, the generated API map, and items to verify."
sidebar:
  order: 99
---

## Progress

- [x] IX cloned and pinned at commit `490c395`; the course code depends on seven of its crates
- [x] Data: `builds.csv` and `jobs.csv`, extracted from the CI history and the Git history of this repository
- [x] CI: formatting, clippy, unit tests and every example compared with `expected/` on three OSes, and a numpy and scikit-learn cross-check on Linux
- [x] Lesson 1: data, features and evaluation
- [x] Lesson 2: linear regression and gradient descent
- [x] Lesson 3: classification
- [x] Lesson 4: clustering
- [x] Lesson 5: principal components
- [x] Lesson 6: ensembles
- [x] Lesson 7: neural networks
- [x] Lesson 8: optimization
- [x] Appendix: the API map, generated from the pinned commit
- [ ] Lessons 9 to 21
- [x] French and Spanish translations

## 2026-09-14 — IX, pinned

- IX is cloned apart from my working copy, with `git clone --filter=blob:none`, and checked out at [`490c39533627d296bf9f8f050e6fafc14d7a20c2`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2), a commit of `main` from 2026-09-14, 21:40 UTC. The workspace has 83 folders under `crates/` (its README says 81 crates); the course reads `ix-math`, `ix-supervised`, `ix-optimize`, `ix-unsupervised`, `ix-voicings`, `ix-io` and `ix-agent`, and depends on the first five.
- `Cargo.toml` names each crate with `git` and `rev`, and `Cargo.lock` is committed. Cargo fetches the whole IX repository once for the five crates, including its `governance/demerzel` submodule.
- The course code shares `ndarray` 0.17 with IX: the matrices go from the hand versions to IX's functions without conversion.
- The IX MCP tools of my Claude Code session helped me find the algorithms; every result in the lessons comes from the compiled examples, not from the tools.

## 2026-09-14 — The data

- [`data/extract.py`](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/data/extract.py) reads `code/duckdb/data/runs.json` and `jobs.json`, the export the [DuckDB course](../../duckdb/journal/) made on 2026-09-14, and runs `git ls-tree` at each built commit to count its `.md` and `.mdx` files.
- `builds.csv`: the successful `build` jobs of *Deploy to GitHub Pages*, 65 rows, with the seconds of the step whose name starts with *Install, build*.
- `jobs.csv`: the jobs that ended in success or failure and have both a checkout step and its post step, 186 rows. The OS is the runner label without `-latest`. `queue_s` is the time from the creation of the job to its start.
- Every timing is a whole number of seconds (the difference of two timestamps, truncated). Lesson 1 shows what that does to IX's task inference, lesson 4 what it does to a Gaussian mixture.
- No data set was downloaded: both files are derived from this public repository.

## 2026-09-14 — The CI

- [`ml-ix-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/ml-ix-examples.yml) runs [`check.sh`](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/check.sh) on `ubuntu-latest`, `windows-latest` and `macos-latest`: `cargo fmt --check`, `cargo clippy --release --all-targets -- -D warnings`, `cargo test --release` (unit tests and doctests, including the `compile_fail` import of lesson 4), then each example, whose output and exit code are compared with `expected/` by `diff --strip-trailing-cr`. `UPDATE=1` rewrites `expected/`, `CROSSCHECK=1` adds the Python check locally.
- The cross-check runs on Linux only, with Python 3.13, numpy 2.4.2 and scikit-learn 1.8.0: it recomputes the metrics, the regression line, the decision tree, the k nearest neighbour accuracies, the silhouettes, DBSCAN and a Gaussian mixture, and compares its output with `expected/crosscheck.txt`. It can't replay IX's random number generator, so it doesn't reproduce IX's k-means starts or random splits.
- Floating-point values are printed with a fixed number of decimals (`fmt_vec` in [`src/lib.rs`](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/src/lib.rs#L47-L51)), so the outputs are identical on the three systems; none needed a per-OS file.
- Runs [34903197003](https://github.com/spareilleux/learn/actions/runs/34903197003) (the lessons' examples, commit `d9ef7fb`) and [34903462618](https://github.com/spareilleux/learn/actions/runs/34903462618) (the exercise solutions, commit `15cde43`) passed on all four jobs at the first push.

## 2026-09-14 — Choices while writing the code

- IX's `train_test_split`, k-means++, GMM start and `StratifiedKFold` draw from Rust's `StdRng`, which Python can't replay. For those, the hand version starts from IX's fitted result and checks that one more step changes nothing (k-means, EM), and the cross-check compares what doesn't depend on the start: sizes, best-of-n inertias, log-likelihoods.
- Lesson 3 tests on every fifth job, a split both languages can make.
- Lesson 3 runs `k = 4` next to `k = 5` for IX's tie-breaking: the tie I first saw disappeared when the test set became every fifth job, and standardized `k = 4` shows one again, on a real test row.
- The first Gaussian mixture comparison didn't match scikit-learn. Tracing it led to the collapsed `complete_s` variances, which became a section of lesson 4 instead of a footnote.

## 2026-09-14 — Where IX differs

Nine places where IX's answer, or its documentation, differs from the textbook or from scikit-learn, each shown by compiled code in the course unless marked. None is filed as an IX issue.

1. **Scaling before splitting.** With `normalize` on, the ML pipeline fits `StandardScaler` (and PCA) on all rows, then splits: the test rows shape the scaling ([`ml_pipeline.rs`, lines 190-203](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-agent/src/ml_pipeline.rs#L190-L203), then [537-538](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-agent/src/ml_pipeline.rs#L537-L538) and [704-705](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-agent/src/ml_pipeline.rs#L704-L705)). Read in the code; the mechanism is shown in [lesson 1](../01-data-and-evaluation/) (first test row 1.440 against 1.042), the tool itself not run.
2. **Integer targets become classes.** `infer_task_type` calls any label vector of non-negative integers with at most 20 distinct values classification ([`preprocessing.rs`, lines 234-254](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-math/src/preprocessing.rs#L234-L254)): the build seconds give `MulticlassClassification { n_classes: 18 }`, and adding 0.5 to one row gives `Regression`. The pipeline uses it when the task is `auto`.
3. **k nearest neighbours ties.** `KNN::predict` takes `max_by_key`, which returns the last maximum: a tie goes to the largest class index ([`knn.rs`, line 53](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-supervised/src/knn.rs#L53)). On the standardized jobs with `k = 4`, test row 27 votes `[2, 0, 2]`: IX says macOS, the hand version and scikit-learn Ubuntu, the true OS; accuracy 0.947 against 0.974.
4. **An empty k-means cluster goes to the origin.** The centroid update starts from zeros and skips clusters without rows ([`kmeans.rs`, lines 137-152](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/kmeans.rs#L137-L152)). `KMeans(3)` on `[5, 5, 9, 9]` gives centroids `[5.0, 9.0, 0.0]`, and `predict([1.0])` returns the empty cluster; scikit-learn gives `[5.0, 9.0, 9.0]` with a warning.
5. **The silhouette of a singleton is 1.** `silhouette_score_exact` in `ix-voicings` sets `a = 0` for a row alone in its cluster, so `s = 1`, where Rousseeuw and scikit-learn use 0 ([`lib.rs`, lines 664-678](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-voicings/src/lib.rs#L664-L678)): 0.9296 against 0.5963 on `[0, 1 | 10]`.
6. **The tutorials' imports don't compile.** `use ix_unsupervised::{KMeans, Clusterer};` fails with `E0432`, because the crate exports modules only ([`lib.rs`, lines 5-14](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/lib.rs#L5-L14)). The same form is in `docs/unsupervised-learning/kmeans.md` (lines 60 and 91), `dbscan.md` (line 50), `pca.md` (lines 63 and 101), `docs/use-cases/fraud-detection.md` (line 43), `gis-spatial-analysis.md` (lines 79, 375, 427), `docs/foundations/rust-for-ml.md` (line 141), and their French versions. The course's doctest checks the first one.
7. **One k-means start.** `KMeans::fit` runs a single k-means++ start, and the `ix_kmeans` MCP tool fixes the seed at 42 ([`handlers.rs`, line 322](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-agent/src/handlers.rs#L322)). On the jobs, seeds 0 to 9 give inertias from 411.23 to 618.02; for `k = 6`, seed 42 gives 223.366 where scikit-learn's best of 50 gives 214.040, with a silhouette of 0.3646 against 0.4400.
8. **The voicings rule doesn't compare.** `ix_voicings::cluster` keeps `k = 5` as soon as its silhouette reaches 0.15, and only tries `k = 3` below that ([`lib.rs`, lines 770-776](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-voicings/src/lib.rs#L770-L776)). On the jobs, it keeps `k = 5` (0.4350) over `k = 3` (0.4997). A design choice rather than an error, but the doc comment calls the threshold one for "accepting the clustering", not for choosing `k`.
9. **Gaussian mixture collapse.** `GMM` floors each variance at `1e-6` ([`gmm.rs`, lines 170-171](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/gmm.rs#L170-L171)) and runs one random start. On the whole-second timings, components collapse on `complete_s`, and the log-likelihood depends on the seed, from −102.666 to 552.879; scikit-learn's best of 10 starts is −102.667. Comparing IX's log-likelihoods picks the most collapsed model.

Differences worth knowing, which I don't count as errors:

- `LogisticRegression` has no regularization and no stopping test: on separable data, its weights grow with the iteration count (lesson 3).
- `ix_optimize::gradient::SGD` is full-batch gradient descent: `minimize` passes it the gradient over all rows.
- `DBSCAN` labels noise `0` and clusters from `1`, as its documentation says; code written for scikit-learn's `-1` merges the noise into a cluster.
- `ix_io::csv_io::read_csv` turns text fields into `NaN` without an error.
- `train_test_split` always shuffles, and takes classification labels as `f64`; there's no stratified or time-ordered option.

## 2026-09-15 — Lessons 5 to 8

- Four lessons in one batch: principal components, ensembles, neural networks, optimization. The course now depends on seven IX crates, having added `ix-ensemble` and `ix-nn` at the same pinned commit, and runs sixteen examples in CI.
- The cross-check grew with them. Lesson 5 is the first where scikit-learn can check IX directly and completely — `PCA` is deterministic, takes no seed, and has a documented sign convention — so every number in that lesson has three independent sources.
- Lesson 6 introduced a 64-bit xorshift generator in the course code. IX draws from `StdRng`, which Python cannot replay; three shifts and three XORs can be replayed exactly, and the numpy check lands on the same 48 rows left out of the same bootstrap. That closes the gap the 2026-09-14 note complained about, for the algorithms the course writes itself.
- Lesson 7 is the first to use finite differences as the oracle rather than scikit-learn. Every claim about what `ix_nn` computes was measured by moving a weight and watching the loss, not derived by reading — which turned out to matter, because two of the three findings are off by a factor nobody would guess from the code.
- Lesson 8 found nothing wrong with `ix_optimize`'s update rules: SGD, Momentum and Adam match the hand versions step for step and land on the same points. The finding there is about `minimize`'s result type, not its arithmetic.

## 2026-09-15 — Where IX differs, continued

Ten more places where IX's answer, or its documentation, differs from the textbook or from scikit-learn, each shown by compiled code in the course. With the nine of 2026-09-14 that makes nineteen. None is filed as an IX issue.

10. **The explained-variance ratio is normalized over the components kept.** `explained_variance_ratio` divides each eigenvalue by the sum of the *kept* eigenvalues ([`pca.rs`, lines 46-57](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/pca.rs#L46-L57)), so the ratios sum to 1 for any `n_components` and the doc comment's "proportion of total variance" holds only when every component is kept. On the standardized jobs, `PCA::new(2)` reports `[0.5635, 0.4365]` where the truth, and scikit-learn, say `[0.3867, 0.2996]` summing to 0.6863. The usual "how many components for 90 %?" question cannot be asked of it.
11. **Power iteration starts from a fixed vector and can return the minor axis.** The start is `(1, …, 1)/√n` ([`pca.rs`, line 107](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/pca.rs#L107)). On a six-point cloud stretched along `(1, -1)`, whose covariance is `[[2.4, -1.6], [-1.6, 2.4]]`, that start *is* the minor eigenvector, so `PCA::new(1)` returns variance 0.8 along `(1, 1)` instead of 4.0 along `(1, -1)`. `PCA::new(2)` is worse: deflation leaves a matrix that sends the start to zero, the `norm < 1e-15` guard fires, and the model ends with the same component twice and a variance of 0. scikit-learn's SVD returns 4.0 and `(0.7071, -0.7071)`. A knife-edge case — it needs exactly equal variances — but nothing in the output says which case you are in.
12. **The variances are unreachable.** `PCA::explained_variance` is a private field, and `explained_variance_ratio()` is normalized as in finding 10, so `save_state()` is the only way to get the eigenvalues out of a fitted model.
13. **A random forest draws its features once per tree, not once per split.** The doc comment promises "random feature subsets (sqrt(n_features) features per split)"; the code draws them before the tree is grown and builds the whole tree from those columns ([`random_forest.rs`, lines 68-84](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-ensemble/src/random_forest.rs#L68-L84)). At the default of three features of five the two agree, both reaching 0.9211 on the test jobs; at `max_features = 1` the hand version, drawing at every split, reaches 0.9474 and IX 0.7632, because fifty one-dimensional trees cannot combine features.
14. **A tie in the forest vote goes to the largest class index.** `predict` takes `max_by`, which keeps the last maximum ([`random_forest.rs`, line 97](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-ensemble/src/random_forest.rs#L97)). Two stumps with seed 6 give probabilities `[0.500, 0.500]`, and IX answers class 1 where scikit-learn and `np.argmax` answer 0. The same shape as finding 3 about `KNN::predict`.
15. **`Dense::backward` divides by the batch size twice.** `grad_output` already carries the `1/n` that `mse_gradient` put there, and `backward` divides by `n` again ([`layer.rs`, lines 40-52](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/layer.rs#L40-L52)). Measured against the central-difference gradient of `mse_loss` on the 65 builds, the ratio is 65.0000 exactly. Training still converges, since every layer divides by the same `n`, but the learning rate you pass is the learning rate divided by the batch size.
16. **`mse_gradient` is not the gradient of `mse_loss` beyond one output column.** `mse_loss` averages over rows and columns, `mse_gradient` divides by the rows only ([`loss.rs`, lines 6-16](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/loss.rs#L6-L16)). Measured for one to four columns, the ratio is 1, 2, 3, 4. Combined with finding 15, a two-output layer on 65 rows moves by the true gradient divided by 32.5.
17. **`Dense::new` takes no seed.** It draws from the thread generator ([`layer.rs`, line 27](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/layer.rs#L27)), so two layers built in the same run already differ and no `Sequential` result can be reproduced or regression-tested. Every other random algorithm in IX takes one — `KMeans`, `RandomForest`, `Dropout`, `transformer::FeedForward`. The `weights` and `bias` fields are public, which is the way out and what the course does.
18. **A `Sequential` of `Dense` layers is one affine map.** `Dense` is the only type implementing the `Layer` trait: `ix-nn` has no activation layer that `Sequential::push` could accept between two affine maps. On exclusive or, two `Dense` layers converge to loss 0.25 — the variance of the targets, the best a constant can do — and predict 0.5 at all four corners, while the same-sized hand network with one sigmoid between its layers reaches 0. After 50 000 epochs the stack still satisfies `f(0,0) + f(1,1) - f(0,1) - f(1,0) = 0` to the last bit: it is not undertrained, it cannot represent the function. The crate's real non-linearities live in `transformer::gelu`, inside `FeedForward`, which works on `Array3` and is not a `Layer`.
19. **`minimize` returns the starting point for a run that diverged.** It tracks the best point it has passed and returns that ([`gradient.rs`, lines 124-165](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-optimize/src/gradient.rs#L124-L165)). Plain descent at rate 0.01 on Rosenbrock runs to NaN on its first few steps; the result reports `best f 24.200000`, which is `f` at the point the caller passed in, with `converged: false` — the same flag a perfectly good run that merely ran out of iterations gets. Neither `best_value` nor `converged` separates the two.

Differences worth knowing, which I don't count as errors:

- `RegressionStump` puts the mean of the residuals in each leaf, where Friedman's recipe and scikit-learn use a Newton step. It is a defensible simplification, and the hand version copies it so the two can be compared; with it, IX and the hand version agree on every one of the 38 test rows at 1, 5, 10, 25 and 50 rounds.
- `GradientBoostedClassifier` has no early stopping and no held-out score. On the jobs it peaks at 0.9474 after five rounds and settles at 0.9211 by twenty-five, and nothing in the API measures that.
- `ix-ensemble` has no out-of-bag score, which bagging gives away for free and scikit-learn exposes as `oob_score=True`.
- `ClosureObjective` never overrides `ObjectiveFunction::gradient`, so wrapping a closure silently buys a measured gradient at two extra evaluations per coordinate per step — 1001 evaluations against 201 for 200 Adam steps in two dimensions. On a smooth objective it costs nothing in accuracy: both runs ended at `1.061e-16`.

## 2026-09-15 — What agreed

Worth recording next to the findings, because the lessons so far have mostly found the opposite:

- `ix_optimize`'s SGD, Momentum and Adam match the hand versions exactly — same step counts (5000, 4129, 2822), same final points, same first step from the same gradient.
- `GradientBoostedClassifier` matches the hand version on every test row at every number of rounds, and numpy reproduces the same accuracies, the same smoothed log priors and the same first-round stumps.
- `PCA`'s five variances match Jacobi's to `1.28e-10` and scikit-learn's to the printed digits; only the ratio and the fixed starting vector are at issue.

## 2026-09-15 — The API map

- The outline promises one lesson per family of algorithms, which will still leave most of the workspace untouched. [`scripts/sync-ix-api-map.mjs`](https://github.com/spareilleux/learn/blob/main/scripts/sync-ix-api-map.mjs) fills the gap from the other side: one `git grep` over the pinned commit, and a generated page per locale listing every `pub` declaration under `crates/*/src/`, crate by crate and module by module. 80 crates, 3398 declarations, of which 2307 are functions.
- It is generated, never hand-written, and `npm run sync:ix-api-map` rebuilds it — so it cannot drift from the pin, which is what usually rots a page like this. The revision is read out of the course's `Cargo.toml` rather than written twice.
- It counts what the source says, not what a caller can reach: `pub` inside a private module is listed and is invisible from outside the crate. Finding 12 — a private field where the ratio is unusable — is exactly the kind of thing the page cannot tell you, and the lessons can.

## 2026-09-16 — A negative zero on macOS

- The first CI run of the lesson 5 to 8 code was red on `macos-latest` alone, in `l07_networks`: the exclusive-or network printed `predictions [-0.0000, 1.0000, 1.0000, -0.0000]` where Windows and Linux print `0.0000` at those two corners. Run [35039180659](https://github.com/spareilleux/learn/actions/runs/35039180659); the other three jobs passed, and so did the fifteen other examples.
- At the two zero corners the network lands below the fourth decimal, and only the *sign* differs — the same additions taken in a different order on ARM. `-0.0` and `0.0` are the same number and compare equal, so the sign is not a result, and no lesson claim changes.
- [`fmt_vec`](https://github.com/spareilleux/learn/blob/be41ba8/code/machine-learning-ix/src/lib.rs#L52-L70) exists so that "the outputs don't depend on how each OS prints the last digits", which makes it where the fix belongs: anything that rounds to zero now prints `0.0000`, never `-0.0000`, and every other sign survives. A unit test pins both halves. No `expected/` file changed, so no lesson had to be requoted.
- The 2026-09-14 note — fixed decimals, so the outputs are identical on the three systems — was right about the remedy and one case short of complete. Fixed decimals do not settle the sign of a zero, and a course written on one machine cannot find that out.

## To verify

- The `ix_ml_pipeline` tool end to end: the scaling order of finding 1, the task inference of finding 2 on a CSV file, and the `All rows contain NaN values` error for a file with a text column. All three are read in the code, not run.
- `LinearRegression::fit` on two identical features: whether `ix_math::linalg::inverse` returns an error, and `fit` panics, or returns a wrong answer.
- A k-means cluster that empties in the middle of a real run, rather than at the start as in finding 4.
- `ix_voicings::cluster` on GA's voicings: the export needs GA's `FretboardVoicingsCLI`, which the course doesn't build.
- The cause of the 48-second build of `95a3830`.
- Whether findings 1 to 9 are already known upstream: I haven't searched IX's issues.
- The examples on Linux ARM runners: CI covers `ubuntu-latest` (x64), `windows-latest` and `macos-latest` (ARM) only.
- Whether `PCA` ever returns unsorted variances on real data, rather than on the constructed cloud of finding 11.
- Whether a `Sequential` deeper than two `Dense` layers is used anywhere in IX, where finding 18 would bite.
- `ix-autograd`: its tape is the crate that should make finding 15 unnecessary, and lesson 12 will measure it.
- Whether findings 10 to 19 are already known upstream: I still have not searched IX issues.
- The API map counts `pub` declarations, not reachable ones; how far apart the two numbers are is unmeasured.
- The values printed by a direct `println!("{:.6}")` rather than through `fmt_vec` — lesson 8's `intercept -0.000000` is one — carry the same signed-zero hazard and are not normalized. That one agreed on the three systems in run 35039180659; the others have not been enumerated.