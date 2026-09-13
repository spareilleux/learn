---
title: 4. Emprunts et chaînes
description: Références partagées et mutables, règles d'emprunt, slices, et String contre &str.
sidebar:
  order: 4
---

Exemple complet : [`examples/l04_borrowing.rs`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/examples/l04_borrowing.rs) — `cargo run --example l04_borrowing`.

## Emprunter au lieu de déplacer

La [leçon 3](../03-ownership-and-moves/) s'est terminée sur une fonction qui « volait » son argument. La plupart du temps, on veut seulement *consulter* une valeur : passez une **référence** avec `&`.

```rust
fn word_count(text: &str) -> usize {
    text.split_whitespace().count()
}

let title = String::from("the rust programming language");
println!("{} words", word_count(&title));   // 4 words
println!("{title}");                        // title est toujours utilisable
```

Une référence **emprunte** la valeur : le propriétaire conserve la possession, et l'emprunt doit prendre fin avant que le propriétaire disparaisse.

## Deux sortes de références

| | Syntaxe | Combien à la fois | Peut modifier |
|---|---|---|---|
| Référence partagée | `&T` | autant qu'on veut | non |
| Référence mutable | `&mut T` | exactement une, et aucune partagée | oui |

```rust
fn shout(text: &mut String) {
    text.make_ascii_uppercase();
    text.push('!');
}

let mut message = String::from("hello");
shout(&mut message);
println!("{message}");   // HELLO!
```

L'appelant écrit `&mut` au point d'appel — comme le mot-clé `ref` de C#, la mutation est visible là où elle se produit. Java n'a pas d'équivalent : toute méthode qui détient une référence peut modifier l'objet.

## La règle : partagé XOR mutable

