---
title: "Leçon 8 : Rx.NET"
description: Reactive Extensions pour .NET 7.0 mesuré par un programme — IObservable et IObserver, sources froides et chaudes, opérateurs testés en temps virtuel sur des notes qui forment des accords, schedulers, la backpressure qu'Rx n'a pas, étapes asynchrones et leur ordre, erreurs et nouvelles tentatives — avec le bug de comptage de la démo réactive de Guitar Alchemist, et l'opérateur Reactor correspondant à chaque opérateur Rx.
sidebar:
  label: 8. Rx.NET
  order: 8
---

Les channels et Dataflow transportent des éléments que quelqu'un *produit* ; Rx sert aux éléments qui *arrivent*. Une touche pressée, une note MIDI jouée, une mesure de capteur, un message poussé par un serveur : la source n'attend pas qu'on la sollicite, et les questions intéressantes portent sur le temps. Quelles notes ont été jouées ensemble ? Quelle était la dernière valeur avant que l'utilisateur arrête de bouger le curseur ? [Reactive Extensions pour .NET](https://github.com/dotnet/reactive) (Rx.NET) y répond avec des opérateurs LINQ sur [`IObservable<T>`](https://learn.microsoft.com/dotnet/api/system.iobservable-1), et avec une abstraction de scheduler qui permet à un test de dérouler des minutes d'événements en un instant.

Rx est aussi l'ancêtre de Reactor. Le [cours Spring Boot, Spring Cloud et Reactor](../../spring-cloud-reactor/02-reactor-mono-and-flux/) présente `Flux` en le comparant à `IObservable`, et le tableau à la fin de cette leçon fait le chemin inverse. La différence qui compte le plus est la backpressure : Reactor l'a, Rx ne l'a pas, et cette leçon mesure ce que cela signifie.

Les liens vers GA pointent sur le commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6). Les liens vers Rx pointent sur l'étiquette [`rxnet-v7.0.0`](https://github.com/dotnet/reactive/tree/rxnet-v7.0.0) de `dotnet/reactive`.

## Exécuter le programme de la leçon

```bash
bash code/csharp-advanced/check.sh                                   # toutes les leçons, comparées avec expected/
dotnet run --project code/csharp-advanced/Advanced -c Release -- l8  # cette leçon seulement, après check.sh
```

