---
title: "Lesson 3: The index and search"
description: Build a small OPTIC-K index with Guitar Alchemist's own writer, read its binary header byte by byte, memory-map it, search it by chord symbol, and measure which of its 124 dimensions never vary.
sidebar:
  label: 3. The index and search
  order: 3
---

GA's live voicing index holds 313,047 guitar, bass and ukulele voicings. Building it takes minutes and a clone of the whole repository, so this lesson builds a small one with the same code: every voicing of three or more notes in the first three frets of a guitar. The file has the same format, the same header and the same search, and every number in this lesson comes from it.

All GA links point to commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6). The outputs come from:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l3
```

## The corpus

[`VoicingGenerator.GenerateAllVoicingsAsync`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Fretboard/Voicings/Generation/VoicingGenerator.cs#L156) slides a window of a few frets along the neck and yields every combination of played and muted strings. Each voicing then goes through the three steps of lesson 2, the same calls as GA's export loop in [`FretboardVoicingsCLI`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Demos/Music%20Theory/FretboardVoicingsCLI/Program.cs#L813-L839), minus its deduplication:

```text
== Corpus: GA's VoicingGenerator, standard tuning, 3 frets, window 3, at least 3 notes
voicings                 15360
  with 3 notes           1280
  with 4 notes           3840
  with 5 notes           6144
  with 6 notes           4096
first three, as generated:
diagram        MIDI (in order)    GA name      doc root
0-0-0-x-x-x    64 59 55           Em/G         E
1-0-0-x-x-x    65 59 55           G7(shell)    F
2-0-0-x-x-x    66 59 55           Gmaj7(shell) F#
```

The counts are a check: a fretboard of 3 frets has frets 0 to 3, four choices for each played string, so the six-note voicings are `4⁶ = 4096`, and the five-note ones `6 × 4⁵ = 6144`, six ways to choose the muted string. The diagrams start at string 1, the high E, and the "doc root" is again the top note of each shape. GA's [`optic-k-rebuild` skill](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/.claude/skills/optic-k-rebuild/SKILL.md) gives the scale of the real thing: about 667,000 raw guitar voicings, 298,000 after deduplication, about 140 seconds.

## The file format

[`OptickIndexWriter`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Demos/Music%20Theory/FretboardVoicingsCLI/OptickIndexWriter.cs) takes a list of `VoicingEntry(float[] Embedding, string Diagram, string Instrument, int[] MidiNotes, string? QualityInferred)` and writes one file. The course reads its header back with a `BinaryReader`, field by field, in the order [`WriteHeader`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Demos/Music%20Theory/FretboardVoicingsCLI/OptickIndexWriter.cs#L233-L258) writes them:

```text
== The header OptickIndexWriter wrote (little-endian)
magic                    OPTK
format version           4
header size              616
schema hash              0x37CD8ECF
endian marker            0xFEFF
dimension                124
voicings                 15360
instruments              3
  guitar   offset 123496, count 15360
  bass     offset 7742056, count 0
  ukulele  offset 7742056, count 0
