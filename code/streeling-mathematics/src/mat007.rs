//! MAT-007, least squares: IX's `LinearRegression::fit` (normal equations and an explicit inverse) on offset
//! and nearly collinear designs, against the SVD route through `pseudo_inverse`. Pre-registered in
//! preregistration-mat007.md; every fixture has its exact answer in closed form, so no oracle needs IX.

use crate::max_or_nan;
use ix_math::svd::svd;
use ix_supervised::linear_regression::LinearRegression;
use ix_supervised::traits::Regressor;
use ndarray::{Array1, Array2};
use std::panic::{self, AssertUnwindSafe};

/// What `fit` returned, or the message of the panic it raised.
#[derive(Debug, Clone, PartialEq)]
pub enum Fit {
    Params { weights: Vec<f64>, bias: f64 },
    Panicked(String),
}

impl Fit {
    /// The first weight (the slope, for one feature) and the bias, or `None` after a panic.
    pub fn slope_and_bias(&self) -> Option<(f64, f64)> {
        match self {
            Fit::Params { weights, bias } => Some((weights[0], *bias)),
            Fit::Panicked(_) => None,
        }
    }
}

/// The message of the lab's own control panic, which `silence_fit_panics` also keeps quiet.
pub const CONTROL_PANIC: &str = "lab control panic";

/// Keeps the default panic report for everything except a panic raised inside `linear_regression.rs`,
/// which `ix_fit` catches and records, and the lab's control panic. Their default report would print a
/// source path, which differs between machines and would break the comparison with expected/.
pub fn silence_fit_panics() {
    static INSTALL: std::sync::Once = std::sync::Once::new();
    INSTALL.call_once(|| {
        let default = panic::take_hook();
        panic::set_hook(Box::new(move |info| {
            let from_fit = info
                .location()
                .is_some_and(|l| l.file().ends_with("linear_regression.rs"));
            let control = info.payload().downcast_ref::<&str>() == Some(&CONTROL_PANIC);
            if !from_fit && !control {
                default(info);
            }
        }));
    });
}

/// Runs a closure and returns the message of its panic, if it panics.
pub fn catch_panic<T>(f: impl FnOnce() -> T) -> Result<T, String> {
    panic::catch_unwind(AssertUnwindSafe(f)).map_err(|payload| {
        if let Some(s) = payload.downcast_ref::<&str>() {
            (*s).to_string()
        } else if let Some(s) = payload.downcast_ref::<String>() {
            s.clone()
        } else {
            "<non-string panic payload>".to_string()
        }
    })
}

/// `LinearRegression::fit`, with its panic (`.expect("X^T X is singular")`, linear_regression.rs:68) caught.
pub fn ix_fit(x: &Array2<f64>, y: &Array1<f64>) -> Fit {
    match catch_panic(|| {
        let mut model = LinearRegression::new();
        model.fit(x, y);
        let weights = model
            .weights
            .as_ref()
            .expect("fit sets the weights")
            .to_vec();
        (weights, model.bias)
    }) {
        Ok((weights, bias)) => Fit::Params { weights, bias },
        Err(message) => Fit::Panicked(message),
    }
}

/// c = 10^0 … 10^7, the offsets of step 1. Powers of ten below 10^23 are exact in f64.
pub fn offsets() -> Vec<f64> {
    (0..=7).map(|k| 10f64.powi(k)).collect()
}

/// x = c + (0, 1, 2) and y = 2x + 1. Every value is an integer below 2^53, so the data are exact.
pub fn offset_data(c: f64) -> (Array2<f64>, Array1<f64>) {
    let x = Array2::from_shape_fn((3, 1), |(i, _)| c + i as f64);
    let y = x.column(0).mapv(|v| 2.0 * v + 1.0);
    (x, y)
}

/// The same observations on the centered feature (-1, 0, 1). Exact answer: slope 2, bias 2c + 3.
pub fn centered_data(c: f64) -> (Array2<f64>, Array1<f64>) {
    let (_, y) = offset_data(c);
    let x = Array2::from_shape_fn((3, 1), |(i, _)| i as f64 - 1.0);
    (x, y)
}

/// The largest |w·x_i + bias - y_i| over the observations, with plain loops in a fixed order.
pub fn max_fit_error(x: &Array2<f64>, y: &Array1<f64>, weights: &[f64], bias: f64) -> f64 {
    (0..x.nrows())
        .map(|i| {
            let fitted: f64 = (0..x.ncols()).map(|j| weights[j] * x[[i, j]]).sum::<f64>() + bias;
            (fitted - y[i]).abs()
        })
        .fold(0.0, max_or_nan)
}

/// N = 10^0 … 10^7, the scales of step 2.
pub fn scales() -> Vec<f64> {
    (0..=7).map(|k| 10f64.powi(k)).collect()
}

/// x1 = N (1, 2, 3, 4), x2 = x1 + (1, -1, -1, 1), y = x1 + x2 + 1. Exact: weights (1, 1), bias 1.
pub fn collinear_data(n: f64) -> (Array2<f64>, Array1<f64>) {
    let bump = [1.0, -1.0, -1.0, 1.0];
    let x = Array2::from_shape_fn((4, 2), |(i, j)| {
        let x1 = n * (i + 1) as f64;
        if j == 0 { x1 } else { x1 + bump[i] }
    });
    let y = Array1::from_shape_fn(4, |i| x[[i, 0]] + x[[i, 1]] + 1.0);
    (x, y)
}

/// The largest of |w_j - 1| and |bias - 1|: the error against the exact answer of `collinear_data`.
pub fn param_error(weights: &[f64], bias: f64) -> f64 {
    weights
        .iter()
        .map(|w| (w - 1.0).abs())
        .fold((bias - 1.0).abs(), max_or_nan)
}

/// The SVD route of step 2, and IX's kappa_2 of the design.
pub struct SvdRoute {
    pub weights: Vec<f64>,
    pub bias: f64,
    pub kappa2: f64,
    pub tol: f64,
}

/// Least squares through IX's `svd`: the design [x | 1] as `fit` builds it, `pseudo_inverse` at
/// tol = max(m, n) * sigma_1 * f64::EPSILON (the tolerance of MAT-006), times y.
pub fn svd_route(x: &Array2<f64>, y: &Array1<f64>) -> SvdRoute {
    let (m, p) = x.dim();
    let design = Array2::from_shape_fn((m, p + 1), |(i, j)| if j < p { x[[i, j]] } else { 1.0 });
    let decomposition = svd(&design).expect("svd of a finite design");
    let s = &decomposition.singular_values;
    let tol = m.max(p + 1) as f64 * s[0] * f64::EPSILON;
    let pinv = decomposition.pseudo_inverse(tol);
    let w: Vec<f64> = (0..p + 1)
        .map(|j| (0..m).map(|i| pinv[[j, i]] * y[i]).sum())
        .collect();
    SvdRoute {
        weights: w[..p].to_vec(),
        bias: w[p],
        kappa2: s[0] / s[s.len() - 1],
        tol,
    }
}
