//! Each pre-registered MAT-004 claim (preregistration-mat004.md) as an assertion: M4-P1 to M4-P7 are the
//! module's, quoted from its section 7, its section 6 exercise and two section 6 readings; M4-L1 is the lab's
//! own, written before the run. Step 5's timing (M4-P5a) is not asserted here.

use ix_math::distance::{chebyshev, minkowski};
use ndarray::array;
use streeling_mathematics::mat004::*;

#[test]
fn m4_p1_no_triangle_violation_above_1e_12_on_the_grid() {
    let points = grid();
    assert_eq!(points.len(), 25);
    for (name, d) in distances() {
        let (worst, _, count) = triangle(d, &points);
        assert_eq!(count, 15_625, "{name}");
        assert!(worst <= 1e-12, "{name}: {worst:e}");
    }
}

#[test]
fn m4_p2_p_one_half_is_refused_with_the_documented_message() {
    let results = half_p_results();
    assert_eq!(results.len(), 3);
    for r in &results {
        assert!(is_p_refusal(r), "{r:?}");
    }
}

#[test]
fn m4_p3_p_infinity_returns_1_where_chebyshev_returns_0_and_4() {
    let (o, t) = (origin(), three_four());
    assert_eq!(minkowski(&o, &o, f64::INFINITY).unwrap(), 1.0);
    assert_eq!(minkowski(&o, &t, f64::INFINITY).unwrap(), 1.0);
    assert_eq!(chebyshev(&o, &o).unwrap(), 0.0);
    assert_eq!(chebyshev(&o, &t).unwrap(), 4.0);
}

#[test]
fn m4_p4_p_1000_overflows_to_infinity() {
    assert_eq!(
        minkowski(&origin(), &three_four(), 1000.0).unwrap(),
        f64::INFINITY
    );
}

#[test]
fn m4_p5b_the_product_rule_holds_exactly_on_1000_pairs() {
    let pairs = product_rule_pairs();
    assert_eq!(pairs.len(), 1000);
    for (i, p) in pairs.iter().enumerate() {
        assert_eq!(p.det_ab, p.det_a * p.det_b, "pair {i}");
    }
}

#[test]
fn m4_p6_cosine_distance_breaks_the_triangle_inequality() {
    let (direct, around) = cosine_triangle();
    assert!((direct - 1.0).abs() <= 1e-12, "{direct}");
    assert!((around - (2.0 - 2f64.sqrt())).abs() <= 1e-12, "{around}");
    assert!(direct > around);
}

#[test]
fn m4_p7_p_nan_passes_the_guard_and_returns_nan() {
    let (o, t) = (origin(), three_four());
    assert!(minkowski(&o, &t, f64::NAN).unwrap().is_nan());
    assert!(minkowski(&o, &o, f64::NAN).unwrap().is_nan());
}

#[test]
fn m4_l1_p_nan_returns_1_between_0_and_1_in_one_dimension() {
    assert_eq!(
        minkowski(&array![0.0], &array![1.0], f64::NAN).unwrap(),
        1.0
    );
}

#[test]
fn controls_every_check_can_fail() {
    let [x, y, z] = exercise_points();
    let (worst, positive, _) = triangle(half_distance, &[x, y, z]);
    assert!(worst > 1e-12 && positive > 0, "{worst}");
    assert_eq!(worst, 2.0);

    let pairs = product_rule_pairs();
    assert!(pairs.iter().any(|p| p.det_ab != p.det_a + p.det_b));

    assert!(f64::NAN.is_nan());
    assert!(!1.0f64.is_nan() && !f64::INFINITY.is_nan());
    assert!(!is_p_refusal(&Ok(1.0)));
}
