---
title: 7. Collections et Streams
description: Le framework de collections sans interfaces en lecture seule, des maps qui renvoient null, des itérateurs fail-fast, et les streams comme un LINQ qui ne s'exécute qu'une fois — comparés à System.Collections.Generic et à LINQ.
sidebar:
  order: 7
---

Exemples complets : [`lessons/l07`](https://github.com/spareilleux/learn/tree/main/code/java-for-csharp/src/main/java/lessons/l07).

## Le framework de collections

Le [framework de collections](https://docs.oracle.com/en/java/javase/25/core/java-collections-framework.html) correspond de près à `System.Collections.Generic`. On programme contre une interface et on choisit une implémentation :

| C# | Interface Java | Implémentation Java habituelle |
|---|---|---|
| `List<T>` | [`List<E>`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/List.html) | `ArrayList` |
| `LinkedList<T>` | `List<E>`, `Deque<E>` | `LinkedList` (rarement le bon choix) |
| `Dictionary<K, V>` | [`Map<K, V>`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Map.html) | `HashMap` |
| `SortedDictionary<K, V>` | `SortedMap`, `NavigableMap` | `TreeMap` |
| `OrderedDictionary<K, V>` (ordre d'insertion) | `SequencedMap` | `LinkedHashMap` |
| `HashSet<T>` / `SortedSet<T>` | `Set<E>` / `NavigableSet<E>` | `HashSet` / `TreeSet` |
| `Queue<T>`, `Stack<T>` | `Deque<E>` | `ArrayDeque` |
| `PriorityQueue<T, P>` | `Queue<E>` | `PriorityQueue` (l'élément est sa propre priorité) |
| `IEnumerable<T>` | `Iterable<T>` | — |
| `IReadOnlyList<T>`, `IReadOnlyDictionary<K, V>` | *aucune* | — |

Les collections ne contiennent que des références : une `List<Integer>` boxe donc chaque élément (leçon 4). N'utilisez pas `Stack` ni `Vector` : ce sont d'anciennes classes synchronisées, et `ArrayDeque` les remplace toutes les deux.

## Non modifiables, mais sans types en lecture seule

La dernière ligne du tableau est la grande différence. Java n'a pas d'interfaces de collections en lecture seule. [`List.of`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/List.html#unmodifiable) renvoie une `List`, avec une méthode `add` qui lève une exception à l'exécution :

```java
// List.of n'est pas modifiable, mais son type reste List : l'erreur survient à l'exécution.
List<String> fixed = List.of("a", "b");
attempt("List.of add", () -> fixed.add("c"));
attempt("List.of with null", () -> List.of("a", null));

// Arrays.asList est une vue de taille fixe qui écrit dans le tableau.
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

Une méthode C# qui prend un `IReadOnlyList<T>` documente son contrat dans le système de types. En Java, le contrat vit dans la Javadoc, et la défense habituelle est une copie. `List.copyOf` renvoie une liste non modifiable et, en général, ne recopie pas une liste qui l'est déjà. Notez aussi que `List.of`, `Set.of` et `Map.of` rejettent les éléments `null`.

| Java | Ce que c'est | Équivalent C# le plus proche |
|---|---|---|
| `List.of(…)`, `List.copyOf(list)` | copie non modifiable, sans null | `list.ToImmutableList()` |
| `Collections.unmodifiableList(list)` | **vue** en lecture seule : les modifications de `list` y apparaissent | `list.AsReadOnly()` |
| `Arrays.asList(array)` | vue de taille fixe sur le tableau : `set` écrit dans le tableau, `add` lève une exception | — |
| `stream.toList()` | liste non modifiable | `ToList()` en donne une modifiable |

## Les maps renvoient `null`

L'indexeur C# lève `KeyNotFoundException` pour une clé absente. [`Map.get`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Map.html#get(java.lang.Object)) en Java renvoie `null` : une clé absente et une clé associée à `null` se ressemblent donc. Les méthodes par défaut de la map couvrent les motifs habituels de C# :

```java
// Map.get renvoie null pour une clé absente au lieu de lever une exception.
Map<String, Integer> stock = new HashMap<>(Map.of("apples", 3));
System.out.println(stock.get("pears") + " " + stock.getOrDefault("pears", 0));

// merge et computeIfAbsent remplacent la gymnastique de TryGetValue.
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

`merge(key, 1, Integer::sum)` est l'idiome de comptage : il insère `1`, ou combine l'ancienne valeur et `1`. `computeIfAbsent` remplace `if (!dict.TryGetValue(k, out var list)) dict[k] = list = new();`. Unboxer en `int` le `null` d'une clé absente lève une `NullPointerException` (leçon 2).

### L'ordre d'itération fait partie du choix

`HashMap` et `HashSet` itèrent dans un ordre quelconque, comme `Dictionary`. Les `Map.of` et `Set.of` immuables vont plus loin et **rendent leur ordre aléatoire** à chaque démarrage de la JVM, pour que les tests ne puissent pas en dépendre par accident. Exécuter quatre fois ce one-liner sur cette machine a affiché deux ordres différents :

```java
System.out.println(Map.of("one", 1, "two", 2, "three", 3, "four", 4, "five", 5).keySet());
```

```text
[five, three, two, four, one]
[two, three, five, one, four]
[five, three, two, four, one]
[five, three, two, four, one]
```

Choisissez `TreeMap` pour des clés triées et `LinkedHashMap` pour l'ordre d'insertion, comme le font les exemples ci-dessus. Sans cela, les tests du cours seraient instables.

### Collections séquencées

Java 21 a ajouté les [collections séquencées](https://openjdk.org/jeps/431) (sequenced collections) : `List`, `Deque`, `LinkedHashSet` et les ensembles triés partagent `getFirst`, `getLast`, `addFirst` et une vue `reversed()`, les équivalents de `First()`, `Last()` et `Reverse()` de LINQ. `LinkedHashMap` et `TreeMap` reçoivent `firstEntry`, `lastEntry` et `reversed()` :

```java
// Collections séquencées de Java 21 : premier, dernier et une vue inversée.
List<Integer> numbers = new ArrayList<>(List.of(1, 2, 3, 4, 5, 6));
System.out.println(numbers.getFirst() + " " + numbers.getLast() + " " + numbers.reversed());
```

```text
1 6 [6, 5, 4, 3, 2, 1]
```

## Modifier pendant l'itération

Les deux plateformes détectent une collection modifiée pendant un `foreach`. Java lève `ConcurrentModificationException`, .NET `InvalidOperationException: Collection was modified; enumeration operation may not execute.` En Java, la solution est [`removeIf`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Collection.html#removeIf(java.util.function.Predicate)), l'équivalent de `List<T>.RemoveAll` :

```java
// Supprimer pendant l'itération échoue immédiatement ; removeIf est la méthode sûre.
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

`numbers.remove(n)` ne fonctionne ici que parce que `n` est un `Integer` : avec un `int`, la suppression se ferait par index (leçon 4).

## Streams : LINQ to Objects

Un [stream](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/stream/package-summary.html) est un pipeline paresseux d'opérations sur une source, comme une requête LINQ sur un `IEnumerable<T>`. Les noms diffèrent :

| LINQ | Stream | Remarque |
|---|---|---|
| `Where` | `filter` | |
| `Select` | `map` | `mapToInt`, `mapToDouble` pour les streams primitifs |
| `SelectMany` | `flatMap` | la fonction renvoie un `Stream` |
| `OrderBy(x => x.K)`, `ThenBy` | `sorted(Comparator.comparing(X::k).thenComparing(…))` | leçon 6 |
| `Distinct`, `Take`, `Skip` | `distinct`, `limit`, `skip` | |
| `TakeWhile`, `SkipWhile` | `takeWhile`, `dropWhile` | |
| `First()`, `FirstOrDefault()` | `findFirst()` | renvoie un `Optional` (leçon 5) |
| `Any`, `All` | `anyMatch`, `allMatch` | et aussi `noneMatch` |
| `Count()` | `count()` | renvoie un `long` |
| `Sum`, `Min`, `Max`, `Average` | `mapToInt(…).sum()`, `min(Comparator)`, `max(Comparator)`, `average()` | |
| `Aggregate` | `reduce` | |
| `GroupBy` | `collect(Collectors.groupingBy(…))` | construit une `Map`, pas une séquence paresseuse |
| `ToDictionary` | `collect(Collectors.toMap(…))` | |
| `ToList()` | `toList()` | non modifiable |
| `Chunk(n)` | `gather(Gatherers.windowFixed(n))` | Java 24 |
| `Zip` | *aucun* | exercice 3 |

```java
// Where / Select / OrderBy / ToList
List<String> bigOrders = ORDERS.stream()
        .filter(o -> o.total() >= 50)
        .sorted(Comparator.comparingDouble(Order::total).reversed())
        .map(o -> o.customer() + ":" + o.product())
        .toList();
System.out.println(bigOrders);

// GroupBy + Sum, avec une map triée pour un ordre stable
Map<String, Double> totals = ORDERS.stream()
        .collect(Collectors.groupingBy(Order::customer, TreeMap::new, Collectors.summingDouble(Order::total)));
System.out.println(totals);
```

```text
[ada:monitor, ada:keyboard, alan:mouse]
{ada=478.0, alan=72.5, grace=25.0}
```

La collecte passe par [`Collectors`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/stream/Collectors.html). `groupingBy` prend une fonction de clé, une fabrique de map facultative (ici `TreeMap::new`) et un collecteur *en aval* (downstream) qui agrège chaque groupe. C'est le motif `GroupBy(…).Select(g => new { g.Key, Total = g.Sum(…) })` en un seul appel.

```java
// Any / All / First / Distinct / Count
System.out.println(ORDERS.stream().anyMatch(o -> o.quantity() > 4) + " "
        + ORDERS.stream().allMatch(o -> o.price() > 1) + " "
        + ORDERS.stream().filter(o -> o.product().equals("mouse")).findFirst().map(Order::customer).orElse("none") + " "
        + ORDERS.stream().map(Order::product).distinct().count());

// SelectMany, Chunk (gatherers de Java 24) et streams primitifs
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

Les [gatherers](https://openjdk.org/jeps/485), finalisés depuis Java 24, sont le point d'extension pour les opérations intermédiaires sur mesure, le rôle que C# confie aux méthodes d'extension sur `IEnumerable<T>`. `Gatherers` fournit `windowFixed`, `windowSliding`, `fold`, `scan` et `mapConcurrent`.

### Paresseux, et à usage unique

Comme LINQ, un stream n'exécute rien avant une opération terminale (`toList`, `count`, `findFirst`…), et les éléments traversent tout le pipeline un par un :

```java
// Les streams sont paresseux : rien ne s'exécute avant une opération terminale, et les éléments passent un par un.
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

Contrairement à un `IEnumerable<T>`, un stream n'est pas une requête réutilisable. Il est consommé par son opération terminale, et une seconde opération lève une exception :

```java
// Un stream ne peut être consommé qu'une fois, contrairement à un IEnumerable.
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

Le côté C# énumère deux fois la même requête `Select` et affiche `5 5`. En Java, gardez la *collection* et rappelez `stream()`, ou passez un `Supplier<Stream<T>>`. Un stream n'est pas non plus un `Iterable`, donc `for` ne l'accepte pas :

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

### Ce que le compilateur détecte

Une requête C# est déjà un `IEnumerable<T>`. Un stream doit être collecté, et l'oublier est une erreur de type, avec un message qui parle d'inférence :

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

`sum()` n'existe que sur les streams primitifs, car un `Stream<T>` ne peut pas savoir comment additionner des `T`. Le `Sum` de C# a des surcharges pour `IEnumerable<int>`, `IEnumerable<double>`, etc. ; Java oblige à convertir d'abord avec `mapToInt(Integer::intValue)` :

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

Et `findFirst` renvoie un `Optional`, jamais l'élément ni `null` :

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

### Deux pièges à l'exécution

```java
// toList() n'est pas modifiable ; toMap rejette les clés en double.
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

`ToDictionary` échoue de la même façon en C# (`An item with the same key has already been added. Key: ada`). `toMap` accepte un troisième argument, une fonction de fusion, pour trancher. `Collectors.toList()`, l'écriture d'avant Java 16, renvoie en pratique une `ArrayList` modifiable, mais sa Javadoc ne garantit rien quant à la mutabilité.

Les streams parallèles (`parallelStream()`) existent, comme le `AsParallel()` de PLINQ. La leçon 9 explique quand ils sont utiles.

## À retenir

- Les mêmes formes que `System.Collections.Generic`, mais pas d'interfaces en lecture seule : `List.of` et `toList()` lèvent `UnsupportedOperationException` à l'exécution.
- `Map.get` renvoie `null` ; utilisez `getOrDefault`, `merge` et `computeIfAbsent`.
- Ne comptez pas sur l'ordre d'une `HashMap`, et jamais sur celui de `Map.of`, qui change d'une exécution à l'autre. Choisissez `TreeMap` ou `LinkedHashMap`.
- Les streams sont LINQ avec d'autres noms. Ils sont paresseux, consommés une seule fois, ne sont pas `Iterable`, et se collectent avec `Collectors`.
- `findFirst` renvoie un `Optional`, `count` un `long`, et `sum` exige un stream primitif.

## Exercices

1. Traduisez cette requête, qui trouve le produit dont la quantité totale est la plus élevée :

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

`groupingBy` est terminal : le résultat groupé est donc une `Map`, et on streame son `entrySet()` pour continuer. `max` évite de tout trier. Java n'a pas de types anonymes ; `Map.Entry` ou un petit record joue leur rôle. Avec les commandes de la leçon, la réponse est `cable` (5 unités).

</details>

2. Écrivez `topWords(String text, int n)`, qui renvoie les `n` mots les plus fréquents sous la forme `word=count`. Départagez les ex æquo par ordre alphabétique, et ignorez la casse et la ponctuation.

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

`topWords("To be, or not to be.", 3)` donne `[be=2, to=2, not=1]`. Le témoin de type explicite `Map.Entry.<String, Long>comparingByValue(…)` est nécessaire parce que l'inférence ne voit pas à travers le `thenComparing` chaîné : sans lui, javac signale « no suitable method found for thenComparing ». C'est un désagrément courant de Java, sans équivalent en C#.

</details>

3. Les streams Java n'ont pas de `Zip`. Écrivez `zip(List<A>, List<B>, BiFunction<A, B, R>)`, qui s'arrête à la liste la plus courte comme le `Zip` de LINQ.

<details>
<summary>Solution</summary>

```java
static <A, B, R> List<R> zip(List<A> first, List<B> second, BiFunction<A, B, R> combine) {
    return IntStream.range(0, Math.min(first.size(), second.size()))
            .mapToObj(i -> combine.apply(first.get(i), second.get(i)))
            .toList();
}
```

Streamer les indices fonctionne pour les `List` à accès direct. Pour des itérables quelconques, on parcourrait deux `Iterator` dans une boucle. `zip(List.of("keyboard", "mouse", "cable"), List.of(1, 2), (p, q) -> p + "x" + q)` donne `[keyboardx1, mousex2]`.

</details>

## Sources

- [Guide du Java Collections Framework](https://docs.oracle.com/en/java/javase/25/core/java-collections-framework.html)
- [Résumé du package `java.util.stream`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/stream/package-summary.html)
- [JEP 431 — Sequenced collections](https://openjdk.org/jeps/431) et [JEP 485 — Stream gatherers](https://openjdk.org/jeps/485)
- [.NET — Collections et structures de données](https://learn.microsoft.com/dotnet/standard/collections/) et [vue d'ensemble de LINQ](https://learn.microsoft.com/dotnet/csharp/linq/)
