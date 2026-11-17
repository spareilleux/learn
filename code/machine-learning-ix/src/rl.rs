//! Lesson 14: bandits and tabular reinforcement learning, measured against IX's `ix-rl`.
//!
//! Random numbers come from the course's own `Rng`, and the normal draws of the testbed are sums of twelve
//! uniforms minus six: arithmetic only, so the three CI systems see the same rewards. IX's learners keep
//! their own seeded `StdRng`.

use std::collections::BTreeMap;
use std::panic::{AssertUnwindSafe, catch_unwind};

use ix_rl::bandit::{EpsilonGreedy, ThompsonSampling, UCB1};
use ix_rl::env::GridWorld;
use ix_rl::q_learning::{QLearning, Sarsa};
use ix_rl::traits::{Agent, Environment};

use crate::autodiff::{Outcome, Rng};
use crate::transformer::panic_message;

/// Approximately N(0, 1): twelve uniforms minus six (Irwin–Hall), mean 0 and variance 1
pub fn normal(rng: &mut Rng) -> f64 {
    (0..12).map(|_| rng.next_f64()).sum::<f64>() - 6.0
}

/// What each learner picks when every value is equal: a new ε-greedy of 10 arms and a new Q-learning of
/// 4 actions at ε = 0, and a UCB1 of 5 arms after one reward of 1 from each
pub fn tie_choices() -> (usize, usize, usize) {
    let mut bandit = EpsilonGreedy::new(10, 0.0, 14);
    let mut agent = QLearning::new(1, 4, 14).with_epsilon(0.0);
    (
        bandit.select_arm(),
        agent.select_action_index(0),
        ucb1_after_equal_rewards(5),
    )
}

/// UCB1's choice once each of its `arms` arms has paid 1 exactly once
pub fn ucb1_after_equal_rewards(arms: usize) -> usize {
    let mut ucb = UCB1::new(arms);
    for _ in 0..arms {
        let arm = ucb.select_arm();
        ucb.update(arm, 1.0);
    }
    ucb.select_arm()
}

/// 100 selections of a 3-arm ε-greedy after `reward` on arm 0, run under `catch_unwind`
pub fn selections_after(reward: f64, epsilon: f64) -> Outcome {
    let mut bandit = EpsilonGreedy::new(3, epsilon, 14);
    bandit.update(0, reward);
    match catch_unwind(AssertUnwindSafe(|| {
        for _ in 0..100 {
            bandit.select_arm();
        }
    })) {
        Ok(()) => Outcome::Value,
        Err(payload) => Outcome::Panic(panic_message(payload)),
    }
}

/// For each state of a `rows` × `cols` GridWorld, in `state_index` order, the Q-table row that
/// `Agent::select_action` reads. Every row but k says 3 (left), row k says 0 (up): a state reads row k
/// exactly when the trait picks 0.
pub fn rows_read(rows: usize, cols: usize) -> Vec<usize> {
    let n = rows * cols;
    let env = GridWorld::new(rows, cols, (0, 0), (rows - 1, cols - 1));
    let mut agent = QLearning::new(n, 4, 14);
    let mut read = vec![usize::MAX; n];
    for k in 0..n {
        agent.q_table.fill(0.0);
        agent.q_table.column_mut(3).fill(1.0);
        agent.q_table[[k, 3]] = 0.0;
        agent.q_table[[k, 0]] = 1.0;
        for r in 0..rows {
            for c in 0..cols {
                if <QLearning as Agent<GridWorld>>::select_action(&agent, &(r, c)) == 0 {
                    read[env.state_index(&(r, c))] = k;
                }
            }
        }
    }
    read
}

/// From `rows_read`: how many states read another state's row, which rows two states read, which none
pub fn row_summary(read: &[usize]) -> (usize, Vec<usize>, Vec<usize>) {
    let others = read.iter().enumerate().filter(|&(s, &k)| s != k).count();
    let mut readers = vec![0; read.len()];
    for &k in read {
        readers[k] += 1;
    }
    let rows_with =
        |count: usize| -> Vec<usize> { (0..read.len()).filter(|&k| readers[k] == count).collect() };
    (others, rows_with(2), rows_with(0))
}

