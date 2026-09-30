//! Lesson 19: the shape of data. IX's `ix-topo` against a persistence reduction written here, exact
//! distances between diagrams and the stability bound; then IX's `ix-manifold` t-SNE and its seeds.
//!
//! The `ix-topo` skill page of IX (`.claude/skills/ix-topo/SKILL.md`, line 28) imports a module the crate
//! doesn't have:
//!
//! ```compile_fail,E0432
//! use ix_topo::simplicial::{rips_complex, SimplexStream};
//! ```
//!
//! The module is `simplex`:
//!
//! ```
//! use ix_topo::simplex::{rips_complex, SimplexStream};
//!
//! let stream: SimplexStream = rips_complex(&[vec![0.0], vec![1.0]], 1, 2.0);
//! assert_eq!(stream.len(), 3);
//! ```

use std::cmp::Ordering;
use std::collections::HashMap;

use ix_manifold::{BarnesHutTsne, Tsne};
use ix_topo::persistence::{
    PersistenceDiagram, bottleneck_distance, compute_persistence, wasserstein_distance,
};
use ix_topo::pointcloud::{betti_at_radius, most_persistent_features, persistence_from_points};
use ix_topo::simplex::rips_complex;
use ndarray::{Array2, ArrayView1};

use crate::autodiff::Rng;
use crate::rl::normal;

/// A point of a persistence diagram, (birth, death); the death of a feature that never dies is infinite
pub type Pair = (f64, f64);

/// Points of the circle, and of each stability cloud
pub const POINTS: usize = 24;
/// A radius above the circle's diameter, at most 2.2: every simplex is present
pub const FULL_RADIUS: f64 = 2.5;
/// How far each point of a stability cloud moves, and how many clouds
pub const DELTA: f64 = 0.01;
pub const CLOUDS: usize = 50;
/// Pairs of random diagrams in P4, and points in each diagram
pub const DIAGRAM_PAIRS: usize = 1000;
pub const DIAGRAM_POINTS: usize = 5;

/// Euclidean distance, summed as `ix-topo` sums it, so that both give the same bits
pub fn distance(a: &[f64], b: &[f64]) -> f64 {
    a.iter()
        .zip(b)
        .map(|(x, y)| (x - y) * (x - y))
        .sum::<f64>()
        .sqrt()
}

fn squared(a: ArrayView1<f64>, b: ArrayView1<f64>) -> f64 {
    a.iter().zip(b).map(|(x, y)| (x - y) * (x - y)).sum()
}

/// 24 points at angles 2πi/24 and radii 1 + 0.1·(2u − 1), u drawn from `Rng(19_100)`
pub fn circle() -> Vec<Vec<f64>> {
    let mut rng = Rng(19_100);
    (0..POINTS)
        .map(|i| {
            let angle = 2.0 * std::f64::consts::PI * i as f64 / POINTS as f64;
            let radius = 1.0 + 0.1 * (2.0 * rng.next_f64() - 1.0);
            vec![radius * angle.cos(), radius * angle.sin()]
        })
        .collect()
}

/// The four corners of the unit square
pub fn square() -> Vec<Vec<f64>> {
    vec![
        vec![0.0, 0.0],
        vec![1.0, 0.0],
        vec![1.0, 1.0],
        vec![0.0, 1.0],
    ]
}

/// Pairs sorted by birth, then death, so that two diagrams compare as lists
pub fn sorted(pairs: &[Pair]) -> Vec<Pair> {
    let mut v = pairs.to_vec();
    v.sort_by(|a, b| a.0.total_cmp(&b.0).then(a.1.total_cmp(&b.1)));
    v
}

fn essential(pairs: &[Pair]) -> usize {
    pairs.iter().filter(|p| p.1.is_infinite()).count()
}

fn symmetric_difference(a: &[usize], b: &[usize]) -> Vec<usize> {
    let (mut i, mut k) = (0, 0);
    let mut out = Vec::with_capacity(a.len() + b.len());
    while i < a.len() && k < b.len() {
        match a[i].cmp(&b[k]) {
            Ordering::Less => {
                out.push(a[i]);
                i += 1;
            }
            Ordering::Greater => {
                out.push(b[k]);
                k += 1;
            }
            Ordering::Equal => {
                i += 1;
                k += 1;
            }
        }
    }
    out.extend_from_slice(&a[i..]);
    out.extend_from_slice(&b[k..]);
    out
}

