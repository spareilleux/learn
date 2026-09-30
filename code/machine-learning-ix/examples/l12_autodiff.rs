//! Lesson 12: automatic differentiation. Forward and reverse mode by hand, then IX's `ix-autograd` tape,
//! measured against closed forms, central differences and the predictions preregistered in the journal.

use machine_learning_ix::autodiff::*;
use machine_learning_ix::fmt_vec;

/// An error too small to mean anything prints as a bound, so the output is the same on every OS
fn fmt_err(e: f64) -> String {
    if e < 1e-12 {
        "< 1e-12".to_string()
    } else {
        format!("{e:.0e}")
    }
}

fn main() {
    println!("== f(x1, x2) = ln(x1) + x1*x2 - sin(x2) at (2, 5)");
    let (f, g) = baydin_forward(2.0, 5.0);
    println!(
        "  forward mode, one pass per input:  f = {f:.4}, df/dx1 = {:.4}, df/dx2 = {:.4}",
        g[0], g[1]
    );
    let (f, g, tape) = baydin_reverse(2.0, 5.0);
    println!(
        "  reverse mode, one backward walk:   f = {f:.4}, df/dx1 = {:.4}, df/dx2 = {:.4}",
        g[0], g[1]
    );
    let adjoint = tape.backward(tape.ops.len() - 1);
    for (i, (op, v)) in tape.ops.iter().zip(&tape.values).enumerate() {
        println!(
            "  entry {i}: {:<10} value {v:>8.4}   adjoint {:>7.4}",
            format!("{op:?}"),
            adjoint[i]
        );
    }

    println!(
        "\n== IX's tape for the linear regression of `minimize_linreg_mse` (20 rows, 3 features)"
    );
    let (x, y) = ix_example_data();
    let run = ix_linreg(&x, &y, &[0.0; 3], 0.0);
    let ops = tape_ops(&run.ctx);
    println!("  {} nodes: {}", ops.len(), ops.join(", "));
    let var = variance_ops();
    println!("  ops::variance adds {}: {}", var.len(), var.join(", "));
    let mut rng = Rng(12);
    let random_w: Vec<f64> = (0..3).map(|_| rng.next_f64() * 2.0 - 1.0).collect();
    let random_b = rng.next_f64() * 2.0 - 1.0;
    for (label, w, b) in [
        ("w = 0, b = 0", vec![0.0; 3], 0.0),
        ("random w, b ", random_w, random_b),
    ] {
        let run = ix_linreg(&x, &y, &w, b);
        let cf = closed_form(&x, &y, &w, b);
        let s = run.state;
        let gw = run.grad(s.w).expect("w gradient");
        let gb = run.grad(s.b).expect("b gradient")[0];
        let gx = run.grad(s.x).expect("x gradient");
        let cfx: Vec<f64> = cf.x.iter().copied().collect();
        println!(
            "  {label}: loss {:.6}, dL/dw {}, dL/db {gb:.6}",
            run.loss(),
            fmt_vec(gw.iter().copied(), 6)
        );
        println!(
            "    largest difference from the closed forms: w {}, b {}, x {}",
            fmt_err(max_abs_diff(&gw, &cf.w)),
            fmt_err((gb - cf.b).abs()),
            fmt_err(max_abs_diff(&gx, &cfx))
        );
        let (loss, hw, hb, entries) = hand_tape_linreg(&x, &y, &w, b);
        println!(
            "    hand-written scalar tape, {entries} entries: loss {}, w {}, b {}",
            fmt_err((loss - run.loss()).abs()),
            fmt_err(max_abs_diff(&hw, &cf.w)),
            fmt_err((hb - cf.b).abs())
        );
    }

    println!("\n== What the tape does not check");
    let run = ix_linreg(&x, &y, &[0.3, 0.1, -0.2], 0.05);
    let y_node = run.ctx.tape.get(run.state.y).expect("y on the tape");
    let cf = closed_form(&x, &y, &[0.3, 0.1, -0.2], 0.05);
    match run.grad(run.state.y) {
        Some(gy) => println!(
            "  y has requires_grad = {}, and backward returned a gradient for it; largest difference from -(2/n)r: {}",
            y_node.value.requires_grad,
            fmt_err(max_abs_diff(&gy, &cf.y))
        ),
        None => println!("  y has no gradient"),
    }
    println!(
        "  x, also built with requires_grad = false, gets one too: {}",
        run.grad(run.state.x).is_some()
    );
    let hook = std::panic::take_hook();
    std::panic::set_hook(Box::new(|_| {}));
    let outcomes = mismatched_shapes();
    std::panic::set_hook(hook);
    for (name, outcome) in outcomes {
        println!("  {name} on [2, 3] and [3, 2]: {outcome:?}");
    }

    println!("\n== Central differences against the tape");
    println!("  mean squared error at w = 0 (quadratic in w), worst of the 3 components of dL/dw:");
    for (eps, err) in quadratic_fd_errors(&x, &y, &decades(12)) {
        println!("    eps {eps:.0e}: {}", fmt_err(err));
    }
    let (xs, c) = signal_and_weights(2026, 64);
    let errors = fft_fd_errors(&xs, &c, &decades(10));
    println!("  L = sum c_k |FFT(x)_k|, 64 samples, worst of the 64 components of dL/dx:");
    for &(eps, err) in &errors {
        println!("    eps {eps:.0e}: {}", fmt_err(err));
    }
    println!(
        "  IX's dL/dx, first four components: {}",
        fmt_vec(ix_fft_gradient(&xs, &c).into_iter().take(4), 6)
    );
    let (best, min) = best_eps(&errors);
    println!(
        "  smallest at eps {best:.0e}; eps 1e-1 is {:.0e} times that, eps 1e-10 {:.0e} times",
        errors[0].1 / min,
        errors[9].1 / min
    );

    println!("\n== IX's FFT-magnitude backward (feature fft-autograd)");
    println!(
        "  20 signals of 64 samples, each with its own weights, eps 1e-5: worst error over 1280 components {}",
        fmt_err(fft_fd_check(20, 64, 1e-5))
    );

    println!("\n== IX's `minimize_linreg_mse`, replayed");
    let ks: Vec<String> = (0..20)
        .map(|i| format!("{:.0}", ((example_noise(i) + 0.01) / (0.02 / 32767.0))))
        .collect();
    println!(
        "  k in the noise -0.01 + k*0.02/32767, rows 0 to 19: {}",
        ks.join(" ")
    );
    let gap: Vec<f64> = (0..20).map(|i| x[[i, 2]] - x[[i, 0]]).collect();
    println!(
        "  x[i, 2] - x[i, 0] over the 20 rows: min {:.6}, max {:.6}",
        gap.iter().copied().fold(f64::INFINITY, f64::min),
        gap.iter().copied().fold(f64::NEG_INFINITY, f64::max)
    );
    let (w, b, mse) = least_squares(&x, &y);
    println!(
        "  least squares: w {}, b {b:.6}, w0 + w2 = {:.6}, mean squared error {}",
        fmt_vec(w.iter().copied(), 6),
        w[0] + w[2],
        fmt_err(mse)
    );
    let adam = ix_example_adam(&x, &y, 200);
    for (step, loss) in &adam.trace {
        println!("  Adam step {step:>3}: loss {loss:.2e}");
    }
    println!(
        "  after 200 steps: w {}, b {:.6}, w0 + w2 = {:.6}, loss {:.2e}",
        fmt_vec(adam.w.iter().copied(), 6),
        adam.b,
        adam.w[0] + adam.w[2],
        adam.final_loss
    );
    match adam.converged_at {
        Some(step) => println!(
            "  loss below 0.01 first at step {step}; the example prints 7500 / {step} = {:.0}x as its speedup over a genetic algorithm",
            7500.0 / step as f64
        ),
        None => println!("  loss never below 0.01"),
    }
}
