---
title: "Lesson 27: Notes that sound outside"
description: "Guitar Alchemist's OutsideNotesSkill tells a guitarist whether a note over a chord is a chord tone, an available tension or an avoid note, without a model. Against a textbook's chord scales, it calls 4 notes no usual scale holds safe to sustain and makes the b9 of a dominant chord an avoid note; it counts the 11 as a chord tone of 13th chords, reads 27 of 40 spellings of chords it knows and no ♯ or ♭, and spells C7 with an A#."
sidebar:
  label: 27. Notes that sound outside
  order: 27
---

GA's chatbot answers "why does F sound outside over Cmaj7?" with `OutsideNotesSkill`, built to close the BACKLOG item "Why does this sound outside?". It classifies one note against one chord as a chord tone, an available tension or an avoid note, without a model, and says its rule is "the standard jazz-pedagogy definition and is derived **purely from the chord tones**" ([`OutsideNotesSkill.cs` lines 12-35](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/OutsideNotesSkill.cs#L12-L35)). This lesson checks that rule against the chord scales a textbook gives five seventh chords, then the chords the skill applies it to, and how it reads the note and the chord out of the question.

All GA links point to commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), the course's pin. On GA's `main` at [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/commit/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) (2026-10-01), `OutsideNotesSkill.cs` only marks its refusal `Declined`, and `ChordVocabulary.cs` is the same file, so the program runs at the pin only. The output comes from:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l27
```

## How the skill answers

The skill finds a chord after "over", "against" or "on", takes the last note-shaped word before it, and works out the interval from the chord's root. A note in the chord's formula is a chord tone; a note a semitone above a chord tone is an avoid note; any other note is an available tension:

```csharp
        var formula = ChordVocabulary.GetFormula(quality);
        var chordPcs = formula.Intervals.Select(i => ((i % 12) + 12) % 12).ToHashSet();
        var rel = ((notePc - rootPc) % 12 + 12) % 12;

        if (chordPcs.Contains(rel))
        {
            var function = ChordToneFunction(formula, rel);
            return new Verdict(
                RelationKind.ChordTone,
                function,
                $"a chord tone — the {function}",
                $"It's part of the chord itself (the {function}), so it sounds fully consonant — " +
                "as inside as a note can be over this chord.");
        }

        var degree = ExtensionLabel(rel);
        // Avoid note = a semitone above a chord tone (forms a b9 clash with it).
        var clashPc = chordPcs.FirstOrDefault(ct => (ct + 1) % 12 == rel, -1);
```

On a dominant chord, an avoid note gets other advice: "exactly the kind of altered tension players reach for", "not a note to simply avoid" ([lines 164-174](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/OutsideNotesSkill.cs#L164-L174)).

## The rule against a textbook

A textbook doesn't classify a note against the chord alone, but against the scales played over it: Ionian or Lydian over a major seventh chord, Dorian, Aeolian or Phrygian over a minor seventh, seven scales over a dominant seventh, Locrian or Locrian #2 over a half-diminished chord, and the whole-half diminished scale over a diminished seventh (`Usual` in `Lesson27.cs`). A note none of them holds isn't a tension of the chord. A note a semitone above a chord tone is an avoid note, except the b9 and b13 of a dominant chord, its altered tensions. The program classifies the twelve notes over each chord both ways:

```text
== The rule against a textbook: c chord tone, t available tension, a avoid note, o in none of the chord's usual scales
chord                        1    b9   9    #9   3    11   #11  5    b13  13   b7   7
Cmaj7              skill     c    a    t    t    c    a    t    c    a    t    t    c
                   textbook  c    o    t    o    c    a    t    c    o    t    o    c
Cm7                skill     c    a    t    c    a    t    t    c    a    t    c    a
                   textbook  c    a    t    c    o    t    o    c    a    t    c    o
C7                 skill     c    a    t    t    c    a    t    c    a    t    c    a
                   textbook  c    t    t    t    c    a    t    c    t    t    c    o
Cm7b5              skill     c    a    t    c    a    t    c    a    t    t    c    a
                   textbook  c    a    t    c    o    t    c    o    t    o    c    o
Cdim7              skill     c    a    t    c    a    t    c    a    t    c    a    t
                   textbook  c    o    t    c    o    t    c    o    t    c    o    t
