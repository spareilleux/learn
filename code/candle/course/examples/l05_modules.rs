//! Lesson 5: modules. A Linear layer from given tensors, a Sequential, the names and shapes a VarMap holds,
//! the statistics of candle_nn::linear's initialization, and the seeded weights the course uses instead.

use candle_core::{DType, Device, Tensor};
use candle_course::{outcome, reseed, show};
use candle_nn::{Activation, Init, Linear, Module, VarBuilder, VarMap, linear, seq};

/// Mean and population standard deviation
fn mean_sd(values: &[f64]) -> (f64, f64) {
    let n = values.len() as f64;
    let mean = values.iter().sum::<f64>() / n;
    let var = values.iter().map(|v| (v - mean).powi(2)).sum::<f64>() / n;
    (mean, var.sqrt())
}

/// Every value of a VarMap, variable after variable in sorted name order
fn values(varmap: &VarMap) -> candle_core::Result<Vec<f64>> {
    let data = varmap.data().lock().unwrap();
    let mut names: Vec<&String> = data.keys().collect();
    names.sort();
    let mut all = vec![];
    for name in names {
        all.extend(data[name].flatten_all()?.to_vec1::<f64>()?);
    }
    Ok(all)
}

fn main() -> anyhow::Result<()> {
    let dev = Device::Cpu;

    println!("== a Linear layer from given tensors: y = x · wᵀ + b");
    let w = Tensor::new(&[[1f64, 2.], [3., 4.], [5., 6.]], &dev)?;
    let b = Tensor::new(&[0.5f64, -0.5, 0.], &dev)?;
    let layer = Linear::new(w, Some(b));
    let x = Tensor::new(&[[10f64, 100.], [1., 1.]], &dev)?;
    show("x", &x, 1)?;
    show("layer.forward(&x)", &layer.forward(&x)?, 1)?;
    show(
        "x.matmul(&w.t()) + b",
        &x.matmul(&layer.weight().t()?)?
            .broadcast_add(layer.bias().unwrap())?,
        1,
    )?;

    println!("\n== a Sequential: Linear, ReLU, Linear");
    let model = seq()
        .add(Linear::new(
            Tensor::new(&[[1f64, -1.], [-1., 1.]], &dev)?,
            None,
        ))
        .add(Activation::Relu)
        .add(Linear::new(Tensor::new(&[[1f64, 1.]], &dev)?, None));
    println!("model.len(): {}", model.len());
    for (i, t) in model.forward_all(&x)?.iter().enumerate() {
        show(&format!("after layer {i}"), t, 1)?;
    }

    println!("\n== a VarMap behind a VarBuilder: linear(4, 16) and linear(16, 3)");
    let varmap = VarMap::new();
    let vb = VarBuilder::from_varmap(&varmap, DType::F64, &dev);
    let hidden = linear(4, 16, vb.pp("hidden"))?;
    let _out = linear(16, 3, vb.pp("out"))?;
    let mut names: Vec<(String, Vec<usize>)> = varmap
        .data()
        .lock()
        .unwrap()
        .iter()
        .map(|(name, var)| (name.clone(), var.dims().to_vec()))
        .collect();
    names.sort();
    for (name, dims) in &names {
        println!("{name}: {dims:?}");
    }
    let count: usize = names.iter().map(|(_, d)| d.iter().product::<usize>()).sum();
    println!(
        "parameters: {count}, all_vars(): {} variables",
        varmap.all_vars().len()
    );
    // Asking again for a name the map holds returns the variable it holds: the init is ignored
    let again = vb
        .pp("hidden")
        .get_with_hints((16, 4), "weight", Init::Const(0.))?;
    println!(
        "hidden.weight asked again with Init::Const(0.): same tensor {}, values still nonzero {}",
        again.id() == hidden.weight().id(),
        again.abs()?.sum_all()?.to_scalar::<f64>()? > 0.0
    );
    outcome(
        "hidden.weight asked with the shape (4, 16)",
        vb.pp("hidden")
            .get_with_hints((4, 16), "weight", Init::Const(0.)),
    );

    println!("\n== the initialization of linear(512, 512), f64");
    let big = VarMap::new();
    let layer = linear(512, 512, VarBuilder::from_varmap(&big, DType::F64, &dev))?;
    let w: Vec<f64> = layer.weight().flatten_all()?.to_vec1()?;
    let (mean, sd) = mean_sd(&w);
    let kaiming = (2.0f64 / 512.0).sqrt();
    let pytorch = 1.0 / (3.0f64 * 512.0).sqrt();
    println!(
        "weights: {} values, |mean| < 0.001 {}, sd within 1% of √(2 / 512) = {kaiming:.4} {}",
        w.len(),
        mean.abs() < 1e-3,
        (sd / kaiming - 1.0).abs() < 0.01
    );
    // A normal distribution puts 4.55% of its values beyond two standard deviations, a uniform one none
    let beyond = w.iter().filter(|v| (*v - mean).abs() > 2.0 * sd).count() as f64 / w.len() as f64;
    println!(
        "share beyond 2 sd within half a point of 4.55%, as a normal distribution: {}",
        (beyond - 0.0455).abs() < 0.005
    );
    println!(
        "PyTorch's nn.Linear: sd 1/√(3 · 512) = {pytorch:.4}; candle's is {:.3} times larger",
        kaiming / pytorch
    );
    let b: Vec<f64> = layer.bias().unwrap().to_vec1()?;
    let bound = 1.0 / 512f64.sqrt();
    let (_, bias_sd) = mean_sd(&b);
    println!(
        "biases: {} values, all within ±1/√512 = ±{bound:.4} {}, sd within 10% of {pytorch:.4} {}",
        b.len(),
        b.iter().all(|v| v.abs() <= bound),
        (bias_sd / pytorch - 1.0).abs() < 0.1
    );

    println!("\n== two VarMaps filled by the same calls");
    let (first, second) = (VarMap::new(), VarMap::new());
    for vm in [&first, &second] {
        linear(
            4,
            16,
            VarBuilder::from_varmap(vm, DType::F64, &dev).pp("hidden"),
        )?;
    }
    println!("same values: {}", values(&first)? == values(&second)?);
    reseed(&first, 5)?;
    reseed(&second, 5)?;
    println!(
        "after reseed(&varmap, 5) on both: same values {}",
        values(&first)? == values(&second)?
    );
    let w = first.data().lock().unwrap()["hidden.weight"]
        .as_tensor()
        .clone();
    show("hidden.weight, first row", &w.get(0)?, 6)?;
    let bound = (6.0f64 / 4.0).sqrt();
    let all = w.flatten_all()?.to_vec1::<f64>()?;
    println!(
        "all 64 weights within ±√(6 / 4) = ±{bound:.4}: {}",
        all.iter().all(|v| v.abs() < bound)
    );
    Ok(())
}
