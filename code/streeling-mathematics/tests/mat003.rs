//! Each pre-registered MAT-003 claim (preregistration.md, P0 to P7) as an assertion with an explicit bound.
//! These tests are the numerical oracle; the rounded table printed by the example is only for reading.

use ndarray::{Array2, array};
use streeling_mathematics::*;

fn sizes() -> std::ops::RangeInclusive<usize> {
    2..=16
}

#[test]
fn p0_the_exact_inverse_is_exact_and_the_check_can_fail() {
    for n in 1..=10 {
        assert_eq!(
            exact_identity_holds(&exact_hilbert_inverse(n)),
            Some(true),
            "n = {n}"
        );
    }
    assert_eq!(
        exact_hilbert_inverse(3),
        vec![vec![9, -36, 30], vec![-36, 192, -180], vec![30, -180, 180]]
    );
    assert_eq!(kappa_inf_exact(3).round(), 748.0);
    let mut wrong = exact_hilbert_inverse(4);
    wrong[1][2] = -wrong[1][2];
    assert_eq!(exact_identity_holds(&wrong), Some(false));
}

// P1 was pre-registered as "the band holds up to n = 11". Refuted on the first run: IX's kappa_2 leaves the
// band at n = 10, far below 1/u, and stays near 1e12 while the true value keeps growing. The test now pins
// what was measured, still judged by the theorem's band and not by a snapshot.
#[test]
fn p1_kappa_2_lies_in_the_theorem_band_up_to_9_and_ix_underestimates_it_from_10() {
    for n in 2..=9 {
        let m = measure(n, 1.0);
        assert!(
            m.band_holds(),
            "n = {n}: kappa_inf/n = {:e}, kappa_2 = {:e}, kappa_inf = {:e}",
            m.kappa_inf / n as f64,
            m.kappa2,
            m.kappa_inf
        );
    }
    for n in 10..=16 {
        let m = measure(n, 1.0);
        assert!(
            m.kappa2 < m.kappa_inf / n as f64,
            "n = {n}: kappa_2 = {:e} is no longer below the lower bound {:e}",
            m.kappa2,
            m.kappa_inf / n as f64
        );
    }
    let k3 = measure(3, 1.0).kappa2;
    assert!(
        (k3 - 524.056_777_586_064_4).abs() <= 1e-9 * 524.06,
        "kappa_2(H_3) = {k3}"
    );
}

#[test]
fn p2_every_accepted_inverse_is_within_n_kappa_u() {
    for n in sizes() {
        let m = measure(n, 1.0);
        if let Some(e) = m.forward_error {
            let bound = n as f64 * m.kappa_inf * U;
            assert!(
                e <= bound,
                "n = {n}: forward error {e:e} > n kappa u = {bound:e}"
            );
        }
    }
}

#[test]
fn p3_inverse_first_refuses_hilbert_between_10_and_12() {
    let first = sizes()
        .find(|&n| ix_inverse(&hilbert(n)).is_none())
        .expect("a refusal up to n = 16");
    assert!((10..=12).contains(&first), "first Singular at n = {first}");
}

#[test]
fn p4_the_refusal_measures_scale_not_conditioning() {
    assert!(
        ix_inverse(&(Array2::<f64>::eye(3) * 2f64.powi(-40))).is_none(),
        "kappa = 1, refused"
    );
    assert_eq!(
        ix_inverse(&(Array2::<f64>::eye(3) * 2f64.powi(-39))),
        Some(Array2::<f64>::eye(3) * 2f64.powi(39))
    );
    let small = sizes().find(|&n| ix_inverse(&hilbert(n).mapv(|x| x * 2f64.powi(-20))).is_none());
    assert!(
        matches!(small, Some(5..=7)),
        "2^-20 H: first Singular at {small:?}"
    );
    let large: Vec<Measurement> = sizes().map(|n| measure(n, 2f64.powi(20))).collect();
    let first = large
        .iter()
        .find(|m| m.inverse.is_none())
        .map_or(17, |m| m.n);
    assert!(first > 11, "2^20 H: first Singular at n = {first}");
    assert!(
        large
            .iter()
            .any(|m| m.forward_error.is_some_and(|e| e > 1.0)),
        "predicted: an accepted inverse with no correct digit"
    );
}

// P5 had two halves. The inverse half held: scaling by 2^k is bit-exact through `inverse`. The svd half, a
// hypothesis from reading svd.rs, was refuted: kappa_2 changes with the scale, and at n = 10 only 2^20 H
// puts it back inside the theorem's band.
#[test]
fn p5_scaling_is_bit_exact_through_inverse_but_changes_the_svd_answer() {
    for k in [-20, 20] {
        let s = 2f64.powi(k);
        for n in sizes() {
            let (m1, ms) = (measure(n, 1.0), measure(n, s));
            if let (Some(x1), Some(xs)) = (&m1.inverse, &ms.inverse) {
                assert!(
                    x1.iter()
                        .zip(xs.iter())
                        .all(|(a, b)| (a / s).to_bits() == b.to_bits()),
                    "n = {n}, k = {k}"
                );
            }
        }
    }
    let (plain, up, down) = (
        measure(10, 1.0),
        measure(10, 2f64.powi(20)),
        measure(10, 2f64.powi(-20)),
    );
    assert!(!plain.band_holds() && up.band_holds() && !down.band_holds());
    assert!(down.kappa2 < plain.kappa2 && plain.kappa2 < up.kappa2);
}

#[test]
fn p6_the_mcp_tolerance_turns_the_pseudo_inverse_into_a_bounded_projector() {
    let first = sizes()
        .find(|&n| measure(n, 1.0).rank_mcp < n)
        .expect("rank drops up to 16");
    assert!(
        (7..=9).contains(&first),
        "rank(sigma_1 * 1e-10) first < n at n = {first}"
    );
    for n in sizes() {
        let m = measure(n, 1.0);
        // ||P||_inf <= sqrt(n) ||P||_2 and ||P||_2 = 1/sigma_r <= 1/tol.
        assert!(
            norm_inf(&m.pinv_mcp) <= (n as f64).sqrt() / m.mcp_tol,
            "n = {n}"
        );
        if m.rank_mcp == n {
            assert!(
                m.pinv_mcp_residual <= n as f64 * m.kappa_inf * U,
                "n = {n}: full rank, residual {:e}",
                m.pinv_mcp_residual
            );
        } else {
            assert!(
                m.pinv_mcp_residual >= 0.5,
                "n = {n}: truncated, residual {:e}",
                m.pinv_mcp_residual
            );
        }
    }
}

#[test]
fn p7_the_residual_check_rejects_a_wrong_inverse() {
    assert!(residual(&hilbert(3), &Array2::eye(3)) >= 1.0);
    assert!(residual(&hilbert(3), &exact_inverse_f64(3, 1.0)) < 1e-12);
    assert!(ix_inverse(&array![[1.0, 2.0], [2.0, 4.0]]).is_none());
}
