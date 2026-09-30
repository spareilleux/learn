//! Lesson 19: IX's `ix-topo` — persistence against a reduction written here, the top dimension computed
//! without cofaces, the bottleneck and Wasserstein distances against exact ones, and the stability bound —
//! then `ix-manifold`'s t-SNE: the Barnes–Hut seed and the early exaggeration.

use machine_learning_ix::topology::{
    CLOUDS, DELTA, DIAGRAM_PAIRS, FULL_RADIUS, POINTS, SHRINK, circle, distance, exaggeration,
    hand_made, random_diagrams, reduction, seeds, stability, top_dimension, truncated_loop,
};

fn yes(b: bool) -> &'static str {
    if b { "yes" } else { "no" }
}

fn main() {
    let points = circle();
    let diameter = points
        .iter()
        .flat_map(|a| points.iter().map(move |b| distance(a, b)))
        .fold(0.0, f64::max);
    println!("== the circle");
    println!(
        "{POINTS} points at radii 1 +- 0.1; diameter {diameter:.4}, so every simplex is present at {FULL_RADIUS}"
    );

    println!(
        "\n== P1, compute_persistence(rips_complex(points, 2, {FULL_RADIUS})) against a reduction written here"
    );
    let r = reduction();
    println!(
        "  H0: {} finite pairs, {} essential; equal to the reduction's: {}; deaths are Kruskal's tree, bit for bit: {}",
        r.h0_finite,
        r.h0_essential,
        yes(r.h0_same),
        yes(r.tree_same)
    );
    println!(
        "  H1 pairs: {}, equal to the reduction's: {}",
        r.h1_pairs,
        yes(r.h1_same)
    );
    for (birth, death) in &r.loops {
        println!(
            "  persistence above 0.5: born {birth:.4} (longest gap between neighbours {:.4}), dies {death:.4}",
            r.longest_gap
        );
    }
    if r.h1_pairs > r.loops.len() {
        println!(
            "  largest persistence of the other H1 pairs: {:.4}",
            r.largest_other
        );
    } else {
        println!("  no other H1 pair");
    }

    println!("\n== P2, the top dimension without cofaces, the circle at max_radius {FULL_RADIUS}");
    let t = top_dimension();
    println!(
        "  persistence_from_points(points, 1, ..): H1 {} pairs, {} essential   (C(24, 2) - 24 + 1 = 253)",
        t.h1_with_1.0, t.h1_with_1.1
    );
    println!(
        "  persistence_from_points(points, 2, ..): H1 right: {}, {} essential; H2 {} pairs, {} essential   (C(23, 3) = 1771)",
        yes(t.h1_with_2_right),
        t.h1_with_2_essential,
        t.h2_with_2.0,
        t.h2_with_2.1
    );
    println!(
        "  H2 from the reduction written here, up to tetrahedra: {} pairs, {} essential",
        t.h2_right.0, t.h2_right.1
    );
    println!(
        "  the unit square's corners at radius 1.5: betti_at_radius {:?} with max_dim 1, {:?} with max_dim 2; up to tetrahedra {:?}",
        t.square_1, t.square_2, t.square_right
    );

    println!("\n== P3, hand-made diagrams: IX, exact");
    let h = hand_made();
    println!(
        "  bottleneck, {{(0, 2), (10, 11)}} and {{(10, 12), (0, 1)}}: {:.4}, {:.4}",
        h.bottleneck.0, h.bottleneck.1
    );
    println!(
        "  W1, {{(0, 10), (1, 2)}} and {{(1, 10), (0, 2)}}: {:.4}, {:.4}; W2: {:.4}, {:.4}",
        h.w1.0, h.w1.1, h.w2.0, h.w2.1
    );
    println!(
        "  {{(0, inf)}} and an empty diagram: IX's bottleneck {:.4}, IX's W2 {:.4}; exact {}",
        h.essential.0, h.essential.1, h.essential.2
    );

    println!("\n== P4, {DIAGRAM_PAIRS} pairs of random 5-point diagrams");
    let d = random_diagrams();
    for (name, (at_least, above), ratio) in [
        ("bottleneck", d.bottleneck, d.bottleneck_ratio),
        ("W1", d.w1, d.w1_ratio),
    ] {
        println!(
            "  {name}: IX at least the exact distance in {at_least}, above it by more than 1e-9 in {above}; median of IX / exact {ratio:.2}"
        );
    }

    println!(
        "\n== P5, stability: {CLOUDS} clouds of {POINTS} points, each point moved by {DELTA}, H1 from persistence_from_points(.., 2, 1.5)"
    );
    let s = stability();
    println!(
        "  H1 pairs in a diagram: fewest {}, most {}",
        s.h1_pairs.0, s.h1_pairs.1
    );
    println!(
        "  exact bottleneck at most 2 delta = 0.02: {} of {CLOUDS}, largest {:.4}",
        s.exact_within, s.largest_exact
    );
    println!(
        "  IX's bottleneck above 0.02: {} of {CLOUDS}, largest {:.4}",
        s.ix_above, s.largest_ix
    );

    println!("\n== P6, seeds: 150 points in three clusters in 10 dimensions");
    let sd = seeds();
    println!(
        "  BarnesHutTsne::with_seed(7) twice: largest coordinate difference above 1e-3: {}",
        yes(sd.barnes_hut_gap > 1e-3)
    );
    println!(
        "  both Barnes-Hut embeddings: 5-nearest-neighbour vote right for at least 95% of the points: {}; below 60%, where a random embedding gives about 1/3: {}",
        yes(sd.votes.0 >= 0.95 && sd.votes.1 >= 0.95),
        yes(sd.votes.0 < 0.6 && sd.votes.1 < 0.6)
    );
    println!(
        "  Tsne::with_seed(7), 300 iterations, twice: the same embedding bit for bit: {}",
        yes(sd.exact_identical)
    );

    println!(
        "\n== P7, early exaggeration, the same points, seed 7, KL(P||Q) against P at perplexity 30"
    );
    let e = exaggeration();
    println!(
        "  200 iterations, default: the same as with_early_exaggeration(12.0, 200), bit for bit: {}",
        yes(e.never_ends)
    );
    // The KL values differ between Windows, Linux and macOS (Rust leaves the precision of exp and ln to the
    // platform): print the comparisons, which hold on all three.
    println!(
        "  KL after 200 iterations: default above exaggeration for the first 50: {}",
        yes(e.kl_default > e.kl_quarter)
    );

    println!("\n== exploratory");
    println!(
        "  Barnes-Hut on the same points scaled by {SHRINK}, twice: vote at least 95% in both runs: {}",
        yes(sd.scaled_votes.0 >= 0.95 && sd.scaled_votes.1 >= 0.95)
    );
    println!(
        "  the default 1000 iterations, exaggeration for the first 250: KL within 0.05 of 200 iterations with the first 50: {}",
        yes((e.kl_1000 - e.kl_quarter).abs() < 0.05)
    );
    let (loops, dimension, persistence) = truncated_loop();
    println!(
        "  the circle at max_radius 1.0: essential H1 pairs {loops}; most_persistent_features ranks first a pair of dimension {dimension}, persistence {persistence:.4}"
    );
}
