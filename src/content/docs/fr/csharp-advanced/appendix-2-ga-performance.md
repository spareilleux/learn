---
title: "Annexe 2 : profiler GA, puis prouver et mesurer"
description: "L'Annexe 1 choisissait ses membres en lisant le code ; celle-ci part d'un profileur sur le vrai pipeline d'indexation de Guitar Alchemist. La reconnaissance d'accords avec des masques de 12 bits, calculée une seule fois par ensemble de classes de hauteurs, un vecteur de classes d'intervalles mis en cache au lieu d'être reconstruit, et une requête LINQ qui allouait 38 Mo par recherche OPTIC-K — chaque changement prouvé octet par octet contre la sortie de GA elle-même, sur toutes les entrées et sur un corpus de 667 125 voicings, mesuré avec BenchmarkDotNet et envoyé en amont sous forme de pull request, avec ce qui a été mesuré puis abandonné."
sidebar:
  label: "Annexe 2 : GA, profilé"
  order: 91
---

L'[Annexe 1](../appendix-benchmarks/) a choisi cinq membres de [Guitar Alchemist](https://github.com/GuitarAlchemist/ga) en les lisant, et a prouvé chaque réécriture sur les 4096 ensembles de classes de hauteurs avant de la chronométrer. La méthode était la bonne, mais le choix des membres relevait de la supposition. Un membre qui alloue 175 Ko n'est un problème que si quelque chose l'appelle souvent.

Cette annexe ne suppose rien quant à l'endroit où chercher. Elle exécute le pipeline de GA lui-même — générer tous les voicings de guitare, les analyser, en faire un document et un embedding, puis interroger l'index OPTIC-K — et laisse un profileur dire où passe le temps. Les mêmes règles s'appliquent ensuite à ce que le profileur trouve :

