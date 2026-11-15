//! Lesson 20: IX's `ix-gpu`. Its shaders through naga, a port of its kNN shader's loop against IX's own
//! `batch_knn_cpu`, its two cosine thresholds and the limits of `Limits::default()` run anywhere; the functions
//! that take a `GpuContext` need an adapter, and only the `l20_on_gpu` program and the ignored tests call them.
//!
//! P4: the three imports of IX's `ix-gpu` skill page (`.claude/skills/ix-gpu/SKILL.md`, lines 28-30) don't
//! compile, because the crate exports functions, not these types:
//!
//! ```compile_fail,E0432
//! use ix_gpu::similarity::GpuCosineSimilarity;
//! ```
//!
//! ```compile_fail,E0432
//! use ix_gpu::matmul::GpuMatMul;
//! ```
//!
//! ```compile_fail,E0432
//! use ix_gpu::distance::GpuDistanceMatrix;
//! ```
//!
//! The fourth line of the page does:
//!
//! ```
//! use ix_gpu::context::GpuContext;
//! ```

pub mod shaders;

use crate::autodiff::Rng;
use ix_gpu::batch::{batch_top_k, similarity_matrix};
use ix_gpu::context::GpuContext;
use ix_gpu::distance::{pairwise_distance_cpu, pairwise_distance_gpu};
use ix_gpu::knn::{batch_knn_cpu, batch_knn_gpu};
use ix_gpu::matmul::{matmul_cpu, matmul_gpu};
use ix_gpu::similarity::{cosine_similarity_cpu, cosine_similarity_gpu};
use std::time::Instant;
use wgpu::naga;

/// Threads in a workgroup of the kNN shader, so candidates per query
pub const THREADS: usize = 256;
/// P2's data: references and queries uniform in [0, 1)^DIM, and the k of the search
pub const DIM: usize = 8;
pub const REFS: usize = 1000;
pub const QUERIES: usize = 1000;
pub const K: usize = 10;

/// What naga's WGSL front end and validator say of one shader
pub struct Naga {
    pub parse_error: Option<String>,
    pub valid: bool,
    pub workgroup_variables: usize,
}

pub fn naga_check(source: &str) -> Naga {
    match naga::front::wgsl::parse_str(source) {
        Err(e) => Naga {
            parse_error: Some(e.message().to_string()),
            valid: false,
            workgroup_variables: 0,
        },
        Ok(module) => Naga {
            parse_error: None,
            valid: naga::valid::Validator::new(
                naga::valid::ValidationFlags::all(),
                naga::valid::Capabilities::default(),
            )
            .validate(&module)
            .is_ok(),
            workgroup_variables: module
                .global_variables
                .iter()
                .filter(|(_, v)| v.space == naga::AddressSpace::WorkGroup)
                .count(),
        },
    }
}

/// The five shaders, with the dot product's also checked with `shared` renamed
pub fn shader_checks() -> Vec<(&'static str, Naga)> {
    vec![
        ("cosine", naga_check(shaders::COSINE)),
        ("dot product", naga_check(shaders::DOT_PRODUCT)),
        (
            "dot product, `shared` renamed",
            naga_check(&shaders::DOT_PRODUCT.replace("shared", "partial")),
        ),
        ("distance matrix", naga_check(shaders::DISTANCE_MATRIX)),
        ("kNN", naga_check(shaders::KNN)),
        ("matrix product", naga_check(shaders::MATMUL)),
    ]
}

/// `n` points of `dim` coordinates uniform in [0, 1), rounded to f32, from `Rng(seed)`, row after row
pub fn uniform_points(seed: u64, n: usize, dim: usize) -> Vec<f32> {
    let mut rng = Rng(seed);
    (0..n * dim).map(|_| rng.next_f64() as f32).collect()
}

/// P2's references and queries: `Rng(20_200)` and `Rng(20_201)`
pub fn knn_data() -> (Vec<f32>, Vec<f32>) {
    (
        uniform_points(20_200, REFS, DIM),
        uniform_points(20_201, QUERIES, DIM),
    )
}