/// The Rips filtration of `points`, simplices up to dimension `build_dim` whose largest distance between two
/// vertices is at most `max_radius`, each at that distance, reduced over Z/2 in filtration order. Faces are
/// found in a hash map. One list of pairs per dimension 0 to `build_dim`; as in `compute_persistence`, pairs
/// of persistence at most 1e-15 are dropped, and a cycle nothing kills is essential.
pub fn rips_persistence(points: &[Vec<f64>], build_dim: usize, max_radius: f64) -> Vec<Vec<Pair>> {
    let n = points.len();
    let mut layer: Vec<(f64, Vec<usize>)> = (0..n).map(|i| (0.0, vec![i])).collect();
    let mut simplices = layer.clone();
    for _ in 0..build_dim {
        let mut next = Vec::new();
        for (value, s) in &layer {
            let last = *s.last().expect("a simplex has a vertex");
            for v in last + 1..n {
                let d = s
                    .iter()
                    .map(|&u| distance(&points[u], &points[v]))
                    .fold(*value, f64::max);
                // a simplex above the radius has no coface below it
                if d <= max_radius {
                    let mut t = s.clone();
                    t.push(v);
                    next.push((d, t));
                }
            }
        }
        simplices.extend(next.iter().cloned());
        layer = next;
    }
    // birth, then dimension, then vertices: the order of `SimplexStream::sort`
    simplices.sort_by(|a, b| {
        a.0.total_cmp(&b.0)
            .then(a.1.len().cmp(&b.1.len()))
            .then(a.1.cmp(&b.1))
    });
    let index: HashMap<&[usize], usize> = simplices
        .iter()
        .enumerate()
        .map(|(i, (_, s))| (s.as_slice(), i))
        .collect();
    let mut columns: Vec<Vec<usize>> = simplices
        .iter()
        .map(|(_, s)| {
            if s.len() < 2 {
                return vec![];
            }
            let mut column: Vec<usize> = (0..s.len())
                .map(|skip| {
                    let face: Vec<usize> = s
                        .iter()
                        .enumerate()
                        .filter(|&(k, _)| k != skip)
                        .map(|(_, &v)| v)
                        .collect();
                    index[face.as_slice()]
                })
                .collect();
            column.sort_unstable();
            column
        })
        .collect();
    // pivot[row] = the column whose lowest entry is that row
    let mut pivot: Vec<Option<usize>> = vec![None; simplices.len()];
    for j in 0..columns.len() {
        while let Some(&low) = columns[j].last() {
            match pivot[low] {
                Some(k) => {
                    let other = columns[k].clone();
                    columns[j] = symmetric_difference(&columns[j], &other);
                }
                None => {
                    pivot[low] = Some(j);
                    break;
                }
            }
        }
    }
    let dimension = |i: usize| simplices[i].1.len() - 1;
    let mut diagrams = vec![Vec::new(); build_dim + 1];
    for (j, column) in columns.iter().enumerate() {
        if let Some(&low) = column.last() {
            let (birth, death) = (simplices[low].0, simplices[j].0);
            if death - birth > 1e-15 {
                diagrams[dimension(low)].push((birth, death));
            }
        } else if pivot[j].is_none() {
            diagrams[dimension(j)].push((simplices[j].0, f64::INFINITY));
        }
    }
    diagrams
}

/// Betti numbers at radius r from diagrams: the pairs born at or before r that die after it
pub fn betti_from(diagrams: &[Vec<Pair>], r: f64) -> Vec<usize> {
    diagrams
        .iter()
        .map(|d| d.iter().filter(|p| p.0 <= r && p.1 > r).count())
        .collect()
}

/// The edge lengths of a minimum spanning tree, by Kruskal's algorithm, in increasing order
pub fn spanning_tree(points: &[Vec<f64>]) -> Vec<f64> {
    fn root(parent: &mut [usize], mut i: usize) -> usize {
        while parent[i] != i {
            parent[i] = parent[parent[i]];
            i = parent[i];
        }
        i
    }
    let n = points.len();
    let mut edges: Vec<(f64, usize, usize)> = (0..n)
        .flat_map(|i| (i + 1..n).map(move |j| (i, j)))
        .map(|(i, j)| (distance(&points[i], &points[j]), i, j))
        .collect();
    edges.sort_by(|a, b| a.0.total_cmp(&b.0));
    let mut parent: Vec<usize> = (0..n).collect();
    let mut tree = Vec::new();
    for (d, i, j) in edges {
        let (a, b) = (root(&mut parent, i), root(&mut parent, j));
        if a != b {
            parent[a] = b;
            tree.push(d);
        }
    }
    tree
}

// ─── Distances between diagrams ────────────────────────────────────────────────────────────────────────

fn linf(a: Pair, b: Pair) -> f64 {
    (a.0 - b.0).abs().max((a.1 - b.1).abs())
}

fn split(d: &[Pair]) -> (Vec<Pair>, Vec<f64>) {
    let finite = d.iter().copied().filter(|p| p.1.is_finite()).collect();
    let mut births: Vec<f64> = d
        .iter()
        .filter(|p| p.1.is_infinite())
        .map(|p| p.0)
        .collect();
    births.sort_by(f64::total_cmp);
    (finite, births)
}