metadata offsets at      616
vectors at               123496 (15360 x 124 x 4 bytes = 7618560)
metadata at              7742056 (1233243 bytes of msgpack)
sqrt weights, first dims 0.67 0.67 0.67 ... ROOT 0.22
file size                8975299 bytes
```

The layout, section by section:

| Bytes | Content |
|---|---|
| 0 to 615 | the header: magic, version, schema hash, dimension, count, one offset and count per instrument, four section offsets, then 124 `float` weights |
| 616 to 123,495 | one 8-byte offset per voicing into the metadata: `15,360 × 8 = 122,880` bytes |
| 123,496 to 7,742,055 | the vectors: 124 `float`s per voicing, instruments one after the other |
| 7,742,056 to the end | the metadata, one [MessagePack](https://msgpack.org/) record per voicing: diagram, instrument, MIDI notes, name |

The weights in the header are the square roots of the partition weights: `√0.45 = 0.67`, `√0.05 = 0.22`. The **endian marker** `0xFEFF` lets a reader on a big-endian machine notice that the bytes are reversed. The **schema hash** is lesson 2's CRC-32 of the layout string; [`OptickIndexReader`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/OptickIndexReader.cs#L64-L76) throws `InvalidDataException` when it doesn't match its own, so a program built with another layout can't silently read wrong numbers. The writer's summary still says it keeps "the 112 search-relevant dims" ([line 11](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Demos/Music%20Theory/FretboardVoicingsCLI/OptickIndexWriter.cs#L11)); the file says 124.

A format like this is what you would design in C# for a large read-only array: fixed-size records you can reach by arithmetic, and variable-size data behind an offset table. The info partitions of lesson 2 are not in the file at all.

## Reading it back

`OptickIndexReader` doesn't read the file into memory: it [memory-maps](https://learn.microsoft.com/dotnet/api/system.io.memorymappedfiles.memorymappedfile) it ([lines 50-55](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/OptickIndexReader.cs#L50-L55)) and hands out each vector as a `ReadOnlySpan<float>` pointing into the mapped pages. The operating system loads the pages that are touched, and several processes can share them.

```text
== OptickIndexReader
Count                    15360
guitar range             (0, 15360)
bass range               (15360, 0)
voicing 0                0-0-0-x-x-x Em/G [64 59 55]
its squared norm         1.150
max |disk - ExtractCompact| 1.5e-8
```

The squared norm of every stored vector is 1.15: each partition has norm 1 multiplied by `√w`, so its squared contribution is `w`, and the weights add up to 1.15. The last line compares the stored `float`s with `EmbeddingSchema.ExtractCompact` computed in `double`: they agree to 1.5 × 10⁻⁸, the precision of a `float`.

The memory map has a cost GA's skill warns about: on Windows, a running process that has the index open locks the file, and a rebuild "WILL fail with IOException" until GaApi and GA's MCP server are stopped.

## Searching

[`OptickSearchStrategy.SearchInternal`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/OptickSearchStrategy.cs#L164-L262) is an exact nearest-neighbour search, the brute-force `k` nearest neighbours of the [IX course](../../machine-learning-ix/03-classification/), with a dot product instead of a distance:

- one [`TensorPrimitives.Dot`](https://learn.microsoft.com/dotnet/api/system.numerics.tensors.tensorprimitives.dot) per voicing, SIMD-accelerated, over the mapped vectors;
- a [`Parallel.For`](https://learn.microsoft.com/dotnet/api/system.threading.tasks.parallel.for) over the voicings, each thread keeping its own [`PriorityQueue`](https://learn.microsoft.com/dotnet/api/system.collections.generic.priorityqueue-2) of the best `k`, merged at the end;
- ties broken by index, lower first, so that the result doesn't depend on thread scheduling. The comment explains why: many voicings share a pitch-class set and therefore a score.

No approximate index, no tree: for the live index, that's 313,047 × 124, about 39 million multiplications per query.

### The query vector

A chat message has no fretboard, so [`MusicalQueryEncoder`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/MusicalQueryEncoder.cs#L43-L109) fills only what a chord symbol can give: STRUCTURE from the pitch classes, MODAL, SYMBOLIC when there are tags, ROOT when the symbol has a root. MORPHOLOGY and CONTEXT stay zero, and so does the interval-class vector inside STRUCTURE, "not yet wired into the query path" ([lines 52-58](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/MusicalQueryEncoder.cs#L52-L58)). The best possible score is therefore below `0.45 + 0.10 + 0.05 = 0.60`.

### Cmaj7

```text
== HybridSearchAsync for "Cmaj7" (query vector from MusicalQueryEncoder)
query partitions set: STRUCTURE, MODAL, ROOT
rank  diagram        MIDI               name         score
1     x-1-x-2-2-x    60 52 47           Cmaj7(shell)/B 0.458
2     x-1-x-x-2-0    60 47 40           Cmaj7(shell)/E 0.458
3     x-1-x-2-2-0    60 52 47 40        Cmaj7(shell)/E 0.458
4     x-1-0-2-2-x    60 55 52 47        Cmaj7/B      0.419
5     x-1-0-x-2-0    60 55 47 40        Cmaj7/E      0.419
with the filter ChordName = "Cmaj7":
rank  diagram        MIDI               name         score
1     3-0-x-2-3-x    67 59 52 48        Cmaj7        0.369
2     3-0-0-2-3-x    67 59 55 52 48     Cmaj7        0.369
```

Every unfiltered result has C, MIDI 60, as its top note, and none has C in the bass: they are inversions and shells. The two root-position Cmaj7 shapes come out lower, at 0.369, because their top note is G. The query says "root C"; the index stored the top note as the root (lesson 2). A search for a chord symbol rewards shapes that have the root on top.

[`HybridSearchAsync`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/OptickSearchStrategy.cs#L49-L73) adds filters after the search: it takes `max(10 × limit, 100)` candidates, then [`ApplyFilters`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/OptickSearchStrategy.cs#L296-L329) splits `"Cmaj7"` into a root, C, and a quality, `maj7`, and keeps the candidates whose name contains `maj7` and whose **lowest** note is a C. The filter uses the real bass; the vectors used the top note. Only two shapes pass, and they are the two lesson 4's chatbot shows.

### Am7 and C

```text
== HybridSearchAsync for "Am7" (query vector from MusicalQueryEncoder)
query partitions set: STRUCTURE, MODAL, ROOT
rank  diagram        MIDI               name         score
1     x-x-2-x-3-3    57 48 43           Am7(shell)/G 0.458
2     x-x-2-2-3-x    57 52 48           Am/C         0.450
3     x-x-2-x-3-0    57 48 40           Am/E         0.450
4     x-x-2-2-3-0    57 52 48 40        Am/E         0.450
5     x-x-2-2-3-3    57 52 48 43        Am7/G        0.419
with the filter ChordName = "Am7":
rank  diagram        MIDI               name         score
1     2-x-x-2-0-x    66 52 45           Gbm7(shell)/A 0.342
2     2-x-2-2-0-x    66 57 52 45        Gbm7(shell)/A 0.342

