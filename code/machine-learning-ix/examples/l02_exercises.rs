//! Lesson 2, exercise solutions.

use ix_optimize::convergence::ConvergenceCriteria;
use ix_optimize::gradient::{Momentum, SGD, minimize};
use ix_optimize::traits::ClosureObjective;
use machine_learning_ix::data::load_builds;
use machine_learning_ix::evaluation::Scaler;
use machine_learning_ix::linear::{fit_closed_form, loss};
use machine_learning_ix::{data_path, pick};
use ndarray::{Array1, array};

fn main() {
    let builds = load_builds(data_path("builds.csv"));
    let pages = builds.pages.column(0).to_owned();
    let seconds = &builds.seconds;

    // Exercise 1: the line on all 65 builds, then without each build in turn
    let (w, b) = fit_closed_form(&pages, seconds);
    println!("== exercise 1");
    println!("all 65 builds: seconds = {w:.6} * pages + {b:.4}");
    let mut changes: Vec<(f64, usize)> = (0..pages.len())
        .map(|i| {
            let keep: Vec<usize> = (0..pages.len()).filter(|&j| j != i).collect();
            let (wi, _) = fit_closed_form(&pick(&pages, &keep), &pick(seconds, &keep));
            ((wi - w).abs(), i)
        })
        .collect();
    changes.sort_by(|a, c| c.0.total_cmp(&a.0));
    for &(change, i) in &changes[..3] {
        println!(
            "without {} ({} pages, {} s): slope changes by {change:.6}",
            builds.shas[i], pages[i], seconds[i]
        );
    }

    // Exercise 2: plain descent against momentum on the standardized problem of the lesson
    let scaler = Scaler::fit(&builds.pages);
    let z = scaler.transform(&builds.pages).column(0).to_owned();
    let objective = ClosureObjective {
        f: |p: &Array1<f64>| loss(&z, seconds, p[0], p[1]),
        dimensions: 2,
    };
    let criteria = ConvergenceCriteria {
        max_iterations: 10_000,
        tolerance: 1e-6,
    };
    println!("\n== exercise 2");
    for learning_rate in [0.01, 0.1] {
        let plain = minimize(
            &objective,
            &mut SGD::new(learning_rate),
            array![0.0, 0.0],
            &criteria,
        );
        let momentum = minimize(
            &objective,
            &mut Momentum::new(learning_rate, 0.9),
            array![0.0, 0.0],
            &criteria,
        );
        println!(
            "learning rate {learning_rate}: SGD {} iterations (loss {:.6}), Momentum(0.9) {} iterations (loss {:.6})",
            plain.iterations, plain.best_value, momentum.iterations, momentum.best_value
        );
    }
}
