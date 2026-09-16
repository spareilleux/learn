//! Lesson 5: five timings pressed into two. The covariance matrix and its eigenvectors by hand,
//! then ix_unsupervised::pca::PCA on the same data, the ratio it reports, and the start its power
//! iteration never leaves.

use ix_unsupervised::pca::PCA;
use ix_unsupervised::traits::DimensionReducer;
use machine_learning_ix::data::{OS_NAMES, load_jobs};
use machine_learning_ix::evaluation::Scaler;
use machine_learning_ix::reduce::{
    HandPca, center, column_means, covariance, jacobi_eigen, reconstruction_error,
};
use machine_learning_ix::{data_path, fmt_vec};
use ndarray::{Array1, Array2, array};

fn main() {
    let jobs = load_jobs(data_path("jobs.csv"));
    let x = Scaler::fit(&jobs.features).transform(&jobs.features);
    println!(
        "== {} jobs, features {:?}, standardized",
        x.nrows(),
        jobs.feature_names
    );

    // 1. The covariance matrix. Standardized columns put 1 on the diagonal, so the total
    //    variance is the number of features and each entry is a correlation.
    let cov = covariance(&center(&x, &column_means(&x)));
    println!("\n== covariance matrix of the standardized features");
    for i in 0..cov.nrows() {
        println!("  {}", fmt_vec(cov.row(i).iter().copied(), 3));
    }
    println!("trace (total variance): {:.3}", cov.diag().sum());

    // 2. Every eigenpair at once, by Jacobi rotations
    let full = HandPca::fit(&x, 5);
    let ratio = full.explained_variance_ratio();
    println!("\n== all five components, by hand (Jacobi)");
    let mut cumulative = 0.0;
    for i in 0..5 {
        cumulative += ratio[i];
        println!(
            "  component {}: variance {:.4}, ratio {:.4}, cumulative {:.4}, {}",
            i + 1,
            full.explained_variance[i],
            ratio[i],
            cumulative,
            fmt_vec(full.components.row(i).iter().copied(), 3)
        );
    }
    println!("sum of the five ratios: {:.4}", ratio.sum());

    // 3. The same five with IX
    let mut ix_full = PCA::new(5);
    ix_full.fit(&x);
    // The variances themselves are private: `save_state` is the only way out of the struct
    let ix_variance = Array1::from(ix_full.save_state().unwrap().explained_variance);
    let ix_components = ix_full.components().unwrap().clone();
    println!("\n== ix_unsupervised::pca::PCA, five components");
    println!(
        "  ix   variance {}",
        fmt_vec(ix_variance.iter().copied(), 4)
    );
    println!(
        "  hand variance {}",
        fmt_vec(full.explained_variance.iter().copied(), 4)
    );
    println!(
        "  largest difference: {:.2e}",
        ix_variance
            .iter()
            .zip(full.explained_variance.iter())
            .map(|(a, b): (&f64, &f64)| (a - b).abs())
            .fold(0.0f64, f64::max)
    );
    for i in 0..5 {
        let hand = full.components.row(i);
        let ix_row = ix_components.row(i);
        let same_way = ix_row.dot(&hand) >= 0.0;
        println!(
            "  component {}: ix {} {}",
            i + 1,
            fmt_vec(ix_row.iter().copied(), 3),
            if same_way {
                "same direction as the hand version"
            } else {
                "opposite direction to the hand version"
            }
        );
    }

    // 4. The ratio IX reports when components are dropped
    let mut ix_two = PCA::new(2);
    ix_two.fit(&x);
    let ix_two_ratio = ix_two.explained_variance_ratio().unwrap();
    let hand_two = HandPca::fit(&x, 2);
    println!("\n== keeping two of the five components");
    println!(
        "  hand ratio {} sum {:.4}",
        fmt_vec(hand_two.explained_variance_ratio().iter().copied(), 4),
        hand_two.explained_variance_ratio().sum()
    );
    println!(
        "  ix   ratio {} sum {:.4}",
        fmt_vec(ix_two_ratio.iter().copied(), 4),
        ix_two_ratio.sum()
    );

    // 5. The scores of the first three jobs, both ways
    println!("\n== first three jobs in two dimensions");
    let hand_scores = hand_two.transform(&x);
    let ix_scores = ix_two.transform(&x);
    for i in 0..3 {
        println!(
            "  job {} on {:<7} hand {} ix {}",
            i,
            OS_NAMES[jobs.os[i]],
            fmt_vec(hand_scores.row(i).iter().copied(), 4),
            fmt_vec(ix_scores.row(i).iter().copied(), 4)
        );
    }

    // 6. What is lost by keeping fewer components
    println!("\n== mean squared reconstruction error, and the variance kept");
    for k in 1..=5 {
        let pca = HandPca::fit(&x, k);
        let back = pca.inverse_transform(&pca.transform(&x));
        println!(
            "  k {k}: error {:.4}, variance kept {:.4}",
            reconstruction_error(&x, &back),
            pca.explained_variance_ratio().sum()
        );
    }

    // 7. A cloud whose principal axis is orthogonal to power iteration's starting vector
    //    (1, 1)/√2. Covariance [[2.4, -1.6], [-1.6, 2.4]]: eigenvalues 4.0 along (1, -1)
    //    and 0.8 along (1, 1).
    let anti: Array2<f64> = array![
        [1.0, -1.0],
        [-1.0, 1.0],
        [2.0, -2.0],
        [-2.0, 2.0],
        [1.0, 1.0],
        [-1.0, -1.0]
    ];
    println!("\n== a cloud stretched along (1, -1)");
    let anti_cov = covariance(&center(&anti, &column_means(&anti)));
    println!(
        "  covariance {:?}",
        anti_cov.iter().copied().collect::<Vec<_>>()
    );
    let (values, vectors) = jacobi_eigen(&anti_cov, 1000, 1e-14);
    println!(
        "  hand eigenvalues {} first eigenvector {}",
        fmt_vec(values.iter().copied(), 4),
        fmt_vec(vectors.row(0).iter().copied(), 4)
    );
    let mut ix_anti = PCA::new(1);
    ix_anti.fit(&anti);
    println!(
        "  ix PCA(1): variance {} component {}",
        fmt_vec(ix_anti.save_state().unwrap().explained_variance, 4),
        fmt_vec(ix_anti.components().unwrap().row(0).iter().copied(), 4)
    );
    let mut ix_anti2 = PCA::new(2);
    ix_anti2.fit(&anti);
    println!(
        "  ix PCA(2): variance {} components {} {}",
        fmt_vec(ix_anti2.save_state().unwrap().explained_variance, 4),
        fmt_vec(ix_anti2.components().unwrap().row(0).iter().copied(), 4),
        fmt_vec(ix_anti2.components().unwrap().row(1).iter().copied(), 4)
    );
    let scores: Array1<f64> = ix_anti.transform(&anti).column(0).to_owned();
    println!("  ix PCA(1) scores {}", fmt_vec(scores.iter().copied(), 4));
}