cells 60: the same 42; avoid notes no usual scale holds 12; tensions no usual scale holds 4: #9 over Cmaj7, b7 over Cmaj7, #11 over Cm7, 13 over Cm7b5; avoid notes the textbook makes tensions 2: b9 over C7, b13 over C7
```

- **The two agree on 42 of the 60 notes, and on 12 more in effect.** The skill calls those 12 notes, which no usual scale holds, avoid notes: either way, don't sustain them.
- **Four notes no usual scale holds are "an available tension", "Safe to sustain as an extension".** They are #9 and b7 over Cmaj7, #11 over Cm7 and 13 over Cm7b5. Each sits a semitone below a chord tone, where the rule doesn't look. That alone doesn't make a note unusable: #11 over Cmaj7 sits a semitone below the fifth, and Lydian holds it. What the four have in common is that no usual chord scale holds them.
- **The skill makes the b9 and b13 of C7 avoid notes.** For the b9, the answer below says so in its headline, and the opposite in its explanation.

## A few answers

```text
== A few of OutsideNotesSkill's answers
why does Db sound outside over C7
  | **Db** over **C dominant 7**: an avoid note — the b9 (flat ninth).
  | It's the b9 (flat ninth), sitting a semitone above the root of the chord. That half-step rub is why it sounds outside — but over a dominant chord it's exactly the kind of altered tension players reach for (b9 (flat ninth) on the V), so it's usable if you resolve it, not a note to simply avoid.
why does D# sound outside over Cmaj7
  | **D#** over **C major 7**: an available tension — the #9 (sharp ninth).
  | It's the #9 (sharp ninth) — a non-chord tone, but it isn't a semitone above any chord tone, so it adds colour without clashing. Safe to sustain as an extension.
why does Bb sound outside over Cmaj7
  | **Bb** over **C major 7**: an available tension — the b7 (minor seventh).
  | It's the b7 (minor seventh) — a non-chord tone, but it isn't a semitone above any chord tone, so it adds colour without clashing. Safe to sustain as an extension.
why does A sound outside over Cm7b5
  | **A** over **C half-diminished**: an available tension — the 13 (thirteenth).
  | It's the 13 (thirteenth) — a non-chord tone, but it isn't a semitone above any chord tone, so it adds colour without clashing. Safe to sustain as an extension.
```

- **Db over C7 is "an avoid note — the b9", then "not a note to simply avoid".**
- **D# and Bb over Cmaj7, and A over Cm7b5, are "Safe to sustain as an extension".**

## The eleventh in extended chords

```text
== F over C and its extended chords: the first line of the answer, and the chord's notes
chord    answer                                                                        notes
C        **F** over **C**: an avoid note — the 11 (natural eleventh).                  C, E, G
Cmaj7    **F** over **C major 7**: an avoid note — the 11 (natural eleventh).          C, E, G, B
Cmaj9    **F** over **C major 9**: an avoid note — the 11 (natural eleventh).          C, E, G, B, D
Cmaj11   **F** over **C major 11**: a chord tone — the perfect eleventh.               C, E, G, B, D, F
Cmaj13   **F** over **C major 13**: a chord tone — the perfect eleventh.               C, E, G, B, D, F, A
C7       **F** over **C dominant 7**: an avoid note — the 11 (natural eleventh).       C, E, G, A#
C9       **F** over **C dominant 9**: an avoid note — the 11 (natural eleventh).       C, E, G, A#, D
C11      **F** over **C dominant 11**: a chord tone — the perfect eleventh.            C, E, G, A#, D, F
C13      **F** over **C dominant 13**: a chord tone — the perfect eleventh.            C, E, G, A#, D, F, A
Cm7      **F** over **C minor 7**: an available tension — the 11 (natural eleventh).   C, Eb, G, Bb
Cm11     **F** over **C minor 11**: a chord tone — the perfect eleventh.               C, Eb, G, Bb, D, F
```

- **F is an avoid note over C, Cmaj7, Cmaj9, C7 and C9, a semitone above E.** Over Cmaj11, Cmaj13, C11 and C13 it is "a chord tone — the perfect eleventh", though E is still in the chord. `ChordVocabulary` builds 11th and 13th chords by stacking thirds up to the eleventh:

```csharp
        "dominant 11" => new("dominant 11", [0, 4, 7, 10, 14, 17], [0, 2, 4, 6, 8, 10], ["root", "major third", "perfect fifth", "minor seventh", "major ninth", "perfect eleventh"]),
        "major 11" => new("major 11", [0, 4, 7, 11, 14, 17], [0, 2, 4, 6, 8, 10], ["root", "major third", "perfect fifth", "major seventh", "major ninth", "perfect eleventh"]),
        "minor 11" => new("minor 11", [0, 3, 7, 10, 14, 17], [0, 2, 4, 6, 8, 10], ["root", "minor third", "perfect fifth", "minor seventh", "major ninth", "perfect eleventh"]),
        "dominant 13" => new("dominant 13", [0, 4, 7, 10, 14, 17, 21], [0, 2, 4, 6, 8, 10, 12], ["root", "major third", "perfect fifth", "minor seventh", "major ninth", "perfect eleventh", "major thirteenth"]),
        "major 13" => new("major 13", [0, 4, 7, 11, 14, 17, 21], [0, 2, 4, 6, 8, 10, 12], ["root", "major third", "perfect fifth", "major seventh", "major ninth", "perfect eleventh", "major thirteenth"]),
