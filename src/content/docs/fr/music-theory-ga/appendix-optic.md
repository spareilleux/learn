---
title: "Annexe B : la hiérarchie OPTIC"
description: D'un doigté jusqu'à une classe d'ensembles, une équivalence à la fois — octave, permutation, cardinalité, transposition, inversion — avec le type de Guitar Alchemist à chaque barreau, son schéma d'embedding OPTIC-K à côté, et deux outils pour monter l'échelle à la main.
sidebar:
  label: "Annexe B : la hiérarchie OPTIC"
  order: 91
---

Les leçons 1 à 4 montent une échelle sans la nommer. La leçon 1 transforme une position sur le manche en hauteur et une hauteur en classe de hauteurs. La leçon 2 transforme un ensemble de classes de hauteurs en gamme et compare des gammes qui sont des transpositions l'une de l'autre. La leçon 4 identifie les ensembles reliés par transposition et inversion et appelle le résultat une classe d'ensembles. Chacune de ces étapes **oublie** quelque chose exprès, et l'ordre dans lequel on oublie est une hiérarchie que la théorie musicale sait nommer.

Callender, Quinn et Tymoczko appellent les cinq équivalences **OPTIC**, dans ["Generalized Voice-Leading Spaces"](https://www.science.org/doi/10.1126/science.1153021) (*Science*, 2008) :

| | équivalence | deux choses sont les mêmes quand elles ne diffèrent que par… |
|---|---|---|
| **O** | octave | le déplacement de notes d'octaves entières |
| **P** | permutation | l'ordre des notes |
| **T** | transposition | le déplacement de tout par le même intervalle |
| **I** | inversion | le renversement des intervalles |
| **C** | cardinalité | le doublement d'une note déjà présente |

Elles sont indépendantes : on peut appliquer n'importe quel sous-ensemble, et chaque sous-ensemble nomme un objet musical différent. « Accord », c'est en général OPC. « Type de gamme », c'est OPTC. « Classe d'ensembles », c'est OPTIC, les cinq.

```bash
dotnet run --project code/music-theory-ga/GaTheory -c Release -- l10
```

## La montée

Commençons en bas, par quelque chose que l'on peut réellement faire avec ses mains : l'accord de C ouvert, `x32010`.

```text
== One fingering, climbed rung by rung
rung                       the object                         what it forgets
a fingering                x32010                             nothing: strings, frets, muted strings
the pitches                C3 E3 G3 C4 E4                     which string each note was played on
- O, octave                0 4 7 0 4                          the octave of each note
- P, permutation           0 0 4 4 7                          the order of the notes
- C, cardinality           0 4 7                              doubled notes
- T, transposition         0 4 7                              which key it is in
- I, inversion             (037)                              major against minor
```

Lis la troisième colonne de haut en bas et tu as toute l'annexe. Un doigté sait tout. Arrivé en haut, tout ce qui survit est la forme `(037)` — une note, une note trois demi-tons plus haut, une note quatre demi-tons au-dessus de celle-là, dans une tonalité quelconque, dans un sens ou dans l'autre.

Remarque ce qui n'est *pas* sur l'échelle. La première étape, de `x32010` à `C3 E3 G3 C4 E4`, n'est pas du tout une équivalence OPTIC : c'est l'instrument. Deux doigtés différents qui font sonner les cinq mêmes hauteurs sont la même *musique* et de la *guitare* différente. OPTIC n'a rien à dire de cette différence, ce qui est précisément pourquoi un programme qui travaille sur des classes d'ensembles ne peut pas te dire où poser les doigts.

## Ce que chaque barreau jette

```text
== What each rung identifies
rung                       distinct objects     of the C major triad
fingerings, frets 0 to 4   63                   ways to play these three pitch classes
pitch multisets            5                    notes sounding in x32010
the pitch-class set        1                    0 4 7
- T: transposition class   1                    one of the 12 major triads
- I: set class             1                    one of the 24 major and minor triads
```

Soixante-trois façons de jouer ces trois classes de hauteurs sur les cinq premières cases, et les trois premiers barreaux de l'échelle les aplatissent toutes en un seul objet. C'est tout l'intérêt d'une équivalence, et c'est aussi son coût : tout ce qui intéresse un guitariste vit sous le barreau où l'échelle commence.

```text
== How many objects there are at each rung
rung                           course   GA       check
pitch-class sets (P, O, C)     4096     4096     ok
transposition classes (+T)     352      352      ok
set classes (+I)               224      224      ok
cardinalities (+C)             13       13       ok
```

4096 sous-ensembles de douze classes de hauteurs ; 352 d'entre eux à transposition près ; 224 à transposition et inversion près. Les `PitchClassSet`, `TranspositionClass` et `SetClass` de GA concordent avec le cours sur les trois comptes, ce qui est la façon dont cette annexe dit que la hiérarchie est bel et bien dans le code.

## Deux accords à la fois

```text
== The same climb for four chords
chord          pitch classes      transposition class / set class
C              0 4 7              0 4 7  /  (037)
A minor        0 4 9              0 3 7  /  (037)
G              2 7 E              0 4 7  /  (037)
F              0 5 9              0 4 7  /  (037)
C and G are different chords, the same transposition class, the same set class.
C and A minor are different transposition classes and the same set class: I joins them.
```

C et G sont des accords différents qui se rejoignent au barreau T. C et A mineur sont des classes de transposition différentes qui se rejoignent au barreau I — c'est la version formelle du fait, vu à la leçon 5, qu'une tonalité majeure et sa relative mineure partagent un ensemble de notes. F et G sont deux autres triades majeures : le même barreau, le même objet.

## Le type de GA à chaque barreau

```text
== GA's types, one per rung
rung                       course                     GA                         check
- O, P, C: a set           id 145: 0 4 7              id 145: 0 4 7              ok
cardinality                3                          3                          ok
- I: prime form            (037)                      (037)                      ok
interval-class vector      <0 0 1 1 1 0>              <0 0 1 1 1 0>              ok
GA's SetClass for this set: SetClass[3 (Tritonic)-<0 0 1 1 1 0>/137]
its Forte number: 3-11
```

- **[`PitchClassSet`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClassSet.cs)** est l'objet obtenu après O, P et C : un identifiant sur 12 bits, sans octaves, sans ordre, sans doublement. Le bug de détection de tonalité de la leçon 7 en est une conséquence directe — un `PitchClassSet` ne peut pas savoir quelle note est la tonique, parce que « quelle note vient en premier » est précisément ce que P a jeté.
- **[`TranspositionClass`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/TranspositionClass.cs)** ajoute T : 352 éléments.
- **[`SetClass`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/SetClass.cs)** ajoute I : 224 éléments, chacun avec une forme primaire, une cardinalité et un vecteur de classes d'intervalles.
- **`Cardinality`**, c'est C, gardée comme propriété plutôt que comme quotient.

Deux barreaux n'ont pas de type, et les deux absences ressortent ailleurs dans ce cours. Il n'y a pas d'objet entre une hauteur et une classe de hauteurs — pas de « hauteur avec une orthographe » qui survive à un accord — et c'est le problème d'orthographe de la leçon 3. Et il n'y a rien *sous* `PitchClassSet` qui garde l'ordre des notes, et c'est celui de la leçon 7.

## Le schéma d'embedding OPTIC-K de GA

GA emploie le même vocabulaire pour l'apprentissage automatique. Son schéma d'embedding, documenté dans [`.agent/skills/optic-k-schema-guardian/SKILL.md`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/.agent/skills/optic-k-schema-guardian/SKILL.md) et implémenté dans `Common/GA.Business.ML/Embeddings/EmbeddingSchema.cs`, compte **216 dimensions** réparties en partitions nommées. Deux d'entre elles sont cette échelle, coupée en deux :

| Partition | Dimensions | Poids | Rôle, dans les mots de GA |
|---|---|---|---|
| STRUCTURE | 6-29 | 0.45 | "Pitch-class set invariants (O+P+T+I). Core musical identity." |
| MORPHOLOGY | 30-53 | 0.25 | "Physical fretboard realization (geometry/fingering)." |

STRUCTURE, c'est le **haut** de l'échelle : les quatre équivalences, l'objet qui leur survit, doté du poids le plus fort parce que deux voicings d'une même classe d'ensembles sont réellement la même harmonie. MORPHOLOGY, c'est tout ce que l'échelle a **jeté** en montant : quelle corde, quelle case, quel doigt — l'étape de `x32010` à `C3 E3 G3 C4 E4` qu'OPTIC ne modélise pas.

Cette coupure est la bonne, et il vaut la peine de dire pourquoi. Une recherche qui n'utiliserait que STRUCTURE renverrait la triade de C majeur jouée n'importe où, y compris là où aucune main n'atteint. Une recherche qui n'utiliserait que MORPHOLOGY renverrait des formes qui se ressemblent et qui n'ont aucun rapport sonore. Les deux partitions sont les deux moitiés de cette annexe, avec des poids.

*À vérifier* : les plages de dimensions et les poids ci-dessus sont lus dans le document de compétence au commit épinglé, dont l'en-tête appelle le schéma v1.4 ; le programme du cours ne compile pas `GA.Business.ML`, donc rien ici n'est vérifié par exécution, contrairement aux tableaux plus haut.

## Monter l'échelle à la main

Deux sites permettent de faire chaque barreau de cette annexe à la souris, et les deux valent une soirée.

Le **[chercheur de gammes d'Ian Ring](https://ianring.com/musictheory/scales/finder/)** est un bracelet à douze perles, exactement le diagramme de la leçon 2. Clique sur les perles pour construire un ensemble ; la page le nomme et renvoie vers sa fiche. Ses trois boutons sont trois barreaux de l'échelle :

- **Rotate up** et **Rotate down** appliquent **T**, un demi-ton à la fois. Fais tourner douze fois et te voilà revenu au point de départ : cette orbite est la classe de transposition.
- **Reflect** applique **I**. Si la réflexion redonne l'ensemble que tu avais déjà, l'ensemble est symétrique par inversion et sa classe d'ensembles contient 12 ensembles plutôt que 24 — la collection diatonique, la gamme par tons et la gamme octatonique se comportent toutes ainsi, et c'est la section de la leçon 2 sur la symétrie.
- Le numéro de la gamme est l'identifiant sur 12 bits de la leçon 2, et [la page de chaque gamme](https://ianring.com/musictheory/scales/2477) donne ses modes, son vecteur d'intervalles et si elle a un partenaire en relation Z, et c'est la leçon 4.

C'est le moyen le plus rapide de vérifier une affirmation de ce cours : les comptes de la leçon 2 et les vecteurs de la leçon 4 peuvent être confirmés un ensemble à la fois sur les pages de Ring, et c'est ainsi que plusieurs l'ont été.

**[Harmonious](https://harmoniousapp.net/)** aborde le même matériau par l'autre bout. Il se présente comme "a map of all chromatic-cluster-free hexatonic, heptatonic, and octotonic scales and modes and their compatible chords (Levine 1995) in twelve-tone equal temperament", et il est organisé par armure et par accord plutôt que par numéro d'ensemble. Là où Ring donne le *quotient* — une page par gamme, transpositions confondues — Harmonious donne la *fibre* : cette tonalité, ces accords, ces substitutions. À eux deux, ils sont les deux directions de cette annexe, et aucun ne remplace l'autre :

| | Ian Ring | Harmonious |
|---|---|---|
| Unité | une classe d'ensembles, sans tonalité | une tonalité et ses accords |
| Barreaux montrés | T et I, sous forme de boutons | sous l'échelle : voicings et paires accord–gamme |
| Idéal pour | vérifier un compte ou un vecteur | trouver une substitution jouable |
| Rapport avec GA | même numérotation sur 12 bits | même idée accord–gamme qu'aux leçons 6 et 7 |

GA se situe entre les deux : `SetClass` est l'objet de Ring, `Voicing` et `Fretboard` sont plus proches de ceux d'Harmonious, et le schéma OPTIC-K ci-dessus est une tentative délibérée de tenir les deux dans un seul vecteur.

## À retenir

- OPTIC, ce sont cinq choses indépendantes à oublier, pas une seule opération. Nommer celles que l'on a appliquées dit ce que le type peut et ne peut pas répondre.
- Chacun des défauts 8, 9, 12 et 19 de l'annexe C est un barreau que l'on monte, puis une question posée qui avait besoin de l'information jetée : une orthographe après O, une tonique après P, un compte après C.
- L'instrument est *sous* le barreau du bas. OPTIC ne dit rien du doigté, et c'est pourquoi GA a besoin d'une seconde partition pour cela.

## Sources

- Clifton Callender, Ian Quinn et Dmitri Tymoczko, ["Generalized Voice-Leading Spaces"](https://www.science.org/doi/10.1126/science.1153021), *Science* 320 (2008), l'article qui nomme OPTIC.
- Dmitri Tymoczko, [*A Geometry of Music*](https://dmitri.mycpanel.princeton.edu/geometry-of-music.html) (Oxford, 2011), chapitres 2 et 3.
- Ian Ring, [*A Study of Musical Scales*](https://ianring.com/musictheory/scales/) et son [chercheur de gammes](https://ianring.com/musictheory/scales/finder/).
- [Harmonious](https://harmoniousapp.net/), et Mark Levine, *The Jazz Theory Book* (1995), qu'il cite pour ses paires accord–gamme.
- GuitarAlchemist/ga au commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6) : `Common/GA.Domain.Core/Theory/Atonal` et [`.agent/skills/optic-k-schema-guardian/SKILL.md`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/.agent/skills/optic-k-schema-guardian/SKILL.md).
- Le programme du cours : [`Lesson10.cs`](https://github.com/spareilleux/learn/blob/main/code/music-theory-ga/GaTheory/Lesson10.cs), [`expected/l10.txt`](https://github.com/spareilleux/learn/blob/main/code/music-theory-ga/expected/l10.txt).
