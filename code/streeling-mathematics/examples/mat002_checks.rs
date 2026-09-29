//! MAT-002: associativity of IX's D12 product over all triples, IX's two D12 tests restated as checks of any
//! product rule, and IX's Petri-net analyser replaying a witness. The printed values are for reading;
//! tests/mat002.rs checks each pre-registered claim.

use ix_bracelet::Group;
use streeling_mathematics::mat002::*;

fn triple(t: &(Element, Element, Element)) -> String {
    format!("({}, {}, {})", show(&t.0), show(&t.1), show(&t.2))
}

fn check_a_text(rule: Rule) -> String {
    match check_a(rule) {
        None => "passes".to_string(),
        Some(f) => format!(
            "fails first at \"{}\"{}{}",
            f.assertion,
            f.g.map_or(String::new(), |g| format!(" for g = {}", show(&g))),
            f.got
                .map_or(String::new(), |p| format!(", got {}", show(&p)))
        ),
    }
}

fn main() {
    let rules: [(&str, Rule); 4] = [
        ("IX compose", rule_ix),
        ("rule S (section 4 exercise)", rule_s),
        ("rule F (section 6 exercise)", rule_f),
        ("rule Z (no sign flip)", rule_z),
    ];
    println!("MAT-002: ix-bracelet D12 and ix-petri at e35138b9");

    println!();
    println!(
        "Steps 1 and 2: associativity over the 13,824 triples, count of failures and the first one"
    );
    for (name, rule) in rules {
        let failures = associativity_failures(rule);
        println!(
            "  {name:<28} | {:>5} failures | first {}",
            failures.len(),
            failures.first().map_or("none".to_string(), triple)
        );
    }
    let s_hand = (el(0, 0), el(1, 0), el(0, 1));
    let f_hand = (el(1, 0), el(0, 1), el(2, 1));
    println!(
        "  hand-found triples among the failures: rule S {} {}, rule F {} {}",
        triple(&s_hand),
        associativity_failures(rule_s).contains(&s_hand),
        triple(&f_hand),
        associativity_failures(rule_f).contains(&f_hand)
    );

    println!();
    println!(
        "Step 3: IX's two tests restated as checks A (group law) and B (action), on each rule"
    );
    let xs = sample_sets();
    for (name, rule) in rules {
        let b = check_b_failures(rule);
        println!(
            "  {name:<28} | A {} | B {} failing (pair, set) of 5184",
            check_a_text(rule),
            b.len()
        );
    }
    println!("  rule F, every failing (pair, set) of check B:");
    for (g, h, k) in check_b_failures(rule_f) {
        println!("    {} . {} on {}", show(&g), show(&h), show_set(&xs[k]));
    }

    println!();
    let r = replay_witness();
    println!(
        "Step 4: deadlock freedom Fails: {}; witness {:?}; reported {:?}; replayed {:?}",
        r.fails, r.witness, r.reported, r.replayed
    );

    println!();
    let images = triad_images();
    let distinct: std::collections::BTreeSet<u16> = images.iter().map(|x| x.raw()).collect();
    println!(
        "Section 6: {{0, 4, 7}} under the 24 elements: {} distinct sets",
        distinct.len()
    );
    for (g, x) in elements().iter().zip(&images) {
        println!("  {} -> {}", show(g), show_set(x));
    }

    println!();
    let (s, r1) = (el(0, 1), el(1, 0));
    println!(
        "Section 4: (s . r) . s = {} under rule Z, {} under IX compose; r^-1 = {}",
        show(&rule_z(&rule_z(&s, &r1), &s)),
        show(&rule_ix(&rule_ix(&s, &r1), &s)),
        show(&r1.inverse())
    );

    println!();
    println!("Negative controls:");
    println!(
        "  rule (i - k, a xor b): {} associativity failures (11,520 predicted)",
        associativity_failures(rule_minus).len()
    );
    println!(
        "  rule returning the identity: check A {}",
        check_a_text(rule_identity)
    );
}
