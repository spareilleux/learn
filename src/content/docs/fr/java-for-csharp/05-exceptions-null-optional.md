---
title: 5. Exceptions, null et Optional
description: Exceptions vérifiées, multi-catch sans filtres, try-with-resources et exceptions supprimées, messages de NullPointerException explicites, et Optional à la place de ?. et ?? — comparés à C#.
sidebar:
  order: 5
---

Exemples complets : [`lessons/l05`](https://github.com/spareilleux/learn/tree/main/code/java-for-csharp/src/main/java/lessons/l05).

## Exceptions vérifiées : le compilateur suit ce qui peut échouer

En C#, toutes les exceptions sont non vérifiées : la signature d'une méthode ne dit pas ce qu'elle lève, et le compilateur ne vous demande jamais de traiter quoi que ce soit. Java coupe la hiérarchie de [`Throwable`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Throwable.html) en deux :

| Nature | Classes | À intercepter ou déclarer ? | Usage typique |
|---|---|---|---|
| vérifiée (checked) | [`Exception`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Exception.html) et ses sous-classes, sauf `RuntimeException` | oui | les échecs auxquels un programme correct doit tout de même s'attendre : E/S, réseau, analyse d'un fichier |
| non vérifiée (unchecked) | [`RuntimeException`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/RuntimeException.html) et ses sous-classes | non | les erreurs de programmation : `NullPointerException`, `IllegalArgumentException`, `IndexOutOfBoundsException` |
| non vérifiée | [`Error`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Error.html) et ses sous-classes | non | la JVM est en difficulté : `OutOfMemoryError`, `StackOverflowError` |

Une méthode qui peut laisser s'échapper une exception vérifiée doit l'annoncer avec `throws`. [`Files.readString`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/nio/file/Files.html#readString(java.nio.file.Path)) déclare `throws IOException`, donc ceci ne compile pas :

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

Les deux corrections sont celles que nomme le message : l'intercepter, ou ajouter `throws IOException` à `load()` et renvoyer la décision à ses appelants. Les règles se trouvent au [JLS §11.2](https://docs.oracle.com/javase/specs/jls/se25/html/jls-11.html#jls-11.2).

```java
static String readConfig(Path path) throws IOException {
    return Files.readString(path);
}

static int parsePort(String text) {
    // NumberFormatException est non vérifiée : rien n'oblige l'appelant à la traiter.
    return Integer.parseInt(text);
}
```

Les bibliothèques Java recourent moins aux exceptions vérifiées qu'autrefois. Les API plus récentes comme `java.time` ne lèvent que des exceptions non vérifiées, et la plupart des frameworks enveloppent les exceptions vérifiées. Les API d'E/S, de réflexion et de concurrence du JDK sont celles où vous les croiserez tous les jours.

## Blocs catch : ordre, multi-catch et pas de filtres

La règle d'ordre est la même que l'erreur CS0160 de C# : un `catch` ne peut pas suivre un `catch` qui traite déjà un super-type.

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

Les exceptions vérifiées ajoutent une règle que C# n'a aucune raison d'avoir : intercepter une exception vérifiée que le corps du `try` ne peut pas lever est une erreur.

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

Un **multi-catch** traite plusieurs types sans lien entre eux dans un seul bloc. Les alternatives ne doivent pas être sous-classes les unes des autres, puisque la sous-classe serait redondante :

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

Java n'a pas de [filtres d'exception](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/exception-handling-statements#a-when-exception-filter). Le côté C# de cette leçon intercepte avec `when (e.Message.Contains("'http'"))` ; la même ligne en Java est une erreur de syntaxe :

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

Testez à l'intérieur du `catch` et relancez ce que vous ne traitez pas. Contrairement à un filtre, cela déroule la pile avant l'exécution du test, ce qui compte surtout pour les débogueurs et les vidages mémoire (crash dumps).

## Les exceptions vérifiées ne traversent pas les lambdas

Les interfaces fonctionnelles de `java.util.function` ne déclarent aucune exception vérifiée : [`Function.apply`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/function/Function.html#apply(T)) n'a pas de clause `throws`. Une lambda qui appelle `Files.readString` ne peut donc pas être une `Function` :

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

C'est le coût quotidien des exceptions vérifiées. Les réponses habituelles sont une simple boucle, ou l'interception dans la lambda avec enveloppement de l'exception dans une exception non vérifiée. L'exercice 1 écrit un adaptateur réutilisable pour la seconde.

## Envelopper en gardant la cause

Enveloppez en passant l'exception d'origine comme **cause**, comme l'`innerException` de C#. Pour `IOException`, le JDK fournit [`UncheckedIOException`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/io/UncheckedIOException.html) :

```java
static String loadOrWrap(Path path) {
    try {
        return readConfig(path);
    } catch (IOException e) {
        // Envelopper dans une exception non vérifiée en gardant l'originale comme cause.
        throw new UncheckedIOException("cannot load " + path.getFileName(), e);
    }
}
```

```text
cannot load missing.properties
caused by NoSuchFileException
```

Une trace de pile affichée par la JVM montre la chaîne sous forme de sections `Caused by:`, l'équivalent des lignes d'exception interne `---> ` de .NET.

## try-with-resources au lieu de `using`

Un `try` avec ressources est le `using` de Java. La ressource doit implémenter [`AutoCloseable`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/AutoCloseable.html) (l'`IDisposable` de Java). Les ressources se ferment dans l'ordre inverse de leur déclaration, avant l'exécution de tout bloc `catch` ou `finally` de la même instruction :

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

Les deux langages divergent quand le corps lève une exception et que la fermeture en lève une aussi. Java garde l'exception du corps, celle qui explique ce qui s'est mal passé, et lui attache l'autre sous forme d'[exception supprimée](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Throwable.html#getSuppressed()) :

```java
// Le corps échoue, puis close échoue aussi : l'exception du corps l'emporte,
// et l'exception de close lui est attachée au lieu de la remplacer.
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

En C#, un `using` est un `try`/`finally`. Une exception levée par `Dispose` remplace celle en cours de propagation, et `query failed on db` est perdue :

```text
dispose db
caught: dispose failed: db
```

Le type de la ressource est vérifié à la compilation. Il n'y a pas de typage canard (duck typing), et une classe dotée d'une méthode `close()` qui n'implémente pas `AutoCloseable` est rejetée :

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

`close()` peut elle-même lever une exception vérifiée. [`BufferedReader.close()`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/io/BufferedReader.html#close()) déclare `IOException`, donc l'appel implicite doit être traité même quand le corps ne peut pas échouer :

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

La sémantique complète, y compris l'ordre de fermeture et la suppression, se trouve au [JLS §14.20.3](https://docs.oracle.com/javase/specs/jls/se25/html/jls-14.html#jls-14.20.3).

## Relancer et `finally`

Une exception Java capture sa trace de pile au moment où elle est **créée**, et non au moment où elle est levée. `throw e` dans un bloc `catch` conserve donc la trace d'origine, et Java n'a pas de `throw;` nu :

```java
static void failDeep() {
    throw new IllegalStateException("deep failure");
}

static void rethrow() {
    try {
        failDeep();
    } catch (IllegalStateException e) {
        // En Java, la trace de pile est capturée à la création de l'exception,
        // donc "throw e" la conserve. C# a besoin de "throw;" pour le même résultat.
        throw e;
    }
}
```

```text
thrown in failDeep
```

Le côté C# montre pourquoi la règle de C# existe. `throw e;` réinitialise la trace à la méthode qui relance, et l'analyseur signale [CA2200](https://learn.microsoft.com/dotnet/fundamentals/code-analysis/quality-rules/ca2200) :

```text
throw e: thrown in RethrowWithVariable
throw;  thrown in FailDeep
```

C# interdit `return` dans un `finally` (CS0157). Java l'autorise, et le résultat du `finally` remplace silencieusement celui du `try`, voire une exception en cours de propagation. `-Xlint:finally`, inclus dans `-Xlint:all`, avertit :

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

`total()` renvoie `2`. Réservez `finally` au nettoyage, et préférez try-with-resources quand le nettoyage consiste à fermer quelque chose.

## `null` : pas de types référence nullables

Les [types référence nullables](https://learn.microsoft.com/dotnet/csharp/nullable-references) de C# 8 font de `string` et `string?` des types différents pour le compilateur. Java n'a rien de tel. Toute référence peut être `null`, `javac` n'émet aucun avertissement, et vous le découvrez à l'exécution.

Ce que Java possède, en revanche, c'est un message précis. Depuis la [JEP 358](https://openjdk.org/jeps/358) (Java 14, activée par défaut depuis Java 15), une `NullPointerException` nomme ce qui était `null` :

```java
static Customer lookup(String id) {
    return CUSTOMERS.get(id); // null quand l'identifiant est inconnu
}

System.out.println(lookup("grace").name().length());
```

```text
Cannot invoke "lessons.l05.Nulls$Customer.name()" because the return value of "lessons.l05.Nulls.lookup(String)" is null
```

La même chaîne d'appels en C# (avec `!` pour faire taire l'avertissement de nullabilité) donne seulement `Object reference not set to an instance of an object.`

Pour échouer tôt, [`Objects.requireNonNull`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Objects.html#requireNonNull(T,java.lang.String)) est l'équivalent d'`ArgumentNullException.ThrowIfNull` :

```java
new Customer(Objects.requireNonNull(null, "name"), null);
```

```text
requireNonNull: name
```

L'analyse statique peut rétablir une partie de la vérification à la compilation. [JSpecify](https://jspecify.dev/) standardise les annotations `@Nullable` et `@NullMarked`, et des outils comme [NullAway](https://github.com/uber/NullAway) les font respecter au moment du build. La [leçon 11](../11-testing/) les met en place et montre NullAway rejetant ce genre de code.

## `Optional<T>` à la place de `?.` et `??`

[`Optional<T>`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Optional.html) est un conteneur qui contient une valeur ou rien. C'est une classe de bibliothèque, pas une syntaxe du langage, et ses méthodes couvrent les opérateurs de null de C# :

| C# | `Optional` en Java |
|---|---|
| `x?.Property` | `.map(X::property)` |
| `x?.Method()` qui renvoie `T?` | `.flatMap(X::method)` qui renvoie un `Optional` |
| `x ?? fallback` | `.orElse(fallback)` |
| `x ?? Compute()` | `.orElseGet(() -> compute())` |
| `x ?? throw new …` | `.orElseThrow(() -> new …)` |
| `x!` | `.orElseThrow()` — lève `NoSuchElementException` |
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

`map` transforme un résultat `null` en `Optional` vide, si bien que `alan` (sans adresse) et `grace` (sans client) aboutissent tous deux à `orElse`. Le côté C# affiche les trois mêmes lignes avec `customers.GetValueOrDefault(id)?.Address?.City ?? "unknown"`.

Une différence avec `??` : `orElse` est une méthode ordinaire, donc son argument est évalué **avant** l'appel, même quand la valeur est présente. Utilisez `orElseGet` quand la valeur de repli coûte cher ou a des effets de bord :

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

`Optional` est destiné aux valeurs de retour. Sa Javadoc indique qu'il est « principalement destiné à servir de type de retour de méthode lorsqu'il est clairement nécessaire de représenter "aucun résultat", et lorsque l'usage de `null` risque de provoquer des erreurs ». Ne l'utilisez pas pour des champs, des paramètres ou des éléments de collection, et ne renvoyez jamais un `Optional` `null`. Pour les primitifs, [`OptionalInt`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/OptionalInt.html), `OptionalLong` et `OptionalDouble` évitent le boxing (leçon 4).

## À retenir

- Les exceptions vérifiées (`Exception` mais pas `RuntimeException`) doivent être interceptées ou déclarées avec `throws` ; C# n'en a pas.
- Le multi-catch remplace les blocs `catch` répétés ; il n'y a pas de filtres `when`.
- Les lambdas destinées aux interfaces de `java.util.function` ne peuvent pas lever d'exceptions vérifiées : enveloppez-les, par exemple dans une `UncheckedIOException`.
- try-with-resources ferme dans l'ordre inverse et garde l'exception du corps, en y ajoutant les échecs de fermeture comme exceptions supprimées.
- `throw e` conserve la trace de pile ; un `return` dans `finally` écrase tout.
- Pas de types référence nullables : appuyez-vous sur les messages explicites des NPE, sur `requireNonNull`, et sur `Optional` pour les valeurs de retour.

## Exercices

1. Écrivez un adaptateur `unchecked` pour que `paths.stream().map(unchecked(Files::readString)).toList()` compile. Une `IOException` doit ressortir sous forme d'`UncheckedIOException` ayant l'originale pour cause.

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

`ThrowingFunction` est une interface fonctionnelle dont la méthode déclare, *elle*, `throws Exception` : `Files::readString` y correspond donc. La clause `RuntimeException` relance les exceptions non vérifiées telles quelles au lieu de les envelopper deux fois. Des bibliothèques comme Vavr proposent la même idée, mais une douzaine de lignes est souvent plus simple qu'une dépendance.

</details>

2. Traduisez cette méthode C#. Quel type de retour évite le boxing ?

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

`OptionalInt` contient directement un `int` ; `Optional<Integer>` le mettrait en boîte. Java n'a pas de `TryParse`, donc l'exception sert de signal d'échec. `parsePort("http")` et `parsePort("70000")` donnent tous deux `8080`.

</details>

3. Prédisez la sortie, puis vérifiez-la. Quelle exception atteint l'appelant, et dans quel ordre les autres sont-elles enregistrées ?

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

L'appelant reçoit l'`IllegalArgumentException` avec le message `body first second`. `second` se ferme avant `first`, donc `log` vaut `[close second, close first]`, et `getSuppressed()` contient les deux `IllegalStateException` dans le même ordre : `close second`, puis `close first`. Chaque ressource est fermée, alors même que chaque `close()` lève une exception. En C#, des déclarations `using` imbriquées libéreraient aussi les deux, mais l'appelant ne verrait que `close first`, la dernière exception levée.

</details>

## Sources

- [JLS chapitre 11 — Exceptions](https://docs.oracle.com/javase/specs/jls/se25/html/jls-11.html) et [§14.20 — The try statement](https://docs.oracle.com/javase/specs/jls/se25/html/jls-14.html#jls-14.20)
- [The Java Tutorials — Exceptions](https://docs.oracle.com/javase/tutorial/essential/exceptions/index.html), notamment [Unchecked exceptions — the controversy](https://docs.oracle.com/javase/tutorial/essential/exceptions/runtime.html)
- [JEP 358 — Helpful NullPointerExceptions](https://openjdk.org/jeps/358)
- [API `Optional`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Optional.html)
- [C# — Instructions de gestion des exceptions](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/exception-handling-statements) et [Types référence nullables](https://learn.microsoft.com/dotnet/csharp/nullable-references)
