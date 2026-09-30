//! Lesson 13: attention, layer normalization and a transformer block. Attention and layer normalization by
//! hand, then IX's `ix-nn`, checked against the formulas, central differences and the predictions
//! preregistered in the journal.

use crate::autodiff::{Outcome, Rng};
use ix_nn::attention::{
    attention_backward, causal_mask, multi_head_attention, multi_head_attention_backward,
    multi_head_attention_forward_cache, scaled_dot_product_attention,
};
use ix_nn::positional::sinusoidal_encoding;
use ix_nn::transformer::{FeedForward, TransformerBlock, swiglu};
use ndarray::{Array, Array1, Array2, Array3, Axis, Dimension, s};
use std::any::Any;
use std::panic::{AssertUnwindSafe, catch_unwind};

/// Uniform in [−1, 1)
pub fn random3(rng: &mut Rng, shape: (usize, usize, usize)) -> Array3<f64> {
    Array3::from_shape_simple_fn(shape, || rng.next_f64() * 2.0 - 1.0)
}

/// Uniform in [−1, 1)
pub fn random2(rng: &mut Rng, shape: (usize, usize)) -> Array2<f64> {
    Array2::from_shape_simple_fn(shape, || rng.next_f64() * 2.0 - 1.0)
}

/// Largest absolute difference between two sequences of numbers
pub fn max_diff<'a>(
    a: impl IntoIterator<Item = &'a f64>,
    b: impl IntoIterator<Item = &'a f64>,
) -> f64 {
    a.into_iter()
        .zip(b)
        .map(|(x, y)| (x - y).abs())
        .fold(0.0, f64::max)
}

/// softmax(QKᵀ/√d_k)V with plain loops, as Vaswani et al. write it. Returns the output and the weights.
pub fn attention_by_hand(
    q: &Array3<f64>,
    k: &Array3<f64>,
    v: &Array3<f64>,
) -> (Array3<f64>, Array3<f64>) {
    let (batch, n, d) = q.dim();
    let m = k.shape()[1];
    let dv = v.shape()[2];
    let mut out = Array3::zeros((batch, n, dv));
    let mut weights = Array3::zeros((batch, n, m));
    for b in 0..batch {
        for i in 0..n {
            let scores: Vec<f64> = (0..m)
                .map(|j| {
                    (0..d).map(|t| q[[b, i, t]] * k[[b, j, t]]).sum::<f64>() / (d as f64).sqrt()
                })
                .collect();
            let max = scores.iter().copied().fold(f64::NEG_INFINITY, f64::max);
            let exps: Vec<f64> = scores.iter().map(|s| (s - max).exp()).collect();
            let total: f64 = exps.iter().sum();
            for (j, e) in exps.iter().enumerate() {
                let w = e / total;
                weights[[b, i, j]] = w;
                for t in 0..dv {
                    out[[b, i, t]] += w * v[[b, j, t]];
                }
            }
        }
    }
    (out, weights)
}

/// Largest |sum of a row of attention weights − 1|
pub fn row_sum_error(weights: &Array3<f64>) -> f64 {
    weights
        .sum_axis(Axis(2))
        .iter()
        .map(|s| (s - 1.0).abs())
        .fold(0.0, f64::max)
}

/// (x − mean) / √(var + ε) for each row, with the population variance, as Ba et al. define it
pub fn layer_norm_by_hand(x: &Array2<f64>, eps: f64) -> Array2<f64> {
    let mut out = x.clone();
    for mut row in out.rows_mut() {
        let n = row.len() as f64;
        let mean = row.sum() / n;
        let var = row.iter().map(|v| (v - mean).powi(2)).sum::<f64>() / n;
        row.mapv_inplace(|v| (v - mean) / (var + eps).sqrt());
    }
    out
}