Le code se trouve dans [`Advanced/Lesson8.cs`](https://github.com/spareilleux/learn/blob/b4d713f86711b770a75d7504f334c5871c95f820/code/csharp-advanced/Advanced/Lesson8.cs), et sa sortie est comparée avec [`expected/l8.txt`](https://github.com/spareilleux/learn/blob/b4d713f86711b770a75d7504f334c5871c95f820/code/csharp-advanced/expected/l8.txt). Le programme référence les paquets [`System.Reactive`](https://www.nuget.org/packages/System.Reactive) et [`Microsoft.Reactive.Testing`](https://www.nuget.org/packages/Microsoft.Reactive.Testing), version 7.0.0, publiés en juillet 2026.

```text
== Where the types come from
IObservable<T>: System.Private.CoreLib; Observable: System.Reactive 7.0.0.0
```

Les deux interfaces, `IObservable<T>` et [`IObserver<T>`](https://learn.microsoft.com/dotnet/api/system.iobserver-1), font partie de la bibliothèque de base depuis .NET Framework 4. Tout le reste, les opérateurs, les sujets et les schedulers, vient du paquet. Un observateur a trois méthodes, `OnNext`, `OnError` et `OnCompleted`, et le contrat est celui que Reactor appelle les signaux : un nombre quelconque d'appels à `OnNext`, puis au plus un `OnError` ou un `OnCompleted`, jamais en même temps.

## Froid et chaud

Un `IObservable` construit avec [`Observable.Create`](https://github.com/dotnet/reactive/blob/rxnet-v7.0.0/Rx.NET/Source/src/System.Reactive/Linq/Observable.Creation.cs#L27) exécute sa fonction une fois pour chaque abonné. C'est un observable *froid*, comme un `Mono` ou un `Flux` construit à partir d'un supplier :

```text
== Cold: each subscriber runs the source
source ran 2 times; first got Dm7 G7 Cmaj7 A7, second got Dm7 G7 Cmaj7 A7
```

Un [`Subject<T>`](https://github.com/dotnet/reactive/blob/rxnet-v7.0.0/Rx.NET/Source/src/System.Reactive/Subjects/Subject.cs) est à la fois un observateur et un observable : tout ce que vous y poussez va aux observateurs abonnés *à ce moment-là*. C'est une source *chaude*, comme une souris ou un appareil MIDI :

```text
== Hot: a Subject pushes to whoever is subscribed now
subscribed before G7: G7 Cmaj7; subscribed before Cmaj7: Cmaj7; Dm7 went to nobody
ReplaySubject(2), subscribed after four chords: Cmaj7 A7
Publish() and Connect(): source ran 1 time; both got Dm7 G7 Cmaj7 A7 / Dm7 G7 Cmaj7 A7
```

- Personne n'a entendu `Dm7`, poussé avant tout abonnement ; l'abonné tardif a aussi manqué `G7`.
- Un `ReplaySubject` garde les dernières valeurs pour les abonnés qui arrivent plus tard : avec un tampon de deux, un nouvel abonné reçoit aussitôt `Cmaj7` et `A7`.
- `Publish()` transforme un observable froid en un observable chaud qui partage un seul abonnement à sa source : les abonnés attendent, `Connect()` démarre la source une fois, et les deux reçoivent chaque accord.

Savoir lequel vous avez décide si s'abonner deux fois fait deux fois le travail, ou si un abonné lent manque des événements. L'exercice 1 partage une source avec `RefCount` au lieu de `Connect`.

## Les opérateurs en temps virtuel

Les opérateurs Rx qui font intervenir le temps prennent un [`IScheduler`](https://github.com/dotnet/reactive/blob/rxnet-v7.0.0/Rx.NET/Source/src/System.Reactive/Concurrency/IScheduler.cs), et le `TestScheduler` de `Microsoft.Reactive.Testing` est un scheduler dont l'horloge n'avance que quand le test le décide. Le programme lui fournit des notes jouées sur un clavier : do, mi et sol en 25 ms, ré, fa et la une demi-seconde plus tard, puis si seul. Des notes qui se suivent à moins de 50 ms forment un accord :

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

Le pipeline se lit ainsi : mettre les notes en tampon, et fermer le tampon chaque fois que le flux est resté silencieux pendant 50 ms. [`Throttle`](https://github.com/dotnet/reactive/blob/rxnet-v7.0.0/Rx.NET/Source/src/System.Reactive/Linq/Observable.Time.cs#L1455-L1476) n'émet une note que si aucune autre note ne la suit dans les 50 ms, donc il se déclenche à 75 ms (25 + 50), 620 ms (570 + 50) et 1 060 ms. `Buffer` ferme un groupe à chaque fois. Le test entier déroule 1,2 seconde d'événements en quelques microsecondes, et donne la même réponse sur toutes les machines.

Un avertissement pour qui connaît RxJS ou Reactor : le `Throttle` de Rx.NET est ce que ces bibliothèques appellent *debounce*. Il attend le silence. L'opérateur qui laisse passer une valeur par période est `Sample`, et `Buffer` avec un `TimeSpan` découpe des fenêtres fixes sans tenir compte des notes :

```text
== The same notes: Sample(100 ms) and Buffer(100 ms)
Sample(100 ms): 100:G  600:A  1100:B
Buffer(100 ms): 100:[C E G]  600:[D F A]  1100:[B]
```

`Sample` n'a gardé que la dernière note de chaque fenêtre de 100 ms qui en a vu une, et les fenêtres fixes ne coïncident avec les accords que parce que les notes étaient bien espacées.

## Les schedulers : où s'exécute l'observateur

Rx ne démarre pas de threads de lui-même. Un observateur s'exécute sur le thread qui appelle `OnNext`, quel qu'il soit, sauf si un opérateur le déplace :

```text
== Schedulers: Rx runs the observer on the thread that calls OnNext, unless told otherwise
Subject.OnNext: observer ran on the caller's thread True, before OnNext returned True
ObserveOn(rx-loop): observer on rx-loop
SubscribeOn(rx-loop): the source ran on rx-loop
Observable.Timer(1 ms): observer on a pool thread True
```

- **Sans scheduler** : `Subject.OnNext` appelle directement l'observateur, sur le thread de l'appelant, et ne rend la main qu'une fois l'observateur revenu.
- [`ObserveOn`](https://github.com/dotnet/reactive/blob/rxnet-v7.0.0/Rx.NET/Source/src/System.Reactive/Linq/Observable.Concurrency.cs#L14-L26) déplace les notifications qui le traversent vers un scheduler, ici un `EventLoopScheduler`, qui possède un thread nommé `rx-loop`. C'est le `publishOn` de Reactor.
- [`SubscribeOn`](https://github.com/dotnet/reactive/blob/rxnet-v7.0.0/Rx.NET/Source/src/System.Reactive/Linq/Observable.Concurrency.cs#L85) déplace l'*abonnement*, si bien qu'une source synchrone comme cet `Observable.Create` s'exécute sur `rx-loop`. C'est le `subscribeOn` de Reactor.
- Les opérateurs temporels comme `Observable.Timer` planifient par défaut sur le pool de threads, si bien que le code après eux ne s'exécute plus sur le thread de l'appelant : la même surprise que le `delayElements` de Reactor, décrite dans le [cours Reactor](../../spring-cloud-reactor/03-reactor-under-the-hood/).

Le programme fait aussi `await` sur des observables : Rx rend `IObservable<T>` [attendable](https://github.com/dotnet/reactive/blob/rxnet-v7.0.0/Rx.NET/Source/src/System.Reactive/Linq/Observable.Awaiter.cs#L12-L20), et `await` renvoie la dernière valeur une fois la séquence terminée, lève son erreur, ou lève une exception si la séquence était vide.

## Pas de backpressure

Un abonné Reactor dit à son publisher combien d'éléments il peut prendre. Un observateur Rx n'a aucun moyen de dire quoi que ce soit : `OnNext` renvoie `void`. Deux cas en découlent. Sans scheduler, le producteur appelle directement l'observateur :

```text
== No backpressure: without a scheduler, OnNext waits for the observer
1,000 OnNext: the observer ran inside each call True, processed 1000
```

L'observateur s'est exécuté à l'intérieur de chaque appel à `OnNext`, donc un observateur lent ralentit bien le producteur, en occupant son thread. C'est de la backpressure par accident seulement, et elle s'arrête dès qu'un opérateur met une file entre eux. `ObserveOn` est un tel opérateur :

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

Le producteur a poussé 10 000 tableaux de 1 Ko pendant que l'observateur était bloqué sur le premier. Chaque `OnNext` a rendu la main immédiatement, et plus de 10 Mo se sont accumulés dans la file qu'`ObserveOn` tient pour la boucle d'événements : 10,7 Mo sur la machine de l'auteur, dans la ligne `# ` du programme. Rien ne limite cette file. La réponse de Rx est de réduire le flux avant qu'il atteigne un observateur lent, avec `Sample`, `Throttle`, `Buffer` ou `Window`, ou de quitter Rx pour un channel borné, ce que fait la leçon 9.

## Les étapes asynchrones et leur ordre

Pour appeler une méthode asynchrone sur chaque élément, Rx propose deux formes, qui se comportent très différemment. Le programme exécute deux lots, où le lot 0 attend jusqu'à 200 ms que le lot 1 démarre :

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
                // Le lot 0 attend jusqu'à 200 ms que le lot 1 démarre
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

- `SelectMany` avec une fonction qui renvoie une `Task` s'abonne à chaque tâche dès que son élément arrive : le lot 1 a démarré pendant que le lot 0 s'exécutait, a fini le premier, et est sorti le premier. C'est le `flatMap` de Reactor, dans l'ordre de fin.
- `Select` vers `Observable.FromAsync`, puis `Concat`, ne démarre chaque tâche qu'une fois la précédente terminée : le lot 0 a attendu ses 200 ms seul, et les résultats ont gardé leur ordre. C'est le `concatMap` de Reactor.
- `Merge(n)`, dans l'exercice 3, se situe entre les deux : au plus `n` tâches à la fois, dans l'ordre de fin.

## Étude de cas : la démo réactive de GA

La partie Rx du [`PerformanceOptimizationDemo`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Demos/Performance/PerformanceOptimizationDemo/Program.cs#L171-L222) de GA pousse 1 000 événements musicaux dans un `Subject`, les regroupe toutes les 100 ms, traite chaque lot de façon asynchrone et compte ce qui sort :

```csharp
var subscription = subject
    .Buffer(TimeSpan.FromMilliseconds(100)) // Regroupe les événements toutes les 100 ms
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

`ProcessBatchAsync` renvoie une `Task<IEnumerable<ProcessedEvent>>` : une tâche par lot, dont le résultat est le lot entier. `SelectMany` aplatit la tâche, pas la collection qu'elle contient, donc chaque `OnNext` reçoit un lot, et `processedCount` compte des lots alors que le journal les appelle des événements. Le programme exécute le même pipeline avec des lots de 100 événements au lieu de 100 ms, pour que le compte ne dépende pas du temps :

```text
== GA's reactive demo: 1,000 events, batches of 100, counted after SelectMany
element type after SelectMany: IEnumerable<ProcessedEvent>; processedCount 10
with a second SelectMany that flattens each batch: processedCount 1000
```

1 000 événements font 10 lots, et la démo afficherait 10. Avec des fenêtres de 100 ms sur des événements espacés par `Task.Delay(1)`, le compte dépend de la résolution du timer de la machine, et la ligne de journal « tous les 100 événements » peut ne jamais apparaître. La correction est un `SelectMany` de plus qui aplatit chaque lot.

La démo se termine aussi par `await Task.Delay(500); // Allow final batches to process`, puis libère l'abonnement. Une demi-seconde est une supposition. Si un lot s'exécute encore quand l'abonnement est libéré, ses résultats sont simplement perdus :

```text
== Disposing the subscription drops the batch still in flight
after Dispose, then the last batch finishing: received 2, OnCompleted False
```

Attendre le pipeline lui-même, comme le fait le programme avec `await pipeline.Do(count).DefaultIfEmpty()`, attend exactement le temps nécessaire, et relance l'erreur du pipeline au lieu de la journaliser depuis `Subscribe`. `DefaultIfEmpty` est là parce qu'attendre un observable qui se termine sans aucune valeur lève une exception.

## Erreurs et nouvelles tentatives

`OnError` termine une séquence pour de bon, et un `Subject` s'en souvient :

```text
== Errors: OnError ends the sequence
observer saw: Dm7, OnError(the MIDI device was unplugged); a later subscriber sees: OnError(the MIDI device was unplugged)
```

Après `OnError`, le sujet a ignoré `G7` et `OnCompleted`, et un abonné arrivé plus tard a reçu l'erreur aussitôt. Une source chaude qui échoue est finie ; pour s'en remettre, il faut une source froide à laquelle se réabonner :

```text
== Retry subscribes again; Catch switches to another sequence
Retry(3): D dorian after 3 subscriptions
Retry(2) on a source that keeps failing: InvalidOperationException: scale service unavailable, 2 subscriptions
Catch: C ionian (cached)
```

[`Retry(n)`](https://github.com/dotnet/reactive/blob/rxnet-v7.0.0/Rx.NET/Source/src/System.Reactive/Linq/Observable.Single.cs#L636-L645) compte les abonnements, pas les nouvelles tentatives : `Retry(3)` a réussi au troisième abonnement, et `Retry(2)` a abandonné après deux, en relançant la dernière erreur. Son résumé dit qu'il « repeats the source observable sequence the specified number of times », et le compte inclut le premier abonnement. Le `retry(n)` de Reactor compte les *ré*abonnements : le [`retry(2)` du cours Reactor](../../spring-cloud-reactor/03-reactor-under-the-hood/#erreurs-et-retries) appelle trois fois le même service de gammes capricieux avant `D dorian`. `Catch` bascule vers une séquence de repli, comme le `onErrorResume` de Reactor. Rx n'a pas de backoff tout prêt comme le `Retry.backoff` de Reactor : `RetryWhen` permet d'en construire un, ou Polly enveloppe l'appel.

## Si vous connaissez Spring et Reactor

| Rx.NET | Reactor |
|---|---|
| `IObservable<T>`, `IObserver<T>` | `Publisher<T>` (`Flux`, `Mono`), `Subscriber<T>` |
| `Observable.Create`, `Defer` | `Flux.create`, `Flux.defer` |
| `Subject<T>` | `Sinks.many().multicast()` |
| `ReplaySubject<T>(n)` | `Sinks.many().replay().limit(n)`, ou `replay(n)` sur un `Flux` |
| `Publish()` + `Connect()`, `Publish().RefCount(n)` | `publish()` + `connect()`, `publish().refCount(n)` ; `share()` |
| `Select`, `Where`, `SelectMany` | `map`, `filter`, `flatMap` |
| `Select(x => Observable.FromAsync(...)).Concat()` | `concatMap` |
| `Merge(n)` | `flatMap(f, n)` |
| `Throttle(t)` (attend le silence) | `sampleTimeout(x -> Mono.delay(t))` |
| `Sample(t)` | `sample(Duration)` |
| `Buffer(TimeSpan)`, `Buffer(count)` | `buffer(Duration)`, `buffer(n)`, `bufferTimeout(n, Duration)` |
| `ObserveOn(scheduler)` | `publishOn(scheduler)` |
| `SubscribeOn(scheduler)` | `subscribeOn(scheduler)` |
| `EventLoopScheduler` | `Schedulers.single()` |
| `TestScheduler` | `VirtualTimeScheduler`, `StepVerifier.withVirtualTime` |
| pas de backpressure : `OnNext` renvoie `void` | `request(n)`, `onBackpressureBuffer`, `limitRate` |
| `Retry(n)` : n abonnements | `retry(n)` : n réabonnements après le premier |
| `Catch` | `onErrorResume` |
| `await observable` | `block()`, ou `blockLast()` |

Les noms viennent de la Javadoc de [`Flux`](https://projectreactor.io/docs/core/release/api/reactor/core/publisher/Flux.html) et de [`Sinks`](https://projectreactor.io/docs/core/release/api/reactor/core/publisher/Sinks.html). La [leçon 2](../../spring-cloud-reactor/02-reactor-mono-and-flux/) et la [leçon 3](../../spring-cloud-reactor/03-reactor-under-the-hood/) du cours Reactor les montrent en action.

## Exercices

1. Partagez une source froide entre deux abonnés, pour qu'elle s'exécute une fois et ne démarre que lorsque les deux se sont abonnés, sans appeler `Connect` vous-même.
2. Jouez au détecteur d'accords une note toutes les 40 ms, de 0 à 280 ms, et terminez la séquence à 1 s. Qu'émet-il, et quand ? Qu'est-ce que cela dit de `Throttle` pour un flux qui ne marque jamais de pause ?
3. Traitez huit éléments avec une fonction asynchrone, jamais plus de deux à la fois. Quel opérateur, et dans quel ordre arrivent les résultats ?

<details>
<summary>Solutions</summary>

1. `Publish().RefCount(2)` se connecte quand le second abonné arrive, et se déconnecte quand le nombre d'abonnés retombe à zéro :

    ```text
    1. Publish().RefCount(2): source ran 1 time; first Dm7 G7 Cmaj7 A7, second Dm7 G7 Cmaj7 A7
    ```

2. Un seul accord de huit notes, à 330 ms : 50 ms après la dernière note. `Throttle` relance son timer à chaque note, donc tant que les notes arrivent à moins de 50 ms d'intervalle, il n'émet rien du tout. Les propres remarques de Rx sur `Throttle` le disent : « for streams that never have gaps larger than or equal to dueTime between elements, the resulting stream won't produce any elements ». Un détecteur pour un flux continu a aussi besoin d'une limite sur la taille ou la durée du groupe, par exemple un tampon fermé par le `Throttle` ou par un timer, selon ce qui arrive en premier (*à vérifier* : le programme de la leçon n'exécute pas cette variante).

    ```text
    2. a note every 40 ms from 0 to 280 ms: 330:[C D E F G A B C]
    ```

3. `Select` de chaque élément vers `Observable.FromAsync(...)`, puis `Merge(2)`. Les résultats arrivent dans l'ordre de fin ; le programme vérifie la concurrence plutôt que l'ordre :

    ```text
    3. Select + Merge(2): 8 results, at most 2 running at once, all of 0..7 True
    ```

</details>

## À retenir

- `IObservable<T>` pousse ; l'observateur ne peut pas ralentir la source. Rx sert aux événements qui arrivent, pas au travail que vous tirez.
- Les observables froids exécutent leur source pour chaque abonné ; les sujets et `Publish` sont chauds et en partagent une.
- Testez les pipelines temporels avec `TestScheduler` : ils s'exécutent en microsecondes et donnent la même réponse partout.
- `Throttle` dans Rx.NET attend le silence, comme *debounce* ailleurs ; `Sample` prend la dernière valeur par période.
- Rx exécute l'observateur sur le thread qui appelle `OnNext` ; `ObserveOn` et `SubscribeOn` déplacent les notifications et les abonnements, comme `publishOn` et `subscribeOn`.
- Derrière `ObserveOn`, la file n'est pas bornée : réduisez d'abord le flux, ou confiez-le à un channel borné.
- `SelectMany` avec des tâches est concurrent et sans ordre, et aplatit la tâche, pas une collection qu'elle contient ; `Concat` garde l'ordre, `Merge(n)` limite la concurrence.
- Attendez le pipeline au lieu de deviner combien de temps il prend, et souvenez-vous qu'`OnError` est définitif.

## Sources

- [dotnet/reactive](https://github.com/dotnet/reactive) et sa [version Rx.NET 7.0.0](https://github.com/dotnet/reactive/releases/tag/rxnet-v7.0.0) ; Ian Griffiths et Lee Campbell, [Introduction to Rx.NET, 2nd edition](https://introtorx.com/), gratuit en ligne.
- Microsoft Learn : [`IObservable<T>`](https://learn.microsoft.com/dotnet/api/system.iobservable-1), [`IObserver<T>`](https://learn.microsoft.com/dotnet/api/system.iobserver-1), [le modèle de conception observateur](https://learn.microsoft.com/dotnet/standard/events/observer-design-pattern).
- Rx.NET à `rxnet-v7.0.0` : [`Subject.cs`](https://github.com/dotnet/reactive/blob/rxnet-v7.0.0/Rx.NET/Source/src/System.Reactive/Subjects/Subject.cs), [`IScheduler.cs`](https://github.com/dotnet/reactive/blob/rxnet-v7.0.0/Rx.NET/Source/src/System.Reactive/Concurrency/IScheduler.cs).
- Reactor : Javadoc de [`Flux`](https://projectreactor.io/docs/core/release/api/reactor/core/publisher/Flux.html) et de [`Sinks`](https://projectreactor.io/docs/core/release/api/reactor/core/publisher/Sinks.html).
- Guitar Alchemist à `a826864` : [`PerformanceOptimizationDemo/Program.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Demos/Performance/PerformanceOptimizationDemo/Program.cs#L171-L222).
