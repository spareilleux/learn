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

/// `[1.000, 2.500]`: fixed decimals, so the outputs don't depend on how each OS prints the last digits
pub fn fmt_vec(v: impl IntoIterator<Item = f64>, decimals: usize) -> String {
    let parts: Vec<String> = v.into_iter().map(|x| format!("{x:.decimals$}")).collect();
    format!("[{}]", parts.join(", "))
}
