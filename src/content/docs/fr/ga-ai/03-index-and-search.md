---
title: "Leçon 3 : l'index et la recherche"
description: Construire un petit index OPTIC-K avec l'écrivain même de Guitar Alchemist, lire son en-tête binaire octet par octet, le mapper en mémoire, y chercher par chiffrage d'accord, et mesurer lesquelles de ses 124 dimensions ne varient jamais.
sidebar:
  label: 3. L'index et la recherche
  order: 3
---

L'index de voicings en production de GA contient 313 047 voicings de guitare, de basse et de ukulélé. Le construire prend des minutes et un clone du dépôt entier ; cette leçon en construit donc un petit avec le même code : chaque voicing de trois notes ou plus dans les trois premières cases d'une guitare. Le fichier a le même format, le même en-tête et la même recherche, et chaque nombre de cette leçon en vient.

Tous les liens vers GA pointent sur le commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6). Les sorties viennent de :

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l3
```

## Le corpus

[`VoicingGenerator.GenerateAllVoicingsAsync`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Fretboard/Voicings/Generation/VoicingGenerator.cs#L156) fait glisser une fenêtre de quelques cases le long du manche et produit chaque combinaison de cordes jouées et étouffées. Chaque voicing passe ensuite par les trois étapes de la leçon 2, les mêmes appels que la boucle d'export de GA dans [`FretboardVoicingsCLI`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Demos/Music%20Theory/FretboardVoicingsCLI/Program.cs#L813-L839), moins sa déduplication :

```text
== Corpus: GA's VoicingGenerator, standard tuning, 3 frets, window 3, at least 3 notes
voicings                 15360
  with 3 notes           1280
  with 4 notes           3840
  with 5 notes           6144
  with 6 notes           4096
first three, as generated:
diagram        MIDI (in order)    GA name      doc root
0-0-0-x-x-x    64 59 55           Em/G         E
1-0-0-x-x-x    65 59 55           G7(shell)    F
2-0-0-x-x-x    66 59 55           Gmaj7(shell) F#
```

Les effectifs servent de vérification : un manche de 3 cases a les cases 0 à 3, quatre choix pour chaque corde jouée, donc les voicings de six notes sont `4⁶ = 4096`, et ceux de cinq notes `6 × 4⁵ = 6144`, avec six façons de choisir la corde étouffée. Les diagrammes commencent à la corde 1, le mi aigu, et la « doc root » est encore la note la plus aiguë de chaque forme. Le [skill `optic-k-rebuild`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/.claude/skills/optic-k-rebuild/SKILL.md) de GA donne l'échelle du vrai index : environ 667 000 voicings de guitare bruts, 298 000 après déduplication, environ 140 secondes.

## Le format du fichier

[`OptickIndexWriter`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Demos/Music%20Theory/FretboardVoicingsCLI/OptickIndexWriter.cs) prend une liste de `VoicingEntry(float[] Embedding, string Diagram, string Instrument, int[] MidiNotes, string? QualityInferred)` et écrit un fichier. Le cours relit son en-tête avec un `BinaryReader`, champ par champ, dans l'ordre où [`WriteHeader`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Demos/Music%20Theory/FretboardVoicingsCLI/OptickIndexWriter.cs#L233-L258) les écrit :

```text
== The header OptickIndexWriter wrote (little-endian)
magic                    OPTK
format version           4
header size              616
schema hash              0x37CD8ECF
endian marker            0xFEFF
dimension                124
voicings                 15360
instruments              3
  guitar   offset 123496, count 15360
  bass     offset 7742056, count 0
  ukulele  offset 7742056, count 0
