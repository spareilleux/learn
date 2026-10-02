---
title: "Lesson 17: The capo and the tunings"
description: "Guitar Alchemist's chatbot answers capo and tuning questions without a model. The course checks every answer against a textbook. The capo's arithmetic is right, but the skill reads the direction and the key from fixed phrasings: it answers a shape when asked what a capo sounds like, reads the article a as the key A and a sharp key without major as its letter, spells D sharp where the key is E flat, and can't say where to put the capo. The tunings skill drops the sharps of the six notes it reads, names E flat standard written in sharps as D standard, and gives open D for open D minor. GA's offline fallback reaches neither skill."
sidebar:
  label: 17. The capo and the tunings
  order: 17
---

[Lesson 16](../16-the-voicings-of-a-chord/) asked where to put the fingers for a chord. Two questions come before it: where the capo goes, and how the strings are tuned. Two skills of the chatbot answer them without a model, both built on 2026-05-14 to close two "dealbreakers" of GA's backlog. The router sends "what shape do I play in E with capo 4" to `skill.capo`, which runs `CapoSkill`, and "what is DADGAD tuning" to `skill.alternatetunings`, which runs `AlternateTuningsSkill` ([`GaPlugin.cs` lines 83 and 93](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs#L80-L93)). The first does semitone arithmetic, the second looks up a table of nine tunings ([`CapoSkill.cs` lines 6-23](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/CapoSkill.cs#L6-L23), [`AlternateTuningsSkill.cs` lines 6-23](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/AlternateTuningsSkill.cs#L6-L23)).

