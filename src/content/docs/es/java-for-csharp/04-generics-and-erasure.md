---
title: 4. Genéricos y borrado de tipos
description: Por qué List<int>, new T() y typeof(T) no existen en Java, cómo los wildcards sustituyen a la varianza in/out y dónde fallan en tiempo de ejecución los genéricos borrados — comparados con los genéricos reificados de C#.
sidebar:
  order: 4
---

Ejemplos completos: [`lessons/l04`](https://github.com/spareilleux/learn/tree/main/code/java-for-csharp/src/main/java/lessons/l04).

## Misma sintaxis, distinta maquinaria

`List<String>`, los métodos genéricos y las restricciones se leen casi como en C#. La diferencia está por debajo. El CLR **reifica** los genéricos: `List<int>` y `List<string>` son tipos distintos en tiempo de ejecución, y el JIT genera código especializado para los tipos de valor. Los genéricos de Java los comprueba el compilador y después se **borran**, lo que se conoce como borrado de tipos (type erasure): el bytecode solo conoce `List`, y cada `T` se convierte en su cota (normalmente `Object`). Esto mantuvo Java 5 compatible con los archivos `.class` antiguos, y explica casi todo lo que hay en esta lección.

```java
List<String> strings = new ArrayList<>();
List<Integer> numbers = new ArrayList<>();
System.out.println(strings.getClass() == numbers.getClass());
System.out.println(strings.getClass().getName());
```

```text
true
java.util.ArrayList
```

El lado C# muestra `False` para `typeof(List<string>) == typeof(List<int>)`, y ``System.Collections.Generic.List`1[System.Int32]`` para el tipo en tiempo de ejecución.

## Lo que prohíbe el borrado

| C# | Java | Por qué |
|---|---|---|
| `List<int>` | `List<Integer>` | un argumento de tipo debe ser un tipo de referencia |
| `new T()` con `where T : new()` | pasar un `Supplier<T>` | no hay ningún `T` que instanciar en tiempo de ejecución |
| `typeof(T)` | pasar un `Class<T>` | ídem |
| `new T[n]` | `(T[]) new Object[n]` o `IntFunction<T[]>` | los arrays conocen su tipo de elemento en tiempo de ejecución; `T` no existe |
| `o is List<string>` | `o instanceof List<?>` | el argumento de tipo no se puede comprobar |
| sobrecargas `F(List<string>)` y `F(List<int>)` | nombres de método distintos | las dos se borran a `F(List)` |
| campo `static T` en `Cache<T>` | no permitido | hay una sola clase, compartida por todos los `Cache<…>` |

Cada uno de estos casos es un error de compilación, con mensajes que conviene saber reconocer.

```java
import java.util.List;

class Scores {
    List<int> values;
}
```

```text
PrimitiveTypeArgument.java:4: error: unexpected type
    List<int> values;
         ^
  required: reference
  found:    int
1 error
```

```java
class Factory<T> {
    T create() {
        return new T();
    }
}
```

```text
NewT.java:3: error: unexpected type
        return new T();
                   ^
  required: class
  found:    type parameter T
  where T is a type-variable:
    T extends Object declared in class Factory
1 error
```

```java
class Registry<T> {
    String typeName() {
        return T.class.getName();
    }
}
```

```text
ClassLiteralOfT.java:3: error: cannot select from a type variable
        return T.class.getName();
                ^
1 error
```

```java
class Stack<T> {
    private T[] items = new T[16];
}
```

```text
GenericArray.java:2: error: generic array creation
    private T[] items = new T[16];
                        ^
1 error
```

```java
import java.util.List;

class Checks {
    boolean isNames(Object value) {
        return value instanceof List<String>;
    }
}
```

```text
InstanceofGeneric.java:5: error: Object cannot be safely cast to List<String>
        return value instanceof List<String>;
               ^
1 error
```

```java
import java.util.List;

class Printer {
    void print(List<String> names) {
    }

    void print(List<Integer> numbers) {
    }
}
```

```text
SameErasure.java:7: error: name clash: print(List<Integer>) and print(List<String>) have the same erasure
    void print(List<Integer> numbers) {
         ^
1 error
```

```java
class Singleton<T> {
    static T instance;
}
```

```text
StaticT.java:2: error: non-static type variable T cannot be referenced from a static context
    static T instance;
           ^
1 error
```

## Las soluciones: pasar lo que el borrado quitó

Cuando el código necesita crear un `T` o comprobarlo, quien llama pasa explícitamente la información que falta — una fábrica o un **token de clase** (class token):

```java
// Sin `new T()`: pasa una fábrica en su lugar.
static <T> List<T> filled(int count, Supplier<T> factory) {
    var list = new ArrayList<T>();
    for (int i = 0; i < count; i++) {
        list.add(factory.get());
    }
    return list;
}

// Sin `typeof(T)`: pasa un token Class<T> cuando el tipo se necesita en tiempo de ejecución.
static <T> T firstOfType(List<?> items, Class<T> type) {
    for (Object item : items) {
        if (type.isInstance(item)) {
            return type.cast(item);
        }
    }
    return null;
}
```

```java
System.out.println(filled(3, StringBuilder::new).size());
List<Object> mixed = List.of(1, "two", 3.0);
System.out.println(firstOfType(mixed, String.class));
```

```text
3
two
```

Encontrarás tokens de clase por todas partes en las bibliotecas Java: `objectMapper.readValue(json, Order.class)` en Jackson, `context.getBean(OrderService.class)` en Spring. Existen porque la biblioteca no puede preguntarle a `T` qué es.

## El boxing es el precio de `List<Integer>`

Cada elemento de una `List<Integer>` es un objeto `Integer` independiente, mientras que una `List<int>` de C# guarda los valores en línea. El boxing también crea una trampa de sobrecarga: `List<Integer>` tiene a la vez `remove(int index)` y `remove(Object value)`.

```java
List<Integer> numbers = new ArrayList<>();
for (int i = 0; i < 5; i++) {
    numbers.add(i * 10);
}

numbers.remove(1);
System.out.println(numbers);
numbers.remove(Integer.valueOf(30));
System.out.println(numbers);
```

```text
[0, 20, 30, 40]
[0, 20, 40]
```

`remove(1)` eliminó el elemento *en el índice 1* (el valor 10), no el valor 1. Para cálculo numérico, los streams primitivos `IntStream`, `LongStream` y `DoubleStream` evitan el boxing: `IntStream.rangeClosed(1, 100).sum()` vale `5050` sin reservar ni un solo `Integer`.

## Tipos crudos y contaminación del heap

Un tipo genérico usado sin argumentos de tipo es un **tipo crudo** (raw type), que se mantiene por el código anterior a Java 5. El compilador avisa, y tiene buenos motivos:

```java
import java.util.ArrayList;
import java.util.List;

class Legacy {
    void run() {
        List names = new ArrayList();
        names.add("Ada");
    }
}
```

```text
RawType.java:6: warning: [rawtypes] found raw type: List
        List names = new ArrayList();
        ^
  missing type arguments for generic class List<E>
  where E is a type-variable:
    E extends Object declared in interface List
RawType.java:6: warning: [rawtypes] found raw type: ArrayList
        List names = new ArrayList();
                         ^
  missing type arguments for generic class ArrayList<E>
  where E is a type-variable:
    E extends Object declared in class ArrayList
RawType.java:7: warning: [unchecked] unchecked call to add(E) as a member of the raw type List
        names.add("Ada");
                 ^
  where E is a type-variable:
    E extends Object declared in interface List
3 warnings
```

A través de una referencia cruda, cualquier cosa puede entrar en una `List<String>`. Nada falla en el punto donde se añade el valor incorrecto; la `ClassCastException` aparece más tarde, allí donde se vuelve a leer un `String`:

```java
@SuppressWarnings({"rawtypes", "unchecked"}) // inseguro a propósito: la lección explica la contaminación del heap
static void pollute(List<String> names) {
    List raw = names;
    raw.add(42);
}
```

```java
var names = new ArrayList<>(List.of("Ada"));
pollute(names);
System.out.println(names.size());
String second = names.get(1);   // el ejemplo captura la excepción e imprime su mensaje
```

```text
2
ClassCastException: class java.lang.Integer cannot be cast to class java.lang.String (java.lang.Integer and java.lang.String are in module java.base of loader 'bootstrap')
```

El compilador insertó el cast en `names.get(1)`, donde el borrado había convertido `String` de nuevo en `Object`. En C#, `List<string>` habría rechazado el propio `Add`. Trata las advertencias `rawtypes` y `unchecked` como errores en el código nuevo.

## Varianza: wildcards en el punto de uso en lugar de `in` y `out`

En C#, la varianza se declara **una vez, en la interfaz**: `IEnumerable<out T>` es covariante, así que un `IEnumerable<string>` *es* un `IEnumerable<object>`. Java no tiene varianza en el punto de declaración. Una `List<String>` nunca es una `List<Object>`:

```java
import java.util.ArrayList;
import java.util.List;

class Zoo {
    void run() {
        List<String> names = new ArrayList<>();
        List<Object> objects = names;
    }
}
```

```text
InvariantList.java:7: error: incompatible types: List<String> cannot be converted to List<Object>
        List<Object> objects = names;
                               ^
1 error
```

En su lugar, cada **método** indica cómo usa su parámetro, con un [wildcard](https://docs.oracle.com/javase/tutorial/java/generics/wildcards.html):

```java
// Lee números: se acepta cualquier List de un subtipo de Number («producer extends»).
static double sum(List<? extends Number> numbers) {
    double total = 0;
    for (Number n : numbers) {
        total += n.doubleValue();
    }
    return total;
}

// Escribe enteros: se acepta cualquier List que pueda contener un Integer («consumer super»).
static void addOneTwoThree(List<? super Integer> target) {
    target.add(1);
    target.add(2);
    target.add(3);
}
```

```java
List<Integer> ints = List.of(1, 2, 3);
List<Double> doubles = List.of(1.5, 2.5);
System.out.println(sum(ints) + " " + sum(doubles));

List<Number> numbers = new ArrayList<>();
List<Object> objects = new ArrayList<>();
addOneTwoThree(numbers);
addOneTwoThree(objects);
System.out.println(numbers + " " + objects);
```

```text
6.0 4.0
[1, 2, 3] [1, 2, 3]
```

| C# | Java | Puede leer `T` | Puede añadir `T` |
|---|---|---|---|
| parámetro `IEnumerable<out T>` | `List<? extends T>` | sí | no |
| `IComparer<in T>`, `Action<in T>` | `List<? super T>` | solo como `Object` | sí |
| `IList<T>` (invariante) | `List<T>` | sí | sí |

La regla práctica es **PECS**: *producer `extends`, consumer `super`* (el productor extiende, el consumidor es un supertipo). El compilador hace cumplir las casillas «no»; su mensaje menciona una *captura* (`CAP#1`), el tipo desconocido que representa el wildcard:

```java
import java.util.List;

class Totals {
    void addZero(List<? extends Number> numbers) {
        numbers.add(0);
    }
}
```

```text
AddToExtends.java:5: error: incompatible types: int cannot be converted to CAP#1
        numbers.add(0);
                    ^
  where CAP#1 is a fresh type-variable:
    CAP#1 extends Number from capture of ? extends Number
Note: Some messages have been simplified; recompile with -Xdiags:verbose to get full output
1 error
```

La `List<? extends Number>` podría ser en realidad una `List<Double>`, así que añadirle un `Integer` podría corromperla.

Las cotas de los parámetros de tipo también usan `extends`, tanto para clases como para interfaces, y `&` para combinarlas:

```java
// Un parámetro de tipo acotado, como `where T : IComparable<T>`.
static <T extends Comparable<? super T>> T max(List<T> items) {
    T best = items.getFirst();
    for (T item : items) {
        if (item.compareTo(best) > 0) {
            best = item;
        }
    }
    return best;
}
```

`max(List.of("pear", "apple", "quince"))` devuelve `quince`. El `? super T` le permite aceptar un tipo cuyo `compareTo` se hereda de un supertipo.

## Los arrays son covariantes en los dos lenguajes

Los dos lenguajes heredaron arrays covariantes, y los dos comprueban cada escritura en tiempo de ejecución:

```java
Object[] slots = new String[2];
slots[0] = 42;
```

```text
ArrayStoreException: java.lang.Integer
```

El lado C# lanza `ArrayTypeMismatchException: Attempted to access an element as a type incompatible with the array.` Una razón más para preferir `List<T>` en ambos.

## Puntos clave

- Java comprueba los genéricos en tiempo de compilación y luego los borra: `List<String>` y `List<Integer>` son la misma clase en tiempo de ejecución.
- No hay primitivos como argumentos de tipo, ni `new T()`, ni `T.class`, ni arrays genéricos, ni sobrecargas que solo difieran en el argumento de tipo.
- Pasa un `Supplier<T>` o un `Class<T>` cuando el código necesite el tipo en tiempo de ejecución.
- Los tipos crudos anulan el sistema de tipos; el fallo aparece más tarde como una `ClassCastException`.
- La varianza se elige en cada método con `? extends` (lectura) y `? super` (escritura) — PECS.

## Ejercicios

1. Traduce este método C#. ¿Qué tiene que proporcionar ahora quien lo llama?

```csharp
static T[] Fill<T>(int count) where T : new()
{
    var result = new T[count];
    for (int i = 0; i < count; i++) result[i] = new T();
    return result;
}
```

<details>
<summary>Solución</summary>

```java
static <T> T[] fill(int count, IntFunction<T[]> newArray, Supplier<T> factory) {
    T[] result = newArray.apply(count);
    for (int i = 0; i < count; i++) {
        result[i] = factory.get();
    }
    return result;
}

StringBuilder[] builders = fill(3, StringBuilder[]::new, StringBuilder::new);
```

Quien llama proporciona lo que el borrado quitó dos veces: cómo crear el array (`StringBuilder[]::new`) y cómo crear un elemento (`StringBuilder::new`). Es el mismo patrón que [`Collection.toArray(IntFunction)`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Collection.html#toArray(java.util.function.IntFunction)).

</details>

2. Escribe la firma de un método `copy` que copie cada elemento de una lista de origen en una lista de destino, de modo que copiar una `List<Integer>` en una `List<Number>` compile.

<details>
<summary>Solución</summary>

```java
static <T> void copy(List<? super T> destination, List<? extends T> source) {
    for (T item : source) {
        destination.add(item);
    }
}
```

El origen *produce* valores `T` (`extends`), el destino los *consume* (`super`). Para `copy(numbers, integers)`, tanto `T = Integer` como `T = Number` cumplen las cotas, así que la llamada compila. Es la firma de [`Collections.copy`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Collections.html#copy(java.util.List,java.util.List)).

</details>

3. Un código C# filtra una lista heterogénea con `items.OfType<T>()`. Escribe `ofType` en Java. ¿Puede seleccionar solo los elementos `List<String>` de una `List<Object>`?

<details>
<summary>Solución</summary>

```java
static <T> List<T> ofType(List<?> items, Class<T> type) {
    return items.stream().filter(type::isInstance).map(type::cast).toList();
}
```

No: el token de clase de una lista es `List.class`, que coincide con cualquier `List` sean cuales sean sus elementos, y `List<String>.class` no existe. En tiempo de ejecución, una `List<String>` y una `List<Integer>` son indistinguibles; tendrías que inspeccionar los elementos.

</details>

## Fuentes

- [dev.java — Generics](https://dev.java/learn/generics/) y [Type erasure](https://docs.oracle.com/javase/tutorial/java/generics/erasure.html)
- [JLS §4.6 — Type erasure](https://docs.oracle.com/javase/specs/jls/se25/html/jls-4.html#jls-4.6) y [§4.8 — Raw types](https://docs.oracle.com/javase/specs/jls/se25/html/jls-4.html#jls-4.8)
- [The Java Tutorials — Wildcards](https://docs.oracle.com/javase/tutorial/java/generics/wildcards.html) y [Restrictions on generics](https://docs.oracle.com/javase/tutorial/java/generics/restrictions.html)
- [C# — Covarianza y contravarianza en genéricos](https://learn.microsoft.com/dotnet/standard/generics/covariance-and-contravariance)
- [Project Valhalla](https://openjdk.org/projects/valhalla/) — el trabajo de largo recorrido sobre clases de valor y genéricos especializados
