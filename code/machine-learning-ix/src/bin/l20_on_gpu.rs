//! Lesson 20 on a GPU: `cargo run --release --bin l20_on_gpu`. CI has no adapter to count on, so `check.sh`
//! doesn't run this program; the lesson quotes one run on the author's machine, saved in `local/l20_on_gpu.txt`.
//!
//! A call that makes wgpu panic runs in a process of its own: `l20_on_gpu probe <what>` makes one call and
//! prints "returned", and the parent reads the child's exit status and the end of its panic message.

use ix_gpu::batch::similarity_matrix;
use ix_gpu::context::GpuContext;
use ix_gpu::knn::batch_knn_gpu;
use ix_gpu::similarity::dot_product_gpu;
use machine_learning_ix::gpu::{
    K, QUERIES, REFS, THREADS, cosine_gap, knn_on_gpu, matmul_times, signed, sums_on_gpu,
    thresholds_on_gpu, uniform_points,
};
use std::process::Command;
use std::time::Instant;

fn yes(b: bool) -> &'static str {
    if b { "yes" } else { "no" }
}

fn context() -> GpuContext {
    GpuContext::new().expect("this program needs a GPU adapter")
}

/// One call, in this process
fn probe(args: &[String]) {
    let ctx = context();
    let number = |i: usize| args[i].parse::<usize>().unwrap();
    match args[0].as_str() {
        "dot" => {
            let v = signed(20_102, 1000);
            std::hint::black_box(dot_product_gpu(&ctx, &v, &v));
        }
        "similarity" => {
            let (n, dim) = (number(1), number(2));
            let flat = uniform_points(20_500, n, dim);
            let vectors: Vec<Vec<f32>> = flat.chunks(dim).map(|v| v.to_vec()).collect();
            std::hint::black_box(similarity_matrix(Some(&ctx), &vectors));
        }
        "knn" => {
            let refs = uniform_points(20_501, 16, 2);
            let queries = uniform_points(20_502, number(1), 2);
            std::hint::black_box(batch_knn_gpu(&ctx, &refs, &queries, 2, 1));
        }
        other => panic!("unknown probe {other}"),
    }
    println!("returned");
}

/// The same call in a child process: "returned", or "panics" and the last line of wgpu's message
fn in_child(args: &[&str]) -> (bool, String) {
    let out = Command::new(std::env::current_exe().unwrap())
        .arg("probe")
        .args(args)
        .output()
        .unwrap();
    let stderr = String::from_utf8_lossy(&out.stderr).into_owned();
    if out.status.success() {
        return (true, "returned".to_string());
    }
    let cause = stderr
        .lines()
        .map(str::trim)
        .rfind(|l| !l.is_empty() && !l.starts_with("note:"))
        .unwrap_or("")
        .to_string();
    (
        false,
        format!(
            "panics; \"wgpu error\": {}; last line: {cause}",
            yes(stderr.contains("wgpu error"))
        ),
    )
}

fn main() {
    let args: Vec<String> = std::env::args().skip(1).collect();
    if args.first().map(String::as_str) == Some("probe") {
        probe(&args[1..]);
        return;
    }

    let start = Instant::now();
    let ctx = context();
    let created = start.elapsed().as_secs_f64() * 1e3;
    println!("== the adapter");
    println!(
        "  {} ({:?}); GpuContext::new() took {created:.0} ms",
        ctx.gpu_name(),
        ctx.backend()
    );

    println!("\n== P1 on the GPU");
    let out = Command::new(std::env::current_exe().unwrap())
        .args(["probe", "dot"])
        .output()
        .unwrap();
    let stderr = String::from_utf8_lossy(&out.stderr);
    println!(
        "  dot_product_gpu, in a process of its own: returns: {}; message starts with \"wgpu error\": {}; contains naga's \"name `shared` is a reserved keyword\": {}",
        yes(out.status.success()),
        yes(stderr.lines().any(|l| l.starts_with("wgpu error"))),
        yes(stderr.contains("name `shared` is a reserved keyword"))
    );
    println!(
        "  cosine_similarity_gpu against cosine_similarity_cpu, 1000 components: gap {:.1e}",
        cosine_gap(&ctx)
    );

    println!("\n== P5 on the GPU, each call in a process of its own");
    for (what, args) in [
        (
            "similarity_matrix, 5792 vectors of dimension 8",
            vec!["similarity", "5792", "8"],
        ),
        (
            "similarity_matrix, 5793 vectors of dimension 8",
            vec!["similarity", "5793", "8"],
        ),
        (
            "similarity_matrix, 10000 vectors of dimension 768",
            vec!["similarity", "10000", "768"],
        ),
        ("batch_knn_gpu, 65535 queries", vec!["knn", "65535"]),
        ("batch_knn_gpu, 65536 queries", vec!["knn", "65536"]),
    ] {
        println!("  {what}: {}", in_child(&args).1);
    }

    println!("\n== P6, batch_knn_gpu on P2's data, k = {K}");
    let knn = knn_on_gpu(&ctx);
    println!(
        "  queries whose {K} indices equal the port's, in order: {} of {QUERIES}; largest distance gap {:.1e}",
        knn.same_as_port, knn.largest_distance_gap
    );
    println!(
        "  queries whose {K} nearest differ from batch_knn_cpu's: GPU {}, port {}",
        knn.differ_from_cpu, knn.port_differ_from_cpu
    );
    println!(
        "  the first {THREADS} of the {REFS} references: equal to batch_knn_cpu's, in order, for {} of {QUERIES}",
        knn.first_256_same_as_cpu
    );

    println!("\n== P7, the GPU's sums against the CPU's");
    let s = sums_on_gpu(&ctx);
    println!(
        "  matmul 256 x 256 x 256: elements that differ {} of 65536, largest gap {:.1e}",
        s.matmul_differing, s.matmul_largest_gap
    );
    println!(
        "  pairwise distances of the {REFS} references: elements that differ {} of {}, largest gap {:.1e}, zero diagonal: {}",
        s.distance_differing,
        REFS * REFS,
        s.distance_largest_gap,
        yes(s.distance_diagonal_zero)
    );

    println!("\n== P8, matmul_cpu against matmul_gpu, median of 5 calls after a warm-up");
    for (m, k, n) in [
        (10, 10, 10),
        (64, 64, 64),
        (256, 768, 1024),
        (1024, 1024, 1024),
    ] {
        let (cpu, gpu) = matmul_times(&ctx, m, k, n);
        println!(
            "  {m} x {k} x {n}: cpu {cpu:.3} ms, gpu {gpu:.3} ms, gpu faster by {:.1}x",
            cpu / gpu
        );
    }

    println!("\n== exploratory");
    println!(
        "  P7's loops on the CPU with fused multiply-adds: matmul elements that differ from the GPU {} of 65536; distances {} of {}",
        s.matmul_differing_from_fused,
        s.distance_differing_from_fused,
        REFS * REFS
    );
    let (tiny, zero) = thresholds_on_gpu(&ctx);
    println!(
        "  P3's vectors with a context: similarity_matrix(Some(&ctx), [a, b])[0][1] {tiny:.6}; similarity_matrix(Some(&ctx), [z, b])[0][0] {zero:.6}"
    );
    let mut again: Vec<f64> = (0..3)
        .map(|_| {
            let start = Instant::now();
            drop(context());
            start.elapsed().as_secs_f64() * 1e3
        })
        .collect();
    again.sort_by(f64::total_cmp);
    println!(
        "  GpuContext::new() three more times in this process: median {:.0} ms",
        again[1]
    );
}
