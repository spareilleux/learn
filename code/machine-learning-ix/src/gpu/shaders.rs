//! Lesson 20: the five WGSL shaders of `ix-gpu` that the lesson checks, copied byte for byte from IX's pinned
//! commit, since the crate keeps them private. The lesson's journal records the comparison with IX.

/// `COSINE_SHADER`: dot(a, b), |a|² and |b|² in one workgroup, for `cosine_similarity_gpu` ([`similarity.rs` 12-73](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/similarity.rs#L12-L73))
pub const COSINE: &str = r#"
@group(0) @binding(0) var<storage, read> a: array<f32>;
@group(0) @binding(1) var<storage, read> b: array<f32>;
@group(0) @binding(2) var<storage, read_write> result: array<f32>;
// result[0] = dot(a,b), result[1] = |a|^2, result[2] = |b|^2

var<workgroup> shared_dot: array<f32, 256>;
var<workgroup> shared_norm_a: array<f32, 256>;
var<workgroup> shared_norm_b: array<f32, 256>;

@compute @workgroup_size(256)
fn cosine_similarity(
    @builtin(global_invocation_id) global_id: vec3<u32>,
    @builtin(local_invocation_id) local_id: vec3<u32>,
    @builtin(workgroup_id) wg_id: vec3<u32>,
) {
    let tid = local_id.x;
    let gid = global_id.x;
    let n = arrayLength(&a);

    // Each thread accumulates partial sums
    var dot_sum: f32 = 0.0;
    var norm_a_sum: f32 = 0.0;
    var norm_b_sum: f32 = 0.0;

    // Grid-stride loop for vectors larger than workgroup
    var i = gid;
    while (i < n) {
        let ai = a[i];
        let bi = b[i];
        dot_sum += ai * bi;
        norm_a_sum += ai * ai;
        norm_b_sum += bi * bi;
        i += 256u * 1u; // stride = workgroup_size * num_workgroups
    }

    shared_dot[tid] = dot_sum;
    shared_norm_a[tid] = norm_a_sum;
    shared_norm_b[tid] = norm_b_sum;

    workgroupBarrier();

    // Parallel reduction
    var stride = 128u;
    while (stride > 0u) {
        if (tid < stride) {
            shared_dot[tid] += shared_dot[tid + stride];
            shared_norm_a[tid] += shared_norm_a[tid + stride];
            shared_norm_b[tid] += shared_norm_b[tid + stride];
        }
        workgroupBarrier();
        stride = stride >> 1u;
    }

    // Thread 0 writes result
    if (tid == 0u) {
        result[0] = shared_dot[0];
        result[1] = shared_norm_a[0];
        result[2] = shared_norm_b[0];
    }
}
"#;

/// `DOT_PRODUCT_SHADER`: dot(a, b) in one workgroup, for `dot_product_gpu` ([`similarity.rs` 76-115](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/similarity.rs#L76-L115))
pub const DOT_PRODUCT: &str = r#"
@group(0) @binding(0) var<storage, read> a: array<f32>;
@group(0) @binding(1) var<storage, read> b: array<f32>;
@group(0) @binding(2) var<storage, read_write> result: array<f32>;

var<workgroup> shared: array<f32, 256>;

@compute @workgroup_size(256)
fn dot_product(
    @builtin(global_invocation_id) global_id: vec3<u32>,
    @builtin(local_invocation_id) local_id: vec3<u32>,
) {
    let tid = local_id.x;
    let gid = global_id.x;
    let n = arrayLength(&a);

    var sum: f32 = 0.0;
    var i = gid;
    while (i < n) {
        sum += a[i] * b[i];
        i += 256u;
    }

    shared[tid] = sum;
    workgroupBarrier();

    var stride = 128u;
    while (stride > 0u) {
        if (tid < stride) {
            shared[tid] += shared[tid + stride];
        }
        workgroupBarrier();
        stride = stride >> 1u;
    }

    if (tid == 0u) {
        result[0] = shared[0];
    }
}
"#;

/// `DISTANCE_MATRIX_SHADER`: the n × n Euclidean distances, for `pairwise_distance_gpu` ([`distance.rs` 29-55](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/distance.rs#L29-L55))
pub const DISTANCE_MATRIX: &str = r#"
@group(0) @binding(0) var<storage, read> points: array<f32>;
@group(0) @binding(1) var<storage, read> params: array<u32>;  // [num_points, dim]
@group(0) @binding(2) var<storage, read_write> distances: array<f32>;

