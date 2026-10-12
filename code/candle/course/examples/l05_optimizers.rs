//! Lesson 5: optimizers. An SGD step against θ − lr · g, three AdamW steps against the algorithm written by
//! hand, and the variables an optimizer keeps, drops or leaves alone.

use candle_core::{Device, Tensor, Var};
use candle_course::outcome;
use candle_nn::{AdamW, Optimizer, ParamsAdamW, SGD};

/// Σ (θ − t)², whose gradient is 2 (θ − t)
fn loss(theta: &Var, t: &Tensor) -> candle_core::Result<Tensor> {
    theta.sub(t)?.sqr()?.sum_all()
}

fn main() -> anyhow::Result<()> {
    let dev = Device::Cpu;
    let start = [0.5f64, -1.25, 2.0];
    let target = [1.0f64, 1.0, 1.0];
    let t = Tensor::new(&target, &dev)?;

    println!("== one SGD step, learning rate 0.1, f64");
    let theta = Var::new(&start, &dev)?;
    let mut sgd = SGD::new(vec![theta.clone()], 0.1)?;
    sgd.backward_step(&loss(&theta, &t)?)?;
    let candle: Vec<f64> = theta.to_vec1()?;
    let by_hand: Vec<f64> = start
        .iter()
        .zip(&target)
        .map(|(p, t)| p - (2.0 * (p - t)) * 0.1)
        .collect();
    println!(
        "candle  {candle:?}\nby hand {by_hand:?}\nbit for bit: {}",
        candle == by_hand
    );

    println!("\n== three AdamW steps, learning rate 0.1, the other parameters at their defaults");
    let params = ParamsAdamW {
        lr: 0.1,
        ..Default::default()
    };
    println!("{params:?}");
    let ParamsAdamW {
        lr,
        beta1,
        beta2,
        eps,
        weight_decay,
    } = params;
    let theta = Var::new(&start, &dev)?;
    let mut adamw = AdamW::new(vec![theta.clone()], params)?;
    let (mut p, mut m, mut v) = (start.to_vec(), vec![0.0; 3], vec![0.0; 3]);
    for step in 1..=3 {
        adamw.backward_step(&loss(&theta, &t)?)?;
        // Decoupled weight decay, moments corrected for their zero start, ε added after the square root
        for i in 0..3 {
            let g = 2.0 * (p[i] - target[i]);
            m[i] = m[i] * beta1 + g * (1.0 - beta1);
            v[i] = v[i] * beta2 + g * g * (1.0 - beta2);
            let m_hat = m[i] * (1.0 / (1.0 - beta1.powi(step)));
            let v_hat = v[i] * (1.0 / (1.0 - beta2.powi(step)));
            p[i] = p[i] * (1.0 - lr * weight_decay) - m_hat / (v_hat.sqrt() + eps) * lr;
        }
        let c: Vec<f64> = theta.to_vec1()?;
        let gap = c
            .iter()
            .zip(&p)
            .map(|(a, b)| (a - b).abs())
            .fold(0.0, f64::max);
        println!(
            "step {step}: candle {c:.12?}, by hand {p:.12?}, within 1e-12 {}, bit for bit {}",
            gap < 1e-12,
            c == p
        );
    }

    println!("\n== the variables an optimizer keeps");
    let int = Var::new(&[1u32, 2, 3], &dev)?;
    let float = Var::new(&[1f32, 2., 3.], &dev)?;
    let sgd = SGD::new(vec![int.clone(), float.clone()], 0.1)?;
    println!(
        "SGD::new with a U32 and an F32 variable: ok, it keeps {}",
        sgd.into_inner().len()
    );
    outcome(
        "AdamW::new with the same two variables",
        AdamW::new(vec![int, float], ParamsAdamW::default()),
    );
    // A variable the loss doesn't use gets no gradient, and step skips it without a word
    let used = Var::new(&start, &dev)?;
    let unused = Var::new(&start, &dev)?;
    let mut sgd = SGD::new(vec![used.clone(), unused.clone()], 0.1)?;
    sgd.backward_step(&loss(&used, &t)?)?;
    println!(
        "a step on a loss of `used` only: used changed {}, unused changed {}",
        used.to_vec1::<f64>()? != start,
        unused.to_vec1::<f64>()? != start
    );
    Ok(())
}
