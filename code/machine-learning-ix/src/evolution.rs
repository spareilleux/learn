//! Lesson 17: selection, crossover and mutation, the genetic algorithm and differential evolution, and
//! Pareto fronts, measured against IX's `ix-evolution`.
//!
//! IX's operators take any `rand::Rng`: they get the course's splitmix64 stream through `RngCore`, and the
//! points, parents and tables come from the course's `Rng`, so the numpy cross-check rebuilds the same
//! Pareto sets. `GeneticAlgorithm` and `DifferentialEvolution` keep their own seeded `StdRng`.

use std::cell::Cell;
use std::panic::{AssertUnwindSafe, catch_unwind};
use std::sync::mpsc;
use std::time::Duration;

use ix_evolution::differential::DifferentialEvolution;
use ix_evolution::frontier::{FrontierError, ObjectiveRow, frontier, to_csv};
use ix_evolution::genetic::GeneticAlgorithm;
use ix_evolution::pareto::{Candidate, Objective, ParetoArchive, rank};
use ix_evolution::selection;
use ix_evolution::traits::{Individual, RealIndividual};
use ndarray::{Array1, array};

use crate::autodiff::{Rng, closed_form, ix_example_data};
use crate::rl::normal;
use crate::sketch::splitmix64;
use crate::transformer::panic_message;

/// The course's splitmix64 stream as a `rand` generator: `next_u64` is the value `Rng` turns into a float
pub struct SplitMix(pub u64);

impl rand::RngCore for SplitMix {
    fn next_u32(&mut self) -> u32 {
        (self.next_u64() >> 32) as u32
    }

    fn next_u64(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(1);
        splitmix64(self.0)
    }

    fn fill_bytes(&mut self, dst: &mut [u8]) {
        for chunk in dst.chunks_mut(8) {
            let bytes = self.next_u64().to_le_bytes();
            chunk.copy_from_slice(&bytes[..chunk.len()]);
        }
    }
}

// ---------------------------------------------------------------------------------------------------------
// P1: selection

pub const DRAWS: usize = 100_000;

/// A population whose i-th individual has the single gene i and the given fitness
fn population(fitness: &[f64]) -> Vec<RealIndividual> {
    fitness
        .iter()
        .enumerate()
        .map(|(i, &f)| RealIndividual::new(array![i as f64]).with_fitness(f))
        .collect()
}

/// How often each individual is drawn, as a fraction of `DRAWS`
fn frequencies(n: usize, mut pick: impl FnMut() -> RealIndividual) -> Vec<f64> {
    let mut counts = vec![0usize; n];
    for _ in 0..DRAWS {
        counts[pick().genes[0] as usize] += 1;
    }
    counts.iter().map(|&c| c as f64 / DRAWS as f64).collect()
}

pub struct Selection {
    /// `tournament` with k = 3, `rank` and `roulette` on fitness [0, 1, 2]
    pub tournament: Vec<f64>,
    pub rank: Vec<f64>,
    pub roulette: Vec<f64>,
    /// `roulette` on [0, 1, 1000] and on [0, 1]
    pub roulette_outlier: Vec<f64>,
    pub roulette_pair: Vec<f64>,
    /// How many times `roulette` drew the worst individual, over the three populations
    pub roulette_worst: usize,
}

pub fn selection() -> Selection {
    let mut rng = SplitMix(17_100);
    let three = population(&[0.0, 1.0, 2.0]);
    let outlier = population(&[0.0, 1.0, 1000.0]);
    let pair = population(&[0.0, 1.0]);
    let tournament = frequencies(3, || selection::tournament(&three, 3, &mut rng));
    let rank = frequencies(3, || selection::rank(&three, &mut rng));
    let roulette = frequencies(3, || selection::roulette(&three, &mut rng));
    let roulette_outlier = frequencies(3, || selection::roulette(&outlier, &mut rng));
    let roulette_pair = frequencies(2, || selection::roulette(&pair, &mut rng));
    let roulette_worst =
        ((roulette[2] + roulette_outlier[2] + roulette_pair[1]) * DRAWS as f64) as usize;
    Selection {
        tournament,
        rank,
        roulette,
        roulette_outlier,
        roulette_pair,
        roulette_worst,
    }
}

// ---------------------------------------------------------------------------------------------------------
// P2: BLX-0.5 crossover

pub struct Blx {
    pub genes: usize,
    pub parent_variance: f64,
    pub child_variance: f64,
    /// Every child gene within [min − d/2, max + d/2] of its parents' genes
    pub inside: bool,
}

