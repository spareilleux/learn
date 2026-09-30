---
title: "Lesson 14: What the substitution skill answers"
description: "Guitar Alchemist's chatbot answers a request for a chord substitution without a model, from the distance between interval-class vectors. The course asks its skill the twelve example prompts, one chord of each quality on the 12 roots and eight pairs of chords a textbook names. For one chord, the list depends only on the chord's quality: every chord gets the five other members of its set class with the smallest bitmasks, all one step away, and G7's list has no Db7. For two chords, relative triads and triads a tritone apart get the same labels, and a chord is one step from itself. The DSL closure that gives textbook answers requires, through ga_dsl_eval, the inputs its own schema calls optional."
sidebar:
  label: 14. What the substitution skill answers
  order: 14
---

[Lesson 12](../12-what-the-progression-skills-answer/) and [lesson 13](../13-what-the-progression-analysis-answers/) asked about chord progressions. This lesson asks the chatbot for another chord: a substitute for G7, the secondary dominant of Am, a reharmonization of Dm7. The router sends such a question to the intent `skill.chordsubstitution`, which runs `ChordSubstitutionSkill` ([`GaPlugin.cs` line 41](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs#L41)). The skill calls no model: for one chord, it lists the chords nearest to it by Grothendieck distance, a distance between interval-class vectors, and for two chords it names their relationship. The chatbot has two other ways to answer. The SKILL.md skill [`chord-substitution`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/chord-substitution/SKILL.md), for the model path, gives the model two MCP tools, `ga_chord_substitutions` and `ga_chord_compare`, whose code repeats the C# skill's; their parsing helpers carry the comment "mirror ChordSubstitutionSkill" ([`ChordSubstitutionMcpTools.cs` line 176](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Mcp/ChordSubstitutionMcpTools.cs#L176)). The DSL closure `domain.chordSubstitutions` works differently: it ranks the chords of a key by the notes they share with the chord. GaMcpServer's `GaChordSubstitutions` tool calls it ([`GaDslTool.cs` lines 208-222](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GaDslTool.cs#L208-L222)), and so does the tool that looks for easier voicings ([`GuitaristProblemTools.cs` lines 602-605](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GuitaristProblemTools.cs#L602-L605)).

All GA links point to commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), the course's pin, unless they name another. On `main` at [`5c3a52a`](https://github.com/GuitarAlchemist/ga/commit/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26) (2026-09-30), `ChordSubstitutionSkill.cs`, `ChordSubstitutionMcpTools.cs`, the SKILL.md, `GrothendieckDelta.cs`, `DslEvalMcpTools.cs` and `DefaultRoutingHintProvider.cs` are unchanged. `GrothendieckService.FindNearby` has changed only in the test that keeps the source out of its own list, which the skill already does itself. The closure has changed only in how it names intervals; the course compiles it at [`6baf32e`](https://github.com/GuitarAlchemist/ga/commit/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40), where `DomainClosures.fs` is the same as on `main`, as in lesson 13. The outputs come from:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l14
```

## The skill's own example prompts

The program starts the chatbot's host as in lesson 12, takes the intent the router would choose and asks it each of its example prompts ([`ChordSubstitutionSkill.cs` lines 35-55](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordSubstitutionSkill.cs#L35-L55)). The skill reads up to two chord symbols in the question; with two, it compares them, with one, it lists substitutes ([lines 146-160](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordSubstitutionSkill.cs#L146-L160)):

```csharp
        // Try to extract up to two chord symbols (extended, includes 7th chords)
        var chords = ExtendedChordSymbol.Matches(message)
            .Select(TryParseChordMatch)
            .Where(c => c.HasValue)
            .Select(c => c!.Value)
            .Take(2)
            .ToList();

        if (chords.Count == 2)
            return Task.FromResult(ExecuteComparison(chords[0], chords[1]));

        // Single-chord path — original behaviour
        var parsed = ParseChord(message);
        if (parsed is null)
            return Task.FromResult(CannotHelp("Could not identify a chord symbol in your message."));
```

The program prints the kind of answer and the chords it names:

```text
== The skill's own example prompts
skill.chordsubstitution: ChordSubstitutionSkill, 12 example prompts
"Tritone substitution for G7"  CanHandle yes
  list for G7: Dm7b5 Ab7 F7 D7 Ebm7b5
  the textbook answer: Db7
"What can I substitute for Cmaj7 in a ii-V-I?"  CanHandle no
  list for Cmaj7: Dbmaj7 Abmaj7 Fmaj7 Dmaj7 Amaj7
"Reharmonize Dm7 in a jazz context"  CanHandle no
  list for Dm7: Fm7 F#m7 Am7 Ebm7 Cm7
"Alternative chord for F major in C"  CanHandle yes
  compares F with C: Set-Class Equivalent, ICV Neighbor (L1 = 1)
"What's the secondary dominant of Am?"  CanHandle no
  list for Am: Cm C Ab Dbm Fm
  the textbook answer: E7
"Show me a backdoor dominant for C major"  CanHandle no
  list for C: Cm Ab Dbm Fm Db
  the textbook answer: Bb7
"Alternative chord for Cmaj7"  CanHandle yes
  list for Cmaj7: Dbmaj7 Abmaj7 Fmaj7 Dmaj7 Amaj7
"What can replace Dm7?"  CanHandle no
  list for Dm7: Fm7 F#m7 Am7 Ebm7 Cm7
"Swap chord for G7"  CanHandle yes
  list for G7: Dm7b5 Ab7 F7 D7 Ebm7b5
"Modal interchange substitutes for C major"  CanHandle no
  list for C: Cm Ab Dbm Fm Db
"Borrow a chord from parallel minor"  CanHandle no
  Could not identify a chord symbol in your message.
"Modal interchange options in F major"  CanHandle no
  list for F: Cm C Ab Dbm Fm
CanHandle accepts 4 of 12
```

- **The relation the prompt names is ignored.** "Tritone substitution for G7", "What's the secondary dominant of Am?" and "Show me a backdoor dominant for C major" read one chord and get the same list as any question about that chord. None of the three lists names the chord a textbook gives: D♭7, E7, B♭7. The comparison of two chords knows the three relations, the list doesn't.
- **A key name is read as a chord.** "Alternative chord for F major in C" reads F and C, so the skill compares F with C instead of offering a chord for F in the key of C.
- **"Borrow a chord from parallel minor"** names no chord and gets the skill's refusal. The skill has no notion of a key: modal interchange in C major gets the list for the C major chord.

Every skill also has `CanHandle`, a test on the words of the question. At the pin, the router doesn't call it; on `main`, it falls back on it when it can't embed the question, as lesson 12 showed ([`SemanticIntentRouter.cs` line 321 on `main`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Common/GA.Business.ML/Agents/Intents/SemanticIntentRouter.cs#L321)). The test accepts 4 of the 12 prompts ([lines 59-75](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordSubstitutionSkill.cs#L59-L75)):

```csharp
    private static readonly Regex SubstituteTrigger =
        new(@"\b(substitut|reharmoni|instead\s+of|alternative\s+chord|swap\s+chord|replace\s+chord)\b",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);

    // Additional comparison keywords for the two-chord path
    private static readonly Regex TwoChordTrigger =
        new(@"\b(?:same|related|equivalent|tritone)\b",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);

    // Extended chord symbol pattern — matches triads AND 7th chords (longer alternations first)
    private static readonly Regex ExtendedChordSymbol =
        new(@"\b(?<root>[A-G])(?<acc>[b#]?)(?<qual>m7b5|dim7|maj7|m7|7|min|m|dim|aug|\+)?(?!\w)",
            RegexOptions.Compiled);

    public bool CanHandle(string message) =>
        ExtendedChordSymbol.IsMatch(message) &&
        (SubstituteTrigger.IsMatch(message) || TwoChordTrigger.IsMatch(message));
```

`\b(substitut|reharmoni...)\b` asks for a word boundary right after the stem, and "substitute", "substitution" and "reharmonize" all go on with a letter: the two stems never match a word. "Tritone substitution for G7" passes on "tritone", the comparison's keyword; the two "alternative chord" prompts and "Swap chord for G7" pass on their own phrases. The router's routing hints write the stems with `\w*` ([`DefaultRoutingHintProvider.cs` lines 53-56](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Intents/DefaultRoutingHintProvider.cs#L53-L56)), and the SKILL.md lists "substitute", "secondary dominant", "backdoor" and "modal interchange" among its triggers ([`SKILL.md` lines 8-21](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/chord-substitution/SKILL.md#L8-L21)).

## One chord on the twelve roots

For one chord, the skill asks `FindNearby` for every pitch-class set within distance 3, keeps the ones of the chord's size, sorts them by cost and takes five ([lines 164-174](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordSubstitutionSkill.cs#L164-L174)):

```csharp
        // Exclude the source from its own substitution list. The previous
        // ReferenceEquals check only worked if the catalog interned the EXACT
        // instance built locally — it doesn't, so the source could leak into
        // its own results. Compare by pitch-class mask instead (PR #85 fix).
        var sourceMask = sourceSet.PitchClassMask;
        var nearby = grothendieck.FindNearby(sourceSet, maxDistance: 3)
            .Where(r => r.Set.PitchClassMask != sourceMask
                        && r.Set.Cardinality == sourceSet.Cardinality)
            .OrderBy(r => r.Cost)
            .Take(5)
            .ToList();
```

`FindNearby` compares the chord's interval-class vector with those of the 4,096 pitch-class sets of `PitchClassSet.Items`, in the order of their ids, 0 to 4095, which are their bitmasks ([`GrothendieckService.cs` lines 55-81](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Atonal/Grothendieck/GrothendieckService.cs#L55-L81), [`PitchClassSetId.cs` lines 70-71](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClassSetId.cs#L70-L71)). The cost is the vectors' L1 distance times 0.6 ([lines 38-42](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Atonal/Grothendieck/GrothendieckService.cs#L38-L42)). The program asks "Substitute for" each of the nine qualities the skill reads on the 12 roots, spelled as the skill spells them. For six qualities, it checks whether the list holds one of two substitutes a textbook gives: two chords a third away, which share two notes with a triad or three with a seventh chord, or, for a dominant 7th, its tritone substitute and the half-diminished 7th a third above. It also counts the notes each listed chord shares with the chord asked about:

```text
== One chord: "Substitute for <chord>" on the 12 roots
major (C ... B): the 12 lists name 6 chords, Cm Ab Dbm Fm Db C
  a textbook substitute listed for 5 of 12 roots, e.g. for C: Am, Em
  notes each listed chord shares with its source: 0 for 29, 1 for 22, 2 for 9
minor (Cm ... Bm): the 12 lists name 6 chords, C Ab Dbm Fm Db Cm
  a textbook substitute listed for 4 of 12 roots, e.g. for Cm: Eb, Ab
  notes each listed chord shares with its source: 0 for 28, 1 for 24, 2 for 8
dominant 7th (C7 ... B7): the 12 lists name 6 chords, Dm7b5 Ab7 F7 D7 Ebm7b5 F#m7b5
  a textbook substitute listed for 4 of 12 roots, e.g. for C7: F#7, Em7b5
  notes each listed chord shares with its source: 0 for 14, 1 for 20, 2 for 23, 3 for 3
major 7th (Cmaj7 ... Bmaj7): the 12 lists name 6 chords, Dbmaj7 Abmaj7 Fmaj7 Dmaj7 Amaj7 F#maj7
  a textbook substitute listed for 0 of 12 roots, e.g. for Cmaj7: Em7, Am7
  notes each listed chord shares with its source: 0 for 16, 1 for 22, 2 for 22
minor 7th (Cm7 ... Bm7): the 12 lists name 6 chords, Fm7 Dm7 F#m7 Am7 Ebm7 Cm7
  a textbook substitute listed for 0 of 12 roots, e.g. for Cm7: Ebmaj7, Abmaj7
  notes each listed chord shares with its source: 0 for 16, 1 for 21, 2 for 23
half-diminished (Cm7b5 ... Bm7b5): the 12 lists name 6 chords, Dm7b5 Ab7 F7 D7 Ebm7b5 F#m7b5
  a textbook substitute listed for 3 of 12 roots, e.g. for Cm7b5: Ab7, Ebm7
  notes each listed chord shares with its source: 0 for 16, 1 for 16, 2 for 25, 3 for 3
diminished (Cdim ... Bdim): the 12 lists name 6 chords, Dbdim Ddim Adim F#dim Ebdim Cdim
  no textbook substitute of the same size
  notes each listed chord shares with its source: 0 for 42, 2 for 18
augmented (Caug ... Baug): the 12 lists name 4 chords, Dbaug Daug Ebaug Caug
  no textbook substitute of the same size
  notes each listed chord shares with its source: 0 for 36
diminished 7th (Cdim7 ... Bdim7): the 12 lists name 3 chords, Dbdim7 Ddim7 Cdim7
  no textbook substitute of the same size
  notes each listed chord shares with its source: 0 for 24
Cost and L1 of every listed chord: cost 0.60, L1 1
ga_chord_substitutions returns the same chords, costs and L1 for 108 of 108 chords
ICV C <001110>, Am <001110>: ComputeDelta(...).L1Norm = 1
ICV C <001110>, F# <001110>: ComputeDelta(...).L1Norm = 1
ICV G7 <012111>, Db7 <012111>: ComputeDelta(...).L1Norm = 1
ICV C <001110>, C <001110>: ComputeDelta(...).L1Norm = 1
```

- **The list depends only on the quality.** A chord and all its transpositions and inversions have the same interval-class vector: the 12 major and 12 minor triads share one, and the 12 dominant 7ths share theirs with the 12 half-diminished 7ths. All are at the same cost, the smallest one, so the list takes the five with the smallest bitmasks, in the order of `PitchClassSet.Items`: `OrderBy` keeps equal elements in their order. For each quality, the twelve lists name six chords, fewer for the augmented triad and the diminished 7th, which have four and three transpositions.
- **G7's list has no D♭7.** D♭7 is in G7's set class, but its bitmask is larger than the five first. Major 7ths and minor 7ths never get a textbook substitute; major and minor triads, dominant 7ths and half-diminished 7ths get one only on the roots whose substitutes happen to be among the six. Among the 60 chords listed for major triads, 29 share no note with their source.
- **Every chord is at cost 0.60, L1 1.** The last four lines show why: C and Am have the same vector, and so do C and F♯, G7 and D♭7, and C and itself, but `ComputeDelta` says 1. When the difference is zero, `GrothendieckDelta.FromIcVs` writes 1 in its first component ([`GrothendieckDelta.cs` lines 125-131](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Atonal/Grothendieck/GrothendieckDelta.cs#L125-L131)):

```csharp
        // Heuristic: When two distinct sets share the same ICV (e.g., diatonic modes/keys),
        // L1 difference is zero. To preserve musical differentiation expected by callers/tests,
        // emit a minimal non-zero delta focused on ic1. This keeps related keys close but not identical.
        if (delta.L1Norm == 0)
        {
            delta = delta with { Ic1 = 1 };
        }
```

- **The SKILL.md path gets the same lists.** `ga_chord_substitutions` returns the same chords, costs and L1 for all 108 chords. The SKILL.md's example for Cmaj7 lists Am7 at cost 0.50 and Em7 at 0.83 ([`SKILL.md` lines 100-104](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/chord-substitution/SKILL.md#L100-L104)); the tool lists five other major 7ths, and a cost of 0.6 × L1 can't be 0.50 or 0.83.

## Two chords

With two chords, the skill tests five relations in turn, and adds a last label when none holds ([lines 246-298](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordSubstitutionSkill.cs#L246-L298)). The first two:

```csharp
        var results = new List<SubstitutionRelationship>();
        var ab = (rootB - rootA + 12) % 12;   // semitones from A up to B
        var ba = (rootA - rootB + 12) % 12;   // semitones from B up to A

        // Tritone substitution: roots 6 semitones apart + both dominant 7ths
        if (ab == 6 && intervalsA.SequenceEqual(Dom7) && intervalsB.SequenceEqual(Dom7))
            results.Add(new("Tritone Substitution",
                $"Roots are 6 semitones (tritone) apart; both are dominant 7ths. " +
                $"The M3 of {nameA} equals the m7 of {nameB} and vice versa — guide tones are shared by inversion. " +
                $"Classic bebop move: both chords resolve to the same target by half-step."));

        // Secondary dominant: A is a P5 above B → A functions as V of B
        if (ba == 7)
            results.Add(new("Secondary Dominant",
                $"{nameA} is a perfect 5th above {nameB} — {nameA} functions as V (dominant) of {nameB}."));
```

The program asks "How are A and B related?" for eight pairs a textbook names, on the 12 roots, and asks `ga_chord_compare` the same pairs:

```text
== Two chords: "How are <A> and <B> related?" on the 12 roots
the same chord twice, e.g. C and C: common notes 3; textbook: the same chord
  12 of 12 roots: Set-Class Equivalent, ICV Neighbor (L1 = 1)
  ga_chord_compare gives the same labels for 12 of 12
V7 and I, e.g. G7 and C: common notes 1; textbook: V7 of I
  12 of 12 roots: Secondary Dominant
  ga_chord_compare gives the same labels for 12 of 12
v and i, e.g. Gm and Cm: common notes 1; textbook: a minor v is not a dominant
  12 of 12 roots: Secondary Dominant, Set-Class Equivalent, ICV Neighbor (L1 = 1)
  ga_chord_compare gives the same labels for 12 of 12
bVII7 and I, e.g. Bb7 and C: common notes 0; textbook: backdoor dominant
  12 of 12 roots: Backdoor Dominant
  ga_chord_compare gives the same labels for 12 of 12
dominant 7ths a tritone apart, e.g. F#7 and C7: common notes 2; textbook: tritone substitution
  12 of 12 roots: Tritone Substitution, Set-Class Equivalent, ICV Neighbor (L1 = 1)
  ga_chord_compare gives the same labels for 12 of 12
relative minor and major, e.g. Am and C: common notes 2; textbook: relative chords
  12 of 12 roots: Set-Class Equivalent, ICV Neighbor (L1 = 1)
  ga_chord_compare gives the same labels for 12 of 12
triads a tritone apart, e.g. F#m and C: common notes 0; textbook: no common note
  12 of 12 roots: Set-Class Equivalent, ICV Neighbor (L1 = 1)
  ga_chord_compare gives the same labels for 12 of 12
viiø7 and V7, e.g. Em7b5 and C7: common notes 3; textbook: viiø7 is V9 without its root
  12 of 12 roots: Set-Class Equivalent, ICV Neighbor (L1 = 1)
  ga_chord_compare gives the same labels for 12 of 12
```

- **Three relations are right on the 12 roots:** V7 and I, bVII7 and I, and the tritone substitution.
- **A minor v is labeled a secondary dominant.** The test reads only the interval between the roots; Gm isn't the dominant of Cm, G or G7 is.
- **The labels don't separate what a textbook separates.** Am and C share two notes, F♯m and C none; both pairs get "Set-Class Equivalent" and "ICV Neighbor (L1 = 1)", because every major and minor triad is in one set class. A chord compared with itself is also "1 step(s) apart in ICV space". Em7b5 and C7, which share three notes, get the same two labels. The SKILL.md's comparison example ends with "Also flagged as ICV Neighbor with L1 = 0" ([`SKILL.md` line 108](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/chord-substitution/SKILL.md#L108)), a value `FromIcVs` never returns.

## What the skill reads as a chord

The skill's chord symbol is a capital letter from A to G, an optional `b` or `#`, an optional quality, and no word character after it ([lines 69-71](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordSubstitutionSkill.cs#L69-L71)). The program asks four more questions; the last one is an entry of GA's prompt corpus ([`prompts.yaml` lines 206-209](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Tests/Apps/GaChatbot.Api.Tests/Corpus/prompts.yaml#L206-L209)):

```text
== What the skill reads as a chord
"A substitute for G7?"  CanHandle no, 200 characters
  compares A with G7: Harmonic Distance
"Substitute for B♭7"  CanHandle no, 254 characters
  list for B: Cm C Ab Dbm Fm
"Substitute for Cmin7"  CanHandle no, 50 characters
  Could not identify a chord symbol in your message.
"Suggest substitutions for G7 in a ii-V-I"  CanHandle no, 263 characters
  list for G7: Dm7b5 Ab7 F7 D7 Ebm7b5
SKILL.md: | `m7` / `min7` | minor 7 |
ga_chord_substitutions("Cmin7"): Could not parse 'Cmin7' as a chord symbol. Try Cmaj7, F#m, Bb7, etc.
```

- **"A substitute for G7?"** The article "A" is a chord symbol: the skill compares A major with G7.
- **B♭7** is read as B major: `♭` isn't `b`, and it isn't a word character, so the symbol stops after B. The improvisation skill of lesson 7 read the same sign the same way ([#757](https://github.com/GuitarAlchemist/ga/issues/757)).
- **Cmin7** isn't read at all, by the skill or by the MCP tool ([`ChordSubstitutionMcpTools.cs` lines 230-232](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Mcp/ChordSubstitutionMcpTools.cs#L230-L232)), although the SKILL.md's table of symbols lists `min7`.
- **The corpus entry** asks only for an answer of at least 100 characters, within 60 seconds. The skill's answer has 263 and no D♭7: the entry passes. Lesson 8 sent this prompt through the chat, where it failed with an HTTP 500 for want of a model.

## The closure that answers from the key

`domain.chordSubstitutions` takes a chord, a key and a scale, keeps the key's diatonic chords that share a note with the chord, ranks them by that count and adds the tritone substitute when the chord has a major third and a minor seventh ([`DomainClosures.fs` lines 535-621](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L535-L621)). The program asks it through `ga_dsl_eval`, as a chatbot skill would, and runs `main`'s closure directly, as GaMcpServer does:

```text
== domain.chordSubstitutions, through ga_dsl_eval at a826864 and as it is on main
input  key: string? — key root (e.g. 'C', 'G'). Defaults to chord root.
input  scale: string? — 'major' or 'minor'. Defaults to 'major'.
input  symbol: string — chord to substitute (e.g. 'Am', 'G7')
5 inputs of 15 closures are marked optional: domain.chordSubstitutions.key, domain.chordSubstitutions.scale, domain.queryChords.degree, domain.queryChords.hasInterval, domain.queryChords.quality
symbol=Am
  a826864  missing-required-arg: closure 'domain.chordSubs…' requires argument 'key' (declared type: string? — key root (e.g. 'C', 'G'). Defaults to chord root.)
  6baf32e  Substitutions for Am in key of A major:
             ★★  A      — 2 shared: A(P1/P1) E(P5/P5)
             ★   C#m    — 1 shared: E(P5/m3)
             ★   D      — 1 shared: A(P1/P5)
             ★   E      — 1 shared: E(P5/P1)
             ★   F#m    — 1 shared: A(P1/m3)
symbol=Am, key=C
  a826864  missing-required-arg: closure 'domain.chordSubs…' requires argument 'scale' (declared type: string? — 'major' or 'minor'. Defaults to 'major'.)
  6baf32e  Substitutions for Am in key of C major:
             ★★  C      — 2 shared: C(m3/P1) E(P5/M3)
             ★★  F      — 2 shared: A(P1/M3) C(m3/P5)
             ★   Dm     — 1 shared: A(P1/P5)
             ★   Em     — 1 shared: E(P5/P1)
symbol=Am, key=C, scale=major
  a826864  Substitutions for Am in key of C major:
             ★★  C      — 2 shared: C(m3/P1) E(P5/M3)
             ★★  F      — 2 shared: A(P1/M3) C(m3/P5)
             ★   Dm     — 1 shared: A(P1/P5)
             ★   Em     — 1 shared: E(P5/P1)
  6baf32e  the same
symbol=G7, key=C, scale=major
  a826864  Substitutions for G7 in key of C major:
             ★★★ Bdim   — 3 shared: B(M3/P1) D(P5/m3) F(m7/TT)
             ★★  Dm     — 2 shared: D(P5/P1) F(m7/m3)
             ★★  Em     — 2 shared: G(P1/m3) B(M3/P5)
             ★   C      — 1 shared: G(P1/P5)
             ★   F      — 1 shared: F(m7/P1)
             ◈  Db7    — tritone sub (shares guide tones enharmonically)
  6baf32e  Substitutions for G7 in key of C major:
             ★★★ Bdim   — 3 shared: B(M3/P1) D(P5/m3) F(m7/d5)
             ★★  Dm     — 2 shared: D(P5/P1) F(m7/m3)
             ★★  Em     — 2 shared: G(P1/m3) B(M3/P5)
             ★   C      — 1 shared: G(P1/P5)
             ★   F      — 1 shared: F(m7/P1)
             ◈  Db7    — tritone sub (shares guide tones enharmonically)
symbol=F#7, key=B, scale=major
  a826864  Substitutions for F#7 in key of B major:
             ★★★ A#dim  — 3 shared: Bb(M3/P1) Db(P5/m3) E(m7/TT)
             ★★  C#m    — 2 shared: Db(P5/P1) E(m7/m3)
             ★★  D#m    — 2 shared: F#(P1/m3) Bb(M3/P5)
             ★   B      — 1 shared: F#(P1/P5)
             ★   E      — 1 shared: E(m7/P1)
             ◈  C7     — tritone sub (shares guide tones enharmonically)
  6baf32e  Substitutions for F#7 in key of B major:
             ★★★ A#dim  — 3 shared: Bb(M3/P1) Db(P5/m3) E(m7/d5)
             ★★  C#m    — 2 shared: Db(P5/P1) E(m7/m3)
             ★★  D#m    — 2 shared: F#(P1/m3) Bb(M3/P5)
             ★   B      — 1 shared: F#(P1/P5)
             ★   E      — 1 shared: E(m7/P1)
             ◈  C7     — tritone sub (shares guide tones enharmonically)
```

- **Optional inputs are required.** The schema calls `key` and `scale` optional and gives their defaults, but `ga_dsl_eval` requires every input the schema declares ([`DslEvalMcpTools.cs` lines 257-270](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Mcp/DslEvalMcpTools.cs#L257-L270)): "everything in InputSchema is required for v0.1". A model that trusts the schema and leaves them out gets an error. Five inputs of two of the 15 closures are in that case.
- **The default key of a minor chord is major.** Without a key, the closure takes the chord's root and the major scale ([lines 557-559](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L557-L559)): Am gets the chords of A major, a key without Am. GaMcpServer's tool passes the key only when it has one ([`GaDslTool.cs` lines 218-220](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GaDslTool.cs#L218-L220)), and the easier-voicings tool never passes it.
- **With a key, the answers are a textbook's.** For G7 in C major, B diminished shares three notes and D♭7 is the tritone substitute; for Am, C and F share two notes. GaMcpServer's description of the tool promises something else for Am in C major: "C (★★★, relative major), Em (★★, shared E/B), F (★, shared A)" ([`GaDslTool.cs` line 212](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GaDslTool.cs#L212)). Em shares only E with Am, F shares A and C, and three stars need three shared notes ([line 614](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L614)).
- **F♯7 in B major** gets A♯dim, C♯m and D♯m, spelled from the key, but the shared notes are written B♭ and D♭: they're named by `conventionalKeyName`, the cause of [#770](https://github.com/GuitarAlchemist/ga/issues/770), met in lesson 10. `main` names the fifth of the diminished chord, F above B and E above A♯, `d5` instead of `TT`: the only difference in these runs.

## Where the course stops

- **The model isn't run.** Whether the semantic router sends each example prompt to this intent needs the embeddings, and what a model writes from `ga_chord_substitutions` and `ga_chord_compare` needs the model (*to verify*).
- **The textbook substitutes are a choice.** Two per quality, plus the tritone substitute; jazz harmony knows others, and the counts hold only for these.
- **The skill and the tools aren't run on `main`.** They and `GrothendieckDelta.cs` are unchanged there, and `FindNearby` differs only in the test that keeps the source out; that the lists are the same on `main` comes from reading the diff.

## Reported upstream

- Not reported upstream when this lesson was written: the list that depends only on the chord's quality, the distance of 1 between equal vectors, the labels that don't separate relative triads from triads a tritone apart, the minor v called a secondary dominant, the ignored relation and the symbols read from key names and articles, `CanHandle`'s stems, and the optional inputs `ga_dsl_eval` requires. The shared notes spelled with flats in a sharp key have the same cause as [#770](https://github.com/GuitarAlchemist/ga/issues/770), and B♭ read as B the same as [#757](https://github.com/GuitarAlchemist/ga/issues/757). All are listed in the [journal](../journal/).

## Exercises

1. Compute the bitmasks of G7, Dm7b5 and D♭7, with C as bit 0, and say why Dm7b5 opens G7's list and D♭7 isn't in it.
2. Change the secondary-dominant test so that it requires a major triad or a dominant 7th. Which rows of the two-chord section change?
3. Write the two stems of `CanHandle` with `\w*`, as the routing hints do. How many of the 12 example prompts does the test accept then, and which does it still reject?
4. For Am in C major, the closure lists C, F, Dm and Em. Which of C major's diatonic chords are missing, and why?

<details>
<summary>Solutions</summary>

1. G7 is G B D F, pitch classes 7, 11, 2 and 5: 128 + 2048 + 4 + 32 = 2212. Dm7b5 is D F A♭ C, 2, 5, 8 and 0: 4 + 32 + 256 + 1 = 293. D♭7 is D♭ F A♭ C♭, 1, 5, 8 and 11: 2 + 32 + 256 + 2048 = 2338. All three have the vector <012111>, so all are at cost 0.60. The stable sort leaves them in the order of the bitmasks, and the list stops after the five smallest; Dm7b5's 293 is the smallest of the set class, and D♭7's 2338 comes after G7's own. Worked by hand.
2. Only "v and i": its label "Secondary Dominant" disappears, and the row reads "Set-Class Equivalent, ICV Neighbor (L1 = 1)". V7 and I keep it. Worked by hand.
3. Seven. It still rejects "What's the secondary dominant of Am?", "Show me a backdoor dominant for C major", "What can replace Dm7?", "Borrow a chord from parallel minor" and "Modal interchange options in F major": none holds one of the test's phrases, and the fourth names no chord. Checked with .NET's regular expressions, not compiled into the course.
4. G and B diminished: G B D and B D F share no note with A C E, and the closure drops a chord with no shared note. Am itself, the same root and quality, is skipped. Worked by hand from lines 580-602.

</details>

## Key takeaways

- A distance that ignores transposition can't rank substitutes: all the chords of a set class tie, and the tie decides the answer.
- A tie broken by storage order is an answer nobody chose: here, the smallest bitmasks.
- A distance that says 1 for equal inputs misleads every caller that reads it as a distance.
- A word boundary right after a stem matches no word; the router's own hints wrote `\w*`.
- The textbook answer can already exist in the codebase, here in a closure, while the skill the chatbot routes to doesn't call it.

## Sources

- GuitarAlchemist/ga at [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `Common/GA.Business.ML/Agents/Skills/ChordSubstitutionSkill.cs`, `Common/GA.Business.ML/Agents/Mcp/ChordSubstitutionMcpTools.cs`, `skills/chord-substitution/SKILL.md`, `Common/GA.Domain.Services/Atonal/Grothendieck/GrothendieckService.cs`, `Common/GA.Domain.Services/Atonal/Grothendieck/GrothendieckDelta.cs`, `Common/GA.Domain.Core/Theory/Atonal/PitchClassSetId.cs`, `Common/GA.Business.ML/Agents/Intents/DefaultRoutingHintProvider.cs`, `Common/GA.Business.ML/Agents/Mcp/DslEvalMcpTools.cs`, `Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs`, `GaMcpServer/Tools/GaDslTool.cs`, `GaMcpServer/Tools/GuitaristProblemTools.cs`, `Tests/Apps/GaChatbot.Api.Tests/Corpus/prompts.yaml`.
- GA at [`6baf32e`](https://github.com/GuitarAlchemist/ga/commit/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40): `DomainClosures.fs`, compiled by the course. GA's `main` at [`5c3a52a`](https://github.com/GuitarAlchemist/ga/commit/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26), committed on 2026-09-30 UTC, for the comparison.
- *Open Music Theory*, the chapters on applied chords, modal mixture and chord substitution in jazz.
