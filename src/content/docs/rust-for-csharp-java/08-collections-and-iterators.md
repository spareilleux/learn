---
title: 8. Collections and iterators
description: Vec, HashMap and friends, and iterator chains that replace LINQ and Java Streams.
sidebar:
  order: 8
---

Full example: [`examples/l08_collections_iterators.rs`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/examples/l08_collections_iterators.rs) — `cargo run --example l08_collections_iterators`.

## The collections you already know

| Rust (`std::collections`) | C# | Java |
|---|---|---|
| [`Vec<T>`](https://doc.rust-lang.org/std/vec/struct.Vec.html) | `List<T>` | `ArrayList<T>` |
| [`VecDeque<T>`](https://doc.rust-lang.org/std/collections/struct.VecDeque.html) | `Queue<T>` / `LinkedList<T>` | `ArrayDeque<T>` |
| [`HashMap<K, V>`](https://doc.rust-lang.org/std/collections/struct.HashMap.html) | `Dictionary<K, V>` | `HashMap<K, V>` |
| [`BTreeMap<K, V>`](https://doc.rust-lang.org/std/collections/struct.BTreeMap.html) | `SortedDictionary<K, V>` | `TreeMap<K, V>` |
| [`HashSet<T>`](https://doc.rust-lang.org/std/collections/struct.HashSet.html) | `HashSet<T>` | `HashSet<T>` |
| [`BTreeSet<T>`](https://doc.rust-lang.org/std/collections/struct.BTreeSet.html) | `SortedSet<T>` | `TreeSet<T>` |
| [`BinaryHeap<T>`](https://doc.rust-lang.org/std/collections/struct.BinaryHeap.html) | `PriorityQueue<T, P>` | `PriorityQueue<T>` |

`Vec` and `String` are in scope everywhere; the others need a `use std::collections::…`.

:::caution[HashMap order]
Iterating a `HashMap` yields entries in an unspecified order that can change between runs. When you need sorted output, use a `BTreeMap` — or collect into one before printing, as the example does.
:::

## LINQ and Streams, translated

The example works on a list of orders ([lines 57-61](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l08_collections_iterators.rs#L57-L61)):

```rust
let big_orders: Vec<&str> = orders
    .iter()
    .filter(|o| o.quantity >= 2)
    .map(|o| o.product)
    .collect();
// big orders: ["mouse", "monitor"]
```

| Rust | C# [LINQ](https://learn.microsoft.com/dotnet/csharp/linq/) | [Java Streams](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/stream/package-summary.html) |
|---|---|---|
| `.iter()` | (the `IEnumerable` itself) | `.stream()` |
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
| collect into `HashSet` | `.Distinct()` | `.distinct()` |
| `vec.sort_by_key(…)` (on the `Vec`) | `.OrderBy(…)` | `.sorted(comparator)` |

From [`examples/l08_collections_iterators.rs`, lines 65-74](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l08_collections_iterators.rs#L65-L74):

```rust
let revenue: f64 = orders.iter().map(|o| o.quantity as f64 * o.unit_price).sum();
let any_monitor = orders.iter().any(|o| o.product == "monitor");
let all_positive = orders.iter().all(|o| o.quantity > 0);
let first_mouse = orders.iter().find(|o| o.product == "mouse").map(|o| o.customer);
```

```text
revenue 562, any monitor true, all positive true, first mouse buyer Some("grace")
```

`find` returns an `Option` — there is no `FirstOrDefault` returning `null`.

## Iterators are lazy

Like LINQ's [deferred execution](https://learn.microsoft.com/dotnet/standard/linq/deferred-execution-lazy-evaluation) and Java's intermediate operations, nothing runs until something **consumes** the iterator (`collect`, `sum`, `for`, `count`…). The compiler warns when you forget:

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

This laziness also lets iterators be infinite: see the Fibonacci example below.

## `collect` needs to know the target type

[`collect`](https://doc.rust-lang.org/std/iter/trait.Iterator.html#method.collect) can build a `Vec`, a `HashSet`, a `String`, a `HashMap`… so you must say which one ([`src/lib.rs`, line 396](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L396)):

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

Either annotate the variable (`let evens: Vec<_> = …`) or use the "turbofish" syntax: `.collect::<Vec<_>>()`. The `_` lets the compiler infer the element type.

## `iter`, `iter_mut`, `into_iter`

Ownership (lessons 3 and 4) shows up in how you iterate:

| Method | Yields | The collection afterwards |
|---|---|---|
| `v.iter()` or `for x in &v` | `&T` | unchanged, still usable |
| `v.iter_mut()` or `for x in &mut v` | `&mut T` | modified in place |
| `v.into_iter()` or `for x in v` | `T` | **moved**, no longer usable |

From [`examples/l08_collections_iterators.rs`, lines 113-117](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l08_collections_iterators.rs#L113-L117):

```rust
let mut prices = vec![10.0, 20.0, 30.0];
for p in prices.iter_mut() {
    *p *= 1.2;                              // `*` writes through the reference
}
let total: f64 = prices.into_iter().sum();  // consumes prices
```

The classic trap is a `for` loop over the collection itself:

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

## Grouping with `HashMap::entry`

There is no `GroupBy` in the standard library; the [`entry`](https://doc.rust-lang.org/std/collections/struct.HashMap.html#method.entry) API makes it a one-liner — like [`CollectionsMarshal.GetValueRefOrAddDefault`](https://learn.microsoft.com/dotnet/api/system.runtime.interopservices.collectionsmarshal.getvaluereforadddefault) in C# or [`merge`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Map.html#merge(K,V,java.util.function.BiFunction)) in Java ([lines 80-85](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l08_collections_iterators.rs#L80-L85)):

```rust
let mut spend: HashMap<&str, f64> = HashMap::new();
for o in &orders {
    *spend.entry(o.customer).or_insert(0.0) += o.quantity as f64 * o.unit_price;
}
let sorted: BTreeMap<_, _> = spend.iter().collect();
// spend per customer: {"ada": 487.0, "grace": 50.0, "linus": 25.0}
```

## Sorting, and why floats are special

`sort` needs a **total order** ([`Ord`](https://doc.rust-lang.org/std/cmp/trait.Ord.html)). Floating-point numbers only have a partial one, because `NaN` is not comparable to anything ([`src/lib.rs`, lines 412-413](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L412-L413)):

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

C# and Java sort doubles without complaint and place `NaN` according to their own convention. In Rust, choose explicitly ([`src/lib.rs`, lines 419-420](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L419-L420)):

```rust
let mut prices: Vec<f64> = vec![19.99, 5.0, 12.5];
prices.sort_by(|a, b| a.total_cmp(b));   // [5.0, 12.5, 19.99]
```

:::note[Why the `Vec<f64>` annotation?]
Without it, the literals are still an undecided "some float" (`{float}`) when the closure is checked, and the call fails with `E0599: no method named total_cmp found for reference &{float}`. Naming the type — or writing a literal like `19.99_f64` — settles it.
:::

## Closures

Rust closures (`|args| body`) are C# lambdas and Java lambdas. They capture variables from the surrounding scope — by reference by default ([lines 121-126](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l08_collections_iterators.rs#L121-L126)):

```rust
let threshold = 50.0;
let is_expensive = |o: &Order| o.unit_price * o.quantity as f64 > threshold;
println!("expensive orders: {}", orders.iter().filter(|o| is_expensive(o)).count());   // 2
```

`move` makes the closure take ownership of what it captures — required when the closure outlives the current scope, for example in a thread (lesson 12) ([lines 128-130](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l08_collections_iterators.rs#L128-L130)):

```rust
let label = String::from("report");
let make_title = move |n: usize| format!("{label} #{n}");
println!("{}", make_title(1));   // report #1
```

| | C# | Java | Rust |
|---|---|---|---|
| Captures | variables (hoisted into a closure class) | effectively-final variables | by reference, mutable reference, or by value (`move`) |
| Function types | `Func<>`, `Action<>` | `Function`, `Consumer`, … | the traits [`Fn`](https://doc.rust-lang.org/std/ops/trait.Fn.html), [`FnMut`](https://doc.rust-lang.org/std/ops/trait.FnMut.html), [`FnOnce`](https://doc.rust-lang.org/std/ops/trait.FnOnce.html) |

## Writing your own iterator

Implement one method, `next`, and every adapter above becomes available — the counterpart of [`IEnumerable<T>`](https://learn.microsoft.com/dotnet/api/system.collections.generic.ienumerable-1) with [`yield return`](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/yield) ([lines 12-26](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l08_collections_iterators.rs#L12-L26), [133-138](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l08_collections_iterators.rs#L133-L138)):

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
        Some(value)                  // never None: an infinite sequence
    }
}

let fibs: Vec<u64> = Fibonacci { current: 0, next: 1 }.take_while(|&n| n < 100).collect();
// fibonacci < 100: [0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89]
```

`type Item = u64;` is an [**associated type**](https://doc.rust-lang.org/reference/items/associated-items.html#associated-types): each iterator decides what it yields.

## Slices bonus: `windows` and `chunks`

From [`examples/l08_collections_iterators.rs`, lines 142-144](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l08_collections_iterators.rs#L142-L144):

```rust
let readings = [3, 5, 4, 8, 9];
let rising = readings.windows(2).filter(|w| w[1] > w[0]).count();          // 3
let batches: Vec<i32> = readings.chunks(2).map(|c| c.iter().sum()).collect(); // [8, 12, 9]
```

## Key takeaways

- `Vec`, `HashMap`, `HashSet`, `BTreeMap` map directly to the collections you know; `HashMap` order is unspecified.
- Iterator adapters are LINQ/Streams: lazy until consumed, and `collect` needs a target type.
- `iter`, `iter_mut` and `into_iter` borrow, mutably borrow, or consume the collection.
- Closures capture by reference unless you write `move`; implementing `next` gives you a full iterator.

## Exercises

1. Translate this LINQ query into an iterator chain:

```csharp
var result = words.Where(w => w.Length > 3)
                  .Select(w => w.ToUpper())
                  .OrderBy(w => w)
                  .ToList();
```

<details>
<summary>Solution</summary>

From [`src/lib.rs`, lines 434-437](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L434-L437):

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

Sorting is a method on `Vec` (it sorts in place), not an iterator adapter, so collect first. `len()` counts bytes; for non-ASCII words, use `w.chars().count()`.

</details>

2. Write `fn word_counts(text: &str) -> BTreeMap<String, usize>` that counts words case-insensitively, so `"the cat and THE hat"` gives `{"and": 1, "cat": 1, "hat": 1, "the": 2}`.

<details>
<summary>Solution</summary>

From [`src/lib.rs`, lines 443-453](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L443-L453):

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

`BTreeMap` keeps the keys sorted, so the output is deterministic.

</details>

3. Implement an iterator `Countdown(u32)` that yields `3, 2, 1` for `Countdown(3)` and then stops, and use it with `map` and `collect` to build `"3... 2... 1..."`.

<details>
<summary>Solution</summary>

From [`src/lib.rs`, lines 459-467](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L459-L467):

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

Returning `None` ends the iteration, like `yield break` or the end of an `IEnumerable`.

</details>

## Sources

- [The Book, ch. 8 — Common Collections](https://doc.rust-lang.org/book/ch08-00-common-collections.html)
- [The Book, ch. 13 — Iterators and Closures](https://doc.rust-lang.org/book/ch13-00-functional-features.html)
- [`std::collections` — choosing a collection](https://doc.rust-lang.org/std/collections/index.html)
- [`Iterator` — standard library](https://doc.rust-lang.org/std/iter/trait.Iterator.html)
