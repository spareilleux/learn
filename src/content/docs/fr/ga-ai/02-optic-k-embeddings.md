---
title: "Leçon 2 : les embeddings OPTIC-K"
description: Les 240 nombres que Guitar Alchemist calcule pour chaque forme d'accord — les partitions et leurs poids, l'historique des versions, les vrais vecteurs de six accords ouverts, la similarité pondérée calculée à la main, ce à quoi le vecteur est invariant, et deux bugs de records positionnels qui l'aplatissent.
sidebar:
  label: 2. Embeddings OPTIC-K
  order: 2
---

Un **embedding** (plongement vectoriel) est un tableau de nombres qui décrit un objet, construit de sorte que des objets semblables reçoivent des tableaux semblables. Les embeddings de texte sortent d'un réseau de neurones, et personne ne peut dire ce que signifie la dimension 417. OPTIC-K est l'inverse : chacun de ses 240 nombres est calculé par du code C# à partir de la théorie musicale, et porte un nom. C'est donc un bon premier embedding à étudier, parce que chaque nombre peut être vérifié. Cette leçon calcule les vecteurs de six accords avec les classes mêmes de GA, et les vérifie.

Tous les liens vers GA pointent sur le commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6). Les sorties viennent de :

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l2
```

## D'où vient le nom

En 2008, Clifton Callender, Ian Quinn et Dmitri Tymoczko ont décrit les objets musicaux par les équivalences qu'on choisit d'ignorer : **O**ctave, **P**ermutation (l'ordre des notes), **T**ransposition, **I**nversion et **C**ardinalité (les notes doublées) ([*Generalized Voice-Leading Spaces*](https://doi.org/10.1126/science.1153021)). Si l'on ignore l'octave et l'ordre, un accord devient un ensemble de classes de hauteurs ; si l'on ignore aussi la transposition et l'inversion, il devient une classe d'ensembles, le sujet de la leçon 4 du [cours de théorie musicale](../../music-theory-ga/04-set-classes/). GA ajoute un **K**, pour la complémentarité, et donne à son embedding le nom de cette liste. Les commentaires de [`TheoryVectorService`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/Services/TheoryVectorService.cs#L41-L77) associent chaque bloc de nombres aux lettres qu'il est censé couvrir.

## Le schéma

[`EmbeddingSchema.Partitions`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/EmbeddingSchema.cs#L117-L137) est le registre que chaque consommateur est censé lire : pour chaque partition, un nom, une plage parmi les 240 emplacements, un poids et un rôle.

```text
== EmbeddingSchema.Partitions (OPTIC-K-v1.8)
partition     raw      dims  role        weight
IDENTITY      0-5      6     Identity    0.00
STRUCTURE     6-29     24    Similarity  0.45
MORPHOLOGY    30-53    24    Similarity  0.25
CONTEXT       54-65    12    Similarity  0.20
SYMBOLIC      66-77    12    Similarity  0.10
EXTENSIONS    78-95    18    Info        0.00
SPECTRAL      96-108   13    Info        0.00
MODAL         109-148  40    Similarity  0.10
HIERARCHY     149-163  15    Info        0.00
ATONAL_MODAL  164-227  64    Info        0.00
ROOT          228-239  12    Similarity  0.05
TotalDimension          240
sum of dims             240
sum of weights          1.15
CompactDimension        124
CompactLayoutV4         optk-v4-pp-r:STRUCTURE:0-23,MORPHOLOGY:24-47,CONTEXT:48-59,SYMBOLIC:60-71,MODAL:72-111,ROOT:112-123
SchemaHashV4            0x37CD8ECF
```

Ce que décrit chaque partition, d'après le générateur et ses services :

| Partition | Décrit | Calculée à partir de |
|---|---|---|
| STRUCTURE | quelles classes de hauteurs, combien, le vecteur d'intervalles | l'ensemble des notes, sans octave ni ordre |
| MORPHOLOGY | la forme sur le manche : basse et note la plus aiguë, écart, position, barré | le voicing physique |
| CONTEXT | fonction harmonique, tension, mouvement | l'analyse de l'accord |
| SYMBOLIC | des étiquettes comme la technique et le style | les étiquettes de l'analyse |
| MODAL | à quel point l'accord évoque chaque mode : 40 emplacements, dont 33 portent le nom d'un mode | les notes, relativement à une fondamentale |
| ROOT | la classe de hauteur de la fondamentale, en encodage one-hot | la fondamentale |
| IDENTITY, EXTENSIONS, SPECTRAL, HIERARCHY, ATONAL_MODAL | type d'objet, caractéristiques psychoacoustiques et spectrales, complexité, familles de la théorie des ensembles | stockées, jamais notées |

Trois choses à remarquer :

- **Seules les six partitions « Similarity » servent à la recherche.** Ensemble, elles contiennent 124 nombres, la `CompactDimension`. Les cinq autres sont des informations pour d'autres outils ; le fichier d'index ne les stocke même pas (leçon 3).
- **Les poids font 1.15 au total, pas 1.** Un vecteur comparé à lui-même obtient donc 1.15, comme le montre la sortie plus bas. Rien ne casse, puisque seul le classement compte, mais un score n'est pas un cosinus au sens habituel, entre 0 et 1.
- **La chaîne de disposition est hachée.** `SchemaHashV4` est le [CRC-32](https://learn.microsoft.com/dotnet/api/system.io.hashing.crc32) de `CompactLayoutV4` ([lignes 154-186](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/EmbeddingSchema.cs#L154-L186)). Le ticket [#616](https://github.com/GuitarAlchemist/ga/issues/616) rapporte `0x37CD8ECF` pour l'index en production de GA, avec 313 047 voicings : le cours et cet index utilisent la même disposition.

À côté du registre, `EmbeddingSchema` garde d'anciennes constantes pour chaque partition. Trois d'entre elles ne correspondent plus :

```text
== Loose constants next to the registry
constant                 value      registry
HierarchyDim             8          15
AtonalModalDim           17         64
ExtensionsEnd            96         240
```

`ExtensionsEnd` est juste, 96 est bien là où finit EXTENSIONS, mais son [commentaire](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/EmbeddingSchema.cs#L406-L407) dit qu'elle vaut `TotalDimension`, ce qui était vrai quand le vecteur avait 96 nombres. Les deux autres comptent davantage : [`ModalVectorService`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/Services/ModalVectorService.cs#L116) alloue son tableau ATONAL_MODAL avec `AtonalModalDim`, 17, et [`WriteInto`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/EmbeddingSchema.cs#L219-L220) copie la longueur qu'on lui donne sans se plaindre : 47 des 64 emplacements de cette partition ne peuvent donc jamais valoir autre chose que zéro. La leçon 3 en trouve exactement 47 sur un corpus entier.

## Versions

Le schéma a grandi en ajoutant des partitions à la fin. L'historique ci-dessous vient des [documents du schéma](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Documentation/Schema) de GA, des commentaires de version de `EmbeddingSchema.cs` et de deux commits :

| Version | Dimensions | Ce qui a changé | Source |
|---|---|---|---|
| v1.2.1 | 96 | EXTENSIONS ajoutée ; « indices 0–77 are unchanged », les indices 0 à 77 sont inchangés | `OPTIC-K_Embedding_Schema_v1.2.1.md`, daté du 2026-01-11 |
| v1.3, v1.3.1 | 108, 109 | SPECTRAL, puis l'entropie spectrale à l'indice 108 | `OPTIC-K_Embedding_Schema_v1.3.md`, `_v1.3.1.md` |
| v1.4 | 216 | indices 0 à 135 définis, le reste réservé | `OPTIC-K_Embedding_Schema_v1.4.1.md`, daté du 2026-01-21 |
| v1.6 | | MODAL et HIERARCHY | commentaires de `EmbeddingSchema.cs` |
| v1.7 | 228 | ATONAL_MODAL | commentaires de `EmbeddingSchema.cs` |
| v1.8 | 240 | ROOT ajoutée ; le bonus de fondamentale retiré de STRUCTURE | commit [`95b5a9d9`](https://github.com/GuitarAlchemist/ga/commit/95b5a9d9), 2026-04-19 |

Le format d'index a sa propre histoire : v4 normalisait tout le vecteur compact d'un coup, v4-pp normalise chaque partition séparément (commit [`3ba35365`](https://github.com/GuitarAlchemist/ga/commit/3ba35365), 2026-04-19), et v4-pp-r ajoute ROOT, ce qui a fait passer la taille compacte de 112 à 124.

La documentation n'a pas suivi. Le document de schéma le plus récent s'arrête à v1.4.1, et celui dont le nom ne porte pas de version, `OPTIC-K_Embedding_Schema.md`, décrit v1.3.1 et 109 dimensions. Dans le code, le résumé du générateur dit encore « 228-dimensional canonical musical embedding (v1.7) » ([ligne 13](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/MusicalEmbeddingGenerator.cs#L13)) et sa propriété `Dimension` « 216 for v1.4/v1.5 » ([ligne 55](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/MusicalEmbeddingGenerator.cs#L55)), alors que les deux renvoient 240. Quand un commentaire et le registre divergent, fais confiance au registre, et mieux encore, affiche-le.

## D'une forme d'accord à un document

Les guitaristes écrivent les formes d'accords de la corde de mi grave à la corde de mi aigu : `x32010` est le C ouvert, avec le mi grave étouffé. GA numérote les cordes dans l'autre sens, à partir du mi aigu, la corde 1, et son générateur de voicings construit les positions dans cet ordre. [`Voicings.FromShape`](https://github.com/spareilleux/learn/blob/8e335d7/code/ga-ai/GaAi/Voicings.cs#L39-L64), dans le cours, convertit un diagramme dans l'ordre de GA, puis [`Voicings.Embed`](https://github.com/spareilleux/learn/blob/8e335d7/code/ga-ai/GaAi/Voicings.cs#L97-L103) exécute les trois étapes qu'exécutent les outils de GA eux-mêmes :

```csharp
var analysis = VoicingAnalyzer.Analyze(voicing);
var doc = VoicingDocumentFactory.FromAnalysis(voicing, analysis, tuningId: "guitar");
var raw = Generator.GenerateEmbeddingAsync(doc).GetAwaiter().GetResult();
```

L'étape du milieu construit un `ChordVoicingRagDocument`, un record d'une cinquantaine de propriétés que lit le générateur. Six accords :

```text
== From a chord shape to GA's voicing document
shape   GA diagram   GA name       pcs      MIDI            doc root inv   rootless function
x32010  0-1-0-2-3-x  C             0 4 7    64 60 55 52 48  4 E      1     yes  Functional Harmony
x35553  3-5-5-5-3-x  C             0 4 7    67 64 60 55 48  7 G      2     yes  Functional Harmony
032010  0-1-0-2-3-0  C/E           0 4 7    64 60 55 52 48 40 4 E      1     yes  Functional Harmony
x32000  0-0-0-2-3-x  Cmaj7         0 4 7 11 64 59 55 52 48  4 E      1     yes  Functional Harmony
x02210  0-1-2-2-0-x  Am            0 4 9    64 60 57 52 45  4 E      2     yes  Functional Harmony
320003  3-0-0-0-2-3  G             2 7 11   67 59 55 50 47 43 7 G      0     yes  Functional Harmony
```

Les noms sont justes. La fondamentale du document ne l'est pas : c'est E pour le C ouvert et G pour le C barré. [`VoicingDocumentFactory`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Rag/VoicingDocumentFactory.cs#L37-L38) prend la première note MIDI à la fois comme fondamentale et comme basse :

```csharp
RootPitchClass = analysis.MidiNotes.Length > 0 ? analysis.MidiNotes[0] % 12 : 0,
MidiBassNote = analysis.MidiNotes.Length > 0 ? analysis.MidiNotes[0] : 0,
```

Comme les notes arrivent en commençant par la corde 1, `MidiNotes[0]` est la note **la plus aiguë**, la note de mélodie, ni la basse ni la fondamentale. La colonne du renversement est calculée à partir de cette note aussi : le C ouvert à l'état fondamental est présenté comme un premier renversement. La fondamentale à laquelle on la compare est lue par `PitchClass.Parse`, qui prend les noms de notes A et E pour les nombres 10 et 11 ([lignes 43-44](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Rag/VoicingDocumentFactory.cs#L43-L44)) : hors du programme du cours, un Em à l'état fondamental, `022000`, sort avec le renversement -1. Chaque partition qui lit `RootPitchClass` ou `MidiBassNote` hérite de l'erreur : ROOT, MODAL, une partie de MORPHOLOGY.

## Deux records positionnels

La colonne « rootless », sans fondamentale, dit oui pour les six accords, qui contiennent pourtant tous leur fondamentale. La cause est un motif que tout développeur C# devrait reconnaître. [`VoicingCharacteristics`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core/Analysis/Voicings/VoicingCharacteristics.cs#L3-L15) est un record positionnel de onze paramètres, et [`VoicingHarmonicAnalyzer`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Fretboard/Voicings/Analysis/VoicingHarmonicAnalyzer.cs#L31-L43) le construit avec des arguments positionnels :

```csharp
// Le record : (ChordId, DissonanceScore, Consonance, IntervalSpread, NoteCount,
//              IntervalClassVector, IsRootless, DropVoicing, IsOpenVoicing, Features, SemanticTags)
return new(
    chordId,
    dissonanceScore,
    consonance,
    intervalSpread,
    pitchClasses.Count,
    pcSet.IntervalClassVector.ToString(),
    intervalSpread > 12,
    dropVoicing,
    false,
    [],
    semanticTags
);
```

`intervalSpread > 12`, « les notes couvrent plus d'une octave », est la définition d'un **voicing ouvert**, et atterrit dans `IsRootless` ; la constante `false` atterrit dans `IsOpenVoicing`. Le compilateur ne peut rien objecter : les deux sont des `bool`. La même chose se produit un niveau plus haut, dans [`VoicingAnalyzer`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Fretboard/Voicings/Analysis/VoicingAnalyzer.cs#L164), avec un record déclaré comme `PerceptualQualities(double Brightness, double ConsonanceScore, double Roughness, string TexturalDescription, string Register)` :

```csharp
var perceptualQualities = new PerceptualQualities(curVoiceChars.Consonance, 0, 0, "Neutral", "Medium");
```

La consonance va dans `Brightness`, et `ConsonanceScore` vaut toujours 0. Le programme affiche les deux records pour les six accords :

```text
== VoicingCharacteristics and PerceptualQualities, as VoicingAnalyzer fills them
shape   span    IsRootless  IsOpen    Consonance  Brightness   ConsonanceScore
x32010  16      True        False     1.000       1.000        0.000
x35553  19      True        False     1.000       1.000        0.000
032010  24      True        False     1.000       1.000        0.000
x32000  16      True        False     1.000       1.000        0.000
x02210  19      True        False     1.000       1.000        0.000
320003  24      True        False     1.000       1.000        0.000
```

Le document copie `ConsonanceScore` dans sa propriété `Consonance`, et le générateur calcule la tension de CONTEXT comme `1.0 - doc.Consonance` ([ligne 102](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/MusicalEmbeddingGenerator.cs#L99-L104)). La tension vaut donc 1 pour chaque accord jamais indexé. Le ticket [#616](https://github.com/GuitarAlchemist/ga/issues/616) a mesuré la partition CONTEXT comme « vide », avec une dimension constante, et en a accusé les littéraux passés à côté ; la dimension constante est celle-ci, et sa cause est le record ci-dessus. Des arguments nommés, `new PerceptualQualities(Brightness: ..., ConsonanceScore: ...)`, auraient rendu les deux erreurs visibles à l'appel.

## Les 240 nombres du C ouvert

```text
== The 240 values of x32010 (C), partition by partition
IDENTITY       3/6   1 0 1 0 0 1
STRUCTURE     10/24  1 0 0 0 1 0 0 1 0 0 0 0 0.5 0 0 1 1 1 0 0 1 0.83 1 0
MORPHOLOGY     7/24  0 0 0 0 1 0 0 0 0 0 0 0 0.17 0.83 1 0.87 -0.5 0.33 0 0 0 0 0 0
CONTEXT        1/12  0 0 0 0 1 0 0 0 0 0 0 0
SYMBOLIC       4/12  1 1 0 0 0 0 0 0 0 1 0 1
EXTENSIONS     9/18  0 1 0.4 0 0 0.57 0.33 0.47 0.2 0 0 0 0.33 0 0 1 0.6 0
SPECTRAL      13/13  0.2 0.26 0.61 0.37 0.4 0.47 0.29 0.6 0.53 0.29 0.64 0.5 0.16
MODAL          2/40  0 0 0 0 0 0.43 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.67 (+13 zeros)
HIERARCHY      1/15  0.33 0 0 0 0 0 0 0 0 0 0 0 0 0 0
ATONAL_MODAL  11/64  0.2 0.5 0 1 0 0 0.33 0.33 0.33 0 0.03 0.44 0.67 1 0 0.88 (+48 zeros)
ROOT           1/12  0 0 0 0 1 0 0 0 0 0 0 0
MODAL slots set: Aeolian=0.43, LydianAugmentedSharp2=0.67
```

STRUCTURE se lit à la main, avec [`TheoryVectorService.ComputeEmbedding`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/Services/TheoryVectorService.cs#L27-L94) ouvert à côté :

| Emplacements | Valeurs | Signification |
|---|---|---|
| 0-11 | `1 0 0 0 1 0 0 1 0 0 0 0` | le chroma : classes de hauteurs 0, 4 et 7, C E G |
| 12 | `0.5` | cardinalité, 3 ÷ 12 × 2 |
| 13-18 | `0 0 1 1 1 0` | le vecteur d'intervalles `<001110>` d'une triade majeure |
| 19 | `0` | complémentarité, toujours passée à 0.0 |
| 20, 21 | `1`, `0.83` | consonance et brillance dérivées du vecteur |
| 22 | `1` | « une fondamentale est connue » |
| 23 | `0` | réservé |

La ligne CONTEXT est la tension constante de la section précédente, à l'emplacement 4 de [`ContextVectorService`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/Services/ContextVectorService.cs#L43-L52) ; les emplacements 6 à 11 sont « réservés » et jamais écrits. La ligne ROOT a son 1 à la classe de hauteur 4, E, la note la plus aiguë. Les emplacements MODAL sont eux aussi calculés relativement à une fondamentale, ce qui expliquerait pourquoi une triade de C majeur allume Aeolian, un mode mineur : lu depuis E, C E G devient E, G, C (une interprétation, *à vérifier* ligne par ligne dans `ModalVectorService`).

Neuf des emplacements nommés de MODAL ne sont remplis par aucun des 15 360 voicings du corpus de la leçon 3.

## La similarité à la main

GA compare deux vecteurs partition par partition : le cosinus de chaque partition de similarité, multiplié par son poids, puis additionné. [`WeightedPartitionCosine`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/EmbeddingSchema.cs#L277-L304) le fait avec [`TensorPrimitives.CosineSimilarity`](https://learn.microsoft.com/dotnet/api/system.numerics.tensors.tensorprimitives.cosinesimilarity), et ignore une partition entièrement nulle. Le cours affiche chaque cosinus par rapport au C ouvert :

```text
== Cosine per partition, and GA's weighted score, against open C
pair             structure  morphology  context  symbolic  modal  root   weighted  compact dot
x32010 x35553    1.000      0.348       1.000    1.000     0.000  0.000  0.837     0.837
x32010 032010    1.000      0.997       1.000    0.750     1.000  1.000  1.124     1.124
x32010 x32000    0.883      0.998       1.000    0.816     0.541  1.000  1.033     1.033
x32010 x02210    0.888      0.998       1.000    0.816     0.153  1.000  0.996     0.996
x32010 320003    0.776      0.496       1.000    0.671     0.000  0.000  0.740     0.740
open C with itself: 1.150
```

La première ligne, le C ouvert contre le C barré en troisième case, à la main :

`0.45 × 1.000 + 0.25 × 0.348 + 0.20 × 1.000 + 0.10 × 1.000 + 0.10 × 0.000 + 0.05 × 0.000 = 0.837`

Lu en musicien, le tableau surprend. Le C barré a exactement les notes du C ouvert, et pourtant il obtient moins que Am (0.996) et Cmaj7 (1.033). Sa STRUCTURE est identique ; ce qui le fait couler, ce sont ROOT et MODAL, tous deux calculés à partir de la note la plus aiguë, G au lieu de E, et sa forme de main différente. Le C ouvert et C/E, qui partagent leurs cinq cordes aiguës, obtiennent 1.124. Et CONTEXT vaut 1.000 sur chaque ligne : 0.20 de chaque score est une constante.

La dernière colonne est le produit scalaire des deux vecteurs compacts. [`ExtractCompact`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/EmbeddingSchema.cs#L241-L267) garde les six partitions de similarité, divise chacune par sa norme euclidienne et la multiplie par la racine carrée de son poids. Alors, pour une partition `p`, `(√w · a/|a|) · (√w · b/|b|) = w · cos(a, b)`, et le produit scalaire de deux vecteurs compacts est le score pondéré. C'est pour cela que l'index stocke des vecteurs compacts : un seul produit scalaire par voicing remplace six cosinus.

## Ce à quoi le vecteur est invariant

Le chroma de STRUCTURE ignore les octaves et l'ordre des notes : tout voicing de C E G reçoit les mêmes douze emplacements, c'est pourquoi le C barré y obtient 1.000. La transposition, c'est une autre affaire. Le cours compare la STRUCTURE de C majeur à ses onze transpositions, et à part, les emplacements 12 à 18, cardinalité et vecteur d'intervalles :

```text
== STRUCTURE of C major (0 4 7) against its 11 transpositions (TheoryVectorService)
T    pcs        structure  icv dims
1    1 5 8      0.665      1.000
2    2 6 9      0.665      1.000
3    3 7 10     0.776      1.000
4    4 8 11     0.776      1.000
5    0 5 9      0.776      1.000
6    1 6 10     0.665      1.000
7    2 7 11     0.776      1.000
8    0 3 8      0.776      1.000
9    1 4 9      0.776      1.000
10   2 5 10     0.665      1.000
11   3 6 11     0.665      1.000
set classes swept                 222
invariant (min cosine > 0.9999)   1
mean of the minimum cosines       0.881
worst minimum cosine              0.514
```

Les dimensions du vecteur d'intervalles ne bougent pas ; la partition entière, si, parce que le chroma nomme les notes elles-mêmes. Sur toutes les classes d'ensembles de deux notes ou plus, une seule est invariante, l'ensemble chromatique de douze notes, le seul ensemble égal à toutes ses transpositions. Ce sont les nombres du propre balayage de GA, [`state/quality/domain-invariants/README.md`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/state/quality/domain-invariants/README.md#L37-L47) : « 1 of 222 set classes is T-invariant », une classe d'ensembles sur 222 invariante par transposition, moyenne 0.88, pire cas 0.51. `TheoryVectorService` consigne ce résultat dans un [commentaire](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/Services/TheoryVectorService.cs#L57-L64) ; [`RootVectorService`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/Services/RootVectorService.cs#L3-L7) dit encore que sortir la fondamentale a rendu STRUCTURE « genuinely O+P+T+I-invariant », vraiment invariante par O, P, T et I.

OPTIC-K est donc invariant à l'octave et à l'ordre, comme le nom le promet, mais pas à la transposition ni à l'inversion : une recherche de « cette forme dans une autre tonalité » ne peut pas compter sur STRUCTURE.

## Un outil MCP, deux ordres de diagramme

GA expose le générateur aux assistants d'IA par un outil [MCP](https://modelcontextprotocol.io/), `ga_generate_voicing_embedding`. Sa [description](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingEmbeddingTool.cs#L42-L44) promet « a 228-dim OPTIC-K embedding vector » et donne l'exemple `'x-3-2-0-1-0' for Cmaj7`. Son [analyseur](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingEmbeddingTool.cs#L134-L173) lit le premier élément comme la corde 1, le mi aigu, comme le générateur de GA. Le cours copie cet analyseur et lui donne l'exemple :

```text
== ga_generate_voicing_embedding's example diagram, x-3-2-0-1-0
parsed by              GA diagram   MIDI             GA name          pcs
the MCP tool's parser  x-3-2-0-1-0  62 57 50 46 40   Dsus2/E          2 4 9 10
chord chart x32010     0-1-0-2-3-x  64 60 55 52 48   C                0 4 7
```

L'exemple est écrit comme un diagramme d'accord, mi grave en premier, et analysé mi aigu en premier : un assistant qui suit la description obtient le vecteur d'un autre accord. Écrit mi grave en premier, ce serait le C ouvert, et toujours pas Cmaj7. Le [cours de programmation agentique](../../agentic-coding/04-mcp/) en tire la leçon générale : la description d'un outil MCP fait partie de son interface, et le modèle la croit.

## Exercices

1. Avec le tableau des cosinus, calcule à la main le score pondéré du C ouvert contre G (`320003`), et compare-le à la sortie.
2. Pourquoi le C ouvert contre Am obtient-il 1.000 sur ROOT, alors que leurs fondamentales sont C et A ?
3. Les poids font 1.15 au total. Sans rien changer au code, comment transformerais-tu un score de GA en un nombre entre 0 et 1, et cela changerait-il un résultat de recherche ?
4. Réécris l'appel à `PerceptualQualities` de `VoicingAnalyzer` avec des arguments nommés, en gardant l'intention évidente de l'auteur.

<details>
<summary>Solutions</summary>

1. `0.45 × 0.776 + 0.25 × 0.496 + 0.20 × 1.000 + 0.10 × 0.671 + 0.10 × 0.000 + 0.05 × 0.000 = 0.3492 + 0.124 + 0.20 + 0.0671 = 0.740`, la valeur affichée.
2. Parce que la fondamentale du document est la note la plus aiguë, et que les deux formes ont E en haut, `64` dans leurs listes MIDI. L'encodage one-hot de ROOT a son 1 à la classe de hauteur 4 pour les deux.
3. Diviser par 1.15, la somme des poids, ou par le score d'un vecteur avec lui-même. Aucun classement ne change, puisque chaque score est divisé par la même constante. Cela ne compte que là où un score est comparé à un seuil fixe.
4. `new PerceptualQualities(Brightness: 0, ConsonanceScore: curVoiceChars.Consonance, Roughness: 0, TexturalDescription: "Neutral", Register: "Medium")`. « Garder l'intention » est une supposition : la brillance devait peut-être être calculée aussi. Avec des arguments nommés, la question est au moins visible en revue de code.

</details>

## À retenir

- OPTIC-K est un embedding construit à la main : 240 nombres nommés en 11 partitions, dont 6 partitions et 124 nombres servent à la similarité, avec des poids dont la somme fait 1.15.
- La similarité est une somme pondérée de cosinus par partition ; stocker chaque partition normalisée et multipliée par la racine carrée de son poids la transforme en un seul produit scalaire.
- Le vecteur est invariant à l'octave et à l'ordre des notes, pas à la transposition : le chroma de STRUCTURE nomme les notes.
- Au commit `a826864`, la fondamentale du document est la note la plus aiguë, deux records positionnels rangent des valeurs aux mauvais endroits, et CONTEXT est une constante : les vecteurs sont déterministes, mais plusieurs partitions ne signifient pas ce que dit leur nom.
- Les commentaires et les documents décrivent d'anciennes versions (96, 109, 216, 228 dimensions) ; le registre, et un programme qui l'affiche, sont la source fiable.

## Sources

- Clifton Callender, Ian Quinn et Dmitri Tymoczko, ["Generalized Voice-Leading Spaces"](https://doi.org/10.1126/science.1153021), *Science* 320 (5874), 2008, p. 346-348.
- GuitarAlchemist/ga au commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6) : `Common/GA.Business.ML/Embeddings` (`EmbeddingSchema.cs`, `MusicalEmbeddingGenerator.cs`, `Services/TheoryVectorService.cs`, `Services/ContextVectorService.cs`, `Services/ModalVectorService.cs`, `Services/RootVectorService.cs`), `Common/GA.Business.ML/Rag/VoicingDocumentFactory.cs`, `Common/GA.Domain.Services/Fretboard/Voicings/Analysis` (`VoicingAnalyzer.cs`, `VoicingHarmonicAnalyzer.cs`), `Common/GA.Business.Core/Analysis/Voicings`, `Common/GA.Business.ML/Documentation/Schema`, `GaMcpServer/Tools/VoicingEmbeddingTool.cs`, `state/quality/domain-invariants/README.md` ; commits [`95b5a9d9`](https://github.com/GuitarAlchemist/ga/commit/95b5a9d9) et [`3ba35365`](https://github.com/GuitarAlchemist/ga/commit/3ba35365).
- Ticket de GA [#616](https://github.com/GuitarAlchemist/ga/issues/616), lu le 2026-09-14.
- Microsoft Learn : [TensorPrimitives.CosineSimilarity](https://learn.microsoft.com/dotnet/api/system.numerics.tensors.tensorprimitives.cosinesimilarity), [Records](https://learn.microsoft.com/dotnet/csharp/fundamentals/types/records), [Arguments nommés et facultatifs](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/named-and-optional-arguments), [Crc32](https://learn.microsoft.com/dotnet/api/system.io.hashing.crc32).
- Wikipédia, [Similarité cosinus](https://en.wikipedia.org/wiki/Cosine_similarity).
