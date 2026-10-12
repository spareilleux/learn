//! Helpers shared by the examples of the Candle course: printing tensors with rounded values, so that
//! the three operating systems print the same digits, printing the message of a Candle error, a seeded
//! generator for initial weights, and the Iris data set of lesson 5.

use candle_core::{Result, Tensor};
use candle_nn::VarMap;

/// Shape, dtype and values of a tensor of any rank, every value rounded to `decimals` and printed as f64.
pub fn show(label: &str, t: &Tensor, decimals: usize) -> Result<()> {
    let values = t
        .flatten_all()?
        .to_dtype(candle_core::DType::F64)?
        .to_vec1::<f64>()?;
    let values: Vec<String> = values.iter().map(|v| format!("{v:.decimals$}")).collect();
    println!(
        "{label}: shape {:?}, {:?}, [{}]",
        t.dims(),
        t.dtype(),
        values.join(", ")
    );
    Ok(())
}

/// Prints `label: ok` or `label: error: <message>`, for the operations a lesson shows failing.
pub fn outcome<T>(label: &str, result: Result<T>) {
    match result {
        Ok(_) => println!("{label}: ok"),
        Err(e) => println!("{label}: error: {e}"),
    }
}

/// Runs `f` and prints its panic message instead of letting the panic end the program. Candle panics,
/// rather than returning an error, for a few operations the lessons show; the default hook would also
/// print the thread id and a path in the Cargo registry, which change from one machine to the next.
pub fn caught<T>(label: &str, f: impl FnOnce() -> T) {
    let hook = std::panic::take_hook();
    std::panic::set_hook(Box::new(|_| {}));
    let result = std::panic::catch_unwind(std::panic::AssertUnwindSafe(f));
    std::panic::set_hook(hook);
    match result {
        Ok(_) => println!("{label}: no panic"),
        Err(payload) => {
            let message = payload
                .downcast_ref::<String>()
                .cloned()
                .or_else(|| payload.downcast_ref::<&str>().map(|s| s.to_string()))
                .unwrap_or_default();
            println!("{label}: panic: {message}");
        }
    }
}

/// SplitMix64, the generator of Steele, Lea and Flood (2014) as Vigna writes it in C, for the examples
/// that need the same initial weights on every run: Candle's CPU generator can't be seeded (lesson 2).
pub struct SplitMix64(u64);

impl SplitMix64 {
    pub fn new(seed: u64) -> Self {
        Self(seed)
    }

    pub fn next_u64(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(0x9E37_79B9_7F4A_7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58_476D_1CE4_E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D0_49BB_1331_11EB);
        z ^ (z >> 31)
    }

    /// A value in `[lo, hi)` from the top 53 bits. Only a division by a power of two, a multiplication
    /// and an addition: every system rounds them the same way, unlike `ln` or `cos` for a normal draw.
    pub fn uniform(&mut self, lo: f64, hi: f64) -> f64 {
        let u = (self.next_u64() >> 11) as f64 / (1u64 << 53) as f64;
        lo + (hi - lo) * u
    }
}

/// Overwrites every variable of a `VarMap` filled by `candle_nn::linear` with seeded uniform values:
/// weights in ±√(6 / in), the standard deviation √(2 / in) of linear's Kaiming normal, and biases in
/// ±1/√in, the range linear draws them from. Names are visited in sorted order: a `VarMap` is a `HashMap`.
pub fn reseed(varmap: &VarMap, seed: u64) -> Result<()> {
    let data = varmap.data().lock().unwrap();
    let mut names: Vec<&String> = data.keys().collect();
    names.sort();
    let mut rng = SplitMix64::new(seed);
    for name in names {
        let var = &data[name];
        let bound = if name.ends_with(".weight") {
            (6.0 / var.dims()[1] as f64).sqrt()
        } else if let Some(layer) = name.strip_suffix(".bias") {
            match data.get(&format!("{layer}.weight")) {
                Some(weight) => 1.0 / (weight.dims()[1] as f64).sqrt(),
                None => candle_core::bail!("{name} has no matching weight"),
            }
        } else {
            candle_core::bail!("{name} is neither a weight nor a bias")
        };
        let values: Vec<f64> = (0..var.elem_count())
            .map(|_| rng.uniform(-bound, bound))
            .collect();
        var.set(&Tensor::from_vec(values, var.dims(), var.device())?.to_dtype(var.dtype())?)?;
    }
    Ok(())
}

/// Iris (Fisher, 1936) from the UCI Machine Learning Repository, split and standardized as lesson 5 uses it.
pub mod iris {
    use candle_core::{DType, Device, Result, Tensor};
    use candle_nn::{Activation, Module, Optimizer, Sequential, VarBuilder, linear, loss, seq};

