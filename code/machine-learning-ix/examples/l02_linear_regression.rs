//! Lesson 2: build seconds as a straight line of the page count, by the closed form and by gradient descent,
//! by hand and with IX (ix_supervised::linear_regression and ix_optimize::gradient).

use ix_optimize::convergence::ConvergenceCriteria;
use ix_optimize::gradient::{Adam, SGD, minimize};
use ix_optimize::traits::{ClosureObjective, ObjectiveFunction};
use ix_supervised::linear_regression::LinearRegression;
use ix_supervised::metrics;
use ix_supervised::traits::Regressor;
use machine_learning_ix::data::load_builds;
use machine_learning_ix::evaluation::{self as hand, Scaler, split_last};
use machine_learning_ix::linear::{fit_closed_form, gradient_step, loss};
use machine_learning_ix::{data_path, pick, rows};
use ndarray::{Array1, array};

/// Mean squared error of the line as a function of its parameters [w, b], with the exact gradient
struct Mse<'a> {
    x: &'a Array1<f64>,
    y: &'a Array1<f64>,
}

impl ObjectiveFunction for Mse<'_> {
    fn evaluate(&self, p: &Array1<f64>) -> f64 {
        loss(self.x, self.y, p[0], p[1])
    }

    fn gradient(&self, p: &Array1<f64>) -> Array1<f64> {
        // gradient_step with a learning rate of 1 returns (w - dw, b - db)
        let (w, b) = gradient_step(self.x, self.y, p[0], p[1], 1.0);
        array![p[0] - w, p[1] - b]
    }

    fn dim(&self) -> usize {
        2
    }
}

fn main() {
    let builds = load_builds(data_path("builds.csv"));
    let (train, test) = split_last(builds.seconds.len(), 0.2);
    let (x_train, x_test) = (rows(&builds.pages, &train), rows(&builds.pages, &test));
    let (y_train, y_test) = (pick(&builds.seconds, &train), pick(&builds.seconds, &test));
    let pages_train = x_train.column(0).to_owned();

    // 1. Closed form, by hand and with IX's normal equation
    let (w, b) = fit_closed_form(&pages_train, &y_train);
    let mut model = LinearRegression::new();
    model.fit(&x_train, &y_train);
    let ix_w = model.weights.as_ref().unwrap()[0];
    println!("== least squares on the {} training builds", train.len());
    println!("hand: seconds = {w:.6} * pages + {b:.6}");
    println!("ix:   seconds = {ix_w:.6} * pages + {:.6}", model.bias);
    println!(
        "same to 1e-9: {}",
        (w - ix_w).abs() < 1e-9 && (b - model.bias).abs() < 1e-9
    );

    // 2. On the test builds: the line against the baseline of lesson 1
    let predicted = model.predict(&x_test);
    let baseline = Array1::from_elem(test.len(), hand::mean(&y_train));
    println!("\n== {} test builds", test.len());
    println!(
        "line:     rmse {:.3}, mae {:.3}, r2 {:.3}",
        metrics::rmse(&y_test, &predicted),
        metrics::mae(&y_test, &predicted),
        metrics::r_squared(&y_test, &predicted)
    );
    println!(
        "baseline: rmse {:.3}, mae {:.3}, r2 {:.3}",
        metrics::rmse(&y_test, &baseline),
        metrics::mae(&y_test, &baseline),
        metrics::r_squared(&y_test, &baseline)
    );
    for i in 0..test.len() {
        println!(
            "  {} {:>3} pages: actual {:>2} s, predicted {:.1} s, error {:+.1}",
            builds.shas[test[i]],
            x_test[[i, 0]],
            y_test[i],
            predicted[i],
            y_test[i] - predicted[i]
        );
    }
    let kept: Vec<usize> = (0..test.len()).filter(|&i| y_test[i] < 40.0).collect();
    let (y_kept, p_kept) = (pick(&y_test, &kept), pick(&predicted, &kept));
    println!(
        "without the 48 s build: rmse {:.3}, mae {:.3}, r2 {:.3}",
        metrics::rmse(&y_kept, &p_kept),
        metrics::mae(&y_kept, &p_kept),
        metrics::r_squared(&y_kept, &p_kept)
    );

    // 3. Gradient descent by hand, on raw page counts
    println!("\n== gradient descent by hand, raw pages");
    for learning_rate in [3e-5, 1e-5] {
        let (mut gw, mut gb) = (0.0, 0.0);
        print!("learning rate {learning_rate:e}:");
        for step in 1..=100_000 {
            (gw, gb) = gradient_step(&pages_train, &y_train, gw, gb, learning_rate);
            if [1, 10, 1000, 100_000].contains(&step) {
                print!(
                    " step {step} loss {:.3e}",
                    loss(&pages_train, &y_train, gw, gb)
                );
            }
        }
        println!("\n  -> w {gw:.6}, b {gb:.6}");
    }

    // 4. The same descent on standardized pages: z = (pages - mean) / std, so seconds = ws * z + bs
    let scaler = Scaler::fit(&x_train);
    let z = scaler.transform(&x_train).column(0).to_owned();
    let (mean, std) = (scaler.means[0], scaler.stds[0]);
    let (mut ws, mut bs) = (0.0, 0.0);
    let mut steps = 0;
    while steps < 10_000 {
        let (nw, nb) = gradient_step(&z, &y_train, ws, bs, 0.1);
        steps += 1;
        let moved = (nw - ws).abs().max((nb - bs).abs());
        (ws, bs) = (nw, nb);
        if moved < 1e-9 {
            break;
        }
    }
    println!("\n== gradient descent by hand, standardized pages, learning rate 0.1");
    println!(
        "{steps} steps: ws {ws:.6}, bs {bs:.6} -> w {:.6}, b {:.6}",
        ws / std,
        bs - ws * mean / std
    );

    // 5. IX's optimizers on the same standardized problem
    println!("\n== ix_optimize::gradient::minimize, from [0, 0]");
    let criteria = ConvergenceCriteria {
        max_iterations: 10_000,
        tolerance: 1e-6,
    };
    let exact = Mse { x: &z, y: &y_train };
    let numerical = ClosureObjective {
        f: |p: &Array1<f64>| loss(&z, &y_train, p[0], p[1]),
        dimensions: 2,
    };
    let runs = [
        (
            "SGD(0.1), exact gradient",
            minimize(&exact, &mut SGD::new(0.1), array![0.0, 0.0], &criteria),
        ),
        (
            "SGD(0.1), numerical gradient",
            minimize(&numerical, &mut SGD::new(0.1), array![0.0, 0.0], &criteria),
        ),
        (
            "Adam(0.1), exact gradient",
            minimize(&exact, &mut Adam::new(0.1), array![0.0, 0.0], &criteria),
        ),
    ];
    for (name, r) in &runs {
        let (rw, rb) = (r.best_params[0], r.best_params[1]);
        println!(
            "{name:30} iterations {:>5}, converged {:5}, loss {:.6}, w {:.6}, b {:.6}",
            r.iterations,
            r.converged,
            r.best_value,
            rw / std,
            rb - rw * mean / std
        );
    }
    println!(
        "closed-form loss on the training builds: {:.6}",
        loss(&pages_train, &y_train, w, b)
    );
}
