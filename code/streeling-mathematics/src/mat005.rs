//! MAT-005, symmetric eigenproblems: IX's cyclic Jacobi `symmetric_eigen` checked through its invariants, on a
//! repeated eigenvalue, on an asymmetric input and across scales, and IX's power-iteration `PCA` on six points
//! whose main axis it is predicted to miss. Pre-registered in preregistration-mat005.md. Products, norms and
//! residuals are computed here with plain loops, without IX.

use crate::{matmul, max_or_nan, min_or_nan};
use ix_math::eigen::symmetric_eigen;
use ix_unsupervised::pca::PCA;
use ix_unsupervised::traits::DimensionReducer;
use ndarray::{Array2, array};

/// B = [[5, 2], [2, 2]], eigenvalues 6 and 1.
pub fn matrix_b() -> Array2<f64> {
    array![[5.0, 2.0], [2.0, 2.0]]
}

/// T, the matrix of IX's `test_eigenvectors_are_orthonormal` and `test_reconstruction`.
pub fn matrix_t() -> Array2<f64> {
    array![[4.0, 1.0, 2.0], [1.0, 3.0, 0.5], [2.0, 0.5, 5.0]]
}

/// I + J of size n, J the matrix of ones: eigenvalues n + 1 once and 1 n - 1 times.
pub fn identity_plus_ones(n: usize) -> Array2<f64> {
    Array2::from_shape_fn((n, n), |(i, j)| if i == j { 2.0 } else { 1.0 })
}

/// N = [[1, 2], [3, 4]], not symmetric.
pub fn matrix_n() -> Array2<f64> {
    array![[1.0, 2.0], [3.0, 4.0]]
}

/// The six points of MAT-005 section 7, one per row; their mean is 0.
pub fn six_points() -> Array2<f64> {
    array![
        [1.0, -1.0],
        [-1.0, 1.0],
        [1.0, 0.0],
        [-1.0, 0.0],
        [0.0, 1.0],
        [0.0, -1.0]
    ]
}

/// Their covariance C = [[4, -2], [-2, 4]] / 5; X^T X is exact for these small integers.
pub fn covariance() -> Array2<f64> {
    array![[4.0, -2.0], [-2.0, 4.0]].mapv(|v| v / 5.0)
}

/// What `symmetric_eigen` returned: eigenvalues in its order, eigenvectors as columns.
pub struct Eigen {
    pub values: Vec<f64>,
    pub vectors: Array2<f64>,
}

pub fn eigen(a: &Array2<f64>) -> Eigen {
    let (values, vectors) =
        symmetric_eigen(a).expect("symmetric_eigen of a non-empty square matrix");
    Eigen {
        values: values.to_vec(),
        vectors,
    }
}

/// The largest |entry| of A v_i - lambda_i v_i, over every returned pair.
pub fn max_eigen_residual(a: &Array2<f64>, e: &Eigen) -> f64 {
    let av = matmul(a, &e.vectors);
    let mut worst: f64 = 0.0;
    for ((i, j), x) in av.indexed_iter() {
        worst = max_or_nan(worst, (x - e.values[j] * e.vectors[[i, j]]).abs());
    }
    worst
}

/// The largest |entry| of V^T V - I.
pub fn max_orthonormality_error(v: &Array2<f64>) -> f64 {
    let vtv = matmul(&v.t().to_owned(), v);
    let mut worst: f64 = 0.0;
    for ((i, j), x) in vtv.indexed_iter() {
        worst = max_or_nan(worst, (x - if i == j { 1.0 } else { 0.0 }).abs());
    }
    worst
}

/// The largest |entry| of V Lambda V^T - A.
pub fn max_reconstruction_error(a: &Array2<f64>, e: &Eigen) -> f64 {
    let n = a.nrows();
    let v_lambda = Array2::from_shape_fn((n, n), |(i, j)| e.vectors[[i, j]] * e.values[j]);
    let r = matmul(&v_lambda, &e.vectors.t().to_owned());
    r.iter()
        .zip(a.iter())
        .map(|(x, y)| (x - y).abs())
        .fold(0.0, max_or_nan)
}

/// One matrix of step 1.
pub struct InvariantRow {
    pub name: &'static str,
    pub values: Vec<f64>,
    /// The eigenvalues the module predicts for it, if any.
    pub predicted: Option<Vec<f64>>,
    pub residual: f64,
    pub orthonormality: f64,
    pub reconstruction: f64,
}

/// Step 1: B, T, I + J of size 3 and 4.
pub fn invariants() -> Vec<InvariantRow> {
    [
        ("B", matrix_b(), Some(vec![6.0, 1.0])),
        ("T", matrix_t(), None),
        ("I+J(3)", identity_plus_ones(3), Some(vec![4.0, 1.0, 1.0])),
        (
            "I+J(4)",
            identity_plus_ones(4),
            Some(vec![5.0, 1.0, 1.0, 1.0]),
        ),
    ]
    .into_iter()
    .map(|(name, a, predicted)| {
        let e = eigen(&a);
        InvariantRow {
            name,
            residual: max_eigen_residual(&a, &e),
            orthonormality: max_orthonormality_error(&e.vectors),
            reconstruction: max_reconstruction_error(&a, &e),
            values: e.values,
            predicted,
        }
    })
    .collect()
}

