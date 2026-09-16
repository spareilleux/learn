---
title: Journal
description: Notes de progression datées du cours de C# avancé — l'épinglage de GA, la vérification de l'IL et des erreurs du compilateur sur trois OS, ce que le JIT et le runtime ont fait sans que la documentation le dise, des benchmarks sur un processeur hybride, des programmes déterministes pour les channels, Dataflow et Rx, le nouveau plan, les trouvailles dans GA et les points à vérifier.
sidebar:
  order: 99
---

## Progression

- [x] Code du cours : le programme des leçons, les exemples décompilés, les extraits rejetés et les benchmarks, comparés à leur sortie attendue par `check.sh`
- [x] CI sous Linux, Windows et macOS, avec une exécution à blanc de chaque benchmark
- [x] Leçon 1 : mémoire, valeurs, références et spans
- [x] Leçon 2 : le ramasse-miettes
- [x] Leçon 3 : async et await sous le capot
- [x] Leçon 4 : performances mesurées
- [ ] Leçon 5 : les génériques en profondeur
- [x] Un nouveau plan en quatre parties et 24 leçons, avec ASP.NET Core en profondeur et les équivalents Spring et Reactor
- [x] Leçon 6 : les channels
- [x] Leçon 7 : TPL Dataflow
- [x] Leçon 8 : Rx.NET
- [x] Leçon 9 : choisir un flux
- [x] Annexe 1 : trois membres de GA optimisés, prouvés sur les 4096 ensembles de classes de hauteurs, puis mesurés

## 2026-09-14 — Mise en place et épinglage de GA

