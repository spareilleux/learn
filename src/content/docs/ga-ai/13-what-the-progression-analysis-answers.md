---
title: "Lesson 13: What the progression analysis answers"
description: "Guitar Alchemist's chatbot has no skill that analyzes a chord progression: the draft waits for a tool, but the DSL closure it would need already answers through ga_dsl_eval. The course asks it the draft's four examples and eight textbook progressions in all 30 keys, at the pin and on main. The pin reads only the roots and gives every minor progression another key; main finds every key, but writes no numeral for a minor key's vii°, names six keys by their enharmonic spelling and lets borrowed chords move the key."
sidebar:
  label: 13. What the progression analysis answers
  order: 13
---

[Lesson 12](../12-what-the-progression-skills-answer/) stopped where the chatbot has no skill: analyzing a progression, with its key and its Roman numerals. The draft of that skill calls it "the single most-requested prompt class" of the public chatbot ([`DRAFT.md` line 30](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/progression-analysis/DRAFT.md#L30)) and waits for a `ga_analyze_progression` tool "not yet implemented in Common/GA.Business.ML/Agents/Mcp/" ([line 20](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/progression-analysis/DRAFT.md#L20)); the folder has no such file, at the pin or on `main`. The computation exists already. The DSL closure `domain.analyzeProgression` infers the key of a progression and labels each chord with a Roman numeral. GaMcpServer's `GaAnalyzeProgression` tool calls it ([`GaDslTool.cs` lines 195-197](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GaDslTool.cs#L195-L197)), and so do two of its tools that need a key first, `GaProgressionCompletion` and `GaArpeggioSuggestions` ([`GuitaristProblemTools.cs` lines 271-273](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GuitaristProblemTools.cs#L271-L273) and [434-436](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GuitaristProblemTools.cs#L434-L436)), and GA's command line ([`Program.fs` line 320](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/GaCli/Program.fs#L320)). This lesson asks it what the draft expects of the tool.

All GA links point to commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), the course's pin, unless they name another. On `main`, the closure was rewritten twice after the pin: [#625](https://github.com/GuitarAlchemist/ga/pull/625) takes the key from `KeyIdentificationService`, the service of lesson 11, and [`6baf32e`](https://github.com/GuitarAlchemist/ga/commit/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40) takes each numeral's case from the chord. `DomainClosures.fs` hasn't changed since, up to `main` at [`5c3a52a`](https://github.com/GuitarAlchemist/ga/commit/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26) (2026-09-30). The course fetches it at `6baf32e` and compiles it unchanged in a project of its own, `GaDslMain`, against the pinned DSL and against `main`'s service, which lesson 11 compiled in `GaKeysMain`. `main`'s chord parser differs from the pinned one, but only for symbols this lesson doesn't use: `M` and `Maj7`, `o`, `sus`, `omit` and `no`, and text left after the symbol. The outputs come from:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l13
```

## What the model is shown

The chatbot's DSL tools expose only the closures of the Domain category ([`DslEvalMcpTools.cs` line 70](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Mcp/DslEvalMcpTools.cs#L70)). The program asks `ga_dsl_list_closures` and `ga_dsl_get_closure_schema` what a model would ask them:

```text
== What ga_dsl_list_closures and ga_dsl_get_closure_schema show the model
15 closures listed, among them domain.analyzeProgression (Domain): Infer the key of a progression and label each chord with a Roman numeral.
input  chords: string — space-separated chord symbols
output string (formatted key + Roman numeral analysis)
```

A model can call the closure through `ga_dsl_eval`, as the three skills of [lesson 10](../10-what-the-model-is-told-to-trust/) call theirs. No SKILL.md tells it to. The answer is three lines: the key with a confidence, the symbols, the numerals. GaMcpServer's two tools cut it by line and by space to take the key and the numerals ([`GuitaristProblemTools.cs` lines 276-293](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GuitaristProblemTools.cs#L276-L293)).

## How the pin finds the key

At the pin, the closure scores each of the 24 major and minor keys ([`DomainClosures.fs` lines 268-276](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L268-L276) and [308-316](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L308-L316)):

```fsharp
let private scoreKey rootPc (offsets: int[]) (chordPcs: int list) =
    let diatonic = offsets |> Array.map (fun o -> (rootPc + o) % 12) |> Set.ofArray
    chordPcs |> List.filter diatonic.Contains |> List.length

let private romanFor rootPc (offsets: int[]) (romans: string[]) chordPc =
    offsets
    |> Array.tryFindIndex (fun o -> (rootPc + o) % 12 = chordPc)
    |> Option.map (fun i -> romans.[i])
    |> Option.defaultValue "?"
```

```fsharp
                      // Score every major and minor key.
                      // Tiebreaker: prefer the key whose root matches the first chord.
                      let firstPc = validPcs |> List.tryHead |> Option.defaultValue 0
                      let keyRootPc, scaleName =
                          [ for rpc in 0..11 do
                              yield rpc, "major", scoreKey rpc majorOffsets validPcs
                              yield rpc, "minor", scoreKey rpc minorOffsets validPcs ]
                          |> List.maxBy (fun (rpc, _, s) -> s * 2 + (if rpc = firstPc then 1 else 0))
                          |> fun (rpc, scale, _) -> rpc, scale
```

`scoreKey` counts the chords whose root is in the key's scale: the chord's quality is never read. A key whose tonic is the first chord's root gets one more point, and between equal scores `List.maxBy` keeps the first, and the list gives each root's major key before its minor key. `romanFor` then gives the degree's numeral from the key's table, whatever the chord ([lines 257-260](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L257-L260)): in C major, D and Dm are both `ii`. The key's name comes from its tonic's pitch class, with the flat name for pitch classes 1, 3, 8 and 10, and a natural or F♯ otherwise ([lines 262-266](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L262-L266)), whatever the question wrote.

## The draft's four examples

The draft gives four questions with the answer the tool should return ([`DRAFT.md` lines 51-54](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/progression-analysis/DRAFT.md#L51-L54)):

```text
== The four examples of skills-dev/_pending-tools/progression-analysis/DRAFT.md
"C Am F G": the draft expects C major, I vi IV V
  a826864  Key: C major  (confidence 4/4)
           C      Am     F      G
           I      vi     IV     V
  6baf32e  Key: C major  (confidence 4/4)
           C      Am     F      G
           I      vi     IV     V
"Dm7 G7 Cmaj7": the draft expects C major, ii V I
  a826864  Key: D minor  (confidence 3/3)
           Dm7    G7     Cmaj7
           i      iv     VII
  6baf32e  Key: C major  (confidence 3/3)
           Dm7    G7     Cmaj7
           ii     V      I
"D A Bm G": the draft expects D major, I V vi IV
  a826864  Key: D major  (confidence 4/4)
           D      A      Bm     G
           I      V      vi     IV
  6baf32e  Key: D major  (confidence 4/4)
           D      A      Bm     G
           I      V      vi     IV
"Fm Bbm C7 Fm": the draft expects F minor, i iv V i
  a826864  Key: F major  (confidence 4/4)
           Fm     Bbm    C7     Fm
           I      IV     V      I
  6baf32e  Key: F minor  (confidence 4/4)
           Fm     Bbm    C7     Fm
           i      iv     V      i
```

At the pin, two of the four are right. Dm7 G7 Cmaj7, the jazz ii–V–I, is D minor, `i iv VII`: D, G and C are all in D minor, and D is the first chord. Fm Bbm C7 Fm is F major, `I IV V I`: F, B♭ and C are in F major and in F minor, and the tie goes to the major key. On `main`, the four match the draft. The fourth example passes `assumeKey="F minor"`, an input the closure doesn't have; `main` finds F minor without it.

## Eight textbook progressions in thirty keys

The program writes each progression in the 15 major or the 15 minor keys, spelled as a textbook spells it; the leading tone of vii°7 is the raised seventh degree, C♯ in D minor and F𝄪, written `F##`, in G♯ minor. It compares the key and the numerals with the textbook's, the numerals without their figures: ii7 V7 Imaj7 reads ii V I, and iiø7 V7 i reads iiø V i.

```text
== Eight textbook progressions in the 30 keys

major keys             Cb Gb Db Ab Eb Bb F  C  G  D  A  E  B  F# C#
I IV V I      a826864  e  e  =  =  =  =  =  =  =  =  =  =  =  =  e
I IV V I      6baf32e  e  e  e  =  =  =  =  =  =  =  =  =  =  =  =
IV V I        a826864  x  x  x  x  x  x  x  x  x  x  x  x  x  x  x
IV V I        6baf32e  e  e  e  =  =  =  =  =  =  =  =  =  =  =  =
I vi IV V     a826864  e  e  =  =  =  =  =  =  =  =  =  =  =  =  e
I vi IV V     6baf32e  e  e  e  =  =  =  =  =  =  =  =  =  =  =  =
ii7 V7 Imaj7  a826864  x  x  x  x  x  x  x  x  x  x  x  x  x  x  x
ii7 V7 Imaj7  6baf32e  e  e  e  =  =  =  =  =  =  =  =  =  =  =  =

minor keys             Ab Eb Bb F  C  G  D  A  E  B  F# C# G# D# A#
i iv V i      a826864  x  x  x  x  x  x  x  x  x  x  x  x  x  x  x
i iv V i      6baf32e  =  e  e  =  =  =  =  =  =  =  =  =  e  =  =
i iv v i      a826864  x  x  x  x  x  x  x  x  x  x  x  x  x  x  x
i iv v i      6baf32e  =  e  e  =  =  =  =  =  =  =  =  =  e  =  =
iiø7 V7 i     a826864  x  x  x  x  x  x  x  x  x  x  x  x  x  x  x
iiø7 V7 i     6baf32e  =  e  e  =  =  =  =  =  =  =  =  =  e  =  =
i iv vii°7 i  a826864  x  x  x  x  x  x  x  x  x  x  x  x  x  x  x
i iv vii°7 i  6baf32e  n  n  n  n  n  n  n  n  n  n  n  n  n  n  n

= the textbook key, spelled as the question, and the textbook numerals; e the same key under its
enharmonic name, the textbook numerals; n the key, other numerals; x another key
a826864: 120 questions, = 24, e 6, n 0, x 90; confidence below the chord count: none
6baf32e: 120 questions, = 84, e 21, n 15, x 0; confidence below the chord count: iiø7 V7 i in 15 keys, i iv vii°7 i in 12 keys
```

- **`x`, the pin, 90 of 120.** IV V I gets the key of IV, where the three chords are I ii V, and ii7 V7 Imaj7 the minor key of ii. No minor progression gets its key: i iv V i, i iv v i and i iv vii°7 i get the parallel major, whose scale holds the same roots, and iiø7 V7 i the minor key of ii, which opens it. On `main`, where the key comes from `KeyIdentificationService`, the grid has no `x`.
- **`e`, the key under its enharmonic name.** At the pin, C♭, G♭ and C♯ major come back as B, F♯ and D♭ major, from the pitch-class table; the other rows have `x` there. On `main`, the name is the one `Identify` puts first, and keys with the same pitch classes are ordered by name ([`KeyIdentificationService.cs` lines 224-227](https://github.com/GuitarAlchemist/ga/blob/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40/Common/GA.Domain.Services/Tonal/KeyIdentificationService.cs#L224-L227)): C♭, G♭ and D♭ major become B, F♯ and C♯ major, and E♭, B♭ and G♯ minor become D♯, A♯ and A♭ minor. That's six of the 30 keys, in every row but the last, where the numerals already differ. The cause is the one of [#772](https://github.com/GuitarAlchemist/ga/issues/772), met in lesson 11.
- **`n`, `main`, i iv vii°7 i in the 15 minor keys.** The key is right, the numerals are `i iv ? i`.
- **The confidence.** At the pin, it counts roots and is full in all 120 questions. On `main`, it's below the chord count for iiø7 V7 i in all 15 minor keys and for i iv vii°7 i in 12. The next section shows why.

```text
Bb major, IV V I: "Eb F Bb"
  a826864  Key: Eb major (3/3), I ii V
  6baf32e  Key: Bb major (3/3), IV V I
Gb major, ii7 V7 Imaj7: "Abm7 Db7 Gbmaj7"
  a826864  Key: Ab minor (3/3), i iv VII
  6baf32e  Key: F# major (3/3), ii V I
G# minor, i iv v i: "G#m C#m D#m G#m"
  a826864  Key: Ab major (4/4), I IV V I
  6baf32e  Key: Ab minor (4/4), i iv v i
D minor, i iv vii°7 i: "Dm Gm C#dim7 Dm"
  a826864  Key: D major (4/4), I IV vii° I
  6baf32e  Key: D minor (3/4), i iv ? i
```

## Chords outside the natural scale

On `main`, `romanFor` looks for the chord's root among the seven notes of the key's natural scale, then takes the case and the sign from the chord ([`DomainClosures.fs` lines 353-374 at `6baf32e`](https://github.com/GuitarAlchemist/ga/blob/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L353-L374)):

```fsharp
/// Roman numeral of a chord in a key: the degree comes from the scale, the case and sign from the
/// chord itself, so E7 in A minor is V (harmonic minor), not the natural-minor v.
let private romanFor rootPc (offsets: int[]) (ast: ChordAst) =
    let chordPc = (noteToSemitone ast.Root + accToSemitone ast.RootAccidental + 120) % 12
    // Bm7b5 parses as a minor quality with a flat fifth; the -7b5 spelling as one extension.
    let halfDiminished =
        ast.Components
        |> List.exists (function
            | Extension "m7b5" -> true
            | Alteration (Flat, "5") -> ast.Quality = Some Minor
            | _ -> false)
    offsets
    |> Array.tryFindIndex (fun o -> (rootPc + o) % 12 = chordPc)
    |> Option.map (fun i ->
        let digits = romanDigits.[i]
        match ast.Quality with
        | _ when halfDiminished -> digits.ToLowerInvariant() + "ø"
        | Some Minor -> digits.ToLowerInvariant()
        | Some Diminished -> digits.ToLowerInvariant() + "°"
        | Some Augmented -> digits + "+"
        | _ -> digits)
    |> Option.defaultValue "?"
```

E7 is `V` in A minor because E is the fifth degree of A natural minor. The leading tone, G♯, is on no degree of it, so G♯dim7 gets `?`. In a major key, three of the chords borrowed from the parallel minor, bIII, bVI and bVII, stand a semitone below a degree: E♭ below E, A♭ below A, B♭ below B. The program asks six questions a textbook reads in C major or A minor:

```text
== Chords borrowed from the parallel minor, and the harmonic minor's V and vii°
"C Ab G C": the textbook reads C major, I bVI V I
  a826864  Key: C minor  (confidence 4/4)
           C      Ab     G      C
           i      VI     v      i
  6baf32e  Key: C major  (confidence 3/4)
           C      Ab     G      C
           I      ?      V      I
"C Eb F C": the textbook reads C major, I bIII IV I
  a826864  Key: C minor  (confidence 4/4)
           C      Eb     F      C
           i      III    iv     i
  6baf32e  Key: C major  (confidence 3/4)
           C      Eb     F      C
           I      ?      IV     I
"C Bb F C": the textbook reads C major, I bVII IV I
  a826864  Key: C minor  (confidence 4/4)
           C      Bb     F      C
           i      VII    iv     i
  6baf32e  Key: F major  (confidence 4/4)
           C      Bb     F      C
           V      IV     I      V
"C Ab Bb C": the textbook reads C major, I bVI bVII I
  a826864  Key: C minor  (confidence 4/4)
           C      Ab     Bb     C
           i      VI     VII    i
  6baf32e  Key: Eb major  (confidence 2/4)
           C      Ab     Bb     C
           VI     IV     V      VI
"Am G#dim7 Am": the textbook reads A minor, i vii° i
  a826864  Key: A major  (confidence 3/3)
           Am     G#dim7 Am
           I      vii°   I
  6baf32e  Key: A minor  (confidence 2/3)
           Am     G#dim7 Am
           i      ?      i
"Bm7b5 E7 Am": the textbook reads A minor, iiø V i
  a826864  Key: B minor  (confidence 3/3)
           Bm7b5  E7     Am
           i      iv     VII
  6baf32e  Key: A minor  (confidence 2/3)
           Bm7b5  E7     Am
           iiø    V      i
KeyIdentificationService.Identify on main, "C Bb F C": F major 3/3, D minor 3/3, C major 2/3
KeyIdentificationService.Identify on main, "C Ab Bb C": Eb major 2/3, F major 2/3, C minor 2/3
KeyIdentificationService.IsChordDiatonic("A minor", ...) on main: Am yes, Bdim yes, Bm7b5 no, E yes, E7 yes, G#dim7 no
KeyIdentificationService.IsChordDiatonic("G# minor", ...) on main: G#m yes, D#7 yes, F# yes, F##dim7 yes
```

- **C Ab G C and C Eb F C.** `main` finds C major and writes `?` where a textbook writes bVI and bIII. The pin finds C minor, where A♭ and E♭ are VI and III, and calls the C major chord `i`.
- **C Bb F C and C Ab Bb C.** `main` moves the key. `Identify` sorts by the count of distinct chords diatonic to the key, plus the cadence weight; then it puts first the key whose tonic triad opens the progression, then the major key, then the name ([lines 224-227](https://github.com/GuitarAlchemist/ga/blob/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40/Common/GA.Domain.Services/Tonal/KeyIdentificationService.cs#L224-L227)). C, B♭ and F are all diatonic in F major and in D minor, against two in C major; neither key opens on its tonic triad, and F major is the major one: the analysis is F major, `V IV I V`. In C Ab Bb C, E♭ major, F major and C minor count two chords, C major only C; E♭ major is major and comes before F by name: the analysis is E♭ major, `VI IV V VI`, although E♭ major's sixth degree carries C minor, not C major. The confidence, 2/4, is the only sign of it.
- **The confidence counts what `IsChordDiatonic` accepts** ([`DomainClosures.fs` lines 421-424 at `6baf32e`](https://github.com/GuitarAlchemist/ga/blob/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L421-L424)). It accepts a minor key's major V and V7 ([`KeyIdentificationService.cs` lines 261-267](https://github.com/GuitarAlchemist/ga/blob/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40/Common/GA.Domain.Services/Tonal/KeyIdentificationService.cs#L261-L267)), but `NormalizeChord` cuts a symbol at its first digit ([line 319](https://github.com/GuitarAlchemist/ga/blob/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40/Common/GA.Domain.Services/Tonal/KeyIdentificationService.cs#L319)): Bm7b5 becomes Bm, a minor triad, while A minor's ii is B diminished. The service reads a root with one accidental ([line 132](https://github.com/GuitarAlchemist/ga/blob/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40/Common/GA.Domain.Services/Tonal/KeyIdentificationService.cs#L132)) and calls major any quality it doesn't know ([lines 145-150](https://github.com/GuitarAlchemist/ga/blob/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40/Common/GA.Domain.Services/Tonal/KeyIdentificationService.cs#L145-L150)). `F##dim7` is thus F♯ major, the natural minor's VII in G♯ minor, and counts: i iv vii°7 i is full in G♯, D♯ and A♯ minor, whose leading tone takes a double sharp.

## Where the course stops

- **The model isn't run.** Whether a model calls `domain.analyzeProgression` through `ga_dsl_eval`, and what it writes from the three lines, needs the model (*to verify*).
- **`main`'s closure runs outside `main`.** It's compiled against the pinned DSL and against `main`'s service compiled against the pinned domain, as in lesson 11. That the lesson's symbols parse the same with `main`'s parser comes from reading its diff, not from a run.
- **The draft asks for more.** Functions, cadences, modulations and the chords foreign to the key ([`DRAFT.md` lines 44-47](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/progression-analysis/DRAFT.md#L44-L47)) aren't in the closure's answer.
- **Eight textbook progressions and six borrowed-chord questions**, without inversions, slash chords, secondary dominants or modulations.

## Reported upstream

- Not reported upstream when this lesson was written: the numerals missing for a minor key's vii° and for chords borrowed from the parallel minor, the key moved by borrowed chords, and the confidence that counts a half-diminished ii as foreign. The keys named by their enharmonic spelling on `main` have the same cause as [#772](https://github.com/GuitarAlchemist/ga/issues/772). The pin's key and numerals read from the roots alone were fixed on `main` by [#625](https://github.com/GuitarAlchemist/ga/pull/625) and `6baf32e`. All are listed in the [journal](../journal/).

## Exercises

1. At the pin, Am Dm E Am is A major. Compute the value `List.maxBy` compares for A major and for A minor, and say why A major wins.
2. Extend `main`'s `romanFor` so that, in a major key, a root a semitone below the third, sixth or seventh degree gets a flat and that degree's numeral, and in a minor key the raised seventh degree gets `vii`. What does it write for the six questions of the last section?
3. Suppose `Identify` put first, before the count, the key whose tonic triad both opens and closes the progression. Which rows of the grid would change on `main`, and what would C Bb F C and C Ab Bb C get?
4. The pin names keys by pitch class. Which of the textbook's 15 minor keys does it spell differently?

<details>
<summary>Solutions</summary>

1. The roots are A, D, E and A: all four are in A major's scale and in A minor's, so both score 4. A is the first chord's root, so both get 4 × 2 + 1 = 9. `List.maxBy` keeps the first of equal values, and the list gives A major before A minor. Worked by hand from lines 308-316.
2. C Ab G C: `I bVI V I`. C Eb F C: `I bIII IV I`. Am G#dim7 Am: `i vii° i`. Bm7b5 E7 Am stays `iiø V i`. C Bb F C and C Ab Bb C don't change, `V IV I V` in F major and `VI IV V VI` in E♭ major: the rule labels the chords, but it doesn't choose the key. Worked by hand.
3. None: the rows whose progression opens and closes on the same tonic triad, I IV V I, i iv V i, i iv v i and i iv vii°7 i, already get their key, and the others don't open and close on the same chord. C Bb F C and C Ab Bb C would get C major, `I ? IV I` and `I ? ? I` with `main`'s `romanFor`, `I bVII IV I` and `I bVI bVII I` with exercise 2's. Worked by hand.
4. Four: C♯ minor is written D♭ minor, a key of eight flats, D♯ minor E♭ minor, G♯ minor A♭ minor and A♯ minor B♭ minor. The table gives pitch classes 1, 3, 8 and 10 a flat whatever the mode. Worked by hand from lines 262-266.

</details>

## Key takeaways

- A closure that exists answers before the skill does: the draft waits for a tool while `ga_dsl_eval` already lists and runs the closure.
- A key read from the roots alone can't tell a key from its parallel: the pin gave A major to Am Dm E Am.
- A draft's examples are a ready-made test: two of four fail at the pin, four of four pass on `main`.
- A numeral table indexed by the natural scale has no place for the harmonic minor's leading tone or for borrowed chords.
- Ranking keys by count first lets borrowed chords move the key away from the chord a progression opens and closes on.

## Sources

- GuitarAlchemist/ga at [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs`, `Common/GA.Business.ML/Agents/Mcp/DslEvalMcpTools.cs`, `GaMcpServer/Tools/GaDslTool.cs`, `GaMcpServer/Tools/GuitaristProblemTools.cs`, `Apps/GaCli/Program.fs`, `skills-dev/_pending-tools/progression-analysis/DRAFT.md`.
- GA at [`6baf32e`](https://github.com/GuitarAlchemist/ga/commit/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40), committed on 2026-09-25 UTC: `Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs` and `Common/GA.Domain.Services/Tonal/KeyIdentificationService.cs`, compiled by the course. GA [#625](https://github.com/GuitarAlchemist/ga/pull/625). GA's `main` at [`5c3a52a`](https://github.com/GuitarAlchemist/ga/commit/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26), committed on 2026-09-30 UTC, for the comparison.
- *Open Music Theory*, the chapters on Roman numerals, the minor scale's raised seventh and modal mixture.