/// For random q and k whose components have variance 1: the variance of q·k over `trials` pairs, and the
/// largest of `m` softmax weights, averaged over the trials, without and with the 1/√d scaling
pub fn scaling_effect(d: usize, m: usize, trials: usize, seed: u64) -> (f64, f64, f64) {
    let mut rng = Rng(seed);
    let a = 3f64.sqrt();
    let mut dots = Vec::new();
    let (mut unscaled, mut scaled) = (0.0, 0.0);
    for _ in 0..trials {
        let q: Vec<f64> = (0..d).map(|_| (rng.next_f64() * 2.0 - 1.0) * a).collect();
        let scores: Vec<f64> = (0..m)
            .map(|_| {
                (0..d)
                    .map(|t| q[t] * (rng.next_f64() * 2.0 - 1.0) * a)
                    .sum::<f64>()
            })
            .collect();
        dots.extend(&scores);
        let largest = |scale: f64| {
            let max = scores.iter().copied().fold(f64::NEG_INFINITY, f64::max);
            let total: f64 = scores.iter().map(|s| ((s - max) * scale).exp()).sum();
            1.0 / total
        };
        unscaled += largest(1.0);
        scaled += largest(1.0 / (d as f64).sqrt());
    }
    let n = dots.len() as f64;
    let mean = dots.iter().sum::<f64>() / n;
    let var = dots.iter().map(|x| (x - mean).powi(2)).sum::<f64>() / n;
    (var, unscaled / trials as f64, scaled / trials as f64)
}

/// A block's output rows before `from`, and from `from` on: their largest change when tokens `from..` of
/// the input are redrawn, under the causal mask
pub fn causal_change(
    block: &TransformerBlock,
    x: &Array3<f64>,
    from: usize,
    rng: &mut Rng,
) -> (f64, f64) {
    let mask = causal_mask(x.shape()[1]);
    let before = block.forward(x, Some(&mask));
    let mut changed = x.clone();
    changed
        .slice_mut(s![.., from.., ..])
        .mapv_inplace(|_| rng.next_f64() * 2.0 - 1.0);
    let after = block.forward(&changed, Some(&mask));
    (
        max_diff(
            before.slice(s![.., ..from, ..]),
            after.slice(s![.., ..from, ..]),
        ),
        max_diff(
            before.slice(s![.., from.., ..]),
            after.slice(s![.., from.., ..]),
        ),
    )
}

/// Central differences of `f` with respect to every element of `x`, each moved by ±ε in place and put back
pub fn central_gradient<D: Dimension>(
    x: &mut Array<f64, D>,
    eps: f64,
    mut f: impl FnMut(&Array<f64, D>) -> f64,
) -> Array<f64, D> {
    let mut g = Array::zeros(x.raw_dim());
    for i in 0..x.len() {
        let orig = x.as_slice().expect("standard layout")[i];
        x.as_slice_mut().expect("standard layout")[i] = orig + eps;
        let plus = f(x);
        x.as_slice_mut().expect("standard layout")[i] = orig - eps;
        let minus = f(x);
        x.as_slice_mut().expect("standard layout")[i] = orig;
        g.as_slice_mut().expect("standard layout")[i] = (plus - minus) / (2.0 * eps);
    }
    g
}

/// L = Σ c ⊙ attention(q, k, v)
fn attention_loss(q: &Array3<f64>, k: &Array3<f64>, v: &Array3<f64>, c: &Array3<f64>) -> f64 {
    let (out, _) = scaled_dot_product_attention(q, k, v, None);
    (&out * c).sum()
}

/// Worst |IX's `attention_backward` − central difference| over every component of dL/dQ, dL/dK and dL/dV,
/// for Q, K, V of shape (2, 4, 3) and L = Σ c ⊙ output
pub fn attention_backward_error(seed: u64, eps: f64) -> f64 {
    let mut rng = Rng(seed);
    let q = random3(&mut rng, (2, 4, 3));
    let k = random3(&mut rng, (2, 4, 3));
    let v = random3(&mut rng, (2, 4, 3));
    let c = random3(&mut rng, (2, 4, 3));
    let (_, w) = scaled_dot_product_attention(&q, &k, &v, None);
    let (gq, gk, gv) = attention_backward(&c, &q, &k, &v, &w);
    let fq = central_gradient(&mut q.clone(), eps, |q| attention_loss(q, &k, &v, &c));
    let fk = central_gradient(&mut k.clone(), eps, |k| attention_loss(&q, k, &v, &c));
    let fv = central_gradient(&mut v.clone(), eps, |v| attention_loss(&q, &k, v, &c));
    max_diff(&gq, &fq)
        .max(max_diff(&gk, &fk))
        .max(max_diff(&gv, &fv))
}

