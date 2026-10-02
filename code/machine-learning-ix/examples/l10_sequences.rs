//! Lesson 10: Markov chains and hidden Markov models. Each quantity is computed by hand first
//! (exact linear systems, log-space recursions), then with IX's pinned `ix_graph`.

use ix_graph::hmm::HiddenMarkovModel;
use ix_graph::markov::MarkovChain;
use machine_learning_ix::ensemble::Rng;
use machine_learning_ix::fmt_vec;
use machine_learning_ix::sequence::{
    Hmm, agreement, argmax_rows, mean_first_passage_exact, runs_of, stationary_exact,
};
use ndarray::{Array2, array};
use std::panic::{self, AssertUnwindSafe};

fn to_ix(h: &Hmm) -> HiddenMarkovModel {
    HiddenMarkovModel::new(h.initial.clone(), h.transition.clone(), h.emission.clone())
        .expect("a valid HMM")
}

fn largest_gap(a: &Array2<f64>, b: &Array2<f64>) -> f64 {
    a.iter()
        .zip(b.iter())
        .map(|(x, y)| (x - y).abs())
        .fold(0.0, |m, d| {
            if d.is_nan() || m.is_nan() {
                f64::NAN
            } else {
                m.max(d)
            }
        })
}

fn path(p: &[usize]) -> String {
    format!("{p:?}")
}