fn variance(v: &[f64]) -> f64 {
    let mean = v.iter().sum::<f64>() / v.len() as f64;
    v.iter().map(|x| (x - mean).powi(2)).sum::<f64>() / v.len() as f64
}

/// `pairs` crossovers of two parents of `genes` genes each, every gene drawn from N(0, 1)
pub fn blx(pairs: usize, genes: usize) -> Blx {
    let mut draws = Rng(17_200);
    let mut rng = SplitMix(17_201);
    let (mut parents, mut children, mut inside) = (Vec::new(), Vec::new(), true);
    for _ in 0..pairs {
        let a = RealIndividual::new((0..genes).map(|_| normal(&mut draws)).collect());
        let b = RealIndividual::new((0..genes).map(|_| normal(&mut draws)).collect());
        let child = a.crossover(&b, &mut rng);
        for ((&x, &y), &c) in a.genes.iter().zip(&b.genes).zip(&child.genes) {
            let d = (x - y).abs();
            inside &= x.min(y) - 0.5 * d <= c && c <= x.max(y) + 0.5 * d;
        }
        parents.extend(a.genes.iter().chain(&b.genes));
        children.extend(child.genes.iter());
    }
    Blx {
        genes: children.len(),
        parent_variance: variance(&parents),
        child_variance: variance(&children),
        inside,
    }
}

// ---------------------------------------------------------------------------------------------------------
// P3: mutation

pub const MUTATED_GENES: usize = 100_000;

pub struct Mutation {
    /// The fraction of genes whose value changed
    pub changed: f64,
    /// The standard deviation of the changes, over the genes that changed
    pub sd: f64,
}

/// `mutate(rate)` on `MUTATED_GENES` genes at 0, run under `catch_unwind`
pub fn mutation(rate: f64) -> Result<Mutation, String> {
    let mut rng = SplitMix(17_300);
    let mut individual = RealIndividual::new(Array1::zeros(MUTATED_GENES));
    catch_unwind(AssertUnwindSafe(|| individual.mutate(rate, &mut rng))).map_err(panic_message)?;
    let changes: Vec<f64> = individual
        .genes
        .iter()
        .copied()
        .filter(|&g| g != 0.0)
        .collect();
    Ok(Mutation {
        changed: changes.len() as f64 / MUTATED_GENES as f64,
        sd: if changes.is_empty() {
            0.0
        } else {
            variance(&changes).sqrt()
        },
    })
}

// ---------------------------------------------------------------------------------------------------------
// P4: elitism

pub const SEEDS: u64 = 20;

fn sphere(x: &Array1<f64>) -> f64 {
    x.mapv(|v| v * v).sum()
}

pub struct ElitismRun {
    pub returned: f64,
    /// The smallest value `fitness_history` recorded
    pub best_seen: f64,
    pub history_rises: bool,
    pub last_recorded: f64,
}

/// IX's GA on the 3-dimensional sphere, its defaults except `elitism`
pub fn elitism_run(elitism: usize, seed: u64) -> ElitismRun {
    let mut ga = GeneticAlgorithm::new().with_seed(seed);
    ga.elitism = elitism;
    let result = ga.minimize(&sphere, 3);
    let history = &result.fitness_history;
    ElitismRun {
        returned: result.best_fitness,
        best_seen: history.iter().copied().fold(f64::INFINITY, f64::min),
        history_rises: history.windows(2).any(|w| w[1] > w[0]),
        last_recorded: *history.last().expect("one entry per generation"),
    }
}

pub fn elitism_runs(elitism: usize) -> Vec<ElitismRun> {
    (0..SEEDS)
        .map(|s| elitism_run(elitism, 17_400 + s))
        .collect()
}

// ---------------------------------------------------------------------------------------------------------
// P5: evaluations on `minimize_linreg_mse`

pub const TARGET_LOSS: f64 = 0.01;

pub struct Race {
    /// The evaluation at which the loss first fell below `TARGET_LOSS`, if it did
    pub first_below: Option<usize>,
    pub evaluations: usize,
    pub best: f64,
}

/// The example's mean squared error over (w₀, w₁, w₂, b), counting its calls
fn race(run: impl FnOnce(&dyn Fn(&Array1<f64>) -> f64) -> f64) -> Race {
    let (x, y) = ix_example_data();
    let calls = Cell::new(0usize);
    let first = Cell::new(None);
    let loss = |g: &Array1<f64>| {
        calls.set(calls.get() + 1);
        let l = closed_form(&x, &y, &[g[0], g[1], g[2]], g[3]).loss;
        if l < TARGET_LOSS && first.get().is_none() {
            first.set(Some(calls.get()));
        }
        l
    };
    let best = run(&loss);
    Race {
        first_below: first.get(),
        evaluations: calls.get(),
        best,
    }
}