/// What `backward` did to one parameter at learning rate 1, next to the central-difference gradient
pub struct Step {
    pub name: &'static str,
    /// Old value minus new value
    pub change: Vec<f64>,
    pub gradient: Vec<f64>,
}

impl Step {
    /// The r of change ≈ r · gradient, by least squares
    pub fn ratio(&self) -> f64 {
        let num: f64 = self
            .change
            .iter()
            .zip(&self.gradient)
            .map(|(c, g)| c * g)
            .sum();
        let den: f64 = self.gradient.iter().map(|g| g * g).sum();
        num / den
    }

    /// max |change − r · gradient|, relative to the largest gradient component
    pub fn deviation(&self, r: f64) -> f64 {
        let largest = self.gradient.iter().fold(0.0, |m: f64, g| m.max(g.abs()));
        self.change
            .iter()
            .zip(&self.gradient)
            .map(|(c, g)| (c - r * g).abs())
            .fold(0.0, f64::max)
            / largest
    }
}

/// max |a − b| relative to the largest |b|
pub fn relative_error<'a>(
    a: impl IntoIterator<Item = &'a f64>,
    b: impl IntoIterator<Item = &'a f64> + Clone,
) -> f64 {
    let largest = b.clone().into_iter().fold(0.0, |m: f64, v| m.max(v.abs()));
    max_diff(a, b) / largest
}

/// L = Σ c ⊙ multi-head self-attention of x
fn mha_loss(x: &Array3<f64>, w: &[Array2<f64>; 4], n_heads: usize, c: &Array3<f64>) -> f64 {
    let (out, _) = multi_head_attention(x, x, x, &w[0], &w[1], &w[2], &w[3], n_heads, None);
    (&out * c).sum()
}

/// `multi_head_attention_backward` at learning rate 1 on self-attention of x (batch × seq × d_model): the
/// change it applies to w_q, w_k, w_v and w_o next to their central-difference gradients, and the relative
/// error of the input gradient it returns
pub fn attention_steps(
    seed: u64,
    (batch, seq, d_model): (usize, usize, usize),
    n_heads: usize,
    eps: f64,
) -> (Vec<Step>, f64) {
    let mut rng = Rng(seed);
    let x = random3(&mut rng, (batch, seq, d_model));
    let c = random3(&mut rng, (batch, seq, d_model));
    let w: [Array2<f64>; 4] = std::array::from_fn(|_| random2(&mut rng, (d_model, d_model)) * 0.5);

    let (_, weights, hq, hk, hv, concat) =
        multi_head_attention_forward_cache(&x, &x, &x, &w[0], &w[1], &w[2], &w[3], n_heads, None);
    let [mut wq, mut wk, mut wv, mut wo] = w.clone();
    let grad_x = multi_head_attention_backward(
        &c, &x, &x, &x, &mut wq, &mut wk, &mut wv, &mut wo, &weights, &hq, &hk, &hv, &concat,
        n_heads, 1.0,
    );

    let names = ["w_q", "w_k", "w_v", "w_o"];
    let updated = [wq, wk, wv, wo];
    let steps = (0..4)
        .map(|i| {
            let mut probe = w.clone();
            let mut wi = probe[i].clone();
            let gradient = central_gradient(&mut wi, eps, |wi| {
                probe[i] = wi.clone();
                mha_loss(&x, &probe, n_heads, &c)
            });
            Step {
                name: names[i],
                change: (&w[i] - &updated[i]).iter().copied().collect(),
                gradient: gradient.iter().copied().collect(),
            }
        })
        .collect();
    let fx = central_gradient(&mut x.clone(), eps, |x| mha_loss(x, &w, n_heads, &c));
    (steps, relative_error(&grad_x, &fx))
}

