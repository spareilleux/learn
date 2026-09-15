---
title: Journal
description: Notes de progression datées du cours de C# avancé — l'épinglage de GA, la vérification de l'IL et des erreurs du compilateur sur trois OS, ce que le JIT et le runtime ont fait sans que la documentation le dise, des benchmarks sur un processeur hybride, les trouvailles dans GA et les points à vérifier.
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

## À vérifier

- Si `PoolingAsyncValueTaskMethodBuilder` supprime les 104 octets de `ValueTaskAfterYield` (leçon 3).
- L'IL de `GA.Core` compilé par Roslyn 4.11, comparé à celui qu'aurait produit le Roslyn 5.0 du SDK.
- Les leçons ont été écrites sur x64 ; les résultats Arm64 viennent uniquement des lignes dépendantes de la machine du runner macOS, jamais d'un benchmark.
