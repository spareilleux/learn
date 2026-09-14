---
title: 5. Exceptions, null and Optional
description: Checked exceptions, multi-catch without filters, try-with-resources and suppressed exceptions, helpful NullPointerException messages, and Optional in place of ?. and ?? — compared with C#.
sidebar:
  order: 5
---

Full examples: [`lessons/l05`](https://github.com/spareilleux/learn/tree/main/code/java-for-csharp/src/main/java/lessons/l05).

## Checked exceptions: the compiler tracks what can fail

In C#, every exception is unchecked: a method's signature doesn't say what it throws, and the compiler never asks you to handle anything. Java splits the [`Throwable`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Throwable.html) hierarchy in two:

| Kind | Classes | Must be caught or declared? | Typical use |
|---|---|---|---|
| checked | [`Exception`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Exception.html) and its subclasses, except `RuntimeException` | yes | failures a correct program must still expect: I/O, network, parsing a file |
| unchecked | [`RuntimeException`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/RuntimeException.html) and its subclasses | no | programming errors: `NullPointerException`, `IllegalArgumentException`, `IndexOutOfBoundsException` |
| unchecked | [`Error`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Error.html) and its subclasses | no | the JVM is in trouble: `OutOfMemoryError`, `StackOverflowError` |

A method that can let a checked exception escape must say so with `throws`. [`Files.readString`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/nio/file/Files.html#readString(java.nio.file.Path)) declares `throws IOException`, so this does not compile:

```java
import java.nio.file.Files;
import java.nio.file.Path;

class Config {
    static String load() {
        return Files.readString(Path.of("app.properties"));
    }
}
```

```text
UnreportedException.java:6: error: unreported exception IOException; must be caught or declared to be thrown
        return Files.readString(Path.of("app.properties"));
                               ^
1 error
```

The two fixes are the ones the message names: catch it, or add `throws IOException` to `load()` and push the decision to its callers. The rules are in [JLS §11.2](https://docs.oracle.com/javase/specs/jls/se25/html/jls-11.html#jls-11.2).

```java
static String readConfig(Path path) throws IOException {
    return Files.readString(path);
}

static int parsePort(String text) {
    // NumberFormatException is unchecked: nothing forces the caller to handle it.
    return Integer.parseInt(text);
}
```

Java libraries use checked exceptions less than they used to. Newer APIs such as `java.time` throw only unchecked exceptions, and most frameworks wrap checked ones. The JDK's I/O, reflection and concurrency APIs are where you will meet them every day.

## Catch blocks: order, multi-catch and no filters

The order rule is the same as C#'s CS0160: a `catch` can't follow one that already handles a supertype.

```java
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

class Reader {
    static String read(Path path) {
        try {
            return Files.readString(path);
        } catch (Exception e) {
            return "";
        } catch (IOException e) {
            return "I/O error";
        }
    }
}
```

```text
CatchOrder.java:11: error: exception IOException has already been caught
        } catch (IOException e) {
          ^
1 error
```

Checked exceptions add a rule C# has no reason to have: catching a checked exception that the `try` body cannot throw is an error.

```java
import java.io.IOException;

class Parser {
    static int parse(String text) {
        try {
            return Integer.parseInt(text);
        } catch (IOException e) {
            return -1;
        }
    }
}
```

```text
NeverThrown.java:7: error: exception IOException is never thrown in body of corresponding try statement
        } catch (IOException e) {
          ^
1 error
```

A **multi-catch** handles several unrelated types in one block. The alternatives must not be subclasses of each other, since the subclass would be redundant:

```java
for (String text : new String[] {"8080", "http"}) {
    try {
        System.out.println("port " + parsePort(text));
    } catch (NumberFormatException | NullPointerException e) {
        System.out.println(e.getClass().getSimpleName() + ": " + e.getMessage());
    }
}
```

```text
port 8080
NumberFormatException: For input string: "http"
```

```java
import java.io.FileNotFoundException;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

class Loader {
    static String load(Path path) {
        try {
            return Files.readString(path);
        } catch (FileNotFoundException | IOException e) {
            return "";
        }
    }
}
```

```text
MulticatchSubclass.java:10: error: Alternatives in a multi-catch statement cannot be related by subclassing
        } catch (FileNotFoundException | IOException e) {
                                         ^
  Alternative FileNotFoundException is a subclass of alternative IOException
1 error
```

Java has no [exception filters](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/exception-handling-statements#a-when-exception-filter). The C# side of this lesson catches with `when (e.Message.Contains("'http'"))`; the same line in Java is a syntax error:

```java
class Filters {
    static int parse(String text) {
        try {
            return Integer.parseInt(text);
        } catch (NumberFormatException e) when (text.isBlank()) {
            return 0;
        }
    }
}
```

```text
ExceptionFilter.java:5: error: '{' expected
        } catch (NumberFormatException e) when (text.isBlank()) {
                                         ^
ExceptionFilter.java:5: error: ';' expected
        } catch (NumberFormatException e) when (text.isBlank()) {
                                                               ^
ExceptionFilter.java:9: error: reached end of file while parsing
}
 ^
3 errors
```

Test inside the `catch` and rethrow what you don't handle. Unlike a filter, this unwinds the stack before the test runs, which mostly matters to debuggers and crash dumps.

## Checked exceptions don't cross lambdas

The functional interfaces of `java.util.function` declare no checked exceptions: [`Function.apply`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/function/Function.html#apply(T)) has no `throws` clause. A lambda that calls `Files.readString` therefore can't be a `Function`:

```java
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;

class Configs {
    static List<String> loadAll(List<Path> paths) {
        return paths.stream().map(path -> Files.readString(path)).toList();
    }
}
```

```text
CheckedInLambda.java:7: error: unreported exception IOException; must be caught or declared to be thrown
        return paths.stream().map(path -> Files.readString(path)).toList();
                                                          ^
1 error
```

This is the daily cost of checked exceptions. The usual answers are a plain loop, or catching inside the lambda and wrapping the exception in an unchecked one. Exercise 1 writes a reusable adapter for the second.

## Wrapping keeps the cause

Wrap with the original exception as the **cause**, like C#'s `innerException`. For `IOException` the JDK provides [`UncheckedIOException`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/io/UncheckedIOException.html):

```java
static String loadOrWrap(Path path) {
    try {
        return readConfig(path);
    } catch (IOException e) {
        // Wrap in an unchecked exception and keep the original as the cause.
        throw new UncheckedIOException("cannot load " + path.getFileName(), e);
    }
}
```

```text
cannot load missing.properties
caused by NoSuchFileException
```

A stack trace printed by the JVM shows the chain as `Caused by:` sections, the counterpart of .NET's `---> ` inner exception lines.

## try-with-resources instead of `using`

A `try` with resources is Java's `using`. The resource must implement [`AutoCloseable`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/AutoCloseable.html) (Java's `IDisposable`). Resources close in reverse order of declaration, before any `catch` or `finally` block of the same statement runs:

```java
record Connection(String name, boolean failOnClose) implements AutoCloseable {
    Connection {
        System.out.println("open " + name);
    }

    @Override
    public void close() {
        System.out.println("close " + name);
        if (failOnClose) {
            throw new IllegalStateException("close failed: " + name);
        }
    }
}

try (var db = new Connection("db", false);
        var cache = new Connection("cache", false)) {
    System.out.println("using " + db.name() + " and " + cache.name());
} finally {
    System.out.println("finally");
}
```

```text
open db
open cache
using db and cache
close cache
close db
finally
```

The two languages differ when the body throws and then closing throws too. Java keeps the body's exception, the one that explains what went wrong, and attaches the other one to it as a [suppressed exception](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Throwable.html#getSuppressed()):

```java
// The body fails, then close fails too: the body's exception wins,
// and the close exception is attached to it instead of replacing it.
try (var db = new Connection("db", true)) {
    throw new IllegalArgumentException("query failed on " + db.name());
} catch (IllegalArgumentException e) {
    System.out.println("caught: " + e.getMessage());
    for (Throwable suppressed : e.getSuppressed()) {
        System.out.println("suppressed: " + suppressed.getMessage());
    }
}
```

```text
open db
close db
caught: query failed on db
suppressed: close failed: db
```

In C#, a `using` is a `try`/`finally`. An exception thrown by `Dispose` replaces the one in flight, and `query failed on db` is lost:

```text
dispose db
caught: dispose failed: db
```

The resource type is checked at compile time. There is no duck typing, and a class with a `close()` method that doesn't implement `AutoCloseable` is rejected:

```java
class Session {
    void end() {}

    static void run() {
        try (var session = new Session()) {
            System.out.println("working");
        }
    }
}
```

```text
NotAutoCloseable.java:5: error: incompatible types: try-with-resources not applicable to variable type
        try (var session = new Session()) {
                 ^
    (Session cannot be converted to AutoCloseable)
1 error
```

`close()` can itself throw a checked exception. [`BufferedReader.close()`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/io/BufferedReader.html#close()) declares `IOException`, so the implicit call needs handling even when the body can't fail:

```java
import java.io.BufferedReader;
import java.io.StringReader;

class FirstLine {
    static String firstLine(String text) {
        try (BufferedReader reader = new BufferedReader(new StringReader(text))) {
            return reader.readLine();
        }
    }
}
```

```text
ImplicitClose.java:6: error: unreported exception IOException; must be caught or declared to be thrown
        try (BufferedReader reader = new BufferedReader(new StringReader(text))) {
                            ^
  exception thrown from implicit call to close() on resource variable 'reader'
ImplicitClose.java:7: error: unreported exception IOException; must be caught or declared to be thrown
            return reader.readLine();
                                  ^
2 errors
```

The full semantics, including the order of closing and suppression, are in [JLS §14.20.3](https://docs.oracle.com/javase/specs/jls/se25/html/jls-14.html#jls-14.20.3).

## Rethrowing and `finally`

A Java exception captures its stack trace when it is **created**, not when it is thrown. `throw e` in a `catch` block therefore keeps the original trace, and Java has no bare `throw;`:

```java
static void failDeep() {
    throw new IllegalStateException("deep failure");
}

static void rethrow() {
    try {
        failDeep();
    } catch (IllegalStateException e) {
        // In Java the stack trace is captured when the exception is created,
        // so "throw e" keeps it. C# needs "throw;" for the same result.
        throw e;
    }
}
```

```text
thrown in failDeep
```

The C# side shows why the C# rule exists. `throw e;` resets the trace to the rethrowing method, and the analyzer reports [CA2200](https://learn.microsoft.com/dotnet/fundamentals/code-analysis/quality-rules/ca2200):

```text
throw e: thrown in RethrowWithVariable
throw;  thrown in FailDeep
```

C# forbids `return` inside `finally` (CS0157). Java allows it, and the `finally` result silently replaces the `try` result, or even an exception in flight. `-Xlint:finally`, included in `-Xlint:all`, warns about it:

```java
class Totals {
    static int total() {
        try {
            return 1;
        } finally {
            return 2;
        }
    }
}
```

```text
FinallyReturn.java:7: warning: [finally] finally clause cannot complete normally
        }
        ^
1 warning
```

`total()` returns `2`. Keep `finally` for cleanup, and prefer try-with-resources when the cleanup is closing something.

## `null`: no nullable reference types

C# 8's [nullable reference types](https://learn.microsoft.com/dotnet/csharp/nullable-references) make `string` and `string?` different types for the compiler. Java has nothing like it. Every reference can be `null`, `javac` gives no warning, and you find out at run time.

What Java does have is a precise message. Since [JEP 358](https://openjdk.org/jeps/358) (Java 14, on by default since 15), a `NullPointerException` names what was `null`:

```java
static Customer lookup(String id) {
    return CUSTOMERS.get(id); // null when the id is unknown
}

System.out.println(lookup("grace").name().length());
```

```text
Cannot invoke "lessons.l05.Nulls$Customer.name()" because the return value of "lessons.l05.Nulls.lookup(String)" is null
```

The same chain in C# (with `!` to silence the nullable warning) gives only `Object reference not set to an instance of an object.`

To fail early, [`Objects.requireNonNull`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Objects.html#requireNonNull(T,java.lang.String)) is the counterpart of `ArgumentNullException.ThrowIfNull`:

```java
new Customer(Objects.requireNonNull(null, "name"), null);
```

```text
requireNonNull: name
```

Static analysis can bring back part of the compile-time checking. [JSpecify](https://jspecify.dev/) standardises `@Nullable` and `@NullMarked` annotations, and tools such as [NullAway](https://github.com/uber/NullAway) enforce them at build time. [Lesson 11](../11-testing/) sets them up and shows NullAway rejecting this kind of code.

## `Optional<T>` in place of `?.` and `??`

[`Optional<T>`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Optional.html) is a container that holds a value or nothing. It is a library class, not language syntax, and its methods cover C#'s null operators:

| C# | Java `Optional` |
|---|---|
| `x?.Property` | `.map(X::property)` |
| `x?.Method()` returning `T?` | `.flatMap(X::method)` returning `Optional` |
| `x ?? fallback` | `.orElse(fallback)` |
| `x ?? Compute()` | `.orElseGet(() -> compute())` |
| `x ?? throw new …` | `.orElseThrow(() -> new …)` |
| `x!` | `.orElseThrow()` — throws `NoSuchElementException` |
| `if (x is { } value)` | `.ifPresent(value -> …)` |

```java
static Optional<Customer> find(String id) {
    return Optional.ofNullable(CUSTOMERS.get(id));
}

// C#: customer?.Address?.City ?? "unknown"
for (String id : new String[] {"ada", "alan", "grace"}) {
    String city = find(id).map(Customer::address).map(Address::city).orElse("unknown");
    System.out.println(id + " -> " + city);
}
```

```text
ada -> London
alan -> unknown
grace -> unknown
```

`map` turns a `null` result into an empty `Optional`, so `alan` (no address) and `grace` (no customer) both fall through to `orElse`. The C# side prints the same three lines with `customers.GetValueOrDefault(id)?.Address?.City ?? "unknown"`.

One difference from `??`: `orElse` is an ordinary method, so its argument is evaluated **before** the call, even when the value is present. Use `orElseGet` when the fallback is expensive or has side effects:

```java
System.out.println("orElse:");
find("ada").map(Customer::name).orElse(defaultCity());
System.out.println("orElseGet:");
find("ada").map(Customer::name).orElseGet(Nulls::defaultCity);
```

```text
orElse:
  computing default city
orElseGet:
```

`Optional` is meant for return values. Its Javadoc says it "is primarily intended for use as a method return type where there is a clear need to represent 'no result,' and where using `null` is likely to cause errors." Don't use it for fields, parameters or collection elements, and never return a `null` `Optional`. For primitives, [`OptionalInt`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/OptionalInt.html), `OptionalLong` and `OptionalDouble` avoid boxing (lesson 4).

## Key takeaways

- Checked exceptions (`Exception` but not `RuntimeException`) must be caught or declared with `throws`; C# has none.
- Multi-catch replaces repeated `catch` blocks; there are no `when` filters.
- Lambdas for `java.util.function` interfaces can't throw checked exceptions: wrap them, for example in `UncheckedIOException`.
- try-with-resources closes in reverse order and keeps the body's exception, adding close failures as suppressed exceptions.
- `throw e` keeps the stack trace; a `return` in `finally` overrides everything.
- No nullable reference types: rely on helpful NPE messages, `requireNonNull`, and `Optional` for return values.

## Exercises

1. Write an adapter `unchecked` so that `paths.stream().map(unchecked(Files::readString)).toList()` compiles. An `IOException` should surface as an `UncheckedIOException` with the original as its cause.

<details>
<summary>Solution</summary>

```java
@FunctionalInterface
interface ThrowingFunction<T, R> {
    R apply(T value) throws Exception;
}

static <T, R> Function<T, R> unchecked(ThrowingFunction<T, R> function) {
    return value -> {
        try {
            return function.apply(value);
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        } catch (RuntimeException e) {
            throw e;
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    };
}
```

`ThrowingFunction` is a functional interface whose method *does* declare `throws Exception`, so `Files::readString` fits it. The `RuntimeException` clause rethrows unchecked exceptions unchanged instead of wrapping them twice. Libraries such as Vavr ship the same idea, but the dozen lines are often simpler than a dependency.

</details>

2. Translate this C# method. Which return type avoids boxing?

```csharp
static int? ParsePort(string text) =>
    int.TryParse(text, out var port) && port is >= 0 and <= 65535 ? port : null;

var port = ParsePort(args[0]) ?? 8080;
```

<details>
<summary>Solution</summary>

```java
static OptionalInt parsePort(String text) {
    try {
        int port = Integer.parseInt(text);
        return port >= 0 && port <= 65535 ? OptionalInt.of(port) : OptionalInt.empty();
    } catch (NumberFormatException e) {
        return OptionalInt.empty();
    }
}

int port = parsePort(args[0]).orElse(8080);
```

`OptionalInt` holds an `int` directly; `Optional<Integer>` would box it. Java has no `TryParse`, so the exception is the failure signal. `parsePort("http")` and `parsePort("70000")` both give `8080`.

</details>

3. Predict the output, then check it. Which exception reaches the caller, and in what order are the others recorded?

```java
record Resource(String name, List<String> log) implements AutoCloseable {
    @Override
    public void close() {
        log.add("close " + name);
        throw new IllegalStateException("close " + name);
    }
}

try (var first = new Resource("first", log);
        var second = new Resource("second", log)) {
    throw new IllegalArgumentException("body " + first.name() + " " + second.name());
}
```

<details>
<summary>Solution</summary>

The caller gets the `IllegalArgumentException` with the message `body first second`. `second` closes before `first`, so `log` is `[close second, close first]`, and `getSuppressed()` holds the two `IllegalStateException`s in the same order: `close second`, then `close first`. Every resource is closed even though each `close()` throws. In C#, nested `using` declarations would also dispose both, but the caller would see only `close first`, the last exception thrown.

</details>

## Sources

- [JLS chapter 11 — Exceptions](https://docs.oracle.com/javase/specs/jls/se25/html/jls-11.html) and [§14.20 — The try statement](https://docs.oracle.com/javase/specs/jls/se25/html/jls-14.html#jls-14.20)
- [The Java Tutorials — Exceptions](https://docs.oracle.com/javase/tutorial/essential/exceptions/index.html), including [Unchecked exceptions — the controversy](https://docs.oracle.com/javase/tutorial/essential/exceptions/runtime.html)
- [JEP 358 — Helpful NullPointerExceptions](https://openjdk.org/jeps/358)
- [`Optional` API](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Optional.html)
- [C# — Exception-handling statements](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/exception-handling-statements) and [Nullable reference types](https://learn.microsoft.com/dotnet/csharp/nullable-references)
