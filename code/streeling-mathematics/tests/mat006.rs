//! Each pre-registered MAT-006 claim (preregistration-mat006.md, M6-P1 to M6-P6) as an assertion.
//! The claims are quoted from section 7 and the section 6 exercise of the module; the bands were set
//! before the run. Step 3 (timings) is not asserted here.

use ndarray::Array2;
use streeling_mathematics::mat006::*;
use streeling_mathematics::max_or_nan;

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
            .fold(0.0, max_or_nan);
        if e >= -10 {
            assert!(worst <= 1e-12, "e = {e}: {worst:e}");
        } else if e <= -13 {
            assert!(worst > 1.0, "e = {e}: worst relative error {worst:e}");
        }
    }
}

// M6-P4, as pre-registered: for each n, the smallest k in 1 ... 6 whose capped singular values (divided
// by 2^20) equal those at scale 1 bit for bit is the module's first value, and the smallest equal to those
// at 2^-20 (divided by 2^-20) is its second; if no k up to 6 matches, the prediction is refuted for that n.
// Partly refuted on the first run: some k <= 6 matches both for every n, and the smallest is the predicted
// pair for n = 6 to 16, but lower for n = 2 to 5 (1 and 1, 2 and 2, 3 and 3, 3 and 3). The test judges that
// criterion for every n and keeps the verdict visible. The measured k, and the post hoc observation that the
// predicted k also matches, are printed in expected/mat006_svd.txt and are not asserted here.
#[test]
fn m6_p4_capped_sweeps_reproduce_both_results_and_the_first_k_is_as_predicted_from_n_6() {
    for n in 2..=16 {
        let row = puzzle(n);
        assert!(
            row.k_matching_scale_1.is_some() && row.k_matching_scale_down.is_some(),
            "n = {n}: no k up to 6 matches"
        );
        let (first, second) = predicted_puzzle(n);
        let holds =
            row.k_matching_scale_1 == Some(first) && row.k_matching_scale_down == Some(second);
        assert_eq!(
            holds,
            n >= 6,
            "n = {n}: the prediction holds only from n = 6"
        );
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
    // A NaN relative error must reach the P2d bounds, where both comparisons fail, not vanish in the fold.
    assert!(
        [1e-16, f64::NAN]
            .iter()
            .copied()
            .fold(0.0, max_or_nan)
            .is_nan()
    );
}
