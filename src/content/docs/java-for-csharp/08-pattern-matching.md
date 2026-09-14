---
title: 8. Pattern matching
description: instanceof and switch patterns, record deconstruction, sealed exhaustiveness, guards, null cases and unnamed variables — and the C# property, relational and list patterns Java doesn't have.
sidebar:
  order: 8
---

Full examples: [`lessons/l08`](https://github.com/spareilleux/learn/tree/main/code/java-for-csharp/src/main/java/lessons/l08).

## Two languages converging

Pattern matching arrived in both languages in stages: C# from version 7 (2017), Java from 16 (2021). In Java 25 the final features are type patterns in `instanceof` and `switch`, record patterns, guards with `when`, `case null` and unnamed variables `_`. They cover the same ground as C#'s type, positional and discard patterns. C# goes further with property, relational, logical and list patterns, which Java expresses with guards.

| C# | Java 25 |
|---|---|
| `o is string s` | `o instanceof String s` |
| `switch` expression with `=>` | `switch` expression with `->` |
| positional pattern `Point(var x, var y)` | [record pattern](https://openjdk.org/jeps/440) `Point(var x, var y)` |
| `case Circle c when c.Radius == 0` | `case Circle c when c.radius() == 0` |
| discard `_` | [unnamed variable](https://openjdk.org/jeps/456) `_` (Java 22) |
| `null` pattern | `case null` |
| property pattern `{ Total: > 1000 }` | *none*: record pattern plus guard |
| relational `< 0`, logical `and`, `or`, `not` | *none*: guard |
| list pattern `[var first, .., var last]` | *none* |
| exhaustiveness warning CS8509 | exhaustiveness **error** for `switch` expressions |

## `instanceof` with a binding

The first step replaces the check-then-cast pair, like C#'s `is` with a declaration:

```java
Object value = "matched";
if (value instanceof String s && s.length() > 3) {
    System.out.println("long string: " + s);
}
```

```text
long string: matched
```

The pattern variable is in scope wherever the compiler can prove the match succeeded, including after a negated test that returns early:

```java
static int lengthOrZero(Object value) {
    // The pattern variable is in scope wherever the match is certain.
    if (!(value instanceof String text)) {
        return 0;
    }
    return text.length();
}
```

Where the match isn't certain, the variable doesn't exist. With `||`, `s` might not be bound:

```java
class Scope {
    static int length(Object value) {
        if (value instanceof String s || value == null) {
            return s.length();
        }
        return 0;
    }
}
```

```text
PatternScope.java:4: error: cannot find symbol
            return s.length();
                   ^
  symbol:   variable s
  location: class Scope
1 error
```

C# reports CS0165, "use of unassigned local variable", for the same code: the variable is declared but not definitely assigned. The rule is the same; only the message differs.

## `switch` over any type

A [pattern `switch`](https://docs.oracle.com/en/java/javase/25/language/pattern-matching-switch.html) accepts any reference type, and cases are tested from top to bottom:

```java
static String classify(Object value) {
    return switch (value) {
        case null -> "null";
        case Integer i when i < 0 -> "negative int " + i;
        case Integer i -> "int " + i;
        case String s when s.isBlank() -> "blank string";
        case String s -> "string of length " + s.length();
        case int[] array -> "int array of length " + array.length;
        case List<?> list -> "list of " + list.size();
        default -> "something else: " + value.getClass().getSimpleName();
    };
}
```

```text
null
negative int -4
int 42
blank string
string of length 7
int array of length 3
list of 2
something else: Double
```

Three details differ from C#:

- **`null`.** A `switch` without `case null` throws `NullPointerException` on a `null` input, even with a `default`. That is the pre-patterns behaviour, kept for compatibility. C# simply falls through to `_`.
- **Guards test what C# puts in the pattern.** `Integer i when i < 0` is C#'s `int i and < 0`. There are no relational patterns, so a guard is always the answer.
- **Generics are erased** (lesson 4). `case List<?> list` is allowed, but `case List<String> list` on an `Object` is not: the element type can't be checked.

The compiler rejects a case that can never match because an earlier one catches everything it would:

```java
class Texts {
    static String kind(Object value) {
        return switch (value) {
            case CharSequence cs -> "text";
            case String s -> "string";
            default -> "other";
        };
    }
}
```

```text
DominatedCase.java:5: error: this case label is dominated by a preceding case label
            case String s -> "string";
                 ^
1 error
```

C# reports the same mistake in a switch expression as error CS8510, "The pattern has already been handled by a previous arm of the switch expression". Java also refuses a `default` next to a pattern that already matches everything:

```java
class Anything {
    static String describe(Object value) {
        return switch (value) {
            case String s -> "string";
            case Object o -> "object";
            default -> "unreachable";
        };
    }
}
```

```text
DefaultAndUnconditional.java:6: error: switch has both an unconditional pattern and a default label
            default -> "unreachable";
            ^
1 error
```

Enum switches were already exhaustive without patterns, and several constants can share one case:

```java
static String color(Suit suit) {
    // Several constants in one case, and no default: the enum switch is exhaustive.
    return switch (suit) {
        case HEARTS, DIAMONDS -> "red";
        case CLUBS, SPADES -> "black";
    };
}
```

```text
red black
```

## Sealed hierarchies and record patterns

Patterns pay off with the sealed interfaces and records of lesson 3. A **record pattern** deconstructs a record into its components and nests to any depth. With a sealed interface, the compiler knows every subtype, so the `switch` needs no `default`:

```java
record Point(double x, double y) {}

sealed interface Shape permits Circle, Rectangle, Triangle {}

record Circle(Point center, double radius) implements Shape {}

record Rectangle(Point topLeft, Point bottomRight) implements Shape {}

record Triangle(Point a, Point b, Point c) implements Shape {}

// No default branch: the compiler knows the three permitted subtypes.
static double area(Shape shape) {
    return switch (shape) {
        case Circle(Point _, double r) -> Math.PI * r * r;
        case Rectangle(Point(var x1, var y1), Point(var x2, var y2)) -> Math.abs(x2 - x1) * Math.abs(y2 - y1);
        case Triangle(Point a, Point b, Point c) ->
            Math.abs((b.x() - a.x()) * (c.y() - a.y()) - (c.x() - a.x()) * (b.y() - a.y())) / 2;
    };
}

// Guards refine a case with a boolean condition.
static String describe(Shape shape) {
    return switch (shape) {
        case Circle c when c.radius() == 0 -> "a point";
        case Circle c -> "a circle of radius " + c.radius();
        case Rectangle(Point(var x1, var y1), Point(var x2, var y2)) when x2 - x1 == y2 - y1 -> "a square";
        case Rectangle r -> "a rectangle";
        case Triangle t -> "a triangle";
    };
}
```

```text
a circle of radius 1.0   3.14
a point                  0.00
a square                 9.00
a rectangle              8.00
a triangle               6.00
```

Deconstruction follows the record's component order, and the component types can be written out or replaced with `var`. `Point _` ignores a component. Only records can be deconstructed: Java has no counterpart to C#'s `Deconstruct` method for ordinary classes.

This is where Java is stricter than C#. Add a subtype and forget a case, and C# gives warning CS8509, then throws `SwitchExpressionException` at run time. For a `switch` expression, Java refuses to compile:

```java
sealed interface Payment permits Card, Transfer, Voucher {}

record Card(String number) implements Payment {}

record Transfer(String iban) implements Payment {}

record Voucher(String code) implements Payment {}

class Fees {
    static double fee(Payment payment) {
        return switch (payment) {
            case Card c -> 0.30;
            case Transfer t -> 0.0;
        };
    }
}
```

```text
MissingPermittedCase.java:11: error: the switch expression does not cover all possible input values
        return switch (payment) {
               ^
1 error
```

The message doesn't name the missing `Voucher`; IntelliJ IDEA's quick fix does. For this reason, a sealed hierarchy switch is better written **without** `default`: adding a subtype then breaks the build at every place that must handle it. C# developers get the same effect by treating CS8509 as an error.

## What C# patterns become in Java

C#'s property, relational and logical patterns have no syntax in Java. Writing them is a parse error, and the messages don't explain why:

```java
class Signs {
    static String sign(int n) {
        return switch (n) {
            case < 0 -> "negative";
            case 0 -> "zero";
            default -> "positive";
        };
    }
}
```

```text
RelationalPattern.java:4: error: illegal start of type
            case < 0 -> "negative";
                   ^
RelationalPattern.java:4: error: ';' expected
            case < 0 -> "negative";
                    ^
2 errors
```

```java
record Point(int x, int y) {}

class Origins {
    static boolean onXAxis(Object o) {
        return o instanceof Point { y: 0 };
    }
}
```

```text
PropertyPattern.java:5: error: ';' expected
        return o instanceof Point { y: 0 };
                                 ^
PropertyPattern.java:5: error: not a statement
        return o instanceof Point { y: 0 };
                                       ^
PropertyPattern.java:5: error: ';' expected
        return o instanceof Point { y: 0 };
                                        ^
3 errors
```

The translation is a record pattern (or a type pattern) plus a guard: `o instanceof Point(var _, var y) && y == 0`. For list patterns, test the size and index the list. The C# side prints the result of the patterns this section is about:

```csharp
static string Size(Order order) => order switch
{
    { Items.Count: 0 } => "empty",
    { Total: > 1000 } => "large",
    { Customer: "ada" or "alan", Total: >= 100 and <= 1000 } => "regular customer",
    _ => "normal",
};
```

Exercise 2 translates this method.

### Primitive patterns are still a preview

A `switch` on an `int` accepts constants, but not type patterns such as `byte b` ("does it fit in a byte?"). [JEP 507](https://openjdk.org/jeps/507) adds them, but in Java 25 they are still a preview feature:

```java
class Bytes {
    static String fits(int value) {
        return switch (value) {
            case byte b -> "fits in a byte";
            default -> "needs an int";
        };
    }
}
```

```text
PrimitivePattern.java:4: error: primitive patterns are a preview feature and are disabled by default.
            case byte b -> "fits in a byte";
                 ^
  (use --enable-preview to enable primitive patterns)
1 error
```

Preview features need `--enable-preview` at both compile time and run time, and they can change before becoming final. This course doesn't use them.

## Unnamed variables

Since Java 22, `_` marks a variable you must declare but don't use: in patterns, lambda parameters, `catch` clauses and `for` loops. It is C#'s discard:

```java
// Unnamed variables (Java 22): _ for what you don't use.
Map<String, Integer> scores = Map.of("ada", 3);
scores.forEach((_, score) -> System.out.println("score " + score));
try {
    Integer.parseInt("x");
} catch (NumberFormatException _) {
    System.out.println("not a number");
}
```

```text
score 3
not a number
```

## Key takeaways

- `instanceof T t` and `switch` patterns replace casts; pattern variables exist only where the match is certain.
- A `switch` expression over a sealed type or an enum must be exhaustive, and it is a compile error, not a warning. Leave out `default` so new subtypes break the build.
- Record patterns deconstruct and nest; only records can be deconstructed.
- No property, relational, logical or list patterns: use a guard (`when`).
- `case null` must be explicit, or the `switch` throws. Dominated cases and `default` next to an unconditional pattern are errors.
- Primitive type patterns are still in preview in Java 25.

## Exercises

1. Model arithmetic expressions as a sealed interface `Expr` with records `Num(int)`, `Add(Expr, Expr)`, `Mul(Expr, Expr)` and `Neg(Expr)`. Write `eval`, then `simplify`, which removes `1 *`, `* 1`, `0 +` and double negation, recursively.

<details>
<summary>Solution</summary>

```java
sealed interface Expr permits Num, Add, Mul, Neg {}

record Num(int value) implements Expr {}

record Add(Expr left, Expr right) implements Expr {}

record Mul(Expr left, Expr right) implements Expr {}

record Neg(Expr operand) implements Expr {}

static int eval(Expr expr) {
    return switch (expr) {
        case Num(int value) -> value;
        case Add(Expr l, Expr r) -> eval(l) + eval(r);
        case Mul(Expr l, Expr r) -> eval(l) * eval(r);
        case Neg(Expr e) -> -eval(e);
    };
}

static Expr simplify(Expr expr) {
    return switch (expr) {
        case Mul(Num(int one), Expr e) when one == 1 -> simplify(e);
        case Mul(Expr e, Num(int one)) when one == 1 -> simplify(e);
        case Add(Num(int zero), Expr e) when zero == 0 -> simplify(e);
        case Neg(Neg(Expr e)) -> simplify(e);
        case Add(Expr l, Expr r) -> new Add(simplify(l), simplify(r));
        case Mul(Expr l, Expr r) -> new Mul(simplify(l), simplify(r));
        case Neg(Expr e) -> new Neg(simplify(e));
        case Num n -> n;
    };
}
```

`simplify(new Add(new Num(0), new Mul(new Num(1), new Neg(new Neg(new Num(7))))))` returns `Num[value=7]`. Java has no constant patterns inside a record pattern (C#'s `Mul(Num(1), var e)`), so the `1` becomes a guard. The specific cases come before the general `Add`, `Mul` and `Neg` cases. Records compare by value, so the test can check the result with `equals`.

</details>

2. Translate the C# `Size` method from the section on C# patterns, using records `Order(String customer, double total, List<String> items)`.

<details>
<summary>Solution</summary>

```java
static String size(Order order) {
    return switch (order) {
        case Order(var _, var _, var items) when items.isEmpty() -> "empty";
        case Order(var _, var total, var _) when total > 1000 -> "large";
        case Order(var customer, var total, var _)
                when (customer.equals("ada") || customer.equals("alan")) && total >= 100 && total <= 1000 ->
            "regular customer";
        case Order _ -> "normal";
    };
}
```

Each C# property pattern becomes a deconstruction that names the components it needs, plus a guard. `case Order _` is the unconditional last case; `default` would work too. A guard-only chain like this is often clearer as `if` statements, and C#'s version is shorter. This is one place where C# is more expressive.

</details>

3. Model a JSON value as a sealed interface with records `JNull`, `JBool`, `JNumber`, `JString`, `JArray(List<Json>)` and `JObject(Map<String, Json>)`. Write `render(Json)`, which prints whole numbers without a decimal point and escapes quotes in strings.

<details>
<summary>Solution</summary>

```java
static String render(Json json) {
    return switch (json) {
        case JNull _ -> "null";
        case JBool(boolean b) -> String.valueOf(b);
        case JNumber(double d) when d == Math.rint(d) -> String.valueOf((long) d);
        case JNumber(double d) -> String.valueOf(d);
        case JString(String s) -> '"' + s.replace("\"", "\\\"") + '"';
        case JArray(List<Json> items) -> items.stream().map(SolutionsTest::render).collect(Collectors.joining(",", "[", "]"));
        case JObject(Map<String, Json> fields) -> fields.entrySet().stream()
                .map(e -> render(new JString(e.getKey())) + ":" + render(e.getValue()))
                .collect(Collectors.joining(",", "{", "}"));
    };
}
```

An object with `name` = `Ada "Countess"` and `tags` = `[1, 2.5, true, null]` renders as `{"name":"Ada \"Countess\"","tags":[1,2.5,true,null]}` when the map keeps insertion order (`LinkedHashMap`). Adding a `JDate` record to `permits` would make this `switch` fail to compile until it handles the new case, and that is the point of the design. The escaping is deliberately minimal: a real serializer also escapes backslashes and control characters.

</details>

## Sources

- [Java language guide — Pattern matching](https://docs.oracle.com/en/java/javase/25/language/pattern-matching.html)
- [JEP 441 — Pattern matching for switch](https://openjdk.org/jeps/441), [JEP 440 — Record patterns](https://openjdk.org/jeps/440), [JEP 456 — Unnamed variables and patterns](https://openjdk.org/jeps/456), [JEP 507 — Primitive types in patterns (third preview)](https://openjdk.org/jeps/507)
- [C# — Patterns](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/patterns)