/// The loop of IX's kNN shader on the CPU, in the same order of operations: thread t keeps the nearest of the
/// references t, t + 256, …, the first on a tie; then, as `batch_knn_gpu` does, the 256 candidates are sorted
/// by distance and the first k kept, padded with `u32::MAX` if there are fewer.
pub fn knn_shader_port(
    refs: &[f32],
    queries: &[f32],
    dim: usize,
    k: usize,
) -> (Vec<u32>, Vec<f32>) {
    let num_refs = refs.len() / dim;
    let mut indices = Vec::new();
    let mut distances = Vec::new();
    for query in queries.chunks(dim) {
        let mut candidates = Vec::with_capacity(THREADS);
        for tid in 0..THREADS {
            let mut best = (f32::MAX, 0u32);
            let mut i = tid;
            while i < num_refs {
                let mut sum = 0.0f32;
                for d in 0..dim {
                    let diff = query[d] - refs[i * dim + d];
                    sum += diff * diff;
                }
                let dist = sum.sqrt();
                if dist < best.0 {
                    best = (dist, i as u32);
                }
                i += THREADS;
            }
            // The shader writes a thread's best only if the thread had references to scan
            if tid < num_refs || tid == 0 {
                candidates.push(best);
            }
        }
        candidates.retain(|c| c.0 < f32::MAX / 2.0);
        candidates.sort_by(|a, b| a.0.partial_cmp(&b.0).unwrap_or(std::cmp::Ordering::Equal));
        for j in 0..k {
            let (dist, index) = candidates
                .get(j)
                .copied()
                .unwrap_or((f32::INFINITY, u32::MAX));
            indices.push(index);
            distances.push(dist);
        }
    }
    (indices, distances)
}

/// Queries whose k indices, taken as sets, differ between two results
pub fn differing_sets(a: &[u32], b: &[u32], k: usize) -> usize {
    a.chunks(k)
        .zip(b.chunks(k))
        .filter(|(x, y)| {
            let (mut x, mut y) = (x.to_vec(), y.to_vec());
            x.sort_unstable();
            y.sort_unstable();
            x != y
        })
        .count()
}

/// Indices of `a` found in the same query's set of `b`, over all queries
pub fn recovered(a: &[u32], b: &[u32], k: usize) -> usize {
    a.chunks(k)
        .zip(b.chunks(k))
        .map(|(x, y)| x.iter().filter(|i| y.contains(i)).count())
        .sum()
}

/// P(the k nearest of n references don't fall in k distinct classes modulo 256), when their indices are a
/// uniform k-subset: 1 − e_k(class sizes)/C(n, k)
pub fn p_wrong(n: usize, k: usize) -> f64 {
    let mut e = vec![0.0f64; k + 1];
    e[0] = 1.0;
    for t in 0..THREADS {
        let size = (n / THREADS + usize::from(t < n % THREADS)) as f64;
        for j in (1..=k).rev() {
            e[j] += e[j - 1] * size;
        }
    }
    let choose = (0..k).fold(1.0, |c, i| c * (n - i) as f64 / (i + 1) as f64);
    1.0 - e[k] / choose
}

pub struct KnnPort {
    pub p_wrong: f64,
    /// Queries whose 10 nearest differ from `batch_knn_cpu`'s: all references, k = 1, the first 256
    pub differ: usize,
    pub differ_k1: usize,
    pub differ_first_256: usize,
    /// Of the QUERIES × K true neighbours, those the port returns
    pub recovered: usize,
}

pub fn knn_port() -> KnnPort {
    let (refs, queries) = knn_data();
    let first = &refs[..THREADS * DIM];
    let port = knn_shader_port(&refs, &queries, DIM, K).0;
    let exact = batch_knn_cpu(&refs, &queries, DIM, K).0;
    let differ = |r: &[f32], k| {
        differing_sets(
            &knn_shader_port(r, &queries, DIM, k).0,
            &batch_knn_cpu(r, &queries, DIM, k).0,
            k,
        )
    };
    KnnPort {
        p_wrong: p_wrong(REFS, K),
        differ: differing_sets(&port, &exact, K),
        differ_k1: differ(&refs, 1),
        differ_first_256: differ(first, K),
        recovered: recovered(&exact, &port, K),
    }
}

