---
title: "Lesson 5: The improvisation skill and chord–scale theory"
description: Guitar Alchemist's improvisation skill called directly, without a model, and checked against chord–scale theory — how it reads a run of chords, the arpeggio and scale it gives each one, where they leave the chord or the key, and a small oracle that finds the key and the textbook scale.
sidebar:
  label: 5. The improvisation skill
  order: 5
---

Lesson 4 ended on questions that a deterministic skill answers without a model. This lesson takes one that guitarists ask all the time, "which arpeggio fits Am F C G?", and the skill that answers it, [`ImprovisationSkill`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs). The program calls the skill directly, as lesson 4 called the relative-key skill, and checks every answer with a small oracle written from textbook definitions: which notes each chord has, which notes each scale has, and which key a progression implies. The music behind it is in two lessons of the music theory course, [scales and modes](../../music-theory-ga/02-scales-and-modes/) and [diatonic chords](../../music-theory-ga/06-diatonic-chords/).

All GA links point to commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6). The skill's file is unchanged on GA's `main` at [`8cd5042`](https://github.com/GuitarAlchemist/ga/commit/8cd5042b91e38eb9949566dc3584fa0a42089788), checked on 2026-09-28, so the answers below are still the chatbot's. The outputs come from:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l5
```

## The skill's answer

```text
== ImprovisationSkill.ExecuteAsync("which arpeggio fits Am F C G")
  | Over **Am – F – C – G**, for each chord:
  |
  | - **Am** → arpeggio **Am**, play **A Aeolian (natural minor)** (diatonic minor — fits most i chords).
  | - **F** → arpeggio **F**, play **F Ionian (major)** (diatonic, includes the 7 — careful on the IV chord).
  | - **C** → arpeggio **C**, play **C Ionian (major)** (diatonic, includes the 7 — careful on the IV chord).
  | - **G** → arpeggio **G**, play **G Ionian (major)** (diatonic, includes the 7 — careful on the IV chord).
  |
  | Each arpeggio spells the chord tones; the scale adds the passing notes for lines between them.
assumption: Each chord classified independently from its written quality; no key inferred.
```

One line per chord: an arpeggio, which spells the chord, and a scale to play over it, the first of a ranked list. The last line says how: each chord is classified on its own, from the quality written in its symbol, and no key is inferred. The skill's comment explains that choice ([lines 22-32](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L22-L32)). The obvious alternative, inferring the key and handing each chord the mode of its degree, "is wrong for any borrowed or secondary chord": an A major chord in C major sits on degree vi, whose mode is Aeolian, with a C natural against the chord's C♯. Reading the written quality can't make that mistake.

It makes another one. F and G are major triads, so both get Ionian, the first scale the skill lists for a major chord ([lines 360-436](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L360-L436)). F Ionian has a B♭ and G Ionian an F♯; the progression has neither. The skill's own colour note says "careful on the IV chord", and still leads with Ionian on it.

The path, in [`ExecuteAsync`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L117-L128) and [`BuildProgressionResponse`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L212-L261):

1. `ExtractChordRun` pulls the chord symbols out of the message with a [source-generated regular expression](https://learn.microsoft.com/dotnet/standard/base-types/regular-expression-source-generators) ([lines 453-462](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L453-L462)). Two chords or more take the progression path, before anything else is tried.
2. For each chord, `ExtractRoot` and `InferQuality` ([lines 309-353](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L309-L353)) split the symbol into a root and a quality, `ArpeggioFor` ([lines 266-284](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L266-L284)) names the arpeggio, and `ScalesFor` lists the scales, best first.
3. The answer's text, its `Evidence` and its `Data` carry the same per-chord results.

Only the single-chord path calls a model, through the `IMusicalQueryExtractor` the skill receives. The course gives it one that throws, so the run would fail if the progression path ever used it; it doesn't. The skill gets a [`NullLogger<T>`](https://learn.microsoft.com/dotnet/api/microsoft.extensions.logging.abstractions.nulllogger-1) for its other dependency, and the program reads `Data` with [`JsonSerializer.SerializeToElement`](https://learn.microsoft.com/dotnet/api/system.text.json.jsonserializer.serializetoelement): every row below is what the skill returned, not text parsed out of its answer.

## An oracle in a hundred lines

To grade the answers, the program needs the notes of each chord and of each scale, spelled, so that it prints B♭ and not A♯. [`Lesson5.cs`](https://github.com/spareilleux/learn/blob/main/code/ga-ai/GaAi/Lesson5.cs) holds three tables written from textbook formulas: the chords of the lesson (`"m7#5"` is `1 b3 #5 b7`), every scale name the skill can return (`"Mixolydian b6"` is `1 2 3 4 5 b6 b7`), and the names of the seven-note modes. A note is a letter and a pitch class, and a degree is spelled on its letter:

```csharp
// A degree such as "b3", "#11" or "bb7" above a root, spelled on the right letter
static Note Degree(Note root, string degree)
{
    var flats = degree.TakeWhile(ch => ch == 'b').Count();
    var sharps = degree.TakeWhile(ch => ch == '#').Count();
    var step = (int.Parse(degree[(flats + sharps)..]) - 1) % 7;
    return new Note((root.Letter + step) % 7, (root.Pc + MajorSteps[step] + sharps - flats + 12) % 12);
}
```

If GA adds or renames a scale, the name is missing from the table and the dictionary lookup throws: the course's CI fails instead of grading an answer it doesn't understand.

Three checks come out of these tables. For one chord: does the arpeggio add a note the chord doesn't have, does it drop one, and does the lead scale lack a chord tone? For a progression: which key is it in, and which scale does the textbook give each chord in that key?

## One chord at a time

The skill classifies each chord of a run on its own, so a run of seventeen chords, all on C, is the same as seventeen questions, and one call answers them all:

```text
== ImprovisationSkill.ExecuteAsync("arpeggios over Cmaj7 C7 Cm7 Cm7b5 Cdim Cdim7 Caug C6 Cm6 C7#11 Cm7#5 Cmaj7#5 C7sus4 CmMaj7 Csus4 Csus2 C5")
written: Cmaj7 C7 Cm7 Cm7b5 Cdim Cdim7 Caug C6 Cm6 C7#11 Cm7#5 Cmaj7#5 C7sus4 CmMaj7 Csus4 Csus2 C5
read:    Cmaj7 C7 Cm7 Cm7b5 Cdim Cdim7 Caug C6 Cm6 C7#11 Cm7#5 Cmaj7 Csus4 Csus2 C5

written  read as    quality                 arpeggio  lead scale                       check
Cmaj7               major 7                 Cmaj7     C Ionian (major)                 ok
C7                  dominant 7              C7        C Mixolydian                     ok
Cm7                 minor 7                 Cm7       C Dorian                         ok
Cm7b5               half-diminished (m7b5)  Cm7b5     C Locrian                        ok
Cdim                diminished triad        Cdim      C Locrian                        ok
Cdim7               diminished 7            Cdim7     C Whole-Half Diminished          ok
Caug                augmented               Caug      C Whole Tone                     ok
C6                  major triad             C         C Ionian (major)                 arpeggio drops A
Cm6                 minor major 7           CmMaj7    C Melodic Minor                  arpeggio adds B; arpeggio drops A
C7#11               dominant 7              C7        C Mixolydian                     arpeggio drops F#; scale lacks F# (choice 2 of 3 has it)
Cm7#5               augmented               Caug      C Whole Tone                     arpeggio adds E; arpeggio drops Eb Bb; scale lacks Eb (none of 2 choices has it)
Cmaj7#5  Cmaj7      major 7                 Cmaj7     C Ionian (major)                 arpeggio adds G; arpeggio drops G#; scale lacks G# (none of 2 choices has it)
C7sus4   (dropped)
CmMaj7   (dropped)
Csus4               unknown                 C         C Major scale of the chord root  arpeggio adds E; arpeggio drops F
Csus2               unknown                 C         C Major scale of the chord root  arpeggio adds E; arpeggio drops D
C5                  unknown                 C         C Major scale of the chord root  arpeggio adds E
```

Seven chords come back right. The other ten go wrong in three places.

**Reading.** `read:` has fifteen chords, not seventeen, and the answer doesn't say so. The tokenizer's regular expression is a list of qualities followed by a word boundary, `\b`. `Cmaj7#5` matches `maj7`, and there is a word boundary between `7` and `#`: the chord is read as `Cmaj7`, without its raised fifth. `C7sus4` and `CmMaj7` match nothing. The list has `7` but no `7sus4`, and `mmaj7` in lower case only; and the shorter matches, `C7` and `Cm`, aren't followed by a word boundary. The skill's own arpeggio label for a minor-major seventh is `mMaj7` ([line 278](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L278)), a spelling its tokenizer can't read back.

**Classifying.** `InferQuality` tests substrings in a fixed order, and the first match wins.

- `Cm7#5` contains `7#5`, which is tested with the augmented family before any minor quality ([line 343](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L343)). The arpeggio is `Caug`, C E G♯, whose E natural clashes with the chord's E♭, and neither scale on offer holds the E♭.
- `Cm6` is sent to "minor major 7" on purpose, "mel min territory" says the comment ([line 346](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L346)). Melodic minor holds the chord, but the arpeggio `CmMaj7` plays B where the chord has A.
- `C7#11` is a plain dominant seventh for the classifier, so the lead scale is Mixolydian, with the F natural that the chord raises. The second choice, Lydian dominant, is the right one.
- `Csus4`, `Csus2` and `C5` are "unknown", and an unknown quality gets the bare root as its arpeggio label ([line 283](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L283)), which reads as a major triad: an E against the sus4's F or the sus2's D, and a third the power chord leaves out on purpose.

**Incomplete.** `C6` gets a triad as its arpeggio, without the A. That one isn't wrong, only short: an arpeggio that drops a note plays nothing outside the chord. An arpeggio that adds one plays a wrong note every time it reaches it.

## A progression and its key

For a progression, the oracle first finds the key. For each of the twelve major scales, it counts the chord tones that fall outside it, and keeps the scale with the fewest; C major and A minor share their notes, so they count as one. Then it gives each chord the key's notes, read from the chord's root. That is the table every chord–scale course starts from: Ionian on I, Dorian on ii, Phrygian on iii, Lydian on IV, Mixolydian on V, Aeolian on vi and Locrian on vii ([Open Music Theory, section 6.7](https://human.libretexts.org/Bookshelves/Music/Music_Theory/Open_Music_Theory_2e_%28Gotham_et_al.%29/06%3A_Jazz/6.07%3A_Chord-Scale_Theory)).

The columns: the skill's lead scale; its *foreign* notes, those that are neither in the key nor in the chord; the textbook scale; the textbook scale's place in the skill's own list, `-` when it isn't there; and the verdict.

```text
== ImprovisationSkill.ExecuteAsync("which arpeggio fits Dm7 G7 Cmaj7") against the key
key: C major / A minor; chord tones outside it: 0

chord  arpeggio  GA lead scale              foreign   textbook                  rank   verdict
Dm7    Dm7       D Dorian                   -         D Dorian                  1      same
G7     G7        G Mixolydian               -         G Mixolydian              1      same
Cmaj7  Cmaj7     C Ionian (major)           -         C Ionian                  1      same

== ImprovisationSkill.ExecuteAsync("which arpeggio fits Am F C G") against the key
key: C major / A minor; chord tones outside it: 0

chord  arpeggio  GA lead scale              foreign   textbook                  rank   verdict
Am     Am        A Aeolian (natural minor)  -         A Aeolian                 1      same
F      F         F Ionian (major)           Bb        F Lydian                  2      DIFF
C      C         C Ionian (major)           -         C Ionian                  1      same
G      G         G Ionian (major)           F#        G Mixolydian              -      DIFF

== ImprovisationSkill.ExecuteAsync("which arpeggio fits Em C G D") against the key
key: G major / E minor; chord tones outside it: 0

chord  arpeggio  GA lead scale              foreign   textbook                  rank   verdict
Em     Em        E Aeolian (natural minor)  -         E Aeolian                 1      same
C      C         C Ionian (major)           F         C Lydian                  2      DIFF
G      G         G Ionian (major)           -         G Ionian                  1      same
D      D         D Ionian (major)           C#        D Mixolydian              -      DIFF
```

The ii–V–I agrees on every chord: the written qualities, m7, 7 and maj7, happen to name the right modes. Triads don't. An F major triad is the same chord whether it is I in F or IV in C, and only the key tells which. Over Am F C G, the skill plays B♭ on F and F♯ on G; over Em C G D, F natural on C and C♯ on D. F Lydian and C Lydian are the skill's second choices; G Mixolydian and D Mixolydian aren't in its list for a major triad at all.

## Chords outside the key

A chord from outside the key is where GA's comment has a point, and the oracle answers it with one rule: keep the key's notes, but put each chord tone in place of the key's note on the same letter.

```csharp
// The key's notes with each chord tone in place of the key note on the same letter, read
// from the chord root: the mode of the key for a diatonic chord, and for a secondary
// dominant the key's notes around the chord's own tones (A in C major: A B C# D E F G)
static List<Note> Textbook(List<Note> chord, int k)
{
    var byLetter = Key(k).ToDictionary(n => n.Letter, n => n.Pc);
    foreach (var tone in chord) byLetter[tone.Letter] = tone.Pc;
    return Enumerable.Range(0, 7).Select(i => (chord[0].Letter + i) % 7).Select(l => new Note(l, byLetter[l])).ToList();
}
```

```text
== ImprovisationSkill.ExecuteAsync("which arpeggio fits C A Dm G") against the key
key: C major / A minor; chord tones outside it: 1

chord  arpeggio  GA lead scale              foreign   textbook                  rank   verdict
C      C         C Ionian (major)           -         C Ionian                  1      same
A      A         A Ionian (major)           F# G#     A Mixolydian b6           -      DIFF
Dm     Dm        D Aeolian (natural minor)  Bb        D Dorian                  2      DIFF
G      G         G Ionian (major)           F#        G Mixolydian              -      DIFF

== ImprovisationSkill.ExecuteAsync("which arpeggio fits Am Dm E") against the key
key: C major / A minor; chord tones outside it: 1

chord  arpeggio  GA lead scale              foreign   textbook                  rank   verdict
Am     Am        A Aeolian (natural minor)  -         A Aeolian                 1      same
Dm     Dm        D Aeolian (natural minor)  Bb        D Dorian                  2      DIFF
E      E         E Ionian (major)           F# C# D#  E Phrygian dominant       -      DIFF
```

In C A Dm G, the A major chord is the dominant of D minor. Its C♯ replaces C, and the scale is A B C♯ D E F G, A Mixolydian ♭6: it keeps the chord's own third, which the degree-based method rejected by GA's comment gets wrong. Berklee's chord–scale teaching builds the scales of secondary dominants the same way, from the chord tones plus the key's other notes, and calls this one Mixolydian ♭13 for V7/II (Nettles and Graf, see the sources; *to verify* against the book). GA's A Ionian keeps the C♯ too, but adds F♯ and G♯, which neither the key nor the chord has.

In Am Dm E, the E major chord is the dominant of A minor, with the leading tone G♯. The rule gives E F G♯ A B C D, E Phrygian dominant, "the fifth mode of the harmonic minor scale, the fifth being the dominant", which the Berklee method calls Mixolydian ♭9 ♭13 ([Wikipedia](https://en.wikipedia.org/wiki/Phrygian_dominant_scale)). GA's E Ionian adds three foreign notes, F♯, C♯ and D♯, on the chord that brings the phrase home.

The minor chords go wrong the same way as the major triads. Dm gets Aeolian, the first scale the skill lists for a minor triad, with its B♭. In both progressions, D minor is ii or iv of the key and takes Dorian, the skill's second choice.

So the choice isn't between the key and the written quality. The textbook uses both: the chord's tones from its symbol, every other note from the key.

## When the key is ambiguous

```text
== ImprovisationSkill.ExecuteAsync("which arpeggio fits C G") against the key
key: C major / A minor or G major / E minor; chord tones outside it: 0

chord  arpeggio  GA lead scale              foreign   textbook                  rank   verdict
C      C         C Ionian (major)           - | F     C Ionian | C Lydian       1 | 2  same in C major / A minor
G      G         G Ionian (major)           F# | -    G Mixolydian | G Ionian   - | 1  same in G major / E minor
```

C and G fit C major and G major equally well, with no chord tone outside either. The oracle says so and grades each chord in both keys, separated by `|`. The skill's two answers are each right in one key and wrong in the other: C Ionian is the C major reading, G Ionian the G major one. Played in turn over a C–G vamp, they switch between F and F♯ at every chord change. GA issue [#744](https://github.com/GuitarAlchemist/ga/issues/744) asks for this case to be handled: say the key is ambiguous rather than pick one silently.

Am F C G, on the other hand, isn't ambiguous in this sense. C major and A minor have the same notes, so every chord gets the same scale whichever name the key is given; only the notes decide.

## Where the oracle stops

```text
== ImprovisationSkill.ExecuteAsync("which arpeggio fits C Fm G C") against the key
key: C major / A minor; chord tones outside it: 1

chord  arpeggio  GA lead scale              foreign   textbook                  rank   verdict
C      C         C Ionian (major)           -         C Ionian                  1      same
Fm     Fm        F Aeolian (natural minor)  Bb Db Eb  F (0 2 3 6 7 9 11)        -      DIFF
G      G         G Ionian (major)           F#        G Mixolydian              -      DIFF
C      C         C Ionian (major)           -         C Ionian                  1      same
```

F minor in C major is a borrowed chord, iv taken from C minor. The rule puts A♭ into C major's notes and gets F G A♭ B C D E, the steps `0 2 3 6 7 9 11`: no scale anyone teaches over F minor, which is why the program prints its steps instead of a name. The usual answer takes the notes of the key the chord is borrowed from, which gives F Dorian if the source is C natural minor (*to verify* against Nettles and Graf). The oracle knows one key and can't find a second. On this row, DIFF only says that the two answers differ, not which one is right: here, neither is. The foreign notes are measured against the oracle's scale, so they mean nothing on this row either.

The oracle doesn't check the rest of chord–scale theory either: tensions and avoid notes, the single-chord path, which needs a model to extract the chord, or anything melodic. Open Music Theory's own criticism of the method describes GA's design closely: chord–scale theory "can lead a student to see each chord as a new key center, instead of viewing an entire chord progression as derived from a parent scale". A skill that classifies each chord on its own, with no key, is that criticism written in C#.

## Reported upstream

- The key-blind scales of the progression path: GA issue [#744](https://github.com/GuitarAlchemist/ga/issues/744), filed on 2026-09-28 from a tracer run against the public chatbot, with the Am F C G and C A Dm G cases of this lesson.
- The defects of "One chord at a time", the tokenizer, the order of `InferQuality`, the unknown suspended and power chords and the `m6` arpeggio: not reported upstream when this lesson was written. They are listed in the [journal](../journal/).

## Exercises

1. Without running anything, predict the verdicts for "which arpeggio fits Bb Gm Cm F". Which scale does the skill give each chord, and which of its notes are foreign?
2. Change the tokenizer so that `C7sus4` and `CmMaj7` are read and `Cmaj7#5` isn't cut short. Then make sure that a chord it still can't read doesn't disappear silently. What would you add?
3. Change `InferQuality` so that `Cm7#5` is a minor chord. Which arpeggio label and which scales should it get?
4. Issue #744 asks for a key-fit test in GA. Which checks of this lesson's oracle would you port as unit tests, and which would you leave out?

<details>
<summary>Solutions</summary>

1. The key is B♭ major, with no chord tone outside it. B♭ gets B♭ Ionian and Gm gets G Aeolian, both right (I and vi). Cm gets C Aeolian, whose A♭ is foreign: the textbook gives C Dorian (ii), the skill's second choice. F gets F Ionian, whose E natural is foreign: the textbook gives F Mixolydian (V), which isn't in the skill's list. Checked with the course program on 2026-09-28, by adding the progression to `Progressions` for one run.
2. Add the missing qualities to the list, each before its shorter prefix: `7sus4` and `7sus2` before `7`, `maj7#5` before `maj7`, and `mMaj7`. For the silent drop, compare the words of the message that start with a chord letter with the chords that were read, and name the unread ones in the answer, for example "I couldn't read Cmaj7#5". Not compiled against GA (*to verify*).
3. Test `m7#5` before the augmented family, as `m7b5` is already tested before the diminished family. The chord is C E♭ G♯ B♭, and G♯ is A♭, so C Aeolian and C Phrygian hold all four tones. The arpeggio label should be `Cm7#5`, which needs a quality of its own: `Minor7` would print `Cm7`. Not compiled against GA (*to verify*).
4. Port the checks that don't depend on a teaching tradition: every chord tone is in the lead scale; the arpeggio adds no note; when one key holds every chord tone, the lead scale has no note outside that key. Pin C A Dm G so that the A chord's scale keeps its C♯ and has no F♯ or G♯. Leave out the scale names and the borrowed-chord rule: the C Fm G C row shows that the rule isn't settled, and #744 itself leaves the key-inference rule open as a design decision.

</details>

## Key takeaways

- GA's improvisation skill answers questions about a progression without a model: it reads the chord symbols with a regular expression, classifies each chord from its written quality, and gives an arpeggio and a ranked list of scales.
- Classifying each chord alone avoids the degree-based mistake that GA's comment describes, but loses the key: over Am F C G the skill plays B♭ on F and F♯ on G.
- The textbook scale for a chord takes both sources: the chord's tones from its symbol, every other note from the key. That rule covers diatonic chords and secondary dominants, not borrowed chords.
- The tokenizer drops or cuts short the chords it doesn't know, silently, and the fixed order of `InferQuality` misreads `Cm7#5`, `C7#11` and the suspended and power chords. The worst cases give an arpeggio with a note the chord doesn't have.
- An oracle is only useful if it says where it stops: on the borrowed-chord row, DIFF means that both answers are wrong.

## Sources

- GuitarAlchemist/ga at [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs`, unchanged on `main` at `8cd5042` on 2026-09-28.
- GA issue [#744](https://github.com/GuitarAlchemist/ga/issues/744), filed on 2026-09-28.
- Mark Gotham, Kyle Gullings, Chelsey Hamm, Bryn Hughes, Brian Jarvis, Megan Lavengood and John Peterson, *Open Music Theory*, 2nd edition, [section 6.7, "Chord-Scale Theory"](https://human.libretexts.org/Bookshelves/Music/Music_Theory/Open_Music_Theory_2e_%28Gotham_et_al.%29/06%3A_Jazz/6.07%3A_Chord-Scale_Theory), CC BY-SA 4.0, read on 2026-09-28.
- Wikipedia, ["Phrygian dominant scale"](https://en.wikipedia.org/wiki/Phrygian_dominant_scale) and ["Chord-scale system"](https://en.wikipedia.org/wiki/Chord-scale_system), for the method's origin in George Russell's *Lydian Chromatic Concept of Tonal Organization* (1953); read on 2026-09-28.
- Barrie Nettles and Richard Graf, *The Chord Scale Theory & Jazz Harmony*, Advance Music, 1997: the Berklee reference for the scales of secondary dominants and borrowed chords. Not read by this course; the two statements that rely on it are marked *to verify*.
- Microsoft Learn: [.NET regular expression source generators](https://learn.microsoft.com/dotnet/standard/base-types/regular-expression-source-generators), [`NullLogger<T>`](https://learn.microsoft.com/dotnet/api/microsoft.extensions.logging.abstractions.nulllogger-1), [`JsonSerializer.SerializeToElement`](https://learn.microsoft.com/dotnet/api/system.text.json.jsonserializer.serializetoelement).
