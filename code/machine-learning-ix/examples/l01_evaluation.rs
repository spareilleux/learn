//! Lesson 1: features and labels as ndarray matrices, a train/test split, a baseline, and the metrics that score it,
//! each computed by hand and with IX.

use ix_math::preprocessing::{InferredTask, StandardScaler, infer_task_type, train_test_split};
use ix_supervised::metrics::{self, Average, ConfusionMatrix};
use machine_learning_ix::data::{OS_NAMES, load_builds, load_jobs};
use machine_learning_ix::evaluation::{self as hand, Scaler, split_last};
use machine_learning_ix::{data_path, fmt_vec, pick, rows};
use ndarray::Array1;

fn main() {
    // 1. The regression data: x = pages of the site, y = seconds of the build step
    let builds = load_builds(data_path("builds.csv"));
    let (x, y) = (&builds.pages, &builds.seconds);
    println!("== builds.csv");
    println!(
        "x: {:?} {:?}, y: {:?}",
        x.shape(),
        x.column(0).iter().take(3).collect::<Vec<_>>(),
        y.len()
    );
    println!(
        "y mean {:.3}, std {:.3} (hand)",
        hand::mean(y),
        hand::std_dev(y)
    );
    println!(
        "y mean {:.3}, std {:.3} (ix_math::stats)",
        ix_math::stats::mean(y).unwrap(),
        ix_math::stats::std_dev(y).unwrap()
    );

    // 2. Two splits with the same sizes: the last 20% in time (hand), and 20% at random (IX, seed 42)
    let (train, test) = split_last(y.len(), 0.2);
    let split = train_test_split(x, y, 0.2, 42).unwrap();
    println!("\n== split");
    println!(
        "chronological: train {}, test {}, test pages {}..{}",
        train.len(),
        test.len(),
        x[[test[0], 0]],
        x[[test[test.len() - 1], 0]]
    );
    println!(
        "ix train_test_split: train {}, test {}, test pages {}",
        split.x_train.nrows(),
        split.x_test.nrows(),
        fmt_vec(split.x_test.column(0).iter().copied(), 0)
    );

    // 3. Baseline: predict the mean of the training y for every test row
    let (y_train, y_test) = (pick(y, &train), pick(y, &test));
    let baseline = Array1::from_elem(test.len(), hand::mean(&y_train));
    println!(
        "\n== baseline on the chronological test set: always {:.3} s",
        baseline[0]
    );
    println!(
        "hand: mse {:.3}, rmse {:.3}, mae {:.3}, r2 {:.3}",
        hand::mse(&y_test, &baseline),
        hand::mse(&y_test, &baseline).sqrt(),
        hand::mae(&y_test, &baseline),
        hand::r2(&y_test, &baseline)
    );
    println!(
        "ix:   mse {:.3}, rmse {:.3}, mae {:.3}, r2 {:.3}",
        metrics::mse(&y_test, &baseline),
        metrics::rmse(&y_test, &baseline),
        metrics::mae(&y_test, &baseline),
        metrics::r_squared(&y_test, &baseline)
    );

    // 4. Scaling: statistics of the training rows only, then the same transformation on the test rows
    let (x_train, x_test) = (rows(x, &train), rows(x, &test));
    let scaler = Scaler::fit(&x_train);
    let ix_scaler = StandardScaler::fit(&x_train).unwrap();
    let everything = StandardScaler::fit(x).unwrap();
    println!("\n== scaling pages");
    println!(
        "hand, train rows: mean {:.3}, std {:.3}",
        scaler.means[0], scaler.stds[0]
    );
    println!(
        "ix,   train rows: mean {:.3}, std {:.3}",
        ix_scaler.means[0], ix_scaler.stds[0]
    );
    println!(
        "ix,   all rows:   mean {:.3}, std {:.3}",
        everything.means[0], everything.stds[0]
    );
    println!(
        "first test row scaled: {:.3} (train statistics), {:.3} (all rows)",
        scaler.transform(&x_test)[[0, 0]],
        everything.transform(&x_test)[[0, 0]]
    );

    // 5. What IX's ML pipeline would call this target
    let distinct = {
        let mut v: Vec<i64> = y.iter().map(|s| *s as i64).collect();
        v.sort();
        v.dedup();
        v.len()
    };
    let task = infer_task_type(y.as_slice().unwrap(), 20);
    println!("\n== infer_task_type: {distinct} distinct values -> {task:?}");
    println!("same seconds with 0.5 added to one row -> {:?}", {
        let mut shifted = y.to_vec();
        shifted[0] += 0.5;
        infer_task_type(&shifted, 20) == InferredTask::Regression
    });

    // 6. The classification data: which OS ran a CI job? Baseline: always the most frequent class
    let jobs = load_jobs(data_path("jobs.csv"));
    let counts: Vec<usize> = (0..3)
        .map(|c| jobs.os.iter().filter(|&&o| o == c).count())
        .collect();
    println!(
        "\n== jobs.csv: {:?} {:?}, classes {:?} = {:?}",
        jobs.features.shape(),
        jobs.feature_names,
        OS_NAMES,
        counts
    );
    let always_ubuntu = Array1::zeros(jobs.os.len());
    let m = hand::confusion(&jobs.os, &always_ubuntu, 3);
    println!("confusion matrix (rows = true class, columns = predicted):\n{m}");
    println!(
        "accuracy {:.3} (hand), {:.3} (ix)",
        hand::accuracy(&jobs.os, &always_ubuntu),
        metrics::accuracy(&jobs.os, &always_ubuntu)
    );
    for (c, name) in OS_NAMES.iter().enumerate() {
        let (p, r, f) = hand::precision_recall_f1(&m, c);
        println!(
            "{:8} precision {:.3} recall {:.3} f1 {:.3} | ix {:.3} {:.3} {:.3}",
            name,
            p,
            r,
            f,
            metrics::precision(&jobs.os, &always_ubuntu, c),
            metrics::recall(&jobs.os, &always_ubuntu, c),
            metrics::f1_score(&jobs.os, &always_ubuntu, c)
        );
    }
    let macro_f1 = (0..3)
        .map(|c| hand::precision_recall_f1(&m, c).2)
        .sum::<f64>()
        / 3.0;
    println!(
        "macro f1 {:.3} (hand), {:.3} (ix f1_avg)",
        macro_f1,
        metrics::f1_avg(&jobs.os, &always_ubuntu, Average::Macro)
    );
    let cm = ConfusionMatrix::from_labels(&jobs.os, &always_ubuntu, 3);
    print!("{}", cm.display());
}
