---
title: "Annexe 1 : trois optimisations, prouvées puis mesurées"
description: Trois membres de Guitar Alchemist réécrits avec des rotations, des popcounts et une table de correspondance — d'abord une vérification exhaustive de l'équivalence sur les 4096 ensembles de classes de hauteurs, ensuite BenchmarkDotNet, et un défaut documenté que la version rapide n'a pas le droit de corriger.
sidebar:
  label: "Annexe 1 : optimisations, prouvées"
  order: 90
---

Un benchmark, à lui seul, ne prouve rien. « Deux mille fois plus rapide » est une affirmation sur deux programmes, et elle n'a d'intérêt que s'il s'agit du *même* programme — la façon la plus simple de gagner un benchmark est de cesser discrètement de faire une partie du travail.

Cette annexe prend trois membres de [Guitar Alchemist](https://github.com/GuitarAlchemist/ga), réécrit chacun d'eux, et fait la preuve avant la mesure. Tous les trois prennent un **ensemble de classes de hauteurs** : un sous-ensemble des douze classes de hauteurs, c'est-à-dire un nombre de 12 bits, c'est-à-dire un domaine d'entrée de 4096 valeurs en tout. Il n'y a rien à échantillonner et rien à discuter. Le programme vérifie que la réécriture renvoie ce que renvoie GA pour **chaque** entrée, et la CI l'exécute sur Linux, Windows et macOS à chaque push. C'est seulement à ce moment-là que les chronomètres méritent d'être lus.

Les liens vers GA pointent vers le commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6).

## Exécuter l'annexe

```bash
bash code/csharp-advanced/check.sh                                   # toutes les leçons, comparées à expected/
dotnet run --project code/csharp-advanced/Advanced -c Release -- a1  # la preuve seule, après check.sh
cd code/csharp-advanced
dotnet run -c Release --project Benchmarks -- --filter "*IntervalClassVectorBenchmarks*"
```

Les réécritures sont dans [`Advanced/GaFast.cs`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/Advanced/GaFast.cs), la preuve dans [`Advanced/Appendix1.cs`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/Advanced/Appendix1.cs), les mesures dans [`Benchmarks/GaBenchmarks.cs`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/Benchmarks/GaBenchmarks.cs).

| | Membre | Le geste | Ce que la preuve doit garantir |
|---|---|---|---|
| 1 | `PitchClassSetId.IsClusterFree` | sortir un invariant de boucle, puis supprimer la boucle | rien — c'est un gain net |
| 2 | `PitchClassSet.IntervalClassVector` | compter les paires avec `PopCount`, puis précalculer les 4096 | un défaut arithmétique documenté qu'il faut **conserver** |
| 3 | `PitchClassSet.ClosestDiatonicKey` | supprimer un dictionnaire que personne ne lit | une égalité tranchée par la stabilité du tri, à reproduire exactement |

## 1. Une boucle qui fait douze fois la même chose

Un ensemble est *sans cluster* lorsqu'il ne contient pas trois classes de hauteurs chromatiquement adjacentes, comptées autour du cercle. La version de GA :

```csharp
public bool IsClusterFree
{
    get
    {
        for (var i = 0; i < 12; i++)
        {
            var extended = Value | (Value << 12);
            if (((extended >> i) & 7) == 7)
            {
                return false;
            }
        }

        return true;
    }
}
```

Deux choses y sont fautives, et une seule est l'évidente.

`extended` ne dépend pas de `i`. Il est reconstruit à chaque itération — un décalage et un OU, douze fois, pour une valeur qui ne change jamais. Le JIT le sortira peut-être de la boucle ; ce qui compte, c'est que le source le demande.

Le problème le plus intéressant est la boucle elle-même. `((extended >> i) & 7) == 7` demande « les bits *i*, *i+1* et *i+2* sont-ils tous à 1 ? », et la réponse pour les douze *i* à la fois tient dans une expression :

```csharp
const int Mask12 = 0xFFF;

// Rotation à droite d'un mot de 12 bits : le bit i du résultat est le bit i + n de l'entrée, modulo 12
static int Rotr12(int value, int n) => ((value >> n) | (value << (12 - n))) & Mask12;

public static bool IsClusterFree(int set) => (set & Rotr12(set, 1) & Rotr12(set, 2)) == 0;
```

