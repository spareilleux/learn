---
title: "Lesson 20: Generated progressions"
description: "Guitar Alchemist's MCP server writes chord progressions from nine templates with ga_generate_progression, without a model; the chatbot doesn't call it. Every chord has the right notes, and 712 of 750 are spelled as a textbook spells them in the 15 keys of each mode: D, G and C minor get sharps, and twelve names per spelling can't write Cb, Fb or E#. GA's own twelve-key table writes the same B for the IV of Gb. A chord symbol passes as a key, a lowercase b turns B major to flats, and the length has no limit: 100000 chords make 17,300,216 characters. Stitched with ga_voice_leading_pair, as the answer suggests, the first pairs meet at 17 of 32 places on main."
sidebar:
  label: 20. Generated progressions
  order: 20
---

[Lesson 19](../19-voice-leading-pairs/) ran `ga_voice_leading_pair`, a tool of `GaMcpServer`, GA's MCP server. The same file holds its companion, `ga_generate_progression`: given a key root and a template name, it writes a chord progression, "Deterministic — no LLM" ([`CompositionTools.cs` lines 108-177](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L108-L177)). Its answer ends with a note: "Compose by passing each chord to ga_search_voicings; stitch with ga_voice_leading_pair for smooth-voiced transitions". The chatbot doesn't call it, and the skill drafted to call it is parked, like lesson 19's ([`skills-dev/_pending-tools/README.md` line 49](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/README.md#L49)).

