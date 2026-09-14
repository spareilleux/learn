---
title: 6. Lambdas e interfaces funcionales
description: Interfaces funcionales en lugar de Func y Action, referencias a métodos, captura de valores efectivamente finales, composición y listas de listeners en lugar de eventos — comparados con los delegados de C#.
sidebar:
  order: 6
---

Ejemplos completos: [`lessons/l06`](https://github.com/spareilleux/learn/tree/main/code/java-for-csharp/src/main/java/lessons/l06).

## Sin tipos delegado: interfaces con un solo método

C# tiene tipos delegado: `Func<string, int>` es un tipo por derecho propio, y desde C# 10 una lambda tiene incluso un tipo natural. Java no tiene ningún tipo función. Una lambda es una implementación de una **interfaz funcional**, una interfaz con exactamente un método abstracto, y el compilador necesita saber de qué interfaz se trata a partir del contexto: el *tipo destino* (target type).

El JDK ofrece las formas habituales en [`java.util.function`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/function/package-summary.html):

| C# | Java | Método que se llama |
|---|---|---|
| `Func<T, R>` | [`Function<T, R>`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/function/Function.html) | `apply` |
| `Func<T1, T2, R>` | `BiFunction<T, U, R>` | `apply` |
| `Func<R>` | [`Supplier<T>`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/function/Supplier.html) | `get` |
| `Action<T>` | [`Consumer<T>`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/function/Consumer.html) | `accept` |
| `Action` | [`Runnable`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Runnable.html) | `run` |
| `Predicate<T>` | [`Predicate<T>`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/function/Predicate.html) | `test` |
| `Func<T, T>` | `UnaryOperator<T>` | `apply` |
| `Func<T, T, T>` | `BinaryOperator<T>` | `apply` |
| `Func<string, int>` sin boxing | `ToIntFunction<String>`, `IntBinaryOperator`, `IntPredicate`… | `applyAsInt`, `test`… |

No hay `Function3`: a partir de dos parámetros, declaras tu propia interfaz. El nombre del método también cambia con la interfaz, así que no puedes llamar a una variable lambda como a un método (`length("abc")` en C#):

```java
// Func<string, int>, Func<int, int, int>, Func<string>, Action<string>, Predicate<string>
Function<String, Integer> length = s -> s.length();
BiFunction<Integer, Integer, Integer> add = (a, b) -> a + b;
Supplier<String> greeting = () -> "hello";
Consumer<String> print = s -> System.out.println("print: " + s);
Predicate<String> isEmpty = s -> s.isEmpty();

// Cada interfaz tiene su propio nombre de método: apply, get, accept, test.
System.out.println(length.apply("lambda") + " " + add.apply(2, 3) + " " + greeting.get());
print.accept("consumer");
System.out.println(isEmpty.test(""));

// Las especializaciones primitivas evitan el boxing.
ToIntFunction<String> fastLength = String::length;
IntBinaryOperator multiply = (a, b) -> a * b;
System.out.println(fastLength.applyAsInt("abc") + " " + multiply.applyAsInt(6, 7));
```

```text
6 5 hello
print: consumer
true
3 42
```

Sin tipo destino, una lambda no tiene tipo. `var` no puede inferir uno, y `Object` no es una interfaz funcional:

```java
class Increments {
    static void run() {
        var increment = (int x) -> x + 1;
    }
}
```

```text
LambdaWithoutTarget.java:3: error: cannot infer type for local variable increment
        var increment = (int x) -> x + 1;
            ^
  (lambda expression needs an explicit target-type)
1 error
```

```java
class References {
    static void run() {
        Object length = String::length;
    }
}
```

```text
MethodRefWithoutInterface.java:3: error: incompatible types: Object is not a functional interface
        Object length = String::length;
                        ^
1 error
```

El lado C# imprime ``Func`2`` para `(string s) => s.Length`.

## Tus propias interfaces funcionales

Cualquier interfaz con un único método abstracto sirve como destino de una lambda, incluidas las antiguas como `Runnable`, `Comparator` o `Callable`. Los métodos default y estáticos no cuentan. La anotación [`@FunctionalInterface`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/FunctionalInterface.html) es opcional, como `@Override`: le pide al compilador que compruebe la regla.

```java
@FunctionalInterface
interface Handler {
    void handle(String message);

    void close();
}
```

```text
NotFunctional.java:1: error: Unexpected @FunctionalInterface annotation
@FunctionalInterface
^
  Handler is not a functional interface
    multiple non-overriding abstract methods found in interface Handler
1 error
```

Como las lambdas toman el tipo de su destino, dos sobrecargas que reciben interfaces funcionales distintas con la misma forma hacen ambigua una llamada. C# tiene el mismo problema con los delegados, pero las interfaces estándar de Java se solapan mucho: `Supplier<String>` y [`Callable<String>`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/Callable.html) no reciben nada y devuelven un `String`.

```java
import java.util.concurrent.Callable;
import java.util.function.Supplier;

class Scheduler {
    static void schedule(Supplier<String> job) {}

    static void schedule(Callable<String> job) {}

    static void run() {
        schedule(() -> "report");
    }
}
```

```text
AmbiguousOverload.java:10: error: reference to schedule is ambiguous
        schedule(() -> "report");
        ^
  both method schedule(Supplier<String>) in Scheduler and method schedule(Callable<String>) in Scheduler match
1 error
```

Un cast como `schedule((Supplier<String>) () -> "report")` elige una. La mejor solución es dar nombres distintos a las sobrecargas, como hace el JDK con `comparingInt` y `comparingLong`.

## Referencias a métodos

Una [referencia a método](https://docs.oracle.com/javase/tutorial/java/javaOO/methodreferences.html) es el equivalente de un grupo de métodos de C#. La forma `::` existe en cuatro variantes:

```java
// Las cuatro variantes de referencia a método.
Function<String, Integer> parse = Integer::parseInt;        // método estático
Set<String> jvmLanguages = Set.of("java", "kotlin", "scala");
Predicate<String> isJvmLanguage = jvmLanguages::contains;   // ligada: jvmLanguages.contains(s)
Function<String, String> upper = String::toUpperCase;       // no ligada: s.toUpperCase()
Supplier<List<String>> newList = ArrayList::new;            // constructor
System.out.println(parse.apply("42") + " " + isJvmLanguage.test("kotlin") + " " + upper.apply("java"));
System.out.println(newList.get().size());
```

```text
42 true JAVA
0
```

La variante *no ligada* (unbound) no tiene equivalente en C#: `String::toUpperCase` convierte el método de instancia en una función cuyo primer parámetro es el receptor. C# necesita una lambda, `s => s.ToUpper()`.

## Captura: valores, no variables

Un cierre (closure) de C# captura la **variable**. La lambda puede modificarla y ve los cambios posteriores. Una lambda de Java solo puede usar variables locales que sean *finales o efectivamente finales* (effectively final, nunca reasignadas), así que en la práctica captura sus **valores**.

```java
class Clicks {
    static int count() {
        int clicks = 0;
        Runnable click = () -> clicks++;
        click.run();
        return clicks;
    }
}
```

```text
CaptureMutable.java:4: error: local variables referenced from a lambda expression must be final or effectively final
        Runnable click = () -> clicks++;
                               ^
1 error
```

La regla descarta un error clásico de C#. En C#, un bucle `for` tiene una sola variable para todas las iteraciones, así que las lambdas creadas en el bucle ven todas su valor final. `foreach` tiene una variable nueva en cada iteración desde C# 5. El lado C# imprime:

```text
3 3 3
0 1 2
```

En Java, la versión con bucle `for` no compila, y el bucle `for` mejorado funciona porque la variable de cada iteración es efectivamente final:

```java
import java.util.ArrayList;
import java.util.List;
import java.util.function.Supplier;

class Loop {
    static List<Supplier<Integer>> suppliers() {
        List<Supplier<Integer>> result = new ArrayList<>();
        for (int i = 0; i < 3; i++) {
            result.add(() -> i);
        }
        return result;
    }
}
```

```text
CaptureLoopIndex.java:9: error: local variables referenced from a lambda expression must be final or effectively final
            result.add(() -> i);
                             ^
1 error
```

```java
// Cada iteración de un bucle for mejorado tiene su propia variable efectivamente final.
List<Supplier<Integer>> suppliers = new ArrayList<>();
for (int value : new int[] {0, 1, 2}) {
    suppliers.add(() -> value);
}
System.out.println(suppliers.stream().map(Supplier::get).toList());
```

```text
[0, 1, 2]
```

Cuando una lambda de verdad tiene que actualizar un estado, captura un objeto mutable en lugar de una variable local. [`AtomicInteger`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/atomic/AtomicInteger.html) es la opción habitual, y además es segura entre hilos. La regla solo se aplica a las variables locales: los campos se pueden leer y escribir libremente, porque la lambda captura `this`.

```java
// Las lambdas capturan valores, no variables: el estado mutable necesita un objeto.
AtomicInteger clicks = new AtomicInteger();
Runnable click = clicks::incrementAndGet;
click.run();
click.run();
System.out.println("clicks: " + clicks.get());
```

```text
clicks: 2
```

A menudo la necesidad desaparece del todo: contar o sumar dentro de una lambda suele ser un pipeline de stream disfrazado (ejercicio 2 y lección 7).

### `this` en una lambda

Antes de Java 8, el equivalente de una lambda era una *clase anónima*, y todavía las encontrarás en código antiguo. Las dos difieren en `this`: en una lambda es la instancia contenedora, como en C#; en una clase anónima es el propio objeto anónimo.

```java
private final String name = "outer";

void showThis() {
    Runnable lambda = () -> System.out.println("lambda this: " + this.name);
    Runnable anonymous = new Runnable() {
        private final String name = "anonymous";

        @Override
        public void run() {
            System.out.println("anonymous this: " + this.name);
        }
    };
    lambda.run();
    anonymous.run();
}
```

```text
lambda this: outer
anonymous this: anonymous
```

## La composición es cosa de la biblioteca

C# compone delegados con `+` (multicast) y no tiene un `Compose` integrado. Las interfaces funcionales de Java no admiten operadores, y `+` entre dos `Runnable` es un error:

```java
class Combine {
    static void run() {
        Runnable hello = () -> System.out.print("hello ");
        Runnable world = () -> System.out.println("world");
        Runnable both = hello + world;
    }
}
```

```text
CombineRunnables.java:5: error: bad operand types for binary operator '+'
        Runnable both = hello + world;
                              ^
  first type:  Runnable
  second type: Runnable
1 error
```

A cambio, las interfaces estándar llevan métodos default para componer funciones: `Function.andThen` y `compose`, `Predicate.and`, `or`, `negate` y `Predicate.not`, y todo un builder en [`Comparator`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Comparator.html):

```java
// La composición es cosa de la biblioteca: métodos default en las interfaces.
UnaryOperator<String> trim = String::strip;
Function<String, Integer> trimmedLength = trim.andThen(String::length);
System.out.println(trimmedLength.apply("  padded  "));
Predicate<String> notBlank = Predicate.not(String::isBlank);
System.out.println(notBlank.and(isJvmLanguage.negate()).test("csharp"));

var people = new ArrayList<>(List.of(new Person("Ada", 36), new Person("Alan", 41), new Person("Grace", 36)));
people.sort(Comparator.comparingInt(Person::age).reversed().thenComparing(Person::name));
System.out.println(people);
```

```text
6
true
[Person[name=Alan, age=41], Person[name=Ada, age=36], Person[name=Grace, age=36]]
```

La cadena de `Comparator` es el `OrderByDescending(p => p.Age).ThenBy(p => p.Name)` de LINQ, aplicado a una lista in situ.

## Sin eventos: listas de listeners

Java no tiene palabra clave `event` ni delegados multicast. Las bibliotecas mantienen una lista de listeners (oyentes), normalmente `Consumer`, y exponen métodos para añadirlos y quitarlos:

```java
static class PriceFeed {
    private final List<Consumer<Double>> listeners = new ArrayList<>();

    void addListener(Consumer<Double> listener) {
        listeners.add(listener);
    }

    boolean removeListener(Consumer<Double> listener) {
        return listeners.remove(listener);
    }

    void publish(double price) {
        listeners.forEach(listener -> listener.accept(price));
    }
}
```

La trampa está en la eliminación. En C#, `feed.PriceChanged -= display.OnPrice` funciona porque dos delegados con el mismo destino y el mismo método son iguales. En Java, cada evaluación de `display::onPrice` crea un objeto nuevo, y las lambdas no redefinen `equals`:

```java
feed.addListener(display::onPrice);
feed.publish(10.5);

// Cada evaluación de display::onPrice crea un objeto nuevo, y las lambdas no redefinen equals.
System.out.println("removed: " + feed.removeListener(display::onPrice));
Consumer<Double> first = display::onPrice;
Consumer<Double> second = display::onPrice;
System.out.println("equal: " + first.equals(second));
feed.publish(11.0);

// Guarda la referencia que registraste si quieres quitarla.
Consumer<Double> listener = display::onPrice;
var other = new PriceFeed();
other.addListener(listener);
System.out.println("removed: " + other.removeListener(listener));
other.publish(12.0);
```

```text
display: 10.5
removed: false
equal: false
display: 11.0
removed: true
```

El lado C# imprime `equal: True`, y el evento se queda sin listener después del `-=`. En Java, guarda la referencia, o devuelve un objeto de suscripción desde el método que añade (ejercicio 3). La [Java Language Specification](https://docs.oracle.com/javase/specs/jls/se25/html/jls-15.html#jls-15.27.4) deja deliberadamente sin especificar la identidad de los objetos lambda, así que tampoco te fíes de `==`.

## Puntos clave

- Una lambda implementa una interfaz funcional elegida por el tipo destino; no hay tipos función, y cada interfaz tiene su propio nombre de método.
- `java.util.function` cubre las formas habituales, con especializaciones primitivas para evitar el boxing.
- Las referencias a métodos existen en cuatro variantes; la no ligada (`String::length`) no tiene equivalente en C#.
- Las lambdas solo pueden usar variables locales efectivamente finales: capturan valores, lo que elimina el error de captura en el bucle `for` de C#.
- La composición pasa por métodos default (`andThen`, `negate`, `Comparator.comparing`), no por operadores.
- Los listeners sustituyen a los eventos; una referencia a método evaluada dos veces da dos objetos distintos.

## Ejercicios

1. Escribe `pipeline(List<UnaryOperator<String>> steps)`, que devuelva un `UnaryOperator<String>` que aplique los pasos en orden, y la identidad para una lista vacía. ¿Por qué no compila `reduce(UnaryOperator.identity(), (f, g) -> f.andThen(g))`?

<details>
<summary>Solución</summary>

```java
static UnaryOperator<String> pipeline(List<UnaryOperator<String>> steps) {
    return steps.stream().reduce(UnaryOperator.identity(), (f, g) -> s -> g.apply(f.apply(s)));
}

UnaryOperator<String> clean = pipeline(List.of(String::strip, String::toLowerCase, s -> s.replace(' ', '-')));
clean.apply("  Hello Java World ");   // "hello-java-world"
```

`andThen` se hereda de `Function` y devuelve una `Function<String, V>`, no un `UnaryOperator<String>`. `reduce` necesita que su acumulador devuelva el tipo del elemento, y javac informa de «bad return type in lambda expression». Escribir la composición como una lambda hace que su tipo destino sea `UnaryOperator<String>`.

</details>

2. Traduce este código C# sin un `AtomicInteger`:

```csharp
int longWords = 0;
words.ForEach(w => { if (w.Length > 3) longWords++; });
```

<details>
<summary>Solución</summary>

```java
long longWords = words.stream().filter(w -> w.length() > 3).count();
```

La versión C# solo necesita una variable capturada mutable porque cuenta a mano. Un stream expresa el recuento directamente, y no hay nada que capturar. `count()` devuelve un `long`. Para `List.of("a", "lambda", "is", "not", "a", "delegate")` el resultado es `2`.

</details>

3. Modifica `PriceFeed` para que `subscribe(Consumer<Double>)` devuelva un objeto cuyo `close()` quite el listener, y úsalo en un try-with-resources. ¿Por qué declarar una interfaz nueva en lugar de devolver `AutoCloseable`?

<details>
<summary>Solución</summary>

```java
interface Subscription extends AutoCloseable {
    @Override
    void close(); // sin excepción comprobada, a diferencia de AutoCloseable.close()
}

static class PriceFeed {
    private final List<Consumer<Double>> listeners = new ArrayList<>();

    Subscription subscribe(Consumer<Double> listener) {
        listeners.add(listener);
        return () -> listeners.remove(listener);
    }

    void publish(double price) {
        List.copyOf(listeners).forEach(listener -> listener.accept(price));
    }
}

try (Subscription subscription = feed.subscribe(received::add)) {
    feed.publish(1.0);
}
feed.publish(2.0);   // received vale [1.0]
```

La lambda captura exactamente el objeto que se añadió, así que `remove` lo encuentra. `AutoCloseable.close()` declara `throws Exception`, lo que obligaría a quien llama a capturar `Exception` (lección 5); redefinir `close()` sin la cláusula `throws` lo evita. `Subscription` es a su vez una interfaz funcional, por eso funciona la lambda. `publish` recorre una copia para que un listener pueda cancelar su suscripción mientras se le notifica. Es el patrón `IDisposable` del `Subscribe` de Rx.

</details>

## Fuentes

- [The Java Tutorials — Lambda expressions](https://docs.oracle.com/javase/tutorial/java/javaOO/lambdaexpressions.html) y [Method references](https://docs.oracle.com/javase/tutorial/java/javaOO/methodreferences.html)
- [JLS §9.8 — Functional interfaces](https://docs.oracle.com/javase/specs/jls/se25/html/jls-9.html#jls-9.8) y [§15.27 — Lambda expressions](https://docs.oracle.com/javase/specs/jls/se25/html/jls-15.html#jls-15.27)
- [Paquete `java.util.function`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/function/package-summary.html)
- [C# — Expresiones lambda](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/lambda-expressions) y [Delegados](https://learn.microsoft.com/dotnet/csharp/programming-guide/delegates/)
