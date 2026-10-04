---
title: "Lesson 26: The modes catalog"
description: "Guitar Alchemist's ModesSkill answers mode questions from Modes.yaml, without a model. 36 of the 129 modes it answers from are not their family's scale from their degree, 8 names are cut at a sharp sign that YAML reads as a comment, 10 modes can't be reached by their own name, and the formula it works out by position is a textbook's for 65 of them."
sidebar:
  label: 26. The modes catalog
  order: 26
---

[Lesson 8](../08-the-chatbots-own-exam/) met `ModesSkill` through one prompt of GA's corpus, and found its formulas numbered by position on two scales, reported as GA issue [#765](https://github.com/GuitarAlchemist/ga/issues/765). The skill says it holds no music theory of its own: "Zero hardcoded music-theory content — the skill is a thin adapter that classifies the query, calls the domain, and formats the result" ([`ModesSkill.cs` lines 8-16](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ModesSkill.cs#L8-L16)). The domain is `Modes.yaml`, read by `ModesConfig`. So this lesson checks the catalog itself, mode by mode, then what the skill makes of it. It needs no model: the skill is deterministic.

All GA links point to commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), the course's pin. On GA's `main` at [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/commit/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) (2026-10-01), `ModesSkill.cs`, `Modes.yaml`, `ModesConfig.fs`, `AtonalModalFamiliesConfig.fs` and `skills/modes/SKILL.md` are the same files, byte for byte, so the program runs at the pin only. The output comes from:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l26
```

## How the skill answers

`ExecuteAsync` tries, in order: the atonal catalog, when the question names an interval class vector, a Forte number or atonal words; a family when the question asks for its modes; a mode whose name the question contains; a family whose name it contains; an overview of all families; and otherwise the major scale's modes ([lines 152-211](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ModesSkill.cs#L152-L211)). A mode's answer says which mode of which family it is, gives its notes on C as the catalog writes them, and adds a formula it works out from those notes:

```csharp
        var degree = family.Modes.ToList().FindIndex(m => m.Name == mode.Name) + 1;
        sb.Append($"**{mode.Name}** is mode {degree} of the **{StripFamilySuffix(family.Name)}** family");
        if (!string.IsNullOrWhiteSpace(mode.Notes))
        {
            sb.Append($"; on C its notes are `{mode.Notes}`");
            var formula = ComputeFormulaFromNotes(mode.Notes);
            if (!string.IsNullOrEmpty(formula))
                sb.Append($" (formula `{formula}`)");
        }
        sb.Append('.');
