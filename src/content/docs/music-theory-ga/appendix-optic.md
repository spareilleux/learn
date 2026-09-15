---
title: "Appendix B: the OPTIC hierarchy"
description: From one fingering up to a set class, one equivalence at a time — octave, permutation, cardinality, transposition, inversion — with Guitar Alchemist's type at each rung, its OPTIC-K embedding schema alongside, and two tools that let you climb the ladder by hand.
sidebar:
  label: "Appendix B: the OPTIC hierarchy"
  order: 91
---

Lessons 1 to 4 climb a ladder without naming it. Lesson 1 turns a fretboard position into a pitch and a pitch into a pitch class. Lesson 2 turns a set of pitch classes into a scale and compares scales that are transpositions of each other. Lesson 4 identifies sets related by transposition and inversion and calls the result a set class. Each of those steps **forgets** something on purpose, and the order in which you forget them is a hierarchy that music theory has a name for.

Callender, Quinn and Tymoczko call the five equivalences **OPTIC**, in ["Generalized Voice-Leading Spaces"](https://www.science.org/doi/10.1126/science.1153021) (*Science*, 2008):

| | equivalence | two things are the same when they differ only by… |
|---|---|---|
| **O** | octave | moving notes by whole octaves |
| **P** | permutation | the order of the notes |
| **T** | transposition | moving everything by the same interval |
| **I** | inversion | turning the intervals upside down |
| **C** | cardinality | doubling a note that is already there |

They are independent: you can apply any subset, and each subset names a different musical object. "Chord" is usually OPC. "Scale type" is OPTC. "Set class" is OPTIC, all five.

```bash
dotnet run --project code/music-theory-ga/GaTheory -c Release -- l10
```

## The climb

Start at the bottom, with something you can actually do with your hands: the open C chord, `x32010`.

```text
== One fingering, climbed rung by rung
rung                       the object                         what it forgets
a fingering                x32010                             nothing: strings, frets, muted strings
the pitches                C3 E3 G3 C4 E4                     which string each note was played on
- O, octave                0 4 7 0 4                          the octave of each note
- P, permutation           0 0 4 4 7                          the order of the notes
- C, cardinality           0 4 7                              doubled notes
- T, transposition         0 4 7                              which key it is in
- I, inversion             (037)                              major against minor
```

Read the third column downwards and you have the whole appendix. A fingering knows everything. By the top, all that survives is the shape `(037)` — a note, a note three semitones up, a note four semitones above that, in some key, either way up.

Note what is *not* on the ladder. The first step, from `x32010` to `C3 E3 G3 C4 E4`, is not an OPTIC equivalence at all: it is the instrument. Two different fingerings that sound the same five pitches are the same *music* and different *guitar*. OPTIC has nothing to say about that difference, which is exactly why a program that works on set classes cannot tell you where to put your fingers.

## What each rung throws away

```text
== What each rung identifies
rung                       distinct objects     of the C major triad
fingerings, frets 0 to 4   63                   ways to play these three pitch classes
pitch multisets            5                    notes sounding in x32010
the pitch-class set        1                    0 4 7
- T: transposition class   1                    one of the 12 major triads
- I: set class             1                    one of the 24 major and minor triads
```

Sixty-three ways to play those three pitch classes on the first five frets, and the ladder's first three rungs flatten all of them into one object. That is the point of an equivalence, and it is also the cost: everything a guitarist cares about lives below the rung where the ladder starts.

```text
== How many objects there are at each rung
rung                           course   GA       check
pitch-class sets (P, O, C)     4096     4096     ok
transposition classes (+T)     352      352      ok
set classes (+I)               224      224      ok
cardinalities (+C)             13       13       ok
```

4096 subsets of twelve pitch classes; 352 of them up to transposition; 224 up to transposition and inversion. GA's `PitchClassSet`, `TranspositionClass` and `SetClass` agree with the course on all three counts, which is the appendix's way of saying the hierarchy is really there in the code.

## Two chords at a time

```text
== The same climb for four chords
chord          pitch classes      transposition class / set class
C              0 4 7              0 4 7  /  (037)
A minor        0 4 9              0 3 7  /  (037)
G              2 7 E              0 4 7  /  (037)
F              0 5 9              0 4 7  /  (037)
C and G are different chords, the same transposition class, the same set class.
C and A minor are different transposition classes and the same set class: I joins them.
```

C and G are different chords that meet at the T rung. C and A minor are different transposition classes that meet at the I rung — which is the formal version of the fact, in lesson 5, that a major key and its relative minor share a set of notes. F and G are two more major triads: the same rung, the same object.

## GA's type at each rung

```text
== GA's types, one per rung
rung                       course                     GA                         check
- O, P, C: a set           id 145: 0 4 7              id 145: 0 4 7              ok
cardinality                3                          3                          ok
- I: prime form            (037)                      (037)                      ok
interval-class vector      <0 0 1 1 1 0>              <0 0 1 1 1 0>              ok
GA's SetClass for this set: SetClass[3 (Tritonic)-<0 0 1 1 1 0>/137]
its Forte number: 3-11
```

- **[`PitchClassSet`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClassSet.cs)** is the object after O, P and C: a 12-bit id, no octaves, no order, no doubling. Lesson 7's key-finding bug is a direct consequence — a `PitchClassSet` cannot know which note is the tonic, because "which note is first" is precisely what P threw away.
- **[`TranspositionClass`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/TranspositionClass.cs)** adds T: 352 items.
- **[`SetClass`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/SetClass.cs)** adds I: 224 items, each with a prime form, a cardinality and an interval-class vector.
- **`Cardinality`** is C, kept as a property rather than a quotient.

Two rungs have no type, and both absences show up elsewhere in this course. There is no object between a pitch and a pitch class — no "pitch with a spelling" that survives a chord — which is lesson 3's spelling problem. And there is nothing *below* `PitchClassSet` that keeps the order of the notes, which is lesson 7's.

## GA's OPTIC-K embedding schema

GA uses the same vocabulary for machine learning. Its embedding schema, documented in [`.agent/skills/optic-k-schema-guardian/SKILL.md`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/.agent/skills/optic-k-schema-guardian/SKILL.md) and implemented in `Common/GA.Business.ML/Embeddings/EmbeddingSchema.cs`, is **216 dimensions** split into named partitions. Two of them are this ladder, cut in half:

| Partition | Dimensions | Weight | Purpose, in GA's words |
|---|---|---|---|
| STRUCTURE | 6-29 | 0.45 | "Pitch-class set invariants (O+P+T+I). Core musical identity." |
| MORPHOLOGY | 30-53 | 0.25 | "Physical fretboard realization (geometry/fingering)." |

STRUCTURE is the **top** of the ladder: the four equivalences, the object that survives them, weighted highest because two voicings of the same set class really are the same harmony. MORPHOLOGY is everything the ladder **discarded** on the way up: which string, which fret, which finger — the step from `x32010` to `C3 E3 G3 C4 E4` that OPTIC does not model.

That split is the right one, and it is worth saying why. A search that used only STRUCTURE would return the C major triad played anywhere, including places no hand reaches. A search that used only MORPHOLOGY would return shapes that look alike and sound unrelated. The two partitions are the two halves of this appendix, given weights.

*To verify*: the dimension ranges and weights above are read from the skill document at the pinned commit, whose front matter calls the schema v1.4; the course program does not build `GA.Business.ML`, so nothing here is checked by running it, unlike the tables above.

## Climbing the ladder by hand

Two sites let you do every rung of this appendix with a mouse, and both are worth an evening.

**[Ian Ring's scale finder](https://ianring.com/musictheory/scales/finder/)** is a twelve-bead bracelet, exactly the diagram of lesson 2. Click the beads to build a set; the page names it and links to its page. Its three buttons are three rungs of the ladder:

- **Rotate up** and **Rotate down** apply **T**, one semitone at a time. Rotate twelve times and you are back where you started: that orbit is the transposition class.
- **Reflect** applies **I**. If reflecting gives you the set you already had, the set is inversionally symmetric and its set class contains 12 sets rather than 24 — the diatonic collection, the whole-tone scale and the octatonic scale all behave this way, which is lesson 2's section on symmetry.
- The scale's number is the 12-bit id of lesson 2, and [each scale's page](https://ianring.com/musictheory/scales/2477) gives its modes, its interval vector and whether it is a Z-relation partner, which is lesson 4.

It is the fastest way to check a claim in this course: the counts in lesson 2 and the vectors in lesson 4 can be confirmed one set at a time on Ring's pages, and that is how several of them were.

**[Harmonious](https://harmoniousapp.net/)** approaches the same material from the other end. It calls itself "a map of all chromatic-cluster-free hexatonic, heptatonic, and octotonic scales and modes and their compatible chords (Levine 1995) in twelve-tone equal temperament", and it is organised by key signature and by chord rather than by set number. Where Ring gives you the *quotient* — one page per scale, transpositions collapsed — Harmonious gives you the *fibre*: this key, these chords, these substitutions. Between them they are the two directions of this appendix, and neither is a replacement for the other:

| | Ian Ring | Harmonious |
|---|---|---|
| Unit | a set class, keyless | a key and its chords |
| Rungs it shows | T and I, as buttons | below the ladder: voicings and chord–scale pairs |
| Best for | checking a count or a vector | finding a substitution you can play |
| Relation to GA | same 12-bit numbering | same chord–scale idea as lessons 6 and 7 |

GA sits between the two: `SetClass` is Ring's object, `Voicing` and `Fretboard` are closer to Harmonious's, and the OPTIC-K schema above is a deliberate attempt to hold both in one vector.

## What to remember

- OPTIC is five independent things to forget, not one operation. Naming which ones you have applied tells you what your type can and cannot answer.
- Every bug in Appendix C's defects 8, 9, 12 and 19 is a rung being climbed and then a question asked that needed the discarded information: a spelling after O, a tonic after P, a count after C.
- The instrument is *below* the bottom rung. OPTIC says nothing about fingering, which is why GA needs a second partition for it.

## Sources

- Clifton Callender, Ian Quinn and Dmitri Tymoczko, ["Generalized Voice-Leading Spaces"](https://www.science.org/doi/10.1126/science.1153021), *Science* 320 (2008), the paper that names OPTIC.
- Dmitri Tymoczko, [*A Geometry of Music*](https://dmitri.mycpanel.princeton.edu/geometry-of-music.html) (Oxford, 2011), chapters 2 and 3.
- Ian Ring, [*A Study of Musical Scales*](https://ianring.com/musictheory/scales/) and its [scale finder](https://ianring.com/musictheory/scales/finder/).
- [Harmonious](https://harmoniousapp.net/), and Mark Levine, *The Jazz Theory Book* (1995), which it cites for its chord–scale pairs.
- GuitarAlchemist/ga at [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `Common/GA.Domain.Core/Theory/Atonal` and [`.agent/skills/optic-k-schema-guardian/SKILL.md`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/.agent/skills/optic-k-schema-guardian/SKILL.md).
- The course program: [`Lesson10.cs`](https://github.com/spareilleux/learn/blob/main/code/music-theory-ga/GaTheory/Lesson10.cs), [`expected/l10.txt`](https://github.com/spareilleux/learn/blob/main/code/music-theory-ga/expected/l10.txt).
