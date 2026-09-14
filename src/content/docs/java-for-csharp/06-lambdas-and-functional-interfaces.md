---
title: 6. Lambdas and functional interfaces
description: Functional interfaces instead of Func and Action, method references, capture of effectively final values, composition, and listener lists instead of events — compared with C# delegates.
sidebar:
  order: 6
---

Full examples: [`lessons/l06`](https://github.com/spareilleux/learn/tree/main/code/java-for-csharp/src/main/java/lessons/l06).

## No delegate types: interfaces with one method

C# has delegate types: `Func<string, int>` is a type in its own right, and since C# 10 a lambda even has a natural type. Java has no function types at all. A lambda is an implementation of a **functional interface**, an interface with exactly one abstract method, and the compiler needs to know which interface from the context: the *target type*.

The JDK provides the common shapes in [`java.util.function`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/function/package-summary.html):

| C# | Java | Method to call |
|---|---|---|
| `Func<T, R>` | [`Function<T, R>`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/function/Function.html) | `apply` |
| `Func<T1, T2, R>` | `BiFunction<T, U, R>` | `apply` |
| `Func<R>` | [`Supplier<T>`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/function/Supplier.html) | `get` |
| `Action<T>` | [`Consumer<T>`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/function/Consumer.html) | `accept` |
| `Action` | [`Runnable`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Runnable.html) | `run` |
| `Predicate<T>` | [`Predicate<T>`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/function/Predicate.html) | `test` |
| `Func<T, T>` | `UnaryOperator<T>` | `apply` |
| `Func<T, T, T>` | `BinaryOperator<T>` | `apply` |
| `Func<string, int>` without boxing | `ToIntFunction<String>`, `IntBinaryOperator`, `IntPredicate`… | `applyAsInt`, `test`… |

There is no `Function3`: beyond two parameters, you declare your own interface. The method name also changes with the interface, so you can't call a lambda variable like a method (`length("abc")` in C#):

```java
// Func<string, int>, Func<int, int, int>, Func<string>, Action<string>, Predicate<string>
Function<String, Integer> length = s -> s.length();
BiFunction<Integer, Integer, Integer> add = (a, b) -> a + b;
Supplier<String> greeting = () -> "hello";
Consumer<String> print = s -> System.out.println("print: " + s);
Predicate<String> isEmpty = s -> s.isEmpty();

// Each interface has its own method name: apply, get, accept, test.
System.out.println(length.apply("lambda") + " " + add.apply(2, 3) + " " + greeting.get());
print.accept("consumer");
System.out.println(isEmpty.test(""));

// Primitive specialisations avoid boxing.
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

Without a target type, a lambda has no type. `var` can't infer one, and `Object` is not a functional interface:

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

The C# side prints ``Func`2`` for `(string s) => s.Length`.

## Your own functional interfaces

Any interface with a single abstract method works as a lambda target, including older ones such as `Runnable`, `Comparator` or `Callable`. Default and static methods don't count. The [`@FunctionalInterface`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/FunctionalInterface.html) annotation is optional, like `@Override`: it asks the compiler to check the rule.

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

Because lambdas are typed by their target, two overloads that take different functional interfaces of the same shape make a call ambiguous. C# has the same problem with delegates, but Java's standard interfaces overlap a lot: `Supplier<String>` and [`Callable<String>`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/Callable.html) both take nothing and return a `String`.

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

A cast such as `schedule((Supplier<String>) () -> "report")` picks one. The better fix is to give the overloads different names, as the JDK does with `comparingInt` and `comparingLong`.

## Method references

A [method reference](https://docs.oracle.com/javase/tutorial/java/javaOO/methodreferences.html) is the counterpart of a C# method group. The `::` form comes in four kinds:

```java
// The four kinds of method reference.
Function<String, Integer> parse = Integer::parseInt;        // static method
Set<String> jvmLanguages = Set.of("java", "kotlin", "scala");
Predicate<String> isJvmLanguage = jvmLanguages::contains;   // bound: jvmLanguages.contains(s)
Function<String, String> upper = String::toUpperCase;       // unbound: s.toUpperCase()
Supplier<List<String>> newList = ArrayList::new;            // constructor
System.out.println(parse.apply("42") + " " + isJvmLanguage.test("kotlin") + " " + upper.apply("java"));
System.out.println(newList.get().size());
```

```text
42 true JAVA
0
```

The *unbound* kind has no C# equivalent: `String::toUpperCase` turns the instance method into a function whose first parameter is the receiver. C# needs a lambda, `s => s.ToUpper()`.

## Capture: values, not variables

A C# closure captures the **variable**. The lambda can modify it, and it sees later changes. A Java lambda can only use local variables that are *final or effectively final* (never reassigned), so in practice it captures their **values**.

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

The rule rules out a classic C# bug. In C#, a `for` loop has one variable for all iterations, so lambdas created in the loop all see its final value. `foreach` gets a fresh variable per iteration since C# 5. The C# side prints:

```text
3 3 3
0 1 2
```

In Java, the `for` loop version doesn't compile, and the enhanced `for` loop works because each iteration's variable is effectively final:

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
// Each iteration of an enhanced for loop has its own effectively final variable.
List<Supplier<Integer>> suppliers = new ArrayList<>();
for (int value : new int[] {0, 1, 2}) {
    suppliers.add(() -> value);
}
System.out.println(suppliers.stream().map(Supplier::get).toList());
```

```text
[0, 1, 2]
```

When a lambda really must update state, capture a mutable object instead of a local. [`AtomicInteger`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/atomic/AtomicInteger.html) is the usual choice, and it is also safe across threads. The rule applies to local variables only: fields can be read and written freely, because the lambda captures `this`.

```java
// Lambdas capture values, not variables: mutable state needs an object.
AtomicInteger clicks = new AtomicInteger();
Runnable click = clicks::incrementAndGet;
click.run();
click.run();
System.out.println("clicks: " + clicks.get());
```

```text
clicks: 2
```

Often the need disappears altogether: counting or summing inside a lambda is usually a stream pipeline in disguise (exercise 2 and lesson 7).

### `this` in a lambda

Before Java 8, the equivalent of a lambda was an *anonymous class*, and you will still find them in older code. The two differ on `this`: in a lambda it is the enclosing instance, as in C#; in an anonymous class it is the anonymous object itself.

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

## Composition is a library feature

C# composes delegates with `+` (multicast) and has no built-in `Compose`. Java functional interfaces don't support operators, and `+` on two `Runnable`s is an error:

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

In exchange, the standard interfaces carry default methods for composing functions: `Function.andThen` and `compose`, `Predicate.and`, `or`, `negate` and `Predicate.not`, and a whole builder on [`Comparator`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Comparator.html):

```java
// Composition is a library feature: default methods on the interfaces.
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

The `Comparator` chain is LINQ's `OrderByDescending(p => p.Age).ThenBy(p => p.Name)`, applied to a list in place.

## No events: listener lists

Java has no `event` keyword and no multicast delegates. Libraries keep a list of listeners, typically `Consumer`s, and expose add and remove methods:

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

The trap is removal. In C#, `feed.PriceChanged -= display.OnPrice` works because two delegates for the same target and method are equal. In Java, each evaluation of `display::onPrice` creates a new object, and lambdas don't override `equals`:

```java
feed.addListener(display::onPrice);
feed.publish(10.5);

// Each evaluation of display::onPrice creates a new object, and lambdas don't override equals.
System.out.println("removed: " + feed.removeListener(display::onPrice));
Consumer<Double> first = display::onPrice;
Consumer<Double> second = display::onPrice;
System.out.println("equal: " + first.equals(second));
feed.publish(11.0);

// Keep the reference you registered if you want to remove it.
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

The C# side prints `equal: True`, and the event has no listener left after `-=`. In Java, keep the reference, or return a subscription object from the add method (exercise 3). The [Java Language Specification](https://docs.oracle.com/javase/specs/jls/se25/html/jls-15.html#jls-15.27.4) deliberately leaves the identity of lambda objects unspecified, so don't rely on `==` either.

## Key takeaways

- A lambda implements a functional interface chosen by the target type; there are no function types, and each interface has its own method name.
- `java.util.function` covers the common shapes, with primitive specialisations to avoid boxing.
- Method references come in four kinds; the unbound one (`String::length`) has no C# equivalent.
- Lambdas can only use effectively final locals: they capture values, which removes C#'s `for` loop capture bug.
- Composition goes through default methods (`andThen`, `negate`, `Comparator.comparing`), not operators.
- Listeners replace events; a method reference evaluated twice gives two unequal objects.

## Exercises

1. Write `pipeline(List<UnaryOperator<String>> steps)` returning a `UnaryOperator<String>` that applies the steps in order, and the identity for an empty list. Why doesn't `reduce(UnaryOperator.identity(), (f, g) -> f.andThen(g))` compile?

<details>
<summary>Solution</summary>

```java
static UnaryOperator<String> pipeline(List<UnaryOperator<String>> steps) {
    return steps.stream().reduce(UnaryOperator.identity(), (f, g) -> s -> g.apply(f.apply(s)));
}

UnaryOperator<String> clean = pipeline(List.of(String::strip, String::toLowerCase, s -> s.replace(' ', '-')));
clean.apply("  Hello Java World ");   // "hello-java-world"
```

`andThen` is inherited from `Function` and returns a `Function<String, V>`, not a `UnaryOperator<String>`. `reduce` needs its accumulator to return the element type, and javac reports "bad return type in lambda expression". Writing the composition as a lambda makes its target type `UnaryOperator<String>`.

</details>

2. Translate this C# code without an `AtomicInteger`:

```csharp
int longWords = 0;
words.ForEach(w => { if (w.Length > 3) longWords++; });
```

<details>
<summary>Solution</summary>

```java
long longWords = words.stream().filter(w -> w.length() > 3).count();
```

The C# version needs a mutable captured variable only because it counts by hand. A stream expresses the count directly, and there is nothing to capture. `count()` returns a `long`. For `List.of("a", "lambda", "is", "not", "a", "delegate")` the result is `2`.

</details>

3. Change `PriceFeed` so that `subscribe(Consumer<Double>)` returns an object whose `close()` removes the listener, and use it in a try-with-resources. Why declare a new interface instead of returning `AutoCloseable`?

<details>
<summary>Solution</summary>

```java
interface Subscription extends AutoCloseable {
    @Override
    void close(); // no checked exception, unlike AutoCloseable.close()
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
feed.publish(2.0);   // received is [1.0]
```

The lambda captures the exact object that was added, so `remove` finds it. `AutoCloseable.close()` declares `throws Exception`, which would force every caller to catch `Exception` (lesson 5); overriding `close()` without the `throws` clause removes that. `Subscription` is itself a functional interface, which is why the lambda works. `publish` iterates over a copy so that a listener can unsubscribe while being notified. It is the `IDisposable` pattern of Rx's `Subscribe`.

</details>

## Sources

- [The Java Tutorials — Lambda expressions](https://docs.oracle.com/javase/tutorial/java/javaOO/lambdaexpressions.html) and [Method references](https://docs.oracle.com/javase/tutorial/java/javaOO/methodreferences.html)
- [JLS §9.8 — Functional interfaces](https://docs.oracle.com/javase/specs/jls/se25/html/jls-9.html#jls-9.8) and [§15.27 — Lambda expressions](https://docs.oracle.com/javase/specs/jls/se25/html/jls-15.html#jls-15.27)
- [`java.util.function` package](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/function/package-summary.html)
- [C# — Lambda expressions](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/lambda-expressions) and [Delegates](https://learn.microsoft.com/dotnet/csharp/programming-guide/delegates/)