`Rotr12(v, 1)` amène le bit *i + 1* là où était le bit *i*, et `Rotr12(v, 2)` y amène le bit *i + 2*. Le bit *i* du ET est donc exactement le test de GA pour ce *i*, et l'ensemble est sans cluster quand aucun bit ne survit. Deux rotations, deux ET, une comparaison à zéro, aucun branchement.

| Méthode | Moyenne | Rapport |
|---|---|---|
| `Ga` | 3,5344 ns | 1,00 |
| `Fast` | 0,1131 ns | 0,03 |

Trente et une fois plus rapide, et 0,11 ns est en dessous du coût d'une seule mauvaise prédiction de branchement — la méthode s'est pour ainsi dire dissoute dans son appelant. Aucune des deux versions n'alloue.

## 2. Compter des paires, et un défaut qui doit survivre

Un **vecteur de classes d'intervalles** compte, pour chaque classe d'intervalle de 1 à 6, combien de paires non ordonnées de l'ensemble sont à cette distance. C'est l'empreinte digitale de la [leçon 4 du cours de théorie musicale](../../music-theory-ga/04-set-classes/), et dans GA c'est une propriété sans cache :

```csharp
public IntervalClassVector IntervalClassVector => _pitchClassesSet.ToIntervalClassVector();
```

`ToIntervalClassVector` construit un *produit cartésien normé* générique, et construire cela, avant d'avoir regardé la moindre paire, fait ceci :

```csharp
Elements = [.. elements];
Base = new(Elements.Count);
Count = BigInteger.Pow(Base, length);
IndexFormat = Count > 0 ? $"D{(int)Math.Floor(BigInteger.Log10(Count) + 1)}" : "D1";

_indexByElement = Elements.Select((o, i) => (o, i)).ToImmutableDictionary(t => t.o, t => t.i);
_elementByIndex = Elements.Select((o, i) => (o, i)).ToImmutableDictionary(t => t.i, t => t.o);
```

Un `BigInteger.Pow`, un `BigInteger.Log10`, un `string.Format` et deux `ImmutableDictionary` — pour compter six petits nombres. Ensuite n² paires sont énumérées, filtrées à travers des délégués, groupées dans un `ILookup` puis repliées dans un `ImmutableSortedDictionary` ; et lire la propriété `Vector` du vecteur obtenu en reconstruit *un autre*, car elle aussi est calculée à chaque accès.

Les six comptes valent trois opérations chacun. Pour la classe d'intervalle `ic`, les paires sont les classes de hauteurs *p* telles que *p* et *p + ic* sont toutes deux présentes — `v & Rotr12(v, ic)` — et [`BitOperations.PopCount`](https://learn.microsoft.com/dotnet/api/system.numerics.bitoperations.popcount) les compte :

```csharp
public static int IntervalClassVectorId(int set)
{
    var value = 0;
    for (var ic = 1; ic <= 6; ic++)
    {
        var count = BitOperations.PopCount((uint)(set & Rotr12(set, ic)));
        if (ic == 6) count /= 2;
        value = value * 12 + count;
    }
    return value;
}
```

La classe d'intervalle 6 est divisée par deux parce que *p* et *p + 6* désignent la même paire vue des deux bouts. Et comme le domaine compte 4096 valeurs, tout cela peut se faire une fois pour toutes, au démarrage :

```csharp
public static readonly int[] IntervalClassVectorIds =
    [.. Enumerable.Range(0, 4096).Select(IntervalClassVectorId)];
```

| Méthode | Moyenne | Alloué | Rapport |
|---|---|---|---|
| `Ga` | 5 518,86 ns | 16 304 o | 1,00 |
| `Computed` | 2,62 ns | — | 0,0005 |
| `Table` | 0,0799 ns | — | 0,00001 |

Deux mille fois plus rapide en calculant à chaque appel, soixante-neuf mille fois depuis la table, et seize kilo-octets d'allocation par lecture de propriété deviennent zéro. C'est ce dernier chiffre qui compte dans un service : le constructeur statique de `PitchClassSet` construit lui-même un index des 4096 ensembles clé par cette propriété, et `SetClass.ToString()` l'appelle, si bien que chaque ligne de journal nommant une classe d'ensembles coûtait 16 Ko.

### Ce qui fait de tout cela une preuve

