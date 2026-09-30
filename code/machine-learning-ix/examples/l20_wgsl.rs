//! Lesson 20: IX's `ix-gpu` without a GPU — its shaders through naga, its kNN shader's loop ported to Rust
//! against its own `batch_knn_cpu`, its two cosine thresholds, and the limits of `Limits::default()`. The calls
//! that need an adapter are in `src/bin/l20_on_gpu.rs`.

use machine_learning_ix::gpu::{
    DIM, K, QUERIES, REFS, THREADS, knn_port, limits, p_wrong, shader_checks, square_bytes,
    thresholds,
};

fn yes(b: bool) -> &'static str {
    if b { "yes" } else { "no" }
}

fn main() {
    println!("== P1, naga 28 on five shaders of ix-gpu, copied from the pinned commit");
    for (name, check) in shader_checks() {
        match check.parse_error {
            Some(message) => println!("  {name}: parse error: {message}"),
            None => println!(
                "  {name}: parses; validates: {}; workgroup variables: {}",
                yes(check.valid),
                check.workgroup_variables
            ),
        }
    }

    println!(
        "\n== P2, the kNN shader's loop ported to Rust: {REFS} references and {QUERIES} queries uniform in [0, 1)^{DIM}, k = {K}"
    );
    let port = knn_port();
    println!(
        "  P(two of the {K} nearest share a class modulo {THREADS}) = 1 - e_{K}(class sizes) / C({REFS}, {K}) = {:.4}",
        port.p_wrong
    );
    println!(
        "  queries whose {K} nearest differ from batch_knn_cpu's: {}; with k = 1: {}; with the first {THREADS} references: {}",
        port.differ, port.differ_k1, port.differ_first_256
    );
    println!(
        "  true neighbours the port returns: {} of {}",
        port.recovered,
        QUERIES * K
    );

    println!("\n== P3, a = (1e-6, 2e-6, 2e-6), b = 2a, z = 0, in f32");
    let t = thresholds();
    println!(
        "  cosine_similarity_cpu(a, b) {:.6}; similarity_matrix(None, [a, b])[0][1] {:.6}; batch_top_k(None, [a], [b], 1) {:.6}",
        t.cosine, t.matrix, t.batch
    );
    println!(
        "  similarity_matrix(None, [z, b])[0][0] {:.6}; cosine_similarity_cpu(z, z) {:.6}",
        t.zero_diagonal, t.zero_cosine
    );

    println!("\n== P5, wgpu::Limits::default()");
    let l = limits();
    println!(
        "  max_storage_buffer_binding_size {}, max_buffer_size {}, max_compute_workgroups_per_dimension {}",
        l.binding, l.buffer, l.workgroups
    );
    println!(
        "  largest n whose n x n f32 matrix fits in one binding: {} ({} bytes); {} needs {}",
        l.largest_square,
        square_bytes(l.largest_square),
        l.largest_square + 1,
        square_bytes(l.largest_square + 1)
    );
    println!(
        "  the guide's 10000 embeddings compared pairwise: {} bytes, above max_buffer_size: {}",
        square_bytes(10_000),
        yes(square_bytes(10_000) > l.buffer)
    );

    println!("\n== exploratory");
    println!(
        "  P(some of the 10 nearest lost): N = 2000 {:.4}, N = 10000 {:.4}; N = 1000 with k = 5 {:.4}, with k = 20 {:.4}",
        p_wrong(2000, 10),
        p_wrong(10_000, 10),
        p_wrong(1000, 5),
        p_wrong(1000, 20)
    );
}
