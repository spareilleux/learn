---
title: Théorie musicale pour Guitar Alchemist — Mission
description: La théorie musicale derrière Guitar Alchemist, pour des développeurs qui jouent un peu de guitare et ne lisent pas la musique — chaque notion expliquée, notée, puis retrouvée dans le code C# de GA et vérifiée contre lui.
sidebar:
  label: Mission
  order: 0
---

:::note[Comment ce cours est testé]
Chaque tableau de sortie des leçons vient de [`code/music-theory-ga`](https://github.com/spareilleux/learn/tree/main/code/music-theory-ga), un programme .NET 10 qui calcule chaque notion à partir des définitions des manuels et demande la même réponse à [Guitar Alchemist](https://github.com/GuitarAlchemist/ga). Il est compilé contre le projet `GA.Domain.Core` de GA, cloné au commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6). [`.github/workflows/music-ga-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/music-ga-examples.yml) l'exécute sous Linux, Windows et macOS et compare la sortie, lignes `DIFF` comprises, avec les fichiers attendus. Le même programme dessine les diagrammes, bracelets, grilles d'accords, manches et cercles des quintes, sous forme de fichiers SVG, et la CI vérifie que les images enregistrées dans le dépôt sont à jour. Les sorties ont été capturées en septembre 2026.
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
- construire gammes et modes à partir de motifs de pas, les lire comme des nombres sur 12 bits et les dessiner en bracelets ;
- lire les chiffrages d'accords, écrire les accords, reconnaître les renversements et nommer les voicings de guitare ;
- calculer vecteurs d'intervalles, formes primaires et numéros de Forte, et expliquer la relation Z ;
- lire les armures, parcourir le cercle des quintes et trouver les tonalités relatives, homonymes et voisines ;
- construire les accords d'une tonalité, les désigner par des chiffres romains et des fonctions, et analyser cadences et progressions ;
- expliquer la conduite des voix, les substitutions, l'emprunt modal, les gammes symétriques, les accords étendus et les techniques de voicing à la guitare ;
- retrouver chacune de ces notions dans le code de GA, et dire où GA s'accorde avec la théorie et où il s'en écarte.

## Plan

Le cours suit les notions qu'utilisent le code, les fichiers de configuration et les outils MCP de GA, de la note isolée aux transformations néo-riemanniennes. Les leçons 1 à 7 sont écrites ; les autres sont le plan, et leur colonne GA nomme les types, fichiers et outils que chacune lira.

| # | Leçon | Théorie | Dans GA | Si tu écris du C# |
|---|---|---|---|---|
| 1 | [Notes, classes de hauteurs et manche](01-notes-and-the-fretboard/) | hauteur, classe de hauteurs, altérations, intervalles, accordage | `PitchClass`, `Note`, `Interval`, `Tuning`, `Fretboard` | objets valeur, hiérarchies fermées de records |
| 2 | [Gammes, modes et identifiants de gamme sur 12 bits](02-scales-and-modes/) | gammes majeure et mineures, modes, transposition, bracelets | `PitchClassSetId`, `Scale`, `MajorScaleMode`, `ModalFamily` | `[Flags]`, rotation de bits, `PopCount` |
| 3 | [Accords, chiffrages, renversements et voicings](03-chords-and-voicings/) | triades, accords de septième, chiffrages d'accords, renversements | `Chord`, `ChordFormula`, `CanonicalChordPatternCatalog`, `Voicing` | parseurs, expressions `switch` |
| 4 | [Classes d'ensembles, vecteurs d'intervalles et relation Z](04-set-classes/) | équivalence T/I, vecteurs d'intervalles, formes primaires, numéros de Forte | `SetClass`, `IntervalClassVector`, `ForteCatalog`, outils MCP | formes canoniques, classes d'équivalence |
| 5 | [Tonalités, armures et cercle des quintes](05-keys-and-the-circle-of-fifths/) | armures, tonalités relatives et homonymes, tonalités voisines | `Key`, `KeySignature`, outils MCP de tonalité | objets valeur à plage bornée, tables de correspondance |
| 6 | [Les accords d'une tonalité](06-diatonic-chords/) | triades et accords de septième diatoniques, chiffres romains, noms des degrés, fonctions | `HarmonicFunction`, `Key.Notes`, `PitchClassSet.GetCompatibleKeys`, `ga_diatonic_chords` | enums, tests d'inclusion sur des masques de bits |
| 7 | [Cadences, ii–V–I et tonalité d'une progression](07-cadences-and-progressions/) | cadences, mouvements plagal et rompu, ii–V–I, résolution de V⁷, trouver la tonalité | `Cadences.yaml`, `PitchClassSet.ClosestDiatonicKey`, `ga_analyze_progression`, `ga_key_from_progression` | calcul de score et départage |
| 8 | [Le ukulélé et la basse](08-ukulele-and-bass/) | accordages rentrants, accordages en quartes, numérotation des cordes | `Tuning.Ukulele`, `Tuning.Bass`, `Str`, `Fretboard`, `Instruments.yaml` | deviner à partir des données, et quand s'en abstenir |
| 9 | Conduite des voix et notes communes | notes communes, conduite des voix conjointe, distance de conduite des voix | `VoiceLeadingSpace`, `ProgressionVoiceLeadingAnalyzer`, `ga_common_tones`, `ga_voice_leading_pair` | métriques de distance |
| 10 | Substitutions et emprunt modal | substitution par le relatif et substitution tritonique, accords d'emprunt | `ChordSubstitutionSkill`, `ModalInterchange.yaml`, `get_borrowed_chords`, `ga_chord_substitutions`, `GrothendieckDelta` | classement de candidats |
| 11 | Les modes en profondeur | modes des mineures mélodique et harmonique, luminosité, familles modales | `MelodicMinorMode`, `HarmonicMinorMode`, `Modes.yaml`, `PitchClassSet.StepBrightness` | génériques sur les degrés |
| 12 | Symétrie : modes à transpositions limitées | gammes par tons, octatonique et augmentée, bracelets symétriques | `SymmetricScaleMode`, `WholeToneScaleMode`, `DiminishedScaleMode`, `AugmentedScaleMode` | invariants par rotation |
| 13 | Accords étendus et altérés | neuvièmes, onzièmes, treizièmes, altérations, structures supérieures, polyaccords | `ChordAlterationService`, `ExtendedChords.yaml`, `ga_polychord` | parseurs à parties optionnelles |
| 14 | Voicings de guitare : shell, drop 2 et drop 3 | voicings shell, voicings serrés et drop, notes guides | `VoicingAnalyzer`, `VoicingDecomposer`, `VoicingGenerator`, `ga_search_voicings` | génération combinatoire |
| 15 | Le manche : CAGED, doigtés et jouabilité | formes CAGED, géométrie du manche, doigtés, accordages alternatifs | `FretboardGeometry`, `PhysicalCostService`, `Biomechanics`, `Tunings.toml`, `ga_easier_voicings` | fonctions de coût |
| 16 | Arpèges, théorie accord–gamme et improvisation | arpèges, paires accord–gamme, notes « outside » | `ImprovisationConcepts.yaml`, `OutsideNotesSkill`, `ga_arpeggio_suggestions` | tables de correspondance |
| 17 | Le Tonnetz et les transformations néo-riemanniennes | P, L et R, le Tonnetz, médiantes chromatiques | `NeoRiemannian.yaml`, `NeoRiemannianConfig.fs` | graphes de transformations |
| A | [Tous les instruments de Guitar Alchemist](appendix-instruments/) | accordages, chœurs, cordes rentrantes | `Instruments.yaml`, `InstrumentsConfig`, `Tuning` | de la configuration que rien ne lit |
| B | [La hiérarchie OPTIC](appendix-optic/) | octave, permutation, transposition, inversion, cardinalité | `PitchClassSet`, `TranspositionClass`, `SetClass`, le schéma OPTIC-K de GA | équivalence, quotient après quotient |
| C | [Toutes les divergences, et à qui revient le bug](appendix-ga-findings/) | les 40 lignes `DIFF` des leçons 1 à 7 | les 19 défauts dont elles viennent | lire honnêtement une comparaison |
| — | [Journal](journal/) | | | |

## Prérequis

- Le [SDK .NET 10](https://dotnet.microsoft.com/download/dotnet/10.0) et [Git](https://git-scm.com/downloads). Sous Windows, lance les scripts du cours depuis Git Bash.
- Moins de 20 Mo de disque pour le clone partiel de GA, sortie de compilation comprise : le script ne récupère que les fichiers des trois projets contre lesquels le programme est compilé.
- Une guitare aide : chaque exemple peut être joué.

## Modules liés sur ce site

Les modules [Streeling](../streeling/), générés à partir de [GuitarAlchemist/Demerzel](https://github.com/GuitarAlchemist/Demerzel), couvrent en partie le même terrain, côté musicien. Chaque leçon renvoie aux modules pertinents :

- [MUS-001 · Qu'est-ce qu'un accord ?](../streeling/music/mus-001-what-is-a-chord/) et [MUS-002 · Au-delà de la tonalité](../streeling/music/mus-002-beyond-tonality/) (leçons 3 et 4) ;
- [MUS-006 · L'univers des gammes](../streeling/music/mus-006-the-scale-universe/) (leçons 2 et 4) ;
- [MUS-003 · Comment fonctionne l'harmonie](../streeling/music/mus-003-functional-harmony/) (leçons 5, 6 et 7) et [MUS-005 · L'harmonie jazz à la guitare](../streeling/music/mus-005-jazz-harmony/) (leçon 7) ;
- [GTR-001 · La carte du manche](../streeling/guitar-studies/gtr-001-the-fretboard-map/), [GTR-002 · La géométrie du CAGED](../streeling/guitar-studies/gtr-002-caged-geometry/) et [GAA-001 · Votre premier accord](../streeling/guitar-alchemist-academy/gaa-001-your-first-chord/) (leçons 1 et 3).

## Ressources

- Mark Gotham et al., [*Open Music Theory*](https://viva.pressbooks.pub/openmusictheory/), version 2 (2023), un manuel gratuit, évalué par des pairs, sous licence CC BY-SA 4.0 : la principale source théorique du cours.
- Ian Ring, [*A Study of Musical Scales*](https://ianring.com/musictheory/scales/) : toutes les gammes par leur numéro sur 12 bits, la numérotation qu'utilise GA, avec un diagramme en bracelet pour chacune.
- Wikipédia : [Interval vector](https://en.wikipedia.org/wiki/Interval_vector), [List of set classes](https://en.wikipedia.org/wiki/List_of_set_classes), [Guitar chord](https://en.wikipedia.org/wiki/Guitar_chord), [Circle of fifths](https://en.wikipedia.org/wiki/Circle_of_fifths), [Cadence](https://en.wikipedia.org/wiki/Cadence).
- [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga) : le code que lit ce cours.