metadata offsets at      616
vectors at               123496 (15360 x 124 x 4 bytes = 7618560)
metadata at              7742056 (1233243 bytes of msgpack)
sqrt weights, first dims 0.67 0.67 0.67 ... ROOT 0.22
file size                8975299 bytes
```

La disposition, section par section :

| Octets | Contenu |
|---|---|
| 0 à 615 | l'en-tête : signature, version, empreinte du schéma, dimension, nombre de voicings, un décalage et un effectif par instrument, quatre décalages de section, puis 124 poids `float` |
| 616 à 123 495 | un décalage de 8 octets par voicing vers les métadonnées : `15,360 × 8 = 122,880` octets |
| 123 496 à 7 742 055 | les vecteurs : 124 `float` par voicing, les instruments l'un après l'autre |
| 7 742 056 à la fin | les métadonnées, un enregistrement [MessagePack](https://msgpack.org/) par voicing : diagramme, instrument, notes MIDI, nom |

Les poids de l'en-tête sont les racines carrées des poids des partitions : `√0.45 = 0.67`, `√0.05 = 0.22`. Le **marqueur de boutisme** `0xFEFF` permet à un lecteur sur une machine gros-boutiste de remarquer que les octets sont inversés. L'**empreinte du schéma** est le CRC-32 de la chaîne de disposition, vu à la leçon 2 ; [`OptickIndexReader`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/OptickIndexReader.cs#L64-L76) lève `InvalidDataException` quand elle ne correspond pas à la sienne, si bien qu'un programme compilé avec une autre disposition ne peut pas lire en silence de mauvais nombres. Le résumé de l'écrivain dit encore qu'il garde « the 112 search-relevant dims » ([ligne 11](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Demos/Music%20Theory/FretboardVoicingsCLI/OptickIndexWriter.cs#L11)) ; le fichier dit 124.

Un format comme celui-ci est ce que tu concevrais en C# pour un grand tableau en lecture seule : des enregistrements de taille fixe qu'on atteint par arithmétique, et des données de taille variable derrière une table de décalages. Les partitions d'information de la leçon 2 ne sont pas du tout dans le fichier.

## Le relire

`OptickIndexReader` ne charge pas le fichier en mémoire : il le [mappe en mémoire](https://learn.microsoft.com/dotnet/api/system.io.memorymappedfiles.memorymappedfile) ([lignes 50-55](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/OptickIndexReader.cs#L50-L55)) et fournit chaque vecteur sous forme de `ReadOnlySpan<float>` qui pointe dans les pages mappées. Le système d'exploitation charge les pages touchées, et plusieurs processus peuvent les partager.

```text
== OptickIndexReader
Count                    15360
guitar range             (0, 15360)
bass range               (15360, 0)
voicing 0                0-0-0-x-x-x Em/G [64 59 55]
its squared norm         1.150
max |disk - ExtractCompact| 1.5e-8
```

La norme au carré de chaque vecteur stocké vaut 1.15 : chaque partition a une norme de 1 multipliée par `√w`, donc sa contribution au carré vaut `w`, et les poids font 1.15 au total. La dernière ligne compare les `float` stockés avec `EmbeddingSchema.ExtractCompact` calculé en `double` : ils concordent à 1,5 × 10⁻⁸ près, la précision d'un `float`.

Le mappage en mémoire a un coût dont le skill de GA prévient : sous Windows, un processus en cours qui a l'index ouvert verrouille le fichier, et une reconstruction « WILL fail with IOException », échouera avec une IOException, tant que GaApi et le serveur MCP de GA ne sont pas arrêtés.

## Chercher

[`OptickSearchStrategy.SearchInternal`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/OptickSearchStrategy.cs#L164-L262) est une recherche des plus proches voisins exacte, les `k` plus proches voisins par force brute du [cours sur IX](../../machine-learning-ix/03-classification/), avec un produit scalaire au lieu d'une distance :

- un [`TensorPrimitives.Dot`](https://learn.microsoft.com/dotnet/api/system.numerics.tensors.tensorprimitives.dot) par voicing, accéléré par SIMD, sur les vecteurs mappés ;
- un [`Parallel.For`](https://learn.microsoft.com/dotnet/api/system.threading.tasks.parallel.for) sur les voicings, chaque thread gardant sa propre [`PriorityQueue`](https://learn.microsoft.com/dotnet/api/system.collections.generic.priorityqueue-2) des `k` meilleurs, fusionnées à la fin ;
- les égalités départagées par indice, le plus bas d'abord, pour que le résultat ne dépende pas de l'ordonnancement des threads. Le commentaire explique pourquoi : beaucoup de voicings partagent un ensemble de classes de hauteurs, et donc un score.

Pas d'index approché, pas d'arbre : pour l'index en production, cela fait 313 047 × 124, environ 39 millions de multiplications par requête.

### Le vecteur de requête

Un message de chat n'a pas de manche ; [`MusicalQueryEncoder`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/MusicalQueryEncoder.cs#L43-L109) ne remplit donc que ce qu'un chiffrage d'accord peut donner : STRUCTURE à partir des classes de hauteurs, MODAL, SYMBOLIC quand il y a des étiquettes, ROOT quand le chiffrage a une fondamentale. MORPHOLOGY et CONTEXT restent à zéro, tout comme le vecteur d'intervalles à l'intérieur de STRUCTURE, « not yet wired into the query path », pas encore branché sur le chemin des requêtes ([lignes 52-58](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/MusicalQueryEncoder.cs#L52-L58)). Le meilleur score possible est donc inférieur à `0.45 + 0.10 + 0.05 = 0.60`.

### Cmaj7

```text
== HybridSearchAsync for "Cmaj7" (query vector from MusicalQueryEncoder)
query partitions set: STRUCTURE, MODAL, ROOT
rank  diagram        MIDI               name         score
1     x-1-x-2-2-x    60 52 47           Cmaj7(shell)/B 0.458
2     x-1-x-x-2-0    60 47 40           Cmaj7(shell)/E 0.458
3     x-1-x-2-2-0    60 52 47 40        Cmaj7(shell)/E 0.458
4     x-1-0-2-2-x    60 55 52 47        Cmaj7/B      0.419
5     x-1-0-x-2-0    60 55 47 40        Cmaj7/E      0.419
with the filter ChordName = "Cmaj7":
rank  diagram        MIDI               name         score
1     3-0-x-2-3-x    67 59 52 48        Cmaj7        0.369
2     3-0-0-2-3-x    67 59 55 52 48     Cmaj7        0.369
```

Chaque résultat non filtré a C, MIDI 60, comme note la plus aiguë, et aucun n'a C à la basse : ce sont des renversements et des voicings réduits (*shells*). Les deux formes de Cmaj7 à l'état fondamental sortent plus bas, à 0.369, parce que leur note la plus aiguë est G. La requête dit « fondamentale C » ; l'index a stocké la note la plus aiguë comme fondamentale (leçon 2). Une recherche par chiffrage d'accord récompense les formes qui ont la fondamentale en haut.

[`HybridSearchAsync`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/OptickSearchStrategy.cs#L49-L73) ajoute des filtres après la recherche : il prend `max(10 × limit, 100)` candidats, puis [`ApplyFilters`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/OptickSearchStrategy.cs#L296-L329) découpe `"Cmaj7"` en une fondamentale, C, et une qualité, `maj7`, et garde les candidats dont le nom contient `maj7` et dont la note **la plus grave** est un C. Le filtre utilise la vraie basse ; les vecteurs ont utilisé la note la plus aiguë. Seules deux formes passent, et ce sont les deux que montre le chatbot de la leçon 4.

### Am7 et C

```text
== HybridSearchAsync for "Am7" (query vector from MusicalQueryEncoder)
query partitions set: STRUCTURE, MODAL, ROOT
rank  diagram        MIDI               name         score
1     x-x-2-x-3-3    57 48 43           Am7(shell)/G 0.458
2     x-x-2-2-3-x    57 52 48           Am/C         0.450
3     x-x-2-x-3-0    57 48 40           Am/E         0.450
4     x-x-2-2-3-0    57 52 48 40        Am/E         0.450
5     x-x-2-2-3-3    57 52 48 43        Am7/G        0.419
with the filter ChordName = "Am7":
rank  diagram        MIDI               name         score
1     2-x-x-2-0-x    66 52 45           Gbm7(shell)/A 0.342
2     2-x-2-2-0-x    66 57 52 45        Gbm7(shell)/A 0.342

