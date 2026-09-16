//! Lesson 6: many weak trees instead of one deep tree. Bootstrap samples, a random forest that
//! draws its features at every split, out-of-bag scoring, and gradient boosting on stumps.

use crate::classify::{Tree, gini, tree_predict};
use ndarray::{Array1, Array2};

/// A 64-bit xorshift generator. IX draws from `rand::rngs::StdRng`, which Python cannot replay;
/// this one is three shifts and three XORs, so the cross-check reproduces every draw.
pub struct Rng(u64);

impl Rng {
    /// Seed 0 would be a fixed point of xorshift, so it is pushed to 1.
    pub fn new(seed: u64) -> Rng {
        Rng(if seed == 0 { 1 } else { seed })
    }

    pub fn next_u64(&mut self) -> u64 {
        let mut x = self.0;
        x ^= x << 13;
        x ^= x >> 7;
        x ^= x << 17;
        self.0 = x;
        x
    }

    /// A number in `0..bound`.
    pub fn below(&mut self, bound: usize) -> usize {
        (self.next_u64() % bound as u64) as usize
    }
}

/// `n` row indices drawn with replacement: one bootstrap sample.
pub fn bootstrap(n: usize, rng: &mut Rng) -> Vec<usize> {
    (0..n).map(|_| rng.below(n)).collect()
}

/// The rows a bootstrap sample left out — on average about 37 % of them, since a row escapes
/// `n` draws with probability `(1 - 1/n)^n`, which tends to `1/e`.
pub fn out_of_bag(n: usize, sample: &[usize]) -> Vec<usize> {
    let mut drawn = vec![false; n];
    for &i in sample {
        drawn[i] = true;
    }
    (0..n).filter(|&i| !drawn[i]).collect()
}

fn class_counts(y: &Array1<usize>, rows: &[usize], classes: usize) -> Vec<usize> {
    let mut counts = vec![0; classes];
    for &r in rows {
        counts[y[r]] += 1;
    }
    counts
}

/// A CART tree that, at every node, looks at only `max_features` features drawn without
/// replacement — Breiman's random forest. Ties in the majority go to the smallest class index.
pub fn fit_tree_random_features(
    x: &Array2<f64>,
    y: &Array1<usize>,
    rows: &[usize],
    classes: usize,
    max_depth: usize,
    max_features: usize,
    rng: &mut Rng,
) -> Tree {
    let counts = class_counts(y, rows, classes);
    let majority = (0..classes)
        .max_by_key(|&c| (counts[c], std::cmp::Reverse(c)))
        .unwrap();
    if max_depth == 0 || gini(&counts) == 0.0 || rows.len() < 2 {
        return Tree::Leaf {
            class: majority,
            counts,
        };
    }

    // The features of this node: a partial Fisher-Yates shuffle, as IX runs once per tree
    let p = x.ncols();
    let mut pool: Vec<usize> = (0..p).collect();
    let take = max_features.min(p);
    for i in 0..take {
        let j = i + rng.below(p - i);
        pool.swap(i, j);
    }

    let parent = gini(&counts);
    let mut best: Option<(f64, usize, f64)> = None;
    for &feature in &pool[..take] {
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
                left: Box::new(fit_tree_random_features(
                    x,
                    y,
                    &left,
                    classes,
                    max_depth - 1,
                    max_features,
                    rng,
                )),
                right: Box::new(fit_tree_random_features(
                    x,
                    y,
                    &right,
                    classes,
                    max_depth - 1,
                    max_features,
                    rng,
                )),
            }
        }
        _ => Tree::Leaf {
            class: majority,
            counts,
        },
    }
}

/// A forest of trees, each grown on its own bootstrap sample.
pub struct Forest {
    pub trees: Vec<Tree>,
    /// The rows each tree did not see
    pub oob: Vec<Vec<usize>>,
    pub classes: usize,
}

impl Forest {
    /// `max_features` features per split; pass `x.ncols()` for plain bagging.
    pub fn fit(
        x: &Array2<f64>,
        y: &Array1<usize>,
        classes: usize,
        n_trees: usize,
        max_depth: usize,
        max_features: usize,
        seed: u64,
    ) -> Forest {
        let n = x.nrows();
        let mut rng = Rng::new(seed);
        let (mut trees, mut oob) = (Vec::new(), Vec::new());
        for _ in 0..n_trees {
            let sample = bootstrap(n, &mut rng);
            oob.push(out_of_bag(n, &sample));
            trees.push(fit_tree_random_features(
                x,
                y,
                &sample,
                classes,
                max_depth,
                max_features,
                &mut rng,
            ));
        }
        Forest {
            trees,
            oob,
            classes,
        }
    }