/// P3: the same two vectors of tiny norm through three functions, and the zero vector through two
pub struct Thresholds {
    pub cosine: f32,
    pub matrix: f32,
    pub batch: f32,
    pub zero_diagonal: f32,
    pub zero_cosine: f32,
}

pub fn thresholds() -> Thresholds {
    let a = vec![1e-6f32, 2e-6, 2e-6];
    let b: Vec<f32> = a.iter().map(|x| 2.0 * x).collect();
    let z = vec![0.0f32; 3];
    Thresholds {
        cosine: cosine_similarity_cpu(&a, &b),
        matrix: similarity_matrix(None, &[a.clone(), b.clone()])[0][1],
        batch: batch_top_k(None, std::slice::from_ref(&a), std::slice::from_ref(&b), 1)[0][0].1,
        zero_diagonal: similarity_matrix(None, &[z.clone(), b])[0][0],
        zero_cosine: cosine_similarity_cpu(&z, &z),
    }
}

/// P5: what `Limits::default()` allows, and the largest n whose n × n f32 matrix fits in one storage binding
pub struct Limits {
    pub binding: u64,
    pub buffer: u64,
    pub workgroups: u32,
    pub largest_square: u64,
}

pub fn limits() -> Limits {
    let l = wgpu::Limits::default();
    let binding = u64::from(l.max_storage_buffer_binding_size);
    Limits {
        binding,
        buffer: l.max_buffer_size,
        workgroups: l.max_compute_workgroups_per_dimension,
        largest_square: (1..)
            .take_while(|n: &u64| 4 * n * n <= binding)
            .last()
            .unwrap_or(0),
    }
}

/// Bytes of an n × n f32 matrix
pub fn square_bytes(n: u64) -> u64 {
    4 * n * n
}

/// Uniform in [−1, 1), in f32, from `Rng(seed)`
pub fn signed(seed: u64, n: usize) -> Vec<f32> {
    let mut rng = Rng(seed);
    (0..n)
        .map(|_| (2.0 * rng.next_f64() - 1.0) as f32)
        .collect()
}

/// Everything below needs an adapter.
///
/// P1 on a GPU: the largest gap between `cosine_similarity_gpu` and `cosine_similarity_cpu`, over the vectors
/// of `Rng(20_100)` and `Rng(20_101)`, 1,000 components each
pub fn cosine_gap(ctx: &GpuContext) -> f32 {
    let (a, b) = (signed(20_100, 1000), signed(20_101, 1000));
    (cosine_similarity_gpu(ctx, &a, &b) - cosine_similarity_cpu(&a, &b)).abs()
}

/// P6: the GPU's kNN against the port and against `batch_knn_cpu`, on P2's data
pub struct KnnGpu {
    /// Queries whose 10 indices equal the port's, in the same order
    pub same_as_port: usize,
    pub largest_distance_gap: f32,
    pub differ_from_cpu: usize,
    pub port_differ_from_cpu: usize,
    /// With the first 256 references: queries whose indices equal `batch_knn_cpu`'s, in order
    pub first_256_same_as_cpu: usize,
}

pub fn knn_on_gpu(ctx: &GpuContext) -> KnnGpu {
    let (refs, queries) = knn_data();
    let (gpu, gpu_dist) = batch_knn_gpu(ctx, &refs, &queries, DIM, K);
    let (port, port_dist) = knn_shader_port(&refs, &queries, DIM, K);
    let cpu = batch_knn_cpu(&refs, &queries, DIM, K).0;
    let first = &refs[..THREADS * DIM];
    let first_gpu = batch_knn_gpu(ctx, first, &queries, DIM, K).0;
    let first_cpu = batch_knn_cpu(first, &queries, DIM, K).0;
    let same = |a: &[u32], b: &[u32]| a.chunks(K).zip(b.chunks(K)).filter(|(x, y)| x == y).count();
    KnnGpu {
        same_as_port: same(&gpu, &port),
        largest_distance_gap: gpu_dist
            .iter()
            .zip(&port_dist)
            .map(|(g, p)| (g - p).abs())
            .fold(0.0, f32::max),
        differ_from_cpu: differing_sets(&gpu, &cpu, K),
        port_differ_from_cpu: differing_sets(&port, &cpu, K),
        first_256_same_as_cpu: same(&first_gpu, &first_cpu),
    }
}

