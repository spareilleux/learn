//! Lesson 18: IX's `ix-adversarial` — FGSM, PGD, Carlini–Wagner and universal perturbations against a fixed
//! linear model, detection by noise, feature squeezing, the certified radius, and the poisoning defences.

use machine_learning_ix::adversarial::{
    DIM, EPSILONS, FORMULA, PER_CLASS, cw_run, detection, fgsm_run, jsma_ignores_its_target,
    label_flips, lipschitz_runs, margin, pgd_against_fgsm, radius, sparse, spectral, squeeze,
    squeeze_zero_bits, test_set, universal_run, weights, zero_gradient,
};

fn yes(b: bool) -> &'static str {
    if b { "yes" } else { "no" }
}

fn main() {
    let points = test_set();
    let w = weights();
    let clean = points
        .iter()
        .filter(|p| margin(&w, p.y, &p.x) > 0.0)
        .count();
    println!("== the model under attack");
    println!(
        "{} test points, {PER_CLASS} per class, in {DIM} dimensions; w = mu = 0.2 everywhere, |w|_2 = {:.3}, |w|_1 = {:.3}",
        points.len(),
        w.dot(&w).sqrt(),
        w.sum()
    );
    println!(
        "clean accuracy {:.4}   (Phi(2) = 0.9772)",
        clean as f64 / points.len() as f64
    );

    println!("\n== P1, FGSM: every margin falls by eps |w|_1 = 20 eps");
    println!(
        "  eps   accuracy   Phi(2 - 10 eps)   changed class   exactly those with 0 < m < 20 eps   margins within 1e-12"
    );
    for (eps, formula) in EPSILONS.iter().zip(FORMULA) {
        let run = fgsm_run(&points, *eps);
        println!(
            "  {:.1}   {:.4}     {formula:.4}            {:>4}            {:<3}                                 {}",
            run.epsilon,
            run.accuracy,
            run.changed,
            yes(run.changed_as_predicted),
            yes(run.margin_error < 1e-12)
        );
    }

    println!(
        "\n== P2, PGD and f64::signum (eps 0.2, alpha 0.05, 10 steps), largest distance from the expected point"
    );
    let x = &points[0].x;
    for (label, zero, shift) in [("+0.0", 0.0, 0.2), ("-0.0", -0.0, -0.2)] {
        let z = zero_gradient(x, zero, shift);
        println!(
            "  gradient {label} everywhere: pgd from x {shift:+.1} {:.3}, adversarial_training_augment from x {shift:+.1} {:.3}, fgsm from x {:.3}",
            z.pgd, z.augment, z.fgsm
        );
    }
    let s = sparse(&points);
    println!("  model with w_j = 0 for the last 50 features, over the 2000 points (fewest, most):");
    println!(
        "    pgd:  features moved {:?}, perturbation norm ({:.4}, {:.4}), accuracy {:.4}",
        s.pgd_moved, s.pgd_norm.0, s.pgd_norm.1, s.pgd_accuracy
    );
    println!(
        "    fgsm: features moved {:?}, perturbation norm ({:.4}, {:.4}), accuracy {:.4}",
        s.fgsm_moved, s.fgsm_norm.0, s.fgsm_norm.1, s.fgsm_accuracy
    );
    println!(
        "  control, the full model: largest distance between pgd's point and fgsm's {:.3}",
        pgd_against_fgsm(&points)
    );

    println!(
        "\n== P3, cw_attack with the hinge loss max(m, 0), lr 0.01, 2000 steps, on the correctly classified points"
    );
    for (c, predicted) in [
        (0.25, "every result x"),
        (1.0, "[0.464, 0.536]"),
        (0.75, "[0.299, 0.367]"),
    ] {
        let run = cw_run(&points, c);
        println!(
            "  c = {c:.2} (c|w| = {:.1}): {} points, {} returned unchanged, misclassified {:.4} (predicted {predicted}), largest | |delta| - m/|w| | {:.4}",
            2.0 * c,
            run.points,
            run.unchanged,
            run.misclassified as f64 / run.points as f64,
            run.distance_gap
        );
    }

    println!(
        "\n== P4, universal_perturbation on one correctly classified point, one iteration, loss = m"
    );
    let u = universal_run(&points);
    println!(
        "  {} points, largest relative error of the new margin against",
        u.points
    );
    println!(
        "    m(1 - |w|) = -m with the fooling direction -y w:   {:.1e}",
        u.fooling
    );
    println!(
        "    m(1 + |w|) = 3m with the loss's gradient +y w:     {:.1e}",
        u.loss_gradient
    );
    println!(
        "    m'(1 - |w|/4) = m'/2 with w/4, m' = m/4:           {:.1e}",
        u.scaled
    );
    println!(
        "  length of the w/4 perturbation against a quarter of the full one: {:.1e}",
        u.scaled_length
    );

    println!(
        "\n== P5, detect_adversarial, sigma 0.1, 50 samples, the 2000 clean points and their FGSM versions at eps 0.2"
    );
    let d = detection(&points);
    println!(
        "  outputs (z, -z): score of the first input {:.4} (expectation 0.04); {} of {} inputs have it to within 1e-12",
        d.score, d.same_score, d.inputs
    );
    println!(
        "  flagged at threshold 0.015: {}; at 0.09: {}",
        d.flagged_low, d.flagged_high
    );
    println!(
        "  control, outputs (p, 1 - p): score nearest the boundary {:.2e}, farthest {:.2e}; more than 10 times: {}",
        d.near,
        d.far,
        yes(d.near > 10.0 * d.far)
    );

    println!("\n== P6, feature_squeezing of 100000 uniform values moved by +-eps");
    for (bits, eps, formula) in [
        (3, 0.05, "0.350, 0.05000, 0.08452"),
        (5, 0.01, "0.310, 0.01000, 0.01796"),
    ] {
        let q = squeeze(bits, eps);
        println!(
            "  {bits} bits, eps {eps}: changed {:.4}, mean |change| {:.5}, root mean square {:.5}   (formula {formula})",
            q.changed, q.mean_abs, q.rms
        );
    }
    println!("  0 bits: {:?}", squeeze_zero_bits().to_vec());

    println!("\n== P7, certified_radius at sigma 1 against the exact radius (AS 241)");
    let r = radius();
    println!(
        "  p_A = 0.501 to 0.999, p_B = 1 - p_A: largest error {:.2e}, at p_A = {:.3}",
        r.max_error, r.at
    );
    println!("  p_A = 0.9: IX {:.6}, exact {:.6}", r.ix_09, r.exact_09);
    println!(
        "  logits (2, -1): {:.4}; logits (3, 1): {:.4}",
        r.logits_2_1, r.logits_3_1
    );

    println!("\n== P8, poisoning");
    let f = label_flips();
    println!(
        "  1000 points in 2 dimensions, {} labels flipped: influence_function unchanged bit for bit: {}",
        f.flipped,
        yes(f.influence_identical)
    );
    println!(
        "  detect_label_flips, k = 5: {} flipped labels found, {} other points flagged",
        f.found, f.others
    );
    let sp = spectral();
    println!(
        "  spectral_signature_defense, 90th percentile, 100 points per class in 10 dimensions: flagged per class {:?}",
        sp.clean
    );
    println!(
        "  with 5 points shifted by 6 added to class 0: flagged per class {:?}, shifted points among them {}",
        sp.poisoned, sp.poison_found
    );

    println!("\n== exploratory");
    println!(
        "  jsma returns the same point for targets 0 and 1: {}",
        yes(jsma_ignores_its_target(&points[0].x))
    );
    let mut l = lipschitz_runs();
    l.sort_by(|a, b| a.total_cmp(b));
    println!(
        "  lipschitz_estimate of x -> (10 x_0, x_1, ..., x_99), constant 10, 200 samples, 20 seeds: lowest {:.3}, median {:.3}, highest {:.3}",
        l[0],
        (l[9] + l[10]) / 2.0,
        l[19]
    );
}
