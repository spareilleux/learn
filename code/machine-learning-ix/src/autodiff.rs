//! Lesson 12: automatic differentiation. Forward mode with dual numbers and reverse mode with a scalar
//! tape, both by hand, then IX's `ix-autograd` tape, checked against closed forms, central differences and
//! the predictions preregistered in the journal.

use crate::sketch::splitmix64;
use ix_autograd::ops;
use ix_autograd::ops_fft;
use ix_autograd::prelude::*;
use ix_autograd::tools::linear_regression::{LinearRegressionTool, LinregState};
use ndarray::{Array, Array2, ArrayD, IxDyn};
use std::collections::HashMap;
use std::panic::{AssertUnwindSafe, catch_unwind};

/// A dual number v + d·ε with ε² = 0. Carrying d alongside v through every operation is forward mode:
/// d ends up holding the derivative with respect to whichever input was seeded with d = 1.
#[derive(Clone, Copy, Debug, PartialEq)]
pub struct Dual {
    pub v: f64,
    pub d: f64,
}

impl Dual {
    /// The input we differentiate with respect to
    pub fn var(v: f64) -> Self {
        Self { v, d: 1.0 }
    }

    /// Any other input
    pub fn constant(v: f64) -> Self {
        Self { v, d: 0.0 }
    }

    pub fn ln(self) -> Self {
        Self {
            v: self.v.ln(),
            d: self.d / self.v,
        }
    }

    pub fn sin(self) -> Self {
        Self {
            v: self.v.sin(),
            d: self.d * self.v.cos(),
        }
    }
}

impl std::ops::Add for Dual {
    type Output = Self;
    fn add(self, o: Self) -> Self {
        Self {
            v: self.v + o.v,
            d: self.d + o.d,
        }
    }
}

impl std::ops::Sub for Dual {
    type Output = Self;
    fn sub(self, o: Self) -> Self {
        Self {
            v: self.v - o.v,
            d: self.d - o.d,
        }
    }
}

impl std::ops::Mul for Dual {
    type Output = Self;
    fn mul(self, o: Self) -> Self {
        Self {
            v: self.v * o.v,
            d: self.d * o.v + self.v * o.d,
        }
    }
}

/// Baydin et al.'s running example, f(x1, x2) = ln(x1) + x1·x2 − sin(x2), in forward mode: one pass per
/// input, each seeding its own input with d = 1.
pub fn baydin_forward(x1: f64, x2: f64) -> (f64, [f64; 2]) {
    let f = |a: Dual, b: Dual| a.ln() + a * b - b.sin();
    let by_x1 = f(Dual::var(x1), Dual::constant(x2));
    let by_x2 = f(Dual::constant(x1), Dual::var(x2));
    (by_x1.v, [by_x1.d, by_x2.d])
}

/// One entry of a scalar Wengert list: the operation and the indices of its operands
#[derive(Clone, Copy, Debug, PartialEq)]
pub enum Op {
    Input,
    Add(usize, usize),
    Sub(usize, usize),
    Mul(usize, usize),
    Ln(usize),
    Sin(usize),
}

/// A scalar tape. Each entry's value is computed when it is appended; its adjoint, when the tape is walked
/// back. An operand always has a smaller index than the entry using it, so walking the indices downwards
/// visits every entry after all the entries that use it.
#[derive(Default, Debug)]
pub struct Tape {
    pub ops: Vec<Op>,
    pub values: Vec<f64>,
}

impl Tape {
    fn push(&mut self, op: Op, value: f64) -> usize {
        self.ops.push(op);
        self.values.push(value);
        self.ops.len() - 1
    }

    pub fn input(&mut self, v: f64) -> usize {
        self.push(Op::Input, v)
    }

    pub fn add(&mut self, a: usize, b: usize) -> usize {
        self.push(Op::Add(a, b), self.values[a] + self.values[b])
    }

    pub fn sub(&mut self, a: usize, b: usize) -> usize {
        self.push(Op::Sub(a, b), self.values[a] - self.values[b])
    }

    pub fn mul(&mut self, a: usize, b: usize) -> usize {
        self.push(Op::Mul(a, b), self.values[a] * self.values[b])
    }

    pub fn ln(&mut self, a: usize) -> usize {
        self.push(Op::Ln(a), self.values[a].ln())
    }

