---
title: "Annexe 1 : cinq optimisations, prouvées puis mesurées"
description: Cinq membres de Guitar Alchemist réécrits avec des rotations, des popcounts et des tables de correspondance — d'abord une vérification exhaustive de l'équivalence sur les 4096 ensembles de classes de hauteurs, ensuite BenchmarkDotNet, un défaut documenté que la version rapide n'a pas le droit de corriger, et un benchmark qu'il a fallu jeter parce qu'il mesurait le JIT et non le code.
sidebar:
  label: "Annexe 1 : optimisations, prouvées"
  order: 90
---

Un benchmark, à lui seul, ne prouve rien. « Mille fois plus rapide » est une affirmation sur deux programmes, et elle n'a d'intérêt que s'il s'agit du *même* programme — la façon la plus simple de gagner un benchmark est de cesser discrètement de faire une partie du travail.

Cette annexe prend cinq membres de [Guitar Alchemist](https://github.com/GuitarAlchemist/ga), réécrit chacun d'eux, et fait la preuve avant la mesure. Tous les cinq prennent un **ensemble de classes de hauteurs** : un sous-ensemble des douze classes de hauteurs, c'est-à-dire un nombre de 12 bits, c'est-à-dire un domaine d'entrée de 4096 valeurs en tout. Il n'y a rien à échantillonner et rien à discuter. Le programme vérifie que la réécriture renvoie ce que renvoie GA pour **chaque** entrée, et la CI l'exécute sur Linux, Windows et macOS à chaque push. C'est seulement à ce moment-là que les chronomètres méritent d'être lus.

La mesure a fini par demander la même méfiance que le code. La première version des benchmarks appelait chaque membre une fois et annonçait que le `IsClusterFree` rapide s'exécutait en 0,0107 ns — un vingt-cinquième de cycle, ce qui n'est pas une vitesse mais un symptôme. L'histoire est dans [les mesures](#les-mesures), à la fin, et c'est la raison pour laquelle chaque chiffre ci-dessous est un balayage du domaine entier.

Les liens vers GA pointent vers le commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6).

## Exécuter l'annexe

```bash
bash code/csharp-advanced/check.sh                                   # toutes les leçons, comparées à expected/
dotnet run --project code/csharp-advanced/Advanced -c Release -- a1  # la preuve seule, après check.sh
cd code/csharp-advanced
dotnet run -c Release --project Benchmarks -- --filter "*NormalFormBenchmarks*"
```

Les réécritures sont dans [`Advanced/GaFast.cs`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/Advanced/GaFast.cs), la preuve dans [`Advanced/Appendix1.cs`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/Advanced/Appendix1.cs), les mesures dans [`Benchmarks/GaBenchmarks.cs`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/Benchmarks/GaBenchmarks.cs).

| | Membre | Le geste | Ce que la preuve doit garantir |
|---|---|---|---|
| 1 | `PitchClassSetId.IsClusterFree` | sortir un invariant de boucle, puis supprimer la boucle | rien — c'est un gain net |
| 2 | `PitchClassSet.IntervalClassVector` | compter les paires avec `PopCount`, puis précalculer les 4096 | un défaut arithmétique documenté qu'il faut **conserver** |
| 3 | `PitchClassSet.ClosestDiatonicKey` | supprimer un dictionnaire que personne ne lit | une égalité tranchée par la stabilité du tri, à reproduire exactement |
| 4 | `PitchClassSet.ToNormalForm` | faire tourner des bits au lieu de construire des ensembles triés | une règle de compacité qui n'est pas celle des manuels |
| 5 | `PitchClassSetId.PrimeForm` | la même arithmétique, puis une table | rien — c'était déjà de l'arithmétique sur les bits |

Tout repose sur une représentation, qu'il vaut la peine d'énoncer une fois. Le bit *p* du nombre vaut 1 quand la classe de hauteur *p* est dans l'ensemble. Transposer de *n* demi-tons, c'est faire tourner ces douze bits de *n* : rien n'est ajouté ni retiré, l'anneau tourne. « Combien de classes de hauteurs satisfont X » est un comptage de bits, soit une instruction. Et le domaine est assez petit pour que n'importe quelle fonction d'un ensemble soit tabulée au démarrage.

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

| Méthode | Les 4096 ensembles | Par ensemble | Rapport |
|---|---|---|---|
| `Ga` | 9,582 µs | 2,34 ns | 1,00 |
| `Fast` | 2,378 µs | 0,58 ns | 0,25 |