/// The matching problem between two diagrams of finite points. Rows are d1's points, then one diagonal slot
/// per point of d2; columns are d2's points, then one slot per point of d1. A point can go to a point of the
/// other diagram, at their L∞ distance, or to its own slot, at its distance to the diagonal, half its
/// persistence; two slots meet at no cost. `None` marks a pair that can't be matched.
fn costs(d1: &[Pair], d2: &[Pair]) -> Vec<Vec<Option<f64>>> {
    let (n1, n2) = (d1.len(), d2.len());
    let size = n1 + n2;
    (0..size)
        .map(|i| {
            (0..size)
                .map(|j| match (i < n1, j < n2) {
                    (true, true) => Some(linf(d1[i], d2[j])),
                    (true, false) => (j - n2 == i).then_some((d1[i].1 - d1[i].0) / 2.0),
                    (false, true) => (i - n1 == j).then_some((d2[j].1 - d2[j].0) / 2.0),
                    (false, false) => Some(0.0),
                })
                .collect()
        })
        .collect()
}

/// Whether every row can get its own column among the allowed pairs: Kuhn's augmenting paths
fn perfect(allowed: &[Vec<bool>]) -> bool {
    fn augment(
        i: usize,
        allowed: &[Vec<bool>],
        seen: &mut [bool],
        owner: &mut [Option<usize>],
    ) -> bool {
        for (j, &ok) in allowed[i].iter().enumerate() {
            if ok && !seen[j] {
                seen[j] = true;
                if owner[j].is_none_or(|k| augment(k, allowed, seen, owner)) {
                    owner[j] = Some(i);
                    return true;
                }
            }
        }
        false
    }
    let n = allowed.len();
    let mut owner = vec![None; n];
    (0..n).all(|i| augment(i, allowed, &mut vec![false; n], &mut owner))
}

/// The assignment of least total cost of a square matrix, row i to column `result[i]`: the Hungarian
/// algorithm with potentials, O(n³)
pub fn hungarian(a: &[Vec<f64>]) -> Vec<usize> {
    let n = a.len();
    let mut u = vec![0.0; n + 1];
    let mut v = vec![0.0; n + 1];
    // p[j] = the row (from 1) assigned to column j (from 1); column 0 holds the row being added
    let mut p = vec![0usize; n + 1];
    let mut way = vec![0usize; n + 1];
    for i in 1..=n {
        p[0] = i;
        let mut j0 = 0;
        let mut minv = vec![f64::INFINITY; n + 1];
        let mut used = vec![false; n + 1];
        loop {
            used[j0] = true;
            let i0 = p[j0];
            let mut delta = f64::INFINITY;
            let mut j1 = 0;
            for j in 1..=n {
                if !used[j] {
                    let cur = a[i0 - 1][j - 1] - u[i0] - v[j];
                    if cur < minv[j] {
                        minv[j] = cur;
                        way[j] = j0;
                    }
                    if minv[j] < delta {
                        delta = minv[j];
                        j1 = j;
                    }
                }
            }
            for j in 0..=n {
                if used[j] {
                    u[p[j]] += delta;
                    v[j] -= delta;
                } else {
                    minv[j] -= delta;
                }
            }
            j0 = j1;
            if p[j0] == 0 {
                break;
            }
        }
        loop {
            let j1 = way[j0];
            p[j0] = p[j1];
            j0 = j1;
            if j0 == 0 {
                break;
            }
        }
    }
    let mut result = vec![0; n];
    for j in 1..=n {
        result[p[j] - 1] = j - 1;
    }
    result
}

/// The bottleneck distance, exactly: the smallest candidate cost at which a perfect matching exists, found by
/// bisection. Essential points are matched among themselves in order of birth, which is optimal on a line;
/// when their numbers differ, no matching exists and the distance is infinite.
pub fn exact_bottleneck(d1: &[Pair], d2: &[Pair]) -> f64 {
    let (f1, e1) = split(d1);
    let (f2, e2) = split(d2);
    if e1.len() != e2.len() {
        return f64::INFINITY;
    }
    let essential = e1
        .iter()
        .zip(&e2)
        .map(|(a, b)| (a - b).abs())
        .fold(0.0, f64::max);
    if f1.is_empty() && f2.is_empty() {
        return essential;
    }
    let c = costs(&f1, &f2);
    let mut candidates: Vec<f64> = c.iter().flatten().flatten().copied().collect();
    candidates.sort_by(f64::total_cmp);
    candidates.dedup();
    let works = |t: f64| {
        let allowed: Vec<Vec<bool>> = c
            .iter()
            .map(|row| row.iter().map(|x| x.is_some_and(|v| v <= t)).collect())
            .collect();
        perfect(&allowed)
    };
    // every point to its own slot is a perfect matching, so the largest candidate works
    let (mut lo, mut hi) = (0, candidates.len() - 1);
    while lo < hi {
        let mid = (lo + hi) / 2;
        if works(candidates[mid]) {
            hi = mid;
        } else {
            lo = mid + 1;
        }
    }
    essential.max(candidates[lo])
}