All GA links point to commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), the course's pin, unless they name another. Between the pin and GA's `main` at [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/commit/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) (2026-10-01), `CapoSkill` only marks its refusal `Declined`, which leaves its answers unchanged. `AlternateTuningsSkill` also changed the expressions that read a tuning's name. So the program asks the capo at the pin, and the tunings at the pin and in `GaMain`, the program of lesson 16 built from GA's `main`. Both compile the tuning questions from `code/ga-ai/Shared/TuningsProbe.cs`. The outputs come from:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l17
dotnet run --project code/ga-ai/GaMain -c Release -- l17
```

## Which prompts reach the two skills

Both skills answer `false` to `CanHandle`, with the comment "semantic-routing only" ([`CapoSkill.cs` line 47](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/CapoSkill.cs#L47), [`AlternateTuningsSkill.cs` line 50](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/AlternateTuningsSkill.cs#L50)), and still do on `main`. On `main`, when the router can't embed a question, it gives the question to the first intent, in registration order, whose skill's `CanHandle` accepts it ([`SemanticIntentRouter.cs` line 321](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Agents/Intents/SemanticIntentRouter.cs#L321), [`OrchestratorSkillIntent.cs` line 29](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.Core.Orchestration/Intents/OrchestratorSkillIntent.cs#L29)). The program starts the chatbot's host as in lesson 15 and asks every skill's `CanHandle` the 22 example prompts of the two skills:

```text
== Without embeddings: the first skill, in registration order, whose CanHandle accepts each example prompt
prompt                                                           first skill that accepts it
What shape do I play in E with capo 4                            none
Song is in E, what chord shape with capo on 4                    none
Capo on 3, song in G, what shape                                 none
I play a C shape with capo 3 — what does it sound like           none
What does a G shape sound like with capo 2                       none
Capo on 5, song in A                                             none
If I capo on 2 and play an Em shape, what's the sounding chord   skill.chordinfo
What's the sounding key if I play in G with capo on 5            none
Capo 7, D shape — sounding chord                                 none
What chord shape for B major with capo 4                         skill.chordvoicings
what is DADGAD tuning                                            none
what's drop D tuning                                             none
how do I tune to drop C                                          none
drop C tuning notes                                              none
how do I tune to open G                                          none
open D tuning notes                                              none
what is double drop D tuning                                     none
what's half step down tuning                                     none
whole step down tuning notes                                     none
DGCGCD tuning explained                                          none
how is DADGAD different from standard                            none
what tuning is Eb Ab Db Gb Bb Eb                                 none
skill intents 32; CanHandle of skill.capo and skill.alternatetunings accepts 0 of their 22 example prompts
```

- **Without embeddings, neither skill answers, though neither needs a model.** The fallback was added on `main` so that the deterministic skills answer when the embedding service is down. The capo and the tunings are deterministic and never get a question that way. Two of the capo's examples go to other skills: the chord-info skill takes the one that names Em, the voicings skill the one that asks for a "chord shape for B major".

## The capo

A capo raises every string by as many semitones as its fret. The guitarist plays the shape, the listener hears the shape plus the fret. `CapoSkill` reads the question with two expressions, one for a shape and one for a sounding key, and tries the shape first ([lines 52-64](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/CapoSkill.cs#L52-L64), [lines 89-104](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/CapoSkill.cs#L89-L104)):

```csharp
    private static readonly Regex SoundingToShape =
        new(@"(?:song\s+(?:is\s+)?in\s+|key\s+(?:is\s+|of\s+)?|in\s+)(?<key>[A-Ga-g][b#♭♯]?)(?:\s+(?<qual>major|minor|maj|min))?\b[^.?!]*?\bcapo\s+(?:on\s+|fret\s+|at\s+)?(?<n>\d{1,2})\b" +
            @"|" +
            @"\bcapo\s+(?:on\s+|fret\s+|at\s+)?(?<n2>\d{1,2})\b[^.?!]*?(?:song\s+(?:is\s+)?in\s+|key\s+(?:is\s+|of\s+)?|in\s+)(?<key2>[A-Ga-g][b#♭♯]?)(?:\s+(?<qual2>major|minor|maj|min))?\b",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);

    // Pattern B: "<shape> shape with capo <N>" → SOUNDING
    // Shape-side anchor: "<note> shape" or "play a <note> shape" or "<note>m shape"
    private static readonly Regex ShapeToSounding =
        new(@"\b(?:play(?:ing)?\s+(?:a\s+|an\s+)?)?(?<shape>[A-Ga-g][b#♭♯]?m?)\s+shape\b[^.?!]*?\bcapo\s+(?:on\s+|fret\s+|at\s+)?(?<n>\d{1,2})\b" +
            @"|" +
            @"\bcapo\s+(?:on\s+|fret\s+|at\s+)?(?<n2>\d{1,2})\b[^.?!]*?\b(?:play(?:ing)?\s+(?:a\s+|an\s+)?)?(?<shape2>[A-Ga-g][b#♭♯]?m?)\s+shape\b",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);