1. **La preuve d'abord.** Chaque changement est vérifié contre les réponses de GA lui-même : sur toutes les entrées quand le domaine est assez petit, et toujours sur un corpus réel. La vérification compare deux *builds de GA*, avant et après, octet par octet.
2. **Ensuite la mesure.** [BenchmarkDotNet](https://benchmarkdotnet.org/) avec `[MemoryDiagnoser]`, avant et après, sur la même machine.
3. **Ensuite l'amont.** Une branche de GA et une pull request par sujet, avec les chiffres et la preuve dans la description.

Les liens vers GA pointent vers le commit [`66bdd04`](https://github.com/GuitarAlchemist/ga/tree/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e), la tête de `main` au moment des mesures. Les pull requests sont [#695](https://github.com/GuitarAlchemist/ga/pull/695) (reconnaissance d'accords), [#694](https://github.com/GuitarAlchemist/ga/pull/694) (vecteur de classes d'intervalles) et [#693](https://github.com/GuitarAlchemist/ga/pull/693) (recherche OPTIC-K).

## Exécuter l'annexe

```bash
bash code/csharp-advanced/check.sh                                     # toutes les leçons et les deux annexes, comparées à expected/
dotnet run --project code/csharp-advanced/GaPerf -c Release -- a2      # la preuve de cette annexe seule, après check.sh
cd code/csharp-advanced
dotnet run -c Release --project GaPerfBenchmarks -- --filter "*RecognitionBenchmarks*"
```

L'Annexe 2 se compile contre son propre commit de GA, que `fetch-ga.sh` récupère dans `.ga-perf/`, à côté du `.ga/` de l'Annexe 1 : les deux annexes lisent des commits différents, et aucune ne fait bouger l'autre. Les réécritures sont dans [`GaPerf/GaFast2.cs`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/GaPerf/GaFast2.cs) et [`GaPerf/OptickDimension.cs`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/GaPerf/OptickDimension.cs), la preuve dans [`GaPerf/Appendix2.cs`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/GaPerf/Appendix2.cs), les mesures dans [`GaPerfBenchmarks/GaPerfBenchmarks.cs`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/GaPerfBenchmarks/GaPerfBenchmarks.cs).

## Où passe le temps

Un petit programme sonde a appelé chaque étape du pipeline sur 20 000 voicings de guitare, en affichant autour de chacune le temps écoulé et [`GC.GetTotalAllocatedBytes`](https://learn.microsoft.com/dotnet/api/system.gc.gettotalallocatedbytes) :

| Étape | Par voicing | Alloué par voicing |
|---|---|---|
| Générer les 667 125 voicings de guitare, en parallèle | 1 419 ms au total | 364 Mo au total |
| Générer les 667 125 voicings de guitare, en séquentiel | 711 ms au total | 305 Mo au total |
| `VoicingAnalyzer.Analyze` | 173 µs | 347 Ko |
| `VoicingHarmonicAnalyzer.Analyze` | 95 µs | 321 Ko |
| `VoicingDocumentFactory.FromAnalysis` | 68 µs | 113 Ko |
| `MusicalEmbeddingGenerator.GenerateEmbeddingAsync` | 93 µs | 125 Ko |
| `KeyIdentificationService.Identify`, par progression | 25 µs | 16 Ko |
| `OptickSearchStrategy.SemanticSearchAsync`, par requête | 6,95 ms | **38 Mo** |

Deux lignes sautent aux yeux avant même tout profileur : une analyse qui alloue un tiers de mégaoctet par voicing, et une recherche qui alloue 38 Mo par requête.

[`dotnet-trace`](https://learn.microsoft.com/dotnet/core/diagnostics/dotnet-trace), avec le profil `dotnet-sampled-thread-time` et un rapport produit par `dotnet-trace report … topN --inclusive`, a ensuite décomposé l'analyse. Parmi les échantillons du thread principal :

- **environ 52 %** étaient dans `CanonicalChordRecognizer.IdentifyChordSet`, et la plupart dans la construction de `HashSet<int>` à l'intérieur de `ChordIntervalPattern.TryMatch` ;
- environ 13,5 % dans `PitchClassSet.GetCompatibleKeys` ;
- environ 11 % dans `NormedPairExtensions.ByNormCounts`, c'est-à-dire, une fois de plus, le vecteur de classes d'intervalles de la section 2 de l'Annexe 1.

La recherche, elle, n'avait aucune frame chaude : `TensorPrimitives.Dot` sur un fichier mappé en mémoire n'alloue rien. C'est ce que les sections suivantes expliquent.

## 1. Trois ensembles de hachage pour compter trois nombres

`CanonicalChordRecognizer` nomme un accord en essayant chaque classe de hauteurs de l'ensemble comme fondamentale, et chaque motif du catalogue contre les intervalles mesurés depuis cette fondamentale. À ce commit, le catalogue compte 62 motifs, donc un voicing de quatre notes fait 248 appels à [`TryMatch`](https://github.com/GuitarAlchemist/ga/blob/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e/Common/GA.Domain.Core/Theory/Harmony/ChordIntervalPattern.cs#L37-L54) :

```csharp
var patternSet = new HashSet<int>(Intervals);
var voicingSet = intervalsFromRoot is HashSet<int> hs ? hs : [.. intervalsFromRoot];

var missing = patternSet.Except(voicingSet).Count();
var extra = voicingSet.Except(patternSet).Count();

if (missing > maxMissing || extra > maxExtra)
    return null;

return new MatchResult(this, Overlap: patternSet.Intersect(voicingSet).Count(), Missing: missing, Extra: extra);
```

Un `HashSet` pour le motif, et un de plus dans chacun des appels à [`Except`](https://learn.microsoft.com/dotnet/api/system.linq.enumerable.except), `Except` et [`Intersect`](https://learn.microsoft.com/dotnet/api/system.linq.enumerable.intersect), qui construisent un ensemble à partir de leur second argument pour y tester l'appartenance. Quatre ensembles par appel, pour compter trois nombres.

Les intervalles mesurés depuis une fondamentale sont des classes de hauteurs, de 0 à 11. Les deux côtés sont donc des ensembles de 12 bits, et les trois comptes sont ce que l'Annexe 1 utilisait partout : un ET, un ET-NON et un [`PopCount`](https://learn.microsoft.com/dotnet/api/system.numerics.bitoperations.popcount).

```csharp
var missing = BitOperations.PopCount((uint)(patternMask & ~voicingMask));
var extra = BitOperations.PopCount((uint)(voicingMask & ~patternMask));
if (missing > maxMissing || extra > maxExtra) return null;

return new MatchResult(pattern, BitOperations.PopCount((uint)(patternMask & voicingMask)), missing, extra);
```

La méthode prend un `IReadOnlyCollection<int>`, qui peut contenir n'importe quoi : un 12, un −1, un doublon. Une valeur hors de l'intervalle de 0 à 11 n'a pas de bit, donc la réécriture n'essaie pas de lui en trouver un. Elle se replie sur le code à base d'ensembles de GA pour cet appel, ce qui la rend correcte par construction sur des entrées qu'aucun appelant n'envoie aujourd'hui.

### La première version allouait encore

La première version à masques construisait chaque masque avec un `foreach` sur `IEnumerable<int>`. Elle était dix fois plus rapide, et allouait pourtant encore 8,6 Mo pour 2 000 voicings :

| Méthode (2 000 voicings × 62 motifs) | Moyenne | Par voicing | Alloué | Rapport |
|---|---|---|---|---|
| `Ga` | 40,110 ms | 20,1 µs | 147,2 Mo | 1,00 |
| `MasksThroughInterface` | 3,869 ms | 1,93 µs | 8,6 Mo | 0,10 |
| `Masks` | 1,427 ms | 0,71 µs | 62,5 Ko | 0,04 |

Un `foreach` sur une interface appelle `GetEnumerator()` à travers l'interface. L'énumérateur de `HashSet<int>` est une struct, qui revient boxée, et un tableau fournit un petit objet énumérateur : 72 octets par appel pour les deux masques. La [leçon 4](../04-measured-performance/) montrait le PGO dynamique supprimant une telle allocation dans une boucle serrée. Ici, il ne l'a pas fait. Ce site d'appel voit deux types, un tableau et un `HashSet`, et savoir si c'en est la raison est *à vérifier*. `Masks` commence par un switch sur le type concret, si bien que le compilateur utilise la boucle sur tableau et l'énumérateur struct :

```csharp
switch (intervals)
{
    case int[] array:
        foreach (var interval in array) { if ((uint)interval > 11) return false; mask |= 1 << interval; }
        return true;
    case HashSet<int> set:
        foreach (var interval in set) { if ((uint)interval > 11) return false; mask |= 1 << interval; }
        return true;
    default:
        return TryMaskThroughInterface(intervals, out mask);
}
```

Encore 2,7 fois plus rapide, et l'allocation a disparu. Les 62,5 Ko restants font 32 octets par voicing, très probablement le `foreach` du benchmark lui-même sur le catalogue, typé comme un `IReadOnlyList`. `(uint)interval > 11` teste les deux bornes de l'intervalle en une seule comparaison, parce qu'un `int` négatif devient un `uint` très grand.

## 2. La même recherche, 266 fois

Rendre `TryMatch` 28 fois plus rapide laisse tout de même 248 appels par voicing de quatre notes. La meilleure question est de savoir s'ils sont nécessaires.

La documentation du reconnaisseur y répond elle-même. La reconnaissance « ne dépend que du contenu en classes de hauteurs et de l'indication facultative de basse pour la notation avec barre oblique », et le commentaire sur le classement appelle cela *l'invariant n° 33* : la basse ne doit pas influencer le motif qui l'emporte. Le résultat pour un ensemble, sans la basse, est donc une fonction de 12 bits. Le programme de preuve a compté combien de fois cette fonction est appelée avec le même argument pendant l'analyse du corpus :

```text
== How often the same set comes back
recognitions per distinct set  16.8                 in the sample
in the whole corpus            265.9
```

Les 667 125 voicings de guitare utilisent environ 2 500 ensembles de classes de hauteurs distincts. **La recherche de motifs de chaque ensemble était répétée 266 fois en moyenne.** Le correctif consiste à retenir la réponse :

```csharp
static readonly (CanonicalChordResult Result, int? Root)?[] Recognized = new (CanonicalChordResult, int?)?[4096];

public static CanonicalChordResult Identify(PitchClassSet set, PitchClass? bass = null)
{
    var (result, root) = Recognized[set.Id.Value] ??= Recognize(set);
    if (root is not { } chordRoot || bass is not { } b || b.Value == chordRoot) return result;
    return result with { SlashSuffix = $"/{NoteNames[b.Value]}" };
}
```

Un tableau de 4096 éléments constitue tout le cache : pas de dictionnaire, pas de hachage, pas d'éviction, parce que l'espace des clés est l'espace des indices. Deux threads en concurrence sur une même case calculent des résultats immuables égaux, et la dernière écriture l'emporte sans dommage.

### C'est la basse qui pouvait tout fausser

Le cache n'est correct que si la basse est appliquée *exactement* comme GA l'applique, et GA ne l'applique pas partout :

- les ensembles de 0, 1 et 2 classes de hauteurs ont leurs propres chemins de code, qui ignorent la basse ;
- un ensemble qui ne correspond à aucun motif se replie sur son numéro de Forte, qui ignore lui aussi la basse ;
- une correspondance de motif n'ajoute `/X` que lorsque la basse diffère de la fondamentale de l'accord.

L'entrée stockée ne conserve donc la fondamentale *que* sur le chemin de correspondance de motif, et `null` partout ailleurs. La version du cours ne voit pas la fondamentale privée de GA. Elle la reconstruit à partir du résultat public, et c'est la preuve qui établit que cette reconstruction est juste : 4096 ensembles × pas de basse et 12 basses × deux passes (la seconde lit le cache), chaque champ comparé :

```text
CanonicalChordRecognizer       106,496/106,496      4096 sets x 13 basses x 2 passes
```

| Méthode (2 000 voicings) | Moyenne | Par voicing | Alloué | Rapport |
|---|---|---|---|---|
| `Ga` | 198 958 µs | 99,5 µs | 677,1 Mo | 1,000 |
| `OncePerSet` | 26,22 µs | 13 ns | 158,8 Ko | 0,0001 |

**7 600 fois plus rapide, et 347 Ko par voicing qui ne sont plus alloués.** Les 79 octets par voicing qui restent sont la copie du `with` pour les voicings dont la basse n'est pas la fondamentale. Comme dans l'Annexe 1, la mesure est un régime établi : les itérations de warmup ont déjà vu les ensembles du corpus. Le premier appel pour chaque ensemble coûte ce qu'il a toujours coûté, et il y a au plus 4096 premiers appels dans un processus.

C'est ce changement qui compte, et il n'a rien d'astucieux. La réécriture à masques de la section 1 est le genre de chose qu'on s'attend à trouver dans une annexe sur les performances. Le cache, lui, est ce que le profil demandait.

## 3. Le vecteur de classes d'intervalles, que l'Annexe 1 avait déjà réécrit

La section 2 de l'Annexe 1 remplaçait le calcul d'`IntervalClassVector` par six popcounts, et conservait volontairement un défaut arithmétique : l'empaquetage en base 12 reporte pour l'agrégat chromatique. Le profil montre que la propriété est toujours sur le chemin critique dans GA : `VoicingHarmonicAnalyzer` la lit une fois par voicing, et `VoicingAnalyzer` jusqu'à quatre fois.

Pour la pull request, une autre réécriture était la plus sûre : **garder le calcul de GA, et ne le faire qu'une fois par ensemble.** Une table de popcounts devrait reproduire l'empaquetage, report compris, et divergerait sans bruit si GA venait à le modifier. Un cache de la réponse de GA elle-même ne peut pas diverger, puisqu'en cas d'absence il appelle le code inchangé :

```csharp
static readonly int[] IntervalClassVectorIdPlusOne = new int[4096];

public static IntervalClassVectorId IntervalClassVectorId(PitchClassSet set)
{
    var stored = IntervalClassVectorIdPlusOne[set.Id.Value];
    if (stored == 0)
    {
        stored = set.IntervalClassVector.Id.Value + 1;
        IntervalClassVectorIdPlusOne[set.Id.Value] = stored;
    }
    return new(stored - 1);
}
```

Le `+ 1` permet à un tableau d'`int` de dire « pas encore calculé » sans second tableau : tous les ensembles de moins de deux classes de hauteurs ont l'identifiant 0, qu'on ne pourrait sinon pas distinguer d'une case vide.

| Méthode (2 000 voicings) | Moyenne | Par voicing | Alloué | Rapport |
|---|---|---|---|---|
| `Ga` | 6 323,165 µs | 3,16 µs | 16,2 Mo | 1,000 |
| `OncePerSet` | 1,147 µs | 0,57 ns | — | 0,0002 |

Dans GA, le cache se trouve dans `ToIntervalClassVector<T>`. Il ne s'applique que lorsque la collection est l'`ImmutableSortedSet<PitchClass>` avec le comparateur par défaut que passe `PitchClassSet`, et toute autre forme de collection emprunte le chemin général. À elle seule, cette pull request fait à peine bouger l'analyse des voicings : le benchmark indiquait 9 %, ce qui reste dans le bruit de cette machine, parce que la reconnaissance d'accords domine encore. Après la section 2, le vecteur de classes d'intervalles est le coût le plus élevé qui reste dans l'analyse harmonique, et c'est la combinaison des deux que montrent les chiffres de bout en bout plus bas.

## 4. Une requête LINQ, 626 000 fois par recherche

La recherche allouait 38 Mo par requête, et le parcours n'alloue rien. Le premier suspect était [`Parallel.For`](https://learn.microsoft.com/dotnet/api/system.threading.tasks.parallel.for) : [`OptickSearchStrategy`](https://github.com/GuitarAlchemist/ga/blob/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e/Common/GA.Business.ML/Search/OptickSearchStrategy.cs#L185-L220) exécute une itération par voicing indexé, avec un tas par worker. Une expérience a donc exécuté le même parcours en séquentiel :

```text
identical top-10 lists: 64/64
current x200                                      1,337.3 ms      7,646.8 MB
chunked x200                                      1,236.8 ms      7,651.3 MB
sequential x50                                    1,670.5 ms      1,910.7 MB
```

38 Mo par requête dans les trois cas. Le parallélisme était innocent : les octets venaient de l'intérieur de la boucle. Le corps de la boucle lit un vecteur, et [`GetVector`](https://github.com/GuitarAlchemist/ga/blob/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e/Common/GA.Business.ML/Search/OptickIndexReader.cs#L179-L183) tient en deux lignes :

```csharp
public static int Dimension => EmbeddingSchema.CompactDimension;

public ReadOnlySpan<float> GetVector(long i)
{
    if ((ulong)i >= (ulong)_count) throw new ArgumentOutOfRangeException(nameof(i));
    return new ReadOnlySpan<float>(_vectors + i * Dimension, Dimension);
}
```

Et [`CompactDimension`](https://github.com/GuitarAlchemist/ga/blob/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e/Common/GA.Business.ML/Embeddings/EmbeddingSchema.cs#L147-L148) n'est pas une constante :

```csharp
public static int CompactDimension =>
    SimilarityPartitions.Sum(p => p.Dim);

public static IEnumerable<EmbeddingPartition> SimilarityPartitions =>
    Partitions.Where(p => p.Role == PartitionRole.Similarity);
```

Chaque lecture filtre le registre des 11 partitions et en fait la somme, en allouant au passage des itérateurs LINQ. `GetVector` lit `Dimension` deux fois, et le parcours appelle `GetVector` une fois pour chacun des 313 047 voicings indexés : **626 094 requêtes LINQ par recherche, pour calculer 124 à chaque fois.**

Rien dans le nom de la propriété ne le laisse deviner. `Dimension` ressemble à un champ, et `=>` à un simple accesseur. La conception est raisonnable, puisque le registre est la source de vérité unique pour la disposition. Le coût n'existe que parce qu'une boucle critique le lit. Le correctif garde la propriété et lit le registre une seule fois :

```csharp
public static int Dimension { get; } = EmbeddingSchema.CompactDimension;
```

Le cours ne peut pas compiler le projet de recherche de GA, qui tire Semantic Kernel, ONNX Runtime et ILGPU. `OptickDimension.cs` copie donc le registre et les deux propriétés depuis le commit de GA, et mesure l'arithmétique des décalages d'un parcours :

| Méthode (313 047 vecteurs) | Moyenne | Par vecteur | Alloué | Rapport |
|---|---|---|---|---|
| `Computed` | 25 849,42 µs | 82,6 ns | 40 070 016 o | 1,000 |
| `Stored` | 67,50 µs | 0,22 ns | — | 0,003 |

Exactement 128 octets par vecteur, 64 par lecture de la propriété. Une fois que le JIT a lu une valeur `static readonly`, il peut l'utiliser comme une constante : `Stored`, c'est la multiplication et rien d'autre.

Dans GA lui-même, avec le vrai index de 313 047 entrées, BenchmarkDotNet a mesuré l'avant et l'après :

| Benchmark | Avant | Après |
|---|---|---|
| `SemanticSearchAsync`, top 10 | 4,986 ms et 38,25 Mo | 2,162 ms et 41 306 o |
| `GetVector` pour chaque entrée | 31,955 ms et 38,21 Mo | 1,689 ms et 0 o |

### Ce qui a été abandonné

Une fois `GetVector` corrigé, l'expérience de partitionnement a tourné de nouveau :

```text
identical top-10 lists: 64/64
current x200                                        827.2 ms          3.1 MB
chunked x200                                      1,009.9 ms          7.2 MB
sequential x50                                      857.6 ms          0.0 MB
```

Le partitionnement par plages avec [`Partitioner.Create`](https://learn.microsoft.com/dotnet/api/system.collections.concurrent.partitioner.create) était *plus lent* que la boucle élément par élément de GA, donc `SearchInternal` reste inchangé. Il aurait été facile de livrer ce changement de partitionnement sur la foi de la première expérience, où il semblait 8 % plus rapide. Ce n'était que du bruit par-dessus 38 Mo de déchets.

## Ce qu'affichent les preuves

```text
== Exhaustive check
member                         agree                inputs
ChordIntervalPattern.TryMatch  6,856,704/6,856,704  62 patterns x 4096 sets x 9 tolerances x 3 shapes
CanonicalChordRecognizer       106,496/106,496      4096 sets x 13 basses x 2 passes
IntervalClassVector.Id         4,096/4,096          4096 sets

== Real corpus: guitar voicings from GA's generator
voicings generated             667,125
voicings checked               41,696               every 16th
distinct pitch-class sets      2,482                of 4096
chord name, canonical, slash   41,696/41,696

== A few voicings, as GA names them
x-3-2-0-1-0                    C
3-2-0-0-0-3                    G
x-x-0-2-3-2                    D
0-2-2-1-0-0                    E
x-5-4-5-3-x                    D7(shell)

== OPTIC-K reader: the dimension, read once
compact dimension              124                  sum of the similarity partitions
GetVector offset and length    313,047/313,047      one per indexed voicing
```

Voilà la preuve du cours, qui compare deux méthodes dans un même processus, et que la CI exécute sur trois OS. Les pull requests en utilisent une plus forte. Le *même* programme de dump est compilé deux fois, une fois contre le `main` de GA et une fois contre la branche, et écrit dans un fichier chaque réponse du chemin concerné. Puis `cmp` compare les fichiers :

| Dump | Contenu | Lignes | Résultat |
|---|---|---|---|
| `trymatch` | chaque motif × 4096 ensembles d'intervalles × 9 tolérances, en tableau et en `HashSet`, plus des entrées hors intervalle et des doublons | 258 048 | identique |
| `identify` | 4096 ensembles × 13 basses × 2 passes | 106 496 | identique |
| `icv` | 4096 ensembles × 2 passes : identifiant, texte, comptes et trois propriétés dérivées | 8 192 | identique |
| `voicings` | les 667 125 voicings de guitare passés dans `VoicingAnalyzer.Analyze` : champs de l'accord, consonance, drop voicing, étiquettes, mode | 667 125 | identique |
| recherche | 2 048 recherches top 10 sur le vrai index | 2 048 | identique |

Comparer deux builds attrape ce que la comparaison de deux méthodes ne peut pas voir : un changement dans un appelant, dans un type oublié par la réécriture, ou dans l'ordre dans lequel l'analyseur lit les choses.

## De bout en bout

La commande `FretboardVoicingsCLI --export-embeddings` de GA construit l'index OPTIC-K : 688 351 voicings pour la guitare, la basse et le ukulélé, 313 047 après déduplication, chacun analysé et converti en embedding. Elle a tourné quatre fois, en alternant le `main` de GA et une build contenant les changements sur les accords et sur le vecteur de classes d'intervalles :

| Tour | `main` de GA | Les deux changements |
|---|---|---|
| 1 | 142,8 s | 62,9 s |
| 2 | 95,0 s | 38,3 s |

Les quatre fichiers d'index sont identiques entrée par entrée. Les benchmarks d'analyse de GA, sur les mêmes 2 000 voicings :

| Benchmark | `main` de GA | Changement sur les accords | Les deux changements |
|---|---|---|---|
| `VoicingHarmonicAnalyzer.Analyze` | 213,19 ms et 700,8 Mo | 8,48 ms et 23,6 Mo | 2,47 ms et 7,3 Mo |
| `VoicingAnalyzer.Analyze` | 234,34 ms et 759,3 Mo | 30,23 ms et 82,1 Mo | 8,94 ms et 22,1 Mo |

`VoicingAnalyzer.Analyze` passe de 117 µs et 380 Ko par voicing à 4,5 µs et 11 Ko. L'export, qui calcule aussi les embeddings et écrit les fichiers, est de 2,3 à 2,5 fois plus rapide.

## Les mesures, et la confiance qu'on peut leur accorder

```text
BenchmarkDotNet v0.15.8, Windows 11 (10.0.26200.9457/25H2/2025Update/HudsonValley2)
Intel Core Ultra 9 285K 3.70GHz, 1 CPU, 24 logical and 24 physical cores
.NET SDK 10.0.112
  [Host]     : .NET 10.0.12 (10.0.12, 10.0.1226.42308), X64 RyuJIT x86-64-v3
```

L'Annexe 1 a été mesurée sur une machine au repos. Celle-ci ne l'a pas été, et la différence mérite d'être énoncée :

- **La machine était partagée.** Les benchmarks du cours ont tourné sur un poste de travail qu'utilisaient d'autres sessions, avec Microsoft Defender, Docker et WSL occupés. Chaque série a tourné sous un verrou global à la machine qui tenait à l'écart les autres builds et les tâches GPU, et la RAM libre ainsi que les processus les plus actifs étaient journalisés au début de chaque série : de 13,6 à 18,5 Go libres, de 32 % à 100 % de CPU au total.
- **Les allocations sont exactes ; les temps sont indicatifs.** Les tableaux du cours ci-dessus utilisent le job par défaut. Les tableaux avant-après de GA utilisent `ShortRun` (trois itérations), dont les barres d'erreur ont atteint de 10 à 50 % de la moyenne sur les exécutions les plus chargées.
- **L'export a varié d'un facteur 1,5 d'un tour à l'autre** pour le même binaire : 142,8 s, puis 95,0 s. Le rapport au sein d'un même tour a tenu, et c'est pour cela que les tours alternent.
- **Chaque accélération annoncée est très loin du bruit.** Aucune n'est inférieure à 2,3 fois, et les plus grandes se comptent en milliers. Une affirmation de 10 % n'aurait pas été publiable sur cette machine, et c'est pourquoi la section 3 n'en fait pas.

## Mesuré, mais pas modifié

- **Le chemin parallèle de `VoicingGenerator`** a généré les 667 125 voicings en 1 419 ms et 364 Mo, et le chemin séquentiel en 711 ms et 305 Mo : le parallèle est deux fois plus lent. Ce fichier relève d'une autre série de correctifs de GA en cours, donc la trouvaille est allée à ce travail plutôt que dans une pull request ici.
- **`PitchClassSet.GetCompatibleKeys`**, 13,5 % du profil de l'analyse, et les membres de `Key` qu'il appelle. Ces fichiers ont eux aussi des correctifs en cours ailleurs ; le même cache par ensemble s'y applique, et il a été rédigé sous forme de proposition.
- **`KeyIdentificationService.Identify`** : 25 µs par progression, appelé une fois par requête, pas une fois par voicing.
- **Les allocations des objets valeurs de la [leçon 5](../05-generics-in-depth/)** (`Items`, `Values`, `ValueObjectCache<T>`) : réelles, mesurées, et absentes de ce profil. Aucune n'est sur le chemin d'indexation.
- **Le partitionnement par plages de la recherche** : plus lent, voir la section 4.
- **L'export de l'index n'est pas toujours reproductible.** Les quatre exports alternés ci-dessus sont identiques, tout comme deux exports antérieurs faits l'un après l'autre avec les deux binaires. Mais le premier export de la soirée, depuis le `main` de GA, diffère de tous les autres sur 266 des 313 047 entrées quand on indexe les entrées par instrument et par diagramme, et les trois groupes de fichiers diffèrent en taille de quelques dizaines d'octets. Chaque comparaison de cette annexe porte sur des exports du même groupe, donc les conclusions tiennent. La cause est *à vérifier*.
