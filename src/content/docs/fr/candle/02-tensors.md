---
title: 2. Tenseurs
description: Le Tensor de Candle vu de l'intérieur, la création de tenseurs, les types d'éléments et leurs conversions, les formes et les dimensions, le broadcasting explicite, l'indexation avec i, index_select et gather, les réductions et les comparaisons, et les erreurs d'exécution et paniques de candle-core 0.11.0 avec leurs vrais messages, dont une vérification de forme arrivée seulement après la version.
sidebar:
  order: 2
---

Un tenseur est un tableau à un nombre quelconque de dimensions dont les éléments ont tous le même type. En C#, tu prendrais un `float[,]` ou un `Span<float>` avec une largeur ; en Java, un `float[]` et une formule d'indice. Un tenseur garde ensemble le tampon plat et la formule, et chaque opération d'un modèle, du produit matriciel au softmax, est une opération sur des tenseurs. Cette leçon est le vocabulaire du reste du cours.

| | PyTorch | Candle |
|---|---|---|
| Créer à partir de valeurs | `torch.tensor([[1., 2.], [3., 4.]])` | `Tensor::new(&[[1f32, 2.], [3., 4.]], &Device::Cpu)?` |
| Type des éléments | `t.dtype`, `t.to(torch.float16)` | `t.dtype()`, `t.to_dtype(DType::F16)?` |
| Forme | `t.shape`, `t.view(4, -1)` | `t.dims()`, `t.reshape((4, ()))?` |
| Broadcasting | implicite dans `a + b` | explicite : `a.broadcast_add(&b)?` |
| Indexation | `t[:, 1:]` | `t.i((.., 1..))?` |
| Une erreur | une exception | une valeur `candle_core::Error` |