```

The program asks the skill its 10 example prompts, and compares each answer with what the prompt asks: the shape to play, or the chord that sounds.

```text
== CapoSkill's example prompts: what each asks, and the answer
prompt                                                           asks         answer         verdict
What shape do I play in E with capo 4                            shape C      shape C        right
Song is in E, what chord shape with capo on 4                    shape C      shape C        right
Capo on 3, song in G, what shape                                 shape E      shape E        right
I play a C shape with capo 3 — what does it sound like           sounds Eb    sounds D#      right, theoretical spelling
What does a G shape sound like with capo 2                       sounds A     sounds A       right
Capo on 5, song in A                                             shape E      shape E        right
If I capo on 2 and play an Em shape, what's the sounding chord   sounds F#m   sounds F#m     right
What's the sounding key if I play in G with capo on 5            sounds C     shape D        wrong direction
Capo 7, D shape — sounding chord                                 sounds A     sounds A       right
What chord shape for B major with capo 4                         shape G      declined       declined
```

```text
== Other phrasings
prompt                                                   asks           answer         verdict
song in Em, capo 2, what shape                           shape Dm       declined       declined
song in E minor, capo 2, what shape                      shape Dm       shape Dm       right
What shape do I play in e with capo 4                    shape C        shape C        right
what shape for F with capo 3                             shape D        declined       declined
capo on 3 in G, what shape                               shape E        shape E        right
Capo on 2, song in F#, what shape                        shape E        shape D#       wrong chord
song in C#, capo 4, what shape                           shape A        shape G#       wrong chord
song in B♭, capo 1, what shape                           shape A        shape A#       wrong chord
I'm in a band, capo 2, song is in G                      shape F        shape G        wrong chord
Playing in D with capo 2, what key does it sound in?     sounds E       shape C        wrong direction
I play a C7 shape with capo 3, what does it sound like   sounds Eb7     declined       declined
what does a Cmaj7 shape sound like with capo 2           sounds Dmaj7   declined       declined
capo 2, Dsus4 shape, what chord do I hear                sounds Esus4   declined       declined
```

- **The direction comes from the phrasing, not from the question.** Unless the question names a shape, a key after "in" is taken for the sounding key, and the skill answers the shape to play. Its own example "What's the sounding key if I play in G with capo on 5" gets the shape D instead of the sound C, and so does "Playing in D with capo 2, what key does it sound in?".
- **The article "a" is read as the key A.** Both expressions ignore case, so in "I'm in a band, capo 2, song is in G" the first "in" is followed by "a", and the skill answers the shape for A.
- **A sharp or flat key without "major" or "minor" after it is read as its letter.** The key ends with `\b`, a word boundary. `#`, `♯` and `♭` aren't word characters, so after them the boundary fails, and the expression backs off to the letter alone. "Capo on 2, song in F#" gets the shape D♯ instead of E, "song in C#, capo 4" G♯ instead of A, and "song in B♭, capo 1" A♯ instead of A. `b` is a letter, so "Bb" is read whole. [Lesson 7](../07-chord-names/) said that this skill and the tunings skill accept `♭` and `♯`: their expressions list both signs, but drop them here. With "major" or "minor" after the key, the boundary falls after the word, which is why the course's grid below is read right.
- **The skill declines what its expressions don't foresee.** A key must follow "in" or "key", so "What chord shape for B major with capo 4", one of its own examples, is declined. A minor key must be written as a word, so "song in Em" is declined. A shape is a letter, an accidental and an optional `m`, so the C7, Cmaj7 and Dsus4 shapes are declined.

## The spelling of the answers

