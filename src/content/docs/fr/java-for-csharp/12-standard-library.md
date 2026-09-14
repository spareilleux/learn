---
title: 12. La bibliothèque standard du quotidien
description: java.time au lieu de DateTime et TimeZoneInfo, BigDecimal au lieu de decimal, java.nio.file au lieu de System.IO, et java.net.http.HttpClient au lieu de HttpClient, avec les valeurs par défaut qui diffèrent.
sidebar:
  order: 12
---

Exemples complets : [`lessons/l12`](https://github.com/spareilleux/learn/tree/main/code/java-for-csharp/src/main/java/lessons/l12), avec le côté C# dans [`csharp/L12.cs`](https://github.com/spareilleux/learn/blob/main/code/java-for-csharp/csharp/L12.cs). La CI exécute les deux et compare leur sortie avec cette leçon.

## Quatre API de tous les jours

Les noms changent, mais la plupart des concepts se correspondent un à un. Les différences se trouvent dans les valeurs par défaut, et ce sont elles le sujet de cette leçon.

| C# | Java 25 |
|---|---|
| `DateTimeOffset` en UTC | [`Instant`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/time/Instant.html) |
| `DateTimeOffset` | `OffsetDateTime` |
| `DateTime` + `TimeZoneInfo` | [`ZonedDateTime`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/time/ZonedDateTime.html) + `ZoneId` |
| `DateOnly`, `TimeOnly` | `LocalDate`, `LocalTime` |
| `DateTime` de `Kind` `Unspecified` | `LocalDateTime` |
| `TimeSpan` | `Duration` (durée), `Period` (calendrier) |
| `decimal` | [`BigDecimal`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/math/BigDecimal.html) |
| `File`, `Directory`, `Path` | [`Files`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/nio/file/Files.html), `Path` |
| `CultureInfo` | `Locale` |
| [`HttpClient`](https://learn.microsoft.com/dotnet/api/system.net.http.httpclient) | [`java.net.http.HttpClient`](https://docs.oracle.com/en/java/javase/25/docs/api/java.net.http/java/net/http/HttpClient.html) |
| `System.Text.Json` | rien dans le JDK : une bibliothèque comme [Jackson](https://github.com/FasterXML/jackson) |

## Dates et heures : `java.time`

`java.time` est arrivé avec Java 8 et a remplacé `java.util.Date` et `Calendar`. Ses types sont immuables et chacun dit ce qu'il contient : un point sur la ligne du temps, une date sans heure, une heure dans un fuseau. Le `DateTime` de C# couvre plusieurs de ces cas à la fois, distingués par son `Kind`.

```java
// Instant est un point sur la ligne du temps, comme un DateTimeOffset en UTC.
Instant noon = Instant.parse("2026-09-13T12:00:00Z");
ZoneId paris = ZoneId.of("Europe/Paris");
System.out.println("in Paris: " + noon.atZone(paris));
System.out.println("in Toronto: " + noon.atZone(ZoneId.of("America/Toronto")));

// LocalDate est DateOnly. Les mois comptent à partir de 1, et une date invalide lève une exception.
LocalDate endOfJanuary = LocalDate.of(2026, 1, 31);
System.out.println("a month after January 31: " + endOfJanuary.plusMonths(1));
System.out.println("from January 31 to March 1: " + Period.between(endOfJanuary, LocalDate.of(2026, 3, 1)));
try {
    LocalDate.of(2026, 2, 30);
} catch (DateTimeException e) {
    System.out.println("DateTimeException: " + e.getMessage());
}
// L'API qu'il remplace comptait les mois à partir de 0.
System.out.println("Calendar.SEPTEMBER: " + Calendar.SEPTEMBER);
```

```text
in Paris: 2026-09-13T14:00+02:00[Europe/Paris]
in Toronto: 2026-09-13T08:00-04:00[America/Toronto]
a month after January 31: 2026-02-28
from January 31 to March 1: P1M1D
DateTimeException: Invalid date 'FEBRUARY 30'
Calendar.SEPTEMBER: 8
```

`plusMonths` s'arrête à la fin du mois, comme `DateOnly.AddMonths`. Les identifiants de fuseau sont les noms [IANA](https://www.iana.org/time-zones) sur tous les OS. .NET les accepte aussi depuis .NET 6, mais sous Windows seulement avec ICU : le côté C# de ce cours tournait avec `InvariantGlobalization` activé, et sous Windows `FindSystemTimeZoneById("Europe/Paris")` a levé `TimeZoneNotFoundException` jusqu'à ce que je le désactive, comme l'annonce [la documentation](https://learn.microsoft.com/dotnet/api/system.timezoneinfo.findsystemtimezonebyid).

Les anciennes classes sont toujours là, et compilent toujours. `new Date(126, 8, 13)` est le 13 septembre 2026, parce que l'année compte à partir de 1900 et le mois à partir de 0 ; javac se contente d'un avertissement :

```java
import java.util.Date;

class Legacy {
    // L'année 2026 s'écrit 126, et septembre est le mois 8.
    static Date lessonDay() {
        return new Date(126, 8, 13);
    }
}
```

```text
LegacyDate.java:6: warning: [deprecation] Date(int,int,int) in Date has been deprecated
        return new Date(126, 8, 13);
               ^
1 warning
```

### Un jour ne dure pas toujours 24 heures

Paris passe à l'heure d'été le 29 mars 2026. Un `ZonedDateTime` connaît les règles du fuseau : « un jour plus tard » et « 24 heures plus tard » donnent donc des résultats différents :

```java
// ZonedDateTime applique les règles du fuseau : Paris passe à l'heure d'été le 29 mars 2026.
ZonedDateTime saturdayNoon = ZonedDateTime.of(2026, 3, 28, 12, 0, 0, 0, paris);
System.out.println("plusDays(1): " + saturdayNoon.plusDays(1));
System.out.println("plusHours(24): " + saturdayNoon.plusHours(24));
System.out.println("that day lasted " + Duration.between(saturdayNoon, saturdayNoon.plusDays(1)));

// Une heure locale qui n'existe pas est avancée ; une heure qui existe deux fois prend le décalage le plus ancien.
System.out.println("02:30 on March 29: " + ZonedDateTime.of(2026, 3, 29, 2, 30, 0, 0, paris));
ZonedDateTime twice = ZonedDateTime.of(2026, 10, 25, 2, 30, 0, 0, paris);
System.out.println("02:30 on October 25: " + twice + ", or " + twice.withLaterOffsetAtOverlap());
```

```text
plusDays(1): 2026-03-29T12:00+02:00[Europe/Paris]
plusHours(24): 2026-03-29T13:00+02:00[Europe/Paris]
that day lasted PT23H
02:30 on March 29: 2026-03-29T03:30+02:00[Europe/Paris]
02:30 on October 25: 2026-10-25T02:30+02:00[Europe/Paris], or 2026-10-25T02:30+01:00[Europe/Paris]
```

C# n'a pas de type qui combine une date, une heure et un fuseau. Un `DateTimeOffset` ne porte qu'un décalage : `AddDays(1)` garde donc `+01:00` et tombe sur 13:00 à Paris. Les deux transitions sont aussi traitées différemment :

| Côté C# | Sortie |
|---|---|
| `saturdayNoon.AddDays(1)` | `2026-03-29T12:00:00.0000000+01:00, in Paris: 2026-03-29T13:00:00.0000000+02:00` |
| `ConvertTimeToUtc` de 02:30 le 29 mars | `ArgumentException: The supplied DateTime represents an invalid time.` |
| `GetUtcOffset` de 02:30 le 25 octobre | `01:00:00`, le décalage standard |

Pour une heure qui existe deux fois, Java choisit donc le décalage le plus ancien (l'heure d'été) et .NET le [décalage standard](https://learn.microsoft.com/dotnet/api/system.timezoneinfo.getutcoffset) (l'heure d'hiver) : la même heure locale correspond à des instants séparés d'une heure.

### Analyse et formatage

Chaque type n'analyse que son propre format. Le `DateTime.Parse("2026-09-13T12:00:00Z")` de .NET réussit et renvoie un `DateTime` de `Kind` `Local`, converti dans le fuseau horaire de la machine. Java refuse d'ignorer le `Z` :

```java
// Chaque type n'analyse que son propre format.
System.out.println("OffsetDateTime.parse: " + OffsetDateTime.parse("2026-09-13T14:00:00+02:00").toInstant());
try {
    LocalDateTime.parse("2026-09-13T12:00:00Z");
} catch (DateTimeParseException e) {
    System.out.println("DateTimeParseException: " + e.getMessage());
}

// Y est l'année de la semaine, et les semaines dépendent de la locale.
LocalDate newYearsEve = LocalDate.of(2026, 12, 31);
System.out.println("yyyy: " + newYearsEve.format(DateTimeFormatter.ofPattern("yyyy-MM-dd")));
System.out.println("YYYY, US: " + newYearsEve.format(DateTimeFormatter.ofPattern("YYYY-MM-dd", Locale.US)));
System.out.println("YYYY, France: " + newYearsEve.format(DateTimeFormatter.ofPattern("YYYY-MM-dd", Locale.FRANCE)));
```

```text
OffsetDateTime.parse: 2026-09-13T12:00:00Z
DateTimeParseException: Text '2026-09-13T12:00:00Z' could not be parsed, unparsed text found at index 19
yyyy: 2026-12-31
YYYY, US: 2027-12-31
YYYY, France: 2026-12-31
```

Les dernières lignes montrent un bug classique. Dans les patterns de [`DateTimeFormatter`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/time/format/DateTimeFormatter.html), `Y` est l'année *de la semaine* (week-based year), et la [documentation du builder](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/time/format/DateTimeFormatterBuilder.html#appendPattern(java.lang.String)) indique qu'elle suit les règles de semaines de la locale. Aux États-Unis, la semaine qui contient le 1er janvier est la semaine 1 de la nouvelle année : le 31 décembre 2026, un jeudi, tombe donc en 2027. La France utilise les semaines ISO, où cette semaine appartient encore à 2026. Le même pattern en .NET affiche `YYYY-12-31` : `Y` n'y est pas un spécificateur de format, il est donc recopié tel quel. Utilisez `yyyy` (ou `uuuu`).

## L'argent : `BigDecimal`

`decimal` est un type valeur de 128 bits avec des opérateurs. `BigDecimal` est un objet immuable à précision arbitraire, avec des méthodes au lieu d'opérateurs :

```java
import java.math.BigDecimal;

class Invoice {
    BigDecimal total(BigDecimal net, BigDecimal tax) {
        return net + tax;
    }
}
```

```text
DecimalOperators.java:5: error: bad operand types for binary operator '+'
        return net + tax;
                   ^
  first type:  BigDecimal
  second type: BigDecimal
1 error
```

Un `BigDecimal` est un entier non mis à l'échelle et une *échelle* (scale), le nombre de chiffres après la virgule : `2.00` vaut 200 avec une échelle de 2. `decimal` garde aussi une échelle, c'est pourquoi `1.10m * 3` affiche `3.30`. Les différences portent sur la construction, l'égalité, la division et l'arrondi :

```java
// Le constructeur double garde l'approximation binaire ; valueOf et le constructeur String, non.
System.out.println("new BigDecimal(0.1): " + new BigDecimal(0.1));
System.out.println("BigDecimal.valueOf(0.1): " + BigDecimal.valueOf(0.1));
System.out.println("new BigDecimal(\"0.1\"): " + new BigDecimal("0.1"));

// Des méthodes au lieu d'opérateurs. L'échelle est conservée, comme avec decimal.
System.out.println("10.50 + 0.5 = " + new BigDecimal("10.50").add(new BigDecimal("0.5")));
System.out.println("1.10 * 3 = " + new BigDecimal("1.10").multiply(BigDecimal.valueOf(3)));

// equals compare aussi l'échelle ; compareTo, non.
var two = new BigDecimal("2.0");
var twoPointZeroZero = new BigDecimal("2.00");
System.out.println("2.0 equals 2.00: " + two.equals(twoPointZeroZero));
System.out.println("2.0 compareTo 2.00: " + two.compareTo(twoPointZeroZero));
System.out.println("HashSet size: " + new HashSet<>(List.of(two, twoPointZeroZero)).size());
System.out.println("TreeSet size: " + new TreeSet<>(List.of(two, twoPointZeroZero)).size());
```

```text
new BigDecimal(0.1): 0.1000000000000000055511151231257827021181583404541015625
BigDecimal.valueOf(0.1): 0.1
new BigDecimal("0.1"): 0.1
10.50 + 0.5 = 11.00
1.10 * 3 = 3.30
2.0 equals 2.00: false
2.0 compareTo 2.00: 0
HashSet size: 2
TreeSet size: 1
```

- **`new BigDecimal(0.1)` est exact, et exactement faux.** Il garde tous les chiffres du `double` le plus proche de 0,1. Le `(decimal)0.1` de C# affiche `0.1`, parce que la conversion arrondit. Construisez à partir de chaînes, ou avec `BigDecimal.valueOf`, qui passe par `Double.toString`.
- **`equals` compare l'échelle.** En C#, `2.0m == 2.00m` et `2.0m.Equals(2.00m)` valent tous deux `True`, et un `HashSet<decimal>` n'en garde qu'un. En Java, `equals` répond `false` : un `HashSet` garde donc deux éléments, alors qu'un `TreeSet`, qui utilise `compareTo`, n'en garde qu'un. Comparez les montants avec `compareTo`, ou normalisez l'échelle avant de les utiliser comme clés.

La division et l'arrondi n'ont pas de valeur par défaut :

```java
// La division demande une échelle ou une précision quand le résultat ne se termine pas.
try {
    BigDecimal.ONE.divide(BigDecimal.valueOf(3));
} catch (ArithmeticException e) {
    System.out.println("ArithmeticException: " + e.getMessage());
}
System.out.println("1 / 3, scale 4: " + BigDecimal.ONE.divide(BigDecimal.valueOf(3), 4, RoundingMode.HALF_EVEN));
System.out.println("1 / 3, DECIMAL128: " + BigDecimal.ONE.divide(BigDecimal.valueOf(3), MathContext.DECIMAL128));

// Il n'y a pas de mode d'arrondi par défaut.
var price = new BigDecimal("2.345");
try {
    price.setScale(2);
} catch (ArithmeticException e) {
    System.out.println("ArithmeticException: " + e.getMessage());
}
System.out.println("HALF_EVEN: " + price.setScale(2, RoundingMode.HALF_EVEN) + ", HALF_UP: " + price.setScale(2, RoundingMode.HALF_UP));
// Math.round sur un double arrondit les moitiés vers le haut, vers l'infini positif.
System.out.println("Math.round(2.5): " + Math.round(2.5) + ", Math.round(-2.5): " + Math.round(-2.5));

// toString peut passer en notation scientifique.
var thousand = new BigDecimal("1000.00").stripTrailingZeros();
System.out.println("toString: " + thousand + ", toPlainString: " + thousand.toPlainString());
```

```text
ArithmeticException: Non-terminating decimal expansion; no exact representable decimal result.
1 / 3, scale 4: 0.3333
1 / 3, DECIMAL128: 0.3333333333333333333333333333333333
ArithmeticException: Rounding necessary
HALF_EVEN: 2.34, HALF_UP: 2.35
Math.round(2.5): 3, Math.round(-2.5): -2
toString: 1E+3, toPlainString: 1000
```

C# répond à chacun de ces cas sans exception. `1m / 3m` vaut `0.3333333333333333333333333333`, arrondi pour tenir dans les 28 à 29 chiffres significatifs d'un `decimal`, et `Math.Round(2.345m, 2)` vaut `2.34`, parce que [`Math.Round`](https://learn.microsoft.com/dotnet/api/system.math.round) arrondit les moitiés au pair, sauf si l'on passe `MidpointRounding.AwayFromZero`. Java vous oblige à choisir : une échelle et un `RoundingMode` pour `divide` et `setScale`, ou un `MathContext`, qui fixe un nombre de chiffres significatifs. `HALF_EVEN` est l'arrondi bancaire, celui de .NET par défaut. `Math.round(2.5)` sur un `double` donne `3` là où le `Math.Round(2.5)` de .NET donne `2` ; pour `-2.5`, les deux donnent `-2`, Java parce qu'il arrondit les moitiés vers l'infini positif, .NET parce que `-2` est pair.

Dans l'autre sens, `decimal` peut déborder (`decimal.MaxValue + 1` lève `OverflowException`), alors que `BigDecimal` grandit. Et `toString` passe en notation scientifique pour une échelle négative, entre autres cas, et une échelle négative est justement ce que produit `stripTrailingZeros` sur `1000.00` : écrivez `toPlainString` pour tout ce qu'une personne lit.

## Fichiers et texte : `java.nio.file`

`Files` réunit des méthodes statiques comme celles de `File` et de `Directory`, et un `Path` est un objet plutôt qu'une chaîne :

```java
// Files.writeString est File.WriteAllText ; UTF-8 est le charset par défaut depuis JDK 18.
System.out.println("default charset: " + Charset.defaultCharset());
Path notes = dir.resolve("notes.txt");
Files.writeString(notes, "pen\npad\nink\n");
System.out.println("readAllLines: " + Files.readAllLines(notes));

// Files.lines est File.ReadLines, mais il garde le fichier ouvert jusqu'à la fermeture du stream.
try (Stream<String> lines = Files.lines(notes)) {
    System.out.println("lines starting with p: " + lines.filter(line -> line.startsWith("p")).count());
}
```

```text
default charset: UTF-8
readAllLines: [pen, pad, ink]
lines starting with p: 2
```

`dir.resolve("notes.txt")` est `Path.Combine`. Avant JDK 18, le charset par défaut était celui de la plateforme, souvent windows-1252 sous Windows ; la [JEP 400](https://openjdk.org/jeps/400) en a fait UTF-8 partout, ce qui est aussi la valeur par défaut de .NET pour `File.WriteAllText`. La JEP 400 a gardé une exception : `System.out` encode toujours avec le charset de la console, si bien qu'un programme Java qui affiche `héllo` dans un terminal Windows peut montrer `h�llo` alors que le fichier qu'il a écrit est correct.

`Files.lines` et `Files.walk` renvoient des streams paresseux sur un handle de fichier ou de répertoire ouvert, et doivent être fermés. `File.ReadLines` ferme son fichier à la fin du `foreach` ; un stream n'a pas ce point d'accroche, d'où le `try`-with-resources.

### Exceptions : vérifiées et spécifiques

Presque toutes les méthodes de `Files` déclarent `IOException`, qui est vérifiée (leçon 5) ; ceci ne compile donc pas :

```java
import java.nio.file.Files;
import java.nio.file.Path;

class Notes {
    static String read(Path path) {
        return Files.readString(path);
    }
}
```

```text
ReadWithoutThrows.java:6: error: unreported exception IOException; must be caught or declared to be thrown
        return Files.readString(path);
                               ^
1 error
```

Les sous-classes nomment le problème, et certains cas que .NET accepte en silence sont des erreurs :

```java
// Les exceptions sont vérifiées, et plus spécifiques qu'IOException.
try {
    Files.readString(dir.resolve("missing.txt"));
} catch (NoSuchFileException e) {
    System.out.println("NoSuchFileException: " + dir.relativize(Path.of(e.getFile())));
}
try {
    Files.createDirectory(dir);
} catch (FileAlreadyExistsException e) {
    System.out.println("createDirectory: FileAlreadyExistsException");
}
Files.createDirectories(dir);
System.out.println("createDirectories: no exception");
try {
    Files.delete(dir);
} catch (DirectoryNotEmptyException e) {
    System.out.println("delete: DirectoryNotEmptyException");
}

// UTF-8 invalide : Files.readString lève une exception, new String remplace l'octet.
Path broken = Files.write(dir.resolve("broken.txt"), new byte[] {'A', (byte) 0xFF, 'B'});
try {
    Files.readString(broken);
} catch (MalformedInputException e) {
    System.out.println("MalformedInputException: " + e.getMessage());
}
String replaced = new String(Files.readAllBytes(broken), StandardCharsets.UTF_8);
System.out.println("new String: " + replaced.chars().mapToObj(c -> String.format("U+%04X", c)).toList());
```

```text
NoSuchFileException: missing.txt
createDirectory: FileAlreadyExistsException
createDirectories: no exception
delete: DirectoryNotEmptyException
MalformedInputException: Input length = 1
new String: [U+0041, U+FFFD, U+0042]
```

| Cas | C# | Java |
|---|---|---|
| fichier absent | `FileNotFoundException` | `NoSuchFileException`, dont le message n'est que le chemin |
| créer un répertoire existant | `Directory.CreateDirectory` : rien ne se passe | `createDirectory` lève une exception ; `createDirectories`, non |
| supprimer un répertoire non vide | `IOException` | `DirectoryNotEmptyException` |
| UTF-8 invalide | `File.ReadAllText` remplace l'octet par U+FFFD | `Files.readString` lève `MalformedInputException` |

La dernière ligne compte pour les pipelines de données : C# lit un fichier corrompu sans broncher, Java s'arrête au premier octet invalide. Les deux comportements sont disponibles des deux côtés ; ce ne sont simplement pas ceux par défaut.

### Culture et locale

`String.format` utilise la locale par défaut, comme `ToString` utilise `CurrentCulture`. Un programme qui formate des nombres sans locale affiche `1234,50` sur une machine française :

```java
// String.format utilise la locale par défaut, comme CurrentCulture ; passez-en une pour obtenir un résultat fixe.
System.out.println("France: " + String.format(Locale.FRANCE, "%.2f", 1234.5));
System.out.println("ROOT: " + String.format(Locale.ROOT, "%.2f", 1234.5));
System.out.println("Turkish lower case has a dotless i: " + "TITLE".toLowerCase(Locale.forLanguageTag("tr")).equals("tıtle"));
```

```text
France: 1234,50
ROOT: 1234.50
Turkish lower case has a dotless i: true
```

`Locale.ROOT` est `CultureInfo.InvariantCulture`. Le test turc montre le même piège dans les deux langages : `toLowerCase()` et `ToLower()` sans argument utilisent la locale courante, et en turc la minuscule de `I` est `ı`. Écrivez `toLowerCase(Locale.ROOT)` pour les identifiants, les noms de fichiers et les mots-clés de protocole.

## HTTP : `java.net.http.HttpClient`

Java 11 a ajouté [`java.net.http`](https://docs.oracle.com/en/java/javase/25/docs/api/java.net.http/java/net/http/package-summary.html). Comme celui de .NET, le client est fait pour être créé une fois et réutilisé, et il est `AutoCloseable` depuis Java 21. L'exemple tourne contre [`HttpServer`](https://docs.oracle.com/en/java/javase/25/docs/api/jdk.httpserver/com/sun/net/httpserver/HttpServer.html), un petit serveur livré avec le JDK : il n'a donc pas besoin du réseau ; le côté C# utilise `HttpListener`.

```java
// HttpClient est AutoCloseable depuis Java 21.
try (HttpClient client = HttpClient.newHttpClient()) {
    System.out.println("follows redirects: " + client.followRedirects() + ", connect timeout: " + client.connectTimeout());

    HttpResponse<String> old = client.send(HttpRequest.newBuilder(URI.create(base + "/old")).build(), HttpResponse.BodyHandlers.ofString());
    System.out.println("GET /old: " + old.statusCode() + ", Location: " + old.headers().firstValue("Location").orElseThrow());
    System.out.println("client version: " + client.version() + ", response version: " + old.version());

    // Un statut d'erreur est une réponse normale, pas une exception.
    HttpResponse<String> missing = client.send(HttpRequest.newBuilder(URI.create(base + "/missing")).build(), HttpResponse.BodyHandlers.ofString());
    System.out.println("GET /missing: " + missing.statusCode());

    // Pas de timeout tant que la requête n'en définit pas.
    try {
        client.send(HttpRequest.newBuilder(URI.create(base + "/slow")).timeout(Duration.ofMillis(100)).build(), HttpResponse.BodyHandlers.ofString());
    } catch (HttpTimeoutException e) {
        System.out.println("HttpTimeoutException: " + e.getMessage());
    }
}

// Suivre les redirections est optionnel ; sendAsync renvoie un CompletableFuture.
try (HttpClient client = HttpClient.newBuilder().followRedirects(HttpClient.Redirect.NORMAL).build()) {
    HttpResponse<String> response = client.sendAsync(HttpRequest.newBuilder(URI.create(base + "/old")).build(), HttpResponse.BodyHandlers.ofString()).join();
    System.out.println("GET /old, following redirects: " + response.statusCode() + " " + response.body() + " from " + response.uri().getPath());
}
```

```text
follows redirects: NEVER, connect timeout: Optional.empty
GET /old: 302, Location: /new
client version: HTTP_2, response version: HTTP_1_1
GET /missing: 404
HttpTimeoutException: request timed out
GET /old, following redirects: 200 moved here from /new
```

Le côté C# affiche :

```text
default timeout: 00:01:40
GET /old: 200 moved here from /new
GET /missing: 404
GetStringAsync: HttpRequestException: Response status code does not indicate success: 404 (Not Found).
TaskCanceledException (TimeoutException): The request was canceled due to the configured HttpClient.Timeout of 0.1 seconds elapsing.
GET /old without redirects: 302, Location: /new
```

| Par défaut | `HttpClient` .NET | `HttpClient` Java |
|---|---|---|
| redirections | suivies (`AllowAutoRedirect` vaut `true`) | [non suivies](https://docs.oracle.com/en/java/javase/25/docs/api/java.net.http/java/net/http/HttpClient.Builder.html#followRedirects(java.net.http.HttpClient.Redirect)) : `Redirect.NEVER` |
| timeout | [100 secondes](https://learn.microsoft.com/dotnet/api/system.net.http.httpclient.timeout) | [aucun](https://docs.oracle.com/en/java/javase/25/docs/api/java.net.http/java/net/http/HttpRequest.Builder.html#timeout(java.time.Duration)) : « block forever » |
| version HTTP | HTTP/1.1 | préfère HTTP/2, se rabat sur ce que parle le serveur |
| statut d'erreur | une réponse ; `GetStringAsync` et `EnsureSuccessStatusCode` lèvent une exception | toujours une réponse |
| asynchrone | `GetAsync` renvoie une `Task` | `send` bloque, `sendAsync` renvoie un `CompletableFuture` |

Deux de ces valeurs par défaut font mal en production. Un client Java sans timeout attend indéfiniment un serveur qui accepte la connexion et ne répond jamais ; définissez `timeout` sur chaque requête, et `connectTimeout` sur le builder. Et du code porté depuis C# qui compte sur le suivi des redirections obtient un 302 au corps vide. L'exercice 3 écrit le `GetStringAsync` qui manque.

Le `send` bloquant est le choix normal sur un thread virtuel (leçon 9). `sendAsync` convient au code qui compose déjà des `CompletableFuture`.

## Ce que le JDK n'a pas

La bibliothèque de classes de base de .NET couvre plus de terrain que le JDK. Il n'y a pas d'API JSON dans le JDK 25 : `java --list-modules` montre `java.net.http` et `jdk.httpserver`, et rien pour JSON. Les projets utilisent [Jackson](https://github.com/FasterXML/jackson), que Spring Boot configure par défaut, ou [Gson](https://github.com/google/gson). Il n'y a pas non plus d'`IHttpClientFactory` ni d'injection de dépendances : ils viennent de frameworks comme Spring, le cours suivant.

## À retenir

- `java.time` a un type par signification : `Instant`, `LocalDate`, `ZonedDateTime`. `ZonedDateTime` applique des règles de fuseau horaire que `DateTimeOffset` ne connaît pas, et résout les trous et les chevauchements au lieu de lever une exception.
- Dans les patterns de date, `Y` est l'année de la semaine et dépend de la locale ; écrivez `yyyy`.
- Construisez un `BigDecimal` à partir d'une chaîne ou de `valueOf`, comparez-le avec `compareTo`, et donnez un `RoundingMode` à chaque `divide` et `setScale`.
- Les méthodes de `Files` lèvent des exceptions vérifiées et spécifiques, et rejettent l'UTF-8 invalide que .NET remplace. Fermez `Files.lines` et `Files.walk`.
- Passez une `Locale` à `String.format` et à `toLowerCase` partout où la sortie n'est pas destinée à une personne.
- Le `HttpClient` de Java ne suit pas les redirections et n'a pas de timeout par défaut ; un statut d'erreur n'est jamais une exception.

## Exercices

1. Écrivez `addBusinessDays(LocalDate start, int days)`, qui saute les samedis et les dimanches. Ajouter 1 jour ouvré au vendredi 11 septembre 2026 donne le lundi 14 ; en ajouter 5 donne le vendredi 18.

<details>
<summary>Solution</summary>

```java
static LocalDate addBusinessDays(LocalDate start, int days) {
    LocalDate date = start;
    int added = 0;
    while (added < days) {
        date = date.plusDays(1);
        if (date.getDayOfWeek() != DayOfWeek.SATURDAY && date.getDayOfWeek() != DayOfWeek.SUNDAY) {
            added++;
        }
    }
    return date;
}
```

`LocalDate` est immuable, comme `DateOnly` : `plusDays` renvoie donc une nouvelle date qu'il faut affecter. `DayOfWeek` est une enum, comparée avec `!=` comme en C#. Le test vérifie aussi qu'ajouter 0 jour renvoie la date de départ inchangée.

</details>

2. Partagez une addition de `100.00` entre 3 personnes de sorte que les parts totalisent exactement le montant : `33.34`, `33.33`, `33.33`. Écrivez `split(BigDecimal total, int people)`.

<details>
<summary>Solution</summary>

```java
static List<BigDecimal> split(BigDecimal total, int people) {
    BigDecimal share = total.divide(BigDecimal.valueOf(people), 2, RoundingMode.DOWN);
    BigDecimal cent = new BigDecimal("0.01");
    int extraCents = total.subtract(share.multiply(BigDecimal.valueOf(people))).divide(cent).intValueExact();
    List<BigDecimal> shares = new ArrayList<>();
    for (int i = 0; i < people; i++) {
        shares.add(i < extraCents ? share.add(cent) : share);
    }
    return shares;
}
```

Arrondir chaque part avec `HALF_EVEN` donnerait trois fois `33.33` et perdrait un centime. Arrondir vers le bas, puis distribuer les centimes restants, garde la somme exacte. `divide(cent)` n'a pas besoin de mode d'arrondi, parce que le reste est un nombre entier de centimes, et `intValueExact` lève une exception au lieu de tronquer si cette hypothèse s'avère un jour fausse. Le test compare la somme avec `compareTo`, pas `equals`, pour la raison d'échelle vue plus haut.

</details>

3. Écrivez `getString(HttpClient client, URI uri)`, l'équivalent Java de `GetStringAsync` : elle renvoie le corps, lève une `IOException` avec le message `Response status code does not indicate success: 404` pour un statut hors 2xx, et n'attend pas plus de 100 secondes. Testez-la contre un `HttpServer` local avec une redirection et un 404.

<details>
<summary>Solution</summary>

```java
static String getString(HttpClient client, URI uri) throws IOException, InterruptedException {
    HttpRequest request = HttpRequest.newBuilder(uri).timeout(Duration.ofSeconds(100)).build();
    HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
    if (response.statusCode() < 200 || response.statusCode() > 299) {
        throw new IOException("Response status code does not indicate success: " + response.statusCode());
    }
    return response.body();
}
```

Le timeout se place sur la requête, là où .NET le met sur le client. Les redirections sont une propriété du client : le test en construit donc un avec `Redirect.NORMAL` et vérifie que `/old` renvoie `moved here`, puis que `/missing` lève une exception avec le message attendu. `IOException` est le choix naturel parce que `send` la déclare déjà : les appelants gèrent ainsi un seul type d'exception pour les erreurs réseau et de statut, comme avec `HttpRequestException`.

</details>

## Sources

- [Résumé du package `java.time`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/time/package-summary.html), [`DateTimeFormatter`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/time/format/DateTimeFormatter.html)
- [`BigDecimal`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/math/BigDecimal.html), [`RoundingMode`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/math/RoundingMode.html)
- [`Files`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/nio/file/Files.html), [JEP 400 — UTF-8 by Default](https://openjdk.org/jeps/400)
- [`java.net.http`](https://docs.oracle.com/en/java/javase/25/docs/api/java.net.http/java/net/http/package-summary.html), [`HttpServer`](https://docs.oracle.com/en/java/javase/25/docs/api/jdk.httpserver/com/sun/net/httpserver/HttpServer.html)
- C# : [fuseaux horaires](https://learn.microsoft.com/dotnet/standard/datetime/time-zone-overview), [globalisation et ICU](https://learn.microsoft.com/dotnet/core/extensions/globalization-icu), [`decimal`](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/floating-point-numeric-types), [recommandations pour `HttpClient`](https://learn.microsoft.com/dotnet/fundamentals/networking/http/httpclient-guidelines)
