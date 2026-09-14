---
title: 9. Concurrencia e hilos virtuales
description: Hilos virtuales en lugar de async/await, executors, CompletableFuture como Task, cancelación por interrupción, locks y atómicos, ScopedValue en lugar de AsyncLocal, y streams paralelos.
sidebar:
  order: 9
---

Ejemplos completos: [`lessons/l09`](https://github.com/spareilleux/learn/tree/main/code/java-for-csharp/src/main/java/lessons/l09).

## Dos respuestas al mismo problema

Un servidor que espera a una base de datos, a una llamada HTTP o a un archivo pasa la mayor parte del tiempo bloqueado. Bloquear un hilo del sistema operativo es caro: cada uno reserva una pila, y el planificador solo puede gestionar un número limitado. C# respondió en 2012 con `async`/`await`: un método que hace `await` devuelve su hilo, y el compilador lo reescribe como una máquina de estados. Java respondió en 2023 con los [hilos virtuales](https://docs.oracle.com/en/java/javase/25/core/virtual-threads.html) ([JEP 444](https://openjdk.org/jeps/444), Java 21): el código sigue bloqueando, pero el hilo que se bloquea es un objeto barato de la JVM, y la JVM lo desmonta de su hilo portador (carrier thread) mientras espera.

Así que Java no tiene palabra clave `async`, ni tipo de retorno `Task<T>` que arrastrar por todas las firmas, ni «async de arriba abajo» (async all the way down). Un método que lee de un socket es un método normal.

| C# | Java 25 |
|---|---|
| `Task.Run(...)` | `executor.submit(...)` o `CompletableFuture.supplyAsync(...)` |
| `await` | una llamada bloqueante en un hilo virtual, o `thenApply`/`thenCompose` |
| `Task<T>` | `Future<T>`, [`CompletableFuture<T>`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/CompletableFuture.html) |
| `await Task.WhenAll(...)` | `executor.invokeAll(...)`, `CompletableFuture.allOf(...)`, o cerrar el executor |
| `CancellationToken` | interrupción del hilo |
| `lock (obj)`, [`System.Threading.Lock`](https://learn.microsoft.com/dotnet/api/system.threading.lock) | `synchronized (obj)`, [`ReentrantLock`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/locks/ReentrantLock.html) |
| `Interlocked.Increment` | `AtomicInteger`, [`LongAdder`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/atomic/LongAdder.html) |
| `ConcurrentDictionary` | [`ConcurrentHashMap`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/ConcurrentHashMap.html) |
| [`AsyncLocal<T>`](https://learn.microsoft.com/dotnet/api/system.threading.asynclocal-1) | [`ScopedValue<T>`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/ScopedValue.html) (Java 25) |
| [PLINQ](https://learn.microsoft.com/dotnet/standard/parallel-programming/introduction-to-plinq) `AsParallel()` | streams `parallel()` |

## Hilos de plataforma e hilos virtuales

`Thread.ofPlatform()` construye lo que .NET llama un hilo: un hilo del sistema operativo. `Thread.ofVirtual()` construye un hilo virtual, que la JVM planifica sobre un pequeño pool de hilos portadores:

```java
// Un hilo de plataforma envuelve un hilo del sistema operativo, como new Thread(...) en .NET.
Thread platform = Thread.ofPlatform().name("platform-1").start(() -> System.out.println("hello from a platform thread"));
platform.join();

// Un hilo virtual lo planifica la JVM sobre unos pocos hilos portadores.
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

Los hilos virtuales son siempre hilos daemon: no mantienen viva la JVM, así que `main` debe esperarlos. Sin el `join()`, el programa podría terminar antes de que se imprima la segunda línea.

Rara vez creas hilos a mano. Lo idiomático es un executor que arranca un hilo virtual por tarea, en un bloque `try`-with-resources. [`ExecutorService.close()`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/ExecutorService.html) (Java 19) espera a todas las tareas enviadas, lo que te da `await Task.WhenAll` sin tener que recopilar las tareas:

```java
// Un hilo virtual por tarea: las llamadas bloqueantes son baratas, así que no hay async/await.
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
} // close() espera a todas las tareas, como await Task.WhenAll(...)
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

Diez mil esperas bloqueantes tardan en total alrededor de un segundo: el programa entero se ejecutó en 1,1 s en mi máquina. Con 10.000 hilos de plataforma, el mismo código reservaría 10.000 pilas. El lado C# obtiene las mismas cifras con `await Task.WhenAll(Enumerable.Range(0, 10_000).Select(SleepThenReturn))`, donde `SleepThenReturn` hace `await` de `Task.Delay`. C# reescribe el código; Java lo conserva y abarata el hilo.

Los hilos virtuales ayudan a *esperar*, no a calcular. Un bucle limitado por la CPU (CPU-bound) sigue necesitando un núcleo, y no hay más núcleos que antes. Los streams paralelos, al final de esta lección, son la herramienta para eso. Tampoco metas los hilos virtuales en un pool: están pensados para crearse por tarea y desecharse.

`submit` captura una excepción lanzada por la tarea y la guarda en el `Future`. `get()` la vuelve a lanzar envuelta en la excepción comprobada `ExecutionException`:

```java
// Una excepción dentro de una tarea se guarda en su Future, y get() la vuelve a lanzar envuelta.
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

### Las excepciones comprobadas se encuentran con los hilos

Las excepciones comprobadas de la lección 5 vuelven a aparecer. `Thread.sleep` lanza `InterruptedException`, y `submit` acepta o bien un `Runnable`, que no puede lanzar excepciones comprobadas, o bien un `Callable`, que sí puede. Una lambda de bloque que no devuelve nada solo puede ser un `Runnable`:

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

Devolver un valor (`return id;` en el ejemplo anterior) convierte la lambda en un `Callable`, y el error desaparece. C# no tiene esta división: `Task.Run` acepta cualquier lambda.

## `CompletableFuture`: el `Task` de Java

Un `Future` solo se puede esperar. [`CompletableFuture`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/CompletableFuture.html) (Java 8) añade continuaciones, así que cubre lo que C# hace con `Task`, `ContinueWith` y `await`:

```java
// supplyAsync es Task.Run; thenApply es el código que va después de un await.
CompletableFuture<Integer> score = CompletableFuture
        .supplyAsync(() -> fetchUser(7), executor)
        .thenApply(Futures::fetchScore);
System.out.println("score: " + score.join());

// thenCombine espera a dos futures independientes, como await Task.WhenAll(a, b).
var name = CompletableFuture.supplyAsync(() -> "Ada", executor);
var year = CompletableFuture.supplyAsync(() -> 1815, executor);
System.out.println(name.thenCombine(year, (n, y) -> n + " was born in " + y).join());

// allOf se completa cuando se han completado todos los futures; los resultados se leen después.
List<CompletableFuture<String>> users = List.of(1, 2, 3).stream()
        .map(id -> CompletableFuture.supplyAsync(() -> fetchUser(id), executor))
        .toList();
CompletableFuture.allOf(users.toArray(CompletableFuture[]::new)).join();
System.out.println(users.stream().map(CompletableFuture::join).toList());

// Fallos: join() envuelve en CompletionException, get() en ExecutionException.
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

Aquí los futures se ejecutan en el executor de hilos virtuales de la lección. Sin el argumento `executor`, `supplyAsync` se ejecuta en el `ForkJoinPool` común, un pool de hilos de plataforma dimensionado según el número de núcleos, que es el sitio equivocado para las tareas que bloquean.

Dos diferencias con C# pillan desprevenido a más de uno:

- **Nada de desenvolver.** `await` vuelve a lanzar la excepción original; `CompletableFuture` siempre la envuelve, como `.Result` de C# la envuelve en `AggregateException`. El lado C# imprime `Result: AggregateException of FormatException` y después `await: FormatException`.
- **`get()` es comprobado, `join()` no.** `get()` declara `InterruptedException` y `ExecutionException`, así que la costumbre de `.Result` no compila en un método que no las trata:

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

Con los hilos virtuales, las largas cadenas de `thenApply` son menos necesarias: el código que se ejecuta en un hilo virtual puede llamar a `join()` y continuar en la línea siguiente, lo que se lee como un `await`. La palabra clave en sí no existe, y el mensaje de javac es un simple error de sintaxis:

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

## La cancelación es interrupción

Java no tiene `CancellationToken`. Un hilo se cancela **interrumpiéndolo**: los métodos bloqueantes como `Thread.sleep`, `BlockingQueue.take` o `Future.get` lanzan entonces `InterruptedException`, y un bucle limitado por la CPU comprueba `Thread.currentThread().isInterrupted()`. `Future.cancel(true)` interrumpe el hilo que ejecuta la tarea:

```java
// Cancelación: no hay CancellationToken; cancel(true) interrumpe el hilo que ejecuta la tarea.
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

Los dos latches solo sirven para que el orden de la salida sea determinista. El equivalente en C# pasa `cts.Token` a `Task.Delay` e imprime `cancelled: True, status: Canceled`. La diferencia está en quién lo pide: el código C# debe aceptar un token y pasarlo hacia abajo, mientras que cualquier código Java que bloquea se puede cancelar sin cambiar su firma. El precio es una regla que respetar: un método que captura `InterruptedException` debe volver a lanzarla o restaurar el indicador con `Thread.currentThread().interrupt()`; si no, la cancelación se pierde sin avisar.

`CompletableFuture` rompe esta regla a propósito. Su `cancel(true)` completa el future con una `CancellationException`, pero el Javadoc dice que el argumento «has no effect in this implementation because interrupts are not used to control processing». La tarea sigue ejecutándose:

```java
// Un timeout sobre el propio future, como Task.WaitAsync(TimeSpan).
var slow = CompletableFuture.supplyAsync(() -> sleepThenReturn(1_000), executor);
try {
    slow.get(50, TimeUnit.MILLISECONDS);
} catch (TimeoutException e) {
    System.out.println("timed out after 50 ms");
}
// cancel(true) completa el CompletableFuture, pero no interrumpe la tarea que hay detrás.
System.out.println("slow cancelled: " + slow.cancel(true));
```

```text
timed out after 50 ms
slow cancelled: true
worker interrupted while sleeping
cancelled: true, state: CANCELLED
slow task ran to the end
```

La última línea aparece un segundo más tarde, cuando el `close()` del executor espera a la tarea lenta que nunca se detuvo. Mi primera versión dormía cinco segundos, y el ejemplo tardaba cinco segundos en terminar: así fue como me di cuenta.

## Estado compartido

Los hilos virtuales no cambian nada respecto a las carreras de datos (data races). Este bucle incrementa un `static int` desde 1.000 tareas, 1.000 veces cada una:

```java
executor.submit(() -> {
    for (int i = 0; i < 1_000; i++) {
        value++;
    }
});
```

Tres ejecuciones en mi máquina imprimieron 76.422, luego 855.000 y luego 803.000, en lugar de 1.000.000. Este fragmento no forma parte de los ejemplos probados, porque su salida no se puede predecir.

El mismo código con una variable local no compila. Una lambda captura valores, no variables (lección 6), así que Java rechaza la variable local mutable compartida que C# acepta y sobre la que se produce la carrera:

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

Las soluciones son las que ya conoces de .NET:

```java
static class Counter {
    private int value;

    // synchronized es el lock (this) de C#; todo objeto tiene un monitor.
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

    // Un lock explícito, con try/finally donde C# usa una sentencia lock.
    void deposit(long amount) {
        lock.lock();
        try {
            balance += amount;
        } finally {
            lock.unlock();
        }
    }
```

Ejecutando cada contador desde 1.000 tareas de 1.000 incrementos, y contando palabras con `ConcurrentHashMap.merge`:

```java
// merge es atómico por clave, como ConcurrentDictionary.AddOrUpdate.
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

- **`synchronized`** es `lock`. Un método `synchronized` bloquea `this` (o la clase, en un método estático), algo que las guías de estilo de C# desaconsejan y que el código Java hace constantemente. Desde C# 13, el código .NET puede bloquear un [`System.Threading.Lock`](https://learn.microsoft.com/dotnet/api/system.threading.lock) dedicado; en Java, un campo `ReentrantLock` cumple ese papel y añade `tryLock` con un timeout.
- **`AtomicInteger`** es `Interlocked`, envuelto en un objeto. `LongAdder` escala mejor cuando muchos hilos incrementan a menudo el mismo contador.
- **Antes de Java 24, `synchronized` fijaba (pinning) los hilos virtuales**: un hilo virtual que se bloqueaba dentro de un bloque `synchronized` retenía su hilo portador, y las bibliotecas se pasaron a `ReentrantLock` para evitarlo. [JEP 491](https://openjdk.org/jeps/491) eliminó esa limitación en Java 24, así que el consejo de evitar `synchronized` con hilos virtuales está desfasado en Java 25.

Igual que C#, que rechaza `lock` sobre un tipo de valor ([CS0185](https://learn.microsoft.com/dotnet/csharp/misc/cs0185)), Java se niega a sincronizar sobre un primitivo:

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

Cambia `int` por `Integer` y compila, lo que es peor: `count++` sustituye el objeto con boxing, así que cada hilo puede bloquear un `Integer` distinto. javac solo advierte, y solo con `-Xlint`:

```text
SynchronizeOnInteger.java:5: warning: [identity] attempt to synchronize on an instance of a value-based class
        synchronized (count) {
        ^
1 warning
```

## `ThreadLocal`, `ScopedValue` y `AsyncLocal`

El código C# que necesita un contexto ambiental (el usuario actual, un ID de traza) usa `AsyncLocal<T>`, que fluye a través de los `await` hacia las tareas y los hilos nuevos. El `ThreadLocal` de Java no fluye a ninguna parte, y un hilo virtual por tarea es un hilo nuevo cada vez. [`ScopedValue`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/ScopedValue.html) ([JEP 506](https://openjdk.org/jeps/506), definitivo en Java 25) es el sustituto moderno: un valor ligado durante una llamada, inmutable dentro de ella y desligado de nuevo después:

```java
static final ThreadLocal<String> CURRENT_USER = new ThreadLocal<>();

// Un ScopedValue está ligado durante una llamada y después vuelve a quedar desligado.
static final ScopedValue<String> REQUEST_USER = ScopedValue.newInstance();

static String greet() {
    return "hello " + (REQUEST_USER.isBound() ? REQUEST_USER.get() : "nobody");
}

public static void main(String[] args) throws Exception {
    CURRENT_USER.set("ada");
    try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
        // Un ThreadLocal pertenece a un solo hilo: una tarea en otro hilo no lo ve.
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

    // Los scoped values tampoco llegan a un executor normal: eso requiere concurrencia estructurada (preview).
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

El lado C# imprime `AsyncLocal in Task.Run: grace` y `in a new thread: AsyncLocal grace, ThreadLocal null`. La última línea de Java es la carencia: un scoped value solo llega a los hilos hijos cuando los bifurca (fork) un `StructuredTaskScope`, y esa API sigue en preview.

## La concurrencia estructurada sigue en preview

La [concurrencia estructurada](https://openjdk.org/jeps/505) trata un grupo de subtareas como una unidad: si una falla, las demás se cancelan, y el ámbito no termina antes que todas ellas. Es lo más parecido a un `Task.WhenAll` que cancela a las tareas hermanas. En Java 25 está en su quinta preview, y usarla sin `--enable-preview` falla:

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

Como con los patrones primitivos de la lección 8, este curso no usa funcionalidades en preview. La API ha cambiado de una preview a otra: en Java 25 un ámbito se crea con los métodos de fábrica estáticos `open()` y un `Joiner` que fija la política de finalización, mientras que las previews anteriores usaban constructores y subclases como `ShutdownOnFailure`.

## Streams paralelos

La lección 7 prometía esta sección. `parallel()` sobre un stream es el `AsParallel()` de PLINQ: el stream se divide y se procesa en el `ForkJoinPool` común:

```java
// parallel() es AsParallel(); el resultado es el mismo que el secuencial.
long sequential = IntStream.rangeClosed(1, 2_000_000).filter(ParallelStreams::isPrime).count();
long parallel = IntStream.rangeClosed(1, 2_000_000).parallel().filter(ParallelStreams::isPrime).count();
System.out.println("primes up to 2,000,000: " + sequential + " sequential, " + parallel + " parallel");

// A diferencia de PLINQ sin AsOrdered(), recolectar conserva el orden de encuentro.
List<Integer> squares = IntStream.rangeClosed(1, 10).parallel().map(x -> x * x).boxed().toList();
System.out.println("squares: " + squares);

// forEach se ejecuta en el orden en que los hilos llegan a los elementos; forEachOrdered lo restablece.
var ordered = new StringBuilder();
IntStream.rangeClosed(1, 10).parallel().forEachOrdered(x -> ordered.append(x).append(' '));
System.out.println("forEachOrdered: " + ordered.toString().strip());

// reduce necesita una identidad verdadera: 0 para la suma. En secuencial, una identidad errónea se suma una vez.
int wrongIdentitySequential = IntStream.rangeClosed(1, 4).reduce(10, Integer::sum);
int rightIdentityParallel = IntStream.rangeClosed(1, 4).parallel().reduce(0, Integer::sum);
System.out.println("reduce(10) sequential: " + wrongIdentitySequential + ", reduce(0) parallel: " + rightIdentityParallel);

// Los streams paralelos se ejecutan en el ForkJoinPool común, compartido por toda la JVM.
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

- **El orden se conserva por defecto.** Un stream paralelo sobre un origen ordenado sigue recolectando en el orden de encuentro; PLINQ necesita `AsOrdered()`. El lado C# imprime `AsOrdered: 1, 4, 9, …`. Solo `forEach` renuncia al orden.
- **La identidad de `reduce` debe ser una identidad de verdad.** `reduce(10, Integer::sum)` suma 10 una vez en secuencial, pero un stream paralelo lo suma una vez por fragmento, así que el resultado depende de cuántos fragmentos cree la máquina. Por eso el ejemplo solo ejecuta la identidad errónea en secuencial.
- **El hilo que llama también trabaja.** El hilo que inicia la operación terminal participa, junto a los workers del pool común. El pool lo comparte toda la JVM, así que un stream paralelo lento ralentiza a todos los demás.

Los streams paralelos ayudan con trabajo grande, limitado por la CPU y sin estado, sobre orígenes que se dividen bien (arrays, rangos, `ArrayList`). No ayudan con la E/S bloqueante (usa hilos virtuales), con colecciones pequeñas (dividir cuesta más de lo que ahorra), ni con `LinkedList` y `Stream.iterate`, que no se dividen bien. Mide antes y después, con una JVM ya calentada: la lección 13 vuelve sobre los benchmarks.

## Puntos clave

- Los hilos virtuales abaratan el bloqueo, así que el código Java sigue siendo síncrono: sin `async`, sin `Task` en las firmas. Usa `Executors.newVirtualThreadPerTaskExecutor()` en un `try`-with-resources; `close()` espera a todas las tareas.
- Los hilos virtuales ayudan a esperar, no a calcular. No los metas en un pool.
- `CompletableFuture` es `Task`: `supplyAsync`, `thenApply`, `thenCombine`, `allOf`. Las excepciones siempre se envuelven, y `get()` lanza excepciones comprobadas mientras que `join()` no.
- La cancelación es interrupción. Vuelve a lanzar `InterruptedException` o restaura el indicador de interrupción. `CompletableFuture.cancel(true)` no interrumpe nada.
- `synchronized`, `ReentrantLock`, los atómicos y `ConcurrentHashMap` se corresponden con `lock`, `Interlocked` y `ConcurrentDictionary`. Desde Java 24, `synchronized` ya no fija los hilos virtuales.
- `ScopedValue` (definitivo en Java 25) sustituye a `ThreadLocal` para el contexto de una petición, pero solo la concurrencia estructurada, todavía en preview, lo pasa a los hilos hijos.
- Los streams paralelos conservan el orden de encuentro, se ejecutan en el pool común compartido y necesitan una identidad verdadera en `reduce`.

## Ejercicios

1. Escribe `fetchAll(List<T> inputs, Function<T, R> fetch)`, el equivalente Java de `await Task.WhenAll(inputs.Select(FetchAsync))`: ejecuta todas las llamadas de forma concurrente y devuelve los resultados en el orden de las entradas. Con un `fetch` que duerme 200 ms, 100 entradas deben completarse en bastante menos de 5 segundos.

<details>
<summary>Solución</summary>

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

`invokeAll` espera a todas las llamadas y devuelve sus futures en el orden de la lista, así que los resultados quedan alineados con las entradas. El testigo de tipo `<Callable<R>>` es necesario: sin él, la lambda interior no tiene tipo destino, y javac informa de «cannot infer type-variable(s) R … Object is not a functional interface». La prueba ejecuta 100 llamadas de 200 ms y comprueba el orden y el tiempo transcurrido. `fetch` es una `Function`, así que no puede lanzar excepciones comprobadas: una llamada HTTP real envolvería su `IOException`, como en el ejercicio 1 de la lección 5.

</details>

2. El código C# suele limitar las llamadas concurrentes con `SemaphoreSlim(3)` y `await semaphore.WaitAsync()`. Escribe `mapThrottled(inputs, maxConcurrency, work)`, que reutiliza `fetchAll` pero deja que como mucho `maxConcurrency` llamadas a `work` se ejecuten a la vez.

<details>
<summary>Solución</summary>

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

[`Semaphore`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/Semaphore.html) es `SemaphoreSlim` con un `acquire()` bloqueante, lo cual no es problema en un hilo virtual. Cada entrada sigue teniendo su propio hilo virtual, pero solo tres a la vez pasan de `acquire()`. La prueba registra el mayor número de llamadas ejecutándose a la vez y comprueba que nunca supera 3. El `finally` importa tanto como el `Release()` de C# en un `finally`: sin él, una excepción en `work` retendría un permiso para siempre.

</details>

3. Dos cuentas, dos tipos de tarea: una transfiere de `a` a `b` y la otra de `b` a `a`, y cada una bloquea las dos cuentas con `synchronized`. Escritas de forma ingenua, 10.000 tareas así pueden producir un interbloqueo (deadlock). Escribe un `transfer(from, to, amount)` que no pueda producir un interbloqueo, y comprueba que el saldo total se conserva.

<details>
<summary>Solución</summary>

```java
static final class Account {
    final int id;
    long balance;

    Account(int id, long balance) {
        this.id = id;
        this.balance = balance;
    }
}

// Bloquea primero la cuenta con el id más pequeño, para que dos transferencias opuestas no puedan esperarse mutuamente.
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

Un interbloqueo necesita un ciclo: una tarea retiene `a` y espera a `b` mientras otra retiene `b` y espera a `a`. Bloquear en un orden global (aquí por id) rompe el ciclo, en Java igual que con sentencias `lock` anidadas en C#. La prueba ejecuta 10.000 transferencias en direcciones alternas dentro de `assertTimeoutPreemptively`, de modo que un interbloqueo hace fallar la prueba en lugar de dejarla colgada, y después comprueba que los dos saldos siguen sumando 2.000.000. Un `ReentrantLock` con `tryLock(timeout)` es la otra respuesta clásica: retirarse y reintentar en lugar de esperar para siempre.

</details>

## Fuentes

- [Bibliotecas principales de Java — Hilos virtuales](https://docs.oracle.com/en/java/javase/25/core/virtual-threads.html)
- [JEP 444 — Virtual Threads](https://openjdk.org/jeps/444), [JEP 491 — Synchronize Virtual Threads without Pinning](https://openjdk.org/jeps/491), [JEP 505 — Structured Concurrency (Fifth Preview)](https://openjdk.org/jeps/505), [JEP 506 — Scoped Values](https://openjdk.org/jeps/506)
- [Resumen del paquete `java.util.concurrent`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/package-summary.html) y [`java.util.stream` — paralelismo](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/stream/package-summary.html)
- [JLS, capítulo 17 — Threads and Locks](https://docs.oracle.com/javase/specs/jls/se25/html/jls-17.html)
- C#: [programación asincrónica](https://learn.microsoft.com/dotnet/csharp/asynchronous-programming/), [cancelación en subprocesos administrados](https://learn.microsoft.com/dotnet/standard/threading/cancellation-in-managed-threads), [la instrucción `lock`](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/lock), [PLINQ](https://learn.microsoft.com/dotnet/standard/parallel-programming/introduction-to-plinq)
