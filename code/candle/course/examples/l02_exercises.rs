//! Lesson 2, solutions of the exercises: pairwise distances with broadcasting, and accuracy from scores.

use candle_core::{D, DType, Device, Tensor};
use candle_course::show;

fn main() -> candle_core::Result<()> {
    let dev = Device::Cpu;

    println!("== exercise 1: squared distances between every point of p and every point of q");
    let p = Tensor::new(&[[0f32, 0.], [3., 4.], [1., 1.]], &dev)?; // (3, 2)
    let q = Tensor::new(&[[0f32, 0.], [6., 8.]], &dev)?; // (2, 2)
    // (3, 1, 2) - (1, 2, 2) broadcasts to (3, 2, 2): one difference vector per pair
    let diff = p.unsqueeze(1)?.broadcast_sub(&q.unsqueeze(0)?)?;
    let d2 = diff.sqr()?.sum(D::Minus1)?;
    show("d2", &d2, 0)?;
    println!("dims {:?}", d2.dims());
    // Nearest point of q for each point of p
    show("nearest", &d2.argmin(1)?, 0)?;
    // The same without the 3-d tensor: |p|^2 + |q|^2 - 2 p.q
    let pp = p.sqr()?.sum_keepdim(1)?; // (3, 1)
    let qq = q.sqr()?.sum_keepdim(1)?.t()?; // (1, 2)
    let d2_bis = pp.broadcast_add(&qq)?.sub(&(p.matmul(&q.t()?)? * 2.0)?)?;
    show("d2 by |p|^2 + |q|^2 - 2 p.q", &d2_bis, 0)?;

    println!("\n== exercise 2: accuracy of scores against labels");
    let scores = Tensor::new(
        &[
            [0.1f32, 2.0, -1.0],
            [1.5, 0.2, 0.3],
            [0.0, 0.1, 0.2],
            [3.0, 2.9, -4.0],
        ],
        &dev,
    )?;
    let labels = Tensor::new(&[1u32, 0, 1, 1], &dev)?;
    let predicted = scores.argmax(D::Minus1)?;
    show("predicted", &predicted, 0)?;
    let correct = predicted.eq(&labels)?; // U8: 1 where equal
    show("correct", &correct, 0)?;
    let accuracy = correct
        .to_dtype(DType::F32)?
        .mean_all()?
        .to_scalar::<f32>()?;
    println!("accuracy {accuracy}");
    Ok(())
}
