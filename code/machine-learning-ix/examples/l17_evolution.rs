//! Lesson 17: IX's `ix-evolution` — selection, BLX crossover and mutation, the genetic algorithm and
//! differential evolution on `minimize_linreg_mse`'s loss, and Pareto fronts.

use std::time::Duration;

use machine_learning_ix::evolution::{
    DRAWS, MUTATED_GENES, POINTS, SEEDS, SETS, SHUFFLES, TARGET_LOSS, blx, de_race, de_returns,
    elitism_runs, error_direction, ga_race, median, misspelled, mutation, pareto_fronts, selection,
    shuffles,
};

fn row(v: &[f64]) -> String {
    v.iter()
        .map(|x| format!("{x:.4}"))
        .collect::<Vec<_>>()
        .join(" ")
}

fn median_f64(values: &[f64]) -> f64 {
    let mut v = values.to_vec();
    v.sort_by(|a, b| a.total_cmp(b));
    (v[v.len() / 2 - 1] + v[v.len() / 2]) / 2.0
}

fn main() {
    let s = selection();
    println!("== selection, {DRAWS} draws each (best, middle, worst)");
    println!(
        "  tournament, k = 3, on [0, 1, 2]:  {}   (19/27, 7/27, 1/27)",
        row(&s.tournament)
    );
    println!(
        "  rank on [0, 1, 2]:                {}   (3/6, 2/6, 1/6)",
        row(&s.rank)
    );
    println!(
        "  roulette on [0, 1, 2]:            {}   (2/3, 1/3, 0)",
        row(&s.roulette)
    );
    println!(
        "  roulette on [0, 1, 1000]:         {}   (1000/1999, 999/1999, 0)",
        row(&s.roulette_outlier)
    );
    println!(
        "  roulette on [0, 1]:               {}",
        row(&s.roulette_pair)
    );
    println!("  roulette drew the worst {} times", s.roulette_worst);

    let b = blx(200, 1000);
    println!();
    println!("== BLX-0.5 crossover, 200 pairs of parents with 1000 genes each");
    println!(
        "  parents' variance {:.4}, children's variance {:.4} (7/6 = 1.1667); every child gene inside its interval: {}",
        b.parent_variance, b.child_variance, b.inside
    );

    println!();
    println!("== mutate(rate) on {MUTATED_GENES} genes at 0");
    let hook = std::panic::take_hook();
    std::panic::set_hook(Box::new(|_| {}));
    for rate in [0.1, 1.0, -0.1, 0.0, f64::NAN] {
        match mutation(rate) {
            Ok(m) => println!(
                "  rate {rate:>4}: fraction changed {:.4}, standard deviation of the changes {:.4}",
                m.changed, m.sd
            ),
            Err(message) => println!("  rate {rate:>4}: panic {message:?}"),
        }
    }
    std::panic::set_hook(hook);

    println!();
    println!(
        "== IX's GA on the sphere in 3 dimensions, {SEEDS} seeds, its defaults except elitism"
    );
    let bare = elitism_runs(0);
    let worse = bare.iter().filter(|r| r.returned > r.best_seen).count();
    let rises = bare.iter().filter(|r| r.history_rises).count();
    println!(
        "  elitism 0: returned fitness above the best recorded for {worse} of {SEEDS}; history rises for {rises}"
    );
    println!(
        "             median returned {:.2e}, median best recorded {:.2e}",
        median_f64(&bare.iter().map(|r| r.returned).collect::<Vec<_>>()),
        median_f64(&bare.iter().map(|r| r.best_seen).collect::<Vec<_>>())
    );
    let kept = elitism_runs(2);
    let steady = kept
        .iter()
        .filter(|r| !r.history_rises && r.returned <= r.last_recorded)
        .count();
    println!(
        "  elitism 2: history never rises and returned at most its last entry for {steady} of {SEEDS}"
    );
    println!(
        "             median returned {:.2e}",
        median_f64(&kept.iter().map(|r| r.returned).collect::<Vec<_>>())
    );

    println!();
    println!(
        "== minimize_linreg_mse's loss over (w0, w1, w2, b): evaluations until it first falls below {TARGET_LOSS}, {SEEDS} seeds"
    );
    for (name, runs) in [
        (
            "GA, defaults",
            (0..SEEDS).map(|s| ga_race(17_500 + s)).collect::<Vec<_>>(),
        ),
        (
            "DE, defaults",
            (0..SEEDS).map(|s| de_race(17_500 + s)).collect::<Vec<_>>(),
        ),
    ] {
        let firsts: Vec<usize> = runs.iter().filter_map(|r| r.first_below).collect();
        println!(
            "  {name}: {} evaluations per run, below {TARGET_LOSS} in {} of {SEEDS} runs, first after a median of {:.1} (min {}, max {})",
            runs[0].evaluations,
            firsts.len(),
            median(&firsts),
            firsts.iter().min().expect("one run"),
            firsts.iter().max().expect("one run"),
        );
        println!(
            "      final loss, median {:.2e}",
            median_f64(&runs.iter().map(|r| r.best).collect::<Vec<_>>())
        );
    }
    println!("  Adam, lesson 12: below {TARGET_LOSS} at step 31");

    println!();
    println!("== DifferentialEvolution::minimize in a thread, 10 generations, waited for 2 s");
    for population in [3, 4] {
        println!(
            "  {population} individuals: returned {}",
            de_returns(population, 10, Duration::from_secs(2))
        );
    }

    println!();
    println!(
        "== pareto::rank on {SETS} sets of {POINTS} uniform points, every objective minimized"
    );
    for (dims, expected) in [(2, 5.878), (3, 18.096)] {
        let f = pareto_fronts(dims);
        println!(
            "  {dims} dimensions: mean size of front 0 {:.3} (expected {expected}); all fronts equal to brute force {} of {SETS}; unchanged with the rows reversed {} of {SETS}",
            f.mean_front0, f.brute_equal, f.reverse_equal
        );
    }

    println!();
    println!(
        "== frontier on two rows for one candidate and metric, directions \"min\" and \"Max\""
    );
    println!(
        "  in that order: UnknownDirection {:?}",
        error_direction(&misspelled(false))
    );
    println!(
        "  reversed:      UnknownDirection {:?}",
        error_direction(&misspelled(true))
    );
    let sh = shuffles();
    println!(
        "  a valid table of 300 rows: {} frontier rows, the same CSV for {} of {SHUFFLES} shuffles",
        sh.frontier_rows, sh.csv_equal
    );
    println!(
        "  IX's table with several defects: {:?}, the same error for {} of {SHUFFLES} shuffles",
        sh.ix_error, sh.error_equal
    );
}
