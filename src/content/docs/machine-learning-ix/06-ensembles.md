---
title: "6. Ensembles: bagging, random forests and gradient boosting"
description: "Fifty shallow trees voting instead of one deep tree — bootstrap samples and the out-of-bag score by hand, a random forest that draws its features at every split against ix_ensemble's one draw per tree, the tie that goes to the largest class index, and gradient boosting on stumps reproduced to the last digit."
sidebar:
  order: 6
---

The decision tree of lesson 3 reached 0.895 on the test jobs. Growing it deeper fits the training rows better and the test rows worse. **Ensembles** take the other road: train many weak models and combine them. Two recipes dominate, and they disagree about almost everything.

**Bagging** trains each model on a different random sample of the rows and averages their votes. The models are independent, so their errors partly cancel; the ensemble is more stable than any of its members. **Boosting** trains models one after another, each one fixing what the ones before it got wrong. The models are entirely dependent, and the ensemble is sharper but easier to overfit.

| | ML.NET | Tribuo | scikit-learn | IX |
|---|---|---|---|---|
| Random forest | [`FastForest`](https://learn.microsoft.com/dotnet/api/microsoft.ml.trainers.fasttree.fastforestbinarytrainer) | [`RandomForestTrainer`](https://tribuo.org/learn/4.3/javadoc/org/tribuo/common/tree/RandomForestTrainer.html) | [`RandomForestClassifier`](https://scikit-learn.org/stable/modules/generated/sklearn.ensemble.RandomForestClassifier.html) | `ix_ensemble::random_forest::RandomForest` |
| Boosting | [`FastTree`](https://learn.microsoft.com/dotnet/api/microsoft.ml.trainers.fasttree.fasttreebinarytrainer), [`LightGbm`](https://learn.microsoft.com/dotnet/api/microsoft.ml.lightgbmextensions) | [`AdaBoostTrainer`](https://tribuo.org/learn/4.3/javadoc/org/tribuo/classification/ensemble/AdaBoostTrainer.html) | [`GradientBoostingClassifier`](https://scikit-learn.org/stable/modules/generated/sklearn.ensemble.GradientBoostingClassifier.html) | `ix_ensemble::gradient_boosting::GradientBoostedClassifier` |
| Out-of-bag score | — | — | `oob_score=True` | — |
| Features per split | configurable | configurable | `max_features`, redrawn at each split | `max_features`, drawn once per tree |

The program is [`examples/l06_ensembles.rs`](https://github.com/spareilleux/learn/blob/37b8830/code/machine-learning-ix/examples/l06_ensembles.rs), on the split of lesson 3: every fifth job tests, the other 148 train.

## The bootstrap

A **bootstrap sample** of `n` rows is `n` rows drawn *with replacement*. Some rows arrive twice, some never:

```text
== one tree, depth 4: test accuracy 0.8947
a bootstrap of 148 rows drew 100 distinct rows and left 48 out (0.324 of them); 1/e = 0.368
```

A given row escapes one draw with probability `1 - 1/n`, and all `n` draws with probability `(1 - 1/n)ⁿ`, which tends to `1/e ≈ 0.368` as `n` grows. About a third of the rows never reach a given tree — and those rows are a free test set for it. Averaged over the forest, that is the **out-of-bag score**: every row judged only by the trees that never saw it, with no data held back.

IX draws its samples from `rand::rngs::StdRng`, which Python cannot replay. The hand version uses a 64-bit xorshift generator instead — three shifts and three XORs ([`src/ensemble.rs`, lines 9-31](https://github.com/spareilleux/learn/blob/37b8830/code/machine-learning-ix/src/ensemble.rs#L9-L31)) — so the cross-check reproduces every draw and lands on the same 48 rows:

```rust
pub fn next_u64(&mut self) -> u64 {
    let mut x = self.0;
    x ^= x << 13;
    x ^= x >> 7;
    x ^= x << 17;
    self.0 = x;
    x
}
```

## Bagging, then a forest

Bagging alone gives fifty trees that are still very much alike: the strongest split — `checkout_s`, which separates Windows from the rest — is the first split of nearly every one of them. Breiman's **random forest** adds a second source of disagreement: at each node, only a random handful of the features may be split on, so weaker features get their turn.

```text
== fifty trees of depth 4, by hand
  bagging, 5 of 5 features: test accuracy 0.8947, out-of-bag accuracy 0.9662
  forest, 3 of 5          : test accuracy 0.9211, out-of-bag accuracy 0.9459
```

Bagging matched the single tree; restricting the features to three of five gained one test job. IX, with its default of `ceil(√5) = 3` features and a different generator, lands on the same score:

```text
== ix_ensemble::random_forest::RandomForest::new(50, 4), seed 42
  trees 50, max_features default None -> ceil(sqrt(5)) = 3
  test accuracy 0.9211
```

## Once per tree, or once per split

The two forests agree here, but they are not the same algorithm. `RandomForest`'s doc comment promises "random feature subsets (sqrt(n_features) features per split)"; the code draws the subset once, before the tree is grown, and builds the whole tree from those columns only ([`random_forest.rs`, lines 68-84](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-ensemble/src/random_forest.rs#L68-L84)):

```rust
// Random feature subset
let mut all_features: Vec<usize> = (0..p).collect();
for i in 0..max_features {
    let j = rng.random_range(i..p);
    all_features.swap(i, j);
}
let feature_indices: Vec<usize> = all_features[..max_features].to_vec();
// … the tree is then fitted on sub_x, which has only those columns
```

With three features of five the difference is small. Push `max_features` to 1 and it is not:

```text
== with a single feature
  hand, one feature drawn at every split: 0.9474
  ix, one feature drawn once per tree:    0.7632
```

Drawing one feature *per split* still builds a real tree: the root may split on `checkout_s`, its children on `queue_s`, their children on something else, and the tree combines all five features down any path. Drawing one feature *per tree* gives fifty one-dimensional models, each able to threshold a single timing, and the vote of fifty stumps-in-disguise is 0.763. The hand version, with the same nominal setting, beats the default forest.

The number to remember is not 0.7632 but this: `max_features` means something different in `ix-ensemble` than it does in scikit-learn, Tribuo or Breiman's paper, and the doc comment describes the other one.

## The vote, and what happens on a tie

`predict` takes the class with the largest averaged probability, through `max_by` ([`random_forest.rs`, line 97](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-ensemble/src/random_forest.rs#L97)). `Iterator::max_by` returns the **last** maximum, so an exact tie goes to the largest class index. Two stumps that disagree make one:

```text
== a tie between two classes
  two stumps, seed 6: probabilities [0.500, 0.500] -> ix predicts class 1
```

scikit-learn, the hand forest and `np.argmax` all take the smallest index instead. This is the same behaviour lesson 3 found in `KNN::predict`, and it comes from the same line of Rust: in IX, a tie is resolved by class order, and the classes are ordered by whatever the caller put in the label vector.

Adding trees does not change the test score here — the three jobs it gets wrong are wrong for every size of forest — but it does steady the out-of-bag estimate:

```text
== by number of trees (hand forest, 3 of 5)
    1 trees: test 0.9211, out-of-bag 0.9375
    2 trees: test 0.9211, out-of-bag 0.9438
    5 trees: test 0.9211, out-of-bag 0.9323
   10 trees: test 0.9211, out-of-bag 0.9388
   25 trees: test 0.9211, out-of-bag 0.9527
   50 trees: test 0.9211, out-of-bag 0.9459
  100 trees: test 0.9211, out-of-bag 0.9527
```

More trees never hurt a bagged ensemble — that is its main practical virtue — but they stop helping, and here they stopped before the first one finished.

## Boosting: fitting what is left over

Gradient boosting starts from a constant and adds one small correction at a time. For classification with `K` classes it keeps `K` running scores per row. The starting scores are the smoothed log priors; at each round, for each class, it fits a **stump** — a tree of depth 1 — to the *residual* `1{y = c} - p(c)`, the amount by which the model currently under-predicts that class, and adds a shrunken copy of the stump to the score.

The residual is the negative gradient of the multiclass log loss with respect to the score, which is where the name comes from: each round is one step of gradient descent, taken in the space of functions rather than parameters.

Finding the stump means finding the split that best separates the residuals, which is the split that minimizes the squared error around the two leaf means. Since the total sum of squares does not depend on where the split falls, minimizing it is the same as *maximizing* `n_L·mean_L² + n_R·mean_R²`, and that can be swept in one pass per feature ([`src/ensemble.rs`, lines 255-265](https://github.com/spareilleux/learn/blob/37b8830/code/machine-learning-ix/src/ensemble.rs#L255-L265)):

```rust
let left_mean = left_sum / left_n as f64;
let right_mean = (total - left_sum) / right_n as f64;
let score = left_n as f64 * left_mean * left_mean + right_n as f64 * right_mean * right_mean;
```

The hand version follows `ix_ensemble` step for step, including the leaf value — the plain mean of the residuals, where Friedman's original recipe and scikit-learn use a Newton step. The two implementations then agree exactly:

```text
== gradient boosting on stumps, learning rate 0.3
   1 rounds: hand 0.6842, ix 0.6842, rows where they differ 0
   5 rounds: hand 0.9474, ix 0.9474, rows where they differ 0
  10 rounds: hand 0.9474, ix 0.9474, rows where they differ 0
  25 rounds: hand 0.9211, ix 0.9211, rows where they differ 0
  50 rounds: hand 0.9211, ix 0.9211, rows where they differ 0
```

Not one row out of 38 differs, at any number of rounds, and the numpy version in the cross-check reproduces the same accuracies. Boosting is the one algorithm in this course where IX, the hand version and a third implementation agree to the last digit — which is worth saying plainly, because the lessons so far have mostly found the opposite.

Five rounds beat fifty. The ensemble peaks at 0.9474 and settles back to 0.9211: with no held-out set and no early stopping, `n_estimators` is the parameter that decides whether boosting helps, and nothing in the API measures it for you. Bagging has the opposite character — its extra trees are harmless — which is the practical reason to reach for a forest first.

The first round is readable on its own:

```text
start, the smoothed log priors: [-0.4529, -1.7592, -1.6500]
  round 1, class ubuntu : split checkout_s <= 1.5, leaves 0.3074 and -0.4358
  round 1, class windows: split checkout_s <= 4.0, leaves -0.1722 and 0.8278
  round 1, class macos  : split queue_s <= 5.5, leaves -0.1671 and 0.7008
  probabilities of the first test job after one round: [0.6682, 0.1567, 0.1751]
```

`exp(-0.4529) = 0.636`: 95 of the 148 training jobs ran on Ubuntu, smoothed by adding one to each count. The model starts by guessing the base rates. Then each class gets the one question that most reduces its own residual — for Windows, "did the checkout take more than 4 seconds?", for macOS, "did the job wait more than 5.5 seconds in the queue?" — and the three answers, softmaxed, already put the first test job on Ubuntu with probability 0.67.

## Key takeaways

- A bootstrap sample of `n` rows leaves out about a third of them, `1/e` as `n` grows, and those rows give each tree a free out-of-bag test.
- A random forest adds random feature subsets to bagging. scikit-learn, Tribuo and Breiman redraw them at every split; `ix_ensemble` draws them once per tree, which with a single feature drops the test accuracy from 0.9474 to 0.7632.
- IX's forest resolves an exact tie in favour of the largest class index, where scikit-learn takes the smallest.
- More trees never hurt a bagged ensemble, but they stop helping: here the test score did not move after the first tree.
- Gradient boosting fits each stump to the residuals of the log loss. The hand version, IX and numpy agree to the last digit, and the score peaked at 5 rounds, so the number of rounds needs a held-out check.

## Exercises

1. Does the out-of-bag score follow the test score as the trees grow deeper?
2. Where do the two forests disagree on the test set, and which rows does the forest still get wrong?
3. Which operating systems does the forest confuse?

<details>
<summary>Solutions</summary>

They are in [`examples/l06_exercises.rs`](https://github.com/spareilleux/learn/blob/37b8830/code/machine-learning-ix/examples/l06_exercises.rs).

**1.** It follows the *shape* but not the level:

```text
== depth against the two scores (hand forest, 50 trees, 3 of 5 features)
  depth 1: out-of-bag 0.7838, test 0.9211
  depth 2: out-of-bag 0.9730, test 0.9211
  depth 3: out-of-bag 0.9730, test 0.9211
  depth 4: out-of-bag 0.9459, test 0.9211
  depth 5: out-of-bag 0.9662, test 0.9211
  depth 6: out-of-bag 0.9595, test 0.9211
  depth 7: out-of-bag 0.9595, test 0.9211
  depth 8: out-of-bag 0.9595, test 0.9211
```

Depth 1 is clearly too shallow, and both scores say so. After that the out-of-bag score wanders between 0.946 and 0.973 while the test score does not move at all. With 148 training rows, an out-of-bag estimate rests on about 54 of them per tree, and differences of 0.02 are noise. It is a useful alarm for "this model is badly wrong", not a way to choose between two reasonable depths.

**2.** They never disagree, and both are wrong on the same three jobs:

```text
== the two forests on the 38 test jobs
  hand 0.9211, ix 0.9211, rows where they disagree: []
  the rows the hand forest still gets wrong:
    test job 12, workflow Deploy to GitHub Pages         truly ubuntu  predicted macos
    test job 27, workflow Rust course examples           truly ubuntu  predicted macos
    test job 29, workflow GHA 05: caches and artifacts   truly ubuntu  predicted windows
```

All three are Ubuntu jobs that behaved like something else — a slow queue or a slow checkout on a runner that is usually quick. Nothing in five timings distinguishes a slow Ubuntu job from a normal macOS one, so no amount of trees will recover them; the ceiling here is the data, not the model.

**3.** Every error is an Ubuntu job called something else:

```text
== confusion of the hand forest, rows true, columns predicted
  order ["ubuntu", "windows", "macos"]
  ubuntu  [23, 1, 2]
  windows [0, 9, 0]
  macos   [0, 0, 3]
```

Windows and macOS are recognized perfectly. This is what an imbalanced training set does: with 121 Ubuntu jobs against 34 and 31, the majority class absorbs the uncertainty, and the errors all fall on it.

</details>

## Sources

- Breiman, *[Random Forests](https://link.springer.com/article/10.1023/A:1010933404324)*, 2001, for bagging, the feature draw at each split and the out-of-bag estimate
- Friedman, *[Greedy Function Approximation: A Gradient Boosting Machine](https://projecteuclid.org/euclid.aos/1013203451)*, 2001
- James, Witten, Hastie, Tibshirani, Taylor, *[An Introduction to Statistical Learning](https://www.statlearning.com/)*, chapter 8
- [scikit-learn: ensemble methods](https://scikit-learn.org/stable/modules/ensemble.html)
- IX at `490c395`: [`ix-ensemble/src/random_forest.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-ensemble/src/random_forest.rs), [`ix-ensemble/src/gradient_boosting.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-ensemble/src/gradient_boosting.rs)