**Quatre fois, pas trente.** C'est le membre pour lequel la mesure honnête est la moins flatteuse, et cela vaut la peine de s'y arrêter : les mêmes deux méthodes, mesurées un appel à la fois, annonçaient 3,25 ns contre 0,0107 ns et un rapport de 0,003. Aucune des deux versions n'alloue. La boucle de GA sort tôt dès qu'elle trouve un cluster — 2 597 des 4096 ensembles en ont un — donc elle fait en moyenne bien moins de douze itérations, et le prédicteur de branchement l'apprend.

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
        // Le bit p du ET vaut 1 quand p et p + ic sont tous deux dans l'ensemble : un bit par paire
        var count = BitOperations.PopCount((uint)(set & Rotr12(set, ic)));

        // Le triton est son propre complément : le ET a compté chaque paire par les deux bouts
        if (ic == 6) count /= 2;

        // L'empaquetage de GA : décaler les chiffres d'un rang en base 12 et ajouter ce compte
        value = value * 12 + count;
    }
    return value;
}
```

Et comme le domaine compte 4096 valeurs, tout cela peut se faire une fois pour toutes, au démarrage :

```csharp
public static readonly int[] IntervalClassVectorIds =
    [.. Enumerable.Range(0, 4096).Select(IntervalClassVectorId)];
