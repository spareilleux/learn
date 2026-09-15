//! Lesson 2: the errors Candle returns at run time, and their messages.

use candle_core::{D, Device, IndexOp, Tensor};
use candle_course::{caught, outcome};

fn main() -> candle_core::Result<()> {
    let dev = Device::Cpu;
    let m = Tensor::new(&[[1f32, 2., 3.], [4., 5., 6.]], &dev)?;
    let row = Tensor::new(&[10f32, 20., 30.], &dev)?;
    let col = Tensor::new(&[[100f32], [200.]], &dev)?;

    println!("== shapes");
    outcome("m + row (no implicit broadcasting)", &m + &row);
    outcome("m.broadcast_add(row)", m.broadcast_add(&row));
    outcome(
        "m.broadcast_add([1, 2])",
        m.broadcast_add(&Tensor::new(&[1f32, 2.], &dev)?),
    );
    outcome("m.matmul(m)", m.matmul(&m));
    outcome("m.matmul(row)", m.matmul(&row));
    outcome("m.reshape((4, 2))", m.reshape((4, 2)));
    outcome("m.reshape(((), 4))", m.reshape(((), 4)));
    outcome("col.broadcast_as((2, 3))", col.broadcast_as((2, 3)));
    outcome("row.broadcast_as((3, 2))", row.broadcast_as((3, 2)));
    outcome("Tensor::cat(&[&m, &col], 0)", Tensor::cat(&[&m, &col], 0));
    outcome("m.squeeze(0)", m.squeeze(0).map(|t| t.dims().to_vec()));

    println!("\n== dimensions and indexes");
    outcome("m.sum(2)", m.sum(2));
    outcome("row.dim(D::Minus2)", row.dim(D::Minus2));
    outcome("m.i(2)", m.i(2));
    outcome("m.i((.., ..5))", m.i((.., ..5)));
    outcome("m.narrow(1, 2, 2)", m.narrow(1, 2, 2));
    outcome(
        "m.index_select([0, 3], 1)",
        m.index_select(&Tensor::new(&[0u32, 3], &dev)?, 1),
    );
    outcome("m.i((0, 0, 0))", m.i((0, 0, 0)));

    println!("\n== dtypes");
    let ints = Tensor::new(&[1u32, 2, 3], &dev)?;
    outcome("row.to_vec1::<f64>()", row.to_vec1::<f64>());
    outcome("row + ints", &row + &ints);
    outcome(
        "ints.matmul(ints)",
        ints.reshape((3, 1))?.matmul(&ints.reshape((1, 3))?),
    );
    caught("ints.sqrt()", || ints.sqrt());
    outcome(
        "m.index_select(f32 ids, 0)",
        m.index_select(&Tensor::new(&[0f32], &dev)?, 0),
    );
    outcome("m.to_scalar::<f32>()", m.to_scalar::<f32>());

    println!("\n== a shape that doesn't match the data (issue #3812, fixed after 0.11.0)");
    let short = Tensor::from_vec(vec![1f32, 2., 3., 4., 5.], (2, 3), &dev)?;
    println!(
        "from_vec(5 values, (2, 3)): ok, dims {:?}, elem_count {}",
        short.dims(),
        short.elem_count()
    );
    caught("short.sum_all()", || short.sum_all());

    println!("\n== seeds");
    outcome("Device::Cpu.set_seed(42)", dev.set_seed(42));
    Ok(())
}