/// `matmul_cpu`'s loop with each multiply and add fused into one rounding, as WGSL allows a GPU to compile it
pub fn matmul_fused(a: &[f32], b: &[f32], m: usize, k: usize, n: usize) -> Vec<f32> {
    let mut c = vec![0.0f32; m * n];
    for i in 0..m {
        for j in 0..n {
            let mut sum = 0.0f32;
            for p in 0..k {
                sum = a[i * k + p].mul_add(b[p * n + j], sum);
            }
            c[i * n + j] = sum;
        }
    }
    c
}

/// `pairwise_distance_cpu`'s loop with each square and add fused into one rounding
pub fn distances_fused(points: &[f32], dim: usize) -> Vec<f32> {
    let n = points.len() / dim;
    let mut out = vec![0.0f32; n * n];
    for i in 0..n {
        for j in 0..n {
            let mut sum = 0.0f32;
            for d in 0..dim {
                let diff = points[i * dim + d] - points[j * dim + d];
                sum = diff.mul_add(diff, sum);
            }
            out[i * n + j] = sum.sqrt();
        }
    }
    out
}

/// P7: the GPU's sums against the CPU's; exploratory, against the same loops with fused multiply-adds
pub struct Sums {
    pub matmul_differing: usize,
    pub matmul_largest_gap: f32,
    pub matmul_differing_from_fused: usize,
    pub distance_differing: usize,
    pub distance_largest_gap: f32,
    pub distance_differing_from_fused: usize,
    pub distance_diagonal_zero: bool,
}

/// A and B of 256 × 256 from `Rng(20_700)` and `Rng(20_701)`; distances between P2's references
pub fn sums_on_gpu(ctx: &GpuContext) -> Sums {
    let n = 256;
    let (a, b) = (signed(20_700, n * n), signed(20_701, n * n));
    let gpu = matmul_gpu(ctx, &a, &b, n, n, n);
    let cpu = matmul_cpu(&a, &b, n, n, n);
    let (refs, _) = knn_data();
    let dg = pairwise_distance_gpu(ctx, &refs, DIM);
    let dc = pairwise_distance_cpu(&refs, DIM);
    let gap = |x: &[f32], y: &[f32]| {
        x.iter()
            .zip(y)
            .map(|(p, q)| (p - q).abs())
            .fold(0.0, f32::max)
    };
    let differing = |x: &[f32], y: &[f32]| x.iter().zip(y).filter(|(p, q)| p != q).count();
    Sums {
        matmul_differing: differing(&gpu, &cpu),
        matmul_largest_gap: gap(&gpu, &cpu),
        matmul_differing_from_fused: differing(&gpu, &matmul_fused(&a, &b, n, n, n)),
        distance_differing: differing(&dg, &dc),
        distance_largest_gap: gap(&dg, &dc),
        distance_differing_from_fused: differing(&dg, &distances_fused(&refs, DIM)),
        distance_diagonal_zero: (0..REFS).all(|i| dg[i * REFS + i] == 0.0),
    }
}

/// Exploratory, P3's vectors through `similarity_matrix` with a context: the tiny pair and the zero diagonal
pub fn thresholds_on_gpu(ctx: &GpuContext) -> (f32, f32) {
    let a = vec![1e-6f32, 2e-6, 2e-6];
    let b: Vec<f32> = a.iter().map(|x| 2.0 * x).collect();
    let z = vec![0.0f32; 3];
    (
        similarity_matrix(Some(ctx), &[a, b.clone()])[0][1],
        similarity_matrix(Some(ctx), &[z, b])[0][0],
    )
}