```

| Méthode | Les 4096 ensembles | Par ensemble | Alloué, par ensemble | Rapport |
|---|---|---|---|---|
| `Ga` | 18,747 ms | 4 577 ns | 13 513 o | 1,000 |
| `Computed` | 15,480 µs | 3,78 ns | — | 0,001 |
| `Table` | 828,4 ns | 0,20 ns | — | 0,00004 |

**Lire cette propriété pour les 4096 ensembles alloue 55 Mo.** Mille fois plus rapide en calculant à chaque appel, vingt-deux mille fois depuis la table, et l'allocation tombe à zéro. C'est ce dernier chiffre qui compte dans un service : le constructeur statique de `PitchClassSet` construit lui-même un index des 4096 ensembles clé par cette propriété, et `SetClass.ToString()` l'appelle, si bien que chaque ligne de journal nommant une classe d'ensembles le payait.

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
    // `Id` est une propriété stockée, pas calculée : les douze bits de l'ensemble sont gratuits
    var mask = set.Id.Value;

    // L'égalité tranchée par GA : un ensemble dont la forme normale contient la classe 3 est
    // attendu mineur. Ici c'est une lecture de tableau, car la section 4 a tabulé toutes les formes normales.
    var expectMinor = (NormalFormMasks[mask] & (1 << 3)) != 0;

    var best = Keys[0];
    var bestScore = -1;
    var bestExpected = false;
    foreach (var candidate in Keys)
    {
        // Le ET garde les notes de la tonalité que l'ensemble contient : c'est le `Matches.Count` de GA
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

| Méthode | Les 4096 ensembles | Par ensemble | Alloué, par ensemble | Rapport |
|---|---|---|---|---|
| `Ga` | 279,681 ms | 68,28 µs | 175 650 o | 1,000 |
| `Fast` | 173,2 µs | 42,3 ns | — | 0,001 |

**175 kilo-octets pour lire une propriété**, et 719 Mo pour la lire sur chaque ensemble du domaine. Mille six cents fois plus rapide, et rien d'alloué.

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

## 4. La forme normale, qui se cachait dans la précédente

Le paragraphe ci-dessus utilisait `NormalFormMasks`, et c'est cette table qui fait que le `ClosestDiatonicKey` rapide n'alloue rien. Avant qu'elle existe, la réécriture appelait encore `set.ToNormalForm()`, et cet unique appel constituait la totalité des 16 Ko qui lui restaient.

Le `ToNormalForm` de GA transpose l'ensemble une fois par membre, de façon à poser ce membre sur 0, et garde la transposition dont la suite d'écarts circulaires a le plus petit *plus grand écart moins plus petit écart*, les égalités étant tranchées lexicographiquement sur les écarts. Cela mérite d'être relu, car ce n'est **pas** la forme normale des manuels, qui minimise l'étendue de la première classe de hauteur à la dernière ; les remarques de GA le disent elles-mêmes. La réécriture doit reproduire la règle de GA, pas celle des livres.

Le coût n'est pas la règle, c'est ce dont la règle est faite — un `ImmutableSortedSet` par rotation, deux `ImmutableArray` d'écarts par comparaison, une `List<PitchClass>` pour le tenant du titre et un `PitchClassSet` pour la réponse. Une transposition est une rotation et les écarts se lisent sur les bits, donc tout cela tient dans deux tampons de pile :

```csharp
public static int NormalFormMask(int set)
{
    if (set == 0) return 0;

    Span<int> gaps = stackalloc int[12];
    Span<int> bestGaps = stackalloc int[12];
    var count = BitOperations.PopCount((uint)set);
    var best = 0;
    var bestSpan = int.MaxValue;

    // Croissant, car GA énumère un ImmutableSortedSet et garde la rotation vue en premier
    for (var member = 0; member < 12; member++)
    {
        if ((set & (1 << member)) == 0) continue;

        // Transposer pour que ce membre tombe sur 0, c'est faire tourner l'ensemble de `member` vers le bas
        var rotation = Rotr12(set, member);
        Gaps(rotation, count, gaps);
        var span = Span(gaps, count);

        // Une étendue plus petite gagne toujours ; à étendue égale, la suite d'écarts la plus petite
        if (span > bestSpan) continue;
        if (span == bestSpan && !MoreCompact(gaps, bestGaps, count)) continue;

        best = rotation;
        bestSpan = span;
        gaps[..count].CopyTo(bestGaps);
    }

    return best;
}
```

Un détail mérite d'être conservé même s'il ne change rien. GA mesure chaque écart par `(pitchClasses[(i + 1) % n] - pitchClasses[i])`, donc pour un ensemble d'une seule note le seul écart est la distance du membre à lui-même — **0**, et non les douze demi-tons que suggérerait un « écart circulaire ». La réécriture fait pareil, et la vérification exhaustive est ce qui prouve que le choix est gratuit : un ensemble d'une note n'a qu'une rotation, donc aucune comparaison n'a lieu et les deux lectures donnent la même réponse pour les douze. C'est le genre de chose qu'il vaut mieux savoir que supposer, et le seul moyen de le savoir est d'exécuter toutes les entrées.

| Méthode | Les 4096 ensembles | Par ensemble | Alloué, par ensemble | Rapport |
|---|---|---|---|---|
| `Ga` | 11,085 ms | 2 706 ns | 6 657 o | 1,000 |
| `Computed` | 1,172 ms | 286 ns | — | 0,106 |
| `Table` | 834,5 ns | 0,20 ns | — | 0,00008 |

Remarquez l'écart entre `Computed` et `Table` ici. La réécriture n'est que 9,5 fois plus rapide que celle de GA, car contrairement au vecteur de classes d'intervalles elle fait encore un vrai travail à chaque appel — jusqu'à douze rotations et une comparaison lexicographique. C'est ce qui rend la table digne de ses 16 Ko : le coût n'est pas seulement dans les allocations.

```text
== Normal form and prime form, on the same sets
set                          GA's normal form         prime form
major scale                  0 1 3 5 6 8 T            0 1 3 5 6 8 T
C major triad                0 3 8                    0 3 7
whole tone                   0 2 4 6 8 T              0 2 4 6 8 T
chromatic aggregate          0 1 2 3 4 5 6 7 8 9 T E  0 1 2 3 4 5 6 7 8 9 T E
```

La deuxième ligne est la règle de GA qui se montre à découvert : la forme normale de l'accord parfait de do majeur est `0 3 8`, alors que sa forme première est `0 3 7`. Les écarts de `0 3 8` sont 3, 5, 4 — une étendue de 2 — contre 4, 3, 5 pour `0 4 7`, étendue de 2 également, et `3 5 4` gagne l'égalité lexicographique contre `4 3 5`. Une forme normale de manuel aurait répondu `0 4 7`.

## 5. PrimeForm, qui était déjà juste

Le `PitchClassSetId.PrimeForm` de GA est le seul membre ici qui n'avait pas besoin d'être repensé. C'est déjà de l'arithmétique pure sur l'identifiant — le plus petit des douze transpositions et des douze transpositions de l'inversion — et il n'alloue rien :

```csharp
var min = Value;
var inverse = Inverse;
for (var i = 0; i < 12; i++)
{
    var t = Transpose(i).Value;
    if (t < min) min = t;

    var ti = inverse.Transpose(i).Value;
    if (ti < min) min = ti;
}
```

Ce qu'il paie, c'est l'emballage. `Inverse` est une propriété qui exécute une boucle de douze itérations pour refléter les bits ; `Transpose` est appelé 24 fois, chaque appel construisant un `PitchClassSetId` par un constructeur qui vérifie l'intervalle de son argument. Écrire la même arithmétique sur des `int` nus est 1,8 fois plus rapide, et la table 415 fois :

| Méthode | Les 4096 ensembles | Par ensemble | Rapport |
|---|---|---|---|
| `Ga` | 347,4 µs | 84,8 ns | 1,000 |
| `Computed` | 193,9 µs | 47,3 ns | 0,562 |
| `Table` | 836,9 ns | 0,20 ns | 0,002 |

Un facteur 1,8 pour avoir réécrit une méthode déjà correcte, c'est le plafond honnête du « micro-optimiser l'arithmétique », et cela mérite d'être posé à côté du 1 600× de la section 3. Les grands gains de cette annexe ne viennent pas d'astuces sur les bits. Ils viennent de la suppression d'un travail dont personne n'avait besoin : un dictionnaire que personne ne lit, un produit cartésien construit pour compter six nombres, un ensemble trié par rotation.

## Ce qu'affiche la vérification exhaustive

```text
== Exhaustive check: all 4096 twelve-bit pitch-class sets
member                       agree              verdict
IsClusterFree                4096/4096          identical
IntervalClassVector.Id       4096/4096          identical
ClosestDiatonicKey           4096/4096          identical
ToNormalForm                 4096/4096          identical
PrimeForm                    4096/4096          identical
sets with no chromatic cluster: 1499 of 4096
```

Cinq lignes, et ce sont elles qui autorisent à citer les chronomètres ci-dessus. `ClosestDiatonicKey` est comparé sur la forme *texte* de la tonalité plutôt que par égalité de record, pour qu'un changement dans la façon dont `Key` se compare à elle-même ne puisse pas masquer une différence.

## Les mesures

[BenchmarkDotNet](https://benchmarkdotnet.org/) v0.15.8, une classe de benchmarks à la fois sur une machine par ailleurs au repos :

```text
BenchmarkDotNet v0.15.8, Windows 11 (10.0.26200.9445/25H2/2025Update/HudsonValley2)
Intel Core Ultra 9 285K 3.70GHz, 1 CPU, 24 logical and 24 physical cores
.NET SDK 10.0.112
  [Host]     : .NET 10.0.12 (10.0.12, 10.0.1226.42308), X64 RyuJIT x86-64-v3
  DefaultJob : .NET 10.0.12 (10.0.12, 10.0.1226.42308), X64 RyuJIT x86-64-v3
