---
title: "Lesson 16: Arpeggios, chord–scale theory and improvisation"
description: The arpeggio on each degree, the scale that goes with each chord and the notes that clash with it, compared with Guitar Alchemist's ga_arpeggio_suggestions tool, the two chatbot skills that pair chords with scales and judge a note over a chord, and its improvisation entries.
sidebar:
  label: 16. Arpeggios and improvisation
  order: 16
---

Lesson 6 stacked thirds within a scale to get its chords, and lesson 11 played a scale from each of its degrees to get its modes. An improviser uses both at once: over each chord, the notes of the chord played one at a time, and a scale that fills the gaps between them. [Guitar Alchemist](https://github.com/GuitarAlchemist/ga) (GA) answers the guitarist's question "what do I play over this chord?" in three places: a tool of its MCP server, `ga_arpeggio_suggestions`, and two skills of its chatbot, `ImprovisationSkill`, which pairs each chord with an arpeggio and scales, and `OutsideNotesSkill`, which says whether a note is a chord tone, a tension or an avoid note. The course program compiles the two skills as they are, reads the tool as text and applies it, and compares all three with the published definitions.

All GA links point to commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6). The skills take a logger and an LLM query extractor from code the course does not build; [`StandIns.cs`](https://github.com/spareilleux/learn/blob/5d5720e/code/music-theory-ga/GaTheory/StandIns.cs) replaces them, and no request below reaches the extractor. No MCP tool and no chatbot was called. The outputs come from the command below; the entry point is `l18`.

```bash
dotnet run --project code/music-theory-ga/GaTheory -c Release -- l18
```

## Arpeggios

### The idea

Wikipedia: "An arpeggio … is a type of chord in which the notes that compose a chord are individually sounded in a progressive rising or descending order", and "An arpeggio for the chord of C major going up two octaves would be the notes (C, E, G, C, E, G, C)" ([Arpeggio](https://en.wikipedia.org/wiki/Arpeggio)). In jazz, "Saxophone player Charlie Parker began soloing using the scales and arpeggios associated with the chords in the chord progression" ([Jazz improvisation](https://en.wikipedia.org/wiki/Jazz_improvisation)). The arpeggio of a seventh chord is its four notes. Stacking thirds within the scale, as in lesson 6, gives the seventh chord on each degree: in C major, Cmaj7, Dm7, Em7, Fmaj7, G7, Am7 and Bm7♭5; in A minor, the same seven chords from Am7.

### In GA: two tables and a skill

`ga_arpeggio_suggestions` keeps two tables, one row per degree of a major or a minor key: the suffix of the arpeggio, the mode, and the intervals of the mode ([`GuitaristProblemTools.cs#L385-L406`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GuitaristProblemTools.cs#L385-L406)). `ImprovisationSkill.ArpeggioFor` names the arpeggio from a root and a quality ([`ImprovisationSkill.cs#L263-L284`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L263-L284)). The program checks both against the course's chords ([`Lesson18.cs#L270-L282`](https://github.com/spareilleux/learn/blob/5d5720e/code/music-theory-ga/GaTheory/Lesson18.cs#L270-L282)):

```text
== The seventh chord on each degree, thirds stacked within C major and within A minor, against the arpeggio suffix of ga_arpeggio_suggestions's two tables (GuitaristProblemTools.cs, read as text) and ImprovisationSkill.ArpeggioFor (GA.Business.ML, compiled) for the course's symbol
degree  notes          course   tool   check  ImprovisationSkill  check
I       C E G B        Cmaj7    maj7   ok     Cmaj7               ok
ii      D F A C        Dm7      m7     ok     Dm7                 ok
iii     E G B D        Em7      m7     ok     Em7                 ok
IV      F A C E        Fmaj7    maj7   ok     Fmaj7               ok
V       G B D F        G7       7      ok     G7                  ok
vi      A C E G        Am7      m7     ok     Am7                 ok
vii°    B D F A        Bm7b5    m7b5   ok     Bm7b5               ok
degree  notes          course   tool   check  ImprovisationSkill  check
i       A C E G        Am7      m7     ok     Am7                 ok
ii°     B D F A        Bm7b5    m7b5   ok     Bm7b5               ok
III     C E G B        Cmaj7    maj7   ok     Cmaj7               ok
iv      D F A C        Dm7      m7     ok     Dm7                 ok
v       E G B D        Em7      m7     ok     Em7                 ok
VI      F A C E        Fmaj7    maj7   ok     Fmaj7               ok
VII     G B D F        G7       7      ok     G7                  ok
```

The fourteen suffixes match, and `ArpeggioFor` gives each chord's own symbol back.

## The scale on each chord

### The idea

"The chord-scale system is a method of matching, from a list of possible chords, a list of possible scales." Wikipedia contrasts it with playing one scale over a whole progression, "the blues scale on A for all chords of the blues progression: A7 E7 D7": "in the chord-scale system, a different scale is used for each chord in the progression (for example mixolydian scales on A, E, and D for chords A7, E7, and D7, respectively)". Teachers differ on the major chord: "Russell associated the C major chord with the lydian scale, while teachers including John Mehegan, David Baker, and Mark Levine teach the major scale as the best match for a C major chord" ([Chord-scale system](https://en.wikipedia.org/wiki/Chord-scale_system)). Another article lists pairs: "C7 → C mixolydian", "C-7 → C dorian", "Cmaj7♯11 → C Lydian mode", "C- → C Aeolian mode (natural minor)" ([Jazz improvisation](https://en.wikipedia.org/wiki/Jazz_improvisation)). And it gives the test the course applies throughout: "the scale contains the chord tones G–B–D♭–F and is said to be compatible with it" ([Jazz scale](https://en.wikipedia.org/wiki/Jazz_scale)). A scale fits a chord when it holds all its notes.

Within one key, the scale on each degree is the mode on that degree, as lesson 11 showed: Ionian on I, Dorian on ii, and so on to Locrian on vii°.

### In GA: the tool's tables, and GA's modes

The program compares the Mode and Notes columns of both tables with the mode on each degree, and the scales the tool and the skills name with GA's modes ([`Lesson18.cs#L284-L315`](https://github.com/spareilleux/learn/blob/5d5720e/code/music-theory-ga/GaTheory/Lesson18.cs#L284-L315)):

```text
== The mode on each degree of C major: its intervals from the course's steps, against the Mode and Notes columns of the tool's major table, and against GA's MajorScaleMode
degree  course      tool             intervals (course)          tool's Notes MajorScaleMode name
I       Ionian      Ionian (major)   R, M2, M3, P4, P5, M6, M7   ok           ok             ok
ii      Dorian      Dorian           R, M2, m3, P4, P5, M6, m7   ok           ok             ok
iii     Phrygian    Phrygian         R, m2, m3, P4, P5, m6, m7   ok           ok             ok
IV      Lydian      Lydian           R, M2, M3, A4, P5, M6, M7   ok           ok             ok
V       Mixolydian  Mixolydian       R, M2, M3, P4, P5, M6, m7   ok           ok             ok
vi      Aeolian     Aeolian (minor)  R, M2, m3, P4, P5, m6, m7   ok           ok             ok
vii°    Locrian     Locrian          R, m2, m3, P4, d5, m6, m7   ok           ok             ok

== The tool's minor table, row by row: the mode on that degree of A minor (the course rotates the steps of natural minor), against the row's Mode and Notes
i       Aeolian     Aeolian (minor)  ok    ok
ii°     Locrian     Locrian          ok    ok
III     Ionian      Ionian (major)   ok    ok
iv      Dorian      Dorian           ok    ok
v       Phrygian    Phrygian         ok    ok
VI      Lydian      Lydian           ok    ok
VII     Mixolydian  Mixolydian       ok    ok

== The textbook scales the tool and the skills name, against GA's mode with that place in its class
name                     course                       GA's mode                check
Melodic Minor            0 2 3 5 7 9 11               Melodic Minor            ok
Lydian Augmented         0 2 4 6 8 9 11               Lydian Augmented         ok
Lydian Dominant          0 2 4 6 7 9 10               Lydian Dominant          ok
Mixolydian b6            0 2 4 5 7 8 10               Mixolydian b6            ok
Locrian #2               0 2 3 5 6 8 10               Locrian Natural 2        ok
Altered (Super Locrian)  0 1 3 4 6 8 10               Altered                  ok
Phrygian Dominant        0 1 4 5 7 8 10               Phrygian Dominant        ok
Half-Whole Diminished    0 1 3 4 6 7 9 10             Half-whole diminished    DIFF
Whole-Half Diminished    0 2 3 5 6 8 9 11             Whole-half diminished    DIFF
Whole Tone               0 2 4 6 8 10                 Whole-tone               ok
Major Pentatonic         0 2 4 7 9                    Major pentatonic         ok
Minor Pentatonic         0 3 5 7 10                   Minor pentatonic         ok
```

The tool's two tables are right, and so is GA's `MajorScaleMode`. Of the twelve other scales, ten match GA's mode at the same place in its class. The two `DIFF` rows are GA's diminished modes, as in [lesson 12](../12-symmetry-and-limited-transposition/): the first, which GA names "Half-whole diminished", starts with a whole step, and the second is the reverse. The fix the course proposed to GA is in the [journal](../journal/#2026-10-04--fixes-proposed-to-guitar-alchemist).

## What `ga_arpeggio_suggestions` returns

The tool's description reads: "For each chord in a progression, suggest the matching arpeggio and mode to improvise over it. … Example: ["Am","F","C","G"] in C major → Am: Aeolian/Am7, F: Lydian/Fmaj7, C: Ionian/Cmaj7, G: Mixolydian/G7." ([`#L409-L412`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GuitaristProblemTools.cs#L409-L412)). When the request names its key, the first word is the tonic and the second the mode, and any word but "minor" means major ([`#L426-L431`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GuitaristProblemTools.cs#L426-L431), [`#L450`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GuitaristProblemTools.cs#L450)). The tool finds the degree whose note is the chord's root ([`#L462-L463`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GuitaristProblemTools.cs#L462-L463)) and returns `chord + arpeggioSuffix`, the whole symbol followed by the table's suffix, with the mode of that degree ([`#L477-L485`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GuitaristProblemTools.cs#L477-L485)). A root outside the key gets a fixed answer ([`#L464-L475`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GuitaristProblemTools.cs#L464-L475)). The tool needs the MCP and F# packages of GA's server, so the program does not compile it: it reads the tables and the lists of degrees from the file, applies these lines ([`Lesson18.cs#L142-L236`](https://github.com/spareilleux/learn/blob/5d5720e/code/music-theory-ga/GaTheory/Lesson18.cs#L142-L236)), and lists the notes of each chord outside the mode it gets ([`#L317-L341`](https://github.com/spareilleux/learn/blob/5d5720e/code/music-theory-ga/GaTheory/Lesson18.cs#L317-L341)):

```text
== What ga_arpeggio_suggestions returns when the request names its key (the course's reading of lines 413 to 495), and the notes of each chord outside the mode it pairs with the chord
the tool's own example: [Am, F, C, G], key "C major" read as "C major"
  Am     vi         Amm7                               Aeolian (minor)      outside the mode: -
  F      IV         Fmaj7                              Lydian               outside the mode: -
  C      I          Cmaj7                              Ionian (major)       outside the mode: -
  G      V          G7                                 Mixolydian           outside the mode: -
a ii-V-I written with sevenths: [Dm7, G7, Cmaj7], key "C major" read as "C major"
  Dm7    ii         Dm7m7                              Dorian               outside the mode: -
  G7     V          G77                                Mixolydian           outside the mode: -
  Cmaj7  I          Cmaj7maj7                          Ionian (major)       outside the mode: -
Wikipedia's chord-scale example: [A7, E7, D7], key "A major" read as "A major"
  A7     I          A7maj7                             Ionian (major)       outside the mode: G
  E7     V          E77                                Mixolydian           outside the mode: -
  D7     IV         D7maj7                             Lydian               outside the mode: C
an A major chord in C major: [C, A, Dm, G], key "C major" read as "C major"
  C      I          Cmaj7                              Ionian (major)       outside the mode: -
  A      vi         Am7                                Aeolian (minor)      outside the mode: C♯
  Dm     ii         Dmm7                               Dorian               outside the mode: -
  G      V          G7                                 Mixolydian           outside the mode: -
a minor key with its dominant: [Am, Dm, E7, Am], key "A minor" read as "A minor"
  Am     i          Amm7                               Aeolian (minor)      outside the mode: -
  Dm     iv         Dmm7                               Dorian               outside the mode: -
  E7     v          E7m7                               Phrygian             outside the mode: G♯
  Am     i          Amm7                               Aeolian (minor)      outside the mode: -
the key written "Am": [Am, Dm, E7], key "Am" read as "Am major"
  Am     I          Ammaj7                             Ionian (major)       outside the mode: C
  Dm     IV         Dmmaj7                             Lydian               outside the mode: F
  E7     V          E77                                Mixolydian           outside the mode: -
a chord outside the key: [C, Bb, F], key "C major" read as "C major"
  C      I          Cmaj7                              Ionian (major)       outside the mode: -
  Bb     chromatic  Bb (chromatic — outside key)       depends on context   outside the mode: (no scale)
  F      IV         Fmaj7                              Lydian               outside the mode: -
for a chord outside the key the tool returns the arpeggio "<chord> (chromatic — outside key)", the mode "depends on context" and the notes "R, M2, M3, P5"
```

- On its own example the tool returns "Amm7", where its description says Am7. A ii–V–I written with sevenths gets "Dm7m7", "G77" and "Cmaj7maj7".
- The mode comes from the degree of the root, not from the chord. Wikipedia's example, A7 E7 D7 in A major, gets Ionian, Mixolydian and Lydian: A7's G is outside A Ionian and D7's C outside D Lydian, where Wikipedia plays Mixolydian on all three. An A major chord in C major sits on degree vi: the tool answers "Am7" and Aeolian, whose C clashes with the chord's C♯. E7, the dominant of A minor, gets "E7m7" and Phrygian, without the chord's G♯.
- A key written "Am" reads "Am major", that is A major: Am gets "Ammaj7" and Ionian, with its C outside, and Dm gets "Dmmaj7" and Lydian.

GA's own code knew the first two. `ImprovisationSkill`'s remarks describe the A major chord in C major ([`ImprovisationSkill.cs#L22-L32`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L22-L32)), and a comment on `ArpeggioFor` calls "root + full-suffix concatenation ("Amm7")" "the single most-broken behavior of the MCP arpeggio tool" ([`#L264-L265`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L264-L265)). [GA #626](https://github.com/GuitarAlchemist/ga/pull/626), merged on 2026-09-24, after the course's commit of 2026-09-14, makes the tool name the arpeggio with the skill's `InferQuality` and `ArpeggioFor`, and compare the chord's quality with the degree's. On `main`, the key is still read the same way. Read, not run.

## What `ImprovisationSkill` offers

The skill "Suggests scales, modes and arpeggios to improvise / solo over a chord or a whole chord progression" ([`ImprovisationSkill.cs#L46-L51`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L46-L51)). `InferQuality` reads the quality after the root, "Most-specific first" ([`#L309-L353`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L309-L353)); `ScalesFor` gives each quality a list of scales, "best/most-common first" ([`#L355-L437`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L355-L437)). The program asks for 31 symbols on C, each with its usual notes ([Chord notation](https://en.wikipedia.org/wiki/Chord_notation), [Jazz chord](https://en.wikipedia.org/wiki/Jazz_chord)), and looks for the chord's notes outside the first scale ([`Lesson18.cs#L343-L358`](https://github.com/spareilleux/learn/blob/5d5720e/code/music-theory-ga/GaTheory/Lesson18.cs#L343-L358)):

```text
== ImprovisationSkill (GA.Business.ML, compiled): the quality InferQuality reads in each symbol, the arpeggio ArpeggioFor names, the first scale ScalesFor offers and the chord's notes outside it, and the first of its scales that holds them all
symbol    notes           quality                 arpeggio   first scale                    outside   holds every note
C         C E G           major triad             C          Ionian (major)                 -         the first
Cm        C E♭ G          minor triad             Cm         Aeolian (natural minor)        -         the first
C6        C E G A         major triad             C          Ionian (major)                 -         the first
C69       C E G A D       major triad             C          Ionian (major)                 -         the first
Cadd9     C E G D         unknown                 C          Major scale of the chord root  -         the first
Csus2     C D G           unknown                 C          Major scale of the chord root  -         the first
Csus4     C F G           unknown                 C          Major scale of the chord root  -         the first
C5        C G             unknown                 C          Major scale of the chord root  -         the first
Cmaj7     C E G B         major 7                 Cmaj7      Ionian (major)                 -         the first
CM7       C E G B         minor 7                 Cm7        Dorian                         E B       none
Cmaj9     C E G B D       major 7                 Cmaj7      Ionian (major)                 -         the first
Cmaj7#11  C E G B F♯      major 7#11              Cmaj7#11   Lydian                         -         the first
Cmaj7#5   C E G♯ B        major 7                 Cmaj7      Ionian (major)                 G♯        none
C7        C E G B♭        dominant 7              C7         Mixolydian                     -         the first
C9        C E G B♭ D      dominant 7              C7         Mixolydian                     -         the first
C13       C E G B♭ D A    dominant 7              C7         Mixolydian                     -         the first
C7sus4    C F G B♭        suspended dominant      C7sus4     Mixolydian                     -         the first
C7#11     C E G B♭ F♯     dominant 7              C7         Mixolydian                     F♯        Lydian Dominant
C7b9      C E G B♭ D♭     altered dominant        C7alt      Altered (Super Locrian)        G         Half-Whole Diminished
C7#9      C E G B♭ D♯     altered dominant        C7alt      Altered (Super Locrian)        G         Half-Whole Diminished
C7b13     C E G B♭ A♭     dominant 7              C7         Mixolydian                     A♭        Mixolydian b6
C7#5      C E G♯ B♭       augmented               Caug       Whole Tone                     -         the first
C7+5      C E G♯ B♭       dominant 7              C7         Mixolydian                     G♯        Mixolydian b6
Caug      C E G♯          augmented               Caug       Whole Tone                     -         the first
Cm7       C E♭ G B♭       minor 7                 Cm7        Dorian                         -         the first
Cm9       C E♭ G B♭ D     minor 7                 Cm7        Dorian                         -         the first
Cm6       C E♭ G A        minor major 7           CmMaj7     Melodic Minor                  -         the first
CmMaj7    C E♭ G B        minor major 7           CmMaj7     Melodic Minor                  -         the first
Cm7b5     C E♭ G♭ B♭      half-diminished (m7b5)  Cm7b5      Locrian                        -         the first
Cdim      C E♭ G♭         diminished triad        Cdim       Locrian                        -         the first
Cdim7     C E♭ G♭ B♭♭     diminished 7            Cdim7      Whole-Half Diminished          -         the first
CanHandle on its 17 example prompts: 16 accepted; turned down: "what scales fit over the progression Cmaj7 A7 Dm7 G7"
```

For 24 of the 31 symbols, the first scale holds every note of the chord. The seven others:

- **CM7.** `InferQuality` lowercases the suffix ([`#L323`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L323)), and "m7" is the test for a minor seventh ([`#L347`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L347)). So CM7, which Wikipedia writes for "a C major seventh chord (CM7)" ([Chord notation](https://en.wikipedia.org/wiki/Chord_notation)), gets the arpeggio Cm7 and Dorian, and its E and B are outside all three scales offered. GA's `ChordVocabulary` describes this very regression: "the skill lowercased the whole quality token before matching, so "CM" resolved to C *minor* instead of C major (a regression of the PR #80 fix that the MCP tool already carried)", consolidated into "one home for the case-sensitive M/M7 handling" ([`ChordVocabulary.cs#L8-L16`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/ChordVocabulary.cs#L8-L16)). `NormalizeQuality` there reads "M7" as "major 7" ([`#L59-L65`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/ChordVocabulary.cs#L59-L65)), but `InferQuality` does not call it.
- **Cmaj7♯5** reads "major 7", because the test for "maj7" ([`#L340`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L340)) comes before the test for "7#5" ([`#L343`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L343)): G♯ is outside both Ionian and Lydian.
- **C7♯11, C7♭13 and C7+5** read "dominant 7", and Mixolydian lacks their F♯, A♭ or G♯; Lydian Dominant and Mixolydian ♭6, further down the list, hold them. Wikipedia pairs "C7♯11 and C lydian dominant", where "every note of the scale may be considered a chord tone" ([Chord-scale system](https://en.wikipedia.org/wiki/Chord-scale_system)).
- **C7♭9 and C7♯9** read "altered dominant", arpeggio C7alt, and get the altered scale first. That scale keeps "The tonic, major third (as a diminished fourth), and dominant seventh" and alters both fifths ([Jazz scale](https://en.wikipedia.org/wiki/Jazz_scale)), so the chord's G is outside it; Half-Whole Diminished, second, holds all five notes.

Two more readings put the right scale under a wrong name. Cm6 reads "minor major 7" ("mel min territory", [`#L346`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L346)), so its arpeggio is CmMaj7, C E♭ G B, not the chord's C E♭ G A; melodic minor holds both. C6 and C69 read "major triad", arpeggio C. Cadd9, Csus2, Csus4 and C5 are "unknown" and get "Major scale of the chord root".

`CanHandle` is the skill's keyword gate, the fallback path behind the chatbot's semantic router ([`#L92-L94`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L92-L94)). It turns down one of the skill's 17 example prompts, "what scales fit over the progression Cmaj7 A7 Dm7 G7" ([`#L74`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L74)). Its keywords count only as whole words ([`ChordIntentMatching.cs#L22-L35`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordIntentMatching.cs#L22-L35)): "what scale" is followed by an s, and no other keyword is in the sentence ([`ImprovisationSkill.cs#L86-L101`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L86-L101)).

On a request that names two chord symbols or more, the skill classifies each chord on its own ([`#L119-L125`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L119-L125), [`#L212-L261`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L212-L261)); its remarks call that deliberate: "The per-chord classification is deliberately key-agnostic" ([`#L23`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L23)). The program calls `ExecuteAsync` directly ([`Lesson18.cs#L359-L368`](https://github.com/spareilleux/learn/blob/5d5720e/code/music-theory-ga/GaTheory/Lesson18.cs#L359-L368)):

```text
== ImprovisationSkill.ExecuteAsync on requests that name two chords or more: two of its own example prompts, Wikipedia's chord-scale example and GAA-003's Dorian and Mixolydian vamps
"which arpeggio fits Am F C G": CanHandle True, chords read Am F C G
  - **Am** → arpeggio **Am**, play **A Aeolian (natural minor)** (diatonic minor — fits most i chords).
  - **F** → arpeggio **F**, play **F Ionian (major)** (diatonic, includes the 7 — careful on the IV chord).
  - **C** → arpeggio **C**, play **C Ionian (major)** (diatonic, includes the 7 — careful on the IV chord).
  - **G** → arpeggio **G**, play **G Ionian (major)** (diatonic, includes the 7 — careful on the IV chord).
"what scales fit over the progression Cmaj7 A7 Dm7 G7": CanHandle False, chords read Cmaj7 A7 Dm7 G7
  - **Cmaj7** → arpeggio **Cmaj7**, play **C Ionian (major)** (diatonic — the safe choice).
  - **A7** → arpeggio **A7**, play **A Mixolydian** (diatonic dominant — natural choice for V chords).
  - **Dm7** → arpeggio **Dm7**, play **D Dorian** (natural 6 — modern jazz default).
  - **G7** → arpeggio **G7**, play **G Mixolydian** (diatonic dominant — natural choice for V chords).
"how do I improvise over A7 E7 D7": CanHandle True, chords read A7 E7 D7
  - **A7** → arpeggio **A7**, play **A Mixolydian** (diatonic dominant — natural choice for V chords).
  - **E7** → arpeggio **E7**, play **E Mixolydian** (diatonic dominant — natural choice for V chords).
  - **D7** → arpeggio **D7**, play **D Mixolydian** (diatonic dominant — natural choice for V chords).
"improvise over Am7 D7": CanHandle True, chords read Am7 D7
  - **Am7** → arpeggio **Am7**, play **A Dorian** (natural 6 — modern jazz default).
  - **D7** → arpeggio **D7**, play **D Mixolydian** (diatonic dominant — natural choice for V chords).
"improvise over A7 G/A": CanHandle True, chords read A7 G A
  - **A7** → arpeggio **A7**, play **A Mixolydian** (diatonic dominant — natural choice for V chords).
  - **G** → arpeggio **G**, play **G Ionian (major)** (diatonic, includes the 7 — careful on the IV chord).
  - **A** → arpeggio **A**, play **A Ionian (major)** (diatonic, includes the 7 — careful on the IV chord).
```

A7 E7 D7 gets Mixolydian three times, Wikipedia's answer, and the Dorian vamp of the Streeling module GAA-003, Am7 D7, gets A Dorian and D Mixolydian. Without a key, a major triad always gets Ionian, with "careful on the IV chord" ([`#L371-L376`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L371-L376)): over Am F C G, the tool's own example, the skill offers F Ionian and G Ionian, whose B♭ and F♯ none of the four chords has, where the tool's description has Lydian and Mixolydian. GAA-003's Mixolydian vamp, A7 to G/A, a G triad over an A bass, reads as three chords: the tokenizer stops at the slash ([`#L461`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L461)), and the bass becomes an A chord, which gets A Ionian and its G♯, against the vamp's G.

## Outside notes

### The idea

Wikipedia: "An F against a C major chord could be considered an avoid note because it lies a semitone above the third, an interval which was historically heard as dissonance. Treating the F as a passing tone is a simpler way to use it in a melody over a C major chord" ([Avoid note](https://en.wikipedia.org/wiki/Avoid_note)). Another article places it within the scale: "An avoid note is a note in a jazz scale that is considered, in jazz theory and practice, too dissonant to be emphasised against the underlying chord", and "Avoid notes are often a minor second (or a minor ninth) above a chord tone or a perfect fourth above the root of the chord"; "Non-classical harmony just tells you which note in the scale to avoid … meaning that all the others are okay" ([Jazz scale](https://en.wikipedia.org/wiki/Jazz_scale)). The chord-scale definition sorts the notes of a scale: a note outside it is neither a tension nor an avoid note of that scale. On a dominant chord, the altered tensions are the point: "The altered extensions played by a jazz guitarist or jazz pianist on an altered dominant chord on G might include (at the discretion of the performer) a flatted ninth A♭ …; a sharp eleventh C♯ … and a flattened thirteenth E♭" ([Jazz improvisation](https://en.wikipedia.org/wiki/Jazz_improvisation)).

### In GA: one rule for twelve notes

`OutsideNotesSkill`'s remarks give its rule: "a non-chord-tone that sits a semitone above a chord tone is an avoid note (it forms a b9 clash with that chord tone); any other non-chord-tone is an available tension" ([`OutsideNotesSkill.cs#L20-L28`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/OutsideNotesSkill.cs#L20-L28)). `Classify` applies it to any note, with no scale ([`#L141-L189`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/OutsideNotesSkill.cs#L141-L189)). The program asks it for the twelve notes over four chords on C, and compares its tensions with the scales `ImprovisationSkill` offers for the same chords ([`Lesson18.cs#L370-L388`](https://github.com/spareilleux/learn/blob/5d5720e/code/music-theory-ga/GaTheory/Lesson18.cs#L370-L388)):

```text
== OutsideNotesSkill.Classify (GA.Business.ML, compiled): each of the twelve notes over Cmaj7, C7, Cm7 and Cm7b5
note  Cmaj7                         C7                            Cm7                           Cm7b5
C     chord tone: root              chord tone: root              chord tone: root              chord tone: root
D♭    avoid: b9                     avoid: b9                     avoid: b9                     avoid: b9
D     tension: 9                    tension: 9                    tension: 9                    tension: 9
E♭    tension: #9                   tension: #9                   chord tone: minor third       chord tone: minor third
E     chord tone: major third       chord tone: major third       avoid: major 3rd              avoid: major 3rd
F     avoid: 11                     avoid: 11                     tension: 11                   tension: 11
F♯    tension: #11                  tension: #11                  tension: #11                  chord tone: diminished fifth
G     chord tone: perfect fifth     chord tone: perfect fifth     chord tone: perfect fifth     avoid: 5th
A♭    avoid: b13                    avoid: b13                    avoid: b13                    tension: b13
A     tension: 13                   tension: 13                   tension: 13                   tension: 13
B♭    tension: b7                   chord tone: minor seventh     chord tone: minor seventh     chord tone: minor seventh
B     chord tone: major seventh     avoid: major 7th              avoid: major 7th              avoid: major 7th

== The notes Classify calls a tension that none of the scales ImprovisationSkill offers for the same chord contains
Cmaj7  scales: Ionian (major), Lydian; tensions: D E♭ F♯ A B♭; in none of them: E♭ (#9), B♭ (b7)
C7     scales: Mixolydian, Lydian Dominant, Mixolydian b6; tensions: D E♭ F♯ A; in none of them: E♭ (#9)
Cm7    scales: Dorian, Aeolian (minor), Phrygian; tensions: D F F♯ A; in none of them: F♯ (#11)
Cm7b5  scales: Locrian, Locrian #2; tensions: D F A♭ A; in none of them: A (13)
```

Over Cmaj7 the avoid notes are D♭, F and A♭; F is Wikipedia's avoid note. Every other note is a "tension", in a scale that fits the chord or not. Over Cmaj7, B♭ is "tension: b7", a minor seventh against the chord's major seventh, and E♭ "tension: #9", against its major third; over Cm7, F♯; over Cm7♭5, A. None is in the scales `ImprovisationSkill` offers for the same chord. B♭ lies a semitone below the chord's B: the rule only looks above chord tones. Over C7, the rule turns the ♭9 and the ♭13 into avoid notes, where Wikipedia lists them among the extensions of an altered dominant. The comment on dominant chords names "the b9/#9/#11/b13 half-step clashes" ([`#L164-L166`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/OutsideNotesSkill.cs#L164-L166)), but the ♯9 and the ♯11 sit a semitone above no chord tone: they come out as tensions.

The skill's example prompts, then three questions added after the first run ([`Lesson18.cs#L389-L403`](https://github.com/spareilleux/learn/blob/5d5720e/code/music-theory-ga/GaTheory/Lesson18.cs#L389-L403)):

```text
== OutsideNotesSkill on its own example prompts: CanHandle, then the first line of ExecuteAsync's answer
"why does F sound outside over Cmaj7": True; **F** over **C major 7**: an avoid note — the 11 (natural eleventh).
"why does that note clash over the chord": True; Tell me a single note and a single chord and I'll say whether it's a chord tone, a tension, or an avoid note — e.g. "why does F sound outside over Cmaj7" or "is A a tension over Cmaj7".
"is F an avoid note over Cmaj7": True; **F** over **C major 7**: an avoid note — the 11 (natural eleventh).
"what is F over G7": False; **F** over **G dominant 7**: a chord tone — the minor seventh.
"why does the b9 sound so tense over C7": True; Tell me a single note and a single chord and I'll say whether it's a chord tone, a tension, or an avoid note — e.g. "why does F sound outside over Cmaj7" or "is A a tension over Cmaj7".
"is A a chord tone or a tension over Cmaj7": True; **A** over **C major 7**: an available tension — the 13 (thirteenth).
"why does Bb sound outside over C major": True; **Bb** over **C**: an available tension — the b7 (minor seventh).
"is F# an avoid note or a tension over Cmaj7": True; **F#** over **C major 7**: an available tension — the #11 (sharp eleventh).
"why does F clash over a Cmaj7 chord": True; **F** over **C major 7**: an avoid note — the 11 (natural eleventh).
"why does the note clash over this chord": False; Tell me a single note and a single chord and I'll say whether it's a chord tone, a tension, or an avoid note — e.g. "why does F sound outside over Cmaj7" or "is A a tension over Cmaj7".

== Added after the first run: OutsideNotesSkill.ExecuteAsync's whole answer for B over C7, and for E and B over CM7, the symbol ImprovisationSkill reads as minor 7
"is B an avoid note over C7": **B** over **C dominant 7**: an avoid note — the major 7th. It's the major 7th, sitting a semitone above the minor seventh of the chord. That half-step rub is why it sounds outside — but over a dominant chord it's exactly the kind of altered tension players reach for (major 7th on the V), so it's usable if you resolve it, not a note to simply avoid.
"is E a chord tone over CM7": **E** over **C major 7**: a chord tone — the major third. It's part of the chord itself (the major third), so it sounds fully consonant — as inside as a note can be over this chord.
"is B a chord tone over CM7": **B** over **C major 7**: a chord tone — the major seventh. It's part of the chord itself (the major seventh), so it sounds fully consonant — as inside as a note can be over this chord.
```

Seven of the ten example prompts get an answer. "what is F over G7" gets one when called directly, but `CanHandle` turns it down: none of the skill's keywords is in the sentence ([`#L67-L72`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/OutsideNotesSkill.cs#L67-L72)). "why does that note clash over the chord" passes `CanHandle`, because the chord pattern ignores case ([`#L291-L293`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/OutsideNotesSkill.cs#L291-L293)) and reads "the chord" as a C chord, then finds no note before "over". "why does the b9 sound so tense over C7" passes and gets the same help text: the skill reads note names, not degrees, as its remarks say ([`#L31-L33`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/OutsideNotesSkill.cs#L31-L33)). "Bb over C major" is measured against a C major triad.

Of the three questions added after the first run, the first shows what a user reads about the major seventh over a dominant chord: an avoid note, then "over a dominant chord it's exactly the kind of altered tension players reach for (major 7th on the V)" ([`#L164-L172`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/OutsideNotesSkill.cs#L164-L172)). The major seventh is none of the altered tensions, and it clashes with the chord's own seventh. The other two show that `OutsideNotesSkill`, which reads the chord through `ChordVocabulary`, takes CM7 for a major seventh: two skills of the same chatbot disagree on that symbol.

## GAA-003 and GA's improvisation entries

The Streeling module [GAA-003 · Improvisation Foundations](../../streeling/guitar-alchemist-academy/gaa-003-improvisation-foundations/) starts from box 1 of A minor pentatonic, "The five notes are: A, C, D, E, G" ([`gaa-003-improvisation-foundations.md#L40-L51`](https://github.com/GuitarAlchemist/Demerzel/blob/0f7a5fd110acfc4835776d38ab1a115533467d34/state/streeling/courses/guitar-alchemist-academy/en/gaa-003-improvisation-foundations.md#L40-L51)). Its first self-check answer explains why that scale is safe over Am7 and less so over A7: "Over Am or Am7 none of its notes lies a half step from a chord tone, so no order or combination makes a half-step clash with the chord. Over a dominant chord such as A7 that no longer holds: C lies a half step below the chord's C#, and D a half step above it" ([`#L467`](https://github.com/GuitarAlchemist/Demerzel/blob/0f7a5fd110acfc4835776d38ab1a115533467d34/state/streeling/courses/guitar-alchemist-academy/en/gaa-003-improvisation-foundations.md#L467)). Over a blues in A it targets the third of each chord: "For A7, target the 3rd (C#). For D7, target the 3rd (F#). For E7, target the 3rd (G#)" ([`#L175`](https://github.com/GuitarAlchemist/Demerzel/blob/0f7a5fd110acfc4835776d38ab1a115533467d34/state/streeling/courses/guitar-alchemist-academy/en/gaa-003-improvisation-foundations.md#L175)). It spells three modes on A ([`#L267`](https://github.com/GuitarAlchemist/Demerzel/blob/0f7a5fd110acfc4835776d38ab1a115533467d34/state/streeling/courses/guitar-alchemist-academy/en/gaa-003-improvisation-foundations.md#L267), [`#L273`](https://github.com/GuitarAlchemist/Demerzel/blob/0f7a5fd110acfc4835776d38ab1a115533467d34/state/streeling/courses/guitar-alchemist-academy/en/gaa-003-improvisation-foundations.md#L273), [`#L279`](https://github.com/GuitarAlchemist/Demerzel/blob/0f7a5fd110acfc4835776d38ab1a115533467d34/state/streeling/courses/guitar-alchemist-academy/en/gaa-003-improvisation-foundations.md#L279)) and names the note that pulls each one away, adding: "They are not "avoid notes" in the chord-scale sense of mus-005, which are notes inside the scale that clash with the chord" ([`#L283-L289`](https://github.com/GuitarAlchemist/Demerzel/blob/0f7a5fd110acfc4835776d38ab1a115533467d34/state/streeling/courses/guitar-alchemist-academy/en/gaa-003-improvisation-foundations.md#L283-L289)). The program checks these claims through `Classify` ([`Lesson18.cs#L404-L419`](https://github.com/spareilleux/learn/blob/5d5720e/code/music-theory-ga/GaTheory/Lesson18.cs#L404-L419)):

```text
== GAA-003's claims, through Classify: the notes of A minor pentatonic over Am7 and over A7, and the notes the module says pull each mode away
A   over Am7: chord tone, root            over A7: chord tone, root
C   over Am7: chord tone, minor third     over A7: tension, #9
D   over Am7: tension, 11                 over A7: avoid, 11
E   over Am7: chord tone, perfect fifth   over A7: chord tone, perfect fifth
G   over Am7: chord tone, minor seventh   over A7: chord tone, minor seventh
Dorian      F   over Am7    avoid, b13
Mixolydian  G♯  over A7     avoid, major 7th
Lydian      D   over Amaj7  avoid, 11
GAA-003's targets, the third of each dominant chord of a blues in A, from ChordVocabulary.GetFormula("dominant 7"): A7 C♯, D7 F♯, E7 G♯
```

Over Am7, `Classify` agrees with the module: A, C, E and G are chord tones, and D is a tension. Over A7 it sees half of the rub: D, a semitone above C♯, is an avoid note, but C, a semitone below it, is a tension, the ♯9. The three notes that pull a mode away all come out as avoid notes, the label GAA-003 says they do not have. The three targets are the thirds of GA's dominant formula ([`ChordVocabulary.cs#L121`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/ChordVocabulary.cs#L121)).

GA's configuration has a file for improvisation, `ImprovisationConcepts.yaml`, with four concepts, each a name and a `Concept` line ([`ImprovisationConcepts.yaml#L6-L14`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Config/ImprovisationConcepts.yaml#L6-L14)). `YamlKnowledgeLoader` turns each into an entry for retrieval: the name, then each other field as "Key: Value", tagged with the file name and the `Category`, if any ([`YamlKnowledgeLoader.fs#L65-L91`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Config/YamlKnowledgeLoader.fs#L65-L91)). The program loads them, then plays GAA-003's box 1 and spells its three modes ([`Lesson18.cs#L421-L448`](https://github.com/spareilleux/learn/blob/5d5720e/code/music-theory-ga/GaTheory/Lesson18.cs#L421-L448)):

```text
== YamlKnowledgeLoader.LoadAllKnowledgeEntries (GA.Business.Config): 192 entries from 15 files; the 4 of ImprovisationConcepts.yaml
Motivic Development    category "", tags ImprovisationConcepts; content: Motivic Development | Concept: Repeat and vary small melodic ideas
Tension and Release    category "", tags ImprovisationConcepts; content: Tension and Release | Concept: Alternate dissonance and resolution
Rhythmic Displacement  category "", tags ImprovisationConcepts; content: Rhythmic Displacement | Concept: Shift motifs across beats
Space Usage            category "", tags ImprovisationConcepts; content: Space Usage | Concept: Use silence as phrasing element

== GAA-003's box 1 of A minor pentatonic, read on the strings in standard tuning, against GA's fifth mode of the major pentatonic
E: frets 5, 8 -> A2 C3
A: frets 5, 7 -> D3 E3
D: frets 5, 7 -> G3 A3
G: frets 5, 7 -> C4 D4
B: frets 5, 8 -> E4 G4
e: frets 5, 8 -> A4 C5
notes of the box: C D E G A; GA's Minor pentatonic: A C D E G; the same notes True

== GAA-003's three modes on A, as the module spells them, against the course's spelling from the steps
mode        course               GAA-003              check
Dorian      A B C D E F♯ G       A B C D E F♯ G       ok
Mixolydian  A B C♯ D E F♯ G      A B C♯ D E F♯ G      ok
Lydian      A B C♯ D♯ E F♯ G♯    A B C♯ D♯ E F♯ G♯    ok
```

The four entries are a name and one line each, and none pairs a chord with a scale or an arpeggio. Box 1 plays A, C, D, E and G, GA's fifth mode of the major pentatonic, and the module spells its three modes right. The loader skips `SpecializedTunings.yaml`, as the [journal](../journal/#2026-10-04--fixes-proposed-to-guitar-alchemist) found; it says so on the error stream, which the output above leaves out.

## Exercises

1. At `a826864`, what does `ga_arpeggio_suggestions` return for G7 in C major, and why?
2. Over an A major chord in C major, the tool offers Aeolian. Which note clashes, and with which note of the chord?
3. Why does `ImprovisationSkill` read CM7 as a minor seventh, while `OutsideNotesSkill` reads it as a major seventh?
4. `Classify` calls B♭ over Cmaj7 a tension. Why does its rule miss the clash, and what would the chord-scale definition say?
5. Which notes of A minor pentatonic lie a half step from a chord tone of A7, and what does `Classify` call them?

<details>
<summary>Solutions</summary>

1. "G77" and Mixolydian. G is degree V of C major, and the tool appends the suffix of that row, "7", to the whole symbol.
2. Aeolian on A has C, a semitone below the chord's C♯. The tool finds the degree from the root alone, A, which is degree vi of C major.
3. `InferQuality` lowercases the suffix, so "M7" becomes "m7", the test for a minor seventh. `OutsideNotesSkill` goes through `ChordVocabulary.NormalizeQuality`, which reads "M7" as a major seventh before lowercasing anything.
4. The rule only looks a semitone above chord tones, and B♭ lies a semitone below B, the chord's seventh. B♭ is in neither scale offered for Cmaj7, Ionian and Lydian, so in the chord-scale sense it is neither a tension nor an avoid note of either: it is a note outside the scale.
5. C, a semitone below C♯, and D, a semitone above it. `Classify` calls D an avoid note (the 11) and C a tension (the ♯9).

</details>

## Key takeaways

- Stacking thirds within a scale gives the arpeggio on each degree. GA's two tables and `ArpeggioFor` name all fourteen right, and the tool's modes are those of the degrees.
- At `a826864`, `ga_arpeggio_suggestions` appends its suffix to the whole symbol ("Amm7", "G77") and takes the mode from the degree of the root, so A7 in A major gets Ionian. GA #626 fixed both on 2026-09-24; a key written "Am" still means A major.
- `ImprovisationSkill` reads each chord on its own, and for 24 of 31 symbols its first scale holds the chord. It reads CM7 as a minor seventh, the regression `ChordVocabulary` says it removed, Cmaj7♯5 as a major seventh, and names Cm6's arpeggio CmMaj7.
- `OutsideNotesSkill` sorts all twelve notes by one rule, a semitone above a chord tone; the textbook sorts the notes of a scale. It calls B♭ over Cmaj7 a tension and the ♭9 and ♭13 over C7 avoid notes, and it tells the user the major seventh over a dominant is an altered tension.
- GA's improvisation entries are four one-line concepts. GAA-003's box 1, modes and targets are right.

## Sources

- Wikipedia: [Arpeggio](https://en.wikipedia.org/wiki/Arpeggio), [Chord-scale system](https://en.wikipedia.org/wiki/Chord-scale_system) (one scale per chord, A7 E7 D7, C7♯11 and Lydian dominant), [Jazz improvisation](https://en.wikipedia.org/wiki/Jazz_improvisation) (arpeggios, the pairs of chords and modes, altered extensions), [Jazz scale](https://en.wikipedia.org/wiki/Jazz_scale) (compatibility, avoid notes, the altered scale), [Avoid note](https://en.wikipedia.org/wiki/Avoid_note), [Chord notation](https://en.wikipedia.org/wiki/Chord_notation) and [Jazz chord](https://en.wikipedia.org/wiki/Jazz_chord) (chord symbols).
- Streeling: [GAA-003 · Improvisation Foundations](../../streeling/guitar-alchemist-academy/gaa-003-improvisation-foundations/).
- GuitarAlchemist/ga at [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `GaMcpServer/Tools/GuitaristProblemTools.cs`, `Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs`, `OutsideNotesSkill.cs`, `ChordIntentMatching.cs`, `Common/GA.Business.ML/Agents/ChordVocabulary.cs`, `Common/GA.Business.Config/ImprovisationConcepts.yaml`, `YamlKnowledgeLoader.fs`; and [GA #626](https://github.com/GuitarAlchemist/ga/pull/626).
