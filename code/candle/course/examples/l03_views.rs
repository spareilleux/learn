//! Lesson 3: which operations share a tensor's buffer and which copy it, strides and contiguity,
//! and when Candle records the graph of operations.

use candle_core::{CpuStorage, D, DType, Device, IndexOp, Storage, Tensor, Var};

/// Address of the first element of the CPU buffer behind a tensor, to tell whether two tensors share it
fn buffer(t: &Tensor) -> usize {
    let (storage, _layout) = t.storage_and_layout();
    match &*storage {
        Storage::Cpu(CpuStorage::F32(v)) => v.as_ptr() as usize,
        Storage::Cpu(CpuStorage::F64(v)) => v.as_ptr() as usize,
        _ => unimplemented!("only f32 and f64 CPU tensors in this example"),
    }
}

fn describe(label: &str, base: &Tensor, t: &Tensor) {
    println!(
        "{label:<26} dims {:<10} stride {:<10} offset {} contiguous {:<5} same buffer {}",
        format!("{:?}", t.dims()),
        format!("{:?}", t.stride()),
        t.layout().start_offset(),
        t.is_contiguous(),
        buffer(base) == buffer(t)
    );
}

fn main() -> candle_core::Result<()> {
    let dev = Device::Cpu;

    println!("== from_vec keeps the Vec's buffer");
    let data: Vec<f32> = (0..12).map(|v| v as f32).collect();
    let address = data.as_ptr() as usize;
    let a = Tensor::from_vec(data, (3, 4), &dev)?;
    println!("same buffer as the Vec: {}", buffer(&a) == address);
    let values: Vec<f32> = (0..12).map(|v| v as f32).collect();
    let s = Tensor::from_slice(&values, (3, 4), &dev)?;
    println!(
        "from_slice, same buffer as the slice: {}",
        buffer(&s) == values.as_ptr() as usize
    );

    println!("\n== views and copies of a (3, 4) tensor");
    describe("a", &a, &a);
    describe("a.clone()", &a, &a.clone());
    describe("a.reshape((2, 6))", &a, &a.reshape((2, 6))?);
    describe("a.unsqueeze(0)", &a, &a.unsqueeze(0)?);
    describe("a.t()", &a, &a.t()?);
    describe("a.t().contiguous()", &a, &a.t()?.contiguous()?);
    describe("a.t().reshape(12)", &a, &a.t()?.reshape(12)?);
    describe("a.i((1.., 1..3))", &a, &a.i((1.., 1..3))?);
    describe("a.i(2)", &a, &a.i(2)?);
    describe("a.i((.., 2))", &a, &a.i((.., 2))?);
    describe("a.broadcast_as((2, 3, 4))", &a, &a.broadcast_as((2, 3, 4))?);
    describe("a.to_dtype(F32)", &a, &a.to_dtype(DType::F32)?);
    describe("a.detach()", &a, &a.detach());
    describe("a.copy()", &a, &a.copy()?);
    describe("(&a + 1.0)", &a, &(&a + 1.0)?);

    println!("\n== the same values through a view and through a copy");
    let t = a.t()?;
    let tc = t.contiguous()?;
    println!("t.i(0)  {:?}", t.i(0)?.to_vec1::<f32>()?);
    println!("tc.i(0) {:?}", tc.i(0)?.to_vec1::<f32>()?);
    println!(
        "t equals tc everywhere: {}",
        t.eq(&tc)?.min_all()?.to_scalar::<u8>()? == 1
    );

    println!("\n== the graph of operations");
    let x = Tensor::new(&[1f32, 2., 3.], &dev)?;
    let y = x.sqr()?.sum_all()?;
    println!(
        "plain tensors: y.track_op() {}, nodes behind y {}",
        y.track_op(),
        y.sorted_nodes().len()
    );
    let w = Var::new(&[1f32, 2., 3.], &dev)?;
    let h = w.broadcast_mul(&x)?;
    let z = h.sqr()?.sum(D::Minus1)?;
    println!(
        "with a Var:    z.track_op() {}, nodes behind z {}",
        z.track_op(),
        z.sorted_nodes().len()
    );
    let dims: Vec<Vec<usize>> = z.sorted_nodes().iter().map(|n| n.dims().to_vec()).collect();
    println!("their dims, from z to w: {dims:?}");
    println!(
        "w.is_variable() {}, h.is_variable() {}",
        w.is_variable(),
        h.is_variable()
    );
    let zd = z.detach();
    println!(
        "z.detach():    track_op() {}, nodes behind {}",
        zd.track_op(),
        zd.sorted_nodes().len()
    );
    println!(
        "an op after detach: track_op() {}",
        zd.affine(2., 0.)?.track_op()
    );
    Ok(())
}
