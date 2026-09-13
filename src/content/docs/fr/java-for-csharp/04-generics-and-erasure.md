---
title: 4. Génériques et effacement de type
description: Pourquoi List<int>, new T() et typeof(T) n'existent pas en Java, comment les wildcards remplacent la variance in/out, et où les génériques effacés échouent à l'exécution — comparés aux génériques réifiés de C#.
sidebar:
  order: 4
---

Exemples complets : [`lessons/l04`](https://github.com/spareilleux/learn/tree/main/code/java-for-csharp/src/main/java/lessons/l04).

## Même syntaxe, mécanique différente

`List<String>`, les méthodes génériques et les contraintes se lisent presque comme en C#. La différence est en dessous. Le CLR **réifie** les génériques : `List<int>` et `List<string>` sont des types distincts à l'exécution, et le JIT génère du code spécialisé pour les types valeur. Les génériques Java sont vérifiés par le compilateur puis **effacés** : le bytecode ne connaît que `List`, et chaque `T` devient sa borne (en général `Object`). Ce choix a permis à Java 5 de rester compatible avec les fichiers `.class` plus anciens, et il explique presque tout dans cette leçon.

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

Le côté C# affiche `False` pour `typeof(List<string>) == typeof(List<int>)`, et ``System.Collections.Generic.List`1[System.Int32]`` pour le type à l'exécution.

## Ce que l'effacement interdit

| C# | Java | Pourquoi |
|---|---|---|
| `List<int>` | `List<Integer>` | un argument de type doit être un type référence |
| `new T()` avec `where T : new()` | passer un `Supplier<T>` | il n'y a pas de `T` à instancier à l'exécution |
| `typeof(T)` | passer un `Class<T>` | idem |
| `new T[n]` | `(T[]) new Object[n]` ou `IntFunction<T[]>` | les tableaux connaissent leur type d'élément à l'exécution ; `T` n'existe pas |
| `o is List<string>` | `o instanceof List<?>` | l'argument de type ne peut pas être vérifié |
| surcharges `F(List<string>)` et `F(List<int>)` | des noms de méthode différents | les deux s'effacent en `F(List)` |
| champ `static T` dans `Cache<T>` | interdit | il n'y a qu'une classe, partagée par tous les `Cache<…>` |

Chacun de ces cas est une erreur de compilation, avec des messages qu'il vaut la peine de savoir reconnaître.

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

## Les contournements : passer ce que l'effacement a retiré

Quand du code doit créer un `T` ou le tester, l'appelant fournit explicitement l'information manquante — une fabrique ou un **jeton de classe** (class token) :

```java
// Pas de `new T()` : passer une fabrique à la place.
static <T> List<T> filled(int count, Supplier<T> factory) {
    var list = new ArrayList<T>();
    for (int i = 0; i < count; i++) {
        list.add(factory.get());
    }
    return list;
}

// Pas de `typeof(T)` : passer un jeton Class<T> quand le type est nécessaire à l'exécution.
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

Vous croiserez des jetons de classe partout dans les bibliothèques Java : `objectMapper.readValue(json, Order.class)` dans Jackson, `context.getBean(OrderService.class)` dans Spring. Ils existent parce que la bibliothèque ne peut pas demander à `T` ce qu'il est.

## Le boxing est le prix de `List<Integer>`

Chaque élément d'une `List<Integer>` est un objet `Integer` distinct, là où une `List<int>` C# stocke les valeurs directement. Le boxing crée aussi un piège de surcharge : `List<Integer>` a à la fois `remove(int index)` et `remove(Object value)`.

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

`remove(1)` a supprimé l'élément *à l'index 1* (la valeur 10), et non la valeur 1. Pour les calculs numériques, les streams primitifs `IntStream`, `LongStream` et `DoubleStream` évitent le boxing : `IntStream.rangeClosed(1, 100).sum()` vaut `5050` sans allouer un seul `Integer`.

## Types bruts et pollution du tas

Un type générique utilisé sans arguments de type est un **type brut** (raw type), conservé pour le code antérieur à Java 5. Le compilateur avertit, et il a de bonnes raisons de le faire :

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

Par une référence brute, n'importe quoi peut entrer dans une `List<String>`. Rien n'échoue à l'endroit où la mauvaise valeur est ajoutée ; la `ClassCastException` apparaît plus tard, là où un `String` est relu :

```java
@SuppressWarnings({"rawtypes", "unchecked"}) // volontairement non sûr : la leçon explique la pollution du tas
static void pollute(List<String> names) {
    List raw = names;
    raw.add(42);
}
```

```java
var names = new ArrayList<>(List.of("Ada"));
pollute(names);
System.out.println(names.size());
String second = names.get(1);   // l'exemple intercepte l'exception et affiche son message
```

```text
2
ClassCastException: class java.lang.Integer cannot be cast to class java.lang.String (java.lang.Integer and java.lang.String are in module java.base of loader 'bootstrap')
```

Le cast a été inséré par le compilateur à `names.get(1)`, là où l'effacement avait ramené `String` à `Object`. En C#, `List<string>` aurait rejeté l'`Add` lui-même. Traitez les avertissements `rawtypes` et `unchecked` comme des erreurs dans du code neuf.

## Variance : des wildcards au site d'utilisation au lieu de `in` et `out`

En C#, la variance est déclarée **une fois, sur l'interface** : `IEnumerable<out T>` est covariante, donc un `IEnumerable<string>` *est* un `IEnumerable<object>`. Java n'a pas de variance au site de déclaration. Une `List<String>` n'est jamais une `List<Object>` :

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

À la place, chaque **méthode** indique comment elle utilise son paramètre, avec un [wildcard](https://docs.oracle.com/javase/tutorial/java/generics/wildcards.html) :

```java
// Lit des nombres : toute List d'un sous-type de Number est acceptée (« producer extends »).
static double sum(List<? extends Number> numbers) {
    double total = 0;
    for (Number n : numbers) {
        total += n.doubleValue();
    }
    return total;
}

// Écrit des entiers : toute List capable de contenir un Integer est acceptée (« consumer super »).
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

| C# | Java | Peut lire des `T` | Peut ajouter des `T` |
|---|---|---|---|
| paramètre `IEnumerable<out T>` | `List<? extends T>` | oui | non |
| `IComparer<in T>`, `Action<in T>` | `List<? super T>` | seulement en tant qu'`Object` | oui |
| `IList<T>` (invariante) | `List<T>` | oui | oui |

La règle empirique est **PECS** : *producer `extends`, consumer `super`* (le producteur étend, le consommateur est un super-type). Le compilateur fait respecter les cases « non » ; son message mentionne une *capture* (`CAP#1`), le type inconnu que représente le wildcard :

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

La `List<? extends Number>` pourrait en réalité être une `List<Double>` : y ajouter un `Integer` risquerait de la corrompre.

Les bornes des paramètres de type utilisent aussi `extends`, pour les classes comme pour les interfaces, et `&` pour les combiner :

```java
// Un paramètre de type borné, comme `where T : IComparable<T>`.
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

`max(List.of("pear", "apple", "quince"))` renvoie `quince`. Le `? super T` lui permet d'accepter un type dont le `compareTo` est hérité d'un super-type.

## Les tableaux sont covariants dans les deux langages

Les deux langages ont hérité de tableaux covariants, et tous deux vérifient chaque écriture à l'exécution :

```java
Object[] slots = new String[2];
slots[0] = 42;
```

```text
ArrayStoreException: java.lang.Integer
```

Le côté C# lève `ArrayTypeMismatchException: Attempted to access an element as a type incompatible with the array.` Une raison de plus de préférer `List<T>` dans les deux langages.

## À retenir

- Java vérifie les génériques à la compilation puis les efface : `List<String>` et `List<Integer>` sont la même classe à l'exécution.
- Pas de primitifs comme arguments de type, pas de `new T()`, pas de `T.class`, pas de tableaux génériques, pas de surcharges qui ne diffèrent que par l'argument de type.
- Passez un `Supplier<T>` ou un `Class<T>` quand le code a besoin du type à l'exécution.
- Les types bruts contournent le système de types ; l'échec se manifeste plus tard sous forme de `ClassCastException`.
- La variance se choisit méthode par méthode avec `? extends` (lecture) et `? super` (écriture) — PECS.

## Exercices

1. Traduisez cette méthode C#. Que doit désormais fournir l'appelant ?

```csharp
static T[] Fill<T>(int count) where T : new()
{
    var result = new T[count];
    for (int i = 0; i < count; i++) result[i] = new T();
    return result;
}
```

<details>
<summary>Solution</summary>

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

L'appelant fournit ce que l'effacement a retiré deux fois : comment créer le tableau (`StringBuilder[]::new`) et comment créer un élément (`StringBuilder::new`). C'est le même motif que [`Collection.toArray(IntFunction)`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Collection.html#toArray(java.util.function.IntFunction)).

</details>

2. Écrivez la signature d'une méthode `copy` qui copie chaque élément d'une liste source dans une liste destination, de sorte que copier une `List<Integer>` dans une `List<Number>` compile.

<details>
<summary>Solution</summary>

```java
static <T> void copy(List<? super T> destination, List<? extends T> source) {
    for (T item : source) {
        destination.add(item);
    }
}
```

La source *produit* des `T` (`extends`), la destination les *consomme* (`super`). Pour `copy(numbers, integers)`, `T = Integer` comme `T = Number` satisfont les bornes, donc l'appel compile. C'est la signature de [`Collections.copy`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Collections.html#copy(java.util.List,java.util.List)).

</details>

3. Du code C# filtre une liste hétérogène avec `items.OfType<T>()`. Écrivez `ofType` en Java. Peut-il sélectionner uniquement les éléments `List<String>` d'une `List<Object>` ?

<details>
<summary>Solution</summary>

```java
static <T> List<T> ofType(List<?> items, Class<T> type) {
    return items.stream().filter(type::isInstance).map(type::cast).toList();
}
```

Non : le jeton de classe d'une liste est `List.class`, qui correspond à toute `List` quels que soient ses éléments, et `List<String>.class` n'existe pas. À l'exécution, une `List<String>` et une `List<Integer>` sont indiscernables ; il faudrait inspecter les éléments.

</details>

## Sources

- [dev.java — Generics](https://dev.java/learn/generics/) et [Type erasure](https://docs.oracle.com/javase/tutorial/java/generics/erasure.html)
- [JLS §4.6 — Type erasure](https://docs.oracle.com/javase/specs/jls/se25/html/jls-4.html#jls-4.6) et [§4.8 — Raw types](https://docs.oracle.com/javase/specs/jls/se25/html/jls-4.html#jls-4.8)
- [The Java Tutorials — Wildcards](https://docs.oracle.com/javase/tutorial/java/generics/wildcards.html) et [Restrictions on generics](https://docs.oracle.com/javase/tutorial/java/generics/restrictions.html)
- [C# — Covariance et contravariance dans les génériques](https://learn.microsoft.com/dotnet/standard/generics/covariance-and-contravariance)
- [Project Valhalla](https://openjdk.org/projects/valhalla/) — le chantier de longue haleine sur les classes valeur et les génériques spécialisés
