---
title: Théorie musicale pour Guitar Alchemist — Mission
description: La théorie musicale derrière Guitar Alchemist, pour des développeurs qui jouent un peu de guitare et ne lisent pas la musique — chaque notion expliquée, notée, puis retrouvée dans le code C# de GA et vérifiée contre lui.
sidebar:
  label: Mission
  order: 0
---

:::note[Comment ce cours est testé]
Chaque tableau de sortie des leçons vient de [`code/music-theory-ga`](https://github.com/spareilleux/learn/tree/main/code/music-theory-ga), un programme .NET 10 qui calcule chaque notion à partir des définitions des manuels et demande la même réponse à [Guitar Alchemist](https://github.com/GuitarAlchemist/ga). Il est compilé contre le projet `GA.Domain.Core` de GA, cloné au commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6). [`.github/workflows/music-ga-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/music-ga-examples.yml) l'exécute sous Linux, Windows et macOS et compare la sortie, lignes `DIFF` comprises, avec les fichiers attendus. Les sorties ont été capturées en septembre 2026.
:::

## Pourquoi j'apprends ça

[Guitar Alchemist](https://github.com/GuitarAlchemist/ga) (GA) est une grosse base de code C# et F# consacrée à la musique : notes, intervalles, gammes, modes, accords, voicings, classes d'ensembles, et des outils qui permettent à un assistant IA de raisonner dessus. Je sais lire le code. Ce que je ne sais pas faire, c'est dire si `ModalFamily`, `PrimeForm` ou `GetSymbolSuffix` calculent ce qu'un musicien entend par ces mots. Ce cours apprend la théorie dans des sources sérieuses, puis lit les types de GA avec cette théorie en main, et note chaque endroit où les deux divergent.

## À qui s'adresse ce cours

Tu écris du C# ou du Java. Tu joues un peu de guitare : quelques accords ouverts, peut-être une gamme pentatonique. Tu ne lis pas la musique, et tu n'en as pas besoin : chaque notion arrive en trois temps.

1. **L'idée**, en mots et sur le manche.
2. **La notation** dans laquelle musiciens et théoriciens l'écrivent.
3. **Dans GA** : les types et méthodes qui la représentent, avec des liens vers les lignes exactes.

Le côté programmation reste familier : objets valeur, records, champs de bits, expressions `switch`, LINQ.

## À la fin de ce cours, je saurai

- convertir entre noms de notes, classes de hauteurs, numéros MIDI et positions sur le manche ;
- nommer et écrire les intervalles, et les replier en classes d'intervalles ;
- construire gammes et modes à partir de motifs de pas et les lire comme des nombres sur 12 bits ;
- lire les chiffrages d'accords, écrire les accords, reconnaître les renversements et nommer les voicings de guitare ;
- calculer vecteurs d'intervalles, formes primaires et numéros de Forte, et expliquer la relation Z ;
- retrouver chacune de ces notions dans le code de GA, et dire où GA s'accorde avec la théorie et où il s'en écarte.

## Plan

| # | Leçon | Théorie | Dans GA | Si tu écris du C# |
|---|---|---|---|---|
| 1 | [Notes, classes de hauteurs et manche](01-notes-and-the-fretboard/) | hauteur, classe de hauteurs, altérations, intervalles, accordage | `PitchClass`, `Note`, `Interval`, `Tuning`, `Fretboard` | objets valeur, hiérarchies fermées de records |
| 2 | [Gammes, modes et identifiants de gamme sur 12 bits](02-scales-and-modes/) | gammes majeure et mineures, modes, transposition | `PitchClassSetId`, `Scale`, `MajorScaleMode`, `ModalFamily` | `[Flags]`, rotation de bits, `PopCount` |
| 3 | [Accords, chiffrages, renversements et voicings](03-chords-and-voicings/) | triades, accords de septième, chiffrages d'accords, renversements | `Chord`, `ChordFormula`, `CanonicalChordPatternCatalog`, `Voicing` | parseurs, expressions `switch` |
| 4 | [Classes d'ensembles, vecteurs d'intervalles et relation Z](04-set-classes/) | équivalence T/I, vecteurs d'intervalles, formes primaires, numéros de Forte | `SetClass`, `IntervalClassVector`, `ForteCatalog`, outils MCP | formes canoniques, classes d'équivalence |
| — | [Journal](journal/) | | | |

## Prérequis

- Le [SDK .NET 10](https://dotnet.microsoft.com/download/dotnet/10.0) et [Git](https://git-scm.com/downloads). Sous Windows, lance les scripts du cours depuis Git Bash.
- Moins de 20 Mo de disque pour le clone partiel de GA, sortie de compilation comprise : le script ne récupère que les fichiers des trois projets contre lesquels le programme est compilé.
- Une guitare aide : chaque exemple peut être joué.

## Modules liés sur ce site

Les modules [Streeling](../streeling/), générés à partir de [GuitarAlchemist/Demerzel](https://github.com/GuitarAlchemist/Demerzel), couvrent en partie le même terrain, côté musicien. Chaque leçon renvoie aux modules pertinents :

- [MUS-001 · Qu'est-ce qu'un accord ?](../streeling/music/mus-001-what-is-a-chord/) et [MUS-002 · Au-delà de la tonalité](../streeling/music/mus-002-beyond-tonality/) (leçons 3 et 4) ;
- [MUS-006 · L'univers des gammes](../streeling/music/mus-006-the-scale-universe/) (leçons 2 et 4) ;
- [GTR-001 · La carte du manche](../streeling/guitar-studies/gtr-001-the-fretboard-map/), [GTR-002 · La géométrie du CAGED](../streeling/guitar-studies/gtr-002-caged-geometry/) et [GAA-001 · Votre premier accord](../streeling/guitar-alchemist-academy/gaa-001-your-first-chord/) (leçons 1 et 3).

## Ressources

- Mark Gotham et al., [*Open Music Theory*](https://viva.pressbooks.pub/openmusictheory/), version 2 (2023), un manuel gratuit, évalué par des pairs, sous licence CC BY-SA 4.0 : la principale source théorique du cours.
- Ian Ring, [*A Study of Musical Scales*](https://ianring.com/musictheory/scales/) : toutes les gammes par leur numéro sur 12 bits, la numérotation qu'utilise GA.
- Wikipédia : [Interval vector](https://en.wikipedia.org/wiki/Interval_vector), [List of set classes](https://en.wikipedia.org/wiki/List_of_set_classes), [Guitar chord](https://en.wikipedia.org/wiki/Guitar_chord).
- [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga) : le code que lit ce cours.
