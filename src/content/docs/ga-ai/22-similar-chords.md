---
title: "Lesson 22: Similar chords"
description: "IcvNeighborsSkill is the Guitar Alchemist chatbot's answer to which chords are similar to a chord: it reads one chord and lists the pitch-class sets whose interval-class vectors are within 2 of its vector. None of its ten example prompts, the questions the router is likeliest to send it, matches the patterns it reads, so it declines all ten, where its sister skill answers eight of its own. It builds 10 of 27 common chords right, CM7 as a minor seventh, and its eight neighbors are the first eight sets by bitmask: the same for every major and minor triad, five of them intervals of two notes."
sidebar:
  label: 22. Similar chords
  order: 22
---

[Lesson 21](../21-the-voicing-search/) measured the embedding search. For chords that share a shape in any key, GA points elsewhere: "Transposition-agnostic "same-shape" similarity uses the ICV path (`IcvNeighborsSkill` / Grothendieck), not the embedding" ([`CLAUDE.md` line 43](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/CLAUDE.md#L43)). `IcvNeighborsSkill` is that path in the chatbot ([`IcvNeighborsSkill.cs` lines 9-49](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IcvNeighborsSkill.cs#L9-L49)), registered with the other skills ([`GaPlugin.cs` line 101](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs#L101)). It reads one chord, builds its pitch-class set, and lists the sets whose interval-class vectors are within an L1 distance of 2 of the chord's, from `GrothendieckService.FindNearby`. [Lesson 14](../14-what-the-substitution-skill-answers/) met `FindNearby` through the substitution skill, and the [music theory course](../../music-theory-ga/04-set-classes/) through the MCP tool `ga_icv_neighbors`; this lesson asks the chatbot's skill.

All GA links point to commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), the course's pin, unless they name another. On GA's `main` at [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/commit/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) (2026-10-01), `IcvNeighborsSkill` and `IntervalClassVectorSkill` only mark their refusal `Declined`, `DefaultRoutingHintProvider` and `GrothendieckDelta` are unchanged, and `FindNearby` compares the source with each set by value; the pitch-class sets themselves changed, so `GaMain` asks again. Its output prints the same tables as the pin's, under titles that say "on main". The output comes from:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l22
dotnet run --project code/ga-ai/GaMain -c Release -- l22
```

## How the skill reads a question

The skill has no keyword test: its `CanHandle` always says no, and the router compares a question with each skill's description and example prompts, adds the hint boosts, and sends it to the best score if that score reaches a minimum confidence ([`SemanticIntentRouter.cs` lines 129-257](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Intents/SemanticIntentRouter.cs#L129-L257)). Those prompts were reworded on 2026-06-16, to keep them away from the neighboring skills', and the comment above them says which words went. The patterns that read the question still need them:

```csharp
    // Routing anchors emphasise the user GOAL — "find OTHER chords SIMILAR to
    // one chord" — using resemble/similar/most-like/interval-profile. Two
    // curation passes (routing-ambiguity diagnostic, 2026-06-16):
    //  1. dropped the bare "ICV" framing (owned by IntervalClassVectorSkill,
    //     the single-chord ICV intent): -0.05 -> +0.036 silhouette.
    //  2. dropped "close/nearby/adjacent" (collided with GrothendieckDeltaSkill's
    //     "how close are X and Y") and "chords to C major" (collided with
    //     ChordInfoSkill's "what is a C major chord"). "other … resemble/similar"
    //     keeps the find-similar goal while shedding both neighbours' vocabulary.
    public IReadOnlyList<string> ExamplePrompts =>
    [
        "which chords are most similar to Dm7",
        "what other chords resemble Cmaj7",
        "find chords with a similar sound to G7",
        "chords related to F major by interval content",
        "what chords share Gmaj7's interval profile",
        "list chords most like E minor",
        "chords with similar interval content to Bm7b5",
        "what voicings are most similar to Am",
        "which chords are closest in interval content to Fmaj7",
        "chords that resemble Cmaj7 harmonically",
    ];

    public bool CanHandle(string message) => false;  // semantic-routing only

    private const int DefaultMaxDistance = 2;
    private const int MaxNeighborsToShow = 8;

    // Single-chord pattern — anchored on "neighbors/near/close/adjacent" + a
    // chord token. Word boundary protects against routing on prose that
    // happens to mention a single chord-letter.
    private static readonly Regex NeighborsPattern =
        new(@"\b(?:icv\s+neighbors?|neighbors?|nearby|close\s+to|near|adjacent|harmonic(?:ally)?\s+(?:close|near|adjacent))\s+(?:to\s+|of\s+)?(?<chord>[A-Ga-g][b#♭♯]?(?:maj|min|m|dim|aug|sus|add|dom)?\d*(?:[b#♭♯]\d+)*°?)\b",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);

    // Reverse anchor: "<chord> ... (icv-)neighbors" / "<chord> ... close"
    private static readonly Regex NeighborsPatternReverse =
        new(@"\b(?<chord>[A-Ga-g][b#♭♯]?(?:maj|min|m|dim|aug|sus|add|dom)?\d*(?:[b#♭♯]\d+)*°?)\b[^.?!]*?\b(?:icv\s+neighbors?|neighbors?|harmonic(?:ally)?\s+(?:close|near|adjacent))\b",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);
```

`ExecuteAsync` tries the first pattern, then the second, takes the chord they capture, and builds its set ([lines 102-118](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IcvNeighborsSkill.cs#L102-L118)). When neither pattern matches, it answers "Ask about ICV-neighbor pitch-class sets near a chord", with a confidence of 0.1 ([lines 254-260](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IcvNeighborsSkill.cs#L254-L260)). On the embedding path, `DefaultRoutingHintProvider` also adds 0.06 to an intent whose rule matches the question; the rule for this skill wants "icv neighbors", "harmonically close" or a few variants ([`DefaultRoutingHintProvider.cs` lines 136-139](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Intents/DefaultRoutingHintProvider.cs#L136-L139)).

## GA's phrasings

The program asks the skill its ten example prompts, the four phrasings of its doc comment ([lines 17-23](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IcvNeighborsSkill.cs#L17-L23)), the two its refusal suggests, and the parked draft's three, and asks `DefaultRoutingHintProvider` which intents each one would boost:

```text
== IcvNeighborsSkill's example prompts and GA's other phrasings for it, at the pin
prompt                                             from           the skill's answer       routing hints, +0.06 each
which chords are most similar to Dm7               anchor         declined                 none
what other chords resemble Cmaj7                   anchor         declined                 none
find chords with a similar sound to G7             anchor         declined                 none
chords related to F major by interval content      anchor         declined                 none
what chords share Gmaj7's interval profile         anchor         declined                 none
list chords most like E minor                      anchor         declined                 none
chords with similar interval content to Bm7b5      anchor         declined                 none
what voicings are most similar to Am               anchor         declined                 none
which chords are closest in interval content to Fmaj7 anchor         declined                 none
chords that resemble Cmaj7 harmonically            anchor         declined                 none
What chords are harmonically close to Cmaj7        doc comment    neighbors of Cmaj7       skill.icvneighbors
Nearby pitch-class sets to C major                 doc comment    declined                 none
Find ICV neighbors of Dm7                          doc comment    neighbors of Dm7         skill.icvneighbors, skill.intervalclassvector
Closest chord to G7 in ICV space                   doc comment    declined                 skill.intervalclassvector
ICV neighbors of Cmaj7                             refusal        neighbors of Cmaj7       skill.icvneighbors, skill.intervalclassvector
what chords are harmonically close to Dm7          refusal        neighbors of Dm7         skill.icvneighbors
Harmonically similar chords to Cmaj7               parked draft   declined                 none
ICV neighbours of [0,3,6,9]                        parked draft   declined                 skill.intervalclassvector
What's close to a half-diminished chord?           parked draft   neighbors of a           skill.interval
anchors 10: answered 0, declined 10, hinted toward skill.icvneighbors 0
CanHandle accepts 0 of them
```

- **The skill declines all ten of its example prompts.** "most similar", "resemble", "closest in interval content": none is a word the patterns read. A question worded like these is the likeliest to reach the skill, since the router compares questions with them, and the skill gives it its refusal. On `main`, the refusal is marked `Declined`, "so a caller may route it to another handler" ([`GuitarAlchemistAgentBase.cs` lines 347-352 on `main`](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Agents/GuitarAlchemistAgentBase.cs#L347-L352)).
- **No hint rule boosts the skill for them,** and two of the doc comment's phrasings, "Nearby pitch-class sets to C major" and "Closest chord to G7 in ICV space", are declined too.
- **The refusal's own suggestion, "ICV neighbors of Cmaj7", is boosted toward two skills,** this one and `skill.intervalclassvector`, whose rule matches "icv" anywhere ([lines 124-126](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Intents/DefaultRoutingHintProvider.cs#L124-L126)).

## The sister skill

`IntervalClassVectorSkill` computes the vector of one chord, and its example prompts were curated in the same pass: it kept the ICV vocabulary as "the discriminator vs the neighbors / delta / path skills, which were de-ICV'd" ([`IntervalClassVectorSkill.cs` lines 43-60](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IntervalClassVectorSkill.cs#L43-L60)). The program asks it its own:

```text
== IntervalClassVectorSkill's example prompts, at the pin
prompt                                             the skill's answer
what is the interval-class vector of Cmaj7         ICV of Cmaj7
interval class vector of Dm7                       ICV of Dm7
compute the ICV of the major scale                 ICV of the major scale
interval-class vector of {0,2,4,5,7,9,11}          ICV of {0,2,4,5,7,9,11}
what's the interval vector for G7                  ICV of G7
how many tritones does Cmaj7 contain               declined
compute the interval-class vector of Fmaj7         ICV of Fmaj7
ICV of the dorian mode                             ICV of the dorian
interval class vector for {0,1,4,8}                ICV of {0,1,4,8}
what's the interval content of Am                  declined
anchors 10: answered 8
```

It answers eight. Its two refusals, "how many tritones does Cmaj7 contain" and "what's the interval content of Am", are the two prompts with neither a set of numbers nor "interval vector", "interval-class vector" or "ICV", which its chord and scale patterns need ([lines 64-77](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IntervalClassVectorSkill.cs#L64-L77)).

## The chords it reads

The chord is a letter, an accidental, one of eight words, digits, alterations and an optional °, then a word boundary. `TryBuildPcSet` builds its set from a table of 16 qualities ([lines 196-232](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IcvNeighborsSkill.cs#L196-L232)):

```csharp
    private static int[] QualityIntervals(string quality)
    {
        var q = quality.ToLowerInvariant().Trim();
        if (q == string.Empty || q == "maj" || q == "major") return [0, 4, 7];
        if (q is "m" or "min" or "minor" or "-") return [0, 3, 7];
        if (q is "dim" or "°" or "o") return [0, 3, 6];
        if (q is "aug" or "+") return [0, 4, 8];
        if (q is "7") return [0, 4, 7, 10];
        if (q is "m7" or "min7" or "-7") return [0, 3, 7, 10];
        if (q is "maj7" or "major7" or "M7") return [0, 4, 7, 11];
        if (q is "m7b5" or "min7b5" or "ø" or "ø7") return [0, 3, 6, 10];
        if (q is "dim7" or "°7" or "o7") return [0, 3, 6, 9];
        if (q is "sus2") return [0, 2, 7];
        if (q is "sus4" or "sus") return [0, 5, 7];
        if (q is "6") return [0, 4, 7, 9];
        if (q is "m6") return [0, 3, 7, 9];
        if (q is "9") return [0, 4, 7, 10, 2];
        if (q is "maj9") return [0, 4, 7, 11, 2];
        if (q is "m9") return [0, 3, 7, 10, 2];
        return [0, 4, 7];
    }
```

The program asks "ICV neighbors of" 27 chords, and compares the set the skill builds with the chord's notes:

```text
== The chords the skill reads, after "ICV neighbors of", at the pin
chord      its notes          read as          notes built        right
C          C E G              C                C E G              yes
Cm         C D# G             Cm               C D# G             yes
Cmaj7      C E G B            Cmaj7            C E G B            yes
CM7        C E G B            CM7              C D# G A#          no
Cmin7      C D# G A#          Cmin7            C D# G A#          yes
Cdom7      C E G A#           Cdom7            C E G              no
Cm7b5      C D# F# A#         Cm7b5            C D# F# A#         yes
Cø7        C D# F# A#         declined         -                  no
Cdim       C D# F#            Cdim             C D# F#            yes
C°         C D# F#            C                C E G              no
Cdim7      C D# F# A          Cdim7            C D# F# A          yes
C°7        C D# F# A          C°               C D# F#            no
Caug       C E G#             Caug             C E G#             yes
C+         C E G#             C                C E G              no
Cadd9      C D E G            Cadd9            C E G              no
C7sus4     C F G A#           declined         -                  no
C7b9       C C# E G A#        C7b9             C E G              no
C7#9       C D# E G A#        C7#9             C E G              no
Cm11       C D D# F G A#      Cm11             C E G              no
C13        C D E G A A#       C13              C E G              no
CmMaj7     C D# G B           declined         -                  no
C5         C G                C5               C E G              no
F#m7b5     C E F# A           F#m7b5           C E F# A           yes
B♭7        D F G# A#          B♭7              D F G# A#          yes
C minor    C D# G             C                C E G              no
A minor    C E A              A                C# E A             no
a Cmaj7    C E G B            a                C# E A             no
chords 27: built right 10
```

- **"CM7", a major seventh, is built as C minor seventh.** The suffix is lowercased before the table is read, so the `"M7"` of line 221 can never match, and "m7" does.
- **An unknown suffix gives a major triad, without a warning.** Cdom7, Cadd9, C7b9, C7#9, Cm11, C13 and C5 are all answered as C E G; "C minor" and "A minor" are read as C and A, since a space ends the chord.
- **° and + end the chord.** They aren't letters, so the word boundary falls before them: C° and C+ become C, and C°7 the triad C°, since a boundary also falls between ° and 7. ø is a letter, so Cø7 has no boundary after its C and is declined, like C7sus4 and CmMaj7, whose suffixes the pattern doesn't have.
- **"a" is a chord.** The pattern ignores case, so the article in "close to a half-diminished chord", the parked draft's phrasing, is read as A major, and so is the one in "ICV neighbors of a Cmaj7".

## The neighbors

The skill asks `FindNearby` for every set within 3, recomputes each distance itself, and keeps the first eight at distance 1 or 2 ([lines 120-140](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IcvNeighborsSkill.cs#L120-L140)):

```csharp
        var sourceIcv = source.IntervalClassVector;
        var rawNeighbors = grothendieck.FindNearby(source, DefaultMaxDistance + 1).ToList();

        var neighbors = rawNeighbors
            .Select(n => (n.Set, Delta: ComputeTrueDelta(sourceIcv, n.Set.IntervalClassVector)))
            .Where(t => !ReferenceEquals(t.Set, source))           // skip the source itself
            .Where(t => t.Delta.l1 > 0)                            // skip exact ICV-identical (same set class)
            .Where(t => t.Delta.l1 <= DefaultMaxDistance)
            .OrderBy(t => t.Delta.l1)
            .Take(MaxNeighborsToShow)
            .ToList();
```

`FindNearby` scans `PitchClassSet.Items` in the order of their ids, which are their bitmasks, and sorts what it keeps by a cost, the distance times 0.6, keeping that order between equal costs ([`GrothendieckService.cs` lines 38-90](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Atonal/Grothendieck/GrothendieckService.cs#L38-L90)). The program counts, for each of the skill's 16 qualities on C, the sets at distance 1 or 2, and compares the eight rows with the first eight of them by id:

```text
== The neighbors the skill lists for a chord, at the pin
chord   its vector      sets 1-2 off  set classes  of notes  rows   of notes  L1, cost   set classes   with a C   the first by id
C       <0 0 1 1 1 0>   108           6            2, 3      8      2, 3      2, 1.20    5             6          yes
Cm      <0 0 1 1 1 0>   108           6            2, 3      8      2, 3      2, 1.20    5             6          yes
Cdim    <0 0 2 0 0 1>   18            2            2         8      2         2, 1.20    2             2          yes
Caug    <0 0 0 3 0 0>   12            1            2         8      2         2, 1.20    1             2          yes
C7      <0 1 2 1 1 1>   132           6            4         8      4         2, 1.20    5             8          yes
Cm7     <0 1 2 1 2 0>   72            3            4         8      4         2, 1.20    3             6          yes
Cmaj7   <1 0 1 2 2 0>   72            4            4         8      4         2, 1.20    4             6          yes
Cm7b5   <0 1 2 1 1 1>   132           6            4         8      4         2, 1.20    5             8          yes
Cdim7   <0 0 4 0 0 2>   0             0                      0      -         -          0             0          -
Csus2   <0 1 0 0 2 0>   48            3            2, 3      8      2, 3      2, 1.20    3             4          yes
Csus4   <0 1 0 0 2 0>   48            3            2, 3      8      2, 3      2, 1.20    3             4          yes
C6      <0 1 2 1 2 0>   72            3            4         8      4         2, 1.20    3             6          yes
Cm6     <0 1 2 1 1 1>   132           6            4         8      4         2, 1.20    5             8          yes
C9      <0 3 2 2 2 1>   24            1            5         8      5         2, 1.20    1             4          yes
Cmaj9   <1 2 2 2 3 0>   72            3            5         8      5         2, 1.20    3             5          yes
Cm9     <1 2 2 2 3 0>   72            3            5         8      5         2, 1.20    3             5          yes
the rows for C:
  {0,3}     C D#       2-3    <0 0 1 0 0 0>
  {0,4}     C E        2-4    <0 0 0 1 0 0>
  {1,4}     C# E       2-3    <0 0 1 0 0 0>
  {0,1,4}   C C# E     3-3    <1 0 1 1 0 0>
  {0,3,4}   C D# E     3-3    <1 0 1 1 0 0>
  {0,5}     C F        2-5    <0 0 0 0 1 0>
  {1,5}     C# F       2-4    <0 0 0 1 0 0>
  {0,1,5}   C C# F     3-4    <1 0 0 1 1 0>
Cdim7: No pitch-class sets within L1 = 2. Try a wider radius.
chords 192: qualities whose 12 roots get the same rows 16 of 16; different answers 10, different vectors 10
```

- **Every row is at distance 2, with a cost of 1.20.** Between two sets of the same size the distance is even, and a set of another size is at least 3 away from a chord of three notes or more, except a two-note set from a triad. "Sorted by harmonic cost" sorts nothing, and the eight rows are the first eight by bitmask, which favors the lowest pitch classes: six of C's eight rows hold a C, and none goes above F.
- **The rows depend on the chord's vector only.** The 192 chords of 12 roots and 16 qualities get 10 different answers, one per vector: C and F#m get the same eight rows.
- **A triad's neighbors are mostly intervals.** Five of C's eight rows are two-note sets, and the three others each hold a semitone, which C major doesn't. Cdim's and Caug's rows are two-note sets only.
- **Cdim7 gets no neighbor, and the advice to "Try a wider radius",** though the radius is a constant, `DefaultMaxDistance` ([line 76](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IcvNeighborsSkill.cs#L76)), that the user can't change.

The music theory course found that `ga_icv_neighbors`, the MCP tool on the same service, printed twelve lines of C's own set class for C at the pin; on `main` it lists each set class once, at its real distance ([`ChordAtonalTool.cs` lines 337-348 on `main`](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/GaMcpServer/Tools/ChordAtonalTool.cs#L337-L348)). The skill computed real distances from the start ([lines 122-129](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IcvNeighborsSkill.cs#L122-L129)), and still lists several transpositions of one set class: C's eight rows hold five set classes.

## The parked skill draft

`skills-dev/_pending-tools/icv-neighbors/DRAFT.md` is a chatbot skill written to call `ga_icv_neighbors`, parked like those of lessons 19 to 21 ([`skills-dev/_pending-tools/README.md` line 52](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/README.md#L52)):

- it says the tool is "not yet implemented in Common/GA.Business.ML/Agents/Mcp/" and points to `Common/GA.Business.ML/Agents/Mcp/AtonalMcpTools.cs` (lines [18](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/icv-neighbors/DRAFT.md#L18) and [72](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/icv-neighbors/DRAFT.md#L72)), a file GA doesn't have; the tool is in `GaMcpServer/Tools/ChordAtonalTool.cs` ([lines 220-254](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/ChordAtonalTool.cs#L220-L254));
- it expects `chord`, `topK` and `metric`, with Euclidean, Manhattan or cosine distances, and an answer of `Neighbours` ([lines 31-41](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/icv-neighbors/DRAFT.md#L31-L41)); the tool takes `symbol` and `maxDistance` and returns lines of text;
- its example gives Cmaj7's vector and three neighbors with a distance each ([lines 53-58](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/icv-neighbors/DRAFT.md#L53-L58)):

```text
== The parked draft's example for Cmaj7, at the pin
chord                  notes          vector           Forte  L1     the draft
Cmaj7                  C E G B        <1 0 1 2 2 0>    4-20   0      [1, 0, 1, 2, 2, 0], 4-20
Am7                    A C E G        <0 1 2 1 2 0>    4-26   4      [1,0,1,2,2,0], distance 0.0, same set class
Cm9 without its root   D# G A# D      <1 0 1 2 2 0>    4-20   0      distance 0.6
Fmaj7                  F A C E        <1 0 1 2 2 0>    4-20   0      distance 0.0, same set class
```

Am7 isn't of Cmaj7's set class: it is A C E G, C6's notes, 4-26, at distance 4. Cm9 without its root is E♭ major seventh, of Cmaj7's class, at distance 0, not 0.6. Of the draft's three phrasings, the skill declines two and reads A major in the third.

## Where the course stops

- **The router isn't run:** it needs the embeddings. The lesson asks the skill the questions the router is likeliest to send it, its own example prompts.
- **The chords' notes are the course's,** a textbook's for each symbol.
- **`ga_icv_neighbors` isn't run here;** the music theory course runs it.
- **The program calls the skills' methods directly,** not through the chatbot.

## Reported upstream

- Reported after this lesson was written, in GA issue [#798](https://github.com/GuitarAlchemist/ga/issues/798): the example prompts the patterns don't read, the chords the table builds wrong, the neighbors listed by bitmask, and the parked skill draft.

## Exercises

1. "which chords are most similar to Dm7" is one of the skill's example prompts. Why does the skill decline it?
2. C's rows include `{0,4}`, C and E. What is the distance between C's vector, `<0 0 1 1 1 0>`, and this set's, `<0 0 0 1 0 0>`? Why can't a neighbor of Cmaj7 have three notes?
3. Why do C and F#m get the same eight rows?
4. "ICV neighbors of CM7" answers for C minor seventh. Which line turns M7 into m7?

<details>
<summary>Solutions</summary>

1. Its patterns need "neighbors", "nearby", "close to", "near" or "adjacent" right before the chord, "neighbors" after it, or "harmonically close", "near" or "adjacent" on either side ([lines 82-89](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IcvNeighborsSkill.cs#L82-L89)); the prompt has none of them, so `ExecuteAsync` gives the refusal.
2. 1 + 1 = 2: C's vector counts a minor third, E–G, and a fifth, C–G, that C–E lacks. A vector counts the intervals between every pair of notes: 6 for four notes, 3 for three, so a three-note set is at least 3 away from Cmaj7, more than the skill's 2.
3. Both are triads of the same set class, with the vector `<0 0 1 1 1 0>`. `FindNearby` compares vectors, not notes, and returns the sets by bitmask, so the eight first at distance 2 are the same.
4. Line 214, `quality.ToLowerInvariant()`: "M7" becomes "m7", which line 220 reads as a minor seventh.

</details>

## Key takeaways

- Routing anchors and the parser that follows them are one contract: rewording one without the other sends questions to a refusal.
- A skill's example prompts make the first test of the skill.
- A table that falls back to a major triad answers questions it can't read.
- "Sorted by cost" means little when every cost ties: the order is then the order of enumeration.
- Neighbors in vector space depend on the vector, not on the chord: every chord of a set class gets the same list.

## Sources

- GuitarAlchemist/ga at [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `Common/GA.Business.ML/Agents/Skills/IcvNeighborsSkill.cs`, `Common/GA.Business.ML/Agents/Skills/IntervalClassVectorSkill.cs`, `Common/GA.Business.ML/Agents/Intents/DefaultRoutingHintProvider.cs`, `Common/GA.Business.ML/Agents/Intents/SemanticIntentRouter.cs`, `Common/GA.Domain.Services/Atonal/Grothendieck/GrothendieckService.cs`, `Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs`, `GaMcpServer/Tools/ChordAtonalTool.cs`, `skills-dev/_pending-tools/icv-neighbors/DRAFT.md`, `CLAUDE.md`.
- GuitarAlchemist/ga at [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/tree/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a): the same skills, with their refusals marked `Declined`, and `ChordAtonalTool.cs`.
- The course's programs: `code/ga-ai/GaAi/Lesson22.cs`, `code/ga-ai/GaMain/Program.cs`, `code/ga-ai/Shared/IcvNeighborsProbe.cs`.