/// The p-Wasserstein distance with the L∞ distance between points, exactly, by the Hungarian algorithm
pub fn exact_wasserstein(d1: &[Pair], d2: &[Pair], p: f64) -> f64 {
    let (f1, e1) = split(d1);
    let (f2, e2) = split(d2);
    if e1.len() != e2.len() {
        return f64::INFINITY;
    }
    let essential: f64 = e1.iter().zip(&e2).map(|(a, b)| (a - b).abs().powf(p)).sum();
    // a cost no admissible matching comes near, for the pairs that can't be matched
    let barred = 1e9;
    let a: Vec<Vec<f64>> = costs(&f1, &f2)
        .iter()
        .map(|row| {
            row.iter()
                .map(|x| x.map_or(barred, |v| v.powf(p)))
                .collect()
        })
        .collect();
    let finite: f64 = hungarian(&a)
        .iter()
        .enumerate()
        .map(|(i, &j)| a[i][j])
        .sum();
    (finite + essential).powf(1.0 / p)
}

fn diagram(pairs: &[Pair]) -> PersistenceDiagram {
    PersistenceDiagram {
        dimension: 1,
        pairs: pairs.to_vec(),
    }
}

/// IX's `bottleneck_distance` on two lists of pairs
pub fn ix_bottleneck(d1: &[Pair], d2: &[Pair]) -> f64 {
    bottleneck_distance(&diagram(d1), &diagram(d2))
}

/// IX's `wasserstein_distance` on two lists of pairs
pub fn ix_wasserstein(d1: &[Pair], d2: &[Pair], p: f64) -> f64 {
    wasserstein_distance(&diagram(d1), &diagram(d2), p)
}

fn median(mut v: Vec<f64>) -> f64 {
    v.sort_by(f64::total_cmp);
    let n = v.len();
    if n % 2 == 1 {
        v[n / 2]
    } else {
        (v[n / 2 - 1] + v[n / 2]) / 2.0
    }
}

// ─── P1, the reduction ─────────────────────────────────────────────────────────────────────────────────

pub struct Reduction {
    /// IX's H₀ and H₁ equal the reduction written here, pair for pair once sorted
    pub h0_same: bool,
    pub h1_same: bool,
    pub h0_finite: usize,
    pub h0_essential: usize,
    /// The finite deaths of H₀ are the edge lengths of Kruskal's tree, bit for bit
    pub tree_same: bool,
    pub h1_pairs: usize,
    /// The H₁ pairs of persistence above 0.5
    pub loops: Vec<Pair>,
    /// The largest persistence among the other H₁ pairs
    pub largest_other: f64,
    /// The longest of the 24 gaps between neighbours on the circle
    pub longest_gap: f64,
}

pub fn reduction() -> Reduction {
    let points = circle();
    let ix = compute_persistence(&rips_complex(&points, 2, FULL_RADIUS));
    let mine = rips_persistence(&points, 2, FULL_RADIUS);
    let h0 = sorted(&ix[0].pairs);
    let h1 = sorted(&ix[1].pairs);
    let deaths: Vec<f64> = h0.iter().filter(|p| p.1.is_finite()).map(|p| p.1).collect();
    Reduction {
        h0_same: h0 == sorted(&mine[0]),
        h1_same: h1 == sorted(&mine[1]),
        h0_finite: deaths.len(),
        h0_essential: essential(&h0),
        tree_same: deaths == spanning_tree(&points),
        h1_pairs: h1.len(),
        loops: h1.iter().copied().filter(|p| p.1 - p.0 > 0.5).collect(),
        largest_other: h1
            .iter()
            .map(|p| p.1 - p.0)
            .filter(|&q| q <= 0.5)
            .fold(0.0, f64::max),
        longest_gap: (0..POINTS)
            .map(|i| distance(&points[i], &points[(i + 1) % POINTS]))
            .fold(0.0, f64::max),
    }
}

// ─── P2, the top dimension ─────────────────────────────────────────────────────────────────────────────

pub struct TopDimension {
    /// `persistence_from_points(circle, 1, 2.5)`: H₁'s pairs, and how many are essential
    pub h1_with_1: (usize, usize),
    /// `persistence_from_points(circle, 2, 2.5)`: H₁ equals the reduction's, built with triangles
    pub h1_with_2_right: bool,
    pub h1_with_2_essential: usize,
    /// … and H₂'s pairs, and how many are essential
    pub h2_with_2: (usize, usize),
    /// H₂ from the reduction written here, built up to tetrahedra
    pub h2_right: (usize, usize),
    /// `betti_at_radius(square, 1, 1.5)` and `(square, 2, 1.5)`, and the reduction's Betti numbers up to
    /// tetrahedra at 1.5
    pub square_1: Vec<usize>,
    pub square_2: Vec<usize>,
    pub square_right: Vec<usize>,
}