```

## The catalog against a textbook

"Mode 4 of the major scale" means the major scale played from its fourth degree: on C, the notes of F major from F to F, moved down to C. The program holds a textbook's first mode for each of the 26 families (`Parents` in `Lesson26.cs`), and checks every mode k of a family against its mode 1 played from degree k:

```text
== The families ModesSkill answers from, and whether mode k is the parent scale from its degree k
family                   modes  notes  mode 1     mode k on degree k  the modes that aren't
Major Scale              7      7      textbook   7 of 7              -
Harmonic Minor           7      7      textbook   6 of 7              7
Melodic Minor            7      7      textbook   7 of 7              -
Major Pentatonic         5      5      textbook   2 of 5              3, 4, 5
Whole Tone               1      6      textbook   1 of 1              -
Diminished               2      8      textbook   2 of 2              -
Blues Scale              1      6      textbook   1 of 1              -
Chromatic                1      12     textbook   1 of 1              -
Perfect Fourth           2      2      textbook   2 of 2              -
Major Third              2      2      textbook   2 of 2              -
Minor Third              2      2      textbook   2 of 2              -
Major Second             2      2      textbook   2 of 2              -
Minor Second             2      2      textbook   2 of 2              -
Harmonic Major           7      7      textbook   7 of 7              -
Double Harmonic          7      7      textbook   6 of 7              7
Neapolitan Minor         7      7      textbook   6 of 7              7
Neapolitan Major         7      7      textbook   3 of 7              4, 5, 6, 7
Dominant Bebop           8      8      textbook   5 of 8              6, 7, 8
Major Bebop              8      8      textbook   3 of 8              4, 5, 6, 7, 8
Prometheus               6      6      textbook   3 of 6              4, 5, 6
Enigmatic                7      7      textbook   2 of 7              3, 4, 5, 6, 7
Hungarian Major          7      7      textbook   1 of 7              2, 3, 4, 5, 6, 7
Hirajoshi                5      5      textbook   5 of 5              -
In Sen                   5      5      textbook   1 of 5              2, 3, 4, 5
Diminished (Octatonic)   8      8      textbook   8 of 8              -
Augmented (Hexatonic)    6      6      textbook   6 of 6              -
families 26; Modes.yaml's that the skill leaves out 5: Major Triad Family, Diminished Triad Family, Augmented Triad Family, Major Seventh Chord Family, All Interval Tetrachord Family
modes 129: mode 1 from their own degree 93, from another degree 2, from no degree 34; notes out of order 3
the modes that aren't:
  Harmonic Minor 7, Ultralocrian: C Db Eb Fb Gb Ab Bb; mode 1 from no degree; from degree 7: C Db Eb Fb Gb Ab Bbb
  Major Pentatonic 3, Blues Minor: C Eb F G Bb; mode 1 from degree 5
  Major Pentatonic 4, Blues Major: C E F A Bb; mode 1 from no degree; from degree 4: semitones 0 2 5 7 9
  Major Pentatonic 5, Minor Pentatonic: C D F G A; mode 1 from degree 4
  Double Harmonic 7, Locrian bb3 bb7: C Dbb Ebb F Gb Ab Bbb; mode 1 from no degree; from degree 7: C Db Ebb F Gb Ab Bbb
  Neapolitan Minor 7, Ultralocrian bb3: C Dbb Eb F Gb Ab Bbb; mode 1 from no degree; from degree 7: C Db Ebb Fb Gb Ab Bbb
  Neapolitan Major 4, Lydian Minor (Lydian b3 b7): C D Eb F# G A Bb; mode 1 from no degree; from degree 4: C D E F# G Ab Bb
  Neapolitan Major 5, Major Locrian: C D Eb F Gb Ab Bb; mode 1 from no degree; from degree 5: C D E F Gb Ab Bb
  Neapolitan Major 6, Altered Dominant n2 (Locrian n2 n7): C D Eb F Gb Ab B; mode 1 from no degree; from degree 6: C D Eb Fb Gb Ab Bb
  Neapolitan Major 7, Altered bb3: C Dbb Eb Fb Gb Ab Bb; mode 1 from no degree; from degree 7: C Db Ebb Fb Gb Ab Bb
  Dominant Bebop 6, Dominant Bebop Mode 6: C Db D Eb F G A Bb; mode 1 from no degree; from degree 6: semitones 0 1 2 3 5 7 8 10
  Dominant Bebop 7, Dominant Bebop Mode 7: C C# D E F G A B; mode 1 from no degree; from degree 7: semitones 0 1 2 4 6 7 9 11
  Dominant Bebop 8, Dominant Bebop Mode 8: C C# D# E F# G# A# B; mode 1 from no degree; from degree 8: semitones 0 1 3 5 6 8 10 11
  Major Bebop 4, Major Bebop Mode 4: C D Eb F G Ab A B; mode 1 from no degree; from degree 4: semitones 0 2 3 4 6 7 9 11
  Major Bebop 5, Major Bebop Mode 5: C Db Eb F Gb G Bb B; mode 1 from no degree; from degree 5: semitones 0 1 2 4 5 7 9 10
  Major Bebop 6, Major Bebop Mode 6: C D E F F# A Bb B; mode 1 from no degree; from degree 6: semitones 0 1 3 4 6 8 9 11
  Major Bebop 7, Major Bebop Mode 7: C D Eb E G Ab A Bb; mode 1 from no degree; from degree 7: semitones 0 2 3 5 7 8 10 11
  Major Bebop 8, Major Bebop Mode 8: C Db D F Gb G Ab B; mode 1 from no degree; from degree 8: semitones 0 1 3 5 6 8 9 10
  Prometheus 4, Prometheus Mode 4: C Eb E G A Bb; mode 1 from no degree; from degree 4: semitones 0 3 4 6 8 10
  Prometheus 5, Prometheus Mode 5: C C# E F# G# A; mode 1 from no degree; from degree 5: semitones 0 1 3 5 7 9
  Prometheus 6, Prometheus Mode 6: C D# F G G# B; mode 1 from no degree; from degree 6: semitones 0 2 4 6 8 11
  Enigmatic 3, Enigmatic Mode 3: C D E Gb G Ab Bb; mode 1 from no degree; from degree 3: C D E F# G Ab Bbb
  Enigmatic 4, Enigmatic Mode 4: C D E F Gb Ab B; mode 1 from no degree; from degree 4: C D E F Gb Abb Bb
  Enigmatic 5, Enigmatic Mode 5: C D Eb F G B Bb; mode 1 from no degree; from degree 5: C D Eb Fb Gbb Ab Bb; notes out of order
  Enigmatic 6, Enigmatic Mode 6: C Db Eb F A G# B; mode 1 from no degree; from degree 6: C Db Ebb Fbb Gb Ab Bb; notes out of order
  Enigmatic 7, Enigmatic Mode 7: C D E G# F# A# B; mode 1 from no degree; from degree 7: C Db Ebb F G A B; notes out of order
  Hungarian Major 2, Hungarian Major Mode 2: C Db Eb F Gb Ab A; mode 1 from no degree; from degree 2: C Db Eb Fb Gb Abb Bbb
  Hungarian Major 3, Hungarian Major Mode 3: C D E F G G# B; mode 1 from no degree; from degree 3: C D Eb F Gb Ab B
  Hungarian Major 4, Hungarian Major Mode 4: C D Eb F F# A Bb; mode 1 from no degree; from degree 4: C Db Eb Fb Gb A Bb
  Hungarian Major 5, Hungarian Major Mode 5: C Db Eb E G Ab Bb; mode 1 from no degree; from degree 5: C D Eb F G# A B
  Hungarian Major 6, Hungarian Major Mode 6: C D D# F# G A B; mode 1 from no degree; from degree 6: C Db Eb F# G A Bb
  Hungarian Major 7, Hungarian Major Mode 7: C C# E F G A Bb; mode 1 from no degree; from degree 7: C D E# F# G# A B
  In Sen 2, In Sen Mode 2: C E F Ab Bb; mode 1 from no degree; from degree 2: semitones 0 4 6 9 11
  In Sen 3, In Sen Mode 3: C Db F G A; mode 1 from no degree; from degree 3: semitones 0 2 5 7 8
  In Sen 4, In Sen Mode 4: C E F G B; mode 1 from no degree; from degree 4: semitones 0 3 5 6 10
  In Sen 5, In Sen Mode 5: C Db Eb G Ab; mode 1 from no degree; from degree 5: semitones 0 2 3 7 9