All GA links point to commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), the course's pin, unless they name another. `CompositionTools.cs` and `ChordPitchClasses`, which reads the root, are the same on GA's `main` at [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/commit/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) (2026-10-01), so the program asks for the progressions at the pin only. The last section stitches them with `ga_voice_leading_pair`, whose search changed on `main`, so `GaMain` runs it again. The output comes from:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l20
dotnet run --project code/ga-ai/GaMain -c Release -- l20
```

## How the tool answers

Each template is a list of steps: an offset in semitones from the key root, a chord quality and a Roman numeral ([lines 27-37](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L27-L37)):

```csharp
    private record ProgressionStep(int SemitoneOffset, string Quality, string RomanLabel);

    private static readonly Dictionary<string, ProgressionStep[]> Templates = new(StringComparer.OrdinalIgnoreCase)
    {
        // Jazz staples
        ["ii-V-I"] =
        [
            new(2, "m7",  "ii7"),
            new(7, "7",   "V7"),
            new(0, "maj7", "Imaj7"),
        ],
```

The nine templates are ii-V-I, circle-of-fifths, rhythm-changes-a, I-V-vi-IV, I-vi-IV-V, canon, 12-bar-blues, and two in minor, minor-vamp and andalusian ([lines 29-106](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L29-L106)). The tool checks the root with `ChordPitchClasses.TryParse` ([line 139](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L139)), then names each chord's root from one of two arrays of twelve names, sharps or flats ([lines 344-380](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L344-L380)):

```csharp
    private static string BuildSymbol(int rootPc, ProgressionStep step, bool preferFlats)
    {
        var chordRootPc = (rootPc + step.SemitoneOffset) % 12;
        var rootName = preferFlats
            ? PitchClassToFlatName(chordRootPc)
            : PitchClassToSharpName(chordRootPc);
        return rootName + step.Quality;
    }

    private static string PitchClassToSharpName(int pc) => pc switch
    {
        0  => "C",  1  => "C#", 2  => "D",  3  => "D#",
        4  => "E",  5  => "F",  6  => "F#", 7  => "G",
        8  => "G#", 9  => "A",  10 => "A#", 11 => "B",
        _  => "C",
    };

    private static string PitchClassToFlatName(int pc) => pc switch
    {
        0  => "C",  1  => "Db", 2  => "D",  3  => "Eb",
        4  => "E",  5  => "F",  6  => "Gb", 7  => "G",
        8  => "Ab", 9  => "A",  10 => "Bb", 11 => "B",
        _  => "C",
    };

    /// <summary>
    ///     True when the user's key root is on the flat side of the circle of fifths
    ///     (F, Bb, Eb, Ab, Db, Gb — i.e. the symbol contains a 'b' OR is plain F). Used
    ///     to pick flat vs sharp enharmonic spelling for generated chord symbols so
    ///     "ii-V-I in Bb" yields Bbmaj7 rather than the sharp-spelled A#maj7.
    ///     C is treated as sharp-side (the pop convention for chromatic chords in C).
    /// </summary>
    private static bool PrefersFlats(string root)
    {
        var r = root.Trim();
        return r.Contains('b') || r.Equals("F", StringComparison.OrdinalIgnoreCase);
    }
```

Each chord of the answer carries its Roman numeral, its symbol, a `degree`, its quality and its pitch classes ([lines 158-165](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L158-L165)). `degree` holds the offset in semitones, 7 for V, not the degree of the scale.

## The templates in every key

The program asks for the seven major templates in the 15 major keys of a key signature, from C♭ to C♯, and the two minor ones in the 15 minor keys, from A♭ minor to A♯ minor. A textbook writes the root of each chord with the letter of its Roman numeral's degree in the key, and the accidental that reaches the note: in D minor, ♭VI is B♭, never A♯. The program compares each symbol with that spelling, and the pitch classes with the chord's:

```text
== The nine templates in the keys a textbook writes, at the pin, against the textbook's spelling
template           mode    keys   chords   spelled right   pitch classes right
ii-V-I             major   15     45       44              45
circle-of-fifths   major   15     60       59              60
rhythm-changes-a   major   15     120      118             120
I-V-vi-IV          major   15     60       57              60
I-vi-IV-V          major   15     60       57              60
canon              major   15     120      113             120
12-bar-blues       major   15     180      167             180
minor-vamp         minor   15     45       44              45
andalusian         minor   15     60       53              60
chords 750: spelled right 712, pitch classes right 750
the chords spelled otherwise, as the tool writes them, with the textbook's spelling and their count:
  Cb major   Bmaj7 for Cbmaj7 3, B for Cb 4, E for Fb 4, B7 for Cb7 7, E7 for Fb7 3
  C# major   Fm7 for E#m7 1, Fm for E#m 1
  Gb major   B for Cb 4, B7 for Cb7 3
  A# minor   F7 for E#7 1, F for E# 1
  D minor    A# for Bb 1
  G minor    D# for Eb 1
  C minor    A# for Bb 1, G# for Ab 1
  Eb minor   B for Cb 1
  Ab minor   E for Fb 1
```

- **Every chord has the right pitch classes, and 712 of 750 are spelled as a textbook spells them.** The fault is only in the names.
- **D, G and C minor get sharps.** `PrefersFlats` looks for a `b` in the root, or the root F; its comment lists the flat side as "F, Bb, Eb, Ab, Db, Gb". The three minor keys have flats in their key signature but none in their name: the andalusian in C minor is written with A♯ and G♯ for B♭ and A♭.
- **Twelve names per array can't spell every key.** Each array has one name per pitch class. In C♭ major, the tonic is written B and the IV E; in G♭ major, the IV is written B; in C♯ major, the iii is written Fm for E♯m; in A♯ minor, the V is written F7 for E♯7. E♭ minor and A♭ minor get B and E for their ♭VI, C♭ and F♭. Lessons 10 and 18 found the same twelve names in other parts of GA.

## GA's own tables

`ChordProgressions.yaml`, GA's configuration of progressions, ends with transposition tables: three of them answer a template of the tool ([lines 580-695](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Config/ChordProgressions.yaml#L580-L695)). The program reads them and asks the tool for the same keys:

```text
== The tool against the twelve-key tables of GA's ChordProgressions.yaml, at the pin
table                                template        keys   same chords   spelled otherwise by a textbook
ii–V–I (Major) — 12 keys             ii-V-I          12     12            none
Pop I–V–vi–IV — 12 keys (triads)     I-V-vi-IV       12     12            Gb: Gb Db Ebm B, textbook Gb Db Ebm Cb
12-Bar Blues — common guitar keys    12-bar-blues    5      5             none
```

- **The tool and GA's tables agree on every row, a wrong chord included.** The table of I-V-vi-IV writes B for the IV of G♭, as the tool does ([line 685](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Config/ChordProgressions.yaml#L685)); a textbook writes C♭. Two sources that agree aren't a check: the table can't serve as the tool's test.

## The roots it reads

`ChordPitchClasses` reads a chord symbol, not a key. Its table of roots ignores case, and lists C♭ but not E♯, and no `♭` ([`MusicalQueryEncoder.cs` lines 166-171](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/MusicalQueryEncoder.cs#L166-L171)). The program asks for a few roots a guitarist or an agent could write:

```text
== The roots the tool reads, at the pin
root       template       chords, or the error
C          I-V-vi-IV      C G Am F
c          I-V-vi-IV      C G Am F
B          I-V-vi-IV      B F# G#m E
b          I-V-vi-IV      B Gb Abm E
Bb         I-V-vi-IV      Bb F Gm Eb
bb         I-V-vi-IV      Bb F Gm Eb
B♭         I-V-vi-IV      unknown root 'B♭' — try C, D, Eb, F#, etc.
Cb         I-V-vi-IV      B Gb Abm E
E#         I-V-vi-IV      unknown root 'E#' — try C, D, Eb, F#, etc.
F major    I-V-vi-IV      F C Dm A#
D minor    I-V-vi-IV      D A Bm G
D minor    andalusian     Dm C A# A
Dm         andalusian     Dm C A# A
C          andalusian     Cm A# G# G
C7b9       andalusian     Cm Bb Ab G
Cmaj7      ii-V-I         Dm7 G7 Cmaj7
```

- **A lowercase b turns B major to flats.** The parser reads "b" as B, then `PrefersFlats` finds a `b` in it: `B Gb Abm E`. "c" and "bb" are right.
- **A chord symbol passes as a root, and its quality is dropped.** "D minor" and "Dm" are read as D, so I-V-vi-IV in "D minor" gets D major's chords, without a warning. `PrefersFlats` compares the whole string with "F", so "F major" gets sharps: `F C Dm A#`.
- **Any `b` in the string decides the spelling.** "C7b9" is read as C, and the `b` of its flat ninth turns the andalusian in C minor to flats: `Cm Bb Ab G`, the spelling that "C" doesn't get.
- **`♭` and E♯ are refused,** with an error that suggests "C, D, Eb, F#, etc.".

## The length

`length` loops or truncates the template ([lines 148-151](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L148-L151)). In the same file, `limit` and `candidatesPerChord` are clamped ([lines 202-203](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L202-L203)); `length` isn't:

```text
== The length, at the pin
length   template       chords    last chord, characters of JSON
(none)   12-bar-blues   12        V7 G7, 2288
0        12-bar-blues   12        V7 G7, 2288
-1       12-bar-blues   12        V7 G7, 2288
4        12-bar-blues   4         I7 C7, 903
13       12-bar-blues   13        I7 C7, 2461
100000   12-bar-blues   100000    I7 C7, 17300216
```

- **0 and a negative length give the template's own length,** without a warning.
- **A length of 100000 returns 100000 chords, 17,300,216 characters of JSON,** one answer far larger than an agent's context window.

## Stitching the progression

The program follows the tool's note for each template, in C major or A minor. It asks `ga_voice_leading_pair` for each move between two chords, and takes the first pair. Two first pairs meet when the second starts on the voicing where the first ends; otherwise a guitarist must jump from one voicing of the chord to another. The program also looks, among the same 15 candidates of each chord, for the joined path that moves least: one voicing per chord, the moves added up with the tool's own distance.

```text
== Each template stitched with ga_voice_leading_pair, in C major or A minor, at the pin
template           chords  moves      first pairs meet   sum of first pairs  least joined path
ii-V-I             3       2          0 of 1             9                   10
circle-of-fifths   4       3          0 of 2             13                  15
rhythm-changes-a   8       7          0 of 6             35                  40
I-V-vi-IV          4       3          0 of 2             13                  15
I-vi-IV-V          4       3          1 of 2             13                  15
canon              8       7          1 of 6             33                  42
12-bar-blues       12      11         4 of 10            31                  34
minor-vamp         3       2          0 of 1             6                   8
andalusian         4       3          0 of 2             12                  16
places where two first pairs should meet 32: they meet at 6; templates whose least joined path moves as little as the sum of first pairs 0 of 9
I-V-vi-IV, the first pairs: x-x-2-0-1-x C/E → x-x-0-0-0-3 G/D, 6; x-2-0-0-x-x G/B → x-3-0-2-x-x D5/C, 3; x-3-2-2-x-x Am/C → x-3-3-2-x-1 F/C, 4
I-V-vi-IV, the least joined path: x-3-2-0-1-x C → x-2-0-0-x-x G/B → x-3-2-2-x-x Am/C → x-3-3-2-x-1 F/C, 15
```

- **At the pin, the first pairs meet at 6 of 32 places, and every joined path moves more than the first pairs added up.** In I-V-vi-IV, the first pair for C → G ends on `x-x-0-0-0-3`, and the first for G → Am starts on `x-2-0-0-x-x` and ends on `x-3-0-2-x-x`, which the index names D5/C.

```text
== Each template stitched with ga_voice_leading_pair, in C major or A minor, on main
template           chords  moves      first pairs meet   sum of first pairs  least joined path
ii-V-I             3       2          1 of 1             6                   6
circle-of-fifths   4       3          2 of 2             10                  10
rhythm-changes-a   8       7          3 of 6             21                  25
I-V-vi-IV          4       3          0 of 2             9                   9
I-vi-IV-V          4       3          1 of 2             9                   9
canon              8       7          3 of 6             27                  27
12-bar-blues       12      11         7 of 10            24                  28
minor-vamp         3       2          0 of 1             7                   7
andalusian         4       3          0 of 2             14                  14
places where two first pairs should meet 32: they meet at 17; templates whose least joined path moves as little as the sum of first pairs 7 of 9
I-V-vi-IV, the first pairs: x-x-2-x-1-3 C/E → x-x-0-x-0-3 G/D, 3; x-x-0-0-0-x G/D → x-x-2-2-1-x Am/E, 5; x-x-x-2-1-0 Am → x-x-x-2-1-1 F/A, 1
I-V-vi-IV, the least joined path: x-x-2-0-1-x C/E → x-x-0-0-0-x G/D → x-x-2-2-1-x Am/E → x-x-3-2-1-x F, 9
```

- **On `main`, they meet at 17 of 32 places.** In 7 of the 9 templates, a joined path moves exactly as little as the first pairs added up, but in five of them the first pairs don't all meet. In I-V-vi-IV, the first pair for C → G ends on `x-x-0-x-0-3` and the next starts on `x-x-0-0-0-x`, two voicings of G; the joined path moves 9 semitones too, without the jump.
- **In rhythm-changes-a and 12-bar-blues, any joined path moves more:** 25 semitones instead of 21, 28 instead of 24. The tool answers one move at a time. Choosing one voicing per chord takes a search over the whole progression, like the one the program runs.

## The skill draft that would call it

`skills-dev/_pending-tools/progression-generator/DRAFT.md` is a chatbot skill written to call `ga_generate_progression` ([lines 1-24](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/progression-generator/DRAFT.md#L1-L24)). Like lesson 19's, it describes another tool:

- arguments `mood`, `key`, `length` with a default of 4, `style` and `complexity` ([lines 32-38](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/progression-generator/DRAFT.md#L32-L38)), where the tool takes `root`, `template` and `length`;
- `Chords`, `RomanNumerals`, `Style` and `Rationale` in the answer ([lines 40-45](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/progression-generator/DRAFT.md#L40-L45)), where the tool returns `chords`, with no style and no rationale;
- keys written "D minor" and "F major" ([lines 49-52](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/progression-generator/DRAFT.md#L49-L52)): passed as a root, "D minor" is read as D, and "F major" gets sharps;
- an example answer, Dm – B♭maj7 – Gm – A7 ([lines 56-63](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/progression-generator/DRAFT.md#L56-L63)), that no template writes;
- a cross-reference to `Common/GA.Business.ML/Agents/Mcp/ProgressionMcpTools.cs` ([line 77](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/progression-generator/DRAFT.md#L77)), a file that GA has neither at the pin nor on `main`.

## Where the course stops

- **The textbook is the course's:** the root's letter follows the Roman numeral's degree, in the 15 key signatures of each mode. The tool's description also offers D♯, G♯ and A♯ as roots for the major templates, keys a textbook writes E♭, A♭ and B♭; the course doesn't grade them.
- **The stitching runs on lesson 3's corpus,** in C major and A minor only, with the 15 candidates the tool uses by default.
- **The joined path is the course's search,** with the tool's own distance; lesson 19 showed that this distance pairs the lowest notes when the sizes differ.
- **The program calls the tools' methods directly,** not through an MCP client and GA's server.

## Exercises

1. In the roots table, "C" writes the andalusian in C minor with sharps and "C7b9" with flats. Which line of the code makes the difference, and why is no root read as C spelled with flats otherwise?
2. In C♯ major, the canon's iii is written Fm. What does a textbook write, and why can neither array of names write it?
3. On `main`, the first pairs of I-V-vi-IV move 3, 5 and 1 semitones. Why can't a guitarist play them in a row, and how much does the joined path the program finds move?
4. The draft maps "Jazz ii-V-I in F" to the key "F major". Passed as the root of ii-V-I, does the sharp spelling show? And with I-V-vi-IV?

<details>
<summary>Solutions</summary>

1. `PrefersFlats` returns true only if the root contains a `b` or equals F ([line 379](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L379)). The parser reads C from "C", "c" or a chord symbol on C, and B♯ isn't in its table. Only a `b` in the quality, like the flat ninth of "C7b9", turns the spelling to flats.
2. E♯m: the iii of C♯ major is on E, raised. The sharp array gives the pitch class 5 the name F, and the flat array too; neither has E♯.
3. The first pair for C → G ends on `x-x-0-x-0-3`, and the next starts on `x-x-0-0-0-x`: two voicings of G, so the hand jumps between them. The joined path `x-x-2-0-1-x` → `x-x-0-0-0-x` → `x-x-2-2-1-x` → `x-x-3-2-1-x` moves 9 semitones, as much as the first pairs added up.
4. With ii-V-I, no: the chords fall on G, C and F, which both arrays name without an accidental, and the tool answers `Gm7 C7 Fmaj7`. With I-V-vi-IV, yes: the IV falls on B♭, and the table shows `F C Dm A#`. Checked by running the pinned tool outside the course's expected output.

</details>

## Key takeaways

- A key's spelling follows its key signature, not the letters of its name: a test for `b` in the name misses D, G and C minor.
- One name per pitch class can't spell keys with E♯, B♯, C♭ or F♭.
- Two sources that agree aren't a check: GA's table shares the tool's B for C♭.
- A parameter without a limit can return an answer no agent can read.
- A pairwise answer can't plan a sequence: the best pair for each move doesn't make a path.

## Sources

- GuitarAlchemist/ga at [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `GaMcpServer/Tools/CompositionTools.cs`, `Common/GA.Business.ML/Search/MusicalQueryEncoder.cs`, `Common/GA.Business.Config/ChordProgressions.yaml`, `skills-dev/_pending-tools/progression-generator/DRAFT.md`, `skills-dev/_pending-tools/README.md`.
- GuitarAlchemist/ga at [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/tree/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a): the same tool, parser, table and draft, and the search of lesson 16.
- The course's programs: `code/ga-ai/GaAi/Lesson20.cs`, `code/ga-ai/GaMain/Program.cs`, `code/ga-ai/Shared/ProgressionProbe.cs`.
