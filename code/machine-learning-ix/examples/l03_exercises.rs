//! Lesson 3, exercise solutions.

use ix_supervised::knn::KNN;
use ix_supervised::logistic_regression::LogisticRegression;
use ix_supervised::metrics::{self, auc_score};
use ix_supervised::traits::Classifier;
use ix_supervised::validation::cross_val_score;
use machine_learning_ix::data::load_jobs;
use machine_learning_ix::evaluation::{Scaler, confusion, precision_recall_f1};
use machine_learning_ix::{data_path, fmt_vec, pick, rows};
use ndarray::{Array1, Axis};

fn main() {
    let jobs = load_jobs(data_path("jobs.csv"));
    let test: Vec<usize> = (0..jobs.os.len()).filter(|i| i % 5 == 0).collect();
    let train: Vec<usize> = (0..jobs.os.len()).filter(|i| i % 5 != 0).collect();

    // Exercise 1: macOS or not, from queue_s and checkout_s, standardized; then other thresholds
    let two = [0, 2];
    let x = jobs.features.select(Axis(1), &two);
    let scaler = Scaler::fit(&rows(&x, &train));
    let (x_train, x_test) = (
        scaler.transform(&rows(&x, &train)),
        scaler.transform(&rows(&x, &test)),
    );
    let is_mac = jobs.os.mapv(|c| usize::from(c == 2));
    let (y_train, y_test) = (pick(&is_mac, &train), pick(&is_mac, &test));
    let mut model = LogisticRegression::new()
        .with_learning_rate(0.1)
        .with_max_iterations(5000);
    model.fit(&x_train, &y_train);
    let p_mac = model.predict_proba(&x_test).column(1).to_owned();
    println!("== exercise 1");
    println!(
        "weights {} bias {:.4}",
        fmt_vec(model.weights.as_ref().unwrap().iter().copied(), 4),
        model.bias
    );
    for threshold in [0.3, 0.5, 0.7, 0.9] {
        let predicted: Array1<usize> = p_mac.mapv(|p| usize::from(p >= threshold));
        let (p, r, f) = precision_recall_f1(&confusion(&y_test, &predicted, 2), 1);
        println!(
            "threshold {threshold}: macos precision {p:.3}, recall {r:.3}, f1 {f:.3}, predicted macos {}",
            predicted.sum()
        );
    }
    println!("AUC {:.3}", auc_score(&y_test, &p_mac));

    // Exercise 2: k from 1 to 15, five stratified folds, on standardized features
    let z = Scaler::fit(&jobs.features).transform(&jobs.features);
    println!("\n== exercise 2");
    let mut best = (0.0, 0);
    for k in 1..=15 {
        let scores = cross_val_score(&z, &jobs.os, || KNN::new(k), 5, 42);
        let mean = scores.iter().sum::<f64>() / 5.0;
        println!("k {k:2}: mean accuracy {mean:.3}");
        if mean > best.0 {
            best = (mean, k);
        }
    }
    println!(
        "best k {} ({:.3}); accuracy of always ubuntu: {:.3}",
        best.1,
        best.0,
        metrics::accuracy(&jobs.os, &Array1::zeros(jobs.os.len()))
    );
}