pub fn top_dimension() -> TopDimension {
    let points = circle();
    let with_1 = persistence_from_points(&points, 1, FULL_RADIUS);
    let with_2 = persistence_from_points(&points, 2, FULL_RADIUS);
    let right = rips_persistence(&points, 3, FULL_RADIUS);
    let square_right = rips_persistence(&square(), 3, 1.5);
    TopDimension {
        h1_with_1: (with_1[1].pairs.len(), essential(&with_1[1].pairs)),
        h1_with_2_right: sorted(&with_2[1].pairs) == sorted(&right[1]),
        h1_with_2_essential: essential(&with_2[1].pairs),
        h2_with_2: (with_2[2].pairs.len(), essential(&with_2[2].pairs)),
        h2_right: (right[2].len(), essential(&right[2])),
        square_1: betti_at_radius(&square(), 1, 1.5),
        square_2: betti_at_radius(&square(), 2, 1.5),
        square_right: betti_from(&square_right[..3], 1.5),
    }
}

// ─── P3 and P4, the distances ──────────────────────────────────────────────────────────────────────────

pub struct HandMade {
    /// (IX, exact) for each distance
    pub bottleneck: (f64, f64),
    pub w1: (f64, f64),
    pub w2: (f64, f64),
    /// {(0, ∞)} against an empty diagram: IX's bottleneck, IX's W₂, the exact distance
    pub essential: (f64, f64, f64),
}

pub fn hand_made() -> HandMade {
    let (a1, a2) = ([(0.0, 2.0), (10.0, 11.0)], [(10.0, 12.0), (0.0, 1.0)]);
    let (b1, b2) = ([(0.0, 10.0), (1.0, 2.0)], [(1.0, 10.0), (0.0, 2.0)]);
    let e1 = [(0.0, f64::INFINITY)];
    HandMade {
        bottleneck: (ix_bottleneck(&a1, &a2), exact_bottleneck(&a1, &a2)),
        w1: (
            ix_wasserstein(&b1, &b2, 1.0),
            exact_wasserstein(&b1, &b2, 1.0),
        ),
        w2: (
            ix_wasserstein(&b1, &b2, 2.0),
            exact_wasserstein(&b1, &b2, 2.0),
        ),
        essential: (
            ix_bottleneck(&e1, &[]),
            ix_wasserstein(&e1, &[], 2.0),
            exact_bottleneck(&e1, &[]),
        ),
    }
}

/// Two diagrams of 5 points each, birth uniform on [0, 1] and persistence uniform on [0, 1]
fn random_diagram(rng: &mut Rng) -> Vec<Pair> {
    (0..DIAGRAM_POINTS)
        .map(|_| {
            let birth = rng.next_f64();
            (birth, birth + rng.next_f64())
        })
        .collect()
}

pub struct RandomDiagrams {
    /// Pairs where IX's distance is at least the exact one, to within 1e-12, and above it by more than 1e-9
    pub bottleneck: (usize, usize),
    pub w1: (usize, usize),
    /// Median of IX's distance over the exact one
    pub bottleneck_ratio: f64,
    pub w1_ratio: f64,
}

/// 1,000 pairs of random diagrams from `Rng(19_400)`
pub fn random_diagrams() -> RandomDiagrams {
    let mut rng = Rng(19_400);
    let (mut b, mut w) = ((0, 0), (0, 0));
    let (mut b_ratios, mut w_ratios) = (Vec::new(), Vec::new());
    for _ in 0..DIAGRAM_PAIRS {
        let d1 = random_diagram(&mut rng);
        let d2 = random_diagram(&mut rng);
        for (ix, exact, count, ratios) in [
            (
                ix_bottleneck(&d1, &d2),
                exact_bottleneck(&d1, &d2),
                &mut b,
                &mut b_ratios,
            ),
            (
                ix_wasserstein(&d1, &d2, 1.0),
                exact_wasserstein(&d1, &d2, 1.0),
                &mut w,
                &mut w_ratios,
            ),
        ] {
            count.0 += usize::from(ix >= exact - 1e-12);
            count.1 += usize::from(ix > exact + 1e-9);
            ratios.push(ix / exact);
        }
    }
    RandomDiagrams {
        bottleneck: b,
        w1: w,
        bottleneck_ratio: median(b_ratios),
        w1_ratio: median(w_ratios),
    }
}

// ─── P5, stability ─────────────────────────────────────────────────────────────────────────────────────

/// Cloud t: 24 points uniform in the unit square from `Rng(19_500 + t)`, then the same points each moved by
/// exactly δ in the direction (u, v)/‖(u, v)‖, u and v uniform on [−1, 1], from the next 48 draws
pub fn cloud(t: usize) -> (Vec<Vec<f64>>, Vec<Vec<f64>>) {
    let mut rng = Rng(19_500 + t as u64);
    let points: Vec<Vec<f64>> = (0..POINTS)
        .map(|_| vec![rng.next_f64(), rng.next_f64()])
        .collect();
    let moved = points
        .iter()
        .map(|p| {
            let (u, v) = (2.0 * rng.next_f64() - 1.0, 2.0 * rng.next_f64() - 1.0);
            let norm = (u * u + v * v).sqrt();
            vec![p[0] + DELTA * (u / norm), p[1] + DELTA * (v / norm)]
        })
        .collect();
    (points, moved)
}