pub fn ga_race(seed: u64) -> Race {
    race(|f| {
        GeneticAlgorithm::new()
            .with_seed(seed)
            .minimize(&f, 4)
            .best_fitness
    })
}

pub fn de_race(seed: u64) -> Race {
    race(|f| {
        DifferentialEvolution::new()
            .with_seed(seed)
            .minimize(&f, 4)
            .best_fitness
    })
}

/// The middle of 20 values: the mean of the 10th and 11th
pub fn median(values: &[usize]) -> f64 {
    let mut v = values.to_vec();
    v.sort_unstable();
    let n = v.len();
    if n % 2 == 1 {
        v[n / 2] as f64
    } else {
        (v[n / 2 - 1] + v[n / 2]) as f64 / 2.0
    }
}

// ---------------------------------------------------------------------------------------------------------
// P6: a population too small for DE/rand/1

/// Whether `DifferentialEvolution::minimize` with `population` individuals returns within `wait`. A run
/// that doesn't keeps its thread spinning until the process exits.
pub fn de_returns(population: usize, generations: usize, wait: Duration) -> bool {
    let (tx, rx) = mpsc::channel();
    std::thread::spawn(move || {
        let result = DifferentialEvolution::new()
            .with_population_size(population)
            .with_generations(generations)
            .with_seed(17_600)
            .minimize(&sphere, 2);
        let _ = tx.send(result.best_fitness);
    });
    rx.recv_timeout(wait).is_ok()
}

// ---------------------------------------------------------------------------------------------------------
// P7: Pareto fronts

pub const SETS: usize = 100;
pub const POINTS: usize = 200;

/// `SETS` sets of `POINTS` points, uniform in the unit cube of `dims` dimensions, drawn point by point
pub fn point_sets(dims: usize) -> Vec<Vec<Vec<f64>>> {
    let mut rng = Rng(17_700 + dims as u64);
    (0..SETS)
        .map(|_| {
            (0..POINTS)
                .map(|_| (0..dims).map(|_| rng.next_f64()).collect())
                .collect()
        })
        .collect()
}

fn candidates(points: &[Vec<f64>]) -> Vec<Candidate> {
    points
        .iter()
        .enumerate()
        .map(|(i, p)| Candidate::new(format!("p{i:03}"), p.clone()))
        .collect()
}

/// Every front of an archive, front 0 first
pub fn fronts(archive: &ParetoArchive) -> Vec<Vec<String>> {
    (0..)
        .map_while(|r| archive.front(r).map(|f| f.to_vec()))
        .collect()
}

/// Non-dominated sorting by brute force, minimizing every coordinate: peel the points no remaining point
/// dominates, and repeat. Each front is sorted by id.
pub fn brute_fronts(points: &[Vec<f64>]) -> Vec<Vec<String>> {
    let dominates = |a: &[f64], b: &[f64]| {
        a.iter().zip(b).all(|(x, y)| x <= y) && a.iter().zip(b).any(|(x, y)| x < y)
    };
    let mut left: Vec<usize> = (0..points.len()).collect();
    let mut out = Vec::new();
    while !left.is_empty() {
        let (front, rest): (Vec<usize>, Vec<usize>) = left
            .iter()
            .partition(|&&i| !left.iter().any(|&j| dominates(&points[j], &points[i])));
        out.push(front.iter().map(|i| format!("p{i:03}")).collect());
        left = rest;
    }
    out
}

pub struct Fronts {
    pub mean_front0: f64,
    /// Sets whose every front matched the brute-force peeling
    pub brute_equal: usize,
    /// Sets whose archive is unchanged when the rows are reversed
    pub reverse_equal: usize,
}

pub fn pareto_fronts(dims: usize) -> Fronts {
    let objectives = vec![Objective::Minimize; dims];
    let (mut total, mut brute_equal, mut reverse_equal) = (0usize, 0, 0);
    for points in point_sets(dims) {
        let rows = candidates(&points);
        let archive = rank(&rows, &objectives).expect("valid candidates");
        total += archive.front(0).expect("a front 0").len();
        brute_equal += usize::from(fronts(&archive) == brute_fronts(&points));
        let reversed: Vec<Candidate> = rows.iter().rev().cloned().collect();
        reverse_equal +=
            usize::from(rank(&reversed, &objectives).expect("valid candidates") == archive);
    }
    Fronts {
        mean_front0: total as f64 / SETS as f64,
        brute_equal,
        reverse_equal,
    }
}

// ---------------------------------------------------------------------------------------------------------
// P8: the frontier's errors

