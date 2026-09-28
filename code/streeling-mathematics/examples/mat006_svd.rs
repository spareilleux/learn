//! MAT-006: IX's one-sided Jacobi SVD against Eckart–Young, across scales, and on MAT-003's puzzle.
//! The printed values are for reading; tests/mat006.rs checks each pre-registered claim.
//! Step 3 (timings) prints to stderr only when MAT006_TIMING is set, so it never enters expected/.

use ix_math::svd::svd;
use ndarray::Array2;
use std::time::Instant;
use streeling_mathematics::mat006::*;

fn max(values: &[f64]) -> f64 {
    values.iter().copied().fold(0.0, f64::max)
}

fn zero_columns(flags: &[bool]) -> String {
    flags.iter().map(|&z| if z { "0" } else { "x" }).collect()
}

fn k(value: Option<usize>) -> String {
    value.map_or("none".to_string(), |v| v.to_string())
}

/// The fastest of 5 runs of 20,000 calls, in seconds.
fn time_svd(x: &Array2<f64>) -> f64 {
    (0..5)
        .map(|_| {
            let start = Instant::now();
            for _ in 0..20_000 {
                std::hint::black_box(svd(std::hint::black_box(x)).expect("svd"));
            }
            start.elapsed().as_secs_f64()
        })
        .fold(f64::INFINITY, f64::min)
}

fn main() {
    let mut raw = Vec::new();
    println!(
        "MAT-006: ix-math svd at e35138b9 (one-sided Jacobi, 50 sweeps, tol 1e-12), IEEE 754 binary64"
    );

    println!();
    println!(
        "Step 1: Eckart-Young, ||X - X_k||_F from truncated_svd against sqrt(sigma_k+1^2 + ...)"
    );
    for (name, x) in [("A", matrix_a()), ("M", matrix_m())] {
        println!("  {name}, ||{name}||_F = {:.6e}", frobenius(&x));
        for row in eckart_young(&x) {
            raw.extend([row.truncation_error, row.tail]);
            println!(
                "    k = {} | truncation {:.6e} | tail {:.6e} | difference {:.3e}",
                row.k,
                row.truncation_error,
                row.tail,
                (row.truncation_error - row.tail).abs()
            );
        }
    }

    println!();
    println!(
        "Step 2: scale sweep, s = 10^e; sigma error is max_i |sigma_i(sX)/s - sigma_i(X)| / sigma_i(X)"
    );
    println!("  U columns: 0 = exactly zero, x = filled");
    for (name, x) in [("A", matrix_a()), ("M", matrix_m())] {
        println!("  {name}:");
        for (e, s) in scales() {
            let row = scale_row(&x, e, s);
            raw.extend(row.sigma_relative_errors.iter().copied());
            raw.push(row.reconstruction_error);
            println!(
                "    e = {:>3} | sigma error {:>9.3e} | reconstruct error {:>9.3e} | U columns {}",
                row.exponent,
                max(&row.sigma_relative_errors),
                row.reconstruction_error,
                zero_columns(&row.u_zero_columns)
            );
        }
    }

    println!();
    println!(
        "Step 4: svd_with_opts(2^20 fl(H_n), k, 1e-12) / 2^20 for k = 1..6, first k equal bit for bit to"
    );
    println!(
        "  svd(fl(H_n)) (scale 1) and to svd(2^-20 fl(H_n)) / 2^-20 (scale down); predicted in brackets"
    );
    for n in 2..=16 {
        let row = puzzle(n);
        let (p1, p2) = predicted_puzzle(n);
        println!(
            "  n = {:>2} | scale 1: k = {:>4} [{p1}] | scale down: k = {:>4} [{p2}] | scale 1 == scale down: {} | predicted k matches too: {}, {}",
            row.n,
            k(row.k_matching_scale_1),
            k(row.k_matching_scale_down),
            row.scale_1_equals_scale_down,
            row.predicted_k_also_matches.0,
            row.predicted_k_also_matches.1
        );
    }

    println!();
    let (absolute, relative) = rank_conventions();
    println!(
        "Step 5: svd(1e-12 I_3): rank(1e-10) = {absolute}, rank(3 sigma_1 eps) = {relative} (ix_svd over MCP: not run)"
    );

    println!();
    let e = rank_1_relative_error();
    raw.push(e);
    println!(
        "Step 6: relative error of truncated_svd(A, 1) = {e:.6}; IX's test accepts anything below 0.10"
    );

    println!();
    println!("Negative controls:");
    let a = matrix_a();
    let s = svd(&a).expect("svd").singular_values.to_vec();
    println!(
        "  Eckart-Young with sigma_2 left out of the tail, k = 0: difference {:.3e}",
        (tail(&s, 0) - tail(&s[..1], 0)).abs()
    );
    println!(
        "  relative error of A against itself: {:e}; of the zero matrix against A: {:e}",
        frobenius_diff(&a, &a) / frobenius(&a),
        frobenius_diff(&Array2::zeros((3, 2)), &a) / frobenius(&a)
    );
    println!(
        "  sizes whose scale-1 and scale-down singular values differ: {}",
        (2..=16)
            .filter(|&n| !puzzle(n).scale_1_equals_scale_down)
            .count()
    );

    println!();
    println!(
        "raw-bits digest of every computed value: {:016x}",
        streeling_mathematics::bits_digest(raw.iter())
    );

    if std::env::var_os("MAT006_TIMING").is_some() {
        for (name, x) in [("A", matrix_a()), ("M", matrix_m())] {
            let scaled = x.mapv(|v| v * 1e6);
            let (t1, t6) = (time_svd(&x), time_svd(&scaled));
            eprintln!(
                "step 3, {name}: 20,000 calls in {t1:.4} s at scale 1 and {t6:.4} s at 1e6, ratio {:.2}",
                t6 / t1
            );
        }
    }
}