À tout moment, on peut avoir **soit** plusieurs lecteurs, **soit** un seul écrivain — jamais les deux. Le compilateur le vérifie ; c'est ce qu'on appelle le **borrow checker** (vérificateur d'emprunts).

```rust
let mut names = vec![String::from("Ada")];
let first = &names[0];
names.push(String::from("Grace"));
println!("{first}");
```

```text
error[E0502]: cannot borrow `names` as mutable because it is also borrowed as immutable
 --> e_borrow_mut.rs:4:5
  |
3 |     let first = &names[0];
  |                  ----- immutable borrow occurs here
4 |     names.push(String::from("Grace"));
  |     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ mutable borrow occurs here
5 |     println!("{first}");
  |                ----- immutable borrow later used here
```

Ce n'est pas de la pédanterie. `push` peut réallouer le buffer du vecteur, ce qui laisserait `first` pointer vers de la mémoire libérée. En C#/Java, le GC maintient l'ancien objet en vie, donc ce bug précis ne provoque pas de plantage — mais la *même règle* attrape un bug que vous connaissez bien.

## Vous avez déjà rencontré ce bug

```java
// Java
for (Integer n : numbers) {
    numbers.add(n * 2);   // ConcurrentModificationException à l'exécution
}
```

```csharp
// C#
foreach (var n in numbers) {
    numbers.Add(n * 2);   // InvalidOperationException: Collection was modified
}
```

En Rust, il ne passe pas le compilateur :

```rust
let mut numbers = vec![1, 2, 3];
for n in &numbers {
    numbers.push(n * 2);
}
```

```text
error[E0502]: cannot borrow `numbers` as mutable because it is also borrowed as immutable
 --> e_iter_mutate.rs:4:9
  |
3 |     for n in &numbers {
  |              --------
  |              |
  |              immutable borrow occurs here
  |              immutable borrow later used here
4 |         numbers.push(n * 2);
  |         ^^^^^^^^^^^^^^^^^^^ mutable borrow occurs here
```

La correction est la même qu'en C#/Java — finir de lire, puis écrire :

```rust
let mut numbers = vec![1, 2, 3];
let doubled: Vec<i32> = numbers.iter().map(|n| n * 2).collect();
numbers.extend(doubled);
println!("{numbers:?}");   // [1, 2, 3, 2, 4, 6]
```

## Pas de références pendantes

Une référence ne peut jamais survivre à ce vers quoi elle pointe :

```rust
fn longest_line() -> &str {
    let text = String::from("line one\nline two");
    text.lines().next().unwrap()
}
```

```text
error[E0106]: missing lifetime specifier
 --> e_dangling.rs:1:22
  |
1 | fn longest_line() -> &str {
  |                      ^ expected named lifetime parameter
  |
  = help: this function's return type contains a borrowed value, but there is no value for it to be borrowed from
…
help: instead, you are more likely to want to return an owned value
  |
1 - fn longest_line() -> &str {
1 + fn longest_line() -> String {
```

`text` est libéré au retour de la fonction, donc une référence vers son contenu serait pendante. Renvoyez plutôt un `String` possédé. (Les durées de vie — la syntaxe `'a` que mentionne l'erreur — ont leur propre leçon, la 9.)

## Slices

Une **slice** emprunte une portion contiguë d'une collection sans la copier :

```rust
let mut scores = vec![90, 72, 85];
scores.push(60);
let top_two = &scores[..2];      // &[i32]
println!("top two: {top_two:?}");  // top two: [90, 72]
```

Pensez à `Span<T>` / `ReadOnlySpan<T>` en C#, ou à `List.subList` en Java — mais vérifiée à la compilation, de sorte qu'elle ne peut jamais survivre au vecteur.

## `String` contre `&str`

C'est la pierre d'achoppement la plus fréquente, et les slices l'expliquent :

| | `String` | `&str` |
|---|---|---|
| Ce que c'est | un buffer UTF-8 possédé et extensible | une slice empruntée de texte UTF-8 |
| Où vivent les octets | sur le tas, possédés par cette valeur | n'importe où : un `String`, le binaire (littéraux), … |
| Peut grandir | oui (`push_str`, `push`) | non |
| Analogie C# | un `StringBuilder` que vous possédez | `ReadOnlySpan<char>` / un `string` que vous ne possédez pas |
| Usage typique | champs de structs, valeurs de retour | paramètres de fonctions |

- Les littéraux de chaîne comme `"hello"` sont des `&str` (`&'static str` : ils vivent dans le binaire).
- `&String` se convertit automatiquement en `&str`, donc **les paramètres devraient généralement être des `&str`** — ils acceptent alors les deux :

```rust
fn first_word(text: &str) -> &str {
    text.split_whitespace().next().unwrap_or("")
}

println!("{}", word_count("a literal works too"));   // 4
println!("first word: {}", first_word(&title));      // first word: the
```

## Les chaînes sont de l'UTF-8, pas des tableaux de caractères

En C# et en Java, `s[0]` / `s.charAt(0)` renvoie une unité UTF-16. Rust refuse d'indexer une chaîne par position :

```rust
let word = String::from("cafe");
let c = word[0];
```

```text
error[E0277]: the type `str` cannot be indexed by `{integer}`
 --> e_index_str.rs:3:18
  |
3 |     let c = word[0];
  |                  ^ string indices are ranges of `usize`
  |
  = help: the trait `SliceIndex<str>` is not implemented for `{integer}`
  = note: you can use `.chars().nth()` or `.bytes().nth()`
```

Comme les caractères occupent de 1 à 4 octets en UTF-8, « le n-ième caractère » est un parcours en O(n), et Rust rend cela explicite :

```rust
let word = "café";
println!("{} bytes, {} chars, first 3 bytes: {}", word.len(), word.chars().count(), &word[..3]);
// 5 bytes, 4 chars, first 3 bytes: caf
```

Découper par intervalle d'octets fonctionne, mais panique si l'on coupe au milieu d'un caractère :

```text
thread 'main' panicked at e_slice_boundary.rs:3:25:
byte index 4 is not a char boundary; it is inside 'é' (bytes 3..5) of `café`
```

## Construire des chaînes

```rust
let mut log = String::new();
for (i, s) in ["alpha", "beta"].iter().enumerate() {
    log.push_str(&format!("{i}:{s} "));
}
println!("{}", log.trim_end());   // 0:alpha 1:beta
```

`format!` fonctionne comme `string.Format` / `String.format` (et comme l'interpolation C# avec `{name}` à l'intérieur du littéral).

## À retenir

- `&T` emprunte en lecture, `&mut T` emprunte en écriture ; le propriétaire conserve la possession.
- Plusieurs emprunts partagés **ou** un seul emprunt mutable — la règle qui attrape aussi « collection modifiée pendant l'itération » à la compilation.
- Les références ne peuvent jamais être pendantes ; renvoyez des valeurs possédées quand les données sont créées dans une fonction.
- Prenez des `&str` en paramètre, stockez des `String` dans les structs ; les chaînes sont en UTF-8, donc itérez avec `.chars()` au lieu d'indexer.

## Exercices

1. Corrigez la signature pour que ceci compile sans cloner, et expliquez pourquoi votre version est plus souple :

```rust
fn is_shouting(text: String) -> bool {
    text.chars().any(|c| c.is_alphabetic()) && text == text.to_uppercase()
}

let msg = String::from("HELLO");
if is_shouting(msg) { println!("{msg} is shouting"); }
```

<details>
<summary>Solution</summary>

```rust
fn is_shouting(text: &str) -> bool {
    text.chars().any(|c| c.is_alphabetic()) && text == text.to_uppercase()
}

let msg = String::from("HELLO");
if is_shouting(&msg) { println!("{msg} is shouting"); }
```

L'emprunt laisse `msg` possédé par l'appelant, et `&str` accepte aussi les littéraux (`is_shouting("hi")`) et les slices.

</details>

2. Ceci compile en C# et s'exécute sans problème. Pourquoi Rust rejette-t-il l'équivalent, et comment le corriger ?

```csharp
var names = new List<string> { "Ada" };
var first = names[0];
names.Add("Grace");
Console.WriteLine(first);
```

<details>
<summary>Solution</summary>

En C#, `first` contient une référence vers l'objet chaîne, que le GC maintient en vie même si la liste est réallouée. En Rust, `&names[0]` pointe *à l'intérieur* du buffer du vecteur, que `push` peut réallouer ; le borrow checker interdit donc la mutation tant que l'emprunt est actif (`E0502`). Corrections : utiliser `first` avant le `push`, ou prendre une copie possédée avec `let first = names[0].clone();`.

</details>

3. Écrivez `fn initials(full_name: &str) -> String` qui renvoie `"A.L."` pour `"Ada Lovelace"`, en gérant correctement les noms qui commencent par une lettre non ASCII comme `"Émile Zola"`.

<details>
<summary>Solution</summary>

```rust
fn initials(full_name: &str) -> String {
    full_name
        .split_whitespace()
        .filter_map(|word| word.chars().next())
        .map(|c| format!("{c}."))
        .collect()
}

assert_eq!(initials("Ada Lovelace"), "A.L.");
assert_eq!(initials("Émile Zola"), "É.Z.");
```

`chars().next()` prend le premier *caractère*, et non le premier octet, donc `É` (2 octets en UTF-8) est géré correctement.

</details>

## Sources

- [The Book, ch. 4.2 — References and Borrowing](https://doc.rust-lang.org/book/ch04-02-references-and-borrowing.html)
- [The Book, ch. 4.3 — The Slice Type](https://doc.rust-lang.org/book/ch04-03-slices.html)
- [The Book, ch. 8.2 — Storing UTF-8 Encoded Text with Strings](https://doc.rust-lang.org/book/ch08-02-strings.html)
