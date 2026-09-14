//! Lesson 3: which OS ran a CI job, from the timings of its steps. Logistic regression, k nearest neighbours
//! and a decision tree, by hand and with ix_supervised.

use ix_supervised::decision_tree::DecisionTree;
use ix_supervised::knn::KNN;
use ix_supervised::logistic_regression::LogisticRegression;
use ix_supervised::metrics;
use ix_supervised::traits::Classifier;
use ix_supervised::validation::cross_val_score;
use machine_learning_ix::classify::{
    Tree, fit_logistic, fit_tree, knn_predict, sigmoid, tree_predict,
};
use machine_learning_ix::data::{OS_NAMES, load_jobs};
use machine_learning_ix::evaluation::{Scaler, confusion, precision_recall_f1};
use machine_learning_ix::{data_path, fmt_vec, pick, rows};
use ndarray::{Array1, Array2, Axis};

fn print_tree(tree: &Tree, names: &[String], depth: usize) {
    let indent = "  ".repeat(depth);
    match tree {
        Tree::Leaf { class, counts } => println!("{indent}-> {} {counts:?}", OS_NAMES[*class]),
        Tree::Split {
            feature,
            threshold,
            left,
            right,
        } => {
            println!("{indent}{} <= {threshold}", names[*feature]);
            print_tree(left, names, depth + 1);
            println!("{indent}{} > {threshold}", names[*feature]);
            print_tree(right, names, depth + 1);
        }
    }
}

