---
title: "Appendix C: every divergence, and whose bug it is"
description: The forty DIFF rows of lessons 1 to 7, each with a verdict — Guitar Alchemist's bug or the course's error — the line of GA that causes it, and the nineteen distinct defects they collapse into.
sidebar:
  label: "Appendix C: every divergence"
  order: 92
---

Every lesson of this course prints a table with three columns: what the course computes from the textbook definition, what Guitar Alchemist answers for the same question, and `ok` or `DIFF`. Lessons 1 to 7 produce **40 `DIFF` rows**. A reader is entitled to ask the obvious question about each one: *is that a bug in GA, or is the course wrong?*

This appendix answers it, row by row. The short version:

| | rows |
|---|---|
| GA's bug, the course matches the theory | 39 |
| Neither: a defensible convention (with a real flaw underneath) | 1 |
| The course's error | 0 |

Forty rows, but not forty problems: they collapse into **19 distinct defects**, because one wrong line can spoil eight rows. The grouping below is the useful view; the per-lesson tables after it are the detail.

:::note[How to check any row yourself]
Nothing here is an opinion about code style. Each row is a value computed twice and compared by a program, on three operating systems, at a pinned commit of GA. Clone this repository and run `bash code/music-theory-ga/check.sh`, or run one lesson with `dotnet run --project code/music-theory-ga/GaTheory -c Release -- l3`. GA is read at commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6) and never modified.
:::