```

### Le benchmark qu'il a fallu jeter

La première version de ces benchmarks faisait la chose évidente : un appel par méthode `[Benchmark]`, sur la gamme majeure. Elle annonçait ceci pour `IsClusterFree` :

```text
| Method | Mean      | Ratio |
| Ga     | 3.2472 ns |  1.000 |
| Fast   | 0.0107 ns |  0.003 |
```

0,0107 ns sur un processeur à 3,7 GHz, c'est un vingt-cinquième de cycle. Aucune méthode ne s'exécute en un vingt-cinquième de cycle. L'argument était une `const`, donc le JIT a replié tout l'appel en un littéral, et ce qui était mesuré, c'était le repliement.

Un champ `static readonly` n'aurait pas aidé non plus : le JIT les promeut en constantes une fois la compilation par niveaux stabilisée. En faire un `static int` mutable a supprimé le repliement et a quand même produit 0,0474 ns avec une **médiane de 0,0000 ns** : sous la résolution de la technique, parce que BenchmarkDotNet soustrait le coût d'une méthode vide et qu'il ne restait rien.

Chaque benchmark balaie donc le domaine entier, en accumulant une valeur que le JIT ne peut pas déclarer morte :

```csharp
[Benchmark]
public int Fast()
{
    var count = 0;
    for (var id = 0; id < 4096; id++)
    {
        if (GaFast.IsClusterFree(id)) count++;
    }
    return count;
}
```

Le compteur de boucle est l'entrée, donc rien ne peut être replié ; chaque méthode a des millisecondes ou des microsecondes de vrai travail ; et les colonnes « par ensemble » ci-dessus sont la moyenne divisée par 4096. Que les trois lignes `Table` tombent sur 828,4 ns, 834,5 ns et 836,9 ns — le même nombre trois fois, pour trois tables différentes — est le plancher de la technique : une lecture de tableau avec vérification de bornes et une itération de boucle, environ 0,20 ns, incluse dans chaque chiffre de cette annexe.

Ce n'est pas une note de bas de page. Le benchmark jeté aurait publié « trente et une fois plus rapide » pour un membre qui l'est quatre fois, et cela aurait eu l'air plus impressionnant que tout ce que l'annexe a réellement trouvé.

### Les allocations

Celles-ci n'ont rien de statistique :

```text
# GA   IntervalClassVector.Id.Value    16,432 bytes
# fast IntervalClassVectorIds[id]           0 bytes
# GA   IsClusterFree                        0 bytes
# fast IsClusterFree                        0 bytes
# GA   ClosestDiatonicKey             179,848 bytes
# fast ClosestDiatonicKey                   0 bytes
# GA   ToNormalForm                     8,000 bytes
# fast NormalFormMask                       0 bytes
# GA   PrimeForm                        1,704 bytes
# fast PrimeFormIds[id]                     0 bytes
```

Elles viennent de [`GC.GetAllocatedBytesForCurrentThread`](https://learn.microsoft.com/dotnet/api/system.gc.getallocatedbytesforcurrentthread) autour d'un appel unique, après un appel de chauffe qui a exécuté les constructeurs statiques — la technique de la [leçon 1](../01-memory-values-and-spans/). Elles dépendent assez de la machine pour être affichées avec un préfixe `# ` et exclues de la comparaison, et sont assez stables pour mériter d'être affichées. Elles sont plus élevées que les chiffres « par ensemble » des tableaux, qui sont les moyennes de `[MemoryDiagnoser]` sur tout le balayage, son propre surcoût déduit ; un appel isolé, un peu froid, coûte un peu plus que la moyenne de 4096.

