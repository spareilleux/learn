---
title: "Lesson 23: Harmonic distance and path"
description: "GrothendieckDeltaSkill and IcvShortestPathSkill are the Guitar Alchemist chatbot's two skills for a pair of chords: the first gives the difference of their interval-class vectors, the second a chain of pitch-class sets from one to the other. The first gives two chords with the same vector a distance of 1 and more chromatic color, C to C included; the second never joins chords of different sizes, so two of its own example prompts get no path after a search of hundreds of sets, and it counts the sets of a path as its steps."
sidebar:
  label: 23. Harmonic distance and path
  order: 23
---

[Lesson 22](../22-similar-chords/) asked `IcvNeighborsSkill` for the sets near one chord. Two skills registered next to it take a pair of chords ([`GaPlugin.cs` lines 100-102](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs#L100-L102)): `GrothendieckDeltaSkill` gives the difference of their interval-class vectors, its L1 and L2 norms and a cost ([`GrothendieckDeltaSkill.cs` lines 97-131](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/GrothendieckDeltaSkill.cs#L97-L131)), and `IcvShortestPathSkill` a chain of pitch-class sets from one to the other ([`IcvShortestPathSkill.cs` lines 9-53](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IcvShortestPathSkill.cs#L9-L53)). Both call `GrothendieckService`, and both have a `CanHandle` that always says no: the router compares a question with each skill's description and example prompts, adds the hint boosts, and sends it to the best score if that score reaches a minimum confidence ([`SemanticIntentRouter.cs` lines 129-257](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Intents/SemanticIntentRouter.cs#L129-L257)).

All GA links point to commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), the course's pin, unless they name another. On GA's `main` at [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/commit/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) (2026-10-01), both skills only mark their refusal `Declined`, `GrothendieckDelta` and `DefaultRoutingHintProvider` are unchanged, and `FindNearby` compares the source with each set by value; the pitch-class sets themselves changed, so `GaMain` asks again. Its output prints the same tables as the pin's, under titles that say "on main". The output comes from:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l23
dotnet run --project code/ga-ai/GaMain -c Release -- l23
```

## How the skills read a question

The delta skill looks for two chords joined by "to", "and" or an arrow:

```csharp
    // Two-chord pattern shared with VoiceLeadingSkill — anchored on
    // "<chord A> to/and <chord B>" with a permissive chord token. Pre-anchored
    // by routing hint, so substring overlap with unrelated phrases is unlikely.
    private static readonly Regex TwoChordPattern =
        new(@"\b(?<a>[A-Ga-g][b#♭♯]?(?:maj|min|m|dim|aug|sus|add|dom)?\d*(?:[b#♭♯]\d+)*°?)\s+(?:to|and|→|->|>)\s+(?<b>[A-Ga-g][b#♭♯]?(?:maj|min|m|dim|aug|sus|add|dom)?\d*(?:[b#♭♯]\d+)*°?)\b",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);
```

The path skill wants "shortest path", "shortest route", "harmonic path", "step by step" or a few other words, then two chords joined by "to", or "how do I get from" two chords, then "harmonic":

```csharp
    // "shortest path / harmonic path / route from A to B"
    private static readonly Regex PathPattern =
        new(@"\b(?:shortest(?:[\s-]*harmonic)?[\s-]*(?:path|route)|harmonic[\s-]*(?:path|route)|BFS\s+path|step[\s-]*by[\s-]*step|PC[\s-]*set\s+path|ICV\s+path|harmonic\s+route)\b[^.?!]*?\b(?:from\s+)?(?<a>[A-Ga-g][b#♭♯]?(?:maj|min|m|dim|aug|sus|add|dom)?\d*(?:[b#♭♯]\d+)*°?)\s+(?:to|→|->)\s+(?<b>[A-Ga-g][b#♭♯]?(?:maj|min|m|dim|aug|sus|add|dom)?\d*(?:[b#♭♯]\d+)*°?)\b",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);

    // Fallback — "how do I get from X to Y harmonically"
    private static readonly Regex HowDoIGetPattern =
        new(@"\bhow\s+do\s+i\s+get\s+from\s+(?<a>[A-Ga-g][b#♭♯]?(?:maj|min|m|dim|aug|sus|add|dom)?\d*(?:[b#♭♯]\d+)*°?)\s+to\s+(?<b>[A-Ga-g][b#♭♯]?(?:maj|min|m|dim|aug|sus|add|dom)?\d*(?:[b#♭♯]\d+)*°?)\b[^.?!]*?\bharmonic",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);
```

Both skills' example prompts were reworded on 2026-06-16, to keep the two apart. The path skill keeps two comments about it, the second written over the first without removing it ([lines 55-66](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IcvShortestPathSkill.cs#L55-L66)).

## GA's phrasings

The program asks each skill its ten example prompts, the phrasings of its doc comment and the two its refusal suggests, asks the other skill the same, and asks `DefaultRoutingHintProvider` which intents each one would boost:

```text
== GrothendieckDeltaSkill's and IcvShortestPathSkill's example prompts and GA's other phrasings for them, at the pin
prompt                                           skill   from          its answer       the other's      routing hints, +0.06 each
how harmonically far is Am from D7               delta   anchor        declined         declined         skill.grothendieckdelta
harmonic distance from Cmaj7 to G7               delta   anchor        Cmaj7 → G7       declined         skill.grothendieckdelta
how far apart are Cmaj7 and Dm7 harmonically     delta   anchor        Cmaj7 → Dm7      declined         none
harmonic cost to move from C to G                delta   anchor        C → G            declined         skill.transpose
how different are C major and F major harmonically delta   anchor        declined         declined         none
harmonic distance between Am and Em              delta   anchor        Am → Em          declined         skill.grothendieckdelta
how close are Cmaj7 and Fmaj7 harmonically       delta   anchor        Cmaj7 → Fmaj7    declined         none
L1 distance from Gmaj7 to Bm7b5                  delta   anchor        Gmaj7 → Bm7b5    declined         none
Grothendieck delta from C to F                   delta   anchor        C → F            declined         skill.grothendieckdelta
measure the harmonic gap between Dm7 and G7      delta   anchor        Dm7 → G7         declined         none
shortest harmonic path from Cmaj7 to G7          path    anchor        Cmaj7 → G7       Cmaj7 → G7       skill.icvshortestpath
shortest path from C major to F major            path    anchor        declined         declined         skill.icvshortestpath
shortest harmonic route from Am to D7            path    anchor        Am → D7          Am → D7          skill.icvshortestpath
shortest path from Cmaj7 to Bm7b5                path    anchor        Cmaj7 → Bm7b5    Cmaj7 → Bm7b5    skill.icvshortestpath
step-by-step harmonic route from C to G          path    anchor        C → G            C → G            skill.icvshortestpath
shortest chord path from Dm7 to Gmaj7            path    anchor        declined         Dm7 → Gmaj7      none
shortest route from C to A minor                 path    anchor        C → A            C → A            skill.icvshortestpath
harmonic stepping stones from Cmaj7 to Fmaj7     path    anchor        declined         Cmaj7 → Fmaj7    none
shortest path from Gmaj7 to Em                   path    anchor        Gmaj7 → Em       Gmaj7 → Em       skill.icvshortestpath
shortest harmonic path of chords from C to F     path    anchor        C → F            C → F            skill.icvshortestpath
Harmonic distance from Cmaj7 to G7               delta   doc comment   Cmaj7 → G7       declined         skill.grothendieckdelta
Grothendieck delta C to F                        delta   doc comment   C → F            declined         skill.grothendieckdelta
How harmonically far is Am from D7               delta   doc comment   declined         declined         skill.grothendieckdelta
Compare the ICVs of Cmaj7 and Dm7                delta   doc comment   Cmaj7 → Dm7      declined         none
harmonic distance from Cmaj7 to G7               delta   refusal       Cmaj7 → G7       declined         skill.grothendieckdelta
delta C to F                                     delta   refusal       C → F            declined         none
Shortest harmonic path from Cmaj7 to G7          path    doc comment   Cmaj7 → G7       Cmaj7 → G7       skill.icvshortestpath
Path from C major to F major                     path    doc comment   declined         declined         none
How do I get from Am to D7 harmonically          path    doc comment   Am → D7          Am → D7          none
shortest path from Cmaj7 to G7                   path    refusal       Cmaj7 → G7       Cmaj7 → G7       skill.icvshortestpath
how do I get from C to F harmonically            path    refusal       C → F            C → F            none
GrothendieckDeltaSkill: anchors 10, answered 8, hinted toward skill.grothendieckdelta 4; the other skill answers 0 of them; CanHandle accepts 0
IcvShortestPathSkill: anchors 10, answered 7, hinted toward skill.icvshortestpath 8; the other skill answers 9 of them; CanHandle accepts 0
```

- **The delta skill answers 8 of its 10 example prompts.** "how harmonically far is Am from D7", also the first phrasing of its doc comment, puts "from" between the chords, and "how different are C major and F major harmonically" puts "major" between the first chord and "and".
- **The path skill answers 7 of its 10.** "shortest path from C major to F major", also in its doc comment as "Path from C major to F major", has "major" after each chord; "shortest chord path from Dm7 to Gmaj7" puts "chord" between "shortest" and "path"; "harmonic stepping stones from Cmaj7 to Fmaj7" has neither "path" nor "route". Of the seven it answers, two get no path and one is read as A major, as the next sections show.
- **The delta skill answers 9 of the path skill's 10 prompts,** since any two chords joined by "to" will do; the path skill answers none of the delta's. A path question worded like these that the router sends to the delta skill gets a distance, not a refusal.
- **The hint rules boost 4 of the delta skill's prompts and 8 of the path skill's** ([`DefaultRoutingHintProvider.cs` lines 128-144](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Intents/DefaultRoutingHintProvider.cs#L128-L144)). "harmonic cost to move from C to G" boosts `skill.transpose` instead, whose rule reads "move … to" and a capital letter ([lines 257-259](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Intents/DefaultRoutingHintProvider.cs#L257-L259)).

## The chords they read

Both skills build their sets with a copy of the table lesson 22 read ([`GrothendieckDeltaSkill.cs` lines 133-173](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/GrothendieckDeltaSkill.cs#L133-L173), [`IcvShortestPathSkill.cs` lines 165-201](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IcvShortestPathSkill.cs#L165-L201)). The program builds lesson 22's chords and the 16 qualities with the three skills' tables, then asks them pairs:

```text
== The chords the two skills read, at the pin
chord tokens 36: built alike by IcvNeighborsSkill, GrothendieckDeltaSkill and IcvShortestPathSkill 36
prompt                                     skill   read as      first built    second built   right
harmonic distance from C major to F major  delta   declined     -              -              no
harmonic distance from C to A minor        delta   C → A        C E G          C# E A         no
harmonic distance from Cmaj7 to a G7       delta   Cmaj7 → a    C E G B        C# E A         no
harmonic distance between CM7 and G7       delta   CM7 → G7     C D# G A#      D F G B        no
harmonic distance from C° to C+            delta   C° → C       C D# F#        C E G          no
shortest path from C major to F major      path    declined     -              -              no
shortest route from C to A minor           path    C → A        C E G          C# E A         no
shortest path from C to a G                path    C → a        C E G          C# E A         no
shortest path from CM7 to G7               path    CM7 → G7     C D# G A#      D F G B        no
```

- **The three tables build the same sets,** so lesson 22's misreadings carry over: CM7 is built as C minor seventh, and a word after the root ends the chord, so "C to A minor", one of the path skill's example prompts, asks for A major.
- **"a" is a chord here too:** "from Cmaj7 to a G7" asks for the distance to A major, and "from C to a G" for a path to A major.
- **° survives on the first chord, not the second.** The first chord only needs a space after it, the second a word boundary, so "C° to C+" is read as C diminished to C major.

## The deltas

The delta skill gives what `ComputeDelta` returns, through `GrothendieckDelta.FromIcVs`:

```csharp
    public static GrothendieckDelta FromIcVs(IntervalClassVector source, IntervalClassVector target)
    {
        var delta = new GrothendieckDelta
        {
            Ic1 = target[IntervalClass.Hemitone] - source[IntervalClass.Hemitone],
            Ic2 = target[IntervalClass.Tone] - source[IntervalClass.Tone],
            Ic3 = target[IntervalClass.FromValue(3)] - source[IntervalClass.FromValue(3)],
            Ic4 = target[IntervalClass.FromValue(4)] - source[IntervalClass.FromValue(4)],
            Ic5 = target[IntervalClass.FromValue(5)] - source[IntervalClass.FromValue(5)],
            Ic6 = target[IntervalClass.Tritone] - source[IntervalClass.Tritone]
        };

        // Heuristic: When two distinct sets share the same ICV (e.g., diatonic modes/keys),
        // L1 difference is zero. To preserve musical differentiation expected by callers/tests,
        // emit a minimal non-zero delta focused on ic1. This keeps related keys close but not identical.
        if (delta.L1Norm == 0)
        {
            delta = delta with { Ic1 = 1 };
        }

        return delta;
    }
```

The program asks the delta skill each pair of its example prompts both ways, and two chords against themselves, then every ordered pair of the 192 chords of 12 roots and 16 qualities:

```text
== The deltas GrothendieckDeltaSkill gives, at the pin
pair             first vector    second vector   L1     the skill's delta      L1   L2      cost   its interpretation
Cmaj7 → G7       <1 0 1 2 2 0>   <0 1 2 1 1 1>   6      [-1, +1, +1, -1, -1, +1] 6    2.449   3.60   -1 ic1 (semitone), +1 ic2 (whole tone), +1 ic3 (minor 3rd), -1 ic4 (major 3rd), -1 ic5 (perfect 4th), +1 ic6 (tritone) â†’ more chromatic color
G7 → Cmaj7       <0 1 2 1 1 1>   <1 0 1 2 2 0>   6      [+1, -1, -1, +1, +1, -1] 6    2.449   3.60   +1 ic1 (semitone), -1 ic2 (whole tone), -1 ic3 (minor 3rd), +1 ic4 (major 3rd), +1 ic5 (perfect 4th), -1 ic6 (tritone) â†’ more chromatic color
Cmaj7 → Dm7      <1 0 1 2 2 0>   <0 1 2 1 2 0>   4      [-1, +1, +1, -1, 0, 0] 4    2.000   2.40   -1 ic1 (semitone), +1 ic2 (whole tone), +1 ic3 (minor 3rd), -1 ic4 (major 3rd) â†’ more chromatic color
Dm7 → Cmaj7      <0 1 2 1 2 0>   <1 0 1 2 2 0>   4      [+1, -1, -1, +1, 0, 0] 4    2.000   2.40   +1 ic1 (semitone), -1 ic2 (whole tone), -1 ic3 (minor 3rd), +1 ic4 (major 3rd) â†’ more chromatic color
C → G            <0 0 1 1 1 0>   <0 0 1 1 1 0>   0      [+1, 0, 0, 0, 0, 0]    1    1.000   0.60   +1 ic1 (semitone) â†’ more chromatic color
G → C            <0 0 1 1 1 0>   <0 0 1 1 1 0>   0      [+1, 0, 0, 0, 0, 0]    1    1.000   0.60   +1 ic1 (semitone) â†’ more chromatic color
Am → Em          <0 0 1 1 1 0>   <0 0 1 1 1 0>   0      [+1, 0, 0, 0, 0, 0]    1    1.000   0.60   +1 ic1 (semitone) â†’ more chromatic color
Em → Am          <0 0 1 1 1 0>   <0 0 1 1 1 0>   0      [+1, 0, 0, 0, 0, 0]    1    1.000   0.60   +1 ic1 (semitone) â†’ more chromatic color
Cmaj7 → Fmaj7    <1 0 1 2 2 0>   <1 0 1 2 2 0>   0      [+1, 0, 0, 0, 0, 0]    1    1.000   0.60   +1 ic1 (semitone) â†’ more chromatic color
Fmaj7 → Cmaj7    <1 0 1 2 2 0>   <1 0 1 2 2 0>   0      [+1, 0, 0, 0, 0, 0]    1    1.000   0.60   +1 ic1 (semitone) â†’ more chromatic color
Gmaj7 → Bm7b5    <1 0 1 2 2 0>   <0 1 2 1 1 1>   6      [-1, +1, +1, -1, -1, +1] 6    2.449   3.60   -1 ic1 (semitone), +1 ic2 (whole tone), +1 ic3 (minor 3rd), -1 ic4 (major 3rd), -1 ic5 (perfect 4th), +1 ic6 (tritone) â†’ more chromatic color
Bm7b5 → Gmaj7    <0 1 2 1 1 1>   <1 0 1 2 2 0>   6      [+1, -1, -1, +1, +1, -1] 6    2.449   3.60   +1 ic1 (semitone), -1 ic2 (whole tone), -1 ic3 (minor 3rd), +1 ic4 (major 3rd), +1 ic5 (perfect 4th), -1 ic6 (tritone) â†’ more chromatic color
C → F            <0 0 1 1 1 0>   <0 0 1 1 1 0>   0      [+1, 0, 0, 0, 0, 0]    1    1.000   0.60   +1 ic1 (semitone) â†’ more chromatic color
F → C            <0 0 1 1 1 0>   <0 0 1 1 1 0>   0      [+1, 0, 0, 0, 0, 0]    1    1.000   0.60   +1 ic1 (semitone) â†’ more chromatic color
Dm7 → G7         <0 1 2 1 2 0>   <0 1 2 1 1 1>   2      [0, 0, 0, 0, -1, +1]   2    1.414   1.20   -1 ic5 (perfect 4th), +1 ic6 (tritone) â†’ increased tension
G7 → Dm7         <0 1 2 1 1 1>   <0 1 2 1 2 0>   2      [0, 0, 0, 0, +1, -1]   2    1.414   1.20   +1 ic5 (perfect 4th), -1 ic6 (tritone) â†’ more consonant
C → C            <0 0 1 1 1 0>   <0 0 1 1 1 0>   0      [+1, 0, 0, 0, 0, 0]    1    1.000   0.60   +1 ic1 (semitone) â†’ more chromatic color
Cmaj7 → Cmaj7    <1 0 1 2 2 0>   <1 0 1 2 2 0>   0      [+1, 0, 0, 0, 0, 0]    1    1.000   0.60   +1 ic1 (semitone) â†’ more chromatic color
ordered pairs 36864: with the same vector 4320, answered L1 1 4320, delta [+1, 0, 0, 0, 0, 0] 4320; with different vectors 32544, L1 right 32544
pairs with different vectors 16272: "more chromatic color" both ways 1440
```

- **Two chords with the same vector are 1 apart, with one more semitone.** C to G, Am to Em, Cmaj7 to Fmaj7, and C to C itself get the delta `[+1, 0, 0, 0, 0, 0]`, an L1 of 1, a cost of 0.60 and "more chromatic color". So do all 4320 ordered pairs of the 192 chords that share a vector; the 32544 others get their L1 right. The answer's own gloss says each component is "how many more occurrences of that interval-class the target has than the source" ([lines 122-128](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/GrothendieckDeltaSkill.cs#L122-L128)): G major has no more semitones than C major. Lesson 22's skill recomputes the delta to avoid this ([`IcvNeighborsSkill.cs` lines 122-129](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IcvNeighborsSkill.cs#L122-L129)); this one doesn't. GA issue [#776](https://github.com/GuitarAlchemist/ga/issues/776) reports the heuristic.
- **The interpretation is the first rule that matches,** and the first is "more semitones or whole tones" ([`GrothendieckDelta.cs` lines 226-258](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Atonal/Grothendieck/GrothendieckDelta.cs#L226-L258)). Cmaj7 to G7 gains a whole tone and G7 to Cmaj7 a semitone, so both ways get "more chromatic color", as 1440 of the 16272 pairs with different vectors do.
- **The arrow before the interpretation prints as `â†’`.** Line 217 holds the bytes of `→` read as Windows-1252 and saved again as UTF-8 ([`GrothendieckDelta.cs` line 217](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Atonal/Grothendieck/GrothendieckDelta.cs#L217)); `main` has the same line.

## The paths

`FindShortestPath` is a breadth-first search: from each set, it moves to the sets of the same size within an L1 of 2 that it hasn't seen, and stops after five moves ([`GrothendieckService.cs` lines 117-163](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Atonal/Grothendieck/GrothendieckService.cs#L117-L163)):

```csharp
            // Check if we've exceeded max steps
            if (path.Count >= maxSteps + 1)
            {
                continue;
            }

            // Find nearby sets (within small distance) to keep the graph sparse and paths musically local.
            // Using radius=2 connects closely related diatonic collections (e.g., C major → G major)
            // that typically differ by one accidental yet may exceed radius=1 under the ICV L1 metric.
            var nearby = FindNearby(current, 2)
                .Select(r => r.Set)
                // Restrict traversal to sets with the same cardinality to avoid unrealistic one-step jumps
                .Where(s => s.Cardinality == current.Cardinality)
                .Where(s => !visited.Contains(s));

            foreach (var next in nearby)
            {
                visited.Add(next);
                var newPath = new List<PitchClassSet>(path) { next };
                queue.Enqueue((next, newPath));
            }
```

The program asks the path skill the example prompts it answers and four more pairs, and counts, for each path, the moves, the L1 and the notes kept at each move, and the moves between two sets of one vector:

```text
== The paths IcvShortestPathSkill finds, at the pin
pair             notes   the answer says                        moves  L1 per move  common notes   same vector
Cmaj7 → G7       4, 4    4 steps total (3 intermediate moves)   3      2,2,2        2,1,0          0
Am → D7          3, 4    No path found within 5 steps           0      -            -              0
Cmaj7 → Bm7b5    4, 4    4 steps total (3 intermediate moves)   3      2,2,2        2,1,0          0
C → G            3, 3    2 steps total (1 intermediate move)    1      0            1              1
C → A            3, 3    2 steps total (1 intermediate move)    1      0            1              1
Gmaj7 → Em       4, 3    No path found within 5 steps           0      -            -              0
C → F            3, 3    2 steps total (1 intermediate move)    1      0            1              1
C → C            3, 3    1 step total (0 intermediate moves)    0      -            -              0
C → Cm           3, 3    2 steps total (1 intermediate move)    1      0            2              1
Cdim7 → Cmaj7    4, 4    No path found within 5 steps           0      -            -              0
Caug → C         3, 3    No path found within 5 steps           0      -            -              0
before "No path" for Am → D7: sets expanded 168 of the 220 of 3 notes, each a scan of the 4096 sets
before "No path" for Gmaj7 → Em: sets expanded 462 of the 495 of 4 notes, each a scan of the 4096 sets
before "No path" for Cdim7 → Cmaj7: sets expanded 3 of the 495 of 4 notes, each a scan of the 4096 sets
before "No path" for Caug → C: sets expanded 4 of the 220 of 3 notes, each a scan of the 4096 sets
the path for "shortest harmonic path from Cmaj7 to G7":
  {0,4,7,11}   C E G B        4-20   <1 0 1 2 2 0>
  {0,2,3,7}    C D D# G       4-14   <1 1 1 1 2 0>  L1 2, common notes 2
  {0,1,4,6}    C C# E F#      4-Z15  <1 1 1 1 1 1>  L1 2, common notes 1
  {2,5,7,11}   D F G B        4-27   <0 1 2 1 1 1>  L1 2, common notes 0
```

- **Chords of different sizes are never joined.** Am to D7 and Gmaj7 to Em, two of the skill's example prompts, and "How do I get from Am to D7 harmonically", from its doc comment, get "No path found within 5 steps", and the answer blames the distance or "the cardinality constraint" ([line 137](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IcvShortestPathSkill.cs#L137)). Before saying so, the search expands 168 of the 220 sets of three notes, or 462 of the 495 sets of four, each a scan of the 4096 sets whose vectors are recomputed at each read ([`PitchClassSet.cs` line 104](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClassSet.cs#L104)); `FindNearby` keeps its answers for 256 sets ([`GrothendieckService.cs` line 21](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Atonal/Grothendieck/GrothendieckService.cs#L21)).
- **The answer counts sets as steps** ([line 141](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IcvShortestPathSkill.cs#L141)). Cmaj7 to G7 is "4 steps total (3 intermediate moves)": three moves, through two sets. C to G is "2 steps total (1 intermediate move)": one move, through none. C to C is "1 step total".
- **A move between two sets of one vector counts as a step.** C to G, C to F, C to Cm and C to A take one move each: their true L1 is 0, which `FromIcVs` turns into 1.
- **The answer names none of the sets in between, and the notes go.** Cmaj7 to G7 passes through C D D# G and C C# E F#, 4-14 and 4-Z15, keeping 2 notes, then 1, then none, where the answer promises "common-tone bridges" ([lines 156-160](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IcvShortestPathSkill.cs#L156-L160)). Cmaj7 to Bm7b5 gets the same counts.
- **Cdim7 and Caug reach only their own transpositions,** 3 and 4 sets: lesson 22 found no set at an L1 of 1 or 2 from Cdim7 and only two-note sets from Caug, and the search keeps the size, so only the sets with their vector remain.

## Where the course stops

- **The router isn't run:** it needs the embeddings. The lesson asks the skills their own example prompts: a question worded exactly like one of them is the likeliest to be sent to them.
- **The count of sets expanded is the course's,** from a search that follows `FindShortestPath`'s rule; the skill doesn't print it. The program doesn't time the skills.
- **The program calls the skills' methods directly,** not through the chatbot.

## Exercises

1. Why does the delta skill decline "how harmonically far is Am from D7"?
2. C major and G major both have the vector `<0 0 1 1 1 0>`. What L1 separates them, and what does the delta skill print? Which line makes the difference?
3. Why does the path skill find no path from Am to D7?
4. The path from Cmaj7 to G7 holds four sets. How many moves does it make, and through how many sets in between? What does the answer say?

<details>
<summary>Solutions</summary>

1. Its pattern needs "to", "and" or an arrow between the two chords ([lines 65-67](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/GrothendieckDeltaSkill.cs#L65-L67)); the prompt has "from".
2. 0. The skill prints an L1 of 1 and the delta `[+1, 0, 0, 0, 0, 0]`, because `FromIcVs` turns a zero delta into `Ic1 = 1` (lines 128-131 of the excerpt above).
3. Am has three notes and D7 four, and the search only moves to sets of the same size (line 150 of `GrothendieckService.cs`), so it never reaches D7.
4. Three moves, through two sets: C D D# G and C C# E F#. The answer says "4 steps total (3 intermediate moves)".

</details>

## Key takeaways

- A heuristic placed in a shared type reaches every caller: one skill corrects it, its sibling prints it.
- A distance that never returns 0 can't say that two chords are alike.
- A search that keeps the size can't join chords of different sizes, and should say so before searching.
- A step count is a count of moves, not of the things the moves join.
- Mojibake in a source file ends up in the chatbot's answers.

## Sources

- GuitarAlchemist/ga at [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `Common/GA.Business.ML/Agents/Skills/GrothendieckDeltaSkill.cs`, `Common/GA.Business.ML/Agents/Skills/IcvShortestPathSkill.cs`, `Common/GA.Business.ML/Agents/Skills/IcvNeighborsSkill.cs`, `Common/GA.Domain.Services/Atonal/Grothendieck/GrothendieckDelta.cs`, `Common/GA.Domain.Services/Atonal/Grothendieck/GrothendieckService.cs`, `Common/GA.Domain.Core/Theory/Atonal/PitchClassSet.cs`, `Common/GA.Business.ML/Agents/Intents/DefaultRoutingHintProvider.cs`, `Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs`.
- GuitarAlchemist/ga at [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/tree/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a): the same skills, with their refusals marked `Declined`, and `GrothendieckDelta.cs`.
- The course's programs: `code/ga-ai/GaAi/Lesson23.cs`, `code/ga-ai/GaMain/Program.cs`, `code/ga-ai/Shared/IcvDeltaPathProbe.cs`.
