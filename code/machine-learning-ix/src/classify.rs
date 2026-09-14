//! Lesson 3: logistic regression, k nearest neighbours and a decision tree, written by hand.

use ndarray::{Array1, Array2, ArrayView1};

pub fn sigmoid(z: f64) -> f64 {
    1.0 / (1.0 + (-z).exp())
}

/// Binary logistic regression by batch gradient descent on the log loss, from w = 0 and b = 0.
/// The gradient of the mean log loss is 1/n Σ (sigmoid(w·x + b) - y)·x, and 1/n Σ (sigmoid(w·x + b) - y) for b.
pub fn fit_logistic(
    x: &Array2<f64>,
    y: &Array1<usize>,
    learning_rate: f64,
    iterations: usize,
) -> (Array1<f64>, f64) {
    let (n, p) = x.dim();
    let (mut w, mut b) = (Array1::<f64>::zeros(p), 0.0);
    for _ in 0..iterations {
        let mut dw = Array1::<f64>::zeros(p);
        let mut db = 0.0;
        for i in 0..n {
            let error = sigmoid(x.row(i).dot(&w) + b) - y[i] as f64;
            dw.scaled_add(error / n as f64, &x.row(i));
            db += error / n as f64;
        }
        w.scaled_add(-learning_rate, &dw);
        b -= learning_rate * db;
    }
    (w, b)
}

fn distance(a: ArrayView1<f64>, b: ArrayView1<f64>) -> f64 {
    a.iter()
        .zip(b)
        .map(|(u, v)| (u - v).powi(2))
        .sum::<f64>()
        .sqrt()
}

/// Majority vote among the k nearest training rows. A tie goes to the smallest class index, as in scikit-learn.
pub fn knn_predict(
    x_train: &Array2<f64>,
    y_train: &Array1<usize>,
    x: &Array2<f64>,
    k: usize,
    classes: usize,
) -> Array1<usize> {
    x.rows()
        .into_iter()
        .map(|row| {
            let mut near: Vec<(f64, usize)> = x_train
                .rows()
                .into_iter()
                .map(|t| distance(row, t))
                .zip(y_train.iter().copied())
                .collect();
            // A stable sort keeps equal distances in training order
            near.sort_by(|a, b| a.0.total_cmp(&b.0));
            let mut votes = vec![0; classes];
            for &(_, class) in &near[..k] {
                votes[class] += 1;
            }
            let best = *votes.iter().max().unwrap();
            votes.iter().position(|&v| v == best).unwrap()
        })
        .collect()
}

/// A CART tree: each split sends x[feature] <= threshold left, the rest right.
#[derive(Debug)]
pub enum Tree {
    Leaf {
        class: usize,
        counts: Vec<usize>,
    },
    Split {
        feature: usize,
        threshold: f64,
        left: Box<Tree>,
        right: Box<Tree>,
    },
}

/// Gini impurity: the probability that two rows drawn at random (with replacement) have different classes.
pub fn gini(counts: &[usize]) -> f64 {
    let n: usize = counts.iter().sum();
    if n == 0 {
        return 0.0;
    }
    1.0 - counts
        .iter()
        .map(|&c| (c as f64 / n as f64).powi(2))
        .sum::<f64>()
}

fn class_counts(y: &Array1<usize>, rows: &[usize], classes: usize) -> Vec<usize> {
    let mut counts = vec![0; classes];
    for &r in rows {
        counts[y[r]] += 1;
    }
    counts
}

/// Grows the tree on `rows`: at each node, the split with the largest drop in weighted Gini impurity,
/// trying every feature and every midpoint between two consecutive distinct values.
pub fn fit_tree(
    x: &Array2<f64>,
    y: &Array1<usize>,
    rows: &[usize],
    classes: usize,
    max_depth: usize,
) -> Tree {
    let counts = class_counts(y, rows, classes);
    let majority = (0..classes)
        .max_by_key(|&c| (counts[c], std::cmp::Reverse(c)))
        .unwrap();
    if max_depth == 0 || gini(&counts) == 0.0 {
        return Tree::Leaf {
            class: majority,
            counts,
        };
    }
    let parent = gini(&counts);
    let mut best: Option<(f64, usize, f64)> = None;
    for feature in 0..x.ncols() {
        let mut sorted = rows.to_vec();
        sorted.sort_by(|&a, &b| x[[a, feature]].total_cmp(&x[[b, feature]]));
        for cut in 1..sorted.len() {
            let (lo, hi) = (x[[sorted[cut - 1], feature]], x[[sorted[cut], feature]]);
            if lo == hi {
                continue;
            }
            let (left, right) = sorted.split_at(cut);
            let weighted = (left.len() as f64 * gini(&class_counts(y, left, classes))
                + right.len() as f64 * gini(&class_counts(y, right, classes)))
                / rows.len() as f64;
            let gain = parent - weighted;
            if best.is_none_or(|(g, _, _)| gain > g) {
                best = Some((gain, feature, (lo + hi) / 2.0));
            }
        }
    }
    match best {
        Some((gain, feature, threshold)) if gain > 0.0 => {
            let (left, right): (Vec<usize>, Vec<usize>) =
                rows.iter().partition(|&&r| x[[r, feature]] <= threshold);
            Tree::Split {
                feature,
                threshold,
                left: Box::new(fit_tree(x, y, &left, classes, max_depth - 1)),
                right: Box::new(fit_tree(x, y, &right, classes, max_depth - 1)),
            }
        }
        _ => Tree::Leaf {
            class: majority,
            counts,
        },
    }
}

pub fn tree_predict(tree: &Tree, row: ArrayView1<f64>) -> usize {
    match tree {
        Tree::Leaf { class, .. } => *class,
        Tree::Split {
            feature,
            threshold,
            left,
            right,
        } => tree_predict(
            if row[*feature] <= *threshold {
                left
            } else {
                right
            },
            row,
        ),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use ndarray::array;

    #[test]
    fn logistic_separates_two_groups() {
        let x = array![[0.0], [1.0], [4.0], [5.0]];
        let (w, b) = fit_logistic(&x, &array![0, 0, 1, 1], 0.5, 2000);
        assert!(sigmoid(w[0] * 0.5 + b) < 0.5 && sigmoid(w[0] * 4.5 + b) > 0.5);
    }

    #[test]
    fn knn_tie_goes_to_the_smallest_class() {
        let x = array![[0.0], [2.0]];
        assert_eq!(
            knn_predict(&x, &array![1, 0], &array![[1.0]], 2, 2),
            array![0]
        );
    }

    #[test]
    fn gini_values() {
        assert_eq!(gini(&[5, 0]), 0.0);
        assert_eq!(gini(&[1, 1]), 0.5);
    }

    #[test]
    fn tree_finds_the_threshold() {
        let x = array![[1.0], [2.0], [8.0], [9.0]];
        let tree = fit_tree(&x, &array![0, 0, 1, 1], &[0, 1, 2, 3], 2, 3);
        assert!(matches!(tree, Tree::Split { threshold: 5.0, .. }));
    }
}
