//! Lesson 4: gradients with Var, backward and GradStore, checked against derivatives worked out by hand
//! and against finite differences.

use candle_core::{D, DType, Device, Tensor, Var};
use candle_course::{outcome, show};

fn main() -> candle_core::Result<()> {
    let dev = Device::Cpu;

    println!("== y = x^2 + 3x at x = 2, so dy/dx = 2x + 3 = 7");
    let x = Var::new(2f64, &dev)?;
    let y = (x.sqr()? + x.affine(3., 0.)?)?;
    let grads = y.backward()?;
    println!("y {}", y.to_scalar::<f64>()?);
    println!(
        "dy/dx {}",
        grads.get(&x).expect("x is a Var").to_scalar::<f64>()?
    );

    println!("\n== which tensors get a gradient");
    let w = Var::new(&[1f32, -2., 3.], &dev)?;
    let c = Tensor::new(&[4f32, 5., 6.], &dev)?;
    let loss = w.mul(&c)?.sqr()?.sum_all()?; // sum((w * c)^2), d/dw = 2 * w * c^2
    let grads = loss.backward()?;
    show("d loss / dw", grads.get(&w).unwrap(), 0)?;
    show(
        "2 * w * c^2 by hand",
        &(w.as_tensor() * 2.0)?.mul(&c.sqr()?)?,
        0,
    )?;
    show("d loss / dc, c a plain tensor", grads.get(&c).unwrap(), 0)?;
    println!("tensors in the GradStore: {}", grads.get_ids().count());
    let e = c.exp()?; // a plain tensor computed from another plain tensor
    let grads = w.mul(&e)?.sum_all()?.backward()?;
    println!(
        "loss = sum(w * exp(c)): gradient for e {}, for c {}",
        grads.get(&e).is_some(),
        grads.get(&c).is_some()
    );

    println!("\n== a tensor used twice adds up its gradients");
    let h = w.affine(1., 1.)?; // h = w + 1
    let twice = h.mul(&h)?.sum_all()?; // sum(h * h), d/dw = 2h
    show("d sum(h*h) / dw", twice.backward()?.get(&w).unwrap(), 0)?;

    println!("\n== backward on a tensor that isn't a scalar starts from ones");
    let v = w.sqr()?; // [w0^2, w1^2, w2^2]
    show(
        "d v / dw, seeded with ones",
        v.backward()?.get(&w).unwrap(),
        0,
    )?;
    show(
        "d sum(v) / dw",
        v.sum_all()?.backward()?.get(&w).unwrap(),
        0,
    )?;

    println!("\n== each backward returns a new GradStore: nothing accumulates between calls");
    let first = loss.backward()?;
    let second = loss.backward()?;
    show("first", first.get(&w).unwrap(), 0)?;
    show("second", second.get(&w).unwrap(), 0)?;

    println!("\n== detach and operations without a gradient");
    let stopped = w.detach().mul(&c)?.sum_all()?;
    println!(
        "through detach: gradient for w {:?}",
        stopped.backward()?.get(&w).map(|_| ())
    );
    let rounded = w.affine(0.5, 0.)?.round()?.sum_all()?;
    println!(
        "through round: gradient for w {:?}",
        rounded.backward()?.get(&w).map(|_| ())
    );
    let through_max = w.max_keepdim(D::Minus1)?.sum_all()?;
    show(
        "through max: d max(w) / dw",
        through_max.backward()?.get(&w).unwrap(),
        0,
    )?;

    println!("\n== matmul against finite differences, f64");
    let a = Var::new(&[[0.5f64, -1.0, 2.0], [1.5, 0.25, -0.75]], &dev)?;
    let b = Tensor::new(&[[1f64, 2.], [-1., 0.5], [3., -2.]], &dev)?;
    let f = |a: &Tensor| -> candle_core::Result<Tensor> { a.matmul(&b)?.tanh()?.sum_all() };
    let analytic = f(a.as_tensor())?.backward()?.get(&a).unwrap().clone();
    let eps = 1e-6;
    let base = a.as_tensor().flatten_all()?.to_vec1::<f64>()?;
    let mut numeric = Vec::new();
    for i in 0..base.len() {
        let (mut plus, mut minus) = (base.clone(), base.clone());
        plus[i] += eps;
        minus[i] -= eps;
        let fp = f(&Tensor::from_vec(plus, (2, 3), &dev)?)?.to_scalar::<f64>()?;
        let fm = f(&Tensor::from_vec(minus, (2, 3), &dev)?)?.to_scalar::<f64>()?;
        numeric.push((fp - fm) / (2.0 * eps));
    }
    let numeric = Tensor::from_vec(numeric, (2, 3), &dev)?;
    show("backward", &analytic, 6)?;
    show("finite differences", &numeric, 6)?;
    let gap = (&analytic - &numeric)?
        .abs()?
        .max_all()?
        .to_scalar::<f64>()?;
    println!("largest gap below 1e-8: {}", gap < 1e-8);

    println!("\n== Var::set changes the value in place");
    let p = Var::new(&[1f32, 2.], &dev)?;
    let before = p.as_tensor().clone();
    p.set(&Tensor::new(&[10f32, 20.], &dev)?)?;
    show("p after set", &p, 0)?;
    show("a clone taken before set sees it", &before, 0)?;
    outcome("p.set(&p.detach())", p.set(&p.detach()));
    outcome(
        "p.set(3 values)",
        p.set(&Tensor::new(&[1f32, 2., 3.], &dev)?),
    );
    outcome("p.set(f64 values)", p.set(&Tensor::new(&[1f64, 2.], &dev)?));
    let ints = Var::new(&[1u32, 2], &dev)?;
    let int_loss = ints.to_dtype(DType::F32)?.sum_all()?;
    println!(
        "gradient for a u32 Var: {:?}",
        int_loss.backward()?.get(&ints).map(|_| ())
    );
    Ok(())
}