- Le cours se compile contre trois projets de GA, `GA.Core`, `GA.Domain.Core` et `GA.Business.Config`, récupérés par [`fetch-ga.sh`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/fetch-ga.sh) au commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), la tête de la branche `main` de GA ce jour-là, avec un clone sans blobs et partiel (sparse) : environ 11 Mo au lieu du dépôt entier. C'est le même commit et le même script que pour le [cours de théorie musicale](../../music-theory-ga/journal/), si bien que les deux cours lisent le même code.
- Ma machine a le SDK .NET 10.0.112 et une préversion 11.0. Le `global.json` du cours épingle `10.0.100` avec `rollForward: latestFeature`, donc `dotnet` choisit 10.0.112 dans le dossier du cours et la préversion ailleurs.
- `GA.Core` référence le paquet [`Microsoft.Net.Compilers.Toolset`](https://www.nuget.org/packages/Microsoft.Net.Compilers.Toolset) en version 4.11.0 : ce projet est donc compilé par le Roslyn 4.11 du paquet, et non par le Roslyn 5.0 du SDK. Il se compile sans problème ; je n'ai pas cherché de différence dans l'IL produit, *à vérifier*.
- `ilspycmd` 11.0.0.9375 est un outil local, restauré par `check.sh`. Deux surprises : `-il` désassemble l'assembly entier et ignore `-t Type`, donc `check.sh` désassemble une seule fois l'assembly `Snippets` ; et l'IL contient des commentaires `// Method begins at RVA 0x…`, qui changent à chaque modification d'une méthode sans rapport, donc `check.sh` les supprime avant de comparer.
- Décompiler avec `-lv CSharp4` montre la machine à états async : au niveau de langage C# 4, ILSpy ne peut pas la retransformer en `await`.

## 2026-09-14 — Vérifier les erreurs du compilateur

- Les extraits rejetés sont compilés en mémoire par un petit programme Roslyn, [`CompileFail`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/CompileFail/Program.cs), plutôt que par un projet par extrait : une seule build au lieu de onze. Il ajoute les `using` implicites du SDK dans un arbre syntaxique séparé et référence les assemblys du runtime. Ses messages sont identiques à ceux de `dotnet build`.
- **CS4007 manquait** au début : le vérificateur appelait `compilation.GetDiagnostics()`, et un `Span<int>` utilisé de part et d'autre d'un `await` compilait sans erreur. Cette erreur n'est signalée que pendant que le compilateur réécrit la méthode en machine à états, ce que `GetDiagnostics()` ne fait pas. Le vérificateur appelle maintenant `compilation.Emit(Stream.Null)` et lit ses diagnostics.
- Je m'attendais à CS8175 pour un span capturé par une lambda, de mémoire d'anciens compilateurs ; Roslyn 5.0 signale **CS9108** (« Cannot use parameter 'frets' that has ref-like type inside an anonymous method… »). La leçon 1 cite le vrai message.
- L'extrait CS8425 produit un avertissement, pas une erreur : le vérificateur l'attend et échoue s'il est absent.

## 2026-09-14 — Ce que le runtime a fait sans que l'IL le dise

- **Boxing supprimé par le JIT.** Un `box` suivi d'un `unbox.any` du même type n'alloue rien, même en tier 0. Avec `DOTNET_TieredCompilation=0`, une boîte qui ne s'échappe pas de la méthode est allouée sur la pile, y compris quand la valeur est convertie en interface : c'est l'allocation d'objets sur la pile de .NET 9, étendue dans .NET 10. `check.sh` exécute la leçon 1 des deux façons.
- **Le seuil du tas des objets volumineux** est vérifié sur la taille avant arrondi : `byte[84,975]` coûte 85 000 octets et reste en génération 0, `byte[84,976]` coûte autant et va dans le LOH (leçon 2).
- **Les littéraux sont sur un tas gelé** : `GC.GetGeneration("C major")` et `GC.GetGeneration(typeof(PitchClass))` renvoient `int.MaxValue`.
- Une première version de la boucle de budget d'allocation de la leçon 2 gardait ses tableaux dans une variable locale, et le JIT pouvait les allouer sur la pile après l'OSR, sans laisser de déchets à collecter. Les tableaux s'échappent maintenant dans un anneau de 16.
- `Task.WhenAll` conserve les exceptions internes dans l'ordre où les tâches ont échoué, qui change d'une exécution à l'autre : le programme les trie, et affiche l'ordre réel sur une ligne dépendante de la machine.
- `SearchValues.Create("#b")` renvoie `Any2CharPackedSearchValues` sur x64 et ``Any2SearchValues`2`` sur Arm64 (le runner macOS) : encore une ligne dépendante de la machine.
- Le budget de la génération 0 dépend de la taille du cache du processeur : 18 Mo sur ma machine, 16 Mo sur le runner Linux, 24 Mo sur le runner Windows et 6 Mo sur le runner macOS, où les mêmes 32 Mo de déchets ont provoqué cinq collectes au lieu d'une.

## 2026-09-14 — Benchmarks

- BenchmarkDotNet 0.15.8. Machine : Intel Core Ultra 9 285K (24 cœurs), 64 Go, Windows 11 25H2, SDK .NET 10.0.112, runtime 10.0.12. BenchmarkDotNet a basculé le mode de gestion de l'alimentation de Windows sur *Performances élevées* pour chaque exécution, puis l'a rétabli ensuite.
- La CI exécute chaque benchmark avec `--job Dry`. La première exécution à blanc a pris **8 min 30 s** : `JitBenchmarks` déclare ses quatre jobs dans une config, et `--job Dry` leur a *ajouté* un job à blanc au lieu de les remplacer. La config utilise maintenant `Job.Dry` quand `BENCHMARKS_DRY=1`, et l'exécution à blanc complète prend environ 30 s en local, de 17 à 53 s sur les runners.
- L'exécution complète des sept classes, l'une après l'autre sans rien d'autre en cours, a pris environ 45 minutes. `JitBenchmarks` exécute à lui seul quatre jobs, et a pris 4 minutes.
- **Le même code a mesuré 31 ns pendant le warmup et de 41 à 52 ns pendant les itérations réelles** (`VoicingWithSpans`). Épinglé sur un cœur avec `--affinity`, il a mesuré 32,4 ns, sur le premier cœur comme sur le dernier. Le Core Ultra 9 285K a des cœurs de performance et des cœurs d'efficacité ; je n'ai pas vérifié de quel type sont ces deux cœurs, ni confirmé que la migration des threads explique les itérations plus lentes, *à vérifier*. La leçon 4 raconte l'histoire et garde les tableaux non épinglés, puisque c'est ce qu'un lecteur obtiendra par défaut.
- J'ai ajouté `[MemoryDiagnoser]` à `JitBenchmarks` pendant que les autres classes tournaient, sans recompiler : l'exécution a utilisé la build précédente et n'a affiché aucune colonne `Allocated`. Après recompilation et nouvelle exécution, elle a montré le résultat sur lequel repose la leçon 4 : avec le PGO, la boucle sur `IEnumerable<int>` n'alloue plus son énumérateur de 40 octets, et s'exécute 9 fois plus vite.
- Deux de mes attentes étaient fausses : `FrozenDictionary` n'a pas été plus rapide que `Dictionary` sur douze suffixes d'accords courts, et `SearchValues` a été 1,7 fois plus *lent* qu'une boucle sur des chiffrages d'accords de 1 à 6 caractères. Les deux résultats figurent dans la leçon 4 tels que mesurés.

## 2026-09-14 — Dogfooding : ce que les leçons ont trouvé dans GA

Aucun de ces points n'a encore été signalé en amont ; ils sont listés pour que les mainteneurs de GA décident de leur sort.

- [`PitchClassSetId.ItemsSpan`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClassSetId.cs#L59-L71) copie les 4 096 identifiants dans un nouveau tableau à chaque appel, soit 16 408 octets. `Items` est déclaré comme `IReadOnlyCollection<PitchClassSetId>` et initialisé avec une expression de collection, donc le compilateur crée un `<>z__ReadOnlyList<PitchClassSetId>`, et le test `is PitchClassSetId[]` qui devrait éviter la copie est toujours faux (leçons 1 et 2).
- [L'opérateur `-` de `PitchClass`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClass.cs#L110-L137) cherche dans un `FrozenDictionary` de 144 tuples pour calculer `(a - b + 12) % 12`. Il prend 583 ns pour les 144 paires, contre 134 ns pour l'arithmétique et 41,5 ns pour un tableau plat de 144 valeurs (leçon 4).
- [`Try.OfAsync`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/Functional/Try.cs#L62-L73) attend sans `ConfigureAwait(false)`, donc bloquer dessus sous un contexte de synchronisation à un seul thread provoque un interblocage, et il attrape `OperationCanceledException`, ce qui transforme une annulation en échec ordinaire (leçon 3).
- [`LazyWithExpiration<T>`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/Utilities/LazyWithExpiration.cs#L20-L40) mesure son expiration avec un `Thread.Sleep` sur un thread du pool, un par valeur. Avec 64 valeurs qui expirent au bout d'une seconde, un `Task.Run` sans rapport a attendu 2 s sur ma machine et de 10 à 12 s sur les runners à 3 et 4 cœurs (leçon 3). Je n'ai pas cherché les endroits où GA l'utilise, *à vérifier*.

## 2026-09-14 — CI

- Commit [`d85a319`](https://github.com/spareilleux/learn/commit/d85a319), exécution [34915741516](https://github.com/spareilleux/learn/actions/runs/34915741516) : verte sur les trois OS, code des leçons uniquement.
- Commit [`8ba378e`](https://github.com/spareilleux/learn/commit/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3), exécution [34919815590](https://github.com/spareilleux/learn/actions/runs/34919815590) : les solutions des exercices, verte sur les trois OS. Les jobs ont pris 1 min 23 s sous Linux, 2 min sous macOS et 3 min 14 s sous Windows, dont 23 s, 27 s et 53 s pour l'exécution à blanc des 37 benchmarks. Environ 14 s de chaque job reviennent à la démonstration `LazyWithExpiration` de la leçon 3 : un `Task.Run` a attendu 11 001 ms sous Linux, 11 766 ms sous macOS et 11 050 ms sous Windows, alors que l'exécution précédente avait mesuré 9 878 ms.
- Le runner Windows a indiqué les mêmes largeurs de vecteurs et les mêmes écarts en virgule flottante que ma machine ; le runner Linux dispose d'AVX-512.

## 2026-09-15 — Un nouveau plan, et la partie 2 commence

- Le cours passe de 12 à 24 leçons en quatre parties : runtime et performances, concurrence et flux de données, ASP.NET Core en profondeur, métaprogrammation et outillage. Les leçons 1 à 4 gardent leurs slugs ; les anciennes leçons 6 et 12 deviennent les leçons 10 et 19, et les leçons 2 et 3 y renvoient désormais. Les leçons 6 à 9 ont été écrites avant la leçon 5.
- Les parties 2 et 3 comparent chaque sujet avec Spring et Reactor, de C# vers Java. Le [cours Spring Boot, Spring Cloud et Reactor](../../spring-cloud-reactor/) fait la comparaison dans l'autre sens, donc les leçons renvoient à ses pages au lieu de réexpliquer Reactor, et la partie 3 construira le pendant ASP.NET Core de son service de gammes.

## 2026-09-15 — Rendre déterministes des programmes concurrents

Chaque comportement des leçons 6 à 9 est affiché par le programme et comparé avec `expected/`, sur trois OS. Une première version de chaque leçon affichait quelque chose qui changeait d'une exécution à l'autre ; chaque leçon a tourné au moins neuf fois de suite avant que sa sortie soit commitée.

- **Des barrières, pas des délais.** Les éléments sont retenus avec un `TaskCompletionSource` jusqu'à ce que le programme ait vu ce qu'il veut montrer, et « le producteur est bloqué » se mesure en attendant qu'un compteur ne bouge plus, puis en affichant le compteur.
- **Les continuations s'exécutent quand bon leur semble.** Un `WriteAsync(...).AsTask()` terminé indiquait encore `IsCompleted` à false sur certaines exécutions, parce que sa continuation est asynchrone : le programme l'attend maintenant. De même avec `Fault` sur un bloc Dataflow, dont le `Completion.Exception` valait encore `null` juste après l'appel.
- **`EnsureOrdered = false` ne veut pas dire « inversé ».** Un premier test attendait que l'élément 0, lent, sorte en dernier ; ce n'était pas le cas sur 8 exécutions sur 20. La leçon 7 montre maintenant ce qu'un consommateur peut recevoir pendant que l'élément 0 s'exécute.
- **Les bornes en temps virtuel.** Des notes à exactement 500 ou 1 000 ms tombaient sur la limite des fenêtres de `Sample` et de `Buffer` ; les notes de la leçon 8 sont placées loin d'elles.
- **`Reader.Count` lève** `NotSupportedException` sur un channel non borné créé avec `SingleReader = true` : son `CanCount` vaut `false`. Le programme draine le channel pour compter ce qui reste.
- **Rx.NET 7.0 n'a pas de pont vers `IAsyncEnumerable`** : `ToAsyncEnumerable()` sur un observable ne compilait pas. La leçon 9 écrit les deux sens à la main.
- La première version de la leçon 7 étiquetait Dm7 comme Forte 4-3, d'après le `ProgrammaticForteCatalog` de GA ; la table de Forte dit 4-26. La leçon prend maintenant les étiquettes dans `CanonicalForteCatalog` et affiche les deux.
- Commits [`69bb214`](https://github.com/spareilleux/learn/commit/69bb2145cf22795d6394209ff82220e8a2bdf0d4) et [`b4d713f`](https://github.com/spareilleux/learn/commit/b4d713f86711b770a75d7504f334c5871c95f820), exécutions [34994143077](https://github.com/spareilleux/learn/actions/runs/34994143077) et [34995561655](https://github.com/spareilleux/learn/actions/runs/34995561655) : vertes sur les trois OS.
- Le benchmark de flux de la leçon 9 a tourné seul pendant 5 minutes sur la même machine que la leçon 4. BenchmarkDotNet a signalé une distribution bimodale pour `RxObserveOnTaskPool`.

## 2026-09-15 — Dogfooding : channels, Dataflow et Rx dans GA

GA utilise des channels dans son générateur de voicings et sa commande d'indexation, et TPL Dataflow et Rx.NET dans une démo de performances. Aucun de ces points n'a encore été signalé en amont.

- [`VoicingGenerator.GenerateAllVoicingsAsync`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Fretboard/Voicings/Generation/VoicingGenerator.cs#L180-L249) : un consommateur qui s'arrête tôt, comme le `.Take(100)` de l'exemple d'utilisation, laisse les producteurs générer toutes les fenêtres dans un channel non borné ; une fenêtre qui lève une exception laisse le consommateur attendre indéfiniment, parce que `Writer.Complete()` n'est jamais atteint ; le résumé dit que l'ordre est conservé, les commentaires en dessous disent le contraire (leçons 6 et 9).
- [`IndexVoicingsCommand`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaCLI/Commands/IndexVoicingsCommand.cs#L158-L251) : quand le consommateur échoue, parce que la base de données est arrêtée par exemple, il journalise et rend la main, et les producteurs attendent indéfiniment sur le channel plein (leçon 6). Le channel borné en mode `Wait` est le bon choix.
- [`PerformanceOptimizationDemo`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Demos/Performance/PerformanceOptimizationDemo/Program.cs) : la partie Dataflow compte les résultats d'une `List<T>` remplie par un autre thread sans attendre ce thread, et ignore le résultat de `SendAsync` (leçon 7) ; la partie Rx compte des lots comme des événements, 10 au lieu de 1 000, et attend 500 ms fixes au lieu d'attendre le pipeline (leçon 8). Sa partie channels est correcte.
- La même démo et `MusicalAnalysisApp`, tous deux en `net10.0`, référencent le paquet `System.Threading.Tasks.Dataflow` 9.0.10, que .NET 10 a déjà dans son framework partagé. Un nouveau projet `net10.0` avec la même référence reçoit l'avertissement NU1510 à la restauration, et charge quand même l'assembly du framework.
- Les numéros de `ProgrammaticForteCatalog` suivent un autre ordre que la table de Forte, bien que ses remarques qualifient les différences de mineures : 4-3 pour l'accord de septième mineure là où Forte dit 4-26 (leçon 7).
- GA a plusieurs classes `BackgroundService`, entre autres le préchauffage du cache et l'initialisation de l'index des voicings ; la leçon 15 est l'endroit où les lire.

## 2026-09-15 — Annexe 1 : optimiser GA, la preuve d'abord

La leçon 4 mesurait le code de GA tel quel. Cette annexe réécrit trois de ses membres, et l'intéressant s'est révélé être non pas le gain de vitesse mais ce que la réécriture n'a *pas* le droit de changer.

- Les trois sont `PitchClassSetId.IsClusterFree`, `PitchClassSet.IntervalClassVector` et `PitchClassSet.ClosestDiatonicKey`. Tous prennent un ensemble de 12 bits, donc le domaine d'entrée entier compte 4096 valeurs : `Advanced -- a1` compare chaque réécriture à la réponse de GA pour chacune d'elles, et la CI l'exécute sur trois OS. Écrire la preuve avant le benchmark a changé ce que j'étais prêt à affirmer.
- `IntervalClassVectorId` empaquette six comptes en chiffres de base 12, et les comptes de 12 de l'agrégat chromatique reportent. GA le documente comme une limitation connue. Empaqueter correctement changerait l'identifiant de l'ensemble 4095, et `ProgrammaticForteCatalog` ordonne chaque cardinalité par cet identifiant, donc tous les numéros de Forte pourraient bouger — la version rapide reproduit le report à la place. Un « correctif » glissé dans un changement de performance, c'est précisément le sujet de cette annexe.
- La réponse de `ClosestDiatonicKey` dépend de la stabilité d'`OrderByDescending` : les égalités reviennent à la tonalité que `Key.Items` liste en premier, les 15 majeures avant les 15 mineures. Une boucle qui remplacerait le tenant du titre sur `>=` plutôt que sur `>` renverrait discrètement une autre tonalité à chaque égalité ; celle qui remplace sur `>` est d'accord avec GA sur les 4096 ensembles.
- Les chiffres, sur cette machine : le vecteur de classes d'intervalles passe de 5 518,86 ns et 16 304 o par lecture de propriété à 2,62 ns calculé et 0,0799 ns depuis une table de 4096 entrées, sans aucune allocation ; `IsClusterFree` de 3,5344 ns à 0,1131 ns ; `ClosestDiatonicKey` de 68,211 µs et 175,66 Ko à 6,195 µs et 15,69 Ko.
- Ce sont les 175 Ko qui constituent la trouvaille, pas les microsecondes. `IdentifyClosestKey` reçoit un `Dictionary<Key, IReadOnlyCollection<PitchClass>>` et le déstructure en `foreach (var (key, _) in items)` : les valeurs sont construites pour les 30 tonalités et jamais lues. Aucun profileur n'a été nécessaire — il a suffi de lire la méthode.
- Les 15,69 Ko qui restent dans la version rapide viennent de `ToNormalForm()`, appelé seulement pour deviner un mode. Les tables de `PrimeForm` et un cache d'instances de `PitchClassSet` sont les candidats suivants, et aucun n'est encore écrit.
- Rien de tout cela n'a encore été remonté en amont.

## À vérifier

- Si `PoolingAsyncValueTaskMethodBuilder` supprime les 104 octets de `ValueTaskAfterYield` (leçon 3).
- L'IL de `GA.Core` compilé par Roslyn 4.11, comparé à celui qu'aurait produit le Roslyn 5.0 du SDK.
- Les leçons ont été écrites sur x64 ; les résultats Arm64 viennent uniquement des lignes dépendantes de la machine du runner macOS, jamais d'un benchmark.
