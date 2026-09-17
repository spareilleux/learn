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
- [x] Leçon 5 : les génériques en profondeur
- [x] Un nouveau plan en quatre parties et 24 leçons, avec ASP.NET Core en profondeur et les équivalents Spring et Reactor
- [x] Leçon 6 : les channels
- [x] Leçon 7 : TPL Dataflow
- [x] Leçon 8 : Rx.NET
- [x] Leçon 9 : choisir un flux
- [x] Annexe 1 : cinq membres de GA optimisés, prouvés sur les 4096 ensembles de classes de hauteurs, puis mesurés — les benchmarks ayant été réécrits une fois qu'il est apparu qu'ils mesuraient le JIT
- [x] Annexe 2 : le pipeline d'indexation de GA profilé, trois changements prouvés contre la sortie de GA elle-même et mesurés, puis envoyés en amont sous forme de pull requests

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
- **Les premiers benchmarks étaient faux, et flatteurs.** Appeler chaque membre une fois sur un argument `const` a laissé le JIT replier l'appel en un littéral : le `IsClusterFree` rapide ressortait à 0,0107 ns, un vingt-cinquième de cycle. Un statique mutable a supprimé le repliement et donnait encore une médiane de zéro, parce que BenchmarkDotNet soustrait une méthode vide. Réécrits pour balayer les 4096 ensembles, `IsClusterFree` est 4 fois plus rapide, pas 31 — et j'aurais publié le 31.
- Ce sont les 175 Ko qui constituent la trouvaille, pas les microsecondes. `IdentifyClosestKey` reçoit un `Dictionary<Key, IReadOnlyCollection<PitchClass>>` et le déstructure en `foreach (var (key, _) in items)` : les valeurs sont construites pour les 30 tonalités et jamais lues. Aucun profileur n'a été nécessaire — il a suffi de lire la méthode.
- `ToNormalForm` et `PrimeForm` sont faits aussi, donc l'annexe prouve maintenant cinq membres et non trois. Tabuler la forme normale a retiré les derniers 16 Ko du `ClosestDiatonicKey` rapide, qui n'alloue plus rien : 1 615 fois plus rapide, 175 Ko par appel disparus. `PrimeForm`, déjà de l'arithmétique sur les bits, n'a donné que 1,8 — le plafond honnête de la réécriture d'une arithmétique correcte, et il mérite d'être posé à côté du 1 615.
- Rien de tout cela n'a encore été remonté en amont.

## 2026-09-16 — Leçon 5 : les génériques en profondeur

