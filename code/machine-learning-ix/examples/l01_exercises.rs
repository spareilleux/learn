//! Lesson 1, exercise solutions.

use ix_math::preprocessing::train_test_split;
use ix_supervised::metrics;
use ix_supervised::validation::StratifiedKFold;
use machine_learning_ix::data::{load_builds, load_jobs};
use machine_learning_ix::evaluation::{self as hand, split_last};
use machine_learning_ix::{data_path, pick};
use ndarray::Array1;

fn main() {
    // Exercise 1: predict each test build with the seconds of the build just before it
    let builds = load_builds(data_path("builds.csv"));
    let y = &builds.seconds;
    let (train, test) = split_last(y.len(), 0.2);
    let y_test = pick(y, &test);
    let previous: Array1<f64> = test.iter().map(|&i| y[i - 1]).collect();
    let mean = Array1::from_elem(test.len(), hand::mean(&pick(y, &train)));
    println!("== exercise 1");
    for (name, p) in [("previous build", &previous), ("training mean", &mean)] {
        println!(
            "{name:14}: mae {:.3}, rmse {:.3}, r2 {:.3}",
            metrics::mae(&y_test, p),
            metrics::rmse(&y_test, p),
            metrics::r_squared(&y_test, p)
        );
    }

    // Exercise 2: how many macOS jobs land in a random 20% test set, and in each stratified fold
    let jobs = load_jobs(data_path("jobs.csv"));
    let labels = jobs.os.mapv(|c| c as f64);
    println!("\n== exercise 2");
    let per_seed: Vec<usize> = (0..10)
        .map(|seed| {
            let split = train_test_split(&jobs.features, &labels, 0.2, seed).unwrap();
            split.y_test.iter().filter(|&&c| c == 2.0).count()
        })
        .collect();
    println!("macos jobs in the 37 test rows of train_test_split, seeds 0 to 9: {per_seed:?}");
    let folds = StratifiedKFold::new(5).split(&jobs.os);
    let per_fold: Vec<(usize, usize)> = folds
        .iter()
        .map(|(_, t)| (t.len(), t.iter().filter(|&&i| jobs.os[i] == 2).count()))
        .collect();
    println!("StratifiedKFold(5), (test rows, macos jobs) per fold: {per_fold:?}");
}