:::tip[Upstream reconciliation]
The original `a826864` snapshot remains the reproducible baseline for the 40 `DIFF` rows. The executable findings were reconciled in [GA #711](https://github.com/GuitarAlchemist/ga/pull/711), merged as [`b363c3f`](https://github.com/GuitarAlchemist/ga/commit/b363c3f086608f850be026546f85ef13c6e6bfb8) on 2026-09-21. Defects 1–5, 7–11 and 13–18 are fixed and covered by regression tests. Entries 6, 12 and 19 remain explicit design or representation boundaries rather than silent fixes.
:::

## The 19 defects

| # | Defect in GA | Rows | Lessons |
|---|---|---|---|
| 1 | [`Pitch.Flat.DFlat/FFlat/GFlat(Octave)`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Primitives/Notes/Pitch.cs#L285-L295) build the wrong note: each returns the note of the line below it | 3 | 1 |
| 2 | [`PitchParser`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Primitives/Notes/PitchParser.cs#L20-L25)'s regex has no anchors and ignores case, so `Eb2` matches as `b2` = B2 | 1 | 1 |
| 3 | [`Note.Flat.TryParse`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Primitives/Notes/Note.cs#L219-L237) upper-cases before replacing `♭`, so `B` becomes B♭ and `D♭` is rejected | 1 | 1 |
| 4 | [`PitchClass.TryParse`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClass.cs#L252-L268) tries the hex-like aliases `A`=10, `B`=11 before note names | 1 | 1 |
| 5 | [`SimpleIntervalSize.TryParse`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Primitives/Intervals/SimpleIntervalSize.cs#L155-L164) and `CompoundIntervalSize.TryParse` throw instead of returning `false` | 1 | 1 |
| 6 | [`ModalFamily`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/ModalFamily.cs#L114-L128) groups sets by interval-class vector but calls the members `Modes` | 2 | 2 |
| 7 | [`ChordFormula.DetermineQuality`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Harmony/ChordFormula.cs#L172-L214) never returns `Major7`, `Minor7`, `HalfDiminished` or `Diminished7` | 2 | 3 |
| 8 | [`DetermineExtension`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Harmony/ChordFormula.cs#L216-L294) reads nine semitones as a major sixth, never a diminished seventh | 1 | 3 |
| 9 | [`Note.Chromatic.ToAccidented`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Primitives/Notes/Note.cs#L75-L77) is `ToSharp().ToAccidented()`: every black key gets a sharp name | 8 | 3 |
| 10 | [`Chord`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Harmony/Chord.cs#L241-L250) rotates its note list for an inversion, then re-analyses from the bass as if it were the root | 1 | 3 |
| 11 | [`Voicing.HasBarre`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Instruments/Fretboard/Voicings/Core/Voicing.cs#L73-L80) counts fret 0, so open strings make a barre | 3 | 3 |
| 12 | [`IntervalClassVectorId`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/IntervalClassVectorId.cs#L39-L85) packs six counts as base-12 digits, and a count of 12 overflows its digit | 1 | 4 |
| 13 | [`KeyTools.GetParallelKey`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/KeyTools.cs#L161-L166) has the same body as `GetRelativeKey`: it keeps the signature instead of the tonic | 5 | 5 |
| 14 | [`KeyTools.GetNeighboringKeys`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/KeyTools.cs#L204) looks a key up by its accidentals instead of its name, and throws | 1 | 5 |
| 15 | [`Key.GetInterval`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Tonal/Key.cs#L76) passes its arguments the wrong way round and returns the inversion | 2 | 5 |
| 16 | [`Key.Major.TryParse`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Tonal/Key.cs#L155-L158) throws on an unparseable root although it has a `return false` path | 1 | 5 |
| 17 | [`HarmonicFunction.FromDegree`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Tonal/HarmonicFunction.cs#L32) sees a degree number only, and its enum has no `Subtonic` | 1 | 6 |
| 18 | [`Cadences.yaml`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Config/Cadences.yaml#L124-L129) numbers one minor-key row from the parallel major (`♭iii` for G in E minor) | 1 | 7 |
| 19 | [`PitchClassSet.ClosestDiatonicKey`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClassSet.cs#L609-L615) breaks the major/minor tie on a normal form, which cannot encode a mode | 4 | 7 |

Three patterns account for most of them.

- **Copy-paste inside a block of near-identical members**: defects 1 and 13. Three factory methods each returning the next line's note, and a `GetParallelKey` whose body was never changed after being copied from `GetRelativeKey`.
- **A pitch class asked to remember a letter**: defects 8, 9 and 12, and the core of 19. A pitch class, a set id and an interval count are all *reductions*: they deliberately throw away the spelling, the octave or the tonic. Every row in this group is that discarded information being asked for again downstream.
- **`TryParse` that throws**: defects 5 and 16, in three types. The [`IParsable<TSelf>.TryParse`](https://learn.microsoft.com/dotnet/api/system.iparsable-1.tryparse) contract says a failed parse returns `false`.

## Lesson 1: notes, pitch classes and the fretboard

| Row | GA answers | Verdict | Why |
|---|---|---|---|
| `Pitch.Flat.DFlat(4)` → `Db4` | `D4` | GA, defect 1 | The method builds `Note.Flat.D`, the natural, although `Note.Flat.DFlat` exists. |
| `Pitch.Flat.FFlat(4)` → `Fb4` | `G4` | GA, defect 1 | It builds `Note.Flat.G`. F♭ is enharmonically E and can never be G. |
| `Pitch.Flat.GFlat(4)` → `Gb4` | `A4` | GA, defect 1 | It builds `Note.Flat.A`, the next line's note again. |
| `Pitch.Sharp.TryParse("Eb2")` → rejected | `B2` | GA, defect 2 | `([A-G])(#?)(10\|11\|[0-9])` is unanchored and case-insensitive, so the match slides past the `E` and reads `b2`. |
| `Note.Flat.Parse("B")` → `B` | `Bb` | GA, defect 3 | `ToUpperInvariant()` runs before `Replace("♭", "b")`, so the trailing-`B` test both over- and under-fires. |
| `PitchClass.Parse("A")` → `9` | `10` | **Neither** | Reading `A` as the digit 10 is a documented set-theory convention, so 10 is not wrong. But the aliases are tried before note names, so the note A can never be parsed as 9 — that part is a defect. |
| `IntervalSize.TryParse("x")` → `False` | throws `ArgumentException` | GA, defect 5 | `SimpleIntervalSize` and `CompoundIntervalSize` both throw where the contract requires `false`. |

An extra finding not in any row: the `Flat(Octave)` factory block has **no `EFlat(Octave)` and no `BFlat(Octave)` at all**, although the per-octave properties `EFlat0`, `BFlat0` and their siblings exist. Only that overload family is unreliable.

## Lesson 2: scales and modes

| Row | GA answers | Verdict | Why |
|---|---|---|---|
| harmonic minor has 7 modes | 14 | GA, defect 6 | A mode is a rotation, so a seven-note scale has seven. GA's 14 are harmonic minor's 7 rotations plus the 7 of its mirror image, harmonic major, which has the same interval-class vector. |
| the blues scale has 6 modes | 24 | GA, defect 6 | 6 rotations, 6 of the mirror, and 12 sets of a Z-related set class that shares the vector. |

GA's class comment describes what it really builds — sets "that share the same interval vector" — so the computation is right and the *name* is wrong. [Ian Ring](https://ianring.com/musictheory/scales/2477) answers 7 and 6.

## Lesson 3: chords, symbols, inversions and voicings

| Row | GA answers | Verdict | Why |
|---|---|---|---|
| `Cmaj7` → `maj7` | `7` | GA, defect 7 | Major plus seventh, and `Major` contributes no prefix, so it prints the dominant seventh's symbol. |
| `Cm7b5` → `m7b5` | `dim7` | GA, defect 7 | The half-diminished chord prints with the fully diminished chord's symbol. |
| `Cdim7` → `dim7` | `dim6` | GA, defect 8 | Nine semitones are read as a major sixth; only the spelling B𝄫 says otherwise, and a formula in semitones has none. |
| `Cm` → `C Eb G` | `C D# G` | GA, defect 9 | |
| `Eb` → `Eb G Bb` | `Eb G A#` | GA, defect 9 | By its letters E♭–A♯ is a fourth, not the chord's fifth. |
| `Ab` → `Ab C Eb` | `Ab C D#` | GA, defect 9 | |
| `Bbm7` → `Bb Db F Ab` | `Bb C# F G#` | GA, defect 9 | Two of four degrees land on the wrong letter. |
| `Cdim` → `C Eb Gb` | `C D# F#` | GA, defect 9 | F♯ names an augmented fourth, not a diminished fifth. |
| `Cdim7` → `C Eb Gb Bbb` | `C D# F# A` | GA, defect 9 | The double flat is the textbook spelling; A is a sixth. |
| `Gb7` → `Gb Bb Db Fb` | `Gb A# C# E` | GA, defect 9 | |
| exercise: `F#dim7` → `F# A C Eb` | `F# A C D#` | GA, defect 9 | The letters of a diminished seventh chord are F A C E. |
| `C/E` → inversion 1, Major | inversion 1, Other | GA, defect 10 | After the rotation the bass sits in `Notes[0]`, so the re-analysis skips the third and finds no third at all. |
| `032010` is not a barre | barre | GA, defect 11 | |
| `022100` is not a barre | barre | GA, defect 11 | |
| `320003` is not a barre | barre | GA, defect 11 | Three open strings share "fret 0"; no finger presses an open string. |

Two of these have a correct implementation elsewhere in the same commit: [`CadenceChordParser`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Chords/Parsing/CadenceChordParser.cs#L11-L14) and the F# [`DslCommand`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Types/DslCommand.fs#L227-L230) know the right symbols, and [`DetectBarreRequirement`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Fretboard/Voicings/Analysis/VoicingPhysicalAnalyzer.cs#L219-L233) does test `fret > 0` and does require adjacent strings.

## Lesson 4: set classes

| Row | GA answers | Verdict | Why |
|---|---|---|---|
| chromatic aggregate ICV → `<12 12 12 12 12 6>` | `<1 1 1 1 0 6>` | GA, defect 12 | The counts are computed correctly, then packed as base-12 digits where 12 does not fit. |

GA documents this one itself, as a "KNOWN LIMITATION" in the type's own comment, with base 13 or a six-field record noted as the fix. It is the only affected set: an 11-note set peaks at 10 per interval class.

## Lesson 5: keys and the circle of fifths

| Row | GA answers | Verdict | Why |
|---|---|---|---|
| parallel of C → C minor | A minor | GA, defect 13 | The parallel key shares the *tonic*; GA keeps the *signature*, which is the relative key. |
| parallel of A♭ → A♭ minor | F minor | GA, defect 13 | |
| parallel of A minor → A major | C major | GA, defect 13 | |
| parallel of E minor → E major | G major | GA, defect 13 | |
| exercise: parallel of A♭ → A♭ minor, 7 flats | F minor | GA, defect 13 | The exercise reruns the same expression. |
| neighbours of C → F, G | throws `InvalidOperationException` | GA, defect 14 | The tool looks the key up again by `""` (C major's accidentals) instead of `"Key of C"`. |
| `Key.Major.C.GetInterval(E)` → M3 | m6 | GA, defect 15 | |
| `Key.Major.G.GetInterval(F#)` → M7 | m2 | GA, defect 15 | Both return the inversion of the documented interval. |
| `Key.Major.TryParse("H")` → `False` | throws | GA, defect 16 | The method has a `return false` path a few lines below. |

GA's core has no relative-key or parallel-key member at all, so the MCP tool is the only code answering these two questions. Its comment inside the *correct* method already swaps the two words, so the confusion is in the vocabulary, not only in one body.

## Lesson 6: the chords of a key

| Row | GA answers | Verdict | Why |
|---|---|---|---|
| VII of A natural minor → G major, **Subtonic** | **LeadingTone** | GA, defect 17 | The seventh degree of natural minor is a whole step below the tonic, so it is the subtonic; a leading tone is a half step below. |

## Lesson 7: cadences and progressions

| Row | GA answers | Verdict | Why |
|---|---|---|---|
| Chromatic Mediant (Metal), Em–Gm in E minor → `i iii` | `i biii` | GA, defect 18 | G is the unaltered third degree of E minor. Read in E minor, ♭iii points at G♭, which the chord does not contain. GA's own F# analyser uses the minor-scale numerals. |
| key of `C F G C` → C major | A minor | GA, defect 19 | |
| key of `G D Em C` → G major | E minor | GA, defect 19 | |
| key of `Dm7 G7 Cmaj7` → C major | A minor | GA, defect 19 | |
| key of `C Am F G7` → C major | A minor | GA, defect 19 | Every seven-note diatonic collection has the normal form `0 1 3 5 6 8 T`, which contains 3, so the mode flag is always raised and the answer is always the relative minor. |

The last four are worth separating from the rest of this appendix, because the fix is not a line: a pitch-class set **has no tonic**. `C F G C` and `Am F C G` are the same set. No function of the set alone can name one of the two relative keys; naming one needs the order of the chords, which `ClosestDiatonicKey` never receives. Returning a key signature, or the pair — which `GetCompatibleKeys` already does — is the honest answer for that input.

## What this appendix is not

It is not a bug report filed against GA, and nothing here has been published outside this repository. It is the record of what a reader should conclude when a lesson prints `DIFF`: in this course, so far, it has meant GA, every time but one.

It is also not a claim that the course is authoritative. The course's own computations are plain implementations of textbook definitions, and its barre rule, its key-finding heuristic and its chord-symbol table are all approximations it declares as such where they appear. Where the course and GA agree, both could still be wrong; those rows print `ok` and this appendix says nothing about them.

## Sources

- Mark Gotham et al., [*Open Music Theory*](https://viva.pressbooks.pub/openmusictheory/) v2: ["Triads"](https://viva.pressbooks.pub/openmusictheory/chapter/triads/), ["Seventh Chords"](https://viva.pressbooks.pub/openmusictheory/chapter/seventh-chords/), ["Mediants"](https://viva.pressbooks.pub/openmusictheory/chapter/mediants/), ["Roman Numerals"](https://viva.pressbooks.pub/openmusictheory/chapter/roman-numerals/), "Minor Scales, Scale Degrees, and Key Signatures".
- Ian Ring, [*A Study of Musical Scales*](https://ianring.com/musictheory/scales/): [harmonic minor](https://ianring.com/musictheory/scales/2477), [the blues scale](https://ianring.com/musictheory/scales/1257), [the chromatic scale](https://ianring.com/musictheory/scales/4095).
- Wikipedia: [Interval vector](https://en.wikipedia.org/wiki/Interval_vector), [Barre chord](https://en.wikipedia.org/wiki/Barre_chord), [Cadence](https://en.wikipedia.org/wiki/Cadence).
- [`IParsable<TSelf>.TryParse`](https://learn.microsoft.com/dotnet/api/system.iparsable-1.tryparse).
- [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga) at [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6).
