//! Code behind the Streeling mathematics modules, measured against IX `ix-math` pinned at `e35138b9`.
//!
//! MAT-003, floating-point arithmetic and conditioning: Hilbert matrices H_n[i][j] = 1/(i+j-1) are
//! inverted by `ix_math::linalg::inverse` and pseudo-inverted through `ix_math::svd`, and every result
//! is judged against the exact inverse, computed here in integers without IX.
//!
//! MAT-006, the SVD: the module `mat006`. MAT-007, least squares: the module `mat007`.

pub mod mat006;
pub mod mat007;

use ix_math::error::MathError;
use ix_math::linalg::inverse;
use ix_math::svd::svd;
use ndarray::Array2;

/// Unit roundoff of IEEE 754 binary64: u = 2^-53, half of `f64::EPSILON`.
pub const U: f64 = f64::EPSILON / 2.0;

/// `inverse` refuses when the largest remaining pivot is below this absolute value (linalg.rs:110 at the pin).
pub const IX_PIVOT_THRESHOLD: f64 = 1e-12;

/// The MCP `ix_svd` handler keeps the singular values above sigma_1 times this (handlers.rs:639 at the pin).
pub const MCP_RANK_FACTOR: f64 = 1e-10;

/// The Hilbert matrix of size n, rounded to f64: what IX receives is fl(H_n), not H_n.
pub fn hilbert(n: usize) -> Array2<f64> {
    Array2::from_shape_fn((n, n), |(i, j)| 1.0 / (i + j + 1) as f64)
}

fn binomial(n: i128, k: i128) -> i128 {
    if k < 0 || k > n {
        return 0;
    }
    let k = k.min(n - k);
    let mut r = 1i128;
    for i in 0..k {
        r = r * (n - i) / (i + 1);
    }
    r
}

/// The exact inverse of H_n, from the closed form with integer entries (Choi 1983). Exact up to n = 16.
pub fn exact_hilbert_inverse(n: usize) -> Vec<Vec<i128>> {
    let m = n as i128;
    (1..=m)
        .map(|i| {
            (1..=m)
                .map(|j| {
                    let sign = if (i + j) % 2 == 0 { 1 } else { -1 };
                    let c = binomial(i + j - 2, i - 1);
                    sign * (i + j - 1)
                        * binomial(m + i - 1, m - j)
                        * binomial(m + j - 1, m - i)
                        * c
                        * c
                })
                .collect()
        })
        .collect()
}

fn gcd(a: i128, b: i128) -> i128 {
    if b == 0 { a } else { gcd(b, a % b) }
}

/// Checks H_n * inv = I in exact integer arithmetic, scaling every 1/(i+j-1) by lcm(1..2n-1).
/// Returns `None` if an intermediate would overflow i128, so an overflow is never read as a verdict.
pub fn exact_identity_holds(inv: &[Vec<i128>]) -> Option<bool> {
    let n = inv.len() as i128;
    let lcm = (1..2 * n).fold(1i128, |l, k| l / gcd(l, k) * k);
    for i in 0..n {
        for j in 0..n {
            let mut sum = 0i128;
            for k in 0..n {
                let term = (lcm / (i + k + 1)).checked_mul(inv[k as usize][j as usize])?;
                sum = sum.checked_add(term)?;
            }
            if sum != if i == j { lcm } else { 0 } {
                return Some(false);
            }
        }
    }
    Some(true)
}

/// The exact inverse rounded to f64, divided by `scale`: the inverse of scale * H_n.
pub fn exact_inverse_f64(n: usize, scale: f64) -> Array2<f64> {
    let inv = exact_hilbert_inverse(n);
    Array2::from_shape_fn((n, n), |(i, j)| inv[i][j] as f64 / scale)
}

/// Maximum absolute row sum.
pub fn norm_inf(a: &Array2<f64>) -> f64 {
    a.rows()
        .into_iter()
        .map(|r| r.iter().map(|x| x.abs()).sum::<f64>())
        .fold(0.0, f64::max)
}

/// Plain triple loop, so the order of the sums is fixed and the checker does not depend on IX.
pub fn matmul(a: &Array2<f64>, b: &Array2<f64>) -> Array2<f64> {
    let (n, k, m) = (a.nrows(), a.ncols(), b.ncols());
    Array2::from_shape_fn((n, m), |(i, j)| (0..k).map(|t| a[[i, t]] * b[[t, j]]).sum())
}