/// Two rows for the same candidate and metric, their directions spelled "min" and "Max", in the given order
pub fn misspelled(reverse: bool) -> Vec<ObjectiveRow> {
    let mut rows = vec![
        ObjectiveRow::new("rev-a", "t", "a", "cost", "min", 1.0),
        ObjectiveRow::new("rev-a", "t", "a", "cost", "Max", 1.0),
    ];
    if reverse {
        rows.reverse();
    }
    rows
}

/// The direction an `UnknownDirection` error names, or the whole error otherwise
pub fn error_direction(rows: &[ObjectiveRow]) -> String {
    match frontier(rows) {
        Err(FrontierError::UnknownDirection { direction, .. }) => direction,
        other => format!("{other:?}"),
    }
}

/// Fisher–Yates with the course's `Rng`
fn shuffled<T: Clone>(rows: &[T], rng: &mut Rng) -> Vec<T> {
    let mut v = rows.to_vec();
    for i in (1..v.len()).rev() {
        let j = (rng.next_f64() * (i + 1) as f64) as usize;
        v.swap(i, j);
    }
    v
}

pub const SHUFFLES: usize = 50;

/// A valid table: 2 revisions × 2 task classes × 25 candidates × 3 metrics
pub fn valid_table() -> Vec<ObjectiveRow> {
    let mut rng = Rng(17_800);
    let metrics = [("cost", "MIN"), ("latency", "MIN"), ("quality", "MAX")];
    let mut rows = Vec::new();
    for revision in ["r1", "r2"] {
        for class in ["build", "test"] {
            for c in 0..25 {
                for (metric, direction) in metrics {
                    rows.push(ObjectiveRow::new(
                        revision,
                        class,
                        format!("c{c:02}"),
                        metric,
                        direction,
                        (rng.next_f64() * 100.0).round() / 10.0,
                    ));
                }
            }
        }
    }
    rows
}

/// IX's own table with several defects, from `the_reported_violation_does_not_depend_on_input_order`
pub fn ix_defect_table() -> Vec<ObjectiveRow> {
    vec![
        ObjectiveRow::new("rev-a", "t", "a", "cost", "MIN", f64::NAN),
        ObjectiveRow::new("rev-a", "t", "a", "cost", "MIN", 1.0),
        ObjectiveRow::new("rev-a", "t", "b", "cost", "MAX", 2.0),
        ObjectiveRow::new("rev-a", "t", "b", "quality", "MAX", 2.0),
    ]
}

pub struct Shuffles {
    pub frontier_rows: usize,
    /// Shuffles of the valid table whose CSV matched the unshuffled one's, byte for byte
    pub csv_equal: usize,
    /// Shuffles of IX's defect table that reported the same error as the table in order
    pub error_equal: usize,
    pub ix_error: String,
}

