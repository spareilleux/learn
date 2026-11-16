//! Lesson 14: bandits, Q-learning and SARSA, by hand and with IX's `ix-rl`.

use machine_learning_ix::rl::{
    Learner, WINDOWS, auer_bound, cliff_summary, grid_q_learning, mean_regret, row_summary,
    rows_read, selections_after, testbed, thompson_lock_in, tie_choices, ucb1_after_equal_rewards,
    update_change, v_start_closed_form,
};

fn paths(counts: &std::collections::BTreeMap<Option<usize>, usize>) -> String {
    let parts: Vec<String> = counts
        .iter()
        .map(|(len, n)| match len {
            Some(len) => format!("{len} steps: {n}"),
            None => format!("no path: {n}"),
        })
        .collect();
    parts.join(", ")
}

fn main() {
    println!("== Ties");
    let (bandit, action, ucb) = tie_choices();
    println!("  new EpsilonGreedy, 10 arms, epsilon 0:       arm {bandit}");
    println!("  new QLearning, 4 actions, epsilon 0:         action {action}");
    println!("  UCB1, 5 arms, after reward 1 from each:      arm {ucb}");
    println!(
        "  UCB1, 3 arms, the same:                      arm {}",
        ucb1_after_equal_rewards(3)
    );

    println!();
    println!("== A NaN reward on arm 0 of 3, then 100 selections");
    // the panic is the result; its report on stderr is not
    let hook = std::panic::take_hook();
    std::panic::set_hook(Box::new(|_| {}));
    println!("  epsilon 0: {:?}", selections_after(f64::NAN, 0.0));
    println!("  epsilon 1: {:?}", selections_after(f64::NAN, 1.0));
    std::panic::set_hook(hook);

    println!();
    println!("== The Agent trait on GridWorld");
    for (rows, cols) in [(5, 5), (4, 4)] {
        let read = rows_read(rows, cols);
        let (others, twice, never) = row_summary(&read);
        println!(
            "  {rows} x {cols}: states reading another state's row: {others}; rows read twice: {twice:?}; rows never read: {never:?}"
        );
    }
    println!("  row read by state (r, c) of the 5 x 5 grid:");
    let read = rows_read(5, 5);
    for r in 0..5 {
        let row: Vec<String> = (0..5).map(|c| format!("{:>2}", read[r * 5 + c])).collect();
        println!("    r = {r}: {}", row.join(" "));
    }
    let change = |trait_update| {
        let m = update_change(trait_update, 14);
        if m == 0.0 {
            "0, exactly".to_string()
        } else {
            format!("{m:.3}")
        }
    };
    println!(
        "  largest |change| of the table after 1000 transitions, Agent::update: {}",
        change(true)
    );
    println!(
        "  the same transitions through update_index:                         {}",
        change(false)
    );

    println!();
    println!(
        "== Q-learning on the 5 x 5 GridWorld: learning rate 0.1, gamma 0.99, epsilon 0.1, 2000 episodes"
    );
    let run = grid_q_learning(2000, 14);
    println!(
        "  V*(start) by value iteration: {:.6}; 10 g^7 - (1 - g^7)/(1 - g): {:.6}",
        run.v_start,
        v_start_closed_form(0.99)
    );
    println!("  max_a Q(start) after training: {:.6}", run.q_start);
    println!(
        "  |max_a Q(start) - V*(start)| below 1e-3: {}",
        (run.q_start - run.v_start).abs() < 1e-3
    );
    println!(
        "  largest |Q - Q*| over the 96 state-actions outside the goal: {:.3}",
        run.worst
    );
    println!(
        "  mean reward per episode: episodes 1-100 {:.2}, 1901-2000 {:.2}",
        run.first, run.last
    );
    let steps = |s: Option<usize>| {
        s.map_or("no path within 100 steps".to_string(), |n| {
            format!("{n} steps")
        })
    };
    println!(
        "  greedy walk, rows from state_index:        {}",
        steps(run.steps)
    );
    println!(
        "  greedy walk through Agent::select_action:  {}",
        steps(run.trait_steps)
    );

    println!();
    println!("== The cliff: gamma 1, step 0.5, epsilon 0.1, 50 runs of 500 episodes");
    let cliff = cliff_summary(50, 500);
    println!("  greedy path, Q-learning: {}", paths(&cliff.q_paths));
    println!("  greedy path, SARSA:      {}", paths(&cliff.sarsa_paths));
    println!(
        "  mean online return, episodes 101-500: Q-learning {:.1}, SARSA {:.1}",
        cliff.q_return, cliff.sarsa_return
    );
    let cycles: Vec<String> = cliff
        .sarsa_cycles
        .iter()
        .map(|(k, n)| match k {
            1 => format!("stays in one cell, against a wall: {n}"),
            k => format!("cycles through {k} cells: {n}"),
        })
        .collect();
    println!("  SARSA's walks with no path: {}", cycles.join("; "));

    println!();
    println!("== The 10-armed testbed: 2000 tasks, 1000 steps, sample averages");
    let windows: Vec<String> = WINDOWS
        .iter()
        .map(|(lo, hi)| format!("{}-{}", lo + 1, hi))
        .collect();
    println!(
        "  epsilon   optimal arm, steps {}      average reward, steps {}",
        windows.join(" / "),
        windows.join(" / ")
    );
    let mut best_mean = 0.0;
    for epsilon in [0.0, 0.01, 0.1] {
        let t = testbed(epsilon, 2000);
        let optimal: Vec<String> = t
            .optimal
            .iter()
            .map(|f| format!("{:>5.1} %", 100.0 * f))
            .collect();
        let reward: Vec<String> = t.reward.iter().map(|r| format!("{r:>5.3}")).collect();
        println!(
            "  {epsilon:<7}   {}           {}",
            optimal.join("  "),
            reward.join("   ")
        );
        best_mean = t.best_mean;
    }
    println!("  mean over the tasks of the best arm's mean: {best_mean:.3}");

    println!();
    println!("== Regret on Bernoulli arms 0.9, 0.8, 0.7 (pseudo-regret, mean over runs)");
    println!("        T   runs   epsilon-greedy 0.1     UCB1   Thompson (IX)   Auer et al. bound");
    let mut table = Vec::new();
    for (horizon, runs) in [(10_000, 100), (100_000, 20)] {
        let row = [Learner::EpsilonGreedy, Learner::Ucb1, Learner::Thompson]
            .map(|l| mean_regret(l, horizon, runs));
        println!(
            "  {horizon:>7}   {runs:>4}   {:>18.1}   {:>6.1}   {:>13.1}   {:>17.1}",
            row[0],
            row[1],
            row[2],
            auer_bound(horizon)
        );
        table.push(row);
    }
    println!(
        "  regret(1e5) / regret(1e4): epsilon-greedy {:.2}, UCB1 {:.2}, Thompson {:.2}",
        table[1][0] / table[0][0],
        table[1][1] / table[0][1],
        table[1][2] / table[0][2]
    );

    println!();
    println!("== IX's Thompson sampling, arms paying 0 or 1 and 0 or 100: 100 runs of 10000 steps");
    for pay in [1.0, 100.0] {
        let (dominated, not_best) = thompson_lock_in(pay, 10_000, 100);
        println!(
            "  pay {pay:>3}: one arm over 99 % of the pulls in {dominated} runs; most-pulled arm not the best in {not_best} runs"
        );
    }
}