`IntervalClassVectorId` empaquette les six comptes en chiffres de base 12, le compte 1 étant le plus significatif. Un chiffre en base 12 va de 0 à 11. L'agrégat chromatique — les douze classes de hauteurs — a cinq comptes valant exactement **12**, qui n'entrent pas, et qui reportent :

```text
== The defect the fast version has to keep, not fix
chromatic aggregate          id                 decoded
GA                           3257430            <1 1 1 1 0 6>
the fast version             3257430            <1 1 1 1 0 6>
```

Le vrai vecteur est `<12 12 12 12 12 6>`. GA documente cet empaquetage dans les commentaires du type lui-même, avec un bug antérieur où un littéral en base 10 écrit en dur se décodait en un vecteur faux dès que l'encodage est passé en base 12.

La réécriture a donc un choix à faire, et une seule des deux options est une optimisation. Empaqueter les comptes *correctement* changerait l'identifiant de l'ensemble 4095 — et `ProgrammaticForteCatalog` ordonne chaque cardinalité par cet identifiant pour attribuer les numéros de Forte, si bien que les numéros de Forte du catalogue se décaleraient. C'est un changement de comportement déguisé en changement de performance. La réécriture reproduit le report, la vérification exhaustive le confirme, et le catalogue est vérifié à part :

```text
== Forte numbering is unchanged
set classes                  224                224 vector ids identical
distinct Forte numbers       224
```

Corriger l'empaquetage est une bonne idée. C'est un changement *différent*, avec sa propre migration, et il n'a rien à faire dans un commit dont le message dit « plus rapide ».

## 3. Un dictionnaire que personne ne lit

`ClosestDiatonicKey` répond à « laquelle des 30 tonalités partage le plus de notes avec cet ensemble ». Son implémentation commence ainsi :

```csharp
var dict = new Dictionary<Key, IReadOnlyCollection<PitchClass>>();
foreach (var key in Key.Items)
{
    var accidentedKeyNotes = key.Notes.Where(note => note.Accidental != null);
    var accidentedPitchClasses = accidentedKeyNotes.Select(note => note.PitchClass).ToImmutableArray();

    dict.Add(key, accidentedPitchClasses);
}
```

Le dictionnaire est passé à `IdentifyClosestKey`, qui le déstructure en `foreach (var (key, _) in items)`. **Les valeurs ne sont jamais lues.** Trente `ImmutableArray` sont construits, chacun à partir d'un filtre et d'une projection sur une collection de notes reconstruite pour l'occasion, puis jetés.

En dessous, `Key.Items` est une propriété, pas un champ : chaque accès concatène les 15 tonalités majeures et les 15 mineures et matérialise une nouvelle `ImmutableList`, et la méthode y touche deux fois. `key.Notes` reconstruit lui aussi sa collection à chaque accès. `IdentifyClosestKey` alloue ensuite, par tonalité, une `List`, une `ImmutableList`, deux enveloppes affichables et une `ImmutableList` triée — et n'utilise de tout cela qu'un seul nombre, `Matches.Count`.

Le calcul entier se réduit, par tonalité, à un ET et un `PopCount` contre un masque de 12 bits précalculé :

```csharp
static readonly (Key Key, int Mask, bool IsMinor)[] Keys =
    [.. Key.Items.Select(key => (key, Mask(key), key.KeyMode == KeyMode.Minor))];

static int Mask(Key key) => key.Notes.Aggregate(0, (mask, note) => mask | 1 << note.PitchClass.Value);

public static Key ClosestDiatonicKey(PitchClassSet set)
{
    // L'égalité tranchée par GA : un ensemble dont la forme normale contient la classe 3 est attendu mineur
    var normalForm = set.IsNormalForm ? set : set.ToNormalForm();
    var expectMinor = normalForm.Contains(Note.Chromatic.DSharpOrEFlat.PitchClass);

    var mask = set.Aggregate(0, (bits, pitchClass) => bits | 1 << pitchClass.Value);
    var best = Keys[0];
    var bestScore = -1;
    var bestExpected = false;
    foreach (var candidate in Keys)
    {
        var score = BitOperations.PopCount((uint)(mask & candidate.Mask));
        var expected = candidate.IsMinor == expectMinor;
        if (score > bestScore || (score == bestScore && expected && !bestExpected))
        {
            (best, bestScore, bestExpected) = (candidate, score, expected);
        }
    }
    return best.Key;
}
```