/// Largest change of a 5 × 5 GridWorld's Q-table after 1,000 random transitions with rewards in [−1, 1),
/// through `Agent::update` (`trait_update`) or through `update_index`
pub fn update_change(trait_update: bool, seed: u64) -> f64 {
    let env = GridWorld::default_5x5();
    let mut agent = QLearning::new(25, 4, seed);
    let mut rng = Rng(seed);
    let cell = |rng: &mut Rng| {
        (
            (rng.next_f64() * 5.0) as usize,
            (rng.next_f64() * 5.0) as usize,
        )
    };
    for _ in 0..1000 {
        let s = cell(&mut rng);
        let a = (rng.next_f64() * 4.0) as usize;
        let s2 = cell(&mut rng);
        let reward = rng.next_f64() * 2.0 - 1.0;
        if trait_update {
            <QLearning as Agent<GridWorld>>::update(&mut agent, &s, &a, reward, &s2, false);
        } else {
            agent.update_index(env.state_index(&s), a, reward, env.state_index(&s2), false);
        }
    }
    agent.q_table.iter().fold(0.0, |m: f64, q| m.max(q.abs()))
}

/// One move on a grid, by the lesson's own rules: 0 up, 1 right, 2 down, 3 left, and the walls stop you
pub fn grid_move(
    rows: usize,
    cols: usize,
    (r, c): (usize, usize),
    action: usize,
) -> (usize, usize) {
    match action {
        0 => (r.saturating_sub(1), c),
        1 => (r, (c + 1).min(cols - 1)),
        2 => ((r + 1).min(rows - 1), c),
        _ => (r, c.saturating_sub(1)),
    }
}

/// Q* of a GridWorld by value iteration: Q(s, a) = +10 when the move reaches the goal, which ends the
/// episode, else −1 + γ max Q(s', ·). The goal's own row stays 0: no episode acts from it.
pub fn value_iteration(
    rows: usize,
    cols: usize,
    goal: (usize, usize),
    gamma: f64,
    sweeps: usize,
) -> Vec<[f64; 4]> {
    let mut q = vec![[0.0; 4]; rows * cols];
    for _ in 0..sweeps {
        let v: Vec<f64> = q
            .iter()
            .map(|row| row.iter().copied().fold(f64::NEG_INFINITY, f64::max))
            .collect();
        for r in 0..rows {
            for c in 0..cols {
                if (r, c) == goal {
                    continue;
                }
                for (a, value) in q[r * cols + c].iter_mut().enumerate() {
                    let next = grid_move(rows, cols, (r, c), a);
                    *value = if next == goal {
                        10.0
                    } else {
                        -1.0 + gamma * v[next.0 * cols + next.1]
                    };
                }
            }
        }
    }
    q
}

/// V*(start) of the 5 × 5 GridWorld in closed form: seven steps at −1, then +10
pub fn v_start_closed_form(gamma: f64) -> f64 {
    10.0 * gamma.powi(7) - (1.0 - gamma.powi(7)) / (1.0 - gamma)
}

/// Steps of a greedy walk from the start to the goal, or `None` after `limit` steps
fn greedy_walk(
    env: &mut GridWorld,
    limit: usize,
    mut choose: impl FnMut((usize, usize)) -> usize,
) -> Option<usize> {
    let mut state = env.reset();
    for step in 1..=limit {
        let (next, _, done) = env.step(&choose(state));
        if done {
            return Some(step);
        }
        state = next;
    }
    None
}

/// Q-learning on the 5 × 5 GridWorld after `episodes` episodes, against Q* by value iteration
pub struct GridRun {
    pub v_start: f64,
    pub q_start: f64,
    /// greedy walk with the row from `state_index`, and through `Agent::select_action`
    pub steps: Option<usize>,
    pub trait_steps: Option<usize>,
    /// largest |Q − Q*| over the 96 state–actions outside the goal
    pub worst: f64,
    /// mean reward per episode over the first and the last 100 episodes
    pub first: f64,
    pub last: f64,
}