/// The parameters of a `TransformerBlock`, in the order its backward reaches them
#[derive(Clone, Copy, Debug, PartialEq)]
pub enum Param {
    FfnW2,
    FfnB2,
    FfnW1,
    FfnB1,
    Norm2Gamma,
    Norm2Beta,
    Wo,
    Wq,
    Wk,
    Wv,
    Norm1Gamma,
    Norm1Beta,
}

impl Param {
    pub const ALL: [Param; 12] = [
        Param::FfnW2,
        Param::FfnB2,
        Param::FfnW1,
        Param::FfnB1,
        Param::Norm2Gamma,
        Param::Norm2Beta,
        Param::Wo,
        Param::Wq,
        Param::Wk,
        Param::Wv,
        Param::Norm1Gamma,
        Param::Norm1Beta,
    ];

    pub fn name(self) -> &'static str {
        match self {
            Param::FfnW2 => "ffn.w2",
            Param::FfnB2 => "ffn.b2",
            Param::FfnW1 => "ffn.w1",
            Param::FfnB1 => "ffn.b1",
            Param::Norm2Gamma => "norm2.gamma",
            Param::Norm2Beta => "norm2.beta",
            Param::Wo => "w_o",
            Param::Wq => "w_q",
            Param::Wk => "w_k",
            Param::Wv => "w_v",
            Param::Norm1Gamma => "norm1.gamma",
            Param::Norm1Beta => "norm1.beta",
        }
    }

    /// LayerNorm parameters, which the block updates by the full gradient
    pub fn is_norm(self) -> bool {
        matches!(
            self,
            Param::Norm1Gamma | Param::Norm1Beta | Param::Norm2Gamma | Param::Norm2Beta
        )
    }

    /// The parameter's values, in place
    pub fn values(self, block: &mut TransformerBlock) -> &mut [f64] {
        match self {
            Param::FfnW2 => block.ffn.w2.as_slice_mut(),
            Param::FfnB2 => block.ffn.b2.as_slice_mut(),
            Param::FfnW1 => block.ffn.w1.as_slice_mut(),
            Param::FfnB1 => block.ffn.b1.as_slice_mut(),
            Param::Norm2Gamma => block.norm2.gamma.as_slice_mut(),
            Param::Norm2Beta => block.norm2.beta.as_slice_mut(),
            Param::Wo => block.w_o.as_slice_mut(),
            Param::Wq => block.w_q.as_slice_mut(),
            Param::Wk => block.w_k.as_slice_mut(),
            Param::Wv => block.w_v.as_slice_mut(),
            Param::Norm1Gamma => block.norm1.gamma.as_slice_mut(),
            Param::Norm1Beta => block.norm1.beta.as_slice_mut(),
        }
        .expect("standard layout")
    }
}

/// L = Σ c ⊙ block(x)
fn block_loss(block: &TransformerBlock, x: &Array3<f64>, c: &Array3<f64>) -> f64 {
    (&block.forward(x, None) * c).sum()
}

