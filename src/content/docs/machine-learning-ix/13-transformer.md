---
title: "13. Attention, layer normalization and a transformer block"
description: "Attention and layer normalization written by hand, then IX's ix-nn transformer block checked against the formulas, central differences and numpy, with nine predictions written before the first run: all nine held. The forward pass is exact; the backward updates the block's LayerNorms by the full gradient and its other weights by a tenth of it."
sidebar:
  order: 13
---

Lesson 7 found IX's `Dense::backward` dividing by the batch size a second time (finding 15), and lesson 12 showed how a tape computes gradients without anyone deriving them. A transformer is where both questions meet: it has more layers than lesson 7's network, each with a backward written by hand. IX's pinned [`ix-nn`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn) crate has the pieces: scaled dot-product and multi-head attention, layer normalization, a feed-forward network, and a block that stacks them with residual connections. This lesson writes attention and layer normalization by hand, runs IX's versions against them, and then checks what IX's backward does to each weight.

The nine predictions this lesson tests were [written in the journal](../journal/#2026-09-30--lesson-13-predicted-before-measuring) and committed before any of its code existed. [The results](../journal/#2026-09-30--lesson-13-measured) follow them. The experiments are in [`transformer.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/src/transformer.rs), one test per prediction. [`l13_transformer.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/examples/l13_transformer.rs) prints what they measure. [`crosscheck.py`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/crosscheck/crosscheck.py) recomputes the attention, the normalization and the scaling table with [numpy](https://numpy.org/doc/stable/).

## 1. Attention, by hand

Each token of a sequence asks a question, a query q, and every token offers a key k and a value v. The query's similarity to each key, scaled and passed through a softmax, becomes a weight, and the token's output is the weighted average of the values ([Vaswani et al.](https://arxiv.org/abs/1706.03762), section 3.2.1):

Attention(Q, K, V) = softmax(QKᵀ / √d_k) V

where each row of Q, K and V is one token and d_k is the length of a query. `attention_by_hand` in `transformer.rs` computes it with plain loops. IX's [`scaled_dot_product_attention`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/attention.rs#L45-L92) computes it with matrix products, one batch element at a time (P1):

```text
== Attention by hand and in IX
  Q, K, V of shape (2, 4, 3), uniform in [-1, 1)
  weights of batch 0, query 0: [0.255277, 0.255466, 0.217414, 0.271842]
  output of batch 0, query 0:  [-0.338191, -0.187914, 0.504304]
  largest difference from softmax(QK^T/sqrt(d_k))V by hand: output < 1e-12, weights < 1e-12
  largest |row sum of the weights - 1|: < 1e-12
```

The four weights are close to a quarter each, because random queries and keys of length 3 are barely more similar to one key than to another. numpy, from the same random numbers, prints the same weights and output.

## 2. Why divide by √d_k

If the components of q and k are independent, with mean 0 and variance 1, then q·k is a sum of d_k products each of variance 1, so its variance is d_k. Without the scaling, the scores spread out as the vectors get longer, and the softmax gives almost all the weight to the largest one:

```text
== Why divide by sqrt(d_k)
  components of q and k with variance 1, 16 keys, 2000 queries
     d   var(q.k)   largest weight, unscaled   scaled
     4        4.0                      0.413    0.226
    16       15.7                      0.679    0.238
    64       63.8                      0.847    0.247
   256      259.7                      0.925    0.247
```

At d_k = 256, the unscaled softmax puts 0.925 of the weight on one key out of 16, where the gradient of a softmax is nearly zero. Divided by √d_k, the scores keep variance 1 at every length, and the largest weight stays near a quarter. Vaswani et al. give this argument in footnote 4.

## 3. Layer normalization

A layer normalization ([Ba et al.](https://arxiv.org/abs/1607.06450)) rescales each token on its own: subtract the mean of its components, divide by their standard deviation, then multiply by a learned γ and add a learned β, one of each per component. It uses the population variance, and an ε inside the square root keeps a constant token from dividing by zero. A batch normalization does the same per component, across the tokens of a batch, which is why it depends on the batch and a layer normalization does not.

```text
== Layer normalization
  token 0:             [2.951819, 3.736748, -0.556086, 2.897718, 3.615376, 3.820285]
  normalized by IX:    [0.136528, 0.652960, -2.171448, 0.100933, 0.573105, 0.707922]
  largest difference from (x - mean)/sqrt(var + 1e-5) by hand: < 1e-12
  mean of each token after: [0.000000, 0.000000], variance: [0.999996, 0.999997]
```

The variance after is not 1 but var/(var + ε), with IX's ε = 10⁻⁵ ([`norm.rs` 36-46](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/norm.rs#L36-L46)). γ starts at 1 and β at 0, so a new layer normalization only normalizes.

## 4. The block, the mask and the order

IX's [`TransformerBlock`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/transformer.rs#L190-L287) is a pre-norm block. Each sublayer reads a normalized copy of its input and adds its result back to the unnormalized input:

h = x + Attention(LN₁(x)),   output = h + FFN(LN₂(h))

The attention is multi-head: the queries, keys and values are projected by w_q, w_k and w_v, cut into heads of d_model / n_heads columns each, attended separately, put side by side again and projected by w_o. The feed-forward network, FFN, is two linear layers with a [GELU](https://arxiv.org/abs/1606.08415) between them, applied to each token alone. The original transformer normalized after each residual addition. Normalizing before, as here, keeps a path from the output to the input that no normalization rescales, which [Xiong et al.](https://arxiv.org/abs/2002.04745) show makes training stable without a learning-rate warm-up.

**The causal mask.** A model that predicts the next token must not see the tokens after it. [`causal_mask`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/attention.rs#L37-L43) adds −10⁹ to every score above the diagonal. After the softmax subtracts the row's maximum, the exponential of about −10⁹ is below the smallest positive double, so those weights are exactly 0, and a weight of exactly 0 adds exactly 0 to the output. Attention is the only place a block mixes tokens, so the rows before a change cannot move at all (P2):

```text
== The causal mask
  block with d_model 8, 2 heads, d_ff 16; 2 sequences of 5 tokens; tokens 3 and 4 redrawn
  largest change in output rows 0 to 2: 0, exactly
  largest change in output rows 3 and 4: 1.777
```

**The order.** Without a mask, nothing in the block depends on where a token sits: the projections, the normalizations and the FFN treat each token alike, and attention takes a weighted sum over all of them. Reordering the input reorders the output the same way (P9). A positional encoding breaks that. The [sinusoidal one](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/positional.rs#L20-L34) of Vaswani et al. adds a fixed vector to each position, before the block:

```text
== Order
  tokens reordered 3, 0, 4, 1, 2, no positional encoding: largest difference < 1e-12
  the same with a sinusoidal encoding added to the input: 1.894
```

## 5. The backward, and the step it takes

IX's layers have no tape: each writes its backward by hand. [`attention_backward`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/attention.rs#L94-L161) returns the gradients for Q, K and V, and they agree with lesson 12's central differences (P3):

```text
== IX's attention backward against central differences
  Q, K, V of shape (2, 4, 3), L = sum c * output, eps 1e-5: worst error over 72 components below 1e-7: true
```

The layers above it do more than return gradients: `multi_head_attention_backward`, `FeedForward::backward`, `LayerNorm::backward` and `TransformerBlock::backward` each take a learning rate and update their own weights. The course measures what they apply. It calls each backward at learning rate 1, so the change in a weight is the step itself, and fits it against the central-difference gradient of the same loss, change = r × gradient (P4 and P5):

```text
== What backward applies at learning rate 1, batch 2, seq 5 (batch x seq = 10)
  change / central-difference gradient, by least squares
  multi_head_attention_backward, d_model 8, 2 heads:
    w_q          0.1000   within 1e-6 of 0.1: true
    w_k          0.1000   within 1e-6 of 0.1: true
    w_v          0.1000   within 1e-6 of 0.1: true
    w_o          0.1000   within 1e-6 of 0.1: true
    input gradient within 1e-6 of central differences: true
  TransformerBlock::backward, d_model 8, 2 heads, d_ff 16, parameters in the order it updates them:
    ffn.w2       0.1000   within 1e-6 of 0.1: true
    ffn.b2       0.1000   within 1e-6 of 0.1: true
    ffn.w1       0.1000   within 1e-6 of 0.1: true
    ffn.b1       0.1000   within 1e-6 of 0.1: true
    norm2.gamma  1.0000   within 1e-6 of 1.0: true
    norm2.beta   1.0000   within 1e-6 of 1.0: true
    w_o          0.1000   within 1e-6 of 0.1: true
    w_q          0.1000   within 1e-6 of 0.1: true
    w_k          0.1000   within 1e-6 of 0.1: true
    w_v          0.1000   within 1e-6 of 0.1: true
    norm1.gamma  1.0000   within 1e-6 of 1.0: true
    norm1.beta   1.0000   within 1e-6 of 1.0: true
    input gradient within 1e-6 of central differences: true
```

Every gradient IX computes is right: the input gradients match, and every change is exactly proportional to its gradient. The factor is not the same everywhere. The attention projections ([`attention.rs` 212, 254-257](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/attention.rs#L212)) and the feed-forward weights ([`transformer.rs` 153-157](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/transformer.rs#L153-L157)) divide their gradient by batch × seq before stepping. The two layer normalizations do not ([`norm.rs` 104-128](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/norm.rs#L104-L128)). No loss has these steps as its gradient step, whatever the gradient passed in:

- **The loss is a sum over tokens.** The normalizations take the right step, and every other weight a step batch × seq times too small.
- **The loss is a mean.** IX's own `TransformerClassifier` and `TransformerRegressor` pass in this gradient: they divide by the batch size and then by the sequence length ([`classifier.rs` 316, 336](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/classifier.rs#L316-L343), and 541, 559 for the regressor). The normalizations are again right, and the other weights divide by batch × seq a second time. With the default full batch, 100 examples of 4 tokens each would move the attention and feed-forward weights 400 times less than the classifier's head and its normalizations, at the same learning rate. That is lesson 7's finding 15, which it found in `Dense`, repeated in two more layers.

The doc comment of `multi_head_attention_backward` also says it returns the input gradient and the four updated matrices ([`attention.rs` 177-178](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/attention.rs#L177-L178)). It returns only the input gradient, and updates the matrices through the `&mut` references it is given.

## 6. The initialization

[Glorot and Bengio](https://proceedings.mlr.press/v9/glorot10a.html) initialize a layer with fan_in inputs and fan_out outputs from U(−a, a) with a = √(6 / (fan_in + fan_out)), which has variance a²/3 = 2 / (fan_in + fan_out). [`FeedForward::new`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/transformer.rs#L38-L50) says "Xavier init" and computes that standard deviation, √(2 / (fan_in + fan_out)), but then uses it as the bound a. `TransformerBlock::new` does the same with √(1/d_model) for the projections ([`transformer.rs` 235-238](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/transformer.rs#L235-L238)). The spread comes out √3 times smaller than the formula it names (P6):

```text
== Initial spread
  FeedForward::new(64, 256): std of w1 and w2 / sqrt(2/(64 + 256)) = 0.5767
  TransformerBlock::new(64, 4, 256): std of w_q, w_k, w_v, w_o / sqrt(1/64) = 0.5763
  U(-a, a) has std a/sqrt(3) = 0.5774 a; Glorot and Bengio's U(-sqrt(3) s, sqrt(3) s) has std s
```

In a pre-norm block the spread should matter less than in lesson 7's plain stack, since each sublayer reads normalized input and the residual path carries the signal whatever the weights; this lesson did not train a block to measure it. The classifier's own output layer is drawn from a normal distribution with the right standard deviation ([`classifier.rs` 180-189](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/classifier.rs#L180-L189)). numpy's own U(−1, 1), a million draws, gives 0.5776 against 1/√3 = 0.5774.

## 7. Two edges

**Heads that don't divide d_model.** Multi-head attention cuts d_model into n_heads heads of d_model / n_heads columns, with integer division and no check ([`attention.rs` 377](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/attention.rs#L377)). With 10 dimensions and 3 heads, each head gets 3 columns and column 9 goes nowhere (P7):

```text
== Ten dimensions over three heads
  change when column 9 of w_q, w_k, w_v and row 9 of w_o are redrawn: 0, exactly
  the same for column 8: 1.327
```

The block runs and reports no error. By the same reading of `multi_head_attention_backward`, the weights of column 9 get a zero gradient too, since nothing writes that column of the projection gradients; the course did not measure it.

**SwiGLU on an odd length.** [`swiglu`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/transformer.rs#L180-L188) ([Shazeer](https://arxiv.org/abs/2002.05202)) splits its input at len / 2 into a gate and a value and multiplies them. On 5 values the gate has 2 and the value 3 (P8):

```text
== SwiGLU
  4 values: Value
  5 values: Panic("called `Result::unwrap()` on an `Err` value: ShapeError/IncompatibleShape: incompatible shapes")
```

## 8. The predictions, scored

| | Prediction, written before the first run | Measured | Verdict |
|---|---|---|---|
| P1 | `scaled_dot_product_attention` equals the formula by hand within 10⁻¹², and its rows sum to 1 | Below 10⁻¹² for both | Confirmed |
| P2 | With the causal mask, redrawing tokens 3 and 4 changes output rows 0 to 2 by exactly 0 | 0; rows 3 and 4 change by 1.777 | Confirmed |
| P3 | `attention_backward` within 10⁻⁷ of central differences at ε = 10⁻⁵ | Below 10⁻⁷ on all 72 components | Confirmed |
| P4 | `multi_head_attention_backward` steps the projections by a tenth of their gradient at batch 2, seq 5, and returns the input gradient itself | 0.1000 for all four; input gradient within 10⁻⁶ | Confirmed |
| P5 | In `TransformerBlock::backward`, the LayerNorms step by their full gradient and every other weight by a tenth | 1.0000 for the four norm parameters, 0.1000 for the eight others | Confirmed |
| P6 | The "Xavier" spread is 1/√3 of the named one: ratio in [0.56, 0.60] | 0.5767 and 0.5763 | Confirmed |
| P7 | 10 dimensions over 3 heads: redrawing column 9 changes the output by exactly 0 | 0; column 8 changes it by 1.327 | Confirmed |
| P8 | `swiglu` panics on 5 values | It panics | Confirmed |
| P9 | Without positions, reordering the tokens reorders the output within 10⁻¹² | Below 10⁻¹²; 1.894 with a sinusoidal encoding | Confirmed |

All nine held on the first run, and none was adjusted afterwards. P4 to P8 were written from reading IX's code, to catch a gap between what it says and what it does, and each found one. P2, P7 and P9 each have a control that shows the check can fail: the rows after the change do move, column 8 does matter, and a positional encoding does break the symmetry.

## What to use for our repositories

- **IX's attention and layer normalization forward passes:** exact, and the causal mask is exact too. Check that n_heads divides d_model before building a block, since nothing else will.
- **Training with `ix-nn`'s backward methods:** each weight's step is its gradient times the learning rate, divided by batch × seq except in the layer normalizations. Pick the learning rate for the attention and feed-forward weights knowing that, or scale the gradient you pass in. To train a new layer, lesson 12's tape is safer than a backward written by hand.
- **Before trusting a backward written by hand,** measure the step it applies, not only the gradient it returns: IX's gradients are all right, and its steps are not.
- **`swiglu`:** even lengths only.

## Exercises

1. Show that if the components of q and k are independent, with mean 0 and variance 1, then q·k has mean 0 and variance d_k.
2. After normalization, the first token's variance prints 0.999996. Without looking at the token, what was its variance before?
3. `TransformerClassifier` trains on 100 examples of 4 tokens each, in one batch. At learning rate η, by how much does w_q move, compared with a gradient step on the classifier's mean loss? What would you change in IX so that one learning rate means one step size?
4. `rope_rotate` ([`positional.rs` 36-66](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/positional.rs#L36-L66), [Su et al.](https://arxiv.org/abs/2104.09864)) rotates each pair of components (2i, 2i + 1) of the token at position m by the angle m·θᵢ. Show that the dot product of a rotated query at position m and a rotated key at position n depends on m − n and not on m and n separately.

<details>
<summary>Solutions</summary>

1. q·k = Σᵢ qᵢkᵢ. Each product has mean E[qᵢ]E[kᵢ] = 0 and variance E[qᵢ²]E[kᵢ²] − 0 = 1. The d_k products are independent, so their variances add: d_k.
2. The variance after is var/(var + 10⁻⁵) = 0.999996, give or take 5 × 10⁻⁷ from the rounding, so var = 10⁻⁵ × 0.999996/(1 − 0.999996) ≈ 2.5, somewhere between 2.2 and 2.9. The token's variance was 2.31.
3. The classifier's gradient is already divided by the 100 examples and the 4 positions, and the attention divides it by batch × seq = 400 again: w_q moves by η/400 times its gradient, where the head and the layer normalizations move by η times theirs. Removing the division from `multi_head_attention_backward` and `FeedForward::backward` would make every layer step by η times the gradient of whatever loss the caller differentiates, as `LayerNorm::backward` already does.
4. On one pair, the rotation by angle α is the 2 × 2 matrix R(α), and R(α)ᵀR(β) = R(β − α). So (R(mθᵢ)q)·(R(nθᵢ)k) = qᵀR(mθᵢ)ᵀR(nθᵢ)k = qᵀR((n − m)θᵢ)k, which depends on n − m only. The dot product is the sum of these over the pairs.

</details>

## Sources

- IX at pinned commit `490c395`: [`attention.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/attention.rs), [`norm.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/norm.rs), [`transformer.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/transformer.rs), [`positional.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/positional.rs) and [`classifier.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/classifier.rs).
- A. Vaswani et al., ["Attention is all you need"](https://arxiv.org/abs/1706.03762), NeurIPS 2017: attention, the scaling, multi-head attention, the sinusoidal encoding.
- J. L. Ba, J. R. Kiros and G. E. Hinton, ["Layer normalization"](https://arxiv.org/abs/1607.06450), 2016.
- R. Xiong et al., ["On layer normalization in the transformer architecture"](https://arxiv.org/abs/2002.04745), ICML 2020: pre-norm and post-norm.
- X. Glorot and Y. Bengio, ["Understanding the difficulty of training deep feedforward neural networks"](https://proceedings.mlr.press/v9/glorot10a.html), AISTATS 2010: the initialization.
- D. Hendrycks and K. Gimpel, ["Gaussian error linear units (GELUs)"](https://arxiv.org/abs/1606.08415), 2016.
- N. Shazeer, ["GLU variants improve transformer"](https://arxiv.org/abs/2002.05202), 2020: SwiGLU.
- J. Su et al., ["RoFormer: enhanced transformer with rotary position embedding"](https://arxiv.org/abs/2104.09864), 2021.