    /// How many trees vote for each class, row by row.
    pub fn votes(&self, x: &Array2<f64>) -> Array2<usize> {
        let mut v = Array2::zeros((x.nrows(), self.classes));
        for tree in &self.trees {
            for i in 0..x.nrows() {
                v[[i, tree_predict(tree, x.row(i))]] += 1;
            }
        }
        v
    }

    /// Majority vote; a tie goes to the smallest class index, as scikit-learn does.
    pub fn predict(&self, x: &Array2<f64>) -> Array1<usize> {
        let v = self.votes(x);
        (0..x.nrows())
            .map(|i| {
                let best = v.row(i).iter().copied().max().unwrap();
                v.row(i).iter().position(|&c| c == best).unwrap()
            })
            .collect()
    }

    /// Out-of-bag accuracy: every row judged only by the trees that never saw it. It needs no
    /// test set, and it is the estimate bagging gives away for free.
    pub fn oob_accuracy(&self, x: &Array2<f64>, y: &Array1<usize>) -> f64 {
        let n = x.nrows();
        let mut votes = Array2::<usize>::zeros((n, self.classes));
        for (tree, rows) in self.trees.iter().zip(&self.oob) {
            for &i in rows {
                votes[[i, tree_predict(tree, x.row(i))]] += 1;
            }
        }
        let (mut judged, mut right) = (0, 0);
        for i in 0..n {
            let best = votes.row(i).iter().copied().max().unwrap();
            if best == 0 {
                continue;
            }
            judged += 1;
            if votes.row(i).iter().position(|&c| c == best).unwrap() == y[i] {
                right += 1;
            }
        }
        right as f64 / judged as f64
    }
}

/// A depth-1 regression tree: the split of one feature that best separates the residuals.
/// Leaves hold the mean residual, the value `ix_ensemble` uses.
pub struct Stump {
    pub feature: usize,
    pub threshold: f64,
    pub left: f64,
    pub right: f64,
}

impl Stump {
    /// Maximizing `n_L·mean_L² + n_R·mean_R²` is the same as minimizing the squared error,
    /// because the total sum of squares does not depend on where the split falls.
    pub fn fit(x: &Array2<f64>, residuals: &Array1<f64>) -> Stump {
        let (n, p) = x.dim();
        let total: f64 = residuals.sum();
        let mean = total / n as f64;
        let mut best = (f64::NEG_INFINITY, 0usize, 0.0, mean, mean);
        for feature in 0..p {
            let mut order: Vec<usize> = (0..n).collect();
            order.sort_by(|&a, &b| x[[a, feature]].total_cmp(&x[[b, feature]]));
            let mut left_sum = 0.0;
            for cut in 0..n - 1 {
                left_sum += residuals[order[cut]];
                let (lo, hi) = (x[[order[cut], feature]], x[[order[cut + 1], feature]]);
                if (lo - hi).abs() < 1e-12 {
                    continue;
                }
                let (left_n, right_n) = (cut + 1, n - cut - 1);
                let left_mean = left_sum / left_n as f64;
                let right_mean = (total - left_sum) / right_n as f64;
                let score = left_n as f64 * left_mean * left_mean
                    + right_n as f64 * right_mean * right_mean;
                if score > best.0 {
                    best = (score, feature, (lo + hi) / 2.0, left_mean, right_mean);
                }
            }
        }
        Stump {
            feature: best.1,
            threshold: best.2,
            left: best.3,
            right: best.4,
        }
    }

    pub fn predict(&self, x: &Array2<f64>) -> Array1<f64> {
        (0..x.nrows())
            .map(|i| {
                if x[[i, self.feature]] <= self.threshold {
                    self.left
                } else {
                    self.right
                }
            })
            .collect()
    }
}

/// `exp(s) / Σ exp(s)` row by row, shifted by the largest score so the exponential cannot overflow.
pub fn softmax(scores: &Array2<f64>) -> Array2<f64> {
    let mut p = scores.clone();
    for mut row in p.rows_mut() {
        let max = row.iter().copied().fold(f64::NEG_INFINITY, f64::max);
        row.mapv_inplace(|s| (s - max).exp());
        let sum = row.sum();
        row.mapv_inplace(|e| e / sum);
    }
    p
}