```

  In jazz harmony, a dominant or major 13th chord leaves out the 11 for that very clash, and an 11th chord leaves out the third.
- **Over Cm7 and Cm11, F is a tension and a chord tone,** as in a textbook: a minor chord has no major third for the 11 to clash with.

## Reading the note

```text
== "why does <note> sound outside over Cmaj7": the note the skill reads, for each way to write it
written      notes     read      misread   not read
natural      7         7         0         0
sharp, #     7         7         0         0
flat, b      7         7         0         0
sharp, ♯     7         0         7         0
flat, ♭      7         0         7         0
lowercase    7         0         0         7
not read right: C♯: C; D♯: D; E♯: E; F♯: F; G♯: G; A♯: A; B♯: B; C♭: C; D♭: D; E♭: E; F♭: F; G♭: G; A♭: A; B♭: B; c: no answer; d: no answer; e: no answer; f: no answer; g: no answer; a: no answer; b: no answer
```

- **Every note written with `#` or `b` is read right, E#, Fb, B# and Cb included.**
- **Every note written with `♯` or `♭` is read as the natural.** The note is a letter, then `#` or `b`, not followed by a letter, a digit or `#` ([lines 295-299](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/OutsideNotesSkill.cs#L295-L299)): `♭` follows, so the letter alone is the note. Lesson 7 found the same for chord symbols, reported as [#757](https://github.com/GuitarAlchemist/ga/issues/757).
- **A lowercase note isn't read at all.** The note's regex is case-sensitive, which also keeps the article "a" from being read as A; "why does f sound outside over Cmaj7" gets the skill's refusal.

## Reading the chord

The chord is the root after the preposition and a run of `maj`, `min`, `m`, `M`, `dim`, `aug`, `sus`, `add`, `alt`, `ø`, `°`, `Δ`, `+`, digits, `#` and `b`, case ignored:

```csharp
    // "<prep> <root><quality>" — prep is over/against/on; root is A–G + optional
    // accidental; quality is the trailing chord-symbol run (letters/digits/#/b/°/ø/+).
    [GeneratedRegex(@"(?<prep>\bover\b|\bagainst\b|\bon\b)\s+(?:a\s+|an\s+|the\s+)?(?<root>[A-G][#b]?)(?<qual>(?:maj|min|m|M|dim|aug|sus|add|alt|ø|°|Δ|\+|\d|#|b)*)",
        RegexOptions.IgnoreCase)]
    private static partial Regex ChordAfterPrepRegex();
```

The program asks about F over C written 45 ways, and lists the chords the skill reads otherwise:

```text
== "why does F sound outside over C<chord>": the chord the skill reads, for each way to write it
written    read as                its notes          the chord's notes
C-         C                      C E G              C Eb G
C°         C °                    C E G              C Eb Gb
Co         C                      C E G              C Eb Gb
Cdom7      C                      C E G              C E G Bb
Cma7       Cm                     C Eb G             C E G B
CΔ7        C δ7                   C E G              C E G B
CΔ         C δ                    C E G              C E G B
C-7        C                      C E G              C Eb G Bb
Cmi7       Cm                     C Eb G             C Eb G Bb
Cm7♭5      C minor 7              C Eb G Bb          C Eb Gb Bb
C-7b5      C                      C E G              C Eb Gb Bb
Co7        C                      C E G              C Eb Gb A
C7♯9       C dominant 7           C E G A#           C Eb E G Bb
C7sus4     C 7sus4                C E G              C F G Bb
CmMaj7     C mmaj7                C E G              C Eb G B
Cm(maj7)   Cm                     C Eb G             C Eb G B
C7#11      C 7#11                 C E G              C E Gb G Bb
Cmaj7#11   C maj7#11              C E G              C E Gb G B
chords written 45: chords ChordVocabulary has 40, read right 27; chords it doesn't have 5, read right 0
```

- **27 of the 40 chords `ChordVocabulary` has are read right, and none of the 5 it lacks.**
- **The run stops at any other character.** "-" reads C-7 as C, "o" reads Co7 as C, the "a" of ma7 and the "i" of mi7 read Cma7 and Cmi7 as Cm, and "(" reads Cm(maj7) as Cm. `♭` and `♯` stop it too: Cm7♭5 is Cm7 and C7♯9 is C7. `NormalizeQuality` knows `dom7`, `ma7` and `-7` ([`ChordVocabulary.cs` lines 81-83](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/ChordVocabulary.cs#L81-L83)), but the run never hands them over.
- **What `NormalizeQuality` doesn't know becomes C E G.** `°` alone has no arm, `Δ` is lowercased to `δ`, as reported in [#783](https://github.com/GuitarAlchemist/ga/issues/783), and 7sus4, mMaj7, 7#11 and maj7#11 aren't in the vocabulary. `GetFormula` gives an unknown quality a major triad ([line 140](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/ChordVocabulary.cs#L140)). The answer still names the chord by its suffix, "C 7sus4", while it classifies F against C E G.
- **Because case is ignored, "a" and "the" can become the root.** In the example prompts below, "over a minor chord" is A major, and "over a dominant chord" is D major: the regex takes "a " as the article, then the "d" of "dominant" as the root.

## Spelling the chord's notes

The skill's evidence lists the chord's notes. It names them from two arrays of twelve names, sharps unless the chord is minor or diminished or its root is one of six flat keys ([lines 226-241](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/OutsideNotesSkill.cs#L226-L241)), and doesn't use the letter steps `ChordFormula` carries for that ([`ChordVocabulary.cs` lines 144-156](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/ChordVocabulary.cs#L144-L156)):

```text
== The chord's notes in the skill's evidence, against one letter per chord step, on 12 roots
chord            symbol  right     the first that differs: the skill's, a textbook's
major                    11 of 12  F#: Gb Bb Db; F# A# C#
minor            m       8 of 12   Dbm: Db E Ab; Db Fb Ab
dominant 7       7       9 of 12   C7: C E G A#; C E G Bb
major 7          maj7    11 of 12  F#maj7: Gb Bb Db F; F# A# C# E#
minor 7          m7      8 of 12   Dbm7: Db E Ab B; Db Fb Ab Cb
half-diminished  m7b5    6 of 12   Dbm7b5: Db E G B; Db Fb Abb Cb
diminished 7     dim7    3 of 12   Cdim7: C Eb Gb A; C Eb Gb Bbb
augmented        aug     6 of 12   Eaug: E G# C; E G# B#
```

- **C7 is C E G A#, F# major is Gb Bb Db, and Cdim7 is C Eb Gb A.** Most diminished sevenths need a double flat, a Cb or an Fb, which the arrays don't have; 3 of the 12 come out right.

## The example prompts

```text
== OutsideNotesSkill's example prompts, and a few other ways to ask: CanHandle, and the first line of the answer
prompt                                             CanHandle  answer
why does F sound outside over Cmaj7                yes        **F** over **C major 7**: an avoid note — the 11 (natural eleventh).
why does that note clash over the chord            yes        Tell me a single note and a single chord and I'll say whether it's a chord tone, a tension, or an avoid note — e.g. "why does F sound outside over Cmaj7" or "is A a tension over Cmaj7".
is F an avoid note over Cmaj7                      yes        **F** over **C major 7**: an avoid note — the 11 (natural eleventh).
what is F over G7                                  no         **F** over **G dominant 7**: a chord tone — the minor seventh.
why does the b9 sound so tense over C7             yes        Tell me a single note and a single chord and I'll say whether it's a chord tone, a tension, or an avoid note — e.g. "why does F sound outside over Cmaj7" or "is A a tension over Cmaj7".
is A a chord tone or a tension over Cmaj7          yes        **A** over **C major 7**: an available tension — the 13 (thirteenth).
why does Bb sound outside over C major             yes        **Bb** over **C**: an available tension — the b7 (minor seventh).
is F# an avoid note or a tension over Cmaj7        yes        **F#** over **C major 7**: an available tension — the #11 (sharp eleventh).
why does F clash over a Cmaj7 chord                yes        **F** over **C major 7**: an avoid note — the 11 (natural eleventh).
why does the note clash over this chord            no         Tell me a single note and a single chord and I'll say whether it's a chord tone, a tension, or an avoid note — e.g. "why does F sound outside over Cmaj7" or "is A a tension over Cmaj7".
why does F sound outside over a minor chord        yes        **F** over **A**: an avoid note — the b13 (flat thirteenth).
why does F sound outside over a dominant chord     yes        **F** over **D**: an available tension — the #9 (sharp ninth).
why does F sound outside on top of Cmaj7           no         Tell me a single note and a single chord and I'll say whether it's a chord tone, a tension, or an avoid note — e.g. "why does F sound outside over Cmaj7" or "is A a tension over Cmaj7".
why does the 11 clash over Cmaj7                   yes        Tell me a single note and a single chord and I'll say whether it's a chord tone, a tension, or an avoid note — e.g. "why does F sound outside over Cmaj7" or "is A a tension over Cmaj7".
example prompts 10: CanHandle accepts 8
```

- **Two example prompts get the refusal.** "why does that note clash over the chord" names no note, and "why does the b9 sound so tense over C7" names a degree: degree words are out of the skill's scope ([lines 31-34](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/OutsideNotesSkill.cs#L31-L34)), but the prompt is one of its examples. "why does the 11 clash over Cmaj7" gets the refusal too.
- **`CanHandle` accepts 8 of the 10.** It wants one of its keywords, a preposition and a chord ([lines 65-86](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/OutsideNotesSkill.cs#L65-L86)): "what is F over G7" has no keyword, though the skill answers it, and "why does the note clash over this chord" has no chord. At the pin the orchestrator doesn't call `CanHandle`; on `main`, the intent router asks it when it can't embed a question ([lesson 25](../25-what-reaches-the-transpose-skill/)).
- **"on top of" passes `CanHandle`'s preposition list, but not the regex,** which wants the chord right after "on": "why does F sound outside on top of Cmaj7" gets the refusal.

## Where the course stops

- **The chord scales are the course's.** `Usual` in `Lesson27.cs` lists the scales jazz textbooks usually give the five chords. Triads, sixth chords and sus chords aren't checked against a textbook: what is played over them depends more on the key.
- **The rule is checked on C.** The skill's verdict depends only on the interval from the root ([line 145](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/OutsideNotesSkill.cs#L145)); the spellings run on 12 roots.
- **No router runs.** The lesson calls the skill directly.

## Exercises

1. Over Cm7, why does the skill call F# an available tension? Which of Cm7's usual scales holds it?
2. What would the skill answer for "why does E sound outside over C7sus4"? What would a textbook say?
3. Why would "why does F sound outside over Cma7" get "an available tension — the 11"?
4. How could the rule change so that #9 over Cmaj7 is no longer safe to sustain, while #11 stays a tension?

<details>
<summary>Solutions</summary>

1. F# is not in Cm7, and it isn't a semitone above a chord tone: F, a semitone below it, isn't in the chord. So it falls to "an available tension". None of Dorian, Aeolian and Phrygian holds F#: they all have F.
2. 7sus4 isn't in `ChordVocabulary`, so `GetFormula` gives C E G, and E is a chord tone, the major third. A textbook's C7sus4 is C F G Bb: the 4th replaces the third, and E, a semitone below F, is the note the sus chord avoids. Worked from the code: the program asks about F over C7sus4, not E.
3. The run stops at the "a" of "ma7", so the chord is Cm. Over C Eb G, F is a fourth above the root, not a semitone above a chord tone, so it's a tension. Worked from the code and the chords table, where Cma7 reads as Cm.
4. Classify against the chord's scales as well as its tones: a non-chord tone is a tension only if a usual scale of the chord holds it. #11 stays a tension over Cmaj7, because Lydian holds it, while no usual scale holds #9.

</details>

## Key takeaways

- An avoid note is a property of the chord scale, not of the chord alone: a rule that looks only at chord tones can't tell an unusable note from a tension.
- When a headline and its explanation disagree, the user reads the headline.
- A chord formula is a claim about practice: stacking thirds to the 13th puts the clash the 11 causes inside the chord.
- A regex that captures part of a symbol needs the same alphabet as the vocabulary behind it.
- Spell a chord's notes from its letters, not from twelve names.

## Sources

- GuitarAlchemist/ga at [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `Common/GA.Business.ML/Agents/Skills/OutsideNotesSkill.cs`, `Common/GA.Business.ML/Agents/ChordVocabulary.cs`.
- The course's program: `code/ga-ai/GaAi/Lesson27.cs`.
