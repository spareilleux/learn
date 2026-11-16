//! Lesson 16: A*, weighted, bidirectional and Q* search, MCTS and local search, with IX's `ix-search`.

use machine_learning_ix::search::{
    EXPLORATION, Found, ITERATIONS, MAZE_SIZE, MAZES, WALL, WEIGHTS, beam_from_optimum,
    bidirectional_cycle, bidirectional_line, climbs_from_optimum, dead_ends, inconsistent, mazes,
    partner_game, queens_climb, queens_restarts, restarts_from_three, tie_breaks,
};

/// A value with −0 printed as 0
fn num(v: f64) -> String {
    format!("{}", v + 0.0)
}

fn path(found: &Found, names: &[&str]) -> String {
    found
        .path
        .iter()
        .map(|&id| names[id])
        .collect::<Vec<_>>()
        .join(" ")
}

fn actions(found: &Found) -> String {
    found
        .actions
        .iter()
        .map(|(from, to)| format!("({from}, {to})"))
        .collect::<Vec<_>>()
        .join(" ")
}

fn main() {
    println!("== A*, S→A 1, S→C 3, A→C 1, C→G 3");
    let names = ["S", "A", "C", "G"];
    let r = inconsistent();
    for (label, found) in [
        ("h(A) = 4, 0 elsewhere", &r.inconsistent),
        ("h = 0", &r.zero),
        ("h = h*", &r.exact),
    ] {
        println!(
            "  {label:<22} cost {}, path {}, {} expansions",
            num(found.cost),
            path(found, &names),
            found.expanded
        );
    }
    println!("  ix-graph Dijkstra       {}", num(r.dijkstra));

    println!();
    println!(
        "== {MAZES} mazes of {MAZE_SIZE} x {MAZE_SIZE}, walls with probability {WALL}, Manhattan h"
    );
    let m = mazes();
    println!("  far corner reachable:                {}", m.reachable);
    println!(
        "  astar None exactly when unreachable: {}",
        m.none_iff_unreachable
    );
    println!(
        "  astar cost = Dijkstra's everywhere:  {}",
        m.astar_is_dijkstra
    );
    println!(
        "  total optimal cost:                  {}",
        num(m.total_cost)
    );
    println!("  A*:          mean expansions {:.1}", m.mean_expanded[0]);
    for (k, w) in WEIGHTS.iter().enumerate() {
        println!(
            "  w = {w:<4}     mean expansions {:.1}, over the bound {}, worst cost / optimum {:.4}",
            m.mean_expanded[k + 1],
            m.over_bound[k],
            m.worst_ratio[k]
        );
    }

    println!();
    println!("== bidirectional_astar, h = 0");
    let (cycle, forward) = bidirectional_cycle();
    let cycle = cycle.expect("a result");
    let names = ["S", "A", "G"];
    println!(
        "  directed cycle S→A→G→S: bidirectional cost {}, path {}; astar cost {}, path {}",
        num(cycle.cost),
        path(&cycle, &names),
        num(forward.cost),
        path(&forward, &names)
    );
    let (line, control) = bidirectional_line();
    println!(
        "  path 0-1-2-3-4: bidirectional path {:?}, cost {}",
        line.path,
        num(line.cost)
    );
    println!("    bidirectional actions {}", actions(&line));
    println!("    astar actions         {}", actions(&control));

    println!();
    println!("== S→A→G and 100 dead ends S→D→X: (cost, expansions, heuristic calls)");
    let d = dead_ends(100);
    for (label, (cost, expanded, calls)) in [
        ("astar", d.astar),
        ("qstar_search", d.qstar),
        ("qstar_two_head", d.two_head),
    ] {
        println!("  {label:<15} {}, {expanded}, {calls}", num(cost));
    }

    println!();
    println!(
        "== A (the opponent picks win or loss) or B (a draw), {ITERATIONS} iterations, exploration {EXPLORATION}, 20 seeds"
    );
    let g = partner_game(20);
    println!("  ix mcts_search chooses A:  {} of 20", g.ix_gambles);
    println!("  negamax MCTS chooses B:    {} of 20", g.negamax_draws);
    println!(
        "  ix minimax:                {:?}, value {}",
        g.minimax_move.expect("a move"),
        num(g.minimax_value)
    );

    println!();
    println!("== 3 moves to a draw, 3 iterations, 20 seeds");
    let (last, first) = tie_breaks(20);
    println!("  mcts_search returns the last expanded child {last} times, the first {first} times");

    println!();
    println!("== local search on -(x - 10)^2 from x = 10");
    for steps in [1, 2, 101] {
        let (x, v) = beam_from_optimum(steps);
        println!(
            "  beam_search, beam 1, {steps:>3} steps: x = {x}, value {}",
            num(v)
        );
    }
    let ((h, hv), (t, tv)) = climbs_from_optimum();
    println!(
        "  hill_climbing: x = {h}, value {}; tabu_search: x = {t}, value {}",
        num(hv),
        num(tv)
    );
    for restarts in [0, 5] {
        let (x, v, calls) = restarts_from_three(restarts);
        println!(
            "  random_restart_hill_climbing from 3, {restarts} restarts: x = {x}, value {}, {calls} generator calls",
            num(v)
        );
    }

    println!();
    println!("== 8 queens, IX's hill_climbing");
    let q = queens_climb(1_000);
    println!(
        "  {} random boards: solved {} ({:.1}%), mean steps {:.2} when solved, {:.2} when stuck",
        q.boards,
        q.solved,
        100.0 * q.solved as f64 / q.boards as f64,
        q.steps_solved,
        q.steps_stuck
    );
    println!(
        "  random_restart_hill_climbing, 20 restarts: solved {} of 100 runs",
        queens_restarts(100, 20)
    );
}