[TorchSharp](https://github.com/dotnet/TorchSharp/blob/8f4def03b641b6753f18076aa5438f8eaaef2d30/README.md) garde les noms et le comportement de PyTorch en C#, donc la colonne PyTorch est aussi un bon guide pour lui. Sources : [les tenseurs de PyTorch](https://docs.pytorch.org/docs/stable/tensors.html), l'[aide-mémoire](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/README.md?plain=1#L267-L282) de Candle et [`Tensor` sur docs.rs](https://docs.rs/candle-core/0.11.0/candle_core/struct.Tensor.html).

Le code est [`examples/l02_tensors.rs`](https://github.com/spareilleux/learn/blob/c45b150/code/candle/course/examples/l02_tensors.rs) et [`examples/l02_errors.rs`](https://github.com/spareilleux/learn/blob/c45b150/code/candle/course/examples/l02_errors.rs). Les valeurs sont affichées par une petite fonction utilitaire, [`show`](https://github.com/spareilleux/learn/blob/c45b150/code/candle/course/src/lib.rs#L6-L20), qui aplatit un tenseur et arrondit chaque valeur, pour que les trois systèmes d'exploitation affichent les mêmes chiffres.

## Ce qu'est un `Tensor`

[`tensor.rs`, lignes 23-68](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/tensor.rs#L23-L68), raccourci :

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

Un `Tensor` est un pointeur à comptage de références, comme une référence d'objet en C# ou en Java : `clone()` copie le pointeur, pas les nombres. Les nombres vivent dans un `Storage`, un tampon plat sur un périphérique, partagé entre tenseurs derrière son propre `Arc`. Le `Layout` dit comment lire ce tampon : la forme, le pas entre éléments le long de chaque dimension (les *strides*), et l'endroit où le tenseur commence. `op` retient l'opération qui a produit le tenseur, pour les gradients (leçon 4). La leçon 3 montre quelles opérations partagent un stockage et lesquelles le copient.

Rien dans `Tensor` n'est modifiable par l'API publique, sauf le contenu d'une `Var` (leçon 4) : chaque opération renvoie un nouveau tenseur.

## Créer des tenseurs

[Lignes 11-34](https://github.com/spareilleux/learn/blob/c45b150/code/candle/course/examples/l02_tensors.rs#L11-L34) :

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

- [`Tensor::new`](https://docs.rs/candle-core/0.11.0/candle_core/struct.Tensor.html#method.new) prend un tableau Rust, des tableaux imbriqués, une slice ou un nombre seul, et lit la forme dans son type : `&[[f32; 3]; 2]` est un tenseur `(2, 3)`. Le type des éléments vient du littéral, `1f32` ici.
- [`Tensor::from_vec`](https://docs.rs/candle-core/0.11.0/candle_core/struct.Tensor.html#method.from_vec) prend un `Vec` plat et une forme. Une forme est un tuple de dimensions, un seul `usize` pour une dimension, ou `()` pour un scalaire.
- Une dimension de la forme peut être `()`, un trou que Candle remplit d'après le nombre d'éléments, comme `-1` dans PyTorch : 12 valeurs dans `(2, (), 3)` donnent `(2, 2, 3)`.
- Un nombre seul donne un tenseur de rang 0, sans dimension. `to_scalar` le relit en valeur Rust.

Des lignes de longueurs différentes ne compilent pas, parce que `[f32; 2]` et `[f32; 3]` sont des types différents. C'est l'une des rares erreurs de forme que Rust attrape pour toi :

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

## Types d'éléments

[`DType`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/dtype.rs#L6-L38) liste `U8`, `U32`, `I16`, `I32`, `I64` pour les entiers ; `F16`, `BF16`, `F32`, `F64` pour les flottants ; et des formats flottants sur 8, 6 et 4 bits servant à stocker des modèles quantifiés. Les poids sont des flottants ; les indices, les identifiants de tokens et les masques sont des entiers.

[Lignes 37-54](https://github.com/spareilleux/learn/blob/c45b150/code/candle/course/examples/l02_tensors.rs#L37-L54) convertissent quatre flottants :

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

Un flottant devient un entier comme le fait le [cast `as`](https://doc.rust-lang.org/reference/expressions/operator-expr.html#numeric-cast) de Rust : la partie fractionnaire est supprimée (2.5 devient 2, pas 3), et une valeur hors de l'intervalle de la cible est ramenée à la borne (−2.5 devient 0 en `U8`, 300.7 devient 255). Java supprime aussi la partie fractionnaire, mais `(byte) 300.7f` y donne 44 : le flottant devient l'`int` 300, qui est ensuite tronqué en octet ([JLS 5.1.3](https://docs.oracle.com/javase/specs/jls/se25/html/jls-5.html#jls-5.1.3)). C# ramène à la borne comme Rust depuis [.NET 9](https://learn.microsoft.com/dotnet/core/compatibility/jit/9.0/fp-to-integer). Un flottant en demi-précision n'a que 65 536 motifs de bits, donc 300.7 devient 300.75, le plus proche. Un modèle stocké en `F16` prend moitié moins de mémoire qu'en `F32`, au prix de cette perte de précision.

Mélanger les types est une erreur, pas une conversion silencieuse : la liste d'erreurs à la fin de cette leçon contient `row + ints`.

## Formes et dimensions

[Lignes 57-78](https://github.com/spareilleux/learn/blob/c45b150/code/candle/course/examples/l02_tensors.rs#L57-L78) :

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

- Les dimensions sont numérotées à partir de 0. [`D::Minus1`](https://docs.rs/candle-core/0.11.0/candle_core/shape/enum.D.html) compte depuis la fin, comme `-1` en Python : la dernière dimension, quel que soit le rang.
- `dims3()` vérifie que le rang vaut 3 et renvoie les trois tailles dans un tuple, ce qui se lit mieux que d'indexer `dims()` dans le code d'un modèle.
- `reshape` change la forme et garde les éléments dans le même ordre ; `flatten_from(1)` fusionne toutes les dimensions à partir de la 1.
- `unsqueeze(0)` ajoute une dimension de taille 1, souvent un lot d'un seul élément ; `squeeze(0)` la retire.
- `transpose` échange deux dimensions, `permute` les réordonne toutes. Aucune ne déplace un nombre : la leçon 3 montre qu'elles ne changent que les strides.

## Le broadcasting est explicite

Ajouter une ligne de biais à chaque ligne d'une matrice, c'est du broadcasting : le plus petit tenseur est répété le long des dimensions où il a une taille 1, ou là où il n'a pas de dimension du tout. PyTorch et TorchSharp le font dans `+`. Le `+` de Candle exige deux formes identiques, et le broadcasting a ses propres méthodes : [lignes 81-88](https://github.com/spareilleux/learn/blob/c45b150/code/candle/course/examples/l02_tensors.rs#L81-L88).

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

La règle est celle de NumPy, implémentée dans [`shape.rs`, lignes 191-227](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/shape.rs#L191-L227) : aligner les formes à droite, et le long de chaque dimension les tailles doivent être égales ou l'une d'elles doit valoir 1. `(2, 3)` et `(3)` donnent `(2, 3)` ; `(3)` et `(2, 1)` donnent `(2, 3)`, un produit extérieur. [`broadcast_binary_op`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/tensor.rs#L137-L156) calcule la forme commune, appelle `broadcast_as` sur les opérandes qui en ont besoin, puis l'opération simple.

Un nombre, c'est différent : `&m * 2.0` fonctionne avec n'importe quelle forme, parce que [`bin_trait!`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/tensor.rs#L2973-L3044) implémente `Mul<f64>` par `affine(2.0, 0.0)`, un `x · 2 + 0` élément par élément.

Les opérateurs sur les tenseurs renvoient un `Result`, ce qui a deux conséquences. Le `?` se place sur l'expression entre parenthèses, comme dans `(&m * 2.0)? - 1.0`, et l'oublier donne l'une de deux erreurs de compilation, selon ce qui suit :

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

`Result<Tensor> - Tensor` compile bien, parce que Candle implémente les opérateurs sur `Result` quand le côté droit est un tenseur, donc `(&a + &b) - &c` fonctionne sans `?` au milieu. Seule manque la version avec un nombre à droite, `Result<Tensor> - f64`.

## Indexation

Le trait [`IndexOp`](https://docs.rs/candle-core/0.11.0/candle_core/trait.IndexOp.html) ajoute `i`, qui prend un indice, un intervalle, ou un tuple de ceux-ci, un par dimension : [lignes 91-109](https://github.com/spareilleux/learn/blob/c45b150/code/candle/course/examples/l02_tensors.rs#L91-L109).

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

- Un nombre retire sa dimension : `m.i(1)` est la ligne 1, de forme `(3)`. Un intervalle la garde : `m.i((.., 1..))` a toujours deux dimensions. [`indexer.rs`, lignes 27-61](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/indexer.rs#L27-L61) transforme les deux en appels à `narrow`.
- `index_select` choisit des lignes ou des colonnes entières d'après un tenseur d'indices `U32` ou `I64`, répétitions comprises. Une table d'embeddings, c'est exactement cela (leçon 5).
- `gather` choisit un élément par ligne : pour la ligne 0 l'élément de la colonne 2, pour la ligne 1 l'élément de la colonne 0. Une perte de classification s'en sert pour prendre le score de la bonne classe.
- `to_scalar`, `to_vec1`, `to_vec2` et `to_vec3` copient les valeurs vers des nombres et des vecteurs Rust, et vérifient à la fois le rang et le type.

Il n'y a pas d'indexation avec `[]`, parce que le trait `Index` de Rust doit renvoyer une référence vers quelque chose qui existe déjà, et une tranche de tenseur est un nouveau tenseur :

```text
error[E0608]: cannot index into a value of type `candle_core::Tensor`
 --> course\examples\x_index.rs:5:18
  |
5 |     let first = m[0];
  |                  ^^^
```

## Réductions et autres opérations

[Lignes 112-137](https://github.com/spareilleux/learn/blob/c45b150/code/candle/course/examples/l02_tensors.rs#L112-L137) :

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

- Une réduction le long d'une dimension la retire ; la version `_keepdim` la laisse avec une taille 1, qui est la forme dont tu as besoin pour réappliquer le résultat par broadcasting sur l'original. `sum_all` et `mean_all` réduisent à un scalaire.
- `argmax` renvoie des indices `U32`, et les comparaisons comme `ge` renvoient un masque `U8` de 0 et de 1.
- `cat` concatène des tenseurs le long d'une dimension existante, `stack` le long d'une nouvelle.
- Le softmax, qui transforme des scores en probabilités, n'est pas une méthode de `Tensor` (`candle-nn` en a un, leçon 5). Écrit à la main, il montre le schéma que tout modèle utilise : réduire avec `_keepdim`, puis revenir par broadcasting.

```rust
fn softmax(x: &Tensor) -> candle::Result<Tensor> {
    let shifted = x.broadcast_sub(&x.max_keepdim(D::Minus1)?)?;
    let e = shifted.exp()?;
    e.broadcast_div(&e.sum_keepdim(D::Minus1)?)
}
```

Soustraire d'abord le maximum ne change rien au résultat, puisque le facteur `exp(-max)` se simplifie, et empêche `exp` de déborder sur de grands scores.

## Erreurs à l'exécution

Les formes et les types sont des valeurs d'exécution, donc la plupart des erreurs reviennent sous forme de `Err`. [`examples/l02_errors.rs`](https://github.com/spareilleux/learn/blob/c45b150/code/candle/course/examples/l02_errors.rs#L12-L53) en provoque une de chaque sorte et affiche son message :

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

La plupart des messages nomment l'opération et les deux formes, ce qui est ce dont tu as besoin. Quelques-uns demandent une traduction :

- `m.squeeze(0)` réussit et renvoie `m` inchangé, parce que la dimension 0 a une taille 2, pas 1. PyTorch fait de même ([`tensor.rs`, ligne 2567](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/tensor.rs#L2566-L2568)) ; une vérification de forme de ton côté est le moyen de l'attraper.
- Un indice au-delà de la fin, `m.i(2)`, est signalé comme le `narrow` qu'il devient.
- `m.i((0, 0, 0))` a un indice de trop. Les deux premiers indices sélectionnent un scalaire, et le troisième échoue dessus : "dimension index 0 out of range for shape []" décrit cette dernière étape, pas ton erreur.
- `row.to_vec1::<f64>()` ne convertit pas : lire les valeurs exige le type exact, donc appelle d'abord `to_dtype`.

`check.sh` exécute cet exemple avec le même environnement que ton shell. Avec `RUST_BACKTRACE=1`, chacune de ces erreurs porte aussi une backtrace, parce que Candle en capture une quand il crée une erreur ([`error.rs`, lignes 263-273](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/error.rs#L263-L273)). Cela aide à trouver d'où vient une erreur de forme dans un gros modèle.

### Deux paniques

Deux opérations de cette liste ne renvoient pas d'erreur ; elles paniquent, et arrêteraient le thread d'un serveur. L'exemple rattrape la panique avec une fonction utilitaire, [`caught`](https://github.com/spareilleux/learn/blob/c45b150/code/candle/course/src/lib.rs#L30-L49), pour afficher son message.

**`sqrt` sur un tenseur entier.** Les opérations unaires sont générées par une macro dont les branches entières sont `todo!("no unary function for u32")` ([`op.rs`, lignes 490-493](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/op.rs#L490-L493)). `todo!` panique avec "not yet implemented". Le même code est sur `main` aujourd'hui. Convertis en type flottant avant d'appeler `sqrt`, `exp`, `log` ou les autres fonctions flottantes.

**Un tampon plus court que sa forme.** [Lignes 55-62](https://github.com/spareilleux/learn/blob/c45b150/code/candle/course/examples/l02_errors.rs#L55-L62) :

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

Cinq valeurs avec une forme de six éléments sont acceptées, et l'erreur n'apparaît que plus tard, sous forme de panique, dans la première opération qui lit le sixième élément. La documentation de `from_vec` dit que les nombres doivent correspondre, mais en 0.11.0 une forme sans trou saute la vérification : [`shape.rs`, lignes 474-478](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/shape.rs#L474-L478) ignore le nombre d'éléments. C'est l'[issue #3812](https://github.com/huggingface/candle/issues/3812), qui y rattache aussi une famille de résultats faux dans les masques d'attention par lots, corrigée sur `main` par la [pull request #3813](https://github.com/huggingface/candle/pull/3813) le 13 août 2026, après la sortie de 0.11.0. Jusqu'à la prochaine version, vérifie toi-même `data.len()` par rapport à la forme quand les données viennent de l'extérieur. Le backend CPU panique sur un indice de slice ; sur un GPU, l'issue signale des lectures au-delà du tampon.

### Graines

```text
== seeds
Device::Cpu.set_seed(42): error: cannot seed the CPU rng with set_seed
```

Le backend CPU tire `rand` et `randn` du générateur aléatoire du thread et refuse de lui donner une graine ([`cpu_backend/mod.rs`, lignes 3096-3108](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/cpu_backend/mod.rs#L3096-L3108)). Une exécution reproductible sur le CPU doit générer elle-même ses nombres aléatoires, avec un générateur à graine de la crate [`rand`](https://docs.rs/rand/0.9/rand/), et les passer à `Tensor::from_vec`. Cela compte pour la leçon 5, où les poids d'une couche commencent aléatoires.

## À retenir

- Un `Tensor` est un pointeur peu coûteux à cloner vers un tampon partagé, plus un layout ; les opérations renvoient de nouveaux tenseurs.
- Les formes sont des tuples, avec au plus un trou `()`. `D::Minus1` compte depuis la fin. Rust attrape les littéraux de tableaux irréguliers, et rien d'autre sur les formes.
- Les types d'éléments ne se convertissent jamais en silence. Flottant vers entier tronque et ramène aux bornes ; `F16` divise la mémoire par deux et arrondit.
- `+`, `-`, `*`, `/` entre tenseurs exigent des formes égales. Le broadcasting, c'est `broadcast_add` et ses semblables ; un nombre à droite passe par `affine`.
- `i` indexe avec des nombres et des intervalles ; `index_select` et `gather` indexent avec des tenseurs.
- Les erreurs sont des valeurs aux messages utiles. En 0.11.0, les fonctions flottantes sur des tenseurs entiers paniquent, et `from_vec` ne vérifie pas le nombre d'éléments ; le générateur du CPU ne peut pas recevoir de graine.

## Exercices

Les solutions sont dans [`examples/l02_exercises.rs`](https://github.com/spareilleux/learn/blob/c45b150/code/candle/course/examples/l02_exercises.rs), et leur sortie dans `expected/l02_exercises.txt`.

1. Avec trois points `p` de forme `(3, 2)` et deux points `q` de forme `(2, 2)`, calcule par broadcasting la matrice `(3, 2)` des distances au carré entre chaque point de `p` et chaque point de `q`, puis l'indice du point de `q` le plus proche de chaque point de `p`. Calcule la même matrice d'une seconde façon, sans tenseur à trois dimensions.

<details>
<summary>Solution</summary>

[Lignes 10-23](https://github.com/spareilleux/learn/blob/c45b150/code/candle/course/examples/l02_exercises.rs#L10-L23) :

```rust
let p = Tensor::new(&[[0f32, 0.], [3., 4.], [1., 1.]], &dev)?; // (3, 2)
let q = Tensor::new(&[[0f32, 0.], [6., 8.]], &dev)?; // (2, 2)
// (3, 1, 2) - (1, 2, 2) s'étend par broadcasting en (3, 2, 2) : un vecteur de différence par paire
let diff = p.unsqueeze(1)?.broadcast_sub(&q.unsqueeze(0)?)?;
let d2 = diff.sqr()?.sum(D::Minus1)?;
// Point de q le plus proche de chaque point de p
show("nearest", &d2.argmin(1)?, 0)?;
// La même chose sans le tenseur à 3 dimensions : |p|^2 + |q|^2 - 2 p.q
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

Le point `(3, 4)` est à la même distance, 25, des deux points de `q` ; `argmin` renvoie le premier indice en cas d'égalité. La première version construit un tenseur `(3, 2, 2)`, qui pour mille points de chaque côté et 768 dimensions ferait trois gigaoctets de flottants ; la seconde ne construit que des matrices `(3, 2)`, et c'est ainsi que s'écrit la recherche des plus proches voisins sur des embeddings (leçon 7, et le [cours sur l'IA de GA](../../ga-ai/03-index-and-search/)).

</details>

2. Un modèle donne des scores pour 3 classes à 4 exemples, dans un tenseur `(4, 3)`, et les bonnes classes sont `[1, 0, 1, 1]`. Calcule l'exactitude, la part des exemples dont le score le plus élevé est la bonne classe, en `f32`.

<details>
<summary>Solution</summary>

[Lignes 26-44](https://github.com/spareilleux/learn/blob/c45b150/code/candle/course/examples/l02_exercises.rs#L26-L44) :

```rust
let labels = Tensor::new(&[1u32, 0, 1, 1], &dev)?;
let predicted = scores.argmax(D::Minus1)?;
let correct = predicted.eq(&labels)?; // U8 : 1 là où c'est égal
let accuracy = correct.to_dtype(DType::F32)?.mean_all()?.to_scalar::<f32>()?;
```

```text
== exercise 2: accuracy of scores against labels
predicted: shape [4], U32, [1, 0, 2, 0]
correct: shape [4], U8, [1, 1, 0, 0]
accuracy 0.5
```

`argmax` donne du `U32`, donc les étiquettes doivent aussi être en `U32`, sinon `eq` échoue sur un type incompatible. La moyenne d'un masque `U8` serait une moyenne entière ; convertir d'abord en `F32` donne 0.5. Les scores du dernier exemple, 3.0 et 2.9, sont proches : l'exactitude ignore de combien une prédiction est juste ou fausse, et c'est pourquoi les modèles sont entraînés sur une perte ([cours IX, leçon 3](../../machine-learning-ix/03-classification/)).

</details>

## Sources

- Candle à `31f35b1` : [`tensor.rs`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/tensor.rs), [`shape.rs`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/shape.rs), [`indexer.rs`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/indexer.rs), [`dtype.rs`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/dtype.rs), [`error.rs`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/error.rs)
- [`candle_core::Tensor`](https://docs.rs/candle-core/0.11.0/candle_core/struct.Tensor.html) et [`candle_core::Error`](https://docs.rs/candle-core/0.11.0/candle_core/error/enum.Error.html) sur docs.rs
- [Issue #3812 de Candle](https://github.com/huggingface/candle/issues/3812) et [pull request #3813](https://github.com/huggingface/candle/pull/3813)
- [Le broadcasting de NumPy](https://numpy.org/doc/stable/user/basics.broadcasting.html), la règle que suit Candle
- [La référence Rust : casts numériques](https://doc.rust-lang.org/reference/expressions/operator-expr.html#numeric-cast)
