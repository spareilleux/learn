//! Lesson 7: backpropagation judged by finite differences. A hand-written affine layer, then
//! ix_nn::layer::Dense — the gradient it really applies, the weights it draws without a seed, and
//! what a stack of Dense layers can and cannot represent.

use ix_nn::layer::{Dense, Layer};
use ix_nn::loss::{mse_gradient as ix_mse_gradient, mse_loss as ix_mse_loss};
use ix_nn::network::Sequential;
use machine_learning_ix::data::load_builds;
use machine_learning_ix::evaluation::{mean, std_dev};
use machine_learning_ix::net::{
    Linear, TwoLayer, finite_difference, largest_gap, mse, mse_gradient,
};
use machine_learning_ix::{data_path, fmt_vec};
use ndarray::{Array1, Array2, Axis, array};

/// A `Dense` whose weights are set by hand, because `Dense::new` draws them from an unseeded
/// generator.
fn fixed_dense(inputs: usize, outputs: usize, weights: &Array2<f64>) -> Dense {
    let mut dense = Dense::new(inputs, outputs);
    dense.weights = weights.clone();
    dense.bias = Array1::zeros(outputs);
    dense
}

/// What one `backward` really subtracts from the weights, with a learning rate of 1.
fn applied_gradient(x: &Array2<f64>, target: &Array2<f64>, weights: &Array2<f64>) -> Array2<f64> {
    let mut dense = fixed_dense(x.ncols(), target.ncols(), weights);
    let output = dense.forward(x);
    dense.backward(&ix_mse_gradient(&output, target), 1.0);
    weights - &dense.weights
}

/// The gradient of `ix_nn::loss::mse_loss` itself, measured rather than derived.
fn numeric_gradient(x: &Array2<f64>, target: &Array2<f64>, weights: &Array2<f64>) -> Vec<f64> {
    let shape = weights.dim();
    let start: Vec<f64> = weights.iter().copied().collect();
    finite_difference(&start, 1e-6, |v| {
        let probe = Array2::from_shape_vec(shape, v.to_vec()).unwrap();
        let mut dense = fixed_dense(x.ncols(), target.ncols(), &probe);
        ix_mse_loss(&dense.forward(x), target)
    })
}

fn main() {
    // The regression of lesson 2, standardized so that one learning rate suits both columns
    let builds = load_builds(data_path("builds.csv"));
    let pages_mean = mean(&builds.pages.column(0).to_owned());
    let pages_std = std_dev(&builds.pages.column(0).to_owned());
    let seconds_mean = mean(&builds.seconds);
    let seconds_std = std_dev(&builds.seconds);
    let x = builds.pages.mapv(|v| (v - pages_mean) / pages_std);
    let target = builds
        .seconds
        .mapv(|v| (v - seconds_mean) / seconds_std)
        .insert_axis(Axis(1));
    println!(
        "== {} builds, pages standardized -> seconds standardized",
        x.nrows()
    );

    // 1. The hand-written layer against finite differences
    let weights = array![[0.4]];
    let layer = Linear {
        weights: weights.clone(),
        bias: Array1::zeros(1),
    };
    let analytic = layer.backward(&x, &mse_gradient(&layer.forward(&x), &target));
    let numeric = finite_difference(&[0.4], 1e-6, |v| {
        let probe = Linear {
            weights: array![[v[0]]],
            bias: Array1::zeros(1),
        };
        mse(&probe.forward(&x), &target)
    });
    println!("\n== the hand layer, judged by finite differences");
    println!(
        "  analytic {:.9}, numeric {:.9}, gap {:.2e}",
        analytic.weights[[0, 0]],
        numeric[0],
        largest_gap(&[analytic.weights[[0, 0]]], &numeric)
    );

    // 2. The same question asked of ix_nn::layer::Dense
    let applied = applied_gradient(&x, &target, &weights);
    let ix_numeric = numeric_gradient(&x, &target, &weights);
    println!("\n== ix_nn::layer::Dense, one output column");
    println!("  gradient of mse_loss, measured: {:.9}", ix_numeric[0]);
    println!("  what backward subtracts:        {:.9}", applied[[0, 0]]);
    println!(
        "  ratio: {:.4}, and the batch has {} rows",
        ix_numeric[0] / applied[[0, 0]],
        x.nrows()
    );

    // 3. Two output columns: mse_loss averages over every cell, mse_gradient divides by the rows
    let wide_target = ndarray::concatenate![Axis(1), target.clone(), target.clone() * 2.0];
    let wide_weights = array![[0.4, 0.1]];
    let wide_applied = applied_gradient(&x, &wide_target, &wide_weights);
    let wide_numeric = numeric_gradient(&x, &wide_target, &wide_weights);
    println!("\n== the same layer with two output columns");
    println!(
        "  measured gradient {}",
        fmt_vec(wide_numeric.iter().copied(), 6)
    );
    println!(
        "  backward subtracts {}",
        fmt_vec(wide_applied.iter().copied(), 6)
    );
    println!(
        "  ratios {}",
        fmt_vec(
            wide_numeric
                .iter()
                .zip(wide_applied.iter())
                .map(|(n, a)| n / a),
            4
        )
    );

    // 4. Dense::new has no seed
    let (a, b) = (Dense::new(3, 2), Dense::new(3, 2));
    println!("\n== Dense::new(3, 2) twice in the same run");
    println!(
        "  the two weight matrices are equal: {}",
        a.weights == b.weights
    );
    println!(
        "  all zero biases: {}, weights are public, so a course can overwrite them",
        a.bias.iter().all(|&v| v == 0.0)
    );

    // 5. Exclusive or: the smallest problem a straight line cannot solve
    let xor = array![[0.0, 0.0], [0.0, 1.0], [1.0, 0.0], [1.0, 1.0]];
    let xor_y = array![[0.0], [1.0], [1.0], [0.0]];
    println!("\n== exclusive or");

    let mut hand = TwoLayer::fixed(2, 4, 1);
    let history = hand.fit(&xor, &xor_y, 50_000, 0.5);
    println!(
        "  hand, two affine layers with a sigmoid between them: loss {:.8} -> {:.8}",
        history[0],
        history[history.len() - 1]
    );
    println!(
        "  predictions {}",
        fmt_vec(hand.predict(&xor).iter().copied(), 4)
    );

    let first = fixed_dense(
        2,
        4,
        &Array2::from_shape_fn((2, 4), |(i, j)| 0.5 - 0.25 * (i + j) as f64),
    );
    let second = fixed_dense(
        4,
        1,
        &Array2::from_shape_fn((4, 1), |(i, _)| 0.4 - 0.2 * i as f64),
    );
    let mut stack = Sequential::new()
        .push(Box::new(first))
        .push(Box::new(second));
    let ix_history = stack.fit(&xor, &xor_y, 50_000, 0.5, ix_mse_loss, ix_mse_gradient);
    let ix_predictions = stack.forward(&xor);
    println!(
        "  ix_nn, two Dense layers and nothing between them: loss {:.8} -> {:.8}",
        ix_history[0],
        ix_history[ix_history.len() - 1]
    );
    println!(
        "  predictions {}",
        fmt_vec(ix_predictions.iter().copied(), 4)
    );
    println!(
        "  f(0,0) + f(1,1) - f(0,1) - f(1,0) = {:.2e}: the stack is one affine map",
        ix_predictions[[0, 0]] + ix_predictions[[3, 0]]
            - ix_predictions[[1, 0]]
            - ix_predictions[[2, 0]]
    );
    println!("  the only impl of the Layer trait in ix-nn is Dense");
}