```

- **Mode 1 is the textbook's scale in all 26 families, but 36 of the other modes aren't mode 1 from their degree.** Two are mode 1 from another degree: the major pentatonic's "Blues Minor" (mode 3) is the scale from degree 5, and its "Minor Pentatonic" (mode 5) from degree 4. The other 34 are mode 1 from no degree at all: their notes are a different scale. They are 4 of the Neapolitan major's 7 modes, 8 of the two bebop scales' 16, 3 of the Prometheus scale's 6, 5 of the enigmatic scale's 7, 6 of the Hungarian major's 7, 4 of the In Sen's 5, the major pentatonic's "Blues Major", and the seventh mode of the harmonic minor, double harmonic and Neapolitan minor.
- **Ultralocrian has the notes of the altered scale.** The seventh mode of harmonic minor has a double-flat seventh, Bbb on C; the catalog writes Bb ([`Modes.yaml` lines 242-243](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Config/Modes.yaml#L242-L243)), which are the altered scale's notes, mode 7 of melodic minor.
- **Three seventh modes have no second degree.** "Locrian bb3 bb7", "Ultralocrian bb3" and "Altered bb3" begin `C Dbb`: Dbb is C again, and the Db these modes start with after C is missing. The Neapolitan minor shows it, with three other things this lesson comes back to:

```yaml
  - Name: Neapolitan Minor Family
    Modes:
      - Name: Neapolitan Minor
        Notes: C Db Eb F G Ab B
      - Name: Lydian #6
        Notes: C D E F# G A# B
      - Name: Mixolydian Augmented
        Notes: C D E F G# A Bb
      - Name: Aeolian #4 (Lydian Diminished)
        Notes: C D Eb F# G Ab Bb
      - Name: Locrian n3
        Notes: C Db E F Gb Ab Bb
      - Name: Ionian #2
        Notes: C D# E F G A B
      - Name: Ultralocrian bb3
        Notes: C Dbb Eb F Gb Ab Bbb
```

- **The skill answers from 26 of the catalog's 31 families.** It drops the families whose name contains "Chord Family" or "Triad Family", to keep chords out of mode answers:

```csharp
    private static bool IsChordOrTriadFamilyName(string name) =>
        name.Contains("Chord Family", StringComparison.OrdinalIgnoreCase) ||
        name.Contains("Triad Family", StringComparison.OrdinalIgnoreCase);