pub fn grid_q_learning(episodes: usize, seed: u64) -> GridRun {
    let mut env = GridWorld::default_5x5();
    let mut agent = QLearning::new(25, 4, seed)
        .with_learning_rate(0.1)
        .with_discount(0.99)
        .with_epsilon(0.1);
    let rewards = agent.train_gridworld(&mut env, episodes, 100);
    let mean = |r: &[f64]| r.iter().sum::<f64>() / r.len().max(1) as f64;
    let q_star = value_iteration(5, 5, (4, 4), 0.99, 200);
    let worst = (0..24)
        .flat_map(|s| (0..4).map(move |a| (s, a)))
        .map(|(s, a)| (agent.q_table[[s, a]] - q_star[s][a]).abs())
        .fold(0.0, f64::max);
    let q_start = agent
        .q_table
        .row(0)
        .iter()
        .copied()
        .fold(f64::NEG_INFINITY, f64::max);
    let trait_steps = greedy_walk(&mut env, 100, |s| {
        <QLearning as Agent<GridWorld>>::select_action(&agent, &s)
    });
    agent.epsilon = 0.0;
    let steps = greedy_walk(&mut env, 100, |s| agent.select_action_index(s.0 * 5 + s.1));
    GridRun {
        v_start: q_star[0].iter().copied().fold(f64::NEG_INFINITY, f64::max),
        q_start,
        steps,
        trait_steps,
        worst,
        first: mean(&rewards[..rewards.len().min(100)]),
        last: mean(&rewards[rewards.len().saturating_sub(100)..]),
    }
}

/// Sutton and Barto's cliff walk (Example 6.6): 4 × 12, start (3, 0), goal (3, 11), the cliff between them
/// on the bottom row. Every move costs −1; a move into the cliff costs −100 and puts you back at the start.
pub struct CliffWalk {
    pub current: (usize, usize),
}

impl CliffWalk {
    pub const START: (usize, usize) = (3, 0);
    pub const GOAL: (usize, usize) = (3, 11);

    pub fn index((r, c): (usize, usize)) -> usize {
        r * 12 + c
    }
}

impl Default for CliffWalk {
    fn default() -> Self {
        Self {
            current: Self::START,
        }
    }
}

impl Environment for CliffWalk {
    type State = (usize, usize);
    type Action = usize;

    fn reset(&mut self) -> Self::State {
        self.current = Self::START;
        self.current
    }

    fn step(&mut self, action: &usize) -> (Self::State, f64, bool) {
        let next = grid_move(4, 12, self.current, *action);
        if next.0 == 3 && (1..=10).contains(&next.1) {
            self.current = Self::START;
            return (self.current, -100.0, false);
        }
        self.current = next;
        (next, -1.0, next == Self::GOAL)
    }

    fn actions(&self) -> Vec<usize> {
        vec![0, 1, 2, 3]
    }
}

/// An episode stops here if it has not reached the goal; with ε = 0.1 none comes close
const CLIFF_LIMIT: usize = 10_000;

/// One run on the cliff: the return of each episode while learning, then the greedy walk after it: its
/// length to the goal, and the states it visits
pub struct CliffRun {
    pub online: Vec<f64>,
    pub greedy: Option<usize>,
    pub walk: Vec<(usize, usize)>,
}

/// The greedy walk on the cliff: steps to the goal, or `None` after 100 steps, and the states visited
fn cliff_greedy(mut choose: impl FnMut(usize) -> usize) -> (Option<usize>, Vec<(usize, usize)>) {
    let mut env = CliffWalk::default();
    let mut state = env.reset();
    let mut walk = vec![state];
    for step in 1..=100 {
        let (next, _, done) = env.step(&choose(CliffWalk::index(state)));
        walk.push(next);
        if done {
            return (Some(step), walk);
        }
        state = next;
    }
    (None, walk)
}

