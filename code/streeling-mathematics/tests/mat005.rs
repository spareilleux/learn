//! Each pre-registered MAT-005 claim (preregistration-mat005.md) as an assertion: M5-P1 to M5-P5 are the
//! module's, quoted from its section 8, its section 7 and 8 exercises and one section 7 reading; M5-L1 is the
//! lab's own, written before the run. The bands were set before the run.

use ndarray::Array2;
use std::f64::consts::FRAC_1_SQRT_2;
use streeling_mathematics::mat005::*;
use streeling_mathematics::max_or_nan;

const ONE_OVER_ROOT_2: [f64; 2] = [FRAC_1_SQRT_2, FRAC_1_SQRT_2];

#[test]
fn m5_p1_the_invariants_hold_within_1e_9_with_the_predicted_eigenvalues() {
    for row in invariants() {
        assert!(
            row.residual <= 1e-9,
            "{}: A v - lambda v {:e}",
            row.name,
            row.residual
        );
        assert!(
            row.orthonormality <= 1e-9,
            "{}: V^T V - I {:e}",
            row.name,
            row.orthonormality
        );
        assert!(
            row.reconstruction <= 1e-9,
            "{}: V Lambda V^T - A {:e}",
            row.name,
            row.reconstruction
        );
        if let Some(predicted) = &row.predicted {
            assert_eq!(row.values.len(), predicted.len(), "{}", row.name);
            for (v, p) in row.values.iter().zip(predicted) {
                assert!((v - p).abs() <= 1e-9, "{}: {:?}", row.name, row.values);
            }
        }
    }
    assert!(invariants().iter().any(|r| r.predicted.is_none()));
}

#[test]
fn m5_p2_the_eigenspace_of_1_is_i_minus_j_over_3() {
    let (columns, err) = eigenspace();
    assert_eq!(columns.len(), 2, "{columns:?}");
    assert!(err <= 1e-9, "{err:e}");
}

#[test]
fn m5_p3a_an_asymmetric_input_gives_exactly_5_and_0_without_error() {
    let e = eigen(&matrix_n());
    assert_eq!(e.values, vec![5.0, 0.0]);
}

#[test]
fn m5_p3b_the_vector_for_5_is_1_2_over_root_5_and_misses_by_1_over_root_5() {
    let n = matrix_n();
    let e = eigen(&n);
    let v = e.vectors.column(0).to_vec();
    let expected = [1.0 / 5f64.sqrt(), 2.0 / 5f64.sqrt()];
    assert!(distance_up_to_sign(&v, &expected) <= 1e-12, "{v:?}");
    let r = residual_norm(&n, &e, 0);
    assert!((r - 1.0 / 5f64.sqrt()).abs() <= 1e-12, "{r}");
}

#[test]
fn m5_p4a_both_pca_components_are_1_1_over_root_2() {
    let p = pca();
    for i in 0..2 {
        let c = p.components.row(i).to_vec();
        assert!(
            distance_up_to_sign(&c, &ONE_OVER_ROOT_2) <= 1e-12,
            "component {i}: {c:?}"
        );
    }
}

#[test]
fn m5_p4b_the_variances_are_2_5_and_0() {
    let v = pca().variances;
    assert!((v[0] - 0.4).abs() <= 1e-9, "{v:?}");
    assert!((0.0..=1e-9).contains(&v[1]), "{v:?}");
}

#[test]
fn m5_p4c_the_explained_variance_ratio_is_1_and_0() {
    let r = pca().ratios;
    assert!((r[0] - 1.0).abs() <= 1e-9, "{r:?}");
    assert!(r[1].abs() <= 1e-9, "{r:?}");
}

#[test]
fn m5_p4d_symmetric_eigen_of_the_same_covariance_gives_6_5_and_2_5() {
    let v = eigen(&covariance()).values;
    assert!((v[0] - 1.2).abs() <= 1e-9, "{v:?}");
    assert!((v[1] - 0.4).abs() <= 1e-9, "{v:?}");
}

#[test]
fn m5_p4e_three_quarters_of_the_variance_is_unaccounted_for() {
    let share = unaccounted_share(&pca().variances);
    assert!((share - 0.75).abs() <= 1e-9, "{share}");
}

#[test]
fn m5_p5_the_identity_test_rotates_nothing_and_i_plus_j_does() {
    assert!(same_bits(&eigen(&Array2::eye(4)).vectors, &Array2::eye(4)));
    assert!(!same_bits(
        &eigen(&identity_plus_ones(4)).vectors,
        &Array2::eye(4)
    ));
}

#[test]
fn m5_l1a_below_1e_12_the_solver_returns_the_diagonal_unrotated() {
    for e in exponents().filter(|e| *e <= -13) {
        let row = scale_row(e);
        assert!(row.returned_diagonal, "e = {e}");
        assert!(
            row.relative_errors[1] >= 1.0 - 1e-12,
            "e = {e}: {:?}",
            row.relative_errors
        );
    }
}

#[test]
fn m5_l1b_from_1e_12_up_the_eigenvalues_scale_with_s() {
    for e in exponents().filter(|e| *e >= -12) {
        let row = scale_row(e);
        for err in &row.relative_errors {
            assert!(*err <= 1e-12, "e = {e}: {:?}", row.relative_errors);
        }
    }
}

#[test]
fn m5_l1c_the_absolute_1e_9_check_passes_on_the_wrong_answer() {
    let row = scale_row(-13);
    assert!(row.returned_diagonal);
    assert!(row.max_residual <= 1e-9, "{:e}", row.max_residual);
}

#[test]
fn controls_every_check_can_fail() {
    let b = matrix_b();
    let good = eigen(&b);
    let swapped = Eigen {
        values: good.values.iter().rev().copied().collect(),
        vectors: good.vectors.clone(),
    };
    assert!(max_eigen_residual(&b, &swapped) > 1e-9);
    // A NaN eigenpair must fail every check, not vanish in the reduction.
    let nan = Eigen {
        values: vec![f64::NAN, 1.0],
        vectors: good.vectors.clone(),
    };
    assert!(max_eigen_residual(&b, &nan).is_nan());
    assert!(max_reconstruction_error(&b, &nan).is_nan());
    assert!(max_orthonormality_error(&Array2::from_elem((2, 2), f64::NAN)).is_nan());
    assert!(distance_up_to_sign(&[f64::NAN, 0.0], &ONE_OVER_ROOT_2).is_nan());

    let ipj = eigen(&identity_plus_ones(3));
    let wrong = projector_from(&ipj.vectors, &[0, 1]);
    let err = wrong
        .iter()
        .zip(eigenspace_projector().iter())
        .map(|(x, y)| (x - y).abs())
        .fold(0.0, max_or_nan);
    assert!(err > 1e-9);

    assert!(distance_up_to_sign(&ONE_OVER_ROOT_2, &[FRAC_1_SQRT_2, -FRAC_1_SQRT_2]) > 0.5);
    assert!(!same_bits(
        &Array2::eye(4),
        &eigen(&identity_plus_ones(4)).vectors
    ));
}
