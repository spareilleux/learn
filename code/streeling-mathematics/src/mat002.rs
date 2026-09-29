//! MAT-002, counterexamples and exhaustive checks: IX's D12 product checked for associativity over all 13,824
//! triples, IX's two D12 tests restated as checks of any product rule and run on known faults, and IX's Petri-net
//! analyser replaying a deadlock witness. Pre-registered in preregistration-mat002.md.

use ix_bracelet::{Action, DihedralElement, Group, PcSet};
use ix_petri::{Limits, PetriNet, Verdict, analyze};
use std::collections::BTreeSet;

pub type Element = DihedralElement;

/// A product rule on D12.
pub type Rule = fn(&Element, &Element) -> Element;

/// (i, a): the rotation i and the reflection flag a = 1.
pub fn el(i: u8, a: u8) -> Element {
    DihedralElement {
        rotation: i,
        reflected: a == 1,
    }
}

/// "(i, a)", as the module writes it.
pub fn show(g: &Element) -> String {
    format!("({}, {})", g.rotation, u8::from(g.reflected))
}

/// The 24 elements in the order of IX's tests: a = 0 first, then a = 1, each with i from 0 to 11.
pub fn elements() -> Vec<Element> {
    (0..2)
        .flat_map(|a| (0..12).map(move |i| el(i, a)))
        .collect()
}

fn sigma(reflected: bool) -> i16 {
    if reflected { -1 } else { 1 }
}

fn make(rotation: i16, reflected: bool) -> Element {
    DihedralElement {
        rotation: rotation.rem_euclid(12) as u8,
        reflected,
    }
}

/// IX's `compose`.
pub fn rule_ix(g: &Element, h: &Element) -> Element {
    g.compose(h)
}

/// Rule S, the section 4 exercise: the sign comes from the second factor.
pub fn rule_s(g: &Element, h: &Element) -> Element {
    make(
        g.rotation as i16 + sigma(h.reflected) * h.rotation as i16,
        g.reflected ^ h.reflected,
    )
}

/// Rule F, the section 6 exercise: IX's `compose`, except (1, 1) . (2, 1) = (5, 0).
pub fn rule_f(g: &Element, h: &Element) -> Element {
    if *g == el(1, 1) && *h == el(2, 1) {
        el(5, 0)
    } else {
        g.compose(h)
    }
}

/// Rule Z, the section 4 reading: no sign flip, Z12 x Z2.
pub fn rule_z(g: &Element, h: &Element) -> Element {
    make(
        g.rotation as i16 + h.rotation as i16,
        g.reflected ^ h.reflected,
    )
}

/// The control rule (i - k mod 12, a xor b), whose associativity failures are known in closed form.
pub fn rule_minus(g: &Element, h: &Element) -> Element {
    make(
        g.rotation as i16 - h.rotation as i16,
        g.reflected ^ h.reflected,
    )
}

/// The control rule that returns the identity for every product.
pub fn rule_identity(_: &Element, _: &Element) -> Element {
    DihedralElement::identity()
}

/// Every triple (g, h, f) with (g . h) . f != g . (h . f), in the order of the elements.
pub fn associativity_failures(rule: Rule) -> Vec<(Element, Element, Element)> {
    let e = elements();
    let mut out = Vec::new();
    for g in &e {
        for h in &e {
            for f in &e {
                if rule(&rule(g, h), f) != rule(g, &rule(h, f)) {
                    out.push((*g, *h, *f));
                }
            }
        }
    }
    out
}

/// The first assertion of check A that fails.
#[derive(Debug, Clone, PartialEq)]
pub struct Failure {
    pub assertion: &'static str,
    pub g: Option<Element>,
    pub got: Option<Element>,
}