    pub fn sin(&mut self, a: usize) -> usize {
        self.push(Op::Sin(a), self.values[a].sin())
    }

    /// Reverse mode: the output's adjoint is 1, and each entry, from the last to the first, adds its adjoint
    /// times its local derivative to its operands' adjoints. One walk gives the derivative with respect to
    /// every input. An operand used twice, like r in r·r, collects two contributions.
    pub fn backward(&self, output: usize) -> Vec<f64> {
        let mut adjoint = vec![0.0; self.ops.len()];
        adjoint[output] = 1.0;
        for i in (0..=output).rev() {
            let g = adjoint[i];
            match self.ops[i] {
                Op::Input => {}
                Op::Add(a, b) => {
                    adjoint[a] += g;
                    adjoint[b] += g;
                }
                Op::Sub(a, b) => {
                    adjoint[a] += g;
                    adjoint[b] -= g;
                }
                Op::Mul(a, b) => {
                    adjoint[a] += g * self.values[b];
                    adjoint[b] += g * self.values[a];
                }
                Op::Ln(a) => adjoint[a] += g / self.values[a],
                Op::Sin(a) => adjoint[a] += g * self.values[a].cos(),
            }
        }
        adjoint
    }
}

/// The same function in reverse mode: one forward pass fills the tape (Baydin et al.'s v1 to v5), one
/// backward walk gives both partial derivatives.
pub fn baydin_reverse(x1: f64, x2: f64) -> (f64, [f64; 2], Tape) {
    let mut t = Tape::default();
    let a = t.input(x1);
    let b = t.input(x2);
    let v1 = t.ln(a);
    let v2 = t.mul(a, b);
    let v3 = t.sin(b);
    let v4 = t.add(v1, v2);
    let f = t.sub(v4, v3);
    let adjoint = t.backward(f);
    (t.values[f], [adjoint[a], adjoint[b]], t)
}

/// Uniform numbers from splitmix64 over a counter, the same stream as the numpy cross-check
pub struct Rng(pub u64);

impl Rng {
    /// In [0, 1), from the top 53 bits
    pub fn next_f64(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(1);
        (splitmix64(self.0) >> 11) as f64 / (1u64 << 53) as f64
    }
}

/// The noise IX's `minimize_linreg_mse` example adds to row i. For i < 20, `(i·7919 + 31) >> 16` is 0, 1
/// or 2, so this is −0.01 plus at most 1.2e-6.
pub fn example_noise(i: usize) -> f64 {
    let seed = (i as u64).wrapping_mul(7919).wrapping_add(31);
    (((seed >> 16) & 0x7fff) as f64 / 32767.0 - 0.5) * 0.02
}

/// The data of IX's `minimize_linreg_mse` example, rebuilt line for line: 20 rows of 3 features from a
/// hash of the index, and y = x·[0.5, −0.3, 0.8] + 0.1 + noise, summed in the example's order.
pub fn ix_example_data() -> (Array2<f64>, Vec<f64>) {
    const N: usize = 20;
    const F: usize = 3;
    let true_w = [0.5, -0.3, 0.8];
    let x = Array2::from_shape_fn((N, F), |(i, j)| {
        let seed = ((i * F + j) as u64)
            .wrapping_mul(1103515245)
            .wrapping_add(12345);
        (((seed >> 16) & 0x7fff) as f64 / 32767.0) * 2.0 - 1.0
    });
    let y = (0..N)
        .map(|i| {
            let mut yi = 0.1;
            for (j, wj) in true_w.iter().enumerate() {
                yi += x[[i, j]] * wj;
            }
            yi + example_noise(i)
        })
        .collect();
    (x, y)
}

/// A linear regression on IX's tape, and the gradients of its loss
pub struct IxLinreg {
    pub ctx: DiffContext,
    pub state: LinregState,
    pub grads: HashMap<TensorHandle, ArrayD<f64>>,
}

impl IxLinreg {
    pub fn loss(&self) -> f64 {
        self.value(self.state.loss)[0]
    }

    pub fn value(&self, h: TensorHandle) -> Vec<f64> {
        let node = self.ctx.tape.get(h).expect("node on the tape");
        node.value.as_f64().iter().copied().collect()
    }

    pub fn grad(&self, h: TensorHandle) -> Option<Vec<f64>> {
        self.grads.get(&h).map(|g| g.iter().copied().collect())
    }
}

