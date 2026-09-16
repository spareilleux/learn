//! Lesson 8: the three update rules that move a parameter vector downhill — plain descent,
//! momentum and Adam — and the test function that tells them apart.

use ndarray::Array1;

/// Rosenbrock's function, `(a - x)² + b (y - x²)²` with `a = 1`, `b = 100`. Its minimum is 0 at
/// `(1, 1)`, at the bottom of a curved valley whose floor is almost flat: the classic way to see
/// a method follow a ridge instead of the slope.
pub fn rosenbrock(v: &Array1<f64>) -> f64 {
    let (x, y) = (v[0], v[1]);
    (1.0 - x).powi(2) + 100.0 * (y - x * x).powi(2)
}

/// The gradient of [`rosenbrock`], written out rather than measured.
pub fn rosenbrock_gradient(v: &Array1<f64>) -> Array1<f64> {
    let (x, y) = (v[0], v[1]);
    Array1::from_vec(vec![
        -2.0 * (1.0 - x) - 400.0 * x * (y - x * x),
        200.0 * (y - x * x),
    ])
}

/// One step of plain gradient descent: `p - lr · g`.
pub struct Sgd {
    pub learning_rate: f64,
}

/// Descent with memory: a running average of past gradients carries the step through flat parts.
pub struct Momentum {
    pub learning_rate: f64,
    pub momentum: f64,
    velocity: Option<Array1<f64>>,
}

/// Adam: a running mean of the gradient divided by the running root mean square of the gradient,
/// each corrected for starting at zero. Every coordinate gets its own step size.
pub struct Adam {
    pub learning_rate: f64,
    pub beta1: f64,
    pub beta2: f64,
    pub epsilon: f64,
    mean: Option<Array1<f64>>,
    square: Option<Array1<f64>>,
    steps: usize,
}

/// One update rule.
pub trait Step {
    fn step(&mut self, params: &Array1<f64>, gradient: &Array1<f64>) -> Array1<f64>;
    fn name(&self) -> &'static str;
}

impl Step for Sgd {
    fn step(&mut self, params: &Array1<f64>, gradient: &Array1<f64>) -> Array1<f64> {
        params - &(self.learning_rate * gradient)
    }
    fn name(&self) -> &'static str {
        "SGD"
    }
}

impl Momentum {
    pub fn new(learning_rate: f64, momentum: f64) -> Momentum {
        Momentum {
            learning_rate,
            momentum,
            velocity: None,
        }
    }
}

impl Step for Momentum {
    fn step(&mut self, params: &Array1<f64>, gradient: &Array1<f64>) -> Array1<f64> {
        let velocity = match &self.velocity {
            Some(v) => self.momentum * v + self.learning_rate * gradient,
            None => self.learning_rate * gradient.clone(),
        };
        let next = params - &velocity;
        self.velocity = Some(velocity);
        next
    }
    fn name(&self) -> &'static str {
        "Momentum"
    }
}

impl Adam {
    pub fn new(learning_rate: f64) -> Adam {
        Adam {
            learning_rate,
            beta1: 0.9,
            beta2: 0.999,
            epsilon: 1e-8,
            mean: None,
            square: None,
            steps: 0,
        }
    }
}

impl Step for Adam {
    fn step(&mut self, params: &Array1<f64>, gradient: &Array1<f64>) -> Array1<f64> {
        self.steps += 1;
        let t = self.steps as f64;
        let mean = match &self.mean {
            Some(m) => self.beta1 * m + (1.0 - self.beta1) * gradient,
            None => (1.0 - self.beta1) * gradient.clone(),
        };
        let square = match &self.square {
            Some(v) => self.beta2 * v + (1.0 - self.beta2) * &gradient.mapv(|g| g * g),
            None => (1.0 - self.beta2) * gradient.mapv(|g| g * g),
        };
        // Both averages start at zero, so early steps are too small: divide the bias away
        let mean_hat = &mean / (1.0 - self.beta1.powf(t));
        let square_hat = &square / (1.0 - self.beta2.powf(t));
        let next = params
            - &(self.learning_rate * &mean_hat / &(square_hat.mapv(f64::sqrt) + self.epsilon));
        self.mean = Some(mean);
        self.square = Some(square);
        next
    }
    fn name(&self) -> &'static str {
        "Adam"
    }
}

/// Where the run ended, and the best point it passed through on the way.
pub struct Run {
    pub last: Array1<f64>,
    pub last_value: f64,
    pub best: Array1<f64>,
    pub best_value: f64,
    pub steps: usize,
}

/// Follow `gradient` downhill from `start` for at most `max_steps`, stopping when the gradient
/// is shorter than `tolerance`. Keeps both the last point and the best one seen.
pub fn descend(
    value: impl Fn(&Array1<f64>) -> f64,
    gradient: impl Fn(&Array1<f64>) -> Array1<f64>,
    rule: &mut dyn Step,
    start: Array1<f64>,
    max_steps: usize,
    tolerance: f64,
) -> Run {
    let mut params = start;
    let mut best = params.clone();
    let mut best_value = value(&params);
    let mut steps = 0;
    for i in 0..max_steps {
        let g = gradient(&params);
        steps = i + 1;
        if g.dot(&g).sqrt() < tolerance {
            break;
        }
        params = rule.step(&params, &g);
        let v = value(&params);
        if v < best_value {
            best_value = v;
            best = params.clone();
        }
    }
    Run {
        last_value: value(&params),
        last: params,
        best,
        best_value,
        steps,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use ndarray::array;

    #[test]
    fn rosenbrock_is_zero_at_its_minimum() {
        assert_eq!(rosenbrock(&array![1.0, 1.0]), 0.0);
        assert_eq!(rosenbrock_gradient(&array![1.0, 1.0]), array![0.0, 0.0]);
    }

    #[test]
    fn the_written_gradient_matches_finite_differences() {
        let point = array![-0.4, 0.8];
        let numeric: Vec<f64> = (0..2)
            .map(|i| {
                let (mut up, mut down) = (point.clone(), point.clone());
                up[i] += 1e-6;
                down[i] -= 1e-6;
                (rosenbrock(&up) - rosenbrock(&down)) / 2e-6
            })
            .collect();
        let analytic = rosenbrock_gradient(&point);
        assert!((analytic[0] - numeric[0]).abs() < 1e-5);
        assert!((analytic[1] - numeric[1]).abs() < 1e-5);
    }

    #[test]
    fn adam_reaches_the_valley_floor_where_descent_crawls() {
        let start = array![-1.2, 1.0];
        let mut adam = Adam::new(0.05);
        let with_adam = descend(
            rosenbrock,
            rosenbrock_gradient,
            &mut adam,
            start.clone(),
            5000,
            1e-8,
        );
        let mut sgd = Sgd {
            learning_rate: 0.001,
        };
        let with_sgd = descend(rosenbrock, rosenbrock_gradient, &mut sgd, start, 5000, 1e-8);
        assert!(with_adam.best_value < with_sgd.best_value);
    }
}
