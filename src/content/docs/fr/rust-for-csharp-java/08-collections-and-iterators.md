---
title: 8. Collections et itérateurs
description: Vec, HashMap et consorts, et les chaînes d'itérateurs qui remplacent LINQ et les Streams Java.
sidebar:
  order: 8
---

Exemple complet : [`examples/l08_collections_iterators.rs`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/examples/l08_collections_iterators.rs) — `cargo run --example l08_collections_iterators`.

## Les collections que vous connaissez déjà

| Rust (`std::collections`) | C# | Java |
|---|---|---|
| [`Vec<T>`](https://doc.rust-lang.org/std/vec/struct.Vec.html) | `List<T>` | `ArrayList<T>` |
| [`VecDeque<T>`](https://doc.rust-lang.org/std/collections/struct.VecDeque.html) | `Queue<T>` / `LinkedList<T>` | `ArrayDeque<T>` |
| [`HashMap<K, V>`](https://doc.rust-lang.org/std/collections/struct.HashMap.html) | `Dictionary<K, V>` | `HashMap<K, V>` |
| [`BTreeMap<K, V>`](https://doc.rust-lang.org/std/collections/struct.BTreeMap.html) | `SortedDictionary<K, V>` | `TreeMap<K, V>` |
| [`HashSet<T>`](https://doc.rust-lang.org/std/collections/struct.HashSet.html) | `HashSet<T>` | `HashSet<T>` |
| [`BTreeSet<T>`](https://doc.rust-lang.org/std/collections/struct.BTreeSet.html) | `SortedSet<T>` | `TreeSet<T>` |
| [`BinaryHeap<T>`](https://doc.rust-lang.org/std/collections/struct.BinaryHeap.html) | `PriorityQueue<T, P>` | `PriorityQueue<T>` |

`Vec` et `String` sont disponibles partout ; les autres nécessitent un `use std::collections::…`.

:::caution[Ordre d'un HashMap]
Itérer sur un `HashMap` produit les entrées dans un ordre non spécifié, qui peut changer d'une exécution à l'autre. Quand vous avez besoin d'une sortie triée, utilisez un `BTreeMap` — ou collectez dans un `BTreeMap` avant d'afficher, comme le fait l'exemple.
:::

## LINQ et Streams, traduits

L'exemple travaille sur une liste de commandes ([lignes 57-61](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l08_collections_iterators.rs#L57-L61)) :

```rust
let big_orders: Vec<&str> = orders
    .iter()
    .filter(|o| o.quantity >= 2)
    .map(|o| o.product)
    .collect();
// big orders: ["mouse", "monitor"]
```

| Rust | C# [LINQ](https://learn.microsoft.com/dotnet/csharp/linq/) | [Streams Java](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/stream/package-summary.html) |
|---|---|---|
| `.iter()` | (l'`IEnumerable` lui-même) | `.stream()` |
| `.filter(\|x\| …)` | `.Where(x => …)` | `.filter(x -> …)` |
| `.map(\|x\| …)` | `.Select(x => …)` | `.map(x -> …)` |
| `.flat_map(\|x\| …)` | `.SelectMany(x => …)` | `.flatMap(x -> …)` |
| `.collect::<Vec<_>>()` | `.ToList()` | `.toList()` |
| `.sum()` | `.Sum()` | `.mapToInt(…).sum()` |
| `.count()` | `.Count()` | `.count()` |
| `.any(…)` / `.all(…)` | `.Any(…)` / `.All(…)` | `.anyMatch(…)` / `.allMatch(…)` |
| `.find(…)` | `.FirstOrDefault(…)` | `.filter(…).findFirst()` |
| `.fold(init, \|acc, x\| …)` | `.Aggregate(init, …)` | `.reduce(init, …)` |
| `.take(n)` / `.skip(n)` | `.Take(n)` / `.Skip(n)` | `.limit(n)` / `.skip(n)` |
| `.zip(other)` | `.Zip(other)` | — |
| `.enumerate()` | `.Select((x, i) => …)` | — |
| `.min_by_key(…)` / `.max_by_key(…)` | `.MinBy(…)` / `.MaxBy(…)` | `.min(comparator)` |
| collecter dans un `HashSet` | `.Distinct()` | `.distinct()` |
| `vec.sort_by_key(…)` (sur le `Vec`) | `.OrderBy(…)` | `.sorted(comparator)` |

Extrait de [`examples/l08_collections_iterators.rs`, lignes 65-74](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l08_collections_iterators.rs#L65-L74) :

```rust
let revenue: f64 = orders.iter().map(|o| o.quantity as f64 * o.unit_price).sum();
let any_monitor = orders.iter().any(|o| o.product == "monitor");
let all_positive = orders.iter().all(|o| o.quantity > 0);
let first_mouse = orders.iter().find(|o| o.product == "mouse").map(|o| o.customer);
```

```text
revenue 562, any monitor true, all positive true, first mouse buyer Some("grace")
```

`find` renvoie un `Option` — il n'existe pas de `FirstOrDefault` qui renvoie `null`.

## Les itérateurs sont paresseux

Comme l'[exécution différée](https://learn.microsoft.com/dotnet/standard/linq/deferred-execution-lazy-evaluation) de LINQ et les opérations intermédiaires de Java, rien ne s'exécute tant que quelque chose ne **consomme** pas l'itérateur (`collect`, `sum`, `for`, `count`…). Le compilateur vous avertit si vous l'oubliez :

```rust
numbers.iter().map(|n| println!("{n}"));
```

```text
warning: unused `Map` that must be used
 --> e08_lazy.rs:3:5
  |
3 |     numbers.iter().map(|n| println!("{n}"));
  |     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  |
  = note: iterators are lazy and do nothing unless consumed
…
help: you might have meant to use `Iterator::for_each`
```

Cette paresse permet aussi aux itérateurs d'être infinis : voir l'exemple de Fibonacci plus bas.

## `collect` doit connaître le type cible

[`collect`](https://doc.rust-lang.org/std/iter/trait.Iterator.html#method.collect) peut construire un `Vec`, un `HashSet`, un `String`, un `HashMap`… vous devez donc indiquer lequel ([`src/lib.rs`, ligne 396](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L396)) :

```rust
let evens = (1..10).filter(|n| n % 2 == 0).collect();
```

```text
error[E0283]: type annotations needed
    --> e08_collect_type.rs:2:9
     |
   2 |     let evens = (1..10).filter(|n| n % 2 == 0).collect();
     |         ^^^^^                                  ------- type must be known at this point
     |
     = note: cannot satisfy `_: FromIterator<i32>`
…
help: consider giving `evens` an explicit type
     |
   2 |     let evens: Vec<_> = (1..10).filter(|n| n % 2 == 0).collect();
     |              ++++++++
```

Annotez la variable (`let evens: Vec<_> = …`) ou utilisez la syntaxe « turbofish » : `.collect::<Vec<_>>()`. Le `_` laisse le compilateur inférer le type des éléments.

## `iter`, `iter_mut`, `into_iter`

La possession (leçons 3 et 4) se manifeste dans la façon d'itérer :

| Méthode | Produit | La collection ensuite |
|---|---|---|
| `v.iter()` ou `for x in &v` | `&T` | inchangée, toujours utilisable |
| `v.iter_mut()` ou `for x in &mut v` | `&mut T` | modifiée sur place |
| `v.into_iter()` ou `for x in v` | `T` | **déplacée**, plus utilisable |

Extrait de [`examples/l08_collections_iterators.rs`, lignes 113-117](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l08_collections_iterators.rs#L113-L117) :

```rust
let mut prices = vec![10.0, 20.0, 30.0];
for p in prices.iter_mut() {
    *p *= 1.2;                              // `*` écrit à travers la référence
}
let total: f64 = prices.into_iter().sum();  // consomme prices
```

Le piège classique est une boucle `for` sur la collection elle-même :

```text
error[E0382]: borrow of moved value: `prices`
   --> e08_into_iter_move.rs:6:16
    |
  2 |     let prices = vec![10.0, 20.0];
    |         ------ move occurs because `prices` has type `Vec<f64>`, which does not implement the `Copy` trait
  3 |     for p in prices {
    |              ------ `prices` moved due to this implicit call to `.into_iter()`
...
  6 |     println!("{prices:?}");
    |                ^^^^^^ value borrowed here after move
…
help: consider iterating over a slice of the `Vec<f64>`'s content to avoid moving into the `for` loop
    |
  3 |     for p in &prices {
    |              +
```

## Regrouper avec `HashMap::entry`

Il n'y a pas de `GroupBy` dans la bibliothèque standard ; l'API [`entry`](https://doc.rust-lang.org/std/collections/struct.HashMap.html#method.entry) en fait une ligne — comme [`CollectionsMarshal.GetValueRefOrAddDefault`](https://learn.microsoft.com/dotnet/api/system.runtime.interopservices.collectionsmarshal.getvaluereforadddefault) en C# ou [`merge`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Map.html#merge(K,V,java.util.function.BiFunction)) en Java ([lignes 80-85](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l08_collections_iterators.rs#L80-L85)) :

```rust
let mut spend: HashMap<&str, f64> = HashMap::new();
for o in &orders {
    *spend.entry(o.customer).or_insert(0.0) += o.quantity as f64 * o.unit_price;
}
let sorted: BTreeMap<_, _> = spend.iter().collect();
// spend per customer: {"ada": 487.0, "grace": 50.0, "linus": 25.0}
```

## Le tri, et pourquoi les flottants sont particuliers

`sort` exige un **ordre total** ([`Ord`](https://doc.rust-lang.org/std/cmp/trait.Ord.html)). Les nombres à virgule flottante n'ont qu'un ordre partiel, car `NaN` n'est comparable à rien ([`src/lib.rs`, lignes 412-413](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L412-L413)) :

```rust
let mut prices = vec![19.99, 5.0, 12.5];
prices.sort();
```

```text
error[E0277]: the trait bound `{float}: Ord` is not satisfied
   --> e08_sort_floats.rs:3:12
    |
  3 |     prices.sort();
    |            ^^^^ the trait `Ord` is not implemented for `{float}`
```

C# et Java trient les doubles sans broncher et placent `NaN` selon leur propre convention. En Rust, choisissez explicitement ([`src/lib.rs`, lignes 419-420](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L419-L420)) :

```rust
let mut prices: Vec<f64> = vec![19.99, 5.0, 12.5];
prices.sort_by(|a, b| a.total_cmp(b));   // [5.0, 12.5, 19.99]
```

:::note[Pourquoi l'annotation `Vec<f64>` ?]
Sans elle, les littéraux sont encore un « flottant quelconque » non déterminé (`{float}`) au moment où la closure est vérifiée, et l'appel échoue avec `E0599: no method named total_cmp found for reference &{float}`. Nommer le type — ou écrire un littéral comme `19.99_f64` — règle la question.
:::

## Closures

Les closures Rust (`|args| body`) sont les lambdas de C# et de Java. Elles capturent les variables de la portée englobante — par référence par défaut ([lignes 121-126](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l08_collections_iterators.rs#L121-L126)) :

```rust
let threshold = 50.0;
let is_expensive = |o: &Order| o.unit_price * o.quantity as f64 > threshold;
println!("expensive orders: {}", orders.iter().filter(|o| is_expensive(o)).count());   // 2
```

`move` fait prendre à la closure la possession de ce qu'elle capture — obligatoire quand la closure survit à la portée courante, par exemple dans un thread (leçon 12) ([lignes 128-130](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l08_collections_iterators.rs#L128-L130)) :

```rust
let label = String::from("report");
let make_title = move |n: usize| format!("{label} #{n}");
println!("{}", make_title(1));   // report #1
```

| | C# | Java | Rust |
|---|---|---|---|
| Captures | variables (remontées dans une classe de closure) | variables effectivement finales | par référence, par référence mutable, ou par valeur (`move`) |
| Types de fonctions | `Func<>`, `Action<>` | `Function`, `Consumer`, … | les traits [`Fn`](https://doc.rust-lang.org/std/ops/trait.Fn.html), [`FnMut`](https://doc.rust-lang.org/std/ops/trait.FnMut.html), [`FnOnce`](https://doc.rust-lang.org/std/ops/trait.FnOnce.html) |

## Écrire votre propre itérateur

Implémentez une seule méthode, `next`, et tous les adaptateurs ci-dessus deviennent disponibles — l'équivalent d'[`IEnumerable<T>`](https://learn.microsoft.com/dotnet/api/system.collections.generic.ienumerable-1) avec [`yield return`](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/yield) ([lignes 12-26](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l08_collections_iterators.rs#L12-L26), [133-138](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l08_collections_iterators.rs#L133-L138)) :

```rust
struct Fibonacci {
    current: u64,
    next: u64,
}

impl Iterator for Fibonacci {
    type Item = u64;

    fn next(&mut self) -> Option<Self::Item> {
        let value = self.current;
        self.current = self.next;
        self.next += value;
        Some(value)                  // jamais None : une séquence infinie
    }
}

let fibs: Vec<u64> = Fibonacci { current: 0, next: 1 }.take_while(|&n| n < 100).collect();
// fibonacci < 100: [0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89]
```

`type Item = u64;` est un [**type associé**](https://doc.rust-lang.org/reference/items/associated-items.html#associated-types) : chaque itérateur décide de ce qu'il produit.

## Bonus sur les slices : `windows` et `chunks`

Extrait de [`examples/l08_collections_iterators.rs`, lignes 142-144](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l08_collections_iterators.rs#L142-L144) :

```rust
let readings = [3, 5, 4, 8, 9];
let rising = readings.windows(2).filter(|w| w[1] > w[0]).count();          // 3
let batches: Vec<i32> = readings.chunks(2).map(|c| c.iter().sum()).collect(); // [8, 12, 9]
```

## À retenir

- `Vec`, `HashMap`, `HashSet`, `BTreeMap` correspondent directement aux collections que vous connaissez ; l'ordre d'un `HashMap` n'est pas spécifié.
- Les adaptateurs d'itérateurs sont LINQ/Streams : paresseux jusqu'à leur consommation, et `collect` a besoin d'un type cible.
- `iter`, `iter_mut` et `into_iter` empruntent, empruntent mutablement ou consomment la collection.
- Les closures capturent par référence sauf si vous écrivez `move` ; implémenter `next` vous donne un itérateur complet.

## Exercices

1. Traduisez cette requête LINQ en chaîne d'itérateurs :

```csharp
var result = words.Where(w => w.Length > 3)
                  .Select(w => w.ToUpper())
                  .OrderBy(w => w)
                  .ToList();
```

<details>
<summary>Solution</summary>

Extrait de [`src/lib.rs`, lignes 434-437](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L434-L437) :

```rust
let words = ["tree", "sky", "apple", "rust", "go"];
let mut result: Vec<String> = words
    .iter()
    .filter(|w| w.len() > 3)
    .map(|w| w.to_uppercase())
    .collect();
result.sort();
assert_eq!(result, ["APPLE", "RUST", "TREE"]);
```

Le tri est une méthode de `Vec` (il trie sur place), pas un adaptateur d'itérateur : collectez donc d'abord. `len()` compte les octets ; pour des mots non ASCII, utilisez `w.chars().count()`.

</details>

2. Écrivez `fn word_counts(text: &str) -> BTreeMap<String, usize>` qui compte les mots sans tenir compte de la casse, de sorte que `"the cat and THE hat"` donne `{"and": 1, "cat": 1, "hat": 1, "the": 2}`.

<details>
<summary>Solution</summary>

Extrait de [`src/lib.rs`, lignes 443-453](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L443-L453) :

```rust
use std::collections::BTreeMap;

fn word_counts(text: &str) -> BTreeMap<String, usize> {
    let mut counts = BTreeMap::new();
    for word in text.split_whitespace() {
        *counts.entry(word.to_lowercase()).or_insert(0) += 1;
    }
    counts
}

let counts = word_counts("the cat and THE hat");
assert_eq!(counts["the"], 2);
assert_eq!(counts.keys().collect::<Vec<_>>(), ["and", "cat", "hat", "the"]);
```

`BTreeMap` garde les clés triées, donc la sortie est déterministe.

</details>

3. Implémentez un itérateur `Countdown(u32)` qui produit `3, 2, 1` pour `Countdown(3)` puis s'arrête, et utilisez-le avec `map` et `collect` pour construire `"3... 2... 1..."`.

<details>
<summary>Solution</summary>

Extrait de [`src/lib.rs`, lignes 459-467](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L459-L467) :

```rust
struct Countdown(u32);

impl Iterator for Countdown {
    type Item = u32;

    fn next(&mut self) -> Option<u32> {
        if self.0 == 0 {
            None
        } else {
            self.0 -= 1;
            Some(self.0 + 1)
        }
    }
}

let text: Vec<String> = Countdown(3).map(|n| format!("{n}...")).collect();
assert_eq!(text.join(" "), "3... 2... 1...");
```

Renvoyer `None` met fin à l'itération, comme `yield break` ou la fin d'un `IEnumerable`.

</details>

## Sources

- [The Book, ch. 8 — Common Collections](https://doc.rust-lang.org/book/ch08-00-common-collections.html)
- [The Book, ch. 13 — Iterators and Closures](https://doc.rust-lang.org/book/ch13-00-functional-features.html)
- [`std::collections` — choisir une collection](https://doc.rust-lang.org/std/collections/index.html)
- [`Iterator` — bibliothèque standard](https://doc.rust-lang.org/std/iter/trait.Iterator.html)
