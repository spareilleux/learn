//! Lesson 2: a straight line y = w·x + b, fitted two ways by hand.

use ndarray::Array1;

/// Least squares in one variable: w = cov(x, y) / var(x), b = mean(y) - w·mean(x).
pub fn fit_closed_form(x: &Array1<f64>, y: &Array1<f64>) -> (f64, f64) {
    let n = x.len() as f64;
    let (mx, my) = (x.sum() / n, y.sum() / n);
    let cov: f64 = x.iter().zip(y).map(|(a, b)| (a - mx) * (b - my)).sum();
    let var: f64 = x.iter().map(|a| (a - mx).powi(2)).sum();
    let w = cov / var;
    (w, my - w * mx)
}

/// One gradient step on the mean squared error L(w, b) = 1/n Σ (w·x + b - y)².
/// dL/dw = 2/n Σ (w·x + b - y)·x and dL/db = 2/n Σ (w·x + b - y).
pub fn gradient_step(
    x: &Array1<f64>,
    y: &Array1<f64>,
    w: f64,
    b: f64,
    learning_rate: f64,
) -> (f64, f64) {
    let n = x.len() as f64;
    let (mut dw, mut db) = (0.0, 0.0);
    for (xi, yi) in x.iter().zip(y) {
        let error = w * xi + b - yi;
        dw += 2.0 * error * xi / n;
        db += 2.0 * error / n;
    }
    (w - learning_rate * dw, b - learning_rate * db)
}

pub fn loss(x: &Array1<f64>, y: &Array1<f64>, w: f64, b: f64) -> f64 {
    x.iter()
        .zip(y)
        .map(|(xi, yi)| (w * xi + b - yi).powi(2))
        .sum::<f64>()
        / x.len() as f64
}

#[cfg(test)]
mod tests {
    use super::*;
    use ndarray::array;

    #[test]
    fn exact_line() {
        let (w, b) = fit_closed_form(&array![1.0, 2.0, 3.0], &array![3.0, 5.0, 7.0]);
        assert!((w - 2.0).abs() < 1e-12 && (b - 1.0).abs() < 1e-12);
    }

    #[test]
    fn descent_reaches_the_closed_form() {
        let (x, y) = (array![0.0, 1.0, 2.0, 3.0], array![1.0, 2.0, 2.0, 4.0]);
        let (mut w, mut b) = (0.0, 0.0);
        for _ in 0..5000 {
            (w, b) = gradient_step(&x, &y, w, b, 0.05);
        }
        let (cw, cb) = fit_closed_form(&x, &y);
        assert!((w - cw).abs() < 1e-9 && (b - cb).abs() < 1e-9);
    }
}
