//! Lesson 1, solutions of the exercises: the product in the other order, and matmul on other dtypes.

use candle_core::{DType, Device, Tensor};
use candle_course::outcome;

fn main() -> candle_core::Result<()> {
    let device = Device::Cpu;
    let a = Tensor::arange(0f32, 6., &device)?.reshape((2, 3))?;
    let b = Tensor::arange(0f32, 12., &device)?.reshape((3, 4))?;

    println!("== exercise 1: b x a, then b x a transposed");
    outcome("b.matmul(&a)", b.matmul(&a));
    // (3, 4) x (4, 3) is defined if we transpose b instead: b.t() is (4, 3), a.t() is (3, 2)
    let c = b.t()?.matmul(&a.t()?)?;
    println!("{c}");
    // (AB)^T = B^T A^T: the same numbers as a.matmul(&b) of the lesson, transposed
    let same = c.eq(&a.matmul(&b)?.t()?)?.min_all()?.to_scalar::<u8>()? == 1;
    println!("b.t() x a.t() equals (a x b).t(): {same}");

    println!("\n== exercise 2: matmul on each dtype");
    for dtype in [
        DType::F64,
        DType::F16,
        DType::BF16,
        DType::U32,
        DType::I64,
        DType::U8,
    ] {
        let result = a.to_dtype(dtype)?.matmul(&b.to_dtype(dtype)?);
        match result {
            Ok(c) => println!(
                "{dtype:?}: ok, first row {:?}",
                c.to_dtype(DType::F64)?.to_vec2::<f64>()?[0]
            ),
            Err(e) => println!("{dtype:?}: error: {e}"),
        }
    }
    Ok(())
}
