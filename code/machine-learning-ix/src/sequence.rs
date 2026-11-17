//! Lesson 10: sequences. A Markov chain's stationary distribution and mean first-passage times solved
//! exactly, and a hidden Markov model's forward, Viterbi and posterior computations written by hand in log
//! space, to compare with `ix_graph`.

use crate::ensemble::Rng;
use ndarray::{Array1, Array2};

/// A number in [0, 1) from the top 53 bits of one draw: exact in binary64, so Python replays it.
pub fn uniform(rng: &mut Rng) -> f64 {
    (rng.next_u64() >> 11) as f64 / (1u64 << 53) as f64
}

/// The first index whose cumulative probability exceeds `u`, or the last index if rounding leaves the
/// total at or below `u`.
pub fn draw(p: impl IntoIterator<Item = f64>, u: f64) -> usize {
    let mut cumulative = 0.0;
    let mut last = 0;
    for (i, pi) in p.into_iter().enumerate() {
        cumulative += pi;
        if u < cumulative {
            return i;
        }
        last = i;
    }
    last
}

/// Solves `a x = b` by Gaussian elimination with partial pivoting. For the small dense systems of this lesson.
pub fn solve(a: &Array2<f64>, b: &Array1<f64>) -> Array1<f64> {
    let n = b.len();
    let mut m = a.clone();
    let mut x = b.clone();
    for col in 0..n {
        let pivot = (col..n)
            .max_by(|&i, &j| m[[i, col]].abs().total_cmp(&m[[j, col]].abs()))
            .expect("non-empty");
        assert!(m[[pivot, col]] != 0.0, "singular system");
        if pivot != col {
            for k in 0..n {
                m.swap([pivot, k], [col, k]);
            }
            x.swap(pivot, col);
        }
        for row in col + 1..n {
            let factor = m[[row, col]] / m[[col, col]];
            for k in col..n {
                m[[row, k]] -= factor * m[[col, k]];
            }
            x[row] -= factor * x[col];
        }
    }
    for row in (0..n).rev() {
        let tail: f64 = (row + 1..n).map(|k| m[[row, k]] * x[k]).sum();
        x[row] = (x[row] - tail) / m[[row, row]];
    }
    x
}

/// The stationary distribution: π P = π with Σ π = 1. The system (Pᵀ − I) π = 0 has rank n − 1 for an
/// irreducible chain, so its last equation is replaced by Σ π = 1.
pub fn stationary_exact(p: &Array2<f64>) -> Array1<f64> {
    let n = p.nrows();
    let mut a = Array2::from_shape_fn((n, n), |(i, j)| p[[j, i]] - if i == j { 1.0 } else { 0.0 });
    let mut b = Array1::zeros(n);
    for j in 0..n {
        a[[n - 1, j]] = 1.0;
    }
    b[n - 1] = 1.0;
    solve(&a, &b)
}

/// The expected number of steps to reach `to` from each state: m_i = 1 + Σ_{j ≠ to} P_ij m_j. The entry of
/// `to` itself is the mean return time, which Kac's lemma says is 1/π_to.
pub fn mean_first_passage_exact(p: &Array2<f64>, to: usize) -> Array1<f64> {
    let n = p.nrows();
    let others: Vec<usize> = (0..n).filter(|&i| i != to).collect();
    let k = others.len();
    let a = Array2::from_shape_fn((k, k), |(r, c)| {
        (if r == c { 1.0 } else { 0.0 }) - p[[others[r], others[c]]]
    });
    let m = solve(&a, &Array1::ones(k));
    let mut out = Array1::zeros(n);
    for (r, &i) in others.iter().enumerate() {
        out[i] = m[r];
    }
    out[to] = 1.0
        + others
            .iter()
            .enumerate()
            .map(|(r, &j)| p[[to, j]] * m[r])
            .sum::<f64>();
    out
}

/// ln p, with ln 0 = −∞ written out rather than left to `f64::ln`.
fn ln(p: f64) -> f64 {
    if p > 0.0 { p.ln() } else { f64::NEG_INFINITY }
}

/// ln Σ exp(vᵢ), shifted by the largest term so that the largest exponential is exp(0) = 1.
pub fn log_sum_exp(v: &[f64]) -> f64 {
    let max = v.iter().copied().fold(f64::NEG_INFINITY, f64::max);
    if max == f64::NEG_INFINITY {
        return max;
    }
    max + v.iter().map(|x| (x - max).exp()).sum::<f64>().ln()
}

/// A discrete hidden Markov model: `initial[i]`, `transition[[i, j]]` and `emission[[i, k]]`, the same
/// three tables as `ix_graph::hmm::HiddenMarkovModel`.
#[derive(Clone, Debug)]
pub struct Hmm {
    pub initial: Array1<f64>,
    pub transition: Array2<f64>,
    pub emission: Array2<f64>,
}

