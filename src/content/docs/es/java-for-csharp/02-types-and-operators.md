---
title: 2. Tipos, igualdad y operadores
description: Primitivos y boxing, ningún tipo sin signo, desbordamiento silencioso, == sobre objetos, var y final, bloques de texto y expresiones switch — comparados con C#.
sidebar:
  order: 2
---

Ejemplos completos: [`lessons/l02`](https://github.com/spareilleux/learn/tree/main/code/java-for-csharp/src/main/java/lessons/l02) — después de `mvn compile`, ejecuta uno con `java -cp target/classes lessons.l02.Numbers`; la CI comprueba cada salida de abajo.

## Dos clases de tipos, y ningún `struct`

| | C# | Java |
|---|---|---|
| Tipos de valor integrados | `int`, `long`, `double`, `bool`, `char`, `decimal`… | 8 [tipos primitivos](https://docs.oracle.com/javase/specs/jls/se25/html/jls-4.html#jls-4.2): `byte short int long float double boolean char` |
| Tipos de valor definidos por el usuario | `struct`, `record struct` | ninguno (consulta [Project Valhalla](https://openjdk.org/projects/valhalla/)) |
| Todo lo demás | tipos de referencia | tipos de referencia |
| Enteros sin signo | `byte`, `ushort`, `uint`, `ulong` | ninguno |
| Aritmética decimal | `decimal` | la clase [`BigDecimal`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/math/BigDecimal.html) |
| Primitivo en un contexto de objeto | boxing a `object` | boxing a una *clase envoltorio* (wrapper): `Integer`, `Long`, `Boolean`… |

En C#, `int` *es* `System.Int32`, un struct con métodos. En Java, `int` es un primitivo sin métodos, e `Integer` es una clase aparte. El compilador convierte automáticamente entre ambos ([autoboxing](https://docs.oracle.com/javase/tutorial/java/data/autoboxing.html)), lo cual es cómodo hasta que deja de serlo.

## Números

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

- **El desbordamiento da la vuelta en silencio**, exactamente como C# en su contexto `unchecked` por defecto. Java no tiene la palabra clave `checked`: [`Math.addExact`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Math.html#addExact(int,int)), `multiplyExact` y compañía lanzan una excepción en su lugar.
- **`byte` tiene signo** (de −128 a 127). Donde duele es al leer bytes de un archivo o de un búfer de red: `(byte) 200` vale `-56`, y `Byte.toUnsignedInt` te devuelve el 200. En C#, `byte` no tiene signo y el que lo tiene es `sbyte`.
- **No hay `uint` ni `ulong`**, pero `Integer` y `Long` tienen métodos estáticos que *interpretan* los mismos bits como valores sin signo.

El lado C#, ejecutado por la CI del curso:

```text
-2147483648
OverflowException: Arithmetic operation resulted in an overflow.
200
-56
```

La división y la aritmética con `char` se comportan igual en los dos lenguajes: la división entera por cero lanza una excepción (`ArithmeticException: / by zero` frente a `DivideByZeroException`), la división en coma flotante da `Infinity`, y `'a' + 1` es el `int` 98.

## `==` compara referencias en los objetos

Esto es lo que hay que recordar. Para los primitivos, `==` compara valores. Para los objetos — `Integer` y `String` incluidos — compara **referencias**, y Java no tiene sobrecarga de operadores para cambiarlo.

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

- `a == b` es `true` solo porque el autoboxing pasa por [`Integer.valueOf`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Integer.html#valueOf(int)), que guarda en caché los valores de −128 a 127. A partir de 128, cada boxing crea un objeto nuevo. El código que compara `Integer` con `==` pasa todas las pruebas con identificadores pequeños y falla en producción.
- Dos literales de cadena idénticos son el mismo objeto (los literales están *internados*), pero una cadena construida en tiempo de ejecución no lo es.
- **Usa `equals`** con los objetos, siempre. [`Objects.equals(x, y)`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Objects.html#equals(java.lang.Object,java.lang.Object)) también gestiona `null`.

En C#, `string` sobrecarga `==` para comparar el contenido, así que `literal == built` es `True`. Los valores con boxing comparados como `object` se comportan como en Java, pero eso rara vez se escribe en C#:

```csharp
object boxedA = 127, boxedB = 127;
Console.WriteLine(boxedA == boxedB);        // False: comparación de referencias sobre object

string literal = "hello";
string built = new System.Text.StringBuilder("hel").Append("lo").ToString();
Console.WriteLine(literal == built);         // True: string sobrecarga ==
```

El boxing también mete `null` en la aritmética. Hacer unboxing de un `Integer` `null` lanza una excepción, y desde Java 14 el mensaje dice exactamente qué variable era nula ([NullPointerExceptions útiles](https://openjdk.org/jeps/358)):

```java
Integer missing = null;
int value = missing;
```

```text
NullPointerException: Cannot invoke "java.lang.Integer.intValue()" because "missing" is null
```

## `var` y `final`

```java
var name = "Ada";          // inferido como String
final var year = 1843;     // no se puede reasignar; C# no tiene equivalente para las variables locales
```

[`var`](https://docs.oracle.com/en/java/javase/25/language/local-variable-type-inference.html) funciona como en C#, pero solo para **variables locales** con inicializador:

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

`final` en una variable local o un campo significa «asignado exactamente una vez» — el `readonly` de C# para los campos, y algo para lo que C# no tiene palabra clave en las variables locales. No hay `const`: una constante es un campo `static final`.

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

## Las conversiones son tan estrictas como en C#

Una conversión de restricción requiere un cast, un `int` no es un `boolean`, y una variable local debe estar definitivamente asignada antes de usarse. Las reglas coinciden con las de C# casi una por una:

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

## Cadenas: formato y bloques de texto

Java no tiene interpolación de cadenas. Las [string templates](https://openjdk.org/jeps/465) se ofrecieron como versión preliminar en Java 21 y 22, y luego se retiraron. Se formatea con [`String.formatted`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/String.html#formatted(java.lang.Object...)) (o `String.format`), con especificadores al estilo de `printf`:

```java
System.out.println("%s published her notes in %d.".formatted(name, year));
```

```text
Ada published her notes in 1843.
```

Los [bloques de texto](https://docs.oracle.com/en/java/javase/25/text-blocks/index.html) son las cadenas multilínea de Java, parecidas a los literales de cadena sin formato de C#. El `"""` de cierre fija la sangría que se elimina:

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

## Expresiones `switch`

El [`switch`](https://docs.oracle.com/en/java/javase/25/language/switch-expressions-and-statements.html) con flechas es una expresión, como la expresión `switch` de C#, y nunca pasa de un caso al siguiente (no hay fall-through). Un bloque que calcula el valor termina con `yield`:

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

Un `switch` sobre un enum que enumera todas las constantes no necesita `default`. Sobre un `int` sí, y Java lo convierte en un error donde C# solo da una advertencia (CS8509):

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

La lección 8 lleva `switch` más lejos, con patrones y tipos sellados.

## Puntos clave

- Java tiene ocho primitivos y ningún tipo de valor definido por el usuario; todo lo demás es una referencia.
- `==` sobre objetos compara referencias: usa `equals`. La caché de `Integer` hace que `==` parezca correcto con números pequeños.
- El desbordamiento es silencioso; `Math.*Exact` es el equivalente de `checked`. `byte` tiene signo y no hay tipos sin signo.
- `var` es solo para variables locales; `final` significa asignado una sola vez; las constantes son `static final`.
- Sin interpolación: `formatted`, bloques de texto y expresiones `switch` con `->` y `yield`.

## Ejercicios

1. Sin ejecutarlo, predice la salida. Después explica cómo corregir el método.

```java
static boolean sameId(Integer left, Integer right) {
    return left == right;
}
// sameId(42, 42)   → ?
// sameId(1000, 1000) → ?
```

<details>
<summary>Solución</summary>

`true` y luego `false`: 42 está dentro de la caché de `Integer`, así que los dos argumentos se convierten con boxing en el mismo objeto; 1000 no lo está, así que son dos objetos. Compara los valores con `left.equals(right)`, u `Objects.equals(left, right)` si alguno puede ser `null`. Si `null` no es un identificador válido, la mejor corrección es declarar los parámetros como `int`.

</details>

2. Un método C# lee una longitud como `uint` de una cabecera binaria. Escribe el equivalente Java de `uint length = BitConverter.ToUInt32(bytes, 0);` para un `byte[]` little-endian, devolviendo un valor que pueda contener cualquier `uint`.

<details>
<summary>Solución</summary>

```java
static long readUInt32LittleEndian(byte[] bytes) {
    return java.nio.ByteBuffer.wrap(bytes, 0, 4)
            .order(java.nio.ByteOrder.LITTLE_ENDIAN)
            .getInt() & 0xFFFFFFFFL;
}
```

`getInt()` devuelve un `int` con signo; la máscara `0xFFFFFFFFL` lo amplía a `long` sin extensión de signo (`Integer.toUnsignedLong` hace lo mismo). `ByteBuffer` es big-endian por defecto, a diferencia de `BitConverter` en x86, de ahí el `order` explícito.

</details>

3. Reescribe este método C# en Java, manteniéndolo como expresión:

```csharp
static string Classify(int status) => status switch
{
    >= 200 and < 300 => "success",
    404 => "not found",
    _ => "other",
};
```

<details>
<summary>Solución</summary>

```java
static String classify(int status) {
    return switch (status) {
        case 404 -> "not found";
        default -> status >= 200 && status < 300 ? "success" : "other";
    };
}
```

Java 25 no tiene patrones relacionales como `>= 200 and < 300` sobre primitivos (los patrones primitivos [siguen en versión preliminar](https://openjdk.org/jeps/507)), así que la comprobación del rango pasa a la rama `default` — o todo el método se convierte en una cadena de `if`.

</details>

## Fuentes

- [JLS §4.2 — Primitive types and values](https://docs.oracle.com/javase/specs/jls/se25/html/jls-4.html#jls-4.2) y [§5.1.7 — Boxing conversion](https://docs.oracle.com/javase/specs/jls/se25/html/jls-5.html#jls-5.1.7) (que exige la caché de −128 a 127)
- [JLS §15.21 — Equality operators](https://docs.oracle.com/javase/specs/jls/se25/html/jls-15.html#jls-15.21)
- [Oracle — Programmer's Guide to Text Blocks](https://docs.oracle.com/en/java/javase/25/text-blocks/index.html)
- [JEP 361 — Switch expressions](https://openjdk.org/jeps/361)
- [C# — Instrucciones checked y unchecked](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/checked-and-unchecked)