/// I - J/3, the projector on the eigenspace of 1 of I + J of size 3.
pub fn eigenspace_projector() -> Array2<f64> {
    Array2::from_shape_fn((3, 3), |(i, j)| {
        (if i == j { 1.0 } else { 0.0 }) - 1.0 / 3.0
    })
}

/// The sum of u u^T over the given columns of V.
pub fn projector_from(v: &Array2<f64>, columns: &[usize]) -> Array2<f64> {
    let n = v.nrows();
    Array2::from_shape_fn((n, n), |(i, j)| {
        columns.iter().map(|&c| v[[i, c]] * v[[j, c]]).sum()
    })
}

/// Step 2: the columns whose eigenvalue is within 1e-9 of 1, and the largest |entry| of their projector
/// minus I - J/3.
pub fn eigenspace() -> (Vec<usize>, f64) {
    let e = eigen(&identity_plus_ones(3));
    let columns: Vec<usize> = (0..3)
        .filter(|&j| (e.values[j] - 1.0).abs() <= 1e-9)
        .collect();
    let p = projector_from(&e.vectors, &columns);
    let err = p
        .iter()
        .zip(eigenspace_projector().iter())
        .map(|(x, y)| (x - y).abs())
        .fold(0.0, max_or_nan);
    (columns, err)
}

/// The Euclidean norm of A v - lambda v, for column j.
pub fn residual_norm(a: &Array2<f64>, e: &Eigen, j: usize) -> f64 {
    let n = a.nrows();
    (0..n)
        .map(|i| {
            let av: f64 = (0..n).map(|k| a[[i, k]] * e.vectors[[k, j]]).sum();
            let r = av - e.values[j] * e.vectors[[i, j]];
            r * r
        })
        .sum::<f64>()
        .sqrt()
}

/// The largest |x_i - sign * y_i| for the better sign.
pub fn distance_up_to_sign(x: &[f64], y: &[f64]) -> f64 {
    [1.0, -1.0]
        .iter()
        .map(|s| {
            x.iter()
                .zip(y)
                .map(|(a, b)| (a - s * b).abs())
                .fold(0.0, max_or_nan)
        })
        .fold(f64::INFINITY, min_or_nan)
}

/// What `PCA::new(2)` returned on the six points.
pub struct PcaResult {
    /// One component per row.
    pub components: Array2<f64>,
    pub variances: Vec<f64>,
    pub ratios: Vec<f64>,
}

/// Step 4.
pub fn pca() -> PcaResult {
    let mut pca = PCA::new(2);
    pca.fit(&six_points());
    let state = pca.save_state().expect("a fitted PCA");
    PcaResult {
        components: pca.components().expect("a fitted PCA").clone(),
        variances: state.explained_variance,
        ratios: pca
            .explained_variance_ratio()
            .expect("a fitted PCA")
            .to_vec(),
    }
}

/// (trace C - sum of the returned variances) / trace C: the share of the variance the components miss.
pub fn unaccounted_share(variances: &[f64]) -> f64 {
    let c = covariance();
    let trace = c[[0, 0]] + c[[1, 1]];
    (trace - variances.iter().sum::<f64>()) / trace
}

/// Whether two matrices have the same entries, bit for bit.
pub fn same_bits(a: &Array2<f64>, b: &Array2<f64>) -> bool {
    a.shape() == b.shape()
        && a.iter()
            .zip(b.iter())
            .all(|(x, y)| x.to_bits() == y.to_bits())
}

/// One scale of M5-L1, for s * B.
pub struct ScaleRow {
    pub exponent: i32,
    /// The eigenvalues divided by s.
    pub values_over_s: Vec<f64>,
    /// |lambda_i / s - (6, 1)_i| / (6, 1)_i.
    pub relative_errors: Vec<f64>,
    /// Whether the eigenvalues are the diagonal of s * B and V is the identity, bit for bit.
    pub returned_diagonal: bool,
    /// The check of IX's tests: the largest |entry| of A v - lambda v.
    pub max_residual: f64,
}

/// M5-L1: `symmetric_eigen(s * B)` for s = 10^e.
pub fn scale_row(exponent: i32) -> ScaleRow {
    let s = crate::mat006::ten_to(exponent);
    let a = matrix_b().mapv(|v| v * s);
    let e = eigen(&a);
    let exact = [6.0, 1.0];
    let diagonal = [a[[0, 0]], a[[1, 1]]];
    ScaleRow {
        exponent,
        values_over_s: e.values.iter().map(|v| v / s).collect(),
        relative_errors: e
            .values
            .iter()
            .zip(exact)
            .map(|(v, x)| (v / s - x).abs() / x)
            .collect(),
        returned_diagonal: e
            .values
            .iter()
            .zip(diagonal)
            .all(|(v, d)| v.to_bits() == d.to_bits())
            && same_bits(&e.vectors, &Array2::eye(2)),
        max_residual: max_eigen_residual(&a, &e),
    }
}

/// The exponents of M5-L1, -14 to 12.
pub fn exponents() -> std::ops::RangeInclusive<i32> {
    -14..=12
}
