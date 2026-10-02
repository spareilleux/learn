---
title: "Lesson 19: Voice-leading pairs"
description: "Guitar Alchemist's MCP server offers agents ga_voice_leading_pair, a tool that pairs playable voicings of two chords from the OPTIC-K index; the chatbot doesn't call it. The course asks it the ten examples of lesson 18, at the pin and with the search of GA's main. At the pin, 3 of the 10 first pairs play both chords; on main all 10 do, and each is the smoothest such pair in the index. The tool checks nothing it pairs: with 50 candidates, it answers C to Am at the pin with the same three Es on both sides, at 0 semitones. Its distance is the least between voicings of the same size, pairs the lowest notes when the sizes differ, and its diagrams start with the high E."
sidebar:
  label: 19. Voice-leading pairs
  order: 19
---

[Lesson 18](../18-voice-leading/) asked the chatbot how to move from one chord to the next. Its skill answered in pitch classes, with no octave and no fret, and the lesson stopped at another path in GA, one that moves real voicings. This lesson runs it. `ga_voice_leading_pair` is a tool of `GaMcpServer`, GA's MCP server, whose tools agents such as Claude Code can call. Given two chord symbols, it asks the OPTIC-K index of [lesson 3](../03-index-and-search/) for 15 voicings of each chord, weighs every pair with a distance in semitones, and returns the five smallest ([`CompositionTools.cs` lines 179-268](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L179-L268)). The chatbot doesn't call it: its own tools are another set, and the skill drafted to call this one is parked ([`skills-dev/_pending-tools/README.md` lines 19-29](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/README.md#L19-L29)).

All GA links point to commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), the course's pin, unless they name another. `CompositionTools.cs` is the same on GA's `main` at [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/commit/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) (2026-10-01), but the search it calls changed after the pin, as [lesson 16](../16-the-voicings-of-a-chord/) showed. The program compiles the tool's file from each clone of GA into the course's two programs, and points it at lesson 3's index: at the pin in `GaAi`, and in `GaMain` at the index that `main`'s code writes from the same corpus. The output comes from:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l19
dotnet run --project code/ga-ai/GaMain -c Release -- l19
```

## How the tool answers

`SearchByChordAsync` reads the symbol with `ChordPitchClasses`, the reader of lesson 16, turns it into a query vector, and asks the index for the nearest voicings ([lines 278-298](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L278-L298)):

```csharp
    private static async Task<SearchOutcome> SearchByChordAsync(
        string chordSymbol, int limit, string? instrument, CancellationToken ct)
    {
        if (!ChordPitchClasses.TryParse(chordSymbol.Trim(), out var rootPc, out var pcs) || rootPc is null)
            return new([], $"unrecognized chord symbol '{chordSymbol}'");

        var structured = new StructuredQuery(
            ChordSymbol: chordSymbol.Trim(),
            RootPitchClass: rootPc,
            PitchClasses: pcs,
            ModeName: null,
            Tags: null);

        var vec = EncoderShared.Value.Encode(structured);
        var strategy = GetStrategy();
        var hits = string.IsNullOrWhiteSpace(instrument)
            ? await strategy.SemanticSearchAsync(vec, limit, ct)
            : await strategy.HybridSearchAsync(vec, new VoicingSearchFilters(VoicingType: instrument), limit, ct);

        return new(hits, null);
    }
```

The query names no chord: without an instrument, the candidates are the voicings whose vectors are nearest to the query, whatever they play. `GetStrategy` takes the search from `VoicingSearchTool`, the server's search tool, by reading its private field `Strategy` ([lines 300-310](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L300-L310)). That class finds the index through `GA_OPTICK_INDEX_PATH` or under `state/voicings/` ([`VoicingSearchTool.cs` lines 64-83](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingSearchTool.cs#L64-L83)). The course compiles a stand-in with the same name and field, which reads lesson 3's index (`code/ga-ai/Shared/VoicingSearchTool.cs`).

The tool weighs every pair of candidates with `VoiceLeadingDistance` ([lines 312-336](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L312-L336)):

```csharp
    /// <summary>
    ///     Sum of absolute semitone differences under greedy ascending-pitch matching.
    ///     For voicings of unequal note count, the shorter one pairs against its nearest
    ///     neighbors and the remainder contributes a small per-note penalty (simulating
    ///     "voice appears from silence" / "voice disappears"). This is not a formal
    ///     Hungarian-optimal assignment — it's O(n log n) and produces a ranking good
    ///     enough to surface smooth voice-leadings among candidates.
    /// </summary>
    private static double VoiceLeadingDistance(IReadOnlyList<int> midi1, IReadOnlyList<int> midi2)
    {
        if (midi1.Count == 0 || midi2.Count == 0) return double.MaxValue;

        var a = midi1.OrderBy(n => n).ToArray();
        var b = midi2.OrderBy(n => n).ToArray();
        var common = Math.Min(a.Length, b.Length);

        double sum = 0;
        for (var i = 0; i < common; i++)
            sum += Math.Abs(a[i] - b[i]);

        // Penalty for unmatched voices (extra notes on either side).
        var extras = Math.Abs(a.Length - b.Length);
        sum += extras * 3.0;  // soft penalty — 3 semitones per orphan note.
        return sum;
    }
```

The distance sorts the MIDI notes of both voicings, pairs them from the lowest up, adds the differences, and counts 3 semitones for each note left over. The tool then sorts the pairs by distance, and by the sum of their two search scores on a tie ([lines 224-235](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L224-L235)).

## The candidates

The program asks for the candidates of the 14 chords in `VoiceLeadingSkill`'s ten example prompts (lesson 18), and compares each voicing with the chord as a textbook spells it, as lesson 16 did: **exact** when the voicing plays the chord's notes and no other, **more** when it plays them and others, **part** when it plays only some of them, **other** otherwise. A seventh chord that lacks only its perfect fifth gets its own verdict, **no fifth**: shell voicings leave the fifth out, and a guitarist plays them for the chord. The course counts exact and no fifth as right. The program also counts the exact voicings of each chord in the whole index:

```text
== The 15 candidates the tool pairs for each chord, at the pin, against the chord a textbook spells
chord    exact   no fifth   more   part   other   exact in the index  first exact candidate
C        10      0          0      5      0       63                  rank 1
F        15      0          0      0      0       35                  rank 1
Am       3       0          0      10     2       35                  rank 1
G7       0       15         0      0      0       49                  none
Cmaj7    5       3          0      7      0       42                  rank 4
Dm7      0       5          0      10     0       25                  none
G        15      0          0      0      0       35                  rank 1
Em       15      0          0      0      0       63                  rank 1
A7       0       2          0      7      6       35                  none
Fmaj7    0       15         0      0      0       60                  none
Bm7b5    4       0          0      11     0       25                  rank 1
D        7       0          0      5      3       27                  rank 1
A        5       0          0      5      5       21                  rank 11
C7       1       12         0      2      0       49                  rank 15
candidates 210: exact 80, no fifth 52, more 0, part 62, other 16
```

- **At the pin, 80 of the 210 candidates are exact, and 52 more lack only the fifth.** G7, Dm7, A7 and Fmaj7 get no exact voicing among their 15, though the index holds 49, 25, 35 and 60. G7 and Fmaj7 still get 15 voicings without the fifth. A gets its first exact voicing at rank 11, C7 at rank 15.
- **The others play part of the chord, or other notes.** For C, 5 of the 15 play part of it, like the C5 of the next table, which has no E.

```text
== The 15 candidates the tool pairs for each chord, on main, against the chord a textbook spells
chord    exact   no fifth   more   part   other   exact in the index  first exact candidate
C        15      0          0      0      0       63                  rank 1
F        15      0          0      0      0       35                  rank 1
Am       15      0          0      0      0       35                  rank 1
G7       15      0          0      0      0       49                  rank 1
Cmaj7    15      0          0      0      0       42                  rank 1
Dm7      15      0          0      0      0       25                  rank 1
G        15      0          0      0      0       35                  rank 1
Em       15      0          0      0      0       63                  rank 1
A7       15      0          0      0      0       35                  rank 1
Fmaj7    15      0          0      0      0       60                  rank 1
Bm7b5    15      0          0      0      0       25                  rank 1
D        15      0          0      0      0       27                  rank 1
A        15      0          0      0      0       21                  rank 1
C7       15      0          0      0      0       49                  rank 1
candidates 210: exact 210, no fifth 0, more 0, part 0, other 0
```

- **On `main`, all 210 candidates are exact.** The tool is the same; the search it calls returns only voicings of the chord asked, for each of the 14 chords.

## The first pair

For each prompt, the program checks both voicings of the first of the five pairs, and counts the pairs, among the five, whose two voicings are right. It also looks for the smoothest pair of exact voicings in the whole index, by the tool's own distance, and gives lesson 18's least motion in pitch classes. The program writes every diagram low E first, as a chart does:

```text
== The tool's first pair for each prompt, at the pin, and the smoothest pair of exact voicings in the index
prompt         first pair: from                           to                                   both right   smoothest exact pair in the index    least in pitch classes
C → F          5: x-3-x-0-1-x C5, part                    x-3-x-2-1-1 F/C, exact               4 of 5       3: x-x-x-0-1-0 → x-x-x-2-1-1         3
C → Am         3: x-3-2-x-1-x C + E (Major 3rd), part     x-3-2-2-x-x Am/C, exact              0 of 5       2: x-x-x-0-1-0 → x-x-x-2-1-0         2
G7 → Cmaj7     3: x-2-3-x-0-3 G7(shell)/B, no fifth       x-2-x-0-1-3 C5/B, part               1 of 5       3: x-x-0-0-0-1 → x-3-x-0-0-0         3
Dm7 → G7       6: x-3-3-x-3-x Dm7(shell)/C, no fifth      x-2-3-x-x-3 G7(shell)/B, no fifth    5 of 5       3: x-x-0-2-1-1 → x-x-0-0-0-1         3
C → G          6: x-x-2-0-1-x C/E, exact                  x-x-0-0-0-3 G/D, exact               4 of 5       3: x-x-2-x-1-3 → x-x-0-x-0-3         3
Em → A7        5: 3-x-2-x-0-0 Em/G, exact                 3-x-2-2-x-x A5/G, part               0 of 5       4: x-x-2-0-0-3 → x-x-2-2-2-3         4
Fmaj7 → Bm7b5  4: 0-0-3-x-x-x Fmaj7(shell)/E, no fifth    1-0-3-x-0-x Bm7b5/F, part            1 of 5       3: x-x-2-2-1-1 → x-x-0-2-0-1         3
D → A          4: x-0-x-2-3-x D5, part                    x-0-x-2-2-0 A, exact                 0 of 5       3: x-x-x-2-3-2 → x-x-x-2-2-0         3
C7 → F         4: x-3-x-3-1-x Bb + C (Major 2nd), part    x-3-x-2-1-1 F/C, exact               4 of 5       4: x-x-2-3-1-3 → x-x-3-2-1-1         4
G7 → C         5: x-x-3-0-0-3 G7(shell)/F, no fifth       x-x-2-0-1-x C/E, exact               5 of 5       4: x-x-0-0-0-1 → x-x-2-0-1-0         4
prompts 10: first pair right on both sides 3, moves more than the smoothest exact pair 8; that pair moves the least in pitch classes 10
the first pair for C → F, as the tool returns it: diagram x-1-0-x-3-x → 1-1-2-x-3-x
```

- **At the pin, 3 of the 10 first pairs play both chords.** C → F starts from `x-3-x-0-1-x`, a C5 that plays C and G but no E. Em → A7 ends on `3-x-2-2-x-x`, A and E over G, without C♯.
- **8 first pairs move more than a pair of the right voicings in the index.** C → G gets two exact voicings that move 6 semitones, while `x-x-2-x-1-3` → `x-x-0-x-0-3` moves 3: the 15 candidates of C and of G don't hold that pair.
- **The smoothest exact pair reaches lesson 18's least motion for all ten prompts.** In lesson 3's corpus, real voicings move as little as the pitch classes allow.

```text
== The tool's first pair for each prompt, on main, and the smoothest pair of exact voicings in the index
prompt         first pair: from                           to                                   both right   smoothest exact pair in the index    least in pitch classes
C → F          3: x-x-x-0-1-0 C/G, exact                  x-x-x-2-1-1 F/A, exact               5 of 5       3: x-x-x-0-1-0 → x-x-x-2-1-1         3
C → Am         2: x-x-x-0-1-0 C/G, exact                  x-x-x-2-1-0 Am, exact                5 of 5       2: x-x-x-0-1-0 → x-x-x-2-1-0         2
G7 → Cmaj7     3: x-x-0-0-0-1 G7/D, exact                 x-3-x-0-0-0 Cmaj7, exact             5 of 5       3: x-x-0-0-0-1 → x-3-x-0-0-0         3
Dm7 → G7       3: x-x-0-2-1-1 Dm7, exact                  x-x-0-0-0-1 G7/D, exact              5 of 5       3: x-x-0-2-1-1 → x-x-0-0-0-1         3
C → G          3: x-x-2-x-1-3 C/E, exact                  x-x-0-x-0-3 G/D, exact               5 of 5       3: x-x-2-x-1-3 → x-x-0-x-0-3         3
Em → A7        4: x-x-2-0-0-3 Em, exact                   x-x-2-2-2-3 A7/E, exact              5 of 5       4: x-x-2-0-0-3 → x-x-2-2-2-3         4
Fmaj7 → Bm7b5  3: x-x-2-2-1-1 Fmaj7/E, exact              x-x-0-2-0-1 Bm7b5/D, exact           5 of 5       3: x-x-2-2-1-1 → x-x-0-2-0-1         3
D → A          3: x-x-x-2-3-2 D/A, exact                  x-x-x-2-2-0 A, exact                 5 of 5       3: x-x-x-2-3-2 → x-x-x-2-2-0         3
C7 → F         4: x-x-2-3-1-3 C7/E, exact                 x-x-3-2-1-1 F, exact                 5 of 5       4: x-x-2-3-1-3 → x-x-3-2-1-1         4
G7 → C         4: x-x-0-0-0-1 G7/D, exact                 x-x-2-0-1-0 C/E, exact               5 of 5       4: x-x-0-0-0-1 → x-x-2-0-1-0         4
prompts 10: first pair right on both sides 10, moves more than the smoothest exact pair 0; that pair moves the least in pitch classes 10
the first pair for C → F, as the tool returns it: diagram 0-1-0-x-x-x → 1-1-2-x-x-x
```

- **On `main`, every first pair plays both chords, and it is the smoothest pair of exact voicings in the index.** All five pairs of every prompt are right.
- **The tool returns its diagrams high E first, on `main` too.** The last line gives the first pair for C → F as the tool returns it: `0-1-0-x-x-x` is `x-x-x-0-1-0` read from the high E. The index writes string 1 first (difference 13 of the [journal](../journal/)'s entry of 2026-09-14). On `main`, the voicings skill turns it into chart order before answering ([`ChordVoicingsSkill.cs` line 136 on `main`](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Agents/Skills/ChordVoicingsSkill.cs#L136)), but the tool returns the index's string as it is ([`CompositionTools.cs` lines 239-254](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L239-L254)). A client that reads `0-1-0-x-x-x` as a chart puts the fingers on the wrong strings.

## Fifty candidates

The description of `candidatesPerChord` promises "Higher = more exhaustive pair search, slower" ([line 195](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L195)). The program asks again with 50 candidates per chord, the most the tool allows ([line 203](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L203)):

```text
== The first pair with 50 candidates per chord, the most the tool allows, at the pin
prompt         distance   from         to           first pair
C → F          3          part         part         0-x-2-x-x-0 E (unison) → 1-x-3-x-x-1 F (unison)
C → Am         0          part         part         0-x-2-x-x-0 E (unison) → 0-x-2-x-x-0 E (unison)
G7 → Cmaj7     3          no fifth     part         x-2-3-x-0-3 G7(shell)/B → x-2-x-0-1-3 C5/B
Dm7 → G7       3          other        part         1-x-3-0-3-x G5/F → 1-x-3-0-x-x F + G (Major 2nd)
C → G          0          part         part         3-x-x-0-x-3 G (unison) → 3-x-x-0-x-3 G (unison)
Em → A7        0          other        part         x-0-x-0-x-0 A5 → x-0-x-0-x-0 A5
Fmaj7 → Bm7b5  1          part         other        0-x-3-x-1-x F5/E → 0-x-3-x-0-x E5
D → A          2          part         part         x-0-x-2-3-x D5 → x-0-x-2-x-0 A5
C7 → F         4          part         exact        x-3-x-3-1-x Bb + C (Major 2nd) → x-3-x-2-1-1 F/C
G7 → C         2          part         part         1-x-x-0-x-3 F + G (Major 2nd) → 3-x-x-0-x-3 G (unison)
prompts 10: first pair right on both sides 0
```

- **At the pin, no first pair plays both chords.** C → Am gets `0-x-2-x-x-0` on both sides: the low E string, the D string at the second fret and the high E string, three Es. E is a note of both chords, and no voice moves. C → G and Em → A7 also get the same voicing on both sides.
- **The distance rewards motion, not the chord.** A wider search brings unisons and bare fifths, which move less, and the tool checks nothing it pairs.

```text
== The first pair with 50 candidates per chord, the most the tool allows, on main
prompt         distance   from         to           first pair
C → F          3          exact        exact        x-x-x-0-1-0 C/G → x-x-x-2-1-1 F/A
C → Am         2          exact        exact        x-x-x-0-1-0 C/G → x-x-x-2-1-0 Am
G7 → Cmaj7     2          more         more         x-2-2-0-3-1 G7/B → x-2-2-0-1-1 Cmaj7/B
Dm7 → G7       3          exact        exact        x-x-0-2-1-1 Dm7 → x-x-0-0-0-1 G7/D
C → G          3          exact        exact        x-x-2-x-1-3 C/E → x-x-0-x-0-3 G/D
Em → A7        4          exact        exact        x-x-2-0-0-3 Em → x-x-2-2-2-3 A7/E
Fmaj7 → Bm7b5  3          exact        exact        x-x-2-2-1-1 Fmaj7/E → x-x-0-2-0-1 Bm7b5/D
D → A          2          more         more         x-x-0-2-2-2 Dmaj7 → x-x-0-2-2-0 Aadd11/D
C7 → F         4          exact        exact        x-x-2-3-1-3 C7/E → x-x-3-2-1-1 F
G7 → C         4          exact        exact        x-x-0-0-0-1 G7/D → x-x-2-0-1-0 C/E
prompts 10: first pair right on both sides 8
```

- **On `main`, 8 first pairs play both chords, and the two others play more.** G7 → Cmaj7 moves `x-2-2-0-3-1` to `x-2-2-0-1-1` by 2 semitones, where 15 candidates gave 3: the first adds E to G7, the second F to Cmaj7. D → A moves a Dmaj7 to an A with a D, by 2 instead of 3.
- **At the pin as on `main`, more candidates trade the chord for less motion.**

## The distance

The tool's description calls its matching "good enough for retrieval ranking, not a formal Hungarian-optimal assignment" ([lines 180-185](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L180-L185)), and the doc comment says that a smaller voicing "pairs against its nearest neighbors" ([lines 312-319](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L312-L319)). The program compares the distance, on every pair the tool weighs for the ten prompts, with the least motion over every way to pair the notes. When the sizes differ, the least chooses which notes of the larger voicing to pair, and adds the same 3 semitones for each note left over:

```text
== The tool's distance on every pair it weighs for the ten prompts, at the pin, against the least motion
pairs of equal size 867: the distance is the least over every pairing 867
pairs of unequal size 1383: the distance is the least over every choice of notes 593
the largest gap, 39 semitones: 0-2-2-0-0-0 Em [40 47 52 55 59 64] → x-x-x-2-2-3 A7(shell) [57 61 67], distance 55, least 16
prompts whose first pair would move less with the least over every choice of notes: 0 of 10
```

- **Between voicings of the same size, the distance is always the least.** Pairing sorted notes can't be beaten when the cost is the sum of the differences: two voices that cross never move less than the same two uncrossed. Here the description sells the matching short.
- **When the sizes differ, the tool pairs the lowest notes, not the nearest, and 593 of 1383 pairs get the least.** From Em `0-2-2-0-0-0` to the A7 shell `x-x-x-2-2-3`, the tool pairs the three lowest notes of Em with A, C♯ and G an octave and more above: 55 semitones with the penalty. Pairing the three highest moves 16.
- **For these ten prompts, the smallest distance doesn't change.** With the least in its place, no first pair would move less, at the pin as on `main`.

```text
== The tool's distance on every pair it weighs for the ten prompts, on main, against the least motion
pairs of equal size 890: the distance is the least over every pairing 890
pairs of unequal size 1360: the distance is the least over every choice of notes 340
the largest gap, 39 semitones: x-x-2-x-0-3 Em [52 59 67] → 0-0-2-x-2-3 A7/E [40 45 52 61 67], distance 47, least 8
prompts whose first pair would move less with the least over every choice of notes: 0 of 10
```

- **On `main`, 340 of 1360 pairs of different sizes get the least,** and the largest gap is 39 semitones again, from a three-note Em to a five-note A7.

## The skill draft that would call it

`skills-dev/_pending-tools/voice-leading/DRAFT.md` is a chatbot skill written to call `ga_voice_leading_pair` ([lines 1-25](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/voice-leading/DRAFT.md#L1-L25)). Its file name keeps it out of the chatbot: the skill loader reads only files named `SKILL.md`, and the README parks the draft until the tool exists among the chatbot's own ([README lines 1-17](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/README.md#L1-L17)). The draft describes another tool than the one in `CompositionTools.cs`:

- an argument `optimize`, `"minimum_movement"` or `"common_tones"`, which the tool doesn't take, and `VoiceMovements`, `TotalSemitones` and `CommonTones` in the answer, where the tool returns pairs of voicings with a distance ([lines 31-44](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/voice-leading/DRAFT.md#L31-L44));
- "a Plücker-line / minimum-displacement solution" ([line 29](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/voice-leading/DRAFT.md#L29)), where the tool sorts MIDI notes;
- a cross-reference to `Common/GA.Business.ML/Agents/Mcp/HarmonyMcpTools.cs` ([line 74](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/voice-leading/DRAFT.md#L74)), a file that GA has neither at the pin nor on `main`;
- an example answer from Dm7 to G7 that announces a total movement of 2 semitones, then lists four moves of 0, 0, 2 and 1 ([lines 54-60](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/voice-leading/DRAFT.md#L54-L60)). They add up to 3, the distance of the tool's first pair on `main` and lesson 18's least motion.

## Where the course stops

- **The corpus is lesson 3's,** 15,360 voicings on three frets, not the production index. Among more voicings, the candidates and the pairs may differ (*to verify*).
- **The program calls the tool's method directly,** with a stand-in for `VoicingSearchTool`, not through an MCP client and GA's server.
- **The verdicts read pitch classes.** The course counts a seventh chord without its fifth as right, whatever note it doubles, and doesn't judge the fingering or the register.
- **Only the first pair is checked in detail.** The program counts the right pairs among the five, but doesn't measure how the distance's fault reorders them.

## Exercises

1. With 50 candidates at the pin, the tool answers C → Am with `0-x-2-x-x-0` on both sides, at 0 semitones. What does that voicing play, and why is a distance of 0 no answer here?
2. Compute the tool's distance from Em `0-2-2-0-0-0`, MIDI notes 40 47 52 55 59 64, to the A7 shell `x-x-x-2-2-3`, MIDI notes 57 61 67. Which pairing moves 16?
3. At the pin, the 15 candidates of G7 all lack only the fifth. Which notes do they play, and what does lesson 16 call such a voicing?
4. The tool takes an instrument, "guitar | bass | ukulele". What does it answer on the course's index for "bass"?

<details>
<summary>Solutions</summary>

1. Three Es: the low E string open, the D string at the second fret and the high E string open. E is a note of both C and A minor, so the voicing plays part of each and neither chord. The query names no chord, and at the pin this voicing is among the 50 nearest to both queries. Paired with itself it moves 0, and nothing in the tool checks what it plays. On `main`, the first pair for C → Am with 50 candidates moves 2 and plays both chords.
2. Sorted, the three notes of the A7 pair with the three lowest of Em: 40 → 57 is 17, 47 → 61 is 14 and 52 → 67 is 15, so 46, plus 3 for each of the three notes left over: 55. Paired with the three highest, 55 → 57, 59 → 61 and 64 → 67 move 2 + 2 + 3 = 7, plus 9: 16.
3. G, B and F, the root, the third and the seventh, nothing else: lesson 16's shell. In the first-pair table, the index's names for them start with "G7(shell)".
4. The error "no voicings retrieved for one or both chords" ([lines 214-221](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L214-L221)): the course's index holds only guitar voicings, so the filter keeps none. With "guitar", the first pairs are those without an instrument. Checked by running the pinned tool outside the course's expected output.

</details>

## Key takeaways

- A ranking by motion ranks only the motion: a tool that pairs what a search returns must check what the voicings play, or trust the search.
- More candidates can make the answer worse when the nearest neighbors drift away from the chord.
- Pairing sorted notes gives the least motion between voicings of the same size; with different sizes, which notes to pair is the part that needs a search.
- The order of a diagram string is a contract: one consumer of the index fixed it, another passes it on.
- A tool an agent can call is not a tool the chatbot can call, and a draft written for one registry can describe a tool that exists in neither.

## Sources

- GuitarAlchemist/ga at [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `GaMcpServer/Tools/CompositionTools.cs`, `GaMcpServer/Tools/VoicingSearchTool.cs`, `skills-dev/_pending-tools/voice-leading/DRAFT.md`, `skills-dev/_pending-tools/README.md`.
- GuitarAlchemist/ga at [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/tree/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a): the same tool and drafts, the search of lesson 16, `Common/GA.Business.ML/Agents/Skills/ChordVoicingsSkill.cs`.
- The course's programs: `code/ga-ai/GaAi/Lesson19.cs`, `code/ga-ai/GaMain/Program.cs`, `code/ga-ai/Shared/VoiceLeadingPairProbe.cs`, `code/ga-ai/Shared/VoicingSearchTool.cs`.
