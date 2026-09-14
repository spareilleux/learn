---
title: 8. Colecciones e iteradores
description: Vec, HashMap y compañía, y las cadenas de iteradores que sustituyen a LINQ y a los Streams de Java.
sidebar:
  order: 8
---

Ejemplo completo: [`examples/l08_collections_iterators.rs`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/examples/l08_collections_iterators.rs) — `cargo run --example l08_collections_iterators`.

## Las colecciones que ya conoces

| Rust (`std::collections`) | C# | Java |
|---|---|---|
| [`Vec<T>`](https://doc.rust-lang.org/std/vec/struct.Vec.html) | `List<T>` | `ArrayList<T>` |
| [`VecDeque<T>`](https://doc.rust-lang.org/std/collections/struct.VecDeque.html) | `Queue<T>` / `LinkedList<T>` | `ArrayDeque<T>` |
| [`HashMap<K, V>`](https://doc.rust-lang.org/std/collections/struct.HashMap.html) | `Dictionary<K, V>` | `HashMap<K, V>` |
| [`BTreeMap<K, V>`](https://doc.rust-lang.org/std/collections/struct.BTreeMap.html) | `SortedDictionary<K, V>` | `TreeMap<K, V>` |
| [`HashSet<T>`](https://doc.rust-lang.org/std/collections/struct.HashSet.html) | `HashSet<T>` | `HashSet<T>` |
| [`BTreeSet<T>`](https://doc.rust-lang.org/std/collections/struct.BTreeSet.html) | `SortedSet<T>` | `TreeSet<T>` |
| [`BinaryHeap<T>`](https://doc.rust-lang.org/std/collections/struct.BinaryHeap.html) | `PriorityQueue<T, P>` | `PriorityQueue<T>` |

`Vec` y `String` están disponibles en todas partes; las demás necesitan un `use std::collections::…`.

:::caution[El orden de un HashMap]
Recorrer un `HashMap` devuelve las entradas en un orden no especificado que puede cambiar de una ejecución a otra. Cuando necesites una salida ordenada, usa un `BTreeMap` — o recógelas en uno antes de imprimir, como hace el ejemplo.
:::

## LINQ y Streams, traducidos

El ejemplo trabaja con una lista de pedidos:

```rust
let big_orders: Vec<&str> = orders
    .iter()
    .filter(|o| o.quantity >= 2)
    .map(|o| o.product)
    .collect();
// big orders: ["mouse", "monitor"]
```

| Rust | [LINQ](https://learn.microsoft.com/dotnet/csharp/linq/) de C# | [Streams de Java](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/stream/package-summary.html) |
|---|---|---|
| `.iter()` | (el propio `IEnumerable`) | `.stream()` |
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
| recoger en un `HashSet` | `.Distinct()` | `.distinct()` |
| `vec.sort_by_key(…)` (sobre el `Vec`) | `.OrderBy(…)` | `.sorted(comparator)` |

```rust
let revenue: f64 = orders.iter().map(|o| o.quantity as f64 * o.unit_price).sum();
let any_monitor = orders.iter().any(|o| o.product == "monitor");
let all_positive = orders.iter().all(|o| o.quantity > 0);
let first_mouse = orders.iter().find(|o| o.product == "mouse").map(|o| o.customer);
```

```text
revenue 562, any monitor true, all positive true, first mouse buyer Some("grace")
```

`find` devuelve un `Option` — no existe un `FirstOrDefault` que devuelva `null`.

## Los iteradores son perezosos

Como la [ejecución diferida](https://learn.microsoft.com/dotnet/standard/linq/deferred-execution-lazy-evaluation) de LINQ y las operaciones intermedias de Java, nada se ejecuta hasta que algo **consume** el iterador (`collect`, `sum`, `for`, `count`…). El compilador te avisa si lo olvidas:

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

Esta pereza también permite que los iteradores sean infinitos: consulta el ejemplo de Fibonacci más abajo.

## `collect` necesita conocer el tipo de destino

[`collect`](https://doc.rust-lang.org/std/iter/trait.Iterator.html#method.collect) puede construir un `Vec`, un `HashSet`, un `String`, un `HashMap`… así que tienes que decir cuál:

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

Anota la variable (`let evens: Vec<_> = …`) o usa la sintaxis «turbofish»: `.collect::<Vec<_>>()`. El `_` deja que el compilador infiera el tipo de los elementos.

## `iter`, `iter_mut`, `into_iter`

La propiedad (lecciones 3 y 4) se nota en la forma de iterar:

| Método | Produce | La colección después |
|---|---|---|
| `v.iter()` o `for x in &v` | `&T` | sin cambios, sigue siendo utilizable |
| `v.iter_mut()` o `for x in &mut v` | `&mut T` | modificada en el sitio |
| `v.into_iter()` o `for x in v` | `T` | **movida**, ya no es utilizable |

```rust
let mut prices = vec![10.0, 20.0, 30.0];
for p in prices.iter_mut() {
    *p *= 1.2;                              // `*` escribe a través de la referencia
}
let total: f64 = prices.into_iter().sum();  // consume prices
```

La trampa clásica es un bucle `for` sobre la propia colección:

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

## Agrupar con `HashMap::entry`

No hay `GroupBy` en la biblioteca estándar; la API [`entry`](https://doc.rust-lang.org/std/collections/struct.HashMap.html#method.entry) lo resuelve en una línea — como [`CollectionsMarshal.GetValueRefOrAddDefault`](https://learn.microsoft.com/dotnet/api/system.runtime.interopservices.collectionsmarshal.getvaluereforadddefault) en C# o [`merge`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Map.html#merge(K,V,java.util.function.BiFunction)) en Java:

```rust
let mut spend: HashMap<&str, f64> = HashMap::new();
for o in &orders {
    *spend.entry(o.customer).or_insert(0.0) += o.quantity as f64 * o.unit_price;
}
let sorted: BTreeMap<_, _> = spend.iter().collect();
// spend per customer: {"ada": 487.0, "grace": 50.0, "linus": 25.0}
```

## Ordenar, y por qué los flotantes son especiales

`sort` necesita un **orden total** ([`Ord`](https://doc.rust-lang.org/std/cmp/trait.Ord.html)). Los números de coma flotante solo tienen uno parcial, porque `NaN` no se puede comparar con nada:

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

C# y Java ordenan los doubles sin rechistar y colocan `NaN` según su propia convención. En Rust, eliges explícitamente:

```rust
let mut prices: Vec<f64> = vec![19.99, 5.0, 12.5];
prices.sort_by(|a, b| a.total_cmp(b));   // [5.0, 12.5, 19.99]
```

:::note[¿Por qué la anotación `Vec<f64>`?]
Sin ella, los literales siguen siendo un «flotante cualquiera» sin decidir (`{float}`) cuando se comprueba la closure, y la llamada falla con `E0599: no method named total_cmp found for reference &{float}`. Nombrar el tipo — o escribir un literal como `19.99_f64` — lo resuelve.
:::

## Closures

Las closures de Rust (`|args| body`) son las lambdas de C# y de Java. Capturan variables del ámbito que las rodea — por referencia, por defecto:

```rust
let threshold = 50.0;
let is_expensive = |o: &Order| o.unit_price * o.quantity as f64 > threshold;
println!("expensive orders: {}", orders.iter().filter(|o| is_expensive(o)).count());   // 2
```

`move` hace que la closure tome la propiedad de lo que captura — obligatorio cuando la closure vive más que el ámbito actual, por ejemplo en un hilo (lección 12):

```rust
let label = String::from("report");
let make_title = move |n: usize| format!("{label} #{n}");
println!("{}", make_title(1));   // report #1
```

| | C# | Java | Rust |
|---|---|---|---|
| Capturas | variables (elevadas a una clase de closure) | variables efectivamente finales | por referencia, por referencia mutable o por valor (`move`) |
| Tipos de función | `Func<>`, `Action<>` | `Function`, `Consumer`, … | los traits [`Fn`](https://doc.rust-lang.org/std/ops/trait.Fn.html), [`FnMut`](https://doc.rust-lang.org/std/ops/trait.FnMut.html), [`FnOnce`](https://doc.rust-lang.org/std/ops/trait.FnOnce.html) |

## Escribir tu propio iterador

Implementa un solo método, `next`, y todos los adaptadores anteriores quedan disponibles — el equivalente de [`IEnumerable<T>`](https://learn.microsoft.com/dotnet/api/system.collections.generic.ienumerable-1) con [`yield return`](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/yield):

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
        Some(value)                  // nunca None: una secuencia infinita
    }
}

let fibs: Vec<u64> = Fibonacci { current: 0, next: 1 }.take_while(|&n| n < 100).collect();
// fibonacci < 100: [0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89]
```

`type Item = u64;` es un [**tipo asociado**](https://doc.rust-lang.org/reference/items/associated-items.html#associated-types): cada iterador decide qué produce.

## Extra sobre slices: `windows` y `chunks`

```rust
let readings = [3, 5, 4, 8, 9];
let rising = readings.windows(2).filter(|w| w[1] > w[0]).count();          // 3
let batches: Vec<i32> = readings.chunks(2).map(|c| c.iter().sum()).collect(); // [8, 12, 9]
```

## Puntos clave

- `Vec`, `HashMap`, `HashSet` y `BTreeMap` corresponden directamente a las colecciones que ya conoces; el orden de un `HashMap` no está especificado.
- Los adaptadores de iteradores son LINQ/Streams: perezosos hasta que se consumen, y `collect` necesita un tipo de destino.
- `iter`, `iter_mut` e `into_iter` toman prestada la colección, la toman prestada de forma mutable o la consumen.
- Las closures capturan por referencia salvo que escribas `move`; implementar `next` te da un iterador completo.

## Ejercicios

1. Traduce esta consulta LINQ a una cadena de iteradores:

```csharp
var result = words.Where(w => w.Length > 3)
                  .Select(w => w.ToUpper())
                  .OrderBy(w => w)
                  .ToList();
```

<details>
<summary>Solución</summary>

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

Ordenar es un método de `Vec` (ordena en el sitio), no un adaptador de iterador, así que primero hay que recoger. `len()` cuenta bytes; para palabras no ASCII, usa `w.chars().count()`.

</details>

2. Escribe `fn word_counts(text: &str) -> BTreeMap<String, usize>` que cuente las palabras sin distinguir mayúsculas de minúsculas, de modo que `"the cat and THE hat"` dé `{"and": 1, "cat": 1, "hat": 1, "the": 2}`.

<details>
<summary>Solución</summary>

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

`BTreeMap` mantiene las claves ordenadas, así que la salida es determinista.

</details>

3. Implementa un iterador `Countdown(u32)` que produzca `3, 2, 1` para `Countdown(3)` y luego se detenga, y úsalo con `map` y `collect` para construir `"3... 2... 1..."`.

<details>
<summary>Solución</summary>

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

Devolver `None` termina la iteración, como `yield break` o el final de un `IEnumerable`.

</details>

## Fuentes

- [The Book, ch. 8 — Common Collections](https://doc.rust-lang.org/book/ch08-00-common-collections.html)
- [The Book, ch. 13 — Iterators and Closures](https://doc.rust-lang.org/book/ch13-00-functional-features.html)
- [`std::collections` — elegir una colección](https://doc.rust-lang.org/std/collections/index.html)
- [`Iterator` — biblioteca estándar](https://doc.rust-lang.org/std/iter/trait.Iterator.html)
