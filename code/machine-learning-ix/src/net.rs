//! Lesson 7: a neural network small enough to differentiate by hand — an affine layer, a
//! squashing function, the chain rule backwards, and finite differences as the judge.

use ndarray::{Array1, Array2, Axis};

/// An affine layer: `y = x W + b`. The gradients come back from `backward`, and nothing is
/// updated behind your back — `ix_nn::layer::Dense` both scales and applies them itself.
pub struct Linear {
    pub weights: Array2<f64>,
    pub bias: Array1<f64>,
}

/// The gradients of one affine layer.
pub struct LinearGrads {
    pub weights: Array2<f64>,
    pub bias: Array1<f64>,
    /// Gradient with respect to the layer's input, the message passed to the layer before it
    pub input: Array2<f64>,
}

impl Linear {
    /// Weights spread evenly over `[-limit, limit]` by a fixed rule rather than a random draw,
    /// so that two runs of this course print the same numbers.
    pub fn fixed(input_size: usize, output_size: usize, limit: f64) -> Linear {
        let cells = (input_size * output_size) as f64;
        let weights = Array2::from_shape_fn((input_size, output_size), |(i, j)| {
            let k = (i * output_size + j) as f64;
            limit * (2.0 * k / (cells - 1.0).max(1.0) - 1.0)
        });
        Linear {
            weights,
            bias: Array1::zeros(output_size),
        }
    }

    pub fn forward(&self, x: &Array2<f64>) -> Array2<f64> {
        x.dot(&self.weights) + &self.bias
    }

    /// The chain rule for `y = x W + b`: `dL/dW = xᵀ (dL/dy)`, `dL/db` sums the rows of `dL/dy`,
    /// and `dL/dx = (dL/dy) Wᵀ`. No division by the batch size: whatever averaging the loss
    /// wants is already inside `grad_output`.
    pub fn backward(&self, x: &Array2<f64>, grad_output: &Array2<f64>) -> LinearGrads {
        LinearGrads {
            weights: x.t().dot(grad_output),
            bias: grad_output.sum_axis(Axis(0)),
            input: grad_output.dot(&self.weights.t()),
        }
    }

    pub fn step(&mut self, grads: &LinearGrads, learning_rate: f64) {
        self.weights = &self.weights - &(learning_rate * &grads.weights);
        self.bias = &self.bias - &(learning_rate * &grads.bias);
    }
}

pub fn sigmoid(z: f64) -> f64 {
    1.0 / (1.0 + (-z).exp())
}

/// `σ'(z) = σ(z)·(1 - σ(z))`, written from the value of σ so it needs no second exponential.
pub fn sigmoid_prime_from_value(s: f64) -> f64 {
    s * (1.0 - s)
}

/// Mean squared error over every cell of the matrix, the definition `ix_nn::loss::mse_loss` uses.
pub fn mse(predicted: &Array2<f64>, target: &Array2<f64>) -> f64 {
    (predicted - target).mapv(|v| v * v).mean().unwrap()
}

/// The true gradient of [`mse`]: `2 (p - t) / (rows × columns)`.
pub fn mse_gradient(predicted: &Array2<f64>, target: &Array2<f64>) -> Array2<f64> {
    let cells = (predicted.nrows() * predicted.ncols()) as f64;
    2.0 * (predicted - target) / cells
}

/// A layer of `hidden` sigmoid units between two affine layers — the smallest network that is
/// not a straight line.
pub struct TwoLayer {
    pub first: Linear,
    pub second: Linear,
}

impl TwoLayer {
    pub fn fixed(inputs: usize, hidden: usize, outputs: usize) -> TwoLayer {
        TwoLayer {
            first: Linear::fixed(inputs, hidden, 1.0),
            second: Linear::fixed(hidden, outputs, 1.0),
        }
    }

    /// Returns the hidden activations and the output.
    pub fn forward(&self, x: &Array2<f64>) -> (Array2<f64>, Array2<f64>) {
        let hidden = self.first.forward(x).mapv(sigmoid);
        let output = self.second.forward(&hidden);
        (hidden, output)
    }

    pub fn predict(&self, x: &Array2<f64>) -> Array2<f64> {
        self.forward(x).1
    }