/// IX's `QLearning` on the cliff through `select_action_index` and `update_index`: γ 1, step 0.5, ε 0.1
pub fn cliff_q_learning(episodes: usize, seed: u64) -> CliffRun {
    let mut env = CliffWalk::default();
    let mut agent = QLearning::new(48, 4, seed)
        .with_learning_rate(0.5)
        .with_discount(1.0)
        .with_epsilon(0.1);
    let mut online = Vec::with_capacity(episodes);
    for _ in 0..episodes {
        let mut s = CliffWalk::index(env.reset());
        let mut total = 0.0;
        for _ in 0..CLIFF_LIMIT {
            let a = agent.select_action_index(s);
            let (next, reward, done) = env.step(&a);
            let next = CliffWalk::index(next);
            agent.update_index(s, a, reward, next, done);
            total += reward;
            s = next;
            if done {
                break;
            }
        }
        online.push(total);
    }
    agent.epsilon = 0.0;
    let (greedy, walk) = cliff_greedy(|s| agent.select_action_index(s));
    CliffRun {
        online,
        greedy,
        walk,
    }
}

/// IX's `Sarsa` on the cliff, with the same settings; its fields are public, it has no builder
pub fn cliff_sarsa(episodes: usize, seed: u64) -> CliffRun {
    let mut env = CliffWalk::default();
    let mut agent = Sarsa::new(48, 4, seed);
    agent.learning_rate = 0.5;
    agent.discount = 1.0;
    agent.epsilon = 0.1;
    let mut online = Vec::with_capacity(episodes);
    for _ in 0..episodes {
        let mut s = CliffWalk::index(env.reset());
        let mut a = agent.select_action_index(s);
        let mut total = 0.0;
        for _ in 0..CLIFF_LIMIT {
            let (next, reward, done) = env.step(&a);
            let next = CliffWalk::index(next);
            // the next action is not needed after the goal, and drawing it would move the random stream
            let next_a = if done {
                0
            } else {
                agent.select_action_index(next)
            };
            agent.update_index(s, a, reward, next, next_a, done);
            total += reward;
            if done {
                break;
            }
            s = next;
            a = next_a;
        }
        online.push(total);
    }
    agent.epsilon = 0.0;
    let (greedy, walk) = cliff_greedy(|s| agent.select_action_index(s));
    CliffRun {
        online,
        greedy,
        walk,
    }
}

/// `runs` runs of each: greedy path lengths counted by length (`None` for no path), the mean online
/// return over episodes 101 to 500, and SARSA's walks with no path counted by the length of the cycle they
/// end in (1: the walk stays in one cell against a wall)
pub struct CliffSummary {
    pub q_paths: BTreeMap<Option<usize>, usize>,
    pub sarsa_paths: BTreeMap<Option<usize>, usize>,
    pub q_return: f64,
    pub sarsa_return: f64,
    pub sarsa_cycles: BTreeMap<usize, usize>,
}

/// Length of the cycle a walk ends in: the smallest k with the last state equal to the one k steps before
fn cycle_length(walk: &[(usize, usize)]) -> usize {
    let last = walk.len() - 1;
    (1..last)
        .find(|&k| walk[last] == walk[last - k])
        .unwrap_or(0)
}

pub fn cliff_summary(runs: u64, episodes: usize) -> CliffSummary {
    let mut summary = CliffSummary {
        q_paths: BTreeMap::new(),
        sarsa_paths: BTreeMap::new(),
        q_return: 0.0,
        sarsa_return: 0.0,
        sarsa_cycles: BTreeMap::new(),
    };
    let late =
        |run: &CliffRun| run.online[100..].iter().sum::<f64>() / (run.online.len() - 100) as f64;
    for seed in 0..runs {
        let q = cliff_q_learning(episodes, 14_000 + seed);
        let sarsa = cliff_sarsa(episodes, 14_000 + seed);
        *summary.q_paths.entry(q.greedy).or_default() += 1;
        *summary.sarsa_paths.entry(sarsa.greedy).or_default() += 1;
        if sarsa.greedy.is_none() {
            *summary
                .sarsa_cycles
                .entry(cycle_length(&sarsa.walk))
                .or_default() += 1;
        }
        summary.q_return += late(&q) / runs as f64;
        summary.sarsa_return += late(&sarsa) / runs as f64;
    }
    summary
}

/// Steps of the three windows of the testbed: 1–100, 401–500 and 901–1,000
pub const WINDOWS: [(usize, usize); 3] = [(0, 100), (400, 500), (900, 1000)];

