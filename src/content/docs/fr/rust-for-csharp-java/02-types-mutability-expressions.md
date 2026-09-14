---
title: 2. Types, mutabilité et expressions
description: let et mut, types numériques, aucune conversion implicite, et tout est expression.
sidebar:
  order: 2
---

Exemple complet : [`examples/l02_types.rs`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/examples/l02_types.rs) — exécutez-le avec `cargo run --example l02_types`.

## Immuable par défaut

Extrait de [`examples/l02_types.rs`, lignes 3-5](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l02_types.rs#L3-L5) :

```rust
let answer = 42;            // inféré en i32, ne peut pas changer
let mut counter: u32 = 0;   // explicitement mutable
counter += 1;
```

En termes C#, chaque `let` est comme une variable locale qu'on ne peut jamais réaffecter ; en Java, comme [`final var`](https://openjdk.org/jeps/286). On **choisit** la mutabilité avec `mut` ([`src/lib.rs`, lignes 10-11](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L10-L11)) :

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
Les erreurs de Rust contiennent généralement la correction (`help: consider making this binding mutable`). Prenez l'habitude de les lire jusqu'au bout — et [`rustc --explain E0384`](https://doc.rust-lang.org/rustc/command-line-arguments.html#--explain-provide-a-detailed-explanation-of-an-error-message) en donne une explication complète.
:::

## Masquage (shadowing)

On peut déclarer une nouvelle variable portant le même nom, même avec un type différent. Pratique pour « analyser puis remplacer » ([lignes 9-11](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l02_types.rs#L9-L11)) :

```rust
let input = "  7 ";
let input: i32 = input.trim().parse().expect("not a number");
println!("input + 1 = {}", input + 1); // input + 1 = 8
```

Ce n'est pas une mutation : le premier `input` (un [`&str`](https://doc.rust-lang.org/std/primitive.str.html)) existe toujours, il est simplement masqué. C# et Java interdisent de redéclarer une variable locale dans la même portée.

## Types scalaires

| Rust | C# | Java | Remarques |
|---|---|---|---|
| `i8` / `u8` | `sbyte` / `byte` | `byte` (signé) / — | Java n'a pas d'entiers non signés |
| `i16` / `u16` | `short` / `ushort` | `short` / — | |
| `i32` / `u32` | `int` / `uint` | `int` / — | `i32` est l'entier par défaut |
| `i64` / `u64` | `long` / `ulong` | `long` / — | |
| `i128` / `u128` | [`Int128`](https://learn.microsoft.com/dotnet/api/system.int128) / `UInt128` | — | |
| `isize` / `usize` | [`nint` / `nuint`](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/integral-numeric-types#native-sized-integers) | — | de la taille d'un pointeur ; utilisés pour les index et les longueurs |
| `f32` / `f64` | `float` / `double` | `float` / `double` | `f64` est le flottant par défaut |
| `bool` | `bool` | `boolean` | |
| `char` | [`Rune`](https://learn.microsoft.com/dotnet/api/system.text.rune) | point de code `int` | **4 octets**, une valeur scalaire Unicode — *pas* une unité UTF-16 comme le `char` de C#/Java |

Extrait de [`examples/l02_types.rs`, lignes 28-33](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l02_types.rs#L28-L33) :

```rust
let note = '♪';
println!("{note} is {} bytes in UTF-8, size_of::<char>() = {}", note.len_utf8(), std::mem::size_of::<char>());
// ♪ is 3 bytes in UTF-8, size_of::<char>() = 4
```

## Aucune conversion implicite

C# et Java élargissent silencieusement un `int` en `long`. Rust ne convertit jamais les nombres à votre place ([`src/lib.rs`, lignes 18-20](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L18-L20)) :

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

Convertissez explicitement avec [`as`](https://doc.rust-lang.org/reference/expressions/operator-expr.html#type-cast-expressions) (ou [`i64::from(small)`](https://doc.rust-lang.org/std/convert/trait.From.html), qui n'existe que pour les conversions sans perte) ([ligne 16](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l02_types.rs#L16)) :

```rust
let total = small as i64 + big; // 30
```

## Le dépassement est un bug, pas une fonctionnalité

| | C# | Java | Rust, build debug | Rust, build release |
|---|---|---|---|---|
| `255u8 + 1` | reboucle (sauf avec [`checked`](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/checked-and-unchecked)) | reboucle | **[panique](https://doc.rust-lang.org/book/ch09-01-unrecoverable-errors-with-panic.html)** | reboucle |

Dans un build debug, Rust arrête le programme :

```text
thread 'main' panicked at e_overflow.rs:3:16:
attempt to add with overflow
```

Quand le rebouclage ou l'échec est le comportement voulu, dites-le explicitement ([lignes 20-25](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l02_types.rs#L20-L25)) :

```rust
let max = u8::MAX;
println!("checked: {:?}, wrapping: {}", max.checked_add(1), max.wrapping_add(1));
// checked: None, wrapping: 0
```

## Tuples et tableaux

Extrait de [`examples/l02_types.rs`, lignes 36-43](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l02_types.rs#L36-L43) :

```rust
let point: (f64, f64) = (1.5, -2.0);
let (x, y) = point;              // déstructuration, comme la déconstruction de tuples en C#
let primes = [2, 3, 5, 7, 11];   // tableau de taille fixe : [i32; 5]
println!("x = {x}, y = {y}, first prime = {}, count = {}", primes[0], primes.len());
// x = 1.5, y = -2, first prime = 2, count = 5
```

Une liste extensible est un [`Vec<T>`](https://doc.rust-lang.org/std/vec/struct.Vec.html) (comme [`List<T>`](https://learn.microsoft.com/dotnet/api/system.collections.generic.list-1) / [`ArrayList<T>`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/ArrayList.html)) — la leçon 8 traite des collections.

## Tout est expression

`if` renvoie une valeur, il n'y a donc pas d'opérateur ternaire ([ligne 46](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l02_types.rs#L46)) :

```rust
let parity = if answer % 2 == 0 { "even" } else { "odd" };
```

Un bloc `{ … }` s'évalue à sa dernière expression — **sans** point-virgule ([lignes 50-54](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l02_types.rs#L50-L54)) :

```rust
let area = {
    let width = 3;
    let height = 4;
    width * height   // pas de `;` → c'est la valeur du bloc
};
```

Les fonctions fonctionnent de la même manière ; `return` n'est nécessaire que pour les sorties anticipées ([lignes 78-80](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l02_types.rs#L78-L80)) :

```rust
fn square(x: i32) -> i32 {
    x * x
}
```

:::caution[Le point-virgule compte]
Écrire `x * x;` transforme l'expression en instruction : la fonction renvoie alors [`()`](https://doc.rust-lang.org/std/primitive.unit.html) (le type unité, le `void` de Rust) et le compilateur signale une incompatibilité de types.
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

Extrait de [`src/lib.rs`, lignes 26-34](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L26-L34) :

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

Extrait de [`src/lib.rs`, lignes 44-46](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L44-L46) :

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

Dans un build debug, le programme panique avec `attempt to add with overflow`. Dans un build release, la valeur reboucle à `0`. Si c'est le rebouclage que vous voulez, écrivez `b = b.wrapping_add(1);` ; si vous voulez le détecter, utilisez [`b.checked_add(1)`](https://doc.rust-lang.org/std/primitive.u8.html#method.checked_add), qui renvoie un [`Option<u8>`](https://doc.rust-lang.org/std/option/enum.Option.html).

</details>

## Sources

- [The Book, ch. 3 — Common Programming Concepts](https://doc.rust-lang.org/book/ch03-00-common-programming-concepts.html)
- [The Rust Reference — Integer overflow](https://doc.rust-lang.org/reference/expressions/operator-expr.html#overflow)
- [`char` — bibliothèque standard](https://doc.rust-lang.org/std/primitive.char.html)