```

  Its comment counts four such families ([lines 515-516](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ModesSkill.cs#L515-L516)); the fifth is "All Interval Tetrachord Family", whose name contains "chord Family", and the comparison ignores case.

## The formulas

A textbook writes a seven-note scale's formula with each degree once: its notes, in ascending order, are 1 to 7, and Lydian is `1 2 3 #4 5 6 7`. For any other number of notes, each number comes from the note's letter: the major pentatonic, C D E G A, is `1 2 3 5 6`. The skill compares the i-th note with the i-th degree of C major, counting past seven from 1 again, and drops an accidental it can't write with two sharps or flats:

```csharp
        for (var i = 0; i < tokens.Length; i++)
        {
            if (!PitchSemitone.TryGetValue(tokens[i], out var semi))
                return string.Empty;  // unknown token — bail rather than guess
            // For scales of <=7 notes, position maps directly to degree slot.
            // For 8-note (Bebop) or longer scales, modulo 7 keeps the reference
            // sensible — the formula notation is still recognizable.
            var slot = i % 7;
            var expected = DegreeSemitones[slot];
            var diff = semi - expected;
            // Normalize across octave boundary for late notes in 8+-note scales.
            if (diff > 6) diff -= 12;
            if (diff < -6) diff += 12;
            var acc = diff switch
            {
                -2 => "bb",
                -1 => "b",
                  0 => "",
                  1 => "#",
                  2 => "##",
                  _ => string.Empty  // out of expected range — omit accidental rather than emit garbage
            };
            parts.Add($"{acc}{i + 1}");
        }
```

```text
== Each mode's formula: the one ModesSkill computes from the notes by position, and a textbook's
notes  modes  the skill's   the letters'    the first of the skill's that differs: notes, the skill's formula, a textbook's
2      10     2 right       -               Perfect Fourth: C F; `1 2`, `1 4`
5      15     0 right       -               Major Pentatonic: C D E G A; `1 2 3 ##4 ##5`, `1 2 3 5 6`
6      14     3 right       -               Whole Tone: C D E F# G# Bb; `1 2 3 #4 #5 #6`, `1 2 3 #4 #5 b7`
7      63     60 right      52 right        Enigmatic Mode 5: C D Eb F G B Bb; `1 2 b3 4 5 ##6 b7`, `1 2 b3 4 5 #6 7`
8      26     0 right       -               Diminished (Half-Whole): C Db Eb E F# G A Bb; `1 b2 b3 b4 b5 bb6 bb7 bb8`, `1 b2 b3 3 #4 5 6 b7`
12     1      0 right       -               Chromatic: C C# D D# E F F# G G# A A# B; `1 b2 bb3 bb4 5 6 7 8 9 10 11 12`, `1 #1 2 #2 3 4 #4 5 #5 6 #6 7`
modes 129: the skill's formula is a textbook's 65; of the 63 seven-note modes, a formula read from the letters would be 52
the seven-note modes whose letters give another formula than their degrees:
  Enigmatic Mode 2: C D# F G A Bb B; letters `1 #2 4 5 6 b7 7`, degrees `1 #2 #3 ##4 ##5 #6 7`
  Enigmatic Mode 3: C D E Gb G Ab Bb; letters `1 2 3 b5 5 b6 b7`, degrees `1 2 3 #4 5 b6 b7`
  Enigmatic Mode 5: C D Eb F G B Bb; letters `1 2 b3 4 5 7 b7`, degrees `1 2 b3 4 5 #6 7`
  Enigmatic Mode 6: C Db Eb F A G# B; letters `1 b2 b3 4 6 #5 7`, degrees `1 b2 b3 4 #5 6 7`
  Enigmatic Mode 7: C D E G# F# A# B; letters `1 2 3 #5 #4 #6 7`, degrees `1 2 3 #4 #5 #6 7`
  Hungarian Major Mode 2: C Db Eb F Gb Ab A; letters `1 b2 b3 4 b5 b6 6`, degrees `1 b2 b3 4 b5 b6 bb7`
  Hungarian Major Mode 3: C D E F G G# B; letters `1 2 3 4 5 #5 7`, degrees `1 2 3 4 5 b6 7`
  Hungarian Major Mode 4: C D Eb F F# A Bb; letters `1 2 b3 4 #4 6 b7`, degrees `1 2 b3 4 b5 6 b7`
  Hungarian Major Mode 5: C Db Eb E G Ab Bb; letters `1 b2 b3 3 5 b6 b7`, degrees `1 b2 b3 b4 5 b6 b7`
  Hungarian Major Mode 6: C D D# F# G A B; letters `1 2 #2 #4 5 6 7`, degrees `1 2 b3 #4 5 6 7`
  Hungarian Major Mode 7: C C# E F G A Bb; letters `1 #1 3 4 5 6 b7`, degrees `1 b2 3 4 5 6 b7`