== HybridSearchAsync for "C" (query vector from MusicalQueryEncoder)
query partitions set: STRUCTURE, MODAL, ROOT
rank  diagram        MIDI               name         score
1     x-1-0-2-x-x    60 55 52           C/E          0.481
2     x-1-0-2-3-x    60 55 52 48        C            0.481
3     x-1-0-x-x-0    60 55 40           C/E          0.481
4     x-1-0-2-x-0    60 55 52 40        C/E          0.481
5     x-1-0-x-3-0    60 55 48 40        C/E          0.481
with the filter ChordName = "C":
rank  diagram        MIDI               name         score
1     x-1-0-2-3-x    60 55 52 48        C            0.481
2     x-1-x-2-3-x    60 52 48           C + E (Major 3rd) 0.453
3     x-1-0-x-3-x    60 55 48           C5           0.415
4     x-1-2-2-3-x    60 57 52 48        Am/C         0.393
5     x-1-x-0-3-x    60 50 48           C + D (Major 2nd) 0.367
```

Le test de qualité est un test de sous-chaîne : le filtre `Am7` accepte donc une forme nommée `Gbm7(shell)/A`, dont le nom contient `m7` et dont la note la plus grave est un A. Pour `"C"`, la qualité est la chaîne vide, que tout nom contient : le filtre garde tout ce qui a C à la basse, y compris une forme avec seulement C et E, et Am/C.

### Les voicings les plus proches d'un voicing

```text
== Nearest voicings to 0-1-0-2-3-x (open C), by its own compact vector
rank  diagram        MIDI               name         score
1     0-1-0-2-3-x    64 60 55 52 48     C            1.150
2     0-1-0-2-x-3    64 60 55 52 43     C/G          1.150
3     0-1-0-x-3-x    64 60 55 48        C            1.149
4     0-1-0-x-x-3    64 60 55 43        C/G          1.149
5     0-1-x-2-x-3    64 60 52 43        C/G          1.149
6     0-1-0-2-x-0    64 60 55 52 40     C/E          1.139
FindSimilarVoicingsAsync("0-1-0-2-3-x") returned 0 results
```

Chercher avec un vecteur stocké trouve d'abord le C ouvert, puis C/G avec le même score à trois décimales : déplacer la basse de C à G, un changement que tout guitariste entend, ne coûte presque rien, parce que la « basse » du vecteur est la note la plus aiguë, E dans les deux cas. La méthode faite pour cela, [`FindSimilarVoicingsAsync`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/OptickSearchStrategy.cs#L75-L92), renvoie une liste vide pour toute entrée : les métadonnées OPTK « is keyed by index, not voicing id », sont indexées par position et non par identifiant de voicing, et elle journalise un avertissement une seule fois.

## Les dimensions qui ne varient jamais

Une dimension qui a la même valeur pour chaque voicing ajoute la même quantité à chaque score : elle ne peut changer aucun classement. Le cours les compte sur le corpus :

```text
== Dimensions that never vary over the 15360 voicings
partition     dims  always 0  constant  weight
IDENTITY      6     3         3         0.00
STRUCTURE     24    2         1         0.45
MORPHOLOGY    24    5         0         0.25
CONTEXT       12    11        1         0.20
SYMBOLIC      12    3         2         0.10
EXTENSIONS    18    6         1         0.00
SPECTRAL      13    0         0         0.00
MODAL         40    16        0         0.10
HIERARCHY     15    14        0         0.00
ATONAL_MODAL  64    47        0         0.00
ROOT          12    0         0         0.05
in the 124 compact dims: 37 always 0, 4 constant
named MODAL slots never set (9 of 33): LocrianNatural6, DorianSharp4, LydianSharp2, AlteredDoubleFlat7, DorianFlat2, LydianAugmented, MixolydianFlat6, LocrianNatural2, Diminished
MODAL slots without a name constant: 7
```

- **CONTEXT**, poids 0.20 : 11 dimensions toujours nulles et une constante, la tension de la leçon 2. Le ticket [#616](https://github.com/GuitarAlchemist/ga/issues/616) a mesuré la même chose sur l'index en production, et 40 dimensions mortes sur 124 ; ce corpus est petit, mais en trouve 41 qui ne varient jamais.
- **ATONAL_MODAL** : les 47 emplacements que le tableau de 17 éléments de la leçon 2 ne peut pas atteindre.
- **MODAL** : 9 des 33 emplacements nommés ne sont jamais remplis. [`ModalVectorService`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/Services/ModalVectorService.cs#L165-L178) cherche chaque mode par un nom d'affichage comme `"Locrian ♮6"` ou `"Dorian ♯4"`, et repart sans rien écrire quand la recherche ne trouve aucun intervalle ; un nom que la recherche ne connaît pas expliquerait ces neuf-là (*à vérifier*). Certains zéros peuvent aussi être réels : un corpus de trois cases a peu de voicings des modes les plus rares.

## Exercices

1. L'en-tête dit que les vecteurs commencent à l'octet 123 496 et les métadonnées à 7 742 056. Vérifie ces deux nombres à partir de la taille de l'en-tête, du nombre de voicings et de la dimension.
2. Pourquoi la norme au carré de chaque vecteur stocké vaut-elle exactement la somme des poids, et que vaudrait-elle pour un voicing dont la partition SYMBOLIC est entièrement nulle ?
3. Un utilisateur demande au chatbot des « voicings de C ». D'après les résultats filtrés pour `"C"`, liste ce qu'un guitariste objecterait.
4. Écris la boucle de produits scalaires de `SearchInternal` pour un seul thread, sans le tas : un `for` sur les voicings qui garde le meilleur score et son indice.

<details>
<summary>Solutions</summary>

1. La table des décalages commence juste après l'en-tête, à 616, avec 8 octets par voicing : `616 + 15,360 × 8 = 123,496`. Les vecteurs occupent `15,360 × 124 × 4 = 7,618,560` octets : `123,496 + 7,618,560 = 7,742,056`. Le fichier se termine `1,233,243` octets de métadonnées plus loin, à 8 975 299, la taille affichée.
2. `ExtractCompact` divise chaque partition par sa norme et la multiplie par `√w`, donc la norme au carré de chaque partition vaut `w`, et les normes au carré de parties disjointes s'additionnent. Une partition entièrement nulle reste à zéro : la norme au carré de ce voicing serait donc `1.15 − 0.10 = 1.05`.
3. La forme `x-1-x-2-3-x` n'a que deux classes de hauteurs, C et E, et s'appelle « C + E (Major 3rd) » ; `x-1-0-x-3-x` est un power chord C5, sans tierce ; `x-1-2-2-3-x` est Am/C, un autre accord ; `x-1-x-0-3-x`, c'est C et D. Seul le premier résultat est un accord de C majeur. Le filtre vérifie la basse et une sous-chaîne du nom, et la qualité vide de `"C"` correspond à tous les noms.
4. Par exemple :

   ```csharp
   var best = (Score: float.NegativeInfinity, Index: -1L);
   for (long i = start; i < start + count; i++)
   {
       var score = TensorPrimitives.Dot(q.AsSpan(), reader.GetVector(i));
       if (score > best.Score) best = (score, i); // strict : l'indice le plus bas l'emporte en cas d'égalité
   }
   ```

   Le `>` strict garde le premier indice, le plus bas, parmi les scores égaux : le même départage que les tas de GA.

</details>

## À retenir

- Un index OPTK est un fichier binaire plat : un en-tête avec une empreinte du schéma, une table de décalages, des vecteurs `float` de taille fixe sur les 124 dimensions de similarité, et des métadonnées MessagePack. Il est mappé en mémoire, pas chargé.
- La recherche est exacte : un produit scalaire SIMD par voicing, des tas top-k par thread, les égalités départagées par indice pour des résultats déterministes.
- L'encodeur de requêtes ne peut remplir que STRUCTURE (sans son vecteur d'intervalles), MODAL, SYMBOLIC et ROOT : les scores d'un chiffrage d'accord restent donc sous 0.60.
- Comme la fondamentale stockée est la note la plus aiguë alors que le filtre utilise la basse, une recherche de « Cmaj7 » classe d'abord les formes avec C en haut, et le filtrage ne garde que deux formes du petit corpus ; le filtre sur le nom est un test de sous-chaîne.
- Sur 15 360 voicings, 41 des 124 dimensions de recherche ne varient jamais, dont CONTEXT : une partie de chaque score est une constante.

## Sources

- GuitarAlchemist/ga au commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6) : `Demos/Music Theory/FretboardVoicingsCLI` (`OptickIndexWriter.cs`, `Program.cs`), `Common/GA.Business.ML/Search` (`OptickIndexReader.cs`, `OptickSearchStrategy.cs`, `MusicalQueryEncoder.cs`), `Common/GA.Business.ML/Embeddings/Services/ModalVectorService.cs`, `Common/GA.Domain.Services/Fretboard/Voicings/Generation/VoicingGenerator.cs`, `.claude/skills/optic-k-rebuild/SKILL.md`.
- Ticket de GA [#616](https://github.com/GuitarAlchemist/ga/issues/616), lu le 2026-09-14.
- Microsoft Learn : [MemoryMappedFile](https://learn.microsoft.com/dotnet/api/system.io.memorymappedfiles.memorymappedfile), [TensorPrimitives.Dot](https://learn.microsoft.com/dotnet/api/system.numerics.tensors.tensorprimitives.dot), [PriorityQueue](https://learn.microsoft.com/dotnet/api/system.collections.generic.priorityqueue-2), [Parallel.For](https://learn.microsoft.com/dotnet/api/system.threading.tasks.parallel.for), [BinaryReader](https://learn.microsoft.com/dotnet/api/system.io.binaryreader).
- [Spécification MessagePack](https://github.com/msgpack/msgpack/blob/master/spec.md).
