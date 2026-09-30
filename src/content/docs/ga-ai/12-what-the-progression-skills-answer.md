---
title: "Lesson 12: What the progression skills answer"
description: "Guitar Alchemist's chatbot has two skills that take a chord progression: one answers with a fixed text, the other lets the model suggest the next chord from a list it computes. The course asks both their own example prompts and asks for the next chord of two textbook progressions in all 30 keys: six prompts that ask to brighten get the darken answer, G Em C gets C major's chords at the pin, and no minor key's list holds its dominant."
sidebar:
  label: 12. What the progression skills answer
  order: 12
---

[Lesson 11](../11-the-chords-the-key-skill-reads/) followed a question about keys. A guitarist more often has a progression and wants to do something with it. GA's chatbot has two skills for that. [`ProgressionMoodSkill`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ProgressionMoodSkill.cs) explains how to make a progression darker or brighter, with "zero LLM calls": it returns one of two fixed texts ([line 7](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ProgressionMoodSkill.cs#L7)). [`ProgressionCompletionSkill`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ProgressionCompletionSkill.cs) suggests the next chord: `KeyIdentificationService`, the service of lesson 11, "detects the key and diatonic set deterministically; the LLM selects and explains cadence candidates from that pre-computed set" ([lines 11-12](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ProgressionCompletionSkill.cs#L11-L12)). Each skill has a SKILL.md, [progression-mood](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-mood/SKILL.md) and [progression-completion](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-completion/SKILL.md), the other surface: the mood SKILL.md gives the model the same catalog, and the completion SKILL.md has it call `ga_key_identify`, a tool that runs the same service. The skill that would analyze a progression, with its key, Roman numerals and cadences, is a draft blocked on a `ga_analyze_progression` tool "not yet implemented in Common/GA.Business.ML/Agents/Mcp/" ([`skills-dev/_pending-tools/progression-analysis/DRAFT.md` line 20](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/progression-analysis/DRAFT.md#L20)).

All GA links point to commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), the course's pin, unless they name another. On `main` at [`5c3a52a`](https://github.com/GuitarAlchemist/ga/commit/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26) (2026-09-30), `ProgressionMoodSkill.cs`, the two SKILL.md files and the draft are unchanged; `ProgressionCompletionSkill.cs` differs from the pin only by a `using` line and a flag that marks a decline. What changed is the service it calls, which lesson 11 compiled at [`6baf32e`](https://github.com/GuitarAlchemist/ga/commit/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40) against the pinned domain; the program reuses that project, `GaKeysMain`. The outputs come from:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l12
```

## The two skills

The program hosts GaChatbot.Api in its own process, as in lesson 9, and lists the intents the router can pick whose name holds "progression":

```text
== The intents that take a chord progression
skill.progressionmood          ProgressionMoodSkill         15 example prompts
skill.progressioncompletion    ProgressionCompletionSkill   5 example prompts
```

The mood skill needs no model, so the program calls it as the chatbot does, through its intent. The completion skill calls the model after the service; the program runs the steps before the call and reads the prompt they build, and the model isn't run.

## Brighter or darker

The mood skill picks its text with one test ([lines 58-66](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ProgressionMoodSkill.cs#L58-L66)):

```csharp
    public Task<AgentResponse> ExecuteAsync(string message, CancellationToken cancellationToken = default)
    {
        var lower = message.ToLowerInvariant();
        var brighten = lower.Contains("brighter") || lower.Contains("uplift") || lower.Contains("happier");

        return Task.FromResult(brighten
            ? BrightenAnswer()
            : DarkenAnswer());
    }
