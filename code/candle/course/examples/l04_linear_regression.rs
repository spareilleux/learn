//! Lesson 4: the linear regression of the IX course, lesson 2 (build seconds as a line of the page count),
//! trained with Candle's gradients, and the gradient compared with ix-autograd's tape.

use candle_core::{DType, Device, Tensor, Var};
use ix_autograd::prelude::{DiffContext, ExecutionMode, Tensor as IxTensor};
use ix_autograd::tools::linear_regression::LinearRegressionTool;
use ndarray::{ArrayD, IxDyn};

/// Page counts and build seconds of the first `n` builds of data/builds.csv, in commit order
fn training_builds(n: usize) -> (Vec<f64>, Vec<f64>) {
    let csv = include_str!("../../data/builds.csv");
    csv.lines()
        .skip(1)
        .take(n)
        .map(|line| {
            let fields: Vec<&str> = line.split(',').collect();
            (
                fields[2].parse::<f64>().unwrap(),
                fields[3].parse::<f64>().unwrap(),
            )
        })
        .unzip()
}

/// Mean squared error of the line w * x + b, built from tensor operations so that backward can follow it
fn mse(x: &Tensor, y: &Tensor, w: &Tensor, b: &Tensor) -> candle_core::Result<Tensor> {
    x.broadcast_mul(w)?
        .broadcast_add(b)?
        .sub(y)?
        .sqr()?
        .mean_all()
}