/// Median of 5 timed calls after one untimed warm-up, in milliseconds
pub fn median_ms(mut f: impl FnMut()) -> f64 {
    f();
    let mut times: Vec<f64> = (0..5)
        .map(|_| {
            let start = Instant::now();
            f();
            start.elapsed().as_secs_f64() * 1e3
        })
        .collect();
    times.sort_by(f64::total_cmp);
    times[2]
}

/// P8: `matmul_cpu` and `matmul_gpu` on an m × k by k × n product, data from `Rng(20_800)` and `Rng(20_801)`,
/// in milliseconds
pub fn matmul_times(ctx: &GpuContext, m: usize, k: usize, n: usize) -> (f64, f64) {
    let (a, b) = (signed(20_800, m * k), signed(20_801, k * n));
    let cpu = median_ms(|| {
        std::hint::black_box(matmul_cpu(&a, &b, m, k, n));
    });
    let gpu = median_ms(|| {
        std::hint::black_box(matmul_gpu(ctx, &a, &b, m, k, n));
    });
    (cpu, gpu)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn p1_naga_rejects_shared_and_the_matrix_product_has_no_tile() {
        let checks = shader_checks();
        let find = |name: &str| &checks.iter().find(|(n, _)| *n == name).unwrap().1;
        let dot = find("dot product");
        assert_eq!(
            dot.parse_error.as_deref(),
            Some("name `shared` is a reserved keyword")
        );
        assert!(find("dot product, `shared` renamed").valid);
        for name in ["cosine", "distance matrix", "kNN", "matrix product"] {
            let check = find(name);
            assert!(check.parse_error.is_none() && check.valid, "{name}");
        }
        assert_eq!(find("matrix product").workgroup_variables, 0);
    }

    #[test]
    fn p2_the_port_loses_neighbours_that_share_a_class() {
        let port = knn_port();
        assert!((port.p_wrong - 0.1253).abs() < 5e-5, "{}", port.p_wrong);
        assert!(
            (90..=160).contains(&port.differ),
            "{} queries differ",
            port.differ
        );
        assert_eq!(port.differ_k1, 0);
        assert_eq!(port.differ_first_256, 0);
    }

    #[test]
    fn p3_two_thresholds_and_a_diagonal() {
        let t = thresholds();
        assert!((t.cosine - 1.0).abs() <= 1e-6, "{}", t.cosine);
        assert!((t.matrix - 1.0).abs() <= 1e-6, "{}", t.matrix);
        assert_eq!(t.batch, 0.0);
        assert_eq!(t.zero_diagonal, 1.0);
        assert_eq!(t.zero_cosine, 0.0);
    }

    #[test]
    fn p5_the_default_limits() {
        let l = limits();
        assert_eq!(l.binding, 134_217_728);
        assert_eq!(l.largest_square, 5_792);
        assert_eq!(square_bytes(5_792), 134_189_056);
        assert_eq!(square_bytes(5_793), 134_235_396);
        assert!(square_bytes(10_000) > l.buffer);
        assert_eq!(l.workgroups, 65_535);
    }

    #[test]
    fn the_port_equals_batch_knn_cpu_when_classes_hold_one_reference() {
        let queries = uniform_points(20_202, 50, 3);
        let refs = uniform_points(20_203, 200, 3);
        for k in [1, 5, 200, 250] {
            assert_eq!(
                knn_shader_port(&refs, &queries, 3, k),
                batch_knn_cpu(&refs, &queries, 3, k),
                "k = {k}"
            );
        }
    }

    #[test]
    fn p_wrong_matches_a_count_on_a_small_case() {
        // 6 references, 256 threads: every class holds at most one, so the k nearest are always right
        assert!(p_wrong(6, 3).abs() < 1e-12);
        // 512 references, k = 2: every class holds two, so 256 of the C(512, 2) pairs share a class
        let expected = 256.0 / (512.0 * 511.0 / 2.0);
        assert!((p_wrong(512, 2) - expected).abs() < 1e-12);
    }
}
