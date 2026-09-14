---
title: 6. Lambdas et interfaces fonctionnelles
description: Des interfaces fonctionnelles au lieu de Func et Action, les références de méthode, la capture de valeurs effectivement finales, la composition, et des listes d'écouteurs au lieu des événements — comparés aux délégués C#.
sidebar:
  order: 6
---

Exemples complets : [`lessons/l06`](https://github.com/spareilleux/learn/tree/main/code/java-for-csharp/src/main/java/lessons/l06).

## Pas de types délégués : des interfaces à une seule méthode

C# a des types délégués : `Func<string, int>` est un type à part entière, et depuis C# 10 une lambda a même un type naturel. Java n'a aucun type fonction. Une lambda est l'implémentation d'une **interface fonctionnelle**, c'est-à-dire une interface qui a exactement une méthode abstraite, et le compilateur doit savoir de quelle interface il s'agit d'après le contexte : le *type cible* (target type).

Le JDK fournit les formes courantes dans [`java.util.function`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/function/package-summary.html) :

| C# | Java | Méthode à appeler |
|---|---|---|
| `Func<T, R>` | [`Function<T, R>`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/function/Function.html) | `apply` |
| `Func<T1, T2, R>` | `BiFunction<T, U, R>` | `apply` |
| `Func<R>` | [`Supplier<T>`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/function/Supplier.html) | `get` |
| `Action<T>` | [`Consumer<T>`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/function/Consumer.html) | `accept` |
| `Action` | [`Runnable`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Runnable.html) | `run` |
| `Predicate<T>` | [`Predicate<T>`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/function/Predicate.html) | `test` |
| `Func<T, T>` | `UnaryOperator<T>` | `apply` |
| `Func<T, T, T>` | `BinaryOperator<T>` | `apply` |
| `Func<string, int>` sans boxing | `ToIntFunction<String>`, `IntBinaryOperator`, `IntPredicate`… | `applyAsInt`, `test`… |

Il n'y a pas de `Function3` : au-delà de deux paramètres, vous déclarez votre propre interface. Le nom de la méthode change aussi avec l'interface, si bien qu'on ne peut pas appeler une variable lambda comme une méthode (`length("abc")` en C#) :

```java
// Func<string, int>, Func<int, int, int>, Func<string>, Action<string>, Predicate<string>
Function<String, Integer> length = s -> s.length();
BiFunction<Integer, Integer, Integer> add = (a, b) -> a + b;
Supplier<String> greeting = () -> "hello";
Consumer<String> print = s -> System.out.println("print: " + s);
Predicate<String> isEmpty = s -> s.isEmpty();

// Chaque interface a son propre nom de méthode : apply, get, accept, test.
System.out.println(length.apply("lambda") + " " + add.apply(2, 3) + " " + greeting.get());
print.accept("consumer");
System.out.println(isEmpty.test(""));

// Les spécialisations primitives évitent le boxing.
ToIntFunction<String> fastLength = String::length;
IntBinaryOperator multiply = (a, b) -> a * b;
System.out.println(fastLength.applyAsInt("abc") + " " + multiply.applyAsInt(6, 7));
```

```text
6 5 hello
print: consumer
true
3 42
```

Sans type cible, une lambda n'a pas de type. `var` ne peut pas en inférer un, et `Object` n'est pas une interface fonctionnelle :

```java
class Increments {
    static void run() {
        var increment = (int x) -> x + 1;
    }
}
```

```text
LambdaWithoutTarget.java:3: error: cannot infer type for local variable increment
        var increment = (int x) -> x + 1;
            ^
  (lambda expression needs an explicit target-type)
1 error
```

```java
class References {
    static void run() {
        Object length = String::length;
    }
}
```

```text
MethodRefWithoutInterface.java:3: error: incompatible types: Object is not a functional interface
        Object length = String::length;
                        ^
1 error
```

Le côté C# affiche ``Func`2`` pour `(string s) => s.Length`.

## Vos propres interfaces fonctionnelles

Toute interface dotée d'une seule méthode abstraite peut servir de cible à une lambda, y compris les plus anciennes comme `Runnable`, `Comparator` ou `Callable`. Les méthodes par défaut et statiques ne comptent pas. L'annotation [`@FunctionalInterface`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/FunctionalInterface.html) est facultative, comme `@Override` : elle demande au compilateur de vérifier la règle.

```java
@FunctionalInterface
interface Handler {
    void handle(String message);

    void close();
}
```

```text
NotFunctional.java:1: error: Unexpected @FunctionalInterface annotation
@FunctionalInterface
^
  Handler is not a functional interface
    multiple non-overriding abstract methods found in interface Handler
1 error
```

Comme les lambdas sont typées par leur cible, deux surcharges qui prennent des interfaces fonctionnelles différentes de même forme rendent un appel ambigu. C# a le même problème avec les délégués, mais les interfaces standard de Java se recoupent beaucoup : `Supplier<String>` et [`Callable<String>`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/Callable.html) ne prennent rien et renvoient toutes deux un `String`.

```java
import java.util.concurrent.Callable;
import java.util.function.Supplier;

class Scheduler {
    static void schedule(Supplier<String> job) {}

    static void schedule(Callable<String> job) {}

    static void run() {
        schedule(() -> "report");
    }
}
```

```text
AmbiguousOverload.java:10: error: reference to schedule is ambiguous
        schedule(() -> "report");
        ^
  both method schedule(Supplier<String>) in Scheduler and method schedule(Callable<String>) in Scheduler match
1 error
```

Un cast comme `schedule((Supplier<String>) () -> "report")` en choisit une. La meilleure correction consiste à donner des noms différents aux surcharges, comme le fait le JDK avec `comparingInt` et `comparingLong`.

## Références de méthode

Une [référence de méthode](https://docs.oracle.com/javase/tutorial/java/javaOO/methodreferences.html) est l'équivalent d'un groupe de méthodes C#. La forme `::` existe en quatre variantes :

```java
// Les quatre variantes de référence de méthode.
Function<String, Integer> parse = Integer::parseInt;        // méthode statique
Set<String> jvmLanguages = Set.of("java", "kotlin", "scala");
Predicate<String> isJvmLanguage = jvmLanguages::contains;   // liée : jvmLanguages.contains(s)
Function<String, String> upper = String::toUpperCase;       // non liée : s.toUpperCase()
Supplier<List<String>> newList = ArrayList::new;            // constructeur
System.out.println(parse.apply("42") + " " + isJvmLanguage.test("kotlin") + " " + upper.apply("java"));
System.out.println(newList.get().size());
```

```text
42 true JAVA
0
```

La variante *non liée* (unbound) n'a pas d'équivalent en C# : `String::toUpperCase` transforme la méthode d'instance en une fonction dont le premier paramètre est le receveur. C# a besoin d'une lambda, `s => s.ToUpper()`.

## Capture : des valeurs, pas des variables

Une closure C# capture la **variable**. La lambda peut la modifier, et elle voit les modifications ultérieures. Une lambda Java ne peut utiliser que des variables locales *finales ou effectivement finales* (jamais réaffectées), donc en pratique elle capture leurs **valeurs**.

```java
class Clicks {
    static int count() {
        int clicks = 0;
        Runnable click = () -> clicks++;
        click.run();
        return clicks;
    }
}
```

```text
CaptureMutable.java:4: error: local variables referenced from a lambda expression must be final or effectively final
        Runnable click = () -> clicks++;
                               ^
1 error
```

Cette règle élimine un bug C# classique. En C#, une boucle `for` a une seule variable pour toutes les itérations, si bien que les lambdas créées dans la boucle voient toutes sa valeur finale. `foreach` reçoit une nouvelle variable à chaque itération depuis C# 5. Le côté C# affiche :

```text
3 3 3
0 1 2
```

En Java, la version avec la boucle `for` ne compile pas, et la boucle `for` améliorée fonctionne parce que la variable de chaque itération est effectivement finale :

```java
import java.util.ArrayList;
import java.util.List;
import java.util.function.Supplier;

class Loop {
    static List<Supplier<Integer>> suppliers() {
        List<Supplier<Integer>> result = new ArrayList<>();
        for (int i = 0; i < 3; i++) {
            result.add(() -> i);
        }
        return result;
    }
}
```

```text
CaptureLoopIndex.java:9: error: local variables referenced from a lambda expression must be final or effectively final
            result.add(() -> i);
                             ^
1 error
```

```java
// Chaque itération d'une boucle for améliorée a sa propre variable effectivement finale.
List<Supplier<Integer>> suppliers = new ArrayList<>();
for (int value : new int[] {0, 1, 2}) {
    suppliers.add(() -> value);
}
System.out.println(suppliers.stream().map(Supplier::get).toList());
```

```text
[0, 1, 2]
```

Quand une lambda doit vraiment modifier un état, capturez un objet mutable plutôt qu'une variable locale. [`AtomicInteger`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/atomic/AtomicInteger.html) est le choix habituel, et il est en plus sûr entre threads. La règle ne s'applique qu'aux variables locales : les champs peuvent être lus et écrits librement, parce que la lambda capture `this`.

```java
// Les lambdas capturent des valeurs, pas des variables : un état mutable demande un objet.
AtomicInteger clicks = new AtomicInteger();
Runnable click = clicks::incrementAndGet;
click.run();
click.run();
System.out.println("clicks: " + clicks.get());
```

```text
clicks: 2
```

Souvent, le besoin disparaît tout simplement : compter ou additionner dans une lambda, c'est généralement un pipeline de stream déguisé (exercice 2 et leçon 7).

### `this` dans une lambda

Avant Java 8, l'équivalent d'une lambda était une *classe anonyme*, et vous en trouverez encore dans du code ancien. Les deux diffèrent sur `this` : dans une lambda, c'est l'instance englobante, comme en C# ; dans une classe anonyme, c'est l'objet anonyme lui-même.

```java
private final String name = "outer";

void showThis() {
    Runnable lambda = () -> System.out.println("lambda this: " + this.name);
    Runnable anonymous = new Runnable() {
        private final String name = "anonymous";

        @Override
        public void run() {
            System.out.println("anonymous this: " + this.name);
        }
    };
    lambda.run();
    anonymous.run();
}
```

```text
lambda this: outer
anonymous this: anonymous
```

## La composition est une fonctionnalité de bibliothèque

C# compose les délégués avec `+` (multicast) et n'a pas de `Compose` intégré. Les interfaces fonctionnelles Java ne prennent pas en charge les opérateurs, et `+` sur deux `Runnable` est une erreur :

```java
class Combine {
    static void run() {
        Runnable hello = () -> System.out.print("hello ");
        Runnable world = () -> System.out.println("world");
        Runnable both = hello + world;
    }
}
```

```text
CombineRunnables.java:5: error: bad operand types for binary operator '+'
        Runnable both = hello + world;
                              ^
  first type:  Runnable
  second type: Runnable
1 error
```

En contrepartie, les interfaces standard portent des méthodes par défaut pour composer des fonctions : `Function.andThen` et `compose`, `Predicate.and`, `or`, `negate` et `Predicate.not`, et tout un builder sur [`Comparator`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Comparator.html) :

```java
// La composition est une fonctionnalité de bibliothèque : des méthodes par défaut sur les interfaces.
UnaryOperator<String> trim = String::strip;
Function<String, Integer> trimmedLength = trim.andThen(String::length);
System.out.println(trimmedLength.apply("  padded  "));
Predicate<String> notBlank = Predicate.not(String::isBlank);
System.out.println(notBlank.and(isJvmLanguage.negate()).test("csharp"));

var people = new ArrayList<>(List.of(new Person("Ada", 36), new Person("Alan", 41), new Person("Grace", 36)));
people.sort(Comparator.comparingInt(Person::age).reversed().thenComparing(Person::name));
System.out.println(people);
```

```text
6
true
[Person[name=Alan, age=41], Person[name=Ada, age=36], Person[name=Grace, age=36]]
```

La chaîne de `Comparator` correspond au `OrderByDescending(p => p.Age).ThenBy(p => p.Name)` de LINQ, appliqué à une liste sur place.

## Pas d'événements : des listes d'écouteurs

Java n'a ni mot-clé `event` ni délégués multicast. Les bibliothèques gardent une liste d'écouteurs (listeners), en général des `Consumer`, et exposent des méthodes d'ajout et de retrait :

```java
static class PriceFeed {
    private final List<Consumer<Double>> listeners = new ArrayList<>();

    void addListener(Consumer<Double> listener) {
        listeners.add(listener);
    }

    boolean removeListener(Consumer<Double> listener) {
        return listeners.remove(listener);
    }

    void publish(double price) {
        listeners.forEach(listener -> listener.accept(price));
    }
}
```

Le piège, c'est le retrait. En C#, `feed.PriceChanged -= display.OnPrice` fonctionne parce que deux délégués ayant la même cible et la même méthode sont égaux. En Java, chaque évaluation de `display::onPrice` crée un nouvel objet, et les lambdas ne redéfinissent pas `equals` :

```java
feed.addListener(display::onPrice);
feed.publish(10.5);

// Chaque évaluation de display::onPrice crée un nouvel objet, et les lambdas ne redéfinissent pas equals.
System.out.println("removed: " + feed.removeListener(display::onPrice));
Consumer<Double> first = display::onPrice;
Consumer<Double> second = display::onPrice;
System.out.println("equal: " + first.equals(second));
feed.publish(11.0);

// Gardez la référence enregistrée si vous voulez la retirer.
Consumer<Double> listener = display::onPrice;
var other = new PriceFeed();
other.addListener(listener);
System.out.println("removed: " + other.removeListener(listener));
other.publish(12.0);
```

```text
display: 10.5
removed: false
equal: false
display: 11.0
removed: true
```

Le côté C# affiche `equal: True`, et l'événement n'a plus aucun écouteur après `-=`. En Java, gardez la référence, ou renvoyez un objet d'abonnement depuis la méthode d'ajout (exercice 3). La [Java Language Specification](https://docs.oracle.com/javase/specs/jls/se25/html/jls-15.html#jls-15.27.4) laisse délibérément non spécifiée l'identité des objets lambda : ne comptez pas non plus sur `==`.

## À retenir

- Une lambda implémente une interface fonctionnelle choisie par le type cible ; il n'y a pas de types fonction, et chaque interface a son propre nom de méthode.
- `java.util.function` couvre les formes courantes, avec des spécialisations primitives pour éviter le boxing.
- Les références de méthode existent en quatre variantes ; la variante non liée (`String::length`) n'a pas d'équivalent en C#.
- Les lambdas ne peuvent utiliser que des variables locales effectivement finales : elles capturent des valeurs, ce qui élimine le bug de capture de la boucle `for` de C#.
- La composition passe par des méthodes par défaut (`andThen`, `negate`, `Comparator.comparing`), pas par des opérateurs.
- Les écouteurs remplacent les événements ; une référence de méthode évaluée deux fois donne deux objets non égaux.

## Exercices

1. Écrivez `pipeline(List<UnaryOperator<String>> steps)` qui renvoie un `UnaryOperator<String>` appliquant les étapes dans l'ordre, et l'identité pour une liste vide. Pourquoi `reduce(UnaryOperator.identity(), (f, g) -> f.andThen(g))` ne compile-t-il pas ?

<details>
<summary>Solution</summary>

```java
static UnaryOperator<String> pipeline(List<UnaryOperator<String>> steps) {
    return steps.stream().reduce(UnaryOperator.identity(), (f, g) -> s -> g.apply(f.apply(s)));
}

UnaryOperator<String> clean = pipeline(List.of(String::strip, String::toLowerCase, s -> s.replace(' ', '-')));
clean.apply("  Hello Java World ");   // "hello-java-world"
```

`andThen` est héritée de `Function` et renvoie une `Function<String, V>`, pas un `UnaryOperator<String>`. `reduce` exige que son accumulateur renvoie le type des éléments, et javac signale « bad return type in lambda expression ». Écrire la composition sous forme de lambda donne à celle-ci le type cible `UnaryOperator<String>`.

</details>

2. Traduisez ce code C# sans `AtomicInteger` :

```csharp
int longWords = 0;
words.ForEach(w => { if (w.Length > 3) longWords++; });
```

<details>
<summary>Solution</summary>

```java
long longWords = words.stream().filter(w -> w.length() > 3).count();
```

La version C# n'a besoin d'une variable capturée mutable que parce qu'elle compte à la main. Un stream exprime directement le comptage, et il n'y a rien à capturer. `count()` renvoie un `long`. Pour `List.of("a", "lambda", "is", "not", "a", "delegate")`, le résultat est `2`.

</details>

3. Modifiez `PriceFeed` pour que `subscribe(Consumer<Double>)` renvoie un objet dont la méthode `close()` retire l'écouteur, et utilisez-le dans un try-with-resources. Pourquoi déclarer une nouvelle interface au lieu de renvoyer un `AutoCloseable` ?

<details>
<summary>Solution</summary>

```java
interface Subscription extends AutoCloseable {
    @Override
    void close(); // pas d'exception vérifiée, contrairement à AutoCloseable.close()
}

static class PriceFeed {
    private final List<Consumer<Double>> listeners = new ArrayList<>();

    Subscription subscribe(Consumer<Double> listener) {
        listeners.add(listener);
        return () -> listeners.remove(listener);
    }

    void publish(double price) {
        List.copyOf(listeners).forEach(listener -> listener.accept(price));
    }
}

try (Subscription subscription = feed.subscribe(received::add)) {
    feed.publish(1.0);
}
feed.publish(2.0);   // received vaut [1.0]
```

La lambda capture l'objet exact qui a été ajouté, donc `remove` le retrouve. `AutoCloseable.close()` déclare `throws Exception`, ce qui forcerait chaque appelant à intercepter `Exception` (leçon 5) ; redéfinir `close()` sans la clause `throws` supprime cette contrainte. `Subscription` est elle-même une interface fonctionnelle, c'est pourquoi la lambda fonctionne. `publish` parcourt une copie pour qu'un écouteur puisse se désabonner pendant qu'il est notifié. C'est le motif `IDisposable` du `Subscribe` de Rx.

</details>

## Sources

- [The Java Tutorials — Lambda expressions](https://docs.oracle.com/javase/tutorial/java/javaOO/lambdaexpressions.html) et [Method references](https://docs.oracle.com/javase/tutorial/java/javaOO/methodreferences.html)
- [JLS §9.8 — Functional interfaces](https://docs.oracle.com/javase/specs/jls/se25/html/jls-9.html#jls-9.8) et [§15.27 — Lambda expressions](https://docs.oracle.com/javase/specs/jls/se25/html/jls-15.html#jls-15.27)
- [Package `java.util.function`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/function/package-summary.html)
- [C# — Expressions lambda](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/lambda-expressions) et [Délégués](https://learn.microsoft.com/dotnet/csharp/programming-guide/delegates/)
