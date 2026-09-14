---
title: 9. Concurrence et threads virtuels
description: Des threads virtuels au lieu d'async/await, les executors, CompletableFuture comme Task, l'annulation par interruption, locks et atomiques, ScopedValue au lieu d'AsyncLocal, et les streams parallèles.
sidebar:
  order: 9
---

Exemples complets : [`lessons/l09`](https://github.com/spareilleux/learn/tree/main/code/java-for-csharp/src/main/java/lessons/l09).

## Deux réponses au même problème

Un serveur qui attend une base de données, un appel HTTP ou un fichier passe l'essentiel de son temps bloqué. Bloquer un thread du système d'exploitation coûte cher : chacun réserve une pile, et l'ordonnanceur ne peut en jongler qu'un nombre limité. C# a répondu en 2012 avec `async`/`await` : une méthode qui attend rend son thread, et le compilateur la réécrit en machine à états. Java a répondu en 2023 avec les [threads virtuels](https://docs.oracle.com/en/java/javase/25/core/virtual-threads.html) ([JEP 444](https://openjdk.org/jeps/444), Java 21) : le code continue de bloquer, mais le thread qui bloque est un objet JVM peu coûteux, et la JVM le démonte de son thread porteur (carrier thread) pendant qu'il attend.

Java n'a donc pas de mot-clé `async`, pas de type de retour `Task<T>` à propager dans chaque signature, et pas de « async jusqu'au bout » (async all the way down). Une méthode qui lit une socket est une méthode ordinaire.

| C# | Java 25 |
|---|---|
| `Task.Run(...)` | `executor.submit(...)` ou `CompletableFuture.supplyAsync(...)` |
| `await` | un appel bloquant sur un thread virtuel, ou `thenApply`/`thenCompose` |
| `Task<T>` | `Future<T>`, [`CompletableFuture<T>`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/CompletableFuture.html) |
| `await Task.WhenAll(...)` | `executor.invokeAll(...)`, `CompletableFuture.allOf(...)`, ou la fermeture de l'executor |
| `CancellationToken` | l'interruption du thread |
| `lock (obj)`, [`System.Threading.Lock`](https://learn.microsoft.com/dotnet/api/system.threading.lock) | `synchronized (obj)`, [`ReentrantLock`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/locks/ReentrantLock.html) |
| `Interlocked.Increment` | `AtomicInteger`, [`LongAdder`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/atomic/LongAdder.html) |
| `ConcurrentDictionary` | [`ConcurrentHashMap`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/ConcurrentHashMap.html) |
| [`AsyncLocal<T>`](https://learn.microsoft.com/dotnet/api/system.threading.asynclocal-1) | [`ScopedValue<T>`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/ScopedValue.html) (Java 25) |
| [PLINQ](https://learn.microsoft.com/dotnet/standard/parallel-programming/introduction-to-plinq) `AsParallel()` | streams `parallel()` |

## Threads de plateforme et threads virtuels

`Thread.ofPlatform()` construit ce que .NET appelle un thread : un thread du système d'exploitation. `Thread.ofVirtual()` construit un thread virtuel, que la JVM ordonnance sur un petit pool de threads porteurs :

```java
// Un thread de plateforme enveloppe un thread du système d'exploitation, comme new Thread(...) en .NET.
Thread platform = Thread.ofPlatform().name("platform-1").start(() -> System.out.println("hello from a platform thread"));
platform.join();

// Un thread virtuel est ordonnancé par la JVM sur quelques threads porteurs.
Thread virtual = Thread.ofVirtual().name("virtual-1").start(() -> {
    Thread current = Thread.currentThread();
    System.out.println(current.getName() + " isVirtual=" + current.isVirtual() + " daemon=" + current.isDaemon());
});
virtual.join();
```

```text
hello from a platform thread
virtual-1 isVirtual=true daemon=true
```

Les threads virtuels sont toujours des threads démons (daemon) : ils ne maintiennent pas la JVM en vie, donc `main` doit les attendre. Sans le `join()`, le programme pourrait se terminer avant l'affichage de la seconde ligne.

On crée rarement des threads à la main. L'idiome est un executor qui démarre un thread virtuel par tâche, dans un bloc `try`-with-resources. [`ExecutorService.close()`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/ExecutorService.html) (Java 19) attend chaque tâche soumise, ce qui donne `await Task.WhenAll` sans avoir à collecter les tâches :

```java
// Un thread virtuel par tâche : les appels bloquants sont peu coûteux, donc pas d'async/await.
long start = System.nanoTime();
var results = new ArrayList<Future<Integer>>();
try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
    for (int i = 0; i < 10_000; i++) {
        int id = i;
        results.add(executor.submit(() -> {
            Thread.sleep(Duration.ofSeconds(1));
            return id;
        }));
    }
} // close() attend chaque tâche, comme await Task.WhenAll(...)
long sum = 0;
for (Future<Integer> result : results) {
    sum += result.get();
}
Duration elapsed = Duration.ofNanos(System.nanoTime() - start);
System.out.println("10,000 tasks slept 1 s each; sum of ids = " + sum);
System.out.println("finished in under 5 s: " + (elapsed.compareTo(Duration.ofSeconds(5)) < 0));
```

```text
10,000 tasks slept 1 s each; sum of ids = 49995000
finished in under 5 s: true
```

Dix mille `sleep` bloquants prennent environ une seconde au total : le programme entier a tourné en 1,1 s sur ma machine. Avec 10 000 threads de plateforme, le même code réserverait 10 000 piles. Le côté C# obtient les mêmes nombres avec `await Task.WhenAll(Enumerable.Range(0, 10_000).Select(SleepThenReturn))`, où `SleepThenReturn` attend `Task.Delay`. C# réécrit le code ; Java le garde tel quel et rend le thread peu coûteux.

Les threads virtuels aident à *attendre*, pas à calculer. Une boucle liée au CPU (CPU-bound) a toujours besoin d'un cœur, et il n'y a pas plus de cœurs qu'avant. Les streams parallèles, à la fin de cette leçon, sont l'outil pour cela. Ne mettez pas non plus les threads virtuels en pool : ils sont faits pour être créés pour chaque tâche, puis jetés.

Qu'il soit peu coûteux de bloquer ne rend pas pour autant le blocage sûr partout. Les threads de boucle d'événements (event loop) des bibliothèques réactives comme [Project Reactor](https://projectreactor.io/docs/core/release/reference/) et Netty ne doivent jamais bloquer, threads virtuels ou non. [BlockHound](https://github.com/reactor/BlockHound) détecte les appels bloquants sur ces threads, et la [leçon 11](../11-testing/) le met en place dans les tests.

`submit` intercepte une exception levée par la tâche et la conserve dans le `Future`. `get()` la relance, enveloppée dans l'exception vérifiée `ExecutionException` :

```java
// Une exception dans une tâche est conservée dans son Future et relancée, enveloppée, par get().
try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
    Future<Integer> failing = executor.submit(() -> Integer.parseInt("forty-two"));
    try {
        failing.get();
    } catch (ExecutionException e) {
        System.out.println("get() threw " + e.getClass().getSimpleName() + " caused by " + e.getCause());
    }
}
```

```text
get() threw ExecutionException caused by java.lang.NumberFormatException: For input string: "forty-two"
```

### Les exceptions vérifiées rencontrent les threads

Les exceptions vérifiées de la leçon 5 refont surface. `Thread.sleep` lève `InterruptedException`, et `submit` accepte soit un `Runnable`, qui ne peut pas lever d'exception vérifiée, soit un `Callable`, qui le peut. Une lambda à corps de bloc qui ne renvoie rien ne peut être qu'un `Runnable` :

```java
import java.util.concurrent.Executors;

class Sleeper {
    static void run() {
        try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
            executor.submit(() -> {
                Thread.sleep(100);
            });
        }
    }
}
```

```text
SleepInRunnable.java:7: error: unreported exception InterruptedException; must be caught or declared to be thrown
                Thread.sleep(100);
                            ^
1 error
```

Renvoyer une valeur (`return id;` dans l'exemple ci-dessus) fait de la lambda un `Callable`, et l'erreur disparaît. C# n'a pas cette distinction : `Task.Run` accepte n'importe quelle lambda.

## `CompletableFuture` : le `Task` de Java

Un `Future` ne peut qu'être attendu. [`CompletableFuture`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/CompletableFuture.html) (Java 8) ajoute les continuations, et couvre donc ce que C# fait avec `Task`, `ContinueWith` et `await` :

```java
// supplyAsync est Task.Run ; thenApply est le code qui suit un await.
CompletableFuture<Integer> score = CompletableFuture
        .supplyAsync(() -> fetchUser(7), executor)
        .thenApply(Futures::fetchScore);
System.out.println("score: " + score.join());

// thenCombine attend deux futures indépendants, comme await Task.WhenAll(a, b).
var name = CompletableFuture.supplyAsync(() -> "Ada", executor);
var year = CompletableFuture.supplyAsync(() -> 1815, executor);
System.out.println(name.thenCombine(year, (n, y) -> n + " was born in " + y).join());

// allOf se termine quand tous les futures sont terminés ; les résultats sont lus ensuite.
List<CompletableFuture<String>> users = List.of(1, 2, 3).stream()
        .map(id -> CompletableFuture.supplyAsync(() -> fetchUser(id), executor))
        .toList();
CompletableFuture.allOf(users.toArray(CompletableFuture[]::new)).join();
System.out.println(users.stream().map(CompletableFuture::join).toList());

// Échecs : join() enveloppe dans CompletionException, get() dans ExecutionException.
CompletableFuture<Integer> failing = CompletableFuture.supplyAsync(() -> Integer.parseInt("x"), executor);
try {
    failing.join();
} catch (CompletionException e) {
    System.out.println("join: " + e.getCause().getClass().getSimpleName());
}
try {
    failing.get();
} catch (ExecutionException e) {
    System.out.println("get: " + e.getCause().getClass().getSimpleName());
}
System.out.println("recovered: " + failing.exceptionally(e -> -1).join());
```

```text
score: 60
Ada was born in 1815
[user-1, user-2, user-3]
join: NumberFormatException
get: NumberFormatException
recovered: -1
```

Ici, les futures s'exécutent sur l'executor de threads virtuels de la leçon. Sans l'argument `executor`, `supplyAsync` s'exécute sur le `ForkJoinPool` commun, un pool de threads de plateforme dimensionné d'après le nombre de cœurs, ce qui est le mauvais endroit pour des tâches qui bloquent.

Deux différences avec C# prennent les gens au dépourvu :

- **Pas de déballage.** `await` relance l'exception d'origine ; `CompletableFuture` l'enveloppe toujours, comme le `.Result` de C# l'enveloppe dans une `AggregateException`. Le côté C# affiche `Result: AggregateException of FormatException` puis `await: FormatException`.
- **`get()` lève des exceptions vérifiées, `join()` non.** `get()` déclare `InterruptedException` et `ExecutionException` : l'habitude du `.Result` ne compile donc pas dans une méthode qui ne les traite pas :

```java
import java.util.concurrent.CompletableFuture;

class Results {
    static String name() {
        return CompletableFuture.supplyAsync(() -> "Ada").get();
    }
}
```

```text
BlockingGet.java:5: error: unreported exception InterruptedException; must be caught or declared to be thrown
        return CompletableFuture.supplyAsync(() -> "Ada").get();
                                                             ^
1 error
```

Avec les threads virtuels, les longues chaînes de `thenApply` sont moins nécessaires : du code qui s'exécute sur un thread virtuel peut appeler `join()` et continuer à la ligne suivante, ce qui se lit comme un `await`. Le mot-clé lui-même n'existe pas, et le message de javac n'est qu'une erreur de syntaxe :

```java
import java.util.concurrent.CompletableFuture;

class Client {
    static CompletableFuture<String> fetch() {
        return CompletableFuture.completedFuture("ok");
    }

    static String body() {
        return await fetch();
    }
}
```

```text
AwaitKeyword.java:9: error: ';' expected
        return await fetch();
                    ^
1 error
```

## Annuler, c'est interrompre

Java n'a pas de `CancellationToken`. On annule un thread en l'**interrompant** : les méthodes bloquantes comme `Thread.sleep`, `BlockingQueue.take` ou `Future.get` lèvent alors `InterruptedException`, et une boucle liée au CPU vérifie `Thread.currentThread().isInterrupted()`. `Future.cancel(true)` interrompt le thread qui exécute la tâche :

```java
// Annulation : pas de CancellationToken ; cancel(true) interrompt le thread qui exécute la tâche.
var started = new CountDownLatch(1);
var stopped = new CountDownLatch(1);
var worker = executor.submit(() -> {
    started.countDown();
    try {
        Thread.sleep(60_000);
        return "finished";
    } catch (InterruptedException e) {
        System.out.println("worker interrupted while sleeping");
        stopped.countDown();
        throw e;
    }
});
started.await();
worker.cancel(true);
stopped.await();
System.out.println("cancelled: " + worker.isCancelled() + ", state: " + worker.state());
```

```text
worker interrupted while sleeping
cancelled: true, state: CANCELLED
```

Les deux latches ne servent qu'à rendre l'ordre de la sortie déterministe. L'équivalent C# passe `cts.Token` à `Task.Delay` et affiche `cancelled: True, status: Canceled`. La différence tient à qui demande : le code C# doit accepter un jeton et le transmettre, alors que tout code Java qui bloque est annulable sans changer de signature. Le prix est une règle à respecter : une méthode qui intercepte `InterruptedException` doit soit la relancer, soit restaurer l'indicateur avec `Thread.currentThread().interrupt()`, sinon l'annulation est perdue en silence.

`CompletableFuture` enfreint cette règle délibérément. Son `cancel(true)` complète le future avec une `CancellationException`, mais la Javadoc précise que l'argument « has no effect in this implementation because interrupts are not used to control processing ». La tâche continue de s'exécuter :

```java
// Un délai d'expiration sur le future lui-même, comme Task.WaitAsync(TimeSpan).
var slow = CompletableFuture.supplyAsync(() -> sleepThenReturn(1_000), executor);
try {
    slow.get(50, TimeUnit.MILLISECONDS);
} catch (TimeoutException e) {
    System.out.println("timed out after 50 ms");
}
// cancel(true) complète le CompletableFuture mais n'interrompt pas la tâche qui se trouve derrière.
System.out.println("slow cancelled: " + slow.cancel(true));
```

```text
timed out after 50 ms
slow cancelled: true
worker interrupted while sleeping
cancelled: true, state: CANCELLED
slow task ran to the end
```

La dernière ligne apparaît une seconde plus tard, quand le `close()` de l'executor attend la tâche lente qui n'a jamais été arrêtée. Ma première version dormait cinq secondes, et l'exemple mettait cinq secondes à se terminer : c'est comme ça que je l'ai découvert.

## État partagé

Les threads virtuels ne changent rien aux accès concurrents aux données (data races). Cette boucle incrémente un `static int` depuis 1 000 tâches, 1 000 fois chacune :

```java
executor.submit(() -> {
    for (int i = 0; i < 1_000; i++) {
        value++;
    }
});
```

Trois exécutions sur ma machine ont affiché 76 422, puis 855 000, puis 803 000, au lieu de 1 000 000. Cet extrait ne fait pas partie des exemples testés, car sa sortie est imprévisible.

Le même code avec une variable locale ne compile pas. Une lambda capture des valeurs, pas des variables (leçon 6) : Java rejette donc la variable locale mutable partagée que C# accepte, et sur laquelle ses threads entrent en concurrence :

```java
class Clicks {
    static int count() throws InterruptedException {
        int count = 0;
        Thread worker = Thread.ofVirtual().start(() -> count++);
        worker.join();
        return count;
    }
}
```

```text
CaptureCounter.java:4: error: local variables referenced from a lambda expression must be final or effectively final
        Thread worker = Thread.ofVirtual().start(() -> count++);
                                                       ^
1 error
```

Les correctifs sont ceux que vous connaissez en .NET :

```java
static class Counter {
    private int value;

    // synchronized est le lock (this) de C# ; chaque objet a un moniteur.
    synchronized void increment() {
        value++;
    }

    synchronized int value() {
        return value;
    }
}

static class Account {
    private final ReentrantLock lock = new ReentrantLock();
    private long balance;

    // Un lock explicite, avec try/finally là où C# utilise une instruction lock.
    void deposit(long amount) {
        lock.lock();
        try {
            balance += amount;
        } finally {
            lock.unlock();
        }
    }
```

En exécutant chaque compteur depuis 1 000 tâches de 1 000 incréments, et en comptant des mots avec `ConcurrentHashMap.merge` :

```java
// merge est atomique par clé, comme ConcurrentDictionary.AddOrUpdate.
var words = List.of("to", "be", "or", "not", "to", "be");
var counts = new ConcurrentHashMap<String, Integer>();
try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
    for (int copy = 0; copy < 100; copy++) {
        for (String word : words) {
            executor.submit(() -> counts.merge(word, 1, Integer::sum));
        }
    }
}
Map<String, Integer> sorted = new TreeMap<>(counts);
System.out.println("word counts: " + sorted);
```

```text
synchronized: 1000000
AtomicInteger: 1000000
LongAdder: 1000000
ReentrantLock: 1000000
word counts: {be=200, not=100, or=100, to=200}
```

- **`synchronized`** est `lock`. Une méthode `synchronized` verrouille `this` (ou la classe, pour une méthode statique), ce que les guides de style C# déconseillent et que le code Java fait en permanence. Depuis C# 13, le code .NET peut verrouiller un [`System.Threading.Lock`](https://learn.microsoft.com/dotnet/api/system.threading.lock) dédié ; en Java, un champ `ReentrantLock` joue ce rôle et ajoute `tryLock` avec un délai d'expiration.
- **`AtomicInteger`** est `Interlocked`, enveloppé dans un objet. `LongAdder` passe mieux à l'échelle quand de nombreux threads incrémentent souvent le même compteur.
- **Avant Java 24, `synchronized` épinglait les threads virtuels** : un thread virtuel qui bloquait dans un bloc `synchronized` gardait son thread porteur, et les bibliothèques passaient à `ReentrantLock` pour l'éviter. La [JEP 491](https://openjdk.org/jeps/491) a levé cette limitation en Java 24 : le conseil d'éviter `synchronized` avec les threads virtuels est donc périmé en Java 25.

Comme C#, qui refuse `lock` sur un type valeur ([CS0185](https://learn.microsoft.com/dotnet/csharp/misc/cs0185)), Java refuse de synchroniser sur un type primitif :

```java
class Tally {
    private int count;

    void increment() {
        synchronized (count) {
            count++;
        }
    }
}
```

```text
SynchronizeOnInt.java:5: error: unexpected type
        synchronized (count) {
        ^
  required: reference
  found:    int
1 error
```

Remplacez `int` par `Integer` et le code compile, ce qui est pire : `count++` remplace l'objet boxé, donc chaque thread peut verrouiller un `Integer` différent. javac se contente d'un avertissement, et seulement avec `-Xlint` :

```text
SynchronizeOnInteger.java:5: warning: [identity] attempt to synchronize on an instance of a value-based class
        synchronized (count) {
        ^
1 warning
```

## `ThreadLocal`, `ScopedValue` et `AsyncLocal`

Le code C# qui a besoin d'un contexte ambiant (l'utilisateur courant, un identifiant de trace) utilise `AsyncLocal<T>`, qui suit les `await` et se propage aux tâches et aux nouveaux threads. Le `ThreadLocal` de Java ne se propage nulle part, et un thread virtuel par tâche, c'est un nouveau thread à chaque fois. [`ScopedValue`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/ScopedValue.html) ([JEP 506](https://openjdk.org/jeps/506), finalisée en Java 25) est le remplaçant moderne : une valeur liée pour la durée d'un appel, immuable pendant cet appel, puis de nouveau déliée :

```java
static final ThreadLocal<String> CURRENT_USER = new ThreadLocal<>();

// Un ScopedValue est lié pour la durée d'un appel, puis de nouveau délié.
static final ScopedValue<String> REQUEST_USER = ScopedValue.newInstance();

static String greet() {
    return "hello " + (REQUEST_USER.isBound() ? REQUEST_USER.get() : "nobody");
}

public static void main(String[] args) throws Exception {
    CURRENT_USER.set("ada");
    try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
        // Un ThreadLocal appartient à un seul thread : une tâche sur un autre thread ne le voit pas.
        System.out.println("caller thread: " + CURRENT_USER.get());
        System.out.println("executor task: " + executor.submit(CURRENT_USER::get).get());
    } finally {
        CURRENT_USER.remove();
    }

    ScopedValue.where(REQUEST_USER, "grace").run(() -> {
        System.out.println("inside the scope: " + greet());
        ScopedValue.where(REQUEST_USER, "alan").run(() -> System.out.println("nested scope: " + greet()));
        System.out.println("back in the outer scope: " + greet());
    });
    System.out.println("after the scope: " + greet());

    // Les scoped values ne passent pas non plus dans un executor ordinaire : il faut pour cela la concurrence structurée (préversion).
    ScopedValue.where(REQUEST_USER, "grace").run(() -> {
        try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
            System.out.println("executor task in the scope: " + executor.submit(ScopedValues::greet).get());
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }
    });
}
```

```text
caller thread: ada
executor task: null
inside the scope: hello grace
nested scope: hello alan
back in the outer scope: hello grace
after the scope: hello nobody
executor task in the scope: hello nobody
```

Le côté C# affiche `AsyncLocal in Task.Run: grace` et `in a new thread: AsyncLocal grace, ThreadLocal null`. La dernière ligne Java montre l'écart : une scoped value n'atteint les threads enfants que s'ils sont créés (forked) par un `StructuredTaskScope`, et cette API est encore en préversion.

## La concurrence structurée est encore en préversion

La [concurrence structurée](https://openjdk.org/jeps/505) (structured concurrency) traite un groupe de sous-tâches comme une seule unité : si l'une échoue, les autres sont annulées, et la portée ne se termine pas avant qu'elles aient toutes fini. C'est ce qui se rapproche le plus d'un `Task.WhenAll` qui annule les tâches sœurs. En Java 25, elle en est à sa cinquième préversion, et l'utiliser sans `--enable-preview` échoue :

```java
import java.util.concurrent.StructuredTaskScope;

class Fanout {
    static String both() throws InterruptedException {
        try (var scope = StructuredTaskScope.open()) {
            var user = scope.fork(() -> "ada");
            var order = scope.fork(() -> 42);
            scope.join();
            return user.get() + " " + order.get();
        }
    }
}
```

```text
StructuredScope.java:1: error: StructuredTaskScope is a preview API and is disabled by default.
import java.util.concurrent.StructuredTaskScope;
                           ^
  (use --enable-preview to enable preview APIs)
StructuredScope.java:5: error: StructuredTaskScope is a preview API and is disabled by default.
        try (var scope = StructuredTaskScope.open()) {
                         ^
  (use --enable-preview to enable preview APIs)
2 errors
```

Comme pour les motifs primitifs de la leçon 8, ce cours n'utilise pas les fonctionnalités en préversion. L'API a changé d'une préversion à l'autre : en Java 25, une portée se crée avec des méthodes fabriques statiques `open()` et un `Joiner` qui fixe la politique de terminaison, là où les préversions précédentes utilisaient des constructeurs et des sous-classes comme `ShutdownOnFailure`.

## Streams parallèles

La leçon 7 avait promis cette section. `parallel()` sur un stream est le `AsParallel()` de PLINQ : le stream est découpé et traité sur le `ForkJoinPool` commun :

```java
// parallel() est AsParallel() ; le résultat est le même qu'en séquentiel.
long sequential = IntStream.rangeClosed(1, 2_000_000).filter(ParallelStreams::isPrime).count();
long parallel = IntStream.rangeClosed(1, 2_000_000).parallel().filter(ParallelStreams::isPrime).count();
System.out.println("primes up to 2,000,000: " + sequential + " sequential, " + parallel + " parallel");

// Contrairement à PLINQ sans AsOrdered(), la collecte conserve l'ordre de rencontre.
List<Integer> squares = IntStream.rangeClosed(1, 10).parallel().map(x -> x * x).boxed().toList();
System.out.println("squares: " + squares);

// forEach s'exécute dans l'ordre où les threads atteignent les éléments ; forEachOrdered le rétablit.
var ordered = new StringBuilder();
IntStream.rangeClosed(1, 10).parallel().forEachOrdered(x -> ordered.append(x).append(' '));
System.out.println("forEachOrdered: " + ordered.toString().strip());

// reduce exige un vrai élément neutre : 0 pour l'addition. En séquentiel, un mauvais élément neutre est ajouté une fois.
int wrongIdentitySequential = IntStream.rangeClosed(1, 4).reduce(10, Integer::sum);
int rightIdentityParallel = IntStream.rangeClosed(1, 4).parallel().reduce(0, Integer::sum);
System.out.println("reduce(10) sequential: " + wrongIdentitySequential + ", reduce(0) parallel: " + rightIdentityParallel);

// Les streams parallèles s'exécutent sur le ForkJoinPool commun, partagé par toute la JVM.
Set<String> threads = ConcurrentHashMap.newKeySet();
IntStream.rangeClosed(1, 2_000_000).parallel().filter(n -> {
    threads.add(Thread.currentThread().getName());
    return isPrime(n);
}).count();
System.out.println("caller thread took part: " + threads.contains(Thread.currentThread().getName()));
System.out.println("common pool workers took part: " + threads.stream().anyMatch(t -> t.startsWith("ForkJoinPool.commonPool-worker-")));
```

```text
primes up to 2,000,000: 148933 sequential, 148933 parallel
squares: [1, 4, 9, 16, 25, 36, 49, 64, 81, 100]
forEachOrdered: 1 2 3 4 5 6 7 8 9 10
reduce(10) sequential: 20, reduce(0) parallel: 10
caller thread took part: true
common pool workers took part: true
```

- **L'ordre est conservé par défaut.** Un stream parallèle sur une source ordonnée collecte toujours dans l'ordre de rencontre ; PLINQ a besoin de `AsOrdered()`. Le côté C# affiche `AsOrdered: 1, 4, 9, …`. Seul `forEach` renonce à l'ordre.
- **L'élément neutre de `reduce` doit en être un vrai.** `reduce(10, Integer::sum)` ajoute 10 une fois en séquentiel, mais un stream parallèle l'ajoute une fois par morceau : le résultat dépend donc du nombre de morceaux que crée la machine. C'est pourquoi l'exemple n'utilise le mauvais élément neutre qu'en séquentiel.
- **L'appelant travaille aussi.** Le thread qui lance l'opération terminale y participe, aux côtés des workers du pool commun. Le pool est partagé par toute la JVM : un stream parallèle lent ralentit donc tous les autres.

Les streams parallèles sont utiles pour un travail volumineux, lié au CPU et sans état, sur des sources qui se découpent bien (tableaux, intervalles, `ArrayList`). Ils ne le sont pas pour les E/S bloquantes (utilisez des threads virtuels), pour les petites collections (le découpage coûte plus qu'il ne rapporte), ni pour `LinkedList` et `Stream.iterate`, qui se découpent mal. Mesurez avant et après, avec une JVM chauffée : la leçon 13 revient sur les benchmarks.

## À retenir

- Les threads virtuels rendent le blocage peu coûteux, donc le code Java reste synchrone : pas d'`async`, pas de `Task` dans les signatures. Utilisez `Executors.newVirtualThreadPerTaskExecutor()` dans un `try`-with-resources ; `close()` attend toutes les tâches.
- Les threads virtuels aident à attendre, pas à calculer. Ne les mettez pas en pool.
- `CompletableFuture` est `Task` : `supplyAsync`, `thenApply`, `thenCombine`, `allOf`. Les exceptions sont toujours enveloppées, et `get()` lève des exceptions vérifiées là où `join()` n'en lève pas.
- Annuler, c'est interrompre. Relancez `InterruptedException` ou restaurez l'indicateur d'interruption. `CompletableFuture.cancel(true)` n'interrompt rien.
- `synchronized`, `ReentrantLock`, les atomiques et `ConcurrentHashMap` correspondent à `lock`, `Interlocked` et `ConcurrentDictionary`. Depuis Java 24, `synchronized` n'épingle plus les threads virtuels.
- `ScopedValue` (finalisée en Java 25) remplace `ThreadLocal` pour le contexte de requête, mais seule la concurrence structurée, encore en préversion, la transmet aux threads enfants.
- Les streams parallèles conservent l'ordre de rencontre, s'exécutent sur le pool commun partagé et exigent un vrai élément neutre dans `reduce`.

## Exercices

1. Écrivez `fetchAll(List<T> inputs, Function<T, R> fetch)`, l'équivalent Java de `await Task.WhenAll(inputs.Select(FetchAsync))` : elle exécute tous les appels de façon concurrente et renvoie les résultats dans l'ordre des entrées. Avec un `fetch` qui dort 200 ms, 100 entrées doivent se terminer en bien moins de 5 secondes.

<details>
<summary>Solution</summary>

```java
static <T, R> List<R> fetchAll(List<T> inputs, Function<T, R> fetch) throws InterruptedException, ExecutionException {
    try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
        List<Callable<R>> calls = inputs.stream().<Callable<R>>map(input -> () -> fetch.apply(input)).toList();
        List<R> results = new ArrayList<>();
        for (Future<R> future : executor.invokeAll(calls)) {
            results.add(future.get());
        }
        return results;
    }
}
```

`invokeAll` attend tous les appels et renvoie leurs futures dans l'ordre de la liste : les résultats s'alignent donc sur les entrées. Le témoin de type `<Callable<R>>` est nécessaire : sans lui, la lambda interne n'a pas de type cible, et javac signale « cannot infer type-variable(s) R … Object is not a functional interface ». Le test exécute 100 appels de 200 ms et vérifie l'ordre et le temps écoulé. `fetch` est une `Function` : elle ne peut donc pas lever d'exception vérifiée, et un vrai appel HTTP envelopperait son `IOException`, comme dans l'exercice 1 de la leçon 5.

</details>

2. Le code C# limite souvent les appels concurrents avec `SemaphoreSlim(3)` et `await semaphore.WaitAsync()`. Écrivez `mapThrottled(inputs, maxConcurrency, work)`, qui réutilise `fetchAll` mais ne laisse s'exécuter en même temps qu'au plus `maxConcurrency` appels de `work`.

<details>
<summary>Solution</summary>

```java
static <T, R> List<R> mapThrottled(List<T> inputs, int maxConcurrency, Function<T, R> work)
        throws InterruptedException, ExecutionException {
    var permits = new Semaphore(maxConcurrency);
    return fetchAll(inputs, input -> {
        try {
            permits.acquire();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException(e);
        }
        try {
            return work.apply(input);
        } finally {
            permits.release();
        }
    });
}
```

[`Semaphore`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/Semaphore.html) est `SemaphoreSlim` avec un `acquire()` bloquant, ce qui ne pose aucun problème sur un thread virtuel. Chaque entrée a toujours son propre thread virtuel, mais seules trois à la fois passent `acquire()`. Le test enregistre le plus grand nombre d'appels en cours au même moment et vérifie qu'il ne dépasse jamais 3. Le `finally` compte autant que le `Release()` dans un `finally` en C# : sans lui, une exception dans `work` garderait un permis pour toujours.

</details>

3. Deux comptes, deux sortes de tâches : l'une transfère de `a` vers `b`, l'autre de `b` vers `a`, chacune verrouillant les deux comptes avec `synchronized`. Écrites naïvement, 10 000 tâches de ce genre peuvent se retrouver en interblocage (deadlock). Écrivez un `transfer(from, to, amount)` qui ne peut pas provoquer d'interblocage, et vérifiez que le solde total est conservé.

<details>
<summary>Solution</summary>

```java
static final class Account {
    final int id;
    long balance;

    Account(int id, long balance) {
        this.id = id;
        this.balance = balance;
    }
}

// Verrouiller d'abord le compte au plus petit id, pour que deux transferts opposés ne puissent pas s'attendre mutuellement.
static void transfer(Account from, Account to, long amount) {
    Account first = from.id < to.id ? from : to;
    Account second = first == from ? to : from;
    synchronized (first) {
        synchronized (second) {
            from.balance -= amount;
            to.balance += amount;
        }
    }
}
```

Un interblocage exige un cycle : une tâche détient `a` et attend `b` pendant qu'une autre détient `b` et attend `a`. Verrouiller dans un ordre global (ici par id) brise le cycle, en Java comme avec des instructions `lock` imbriquées en C#. Le test exécute 10 000 transferts dans des sens alternés sous `assertTimeoutPreemptively`, pour qu'un interblocage fasse échouer le test au lieu de le bloquer, puis vérifie que les deux soldes totalisent toujours 2 000 000. Un `ReentrantLock` avec `tryLock(timeout)` est l'autre réponse classique : renoncer et réessayer au lieu d'attendre indéfiniment.

</details>

## Sources

- [Java Core Libraries — Threads virtuels](https://docs.oracle.com/en/java/javase/25/core/virtual-threads.html)
- [JEP 444 — Virtual Threads](https://openjdk.org/jeps/444), [JEP 491 — Synchronize Virtual Threads without Pinning](https://openjdk.org/jeps/491), [JEP 505 — Structured Concurrency (Fifth Preview)](https://openjdk.org/jeps/505), [JEP 506 — Scoped Values](https://openjdk.org/jeps/506)
- [Résumé du package `java.util.concurrent`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/package-summary.html) et [`java.util.stream` — parallélisme](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/stream/package-summary.html)
- [JLS chapitre 17 — Threads and Locks](https://docs.oracle.com/javase/specs/jls/se25/html/jls-17.html)
- C# : [programmation asynchrone](https://learn.microsoft.com/dotnet/csharp/asynchronous-programming/), [annulation dans les threads managés](https://learn.microsoft.com/dotnet/standard/threading/cancellation-in-managed-threads), [l'instruction `lock`](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/lock), [PLINQ](https://learn.microsoft.com/dotnet/standard/parallel-programming/introduction-to-plinq)
