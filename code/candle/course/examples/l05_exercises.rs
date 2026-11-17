//! Lesson 5, solutions of the exercises: the two rows where UCI's iris.data differs from Fisher's paper,
//! SGD with momentum written with Var::set, and the order in which VarMap::load expects its variables.

use candle_core::{DType, Device, Tensor, Var};
use candle_course::{iris, reseed};
use candle_nn::{Module, Optimizer, SGD, VarBuilder, VarMap, loss};

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

    println!("== exercise 1: iris.data against bezdekIris.data");
    let old = include_str!("../../data/iris.data");
    let new = include_str!("../../data/bezdekIris.data");
    for (i, (a, b)) in old.lines().zip(new.lines()).enumerate() {
        if a != b {
            println!("row {}: iris.data {a}, bezdekIris.data {b}", i + 1);
        }
    }
    let rows = iris::parse(old);
    println!(
        "rows 35 and 38 of iris.data are identical: {}",
        rows[34] == rows[37]
    );

    let data = iris::split(&iris::parse(new));
    let x = iris::features(&data.train_x, DType::F64, &dev)?;
    let y = Tensor::new(data.train_y.as_slice(), &dev)?;

    println!("\n== exercise 2: SGD with momentum 0.9, written with Var::set, learning rate 0.01");
    for momentum in [0.0, 0.9] {
        let varmap = VarMap::new();
        let model = iris::model(VarBuilder::from_varmap(&varmap, DType::F64, &dev))?;
        reseed(&varmap, 5)?;
        let vars: Vec<Var> = varmap.all_vars();
        let mut buffers: Vec<Option<Tensor>> = vec![None; vars.len()];
        for _ in 0..300 {
            let grads = loss::cross_entropy(&model.forward(&x)?, &y)?.backward()?;
            for (var, buffer) in vars.iter().zip(buffers.iter_mut()) {
                let g = grads.get(var).unwrap();
                // PyTorch's rule: the buffer starts as the first gradient, then b = μ b + g; θ = θ − lr b
                let b = match buffer.take() {
                    None => g.clone(),
                    Some(b) => ((b * momentum)? + g)?,
                };
                var.set(&var.sub(&(&b * 0.01)?)?)?;
                *buffer = Some(b);
            }
        }
        println!(
            "momentum {momentum}: loss after 300 epochs {:.4}",
            iris::loss(&model, &x, &y)?
        );
    }
    // Momentum 0 by hand must match candle's SGD, which has no momentum
    let varmap = VarMap::new();
    let model = iris::model(VarBuilder::from_varmap(&varmap, DType::F64, &dev))?;
    reseed(&varmap, 5)?;
    let mut sgd = SGD::new(varmap.all_vars(), 0.01)?;
    iris::train(&model, &mut sgd, &x, &y, 300)?;
    println!(
        "candle's SGD, same learning rate: {:.4}",
        iris::loss(&model, &x, &y)?
    );

    println!("\n== exercise 3: save, then load in the two possible orders");
    let trained = VarMap::new();
    let model = iris::model(VarBuilder::from_varmap(&trained, DType::F64, &dev))?;
    reseed(&trained, 5)?;
    let mut opt = SGD::new(trained.all_vars(), 0.1)?;
    iris::train(&model, &mut opt, &x, &y, 50)?;
    let path = std::env::temp_dir().join("candle-course-l05-iris.safetensors");
    trained.save(&path)?;
    // Model first, then load: load overwrites the variables the map already holds
    let mut first = VarMap::new();
    let _model = iris::model(VarBuilder::from_varmap(&first, DType::F64, &dev))?;
    first.load(&path)?;
    println!(
        "layers built, then load: same values {}",
        values(&first)? == values(&trained)?
    );
    // Load first: the map is empty, nothing is kept, and the layers built afterwards are random
    let mut second = VarMap::new();
    second.load(&path)?;
    println!(
        "load into an empty VarMap: ok, {} variables",
        second.all_vars().len()
    );
    let _model = iris::model(VarBuilder::from_varmap(&second, DType::F64, &dev))?;
    println!(
        "then the layers: same values {}",
        values(&second)? == values(&trained)?
    );
    std::fs::remove_file(&path)?;
    Ok(())
}
