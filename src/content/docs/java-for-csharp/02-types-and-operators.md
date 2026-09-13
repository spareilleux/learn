---
title: 2. Types, equality and operators
description: Primitives and boxing, no unsigned types, silent overflow, == on objects, var and final, text blocks and switch expressions — compared with C#.
sidebar:
  order: 2
---

Full examples: [`lessons/l02`](https://github.com/spareilleux/learn/tree/main/code/java-for-csharp/src/main/java/lessons/l02) — after `mvn compile`, run one with `java -cp target/classes lessons.l02.Numbers`; CI checks every output below.

## Two kinds of types, and no `struct`

| | C# | Java |
|---|---|---|
| Built-in value types | `int`, `long`, `double`, `bool`, `char`, `decimal`… | 8 [primitive types](https://docs.oracle.com/javase/specs/jls/se25/html/jls-4.html#jls-4.2): `byte short int long float double boolean char` |
| User-defined value types | `struct`, `record struct` | none (see [Project Valhalla](https://openjdk.org/projects/valhalla/)) |
| Everything else | reference types | reference types |
| Unsigned integers | `byte`, `ushort`, `uint`, `ulong` | none |
| Decimal arithmetic | `decimal` | the [`BigDecimal`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/math/BigDecimal.html) class |
| Primitive in an object context | boxing to `object` | boxing to a *wrapper class*: `Integer`, `Long`, `Boolean`… |

In C#, `int` *is* `System.Int32`, a struct with methods. In Java, `int` is a primitive with no methods, and `Integer` is a separate class. The compiler converts between them automatically ([autoboxing](https://docs.oracle.com/javase/tutorial/java/data/autoboxing.html)), which is convenient until it isn't.

## Numbers

```java
int max = Integer.MAX_VALUE;
System.out.println(max + 1);

try {
    System.out.println(Math.addExact(max, 1));
} catch (ArithmeticException e) {
    System.out.println("ArithmeticException: " + e.getMessage());
}

byte b = (byte) 200;
System.out.println(b);
System.out.println(Byte.toUnsignedInt(b));

int allOnes = -1;
System.out.println(Integer.toUnsignedString(allOnes));
System.out.println(Integer.divideUnsigned(allOnes, 2));
```

```text
-2147483648
ArithmeticException: integer overflow
-56
200
4294967295
2147483647
```

- **Overflow wraps silently**, exactly like C# in its default `unchecked` context. Java has no `checked` keyword: [`Math.addExact`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Math.html#addExact(int,int)), `multiplyExact` and friends throw instead.
- **`byte` is signed** (−128 to 127). Reading bytes from a file or a network buffer is where this bites: `(byte) 200` is `-56`, and `Byte.toUnsignedInt` gives you the 200 back. In C#, `byte` is unsigned and `sbyte` is the signed one.
- **No `uint` or `ulong`**, but `Integer` and `Long` have static methods that *interpret* the same bits as unsigned.

The C# side, run by the course's CI:

```text
-2147483648
OverflowException: Arithmetic operation resulted in an overflow.
200
-56
```

Division and `char` arithmetic behave the same in both languages: integer division by zero throws (`ArithmeticException: / by zero` vs `DivideByZeroException`), floating-point division gives `Infinity`, and `'a' + 1` is the `int` 98.

## `==` compares references for objects

This is the one to remember. For primitives, `==` compares values. For objects — including `Integer` and `String` — it compares **references**, and Java has no operator overloading to change that.

```java
Integer a = 127;
Integer b = 127;
Integer c = 128;
Integer d = 128;
System.out.println(a == b);
System.out.println(c == d);
System.out.println(c.equals(d));

String literal = "hello";
String sameLiteral = "hello";
String built = new StringBuilder("hel").append("lo").toString();
System.out.println(literal == sameLiteral);
System.out.println(literal == built);
System.out.println(literal.equals(built));
```

```text
true
false
true
true
false
true
```

- `a == b` is `true` only because autoboxing goes through [`Integer.valueOf`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Integer.html#valueOf(int)), which caches the values −128 to 127. From 128 on, each boxing creates a new object. Code that compares `Integer`s with `==` passes every test with small IDs and fails in production.
- Two identical string literals are the same object (literals are *interned*), but a string built at run time is not.
- **Use `equals`** for objects, always. [`Objects.equals(x, y)`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Objects.html#equals(java.lang.Object,java.lang.Object)) also handles `null`.

In C#, `string` overloads `==` to compare contents, so `literal == built` is `True`. Boxed values compared as `object` behave like Java's, but you rarely write that in C#:

```csharp
object boxedA = 127, boxedB = 127;
Console.WriteLine(boxedA == boxedB);        // False: reference comparison on object

string literal = "hello";
string built = new System.Text.StringBuilder("hel").Append("lo").ToString();
Console.WriteLine(literal == built);         // True: string overloads ==
```

Boxing also brings `null` into arithmetic. Unboxing a `null` `Integer` throws, and since Java 14 the message says exactly which variable was null ([helpful NullPointerExceptions](https://openjdk.org/jeps/358)):

```java
Integer missing = null;
int value = missing;
```

```text
NullPointerException: Cannot invoke "java.lang.Integer.intValue()" because "missing" is null
```

## `var` and `final`

```java
var name = "Ada";          // inferred as String
final var year = 1843;     // cannot be reassigned; C# has no equivalent for locals
```

[`var`](https://docs.oracle.com/en/java/javase/25/language/local-variable-type-inference.html) works like C#'s, but only for **local variables** with an initializer:

```java
class VarField {
    var count = 0;
}
```

```text
VarField.java:2: error: 'var' is not allowed here
    var count = 0;
    ^
1 error
```

`final` on a local or a field means "assigned exactly once" — C#'s `readonly` for fields, and something C# has no keyword for on locals. There is no `const`: a constant is a `static final` field.

```java
class ReassignFinal {
    void run() {
        final int limit = 10;
        limit = 20;
    }
}
```

```text
ReassignFinal.java:4: error: cannot assign a value to final variable limit
        limit = 20;
        ^
1 error
```

## Conversions are as strict as in C#

Narrowing needs a cast, `int` is not a `boolean`, and a local must be definitely assigned before use. The rules match C#'s almost one for one:

```java
class LossyConversion {
    void run() {
        double price = 3.5;
        int rounded = price;
    }
}
```

```text
LossyConversion.java:4: error: incompatible types: possible lossy conversion from double to int
        int rounded = price;
                      ^
1 error
```

```java
class Unassigned {
    int run(boolean flag) {
        int result;
        if (flag) {
            result = 1;
        }
        return result;
    }
}
```

```text
Unassigned.java:7: error: variable result might not have been initialized
        return result;
               ^
1 error
```

## Strings: formatting and text blocks

Java has no string interpolation. [String templates](https://openjdk.org/jeps/465) were previewed in Java 21 and 22, then withdrawn. You format with [`String.formatted`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/String.html#formatted(java.lang.Object...)) (or `String.format`), using `printf`-style specifiers:

```java
System.out.println("%s published her notes in %d.".formatted(name, year));
```

```text
Ada published her notes in 1843.
```

[Text blocks](https://docs.oracle.com/en/java/javase/25/text-blocks/index.html) are Java's multi-line strings, close to C# raw string literals. The closing `"""` sets the indentation to strip:

```java
String json = """
        {
          "name": "%s",
          "year": %d
        }
        """.formatted(name, year);
System.out.print(json);
```

```text
{
  "name": "Ada",
  "year": 1843
}
```

## `switch` expressions

Arrow-form [`switch`](https://docs.oracle.com/en/java/javase/25/language/switch-expressions-and-statements.html) is an expression, like C#'s `switch` expression, and never falls through. A block that computes the value ends with `yield`:

```java
var size = Size.MEDIUM;
int price = switch (size) {
    case SMALL -> 3;
    case MEDIUM -> 4;
    case LARGE -> {
        int base = 4;
        yield base + 1;
    }
};
```

A `switch` over an enum that lists every constant needs no `default`. Over an `int` it does, and Java makes it an error where C# only warns (CS8509):

```java
class SwitchNotExhaustive {
    String describe(int code) {
        return switch (code) {
            case 200 -> "OK";
            case 404 -> "Not Found";
        };
    }
}
```

```text
SwitchNotExhaustive.java:3: error: the switch expression does not cover all possible input values
        return switch (code) {
               ^
1 error
```

Lesson 8 takes `switch` further, with patterns and sealed types.

## Key takeaways

- Java has eight primitives and no user-defined value types; everything else is a reference.
- `==` on objects compares references: use `equals`. The `Integer` cache makes `==` look right for small numbers.
- Overflow is silent; `Math.*Exact` is the `checked` equivalent. `byte` is signed and there are no unsigned types.
- `var` is for locals only; `final` means assigned once; constants are `static final`.
- No interpolation: `formatted`, text blocks, and `switch` expressions with `->` and `yield`.

## Exercises

1. Without running it, predict the output. Then explain how to fix the method.

```java
static boolean sameId(Integer left, Integer right) {
    return left == right;
}
// sameId(42, 42)   → ?
// sameId(1000, 1000) → ?
```

<details>
<summary>Solution</summary>

`true`, then `false`: 42 is inside the `Integer` cache, so both arguments box to the same object; 1000 is not, so they are two objects. Compare values with `left.equals(right)`, or `Objects.equals(left, right)` if either may be `null`. If `null` is not a valid ID, the best fix is to declare the parameters as `int`.

</details>

2. A C# method reads a length as a `uint` from a binary header. Write the Java equivalent of `uint length = BitConverter.ToUInt32(bytes, 0);` for a little-endian `byte[]`, returning a value that can hold every `uint`.

<details>
<summary>Solution</summary>

```java
static long readUInt32LittleEndian(byte[] bytes) {
    return java.nio.ByteBuffer.wrap(bytes, 0, 4)
            .order(java.nio.ByteOrder.LITTLE_ENDIAN)
            .getInt() & 0xFFFFFFFFL;
}
```

`getInt()` returns a signed `int`; masking with `0xFFFFFFFFL` widens it to a `long` without sign extension (`Integer.toUnsignedLong` does the same). `ByteBuffer` is big-endian by default, unlike `BitConverter` on x86, hence the explicit `order`.

</details>

3. Rewrite this C# method in Java, keeping it an expression:

```csharp
static string Classify(int status) => status switch
{
    >= 200 and < 300 => "success",
    404 => "not found",
    _ => "other",
};
```

<details>
<summary>Solution</summary>

```java
static String classify(int status) {
    return switch (status) {
        case 404 -> "not found";
        default -> status >= 200 && status < 300 ? "success" : "other";
    };
}
```

Java 25 has no relational patterns like `>= 200 and < 300` on primitives (primitive patterns are [still in preview](https://openjdk.org/jeps/507)), so the range check moves into the `default` branch — or the whole method becomes an `if` chain.

</details>

## Sources

- [JLS §4.2 — Primitive types and values](https://docs.oracle.com/javase/specs/jls/se25/html/jls-4.html#jls-4.2) and [§5.1.7 — Boxing conversion](https://docs.oracle.com/javase/specs/jls/se25/html/jls-5.html#jls-5.1.7) (which requires the −128 to 127 cache)
- [JLS §15.21 — Equality operators](https://docs.oracle.com/javase/specs/jls/se25/html/jls-15.html#jls-15.21)
- [Oracle — Programmer's Guide to Text Blocks](https://docs.oracle.com/en/java/javase/25/text-blocks/index.html)
- [JEP 361 — Switch expressions](https://openjdk.org/jeps/361)
- [C# — Checked and unchecked statements](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/checked-and-unchecked)