    pub const SPECIES: [&str; 3] = ["setosa", "versicolor", "virginica"];

    /// The rows of a UCI Iris file: four measurements in centimetres and the species' index
    pub fn parse(text: &str) -> Vec<([f64; 4], u32)> {
        text.lines()
            .filter(|line| !line.is_empty())
            .map(|line| {
                let fields: Vec<&str> = line.split(',').collect();
                let mut x = [0.0; 4];
                for (value, field) in x.iter_mut().zip(&fields) {
                    *value = field.parse().unwrap();
                }
                let name = fields[4].trim_start_matches("Iris-");
                let species = SPECIES.iter().position(|s| *s == name).unwrap();
                (x, species as u32)
            })
            .collect()
    }

    pub struct Split {
        pub train_x: Vec<[f64; 4]>,
        pub train_y: Vec<u32>,
        pub test_x: Vec<[f64; 4]>,
        pub test_y: Vec<u32>,
        pub means: [f64; 4],
        pub sds: [f64; 4],
    }

    /// Every fifth flower of each species (positions 4, 9, 14… within it) is held out for the test; both
    /// sets are standardized with the means and standard deviations of the training set
    pub fn split(rows: &[([f64; 4], u32)]) -> Split {
        let mut seen = [0usize; 3];
        let (mut train, mut test) = (vec![], vec![]);
        for &(x, y) in rows {
            if seen[y as usize] % 5 == 4 {
                test.push((x, y));
            } else {
                train.push((x, y));
            }
            seen[y as usize] += 1;
        }
        let n = train.len() as f64;
        let mut means = [0.0; 4];
        let mut sds = [0.0; 4];
        for j in 0..4 {
            means[j] = train.iter().map(|(x, _)| x[j]).sum::<f64>() / n;
            sds[j] = (train
                .iter()
                .map(|(x, _)| (x[j] - means[j]).powi(2))
                .sum::<f64>()
                / n)
                .sqrt();
        }
        let standardize = |x: &[f64; 4]| -> [f64; 4] {
            let mut z = [0.0; 4];
            for j in 0..4 {
                z[j] = (x[j] - means[j]) / sds[j];
            }
            z
        };
        Split {
            train_x: train.iter().map(|(x, _)| standardize(x)).collect(),
            train_y: train.iter().map(|(_, y)| *y).collect(),
            test_x: test.iter().map(|(x, _)| standardize(x)).collect(),
            test_y: test.iter().map(|(_, y)| *y).collect(),
            means,
            sds,
        }
    }

    /// Rows of four features as an (n, 4) tensor of the given type
    pub fn features(x: &[[f64; 4]], dtype: DType, dev: &Device) -> Result<Tensor> {
        let values: Vec<f64> = x.iter().flatten().copied().collect();
        Tensor::from_vec(values, (x.len(), 4), dev)?.to_dtype(dtype)
    }

    /// 4 → 16 → 3 with a ReLU, its variables named hidden.weight, hidden.bias, out.weight and out.bias
    pub fn model(vb: VarBuilder) -> Result<Sequential> {
        Ok(seq()
            .add(linear(4, 16, vb.pp("hidden"))?)
            .add(Activation::Relu)
            .add(linear(16, 3, vb.pp("out"))?))
    }

    /// Full-batch training: one step per epoch on the cross-entropy of the whole training set. Returns the
    /// loss each epoch stepped on, so `losses[0]` is the loss of the initial weights.
    pub fn train<O: Optimizer>(
        model: &Sequential,
        opt: &mut O,
        x: &Tensor,
        y: &Tensor,
        epochs: usize,
    ) -> Result<Vec<f64>> {
        let mut losses = Vec::with_capacity(epochs);
        for _ in 0..epochs {
            let loss = loss::cross_entropy(&model.forward(x)?, y)?;
            losses.push(loss.to_dtype(DType::F64)?.to_scalar::<f64>()?);
            opt.backward_step(&loss)?;
        }
        Ok(losses)
    }

    /// The cross-entropy of the current weights
    pub fn loss(model: &Sequential, x: &Tensor, y: &Tensor) -> Result<f64> {
        loss::cross_entropy(&model.forward(x)?, y)?
            .to_dtype(DType::F64)?
            .to_scalar::<f64>()
    }

    /// The index of the largest logit of each row
    pub fn predict(model: &Sequential, x: &Tensor) -> Result<Vec<u32>> {
        model.forward(x)?.argmax(1)?.to_vec1::<u32>()
    }
}

