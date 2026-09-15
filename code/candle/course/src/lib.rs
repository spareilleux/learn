//! Helpers shared by the examples of the Candle course: printing tensors with rounded values, so that
//! the three operating systems print the same digits, and printing the message of a Candle error.

use candle_core::{Result, Tensor};

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
}
