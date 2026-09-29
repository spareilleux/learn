---
title: "Lesson 8: The chatbot's own exam"
description: "Guitar Alchemist's prompt corpus, the invariants its chatbot is tested against, run without a model on the course's host, then tested itself: each prompt's checks applied to the answers of the other prompts and to its own answer a semitone higher. Case-insensitive substrings, more than a third of them one letter long, accept an error message, the wrong mode family and an answer about another tuning; a stricter reading of the same strings cuts the accepted foreign answers from 169 to 69."
sidebar:
  label: 8. The chatbot's own exam
  order: 8
---

Lessons 5 to 7 graded the chatbot's answers with oracles the course wrote from textbooks and standards. GA has an oracle of its own. [`prompts.yaml`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Tests/Apps/GaChatbot.Api.Tests/Corpus/prompts.yaml) lists questions a user might ask, each with the strings its answer must contain or must not contain, and [`PromptCorpusTests`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Tests/Apps/GaChatbot.Api.Tests/Corpus/PromptCorpusTests.cs) sends each one to GaChatbot.Api and checks the answer. The test calls itself "the safety net under ongoing skill refactors" and "the oracle for the autonomous improvement loop"; the workflow [`chatbot-qa-snapshot.yml`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/.github/workflows/chatbot-qa-snapshot.yml#L43) runs it every day at 06:00 UTC. This lesson runs the corpus without a model, as the course runs everything, and then tests the test: what does an answer have to get wrong for the gate to notice?

