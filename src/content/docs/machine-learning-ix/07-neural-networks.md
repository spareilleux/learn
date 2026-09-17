---
title: "7. Neural networks, and finite differences as the judge"
description: "An affine layer and backpropagation written by hand and checked against central differences, then ix_nn — the gradient Dense really applies, which is the true one divided by the batch size, the loss whose gradient is off by the number of output columns, weights drawn without a seed, and a Sequential of Dense layers that stays one affine map because the crate has no activation layer."
sidebar:
  order: 7
---

Every model so far had a shape chosen in advance: a line, a boundary, a tree. A **neural network** has almost no shape. It is a stack of two kinds of step — an affine map `y = xW + b`, and a fixed non-linear function applied to each number — and what it can represent depends only on how many of them you stack.

The part worth learning by hand is not the stacking. It is **backpropagation**: the chain rule applied backwards through the stack, which turns one loss into a gradient for every weight. It is also the part that is easy to get subtly wrong and hard to notice, which is why this lesson leans on the one tool that settles such arguments — **finite differences**, which know nothing about the chain rule and can only measure.

| | ML.NET | Tribuo | PyTorch | IX |
|---|---|---|---|---|
| A layer | — | [`Layer`](https://tribuo.org/learn/4.3/javadoc/org/tribuo/interop/tensorflow/package-summary.html) via TensorFlow | `nn.Linear` | `ix_nn::layer::Dense` |
| A stack | — | — | `nn.Sequential` | `ix_nn::network::Sequential` |
| Activations | — | — | `nn.ReLU`, `nn.Sigmoid`… | none implementing `Layer` |
| Losses | — | — | `nn.MSELoss` | `mse_loss`, `binary_cross_entropy` |
| Automatic gradients | — | — | autograd | `ix-autograd`, a separate crate with its own tape |

The program is [`examples/l07_networks.rs`](https://github.com/spareilleux/learn/blob/37b8830/code/machine-learning-ix/examples/l07_networks.rs), on the 65 builds of lesson 2 with both columns standardized.

## One layer, and its three gradients

For `y = xW + b`, the chain rule gives three things at once. Write `g = dL/dy`, the gradient the layer receives from above:

```text
dL/dW = xᵀ g          dL/db = Σ rows of g          dL/dx = g Wᵀ
```

The first two update this layer; the third is the message passed to the layer below. The hand version returns all three and applies none of them ([`src/net.rs`, lines 40-55](https://github.com/spareilleux/learn/blob/37b8830/code/machine-learning-ix/src/net.rs#L40-L55)):

```rust
pub fn backward(&self, x: &Array2<f64>, grad_output: &Array2<f64>) -> LinearGrads {
    LinearGrads {
        weights: x.t().dot(grad_output),
        bias: grad_output.sum_axis(Axis(0)),
        input: grad_output.dot(&self.weights.t()),
    }
}
```

No division by the batch size appears, and none should: whatever averaging the loss wants is already inside `g`. If the loss is a mean over `n` rows, its own gradient carries the `1/n`.

The judge agrees:

```text
== the hand layer, judged by finite differences
  analytic -0.534895701, numeric -0.534895701, gap 4.35e-11
```

The numeric value comes from the central difference `(f(w + h) - f(w - h)) / 2h` with `h = 1e-6`, which has error of order `h²`, about `1e-12`, plus rounding. A gap of `4e-11` is a pass. Any real mistake in `backward` — a missing transpose, a forgotten factor — shows up as a gap of order 1, not of order `1e-11`.

## The gradient `Dense` actually applies

`ix_nn::layer::Dense` does not return its gradients; `backward` updates the weights itself and returns only the message for the layer below ([`layer.rs`, lines 40-52](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/layer.rs#L40-L52)):

```rust
let grad_weights = input.t().dot(grad_output) / n;
let grad_bias = grad_output.mean_axis(ndarray::Axis(0)).unwrap();
let grad_input = grad_output.dot(&self.weights.t());
self.weights = &self.weights - &(learning_rate * &grad_weights);
```

So the question "what does `Dense` subtract?" can be answered by experiment rather than by reading: set the weights by hand, call `backward` with a learning rate of 1, and look at how much they moved. Next to it, measure the gradient of `ix_nn::loss::mse_loss` itself with central differences.

```text
== ix_nn::layer::Dense, one output column
  gradient of mse_loss, measured: -0.534895701
  what backward subtracts:        -0.008229165
  ratio: 65.0000, and the batch has 65 rows
```

Exactly 65: the number of rows. `grad_output` already holds the `1/n` that `mse_gradient` put there, and `backward` divides by `n` a second time. The direction is right, so training still works — but the learning rate you pass is not the learning rate you get. On these 65 rows, `learning_rate = 0.1` behaves like 0.0015; on a batch of 10 000 it would behave like `1e-5`, and a network that trains fine on a small set would appear frozen on a large one. Nothing else changes, because every `Dense` divides by the same `n`, so the layers stay in proportion to each other.

## A loss and a gradient that do not match

`mse_loss` averages over every cell of the matrix, rows *and* columns. `mse_gradient` divides by the rows only ([`loss.rs`, lines 6-16](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/loss.rs#L6-L16)):

```rust
pub fn mse_loss(predicted: &Array2<f64>, target: &Array2<f64>) -> f64 {
    let diff = predicted - target;
    diff.mapv(|v| v * v).mean().unwrap()
}

pub fn mse_gradient(predicted: &Array2<f64>, target: &Array2<f64>) -> Array2<f64> {
    let n = predicted.nrows() as f64;
    2.0 * (predicted - target) / n
}
```

With one output column the two agree. With `m` columns, `mse_gradient` is `m` times the true gradient of `mse_loss`, and the two effects compose:

```text
== the same layer with two output columns
  measured gradient [-0.267448, -1.234896]
  backward subtracts [-0.008229, -0.037997]
  ratios [32.5000, 32.5000]
```

32.5 is `65 / 2`: divided by 65 rows by `Dense`, multiplied by 2 columns by `mse_gradient`. The exercise walks the ratio out to four columns and gets 1, 2, 3, 4 exactly. Every network in IX with more than one output is therefore trained at a learning rate scaled by the number of outputs, which is the kind of thing that turns "we tuned the learning rate" into folklore.

## Weights nobody can reproduce

`Dense::new` draws its weights from a normal distribution with no seed anywhere in sight ([`layer.rs`, line 27](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/layer.rs#L27)):

```rust
weights: Array2::random((input_size, output_size), Normal::new(0.0, std).unwrap()),
```

`ndarray_rand::RandomExt::random` draws from the thread generator, so two layers built in the same run already differ, and two runs of the same program differ too:

```text
== Dense::new(3, 2) twice in the same run
  the two weight matrices are equal: false
  all zero biases: true, weights are public, so a course can overwrite them
```

Every other random algorithm in IX takes a seed — `KMeans::with_seed`, `RandomForest::with_seed`, `Dropout::new(p, seed)`, `transformer::FeedForward::new(d_model, d_ff, seed)`. `Dense` is the exception, and the consequence is that no result from `Sequential` can be reproduced or regression-tested. The way out is that `weights` and `bias` are public fields: build the layer, then overwrite them, which is what this lesson does everywhere.

## What a stack of `Dense` layers can represent

Two affine maps in a row are one affine map: `(xA + a)B + b = x(AB) + (aB + b)`. A network only becomes more than a line when something non-linear sits between its layers.

`ix-nn` has a `Layer` trait with `forward` and `backward`, and exactly one type implements it: `Dense`. There is no `ReLU` layer, no `Sigmoid` layer, nothing that `Sequential::push` could accept between two affine maps. (The crate does have a GELU — `transformer::gelu` — but it lives inside `FeedForward`, works on `Array3`, and is not a `Layer`.)

**Exclusive or** is the smallest problem that shows what that costs. Four points, and no straight line separates the two classes:

```text
== exclusive or
  hand, two affine layers with a sigmoid between them: loss 0.35722182 -> 0.00000000
  predictions [0.0000, 1.0000, 1.0000, 0.0000]
  ix_nn, two Dense layers and nothing between them: loss 0.34500000 -> 0.25000000
  predictions [0.5000, 0.5000, 0.5000, 0.5000]
  f(0,0) + f(1,1) - f(0,1) - f(1,0) = 0.00e0: the stack is one affine map
```

The hand network — same size, same learning rate, same 50 000 epochs, one sigmoid between the layers — solves it exactly. The IX stack converges to 0.25 and predicts 0.5 everywhere: 0.25 is the variance of the four targets, the best a constant can do, and a constant is the best an affine map can do here.

The last line is the proof rather than the symptom. For any affine `f`, `f(0,0) + f(1,1) = f(0,1) + f(1,0)`, because both sides are `2f` evaluated at the same centre. The trained stack satisfies it to the last bit, after 50 000 epochs of training, at every depth. It is not undertrained; it cannot represent the function.

None of this makes `ix-nn` wrong — attention, layer normalization, RoPE, ALiBi and the transformer blocks in the same crate are where its real work is, and those do have their non-linearities. But `Sequential` plus `Dense` is the part that looks like a beginner's neural network API, and it is the part that can only fit lines.

## Key takeaways

- The backward pass of an affine layer gives three gradients, `xᵀ g`, the sum of the rows of `g` and `g Wᵀ`. Central differences check them to about `1e-11`, and any real mistake shows up as a gap of order 1.
- `Dense::backward` divides by the batch size a second time, so the learning rate you pass shrinks with the number of rows.
- `mse_loss` averages over every cell but `mse_gradient` divides by the rows only: with `m` output columns, the gradient is `m` times the true one.
- `Dense::new` draws its weights without a seed; overwrite the public `weights` and `bias` to make a result reproducible.
- Two affine maps in a row are one affine map. With no activation layer, IX's `Sequential` of `Dense` layers predicts 0.5 everywhere on exclusive or, where one sigmoid between the layers solves it.

## Exercises

1. Choose a learning rate that makes one step of `Dense` land exactly where one step of the hand layer lands.
2. Measure `mse_gradient` against the true gradient of `mse_loss` for one to four output columns.
3. How wide does the hidden layer have to be before the hand network solves exclusive or?

<details>
<summary>Solutions</summary>

They are in [`examples/l07_exercises.rs`](https://github.com/spareilleux/learn/blob/37b8830/code/machine-learning-ix/examples/l07_exercises.rs).

**1.** Multiply by the number of rows, the factor measured above:

```text
== matching one step of the hand layer with one step of Dense
  hand weight after one step at rate 0.5      0.667447851
  Dense weight after one step at rate 0.5 x 65  0.667447851
  gap 0.00e0
```

Not approximately — bit for bit, because the only difference between the two code paths is one multiplication. The landing point is worth a second look: 0.667447851 is the closed-form least-squares slope of lesson 2. With both columns standardized the loss is `w² - 2rw + 1`, whose gradient is `2w - 2r`, so a step of rate 0.5 from any starting point lands on `r` exactly. One step, no iteration.

**2.** The ratio is the number of output columns:

```text
== ix_nn::loss::mse_gradient divided by the true gradient of mse_loss
  1 column(s): ratio [1.0000], and mse_loss = 0.626042
  2 column(s): ratio [2.0000], and mse_loss = 1.859063
  3 column(s): ratio [3.0000], and mse_loss = 3.758750
  4 column(s): ratio [4.0000], and mse_loss = 6.325104
```

**3.** Two sigmoid units are enough, and one is not:

```text
== width of the hidden layer against what it can learn (exclusive or)
  hidden 1: final loss 0.166788, corners right 3 of 4
  hidden 2: final loss 0.000000, corners right 4 of 4
  hidden 3: final loss 0.000000, corners right 4 of 4
  hidden 4: final loss 0.000000, corners right 4 of 4
```

One sigmoid unit draws one boundary, and exclusive or needs two; it gets three corners right and settles at 0.167, better than the 0.25 of a constant but not a solution. Two units draw two boundaries, and the output layer combines them. This is the smallest example of the general result — a single hidden layer of sufficient width can approximate any continuous function — and of its useless half: the theorem says a width exists, not which one.

</details>

## Sources

- Rumelhart, Hinton and Williams, *[Learning representations by back-propagating errors](https://www.nature.com/articles/323533a0)*, 1986
- Goodfellow, Bengio, Courville, *[Deep Learning](https://www.deeplearningbook.org/)*, chapter 6, including the gradient check by finite differences
- Nielsen, *[Neural Networks and Deep Learning](http://neuralnetworksanddeeplearning.com/chap2.html)*, chapter 2, for backpropagation step by step
- [PyTorch: `torch.autograd.gradcheck`](https://docs.pytorch.org/docs/stable/generated/torch.autograd.gradcheck.html), the same test as a library function
- IX at `490c395`: [`ix-nn/src/layer.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/layer.rs), [`ix-nn/src/network.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/network.rs), [`ix-nn/src/loss.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/loss.rs), [`ix-nn/src/transformer.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/transformer.rs)
