//! Lesson 7, solutions to the exercises.

use ix_nn::layer::{Dense, Layer};
use ix_nn::loss::{mse_gradient as ix_mse_gradient, mse_loss as ix_mse_loss};
use machine_learning_ix::data::load_builds;
use machine_learning_ix::evaluation::{mean, std_dev};
use machine_learning_ix::net::{Linear, mse, mse_gradient};
use machine_learning_ix::{data_path, fmt_vec};
use ndarray::{Array1, Array2, Axis, array};

fn main() {
    let builds = load_builds(data_path("builds.csv"));
    let pages = builds.pages.column(0).to_owned();
    let (pm, ps) = (mean(&pages), std_dev(&pages));
    let (sm, ss) = (mean(&builds.seconds), std_dev(&builds.seconds));
    let x = builds.pages.mapv(|v| (v - pm) / ps);
    let target = builds.seconds.mapv(|v| (v - sm) / ss).insert_axis(Axis(1));
    let n = x.nrows();

    // 1. The learning rate that makes Dense take the step the hand layer takes.
    //    Dense divides the weight gradient by the number of rows, so multiply the rate by it.
    println!("== matching one step of the hand layer with one step of Dense");
    let start = array![[0.4]];
    let mut hand = Linear {
        weights: start.clone(),
        bias: Array1::zeros(1),
    };
    let grads = hand.backward(&x, &mse_gradient(&hand.forward(&x), &target));
    hand.step(&grads, 0.5);

    let mut dense = Dense::new(1, 1);
    dense.weights = start.clone();
    dense.bias = Array1::zeros(1);
    let output = dense.forward(&x);
    dense.backward(&ix_mse_gradient(&output, &target), 0.5 * n as f64);
    println!(
        "  hand weight after one step at rate 0.5      {:.9}",
        hand.weights[[0, 0]]
    );
    println!(
        "  Dense weight after one step at rate 0.5 x {n}  {:.9}",
        dense.weights[[0, 0]]
    );
    println!(
        "  gap {:.2e}",
        (hand.weights[[0, 0]] - dense.weights[[0, 0]]).abs()
    );

    // 2. mse_gradient against the true gradient of mse_loss, for one to four output columns
    println!("\n== ix_nn::loss::mse_gradient divided by the true gradient of mse_loss");
    for columns in 1..=4 {
        let wide = Array2::from_shape_fn((n, columns), |(i, j)| target[[i, 0]] * (j + 1) as f64);
        let prediction = Array2::from_shape_fn((n, columns), |(i, _)| x[[i, 0]] * 0.4);
        let claimed = ix_mse_gradient(&prediction, &wide);
        // The true gradient of a mean over rows x columns
        let cells = (n * columns) as f64;
        let truth = 2.0 * (&prediction - &wide) / cells;
        let ratios: Vec<f64> = claimed
            .iter()
            .zip(truth.iter())
            .filter(|(_, t)| t.abs() > 1e-12)
            .map(|(c, t)| c / t)
            .take(1)
            .collect();
        println!(
            "  {columns} column(s): ratio {}, and mse_loss = {:.6}",
            fmt_vec(ratios, 4),
            ix_mse_loss(&prediction, &wide)
        );
    }

    // 3. A hidden layer of width 1 is not enough for exclusive or
    println!("\n== width of the hidden layer against what it can learn (exclusive or)");
    let xor = array![[0.0, 0.0], [0.0, 1.0], [1.0, 0.0], [1.0, 1.0]];
    let xor_y = array![[0.0], [1.0], [1.0], [0.0]];
    for hidden in 1..=4 {
        let mut net = machine_learning_ix::net::TwoLayer::fixed(2, hidden, 1);
        let history = net.fit(&xor, &xor_y, 50_000, 0.5);
        let p = net.predict(&xor);
        let right = (0..4)
            .filter(|&i| (p[[i, 0]] > 0.5) == (xor_y[[i, 0]] > 0.5))
            .count();
        println!(
            "  hidden {hidden}: final loss {:.6}, corners right {right} of 4",
            history[history.len() - 1]
        );
    }
    println!(
        "  a single sigmoid unit still draws one boundary: 0.25 is the best a constant can do"
    );
    println!(
        "  the variance of the four targets is {:.4}",
        mse(&Array2::from_elem((4, 1), 0.5), &xor_y)
    );
}
