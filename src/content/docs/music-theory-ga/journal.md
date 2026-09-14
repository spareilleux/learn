---
title: Journal
description: Dated progress notes — GA pin and build, CI runs, differences between the theory, GA's code and GA's MCP tools, and items to verify.
sidebar:
  order: 99
---

## Progress

- [x] Course program: .NET 10, built against GA's `GA.Domain.Core` at a pinned commit
- [x] CI: every lesson's output compared with its expected file on three OSes
- [x] Lesson 1: notes, pitch classes and the fretboard
- [x] Lesson 2: scales, modes and 12-bit scale ids
- [x] Lesson 3: chords, symbols, inversions and voicings
- [x] Lesson 4: set classes, interval vectors and the Z-relation

## 2026-09-14 — Pinning GA and building against it

- GA is pinned on [`a826864`](https://github.com/GuitarAlchemist/ga/commit/a826864f3a012cad88e415954bf57eca0ce12aa6) (`chore(quality): snapshot 2026-09-14`), the head of `main` on the day. The author's local clone of GA is never used or modified: [`fetch-ga.sh`](https://github.com/spareilleux/learn/blob/79d2198/code/music-theory-ga/fetch-ga.sh) makes its own clone in `code/music-theory-ga/.ga`, ignored by Git.
- The clone is blobless (`--filter=blob:none`) with a non-cone sparse checkout of `/Directory.Build.props`, `GA.Core`, `GA.Business.Config` and `GA.Domain.Core`: Git downloads only the contents of those files at checkout. `GA.Domain.Core` references the two others; `GA.Business.Config` is an F# project, which the .NET SDK builds without extra setup.
- In Git Bash on Windows, the sparse patterns starting with `/` were rewritten into Windows paths (`C:/Program Files/Git/Common/...`) and matched nothing. `MSYS_NO_PATHCONV=1` fixes it.
- A `git grep` over the blobless clone hung: it fetched every blob of the repository one by one. Reading single files with `git show HEAD:<path>` fetches only those.
- The course project references GA with a plain `ProjectReference` ([`GaTheory.csproj`](https://github.com/spareilleux/learn/blob/79d2198/code/music-theory-ga/GaTheory/GaTheory.csproj#L9-L14)). Local build of GA's three projects plus the course: 5 to 13 seconds after the first restore.
- CI run [34903462624](https://github.com/spareilleux/learn/actions/runs/34903462624), for the push that contained commit `79d2198`: green on the three OSes, 34 s on Linux, 47 s on macOS, 67 s on Windows, clone included.

## 2026-09-14 — Verifying the theory

- The course's [`Theory.cs`](https://github.com/spareilleux/learn/blob/79d2198/code/music-theory-ga/GaTheory/Theory.cs) is written from the textbook definitions only, then compared with GA. Sources: *Open Music Theory* (chapters listed in each lesson), Wikipedia (MIDI tuning standard, Guitar tunings, Guitar chord, Blues scale, Interval vector, List of set classes), Ian Ring's scale 2741, OEIS A000029 and A000031.
- The Open Music Theory site and OEIS answer 403 to plain HTTP clients; the chapters were read in a browser.
- Checked in bulk on all 4096 sets: the course's Rahn prime form equals GA's minimal-id prime form for every set; 224 set classes and 352 transposition classes, as OEIS says. Forte's and Rahn's packings differ on 6 set classes, and on 17 of the 352 transposition classes, the figure *List of set classes* gives (the 17 were computed with the same algorithm outside the program).
- Bugs found in the course program itself while writing: the empty set crashed the prime-form sort key; the barre rule first counted open strings, copying GA; the voicing `x02010` was first named C6/A until the namer tried the bass as the root first.

## 2026-09-14 — Differences in GA's code (commit a826864)

Kept as `DIFF` lines in the expected outputs, so that CI notices when GA changes. None was reported upstream.

Lesson 1, notes:

- `Pitch.Flat.DFlat(octave)`, `FFlat` and `GFlat` build D, G and A ([`Pitch.cs#L285-L295`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Primitives/Notes/Pitch.cs#L285-L295)).
- `PitchParser`'s regex has no anchors and ignores case: `Pitch.Sharp.TryParse("Eb2")` succeeds with B2.
- `Note.Flat.Parse("B")` is B♭: the parser upper-cases, then reads a trailing `B` as a flat.
- `PitchClass.Parse("A")` is 10 (hexadecimal-style digit, on purpose), while the note A is 9.
- `SimpleIntervalSize.TryParse` throws instead of returning `false`.
- `Fretboard.GetPositionsForNote(Note.Sharp.C)` finds nothing: positions hold `Note.Chromatic`, and records of different types are never equal.
- Minor, no visible effect: `ValueObjectUtils.IsValueInRange(..., normalize: true)` computes `count = max - min` and adds 1 after the modulo, unlike `EnsureValueRange`; with normalization both always end in range ([`ValueObjectUtils.cs#L69-L92`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/ValueObjects/ValueObjectUtils.cs#L69-L92)).

Lesson 2, scales:

- `ModalFamily` groups the sets containing 0 by interval-class vector, not by rotation: 14 "modes" for harmonic minor (its own 7 and harmonic major's), 24 for blues (with its inversion and a Z-related class). Not a bug, but the name suggests rotations.
- The minor scales are spelled from A, so `Scale.NaturalMinor` has the id of C major (2741). Expected for a pitch-class set, surprising next to the other scales, spelled from C.

Lesson 3, chords:

- `ChordFormula.DetermineQuality` never returns `Major7`, `Minor7`, `HalfDiminished` or `Diminished7`, so `GetSymbolSuffix` gives `7` for maj7, `dim7` for m7♭5 and `dim6` for dim7.
- The `Chord` constructor spells every non-root note with sharps: `Eb` → `Eb G A#`, `Gb7` → `Gb A# C# E`.
- `Chord.AnalyzeChordFormula` skips `Notes[0]` as if it were the root; after `ToInversion(1)` it is the bass, the third is lost and the quality is `Other`.
- `Voicing.HasBarre` counts open strings: open C with a low E, open E and open G are "barre" chords.
- GA's voicing diagrams start at string 1 (high E), the reverse of chord charts.
- `CanonicalChordPatternCatalog` lists four interval sets twice (`9-sus4`/`dominant-11`, `major-6-add-9`/`6-9`, `minor-6-add-9`/`minor-6-9`, `augmented-7`/`dominant-7-sharp-5`); `TryFindExact` can never return the second name of each pair.
- The catalog matches intervals from the lowest note in the course's usage, so an inversion such as `032010` (C/E) has no name.

Lesson 4, set classes:

- `IntervalClassVectorId` packs the counts in base 12; the chromatic scale's counts of 12 overflow and decode to `<1 1 1 1 0 6>`.
- `CanonicalForteCatalog` describes its data as "the standard Forte-column values", but stores Rahn's spellings for the disputed classes (`5-20 01568`, `6-Z29 023679`), like Open Music Theory's table. The labels are right; only the comment is imprecise.
- `GrothendieckDelta.FromIcVs` turns a zero difference into `Ic1 = 1` on purpose, so sets with the same vector are reported at distance 1, and a triad's "neighbours at distance 1" are the other major and minor triads, itself included.

## 2026-09-14 — GA's MCP server

Called from this session through the GA MCP server (the server does not report a version; it may not run commit `a826864`). The code references are to `a826864`.

- `ga_set_class_subs("Am")` and `("G7")`: the right lists (all major and minor triads; all dominant and half-diminished sevenths), but every chord under `[maj]` (`c.EndsWith("")` in [`ChordAtonalTool.cs#L187-L190`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/ChordAtonalTool.cs#L187-L190)), and a description saying "Am and C are NOT equivalent".
- `ga_chord_intervals`: `Cm7b5` → P1 m3 P5 m7, `G7b9` → P1 M3 P5 m7, `C9` → P1 M3 P5 M9, `Cmaj9` → P1 M3 P5 M9. The F# closure keeps one interval per extension and ignores alterations ([`DomainClosures.fs#L85-L98`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L85-L98)). `ga_parse_chord("Cm7b5")` did parse `alt:b5`.
- `ga_chord_to_set`, which takes its pitch classes from the same closure: `Cm7b5` → `{C, Eb, G, Bb}`, 4-26 (should be 4-27, with G♭); `Cdim7` → `{C, Eb, F#, Bb}`, 4-27, "Scale: Major Seventh" (should be 4-28, with A); `C` → 3-11, prime `0 3 7`, a modal family of 6.
- `ga_icv_neighbors("C", 1)`: twelve identical lines `<0 0 1 1 1 0> Δ=1 Forte:3-11 [Major Triad]`, explained by the zero-delta rule above.
- `ga_scale_by_id(2741)`: Major, with `Forte Number: Some(n/a)` (7-35 expected). `ga_scale_by_name("Dorian")`: not found.
- `get_tuning(Guitar, Standard)`: E2 A2 D3 G3 B3 E4, right. `get_chord_voicings("C", maxFret 3)`: "An error occurred". `ga_search_voicings("C major open chord")`: the "open" constraint was ignored (diagram `8-8-x-x-7-x`, labelled C/E).

## 2026-09-14 — Notes on the Streeling modules

The modules are generated from GuitarAlchemist/Demerzel and were not modified; lessons link them where they help.

- MUS-006, "Modes as Rotations": a circular left shift of the id transposes (C major shifted by 2 is D major, 2774); getting D Dorian on C needs the opposite shift (1709). The practice answer "rotate left by 2 semitones → 2nd mode" has the same direction problem.
- MUS-006 says Forte "identified 224 distinct set classes for cardinalities 3 through 9"; 224 counts all cardinalities from 0 to 12.
- MUS-002 derives the prime form of the open strings (E A D G B) as `[0,2,5,7,9]`, comparing pitch classes instead of intervals in the tie-break; the prime form is `(02479)`. The same module answers "are major and minor triads different set classes? Yes", then puts both in 3-11, and writes prime forms in square brackets where Open Music Theory uses parentheses.
- GTR-002 labels the C shape `x 3 2 0 1 0` with "Strings: 5-4-3-2-1": six symbols for five strings, the `x` being string 6.

## To verify

- Whether GA's full chord recognizer (not `TryFindExact` alone) names inversions such as `032010`; the MCP voicing search suggests it does (`C/E`), but the course did not call it.
- The MCP server's commit: the answers above were not reproduced against a server built from `a826864`.
