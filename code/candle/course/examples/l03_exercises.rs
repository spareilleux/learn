//! Lesson 3, solutions of the exercises: predicting views and copies, and the memory a broadcast saves.

use candle_core::{CpuStorage, DType, Device, IndexOp, Storage, Tensor};

fn buffer(t: &Tensor) -> usize {
    let (storage, _) = t.storage_and_layout();
    match &*storage {
        Storage::Cpu(CpuStorage::F32(v)) => v.as_ptr() as usize,
        _ => unimplemented!(),
    }
}

/// Bytes held by the buffer behind a tensor, which can be more than the tensor's own elements need
fn buffer_bytes(t: &Tensor) -> usize {
    let (storage, _) = t.storage_and_layout();
    match &*storage {
        Storage::Cpu(CpuStorage::F32(v)) => v.len() * 4,
        _ => unimplemented!(),
    }
}

fn main() -> candle_core::Result<()> {
    let dev = Device::Cpu;
    let a = Tensor::arange(0f32, 24., &dev)?.reshape((2, 3, 4))?;

    println!("== exercise 1: view or copy?");
    let cases: Vec<(&str, Tensor)> = vec![
        ("a.permute((2, 0, 1))", a.permute((2, 0, 1))?),
        (
            "a.permute((2, 0, 1)).flatten_all()",
            a.permute((2, 0, 1))?.flatten_all()?,
        ),
        ("a.flatten_all()", a.flatten_all()?),
        ("a.i((.., 1, ..))", a.i((.., 1, ..))?),
        (
            "a.i((.., 1, ..)).contiguous()",
            a.i((.., 1, ..))?.contiguous()?,
        ),
        ("a.i((1, ..)).contiguous()", a.i((1, ..))?.contiguous()?),
        ("a.squeeze(0)", a.squeeze(0)?),
        ("a.transpose(1, 1)", a.transpose(1, 1)?),
    ];
    for (label, t) in cases {
        println!(
            "{label:<36} contiguous {:<5} same buffer {}",
            t.is_contiguous(),
            buffer(&t) == buffer(&a)
        );
    }

    println!("\n== exercise 2: the memory behind a broadcast");
    let bias = Tensor::zeros(1000, DType::F32, &dev)?;
    let wide = bias.broadcast_as((1000, 1000))?;
    let copy = wide.contiguous()?;
    println!(
        "wide:   {} elements, buffer {} bytes",
        wide.elem_count(),
        buffer_bytes(&wide)
    );
    println!(
        "copy:   {} elements, buffer {} bytes",
        copy.elem_count(),
        buffer_bytes(&copy)
    );
    let row = copy.i(0)?;
    println!(
        "copy.i(0): {} elements, buffer {} bytes",
        row.elem_count(),
        buffer_bytes(&row)
    );
    let small = row.copy()?;
    println!(
        "copy.i(0).copy(): {} elements, buffer {} bytes",
        small.elem_count(),
        buffer_bytes(&small)
    );
    let compact = row.force_contiguous()?;
    println!(
        "copy.i(0).force_contiguous(): {} elements, buffer {} bytes",
        compact.elem_count(),
        buffer_bytes(&compact)
    );
    Ok(())
}
