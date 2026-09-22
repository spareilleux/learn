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
- [x] Diagrams: bracelets, chord grids, fretboard and circles of fifths drawn by the course program, checked by CI
- [x] Lesson 5: keys, key signatures and the circle of fifths
- [x] Lesson 6: the chords of a key
- [x] Lesson 7: cadences, ii–V–I and the key of a progression
- [x] Lesson 8: the ukulele and the bass
- [x] Appendix A: every instrument in GA's catalogue
- [x] Appendix B: the OPTIC hierarchy
- [x] Appendix C: a verdict on every `DIFF` row of lessons 1 to 7
- [ ] Lessons 9 to 17 (see the outline on the mission page)

## 2026-09-21 — Appendix C reconciled upstream

- [GA #711](https://github.com/GuitarAlchemist/ga/pull/711) reconciled the executable Appendix C findings and was merged as [`b363c3f`](https://github.com/GuitarAlchemist/ga/commit/b363c3f086608f850be026546f85ef13c6e6bfb8).
- Defects 1–5, 7–11 and 13–18 are fixed with regression coverage. Entries 6, 12 and 19 remain documented design or representation boundaries.
- The course stays pinned to `a826864` so the original 40 `DIFF` rows remain reproducible; the appendix now links the newer upstream outcome instead of rewriting that historical evidence.

## 2026-09-18 — Upstream GA fixes: resolving the findings

- **16 of the 19 defects resolved upstream in GA**:
  - Notes & pitch parsing: `Pitch.Flat` factories (`DFlat`, `FFlat`, `GFlat`, `EFlat`, `BFlat`) corrected; `PitchParser` anchored regexes with compiled static patterns; `Note.Flat.TryParse` fixed so natural B parses as B (not B♭) and Unicode `♭` is handled without case mutation; `PitchClass.TryParseSetNotation` separated from `TryParse`; `SimpleIntervalSize.TryParse` and `CompoundIntervalSize.TryParse` return `false` on invalid inputs instead of throwing.
  - Chords & voicings: `ChordFormula` quality and suffix classification updated (dim7 distinguished from 6th/13th, `m7b5` and `dim7` preserved); spelling-aware interval transposition added to `Chord` constructor; original `Root` and `Formula` preserved across chord inversions; `Voicing.HasBarre()` open strings (fret 0) excluded.
  - Keys & tonality: `KeyTools.GetParallelKey` preserves tonic with opposite mode; `KeyTools.GetNeighboringKeys` uses signature count lookup; `Key.GetInterval` root-to-note argument order restored; `Key.Major.TryParse` returns `false` on invalid root; `HarmonicFunction.Subtonic` enum member added; `Cadences.yaml` `iii` Roman numeral fixed in E Minor.
  - Defect 12 (ICV packing base 12) remains pinned to preserve existing catalog numbering; defect 6 (ModalFamily) and defect 19 (ClosestDiatonicKey tonic ambiguity) documented as design/heuristic limitations.

## 2026-09-15 — A verdict on every divergence, the ukulele and the bass, three appendices

- **All 40 `DIFF` rows of lessons 1 to 7 now have a verdict**, in [Appendix C](../appendix-ga-findings/): 39 are GA's bug, one (`PitchClass.Parse("A")`) is a defensible convention with a precedence flaw underneath, and none is an error in the course. They come from **19 distinct defects** — one wrong line in `Note.Chromatic.ToAccidented` accounts for eight rows on its own — and they fall into three families: copy-paste inside a block of near-identical members, a reduced type asked for the information it was built to discard, and `TryParse` that throws.
- Nine sentences across lessons 1, 2, 3, 4, 6 and 7 presented a divergence as a matter of taste and now give the verdict. The worst of them was lesson 2's "Neither answer is wrong" about `ModalFamily`: a mode is a rotation, a scale has as many modes as it has notes, and Ian Ring's pages answer 7 and 6 where GA answers 14 and 24.
- **Lesson 8, the ukulele and the bass.** Two facts that guitar-shaped code gets wrong: a ukulele is re-entrant (its fourth string is higher than its third), and a bass is tuned entirely in fourths (it has none of the guitar's one irregular pair). A ukulele's gaps are 5 4 5, the same as the guitar's top four strings; a baritone ukulele *is* those four strings; a bass is the bottom four, an octave down.
- `Tuning.BuildPitchArray` decides which end of a tuning is string 1 by comparing the **first pitch with the last one only**. That works on any tuning that rises or falls all the way. On GA's own two 5-string banjo tunings, whose short drone string is written first and sounds higher than the last string, it keeps the file's order and numbers the strings backwards. `Str`'s comment, "String 1 is the string with the highest pitch", cannot hold for that instrument: string 1 is D4 and string 5 is G4.
- `Fretboard.GetNote` documents its first parameter as "Zero-based string index (0 = lowest string)" and then indexes `Tuning[stringIndex + 1]`, where string 1 is the highest. The comment is wrong, not the code.
- **Appendix A: `InstrumentsConfig` returns one instrument.** The course program now references `GA.Business.Config` and calls `getAllInstruments()` on the same run that reads the file itself: the file holds **122 instruments and 280 tunings**, the loader returns **1 and 2**. `InstrumentsYaml` expects a document with an `Instruments:` list of `{ Name, Tunings }`; the file is a mapping of instruments, each a mapping of tunings, with no `Instruments` key anywhere. Both the null check and the `with _ ->` handler fall back to `defaultData ()`, two hard-coded guitar tunings. Nothing fails and nothing logs.
- Seven of the 280 tunings are not pitches: two pedal steel entries begin with their tuning's *name* (`C6`, `E9`), one begins with the literal word `Tuning`, one is the instrument's own name, one is missing an octave, and the two harp guitars use `|` to separate the sub-bass strings. The same name-as-a-pitch slip produced the ukulele's five-pitch tunings, which parse silently.
- **Appendix B: the OPTIC hierarchy.** One fingering climbed to a set class, one equivalence at a time, with GA's type at each rung — `PitchClassSet` after O, P and C, `TranspositionClass` after T, `SetClass` after I — and the counts 4096, 352 and 224 agreeing with the course. GA's OPTIC-K embedding schema splits the same ladder in two: STRUCTURE (dimensions 6-29, weight 0.45) is "pitch-class set invariants (O+P+T+I)", MORPHOLOGY (30-53, weight 0.25) is "physical fretboard realization", which is everything the ladder discards. The weights and ranges are read from the skill document, not run: *to verify*.
- The appendix also explains Ian Ring's [scale finder](https://ianring.com/musictheory/scales/finder/) as the ladder made clickable — Rotate is T, Reflect is I — and [Harmonious](https://harmoniousapp.net/) as the same material seen from the other end, by key and by chord rather than by set number.
- The course program grows to ten entry points (`l1` to `l10`), all in `check.sh`. `Diagrams.Fretboard` now takes a tuning, so the ukulele and the bass get their own fretboard diagrams; the fourteen existing SVG files are byte-identical after the change.
- **You can hear the lessons now.** A ```play code block becomes a player: the pitches on one line sound together, one line after another. The samples are one recorded note per semitone of FluidR3_GM's nylon acoustic guitar, pinned on one commit of [`gleitz/midi-js-soundfonts`](https://github.com/gleitz/midi-js-soundfonts) and fetched on the first click — nothing is synthesised, no audio file is stored here, and every note is a sample played at its own pitch. Standard tuning is in lesson 1, C ionian against C dorian in lesson 2, the four voicings in lesson 3, ii–V–I in lesson 7, and the guitar shape against the same fingers on a ukulele in lesson 8. The block is code, so it is identical in the three languages; only the button's label follows the page.

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

## 2026-09-15 — Diagrams

- The diagrams are SVG files written by the course program ([`Diagrams.cs`](https://github.com/spareilleux/learn/blob/a2439ba/code/music-theory-ga/GaTheory/Diagrams.cs)) into `src/assets/music-theory-ga/`, then imported by the `.mdx` lessons as components, so they are inlined in the page. Their colours are `currentColor` and Starlight's CSS variables (`--sl-color-accent-high`, `--sl-color-orange-high`, `--sl-color-green-high`, `--sl-color-bg`), with a light fallback, and they follow the site's light or dark theme. They contain note names and numbers only, so the three languages share the same files; the description is in each page's `aria-label` and in the paragraph before the figure.
- `check.sh` regenerates them in memory and compares them with the committed files; CI fails when a diagram is out of date. Regenerate with `dotnet run --project GaTheory -c Release -- svg ../../src/assets/music-theory-ga`.
- GA has React components for the same pictures, which the course reads but does not reuse: `BraceletNotation.tsx`, `FretDiagram.tsx` and `VexChordDiagram.tsx`, under `ReactComponents/ga-react-components/src/components`. Reading `BraceletNotation` and its `NoteGroup` (not run, *to verify* in a browser): the dots and labels are placed at `angle − 90°`, but the spokes of `NoteGroup` use `cos(angle)` without the offset, so they would be rotated by a quarter turn; and `findSymmetryAxes` only tests axes through a note, missing axes between two notes, and adds each axis twice.

## 2026-09-15 — Lessons 5 to 7: differences in GA's code (commit a826864)

Kept as `DIFF` lines in the expected outputs. None was reported upstream.

Lesson 5, keys:

- `Key.GetInterval(note)` returns `note.GetInterval(Root)`, the interval from the note up to the root: `Key.Major.C.GetInterval(E)` is m6, not M3 ([`Key.cs#L70-L76`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Tonal/Key.cs#L70-L76)).
- `Key.Major.TryParse("H")` throws `InvalidOperationException` instead of returning `false`, and `Key.Minor.TryParse` has the same code ([`Key.cs#L153-L186`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Tonal/Key.cs#L153-L186)).
- The MCP tools `get_parallel_key` and `get_relative_key` have the same body: the other mode on the same signature, so the parallel key of C is A minor ([`KeyTools.cs#L135-L169`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/KeyTools.cs#L135-L169)).
- `get_neighboring_keys` passes `key.KeySignature.ToString()`, the list of accidentals, to a lookup by key name, and fails ([`KeyTools.cs#L197-L215`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/KeyTools.cs#L197-L215)).

Lesson 6, chords of a key:

- `HarmonicFunctionExtensions.FromDegree(7)` is always `LeadingTone`, also for the subtonic of natural minor; `ScaleDegreeFunction.Subtonic` exists but is not used there.
- `ga_diatonic_chords` names roots from a 12-name table: F♯ major gets `Fdim` (E♯dim) and G♭ major gets `B` (C♭) ([`DomainClosures.fs#L23-L36`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L23-L36)). The core's `Key.Notes` spells both keys right.
- Code reading only (`GA.Domain.Services` is not built by the course, *to verify*): `HarmonicFunctionAnalyzer.Parse` tests `Contains("tonic")` before `"supertonic"` and `"mediant"` before `"submediant"`, so "Supertonic" would parse as `Tonic` and "Submediant" as `Mediant` ([`HarmonicFunctionAnalyzer.cs#L29-L72`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Tonal/HarmonicFunctionAnalyzer.cs#L29-L72)). `ToPrimaryCategory` groups the mediant and submediant with the tonic, where Open Music Theory calls iii and vi weak predominants: a choice of textbook, not a bug.

Lesson 7, cadences and progressions:

- `Cadences.yaml` numbers "Chromatic Mediant (Metal)", Em–Gm in E minor, as `i biii`, from E major; the Andalusian cadence in the same file is numbered from the notes of E Phrygian. Its "Phrygian Half Cadence" is ♭II–i, where the classical term means iv⁶–V in minor.
- `PitchClassSet.ClosestDiatonicKey` breaks ties with "the normal form contains pitch class 3, so minor". The normal form of a major scale's notes is `0 1 3 5 6 8 T`, so C F G C, G D Em C, Dm7 G7 Cmaj7 and C Am F G7 come out in the relative minor ([`PitchClassSet.cs#L597-L660`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClassSet.cs#L597-L660)).
- `ga_key_from_progression` and `ga_analyze_progression` score keys by chord roots only, against the natural minor scale, and prefer the first chord's root ([`GuitaristProblemTools.cs#L157-L223`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GuitaristProblemTools.cs#L157-L223), [`DomainClosures.fs#L255-L336`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L255-L336)).

## 2026-09-15 — GA's MCP server, keys and progressions

Same caveat as on 2026-09-14: the server does not report its version.

- `get_parallel_key("Key of C")` → `Key of Am`. `get_relative_key("Key of Ab")` → `Key of Fm`, right. `get_key_signature_info("Key of Gm")` → root G, `Bb Eb`, notes G A Bb C D Eb F, right.
- `get_neighboring_keys("Key of C")` and `get_diatonic_chords("A minor")`: "An error occurred invoking …".
- `ga_diatonic_chords`: F♯ major → `F#, G#m, A#m, B, C#, D#m, Fdim`; G♭ major → `Gb, Abm, Bbm, B, Db, Ebm, Fdim`.
- `ga_key_from_progression(["Am","F","C","G"])` → best guess A minor (then C major and D minor, all 4/4), while the tool's description promises C major; `(["Dm7","G7","Cmaj7"])` → D minor (then C major and C minor).
- `ga_analyze_progression("Am Dm E7 Am")` → "Key: A major, I IV V I"; `("Dm7 G7 Cmaj7")` → "Key: D minor, i iv VII".

## 2026-09-15 — Notes on the Streeling modules, continued

- MUS-003, "Guitar Example — D7 to G Voice Movements": the tab puts C at fret 1 of the high E string and F♯ at fret 1 of the B string. Fret 1 is F on the high E string and C on the B string; open D7 (`xx0212`) has F♯ at fret 2 of string 1 and C at fret 1 of string 2. The lessons link MUS-003 for its functions, cadences and closely related keys, not for this example.
- MUS-003 puts iii and vi in the tonic family; lesson 6 gives both readings.

## To verify

- Whether GA's full chord recognizer (not `TryFindExact` alone) names inversions such as `032010`; the MCP voicing search suggests it does (`C/E`), but the course did not call it.
- The MCP server's commit: the answers above were not reproduced against a server built from `a826864`.
- `HarmonicFunctionAnalyzer.Parse` on "Supertonic" and "Submediant", by a test in GA.
- The spokes and symmetry axes of GA's `BraceletNotation`, rendered in a browser.
