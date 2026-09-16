//! Lesson 5, solutions to the exercises.

use ix_unsupervised::pca::PCA;
use ix_unsupervised::traits::DimensionReducer;
use machine_learning_ix::data::load_jobs;
use machine_learning_ix::evaluation::Scaler;
use machine_learning_ix::reduce::{HandPca, center, column_means, covariance};
use machine_learning_ix::{data_path, fmt_vec};

fn main() {
    let jobs = load_jobs(data_path("jobs.csv"));
    let x = Scaler::fit(&jobs.features).transform(&jobs.features);

    // 1. How many components keep 90 % of the variance, and what IX would claim for each count
    println!("== components needed for a share of the variance");
    let full = HandPca::fit(&x, 5);
    let ratio = full.explained_variance_ratio();
    let mut running = 0.0;
    for k in 1..=5 {
        running += ratio[k - 1];
        let mut ix = PCA::new(k);
        ix.fit(&x);
        let claimed = ix.explained_variance_ratio().unwrap().sum();
        println!("  k {k}: really kept {running:.4}, ix reports {claimed:.4}");
    }
    let needed = (1..=5)
        .find(|&k| ratio.iter().take(k).sum::<f64>() >= 0.9)
        .unwrap();
    println!("  {needed} components pass 0.90; IX reports 1.0000 for every k");

    // 2. Whitening: divide each score by its own standard deviation, and the scores lose
    //    every correlation and every difference of scale
    println!("\n== whitening the two-component scores");
    let two = HandPca::fit(&x, 2);
    let scores = two.transform(&x);
    let before = covariance(&center(&scores, &column_means(&scores)));
    println!("  covariance of the raw scores");
    for i in 0..2 {
        println!("    {}", fmt_vec(before.row(i).iter().copied(), 6));
    }
    // The variance along component i is exactly the eigenvalue, up to the n - 1 divisor
    let mut whitened = scores.clone();
    for i in 0..2 {
        let scale = two.explained_variance[i].sqrt();
        whitened.column_mut(i).mapv_inplace(|v: f64| v / scale);
    }
    let after = covariance(&center(&whitened, &column_means(&whitened)));
    println!("  covariance of the whitened scores");
    for i in 0..2 {
        println!("    {}", fmt_vec(after.row(i).iter().copied(), 6));
    }

    // 3. The reconstruction of one job, component by component
    println!("\n== job 0 rebuilt, one component at a time");
    println!("  true      {}", fmt_vec(x.row(0).iter().copied(), 3));
    for k in 1..=5 {
        let pca = HandPca::fit(&x, k);
        let back = pca.inverse_transform(&pca.transform(&x));
        println!("  k {k}       {}", fmt_vec(back.row(0).iter().copied(), 3));
    }
}
