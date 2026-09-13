---
title: 3. Classes, records et enums
description: Des getters au lieu des propriétés, virtuel par défaut, accès package-private, records, enums qui sont des classes, et interfaces scellées — comparés à C#.
sidebar:
  order: 3
---

Exemples complets : [`lessons/l03`](https://github.com/spareilleux/learn/tree/main/code/java-for-csharp/src/main/java/lessons/l03).

## Classes : ce qui manque, ce qui diffère

```java
static class Account {
    private final String owner;
    private long balanceCents;

    Account(String owner, long openingCents) {
        if (openingCents < 0) {
            throw new IllegalArgumentException("opening balance must not be negative");
        }
        this.owner = owner;
        this.balanceCents = openingCents;
    }

    String getOwner() {
        return owner;
    }

    long getBalanceCents() {
        return balanceCents;
    }

    void deposit(long cents) {
        balanceCents += cents;
    }

    String describe() {
        return owner + ": " + balanceCents + " cents";
    }
}
```

En venant de C#, quatre choses sautent aux yeux :

- **Pas de propriétés.** Un champ est privé et exposé par des méthodes `getX()`/`setX()`, la convention [JavaBeans](https://docs.oracle.com/javase/tutorial/javabeans/writing/properties.html) sur laquelle s'appuient des frameworks comme Spring et Jackson. Les records (plus bas) éliminent l'essentiel de ce code répétitif.
- **Pas de `readonly`** : un champ affecté une seule fois est `final`.
- **Pas d'initialiseurs d'objet** (`new Account { Owner = "Ada" }`) et **pas d'arguments nommés ni optionnels** : des constructeurs surchargés ou un builder les remplacent.
- **Une seule classe publique de niveau supérieur par fichier**, et le fichier doit porter son nom :

```java
public class Customer {
}
```

```text
WrongFileName.java:1: error: class Customer is public, should be declared in a file named Customer.java
public class Customer {
       ^
1 error
```

C# n'a pas non plus d'équivalent à `partial` : une classe vit dans un seul et unique fichier.

## Les méthodes sont virtuelles par défaut

En C#, une méthode n'est pas virtuelle sauf si elle est marquée `virtual`, et une classe dérivée doit écrire `override`. En Java, **toute méthode d'instance peut être redéfinie** sauf si elle est `final`, `private` ou `static`, et `extends` remplace `:`.

```java
static class SavingsAccount extends Account {
    private final int ratePerMille;

    SavingsAccount(String owner, long openingCents, int ratePerMille) {
        super(owner, openingCents);
        this.ratePerMille = ratePerMille;
    }

    @Override
    String describe() {
        return super.describe() + " (savings, " + ratePerMille + " per mille)";
    }
}
```

```java
List<Account> accounts = new ArrayList<>();
accounts.add(new Account("Ada", 10_000));
accounts.add(new SavingsAccount("Grace", 25_000, 15));

for (Account account : accounts) {
    account.deposit(500);
    System.out.println(account.describe());
}
```

```text
Ada: 10500 cents
Grace: 25500 cents (savings, 15 per mille)
```

[`@Override`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Override.html) est une annotation, et elle est facultative. Sans elle, une faute de frappe déclare silencieusement une *nouvelle* méthode. Avec elle, le compilateur vérifie :

```java
class Base {
    String describe() {
        return "base";
    }
}

class Derived extends Base {
    @Override
    String descibe() {
        return "derived";
    }
}
```

```text
MissingOverride.java:8: error: method does not override or implement a method from a supertype
    @Override
    ^
1 error
```

Écrivez toujours `@Override`. Il n'existe pas d'équivalent du modificateur `new` de C# pour masquer une méthode : le côté C# de cette leçon affiche `base` pour une méthode masquée et `derived` pour une méthode redéfinie, alors qu'en Java une méthode de même signature redéfinit toujours.

## Modificateurs d'accès

| C# | Java | Visible par |
|---|---|---|
| `public` | `public` | tout le monde |
| `private` | `private` | la classe de niveau supérieur et tout ce qui y est imbriqué (C# permet à une classe imbriquée de lire les membres privés de sa classe englobante, mais pas l'inverse) |
| `protected` | `protected` | les sous-classes **et tout le package** |
| `internal` | *(aucun modificateur)*, « package-private » | le même **package**, pas le même assembly |
| `private protected` | — | |
| par défaut pour les membres : `private` | par défaut : package-private | |

Deux pièges. Le `protected` de Java est plus large que celui de C#, puisque n'importe quelle classe du même package peut l'utiliser. Et omettre le modificateur ne rend pas un membre privé : il est visible dans tout le package. Y accéder depuis un autre package échoue :

```java
package other;

import lessons.l03.Accounts;

class PackagePrivate {
    void run() {
        var account = new Accounts.Account("Ada", 100);
    }
}
```

```text
PackagePrivate.java:7: error: Account is not public in Accounts; cannot be accessed from outside package
        var account = new Accounts.Account("Ada", 100);
                                  ^
1 error
```

Un package n'est pas un assembly : rien n'empêche un autre JAR de déclarer des classes dans votre package. Une encapsulation comparable à celle des assemblies vient des [modules](https://dev.java/learn/modules/) (leçon 14).

## Records

Un [record](https://docs.oracle.com/en/java/javase/25/language/records.html) est un `record class` C# à paramètres positionnels : une classe finale avec des champs privés finaux, un constructeur, des accesseurs, `equals`, `hashCode` et `toString`.

```java
record Point(int x, int y) {
    Point {
        if (x < 0 || y < 0) {
            throw new IllegalArgumentException("negative coordinate: " + x + ", " + y);
        }
    }

    Point withX(int newX) {
        return new Point(newX, y);
    }

    double length() {
        return Math.sqrt(x * x + y * y);
    }
}
```

```java
var p = new Point(3, 4);
System.out.println(p);
System.out.println(p.x() + " " + p.length());
System.out.println(p.equals(new Point(3, 4)));
System.out.println(p.withX(6));
```

```text
Point[x=3, y=4]
3 5.0
true
Point[x=6, y=4]
```

- L'accesseur est `x()`, et non `getX()` ou `X`.
- Le **constructeur compact** `Point { … }` exécute la validation avant l'affectation des champs ; inutile de répéter les paramètres.
- **Pas encore d'expressions `with`** (la [JEP 468](https://openjdk.org/jeps/468) est candidate, elle ne fait pas partie de Java 25) : écrivez à la main des méthodes du style `withX`.

```java
record Point(int x, int y) {
}

class Moves {
    Point right(Point p) {
        return p with { x = p.x() + 1; };
    }
}
```

```text
WithExpression.java:6: error: ';' expected
        return p with { x = p.x() + 1; };
                ^
WithExpression.java:6: error: not a statement
        return p with { x = p.x() + 1; };
                 ^
WithExpression.java:6: error: ';' expected
        return p with { x = p.x() + 1; };
                     ^
3 errors
```

- Les champs sont finaux, donc un record ne peut pas se modifier lui-même (`cannot assign a value to final variable x`). Mais il n'est immuable qu'**en surface**, exactement comme un record C# qui contient une `List<T>` :

```java
var items = new java.util.ArrayList<>(List.of("book"));
var order = new Order("A-1", items);
items.add("pen");
System.out.println(order);
```

```text
Order[id=A-1, items=[book, pen]]
```

Pour comparaison, le côté C# affiche `Point { X = 3, Y = 4 }` et accepte `p with { X = 6 }`.

## `equals` et `hashCode` vont ensemble

Une classe qui redéfinit `equals` doit redéfinir `hashCode`, sinon les collections à base de hachage ne fonctionnent plus — le même contrat que `Equals`/`GetHashCode` en .NET. javac avertit en cas d'oubli, avec `-Xlint` :

```java
class Tag {
    private final String name;

    Tag(String name) {
        this.name = name;
    }

    @Override
    public boolean equals(Object other) {
        return other instanceof Tag tag && tag.name.equals(name);
    }
}
```

```text
EqualsWithoutHashCode.java:1: warning: [overrides] Class Tag overrides equals, but neither it nor any superclass overrides hashCode method
class Tag {
^
1 warning
```

```java
var tags = new HashSet<Tag>();
tags.add(new Tag("java"));
System.out.println(new Tag("java").equals(new Tag("java")));
System.out.println(tags.contains(new Tag("java")));
```

```text
true
false
```

Les records implémentent correctement ces deux méthodes gratuitement, une raison de plus de les utiliser pour les données.

## Les enums sont des classes

Un `enum` C# est un entier nommé : `(Size)42` compile et s'exécute. Un [enum](https://docs.oracle.com/javase/tutorial/java/javaOO/enum.html) Java est une classe avec un ensemble fixe d'instances, qui peut avoir des champs, des constructeurs et des méthodes — et même un corps de méthode différent pour chaque constante.

```java
enum Planet {
    MERCURY(3.303e+23, 2.4397e6),
    EARTH(5.976e+24, 6.37814e6);

    private static final double G = 6.67300E-11;
    private final double mass;
    private final double radius;

    Planet(double mass, double radius) {
        this.mass = mass;
        this.radius = radius;
    }

    double surfaceGravity() {
        return G * mass / (radius * radius);
    }
}

enum Operation {
    PLUS {
        @Override
        int apply(int a, int b) {
            return a + b;
        }
    },
    TIMES {
        @Override
        int apply(int a, int b) {
            return a * b;
        }
    };

    abstract int apply(int a, int b);
}
```

```java
for (Planet planet : Planet.values()) {
    System.out.printf("%s %.2f%n", planet, planet.surfaceGravity());
}
System.out.println(Planet.valueOf("EARTH").ordinal());
System.out.println(Operation.TIMES.apply(6, 7));

var counts = new EnumMap<Planet, Integer>(Planet.class);
counts.put(Planet.EARTH, 8);
System.out.println(counts);

try {
    Planet.valueOf("PLUTO");
} catch (IllegalArgumentException e) {
    System.out.println(e.getMessage());
}
```

```text
MERCURY 3.70
EARTH 9.80
1
42
{EARTH=8}
No enum constant lessons.l03.Enums.Planet.PLUTO
```

Impossible de fabriquer une valeur hors de l'ensemble : `new Size()` est une erreur de compilation (`enum classes may not be instantiated`), et `valueOf` lève une exception pour un nom inconnu, comme le ferait `Enum.Parse` en C#. Le côté C# de cette leçon montre `(Size)42` qui affiche `42` alors qu'`Enum.IsDefined` renvoie `False`. Au lieu de `[Flags]`, Java utilise un [`EnumSet`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/EnumSet.html), adossé à un vecteur de bits (exercice 3).

## Interfaces et hiérarchies scellées

Les interfaces fonctionnent comme les interfaces de C# 8+ : méthodes abstraites, méthodes `default` avec un corps, méthodes `static` et utilitaires `private`. Ce que Java ajoute, c'est [`sealed`](https://docs.oracle.com/en/java/javase/25/language/sealed-classes-and-interfaces.html) avec une liste `permits` — un ensemble fermé d'implémentations pour lequel C# n'a pas de mot-clé.

```java
sealed interface Shape permits Circle, Square {
    double area();

    default String describe() {
        return getClass().getSimpleName() + " with area " + String.format("%.1f", area());
    }

    static Shape unitSquare() {
        return new Square(1);
    }
}

record Circle(double radius) implements Shape {
    public double area() {
        return Math.PI * radius * radius;
    }
}

record Square(double side) implements Shape {
    public double area() {
        return side * side;
    }
}
```

```text
Circle with area 3.1
Square with area 4.0
Square with area 1.0
```

Une classe absente de la liste ne peut pas s'y joindre (le fichier déclare sa propre petite interface `Shape`) :

```java
sealed interface Shape permits Circle {
}

record Circle(double radius) implements Shape {
}

record Triangle(double base, double height) implements Shape {
}
```

```text
NotPermitted.java:7: error: class is not allowed to extend sealed class: Shape (as it is not listed in its 'permits' clause)
record Triangle(double base, double height) implements Shape {
^
1 error
```

Dans la leçon 8, `switch` s'appuie sur la liste `permits` pour prouver que tous les cas sont traités.

## Classes imbriquées : `static` compte

Une classe imbriquée déclarée `static` correspond à une classe imbriquée C#. **Sans `static`**, c'est une *classe interne* (inner class) : chaque instance porte une référence cachée vers une instance de la classe englobante et peut utiliser ses champs.

```java
private int created;

class Counter {
    void increment() {
        created++;
    }
}

public static void main(String[] args) {
    var outer = new Shapes();
    Shapes.Counter counter = outer.new Counter();
    counter.increment();
    counter.increment();
    System.out.println(outer.created);   // 2
}
```

En créer une sans instance englobante échoue, avec un message qui ne parle pas de classes internes :

```java
class Outer {
    class Inner {
    }

    static Inner create() {
        return new Inner();
    }
}
```

```text
InnerFromStatic.java:6: error: non-static variable this cannot be referenced from a static context
        return new Inner();
               ^
1 error
```

La référence cachée maintient aussi l'objet englobant en vie. Rendez les classes imbriquées `static`, sauf si elles ont vraiment besoin de l'instance englobante.

## Pas de surcharge d'opérateurs, pas de méthodes d'extension

`BigDecimal` a une méthode `add`, pas d'opérateur `+`, et vous ne pouvez pas lui en donner un :

```java
import java.math.BigDecimal;

class Invoice {
    BigDecimal total(BigDecimal net, BigDecimal tax) {
        return net + tax;
    }
}
```

```text
NoOperatorOverloading.java:5: error: bad operand types for binary operator '+'
        return net + tax;
                   ^
  first type:  BigDecimal
  second type: BigDecimal
1 error
```

Pas de méthodes d'extension non plus : les utilitaires vivent dans des classes statiques (`Collections`, `Objects`, `Strings` dans [Guava](https://github.com/google/guava)) et s'appellent sous la forme `Objects.requireNonNull(x)`.

## À retenir

- Des getters et setters au lieu des propriétés ; des records pour les données.
- Toute méthode est virtuelle sauf si elle est `final` ; écrivez toujours `@Override`.
- Aucun modificateur signifie package-private, et `protected` inclut le package.
- Les records ne sont immuables qu'en surface et n'ont pas encore d'expression `with`.
- Les enums sont des classes avec un ensemble fixe d'instances ; `EnumSet` remplace `[Flags]`.
- `sealed … permits` ferme une hiérarchie ; les classes imbriquées non `static` capturent leur instance englobante.

## Exercices

1. Traduisez ce type C# en un record Java qui rejette un nom vide et un prix négatif :

```csharp
public record Product(string Name, decimal Price)
{
    public string Name { get; } = !string.IsNullOrWhiteSpace(Name) ? Name : throw new ArgumentException("name required");
    public decimal Price { get; } = Price >= 0 ? Price : throw new ArgumentOutOfRangeException(nameof(Price));
}
```

<details>
<summary>Solution</summary>

```java
record Product(String name, BigDecimal price) {
    Product {
        if (name == null || name.isBlank()) {
            throw new IllegalArgumentException("name required");
        }
        if (price.signum() < 0) {
            throw new IllegalArgumentException("price must not be negative");
        }
    }
}
```

`BigDecimal` remplace `decimal` ; `signum()` évite la comparaison `compareTo(BigDecimal.ZERO) < 0`. `isBlank()` est `string.IsNullOrWhiteSpace` sans la vérification de `null`.

</details>

2. Corrigez `Tag` pour que `tags.contains(new Tag("java"))` renvoie `true`. Donnez ensuite l'alternative en une ligne.

<details>
<summary>Solution</summary>

```java
@Override
public int hashCode() {
    return name.hashCode();
}
```

`Objects.hash(name)` fonctionne aussi et s'étend à plusieurs champs. L'alternative en une ligne consiste à en faire un record, qui génère `equals` et `hashCode` à partir de ses composants : `record Tag(String name) {}`.

</details>

3. Traduisez cet enum de drapeaux C# et sa vérification en Java, sans utiliser d'entiers :

```csharp
[Flags] enum Permission { Read = 1, Write = 2, Delete = 4 }
var granted = Permission.Read | Permission.Write;
bool canWrite = granted.HasFlag(Permission.Write);
```

<details>
<summary>Solution</summary>

```java
enum Permission { READ, WRITE, DELETE }

EnumSet<Permission> granted = EnumSet.of(Permission.READ, Permission.WRITE);
boolean canWrite = granted.contains(Permission.WRITE);
```

`EnumSet` stocke l'ensemble sous forme de champ de bits en interne : il est donc aussi compact que `[Flags]`, et on ne peut pas y stocker une valeur étrangère à l'enum.

</details>

## Sources

- [dev.java — Classes and objects](https://dev.java/learn/classes-objects/) et [Records](https://dev.java/learn/records/)
- [JLS §6.6 — Access control](https://docs.oracle.com/javase/specs/jls/se25/html/jls-6.html#jls-6.6)
- [JLS §8.9 — Enum classes](https://docs.oracle.com/javase/specs/jls/se25/html/jls-8.html#jls-8.9)
- [JEP 409 — Sealed classes](https://openjdk.org/jeps/409) et [JEP 395 — Records](https://openjdk.org/jeps/395)
- [Contrat de `Object.hashCode`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Object.html#hashCode())
