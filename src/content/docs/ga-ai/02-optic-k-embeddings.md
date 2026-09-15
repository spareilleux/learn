---
title: "Lesson 2: OPTIC-K embeddings"
description: The 240 numbers Guitar Alchemist computes for every chord shape — the partitions and their weights, the version history, real vectors of six open chords, the weighted similarity computed by hand, what the vector is invariant to, and two positional-record bugs that flatten it.
sidebar:
  label: 2. OPTIC-K embeddings
  order: 2
---

An **embedding** is an array of numbers that describes an object, built so that similar objects get similar arrays. Text embeddings come out of a neural network and nobody can say what dimension 417 means. OPTIC-K is the opposite: every one of its 240 numbers is computed by C# code from music theory, and has a name. That makes it a good first embedding to study, because each number can be checked. This lesson computes the vectors of six chords with GA's own classes and checks them.

All GA links point to commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6). The outputs come from:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l2
```

## Where the name comes from

In 2008, Clifton Callender, Ian Quinn and Dmitri Tymoczko described musical objects by the equivalences you choose to ignore: **O**ctave, **P**ermutation (the order of the notes), **T**ransposition, **I**nversion and **C**ardinality (doubled notes) ([*Generalized Voice-Leading Spaces*](https://doi.org/10.1126/science.1153021)). Ignore octave and order, and a chord becomes a set of pitch classes; ignore transposition and inversion too, and it becomes a set class, the subject of lesson 4 of the [music theory course](../../music-theory-ga/04-set-classes/). A **K**, for complementarity, comes from [Harmonious](https://harmoniousapp.net/), Jared Updike's chord and scale reference: its [Equivalence Groups](https://harmoniousapp.net/p/ec/Equivalence-Groups) page adds the letter and notes that it isn't standard terminology. GA names its embedding after the full list, and its [`OpticKClass`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/OpticKClass.cs#L3-L15) cites that page. The comments of [`TheoryVectorService`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/Services/TheoryVectorService.cs#L41-L77) map each block of numbers to the letters it is meant to cover.

## The schema

[`EmbeddingSchema.Partitions`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/EmbeddingSchema.cs#L117-L137) is the registry every consumer is meant to read: a name, a range of the 240 slots, a weight and a role for each partition.

```text
== EmbeddingSchema.Partitions (OPTIC-K-v1.8)
partition     raw      dims  role        weight
IDENTITY      0-5      6     Identity    0.00
STRUCTURE     6-29     24    Similarity  0.45
MORPHOLOGY    30-53    24    Similarity  0.25
CONTEXT       54-65    12    Similarity  0.20
SYMBOLIC      66-77    12    Similarity  0.10
EXTENSIONS    78-95    18    Info        0.00
SPECTRAL      96-108   13    Info        0.00
MODAL         109-148  40    Similarity  0.10
HIERARCHY     149-163  15    Info        0.00
ATONAL_MODAL  164-227  64    Info        0.00
ROOT          228-239  12    Similarity  0.05
TotalDimension          240
sum of dims             240
sum of weights          1.15
CompactDimension        124
CompactLayoutV4         optk-v4-pp-r:STRUCTURE:0-23,MORPHOLOGY:24-47,CONTEXT:48-59,SYMBOLIC:60-71,MODAL:72-111,ROOT:112-123
SchemaHashV4            0x37CD8ECF
```

What each partition describes, from the generator and its services:

| Partition | Describes | Computed from |
|---|---|---|
| STRUCTURE | which pitch classes, how many, the interval-class vector | the set of notes, octave and order ignored |
| MORPHOLOGY | the shape on the fretboard: bass and top note, span, fret position, barre | the physical voicing |
| CONTEXT | harmonic function, tension, motion | the analysis of the chord |
| SYMBOLIC | tags such as technique and style | tags from the analysis |
| MODAL | how strongly the chord suggests each mode: 40 slots, 33 of them named after a mode | the notes, relative to a root |
| ROOT | the root pitch class, one-hot | the root |
| IDENTITY, EXTENSIONS, SPECTRAL, HIERARCHY, ATONAL_MODAL | object kind, psychoacoustic and spectral features, complexity, set-theoretic families | stored, never scored |

Three things to notice:

- **Only the six "Similarity" partitions are searched.** Together they hold 124 numbers, the `CompactDimension`. The five others are information for other tools; the index file doesn't even store them (lesson 3).
- **The weights add up to 1.15, not 1.** A vector compared with itself therefore scores 1.15, as the output below shows. Nothing breaks, since only the ranking matters, but a score is not a cosine in the usual 0 to 1 sense.
- **The layout string is hashed.** `SchemaHashV4` is the [CRC-32](https://learn.microsoft.com/dotnet/api/system.io.hashing.crc32) of `CompactLayoutV4` ([lines 154-186](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/EmbeddingSchema.cs#L154-L186)). Issue [#616](https://github.com/GuitarAlchemist/ga/issues/616) reports `0x37CD8ECF` for GA's live index of 313,047 voicings: the course and that index use the same layout.

Next to the registry, `EmbeddingSchema` keeps older constants for each partition. Three of them no longer match:

```text
== Loose constants next to the registry
constant                 value      registry
HierarchyDim             8          15
AtonalModalDim           17         64
ExtensionsEnd            96         240
```

`ExtensionsEnd` is right, 96 is where EXTENSIONS ends, but its [comment](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/EmbeddingSchema.cs#L406-L407) says it equals `TotalDimension`, which was true when the vector had 96 numbers. The two others matter more: [`ModalVectorService`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/Services/ModalVectorService.cs#L116) allocates its ATONAL_MODAL array with `AtonalModalDim`, 17, and [`WriteInto`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/EmbeddingSchema.cs#L219-L220) copies whatever length it's given without complaint, so 47 of that partition's 64 slots can never be anything but zero. Lesson 3 finds exactly 47 on a whole corpus.

## Versions

The schema grew by appending partitions. The history below comes from GA's [schema documents](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Documentation/Schema), the version comments in `EmbeddingSchema.cs` and two commits:

| Version | Dimensions | What changed | Source |
|---|---|---|---|
| v1.2.1 | 96 | EXTENSIONS appended; "indices 0–77 are unchanged" | `OPTIC-K_Embedding_Schema_v1.2.1.md`, dated 2026-01-11 |
| v1.3, v1.3.1 | 108, 109 | SPECTRAL, then spectral entropy at index 108 | `OPTIC-K_Embedding_Schema_v1.3.md`, `_v1.3.1.md` |
| v1.4 | 216 | defined indices 0-135, the rest reserved | `OPTIC-K_Embedding_Schema_v1.4.1.md`, dated 2026-01-21 |
| v1.6 | | MODAL and HIERARCHY | comments in `EmbeddingSchema.cs` |
| v1.7 | 228 | ATONAL_MODAL | comments in `EmbeddingSchema.cs` |
| v1.8 | 240 | ROOT appended; the root bonus removed from STRUCTURE | commit [`95b5a9d9`](https://github.com/GuitarAlchemist/ga/commit/95b5a9d9), 2026-04-19 |

The index format has its own history: v4 normalized the whole compact vector at once, v4-pp normalizes each partition separately (commit [`3ba35365`](https://github.com/GuitarAlchemist/ga/commit/3ba35365), 2026-04-19), and v4-pp-r adds ROOT, which moved the compact size from 112 to 124.

The documentation has not followed. The newest schema document stops at v1.4.1, and the one without a version in its name, `OPTIC-K_Embedding_Schema.md`, describes v1.3.1 and 109 dimensions. In the code, the generator's summary still says "228-dimensional canonical musical embedding (v1.7)" ([line 13](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/MusicalEmbeddingGenerator.cs#L13)) and its `Dimension` property "216 for v1.4/v1.5" ([line 55](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/MusicalEmbeddingGenerator.cs#L55)), while both return 240. When a comment and the registry disagree, trust the registry, and better, print it.

## From a chord shape to a document

Guitarists write chord shapes from the low E string to the high E: `x32010` is open C, with the low E muted. GA numbers strings the other way, from the high E, string 1, and its voicing generator builds positions in that order. The course's [`Voicings.FromShape`](https://github.com/spareilleux/learn/blob/8e335d7/code/ga-ai/GaAi/Voicings.cs#L39-L64) converts a chart into GA's order, then [`Voicings.Embed`](https://github.com/spareilleux/learn/blob/8e335d7/code/ga-ai/GaAi/Voicings.cs#L97-L103) runs the three steps GA's own tools run:

```csharp
var analysis = VoicingAnalyzer.Analyze(voicing);
var doc = VoicingDocumentFactory.FromAnalysis(voicing, analysis, tuningId: "guitar");
var raw = Generator.GenerateEmbeddingAsync(doc).GetAwaiter().GetResult();
```

The middle step builds a `ChordVoicingRagDocument`, a record of about fifty properties that the generator reads. Six chords:

```text
== From a chord shape to GA's voicing document
shape   GA diagram   GA name       pcs      MIDI            doc root inv   rootless function
x32010  0-1-0-2-3-x  C             0 4 7    64 60 55 52 48  4 E      1     yes  Functional Harmony
x35553  3-5-5-5-3-x  C             0 4 7    67 64 60 55 48  7 G      2     yes  Functional Harmony
032010  0-1-0-2-3-0  C/E           0 4 7    64 60 55 52 48 40 4 E      1     yes  Functional Harmony
x32000  0-0-0-2-3-x  Cmaj7         0 4 7 11 64 59 55 52 48  4 E      1     yes  Functional Harmony
x02210  0-1-2-2-0-x  Am            0 4 9    64 60 57 52 45  4 E      2     yes  Functional Harmony
320003  3-0-0-0-2-3  G             2 7 11   67 59 55 50 47 43 7 G      0     yes  Functional Harmony
```

The names are right. The document's root is not: it is E for open C and G for the barre C. [`VoicingDocumentFactory`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Rag/VoicingDocumentFactory.cs#L37-L38) takes the first MIDI note as both the root and the bass:

```csharp
RootPitchClass = analysis.MidiNotes.Length > 0 ? analysis.MidiNotes[0] % 12 : 0,
MidiBassNote = analysis.MidiNotes.Length > 0 ? analysis.MidiNotes[0] : 0,
```

Because the notes come string 1 first, `MidiNotes[0]` is the **highest** note, the melody note, not the bass and not the root. The inversion column is computed from that note too: open C in root position is reported as a first inversion. The chord root it is compared with is read by `PitchClass.Parse`, which takes the note names A and E for the numbers 10 and 11 ([lines 43-44](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Rag/VoicingDocumentFactory.cs#L43-L44)): outside the course program, a root-position E minor, `022000`, came out with the inversion -1. Every partition that reads `RootPitchClass` or `MidiBassNote` inherits the error: ROOT, MODAL, part of MORPHOLOGY.

## Two positional records

The "rootless" column says yes for all six chords, each of which contains its root. The cause is a pattern every C# developer should recognise. [`VoicingCharacteristics`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core/Analysis/Voicings/VoicingCharacteristics.cs#L3-L15) is a positional record of eleven parameters, and [`VoicingHarmonicAnalyzer`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Fretboard/Voicings/Analysis/VoicingHarmonicAnalyzer.cs#L31-L43) builds it with positional arguments:

```csharp
// The record: (ChordId, DissonanceScore, Consonance, IntervalSpread, NoteCount,
//              IntervalClassVector, IsRootless, DropVoicing, IsOpenVoicing, Features, SemanticTags)
return new(
    chordId,
    dissonanceScore,
    consonance,
    intervalSpread,
    pitchClasses.Count,
    pcSet.IntervalClassVector.ToString(),
    intervalSpread > 12,
    dropVoicing,
    false,
    [],
    semanticTags
);
```

`intervalSpread > 12`, "the notes span more than an octave", is what an **open voicing** means, and it lands in `IsRootless`; the constant `false` lands in `IsOpenVoicing`. The compiler can't object: both are `bool`. The same thing happens one level up, in [`VoicingAnalyzer`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Fretboard/Voicings/Analysis/VoicingAnalyzer.cs#L164), with a record declared as `PerceptualQualities(double Brightness, double ConsonanceScore, double Roughness, string TexturalDescription, string Register)`:

```csharp
var perceptualQualities = new PerceptualQualities(curVoiceChars.Consonance, 0, 0, "Neutral", "Medium");
```

The consonance goes into `Brightness`, and `ConsonanceScore` is always 0. The program prints both records for the six chords:

```text
== VoicingCharacteristics and PerceptualQualities, as VoicingAnalyzer fills them
shape   span    IsRootless  IsOpen    Consonance  Brightness   ConsonanceScore
x32010  16      True        False     1.000       1.000        0.000
x35553  19      True        False     1.000       1.000        0.000
032010  24      True        False     1.000       1.000        0.000
x32000  16      True        False     1.000       1.000        0.000
x02210  19      True        False     1.000       1.000        0.000
320003  24      True        False     1.000       1.000        0.000
```

The document copies `ConsonanceScore` into its `Consonance` property, and the generator computes CONTEXT's tension as `1.0 - doc.Consonance` ([line 102](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/MusicalEmbeddingGenerator.cs#L99-L104)). So the tension is 1 for every chord ever indexed. Issue [#616](https://github.com/GuitarAlchemist/ga/issues/616) measured the CONTEXT partition as "empty" with one constant dimension and blamed the literals passed next to it; the constant dimension is this one, and its cause is the record above. Named arguments, `new PerceptualQualities(Brightness: ..., ConsonanceScore: ...)`, would have made both slips visible at the call site.

## The 240 numbers of open C

```text
== The 240 values of x32010 (C), partition by partition
IDENTITY       3/6   1 0 1 0 0 1
STRUCTURE     10/24  1 0 0 0 1 0 0 1 0 0 0 0 0.5 0 0 1 1 1 0 0 1 0.83 1 0
MORPHOLOGY     7/24  0 0 0 0 1 0 0 0 0 0 0 0 0.17 0.83 1 0.87 -0.5 0.33 0 0 0 0 0 0
CONTEXT        1/12  0 0 0 0 1 0 0 0 0 0 0 0
SYMBOLIC       4/12  1 1 0 0 0 0 0 0 0 1 0 1
EXTENSIONS     9/18  0 1 0.4 0 0 0.57 0.33 0.47 0.2 0 0 0 0.33 0 0 1 0.6 0
SPECTRAL      13/13  0.2 0.26 0.61 0.37 0.4 0.47 0.29 0.6 0.53 0.29 0.64 0.5 0.16
MODAL          2/40  0 0 0 0 0 0.43 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.67 (+13 zeros)
HIERARCHY      1/15  0.33 0 0 0 0 0 0 0 0 0 0 0 0 0 0
ATONAL_MODAL  11/64  0.2 0.5 0 1 0 0 0.33 0.33 0.33 0 0.03 0.44 0.67 1 0 0.88 (+48 zeros)
ROOT           1/12  0 0 0 0 1 0 0 0 0 0 0 0
MODAL slots set: Aeolian=0.43, LydianAugmentedSharp2=0.67
```

STRUCTURE can be read by hand with [`TheoryVectorService.ComputeEmbedding`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/Services/TheoryVectorService.cs#L27-L94) open next to it:

| Slots | Values | Meaning |
|---|---|---|
| 0-11 | `1 0 0 0 1 0 0 1 0 0 0 0` | the chroma: pitch classes 0, 4 and 7, C E G |
| 12 | `0.5` | cardinality, 3 ÷ 12 × 2 |
| 13-18 | `0 0 1 1 1 0` | the interval-class vector `<001110>` of a major triad |
| 19 | `0` | complementarity, always passed as 0.0 |
| 20, 21 | `1`, `0.83` | consonance and brightness derived from the vector |
| 22 | `1` | "a root is known" |
| 23 | `0` | reserved |

The CONTEXT line is the constant tension of the previous section, at slot 4 of [`ContextVectorService`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/Services/ContextVectorService.cs#L43-L52); slots 6 to 11 are "reserved" and never written. The ROOT line has its 1 at pitch class 4, E, the top note. The MODAL slots are computed relative to a root as well, which would explain why a C major triad lights up Aeolian, a minor mode: read from E, C E G is E, G, C (an interpretation, *to verify* line by line in `ModalVectorService`).

Nine of MODAL's named slots are never set by any of the 15,360 voicings of lesson 3's corpus.

## Similarity by hand

GA compares two vectors partition by partition: the cosine of each similarity partition, multiplied by its weight, summed. [`WeightedPartitionCosine`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/EmbeddingSchema.cs#L277-L304) does it with [`TensorPrimitives.CosineSimilarity`](https://learn.microsoft.com/dotnet/api/system.numerics.tensors.tensorprimitives.cosinesimilarity), and skips a partition that is all zeros. The course prints each cosine against open C:

```text
== Cosine per partition, and GA's weighted score, against open C
pair             structure  morphology  context  symbolic  modal  root   weighted  compact dot
x32010 x35553    1.000      0.348       1.000    1.000     0.000  0.000  0.837     0.837
x32010 032010    1.000      0.997       1.000    0.750     1.000  1.000  1.124     1.124
x32010 x32000    0.883      0.998       1.000    0.816     0.541  1.000  1.033     1.033
x32010 x02210    0.888      0.998       1.000    0.816     0.153  1.000  0.996     0.996
x32010 320003    0.776      0.496       1.000    0.671     0.000  0.000  0.740     0.740
open C with itself: 1.150
```

The first row, open C against the barre C at the third fret, by hand:

`0.45 × 1.000 + 0.25 × 0.348 + 0.20 × 1.000 + 0.10 × 1.000 + 0.10 × 0.000 + 0.05 × 0.000 = 0.837`

Read musically, the table is surprising. The barre C has exactly the notes of open C, yet it scores lower than Am (0.996) and Cmaj7 (1.033). Its STRUCTURE is identical; what sinks it is ROOT and MODAL, both computed from the top note, G instead of E, and its different hand shape. Open C and C/E, which share their top five strings, score 1.124. And CONTEXT is 1.000 on every row: 0.20 of every score is a constant.

The last column is the dot product of the two compact vectors. [`ExtractCompact`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/EmbeddingSchema.cs#L241-L267) keeps the six similarity partitions, divides each by its Euclidean norm and multiplies it by the square root of its weight. Then for a partition `p`, `(√w · a/|a|) · (√w · b/|b|) = w · cos(a, b)`, and the dot product of two compact vectors is the weighted score. That's why the index stores compact vectors: a single dot product per voicing replaces six cosines.

## What the vector is invariant to

STRUCTURE's chroma ignores octaves and note order: any voicing of C E G gets the same twelve slots, which is why the barre C scores 1.000 there. Transposition is another matter. The course compares the STRUCTURE of C major with its eleven transpositions, and separately the slots 12 to 18, cardinality and interval-class vector:

```text
== STRUCTURE of C major (0 4 7) against its 11 transpositions (TheoryVectorService)
T    pcs        structure  icv dims
1    1 5 8      0.665      1.000
2    2 6 9      0.665      1.000
3    3 7 10     0.776      1.000
4    4 8 11     0.776      1.000
5    0 5 9      0.776      1.000
6    1 6 10     0.665      1.000
7    2 7 11     0.776      1.000
8    0 3 8      0.776      1.000
9    1 4 9      0.776      1.000
10   2 5 10     0.665      1.000
11   3 6 11     0.665      1.000
set classes swept                 222
invariant (min cosine > 0.9999)   1
mean of the minimum cosines       0.881
worst minimum cosine              0.514
```

The interval-class dimensions don't move; the whole partition does, because the chroma names the literal notes. Over every set class of two notes or more, one is invariant, the twelve-note chromatic set, the only set equal to all its transpositions. These are the numbers of GA's own sweep, [`state/quality/domain-invariants/README.md`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/state/quality/domain-invariants/README.md#L37-L47): "1 of 222 set classes is T-invariant", mean 0.88, worst 0.51. `TheoryVectorService` records the finding in a [comment](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/Services/TheoryVectorService.cs#L57-L64); [`RootVectorService`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/Services/RootVectorService.cs#L3-L7) still says that moving the root out made STRUCTURE "genuinely O+P+T+I-invariant".

So OPTIC-K is invariant to octave and order, as the name promises, and not to transposition or inversion: a search for "this shape in another key" can't rely on STRUCTURE.

## One MCP tool, two diagram orders

GA exposes the generator to AI assistants through an [MCP](https://modelcontextprotocol.io/) tool, `ga_generate_voicing_embedding`. Its [description](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingEmbeddingTool.cs#L42-L44) promises "a 228-dim OPTIC-K embedding vector" and gives the example `'x-3-2-0-1-0' for Cmaj7`. Its [parser](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingEmbeddingTool.cs#L134-L173) reads the first element as string 1, the high E, like GA's generator. The course copies that parser and feeds it the example:

```text
== ga_generate_voicing_embedding's example diagram, x-3-2-0-1-0
parsed by              GA diagram   MIDI             GA name          pcs
the MCP tool's parser  x-3-2-0-1-0  62 57 50 46 40   Dsus2/E          2 4 9 10
chord chart x32010     0-1-0-2-3-x  64 60 55 52 48   C                0 4 7
```

The example is written like a chord chart, low E first, and parsed high E first: an assistant following the description gets the vector of a different chord. Written low E first it would be open C, and still not Cmaj7. The [agentic coding course](../../agentic-coding/04-mcp/) makes the general point: an MCP tool's description is part of its interface, and the model believes it.

## Exercises

1. Using the table of cosines, compute the weighted score of open C against G (`320003`) by hand, and check it against the output.
2. Why does open C against Am score 1.000 on ROOT, when their roots are C and A?
3. The weights add up to 1.15. Change nothing in the code: how would you turn a GA score into a number between 0 and 1, and would it change any search result?
4. Rewrite the `PerceptualQualities` call of `VoicingAnalyzer` with named arguments, keeping the author's evident intent.

<details>
<summary>Solutions</summary>

1. `0.45 × 0.776 + 0.25 × 0.496 + 0.20 × 1.000 + 0.10 × 0.671 + 0.10 × 0.000 + 0.05 × 0.000 = 0.3492 + 0.124 + 0.20 + 0.0671 = 0.740`, the value printed.
2. Because the document's root is the top note, and both shapes have E on top, `64` in their MIDI lists. The ROOT one-hot of both has its 1 at pitch class 4.
3. Divide by 1.15, the sum of the weights, or by the score of a vector with itself. It changes no ranking, since every score is divided by the same constant. It matters only where a score is compared with a fixed threshold.
4. `new PerceptualQualities(Brightness: 0, ConsonanceScore: curVoiceChars.Consonance, Roughness: 0, TexturalDescription: "Neutral", Register: "Medium")`. "Keeping the intent" is a guess: the brightness was perhaps meant to be computed too. With named arguments, the question is at least visible in review.

</details>

## Key takeaways

- OPTIC-K is a hand-built embedding: 240 named numbers in 11 partitions, of which 6 partitions and 124 numbers are used for similarity, with weights summing to 1.15.
- Similarity is a weighted sum of per-partition cosines; storing each partition normalized and scaled by the square root of its weight turns it into a single dot product.
- The vector is invariant to octave and note order, not to transposition: STRUCTURE's chroma names the notes.
- At commit `a826864`, the document's root is the top note, two positional records put values in the wrong slots, and CONTEXT is a constant: the vectors are deterministic, but several partitions don't mean what their names say.
- Comments and documents describe older versions (96, 109, 216, 228 dimensions); the registry and a program that prints it are the reliable source.

## Sources

- Clifton Callender, Ian Quinn and Dmitri Tymoczko, ["Generalized Voice-Leading Spaces"](https://doi.org/10.1126/science.1153021), *Science* 320 (5874), 2008, pp. 346-348.
- GuitarAlchemist/ga at [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `Common/GA.Business.ML/Embeddings` (`EmbeddingSchema.cs`, `MusicalEmbeddingGenerator.cs`, `Services/TheoryVectorService.cs`, `Services/ContextVectorService.cs`, `Services/ModalVectorService.cs`, `Services/RootVectorService.cs`), `Common/GA.Business.ML/Rag/VoicingDocumentFactory.cs`, `Common/GA.Domain.Services/Fretboard/Voicings/Analysis` (`VoicingAnalyzer.cs`, `VoicingHarmonicAnalyzer.cs`), `Common/GA.Business.Core/Analysis/Voicings`, `Common/GA.Business.ML/Documentation/Schema`, `GaMcpServer/Tools/VoicingEmbeddingTool.cs`, `state/quality/domain-invariants/README.md`; commits [`95b5a9d9`](https://github.com/GuitarAlchemist/ga/commit/95b5a9d9) and [`3ba35365`](https://github.com/GuitarAlchemist/ga/commit/3ba35365).
- GA issue [#616](https://github.com/GuitarAlchemist/ga/issues/616), read on 2026-09-14.
- Microsoft Learn: [TensorPrimitives.CosineSimilarity](https://learn.microsoft.com/dotnet/api/system.numerics.tensors.tensorprimitives.cosinesimilarity), [Records](https://learn.microsoft.com/dotnet/csharp/fundamentals/types/records), [Named and optional arguments](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/named-and-optional-arguments), [Crc32](https://learn.microsoft.com/dotnet/api/system.io.hashing.crc32).
- Wikipedia, [Cosine similarity](https://en.wikipedia.org/wiki/Cosine_similarity).
