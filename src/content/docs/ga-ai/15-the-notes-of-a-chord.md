---
title: "Lesson 15: The notes of a chord"
description: "Guitar Alchemist's chatbot spells the notes of a chord without a model, and names the chord a list of notes makes. The course asks its skill the 32 example prompts, the 82 suffixes of its vocabulary, 588 chords on 21 roots, and each of those chords back as a list of notes. The spelling is a textbook's for every chord but the altered dominant. The reading decides the rest: the article a is read as the root A, three example prompts and 22 suffixes aren't read, a symbol read in part gets the notes of a smaller chord, and none of the 106 spellings with a double or triple accidental is named back. The MCP tool of the SKILL.md path reads 14 of the 51 symbols."
sidebar:
  label: 15. The notes of a chord
  order: 15
---

[Lesson 14](../14-what-the-substitution-skill-answers/) asked the chatbot for a chord to put in place of another. This lesson asks the most basic question a guitarist puts to it: which notes are in a chord, and which chord a set of notes makes. The router sends both to the intent `skill.chordinfo`, which runs `ChordInfoSkill` ([`GaPlugin.cs` line 36](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs#L36)). The skill calls no model: it reads a chord symbol and spells its notes from a formula, or reads a list of notes and looks for a formula that fits. For the model path, the SKILL.md [`chord-info`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/chord-info/SKILL.md) gives the model one MCP tool, `ga_chord_info`, and tells it never to spell a chord from memory ([`SKILL.md` line 43](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/chord-info/SKILL.md#L43)); GA's plugin registers the tool ([`GaPlugin.cs` line 195](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs#L195)). The skill and the tool share two files: `ChordVocabulary`, which maps a suffix to a quality and a quality to its formula, and `ChordSpelling`, which puts each note on its letter.

All GA links point to commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), the course's pin, unless they name another. On `main` at [`5c3a52a`](https://github.com/GuitarAlchemist/ga/commit/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26) (2026-09-30), `ChordInfoSkill.cs`, `ChordVocabulary.cs`, `ChordSpelling.cs`, `ChordMcpTools.cs` and the SKILL.md are unchanged. The outputs come from:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l15
```

## The skill's own example prompts

The program starts the chatbot's host as in lesson 12, takes the intent the router would choose and asks it each of its 32 example prompts ([`ChordInfoSkill.cs` lines 29-98](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordInfoSkill.cs#L29-L98)). The skill tries two ways of reading a chord name, then a list of notes, and gives up when all three fail ([lines 114-118](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordInfoSkill.cs#L114-L118), [lines 154-169](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordInfoSkill.cs#L154-L169)):

```csharp
    private static (string Root, string Quality)? TryParse(string message)
    {
        var chordQuestion = ChordQuestionRegex().Match(message);
        if (chordQuestion.Success)
        {
            return (ChordVocabulary.NormalizeRoot(chordQuestion.Groups["root"].Value), ChordVocabulary.NormalizeQuality(chordQuestion.Groups["quality"].Value));
        }

        var compact = CompactChordRegex().Match(message);
        if (compact.Success)
        {
            return (ChordVocabulary.NormalizeRoot(compact.Groups["root"].Value), ChordVocabulary.NormalizeQuality(compact.Groups["quality"].Value));
        }

        return null;
    }
```

The program reads what the skill understood from the lines of its evidence, `Root:`, `Quality:` and `Notes:`, and compares the notes with the ones a textbook spells for each prompt:

```text
== The skill's own example prompts
skill.chordinfo: ChordInfoSkill, 32 example prompts
"What is a C major chord?"  CanHandle yes
  C major: C E G
"What notes are in Dm7?"  CanHandle yes
  D minor 7: D F A C
"Notes in an F minor chord"  CanHandle yes
  F minor: F Ab C
"What chord contains C E G?"  CanHandle yes
  C major: C E G
"Spell a B7 chord"  CanHandle yes
  B dominant 7: B D# F# A
"What notes are in a Cmaj7?"  CanHandle yes
  C major 7: C E G B
"Tell me the tones in F#m7b5"  CanHandle no
  F# half-diminished: F# A C E
"tell me about Dm7"  CanHandle yes
  D minor 7: D F A C
"tell me about a Cmaj7 chord"  CanHandle yes
  C major 7: C E G B
"what makes a chord a major seventh"  CanHandle yes
  A major: A C# E
  the question names a quality, no root
"what makes a chord diminished"  CanHandle yes
  A major: A C# E
  the question names a quality, no root
"what makes a chord a dominant seventh"  CanHandle yes
  A major: A C# E
  the question names a quality, no root
"What chord is C E G"  CanHandle yes
  C major: C E G
"What chord is F A C E"  CanHandle yes
  F major 7: F A C E
"Which chord contains the notes G B D F"  CanHandle yes
  G dominant 7: G B D F
"What chord is C E G Bb D"  CanHandle yes
  C dominant 9: C E G Bb D
"anatomy of a D7sus4 chord"  CanHandle no
  no chord: "Could not parse a chord name from your question."
  the textbook: D G A C
"break down Gmaj13 for me"  CanHandle no
  G major 13: G B D F# A C E
"what is a C add 9 chord"  CanHandle no
  no chord: "Could not parse a chord name from your question."
  the textbook: C E G D
"give me the notes of an F#m7b5"  CanHandle yes
  F# half-diminished: F# A C E
"tones in a Bb diminished seventh"  CanHandle no
  no chord: "Could not parse a chord name from your question."
  the textbook: Bb Db Fb Abb
"What is C7b9"  CanHandle yes
  C dominant 7 flat 9: C E G Bb Db
"What is Cmaj9"  CanHandle yes
  C major 9: C E G B D
"What is Dm7b5"  CanHandle yes
  D half-diminished: D F Ab C
"What is F#m7"  CanHandle yes
  F# minor 7: F# A C# E
"What is Bbdim7"  CanHandle yes
  Bb diminished 7: Bb Db Fb Abb
"what notes are in a C major triad"  CanHandle yes
  C major: C E G
"what are the notes of an A minor triad"  CanHandle yes
  A minor: A C E
"what notes make up a G7 chord"  CanHandle yes
  G dominant 7: G B D F
"which notes form a B diminished triad"  CanHandle yes
  B diminished: B D F
"spell a G7 chord"  CanHandle yes
  G dominant 7: G B D F
"what notes are in an E major chord"  CanHandle yes
  E major: E G# B
The intent's answer is the skill's Result for 32 of 32
The textbook's notes for 26 of the 29 prompts that name a chord or its notes
CanHandle accepts 27 of 32
```

- **Three questions about a quality get A major.** "what makes a chord diminished" is answered "A major chord contains A, C#, and E", and so are the two other "what makes a chord" prompts. The first regular expression looks for a root, an optional quality and the word "chord" ([lines 302-303](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordInfoSkill.cs#L302-L303)); its root class `[A-Ga-g]` takes the article "a", and "a chord" is the first match in the sentence:

```csharp
    [GeneratedRegex(@"\b(?<root>[A-Ga-g][#b]?)\s*(?<quality>major 13|minor 13|dominant 13|major 11|minor 11|dominant 11|major 9|minor 9|dominant 9|major 7|minor 7|dominant 7|major 6|minor 6|half[- ]diminished|altered dominant|major|minor|maj|min|diminished|dim|augmented|aug|sus[24]?|add9|7alt|alt|13|11|9|7|6)?\s*(?:chord|triad)\b", RegexOptions.CultureInvariant)]
    private static partial Regex ChordQuestionRegex();
```

The second expression met the same article, and its comment says how it was fixed: its quality became required ([lines 310-314](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordInfoSkill.cs#L310-L314)). The first one kept its optional quality.

- **Three prompts aren't read.** "anatomy of a D7sus4 chord": the symbol expression has no `7sus4`, and after `7` it asks for a word boundary, which the `s` of `sus4` doesn't give. "what is a C add 9 chord": the symbol expression has `add9`, without a space. "tones in a Bb diminished seventh": no "chord" or "triad" for the first expression, no symbol for the second. The answer is "Could not parse a chord name from your question."
- **The 26 others are right,** B7's D♯ and B♭dim7's F♭ and A♭♭ included.
- **`CanHandle` accepts 27 of 32.** It accepts a symbol only next to the words "chord", "triad" or "note", or after a lead-in such as "what is" or "tell me about" ([lines 100-110](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordInfoSkill.cs#L100-L110), [lines 267-282](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordInfoSkill.cs#L267-L282)). Besides the three prompts the skill can't read, it rejects "Tell me the tones in F#m7b5" and "break down Gmaj13 for me", which the skill answers right. At the pin, the router doesn't call `CanHandle`; on `main`, it falls back on it when it can't embed the question ([`SemanticIntentRouter.cs` line 321 on `main`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Common/GA.Business.ML/Agents/Intents/SemanticIntentRouter.cs#L321)).

## Every suffix the vocabulary knows

`ChordVocabulary.NormalizeQuality` maps 83 spellings of a suffix, the empty one included, to the qualities of `GetFormula` ([`ChordVocabulary.cs` lines 59-104](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/ChordVocabulary.cs#L59-L104)). Its doc comment explains the two capital arms: `M` is major and must not be lowercased into `m`, minor:

```csharp
    /// <summary>
    ///     Normalises a quality suffix to its canonical form (the key <see cref="GetFormula"/> switches on).
    /// </summary>
    /// <remarks>
    ///     The uppercase <c>"M"</c> / <c>"M7"</c> arms are matched <b>case-sensitively before</b> the
    ///     lowercase fallback: <c>"M"</c> means major and must not fold through <c>ToLowerInvariant()</c>
    ///     to <c>"m"</c> (minor). This is the PR #80 fix; consolidating it here keeps the skill from
    ///     re-introducing the <c>"CM"</c> → C-minor regression.
    /// </remarks>
    public static string NormalizeQuality(string raw)
    {
        var trimmed = raw.Trim();
        return trimmed switch
        {
            "M"  => "major",
            "M7" => "major 7",
            _    => trimmed.ToLowerInvariant() switch
            {
                "" => "major",
```

The program asks the skill for each of the 82 other suffixes, the 51 symbols as "What notes are in C…?", the 31 words as "What notes are in a C … chord?", and prints the ones it doesn't read as the vocabulary does:

```text
== Every suffix the vocabulary knows
"What notes are in C+?"  the vocabulary: augmented, the skill: no chord
"What notes are in C5?"  the vocabulary: power, the skill: no chord
"What notes are in Cno3?"  the vocabulary: power, the skill: no chord
"What notes are in Cdom7?"  the vocabulary: dominant 7, the skill: no chord
"What notes are in Cma7?"  the vocabulary: major 7, the skill: no chord
"What notes are in CΔ7?"  the vocabulary: major, the skill: no chord
"What notes are in C-7?"  the vocabulary: minor 7, the skill: no chord
"What notes are in C°7?"  the vocabulary: diminished 7, the skill: no chord
"What notes are in Cmin7b5?"  the vocabulary: half-diminished, the skill: no chord
"What notes are in Cø?"  the vocabulary: half-diminished, the skill: no chord
"What notes are in Cø7?"  the vocabulary: half-diminished, the skill: no chord
"What notes are in C7+5?"  the vocabulary: dominant 7 sharp 5, the skill: dominant 7
"What notes are in a C power chord?"  the vocabulary: power, the skill: no chord
"What notes are in a C dominant chord?"  the vocabulary: dominant 7, the skill: no chord
"What notes are in a C diminished 7 chord?"  the vocabulary: diminished 7, the skill: no chord
"What notes are in a C diminished7 chord?"  the vocabulary: diminished 7, the skill: no chord
"What notes are in a C minor 7 flat 5 chord?"  the vocabulary: half-diminished, the skill: no chord
"What notes are in a C dominant 7 flat 5 chord?"  the vocabulary: dominant 7 flat 5, the skill: no chord
"What notes are in a C dominant 7 sharp 5 chord?"  the vocabulary: dominant 7 sharp 5, the skill: no chord
"What notes are in a C dominant 7 flat 9 chord?"  the vocabulary: dominant 7 flat 9, the skill: no chord
"What notes are in a C dominant 7 sharp 9 chord?"  the vocabulary: dominant 7 sharp 9, the skill: no chord
"What notes are in a C altered chord?"  the vocabulary: altered dominant, the skill: no chord
The skill reads 60 of 82 suffixes as the vocabulary does (51 symbols, 31 words)
NormalizeQuality("Δ7") returns "δ7", which GetFormula doesn't know
ga_chord_info reads 14 of the 51 symbols: M M7 maj m min dim aug 7 maj7 m7 min7 dim7 m7b5 min7b5
```

- **22 of 82 aren't read, or are read as another quality.** The symbol expression, which ignores case, has no `5`, `no3`, `dom7`, `ma7`, `-7`, `°7`, `ø`, `ø7` or `min7b5` ([lines 305-316](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordInfoSkill.cs#L305-L316)); the vocabulary maps them, and the skill never hands them over. Its comment lists `+` and "power 5/no3" among the forms it supports. `+` is in the alternation, but the `\b` after it needs a word character on one side, and in the question `+` is followed by a question mark. The power formula can't be reached at all, as "C5" or as "a C power chord". The spelled-out forms stop at the first expression's list, which lacks, among others, "power", "diminished 7", "dominant 7 flat 5", and "dominant" or "altered" on their own. `7+5` is read as a dominant 7th, for the reason given in the next section.
- **The vocabulary's `Δ7` can't match.** `NormalizeQuality` lowercases the suffix before its second switch, and `ToLowerInvariant` lowercases Greek letters too: the capital delta of `Δ7` becomes `δ`, and no arm is written `δ7`. The suffix falls through unchanged, and `GetFormula` gives an unknown quality a major triad ([line 140](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/ChordVocabulary.cs#L140)). Neither expression reads `Δ`, so the chatbot doesn't get that far.

```csharp
                // 7th family
                "7" or "dominant" or "dom7" or "dominant 7" => "dominant 7",
                "maj7" or "major 7" or "ma7" or "Δ7" => "major 7",
                "m7" or "min7" or "minor 7" or "-7" => "minor 7",
```

- **`ga_chord_info` reads 14 of the 51 symbols,** the last line shows; the section on the tool comes back to them.

## Beyond the vocabulary

The program asks for symbols the vocabulary has no entry for, a slash chord, the flat sign `♭`, and two sentences a guitarist might type:

```text
== Beyond the vocabulary
"What notes are in Cmaj7#11?"
  C major 7: C E G B
  the textbook: C E G B F#
"What notes are in C7#11?"
  C dominant 7: C E G Bb
  the textbook: C E G Bb F#
"What notes are in C7(b9)?"
  C dominant 7: C E G Bb
  the textbook: C E G Bb Db
"What notes are in Cm(maj7)?"
  C minor: C Eb G
  the textbook: C Eb G B
"What notes are in C6/9?"
  C major 6: C E G A
  the textbook: C E G A D
"What notes are in C7#5#9?"
  C dominant 7 sharp 5: C E G# Bb
  the textbook: C E G# Bb D#
"What notes are in C7sus4?"
  no chord: "Could not parse a chord name from your question."
  the textbook: C F G Bb
"What notes are in C/E?"
  no chord: "Could not parse a chord name from your question."
  the textbook: C E G
"What notes are in B♭7?"
  no chord: "Could not parse a chord name from your question."
  the textbook: Bb D F Ab
"What notes are in an E♭ major chord?"
  no chord: "Could not parse a chord name from your question."
  the textbook: Eb G Bb
"I am learning Cmaj7, what notes are in it?"
  A minor: A C E
  the textbook: C E G B
"Am I right that G7 has an F?"
  A minor: A C E
  the textbook: G B D F
```

- **Six symbols get the notes of a smaller chord.** After the suffix, the symbol expression asks for a word boundary and no letter ([line 315](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordInfoSkill.cs#L315)): `#`, `(`, `/` and `+` pass both. Cmaj7♯11 is answered as Cmaj7, C7(♭9) as C7, Cm(maj7) as Cm, C6/9 as C6, and nothing in the answer says a part was dropped. The improvisation skill of lesson 5 read Cmaj7♯5 as Cmaj7 the same way (row 23 of the [journal](../journal/)).
- **C7sus4, C/E and the flat sign aren't read**, and the answer says so. `♭` isn't the letter `b`.
- **"I am" and "Am I" are A minor.** The symbol expression ignores case, so "am" is the root A with the suffix `m`, and it comes before Cmaj7 or G7 in the sentence.

## Spelling: 21 roots, 28 qualities

The skill puts each note on a letter: the formula gives each note its number of letters above the root, and `ChordSpelling.Spell` adds the accidentals that reach the note's pitch ([`ChordSpelling.cs` lines 52-69](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Mcp/ChordSpelling.cs#L52-L69)):

```csharp
    public static string Spell(string root, int pitchClass, int letterSteps)
    {
        var rootLetter   = char.ToUpperInvariant(root[0]);
        var rootIndex    = Array.IndexOf(NaturalLetters, rootLetter);
        var targetLetter = NaturalLetters[(rootIndex + letterSteps) % NaturalLetters.Length];
        var targetNatural = NaturalPitchClasses[targetLetter];
        var normalized   = ((pitchClass % 12) + 12) % 12;
        var accidental   = ((normalized - targetNatural) % 12 + 12) % 12;

        return accidental switch
        {
            0  => targetLetter.ToString(),
            1  => $"{targetLetter}#",
            2  => $"{targetLetter}##",
            10 => $"{targetLetter}bb",
            11 => $"{targetLetter}b",
            _  => $"{targetLetter}{(accidental < 6 ? new string('#', accidental) : new string('b', 12 - accidental))}",
        };
```

The program spells the same chords its own way, from degrees written in `Lesson15.cs`: a 3 is two letters and four semitones above the root, a ♭3 the same letter a semitone lower. It asks the skill for the 28 qualities it can read on the 21 roots of the vocabulary, C to B with B♯, C♭, E♯ and F♭:

```text
== Spelling: 21 roots, 28 qualities
The skill spells 567 of 588 chords as the textbook does
  C7alt: skill C E F# G# Bb Db D#, textbook C E Gb G# Bb Db D#
  C#7alt: skill C# E# F## G## B D D##, textbook C# E# G G## B D D##
  Db7alt: skill Db F G A Cb Ebb E, textbook Db F Abb A Cb Ebb E
  … and 18 more
The chords that differ: 21 7alt
C7alt: Intervals: root, major third, flat fifth, sharp fifth, minor seventh, flat ninth, sharp ninth
Chords with a double or triple accidental: 175 of 588
```

- **567 of 588 agree.** The 21 others are the altered dominant, on every root. Its formula puts the flat fifth on the fourth's letter, three letters above the root instead of four ([`ChordVocabulary.cs` line 130](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/ChordVocabulary.cs#L130)): F♯ for C, where the flat fifth of C is G♭. F♯ is a usual spelling of an altered chord's ♯11, but the skill's evidence calls the note "flat fifth".
- **175 spellings have a double or triple accidental,** B♭dim7's A♭♭ or B♯ augmented's F♯♯♯. They are right, and the next section gives them back to the skill.

## The skill's own spellings, asked back as notes

A question where "what chord" or "which chord" is followed by "is", "contains", "has" or "uses" goes to the third reading ([line 322](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordInfoSkill.cs#L322)). The skill collects every note name in the question, keeps 3 to 5 distinct ones, and tries each as a root against 19 formulas ([lines 171-223](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordInfoSkill.cs#L171-L223), [lines 236-265](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordInfoSkill.cs#L236-L265)). A note name is a letter, one optional accidental, and no letter after it:

```csharp
    [GeneratedRegex(@"(?<![A-Za-z])(?<note>[A-Ga-g][#b]?)(?![A-Za-z])", RegexOptions.CultureInvariant)]
    private static partial Regex NoteTokenRegex();
```

The program reads the list of 19 formulas from the skill by reflection, then asks "What chord is …" with the notes the skill spelled for each of the 588 chords. A round trip needs no oracle: a skill that spells a chord should name it from its own spelling. The last lines ask six lists of notes of its own:

```text
== The skill's own spellings, asked back as notes
It names 19 qualities from notes; not dominant 7 flat 9, dominant 7 sharp 9, altered dominant, dominant 11, major 11, minor 11, dominant 13, major 13, minor 13
a quality it names, single accidentals: 293 chords, named back 293, as another chord 0, not named 0
a quality it names, a double or triple accidental: 106 chords, named back 0, as another chord 58, not named 48
  "What chord is D# F## A#" → D# minor: D# F# A#
a quality it doesn't name, 3 to 5 notes: 42 chords, named back 0, as another chord 12, not named 30
  "What chord is C E G Bb Db" → no chord: "Could not parse a chord name from your question."
6 or 7 notes: 147 chords, named back 0, as another chord 3, not named 144
  "What chord is C E F# G# Bb Db D#" → no chord: "Could not parse a chord name from your question."
```

```text
== Lists of notes
"What chord is C E G# B" → no chord: "Could not parse a chord name from your question."
"What chord is C E G Bb Db" → no chord: "Could not parse a chord name from your question."
"What chord is C Eb Gb Bbb" → C diminished: C Eb Gb
"What chord is F# A# C##" → F# major: F# A# C#
"Which chord has a C, an E and a G?" → A minor 7: A C E G
"What chord is C E G B♭" → C major 7: C E G B
```

- **Single accidentals: all 293 named back.** Every chord of the 19 formulas spelled without a double accidental comes back as itself.
- **Double accidentals: none of 106.** The note expression takes one accidental and refuses a letter after it: `Bbb` is dropped, since a `b` follows `Bb`, and `C##` is read as C♯, since `#` isn't a letter. "C Eb Gb Bbb", the spelling of Cdim7 that the skill and the tool's description both give, is named C diminished; F♯ augmented is named F♯ major. The flat sign is dropped the same way: C E G B♭ is C major 7, the misreading of [#757](https://github.com/GuitarAlchemist/ga/issues/757).
- **7b9 and 7#9 aren't among the 19.** They have five notes, within the limit, but "What chord is C E G Bb Db" gets the refusal although "What is C7b9" spells exactly those notes, and GA's prompt corpus asks both kinds of question ([`prompts.yaml` lines 462-468](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Tests/Apps/GaChatbot.Api.Tests/Corpus/prompts.yaml#L462-L468), [lines 542-548](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Tests/Apps/GaChatbot.Api.Tests/Corpus/prompts.yaml#L542-L548)). "What chord is C E G# B" is the example the list's own comment gives for "7-with-altered-fifth" ([lines 261-262](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordInfoSkill.cs#L261-L262)); it's Cmaj7♯5, and the list has only the dominant 7th with a raised or lowered fifth.
- **Six and seven notes are refused by design:** the comment gives the reason, an 11th or 13th chord has several names ([lines 184-189](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordInfoSkill.cs#L184-L189)).
- **"Which chord has a C, an E and a G?" is A minor 7:** the note expression reads the article "a".

## ga_chord_info, the tool of the SKILL.md

The tool reads a symbol with its own expression, anchored and shorter than the skill's ([`ChordMcpTools.cs` lines 77-82](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Mcp/ChordMcpTools.cs#L77-L82)):

```csharp
    // Order matters in the alternation: longer prefixes first so `dim7` is
    // tried before `dim` and `m7b5` before `m7`. Without this ordering, input
    // "Cdim7" matches `dim` and leaves "7" unconsumed, failing the ^...$ anchor
    // and the whole regex. Same for "Cm7b5" → matches `m` and fails on "7b5".
    [GeneratedRegex(@"^(?<root>[A-Ga-g][#b]?)(?<quality>maj7|min7b5|min7|m7b5|m7|maj|min|m|dim7|dim|aug|7|M7|M)?$",
        RegexOptions.CultureInvariant)]
```

The program asks it the symbols of the SKILL.md's table of suffixes ([`SKILL.md` lines 60-72](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/chord-info/SKILL.md#L60-L72)) and the five examples of its own description:

```text
== ga_chord_info, the tool of the SKILL.md
The SKILL.md's table lists 16 symbols, the tool reads 15
  Cdom7: "Could not parse 'Cdom7' as a chord symbol. Try C, Cm, Cmaj7, F#dim, Bbm7, etc."
The tool returns the notes its description gives for 5 of its 5 examples
```

- **The table lists `Cdom7`,** and the tool refuses it: its expression has no `dom7`.
- **14 of the vocabulary's 51 symbols,** the section on the vocabulary showed: triads, 7ths, `dim7` and `m7b5`. The SKILL.md says so: suspended and added-note chords, 9ths, 11ths, 13ths, slash chords and altered dominants return an error, and the model must decline ([lines 95-102](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/chord-info/SKILL.md#L95-L102)); it must decline a list of notes too, since no tool reads one. The same chatbot spells Cmaj9 on the skill's path, and its SKILL.md tells the model to decline it.
- **Where the tool reads, it's right:** its five examples come back as its description gives them.

## Where the course stops

- **The model isn't run.** Whether the semantic router sends each of these questions to `skill.chordinfo`, "I am learning Cmaj7" among them, needs the embeddings, and what a model writes from `ga_chord_info` needs the model (*to verify*).
- **The textbook spellings are the course's,** from degrees; for the altered dominant, a ♯11 spelling is also in use.
- **The skill and the tool aren't run on `main`.** Their files are unchanged there; that they answer the same on `main` comes from reading the diff.

## Reported upstream

- Reported after this lesson was written: GA issue [#782](https://github.com/GuitarAlchemist/ga/issues/782) for the article and "am" read as roots, the example prompts and suffixes the skill doesn't read, the symbols read in part, and the double accidentals and the formulas missing from the reading of notes; [#783](https://github.com/GuitarAlchemist/ga/issues/783) for the altered dominant's flat fifth, the vocabulary's `Δ7`, and the tool that reads 14 symbols. B♭ read as B is the same as [#757](https://github.com/GuitarAlchemist/ga/issues/757). All are listed in the [journal](../journal/).

## Exercises

1. Make the root class of the first expression `[A-G]`. Which of the 32 example prompts change, and what do they answer then?
2. Spell B♯ augmented as the skill does, then say what it answers to "What chord is" followed by that spelling.
3. Add `7sus4` to the symbol expression's alternation and change nothing else. What does "anatomy of a D7sus4 chord" answer then?
4. Let the note expression take two accidentals, `bb` or `##`. Why is "C Eb Gb Bbb" still not named C diminished 7th?

<details>
<summary>Solutions</summary>

1. The three "what makes a chord" prompts, and only they: the first expression no longer matches, the symbol expression finds no symbol, and the question has no "what chord" or "which chord" followed by "is", "contains", "has" or "uses". They get "Could not parse a chord name from your question." instead of A major. Checked with .NET's regular expressions against GA's compiled expressions, outside the course program.
2. B♯ D♯♯ F♯♯♯: the third and the fifth are two and four letters above B. The note expression reads B♯, D♯ and F♯, pitch classes 0, 3 and 6, and the skill answers "B# diminished chord contains B#, D#, and F#." Checked by calling GA's compiled skill, outside the course program.
3. "D major chord contains D, F#, and A.": `NormalizeQuality` has no arm for `7sus4` and returns it unchanged, and `GetFormula` gives an unknown quality a major triad. A suffix the expression reads needs an entry in the vocabulary, or the answer is a triad. Checked by calling GA's compiled vocabulary, outside the course program.
4. `ChordVocabulary.PitchClasses` has 21 names, none with two accidentals ([`ChordVocabulary.cs` lines 23-32](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/ChordVocabulary.cs#L23-L32)), and the skill keeps only the names it finds there. `Bbb` is dropped after the expression instead of by it, and the three other notes are still a diminished triad. Checked by calling GA's compiled vocabulary, outside the course program.

</details>

## Key takeaways

- A spelling that is right on 567 of 588 chords doesn't make the answers right: what the skill reads decides which chord it spells.
- A character class with lowercase letters reads English words: the article "a" and "am".
- A match that stops at a word boundary answers a smaller chord than the one asked; a skill should say what it dropped, or decline.
- A round trip is a test without an oracle: give a function its own output back.
- `ToLowerInvariant` isn't limited to ASCII: Δ becomes δ.
- A fallback to a major triad turns every quality nobody wrote down into a confident answer.

## Sources

- GuitarAlchemist/ga at [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `Common/GA.Business.ML/Agents/Skills/ChordInfoSkill.cs`, `Common/GA.Business.ML/Agents/ChordVocabulary.cs`, `Common/GA.Business.ML/Agents/Mcp/ChordSpelling.cs`, `Common/GA.Business.ML/Agents/Mcp/ChordMcpTools.cs`, `skills/chord-info/SKILL.md`, `Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs`, `Tests/Apps/GaChatbot.Api.Tests/Corpus/prompts.yaml`.
- GA's `main` at [`5c3a52a`](https://github.com/GuitarAlchemist/ga/commit/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26), committed on 2026-09-30 UTC, for the comparison and `SemanticIntentRouter.cs`.
- *Open Music Theory*, the chapters on chord symbols and seventh chords.
