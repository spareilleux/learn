---
title: "2. Reactor: Mono y Flux"
description: Mono y Flux comparados con Task, IAsyncEnumerable y Rx.NET — ensamblado frente a suscripción, los operadores que LINQ ya te enseñó, las señales y la demanda, y StepVerifier con tiempo virtual.
sidebar:
  order: 2
---

Ejemplo completo: [`code/spring-cloud-reactor/l02-reactor`](https://github.com/spareilleux/learn/tree/main/code/spring-cloud-reactor/l02-reactor), Java sencillo con [`reactor-core`](https://projectreactor.io/docs/core/release/reference/) y [`reactor-test`](https://projectreactor.io/docs/core/release/reference/testing.html), sin Spring. `ExamplesTest` ejecuta cada ejemplo y compara su salida con [`expected`](https://github.com/spareilleux/learn/tree/main/code/spring-cloud-reactor/l02-reactor/expected); el lado .NET es [`csharp/l02-task-vs-flux.cs`](https://github.com/spareilleux/learn/blob/main/code/spring-cloud-reactor/csharp/l02-task-vs-flux.cs).

## Dos tipos, cuatro interfaces

WebFlux, Spring Cloud Gateway, R2DBC y los clientes reactivos de las lecciones siguientes hablan todos [Project Reactor](https://projectreactor.io/docs/core/release/reference/). Sus dos tipos son todo el vocabulario:

- **`Mono<T>`** emite como mucho un valor y luego termina, o falla. Está donde C# devolvería un `Task<T>`.
- **`Flux<T>`** emite cualquier número de valores y luego termina, o falla. Está donde C# devolvería un `IAsyncEnumerable<T>` o un `IObservable<T>`.

Ambos implementan `Publisher<T>`, una de las cuatro interfaces de la [especificación Reactive Streams](https://github.com/reactive-streams/reactive-streams-jvm/blob/a625d3aba756e9842ad1291a5b73f5db280b6168/README.md): un `Publisher` acepta un `Subscriber`, le da una `Subscription` y solo le envía valores al ritmo que el suscriptor los pide a través de esa suscripción. El JDK incluye las mismas cuatro interfaces como [`java.util.concurrent.Flow`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/Flow.html). .NET no tiene un equivalente estándar; el pariente más cercano es [Rx.NET](https://github.com/dotnet/reactive), cuyo `IObservable<T>` empuja valores sin ningún mecanismo de petición.

| C# | Reactor | Notas |
|---|---|---|
| `Task<T>` | `Mono<T>` | un `Mono` no arranca hasta que alguien se suscribe; un `Task` normalmente ya ha arrancado |
| `Task` | `Mono<Void>` | termina sin valor |
| `IAsyncEnumerable<T>` | `Flux<T>` | ambos son perezosos; en los dos tira el suscriptor, por lotes con Reactor |
| `IObservable<T>` (Rx.NET) | `Flux<T>` | Rx empuja; Reactor solo empuja lo que se ha pedido |
| `await` | un operador a continuación, o `block()` en el borde | no hay `await` en Java: el pipeline es la continuación |
| operadores LINQ | `map`, `filter`, `flatMap`, … | más de 400 métodos públicos en `Flux`, sobrecargas incluidas, con diagramas de canicas en el [Javadoc](https://projectreactor.io/docs/core/release/api/reactor/core/publisher/Flux.html) |
| `null` | `Mono.empty()` | Reactor prohíbe los valores `null` |
| `FakeTimeProvider`, el `TestScheduler` de Rx | `StepVerifier.withVirtualTime` | las pruebas que abarcan minutos se ejecutan en milisegundos |

La [lección 9 del curso de Java](../../java-for-csharp/09-concurrency-and-virtual-threads/) comparó `Task` con `CompletableFuture`. La diferencia con `Mono` va primero.

## Ensamblado y suscripción

Construir un pipeline y ejecutarlo son dos momentos distintos. La documentación de Reactor llama al primero **ensamblado** (assembly) y al segundo **suscripción** (subscription):

```java
static Scale lookUp(String root, String mode) {
    System.out.println("  looking up " + root + " " + mode);
    return Scale.of(root, mode);
}

public static void main(String[] args) {
    // Ensamblado: esta línea construye una descripción del trabajo. Todavía no se ejecuta nada.
    Mono<Scale> dorian = Mono.fromCallable(() -> lookUp("D", "dorian"));
    System.out.println("assembled a Mono");

    // La suscripción arranca el trabajo, una vez por suscriptor: un Mono es frío.
    System.out.println("first subscriber:");
    dorian.subscribe(scale -> System.out.println("  got " + scale.notes()));
    System.out.println("second subscriber:");
    dorian.subscribe(scale -> System.out.println("  got " + scale.notes()));

    // Un CompletableFuture es caliente, como un Task: arranca al crearse y se ejecuta una sola vez.
    System.out.println("CompletableFuture:");
    CompletableFuture<Scale> future = CompletableFuture.supplyAsync(() -> lookUp("E", "phrygian"));
    future.join();
    System.out.println("  joined twice, same result: " + (future.join() == future.join()));

    // Mono.just recibe un valor, así que su argumento se calcula durante el ensamblado, haya suscriptor o no.
    System.out.println("Mono.just:");
    Mono<Scale> eager = Mono.just(lookUp("F", "lydian"));
    System.out.println("  assembled, no subscriber yet");

    // Mono.defer aplaza la construcción del propio Mono hasta que alguien se suscribe.
    System.out.println("Mono.defer:");
    Mono<Scale> deferred = Mono.defer(() -> Mono.just(lookUp("G", "mixolydian")));
    System.out.println("  assembled, no subscriber yet");
    deferred.subscribe();
    eager.subscribe();
}
```

```text
assembled a Mono
first subscriber:
  looking up D dorian
  got [D, E, F, G, A, B, C]
second subscriber:
  looking up D dorian
  got [D, E, F, G, A, B, C]
CompletableFuture:
  looking up E phrygian
  joined twice, same result: true
Mono.just:
  looking up F lydian
  assembled, no subscriber yet
Mono.defer:
  assembled, no subscriber yet
  looking up G mixolydian
```

De esta salida salen tres reglas:

- **Sin suscriptor no pasa nada.** Un método que devuelve un `Mono` solo ha descrito el trabajo. Olvidar suscribirse es la versión reactiva de llamar a un método `async` sin esperarlo, salvo que el trabajo ni siquiera empieza. En WebFlux, el framework se suscribe a lo que devuelve un controlador, así que el código de la aplicación rara vez llama a `subscribe` por sí mismo.
- **Cada suscriptor vuelve a ejecutar el pipeline.** La búsqueda se ejecutó dos veces para dos suscriptores. Un `Mono` es una receta, no un resultado; un `Task` o un `CompletableFuture` es un resultado, calculado una sola vez. Cuando varios suscriptores deben compartir una misma ejecución, `cache()` o `share()` vuelven caliente un pipeline.
- **`Mono.just` es impaciente.** Su argumento es una expresión Java normal, evaluada antes incluso de llamar a `just`: `F lydian` se buscó sin ningún suscriptor. `Mono.fromCallable`, `Mono.fromSupplier` y `Mono.defer` aplazan el trabajo hasta la suscripción. El único efecto de `eager.subscribe()`, la última línea, es entregar un valor calculado mucho antes.

El lado C# imprime las mismas tres situaciones para `Task`, `IAsyncEnumerable` y Rx.NET:

```text
Task:
  looking up E phrygian
  awaited twice, same result: True
IAsyncEnumerable:
  created, not enumerated
  looking up D dorian
  got D dorian
  looking up D dorian
  got D dorian
  LINQ: Cm Dm Am
Observable.Return:
  looking up F lydian
  created, no subscriber yet
Observable.Defer:
  created, no subscriber yet
  looking up G mixolydian
```

Un `IAsyncEnumerable` se comporta como un `Flux`: el iterador vuelve a ejecutarse en cada `await foreach`. `Observable.Return` y `Observable.Defer` tienen exactamente la trampa y la solución de `Mono.just` y `Mono.defer`, porque Rx.NET y Reactor vienen del mismo diseño. La línea `LINQ` usa los operadores que .NET 10 incluye para `IAsyncEnumerable` en el propio framework ([`System.Linq.AsyncEnumerable`](https://learn.microsoft.com/dotnet/api/system.linq.asyncenumerable)).

## Operadores

La mayoría de los operadores son LINQ con otro nombre, lo que hace que un pipeline sea fácil de leer y fácil de malinterpretar:

```java
Flux<Mode> modes = Flux.fromArray(Mode.values());

// map y filter son Select y Where.
List<String> minorModes = modes
        .filter(mode -> Scale.of("C", mode.label()).triads().getFirst().quality() == Chord.Quality.MINOR)
        .map(Mode::label)
        .collectList()
        .block();
System.out.println("modes with a minor tonic chord: " + minorModes);

// flatMapIterable es SelectMany sobre una colección; distinct y count se llaman igual que en LINQ.
Mono<Long> distinctChords = modes
        .flatMapIterable(mode -> Scale.of("C", mode.label()).triads())
        .map(Chord::symbol)
        .distinct()
        .count();
System.out.println("distinct triads in the seven modes on C: " + distinctChords.block());

// zip empareja dos secuencias elemento a elemento, como Enumerable.Zip.
Flux<String> degrees = Flux.just("I", "ii", "iii", "IV", "V", "vi", "vii°");
Flux<Chord> chords = Flux.fromIterable(Scale.of("G", "major").triads());
System.out.println(Flux.zip(degrees, chords, (degree, chord) -> degree + "=" + chord)
        .take(4)
        .collectList()
        .block());

// reduce es Aggregate; un Flux de Monos se fusiona con flatMap, como await Task.WhenAll.
Mono<String> progression = Flux.just("C", "A", "D", "G")
        .flatMap(root -> Mono.fromCallable(() -> Scale.of(root, "major").triads().getFirst().symbol()))
        .reduce((left, right) -> left + " " + right);
System.out.println("progression: " + progression.block());
```

```text
modes with a minor tonic chord: [dorian, phrygian, aeolian]
distinct triads in the seven modes on C: 25
[I=G, ii=Am, iii=Bm, IV=C]
progression: C A D G
```

| LINQ | Reactor |
|---|---|
| `Select` | `map` |
| `Where` | `filter` |
| `SelectMany` sobre colecciones | `flatMapIterable` |
| `SelectMany` sobre resultados asíncronos | `flatMap` (concurrente), `concatMap` (de uno en uno), `flatMapSequential` |
| `Aggregate` | `reduce` |
| `ToListAsync`, `ToDictionaryAsync` | `collectList`, `collectMap` |
| `Zip` | `zip`, `zipWith` |
| `Take`, `Skip` | `take`, `skip` |
| `Distinct`, `Count` | `distinct`, `count` |
| `Concat` | `concatWith`, `Flux.concat` |
| `DefaultIfEmpty` | `defaultIfEmpty`, `switchIfEmpty` |
| `Task.WhenAll` | `Mono.zip`, `Flux.merge`, `flatMap` |

`collectList` y `count` convierten un `Flux` en un `Mono`, como los métodos LINQ que terminan en `Async` y devuelven un `Task`. `block()` espera después ese `Mono`, como `.GetAwaiter().GetResult()`. Está bien en `main` y en las pruebas; la lección 3 muestra dónde lo rechaza Reactor.

### `flatMap` no conserva el orden

`flatMap` se suscribe a los publishers internos de forma concurrente y reenvía sus valores a medida que llegan. El `Mono.fromCallable` síncrono de arriba terminaba de inmediato, así que el orden parecía conservado. Con publishers internos que tardan, no lo está. Esta prueba usa un servicio de acordes de tónica cuya respuesta tarda 300 ms para C y 100 ms para los demás:

```java
// Un servicio de acordes que responde despacio para algunas tónicas; las duraciones son virtuales.
static Mono<String> slowTonic(String root, long millis) {
    return Mono.delay(Duration.ofMillis(millis)).map(tick -> Scale.of(root, "major").triads().getFirst().symbol());
}

@Test
void flatMapEmitsInCompletionOrder() {
    // Sin tiempo virtual, esta prueba esperaría 300 ms de tiempo real.
    StepVerifier.withVirtualTime(() -> Flux.just("C", "F", "G")
                    .flatMap(root -> slowTonic(root, root.equals("C") ? 300 : 100)))
            .thenAwait(Duration.ofMillis(300))
            .expectNext("F", "G", "C")
            .verifyComplete();
}

@Test
void concatMapKeepsTheSourceOrder() {
    StepVerifier.withVirtualTime(() -> Flux.just("C", "F", "G")
                    .concatMap(root -> slowTonic(root, root.equals("C") ? 300 : 100)))
            .expectSubscription()
            .expectNoEvent(Duration.ofMillis(300))
            .expectNext("C")
            .thenAwait(Duration.ofMillis(200))
            .expectNext("F", "G")
            .verifyComplete();
}
```

`flatMap` emitió F, G y luego C, en orden de finalización: es `Task.WhenAny` en un bucle, no `Task.WhenAll`, cuyos resultados conservan el orden de las tareas. `concatMap` espera a cada publisher interno antes de suscribirse al siguiente, así que conserva el orden y tarda 500 ms. `flatMapSequential` es la tercera opción: suscripciones concurrentes y resultados reordenados según la fuente.

## Señales

Un `Subscriber` recibe cuatro tipos de señal: `onSubscribe` una vez, `onNext` por cada valor, y después `onComplete` u `onError`, nunca ambas. `log()` imprime cada señal que pasa por su posición en el pipeline:

```java
// log() imprime cada señal que pasa por este punto del pipeline.
Flux.just("C", "E", "G")
        .map(String::toLowerCase)
        .log("triad")
        .take(2)
        .subscribe(note -> System.out.println("subscriber got " + note));
```

```text
[ INFO] (main) | onSubscribe([Fuseable] FluxMapFuseable.MapFuseableSubscriber)
[ INFO] (main) | request(2)
[ INFO] (main) | onNext(c)
subscriber got c
[ INFO] (main) | onNext(e)
subscriber got e
[ INFO] (main) | cancel()
```

Sin SLF4J en el class path, Reactor escribe en la consola, y el nombre de categoría `triad` no aparece. La salida muestra lo que `IAsyncEnumerable` nunca deja ver:

- **La demanda sube.** El suscriptor lo pidió todo, pero `take(2)` solo pasó `request(2)` hacia arriba. Cada operador puede cambiar la demanda; la lección 3 trata de lo que ocurre cuando una fuente produce más deprisa que eso.
- **La cancelación también sube.** En cuanto `take` tiene sus dos valores, envía `cancel()` a la fuente, el equivalente de salir de un bucle `await foreach`, que libera el enumerador. No se pasa ningún `CancellationToken` por ninguna parte.
- **Todo se ejecutó en `main`.** Reactor no cambia de hilo salvo que lo haga un operador o un scheduler, algo que también cubre la lección 3.

Los errores y los resultados vacíos también son señales:

```java
// Los errores también son señales: la secuencia se detiene en el primero.
Flux.just("C", "H", "D")
        .map(root -> Scale.of(root, "major").root())
        .subscribe(
                root -> System.out.println("onNext " + root),
                error -> System.out.println("onError " + error.getMessage()),
                () -> System.out.println("onComplete"));

// null no es un valor en Reactor: un mapper que devuelve null hace fallar la secuencia.
Mono.just("C")
        .map(root -> (String) null)
        .subscribe(
                value -> System.out.println("onNext " + value),
                // El mensaje nombra la clase generada de la lambda, cuya dirección cambia de una ejecución a otra.
                error -> System.out.println("onError " + error.getClass().getSimpleName() + ": "
                        + error.getMessage().replaceAll("/0x[0-9a-f]+", "/0x...")));

// El vacío es la forma en que Reactor dice "ningún valor": defaultIfEmpty y switchIfEmpty lo gestionan.
Mono<String> favourite = Mono.justOrEmpty(System.getenv("NO_SUCH_VARIABLE_FOR_THE_LESSON"));
System.out.println("empty Mono blocks to: " + favourite.block());
System.out.println("defaultIfEmpty: " + favourite.defaultIfEmpty("ionian").block());
```

```text
onNext C
onError unknown note: H
onError NullPointerException: The mapper [dev.learn.reactor.l02.Operators$$Lambda/0x...] returned a null value.
empty Mono blocks to: null
defaultIfEmpty: ionian
```

- **Un error termina la secuencia.** `D` nunca se procesó y `onComplete` nunca se imprimió. La excepción lanzada dentro de `map` se convirtió en una señal `onError` en lugar de propagarse por la pila de llamadas; la lección 3 muestra cómo recuperarse de ella.
- **`null` se rechaza.** La [especificación Reactive Streams](https://github.com/reactive-streams/reactive-streams-jvm/blob/a625d3aba756e9842ad1291a5b73f5db280b6168/README.md#2.13) prohíbe los elementos `null`, así que un mapper que devuelve `null` falla. `Mono.justOrEmpty` convierte un valor posiblemente nulo en un `Mono` vacío, igual que `?.` y `??` gestionan `null` en C#.
- **`block()` sobre un `Mono` vacío devuelve `null`.** Es el único lugar en que Reactor devuelve `null`, en el borde entre el código reactivo y el código normal.
- **Un `subscribe` sin manejador de errores** tampoco lanza nada. En una prueba puntual con el mismo `map` y solo un consumidor de valores, Reactor registró `[ERROR] (main) Operator called default onErrorDropped - reactor.core.Exceptions$ErrorCallbackNotImplemented: java.lang.IllegalStateException: boom` con su traza de pila, y `main` siguió adelante. Pasa siempre un consumidor de errores, o deja que un framework se suscriba por ti.

## Probar con `StepVerifier`

`block()` en una prueba sirve para un único valor, pero no dice nada del orden, del número de valores ni de cómo termina una secuencia. [`StepVerifier`](https://projectreactor.io/docs/core/release/reference/testing.html), en `reactor-test`, se suscribe y comprueba cada señal por turno:

```java
static Flux<String> triads(String root, String mode) {
    return Flux.defer(() -> Flux.fromIterable(Scale.of(root, mode).triads())).map(Chord::symbol);
}

@Test
void expectEachSignalInOrder() {
    StepVerifier.create(triads("A", "minor"))
            .expectNext("Am", "Bdim", "C")
            .expectNextCount(3)
            .expectNext("G")
            .verifyComplete();
}

@Test
void errorsAreSignalsToExpect() {
    StepVerifier.create(triads("H", "minor"))
            .expectErrorMessage("unknown note: H")
            .verify();
}
```

No se comprueba nada hasta que se ejecuta `verify()`, `verifyComplete()` u otro método `verify…`: sin él, la prueba construye un escenario y pasa sin suscribirse. Cuando falla una expectativa, el mensaje nombra el paso:

```java
StepVerifier.create(triads("D", "dorian"))
        .expectNext("Dm", "Em", "F#")
        .verifyComplete();
```

```text
expectation "expectNext(F#)" failed (expected value: F#; actual value: F)
```

El **tiempo virtual** reemplaza el reloj de Reactor mientras dura una prueba. `withVirtualTime` recibe un supplier, no un `Flux`, para que los operadores como `Mono.delay` se creen después de instalar el reloj virtual; `thenAwait` lo hace avanzar, y `expectNoEvent` comprueba que no ocurrió nada durante un periodo. Las pruebas de `flatMap` de arriba cubren 500 ms de tiempo virtual en unos pocos milisegundos. Las pruebas .NET consiguen lo mismo con [`FakeTimeProvider`](https://learn.microsoft.com/dotnet/api/microsoft.extensions.time.testing.faketimeprovider) para el código que recibe un `TimeProvider`, o con el `TestScheduler` de Rx.NET.

## Puntos clave

- `Mono` es cero o un valor, `Flux` es de cero a muchos; ambos son publishers de Reactive Streams, más cercanos al `IObservable` de Rx.NET que a `Task`.
- El ensamblado construye una descripción; la suscripción la ejecuta, una vez por suscriptor. Sin suscriptor no pasa nada, y `Mono.just(expensive())` ejecuta `expensive()` de todas formas: usa `fromCallable` o `defer`.
- Los operadores son LINQ con otros nombres. `flatMap` es concurrente y emite en orden de finalización; `concatMap` y `flatMapSequential` conservan el orden de la fuente.
- Las señales son `onSubscribe`, `onNext`, `onComplete` y `onError`. La demanda (`request`) y la cancelación suben hacia la fuente; los valores, los errores y la finalización bajan. `log()` las muestra todas.
- Los errores terminan una secuencia, `null` está prohibido y el vacío es una señal por derecho propio.
- Prueba con `StepVerifier` y termina siempre con un método `verify`; usa tiempo virtual para todo lo que tenga un retardo.

## Ejercicios

1. Este método compila y devuelve un `Flux`. Explica por qué la llamada `eagerTriads("H", "major")` lanza una excepción, cuando quien llama a una API reactiva espera en su lugar una señal `onError`, y luego corrígelo.

```java
static Flux<String> eagerTriads(String root, String mode) {
    return Flux.fromIterable(Scale.of(root, mode).triads()).map(Chord::symbol);
}
```

<details>
<summary>Solución</summary>

```java
static Flux<String> lazyTriads(String root, String mode) {
    return Flux.defer(() -> Flux.fromIterable(Scale.of(root, mode).triads())).map(Chord::symbol);
}

@Test
void exercise1WhereTheErrorHappens() {
    var thrown = assertThrows(IllegalArgumentException.class, () -> eagerTriads("H", "major"));
    assertEquals("unknown note: H", thrown.getMessage());

    Flux<String> assembled = lazyTriads("H", "major");
    StepVerifier.create(assembled).expectErrorMessage("unknown note: H").verify();
}
```

`Scale.of(root, mode)` es un argumento de `fromIterable`, así que Java lo evalúa durante el ensamblado, en el marco de pila de quien llama: la misma trampa que `Mono.just`. `Flux.defer` lo traslada a la suscripción, donde la excepción se convierte en una señal `onError`. El equivalente en C# es un método `async` que valida sus argumentos: la excepción se guarda en el `Task` devuelto, no la lanza la llamada, salvo que la validación esté en un envoltorio que no sea `async`.

</details>

2. Porta esta consulta C# a Reactor, devolviendo un `Mono<List<String>>`: de las tonalidades C, G, D, A, E y B, en ese orden, quédate con las tres primeras cuya escala mayor contenga F#.

```csharp
var keys = await new[] { "C", "G", "D", "A", "E", "B" }.ToAsyncEnumerable()
    .Where(root => MajorScale(root).Contains("F#"))
    .Take(3)
    .ToListAsync();
```

<details>
<summary>Solución</summary>

```java
static Mono<List<String>> keysWithFSharp() {
    Note fSharp = Note.parse("F#");
    return Flux.just("C", "G", "D", "A", "E", "B")
            .filter(root -> Scale.of(root, "major").notes().contains(fSharp))
            .take(3)
            .collectList();
}
```

La prueba espera `[G, D, A]`. `take(3)` cancela la fuente tras la tercera coincidencia, así que E y B nunca se comprueban, igual que el `Take` de LINQ detiene la enumeración. El record `Note` se compara por valor, así que `contains` funciona con una nota recién parseada.

</details>

3. Escribe un metrónomo: un `Flux<String>` que toque una progresión de cuatro acordes, un acorde cada 500 ms, dos veces, y luego termine. Pruébalo sin esperar cuatro segundos.

<details>
<summary>Solución</summary>

```java
static Flux<String> metronome(List<String> progression) {
    return Flux.interval(Duration.ofMillis(500))
            .map(beat -> progression.get((int) (beat % progression.size())))
            .take(progression.size() * 2L);
}

@Test
void exercise3MetronomeInVirtualTime() {
    Duration took = StepVerifier.withVirtualTime(() -> metronome(List.of("C", "Am", "F", "G")))
            .expectSubscription()
            .expectNoEvent(Duration.ofMillis(500))
            .expectNext("C")
            .thenAwait(Duration.ofMillis(1500))
            .expectNext("Am", "F", "G")
            .thenAwait(Duration.ofSeconds(2))
            .expectNext("C", "Am", "F", "G")
            .verifyComplete();
    assertTrue(took.compareTo(Duration.ofSeconds(1)) < 0, "four virtual seconds took " + took);
}
```

`Flux.interval` emite 0, 1, 2… con un temporizador y nunca termina; `take` lo detiene. `expectSubscription()` va antes de `expectNoEvent`, porque la propia suscripción es un evento. Los métodos `verify` devuelven el tiempo real que tardaron, lo que la prueba usa para demostrar que no hubo ninguna espera real.

</details>

## Fuentes

- [Guía de referencia de Reactor 3](https://projectreactor.io/docs/core/release/reference/): [introducción a la programación reactiva](https://projectreactor.io/docs/core/release/reference/reactiveProgramming.html), [funcionalidades principales](https://projectreactor.io/docs/core/release/reference/coreFeatures.html), [pruebas](https://projectreactor.io/docs/core/release/reference/testing.html), [¿qué operador necesito?](https://projectreactor.io/docs/core/release/reference/apdx-operatorChoice.html)
- Javadoc de [`Flux`](https://projectreactor.io/docs/core/release/api/reactor/core/publisher/Flux.html) y de [`Mono`](https://projectreactor.io/docs/core/release/api/reactor/core/publisher/Mono.html)
- [Especificación Reactive Streams](https://github.com/reactive-streams/reactive-streams-jvm/blob/a625d3aba756e9842ad1291a5b73f5db280b6168/README.md), [`java.util.concurrent.Flow`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/Flow.html)
- .NET: [flujos asíncronos](https://learn.microsoft.com/dotnet/csharp/asynchronous-programming/generate-consume-asynchronous-stream), [`System.Linq.AsyncEnumerable`](https://learn.microsoft.com/dotnet/api/system.linq.asyncenumerable), [Reactive Extensions para .NET](https://github.com/dotnet/reactive), [`FakeTimeProvider`](https://learn.microsoft.com/dotnet/api/microsoft.extensions.time.testing.faketimeprovider)