fn main() -> anyhow::Result<()> {
    let dev = Device::Cpu;
    // The IX course trains on the first 80% of the 65 builds, in commit order
    let (pages, seconds) = training_builds(52);
    let n = pages.len() as f64;

    println!("== closed form in plain Rust, f64, {} builds", pages.len());
    let mean_x = pages.iter().sum::<f64>() / n;
    let mean_y = seconds.iter().sum::<f64>() / n;
    let cov: f64 = pages
        .iter()
        .zip(&seconds)
        .map(|(x, y)| (x - mean_x) * (y - mean_y))
        .sum();
    let var: f64 = pages.iter().map(|x| (x - mean_x).powi(2)).sum();
    let (w_star, b_star) = (cov / var, mean_y - cov / var * mean_x);
    println!("seconds = {w_star:.6} * pages + {b_star:.6}");

    println!("\n== gradient of the loss at w = 0, b = 0, raw pages");
    let x = Tensor::from_vec(pages.clone(), pages.len(), &dev)?;
    let y = Tensor::from_vec(seconds.clone(), seconds.len(), &dev)?;
    let w = Var::new(0f64, &dev)?;
    let b = Var::new(0f64, &dev)?;
    let loss = mse(&x, &y, &w, &b)?;
    let grads = loss.backward()?;
    let (dw, db) = (
        grads.get(&w).unwrap().to_scalar::<f64>()?,
        grads.get(&b).unwrap().to_scalar::<f64>()?,
    );
    println!(
        "candle:  loss {:.6}, dw {dw:.6}, db {db:.6}",
        loss.to_scalar::<f64>()?
    );
    // By hand, as in the IX course: dL/dw = 2/n sum((w x + b - y) x), dL/db = 2/n sum(w x + b - y)
    let hand_dw: f64 = pages
        .iter()
        .zip(&seconds)
        .map(|(x, y)| 2.0 * (0.0 * x + 0.0 - y) * x / n)
        .sum();
    let hand_db: f64 = seconds.iter().map(|y| 2.0 * (0.0 - y) / n).sum();
    println!("by hand:              dw {hand_dw:.6}, db {hand_db:.6}");

    // ix-autograd: the same graph on its tape, with x as an (n, 1) matrix and w, b as (1, 1)
    let column = |v: &[f64]| ArrayD::from_shape_vec(IxDyn(&[v.len(), 1]), v.to_vec()).unwrap();
    let scalar = |v: f64| ArrayD::from_elem(IxDyn(&[1, 1]), v);
    let mut ctx = DiffContext::new(ExecutionMode::Train);
    let state = LinearRegressionTool::build_graph(
        &mut ctx,
        IxTensor::from_array(column(&pages)),
        IxTensor::from_array_with_grad(scalar(0.0)),
        IxTensor::from_array_with_grad(scalar(0.0)),
        IxTensor::from_array(column(&seconds)),
    )?;
    let ix_loss = ctx
        .tape
        .get(state.loss)
        .unwrap()
        .value
        .as_f64()
        .iter()
        .next()
        .copied()
        .unwrap();
    let ix_grads = ctx.backward(state.loss, ArrayD::from_elem(IxDyn(&[]), 1.0))?;
    let (ix_dw, ix_db) = (ix_grads[&state.w][[0, 0]], ix_grads[&state.b][[0, 0]]);
    println!("ix:      loss {ix_loss:.6}, dw {ix_dw:.6}, db {ix_db:.6}");
    println!(
        "candle and ix agree to 1e-9: {}",
        (dw - ix_dw).abs() < 1e-9
            && (db - ix_db).abs() < 1e-9
            && (loss.to_scalar::<f64>()? - ix_loss).abs() < 1e-9
    );
    println!(
        "tape nodes in ix: {}, nodes behind candle's loss: {}",
        ctx.tape.len(),
        loss.sorted_nodes().len()
    );
    println!(
        "gradients ix computed: {}, gradients candle kept: {}",
        ix_grads.len(),
        grads.get_ids().count()
    );

    println!("\n== gradient descent with Var::set, raw pages");
    for lr in [3e-5, 1e-5] {
        let w = Var::new(0f64, &dev)?;
        let b = Var::new(0f64, &dev)?;
        print!("learning rate {lr:e}:");
        for step in 1..=1000 {
            let grads = mse(&x, &y, &w, &b)?.backward()?;
            w.set(&(w.as_tensor() - (grads.get(&w).unwrap() * lr)?)?)?;
            b.set(&(b.as_tensor() - (grads.get(&b).unwrap() * lr)?)?)?;
            // The loss after the step, as the IX course prints it
            if [1, 10, 1000].contains(&step) {
                print!(
                    " step {step} loss {:.3e}",
                    mse(&x, &y, &w, &b)?.to_scalar::<f64>()?
                );
            }
        }
        println!(
            " -> w {:.4e}, b {:.4e}",
            w.to_scalar::<f64>()?,
            b.to_scalar::<f64>()?
        );
    }

    println!(
        "\n== gradient descent with Var::set, standardized pages, learning rate 0.1, 100 steps"
    );
    let sd_x = (pages.iter().map(|p| (p - mean_x).powi(2)).sum::<f64>() / n).sqrt();
    for dtype in [DType::F64, DType::F32] {
        let z = x.affine(1.0 / sd_x, -mean_x / sd_x)?.to_dtype(dtype)?;
        let yt = y.to_dtype(dtype)?;
        let ws = Var::zeros((), dtype, &dev)?;
        let bs = Var::zeros((), dtype, &dev)?;
        for _ in 0..100 {
            let grads = mse(&z, &yt, &ws, &bs)?.backward()?;
            ws.set(&(ws.as_tensor() - (grads.get(&ws).unwrap() * 0.1)?)?)?;
            bs.set(&(bs.as_tensor() - (grads.get(&bs).unwrap() * 0.1)?)?)?;
        }
        let ws = ws.to_dtype(DType::F64)?.to_scalar::<f64>()?;
        let bs = bs.to_dtype(DType::F64)?.to_scalar::<f64>()?;
        let (w, b) = (ws / sd_x, bs - ws * mean_x / sd_x);
        println!(
            "{dtype:?}: ws {ws:.6}, bs {bs:.6} -> w {w:.6}, b {b:.6}, gap to the closed form {:.1e}",
            (w - w_star).abs().max((b - b_star).abs())
        );
    }
    Ok(())
}
