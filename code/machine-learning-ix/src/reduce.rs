//! Lesson 5: principal component analysis written by hand — the covariance matrix, the Jacobi
//! rotations that diagonalize it, and the share of the variance each component explains.

use ndarray::{Array1, Array2, Axis, s};

/// Column means of `x`.
pub fn column_means(x: &Array2<f64>) -> Array1<f64> {
    x.mean_axis(Axis(0)).expect("no rows")
}

/// `x` with `means` subtracted from every row.
pub fn center(x: &Array2<f64>, means: &Array1<f64>) -> Array2<f64> {
    let mut c = x.clone();
    for mut row in c.rows_mut() {
        row -= means;
    }
    c
}

/// Unbiased covariance matrix of already centered data: `Xᵀ X / (n - 1)`.
/// The `n.max(2) - 1` guard is the one `ix_unsupervised::pca` uses.
pub fn covariance(centered: &Array2<f64>) -> Array2<f64> {
    let n = centered.nrows();
    centered.t().dot(centered) / (n.max(2) - 1) as f64
}

/// Jacobi's eigenvalue algorithm for a symmetric matrix: repeatedly rotate away the largest
/// off-diagonal entry until none exceeds `tol`. Unlike power iteration it returns every
/// eigenpair at once, and each to full precision.
///
/// Returns the eigenvalues in decreasing order and their eigenvectors as rows, each row signed
/// so that its largest-magnitude entry is positive — the convention scikit-learn's `svd_flip`
/// applies to `components_`.
pub fn jacobi_eigen(a: &Array2<f64>, rotations: usize, tol: f64) -> (Array1<f64>, Array2<f64>) {
    let n = a.nrows();
    let mut m = a.clone();
    let mut v = Array2::<f64>::eye(n);

    for _ in 0..rotations {
        // The largest off-diagonal entry, which this rotation will set to zero
        let (mut p, mut q, mut largest) = (0, 0, 0.0);
        for i in 0..n {
            for j in i + 1..n {
                if m[[i, j]].abs() > largest {
                    largest = m[[i, j]].abs();
                    (p, q) = (i, j);
                }
            }
        }
        if largest < tol {
            break;
        }

        // The angle that zeroes m[p][q]: cot(2θ) = (m[p][p] - m[q][q]) / (2 m[p][q])
        let theta = 0.5 * (2.0 * m[[p, q]]).atan2(m[[p, p]] - m[[q, q]]);
        let (c, s) = (theta.cos(), theta.sin());
        for k in 0..n {
            let (kp, kq) = (m[[k, p]], m[[k, q]]);
            m[[k, p]] = c * kp + s * kq;
            m[[k, q]] = c * kq - s * kp;
        }
        for k in 0..n {
            let (pk, qk) = (m[[p, k]], m[[q, k]]);
            m[[p, k]] = c * pk + s * qk;
            m[[q, k]] = c * qk - s * pk;
        }
        for k in 0..n {
            let (kp, kq) = (v[[k, p]], v[[k, q]]);
            v[[k, p]] = c * kp + s * kq;
            v[[k, q]] = c * kq - s * kp;
        }
    }

    let mut order: Vec<usize> = (0..n).collect();
    order.sort_by(|&i, &j| m[[j, j]].total_cmp(&m[[i, i]]));
    let values = order.iter().map(|&i| m[[i, i]]).collect();
    let mut vectors = Array2::zeros((n, n));
    for (row, &i) in order.iter().enumerate() {
        let column = v.column(i);
        // The *first* entry of largest magnitude, the way numpy's argmax breaks a tie
        let mut leading = 0;
        for k in 1..n {
            if column[k].abs() > column[leading].abs() {
                leading = k;
            }
        }
        let sign = if column[leading] < 0.0 { -1.0 } else { 1.0 };
        for k in 0..n {
            vectors[[row, k]] = sign * column[k];
        }
    }
    (values, vectors)
}

/// PCA by hand: centre the data, diagonalize its covariance matrix, keep the top `k` components.
pub struct HandPca {
    pub mean: Array1<f64>,
    /// One component per row, in decreasing order of explained variance
    pub components: Array2<f64>,
    /// The variance along each kept component
    pub explained_variance: Array1<f64>,
    /// The variance of the data over *every* feature, kept or dropped
    pub total_variance: f64,
}

impl HandPca {
    pub fn fit(x: &Array2<f64>, k: usize) -> HandPca {
        let mean = column_means(x);
        let cov = covariance(&center(x, &mean));
        let (values, vectors) = jacobi_eigen(&cov, 1000, 1e-14);
        HandPca {
            mean,
            components: vectors.slice(s![..k, ..]).to_owned(),
            explained_variance: values.slice(s![..k]).to_owned(),
            total_variance: values.sum(),
        }
    }

    /// The `k` coordinates of each row in the component basis.
    pub fn transform(&self, x: &Array2<f64>) -> Array2<f64> {
        center(x, &self.mean).dot(&self.components.t())
    }

    /// The share of the *data's* total variance each kept component explains. These sum to 1
    /// only when every component is kept.
    pub fn explained_variance_ratio(&self) -> Array1<f64> {
        &self.explained_variance / self.total_variance
    }

    /// Back from the `k` scores to the original features: the best rank-`k` approximation of `x`.
    pub fn inverse_transform(&self, scores: &Array2<f64>) -> Array2<f64> {
        scores.dot(&self.components) + &self.mean
    }
}

/// Mean squared difference between `x` and its reconstruction, over every cell of the matrix.
pub fn reconstruction_error(x: &Array2<f64>, approx: &Array2<f64>) -> f64 {
    (x - approx).iter().map(|d| d * d).sum::<f64>() / (x.nrows() * x.ncols()) as f64
}

#[cfg(test)]
mod tests {
    use super::*;
    use ndarray::array;

    #[test]
    fn jacobi_diagonalizes_a_known_matrix() {
        // Eigenvalues 3 and 1, eigenvectors (1, 1)/√2 and (1, -1)/√2
        let (values, vectors) = jacobi_eigen(&array![[2.0, 1.0], [1.0, 2.0]], 100, 1e-14);
        assert!((values[0] - 3.0).abs() < 1e-12 && (values[1] - 1.0).abs() < 1e-12);
        let root = 0.5f64.sqrt();
        assert!((vectors[[0, 0]] - root).abs() < 1e-12);
        assert!((vectors[[0, 1]] - root).abs() < 1e-12);
    }

    #[test]
    fn a_plane_in_three_dimensions_needs_two_components() {
        // Every row lies on the plane z = 0, so the third eigenvalue is 0
        let x = array![
            [1.0, 0.0, 0.0],
            [0.0, 2.0, 0.0],
            [-1.0, 1.0, 0.0],
            [3.0, -2.0, 0.0]
        ];
        let pca = HandPca::fit(&x, 3);
        assert!(pca.explained_variance[2].abs() < 1e-12);
        let kept = HandPca::fit(&x, 2);
        let ratio = kept.explained_variance_ratio();
        assert!((ratio.sum() - 1.0).abs() < 1e-12);
        // Two components rebuild the rows exactly
        let back = kept.inverse_transform(&kept.transform(&x));
        assert!(reconstruction_error(&x, &back) < 1e-24);
    }

    #[test]
    fn the_ratio_of_one_component_is_below_one() {
        let x = array![[1.0, 0.0], [2.0, 1.0], [3.0, 0.0], [4.0, 1.0]];
        let one = HandPca::fit(&x, 1);
        assert!(one.explained_variance_ratio()[0] < 1.0);
    }
}
