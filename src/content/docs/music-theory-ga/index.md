---
title: Music theory for Guitar Alchemist — Mission
description: The music theory behind Guitar Alchemist, for developers who play a little guitar and don't read music — each concept explained, written down, then found in GA's C# code and checked against it.
sidebar:
  label: Mission
  order: 0
---

:::note[How this course is tested]
Every table of output in the lessons comes from [`code/music-theory-ga`](https://github.com/spareilleux/learn/tree/main/code/music-theory-ga), a .NET 10 program that computes each concept from the textbook definitions and asks [Guitar Alchemist](https://github.com/GuitarAlchemist/ga) for the same answer. It builds against GA's `GA.Domain.Core` project, cloned at commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6). [`.github/workflows/music-ga-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/music-ga-examples.yml) runs it on Linux, Windows and macOS and compares the output, `DIFF` lines included, with the expected files. The same program draws the diagrams, bracelets, chord grids, fretboards and circles of fifths, as SVG files, and CI checks that the committed images are up to date. The outputs were captured in September 2026.
:::

## Why I'm learning this

[Guitar Alchemist](https://github.com/GuitarAlchemist/ga) (GA) is a large C# and F# code base about music: notes, intervals, scales, modes, chords, voicings, set classes, and tools that let an AI assistant reason about them. I can read the code. What I can't do is tell whether `ModalFamily`, `PrimeForm` or `GetSymbolSuffix` compute what a musician means by those words. This course learns the theory from serious sources, then reads GA's types with that theory in hand, and writes down every place where the two disagree.

## Who this course is for

You write C# or Java. You play a little guitar: a few open chords, maybe a pentatonic scale. You don't read music, and you don't need to: every concept comes in three steps.

1. **The idea**, in words and on the fretboard.
2. **The notation** musicians and theorists write it in.
3. **In GA**: the types and methods that represent it, with links to the exact lines.

The programming side stays familiar: value objects, records, bit fields, `switch` expressions, LINQ.

## By the end of this course, I will be able to

- convert between note names, pitch classes, MIDI numbers and fretboard positions;
- name and spell intervals, and fold them into interval classes;
- build scales and modes from step patterns, read them as 12-bit numbers and draw them as bracelets;
- read chord symbols, spell chords, recognise inversions and name guitar voicings;
- compute interval-class vectors, prime forms and Forte numbers, and explain the Z-relation;
- read key signatures, walk the circle of fifths and find relative, parallel and closely related keys;
- build the chords of a key, label them with Roman numerals and functions, and analyse cadences and progressions;
- explain voice leading, substitutions, modal mixture, symmetric scales, extended chords and guitar voicing techniques;
- find each of these in GA's code, and say where GA agrees with the theory and where it doesn't.

## Outline

The course follows the concepts that GA's code, configuration files and MCP tools use, from the single note to the neo-Riemannian transformations. Lessons 1 to 7 are written; the others are the plan, and their GA column names the types, files and tools each one will read.

| # | Lesson | Theory | In GA | If you write C# |
|---|---|---|---|---|
| 1 | [Notes, pitch classes and the fretboard](01-notes-and-the-fretboard/) | pitch, pitch class, accidentals, intervals, tuning | `PitchClass`, `Note`, `Interval`, `Tuning`, `Fretboard` | value objects, closed record hierarchies |
| 2 | [Scales, modes and 12-bit scale ids](02-scales-and-modes/) | major and minor scales, modes, transposition, bracelets | `PitchClassSetId`, `Scale`, `MajorScaleMode`, `ModalFamily` | `[Flags]`, bit rotation, `PopCount` |
| 3 | [Chords, symbols, inversions and voicings](03-chords-and-voicings/) | triads, seventh chords, chord symbols, inversions | `Chord`, `ChordFormula`, `CanonicalChordPatternCatalog`, `Voicing` | parsers, `switch` expressions |
| 4 | [Set classes, interval vectors and the Z-relation](04-set-classes/) | T/I equivalence, interval-class vectors, prime forms, Forte numbers | `SetClass`, `IntervalClassVector`, `ForteCatalog`, MCP tools | canonical forms, equivalence classes |
| 5 | [Keys, key signatures and the circle of fifths](05-keys-and-the-circle-of-fifths/) | key signatures, relative and parallel keys, closely related keys | `Key`, `KeySignature`, MCP key tools | range value objects, lookup tables |
| 6 | [The chords of a key](06-diatonic-chords/) | diatonic triads and seventh chords, Roman numerals, scale-degree names, functions | `HarmonicFunction`, `Key.Notes`, `PitchClassSet.GetCompatibleKeys`, `ga_diatonic_chords` | enums, subset tests on bit masks |
| 7 | [Cadences, ii–V–I and the key of a progression](07-cadences-and-progressions/) | cadences, plagal and deceptive motion, ii–V–I, resolving V⁷, finding the key | `Cadences.yaml`, `PitchClassSet.ClosestDiatonicKey`, `ga_analyze_progression`, `ga_key_from_progression` | scoring and tie-breaking |
| 8 | Voice leading and common tones | common tones, smooth voice leading, voice-leading distance | `VoiceLeadingSpace`, `ProgressionVoiceLeadingAnalyzer`, `ga_common_tones`, `ga_voice_leading_pair` | distance metrics |
| 9 | Substitutions and modal mixture | relative and tritone substitution, borrowed chords | `ChordSubstitutionSkill`, `ModalInterchange.yaml`, `get_borrowed_chords`, `ga_chord_substitutions`, `GrothendieckDelta` | ranking candidates |
| 10 | Modes in depth | modes of melodic and harmonic minor, brightness, modal families | `MelodicMinorMode`, `HarmonicMinorMode`, `Modes.yaml`, `PitchClassSet.StepBrightness` | generics over scale degrees |
| 11 | Symmetry: modes of limited transposition | whole-tone, octatonic and augmented scales, symmetric bracelets | `SymmetricScaleMode`, `WholeToneScaleMode`, `DiminishedScaleMode`, `AugmentedScaleMode` | invariants under rotation |
| 12 | Extended and altered chords | ninths, elevenths, thirteenths, alterations, upper structures, polychords | `ChordAlterationService`, `ExtendedChords.yaml`, `ga_polychord` | parsers with optional parts |
| 13 | Guitar voicings: shells, drop 2 and drop 3 | shell voicings, close and drop voicings, guide tones | `VoicingAnalyzer`, `VoicingDecomposer`, `VoicingGenerator`, `ga_search_voicings` | combinatorial generation |
| 14 | The fretboard: CAGED, fingering and playability | CAGED shapes, fretboard geometry, fingering, alternate tunings | `FretboardGeometry`, `PhysicalCostService`, `Biomechanics`, `Tunings.toml`, `ga_easier_voicings` | cost functions |
| 15 | Arpeggios, chord–scale theory and improvisation | arpeggios, chord–scale pairs, outside notes | `ImprovisationConcepts.yaml`, `OutsideNotesSkill`, `ga_arpeggio_suggestions` | mapping tables |
| 16 | The Tonnetz and neo-Riemannian transformations | P, L and R, the Tonnetz, chromatic mediants | `NeoRiemannian.yaml`, `NeoRiemannianConfig.fs` | graphs of transformations |
| — | [Journal](journal/) | | | |

## Prerequisites

- The [.NET 10 SDK](https://dotnet.microsoft.com/download/dotnet/10.0) and [Git](https://git-scm.com/downloads). On Windows, run the course scripts from Git Bash.
- Under 20 MB of disk for GA's partial clone, build output included: the script fetches only the files of the three projects the program builds against.
- A guitar helps: every example can be played.

## Related modules on this site

The [Streeling](../streeling/) modules, generated from [GuitarAlchemist/Demerzel](https://github.com/GuitarAlchemist/Demerzel), cover some of the same ground from the musician's side. Each lesson links the relevant ones:

- [MUS-001 · What Is a Chord?](../streeling/music/mus-001-what-is-a-chord/) and [MUS-002 · Beyond Tonality](../streeling/music/mus-002-beyond-tonality/) (lessons 3 and 4);
- [MUS-006 · The Scale Universe](../streeling/music/mus-006-the-scale-universe/) (lessons 2 and 4);
- [MUS-003 · How Harmony Works](../streeling/music/mus-003-functional-harmony/) (lessons 5, 6 and 7) and [MUS-005 · Jazz Harmony for Guitar](../streeling/music/mus-005-jazz-harmony/) (lesson 7);
- [GTR-001 · The Fretboard Map](../streeling/guitar-studies/gtr-001-the-fretboard-map/), [GTR-002 · CAGED Geometry](../streeling/guitar-studies/gtr-002-caged-geometry/) and [GAA-001 · Your First Chord](../streeling/guitar-alchemist-academy/gaa-001-your-first-chord/) (lessons 1 and 3).

## Resources

- Mark Gotham et al., [*Open Music Theory*](https://viva.pressbooks.pub/openmusictheory/), version 2 (2023), a free, peer-reviewed textbook under CC BY-SA 4.0: the course's main theory source.
- Ian Ring, [*A Study of Musical Scales*](https://ianring.com/musictheory/scales/): every scale by its 12-bit number, the numbering GA uses, with a bracelet diagram for each.
- Wikipedia: [Interval vector](https://en.wikipedia.org/wiki/Interval_vector), [List of set classes](https://en.wikipedia.org/wiki/List_of_set_classes), [Guitar chord](https://en.wikipedia.org/wiki/Guitar_chord), [Circle of fifths](https://en.wikipedia.org/wiki/Circle_of_fifths), [Cadence](https://en.wikipedia.org/wiki/Cadence).
- [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga): the code this course reads.