@compute @workgroup_size(16, 16)
fn pairwise_distance(
    @builtin(global_invocation_id) global_id: vec3<u32>,
) {
    let n = params[0];
    let dim = params[1];
    let i = global_id.x;
    let j = global_id.y;

    if (i >= n || j >= n) {
        return;
    }

    var sum: f32 = 0.0;
    for (var d = 0u; d < dim; d++) {
        let diff = points[i * dim + d] - points[j * dim + d];
        sum += diff * diff;
    }

    distances[i * n + j] = sqrt(sum);
}
"#;

/// `KNN_SHADER`: one candidate per thread and query, for `batch_knn_gpu` ([`knn.rs` 34-106](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/knn.rs#L34-L106))
pub const KNN: &str = r#"
@group(0) @binding(0) var<storage, read> refs: array<f32>;
@group(0) @binding(1) var<storage, read> queries: array<f32>;
@group(0) @binding(2) var<storage, read> params: array<u32>;  // [num_refs, num_queries, dim, k]
@group(0) @binding(3) var<storage, read_write> out_indices: array<u32>;
@group(0) @binding(4) var<storage, read_write> out_dists: array<f32>;

@compute @workgroup_size(256)
fn batch_knn(
    @builtin(global_invocation_id) global_id: vec3<u32>,
    @builtin(local_invocation_id) local_id: vec3<u32>,
    @builtin(workgroup_id) wg_id: vec3<u32>,
) {
    let num_refs = params[0];
    let num_queries = params[1];
    let dim = params[2];
    let k = params[3];

    let query_idx = wg_id.x;
    if (query_idx >= num_queries) {
        return;
    }

    let tid = local_id.x;
    let q_base = query_idx * dim;

    // Each thread finds its local best-k from its subset of refs
    // Simple approach: each thread scans all refs with stride,
    // keeping track of the single nearest it found.
    // Then thread 0 gathers all partial results.

    // For large k, this approach is limited. For k <= workgroup_size (256),
    // we use a different strategy: each thread computes distance to one ref
    // and we do a parallel top-k selection.

    // Simple approach: each thread computes distances for its stride of refs,
    // stores the best distance and index.

    var best_dist: f32 = 3.402823e+38; // f32::MAX
    var best_idx: u32 = 0u;

    var i = tid;
    while (i < num_refs) {
        var dist: f32 = 0.0;
        for (var d = 0u; d < dim; d++) {
            let diff = queries[q_base + d] - refs[i * dim + d];
            dist += diff * diff;
        }
        dist = sqrt(dist);

        if (dist < best_dist) {
            best_dist = dist;
            best_idx = i;
        }
        i += 256u;
    }

    // For k=1, thread 0 just picks the global best
    // For k>1, we need a more sophisticated approach.
    // Simple solution: write all thread results to output, sort on CPU.
    // This is a pragmatic GPU/CPU hybrid approach.

    // Write this thread's best to a per-query output section
    let out_base = query_idx * 256u;
    if (tid < num_refs || tid == 0u) {
        out_indices[out_base + tid] = best_idx;
        out_dists[out_base + tid] = best_dist;
    } else {
        out_indices[out_base + tid] = 0u;
        out_dists[out_base + tid] = 3.402823e+38;
    }
}
"#;

/// `MATMUL_SHADER`: C = A × B, one thread per element, for `matmul_gpu` ([`matmul.rs` 12-43](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/matmul.rs#L12-L43))
pub const MATMUL: &str = r#"
struct Params {
    M: u32,
    N: u32,
    K: u32,
    _pad: u32,
}

@group(0) @binding(0) var<storage, read> a: array<f32>;
@group(0) @binding(1) var<storage, read> b: array<f32>;
@group(0) @binding(2) var<storage, read_write> c: array<f32>;
@group(0) @binding(3) var<uniform> params: Params;

@compute @workgroup_size(16, 16)
fn matmul(
    @builtin(global_invocation_id) global_id: vec3<u32>,
) {
    let row = global_id.x;
    let col = global_id.y;

    if (row >= params.M || col >= params.N) {
        return;
    }

    var sum: f32 = 0.0;
    for (var k: u32 = 0u; k < params.K; k++) {
        sum += a[row * params.K + k] * b[k * params.N + col];
    }

    c[row * params.N + col] = sum;
}
"#;
