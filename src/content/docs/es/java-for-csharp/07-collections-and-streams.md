---
title: 7. Colecciones y Streams
description: El framework de colecciones sin interfaces de solo lectura, mapas que devuelven null, iteradores fail-fast y streams como un LINQ que se ejecuta una sola vez — comparados con System.Collections.Generic y LINQ.
sidebar:
  order: 7
---

Ejemplos completos: [`lessons/l07`](https://github.com/spareilleux/learn/tree/main/code/java-for-csharp/src/main/java/lessons/l07).

## El framework de colecciones

El [framework de colecciones](https://docs.oracle.com/en/java/javase/25/core/java-collections-framework.html) se corresponde de cerca con `System.Collections.Generic`. Programas contra una interfaz y eliges una implementación:

| C# | Interfaz Java | Implementación Java habitual |
|---|---|---|
| `List<T>` | [`List<E>`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/List.html) | `ArrayList` |
| `LinkedList<T>` | `List<E>`, `Deque<E>` | `LinkedList` (rara vez la opción adecuada) |
| `Dictionary<K, V>` | [`Map<K, V>`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Map.html) | `HashMap` |
| `SortedDictionary<K, V>` | `SortedMap`, `NavigableMap` | `TreeMap` |
| `OrderedDictionary<K, V>` (orden de inserción) | `SequencedMap` | `LinkedHashMap` |
| `HashSet<T>` / `SortedSet<T>` | `Set<E>` / `NavigableSet<E>` | `HashSet` / `TreeSet` |
| `Queue<T>`, `Stack<T>` | `Deque<E>` | `ArrayDeque` |
| `PriorityQueue<T, P>` | `Queue<E>` | `PriorityQueue` (el elemento es su propia prioridad) |
| `IEnumerable<T>` | `Iterable<T>` | — |
| `IReadOnlyList<T>`, `IReadOnlyDictionary<K, V>` | *ninguna* | — |

Las colecciones solo contienen referencias, así que una `List<Integer>` hace boxing de cada elemento (lección 4). No uses `Stack` ni `Vector`: son clases heredadas sincronizadas, y `ArrayDeque` sustituye a las dos.

## No modificables, pero sin tipos de solo lectura

La última fila de la tabla es la gran diferencia. Java no tiene interfaces de colección de solo lectura. [`List.of`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/List.html#unmodifiable) devuelve una `List`, con un método `add` que lanza una excepción en tiempo de ejecución:

```java
// List.of no es modificable, pero su tipo sigue siendo List: el error llega en tiempo de ejecución.
List<String> fixed = List.of("a", "b");
attempt("List.of add", () -> fixed.add("c"));
attempt("List.of with null", () -> List.of("a", null));

// Arrays.asList es una vista de tamaño fijo cuyas escrituras llegan al array.
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

Un método C# que recibe un `IReadOnlyList<T>` documenta su contrato en el sistema de tipos. En Java, el contrato vive en el Javadoc, y la defensa habitual es una copia. `List.copyOf` devuelve una lista no modificable y, en general, no copia una que ya lo es. Ten en cuenta también que `List.of`, `Set.of` y `Map.of` rechazan los elementos `null`.

| Java | Qué es | Lo más parecido en C# |
|---|---|---|
| `List.of(…)`, `List.copyOf(list)` | copia no modificable, sin nulls | `list.ToImmutableList()` |
| `Collections.unmodifiableList(list)` | **vista** de solo lectura: los cambios en `list` se ven a través de ella | `list.AsReadOnly()` |
| `Arrays.asList(array)` | vista de tamaño fijo del array: `set` escribe en él, `add` lanza una excepción | — |
| `stream.toList()` | lista no modificable | `ToList()` da una lista mutable |

## Los mapas devuelven `null`

El indexador de C# lanza `KeyNotFoundException` para una clave ausente. [`Map.get`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Map.html#get(java.lang.Object)) de Java devuelve `null`, así que una clave ausente y una clave asociada a `null` parecen lo mismo. Los métodos por defecto del mapa cubren los patrones habituales de C#:

```java
// Map.get devuelve null para una clave ausente en lugar de lanzar una excepción.
Map<String, Integer> stock = new HashMap<>(Map.of("apples", 3));
System.out.println(stock.get("pears") + " " + stock.getOrDefault("pears", 0));

// merge y computeIfAbsent sustituyen el baile de TryGetValue.
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

`merge(key, 1, Integer::sum)` es la forma idiomática de contar: inserta `1`, o combina el valor anterior con `1`. `computeIfAbsent` sustituye a `if (!dict.TryGetValue(k, out var list)) dict[k] = list = new();`. Hacer unboxing a `int` del `null` de una clave ausente lanza una `NullPointerException` (lección 2).

### El orden de iteración forma parte de la elección

`HashMap` y `HashSet` iteran sin un orden particular, como `Dictionary`. Los inmutables `Map.of` y `Set.of` van más allá y **aleatorizan** su orden en cada arranque de la JVM, para que las pruebas no puedan depender de él por accidente. Ejecutar cuatro veces esta línea en esta máquina imprimió dos órdenes distintos:

```java
System.out.println(Map.of("one", 1, "two", 2, "three", 3, "four", 4, "five", 5).keySet());
```

```text
[five, three, two, four, one]
[two, three, five, one, four]
[five, three, two, four, one]
[five, three, two, four, one]
```

Elige `TreeMap` para claves ordenadas y `LinkedHashMap` para el orden de inserción, como hacen los ejemplos anteriores. De lo contrario, las pruebas del curso serían inestables.

### Colecciones secuenciadas

Java 21 añadió las [colecciones secuenciadas](https://openjdk.org/jeps/431): `List`, `Deque`, `LinkedHashSet` y los conjuntos ordenados comparten `getFirst`, `getLast`, `addFirst` y una vista `reversed()`, los equivalentes de `First()`, `Last()` y `Reverse()` de LINQ. `LinkedHashMap` y `TreeMap` obtienen `firstEntry`, `lastEntry` y `reversed()`:

```java
// Colecciones secuenciadas de Java 21: primero, último y una vista invertida.
List<Integer> numbers = new ArrayList<>(List.of(1, 2, 3, 4, 5, 6));
System.out.println(numbers.getFirst() + " " + numbers.getLast() + " " + numbers.reversed());
```

```text
1 6 [6, 5, 4, 3, 2, 1]
```

## Modificar mientras se itera

Las dos plataformas detectan una colección modificada durante un `foreach`. Java lanza `ConcurrentModificationException`, .NET `InvalidOperationException: Collection was modified; enumeration operation may not execute.` La solución en Java es [`removeIf`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Collection.html#removeIf(java.util.function.Predicate)), el equivalente de `List<T>.RemoveAll`:

```java
// Eliminar mientras se itera falla de inmediato; removeIf es la forma segura.
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

`numbers.remove(n)` funciona aquí solo porque `n` es un `Integer`: con un `int` eliminaría por índice (lección 4).

## Streams: LINQ to Objects

Un [stream](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/stream/package-summary.html) es una cadena perezosa de operaciones sobre un origen, como una consulta LINQ sobre `IEnumerable<T>`. Los nombres cambian:

| LINQ | Stream | Nota |
|---|---|---|
| `Where` | `filter` | |
| `Select` | `map` | `mapToInt`, `mapToDouble` para streams primitivos |
| `SelectMany` | `flatMap` | la función devuelve un `Stream` |
| `OrderBy(x => x.K)`, `ThenBy` | `sorted(Comparator.comparing(X::k).thenComparing(…))` | lección 6 |
| `Distinct`, `Take`, `Skip` | `distinct`, `limit`, `skip` | |
| `TakeWhile`, `SkipWhile` | `takeWhile`, `dropWhile` | |
| `First()`, `FirstOrDefault()` | `findFirst()` | devuelve un `Optional` (lección 5) |
| `Any`, `All` | `anyMatch`, `allMatch` | también `noneMatch` |
| `Count()` | `count()` | devuelve un `long` |
| `Sum`, `Min`, `Max`, `Average` | `mapToInt(…).sum()`, `min(Comparator)`, `max(Comparator)`, `average()` | |
| `Aggregate` | `reduce` | |
| `GroupBy` | `collect(Collectors.groupingBy(…))` | construye un `Map`, no una secuencia perezosa |
| `ToDictionary` | `collect(Collectors.toMap(…))` | |
| `ToList()` | `toList()` | no modificable |
| `Chunk(n)` | `gather(Gatherers.windowFixed(n))` | Java 24 |
| `Zip` | *ninguno* | ejercicio 3 |

```java
// Where / Select / OrderBy / ToList
List<String> bigOrders = ORDERS.stream()
        .filter(o -> o.total() >= 50)
        .sorted(Comparator.comparingDouble(Order::total).reversed())
        .map(o -> o.customer() + ":" + o.product())
        .toList();
System.out.println(bigOrders);

// GroupBy + Sum, con un mapa ordenado para un orden estable
Map<String, Double> totals = ORDERS.stream()
        .collect(Collectors.groupingBy(Order::customer, TreeMap::new, Collectors.summingDouble(Order::total)));
System.out.println(totals);
```

```text
[ada:monitor, ada:keyboard, alan:mouse]
{ada=478.0, alan=72.5, grace=25.0}
```

La recolección pasa por [`Collectors`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/stream/Collectors.html). `groupingBy` recibe una función de clave, una fábrica de mapas opcional (aquí `TreeMap::new`) y un collector *secundario* (downstream) que agrega cada grupo. Es el patrón `GroupBy(…).Select(g => new { g.Key, Total = g.Sum(…) })` en una sola llamada.

```java
// Any / All / First / Distinct / Count
System.out.println(ORDERS.stream().anyMatch(o -> o.quantity() > 4) + " "
        + ORDERS.stream().allMatch(o -> o.price() > 1) + " "
        + ORDERS.stream().filter(o -> o.product().equals("mouse")).findFirst().map(Order::customer).orElse("none") + " "
        + ORDERS.stream().map(Order::product).distinct().count());

// SelectMany, Chunk (gatherers de Java 24) y streams primitivos
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

Los [gatherers](https://openjdk.org/jeps/485), definitivos desde Java 24, son el punto de extensión para operaciones intermedias personalizadas, el papel que en C# cumplen los métodos de extensión sobre `IEnumerable<T>`. `Gatherers` proporciona `windowFixed`, `windowSliding`, `fold`, `scan` y `mapConcurrent`.

### Perezosos y de un solo uso

Como en LINQ, un stream no ejecuta nada hasta una operación terminal (`toList`, `count`, `findFirst`…), y los elementos recorren toda la cadena de uno en uno:

```java
// Los streams son perezosos: nada se ejecuta hasta una operación terminal, y los elementos pasan de uno en uno.
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

A diferencia de un `IEnumerable<T>`, un stream no es una consulta reutilizable. Su operación terminal lo consume, y una segunda lanza una excepción:

```java
// Un stream solo se puede consumir una vez, a diferencia de un IEnumerable.
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

El lado C# enumera dos veces la misma consulta `Select` e imprime `5 5`. En Java, conserva la *colección* y vuelve a llamar a `stream()`, o pasa un `Supplier<Stream<T>>`. Un stream tampoco es un `Iterable`, así que `for` no lo acepta:

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

### Lo que detecta el compilador

Una consulta C# ya es un `IEnumerable<T>`. Un stream hay que recolectarlo, y olvidarlo es un error de tipos con un mensaje sobre la inferencia:

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

`sum()` solo existe en los streams primitivos, porque un `Stream<T>` no puede saber cómo sumar valores `T`. El `Sum` de C# tiene sobrecargas para `IEnumerable<int>`, `IEnumerable<double>`, etc.; Java te obliga a convertir antes con `mapToInt(Integer::intValue)`:

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

Y `findFirst` devuelve un `Optional`, nunca el elemento ni `null`:

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

### Dos trampas en tiempo de ejecución

```java
// toList() no es modificable; toMap rechaza las claves duplicadas.
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

`ToDictionary` falla de la misma manera en C# (`An item with the same key has already been added. Key: ada`). `toMap` acepta un tercer argumento, una función de fusión, para decidir en su lugar. `Collectors.toList()`, la forma anterior a Java 16, devuelve en la práctica un `ArrayList` mutable, pero su Javadoc no garantiza nada sobre la mutabilidad.

Los streams paralelos (`parallelStream()`) existen, como el `AsParallel()` de PLINQ. La lección 9 explica cuándo ayudan.

## Puntos clave

- Las mismas formas que `System.Collections.Generic`, pero sin interfaces de solo lectura: `List.of` y `toList()` lanzan `UnsupportedOperationException` en tiempo de ejecución.
- `Map.get` devuelve `null`; usa `getOrDefault`, `merge` y `computeIfAbsent`.
- No confíes en el orden de `HashMap`, y nunca en el de `Map.of`, que cambia de una ejecución a otra. Elige `TreeMap` o `LinkedHashMap`.
- Los streams son LINQ con otros nombres. Son perezosos, se consumen una sola vez, no son `Iterable` y se recolectan con `Collectors`.
- `findFirst` devuelve un `Optional`, `count` un `long`, y `sum` necesita un stream primitivo.

## Ejercicios

1. Traduce esta consulta, que encuentra el producto con la mayor cantidad total:

```csharp
var best = orders.GroupBy(o => o.Product)
    .Select(g => new { Product = g.Key, Quantity = g.Sum(o => o.Quantity) })
    .OrderByDescending(x => x.Quantity)
    .First().Product;
```

<details>
<summary>Solución</summary>

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

`groupingBy` es terminal, así que el resultado agrupado es un `Map`, y para continuar haces un stream de su `entrySet()`. `max` evita ordenarlo todo. Java no tiene tipos anónimos; `Map.Entry` o un pequeño record cumplen su papel. Con los pedidos de la lección, la respuesta es `cable` (5 unidades).

</details>

2. Escribe `topWords(String text, int n)`, que devuelva las `n` palabras más frecuentes como `word=count`. Desempata por orden alfabético e ignora mayúsculas y signos de puntuación.

<details>
<summary>Solución</summary>

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

`topWords("To be, or not to be.", 3)` da `[be=2, to=2, not=1]`. El testigo de tipo explícito `Map.Entry.<String, Long>comparingByValue(…)` es necesario porque la inferencia no ve a través del `thenComparing` encadenado: sin él, javac informa de «no suitable method found for thenComparing». Es una molestia habitual de Java sin equivalente en C#.

</details>

3. Los streams de Java no tienen `Zip`. Escribe `zip(List<A>, List<B>, BiFunction<A, B, R>)`, que se detenga en la lista más corta, como el `Zip` de LINQ.

<details>
<summary>Solución</summary>

```java
static <A, B, R> List<R> zip(List<A> first, List<B> second, BiFunction<A, B, R> combine) {
    return IntStream.range(0, Math.min(first.size(), second.size()))
            .mapToObj(i -> combine.apply(first.get(i), second.get(i)))
            .toList();
}
```

Recorrer los índices con un stream funciona para las `List` con acceso aleatorio. Para iterables cualesquiera, recorrerías dos `Iterator` en un bucle. `zip(List.of("keyboard", "mouse", "cable"), List.of(1, 2), (p, q) -> p + "x" + q)` da `[keyboardx1, mousex2]`.

</details>

## Fuentes

- [Guía del Java Collections Framework](https://docs.oracle.com/en/java/javase/25/core/java-collections-framework.html)
- [Resumen del paquete `java.util.stream`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/stream/package-summary.html)
- [JEP 431 — Sequenced collections](https://openjdk.org/jeps/431) y [JEP 485 — Stream gatherers](https://openjdk.org/jeps/485)
- [.NET — Colecciones y estructuras de datos](https://learn.microsoft.com/dotnet/standard/collections/) e [Información general de LINQ](https://learn.microsoft.com/dotnet/csharp/linq/)