/// `TransformerBlock::backward` at learning rate 1 on x (batch × seq × 8), 2 heads, d_ff 16: the change it
/// applies to each parameter next to its central-difference gradient, and the relative error of the input
/// gradient it returns
pub fn block_steps(seed: u64, batch: usize, seq: usize, eps: f64) -> (Vec<Step>, f64) {
    let mut rng = Rng(seed);
    let x = random3(&mut rng, (batch, seq, 8));
    let c = random3(&mut rng, (batch, seq, 8));

    let mut trained = TransformerBlock::new(8, 2, 16, seed);
    let before: Vec<Vec<f64>> = Param::ALL
        .iter()
        .map(|p| p.values(&mut trained).to_vec())
        .collect();
    trained.forward_cache(&x, None);
    let grad_x = trained.backward(&c, 1.0);

    let mut probe = TransformerBlock::new(8, 2, 16, seed);
    let steps = Param::ALL
        .iter()
        .zip(before)
        .map(|(&p, old)| {
            let gradient = (0..old.len())
                .map(|i| {
                    let orig = p.values(&mut probe)[i];
                    p.values(&mut probe)[i] = orig + eps;
                    let plus = block_loss(&probe, &x, &c);
                    p.values(&mut probe)[i] = orig - eps;
                    let minus = block_loss(&probe, &x, &c);
                    p.values(&mut probe)[i] = orig;
                    (plus - minus) / (2.0 * eps)
                })
                .collect();
            let new = p.values(&mut trained);
            Step {
                name: p.name(),
                change: old.iter().zip(new.iter()).map(|(o, n)| o - n).collect(),
                gradient,
            }
        })
        .collect();
    let fx = central_gradient(&mut x.clone(), eps, |x| block_loss(&probe, x, &c));
    (steps, relative_error(&grad_x, &fx))
}

/// Population standard deviation
pub fn spread<'a>(values: impl IntoIterator<Item = &'a f64>) -> f64 {
    let v: Vec<f64> = values.into_iter().copied().collect();
    let n = v.len() as f64;
    let mean = v.iter().sum::<f64>() / n;
    (v.iter().map(|x| (x - mean).powi(2)).sum::<f64>() / n).sqrt()
}

/// The standard deviation of `FeedForward::new`'s w1 and w2 over √(2/(d_model + d_ff)), and of
/// `TransformerBlock::new`'s four projections over √(1/d_model)
pub fn init_spreads(d_model: usize, d_ff: usize, seed: u64) -> (f64, f64) {
    let ffn = FeedForward::new(d_model, d_ff, seed);
    let ffn_ratio = spread(ffn.w1.iter().chain(&ffn.w2)) / (2.0 / (d_model + d_ff) as f64).sqrt();
    let block = TransformerBlock::new(d_model, 4, d_ff, seed);
    let projections = block
        .w_q
        .iter()
        .chain(&block.w_k)
        .chain(&block.w_v)
        .chain(&block.w_o);
    let block_ratio = spread(projections) / (1.0 / d_model as f64).sqrt();
    (ffn_ratio, block_ratio)
}

/// A block with d_model 10 and 3 heads: the largest change in its output when column `col` of w_q, w_k
/// and w_v and row `col` of w_o are redrawn
pub fn uneven_heads_change(col: usize, seed: u64) -> f64 {
    let mut rng = Rng(seed);
    let mut block = TransformerBlock::new(10, 3, 16, seed);
    let x = random3(&mut rng, (1, 4, 10));
    let before = block.forward(&x, None);
    for w in [&mut block.w_q, &mut block.w_k, &mut block.w_v] {
        w.column_mut(col)
            .mapv_inplace(|_| rng.next_f64() * 2.0 - 1.0);
    }
    block
        .w_o
        .row_mut(col)
        .mapv_inplace(|_| rng.next_f64() * 2.0 - 1.0);
    max_diff(&before, &block.forward(&x, None))
}

pub(crate) fn panic_message(payload: Box<dyn Any + Send>) -> String {
    payload
        .downcast_ref::<String>()
        .cloned()
        .or_else(|| payload.downcast_ref::<&str>().map(|s| s.to_string()))
        .unwrap_or_default()
}

/// `swiglu` on `len` values, run under `catch_unwind`
pub fn swiglu_outcome(len: usize) -> Outcome {
    let x: Array1<f64> = (0..len).map(|i| i as f64 * 0.5 - 1.0).collect();
    match catch_unwind(AssertUnwindSafe(|| swiglu(&x))) {
        Ok(_) => Outcome::Value,
        Err(payload) => Outcome::Panic(panic_message(payload)),
    }
}

/// The 5 tokens of x in the order 3, 0, 4, 1, 2
pub fn permute(x: &Array3<f64>) -> Array3<f64> {
    x.select(Axis(1), &[3, 0, 4, 1, 2])
}

