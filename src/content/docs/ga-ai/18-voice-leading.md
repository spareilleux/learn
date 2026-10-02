---
title: "Lesson 18: Voice leading"
description: "Guitar Alchemist's chatbot answers voice-leading questions without a model, by trying every pairing of two chords' notes. The course checks each total against the least motion a textbook finds. Between two chords of the same size the total is always the least. When the sizes differ, the skill doubles the root and moves more than needed in 1186 of 3072 answers, one of its own examples among them, while every answer claims that any other voicing moves more. It reads only 24 of 46 chord symbols right, drops a sharp, flat or diminished sign at the end of the question, reads CM7 as C minor seventh, spells B flat as A sharp, and GA's offline fallback never reaches it."
sidebar:
  label: 18. Voice leading
  order: 18
---

[Lesson 17](../17-the-capo-and-the-tunings/) asked where the capo goes and how the strings are tuned. Once the chords are chosen, the next question is how to move from one to the next. Voice leading answers it: each note of a chord is a voice, and each voice moves to a note of the next chord, as little as possible. The router sends "voice leading from C to F" to `skill.voiceleading`, which runs `VoiceLeadingSkill`, registered between the capo and the tunings ([`GaPlugin.cs` lines 85-88](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs#L85-L88)). It was built on 2026-05-14, like them, to close a "dealbreaker" of GA's backlog, and it needs no model: it tries every pairing of the two chords' notes and keeps the one that moves least ([`VoiceLeadingSkill.cs` lines 6-23](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/VoiceLeadingSkill.cs#L6-L23)).

All GA links point to commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), the course's pin, unless they name another. `VoiceLeadingSkill.cs` is the same on GA's `main` at [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/commit/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) (2026-10-01), so the program asks it at the pin only. The output comes from:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l18
```

## Which prompts reach the skill

`CanHandle` answers `false`, with the comment "semantic-routing only" ([line 49](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/VoiceLeadingSkill.cs#L49)). On `main`, when the router can't embed a question, it gives the question to the first intent, in registration order, whose skill's `CanHandle` accepts it ([`SemanticIntentRouter.cs` line 321](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Agents/Intents/SemanticIntentRouter.cs#L321), [`OrchestratorSkillIntent.cs` line 29](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.Core.Orchestration/Intents/OrchestratorSkillIntent.cs#L29)). The program starts the chatbot's host as in lesson 15 and asks every skill's `CanHandle` the skill's 10 example prompts:

```text
== Without embeddings: the first skill, in registration order, whose CanHandle accepts each example prompt
prompt                                       first skill that accepts it
voice leading from C to F                    none
smooth voice leading C to Am                 none
best voicing from G7 to Cmaj7                skill.chordvoicings
how do I voice lead Dm7 to G7                none
voice leading C major to G major             none
smoothest voicing from Em to A7              skill.chordvoicings
voice leading Fmaj7 to Bm7b5                 none
what's the smoothest voicing from D to A     none
voice lead C7 to F                           none
best way to move from G7 to C                none
skill intents 32; CanHandle of skill.voiceleading accepts 0 of its 10 example prompts
```

- **Without embeddings, the skill never answers, though it needs no model.** Two of its examples go to the voicings skill of [lesson 16](../16-the-voicings-of-a-chord/), because they say "voicing": that skill answers fingerings for one chord, not the move between two.
- **On `main`, a refusal can be marked `Declined`,** "so a caller may route it to another handler" ([`GuitarAlchemistAgentBase.cs` lines 347-352 on `main`](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Agents/GuitarAlchemistAgentBase.cs#L347-L352)). The skill's two refusals aren't ([lines 280-294](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/VoiceLeadingSkill.cs#L280-L294)).

## How the skill answers

The skill reads two chord symbols around "to", "→", "->" or ">" ([lines 51-57](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/VoiceLeadingSkill.cs#L51-L57)):

```csharp
    // Two-chord pattern: <chord A> to/→/-> <chord B>. The chord token allows
    // root + optional accidental + optional quality keyword + optional digit
    // + optional flat/sharp-with-digit modifiers (b5, #9, b9...) + optional
    // ° symbol for diminished.
    private static readonly Regex TwoChordPattern =
        new(@"\b(?<a>[A-Ga-g][b#♭♯]?(?:maj|min|m|dim|aug|sus|add|dom)?\d*(?:[b#♭♯]\d+)*°?)\s+(?:to|→|->|>)\s+(?<b>[A-Ga-g][b#♭♯]?(?:maj|min|m|dim|aug|sus|add|dom)?\d*(?:[b#♭♯]\d+)*°?)\b",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);
```

It turns each symbol into pitch classes, then pairs the notes of the two chords. When one chord has fewer notes, it repeats that chord's root until both have as many ([lines 101-110](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/VoiceLeadingSkill.cs#L101-L110), [`Pad`, lines 185-194](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/VoiceLeadingSkill.cs#L185-L194)):

```csharp
        // For an exhaustive minimum-cost matching, we permute the SHORTER chord
        // against subsets of the larger. To keep the explanation crisp, we pad
        // the smaller chord by repeating its root so |A| = |B| for assignment
        // — this is the standard voice-leading framing when voice counts
        // differ (e.g. triad → 7th chord adds a voice that gets the new tone).
        var n = Math.Max(chordA.Length, chordB.Length);
        var paddedA = Pad(chordA, n);
        var paddedB = Pad(chordB, n);

        var (bestPerm, bestCost) = FindBestAssignment(paddedA, paddedB);
```

`FindBestAssignment` tries every permutation and keeps the first with the least total, each voice moving by the shorter way, at most 6 semitones ([lines 139-183](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/VoiceLeadingSkill.cs#L139-L183)). The answer gives the total, a table of the voices, and a closing sentence: "This is the optimal pitch-class assignment — every other voicing of … requires more total semitone movement" ([line 131](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/VoiceLeadingSkill.cs#L131)).

The program reads the total and the table of each answer. It names the chords the table moves from and to, and compares the total with the **least motion**: as many voices as the larger chord, every note of both chords sounded, and any note of the smaller chord doubled. It also counts the pairings, in the skill's own frame with the root doubled, that reach the skill's total.

```text
== VoiceLeadingSkill's example prompts: the chords read, the total motion, and the least motion
prompt                                     asks           reads          total   least  best pairings
voice leading from C to F                  C → F          C → F          3       3      1
smooth voice leading C to Am               C → Am         C → Am         2       2      1
best voicing from G7 to Cmaj7              G7 → Cmaj7     G7 → Cmaj7     3       3      1
how do I voice lead Dm7 to G7              Dm7 → G7       Dm7 → G7       3       3      1
voice leading C major to G major           C → G          declined       -       -      -
smoothest voicing from Em to A7            Em → A7        Em → A7        5       4      1
voice leading Fmaj7 to Bm7b5               Fmaj7 → Bm7b5  Fmaj7 → Bm7b5  3       3      1
what's the smoothest voicing from D to A   D → A          D → A          3       3      1
voice lead C7 to F                         C7 → F         C7 → F         4       4      1
best way to move from G7 to C              G7 → C         G7 → C         4       4      1
```

- **Eight examples get the least motion.** Between C and F, the voice on C stays, E goes up to F and G up to A: 3 semitones.
- **"smoothest voicing from Em to A7" gets 5 semitones, where 4 are enough.** Em has three notes and A7 four, so the skill doubles E. Doubling G or B instead moves 4 semitones, and the answer still says that every other voicing moves more.
- **"voice leading C major to G major" is declined.** A chord must be followed by spaces and "to", so the word "major" after C breaks the expression.

## The least motion, chord by chord

The program asks "voice leading C… to …" for the 16 qualities the skill builds, on C and on each of the 12 roots, and groups the answers by the number of notes of the two chords:

```text
== "voice leading C<quality> to <root><quality>": the 16 qualities the skill builds, on C and on each of the 12 roots
voices   prompts   read right   least motion   more than the least   most extra   several best pairings
3 → 3    432       432          432            0                     0            54
3 → 4    504       504          266            238                   5            69
3 → 5    216       216          34             182                   7            67
4 → 3    504       504          266            238                   5            69
4 → 4    588       588          588            0                     0            56
4 → 5    252       252          79             173                   5            88
5 → 3    216       216          34             182                   7            67
5 → 4    252       252          79             173                   5            88
5 → 5    108       108          108            0                     0            49
prompts 3072: closing on "every other voicing … requires more total semitone movement" 3072, more motion than the least 1186, several best pairings 607
by how much more: 1 semitone 512, 2 semitones 294, 3 semitones 240, 4 semitones 94, 5 semitones 24, 6 semitones 20, 7 semitones 2
the first answers with the most extra motion:
  Csus2 to Em9: 11 semitones, least 4
  Cm9 to Absus2: 11 semitones, least 4
  Cm to Emaj9: 10 semitones, least 4
  Cm to Em9: 10 semitones, least 4
  Cm to Fm9: 9 semitones, least 3
the first answers with the most best pairings:
  Cmaj9 to Em9: 7 pairings
  Cm9 to Abmaj9: 7 pairings
  Csus2 to Em9: 5 pairings
```

- **Between two chords of the same size, the total is always the least.** Every permutation is tried, and no doubling is needed.
- **When the sizes differ, the root is the wrong note to double in 1186 answers.** The new voice must reach the note the smaller chord lacks, and starting it from the root can cost up to 7 semitones more than starting it from another note. From Csus2 to Em9, the two extra voices start on C: 11 semitones, where 4 are enough. The skill's comment calls root doubling "the standard voice-leading framing", and four-part harmony does double the root of a triad first. But then the answer is the best move with the root doubled, not the least motion.
- **The closing sentence is in all 3072 answers.** It's wrong in the 1186 answers where another doubling moves less, and in the 607 where another pairing in the skill's own frame moves just as little.

## The chord symbols

`BuildChord` lowercases the quality, then looks it up in a table of 16 qualities ([lines 224-252](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/VoiceLeadingSkill.cs#L224-L252)):

```csharp
    private static int[]? BuildChord(int root, string quality)
    {
        var q = quality.ToLowerInvariant().Trim();

        // Tone choices: 1, b3, 3, 4, b5, 5, #5, 6, b7, 7, b9, 9, #9, 11, #11, 13
        int[]? intervals = q switch
        {
            "" or "maj" or "major"           => [0, 4, 7],                     // major triad
            "m" or "min" or "minor" or "-"   => [0, 3, 7],                     // minor triad
            "dim" or "°" or "o"              => [0, 3, 6],                     // dim triad
            "aug" or "+"                     => [0, 4, 8],                     // aug triad
            "7"                              => [0, 4, 7, 10],                 // dom 7
            "m7" or "min7" or "-7"           => [0, 3, 7, 10],                 // min 7
            "maj7" or "major7" or "M7" or "Δ7" or "Δ"
                                             => [0, 4, 7, 11],                 // maj 7
            "m7b5" or "ø" or "ø7" or "half-dim" or "min7b5"
                                             => [0, 3, 6, 10],                 // half-dim
            "dim7" or "°7" or "o7"           => [0, 3, 6, 9],                  // dim 7
            "sus2"                           => [0, 2, 7],
            "sus4" or "sus"                  => [0, 5, 7],
            "6"                              => [0, 4, 7, 9],                  // maj 6
            "m6" or "min6"                   => [0, 3, 7, 9],                  // min 6
            "9"                              => [0, 4, 7, 10, 2],              // dom 9
            "maj9"                           => [0, 4, 7, 11, 2],
            "m9" or "min9"                   => [0, 3, 7, 10, 2],
            // Unknown quality — return null so the caller emits CannotParse
            // instead of pretending the chord is a major triad.
            _                                => null,
        };
```

The program writes each symbol on C, first as the first chord, then as the last:

```text
== Each chord symbol on C, as the first chord ("voice leading C<symbol> to F") and as the last ("voice leading F to C<symbol>")
written    means      first                  last
C          C          right                  right
Cmaj       C          right                  right
C major    C          declined               right
Cm         Cm         right                  right
Cmin       Cm         right                  right
C minor    Cm         declined               reads C
C-         Cm         declined               reads C
Cdim       Cdim       right                  right
C°         Cdim       right                  reads C
Co         Cdim       declined               declined
Caug       Caug       right                  right
C+         Caug       declined               reads C
Csus2      Csus2      right                  right
Csus4      Csus4      right                  right
Csus       Csus4      right                  right
C7         C7         right                  right
Cdom7      C7         declined               declined
Cm7        Cm7        right                  right
Cmin7      Cm7        right                  right
C-7        Cm7        declined               reads C
Cmaj7      Cmaj7      right                  right
CM7        Cmaj7      reads Cm7              reads Cm7
CΔ7        Cmaj7      declined               declined
CΔ         Cmaj7      declined               declined
Cmajor7    Cmaj7      declined               declined
Cm7b5      Cm7b5      right                  right
Cmin7b5    Cm7b5      right                  right
Cø         Cm7b5      declined               declined
Cø7        Cm7b5      declined               declined
Cdim7      Cdim7      right                  right
C°7        Cdim7      declined               reads Cdim
Co7        Cdim7      declined               declined
C6         C6         right                  right
Cm6        Cm6        right                  right
Cmin6      Cm6        right                  right
C9         C9         right                  right
Cmaj9      Cmaj9      right                  right
Cm9        Cm9        right                  right
Cmin9      Cm9        right                  right
Cadd9      Cadd9      declined               declined
C7sus4     C7sus4     declined               declined
C7b9       C7b9       declined               declined
C7#9       C7#9       declined               declined
CmMaj7     CmMaj7     declined               declined
C11        C11        declined               declined
C13        C13        declined               declined
symbols 46: read right as the first chord 24, as the last 24
```

- **The table lists more symbols than the expression lets through.** After the root, the expression takes one word among `maj`, `min`, `m`, `dim`, `aug`, `sus`, `add` and `dom`, digits, accidentals followed by digits, and a final `°`. `Δ`, `ø`, `+`, `-`, `o`, "major7" and "dom7" never reach the table, or reach it in a form it doesn't list. As the first chord, they're all declined. As the last, `+` and `-` stop the expression, which keeps the letter: "voice leading F to C+" gets C major. The others are declined.
- **Words after the last chord are ignored.** "voice leading F to C minor" gets C major, and "voice leading F to C major" is right by chance.
- **CM7 is read as C minor seventh.** The table lists `M7`, but the quality is lowercased first, so `m7` matches before it. "voice leading CM7 to FM7" moves Cm7 to Fm7. C minor seventh has E♭ and B♭ where C major seventh has E and B.
- **A final `°` is dropped.** The expression ends with `\b`, a word boundary, and `°` isn't a word character: "voice leading F to C°" gets C major. As the first chord, `°` is read, but "C°7" is declined, since `°` may only end the symbol.
- **Seven common chords are declined:** add9, 7sus4, 7♭9, 7♯9, mMaj7, 11 and 13. The comment says it's deliberate: a review of 2026-05-14 found that unknown qualities were answered as major triads ([lines 216-223](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/VoiceLeadingSkill.cs#L216-L223)).

## A root with an accidental

The program writes the ten roots with an accidental, in ASCII and with `♯` and `♭`, as the first chord and as the last:

```text
== A root with an accidental, first ("voice leading <root> to C") and last ("voice leading C to <root>", "… to <root>m")
notation   first    last     last, m   the root first, spelled   the last, misread as
ASCII #    5 of 5   0 of 5   5 of 5    C#, D#, F#, G#, A#        C, D, F, G, A
♯          5 of 5   0 of 5   5 of 5    C#, D#, F#, G#, A#        C, D, F, G, A
ASCII b    5 of 5   5 of 5   5 of 5    Db, Eb, Gb, Ab, A#        -
♭          5 of 5   0 of 5   5 of 5    Db, Eb, Gb, Ab, Bb        D, E, G, A, B
```

- **A sharp, or a flat written `♭`, is dropped at the end of the question.** The same `\b` fails after `#`, `♯` and `♭`, and the expression keeps the letter: "voice leading from C to F#" gets C → F. The answer's first line names the chord read, so a careful reader can see it. `b` is a letter, so "Db" is read whole, and with `m` after the accidental the boundary falls after the `m`. The capo and tunings skills of lesson 17 have the same fault.
- **The skill's own refusal suggests B°,** "Try a chord-symbol like C, Am, G7, Cmaj7, Dm7, F#m7b5, or B°", which is read only as the first chord.

## The spelling of the answers

The skill spells the notes with sharps, unless one of the two symbols has a flat or the question says "flat" ([lines 85-86](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/VoiceLeadingSkill.cs#L85-L86), [lines 261-266](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/VoiceLeadingSkill.cs#L261-L266)):

```csharp
    private static bool TokenHasFlats(string token) =>
        token.IndexOf('b', StringComparison.OrdinalIgnoreCase) > 0  // 'b' at position 0 is the note B, not a flat
        || token.IndexOf('♭') >= 0;

    private static string Spell(int pc, bool preferFlats) =>
        preferFlats ? FlatNames[((pc % 12) + 12) % 12] : SharpNames[((pc % 12) + 12) % 12];
```

The program asks ii7 to V7 and V7 to Imaj7 in the 12 major keys, and V7 to i in the 12 minor keys, and lists the notes the skill spells otherwise than their chord does:

```text
== Spelling: ii7 to V7 and V7 to Imaj7 in the 12 major keys, the notes spelled otherwise than in their chord
key   ii7 to V7                          V7 to Imaj7
C     as spelled                         as spelled
G     as spelled                         as spelled
D     as spelled                         as spelled
A     as spelled                         as spelled
E     as spelled                         as spelled
B     as spelled                         as spelled
F#    F for E#                           F for E#
F     A# for Bb                          A# for Bb
Bb    D# for Eb, A# for Bb               A# for Bb, D# for Eb
Eb    G# for Ab, A# for Bb, D# for Eb    as spelled
Ab    as spelled                         as spelled
Db    as spelled                         as spelled
```

```text
== Spelling: V7 to i in the 12 minor keys
key   V7 to i
Cm    D# for Eb
Gm    A# for Bb
Dm    as spelled
Am    as spelled
Em    as spelled
Bm    as spelled
F#m   F for E#
C#m   C for B#
G#m   G for F##
Fm    A# for Bb, G# for Ab
Bbm   A# for Bb, D# for Eb, C# for Db
Ebm   as spelled
prompts 36: every note spelled as in its chord 22
```

- **A B♭ root written in ASCII doesn't count as a flat.** `TokenHasFlats` looks for a `b` ignoring case, which finds the root `B` of "Bb" at position 0, and the test wants a position above 0. So "F7 to Bbmaj7" gives A♯ and D♯, and "Bb" as the first chord is spelled A♯. Written `B♭`, it counts.
- **Without a flat in the question, a flat key gets sharps.** D7 to Gm gives A♯ for B♭: the skill doesn't know the key, only the two symbols.
- **Twelve names can't spell every chord.** The skill has one name per pitch class. In F♯ major, E♯ is written F. The B♯ of G♯7 is written C, and the double-sharp F of D♯7 is written G.

## Other phrasings

```text
== Other phrasings
prompt                                         asks                   reads            verdict
how do I get from G7 to a C chord              G7 → C                 G7 → A           wrong chord
voice leading Dm7 to G7 to Cmaj7               Dm7 → G7 → Cmaj7       Dm7 → G7         reads 2 of 3 chords
voice leading CM7 to FM7                       Cmaj7 → Fmaj7          Cm7 → Fm7        wrong chord
voice leading G7 → C                           G7 → C                 G7 → C           right
voice leading G7 - C                           G7 → C                 declined         declined
voice leading from G7 into C                   G7 → C                 declined         declined
voice leading from C to F#                     C → F#                 C → F            wrong chord
voice leading from G to B°                     G → Bdim               G → B            wrong chord
smooth voice leading from C major to A minor   C → Am                 declined         declined
how do I voice lead Bb to Eb                   Bb → Eb                Bb → Eb          right
```

- **The article "a" is read as the chord A.** The expression ignores case, so in "how do I get from G7 to a C chord" the chord after "to" is "a": the skill moves G7 to A major.
- **A progression of three chords gets only its first move.** The expression reads one pair, and the answer doesn't say that it stopped.
- **"-" and "into" aren't read as "to",** and chords written as words are declined.

## Where the course stops

- **The router and the model aren't run.** Which intent the router picks for these questions in production needs the embeddings (*to verify*).
- **The least motion is the course's test:** every note of both chords sounded, as many voices as the larger chord. A textbook may also drop the fifth of a seventh chord, which would move even less, and it places the voices in registers. The skill and the course both work on pitch classes, so a "voicing" here has no octave and no fret.
- **Another path in GA moves real voicings.** The MCP tool `ga_voice_leading_pair` pairs playable voicings of the OPTIC-K index with "a greedy sorted-pitch matching", "not a formal Hungarian-optimal assignment" ([`CompositionTools.cs` lines 179-186](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L179-L186)). The course doesn't run it.

## Exercises

1. "voice leading from C to F#" gets C → F. Give two ways to write the question so that the skill moves C to F♯ major.
2. The skill moves Em to A7 by 5 semitones. Which note of Em must be doubled to move only 4, and how?
3. Why does "voice leading F7 to Bbmaj7" spell A♯ and D♯, while "voice leading F7 to B♭maj7" spells B♭ and E♭? Give a third way to get flats.
4. "voice leading CM7 to FM7" and "voice leading Cmaj7 to Fmaj7" both get 4 semitones. How does the answer show that the first moves other chords?

<details>
<summary>Solutions</summary>

1. Write the flat, `Gb`: `b` is a letter, so the boundary holds after it, and "voice leading from C to Gb" moves C to G♭ by 6 semitones, spelled with flats. Or add a quality: "voice leading from C to F#maj" ends on the `j`, and gets the same 6 semitones, spelled with sharps. Checked by running the pinned skill outside the course's expected output.
2. G or B. Doubling B: E stays, G stays, B goes down to A and the other B up to C♯, 0 + 0 + 2 + 2. Doubling G: E stays, G stays, the other G goes up to A, and B up to C♯, 0 + 0 + 2 + 2. The skill doubles E, which must go down 3 semitones to C♯ while B goes down 2 to A. Checked by running the pinned skill outside the course's expected output.
3. `TokenHasFlats` looks for `b` ignoring case and finds the `B` of "Bbmaj7" at position 0, which it takes for the note B; `♭` is found directly. With "flat" anywhere in the question, for example "voice leading F7 to Bbmaj7 in flats", the answer is spelled with flats. Checked by running the pinned skill outside the course's expected output.
4. By its notes: the table of the first gives D♯ and A♯, the E♭ and B♭ of Cm7, where Cmaj7 has E and B. The first line also echoes "CM7 → FM7", which hides the misreading. Checked by running the pinned skill outside the course's expected output.

</details>

## Key takeaways

- An optimal search is optimal only over what it searches: trying every permutation finds the best pairing, not the best doubling.
- A claim of optimality in an answer is a claim the program can check, answer by answer, against a slower exhaustive search.
- A table of symbols promises only what the expression in front of it lets through.
- `\b` after `#`, `♯`, `♭` or `°` fails, and the expression keeps the letter: the same fault as lessons 7, 9 and 17.
- A case-insensitive search for the flat `b` finds the note B.

## Sources

- GuitarAlchemist/ga at [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `Common/GA.Business.ML/Agents/Skills/VoiceLeadingSkill.cs`, `Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs`, `GaMcpServer/Tools/CompositionTools.cs`.
- GuitarAlchemist/ga at [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/tree/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a): the same skill, `Common/GA.Business.ML/Agents/GuitarAlchemistAgentBase.cs`, `Common/GA.Business.ML/Agents/Intents/SemanticIntentRouter.cs`, `Common/GA.Business.Core.Orchestration/Intents/OrchestratorSkillIntent.cs`.
- The course's program: `code/ga-ai/GaAi/Lesson18.cs`.
