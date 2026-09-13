---
title: 3. Classes, records and enums
description: Getters instead of properties, virtual by default, package-private access, records, enums that are classes, and sealed interfaces — compared with C#.
sidebar:
  order: 3
---

Full examples: [`lessons/l03`](https://github.com/spareilleux/learn/tree/main/code/java-for-csharp/src/main/java/lessons/l03).

## Classes: what is missing, what is different

```java
static class Account {
    private final String owner;
    private long balanceCents;

    Account(String owner, long openingCents) {
        if (openingCents < 0) {
            throw new IllegalArgumentException("opening balance must not be negative");
        }
        this.owner = owner;
        this.balanceCents = openingCents;
    }

    String getOwner() {
        return owner;
    }

    long getBalanceCents() {
        return balanceCents;
    }

    void deposit(long cents) {
        balanceCents += cents;
    }

    String describe() {
        return owner + ": " + balanceCents + " cents";
    }
}
```

Coming from C#, four things stand out:

- **No properties.** A field is private and exposed through `getX()`/`setX()` methods, the [JavaBeans](https://docs.oracle.com/javase/tutorial/javabeans/writing/properties.html) convention that frameworks such as Spring and Jackson rely on. Records (below) remove most of this boilerplate.
- **No `readonly`**: a field assigned once is `final`.
- **No object initializers** (`new Account { Owner = "Ada" }`) and **no named or optional arguments**: overloaded constructors or a builder take their place.
- **One public top-level class per file**, and the file must be named after it:

```java
public class Customer {
}
```

```text
WrongFileName.java:1: error: class Customer is public, should be declared in a file named Customer.java
public class Customer {
       ^
1 error
```

C# has no `partial` counterpart either: a class lives in exactly one file.

## Methods are virtual by default

In C#, a method is non-virtual unless marked `virtual`, and a derived class must say `override`. In Java, **every instance method can be overridden** unless it is `final`, `private` or `static`, and `extends` replaces `:`.

```java
static class SavingsAccount extends Account {
    private final int ratePerMille;

    SavingsAccount(String owner, long openingCents, int ratePerMille) {
        super(owner, openingCents);
        this.ratePerMille = ratePerMille;
    }

    @Override
    String describe() {
        return super.describe() + " (savings, " + ratePerMille + " per mille)";
    }
}
```

```java
List<Account> accounts = new ArrayList<>();
accounts.add(new Account("Ada", 10_000));
accounts.add(new SavingsAccount("Grace", 25_000, 15));

for (Account account : accounts) {
    account.deposit(500);
    System.out.println(account.describe());
}
```

```text
Ada: 10500 cents
Grace: 25500 cents (savings, 15 per mille)
```

[`@Override`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Override.html) is an annotation, and it is optional. Without it, a typo silently declares a *new* method. With it, the compiler checks:

```java
class Base {
    String describe() {
        return "base";
    }
}

class Derived extends Base {
    @Override
    String descibe() {
        return "derived";
    }
}
```

```text
MissingOverride.java:8: error: method does not override or implement a method from a supertype
    @Override
    ^
1 error
```

Always write `@Override`. There is no equivalent of C#'s `new` modifier for hiding a method: the C# side of this lesson prints `base` for a hidden method and `derived` for an overridden one, while in Java a method with the same signature always overrides.

## Access modifiers

| C# | Java | Visible to |
|---|---|---|
| `public` | `public` | everyone |
| `private` | `private` | the top-level class and everything nested in it (C# lets a nested class read its outer class's private members, but not the reverse) |
| `protected` | `protected` | subclasses **and the whole package** |
| `internal` | *(no modifier)*, "package-private" | the same **package**, not the same assembly |
| `private protected` | — | |
| default for members: `private` | default: package-private | |

Two traps. Java's `protected` is wider than C#'s, since any class in the same package can use it. And leaving out the modifier does not make a member private: it is visible to the whole package. Accessing it from another package fails:

```java
package other;

import lessons.l03.Accounts;

class PackagePrivate {
    void run() {
        var account = new Accounts.Account("Ada", 100);
    }
}
```

```text
PackagePrivate.java:7: error: Account is not public in Accounts; cannot be accessed from outside package
        var account = new Accounts.Account("Ada", 100);
                                  ^
1 error
```

A package is not an assembly: nothing stops another JAR from declaring classes in your package. Assembly-like encapsulation comes from [modules](https://dev.java/learn/modules/) (lesson 14).

## Records

A [record](https://docs.oracle.com/en/java/javase/25/language/records.html) is a C# `record class` with positional parameters: a final class with private final fields, a constructor, accessors, `equals`, `hashCode` and `toString`.

```java
record Point(int x, int y) {
    Point {
        if (x < 0 || y < 0) {
            throw new IllegalArgumentException("negative coordinate: " + x + ", " + y);
        }
    }

    Point withX(int newX) {
        return new Point(newX, y);
    }

    double length() {
        return Math.sqrt(x * x + y * y);
    }
}
```

```java
var p = new Point(3, 4);
System.out.println(p);
System.out.println(p.x() + " " + p.length());
System.out.println(p.equals(new Point(3, 4)));
System.out.println(p.withX(6));
```

```text
Point[x=3, y=4]
3 5.0
true
Point[x=6, y=4]
```

- The accessor is `x()`, not `getX()` or `X`.
- The **compact constructor** `Point { … }` runs validation before the fields are assigned; there is no need to repeat the parameters.
- **No `with` expressions** yet ([JEP 468](https://openjdk.org/jeps/468) is a candidate, not part of Java 25): write `withX`-style methods by hand.

```java
record Point(int x, int y) {
}

class Moves {
    Point right(Point p) {
        return p with { x = p.x() + 1; };
    }
}
```

```text
WithExpression.java:6: error: ';' expected
        return p with { x = p.x() + 1; };
                ^
WithExpression.java:6: error: not a statement
        return p with { x = p.x() + 1; };
                 ^
WithExpression.java:6: error: ';' expected
        return p with { x = p.x() + 1; };
                     ^
3 errors
```

- Fields are final, so a record cannot mutate itself (`cannot assign a value to final variable x`). But it is only **shallowly** immutable, exactly like a C# record holding a `List<T>`:

```java
var items = new java.util.ArrayList<>(List.of("book"));
var order = new Order("A-1", items);
items.add("pen");
System.out.println(order);
```

```text
Order[id=A-1, items=[book, pen]]
```

For comparison, the C# side prints `Point { X = 3, Y = 4 }` and supports `p with { X = 6 }`.

## `equals` and `hashCode` go together

A class that overrides `equals` must override `hashCode`, or hash-based collections break — the same contract as `Equals`/`GetHashCode` in .NET. javac warns when you forget, with `-Xlint`:

```java
class Tag {
    private final String name;

    Tag(String name) {
        this.name = name;
    }

    @Override
    public boolean equals(Object other) {
        return other instanceof Tag tag && tag.name.equals(name);
    }
}
```

```text
EqualsWithoutHashCode.java:1: warning: [overrides] Class Tag overrides equals, but neither it nor any superclass overrides hashCode method
class Tag {
^
1 warning
```

```java
var tags = new HashSet<Tag>();
tags.add(new Tag("java"));
System.out.println(new Tag("java").equals(new Tag("java")));
System.out.println(tags.contains(new Tag("java")));
```

```text
true
false
```

Records get both methods right for free, which is one more reason to use them for data.

## Enums are classes

A C# `enum` is a named integer: `(Size)42` compiles and runs. A Java [enum](https://docs.oracle.com/javase/tutorial/java/javaOO/enum.html) is a class with a fixed set of instances, which can have fields, constructors and methods — even a different method body per constant.

```java
enum Planet {
    MERCURY(3.303e+23, 2.4397e6),
    EARTH(5.976e+24, 6.37814e6);

    private static final double G = 6.67300E-11;
    private final double mass;
    private final double radius;

    Planet(double mass, double radius) {
        this.mass = mass;
        this.radius = radius;
    }

    double surfaceGravity() {
        return G * mass / (radius * radius);
    }
}

enum Operation {
    PLUS {
        @Override
        int apply(int a, int b) {
            return a + b;
        }
    },
    TIMES {
        @Override
        int apply(int a, int b) {
            return a * b;
        }
    };

    abstract int apply(int a, int b);
}
```

```java
for (Planet planet : Planet.values()) {
    System.out.printf("%s %.2f%n", planet, planet.surfaceGravity());
}
System.out.println(Planet.valueOf("EARTH").ordinal());
System.out.println(Operation.TIMES.apply(6, 7));

var counts = new EnumMap<Planet, Integer>(Planet.class);
counts.put(Planet.EARTH, 8);
System.out.println(counts);

try {
    Planet.valueOf("PLUTO");
} catch (IllegalArgumentException e) {
    System.out.println(e.getMessage());
}
```

```text
MERCURY 3.70
EARTH 9.80
1
42
{EARTH=8}
No enum constant lessons.l03.Enums.Planet.PLUTO
```

There is no way to make an out-of-range value: `new Size()` is a compile error (`enum classes may not be instantiated`), and `valueOf` throws on an unknown name where C#'s `Enum.Parse` would too. The C# side of this lesson shows `(Size)42` printing `42` with `Enum.IsDefined` returning `False`. Instead of `[Flags]`, Java uses an [`EnumSet`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/EnumSet.html), backed by a bit vector (exercise 3).

## Interfaces and sealed hierarchies

Interfaces work like C# 8+ interfaces: abstract methods, `default` methods with a body, `static` methods and `private` helpers. What Java adds is [`sealed`](https://docs.oracle.com/en/java/javase/25/language/sealed-classes-and-interfaces.html) with a `permits` list — a closed set of implementations that C# has no keyword for.

```java
sealed interface Shape permits Circle, Square {
    double area();

    default String describe() {
        return getClass().getSimpleName() + " with area " + String.format("%.1f", area());
    }

    static Shape unitSquare() {
        return new Square(1);
    }
}

record Circle(double radius) implements Shape {
    public double area() {
        return Math.PI * radius * radius;
    }
}

record Square(double side) implements Shape {
    public double area() {
        return side * side;
    }
}
```

```text
Circle with area 3.1
Square with area 4.0
Square with area 1.0
```

A class outside the list cannot join (the file declares its own small `Shape`):

```java
sealed interface Shape permits Circle {
}

record Circle(double radius) implements Shape {
}

record Triangle(double base, double height) implements Shape {
}
```

```text
NotPermitted.java:7: error: class is not allowed to extend sealed class: Shape (as it is not listed in its 'permits' clause)
record Triangle(double base, double height) implements Shape {
^
1 error
```

In lesson 8, `switch` uses the `permits` list to prove that every case is handled.

## Nested classes: `static` matters

A nested class declared `static` is a C# nested class. **Without `static`**, it is an *inner class*: each instance carries a hidden reference to an instance of the enclosing class and can use its fields.

```java
private int created;

class Counter {
    void increment() {
        created++;
    }
}

public static void main(String[] args) {
    var outer = new Shapes();
    Shapes.Counter counter = outer.new Counter();
    counter.increment();
    counter.increment();
    System.out.println(outer.created);   // 2
}
```

Creating one without an outer instance fails, with a message that doesn't mention inner classes:

```java
class Outer {
    class Inner {
    }

    static Inner create() {
        return new Inner();
    }
}
```

```text
InnerFromStatic.java:6: error: non-static variable this cannot be referenced from a static context
        return new Inner();
               ^
1 error
```

The hidden reference also keeps the outer object alive. Make nested classes `static` unless they really need the outer instance.

## No operator overloading, no extension methods

`BigDecimal` has an `add` method, not a `+` operator, and you cannot give it one:

```java
import java.math.BigDecimal;

class Invoice {
    BigDecimal total(BigDecimal net, BigDecimal tax) {
        return net + tax;
    }
}
```

```text
NoOperatorOverloading.java:5: error: bad operand types for binary operator '+'
        return net + tax;
                   ^
  first type:  BigDecimal
  second type: BigDecimal
1 error
```

There are no extension methods either: helpers live in static utility classes (`Collections`, `Objects`, `Strings` in [Guava](https://github.com/google/guava)) and are called as `Objects.requireNonNull(x)`.

## Key takeaways

- Getters and setters instead of properties; records for data.
- Every method is virtual unless `final`; always write `@Override`.
- No modifier means package-private, and `protected` includes the package.
- Records are shallowly immutable and have no `with` expression yet.
- Enums are classes with a fixed set of instances; `EnumSet` replaces `[Flags]`.
- `sealed … permits` closes a hierarchy; non-`static` nested classes capture their outer instance.

## Exercises

1. Translate this C# type into a Java record that rejects an empty name and a negative price:

```csharp
public record Product(string Name, decimal Price)
{
    public string Name { get; } = !string.IsNullOrWhiteSpace(Name) ? Name : throw new ArgumentException("name required");
    public decimal Price { get; } = Price >= 0 ? Price : throw new ArgumentOutOfRangeException(nameof(Price));
}
```

<details>
<summary>Solution</summary>

```java
record Product(String name, BigDecimal price) {
    Product {
        if (name == null || name.isBlank()) {
            throw new IllegalArgumentException("name required");
        }
        if (price.signum() < 0) {
            throw new IllegalArgumentException("price must not be negative");
        }
    }
}
```

`BigDecimal` stands in for `decimal`; `signum()` avoids comparing with `compareTo(BigDecimal.ZERO) < 0`. `isBlank()` is `string.IsNullOrWhiteSpace` without the null check.

</details>

2. Fix `Tag` so that `tags.contains(new Tag("java"))` returns `true`. Then give the one-line alternative.

<details>
<summary>Solution</summary>

```java
@Override
public int hashCode() {
    return name.hashCode();
}
```

`Objects.hash(name)` also works and scales to several fields. The one-line alternative is to make it a record, which generates `equals` and `hashCode` from its components: `record Tag(String name) {}`.

</details>

3. Translate this C# flags enum and its check into Java without using integers:

```csharp
[Flags] enum Permission { Read = 1, Write = 2, Delete = 4 }
var granted = Permission.Read | Permission.Write;
bool canWrite = granted.HasFlag(Permission.Write);
```

<details>
<summary>Solution</summary>

```java
enum Permission { READ, WRITE, DELETE }

EnumSet<Permission> granted = EnumSet.of(Permission.READ, Permission.WRITE);
boolean canWrite = granted.contains(Permission.WRITE);
```

`EnumSet` stores the set as a bit field internally, so it is as compact as `[Flags]`, and a value outside the enum cannot be stored in it.

</details>

## Sources

- [dev.java — Classes and objects](https://dev.java/learn/classes-objects/) and [Records](https://dev.java/learn/records/)
- [JLS §6.6 — Access control](https://docs.oracle.com/javase/specs/jls/se25/html/jls-6.html#jls-6.6)
- [JLS §8.9 — Enum classes](https://docs.oracle.com/javase/specs/jls/se25/html/jls-8.html#jls-8.9)
- [JEP 409 — Sealed classes](https://openjdk.org/jeps/409) and [JEP 395 — Records](https://openjdk.org/jeps/395)
- [`Object.hashCode` contract](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Object.html#hashCode())