pub struct Stability {
    /// Clouds where the exact bottleneck distance between the H₁ diagrams is at most 2δ, to within 1e-12
    pub exact_within: usize,
    /// Clouds where IX's is above 2δ
    pub ix_above: usize,
    pub largest_exact: f64,
    pub largest_ix: f64,
    /// Fewest and most H₁ pairs in a diagram
    pub h1_pairs: (usize, usize),
}

pub fn stability() -> Stability {
    let mut s = Stability {
        exact_within: 0,
        ix_above: 0,
        largest_exact: 0.0,
        largest_ix: 0.0,
        h1_pairs: (usize::MAX, 0),
    };
    for t in 0..CLOUDS {
        let (points, moved) = cloud(t);
        // 1.5 is above the square's diagonal plus 2δ: every simplex is present in both
        let d1 = persistence_from_points(&points, 2, 1.5)[1].pairs.clone();
        let d2 = persistence_from_points(&moved, 2, 1.5)[1].pairs.clone();
        let (exact, ix) = (exact_bottleneck(&d1, &d2), ix_bottleneck(&d1, &d2));
        s.exact_within += usize::from(exact <= 2.0 * DELTA + 1e-12);
        s.ix_above += usize::from(ix > 2.0 * DELTA);
        s.largest_exact = s.largest_exact.max(exact);
        s.largest_ix = s.largest_ix.max(ix);
        for n in [d1.len(), d2.len()] {
            s.h1_pairs = (s.h1_pairs.0.min(n), s.h1_pairs.1.max(n));
        }
    }
    s
}

/// Exploratory: at max_radius 1.0 the circle's loop hasn't died, so it is essential, and
/// `most_persistent_features` keeps finite pairs only. The number of essential H₁ pairs, and the
/// dimension and persistence of the feature it ranks first.
pub fn truncated_loop() -> (usize, usize, f64) {
    let diagrams = persistence_from_points(&circle(), 2, 1.0);
    let top = most_persistent_features(&diagrams, 1)[0];
    (essential(&diagrams[1].pairs), top.0, top.3)
}

// ─── P6 and P7, t-SNE ──────────────────────────────────────────────────────────────────────────────────

/// Points of the t-SNE data, in three clusters
pub const TSNE_POINTS: usize = 150;

/// 150 points in 10 dimensions, clusters of 50 around 0, 10·e₁ and 10·e₂, with the course's approximate
/// normal noise from `Rng(19_600)`; and each point's cluster
pub fn blobs() -> (Array2<f64>, Vec<usize>) {
    let mut rng = Rng(19_600);
    let x = Array2::from_shape_fn((TSNE_POINTS, 10), |(i, j)| {
        let cluster = i / 50;
        let centre = if cluster > 0 && j == cluster - 1 {
            10.0
        } else {
            0.0
        };
        centre + normal(&mut rng)
    });
    (x, (0..TSNE_POINTS).map(|i| i / 50).collect())
}

/// The share of points whose 5 nearest neighbours in the embedding vote for their own cluster; a tie goes to
/// the lowest cluster
pub fn vote(y: &Array2<f64>, labels: &[usize]) -> f64 {
    let n = y.nrows();
    let right = (0..n)
        .filter(|&i| {
            let mut others: Vec<(f64, usize)> = (0..n)
                .filter(|&j| j != i)
                .map(|j| (squared(y.row(i), y.row(j)), j))
                .collect();
            others.sort_by(|a, b| a.0.total_cmp(&b.0));
            let mut counts = [0usize; 3];
            for &(_, j) in &others[..5] {
                counts[labels[j]] += 1;
            }
            let best = (0..3)
                .max_by_key(|&c| (counts[c], std::cmp::Reverse(c)))
                .expect("three clusters");
            best == labels[i]
        })
        .count();
    right as f64 / n as f64
}

fn largest_gap(a: &Array2<f64>, b: &Array2<f64>) -> f64 {
    a.iter()
        .zip(b)
        .fold(0.0f64, |m, (x, y)| m.max((x - y).abs()))
}

pub struct Seeds {
    /// The largest coordinate difference between two Barnes–Hut runs with the same seed
    pub barnes_hut_gap: f64,
    /// Each run's 5-nearest-neighbour vote
    pub votes: (f64, f64),
    /// Two exact runs with the same seed are equal bit for bit
    pub exact_identical: bool,
    /// Exploratory, measured after the first run: the votes of two Barnes–Hut runs on the same points
    /// scaled by 0.3
    pub scaled_votes: (f64, f64),
}

/// How much the exploratory check shrinks the points: bhtsne 0.5.3 starts its bandwidth search at β = 1 and,
/// when the entropy is below the target, moves β up instead of down (`zero_point_five` is 5.0), so the search
/// only works when β = 1 already gives an entropy above ln(perplexity), a flatter distribution than the target
pub const SHRINK: f64 = 0.3;

