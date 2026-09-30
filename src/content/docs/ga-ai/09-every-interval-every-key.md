---
title: "Lesson 9: Every interval, every key"
description: "Guitar Alchemist's three skills that spell notes without a model, IntervalSkill, ScaleInfoSkill and RelativeKeySkill, asked every interval two note names can make and every key, and graded by a textbook's letter arithmetic. A sharp on the second note is dropped, so E to G# is a minor third; a unison lowered is a perfect unison; the relative minor of B major depends on which skill answers; and eight of IntervalSkill's thirteen example prompts are questions it can't read."
sidebar:
  label: 9. Every interval, every key
  order: 9
---

Lessons 5 and 7 found chord symbols the chatbot misreads. A chord name can be ambiguous; a spelling question can't. "What is the interval from E to G#?" has one answer, a major third, and a textbook computes it from the letters: E, F, G is three letters, so a third; four semitones, so major. GA's chatbot has three skills that answer such questions without a model: [`IntervalSkill`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IntervalSkill.cs), [`ScaleInfoSkill`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ScaleInfoSkill.cs) and [`RelativeKeySkill`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/RelativeKeySkill.cs). This lesson asks them every interval two note names can make and every key, and grades each answer.

All GA links point to commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), the course's pin. On GA's `main` at [`53b7253`](https://github.com/GuitarAlchemist/ga/commit/53b7253596e71e40c02208a3a85edd25419aeb53), `IntervalSkill.cs`, `IntervalNaming.cs`, `KeyNaming.cs` and the domain's `NoteExtensions.cs` are unchanged; `ScaleInfoSkill` and `RelativeKeySkill` have changed only in `CanHandle` and in a `Declined` flag on the refusal `RelativeKeySkill` gives when none of its patterns match, which no answer below goes through. The outputs come from:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l9
```

## The textbook

The course's oracle is about twenty lines in [`Lesson9.cs`](https://github.com/spareilleux/learn/blob/main/code/ga-ai/GaAi/Lesson9.cs). An interval's number counts letters, from the first note's letter up to the second's; its quality compares its semitones with the major or perfect interval of that number:

```csharp
static (string Short, string Long, int Semitones) Interval(string a, string b)
{
    var steps = (Letters.IndexOf(b[0]) - Letters.IndexOf(a[0]) + 7) % 7;
    var semitones = ((Pitch(b) - Pitch(a)) % 12 + 12) % 12;
    var offset = ((semitones - MajorSteps[steps] + 6) % 12 + 12) % 12 - 6;
    var perfect = steps is 0 or 3 or 4;
    var quality = (perfect, offset) switch
    {
        (true, 0) => "P",
        (false, 0) => "M",
        (false, -1) => "m",
        (_, > 0) => new string('A', offset),
        (true, < 0) => new string('d', -offset),
        _ => new string('d', -offset - 1),
    };
    // Counted from the major or perfect interval of that number: C to Cb is a semitone down
    return ($"{quality}{steps + 1}", $"{QualityName(quality)} {Sizes[steps]}", MajorSteps[steps] + offset);
}
```

A key's scale is spelled the same way: seven letters from the tonic, each with the accidental that puts it at the right distance. The relative minor of a major key is its sixth note, the relative major of a minor key its third, and the signature counts the scale's accidentals. The 21 note names are the seven letters with a flat, nothing or a sharp; the 30 keys are the fifteen of each mode with at most seven sharps or flats.

## 441 questions

Each question is "What is the interval from X to Y?", sent to the intent `skill.interval`, as lesson 8 sent its prompts. GA's answer names the two notes it read, which tells a misread note from a miscomputed interval:

```text
== IntervalSkill, "What is the interval from X to Y?" for the 21 x 21 note names
. right   # a note read as another   a right interval, quality abbreviated   x wrong interval

from\to Cb C  C# Db D  D# Eb E  E# Fb F  F# Gb G  G# Ab A  A# Bb B  B#
Cb      .  .  #  .  .  #  .  .  #  .  .  #  .  .  #  .  .  #  .  x  # 
C       x  .  #  .  .  #  .  .  #  .  .  #  .  .  #  .  .  #  .  .  # 
C#      x  x  #  .  .  #  .  .  #  a  .  #  a  .  #  .  .  #  .  .  # 
Db      .  .  #  .  .  #  .  .  #  .  .  #  .  .  #  .  .  #  .  .  # 
D       .  .  #  x  .  #  .  .  #  .  .  #  .  .  #  .  .  #  .  .  # 
D#      a  .  #  x  x  #  .  .  #  a  .  #  a  .  #  a  .  #  .  .  # 
Eb      .  .  #  .  .  #  .  .  #  .  .  #  .  .  #  .  .  #  .  .  # 
E       .  .  #  .  .  #  x  .  #  .  .  #  .  .  #  .  .  #  .  .  # 
E#      a  .  #  a  .  #  x  x  #  x  .  #  a  .  #  a  .  #  a  .  # 
Fb      .  .  #  .  .  #  .  x  #  .  .  #  .  .  #  .  .  #  .  a  # 
F       .  .  #  .  .  #  .  .  #  x  .  #  .  .  #  .  .  #  .  .  # 
F#      a  .  #  .  .  #  .  .  #  x  x  #  .  .  #  .  .  #  .  .  # 
Gb      .  .  #  .  .  #  .  .  #  .  .  #  .  .  #  .  .  #  .  .  # 
G       .  .  #  .  .  #  .  .  #  .  .  #  x  .  #  .  .  #  .  .  # 
G#      a  .  #  a  .  #  .  .  #  a  .  #  x  x  #  .  .  #  .  .  # 
Ab      .  .  #  .  .  #  .  .  #  .  .  #  .  .  #  .  .  #  .  .  # 
A       .  .  #  .  .  #  .  .  #  .  .  #  .  .  #  x  .  #  .  .  # 
A#      a  .  #  a  .  #  a  .  #  a  .  #  a  .  #  x  x  #  .  .  # 
Bb      .  .  #  .  .  #  .  .  #  .  .  #  .  .  #  .  .  #  .  .  # 
B       .  .  #  .  .  #  .  .  #  a  .  #  .  .  #  .  .  #  x  .  # 
B#      x  .  #  a  .  #  a  .  #  x  a  #  a  .  #  a  .  #  x  x  # 

441 questions: 241 right, 147 with a note read as another, 27 right with the quality abbreviated, 26 wrong
```

The `#` columns are every question whose second note has a sharp: 7 sharps times 21 first notes, 147 questions, all answered for the natural note. The pattern ([lines 62-64](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IntervalSkill.cs#L62-L64)) ends in `\b`:

```csharp
    private static readonly Regex IntervalPattern = new(
        @"\b([A-Ga-g][#b]?)\s*(?:to|and)\s+([A-Ga-g][#b]?)\b",
        RegexOptions.IgnoreCase | RegexOptions.Compiled);
```

`\b` is a boundary between a word character and a non-word character, or between a word character and the start or end of the text. After `G#` comes a question mark, a space or the end of the text, and `#` isn't a word character either, so there is no boundary there; the engine gives the optional `#` back and matches `G`, followed by the boundary between `G` and `#`. A flat survives, because `b` is a letter, and the first note survives, because no `\b` follows it. It is the same final `\b` that made `ImprovisationSkill` read `F#` as `F` in [lesson 7](../07-chord-names/), GA issue [#757](https://github.com/GuitarAlchemist/ga/issues/757), in another skill's pattern.

Written other ways, the same questions fare no better:

```text
== The same question, written another way
What is the interval between E and G#?
  | From **E** to **G** is a **minor third** (m3, 3 semitones).
What is the interval from C to F♯?
  | From **C** to **F** is a **perfect fourth** (P4, 5 semitones).
What is the interval from B♭ to D?
  | Could not parse two note names from your question.
```

E to G# is the third of an E major chord. The `♯` of `F♯` isn't in the pattern's character class, so the pattern stops before it and reads F; `B♭` isn't read at all.

## Where the domain is wrong

27 answers are right with an abbreviated quality: `IntervalNaming.QualityLongName` ([lines 56-64](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/IntervalNaming.cs#L56-L64)) names five qualities, so a doubly augmented fourth is printed "AA fourth". The 26 others are wrong with both notes read right:

```text
== The note names read right, the interval wrong
Cb to B   GA major seventh (M7, 11)           textbook augmented seventh (A7, 12)
C  to Cb  GA perfect unison (P1, 0)           textbook diminished unison (d1, -1)
C# to Cb  GA perfect unison (P1, 0)           textbook doubly diminished unison (dd1, -2)
C# to C   GA perfect unison (P1, 0)           textbook diminished unison (d1, -1)
D  to Db  GA perfect unison (P1, 0)           textbook diminished unison (d1, -1)
D# to Db  GA perfect unison (P1, 0)           textbook doubly diminished unison (dd1, -2)
D# to D   GA perfect unison (P1, 0)           textbook diminished unison (d1, -1)
E  to Eb  GA perfect unison (P1, 0)           textbook diminished unison (d1, -1)
E# to Eb  GA perfect unison (P1, 0)           textbook doubly diminished unison (dd1, -2)
E# to E   GA perfect unison (P1, 0)           textbook diminished unison (d1, -1)
E# to Fb  GA major second (M2, 2)             textbook doubly diminished second (dd2, -1)
Fb to E   GA major seventh (M7, 11)           textbook augmented seventh (A7, 12)
F  to Fb  GA perfect unison (P1, 0)           textbook diminished unison (d1, -1)
F# to Fb  GA perfect unison (P1, 0)           textbook doubly diminished unison (dd1, -2)
F# to F   GA perfect unison (P1, 0)           textbook diminished unison (d1, -1)
G  to Gb  GA perfect unison (P1, 0)           textbook diminished unison (d1, -1)
G# to Gb  GA perfect unison (P1, 0)           textbook doubly diminished unison (dd1, -2)
G# to G   GA perfect unison (P1, 0)           textbook diminished unison (d1, -1)
A  to Ab  GA perfect unison (P1, 0)           textbook diminished unison (d1, -1)
A# to Ab  GA perfect unison (P1, 0)           textbook doubly diminished unison (dd1, -2)
A# to A   GA perfect unison (P1, 0)           textbook diminished unison (d1, -1)
B  to Bb  GA perfect unison (P1, 0)           textbook diminished unison (d1, -1)
B# to Cb  GA major second (M2, 2)             textbook doubly diminished second (dd2, -1)
B# to Fb  GA perfect fifth (P5, 7)            textbook triply diminished fifth (ddd5, 4)
B# to Bb  GA perfect unison (P1, 0)           textbook doubly diminished unison (dd1, -2)
B# to B   GA perfect unison (P1, 0)           textbook diminished unison (d1, -1)
```

21 of them are a unison lowered, the second note on the same letter with fewer sharps or more flats: "C# to C" is a perfect unison of 0 semitones. The domain computes the semitones modulo 12 ([`NoteExtensions.cs` line 110](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Primitives/Extensions/NoteExtensions.cs#L110)), so C# to C is 11, and `DetermineQuality` subtracts the unison's 0 ([lines 13-56](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Primitives/Extensions/NoteExtensions.cs#L13-L56)). A difference of 11 has no arm, and the default arm returns perfect; the switch for seconds, thirds, sixths and sevenths has arms from -3 to 2 and returns major by default:

```csharp
            return difference switch
            {
                -2 => IntervalQuality.DoublyDiminished,
                -1 => IntervalQuality.Diminished,
                0 => IntervalQuality.Perfect,
                1 => IntervalQuality.Augmented,
                2 => IntervalQuality.DoublyAugmented,
                _ => IntervalQuality.Perfect
            };
```

The other five go through the same default: Cb to B is twelve semitones, 0 modulo 12, and becomes a major seventh. They need a Cb, Fb, E# or B#, which a guitarist rarely writes; the unisons don't. GA's `main` has a different `Note.cs`, so these answers were checked there once, outside the course program: `GA.Domain.Core`, with the `GA.Core` and `GA.Business.Config` it references, and `IntervalNaming.cs` taken from `main` with `git archive` and run on the 441 pairs with the notes read right. The 21 unisons and the five others come out the same, and so does C to B#, an augmented seventh it calls major; on the pinned skill its sharp is dropped first.

## Keys

For each of the 30 keys the program asks `ScaleInfoSkill` for its notes, which it gives with the relative key, and asks `RelativeKeySkill` for the relative key and the signature. Only the keys where something differs are printed:

```text
== ScaleInfoSkill and RelativeKeySkill on the 30 keys with at most seven sharps or flats
key         notes  relative key: ScaleInfoSkill  RelativeKeySkill  textbook      signature
Cb major    right  Ab minor                        Ab minor          Ab minor      not read as a key
B major     right  Ab minor                        G# minor          G# minor      5 sharps
F# major    right  Eb minor                        D# minor          D# minor      6 sharps
C# major    right  Bb minor                        A# minor          A# minor      7 sharps
G# minor    right  Cb major                        B major           B major       5 sharps
D# minor    right  Gb major                        F# major          F# major      6 sharps
A# minor    right  Db major                        C# major          C# major      7 sharps

30 keys: notes right 30, relative key right: ScaleInfoSkill 24, RelativeKeySkill 30; signature right 29
How many flats in Cb major?
  | I couldn't identify 'Cb' as a key. Try a single pitch letter optionally followed by # or b (e.g. C, G, F#, Bb).
```

The notes of all 30 scales are right. The relative key isn't, for six keys and for one of the two skills: `ScaleInfoSkill` says the relative minor of B major is A♭ minor, and `RelativeKeySkill` says G♯ minor. `ScaleInfoSkill` gets the name from `KeyNaming.RelativeKeyName` ([lines 55-65](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/KeyNaming.cs#L55-L65)), which takes the first key of the other mode with the same pitch classes; G♯ minor and A♭ minor have the same pitch classes, and A♭ minor comes first. The six keys are the sharp keys that have a flat twin. `RelativeKeySkill` was fixed for exactly this in May: its comment ([lines 119-125](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/RelativeKeySkill.cs#L119-L125)) says the old lookup "always returned flat-side spellings" and that "F# major incorrectly returned "Ebm"". The fix went into one skill; the helper the other skill calls kept the old method. "What notes are in B major?" and "What is the relative minor of B major?" get two different answers from the same chatbot.

C♭ major is read by `RelativeKeySkill` when asked for its relative minor, which it looks up in its circle of fifths ([lines 84-91](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/RelativeKeySkill.cs#L84-L91)), and not when asked for its signature, which starts from a table of roots without C♭ ([lines 72-81](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/RelativeKeySkill.cs#L72-L81)). The refusal then asks for what the user wrote: "a single pitch letter optionally followed by # or b".

Past seven sharps or flats, the keys are theoretical. `ScaleInfoSkill` says it doesn't recognize them, and `RelativeKeySkill` answers:

```text
== Keys past seven sharps or flats that RelativeKeySkill reads
What notes are in G# major?
  | I don't recognise "G# major" as a standard key. Try a key like C major, F# minor, or Bb major.
How many sharps in D# major?  textbook 9 sharps, usually written Eb major
  | **D# major** has no sharps or flats.
How many sharps in G# major?  textbook 8 sharps, usually written Ab major
  | **G# major** has no sharps or flats.
How many sharps in A# major?  textbook 10 sharps, usually written Bb major
  | **A# major** has no sharps or flats.
How many sharps in Db minor?  textbook 8 flats, usually written C# minor
  | **Db minor** has no sharps or flats.
How many sharps in Gb minor?  textbook 9 flats, usually written F# minor
  | **Gb minor** has no sharps or flats.
What is the parallel minor of G# major?  textbook: G# minor has 5 sharps
  | Same root note (**G#**) but different scales — the parallel minor lowers the 3rd, 6th, and 7th degrees. G# major has no sharps or flats; G# minor has 3 flats (three positions counter-clockwise on the circle of fifths).
```

The table of roots holds the seventeen usual note names; the circle of fifths holds fifteen keys of each mode, without D♯, G♯ or A♯ major or D♭ or G♭ minor. For a key found in the first and not the second, `MajorSharpsFlats` and `MinorSharpsFlats` return 0 ([lines 208-212](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/RelativeKeySkill.cs#L208-L212)), which is printed as "no sharps or flats". The parallel minor subtracts three from that 0, and G♯ minor, a key with five sharps, is said to have three flats.

## The skills' own examples

An intent lists example prompts, and the intent router sends a question to the intent whose examples it resembles most ([`IIntent.cs` lines 29-32](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Intents/IIntent.cs#L29-L32)). The intent that wraps a skill passes the question straight to the skill's `ExecuteAsync` ([`OrchestratorSkillIntent.cs` line 29](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core.Orchestration/Intents/OrchestratorSkillIntent.cs#L29)). So each skill should at least answer its own examples:

```text
== Each skill's example prompts, which the intent router matches questions against, sent to that skill
skill.interval: 5 of 13 answered
  What's a perfect fifth?                  | Could not parse two note names from your question.
  What is a major sixth?                   | Could not parse two note names from your question.
  Define a minor third                     | Could not parse two note names from your question.
  Minor third up from D                    | Could not parse two note names from your question.
  Perfect fourth above C                   | Could not parse two note names from your question.
  Major sixth above G                      | Could not parse two note names from your question.
  augmented fourth definition              | Could not parse two note names from your question.
  semitones in a major sixth               | Could not parse two note names from your question.
skill.scaleinfo: 21 of 24 answered
  What's the formula for harmonic minor    | Could not parse a key name from your question.
  Formula for melodic minor scale          | Could not parse a key name from your question.
  what notes are in the B flat major scale | Could not parse a key name from your question.
skill.relativekey: 12 of 12 answered
```

Eight of `IntervalSkill`'s examples, five definitions and three questions such as "Minor third up from D", name at most one note, and its pattern needs two joined by "to" or "and". The comment above them ([lines 34-44](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IntervalSkill.cs#L34-L44)) says they were added to win these questions from `CircleOfFifthsSkill` and `ScaleInfoSkill`: the routing was fixed, and the answer it routes to is "Could not parse two note names from your question." What the whole chatbot serves for them needs the embedding model, which the course doesn't run (*to verify*). The direct-chat fallback is off by default and gated on the router's confidence, not the skill's ([`IFallbackChatHandler.cs` line 66](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core.Orchestration/Abstractions/IFallbackChatHandler.cs#L66), [`FallbackChatApplicationService.cs` lines 142-158](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core.Orchestration/Services/FallbackChatApplicationService.cs#L142-L158)). On `main`, `IntentResult` has gained a `Declined` flag for a query "that does not have the input shape this intent handles", which lets the orchestrator try the next path; `IntervalSkill` doesn't set it.

`ScaleInfoSkill` misses two formula questions, which name no key, and "B flat" written as a word, because its pattern wants the accidental as a symbol next to the letter.

## Where the course stops

- **One phrasing per kind of question**, plus the three variants of the interval question. Other phrasings may be read differently.
- **No double sharps or flats in the questions.** The 21 names have at most one accidental; the textbook handles two, for the theoretical keys.
- **Routing isn't tested.** The questions go to the intents directly; which intent the router picks for them, and what the chatbot serves when the skill can't read them, needs the model.
- **Theoretical keys may be refused.** A chatbot that says it doesn't know G♯ major is honest; the finding is the wrong count, not the refusal.
- **`main`'s domain was checked once**, by hand, not by the course program.

## Reported upstream

- Not reported upstream when this lesson was written: the dropped sharp, the unrecognized `♯` and `♭`, the lowered unisons and the default arm, the abbreviated qualities, `ScaleInfoSkill`'s relative keys, `RelativeKeySkill`'s signatures past seven accidentals and its refusal of C♭, and the example prompts the skills can't answer. They are listed in the [journal](../journal/).

## Exercises

1. Rewrite `IntervalPattern` so that "E and G#" reads `G#` and "B♭ to D" reads `B♭`, without changing what it reads in "distance from F# to D" or "interval from Bb to Eb". What else has to change for `B♭` to be answered?
2. `DetermineQuality` gets a difference between 0 and 11 minus the expected semitones. How would you bring it into the range its arms cover, and what does C# to C become? Which of the 26 wrong answers would still reach the default arm?
3. Rewrite `KeyNaming.RelativeKeyName` so that it gives G♯ minor for B major and B major for G♯ minor, and still A♭ minor for C♭ major.
4. Predict `IntervalSkill`'s answer to "What is the interval between C and F sharp?" and `ScaleInfoSkill`'s to "what notes are in the B flat major scale". Which of the two answers is worse for a user, and why?

<details>
<summary>Solutions</summary>

1. `\b([A-Ga-g][#b♯♭]?)\s*(?:to|and)\s+([A-Ga-g][#b♯♭]?)(?![\w#♯♭])`: the accidental class gains `♯` and `♭`, and the final `\b` becomes a lookahead that only forbids another letter, digit or accidental after the note, so it no longer needs a word character before it. Checked with .NET's regex engine on the questions of the exercise and of this lesson: `E|G#`, `C|F♯`, `B♭|D`, `F#|D`, `Bb|Eb`. The notes then go to `IntervalNaming.TryParseNote`, which passes them to the domain's parsers; replacing `♯` and `♭` with `#` and `b` first, as `RelativeKeySkill.NormalizeKey` does ([line 226](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/RelativeKeySkill.cs#L226)), means the skill doesn't depend on whether those parsers accept them. Not compiled against GA (*to verify*).
2. Wrap it: `((difference + 6) % 12 + 12) % 12 - 6` gives a value from -6 to 5. C# to C gives 11 - 0 = 11, wrapped to -1: a diminished unison, a semitone down. The 21 unisons, the two sevenths (-11 becomes 1, augmented) and the two seconds (9 becomes -3, doubly diminished) then have an arm; B# to Fb, 4 - 7 = -3 for a fifth, is triply diminished, and the perfect switch stops at doubly, so it still reaches the default. The semitones the skill prints come from the interval the domain builds from the quality and the number, so what it prints for a diminished unison has to be checked as well (*to verify*). Worked by hand from the code.
3. Match the key signature instead of the pitch classes: the relative key is the key of the other mode with the same number of accidentals of the same kind, `Key.Items.First(k => k.KeyMode != key.KeyMode && k.KeySignature.AccidentalCount == key.KeySignature.AccidentalCount && k.KeySignature.AccidentalKind == key.KeySignature.AccidentalKind)`. B major has five sharps, like G♯ minor and unlike A♭ minor's seven flats; C♭ major has seven flats, like A♭ minor. C major and A minor have no accidentals, and their kind must compare equal for them to match. Not compiled against GA (*to verify*).
4. `IntervalSkill` reads "C and F" and answers "From **C** to **F** is a **perfect fourth** (P4, 5 semitones)": the word "sharp" is outside the pattern, and the answer names F, which a careful reader might notice. `ScaleInfoSkill` answers "Could not parse a key name from your question." The first is worse: a refusal sends the user to rephrase, a wrong answer about a different note is believed. Checked with the course program on 2026-09-29, by asking both questions for one run.

</details>

## Key takeaways

- A spelling question has one right answer, and a textbook's letter arithmetic computes it: an interval's number counts letters, its quality counts semitones. That makes every such skill testable against all its inputs, here 441 intervals and 30 keys.
- A regular expression that ends in `\b` after an optional `#` drops the `#` whenever a space, punctuation or the end of the text follows it. GA has this flaw in the patterns of at least two skills; E to G# comes out a minor third.
- A switch with a default arm hides the values nobody expected: semitones taken modulo 12 give differences the arms don't cover, and the default says "perfect".
- A fix applied to one of two code paths leaves the chatbot contradicting itself: the relative minor of B major is G♯ minor or A♭ minor depending on which skill the router picks.
- A skill's example prompts are a test it can run on itself. `IntervalSkill` fails eight of its thirteen.

## Sources

- GuitarAlchemist/ga at [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `Common/GA.Business.ML/Agents/Skills/IntervalSkill.cs`, `ScaleInfoSkill.cs`, `RelativeKeySkill.cs`, `Common/GA.Business.ML/Agents/IntervalNaming.cs`, `KeyNaming.cs`, `Common/GA.Business.ML/Agents/Intents/IIntent.cs`, `Common/GA.Business.Core.Orchestration/Intents/OrchestratorSkillIntent.cs`, `Common/GA.Business.Core.Orchestration/Services/FallbackChatApplicationService.cs`, `Common/GA.Domain.Core/Primitives/Extensions/NoteExtensions.cs`.
- GA's `main` at [`53b7253`](https://github.com/GuitarAlchemist/ga/commit/53b7253596e71e40c02208a3a85edd25419aeb53), committed on 2026-09-30 UTC: `OrchestratorSkillIntent.cs` and `IIntent.cs` for the `Declined` flag; `GA.Domain.Core` for the one-off check of the intervals.
- *Open Music Theory*, the fundamentals chapters on intervals and key signatures, for the textbook's definitions: interval number by letters, quality by semitones, relative keys sharing a signature.