/// Largest |block(permuted x) − permuted block(x)| for 5 tokens, without a positional encoding and with a
/// sinusoidal one added to the input: the encoding belongs to the slot, so it is added after permuting
pub fn permutation_change(seed: u64) -> (f64, f64) {
    let mut rng = Rng(seed);
    let block = TransformerBlock::new(8, 2, 16, seed);
    let x = random3(&mut rng, (1, 5, 8));
    let plain = max_diff(
        &block.forward(&permute(&x), None),
        &permute(&block.forward(&x, None)),
    );
    let pe = sinusoidal_encoding(5, 8);
    let encode = |a: &Array3<f64>| {
        let mut b = a.clone();
        for mut tokens in b.outer_iter_mut() {
            tokens += &pe;
        }
        b
    };
    let positional = max_diff(
        &block.forward(&encode(&permute(&x)), None),
        &permute(&block.forward(&encode(&x), None)),
    );
    (plain, positional)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn p1_attention_is_the_formula() {
        let mut rng = Rng(13);
        let q = random3(&mut rng, (2, 4, 3));
        let k = random3(&mut rng, (2, 4, 3));
        let v = random3(&mut rng, (2, 4, 3));
        let (out, w) = scaled_dot_product_attention(&q, &k, &v, None);
        let (hand_out, hand_w) = attention_by_hand(&q, &k, &v);
        assert!(max_diff(&out, &hand_out) < 1e-12);
        assert!(max_diff(&w, &hand_w) < 1e-12);
        assert!(row_sum_error(&w) < 1e-12);
    }

    #[test]
    fn p2_the_causal_mask_is_exact() {
        let mut rng = Rng(13);
        let block = TransformerBlock::new(8, 2, 16, 13);
        let x = random3(&mut rng, (2, 5, 8));
        let (past, future) = causal_change(&block, &x, 3, &mut rng);
        assert_eq!(past, 0.0);
        assert!(future > 0.0, "the check can fail: {future}");
    }

    #[test]
    fn p3_attention_backward_matches_central_differences() {
        assert!(attention_backward_error(13, 1e-5) <= 1e-7);
    }

    #[test]
    fn p4_projections_step_by_a_tenth_of_the_gradient() {
        let (steps, input) = attention_steps(13, (2, 5, 8), 2, 1e-5);
        for step in &steps {
            assert!(step.deviation(0.1) <= 1e-6, "{}", step.name);
        }
        assert!(input <= 1e-6, "{input}");
    }

    #[test]
    fn p5_one_block_two_step_sizes() {
        let (steps, input) = block_steps(13, 2, 5, 1e-5);
        for (step, p) in steps.iter().zip(Param::ALL) {
            let expected = if p.is_norm() { 1.0 } else { 0.1 };
            assert!(step.deviation(expected) <= 1e-6, "{}", step.name);
        }
        assert!(input <= 1e-6, "{input}");
    }

    #[test]
    fn p6_the_xavier_spread_is_one_over_root_three() {
        let (ffn, block) = init_spreads(64, 256, 13);
        assert!((0.56..=0.60).contains(&ffn), "{ffn}");
        assert!((0.56..=0.60).contains(&block), "{block}");
    }

    #[test]
    fn p7_column_9_is_never_read() {
        assert_eq!(uneven_heads_change(9, 13), 0.0);
        assert!(uneven_heads_change(8, 13) > 0.0, "the check can fail");
    }

    #[test]
    fn p8_swiglu_panics_on_an_odd_length() {
        assert!(matches!(swiglu_outcome(5), Outcome::Panic(_)));
        assert_eq!(swiglu_outcome(4), Outcome::Value);
    }

    #[test]
    fn p9_no_positions_no_order() {
        let (plain, positional) = permutation_change(13);
        assert!(plain < 1e-12, "{plain}");
        assert!(positional > 1e-3, "the check can fail: {positional}");
    }
}
