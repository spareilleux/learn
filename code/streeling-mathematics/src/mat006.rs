//! MAT-006, the SVD: IX's one-sided Jacobi `svd` checked against Eckart–Young, across scales from 10^-14 to
//! 10^12, and on MAT-003's scaled Hilbert matrices with a capped number of sweeps. Pre-registered in
//! preregistration-mat006.md. Norms and errors are computed here with plain loops, without IX.

use ix_math::svd::{SvdResult, svd, svd_with_opts, truncated_svd};
use ndarray::{Array2, array};

/// A = [[1, 2], [3, 4], [5, 6]], the matrix of IX's rank-1 truncation test.
pub fn matrix_a() -> Array2<f64> {
    array![[1.0, 2.0], [3.0, 4.0], [5.0, 6.0]]
}

/// M = [[1, 2, 3], [4, 5, 6], [7, 8, 10]], the matrix of IX's `ix_svd` MCP test; det M = -3.
pub fn matrix_m() -> Array2<f64> {
    array![[1.0, 2.0, 3.0], [4.0, 5.0, 6.0], [7.0, 8.0, 10.0]]
}

/// sqrt of the sum of squares, in row-major order.
pub fn frobenius(a: &Array2<f64>) -> f64 {
    a.iter().map(|x| x * x).sum::<f64>().sqrt()
}

/// ||a - b||_F, element by element in row-major order.
pub fn frobenius_diff(a: &Array2<f64>, b: &Array2<f64>) -> f64 {
    a.iter()
        .zip(b.iter())
        .map(|(x, y)| (x - y) * (x - y))
        .sum::<f64>()
        .sqrt()
}

/// 10^e, parsed rather than computed, so that it is the correctly rounded value on every platform.
pub fn ten_to(e: i32) -> f64 {
    format!("1e{e}").parse().expect("a decimal power of ten")
}

/// 2^e for |e| < 1022, built from its bits: exact.
pub fn two_to(e: i32) -> f64 {
    f64::from_bits(((1023 + e) as u64) << 52)
}

/// ||svd(b).reconstruct() - b||_F / ||b||_F.
pub fn relative_reconstruction_error(b: &Array2<f64>) -> f64 {
    let r = svd(b).expect("svd of a finite matrix");
    frobenius_diff(&r.reconstruct(), b) / frobenius(b)
}

/// One k of step 1: the truncation error through `truncated_svd` and the Eckart–Young tail from `svd`.
pub struct EckartYoung {
    pub k: usize,
    pub truncation_error: f64,
    pub tail: f64,
}

/// sqrt(sigma_{k+1}^2 + ...), the Eckart–Young error of the best rank-k approximation.
pub fn tail(singular_values: &[f64], k: usize) -> f64 {
    singular_values
        .iter()
        .skip(k)
        .map(|s| s * s)
        .sum::<f64>()
        .sqrt()
}

/// Step 1 for k = 0 ... number of columns.
pub fn eckart_young(x: &Array2<f64>) -> Vec<EckartYoung> {
    let s = svd(x).expect("svd").singular_values.to_vec();
    (0..=x.ncols())
        .map(|k| {
            let approx = truncated_svd(x, k).expect("truncated svd").reconstruct();
            EckartYoung {
                k,
                truncation_error: frobenius_diff(&approx, x),
                tail: tail(&s, k),
            }
        })
        .collect()
}

/// s = 10^-14, 10^-13, ..., 10^12, the scales of step 2.
pub fn scales() -> Vec<(i32, f64)> {
    (-14..=12).map(|e| (e, ten_to(e))).collect()
}

/// One scale of step 2.
pub struct ScaleRow {
    pub exponent: i32,
    /// |sigma_i(s X) / s - sigma_i(X)| / sigma_i(X), for each i.
    pub sigma_relative_errors: Vec<f64>,
    pub reconstruction_error: f64,
    /// Whether each column of U is exactly zero.
    pub u_zero_columns: Vec<bool>,
}