/// The 10-armed testbed at one ε: fraction of optimal choices and mean reward in each window, over all
/// tasks, and the mean over tasks of the best arm's mean
pub struct Testbed {
    pub optimal: [f64; 3],
    pub reward: [f64; 3],
    pub best_mean: f64,
}

/// Sutton and Barto's testbed: arm means ~ N(0, 1), rewards ~ N(mean, 1), 1,000 steps of IX's ε-greedy.
/// Task t draws from `Rng(t · 10^6)`, so every ε sees the same means and the same noise.
pub fn testbed(epsilon: f64, tasks: u64) -> Testbed {
    let mut result = Testbed {
        optimal: [0.0; 3],
        reward: [0.0; 3],
        best_mean: 0.0,
    };
    for t in 0..tasks {
        let mut rng = Rng(t * 1_000_000);
        let means: Vec<f64> = (0..10).map(|_| normal(&mut rng)).collect();
        let best = (0..10).fold(0, |b, i| if means[i] > means[b] { i } else { b });
        result.best_mean += means[best] / tasks as f64;
        let mut bandit = EpsilonGreedy::new(10, epsilon, t);
        for step in 0..1000 {
            let arm = bandit.select_arm();
            let reward = means[arm] + normal(&mut rng);
            bandit.update(arm, reward);
            for (w, &(lo, hi)) in WINDOWS.iter().enumerate() {
                if (lo..hi).contains(&step) {
                    result.optimal[w] += f64::from(u8::from(arm == best));
                    result.reward[w] += reward;
                }
            }
        }
    }
    for value in result.optimal.iter_mut().chain(result.reward.iter_mut()) {
        *value /= (tasks * 100) as f64;
    }
    result
}

/// Bernoulli arms of P7 and P8, and the gap of each to the best
pub const ARMS: [f64; 3] = [0.9, 0.8, 0.7];
pub const GAPS: [f64; 3] = [0.0, 0.1, 0.2];

#[derive(Clone, Copy, Debug, PartialEq)]
pub enum Learner {
    EpsilonGreedy,
    Ucb1,
    Thompson,
}

/// The two calls a bandit loop needs, over IX's three bandits
trait Bandit {
    fn pick(&mut self) -> usize;
    fn learn(&mut self, arm: usize, reward: f64);
}

impl Bandit for EpsilonGreedy {
    fn pick(&mut self) -> usize {
        self.select_arm()
    }
    fn learn(&mut self, arm: usize, reward: f64) {
        self.update(arm, reward)
    }
}

impl Bandit for UCB1 {
    fn pick(&mut self) -> usize {
        self.select_arm()
    }
    fn learn(&mut self, arm: usize, reward: f64) {
        self.update(arm, reward)
    }
}

impl Bandit for ThompsonSampling {
    fn pick(&mut self) -> usize {
        self.select_arm()
    }
    fn learn(&mut self, arm: usize, reward: f64) {
        self.update(arm, reward)
    }
}

fn play(bandit: &mut impl Bandit, horizon: usize, pay: f64, rng: &mut Rng) -> [usize; 3] {
    let mut pulls = [0; 3];
    for _ in 0..horizon {
        let arm = bandit.pick();
        let reward = if rng.next_f64() < ARMS[arm] { pay } else { 0.0 };
        bandit.learn(arm, reward);
        pulls[arm] += 1;
    }
    pulls
}

/// Pulls of each arm in run `run`: `horizon` steps, arms paying `pay` or 0; run r draws from `Rng(r · 10^9)`
/// and seeds IX's learner with r (ε-greedy at ε = 0.1)
pub fn pulls(learner: Learner, horizon: usize, pay: f64, run: u64) -> [usize; 3] {
    let mut rng = Rng(run * 1_000_000_000);
    match learner {
        Learner::EpsilonGreedy => {
            play(&mut EpsilonGreedy::new(3, 0.1, run), horizon, pay, &mut rng)
        }
        Learner::Ucb1 => play(&mut UCB1::new(3), horizon, pay, &mut rng),
        Learner::Thompson => play(&mut ThompsonSampling::new(3, run), horizon, pay, &mut rng),
    }
}

