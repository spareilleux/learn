---
title: "3. Classification: logistic regression, k nearest neighbours, decision trees"
description: Which OS ran a CI job, from the timings of its steps — logistic regression by gradient descent, k nearest neighbours with and without scaling, a CART decision tree with Gini impurity, and stratified cross-validation, each written by hand and compared with ix-supervised and scikit-learn, including a tie that IX breaks the other way.
sidebar:
  order: 3
---

Regression predicts a number; **classification** predicts a class. This lesson predicts the OS of a CI job, Ubuntu, Windows or macOS, from five timings in seconds: `queue_s` (waiting for a runner), `setup_s` (the *Set up job* step), `checkout_s` and `post_checkout_s` (the checkout and its cleanup), and `complete_s` (the *Complete job* step). Lesson 1 gave the baseline: always Ubuntu, 65% accuracy, macro F1 0.263.

Three classifiers, three ideas of what "learning" means: a weighted sum pushed through a curve, the nearest examples, and a list of questions.

| | ML.NET | Tribuo | scikit-learn | IX |
|---|---|---|---|---|
| Logistic regression | [`LbfgsLogisticRegression`](https://learn.microsoft.com/dotnet/api/microsoft.ml.standardtrainerscatalog.lbfgslogisticregression) | [`LogisticRegressionTrainer`](https://tribuo.org/learn/4.3/javadoc/org/tribuo/classification/sgd/linear/LogisticRegressionTrainer.html) | [`LogisticRegression`](https://scikit-learn.org/stable/modules/generated/sklearn.linear_model.LogisticRegression.html) | `ix_supervised::logistic_regression` |
| k nearest neighbours | — | [`KNNTrainer`](https://tribuo.org/learn/4.3/javadoc/org/tribuo/common/nearest/KNNTrainer.html) | [`KNeighborsClassifier`](https://scikit-learn.org/stable/modules/generated/sklearn.neighbors.KNeighborsClassifier.html) | `ix_supervised::knn::KNN` |
| Decision tree | boosted trees: [`FastTree`](https://learn.microsoft.com/dotnet/api/microsoft.ml.trainers.fasttree.fasttreebinarytrainer) | [`CARTClassificationTrainer`](https://tribuo.org/learn/4.3/javadoc/org/tribuo/classification/dtree/CARTClassificationTrainer.html) | [`DecisionTreeClassifier`](https://scikit-learn.org/stable/modules/tree.html) | `ix_supervised::decision_tree::DecisionTree` |
| Cross-validation | [`CrossValidate`](https://learn.microsoft.com/dotnet/api/microsoft.ml.multiclassclassificationcatalog.crossvalidate) | [`CrossValidation`](https://tribuo.org/learn/4.3/javadoc/org/tribuo/evaluation/CrossValidation.html) | [`cross_val_score`](https://scikit-learn.org/stable/modules/generated/sklearn.model_selection.cross_val_score.html) | `ix_supervised::validation::cross_val_score` |

In IX, all three implement the [`Classifier`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-supervised/src/traits.rs#L11-L16) trait: `fit(&x, &y)`, `predict(&x)` and `predict_proba(&x)`, with labels as `Array1<usize>`. The program is [`examples/l03_classification.rs`](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/examples/l03_classification.rs). Every fifth job is a test job, the others train: a rule the Python cross-check can repeat, which IX's random split can't give it.

```text
== split: train 148 [95, 25, 28], test 38 [26, 9, 3] (ubuntu, windows, macos)
```

## Logistic regression

A line gives any number; a class needs a probability between 0 and 1. Logistic regression computes the same weighted sum as lesson 2, `z = w·x + b`, then squeezes it with the **sigmoid** `σ(z) = 1 / (1 + e⁻ᶻ)`: `z = 0` gives 0.5, a large positive `z` gives almost 1. It answers a yes/no question; here, *is this job running on Windows?*, from `checkout_s` and `post_checkout_s`.

The loss is no longer the squared error but the **log loss**, which punishes a confident wrong answer without limit. With `pᵢ = σ(w·xᵢ + b)` and `yᵢ` equal to 0 or 1:

```text
L(w, b) = -1/n Σ [ yᵢ·ln(pᵢ) + (1 - yᵢ)·ln(1 - pᵢ) ]
∂L/∂w = 1/n Σ (pᵢ - yᵢ)·xᵢ        ∂L/∂b = 1/n Σ (pᵢ - yᵢ)
```

The gradient has the same shape as the one of lesson 2: prediction minus truth, times the input. There's no closed form; [`src/classify.rs`, lines 9-31](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/src/classify.rs#L9-L31) takes a fixed number of gradient steps from zero:

```rust
for _ in 0..iterations {
    let mut dw = Array1::<f64>::zeros(p);
    let mut db = 0.0;
    for i in 0..n {
        let error = sigmoid(x.row(i).dot(&w) + b) - y[i] as f64;
        dw.scaled_add(error / n as f64, &x.row(i));
        db += error / n as f64;
    }
    w.scaled_add(-learning_rate, &dw);
    b -= learning_rate * db;
}
```

[`LogisticRegression::fit`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-supervised/src/logistic_regression.rs#L44-L68) does the same with matrix products, and `predict` answers 1 when the probability is at least 0.5:

```text
== logistic regression, windows or not, features ["checkout_s", "post_checkout_s"]
lr 0.01, 1000 iterations: hand w [0.2924, 0.4670] b -1.9327 | ix w [0.2924, 0.4670] b -1.9327 | same to 1e-9: true
  test: accuracy 1.000, windows precision 1.000, recall 1.000
  P(windows | checkout 1 s, post 0.5 s) = 0.197  P(windows | checkout 3 s, post 1.5 s) = 0.412  P(windows | checkout 6 s, post 3 s) = 0.773
lr 0.1, 20000 iterations: hand w [2.4770, 1.8829] b -12.3652 | ix w [2.4770, 1.8829] b -12.3652 | same to 1e-9: true
  test: accuracy 0.974, windows precision 0.900, recall 1.000
  P(windows | checkout 1 s, post 0.5 s) = 0.000  P(windows | checkout 3 s, post 1.5 s) = 0.108  P(windows | checkout 6 s, post 3 s) = 1.000
```

Same numbers by hand and in IX, but which model is *the* logistic regression of this data? In the training rows, the Windows jobs are exactly the jobs with a checkout longer than 4 seconds (the decision tree below finds that rule). On separable data the log loss has no minimum: it keeps falling as the weights grow, and the probabilities go to 0 and 1. IX has no stopping test and no penalty, so the answer is whatever the iteration count gives. The two runs agree on almost every test job, but not on how sure they are: a job with a 3-second checkout is 41% Windows for one, 11% for the other.

Other libraries add a penalty on the size of the weights, **regularization**, which gives the loss a single minimum. scikit-learn's default, `C=1`, finds `w [2.0809, 0.9997] b -9.8885` in the cross-check, and a nearly unpenalized `C=1e6` finds `[6.5664, 2.9888] b -30.3265`; both have a test accuracy of 0.974. ML.NET's `LbfgsLogisticRegression` has penalties by default too: `l1Regularization = 1` and `l2Regularization = 1`.

## k nearest neighbours

The simplest classifier learns nothing: to classify a job, find the `k` training jobs whose timings are closest, and take the class most of them have. "Closest" is the Euclidean distance, `√Σ (aⱼ - bⱼ)²` over the five features ([`src/classify.rs`, lines 41-68](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/src/classify.rs#L41-L68)):

```rust
let mut near: Vec<(f64, usize)> = x_train
    .rows()
    .into_iter()
    .map(|t| distance(row, t))
    .zip(y_train.iter().copied())
    .collect();
// A stable sort keeps equal distances in training order
near.sort_by(|a, b| a.0.total_cmp(&b.0));
let mut votes = vec![0; classes];
for &(_, class) in &near[..k] {
    votes[class] += 1;
}
let best = *votes.iter().max().unwrap();
votes.iter().position(|&v| v == best).unwrap()
```

Distances add seconds of queueing to seconds of checkout, so the features with the largest spread decide. The program runs `k = 4` and `k = 5` on the raw timings, then on timings standardized with the training rows, as in lesson 1:

```text
== k nearest neighbours, features ["queue_s", "setup_s", "checkout_s", "post_checkout_s", "complete_s"]
raw          k = 4: accuracy hand 0.921, ix 0.921, test rows where they differ: []
raw          k = 5: accuracy hand 0.921, ix 0.921, test rows where they differ: []
standardized k = 4: accuracy hand 0.974, ix 0.947, test rows where they differ: [27]
  test row 27 (jobs.csv row 135, from 0): votes [2, 0, 2] -> hand ubuntu, ix macos, true ubuntu
standardized k = 5: accuracy hand 0.974, ix 0.974, test rows where they differ: []
```

Standardizing lifts the accuracy from 92% to 97%. With `k = 4`, one test job has two Ubuntu neighbours and two macOS ones: a tie. The hand version gives the tie to the first class, Ubuntu, and so does scikit-learn (accuracy 0.974 in the cross-check). [`KNN::predict`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-supervised/src/knn.rs#L34-L55) gives it to macOS:

```rust
votes.iter().enumerate().max_by_key(|(_, &v)| v).unwrap().0
```

[`Iterator::max_by_key`](https://doc.rust-lang.org/std/iter/trait.Iterator.html#method.max_by_key) returns the **last** of several equal maximums, so IX breaks every tie toward the largest class index. Neither rule is more correct, but the result then depends on the order of the classes, and differs from scikit-learn's. An odd `k` avoids ties between two classes, not between three: `k = 5` can vote 2, 2, 1.

ML.NET has no k nearest neighbours trainer in its [list of trainers](https://learn.microsoft.com/dotnet/machine-learning/resources/tasks).

## Decision trees

A decision tree asks a question about one feature at each node, `checkout_s <= 4?`, and sends the job left or right until it reaches a leaf, which holds a class. Growing it is greedy: at each node, try every feature and every threshold halfway between two consecutive values, and keep the question that makes the two groups purest.

Purity is measured by **Gini impurity**, the probability that two jobs drawn at random from the group (with replacement) have different classes. With `pₖ` the share of class `k`:

```text
Gini = 1 - Σ pₖ²                 [10, 0, 0] → 0        [5, 5, 0] → 0.5
gain = Gini(parent) - (nₗ·Gini(left) + nᵣ·Gini(right)) / n
```

The hand version is [`src/classify.rs`, lines 105-160](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/src/classify.rs#L105-L160); IX's is [`best_split`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-supervised/src/decision_tree.rs#L177-L240), called by `build_tree` until the depth limit, fewer than `min_samples_split` rows (2 by default), or a pure node ([line 268](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-supervised/src/decision_tree.rs#L268)). Both keep the first split with the largest gain, and both split `<=` to the left. The program prints the hand tree, then IX's saved nodes:

```text
== decision tree, max depth 3
checkout_s <= 4
  queue_s <= 5.5
    queue_s <= 4.5
      -> ubuntu [89, 0, 0]
    queue_s > 4.5
      -> ubuntu [5, 0, 3]
  queue_s > 5.5
    checkout_s <= 1.5
      -> macos [1, 0, 4]
    checkout_s > 1.5
      -> macos [0, 0, 21]
checkout_s > 4
  -> windows [0, 25, 0]
ix nodes, pre-order: [{"Split":{"feature":2,"threshold":4.0}},{"Split":{"feature":0,"threshold":5.5}},{"Split":{"feature":0,"threshold":4.5}},{"Leaf":{"class":0,"class_counts":[89.0,0.0,0.0]}},{"Leaf":{"class":0,"class_counts":[5.0,0.0,3.0]}},{"Split":{"feature":2,"threshold":1.5}},{"Leaf":{"class":2,"class_counts":[1.0,0.0,4.0]}},{"Leaf":{"class":2,"class_counts":[0.0,0.0,21.0]}},{"Leaf":{"class":1,"class_counts":[0.0,25.0,0.0]}}]
test accuracy hand 0.921, ix 0.921, same predictions: true
confusion matrix (rows = true, columns = predicted):
[[23, 1, 2],
 [0, 9, 0],
 [0, 0, 3]]
ubuntu   precision 1.000 recall 0.885 f1 0.939
windows  precision 0.900 recall 1.000 f1 0.947
macos    precision 0.600 recall 1.000 f1 0.750
```

The same tree three times: by hand, in IX, and in scikit-learn's `export_text` in the cross-check. It reads like a rule you could have written: a checkout longer than 4 seconds is Windows; otherwise, more than 5.5 seconds in the queue is macOS. The tree finds every Windows and macOS test job, and mistakes 3 of 26 Ubuntu jobs for something else: by its own rules, one had a checkout longer than 4 seconds, and two waited more than 5.5 seconds in the queue.

A tree is the only model of the three that explains itself. Its weakness is the other side of that: grown deep enough, it asks questions until every training job is in a pure leaf, including the accidents of this sample.

## Cross-validation

38 test jobs make a noisy score: one job is 2.6 points of accuracy. **k-fold cross-validation** uses every row for testing once: split the rows into `k` folds, train on `k - 1`, test on the last, and repeat for each fold. [`cross_val_score`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-supervised/src/validation.rs#L300-L329) takes a closure that builds a new model for each fold, and uses `StratifiedKFold` (exercise 2 of lesson 1), so each fold keeps the share of each OS:

```rust
cross_val_score(x, &jobs.os, || DecisionTree::new(3), 5, 42)
```

```text
== cross_val_score, 5 stratified folds, seed 42
knn k=5, raw           folds [0.923, 0.919, 0.973, 1.000, 1.000] mean 0.963
decision tree depth 3  folds [0.923, 0.919, 0.973, 1.000, 0.944] mean 0.952
decision tree depth 10 folds [0.923, 0.892, 0.973, 1.000, 0.917] mean 0.941
```

The deeper tree scores lower: it learns rules from the training folds that don't hold on the test fold, which is **overfitting**. The folds vary from 0.89 to 1.00, more than the models differ from each other: on 186 jobs, a difference of one point between two models means little.

`cross_val_score` takes a model, not a pipeline: a scaler fitted inside each fold, as lesson 1 requires, can't be passed to it. Exercise 2 shows what that costs.

## Key takeaways

- Logistic regression is a line through a sigmoid, trained by gradient descent on the log loss. IX's has no regularization and no stopping test: on nearly separable data, its weights and probabilities depend on the number of iterations.
- k nearest neighbours needs features on the same scale. IX breaks voting ties toward the largest class index, scikit-learn toward the smallest.
- A decision tree picks, at each node, the threshold with the largest drop in Gini impurity. IX, the hand version and scikit-learn grow the same tree on this data.
- Cross-validation gives a score per fold: read their spread before comparing two models.

## Exercises

The solutions are in [`examples/l03_exercises.rs`](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/examples/l03_exercises.rs), and their output in `expected/l03_exercises.txt`.

1. Train IX's logistic regression to answer *macOS or not* from `queue_s` and `checkout_s`, standardized with the training rows (learning rate 0.1, 5,000 iterations). The model predicts macOS when the probability is at least 0.5: compute the precision, recall and F1 for macOS with thresholds 0.3, 0.5, 0.7 and 0.9 instead, and IX's `auc_score`.

<details>
<summary>Solution</summary>

[Lines 18-47](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/examples/l03_exercises.rs#L18-L47):

```rust
let p_mac = model.predict_proba(&x_test).column(1).to_owned();
for threshold in [0.3, 0.5, 0.7, 0.9] {
    let predicted: Array1<usize> = p_mac.mapv(|p| usize::from(p >= threshold));
    let (p, r, f) = precision_recall_f1(&confusion(&y_test, &predicted, 2), 1);
    // …
}
println!("AUC {:.3}", auc_score(&y_test, &p_mac));
```

```text
== exercise 1
weights [4.1125, -0.6938] bias -2.8674
threshold 0.3: macos precision 0.600, recall 1.000, f1 0.750, predicted macos 5
threshold 0.5: macos precision 0.600, recall 1.000, f1 0.750, predicted macos 5
threshold 0.7: macos precision 0.750, recall 1.000, f1 0.857, predicted macos 4
threshold 0.9: macos precision 0.750, recall 1.000, f1 0.857, predicted macos 4
AUC 1.000
```

A higher threshold trades recall for precision; here, it removes one wrong macOS answer without losing a right one. The **AUC**, the area under the ROC curve ([`metrics.rs`, lines 480-483](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-supervised/src/metrics.rs#L480-L483)), is the probability that a random macOS job gets a higher score than a random other job, over all thresholds at once. 1.000 says the three macOS test jobs score above every other job: a threshold between them and the fourth job, somewhere above 0.9, would be perfect. AUC judges the ranking; the threshold is a separate choice, made on how much a false alarm costs compared with a miss. With only 3 macOS test jobs, none of these numbers is precise.

</details>

2. Choose `k` for k nearest neighbours: run `cross_val_score` with 5 folds for `k` from 1 to 15, on the five features standardized with the statistics of **all** rows, and print the best `k`.

<details>
<summary>Solution</summary>

[Lines 49-66](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/examples/l03_exercises.rs#L49-L66):

```rust
let z = Scaler::fit(&jobs.features).transform(&jobs.features);
let mut best = (0.0, 0);
for k in 1..=15 {
    let scores = cross_val_score(&z, &jobs.os, || KNN::new(k), 5, 42);
    let mean = scores.iter().sum::<f64>() / 5.0;
    println!("k {k:2}: mean accuracy {mean:.3}");
    if mean > best.0 {
        best = (mean, k);
    }
}
```

```text
== exercise 2
k  1: mean accuracy 0.974
k  2: mean accuracy 0.957
k  3: mean accuracy 0.968
k  4: mean accuracy 0.974
k  5: mean accuracy 0.963
k  6: mean accuracy 0.963
k  7: mean accuracy 0.963
k  8: mean accuracy 0.968
k  9: mean accuracy 0.963
k 10: mean accuracy 0.968
k 11: mean accuracy 0.963
k 12: mean accuracy 0.963
k 13: mean accuracy 0.963
k 14: mean accuracy 0.963
k 15: mean accuracy 0.958
best k 4 (0.974); accuracy of always ubuntu: 0.651
```

`k = 1` and `k = 4` both print 0.974; `k = 4` wins in a later digit. From `k = 1` to `k = 15`, the means stay within 1.7 points, about three jobs out of 186: this data doesn't pick a `k`. Every choice beats the baseline by at least 30 points.

The scaler has seen the test fold of every split, which is the leakage of lesson 1. With 186 rows from the same CI, the means and deviations of four fifths of the rows are close to those of all rows, so the effect here is small, but a score chosen this way is slightly optimistic. Doing it right means writing the fold loop by hand, with `StratifiedKFold::split` and a scaler fitted on each training fold.

</details>

## Sources

- James, Witten, Hastie, Tibshirani, Taylor, *[An Introduction to Statistical Learning](https://www.statlearning.com/)*, chapters 4 (logistic regression, k nearest neighbours), 5 (cross-validation) and 8 (trees)
- [scikit-learn: nearest neighbours](https://scikit-learn.org/stable/modules/neighbors.html), [decision trees](https://scikit-learn.org/stable/modules/tree.html) and [cross-validation](https://scikit-learn.org/stable/modules/cross_validation.html)
- IX at `490c395`: [`logistic_regression.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-supervised/src/logistic_regression.rs), [`knn.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-supervised/src/knn.rs), [`decision_tree.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-supervised/src/decision_tree.rs), [`validation.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-supervised/src/validation.rs)