/// Check A, `group_law_exhaustive_closure_and_inverse` restated for any rule, with IX's `inverse`, in the
/// order of the test. `None` when every assertion holds.
pub fn check_a(rule: Rule) -> Option<Failure> {
    let e = elements();
    let id = DihedralElement::identity();
    let fail = |assertion, g: &Element, got| {
        Some(Failure {
            assertion,
            g: Some(*g),
            got: Some(got),
        })
    };
    for g in &e {
        let inv = g.inverse();
        for (assertion, got, want) in [
            ("g . g^-1 = e", rule(g, &inv), id),
            ("g^-1 . g = e", rule(&inv, g), id),
            ("e . g = g", rule(&id, g), *g),
            ("g . e = g", rule(g, &id), *g),
        ] {
            if got != want {
                return fail(assertion, g, got);
            }
        }
        for h in &e {
            let gh = rule(g, h);
            if gh.rotation >= 12 {
                return fail("rotation of g . h below 12", g, gh);
            }
        }
    }
    let products: BTreeSet<(u8, bool)> = e
        .iter()
        .flat_map(|g| e.iter().map(move |h| rule(g, h)))
        .map(|p| (p.rotation, p.reflected))
        .collect();
    if products.len() != 24 {
        return Some(Failure {
            assertion: "the 576 products include all 24 elements",
            g: None,
            got: None,
        });
    }
    None
}

/// The nine sample sets of IX's `action.rs:70`, in its order.
pub fn sample_sets() -> Vec<PcSet> {
    vec![
        PcSet::empty(),
        PcSet::chromatic(),
        PcSet::from_pcs([0, 4, 7]),
        PcSet::from_pcs([0, 3, 7]),
        PcSet::from_pcs([0, 2, 4, 5, 7, 9, 11]),
        PcSet::from_pcs([0, 1, 4, 6]),
        PcSet::from_pcs([0, 2, 4, 6, 8, 10]),
        PcSet::from_pcs([0]),
        PcSet::from_pcs([0, 6]),
    ]
}

/// "{0, 4, 7}".
pub fn show_set(x: &PcSet) -> String {
    let pcs: Vec<String> = x.iter_pcs().map(|p| p.to_string()).collect();
    format!("{{{}}}", pcs.join(", "))
}

/// Check B, `action_composition_matches_group_composition` restated for any rule, with IX's `apply`: every
/// (g, h, index of the sample set) where (g . h).apply(x) != g.apply(h.apply(x)).
pub fn check_b_failures(rule: Rule) -> Vec<(Element, Element, usize)> {
    let e = elements();
    let xs = sample_sets();
    let mut out = Vec::new();
    for g in &e {
        for h in &e {
            let gh = rule(g, h);
            for (k, x) in xs.iter().enumerate() {
                if gh.apply(*x) != g.apply(h.apply(*x)) {
                    out.push((*g, *h, k));
                }
            }
        }
    }
    out
}

/// A set transposed by i, by hand, without IX's `apply`.
pub fn transpose(pcs: &[u8], i: u8) -> PcSet {
    PcSet::from_pcs(pcs.iter().map(|p| (p + i) % 12))
}

/// M2-P5: the 24 images of {0, 4, 7} under IX's `apply`, in the order of the elements.
pub fn triad_images() -> Vec<PcSet> {
    let c_major = PcSet::from_pcs([0, 4, 7]);
    elements().iter().map(|g| g.apply(c_major)).collect()
}

/// The net of IX's `witness_sequences_are_shortest_and_replayable`, with the same builder calls in the same
/// order.
pub fn witness_net() -> PetriNet {
    PetriNet::builder()
        .place("start", 1)
        .place("mid", 0)
        .place("end", 0)
        .transition("a_short")
        .transition("b_long")
        .arc("start", "a_short")
        .arc("a_short", "end")
        .arc("start", "b_long")
        .arc("b_long", "mid")
        .arc("mid", "b_long_2")
        .transition("b_long_2")
        .arc("b_long_2", "end")
        .build()
        .expect("the net of IX's test")
}

/// What step 4 observed.
pub struct Replay {
    /// Whether deadlock freedom is `Fails`.
    pub fails: bool,
    pub witness: Vec<String>,
    pub reported: String,
    pub replayed: String,
}

/// Step 4: `analyze` with the default limits, then the first reported witness replayed with `fire`.
pub fn replay_witness() -> Replay {
    let net = witness_net();
    let a = analyze(&net, Limits::default());
    let Verdict::Fails(deadlocks) = &a.deadlock_free else {
        return Replay {
            fails: false,
            witness: Vec::new(),
            reported: String::new(),
            replayed: String::new(),
        };
    };
    let d = &deadlocks[0];
    let mut m = net.initial_marking().clone();
    for id in &d.witness {
        let t = net.transition_index(id).expect("a transition of the net");
        m = net.fire(&m, t).expect("an enabled transition");
    }
    Replay {
        fails: true,
        witness: d.witness.clone(),
        reported: d.marking.clone(),
        replayed: net.describe_marking(&m),
    }
}