the seven-note modes whose formulas differ:
  Enigmatic Mode 5: C D Eb F G B Bb; `1 2 b3 4 5 ##6 b7`, `1 2 b3 4 5 #6 7`
  Enigmatic Mode 6: C Db Eb F A G# B; `1 b2 b3 4 ##5 b6 7`, `1 b2 b3 4 #5 6 7`
  Enigmatic Mode 7: C D E G# F# A# B; `1 2 3 4 b5 #6 7`, `1 2 3 #4 #5 #6 7`
the other differences, one per family:
  Major Pentatonic: C D E G A; `1 2 3 ##4 ##5`, `1 2 3 5 6`
  Whole Tone: C D E F# G# Bb; `1 2 3 #4 #5 #6`, `1 2 3 #4 #5 b7`
  Diminished (Half-Whole): C Db Eb E F# G A Bb; `1 b2 b3 b4 b5 bb6 bb7 bb8`, `1 b2 b3 3 #4 5 6 b7`
  Blues Scale: C Eb F F# G Bb; `1 #2 #3 #4 5 #6`, `1 b3 4 #4 5 b7`
  Chromatic: C C# D D# E F F# G G# A A# B; `1 b2 bb3 bb4 5 6 7 8 9 10 11 12`, `1 #1 2 #2 3 4 #4 5 #5 6 #6 7`
  Perfect Fourth: C F; `1 2`, `1 4`
  Major Third: C E; `1 ##2`, `1 3`
  Minor Third: C Eb; `1 #2`, `1 b3`
  Minor Seventh: C Bb; `1 2`, `1 b7`
  Major Seventh: C B; `1 2`, `1 7`
  Dominant Bebop: C D E F G A Bb B; `1 2 3 4 5 6 b7 b8`, `1 2 3 4 5 6 b7 7`
  Major Bebop: C D E F G G# A B; `1 2 3 4 5 b6 bb7 b8`, `1 2 3 4 5 #5 6 7`
  Prometheus: C D E F# A Bb; `1 2 3 #4 ##5 #6`, `1 2 3 #4 6 b7`
  Hirajoshi: C D Eb G Ab; `1 2 b3 ##4 #5`, `1 2 b3 5 b6`
  In Sen: C Db F G Bb; `1 b2 #3 ##4 5`, `1 b2 4 5 b7`
  Whole-Half Diminished: C D Eb F Gb Ab A B; `1 2 b3 4 b5 b6 bb7 b8`, `1 2 b3 4 b5 b6 6 7`
  Augmented Scale: C Eb E G Ab B; `1 #2 3 ##4 #5 ##6`, `1 b3 3 5 b6 7`
```

- **The formulas are right for 60 of the 63 seven-note modes, and for 5 of the other 66.** The three seven-note ones are enigmatic modes whose notes aren't in ascending order in the catalog.
- **Every five-note and every eight-note scale gets a wrong formula.** The major pentatonic is `1 2 3 ##4 ##5`: G is written as a doubly sharp fourth. The eight-note scales end on an eighth degree: `b8` for the dominant bebop's major seventh, `bb8` for the half-whole diminished scale's minor seventh.
- **A two-note scale can get the wrong note.** The catalog has five families of two-note "modes". For C F, the skill expects D in second place; F is three semitones above it, so the accidental is dropped and the formula is `1 2`, which names D. The minor and major sevenths, C Bb and C B, are `1 2` too.
- **The whole-tone difference is only spelling.** `#6` and `b7` are the same note; the catalog writes it Bb.
- **Reading every number from the letter, as issue #765 suggests, isn't enough either.** For 52 of the 63 seven-note modes it gives the same formula as their degrees. For the 11 others, as the catalog spells them, it doesn't give each degree once in ascending order: most get a degree twice and lose another, as enigmatic mode 2, `C D# F G A Bb B`, would be `1 #2 4 5 6 b7 7`, and enigmatic modes 6 and 7 keep the catalog's notes out of order. A textbook's rule needs both: degrees for seven notes, letters otherwise.

## A few answers

