---
title: 8. Pattern matching
description: Motifs dans instanceof et switch, déconstruction de records, exhaustivité des types scellés, gardes, cas null et variables anonymes — et les motifs de propriété, relationnels et de liste de C# que Java n'a pas.
sidebar:
  order: 8
---

Exemples complets : [`lessons/l08`](https://github.com/spareilleux/learn/tree/main/code/java-for-csharp/src/main/java/lessons/l08).

## Deux langages qui convergent

Le filtrage par motif (pattern matching) est arrivé par étapes dans les deux langages : en C# à partir de la version 7 (2017), en Java à partir de la 16 (2021). En Java 25, les fonctionnalités finalisées sont les motifs de type dans `instanceof` et `switch`, les motifs de record, les gardes avec `when`, `case null` et les variables anonymes `_`. Elles couvrent le même terrain que les motifs de type, positionnels et d'élimination (discard) de C#. C# va plus loin avec les motifs de propriété, relationnels, logiques et de liste, que Java exprime avec des gardes.

| C# | Java 25 |
|---|---|
| `o is string s` | `o instanceof String s` |
| expression `switch` avec `=>` | expression `switch` avec `->` |
| motif positionnel `Point(var x, var y)` | [motif de record](https://openjdk.org/jeps/440) `Point(var x, var y)` |
| `case Circle c when c.Radius == 0` | `case Circle c when c.radius() == 0` |
| élimination `_` | [variable anonyme](https://openjdk.org/jeps/456) `_` (Java 22) |
| motif `null` | `case null` |
| motif de propriété `{ Total: > 1000 }` | *aucun* : motif de record plus garde |
| relationnel `< 0`, logique `and`, `or`, `not` | *aucun* : garde |
| motif de liste `[var first, .., var last]` | *aucun* |
| avertissement d'exhaustivité CS8509 | **erreur** d'exhaustivité pour les expressions `switch` |

## `instanceof` avec une liaison

La première étape remplace la paire test-puis-cast, comme le `is` de C# avec une déclaration :

```java
Object value = "matched";
if (value instanceof String s && s.length() > 3) {
    System.out.println("long string: " + s);
}
```

```text
long string: matched
```

La variable du motif est accessible partout où le compilateur peut prouver que la correspondance a réussi, y compris après un test négatif qui sort de la méthode :

```java
static int lengthOrZero(Object value) {
    // La variable du motif est accessible partout où la correspondance est certaine.
    if (!(value instanceof String text)) {
        return 0;
    }
    return text.length();
}
```

Là où la correspondance n'est pas certaine, la variable n'existe pas. Avec `||`, `s` pourrait ne pas être liée :

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

Pour le même code, C# signale CS0165, « utilisation d'une variable locale non assignée » : la variable est déclarée mais pas assignée de façon certaine. La règle est la même ; seul le message diffère.

## `switch` sur n'importe quel type

Un [`switch` à motifs](https://docs.oracle.com/en/java/javase/25/language/pattern-matching-switch.html) accepte n'importe quel type référence, et les cas sont testés de haut en bas :

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

Trois détails diffèrent de C# :

- **`null`.** Un `switch` sans `case null` lève `NullPointerException` sur une entrée `null`, même avec un `default`. C'est le comportement d'avant les motifs, conservé pour la compatibilité. C# tombe simplement dans `_`.
- **Les gardes testent ce que C# met dans le motif.** `Integer i when i < 0` est le `int i and < 0` de C#. Il n'y a pas de motifs relationnels, donc la réponse est toujours une garde.
- **Les génériques sont effacés** (leçon 4). `case List<?> list` est permis, mais pas `case List<String> list` sur un `Object` : le type des éléments ne peut pas être vérifié.

Le compilateur rejette un cas qui ne peut jamais correspondre parce qu'un cas précédent intercepte déjà tout ce qu'il accepterait :

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

Dans une expression switch, C# signale la même erreur sous le code CS8510, « Le modèle a déjà été géré par un bras précédent de l'expression switch ». Java refuse aussi un `default` à côté d'un motif qui correspond déjà à tout :

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

Les `switch` sur des enums étaient déjà exhaustifs sans motifs, et plusieurs constantes peuvent partager un même cas :

```java
static String color(Suit suit) {
    // Plusieurs constantes dans un même cas, et pas de default : le switch sur l'enum est exhaustif.
    return switch (suit) {
        case HEARTS, DIAMONDS -> "red";
        case CLUBS, SPADES -> "black";
    };
}
```

```text
red black
```

## Hiérarchies scellées et motifs de record

Les motifs portent leurs fruits avec les interfaces scellées et les records de la leçon 3. Un **motif de record** déconstruit un record en ses composants et s'imbrique à n'importe quelle profondeur. Avec une interface scellée, le compilateur connaît tous les sous-types, donc le `switch` n'a pas besoin de `default` :

```java
record Point(double x, double y) {}

sealed interface Shape permits Circle, Rectangle, Triangle {}

record Circle(Point center, double radius) implements Shape {}

record Rectangle(Point topLeft, Point bottomRight) implements Shape {}

record Triangle(Point a, Point b, Point c) implements Shape {}

// Pas de branche default : le compilateur connaît les trois sous-types permis.
static double area(Shape shape) {
    return switch (shape) {
        case Circle(Point _, double r) -> Math.PI * r * r;
        case Rectangle(Point(var x1, var y1), Point(var x2, var y2)) -> Math.abs(x2 - x1) * Math.abs(y2 - y1);
        case Triangle(Point a, Point b, Point c) ->
            Math.abs((b.x() - a.x()) * (c.y() - a.y()) - (c.x() - a.x()) * (b.y() - a.y())) / 2;
    };
}

// Les gardes affinent un cas avec une condition booléenne.
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

La déconstruction suit l'ordre des composants du record, et les types des composants peuvent être écrits en toutes lettres ou remplacés par `var`. `Point _` ignore un composant. Seuls les records peuvent être déconstruits : Java n'a pas d'équivalent à la méthode `Deconstruct` de C# pour les classes ordinaires.

C'est là que Java est plus strict que C#. Ajoutez un sous-type et oubliez un cas : C# donne l'avertissement CS8509, puis lève `SwitchExpressionException` à l'exécution. Pour une expression `switch`, Java refuse de compiler :

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

Le message ne nomme pas le `Voucher` manquant ; le correctif rapide (quick fix) d'IntelliJ IDEA, si. C'est pourquoi un `switch` sur une hiérarchie scellée s'écrit de préférence **sans** `default` : ajouter un sous-type casse alors le build à chaque endroit qui doit le gérer. Les développeurs C# obtiennent le même effet en traitant CS8509 comme une erreur.

## Ce que deviennent les motifs C# en Java

Les motifs de propriété, relationnels et logiques de C# n'ont pas de syntaxe en Java. Les écrire provoque une erreur d'analyse syntaxique, et les messages n'expliquent pas pourquoi :

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

La traduction est un motif de record (ou un motif de type) plus une garde : `o instanceof Point(var _, var y) && y == 0`. Pour les motifs de liste, testez la taille et indexez la liste. Le côté C# affiche le résultat des motifs dont traite cette section :

```csharp
static string Size(Order order) => order switch
{
    { Items.Count: 0 } => "empty",
    { Total: > 1000 } => "large",
    { Customer: "ada" or "alan", Total: >= 100 and <= 1000 } => "regular customer",
    _ => "normal",
};
```

L'exercice 2 traduit cette méthode.

### Les motifs primitifs sont encore en préversion

Un `switch` sur un `int` accepte des constantes, mais pas des motifs de type comme `byte b` (« tient-il dans un byte ? »). La [JEP 507](https://openjdk.org/jeps/507) les ajoute, mais en Java 25 ils sont encore une fonctionnalité en préversion :

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

Les fonctionnalités en préversion exigent `--enable-preview` à la compilation comme à l'exécution, et elles peuvent changer avant d'être finalisées. Ce cours ne les utilise pas.

## Variables anonymes

Depuis Java 22, `_` désigne une variable qu'il faut déclarer mais qu'on n'utilise pas : dans les motifs, les paramètres de lambda, les clauses `catch` et les boucles `for`. C'est l'élimination (discard) de C# :

```java
// Variables anonymes (Java 22) : _ pour ce qu'on n'utilise pas.
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

## À retenir

- `instanceof T t` et les motifs de `switch` remplacent les casts ; les variables de motif n'existent que là où la correspondance est certaine.
- Une expression `switch` sur un type scellé ou un enum doit être exhaustive, et c'est une erreur de compilation, pas un avertissement. Omettez `default` pour que les nouveaux sous-types cassent le build.
- Les motifs de record déconstruisent et s'imbriquent ; seuls les records peuvent être déconstruits.
- Pas de motifs de propriété, relationnels, logiques ni de liste : utilisez une garde (`when`).
- `case null` doit être explicite, sinon le `switch` lève une exception. Les cas dominés et un `default` à côté d'un motif inconditionnel sont des erreurs.
- Les motifs de type primitifs sont encore en préversion en Java 25.

## Exercices

1. Modélisez des expressions arithmétiques par une interface scellée `Expr` avec les records `Num(int)`, `Add(Expr, Expr)`, `Mul(Expr, Expr)` et `Neg(Expr)`. Écrivez `eval`, puis `simplify`, qui supprime `1 *`, `* 1`, `0 +` et la double négation, récursivement.

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

`simplify(new Add(new Num(0), new Mul(new Num(1), new Neg(new Neg(new Num(7))))))` renvoie `Num[value=7]`. Java n'a pas de motifs constants à l'intérieur d'un motif de record (le `Mul(Num(1), var e)` de C#), donc le `1` devient une garde. Les cas spécifiques précèdent les cas généraux `Add`, `Mul` et `Neg`. Les records se comparent par valeur, le test peut donc vérifier le résultat avec `equals`.

</details>

2. Traduisez la méthode C# `Size` de la section sur les motifs C#, avec des records `Order(String customer, double total, List<String> items)`.

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

Chaque motif de propriété C# devient une déconstruction qui nomme les composants dont elle a besoin, plus une garde. `case Order _` est le dernier cas, inconditionnel ; `default` fonctionnerait aussi. Une chaîne faite uniquement de gardes comme celle-ci est souvent plus claire sous forme d'instructions `if`, et la version C# est plus courte. C'est un des endroits où C# est plus expressif.

</details>

3. Modélisez une valeur JSON par une interface scellée avec les records `JNull`, `JBool`, `JNumber`, `JString`, `JArray(List<Json>)` et `JObject(Map<String, Json>)`. Écrivez `render(Json)`, qui affiche les nombres entiers sans point décimal et échappe les guillemets dans les chaînes.

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

Un objet avec `name` = `Ada "Countess"` et `tags` = `[1, 2.5, true, null]` est rendu sous la forme `{"name":"Ada \"Countess\"","tags":[1,2.5,true,null]}` quand la map conserve l'ordre d'insertion (`LinkedHashMap`). Ajouter un record `JDate` à `permits` empêcherait ce `switch` de compiler tant qu'il ne gère pas le nouveau cas, et c'est tout l'intérêt de cette conception. L'échappement est volontairement minimal : un vrai sérialiseur échappe aussi les barres obliques inverses et les caractères de contrôle.

</details>

## Sources

- [Guide du langage Java — Pattern matching](https://docs.oracle.com/en/java/javase/25/language/pattern-matching.html)
- [JEP 441 — Pattern matching for switch](https://openjdk.org/jeps/441), [JEP 440 — Record patterns](https://openjdk.org/jeps/440), [JEP 456 — Unnamed variables and patterns](https://openjdk.org/jeps/456), [JEP 507 — Primitive types in patterns (third preview)](https://openjdk.org/jeps/507)
- [C# — Modèles](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/patterns)
