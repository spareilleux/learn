---
title: 12. The standard library you reach for
description: java.time instead of DateTime and TimeZoneInfo, BigDecimal instead of decimal, java.nio.file instead of System.IO, and java.net.http.HttpClient instead of HttpClient, with the defaults that differ.
sidebar:
  order: 12
---

Full examples: [`lessons/l12`](https://github.com/spareilleux/learn/tree/main/code/java-for-csharp/src/main/java/lessons/l12), with the C# side in [`csharp/L12.cs`](https://github.com/spareilleux/learn/blob/main/code/java-for-csharp/csharp/L12.cs). CI runs both and compares their output with this lesson.

## Four everyday APIs

The names change, but most concepts map one to one. The differences are in the defaults, and they are the subject of this lesson.

| C# | Java 25 |
|---|---|
| `DateTimeOffset` in UTC | [`Instant`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/time/Instant.html) |
| `DateTimeOffset` | `OffsetDateTime` |
| `DateTime` + `TimeZoneInfo` | [`ZonedDateTime`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/time/ZonedDateTime.html) + `ZoneId` |
| `DateOnly`, `TimeOnly` | `LocalDate`, `LocalTime` |
| `DateTime` with `Kind` `Unspecified` | `LocalDateTime` |
| `TimeSpan` | `Duration` (time), `Period` (calendar) |
| `decimal` | [`BigDecimal`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/math/BigDecimal.html) |
| `File`, `Directory`, `Path` | [`Files`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/nio/file/Files.html), `Path` |
| `CultureInfo` | `Locale` |
| [`HttpClient`](https://learn.microsoft.com/dotnet/api/system.net.http.httpclient) | [`java.net.http.HttpClient`](https://docs.oracle.com/en/java/javase/25/docs/api/java.net.http/java/net/http/HttpClient.html) |
| `System.Text.Json` | nothing in the JDK: a library such as [Jackson](https://github.com/FasterXML/jackson) |

## Dates and times: `java.time`

`java.time` arrived in Java 8 and replaced `java.util.Date` and `Calendar`. Its types are immutable and each one says what it holds: a point on the timeline, a date without a time, a time in a zone. C#'s `DateTime` covers several of those at once, told apart by its `Kind`.

```java
// Instant is a point on the timeline, like a DateTimeOffset in UTC.
Instant noon = Instant.parse("2026-09-13T12:00:00Z");
ZoneId paris = ZoneId.of("Europe/Paris");
System.out.println("in Paris: " + noon.atZone(paris));
System.out.println("in Toronto: " + noon.atZone(ZoneId.of("America/Toronto")));

// LocalDate is DateOnly. Months count from 1, and an invalid date throws.
LocalDate endOfJanuary = LocalDate.of(2026, 1, 31);
System.out.println("a month after January 31: " + endOfJanuary.plusMonths(1));
System.out.println("from January 31 to March 1: " + Period.between(endOfJanuary, LocalDate.of(2026, 3, 1)));
try {
    LocalDate.of(2026, 2, 30);
} catch (DateTimeException e) {
    System.out.println("DateTimeException: " + e.getMessage());
}
// The API it replaces counted months from 0.
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

`plusMonths` clamps to the end of the month, like `DateOnly.AddMonths`. Zone ids are the [IANA](https://www.iana.org/time-zones) names on every OS. .NET accepts them too since .NET 6, but on Windows only with ICU: the C# side of this course ran with `InvariantGlobalization` enabled, and on Windows `FindSystemTimeZoneById("Europe/Paris")` threw `TimeZoneNotFoundException` until I turned it off, as [the documentation](https://learn.microsoft.com/dotnet/api/system.timezoneinfo.findsystemtimezonebyid) warns.

The old classes are still there, and still compile. `new Date(126, 8, 13)` is September 13, 2026, because the year counts from 1900 and the month from 0; javac only warns:

```java
import java.util.Date;

class Legacy {
    // Year 2026 is written 126, and September is month 8.
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

### A day is not always 24 hours

Paris moves to summer time on March 29, 2026. A `ZonedDateTime` knows the zone's rules, so "one day later" and "24 hours later" are different results:

```java
// ZonedDateTime applies the zone's rules: Paris moves to summer time on March 29, 2026.
ZonedDateTime saturdayNoon = ZonedDateTime.of(2026, 3, 28, 12, 0, 0, 0, paris);
System.out.println("plusDays(1): " + saturdayNoon.plusDays(1));
System.out.println("plusHours(24): " + saturdayNoon.plusHours(24));
System.out.println("that day lasted " + Duration.between(saturdayNoon, saturdayNoon.plusDays(1)));

// A local time that doesn't exist is moved forward; one that happens twice takes the earlier offset.
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

C# has no type that combines a date, a time and a zone. A `DateTimeOffset` carries only an offset, so `AddDays(1)` keeps `+01:00` and lands on 13:00 in Paris. The two transitions are handled differently too:

| On the C# side | Output |
|---|---|
| `saturdayNoon.AddDays(1)` | `2026-03-29T12:00:00.0000000+01:00, in Paris: 2026-03-29T13:00:00.0000000+02:00` |
| `ConvertTimeToUtc` of 02:30 on March 29 | `ArgumentException: The supplied DateTime represents an invalid time.` |
| `GetUtcOffset` of 02:30 on October 25 | `01:00:00`, the standard offset |

So for a time that happens twice, Java picks the earlier offset (summer time) and .NET the [standard one](https://learn.microsoft.com/dotnet/api/system.timezoneinfo.getutcoffset) (winter time): the same local time maps to instants one hour apart.

### Parsing and formatting

Each type parses only its own format. .NET's `DateTime.Parse("2026-09-13T12:00:00Z")` succeeds and returns a `DateTime` of `Kind` `Local`, converted to the machine's time zone. Java refuses to drop the `Z`:

```java
// Each type parses only its own format.
System.out.println("OffsetDateTime.parse: " + OffsetDateTime.parse("2026-09-13T14:00:00+02:00").toInstant());
try {
    LocalDateTime.parse("2026-09-13T12:00:00Z");
} catch (DateTimeParseException e) {
    System.out.println("DateTimeParseException: " + e.getMessage());
}

// Y is the week-based year, and weeks depend on the locale.
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

The last lines are a classic bug. In [`DateTimeFormatter`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/time/format/DateTimeFormatter.html) patterns, `Y` is the *week-based* year, and the [builder's documentation](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/time/format/DateTimeFormatterBuilder.html#appendPattern(java.lang.String)) says it follows the locale's week rules. In the US, the week that contains January 1 is week 1 of the new year, so December 31, 2026, a Thursday, is in 2027. France uses ISO weeks, where that week still belongs to 2026. The same pattern in .NET prints `YYYY-12-31`: `Y` isn't a format specifier there, so it is copied as is. Use `yyyy` (or `uuuu`).

## Money: `BigDecimal`

`decimal` is a 128-bit value type with operators. `BigDecimal` is an immutable object with arbitrary precision, and methods instead of operators:

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

A `BigDecimal` is an unscaled integer and a *scale*, the number of digits after the point: `2.00` is 200 with scale 2. `decimal` keeps a scale too, which is why `1.10m * 3` prints `3.30`. The differences are in construction, equality, division and rounding:

```java
// The double constructor keeps the binary approximation; valueOf and the string constructor don't.
System.out.println("new BigDecimal(0.1): " + new BigDecimal(0.1));
System.out.println("BigDecimal.valueOf(0.1): " + BigDecimal.valueOf(0.1));
System.out.println("new BigDecimal(\"0.1\"): " + new BigDecimal("0.1"));

// Methods instead of operators. The scale is kept, as with decimal.
System.out.println("10.50 + 0.5 = " + new BigDecimal("10.50").add(new BigDecimal("0.5")));
System.out.println("1.10 * 3 = " + new BigDecimal("1.10").multiply(BigDecimal.valueOf(3)));

// equals compares the scale too; compareTo doesn't.
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

- **`new BigDecimal(0.1)` is exact, and exactly wrong.** It keeps every digit of the `double` nearest to 0.1. C#'s `(decimal)0.1` prints `0.1`, because the conversion rounds. Build from strings, or with `BigDecimal.valueOf`, which goes through `Double.toString`.
- **`equals` compares the scale.** In C#, `2.0m == 2.00m` and `2.0m.Equals(2.00m)` are both `True`, and a `HashSet<decimal>` keeps one of them. In Java, `equals` says `false`, so a `HashSet` keeps two elements while a `TreeSet`, which uses `compareTo`, keeps one. Compare amounts with `compareTo`, or normalise the scale before using them as keys.

Division and rounding have no defaults:

```java
// Division needs a scale or a precision when the result doesn't terminate.
try {
    BigDecimal.ONE.divide(BigDecimal.valueOf(3));
} catch (ArithmeticException e) {
    System.out.println("ArithmeticException: " + e.getMessage());
}
System.out.println("1 / 3, scale 4: " + BigDecimal.ONE.divide(BigDecimal.valueOf(3), 4, RoundingMode.HALF_EVEN));
System.out.println("1 / 3, DECIMAL128: " + BigDecimal.ONE.divide(BigDecimal.valueOf(3), MathContext.DECIMAL128));

// There is no default rounding mode.
var price = new BigDecimal("2.345");
try {
    price.setScale(2);
} catch (ArithmeticException e) {
    System.out.println("ArithmeticException: " + e.getMessage());
}
System.out.println("HALF_EVEN: " + price.setScale(2, RoundingMode.HALF_EVEN) + ", HALF_UP: " + price.setScale(2, RoundingMode.HALF_UP));
// Math.round on a double rounds halves up, towards positive infinity.
System.out.println("Math.round(2.5): " + Math.round(2.5) + ", Math.round(-2.5): " + Math.round(-2.5));

// toString can switch to scientific notation.
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

C# answers each of these without an exception. `1m / 3m` is `0.3333333333333333333333333333`, rounded to fit the 28 to 29 significant digits of a `decimal`, and `Math.Round(2.345m, 2)` is `2.34`, because [`Math.Round`](https://learn.microsoft.com/dotnet/api/system.math.round) rounds halves to even unless you pass `MidpointRounding.AwayFromZero`. Java makes you choose: a scale and a `RoundingMode` for `divide` and `setScale`, or a `MathContext`, which sets a number of significant digits. `HALF_EVEN` is banker's rounding, the .NET default. `Math.round(2.5)` on a `double` gives `3` where .NET's `Math.Round(2.5)` gives `2`; for `-2.5` both give `-2`, Java because it rounds halves towards positive infinity, .NET because `-2` is even.

The other way round, `decimal` can overflow (`decimal.MaxValue + 1` throws `OverflowException`), while `BigDecimal` grows. And `toString` switches to scientific notation for a negative scale, among other cases, and a negative scale is what `stripTrailingZeros` produces on `1000.00`: write `toPlainString` for anything a person reads.

## Files and text: `java.nio.file`

`Files` holds static methods like `File` and `Directory` together, and a `Path` is an object rather than a string:

```java
// Files.writeString is File.WriteAllText; UTF-8 is the default charset since JDK 18.
System.out.println("default charset: " + Charset.defaultCharset());
Path notes = dir.resolve("notes.txt");
Files.writeString(notes, "pen\npad\nink\n");
System.out.println("readAllLines: " + Files.readAllLines(notes));

// Files.lines is File.ReadLines, but it holds the file open until the stream is closed.
try (Stream<String> lines = Files.lines(notes)) {
    System.out.println("lines starting with p: " + lines.filter(line -> line.startsWith("p")).count());
}
```

```text
default charset: UTF-8
readAllLines: [pen, pad, ink]
lines starting with p: 2
```

`dir.resolve("notes.txt")` is `Path.Combine`. Before JDK 18, the default charset was the platform's, often windows-1252 on Windows; [JEP 400](https://openjdk.org/jeps/400) made it UTF-8 everywhere, which is also .NET's default for `File.WriteAllText`. JEP 400 kept one exception: `System.out` still encodes with the console's charset, so a Java program that prints `héllo` in a Windows terminal can show `h�llo` while the file it wrote is correct.

`Files.lines` and `Files.walk` return lazy streams over an open file or directory handle, and must be closed. `File.ReadLines` closes its file when the `foreach` ends; a stream doesn't have that hook, hence the `try`-with-resources.

### Exceptions: checked and specific

Almost every `Files` method declares `IOException`, which is checked (lesson 5), so this doesn't compile:

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

The subclasses name the problem, and some cases that .NET accepts silently are errors:

```java
// The exceptions are checked, and more specific than IOException.
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

// Invalid UTF-8: Files.readString throws, new String replaces the byte.
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

| Case | C# | Java |
|---|---|---|
| missing file | `FileNotFoundException` | `NoSuchFileException`, whose message is only the path |
| create an existing directory | `Directory.CreateDirectory`: nothing happens | `createDirectory` throws; `createDirectories` doesn't |
| delete a non-empty directory | `IOException` | `DirectoryNotEmptyException` |
| invalid UTF-8 | `File.ReadAllText` replaces the byte with U+FFFD | `Files.readString` throws `MalformedInputException` |

The last row matters for data pipelines: C# reads a corrupted file without complaint, Java stops at the first bad byte. Both behaviours are available on both sides; they are just not the default ones.

### Culture and locale

`String.format` uses the default locale, as `ToString` uses `CurrentCulture`. A program that formats numbers without a locale prints `1234,50` on a French machine:

```java
// String.format uses the default locale, like CurrentCulture; pass one to get a fixed result.
System.out.println("France: " + String.format(Locale.FRANCE, "%.2f", 1234.5));
System.out.println("ROOT: " + String.format(Locale.ROOT, "%.2f", 1234.5));
System.out.println("Turkish lower case has a dotless i: " + "TITLE".toLowerCase(Locale.forLanguageTag("tr")).equals("tıtle"));
```

```text
France: 1234,50
ROOT: 1234.50
Turkish lower case has a dotless i: true
```

`Locale.ROOT` is `CultureInfo.InvariantCulture`. The Turkish test is the same trap in both languages: `toLowerCase()` and `ToLower()` without an argument use the current locale, and in Turkish the lower case of `I` is `ı`. Write `toLowerCase(Locale.ROOT)` for identifiers, file names and protocol keywords.

## HTTP: `java.net.http.HttpClient`

Java 11 added [`java.net.http`](https://docs.oracle.com/en/java/javase/25/docs/api/java.net.http/java/net/http/package-summary.html). Like .NET's, the client is meant to be created once and reused, and it is `AutoCloseable` since Java 21. The example runs against [`HttpServer`](https://docs.oracle.com/en/java/javase/25/docs/api/jdk.httpserver/com/sun/net/httpserver/HttpServer.html), a small server that ships with the JDK, so it needs no network; the C# side uses `HttpListener`.

```java
// HttpClient is AutoCloseable since Java 21.
try (HttpClient client = HttpClient.newHttpClient()) {
    System.out.println("follows redirects: " + client.followRedirects() + ", connect timeout: " + client.connectTimeout());

    HttpResponse<String> old = client.send(HttpRequest.newBuilder(URI.create(base + "/old")).build(), HttpResponse.BodyHandlers.ofString());
    System.out.println("GET /old: " + old.statusCode() + ", Location: " + old.headers().firstValue("Location").orElseThrow());
    System.out.println("client version: " + client.version() + ", response version: " + old.version());

    // An error status is a normal response, not an exception.
    HttpResponse<String> missing = client.send(HttpRequest.newBuilder(URI.create(base + "/missing")).build(), HttpResponse.BodyHandlers.ofString());
    System.out.println("GET /missing: " + missing.statusCode());

    // No timeout unless the request sets one.
    try {
        client.send(HttpRequest.newBuilder(URI.create(base + "/slow")).timeout(Duration.ofMillis(100)).build(), HttpResponse.BodyHandlers.ofString());
    } catch (HttpTimeoutException e) {
        System.out.println("HttpTimeoutException: " + e.getMessage());
    }
}

// Following redirects is opt-in; sendAsync returns a CompletableFuture.
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

The C# side prints:

```text
default timeout: 00:01:40
GET /old: 200 moved here from /new
GET /missing: 404
GetStringAsync: HttpRequestException: Response status code does not indicate success: 404 (Not Found).
TaskCanceledException (TimeoutException): The request was canceled due to the configured HttpClient.Timeout of 0.1 seconds elapsing.
GET /old without redirects: 302, Location: /new
```

| Default | .NET `HttpClient` | Java `HttpClient` |
|---|---|---|
| redirects | followed (`AllowAutoRedirect` is `true`) | [not followed](https://docs.oracle.com/en/java/javase/25/docs/api/java.net.http/java/net/http/HttpClient.Builder.html#followRedirects(java.net.http.HttpClient.Redirect)): `Redirect.NEVER` |
| timeout | [100 seconds](https://learn.microsoft.com/dotnet/api/system.net.http.httpclient.timeout) | [none](https://docs.oracle.com/en/java/javase/25/docs/api/java.net.http/java/net/http/HttpRequest.Builder.html#timeout(java.time.Duration)): "block forever" |
| HTTP version | HTTP/1.1 | prefers HTTP/2, falls back to what the server speaks |
| error status | a response; `GetStringAsync` and `EnsureSuccessStatusCode` throw | always a response |
| async | `GetAsync` returns a `Task` | `send` blocks, `sendAsync` returns a `CompletableFuture` |

Two of these defaults bite in production. A Java client without a timeout waits forever on a server that accepts the connection and never answers; set `timeout` on each request, and `connectTimeout` on the builder. And code ported from C# that expects redirects to be followed gets a 302 with an empty body. Exercise 3 writes the missing `GetStringAsync`.

Blocking `send` is the normal choice on a virtual thread (lesson 9). `sendAsync` fits code that already composes `CompletableFuture`s.

## What the JDK doesn't have

The .NET base class library covers more ground than the JDK. There is no JSON API in JDK 25: `java --list-modules` shows `java.net.http` and `jdk.httpserver`, and nothing for JSON. Projects use [Jackson](https://github.com/FasterXML/jackson), which Spring Boot configures by default, or [Gson](https://github.com/google/gson). There is no `IHttpClientFactory` or dependency injection either: those come from frameworks such as Spring, the next course.

## Key takeaways

- `java.time` has one type per meaning: `Instant`, `LocalDate`, `ZonedDateTime`. `ZonedDateTime` applies time zone rules that `DateTimeOffset` doesn't know, and resolves gaps and overlaps instead of throwing.
- In date patterns, `Y` is the week-based year and depends on the locale; write `yyyy`.
- Build a `BigDecimal` from a string or `valueOf`, compare it with `compareTo`, and give every `divide` and `setScale` a `RoundingMode`.
- `Files` methods throw checked, specific exceptions, and reject invalid UTF-8 that .NET replaces. Close `Files.lines` and `Files.walk`.
- Pass a `Locale` to `String.format` and `toLowerCase` wherever the output is not for a person.
- Java's `HttpClient` doesn't follow redirects and has no timeout by default; an error status is never an exception.

## Exercises

1. Write `addBusinessDays(LocalDate start, int days)`, which skips Saturdays and Sundays. Adding 1 business day to Friday, September 11, 2026 gives Monday the 14th; adding 5 gives Friday the 18th.

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

`LocalDate` is immutable, like `DateOnly`, so `plusDays` returns a new date that must be assigned. `DayOfWeek` is an enum, compared with `!=` as in C#. The test also checks that adding 0 days returns the start date unchanged.

</details>

2. Split a bill of `100.00` between 3 people so that the shares add up to exactly the total: `33.34`, `33.33`, `33.33`. Write `split(BigDecimal total, int people)`.

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

Rounding each share with `HALF_EVEN` would give three times `33.33` and lose a cent. Rounding down, then handing out the remaining cents, keeps the sum exact. `divide(cent)` needs no rounding mode because the remainder is a whole number of cents, and `intValueExact` throws instead of truncating if that assumption is ever wrong. The test compares the sum with `compareTo`, not `equals`, for the scale reason above.

</details>

3. Write `getString(HttpClient client, URI uri)`, the Java counterpart of `GetStringAsync`: it returns the body, throws an `IOException` with the message `Response status code does not indicate success: 404` for a non-2xx status, and doesn't wait more than 100 seconds. Test it against a local `HttpServer` with a redirect and a 404.

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

The timeout goes on the request, where .NET puts it on the client. Redirects are a property of the client, so the test builds one with `Redirect.NORMAL` and checks that `/old` returns `moved here`, then that `/missing` throws with the expected message. `IOException` is the natural choice because `send` already declares it, so callers handle one exception type for network and status errors, as with `HttpRequestException`.

</details>

## Sources

- [`java.time` package summary](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/time/package-summary.html), [`DateTimeFormatter`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/time/format/DateTimeFormatter.html)
- [`BigDecimal`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/math/BigDecimal.html), [`RoundingMode`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/math/RoundingMode.html)
- [`Files`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/nio/file/Files.html), [JEP 400 — UTF-8 by Default](https://openjdk.org/jeps/400)
- [`java.net.http`](https://docs.oracle.com/en/java/javase/25/docs/api/java.net.http/java/net/http/package-summary.html), [`HttpServer`](https://docs.oracle.com/en/java/javase/25/docs/api/jdk.httpserver/com/sun/net/httpserver/HttpServer.html)
- C#: [time zones](https://learn.microsoft.com/dotnet/standard/datetime/time-zone-overview), [globalization and ICU](https://learn.microsoft.com/dotnet/core/extensions/globalization-icu), [`decimal`](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/floating-point-numeric-types), [`HttpClient` guidelines](https://learn.microsoft.com/dotnet/fundamentals/networking/http/httpclient-guidelines)