impl Hmm {
    /// The occasionally dishonest casino of Durbin, Eddy, Krogh and Mitchison (1998), section 3.2. State 0 is
    /// a fair die, state 1 a loaded one that shows a six half the time; the faces are 0 to 5 here.
    pub fn casino() -> Hmm {
        Hmm {
            initial: Array1::from(vec![0.5, 0.5]),
            transition: Array2::from_shape_vec((2, 2), vec![0.95, 0.05, 0.1, 0.9]).expect("2 × 2"),
            emission: Array2::from_shape_vec(
                (2, 6),
                vec![
                    1. / 6.,
                    1. / 6.,
                    1. / 6.,
                    1. / 6.,
                    1. / 6.,
                    1. / 6.,
                    0.1,
                    0.1,
                    0.1,
                    0.1,
                    0.1,
                    0.5,
                ],
            )
            .expect("2 × 6"),
        }
    }

    pub fn n_states(&self) -> usize {
        self.initial.len()
    }

    /// `t` hidden states and the symbols they emit. Per step: one draw for the state, one for the symbol.
    pub fn sample(&self, t: usize, rng: &mut Rng) -> (Vec<usize>, Vec<usize>) {
        let mut states = Vec::with_capacity(t);
        let mut symbols = Vec::with_capacity(t);
        for step in 0..t {
            let state = if step == 0 {
                draw(self.initial.iter().copied(), uniform(rng))
            } else {
                draw(
                    self.transition.row(states[step - 1]).iter().copied(),
                    uniform(rng),
                )
            };
            states.push(state);
            symbols.push(draw(self.emission.row(state).iter().copied(), uniform(rng)));
        }
        (states, symbols)
    }

    /// P(observations) by the forward recursion in probability space, with no scaling. It underflows to 0
    /// once the probability falls below the smallest binary64 number.
    pub fn forward_plain(&self, obs: &[usize]) -> f64 {
        let n = self.n_states();
        let mut alpha: Vec<f64> = (0..n)
            .map(|i| self.initial[i] * self.emission[[i, obs[0]]])
            .collect();
        for &o in &obs[1..] {
            alpha = (0..n)
                .map(|j| {
                    (0..n)
                        .map(|i| alpha[i] * self.transition[[i, j]])
                        .sum::<f64>()
                        * self.emission[[j, o]]
                })
                .collect();
        }
        alpha.iter().sum()
    }

    /// ln α_t(i) for every t and i, by the forward recursion in log space.
    pub fn log_alpha(&self, obs: &[usize]) -> Array2<f64> {
        let n = self.n_states();
        let mut la = Array2::zeros((obs.len(), n));
        for i in 0..n {
            la[[0, i]] = ln(self.initial[i]) + ln(self.emission[[i, obs[0]]]);
        }
        for t in 1..obs.len() {
            for j in 0..n {
                let terms: Vec<f64> = (0..n)
                    .map(|i| la[[t - 1, i]] + ln(self.transition[[i, j]]))
                    .collect();
                la[[t, j]] = log_sum_exp(&terms) + ln(self.emission[[j, obs[t]]]);
            }
        }
        la
    }

    /// ln P(observations).
    pub fn forward_log(&self, obs: &[usize]) -> f64 {
        let la = self.log_alpha(obs);
        log_sum_exp(&la.row(obs.len() - 1).to_vec())
    }

    /// P(state i at t | observations), from the forward and backward recursions in log space.
    pub fn posteriors(&self, obs: &[usize]) -> Array2<f64> {
        let (t_len, n) = (obs.len(), self.n_states());
        let la = self.log_alpha(obs);
        let mut lb = Array2::zeros((t_len, n));
        for t in (0..t_len - 1).rev() {
            for i in 0..n {
                let terms: Vec<f64> = (0..n)
                    .map(|j| {
                        ln(self.transition[[i, j]])
                            + ln(self.emission[[j, obs[t + 1]]])
                            + lb[[t + 1, j]]
                    })
                    .collect();
                lb[[t, i]] = log_sum_exp(&terms);
            }
        }
        let total = log_sum_exp(&la.row(t_len - 1).to_vec());
        Array2::from_shape_fn((t_len, n), |(t, i)| (la[[t, i]] + lb[[t, i]] - total).exp())
    }

