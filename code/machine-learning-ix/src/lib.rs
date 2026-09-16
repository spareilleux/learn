//! Code of the "Machine learning, as applied in IX" course: the data sets, each algorithm written by hand,
//! and helpers to print results the same way on every OS. The examples compare these with the IX crates.
//!
//! Lesson 4: the import of IX's k-means tutorial (docs/unsupervised-learning/kmeans.md) doesn't compile,
//! because `ix_unsupervised` exports its modules, not the types inside them:
//!
//! ```compile_fail,E0432
//! use ix_unsupervised::{KMeans, Clusterer};
//! ```
//!
//! The paths that work:
//!
//! ```
//! use ix_unsupervised::kmeans::KMeans;
//! use ix_unsupervised::traits::Clusterer;
//!
//! let mut kmeans = KMeans::new(2).with_seed(42);
//! let labels = kmeans.fit_predict(&ndarray::array![[0.0], [1.0], [10.0]]);
//! assert_eq!(labels[0], labels[1]);
//! ```

pub mod classify;
pub mod cluster;
pub mod data;
pub mod ensemble;
pub mod evaluation;
pub mod linear;
pub mod net;
pub mod optimize;
pub mod reduce;

use ndarray::{Array1, Array2};

/// Path of a file under `data/`, from wherever cargo runs the example
pub fn data_path(name: &str) -> std::path::PathBuf {
    std::path::Path::new(env!("CARGO_MANIFEST_DIR"))
        .join("data")
        .join(name)
}

/// Rows of a matrix picked by index
pub fn rows(x: &Array2<f64>, indices: &[usize]) -> Array2<f64> {
    x.select(ndarray::Axis(0), indices)
}

/// Elements of a vector picked by index
pub fn pick<T: Clone>(y: &Array1<T>, indices: &[usize]) -> Array1<T> {
    indices.iter().map(|&i| y[i].clone()).collect()
}

/// `[1.000, 2.500]`: fixed decimals, so the outputs don't depend on how each OS prints the last digits.
///
/// A value that rounds to zero prints as `0.000`, never `-0.000`. The sign of a zero is not a result:
/// the exclusive-or network of lesson 7 lands on `-0.0` on macOS and `0.0` on Windows and Linux, from
/// the same arithmetic in a different order, and both mean the same number.
pub fn fmt_vec(v: impl IntoIterator<Item = f64>, decimals: usize) -> String {
    let parts: Vec<String> = v
        .into_iter()
        .map(|x| {
            let printed = format!("{x:.decimals$}");
            match printed.strip_prefix('-') {
                Some(without_sign) if without_sign.chars().all(|c| c == '0' || c == '.') => {
                    without_sign.to_string()
                }
                _ => printed,
            }
        })
        .collect();
    format!("[{}]", parts.join(", "))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_zero_never_prints_with_a_minus_sign() {
        // -0.0 and a value too small to show are the same number as 0.0 at this precision,
        // and which of the two an optimizer lands on differs between macOS and Windows.
        assert_eq!(fmt_vec([-0.0, 0.0], 4), "[0.0000, 0.0000]");
        assert_eq!(fmt_vec([-1e-9, 1e-9], 4), "[0.0000, 0.0000]");
        // every other sign survives
        assert_eq!(fmt_vec([-0.5, -0.00006], 4), "[-0.5000, -0.0001]");
    }
}
