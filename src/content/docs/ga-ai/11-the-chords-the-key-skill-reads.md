---
title: "Lesson 11: The chords the key skill reads"
description: "Guitar Alchemist's key skill reads the chord symbols out of the question with one regular expression, scores the 30 keys and hands the model the keys tied at the top. The course asks for the key of six textbook progressions in all 30 keys, with the pinned service and with the one on GA's main: the pin reads no seventh chord, both read F♯ as F, main answers C♯ major for D♭ G♭ A♭ D♭, and C D G C comes out in G major."
sidebar:
  label: 11. The chords the key skill reads
  order: 11
---

[Lesson 10](../10-what-the-model-is-told-to-trust/) called the tool a model is told to trust. The key skill goes further: the answer is computed before the model sees the question. [`KeyIdentificationSkill`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/KeyIdentificationSkill.cs) scores the keys, then asks the model to explain the result, with the instruction "Use ONLY the data below — do not guess or add your own analysis" ([line 97](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/KeyIdentificationSkill.cs#L97)). The other surface for "what key is …", the [key-identification SKILL.md](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/key-identification/SKILL.md), tells the model to call the `ga_key_identify` tool and not to analyze the progression itself. Both run the same steps. [`KeyIdentificationService`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/KeyIdentificationService.cs)'s `ExtractChords` reads the chord symbols out of the question and its `Identify` scores the 30 major and minor keys; then the tool, like the skill, keeps the keys whose count equals the first key's as the top matches, followed by up to three partial matches. What these steps produce is what the model is told to say, and the program runs them without a model.

All GA links point to commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), the course's pin, unless they name another. Key detection has changed on GA's `main` since. [#625](https://github.com/GuitarAlchemist/ga/pull/625), merged on 2026-09-24, moved the service to `GA.Domain.Services`, extended its regular expression to seventh chords, counted dominant sevenths and added a weight for the final cadence. [#729](https://github.com/GuitarAlchemist/ga/pull/729), commit [`6baf32e`](https://github.com/GuitarAlchemist/ga/commit/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40), changed how ties are broken, after [lesson 7 of the music-theory-ga course](../../music-theory-ga/07-cadences-and-progressions/) had tested GA's MCP server tools. Those tools take the chords alone; this lesson asks the chatbot's question, a sentence the chords must be read out of. On `main` at [`5c3a52a`](https://github.com/GuitarAlchemist/ga/commit/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26) (2026-09-30), the service is still as `6baf32e` left it, the SKILL.md is unchanged, and the tool and the skill differ from the pin only by a `using` line and, in the skill, a flag that marks a decline. `fetch-ga.sh` fetches the service at `6baf32e`, and the project [`GaKeysMain`](https://github.com/spareilleux/learn/blob/main/code/ga-ai/GaKeysMain/GaKeysMain.csproj) compiles it against the pinned domain, whose `Key.Items` and `Key.Notes` are unchanged on `main`. The outputs come from:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l11
```

## What the model is given

The tool keeps the keys whose count equals the first key's, then the next three ([`KeyIdentificationMcpTools.cs` lines 66-75](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Mcp/KeyIdentificationMcpTools.cs#L66-L75)):

```csharp
        var topScore = candidates[0].MatchCount;
        var topTied  = candidates
            .Where(c => c.MatchCount == topScore)
            .Select(ToCandidate)
            .ToArray();
        var partial  = candidates
            .Skip(topTied.Length)
            .Take(MaxPartialCandidates)
            .Select(ToCandidate)
            .ToArray();
```

`KeyIdentificationSkill` builds the same top list ([lines 62-63](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/KeyIdentificationSkill.cs#L62-L63)) and prints it in the model's prompt under "TOP MATCHES (all tied at the highest score)", followed by the next three keys under "PARTIAL MATCHES" ([lines 100-114](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/KeyIdentificationSkill.cs#L100-L114)). [`Lesson11.cs`](https://github.com/spareilleux/learn/blob/main/code/ga-ai/GaAi/Lesson11.cs) calls `ExtractChords` and `Identify` of both versions and applies these lines to their results. For the pinned version it also calls `ga_key_identify` itself, `KeyIdentificationMcpTools.IdentifyKey`, and stops if the tool reads other chords or returns other keys:

```text
== The pinned answers, checked against ga_key_identify
99 questions: KeyIdentificationMcpTools.IdentifyKey read the same chords and returned the same keys
```

The textbook side is short. A progression built on a key's scale is in that key. A key and its relative share all seven triads, so the triads alone can't tell C major from A minor; the first chord and the ending do. The course looks at the first key of the top matches and at whether the textbook key is among them.

## The skill's own examples

The seven example prompts of `KeyIdentificationSkill`, and the progressions of the SKILL.md's two examples:

```text
== The key skill's example prompts: the chords read, and the keys tied at the top
"What key is C Am F G in?"
  a826864  reads C Am F G       4/4: A minor, C major
  6baf32e  reads C Am F G       4/4: C major, A minor
"Identify the key of Dm G C"
  a826864  reads Dm G C         3/3: A minor, C major
  6baf32e  reads Dm G C         3/3: C major, A minor
"What key does Am F G E sound like?"
  a826864  reads Am F G E       3/4: A minor, C major
  6baf32e  reads Am F G E       3/4: A minor, C major
"Tell me the key of these chords: G D Em C"
  a826864  reads G D Em C       4/4: E minor, G major
  6baf32e  reads G D Em C       4/4: G major, E minor
"Find the tonic of A E F#m D"
  a826864  reads A E F#m D      4/4: A major, F# minor
  6baf32e  reads A E F#m D      4/4: A major, F# minor
"What's the tonic of these chords: C F G C"
  a826864  reads C F G          3/3: A minor, C major
  6baf32e  reads C F G          3/3: C major, A minor
"Identify the tonic of this progression: D A Bm G"
  a826864  reads D A Bm G       4/4: B minor, D major
  6baf32e  reads D A Bm G       4/4: D major, B minor
"Dm G C"
  a826864  reads Dm G C         3/3: A minor, C major
  6baf32e  reads Dm G C         3/3: C major, A minor
"C Am F G"
  a826864  reads C Am F G       4/4: A minor, C major
  6baf32e  reads C Am F G       4/4: C major, A minor
```

At the pin, every example ties a key with its relative, and the tie is sorted by name ([line 178](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/KeyIdentificationService.cs#L178)): A minor comes before C major, E minor before G major, B minor before D major. The SKILL.md's first example reads "The progression `Dm G C` is in **C major** (3/3 chords diatonic)" ([line 60](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/key-identification/SKILL.md#L60)); the tool returns C major and A minor, and for more than one top candidate the SKILL.md tells the model to name both ([line 64](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/key-identification/SKILL.md#L64)). On `main`, C major comes first because Dm G C ends with G C, a V–I of C major, and the cadence weight adds 2; A minor stays in the top matches, because the tool groups keys by count and A minor's is also 3. In the other examples, `main` gives a tie to the key whose tonic triad opens the progression, then to the major key. In "Am F G E", the E isn't counted in A minor by either version: the service matches the natural minor's triads ([lines 40-45](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/KeyIdentificationService.cs#L40-L45)), whose triad on the fifth degree is E minor.

## Reading the chords

The program puts each symbol in "What key is X in?" and prints what `ExtractChords` returns. After each version's reading, a column gives the quality the service's private parser assigns to each chord read; the program calls the parser by reflection.

```text
== What each version reads in "What key is X in?", and what each chord counts as
X        a826864 reads  counts as      6baf32e reads  counts as
C        C              major          C              major
Cm       Cm             minor          Cm             minor
Cdim     Cdim           diminished     Cdim           diminished
Caug     Caug           major          Caug           major
C+       C              major          C              major
C°       C              major          C              major
Cmin     nothing        -              Cmin           minor
C#       C              major          C              major
C#m      C#m            minor          C#m            minor
Db       Db             major          Db             major
F#       F              major          F              major
F#7      F#             major          F#7            dominant
B♭       B              major          B              major
F♯       F              major          F              major
C7       nothing        -              C7             dominant
Cm7      nothing        -              Cm7            minor
Cmaj7    nothing        -              Cmaj7          major
CM7      nothing        -              nothing        -
CΔ7      nothing        -              nothing        -
Cm7b5    nothing        -              Cm7b5          minor
Cø7      nothing        -              nothing        -
Cdim7    nothing        -              Cdim7          diminished
C6       nothing        -              C6             major
C9       nothing        -              C9             major
Csus4    nothing        -              Csus4          major
Cadd9    nothing        -              Cadd9          major
C7#9     nothing        -              C7#9           dominant
C/E      C E            major major    C E            major major
```

At the pin, the regular expression is ([line 211](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/KeyIdentificationService.cs#L211)):

```csharp
    [GeneratedRegex(@"\b[A-G][b#]?(m|dim|aug|maj)?\b", RegexOptions.None)]
    private static partial Regex ChordPattern();
```

`\b` matches between a word character (a letter, a digit or `_`) and anything else. In `Am7`, `m` and `7` are both word characters, so the final `\b` fails after `m`; without the `m` it fails after `A`, and the chord is skipped. Every symbol with a digit right after a letter is skipped the same way: `C7`, `Cm7`, `Cmaj7`, `Cm7b5`, `C6`. So is a quality the group doesn't list, `sus` in `Csus4` or `add` in `Cadd9`, with or without a digit. The SKILL.md says the tool "doesn't distinguish a `Cmaj7` from a `C` for the purposes of key fitting" ([line 81](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/key-identification/SKILL.md#L81)); at the pin, it doesn't read `Cmaj7` at all. In `F#` followed by a space, the `#` and the space are both non-word characters, so the final `\b` fails after `#`; the regex gives the `#` back and matches `F`. `F#m` keeps its sharp because `m` is a letter; `F#7` keeps it because `7` is a digit, and loses the `7`, since the pattern stops at the sharp. This is the cause of [#757](https://github.com/GuitarAlchemist/ga/issues/757) in the improvisation skill and of [#767](https://github.com/GuitarAlchemist/ga/issues/767) in the interval skill, here in a third pattern. `B♭` and `F♯` use the music signs, which `[b#]` doesn't include. `C°` is read as `C`, and counts as a major triad. `C/E` becomes two chords.

On `main`, `Cm7b5` is read and counts as minor: the parser deletes everything from the first digit on ([lines 316-321](https://github.com/GuitarAlchemist/ga/blob/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40/Common/GA.Domain.Services/Tonal/KeyIdentificationService.cs#L316-L321)), and `Cm` is left. The triad of a half-diminished seventh is diminished. The pin's parser does the same ([lines 205-209](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/KeyIdentificationService.cs#L205-L209)), but its pattern never passes it the symbol.

On `main`, the pattern accepts digits and alterations after the quality ([line 325](https://github.com/GuitarAlchemist/ga/blob/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40/Common/GA.Domain.Services/Tonal/KeyIdentificationService.cs#L325)):

```csharp
    [GeneratedRegex(@"\b[A-G][b#]?(?:maj|Maj|min|m|dim|aug|sus|add)?\d*(?:b5|#5|b9|#9|#11|b13)?\b", RegexOptions.None)]
    private static partial Regex ChordPattern();
```

The seventh chords are read. `C7` and `C7#9` count as dominants, which `Identify` accepts on the fifth degree of a major key or the seventh degree of a minor one. The final `\b` is still there: `C#` and `F#` still come back as `C` and `F`, and `CM7`, `CΔ7` and `Cø7` are still skipped.

## Six progressions in thirty keys

The program builds six progressions on the scale of each key with at most seven sharps or flats, spells them as the textbook does and asks "What key is … in?". Three are in the 15 major keys: I IV V I; I II V I, where II is a major triad, the dominant of the dominant (C D G C); and ii7 V7 Imaj7 (Dm7 G7 Cmaj7). Three are in the 15 minor keys: i iv V i, with the major V of the harmonic minor (Am Dm E Am); iiø7 V7 i (Bm7b5 E7 Am); and i VI III VII (Am F C G).

```text
== "What key is ... in?" for six textbook progressions in the 30 keys

major keys             Cb Gb Db Ab Eb Bb F  C  G  D  A  E  B  F# C#
I IV V I      a826864  ~  ~  ~  =  ~  =  ~  ~  ~  ~  =  ~  r  r  r
I IV V I      6baf32e  ~  ~  ~  =  =  =  =  =  =  =  =  =  r  r  r
I II V I      a826864  x  x  x  x  x  x  x  x  x  x  x  r  r  r  r
I II V I      6baf32e  x  x  x  x  x  x  x  x  x  x  x  r  r  r  r
ii7 V7 Imaj7  a826864  r  r  r  r  r  r  r  r  r  r  r  r  r  r  r
ii7 V7 Imaj7  6baf32e  ~  ~  ~  =  =  =  =  =  =  =  =  =  =  =  =

minor keys             Ab Eb Bb F  C  G  D  A  E  B  F# C# G# D# A#
i iv V i      a826864  =  ~  ~  ~  ~  ~  ~  =  ~  r  r  r  r  r  r
i iv V i      6baf32e  =  ~  ~  =  =  =  =  =  =  r  r  r  r  r  r
iiø7 V7 i     a826864  r  r  r  r  r  r  r  r  r  r  r  r  r  r  r
iiø7 V7 i     6baf32e  =  ~  ~  =  =  =  =  =  =  =  =  =  ~  =  =
i VI III VII  a826864  =  ~  ~  ~  =  ~  =  =  =  =  ~  =  r  r  r
i VI III VII  6baf32e  =  ~  ~  =  =  =  =  =  =  =  =  =  r  r  r

= every chord read as written, the textbook key first; ~ read, the key tied at the top but not first;
x read, the key not among the top; r a chord dropped or read as another chord
a826864: 90 questions, = 12, ~ 21, x 11, r 46; a key after the top with a higher count: 0
6baf32e: 90 questions, = 50, ~ 13, x 11, r 16; a key after the top with a higher count: 2
```

At the pin, the 30 questions with seventh chords lose every seventh chord: what is left is the i of iiø7 V7 i and, where a root has a sharp, the bare root, `F#` for `F#m7`. 16 more lose a sharp: each question with a major triad on F♯, C♯, G♯, D♯, A♯ or E♯. Of the 44 questions read as written, 12 get the textbook key first, 21 get it among the keys tied at the top, sorted after another key by name, and 11 don't get it at all.

On `main`, 50 questions get the textbook key first. The 16 with a sharp major triad still lose the sharp. The 13 `~` are all keys that share their seven pitch classes with another key. D♭ major has the notes of C♯ major, and its relative B♭ minor those of A♯ minor, so the four keys tie on the count. C♯ major and D♭ major both open on their tonic and are both major, and the last rule, the name, picks C♯ major: a progression written with five flats gets a key with seven sharps. G♭ major becomes F♯ major, C♭ major B major, E♭ minor D♯ minor, B♭ minor A♯ minor, and G♯ minor A♭ minor. The 11 `x` are the same in both versions: I II V I, in every key whose chords are read.

Five questions in full; for a question that repeats a chord, the program also gives `main`'s `Identify` the chords as a list, as written:

```text
Db major, I IV V I: "What key is Db Gb Ab Db in?"
  a826864  reads Db Gb Ab; top 3/3: A# minor, Bb minor, C# major, Db major; then Ab major 2/3, D# minor 2/3, Eb minor 2/3
  6baf32e  reads Db Gb Ab; top 3/3: C# major, Db major, A# minor, Bb minor; then Ab major 2/3, F# major 2/3, Gb major 2/3
           given Db Gb Ab Db as a list, Identify puts C# major first; top 3/3: C# major, Db major, A# minor, Bb minor; then Ab major 2/3, F# major 2/3, Gb major 2/3
C major, I II V I: "What key is C D G C in?"
  a826864  reads C D G; top 3/3: E minor, G major; then A minor 2/3, B minor 2/3, C major 2/3
  6baf32e  reads C D G; top 3/3: G major, E minor; then C major 2/3, D major 2/3, A minor 2/3
           given C D G C as a list, Identify puts C major first; top 2/3: C major, D major, A minor, B minor; then A minor 2/3, B minor 2/3, A major 1/3
E major, ii7 V7 Imaj7: "What key is F#m7 B7 Emaj7 in?"
  a826864  reads F#; top 1/1: A# minor, Ab minor, B major, Bb minor, C# major, Cb major, D# minor, Db major, Eb minor, F# major, G# minor, Gb major
  6baf32e  reads F#m7 B7 Emaj7; top 3/3: E major, C# minor; then F# minor 2/3, A major 2/3, B major 1/3
F# minor, i iv V i: "What key is F#m Bm C# F#m in?"
  a826864  reads F#m Bm C; top 2/3: A major, B minor, D major, E minor, F# minor, G major; then A minor 1/3, C major 1/3, C# minor 1/3
  6baf32e  reads F#m Bm C; top 2/3: F# minor, A major, D major, G major, B minor, E minor; then C major 1/3, E major 1/3, F major 1/3
           given F#m Bm C# F#m as a list, Identify puts F# minor first; top 2/3: F# minor, A major, D major, B minor; then Ab major 1/3, C# major 1/3, Db major 1/3
B minor, iiø7 V7 i: "What key is C#m7b5 F#7 Bm in?"
  a826864  reads C# F# Bm; top 2/3: A# minor, Bb minor, C# major, D# minor, Db major, Eb minor, F# major, Gb major; then A major 1/3, Ab major 1/3, Ab minor 1/3
  6baf32e  reads C#m7b5 F#7 Bm; top 1/3: B minor, C# minor, D major, E major, G major, E minor; then G# minor 2/3, C# minor 1/3, D major 1/3
```

`ExtractChords` drops repeated chords ([line 299](https://github.com/GuitarAlchemist/ga/blob/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40/Common/GA.Domain.Services/Tonal/KeyIdentificationService.cs#L299)), so the final C of C D G C never reaches `Identify`. The cadence weight of #625 looks at the last two chords ([lines 231-246](https://github.com/GuitarAlchemist/ga/blob/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40/Common/GA.Domain.Services/Tonal/KeyIdentificationService.cs#L231-L246)):

```csharp
        var tonic = kd.DiatonicTriads[0];
        var last = ordered[^1];
        if (ordered.Count < 2 || last.RootPc != tonic.RootPc || last.Quality != tonic.Quality) return 0;
```

With C D G, the last two chords are D G, a V–I of G major: G major holds all three chords and gets the cadence weight as well. Given the four chords, `Identify` does put C major first: its count is 2, since D major isn't one of C major's triads, and the cadence adds 2. The tool then groups the keys whose count is 2 as "tied at the highest score": C major, D major, A minor, B minor. The next three skip as many keys as the top holds, not the keys it holds, so A minor and B minor come back as partial matches, and G major, which counts 3, is in neither list. The same grouping, on the question as the chatbot reads it, gives C♯m7b5 F♯7 Bm a top of six keys at 1/3, with B minor first, and G♯ minor at 2/3 among the partial matches: the model is told the top is the highest score, and a partial match scores higher. That happens twice in the 90 questions.

The 16 dropped sharps would be read with one change to `main`'s pattern: replace the final `\b` with `(?!\w)`, "not followed by a word character". Checked with .NET's regex engine on the 90 questions: 74 are read as written with the current pattern, 90 with the lookahead.

## The relative key

Each candidate carries its relative key, and the skill's prompt shows it to the model:

```text
== The relative key each candidate carries, against the textbook
a826864: 30 keys, 6 with another relative key: A# minor → Db major; B major → Ab minor; C# major → Bb minor; D# minor → Gb major; F# major → Eb minor; G# minor → Cb major
6baf32e: 30 keys, 6 with another relative key: A# minor → Db major; B major → Ab minor; C# major → Bb minor; D# minor → Gb major; F# major → Eb minor; G# minor → Cb major
```

The service finds the relative key by pitch-class set: the first key of the other mode with the same seven pitch classes ([lines 93-101](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/KeyIdentificationService.cs#L93-L101)):

```csharp
        return [.. items.Select(item =>
        {
            var (key, name, pcs, triads, symbols) = item;
            var mask     = pcs.Aggregate(0, (acc, pc) => acc | (1 << pc));
            var sibling  = byMask.GetValueOrDefault(mask)
                               ?.FirstOrDefault(x => x.Mode != key.KeyMode);
            return new DomainKeyData(name, sibling?.Name ?? string.Empty, symbols, pcs, triads);
        })];
```

`Key.Items` lists the major keys from C♭ to C♯, then the minor keys from A♭ to A♯ ([`Key.cs` lines 49-50](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Tonal/Key.cs#L49-L50)). B major has the pitch classes of C♭ major, A♭ minor and G♯ minor, and the first minor key of the four is A♭ minor. Six keys get the relative key of their enharmonic twin. In [lesson 9](../09-every-interval-every-key/), `ScaleInfoSkill` got the same six wrong the same way ([#769](https://github.com/GuitarAlchemist/ga/issues/769)).

## What the model reads

`BuildPrompt` is private as well; the program calls it by reflection with what `ExecuteAsync` passes it, and prints the data part of the prompt:

```text
== The data KeyIdentificationSkill puts in the model's prompt for "What key is Db Gb Ab Db in?", at a826864
── TOP MATCHES (all tied at the highest score) ──
• A# minor  (3/3 chords diatonic)
  Relative key : Db major
  Diatonic set : A#m, B#dim, C#, D#m, E#m, F#, G#
• Bb minor  (3/3 chords diatonic)
  Relative key : Db major
  Diatonic set : Bbm, Cdim, Db, Ebm, Fm, Gb, Ab
• C# major  (3/3 chords diatonic)
  Relative key : Bb minor
  Diatonic set : C#, D#m, E#m, F#, G#, A#m, B#dim
• Db major  (3/3 chords diatonic)
  Relative key : Bb minor
  Diatonic set : Db, Ebm, Fm, Gb, Ab, Bbm, Cdim

── PARTIAL MATCHES ──
• Ab major  (2/3 chords diatonic)
• D# minor  (2/3 chords diatonic)
• Eb minor  (2/3 chords diatonic)
```

The instructions that follow ask the model to explain which key "(or keys)" the progression is in and, "If two keys tie (e.g. C major and A minor)", how to tell them apart by listening for the tonic. Here four keys tie, and they are two keys, each spelled twice. A♯ minor comes first, with D♭ major as its relative key; C♯ major's diatonic set spells E♯m and B♯dim for a question written in D♭. On `main`, the same list starts with C♯ major.

## Where the course stops

- **The model isn't run.** What it says when four keys are "all tied", or when a sharp has been dropped, needs the model (*to verify*).
- **Routing isn't tested.** Which of the two surfaces answers is decided by routing, which needs the embedding model; both compute the same answer.
- **`main`'s service runs against the pinned domain.** `Key.Items` and `Key.Notes` are unchanged on `main`; the rest of `main`'s chatbot isn't run.
- **One phrasing.** Every question is "What key is … in?", with the chords separated by spaces.
- **Textbook progressions only**: root-position triads and seventh chords, no inversions, borrowed chords or modulations.

## Reported upstream

- Reported after this lesson was written: the symbols `main` still skips, the dropped sharps and the repeated chords `ExtractChords` drops, as GA issue [#771](https://github.com/GuitarAlchemist/ga/issues/771); the ties between keys with the same pitch classes, the top matches grouped by count, the relative keys and the SKILL.md's single-candidate example, as [#772](https://github.com/GuitarAlchemist/ga/issues/772). The seventh chords skipped at the pin are read on `main` since [#625](https://github.com/GuitarAlchemist/ga/pull/625). All are listed in the [journal](../journal/).

## Exercises

1. The final `\b` of `main`'s `ChordPattern` drops a sharp before a space. Replace it so that `F#`, `C#` and `G#` keep their sharp and `C#m7b5` and `Cmaj7#11` are still read whole. Which of the 90 questions change?
2. `ExtractChords` removes repeated chords. What would `main` answer for C D G C if it kept them, and what else must change before the model gets C major alone at the top?
3. Rewrite the relative-key lookup so that B major gets G♯ minor and G♯ minor gets B major, without comparing pitch-class sets.
4. For "What key is Db Gb Ab Db in?", `main` puts C♯ major first. Which rule, added before the name, would give D♭ major, and what would it give for "What key is C# F# G# C# in?"?

<details>
<summary>Solutions</summary>

1. Replace the final `\b` with `(?!\w)`: after `F#` the next character is a space, which isn't a word character, so the match keeps the `#`; after `Cmaj7#11` it is a space too, and the pattern has already consumed the `#11`. The 16 `r` questions of `main` are then read as written, and the other 74 read the same chords as before. Checked with .NET's regex engine on the 90 questions; what `Identify` answers for the 16 needs a run (*to verify*).
2. Given C D G C, `Identify` puts C major first, with a count of 2 and a cadence of 2. The tool would then group the four keys that count 2 and leave G major, which counts 3, out of both lists (the second question in full above shows it). The selection has to use `Identify`'s order: the service would expose each key's score, the count plus the cadence, and the tool would keep the keys whose score equals the first key's, then the three keys that follow them in `Identify`'s order. C major would be alone at 4, followed by G major and E minor at 3. Worked by hand from the code.
3. Take the relative key from the scale: a major key's relative minor starts on its sixth degree, and a minor key's relative major on its third. The domain's `Key.Notes` spells those degrees right (lesson 9): B major's sixth is G♯, G♯ minor's third is B. The lookup becomes a name built from `key.Notes[5]` or `key.Notes[2]` and the other mode, and no pitch-class set is involved. Worked by hand; the six keys are checked against the textbook in the output above.
4. Prefer the key whose tonic is spelled like the first chord's root. `OpensOnTonic` compares pitch classes, so D♭ and C♯ both pass; comparing names, D♭ major passes and C♯ major doesn't. For C♯ F♯ G♯ C♯ the same rule gives C♯ major, but the question must first keep its sharps (exercise 1): today it is read as C F G and answered C major. Worked by hand from the code.

</details>

## Key takeaways

- When the model is told to use only the data it is given, the answer is decided before the model runs, by what the skill reads in the question.
- A regular expression that reads chords out of prose decides what the key skill hears: at the pin it skipped every seventh chord, and on `main` it still reads F♯ as F.
- A final `\b` after `#` fails before a space. The same bug is now in three patterns of GA's chatbot.
- Removing repeated chords cuts off the progression's ending, and `main`'s cadence weight then hears the cut-off end as the cadence: D G in C D G C.
- A ranking and the selection built on it must use the same score: `main` orders the keys by count plus cadence, and the tool still groups them by count.
- Keys with the same pitch classes can only be told apart by the question's spelling. An order by name picks C♯ major for D♭.

## Sources

- GuitarAlchemist/ga at [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `Common/GA.Business.ML/Agents/KeyIdentificationService.cs`, `Common/GA.Business.ML/Agents/Mcp/KeyIdentificationMcpTools.cs`, `Common/GA.Business.ML/Agents/Skills/KeyIdentificationSkill.cs`, `skills/key-identification/SKILL.md`, `Common/GA.Domain.Core/Theory/Tonal/Key.cs`.
- GA at [`6baf32e`](https://github.com/GuitarAlchemist/ga/commit/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40), committed on 2026-09-25 UTC: `Common/GA.Domain.Services/Tonal/KeyIdentificationService.cs`, compiled by the course. GA's `main` at [`5c3a52a`](https://github.com/GuitarAlchemist/ga/commit/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26), committed on 2026-09-30 UTC, for the comparison of the service, the tool, the skill and the SKILL.md.
- *Open Music Theory*, the chapters on diatonic triads, the minor scale's raised seventh and cadences, for the textbook's progressions.
