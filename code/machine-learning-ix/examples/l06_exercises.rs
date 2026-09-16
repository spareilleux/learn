//! Lesson 6, solutions to the exercises.

use ix_ensemble::random_forest::RandomForest;
use ix_ensemble::traits::EnsembleClassifier;
use machine_learning_ix::data::{OS_NAMES, load_jobs};
use machine_learning_ix::ensemble::Forest;
use machine_learning_ix::evaluation::{accuracy, confusion};
use machine_learning_ix::{data_path, pick, rows};

fn main() {
    let jobs = load_jobs(data_path("jobs.csv"));
    let test_rows: Vec<usize> = (0..jobs.os.len()).filter(|i| i % 5 == 0).collect();
    let train_rows: Vec<usize> = (0..jobs.os.len()).filter(|i| i % 5 != 0).collect();
    let (x_train, x_test) = (
        rows(&jobs.features, &train_rows),
        rows(&jobs.features, &test_rows),
    );
    let (y_train, y_test) = (pick(&jobs.os, &train_rows), pick(&jobs.os, &test_rows));

    // 1. Does the out-of-bag score follow the test score as the trees get deeper?
    println!("== depth against the two scores (hand forest, 50 trees, 3 of 5 features)");
    for depth in 1..=8 {
        let forest = Forest::fit(&x_train, &y_train, 3, 50, depth, 3, 42);
        println!(
            "  depth {depth}: out-of-bag {:.4}, test {:.4}",
            forest.oob_accuracy(&x_train, &y_train),
            accuracy(&y_test, &forest.predict(&x_test))
        );
    }

    // 2. Where the two forests disagree, and which one is right
    let hand = Forest::fit(&x_train, &y_train, 3, 50, 4, 3, 42);
    let mut ix = RandomForest::new(50, 4).with_seed(42);
    ix.fit(&x_train, &y_train);
    let (hp, ip) = (hand.predict(&x_test), ix.predict(&x_test));
    println!("\n== the two forests on the {} test jobs", x_test.nrows());
    let disagree: Vec<usize> = (0..x_test.nrows()).filter(|&i| hp[i] != ip[i]).collect();
    println!(
        "  hand {:.4}, ix {:.4}, rows where they disagree: {disagree:?}",
        accuracy(&y_test, &hp),
        accuracy(&y_test, &ip)
    );
    println!("  the rows the hand forest still gets wrong:");
    for i in 0..x_test.nrows() {
        if hp[i] != y_test[i] {
            println!(
                "    test job {i:2}, workflow {:<30} truly {:<7} predicted {}",
                jobs.workflows[test_rows[i]], OS_NAMES[y_test[i]], OS_NAMES[hp[i]]
            );
        }
    }

    // 3. Which OS the forest still confuses
    println!("\n== confusion of the hand forest, rows true, columns predicted");
    println!("  order {OS_NAMES:?}");
    let m = confusion(&y_test, &hp, 3);
    for (i, name) in OS_NAMES.iter().enumerate() {
        println!("  {name:<7} {:?}", m.row(i).to_vec());
    }
}
