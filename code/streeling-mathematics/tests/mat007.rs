//! Each pre-registered MAT-007 claim (preregistration-mat007.md, M7-P1a to M7-P2d) as an assertion.
//! The claims are quoted from section 6 of the module; the bands for "about" were set before the run.

use streeling_mathematics::mat007::*;

fn fit_offset(c: f64) -> Fit {
    silence_fit_panics();
    let (x, y) = offset_data(c);
    ix_fit(&x, &y)
}

fn fit_scale(n: f64) -> (Fit, SvdRoute) {
    silence_fit_panics();
    let (x, y) = collinear_data(n);
    (ix_fit(&x, &y), svd_route(&x, &y))
}

fn fit_error(fit: &Fit) -> f64 {
    match fit {
        Fit::Params { weights, bias } => param_error(weights, *bias),
        Fit::Panicked(message) => panic!("fit panicked: {message}"),
    }
}

#[test]
fn m7_p1a_the_slope_is_within_1e_9_of_2_up_to_c_1e3() {
    for c in [1.0, 1e1, 1e2, 1e3] {
        let (slope, _) = fit_offset(c).slope_and_bias().expect("fit returns");
        assert!((slope - 2.0).abs() < 1e-9, "c = {c:e}: slope {slope}");
    }
}

#[test]
fn m7_p1b_at_c_1e5_the_slope_is_2_minus_2_pow_minus_18_and_the_bias_1_5() {
    let (slope, bias) = fit_offset(1e5).slope_and_bias().expect("fit returns");
    assert_eq!(
        slope.to_bits(),
        (2.0 - 2f64.powi(-18)).to_bits(),
        "slope {slope}"
    );
    assert_eq!(bias.to_bits(), 1.5f64.to_bits(), "bias {bias}");
}

#[test]
fn m7_p1c_at_c_1e6_the_fit_returns_slope_2_plus_2_pow_minus_11_bias_0_and_misses_by_about_487() {
    let (x, y) = offset_data(1e6);
    let (slope, bias) = fit_offset(1e6)
        .slope_and_bias()
        .expect("fit returns, no panic");
    assert_eq!(slope.to_bits(), 2.00048828125f64.to_bits(), "slope {slope}");
    assert_eq!(bias.to_bits(), 0f64.to_bits(), "bias {bias}");
    let error = max_fit_error(&x, &y, &[slope], bias);
    assert!((486.0..=489.0).contains(&error), "max |fit - y| = {error}");
}

#[test]
fn m7_p1d_at_c_1e7_fit_panics_with_x_t_x_is_singular() {
    match fit_offset(1e7) {
        Fit::Panicked(message) => assert!(message.contains("X^T X is singular"), "{message}"),
        other => panic!("expected a panic, got {other:?}"),
    }
}

#[test]
fn m7_p1e_centered_the_slope_is_exactly_2_and_the_bias_2c_plus_3_within_1e_15() {
    silence_fit_panics();
    for c in offsets() {
        let (x, y) = centered_data(c);
        let (slope, bias) = ix_fit(&x, &y).slope_and_bias().expect("fit returns");
        let exact = 2.0 * c + 3.0;
        assert_eq!(slope.to_bits(), 2f64.to_bits(), "c = {c:e}: slope {slope}");
        assert!(
            (bias - exact).abs() <= 1e-15 * exact,
            "c = {c:e}: bias {bias}, exact {exact}"
        );
    }
}

#[test]
fn m7_p2a_the_normal_equations_are_within_1e_9_up_to_n_1e3() {
    for n in [1.0, 1e1, 1e2, 1e3] {
        let e = fit_error(&fit_scale(n).0);
        assert!(e < 1e-9, "N = {n:e}: error {e:e}");
    }
}

#[test]
fn m7_p2b_at_n_1e5_the_normal_equations_err_by_about_3e_5() {
    let e = fit_error(&fit_scale(1e5).0);
    assert!((3e-6..=3e-4).contains(&e), "error {e:e}");
}

#[test]
fn m7_p2c_at_n_1e7_the_normal_equations_return_and_err_by_about_0_25() {
    let e = fit_error(&fit_scale(1e7).0);
    assert!((0.025..=2.5).contains(&e), "error {e:e}");
}

#[test]
fn m7_p2d_the_svd_route_stays_below_1e_7_at_every_n() {
    for n in scales() {
        let route = fit_scale(n).1;
        let e = param_error(&route.weights, route.bias);
        assert!(
            e < 1e-7,
            "N = {n:e}: error {e:e}, kappa_2 {:e}",
            route.kappa2
        );
    }
}

#[test]
fn controls_every_check_can_fail() {
    assert!(param_error(&[1.0, 1.0], 0.0) >= 1.0);
    assert_ne!((2.0 - 2f64.powi(-18)).to_bits(), 2f64.to_bits());
    assert!(matches!(fit_offset(1.0), Fit::Params { .. }));
    silence_fit_panics();
    assert_eq!(
        catch_panic::<()>(|| std::panic::panic_any(CONTROL_PANIC)),
        Err(CONTROL_PANIC.to_string())
    );
}