```text
== A few of ModesSkill's answers, first line
What is Ultralocrian?
  | **Ultralocrian** is mode 7 of the **Harmonic Minor** family; on C its notes are `C Db Eb Fb Gb Ab Bb` (formula `1 b2 b3 b4 b5 b6 b7`).
What is Altered?
  | **Altered** is mode 7 of the **Melodic Minor** family; on C its notes are `C Db Eb Fb Gb Ab Bb` (formula `1 b2 b3 b4 b5 b6 b7`).
What is Major Locrian?
  | **Major Locrian** is mode 5 of the **Neapolitan Major** family; on C its notes are `C D Eb F Gb Ab Bb` (formula `1 2 b3 4 b5 b6 b7`).
What is Major Pentatonic?
  | **Major Pentatonic** is mode 1 of the **Major Pentatonic** family; on C its notes are `C D E G A` (formula `1 2 3 ##4 ##5`).
What is Dominant Bebop?
  | **Dominant Bebop** is mode 1 of the **Dominant Bebop** family; on C its notes are `C D E F G A Bb B` (formula `1 2 3 4 5 6 b7 b8`).
What is Perfect Fourth?
  | **Perfect Fourth** is mode 1 of the **Perfect Fourth** family; on C its notes are `C F` (formula `1 2`).
```

- **Ultralocrian and Altered get the same notes and the same formula.** Major Locrian gets Locrian #2's notes, C D Eb F Gb Ab Bb; a textbook's major Locrian is C D E F Gb Ab Bb.
- **The perfect fourth is a mode of two notes, with a formula that names D.**

## The names

YAML ends a value at a space followed by `#`: what follows is a comment, unless the value is quoted. The program reads `Modes.yaml`'s mode names as written and compares them with the names `ModesConfig` reads:

```text
== The mode names Modes.yaml writes, and the names ModesConfig reads: the ones that differ
written                            read
Lydian Augmented #2                Lydian Augmented
Lydian #2 #6                       Lydian
Ionian Augmented #2                Ionian Augmented
Lydian #6                          Lydian
Aeolian #4 (Lydian Diminished)     Aeolian
Ionian #2                          Ionian
Lydian Augmented #6                Lydian Augmented
Lydian Dominant #5                 Lydian Dominant
mode names written 165, read 165, read otherwise than written 8
```

- **Eight names lose everything from their first sharp sign.** "Lydian #6" becomes "Lydian", "Aeolian #4 (Lydian Diminished)" becomes "Aeolian", and "Lydian Dominant #5" becomes "Lydian Dominant". The harmonic minor's names are quoted, `'Locrian #6'` ([`Modes.yaml` line 209](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Config/Modes.yaml#L209)); the double harmonic's, Neapolitan minor's, Neapolitan major's and harmonic major's aren't (lines 631 to 681).

Then the program asks the skill `What is <name>?` for every mode's name and alternate name:

```text
== "What is <name>?" for each mode's name and alternate names: the modes ModesSkill answers with another
asked                            the mode named                                    answered
What is Minor Pentatonic?        Minor Pentatonic (Major Pentatonic 5)             Blues Minor (Major Pentatonic 3)
What is Lydian Augmented?        Lydian Augmented (Harmonic Major 6)               Lydian Augmented (Melodic Minor 3)
What is Lydian?                  Lydian (Double Harmonic 2)                        Lydian (Major Scale 4)
What is Ionian Augmented?        Ionian Augmented (Double Harmonic 6)              Ionian #5 (Harmonic Minor 3)
What is Lydian?                  Lydian (Neapolitan Minor 2)                       Lydian (Major Scale 4)
What is Aeolian?                 Aeolian (Neapolitan Minor 4)                      Aeolian (Major Scale 6)
What is Ionian?                  Ionian (Neapolitan Minor 6)                       Ionian (Major Scale 1)
What is Lydian Augmented?        Lydian Augmented (Neapolitan Major 2)             Lydian Augmented (Melodic Minor 3)
What is Lydian Dominant?         Lydian Dominant (Neapolitan Major 3)              Lydian Dominant (Melodic Minor 4)
What is Whole-Half Diminished?   Whole-Half Diminished (Diminished (Octatonic) 1)  Diminished (Whole-Half) (Diminished 2)
mode names 129: answered with their mode 119, with another 10, CanHandle accepts 129; alternate names 68: answered with their mode 68, with another 0, CanHandle accepts 7
```