```

The program asks it its 15 example prompts, the ones the router compares questions with, and notes what each one asks for:

```text
== ProgressionMoodSkill's example prompts: what each asks for, and the answer it gets
prompt                                                     asks       gets
How do I make this progression sound darker?               darken     darken
Make this progression sound moodier                        darken     darken
How can I make my chords sound sadder?                     darken     darken
What can I do to make a song sound more melancholy?        darken     darken
How to add a darker feel to a chord progression            darken     darken
Techniques to make a major progression minor-sounding      darken     darken
Make my song sound brighter                                brighten   brighten
How to make a progression more uplifting                   brighten   brighten
Brighten up a minor key tune                               brighten   darken
Brighten this minor song                                   brighten   darken
How do I lift the mood of a minor progression?             brighten   darken
How does Mixolydian flavor brighten rock progressions?     brighten   darken
Use Lydian color to brighten a major progression           brighten   darken
Phrygian flavor to darken a progression                    darken     darken
What mode adds the most brightness to a major key tune?    brighten   darken
7 prompts ask to darken: 7 get the darken answer
8 prompts ask to brighten: 2 get the brighten answer
```

"Brighten" and "brightness" don't contain "brighter", and "lift the mood" isn't "uplift". Six of the eight prompts that ask to brighten get the five ways to darken. They are the six brighten prompts added on 2026-05-12 to fix misroutes, which the comments of [lines 36-53](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ProgressionMoodSkill.cs#L36-L53) record: routing now brings them to the skill, and the skill answers the opposite. The SKILL.md gives the model the same rule, "pick the **brighten** branch when the query mentions brighter / uplifting / happier" ([line 36](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-mood/SKILL.md#L36)), though its triggers list "brighten" ([line 17](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-mood/SKILL.md#L17)). What a model does with that rule isn't run here (*to verify*).

## The chords the two texts write

The program lists the progressions each text writes between backticks and flags any token that is neither a chord symbol nor a Roman numeral:

```text
== The progressions each text writes out
ProgressionMoodSkill, darken answer:
  C F G
  C Fm G
  C bA G   <- bA: neither a chord symbol nor a Roman numeral
  C bB F   <- bB: neither a chord symbol nor a Roman numeral
  C G F
ProgressionMoodSkill, brighten answer:
  I bVII IV I
skills/progression-mood/SKILL.md, the progressions written with chord names:
  C F G
  C Fm G
  C F Gm
  C Am F G
  C Am Ab G
  C Bb F
  C G F
```

`bA` and `bB` are neither: a chord symbol writes its flat after the letter, `Ab` and `Bb`, and a Roman numeral writes it before the numeral, `bVI` and `bVII` ([lines 74 and 77](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ProgressionMoodSkill.cs#L74-L77)). The SKILL.md writes `C Am Ab G` and `C Bb F` ([lines 48](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-mood/SKILL.md#L48) and [51](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-mood/SKILL.md#L51)) and asks the model to "Reproduce the technique list verbatim" ([line 38](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-mood/SKILL.md#L38)). The two lists differ in more than spelling. The second darkening technique is `IV → iv`, `vi → bVI` and `V → v` in the C# text; the SKILL.md's has `IV → iv` and `V → v`, adds `bIII`, `bVI` and `bVII` from the parallel minor, and gives three worked examples, one of which mentions `vi → bVI`. The second brightening technique raises the fourth degree, "#iv° actually", or holds a IV with a #11 in the C# text ([line 104](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ProgressionMoodSkill.cs#L104)); the SKILL.md uses a `IVmaj7#11` or a major `II` ([line 60](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-mood/SKILL.md#L60)).

## The keyword test

