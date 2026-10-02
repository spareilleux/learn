---
title: "Lesson 21: The voicing search"
description: "Guitar Alchemist's MCP server searches its OPTIC-K voicing index with ga_search_voicings, and lists what the search reads with ga_voicing_vocabulary: 18 roots, 45 chord qualities, 23 modes and 188 tags. The mode never reaches the query's vector: C Lydian answers as C does, and Lydian alone answers the index's first ten voicings, every score 0. The 188 tags set 12 bits, so jazz answers as rock-guitar and rootless as shell-voicing, and none of the 100 voicings answered for ten seventh chords with rootless is rootless. Words like for, the and what pass for tags, and no query can score above 0.70, where the skill's example shows 0.9831."
sidebar:
  label: 21. The voicing search
  order: 21
---

[Lesson 20](../20-generated-progressions/) ended on a note of `ga_generate_progression`: "Compose by passing each chord to ga_search_voicings". `ga_search_voicings` is `GaMcpServer`'s search of the OPTIC-K index: it reads a chord, a mode and style or technique tags out of a query, turns them into a query vector, and returns the nearest voicings ([`VoicingSearchTool.cs` lines 92-236](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingSearchTool.cs#L92-L236)). A second tool, `ga_voicing_vocabulary`, lists what the search reads, so that an agent can rewrite its user's words before searching ([`VoicingVocabularyTool.cs` lines 24-78](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingVocabularyTool.cs#L24-L78)). GA's `voicing-search` skill tells Claude Code to call the vocabulary once, then the search ([`.claude/skills/voicing-search/SKILL.md` line 30](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/.claude/skills/voicing-search/SKILL.md#L30)). Lessons 3 and 16 opened the reader and the search from the chatbot's side; this lesson asks the tool.

All GA links point to commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), the course's pin, unless they name another. On GA's `main` at [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/commit/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) (2026-10-01), the two tools differ only in a comment and a description, and the reader and the tag registry are unchanged; the query encoder and the search changed, so `GaMain` asks again the questions whose answers depend on them. The program compiles GA's own `VoicingSearchTool.cs`, which now also serves lessons 19 and 20 in place of the course's stand-in. It finds the course's index through `GA_OPTICK_INDEX_PATH` ([lines 64-80](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingSearchTool.cs#L64-L80)), and its telemetry log is switched off through `GA_VOICING_NO_TELEMETRY` ([`VoicingTelemetryLog.cs` lines 33-36](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/VoicingTelemetryLog.cs#L33-L36)). The output comes from:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l21
dotnet run --project code/ga-ai/GaMain -c Release -- l21
```

## How the tool reads a query

`TypedMusicalQueryExtractor` reads the query one word at a time ([lines 86-148](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/TypedMusicalQueryExtractor.cs#L86-L148)). The first word that starts with a capital and parses as a chord is the chord. Then a word, or two, from a list of 23 modes is the mode, an instrument is a filter, a few filler words like "chord" and "voicing" are skipped, and any other word of three letters or more that `SymbolicTagRegistry` knows is a tag:

```csharp
            // 2. Mode: single-word modes or two-word ("harmonic minor").
            if (modeName is null)
            {
                if (KnownModesSet.Contains(tok))
                {
                    modeName = tok;
                    continue;
                }
                if (i + 1 < tokens.Length)
                {
                    var twoWord = tok + " " + tokens[i + 1];
                    if (KnownModesSet.Contains(twoWord))
                    {
                        modeName = twoWord;
                        continue;
                    }
                }
            }

            // 3. Instrument filter — first hit wins. Consumes the token so it never
            //    leaks into the tag stream (where "bass" would otherwise miss the
            //    registry and silently return no voicings from the wrong population).
            if (instrument is null && InstrumentAliases.TryGetValue(tok, out var inst))
            {
                instrument = inst;
                continue;
            }

            // 4. Linguistic filler ("chord", "voicing", "shape", …) never becomes a tag.
            //    Without this, the registry's substring fallback maps "chord" onto the
            //    first tag whose name contains it and poisons the SYMBOLIC vector.
            if (TagStopWords.Contains(tok))
            {
                continue;
            }

            // 5. Symbolic tag — matches the corpus's vocabulary (case-insensitive,
            //    hyphen-normalized, with prefix/substring fallback). Require tokens
            //    ≥ 3 chars so the registry's substring-contains fallback doesn't fire
            //    on stop-words ("a", "me", "to") that happen to be substrings of a tag.
            if (tok.Length >= 3 && registry.GetBitIndex(tok).HasValue)
            {
                tags.Add(tok.ToLowerInvariant());
            }
```

The registry knows a word when it is one of its tags, or when either contains the other ([`SymbolicTagRegistry.cs` lines 196-220](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Config/Configuration/SymbolicTagRegistry.cs#L196-L220)):

```csharp
    public int? GetBitIndex(string tag)
    {
        if (string.IsNullOrWhiteSpace(tag))
        {
            return null;
        }

        var normalized = tag.ToLowerInvariant().Trim().Replace(" ", "-").Replace("_", "-");

        if (_tagToBitMap.TryGetValue(normalized, out var bit))
        {
            return bit;
        }

        // Partial match fallback (e.g. "sweep" matches "sweep-picking")
        foreach (var kvp in _tagToBitMap)
        {
            if (normalized.Contains(kvp.Key) || kvp.Key.Contains(normalized))
            {
                return kvp.Value;
            }
        }

        return null;
    }
```

`MusicalQueryEncoder` then turns the reading into a vector ([`MusicalQueryEncoder.cs` lines 43-108](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/MusicalQueryEncoder.cs#L43-L108)). STRUCTURE, MODAL and ROOT come from the chord's pitch classes, SYMBOLIC from the tags, and MORPHOLOGY and CONTEXT stay at zero. The encoder never reads the mode:

```csharp
        // SYMBOLIC — technique/style tags
        if (q.Tags is { Count: > 0 })
        {
            var symbolicVec = SymbolicVectorService.ComputeEmbedding(q.Tags);
            EmbeddingSchema.WriteInto(raw, "SYMBOLIC", symbolicVec);
        }

        // ROOT — 12-dim one-hot (v1.8). Query carries root signal IF the chord symbol
        // specified one; otherwise zero. Low weight (0.05) in the weighted cosine, so
        // root match adds a small discriminating boost on top of set-class-level STRUCTURE.
        if (root2.HasValue)
        {
            var rootVec = RootVectorService.ComputeEmbedding(root2);
            EmbeddingSchema.WriteInto(raw, "ROOT", rootVec);
        }

        // MORPHOLOGY (24 dim) and CONTEXT (12 dim) remain zero — a text query carries no
        // fretboard realization or temporal-motion information. Their cosine contribution
        // is therefore zero, which is the correct behavior.

        return ExtractCompactAndNormalize(raw);
```

`SymbolicVectorService` gives the tags 12 dimensions, one per bit of the registry, and sets the bit of each tag to 1 ([`SymbolicVectorService.cs` lines 13-32](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/Services/SymbolicVectorService.cs#L13-L32)). The answer repeats the reading under `interpreted`, mode included, "to confirm the parser understood what the user wanted", as the skill puts it ([`SKILL.md` line 92](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/.claude/skills/voicing-search/SKILL.md#L92)).

## The vocabulary

`ga_voicing_vocabulary` returns the roots and chord qualities of `ChordPitchClasses`, the reader's modes, and every name the registry knows as a tag. The registry gives each tag a bit, by the file or the category it comes from ([`SymbolicTagRegistry.cs` lines 46-111](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Config/Configuration/SymbolicTagRegistry.cs#L46-L111)). The program reads the vocabulary, groups the tags by bit, and asks the search each entry alone:

```text
== What ga_voicing_vocabulary lists, and how ga_search_voicings reads it, at the pin
roots 18, chord-quality suffixes 45, modes 23, symbolic tags 188
the query's SYMBOLIC partition: 12 dimensions; a tag sets the one its bit names
bit  where the registry takes it from                     tags  the first four
0    SemanticNomenclature, Structure                      6     closed-voicing, dense, open-voicing, resonant
1    SemanticNomenclature, Register                       5     register:high, register:low, register:mid, register:mid-high
2    SemanticNomenclature, Playability                    2     beginner-friendly, campfire-chord
3    GuitarTechniques.yaml                                16    bending, caged-system, chicken-picking, economy-picking
4    ArticulationTechniques.yaml                          4     accents, legato, slides, staccato
5    SemanticNomenclature, CAGED                          5     a-shape, c-shape, d-shape, e-shape
6    SemanticNomenclature, Mood                           8     aggressive, bright, dreamy, melancholy
7    SemanticNomenclature, Genre                          4     flamenco, jazz, neo-soul, rock-guitar
8    AdvancedHarmony.yaml                                 23    added-note-chords, augmented-scale, cluster-chords, eleventh-chords
9    VoiceLeading.yaml                                    28    augmented-fourth, chord-melody-technique, chromatic-voice-leading, contrary-motion
10   AtonalTechniques.yaml, KeyModulationTechniques.yaml  27    chromatic-mediant, chromatic-trichord, circle-of-fifths-modulation, direct-modulation
11   IconicChords                                         60    a-hard-day's-night-chord, add9(no3), beatles-chord, beatles-intro-chord
entries listed twice, with and without hyphens: 8, cmaj9floating, drop2voicings, drop3voicings, messiaen’smode2(octatonic)
tags that also give the query a chord, a famous chord's: 53
entries read otherwise when typed alone:
  g5: nothing
  schoenberg-op.16-chord: tags schoenberg-op 16-chord
  schoenbergop.16chord: tags schoenbergop 16chord
  harmonic minor: mode harmonic minor, tags minor
  lydian dominant: mode lydian, tags dominant
  melodic minor: mode melodic minor, tags minor
  phrygian dominant: mode phrygian, tags dominant
  whole tone: mode whole tone, tags tone
```

- **188 tags, 12 bits.** A tag sets its bit, and nothing else: `jazz`, `rock-guitar`, `flamenco` and `neo-soul` set the same one, and the 60 famous chords another.
- **Eight entries are another one without its hyphens.** The registry adds a copy without hyphens to every tag with a digit, so that "drop2" finds the bit of `drop-2-voicings` ([lines 176-193](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Config/Configuration/SymbolicTagRegistry.cs#L176-L193)); the vocabulary lists both.
- **53 tags also give the query a chord.** When a query names no chord, a famous chord's tag gives it that chord's notes: "Hendrix chord" searches for an E7#9 ([`TypedMusicalQueryExtractor.cs` lines 157-174](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/TypedMusicalQueryExtractor.cs#L157-L174)).
- **Three tags are read otherwise, and five modes read a tag.** `g5` is shorter than the three letters a tag needs, and the `.` of `schoenberg-op.16-chord` splits it in two. "lydian dominant" and "phrygian dominant" are read as Lydian and Phrygian, since one word is tried before two, and "dominant" becomes a tag. "harmonic minor", "melodic minor" and "whole tone" keep their mode and add "minor" or "tone" as a tag.

## The vocabulary's own examples

The vocabulary ends with five examples: what a user said, and the query an agent should send instead ([`VoicingVocabularyTool.cs` lines 63-70](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingVocabularyTool.cs#L63-L70)). The program asks both:

```text
== The vocabulary's five examples, as the user said them and as it rewrites them, at the pin
the user said                read as                            rewritten         read as                    same voicings   top scores
Cmaj7 jazz voicing           chord Cmaj7, tags jazz             Cmaj7 jazz        chord Cmaj7, tags jazz     yes             0.5085, 0.5085
F# Lydian drop 2             chord F#, mode Lydian, tags drop   F# Lydian drop2   chord F#, mode Lydian, tags drop2 yes             0.5310, 0.5310
rootless Dm7                 chord Dm7, tags rootless           Dm7 rootless      chord Dm7, tags rootless   yes             0.5085, 0.5085
something jazzy in F minor   chord F, mode minor, tags jazzy    Fm jazz           chord Fm, tags jazz        no              0.4810, 0.4810
shell voicing for G7         chord G7, tags shell for           G7 shell          chord G7, tags shell       yes             0.4932, 0.5078
F minor, read as chord F, mode minor: x-x-x-2-1-1 F/A, x-x-3-2-1-1 F, x-0-x-x-1-1 F/A
Fm, read as chord Fm: x-x-x-1-1-1 Fm/Ab, x-x-3-1-1-1 Fm, x-3-x-1-x-1 Fm/C
```

```text
== The vocabulary's five examples, as the user said them and as it rewrites them, on main
the user said                read as                            rewritten         read as                    same voicings   top scores
Cmaj7 jazz voicing           chord Cmaj7, tags jazz             Cmaj7 jazz        chord Cmaj7, tags jazz     yes             0.6447, 0.6447
F# Lydian drop 2             chord F#, mode Lydian, tags drop   F# Lydian drop2   chord F#, mode Lydian, tags drop2 yes             0.6500, 0.6500
rootless Dm7                 chord Dm7, tags rootless           Dm7 rootless      chord Dm7, tags rootless   yes             0.6408, 0.6408
something jazzy in F minor   chord F, mode minor, tags jazzy    Fm jazz           chord Fm, tags jazz        no              0.6000, 0.6000
shell voicing for G7         chord G7, tags shell for           G7 shell          chord G7, tags shell       yes             0.6316, 0.6447
F minor, read as chord F, mode minor: x-x-x-2-1-1 F/A, x-x-3-2-1-x F, x-x-3-2-1-1 F
Fm, read as chord Fm: x-x-x-1-1-1 Fm/Ab, x-x-3-1-1-x Fm, x-x-3-1-1-1 Fm
```

- **"something jazzy in F minor" gets F major voicings, at the pin and on `main`.** The reader takes "F" for a chord, a major triad, and "minor" for a mode, which the vector ignores. "Fm" gets F minor.
- **"shell voicing for G7" reads "for" as a tag.** It gets the same ten voicings as "G7 shell", with a lower top score.
- The three other examples get the same voicings as their rewrite.

## Modes

The tool's description promises "mode names (Lydian, Dorian)" ([line 95](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingSearchTool.cs#L95)), and the skill describes the MODAL partition as "mode flavor" ([`SKILL.md` line 14](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/.claude/skills/voicing-search/SKILL.md#L14)). The program asks four chords followed by each of the 23 modes, then each mode alone:

```text
== The 23 modes after a chord, and alone, at the pin
chord   modes  the same ten voicings as alone the others, as read
C       23     19                             harmonic minor: mode harmonic minor, tags minor; lydian dominant: mode lydian, tags dominant; melodic minor: mode melodic minor, tags minor; phrygian dominant: mode phrygian, tags dominant
Am      23     19                             harmonic minor: mode harmonic minor, tags minor; lydian dominant: mode lydian, tags dominant; melodic minor: mode melodic minor, tags minor; phrygian dominant: mode phrygian, tags dominant
G7      23     19                             harmonic minor: mode harmonic minor, tags minor; lydian dominant: mode lydian, tags dominant; melodic minor: mode melodic minor, tags minor; phrygian dominant: mode phrygian, tags dominant
Dm7     23     18                             harmonic minor: mode harmonic minor, tags minor; lydian dominant: mode lydian, tags dominant; melodic minor: mode melodic minor, tags minor; phrygian dominant: mode phrygian, tags dominant; whole tone: mode whole tone, tags tone
modes alone: 18 of 23 answer with every score 0.0000, all the same ten voicings: yes, the index's first ten: yes
  x-x-x-0-0-0 Em/G, x-x-x-0-0-1 G7(shell), x-x-x-0-0-2 Gmaj7(shell), x-x-x-0-0-3 G + B (Major 3rd), x-x-x-0-1-0 C/G, x-x-x-0-1-1 Csus4/G, x-x-x-0-1-2 C5/G, x-x-x-0-1-3 C5, x-x-x-0-2-0 Dbdim/G, x-x-x-0-2-1 Gm7b5
  harmonic minor: mode harmonic minor, tags minor, top score 0.0577
  lydian dominant: mode lydian, tags dominant, top score 0.0577
  melodic minor: mode melodic minor, tags minor, top score 0.0577
  phrygian dominant: mode phrygian, tags dominant, top score 0.0577
  whole tone: mode whole tone, tags tone, top score 0.0577
```

```text
== The 23 modes after a chord, and alone, on main
chord   modes  the same ten voicings as alone the others, as read
C       23     19                             harmonic minor: mode harmonic minor, tags minor; lydian dominant: mode lydian, tags dominant; melodic minor: mode melodic minor, tags minor; phrygian dominant: mode phrygian, tags dominant
Am      23     19                             harmonic minor: mode harmonic minor, tags minor; lydian dominant: mode lydian, tags dominant; melodic minor: mode melodic minor, tags minor; phrygian dominant: mode phrygian, tags dominant
G7      23     21                             lydian dominant: mode lydian, tags dominant; phrygian dominant: mode phrygian, tags dominant
Dm7     23     18                             harmonic minor: mode harmonic minor, tags minor; lydian dominant: mode lydian, tags dominant; melodic minor: mode melodic minor, tags minor; phrygian dominant: mode phrygian, tags dominant; whole tone: mode whole tone, tags tone
modes alone: 18 of 23 answer with every score 0.0000, all the same ten voicings: yes, the index's first ten: yes
  x-x-x-0-0-0 Em/G, x-x-x-0-0-1 G7(shell), x-x-x-0-0-2 Gmaj7(shell), x-x-x-0-0-3 G + B (Major 3rd), x-x-x-0-1-0 C/G, x-x-x-0-1-1 Csus4/G, x-x-x-0-1-2 C5/G, x-x-x-0-1-3 C5, x-x-x-0-2-0 Dbdim/G, x-x-x-0-2-1 Gm7b5
  harmonic minor: mode harmonic minor, tags minor, top score 0.0577
  lydian dominant: mode lydian, tags dominant, top score 0.0577
  melodic minor: mode melodic minor, tags minor, top score 0.0577
  phrygian dominant: mode phrygian, tags dominant, top score 0.0577
  whole tone: mode whole tone, tags tone, top score 0.0577
```

- **A mode changes nothing.** "C Lydian" answers the same ten voicings as "C". The only modes that change an answer are modes that read a tag. MODAL is computed from the chord's notes, and the mode's name is left in `interpreted`.
- **A mode alone answers the index's first ten voicings.** With no chord and no tag, every partition of the query is zero: 18 of the 23 modes get a score of 0 for every voicing, and the search returns the first ten it reads. `HasIntent` counts a mode as something to search for ([lines 238-242](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingSearchTool.cs#L238-L242)), so the tool never gives its answer for a query it can't read, "No chord, mode, or known tag recognized" ([lines 155-177](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingSearchTool.cs#L155-L177)). The vocabulary itself counts on "STRUCTURE and/or MODAL partitions" to rank voicings ([`VoicingVocabularyTool.cs` lines 72-76](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingVocabularyTool.cs#L72-L76)), and only a chord fills them.

## Tags

The skill presents the tags as technique and style, "drop2, shell, jazz, rootless" ([`SKILL.md` line 3](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/.claude/skills/voicing-search/SKILL.md#L3)). The program adds each of the 188 tags to three chords:

```text
== The 188 symbolic tags after a chord, at the pin
chord   tags   different answers  the same ten as the chord alone  bits whose tags all answer alike
Cmaj7   188    7                  53                               12 of 12
Dm7     188    7                  53                               12 of 12
G7      188    5                  76                               12 of 12
for Cmaj7, the bits whose tags change nothing: 3, 4, 5, 10
for Cmaj7, jazz and rock-guitar: the same answer yes
for Cmaj7, shell-voicing and rootless: the same answer yes
for Cmaj7, jazz and shell-voicing: the same answer no
```

```text
== The 188 symbolic tags after a chord, on main
chord   tags   different answers  the same ten as the chord alone  bits whose tags all answer alike
Cmaj7   188    5                  76                               12 of 12
Dm7     188    4                  53                               12 of 12
G7      188    3                  135                              12 of 12
for Cmaj7, the bits whose tags change nothing: 3, 4, 5, 8, 10
for Cmaj7, jazz and rock-guitar: the same answer yes
for Cmaj7, shell-voicing and rootless: the same answer yes
for Cmaj7, jazz and shell-voicing: the same answer yes
```

- **188 tags give Cmaj7 and Dm7 seven answers at the pin, and G7 five,** the chord's own answer among them. Within each bit, the tags read as typed all give the same answer: `jazz` answers as `rock-guitar`, and `shell-voicing` as `rootless`. On `main` the answers are fewer still, and `jazz` and `shell-voicing` give Cmaj7 the same answer too.
- **Some bits change nothing.** For Cmaj7, the tags of bits 3, 4, 5 and 10, among them `caged-system`, `legato` and the CAGED shapes, leave the answer as it was; on `main`, bit 8 joins them.

`rootless` and `shell-voicing` come from the same category of `SemanticNomenclature.yaml`, Structure, and set bit 0 ([lines 129-140](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Config/SemanticNomenclature.yaml#L129-L140)). A rootless voicing leaves out the chord's root. The program asks ten seventh chords with "rootless", and counts the voicings of the index that play three notes or more, all of them the chord's, none of them its root:

```text
== "rootless" after a seventh chord, at the pin
chord   ten voicings, rootless rootless in the index  the first three
Cmaj7   0 of 10                63                     x-2-2-x-1-x Cmaj7(shell)/B, 0-2-x-x-1-x Cmaj7(shell)/E, 0-2-2-x-1-x Cmaj7(shell)/E
Dm7     0 of 10                35                     x-3-3-x-3-x Dm7(shell)/C, 1-3-x-x-3-x Dm7(shell)/F, 1-3-0-x-x-x Dm7(shell)/F
Em7     0 of 10                35                     x-x-x-0-3-0 Em7(shell)/G, x-x-0-0-x-0 Em7(shell)/D, x-x-0-0-3-0 Em7(shell)/D
Fmaj7   0 of 10                35                     x-x-2-2-x-1 Fmaj7(shell)/E, 0-x-3-2-x-1 Fmaj7(shell)/E, 0-0-3-x-x-1 Fmaj7(shell)/E
G7      0 of 10                19                     x-2-3-x-x-3 G7(shell)/B, 1-x-x-x-0-3 G7(shell)/F, 1-x-x-0-0-3 G7(shell)/F
Am7     0 of 10                63                     3-3-x-2-x-x Am7(shell)/G, x-3-2-2-x-x Am/C, 0-3-x-2-x-x Am/E
C7      0 of 10                35                     x-x-2-3-1-x C7(shell)/E, x-1-2-x-1-x C7(shell)/Bb, 0-x-x-3-1-x C7(shell)/E
D7      0 of 10                15                     2-3-x-x-3-x D7(shell)/Gb, 2-3-0-x-x-x D7(shell)/Gb, 2-3-0-x-3-x D7(shell)/Gb
E7      0 of 10                5                      x-x-x-1-3-0 E7(shell)/Ab, 0-x-0-1-3-0 E7(shell), x-x-0-1-x-0 E7(shell)/D
A7      0 of 10                21                     3-0-x-2-x-x G + A (Major 2nd), 3-x-2-2-x-x A5/G, 3-0-2-2-x-x A5/G
voicings answered 100: rootless 0
```

```text
== "rootless" after a seventh chord, on main
chord   ten voicings, rootless rootless in the index  the first three
Cmaj7   0 of 10                63                     x-2-2-x-1-3 Cmaj7/B, x-3-2-x-0-3 Cmaj7, x-3-2-0-0-3 Cmaj7
Dm7     0 of 10                35                     x-3-0-2-3-1 Dm7/C, 1-3-x-2-3-x Dm7/F, 1-3-x-2-3-1 Dm7/F
Em7     0 of 10                35                     x-2-0-0-x-0 Em7/B, x-2-0-0-0-0 Em7/B, x-2-0-0-3-0 Em7/B
Fmaj7   0 of 10                35                     1-0-3-2-1-0 Fmaj7, x-3-2-2-x-1 Fmaj7/C, x-3-2-2-1-1 Fmaj7/C
G7      0 of 10                19                     x-2-3-0-3-1 G7/B, 1-2-x-x-3-3 G7/F, 1-2-x-0-3-1 G7/F
Am7     0 of 10                63                     x-3-2-2-1-3 Am7/C, 0-3-x-2-1-3 Am7/E, 0-3-2-2-1-3 Am7/E
C7      0 of 10                35                     x-x-2-3-1-3 C7/E, x-1-2-x-1-3 C7/Bb, x-1-2-0-1-3 C7/Bb
D7      0 of 10                15                     x-3-0-2-1-2 D7/C, 2-3-x-2-3-2 D7/Gb, 2-3-0-2-1-x D7/Gb
E7      0 of 10                5                      x-2-2-1-3-x E7/B, x-x-0-1-0-0 E7/D, x-2-x-1-3-0 E7/B
A7      0 of 10                21                     x-x-2-2-2-3 A7/E, x-0-x-0-2-0 A7, x-0-2-x-2-3 A7
voicings answered 100: rootless 0
```

- **None of the 100 voicings answered is rootless, at the pin or on `main`,** while the index holds between 5 and 63 for each chord. At the pin, the first answers are voicings GA's analysis calls shells, root included. The tag can only move SYMBOLIC, worth 0.10 of the score; the query's STRUCTURE, worth 0.45, holds the whole chord, root included.

## Words read as tags

A word becomes a tag when it contains a tag, or a tag contains it; the vocabulary calls this a "substring fallback" ([`VoicingVocabularyTool.cs` lines 58-61](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingVocabularyTool.cs#L58-L61)). The program asks GA's own example queries, from the tool's description, the skill and the parked draft, then three of the course's:

```text
== GA's example queries, and words read as tags, at the pin
query                                     read as                            top score    words no tag spells, and the tag they match
Cmaj7 drop2 jazz                          chord Cmaj7, tags drop2 jazz       0.4938       drop2 → drop2voicings
F# Lydian                                 chord F#, mode Lydian              0.4810
Dm7                                       chord Dm7                          0.4585
something warm and mellow                 nothing                            none
show me Cmaj7 voicings                    chord Cmaj7                        0.4585
drop-2 Dm7                                chord Dm7, tags drop-2             0.4942       drop-2 → drop-2-voicings
rootless G7 shapes                        chord G7, tags rootless            0.5078
Lydian on guitar                          mode Lydian                        0.0000
jazz voicings                             tags jazz                          0.0577
shell voicings                            tags shell                         0.0707       shell → shell-voicing
voicings with a similar quality to F#m7b5 chord F#m7b5                       0.4368
something warm and dreamy                 tags dreamy                        0.0577
something jazzy in F minor for a ballad   chord F, mode minor, tags jazzy for 0.4810       jazzy → jazz, for → normal-form
Find me a mellow Cm9                      chord Cm9                          0.3887
Rootless Dm7 voicing                      chord Dm7, tags rootless           0.5085
Drop-2 voicing for Gmaj7                  chord Gmaj7, tags drop-2 for       0.4585       drop-2 → drop-2-voicings, for → normal-form
Bright open-position Em                   chord Em, tags bright              0.5310
the course's:
the best G7 voicing                       chord G7, tags the                 0.4578       the → pitch-axis-theory
what is a good Am7 voicing                chord Am7, tags what               0.4995       what → so-what-chord
a sad chord for the end of a song         tags sad for the end               0.0500       for → normal-form, the → pitch-axis-theory, end → beginner-friendly
```

- **Common words become tags.** "for" matches `normal-form`, "the" `pitch-axis-theory`, "what" `so-what-chord` and "end" `beginner-friendly`. The reader skips "chord" and "voicing" for that reason, and words under three letters, "a", "me", "to" ([lines 132-147](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/TypedMusicalQueryExtractor.cs#L132-L147)); "for", "the", "what" and "end" pass both guards. Each sets a bit, and once the partition is normalized a second bit lowers the weight of the first: "G7 shell for" scores below "G7 shell". The skill's own example, "something jazzy in F minor for a ballad", reads "for" ([`SKILL.md` line 33](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/.claude/skills/voicing-search/SKILL.md#L33)).
- **Without a chord, only SYMBOLIC can match.** "Lydian on guitar", "jazz voicings" and "shell voicings" are among the skill's uses ([line 19](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/.claude/skills/voicing-search/SKILL.md#L19)), and score 0, 0.0577 and 0.0707. The skill gives "something warm and dreamy" as a query the reader gets nothing from, with "arbitrary results" ([line 26](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/.claude/skills/voicing-search/SKILL.md#L26)); the tool reads `dreamy`, a tag, and scores 0.0577.
- **"something warm and mellow", the tool's own example of fuzzy phrasing, reads nothing** and returns no voicing ([line 99](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingSearchTool.cs#L99)). Its `allowSampling` would ask the client's model to read it ([lines 109-111](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingSearchTool.cs#L109-L111)); the course leaves it off.

## The scores

The skill explains the scores under "Why Scores Cluster 0.4–0.98": "STRUCTURE (0.45) + MORPHOLOGY (0.25) + CONTEXT (0.20) + SYMBOLIC (0.10) + MODAL (0.10)", and "Near-perfect matches across all partitions approach 1.0" ([lines 94-96](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/.claude/skills/voicing-search/SKILL.md#L94-L96)); its example answer scores 0.9831 ([line 81](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/.claude/skills/voicing-search/SKILL.md#L81)). The program reads the weights from `EmbeddingSchema` ([lines 120-136](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/EmbeddingSchema.cs#L120-L136)), and asks every root, alone and with every quality:

```text
== The scores, at the pin
partitions a query fills: STRUCTURE 0.45, SYMBOLIC 0.10, MODAL 0.10, ROOT 0.05; always empty: MORPHOLOGY 0.25, CONTEXT 0.20
the highest score a query can reach: 0.70
chord queries 828: the highest top score 0.5250, for E5
  Cmaj7: 0.4585
  Cmaj7 jazz: 0.5085
  Cmaj7 drop2 jazz: 0.4938
  Cmaj7 shell dreamy jazz: 0.5451
  G7: 0.4578
  G7 shell: 0.5078
  G7 shell for: 0.4932
```

```text
== The scores, on main
partitions a query fills: STRUCTURE 0.45, SYMBOLIC 0.10, MODAL 0.10, ROOT 0.05; always empty: MORPHOLOGY 0.25, CONTEXT 0.20
the highest score a query can reach: 0.70
chord queries 828: the highest top score 0.6000, for A
  Cmaj7: 0.6000
  Cmaj7 jazz: 0.6447
  Cmaj7 drop2 jazz: 0.6577
  Cmaj7 shell dreamy jazz: 0.6775
  G7: 0.6000
  G7 shell: 0.6447
  G7 shell for: 0.6316
```

- **No query can score above 0.70.** The encoder leaves MORPHOLOGY and CONTEXT at zero, so their 0.45 never counts. The 828 chord queries peak at 0.5250 at the pin; on `main`, Cmaj7, G7 and A reach 0.6000, the weights of STRUCTURE, MODAL and ROOT added up, and only tags can add the last 0.10. The example's 0.9831 is out of reach.
- **Adding `jazz` raises the score here.** The skill warns that a style tag "currently *lowers* the score" because the index's voicings lack style bits ([line 47](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/.claude/skills/voicing-search/SKILL.md#L47)). On the index the pinned code writes, "Cmaj7 jazz" scores above "Cmaj7", at the pin and on `main`. The course's index isn't GA's production index, where the warning may still hold.
- **The skill's warning about "drop2" is out of date.** "`drop2` does NOT match — use `drop-2-voicings`" ([line 39](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/.claude/skills/voicing-search/SKILL.md#L39)); with the registry's copies without hyphens, "drop2" reads as a tag.

## The skill draft that would call it

`skills-dev/_pending-tools/voicing-search/DRAFT.md` is a chatbot skill written for voicing search, parked like those of lessons 19 and 20 ([`skills-dev/_pending-tools/README.md` line 47](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/README.md#L47)). It calls another tool, `ga_search_voicings_by_query` ([lines 22-26](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/voicing-search/DRAFT.md#L22-L26)):

- that tool is in `GaMcpServer`, in `VoicingEmbeddingTool.cs`, and posts the query to GaApi, which embeds it with Ollama ([lines 93-132](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingEmbeddingTool.cs#L93-L132)); the course can't run it offline;
- the draft says it is "not yet implemented in Common/GA.Business.ML/Agents/Mcp/" ([line 22](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/voicing-search/DRAFT.md#L22)), and points to `Common/GA.Business.ML/Agents/Mcp/VoicingMcpTools.cs` ([line 83](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/voicing-search/DRAFT.md#L83)), a file GA has at neither commit;
- it expects `topK`, `instrument` and an answer of `Results` with `contextTags` and `sourceCorpus` ([lines 35-44](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/voicing-search/DRAFT.md#L35-L44)), where the tool takes `query` and `limit` and returns GaApi's answer;
- its example answer for "mellow Cm9" scores 0.91 and shows a voicing with three tags ([lines 57-68](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/voicing-search/DRAFT.md#L57-L68)):

```text
== The parked draft's example answer for "mellow Cm9", at the pin
x-3-5-3-3-3 plays C G A# D G; Cm9 is C D D# G A#, and the voicing leaves out D#
its tag low-density: in the vocabulary no, read as chord Cm9
its tag rootless-on-bass: in the vocabulary no, read as chord Cm9, tags rootless-on-bass
its tag quartal-flavour: in the vocabulary no, read as chord Cm9
```

The voicing has no minor third: its chart calls the G string's third fret E♭ and the high E's D, where they play B♭ and G. None of its three tags is in the vocabulary.

## Where the course stops

- **The index is lesson 3's,** 15,360 guitar voicings on the first three frets, not GA's production index: the answers and the scores can differ there; the readings don't depend on the index.
- **The instrument filter isn't tried:** the course's index holds only guitar voicings.
- **`allowSampling` stays off,** and `ga_search_voicings_by_query` isn't run: both need a model.
- **The rootless test is the course's,** on the notes each voicing plays.
- **The program calls the tools' methods directly,** not through an MCP client and GA's server.

## Exercises

1. "Lydian on guitar" returns ten voicings, all scored 0. Why doesn't the tool answer that it can't read the query, and why these ten?
2. "G7 shell" scores 0.5078 at the pin and "G7 shell for" 0.4932, with "G7" at 0.4578. Where do the two differences come from?
3. `jazz` and `rock-guitar` give Cmaj7 the same answer. Why, and which other tags give it too?
4. The parked draft's answer for "mellow Cm9" is `x-3-5-3-3-3`. Which of Cm9's notes does it leave out, and what does that make the chord?

<details>
<summary>Solutions</summary>

1. `HasIntent` counts the mode "Lydian" as something to search for ([lines 238-242](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingSearchTool.cs#L238-L242)), so the tool searches. The encoder ignores the mode, so the query vector is zero, every voicing scores 0, and the search keeps the first ten it reads, the index's first ten.
2. "shell" reads `shell-voicing`, of bit 0: SYMBOLIC adds 0.5078 − 0.4578 = 0.0500. "for" reads `normal-form`, of bit 10. Normalized, the query's two bits weigh 1/√2 each, so bit 0 now adds 0.0500/√2 and bit 10 nothing: 0.4578 + 0.0354 = 0.4932.
3. They set the same bit, 7, the registry's Genre category, and the query's SYMBOLIC partition is the same vector. `flamenco` and `neo-soul`, the bit's two other tags, give that answer too: the program found that every bit's tags, read as typed, answer alike.
4. It plays C G A# D G: it leaves out D#, E♭, the minor third. Without a third, it is neither minor nor major, a C9 with no third.

</details>

## Key takeaways

- A reader that recognizes a word isn't a search that uses it: the mode is read, printed in `interpreted`, and dropped.
- 188 tags over 12 bits are 12 words for the search, not 188.
- A tag that names a property isn't a filter: check the answers against the property.
- Matching by substring turns common words into signals.
- A documented score range can be checked against the weights a query can fill.

## Sources

- GuitarAlchemist/ga at [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `GaMcpServer/Tools/VoicingSearchTool.cs`, `GaMcpServer/Tools/VoicingVocabularyTool.cs`, `GaMcpServer/Tools/VoicingEmbeddingTool.cs`, `Common/GA.Business.ML/Search/TypedMusicalQueryExtractor.cs`, `Common/GA.Business.ML/Search/MusicalQueryEncoder.cs`, `Common/GA.Business.ML/Embeddings/Services/SymbolicVectorService.cs`, `Common/GA.Business.Config/Configuration/SymbolicTagRegistry.cs`, `Common/GA.Business.Config/SemanticNomenclature.yaml`, `.claude/skills/voicing-search/SKILL.md`, `skills-dev/_pending-tools/voicing-search/DRAFT.md`.
- GuitarAlchemist/ga at [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/tree/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a): the same tools, reader and registry, and the search of lesson 16.
- The course's programs: `code/ga-ai/GaAi/Lesson21.cs`, `code/ga-ai/GaMain/Program.cs`, `code/ga-ai/Shared/SearchVoicingsProbe.cs`, `code/ga-ai/Shared/SearchIndex.cs`.
