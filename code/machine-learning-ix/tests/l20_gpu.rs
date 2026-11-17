//! Lesson 20's predictions that need a GPU adapter: `cargo test --release --test l20_gpu -- --ignored
//! --test-threads=1`. CI has no adapter to count on, so they are ignored there.

use ix_gpu::context::GpuContext;
use machine_learning_ix::gpu::{QUERIES, cosine_gap, knn_on_gpu, matmul_times, sums_on_gpu};
use std::process::Command;

fn context() -> GpuContext {
    GpuContext::new().expect("this test needs a GPU adapter")
}

/// Runs one call of `l20_on_gpu probe …` in a process of its own: whether it returned, and its stderr
fn probe(args: &[&str]) -> (bool, String) {
    let out = Command::new(env!("CARGO_BIN_EXE_l20_on_gpu"))
        .arg("probe")
        .args(args)
        .output()
        .unwrap();
    (
        out.status.success(),
        String::from_utf8_lossy(&out.stderr).into_owned(),
    )
}

#[test]
#[ignore = "needs a GPU adapter"]
fn p1_dot_product_gpu_panics_and_the_cosine_agrees() {
    let (returned, stderr) = probe(&["dot"]);
    assert!(!returned);
    assert!(
        stderr.lines().any(|l| l.starts_with("wgpu error")),
        "{stderr}"
    );
    assert!(
        stderr.contains("name `shared` is a reserved keyword"),
        "{stderr}"
    );
    assert!(cosine_gap(&context()) <= 1e-6);
}

#[test]
#[ignore = "needs a GPU adapter"]
fn p5_the_limits_on_a_gpu() {
    for (args, returns) in [
        (vec!["similarity", "5792", "8"], true),
        (vec!["similarity", "5793", "8"], false),
        (vec!["similarity", "10000", "768"], false),
        (vec!["knn", "65535"], true),
        (vec!["knn", "65536"], false),
    ] {
        let (returned, stderr) = probe(&args);
        assert_eq!(returned, returns, "{args:?}: {stderr}");
        if !returns {
            assert!(stderr.contains("wgpu error"), "{args:?}: {stderr}");
        }
    }
}

#[test]
#[ignore = "needs a GPU adapter"]
fn p6_the_gpu_returns_the_port() {
    let knn = knn_on_gpu(&context());
    assert_eq!(knn.same_as_port, QUERIES);
    assert!(
        knn.largest_distance_gap <= 1e-6,
        "{}",
        knn.largest_distance_gap
    );
    assert_eq!(knn.differ_from_cpu, knn.port_differ_from_cpu);
    assert_eq!(knn.first_256_same_as_cpu, QUERIES);
}

#[test]
#[ignore = "needs a GPU adapter"]
fn p7_the_same_sums_almost() {
    let s = sums_on_gpu(&context());
    assert!(s.matmul_differing >= 1);
    assert!(s.matmul_largest_gap <= 1e-4, "{}", s.matmul_largest_gap);
    assert!(s.distance_largest_gap <= 1e-5, "{}", s.distance_largest_gap);
    assert!(s.distance_diagonal_zero);
}

#[test]
#[ignore = "needs a GPU adapter"]
fn p8_the_guides_speed_ups() {
    let ctx = context();
    let (cpu, gpu) = matmul_times(&ctx, 1024, 1024, 1024);
    assert!(cpu / gpu >= 20.0, "cpu {cpu} ms, gpu {gpu} ms");
    let (cpu, gpu) = matmul_times(&ctx, 10, 10, 10);
    assert!(cpu < gpu, "cpu {cpu} ms, gpu {gpu} ms");
}