/// ||A X - I|| in the infinity norm.
pub fn residual(a: &Array2<f64>, x: &Array2<f64>) -> f64 {
    let mut r = matmul(a, x);
    for i in 0..r.nrows() {
        r[[i, i]] -= 1.0;
    }
    norm_inf(&r)
}

/// ||X - exact|| / ||exact|| in the infinity norm.
pub fn forward_error(x: &Array2<f64>, exact: &Array2<f64>) -> f64 {
    norm_inf(&(x - exact)) / norm_inf(exact)
}

/// kappa_inf(H_n) = ||H_n|| * ||H_n^-1||, the second factor from the exact inverse.
pub fn kappa_inf_exact(n: usize) -> f64 {
    norm_inf(&hilbert(n)) * norm_inf(&exact_inverse_f64(n, 1.0))
}

/// `inverse` with its refusal made explicit: `None` when IX answers `Singular`.
pub fn ix_inverse(a: &Array2<f64>) -> Option<Array2<f64>> {
    match inverse(a) {
        Ok(x) => Some(x),
        Err(MathError::Singular) => None,
        Err(e) => panic!("inverse failed for another reason: {e}"),
    }
}

/// One Hilbert size, one scale, everything the lesson reports.
pub struct Measurement {
    pub n: usize,
    pub scale: f64,
    pub kappa_inf: f64,
    pub singular_values: Vec<f64>,
    pub kappa2: f64,
    pub inverse: Option<Array2<f64>>,
    pub forward_error: Option<f64>,
    pub residual: Option<f64>,
    pub mcp_tol: f64,
    pub rank_mcp: usize,
    pub pinv_mcp: Array2<f64>,
    pub pinv_mcp_residual: f64,
    pub pinv0_forward_error: f64,
}

impl Measurement {
    /// Whether IX's kappa_2, computed on the stored fl(scale * H_n), lies in the band kappa_inf / n <= kappa_2 <=
    /// kappa_inf of the exact H_n. The two sides describe different matrices, so `false` is a measurement, not
    /// proof of an svd defect (README, note of 2026-09-27).
    pub fn band_holds(&self) -> bool {
        self.kappa_inf / self.n as f64 <= self.kappa2 && self.kappa2 <= self.kappa_inf
    }
}

pub fn measure(n: usize, scale: f64) -> Measurement {
    let a = hilbert(n).mapv(|x| x * scale);
    let exact = exact_inverse_f64(n, scale);
    let s = svd(&a).expect("svd of a non-empty matrix");
    let singular_values = s.singular_values.to_vec();
    let kappa2 = singular_values[0] / singular_values[n - 1];
    let x = ix_inverse(&a);
    let forward = x.as_ref().map(|x| forward_error(x, &exact));
    let res = x.as_ref().map(|x| residual(&a, x));
    let mcp_tol = singular_values[0] * MCP_RANK_FACTOR;
    let pinv_mcp = s.pseudo_inverse(mcp_tol);
    let pinv_mcp_residual = residual(&a, &pinv_mcp);
    let pinv0_forward_error = forward_error(&s.pseudo_inverse(0.0), &exact);
    Measurement {
        n,
        scale,
        kappa_inf: kappa_inf_exact(n),
        singular_values,
        kappa2,
        inverse: x,
        forward_error: forward,
        residual: res,
        mcp_tol,
        rank_mcp: s.rank(mcp_tol),
        pinv_mcp,
        pinv_mcp_residual,
        pinv0_forward_error,
    }
}

/// FNV-1a over the raw bits of every value, so a one-ulp difference between two platforms shows.
pub fn bits_digest<'a>(values: impl IntoIterator<Item = &'a f64>) -> u64 {
    let mut h: u64 = 0xcbf2_9ce4_8422_2325;
    for v in values {
        for b in v.to_bits().to_le_bytes() {
            h ^= b as u64;
            h = h.wrapping_mul(0x0000_0100_0000_01b3);
        }
    }
    h
}

/// Every f64 a measurement computed, in a fixed order, for `bits_digest`.
pub fn raw_values(m: &Measurement) -> Vec<f64> {
    let mut v = m.singular_values.clone();
    if let Some(x) = &m.inverse {
        v.extend(x.iter());
    }
    v.extend(m.pinv_mcp.iter());
    v.push(m.pinv0_forward_error);
    v
}