Every skill also has a `CanHandle` method, a test on the words of the question. At the pin, nothing outside the tests calls it: the router compares embeddings. On `main`, [`OrchestratorSkillIntent`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Common/GA.Business.Core.Orchestration/Intents/OrchestratorSkillIntent.cs#L29) passes it to the router, which falls back on it when it can't embed the question and gives the question to the first intent whose test accepts it ([`SemanticIntentRouter.cs` line 321](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Common/GA.Business.ML/Agents/Intents/SemanticIntentRouter.cs#L321)). Both skills' tests are unchanged on `main`. The program asks each test about its own skill's example prompts:

```text
== CanHandle, the keyword test main's router falls back on when it has no embeddings
ProgressionMoodSkill: 0 of 15 example prompts accepted
ProgressionCompletionSkill: 3 of 5 example prompts accepted
  rejected: What chord comes next after C G Am?
  rejected: Help me end Am F G
```

The mood skill's test returns `false` ([line 56](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ProgressionMoodSkill.cs#L56)), so without embeddings `main` never reaches it. The completion skill's trigger ([lines 35-37](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ProgressionCompletionSkill.cs#L35-L37)) holds `what\s+comes\s+next`, which "What chord comes next" doesn't match, and no "help me end", which the SKILL.md lists as a trigger ([line 17](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-completion/SKILL.md#L17)):

```csharp
    private static readonly Regex CompletionTrigger = new(
        @"\b(finish|complete|end\s+it|end\s+this|what\s+comes\s+next|next\s+chord|help\s+me\s+finish|how\s+(do\s+i|to)\s+end|what\s+should\s+follow|continue|extend)\b",
        RegexOptions.IgnoreCase | RegexOptions.Compiled);
```

## What the completion skill tells the model

`ExecuteAsync` reads the chords with `ExtractChords`, scores the keys with `Identify` and hands `BuildPrompt` the first key and the whole list ([lines 49-67](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ProgressionCompletionSkill.cs#L49-L67)). `BuildPrompt` names every key tied with the first, but takes the chords the model may suggest from the first key alone ([lines 93-107](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ProgressionCompletionSkill.cs#L93-L107)):

```csharp
        var topTied = all.Where(c => c.MatchCount == top.MatchCount).ToList();
        var keyDesc = topTied.Count == 1
            ? top.Key
            : string.Join(" / ", topTied.Select(c => c.Key));
```

`BuildPrompt` is private; the program calls it by reflection and prints what the model reads for the skill's first example prompt, from the progression to the rules, then the two suggestions of the JSON example that closes the prompt:

```text
== What the model reads for "What chord comes next after C G Am?", pinned
  | The input progression is: [C, G, Am]
  | Detected key: A minor / C major / E minor / G major  (3/3 chords diatonic)
  |
  | AVAILABLE DIATONIC CHORDS — you may ONLY suggest chords from this list:
  | Am, Bdim, C, Dm, Em, F, G
  |
  | Task: Suggest 2-3 chord completions (each 1-2 chords) that cadence naturally
  | to end or continue the progression in A minor / C major / E minor / G major.
  |
  | For each suggestion:
  |   - Name the cadence type (authentic, half, deceptive, or plagal)
  |   - Give the Roman numeral(s)
  |   - Write a one-sentence guitarist-friendly explanation
  |
  | IMPORTANT: Every chord you suggest MUST appear in the AVAILABLE DIATONIC CHORDS list.
  | You may substitute the plain V chord with V7 even if only V appears in the diatonic list
  | (this is the standard harmonic minor adjustment).
  |
  | { "chords": ["E7"], "cadence": "authentic", "roman": "V7-i", "explanation": "Strongest resolution back to Am." },
  | { "chords": ["G"],  "cadence": "half",      "roman": "bVII-i", "explanation": "Open loop, floats back to the top." }
```

Which key is first decides the list. At the pin, `Identify` sorts the keys by count, then by name ([`KeyIdentificationService.cs` lines 177-178](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/KeyIdentificationService.cs#L177-L178)). On `main`, it sorts them by count plus a weight for the final cadence, then puts first the key whose tonic triad opens the progression, then the major key, then the name ([lines 224-227](https://github.com/GuitarAlchemist/ga/blob/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40/Common/GA.Domain.Services/Tonal/KeyIdentificationService.cs#L224-L227)). For `main`, the program applies the skill's lines to `main`'s service; for the pin, it checks those lines against the prompt `BuildPrompt` itself writes, on every question of the lesson.

## The skill's own examples

The program asks the skill's five example prompts, then the bare progression of the SKILL.md's example:

```text
== ProgressionCompletionSkill's example prompts: the key and the chords the model may suggest
"What chord comes next after C G Am?"
  a826864  reads C G Am; key: A minor / C major / E minor / G major (3/3)
           may suggest: Am, Bdim, C, Dm, Em, F, G
  6baf32e  reads C G Am; key: C major / G major / A minor / E minor (3/3)
           may suggest: C, Dm, Em, F, G, Am, Bdim
"How do I finish this progression: Em D C"
  a826864  reads Em D C; key: E minor / G major (3/3)
           may suggest: Em, F#dim, G, Am, Bm, C, D
  6baf32e  reads Em D C; key: E minor / G major (3/3)
           may suggest: Em, F#dim, G, Am, Bm, C, D
"Help me end Am F G"
  a826864  reads Am F G; key: A minor / C major (3/3)
           may suggest: Am, Bdim, C, Dm, Em, F, G
  6baf32e  reads Am F G; key: A minor / C major (3/3)
           may suggest: Am, Bdim, C, Dm, Em, F, G
"What should follow Dm G C?"
  a826864  reads Dm G C; key: A minor / C major (3/3)
           may suggest: Am, Bdim, C, Dm, Em, F, G
  6baf32e  reads Dm G C; key: C major / A minor (3/3)
           may suggest: C, Dm, Em, F, G, Am, Bdim
"Continue this progression: F C G"
  a826864  reads F C G; key: A minor / C major (3/3)
           may suggest: Am, Bdim, C, Dm, Em, F, G
  6baf32e  reads F C G; key: C major / A minor (3/3)
           may suggest: C, Dm, Em, F, G, Am, Bdim
"C G Am"
  a826864  reads C G Am; key: A minor / C major / E minor / G major (3/3)
           may suggest: Am, Bdim, C, Dm, Em, F, G
  6baf32e  reads C G Am; key: C major / G major / A minor / E minor (3/3)
           may suggest: C, Dm, Em, F, G, Am, Bdim
```

C G Am, the skill's first example and the SKILL.md's only one, fits four keys: C major and A minor, and also G major and E minor, whose scale holds F♯ instead of F. At the pin, A minor comes first by name; on `main`, C major, which opens the progression. The SKILL.md describes another result: "`TopCandidates: [{ Key: "C major", DiatonicSet: [C, Dm, Em, F, G, Am, B°] }, ...]` (also tied with A minor)" ([line 86](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-completion/SKILL.md#L86)). At the pin, A minor is first and G major and E minor are tied too; the list writes `Bdim`, not `B°`. Its example answer then suggests `Dm → G7` ([line 92](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-completion/SKILL.md#L92)): G7 isn't in the list, and the SKILL.md's first hard constraint is "Every suggested chord must appear in `DiatonicSet`" ([line 96](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-completion/SKILL.md#L96)). For ties, the SKILL.md says that relative keys share the same diatonic set and that a tie with another key is rare, "very short progressions" ([line 56](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-completion/SKILL.md#L56)).

## The next chord in thirty keys

The program asks "What chord comes next after …?" for I vi IV in the 15 major keys and i VI VII in the 15 minor keys, spelled as a textbook spells them, and compares the list the model may suggest from with the key's seven triads:

```text
== "What chord comes next after ...?" for two textbook progressions in the 30 keys

I vi IV             Cb Gb Db Ab Eb Bb F  C  G  D  A  E  B  F# C#
           a826864  =  x  e  x  x  =  x  =  x  =  =  x  e  r  r
           6baf32e  e  e  e  =  =  =  =  =  =  =  =  =  =  r  r

i VI VII            Ab Eb Bb F  C  G  D  A  E  B  F# C# G# D# A#
           a826864  =  e  e  =  =  =  =  =  =  =  =  =  r  r  r
           6baf32e  =  e  e  =  =  =  =  =  =  =  =  =  r  r  r

= the chords read as written, and the model may suggest the key's chords as the textbook spells them;
e the same chords, spelled from the enharmonic key; x other chords; r a chord dropped or read as another chord
a826864: 30 questions, = 15, e 4, x 6, r 5; a key of another scale tied at the top in 13 of the 25 read as written
6baf32e: 30 questions, = 20, e 5, x 0, r 5; a key of another scale tied at the top in 13 of the 25 read as written
```

- **`x`, the pin, six major keys.** G Em C is I vi IV in G major and V iii I in C major, and the four keys of C G Am tie again; A minor comes first by name, and the model may suggest only C major's chords, without D, the dominant of G major. In G♭, A♭, E♭, F and E major too, a key of the other scale comes first by name. On `main`, the key whose tonic triad opens the progression comes first: the row has no `x`, though G♭ major becomes F♯ major (`e`).
- **`e`, spelled from the enharmonic key.** D♭ B♭m G♭ ties eight keys, D♭ major's four names and G♭ major's. At the pin, A♯ minor comes first, and the model may suggest `A#m, B#dim, C#, D#m, E#m, F#, G#` for a question written with flats; on `main`, C♯ major. Four questions at the pin, D♭ and B major and E♭ and B♭ minor; five on `main`, where C♭, G♭ and D♭ major become B, F♯ and C♯ major and E♭ and B♭ minor become D♯ and A♯ minor.
- **`r`, a sharp dropped.** `ExtractChords` drops a sharp before a space or a question mark ([#771](https://github.com/GuitarAlchemist/ga/issues/771)): F♯ D♯m B is read F D♯m B, and at the pin the model may suggest A♭ minor's chords, `Abm, Bbdim, Cb, Dbm, Ebm, Fb, Gb`.
- **Ties with another scale.** Every I vi IV read as written ties with the key a fourth up, where the three chords are V iii I: 13 of the 25 questions read as written, not a rare case of very short progressions.

```text
C major, I vi IV: "What chord comes next after C Am F?"
  a826864  reads C Am F; key: A minor / C major / D minor / F major (3/3)
           may suggest: Am, Bdim, C, Dm, Em, F, G
  6baf32e  reads C Am F; key: C major / F major / A minor / D minor (3/3)
           may suggest: C, Dm, Em, F, G, Am, Bdim
G major, I vi IV: "What chord comes next after G Em C?"
  a826864  reads G Em C; key: A minor / C major / E minor / G major (3/3)
           may suggest: Am, Bdim, C, Dm, Em, F, G
  6baf32e  reads G Em C; key: G major / C major / A minor / E minor (3/3)
           may suggest: G, Am, Bm, C, D, Em, F#dim
Db major, I vi IV: "What chord comes next after Db Bbm Gb?"
  a826864  reads Db Bbm Gb; key: A# minor / Bb minor / C# major / D# minor / Db major / Eb minor / F# major / Gb major (3/3)
           may suggest: A#m, B#dim, C#, D#m, E#m, F#, G#
  6baf32e  reads Db Bbm Gb; key: C# major / Db major / F# major / Gb major / A# minor / Bb minor / D# minor / Eb minor (3/3)
           may suggest: C#, D#m, E#m, F#, G#, A#m, B#dim
F# major, I vi IV: "What chord comes next after F# D#m B?"
  a826864  reads F D#m B; key: Ab minor / B major / Cb major / D# minor / Eb minor / F# major / G# minor / Gb major (2/3)
           may suggest: Abm, Bbdim, Cb, Dbm, Ebm, Fb, Gb
  6baf32e  reads F D#m B; key: B major / Cb major / F# major / Gb major / Ab minor / D# minor / Eb minor / G# minor (2/3)
           may suggest: B, C#m, D#m, E, F#, G#m, A#dim
G# minor, i VI VII: "What chord comes next after G#m E F#?"
  a826864  reads G#m E F; key: Ab minor / B major / C# minor / Cb major / E major / G# minor (2/3)
           may suggest: Abm, Bbdim, Cb, Dbm, Ebm, Fb, Gb
  6baf32e  reads G#m E F; key: Ab minor / G# minor / B major / Cb major / E major / C# minor (2/3)
           may suggest: Abm, Bbdim, Cb, Dbm, Ebm, Fb, Gb
```

## The dominant of a minor key

The list is the key's seven triads, the natural minor's for a minor key ([lines 39-45](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/KeyIdentificationService.cs#L39-L45)). The program looks for the triads on the fifth degree in each key's own list:

```text
== The dominant the list holds, in each key's own list
15 major keys: the major triad on the fifth degree in 15, the minor one in 0
15 minor keys: the major triad on the fifth degree in 0, the minor one in 15
A minor: Am, Bdim, C, Dm, Em, F, G
  the prompt's example suggests E7 ("V7-i"): E7 in the list: no; E: no
  and G as a half cadence ("bVII-i"): G is degree 7 of the list; a half cadence ends on degree 5, Em
```

A cadence in a minor key usually takes its dominant from the harmonic minor: E or E7 in A minor, with the leading tone G♯. No minor key's list holds it. The prompt allows it only when it is already there: "You may substitute the plain V chord with V7 even if only V appears in the diatonic list (this is the standard harmonic minor adjustment)" ([lines 117-119](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ProgressionCompletionSkill.cs#L117-L119)); in a minor key, only v appears. Its own example then suggests E7 as V7–i for A minor ([line 130](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ProgressionCompletionSkill.cs#L130)), a chord its list doesn't hold, and G as a half cadence, "bVII-i" ([line 131](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ProgressionCompletionSkill.cs#L131)): a half cadence ends on V, "anything → V" in the SKILL.md's catalog ([line 67](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-completion/SKILL.md#L67)), and G is the seventh degree. The SKILL.md allows V7 in minor "even when only `v` appears" ([line 71](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-completion/SKILL.md#L71)) and forbids any chord outside the list ([line 96](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-completion/SKILL.md#L96)). In a minor key, the model can't suggest an authentic cadence without breaking one of the two rules.

## Where the course stops

- **The model isn't run.** What it suggests from these lists, and whether it follows the V7 rule or the list, needs the model (*to verify*).
- **Routing isn't tested.** Which questions reach the two skills is decided by the embedding model; the keyword test is only asked about the skills' own examples.
- **`main`'s completion skill isn't run.** Its lines are applied to `main`'s service at `6baf32e`, compiled against the pinned domain; for the pin, the same lines are checked against `BuildPrompt` on all 36 questions.
- **The analysis skill isn't there.** The chatbot has none, at the pin or on `main`. The DSL's `domain.analyzeProgression` closure exists, and GaMcpServer's `GaAnalyzeProgression` tool calls it ([`GaDslTool.cs` lines 195-197](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GaDslTool.cs#L195-L197)), but no chatbot skill does; this lesson doesn't run it.
- **Two textbook progressions**, in root-position triads.

## Reported upstream

- Not reported upstream when this lesson was written: the brighten test, the two texts' chords, the lists taken from the first key by name, the lists spelled from the enharmonic key, the dominant missing from a minor key's list, the prompt's example, the SKILL.md's example and the keyword tests. The dropped sharps are [#771](https://github.com/GuitarAlchemist/ga/issues/771), and the order of keys with the same pitch classes has the same cause as [#772](https://github.com/GuitarAlchemist/ga/issues/772). All are listed in the [journal](../journal/).

## Exercises

1. Rewrite the mood skill's test so that its 15 example prompts get the answer they ask for. The SKILL.md says to answer darken when both moods appear: what does your test answer for "How do I make a happier song sound darker?"
2. For "What chord comes next after G Em C?", the pinned skill offers C major's chords. Which rule, applied before the name, gives G major's list, and what does it give for C G Am and for Am F G?
3. Change the list of a minor key so that the model can suggest an authentic cadence without breaking the prompt's rules. Which chord do you add to A minor's list, what does the prompt's V7 rule then allow, and what must the SKILL.md change?
4. With A minor's list as it is, which of the SKILL.md's four cadences ([lines 64-69](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-completion/SKILL.md#L64-L69)) can the model build?

<details>
<summary>Solutions</summary>

1. Test the darkening words first, `dark`, `sad`, `moodier`, `melancholy` and `minor-sounding`, then the stems `bright`, `lift` and `happ`. "Brighten", "brightness", "lift the mood", "uplifting" and "happier" each contain one of the stems, and none of the eight brighten prompts contains a darkening word ("lift the mood" holds "mood", not "moodier"). "How do I make a happier song sound darker?" then gets the darken answer, as the SKILL.md asks; the pinned test answers brighten, because the question holds "happier". Worked by hand on the 15 prompts.
2. Prefer the key whose tonic triad is the first chord, as `main` does. G Em C gets G major's list, C G Am C major's and Am F G A minor's: the output above shows `main` putting G major, C major and A minor first. Worked from the output.
3. Add the dominant triad of the harmonic minor, E for A minor: the fifth degree of `Key.Notes` as a major triad. The prompt's rule then works in a minor key as it does in a major one: V appears, so the model may write V7, and the prompt's E7 example holds. The SKILL.md's hard constraint still forbids E7, as it forbids G7 in C major, which its own example suggests: it needs the same exception for V7 as the prompt. Worked by hand.
4. Only the plagal cadence, as iv–i, Dm–Am: the SKILL.md says "In a minor key, substitute as needed" ([line 71](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-completion/SKILL.md#L71)). The authentic cadence (V → I) and the deceptive one (V → vi) need the major V, which isn't in the list. A half cadence ends on V, and the list has only v, Em, a dominant without the leading tone G♯. Worked by hand.

</details>

## Key takeaways

- A fixed answer is still chosen by a test: when that test misses "brighten", a question routed right gets the opposite answer, and fixing the routing brought the question to the bug.
- A skill that restricts the model to a list decides the answer by the list: at the pin, ties broken by name give G Em C the chords of C major.
- A list and the rules about it must agree: the prompt allows V7 when V appears, and in a minor key it never does.
- A prompt's or a SKILL.md's example teaches the model: E7 outside the list, a half cadence that doesn't end on V, G7 against the hard constraint.
- Two texts meant to say the same thing drift apart: the C# answer writes `bA` and `bB`, the SKILL.md `Ab` and `Bb`, with different techniques.

## Sources

- GuitarAlchemist/ga at [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `Common/GA.Business.ML/Agents/Skills/ProgressionMoodSkill.cs`, `Common/GA.Business.ML/Agents/Skills/ProgressionCompletionSkill.cs`, `Common/GA.Business.ML/Agents/KeyIdentificationService.cs`, `skills/progression-mood/SKILL.md`, `skills/progression-completion/SKILL.md`, `skills-dev/_pending-tools/progression-analysis/DRAFT.md`, `GaMcpServer/Tools/GaDslTool.cs`.
- GA at [`6baf32e`](https://github.com/GuitarAlchemist/ga/commit/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40), committed on 2026-09-25 UTC: `Common/GA.Domain.Services/Tonal/KeyIdentificationService.cs`, compiled by the course. GA's `main` at [`5c3a52a`](https://github.com/GuitarAlchemist/ga/commit/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26), committed on 2026-09-30 UTC: `OrchestratorSkillIntent.cs` and `SemanticIntentRouter.cs`, and the comparison of the two skills, their SKILL.md files and the draft.
- *Open Music Theory*, the chapters on cadences, the minor scale's raised seventh and modal mixture.
