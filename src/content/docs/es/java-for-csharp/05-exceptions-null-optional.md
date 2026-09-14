---
title: 5. Excepciones, null y Optional
description: Excepciones comprobadas, multi-catch sin filtros, try-with-resources y excepciones suprimidas, mensajes útiles de NullPointerException y Optional en lugar de ?. y ?? — comparados con C#.
sidebar:
  order: 5
---

Ejemplos completos: [`lessons/l05`](https://github.com/spareilleux/learn/tree/main/code/java-for-csharp/src/main/java/lessons/l05).

## Excepciones comprobadas: el compilador lleva la cuenta de lo que puede fallar

En C#, todas las excepciones son no comprobadas: la firma de un método no dice qué lanza, y el compilador nunca te pide que trates nada. Java divide en dos la jerarquía de [`Throwable`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Throwable.html):

| Tipo | Clases | ¿Hay que capturarla o declararla? | Uso típico |
|---|---|---|---|
| comprobada (checked) | [`Exception`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Exception.html) y sus subclases, salvo `RuntimeException` | sí | fallos que un programa correcto debe prever igualmente: E/S, red, análisis de un archivo |
| no comprobada (unchecked) | [`RuntimeException`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/RuntimeException.html) y sus subclases | no | errores de programación: `NullPointerException`, `IllegalArgumentException`, `IndexOutOfBoundsException` |
| no comprobada (unchecked) | [`Error`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Error.html) y sus subclases | no | la JVM está en apuros: `OutOfMemoryError`, `StackOverflowError` |

Un método que puede dejar escapar una excepción comprobada debe indicarlo con `throws`. [`Files.readString`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/nio/file/Files.html#readString(java.nio.file.Path)) declara `throws IOException`, así que esto no compila:

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

Las dos soluciones son las que nombra el mensaje: capturarla, o añadir `throws IOException` a `load()` y trasladar la decisión a quienes lo llaman. Las reglas están en [JLS §11.2](https://docs.oracle.com/javase/specs/jls/se25/html/jls-11.html#jls-11.2).

```java
static String readConfig(Path path) throws IOException {
    return Files.readString(path);
}

static int parsePort(String text) {
    // NumberFormatException no es comprobada: nada obliga a quien llama a tratarla.
    return Integer.parseInt(text);
}
```

Las bibliotecas Java usan las excepciones comprobadas menos que antes. Las API más recientes, como `java.time`, solo lanzan excepciones no comprobadas, y la mayoría de los frameworks envuelven las comprobadas. Las API de E/S, reflexión y concurrencia del JDK son donde te las encontrarás a diario.

## Bloques catch: orden, multi-catch y sin filtros

La regla del orden es la misma que el CS0160 de C#: un `catch` no puede ir después de otro que ya trata un supertipo.

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

Las excepciones comprobadas añaden una regla que C# no tiene motivo para tener: capturar una excepción comprobada que el cuerpo del `try` no puede lanzar es un error.

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

Un **multi-catch** trata varios tipos no relacionados en un solo bloque. Las alternativas no pueden ser subclases unas de otras, ya que la subclase sería redundante:

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

Java no tiene [filtros de excepción](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/exception-handling-statements#a-when-exception-filter). El lado C# de esta lección captura con `when (e.Message.Contains("'http'"))`; la misma línea en Java es un error de sintaxis:

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

Haz la comprobación dentro del `catch` y vuelve a lanzar lo que no trates. A diferencia de un filtro, esto deshace la pila antes de que se ejecute la comprobación, lo que importa sobre todo a los depuradores y a los volcados de memoria.

## Las excepciones comprobadas no atraviesan las lambdas

Las interfaces funcionales de `java.util.function` no declaran excepciones comprobadas: [`Function.apply`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/function/Function.html#apply(T)) no tiene cláusula `throws`. Por eso una lambda que llama a `Files.readString` no puede ser una `Function`:

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

Este es el coste diario de las excepciones comprobadas. Las respuestas habituales son un bucle normal, o capturar dentro de la lambda y envolver la excepción en una no comprobada. El ejercicio 1 escribe un adaptador reutilizable para lo segundo.

## Envolver conserva la causa

Envuelve pasando la excepción original como **causa**, como el `innerException` de C#. Para `IOException`, el JDK ofrece [`UncheckedIOException`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/io/UncheckedIOException.html):

```java
static String loadOrWrap(Path path) {
    try {
        return readConfig(path);
    } catch (IOException e) {
        // Envuelve en una excepción no comprobada y conserva la original como causa.
        throw new UncheckedIOException("cannot load " + path.getFileName(), e);
    }
}
```

```text
cannot load missing.properties
caused by NoSuchFileException
```

Una traza de pila impresa por la JVM muestra la cadena en secciones `Caused by:`, el equivalente de las líneas `---> ` de excepción interna en .NET.

## try-with-resources en lugar de `using`

Un `try` con recursos es el `using` de Java. El recurso debe implementar [`AutoCloseable`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/AutoCloseable.html) (el `IDisposable` de Java). Los recursos se cierran en orden inverso a su declaración, antes de que se ejecute cualquier bloque `catch` o `finally` de la misma instrucción:

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

Los dos lenguajes difieren cuando el cuerpo lanza una excepción y después el cierre también lanza otra. Java conserva la excepción del cuerpo, la que explica qué salió mal, y le adjunta la otra como [excepción suprimida](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Throwable.html#getSuppressed()):

```java
// El cuerpo falla y luego también falla el cierre: gana la excepción del cuerpo,
// y la excepción del cierre se le adjunta en lugar de sustituirla.
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

En C#, un `using` es un `try`/`finally`. Una excepción lanzada por `Dispose` sustituye a la que estaba en curso, y `query failed on db` se pierde:

```text
dispose db
caught: dispose failed: db
```

El tipo del recurso se comprueba en tiempo de compilación. No hay duck typing, y una clase con un método `close()` que no implementa `AutoCloseable` se rechaza:

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

El propio `close()` puede lanzar una excepción comprobada. [`BufferedReader.close()`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/io/BufferedReader.html#close()) declara `IOException`, así que la llamada implícita hay que tratarla incluso cuando el cuerpo no puede fallar:

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

La semántica completa, incluidos el orden de cierre y la supresión, está en [JLS §14.20.3](https://docs.oracle.com/javase/specs/jls/se25/html/jls-14.html#jls-14.20.3).

## Volver a lanzar y `finally`

Una excepción Java captura su traza de pila cuando se **crea**, no cuando se lanza. Por eso `throw e` en un bloque `catch` conserva la traza original, y Java no tiene un `throw;` a secas:

```java
static void failDeep() {
    throw new IllegalStateException("deep failure");
}

static void rethrow() {
    try {
        failDeep();
    } catch (IllegalStateException e) {
        // En Java la traza de pila se captura cuando se crea la excepción,
        // así que "throw e" la conserva. C# necesita "throw;" para lo mismo.
        throw e;
    }
}
```

```text
thrown in failDeep
```

El lado C# muestra por qué existe la regla de C#. `throw e;` reinicia la traza en el método que vuelve a lanzar, y el analizador informa de [CA2200](https://learn.microsoft.com/dotnet/fundamentals/code-analysis/quality-rules/ca2200):

```text
throw e: thrown in RethrowWithVariable
throw;  thrown in FailDeep
```

C# prohíbe `return` dentro de `finally` (CS0157). Java lo permite, y el resultado del `finally` sustituye en silencio al del `try`, o incluso a una excepción en curso. `-Xlint:finally`, incluido en `-Xlint:all`, avisa de ello:

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

`total()` devuelve `2`. Reserva `finally` para la limpieza, y prefiere try-with-resources cuando la limpieza consiste en cerrar algo.

## `null`: sin tipos de referencia que aceptan valores null

Los [tipos de referencia que aceptan valores null](https://learn.microsoft.com/dotnet/csharp/nullable-references) de C# 8 hacen que `string` y `string?` sean tipos distintos para el compilador. Java no tiene nada parecido. Cualquier referencia puede ser `null`, `javac` no da ninguna advertencia, y te enteras en tiempo de ejecución.

Lo que Java sí tiene es un mensaje preciso. Desde [JEP 358](https://openjdk.org/jeps/358) (Java 14, activado por defecto desde la 15), una `NullPointerException` nombra lo que era `null`:

```java
static Customer lookup(String id) {
    return CUSTOMERS.get(id); // null cuando el id es desconocido
}

System.out.println(lookup("grace").name().length());
```

```text
Cannot invoke "lessons.l05.Nulls$Customer.name()" because the return value of "lessons.l05.Nulls.lookup(String)" is null
```

La misma cadena en C# (con `!` para silenciar la advertencia de nulabilidad) solo da `Object reference not set to an instance of an object.`

Para fallar pronto, [`Objects.requireNonNull`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Objects.html#requireNonNull(T,java.lang.String)) es el equivalente de `ArgumentNullException.ThrowIfNull`:

```java
new Customer(Objects.requireNonNull(null, "name"), null);
```

```text
requireNonNull: name
```

El análisis estático puede recuperar parte de la comprobación en tiempo de compilación. [JSpecify](https://jspecify.dev/) estandariza las anotaciones `@Nullable` y `@NullMarked`, y herramientas como [NullAway](https://github.com/uber/NullAway) las hacen cumplir durante la compilación. La [lección 11](../11-testing/) las configura y muestra a NullAway rechazando este tipo de código.

## `Optional<T>` en lugar de `?.` y `??`

[`Optional<T>`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Optional.html) es un contenedor que guarda un valor o nada. Es una clase de biblioteca, no sintaxis del lenguaje, y sus métodos cubren los operadores de null de C#:

| C# | `Optional` de Java |
|---|---|
| `x?.Property` | `.map(X::property)` |
| `x?.Method()` que devuelve `T?` | `.flatMap(X::method)` que devuelve `Optional` |
| `x ?? fallback` | `.orElse(fallback)` |
| `x ?? Compute()` | `.orElseGet(() -> compute())` |
| `x ?? throw new …` | `.orElseThrow(() -> new …)` |
| `x!` | `.orElseThrow()` — lanza `NoSuchElementException` |
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

`map` convierte un resultado `null` en un `Optional` vacío, así que `alan` (sin dirección) y `grace` (sin cliente) acaban los dos en `orElse`. El lado C# imprime las mismas tres líneas con `customers.GetValueOrDefault(id)?.Address?.City ?? "unknown"`.

Una diferencia con `??`: `orElse` es un método normal, así que su argumento se evalúa **antes** de la llamada, incluso cuando el valor está presente. Usa `orElseGet` cuando el valor por defecto es costoso o tiene efectos secundarios:

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

`Optional` está pensado para valores de retorno. Su Javadoc dice que «está pensado principalmente para usarse como tipo de retorno de un método cuando hay una clara necesidad de representar “ningún resultado” y cuando usar `null` probablemente cause errores». No lo uses para campos, parámetros ni elementos de colecciones, y nunca devuelvas un `Optional` `null`. Para los primitivos, [`OptionalInt`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/OptionalInt.html), `OptionalLong` y `OptionalDouble` evitan el boxing (lección 4).

## Puntos clave

- Las excepciones comprobadas (`Exception` pero no `RuntimeException`) deben capturarse o declararse con `throws`; C# no tiene ninguna.
- El multi-catch sustituye a los bloques `catch` repetidos; no hay filtros `when`.
- Las lambdas para las interfaces de `java.util.function` no pueden lanzar excepciones comprobadas: envuélvelas, por ejemplo en `UncheckedIOException`.
- try-with-resources cierra en orden inverso y conserva la excepción del cuerpo, añadiendo los fallos de cierre como excepciones suprimidas.
- `throw e` conserva la traza de pila; un `return` en `finally` se impone a todo.
- No hay tipos de referencia que aceptan valores null: apóyate en los mensajes útiles de las NPE, en `requireNonNull` y en `Optional` para los valores de retorno.

## Ejercicios

1. Escribe un adaptador `unchecked` para que `paths.stream().map(unchecked(Files::readString)).toList()` compile. Una `IOException` debe aparecer como una `UncheckedIOException` con la original como causa.

<details>
<summary>Solución</summary>

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

`ThrowingFunction` es una interfaz funcional cuyo método *sí* declara `throws Exception`, así que `Files::readString` encaja en ella. La cláusula `RuntimeException` vuelve a lanzar sin cambios las excepciones no comprobadas en lugar de envolverlas dos veces. Bibliotecas como Vavr incluyen la misma idea, pero esa docena de líneas suele ser más sencilla que una dependencia.

</details>

2. Traduce este método C#. ¿Qué tipo de retorno evita el boxing?

```csharp
static int? ParsePort(string text) =>
    int.TryParse(text, out var port) && port is >= 0 and <= 65535 ? port : null;

var port = ParsePort(args[0]) ?? 8080;
```

<details>
<summary>Solución</summary>

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

`OptionalInt` guarda un `int` directamente; `Optional<Integer>` lo envolvería en un objeto. Java no tiene `TryParse`, así que la excepción es la señal de fallo. `parsePort("http")` y `parsePort("70000")` dan los dos `8080`.

</details>

3. Predice la salida y luego compruébala. ¿Qué excepción llega a quien llama, y en qué orden se registran las demás?

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
<summary>Solución</summary>

Quien llama recibe la `IllegalArgumentException` con el mensaje `body first second`. `second` se cierra antes que `first`, así que `log` vale `[close second, close first]`, y `getSuppressed()` contiene las dos `IllegalStateException` en el mismo orden: `close second` y después `close first`. Todos los recursos se cierran aunque cada `close()` lance una excepción. En C#, unas declaraciones `using` anidadas también liberarían los dos, pero quien llama solo vería `close first`, la última excepción lanzada.

</details>

## Fuentes

- [JLS, capítulo 11 — Exceptions](https://docs.oracle.com/javase/specs/jls/se25/html/jls-11.html) y [§14.20 — The try statement](https://docs.oracle.com/javase/specs/jls/se25/html/jls-14.html#jls-14.20)
- [The Java Tutorials — Exceptions](https://docs.oracle.com/javase/tutorial/essential/exceptions/index.html), incluido [Unchecked exceptions — the controversy](https://docs.oracle.com/javase/tutorial/essential/exceptions/runtime.html)
- [JEP 358 — Helpful NullPointerExceptions](https://openjdk.org/jeps/358)
- [API de `Optional`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Optional.html)
- [C# — Instrucciones de control de excepciones](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/exception-handling-statements) y [Tipos de referencia que aceptan valores NULL](https://learn.microsoft.com/dotnet/csharp/nullable-references)
