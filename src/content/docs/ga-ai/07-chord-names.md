---
title: "Lesson 7: Chord names the chatbot can't read"
description: "Improvisation requests with invalid chord names, valid ones, and both, sent to Guitar Alchemist's improvisation skill at the course's pin and to the version of pull request #749, which declines requests that name only invalid chords — compiled next to the pin with an extern alias, and graded by a small recognizer of chord symbols. The guard works; lowercase names, bad qualities, flat signs, a bare sharp root, C+ and Bø7 still get through or get misread."
sidebar:
  label: 7. Chord names it can't read
  order: 7
---

On 2026-09-28 a tracer run asked the public chatbot "which arpeggio fits Hm Q7". Neither Hm nor Q7 is a chord in English notation, and the answer should have said so. It said: "The note Hm Q7 (also known as H) is a perfect 4th above the note Q.To create an arpeggio based on this note, you'll need to find a chord that includes H and its neighboring notes. …" That became GA issue [#745](https://github.com/GuitarAlchemist/ga/issues/745), and the same day pull request [#749](https://github.com/GuitarAlchemist/ga/pull/749) added a guard that declines such requests. This lesson runs that guard, and the improvisation skill of lesson 5 before and after it, on sixteen requests, and grades what they do with a small recognizer of chord symbols. The question is wider than #745's: which chord names can the chatbot read at all?

All GA links point to commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), the course's pin, except those to #749's files, which point to its merge commit [`d7efd41`](https://github.com/GuitarAlchemist/ga/commit/d7efd4142908542d469e0b1a9e6dd3dceba8ecc5). The three files the lesson compiles are unchanged on GA's `main` at [`f4f4d30`](https://github.com/GuitarAlchemist/ga/commit/f4f4d30465b39be7ec36aba3742c218782cf9127), checked on 2026-09-28. The outputs come from:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l7
```

## How Hm Q7 reached the model

#749's description traces two paths from that message to the language model, both through GA's fallback:

1. **Nothing matches.** The semantic intent router of lesson 4 scores the message below its threshold for every intent, the agent router finds nothing better, and the answer comes from the direct model call. That's the path the tracer recorded: routing `fallback-direct`, method `low-confidence-fallback`.
2. **The skill matches, and its answer is replaced.** If the router does pick the improvisation skill, the skill finds no chord symbol, hands the message to its extractor, which calls a model, and ends on its no-chord answer, "I couldn't find a chord name in your request…", with confidence 0.2. [`OrchestratedChatApplicationService`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/GaChatbot.Api/Services/OrchestratedChatApplicationService.cs#L17) replaces any answer below `Chatbot:FallbackMinConfidence`, 0.25, with the model's.

A model with no guard answers anything. Offline, the course sees the first step of the second path: at the pin, the skill hands "which arpeggio fits Hm Q7" to its extractor, and the course's extractor stops the run there, as in lessons 5 and 6.

#749 adds [`InvalidChordNames`](https://github.com/GuitarAlchemist/ga/blob/d7efd4142908542d469e0b1a9e6dd3dceba8ecc5/Common/GA.Business.ML/Agents/Skills/InvalidChordNames.cs). Its `Find` returns the tokens shaped like chord symbols whose root letter is outside A–G, but only when the message asks an improvisation question and names no valid chord. The orchestrator calls it after semantic dispatch and before the agent router, in both its answer paths ([`ProductionOrchestrator.cs` lines 828-840](https://github.com/GuitarAlchemist/ga/blob/d7efd4142908542d469e0b1a9e6dd3dceba8ecc5/Common/GA.Business.Core.Orchestration/Services/ProductionOrchestrator.cs#L828-L840), called at lines 259 and 550), and the skill calls it before its extractor. Either way, the decline has confidence 0.9, above the fallback's threshold, so it is the answer.

## Compiling a fix next to the pin

The course builds against GA at `a826864`, and moving the pin would change every lesson's output. So the program compiles only #749's three files, `InvalidChordNames.cs`, `ImprovisationSkill.cs` and `ChordIntentMatching.cs`, taken from the merge commit, into a small project of its own that references the pinned `GA.Business.ML`. [`fetch-ga.sh`](https://github.com/spareilleux/learn/blob/main/code/ga-ai/fetch-ga.sh) takes them out of the blobless clone with `git show`, so the course's repository holds no copy of GA's code:

```xml
<ItemGroup>
  <Compile Include="../.ga-fix/*.cs" />
  <!-- The global usings the three files were written against, from the pinned project -->
  <Compile Include="$(GaRoot)Common/GA.Business.ML/GlobalUsings.cs" Link="GlobalUsings.cs" />
</ItemGroup>
```

The project now defines `GA.Business.ML.Agents.Skills.ImprovisationSkill` itself, and so does the assembly it references. Inside the project, the compiler uses its own definition and says so with warning [CS0436](https://learn.microsoft.com/dotnet/csharp/language-reference/compiler-messages/using-directive-errors#cs0436), which the project silences on purpose. The course program references both assemblies, so it has two types with the same full name. It gives the new one an [extern alias](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/extern-alias), through the `Aliases` metadata of its [project reference](https://learn.microsoft.com/visualstudio/msbuild/common-msbuild-project-items#projectreference):

```xml
<ProjectReference Include="../GaFix749/GaFix749.csproj" Aliases="fix749" />
```

`Lesson7.cs` starts with `extern alias fix749;` and names the fixed namespace `Fixed` with a [using alias](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/using-directive), `using Fixed = fix749::GA.Business.ML.Agents.Skills;`. Without an alias, the names resolve to the pinned assembly, as everywhere else in the course:

```csharp
var pinned = new ImprovisationSkill(NullLogger<ImprovisationSkill>.Instance, new NoExtractor());
var fixedSkill = new Fixed.ImprovisationSkill(NullLogger<Fixed.ImprovisationSkill>.Instance, new NoExtractor());
```

The three files call the rest of `GA.Business.ML` as it is at the pin, not as it is at #749's merge commit. That is enough here because #749 changed nothing else in that project; its other changes are in the orchestrator and in tests. Had the fix needed a new type elsewhere, the build would fail and say so.

## A recognizer of chord symbols

To grade the answers, the program needs to know which words of a message are chord symbols. `Read` in [`Lesson7.cs`](https://github.com/spareilleux/learn/blob/main/code/ga-ai/GaAi/Lesson7.cs) follows the convention of lead sheets: an uppercase root from A to G, an optional accidental, a quality from a list, an optional bass note after a slash. A word shaped like one but broken, with a root outside A–G, a lowercase root or a quality outside the list, is "not a chord symbol". A word that isn't shaped like one at all, "fits", "mode", "I", is text:

```csharp
static readonly Regex Symbol = new(@"^(?<letter>[A-Za-z])(?<accidental>[#b♯♭]?)(?<quality>[^/]*)(?:/(?<bass>[A-G][#b♯♭]?))?$");

// Roman numerals of harmony: "V7", "ii", "IV". A single "I" is left out: it is the pronoun
static readonly Regex Roman = new(@"^(?=.{2})(?:VII|VI|V|IV|III|II|I|vii|vi|v|iv|iii|ii|i)(?:7|°|ø)?$");
```

```text
== What each message holds, read as chord symbols are written
#   message                            chords       not chord symbols
1   which arpeggio fits Hm Q7          -            Hm (root H), Q7 (root Q)
2   which arpeggio fits X7alt          -            X7alt (root X)
3   Q7, which arpeggio should I use?   -            Q7 (root Q)
4   which arpeggio fits H7             -            H7 (root H)
5   which arpeggio fits hm q7          -            hm (lowercase root), q7 (lowercase root)
6   which arpeggio fits Cq7            -            Cq7 (quality q7)
7   which arpeggio fits Am F C G       Am F C G     -
8   which arpeggio fits Bb Eb F        Bb Eb F      -
9   which arpeggio fits B♭ E♭ F        Bb Eb F      -
10  which arpeggio fits B F# G#m E     B F# G#m E   -
11  which arpeggio fits C C+ F         C C+ F       -
12  which arpeggio fits Bø7 E7 Am      Bø7 E7 Am    -
13  which arpeggio fits Am F Q7 G      Am F G       Q7 (root Q)
14  which arpeggio fits C and Q7       C            Q7 (root Q)
15  Hm, which mode is brightest?       -            Hm (root H)
16  which arpeggio fits V7             -            V7 (Roman numeral)
```

B♭ and Bb are the same chord, so the recognizer writes both with ASCII accidentals. The grading rule follows #745's acceptance criteria: a message that holds a word that isn't a chord symbol should be declined, or at least the answer should name that word; a message with two chords or more should be answered chord by chord, for exactly those chords. The rest, a single chord or none, takes the skill's model path and isn't graded here.

## What GA does with them

```text
== What GA does with them
#   skill at a826864       #749 guard   #749 skill             verdict (#749)
1   needs the model        Hm Q7        declines               same
2   needs the model        X7alt        declines               same
3   needs the model        Q7           declines               same
4   needs the model        H7           declines               same
5   needs the model        -            needs the model        DIFF reaches the model
6   needs the model        -            needs the model        DIFF reaches the model
7   answers Am F C G       -            answers Am F C G       same
8   answers Bb Eb F        -            answers Bb Eb F        same
9   answers B E F          -            answers B E F          DIFF reads Bb as B, Eb as E
10  answers B F G#m E      -            answers B F G#m E      DIFF reads F# as F
11  answers C C F          -            answers C C F          DIFF reads C+ as C
12  answers E7 Am          -            answers E7 Am          DIFF drops Bø7 without a word
13  answers Am F G         -            answers Am F G         DIFF drops Q7 without a word
14  needs the model        -            needs the model        DIFF reaches the model
15  needs the model        -            needs the model        DIFF reaches the model
16  needs the model        -            needs the model        n/a
```

"needs the model" means the skill handed the message to its extractor; in the live chatbot, a model answers from there, or the fallback does. The "#749 guard" column is `InvalidChordNames.Find`, the call the orchestrator makes.

**Rows 1 to 4: the guard does its job.** Each message that names only chords with a root outside A–G is declined, including the one that opens with the chord (`Q7, which arpeggio…`). At the pin, all four went to the model.

**Rows 5, 6 and 14: the guard doesn't fire, and the message goes on to the model.** The guard's regular expression is case-sensitive and looks for roots from H to Z, so `hm q7` doesn't match. `Cq7` has a valid root and an unknown quality, which #749 lists as out of scope. `C and Q7` names a valid chord, `C`, so the guard stays silent by design: a request that mixes valid and invalid chords "keeps its route". For all three, what the user reads depends on a model that has already invented theory about invalid tokens.

**Rows 9 to 12: valid chords, read wrong.** No model is involved and nothing is declined: the skill answers, for other chords.

- `B♭ E♭ F` is answered as B, E and F: a B major arpeggio and B Ionian for B♭. Every symbol in the skill's expressions allows `[#b]` after the root, not `♭` or `♯` ([lines 447-462](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L447-L462)). GA's capo and alternate-tuning skills accept both signs.
- `F#` is read as F, in plain ASCII. The run comes from `ChordTokenRegex`, which ends with `\b`, a [word boundary](https://learn.microsoft.com/dotnet/standard/base-types/anchors-in-regular-expressions#word-boundary-b): a place between a [word character](https://learn.microsoft.com/dotnet/standard/base-types/character-classes-in-regular-expressions#word-character-w) and a character that isn't one, or the start or end of the text. After `F#` comes a space, and neither `#` nor a space is a word character, so there is no boundary there. The engine backtracks, drops the optional `#`, and finds a boundary between `F` and `#`. `G#m` survives because it ends on `m`; `Bb` because `b` is a letter.
- `C+` is read as C for the same reason: `+` is one of the qualities the expression lists, but a `+` followed by a space leaves no boundary.
- `Bø7` disappears from the run: `ø` is a letter, so no boundary separates it from the `7`, and the list has `°7` but no `ø7`. The skill answers for E7 and Am and says nothing about the first chord.

The decline of rows 1 to 4 tells the user that a chord name is a root "optionally followed by # or b". Row 10 shows that the skill can't read the simplest one of those, a major chord on a sharp root.

**Row 13: an invalid chord dropped in silence.** `Am F Q7 G` gets an answer for Am, F and G. Lesson 5 found the same silence for chords the skill can't parse, `C7sus4` and `CmMaj7`.

## The decline

```text
== #749's skill on "which arpeggio fits Hm Q7"
confidence 0.9
  | I don't recognize "Hm" and "Q7" as chord names, so I can't suggest arpeggios or scales for them. A chord name starts with a root letter from A to G, optionally followed by # or b, then the chord quality: for example 'Bm', 'G7' or 'Cmaj7'. In German notation H is B: "Hm" is written "Bm" here. Name the chords again and I'll give the arpeggio and scales for each.
assumption: Not chord names (root outside A-G): Hm, Q7.
```

The answer names the tokens, says what a chord name looks like, and asks again, with no theory about the tokens. Its last touch is musical: in German notation, and in the Nordic countries, H is B natural and B is B♭, so "Hm" is a real chord, B minor. The hint is right, and it comes for any token that starts with H. For `H7` the answer reads "In German notation H is B: "H7" is written "B7" here."

## Where the recognizer stops

- **Row 15 is the recognizer's mistake, not GA's.** "Hm, which mode is brightest?" opens with an interjection. The recognizer reads `Hm` as a broken chord symbol; GA's guard skips an interjection that opens a message and is followed by a comma, which is the right reading. The question itself, which mode sounds brightest, is one for a model, and going there is correct.
- **Roman numerals are not graded.** `V7` names a chord only in a key, and the message gives none. GA's guard leaves Roman numerals out on purpose; what the answer should be, a question back about the key, isn't checked here.
- **The list of qualities is finite.** A valid symbol that isn't in it, `C13#11` for example, would be called broken. The list covers the chords of lessons 5 and 7, no more.
- **One notation.** The recognizer knows the English letters, uppercase. German H and B, solfège (`Do`, `Ré`) and lowercase chord names, common in quick typing, are all "not chord symbols" to it, which is the course's choice, not a fact about music.

## Reported upstream

- Invalid chord names reaching the model: GA issue [#745](https://github.com/GuitarAlchemist/ga/issues/745), fixed by pull request [#749](https://github.com/GuitarAlchemist/ga/pull/749), merged on 2026-09-28. Rows 1 to 4 are that fix.
- Rows 5, 6, 9 to 12 and 13, the lowercase names, the unknown quality, the flat signs, the bare sharp root, `C+`, `Bø7` and the silent drop: reported after this lesson was written, the misread and dropped symbols as GA issue [#757](https://github.com/GuitarAlchemist/ga/issues/757) and the requests the guard lets through as [#759](https://github.com/GuitarAlchemist/ga/issues/759). They are listed in the [journal](../journal/).

## Exercises

1. Without running anything, predict what the skill answers for "which arpeggio fits F♯ C♯m". Which of the two chords keeps its quality?
2. Change the skill so that rows 9 to 12 read their chords. What is the smallest change to `ChordTokenRegex`, and what else is needed?
3. Why would it be hard to extend the guard to lowercase tokens? Name three words that a lowercase rule would have to leave alone.
4. What should the answer to row 13, "which arpeggio fits Am F Q7 G", say? Where in the skill would you put it?

<details>
<summary>Solutions</summary>

1. The skill answers for F and C: both roots lose their sharp, because `♯` isn't in the expressions, and `C♯m` also loses its minor quality, since the match stops at `C`. Neither chord keeps its quality as written. Checked with the course program on 2026-09-28, by adding the message to `Messages` for one run.
2. Three changes. Replace `♭` with `b` and `♯` with `#` in the message before the skill reads it. End `ChordTokenRegex` with the lookahead `(?![\w#+°ø-])` instead of `\b`, so that a symbol may end on `#`, `+` or `°` but not in the middle of a word. Add `ø7` before `ø` in the list of qualities. With those three edits made to #749's `ImprovisationSkill.cs` for one run, rows 9 to 12 read `same`, and rows 1 to 8 and 13 to 16 don't change; checked with the course program on 2026-09-28. `InferQuality` already classifies a symbol containing `ø` as half-diminished and one starting with `+` after its root as augmented ([lines 309-353](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L309-L353)).
3. Lowercase letters are also words. A rule that treats a lowercase letter plus a suffix as a chord name would catch `am` (as in "I am"), `hm` and `mm` (interjections), and `a` before a number. The guard would need the context the uppercase rule gets for free: a run of several tokens, or a position after "fits" or "over".
4. It should answer for Am, F and G and name Q7, for example "I don't recognize "Q7" as a chord name; here are the other three." The skill already has what it needs: `InvalidChordNames` finds the token, but only returns it when no valid chord is named. A variant that returns the invalid tokens in any case, called from the progression path, could add one sentence to the answer. Not compiled against GA (*to verify*).

</details>

## Key takeaways

- A chatbot with a model behind it answers any message, so what can't be answered has to be declined before the model sees it. #749 does that for improvisation requests that name only chords with a root outside A–G, with a confidence above the fallback's threshold.
- A fix that isn't in the pinned commit can still be run: compile its files next to the pinned assembly, and reach the duplicate type through an extern alias.
- The guard misses lowercase names, unknown qualities on a valid root, and requests that mix valid and invalid chords; those still reach the model or lose a chord in silence.
- Valid chords are misread without a model: flat and sharp signs, a bare sharp root in ASCII, `C+` and `Bø7`. The cause is the character set of the skill's expressions and the final `\b`, which can't follow `#`, `+` or `°`.
- The recognizer is wrong on the interjection row, where GA is right: an oracle has to say where it stops.

## Sources

- GuitarAlchemist/ga at [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs`, `Apps/GaChatbot.Api/Services/OrchestratedChatApplicationService.cs`.
- GA pull request [#749](https://github.com/GuitarAlchemist/ga/pull/749), merged on 2026-09-28 as [`d7efd41`](https://github.com/GuitarAlchemist/ga/commit/d7efd4142908542d469e0b1a9e6dd3dceba8ecc5): `InvalidChordNames.cs`, `ImprovisationSkill.cs`, `ChordIntentMatching.cs`, `ProductionOrchestrator.cs`, and its description; GA issue [#745](https://github.com/GuitarAlchemist/ga/issues/745), with the tracer's answer.
- Microsoft Learn: [extern alias](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/extern-alias), [CS0436](https://learn.microsoft.com/dotnet/csharp/language-reference/compiler-messages/using-directive-errors#cs0436), [the `using` directive](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/using-directive), [common MSBuild project items](https://learn.microsoft.com/visualstudio/msbuild/common-msbuild-project-items#projectreference), [anchors](https://learn.microsoft.com/dotnet/standard/base-types/anchors-in-regular-expressions#word-boundary-b) and [character classes](https://learn.microsoft.com/dotnet/standard/base-types/character-classes-in-regular-expressions#word-character-w) in .NET regular expressions.