pub fn seeds() -> Seeds {
    let (x, labels) = blobs();
    let bh = |x: &Array2<f64>| BarnesHutTsne::new().with_seed(7).fit_transform(x.view());
    let (a, b) = (bh(&x), bh(&x));
    let exact = || {
        Tsne::new()
            .with_seed(7)
            .with_n_iter(300)
            .fit_transform(x.view())
    };
    let shrunk = &x * SHRINK;
    Seeds {
        barnes_hut_gap: largest_gap(&a, &b),
        votes: (vote(&a, &labels), vote(&b, &labels)),
        exact_identical: exact() == exact(),
        scaled_votes: (vote(&bh(&shrunk), &labels), vote(&bh(&shrunk), &labels)),
    }
}

/// t-SNE's P: each row's precision found by bisection until the entropy is ln(perplexity) to within 1e-10,
/// then symmetrized, (P + Pᵀ)/2n
pub fn affinities(x: &Array2<f64>, perplexity: f64) -> Array2<f64> {
    let n = x.nrows();
    let target = perplexity.ln();
    let mut p = Array2::<f64>::zeros((n, n));
    for i in 0..n {
        let d: Vec<f64> = (0..n).map(|j| squared(x.row(i), x.row(j))).collect();
        let nearest = (0..n)
            .filter(|&j| j != i)
            .map(|j| d[j])
            .fold(f64::INFINITY, f64::min);
        let (mut lo, mut hi, mut beta) = (0.0f64, f64::INFINITY, 1.0f64);
        let mut row = vec![0.0; n];
        for _ in 0..200 {
            for (j, r) in row.iter_mut().enumerate() {
                // shifted by the nearest distance, which cancels in the normalization
                *r = if j == i {
                    0.0
                } else {
                    (-(d[j] - nearest) * beta).exp()
                };
            }
            let sum: f64 = row.iter().sum();
            let mut entropy = 0.0;
            for r in row.iter_mut() {
                *r /= sum;
                if *r > 0.0 {
                    entropy -= *r * r.ln();
                }
            }
            if (entropy - target).abs() < 1e-10 {
                break;
            }
            if entropy > target {
                lo = beta;
                beta = if hi.is_finite() {
                    (beta + hi) / 2.0
                } else {
                    beta * 2.0
                };
            } else {
                hi = beta;
                beta = (beta + lo) / 2.0;
            }
        }
        for (j, r) in row.into_iter().enumerate() {
            p[[i, j]] = r;
        }
    }
    (&p + &p.t()) / (2.0 * n as f64)
}

/// KL(P‖Q) of an embedding, Q from the Student-t kernel (1 + ‖yᵢ − yⱼ‖²)⁻¹
pub fn kl(p: &Array2<f64>, y: &Array2<f64>) -> f64 {
    let n = y.nrows();
    let w = Array2::from_shape_fn((n, n), |(i, j)| {
        if i == j {
            0.0
        } else {
            1.0 / (1.0 + squared(y.row(i), y.row(j)))
        }
    });
    let z = w.sum();
    p.iter()
        .zip(&w)
        .filter(|(pv, _)| **pv > 0.0)
        .map(|(pv, wv)| pv * (pv / (wv / z)).ln())
        .sum()
}

pub struct Exaggeration {
    /// `Tsne::new().with_n_iter(200)` equals `.with_early_exaggeration(12.0, 200)`, bit for bit
    pub never_ends: bool,
    /// KL(P‖Q) with the default, with exaggeration for the first 50 of 200 iterations, and exploratory, with
    /// the default 1,000 iterations; the values differ between Windows, Linux and macOS
    pub kl_default: f64,
    pub kl_quarter: f64,
    pub kl_1000: f64,
}