/// `LinearRegressionTool::build_graph` then `backward` from the loss. x and y are built the way the IX
/// example builds them, with `Tensor::from_array` (requires_grad false); w and b with `from_array_with_grad`.
pub fn ix_linreg(x: &Array2<f64>, y: &[f64], w: &[f64], b: f64) -> IxLinreg {
    let mut ctx = DiffContext::new(ExecutionMode::Train);
    let state = LinearRegressionTool::build_graph(
        &mut ctx,
        Tensor::from_array(x.clone().into_dyn()),
        Tensor::from_array_with_grad(
            Array::from_shape_vec(IxDyn(&[w.len(), 1]), w.to_vec()).expect("w shape"),
        ),
        Tensor::from_array_with_grad(Array::from_elem(IxDyn(&[1, 1]), b)),
        Tensor::from_array(
            Array::from_shape_vec(IxDyn(&[y.len(), 1]), y.to_vec()).expect("y shape"),
        ),
    )
    .expect("linear regression graph");
    let grads = ctx
        .backward(state.loss, Array::from_elem(IxDyn(&[]), 1.0))
        .expect("backward");
    IxLinreg { ctx, state, grads }
}

/// The op names on a tape, in the order they were recorded
pub fn tape_ops(ctx: &DiffContext) -> Vec<&'static str> {
    (0..ctx.tape.len())
        .map(|i| ctx.tape.get(TensorHandle(i)).expect("node").op)
        .collect()
}

/// The nodes `ops::variance` adds after one input leaf
pub fn variance_ops() -> Vec<&'static str> {
    let mut ctx = DiffContext::new(ExecutionMode::Train);
    let a = ops::input(
        &mut ctx,
        Tensor::from_array_with_grad(
            Array::from_shape_vec(IxDyn(&[4]), vec![1.0, 2.0, 4.0, 8.0]).expect("shape"),
        ),
    );
    ops::variance(&mut ctx, a).expect("variance");
    tape_ops(&ctx)[1..].to_vec()
}

/// The mean squared error of y ≈ x·w + b and its gradients, written out: with r = x·w + b − y,
/// ∂L/∂w = (2/n)xᵀr, ∂L/∂b = (2/n)Σr, ∂L/∂x = (2/n)r wᵀ and ∂L/∂y = −(2/n)r.
pub struct ClosedForm {
    pub loss: f64,
    pub w: Vec<f64>,
    pub b: f64,
    pub x: Array2<f64>,
    pub y: Vec<f64>,
}

pub fn closed_form(x: &Array2<f64>, y: &[f64], w: &[f64], b: f64) -> ClosedForm {
    let (n, f) = x.dim();
    let r: Vec<f64> = (0..n)
        .map(|i| (0..f).map(|j| x[[i, j]] * w[j]).sum::<f64>() + b - y[i])
        .collect();
    let s = 2.0 / n as f64;
    ClosedForm {
        loss: r.iter().map(|ri| ri * ri).sum::<f64>() / n as f64,
        w: (0..f)
            .map(|j| s * (0..n).map(|i| x[[i, j]] * r[i]).sum::<f64>())
            .collect(),
        b: s * r.iter().sum::<f64>(),
        x: Array2::from_shape_fn((n, f), |(i, j)| s * r[i] * w[j]),
        y: r.iter().map(|ri| -s * ri).collect(),
    }
}

/// The same loss on the scalar tape: one entry per multiplication and addition, 20 × 3 products for the
/// example's data. Returns the loss and its gradients for w and b.
pub fn hand_tape_linreg(
    x: &Array2<f64>,
    y: &[f64],
    w: &[f64],
    b: f64,
) -> (f64, Vec<f64>, f64, usize) {
    let (n, f) = x.dim();
    let mut t = Tape::default();
    let wi: Vec<usize> = w.iter().map(|&v| t.input(v)).collect();
    let bi = t.input(b);
    let inv_n = t.input(1.0 / n as f64);
    let mut total: Option<usize> = None;
    for (i, &yv) in y.iter().enumerate() {
        let mut acc = bi;
        for (j, &wj) in wi.iter().enumerate().take(f) {
            let xij = t.input(x[[i, j]]);
            let p = t.mul(xij, wj);
            acc = t.add(acc, p);
        }
        let yi = t.input(yv);
        let r = t.sub(acc, yi);
        let sq = t.mul(r, r);
        total = Some(match total {
            None => sq,
            Some(s) => t.add(s, sq),
        });
    }
    let loss = t.mul(total.expect("at least one row"), inv_n);
    let adjoint = t.backward(loss);
    (
        t.values[loss],
        wi.iter().map(|&k| adjoint[k]).collect(),
        adjoint[bi],
        t.ops.len(),
    )
}