== HybridSearchAsync for "C" (query vector from MusicalQueryEncoder)
query partitions set: STRUCTURE, MODAL, ROOT
rank  diagram        MIDI               name         score
1     x-1-0-2-x-x    60 55 52           C/E          0.481
2     x-1-0-2-3-x    60 55 52 48        C            0.481
3     x-1-0-x-x-0    60 55 40           C/E          0.481
4     x-1-0-2-x-0    60 55 52 40        C/E          0.481
5     x-1-0-x-3-0    60 55 48 40        C/E          0.481
with the filter ChordName = "C":
rank  diagram        MIDI               name         score
1     x-1-0-2-3-x    60 55 52 48        C            0.481
2     x-1-x-2-3-x    60 52 48           C + E (Major 3rd) 0.453
3     x-1-0-x-3-x    60 55 48           C5           0.415
4     x-1-2-2-3-x    60 57 52 48        Am/C         0.393
5     x-1-x-0-3-x    60 50 48           C + D (Major 2nd) 0.367
```

The quality test is a substring test, so the `Am7` filter accepts a shape named `Gbm7(shell)/A`: its name contains `m7` and its lowest note is an A. For `"C"`, the quality is the empty string, which every name contains: the filter keeps anything with C in the bass, including a shape with only C and E, and Am/C.

### Nearest voicings to a voicing

```text
== Nearest voicings to 0-1-0-2-3-x (open C), by its own compact vector
rank  diagram        MIDI               name         score
1     0-1-0-2-3-x    64 60 55 52 48     C            1.150
2     0-1-0-2-x-3    64 60 55 52 43     C/G          1.150
3     0-1-0-x-3-x    64 60 55 48        C            1.149
4     0-1-0-x-x-3    64 60 55 43        C/G          1.149
5     0-1-x-2-x-3    64 60 52 43        C/G          1.149
6     0-1-0-2-x-0    64 60 55 52 40     C/E          1.139
FindSimilarVoicingsAsync("0-1-0-2-3-x") returned 0 results
```

Searching with a stored vector finds open C first, then C/G at the same score to three decimals: moving the bass from C to G, a change any guitarist hears, costs almost nothing, because the vector's "bass" is the top note, E in both. The method made for this, [`FindSimilarVoicingsAsync`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/OptickSearchStrategy.cs#L75-L92), returns an empty list for any input: OPTK metadata "is keyed by index, not voicing id", and it traces a warning once.

## Dimensions that never vary

A dimension that has the same value for every voicing adds the same amount to every score: it can't change a ranking. The course counts them over the corpus:

```text
== Dimensions that never vary over the 15360 voicings
partition     dims  always 0  constant  weight
IDENTITY      6     3         3         0.00
STRUCTURE     24    2         1         0.45
MORPHOLOGY    24    5         0         0.25
CONTEXT       12    11        1         0.20
SYMBOLIC      12    3         2         0.10
EXTENSIONS    18    6         1         0.00
SPECTRAL      13    0         0         0.00
MODAL         40    16        0         0.10
HIERARCHY     15    14        0         0.00
ATONAL_MODAL  64    47        0         0.00
ROOT          12    0         0         0.05
in the 124 compact dims: 37 always 0, 4 constant
named MODAL slots never set (9 of 33): LocrianNatural6, DorianSharp4, LydianSharp2, AlteredDoubleFlat7, DorianFlat2, LydianAugmented, MixolydianFlat6, LocrianNatural2, Diminished
MODAL slots without a name constant: 7
```

- **CONTEXT**, weight 0.20: 11 dimensions always zero and one constant, the tension of lesson 2. Issue [#616](https://github.com/GuitarAlchemist/ga/issues/616) measured the same on the live index, and 40 dead dimensions out of 124; this corpus is small, but finds 41 that never vary.
- **ATONAL_MODAL**: the 47 slots the 17-element array of lesson 2 can't reach.
- **MODAL**: 9 of the 33 named slots are never set. [`ModalVectorService`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/Services/ModalVectorService.cs#L165-L178) looks each mode up by a display name such as `"Locrian ♮6"` or `"Dorian ♯4"`, and returns without writing when the lookup finds no intervals; a name the lookup doesn't know would explain these nine (*to verify*). Some zeros may also be real: a three-fret corpus has few voicings of the rarer modes.

## Exercises

1. The header says the vectors start at byte 123,496 and the metadata at 7,742,056. Check both numbers from the header size, the count and the dimension.
2. Why is the squared norm of every stored vector exactly the sum of the weights, and what would it be for a voicing whose SYMBOLIC partition is all zeros?
3. A user asks the chatbot for "C voicings". Using the filtered results for `"C"`, list what a guitarist would object to.
4. Write the dot product loop of `SearchInternal` for a single thread, without the heap: a `for` over the voicings that keeps the best score and its index.

<details>
<summary>Solutions</summary>

1. The offset table starts right after the header, at 616, with 8 bytes per voicing: `616 + 15,360 × 8 = 123,496`. The vectors take `15,360 × 124 × 4 = 7,618,560` bytes: `123,496 + 7,618,560 = 7,742,056`. The file ends `1,233,243` bytes of metadata later, at 8,975,299, the size printed.
2. `ExtractCompact` divides each partition by its norm and multiplies it by `√w`, so each partition's squared norm is `w`, and the squared norms of disjoint parts add up. A partition that is all zeros is left at zero, so that voicing's squared norm would be `1.15 − 0.10 = 1.05`.
3. The shape `x-1-x-2-3-x` has only two pitch classes, C and E, and is named "C + E (Major 3rd)"; `x-1-0-x-3-x` is a C5 power chord, with no third; `x-1-2-2-3-x` is Am/C, a different chord; `x-1-x-0-3-x` is C and D. Only the first result is a C major chord. The filter checks the bass and a substring of the name, and the empty quality of `"C"` matches every name.
4. For example:

   ```csharp
   var best = (Score: float.NegativeInfinity, Index: -1L);
   for (long i = start; i < start + count; i++)
   {
       var score = TensorPrimitives.Dot(q.AsSpan(), reader.GetVector(i));
       if (score > best.Score) best = (score, i); // strict: the lower index wins ties
   }
   ```

   The strict `>` keeps the first, lowest index among equal scores, the same tie-break as GA's heaps.

</details>

## Key takeaways

- An OPTK index is a flat binary file: a header with a schema hash, an offset table, fixed-size `float` vectors of the 124 similarity dimensions, and MessagePack metadata. It is memory-mapped, not loaded.
- Search is exact: a SIMD dot product per voicing, top-k heaps per thread, ties broken by index for deterministic results.
- The query encoder can only fill STRUCTURE (without its interval-class vector), MODAL, SYMBOLIC and ROOT, so scores for a chord symbol stay below 0.60.
- Because the stored root is the top note while the filter uses the bass, a search for "Cmaj7" ranks shapes with C on top first, and filtering keeps only two shapes of the small corpus; the name filter is a substring test.
- On 15,360 voicings, 41 of the 124 searched dimensions never vary, CONTEXT among them: part of every score is a constant.

## Sources

- GuitarAlchemist/ga at [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `Demos/Music Theory/FretboardVoicingsCLI` (`OptickIndexWriter.cs`, `Program.cs`), `Common/GA.Business.ML/Search` (`OptickIndexReader.cs`, `OptickSearchStrategy.cs`, `MusicalQueryEncoder.cs`), `Common/GA.Business.ML/Embeddings/Services/ModalVectorService.cs`, `Common/GA.Domain.Services/Fretboard/Voicings/Generation/VoicingGenerator.cs`, `.claude/skills/optic-k-rebuild/SKILL.md`.
- GA issue [#616](https://github.com/GuitarAlchemist/ga/issues/616), read on 2026-09-14.
- Microsoft Learn: [MemoryMappedFile](https://learn.microsoft.com/dotnet/api/system.io.memorymappedfiles.memorymappedfile), [TensorPrimitives.Dot](https://learn.microsoft.com/dotnet/api/system.numerics.tensors.tensorprimitives.dot), [PriorityQueue](https://learn.microsoft.com/dotnet/api/system.collections.generic.priorityqueue-2), [Parallel.For](https://learn.microsoft.com/dotnet/api/system.threading.tasks.parallel.for), [BinaryReader](https://learn.microsoft.com/dotnet/api/system.io.binaryreader).
- [MessagePack specification](https://github.com/msgpack/msgpack/blob/master/spec.md).
