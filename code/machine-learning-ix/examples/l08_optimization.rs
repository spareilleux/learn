//! Lesson 8: three update rules down Rosenbrock's valley, by hand and with ix_optimize; the cost
//! of a gradient nobody wrote; what `minimize` returns when the run blows up; and two searches
//! that need no gradient at all.

use ix_math::calculus::numerical_gradient;
use ix_optimize::annealing::{CoolingSchedule, SimulatedAnnealing};
use ix_optimize::convergence::ConvergenceCriteria;
use ix_optimize::gradient::{Adam as IxAdam, Momentum as IxMomentum, SGD as IxSgd, minimize};
use ix_optimize::pso::ParticleSwarm;
use ix_optimize::traits::{ClosureObjective, ObjectiveFunction, Optimizer};
use machine_learning_ix::data::load_builds;
use machine_learning_ix::evaluation::{mean, std_dev};
use machine_learning_ix::optimize::{
    Adam, Momentum, Run, Sgd, Step, descend, rosenbrock, rosenbrock_gradient,
};
use machine_learning_ix::{data_path, fmt_vec};
use ndarray::{Array1, array};

/// Rosenbrock with the gradient written out, so `minimize` never has to measure it.
struct Rosenbrock;

impl ObjectiveFunction for Rosenbrock {
    fn evaluate(&self, x: &Array1<f64>) -> f64 {
        rosenbrock(x)
    }
    fn gradient(&self, x: &Array1<f64>) -> Array1<f64> {
        rosenbrock_gradient(x)
    }
    fn dim(&self) -> usize {
        2
    }
}

fn show(name: &str, run: &Run) {
    println!(
        "  {name:9} {:5} steps: last {} f {:.6}, best f {:.6}",
        run.steps,
        fmt_vec(run.last.iter().copied(), 4),
        run.last_value,
        run.best_value
    );
}

