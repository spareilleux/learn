//! MAT-007: IX's normal-equation fit on offset and nearly collinear designs, against the SVD route.
//! The printed values are for reading; tests/mat007.rs checks each pre-registered claim.
//! Exact values print in Rust's shortest round-trip form, so 2.00048828125 is the stored f64 itself.

use streeling_mathematics::mat007::*;

fn verdict(fit: &Fit) -> String {
    match fit {
        Fit::Params { .. } => "returned".to_string(),
        Fit::Panicked(message) => format!("panicked: {message}"),
    }
}

fn main() {
    silence_fit_panics();
    let mut raw = Vec::new();

    println!("MAT-007: ix-supervised LinearRegression::fit at e35138b9, IEEE 754 binary64");
    println!(
        "fit solves the normal equations with inverse(X^T X), which refuses a pivot below 1e-12"
    );
    println!();
    println!("Step 1: x = c + (0, 1, 2), y = 2x + 1 (exact: slope 2, bias 1)");
    println!(
        "{:>6} | {:>22} | {:>22} | {:>12} | fit",
        "c", "slope", "bias", "max|fit-y|"
    );
    for c in offsets() {
        let (x, y) = offset_data(c);
        let fit = ix_fit(&x, &y);
        match fit.slope_and_bias() {
            Some((slope, bias)) => {
                let error = max_fit_error(&x, &y, &[slope], bias);
                raw.extend([slope, bias, error]);
                println!(
                    "{c:>6e} | {slope:>22} | {bias:>22} | {error:>12.3e} | {}",
                    verdict(&fit)
                );
            }
            None => println!(
                "{c:>6e} | {:>22} | {:>22} | {:>12} | {}",
                "-",
                "-",
                "-",
                verdict(&fit)
            ),
        }
    }

    println!();
    println!("Step 1, centered feature (-1, 0, 1), same y (exact: slope 2, bias 2c + 3)");
    println!(
        "{:>6} | {:>22} | {:>22} | {:>12}",
        "c", "slope", "bias", "rel. bias err"
    );
    for c in offsets() {
        let (x, y) = centered_data(c);
        let fit = ix_fit(&x, &y);
        let (slope, bias) = fit.slope_and_bias().expect("the centered fit returns");
        let exact = 2.0 * c + 3.0;
        let relative = (bias - exact).abs() / exact;
        raw.extend([slope, bias, relative]);
        println!("{c:>6e} | {slope:>22} | {bias:>22} | {relative:>12.3e}");
    }

    println!();
    println!(
        "Step 2: x1 = N (1, 2, 3, 4), x2 = x1 + (1, -1, -1, 1), y = x1 + x2 + 1 (exact: 1, 1, bias 1)"
    );
    println!("SVD route: pseudo_inverse of [x1 x2 1] at tol = 4 * sigma_1 * EPSILON, times y");
    println!(
        "{:>6} | {:>10} | {:>12} | {:>12} | fit",
        "N", "kappa_2", "fit error", "svd error"
    );
    for n in scales() {
        let (x, y) = collinear_data(n);
        let fit = ix_fit(&x, &y);
        let route = svd_route(&x, &y);
        let svd_error = param_error(&route.weights, route.bias);
        raw.extend(route.weights.iter().copied());
        raw.extend([route.bias, route.kappa2, svd_error]);
        let fit_error = match &fit {
            Fit::Params { weights, bias } => {
                let e = param_error(weights, *bias);
                raw.extend(weights.iter().copied());
                raw.extend([*bias, e]);
                format!("{e:>12.3e}")
            }
            Fit::Panicked(_) => format!("{:>12}", "-"),
        };
        println!(
            "{n:>6e} | {:>10.3e} | {fit_error} | {svd_error:>12.3e} | {}",
            route.kappa2,
            verdict(&fit)
        );
    }

    println!();
    println!("Negative controls:");
    println!(
        "  weight error of the wrong answer (1, 1, bias 0): {:.3e}",
        param_error(&[1.0, 1.0], 0.0)
    );
    println!(
        "  2 - 2^-18 == 2 bit for bit: {}",
        (2.0 - 2f64.powi(-18)).to_bits() == 2f64.to_bits()
    );
    println!(
        "  panic catcher on a closure that panics: {:?}",
        catch_panic::<()>(|| std::panic::panic_any(CONTROL_PANIC))
    );

    println!();
    println!(
        "raw-bits digest of every computed value: {:016x}",
        streeling_mathematics::bits_digest(raw.iter())
    );
}
