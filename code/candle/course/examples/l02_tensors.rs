//! Lesson 2: creating tensors, dtypes, shapes, broadcasting, indexing and a few operations.

use candle::{D, DType, Device, IndexOp, Tensor};
use candle_core as candle;
use candle_course::show;

fn main() -> candle::Result<()> {
    let dev = Device::Cpu;

    println!("== creating");
    let from_array = Tensor::new(&[[1f32, 2., 3.], [4., 5., 6.]], &dev)?;
    show("new(&[[f32; 3]; 2])", &from_array, 0)?;
    let from_vec = Tensor::from_vec(vec![1u32, 2, 3, 4, 5, 6], (3, 2), &dev)?;
    show("from_vec(Vec<u32>, (3, 2))", &from_vec, 0)?;
    let hole = Tensor::from_vec((0..12).collect::<Vec<i64>>(), (2, (), 3), &dev)?;
    show("from_vec(0..12, (2, (), 3))", &hole, 0)?;
    show(
        "zeros((2, 2), F64)",
        &Tensor::zeros((2, 2), DType::F64, &dev)?,
        0,
    )?;
    show("full(7u8, 3)", &Tensor::full(7u8, 3, &dev)?, 0)?;
    show(
        "arange_step(0.0, 1.0, 0.25)",
        &Tensor::arange_step(0f32, 1., 0.25, &dev)?,
        2,
    )?;
    let scalar = Tensor::new(2.5f64, &dev)?;
    println!(
        "scalar: rank {}, dims {:?}, value {}",
        scalar.rank(),
        scalar.dims(),
        scalar.to_scalar::<f64>()?
    );

    println!("\n== dtypes");
    let x = Tensor::new(&[1.4f32, 2.5, -2.5, 300.7], &dev)?;
    show("f32", &x, 2)?;
    show("to_dtype(U8)", &x.to_dtype(DType::U8)?, 0)?;
    show("to_dtype(I64)", &x.to_dtype(DType::I64)?, 0)?;
    show("to_dtype(F16)", &x.to_dtype(DType::F16)?, 2)?;
    let third = Tensor::new(1f64 / 3., &dev)?;
    println!(
        "1/3 as f64 {:.17}, as f32 {:.17}",
        third.to_scalar::<f64>()?,
        third.to_dtype(DType::F32)?.to_scalar::<f32>()?
    );
    println!(
        "size in bytes: F16 {}, F32 {}, F64 {}, U8 {}",
        DType::F16.size_in_bytes(),
        DType::F32.size_in_bytes(),
        DType::F64.size_in_bytes(),
        DType::U8.size_in_bytes()
    );

    println!("\n== shapes");
    let t = Tensor::arange(0f32, 24., &dev)?.reshape((2, 3, 4))?;
    println!(
        "dims {:?}, rank {}, elem_count {}",
        t.dims(),
        t.rank(),
        t.elem_count()
    );
    println!("dim(0) {}, dim(D::Minus1) {}", t.dim(0)?, t.dim(D::Minus1)?);
    let (b, r, c) = t.dims3()?;
    println!("dims3: b {b}, r {r}, c {c}");
    println!("reshape((4, ())) -> {:?}", t.reshape((4, ()))?.dims());
    println!("flatten_from(1) -> {:?}", t.flatten_from(1)?.dims());
    println!(
        "unsqueeze(0) -> {:?}, then squeeze(0) -> {:?}",
        t.unsqueeze(0)?.dims(),
        t.unsqueeze(0)?.squeeze(0)?.dims()
    );
    println!(
        "transpose(1, 2) -> {:?}, permute((2, 0, 1)) -> {:?}",
        t.transpose(1, 2)?.dims(),
        t.permute((2, 0, 1))?.dims()
    );

    println!("\n== broadcasting");
    let m = Tensor::new(&[[1f32, 2., 3.], [4., 5., 6.]], &dev)?;
    let row = Tensor::new(&[10f32, 20., 30.], &dev)?;
    let col = Tensor::new(&[[100f32], [200.]], &dev)?;
    show("m.broadcast_add(row)", &m.broadcast_add(&row)?, 0)?;
    show("m.broadcast_add(col)", &m.broadcast_add(&col)?, 0)?;
    show("row.broadcast_mul(col)", &row.broadcast_mul(&col)?, 0)?;
    show("(&m * 2.0)? - 1.0", &((&m * 2.0)? - 1.0)?, 0)?;
    show("m.broadcast_as((2, 2, 3))", &m.broadcast_as((2, 2, 3))?, 0)?;

    println!("\n== indexing");
    show("m.i(1)", &m.i(1)?, 0)?;
    show("m.i((.., 1))", &m.i((.., 1))?, 0)?;
    show("m.i((.., 1..))", &m.i((.., 1..))?, 0)?;
    show("m.i((0, ..=1))", &m.i((0, ..=1))?, 0)?;
    show("m.narrow(1, 0, 2)", &m.narrow(1, 0, 2)?, 0)?;
    let ids = Tensor::new(&[2u32, 0, 2], &dev)?;
    show(
        "m.index_select(ids [2, 0, 2], 1)",
        &m.index_select(&ids, 1)?,
        0,
    )?;
    show("m.i((.., &ids))", &m.i((.., &ids))?, 0)?;
    let picks = Tensor::new(&[[2u32], [0]], &dev)?;
    show("m.gather(picks [[2], [0]], 1)", &m.gather(&picks, 1)?, 0)?;
    println!(
        "m.i((1, 2)) as a Rust value: {}",
        m.i((1, 2))?.to_scalar::<f32>()?
    );
    println!("m.to_vec2(): {:?}", m.to_vec2::<f32>()?);

    println!("\n== operations");
    show("m.sum_all()", &m.sum_all()?, 0)?;
    show("m.sum(0)", &m.sum(0)?, 0)?;
    show("m.sum_keepdim(0)", &m.sum_keepdim(0)?, 0)?;
    show("m.mean(D::Minus1)", &m.mean(D::Minus1)?, 1)?;
    show("m.max(1)", &m.max(1)?, 0)?;
    show("m.argmax(1)", &m.argmax(1)?, 0)?;
    show("m.t()?.matmul(&m)", &m.t()?.matmul(&m)?, 0)?;
    show("m.sqr()?.sqrt()", &m.sqr()?.sqrt()?, 0)?;
    show("m.ge(3.0)", &m.ge(3f64)?, 0)?;
    show("row.exp()", &row.affine(0.1, 0.)?.exp()?, 4)?;
    show("softmax by hand", &softmax(&row.affine(0.1, 0.)?)?, 4)?;
    show("Tensor::cat(&[&m, &m], 0)", &Tensor::cat(&[&m, &m], 0)?, 0)?;
    show(
        "Tensor::stack(&[&row, &row], 0)",
        &Tensor::stack(&[&row, &row], 0)?,
        0,
    )?;
    println!("{}", m.i((.., 1..))?);
    Ok(())
}

/// softmax(x)_i = exp(x_i) / sum_j exp(x_j), shifted by the maximum so exp doesn't overflow
fn softmax(x: &Tensor) -> candle::Result<Tensor> {
    let shifted = x.broadcast_sub(&x.max_keepdim(D::Minus1)?)?;
    let e = shifted.exp()?;
    e.broadcast_div(&e.sum_keepdim(D::Minus1)?)
}