/// Snippets the lessons show being rejected by the compiler. Each one is a `compile_fail` doctest with the
/// error code rustc gives, so `cargo test` fails if a new version of Candle or Rust starts accepting it.
pub mod rejected {
    /// Lesson 1: an operation returns a `Result`, which can't be printed as a tensor without `?`.
    ///
    /// ```compile_fail,E0277
    /// use candle_core::{Device, Tensor};
    /// let a = Tensor::arange(0f32, 6., &Device::Cpu).unwrap().reshape((2, 3)).unwrap();
    /// let b = Tensor::arange(0f32, 12., &Device::Cpu).unwrap().reshape((3, 4)).unwrap();
    /// let c = a.matmul(&b);
    /// println!("{c}");
    /// ```
    pub fn result_is_not_a_tensor() {}

    /// Lesson 1: the cheat sheet of Candle's README passes the dtype by reference.
    ///
    /// ```compile_fail,E0308
    /// use candle_core::{DType, Device, Tensor};
    /// # fn f() -> candle_core::Result<()> {
    /// let tensor = Tensor::zeros((2, 2), DType::F32, &Device::Cpu)?;
    /// let half = tensor.to_dtype(&DType::F16)?;
    /// # Ok(()) }
    /// ```
    pub fn readme_to_dtype_by_reference() {}

    /// Lesson 2: rows of different lengths are different array types.
    ///
    /// ```compile_fail,E0308
    /// use candle_core::{Device, Tensor};
    /// let ragged = Tensor::new(&[[1f32, 2.], [3., 4., 5.]], &Device::Cpu);
    /// ```
    pub fn ragged_rows() {}

    /// Lesson 2: arithmetic operators on tensors return a `Result`, and a `Result` has no tensor methods.
    ///
    /// ```compile_fail,E0599
    /// use candle_core::{Device, Tensor};
    /// # fn f() -> candle_core::Result<()> {
    /// let a = Tensor::new(&[1f32, 2.], &Device::Cpu)?;
    /// let total = (&a + &a).sum_all()?;
    /// # Ok(()) }
    /// ```
    pub fn operator_result_has_no_methods() {}

    /// Lesson 2: `Result<Tensor> - f64` isn't implemented, only `Tensor - f64`.
    ///
    /// ```compile_fail,E0277
    /// use candle_core::{Device, Tensor};
    /// # fn f() -> candle_core::Result<()> {
    /// let m = Tensor::new(&[1f32, 2.], &Device::Cpu)?;
    /// let shifted = (&m * 2.0) - 1.0;
    /// # Ok(()) }
    /// ```
    pub fn result_minus_scalar() {}

    /// Lesson 2: tensors have no `[]` indexing; `i` from `IndexOp` returns a `Result<Tensor>`.
    ///
    /// ```compile_fail,E0608
    /// use candle_core::{Device, Tensor};
    /// # fn f() -> candle_core::Result<()> {
    /// let m = Tensor::new(&[[1f32, 2.], [3., 4.]], &Device::Cpu)?;
    /// let first = m[0];
    /// # Ok(()) }
    /// ```
    pub fn square_bracket_indexing() {}

    /// Lesson 4: a `Var` can only be made by Candle's constructors, not from any tensor by hand.
    ///
    /// ```compile_fail,E0423
    /// use candle_core::{Device, Tensor, Var};
    /// # fn f() -> candle_core::Result<()> {
    /// let t = Tensor::new(&[1f32, 2.], &Device::Cpu)?;
    /// let v = Var(t);
    /// # Ok(()) }
    /// ```
    pub fn var_from_tuple_struct() {}

    /// Lesson 5: `forward` is a method of the `Module` trait, which has to be in scope.
    ///
    /// ```compile_fail,E0599
    /// use candle_core::{Device, Tensor};
    /// use candle_nn::Linear;
    /// # fn f() -> candle_core::Result<()> {
    /// let layer = Linear::new(Tensor::new(&[[1f32, 2.]], &Device::Cpu)?, None);
    /// let y = layer.forward(&Tensor::new(&[[3f32, 4.]], &Device::Cpu)?)?;
    /// # Ok(()) }
    /// ```
    pub fn forward_without_module() {}

    /// Lesson 5: `SGD::new` is a function of the `Optimizer` trait, which has to be in scope.
    ///
    /// ```compile_fail,E0599
    /// use candle_core::{Device, Var};
    /// use candle_nn::SGD;
    /// # fn f() -> candle_core::Result<()> {
    /// let w = Var::new(&[1f32, 2.], &Device::Cpu)?;
    /// let sgd = SGD::new(vec![w], 0.1)?;
    /// # Ok(()) }
    /// ```
    pub fn sgd_new_without_optimizer() {}
}