La CI exécute chaque classe de benchmarks avec `--job Dry`, qui vérifie qu'elles tournent encore et ne mesure rien, parce que les temps d'un runner partagé sont du bruit.

## Points à retenir

- Le domaine d'entrée d'un ensemble de 12 bits compte 4096 valeurs. Quand le domaine est aussi petit, « je l'ai testé » devrait vouloir dire *en entier*, et ce test a sa place dans la CI, à côté du benchmark.
- Une réécriture qui renvoie une autre réponse n'est la version rapide de rien du tout. Le report en base 12 de GA est un vrai défaut et la version rapide le reproduit ; l'écart nul d'un ensemble d'une seule note aussi.
- **Mesurez votre mesure.** Un chiffre sous le cycle n'est pas un résultat, c'est un bug dans la mesure : un argument `const` ou `static readonly` est replié, et la soustraction du surcoût par BenchmarkDotNet emporte le reste. Balayez un domaine, accumulez un résultat, et divisez.
- Les grands gains sont venus de la suppression de travail, pas d'astuces sur les bits : un dictionnaire dont les valeurs ne sont jamais lues, un produit cartésien construit pour compter six nombres, un ensemble trié par rotation. Réécrire une arithmétique déjà correcte a rapporté 1,8×.
- Une propriété sans cache est une méthode au nom trompeur. `IntervalClassVector` et `Key.Items` reconstruisent tout à chaque accès, et toutes deux sont lues dans des boucles ailleurs dans GA.

## Sources

- BenchmarkDotNet : [comment il fonctionne](https://benchmarkdotnet.org/articles/guides/how-it-works.html), [bonnes pratiques](https://benchmarkdotnet.org/articles/guides/good-practices.html).
- Microsoft Learn : [`BitOperations.PopCount`](https://learn.microsoft.com/dotnet/api/system.numerics.bitoperations.popcount), [`GC.GetAllocatedBytesForCurrentThread`](https://learn.microsoft.com/dotnet/api/system.gc.getallocatedbytesforcurrentthread), [`Enumerable.OrderByDescending`](https://learn.microsoft.com/dotnet/api/system.linq.enumerable.orderbydescending), [`BigInteger`](https://learn.microsoft.com/dotnet/api/system.numerics.biginteger), [`stackalloc`](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/stackalloc).
- Guitar Alchemist au commit `a826864` : [`PitchClassSetId.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClassSetId.cs#L42-L57) et sa [`PrimeForm`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClassSetId.cs#L133-L156), [`PitchClassSet.ToNormalForm`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClassSet.cs#L412-L475) et [`FindClosestDiatonicKey2`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClassSet.cs#L597-L658), [`AtonalExtensions.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/AtonalExtensions.cs#L28-L35), [`VariationsWithRepetitions.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/Combinatorics/VariationsWithRepetitions.cs#L55-L73), [`Key.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Tonal/Key.cs#L49-L50).
- Le code du cours : [`GaFast.cs`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/Advanced/GaFast.cs), [`Appendix1.cs`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/Advanced/Appendix1.cs), [`GaBenchmarks.cs`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/Benchmarks/GaBenchmarks.cs), [`expected/a1.txt`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/expected/a1.txt).
- Le même code lu comme de la musique, et non comme de la performance : [Théorie musicale pour Guitar Alchemist](../../music-theory-ga/), en particulier la [leçon 4](../../music-theory-ga/04-set-classes/), la [leçon 7](../../music-theory-ga/07-cadences-and-progressions/) et [son annexe C](../../music-theory-ga/appendix-ga-findings/).