pub fn exaggeration() -> Exaggeration {
    let (x, _) = blobs();
    let p = affinities(&x, 30.0);
    let base = || Tsne::new().with_seed(7).with_n_iter(200);
    let default = base().fit_transform(x.view());
    let throughout = base()
        .with_early_exaggeration(12.0, 200)
        .fit_transform(x.view());
    let quarter = base()
        .with_early_exaggeration(12.0, 50)
        .fit_transform(x.view());
    let long = Tsne::new().with_seed(7).fit_transform(x.view());
    Exaggeration {
        never_ends: default == throughout,
        kl_default: kl(&p, &default),
        kl_quarter: kl(&p, &quarter),
        kl_1000: kl(&p, &long),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Every assignment of a small matching problem, for the bottleneck and W₁ values
    fn brute(d1: &[Pair], d2: &[Pair]) -> (f64, f64) {
        fn permutations(
            k: usize,
            perm: &mut Vec<usize>,
            used: &mut [bool],
            out: &mut Vec<Vec<usize>>,
        ) {
            if perm.len() == k {
                out.push(perm.clone());
                return;
            }
            for j in 0..k {
                if !used[j] {
                    used[j] = true;
                    perm.push(j);
                    permutations(k, perm, used, out);
                    perm.pop();
                    used[j] = false;
                }
            }
        }
        let c = costs(d1, d2);
        let k = c.len();
        let mut all = Vec::new();
        permutations(k, &mut Vec::new(), &mut vec![false; k], &mut all);
        let (mut best_max, mut best_sum) = (f64::INFINITY, f64::INFINITY);
        for perm in all {
            let chosen: Option<Vec<f64>> = perm.iter().enumerate().map(|(i, &j)| c[i][j]).collect();
            if let Some(chosen) = chosen {
                best_max = best_max.min(chosen.iter().copied().fold(0.0, f64::max));
                best_sum = best_sum.min(chosen.iter().sum());
            }
        }
        (best_max, best_sum)
    }

    #[test]
    fn the_exact_distances_agree_with_every_assignment() {
        let mut rng = Rng(19_000);
        for _ in 0..200 {
            let n1 = 1 + (rng.next_f64() * 3.0) as usize;
            let n2 = (rng.next_f64() * 3.0) as usize;
            let d1: Vec<Pair> = (0..n1).map(|_| random_diagram(&mut rng)[0]).collect();
            let d2: Vec<Pair> = (0..n2).map(|_| random_diagram(&mut rng)[0]).collect();
            let (b, w) = brute(&d1, &d2);
            assert!((exact_bottleneck(&d1, &d2) - b).abs() < 1e-12);
            assert!((exact_wasserstein(&d1, &d2, 1.0) - w).abs() < 1e-12);
        }
    }

    #[test]
    fn p1_the_reduction_is_the_standard_one() {
        let r = reduction();
        assert!(r.h0_same && r.h1_same && r.tree_same);
        assert_eq!((r.h0_finite, r.h0_essential), (23, 1));
        assert_eq!(r.loops.len(), 1, "{:?}", r.loops);
        let (birth, death) = r.loops[0];
        assert!((0.25..=0.35).contains(&birth), "{birth}");
        assert!((1.5..=1.95).contains(&death), "{death}");
    }

    #[test]
    fn p2_the_top_dimension_has_no_cofaces() {
        let t = top_dimension();
        assert_eq!(t.h1_with_1, (253, 253));
        assert!(t.h1_with_2_right);
        assert_eq!(t.h1_with_2_essential, 0);
        assert_eq!(t.h2_with_2, (1771, 1771));
        assert_eq!(t.square_1, [1, 3]);
        assert_eq!(t.square_2, [1, 0, 1]);
        assert_eq!(t.square_right, [1, 0, 0]);
    }

    #[test]
    fn p3_two_distances_on_hand_made_diagrams() {
        let h = hand_made();
        assert_eq!(h.bottleneck, (10.0, 1.0));
        assert_eq!(h.w1, (16.0, 2.0));
        assert!((h.w2.0 - 128f64.sqrt()).abs() < 1e-12, "{}", h.w2.0);
        assert!((h.w2.1 - 2f64.sqrt()).abs() < 1e-12, "{}", h.w2.1);
        assert_eq!(h.essential, (0.0, 0.0, f64::INFINITY));
    }

    #[test]
    fn p4_random_diagrams() {
        let r = random_diagrams();
        assert_eq!(r.bottleneck.0, DIAGRAM_PAIRS);
        assert_eq!(r.w1.0, DIAGRAM_PAIRS);
        assert!(r.bottleneck.1 >= 900, "{}", r.bottleneck.1);
        assert!(r.w1.1 >= 900, "{}", r.w1.1);
    }

    #[test]
    fn p5_stability() {
        let s = stability();
        assert_eq!(s.exact_within, CLOUDS);
        assert!(s.ix_above >= 5, "{}", s.ix_above);
    }

    #[test]
    fn p6_barnes_hut_ignores_its_seed() {
        let s = seeds();
        assert!(s.barnes_hut_gap > 1e-3, "{}", s.barnes_hut_gap);
        assert!(s.exact_identical);
        // Refuted: the prediction said at least 0.95 for both runs. The first run measured 0.267 and 0.347,
        // near the 1/3 of a random embedding, so the test now pins that: bhtsne 0.5.3's bandwidth search
        // diverges on these distances and P degenerates.
        assert!(s.votes.0 < 0.6 && s.votes.1 < 0.6, "{:?}", s.votes);
        // exploratory: the same points scaled by 0.3
        assert!(
            s.scaled_votes.0 >= 0.95 && s.scaled_votes.1 >= 0.95,
            "{:?}",
            s.scaled_votes
        );
    }

    #[test]
    fn p7_early_exaggeration_never_ends_below_250_iterations() {
        let e = exaggeration();
        assert!(e.never_ends);
        assert!(
            e.kl_default > e.kl_quarter,
            "{} {}",
            e.kl_default,
            e.kl_quarter
        );
    }
}