/// Pseudo-regret Σ Δ of the arms pulled
pub fn regret(pulls: [usize; 3]) -> f64 {
    pulls.iter().zip(GAPS).map(|(&n, gap)| n as f64 * gap).sum()
}

/// Mean pseudo-regret over runs 0 to `runs` − 1, arms paying 0 or 1
pub fn mean_regret(learner: Learner, horizon: usize, runs: u64) -> f64 {
    (0..runs)
        .map(|run| regret(pulls(learner, horizon, 1.0, run)))
        .sum::<f64>()
        / runs as f64
}

/// Auer, Cesa-Bianchi and Fischer's bound on UCB1's expected regret: 8 Σ ln T / Δᵢ + (1 + π²/3) Σ Δᵢ
pub fn auer_bound(horizon: usize) -> f64 {
    let suboptimal = &GAPS[1..];
    8.0 * (horizon as f64).ln() * suboptimal.iter().map(|gap| 1.0 / gap).sum::<f64>()
        + (1.0 + std::f64::consts::PI.powi(2) / 3.0) * suboptimal.iter().sum::<f64>()
}

/// Over `runs` runs of IX's Thompson sampling: how many give one arm more than 99 % of the pulls, and in how
/// many the most-pulled arm is not the best one
pub fn thompson_lock_in(pay: f64, horizon: usize, runs: u64) -> (usize, usize) {
    let mut dominated = 0;
    let mut not_best = 0;
    for run in 0..runs {
        let p = pulls(Learner::Thompson, horizon, pay, run);
        let top = (0..3).fold(0, |b, i| if p[i] > p[b] { i } else { b });
        dominated += usize::from(p[top] * 100 > horizon * 99);
        not_best += usize::from(top != 0);
    }
    (dominated, not_best)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn p1_ties_go_to_the_last_index() {
        assert_eq!(tie_choices(), (9, 3, 4));
        // control: a unique maximum at index 0 is found, so the check can tell the two tie rules apart
        let mut bandit = EpsilonGreedy::new(10, 0.0, 14);
        bandit.update(0, 1.0);
        assert_eq!(bandit.select_arm(), 0);
    }

    #[test]
    fn p2_a_nan_reward_panics_at_the_next_greedy_choice() {
        assert!(matches!(selections_after(f64::NAN, 0.0), Outcome::Panic(_)));
        assert_eq!(selections_after(f64::NAN, 1.0), Outcome::Value);
        // control: an ordinary reward does not panic
        assert_eq!(selections_after(1.0, 0.0), Outcome::Value);
    }

    #[test]
    fn p3_the_agent_trait_reads_the_wrong_row_and_learns_nothing() {
        let (others, twice, never) = row_summary(&rows_read(5, 5));
        assert_eq!(others, 20);
        assert_eq!(twice, vec![4, 8, 12, 16]);
        assert_eq!(never, vec![21, 22, 23, 24]);
        assert_eq!(rows_read(4, 4), (0..16).collect::<Vec<_>>());
        assert_eq!(update_change(true, 14), 0.0);
        // control: the same transitions through update_index do change the table
        assert!(update_change(false, 14) > 0.1);
    }

    #[test]
    fn p4_q_learning_finds_v_star() {
        let run = grid_q_learning(2000, 14);
        assert!((run.v_start - v_start_closed_form(0.99)).abs() < 1e-12);
        assert!((run.q_start - run.v_start).abs() < 1e-3, "{}", run.q_start);
        assert_eq!(run.steps, Some(8));
        // control: an untrained table does not find the goal
        assert_eq!(grid_q_learning(0, 14).steps, None);
    }

    #[test]
    fn p5_sarsa_takes_the_safe_path_refuted_in_part() {
        let s = cliff_summary(50, 500);
        // held: Q-learning's greedy path runs along the cliff in at least 45 runs
        assert!(
            s.q_paths.get(&Some(13)).copied().unwrap_or(0) >= 45,
            "{:?}",
            s.q_paths
        );
        // held: SARSA's online return beats Q-learning's by at least 10
        assert!(
            s.sarsa_return - s.q_return >= 10.0,
            "{} {}",
            s.sarsa_return,
            s.q_return
        );
        // refuted: the prediction said SARSA's greedy path is longer than 13 steps in at least 40 runs. The
        // first run measured 38; in the other 12 the greedy walk never reaches the goal. The test pins what
        // was measured, so that a change shows.
        let longer: usize = s
            .sarsa_paths
            .iter()
            .filter(|(len, _)| len.is_some_and(|n| n > 13))
            .map(|(_, &count)| count)
            .sum();
        assert_eq!(longer, 38, "{:?}", s.sarsa_paths);
        assert_eq!(s.sarsa_paths.get(&None), Some(&12));
    }

    #[test]
    fn p6_the_ten_armed_testbed() {
        let [greedy, small, large] = [0.0, 0.01, 0.1].map(|e| testbed(e, 2000));
        assert!(
            (0.25..=0.45).contains(&greedy.optimal[2]),
            "{}",
            greedy.optimal[2]
        );
        assert!(
            (0.70..=0.90).contains(&large.optimal[2]),
            "{}",
            large.optimal[2]
        );
        assert!(greedy.optimal[2] < small.optimal[2] && small.optimal[2] < large.optimal[2]);
        assert!(greedy.reward[2] < small.reward[2] && small.reward[2] < large.reward[2]);
    }

    #[test]
    fn p7_linear_against_logarithmic_regret() {
        let eps = [
            mean_regret(Learner::EpsilonGreedy, 10_000, 100),
            mean_regret(Learner::EpsilonGreedy, 100_000, 20),
        ];
        let ucb = [
            mean_regret(Learner::Ucb1, 10_000, 100),
            mean_regret(Learner::Ucb1, 100_000, 20),
        ];
        assert!((990.0..=1200.0).contains(&eps[1]), "{eps:?}");
        assert!((6.0..=10.5).contains(&(eps[1] / eps[0])), "{eps:?}");
        assert!((1.3..=3.0).contains(&(ucb[1] / ucb[0])), "{ucb:?}");
        assert!(
            ucb[0] < auer_bound(10_000) && ucb[1] < auer_bound(100_000),
            "{ucb:?}"
        );
    }

    #[test]
    fn p8_thompson_sampling_assumes_unit_variance() {
        let (dominated, not_best) = thompson_lock_in(100.0, 10_000, 100);
        assert_eq!(dominated, 100);
        assert!((45..=75).contains(&not_best), "{not_best}");
        // paying 0 or 1, the model fits and the best arm wins
        let (_, not_best) = thompson_lock_in(1.0, 10_000, 100);
        assert!(100 - not_best >= 90, "{not_best}");
    }

    #[test]
    fn value_iteration_matches_the_closed_form() {
        let q = value_iteration(5, 5, (4, 4), 0.99, 200);
        let v = q[0].iter().copied().fold(f64::NEG_INFINITY, f64::max);
        assert!((v - v_start_closed_form(0.99)).abs() < 1e-12);
        // one step from the goal, moving into it pays 10
        assert_eq!(q[19][2], 10.0);
    }

    #[test]
    fn the_cliff_resets_and_the_goal_ends() {
        let mut env = CliffWalk::default();
        assert_eq!(env.step(&1), (CliffWalk::START, -100.0, false));
        env.reset();
        let path = [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2];
        let rewards: Vec<(f64, bool)> = path
            .iter()
            .map(|a| env.step(a))
            .map(|(_, r, d)| (r, d))
            .collect();
        assert!(rewards[..12].iter().all(|&(r, d)| r == -1.0 && !d));
        assert_eq!(rewards[12], (-1.0, true));
    }

    #[test]
    fn the_normal_draws_have_mean_0_and_variance_1() {
        let mut rng = Rng(14);
        let draws: Vec<f64> = (0..100_000).map(|_| normal(&mut rng)).collect();
        let mean = draws.iter().sum::<f64>() / draws.len() as f64;
        let var = draws.iter().map(|x| (x - mean).powi(2)).sum::<f64>() / draws.len() as f64;
        assert!(
            mean.abs() < 0.01 && (var - 1.0).abs() < 0.02,
            "{mean} {var}"
        );
    }
}
