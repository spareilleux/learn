//! Each pre-registered MAT-002 claim (preregistration-mat002.md) as an assertion: M2-P1 to M2-P6 are the
//! module's, quoted from its section 7 and two readings in sections 4 and 6; M2-L1 is the lab's own, derived by
//! hand before the run.

use ix_bracelet::{Group, PcSet};
use std::collections::BTreeSet;
use streeling_mathematics::mat002::*;

#[test]
fn m2_p1_ix_compose_is_associative_on_all_13824_triples() {
    assert_eq!(elements().len(), 24);
    assert_eq!(associativity_failures(rule_ix), vec![]);
}

#[test]
fn m2_p2_both_faults_fail_including_the_hand_found_triples() {
    let s = associativity_failures(rule_s);
    assert!(!s.is_empty());
    assert!(s.contains(&(el(0, 0), el(1, 0), el(0, 1))));
    let f = associativity_failures(rule_f);
    assert!(!f.is_empty());
    assert!(f.contains(&(el(1, 0), el(0, 1), el(2, 1))));
}

#[test]
fn m2_p3_what_ix_tests_detect() {
    assert_eq!(check_a(rule_ix), None);
    assert!(check_b_failures(rule_ix).is_empty());

    assert_eq!(check_a(rule_f), None);
    assert!(!check_b_failures(rule_f).is_empty());

    assert_eq!(
        check_a(rule_s),
        Some(Failure {
            assertion: "e . g = g",
            g: Some(el(1, 1)),
            got: Some(el(11, 1)),
        })
    );
    assert!(!check_b_failures(rule_s).is_empty());
}

#[test]
fn m2_p4_the_witness_is_a_short_and_replays_to_the_reported_marking() {
    let r = replay_witness();
    assert!(r.fails);
    assert_eq!(r.witness, vec!["a_short".to_string()]);
    assert_eq!(r.replayed, r.reported);
}

#[test]
fn m2_p5_the_c_major_triad_has_24_distinct_images() {
    let images = triad_images();
    let distinct: BTreeSet<u16> = images.iter().map(|x| x.raw()).collect();
    assert_eq!(distinct.len(), 24);
    // As pre-registered, the 12 images by a = 0 and by a = 1 are compared as sets with the 12 transpositions.
    // The first version of this test paired image i with transposition i, which the pre-registration does not
    // say: (0, 1) sends {0, 4, 7} to {0, 5, 8}, the minor triad transposed by 5 (README, MAT-002).
    let raw = |v: &[PcSet]| v.iter().map(|x| x.raw()).collect::<BTreeSet<u16>>();
    let majors: Vec<PcSet> = (0..12).map(|i| transpose(&[0, 4, 7], i)).collect();
    let minors: Vec<PcSet> = (0..12).map(|i| transpose(&[0, 3, 7], i)).collect();
    assert_eq!(raw(&images[..12]), raw(&majors));
    assert_eq!(raw(&images[12..]), raw(&minors));
}

#[test]
fn m2_p6_no_sign_flip_is_associative_but_breaks_srs() {
    assert_eq!(associativity_failures(rule_z), vec![]);
    let (s, r) = (el(0, 1), el(1, 0));
    assert_eq!(rule_z(&rule_z(&s, &r), &s), el(1, 0));
    assert_eq!(rule_ix(&rule_ix(&s, &r), &s), el(11, 0));
    assert_eq!(r.inverse(), el(11, 0));
}

#[test]
fn m2_l1_check_b_sees_the_one_entry_fault_on_exactly_five_sets() {
    let xs = sample_sets();
    let failing: Vec<(Element, Element, PcSet)> = check_b_failures(rule_f)
        .into_iter()
        .map(|(g, h, k)| (g, h, xs[k]))
        .collect();
    let expected: Vec<(Element, Element, PcSet)> = [
        PcSet::from_pcs([0, 4, 7]),
        PcSet::from_pcs([0, 3, 7]),
        PcSet::from_pcs([0, 2, 4, 5, 7, 9, 11]),
        PcSet::from_pcs([0, 1, 4, 6]),
        PcSet::from_pcs([0]),
    ]
    .into_iter()
    .map(|x| (el(1, 1), el(2, 1), x))
    .collect();
    assert_eq!(failing, expected);
}

#[test]
fn controls_every_check_can_fail() {
    assert_eq!(associativity_failures(rule_minus).len(), 11_520);
    assert!(check_a(rule_identity).is_some());
}