All GA links point to commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), the course's pin. On GA's `main` at [`fc76ad6`](https://github.com/GuitarAlchemist/ga/commit/fc76ad63cb70073330b6868d6e3c39307c5e262c), checked on 2026-09-29, `PromptCorpusTests.cs` and the skills this lesson cites are unchanged; the corpus has grown from 68 prompts to 75, and the entries the lesson quotes are the same. The outputs come from:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l8
```

## The gate

An entry names the question, the intent that must answer it, and the strings:

```yaml
  - prompt: "What notes are in a G7 chord"
    category: chord-tones
    routes_to: skill.chordinfo
    contains: ["G", "B", "D", "F"]
    not_contains: ["Mixolydian", "solo over", "scale has"]
    min_length: 25
    max_elapsed_ms: 20000
    retry: 0
```

`EvaluatePromptAsync` checks them in a fixed order: an empty answer, the degraded-backend markers, the minimum length, eight phrases banned from every answer, then `not_contains`, `contains` and `contains_any`, and last the route, the grounding and the shape of the trace ([lines 313-484](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Tests/Apps/GaChatbot.Api.Tests/Corpus/PromptCorpusTests.cs#L313-L484)). Every string is looked for the same way ([lines 367-379](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Tests/Apps/GaChatbot.Api.Tests/Corpus/PromptCorpusTests.cs#L367-L379)):

```csharp
        if (entry.Contains is not null)
        {
            foreach (var must in entry.Contains)
                if (!answer.Contains(must, StringComparison.OrdinalIgnoreCase))
                    return ($"{label} → missing required substring: \"{must}\"", null);
        }

        if (entry.ContainsAny is not null && entry.ContainsAny.Count > 0)
        {
            var hit = entry.ContainsAny.Any(s => answer.Contains(s, StringComparison.OrdinalIgnoreCase));
            if (!hit)
                return ($"{label} → none of contains_any matched: [{string.Join(", ", entry.ContainsAny)}]", null);
        }
```

A substring, and case doesn't count. GA knows the limit: the comment on the judge test says the substring invariants "stay green even when the chat model is replaced with a bogus one (measured: 50 of 52 still passed)", and the three prompts whose answer is prose carry a rubric for a judge model instead ([lines 204-210](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Tests/Apps/GaChatbot.Api.Tests/Corpus/PromptCorpusTests.cs#L204-L210)). The degraded markers have a history too: for a month the daily snapshot published a pass rate of 7.69% for a chatbot that scored 98.08% with a model, because answers from a backend with no model failed as ordinary mismatches ([lines 54-75](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Tests/Apps/GaChatbot.Api.Tests/Corpus/PromptCorpusTests.cs#L54-L75)). Since then, an answer that contains one of two phrases, "The chatbot can't serve a request right now" or "right now. Please try again.", counts as "no signal" rather than as a failure.

## Without a model

The corpus isn't in the course's sparse checkout, so [`fetch-ga.sh`](https://github.com/spareilleux/learn/blob/main/code/ga-ai/fetch-ga.sh) takes it out of the clone with `git show`, as it does for #749's files in lesson 7. `Lesson8.cs` reads it with YamlDotNet and the same settings as the test, and ports the text checks line for line into `Evaluate`.

Without a model the intent router can't embed a question, and lesson 4 showed where that ends: HTTP 500. So a prompt that names its intent in `routes_to` is sent to that intent directly, through the `IIntent` registered under that id, and the others go to `POST /api/chatbot/chat`. For a direct call, the route, grounding and trace checks don't apply; the text checks do.

Preparing this lesson turned up two gaps in the course's own host:

- **GA's `skills/` folder was missing.** [`SkillMdPlugin.ResolveSkillsPath`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Plugins/SkillMdPlugin.cs#L113-L151) looks for it at the root of the git repository that holds the running program. Walking up from the course program, the first `.git` it meets is the course's repository, not the clone. The course now fetches `skills/` and points `SKILLMD_SKILLS_PATH` at the clone's copy; the method accepts that override only inside the repository it found, and the clone sits inside the course's repository. The outputs of lessons 1 to 7 are the same with this change.
- **A key in the environment would have been used.** The skills that follow a SKILL.md call Anthropic's API whenever a key is found, in the configuration or in `ANTHROPIC_API_KEY` ([`AnthropicProvider.cs` lines 113-114](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Providers.Anthropic/AnthropicProvider.cs#L113-L114)). Run with a fake key, this lesson's host sent the request and got `AnthropicUnauthorizedException`. The course host now sets `Anthropic:ApiKey` to an empty string, which the provider reads first.

```text
== GA's prompt corpus at a826864 (Tests/Apps/GaChatbot.Api.Tests/Corpus/prompts.yaml)
prompts 68, skipped 5, with a judge rubric 3, naming the intent that must answer 39
expected strings 224, of one character 84

== Each prompt without a model, checked as PromptCorpusTests checks it
#   prompt                                         answered by                verdict
1   What are the modes of the major scale          skill.modes                pass
2   What are the modes of melodic minor            skill.modes                pass
3   What are the modes of harmonic minor           skill.modes                pass
4   What is Lydian dominant                        skill.modes                pass
5   Phrygian dominant                              skill.modes                pass
6   Tell me about Hijaz                            skill.modes                pass
7   What are the byzantine modes                   skill.modes                pass
8   Show me the notes in C major                   chat: HTTP 500
9   What is the relative minor of G major          chat: HTTP 500
10  What are the diatonic chords in G major        skill.diatonicchords       too short (65 < 100 chars)
11  What are the diatonic chords in D major        skill.diatonicchords       too short (65 < 100 chars)
12  Explain the circle of fifths                   chat: HTTP 500
13  What is the difference between major and min…  chat: HTTP 500
14  why does F sound outside over Cmaj7            skill.outsidenotes         pass
15  is A a tension or a chord tone over Cmaj7      skill.outsidenotes         pass
16  Transpose C E G to D                           chat: HTTP 500
17  What are the common tones between Cmaj7 and …  chat: HTTP 500
18  Are 0146 and 0137 z-related                    chat: algebra              pass
19  Identify the key of Am F C G                   chat: HTTP 500
20  Suggest substitutions for G7 in a ii-V-I       chat: HTTP 500
21  give me a ii-V-I progression in Bb             skill.diatonicchords       missing "Cm"
22  ii-V-I in Bb                                   skill.diatonicchords       missing "Cm"
23  Show me some easy beginner chords              chat: HTTP 500
24  List atonal modal families                     skill.modes                pass
25  What is the interval class vector of C E G     chat: HTTP 500
26  modes of melodi minor                          skill.modes                pass
27  diatnic chords in G major                      chat: HTTP 500
28  What is dorian                                 skill.modes                pass
29  tell me about phrygian                         skill.modes                pass
30  notes in c major                               skill.scaleinfo            pass
31  DIATONIC CHORDS IN G MAJOR                     skill.diatonicchords       pass
32  What is the relative major of A minor          chat: HTTP 500
33  What is the parallel minor of C major          chat: HTTP 500
34  Diatonic chords in F major                     skill.diatonicchords       too short (65 < 80 chars)
35  Diatonic chords in A minor                     skill.diatonicchords       too short (65 < 80 chars)
36  What is the altered scale                      skill.modes                pass
37  What is Hungarian minor                        skill.modes                pass
38  What is the whole tone scale                   skill.modes                pass
39  What is the diminished scale                   skill.modes                pass
40  What is Locrian                                skill.modes                pass
41  What is Mixolydian                             skill.modes                pass
42  What is Forte number 4-Z29                     chat: algebra              pass
43  List symmetric atonal families                 chat: HTTP 500
44  Transpose C major to E                         chat: HTTP 500
45  Common tones between G7 and Dm7                chat: HTTP 500
46  What key is Cm Ab Eb Bb in                     chat: HTTP 500
47  Show me a Cmaj9 chord                          skill.chordinfo            pass
48  What is C7b9                                   skill.chordinfo            pass
49  which arpeggio fits Am F C G                   skill.improvisation        pass
50  what arpeggios work over Dm7 G7 Cmaj7          skill.improvisation        pass
51  How do I tune to drop C                        skill.alternatetunings     pass
52  Give me a Cadd9 in DADGAD                      skipped
53  What's the easiest A minor in drop-D           skipped
54  Transpose this progression to capo 3           skipped
55  What's the smoothest voice leading from Cmaj…  skipped
56  What chord is C E G                            skill.chordinfo            pass
57  What chord is F A C E                          skill.chordinfo            pass
58  What chord is C E G Bb D                       skill.chordinfo            pass
59  What chord is D F A C E                        skill.chordinfo            pass
60  Transpose A minor to C minor                   chat: HTTP 500
61  Are pitch classes 0,1,4 and 0,1,6 equivalent…  chat: HTTP 500
62  What notes are in a G7 chord                   skill.chordinfo            pass
63  Explain why a tritone substitution works       chat: HTTP 500
64  What is the difference between a major seven…  chat: HTTP 500
65  Why does the Lydian mode sound brighter than…  chat: HTTP 500
66  What is the relative minor of E-flat major     skipped
67  What notes are in a C major triad              skill.chordinfo            pass
68  which notes form a B minor triad               skill.chordinfo            pass

68 prompts: 5 skipped, 22 end in an HTTP error, 41 answered: 35 pass, 6 fail, 0 of them flagged as a degraded backend
```

The 22 HTTP errors are lesson 4's failure: no `routes_to`, no guard that catches the question, and a fallback that needs the model. The algebra guard answers two, #18 and #42, without a model. Of the 39 prompts sent to an intent, the seven sent to `DiatonicChordsSkill` are the only ones that need a model: they account for the six failures and for one of the passes.

## A skill that needs a model

`DiatonicChordsSkill` is what GA calls a Path B skill: a model reads [`skills/diatonic-chords/SKILL.md`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/diatonic-chords/SKILL.md) and is expected to compute the chords by calling the tool `ga_dsl_eval` with the closure `domain.diatonicChords`. Its chat client always comes from Anthropic, whatever model the rest of the chatbot uses ([`DefaultChatClientFactory.cs` lines 45-49](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Extensions/DefaultChatClientFactory.cs#L45-L49)). Without a key, creating the client throws:

```text
== #10 What are the diatonic chords in G major: the intent's answer and the skills' log lines
  | I encountered an error processing your request. Please try again.
Error SkillMdDrivenSkill: SkillMdDrivenSkill [diatonic-chords] failed — tools=15, message head="What are the diatonic chords in G major" (InvalidOperationException)
Warning DiatonicChordsSkill: DiatonicChordsSkill: LLM produced an answer without invoking ga_dsl_eval. Closure domain.diatonicChords should have been called. Evidence: (no exception)
```

Two layers handle the failure, and they disagree about what happened:

- The inner [`SkillMdDrivenSkill`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/SkillMdDrivenSkill.cs#L204-L226) catches the exception, logs it, and returns "I encountered an error processing your request. Please try again." with confidence 0.
- The wrapper, [`SkillMdDrivenWrapperBase`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/SkillMdDrivenWrapperBase.cs#L98-L152), receives that text as a normal answer. It finds no call to `ga_dsl_eval` in the evidence and logs that the model "produced an answer" without the tool; no model was reached. Its own degraded text, "I couldn't list the diatonic chords for that key right now. Please try again.", comes from its catch block, which runs when building the inner skill fails or when the inner skill throws ([lines 154-176](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/SkillMdDrivenWrapperBase.cs#L154-L176)); here the inner skill returned normally.

That wrapper text is the one GA's degraded marker was written for: the comment on `BackendDegradedMarkers` names it as a source. The inner text isn't a marker, so the gate scores the seven prompts as six failures and one pass instead of seven times "no signal". Before the course fetched `skills/`, building the inner skill failed on the missing SKILL.md, the wrapper's catch block returned its own text, and all seven were flagged as degraded; with the file in place, the detector misses them. GA's daily workflow provides an Ollama endpoint and no Anthropic key, so its runs should take the same path for these prompts (*to verify*: the snapshots of 2026-09-25 to 2026-09-29 are all marked degraded, and none lists its failures by prompt).

## What a pass proves

GA's comment says what the invariants don't see: quality. The course measures how much they do see, with two tests of the gate itself:

- **Other answers.** Each prompt that passes gets its invariants applied to the 31 other distinct answers of the run. An answer to another question isn't always wrong for this one, but an invariant that accepts many of them says little about its own.
- **A semitone higher.** When the prompt names a note or a chord, its answer is checked again with every note name and chord root moved up a semitone: `Cmaj7` becomes `C#maj7`, `Bb` becomes `B`. The result is an answer about another pitch, wrong for the question asked. For a prompt that names no pitch, like "What is Dorian", the moved answer would still be right, and the column says n/a. The course recognizes a note name in the question only when it starts with a capital letter, because "a" is also an English word: #30, "notes in c major", names C major in lowercase and gets n/a, a miss of the course's test.

```text
== GA's invariants applied to the other answers, and to the same answer a semitone higher
#   prompt                                     other answers pass         a semitone higher
1   What are the modes of the major scale      0 of 31                    n/a
2   What are the modes of melodic minor        0 of 31                    n/a
3   What are the modes of harmonic minor       0 of 31                    n/a
4   What is Lydian dominant                    1 of 31 (#1)               n/a
5   Phrygian dominant                          1 of 31 (#3)               n/a
6   Tell me about Hijaz                        1 of 31 (#3)               n/a
7   What are the byzantine modes               1 of 31 (#37)              n/a
14  why does F sound outside over Cmaj7        0 of 31                    pass
15  is A a tension or a chord tone over Cmaj7  3 of 31 (#49, #50, #51)    pass
18  Are 0146 and 0137 z-related                0 of 31                    n/a
24  List atonal modal families                 0 of 31                    n/a
26  modes of melodi minor                      5 of 31 (#2, #3, #4, …)    n/a
28  What is dorian                             4 of 31 (#1, #2, #3, …)    n/a
29  tell me about phrygian                     3 of 31 (#1, #3, #5)       n/a
30  notes in c major                           21 of 31 (#1, #2, #3, …)   n/a
31  DIATONIC CHORDS IN G MAJOR                 21 of 31 (#1, #2, #3, …)   pass
36  What is the altered scale                  1 of 31 (#2)               n/a
37  What is Hungarian minor                    0 of 31                    n/a
38  What is the whole tone scale               1 of 31 (#24)              n/a
39  What is the diminished scale               1 of 31 (#24)              n/a
40  What is Locrian                            3 of 31 (#1, #2, #3)       n/a
41  What is Mixolydian                         3 of 31 (#1, #2, #50)      n/a
42  What is Forte number 4-Z29                 1 of 31 (#18)              n/a
47  Show me a Cmaj9 chord                      23 of 31 (#1, #2, #3, …)   missing "E"
48  What is C7b9                               8 of 31 (#1, #2, #3, …)    missing "E"
49  which arpeggio fits Am F C G               5 of 31 (#1, #2, #3, …)    pass
50  what arpeggios work over Dm7 G7 Cmaj7      6 of 31 (#1, #2, #3, …)    pass
51  How do I tune to drop C                    1 of 31 (#14)              pass
56  What chord is C E G                        7 of 31 (#1, #2, #3, …)    missing "C major"
57  What chord is F A C E                      0 of 31                    missing "F major 7"
58  What chord is C E G Bb D                   0 of 31                    missing "C dominant 9"
59  What chord is D F A C E                    0 of 31                    missing "D minor 9"
62  What notes are in a G7 chord               17 of 31 (#3, #4, #5, …)   missing "B"
67  What notes are in a C major triad          24 of 31 (#1, #2, #3, …)   missing "E"
68  which notes form a B minor triad           7 of 31 (#1, #2, #3, …)    missing "B"

35 passing prompts; other answers accepted: 169; accepted a semitone higher: 6 of 15 that name a pitch
```

Some acceptances are fair. Hijaz, a maqam of Arabic music, is usually approximated in twelve-tone equal temperament by the scale Western books call Phrygian dominant, and the harmonic minor family, answer #3, lists it. Most are not. "What notes are in a C major triad" accepts 24 of the 31 other answers, and "What notes are in a G7 chord" 17, because their `contains` lists are note letters, and a case-insensitive `"E"` is in "the", `"D"` in "and", `"F"` in "of". 84 of the corpus's 224 expected strings are one character long, 81 of them note letters.

The semitone column says the same from the other side. The answers of #56 to #59 fail because their invariants hold a chord name, from "C major" to "D minor 9". The others fail by luck of spelling: moved up, the G7 answer reads "G# dominant 7 chord contains G#, C, D#, and F#", and it fails only because no word of it holds a `b`. And #51 passes:

```text
== #51 How do I tune to drop C, the answer a semitone higher: GA pass, strict missing "C"
  | **Drop C# tuning** (low → high): **C# – G# – C# – F# – A# – D#**
  |
  | | String | Note | vs Standard |
```

`"C"` is in `C#`, and `"Drop C"` is in `Drop C#`. Four more pass a semitone higher because their invariants name no pitch at all: "avoid" and "11" for #14, a tension or a 13 for #15, and "Aeolian" or "arpeggio" for the two arpeggio prompts. The error message of #31 has no note to move.

## Answers the gate accepts

Five of the answers that passed, with the string that let each one through. The first three are wrong answers. The last two list the right notes with a wrong formula, and the gate reads only the scale's name.

```text
== #26 modes of melodi minor: pass
  | The **Major Scale** family has 7 modes:
  |
  | 1. **Ionian** — on C: `C D E F G A B` — characteristic: `2`, `3`, `6`, `7`
  | 2. **Dorian** — on C: `C D Eb F G A Bb` — characteristic: `2`, `b3`, `6`, `b7`
  | 3. **Phrygian** — on C: `C Db Eb F G Ab Bb` — characteristic: `b2`, `b3`, `b6`, `b7`
  | 4. **Lydian** — on C: `C D E F# G A B` — characteristic: `#4`, `2`, `3`, `6`, `7`
  | … 5 more lines
"Melodic Minor" matches "melodic minor" on line 11
```

The prompt sits in the corpus's `typo-tolerance` category, under the comment "Real users misspell. The router should still get them home." `ModesSkill` doesn't recognize "melodi minor", so it takes its default branch and lists the major scale's modes, without saying that it didn't recognize the family ([`ModesSkill.cs` lines 202-207](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ModesSkill.cs#L202-L207)). Every family answer ends with the same suggestion, "Ask about a specific family ("modes of melodic minor", "harmonic major modes") or a single mode ("what is Lydian dominant?")" ([line 449](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ModesSkill.cs#L449)), and the entry's `contains_any` is satisfied by that line ([`prompts.yaml` lines 270-276](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Tests/Apps/GaChatbot.Api.Tests/Corpus/prompts.yaml#L270-L276)).

```text
== #31 DIATONIC CHORDS IN G MAJOR: pass
  | I encountered an error processing your request. Please try again.
"G" matches "processing" on line 1
```

The error text of the section "A skill that needs a model", accepted as the diatonic chords of G major ([lines 316-322](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Tests/Apps/GaChatbot.Api.Tests/Corpus/prompts.yaml#L316-L322)).

```text
== #49 which arpeggio fits Am F C G: pass
  | Over **Am – F – C – G**, for each chord:
  |
  | - **Am** → arpeggio **Am**, play **A Aeolian (natural minor)** (diatonic minor — fits most i chords).
  | - **F** → arpeggio **F**, play **F Ionian (major)** (diatonic, includes the 7 — careful on the IV chord).
  | - **C** → arpeggio **C**, play **C Ionian (major)** (diatonic, includes the 7 — careful on the IV chord).
  | - **G** → arpeggio **G**, play **G Ionian (major)** (diatonic, includes the 7 — careful on the IV chord).
  | … 2 more lines
"Aeolian" matches "Aeolian" on line 3
```

The key-blind answer of [lesson 5](../05-improvisation-skill/) and GA issue [#744](https://github.com/GuitarAlchemist/ga/issues/744): F Ionian holds a B♭ and G Ionian an F♯, and neither note is in the progression's key, A minor or C major. The entry would also accept "arpeggio", a word of the question. On `main`, the corpus has since gained an entry for "which arpeggio fits C A Dm G" with `not_contains: ["A Aeolian"]`, written after the tracer run of 2026-09-28 behind #744: a string that a wrong answer contains is a sharper check than a string a right one should.

```text
== #38 What is the whole tone scale: pass
  | **Whole Tone** is mode 1 of the **Whole Tone** family; on C its notes are `C D E F# G# Bb` (formula `1 2 3 #4 #5 #6`).
"Whole Tone" matches "Whole Tone" on line 1

== #39 What is the diminished scale: pass
  | **Diminished (Half-Whole)** is mode 1 of the **Diminished** family; on C its notes are `C Db Eb E F# G A Bb` (formula `1 b2 b3 b4 b5 bb6 bb7 bb8`).
"Diminished" matches "Diminished" on line 1
```

Nothing checks whether the formula agrees with the notes; exercise 4 does.

## A stricter reading

The same strings can be read more strictly, without changing the corpus. `StrictContains` in [`Lesson8.cs`](https://github.com/spareilleux/learn/blob/main/code/ga-ai/GaAi/Lesson8.cs) applies two rules: a string that starts with a note name, such as `G`, `F#`, `Bb`, `Cm` or `C major`, must match with the same case; and every string must stand alone, with no letter, digit or accidental against either end, so `"C"` no longer matches `C#` or `Cmaj7`, and `"G"` no longer matches "processing".

```csharp
static bool StrictContains(string answer, string s)
{
    var comparison = NoteToken.IsMatch(s.Split(' ')[0]) ? StringComparison.Ordinal : StringComparison.OrdinalIgnoreCase;
    for (var i = answer.IndexOf(s, comparison); i >= 0; i = answer.IndexOf(s, i + 1, comparison))
    {
        var end = i + s.Length;
        if ((i == 0 || !IsTokenChar(answer[i - 1])) && (end == answer.Length || !IsTokenChar(answer[end])))
            return true;
    }
    return false;
}
```

```text
== The same invariants, read strictly: each prompt's own answer
#31 DIATONIC CHORDS IN G MAJOR: GA pass, strict none of contains_any

== The strict reading applied to the other answers, and to the same answer a semitone higher
#   prompt                                     other answers pass         a semitone higher
1   What are the modes of the major scale      0 of 31                    n/a
2   What are the modes of melodic minor        0 of 31                    n/a
3   What are the modes of harmonic minor       0 of 31                    n/a
4   What is Lydian dominant                    1 of 31 (#1)               n/a
5   Phrygian dominant                          1 of 31 (#3)               n/a
6   Tell me about Hijaz                        1 of 31 (#3)               n/a
7   What are the byzantine modes               1 of 31 (#37)              n/a
14  why does F sound outside over Cmaj7        0 of 31                    pass
15  is A a tension or a chord tone over Cmaj7  1 of 31 (#51)              pass
18  Are 0146 and 0137 z-related                0 of 31                    n/a
24  List atonal modal families                 0 of 31                    n/a
26  modes of melodi minor                      5 of 31 (#2, #3, #4, …)    n/a
28  What is dorian                             4 of 31 (#1, #2, #3, …)    n/a
29  tell me about phrygian                     3 of 31 (#1, #3, #5)       n/a
30  notes in c major                           3 of 31 (#1, #2, #3)       n/a
36  What is the altered scale                  1 of 31 (#2)               n/a
37  What is Hungarian minor                    0 of 31                    n/a
38  What is the whole tone scale               1 of 31 (#24)              n/a
39  What is the diminished scale               1 of 31 (#24)              n/a
40  What is Locrian                            3 of 31 (#1, #2, #3)       n/a
41  What is Mixolydian                         3 of 31 (#1, #2, #50)      n/a
42  What is Forte number 4-Z29                 1 of 31 (#18)              n/a
47  Show me a Cmaj9 chord                      4 of 31 (#1, #2, #3, …)    missing "E"
48  What is C7b9                               5 of 31 (#1, #2, #3, …)    missing "C"
49  which arpeggio fits Am F C G               5 of 31 (#1, #2, #3, …)    pass
50  what arpeggios work over Dm7 G7 Cmaj7      6 of 31 (#1, #2, #3, …)    pass
51  How do I tune to drop C                    0 of 31                    missing "C"
56  What chord is C E G                        2 of 31 (#30, #47)         missing "C major"
57  What chord is F A C E                      0 of 31                    missing "F major 7"
58  What chord is C E G Bb D                   0 of 31                    missing "C dominant 9"
59  What chord is D F A C E                    0 of 31                    missing "D minor 9"
62  What notes are in a G7 chord               1 of 31 (#3)               missing "G"
67  What notes are in a C major triad          12 of 31 (#1, #2, #3, …)   missing "C"
68  which notes form a B minor triad           4 of 31 (#1, #2, #3, …)    missing "B"

34 passing prompts; other answers accepted: 69; accepted a semitone higher: 4 of 14 that name a pitch
```

The strict reading changes one verdict on the run's own answers, the error message of #31, and that change is right. The foreign answers it accepts drop from 169 to 69, and #51 moved up a semitone now fails for the right reason: no `C` stands alone in it. The G7 prompt accepts one answer instead of 17: the harmonic minor family, whose notes include G, B, D and F.

What it can't do is read what the invariants don't name. #14, #15, #49 and #50 still pass a semitone higher, and #26 still accepts the wrong family, because their strings hold no pitch that a wrong answer lacks. #67 still accepts 12 answers: C, E and G stand alone in any list of C major's notes. An invariant that checks a chord's notes has to compare sets, "the answer names exactly C, E and G", which substring checks can't express. And a strict reading has false failures of its own: "tension" no longer matches "tensions". None occurred in this run, which is a fact about 41 answers, not a guarantee.

## Where the course stops

- **Routing isn't tested.** The course calls each intent directly, so `routes_to`, `routing_method`, grounding and the trace checks, the half of the gate that catches misroutes, aren't exercised. Neither are the 22 prompts that need the router or a model, the three judged ones among them.
- **The semitone test is one kind of wrong answer.** It leaves the words alone and moves the pitches; it says nothing about an answer that names the right notes and draws the wrong conclusion.
- **"Other answers" measures how specific an invariant is, not whether an answer is right.** An accepted foreign answer can be acceptable, as for Hijaz.
- **The strict reading is the course's proposal**, measured on this run only. Adopting it would mean one change in `EvaluatePromptAsync` and a review of the corpus's 224 strings.

## Reported upstream

- Not reported upstream when this lesson was written: the degraded detector that misses a Path B skill's error, the wrapper's misleading log line, the typo that gets the major scale silently, the positional formulas of #38 and #39, and the case-insensitive substrings. They are listed in the [journal](../journal/).

## Exercises

1. Add "I encountered an error processing your request" to `BackendDegradedMarkers` in the course's port. What does the summary line of the first table print, and what happens to #31?
2. Rewrite the invariants of #26 so that the major-scale answer fails and the melodic minor family, answer #2, passes. Which other answers does your version accept?
3. #61 asks "Are pitch classes 0,1,4 and 0,1,6 equivalent under inversion". Answer it, then say which strings of its `contains_any`, `["yes", "no", "Z", "equivalent", "inversion", "transposition", "different", "same", "related"]`, a wrong answer would satisfy.
4. Check the formulas of #38 and #39 against their notes, letter by letter. Which degrees disagree, and what formula spells each scale's notes as written? Read [`ComputeFormulaFromNotes`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ModesSkill.cs#L779-L811) and say why it goes wrong on these two scales.

<details>
<summary>Solutions</summary>

1. `68 prompts: 5 skipped, 22 end in an HTTP error, 41 answered: 34 pass, 7 fail, 7 of them flagged as a degraded backend`. The seven diatonic prompts, #31 included, become `BACKEND_DEGRADED`, and the run reports no signal for them instead of six failures and one pass. Checked with the course program on 2026-09-29, by adding the marker for one run.
2. `contains: ["Melodic Minor", "Lydian Dominant", "Altered"]`, the strings of #2, all required. The suggestion line names the first two but not the altered scale, so the major-scale answer fails with `missing "Altered"`, and #2's answer passes. Of the other answers of the run, only #2 passes. Checked with the course program on 2026-09-29, by replacing the entry for one run. A strict reading wouldn't help here: the suggestion line holds "melodic minor" as whole words.
3. No. The inversion of {0,1,4} is {0,11,8}, which transposes to {0,3,4}; neither it nor {0,1,4} is a transposition of {0,1,6}. The two sets are different set classes, 3-3 (014) and 3-5 (016) in Forte's list, with interval-class vectors <101100> and <100011>. A wrong answer, "Yes, they are equivalent", satisfies "yes" and "equivalent", and "no" is in "not", "note" and "know", so any answer that reaches the entry's `min_length`, 50 characters, is likely to pass. Worked by hand: the prompt ends in HTTP 500 without a model, so the course has no answer to check.
4. #38: `#6` is A♯, and the note is B♭; the notes as written spell `1 2 3 #4 #5 b7`. #39: `b4` is F♭ where the note is E, `b5` G♭ where it is F♯, `bb6` A𝄫 where it is G, `bb7` B𝄫 where it is A, and `bb8`, which isn't a degree anyone writes, C𝄫 where it is B♭. The pitch classes all agree; the letters don't. The notes as written spell `1 b2 b3 3 #4 5 6 b7`; jazz texts usually write the E♭ as D♯, `1 b2 #2 3 #4 5 6 b7`, the formula lesson 5's oracle uses. `ComputeFormulaFromNotes` compares the i-th note with the i-th degree of C major, by position: that works for a seven-note scale spelled on seven letters, and gives the wrong degree numbers to a scale of six or eight notes. Deriving each degree from the note's letter would give the formulas above. Worked by hand from the output and the method's code; not compiled against GA (*to verify*).

</details>

## Key takeaways

- A test suite is itself a claim about the program, and it can be tested: apply its checks to answers they weren't written for, and to answers that are wrong on purpose, and count what passes.
- GA's corpus checks case-insensitive substrings. More than a third of its expected strings are one character long, most of them note letters, which most English sentences contain; its invariants accepted 169 foreign answers, an error message and the wrong mode family.
- An answer about another pitch passes when the invariants hold no pitch, or hold one as a substring of another: "C" is in "C#".
- Graceful degradation has to be recognized by the gate. A Path B skill without a model answers with a text GA's degraded markers don't know, so its failures are scored as the chatbot's.
- Reading the same strings as whole tokens, with note names case-sensitive, cuts the foreign acceptances to 69 without changing a correct verdict here. What substrings can't express, such as "exactly these notes", needs a check that parses the answer.

## Sources

- GuitarAlchemist/ga at [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `Tests/Apps/GaChatbot.Api.Tests/Corpus/prompts.yaml`, `Tests/Apps/GaChatbot.Api.Tests/Corpus/PromptCorpusTests.cs`, `.github/workflows/chatbot-qa-snapshot.yml`, `Common/GA.Business.ML/Agents/Skills/ModesSkill.cs`, `SkillMdDrivenSkill.cs`, `SkillMdDrivenWrapperBase.cs`, `DiatonicChordsSkill.cs`, `Common/GA.Business.ML/Agents/Plugins/SkillMdPlugin.cs`, `Common/GA.Business.ML/Extensions/DefaultChatClientFactory.cs`, `Common/GA.Providers.Anthropic/AnthropicProvider.cs`.
- GA's `main` at [`fc76ad6`](https://github.com/GuitarAlchemist/ga/commit/fc76ad63cb70073330b6868d6e3c39307c5e262c) (2026-09-29): the corpus's new entries, among them "which arpeggio fits C A Dm G", added in [`503d70d`](https://github.com/GuitarAlchemist/ga/commit/503d70d3bed961e71fa82c35dd35066a301040d5); the snapshot `state/quality/chatbot-qa/2026-09-29.json`.
- Allen Forte, *The Structure of Atonal Music* (Yale University Press, 1973), for the set-class names of exercise 3.
