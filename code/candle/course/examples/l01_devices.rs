//! Lesson 1: which backends this build of Candle has, and what asking for a GPU does without the feature.

use candle_core::{Device, utils};

fn main() -> candle_core::Result<()> {
    println!("cuda feature:       {}", utils::cuda_is_available());
    println!("metal feature:      {}", utils::metal_is_available());
    println!("mkl feature:        {}", utils::has_mkl());
    println!("accelerate feature: {}", utils::has_accelerate());

    match Device::new_cuda(0) {
        Ok(d) => println!("Device::new_cuda(0): {d:?}"),
        Err(e) => println!("Device::new_cuda(0): error: {e}"),
    }
    match Device::new_metal(0) {
        Ok(d) => println!("Device::new_metal(0): {d:?}"),
        Err(e) => println!("Device::new_metal(0): error: {e}"),
    }
    // Falls back to the CPU instead of failing
    let device = Device::cuda_if_available(0)?;
    println!("Device::cuda_if_available(0): {device:?}");
    Ok(())
}
