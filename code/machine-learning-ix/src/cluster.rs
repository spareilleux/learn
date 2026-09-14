//! Lesson 4: k-means, DBSCAN and the silhouette score, written by hand.

use ndarray::{Array1, Array2, ArrayView1};

fn squared_distance(a: ArrayView1<f64>, b: ArrayView1<f64>) -> f64 {
    a.iter().zip(b).map(|(u, v)| (u - v).powi(2)).sum()
}

/// Index of the nearest centroid; the first one wins a tie.
pub fn nearest(row: ArrayView1<f64>, centroids: &Array2<f64>) -> usize {
    let mut best = 0;
    for c in 1..centroids.nrows() {
        if squared_distance(row, centroids.row(c)) < squared_distance(row, centroids.row(best)) {
            best = c;
        }
    }
    best
}

/// One Lloyd iteration: assign every row to its nearest centroid, then move each centroid to the mean of its rows.
/// A centroid that gets no row stays where it is.
pub fn lloyd_step(x: &Array2<f64>, centroids: &Array2<f64>) -> (Array1<usize>, Array2<f64>) {
    let labels: Array1<usize> = x
        .rows()
        .into_iter()
        .map(|r| nearest(r, centroids))
        .collect();
    let mut moved = centroids.clone();
    for c in 0..centroids.nrows() {
        let members: Vec<usize> = (0..x.nrows()).filter(|&i| labels[i] == c).collect();
        if !members.is_empty() {
            let sum = members
                .iter()
                .fold(Array1::<f64>::zeros(x.ncols()), |acc, &i| acc + x.row(i));
            moved.row_mut(c).assign(&(sum / members.len() as f64));
        }
    }
    (labels, moved)
}

/// Lloyd iterations from the given centroids until no centroid moves.
pub fn kmeans_from(
    x: &Array2<f64>,
    mut centroids: Array2<f64>,
    max_iterations: usize,
) -> (Array1<usize>, Array2<f64>, usize) {
    for iteration in 1..=max_iterations {
        let (labels, moved) = lloyd_step(x, &centroids);
        if moved == centroids {
            return (labels, centroids, iteration);
        }
        centroids = moved;
    }
    let (labels, _) = lloyd_step(x, &centroids);
    (labels, centroids, max_iterations)
}

/// Sum of squared distances from each row to its centroid.
pub fn inertia(x: &Array2<f64>, labels: &Array1<usize>, centroids: &Array2<f64>) -> f64 {
    x.rows()
        .into_iter()
        .zip(labels)
        .map(|(r, &c)| squared_distance(r, centroids.row(c)))
        .sum()
}

/// DBSCAN with scikit-learn's conventions: -1 is noise, clusters are 0, 1, …, and min_points counts the point itself.
pub fn dbscan(x: &Array2<f64>, eps: f64, min_points: usize) -> Vec<i64> {
    let n = x.nrows();
    let neighbours = |i: usize| -> Vec<usize> {
        (0..n)
            .filter(|&j| squared_distance(x.row(i), x.row(j)).sqrt() <= eps)
            .collect()
    };
    let mut labels = vec![None::<i64>; n];
    let mut cluster = -1;
    for i in 0..n {
        if labels[i].is_some() {
            continue;
        }
        let around = neighbours(i);
        if around.len() < min_points {
            labels[i] = Some(-1); // noise for now: a later cluster can still reach it as a border point
            continue;
        }
        cluster += 1;
        labels[i] = Some(cluster);
        let mut queue = around;
        while let Some(j) = queue.pop() {
            match labels[j] {
                Some(-1) => labels[j] = Some(cluster), // border point
                None => {
                    labels[j] = Some(cluster);
                    let reach = neighbours(j);
                    if reach.len() >= min_points {
                        queue.extend(reach); // core point: its neighbours join the cluster too
                    }
                }
                _ => {}
            }
        }
    }
    labels.into_iter().map(Option::unwrap).collect()
}

/// Mean silhouette: for each row, a = mean distance to its own cluster, b = smallest mean distance to another cluster,
/// s = (b - a) / max(a, b). A row alone in its cluster scores 0 (Rousseeuw, 1987).
pub fn silhouette(x: &Array2<f64>, labels: &[usize]) -> f64 {
    let n = x.nrows();
    let clusters = labels.iter().max().unwrap() + 1;
    let mut total = 0.0;
    for i in 0..n {
        let mut sums = vec![0.0; clusters];
        let mut sizes = vec![0usize; clusters];
        for j in 0..n {
            if j != i {
                sums[labels[j]] += squared_distance(x.row(i), x.row(j)).sqrt();
                sizes[labels[j]] += 1;
            }
        }
        let own = labels[i];
        if sizes[own] == 0 {
            continue;
        }
        let a = sums[own] / sizes[own] as f64;
        let b = (0..clusters)
            .filter(|&c| c != own && sizes[c] > 0)
            .map(|c| sums[c] / sizes[c] as f64)
            .fold(f64::INFINITY, f64::min);
        total += (b - a) / a.max(b);
    }
    total / n as f64
}