The skill writes its answer with sharps, unless the key or the shape it read has a flat, or, for a shape, the question says "flat" ([lines 178-191](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/CapoSkill.cs#L178-L191)):

```csharp
    /// <summary>
    /// Pick the enharmonic spelling that matches the user's preferred side.
    /// If the user said "Eb major" → flats. If "F# major" → sharps.
    /// Default: sharps (guitarist convention).
    /// </summary>
    private static string SpellPc(int pc, bool preferFlats) =>
        preferFlats ? FlatNames[((pc % 12) + 12) % 12] : SharpNames[((pc % 12) + 12) % 12];

    private static bool KeyIsFlat(string keyRaw) =>
        keyRaw.IndexOf('b') >= 0 || keyRaw.IndexOf('♭') >= 0;

    private static bool ShapeIsFlat(string shapeRaw, string fullMessage) =>
        shapeRaw.IndexOf('b') >= 0 || shapeRaw.IndexOf('♭') >= 0
        || fullMessage.Contains("flat", StringComparison.OrdinalIgnoreCase);
```

The program asks for the 30 keys a key signature writes, major and minor, with the capo on frets 1 to 11, then for the eight open shapes with the capo on the same frets. It calls an answer **right, theoretical spelling** when the note is right but the key or chord it names is one no key signature writes, like D♯ major:

```text
== "Song is in <key>, what shape with capo <fret>": 30 keys, frets 1 to 11
key      prompts   right   right, theoretical spelling    wrong   declined
major    165       127     27 (A# D# G#)                  0       11 (Cb)
minor    165       159     6 (Dbm Gbm)                    0       0
the answers' "an Am shape at capo N would sound as …m": 319, a wrong chord 0, a theoretical minor key 16
```

```text
== "What does a <shape> shape sound like with capo <fret>": the eight open shapes, frets 1 to 11
shape    prompts   right   wrong   declined   right, theoretical spelling
C        11        8       0       0          3, capo 3: D#, 8: G#, 10: A#
A        11        8       0       0          3, capo 1: A#, 6: D#, 11: G#
G        11        8       0       0          3, capo 1: G#, 3: A#, 8: D#
E        11        8       0       0          3, capo 4: G#, 6: A#, 11: D#
D        11        8       0       0          3, capo 1: D#, 6: G#, 8: A#
Am       11        11      0       0          0
Em       11        11      0       0          0
Dm       11        11      0       0          0
```

- **The arithmetic is never wrong.** In both grids, no answer gives a wrong chord.
- **The spelling often is.** 27 shapes of the major grid, and 3 of the 11 answers for each major open shape, are A♯, D♯ or G♯ major, which a textbook writes B♭, E♭ and A♭. The class's own comment says a C shape with the capo on 3 sounds as E♭ ([line 13](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/CapoSkill.cs#L13)); the skill answers D♯. A minor key written with flats gives its shape in flats: D♭m and G♭m, which a textbook writes C♯m and F♯m.
- **C♭ major is declined.** The table of roots has no C♭ ([lines 67-76](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/CapoSkill.cs#L67-L76)), though its key signature has seven flats.

## Where to put the capo

The question a guitarist asks first is the other way round: where to put the capo to play a key with the open shapes C, A, G, E and D. The arithmetic is the same, run backwards. The program asks it for the 12 keys and lists the frets 0 to 7 that give an open shape:

```text
== "Where should I put the capo to play in <key> with open chords?"
key   frets 0 to 7 that give an open shape: C A G E D  the skill's answer
C     0 C, 3 A, 5 G                                    declined
Db    1 C, 4 A, 6 G                                    declined
D     0 D, 2 C, 5 A, 7 G                               declined
Eb    1 D, 3 C, 6 A                                    declined
E     0 E, 2 D, 4 C, 7 A                               declined
F     1 E, 3 D, 5 C                                    declined
F#    2 E, 4 D, 6 C                                    declined
G     0 G, 3 E, 5 D, 7 C                               declined
Ab    1 G, 4 E, 6 D                                    declined
A     0 A, 2 G, 5 E, 7 D                               declined
Bb    1 A, 3 G, 6 E                                    declined
B     2 A, 4 G, 7 E                                    declined
```

- **The skill declines all 12.** Both expressions need a fret number in the question.

## The tunings

`AlternateTuningsSkill` reads a tuning's name with nine expressions, one per tuning of its table ([lines 53-74](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/AlternateTuningsSkill.cs#L53-L74)), and answers the six notes, low string first, with what each string moves from standard tuning:

```csharp
    private static readonly (Regex Pattern, string Key)[] TuningPatterns =
    [
        // DADGAD — contiguous or hyphenated
        (new Regex(@"\b(?:dadgad|d-a-d-g-a-d)\b", RegexOptions.IgnoreCase | RegexOptions.Compiled), "dadgad"),
        // Drop D — but NOT "double drop D"
        (new Regex(@"(?<!\bdouble\s)(?<!\bdouble-)\bdrop[\s-]?d\b", RegexOptions.IgnoreCase | RegexOptions.Compiled), "drop-d"),
        // Double drop D
        (new Regex(@"\bdouble[\s-]?drop[\s-]?d\b", RegexOptions.IgnoreCase | RegexOptions.Compiled), "double-drop-d"),
        // Drop C — the (?![#b]) rejects "drop C#" / "drop Cb", which are
        // different tunings not in this table (better no match than a wrong one).
        (new Regex(@"\bdrop[\s-]?c\b(?![#b])", RegexOptions.IgnoreCase | RegexOptions.Compiled), "drop-c"),
        // Open G
        (new Regex(@"\bopen[\s-]?g\b", RegexOptions.IgnoreCase | RegexOptions.Compiled), "open-g"),
        // Open D
        (new Regex(@"\bopen[\s-]?d\b", RegexOptions.IgnoreCase | RegexOptions.Compiled), "open-d"),
        // DGCGCD (Sonic Youth / Pink Floyd style)
        (new Regex(@"\bdgcgcd\b", RegexOptions.IgnoreCase | RegexOptions.Compiled), "dgcgcd"),
        // Half step down
        (new Regex(@"\bhalf[\s-]?step[\s-]?down\b|\beb\s+standard\b", RegexOptions.IgnoreCase | RegexOptions.Compiled), "half-step-down"),
        // Whole step down
        (new Regex(@"\bwhole[\s-]?step[\s-]?down\b|\bd\s+standard\b", RegexOptions.IgnoreCase | RegexOptions.Compiled), "whole-step-down"),
    ];
```

```text
== AlternateTuningsSkill's example prompts: the tuning each one gets
prompt                                   answer                         verdict
what is DADGAD tuning                    DADGAD                         right
what's drop D tuning                     Drop D                         right
how do I tune to drop C                  Drop C                         right
drop C tuning notes                      Drop C                         right
how do I tune to open G                  Open G                         right
open D tuning notes                      Open D                         right
what is double drop D tuning             Double Drop D                  right
what's half step down tuning             Half-step down (Eb standard)   right
whole step down tuning notes             Whole-step down (D standard)   right
DGCGCD tuning explained                  DGCGCD                         right
how is DADGAD different from standard    DADGAD                         right
what tuning is Eb Ab Db Gb Bb Eb         Half-step down (Eb standard)   right
```

```text
== The nine tunings of the skill's table: notes and moves from standard, against a textbook
tuning                         notes                  moves from standard        as a textbook
DADGAD                         D A D G A D            -2st same same same -2st -2st right
Drop D                         D A D G B E            -2st same same same same same right
Double Drop D                  D A D G B D            -2st same same same same -2st right
Drop C                         C G C F A D            -4st -2st -2st -2st -2st -2st right
Open G                         D G D G B D            -2st -2st same same same -2st right
Open D                         D A D F# A D           -2st same same -1st -2st -2st right
DGCGCD                         D G C G C D            -2st -2st -2st same +1st -2st right
Half-step down (Eb standard)   Eb Ab Db Gb Bb Eb      -1st -1st -1st -1st -1st -1st right
Whole-step down (D standard)   D G C F A D            -2st -2st -2st -2st -2st -2st right
```

- **The table is right.** The 12 examples get their tuning, and the nine tunings' notes and moves are a textbook's.

## A tuning given by its notes

When no name matches, the skill reads the first six notes of the question and looks for a tuning of its table with the same spelling ([lines 203-211](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/AlternateTuningsSkill.cs#L203-L211), [lines 228-238](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/AlternateTuningsSkill.cs#L228-L238)):

```csharp
    private static string[]? TryParseSixNoteTuning(string msg)
    {
        var matches = Regex.Matches(msg, @"\b[A-Ga-g][b#♭♯]?\b");
        if (matches.Count < 6) return null;
        // Take the first 6 — accept that if the user mentions extra pitches
        // elsewhere in the prompt we might pick up garbage. Common phrasings
        // tend to put the 6 notes right next to each other.
        var arr = new string[6];
        for (var i = 0; i < 6; i++) arr[i] = NormalizeNote(matches[i].Value);
        return arr;
    }
```

The program asks "what tuning is …" with the notes of the nine tunings, of standard tuning and of E♭ standard written in sharps, in four notations: ASCII, `♯` and `♭`, hyphens between the notes, and lower case. It expects the tuning of the table with the same pitches, or, when none has them, the notes asked:

```text
== "what tuning is …" with the six notes, at the pin: the tuning each notation gets
tuning                         ASCII            ♯ and ♭          hyphens          lower case
DADGAD                         right            right            right            right
Drop D                         right            right            right            right
Double Drop D                  right            right            right            right
Drop C                         right            right            right            right
Open G                         right            right            right            right
Open D                         other notes      other notes      other notes      other notes
DGCGCD                         right            right            right            right
Half-step down (Eb standard)   right            other notes      right            right
Whole-step down (D standard)   right            right            right            right
standard                       right            right            right            right
Eb standard, in sharps         another tuning   another tuning   another tuning   another tuning
questions 44: answered with the tuning asked or its notes 35, with another named tuning 4, other answers 5
  Open D, every notation: no name, reads D A D F A D
  Half-step down (Eb standard), ♯ and ♭: no name, reads E A D G B E
  Eb standard, in sharps, every notation: Whole-step down (D standard)
```

- **The expression drops the sharps, and the flats written `♭`.** It ends with `\b`, as the capo's key does. F♯ is read as F, so Open D's notes, D A D F♯ A D, are read as D A D F A D, which no tuning matches, in every notation. E♭ A♭ D♭ G♭ B♭ E♭ is read as E A D G B E, standard tuning, which the skill doesn't name.
- **E♭ standard written in sharps is named Whole-step down.** D♯ G♯ C♯ F♯ A♯ D♯ is read as D G C F A D, a tuning a semitone lower on every string, and the answer gives its name and its table.
- **On `main`, the reading of six notes is the pin's,** and `GaMain` prints the same table.

## Tunings outside the table

The program asks for ten tunings by name, outside the table or written with an accidental, and compares the notes of the answer with the tuning asked:

```text
== Tunings outside the table, at the pin
prompt                                       asks for            answer                           verdict
what is open D minor tuning                  D A D F A D         Open D: D A D F# A D             another tuning
what is open G minor tuning                  D G D G Bb D        Open G: D G D G B D              another tuning
what is open E tuning                        E B E G# B E        declined                         declined
what is open C tuning                        C G C G C E         declined                         declined
what is drop B tuning                        B F# B E G# C#      declined                         declined
what is C standard tuning                    C F Bb Eb G C       declined                         declined
what is drop C# tuning                       C# G# C# F# A# D#   declined                         declined
what is drop C♯ tuning                       C# G# C# F# A# D#   Drop C: C G C F A D              another tuning
what is drop D♭ tuning                       Db Ab Db Gb Bb Eb   Drop D: D A D G B E              another tuning
what is standard tuning                      E A D G B E         declined                         declined
"What does an Em shape look like in drop-D": Drop D, the answer names Em: no
```

```text
== Tunings outside the table, on main
prompt                                       asks for            answer                           verdict
what is open D minor tuning                  D A D F A D         Open D: D A D F# A D             another tuning
what is open G minor tuning                  D G D G Bb D        Open G: D G D G B D              another tuning
what is open E tuning                        E B E G# B E        declined                         declined
what is open C tuning                        C G C G C E         declined                         declined
what is drop B tuning                        B F# B E G# C#      declined                         declined
what is C standard tuning                    C F Bb Eb G C       declined                         declined
what is drop C# tuning                       C# G# C# F# A# D#   declined                         declined
what is drop C♯ tuning                       C# G# C# F# A# D#   declined                         declined
what is drop D♭ tuning                       Db Ab Db Gb Bb Eb   declined                         declined
what is standard tuning                      E A D G B E         declined                         declined
"What does an Em shape look like in drop-D": Drop D, the answer names Em: no
```

- **Open D minor gets open D, and open G minor gets open G.** The expression for open D stops at the `d`, and "minor" after it isn't read. The answer gives F♯ where the guitarist asked for F, and B where they asked for B♭.
- **At the pin, "drop C♯" gets drop C, and "drop D♭" drop D.** The pin's drop C rejects an ASCII `#` or `b` after its letter, not `♯` or `♭`, and its drop D has no such check. On `main`, the expressions of drop D, double drop D, drop C, open G and open D reject all four, and both questions are declined ([lines 57-67 on `main`](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Agents/Skills/AlternateTuningsSkill.cs#L57-L67)).
- **The tunings outside the table are declined,** as the comment of drop C wants it: "better no match than a wrong one". Standard tuning is one of them.
- **The class's comment promises an answer the code doesn't give.** It lists "What does an Em shape look like in drop-D" with "caveat about altered low E string" ([line 15](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/AlternateTuningsSkill.cs#L15)). The skill answers the drop D table, which doesn't name Em.

## Where the course stops

- **The router and the model aren't run.** Which intent the router picks for these questions in production needs the embeddings (*to verify*).
- **The theoretical spelling is the course's test:** a major or minor key or chord whose root no key signature writes with that quality. A guitarist reading a chord chart may accept A♯ for B♭; a key signature can't.
- **The capo runs at the pin only.** On `main`, `CapoSkill` differs by the `Declined` flag of its refusal, read from the diff.

## Exercises

1. Why is "song in Em, capo 2, what shape" declined? What does the pinned skill answer to "song in E min, capo 2, what shape"?
2. How can a guitarist get B♭ rather than A♯ from "What does an A shape sound like with capo 1"?
3. At the pin, what does the tunings skill answer to "what tuning is D A D Gb A D"? Which of its two steps keeps it from naming open D?
4. At the pin, why is "what is drop Db tuning" declined, while "what is drop D♭ tuning" gets drop D?

<details>
<summary>Solutions</summary>

1. After the key, the expression wants a word boundary, or a space and one of `major`, `minor`, `maj` or `min`. "Em" is one word, so the boundary fails between E and m, and the question is declined. "song in E min, capo 2, what shape" gets the shape Dm. Checked by running the pinned skill outside the course's expected output.
2. With the word "flat" anywhere in the question, for example "What does an A shape sound like with capo 1, in flats": for a shape, the skill writes flats when the question contains "flat", and answers B♭. Checked by running the pinned skill outside the course's expected output.
3. No name, with the notes D A D Gb A D. Here the reading is whole, since `b` is a letter, but `NotesMatch` compares spellings: G♭ isn't F♯. Checked by running the pinned skill outside the course's expected output.
4. In ASCII, `b` is a letter, so there's no word boundary between `D` and `b`, and the expression for drop D doesn't match. Six notes aren't there either, so the skill declines. `♭` isn't a word character, so the boundary holds between `D` and `♭`, and the expression matches. Checked by running the pinned skill outside the course's expected output.

</details>

## Key takeaways

- An answer of arithmetic can be checked against a textbook prompt by prompt: here, every key a signature writes on every fret, and 44 tunings given by their notes.
- An expression that reads a key must take the accidental with the letter: `\b` after `#`, `♯` or `♭` fails, and the expression keeps the letter.
- A skill that reads the direction from the phrasing answers the other question when the phrasing changes.
- Spelling is part of the answer: D♯ and E♭ are the same fret, not the same key.
- A skill that needs no model should be reachable without one.

## Sources

- GuitarAlchemist/ga at [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `Common/GA.Business.ML/Agents/Skills/CapoSkill.cs`, `Common/GA.Business.ML/Agents/Skills/AlternateTuningsSkill.cs`, `Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs`.
- GuitarAlchemist/ga at [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/tree/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a): the same two skills, `Common/GA.Business.ML/Agents/Intents/SemanticIntentRouter.cs`, `Common/GA.Business.Core.Orchestration/Intents/OrchestratorSkillIntent.cs`.
- The course's programs: `code/ga-ai/GaAi/Lesson17.cs`, `code/ga-ai/GaMain/Program.cs`, `code/ga-ai/Shared/TuningsProbe.cs`.