pub fn scale_row(x: &Array2<f64>, exponent: i32, s: f64) -> ScaleRow {
    let base = svd(x).expect("svd").singular_values;
    let scaled = x.mapv(|v| v * s);
    let r = svd(&scaled).expect("svd of the scaled matrix");
    ScaleRow {
        exponent,
        sigma_relative_errors: r
            .singular_values
            .iter()
            .zip(base.iter())
            .map(|(v, b)| (v / s - b).abs() / b)
            .collect(),
        reconstruction_error: frobenius_diff(&r.reconstruct(), &scaled) / frobenius(&scaled),
        u_zero_columns: (0..r.u.ncols())
            .map(|j| r.u.column(j).iter().all(|&v| v == 0.0))
            .collect(),
    }
}

/// The singular values of `r` divided by `by`, as raw bits.
pub fn singular_value_bits(r: &SvdResult, by: f64) -> Vec<u64> {
    r.singular_values
        .iter()
        .map(|v| (v / by).to_bits())
        .collect()
}

/// One n of step 4.
pub struct PuzzleRow {
    pub n: usize,
    /// Smallest k in 1..=6 for which the capped 2^20 result equals svd(fl(H_n)) bit for bit.
    pub k_matching_scale_1: Option<usize>,
    /// Smallest k in 1..=6 for which it equals svd(2^-20 fl(H_n)) / 2^-20 bit for bit.
    pub k_matching_scale_down: Option<usize>,
    /// Whether svd(fl(H_n)) and svd(2^-20 fl(H_n)) / 2^-20 agree bit for bit.
    pub scale_1_equals_scale_down: bool,
    /// Post hoc, not pre-registered: whether the capped result at the module's predicted k also equals
    /// the scale-1 and the scale-down result, where the smallest matching k is lower than predicted.
    pub predicted_k_also_matches: (bool, bool),
}

/// Step 4: `svd_with_opts(2^20 fl(H_n), k, 1e-12)` for k = 1 ... 6, against the two uncapped results.
pub fn puzzle(n: usize) -> PuzzleRow {
    let h = crate::hilbert(n);
    let (up, down) = (two_to(20), two_to(-20));
    let scale_1 = singular_value_bits(&svd(&h).expect("svd"), 1.0);
    let scale_down = singular_value_bits(&svd(&h.mapv(|v| v * down)).expect("svd"), down);
    let scaled_up = h.mapv(|v| v * up);
    let capped: Vec<Vec<u64>> = (1..=6)
        .map(|k| {
            singular_value_bits(
                &svd_with_opts(&scaled_up, k, 1e-12).expect("capped svd"),
                up,
            )
        })
        .collect();
    let first = |target: &Vec<u64>| capped.iter().position(|c| c == target).map(|i| i + 1);
    let (p1, p2) = predicted_puzzle(n);
    PuzzleRow {
        n,
        k_matching_scale_1: first(&scale_1),
        k_matching_scale_down: first(&scale_down),
        scale_1_equals_scale_down: scale_1 == scale_down,
        predicted_k_also_matches: (capped[p1 - 1] == scale_1, capped[p2 - 1] == scale_down),
    }
}

/// The two values of k that MAT-006 section 7 step 4 predicts for n.
pub fn predicted_puzzle(n: usize) -> (usize, usize) {
    match n {
        2 => (2, 2),
        3..=6 => (4, 3),
        7..=14 => (5, 4),
        _ => (6, 4),
    }
}

/// Step 5, the part without MCP: `rank(1e-10)` and `rank(3 sigma_1 eps)` of svd(1e-12 I_3).
pub fn rank_conventions() -> (usize, usize) {
    let r = svd(&Array2::eye(3).mapv(|v: f64| v * 1e-12)).expect("svd");
    let relative = 3.0 * r.singular_values[0] * f64::EPSILON;
    (r.rank(1e-10), r.rank(relative))
}

/// Step 6: the relative error of `truncated_svd(A, 1)`, which IX's test bounds by 0.10.
pub fn rank_1_relative_error() -> f64 {
    let a = matrix_a();
    let approx = truncated_svd(&a, 1).expect("truncated svd").reconstruct();
    frobenius_diff(&approx, &a) / frobenius(&a)
}
