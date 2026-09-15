//! Lesson 1: what Candle found on this machine. The output depends on the CPU, so check.sh doesn't compare it.

use candle_core::utils;

fn main() {
    println!(
        "os / arch:        {} / {}",
        std::env::consts::OS,
        std::env::consts::ARCH
    );
    println!("compiled for avx2: {}", utils::with_avx());
    println!("compiled for neon: {}", utils::with_neon());
    println!("compiled for f16c: {}", utils::with_f16c());
    println!("threads (rayon):   {}", utils::get_num_threads());
}
