---
title: 2. Tensors
description: Candle's Tensor from the inside, creating tensors, element types and their conversions, shapes and dimensions, explicit broadcasting, indexing with i, index_select and gather, reductions and comparisons, and the run-time errors and panics of candle-core 0.11.0 with their real messages, including a shape check that only arrived after the release.
sidebar:
  order: 2
---

A tensor is an array with any number of dimensions whose elements all have one type. In C# you'd reach for a `float[,]` or a `Span<float>` with a width; in Java, a `float[]` and an index formula. A tensor keeps the flat buffer and the formula together, and every operation of a model, from a matrix product to a softmax, is an operation on tensors. This lesson is the vocabulary of the rest of the course.

| | PyTorch | Candle |
|---|---|---|
| Create from values | `torch.tensor([[1., 2.], [3., 4.]])` | `Tensor::new(&[[1f32, 2.], [3., 4.]], &Device::Cpu)?` |
| Element type | `t.dtype`, `t.to(torch.float16)` | `t.dtype()`, `t.to_dtype(DType::F16)?` |
| Shape | `t.shape`, `t.view(4, -1)` | `t.dims()`, `t.reshape((4, ()))?` |
| Broadcasting | implicit in `a + b` | explicit: `a.broadcast_add(&b)?` |
| Indexing | `t[:, 1:]` | `t.i((.., 1..))?` |
| An error | an exception | a `candle_core::Error` value |

