---
title: 12. La biblioteca estándar del día a día
description: java.time en lugar de DateTime y TimeZoneInfo, BigDecimal en lugar de decimal, java.nio.file en lugar de System.IO y java.net.http.HttpClient en lugar de HttpClient, con los valores por defecto que cambian.
sidebar:
  order: 12
---

Ejemplos completos: [`lessons/l12`](https://github.com/spareilleux/learn/tree/main/code/java-for-csharp/src/main/java/lessons/l12), con el lado C# en [`csharp/L12.cs`](https://github.com/spareilleux/learn/blob/main/code/java-for-csharp/csharp/L12.cs). La CI ejecuta ambos y compara su salida con esta lección.

## Cuatro API de uso diario

Los nombres cambian, pero la mayoría de los conceptos se corresponden uno a uno. Las diferencias están en los valores por defecto, y son el tema de esta lección.

| C# | Java 25 |
|---|---|
| `DateTimeOffset` en UTC | [`Instant`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/time/Instant.html) |
| `DateTimeOffset` | `OffsetDateTime` |
| `DateTime` + `TimeZoneInfo` | [`ZonedDateTime`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/time/ZonedDateTime.html) + `ZoneId` |
| `DateOnly`, `TimeOnly` | `LocalDate`, `LocalTime` |
| `DateTime` con `Kind` `Unspecified` | `LocalDateTime` |
| `TimeSpan` | `Duration` (tiempo), `Period` (calendario) |
| `decimal` | [`BigDecimal`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/math/BigDecimal.html) |
| `File`, `Directory`, `Path` | [`Files`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/nio/file/Files.html), `Path` |
| `CultureInfo` | `Locale` |
| [`HttpClient`](https://learn.microsoft.com/dotnet/api/system.net.http.httpclient) | [`java.net.http.HttpClient`](https://docs.oracle.com/en/java/javase/25/docs/api/java.net.http/java/net/http/HttpClient.html) |
| `System.Text.Json` | nada en el JDK: una biblioteca como [Jackson](https://github.com/FasterXML/jackson) |

## Fechas y horas: `java.time`

`java.time` llegó en Java 8 y sustituyó a `java.util.Date` y `Calendar`. Sus tipos son inmutables y cada uno dice lo que contiene: un punto de la línea temporal, una fecha sin hora, una hora en una zona. El `DateTime` de C# cubre varios de esos casos a la vez, y los distingue por su `Kind`.

```java
// Instant es un punto de la línea temporal, como un DateTimeOffset en UTC.
Instant noon = Instant.parse("2026-09-13T12:00:00Z");
ZoneId paris = ZoneId.of("Europe/Paris");
System.out.println("in Paris: " + noon.atZone(paris));
System.out.println("in Toronto: " + noon.atZone(ZoneId.of("America/Toronto")));

// LocalDate es DateOnly. Los meses cuentan desde 1, y una fecha inválida lanza una excepción.
LocalDate endOfJanuary = LocalDate.of(2026, 1, 31);
System.out.println("a month after January 31: " + endOfJanuary.plusMonths(1));
System.out.println("from January 31 to March 1: " + Period.between(endOfJanuary, LocalDate.of(2026, 3, 1)));
try {
    LocalDate.of(2026, 2, 30);
} catch (DateTimeException e) {
    System.out.println("DateTimeException: " + e.getMessage());
}
// La API a la que sustituye contaba los meses desde 0.
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

`plusMonths` se ajusta al final del mes, como `DateOnly.AddMonths`. Los identificadores de zona son los nombres de la [IANA](https://www.iana.org/time-zones) en todos los sistemas operativos. .NET también los acepta desde .NET 6, pero en Windows solo con ICU: el lado C# de este curso se ejecutaba con `InvariantGlobalization` activado, y en Windows `FindSystemTimeZoneById("Europe/Paris")` lanzó `TimeZoneNotFoundException` hasta que lo desactivé, como advierte [la documentación](https://learn.microsoft.com/dotnet/api/system.timezoneinfo.findsystemtimezonebyid).

Las clases antiguas siguen ahí, y siguen compilando. `new Date(126, 8, 13)` es el 13 de septiembre de 2026, porque el año cuenta desde 1900 y el mes desde 0; javac solo emite una advertencia:

```java
import java.util.Date;

class Legacy {
    // El año 2026 se escribe 126, y septiembre es el mes 8.
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

### Un día no siempre dura 24 horas

París pasa al horario de verano el 29 de marzo de 2026. Un `ZonedDateTime` conoce las reglas de la zona, así que «un día después» y «24 horas después» dan resultados distintos:

```java
// ZonedDateTime aplica las reglas de la zona: París pasa al horario de verano el 29 de marzo de 2026.
ZonedDateTime saturdayNoon = ZonedDateTime.of(2026, 3, 28, 12, 0, 0, 0, paris);
System.out.println("plusDays(1): " + saturdayNoon.plusDays(1));
System.out.println("plusHours(24): " + saturdayNoon.plusHours(24));
System.out.println("that day lasted " + Duration.between(saturdayNoon, saturdayNoon.plusDays(1)));

// Una hora local que no existe se desplaza hacia delante; una que ocurre dos veces toma el desfase anterior.
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

C# no tiene ningún tipo que combine una fecha, una hora y una zona. Un `DateTimeOffset` solo lleva un desfase, así que `AddDays(1)` conserva `+01:00` y cae a las 13:00 en París. Las dos transiciones también se tratan de otra manera:

| En el lado C# | Salida |
|---|---|
| `saturdayNoon.AddDays(1)` | `2026-03-29T12:00:00.0000000+01:00, in Paris: 2026-03-29T13:00:00.0000000+02:00` |
| `ConvertTimeToUtc` de las 02:30 del 29 de marzo | `ArgumentException: The supplied DateTime represents an invalid time.` |
| `GetUtcOffset` de las 02:30 del 25 de octubre | `01:00:00`, el desfase estándar |

Así que, para una hora que ocurre dos veces, Java elige el desfase anterior (horario de verano) y .NET el [estándar](https://learn.microsoft.com/dotnet/api/system.timezoneinfo.getutcoffset) (horario de invierno): la misma hora local corresponde a instantes separados por una hora.

### Análisis y formato

Cada tipo solo analiza su propio formato. El `DateTime.Parse("2026-09-13T12:00:00Z")` de .NET funciona y devuelve un `DateTime` de `Kind` `Local`, convertido a la zona horaria de la máquina. Java se niega a descartar la `Z`:

```java
// Cada tipo solo analiza su propio formato.
System.out.println("OffsetDateTime.parse: " + OffsetDateTime.parse("2026-09-13T14:00:00+02:00").toInstant());
try {
    LocalDateTime.parse("2026-09-13T12:00:00Z");
} catch (DateTimeParseException e) {
    System.out.println("DateTimeParseException: " + e.getMessage());
}

// Y es el año basado en semanas, y las semanas dependen de la configuración regional.
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

Las últimas líneas muestran un error clásico. En los patrones de [`DateTimeFormatter`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/time/format/DateTimeFormatter.html), `Y` es el año *basado en semanas*, y la [documentación del builder](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/time/format/DateTimeFormatterBuilder.html#appendPattern(java.lang.String)) dice que sigue las reglas de semana de la configuración regional. En Estados Unidos, la semana que contiene el 1 de enero es la semana 1 del año nuevo, así que el 31 de diciembre de 2026, un jueves, pertenece a 2027. Francia usa las semanas ISO, en las que esa semana todavía pertenece a 2026. El mismo patrón en .NET imprime `YYYY-12-31`: allí `Y` no es un especificador de formato, así que se copia tal cual. Usa `yyyy` (o `uuuu`).

## Dinero: `BigDecimal`

`decimal` es un tipo de valor de 128 bits con operadores. `BigDecimal` es un objeto inmutable de precisión arbitraria, con métodos en lugar de operadores:

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

Un `BigDecimal` es un entero sin escala más una *escala*, el número de dígitos tras el punto decimal: `2.00` es 200 con escala 2. `decimal` también conserva una escala, y por eso `1.10m * 3` imprime `3.30`. Las diferencias están en la construcción, la igualdad, la división y el redondeo:

```java
// El constructor que recibe un double conserva la aproximación binaria; valueOf y el constructor de cadena no.
System.out.println("new BigDecimal(0.1): " + new BigDecimal(0.1));
System.out.println("BigDecimal.valueOf(0.1): " + BigDecimal.valueOf(0.1));
System.out.println("new BigDecimal(\"0.1\"): " + new BigDecimal("0.1"));

// Métodos en lugar de operadores. La escala se conserva, como con decimal.
System.out.println("10.50 + 0.5 = " + new BigDecimal("10.50").add(new BigDecimal("0.5")));
System.out.println("1.10 * 3 = " + new BigDecimal("1.10").multiply(BigDecimal.valueOf(3)));

// equals también compara la escala; compareTo no.
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

- **`new BigDecimal(0.1)` es exacto, y exactamente erróneo.** Conserva cada dígito del `double` más cercano a 0.1. El `(decimal)0.1` de C# imprime `0.1`, porque la conversión redondea. Construye a partir de cadenas, o con `BigDecimal.valueOf`, que pasa por `Double.toString`.
- **`equals` compara la escala.** En C#, `2.0m == 2.00m` y `2.0m.Equals(2.00m)` valen ambos `True`, y un `HashSet<decimal>` conserva solo uno de los dos. En Java, `equals` dice `false`, así que un `HashSet` conserva dos elementos mientras que un `TreeSet`, que usa `compareTo`, conserva uno. Compara importes con `compareTo`, o normaliza la escala antes de usarlos como claves.

La división y el redondeo no tienen valores por defecto:

```java
// La división necesita una escala o una precisión cuando la expansión decimal no termina.
try {
    BigDecimal.ONE.divide(BigDecimal.valueOf(3));
} catch (ArithmeticException e) {
    System.out.println("ArithmeticException: " + e.getMessage());
}
System.out.println("1 / 3, scale 4: " + BigDecimal.ONE.divide(BigDecimal.valueOf(3), 4, RoundingMode.HALF_EVEN));
System.out.println("1 / 3, DECIMAL128: " + BigDecimal.ONE.divide(BigDecimal.valueOf(3), MathContext.DECIMAL128));

// No hay modo de redondeo por defecto.
var price = new BigDecimal("2.345");
try {
    price.setScale(2);
} catch (ArithmeticException e) {
    System.out.println("ArithmeticException: " + e.getMessage());
}
System.out.println("HALF_EVEN: " + price.setScale(2, RoundingMode.HALF_EVEN) + ", HALF_UP: " + price.setScale(2, RoundingMode.HALF_UP));
// Math.round sobre un double redondea las mitades hacia arriba, hacia más infinito.
System.out.println("Math.round(2.5): " + Math.round(2.5) + ", Math.round(-2.5): " + Math.round(-2.5));

// toString puede pasar a notación científica.
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

C# responde a cada uno de estos casos sin excepción. `1m / 3m` es `0.3333333333333333333333333333`, redondeado para caber en los 28 o 29 dígitos significativos de un `decimal`, y `Math.Round(2.345m, 2)` es `2.34`, porque [`Math.Round`](https://learn.microsoft.com/dotnet/api/system.math.round) redondea las mitades al par salvo que se pase `MidpointRounding.AwayFromZero`. Java obliga a elegir: una escala y un `RoundingMode` para `divide` y `setScale`, o un `MathContext`, que fija un número de dígitos significativos. `HALF_EVEN` es el redondeo bancario, el valor por defecto de .NET. `Math.round(2.5)` sobre un `double` da `3` donde el `Math.Round(2.5)` de .NET da `2`; para `-2.5` ambos dan `-2`, Java porque redondea las mitades hacia más infinito, .NET porque `-2` es par.

En sentido contrario, `decimal` puede desbordarse (`decimal.MaxValue + 1` lanza `OverflowException`), mientras que `BigDecimal` crece. Y `toString` pasa a notación científica con una escala negativa, entre otros casos, y una escala negativa es justo lo que produce `stripTrailingZeros` sobre `1000.00`: usa `toPlainString` para todo lo que vaya a leer una persona.

## Archivos y texto: `java.nio.file`

`Files` reúne en una sola clase los métodos estáticos de `File` y `Directory`, y un `Path` es un objeto en lugar de una cadena:

```java
// Files.writeString es File.WriteAllText; UTF-8 es el charset por defecto desde JDK 18.
System.out.println("default charset: " + Charset.defaultCharset());
Path notes = dir.resolve("notes.txt");
Files.writeString(notes, "pen\npad\nink\n");
System.out.println("readAllLines: " + Files.readAllLines(notes));

// Files.lines es File.ReadLines, pero mantiene el archivo abierto hasta que se cierra el stream.
try (Stream<String> lines = Files.lines(notes)) {
    System.out.println("lines starting with p: " + lines.filter(line -> line.startsWith("p")).count());
}
```

```text
default charset: UTF-8
readAllLines: [pen, pad, ink]
lines starting with p: 2
```

`dir.resolve("notes.txt")` es `Path.Combine`. Antes de JDK 18, el charset por defecto era el de la plataforma, a menudo windows-1252 en Windows; [JEP 400](https://openjdk.org/jeps/400) lo convirtió en UTF-8 en todas partes, que es también el valor por defecto de .NET para `File.WriteAllText`. JEP 400 mantuvo una excepción: `System.out` sigue codificando con el charset de la consola, así que un programa Java que imprime `héllo` en un terminal de Windows puede mostrar `h�llo` aunque el archivo que escribió sea correcto.

`Files.lines` y `Files.walk` devuelven streams perezosos sobre un descriptor de archivo o de directorio abierto, y hay que cerrarlos. `File.ReadLines` cierra su archivo cuando termina el `foreach`; un stream no tiene ese enganche, de ahí el `try`-with-resources.

### Excepciones: comprobadas y específicas

Casi todos los métodos de `Files` declaran `IOException`, que es una excepción comprobada (lección 5), así que esto no compila:

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

Las subclases nombran el problema, y algunos casos que .NET acepta sin decir nada son errores:

```java
// Las excepciones son comprobadas, y más específicas que IOException.
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

// UTF-8 inválido: Files.readString lanza una excepción, new String sustituye el byte.
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

| Caso | C# | Java |
|---|---|---|
| archivo inexistente | `FileNotFoundException` | `NoSuchFileException`, cuyo mensaje es solo la ruta |
| crear un directorio que ya existe | `Directory.CreateDirectory`: no pasa nada | `createDirectory` lanza una excepción; `createDirectories` no |
| borrar un directorio no vacío | `IOException` | `DirectoryNotEmptyException` |
| UTF-8 inválido | `File.ReadAllText` sustituye el byte por U+FFFD | `Files.readString` lanza `MalformedInputException` |

La última fila importa en los pipelines de datos: C# lee un archivo corrupto sin quejarse, Java se detiene en el primer byte erróneo. Los dos comportamientos están disponibles en ambos lados; simplemente no son los de por defecto.

### Cultura y configuración regional

`String.format` usa la configuración regional por defecto, igual que `ToString` usa `CurrentCulture`. Un programa que formatea números sin configuración regional imprime `1234,50` en una máquina francesa:

```java
// String.format usa la configuración regional por defecto, como CurrentCulture; pasa una para obtener un resultado fijo.
System.out.println("France: " + String.format(Locale.FRANCE, "%.2f", 1234.5));
System.out.println("ROOT: " + String.format(Locale.ROOT, "%.2f", 1234.5));
System.out.println("Turkish lower case has a dotless i: " + "TITLE".toLowerCase(Locale.forLanguageTag("tr")).equals("tıtle"));
```

```text
France: 1234,50
ROOT: 1234.50
Turkish lower case has a dotless i: true
```

`Locale.ROOT` es `CultureInfo.InvariantCulture`. La prueba del turco es la misma trampa en los dos lenguajes: `toLowerCase()` y `ToLower()` sin argumento usan la configuración regional actual, y en turco la minúscula de `I` es `ı`. Escribe `toLowerCase(Locale.ROOT)` para identificadores, nombres de archivo y palabras clave de protocolos.

## HTTP: `java.net.http.HttpClient`

Java 11 añadió [`java.net.http`](https://docs.oracle.com/en/java/javase/25/docs/api/java.net.http/java/net/http/package-summary.html). Como el de .NET, el cliente está pensado para crearse una vez y reutilizarse, y es `AutoCloseable` desde Java 21. El ejemplo se ejecuta contra [`HttpServer`](https://docs.oracle.com/en/java/javase/25/docs/api/jdk.httpserver/com/sun/net/httpserver/HttpServer.html), un pequeño servidor incluido en el JDK, así que no necesita red; el lado C# usa `HttpListener`.

```java
// HttpClient es AutoCloseable desde Java 21.
try (HttpClient client = HttpClient.newHttpClient()) {
    System.out.println("follows redirects: " + client.followRedirects() + ", connect timeout: " + client.connectTimeout());

    HttpResponse<String> old = client.send(HttpRequest.newBuilder(URI.create(base + "/old")).build(), HttpResponse.BodyHandlers.ofString());
    System.out.println("GET /old: " + old.statusCode() + ", Location: " + old.headers().firstValue("Location").orElseThrow());
    System.out.println("client version: " + client.version() + ", response version: " + old.version());

    // Un código de estado de error es una respuesta normal, no una excepción.
    HttpResponse<String> missing = client.send(HttpRequest.newBuilder(URI.create(base + "/missing")).build(), HttpResponse.BodyHandlers.ofString());
    System.out.println("GET /missing: " + missing.statusCode());

    // Sin timeout salvo que la petición lo fije.
    try {
        client.send(HttpRequest.newBuilder(URI.create(base + "/slow")).timeout(Duration.ofMillis(100)).build(), HttpResponse.BodyHandlers.ofString());
    } catch (HttpTimeoutException e) {
        System.out.println("HttpTimeoutException: " + e.getMessage());
    }
}

// Seguir las redirecciones hay que activarlo; sendAsync devuelve un CompletableFuture.
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

El lado C# imprime:

```text
default timeout: 00:01:40
GET /old: 200 moved here from /new
GET /missing: 404
GetStringAsync: HttpRequestException: Response status code does not indicate success: 404 (Not Found).
TaskCanceledException (TimeoutException): The request was canceled due to the configured HttpClient.Timeout of 0.1 seconds elapsing.
GET /old without redirects: 302, Location: /new
```

| Valor por defecto | `HttpClient` de .NET | `HttpClient` de Java |
|---|---|---|
| redirecciones | se siguen (`AllowAutoRedirect` es `true`) | [no se siguen](https://docs.oracle.com/en/java/javase/25/docs/api/java.net.http/java/net/http/HttpClient.Builder.html#followRedirects(java.net.http.HttpClient.Redirect)): `Redirect.NEVER` |
| timeout | [100 segundos](https://learn.microsoft.com/dotnet/api/system.net.http.httpclient.timeout) | [ninguno](https://docs.oracle.com/en/java/javase/25/docs/api/java.net.http/java/net/http/HttpRequest.Builder.html#timeout(java.time.Duration)): «block forever» |
| versión de HTTP | HTTP/1.1 | prefiere HTTP/2 y recurre a lo que hable el servidor |
| código de estado de error | una respuesta; `GetStringAsync` y `EnsureSuccessStatusCode` lanzan una excepción | siempre una respuesta |
| asincronía | `GetAsync` devuelve un `Task` | `send` bloquea, `sendAsync` devuelve un `CompletableFuture` |

Dos de estos valores por defecto dan problemas en producción. Un cliente Java sin timeout espera para siempre a un servidor que acepta la conexión y nunca responde; fija `timeout` en cada petición, y `connectTimeout` en el builder. Y el código portado desde C# que espera que se sigan las redirecciones recibe un 302 con el cuerpo vacío. El ejercicio 3 escribe el `GetStringAsync` que falta.

Un `send` bloqueante es la opción normal en un hilo virtual (lección 9). `sendAsync` encaja en código que ya compone `CompletableFuture`s.

## Lo que el JDK no tiene

La biblioteca de clases base de .NET abarca más terreno que el JDK. No hay API de JSON en JDK 25: `java --list-modules` muestra `java.net.http` y `jdk.httpserver`, y nada para JSON. Los proyectos usan [Jackson](https://github.com/FasterXML/jackson), que Spring Boot configura por defecto, o [Gson](https://github.com/google/gson). Tampoco hay `IHttpClientFactory` ni inyección de dependencias: eso lo aportan frameworks como Spring, el tema del siguiente curso.

## Puntos clave

- `java.time` tiene un tipo por significado: `Instant`, `LocalDate`, `ZonedDateTime`. `ZonedDateTime` aplica reglas de zona horaria que `DateTimeOffset` no conoce, y resuelve los huecos y los solapamientos en lugar de lanzar una excepción.
- En los patrones de fecha, `Y` es el año basado en semanas y depende de la configuración regional; escribe `yyyy`.
- Construye un `BigDecimal` a partir de una cadena o con `valueOf`, compáralo con `compareTo` y da un `RoundingMode` a cada `divide` y `setScale`.
- Los métodos de `Files` lanzan excepciones comprobadas y específicas, y rechazan el UTF-8 inválido que .NET sustituye. Cierra `Files.lines` y `Files.walk`.
- Pasa un `Locale` a `String.format` y a `toLowerCase` siempre que la salida no esté destinada a una persona.
- El `HttpClient` de Java no sigue las redirecciones y no tiene timeout por defecto; un código de estado de error nunca es una excepción.

## Ejercicios

1. Escribe `addBusinessDays(LocalDate start, int days)`, que se salta los sábados y los domingos. Sumar 1 día hábil al viernes 11 de septiembre de 2026 da el lunes 14; sumar 5 da el viernes 18.

<details>
<summary>Solución</summary>

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

`LocalDate` es inmutable, como `DateOnly`, así que `plusDays` devuelve una fecha nueva que hay que asignar. `DayOfWeek` es un enum, que se compara con `!=` como en C#. La prueba comprueba también que sumar 0 días devuelve la fecha de inicio sin cambios.

</details>

2. Reparte una cuenta de `100.00` entre 3 personas de modo que las partes sumen exactamente el total: `33.34`, `33.33`, `33.33`. Escribe `split(BigDecimal total, int people)`.

<details>
<summary>Solución</summary>

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

Redondear cada parte con `HALF_EVEN` daría tres veces `33.33` y perdería un céntimo. Redondear hacia abajo y repartir después los céntimos restantes mantiene la suma exacta. `divide(cent)` no necesita modo de redondeo porque el resto es un número entero de céntimos, y `intValueExact` lanza una excepción en lugar de truncar si esa suposición llegara a fallar. La prueba compara la suma con `compareTo`, no con `equals`, por la cuestión de la escala vista arriba.

</details>

3. Escribe `getString(HttpClient client, URI uri)`, el equivalente Java de `GetStringAsync`: devuelve el cuerpo, lanza una `IOException` con el mensaje `Response status code does not indicate success: 404` para un código de estado fuera de 2xx y no espera más de 100 segundos. Pruébalo contra un `HttpServer` local con una redirección y un 404.

<details>
<summary>Solución</summary>

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

El timeout va en la petición, donde .NET lo pone en el cliente. Las redirecciones son una propiedad del cliente, así que la prueba construye uno con `Redirect.NORMAL` y comprueba que `/old` devuelve `moved here`, y después que `/missing` lanza la excepción con el mensaje esperado. `IOException` es la opción natural porque `send` ya la declara: quien llama trata un solo tipo de excepción para los errores de red y los de código de estado, como con `HttpRequestException`.

</details>

## Fuentes

- [Resumen del paquete `java.time`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/time/package-summary.html), [`DateTimeFormatter`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/time/format/DateTimeFormatter.html)
- [`BigDecimal`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/math/BigDecimal.html), [`RoundingMode`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/math/RoundingMode.html)
- [`Files`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/nio/file/Files.html), [JEP 400 — UTF-8 by Default](https://openjdk.org/jeps/400)
- [`java.net.http`](https://docs.oracle.com/en/java/javase/25/docs/api/java.net.http/java/net/http/package-summary.html), [`HttpServer`](https://docs.oracle.com/en/java/javase/25/docs/api/jdk.httpserver/com/sun/net/httpserver/HttpServer.html)
- C#: [zonas horarias](https://learn.microsoft.com/dotnet/standard/datetime/time-zone-overview), [globalización e ICU](https://learn.microsoft.com/dotnet/core/extensions/globalization-icu), [`decimal`](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/floating-point-numeric-types), [directrices de `HttpClient`](https://learn.microsoft.com/dotnet/fundamentals/networking/http/httpclient-guidelines)
