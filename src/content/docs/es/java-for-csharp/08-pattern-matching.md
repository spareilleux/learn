---
title: 8. Pattern matching
description: Patrones en instanceof y switch, deconstrucción de records, exhaustividad con tipos sellados, guardas, casos null y variables sin nombre — y los patrones de propiedad, relacionales y de lista de C# que Java no tiene.
sidebar:
  order: 8
---

Ejemplos completos: [`lessons/l08`](https://github.com/spareilleux/learn/tree/main/code/java-for-csharp/src/main/java/lessons/l08).

## Dos lenguajes que convergen

El pattern matching llegó a los dos lenguajes por etapas: a C# desde la versión 7 (2017), a Java desde la 16 (2021). En Java 25, las funcionalidades definitivas son los patrones de tipo en `instanceof` y `switch`, los patrones de record, las guardas con `when`, `case null` y las variables sin nombre `_`. Cubren el mismo terreno que los patrones de tipo, posicionales y de descarte de C#. C# va más allá con los patrones de propiedad, relacionales, lógicos y de lista, que Java expresa con guardas.

| C# | Java 25 |
|---|---|
| `o is string s` | `o instanceof String s` |
| expresión `switch` con `=>` | expresión `switch` con `->` |
| patrón posicional `Point(var x, var y)` | [patrón de record](https://openjdk.org/jeps/440) `Point(var x, var y)` |
| `case Circle c when c.Radius == 0` | `case Circle c when c.radius() == 0` |
| descarte `_` | [variable sin nombre](https://openjdk.org/jeps/456) `_` (Java 22) |
| patrón `null` | `case null` |
| patrón de propiedad `{ Total: > 1000 }` | *ninguno*: patrón de record más guarda |
| relacional `< 0`, lógicos `and`, `or`, `not` | *ninguno*: guarda |
| patrón de lista `[var first, .., var last]` | *ninguno* |
| advertencia de exhaustividad CS8509 | **error** de exhaustividad para las expresiones `switch` |

## `instanceof` con una variable ligada

El primer paso sustituye el par comprobación y cast, como el `is` de C# con una declaración:

```java
Object value = "matched";
if (value instanceof String s && s.length() > 3) {
    System.out.println("long string: " + s);
}
```

```text
long string: matched
```

La variable de patrón está en ámbito allí donde el compilador puede demostrar que la coincidencia ha tenido éxito, incluso después de una comprobación negada que retorna antes:

```java
static int lengthOrZero(Object value) {
    // La variable de patrón está en ámbito allí donde la coincidencia es segura.
    if (!(value instanceof String text)) {
        return 0;
    }
    return text.length();
}
```

Donde la coincidencia no es segura, la variable no existe. Con `||`, puede que `s` no esté ligada:

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

C# informa de CS0165, «use of unassigned local variable», para el mismo código: la variable está declarada pero no definitivamente asignada. La regla es la misma; solo cambia el mensaje.

## `switch` sobre cualquier tipo

Un [`switch` con patrones](https://docs.oracle.com/en/java/javase/25/language/pattern-matching-switch.html) acepta cualquier tipo de referencia, y los casos se prueban de arriba abajo:

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

Tres detalles difieren de C#:

- **`null`.** Un `switch` sin `case null` lanza `NullPointerException` ante una entrada `null`, incluso con un `default`. Es el comportamiento anterior a los patrones, conservado por compatibilidad. C# simplemente cae en `_`.
- **Las guardas comprueban lo que C# pone en el patrón.** `Integer i when i < 0` es el `int i and < 0` de C#. No hay patrones relacionales, así que la respuesta siempre es una guarda.
- **Los genéricos se borran** (lección 4). `case List<?> list` está permitido, pero `case List<String> list` sobre un `Object` no: el tipo de los elementos no se puede comprobar.

El compilador rechaza un caso que nunca puede coincidir porque uno anterior ya captura todo lo que capturaría:

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

C# informa del mismo error en una expresión switch como error CS8510, «The pattern has already been handled by a previous arm of the switch expression». Java también rechaza un `default` junto a un patrón que ya coincide con todo:

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

Los switch sobre enums ya eran exhaustivos sin patrones, y varias constantes pueden compartir un caso:

```java
static String color(Suit suit) {
    // Varias constantes en un case, y sin default: el switch sobre el enum es exhaustivo.
    return switch (suit) {
        case HEARTS, DIAMONDS -> "red";
        case CLUBS, SPADES -> "black";
    };
}
```

```text
red black
```

## Jerarquías selladas y patrones de record

Los patrones rinden con las interfaces selladas y los records de la lección 3. Un **patrón de record** descompone un record en sus componentes y se anida a cualquier profundidad. Con una interfaz sellada, el compilador conoce todos los subtipos, así que el `switch` no necesita `default`:

```java
record Point(double x, double y) {}

sealed interface Shape permits Circle, Rectangle, Triangle {}

record Circle(Point center, double radius) implements Shape {}

record Rectangle(Point topLeft, Point bottomRight) implements Shape {}

record Triangle(Point a, Point b, Point c) implements Shape {}

// Sin rama default: el compilador conoce los tres subtipos permitidos.
static double area(Shape shape) {
    return switch (shape) {
        case Circle(Point _, double r) -> Math.PI * r * r;
        case Rectangle(Point(var x1, var y1), Point(var x2, var y2)) -> Math.abs(x2 - x1) * Math.abs(y2 - y1);
        case Triangle(Point a, Point b, Point c) ->
            Math.abs((b.x() - a.x()) * (c.y() - a.y()) - (c.x() - a.x()) * (b.y() - a.y())) / 2;
    };
}

// Las guardas refinan un case con una condición booleana.
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

La deconstrucción sigue el orden de los componentes del record, y los tipos de los componentes pueden escribirse explícitamente o sustituirse por `var`. `Point _` ignora un componente. Solo los records se pueden deconstruir: Java no tiene equivalente al método `Deconstruct` de C# para las clases ordinarias.

Aquí es donde Java es más estricto que C#. Si añades un subtipo y olvidas un caso, C# da la advertencia CS8509 y después lanza `SwitchExpressionException` en tiempo de ejecución. Para una expresión `switch`, Java se niega a compilar:

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

El mensaje no nombra el `Voucher` que falta; la corrección rápida de IntelliJ IDEA sí lo hace. Por eso, un switch sobre una jerarquía sellada se escribe mejor **sin** `default`: añadir un subtipo rompe entonces el build en cada lugar que debe tratarlo. Los desarrolladores C# obtienen el mismo efecto tratando CS8509 como un error.

## En qué se convierten los patrones de C# en Java

Los patrones de propiedad, relacionales y lógicos de C# no tienen sintaxis en Java. Escribirlos es un error de análisis sintáctico, y los mensajes no explican por qué:

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

La traducción es un patrón de record (o un patrón de tipo) más una guarda: `o instanceof Point(var _, var y) && y == 0`. Para los patrones de lista, comprueba el tamaño e indexa la lista. El lado C# imprime el resultado de los patrones de los que trata esta sección:

```csharp
static string Size(Order order) => order switch
{
    { Items.Count: 0 } => "empty",
    { Total: > 1000 } => "large",
    { Customer: "ada" or "alan", Total: >= 100 and <= 1000 } => "regular customer",
    _ => "normal",
};
```

El ejercicio 2 traduce este método.

### Los patrones primitivos siguen en preview

Un `switch` sobre un `int` acepta constantes, pero no patrones de tipo como `byte b` («¿cabe en un byte?»). [JEP 507](https://openjdk.org/jeps/507) los añade, pero en Java 25 siguen siendo una funcionalidad en preview:

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

Las funcionalidades en preview necesitan `--enable-preview` tanto en compilación como en ejecución, y pueden cambiar antes de ser definitivas. Este curso no las usa.

## Variables sin nombre

Desde Java 22, `_` marca una variable que debes declarar pero no usas: en patrones, parámetros de lambdas, cláusulas `catch` y bucles `for`. Es el descarte de C#:

```java
// Variables sin nombre (Java 22): _ para lo que no usas.
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

## Puntos clave

- `instanceof T t` y los patrones de `switch` sustituyen a los casts; las variables de patrón solo existen donde la coincidencia es segura.
- Una expresión `switch` sobre un tipo sellado o un enum debe ser exhaustiva, y si no lo es se produce un error de compilación, no una advertencia. Omite `default` para que los nuevos subtipos rompan el build.
- Los patrones de record deconstruyen y se anidan; solo los records se pueden deconstruir.
- No hay patrones de propiedad, relacionales, lógicos ni de lista: usa una guarda (`when`).
- `case null` debe ser explícito, o el `switch` lanza una excepción. Los casos dominados y un `default` junto a un patrón incondicional son errores.
- Los patrones de tipos primitivos siguen en preview en Java 25.

## Ejercicios

1. Modela expresiones aritméticas como una interfaz sellada `Expr` con los records `Num(int)`, `Add(Expr, Expr)`, `Mul(Expr, Expr)` y `Neg(Expr)`. Escribe `eval` y después `simplify`, que elimina `1 *`, `* 1`, `0 +` y la doble negación, de forma recursiva.

<details>
<summary>Solución</summary>

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

`simplify(new Add(new Num(0), new Mul(new Num(1), new Neg(new Neg(new Num(7))))))` devuelve `Num[value=7]`. Java no tiene patrones constantes dentro de un patrón de record (el `Mul(Num(1), var e)` de C#), así que el `1` se convierte en una guarda. Los casos específicos van antes de los casos generales `Add`, `Mul` y `Neg`. Los records se comparan por valor, así que la prueba puede comprobar el resultado con `equals`.

</details>

2. Traduce el método C# `Size` de la sección sobre los patrones de C#, usando records `Order(String customer, double total, List<String> items)`.

<details>
<summary>Solución</summary>

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

Cada patrón de propiedad de C# se convierte en una deconstrucción que nombra los componentes que necesita, más una guarda. `case Order _` es el último caso, incondicional; `default` también funcionaría. Una cadena basada solo en guardas como esta suele quedar más clara con sentencias `if`, y la versión de C# es más corta. Es un punto en el que C# es más expresivo.

</details>

3. Modela un valor JSON como una interfaz sellada con los records `JNull`, `JBool`, `JNumber`, `JString`, `JArray(List<Json>)` y `JObject(Map<String, Json>)`. Escribe `render(Json)`, que imprime los números enteros sin punto decimal y escapa las comillas en las cadenas.

<details>
<summary>Solución</summary>

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

Un objeto con `name` = `Ada "Countess"` y `tags` = `[1, 2.5, true, null]` se representa como `{"name":"Ada \"Countess\"","tags":[1,2.5,true,null]}` cuando el mapa conserva el orden de inserción (`LinkedHashMap`). Añadir un record `JDate` a `permits` haría que este `switch` dejara de compilar hasta que trate el nuevo caso, y ese es el objetivo del diseño. El escapado es deliberadamente mínimo: un serializador real también escapa las barras invertidas y los caracteres de control.

</details>

## Fuentes

- [Guía del lenguaje Java — Pattern matching](https://docs.oracle.com/en/java/javase/25/language/pattern-matching.html)
- [JEP 441 — Pattern matching for switch](https://openjdk.org/jeps/441), [JEP 440 — Record patterns](https://openjdk.org/jeps/440), [JEP 456 — Unnamed variables and patterns](https://openjdk.org/jeps/456), [JEP 507 — Primitive types in patterns (third preview)](https://openjdk.org/jeps/507)
- [C# — Patrones](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/patterns)