/// A mixture of k Gaussians with diagonal covariances: a weight, a mean and a variance per feature for each component.
#[derive(Clone, Debug)]
pub struct Mixture {
    pub weights: Array1<f64>,
    pub means: Array2<f64>,
    pub variances: Array2<f64>,
}

/// Density of one diagonal Gaussian: Π over features of exp(-(x - m)² / 2v) / sqrt(2πv).
pub fn gaussian_density(
    row: ArrayView1<f64>,
    mean: ArrayView1<f64>,
    variance: ArrayView1<f64>,
) -> f64 {
    row.iter()
        .zip(mean)
        .zip(variance)
        .map(|((x, m), v)| {
            (-(x - m).powi(2) / (2.0 * v)).exp() / (2.0 * std::f64::consts::PI * v).sqrt()
        })
        .product()
}

/// Sum over rows of ln Σ_k weight_k · density_k(row)
pub fn log_likelihood(x: &Array2<f64>, g: &Mixture) -> f64 {
    x.rows()
        .into_iter()
        .map(|r| {
            (0..g.weights.len())
                .map(|k| g.weights[k] * gaussian_density(r, g.means.row(k), g.variances.row(k)))
                .sum::<f64>()
                .ln()
        })
        .sum()
}

/// One expectation-maximization step.
/// E: responsibility r[i][k] = weight_k · density_k(row i), normalized over k.
/// M: weight_k = Σ_i r[i][k] / n, mean_k = Σ_i r[i][k] · row i / Σ_i r[i][k], variance_k likewise, at least 1e-6 as in IX.
pub fn em_step(x: &Array2<f64>, g: &Mixture) -> Mixture {
    let (n, d) = x.dim();
    let k = g.weights.len();
    let mut r = Array2::<f64>::zeros((n, k));
    for i in 0..n {
        for c in 0..k {
            r[[i, c]] =
                g.weights[c] * gaussian_density(x.row(i), g.means.row(c), g.variances.row(c));
        }
        let total = r.row(i).sum();
        r.row_mut(i).mapv_inplace(|v| v / total);
    }
    let mut next = Mixture {
        weights: Array1::zeros(k),
        means: Array2::zeros((k, d)),
        variances: Array2::zeros((k, d)),
    };
    for c in 0..k {
        let nk = r.column(c).sum();
        next.weights[c] = nk / n as f64;
        for j in 0..d {
            let mean = (0..n).map(|i| r[[i, c]] * x[[i, j]]).sum::<f64>() / nk;
            let variance = (0..n)
                .map(|i| r[[i, c]] * (x[[i, j]] - mean).powi(2))
                .sum::<f64>()
                / nk;
            next.means[[c, j]] = mean;
            next.variances[[c, j]] = variance.max(1e-6);
        }
    }
    next
}

#[cfg(test)]
mod tests {
    use super::*;
    use ndarray::array;

    #[test]
    fn em_finds_two_groups() {
        let x = array![[0.0], [0.2], [-0.2], [10.0], [10.2], [9.8]];
        let mut g = Mixture {
            weights: array![0.5, 0.5],
            means: array![[1.0], [8.0]],
            variances: array![[1.0], [1.0]],
        };
        let before = log_likelihood(&x, &g);
        for _ in 0..50 {
            g = em_step(&x, &g);
        }
        assert!(log_likelihood(&x, &g) > before);
        assert!((g.means[[0, 0]] - 0.0).abs() < 1e-9 && (g.means[[1, 0]] - 10.0).abs() < 1e-9);
        assert!((g.weights[0] - 0.5).abs() < 1e-9);
    }

    #[test]
    fn kmeans_on_two_groups() {
        let x = array![[0.0], [1.0], [10.0], [11.0]];
        let (labels, centroids, _) = kmeans_from(&x, array![[0.0], [1.0]], 10);
        assert_eq!(labels, array![0, 0, 1, 1]);
        assert_eq!(centroids, array![[0.5], [10.5]]);
        assert_eq!(inertia(&x, &labels, &centroids), 1.0);
    }

    #[test]
    fn dbscan_noise_and_border() {
        let x = array![[0.0], [1.0], [2.0], [3.0], [10.0]];
        assert_eq!(dbscan(&x, 1.0, 3), vec![0, 0, 0, 0, -1]);
    }

    #[test]
    fn silhouette_of_a_singleton_is_zero() {
        let x = array![[0.0], [1.0], [10.0]];
        let s = silhouette(&x, &[0, 0, 1]);
        // rows 0 and 1: a = 1, b = 10 and 9; row 2 alone: 0
        assert!((s - (0.9 + 8.0 / 9.0) / 3.0).abs() < 1e-12);
    }
}