- **10 of the 129 modes can't be reached by their own name.** Eight are the cut names: they now repeat a name from the major scale, melodic minor or harmonic minor family, whose mode answers. The other two names really are twice in the catalog: "Minor Pentatonic" is the name of the major pentatonic's mode 5 and an alternate name of its mode 3, and "Whole-Half Diminished" names the octatonic family's mode 1 and is an alternate name of the diminished family's mode 2.
- **The first match in the catalog wins.** The skill sorts every name and alternate name by length, longest first, and keeps the catalog's order between names of the same length; the first one the question contains is the answer:

```csharp
        var aliasedModes = families
            .SelectMany(f => f.Modes
                .SelectMany(m => GetAllAliasesForMode(m).Select(a => (Alias: a, Family: f, Mode: m))))
            .OrderByDescending(t => t.Alias.Length)
            .ToList();

        foreach (var (alias, family, mode) in aliasedModes)
        {
            if (string.IsNullOrWhiteSpace(alias)) continue;
            if (lowerQuery.Contains(alias))
                return (family, mode);
        }
```

- **`CanHandle` accepts every mode name but 7 of the 68 alternate names.** It compares the rest of the question with the modes' and families' names, not their alternate names ([lines 137-144](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ModesSkill.cs#L137-L144)): among the example prompts below, "Tell me about Hijaz" is declined. At the pin the orchestrator doesn't call `CanHandle`; on `main`, it is what the intent router asks when it can't embed a question ([lesson 25](../25-what-reaches-the-transpose-skill/), [`SemanticIntentRouter.cs` lines 313-335](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Agents/Intents/SemanticIntentRouter.cs#L313-L335)). Which skill answers first there depends on the registration order, which this lesson doesn't run.

## The example prompts

```text
== ModesSkill's example prompts: what the first line of the answer is about
prompt                                       CanHandle  answer
What are the modes of the major scale        no         the Major Scale family
List the diatonic modes                      no         the Major Scale family
What are other famous modes                  no         The catalog has **26 mode families** total — these are the named scal…
What are the modes of melodic minor          no         the Melodic Minor family
Modes of harmonic minor                      no         the Harmonic Minor family
What is Lydian dominant                      yes        Lydian Dominant (Melodic Minor 4)
What is Phrygian dominant                    yes        Phrygian Dominant (Harmonic Minor 5)
What is the altered scale                    no         Altered (Melodic Minor 7)
Tell me about Hungarian minor                yes        Hungarian Minor (Double Harmonic 4)
What is the whole tone scale                 no         Whole Tone (Whole Tone 1)
What is the diminished scale                 no         Diminished (Half-Whole) (Diminished 1)
What modes are non-diatonic                  no         The catalog has **26 mode families** total — these are the named scal…
Show me all the mode families                no         The catalog has **26 mode families** total — these are the named scal…
What is Hirajoshi                            yes        Hirajoshi (Hirajoshi 1)
What is Dorian                               yes        Dorian (Major Scale 2)
What is Phrygian                             yes        Phrygian (Major Scale 3)
What is Lydian                               yes        Lydian (Major Scale 4)
What is Mixolydian                           yes        Mixolydian (Major Scale 5)
What is Aeolian                              yes        Aeolian (Major Scale 6)
What is Ionian                               yes        Ionian (Major Scale 1)
What is Locrian                              yes        Locrian (Major Scale 7)
Tell me about Hijaz                          no         Phrygian Dominant (Harmonic Minor 5)
What is Maqam Hijaz                          no         Phrygian Dominant (Harmonic Minor 5)
What is Freygish                             no         Phrygian Dominant (Harmonic Minor 5)
What is Bhairavi                             no         Phrygian (Major Scale 3)
What is the Byzantine scale                  no         Double Harmonic (Byzantine) (Double Harmonic 1)
What is the Spanish Gypsy scale              no         Phrygian Dominant (Harmonic Minor 5)
What is Ahava Rabbah                         no         Phrygian Dominant (Harmonic Minor 5)
What modes have a major 7th                  no         the Major Scale family
Mixolydian versus Ionian differences         no         Mixolydian (Major Scale 5)
Characteristics of Locrian                   no         Locrian (Major Scale 7)
What families have ICV <2 5 4 3 6 1>         no         **Major Scale Family** — ICV `<2 5 4 3 6 1>`, 7-note set, 7 distinct …
What is Forte number 7-29                    no         Forte number **7-29** matches 1 family:
List symmetric families                      no         **6 symmetric / modes-of-limited-transposition families** in the aton…
List atonal modal families                   no         The **atonal modal-families catalog** has **200 families** indexed by…
List unnamed modal families                  no         the Major Scale family
What are modes of limited transposition      no         **6 symmetric / modes-of-limited-transposition families** in the aton…
example prompts 37: CanHandle accepts 11
```

- **"List unnamed modal families" gets the major scale's modes.** The atonal path looks for "unnamed famil" ([line 606](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ModesSkill.cs#L606)), and the prompt says "unnamed modal families"; it falls through to the default answer ([lines 202-207](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ModesSkill.cs#L202-L207)), the one lesson 8's "melodi minor" got.
- **"What modes have a major 7th" gets the major scale's modes too, and "Mixolydian versus Ionian differences" gets Mixolydian alone:** the longest name in the question wins, and the skill has no comparison.
- **`CanHandle` accepts 11 of the 37.**

## Where the course stops

- **The textbook is the course's.** `Parents` in `Lesson26.cs` holds each family's first mode as the usual references give it; the modes' names aren't checked against a textbook, only their notes against their own family's first mode.
- **Spelling is the catalog's.** The formulas are compared with a textbook's rule applied to the catalog's own notes, and a sharp and a flat that name the same note are told apart only where the rule needs it.
- **The atonal catalog and the routing aren't checked.** The 200 atonal families are not compared with a set-class table, and no router is run: the lesson calls the skill directly.

## Reported upstream

- Reported after this lesson was written, in GA issue [#813](https://github.com/GuitarAlchemist/ga/issues/813): the modes that aren't their family's scale from their degree, the names YAML cuts at " #" and the modes they leave unreachable, the alternate names `CanHandle` ignores, the "Chord Family" filter, and the example prompts that get the default answer. The formula counts were added to [#765](https://github.com/GuitarAlchemist/ga/issues/765) in [a comment](https://github.com/GuitarAlchemist/ga/issues/765#issuecomment-5982283789).

## Exercises

1. On which degree of C D E G A does the catalog's "Minor Pentatonic", C D F G A, start? Which of the family's modes carries the minor pentatonic's notes?
2. Why does the skill write `1 2` for the perfect fourth, C F?
3. `Modes.yaml` names the Neapolitan major's third mode "Lydian Dominant #5". Why does "What is Lydian Dominant?" get the melodic minor's mode, and what would it take for "What is Lydian Dominant #5?" to get the Neapolitan major's?
4. Why does "List unnamed modal families" get the major scale's modes, when "List symmetric families" gets the atonal catalog?

<details>
<summary>Solutions</summary>

1. On degree 4, G: G A C D E, moved to C, is C D F G A. The minor pentatonic starts on degree 5, A: C Eb F G Bb, the notes of the catalog's mode 3, "Blues Minor", whose alternate name is "Minor Pentatonic".
2. F is the second note, so the skill compares it with D, the second degree of C major. F is three semitones above D, outside the two sharps the `switch` can write, so the accidental is dropped (line 806) and the number stays 2.
3. The name is unquoted, so YAML reads "Lydian Dominant": the melodic minor's mode 4 has the same name, comes first in the catalog, and wins the tie. Quoted, `'Lydian Dominant #5'`, as lines 209 to 280 quote theirs, the name keeps its sharp sign; it is then longer than "lydian dominant", so the skill tries it first, and "What is Lydian Dominant #5?" contains it. Worked from the code: the program doesn't ask for the names as written.
4. "List symmetric families" contains "symmetric famil", one of the atonal path's phrases (line 597). "List unnamed modal families" contains none: the phrase it would need is "unnamed famil" (line 606), and the word "modal" sits in between. It then names no family or mode the skill knows, so it gets the default answer, the major scale's modes (lines 202-207).

</details>

## Key takeaways

- A skill with no music theory of its own is as right as its catalog: check the catalog, mode by mode.
- "Mode k" is a claim a program can check: the family's first mode, played from degree k.
- A formula numbered by position is right for a seven-note scale in ascending order, and for other sizes only where the notes take the letters in order, as few do.
- In YAML, quote any value that holds a space followed by `#`.
- A lookup that keeps the first match needs names that occur once.

## Sources

- GuitarAlchemist/ga at [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `Common/GA.Business.ML/Agents/Skills/ModesSkill.cs`, `Common/GA.Business.Config/Modes.yaml`, `Common/GA.Business.Config/ModesConfig.fs`.
- GuitarAlchemist/ga at [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/tree/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a): `SemanticIntentRouter.cs` with its keyword fallback.
- The course's program: `code/ga-ai/GaAi/Lesson26.cs`.