- La leçon 5 comble le vide entre les leçons 4 et 6, qui ont été écrites en premier. Ses sorties viennent de la même machine et du même SDK que le reste du cours ; commit du code [`378eec1`](https://github.com/spareilleux/learn/commit/378eec1333390889e29fd0c42af0fae47512035e).
- Exécution CI [35173274425](https://github.com/spareilleux/learn/actions/runs/35173274425) : verte sous Linux, Windows et macOS. Les lignes dépendantes de la machine étaient les mêmes sur les trois runners que sur ma machine, celui en Arm64 compris : 4 592 octets pour le premier accès au cache de `Str`, et 1 puis 0 méthode compilée pour `Shared<string>` puis `Shared<object>`.
- **Le résumé du JIT lui-même comme test.** `DOTNET_JitDisasmSummary=1` et `DOTNET_JitStdOutFile` fonctionnent dans le runtime livré, donc `check.sh` compare la liste des compilations de `Shared<T>.Describe` : quatre pour six arguments de type, dont une sur `System.__Canon`. Il lance `Advanced.dll` directement : avec `dotnet run`, le processus du SDK lui-même hériterait des variables et écrirait dans le même fichier.
- **Ce que le runtime ne vérifie pas.** `MakeGenericMethod` a accepté `(int, string)` pour un paramètre `where T : unmanaged` ; le compilateur le rejette avec CS8377. `notnull` ne laisse rien dans `GenericParameterAttributes`.
- **Un extrait que je croyais rejeté s'est compilé.** L'interface `IStaticReadonlyCollectionFromValues<TSelf>` de GA masque la propriété abstraite statique `Items` avec une propriété `new static` qui a un corps. Je m'attendais à ce que `T.Items` sur un paramètre de type contraint par cette interface soit rejeté ; Roslyn 5.0 l'a compilé. J'ai retiré l'extrait ; le membre auquel cet appel se lie est *à vérifier*.
- **Le désassemblage a changé ma lecture du benchmark.** Dans le code partagé, lire un champ statique de `Counter<T>` appelle `CORINFO_HELP_GET_NONGCSTATIC_BASE` à chaque itération, au niveau 1 comme avec la compilation hiérarchisée désactivée, et pourtant la boucle n'était que 1,46 fois plus lente que la version `int`.
- **Encore le PGO.** Un `foreach` sur `PitchClass.Items` alloue 72 octets lors des premiers appels du programme, et 40 octets dans le benchmark, après le PGO dynamique.

## 2026-09-16 — Dogfooding : les interfaces d'objets valeurs de GA

Rien de tout cela n'a encore été remonté en amont.

- [`ValueObjectUtils<TSelf>.Items`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/ValueObjects/ValueObjectUtils.cs#L10) crée une nouvelle `ValueObjectCollection<TSelf>` de 32 octets à chaque lecture, bien que l'interface documente `Items` comme mémoïsée ; un `foreach` dessus alloue 72 octets (leçon 5).
- `Values` est déclaré `IReadOnlyList<int>` dans [`IStaticValueObjectList<TSelf>`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/Collections/Abstractions/IStaticValueObjectList.cs#L57), et les types qui l'implémentent renvoient un `ImmutableArray<int>` : 24 octets de boxing par lecture. Douze lectures ont pris 41,8 ns et 288 octets, contre 3,1 ns et rien du tout à travers l'`ImmutableArray` (leçon 5).
- [`ValueObjectCache<T>`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/ValueObjects/ValueObjectCache.cs#L38-L52) construit à sa première utilisation deux `FrozenSet` que rien ne lit dans les trois projets récupérés : 4 592 octets pour les 26 valeurs de `Str` (leçon 5).
- [`IRangeValueObject<TSelf>.EnsureValueInRange`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/Abstractions/IRangeValueObject.cs#L55-L63) normalise avec une taille d'intervalle de `max - min` au lieu de `max - min + 1` : 12 devient 2 pour une classe de hauteurs. Aucun appelant des projets récupérés ne passe `normalize: true`, donc le bug est latent (leçon 5).
- `default(Str)`, `new Str[n]` et `new T()` donnent la corde 0, que la vérification d'intervalle de `Str` interdit ; il en va de même pour tous les objets valeurs de GA dont le minimum est 1 (leçon 5).
- Le `out` de `IStaticReadonlyCollection<out TSelf>` n'a aucun effet : 13 des 17 types qui l'implémentent sont des structs, et l'interface n'a aucun membre d'instance (leçon 5).

## 2026-09-17 — Annexe 2 : profiler GA, avec des pull requests

L'Annexe 1 choisissait quoi optimiser en lisant GA. Cette fois, c'est un profileur qui a choisi, sur le pipeline de GA lui-même au commit [`66bdd04`](https://github.com/GuitarAlchemist/ga/tree/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e), et chaque changement est parti en amont. Le travail s'est étalé du soir du 16 septembre 2026 jusqu'aux petites heures du 17.

- **Trois pull requests.**
  - [#695](https://github.com/GuitarAlchemist/ga/pull/695) : la reconnaissance d'accords avec des masques de 12 bits, calculée une seule fois par ensemble de classes de hauteurs.
  - [#694](https://github.com/GuitarAlchemist/ga/pull/694) : le vecteur de classes d'intervalles calculé une seule fois par ensemble.
  - [#693](https://github.com/GuitarAlchemist/ga/pull/693) : `OptickIndexReader.Dimension` lu une seule fois.

  Chacune a été faite sur sa propre branche partant de `main`. Les tests de GA passaient avant l'ouverture de chaque PR : GA.Domain.Core.Tests à 458/458 et 459/459, et les tests d'accords et de voicings de GA.Business.Core.Tests à 421/421 et 419/419. Pour GA.Business.ML.Tests, les tests de recherche et de schéma sont passés à 227 sur 228 ; le test en échec échoue de la même façon sur `main`.
- **Où passait le temps.** `dotnet-trace` sur l'analyse des voicings a situé environ 52 % du thread principal dans `CanonicalChordRecognizer.IdentifyChordSet`, surtout pour construire des `HashSet`. Une sonde a mesuré `VoicingAnalyzer.Analyze` à 173 µs et 347 Ko par voicing, et une recherche OPTIC-K à 38 Mo par requête.
- **La preuve compare deux builds de GA, pas deux méthodes.** Un même programme de dump est compilé contre `main` et contre la branche, écrit chaque réponse, puis `cmp` compare les fichiers. Tous étaient identiques octet par octet :
  - `TryMatch` : 258 048 lignes ;
  - la reconnaissance : 106 496 lignes, chaque ensemble × 13 basses × 2 passes ;
  - les vecteurs de classes d'intervalles : 8 192 lignes ;
  - les 667 125 voicings de guitare passés dans `VoicingAnalyzer.Analyze` ;
  - 2 048 recherches sur le vrai index de 313 047 entrées.

  La preuve propre au cours, `GaPerf -- a2`, vérifie 6 856 704 appels à `TryMatch` et 106 496 reconnaissances, et tourne dans la CI.
- **La trouvaille, c'était le cache, pas les masques.** Les 667 125 voicings utilisent environ 2 500 ensembles de classes de hauteurs distincts, donc la recherche de motifs de chaque ensemble était répétée 266 fois. Avec un tableau de 4096 cases, la reconnaissance est 7 600 fois plus rapide dans le benchmark du cours. Dans GA, avec les deux changements, `VoicingAnalyzer.Analyze` est passé de 234,34 ms et 759 Mo à 8,94 ms et 22 Mo pour 2 000 voicings.
- **Les 38 Mo de la recherche n'étaient pas dans la recherche.** Une expérience avec un parcours séquentiel a alloué les mêmes 38 Mo que le parcours parallèle, ce qui a disculpé `Parallel.For`. Les octets venaient de `GetVector`, qui lisait une propriété exécutant un `Where` + `Sum` LINQ sur le registre des partitions : 626 094 requêtes par recherche. Lue une seule fois, une recherche est passée de 4,986 ms et 38,25 Mo à 2,162 ms et 41 Ko.
- **Deux résultats auxquels je ne m'attendais pas.**
  - La première version à masques allouait encore 72 octets par appel, à cause des énumérateurs obtenus à travers `IEnumerable<int>`. Un switch sur `int[]` et `HashSet<int>` les a supprimés et l'a rendue encore 2,7 fois plus rapide. Le PGO dynamique n'a pas supprimé cette allocation, contrairement à celle de la leçon 4 ; la raison est *à vérifier*.
  - Le partitionnement par plages de la recherche, qui semblait 8 % plus rapide avant le correctif, s'est révélé 22 % plus lent après. Je l'ai abandonné.
- **De bout en bout**, l'export OPTIC-K a tourné quatre fois, en alternant le `main` de GA et une build contenant les deux changements sur l'analyse : 142,8 s contre 62,9 s, puis 95,0 s contre 38,3 s. Les fichiers d'index étaient identiques entrée par entrée.
- **La machine n'était pas au repos, et les chiffres le disent.**
  - D'autres sessions tournaient. Chaque build et chaque série de benchmarks prenait un verrou global à la machine, et chaque série BenchmarkDotNet prenait aussi le verrou du GPU.
  - La RAM libre et les processus les plus actifs étaient journalisés au début de chaque série : de 13,6 à 18,5 Go libres, de 32 % à 100 % de CPU au total, avec Microsoft Defender, Docker et WSL en tête.
  - Le même binaire d'export a pris 142,8 s, puis 95,0 s.
  - Le coordinateur a signalé deux captures Chrome headless faites par une autre session entre 0 h 47 et 0 h 49. Aucune de mes séries n'a tourné dans cette fenêtre : les benchmarks d'avant se sont terminés à 0 h 42 min 38 s, et le suivant a commencé à 0 h 50 min 22 s. Les séries de GA qui venaient de tourner juste avant ont tout de même été relancées, avec les mêmes allocations et des temps dans les barres d'erreur.
  - Les tableaux avant-après de GA utilisent `ShortRun`. Leurs allocations sont exactes ; les temps sont indicatifs.
  - Une exécution de la série sur les accords n'a pas eu lieu : mon script pointait vers un worktree qui n'existait pas, et elle a été relancée.
- **Mesuré, mais pas modifié.**
  - Le chemin parallèle de `VoicingGenerator` est deux fois plus lent que son chemin séquentiel (1 419 ms contre 711 ms pour 667 125 voicings), et `PitchClassSet.GetCompatibleKeys` prend 13,5 % du profil de l'analyse. Les deux fichiers relèvent de correctifs de GA en cours dans une autre session, donc ces points y sont partis sous forme de propositions.
  - `KeyIdentificationService.Identify` n'est pas sur le chemin critique : 25 µs, une fois par requête.
  - Les allocations des objets valeurs de la leçon 5 n'apparaissent pas dans ce profil.
- **L'export de l'index n'est pas toujours reproductible.** Le premier export de la soirée diffère des suivants sur 266 des 313 047 entrées, indexées par instrument et par diagramme, bien qu'il provienne du même commit de GA. Chaque comparaison ci-dessus porte sur des exports du même groupe ; la cause est *à vérifier*.

## À vérifier

- Pourquoi le PGO dynamique n'a pas supprimé les énumérateurs boxés de la première version à masques de `TryMatch` (annexe 2).
- Pourquoi l'export de l'index OPTIC-K de GA diffère d'une session à l'autre sur 266 des 313 047 entrées (annexe 2).
- Le membre auquel `T.Items` se lie quand une interface dérivée masque une propriété abstraite statique avec une propriété `new static` (leçon 5).
- Pourquoi un appel de fonction d'assistance par itération n'a rendu la boucle partagée `ReadStatic<string>` que 1,46 fois plus lente (leçon 5).
- Lequel des deux objets d'un `foreach` sur `PitchClass.Items` le PGO dynamique cesse d'allouer (leçon 5).
- Si `PoolingAsyncValueTaskMethodBuilder` supprime les 104 octets de `ValueTaskAfterYield` (leçon 3).
- L'IL de `GA.Core` compilé par Roslyn 4.11, comparé à celui qu'aurait produit le Roslyn 5.0 du SDK.
- Les leçons ont été écrites sur x64 ; les résultats Arm64 viennent uniquement des lignes dépendantes de la machine du runner macOS, jamais d'un benchmark.
