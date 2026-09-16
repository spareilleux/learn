//! Lesson 6: one tree guesses, fifty trees vote. Bootstrap samples and out-of-bag scoring by hand,
//! a random forest that draws features at every split against ix_ensemble's one draw per tree,
//! and gradient boosting on stumps.

use ix_ensemble::gradient_boosting::GradientBoostedClassifier;
use ix_ensemble::random_forest::RandomForest;
use ix_ensemble::traits::EnsembleClassifier;
use machine_learning_ix::classify::{fit_tree, tree_predict};
use machine_learning_ix::data::{OS_NAMES, load_jobs};
use machine_learning_ix::ensemble::{Boosted, Forest, Rng, bootstrap, out_of_bag, softmax};
use machine_learning_ix::evaluation::accuracy;
use machine_learning_ix::{data_path, fmt_vec, pick, rows};
use ndarray::{Array1, Array2, array};

fn main() {
    let jobs = load_jobs(data_path("jobs.csv"));
    // The split of lesson 3: every fifth job tests, the rest train
    let test_rows: Vec<usize> = (0..jobs.os.len()).filter(|i| i % 5 == 0).collect();
    let train_rows: Vec<usize> = (0..jobs.os.len()).filter(|i| i % 5 != 0).collect();
    let (x_train, x_test) = (
        rows(&jobs.features, &train_rows),
        rows(&jobs.features, &test_rows),
    );
    let (y_train, y_test) = (pick(&jobs.os, &train_rows), pick(&jobs.os, &test_rows));
    let all: Vec<usize> = (0..x_train.nrows()).collect();
    println!(
        "== {} jobs, features {:?}: train {}, test {}",
        jobs.os.len(),
        jobs.feature_names,
        x_train.nrows(),
        x_test.nrows()
    );

    // 1. One tree, the baseline of lesson 3
    let tree = fit_tree(&x_train, &y_train, &all, 3, 4);
    let single: Array1<usize> = x_test
        .rows()
        .into_iter()
        .map(|r| tree_predict(&tree, r))
        .collect();
    println!(
        "\n== one tree, depth 4: test accuracy {:.4}",
        accuracy(&y_test, &single)
    );

    // 2. What a bootstrap sample leaves behind
    let mut rng = Rng::new(42);
    let sample = bootstrap(x_train.nrows(), &mut rng);
    let left_out = out_of_bag(x_train.nrows(), &sample);
    println!(
        "a bootstrap of {} rows drew {} distinct rows and left {} out ({:.3} of them); 1/e = {:.3}",
        x_train.nrows(),
        x_train.nrows() - left_out.len(),
        left_out.len(),
        left_out.len() as f64 / x_train.nrows() as f64,
        1.0 / std::f64::consts::E
    );

    // 3. Bagging (every feature at every split) and a random forest (three of five)
    println!("\n== fifty trees of depth 4, by hand");
    for (label, max_features) in [("bagging, 5 of 5 features", 5), ("forest, 3 of 5", 3)] {
        let forest = Forest::fit(&x_train, &y_train, 3, 50, 4, max_features, 42);
        println!(
            "  {label:24}: test accuracy {:.4}, out-of-bag accuracy {:.4}",
            accuracy(&y_test, &forest.predict(&x_test)),
            forest.oob_accuracy(&x_train, &y_train)
        );
    }

    // 4. ix_ensemble on the same split. Its default is ceil(sqrt(5)) = 3 features, drawn once
    //    per tree rather than at every split.
    let mut ix_forest = RandomForest::new(50, 4).with_seed(42);
    ix_forest.fit(&x_train, &y_train);
    println!("\n== ix_ensemble::random_forest::RandomForest::new(50, 4), seed 42");
    println!(
        "  trees {}, max_features default {:?} -> ceil(sqrt(5)) = 3",
        ix_forest.n_estimators(),
        ix_forest.max_features
    );
    println!(
        "  test accuracy {:.4}",
        accuracy(&y_test, &ix_forest.predict(&x_test))
    );

    // 5. One feature per tree against one feature per split
    println!("\n== with a single feature");
    let hand_one = Forest::fit(&x_train, &y_train, 3, 50, 4, 1, 42);
    let mut ix_one = RandomForest::new(50, 4).with_seed(42).with_max_features(1);
    ix_one.fit(&x_train, &y_train);
    println!(
        "  hand, one feature drawn at every split: {:.4}",
        accuracy(&y_test, &hand_one.predict(&x_test))
    );
    println!(
        "  ix, one feature drawn once per tree:    {:.4}",
        accuracy(&y_test, &ix_one.predict(&x_test))
    );

    // 6. How the vote settles as trees are added
    println!("\n== by number of trees (hand forest, 3 of 5)");
    for n in [1, 2, 5, 10, 25, 50, 100] {
        let f = Forest::fit(&x_train, &y_train, 3, n, 4, 3, 42);
        println!(
            "  {n:3} trees: test {:.4}, out-of-bag {:.4}",
            accuracy(&y_test, &f.predict(&x_test)),
            f.oob_accuracy(&x_train, &y_train)
        );
    }

    // 7. A tie in the vote. `predict` takes `max_by`, which keeps the last maximum, so a tie
    //    goes to the largest class index; scikit-learn and the hand forest take the smallest.
    println!("\n== a tie between two classes");
    let tiny = array![[0.0], [1.0]];
    let tiny_y = array![0usize, 1usize];
    for seed in 0..40u64 {
        let mut f = RandomForest::new(2, 0).with_seed(seed);
        f.fit(&tiny, &tiny_y);
        let proba = f.predict_proba(&tiny);
        if (proba[[0, 0]] - 0.5).abs() < 1e-12 && (proba[[0, 1]] - 0.5).abs() < 1e-12 {
            println!(
                "  two stumps, seed {seed}: probabilities {} -> ix predicts class {}",
                fmt_vec(proba.row(0).iter().copied(), 3),
                f.predict(&tiny)[0]
            );
            break;
        }
    }

    // 8. Gradient boosting: the same recipe by hand and in IX
    println!("\n== gradient boosting on stumps, learning rate 0.3");
    for rounds in [1, 5, 10, 25, 50] {
        let hand = Boosted::fit(&x_train, &y_train, 3, rounds, 0.3);
        let mut ix_gb = GradientBoostedClassifier::new(rounds, 0.3);
        ix_gb.fit(&x_train, &y_train);
        let (hp, ip) = (hand.predict(&x_test), ix_gb.predict(&x_test));
        let differ = (0..x_test.nrows()).filter(|&i| hp[i] != ip[i]).count();
        println!(
            "  {rounds:2} rounds: hand {:.4}, ix {:.4}, rows where they differ {differ}",
            accuracy(&y_test, &hp),
            accuracy(&y_test, &ip)
        );
    }

    // 9. The first stump of the first round, and the priors it starts from
    let one = Boosted::fit(&x_train, &y_train, 3, 1, 0.3);
    println!(
        "\nstart, the smoothed log priors: {}",
        fmt_vec(one.init.iter().copied(), 4)
    );
    for (c, name) in OS_NAMES.iter().enumerate() {
        let s = &one.rounds[0][c];
        println!(
            "  round 1, class {name:<7}: split {} <= {:.1}, leaves {:.4} and {:.4}",
            jobs.feature_names[s.feature], s.threshold, s.left, s.right
        );
    }
    let probabilities: Array2<f64> = softmax(&one.raw_scores(&x_test));
    println!(
        "  probabilities of the first test job after one round: {}",
        fmt_vec(probabilities.row(0).iter().copied(), 4)
    );
}