/// Multiclass gradient boosting on stumps, the way `ix_ensemble` does it: start from the
/// smoothed log priors, then at each round fit one stump per class to the residual
/// `1 if y = c else 0`, minus the probability the model currently gives class `c`.
pub struct Boosted {
    pub init: Array1<f64>,
    /// `rounds[r][c]`
    pub rounds: Vec<Vec<Stump>>,
    pub learning_rate: f64,
    pub classes: usize,
}

impl Boosted {
    pub fn fit(
        x: &Array2<f64>,
        y: &Array1<usize>,
        classes: usize,
        n_rounds: usize,
        learning_rate: f64,
    ) -> Boosted {
        let n = x.nrows();
        let mut counts = vec![0usize; classes];
        for &label in y {
            counts[label] += 1;
        }
        let init: Array1<f64> = counts
            .iter()
            .map(|&c| ((c as f64 + 1.0) / (n as f64 + classes as f64)).ln())
            .collect();

        let mut scores = Array2::from_shape_fn((n, classes), |(_, c)| init[c]);
        let mut rounds = Vec::new();
        for _ in 0..n_rounds {
            let proba = softmax(&scores);
            let mut stumps = Vec::new();
            for c in 0..classes {
                let residuals: Array1<f64> = (0..n)
                    .map(|i| (y[i] == c) as u8 as f64 - proba[[i, c]])
                    .collect();
                let stump = Stump::fit(x, &residuals);
                let step = stump.predict(x);
                for i in 0..n {
                    scores[[i, c]] += learning_rate * step[i];
                }
                stumps.push(stump);
            }
            rounds.push(stumps);
        }
        Boosted {
            init,
            rounds,
            learning_rate,
            classes,
        }
    }

    pub fn raw_scores(&self, x: &Array2<f64>) -> Array2<f64> {
        let mut scores = Array2::from_shape_fn((x.nrows(), self.classes), |(_, c)| self.init[c]);
        for round in &self.rounds {
            for (c, stump) in round.iter().enumerate() {
                let step = stump.predict(x);
                for i in 0..x.nrows() {
                    scores[[i, c]] += self.learning_rate * step[i];
                }
            }
        }
        scores
    }

    /// A tie goes to the smallest class index.
    pub fn predict(&self, x: &Array2<f64>) -> Array1<usize> {
        let p = softmax(&self.raw_scores(x));
        (0..x.nrows())
            .map(|i| {
                let best = p.row(i).iter().copied().fold(f64::NEG_INFINITY, f64::max);
                p.row(i).iter().position(|&v| v == best).unwrap()
            })
            .collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use ndarray::array;

    #[test]
    fn a_bootstrap_leaves_about_a_third_of_the_rows_out() {
        let mut rng = Rng::new(42);
        let left_out: usize = (0..200)
            .map(|_| out_of_bag(100, &bootstrap(100, &mut rng)).len())
            .sum();
        let share = left_out as f64 / (200.0 * 100.0);
        assert!((share - 1.0 / std::f64::consts::E).abs() < 0.02, "{share}");
    }

    #[test]
    fn the_generator_repeats_from_the_same_seed() {
        let (mut a, mut b) = (Rng::new(7), Rng::new(7));
        assert_eq!(a.next_u64(), b.next_u64());
        assert_ne!(Rng::new(7).next_u64(), Rng::new(8).next_u64());
    }

    #[test]
    fn a_forest_learns_a_threshold() {
        let x = array![[1.0], [2.0], [8.0], [9.0]];
        let y = array![0, 0, 1, 1];
        let forest = Forest::fit(&x, &y, 2, 25, 3, 1, 42);
        assert_eq!(forest.predict(&array![[1.5], [8.5]]), array![0, 1]);
    }

    #[test]
    fn a_stump_splits_the_residuals() {
        let x = array![[0.0], [1.0], [2.0], [3.0]];
        let stump = Stump::fit(&x, &array![-1.0, -1.0, 1.0, 1.0]);
        assert_eq!(stump.threshold, 1.5);
        assert_eq!((stump.left, stump.right), (-1.0, 1.0));
    }

    #[test]
    fn boosting_separates_two_groups() {
        let x = array![[0.0], [1.0], [8.0], [9.0]];
        let y = array![0, 0, 1, 1];
        let model = Boosted::fit(&x, &y, 2, 20, 0.3);
        assert_eq!(model.predict(&x), y);
    }
}
