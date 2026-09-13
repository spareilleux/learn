---
title: 2. Types, mutabilité et expressions
description: let et mut, types numériques, aucune conversion implicite, et tout est expression.
sidebar:
  order: 2
---

Exemple complet : [`examples/l02_types.rs`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/examples/l02_types.rs) — exécutez-le avec `cargo run --example l02_types`.

## Immuable par défaut

```rust
let answer = 42;            // inféré en i32, ne peut pas changer
let mut counter: u32 = 0;   // explicitement mutable
counter += 1;
```

En termes C#, chaque `let` est comme une variable locale qu'on ne peut jamais réaffecter ; en Java, comme `final var`. On **choisit** la mutabilité avec `mut` :

```rust
let count = 0;
count += 1;
```

```text
error[E0384]: cannot assign twice to immutable variable `count`
 --> e_immutable.rs:3:5
  |
2 |     let count = 0;
  |         ----- first assignment to `count`
3 |     count += 1;
  |     ^^^^^^^^^^ cannot assign twice to immutable variable
  |
help: consider making this binding mutable
  |
2 |     let mut count = 0;
  |         +++
```

:::tip[Lisez l'erreur en entier]
Les erreurs de Rust contiennent généralement la correction (`help: consider making this binding mutable`). Prenez l'habitude de les lire jusqu'au bout — et `rustc --explain E0384` en donne une explication complète.
:::

## Masquage (shadowing)

On peut déclarer une nouvelle variable portant le même nom, même avec un type différent. Pratique pour « analyser puis remplacer » :

```rust
let input = "  7 ";
let input: i32 = input.trim().parse().expect("not a number");
println!("input + 1 = {}", input + 1); // input + 1 = 8
```

Ce n'est pas une mutation : le premier `input` (un `&str`) existe toujours, il est simplement masqué. C# et Java interdisent de redéclarer une variable locale dans la même portée.

## Types scalaires

| Rust | C# | Java | Remarques |
|---|---|---|---|
| `i8` / `u8` | `sbyte` / `byte` | `byte` (signé) / — | Java n'a pas d'entiers non signés |
| `i16` / `u16` | `short` / `ushort` | `short` / — | |
| `i32` / `u32` | `int` / `uint` | `int` / — | `i32` est l'entier par défaut |
| `i64` / `u64` | `long` / `ulong` | `long` / — | |
| `i128` / `u128` | `Int128` / `UInt128` | — | |
| `isize` / `usize` | `nint` / `nuint` | — | de la taille d'un pointeur ; utilisés pour les index et les longueurs |
| `f32` / `f64` | `float` / `double` | `float` / `double` | `f64` est le flottant par défaut |
| `bool` | `bool` | `boolean` | |
| `char` | `Rune` | point de code `int` | **4 octets**, une valeur scalaire Unicode — *pas* une unité UTF-16 comme le `char` de C#/Java |

```rust
let note = '♪';
println!("{note} is {} bytes in UTF-8, size_of::<char>() = {}", note.len_utf8(), std::mem::size_of::<char>());
// ♪ is 3 bytes in UTF-8, size_of::<char>() = 4
```

## Aucune conversion implicite

C# et Java élargissent silencieusement un `int` en `long`. Rust ne convertit jamais les nombres à votre place :

```rust
let small: i32 = 10;
let big: i64 = 20;
let total = small + big;
```

```text
error[E0308]: mismatched types
 --> e_mismatch.rs:4:25
  |
4 |     let total = small + big;
  |                         ^^^ expected `i32`, found `i64`
```

Convertissez explicitement avec `as` (ou `i64::from(small)`, qui n'existe que pour les conversions sans perte) :

```rust
let total = small as i64 + big; // 30
```

## Le dépassement est un bug, pas une fonctionnalité

| | C# | Java | Rust, build debug | Rust, build release |
|---|---|---|---|---|
| `255u8 + 1` | reboucle (sauf avec `checked`) | reboucle | **panique** | reboucle |

Dans un build debug, Rust arrête le programme :

```text
thread 'main' panicked at e_overflow.rs:3:16:
attempt to add with overflow
```

Quand le rebouclage ou l'échec est le comportement voulu, dites-le explicitement :

```rust
let max = u8::MAX;
println!("checked: {:?}, wrapping: {}", max.checked_add(1), max.wrapping_add(1));
// checked: None, wrapping: 0
```

## Tuples et tableaux

```rust
let point: (f64, f64) = (1.5, -2.0);
let (x, y) = point;              // déstructuration, comme la déconstruction de tuples en C#
let primes = [2, 3, 5, 7, 11];   // tableau de taille fixe : [i32; 5]
println!("x = {x}, y = {y}, first prime = {}, count = {}", primes[0], primes.len());
// x = 1.5, y = -2, first prime = 2, count = 5
```

Une liste extensible est un `Vec<T>` (comme `List<T>` / `ArrayList<T>`) — la leçon 8 traite des collections.

## Tout est expression

`if` renvoie une valeur, il n'y a donc pas d'opérateur ternaire :

```rust
let parity = if answer % 2 == 0 { "even" } else { "odd" };
```

Un bloc `{ … }` s'évalue à sa dernière expression — **sans** point-virgule :

```rust
let area = {
    let width = 3;
    let height = 4;
    width * height   // pas de `;` → c'est la valeur du bloc
};
```

Les fonctions fonctionnent de la même manière ; `return` n'est nécessaire que pour les sorties anticipées :

```rust
fn square(x: i32) -> i32 {
    x * x
}
```

:::caution[Le point-virgule compte]
Écrire `x * x;` transforme l'expression en instruction : la fonction renvoie alors `()` (le type unité, le `void` de Rust) et le compilateur signale une incompatibilité de types.
:::

## Boucles

```rust
// loop + break avec une valeur
let mut n = 1;
let first_power_over_100 = loop {
    n *= 2;
    if n > 100 {
        break n;
    }
};                                   // 128

// for sur des intervalles : 0..3 exclut la borne de fin, 1..=10 l'inclut
for i in 0..3 {
    print!("{i} ");                  // 0 1 2
}
let sum: i32 = (1..=10).sum();       // 55
```

Il n'y a pas de `for (int i = 0; i < n; i++)` à la C : utilisez un intervalle. `while condition { … }` existe aussi.

## À retenir

- `let` est immuable ; ajoutez `mut` seulement quand vous en avez besoin.
- Les types numériques sont explicites, les conversions sont explicites, le dépassement panique en debug.
- `char` est une valeur scalaire Unicode (4 octets), pas de l'UTF-16.
- `if`, les blocs, `loop` et les fonctions sont des expressions ; la dernière expression sans `;` en est la valeur.

## Exercices

1. Écrivez une fonction `clamp_percent(value: i32) -> u8` qui renvoie `0` pour les valeurs négatives, `100` pour les valeurs supérieures à 100, et la valeur elle-même sinon — en utilisant `if` comme expression.

<details>
<summary>Solution</summary>

```rust
fn clamp_percent(value: i32) -> u8 {
    if value < 0 {
        0
    } else if value > 100 {
        100
    } else {
        value as u8
    }
}
```

Le `as u8` est sûr ici, car on sait que la valeur est comprise dans `0..=100`. Rust fournit aussi `value.clamp(0, 100) as u8`.

</details>

2. Pourquoi cette fonction ne compile-t-elle pas, et quelle est la correction d'un seul caractère ?

```rust
fn double(x: i32) -> i32 {
    x * 2;
}
```

<details>
<summary>Solution</summary>

Le point-virgule final transforme `x * 2` en instruction, si bien que le corps s'évalue à `()` au lieu de `i32` (erreur `E0308: mismatched types`). Supprimez le `;`.

</details>

3. En C#, `byte b = 255; b++;` donne `0`. Que se passe-t-il en Rust avec `let mut b: u8 = 255; b += 1;` ?

<details>
<summary>Solution</summary>

Dans un build debug, le programme panique avec `attempt to add with overflow`. Dans un build release, la valeur reboucle à `0`. Si c'est le rebouclage que vous voulez, écrivez `b = b.wrapping_add(1);` ; si vous voulez le détecter, utilisez `b.checked_add(1)`, qui renvoie un `Option<u8>`.

</details>

## Sources

- [The Book, ch. 3 — Common Programming Concepts](https://doc.rust-lang.org/book/ch03-00-common-programming-concepts.html)
- [The Rust Reference — Integer overflow](https://doc.rust-lang.org/reference/expressions/operator-expr.html#overflow)
- [`char` — bibliothèque standard](https://doc.rust-lang.org/std/primitive.char.html)