fn main() {
    let jobs = load_jobs(data_path("jobs.csv"));
    let names = &jobs.feature_names;
    // Every fifth job tests, the others train: the same rows in the scikit-learn check, which can't replay IX's random split
    let test_rows: Vec<usize> = (0..jobs.os.len()).filter(|i| i % 5 == 0).collect();
    let test = &test_rows;
    let train: Vec<usize> = (0..jobs.os.len()).filter(|i| i % 5 != 0).collect();
    let (x_train, x_test) = (rows(&jobs.features, &train), rows(&jobs.features, test));
    let (y_train, y_test) = (pick(&jobs.os, &train), pick(&jobs.os, test));
    let count = |y: &Array1<usize>| {
        (0..3)
            .map(|c| y.iter().filter(|&&v| v == c).count())
            .collect::<Vec<_>>()
    };
    println!(
        "== split: train {} {:?}, test {} {:?} (ubuntu, windows, macos)",
        y_train.len(),
        count(&y_train),
        y_test.len(),
        count(&y_test)
    );

    // 1. Binary logistic regression: is it Windows? Two features: checkout_s and post_checkout_s
    let two = [2, 3];
    let (xb_train, xb_test) = (x_train.select(Axis(1), &two), x_test.select(Axis(1), &two));
    let (yb_train, yb_test) = (
        y_train.mapv(|c| usize::from(c == 1)),
        y_test.mapv(|c| usize::from(c == 1)),
    );
    println!(
        "\n== logistic regression, windows or not, features {:?}",
        [&names[2], &names[3]]
    );
    for (learning_rate, iterations) in [(0.01, 1000), (0.1, 20_000)] {
        let (w, b) = fit_logistic(&xb_train, &yb_train, learning_rate, iterations);
        let mut model = LogisticRegression::new()
            .with_learning_rate(learning_rate)
            .with_max_iterations(iterations);
        model.fit(&xb_train, &yb_train);
        let ix_w = model.weights.as_ref().unwrap();
        let same = (&w - ix_w).iter().all(|d| d.abs() < 1e-9) && (b - model.bias).abs() < 1e-9;
        let predicted = model.predict(&xb_test);
        let m = confusion(&yb_test, &predicted, 2);
        let (p, r, _) = precision_recall_f1(&m, 1);
        println!(
            "lr {learning_rate}, {iterations} iterations: hand w {} b {b:.4} | ix w {} b {:.4} | same to 1e-9: {same}",
            fmt_vec(w.iter().copied(), 4),
            fmt_vec(ix_w.iter().copied(), 4),
            model.bias
        );
        println!(
            "  test: accuracy {:.3}, windows precision {p:.3}, recall {r:.3}",
            metrics::accuracy(&yb_test, &predicted)
        );
        for checkout in [1.0, 3.0, 6.0] {
            print!(
                "  P(windows | checkout {checkout} s, post {} s) = {:.3}",
                checkout / 2.0,
                sigmoid(w[0] * checkout + w[1] * checkout / 2.0 + b)
            );
        }
        println!();
    }

    // 2. k nearest neighbours, all five features: raw, then standardized with the training statistics
    println!("\n== k nearest neighbours, features {names:?}");
    let scaler = Scaler::fit(&x_train);
    for (label, train, test) in [
        ("raw", x_train.clone(), x_test.clone()),
        (
            "standardized",
            scaler.transform(&x_train),
            scaler.transform(&x_test),
        ),
    ] {
        for k in [4, 5] {
            let hand = knn_predict(&train, &y_train, &test, k, 3);
            let mut knn = KNN::new(k);
            knn.fit(&train, &y_train);
            let ix = knn.predict(&test);
            let differ: Vec<usize> = (0..test.nrows()).filter(|&i| hand[i] != ix[i]).collect();
            println!(
                "{label:12} k = {k}: accuracy hand {:.3}, ix {:.3}, test rows where they differ: {differ:?}",
                metrics::accuracy(&y_test, &hand),
                metrics::accuracy(&y_test, &ix)
            );
            for &i in &differ {
                let votes = knn.predict_proba(&test.select(Axis(0), &[i]));
                println!(
                    "  test row {i} (jobs.csv row {}, from 0): votes {} -> hand {}, ix {}, true {}",
                    test_rows[i],
                    fmt_vec(votes.row(0).iter().map(|v| v * k as f64), 0),
                    OS_NAMES[hand[i]],
                    OS_NAMES[ix[i]],
                    OS_NAMES[y_test[i]]
                );
            }
        }
    }

    // 3. Decision tree, depth 3
    println!("\n== decision tree, max depth 3");
    let all: Vec<usize> = (0..x_train.nrows()).collect();
    let tree = fit_tree(&x_train, &y_train, &all, 3, 3);
    print_tree(&tree, names, 0);
    let hand: Array1<usize> = x_test
        .rows()
        .into_iter()
        .map(|r| tree_predict(&tree, r))
        .collect();
    let mut ix_tree = DecisionTree::new(3);
    ix_tree.fit(&x_train, &y_train);
    let ix = ix_tree.predict(&x_test);
    let state = serde_json::to_value(ix_tree.save_state().unwrap()).unwrap();
    println!("ix nodes, pre-order: {}", state["nodes"]);
    println!(
        "test accuracy hand {:.3}, ix {:.3}, same predictions: {}",
        metrics::accuracy(&y_test, &hand),
        metrics::accuracy(&y_test, &ix),
        hand == ix
    );
    let m = confusion(&y_test, &ix, 3);
    println!("confusion matrix (rows = true, columns = predicted):\n{m}");
    for (c, name) in OS_NAMES.iter().enumerate() {
        let (p, r, f) = precision_recall_f1(&m, c);
        println!("{name:8} precision {p:.3} recall {r:.3} f1 {f:.3}");
    }

    // 4. Five-fold stratified cross-validation on all 186 jobs
    println!("\n== cross_val_score, 5 stratified folds, seed 42");
    let x: &Array2<f64> = &jobs.features;
    for (name, scores) in [
        (
            "knn k=5, raw",
            cross_val_score(x, &jobs.os, || KNN::new(5), 5, 42),
        ),
        (
            "decision tree depth 3",
            cross_val_score(x, &jobs.os, || DecisionTree::new(3), 5, 42),
        ),
        (
            "decision tree depth 10",
            cross_val_score(x, &jobs.os, || DecisionTree::new(10), 5, 42),
        ),
    ] {
        let mean = scores.iter().sum::<f64>() / scores.len() as f64;
        println!("{name:22} folds {} mean {mean:.3}", fmt_vec(scores, 3));
    }
}
