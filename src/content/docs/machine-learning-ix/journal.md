---
title: Journal
description: Dated progress notes — IX pinned at 490c395, the data extracted from this site's CI, the CI of the course code, nine places where IX differs from the textbook or scikit-learn, and items to verify.
sidebar:
  order: 99
---

## Progress

- [x] IX cloned and pinned at commit `490c395`; the course code depends on five of its crates
- [x] Data: `builds.csv` and `jobs.csv`, extracted from the CI history and the Git history of this repository
- [x] CI: formatting, clippy, unit tests and every example compared with `expected/` on three OSes, and a numpy and scikit-learn cross-check on Linux
- [x] Lesson 1: data, features and evaluation
- [x] Lesson 2: linear regression and gradient descent
- [x] Lesson 3: classification
- [x] Lesson 4: clustering
- [ ] French and Spanish translations

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

## To verify

- The `ix_ml_pipeline` tool end to end: the scaling order of finding 1, the task inference of finding 2 on a CSV file, and the `All rows contain NaN values` error for a file with a text column. All three are read in the code, not run.
- `LinearRegression::fit` on two identical features: whether `ix_math::linalg::inverse` returns an error, and `fit` panics, or returns a wrong answer.
- A k-means cluster that empties in the middle of a real run, rather than at the start as in finding 4.
- `ix_voicings::cluster` on GA's voicings: the export needs GA's `FretboardVoicingsCLI`, which the course doesn't build.
- The cause of the 48-second build of `95a3830`.
- Whether findings 1 to 9 are already known upstream: I haven't searched IX's issues.
- The examples on Linux ARM runners: CI covers `ubuntu-latest` (x64), `windows-latest` and `macos-latest` (ARM) only.