    /// The most probable state sequence and its log-probability. Ties go to the lowest state index, the rule
    /// IX's `viterbi` applies with its strict `>`.
    pub fn viterbi(&self, obs: &[usize]) -> (Vec<usize>, f64) {
        let (t_len, n) = (obs.len(), self.n_states());
        let mut delta = Array2::zeros((t_len, n));
        let mut back = Array2::<usize>::zeros((t_len, n));
        for i in 0..n {
            delta[[0, i]] = ln(self.initial[i]) + ln(self.emission[[i, obs[0]]]);
        }
        for t in 1..t_len {
            for j in 0..n {
                let (mut best, mut arg) = (f64::NEG_INFINITY, 0);
                for i in 0..n {
                    let v = delta[[t - 1, i]] + ln(self.transition[[i, j]]);
                    if v > best {
                        best = v;
                        arg = i;
                    }
                }
                delta[[t, j]] = best + ln(self.emission[[j, obs[t]]]);
                back[[t, j]] = arg;
            }
        }
        let (mut best, mut last) = (f64::NEG_INFINITY, 0);
        for i in 0..n {
            if delta[[t_len - 1, i]] > best {
                best = delta[[t_len - 1, i]];
                last = i;
            }
        }
        let mut path = vec![last; t_len];
        for t in (0..t_len - 1).rev() {
            path[t] = back[[t + 1, path[t + 1]]];
        }
        (path, best)
    }

    /// ln P(path, observations): the log-probability of one given state sequence.
    pub fn path_log_probability(&self, path: &[usize], obs: &[usize]) -> f64 {
        let mut lp = ln(self.initial[path[0]]) + ln(self.emission[[path[0], obs[0]]]);
        for t in 1..obs.len() {
            lp +=
                ln(self.transition[[path[t - 1], path[t]]]) + ln(self.emission[[path[t], obs[t]]]);
        }
        lp
    }
}

/// For each t, the state with the largest posterior, lowest index on a tie.
pub fn argmax_rows(p: &Array2<f64>) -> Vec<usize> {
    p.rows()
        .into_iter()
        .map(|row| {
            let mut best = 0;
            for (i, &v) in row.iter().enumerate() {
                if v > row[best] {
                    best = i;
                }
            }
            best
        })
        .collect()
}

/// The share of positions where two sequences agree.
pub fn agreement(a: &[usize], b: &[usize]) -> f64 {
    a.iter().zip(b).filter(|(x, y)| x == y).count() as f64 / a.len() as f64
}

/// The number of maximal runs of `state` in a sequence.
pub fn runs_of(path: &[usize], state: usize) -> usize {
    path.iter()
        .enumerate()
        .filter(|&(t, &s)| s == state && (t == 0 || path[t - 1] != state))
        .count()
}

#[cfg(test)]
mod tests {
    use super::*;
    use ndarray::array;

    #[test]
    fn stationary_of_a_two_state_chain_is_known_in_closed_form() {
        // For [[1 - a, a], [b, 1 - b]], π = (b, a) / (a + b).
        let p = array![[0.7, 0.3], [0.2, 0.8]];
        let pi = stationary_exact(&p);
        assert!((pi[0] - 0.4).abs() < 1e-15 && (pi[1] - 0.6).abs() < 1e-15);
    }

    #[test]
    fn kac_return_time_is_one_over_pi() {
        let p = array![[0.7, 0.3], [0.2, 0.8]];
        let m = mean_first_passage_exact(&p, 0);
        assert!((m[0] - 1.0 / 0.4).abs() < 1e-12, "{}", m[0]);
        // From state 1, each step leaves with probability 0.2: a geometric wait of mean 5.
        assert!((m[1] - 5.0).abs() < 1e-12, "{}", m[1]);
    }

    #[test]
    fn log_forward_matches_plain_forward_on_a_short_sequence() {
        let hmm = Hmm::casino();
        let obs = [5, 5, 0, 3, 5];
        assert!((hmm.forward_log(&obs) - hmm.forward_plain(&obs).ln()).abs() < 1e-12);
    }

    #[test]
    fn viterbi_path_scores_its_own_log_probability() {
        let hmm = Hmm::casino();
        let obs = [5, 5, 5, 0, 1, 2, 5, 5];
        let (path, lp) = hmm.viterbi(&obs);
        assert!((hmm.path_log_probability(&path, &obs) - lp).abs() < 1e-12);
    }

    #[test]
    fn a_failing_check_fails() {
        // Negative control: a path that is not the Viterbi path scores lower.
        let hmm = Hmm::casino();
        let obs = [5, 5, 5, 5, 5, 5];
        let (path, lp) = hmm.viterbi(&obs);
        let flipped: Vec<usize> = path.iter().map(|s| 1 - s).collect();
        assert!(hmm.path_log_probability(&flipped, &obs) < lp);
        assert!(agreement(&path, &flipped) < 1.0);
    }
}
