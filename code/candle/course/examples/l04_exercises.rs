//! Lesson 4, solutions of the exercises: the gradient of the logistic loss, and a quadratic fitted by descent.

use candle_core::{DType, Device, Tensor, Var};
use candle_course::show;

fn main() -> candle_core::Result<()> {
    let dev = Device::Cpu;

    println!("== exercise 1: gradient of the logistic loss");
    let x = Tensor::new(&[[1f64, 2.], [2., -1.], [-1., -3.], [0.5, 0.5]], &dev)?; // (4, 2)
    let y = Tensor::new(&[1f64, 0., 0., 1.], &dev)?;
    let w = Var::new(&[0.3f64, -0.2], &dev)?;
    let b = Var::new(0.1f64, &dev)?;
    // p = sigmoid(x.w + b), loss = -mean(y log p + (1 - y) log(1 - p))
    let z = x.matmul(&w.unsqueeze(1)?)?.squeeze(1)?.broadcast_add(&b)?;
    let p = z.neg()?.exp()?.affine(1., 1.)?.recip()?;
    let one_minus_y = y.affine(-1., 1.)?;
    let loss = (y.mul(&p.log()?)? + one_minus_y.mul(&p.affine(-1., 1.)?.log()?)?)?
        .mean_all()?
        .neg()?;
    let grads = loss.backward()?;
    println!("loss {:.6}", loss.to_scalar::<f64>()?);
    show("candle dw", grads.get(&w).unwrap(), 6)?;
    show("candle db", grads.get(&b).unwrap(), 6)?;
    // By hand: dL/dw = x^T (p - y) / n, dL/db = mean(p - y)
    let err = p.detach().sub(&y)?;
    show(
        "by hand dw",
        &(x.t()?.matmul(&err.unsqueeze(1)?)?.squeeze(1)? / 4.0)?,
        6,
    )?;
    show("by hand db", &err.mean_all()?, 6)?;

    println!("\n== exercise 2: seconds = a z^2 + b z + c on the standardized pages");
    let csv = include_str!("../../data/builds.csv");
    let (pages, seconds): (Vec<f64>, Vec<f64>) = csv
        .lines()
        .skip(1)
        .take(52)
        .map(|l| {
            let f: Vec<&str> = l.split(',').collect();
            (f[2].parse::<f64>().unwrap(), f[3].parse::<f64>().unwrap())
        })
        .unzip();
    let n = pages.len() as f64;
    let mean = pages.iter().sum::<f64>() / n;
    let sd = (pages.iter().map(|p| (p - mean).powi(2)).sum::<f64>() / n).sqrt();
    let z = Tensor::from_vec(pages, 52, &dev)?.affine(1. / sd, -mean / sd)?;
    let y = Tensor::from_vec(seconds, 52, &dev)?;
    let zz = z.sqr()?;
    let (qa, qb, qc) = (
        Var::zeros((), DType::F64, &dev)?,
        Var::zeros((), DType::F64, &dev)?,
        Var::zeros((), DType::F64, &dev)?,
    );
    let loss_of = |a: &Tensor, b: &Tensor, c: &Tensor| -> candle_core::Result<Tensor> {
        zz.broadcast_mul(a)?
            .add(&z.broadcast_mul(b)?)?
            .broadcast_add(c)?
            .sub(&y)?
            .sqr()?
            .mean_all()
    };
    for step in 1..=2000 {
        let grads = loss_of(&qa, &qb, &qc)?.backward()?;
        for v in [&qa, &qb, &qc] {
            v.set(&(v.as_tensor() - (grads.get(v).unwrap() * 0.05)?)?)?;
        }
        if [1, 100, 2000].contains(&step) {
            println!(
                "step {step}: loss {:.6}",
                loss_of(&qa, &qb, &qc)?.to_scalar::<f64>()?
            );
        }
    }
    println!(
        "a {:.6}, b {:.6}, c {:.6}",
        qa.to_scalar::<f64>()?,
        qb.to_scalar::<f64>()?,
        qc.to_scalar::<f64>()?
    );
    // The straight line of the lesson reaches 5.908583 on the same builds
    Ok(())
}