pub fn max_abs_diff(a: &[f64], b: &[f64]) -> f64 {
    assert_eq!(a.len(), b.len());
    a.iter()
        .zip(b)
        .map(|(p, q)| (p - q).abs())
        .fold(0.0, f64::max)
}

/// What an op did with two shapes that do not broadcast
#[derive(Debug, PartialEq)]
pub enum Outcome {
    Value,
    Error(String),
    Panic(String),
}

/// `add`, `sub` and `mul` on [2, 3] and [3, 2], each run under `catch_unwind`
pub fn mismatched_shapes() -> Vec<(&'static str, Outcome)> {
    type BinaryOp =
        fn(&mut DiffContext, TensorHandle, TensorHandle) -> ix_autograd::Result<TensorHandle>;
    let cases: [(&'static str, BinaryOp); 3] =
        [("add", ops::add), ("sub", ops::sub), ("mul", ops::mul)];
    cases
        .iter()
        .map(|&(name, op)| {
            let run = catch_unwind(AssertUnwindSafe(|| {
                let mut ctx = DiffContext::new(ExecutionMode::Train);
                let a = ops::input(&mut ctx, Tensor::from_array(Array::zeros(IxDyn(&[2, 3]))));
                let b = ops::input(&mut ctx, Tensor::from_array(Array::zeros(IxDyn(&[3, 2]))));
                op(&mut ctx, a, b).map(|_| ()).map_err(|e| e.to_string())
            }));
            let outcome = match run {
                Ok(Ok(())) => Outcome::Value,
                Ok(Err(e)) => Outcome::Error(e),
                Err(payload) => Outcome::Panic(
                    payload
                        .downcast_ref::<String>()
                        .cloned()
                        .or_else(|| payload.downcast_ref::<&str>().map(|s| s.to_string()))
                        .unwrap_or_default(),
                ),
            };
            (name, outcome)
        })
        .collect()
}

/// The mean squared error recomputed with plain loops in a fixed order, so that its rounding, and so the
/// finite-difference noise printed from it, is the same on every OS.
pub fn mse_plain(x: &Array2<f64>, y: &[f64], w: &[f64], b: f64) -> f64 {
    closed_form(x, y, w, b).loss
}

/// Central differences (f(x + εe_i) − f(x − εe_i)) / 2ε for every component i
pub fn central_differences(f: impl Fn(&[f64]) -> f64, x: &[f64], eps: f64) -> Vec<f64> {
    (0..x.len())
        .map(|i| {
            let mut plus = x.to_vec();
            plus[i] += eps;
            let mut minus = x.to_vec();
            minus[i] -= eps;
            (f(&plus) - f(&minus)) / (2.0 * eps)
        })
        .collect()
}

/// ε = 10^-1, 10^-2, …, 10^-last
pub fn decades(last: i32) -> Vec<f64> {
    (1..=last).map(|k| 10f64.powi(-k)).collect()
}

/// For the example's loss at w = 0, b = 0: the worst error of the central differences over the three
/// components of w, against the gradient IX's tape returns, for each ε
pub fn quadratic_fd_errors(x: &Array2<f64>, y: &[f64], eps: &[f64]) -> Vec<(f64, f64)> {
    let w0 = vec![0.0; x.ncols()];
    let run = ix_linreg(x, y, &w0, 0.0);
    let g = run.grad(run.state.w).expect("w gradient");
    eps.iter()
        .map(|&e| {
            let fd = central_differences(|w| mse_plain(x, y, w, 0.0), &w0, e);
            (e, max_abs_diff(&fd, &g))
        })
        .collect()
}

/// A signal of n samples uniform in [−1, 1] and n weights uniform in [0, 1], from one seed
pub fn signal_and_weights(seed: u64, n: usize) -> (Vec<f64>, Vec<f64>) {
    let mut rng = Rng(seed);
    let x = (0..n).map(|_| rng.next_f64() * 2.0 - 1.0).collect();
    let c = (0..n).map(|_| rng.next_f64()).collect();
    (x, c)
}

/// L = Σ c_k |Y_k| with Y = `ix_signal::fft::rfft(x)`, all N bins, summed in the order IX's `sum` uses
pub fn weighted_magnitude(x: &[f64], c: &[f64]) -> f64 {
    ix_signal::fft::rfft(x)
        .iter()
        .zip(c)
        .map(|(y, ck)| (y.re * y.re + y.im * y.im).sqrt() * ck)
        .sum()
}

/// ∂L/∂x from IX's tape: `rfft_magnitude`, `mul` by the weights, `sum`, then `backward`
pub fn ix_fft_gradient(x: &[f64], c: &[f64]) -> Vec<f64> {
    let n = x.len();
    let mut ctx = DiffContext::new(ExecutionMode::Train);
    let xh = ops::input(
        &mut ctx,
        Tensor::from_array_with_grad(
            Array::from_shape_vec(IxDyn(&[n]), x.to_vec()).expect("x shape"),
        ),
    );
    let ch = ops::input(
        &mut ctx,
        Tensor::from_array(Array::from_shape_vec(IxDyn(&[n]), c.to_vec()).expect("c shape")),
    );
    let mag = ops_fft::rfft_magnitude(&mut ctx, xh).expect("rfft_magnitude");
    let weighted = ops::mul(&mut ctx, mag, ch).expect("mul");
    let loss = ops::sum(&mut ctx, weighted).expect("sum");
    let grads = ctx
        .backward(loss, Array::from_elem(IxDyn(&[]), 1.0))
        .expect("backward");
    grads[&xh].iter().copied().collect()
}

/// The worst central-difference error against IX's FFT backward, for each ε, on one signal
pub fn fft_fd_errors(x: &[f64], c: &[f64], eps: &[f64]) -> Vec<(f64, f64)> {
    let g = ix_fft_gradient(x, c);
    eps.iter()
        .map(|&e| {
            let fd = central_differences(|s| weighted_magnitude(s, c), x, e);
            (e, max_abs_diff(&fd, &g))
        })
        .collect()
}

/// The ε with the smallest error in a table
pub fn best_eps(errors: &[(f64, f64)]) -> (f64, f64) {
    errors
        .iter()
        .copied()
        .fold((f64::NAN, f64::INFINITY), |best, e| {
            if e.1 < best.1 { e } else { best }
        })
}

/// The worst error over `signals` signals (seeds 1, 2, …) of n samples, at one ε
pub fn fft_fd_check(signals: u64, n: usize, eps: f64) -> f64 {
    (1..=signals)
        .map(|seed| {
            let (x, c) = signal_and_weights(seed, n);
            fft_fd_errors(&x, &c, &[eps])[0].1
        })
        .fold(0.0, f64::max)
}

/// Least squares with an intercept, from the normal equations (xᵀx)θ = xᵀy solved by Gaussian elimination
/// with partial pivoting. Returns w, b and the mean squared error of the fit.
pub fn least_squares(x: &Array2<f64>, y: &[f64]) -> (Vec<f64>, f64, f64) {
    let (n, f) = x.dim();
    let p = f + 1;
    let a = |i: usize, j: usize| if j < f { x[[i, j]] } else { 1.0 };
    let mut m = vec![vec![0.0; p + 1]; p];
    for (r, row) in m.iter_mut().enumerate() {
        for (c, cell) in row.iter_mut().enumerate().take(p) {
            *cell = (0..n).map(|i| a(i, r) * a(i, c)).sum();
        }
        row[p] = (0..n).map(|i| a(i, r) * y[i]).sum();
    }
    for col in 0..p {
        let pivot = (col..p)
            .max_by(|&i, &j| m[i][col].abs().total_cmp(&m[j][col].abs()))
            .expect("rows left");
        m.swap(col, pivot);
        let pivot_row = m[col].clone();
        for row in m.iter_mut().skip(col + 1) {
            let k = row[col] / pivot_row[col];
            for (cell, pv) in row.iter_mut().zip(&pivot_row).skip(col) {
                *cell -= k * pv;
            }
        }
    }
    let mut theta = vec![0.0; p];
    for r in (0..p).rev() {
        let s: f64 = (r + 1..p).map(|c| m[r][c] * theta[c]).sum();
        theta[r] = (m[r][p] - s) / m[r][r];
    }
    let b = theta[f];
    let w = theta[..f].to_vec();
    let mse = closed_form(x, y, &w, b).loss;
    (w, b, mse)
}

/// IX's `minimize_linreg_mse` loop, replayed: Adam with the example's constants on `LinearRegressionTool`
pub struct AdamRun {
    pub trace: Vec<(usize, f64)>,
    pub converged_at: Option<usize>,
    pub final_loss: f64,
    pub w: Vec<f64>,
    pub b: f64,
}

pub fn ix_example_adam(x: &Array2<f64>, y: &[f64], steps: usize) -> AdamRun {
    const LR: f64 = 0.05;
    const BETA1: f64 = 0.9;
    const BETA2: f64 = 0.999;
    const EPSILON: f64 = 1e-8;
    const TARGET_LOSS: f64 = 0.01;
    let (n, f) = x.dim();
    let x_dyn = x.clone().into_dyn();
    let y_dyn = Array::from_shape_vec(IxDyn(&[n, 1]), y.to_vec()).expect("y shape");
    let mut w: ArrayD<f64> = Array::zeros(IxDyn(&[f, 1]));
    let mut b: ArrayD<f64> = Array::zeros(IxDyn(&[1, 1]));
    let (mut m_w, mut v_w): (ArrayD<f64>, ArrayD<f64>) =
        (Array::zeros(w.raw_dim()), Array::zeros(w.raw_dim()));
    let (mut m_b, mut v_b): (ArrayD<f64>, ArrayD<f64>) =
        (Array::zeros(b.raw_dim()), Array::zeros(b.raw_dim()));
    let tool = LinearRegressionTool;
    let mut run = AdamRun {
        trace: Vec::new(),
        converged_at: None,
        final_loss: f64::INFINITY,
        w: Vec::new(),
        b: 0.0,
    };
    for step in 1..=steps {
        let mut ctx = DiffContext::new(ExecutionMode::Train);
        let mut inputs = ValueMap::new();
        inputs.insert("x".into(), Tensor::from_array(x_dyn.clone()));
        inputs.insert("w".into(), Tensor::from_array_with_grad(w.clone()));
        inputs.insert("b".into(), Tensor::from_array_with_grad(b.clone()));
        inputs.insert("y".into(), Tensor::from_array(y_dyn.clone()));
        let out = tool.forward(&mut ctx, &inputs).expect("forward");
        let loss = out["loss"]
            .as_f64()
            .iter()
            .copied()
            .next()
            .expect("scalar loss");
        run.final_loss = loss;
        let grads = tool.backward(&mut ctx, &ValueMap::new()).expect("backward");
        let step_f = step as f64;
        let (c1, c2) = (1.0 - BETA1.powf(step_f), 1.0 - BETA2.powf(step_f));
        for (param, m, v, g) in [
            (&mut w, &mut m_w, &mut v_w, grads["w"].as_f64()),
            (&mut b, &mut m_b, &mut v_b, grads["b"].as_f64()),
        ] {
            m.zip_mut_with(g, |m, &g| *m = BETA1 * *m + (1.0 - BETA1) * g);
            v.zip_mut_with(g, |v, &g| *v = BETA2 * *v + (1.0 - BETA2) * g * g);
            for (p, (&m, &v)) in param.iter_mut().zip(m.iter().zip(v.iter())) {
                *p -= LR * (m / c1) / ((v / c2).sqrt() + EPSILON);
            }
        }
        if step == 1 || step % 10 == 0 {
            run.trace.push((step, loss));
        }
        if run.converged_at.is_none() && loss < TARGET_LOSS {
            run.converged_at = Some(step);
        }
    }
    run.w = w.iter().copied().collect();
    run.b = b[[0, 0]];
    run
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn forward_and_reverse_match_baydin_et_al() {
        // Table 2 and 3 of Baydin et al. (2018): f(2, 5) = 11.652, ∂f/∂x1 = 5.5, ∂f/∂x2 = 1.716
        let (f, g) = baydin_forward(2.0, 5.0);
        let (f_rev, g_rev, tape) = baydin_reverse(2.0, 5.0);
        assert!((f - 11.652).abs() < 5e-4 && (f - f_rev).abs() < 1e-15);
        assert!((g[0] - 5.5).abs() < 1e-15 && (g[1] - (2.0 - 5f64.cos())).abs() < 1e-15);
        assert_eq!(g, g_rev);
        assert_eq!(tape.ops.len(), 7);
    }

    #[test]
    fn p1_the_tape_has_ten_nodes_and_variance_adds_six() {
        let (x, y) = ix_example_data();
        let run = ix_linreg(&x, &y, &[0.0; 3], 0.0);
        assert_eq!(
            tape_ops(&run.ctx),
            [
                "input",
                "input",
                "input",
                "input",
                "matmul",
                "add",
                "sub",
                "mul",
                "sum",
                "div_scalar"
            ]
        );
        assert_eq!(
            variance_ops(),
            ["sum", "div_scalar", "sub", "mul", "sum", "div_scalar"]
        );
    }

    #[test]
    fn p2_gradients_equal_the_closed_forms() {
        let (x, y) = ix_example_data();
        let mut rng = Rng(12);
        let random_w: Vec<f64> = (0..3).map(|_| rng.next_f64() * 2.0 - 1.0).collect();
        let random_b = rng.next_f64() * 2.0 - 1.0;
        for (w, b) in [(vec![0.0; 3], 0.0), (random_w, random_b)] {
            let run = ix_linreg(&x, &y, &w, b);
            let cf = closed_form(&x, &y, &w, b);
            let s = run.state;
            assert!(max_abs_diff(&run.grad(s.w).unwrap(), &cf.w) <= 1e-12);
            assert!((run.grad(s.b).unwrap()[0] - cf.b).abs() <= 1e-12);
            let cfx: Vec<f64> = cf.x.iter().copied().collect();
            assert!(max_abs_diff(&run.grad(s.x).unwrap(), &cfx) <= 1e-12);
            let (loss, hw, hb, _) = hand_tape_linreg(&x, &y, &w, b);
            assert!((loss - run.loss()).abs() <= 1e-12);
            assert!(max_abs_diff(&hw, &cf.w) <= 1e-12 && (hb - cf.b).abs() <= 1e-12);
        }
    }

    #[test]
    fn p3_requires_grad_false_does_not_stop_the_gradient() {
        let (x, y) = ix_example_data();
        let run = ix_linreg(&x, &y, &[0.3, 0.1, -0.2], 0.05);
        let y_node = run.ctx.tape.get(run.state.y).unwrap();
        assert!(!y_node.value.requires_grad);
        let gy = run.grad(run.state.y).expect("a gradient for y");
        let cf = closed_form(&x, &y, &[0.3, 0.1, -0.2], 0.05);
        assert!(max_abs_diff(&gy, &cf.y) <= 1e-12);
    }

    #[test]
    fn p4_mismatched_shapes_panic() {
        for (name, outcome) in mismatched_shapes() {
            assert!(matches!(outcome, Outcome::Panic(_)), "{name}: {outcome:?}");
        }
    }

    #[test]
    fn p5_central_differences_on_a_quadratic_are_exact_up_to_rounding() {
        let (x, y) = ix_example_data();
        let errors = quadratic_fd_errors(&x, &y, &[1e-1, 1e-10]);
        assert!(errors[0].1 <= 1e-12, "{errors:?}");
        assert!(errors[1].1 >= 1e-9, "{errors:?}");
    }

    #[test]
    fn p6_central_differences_on_the_fft_loss_have_a_best_eps() {
        let (x, c) = signal_and_weights(2026, 64);
        let errors = fft_fd_errors(&x, &c, &decades(10));
        let (eps, min) = best_eps(&errors);
        assert!((1e-6..=1e-3).contains(&eps), "{errors:?}");
        assert!(
            errors[0].1 >= 100.0 * min && errors[9].1 >= 100.0 * min,
            "{errors:?}"
        );
    }

    #[test]
    fn p7_the_fft_backward_matches_central_differences() {
        assert!(fft_fd_check(20, 64, 1e-5) <= 1e-6);
    }

    #[test]
    fn p8_the_example_noise_is_a_constant() {
        let (x, y) = ix_example_data();
        let (_, b, mse) = least_squares(&x, &y);
        assert!((0.0899..=0.0901).contains(&b), "{b}");
        assert!(mse < 1e-11, "{mse}");
    }
}
