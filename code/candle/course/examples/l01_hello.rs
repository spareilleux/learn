//! Lesson 1: the first program, the matrix product of the Candle README with values that don't change between runs.

use candle_core::{Device, Tensor};

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let device = Device::Cpu;

    // arange instead of the README's randn: the same numbers on every run and every OS
    let a = Tensor::arange(0f32, 6., &device)?.reshape((2, 3))?;
    let b = Tensor::arange(0f32, 12., &device)?.reshape((3, 4))?;

    let c = a.matmul(&b)?;
    println!("{c}");
    Ok(())
}
