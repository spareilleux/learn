---
title: Music theory for Guitar Alchemist — Mission
description: The music theory behind Guitar Alchemist, for developers who play a little guitar and don't read music — each concept explained, written down, then found in GA's C# code and checked against it.
sidebar:
  label: Mission
  order: 0
---

:::note[How this course is tested]
Every table of output in the lessons comes from [`code/music-theory-ga`](https://github.com/spareilleux/learn/tree/main/code/music-theory-ga), a .NET 10 program that computes each concept from the textbook definitions and asks [Guitar Alchemist](https://github.com/GuitarAlchemist/ga) for the same answer. It builds against GA's `GA.Domain.Core` project, cloned at commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6). [`.github/workflows/music-ga-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/music-ga-examples.yml) runs it on Linux, Windows and macOS and compares the output, `DIFF` lines included, with the expected files. The outputs were captured in September 2026.
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
- build scales and modes from step patterns and read them as 12-bit numbers;
- read chord symbols, spell chords, recognise inversions and name guitar voicings;
- compute interval-class vectors, prime forms and Forte numbers, and explain the Z-relation;
- find each of these in GA's code, and say where GA agrees with the theory and where it doesn't.

## Outline

| # | Lesson | Theory | In GA | If you write C# |
|---|---|---|---|---|
| 1 | [Notes, pitch classes and the fretboard](01-notes-and-the-fretboard/) | pitch, pitch class, accidentals, intervals, tuning | `PitchClass`, `Note`, `Interval`, `Tuning`, `Fretboard` | value objects, closed record hierarchies |
| 2 | [Scales, modes and 12-bit scale ids](02-scales-and-modes/) | major and minor scales, modes, transposition | `PitchClassSetId`, `Scale`, `MajorScaleMode`, `ModalFamily` | `[Flags]`, bit rotation, `PopCount` |
| 3 | [Chords, symbols, inversions and voicings](03-chords-and-voicings/) | triads, seventh chords, chord symbols, inversions | `Chord`, `ChordFormula`, `CanonicalChordPatternCatalog`, `Voicing` | parsers, `switch` expressions |
| 4 | [Set classes, interval vectors and the Z-relation](04-set-classes/) | T/I equivalence, interval-class vectors, prime forms, Forte numbers | `SetClass`, `IntervalClassVector`, `ForteCatalog`, MCP tools | canonical forms, equivalence classes |
| — | [Journal](journal/) | | | |

## Prerequisites

- The [.NET 10 SDK](https://dotnet.microsoft.com/download/dotnet/10.0) and [Git](https://git-scm.com/downloads). On Windows, run the course scripts from Git Bash.
- Under 20 MB of disk for GA's partial clone, build output included: the script fetches only the files of the three projects the program builds against.
- A guitar helps: every example can be played.

## Related modules on this site

The [Streeling](../streeling/) modules, generated from [GuitarAlchemist/Demerzel](https://github.com/GuitarAlchemist/Demerzel), cover some of the same ground from the musician's side. Each lesson links the relevant ones:

- [MUS-001 · What Is a Chord?](../streeling/music/mus-001-what-is-a-chord/) and [MUS-002 · Beyond Tonality](../streeling/music/mus-002-beyond-tonality/) (lessons 3 and 4);
- [MUS-006 · The Scale Universe](../streeling/music/mus-006-the-scale-universe/) (lessons 2 and 4);
- [GTR-001 · The Fretboard Map](../streeling/guitar-studies/gtr-001-the-fretboard-map/), [GTR-002 · CAGED Geometry](../streeling/guitar-studies/gtr-002-caged-geometry/) and [GAA-001 · Your First Chord](../streeling/guitar-alchemist-academy/gaa-001-your-first-chord/) (lessons 1 and 3).

## Resources

- Mark Gotham et al., [*Open Music Theory*](https://viva.pressbooks.pub/openmusictheory/), version 2 (2023), a free, peer-reviewed textbook under CC BY-SA 4.0: the course's main theory source.
- Ian Ring, [*A Study of Musical Scales*](https://ianring.com/musictheory/scales/): every scale by its 12-bit number, the numbering GA uses.
- Wikipedia: [Interval vector](https://en.wikipedia.org/wiki/Interval_vector), [List of set classes](https://en.wikipedia.org/wiki/List_of_set_classes), [Guitar chord](https://en.wikipedia.org/wiki/Guitar_chord).
- [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga): the code this course reads.
