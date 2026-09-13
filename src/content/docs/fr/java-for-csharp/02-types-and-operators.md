---
title: 2. Types, égalité et opérateurs
description: Primitifs et boxing, aucun type non signé, dépassement silencieux, == sur les objets, var et final, blocs de texte et expressions switch — comparés à C#.
sidebar:
  order: 2
---

Exemples complets : [`lessons/l02`](https://github.com/spareilleux/learn/tree/main/code/java-for-csharp/src/main/java/lessons/l02) — après `mvn compile`, lancez-en un avec `java -cp target/classes lessons.l02.Numbers` ; la CI vérifie chaque sortie ci-dessous.

## Deux sortes de types, et pas de `struct`

| | C# | Java |
|---|---|---|
| Types valeur intégrés | `int`, `long`, `double`, `bool`, `char`, `decimal`… | 8 [types primitifs](https://docs.oracle.com/javase/specs/jls/se25/html/jls-4.html#jls-4.2) : `byte short int long float double boolean char` |
| Types valeur définis par l'utilisateur | `struct`, `record struct` | aucun (voir [Project Valhalla](https://openjdk.org/projects/valhalla/)) |
| Tout le reste | types référence | types référence |
| Entiers non signés | `byte`, `ushort`, `uint`, `ulong` | aucun |
| Arithmétique décimale | `decimal` | la classe [`BigDecimal`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/math/BigDecimal.html) |
| Primitif dans un contexte objet | boxing vers `object` | boxing vers une *classe enveloppe* (wrapper) : `Integer`, `Long`, `Boolean`… |

En C#, `int` *est* `System.Int32`, une struct dotée de méthodes. En Java, `int` est un primitif sans méthodes, et `Integer` est une classe distincte. Le compilateur convertit automatiquement de l'un à l'autre ([autoboxing](https://docs.oracle.com/javase/tutorial/java/data/autoboxing.html)), ce qui est pratique jusqu'au jour où ça ne l'est plus.

## Nombres

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

- **Le dépassement reboucle en silence**, exactement comme C# dans son contexte `unchecked` par défaut. Java n'a pas de mot-clé `checked` : [`Math.addExact`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Math.html#addExact(int,int)), `multiplyExact` et consorts lèvent une exception à la place.
- **`byte` est signé** (de −128 à 127). C'est en lisant des octets depuis un fichier ou un tampon réseau que ça fait mal : `(byte) 200` vaut `-56`, et `Byte.toUnsignedInt` vous rend le 200. En C#, `byte` est non signé et c'est `sbyte` qui est signé.
- **Pas de `uint` ni de `ulong`**, mais `Integer` et `Long` ont des méthodes statiques qui *interprètent* les mêmes bits comme non signés.

Le côté C#, exécuté par la CI du cours :

```text
-2147483648
OverflowException: Arithmetic operation resulted in an overflow.
200
-56
```

La division et l'arithmétique sur les `char` se comportent de la même façon dans les deux langages : la division entière par zéro lève une exception (`ArithmeticException: / by zero` contre `DivideByZeroException`), la division en virgule flottante donne `Infinity`, et `'a' + 1` est l'`int` 98.

## `==` compare les références pour les objets

C'est celui à retenir. Pour les primitifs, `==` compare les valeurs. Pour les objets — `Integer` et `String` compris — il compare les **références**, et Java n'a pas de surcharge d'opérateurs pour changer cela.

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

- `a == b` vaut `true` uniquement parce que l'autoboxing passe par [`Integer.valueOf`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Integer.html#valueOf(int)), qui met en cache les valeurs de −128 à 127. À partir de 128, chaque boxing crée un nouvel objet. Du code qui compare des `Integer` avec `==` passe tous les tests avec de petits identifiants et échoue en production.
- Deux littéraux de chaîne identiques sont le même objet (les littéraux sont *internés*), mais une chaîne construite à l'exécution ne l'est pas.
- **Utilisez `equals`** pour les objets, toujours. [`Objects.equals(x, y)`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Objects.html#equals(java.lang.Object,java.lang.Object)) gère aussi `null`.

En C#, `string` surcharge `==` pour comparer le contenu, donc `literal == built` vaut `True`. Des valeurs boxées comparées en tant qu'`object` se comportent comme en Java, mais on écrit rarement cela en C# :

```csharp
object boxedA = 127, boxedB = 127;
Console.WriteLine(boxedA == boxedB);        // False : comparaison de références sur object

string literal = "hello";
string built = new System.Text.StringBuilder("hel").Append("lo").ToString();
Console.WriteLine(literal == built);         // True : string surcharge ==
```

Le boxing fait aussi entrer `null` dans l'arithmétique. Déballer un `Integer` `null` lève une exception, et depuis Java 14 le message indique exactement quelle variable était nulle ([NullPointerExceptions explicites](https://openjdk.org/jeps/358)) :

```java
Integer missing = null;
int value = missing;
```

```text
NullPointerException: Cannot invoke "java.lang.Integer.intValue()" because "missing" is null
```

## `var` et `final`

```java
var name = "Ada";          // inféré en String
final var year = 1843;     // ne peut pas être réaffecté ; C# n'a pas d'équivalent pour les variables locales
```

[`var`](https://docs.oracle.com/en/java/javase/25/language/local-variable-type-inference.html) fonctionne comme en C#, mais uniquement pour les **variables locales** avec un initialiseur :

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

`final` sur une variable locale ou un champ signifie « affecté exactement une fois » — le `readonly` de C# pour les champs, et quelque chose pour lequel C# n'a pas de mot-clé sur les variables locales. Il n'y a pas de `const` : une constante est un champ `static final`.

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

## Les conversions sont aussi strictes qu'en C#

Une conversion restrictive exige un cast, un `int` n'est pas un `boolean`, et une variable locale doit être définitivement affectée avant d'être utilisée. Les règles correspondent à celles de C# presque une à une :

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

## Chaînes : formatage et blocs de texte

Java n'a pas d'interpolation de chaînes. Les [string templates](https://openjdk.org/jeps/465) ont été proposés en préversion dans Java 21 et 22, puis retirés. On formate avec [`String.formatted`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/String.html#formatted(java.lang.Object...)) (ou `String.format`), avec des spécificateurs à la `printf` :

```java
System.out.println("%s published her notes in %d.".formatted(name, year));
```

```text
Ada published her notes in 1843.
```

Les [blocs de texte](https://docs.oracle.com/en/java/javase/25/text-blocks/index.html) sont les chaînes multilignes de Java, proches des littéraux de chaîne bruts de C#. Le `"""` fermant fixe l'indentation à retirer :

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

## Expressions `switch`

Le [`switch`](https://docs.oracle.com/en/java/javase/25/language/switch-expressions-and-statements.html) à flèches est une expression, comme l'expression `switch` de C#, et ne passe jamais d'un cas au suivant (pas de fall-through). Un bloc qui calcule la valeur se termine par `yield` :

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

Un `switch` sur un enum qui énumère toutes les constantes n'a pas besoin de `default`. Sur un `int`, si, et Java en fait une erreur là où C# ne donne qu'un avertissement (CS8509) :

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

La leçon 8 va plus loin avec `switch`, grâce aux motifs et aux types scellés.

## À retenir

- Java a huit primitifs et aucun type valeur défini par l'utilisateur ; tout le reste est une référence.
- `==` sur des objets compare des références : utilisez `equals`. Le cache d'`Integer` donne l'illusion que `==` fonctionne pour les petits nombres.
- Le dépassement est silencieux ; `Math.*Exact` est l'équivalent de `checked`. `byte` est signé et il n'y a pas de types non signés.
- `var` est réservé aux variables locales ; `final` signifie affecté une seule fois ; les constantes sont `static final`.
- Pas d'interpolation : `formatted`, les blocs de texte, et les expressions `switch` avec `->` et `yield`.

## Exercices

1. Sans l'exécuter, prédisez la sortie. Expliquez ensuite comment corriger la méthode.

```java
static boolean sameId(Integer left, Integer right) {
    return left == right;
}
// sameId(42, 42)   → ?
// sameId(1000, 1000) → ?
```

<details>
<summary>Solution</summary>

`true`, puis `false` : 42 est dans le cache d'`Integer`, donc les deux arguments sont boxés vers le même objet ; 1000 ne l'est pas, ce sont donc deux objets. Comparez les valeurs avec `left.equals(right)`, ou `Objects.equals(left, right)` si l'un des deux peut être `null`. Si `null` n'est pas un identifiant valide, la meilleure correction est de déclarer les paramètres en `int`.

</details>

2. Une méthode C# lit une longueur sous forme de `uint` dans un en-tête binaire. Écrivez l'équivalent Java de `uint length = BitConverter.ToUInt32(bytes, 0);` pour un `byte[]` little-endian, en renvoyant une valeur capable de contenir n'importe quel `uint`.

<details>
<summary>Solution</summary>

```java
static long readUInt32LittleEndian(byte[] bytes) {
    return java.nio.ByteBuffer.wrap(bytes, 0, 4)
            .order(java.nio.ByteOrder.LITTLE_ENDIAN)
            .getInt() & 0xFFFFFFFFL;
}
```

`getInt()` renvoie un `int` signé ; le masque `0xFFFFFFFFL` l'élargit en `long` sans extension de signe (`Integer.toUnsignedLong` fait la même chose). `ByteBuffer` est big-endian par défaut, contrairement à `BitConverter` sur x86, d'où l'`order` explicite.

</details>

3. Réécrivez cette méthode C# en Java, en gardant une expression :

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

Java 25 n'a pas de motifs relationnels comme `>= 200 and < 300` sur les primitifs (les motifs primitifs sont [encore en préversion](https://openjdk.org/jeps/507)) : la vérification d'intervalle passe donc dans la branche `default` — ou toute la méthode devient une chaîne de `if`.

</details>

## Sources

- [JLS §4.2 — Primitive types and values](https://docs.oracle.com/javase/specs/jls/se25/html/jls-4.html#jls-4.2) et [§5.1.7 — Boxing conversion](https://docs.oracle.com/javase/specs/jls/se25/html/jls-5.html#jls-5.1.7) (qui impose le cache de −128 à 127)
- [JLS §15.21 — Equality operators](https://docs.oracle.com/javase/specs/jls/se25/html/jls-15.html#jls-15.21)
- [Oracle — Programmer's Guide to Text Blocks](https://docs.oracle.com/en/java/javase/25/text-blocks/index.html)
- [JEP 361 — Switch expressions](https://openjdk.org/jeps/361)
- [C# — Instructions checked et unchecked](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/checked-and-unchecked)
