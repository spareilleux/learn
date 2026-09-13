---
title: 4. Generics and type erasure
description: Why List<int>, new T() and typeof(T) don't exist in Java, how wildcards replace in/out variance, and where erased generics fail at run time — compared with C#'s reified generics.
sidebar:
  order: 4
---

Full examples: [`lessons/l04`](https://github.com/spareilleux/learn/tree/main/code/java-for-csharp/src/main/java/lessons/l04).

## Same syntax, different machinery

`List<String>`, generic methods and constraints read almost like C#. The difference is underneath. The CLR **reifies** generics: `List<int>` and `List<string>` are distinct types at run time, and the JIT generates specialised code for value types. Java generics are checked by the compiler and then **erased**: the bytecode only knows `List`, and every `T` becomes its bound (usually `Object`). This kept Java 5 compatible with older class files, and it explains almost everything in this lesson.

```java
List<String> strings = new ArrayList<>();
List<Integer> numbers = new ArrayList<>();
System.out.println(strings.getClass() == numbers.getClass());
System.out.println(strings.getClass().getName());
```

```text
true
java.util.ArrayList
```

The C# side prints `False` for `typeof(List<string>) == typeof(List<int>)`, and ``System.Collections.Generic.List`1[System.Int32]`` for the runtime type.

## What erasure forbids

| C# | Java | Why |
|---|---|---|
| `List<int>` | `List<Integer>` | a type argument must be a reference type |
| `new T()` with `where T : new()` | pass a `Supplier<T>` | there is no `T` at run time to instantiate |
| `typeof(T)` | pass a `Class<T>` | same |
| `new T[n]` | `(T[]) new Object[n]` or `IntFunction<T[]>` | arrays know their element type at run time; `T` doesn't exist |
| `o is List<string>` | `o instanceof List<?>` | the type argument can't be checked |
| overloads `F(List<string>)` and `F(List<int>)` | different method names | both erase to `F(List)` |
| `static T` field in `Cache<T>` | not allowed | there is one class, shared by every `Cache<…>` |

Each of these is a compile error, with messages worth recognising.

```java
import java.util.List;

class Scores {
    List<int> values;
}
```

```text
PrimitiveTypeArgument.java:4: error: unexpected type
    List<int> values;
         ^
  required: reference
  found:    int
1 error
```

```java
class Factory<T> {
    T create() {
        return new T();
    }
}
```

```text
NewT.java:3: error: unexpected type
        return new T();
                   ^
  required: class
  found:    type parameter T
  where T is a type-variable:
    T extends Object declared in class Factory
1 error
```

```java
class Registry<T> {
    String typeName() {
        return T.class.getName();
    }
}
```

```text
ClassLiteralOfT.java:3: error: cannot select from a type variable
        return T.class.getName();
                ^
1 error
```

```java
class Stack<T> {
    private T[] items = new T[16];
}
```

```text
GenericArray.java:2: error: generic array creation
    private T[] items = new T[16];
                        ^
1 error
```

```java
import java.util.List;

class Checks {
    boolean isNames(Object value) {
        return value instanceof List<String>;
    }
}
```

```text
InstanceofGeneric.java:5: error: Object cannot be safely cast to List<String>
        return value instanceof List<String>;
               ^
1 error
```

```java
import java.util.List;

class Printer {
    void print(List<String> names) {
    }

    void print(List<Integer> numbers) {
    }
}
```

```text
SameErasure.java:7: error: name clash: print(List<Integer>) and print(List<String>) have the same erasure
    void print(List<Integer> numbers) {
         ^
1 error
```

```java
class Singleton<T> {
    static T instance;
}
```

```text
StaticT.java:2: error: non-static type variable T cannot be referenced from a static context
    static T instance;
           ^
1 error
```

## The workarounds: pass what erasure removed

When code needs to create a `T` or test for it, the caller passes the missing information explicitly — a factory or a **class token**:

```java
// No `new T()`: pass a factory instead.
static <T> List<T> filled(int count, Supplier<T> factory) {
    var list = new ArrayList<T>();
    for (int i = 0; i < count; i++) {
        list.add(factory.get());
    }
    return list;
}

// No `typeof(T)`: pass a Class<T> token when the type is needed at run time.
static <T> T firstOfType(List<?> items, Class<T> type) {
    for (Object item : items) {
        if (type.isInstance(item)) {
            return type.cast(item);
        }
    }
    return null;
}
```

```java
System.out.println(filled(3, StringBuilder::new).size());
List<Object> mixed = List.of(1, "two", 3.0);
System.out.println(firstOfType(mixed, String.class));
```

```text
3
two
```

You will meet class tokens everywhere in Java libraries: `objectMapper.readValue(json, Order.class)` in Jackson, `context.getBean(OrderService.class)` in Spring. They exist because the library cannot ask `T` what it is.

## Boxing is the price of `List<Integer>`

Every element of a `List<Integer>` is a separate `Integer` object, where a C# `List<int>` stores the values inline. Boxing also creates an overload trap: `List<Integer>` has both `remove(int index)` and `remove(Object value)`.

```java
List<Integer> numbers = new ArrayList<>();
for (int i = 0; i < 5; i++) {
    numbers.add(i * 10);
}

numbers.remove(1);
System.out.println(numbers);
numbers.remove(Integer.valueOf(30));
System.out.println(numbers);
```

```text
[0, 20, 30, 40]
[0, 20, 40]
```

`remove(1)` removed the element *at index 1* (the value 10), not the value 1. For numeric work, the primitive streams `IntStream`, `LongStream` and `DoubleStream` avoid boxing: `IntStream.rangeClosed(1, 100).sum()` is `5050` without allocating a single `Integer`.

## Raw types and heap pollution

A generic type used without type arguments is a **raw type**, kept for pre-Java 5 code. The compiler warns, and it has good reason to:

```java
import java.util.ArrayList;
import java.util.List;

class Legacy {
    void run() {
        List names = new ArrayList();
        names.add("Ada");
    }
}
```

```text
RawType.java:6: warning: [rawtypes] found raw type: List
        List names = new ArrayList();
        ^
  missing type arguments for generic class List<E>
  where E is a type-variable:
    E extends Object declared in interface List
RawType.java:6: warning: [rawtypes] found raw type: ArrayList
        List names = new ArrayList();
                         ^
  missing type arguments for generic class ArrayList<E>
  where E is a type-variable:
    E extends Object declared in class ArrayList
RawType.java:7: warning: [unchecked] unchecked call to add(E) as a member of the raw type List
        names.add("Ada");
                 ^
  where E is a type-variable:
    E extends Object declared in interface List
3 warnings
```

Through a raw reference, anything can go into a `List<String>`. Nothing fails where the wrong value is added; the `ClassCastException` appears later, wherever a `String` is read back:

```java
@SuppressWarnings({"rawtypes", "unchecked"}) // deliberately unsafe: the lesson explains heap pollution
static void pollute(List<String> names) {
    List raw = names;
    raw.add(42);
}
```

```java
var names = new ArrayList<>(List.of("Ada"));
pollute(names);
System.out.println(names.size());
String second = names.get(1);   // the example catches the exception and prints its message
```

```text
2
ClassCastException: class java.lang.Integer cannot be cast to class java.lang.String (java.lang.Integer and java.lang.String are in module java.base of loader 'bootstrap')
```

The cast was inserted by the compiler at `names.get(1)`, where erasure turned `String` back into `Object`. In C#, `List<string>` would have rejected the `Add` itself. Treat `rawtypes` and `unchecked` warnings as errors in new code.

## Variance: use-site wildcards instead of `in` and `out`

In C#, variance is declared **once, on the interface**: `IEnumerable<out T>` is covariant, so an `IEnumerable<string>` *is* an `IEnumerable<object>`. Java has no declaration-site variance. `List<String>` is never a `List<Object>`:

```java
import java.util.ArrayList;
import java.util.List;

class Zoo {
    void run() {
        List<String> names = new ArrayList<>();
        List<Object> objects = names;
    }
}
```

```text
InvariantList.java:7: error: incompatible types: List<String> cannot be converted to List<Object>
        List<Object> objects = names;
                               ^
1 error
```

Instead, each **method** says how it uses its parameter, with a [wildcard](https://docs.oracle.com/javase/tutorial/java/generics/wildcards.html):

```java
// Reads numbers: any List of a subtype of Number is accepted ("producer extends").
static double sum(List<? extends Number> numbers) {
    double total = 0;
    for (Number n : numbers) {
        total += n.doubleValue();
    }
    return total;
}

// Writes integers: any List that can hold an Integer is accepted ("consumer super").
static void addOneTwoThree(List<? super Integer> target) {
    target.add(1);
    target.add(2);
    target.add(3);
}
```

```java
List<Integer> ints = List.of(1, 2, 3);
List<Double> doubles = List.of(1.5, 2.5);
System.out.println(sum(ints) + " " + sum(doubles));

List<Number> numbers = new ArrayList<>();
List<Object> objects = new ArrayList<>();
addOneTwoThree(numbers);
addOneTwoThree(objects);
System.out.println(numbers + " " + objects);
```

```text
6.0 4.0
[1, 2, 3] [1, 2, 3]
```

| C# | Java | Can read `T` | Can add `T` |
|---|---|---|---|
| `IEnumerable<out T>` parameter | `List<? extends T>` | yes | no |
| `IComparer<in T>`, `Action<in T>` | `List<? super T>` | only as `Object` | yes |
| `IList<T>` (invariant) | `List<T>` | yes | yes |

The rule of thumb is **PECS**: *producer `extends`, consumer `super`*. The compiler enforces the "no" cells; its message mentions a *capture* (`CAP#1`), the unknown type the wildcard stands for:

```java
import java.util.List;

class Totals {
    void addZero(List<? extends Number> numbers) {
        numbers.add(0);
    }
}
```

```text
AddToExtends.java:5: error: incompatible types: int cannot be converted to CAP#1
        numbers.add(0);
                    ^
  where CAP#1 is a fresh type-variable:
    CAP#1 extends Number from capture of ? extends Number
Note: Some messages have been simplified; recompile with -Xdiags:verbose to get full output
1 error
```

The `List<? extends Number>` might really be a `List<Double>`, so adding an `Integer` could corrupt it.

Bounds on type parameters use `extends` too, for classes and interfaces alike, and `&` to combine them:

```java
// A bounded type parameter, like `where T : IComparable<T>`.
static <T extends Comparable<? super T>> T max(List<T> items) {
    T best = items.getFirst();
    for (T item : items) {
        if (item.compareTo(best) > 0) {
            best = item;
        }
    }
    return best;
}
```

`max(List.of("pear", "apple", "quince"))` returns `quince`. The `? super T` lets it accept a type whose `compareTo` is inherited from a supertype.

## Arrays are covariant in both languages

Both languages inherited covariant arrays, and both check every store at run time:

```java
Object[] slots = new String[2];
slots[0] = 42;
```

```text
ArrayStoreException: java.lang.Integer
```

The C# side throws `ArrayTypeMismatchException: Attempted to access an element as a type incompatible with the array.` One more reason to prefer `List<T>` in both.

## Key takeaways

- Java checks generics at compile time and erases them: `List<String>` and `List<Integer>` are the same class at run time.
- No primitives as type arguments, no `new T()`, no `T.class`, no generic arrays, no overloads that differ only by type argument.
- Pass a `Supplier<T>` or a `Class<T>` when code needs the type at run time.
- Raw types defeat the type system; the failure shows up later as a `ClassCastException`.
- Variance is chosen per method with `? extends` (read) and `? super` (write) — PECS.

## Exercises

1. Translate this C# method. What must the caller now provide?

```csharp
static T[] Fill<T>(int count) where T : new()
{
    var result = new T[count];
    for (int i = 0; i < count; i++) result[i] = new T();
    return result;
}
```

<details>
<summary>Solution</summary>

```java
static <T> T[] fill(int count, IntFunction<T[]> newArray, Supplier<T> factory) {
    T[] result = newArray.apply(count);
    for (int i = 0; i < count; i++) {
        result[i] = factory.get();
    }
    return result;
}

StringBuilder[] builders = fill(3, StringBuilder[]::new, StringBuilder::new);
```

The caller provides what erasure removed twice: how to create the array (`StringBuilder[]::new`) and how to create an element (`StringBuilder::new`). It is the same pattern as [`Collection.toArray(IntFunction)`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Collection.html#toArray(java.util.function.IntFunction)).

</details>

2. Write the signature of a method `copy` that copies every element of a source list into a destination list, so that copying a `List<Integer>` into a `List<Number>` compiles.

<details>
<summary>Solution</summary>

```java
static <T> void copy(List<? super T> destination, List<? extends T> source) {
    for (T item : source) {
        destination.add(item);
    }
}
```

The source *produces* `T`s (`extends`), the destination *consumes* them (`super`). For `copy(numbers, integers)`, both `T = Integer` and `T = Number` satisfy the bounds, so the call compiles. This is the signature of [`Collections.copy`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Collections.html#copy(java.util.List,java.util.List)).

</details>

3. C# code filters a heterogeneous list with `items.OfType<T>()`. Write `ofType` in Java. Can it select only the `List<String>` elements of a `List<Object>`?

<details>
<summary>Solution</summary>

```java
static <T> List<T> ofType(List<?> items, Class<T> type) {
    return items.stream().filter(type::isInstance).map(type::cast).toList();
}
```

No: the class token for a list is `List.class`, which matches every `List` whatever its elements, and `List<String>.class` does not exist. At run time a `List<String>` and a `List<Integer>` are indistinguishable; you would have to inspect the elements.

</details>

## Sources

- [dev.java — Generics](https://dev.java/learn/generics/) and [Type erasure](https://docs.oracle.com/javase/tutorial/java/generics/erasure.html)
- [JLS §4.6 — Type erasure](https://docs.oracle.com/javase/specs/jls/se25/html/jls-4.html#jls-4.6) and [§4.8 — Raw types](https://docs.oracle.com/javase/specs/jls/se25/html/jls-4.html#jls-4.8)
- [The Java Tutorials — Wildcards](https://docs.oracle.com/javase/tutorial/java/generics/wildcards.html) and [Restrictions on generics](https://docs.oracle.com/javase/tutorial/java/generics/restrictions.html)
- [C# — Covariance and contravariance in generics](https://learn.microsoft.com/dotnet/standard/generics/covariance-and-contravariance)
- [Project Valhalla](https://openjdk.org/projects/valhalla/) — the long-running work on value classes and specialised generics
