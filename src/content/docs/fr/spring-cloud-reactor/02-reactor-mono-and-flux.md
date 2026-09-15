---
title: "2. Reactor : Mono et Flux"
description: Mono et Flux comparés à Task, IAsyncEnumerable et Rx.NET — assemblage contre souscription, les opérateurs que LINQ vous a déjà appris, signaux et demande, et StepVerifier avec le temps virtuel.
sidebar:
  order: 2
---

Exemple complet : [`code/spring-cloud-reactor/l02-reactor`](https://github.com/spareilleux/learn/tree/main/code/spring-cloud-reactor/l02-reactor), du Java ordinaire avec [`reactor-core`](https://projectreactor.io/docs/core/release/reference/) et [`reactor-test`](https://projectreactor.io/docs/core/release/reference/testing.html), sans Spring. `ExamplesTest` exécute chaque exemple et compare sa sortie à [`expected`](https://github.com/spareilleux/learn/tree/main/code/spring-cloud-reactor/l02-reactor/expected) ; le côté .NET est [`csharp/l02-task-vs-flux.cs`](https://github.com/spareilleux/learn/blob/main/code/spring-cloud-reactor/csharp/l02-task-vs-flux.cs).

## Deux types, quatre interfaces

WebFlux, Spring Cloud Gateway, R2DBC et les clients réactifs des leçons suivantes parlent tous [Project Reactor](https://projectreactor.io/docs/core/release/reference/). Ses deux types constituent tout le vocabulaire :

- **`Mono<T>`** émet au plus une valeur, puis se termine, ou échoue. C'est là où C# renverrait un `Task<T>`.
- **`Flux<T>`** émet un nombre quelconque de valeurs, puis se termine, ou échoue. C'est là où C# renverrait un `IAsyncEnumerable<T>` ou un `IObservable<T>`.

Les deux implémentent `Publisher<T>`, l'une des quatre interfaces de la [spécification Reactive Streams](https://github.com/reactive-streams/reactive-streams-jvm/blob/master/README.md) : un `Publisher` accepte un `Subscriber`, lui donne une `Subscription`, et ne lui envoie des valeurs qu'aussi vite que le subscriber les demande via cette subscription. Le JDK embarque les mêmes quatre interfaces sous la forme de [`java.util.concurrent.Flow`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/Flow.html). .NET n'a pas d'équivalent standard ; le parent le plus proche est [Rx.NET](https://github.com/dotnet/reactive), dont l'`IObservable<T>` pousse les valeurs sans aucun mécanisme de demande.

| C# | Reactor | Remarques |
|---|---|---|
| `Task<T>` | `Mono<T>` | un `Mono` ne démarre pas avant qu'on y souscrive ; un `Task` a en général déjà démarré |
| `Task` | `Mono<Void>` | se termine sans valeur |
| `IAsyncEnumerable<T>` | `Flux<T>` | les deux sont paresseux ; dans les deux cas, le subscriber tire les valeurs, par lots avec Reactor |
| `IObservable<T>` (Rx.NET) | `Flux<T>` | Rx pousse ; Reactor ne pousse que ce qui a été demandé |
| `await` | un opérateur suivant, ou `block()` à la frontière | il n'y a pas d'`await` en Java : le pipeline est la continuation |
| opérateurs LINQ | `map`, `filter`, `flatMap`, … | plus de 400 méthodes publiques sur `Flux`, surcharges comprises, avec des marble diagrams dans la [Javadoc](https://projectreactor.io/docs/core/release/api/reactor/core/publisher/Flux.html) |
| `null` | `Mono.empty()` | Reactor interdit les valeurs `null` |
| `FakeTimeProvider`, le `TestScheduler` de Rx | `StepVerifier.withVirtualTime` | des tests qui couvrent des minutes s'exécutent en millisecondes |

La [leçon 9 du cours Java](../../java-for-csharp/09-concurrency-and-virtual-threads/) a mis `Task` en correspondance avec `CompletableFuture`. La différence avec `Mono` vient en premier.

## Assemblage et souscription

Construire un pipeline et l'exécuter sont deux moments distincts. La documentation de Reactor appelle le premier **assemblage** (assembly) et le second **souscription** (subscription) :

```java
static Scale lookUp(String root, String mode) {
    System.out.println("  looking up " + root + " " + mode);
    return Scale.of(root, mode);
}

public static void main(String[] args) {
    // Assemblage : cette ligne construit une description du travail. Rien ne s'exécute encore.
    Mono<Scale> dorian = Mono.fromCallable(() -> lookUp("D", "dorian"));
    System.out.println("assembled a Mono");

    // La souscription lance le travail, une fois par subscriber : un Mono est froid.
    System.out.println("first subscriber:");
    dorian.subscribe(scale -> System.out.println("  got " + scale.notes()));
    System.out.println("second subscriber:");
    dorian.subscribe(scale -> System.out.println("  got " + scale.notes()));

    // Un CompletableFuture est chaud, comme un Task : il démarre à sa création et s'exécute une seule fois.
    System.out.println("CompletableFuture:");
    CompletableFuture<Scale> future = CompletableFuture.supplyAsync(() -> lookUp("E", "phrygian"));
    future.join();
    System.out.println("  joined twice, same result: " + (future.join() == future.join()));

    // Mono.just prend une valeur, donc son argument est calculé pendant l'assemblage, qu'il y ait un subscriber ou non.
    System.out.println("Mono.just:");
    Mono<Scale> eager = Mono.just(lookUp("F", "lydian"));
    System.out.println("  assembled, no subscriber yet");

    // Mono.defer repousse la construction du Mono lui-même jusqu'à ce que quelqu'un souscrive.
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

Trois règles ressortent de cette sortie :

- **Rien ne se passe sans subscriber.** Une méthode qui renvoie un `Mono` n'a fait que décrire le travail. Oublier de souscrire est la version réactive de l'appel d'une méthode `async` sans l'attendre, sauf qu'ici le travail ne démarre même pas. Dans WebFlux, le framework souscrit à ce que renvoie un contrôleur, si bien que le code applicatif appelle rarement `subscribe` lui-même.
- **Chaque subscriber exécute à nouveau le pipeline.** La recherche s'est exécutée deux fois pour deux subscribers. Un `Mono` est une recette, pas un résultat ; un `Task` ou un `CompletableFuture` est un résultat, calculé une fois. Quand plusieurs subscribers doivent partager une même exécution, `cache()` ou `share()` rendent un pipeline chaud.
- **`Mono.just` évalue d'emblée.** Son argument est une expression Java ordinaire, évaluée avant même l'appel à `just` : `F lydian` a été recherché sans aucun subscriber. `Mono.fromCallable`, `Mono.fromSupplier` et `Mono.defer` repoussent le travail jusqu'à la souscription. Le seul effet de bord de `eager.subscribe()`, la dernière ligne, est de livrer une valeur calculée bien avant.

Le côté C# affiche les trois mêmes situations pour `Task`, `IAsyncEnumerable` et Rx.NET :

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

Un `IAsyncEnumerable` se comporte comme un `Flux` : l'itérateur s'exécute à nouveau pour chaque `await foreach`. `Observable.Return` et `Observable.Defer` ont exactement le piège et le remède de `Mono.just` et `Mono.defer`, parce que Rx.NET et Reactor sont issus de la même conception. La ligne `LINQ` utilise les opérateurs que .NET 10 livre pour `IAsyncEnumerable` dans le framework lui-même ([`System.Linq.AsyncEnumerable`](https://learn.microsoft.com/dotnet/api/system.linq.asyncenumerable)).

## Les opérateurs

La plupart des opérateurs sont du LINQ sous un autre nom, ce qui rend un pipeline facile à lire, et facile à mal lire :

```java
Flux<Mode> modes = Flux.fromArray(Mode.values());

// map et filter sont Select et Where.
List<String> minorModes = modes
        .filter(mode -> Scale.of("C", mode.label()).triads().getFirst().quality() == Chord.Quality.MINOR)
        .map(Mode::label)
        .collectList()
        .block();
System.out.println("modes with a minor tonic chord: " + minorModes);

// flatMapIterable est SelectMany sur une collection ; distinct et count portent le même nom qu'en LINQ.
Mono<Long> distinctChords = modes
        .flatMapIterable(mode -> Scale.of("C", mode.label()).triads())
        .map(Chord::symbol)
        .distinct()
        .count();
System.out.println("distinct triads in the seven modes on C: " + distinctChords.block());

// zip apparie deux séquences élément par élément, comme Enumerable.Zip.
Flux<String> degrees = Flux.just("I", "ii", "iii", "IV", "V", "vi", "vii°");
Flux<Chord> chords = Flux.fromIterable(Scale.of("G", "major").triads());
System.out.println(Flux.zip(degrees, chords, (degree, chord) -> degree + "=" + chord)
        .take(4)
        .collectList()
        .block());

// reduce est Aggregate ; un Flux de Monos se fusionne avec flatMap, comme await Task.WhenAll.
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
| `SelectMany` sur des collections | `flatMapIterable` |
| `SelectMany` sur des résultats asynchrones | `flatMap` (concurrent), `concatMap` (un à la fois), `flatMapSequential` |
| `Aggregate` | `reduce` |
| `ToListAsync`, `ToDictionaryAsync` | `collectList`, `collectMap` |
| `Zip` | `zip`, `zipWith` |
| `Take`, `Skip` | `take`, `skip` |
| `Distinct`, `Count` | `distinct`, `count` |
| `Concat` | `concatWith`, `Flux.concat` |
| `DefaultIfEmpty` | `defaultIfEmpty`, `switchIfEmpty` |
| `Task.WhenAll` | `Mono.zip`, `Flux.merge`, `flatMap` |

`collectList` et `count` transforment un `Flux` en `Mono`, comme les méthodes LINQ qui se terminent par `Async` et renvoient un `Task`. `block()` attend ensuite ce `Mono`, comme `.GetAwaiter().GetResult()`. C'est acceptable dans `main` et dans les tests ; la leçon 3 montre où Reactor le refuse.

### `flatMap` ne conserve pas l'ordre

`flatMap` souscrit aux publishers internes de manière concurrente et transmet leurs valeurs à mesure qu'elles arrivent. Le `Mono.fromCallable` synchrone ci-dessus se terminait immédiatement, si bien que l'ordre semblait préservé. Avec des publishers internes qui prennent du temps, il ne l'est pas. Ce test utilise un service d'accords de tonique dont la réponse prend 300 ms pour C et 100 ms pour les autres :

```java
// Un service d'accords qui répond lentement pour certaines fondamentales ; les durées sont virtuelles.
static Mono<String> slowTonic(String root, long millis) {
    return Mono.delay(Duration.ofMillis(millis)).map(tick -> Scale.of(root, "major").triads().getFirst().symbol());
}

@Test
void flatMapEmitsInCompletionOrder() {
    // Sans temps virtuel, ce test attendrait 300 ms de temps réel.
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

`flatMap` a émis F, G, puis C, dans l'ordre d'achèvement : c'est `Task.WhenAny` dans une boucle, pas `Task.WhenAll`, dont les résultats conservent l'ordre des tâches. `concatMap` attend chaque publisher interne avant de souscrire au suivant : il conserve donc l'ordre et prend 500 ms. `flatMapSequential` est le troisième choix : souscriptions concurrentes, résultats réordonnés pour correspondre à la source.

## Les signaux

Un `Subscriber` reçoit quatre sortes de signaux : `onSubscribe` une fois, `onNext` pour chaque valeur, puis `onComplete` ou `onError`, jamais les deux. `log()` affiche chaque signal qui franchit sa position dans le pipeline :

```java
// log() affiche chaque signal qui franchit ce point du pipeline.
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

Sans SLF4J sur le class path, Reactor journalise dans la console, et le nom de catégorie `triad` n'apparaît pas. La sortie montre ce qu'`IAsyncEnumerable` ne rend jamais visible :

- **La demande remonte.** Le subscriber a tout demandé, mais `take(2)` n'a transmis que `request(2)` vers l'amont. Chaque opérateur peut modifier la demande ; la leçon 3 porte sur ce qui arrive quand une source produit plus vite que cela.
- **L'annulation remonte aussi.** Dès que `take` a ses deux valeurs, il envoie `cancel()` à la source, l'équivalent de la sortie d'une boucle `await foreach`, qui libère l'énumérateur. Aucun `CancellationToken` n'est passé nulle part.
- **Tout s'est exécuté sur `main`.** Reactor ne change pas de thread à moins qu'un opérateur ou un scheduler ne le fasse, ce que la leçon 3 couvre aussi.

Les erreurs et les résultats vides sont eux aussi des signaux :

```java
// Les erreurs sont aussi des signaux : la séquence s'arrête à la première.
Flux.just("C", "H", "D")
        .map(root -> Scale.of(root, "major").root())
        .subscribe(
                root -> System.out.println("onNext " + root),
                error -> System.out.println("onError " + error.getMessage()),
                () -> System.out.println("onComplete"));

// null n'est pas une valeur dans Reactor : un mapper qui renvoie null fait échouer la séquence.
Mono.just("C")
        .map(root -> (String) null)
        .subscribe(
                value -> System.out.println("onNext " + value),
                // Le message nomme la classe générée de la lambda, dont l'adresse change d'une exécution à l'autre.
                error -> System.out.println("onError " + error.getClass().getSimpleName() + ": "
                        + error.getMessage().replaceAll("/0x[0-9a-f]+", "/0x...")));

// Vide, c'est la façon dont Reactor dit "pas de valeur" : defaultIfEmpty et switchIfEmpty le gèrent.
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

- **Une erreur termine la séquence.** `D` n'a jamais été traité et `onComplete` ne s'est jamais affiché. L'exception levée dans `map` est devenue un signal `onError` au lieu de remonter la pile d'appels ; la leçon 3 montre comment s'en remettre.
- **`null` est refusé.** La [spécification Reactive Streams](https://github.com/reactive-streams/reactive-streams-jvm/blob/master/README.md#2.13) interdit les éléments `null`, donc un mapper qui renvoie `null` échoue. `Mono.justOrEmpty` transforme une valeur éventuellement nulle en `Mono` vide, comme `?.` et `??` gèrent `null` en C#.
- **`block()` sur un `Mono` vide renvoie `null`.** C'est le seul endroit où Reactor rend `null`, à la frontière entre le code réactif et le code ordinaire.
- **Un `subscribe` sans gestionnaire d'erreur** ne lève pas d'exception non plus. Dans une sonde ponctuelle avec le même `map` et seulement un consommateur de valeurs, Reactor a journalisé `[ERROR] (main) Operator called default onErrorDropped - reactor.core.Exceptions$ErrorCallbackNotImplemented: java.lang.IllegalStateException: boom` avec sa trace de pile, et `main` a continué. Passez toujours un consommateur d'erreurs, ou laissez un framework souscrire à votre place.

## Tester avec `StepVerifier`

`block()` dans un test fonctionne pour une valeur unique mais ne dit rien de l'ordre, du nombre de valeurs ni de la façon dont une séquence se termine. [`StepVerifier`](https://projectreactor.io/docs/core/release/reference/testing.html), dans `reactor-test`, souscrit et vérifie chaque signal tour à tour :

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

Rien n'est vérifié tant que `verify()`, `verifyComplete()` ou une autre méthode `verify…` ne s'exécute pas : sans elle, le test construit un scénario et réussit sans souscrire. Quand une attente échoue, le message nomme l'étape :

```java
StepVerifier.create(triads("D", "dorian"))
        .expectNext("Dm", "Em", "F#")
        .verifyComplete();
```

```text
expectation "expectNext(F#)" failed (expected value: F#; actual value: F)
```

Le **temps virtuel** remplace l'horloge de Reactor pendant la durée d'un test. `withVirtualTime` prend un supplier, pas un `Flux`, afin que les opérateurs comme `Mono.delay` soient créés après l'installation de l'horloge virtuelle ; `thenAwait` la fait avancer, et `expectNoEvent` vérifie que rien ne s'est passé pendant une période. Les tests `flatMap` ci-dessus couvrent 500 ms de temps virtuel en quelques millisecondes. Les tests .NET obtiennent la même chose avec [`FakeTimeProvider`](https://learn.microsoft.com/dotnet/api/microsoft.extensions.time.testing.faketimeprovider) pour le code qui prend un `TimeProvider`, ou avec le `TestScheduler` de Rx.NET.

## À retenir

- `Mono`, c'est zéro ou une valeur, `Flux`, de zéro à plusieurs ; les deux sont des publishers Reactive Streams, plus proches de l'`IObservable` de Rx.NET que de `Task`.
- L'assemblage construit une description ; la souscription l'exécute, une fois par subscriber. Rien ne se passe sans subscriber, et `Mono.just(expensive())` exécute `expensive()` quoi qu'il arrive : utilisez `fromCallable` ou `defer`.
- Les opérateurs sont du LINQ avec d'autres noms. `flatMap` est concurrent et émet dans l'ordre d'achèvement ; `concatMap` et `flatMapSequential` conservent l'ordre de la source.
- Les signaux sont `onSubscribe`, `onNext`, `onComplete` et `onError`. La demande (`request`) et l'annulation remontent vers l'amont ; les valeurs, les erreurs et l'achèvement descendent vers l'aval. `log()` les montre tous.
- Les erreurs terminent une séquence, `null` est interdit, et l'absence de valeur est un signal à part entière.
- Testez avec `StepVerifier` et terminez toujours par une méthode `verify` ; utilisez le temps virtuel pour tout ce qui comporte un délai.

## Exercices

1. Cette méthode compile et renvoie un `Flux`. Expliquez pourquoi l'appel `eagerTriads("H", "major")` lève une exception, alors que l'appelant d'une API réactive attend plutôt un signal `onError`, puis corrigez-la.

```java
static Flux<String> eagerTriads(String root, String mode) {
    return Flux.fromIterable(Scale.of(root, mode).triads()).map(Chord::symbol);
}
```

<details>
<summary>Solution</summary>

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

`Scale.of(root, mode)` est un argument de `fromIterable` : Java l'évalue donc pendant l'assemblage, dans le cadre de pile de l'appelant : c'est le même piège que `Mono.just`. `Flux.defer` le déplace dans la souscription, où l'exception devient un signal `onError`. L'équivalent C# est une méthode `async` qui valide ses arguments : l'exception est stockée dans le `Task` renvoyé, pas levée par l'appel, sauf si la validation se trouve dans un wrapper non `async`.

</details>

2. Portez cette requête C# vers Reactor, en renvoyant un `Mono<List<String>>` : parmi les tonalités C, G, D, A, E et B, dans cet ordre, gardez les trois premières dont la gamme majeure contient F#.

```csharp
var keys = await new[] { "C", "G", "D", "A", "E", "B" }.ToAsyncEnumerable()
    .Where(root => MajorScale(root).Contains("F#"))
    .Take(3)
    .ToListAsync();
```

<details>
<summary>Solution</summary>

```java
static Mono<List<String>> keysWithFSharp() {
    Note fSharp = Note.parse("F#");
    return Flux.just("C", "G", "D", "A", "E", "B")
            .filter(root -> Scale.of(root, "major").notes().contains(fSharp))
            .take(3)
            .collectList();
}
```

Le test attend `[G, D, A]`. `take(3)` annule la source après la troisième correspondance, si bien que E et B ne sont jamais testés, de même que le `Take` de LINQ arrête l'énumération. Le record `Note` se compare par valeur, donc `contains` fonctionne avec une note fraîchement analysée.

</details>

3. Écrivez un métronome : un `Flux<String>` qui joue une progression de quatre accords, un accord toutes les 500 ms, deux fois, puis se termine. Testez-le sans attendre quatre secondes.

<details>
<summary>Solution</summary>

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

`Flux.interval` émet 0, 1, 2… sur une minuterie et ne se termine jamais ; `take` y met fin. `expectSubscription()` vient avant `expectNoEvent`, parce que la souscription est elle-même un événement. Les méthodes `verify` renvoient le temps réel qu'elles ont pris, ce que le test utilise pour prouver qu'aucune attente réelle n'a eu lieu.

</details>

## Sources

- [Guide de référence de Reactor 3](https://projectreactor.io/docs/core/release/reference/) : [introduction à la programmation réactive](https://projectreactor.io/docs/core/release/reference/reactiveProgramming.html), [fonctionnalités principales](https://projectreactor.io/docs/core/release/reference/coreFeatures.html), [tests](https://projectreactor.io/docs/core/release/reference/testing.html), [de quel opérateur ai-je besoin ?](https://projectreactor.io/docs/core/release/reference/apdx-operatorChoice.html)
- Javadoc de [`Flux`](https://projectreactor.io/docs/core/release/api/reactor/core/publisher/Flux.html) et de [`Mono`](https://projectreactor.io/docs/core/release/api/reactor/core/publisher/Mono.html)
- [Spécification Reactive Streams](https://github.com/reactive-streams/reactive-streams-jvm/blob/master/README.md), [`java.util.concurrent.Flow`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/Flow.html)
- .NET : [les flux asynchrones](https://learn.microsoft.com/dotnet/csharp/asynchronous-programming/generate-consume-asynchronous-stream), [`System.Linq.AsyncEnumerable`](https://learn.microsoft.com/dotnet/api/system.linq.asyncenumerable), [Reactive Extensions pour .NET](https://github.com/dotnet/reactive), [`FakeTimeProvider`](https://learn.microsoft.com/dotnet/api/microsoft.extensions.time.testing.faketimeprovider)
