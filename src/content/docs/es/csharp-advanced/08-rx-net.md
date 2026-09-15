---
title: "Lección 8: Rx.NET"
description: Reactive Extensions para .NET 7.0 medido con un programa — IObservable e IObserver, fuentes frías y calientes, operadores probados en tiempo virtual sobre notas que forman acordes, schedulers, el backpressure que Rx no tiene, pasos asíncronos y su orden, errores y reintentos — con el error de recuento de la demo reactiva de Guitar Alchemist, y el operador de Reactor para cada operador de Rx.
sidebar:
  label: 8. Rx.NET
  order: 8
---

Los canales y Dataflow mueven elementos que alguien *produce*; Rx es para elementos que *ocurren*. Una tecla pulsada, una nota MIDI tocada, la lectura de un sensor, un mensaje que envía un servidor: la fuente no espera a que se lo pidan, y las preguntas interesantes tienen que ver con el tiempo. ¿Qué notas se tocaron juntas? ¿Cuál fue el último valor antes de que el usuario dejara de mover el deslizador? [Reactive Extensions para .NET](https://github.com/dotnet/reactive) (Rx.NET) las responde con operadores LINQ sobre [`IObservable<T>`](https://learn.microsoft.com/dotnet/api/system.iobservable-1), y con una abstracción de scheduler que permite a una prueba recorrer minutos de eventos en un instante.

Rx es también el antepasado de Reactor. El [curso de Spring Boot, Spring Cloud y Reactor](../../spring-cloud-reactor/02-reactor-mono-and-flux/) presenta `Flux` comparándolo con `IObservable`, y la tabla del final de esta lección va en sentido contrario. La diferencia que más importa es el backpressure: Reactor lo tiene, Rx no, y esta lección mide lo que eso significa.

Los enlaces a GA apuntan al commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6). Los enlaces a Rx apuntan a la etiqueta [`rxnet-v7.0.0`](https://github.com/dotnet/reactive/tree/rxnet-v7.0.0) de `dotnet/reactive`.

## Ejecutar el programa de la lección

```bash
bash code/csharp-advanced/check.sh                                   # todas las lecciones, comparadas con expected/
dotnet run --project code/csharp-advanced/Advanced -c Release -- l8  # solo esta lección, después de check.sh
```

El código está en [`Advanced/Lesson8.cs`](https://github.com/spareilleux/learn/blob/b4d713f86711b770a75d7504f334c5871c95f820/code/csharp-advanced/Advanced/Lesson8.cs), y su salida se compara con [`expected/l8.txt`](https://github.com/spareilleux/learn/blob/b4d713f86711b770a75d7504f334c5871c95f820/code/csharp-advanced/expected/l8.txt). El programa hace referencia a los paquetes [`System.Reactive`](https://www.nuget.org/packages/System.Reactive) y [`Microsoft.Reactive.Testing`](https://www.nuget.org/packages/Microsoft.Reactive.Testing), versión 7.0.0, publicados en julio de 2026.

```text
== Where the types come from
IObservable<T>: System.Private.CoreLib; Observable: System.Reactive 7.0.0.0
```

Las dos interfaces, `IObservable<T>` e [`IObserver<T>`](https://learn.microsoft.com/dotnet/api/system.iobserver-1), forman parte de la biblioteca base desde .NET Framework 4. Todo lo demás, los operadores, los subjects y los schedulers, viene del paquete. Un observador tiene tres métodos, `OnNext`, `OnError` y `OnCompleted`, y el contrato es el que Reactor llama señales: cualquier número de llamadas a `OnNext`, luego como mucho un `OnError` o un `OnCompleted`, nunca a la vez.

## Frío y caliente

Un `IObservable` construido con [`Observable.Create`](https://github.com/dotnet/reactive/blob/rxnet-v7.0.0/Rx.NET/Source/src/System.Reactive/Linq/Observable.Creation.cs#L27) ejecuta su función una vez por cada suscriptor. Es un observable *frío*, como un `Mono` o un `Flux` construido a partir de un proveedor:

```text
== Cold: each subscriber runs the source
source ran 2 times; first got Dm7 G7 Cmaj7 A7, second got Dm7 G7 Cmaj7 A7
```

Un [`Subject<T>`](https://github.com/dotnet/reactive/blob/rxnet-v7.0.0/Rx.NET/Source/src/System.Reactive/Subjects/Subject.cs) es a la vez observador y observable: lo que le envías va a los observadores suscritos *en ese momento*. Es una fuente *caliente*, como un ratón o un dispositivo MIDI:

```text
== Hot: a Subject pushes to whoever is subscribed now
subscribed before G7: G7 Cmaj7; subscribed before Cmaj7: Cmaj7; Dm7 went to nobody
ReplaySubject(2), subscribed after four chords: Cmaj7 A7
Publish() and Connect(): source ran 1 time; both got Dm7 G7 Cmaj7 A7 / Dm7 G7 Cmaj7 A7
```

- Nadie oyó `Dm7`, enviado antes de que nadie se suscribiera; el suscriptor tardío se perdió también `G7`.
- Un `ReplaySubject` guarda los últimos valores para los suscriptores que llegan después: con un búfer de dos, un nuevo suscriptor recibe `Cmaj7` y `A7` en seguida.
- `Publish()` convierte un observable frío en uno caliente que comparte una sola suscripción a su fuente: los suscriptores esperan, `Connect()` inicia la fuente una vez, y ambos reciben todos los acordes.

Cuál de los dos tienes decide si suscribirse dos veces ejecuta el trabajo dos veces, o si un suscriptor lento se pierde eventos. El ejercicio 1 comparte una fuente con `RefCount` en lugar de `Connect`.

## Operadores en tiempo virtual

Los operadores de Rx que tienen que ver con el tiempo reciben un [`IScheduler`](https://github.com/dotnet/reactive/blob/rxnet-v7.0.0/Rx.NET/Source/src/System.Reactive/Concurrency/IScheduler.cs), y el `TestScheduler` de `Microsoft.Reactive.Testing` es un scheduler cuyo reloj solo avanza cuando la prueba lo indica. El programa le da notas tocadas en un teclado: do, mi y sol en 25 ms, re, fa y la medio segundo después, y luego si sola. Las notas que se suceden con menos de 50 ms de separación forman un acorde:

```csharp
static void VirtualTime()
{
    Title("Virtual time: notes played within 50 ms of each other form a chord");
    var scheduler = new TestScheduler();
    var notes = scheduler.CreateHotObservable(
        ReactiveTest.OnNext(Ms(0), "C"), ReactiveTest.OnNext(Ms(12), "E"), ReactiveTest.OnNext(Ms(25), "G"),
        ReactiveTest.OnNext(Ms(510), "D"), ReactiveTest.OnNext(Ms(540), "F"), ReactiveTest.OnNext(Ms(570), "A"),
        ReactiveTest.OnNext(Ms(1010), "B"),
        ReactiveTest.OnCompleted<string>(Ms(1200)));

    var chords = notes
        .Buffer(notes.Throttle(TimeSpan.FromMilliseconds(50), scheduler))
        .Where(chord => chord.Count > 0);
    var observer = scheduler.CreateObserver<IList<string>>();
    chords.Subscribe(observer);
    scheduler.Start();
    foreach (var message in observer.Messages)
    {
        var value = message.Value;
        Line($"t = {TimeSpan.FromTicks(message.Time).TotalMilliseconds,4} ms  {value.Kind}{(value.Kind == NotificationKind.OnNext ? " " + string.Join(" ", value.Value) : "")}");
    }

    Title("The same notes: Sample(100 ms) and Buffer(100 ms)");
    foreach (var (name, pipeline) in new (string, Func<IObservable<string>, IScheduler, IObservable<string>>)[]
    {
        ("Sample(100 ms)", (source, s) => source.Sample(TimeSpan.FromMilliseconds(100), s)),
        ("Buffer(100 ms)", (source, s) => source.Buffer(TimeSpan.FromMilliseconds(100), s).Select(buffer => $"[{string.Join(" ", buffer)}]")),
    })
    {
        var testScheduler = new TestScheduler();
        var source = testScheduler.CreateHotObservable(
            ReactiveTest.OnNext(Ms(0), "C"), ReactiveTest.OnNext(Ms(12), "E"), ReactiveTest.OnNext(Ms(25), "G"),
            ReactiveTest.OnNext(Ms(510), "D"), ReactiveTest.OnNext(Ms(540), "F"), ReactiveTest.OnNext(Ms(570), "A"),
            ReactiveTest.OnNext(Ms(1010), "B"),
            ReactiveTest.OnCompleted<string>(Ms(1200)));
        var results = testScheduler.CreateObserver<string>();
        pipeline(source, testScheduler).Subscribe(results);
        testScheduler.Start();
        var shown = results.Messages
            .Where(m => m.Value.Kind == NotificationKind.OnNext && m.Value.Value != "[]")
            .Select(m => $"{TimeSpan.FromTicks(m.Time).TotalMilliseconds}:{m.Value.Value}");
        Line($"{name}: {string.Join("  ", shown)}");
    }
}
```

```text
== Virtual time: notes played within 50 ms of each other form a chord
t =   75 ms  OnNext C E G
t =  620 ms  OnNext D F A
t = 1060 ms  OnNext B
t = 1200 ms  OnCompleted
```

El pipeline se lee así: almacena las notas en un búfer, y cierra el búfer cada vez que el flujo lleva 50 ms en silencio. [`Throttle`](https://github.com/dotnet/reactive/blob/rxnet-v7.0.0/Rx.NET/Source/src/System.Reactive/Linq/Observable.Time.cs#L1455-L1476) emite una nota solo cuando ninguna otra la sigue en 50 ms, así que se dispara a los 75 ms (25 + 50), a los 620 ms (570 + 50) y a los 1.060 ms. `Buffer` cierra un grupo cada vez. La prueba entera recorre 1,2 segundos de eventos en unos pocos microsegundos, y da la misma respuesta en todas las máquinas.

Una advertencia para quien conozca RxJS o Reactor: el `Throttle` de Rx.NET es lo que esas bibliotecas llaman *debounce*. Espera el silencio. El operador que deja pasar un valor por periodo es `Sample`, y `Buffer` con un `TimeSpan` corta ventanas fijas sin fijarse en las notas:

```text
== The same notes: Sample(100 ms) and Buffer(100 ms)
Sample(100 ms): 100:G  600:A  1100:B
Buffer(100 ms): 100:[C E G]  600:[D F A]  1100:[B]
```

`Sample` conservó solo la última nota de cada ventana de 100 ms que vio alguna, y las ventanas fijas coinciden con los acordes solo porque las notas se tocaron bien separadas.

## Schedulers: dónde se ejecuta el observador

Rx no inicia subprocesos por sí solo. Un observador se ejecuta en el subproceso que llama a `OnNext`, salvo que un operador lo mueva:

```text
== Schedulers: Rx runs the observer on the thread that calls OnNext, unless told otherwise
Subject.OnNext: observer ran on the caller's thread True, before OnNext returned True
ObserveOn(rx-loop): observer on rx-loop
SubscribeOn(rx-loop): the source ran on rx-loop
Observable.Timer(1 ms): observer on a pool thread True
```

- **Sin scheduler**: `Subject.OnNext` llama directamente al observador, en el subproceso del llamador, y solo retorna cuando el observador ha retornado.
- [`ObserveOn`](https://github.com/dotnet/reactive/blob/rxnet-v7.0.0/Rx.NET/Source/src/System.Reactive/Linq/Observable.Concurrency.cs#L14-L26) mueve las notificaciones que pasan por él a un scheduler, aquí un `EventLoopScheduler`, que posee un subproceso llamado `rx-loop`. Es el `publishOn` de Reactor.
- [`SubscribeOn`](https://github.com/dotnet/reactive/blob/rxnet-v7.0.0/Rx.NET/Source/src/System.Reactive/Linq/Observable.Concurrency.cs#L85) mueve la *suscripción*, así que una fuente síncrona como este `Observable.Create` se ejecuta en `rx-loop`. Es el `subscribeOn` de Reactor.
- Los operadores basados en el tiempo como `Observable.Timer` planifican en el grupo de subprocesos de forma predeterminada, así que el código que viene después ya no se ejecuta en el subproceso del llamador: la misma sorpresa que el `delayElements` de Reactor, descrita en el [curso de Reactor](../../spring-cloud-reactor/03-reactor-under-the-hood/).

El programa también hace `await` sobre observables: Rx hace que `IObservable<T>` sea [esperable](https://github.com/dotnet/reactive/blob/rxnet-v7.0.0/Rx.NET/Source/src/System.Reactive/Linq/Observable.Awaiter.cs#L12-L20), y `await` devuelve el último valor cuando la secuencia termina, lanza su error, o lanza una excepción si la secuencia estaba vacía.

## Sin backpressure

Un suscriptor de Reactor le dice a su publicador cuántos elementos puede aceptar. Un observador de Rx no tiene forma de decir nada: `OnNext` devuelve `void`. De ahí salen dos casos. Sin scheduler, el productor llama directamente al observador:

```text
== No backpressure: without a scheduler, OnNext waits for the observer
1,000 OnNext: the observer ran inside each call True, processed 1000
```

El observador se ejecutó dentro de cada llamada a `OnNext`, así que un observador lento sí frena al productor, ocupando su subproceso. Es backpressure solo por accidente, y se acaba en cuanto un operador pone una cola entre ambos. `ObserveOn` es uno de esos operadores:

```csharp
static async Task NoBackpressure()
{
    Title("No backpressure: without a scheduler, OnNext waits for the observer");
    var subject = new Subject<int>();
    var processed = 0;
    var insideEachCall = true;
    var pushed = 0;
    subject.Subscribe(_ =>
    {
        insideEachCall &= processed == pushed;
        processed++;
    });
    for (; pushed < 1000; pushed++)
    {
        subject.OnNext(pushed);
    }

    Line($"1,000 OnNext: the observer ran inside each call {insideEachCall}, processed {processed}");

    Title("No backpressure: behind ObserveOn, OnNext returns at once and the queue grows");
    using var loop = new EventLoopScheduler(start => new Thread(start) { Name = "rx-slow", IsBackground = true });
    var gate = new ManualResetEventSlim();
    var done = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
    var slowProcessed = 0;
    var queued = new Subject<byte[]>();
    using var subscription = queued.ObserveOn(loop).Subscribe(_ =>
    {
        gate.Wait();
        slowProcessed++;
    }, () => done.SetResult());

    var before = GC.GetTotalMemory(forceFullCollection: true);
    for (var i = 0; i < 10_000; i++)
    {
        queued.OnNext(new byte[1024]);
    }

    queued.OnCompleted();
    var after = GC.GetTotalMemory(forceFullCollection: true);
    Line($"10,000 OnNext of 1 KB returned while the observer held the first: processed {slowProcessed}, more than 10 MB still reachable {after - before > 10_000_000}");
    Machine($"memory reachable after pushing: {(after - before) / 1_000_000.0:F1} MB more");
    gate.Set();
    await done.Task;
    Line($"after releasing the observer: processed {slowProcessed}");
}
```

```text
== No backpressure: behind ObserveOn, OnNext returns at once and the queue grows
10,000 OnNext of 1 KB returned while the observer held the first: processed 0, more than 10 MB still reachable True
after releasing the observer: processed 10000
```

El productor envió 10.000 arrays de 1 KB mientras el observador seguía atascado en el primero. Cada `OnNext` retornó de inmediato, y más de 10 MB se acumularon en la cola que `ObserveOn` mantiene para el bucle de eventos: 10,7 MB en la máquina del autor, en la línea `# ` del programa. Nada limita esa cola. La respuesta de Rx es reducir el flujo antes de que llegue a un observador lento, con `Sample`, `Throttle`, `Buffer` o `Window`, o salir de Rx hacia un canal acotado, que es lo que hace la lección 9.

## Pasos asíncronos y su orden

Para llamar a un método asíncrono por cada elemento, Rx ofrece dos formas, y se comportan de manera muy distinta. El programa ejecuta dos lotes, donde el lote 0 espera hasta 200 ms a que empiece el lote 1:

```csharp
static async Task AsyncSteps()
{
    Title("An asynchronous step: SelectMany runs batches concurrently, Concat one at a time");
    foreach (var name in new[] { "SelectMany", "Select + Concat" })
    {
        var secondStarted = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
        var overlapped = false;

        async Task<string> Process(int batch)
        {
            if (batch == 0)
            {
                // El lote 0 espera hasta 200 ms a que empiece el lote 1
                overlapped = await Task.WhenAny(secondStarted.Task, Task.Delay(200)) == secondStarted.Task;
            }
            else
            {
                secondStarted.TrySetResult();
            }

            return $"batch {batch}";
        }

        var batches = Observable.Range(0, 2);
        var pipeline = name == "SelectMany"
            ? batches.SelectMany(Process)
            : batches.Select(batch => Observable.FromAsync(() => Process(batch))).Concat();
        var results = await pipeline.ToList();
        Line($"{name,-16} batch 1 started while batch 0 ran: {overlapped,-5}  results: {string.Join(", ", results)}");
    }
}
```

```text
== An asynchronous step: SelectMany runs batches concurrently, Concat one at a time
SelectMany       batch 1 started while batch 0 ran: True   results: batch 1, batch 0
Select + Concat  batch 1 started while batch 0 ran: False  results: batch 0, batch 1
```

- `SelectMany` con una función que devuelve un `Task` se suscribe a cada tarea en cuanto llega su elemento: el lote 1 empezó mientras el lote 0 se ejecutaba, terminó primero, y salió primero. Es el `flatMap` de Reactor, en orden de finalización.
- `Select` hacia `Observable.FromAsync`, y luego `Concat`, inicia cada tarea solo cuando la anterior ha terminado: el lote 0 esperó sus 200 ms solo, y los resultados conservaron su orden. Es el `concatMap` de Reactor.
- `Merge(n)`, en el ejercicio 3, queda en medio: como mucho `n` tareas a la vez, en orden de finalización.

## Caso de estudio: la demo reactiva de GA

La parte Rx de [`PerformanceOptimizationDemo`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Demos/Performance/PerformanceOptimizationDemo/Program.cs#L171-L222) de GA envía 1.000 eventos musicales a un `Subject`, los agrupa cada 100 ms, procesa cada lote de forma asíncrona y cuenta lo que sale:

```csharp
var subscription = subject
    .Buffer(TimeSpan.FromMilliseconds(100)) // Agrupar los eventos cada 100 ms
    .Where(batch => batch.Count > 0)
    .SelectMany(batch => ProcessBatchAsync(batch))
    .Subscribe(
        _ =>
        {
            Interlocked.Increment(ref processedCount);
            if (processedCount % 100 == 0)
            {
                logger.LogInformation("Processed {Count} musical events", processedCount);
            }
        },
        error => logger.LogError(error, "Error in reactive pipeline"),
        () => logger.LogInformation("Reactive pipeline completed"));
```

`ProcessBatchAsync` devuelve un `Task<IEnumerable<ProcessedEvent>>`: una tarea por lote, cuyo resultado es el lote entero. `SelectMany` aplana la tarea, no la colección que contiene, así que cada `OnNext` recibe un lote, y `processedCount` cuenta lotes mientras el registro los llama eventos. El programa ejecuta el mismo pipeline con lotes de 100 eventos en lugar de 100 ms, para que el recuento no dependa de los tiempos:

```text
== GA's reactive demo: 1,000 events, batches of 100, counted after SelectMany
element type after SelectMany: IEnumerable<ProcessedEvent>; processedCount 10
with a second SelectMany that flattens each batch: processedCount 1000
```

1.000 eventos forman 10 lotes, y la demo informaría de 10. Con ventanas de 100 ms sobre eventos espaciados con `Task.Delay(1)`, el recuento depende de la resolución del temporizador de la máquina, y la línea de registro «cada 100 eventos» puede no aparecer nunca. La corrección es un `SelectMany` más que aplane cada lote.

La demo termina además con `await Task.Delay(500); // Allow final batches to process`, y luego libera la suscripción. Medio segundo es una conjetura. Si un lote sigue ejecutándose cuando se libera la suscripción, sus resultados simplemente se descartan:

```text
== Disposing the subscription drops the batch still in flight
after Dispose, then the last batch finishing: received 2, OnCompleted False
```

Esperar el propio pipeline, como hace el programa con `await pipeline.Do(count).DefaultIfEmpty()`, espera exactamente lo necesario, y vuelve a lanzar el error del pipeline en lugar de registrarlo desde dentro de `Subscribe`. `DefaultIfEmpty` está ahí porque esperar un observable que termina sin ningún valor lanza una excepción.

## Errores y reintentos

`OnError` termina una secuencia para siempre, y un `Subject` lo recuerda:

```text
== Errors: OnError ends the sequence
observer saw: Dm7, OnError(the MIDI device was unplugged); a later subscriber sees: OnError(the MIDI device was unplugged)
```

Tras `OnError`, el subject ignoró `G7` y `OnCompleted`, y un suscriptor que llegó después recibió el error en seguida. Una fuente caliente que falla está acabada; para recuperarse, hace falta una fuente fría a la que volver a suscribirse:

```text
== Retry subscribes again; Catch switches to another sequence
Retry(3): D dorian after 3 subscriptions
Retry(2) on a source that keeps failing: InvalidOperationException: scale service unavailable, 2 subscriptions
Catch: C ionian (cached)
```

[`Retry(n)`](https://github.com/dotnet/reactive/blob/rxnet-v7.0.0/Rx.NET/Source/src/System.Reactive/Linq/Observable.Single.cs#L636-L645) cuenta suscripciones, no reintentos: `Retry(3)` tuvo éxito en la tercera suscripción, y `Retry(2)` se rindió tras dos, volviendo a lanzar el último error. Su resumen dice que «repeats the source observable sequence the specified number of times», y el recuento incluye la primera suscripción. El `retry(n)` de Reactor cuenta *re*suscripciones: el [`retry(2)` del curso de Reactor](../../spring-cloud-reactor/03-reactor-under-the-hood/#errores-y-reintentos) llama tres veces al mismo servicio de escalas poco fiable antes de `D dorian`. `Catch` cambia a una secuencia de reserva, como el `onErrorResume` de Reactor. Rx no tiene un backoff listo para usar como el `Retry.backoff` de Reactor: `RetryWhen` permite construir uno, o Polly envuelve la llamada.

## Si conoces Spring y Reactor

| Rx.NET | Reactor |
|---|---|
| `IObservable<T>`, `IObserver<T>` | `Publisher<T>` (`Flux`, `Mono`), `Subscriber<T>` |
| `Observable.Create`, `Defer` | `Flux.create`, `Flux.defer` |
| `Subject<T>` | `Sinks.many().multicast()` |
| `ReplaySubject<T>(n)` | `Sinks.many().replay().limit(n)`, o `replay(n)` sobre un `Flux` |
| `Publish()` + `Connect()`, `Publish().RefCount(n)` | `publish()` + `connect()`, `publish().refCount(n)`; `share()` |
| `Select`, `Where`, `SelectMany` | `map`, `filter`, `flatMap` |
| `Select(x => Observable.FromAsync(...)).Concat()` | `concatMap` |
| `Merge(n)` | `flatMap(f, n)` |
| `Throttle(t)` (espera el silencio) | `sampleTimeout(x -> Mono.delay(t))` |
| `Sample(t)` | `sample(Duration)` |
| `Buffer(TimeSpan)`, `Buffer(count)` | `buffer(Duration)`, `buffer(n)`, `bufferTimeout(n, Duration)` |
| `ObserveOn(scheduler)` | `publishOn(scheduler)` |
| `SubscribeOn(scheduler)` | `subscribeOn(scheduler)` |
| `EventLoopScheduler` | `Schedulers.single()` |
| `TestScheduler` | `VirtualTimeScheduler`, `StepVerifier.withVirtualTime` |
| sin backpressure: `OnNext` devuelve `void` | `request(n)`, `onBackpressureBuffer`, `limitRate` |
| `Retry(n)`: n suscripciones | `retry(n)`: n resuscripciones después de la primera |
| `Catch` | `onErrorResume` |
| `await observable` | `block()`, o `blockLast()` |

Los nombres vienen de la Javadoc de [`Flux`](https://projectreactor.io/docs/core/release/api/reactor/core/publisher/Flux.html) y de [`Sinks`](https://projectreactor.io/docs/core/release/api/reactor/core/publisher/Sinks.html). La [lección 2](../../spring-cloud-reactor/02-reactor-mono-and-flux/) y la [lección 3](../../spring-cloud-reactor/03-reactor-under-the-hood/) del curso de Reactor los muestran en ejecución.

## Ejercicios

1. Comparte una fuente fría entre dos suscriptores, de modo que se ejecute una sola vez y empiece solo cuando ambos se hayan suscrito, sin llamar tú mismo a `Connect`.
2. Toca al detector de acordes una nota cada 40 ms, de 0 a 280 ms, y termina la secuencia a 1 s. ¿Qué emite, y cuándo? ¿Qué dice eso de `Throttle` para un flujo que nunca hace pausas?
3. Procesa ocho elementos con una función asíncrona, nunca más de dos a la vez. ¿Qué operador, y en qué orden llegan los resultados?

<details>
<summary>Soluciones</summary>

1. `Publish().RefCount(2)` se conecta cuando llega el segundo suscriptor, y se desconecta cuando el número de suscriptores vuelve a cero:

    ```text
    1. Publish().RefCount(2): source ran 1 time; first Dm7 G7 Cmaj7 A7, second Dm7 G7 Cmaj7 A7
    ```

2. Un acorde de ocho notas, a los 330 ms: 50 ms después de la última nota. `Throttle` reinicia su temporizador en cada nota, así que mientras las notas sigan llegando con menos de 50 ms de separación, no emite nada en absoluto. Las propias observaciones de Rx sobre `Throttle` lo dicen: «for streams that never have gaps larger than or equal to dueTime between elements, the resulting stream won't produce any elements». Un detector para un flujo continuo necesita además un límite de tamaño o de duración del grupo, por ejemplo un búfer cerrado por el `Throttle` o por un temporizador, lo que ocurra primero (*por verificar*: el programa de la lección no ejecuta esa variante).

    ```text
    2. a note every 40 ms from 0 to 280 ms: 330:[C D E F G A B C]
    ```

3. `Select` de cada elemento hacia `Observable.FromAsync(...)`, y luego `Merge(2)`. Los resultados llegan en orden de finalización; el programa comprueba la concurrencia en lugar del orden:

    ```text
    3. Select + Merge(2): 8 results, at most 2 running at once, all of 0..7 True
    ```

</details>

## Puntos clave

- `IObservable<T>` empuja; el observador no puede frenar la fuente. Rx es para eventos que ocurren, no para trabajo del que tiras.
- Los observables fríos ejecutan su fuente para cada suscriptor; los subjects y `Publish` son calientes y comparten una.
- Prueba los pipelines basados en el tiempo con `TestScheduler`: se ejecutan en microsegundos y dan la misma respuesta en todas partes.
- `Throttle` en Rx.NET espera el silencio, como *debounce* en otras bibliotecas; `Sample` toma el último valor de cada periodo.
- Rx ejecuta el observador en el subproceso que llama a `OnNext`; `ObserveOn` y `SubscribeOn` mueven notificaciones y suscripciones, como `publishOn` y `subscribeOn`.
- Detrás de `ObserveOn` la cola no está acotada: reduce antes el flujo, o entrégalo a un canal acotado.
- `SelectMany` con tareas es concurrente y sin orden, y aplana la tarea, no una colección que contenga; `Concat` conserva el orden, `Merge(n)` limita la concurrencia.
- Espera el pipeline en lugar de adivinar cuánto tarda, y recuerda que `OnError` es definitivo.

## Fuentes

- [dotnet/reactive](https://github.com/dotnet/reactive) y su [versión Rx.NET 7.0.0](https://github.com/dotnet/reactive/releases/tag/rxnet-v7.0.0); Ian Griffiths y Lee Campbell, [Introduction to Rx.NET, 2nd edition](https://introtorx.com/), gratuito en línea.
- Microsoft Learn: [`IObservable<T>`](https://learn.microsoft.com/dotnet/api/system.iobservable-1), [`IObserver<T>`](https://learn.microsoft.com/dotnet/api/system.iobserver-1), [el patrón de diseño de observador](https://learn.microsoft.com/dotnet/standard/events/observer-design-pattern).
- Rx.NET en `rxnet-v7.0.0`: [`Subject.cs`](https://github.com/dotnet/reactive/blob/rxnet-v7.0.0/Rx.NET/Source/src/System.Reactive/Subjects/Subject.cs), [`IScheduler.cs`](https://github.com/dotnet/reactive/blob/rxnet-v7.0.0/Rx.NET/Source/src/System.Reactive/Concurrency/IScheduler.cs).
- Reactor: Javadoc de [`Flux`](https://projectreactor.io/docs/core/release/api/reactor/core/publisher/Flux.html) y de [`Sinks`](https://projectreactor.io/docs/core/release/api/reactor/core/publisher/Sinks.html).
- Guitar Alchemist en `a826864`: [`PerformanceOptimizationDemo/Program.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Demos/Performance/PerformanceOptimizationDemo/Program.cs#L171-L222).
