//! Lesson 5: losses. cross_entropy against the formula, logits of ±1000, the targets nll accepts, and the
//! binary cross-entropy with logits, which turns a confident prediction into NaN or infinity.

use candle_core::{DType, Device, Tensor, Var};
use candle_course::{outcome, show};
use candle_nn::{loss, ops};

/// The first value of a tensor, as f64
fn first(t: &Tensor) -> candle_core::Result<f64> {
    Ok(t.to_dtype(DType::F64)?.flatten_all()?.to_vec1::<f64>()?[0])
}

/// Three significant digits, or one for a subnormal f32 (below 1.2e-38), which carries only a few bits:
/// their last digits could depend on the system's exp
fn sci(v: f64) -> String {
    if v != 0.0 && v.abs() < 1e-37 {
        format!("{v:.0e}")
    } else {
        format!("{v:.3e}")
    }
}

/// max(x, 0) − x · y + log(1 + exp(−|x|)), averaged: the same loss, without the sigmoid's rounding
fn stable_bce(x: &Tensor, y: &Tensor) -> candle_core::Result<Tensor> {
    let log_term = (x.abs()?.neg()?.exp()? + 1.0)?.log()?;
    (x.relu()? - (x * y)?)?.add(&log_term)?.mean_all()
}

fn main() -> anyhow::Result<()> {
    let dev = Device::Cpu;

    println!("== cross_entropy against the formula, f64");
    let logits = [
        [2.0f64, 1.0, 0.1, -1.0],
        [0.5, 0.5, 0.5, 3.0],
        [-2.0, 4.0, 1.0, 0.0],
    ];
    let targets = [0u32, 3, 1];
    let z = Tensor::new(&logits, &dev)?;
    let y = Tensor::new(&targets, &dev)?;
    let candle = loss::cross_entropy(&z, &y)?.to_scalar::<f64>()?;
    // −log softmax at the target, i.e. log Σ exp(z − max) − (z_target − max), averaged over the rows
    let by_hand = logits
        .iter()
        .zip(targets)
        .map(|(row, t)| {
            let max = row.iter().copied().fold(f64::MIN, f64::max);
            row.iter().map(|v| (v - max).exp()).sum::<f64>().ln() - (row[t as usize] - max)
        })
        .sum::<f64>()
        / 3.0;
    println!(
        "candle {candle:.10}, by hand {by_hand:.10}, agree to 1e-12: {}",
        (candle - by_hand).abs() < 1e-12
    );

    println!("\n== logits of 1000, 0 and -1000, f64");
    let big = Tensor::new(&[[1000f64, 0., -1000.]], &dev)?;
    for t in 0u32..3 {
        let l = loss::cross_entropy(&big, &Tensor::new(&[t], &dev)?)?;
        println!("target {t}: cross_entropy {:.1}", l.to_scalar::<f64>()?);
    }
    show("ops::log_softmax", &ops::log_softmax(&big, 1)?, 1)?;
    let naive = big
        .exp()?
        .broadcast_div(&big.exp()?.sum_keepdim(1)?)?
        .log()?;
    show("log(exp(z) / sum(exp(z))), written naively", &naive, 1)?;

    println!("\n== the targets nll accepts");
    outcome(
        "i64 targets",
        loss::cross_entropy(&z, &Tensor::new(&[0i64, 3, 1], &dev)?),
    );
    outcome(
        "f32 targets",
        loss::cross_entropy(&z, &Tensor::new(&[0f32, 3., 1.], &dev)?),
    );
    outcome(
        "a target out of range, 4 of 4 classes",
        loss::cross_entropy(&z, &Tensor::new(&[0u32, 4, 1], &dev)?),
    );
    // gather writes 0 for an index equal to the type's maximum: that row adds nothing, and still counts
    let skipped = loss::cross_entropy(&z, &Tensor::new(&[0u32, u32::MAX, 1], &dev)?)?;
    let rows = ops::log_softmax(&z, 1)?.to_vec2::<f64>()?;
    println!(
        "target u32::MAX in the second row: loss {:.10}, (row 1 + row 3) / 3 = {:.10}, / 2 = {:.10}",
        skipped.to_scalar::<f64>()?,
        -(rows[0][0] + rows[2][1]) / 3.0,
        -(rows[0][0] + rows[2][1]) / 2.0
    );

    println!("\n== binary_cross_entropy_with_logit, one logit at a time");
    println!(
        "type, logit, target: candle's loss and gradient | the stable form's loss and gradient"
    );
    let cases: [(DType, &[(f64, f64)]); 2] = [
        (
            DType::F32,
            &[
                (16.0, 1.0),
                (17.0, 1.0),
                (-100.0, 0.0),
                (17.0, 0.0),
                (-100.0, 1.0),
            ],
        ),
        (DType::F64, &[(36.0, 1.0), (37.0, 1.0), (-800.0, 0.0)]),
    ];
    for (dtype, list) in cases {
        for &(logit, target) in list {
            let x = Var::from_tensor(&Tensor::new(&[[logit]], &dev)?.to_dtype(dtype)?)?;
            let t = Tensor::new(&[[target]], &dev)?.to_dtype(dtype)?;
            let candle = loss::binary_cross_entropy_with_logit(&x, &t)?;
            let candle_grad = first(candle.backward()?.get(&x).unwrap())?;
            let stable = stable_bce(&x, &t)?;
            let stable_grad = first(stable.backward()?.get(&x).unwrap())?;
            println!(
                "{dtype:?}, {logit}, {target}: {} {} | {} {}",
                sci(first(&candle)?),
                sci(candle_grad),
                sci(first(&stable)?),
                sci(stable_grad)
            );
        }
    }
    let batch = Tensor::new(&[[16f32], [17.]], &dev)?;
    let ones = Tensor::new(&[[1f32], [1.]], &dev)?;
    println!(
        "a batch of the logits 16 and 17, targets 1, F32: mean loss {:.3e}",
        first(&loss::binary_cross_entropy_with_logit(&batch, &ones)?)?
    );
    // Its documentation describes the target as "a tensor of u32"
    outcome(
        "binary_cross_entropy_with_logit with U32 targets",
        loss::binary_cross_entropy_with_logit(&batch, &Tensor::new(&[[1u32], [1]], &dev)?),
    );
    Ok(())
}
