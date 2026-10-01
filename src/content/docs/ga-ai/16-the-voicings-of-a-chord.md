---
title: "Lesson 16: The voicings of a chord"
description: "Guitar Alchemist's chatbot answers a request for the voicings of a chord without a model, from the OPTIC-K index. The course plays every diagram it returns, at the pin and with the voicing pipeline of GA's main, which changed after the pin. On main, every voicing plays the chord the skill read. The reading and the names decide the rest: minor and every spelled-out quality are read as a major triad, CanHandle rejects a bare major chord, C-7 is read as C7, the 6th chords, eight augmented and six sus4 triads of a 144-chord grid get no voicing of their own because the index names them otherwise, and five of the 48 voicings answered for a technique are that technique."
sidebar:
  label: 16. The voicings of a chord
  order: 16
---

[Lesson 15](../15-the-notes-of-a-chord/) asked the chatbot which notes make a chord. This lesson asks the question a guitarist asks next: where to put the fingers. The router sends "voicings for Cmaj7" to the intent `skill.chordvoicings`, which runs `ChordVoicingsSkill` ([`GaPlugin.cs` line 108](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs#L108)); a comment in GA calls it the chatbot's most used skill ([`ChordVoicingsSkill.cs` line 14](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordVoicingsSkill.cs#L14)). It calls no model. `TypedMusicalQueryExtractor` reads a chord, a mode and technique words from the question, `MusicalQueryEncoder` turns them into a query vector, and the OPTIC-K index of [lesson 3](../03-index-and-search/) returns the nearest voicings, filtered by the chord's name ([lines 75-167](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordVoicingsSkill.cs#L75-L167)).

All GA links point to commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), the course's pin, unless they name another. Most of the voicing pipeline changed on GA's `main` after the pin: between the pin and [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/commit/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) (2026-10-01), `git diff --stat` lists 17 changed files among the skill, `VoicingAgent`, `Search/`, `Embeddings/`, `VoicingDocumentFactory`, the voicing domain services and the CLI that writes the index. The code that reads the question didn't change: `TypedMusicalQueryExtractor.cs` is identical, and so are `ChordPitchClasses`, the skill's `CanHandle` and its two expressions. So the program reads at the pin, and asks for the answers twice: at the pin, and in a second program, `GaMain`, built from a second clone of GA at `f4f5b4a`. Both compile the same questions, from `code/ga-ai/Shared/ChordVoicingsProbe.cs`. The outputs come from:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l16
dotnet run --project code/ga-ai/GaMain -c Release -- l16
```

## Which prompts reach the skill

On `main`, when the router can't embed a question, it falls back on each skill's `CanHandle` ([`SemanticIntentRouter.cs` line 321](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Agents/Intents/SemanticIntentRouter.cs#L321), [`OrchestratorSkillIntent.cs` line 29](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.Core.Orchestration/Intents/OrchestratorSkillIntent.cs#L29)). `ChordVoicingsSkill.CanHandle` wants a voicing word and a chord ([lines 57-73](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordVoicingsSkill.cs#L57-L73)):

```csharp
    public bool CanHandle(string message)
    {
        if (string.IsNullOrWhiteSpace(message)) return false;
        var q = message.ToLowerInvariant();
        // Whole-word match so a keyword embedded in an unrelated word doesn't
        // fire (e.g. "shell" inside "PowerShell" — see ga#261).
        var hasVoicingIntent = VoicingKeywords.Any(k => ChordIntentMatching.ContainsWord(q, k));
        if (!hasVoicingIntent) return false;
        // Require a real chord token. The two regexes are case-sensitive on the
        // root so bare lowercase "a"/"e" in normal English ("show me a shape")
        // won't trigger. Strict form requires an accidental/quality/digit
        // immediately after the root (Cmaj7, G7, F#m); spaced form allows
        // "[A-G] major/minor/dim/aug/sus" with whitespace between root and
        // quality (Bb major, C minor).
        return ChordSuffixRegex().IsMatch(message)
               || ChordWithSpacedQualityRegex().IsMatch(message);
    }
```

A chord is a capital root followed by a suffix, or by a quality word after a space ([lines 178-185](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordVoicingsSkill.cs#L178-L185)):

```csharp
    [GeneratedRegex(@"\b[A-G][#b]?(?:maj|min|m|M|dim|aug|sus|add|alt|°|Δ|11|13|5|6|7|9)\w*\b")]
    private static partial Regex ChordSuffixRegex();

    // Spaced quality form: "C major", "Bb minor", "F# augmented". Quality word
    // accepts upper- and lower-case first letters but requires the root to be
    // an uppercase chord letter.
    [GeneratedRegex(@"\b[A-G][#b]?\s+(?:[Mm]ajor|[Mm]inor|[Mm]aj|[Mm]in|[Dd]im|[Aa]ug|[Ss]us)\b")]
    private static partial Regex ChordWithSpacedQualityRegex();
```

The program starts the chatbot's host as in lesson 15, takes the skill behind the intent and asks `CanHandle` each of its 12 example prompts ([lines 31-45](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordVoicingsSkill.cs#L31-L45)), then asks the host's extractor what it reads in them:

```text
== The skill's example prompts: CanHandle, and the chord TypedMusicalQueryExtractor reads
prompt                           CanHandle  chord read             also read
voicings for Cmaj7               yes        Cmaj7: C E G B         tags for
show me Dm7 voicings             yes        Dm7: C D F A
shapes for F major               yes        F: C F A               mode major, tags for
fingerings for G7                yes        G7: D F G B            tags for
Cmaj9 voicings                   yes        Cmaj9: C D E G B
drop2 voicings of Cmaj7          yes        Cmaj7: C E G B         tags drop2
shell voicing for Dm7            yes        Dm7: C D F A           tags shell for
rootless A7 voicings             yes        A7: C# E G A           tags rootless
quartal voicings in C            no         C: C E G               tags quartal
all C major voicings on guitar   yes        C: C E G               mode major, tags all, instrument guitar
open chord shape for E minor     yes        E: E G# B              mode minor, tags open for
barre voicings for Bb major      yes        Bb: D F A#             mode major, tags for
```

```text
== Other phrasings
prompt                           CanHandle  chord read             also read
voicings for C                   no         C: C E G               tags for
G chord shapes                   no         G: D G B
how do I play a D chord          no         D: D F# A
voicings for A minor             yes        A: C# E A              mode minor, tags for
voicings for Am                  yes        Am: C E A              tags for
voicings for am                  no         no chord               tags for
Bb voicings please               no         Bb: D F A#
voicings for F#m7b5              yes        F#m7b5: C E F# A       tags for
voicings for C7(b9)              yes        C7(b9): C C# E G A#    tags for
voicings for C/G                 no         C/G: C E G             tags for
```

- **`CanHandle` rejects one of its own examples, and every bare major chord.** "quartal voicings in C" has a voicing word, but a root alone isn't a chord for either expression. "voicings for C", "G chord shapes" and "Bb voicings please" are rejected the same way, and "voicings for C/G" too: `/` isn't a suffix. "how do I play a D chord" has no voicing word.
- **"minor" is read as a mode, and the chord as a major triad.** The extractor takes the first capitalized word that `ChordPitchClasses` parses as the chord ([`TypedMusicalQueryExtractor.cs` lines 90-102](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/TypedMusicalQueryExtractor.cs#L90-L102)); "A" parses as A major, and "minor" is in the list of modes ([lines 104-111](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/TypedMusicalQueryExtractor.cs#L104-L111)). "voicings for A minor" reads A major, and so does the example "open chord shape for E minor" for E. `CanHandle`'s comment gives "C minor" as a form it accepts.
- **A partial reading keeps the model away.** The host's extractor asks a model only when the typed reading finds nothing ([lines 217-226](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/TypedMusicalQueryExtractor.cs#L217-L226)). "voicings for am" reads no chord, and in production a model would get it, which the course doesn't run. "voicings for A minor" reads A major, so no model ever sees it.

## The symbols and the spelled-out qualities

`ChordPitchClasses` builds a chord from its suffix rather than looking it up. It folds the suffix's variants, takes its alterations, additions and omissions, then its triad and its extensions, and refuses a suffix that leaves something it can't explain ([`MusicalQueryEncoder.cs` lines 240-336](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/MusicalQueryEncoder.cs#L240-L336)):

```csharp
        // ── normalize symbol variants (case matters: 'M7' = major7, 'm' = minor) ──
        w = Regex.Replace(w, "△|Δ", "maj");
        w = Regex.Replace(w, "ø|Ø", "m7b5");
        w = Regex.Replace(w, @"M(?=7|9|11|13|6)", "maj");        // M7 / M9 / M13 → major-7th family
        w = w.Replace("Maj", "maj").Replace("MAJ", "maj").Replace("Major", "maj").Replace("major", "maj");
        w = w.Replace("Min", "min").Replace("MIN", "min").Replace("minor", "min");
        w = w.Replace("M", "maj");                                // any lone uppercase M ⇒ major
        // The major-7th marker is now canonical, so folding to lower case leaves a residual
        // 'm' meaning unambiguously minor.
        w = w.ToLowerInvariant();
        w = w.Replace("°", "dim").Replace("o7", "dim7");
```

```csharp
        // residue check: anything left (besides separators) means it was not a chord symbol.
        var residue = Regex.Replace(w, @"[\s/()+\-]", "");
        if (residue.Length > 0) return false;
```

The program asks for the 51 symbols of lesson 15 as "voicings for C…" and for the 31 spelled-out qualities as "voicings for C …", and compares the chord the extractor reads with a textbook's:

```text
== The 51 symbols of lesson 15, asked as "voicings for C…"
read as a textbook spells them: 47 of 51
  Cdom7: no chord, a textbook's C E G A#
  Cma7: no chord, a textbook's C E G B
  C-7: C-7: C E G A#, a textbook's C D# G A#
  C7+5: no chord, a textbook's C E G# A#
symbols ChordPitchClasses and ChordVocabulary read as different chords: 5: Cdom7 Cma7 CΔ7 C-7 C7+5
```

```text
== The 31 spelled-out qualities, asked as "voicings for C …"
CanHandle accepts 13 of 31; read as a textbook spells them: 1
  read as C: C E G: 31, major, minor, diminished, augmented, power, dominant, …
```

- **47 of the 51 symbols are read as a textbook spells them.** `dom7`, `ma7` and `7+5` leave letters or a digit the parser can't explain, and the question reads no chord. `C-7` is read as C7: the residue check takes `-` for a separator, so the minor sign is dropped and the seventh is a dominant one.
- **The chatbot has two readers of chord symbols, and they disagree on five of the 51.** `ChordVocabulary`, which `ChordInfoSkill` uses (lesson 15), maps `dom7` to a dominant seventh, `ma7` to a major seventh, `-7` to a minor seventh and `7+5` to a dominant seventh with a sharp fifth ([`ChordVocabulary.cs` lines 81-87](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/ChordVocabulary.cs#L81-L87)); `ChordPitchClasses` reads no chord for three of them and a dominant seventh for `-7`. The fifth, `CΔ7`, is the vocabulary's `δ7` of lesson 15.
- **Every spelled-out quality is read as C major.** The parser reads "C" alone, and the words after it become a mode, tags or nothing. Only "major" comes out right. `CanHandle` accepts 13 of the 31, those that start with "major" or "minor": in its spaced expression, `dim` and `aug` must end a word, and "diminished" and "augmented" go on.

## What the answers play, at the pin

The skill's answer lists each voicing with a name and a diagram. The program plays the diagram: each string that sounds gives its open note plus its fret, and the voicing's pitch classes are the set of those notes. It compares them with the chord the prompt asks for, as a textbook spells it: **exact** when the voicing plays those notes and no other, **more** when it plays them and others, **part** when it plays only some of them, **other** otherwise. At the pin, the diagram is GA's string, string 1, the high E, first (difference 13 of the [journal](../journal/)'s entry of 2026-09-14, fixed on `main`):

```text
== The example prompts' answers, at the pin: what each voicing plays
prompt                           voicings   exact  more   part   other
voicings for Cmaj7               2          2      0      0      0
show me Dm7 voicings             1          0      0      0      1
shapes for F major               8          8      0      0      0
fingerings for G7                8          1      0      7      0
Cmaj9 voicings                   8          0      0      8      0
drop2 voicings of Cmaj7          2          2      0      0      0
shell voicing for Dm7            1          0      0      0      1
rootless A7 voicings             5          0      0      5      0
quartal voicings in C            8          0      0      0      8
all C major voicings on guitar   8          2      0      3      3
open chord shape for E minor     8          0      0      0      8
barre voicings for Bb major      8          6      0      2      0
```

```text
== "show me Dm7 voicings": the answer, and what each voicing plays (asked: C D F A)
Found 1 voicing:
name             diagram          score    plays
Bm7(shell)/D     x-0-2-0-x-x      0.342    D A B            other
```

- **At the pin, Dm7 gets one voicing, and it isn't Dm7.** `Bm7(shell)/D` plays D, A and B. At the pin, the name filter looked for the quality as a substring of the stored name and took the lowest note for the root ([`OptickSearchStrategy.cs` lines 315-324](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/OptickSearchStrategy.cs#L315-L324)): `m7` is in `Bm7(shell)/D`, and its lowest note is D. That is difference 11 of the journal, fixed on `main`.

The program then asks for 144 chords, 12 qualities on 12 roots, as "voicings for <chord>". Lesson 3's corpus, GA's voicing generator on the first three frets, holds every chord of the grid; the program checks it, and stops if one is missing:

```text
== A grid of 144 chords, at the pin: "voicings for <chord>" on 12 roots
For each quality, the roots whose answer has only voicings that play the chord, some, or none;
the corpus holds every chord of the grid. Then what the voicings that aren't the chord play.
quality  all    some   none   the other voicings play
major    2      9      1      other 20, part 15
m        1      9      2      other 20, part 8
7        0      5      7      other 7, part 38
maj7     1      8      3      more 2, other 9, part 26
m7       0      6      6      other 12, part 26
dim      3      8      1      more 11, other 10, part 1
aug      8      4      0      more 1, other 2, part 1
sus4     2      5      5      more 2, other 12, part 34
m7b5     0      6      6      other 5, part 32
dim7     6      1      5      other 1, part 46
6        0      2      10     more 1, other 1, part 84
9        1      1      10     other 7, part 70
voicings returned: 841; exact 337, more 17, part 381, other 106
```

- **At the pin, 337 of 841 voicings play the chord asked, and for 56 of the 144 chords none does.** Most of the others play part of the chord (381), like the G7 shells without their fifth.

## The same questions on main

`GaMain` builds lesson 3's corpus and index with `main`'s generator, analysis, embedding and writer, and builds the skill as the host does ([`ServiceCollectionExtensions.cs` lines 78-111](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/GaChatbot.Api/Extensions/ServiceCollectionExtensions.cs#L78-L111), unchanged on `main`). On `main`, the skill writes its diagrams in chart order, low E first ([`ChordVoicingsSkill.cs` line 136](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Agents/Skills/ChordVoicingsSkill.cs#L136)):

```text
== Corpus on main: GA's VoicingGenerator, standard tuning, 3 frets, window 3, at least 3 notes
voicings                 15360
the names main's analysis gives the voicings of five chords, with their counts:
  C6, C E G A            Am7/G 24, Am7/E 17, Am7 6, Am7/C 2
  C6/9, C D E G A        C6/E 11, C6/G 11, C6 1, C6/A 1
  Dsus4, D G A           Gsus2 24, Gsus2/A 13, Gsus2/D 2
  Dbaug, Db F A          Faug 14, Faug/A 7
  Caug, C E G#           Caug/E 14, Caug 6, Caug/Ab 1
```

```text
== The example prompts' answers, on main: what each voicing plays
prompt                           voicings   exact  more   part   other
voicings for Cmaj7               8          8      0      0      0
show me Dm7 voicings             8          8      0      0      0
shapes for F major               8          8      0      0      0
fingerings for G7                8          8      0      0      0
Cmaj9 voicings                   8          8      0      0      0
drop2 voicings of Cmaj7          8          8      0      0      0
shell voicing for Dm7            8          8      0      0      0
rootless A7 voicings             8          8      0      0      0
quartal voicings in C            8          0      0      0      8
all C major voicings on guitar   8          8      0      0      0
open chord shape for E minor     8          0      0      0      8
barre voicings for Bb major      8          8      0      0      0
```

```text
== A grid of 144 chords, on main: "voicings for <chord>" on 12 roots
For each quality, the roots whose answer has only voicings that play the chord, some, or none;
the corpus holds every chord of the grid. Then what the voicings that aren't the chord play.
quality  all    some   none   the other voicings play
major    10     2      0      more 4
m        10     2      0      more 3
7        12     0      0
maj7     10     2      0      more 2
m7       10     2      0      part 2
dim      10     2      0      more 6
aug      4      0      8      more 61
sus4     3      3      6      more 57, part 1
m7b5     11     1      0      more 1
dim7     12     0      0
6        0      0      12     more 74
9        8      4      0      more 7
voicings returned: 1097; exact 879, more 215, part 3, other 0
```

- **On `main`, every voicing the skill returns plays the chord it read.** 10 of the 12 examples get 8 voicings of their chord; the two others get the chord misread, E major for "E minor" and C major for "quartal voicings in C". On the grid, 879 of 1,097 voicings play the chord exactly, none plays another chord (other 0), and the rest play the chord and more (215) or part of it (3).
- **The 6th chords, eight augmented and six sus4 triads get no voicing of their own, though the corpus holds them all.** The index names C E G A "Am7", never "C6", and names the 6/9 C D E G A "C6": "voicings for C6" gets 6/9 voicings named C6. It names D G A "Gsus2" and D♭ F A "Faug". The name filter compares the root and the quality of the stored name with the request's ([`OptickSearchStrategy.cs` lines 307-319](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Search/OptickSearchStrategy.cs#L307-L319)), and cuts the stored name at its first parenthesis ([lines 348-349](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Search/OptickSearchStrategy.cs#L348-L349)), so `Dbaug(maj7)/C`, D♭ F A plus C, passes as D♭ augmented. When no stored name passes, the skill searches again without the filter ([lines 109-115](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Agents/Skills/ChordVoicingsSkill.cs#L109-L115)), and the nearest voicings to Dsus4 are D7sus4.

```csharp
        var filterChord = filters.ChordName is { Length: > 0 } cn ? ParseChordName(cn) : null;

        foreach (var r in pool)
        {
            var d = r.Document;
            if (filterChord is { } fc)
            {
                if (ParseChordName(d.ChordName) is not { } docChord) continue;
                if (docChord.RootPitchClass != fc.RootPitchClass) continue;
                if (!string.Equals(docChord.Quality, fc.Quality, StringComparison.Ordinal)) continue;
                if (fc.BassPitchClass is int bass
                    && (d.MidiNotes.Length == 0 || ((d.MidiNotes.Min() % 12) + 12) % 12 != bass)) continue;
            }
```

## The techniques

Six of the 12 example prompts name a technique, and the skill's description promises them: "drop2, shell, rootless, quartal, barre" ([lines 24-29](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordVoicingsSkill.cs#L24-L29)). The program checks each voicing of `main`'s answers with the course's definitions, all read from the diagram:

- **drop2**: four notes on four strings, the chord's four notes, and raising the lowest by an octave gives a close position in which it is the second note from the top;
- **shell**: the root, the third and the seventh, nothing else;
- **rootless**: at least three chord tones, without the root;
- **quartal**: at least three notes stacked in perfect fourths from the root; "quartal voicings in C" is taken as C F B♭;
- **open**: the chord with at least one open string;
- **barre**: the chord with no open string, and the same fret on the lowest and the highest strings that sound.

The table counts the voicings that play the chord, those that are the technique, and the corpus voicings that are the technique:

```text
== The techniques the example prompts name, on main
prompt                           voicings   chord    technique  in the corpus
drop2 voicings of Cmaj7          8          8        2          3
shell voicing for Dm7            8          8        0          19
rootless A7 voicings             8          8        0          45
quartal voicings in C            8          0        0          1
open chord shape for E minor     8          0        0          60
barre voicings for Bb major      8          8        3          11
```

```text
== "open chord shape for E minor": the answer, and what each voicing plays (asked: E G B)
Found 8 voicings:
name             diagram          score    plays
E/B              x-2-x-1-x-0      0.635    E G# B           other
E                0-x-x-1-0-x      0.635    E G# B           other
E                0-2-x-1-x-x      0.635    E G# B           other
E                0-2-x-1-x-0      0.635    E G# B           other
E                0-2-x-1-0-0      0.635    E G# B           other
E/Ab             x-x-x-1-0-0      0.632    E G# B           other
E                x-x-2-1-0-x      0.632    E G# B           other
E                x-x-2-1-0-0      0.632    E G# B           other
```

- **5 of the 48 voicings are the technique asked,** 2 drop2 and 3 barre voicings; none is a shell, a rootless A7, a quartal voicing or an open E minor, though the corpus holds 19, 45, 1 and 60 of them.
- **GA drops the techniques on purpose, and tells its telemetry, not the guitarist.** Its decision record ADR-0002 explains that the index carries only the diagram, the inferred name, the instrument and the MIDI notes, so the index path honours the chord name, the pitch range, the instrument and the comfort filters, and declares the others dropped, `Tags` and `ModeName` among them ([`OptickSearchStrategy.cs` lines 101-130](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Search/OptickSearchStrategy.cs#L101-L130), [`0002-voicing-filter-parity-cpu-gpu-only.md`](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/docs/adr/0002-voicing-filter-parity-cpu-gpu-only.md)). `VoicingAgent` writes the dropped filters to its telemetry log ([`VoicingAgent.cs` lines 110-126](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Agents/VoicingAgent.cs#L110-L126)); `ChordVoicingsSkill` records nothing, and its answer starts "Found 8 voicings:".
- **The six techniques can be read from the diagram and the tuning,** as the course does here. ADR-0002 applies the comfort filters on the index path for that reason: every strategy carries the diagram.

## Where the course stops

- **The corpus is lesson 3's,** 15,360 voicings on three frets, not the production index. Among more voicings, the nearest ones may differ (*to verify*).
- **The router and the model aren't run.** Which intent the router picks for these prompts, and what a model reads in "voicings for am", need the embeddings and the model (*to verify*).
- **The definitions of the techniques are the course's,** and so is the reading of "quartal voicings in C".
- **`GaMain` builds the skill as the host does, without the host.** The host's wiring is unchanged on `main`; that it builds the same objects comes from reading it.

## Reported upstream

- Not reported upstream when this lesson was written: "minor" and the spelled-out qualities read as a major triad, `CanHandle`'s bare chords, `ChordPitchClasses`'s four symbols, the index's names that the filter can't find, and the techniques dropped without a word in the answer. All are listed in the [journal](../journal/).

## Exercises

1. Ask `main`'s skill "voicings for Am", then "voicings for A minor". Which chord do the voicings of each answer play?
2. How many of the grid's 144 prompts does `CanHandle` accept, and which does it reject?
3. What does `CanHandle` answer to "voicings for C-7"? What would `main`'s skill answer if the router sent it the question anyway?
4. On `main`, for which four of the 12 roots does "voicings for <root>aug" get only augmented triads? Why four?

<details>
<summary>Solutions</summary>

1. "voicings for Am" gets eight voicings of A minor, A C E; "voicings for A minor" gets eight voicings of A major, A C♯ E. The first is read as the symbol `Am`, the second as the chord `A` and the mode `minor`, which the index drops. Checked by running `GaMain`'s skill outside the course's expected output.
2. 132: it rejects the 12 bare major chords, "voicings for C" to "voicings for B", whose root has neither a suffix nor a quality word. Checked by running `CanHandle` on the 144 prompts, outside the course's expected output.
3. It rejects it: after the root, `-` matches neither expression. Asked directly, `main`'s skill reads C7 and answers eight voicings of C E G B♭. Checked by running `GaMain`'s skill outside the course's expected output.
4. C, D, F and G. An augmented triad divides the octave into three major thirds, so the same three notes have three names, and the index stores one of them: Caug for C E G♯, Daug for D F♯ A♯, Faug for D♭ F A and Gaug for E♭ G B. The filter accepts only the stored name. The eight other roots get augmented triads with a major seventh, whose name the filter cuts at its parenthesis. Checked by running `GaMain`'s skill outside the course's expected output.

</details>

## Key takeaways

- A voicing can be checked without a textbook: the diagram and the tuning give its notes.
- On `main`, every voicing the skill returns plays the chord it read; what remains wrong is in the reading and in the names.
- A partial reading keeps the fallback away: the typed reader takes "A" from "A minor", and the model never sees the question.
- A filter on names needs one name per chord: C6 and Am7, Dsus4 and Gsus2, and each augmented triad are one set of notes with several names.
- A filter that is dropped should reach the answer, not only the telemetry.

## Sources

- GuitarAlchemist/ga at [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `Common/GA.Business.ML/Agents/Skills/ChordVoicingsSkill.cs`, `Common/GA.Business.ML/Search/TypedMusicalQueryExtractor.cs`, `Common/GA.Business.ML/Search/MusicalQueryEncoder.cs` (`ChordPitchClasses`), `Common/GA.Business.ML/Agents/ChordVocabulary.cs`, `Apps/GaChatbot.Api/Extensions/ServiceCollectionExtensions.cs`, `Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs`.
- GuitarAlchemist/ga at [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/tree/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a): the same skill and extractor, `Common/GA.Business.ML/Search/OptickSearchStrategy.cs`, `Common/GA.Business.ML/Agents/Intents/SemanticIntentRouter.cs`, `Common/GA.Business.Core.Orchestration/Intents/OrchestratorSkillIntent.cs`, `docs/adr/0002-voicing-filter-parity-cpu-gpu-only.md`.
- The course's programs: `code/ga-ai/GaAi/Lesson16.cs`, `code/ga-ai/GaMain/Program.cs`, `code/ga-ai/Shared/ChordVoicingsProbe.cs`, `code/ga-ai/fetch-ga.sh`.
