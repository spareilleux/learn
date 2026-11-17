//! Lesson 13: attention, layer normalization and a transformer block. The formulas by hand, then IX's
//! `ix-nn`, measured against them, against central differences and against the predictions preregistered
//! in the journal.

use ix_nn::attention::scaled_dot_product_attention;
use ix_nn::norm::LayerNorm;
use ix_nn::transformer::TransformerBlock;
use machine_learning_ix::autodiff::Rng;
use machine_learning_ix::fmt_vec;
use machine_learning_ix::transformer::*;
use ndarray::s;

/// A difference that should be rounding at most prints as a bound, so the output is the same on every OS;
/// one that should be exactly zero prints as such
fn fmt_small(e: f64) -> String {
    if e == 0.0 {
        "0, exactly".to_string()
    } else if e < 1e-12 {
        "< 1e-12".to_string()
    } else {
        format!("{e:.0e}")
    }
}

fn main() {
    println!("== Attention by hand and in IX");
    let mut rng = Rng(13);
    let q = random3(&mut rng, (2, 4, 3));
    let k = random3(&mut rng, (2, 4, 3));
    let v = random3(&mut rng, (2, 4, 3));
    let (out, w) = scaled_dot_product_attention(&q, &k, &v, None);
    let (hand_out, hand_w) = attention_by_hand(&q, &k, &v);
    println!("  Q, K, V of shape (2, 4, 3), uniform in [-1, 1)");
    println!(
        "  weights of batch 0, query 0: {}",
        fmt_vec(w.slice(s![0, 0, ..]).iter().copied(), 6)
    );
    println!(
        "  output of batch 0, query 0:  {}",
        fmt_vec(out.slice(s![0, 0, ..]).iter().copied(), 6)
    );
    println!(
        "  largest difference from softmax(QK^T/sqrt(d_k))V by hand: output {}, weights {}",
        fmt_small(max_diff(&out, &hand_out)),
        fmt_small(max_diff(&w, &hand_w))
    );
    println!(
        "  largest |row sum of the weights - 1|: {}",
        fmt_small(row_sum_error(&w))
    );

    println!("\n== Why divide by sqrt(d_k)");
    println!("  components of q and k with variance 1, 16 keys, 2000 queries");
    println!("     d   var(q.k)   largest weight, unscaled   scaled");
    for d in [4, 16, 64, 256] {
        let (var, unscaled, scaled) = scaling_effect(d, 16, 2000, 7);
        println!("  {d:>4}   {var:>8.1}   {unscaled:>24.3}   {scaled:>6.3}");
    }

    println!("\n== Layer normalization");
    let x = random2(&mut rng, (2, 6)) * 3.0 + 1.0;
    let ln = LayerNorm::new(6);
    let ix = ln.forward(&x);
    let hand = layer_norm_by_hand(&x, 1e-5);
    println!(
        "  token 0:             {}",
        fmt_vec(x.row(0).iter().copied(), 6)
    );
    println!(
        "  normalized by IX:    {}",
        fmt_vec(ix.row(0).iter().copied(), 6)
    );
    println!(
        "  largest difference from (x - mean)/sqrt(var + 1e-5) by hand: {}",
        fmt_small(max_diff(&ix, &hand))
    );
    let mean: Vec<f64> = ix.rows().into_iter().map(|r| r.sum() / 6.0).collect();
    let var: Vec<f64> = ix
        .rows()
        .into_iter()
        .map(|r| r.iter().map(|v| v * v).sum::<f64>() / 6.0)
        .collect();
    println!(
        "  mean of each token after: {}, variance: {}",
        fmt_vec(mean, 6),
        fmt_vec(var, 6)
    );

    println!("\n== The causal mask");
    let block = TransformerBlock::new(8, 2, 16, 13);
    let mut rng = Rng(13);
    let x = random3(&mut rng, (2, 5, 8));
    let (past, future) = causal_change(&block, &x, 3, &mut rng);
    println!(
        "  block with d_model 8, 2 heads, d_ff 16; 2 sequences of 5 tokens; tokens 3 and 4 redrawn"
    );
    println!(
        "  largest change in output rows 0 to 2: {}",
        fmt_small(past)
    );
    println!("  largest change in output rows 3 and 4: {future:.3}");

    println!("\n== IX's attention backward against central differences");
    println!(
        "  Q, K, V of shape (2, 4, 3), L = sum c * output, eps 1e-5: worst error over 72 components below 1e-7: {}",
        attention_backward_error(13, 1e-5) <= 1e-7
    );

    println!("\n== What backward applies at learning rate 1, batch 2, seq 5 (batch x seq = 10)");
    println!("  change / central-difference gradient, by least squares");
    let (steps, input) = attention_steps(13, (2, 5, 8), 2, 1e-5);
    println!("  multi_head_attention_backward, d_model 8, 2 heads:");
    for step in &steps {
        println!(
            "    {:<12} {:.4}   within 1e-6 of 0.1: {}",
            step.name,
            step.ratio(),
            step.deviation(0.1) <= 1e-6
        );
    }
    println!(
        "    input gradient within 1e-6 of central differences: {}",
        input <= 1e-6
    );
    let (steps, input) = block_steps(13, 2, 5, 1e-5);
    println!(
        "  TransformerBlock::backward, d_model 8, 2 heads, d_ff 16, parameters in the order it updates them:"
    );
    for (step, p) in steps.iter().zip(Param::ALL) {
        let expected = if p.is_norm() { 1.0 } else { 0.1 };
        println!(
            "    {:<12} {:.4}   within 1e-6 of {expected:.1}: {}",
            step.name,
            step.ratio(),
            step.deviation(expected) <= 1e-6
        );
    }
    println!(
        "    input gradient within 1e-6 of central differences: {}",
        input <= 1e-6
    );

    println!("\n== Initial spread");
    let (ffn, projections) = init_spreads(64, 256, 13);
    println!("  FeedForward::new(64, 256): std of w1 and w2 / sqrt(2/(64 + 256)) = {ffn:.4}");
    println!(
        "  TransformerBlock::new(64, 4, 256): std of w_q, w_k, w_v, w_o / sqrt(1/64) = {projections:.4}"
    );
    println!(
        "  U(-a, a) has std a/sqrt(3) = {:.4} a; Glorot and Bengio's U(-sqrt(3) s, sqrt(3) s) has std s",
        1.0 / 3f64.sqrt()
    );

    println!("\n== Ten dimensions over three heads");
    println!(
        "  change when column 9 of w_q, w_k, w_v and row 9 of w_o are redrawn: {}",
        fmt_small(uneven_heads_change(9, 13))
    );
    println!("  the same for column 8: {:.3}", uneven_heads_change(8, 13));

    println!("\n== SwiGLU");
    let hook = std::panic::take_hook();
    std::panic::set_hook(Box::new(|_| {}));
    let outcomes = [(4, swiglu_outcome(4)), (5, swiglu_outcome(5))];
    std::panic::set_hook(hook);
    for (len, outcome) in outcomes {
        println!("  {len} values: {outcome:?}");
    }

    println!("\n== Order");
    let (plain, positional) = permutation_change(13);
    println!(
        "  tokens reordered 3, 0, 4, 1, 2, no positional encoding: largest difference {}",
        fmt_small(plain)
    );
    println!("  the same with a sinusoidal encoding added to the input: {positional:.3}");
}
