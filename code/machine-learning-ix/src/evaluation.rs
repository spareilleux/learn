//! Lesson 1: splitting, scaling and scoring, written by hand.

use ndarray::{Array1, Array2, Axis};

/// Chronological split: the first rows train, the last `test_ratio` of them test.
/// Same test size as `ix_math::preprocessing::train_test_split`, which shuffles instead.
pub fn split_last(n: usize, test_ratio: f64) -> (Vec<usize>, Vec<usize>) {
    let n_test = ((n as f64 * test_ratio).round() as usize).clamp(1, n - 1);
    ((0..n - n_test).collect(), (n - n_test..n).collect())
}

pub fn mean(y: &Array1<f64>) -> f64 {
    y.sum() / y.len() as f64
}

/// Population standard deviation (divides by n, like numpy's default and IX's `StandardScaler`)
pub fn std_dev(y: &Array1<f64>) -> f64 {
    let m = mean(y);
    (y.iter().map(|v| (v - m).powi(2)).sum::<f64>() / y.len() as f64).sqrt()
}

/// z = (x - mean) / std per column, with the mean and std of the training rows only.
pub struct Scaler {
    pub means: Array1<f64>,
    pub stds: Array1<f64>,
}

impl Scaler {
    pub fn fit(x: &Array2<f64>) -> Scaler {
        let means = x.axis_iter(Axis(1)).map(|c| mean(&c.to_owned())).collect();
        // A constant column would divide by zero: keep it as it is
        let stds = x
            .axis_iter(Axis(1))
            .map(|c| std_dev(&c.to_owned()))
            .map(|s| if s == 0.0 { 1.0 } else { s })
            .collect();
        Scaler { means, stds }
    }

    pub fn transform(&self, x: &Array2<f64>) -> Array2<f64> {
        (x - &self.means) / &self.stds
    }
}

// Regression metrics: y are the true values, p the predictions

pub fn mse(y: &Array1<f64>, p: &Array1<f64>) -> f64 {
    y.iter().zip(p).map(|(a, b)| (a - b).powi(2)).sum::<f64>() / y.len() as f64
}

pub fn mae(y: &Array1<f64>, p: &Array1<f64>) -> f64 {
    y.iter().zip(p).map(|(a, b)| (a - b).abs()).sum::<f64>() / y.len() as f64
}

/// 1 - (squared error of the model) / (squared error of predicting the mean of y)
pub fn r2(y: &Array1<f64>, p: &Array1<f64>) -> f64 {
    let m = mean(y);
    let residual: f64 = y.iter().zip(p).map(|(a, b)| (a - b).powi(2)).sum();
    let total: f64 = y.iter().map(|a| (a - m).powi(2)).sum();
    1.0 - residual / total
}

// Classification metrics: labels are class indices 0..k

/// `m[[t, p]]` counts the rows of true class t predicted as p.
pub fn confusion(y: &Array1<usize>, p: &Array1<usize>, k: usize) -> Array2<usize> {
    let mut m = Array2::zeros((k, k));
    for (&t, &q) in y.iter().zip(p) {
        m[[t, q]] += 1;
    }
    m
}

pub fn accuracy(y: &Array1<usize>, p: &Array1<usize>) -> f64 {
    y.iter().zip(p).filter(|(a, b)| a == b).count() as f64 / y.len() as f64
}

/// (precision, recall, F1) of class c; 0 when a denominator is 0, as IX and scikit-learn do.
pub fn precision_recall_f1(m: &Array2<usize>, c: usize) -> (f64, f64, f64) {
    let tp = m[[c, c]] as f64;
    let predicted = m.column(c).sum() as f64;
    let actual = m.row(c).sum() as f64;
    let ratio = |a: f64, b: f64| if b == 0.0 { 0.0 } else { a / b };
    let (precision, recall) = (ratio(tp, predicted), ratio(tp, actual));
    (
        precision,
        recall,
        ratio(2.0 * precision * recall, precision + recall),
    )
}

#[cfg(test)]
mod tests {
    use super::*;
    use ndarray::array;

    #[test]
    fn perfect_and_mean_predictions() {
        let y = array![1.0, 2.0, 3.0];
        assert_eq!(r2(&y, &y), 1.0);
        assert_eq!(r2(&y, &array![2.0, 2.0, 2.0]), 0.0);
        assert!((mse(&y, &array![2.0, 2.0, 2.0]) - 2.0 / 3.0).abs() < 1e-15);
    }

    #[test]
    fn confusion_and_scores() {
        let m = confusion(&array![0, 0, 1, 1], &array![0, 1, 1, 1], 2);
        assert_eq!(m, array![[1, 1], [0, 2]]);
        let (p, r, f) = precision_recall_f1(&m, 1);
        assert_eq!((p, r), (2.0 / 3.0, 1.0));
        assert!((f - 0.8).abs() < 1e-15);
    }

    #[test]
    fn scaler_uses_training_statistics() {
        let s = Scaler::fit(&array![[1.0], [3.0]]);
        assert_eq!(s.transform(&array![[5.0]]), array![[3.0]]);
    }

    #[test]
    fn split_keeps_order() {
        assert_eq!(split_last(5, 0.2), (vec![0, 1, 2, 3], vec![4]));
    }
}
