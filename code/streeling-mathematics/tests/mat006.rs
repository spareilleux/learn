//! Each pre-registered MAT-006 claim (preregistration-mat006.md, M6-P1 to M6-P6) as an assertion.
//! The claims are quoted from section 7 and the section 6 exercise of the module; the bands were set
//! before the run. Step 3 (timings) is not asserted here.

use ndarray::Array2;
use streeling_mathematics::mat006::*;

fn matrices() -> [(&'static str, Array2<f64>); 2] {
    [("A", matrix_a()), ("M", matrix_m())]
}

#[test]
fn m6_p1_eckart_young_holds_for_every_k_decreases_and_vanishes_at_full_rank() {
    for (name, x) in matrices() {
        let norm = frobenius(&x);
        let rows = eckart_young(&x);
        for row in &rows {
            assert!(
                (row.truncation_error - row.tail).abs() <= 1e-9 * norm,
                "{name}, k = {}: truncation {:e}, tail {:e}",
                row.k,
                row.truncation_error,
                row.tail
            );
        }
        for pair in rows.windows(2) {
            assert!(
                pair[1].truncation_error <= pair[0].truncation_error,
                "{name}: the error grows from k = {} to k = {}",
                pair[0].k,
                pair[1].k
            );
        }
        let last = rows.last().expect("k = n");
        assert!(
            last.truncation_error <= 1e-12 * norm,
            "{name}, k = {}: {:e}",
            last.k,
            last.truncation_error
        );
    }
}

#[test]
fn m6_p2a_the_singular_values_of_s_a_scale_with_s_at_every_scale() {
    for (e, s) in scales() {
        let row = scale_row(&matrix_a(), e, s);
        for err in &row.sigma_relative_errors {
            assert!(*err <= 1e-12, "e = {e}: {err:e}");
        }
    }
}

#[test]
fn m6_p2b_reconstruct_of_s_a_is_accurate_then_rank_1_then_zero() {
    for (e, s) in scales() {
        let err = scale_row(&matrix_a(), e, s).reconstruction_error;
        match e {
            -11.. => assert!(err < 1e-12, "e = {e}: {err:e}"),
            -12 => assert!((0.0535..=0.0545).contains(&err), "e = {e}: {err:e}"),
            _ => assert_eq!(err, 1.0, "e = {e}"),
        }
    }
}

#[test]
fn m6_p2c_the_columns_of_u_stay_zero_below_the_absolute_threshold() {
    for (e, s) in scales().into_iter().filter(|(e, _)| *e <= -13) {
        let zero = scale_row(&matrix_a(), e, s).u_zero_columns;
        assert_eq!(zero, vec![true, true], "e = {e}");
    }
    let zero = scale_row(&matrix_a(), -12, ten_to(-12)).u_zero_columns;
    assert_eq!(zero, vec![false, true]);
}

#[test]
fn m6_p2d_m_is_accurate_from_1e_10_and_wrong_by_over_100_percent_from_1e_13_down() {
    for (e, s) in scales() {
        let row = scale_row(&matrix_m(), e, s);
        let worst = row
            .sigma_relative_errors
            .iter()
            .copied()
            .fold(0.0, f64::max);
        if e >= -10 {
            assert!(worst <= 1e-12, "e = {e}: {worst:e}");
        } else if e <= -13 {
            assert!(worst > 1.0, "e = {e}: worst relative error {worst:e}");
        }
    }
}

// M6-P4 was pre-registered as "the smallest matching k is the module's predicted pair for every n".
// Partly refuted on the first run: for n = 2 to 5 the smallest k is lower than predicted (n = 2: 1 and 1,
// predicted 2 and 2; n = 3: 2 and 2, predicted 4 and 3; n = 4 and 5: 3 and 3, predicted 4 and 3); for
// n = 6 to 16 it is exactly the predicted pair. What the module's explanation needs does hold for every n:
// some k <= 6 at scale 2^20 reproduces both uncapped results bit for bit. The test pins what was measured.
// Post hoc, not pre-registered: at the predicted k the capped result also reproduces both, for every n, so
// the module's sweep counts hold; for n = 2 to 5 the sweeps after the first matching k change no bit.
#[test]
fn m6_p4_capped_sweeps_reproduce_both_results_and_the_first_k_is_as_predicted_from_n_6() {
    let measured_below_6 = [(2, 1, 1), (3, 2, 2), (4, 3, 3), (5, 3, 3)];
    for n in 2..=16 {
        let row = puzzle(n);
        let (first, second) = match measured_below_6.iter().find(|(m, _, _)| *m == n) {
            Some(&(_, a, b)) => (a, b),
            None => predicted_puzzle(n),
        };
        assert_eq!(row.k_matching_scale_1, Some(first), "n = {n}, scale 1");
        assert_eq!(
            row.k_matching_scale_down,
            Some(second),
            "n = {n}, scale 2^-20"
        );
    }
    for (n, a, b) in measured_below_6 {
        assert_ne!(
            (a, b),
            predicted_puzzle(n),
            "n = {n} is recorded as refuted"
        );
    }
    for n in 2..=16 {
        assert_eq!(puzzle(n).predicted_k_also_matches, (true, true), "n = {n}");
    }
}

#[test]
fn m6_p5_an_absolute_rank_tolerance_sees_nothing_in_1e_12_i3() {
    assert_eq!(rank_conventions(), (0, 3));
}

#[test]
fn m6_p6_the_rank_1_error_is_0_054_against_the_test_bound_0_10() {
    let e = rank_1_relative_error();
    assert!((0.0535..0.0545).contains(&e), "{e}");
}

#[test]
fn controls_every_check_can_fail() {
    let a = matrix_a();
    let s = ix_math::svd::svd(&a).expect("svd").singular_values.to_vec();
    assert!((tail(&s, 0) - tail(&s[..1], 0)).abs() > 1e-9 * frobenius(&a));
    assert_eq!(frobenius_diff(&a, &a) / frobenius(&a), 0.0);
    assert_eq!(
        frobenius_diff(&Array2::zeros((3, 2)), &a) / frobenius(&a),
        1.0
    );
    assert!((2..=16).any(|n| !puzzle(n).scale_1_equals_scale_down));
    assert_eq!(two_to(-20) * two_to(20), 1.0);
    assert_eq!(ten_to(-12), 1e-12);
}
