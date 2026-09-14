---
title: 7. Collections and Streams
description: The collections framework without read-only interfaces, maps that return null, fail-fast iterators, and streams as LINQ that runs once — compared with System.Collections.Generic and LINQ.
sidebar:
  order: 7
---

Full examples: [`lessons/l07`](https://github.com/spareilleux/learn/tree/main/code/java-for-csharp/src/main/java/lessons/l07).

## The collections framework

The [collections framework](https://docs.oracle.com/en/java/javase/25/core/java-collections-framework.html) maps closely onto `System.Collections.Generic`. You program against an interface and choose an implementation:

| C# | Java interface | Usual Java implementation |
|---|---|---|
| `List<T>` | [`List<E>`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/List.html) | `ArrayList` |
| `LinkedList<T>` | `List<E>`, `Deque<E>` | `LinkedList` (rarely the right choice) |
| `Dictionary<K, V>` | [`Map<K, V>`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Map.html) | `HashMap` |
| `SortedDictionary<K, V>` | `SortedMap`, `NavigableMap` | `TreeMap` |
| `OrderedDictionary<K, V>` (insertion order) | `SequencedMap` | `LinkedHashMap` |
| `HashSet<T>` / `SortedSet<T>` | `Set<E>` / `NavigableSet<E>` | `HashSet` / `TreeSet` |
| `Queue<T>`, `Stack<T>` | `Deque<E>` | `ArrayDeque` |
| `PriorityQueue<T, P>` | `Queue<E>` | `PriorityQueue` (the element is its own priority) |
| `IEnumerable<T>` | `Iterable<T>` | — |
| `IReadOnlyList<T>`, `IReadOnlyDictionary<K, V>` | *none* | — |

Collections hold references only, so a `List<Integer>` boxes every element (lesson 4). Don't use `Stack` and `Vector`: they are synchronized legacy classes, and `ArrayDeque` replaces both.

## Unmodifiable, but not read-only types

The last row of the table is the big difference. Java has no read-only collection interfaces. [`List.of`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/List.html#unmodifiable) returns a `List`, with an `add` method that throws at run time:

```java
// List.of is unmodifiable, but its type is still List: the error comes at run time.
List<String> fixed = List.of("a", "b");
attempt("List.of add", () -> fixed.add("c"));
attempt("List.of with null", () -> List.of("a", null));

// Arrays.asList is a fixed-size view that writes through to the array.
String[] array = {"x", "y"};
List<String> view = Arrays.asList(array);
view.set(0, "changed");
System.out.println(array[0]);
attempt("Arrays.asList add", () -> view.add("z"));
```

```text
List.of add: UnsupportedOperationException
List.of with null: NullPointerException
changed
Arrays.asList add: UnsupportedOperationException
```

A C# method that takes an `IReadOnlyList<T>` documents its contract in the type system. In Java, the contract lives in the Javadoc, and the usual defence is a copy. `List.copyOf` returns an unmodifiable list and generally doesn't copy one that already is. Note also that `List.of`, `Set.of` and `Map.of` reject `null` elements.

| Java | What it is | Closest C# |
|---|---|---|
| `List.of(…)`, `List.copyOf(list)` | unmodifiable copy, no nulls | `list.ToImmutableList()` |
| `Collections.unmodifiableList(list)` | read-only **view**: changes to `list` show through | `list.AsReadOnly()` |
| `Arrays.asList(array)` | fixed-size view of the array: `set` writes through, `add` throws | — |
| `stream.toList()` | unmodifiable list | `ToList()` gives a mutable one |

## Maps return `null`

The C# indexer throws `KeyNotFoundException` for a missing key. Java's [`Map.get`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Map.html#get(java.lang.Object)) returns `null`, so a missing key and a key mapped to `null` look the same. The map's default methods cover the usual C# patterns:

```java
// Map.get returns null for a missing key instead of throwing.
Map<String, Integer> stock = new HashMap<>(Map.of("apples", 3));
System.out.println(stock.get("pears") + " " + stock.getOrDefault("pears", 0));

// merge and computeIfAbsent replace the TryGetValue dance.
Map<String, Integer> counts = new TreeMap<>();
for (String word : "to be or not to be".split(" ")) {
    counts.merge(word, 1, Integer::sum);
}
System.out.println(counts);
Map<String, List<String>> byInitial = new LinkedHashMap<>();
for (String word : List.of("tea", "coffee", "tonic")) {
    byInitial.computeIfAbsent(word.substring(0, 1), k -> new ArrayList<>()).add(word);
}
System.out.println(byInitial);
```

```text
null 0
{be=2, not=1, or=1, to=2}
{t=[tea, tonic], c=[coffee]}
```

`merge(key, 1, Integer::sum)` is the counting idiom: it inserts `1`, or combines the old value and `1`. `computeIfAbsent` replaces `if (!dict.TryGetValue(k, out var list)) dict[k] = list = new();`. Unboxing the `null` of a missing key into an `int` throws a `NullPointerException` (lesson 2).

### Iteration order is part of the choice

`HashMap` and `HashSet` iterate in no particular order, like `Dictionary`. The immutable `Map.of` and `Set.of` go further and **randomise** their order on each JVM start, so tests can't depend on it by accident. Running this one-liner four times on this machine printed two different orders:

```java
System.out.println(Map.of("one", 1, "two", 2, "three", 3, "four", 4, "five", 5).keySet());
```

```text
[five, three, two, four, one]
[two, three, five, one, four]
[five, three, two, four, one]
[five, three, two, four, one]
```

Choose `TreeMap` for sorted keys and `LinkedHashMap` for insertion order, as the examples above do. The course's tests would be flaky otherwise.

### Sequenced collections

Java 21 added [sequenced collections](https://openjdk.org/jeps/431): `List`, `Deque`, `LinkedHashSet` and sorted sets share `getFirst`, `getLast`, `addFirst` and a `reversed()` view, the counterparts of LINQ's `First()`, `Last()` and `Reverse()`. `LinkedHashMap` and `TreeMap` get `firstEntry`, `lastEntry` and `reversed()`:

```java
// Java 21 sequenced collections: first, last and a reversed view.
List<Integer> numbers = new ArrayList<>(List.of(1, 2, 3, 4, 5, 6));
System.out.println(numbers.getFirst() + " " + numbers.getLast() + " " + numbers.reversed());
```

```text
1 6 [6, 5, 4, 3, 2, 1]
```

## Modifying while iterating

Both platforms detect a collection modified during a `foreach`. Java throws `ConcurrentModificationException`, .NET `InvalidOperationException: Collection was modified; enumeration operation may not execute.` The fix in Java is [`removeIf`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Collection.html#removeIf(java.util.function.Predicate)), the counterpart of `List<T>.RemoveAll`:

```java
// Removing while iterating fails fast; removeIf is the safe way.
attempt("remove in for-each", () -> {
    for (Integer n : numbers) {
        if (n % 2 == 0) {
            numbers.remove(n);
        }
    }
});
numbers.removeIf(n -> n % 2 == 0);
System.out.println(numbers);
```

```text
remove in for-each: ConcurrentModificationException
[1, 3, 5]
```

`numbers.remove(n)` works here only because `n` is an `Integer`: with an `int` it would remove by index (lesson 4).

## Streams: LINQ to Objects

A [stream](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/stream/package-summary.html) is a lazy pipeline of operations over a source, like a LINQ query over `IEnumerable<T>`. The names differ:

| LINQ | Stream | Note |
|---|---|---|
| `Where` | `filter` | |
| `Select` | `map` | `mapToInt`, `mapToDouble` for primitive streams |
| `SelectMany` | `flatMap` | the function returns a `Stream` |
| `OrderBy(x => x.K)`, `ThenBy` | `sorted(Comparator.comparing(X::k).thenComparing(…))` | lesson 6 |
| `Distinct`, `Take`, `Skip` | `distinct`, `limit`, `skip` | |
| `TakeWhile`, `SkipWhile` | `takeWhile`, `dropWhile` | |
| `First()`, `FirstOrDefault()` | `findFirst()` | returns an `Optional` (lesson 5) |
| `Any`, `All` | `anyMatch`, `allMatch` | also `noneMatch` |
| `Count()` | `count()` | returns a `long` |
| `Sum`, `Min`, `Max`, `Average` | `mapToInt(…).sum()`, `min(Comparator)`, `max(Comparator)`, `average()` | |
| `Aggregate` | `reduce` | |
| `GroupBy` | `collect(Collectors.groupingBy(…))` | builds a `Map`, not a lazy sequence |
| `ToDictionary` | `collect(Collectors.toMap(…))` | |
| `ToList()` | `toList()` | unmodifiable |
| `Chunk(n)` | `gather(Gatherers.windowFixed(n))` | Java 24 |
| `Zip` | *none* | exercise 3 |

```java
// Where / Select / OrderBy / ToList
List<String> bigOrders = ORDERS.stream()
        .filter(o -> o.total() >= 50)
        .sorted(Comparator.comparingDouble(Order::total).reversed())
        .map(o -> o.customer() + ":" + o.product())
        .toList();
System.out.println(bigOrders);

// GroupBy + Sum, with a sorted map for a stable order
Map<String, Double> totals = ORDERS.stream()
        .collect(Collectors.groupingBy(Order::customer, TreeMap::new, Collectors.summingDouble(Order::total)));
System.out.println(totals);
```

```text
[ada:monitor, ada:keyboard, alan:mouse]
{ada=478.0, alan=72.5, grace=25.0}
```

Collecting goes through [`Collectors`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/stream/Collectors.html). `groupingBy` takes a key function, an optional map factory (`TreeMap::new` here) and a *downstream* collector that aggregates each group. It is the `GroupBy(…).Select(g => new { g.Key, Total = g.Sum(…) })` pattern in one call.

```java
// Any / All / First / Distinct / Count
System.out.println(ORDERS.stream().anyMatch(o -> o.quantity() > 4) + " "
        + ORDERS.stream().allMatch(o -> o.price() > 1) + " "
        + ORDERS.stream().filter(o -> o.product().equals("mouse")).findFirst().map(Order::customer).orElse("none") + " "
        + ORDERS.stream().map(Order::product).distinct().count());

// SelectMany, Chunk (Java 24 gatherers) and primitive streams
System.out.println(Stream.of("a,b", "c").flatMap(s -> Stream.of(s.split(","))).toList());
System.out.println(IntStream.rangeClosed(1, 7).boxed().gather(Gatherers.windowFixed(3)).toList());
var stats = ORDERS.stream().mapToInt(Order::quantity).summaryStatistics();
System.out.println("quantities: sum " + stats.getSum() + ", min " + stats.getMin() + ", max " + stats.getMax());
```

```text
true true alan 4
[a, b, c]
[[1, 2, 3], [4, 5, 6], [7]]
quantities: sum 11, min 1, max 5
```

[Gatherers](https://openjdk.org/jeps/485), final since Java 24, are the extension point for custom intermediate operations, the role C# fills with extension methods on `IEnumerable<T>`. `Gatherers` provides `windowFixed`, `windowSliding`, `fold`, `scan` and `mapConcurrent`.

### Lazy, and single-use

Like LINQ, a stream runs nothing until a terminal operation (`toList`, `count`, `findFirst`…), and elements pass through the whole pipeline one at a time:

```java
// Streams are lazy: nothing runs until a terminal operation, and elements flow one at a time.
Stream<String> pipeline = Stream.of("one", "two", "three")
        .peek(s -> System.out.println("  filter " + s))
        .filter(s -> s.length() == 3)
        .peek(s -> System.out.println("  map " + s))
        .map(String::toUpperCase);
System.out.println("pipeline built");
System.out.println(pipeline.findFirst().orElseThrow());
```

```text
pipeline built
  filter one
  map one
ONE
```

Unlike an `IEnumerable<T>`, a stream is not a reusable query. It is consumed by its terminal operation, and a second one throws:

```java
// A stream can be consumed only once, unlike an IEnumerable.
Stream<String> once = Stream.of("x");
once.count();
try {
    once.count();
} catch (IllegalStateException e) {
    System.out.println(e.getMessage());
}
```

```text
stream has already been operated upon or closed
```

The C# side enumerates the same `Select` query twice and prints `5 5`. In Java, keep the *collection* and call `stream()` again, or pass a `Supplier<Stream<T>>`. A stream is not an `Iterable` either, so `for` doesn't accept it:

```java
import java.util.stream.Stream;

class Names {
    static void print(Stream<String> names) {
        for (String name : names) {
            System.out.println(name);
        }
    }
}
```

```text
StreamIsNotIterable.java:5: error: for-each not applicable to expression type
        for (String name : names) {
                           ^
  required: array or java.lang.Iterable
  found:    Stream<String>
1 error
```

### What the compiler catches

A C# query is already an `IEnumerable<T>`. A stream has to be collected, and forgetting it is a type error with a message about inference:

```java
import java.util.List;

class Upper {
    static List<String> upper(List<String> names) {
        return names.stream().map(String::toUpperCase);
    }
}
```

```text
StreamIsNotAList.java:5: error: incompatible types: no instance(s) of type variable(s) R exist so that Stream<R> conforms to List<String>
        return names.stream().map(String::toUpperCase);
                                 ^
  where R,T are type-variables:
    R extends Object declared in method <R>map(Function<? super T,? extends R>)
    T extends Object declared in interface Stream
1 error
```

`sum()` exists only on primitive streams, because a `Stream<T>` can't know how to add `T`s. C#'s `Sum` has overloads for `IEnumerable<int>`, `IEnumerable<double>` and so on; Java makes you convert first with `mapToInt(Integer::intValue)`:

```java
import java.util.List;

class Totals {
    static int total(List<Integer> quantities) {
        return quantities.stream().sum();
    }
}
```

```text
SumOnBoxedStream.java:5: error: cannot find symbol
        return quantities.stream().sum();
                                  ^
  symbol:   method sum()
  location: interface Stream<Integer>
1 error
```

And `findFirst` returns an `Optional`, never the element or `null`:

```java
import java.util.List;

class First {
    static String firstLong(List<String> words) {
        return words.stream().filter(w -> w.length() > 3).findFirst();
    }
}
```

```text
FindFirstIsOptional.java:5: error: incompatible types: Optional<String> cannot be converted to String
        return words.stream().filter(w -> w.length() > 3).findFirst();
                                                                   ^
1 error
```

### Two run-time traps

```java
// toList() is unmodifiable; toMap rejects duplicate keys.
try {
    bigOrders.add("more");
} catch (UnsupportedOperationException e) {
    System.out.println("toList() result is unmodifiable");
}
try {
    ORDERS.stream().collect(Collectors.toMap(Order::customer, Order::product));
} catch (IllegalStateException e) {
    System.out.println(e.getMessage());
}
```

```text
toList() result is unmodifiable
Duplicate key ada (attempted merging values keyboard and monitor)
```

`ToDictionary` fails the same way in C# (`An item with the same key has already been added. Key: ada`). `toMap` takes a third argument, a merge function, to decide instead. `Collectors.toList()`, the pre-Java 16 spelling, returns a mutable `ArrayList` in practice, but its Javadoc guarantees nothing about mutability.

Parallel streams (`parallelStream()`) exist, like PLINQ's `AsParallel()`. Lesson 9 covers when they help.

## Key takeaways

- Same shapes as `System.Collections.Generic`, but no read-only interfaces: `List.of` and `toList()` throw `UnsupportedOperationException` at run time.
- `Map.get` returns `null`; use `getOrDefault`, `merge` and `computeIfAbsent`.
- Don't rely on `HashMap` order, and never on `Map.of` order, which changes between runs. Choose `TreeMap` or `LinkedHashMap`.
- Streams are LINQ with different names. They are lazy, consumed once, not `Iterable`, and collected with `Collectors`.
- `findFirst` returns an `Optional`, `count` a `long`, and `sum` needs a primitive stream.

## Exercises

1. Translate this query, which finds the product with the largest total quantity:

```csharp
var best = orders.GroupBy(o => o.Product)
    .Select(g => new { Product = g.Key, Quantity = g.Sum(o => o.Quantity) })
    .OrderByDescending(x => x.Quantity)
    .First().Product;
```

<details>
<summary>Solution</summary>

```java
static String bestSeller(List<Order> orders) {
    return orders.stream()
            .collect(Collectors.groupingBy(Order::product, Collectors.summingInt(Order::quantity)))
            .entrySet().stream()
            .max(Map.Entry.comparingByValue())
            .map(Map.Entry::getKey)
            .orElseThrow();
}
```

`groupingBy` is terminal, so the grouped result is a `Map`, and you stream its `entrySet()` to continue. `max` avoids sorting everything. Java has no anonymous types; `Map.Entry` or a small record plays their role. With the lesson's orders, the answer is `cable` (5 units).

</details>

2. Write `topWords(String text, int n)`, returning the `n` most frequent words as `word=count`. Break ties alphabetically, and ignore case and punctuation.

<details>
<summary>Solution</summary>

```java
static List<String> topWords(String text, int n) {
    return Arrays.stream(text.toLowerCase().split("\\W+"))
            .filter(w -> !w.isEmpty())
            .collect(Collectors.groupingBy(w -> w, Collectors.counting()))
            .entrySet().stream()
            .sorted(Map.Entry.<String, Long>comparingByValue(Comparator.reverseOrder())
                    .thenComparing(Map.Entry.comparingByKey()))
            .limit(n)
            .map(e -> e.getKey() + "=" + e.getValue())
            .toList();
}
```

`topWords("To be, or not to be.", 3)` gives `[be=2, to=2, not=1]`. The explicit type witness `Map.Entry.<String, Long>comparingByValue(…)` is needed because inference can't see through the chained `thenComparing`: without it, javac reports "no suitable method found for thenComparing". It is a common Java annoyance with no C# counterpart.

</details>

3. Java streams have no `Zip`. Write `zip(List<A>, List<B>, BiFunction<A, B, R>)`, stopping at the shorter list like LINQ's `Zip`.

<details>
<summary>Solution</summary>

```java
static <A, B, R> List<R> zip(List<A> first, List<B> second, BiFunction<A, B, R> combine) {
    return IntStream.range(0, Math.min(first.size(), second.size()))
            .mapToObj(i -> combine.apply(first.get(i), second.get(i)))
            .toList();
}
```

Streaming the indices works for `List`s with random access. For arbitrary iterables, you would walk two `Iterator`s in a loop. `zip(List.of("keyboard", "mouse", "cable"), List.of(1, 2), (p, q) -> p + "x" + q)` gives `[keyboardx1, mousex2]`.

</details>

## Sources

- [Java Collections Framework guide](https://docs.oracle.com/en/java/javase/25/core/java-collections-framework.html)
- [`java.util.stream` package summary](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/stream/package-summary.html)
- [JEP 431 — Sequenced collections](https://openjdk.org/jeps/431) and [JEP 485 — Stream gatherers](https://openjdk.org/jeps/485)
- [.NET — Collections and data structures](https://learn.microsoft.com/dotnet/standard/collections/) and [LINQ overview](https://learn.microsoft.com/dotnet/csharp/linq/)