fn main() {
    println!("== Markov chain: bull, bear, stagnant");
    let market = array![[0.9, 0.075, 0.025], [0.15, 0.8, 0.05], [0.25, 0.25, 0.5]];
    let exact = stationary_exact(&market);
    let chain = MarkovChain::new(market.clone()).expect("row-stochastic");
    let power = chain.stationary_distribution(10_000, 1e-15);
    let gap = exact
        .iter()
        .zip(power.iter())
        .map(|(a, b)| (a - b).abs())
        .fold(0.0, f64::max);
    println!(
        "  exact stationary distribution: {}",
        fmt_vec(exact.iter().copied(), 4)
    );
    println!(
        "  IX power iteration:            {}",
        fmt_vec(power.iter().copied(), 4)
    );
    println!("  largest gap below 1e-12: {}", gap < 1e-12);
    println!("  is_ergodic(1): {}", chain.is_ergodic(1));

    println!("\n== mean first passage to stagnant (state 2)");
    let m = mean_first_passage_exact(&market, 2);
    println!(
        "  exact, from bull, bear, stagnant: {}",
        fmt_vec(m.iter().copied(), 4)
    );
    println!("  Kac: 1 / pi_2 = {:.4}", 1.0 / exact[2]);
    for max_steps in [1000, 20, 5] {
        let from_bull = chain.mean_first_passage(0, 2, 20_000, max_steps, 42);
        let back = chain.mean_first_passage(2, 2, 20_000, max_steps, 42);
        println!(
            "  IX, 20000 walks, at most {max_steps:>4} steps: from bull {from_bull:.3}, return {back:.3}"
        );
    }

    println!("\n== a periodic chain [[0, 1], [1, 0]]");
    let flip = MarkovChain::new(array![[0.0, 1.0], [1.0, 0.0]]).expect("row-stochastic");
    let start = array![1.0, 0.0];
    let walk: Vec<String> = (1..=4)
        .map(|k| fmt_vec(flip.state_distribution(&start, k).iter().copied(), 1))
        .collect();
    println!(
        "  state_distribution from [1, 0], 1 to 4 steps: {}",
        walk.join(" ")
    );
    println!(
        "  stationary_distribution: {}",
        fmt_vec(flip.stationary_distribution(1000, 1e-12).iter().copied(), 4)
    );
    println!("  is_ergodic(100): {}", flip.is_ergodic(100));

    println!("\n== the casino: 1000 rolls from the course's generator, seed 10");
    let casino = Hmm::casino();
    let ix_casino = to_ix(&casino);
    let mut rng = Rng::new(10);
    let (truth, rolls) = casino.sample(1000, &mut rng);
    let sixes = rolls.iter().filter(|&&r| r == 5).count();
    let loaded = truth.iter().filter(|&&s| s == 1).count();
    println!(
        "  true path: {loaded} loaded rolls in {} runs; {sixes} sixes",
        runs_of(&truth, 1)
    );
    println!(
        "  forward in probability space: T = 300 gives {:.3e}, T = 1000 gives {:.3e}",
        casino.forward_plain(&rolls[..300]),
        casino.forward_plain(&rolls)
    );
    let hand_ll = casino.forward_log(&rolls);
    let ix_ll = ix_casino.forward(&rolls);
    println!("  ln P(rolls), hand log space: {hand_ll:.4}");
    println!("  ln P(rolls), IX forward:     {ix_ll:.4}");
    println!("  agree within 1e-9: {}", (hand_ll - ix_ll).abs() < 1e-9);

    println!("\n== decoding the 1000 rolls");
    let (hand_path, hand_lp) = casino.viterbi(&rolls);
    let (ix_path, ix_lp) = ix_casino.viterbi(&rolls);
    println!(
        "  Viterbi: hand path = IX path: {}; log-probabilities agree within 1e-9: {}",
        hand_path == ix_path,
        (hand_lp - ix_lp).abs() < 1e-9
    );
    println!(
        "  Viterbi: agreement with the true states {:.3}; {} loaded runs",
        agreement(&ix_path, &truth),
        runs_of(&ix_path, 1)
    );
    let hand_post = casino.posteriors(&rolls);
    let ix_post = ix_casino.forward_backward(&rolls);
    println!(
        "  posteriors: hand against IX forward_backward, largest gap below 1e-9: {}",
        largest_gap(&hand_post, &ix_post) < 1e-9
    );
    let map = ix_casino.map_estimate(&rolls);
    println!(
        "  posterior decoding (map_estimate): agreement with the true states {:.3}; {} loaded runs; same as hand argmax: {}",
        agreement(&map, &truth),
        runs_of(&map, 1),
        map == argmax_rows(&hand_post)
    );

    println!("\n== when the best states are not a path");
    let trap = Hmm {
        initial: array![0.4, 0.3, 0.3],
        transition: array![[0.0, 0.0, 1.0], [0.0, 1.0, 0.0], [0.0, 1.0, 0.0]],
        emission: array![[1.0], [1.0], [1.0]],
    };
    let ix_trap = to_ix(&trap);
    let obs = [0, 0];
    let map = ix_trap.map_estimate(&obs);
    let (vpath, vlp) = ix_trap.viterbi(&obs);
    println!(
        "  map_estimate: {}, probability of that path {:.4}",
        path(&map),
        trap.path_log_probability(&map, &obs).exp()
    );
    println!(
        "  viterbi:      {}, probability {:.4}",
        path(&vpath),
        vlp.exp()
    );

    println!("\n== Baum-Welch from a wrong start, on the 1000 rolls");
    let guess = HiddenMarkovModel::new(
        array![0.5, 0.5],
        array![[0.8, 0.2], [0.2, 0.8]],
        array![
            [1. / 6., 1. / 6., 1. / 6., 1. / 6., 1. / 6., 1. / 6.],
            [0.15, 0.15, 0.15, 0.15, 0.15, 0.25]
        ],
    )
    .expect("a valid HMM");
    let mut lls = vec![guess.forward(&rolls)];
    let mut fitted = guess.clone();
    for k in 1..=10 {
        fitted = guess.baum_welch(&rolls, k, 0.0).expect("non-empty");
        lls.push(fitted.forward(&rolls));
    }
    for (k, ll) in lls.iter().enumerate() {
        println!("  {k:>2} iterations: ln P = {ll:.4}");
    }
    println!(
        "  never decreases: {}",
        lls.windows(2).all(|w| w[1] >= w[0] - 1e-9)
    );
    println!(
        "  after 10: stay fair {:.4}, stay loaded {:.4}, P(six | loaded) {:.4}; truth 0.9500, 0.9000, 0.5000",
        fitted.transition[[0, 0]],
        fitted.transition[[1, 1]],
        fitted.emission[[1, 5]]
    );

    println!("\n== edges");
    let blocked = Hmm {
        initial: array![0.5, 0.5],
        transition: array![[0.5, 0.5], [0.5, 0.5]],
        emission: array![[0.5, 0.5, 0.0], [0.5, 0.5, 0.0]],
    };
    let ix_blocked = to_ix(&blocked);
    let (bpath, blp) = ix_blocked.viterbi(&[0, 2, 1]);
    println!(
        "  viterbi on an impossible symbol: path {}, log-probability {blp}",
        path(&bpath)
    );
    println!("  forward on it: {}", ix_blocked.forward(&[0, 2, 1]));
    let beta = ix_casino.backward(&rolls[..10]);
    println!(
        "  backward entries all positive: {} (a log-probability is never positive)",
        beta.iter().all(|&b| b > 0.0)
    );
    let quiet = panic::take_hook();
    panic::set_hook(Box::new(|_| {}));
    let outside = panic::catch_unwind(AssertUnwindSafe(|| ix_casino.forward(&[0, 6])));
    panic::set_hook(quiet);
    println!(
        "  a symbol outside the alphabet (6 on a die of 0 to 5): forward panics: {}",
        outside.is_err()
    );
}
