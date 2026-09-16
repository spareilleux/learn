//! Lesson 8, solutions to the exercises.

use ix_optimize::convergence::ConvergenceCriteria;
use ix_optimize::gradient::{Adam as IxAdam, minimize};
use ix_optimize::traits::{ClosureObjective, ObjectiveFunction};
use machine_learning_ix::fmt_vec;
use machine_learning_ix::optimize::{
    Adam, Momentum, Sgd, descend, rosenbrock, rosenbrock_gradient,
};
use ndarray::{Array1, array};
use std::cell::Cell;

/// Rosenbrock that counts how often it is evaluated.
struct Counted<'a> {
    calls: &'a Cell<usize>,
    written_gradient: bool,
}

impl ObjectiveFunction for Counted<'_> {
    fn evaluate(&self, x: &Array1<f64>) -> f64 {
        self.calls.set(self.calls.get() + 1);
        rosenbrock(x)
    }
    fn gradient(&self, x: &Array1<f64>) -> Array1<f64> {
        if self.written_gradient {
            rosenbrock_gradient(x)
        } else {
            ix_math::calculus::numerical_gradient(&|p: &Array1<f64>| self.evaluate(p), x, 1e-7)
        }
    }
    fn dim(&self) -> usize {
        2
    }
}

fn main() {
    let start = array![-1.2, 1.0];

    // 1. The largest plain-descent rate that still reaches the valley
    println!("== plain descent on Rosenbrock, 5000 steps, by learning rate");
    for rate in [0.0001, 0.0005, 0.001, 0.002, 0.005, 0.01] {
        let mut rule = Sgd {
            learning_rate: rate,
        };
        let run = descend(
            rosenbrock,
            rosenbrock_gradient,
            &mut rule,
            start.clone(),
            5000,
            1e-8,
        );
        let ending = if run.last_value.is_finite() {
            format!("{:.6}", run.last_value)
        } else {
            format!("{}", run.last_value)
        };
        println!("  rate {rate:<7}: ends at f {ending}");
    }

    // 2. What the missing gradient costs in evaluations
    println!("\n== evaluations of f for 200 Adam steps");
    let criteria = ConvergenceCriteria::new(200, 1e-12);
    for written in [true, false] {
        let calls = Cell::new(0);
        let objective = Counted {
            calls: &calls,
            written_gradient: written,
        };
        let mut adam = IxAdam::new(0.05);
        let result = minimize(&objective, &mut adam, start.clone(), &criteria);
        println!(
            "  written gradient {written:<5}: {} evaluations, best f {:.3e}",
            calls.get(),
            result.best_value
        );
    }

    // 3. Momentum: how the coefficient changes the number of steps
    println!("\n== momentum coefficient against steps to reach f < 1e-10");
    for coefficient in [0.0, 0.5, 0.9, 0.95, 0.99] {
        let mut rule = Momentum::new(0.001, coefficient);
        let run = descend(
            rosenbrock,
            rosenbrock_gradient,
            &mut rule,
            start.clone(),
            20_000,
            1e-8,
        );
        println!(
            "  {coefficient:<5}: {:5} steps, last {} f {:.3e}",
            run.steps,
            fmt_vec(run.last.iter().copied(), 4),
            run.last_value
        );
    }

    // 4. A closure objective pays for the gradient it did not write, even when it lands well
    let closure = ClosureObjective {
        f: |v: &Array1<f64>| rosenbrock(v),
        dimensions: 2,
    };
    let mut adam = Adam::new(0.05);
    let by_hand = descend(
        rosenbrock,
        |v| ix_math::calculus::numerical_gradient(&|p: &Array1<f64>| rosenbrock(p), v, 1e-7),
        &mut adam,
        start.clone(),
        200,
        1e-12,
    );
    let mut ix_adam = IxAdam::new(0.05);
    let by_ix = minimize(&closure, &mut ix_adam, start.clone(), &criteria);
    println!("\n== the measured gradient, both ways, 200 steps");
    println!(
        "  hand {} f {:.3e}",
        fmt_vec(by_hand.last.iter().copied(), 6),
        by_hand.last_value
    );
    println!(
        "  ix   {} f {:.3e}",
        fmt_vec(by_ix.best_params.iter().copied(), 6),
        by_ix.best_value
    );
}