[TorchSharp](https://github.com/dotnet/TorchSharp/blob/8f4def03b641b6753f18076aa5438f8eaaef2d30/README.md) keeps PyTorch's names and behaviour in C#, so the PyTorch column is also a good guide to it. Sources: [PyTorch tensors](https://docs.pytorch.org/docs/stable/tensors.html), Candle's [cheat sheet](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/README.md?plain=1#L267-L282) and [`Tensor` on docs.rs](https://docs.rs/candle-core/0.11.0/candle_core/struct.Tensor.html).

The code is [`examples/l02_tensors.rs`](https://github.com/spareilleux/learn/blob/c45b150/code/candle/course/examples/l02_tensors.rs) and [`examples/l02_errors.rs`](https://github.com/spareilleux/learn/blob/c45b150/code/candle/course/examples/l02_errors.rs). Values are printed by a small helper, [`show`](https://github.com/spareilleux/learn/blob/c45b150/code/candle/course/src/lib.rs#L6-L20), which flattens a tensor and rounds every value, so that the three operating systems print the same digits.

## What a `Tensor` is

[`tensor.rs`, lines 23-68](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/tensor.rs#L23-L68), shortened:

```rust
pub struct Tensor_ {
    id: TensorId,
    storage: Arc<RwLock<Storage>>,
    layout: Layout,
    op: BackpropOp,
    is_variable: bool,
    dtype: DType,
    device: Device,
}

pub struct Tensor(Arc<Tensor_>);
```

A `Tensor` is a reference-counted pointer, like a C# or Java object reference: `clone()` copies the pointer, not the numbers. The numbers live in a `Storage`, a flat buffer on one device, shared between tensors behind its own `Arc`. The `Layout` says how to read that buffer: the shape, the step between elements along each dimension (the *strides*), and where the tensor starts. `op` remembers the operation that produced the tensor, for gradients (lesson 4). Lesson 3 shows which operations share a storage and which copy it.

Nothing in `Tensor` is mutable through the public API, except a `Var`'s content (lesson 4): every operation returns a new tensor.

## Creating tensors

[Lines 11-34](https://github.com/spareilleux/learn/blob/c45b150/code/candle/course/examples/l02_tensors.rs#L11-L34):

```rust
let from_array = Tensor::new(&[[1f32, 2., 3.], [4., 5., 6.]], &dev)?;
let from_vec = Tensor::from_vec(vec![1u32, 2, 3, 4, 5, 6], (3, 2), &dev)?;
let hole = Tensor::from_vec((0..12).collect::<Vec<i64>>(), (2, (), 3), &dev)?;
Tensor::zeros((2, 2), DType::F64, &dev)?;
Tensor::full(7u8, 3, &dev)?;
Tensor::arange_step(0f32, 1., 0.25, &dev)?;
let scalar = Tensor::new(2.5f64, &dev)?;
```

```text
== creating
new(&[[f32; 3]; 2]): shape [2, 3], F32, [1, 2, 3, 4, 5, 6]
from_vec(Vec<u32>, (3, 2)): shape [3, 2], U32, [1, 2, 3, 4, 5, 6]
from_vec(0..12, (2, (), 3)): shape [2, 2, 3], I64, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
zeros((2, 2), F64): shape [2, 2], F64, [0, 0, 0, 0]
full(7u8, 3): shape [3], U8, [7, 7, 7]
arange_step(0.0, 1.0, 0.25): shape [4], F32, [0.00, 0.25, 0.50, 0.75]
scalar: rank 0, dims [], value 2.5
```

- [`Tensor::new`](https://docs.rs/candle-core/0.11.0/candle_core/struct.Tensor.html#method.new) takes a Rust array, nested arrays, a slice or a single number, and reads the shape from its type: `&[[f32; 3]; 2]` is a `(2, 3)` tensor. The element type comes from the literal, `1f32` here.
- [`Tensor::from_vec`](https://docs.rs/candle-core/0.11.0/candle_core/struct.Tensor.html#method.from_vec) takes a flat `Vec` and a shape. A shape is a tuple of dimensions, a single `usize` for one dimension, or `()` for a scalar.
- One dimension of the shape can be `()`, a hole Candle fills from the number of elements, like `-1` in PyTorch: 12 values in `(2, (), 3)` make `(2, 2, 3)`.
- A single number makes a tensor of rank 0, with no dimensions. `to_scalar` reads it back into a Rust value.

Rows of different lengths don't compile, because `[f32; 2]` and `[f32; 3]` are different types. This is one of the few shape errors Rust catches for you:

```rust
let ragged = Tensor::new(&[[1f32, 2.], [3., 4., 5.]], &Device::Cpu)?;
```

```text
error[E0308]: mismatched types
 --> course\examples\x_ragged.rs:4:44
  |
4 |     let ragged = Tensor::new(&[[1f32, 2.], [3., 4., 5.]], &Device::Cpu)?;
  |                                            ^^^^^^^^^^^^ expected an array with a size of 2, found one with a size of 3
```

## Element types

[`DType`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/dtype.rs#L6-L38) lists `U8`, `U32`, `I16`, `I32`, `I64` for integers; `F16`, `BF16`, `F32`, `F64` for floats; and 8-, 6- and 4-bit float formats used to store quantized models. Weights are floats; indexes, token ids and masks are integers.

[Lines 37-54](https://github.com/spareilleux/learn/blob/c45b150/code/candle/course/examples/l02_tensors.rs#L37-L54) convert four floats:

```rust
let x = Tensor::new(&[1.4f32, 2.5, -2.5, 300.7], &dev)?;
show("to_dtype(U8)", &x.to_dtype(DType::U8)?, 0)?;
show("to_dtype(I64)", &x.to_dtype(DType::I64)?, 0)?;
show("to_dtype(F16)", &x.to_dtype(DType::F16)?, 2)?;
```

```text
== dtypes
f32: shape [4], F32, [1.40, 2.50, -2.50, 300.70]
to_dtype(U8): shape [4], U8, [1, 2, 0, 255]
to_dtype(I64): shape [4], I64, [1, 2, -2, 300]
to_dtype(F16): shape [4], F16, [1.40, 2.50, -2.50, 300.75]
1/3 as f64 0.33333333333333331, as f32 0.33333334326744080
size in bytes: F16 2, F32 4, F64 8, U8 1
```

A float becomes an integer the way Rust's [`as` cast](https://doc.rust-lang.org/reference/expressions/operator-expr.html#numeric-cast) does it: the fraction is dropped (2.5 becomes 2, not 3), and a value outside the target's range is clamped (−2.5 becomes 0 in `U8`, 300.7 becomes 255). Java drops the fraction too, but `(byte) 300.7f` gives 44 there: the float becomes the `int` 300, which then wraps around to a byte ([JLS 5.1.3](https://docs.oracle.com/javase/specs/jls/se25/html/jls-5.html#jls-5.1.3)). C# clamps like Rust since [.NET 9](https://learn.microsoft.com/dotnet/core/compatibility/jit/9.0/fp-to-integer). A half-precision float has only 65,536 bit patterns, so 300.7 becomes 300.75, its nearest one. A model stored in `F16` takes half the memory of `F32`, for that loss of precision.

Mixing types is an error, not a silent conversion: the error list at the end of this lesson has `row + ints`.

## Shapes and dimensions

[Lines 57-78](https://github.com/spareilleux/learn/blob/c45b150/code/candle/course/examples/l02_tensors.rs#L57-L78):

```text
== shapes
dims [2, 3, 4], rank 3, elem_count 24
dim(0) 2, dim(D::Minus1) 4
dims3: b 2, r 3, c 4
reshape((4, ())) -> [4, 6]
flatten_from(1) -> [2, 12]
unsqueeze(0) -> [1, 2, 3, 4], then squeeze(0) -> [2, 3, 4]
transpose(1, 2) -> [2, 4, 3], permute((2, 0, 1)) -> [4, 2, 3]
```

- Dimensions are numbered from 0. [`D::Minus1`](https://docs.rs/candle-core/0.11.0/candle_core/shape/enum.D.html) counts from the end, like `-1` in Python: the last dimension, whatever the rank.
- `dims3()` checks that the rank is 3 and returns the three sizes as a tuple, which reads better than indexing `dims()` in model code.
- `reshape` changes the shape and keeps the elements in the same order; `flatten_from(1)` merges every dimension from 1 on.
- `unsqueeze(0)` adds a dimension of size 1, often a batch of one; `squeeze(0)` removes it.
- `transpose` swaps two dimensions, `permute` reorders all of them. Neither moves a number: lesson 3 shows they only change the strides.

## Broadcasting is explicit

Adding a bias row to every row of a matrix is broadcasting: the smaller tensor is repeated along the dimensions where it has size 1, or where it has no dimension at all. PyTorch and TorchSharp do it inside `+`. Candle's `+` requires two identical shapes, and broadcasting has its own methods: [lines 81-88](https://github.com/spareilleux/learn/blob/c45b150/code/candle/course/examples/l02_tensors.rs#L81-L88).

```rust
let m = Tensor::new(&[[1f32, 2., 3.], [4., 5., 6.]], &dev)?;
let row = Tensor::new(&[10f32, 20., 30.], &dev)?;
let col = Tensor::new(&[[100f32], [200.]], &dev)?;
show("m.broadcast_add(row)", &m.broadcast_add(&row)?, 0)?;
show("m.broadcast_add(col)", &m.broadcast_add(&col)?, 0)?;
show("row.broadcast_mul(col)", &row.broadcast_mul(&col)?, 0)?;
show("(&m * 2.0)? - 1.0", &((&m * 2.0)? - 1.0)?, 0)?;
show("m.broadcast_as((2, 2, 3))", &m.broadcast_as((2, 2, 3))?, 0)?;
```

```text
== broadcasting
m.broadcast_add(row): shape [2, 3], F32, [11, 22, 33, 14, 25, 36]
m.broadcast_add(col): shape [2, 3], F32, [101, 102, 103, 204, 205, 206]
row.broadcast_mul(col): shape [2, 3], F32, [1000, 2000, 3000, 2000, 4000, 6000]
(&m * 2.0)? - 1.0: shape [2, 3], F32, [1, 3, 5, 7, 9, 11]
m.broadcast_as((2, 2, 3)): shape [2, 2, 3], F32, [1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6]
```

The rule is NumPy's, implemented in [`shape.rs`, lines 191-227](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/shape.rs#L191-L227): align the shapes on the right, and along each dimension the sizes must be equal or one of them must be 1. `(2, 3)` and `(3)` give `(2, 3)`; `(3)` and `(2, 1)` give `(2, 3)`, an outer product. [`broadcast_binary_op`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/tensor.rs#L137-L156) computes the common shape, calls `broadcast_as` on the operands that need it, then the plain operation.

A number is different: `&m * 2.0` works with any shape, because [`bin_trait!`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/tensor.rs#L2973-L3044) implements `Mul<f64>` as `affine(2.0, 0.0)`, an element-wise `x · 2 + 0`.

Operators on tensors return a `Result`, which has two consequences. The `?` goes on the parenthesized expression, as in `(&m * 2.0)? - 1.0`, and forgetting it gives one of two compile errors, depending on what comes next:

```text
error[E0277]: cannot subtract `{float}` from `Result<candle_core::Tensor, candle_core::Error>`
    --> course\examples\x_minus.rs:5:30
     |
   5 |     let shifted = (&m * 2.0) - 1.0;
     |                              ^ no implementation for `Result<candle_core::Tensor, candle_core::Error> - {float}`
```

```text
error[E0599]: no method named `sum_all` found for enum `Result<T, E>` in the current scope
    --> course\examples\x_methods.rs:5:27
     |
   5 |     let total = (&a + &a).sum_all()?;
     |                           ^^^^^^^ method not found in `Result<candle_core::Tensor, candle_core::Error>`
```

`Result<Tensor> - Tensor` does compile, because Candle implements the operators on `Result` when the right side is a tensor, so `(&a + &b) - &c` works without `?` in the middle. Only the version with a number on the right, `Result<Tensor> - f64`, is missing.

## Indexing

The [`IndexOp`](https://docs.rs/candle-core/0.11.0/candle_core/trait.IndexOp.html) trait adds `i`, which takes an index, a range, or a tuple of them, one per dimension: [lines 91-109](https://github.com/spareilleux/learn/blob/c45b150/code/candle/course/examples/l02_tensors.rs#L91-L109).

```text
== indexing
m.i(1): shape [3], F32, [4, 5, 6]
m.i((.., 1)): shape [2], F32, [2, 5]
m.i((.., 1..)): shape [2, 2], F32, [2, 3, 5, 6]
m.i((0, ..=1)): shape [2], F32, [1, 2]
m.narrow(1, 0, 2): shape [2, 2], F32, [1, 2, 4, 5]
m.index_select(ids [2, 0, 2], 1): shape [2, 3], F32, [3, 1, 3, 6, 4, 6]
m.i((.., &ids)): shape [2, 3], F32, [3, 1, 3, 6, 4, 6]
m.gather(picks [[2], [0]], 1): shape [2, 1], F32, [3, 4]
m.i((1, 2)) as a Rust value: 6
m.to_vec2(): [[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]]
```

- A number removes its dimension: `m.i(1)` is row 1, of shape `(3)`. A range keeps it: `m.i((.., 1..))` is still two-dimensional. [`indexer.rs`, lines 27-61](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/indexer.rs#L27-L61) turns both into `narrow` calls.
- `index_select` picks whole rows or columns by a `U32` or `I64` tensor of indexes, repeats included. An embedding table is exactly that (lesson 5).
- `gather` picks one element per row: for row 0 the element in column 2, for row 1 the element in column 0. A classification loss uses it to pick the score of the right class.
- `to_scalar`, `to_vec1`, `to_vec2` and `to_vec3` copy the values out into Rust numbers and vectors, and check both the rank and the type.

There is no `[]` indexing, because Rust's `Index` trait must return a reference to something that already exists, and a slice of a tensor is a new tensor:

```text
error[E0608]: cannot index into a value of type `candle_core::Tensor`
 --> course\examples\x_index.rs:5:18
  |
5 |     let first = m[0];
  |                  ^^^
```

## Reductions and other operations

[Lines 112-137](https://github.com/spareilleux/learn/blob/c45b150/code/candle/course/examples/l02_tensors.rs#L112-L137):

```text
== operations
m.sum_all(): shape [], F32, [21]
m.sum(0): shape [3], F32, [5, 7, 9]
m.sum_keepdim(0): shape [1, 3], F32, [5, 7, 9]
m.mean(D::Minus1): shape [2], F32, [2.0, 5.0]
m.max(1): shape [2], F32, [3, 6]
m.argmax(1): shape [2], U32, [2, 2]
m.t()?.matmul(&m): shape [3, 3], F32, [17, 22, 27, 22, 29, 36, 27, 36, 45]
m.sqr()?.sqrt(): shape [2, 3], F32, [1, 2, 3, 4, 5, 6]
m.ge(3.0): shape [2, 3], U8, [0, 0, 1, 1, 1, 1]
row.exp(): shape [3], F32, [2.7183, 7.3891, 20.0855]
softmax by hand: shape [3], F32, [0.0900, 0.2447, 0.6652]
Tensor::cat(&[&m, &m], 0): shape [4, 3], F32, [1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6]
Tensor::stack(&[&row, &row], 0): shape [2, 3], F32, [10, 20, 30, 10, 20, 30]
[[2., 3.],
 [5., 6.]]
Tensor[[2, 2], f32]
```

- A reduction along a dimension removes it; the `_keepdim` version leaves it with size 1, which is the shape you need to broadcast the result back against the original. `sum_all` and `mean_all` reduce to a scalar.
- `argmax` returns `U32` indexes, and comparisons such as `ge` return a `U8` mask of 0 and 1.
- `cat` joins tensors along an existing dimension, `stack` along a new one.
- The softmax, which turns scores into probabilities, isn't a method of `Tensor` (`candle-nn` has one, lesson 5). Written by hand, it shows the pattern every model uses: reduce with `_keepdim`, then broadcast back.

```rust
fn softmax(x: &Tensor) -> candle::Result<Tensor> {
    let shifted = x.broadcast_sub(&x.max_keepdim(D::Minus1)?)?;
    let e = shifted.exp()?;
    e.broadcast_div(&e.sum_keepdim(D::Minus1)?)
}
```

Subtracting the maximum first changes nothing in the result, since the factor `exp(-max)` cancels out, and keeps `exp` from overflowing on large scores.

## Errors at run time

Shapes and types are run-time values, so most mistakes come back as an `Err`. [`examples/l02_errors.rs`](https://github.com/spareilleux/learn/blob/c45b150/code/candle/course/examples/l02_errors.rs#L12-L53) makes one of each and prints its message:

```text
== shapes
m + row (no implicit broadcasting): error: shape mismatch in add, lhs: [2, 3], rhs: [3]
m.broadcast_add(row): ok
m.broadcast_add([1, 2]): error: shape mismatch in broadcast_add, lhs: [2, 3], rhs: [2]
m.matmul(m): error: shape mismatch in matmul, lhs: [2, 3], rhs: [2, 3]
m.matmul(row): error: shape mismatch in matmul, lhs: [2, 3], rhs: [3]
m.reshape((4, 2)): error: shape mismatch in reshape, lhs: [2, 3], rhs: [4, 2]
m.reshape(((), 4)): error: cannot reshape tensor with 6 elements to ((), 4)
col.broadcast_as((2, 3)): ok
row.broadcast_as((3, 2)): error: cannot broadcast [3] to [3, 2]
Tensor::cat(&[&m, &col], 0): error: shape mismatch in cat for dim 1, shape for arg 1: [2, 3] shape for arg 2: [2, 1]
m.squeeze(0): ok

== dimensions and indexes
m.sum(2): error: sum: dimension index 2 out of range for shape [2, 3]
row.dim(D::Minus2): error: dim: dimension index -2 out of range for shape [3]
m.i(2): error: narrow invalid args start + len > dim_len: [2, 3], dim: 0, start: 2, len:1
m.i((.., ..5)): error: narrow invalid args start + len > dim_len: [2, 3], dim: 1, start: 0, len:5
m.narrow(1, 2, 2): error: narrow invalid args start + len > dim_len: [2, 3], dim: 1, start: 2, len:2
m.index_select([0, 3], 1): error: index-select invalid index 3 with dim size 3
m.i((0, 0, 0)): error: narrow: dimension index 0 out of range for shape []

== dtypes
row.to_vec1::<f64>(): error: unexpected dtype, expected: F64, got: F32
row + ints: error: dtype mismatch in add, lhs: F32, rhs: U32
ints.matmul(ints): error: unsupported dtype U32 for op matmul
ints.sqrt(): panic: not yet implemented: no unary function for u32
m.index_select(f32 ids, 0): error: unsupported dtype F32 for op index-select
m.to_scalar::<f32>(): error: unexpected rank, expected: 0, got: 2 ([2, 3])
```

Most messages name the operation and both shapes, which is what you need. A few need translating:

- `m.squeeze(0)` succeeds and returns `m` unchanged, because dimension 0 has size 2, not 1. PyTorch does the same ([`tensor.rs`, line 2567](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/tensor.rs#L2566-L2568)); a shape check of your own is the way to catch it.
- An index past the end, `m.i(2)`, is reported as the `narrow` it becomes.
- `m.i((0, 0, 0))` has one index too many. The first two indexes select a scalar, and the third one fails on it: "dimension index 0 out of range for shape []" describes that last step, not your mistake.
- `row.to_vec1::<f64>()` doesn't convert: reading values out requires the exact type, so call `to_dtype` first.

`check.sh` runs this example with the same environment as your shell. With `RUST_BACKTRACE=1` set, every one of these errors also carries a backtrace, because Candle captures one when it creates an error ([`error.rs`, lines 263-273](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/error.rs#L263-L273)). That helps find where a shape error came from in a large model.

### Two panics

Two operations in that list don't return an error; they panic, and would stop a server's thread. The example catches the panic with a helper, [`caught`](https://github.com/spareilleux/learn/blob/c45b150/code/candle/course/src/lib.rs#L30-L49), to print its message.

**`sqrt` on an integer tensor.** Unary operations are generated by a macro whose integer branches are `todo!("no unary function for u32")` ([`op.rs`, lines 490-493](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/op.rs#L490-L493)). `todo!` panics with "not yet implemented". The same code is on `main` today. Convert to a float type before calling `sqrt`, `exp`, `log` or the other float functions.

**A buffer shorter than its shape.** [Lines 55-62](https://github.com/spareilleux/learn/blob/c45b150/code/candle/course/examples/l02_errors.rs#L55-L62):

```rust
let short = Tensor::from_vec(vec![1f32, 2., 3., 4., 5.], (2, 3), &dev)?;
println!("from_vec(5 values, (2, 3)): ok, dims {:?}, elem_count {}", short.dims(), short.elem_count());
caught("short.sum_all()", || short.sum_all());
```

```text
== a shape that doesn't match the data (issue #3812, fixed after 0.11.0)
from_vec(5 values, (2, 3)): ok, dims [2, 3], elem_count 6
short.sum_all(): panic: range end index 6 out of range for slice of length 5
```

Five values with a shape of six elements are accepted, and the error only appears later, as a panic, in the first operation that reads the sixth element. The documentation of `from_vec` says the counts must match, but in 0.11.0 a shape without a hole skips the check: [`shape.rs`, lines 474-478](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/shape.rs#L474-L478) ignores the element count. It is [issue #3812](https://github.com/huggingface/candle/issues/3812), which also traces a family of wrong results in batched attention masks to it, fixed on `main` by [pull request #3813](https://github.com/huggingface/candle/pull/3813) on August 13, 2026, after 0.11.0 was released. Until the next release, check `data.len()` against the shape yourself when the data comes from outside. The CPU backend panics on a slice index; on a GPU, the issue reports reads past the buffer.

### Seeds

```text
== seeds
Device::Cpu.set_seed(42): error: cannot seed the CPU rng with set_seed
```

The CPU backend draws `rand` and `randn` from the thread's random generator and refuses to seed it ([`cpu_backend/mod.rs`, lines 3096-3108](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/cpu_backend/mod.rs#L3096-L3108)). A reproducible run on the CPU has to generate its random numbers itself, with a seeded generator from the [`rand`](https://docs.rs/rand/0.9/rand/) crate, and pass them to `Tensor::from_vec`. That matters for lesson 5, where a layer's weights start random.

## Key takeaways

- A `Tensor` is a cheap-to-clone pointer to a shared buffer plus a layout; operations return new tensors.
- Shapes are tuples, with at most one `()` hole. `D::Minus1` counts from the end. Rust catches ragged array literals, and nothing else about shapes.
- Element types never convert silently. Float to integer truncates and clamps; `F16` halves memory and rounds.
- `+`, `-`, `*`, `/` between tensors need equal shapes. Broadcasting is `broadcast_add` and its siblings; a number on the right uses `affine`.
- `i` indexes with numbers and ranges; `index_select` and `gather` index with tensors.
- Errors are values with useful messages. In 0.11.0, float functions on integer tensors panic, and `from_vec` doesn't check the element count; the CPU generator can't be seeded.

## Exercises

The solutions are in [`examples/l02_exercises.rs`](https://github.com/spareilleux/learn/blob/c45b150/code/candle/course/examples/l02_exercises.rs), and their output in `expected/l02_exercises.txt`.

1. Given three points `p` of shape `(3, 2)` and two points `q` of shape `(2, 2)`, compute the `(3, 2)` matrix of squared distances between each point of `p` and each point of `q` with broadcasting, then the index of the nearest point of `q` for each point of `p`. Compute the same matrix a second way, without a three-dimensional tensor.

<details>
<summary>Solution</summary>

[Lines 10-23](https://github.com/spareilleux/learn/blob/c45b150/code/candle/course/examples/l02_exercises.rs#L10-L23):

```rust
let p = Tensor::new(&[[0f32, 0.], [3., 4.], [1., 1.]], &dev)?; // (3, 2)
let q = Tensor::new(&[[0f32, 0.], [6., 8.]], &dev)?; // (2, 2)
// (3, 1, 2) - (1, 2, 2) broadcasts to (3, 2, 2): one difference vector per pair
let diff = p.unsqueeze(1)?.broadcast_sub(&q.unsqueeze(0)?)?;
let d2 = diff.sqr()?.sum(D::Minus1)?;
// Nearest point of q for each point of p
show("nearest", &d2.argmin(1)?, 0)?;
// The same without the 3-d tensor: |p|^2 + |q|^2 - 2 p.q
let pp = p.sqr()?.sum_keepdim(1)?; // (3, 1)
let qq = q.sqr()?.sum_keepdim(1)?.t()?; // (1, 2)
let d2_bis = pp.broadcast_add(&qq)?.sub(&(p.matmul(&q.t()?)? * 2.0)?)?;
```

```text
== exercise 1: squared distances between every point of p and every point of q
d2: shape [3, 2], F32, [0, 100, 25, 25, 2, 74]
dims [3, 2]
nearest: shape [3], U32, [0, 0, 0]
d2 by |p|^2 + |q|^2 - 2 p.q: shape [3, 2], F32, [0, 100, 25, 25, 2, 74]
```

The point `(3, 4)` is at the same distance, 25, from both points of `q`; `argmin` returns the first index on a tie. The first version builds a `(3, 2, 2)` tensor, which for a thousand points of each and 768 dimensions would be three gigabytes of floats; the second only builds `(3, 2)` matrices, which is how nearest-neighbour search on embeddings is written (lesson 7, and the [GA AI course](../../ga-ai/03-index-and-search/)).

</details>

2. A model gives scores for 3 classes to 4 examples, in a `(4, 3)` tensor, and the right classes are `[1, 0, 1, 1]`. Compute the accuracy, the share of examples whose highest score is the right class, as an `f32`.

<details>
<summary>Solution</summary>

[Lines 26-44](https://github.com/spareilleux/learn/blob/c45b150/code/candle/course/examples/l02_exercises.rs#L26-L44):

```rust
let labels = Tensor::new(&[1u32, 0, 1, 1], &dev)?;
let predicted = scores.argmax(D::Minus1)?;
let correct = predicted.eq(&labels)?; // U8: 1 where equal
let accuracy = correct.to_dtype(DType::F32)?.mean_all()?.to_scalar::<f32>()?;
```

```text
== exercise 2: accuracy of scores against labels
predicted: shape [4], U32, [1, 0, 2, 0]
correct: shape [4], U8, [1, 1, 0, 0]
accuracy 0.5
```

`argmax` gives `U32`, so the labels must be `U32` too, or `eq` fails with a dtype mismatch. The mean of a `U8` mask would be an integer mean; converting to `F32` first gives 0.5. The last example's scores, 3.0 and 2.9, are close: accuracy ignores by how much a prediction is right or wrong, which is why models are trained on a loss instead ([IX course, lesson 3](../../machine-learning-ix/03-classification/)).

</details>

## Sources

- Candle at `31f35b1`: [`tensor.rs`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/tensor.rs), [`shape.rs`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/shape.rs), [`indexer.rs`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/indexer.rs), [`dtype.rs`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/dtype.rs), [`error.rs`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/error.rs)
- [`candle_core::Tensor`](https://docs.rs/candle-core/0.11.0/candle_core/struct.Tensor.html) and [`candle_core::Error`](https://docs.rs/candle-core/0.11.0/candle_core/error/enum.Error.html) on docs.rs
- [Candle issue #3812](https://github.com/huggingface/candle/issues/3812) and [pull request #3813](https://github.com/huggingface/candle/pull/3813)
- [NumPy broadcasting](https://numpy.org/doc/stable/user/basics.broadcasting.html), the rule Candle follows
- [The Rust Reference: numeric casts](https://doc.rust-lang.org/reference/expressions/operator-expr.html#numeric-cast)
