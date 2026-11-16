//! MAT-004: IX's distances on a grid, `minkowski` at the edges of its guard, `cosine_distance`, and the product
//! rule of `determinant`. The printed values are for reading; tests/mat004.rs checks each pre-registered claim.
//! Step 5's timings print to stderr only when MAT004_TIMING is set, so they never enter expected/.

use ix_math::distance::{chebyshev, minkowski};
use ix_math::linalg::determinant;
use ndarray::array;
use std::time::Instant;
use streeling_mathematics::mat004::*;
use streeling_mathematics::max_or_nan;

fn show(r: &Result<f64, ix_math::error::MathError>) -> String {
    match r {
        Ok(v) => format!("Ok({v:?})"),
        Err(e) => format!("Err({e})"),
    }
}

/// The fastest of 5 runs, per call, in seconds.
fn time_determinant(n: usize) -> f64 {
    let a = fixed_matrix(n);
    let k = calls_per_run(n as u64);
    (0..5)
        .map(|_| {
            let start = Instant::now();
            for _ in 0..k {
                std::hint::black_box(determinant(std::hint::black_box(&a)).expect("square"));
            }
            start.elapsed().as_secs_f64() / k as f64
        })
        .fold(f64::INFINITY, f64::min)
}

fn main() {
    let mut raw = Vec::new();
    println!("MAT-004: ix-math distances and determinant at e35138b9, IEEE 754 binary64");

    println!();
    println!(
        "Step 1: triangle inequality on the 25 grid points, largest d(x, z) - (d(x, y) + d(y, z))"
    );
    let points = grid();
    for (name, d) in distances() {
        let (worst, positive, count) = triangle(d, &points);
        raw.push(worst);
        println!(
            "  {name:<15} | {count} triples | largest excess {worst:.3e} | strictly positive in {positive}"
        );
    }

    println!();
    println!("Step 2: minkowski with p = 1/2 on (x, y), (y, z), (x, z) of the section 5 exercise:");
    for r in half_p_results() {
        println!("  {}", show(&r));
    }

    println!();
    let inf = f64::INFINITY;
    let (o, t) = (origin(), three_four());
    let step3 = [minkowski(&o, &o, inf), minkowski(&o, &t, inf)];
    let cheb = [chebyshev(&o, &o), chebyshev(&o, &t)];
    println!(
        "Step 3: minkowski with p = inf: (0, 0)-(0, 0) {}, (0, 0)-(3, 4) {}; chebyshev: {}, {}",
        show(&step3[0]),
        show(&step3[1]),
        show(&cheb[0]),
        show(&cheb[1])
    );

    println!();
    let step4 = minkowski(&o, &t, 1000.0);
    println!(
        "Step 4: minkowski with p = 1000 on (0, 0)-(3, 4): {}",
        show(&step4)
    );

    println!();
    let pairs = product_rule_pairs();
    let exact = pairs
        .iter()
        .filter(|p| p.det_ab == p.det_a * p.det_b)
        .count();
    let singular = pairs
        .iter()
        .filter(|p| p.det_a == 0.0 || p.det_b == 0.0)
        .count();
    let largest = pairs.iter().map(|p| p.det_ab.abs()).fold(0.0, max_or_nan);
    for p in &pairs {
        raw.extend([p.det_a, p.det_b, p.det_ab]);
    }
    println!(
        "Step 5: det(AB) == det A * det B for {exact} of {} pairs; {singular} pairs have a singular factor; largest |det(AB)| {largest}",
        pairs.len()
    );
    println!("  timing: only with MAT004_TIMING, on stderr");

    println!();
    let (direct, around) = cosine_triangle();
    raw.extend([direct, around]);
    println!(
        "Section 6: cosine_distance d(x, z) = {direct:.12}, d(x, y) + d(y, z) = {around:.12} (2 - sqrt 2 = {:.12})",
        2.0 - 2f64.sqrt()
    );
    let nan = f64::NAN;
    println!(
        "Section 6: minkowski with p = NaN: (0, 0)-(3, 4) {}, (0, 0)-(0, 0) {}",
        show(&minkowski(&o, &t, nan)),
        show(&minkowski(&o, &o, nan))
    );

    println!();
    let one_d = minkowski(&array![0.0], &array![1.0], nan);
    println!(
        "M4-L1, the lab's own: minkowski([0], [1], NaN) = {}",
        show(&one_d)
    );

    println!();
    println!("Negative controls:");
    let [x, y, z] = exercise_points();
    let (worst, positive, _) = triangle(half_distance, &[x, y, z]);
    println!(
        "  p = 1/2 by hand on the exercise points: largest excess {worst}, strictly positive in {positive} triples"
    );
    let additive = pairs
        .iter()
        .filter(|p| p.det_ab != p.det_a + p.det_b)
        .count();
    println!(
        "  det(AB) == det A + det B fails for {additive} of {} pairs",
        pairs.len()
    );
    println!(
        "  NaN is not NaN? {}; 1.0 is NaN? {}; inf is NaN? {}",
        !nan.is_nan(),
        1.0f64.is_nan(),
        inf.is_nan()
    );

    println!();
    println!(
        "raw-bits digest of every computed value: {:016x}",
        streeling_mathematics::bits_digest(raw.iter())
    );

    if std::env::var_os("MAT004_TIMING").is_some() {
        let mut previous = None;
        for n in 2..=11 {
            let t = time_determinant(n);
            match previous {
                Some(p) => eprintln!(
                    "step 5, n = {n:>2}: {t:.3e} s per call, {} calls per run, ratio {:.2} (band {:.1} to {})",
                    calls_per_run(n as u64),
                    t / p,
                    n as f64 / 2.0,
                    2 * n
                ),
                None => eprintln!(
                    "step 5, n = {n:>2}: {t:.3e} s per call, {} calls per run",
                    calls_per_run(n as u64)
                ),
            }
            previous = Some(t);
        }
    }
}
