//! Lesson 4: groups of CI jobs without their labels. k-means, the silhouette score and the rule ix-voicings uses
//! to choose k, DBSCAN and a Gaussian mixture, by hand and with ix_unsupervised.

use ix_unsupervised::dbscan::DBSCAN;
use ix_unsupervised::gmm::GMM;
use ix_unsupervised::kmeans::{KMeans, inertia};
use ix_unsupervised::traits::Clusterer;
use machine_learning_ix::cluster::{self, Mixture, em_step, kmeans_from, log_likelihood};
use machine_learning_ix::data::{OS_NAMES, load_jobs};
use machine_learning_ix::evaluation::Scaler;
use machine_learning_ix::{data_path, fmt_vec};
use ndarray::{Array1, Array2, array};

/// Rows = clusters, columns = runner OS
fn crosstab(
    labels: impl Iterator<Item = usize>,
    os: &Array1<usize>,
    clusters: usize,
) -> Array2<usize> {
    let mut t = Array2::zeros((clusters, 3));
    for (l, &o) in labels.zip(os) {
        t[[l, o]] += 1;
    }
    t
}

fn main() {
    let jobs = load_jobs(data_path("jobs.csv"));
    // Every feature in standard deviations, so that no timing dominates the distances
    let x = Scaler::fit(&jobs.features).transform(&jobs.features);
    println!(
        "== {} jobs, features {:?}, standardized",
        x.nrows(),
        jobs.feature_names
    );

    // 1. k-means with IX (k-means++ start, seed 42), then Lloyd's steps by hand from IX's centroids
    let mut km = KMeans::new(3).with_seed(42);
    let labels = km.fit_predict(&x);
    let centroids = km.centroids.clone().unwrap();
    let (hand_labels, hand_centroids, steps) = kmeans_from(&x, centroids.clone(), 100);
    println!("\n== k-means, k = 3");
    for c in 0..3 {
        println!(
            "ix centroid {c}: {}",
            fmt_vec(centroids.row(c).iter().copied(), 3)
        );
    }
    println!(
        "ix inertia {:.4}, hand inertia {:.4}",
        inertia(&x, &labels, &centroids),
        cluster::inertia(&x, &hand_labels, &hand_centroids)
    );
    println!(
        "hand Lloyd steps from ix centroids until nothing moves: {steps}, same labels: {}",
        hand_labels == labels
    );
    println!(
        "clusters (rows) against OS (columns {OS_NAMES:?}):\n{}",
        crosstab(labels.iter().copied(), &jobs.os, 3)
    );

    // 2. Another start, another answer
    let first_rows = x.slice(ndarray::s![0..3, ..]).to_owned();
    let (l, c, s) = kmeans_from(&x, first_rows, 100);
    println!(
        "\nhand, starting from the first 3 rows: {s} steps, inertia {:.4}",
        cluster::inertia(&x, &l, &c)
    );
    let by_seed: Vec<f64> = (0..10)
        .map(|seed| {
            let mut m = KMeans::new(3).with_seed(seed);
            let l = m.fit_predict(&x);
            inertia(&x, &l, m.centroids.as_ref().unwrap())
        })
        .collect();
    println!("ix, seeds 0 to 9: inertia {}", fmt_vec(by_seed, 4));

    // 3. Choosing k: inertia always falls, the silhouette doesn't
    println!("\n== choosing k (ix KMeans, seed 42)");
    for k in 2..=6 {
        let mut m = KMeans::new(k).with_seed(42);
        let l = m.fit_predict(&x);
        let lv: Vec<usize> = l.to_vec();
        println!(
            "k {k}: inertia {:>8.3}, silhouette hand {:.4}, ix_voicings {:.4}",
            inertia(&x, &l, m.centroids.as_ref().unwrap()),
            cluster::silhouette(&x, &lv),
            ix_voicings::silhouette_score(&x, &lv)
        );
    }
    // The rule of ix_voicings::cluster: k = 5, or k = 3 if the silhouette of k = 5 is below 0.15
    let mut five = KMeans::new(5).with_seed(42);
    let s5 = ix_voicings::silhouette_score(&x, &five.fit_predict(&x).to_vec());
    println!(
        "ix-voicings rule: silhouette(k = 5) = {s5:.4} -> keep k = {}",
        if s5 >= 0.15 { 5 } else { 3 }
    );

    // 4. Two edge cases: a point alone in its cluster, and more clusters than distinct points
    let tiny = array![[0.0], [1.0], [10.0]];
    println!("\n== edge cases");
    println!(
        "silhouette of [0, 1 | 10]: hand {:.4}, ix_voicings {:.4}",
        cluster::silhouette(&tiny, &[0, 0, 1]),
        ix_voicings::silhouette_score(&tiny, &[0, 0, 1])
    );
    let two_values = array![[5.0], [5.0], [9.0], [9.0]];
    let mut ghost = KMeans::new(3).with_seed(42);
    ghost.fit(&two_values);
    println!(
        "KMeans(3) on [5, 5, 9, 9]: centroids {}",
        fmt_vec(
            ghost.centroids.as_ref().unwrap().column(0).iter().copied(),
            1
        )
    );
    println!(
        "predict [1.0] -> cluster {}",
        ghost.predict(&array![[1.0]])[0]
    );

    // 5. DBSCAN: IX labels noise 0 and clusters from 1; the hand version uses scikit-learn's -1 and 0, 1, …
    println!("\n== DBSCAN, min_points 5");
    for eps in [0.5, 1.0, 1.5, 2.0] {
        let ix_labels = DBSCAN::new(eps, 5).fit_predict(&x);
        let hand = cluster::dbscan(&x, eps, 5);
        let shifted: Vec<i64> = ix_labels.iter().map(|&l| l as i64 - 1).collect();
        let clusters = (*hand.iter().max().unwrap() + 1) as usize;
        let sizes: Vec<usize> = (0..clusters as i64)
            .map(|c| hand.iter().filter(|&&l| l == c).count())
            .collect();
        println!(
            "eps {eps}: cluster sizes {sizes:?}, noise {}, ix labels - 1 == hand labels: {}",
            hand.iter().filter(|&&l| l == -1).count(),
            shifted == hand
        );
        if eps == 1.0 {
            println!(
                "clusters (rows, noise last) against OS:\n{}",
                crosstab(
                    hand.iter()
                        .map(|&l| if l < 0 { clusters } else { l as usize }),
                    &jobs.os,
                    clusters + 1
                )
            );
        }
    }

    // 6. Gaussian mixture with diagonal covariances: IX's EM, then one more EM step by hand from IX's parameters
    println!("\n== Gaussian mixture, k = 3, diagonal covariances");
    let mut gmm = GMM::new(3).with_seed(42);
    let g_labels = gmm.fit_predict(&x);
    let fitted = Mixture {
        weights: gmm.weights.clone().unwrap(),
        means: gmm.means.clone().unwrap(),
        variances: gmm.covariances.clone().unwrap(),
    };
    let next = em_step(&x, &fitted);
    println!("weights {}", fmt_vec(fitted.weights.iter().copied(), 3));
    println!(
        "log-likelihood ix {:.3}, hand {:.3}, after one more hand step {:.3}",
        gmm.log_likelihood(&x),
        log_likelihood(&x, &fitted),
        log_likelihood(&x, &next)
    );
    let moved = (&next.means - &fitted.means)
        .iter()
        .fold(0.0_f64, |m, d| m.max(d.abs()));
    println!(
        "largest change of a mean in that step: {}",
        if moved < 1e-3 {
            "below 1e-3"
        } else {
            "1e-3 or more"
        }
    );
    println!(
        "components (rows) against OS:\n{}",
        crosstab(g_labels.iter().copied(), &jobs.os, 3)
    );
    for (j, name) in jobs.feature_names.iter().enumerate() {
        println!(
            "variance of {name:15} per component {}",
            fmt_vec(fitted.variances.column(j).iter().copied(), 6)
        );
    }
    let by_seed: Vec<f64> = (0..10)
        .map(|seed| {
            let mut g = GMM::new(3).with_seed(seed);
            g.fit(&x);
            g.log_likelihood(&x)
        })
        .collect();
    println!("log-likelihood, seeds 0 to 9: {}", fmt_vec(by_seed, 3));
}