| Méthode | Moyenne | Alloué | Rapport |
|---|---|---|---|
| `Ga` | 68,211 µs | 175,66 Ko | 1,00 |
| `Fast` | 6,195 µs | 15,69 Ko | 0,09 |

**175 kilo-octets pour lire une propriété.** Onze fois plus rapide et onze fois plus léger — et les 15,69 Ko restants ne viennent pas de la recherche de tonalité : c'est `ToNormalForm()`, appelé pour décider s'il faut attendre une réponse majeure ou mineure, et laissé intact ici. C'est le candidat suivant.

### L'égalité est toute la difficulté

GA choisit sa réponse ainsi :

```csharp
list.OrderByDescending(tuple => tuple.Matches.Count)
    .ThenByDescending(tuple => tuple.Key.KeyMode == expectedKeyMode)
    .First()
```

[LINQ to Objects trie de façon stable](https://learn.microsoft.com/dotnet/api/system.linq.enumerable.orderbydescending), donc quand plusieurs tonalités sont à égalité sur les deux critères, la gagnante est celle qui venait en premier dans `Key.Items` — les 15 majeures, puis les 15 mineures. Une boucle qui remplacerait le tenant du titre sur `>=` au lieu de `>` renverrait une *autre tonalité* pour beaucoup d'ensembles : le même compte, un autre nom. La réécriture parcourt les tonalités dans ce même ordre et ne remplace que sur un score strictement meilleur, et c'est la vérification sur les 4096 cas qui dit que c'est juste.

Il vaut la peine de voir à quoi ressemblent les réponses :

```text
== A few sets, so the tables above are readable
set                          interval-class vector closest key, cluster-free
major scale                  2741: <2 5 4 3 6 1> Key of Am, True
C major triad                145: <0 0 1 1 1 0> Key of Dm, True
whole tone                   1365: <0 6 0 6 0 3> Key of Cb, True
chromatic aggregate          4095: <1 1 1 1 0 6> Key of Abm, False
```

La tonalité diatonique la plus proche de la gamme de do majeur est la mineur, et celle de l'accord parfait de do majeur est ré mineur. Les deux sont fausses, pour une raison que la [leçon 7 du cours de théorie musicale](../../music-theory-ga/07-cadences-and-progressions/#trouver-la-tonalité-dune-progression) démonte : un ensemble de classes de hauteurs n'a pas de tonique. `C F G C` et `Am F C G` sont le même ensemble, donc aucune fonction de l'ensemble seul ne peut choisir entre deux tonalités relatives, et la façon dont GA tranche l'égalité essaie quand même, en lisant un mode sur une forme normale, qui ne peut pas en encoder un. L'[annexe C de ce cours](../../music-theory-ga/appendix-ga-findings/) le classe comme défaut 19.

L'optimisation reproduit tout cela, parce que c'est cela, une optimisation.

## Ce qu'affiche la vérification exhaustive

```text
== Exhaustive check: all 4096 twelve-bit pitch-class sets
member                       agree              verdict
IsClusterFree                4096/4096          identical
IntervalClassVector.Id       4096/4096          identical
ClosestDiatonicKey           4096/4096          identical
sets with no chromatic cluster: 1499 of 4096
```

Trois lignes, et ce sont elles qui autorisent à citer les chronomètres ci-dessus. `ClosestDiatonicKey` est comparé sur la forme *texte* de la tonalité plutôt que par égalité de record, pour qu'un changement dans la façon dont `Key` se compare à elle-même ne puisse pas masquer une différence.

## Les mesures

[BenchmarkDotNet](https://benchmarkdotnet.org/) v0.15.8, une classe de benchmarks à la fois sur une machine par ailleurs au repos :

```text
BenchmarkDotNet v0.15.8, Windows 11 (10.0.26200.9445/25H2/2025Update/HudsonValley2)
Intel Core Ultra 9 285K 3.70GHz, 1 CPU, 24 logical and 24 physical cores
.NET SDK 10.0.112
  [Host]     : .NET 10.0.12 (10.0.12, 10.0.1226.42308), X64 RyuJIT x86-64-v3
  DefaultJob : .NET 10.0.12 (10.0.12, 10.0.1226.42308), X64 RyuJIT x86-64-v3
```

Chaque méthode `[Benchmark]` fait exactement un appel, sur la gamme majeure (2741) — sept notes, le cas courant dans GA. La CI exécute les mêmes classes avec `--job Dry`, qui vérifie qu'elles tournent encore et ne mesure rien, parce que les temps d'un runner partagé sont du bruit. Les temps absolus différeront sur votre machine ; ce sont les rapports qui sont l'affirmation.

Les chiffres d'allocation, eux, n'ont rien de statistique :

```text
# GA   IntervalClassVector.Id.Value    16,432 bytes
# fast IntervalClassVectorIds[id]           0 bytes
# GA   IsClusterFree                        0 bytes
# fast IsClusterFree                        0 bytes
# GA   ClosestDiatonicKey             179,848 bytes
# fast ClosestDiatonicKey              16,064 bytes
```

Ils viennent de [`GC.GetAllocatedBytesForCurrentThread`](https://learn.microsoft.com/dotnet/api/system.gc.getallocatedbytesforcurrentthread) autour d'un appel unique, après un appel de chauffe qui a exécuté les constructeurs statiques — la technique de la [leçon 1](../01-memory-values-and-spans/). Ils dépendent assez de la machine pour être affichés avec un préfixe `# ` et exclus de la comparaison, et sont assez stables pour mériter d'être affichés. Ils sont aussi un peu plus élevés que ceux de `[MemoryDiagnoser]`, qui soustrait son propre surcoût.

## Points à retenir

- Le domaine d'entrée d'un ensemble de 12 bits compte 4096 valeurs. Quand le domaine est aussi petit, « je l'ai testé » devrait vouloir dire *en entier*, et ce test a sa place dans la CI, à côté du benchmark.
- Une réécriture qui renvoie une autre réponse n'est la version rapide de rien du tout. Le report en base 12 de GA est un vrai défaut, et la version rapide le reproduit exactement ; le corriger est un changement séparé, au rayon d'impact séparé.
- Les tris stables sont porteurs. `OrderByDescending(…).ThenByDescending(…).First()` cache une règle de départage dans l'*ordre d'entrée*, et il faut l'expliquer à une boucle écrite à la main.
- Une propriété sans cache est une méthode au nom trompeur. `IntervalClassVector` et `Key.Items` reconstruisent tout à chaque accès, et toutes deux sont lues dans des boucles ailleurs dans GA.
- Le chiffre marquant ici n'est pas un temps, c'est 175 Ko d'allocation pour lire une propriété — et aucun profileur n'a été nécessaire pour le trouver, seulement la lecture d'une méthode qui remplit un dictionnaire puis ignore ses valeurs.

## Sources

- BenchmarkDotNet : [comment il fonctionne](https://benchmarkdotnet.org/articles/guides/how-it-works.html), [bonnes pratiques](https://benchmarkdotnet.org/articles/guides/good-practices.html).
- Microsoft Learn : [`BitOperations.PopCount`](https://learn.microsoft.com/dotnet/api/system.numerics.bitoperations.popcount), [`GC.GetAllocatedBytesForCurrentThread`](https://learn.microsoft.com/dotnet/api/system.gc.getallocatedbytesforcurrentthread), [`Enumerable.OrderByDescending`](https://learn.microsoft.com/dotnet/api/system.linq.enumerable.orderbydescending), [`BigInteger`](https://learn.microsoft.com/dotnet/api/system.numerics.biginteger).
- Guitar Alchemist au commit `a826864` : [`PitchClassSetId.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClassSetId.cs#L42-L57), [`PitchClassSet.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClassSet.cs#L597-L658), [`AtonalExtensions.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/AtonalExtensions.cs#L28-L35), [`VariationsWithRepetitions.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/Combinatorics/VariationsWithRepetitions.cs#L55-L73), [`IntervalClassVector.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/IntervalClassVector.cs), [`Key.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Tonal/Key.cs#L49-L50).
- Le code du cours : [`GaFast.cs`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/Advanced/GaFast.cs), [`Appendix1.cs`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/Advanced/Appendix1.cs), [`GaBenchmarks.cs`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/Benchmarks/GaBenchmarks.cs), [`expected/a1.txt`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/expected/a1.txt).
- Le même code lu comme de la musique, et non comme de la performance : [Théorie musicale pour Guitar Alchemist](../../music-theory-ga/), en particulier la [leçon 4](../../music-theory-ga/04-set-classes/), la [leçon 7](../../music-theory-ga/07-cadences-and-progressions/) et [son annexe C](../../music-theory-ga/appendix-ga-findings/).
