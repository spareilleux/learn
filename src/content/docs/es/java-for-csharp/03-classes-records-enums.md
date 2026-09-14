---
title: 3. Clases, records y enums
description: Getters en lugar de propiedades, virtual por defecto, acceso package-private, records, enums que son clases e interfaces selladas — comparados con C#.
sidebar:
  order: 3
---

Ejemplos completos: [`lessons/l03`](https://github.com/spareilleux/learn/tree/main/code/java-for-csharp/src/main/java/lessons/l03).

## Clases: lo que falta, lo que cambia

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

Viniendo de C#, llaman la atención cuatro cosas:

- **No hay propiedades.** Un campo es privado y se expone mediante métodos `getX()`/`setX()`, la convención [JavaBeans](https://docs.oracle.com/javase/tutorial/javabeans/writing/properties.html) en la que se apoyan frameworks como Spring y Jackson. Los records (más abajo) eliminan la mayor parte de este código repetitivo.
- **No hay `readonly`**: un campo asignado una sola vez es `final`.
- **No hay inicializadores de objeto** (`new Account { Owner = "Ada" }`) **ni argumentos con nombre u opcionales**: los sustituyen constructores sobrecargados o un builder.
- **Una sola clase pública de nivel superior por archivo**, y el archivo debe llevar su nombre:

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

Tampoco hay equivalente al `partial` de C#: una clase vive en un único archivo.

## Los métodos son virtuales por defecto

En C#, un método no es virtual a menos que se marque como `virtual`, y una clase derivada debe escribir `override`. En Java, **cualquier método de instancia se puede redefinir** salvo que sea `final`, `private` o `static`, y `extends` sustituye a `:`.

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

[`@Override`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Override.html) es una anotación, y es opcional. Sin ella, un error tipográfico declara en silencio un método *nuevo*. Con ella, el compilador lo comprueba:

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

Escribe siempre `@Override`. No existe equivalente del modificador `new` de C# para ocultar un método: el lado C# de esta lección muestra `base` para un método oculto y `derived` para uno redefinido, mientras que en Java un método con la misma firma siempre redefine.

## Modificadores de acceso

| C# | Java | Visible para |
|---|---|---|
| `public` | `public` | todo el mundo |
| `private` | `private` | la clase de nivel superior y todo lo que está anidado en ella (C# permite que una clase anidada lea los miembros privados de su clase contenedora, pero no al revés) |
| `protected` | `protected` | las subclases **y todo el paquete** |
| `internal` | *(sin modificador)*, «package-private» | el mismo **paquete**, no el mismo ensamblado |
| `private protected` | — | |
| por defecto para los miembros: `private` | por defecto: package-private | |

Dos trampas. El `protected` de Java es más amplio que el de C#, ya que cualquier clase del mismo paquete puede usarlo. Y omitir el modificador no hace privado a un miembro: es visible en todo el paquete. Acceder a él desde otro paquete falla:

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

Un paquete no es un ensamblado: nada impide que otro JAR declare clases en tu paquete. Una encapsulación parecida a la de los ensamblados viene de los [módulos](https://dev.java/learn/modules/) (lección 14).

## Records

Un [record](https://docs.oracle.com/en/java/javase/25/language/records.html) es un `record class` de C# con parámetros posicionales: una clase final con campos privados finales, un constructor, accesores, `equals`, `hashCode` y `toString`.

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

- El accesor es `x()`, no `getX()` ni `X`.
- El **constructor compacto** `Point { … }` ejecuta la validación antes de que se asignen los campos; no hace falta repetir los parámetros.
- **Todavía no hay expresiones `with`** ([JEP 468](https://openjdk.org/jeps/468) es candidata, no forma parte de Java 25): escribe a mano métodos al estilo de `withX`.

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

- Los campos son finales, así que un record no puede modificarse a sí mismo (`cannot assign a value to final variable x`). Pero solo es inmutable **en superficie**, exactamente como un record de C# que contiene una `List<T>`:

```java
var items = new java.util.ArrayList<>(List.of("book"));
var order = new Order("A-1", items);
items.add("pen");
System.out.println(order);
```

```text
Order[id=A-1, items=[book, pen]]
```

A modo de comparación, el lado C# muestra `Point { X = 3, Y = 4 }` y admite `p with { X = 6 }`.

## `equals` y `hashCode` van juntos

Una clase que redefine `equals` debe redefinir `hashCode`, o las colecciones basadas en hash dejan de funcionar — el mismo contrato que `Equals`/`GetHashCode` en .NET. javac avisa cuando se te olvida, con `-Xlint`:

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

Los records implementan bien los dos métodos sin coste alguno, una razón más para usarlos con datos.

## Los enums son clases

Un `enum` de C# es un entero con nombre: `(Size)42` compila y se ejecuta. Un [enum](https://docs.oracle.com/javase/tutorial/java/javaOO/enum.html) de Java es una clase con un conjunto fijo de instancias, que puede tener campos, constructores y métodos — incluso un cuerpo de método distinto para cada constante.

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

No hay forma de crear un valor fuera del conjunto: `new Size()` es un error de compilación (`enum classes may not be instantiated`), y `valueOf` lanza una excepción con un nombre desconocido, igual que haría `Enum.Parse` en C#. El lado C# de esta lección muestra `(Size)42` imprimiendo `42` mientras `Enum.IsDefined` devuelve `False`. En lugar de `[Flags]`, Java usa un [`EnumSet`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/EnumSet.html), respaldado por un vector de bits (ejercicio 3).

## Interfaces y jerarquías selladas

Las interfaces funcionan como las de C# 8+: métodos abstractos, métodos `default` con cuerpo, métodos `static` y auxiliares `private`. Lo que añade Java es [`sealed`](https://docs.oracle.com/en/java/javase/25/language/sealed-classes-and-interfaces.html) con una lista `permits` — un conjunto cerrado de implementaciones para el que C# no tiene palabra clave.

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

Una clase que no está en la lista no puede unirse (el archivo declara su propia `Shape` reducida):

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

En la lección 8, `switch` usa la lista `permits` para demostrar que se tratan todos los casos.

## Clases anidadas: `static` importa

Una clase anidada declarada `static` es una clase anidada de C#. **Sin `static`**, es una *clase interna* (inner class): cada instancia lleva una referencia oculta a una instancia de la clase contenedora y puede usar sus campos.

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

Crear una sin instancia contenedora falla, con un mensaje que no menciona las clases internas:

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

La referencia oculta también mantiene vivo el objeto contenedor. Haz que las clases anidadas sean `static` salvo que de verdad necesiten la instancia contenedora.

## Sin sobrecarga de operadores, sin métodos de extensión

`BigDecimal` tiene un método `add`, no un operador `+`, y no puedes dárselo:

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

Tampoco hay métodos de extensión: los auxiliares viven en clases de utilidades estáticas (`Collections`, `Objects`, `Strings` en [Guava](https://github.com/google/guava)) y se llaman como `Objects.requireNonNull(x)`.

## Puntos clave

- Getters y setters en lugar de propiedades; records para los datos.
- Todo método es virtual salvo que sea `final`; escribe siempre `@Override`.
- Sin modificador significa package-private, y `protected` incluye el paquete.
- Los records solo son inmutables en superficie y todavía no tienen expresión `with`.
- Los enums son clases con un conjunto fijo de instancias; `EnumSet` sustituye a `[Flags]`.
- `sealed … permits` cierra una jerarquía; las clases anidadas no `static` capturan su instancia contenedora.

## Ejercicios

1. Traduce este tipo C# a un record Java que rechace un nombre vacío y un precio negativo:

```csharp
public record Product(string Name, decimal Price)
{
    public string Name { get; } = !string.IsNullOrWhiteSpace(Name) ? Name : throw new ArgumentException("name required");
    public decimal Price { get; } = Price >= 0 ? Price : throw new ArgumentOutOfRangeException(nameof(Price));
}
```

<details>
<summary>Solución</summary>

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

`BigDecimal` hace las veces de `decimal`; `signum()` evita comparar con `compareTo(BigDecimal.ZERO) < 0`. `isBlank()` es `string.IsNullOrWhiteSpace` sin la comprobación de null.

</details>

2. Corrige `Tag` para que `tags.contains(new Tag("java"))` devuelva `true`. Después da la alternativa de una sola línea.

<details>
<summary>Solución</summary>

```java
@Override
public int hashCode() {
    return name.hashCode();
}
```

`Objects.hash(name)` también funciona y se adapta a varios campos. La alternativa de una línea es convertirlo en un record, que genera `equals` y `hashCode` a partir de sus componentes: `record Tag(String name) {}`.

</details>

3. Traduce este enum de flags de C# y su comprobación a Java sin usar enteros:

```csharp
[Flags] enum Permission { Read = 1, Write = 2, Delete = 4 }
var granted = Permission.Read | Permission.Write;
bool canWrite = granted.HasFlag(Permission.Write);
```

<details>
<summary>Solución</summary>

```java
enum Permission { READ, WRITE, DELETE }

EnumSet<Permission> granted = EnumSet.of(Permission.READ, Permission.WRITE);
boolean canWrite = granted.contains(Permission.WRITE);
```

`EnumSet` guarda internamente el conjunto como un campo de bits, así que es tan compacto como `[Flags]`, y no se puede guardar en él un valor ajeno al enum.

</details>

## Fuentes

- [dev.java — Classes and objects](https://dev.java/learn/classes-objects/) y [Records](https://dev.java/learn/records/)
- [JLS §6.6 — Access control](https://docs.oracle.com/javase/specs/jls/se25/html/jls-6.html#jls-6.6)
- [JLS §8.9 — Enum classes](https://docs.oracle.com/javase/specs/jls/se25/html/jls-8.html#jls-8.9)
- [JEP 409 — Sealed classes](https://openjdk.org/jeps/409) y [JEP 395 — Records](https://openjdk.org/jeps/395)
- [Contrato de `Object.hashCode`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Object.html#hashCode())
