//! Lesson 3: timings on the CPU. They depend on the machine, so check.sh runs this example without
//! comparing its output. RAYON_NUM_THREADS sets the number of threads matmul uses.

use candle_core::{DType, Device, Module, Tensor, Var, utils};
use std::time::Instant;

/// Median time of `runs` calls of `f`, in milliseconds, after one warm-up call
fn median_ms<T>(runs: usize, mut f: impl FnMut() -> T) -> f64 {
    std::hint::black_box(f());
    let mut times: Vec<f64> = (0..runs)
        .map(|_| {
            let start = Instant::now();
            std::hint::black_box(f());
            start.elapsed().as_secs_f64() * 1000.0
        })
        .collect();
    times.sort_by(f64::total_cmp);
    times[runs / 2]
}

/// Deterministic values in [-1, 1) from a linear congruential generator
fn values(n: usize, seed: u64) -> Vec<f32> {
    let mut state = seed;
    (0..n)
        .map(|_| {
            state = state
                .wrapping_mul(6364136223846793005)
                .wrapping_add(1442695040888963407);
            ((state >> 40) as f32 / (1u64 << 24) as f32) * 2.0 - 1.0
        })
        .collect()
}

/// The textbook i-k-j triple loop, as a baseline for gemm
fn naive_matmul(a: &[f32], b: &[f32], n: usize) -> Vec<f32> {
    let mut c = vec![0f32; n * n];
    for i in 0..n {
        for k in 0..n {
            let aik = a[i * n + k];
            for j in 0..n {
                c[i * n + j] += aik * b[k * n + j];
            }
        }
    }
    c
}

struct Layer {
    w: Tensor,
    b: Tensor,
}

impl Module for Layer {
    fn forward(&self, xs: &Tensor) -> candle_core::Result<Tensor> {
        xs.matmul(&self.w.t()?)?.broadcast_add(&self.b)?.relu()
    }
}

fn main() -> candle_core::Result<()> {
    let dev = Device::Cpu;
    println!(
        "threads {}, avx2 kernels compiled in {}, os {}",
        utils::get_num_threads(),
        utils::with_avx(),
        std::env::consts::OS
    );

    println!("\n== matmul of two n x n matrices (median, ms)");
    for n in [256, 512, 1024] {
        let a32 = Tensor::from_vec(values(n * n, 1), (n, n), &dev)?;
        let b32 = Tensor::from_vec(values(n * n, 2), (n, n), &dev)?;
        let (a64, b64) = (a32.to_dtype(DType::F64)?, b32.to_dtype(DType::F64)?);
        let (a16, b16) = (a32.to_dtype(DType::F16)?, b32.to_dtype(DType::F16)?);
        let t32 = median_ms(5, || a32.matmul(&b32).unwrap());
        let t64 = median_ms(5, || a64.matmul(&b64).unwrap());
        let t16 = median_ms(3, || a16.matmul(&b16).unwrap());
        let gflops = 2.0 * (n as f64).powi(3) / (t32 / 1000.0) / 1e9;
        print!(
            "n {n:>4}: f32 {t32:>8.2}  f64 {t64:>8.2}  f16 {t16:>8.2}  (f32: {gflops:>4.0} GFLOPS)"
        );
        if n <= 512 {
            let av = a32.flatten_all()?.to_vec1::<f32>()?;
            let bv = b32.flatten_all()?.to_vec1::<f32>()?;
            let tn = median_ms(3, || naive_matmul(&av, &bv, n));
            print!("  triple loop {tn:>8.2}");
        }
        println!();
    }

    println!("\n== element-wise operations on 2048 x 2048 f32 (median of 9, ms)");
    let n = 2048;
    let a = Tensor::from_vec(values(n * n, 3), (n, n), &dev)?;
    let b = Tensor::from_vec(values(n * n, 4), (n, n), &dev)?;
    let bias = Tensor::from_vec(values(n, 5), n, &dev)?;
    let (at, bt) = (a.t()?, b.t()?);
    let rows = [
        (
            "a + b, both contiguous",
            median_ms(9, || (&a + &b).unwrap()),
        ),
        (
            "a.t() + b.t(), both strided",
            median_ms(9, || (&at + &bt).unwrap()),
        ),
        (
            "a.broadcast_add(bias)",
            median_ms(9, || a.broadcast_add(&bias).unwrap()),
        ),
        (
            "a.t().contiguous(), a copy",
            median_ms(9, || at.contiguous().unwrap()),
        ),
        ("a.exp()", median_ms(9, || a.exp().unwrap())),
        ("a.relu()", median_ms(9, || a.relu().unwrap())),
        ("a.t(), a view", median_ms(9, || a.t().unwrap())),
    ];
    for (label, ms) in rows {
        println!("{label:<30} {ms:>8.3}");
    }

    println!("\n== 3 layers 256 -> 256, batch 64, 200 forward passes (median of 5, ms)");
    let layers: Vec<Layer> = (0..3u64)
        .map(|i| Layer {
            w: Tensor::from_vec(values(256 * 256, 10 + i), (256, 256), &dev).unwrap(),
            b: Tensor::from_vec(values(256, 20 + i), 256, &dev).unwrap(),
        })
        .collect();
    let var_layers: Vec<Layer> = layers
        .iter()
        .map(|l| Layer {
            w: Var::from_tensor(&l.w).unwrap().into_inner(),
            b: Var::from_tensor(&l.b).unwrap().into_inner(),
        })
        .collect();
    let xs = Tensor::from_vec(values(64 * 256, 30), (64, 256), &dev)?;
    let run = |layers: &[Layer]| {
        for _ in 0..200 {
            let mut h = xs.clone();
            for l in layers {
                h = l.forward(&h).unwrap();
            }
            std::hint::black_box(h);
        }
    };
    // Twice each, alternating, so that warming up the allocator doesn't favour the second one
    for round in 1..=2 {
        println!(
            "round {round}: plain tensors, no graph  {:>8.2}",
            median_ms(5, || run(&layers))
        );
        println!(
            "round {round}: Var weights, graph kept  {:>8.2}",
            median_ms(5, || run(&var_layers))
        );
    }
    Ok(())
}