    /// One full-batch step on the mean squared error. Returns the loss before the step.
    pub fn train_step(&mut self, x: &Array2<f64>, target: &Array2<f64>, learning_rate: f64) -> f64 {
        let (hidden, output) = self.forward(x);
        let loss = mse(&output, target);
        let grad_output = mse_gradient(&output, target);
        let second = self.second.backward(&hidden, &grad_output);
        // Through the sigmoid: multiply by σ'(z), which the activations already give us
        let grad_hidden = &second.input * &hidden.mapv(sigmoid_prime_from_value);
        let first = self.first.backward(x, &grad_hidden);
        self.second.step(&second, learning_rate);
        self.first.step(&first, learning_rate);
        loss
    }

    pub fn fit(
        &mut self,
        x: &Array2<f64>,
        target: &Array2<f64>,
        epochs: usize,
        learning_rate: f64,
    ) -> Vec<f64> {
        (0..epochs)
            .map(|_| self.train_step(x, target, learning_rate))
            .collect()
    }
}

/// The numeric gradient of `loss` at `values`, by the central difference
/// `(f(v + h) - f(v - h)) / 2h`. Slow, but it knows nothing about the chain rule, which makes it
/// the right judge of a hand-written `backward`.
pub fn finite_difference(values: &[f64], h: f64, mut loss: impl FnMut(&[f64]) -> f64) -> Vec<f64> {
    let mut gradient = Vec::with_capacity(values.len());
    let mut probe = values.to_vec();
    for i in 0..values.len() {
        let original = probe[i];
        probe[i] = original + h;
        let up = loss(&probe);
        probe[i] = original - h;
        let down = loss(&probe);
        probe[i] = original;
        gradient.push((up - down) / (2.0 * h));
    }
    gradient
}

/// The largest gap between two vectors, the usual way a gradient check is reported.
pub fn largest_gap(a: &[f64], b: &[f64]) -> f64 {
    a.iter()
        .zip(b)
        .map(|(u, v)| (u - v).abs())
        .fold(0.0f64, f64::max)
}

#[cfg(test)]
mod tests {
    use super::*;
    use ndarray::array;

    #[test]
    fn backward_agrees_with_finite_differences() {
        let x = array![[1.0, 2.0], [-1.0, 0.5], [0.3, 0.7]];
        let target = array![[1.0], [0.0], [1.0]];
        let layer = Linear::fixed(2, 1, 1.0);
        let grads = layer.backward(&x, &mse_gradient(&layer.forward(&x), &target));

        let start: Vec<f64> = layer.weights.iter().copied().collect();
        let numeric = finite_difference(&start, 1e-6, |v| {
            let probe = Linear {
                weights: Array2::from_shape_vec((2, 1), v.to_vec()).unwrap(),
                bias: layer.bias.clone(),
            };
            mse(&probe.forward(&x), &target)
        });
        let analytic: Vec<f64> = grads.weights.iter().copied().collect();
        assert!(largest_gap(&analytic, &numeric) < 1e-8);
    }

    #[test]
    fn two_layers_with_a_sigmoid_learn_exclusive_or() {
        let x = array![[0.0, 0.0], [0.0, 1.0], [1.0, 0.0], [1.0, 1.0]];
        let y = array![[0.0], [1.0], [1.0], [0.0]];
        let mut net = TwoLayer::fixed(2, 4, 1);
        net.fit(&x, &y, 50_000, 0.5);
        let p = net.predict(&x);
        for i in 0..4 {
            assert_eq!(p[[i, 0]] > 0.5, y[[i, 0]] > 0.5, "row {i}: {}", p[[i, 0]]);
        }
    }

    #[test]
    fn without_a_sigmoid_a_stack_stays_affine() {
        // Two affine layers compose into one: f(a) + f(d) = f(b) + f(c) whenever a + d = b + c
        let first = Linear::fixed(2, 3, 1.0);
        let second = Linear::fixed(3, 1, 1.0);
        let through = |row: Array2<f64>| second.forward(&first.forward(&row))[[0, 0]];
        let corners = array![[0.0, 0.0], [0.0, 1.0], [1.0, 0.0], [1.0, 1.0]];
        let f = |i: usize| through(corners.row(i).to_owned().insert_axis(Axis(0)));
        assert!((f(0) + f(3) - f(1) - f(2)).abs() < 1e-12);
    }
}
