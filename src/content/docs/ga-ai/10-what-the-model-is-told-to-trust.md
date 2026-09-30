---
title: "Lesson 10: What the model is told to trust"
description: "Guitar Alchemist's Transpose, DiatonicChords and CommonTones skills tell a model to call a deterministic closure through the ga_dsl_eval tool and to use its answer. The course calls that tool with the arguments each SKILL.md prescribes and grades the closures by a textbook's letter arithmetic: D minor comes back with an A♯, G7 transposed to E♭ is D♯7, and the C♯ that the chords A and C♯m share comes back as D♭."
sidebar:
  label: 10. What the model is told to trust
  order: 10
---

[Lesson 9](../09-every-interval-every-key/) tested the skills that spell notes without a model. Three other skills, [`TransposeSkill`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/TransposeSkill.cs), [`DiatonicChordsSkill`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/DiatonicChordsSkill.cs) and [`CommonTonesSkill`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/CommonTonesSkill.cs), hand the question to a model, and their SKILL.md files tell it not to compute the answer: it must call a closure through the `ga_dsl_eval` tool and use what comes back. The diatonic-chords SKILL.md gives spelling as the reason, in [its description](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/diatonic-chords/SKILL.md#L3): "since LLMs commonly mis-spell the iv/vii° in less-common keys". The course can't run the model, but it can call the tool the model is told to call, with the arguments the SKILL.md prescribes. Whatever the closure answers is what a model that follows its instructions will say.

All GA links point to commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), the course's pin. On GA's `main` at [`53b7253`](https://github.com/GuitarAlchemist/ga/commit/53b7253596e71e40c02208a3a85edd25419aeb53), the three SKILL.md files, the three skills and `ga_dsl_eval` are unchanged. `DomainClosures.fs` has changed there, but not in the code this lesson calls: `transposeChord`, `diatonicChords`, the two arrays of note names, `preferFlat`, `conventionalKeyName` and the line where `commonTones` names a note are identical, compared function by function. The chord parser has changed there: it now rejects anything left after the symbol and reads `sus`, capitalized `Maj7` and `omit` forms, and the symbols below have none of these. The outputs come from:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l10
```

## What the model is told

The three skills route only through the intent router's embeddings: [`SkillMdDrivenWrapperBase`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/SkillMdDrivenWrapperBase.cs#L85) returns `false` from `CanHandle`. Once chosen, a skill passes the question to a model with its SKILL.md as instructions; each of the three SKILL.md files lists one tool under `allowed-tools`, `ga_dsl_eval`. The wrapper then checks whether the model called the tool ([lines 111-144](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/SkillMdDrivenWrapperBase.cs#L111-L144)). If it did, the answer's evidence gets `grounding.source: ga.dsl@domain.diatonicChords` (or the skill's closure) and the model's confidence is kept. If it didn't, the evidence says "answer is LLM-only, not deterministic" and the confidence is capped at 0.5. The design trusts the closure more than the model.

The SKILL.md files say the same in prose. [diatonic-chords](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/diatonic-chords/SKILL.md#L26): "Do NOT enumerate the chords mentally — the closure handles enharmonic spelling correctly". [transpose](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/transpose/SKILL.md#L28): "Do NOT compute the transposition mentally — for less-common keys (Gb major, C# minor) the LLM will confidently flip enharmonics and produce wrong spellings". [common-tones](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/common-tones/SKILL.md#L63): "The closure returns a formatted string already. Surface it verbatim".

`ga_dsl_eval` is a static method, [`DslEvalMcpTools.EvalClosure`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Mcp/DslEvalMcpTools.cs#L134-L139). It takes a closure name and a flat map of string arguments, which is what the model sends. The chatbot's startup registers the closures with `GaClosureBootstrap.init()` ([`ChatbotOrchestrationExtensions.cs` line 42](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core.Orchestration/Extensions/ChatbotOrchestrationExtensions.cs#L42)); [`Lesson10.cs`](https://github.com/spareilleux/learn/blob/main/code/ga-ai/GaAi/Lesson10.cs) does the same, then calls the tool:

```csharp
static DslEvalResult Eval(string closure, params (string Key, string Value)[] args) =>
    DslEvalMcpTools.EvalClosure(closure, args.ToDictionary(a => a.Key, a => a.Value));
```

The textbook is lesson 9's letter arithmetic. A key's seven triads are built on its scale, one letter per degree, with the qualities of major or natural minor. A note moved by an interval takes the letter the interval's number counts, and the accidental that gives the right number of semitones.

## Seven chords, thirty keys

The diatonic-chords SKILL.md gives two arguments: `root`, the tonic, and `scale`, `major` or `minor`. The program asks for the 30 keys with at most seven sharps or flats and prints the ones that differ from the textbook:

```text
== ga_dsl_eval "domain.diatonicChords" on the 30 keys with at most seven sharps or flats
Cb major   GA       B Dbm Ebm E Gb Abm Bbdim
           textbook Cb Dbm Ebm Fb Gb Abm Bbdim
Gb major   GA       Gb Abm Bbm B Db Ebm Fdim
           textbook Gb Abm Bbm Cb Db Ebm Fdim
F# major   GA       F# G#m A#m B C# D#m Fdim
           textbook F# G#m A#m B C# D#m E#dim
C# major   GA       C# D#m Fm F# G# A#m Cdim
           textbook C# D#m E#m F# G# A#m B#dim
Ab minor   GA       Abm Bbdim B Dbm Ebm E Gb
           textbook Abm Bbdim Cb Dbm Ebm Fb Gb
Eb minor   GA       Ebm Fdim Gb Abm Bbm B Db
           textbook Ebm Fdim Gb Abm Bbm Cb Db
C minor    GA       Cm Ddim D# Fm Gm G# A#
           textbook Cm Ddim Eb Fm Gm Ab Bb
G minor    GA       Gm Adim A# Cm Dm D# F
           textbook Gm Adim Bb Cm Dm Eb F
D minor    GA       Dm Edim F Gm Am A# C
           textbook Dm Edim F Gm Am Bb C
D# minor   GA       D#m Fdim F# G#m A#m B C#
           textbook D#m E#dim F# G#m A#m B C#
A# minor   GA       A#m Cdim C# D#m Fm F# G#
           textbook A#m B#dim C# D#m E#m F# G#

30 keys: 19 right, 11 with a chord on another letter
```

Every chord has the right root pitch and quality; 11 keys have at least one chord on the wrong letter. The closure computes each chord's root as a pitch class above the tonic and names it from one of two arrays of twelve names ([lines 22-36](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L22-L36)):

```fsharp
/// Chromatic note names using sharp spelling.
let private sharpNames = [| "C";"C#";"D";"D#";"E";"F";"F#";"G";"G#";"A";"A#";"B" |]

/// Chromatic note names using flat spelling.
let private flatNames  = [| "C";"Db";"D";"Eb";"E";"F";"Gb";"G";"Ab";"A";"Bb";"B" |]

/// True when the key conventionally uses flat accidentals.
/// F natural is the one exception among white-key roots (it contains Bb).
let private preferFlat (note: string) (acc: AccidentalType) =
    match acc with
    | Flat | DoubleFlat  -> true
    | Sharp | DoubleSharp -> false
    | Natural             -> note = "F"
```

`preferFlat` looks at the tonic, not at the key ([line 187](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L187)). F is the only white-key tonic of a flat major key, but D, G and C minor are flat keys on white-key tonics too, so their B♭, E♭ and A♭ come out A♯, D♯ and G♯. And an array indexed by pitch class has one name per pitch class: it can't write C♭, F♭, E♯ or B♯, which eight keys need. G♭ major's fourth chord, C♭, comes out B; F♯ major's seventh, E♯dim, comes out Fdim.

## The SKILL.md's examples

The SKILL.md shows the model what the closure returns:

```text
== The results diatonic-chords' SKILL.md gives for the closure
C major   GA       ["C","Dm","Em","F","G","Am","Bdim"]
          SKILL.md ["C", "Dm", "Em", "F", "G", "Am", "B°"]
A minor   GA       ["Am","Bdim","C","Dm","Em","F","G"]
          SKILL.md ["Am", "B°", "C", "Dm", "Em", "F", "G"]
Bb major  GA       ["Bb","Cm","Dm","Eb","F","Gm","Adim"]
          SKILL.md ["Bb","Cm","Dm","Eb","F","Gm","A°"]
Gb major  GA       ["Gb","Abm","Bbm","B","Db","Ebm","Fdim"]
          SKILL.md Gb major returns Cm, not B#m
F# minor  GA       ["F#m","G#dim","A","Bm","C#m","D","E"]
          SKILL.md F# minor returns G#°, not Ab°
```

The SKILL.md writes the diminished triad `B°` and the closure writes `Bdim`. The SKILL.md tells the model to use each chord "exactly as the closure returned it", so this only changes what the user reads. The claims about uncommon keys are half right. G♭ major has no C minor chord: its fourth chord is C♭ major, and the closure returns B. F♯ minor's second chord is G♯dim, which the closure does return. The skill's own description makes the same promise ([`DiatonicChordsSkill.cs` lines 27-32](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/DiatonicChordsSkill.cs#L27-L32)): the closure is called "so enharmonic spelling is correct in less-common keys (Gb major, F# minor)".

## Transposing by semitones

Transpose's SKILL.md gives two arguments, `symbol` and `semitones`, with a table from interval names to semitones ([line 42](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/transpose/SKILL.md#L42) and below): "up a minor third" is 3. The closure adds the semitones to the root's pitch class and names the result from the same two arrays, chosen by the chord's own root ([lines 159-162](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L159-L162)):

```fsharp
                      let rootPc  = (noteToSemitone ast.Root + accToSemitone ast.RootAccidental + 120) % 12
                      let newPc   = (rootPc + semitones % 12 + 12) % 12
                      let naming  = spellingOf (preferFlat ast.Root ast.RootAccidental)
                      let newRoot, newAcc = splitNoteAcc naming.[newPc]
```

The program moves each of the 21 note names up each interval of the table, from the unison to the octave, except the tritone, which the table maps to 6 semitones whatever its spelling:

```text
== ga_dsl_eval "domain.transposeChord": the 21 note names up each interval of transpose's SKILL.md but the tritone
. right   ~ right pitch, another letter   d the textbook needs a double sharp or flat   x wrong pitch

note    P1 m2 M2 m3 M3 P4 P5 m6 M6 m7 M7 P8
Cb      ~  d  .  d  .  ~  .  d  .  d  .  ~ 
C       .  ~  .  ~  .  .  .  ~  .  ~  .  . 
C#      .  .  .  .  ~  .  .  .  .  .  ~  . 
Db      .  d  .  ~  .  .  .  d  .  ~  .  . 
D       .  ~  .  .  .  .  .  ~  .  .  .  . 
D#      .  .  ~  .  d  .  .  .  ~  .  d  . 
Eb      .  ~  .  .  .  .  .  ~  .  .  .  . 
E       .  .  .  .  .  .  .  .  .  .  .  . 
E#      ~  .  d  .  d  .  ~  .  d  .  d  ~ 
Fb      ~  d  .  d  .  d  ~  d  .  d  .  ~ 
F       .  .  .  .  .  .  .  .  .  .  .  . 
F#      .  .  .  .  .  .  .  .  .  .  ~  . 
Gb      .  d  .  d  .  ~  .  d  .  ~  .  . 
G       .  ~  .  ~  .  .  .  ~  .  .  .  . 
G#      .  .  .  .  ~  .  .  .  ~  .  d  . 
Ab      .  d  .  ~  .  .  .  ~  .  .  .  . 
A       .  ~  .  .  .  .  .  .  .  .  .  . 
A#      .  .  ~  .  d  .  ~  .  d  .  d  . 
Bb      .  ~  .  .  .  .  .  .  .  .  .  . 
B       .  .  .  .  .  .  .  .  .  .  .  . 
B#      ~  .  d  .  d  ~  d  .  d  .  d  ~ 

252 questions: 182 right, 40 on another letter, 30 where the textbook needs a double accidental, 0 wrong pitch
```

No pitch is wrong; every error is a letter. Even a unison can change letters: C♭ moved by 0 semitones comes back as B, and E♯ as F, because the closure names the unchanged pitch class from its array. An interval's number counts letters and a semitone count doesn't. A third spans three letters, so C up a minor third is E♭ (C, D, E); a second spans two, so C up an augmented second is D♯ (C, D). Both are 3 semitones, and the closure answers D♯ because C takes the sharp array. The table in the SKILL.md has dropped the number the textbook needs before the closure is called. Only E, F and B come out right on every interval: every interval above E and B is a natural or a sharp, and every one above F a natural or a flat. The `d` cells are intervals whose textbook answer has a double sharp or flat (C♭ up a minor second is D double flat); the arrays can't write those either, and they are counted apart.

## The skill's own examples

`TransposeSkill`'s example prompts, converted as the SKILL.md says:

```text
== Transpose's example prompts, with the arguments its SKILL.md maps them to, one call per chord
prompt                                symbol    semitones  GA           textbook
Transpose Cmaj7 up a perfect fourth   Cmaj7             5  Fmaj7        Fmaj7
Move this F chord down a minor third  F                -3  D            D
What's Dm7 up a whole step?           Dm7               2  Em7          Em7
Transpose G7 to Eb                    G7                8  D#7          Eb7
                                      G7               -4  D#7          Eb7
Shift Am7 up a fifth                  Am7               7  Em7          Em7
transpose C-Am-F-G to G major         C Am F G          7  G Em C D     G Em C D
transpose C-Am-F-G to Eb major        C Am F G          3  D# Cm Ab A#  Eb Cm Ab Bb

Bb up a whole step, then back down: C, then A#
```

"Transpose G7 to Eb" is one of the skill's example prompts, and it gives D♯7 whichever way the model counts, up a minor sixth or down a major third: the closure never sees E♭, only a number. The progression moved to E♭ major comes back as D♯ Cm A♭ A♯, the key spelled two ways in four chords. For a progression, the SKILL.md says to call the skill once per chord or to ask for the chords ([line 95](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/transpose/SKILL.md#L95)), and called once per chord, each call picks its array from its own chord. A B♭ moved up a whole step and back comes back as A♯.

## The symbols passed back in

A conversation can pass a closure's answer back to a closure, so the program checks that both diminished symbols parse:

```text
== The chord symbols the closures return, passed back in
B° up a semitone             Cdim
Bdim up a semitone           Cdim
```

Both do; the difference between the SKILL.md's `B°` and the closure's `Bdim` stops there.

## Common tones

Common-tones' SKILL.md gives two arguments, `chord1` and `chord2`. The program asks for every pair of triads in each of the 30 keys, 21 pairs per key, with the chords spelled as the textbook spells them, and compares the shared notes with the notes the two triads share in the key's scale:

```text
== ga_dsl_eval "domain.commonTones" on every pair of triads in each of the 30 keys
key        misspelled pairs  the key's note as GA writes it
Cb major   9 of 21           Cb as B, Fb as E, Gb as F#
Gb major   6 of 21           Cb as B, Gb as F#
Db major   3 of 21           Gb as F#
D major    3 of 21           C# as Db
A major    6 of 21           C# as Db, G# as Ab
E major    9 of 21           C# as Db, D# as Eb, G# as Ab
B major    11 of 21          A# as Bb, C# as Db, D# as Eb, G# as Ab
F# major   12 of 21          A# as Bb, C# as Db, D# as Eb, E# as F, G# as Ab
C# major   13 of 21          A# as Bb, B# as C, C# as Db, D# as Eb, E# as F, G# as Ab
Ab minor   9 of 21           Cb as B, Fb as E, Gb as F#
Eb minor   6 of 21           Cb as B, Gb as F#
Bb minor   3 of 21           Gb as F#
B minor    3 of 21           C# as Db
F# minor   6 of 21           C# as Db, G# as Ab
C# minor   9 of 21           C# as Db, D# as Eb, G# as Ab
G# minor   11 of 21          A# as Bb, C# as Db, D# as Eb, G# as Ab
D# minor   12 of 21          A# as Bb, C# as Db, D# as Eb, E# as F, G# as Ab
A# minor   13 of 21          A# as Bb, B# as C, C# as Db, D# as Eb, E# as F, G# as Ab

630 pairs: shared notes right 630, spelled as the key spells them 486
```

The shared notes are right in all 630 pairs: the closure intersects pitch classes. It then names each one with `conventionalKeyName` ([lines 263-266](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L263-L266), called at [line 523](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L523)), which knows neither chord:

```fsharp
let private conventionalKeyName pc =
    match pc with
    | 1 | 3 | 8 | 10 -> flatNames.[pc]   // Db, Eb, Ab, Bb — prefer flat
    | _               -> sharpNames.[pc]  // everything else — prefer sharp / natural
```

C♯ is always D♭ and G♯ always A♭, while G♭ is always F♯. Twelve keys have no misspelled pair, six of each mode, the ones whose notes this rule happens to name. D minor is one of them, although `diatonicChords` writes its B♭ as A♯; D major is not, although `diatonicChords` spells it right. Three closures in one file spell the same notes by three rules: by the tonic, by the chord's root, by the pitch class alone.

```text
== Common-tones' SKILL.md example, and a pair from A major
Cmaj7 and Am7
  | Common tones (3):
  |   C (P1 in Cmaj7, m3 in Am7)
  |   E (M3 in Cmaj7, P5 in Am7)
  |   G (P5 in Cmaj7, m7 in Am7)
A and C#m
  | Common tones (2):
  |   Db (M3 in A, P1 in C#m)
  |   E (P5 in A, m3 in C#m)
```

The SKILL.md's example is right. In A major, the root of C♯m comes back as "Db", and the SKILL.md tells the model to surface it verbatim.

## Where GA already spells right

GA's domain spells keys right. In lesson 9, `ScaleInfoSkill` gave the notes of all 30 scales correctly; it takes them from the domain's `Key.Notes` ([`ScaleInfoSkill.cs` line 132](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ScaleInfoSkill.cs#L132)). The closures don't call it; they rebuild spelling from pitch classes, and a pitch class carries no letter.

## Where the course stops

- **The model isn't run.** Whether it calls `ga_dsl_eval`, which arguments it sends and whether it re-spells the answer against its instructions need the model (*to verify*). A model that ignores the SKILL.md could spell better than the closure.
- **Routing isn't tested.** The three skills are reached only through the router's embeddings.
- **Triads only.** The diatonic chords are triads; the common tones are tested on triads, although seventh chords go through the same naming.
- **Transposition is graded against named intervals**, the table's, without the tritone. A user who says "three semitones" names no letter, and any spelling of the result is defensible.
- **`main`'s closures were compared, not run.** The functions this lesson calls are textually identical at the pin and on `main`.

## Reported upstream

- Not reported upstream when this lesson was written: the spelling of `diatonicChords`, `transposeChord` and `commonTones`, and the claims of the diatonic-chords SKILL.md. They are listed in the [journal](../journal/).

## Exercises

1. Rewrite the naming in `diatonicChords` so that each degree gets its own letter. Which of the 11 keys come out right, and what does it return for a key such as G♯ major, whose seventh degree is F double sharp?
2. `transposeChord` takes a number of semitones. What would it need to spell C up a minor third as E♭ and C up an augmented second as D♯, and how would the table in transpose's SKILL.md change?
3. `commonTones` names the shared notes without knowing a key. Which spelling could it use that is right in all 630 pairs of this lesson, still without a key?
4. A user asks "Transpose G7 to Eb". Following the SKILL.md, what does the model send, what does it get back, and what does the chatbot's evidence say about the answer?

<details>
<summary>Solutions</summary>

1. Take the letter from the degree and the accidental from the pitch: for degree `i`, the letter is `i` steps above the tonic's letter, and the accidental is the difference, wrapped to -6..5, between the pattern's pitch class and that letter's natural pitch, as `Spell` does in `Lesson10.cs`. All 11 keys then match the textbook, since the textbook is the same computation. G♯ major's seventh chord is F double sharp diminished; the closure's `accStr` already writes `DoubleSharp` as `##`, so `F##dim`. Not compiled against GA (*to verify*).
2. The interval's number: with a count of letter steps beside the semitones, the result's letter is that many steps above the root's, and the semitones give the accidental. The table would map "minor third" to 2 steps and 3 semitones, and "augmented second" to 1 step and 3 semitones. For "Transpose G7 to Eb", a target root is simpler still: the closure would take E♭'s letter from the user. Not compiled against GA (*to verify*).
3. Chord1's spelling: each shared note named as chord1 spells it, from chord1's root letter and the note's degree in the chord (the third two letter steps up, the fifth four). A key's triads spell their notes as the key does, so chord1's spelling is the key's in every pair of the lesson, and the rule needs no key for chords that belong to none. Worked by hand from the lesson's pairs.
4. `ga_dsl_eval(closureName: "domain.transposeChord", args: { "symbol": "G7", "semitones": "8" })`, or `-4`; the result is `D#7` both ways. Following the SKILL.md's template, "**Cmaj7 up a perfect fourth = Fmaj7** (interval = +5 semitones)", the model would lead with **G7 up a minor sixth = D#7**. Because the model called `ga_dsl_eval`, `SkillMdDrivenWrapperBase` adds `grounding.source: ga.dsl@domain.transposeChord` to the evidence and keeps the model's confidence: the evidence names the closure as the answer's source, as it would for a right answer. Worked from the code; the model's actual call needs the model (*to verify*).

</details>

## Key takeaways

- A skill that tells a model "call this tool, don't compute it yourself" moves correctness into the tool. Calling the tool with the SKILL.md's own arguments tests what an obedient model will say, without the model.
- One name per pitch class can't give one letter per degree. An array indexed by pitch class has one name per pitch class, and a key needs one letter per degree: 11 of 30 keys, 70 of 252 transpositions and 144 of 630 common-tone pairs come out on another letter.
- A semitone count drops the interval's number. Once "minor third" has become 3, E♭ and D♯ can no longer be told apart.
- Three closures in one file spell the same notes by three rules, so D minor's B♭ is A♯ in one and B♭ in another.
- A grounding label says where an answer came from, not whether it is right.

## Sources

- GuitarAlchemist/ga at [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs`, `Common/GA.Business.DSL/Library.fs`, `Common/GA.Business.ML/Agents/Mcp/DslEvalMcpTools.cs`, `Common/GA.Business.ML/Agents/Skills/SkillMdDrivenWrapperBase.cs`, `TransposeSkill.cs`, `DiatonicChordsSkill.cs`, `CommonTonesSkill.cs`, `ScaleInfoSkill.cs`, `skills/transpose/SKILL.md`, `skills/diatonic-chords/SKILL.md`, `skills/common-tones/SKILL.md`, `Common/GA.Business.Core.Orchestration/Extensions/ChatbotOrchestrationExtensions.cs`.
- GA's `main` at [`53b7253`](https://github.com/GuitarAlchemist/ga/commit/53b7253596e71e40c02208a3a85edd25419aeb53), committed on 2026-09-30 UTC: `DomainClosures.fs` and `ChordParser.fs`, for the function-by-function comparison.
- *Open Music Theory*, the fundamentals chapters on intervals, scales and triads, for the textbook's definitions: interval number by letters, quality by semitones, one letter per scale degree.
