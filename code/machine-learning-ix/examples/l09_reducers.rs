//! Lesson 9: five different reasons to reduce dimensions. Classical MDS is derived by hand;
//! the other reducers exercise IX's pinned APIs on the course's CI jobs or a small geometry.

use ix_unsupervised::kernel_pca::{Kernel, KernelPca};
use ix_unsupervised::lda::LinearDiscriminantAnalysis;
use ix_unsupervised::mds::{classical_mds, pairwise_euclidean};
use ix_unsupervised::nmf::NonNegativeMatrixFactorization;
use ix_unsupervised::traits::DimensionReducer;
use ix_unsupervised::tsne::TSNE;
use machine_learning_ix::data::load_jobs;
use machine_learning_ix::evaluation::Scaler;
use machine_learning_ix::reduce::{jacobi_eigen, reconstruction_error};
use machine_learning_ix::{data_path, rows};
use ndarray::{Array2, array, s};

/// B = -1/2 J D² J. Jacobi returns eigenvectors as rows; each scaled row becomes a column.
fn hand_mds(d: &Array2<f64>, k: usize) -> Array2<f64> {
    let n = d.nrows();
    assert_eq!(d.ncols(), n);
    assert!(k > 0 && k < n);
    let squared = d.mapv(|v| v * v);
    let row_means: Vec<f64> = squared
        .rows()
        .into_iter()
        .map(|r| r.sum() / n as f64)
        .collect();
    let grand_mean = squared.sum() / (n * n) as f64;
    let gram = Array2::from_shape_fn((n, n), |(i, j)| {
        -0.5 * (squared[[i, j]] - row_means[i] - row_means[j] + grand_mean)
    });
    let (values, vectors) = jacobi_eigen(&gram, 1000, 1e-14);
    Array2::from_shape_fn((n, k), |(i, axis)| {
        vectors[[axis, i]] * values[axis].max(0.0).sqrt()
    })
}

fn largest_distance_gap(want: &Array2<f64>, points: &Array2<f64>) -> f64 {
    let got = pairwise_euclidean(points);
    want.iter()
        .zip(got.iter())
        .map(|(a, b)| (a - b).abs())
        .fold(0.0, f64::max)
}

fn ring_mean_gap(y: &Array2<f64>, axis: usize) -> f64 {
    let inner = y.slice(s![0..4, axis]).sum() / 4.0;
    let outer = y.slice(s![4..8, axis]).sum() / 4.0;
    (inner - outer).abs()
}

fn main() {
    // A square has no information beyond two dimensions. Compare *distances*, because an
    // eigensolver may rotate or reverse the axes without changing the embedding.
    let square = array![[0.0, 0.0], [1.0, 0.0], [1.0, 1.0], [0.0, 1.0]];
    let distances = pairwise_euclidean(&square);
    let hand = hand_mds(&distances, 2);
    let ix = classical_mds(&distances, 2).expect("square distances");
    let hand_gap = largest_distance_gap(&distances, &hand);
    let ix_gap = largest_distance_gap(&distances, &ix);
    assert!(hand_gap < 1e-10 && ix_gap < 1e-10);
    println!("== classical MDS: square from distances alone");
    println!("  hand and IX recover all six distances: true");

    // Opposite points on each ring cancel in linear PCA. An RBF kernel can distinguish radii.
    let rings = array![
        [1.0, 0.0],
        [-1.0, 0.0],
        [0.0, 1.0],
        [0.0, -1.0],
        [2.0, 0.0],
        [-2.0, 0.0],
        [0.0, 2.0],
        [0.0, -2.0]
    ];
    let linear = KernelPca::new(1, Kernel::Linear)
        .fit_transform(&rings)
        .unwrap();
    let rbf = KernelPca::new(4, Kernel::Rbf { gamma: 0.5 })
        .fit_transform(&rings)
        .unwrap();
    let linear_gap = ring_mean_gap(&linear, 0);
    let radial_gap = ring_mean_gap(&rbf, 3);
    assert!(linear_gap < 1e-10 && radial_gap > 0.5);
    println!("\n== kernel PCA: concentric rings");
    println!("  mean gap on linear axis: {:.4}", linear_gap);
    println!("  mean gap on RBF axis 1: {:.4}", ring_mean_gap(&rbf, 0));
    println!("  mean gap on RBF axis 4: {:.4}", radial_gap);
    println!("  linear axis separates ring means: {}", linear_gap > 0.1);
    println!(
        "  fourth RBF axis separates ring means: {}",
        radial_gap > 0.1
    );

    let jobs = load_jobs(data_path("jobs.csv"));
    let scaled = Scaler::fit(&jobs.features).transform(&jobs.features);
    // A standardized timing can be negative; NMF instead consumes the raw non-negative seconds.
    let mut nmf = NonNegativeMatrixFactorization::new(2)
        .with_seed(42)
        .with_max_iterations(300);
    let loadings = nmf.fit_transform(&jobs.features).unwrap();
    let rebuilt = nmf.reconstruct(&loadings).unwrap();
    let mse = reconstruction_error(&jobs.features, &rebuilt);
    assert!(mse.is_finite());
    println!(
        "\n== NMF: CI timings, {} jobs x {} features",
        jobs.features.nrows(),
        jobs.features.ncols()
    );
    println!("  rank 2 reconstruction MSE: {:.3}", mse);
    println!(
        "  standardized input rejected: {}",
        NonNegativeMatrixFactorization::new(2)
            .fit_transform(&scaled)
            .is_err()
    );

    // Labels are essential to LDA: here the runner OS is known, but the projection is fitted
    // on the same rows. It is a visualization, not a held-out classifier score.
    let mut lda = LinearDiscriminantAnalysis::new(2);
    lda.fit(&scaled, &jobs.os).unwrap();
    let projected = lda.transform(&scaled).unwrap();
    assert_eq!(projected.dim(), (jobs.features.nrows(), 2));
    println!("\n== LDA: runner OS labels");
    println!("  three OS classes allow at most two axes: true");
    println!(
        "  projection finite: {}",
        projected.iter().all(|v| v.is_finite())
    );

    // Keep t-SNE tiny: IX computes every pair, on every iteration, despite the module header's
    // Barnes-Hut claim. Its transform returns the fitted embedding, ignoring the argument.
    let sample = rows(&scaled, &(0..12).collect::<Vec<_>>());
    let mut tsne = TSNE::new(2)
        .with_perplexity(3.0)
        .with_max_iterations(300)
        .with_seed(42);
    tsne.fit(&sample);
    let embedding = tsne.transform(&sample);
    assert_eq!(embedding.dim(), (12, 2));
    println!("\n== t-SNE: first 12 standardized jobs");
    println!(
        "  12 x 2 finite embedding: {}",
        embedding.iter().all(|v| v.is_finite())
    );
    println!(
        "  transform ignores its input: {}",
        embedding == tsne.transform(&array![[999.0]])
    );
}
