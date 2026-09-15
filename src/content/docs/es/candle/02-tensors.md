---
title: 2. Tensores
description: El Tensor de Candle por dentro, crear tensores, los tipos de elemento y sus conversiones, formas y dimensiones, broadcasting explícito, indexar con i, index_select y gather, reducciones y comparaciones, y los errores y panics en tiempo de ejecución de candle-core 0.11.0 con sus mensajes reales, incluida una comprobación de forma que solo llegó después de la versión publicada.
sidebar:
  order: 2
---

Un tensor es un array con cualquier número de dimensiones cuyos elementos tienen todos un mismo tipo. En C# recurrirías a un `float[,]` o a un `Span<float>` con un ancho; en Java, a un `float[]` y una fórmula de índices. Un tensor mantiene juntos el buffer plano y la fórmula, y cada operación de un modelo, de un producto de matrices a un softmax, es una operación sobre tensores. Esta lección es el vocabulario del resto del curso.

| | PyTorch | Candle |
|---|---|---|
| Crear a partir de valores | `torch.tensor([[1., 2.], [3., 4.]])` | `Tensor::new(&[[1f32, 2.], [3., 4.]], &Device::Cpu)?` |
| Tipo de elemento | `t.dtype`, `t.to(torch.float16)` | `t.dtype()`, `t.to_dtype(DType::F16)?` |
| Forma | `t.shape`, `t.view(4, -1)` | `t.dims()`, `t.reshape((4, ()))?` |
| Broadcasting | implícito en `a + b` | explícito: `a.broadcast_add(&b)?` |
| Indexación | `t[:, 1:]` | `t.i((.., 1..))?` |
| Un error | una excepción | un valor `candle_core::Error` |