fn main() {
    let start = array![-1.2, 1.0];
    println!(
        "== Rosenbrock from {}, minimum 0 at [1, 1]",
        fmt_vec(start.iter().copied(), 1)
    );
    println!("  f(start) = {:.4}", rosenbrock(&start));

    // 1. The three rules by hand
    println!("\n== by hand, 5000 steps at most");
    let mut sgd = Sgd {
        learning_rate: 0.001,
    };
    let mut momentum = Momentum::new(0.001, 0.9);
    let mut adam = Adam::new(0.05);
    let rules: Vec<&mut dyn Step> = vec![&mut sgd, &mut momentum, &mut adam];
    for rule in rules {
        let name = rule.name();
        let run = descend(
            rosenbrock,
            rosenbrock_gradient,
            rule,
            start.clone(),
            5000,
            1e-8,
        );
        show(name, &run);
    }

    // 2. ix_optimize on the same problem, with the same rules and the written gradient
    println!("\n== ix_optimize::gradient::minimize, the same 5000 steps");
    let criteria = ConvergenceCriteria::new(5000, 1e-8);
    let report = |name: &str, result: ix_optimize::traits::OptimizeResult| {
        println!(
            "  {name:9} {:5} steps: best {} f {:.6}, converged {}",
            result.iterations,
            fmt_vec(result.best_params.iter().copied(), 4),
            result.best_value,
            result.converged
        );
    };
    report(
        "SGD",
        minimize(
            &Rosenbrock,
            &mut IxSgd::new(0.001),
            start.clone(),
            &criteria,
        ),
    );
    report(
        "Momentum",
        minimize(
            &Rosenbrock,
            &mut IxMomentum::new(0.001, 0.9),
            start.clone(),
            &criteria,
        ),
    );
    report(
        "Adam",
        minimize(
            &Rosenbrock,
            &mut IxAdam::new(0.05),
            start.clone(),
            &criteria,
        ),
    );

    // 3. One Adam step, side by side
    let gradient = rosenbrock_gradient(&start);
    let mut hand_one = Adam::new(0.05);
    let mut ix_one = IxAdam::new(0.05);
    println!("\n== the first Adam step from the same gradient");
    println!("  gradient {}", fmt_vec(gradient.iter().copied(), 4));
    println!(
        "  hand {}",
        fmt_vec(hand_one.step(&start, &gradient).iter().copied(), 8)
    );
    println!(
        "  ix   {}",
        fmt_vec(ix_one.step(&start, &gradient).iter().copied(), 8)
    );

    // 4. What a gradient nobody wrote costs. `ClosureObjective` has no `gradient`, so the
    //    default runs `ix_math::calculus::numerical_gradient` with a step of 1e-7.
    let measured = numerical_gradient(&|v: &Array1<f64>| rosenbrock(v), &start, 1e-7);
    println!("\n== the gradient at the start, written and measured");
    println!("  written  {}", fmt_vec(gradient.iter().copied(), 9));
    println!("  measured {}", fmt_vec(measured.iter().copied(), 9));
    println!(
        "  largest gap {:.2e}, and two extra evaluations of f per coordinate per step",
        gradient
            .iter()
            .zip(measured.iter())
            .map(|(a, b): (&f64, &f64)| (a - b).abs())
            .fold(0.0f64, f64::max)
    );
    let closure = ClosureObjective {
        f: |v: &Array1<f64>| rosenbrock(v),
        dimensions: 2,
    };
    let mut closure_adam = IxAdam::new(0.05);
    let closure_result = minimize(&closure, &mut closure_adam, start.clone(), &criteria);
    println!(
        "  Adam on ClosureObjective: best f {:.3e} against {:.3e} with the written gradient",
        closure_result.best_value,
        {
            let mut a = IxAdam::new(0.05);
            minimize(&Rosenbrock, &mut a, start.clone(), &criteria).best_value
        }
    );

    // 5. A learning rate that blows the run up. `minimize` reports the best point it passed,
    //    not where it ended, so the result looks finite while the run did not.
    println!("\n== a step size that diverges");
    let mut wild = IxSgd::new(0.01);
    let wild_result = minimize(&Rosenbrock, &mut wild, start.clone(), &criteria);
    println!(
        "  ix SGD lr 0.01: best f {:.6} after {} steps, converged {}",
        wild_result.best_value, wild_result.iterations, wild_result.converged
    );
    let mut hand_wild = Sgd {
        learning_rate: 0.01,
    };
    let hand_run = descend(
        rosenbrock,
        rosenbrock_gradient,
        &mut hand_wild,
        start.clone(),
        5000,
        1e-8,
    );
    println!(
        "  the same run by hand ends at f {} — the best point hides the divergence",
        if hand_run.last_value.is_finite() {
            format!("{:.6}", hand_run.last_value)
        } else {
            format!("{}", hand_run.last_value)
        }
    );

    // 6. Two searches that never ask for a gradient
    println!("\n== without a gradient");
    let annealing = SimulatedAnnealing::new()
        .with_temp(10.0, 1e-6)
        .with_cooling(CoolingSchedule::Exponential { alpha: 0.995 })
        .with_max_iterations(20_000)
        .with_step_size(0.3)
        .with_seed(42);
    let annealed = annealing.minimize(&Rosenbrock, start.clone());
    println!(
        "  simulated annealing, seed 42: best {} f {:.6} after {} iterations",
        fmt_vec(annealed.best_params.iter().copied(), 4),
        annealed.best_value,
        annealed.iterations
    );
    let swarm = ParticleSwarm::new()
        .with_particles(40)
        .with_max_iterations(200)
        .with_bounds(-2.0, 2.0)
        .with_seed(42);
    let swarmed = swarm.minimize(&Rosenbrock);
    println!(
        "  particle swarm, 40 particles, seed 42: best {} f {:.6}",
        fmt_vec(swarmed.best_params.iter().copied(), 4),
        swarmed.best_value
    );

    // 7. Back to the line of lesson 2: the same three rules on a real loss
    let builds = load_builds(data_path("builds.csv"));
    let pages = builds.pages.column(0).to_owned();
    let (pm, ps) = (mean(&pages), std_dev(&pages));
    let (sm, ss) = (mean(&builds.seconds), std_dev(&builds.seconds));
    let x: Array1<f64> = pages.mapv(|v| (v - pm) / ps);
    let y: Array1<f64> = builds.seconds.mapv(|v| (v - sm) / ss);
    let n = x.len() as f64;
    let loss = |w: &Array1<f64>| {
        x.iter()
            .zip(y.iter())
            .map(|(a, b)| (w[0] * a + w[1] - b).powi(2))
            .sum::<f64>()
            / n
    };
    let loss_gradient = |w: &Array1<f64>| {
        let (mut dw, mut db) = (0.0, 0.0);
        for (a, b) in x.iter().zip(y.iter()) {
            let e = w[0] * a + w[1] - b;
            dw += 2.0 * e * a / n;
            db += 2.0 * e / n;
        }
        Array1::from_vec(vec![dw, db])
    };
    // Standardized on both sides, the closed form is just the correlation
    let closed = x.iter().zip(y.iter()).map(|(a, b)| a * b).sum::<f64>() / n;
    println!("\n== the build-time line, standardized: closed form slope {closed:.6}, intercept 0");
    let zero = array![0.0, 0.0];
    for (name, rule) in [
        ("SGD", Box::new(Sgd { learning_rate: 0.1 }) as Box<dyn Step>),
        ("Momentum", Box::new(Momentum::new(0.1, 0.9))),
        ("Adam", Box::new(Adam::new(0.1))),
    ] {
        let mut rule = rule;
        let run = descend(
            loss,
            loss_gradient,
            rule.as_mut(),
            zero.clone(),
            2000,
            1e-10,
        );
        println!(
            "  {name:9} {:4} steps: slope {:.6}, intercept {:.6}, loss {:.6}",
            run.steps, run.last[0], run.last[1], run.last_value
        );
    }
}
