---
title: "19. The shape of data: persistent homology"
description: "Rips filtrations, persistence diagrams and the distances between them with IX's ix-topo, then the seed and the early exaggeration of ix-manifold's two t-SNEs, with eight predictions written before the first run: seven held and one was refuted in part. The reduction is the standard one, but the top dimension has no cofaces and reports 1,771 voids in a contractible complex, the two distances pair points by rank instead of searching for a matching, and break the stability theorem in 24 of 50 clouds, and the Barnes–Hut t-SNE ignores its seed and, at the pinned bhtsne 0.5.3, returns a map with no clusters."
sidebar:
  order: 19
---

Persistent homology describes the shape of a point cloud by what appears and disappears as the points are joined at a growing scale: connected components, loops, voids. Each feature gets a birth and a death, and a *persistence diagram* collects those pairs. [Carlsson (2009)](https://doi.org/10.1090/S0273-0979-09-01249-X) makes the case for it as a data analysis tool. IX's pinned [`ix-topo`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-topo) crate builds the filtration, computes the diagrams, and compares them with two distances. Three other IX crates call it, two of them to fingerprint GA's voicing embeddings. The same lesson then returns to t-SNE, which [lesson 9](../09-other-reducers/) met in `ix-unsupervised`, through the second implementation IX has, in [`ix-manifold`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-manifold): an exact `Tsne` and a `BarnesHutTsne` built on the [bhtsne](https://docs.rs/bhtsne/0.5.3/bhtsne/) crate.

The eight predictions this lesson tests were [written in the journal](../journal/#2026-09-30--lesson-19-predicted-before-measuring) and committed before any of its code existed. [The results](../journal/#2026-09-30--lesson-19-measured) follow them. The experiments are in [`topology.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/src/topology.rs), one test per prediction, and [`l19_topology.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/examples/l19_topology.rs) prints what they measure. [`crosscheck.py`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/crosscheck/crosscheck.py) computes the diagrams again with Python sets, the exact distances with SciPy's [`maximum_bipartite_matching`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.sparse.csgraph.maximum_bipartite_matching.html) and [`linear_sum_assignment`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.optimize.linear_sum_assignment.html), IX's two matchings once more, and finds the same numbers.

## 1. A circle at a growing scale

The Vietoris–Rips complex at scale r joins every set of points whose pairwise distances are all at most r: an edge for two points, a triangle for three, a tetrahedron for four. As r grows, simplices are only added, so the complexes form a *filtration*. `rips_complex(points, max_dim, max_radius)` builds it up to dimension max_dim and gives each simplex its diameter, the largest distance between two of its vertices, as its filtration value, the convention of [Ripser](https://doi.org/10.1007/s41468-021-00071-5) ([`simplex.rs` 216](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-topo/src/simplex.rs#L216)). A component is born at 0 and dies when an edge merges it into an older one. A loop is born with the edge that closes it and dies when triangles fill it. A feature that never dies within the filtration is *essential*, with death ∞.

The lesson's circle is 24 points at angles 2πi/24 and radii 1 + 0.1·(2u − 1), with u uniform from the course's generator:

```text
== the circle
24 points at radii 1 +- 0.1; diameter 2.1592, so every simplex is present at 2.5
```

At 2.5 the complex is a full simplex on 24 vertices, which is contractible: one component, no loop, no void.

## 2. The reduction is the standard one

`compute_persistence` reduces the boundary matrix over Z/2, column by column in filtration order, and pairs each column's lowest row with it ([`persistence.rs` 70-163](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-topo/src/persistence.rs#L70-L163)): the algorithm of [Edelsbrunner, Letscher and Zomorodian (2002)](https://doi.org/10.1007/s00454-002-2885-2) and [Zomorodian and Carlsson (2005)](https://doi.org/10.1007/s00454-004-1146-y). It finds each face by scanning the whole list of simplices, which costs time, not correctness, and drops pairs whose persistence is below 10⁻¹⁵. The lesson writes the same reduction with a hash map from faces to columns. It also checks H₀ against [Kruskal (1956)](https://doi.org/10.1090/S0002-9939-1956-0078686-7): in a Rips filtration a component dies at the length of the edge that merges it, so the finite H₀ deaths are the edge lengths of a minimum spanning tree. P1 compares the three:

```text
== P1, compute_persistence(rips_complex(points, 2, 2.5)) against a reduction written here
  H0: 23 finite pairs, 1 essential; equal to the reduction's: yes; deaths are Kruskal's tree, bit for bit: yes
  H1 pairs: 1, equal to the reduction's: yes
  persistence above 0.5: born 0.3153 (longest gap between neighbours 0.3153), dies 1.7007
  no other H1 pair
```

Every pair matches, bit for bit. The circle's one loop is born when the ring closes, at the longest of the 24 gaps between neighbours, and dies at 1.7007. For evenly spaced points on a circle of radius 1 it would die near √3 = 1.732, the side of the inscribed equilateral triangle, where the complex stops being a circle ([Adamaszek and Adams 2017](https://arxiv.org/abs/1503.03669)). Every other H₁ pair has zero persistence and was dropped. The cross-check finds the same loop with Python sets and the same H₀ deaths with SciPy's [`minimum_spanning_tree`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.sparse.csgraph.minimum_spanning_tree.html).

## 3. The top dimension has no cofaces

A loop can only be filled by triangles, and a void only by tetrahedra. `persistence_from_points(points, max_dim, max_radius)` builds `rips_complex(points, max_dim, max_radius)` and returns the diagrams up to max_dim, which its doc comment describes as "maximum homology dimension (1 = loops, 2 = voids)" ([`pointcloud.rs` 30-44](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-topo/src/pointcloud.rs#L30-L44)). But a complex built up to dimension max_dim has no simplex of dimension max_dim + 1, so nothing can kill a cycle of the top dimension: every one of them is reported as essential. `betti_at_radius` and `betti_curve` ([`pointcloud.rs` 46-89](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-topo/src/pointcloud.rs#L46-L89)) count the top Betti number the same way, through `betti_numbers`, where the top dimension has no boundary to subtract ([`simplex.rs` 142-199](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-topo/src/simplex.rs#L142-L199)). P2 asks for the circle's diagrams at 2.5, where the answer is (1, 0, 0), and for the four corners of the unit square at 1.5, above the diagonal √2:

```text
== P2, the top dimension without cofaces, the circle at max_radius 2.5
  persistence_from_points(points, 1, ..): H1 253 pairs, 253 essential   (C(24, 2) - 24 + 1 = 253)
  persistence_from_points(points, 2, ..): H1 right: yes, 0 essential; H2 1771 pairs, 1771 essential   (C(23, 3) = 1771)
  H2 from the reduction written here, up to tetrahedra: 2 pairs, 0 essential
  the unit square's corners at radius 1.5: betti_at_radius [1, 3] with max_dim 1, [1, 0, 1] with max_dim 2; up to tetrahedra [1, 0, 0]
```

With max_dim = 1, the complex is the complete graph on 24 vertices, and each of its 253 independent cycles is reported as a loop that never dies. With max_dim = 2, H₁ is right, but H₂ now has 1,771 essential voids, one per independent 2-cycle of the full 2-skeleton. Built one dimension higher, the lesson's reduction finds 2 finite H₂ pairs and no essential one. The square shows it at small scale: `betti_at_radius` reports 3 loops with max_dim = 1 and a void with max_dim = 2, where a full tetrahedron has none.

The fix is to build one dimension higher than the last diagram you read. Three callers at the pinned commit pass max_dim = 1 and read β₁: `topology` in ix-voicings, which reports the essential H₁ pairs as β₁ ([`lib.rs` 879-899](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-voicings/src/lib.rs#L879-L899)); the daily fingerprint of ix-embedding-diagnostics ([`main.rs` 697](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-embedding-diagnostics/src/main.rs#L697)); and the `ix_topo` MCP tool, by default ([`handlers.rs` 2151](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-agent/src/handlers.rs#L2151)). The 14 fingerprints retained in [`state/quality-snapshots/embeddings/`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2/state/quality-snapshots/embeddings), from 2026-04-12 to 2026-04-25, all report β₁ = 0, and they are right: at their radius, 100 points per instrument are joined by 2 to 6 edges, a forest with no cycle. The finding changes none of them, but it would change the first fingerprint whose graph closes a cycle.

## 4. Two distances between diagrams

Two diagrams are compared by matching their points, where any point may also be matched to the diagonal, at the cost of its distance to it, (death − birth)/2 in the L∞ norm. The bottleneck distance is the smallest achievable largest cost; the p-Wasserstein distance is the smallest achievable (Σ costᵖ)^(1/p). Two essential points must be matched together, so diagrams with different numbers of them are infinitely far apart. [Cohen-Steiner, Edelsbrunner and Harer (2007)](https://doi.org/10.1007/s00454-006-1276-5) define the first; [Kerber, Morozov and Nigmetov (2017)](https://doi.org/10.1145/3064175) compute both exactly. The lesson computes them by bisection over the candidate costs with a bipartite matching by augmenting paths, and with the Hungarian algorithm of [Kuhn (1955)](https://doi.org/10.1002/nav.3800020109), and checks both against every assignment of small problems.

`bottleneck_distance`'s doc comment gives the definition: "the infimum over all matchings of the maximum cost of any matched pair". The code, whose inline comment says "Simple approximation", pads each diagram with the diagonal projections of the other's points, sorts both lists by persistence, and pairs them rank by rank ([`persistence.rs` 165-213](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-topo/src/persistence.rs#L165-L213)). `wasserstein_distance` drops the essential points, pads the shorter list with projections of the longer one's points, sorts both by *birth* and pairs them index by index ([`persistence.rs` 215-255](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-topo/src/persistence.rs#L215-L255)). Neither searches over matchings. P3 builds diagrams where that matters:

```text
== P3, hand-made diagrams: IX, exact
  bottleneck, {(0, 2), (10, 11)} and {(10, 12), (0, 1)}: 10.0000, 1.0000
  W1, {(0, 10), (1, 2)} and {(1, 10), (0, 2)}: 16.0000, 2.0000; W2: 11.3137, 1.4142
  {(0, inf)} and an empty diagram: IX's bottleneck 0.0000, IX's W2 0.0000; exact inf
```

In the first pair, (0, 2) and (10, 12) have the same persistence, so ranking by persistence matches them, at cost 10, where (0, 2) with (0, 1) and (10, 11) with (10, 12) cost 1 each. In the second, sorting by birth puts (0, 2) against (0, 10) and (1, 2) against (1, 10), at cost 8 each, where swapping the partners costs 1 each. And a diagram with one essential loop is at distance 0 from an empty one, where no matching exists.

## 5. Always above, and usually

Both of IX's matchings are admissible, so neither distance can fall below the exact one. P4 asks how often it lies above, on 1,000 pairs of diagrams of 5 random points, each born uniformly on [0, 1] with a persistence uniform on [0, 1]:

```text
== P4, 1000 pairs of random 5-point diagrams
  bottleneck: IX at least the exact distance in 1000, above it by more than 1e-9 in 999; median of IX / exact 2.29
  W1: IX at least the exact distance in 1000, above it by more than 1e-9 in 982; median of IX / exact 1.64
```

IX is never below and almost always above: its bottleneck distance is exact in one pair of 1,000, and the median ratio is 2.29. The exact bottleneck distance is at most half the largest persistence, here 0.5, while IX pairs the diagonal projections in list order. The cross-check computes both of IX's matchings again in Python and the exact distances with SciPy, and counts the same 1,000, 999, 1,000 and 982.

## 6. The stability theorem, and what breaks it

What makes diagrams worth comparing is stability: moving each point of a cloud by at most δ changes each simplex's diameter by at most 2δ, and then the bottleneck distance between the diagrams by at most 2δ ([Cohen-Steiner et al. 2007](https://doi.org/10.1007/s00454-006-1276-5); [Chazal et al. 2009](https://doi.org/10.1111/j.1467-8659.2009.01516.x)). A small change in the data can't make a large change in the diagram. P5 draws 50 clouds of 24 points uniform in the unit square, moves each point by exactly δ = 0.01 in a random direction, and compares the H₁ diagrams, built up to triangles so that H₁ has its cofaces:

```text
== P5, stability: 50 clouds of 24 points, each point moved by 0.01, H1 from persistence_from_points(.., 2, 1.5)
  H1 pairs in a diagram: fewest 0, most 7
  exact bottleneck at most 2 delta = 0.02: 50 of 50, largest 0.0195
  IX's bottleneck above 0.02: 24 of 50, largest 0.2526
```

The theorem holds for the exact distance in 50 of 50 clouds. IX's distance breaks the bound in 24 of them, the worst by more than 12 times. The rank-by-rank pairing explains it: when two loops of close persistence swap ranks, or a loop shorter than 2δ appears or vanishes and shifts the ranks after it, it matches points that have nothing to do with each other. A caller who thresholds IX's distance to decide whether two embeddings have the same shape measures the order of the persistences as much as the shape.

## 7. The Barnes–Hut t-SNE ignores its seed

t-SNE ([van der Maaten and Hinton 2008](https://jmlr.org/papers/v9/vandermaaten08a.html)) turns distances into neighbour probabilities P, each row's bandwidth chosen so that its entropy is the log of the perplexity, then moves points in the plane until their Student-t similarities Q match P. The Barnes–Hut version ([van der Maaten 2014](https://jmlr.org/papers/v15/vandermaaten14a.html)) approximates the forces with a tree. `BarnesHutTsne::with_seed` stores a seed, and `fit_transform` discards it with `let _ = self.seed;`: bhtsne 0.5.3 draws its initial embedding from `rand::thread_rng()` ([`lib.rs` 354-392](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-manifold/src/lib.rs#L354-L392); [bhtsne `tsne/mod.rs` 131-136](https://docs.rs/bhtsne/0.5.3/src/bhtsne/tsne/mod.rs.html#131-136)). The comment above that line says so and plans to "Document this in the type docs", which still say "seed 0". The exact `Tsne` seeds a ChaCha8 generator ([`lib.rs` 131-134](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-manifold/src/lib.rs#L131-L134)). P6 fits 150 points in 10 dimensions, three clusters of 50 around 0, 10·e₁ and 10·e₂ with the course's approximate normal noise, and scores each embedding by the vote of each point's 5 nearest neighbours in it:

```text
== P6, seeds: 150 points in three clusters in 10 dimensions
  BarnesHutTsne::with_seed(7) twice: largest coordinate difference above 1e-3: yes
  both Barnes-Hut embeddings: 5-nearest-neighbour vote right for at least 95% of the points: no; below 60%, where a random embedding gives about 1/3: yes
  Tsne::with_seed(7), 300 iterations, twice: the same embedding bit for bit: yes
```

The seed part held: two Barnes–Hut runs with seed 7 differ, and two exact runs are identical. The other part was refuted. The prediction said both Barnes–Hut maps would separate the clusters; the first run scored 0.267 and 0.347, near the third a random map gives. The test now pins that measurement, below 0.6, and keeps the 0.95 of the prediction visible in a comment.

The cause is in bhtsne 0.5.3's bandwidth search ([`tsne/mod.rs` 194-270](https://docs.rs/bhtsne/0.5.3/src/bhtsne/tsne/mod.rs.html#194-270)). It starts at β = 1, where the kernel is exp(−β·d²). When the entropy is too low, β must go down, and without a lower bracket yet, the code sets it to a constant named `zero_point_five`, whose value is 5.0. β goes up instead, the entropy falls further, and after 200 steps each row puts nearly all its weight on its nearest neighbour. The search only works when β = 1 already gives too high an entropy, which requires small distances. Here the squared distances within a cluster are about 20, and the right β is well below 1. bhtsne 0.6.0 adds a regression test whose comment describes exactly this ([`src/test.rs` 845-853](https://docs.rs/crate/bhtsne/0.6.0/source/src/test.rs)): "releases 0.5.3-0.5.4 moved beta upwards instead (a constant named `zero_point_five` was set to 5.0), making the search diverge and the conditional distribution degenerate". IX's workspace pins `bhtsne = "=0.5.3"` ([`Cargo.toml` 108](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/Cargo.toml#L108)). Its own test that Barnes–Hut separates two clusters draws noise with a standard deviation of 0.1, where the squared distances within a cluster are about 0.16, β = 1 is already too small, and the search goes the right way ([`lib.rs` 548-582](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-manifold/src/lib.rs#L548-L582)). An exploratory check, measured after the first run, scales the same points by 0.3:

```text
== exploratory
  Barnes-Hut on the same points scaled by 0.3, twice: vote at least 95% in both runs: yes
```

The same data, shrunk, is separated perfectly. t-SNE is meant to be invariant to that scale, since the bandwidth search absorbs it; this one is not. The `tsne-voicings` binary uses Barnes–Hut by default, and its enum's doc comment notes that it isn't seed-deterministic, yet it writes `"seed": 42` into its output ([`tsne_voicings.rs` 53-92](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-voicings/src/bin/tsne_voicings.rs#L53-L92)). Whether GA's voicing embeddings are at a scale where the search diverges wasn't measured; the journal lists it as to verify.

## 8. Early exaggeration that never ends

Early exaggeration multiplies P by 12 at the start, so that clusters form and move apart before the fine placement. The module doc says `Tsne` does it "for the first quarter of iters" ([`lib.rs` 36-38](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-manifold/src/lib.rs#L36-L38)). The code stops it after `early_exaggeration_iters`, 250 by default, whatever `n_iter` is ([`lib.rs` 79](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-manifold/src/lib.rs#L79), [139-143](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-manifold/src/lib.rs#L139-L143)). With 250 iterations or fewer, the embedding is fitted to 12P throughout. P7 scores the embeddings with KL(P‖Q), against a P at perplexity 30 that the lesson computes with its own bisection:

```text
== P7, early exaggeration, the same points, seed 7, KL(P||Q) against P at perplexity 30
  200 iterations, default: the same as with_early_exaggeration(12.0, 200), bit for bit: yes
  KL after 200 iterations: default above exaggeration for the first 50: yes
```

With 200 iterations, the default is the exaggerated run, bit for bit, and its KL is about six times that of the documented quarter: 1.452 against 0.246 on the author's Windows machine and on CI's Windows runner, 1.540 against 0.249 on CI's Ubuntu, 1.466 against 0.247 on its macOS. The same seed doesn't give the same map on the three systems: it fixes the ChaCha8 random stream, not the floating-point functions that follow. Rust documents the precision of `f64::exp`, `ln` and `powi` as "non-deterministic", varying "by platform, Rust version" ([`f64::exp`](https://doc.rust-lang.org/std/primitive.f64.html#method.exp)), and IX's own separation test lowered its threshold after Linux gave other ratios than Windows on the same seed ([`lib.rs` 485-493](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-manifold/src/lib.rs#L485-L493)). The lesson didn't isolate which call diverges first. So the example prints the comparison, which holds on all three, rather than the values: the first CI run printed them, and failed on Ubuntu and macOS. A second exploratory check runs the default 1,000 iterations, with exaggeration for the first 250:

```text
  the default 1000 iterations, exaggeration for the first 250: KL within 0.05 of 200 iterations with the first 50: yes
```

The 1,000 iterations reach 0.241 on Windows, 0.237 on Ubuntu and 0.243 on macOS: 50 exaggerated iterations out of 200 get within about 0.01 of the default 1,000. A caller who shortens `n_iter` to save time, as the lesson did, gets a map fitted to the wrong target unless they also shorten `early_exaggeration_iters`.

## 9. The skill's import, and the features left out

The `ix-topo` skill page shows `use ix_topo::simplicial::{rips_complex, SimplexStream};` ([`SKILL.md` 28](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/.claude/skills/ix-topo/SKILL.md?plain=1#L28)). The crate has no `simplicial` module; its modules are `error`, `persistence`, `pointcloud` and `simplex` ([`lib.rs` 6-9](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-topo/src/lib.rs#L6-L9)). P8 keeps that line as a `compile_fail` doctest, which fails with E0432, unresolved import, and the same line with `simplex` as a doctest that compiles.

A last exploratory check cuts the circle's filtration at 1.0, before its loop dies, so that the loop is essential there. `most_persistent_features` keeps only finite pairs ([`pointcloud.rs` 91-111](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-topo/src/pointcloud.rs#L91-L111)):

```text
  the circle at max_radius 1.0: essential H1 pairs 1; most_persistent_features ranks first a pair of dimension 0, persistence 0.3057
```

The feature it ranks first is the last gap to close in the ring, a component that lives 0.31. The loop, the one feature a reader of this diagram should see, isn't in the list at all, and neither is the component that never dies.

## 10. The predictions, scored

| | Prediction, written before the first run | Measured | Verdict |
|---|---|---|---|
| P1 | IX's H₀ and H₁ equal to a reduction written here, bit for bit; 23 finite H₀ deaths equal to Kruskal's tree; one H₁ pair above 0.5, born in [0.25, 0.35], dying in [1.5, 1.95] | All equal; born 0.3153, dies 1.7007 | Confirmed |
| P2 | Circle at 2.5: 253 essential H₁ pairs with max_dim = 1; H₁ right and 1,771 essential H₂ pairs with max_dim = 2; square at 1.5: [1, 3] and [1, 0, 1] | As predicted; up to tetrahedra, 2 finite H₂ pairs and [1, 0, 0] | Confirmed |
| P3 | Bottleneck 10 against 1; W₁ 16 against 2; W₂ 11.31 against 1.414; one essential point against none: 0 against ∞ | 10, 1; 16, 2; 11.3137, 1.4142; 0, 0 and ∞ | Confirmed |
| P4 | IX at least the exact distance in 1,000 of 1,000 pairs for both, above by more than 10⁻⁹ in at least 900 | 1,000 and 999 for the bottleneck, 1,000 and 982 for W₁ | Confirmed |
| P5 | Exact bottleneck at most 0.02 in 50 of 50 clouds; IX's above 0.02 in at least 5 | 50 of 50, largest 0.0195; 24, largest 0.2526 | Confirmed |
| P6 | Two Barnes–Hut runs with seed 7 differ by more than 10⁻³; two exact runs identical; both Barnes–Hut maps vote right for at least 95% | Differ, identical; votes 0.267 and 0.347 | Refuted in part |
| P7 | 200 iterations: default equal to exaggeration for all 200, bit for bit; its KL higher than with exaggeration for the first 50 | Equal; 1.452 against 0.246 (1.540 and 0.249 on Ubuntu, 1.466 and 0.247 on macOS) | Confirmed |
| P8 | The skill's import fails with E0432; the same line with `simplex` compiles | As predicted | Confirmed |

Seven held on the first run and one was refuted in part. No interval was changed afterwards. The refuted part came from a gap in the reading, not in the arithmetic: the prediction read `ix-manifold` and stopped at the call into bhtsne, whose bandwidth search it assumed was right. The test pins what the first run measured, and the scale check that explains it is marked exploratory, since it was chosen after seeing the result. The controls show that the other checks can fail: the exact distance does satisfy the stability bound, the lesson's reduction built one dimension higher does find the right H₂, and the exact `Tsne` is reproducible on one system.

## What to use for our repositories

- **`compute_persistence` and `rips_complex`:** correct, and bit for bit the standard reduction. The face lookup scans the whole list, so keep complexes small, or look faces up in a map as the lesson does.
- **`persistence_from_points`, `betti_at_radius`, `betti_curve`:** build one dimension higher than the last diagram or Betti number you read, and ignore that top one. For β₁, pass max_dim = 2 and read index 1.
- **`bottleneck_distance` and `wasserstein_distance`:** upper bounds, not the distances their doc comments name, and without the stability that makes diagrams comparable. For a threshold or a regression test, use an exact matching: the lesson's bisection and Hungarian algorithm are a few dozen lines, and SciPy's `linear_sum_assignment` does it in Python. Count essential points separately; IX's distances ignore them.
- **`most_persistent_features`:** add the essential pairs yourself, first.
- **`BarnesHutTsne`:** not reproducible, whatever seed you pass, and at the pinned bhtsne 0.5.3 its bandwidth search diverges unless the nearest distances are small. Scale the data so that it doesn't, check the map with a neighbour vote as the lesson does, or use the exact `Tsne` below a few thousand points.
- **`Tsne`:** with fewer than 1,000 iterations, set `early_exaggeration_iters` to a quarter of `n_iter` yourself. Its seed reproduces a map on one system, not across Windows, Linux and macOS: from one system to another, compare maps with a tolerance or a neighbour vote, not bit for bit.
- **The `ix-topo` skill:** import from `ix_topo::simplex`.

## Exercises

1. Show that the finite H₀ deaths of a Rips filtration are the edge lengths of a minimum spanning tree.
2. Why does the complete graph on n vertices have C(n, 2) − n + 1 independent cycles, and the full 2-skeleton on n vertices C(n − 1, 3) independent 2-cycles?
3. Find the exact bottleneck matching of P3's first pair of diagrams, and explain why ranking by persistence misses it.
4. Why can IX's bottleneck distance break the stability bound, when it is never below the exact distance, which satisfies it?
5. In bhtsne 0.5.3's search, what happens to β when the entropy at β = 1 is below ln(perplexity)? Why does scaling the data by 0.3 help, and what should scaling do to t-SNE?

<details>
<summary>Solutions</summary>

1. Kruskal's algorithm adds edges in increasing length and keeps an edge when it joins two components. In the Rips filtration, the edges also enter in increasing length, and an edge that joins two components is exactly one that kills an H₀ class, at its length, while an edge inside a component creates a loop instead. So the killing edges are Kruskal's tree, with the same lengths, the 23 finite deaths of P1.
2. A connected graph with V vertices and E edges has E − V + 1 independent cycles, since a spanning tree has V − 1 edges and each other edge closes one cycle: C(n, 2) − n + 1. In the full 2-skeleton, H₁ = 0, so every 1-cycle bounds and the boundaries of the C(n, 3) triangles span a space of dimension C(n, 2) − n + 1. The 2-cycles are the kernel of that map: C(n, 3) − C(n, 2) + n − 1 = C(n − 1, 3). For n = 24, 253 and 1,771.
3. Match (0, 2) with (0, 1) at cost max(0, 1) = 1, and (10, 11) with (10, 12) at cost 1: the bottleneck is 1. It can't be lower, because (0, 2) costs 1 against (0, 1), 10 against (10, 12) and 1 against the diagonal. Ranking by persistence pairs (0, 2) with (10, 12), both of persistence 2, at cost 10, because persistence says nothing about where a point is.
4. The bound constrains the exact distance, and IX's is only an upper bound of it. A perturbation of 0.01 can swap the ranks of two loops of close persistence at different places, or add a loop of persistence below 0.02 that shifts every rank after it, and the rank-by-rank pairing then matches loops far apart. The exact distance would match each loop with its moved copy, or a new tiny loop with the diagonal.
5. β = 1 is recorded as the upper bracket, and since no lower bracket is known, β is set to 5.0, then multiplied by 5 at each step: it grows until the 200 steps run out, and each row puts nearly all its weight on its nearest neighbour. Shrinking the data by 0.3 divides every squared distance by about 11, so that at β = 1 the entropy is already above the target and the search goes the right way. t-SNE should be invariant to that scale, since the bandwidths absorb it; the embedding shouldn't change.

</details>

## Sources

- IX at pinned commit `490c395`: [`persistence.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-topo/src/persistence.rs), [`pointcloud.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-topo/src/pointcloud.rs), [`simplex.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-topo/src/simplex.rs), [`ix-manifold/src/lib.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-manifold/src/lib.rs), [the `ix-topo` skill](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/.claude/skills/ix-topo/SKILL.md).
- bhtsne [0.5.3](https://docs.rs/bhtsne/0.5.3/bhtsne/), the version IX pins, and [0.6.0's regression test](https://docs.rs/crate/bhtsne/0.6.0/source/src/test.rs).
- G. Carlsson, ["Topology and data"](https://doi.org/10.1090/S0273-0979-09-01249-X), Bulletin of the AMS 46, 2009.
- H. Edelsbrunner, D. Letscher and A. Zomorodian, ["Topological persistence and simplification"](https://doi.org/10.1007/s00454-002-2885-2), Discrete & Computational Geometry 28, 2002. A. Zomorodian and G. Carlsson, ["Computing persistent homology"](https://doi.org/10.1007/s00454-004-1146-y), Discrete & Computational Geometry 33, 2005.
- D. Cohen-Steiner, H. Edelsbrunner and J. Harer, ["Stability of persistence diagrams"](https://doi.org/10.1007/s00454-006-1276-5), Discrete & Computational Geometry 37, 2007. F. Chazal, D. Cohen-Steiner, L. J. Guibas, F. Mémoli and S. Y. Oudot, ["Gromov-Hausdorff stable signatures for shapes using persistence"](https://doi.org/10.1111/j.1467-8659.2009.01516.x), Computer Graphics Forum 28, 2009.
- M. Kerber, D. Morozov and A. Nigmetov, ["Geometry helps to compare persistence diagrams"](https://doi.org/10.1145/3064175), ACM Journal of Experimental Algorithmics 22, 2017.
- U. Bauer, ["Ripser: efficient computation of Vietoris–Rips persistence barcodes"](https://doi.org/10.1007/s41468-021-00071-5), Journal of Applied and Computational Topology 5, 2021.
- M. Adamaszek and H. Adams, ["The Vietoris–Rips complexes of a circle"](https://arxiv.org/abs/1503.03669), Pacific Journal of Mathematics 290, 2017.
- H. W. Kuhn, ["The Hungarian method for the assignment problem"](https://doi.org/10.1002/nav.3800020109), Naval Research Logistics Quarterly 2, 1955. J. B. Kruskal, ["On the shortest spanning subtree of a graph and the traveling salesman problem"](https://doi.org/10.1090/S0002-9939-1956-0078686-7), Proceedings of the AMS 7, 1956.
- L. van der Maaten and G. Hinton, ["Visualizing data using t-SNE"](https://jmlr.org/papers/v9/vandermaaten08a.html), JMLR 9, 2008. L. van der Maaten, ["Accelerating t-SNE using tree-based algorithms"](https://jmlr.org/papers/v15/vandermaaten14a.html), JMLR 15, 2014.
- SciPy: [`maximum_bipartite_matching`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.sparse.csgraph.maximum_bipartite_matching.html), [`linear_sum_assignment`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.optimize.linear_sum_assignment.html), [`minimum_spanning_tree`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.sparse.csgraph.minimum_spanning_tree.html).
- Rust: the precision of [`f64::exp`](https://doc.rust-lang.org/std/primitive.f64.html#method.exp), [`ln`](https://doc.rust-lang.org/std/primitive.f64.html#method.ln) and [`powi`](https://doc.rust-lang.org/std/primitive.f64.html#method.powi).