[TorchSharp](https://github.com/dotnet/TorchSharp/blob/8f4def03b641b6753f18076aa5438f8eaaef2d30/README.md) conserva en C# los nombres y el comportamiento de PyTorch, así que la columna de PyTorch también sirve de guía para él. Fuentes: [tensores de PyTorch](https://docs.pytorch.org/docs/stable/tensors.html), la [chuleta](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/README.md?plain=1#L267-L282) de Candle y [`Tensor` en docs.rs](https://docs.rs/candle-core/0.11.0/candle_core/struct.Tensor.html).

El código está en [`examples/l02_tensors.rs`](https://github.com/spareilleux/learn/blob/c45b150/code/candle/course/examples/l02_tensors.rs) y [`examples/l02_errors.rs`](https://github.com/spareilleux/learn/blob/c45b150/code/candle/course/examples/l02_errors.rs). Los valores los imprime un pequeño helper, [`show`](https://github.com/spareilleux/learn/blob/c45b150/code/candle/course/src/lib.rs#L6-L20), que aplana un tensor y redondea cada valor, para que los tres sistemas operativos impriman los mismos dígitos.

## Qué es un `Tensor`

[`tensor.rs`, líneas 23-68](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/tensor.rs#L23-L68), abreviado:

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

Un `Tensor` es un puntero con conteo de referencias, como una referencia a un objeto en C# o Java: `clone()` copia el puntero, no los números. Los números viven en un `Storage`, un buffer plano en un dispositivo, compartido entre tensores detrás de su propio `Arc`. El `Layout` dice cómo leer ese buffer: la forma, el paso entre elementos a lo largo de cada dimensión (los *strides*) y dónde empieza el tensor. `op` recuerda la operación que produjo el tensor, para los gradientes (lección 4). La lección 3 muestra qué operaciones comparten un storage y cuáles lo copian.

Nada en `Tensor` es mutable a través de la API pública, salvo el contenido de una `Var` (lección 4): cada operación devuelve un tensor nuevo.

## Crear tensores

[Líneas 11-34](https://github.com/spareilleux/learn/blob/c45b150/code/candle/course/examples/l02_tensors.rs#L11-L34):

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

- [`Tensor::new`](https://docs.rs/candle-core/0.11.0/candle_core/struct.Tensor.html#method.new) recibe un array de Rust, arrays anidados, un slice o un único número, y lee la forma de su tipo: `&[[f32; 3]; 2]` es un tensor `(2, 3)`. El tipo de elemento viene del literal, `1f32` aquí.
- [`Tensor::from_vec`](https://docs.rs/candle-core/0.11.0/candle_core/struct.Tensor.html#method.from_vec) recibe un `Vec` plano y una forma. Una forma es una tupla de dimensiones, un único `usize` para una dimensión, o `()` para un escalar.
- Una dimensión de la forma puede ser `()`, un hueco que Candle rellena a partir del número de elementos, como `-1` en PyTorch: 12 valores en `(2, (), 3)` dan `(2, 2, 3)`.
- Un único número da un tensor de rango 0, sin dimensiones. `to_scalar` lo vuelve a leer como un valor de Rust.

Las filas de longitudes distintas no compilan, porque `[f32; 2]` y `[f32; 3]` son tipos distintos. Es uno de los pocos errores de forma que Rust detecta por ti:

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

## Tipos de elemento

[`DType`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/dtype.rs#L6-L38) enumera `U8`, `U32`, `I16`, `I32`, `I64` para los enteros; `F16`, `BF16`, `F32`, `F64` para los flotantes; y formatos flotantes de 8, 6 y 4 bits usados para guardar modelos cuantizados. Los pesos son flotantes; los índices, los ids de token y las máscaras son enteros.

[Las líneas 37-54](https://github.com/spareilleux/learn/blob/c45b150/code/candle/course/examples/l02_tensors.rs#L37-L54) convierten cuatro flotantes:

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

Un flotante se convierte en entero como lo hace el [cast `as`](https://doc.rust-lang.org/reference/expressions/operator-expr.html#numeric-cast) de Rust: se descarta la parte fraccionaria (2.5 pasa a 2, no a 3), y un valor fuera del rango del destino se satura (−2.5 pasa a 0 en `U8`, 300.7 pasa a 255). Java también descarta la parte fraccionaria, pero allí `(byte) 300.7f` da 44: el flotante pasa al `int` 300, que luego da la vuelta al convertirse en byte ([JLS 5.1.3](https://docs.oracle.com/javase/specs/jls/se25/html/jls-5.html#jls-5.1.3)). C# satura como Rust desde [.NET 9](https://learn.microsoft.com/dotnet/core/compatibility/jit/9.0/fp-to-integer). Un flotante de media precisión solo tiene 65 536 combinaciones de bits, así que 300.7 pasa a 300.75, la más cercana. Un modelo guardado en `F16` ocupa la mitad de memoria que en `F32`, a cambio de esa pérdida de precisión.

Mezclar tipos es un error, no una conversión silenciosa: la lista de errores al final de esta lección incluye `row + ints`.

## Formas y dimensiones

[Líneas 57-78](https://github.com/spareilleux/learn/blob/c45b150/code/candle/course/examples/l02_tensors.rs#L57-L78):

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

- Las dimensiones se numeran desde 0. [`D::Minus1`](https://docs.rs/candle-core/0.11.0/candle_core/shape/enum.D.html) cuenta desde el final, como `-1` en Python: la última dimensión, sea cual sea el rango.
- `dims3()` comprueba que el rango es 3 y devuelve los tres tamaños como una tupla, lo que se lee mejor que indexar `dims()` en el código de un modelo.
- `reshape` cambia la forma y mantiene los elementos en el mismo orden; `flatten_from(1)` fusiona todas las dimensiones a partir de la 1.
- `unsqueeze(0)` añade una dimensión de tamaño 1, a menudo un lote de uno; `squeeze(0)` la quita.
- `transpose` intercambia dos dimensiones, `permute` las reordena todas. Ninguna mueve un número: la lección 3 muestra que solo cambian los strides.

## El broadcasting es explícito

Sumar una fila de sesgo a cada fila de una matriz es broadcasting: el tensor más pequeño se repite a lo largo de las dimensiones en las que tiene tamaño 1, o en las que no tiene dimensión alguna. PyTorch y TorchSharp lo hacen dentro de `+`. El `+` de Candle exige dos formas idénticas, y el broadcasting tiene sus propios métodos: [líneas 81-88](https://github.com/spareilleux/learn/blob/c45b150/code/candle/course/examples/l02_tensors.rs#L81-L88).

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

La regla es la de NumPy, implementada en [`shape.rs`, líneas 191-227](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/shape.rs#L191-L227): se alinean las formas por la derecha, y en cada dimensión los tamaños deben ser iguales o uno de ellos debe ser 1. `(2, 3)` y `(3)` dan `(2, 3)`; `(3)` y `(2, 1)` dan `(2, 3)`, un producto exterior. [`broadcast_binary_op`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/tensor.rs#L137-L156) calcula la forma común, llama a `broadcast_as` sobre los operandos que lo necesitan y luego a la operación simple.

Un número es distinto: `&m * 2.0` funciona con cualquier forma, porque [`bin_trait!`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/tensor.rs#L2973-L3044) implementa `Mul<f64>` como `affine(2.0, 0.0)`, un `x · 2 + 0` elemento a elemento.

Los operadores sobre tensores devuelven un `Result`, lo que tiene dos consecuencias. El `?` va sobre la expresión entre paréntesis, como en `(&m * 2.0)? - 1.0`, y olvidarlo da uno de dos errores de compilación, según lo que venga después:

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

`Result<Tensor> - Tensor` sí compila, porque Candle implementa los operadores sobre `Result` cuando el lado derecho es un tensor, así que `(&a + &b) - &c` funciona sin `?` en medio. Solo falta la versión con un número a la derecha, `Result<Tensor> - f64`.

## Indexación

El trait [`IndexOp`](https://docs.rs/candle-core/0.11.0/candle_core/trait.IndexOp.html) añade `i`, que recibe un índice, un rango o una tupla de ellos, uno por dimensión: [líneas 91-109](https://github.com/spareilleux/learn/blob/c45b150/code/candle/course/examples/l02_tensors.rs#L91-L109).

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

- Un número elimina su dimensión: `m.i(1)` es la fila 1, de forma `(3)`. Un rango la conserva: `m.i((.., 1..))` sigue siendo bidimensional. [`indexer.rs`, líneas 27-61](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/indexer.rs#L27-L61) convierte ambos en llamadas a `narrow`.
- `index_select` elige filas o columnas enteras mediante un tensor de índices `U32` o `I64`, con repeticiones incluidas. Una tabla de embeddings es exactamente eso (lección 5).
- `gather` elige un elemento por fila: para la fila 0 el elemento de la columna 2, para la fila 1 el de la columna 0. Una pérdida de clasificación lo usa para tomar la puntuación de la clase correcta.
- `to_scalar`, `to_vec1`, `to_vec2` y `to_vec3` copian los valores fuera, a números y vectores de Rust, y comprueban tanto el rango como el tipo.

No hay indexación con `[]`, porque el trait `Index` de Rust debe devolver una referencia a algo que ya existe, y un trozo de un tensor es un tensor nuevo:

```text
error[E0608]: cannot index into a value of type `candle_core::Tensor`
 --> course\examples\x_index.rs:5:18
  |
5 |     let first = m[0];
  |                  ^^^
```

## Reducciones y otras operaciones

[Líneas 112-137](https://github.com/spareilleux/learn/blob/c45b150/code/candle/course/examples/l02_tensors.rs#L112-L137):

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

- Una reducción a lo largo de una dimensión la elimina; la versión `_keepdim` la deja con tamaño 1, que es la forma que necesitas para volver a hacer broadcasting del resultado contra el original. `sum_all` y `mean_all` reducen a un escalar.
- `argmax` devuelve índices `U32`, y las comparaciones como `ge` devuelven una máscara `U8` de 0 y 1.
- `cat` une tensores a lo largo de una dimensión existente, `stack` a lo largo de una nueva.
- El softmax, que convierte puntuaciones en probabilidades, no es un método de `Tensor` (`candle-nn` tiene uno, lección 5). Escrito a mano, muestra el patrón que usa todo modelo: reducir con `_keepdim` y volver a hacer broadcasting.

```rust
fn softmax(x: &Tensor) -> candle::Result<Tensor> {
    let shifted = x.broadcast_sub(&x.max_keepdim(D::Minus1)?)?;
    let e = shifted.exp()?;
    e.broadcast_div(&e.sum_keepdim(D::Minus1)?)
}
```

Restar primero el máximo no cambia nada en el resultado, ya que el factor `exp(-max)` se cancela, y evita que `exp` desborde con puntuaciones grandes.

## Errores en tiempo de ejecución

Las formas y los tipos son valores en tiempo de ejecución, así que la mayoría de los errores vuelven como un `Err`. [`examples/l02_errors.rs`](https://github.com/spareilleux/learn/blob/c45b150/code/candle/course/examples/l02_errors.rs#L12-L53) provoca uno de cada y imprime su mensaje:

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

La mayoría de los mensajes nombran la operación y las dos formas, que es lo que necesitas. Unos pocos requieren traducción:

- `m.squeeze(0)` tiene éxito y devuelve `m` sin cambios, porque la dimensión 0 tiene tamaño 2, no 1. PyTorch hace lo mismo ([`tensor.rs`, línea 2567](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/tensor.rs#L2566-L2568)); una comprobación de forma propia es la manera de detectarlo.
- Un índice más allá del final, `m.i(2)`, se informa como el `narrow` en el que se convierte.
- `m.i((0, 0, 0))` tiene un índice de más. Los dos primeros índices seleccionan un escalar, y el tercero falla sobre él: "dimension index 0 out of range for shape []" describe ese último paso, no tu error.
- `row.to_vec1::<f64>()` no convierte: leer los valores exige el tipo exacto, así que llama antes a `to_dtype`.

`check.sh` ejecuta este ejemplo con el mismo entorno que tu shell. Con `RUST_BACKTRACE=1` definido, cada uno de estos errores lleva además un backtrace, porque Candle captura uno al crear un error ([`error.rs`, líneas 263-273](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/error.rs#L263-L273)). Eso ayuda a encontrar de dónde vino un error de forma en un modelo grande.

### Dos panics

Dos operaciones de esa lista no devuelven un error; provocan un panic, y detendrían el hilo de un servidor. El ejemplo captura el panic con un helper, [`caught`](https://github.com/spareilleux/learn/blob/c45b150/code/candle/course/src/lib.rs#L30-L49), para imprimir su mensaje.

**`sqrt` sobre un tensor entero.** Las operaciones unarias se generan con una macro cuyas ramas enteras son `todo!("no unary function for u32")` ([`op.rs`, líneas 490-493](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/op.rs#L490-L493)). `todo!` provoca un panic con "not yet implemented". El mismo código está hoy en `main`. Convierte a un tipo flotante antes de llamar a `sqrt`, `exp`, `log` u otras funciones de coma flotante.

**Un buffer más corto que su forma.** [Líneas 55-62](https://github.com/spareilleux/learn/blob/c45b150/code/candle/course/examples/l02_errors.rs#L55-L62):

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

Cinco valores con una forma de seis elementos se aceptan, y el error solo aparece más tarde, como un panic, en la primera operación que lee el sexto elemento. La documentación de `from_vec` dice que las cantidades deben coincidir, pero en 0.11.0 una forma sin hueco se salta la comprobación: [`shape.rs`, líneas 474-478](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/shape.rs#L474-L478) ignora el número de elementos. Es el [issue #3812](https://github.com/huggingface/candle/issues/3812), que además atribuye a esto una familia de resultados erróneos en máscaras de atención por lotes, corregido en `main` por la [pull request #3813](https://github.com/huggingface/candle/pull/3813) el 13 de agosto de 2026, después de publicarse 0.11.0. Hasta la próxima versión, comprueba tú mismo `data.len()` contra la forma cuando los datos vienen de fuera. El backend de CPU provoca un panic por un índice de slice; en una GPU, el issue informa de lecturas más allá del buffer.

### Semillas

```text
== seeds
Device::Cpu.set_seed(42): error: cannot seed the CPU rng with set_seed
```

El backend de CPU obtiene `rand` y `randn` del generador aleatorio del hilo y se niega a darle una semilla ([`cpu_backend/mod.rs`, líneas 3096-3108](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/cpu_backend/mod.rs#L3096-L3108)). Una ejecución reproducible en la CPU tiene que generar ella misma sus números aleatorios, con un generador con semilla del crate [`rand`](https://docs.rs/rand/0.9/rand/), y pasarlos a `Tensor::from_vec`. Eso importa en la lección 5, donde los pesos de una capa empiezan siendo aleatorios.

## Puntos clave

- Un `Tensor` es un puntero barato de clonar a un buffer compartido más un layout; las operaciones devuelven tensores nuevos.
- Las formas son tuplas, con como mucho un hueco `()`. `D::Minus1` cuenta desde el final. Rust detecta los literales de arrays irregulares, y nada más sobre las formas.
- Los tipos de elemento nunca se convierten en silencio. De flotante a entero se trunca y se satura; `F16` reduce la memoria a la mitad y redondea.
- `+`, `-`, `*`, `/` entre tensores exigen formas iguales. El broadcasting es `broadcast_add` y sus hermanos; un número a la derecha usa `affine`.
- `i` indexa con números y rangos; `index_select` y `gather` indexan con tensores.
- Los errores son valores con mensajes útiles. En 0.11.0, las funciones de coma flotante sobre tensores enteros provocan un panic, y `from_vec` no comprueba el número de elementos; el generador de la CPU no admite semilla.

## Ejercicios

Las soluciones están en [`examples/l02_exercises.rs`](https://github.com/spareilleux/learn/blob/c45b150/code/candle/course/examples/l02_exercises.rs), y su salida en `expected/l02_exercises.txt`.

1. Dados tres puntos `p` de forma `(3, 2)` y dos puntos `q` de forma `(2, 2)`, calcula con broadcasting la matriz `(3, 2)` de distancias al cuadrado entre cada punto de `p` y cada punto de `q`, y luego el índice del punto de `q` más cercano a cada punto de `p`. Calcula la misma matriz de una segunda forma, sin un tensor tridimensional.

<details>
<summary>Solución</summary>

[Líneas 10-23](https://github.com/spareilleux/learn/blob/c45b150/code/candle/course/examples/l02_exercises.rs#L10-L23):

```rust
let p = Tensor::new(&[[0f32, 0.], [3., 4.], [1., 1.]], &dev)?; // (3, 2)
let q = Tensor::new(&[[0f32, 0.], [6., 8.]], &dev)?; // (2, 2)
// (3, 1, 2) - (1, 2, 2) se expande a (3, 2, 2): un vector de diferencias por pareja
let diff = p.unsqueeze(1)?.broadcast_sub(&q.unsqueeze(0)?)?;
let d2 = diff.sqr()?.sum(D::Minus1)?;
// Punto de q más cercano a cada punto de p
show("nearest", &d2.argmin(1)?, 0)?;
// Lo mismo sin el tensor tridimensional: |p|^2 + |q|^2 - 2 p.q
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

El punto `(3, 4)` está a la misma distancia, 25, de los dos puntos de `q`; `argmin` devuelve el primer índice en caso de empate. La primera versión construye un tensor `(3, 2, 2)`, que para mil puntos de cada lado y 768 dimensiones serían tres gigabytes de flotantes; la segunda solo construye matrices `(3, 2)`, que es como se escribe la búsqueda de vecinos más cercanos sobre embeddings (lección 7, y el [curso de IA de GA](../../ga-ai/03-index-and-search/)).

</details>

2. Un modelo da puntuaciones para 3 clases a 4 ejemplos, en un tensor `(4, 3)`, y las clases correctas son `[1, 0, 1, 1]`. Calcula la exactitud, la proporción de ejemplos cuya puntuación más alta es la clase correcta, como un `f32`.

<details>
<summary>Solución</summary>

[Líneas 26-44](https://github.com/spareilleux/learn/blob/c45b150/code/candle/course/examples/l02_exercises.rs#L26-L44):

```rust
let labels = Tensor::new(&[1u32, 0, 1, 1], &dev)?;
let predicted = scores.argmax(D::Minus1)?;
let correct = predicted.eq(&labels)?; // U8: 1 donde son iguales
let accuracy = correct.to_dtype(DType::F32)?.mean_all()?.to_scalar::<f32>()?;
```

```text
== exercise 2: accuracy of scores against labels
predicted: shape [4], U32, [1, 0, 2, 0]
correct: shape [4], U8, [1, 1, 0, 0]
accuracy 0.5
```

`argmax` da `U32`, así que las etiquetas también deben ser `U32`, o `eq` falla con un dtype mismatch. La media de una máscara `U8` sería una media entera; convertir antes a `F32` da 0.5. Las puntuaciones del último ejemplo, 3.0 y 2.9, están muy cerca: la exactitud ignora por cuánto acierta o falla una predicción, y por eso los modelos se entrenan con una pérdida ([curso de IX, lección 3](../../machine-learning-ix/03-classification/)).

</details>

## Fuentes

- Candle en `31f35b1`: [`tensor.rs`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/tensor.rs), [`shape.rs`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/shape.rs), [`indexer.rs`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/indexer.rs), [`dtype.rs`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/dtype.rs), [`error.rs`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/error.rs)
- [`candle_core::Tensor`](https://docs.rs/candle-core/0.11.0/candle_core/struct.Tensor.html) y [`candle_core::Error`](https://docs.rs/candle-core/0.11.0/candle_core/error/enum.Error.html) en docs.rs
- [Issue #3812 de Candle](https://github.com/huggingface/candle/issues/3812) y [pull request #3813](https://github.com/huggingface/candle/pull/3813)
- [Broadcasting en NumPy](https://numpy.org/doc/stable/user/basics.broadcasting.html), la regla que sigue Candle
- [The Rust Reference: casts numéricos](https://doc.rust-lang.org/reference/expressions/operator-expr.html#numeric-cast)