pub fn shuffles() -> Shuffles {
    let mut rng = Rng(17_801);
    let table = valid_table();
    let front = frontier(&table).expect("valid table");
    let csv = to_csv(&front);
    let defects = ix_defect_table();
    let error = frontier(&defects).expect_err("defects");
    let (mut csv_equal, mut error_equal) = (0, 0);
    for _ in 0..SHUFFLES {
        let rows = shuffled(&table, &mut rng);
        csv_equal += usize::from(to_csv(&frontier(&rows).expect("valid table")) == csv);
        let rows = shuffled(&defects, &mut rng);
        error_equal += usize::from(frontier(&rows).expect_err("defects") == error);
    }
    Shuffles {
        frontier_rows: front.len(),
        csv_equal,
        error_equal,
        ix_error: error.to_string(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn p1_selection_frequencies() {
        let s = selection();
        let close =
            |got: &[f64], want: &[f64]| got.iter().zip(want).all(|(g, w)| (g - w).abs() <= 0.006);
        assert!(
            close(&s.tournament, &[19.0 / 27.0, 7.0 / 27.0, 1.0 / 27.0]),
            "{:?}",
            s.tournament
        );
        assert!(close(&s.rank, &[0.5, 1.0 / 3.0, 1.0 / 6.0]), "{:?}", s.rank);
        assert!(
            close(&s.roulette, &[2.0 / 3.0, 1.0 / 3.0, 0.0]),
            "{:?}",
            s.roulette
        );
        assert!(close(
            &s.roulette_outlier,
            &[1000.0 / 1999.0, 999.0 / 1999.0, 0.0]
        ));
        assert!(
            close(&s.roulette_pair, &[1.0, 0.0]),
            "{:?}",
            s.roulette_pair
        );
        assert_eq!(s.roulette_worst, 0);
    }

    #[test]
    fn p2_blx_widens_by_seven_sixths() {
        let b = blx(200, 1000);
        assert_eq!(b.genes, 200_000);
        assert!(
            (b.child_variance - 7.0 / 6.0).abs() <= 0.015,
            "{}",
            b.child_variance
        );
        assert!(b.inside);
    }

    #[test]
    fn p3_the_mutation_rate_is_a_standard_deviation() {
        for rate in [0.1, 1.0, -0.1] {
            let m = mutation(rate).expect("finite rate");
            assert!(
                (m.changed - 0.3).abs() <= 0.005,
                "rate {rate}: {}",
                m.changed
            );
            assert!(
                (m.sd / rate.abs() - 1.0).abs() <= 0.02,
                "rate {rate}: {}",
                m.sd
            );
        }
        assert_eq!(mutation(0.0).expect("finite rate").changed, 0.0);
        assert!(mutation(f64::NAN).is_err());
    }

    #[test]
    fn p4_without_elitism_the_last_generation_is_returned() {
        let runs = elitism_runs(0);
        assert!(runs.iter().filter(|r| r.returned > r.best_seen).count() >= 18);
        assert!(runs.iter().all(|r| r.history_rises));
        let control = elitism_runs(2);
        assert!(
            control
                .iter()
                .all(|r| !r.history_rises && r.returned <= r.last_recorded)
        );
    }

    #[test]
    fn p5_evaluations_on_the_linreg_example_refuted_in_part() {
        let ga: Vec<Race> = (0..SEEDS).map(|s| ga_race(17_500 + s)).collect();
        let de: Vec<Race> = (0..SEEDS).map(|s| de_race(17_500 + s)).collect();
        // held: every GA run and every DE run gets below 0.01, within 49,100 and 50,050 evaluations
        assert!(
            ga.iter()
                .all(|r| r.evaluations == 49_100 && r.first_below.is_some())
        );
        assert!(
            de.iter()
                .all(|r| r.evaluations == 50_050 && r.first_below.is_some())
        );
        let ga_median = median(
            &ga.iter()
                .map(|r| r.first_below.unwrap())
                .collect::<Vec<_>>(),
        );
        let de_median = median(
            &de.iter()
                .map(|r| r.first_below.unwrap())
                .collect::<Vec<_>>(),
        );
        // refuted: the prediction put the GA's median between 1,000 and 10,000 evaluations, and DE's below
        // it. The first run measured 916 for the GA and 1,250 for DE. The test pins what was measured, so
        // that a change shows.
        assert_eq!(ga_median, 916.0);
        assert_eq!(de_median, 1_250.0);
    }

    #[test]
    fn p6_three_individuals_never_return() {
        assert!(!de_returns(3, 10, Duration::from_secs(2)));
        assert!(de_returns(4, 10, Duration::from_secs(2)));
    }

    #[test]
    fn p7_first_front_sizes() {
        let two = pareto_fronts(2);
        let three = pareto_fronts(3);
        assert!(
            (5.22..=6.54).contains(&two.mean_front0),
            "{}",
            two.mean_front0
        );
        assert!(
            (16.8..=19.4).contains(&three.mean_front0),
            "{}",
            three.mean_front0
        );
        for f in [&two, &three] {
            assert_eq!((f.brute_equal, f.reverse_equal), (SETS, SETS));
        }
    }

    #[test]
    fn p8_the_error_depends_on_row_order() {
        assert_eq!(error_direction(&misspelled(false)), "min");
        assert_eq!(error_direction(&misspelled(true)), "Max");
        let s = shuffles();
        assert_eq!((s.csv_equal, s.error_equal), (SHUFFLES, SHUFFLES));
    }

    #[test]
    fn splitmix_matches_the_course_stream() {
        use rand::RngCore;
        let (mut a, mut b) = (SplitMix(5), Rng(5));
        for _ in 0..10 {
            assert_eq!(
                (a.next_u64() >> 11) as f64 / (1u64 << 53) as f64,
                b.next_f64()
            );
        }
    }

    #[test]
    fn brute_force_fronts_on_a_hand_example() {
        // (1, 3) and (3, 1) are incomparable, (2, 2) too; (3, 3) is dominated by (2, 2), (4, 4) by all
        let points = vec![
            vec![1.0, 3.0],
            vec![3.0, 1.0],
            vec![2.0, 2.0],
            vec![3.0, 3.0],
            vec![4.0, 4.0],
        ];
        assert_eq!(
            brute_fronts(&points),
            vec![vec!["p000", "p001", "p002"], vec!["p003"], vec!["p004"]]
        );
    }
}
