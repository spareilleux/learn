---
title: "Lesson 28: Comparing major and minor"
description: "Guitar Alchemist's TheoryComparisonSkill answers one question, the difference between major and minor, with a fixed text whose scales are a textbook's. Its regexes read all 7 of its example prompts but 5 of the course's 20 phrasings, its same-pair answer suggests a comparison it refuses, the parallel keys it leaves to RelativeKeySkill get that skill's refusal, and without embeddings GA's main sends none of its examples to it."
sidebar:
  label: 28. Comparing major and minor
  order: 28
---

GA's chatbot answers "What is the difference between major and minor" with `TheoryComparisonSkill`. It was built on 2026-05-16 because that corpus prompt went to `RelativeKeySkill`, got its 0.1-confidence text, then timed out waiting for Ollama ([`TheoryComparisonSkill.cs` lines 12-18](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/TheoryComparisonSkill.cs#L12-L18)). It answers without a model, and only one pair: its remarks call its scope "major vs minor (the broken prompt)" ([lines 20-25](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/TheoryComparisonSkill.cs#L20-L25)). This lesson asks which phrasings it reads, checks its answer against a textbook, and asks GA's `main` what its chatbot does with the skill's own examples when nothing can embed them.

All GA links point to commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), the course's pin. On GA's `main` at [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/commit/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) (2026-10-01), `TheoryComparisonSkill.cs` only marks its refusal `Declined`, and `RelativeKeySkill.cs` the same, with a new `CanHandle` described below, so `GaAi` asks the skills at the pin, and `GaMain` asks `main`'s chatbot host, started as in [lesson 25](../25-what-reaches-the-transpose-skill/). The output comes from:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l28
dotnet run --project code/ga-ai/GaMain -c Release -- l28
```

## How the skill reads a question

`CanHandle` always says no, so only the router's embeddings can pick the skill. `ExecuteAsync` tries four regexes in turn, each looking for two of the words `major` and `minor`:

```csharp
    public bool CanHandle(string message) => false;  // semantic-routing only

    // Match "difference between X and Y", "compare X and Y", "X vs Y",
    // "X versus Y", "how do X and Y differ", "X and Y difference".
    // Quality tokens are kept narrow so unrelated comparisons
    // ("C major vs F major", "Hendrix vs Clapton") do not route here.
    private const string QualityTokens = "major|minor";

    private static readonly Regex DifferencePattern =
        new(@"\b(?:what(?:'s|\s+is)?\s+the\s+)?(?:difference|distinction)\s+between\s+(?<a>" + QualityTokens + @")\s+and\s+(?<b>" + QualityTokens + @")\b",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);

    private static readonly Regex ComparePattern =
        new(@"\bcompare\s+(?<a>" + QualityTokens + @")\s+(?:and|with|vs|versus)\s+(?<b>" + QualityTokens + @")\b",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);

    private static readonly Regex VsPattern =
        // Negative lookbehind keeps "C major vs C minor" out — that's a
        // parallel-key question handled by RelativeKeySkill. Bare
        // "major vs minor" with no preceding key letter falls through.
        new(@"(?<![A-Ga-g][b#♭♯]?\s)\b(?<a>" + QualityTokens + @")\s+(?:vs\.?|versus)\s+(?<b>" + QualityTokens + @")\b",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);

    private static readonly Regex HowDifferPattern =
        new(@"\bhow\s+do\s+(?<a>" + QualityTokens + @")\s+and\s+(?<b>" + QualityTokens + @")\s+differ\b",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);
```

Two different words get the comparison, with `major` put first; the same word twice gets a short answer of its own; no match gets an empty refusal ([lines 77-111](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/TheoryComparisonSkill.cs#L77-L111), [lines 151-165](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/TheoryComparisonSkill.cs#L151-L165)).

## The phrasings it answers

The program asks the skill its 7 example prompts and 20 phrasings of the course's, and names the first regex that matches:

```text
== TheoryComparisonSkill: the regex that finds the pair in each phrasing, and the answer
source   phrasing                                                   regex              answer
example  What is the difference between major and minor             DifferencePattern  answer
example  Compare major and minor                                    ComparePattern     answer
example  Major vs minor                                             VsPattern          answer
example  Major versus minor                                         VsPattern          answer
example  Difference between major and minor scales                  DifferencePattern  answer
example  Explain the difference between major and minor             DifferencePattern  answer
example  How do major and minor differ                              HowDifferPattern   answer
course   Minor vs major                                             VsPattern          answer
course   Major vs. minor                                            VsPattern          answer
course   Compare minor with major                                   ComparePattern     answer
course   What is the difference between minor and major             DifferencePattern  answer
course   What's the difference between major and minor keys         DifferencePattern  answer
course   Major and minor difference                                 none               refused
course   How are major and minor different                          none               refused
course   Major or minor: what's the difference?                     none               refused
course   Majors vs minors                                           none               refused
course   What is the difference between the major and minor scales  none               refused
course   Difference between a major and a minor chord               none               refused
course   Explain the major vs minor difference                      none               refused
course   Which sounds sadder, a major vs minor chord?               none               refused
course   C major vs C minor                                         none               refused
course   What's the difference between C major and C minor          none               refused
course   Major vs major                                             VsPattern          same pair
course   Major vs dorian                                            none               refused
course   Dorian vs Aeolian                                          none               refused
course   Harmonic minor vs melodic minor                            none               refused
course   Major pentatonic vs minor pentatonic                       none               refused
example prompts 7: answer 7; the course's 20: answer 5, same pair 1, refused 14; CanHandle accepts 0
```

- **All 7 example prompts get the answer, and 5 of the course's 20 phrasings.** The pair can come in either order, and "vs." and "Compare … with" are read.
- **A word more and the question is lost.** Nothing may stand between "between" and the first word, or between the words and "and": "the major and minor scales" and "a major and a minor chord" are refused. So are "Majors vs minors", where an "s" comes before the space the regexes want, and "How are major and minor different". The comment above the regexes counts "X and Y difference" among the shapes they match, but none of them has it: "Major and minor difference" is refused.
- **`VsPattern`'s lookbehind keeps out more than keys.** It refuses a word preceded by a letter from A to G, an optional accidental and a space, to leave "C major vs C minor" to another skill. With the case ignored, the "e" of "the" and the article "a" are such letters: "Explain the major vs minor difference" and "Which sounds sadder, a major vs minor chord?" are refused.
- **Nothing else is compared.** "Dorian vs Aeolian", "Harmonic minor vs melodic minor" and "Major pentatonic vs minor pentatonic" are refused, as the remarks' scope says.

## The answer against a textbook

```text
== TheoryComparisonSkill's answer to "What is the difference between major and minor"
  | Major and minor differ primarily in the **third scale degree**, with secondary differences at the 6th and 7th depending on the minor form.
  | 
  | **Scale formulas (semitones from root):**
  | - Major:   2 2 1 2 2 2 1 — degrees `1 2 3 4 5 6 7` (major third = 4 semitones)
  | - Minor:   2 1 2 2 1 2 2 — degrees `1 2 b3 4 5 b6 b7` (minor third = 3 semitones, natural minor)
  | 
  | The single interval that flips is the **third**: a major third (4 semitones) versus a minor third (3 semitones). That one-semitone shift changes the entire harmonic and emotional character of the key — chords built on the same root come out major or minor accordingly.
  | 
  | **Common associations:** major sounds bright and stable (often "happy"); minor sounds darker and more ambiguous (often "sad" but really just emotionally richer). These are cultural shorthand, not absolutes.
  | 
  | **Minor variants:**
  | - Natural minor: `1 2 b3 4 5 b6 b7`
  | - Harmonic minor: `1 2 b3 4 5 b6 7` — raised 7th for stronger dominant resolution
  | - Melodic minor: `1 2 b3 4 5 6 7` ascending (raised 6th and 7th), natural minor descending
  | 
  | **In context:**
  | - Relative pairs share a key signature (C major ↔ A minor, G major ↔ E minor)
  | - Parallel pairs share a root but flip quality (C major ↔ C minor)
  | - Diatonic chords differ: I IV V (major-quality) vs i iv V (minor with raised 7th in V)
```

The program reads the scales back out of the answer and compares them with a textbook's, then checks the relative pairs and the triads it names:

```text
== The scales in the answer, against a textbook: the degrees it writes, the degrees its steps give, and a textbook's
scale            the answer writes  its steps give     a textbook         the same  degrees not major's
Major            1 2 3 4 5 6 7      1 2 3 4 5 6 7      1 2 3 4 5 6 7      yes       none
Minor            1 2 b3 4 5 b6 b7   1 2 b3 4 5 b6 b7   1 2 b3 4 5 b6 b7   yes       3 6 7
Natural minor    1 2 b3 4 5 b6 b7   -                  1 2 b3 4 5 b6 b7   yes       3 6 7
Harmonic minor   1 2 b3 4 5 b6 7    -                  1 2 b3 4 5 b6 7    yes       3 6
Melodic minor    1 2 b3 4 5 6 7     -                  1 2 b3 4 5 6 7     yes       3
relative pairs: C major ↔ A minor: the same notes yes; G major ↔ E minor: the same notes yes
triads on degrees 1, 4 and 5: major: major, major, major; natural minor: minor, minor, minor; harmonic minor: minor, minor, major
```

- **Every scale in the answer is a textbook's,** from its steps as from its degrees, and so are its relative pairs and the qualities of I, IV and V.
- **"The single interval that flips is the third" holds for the melodic minor only.** The natural minor, the one the answer writes first, differs from major at the 3rd, 6th and 7th, and the harmonic minor at the 3rd and 6th. The answer's first sentence says so, "secondary differences at the 6th and 7th", and the sentence after the formulas says the opposite.

## The same pair twice

```text
== The same pair twice: the answer, the comparison it suggests, and the skill's answer to that
question         suggests             answer to the suggestion
Major vs major   major vs dorian      refused
Minor vs minor   minor vs dorian      refused
  | You asked to compare major to itself — there's no difference. Try comparing major to its opposite (major↔minor) or to a specific mode (e.g. "major vs dorian").
```

- **"Major vs major" gets a suggestion the skill refuses:** "major vs dorian", and "minor vs dorian" for minor. Its regexes know only `major` and `minor` ([line 56](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/TheoryComparisonSkill.cs#L56)).

## The parallel keys

`VsPattern`'s comment says "C major vs C minor" is "a parallel-key question handled by RelativeKeySkill" ([lines 67-69](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/TheoryComparisonSkill.cs#L67-L69)). `RelativeKeySkill` reads "relative" or "parallel" followed by "minor of" or "major of", and key signatures ([`RelativeKeySkill.cs` lines 52-70](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/RelativeKeySkill.cs#L52-L70)):

```text
== RelativeKeySkill, which VsPattern's comment says handles "C major vs C minor": confidence and the first line of the answer
question                                             confidence   answer
C major vs C minor                                   0.100        Ask about the relative or parallel key of a given major/minor key, or how many sharps/flats a key has.
What's the difference between C major and C minor    0.100        Ask about the relative or parallel key of a given major/minor key, or how many sharps/flats a key has.
Parallel minor of C major                            1.000        The parallel minor of **C major** is **C minor**.
```

- **Neither skill answers "C major vs C minor".** `RelativeKeySkill` gives its refusal with a confidence of 0.1, and answers the question only as "Parallel minor of C major".

## Without embeddings, on main

The router reaches the skill only through embeddings. GA's own routing diagnostic of 2026-06-16 ranks it the best separated of its 30 intents, its seven examples being seven phrasings of one question, and puts "Major versus minor" closest to `RelativeKeySkill`'s "Relative major of A minor" ([`routing-ambiguity-2026-06-16.md` lines 53 and 93](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/state/quality/routing-diagnostic/routing-ambiguity-2026-06-16.md?plain=1#L53-L93)). The course has no model to compute them. Without one, the pinned chatbot answered every question of [lesson 25](../25-what-reaches-the-transpose-skill/) with HTTP 500; `main`'s router asks each intent whether it matches without embeddings, then its agent router falls back on keywords. The program asks `main`'s host the 7 example prompts and three of the course's phrasings:

```text
== Without embeddings: the intent SemanticIntentRouter picks for the example prompts and three of the course's phrasings, and what POST /api/chatbot/chat answers (on main)
phrasing                                                   router picks             chat: agent (routing method)                  first line of the answer
What is the difference between major and minor             none                     voicing (keyword)                             Found 10 voicings matching mode major + tags [wha…
Compare major and minor                                    none                     voicing (keyword)                             Found 10 voicings matching mode major + tags [min…
Major vs minor                                             none                     voicing (keyword)                             Found 10 voicings matching mode Major + tags [min…
Major versus minor                                         none                     voicing (keyword)                             Found 10 voicings matching mode Major + tags [min…
Difference between major and minor scales                  none                     fallback-direct (error-fallback-unavailable)  Our reasoning service is currently unavailable, s…
Explain the difference between major and minor             none                     voicing (keyword)                             Found 10 voicings matching mode major + tags [the…
How do major and minor differ                              none                     voicing (keyword)                             Found 10 voicings matching mode major + tags [min…
Minor vs major                                             none                     voicing (keyword)                             Found 10 voicings matching mode Minor + tags [maj…
Difference between a major and a minor chord               skill.chordinfo          skill.chordinfo (orchestrator-skill-semantic) A minor chord contains A, C, and E.
C major vs C minor                                         none                     voicing (keyword)                             Found 10 voicings matching chord C + mode major +…
10 phrasings; the router picks none 9, skill.chordinfo 1; the chat endpoint answers with voicing (keyword) 8, fallback-direct (error-fallback-unavailable) 1, skill.chordinfo (orchestrator-skill-semantic) 1
```

- **None of the 7 example prompts reaches the skill.** 6 get a search for voicings, by "major" or "minor" as a mode and by other words of the question as tags; one gets the fallback, "Our reasoning service is currently unavailable".
- **"Difference between a major and a minor chord" gets "A minor chord contains A, C, and E."** `ChordInfoSkill` accepts it and reads the article "a" as a root, as [lesson 15](../15-the-notes-of-a-chord/) found, reported as [#782](https://github.com/GuitarAlchemist/ga/issues/782).
- **`main` gave another skill the fix.** `RelativeKeySkill`'s `CanHandle` now accepts exactly the phrasings its regexes read: "this predicate only serves the offline keyword fallback" ([lines 50-63 on `main`](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Agents/Skills/RelativeKeySkill.cs#L50-L63)). `TheoryComparisonSkill`'s is still `false`.

## Where the course stops

- **No router with embeddings runs.** Which phrasings the deployed chatbot sends to the skill depends on its embeddings.
- **The answer's "Common associations" paragraph isn't checked.** It says itself that they are "cultural shorthand, not absolutes".
- **On `main`, the program asks 10 questions, not 27,** to keep its run short.

## Reported upstream

- Reported after this lesson was written, in GA issue [#815](https://github.com/GuitarAlchemist/ga/issues/815): the phrasings the regexes refuse, the lookbehind that refuses "the major vs minor", the questions the skill hands on to a refusal, the sentence that says only the third flips, and the example prompts `main` never sends to the skill without embeddings.

## Exercises

1. Why is "Explain the major vs minor difference" refused, when "Major vs minor" gets the answer?
2. What change to `DifferencePattern` would let "What is the difference between the major and minor scales" through? Which other refused phrasing would it let through?
3. For which minor does "the single interval that flips is the third" hold?
4. Why does `RelativeKeySkill` refuse "C major vs C minor", when it answers "Parallel minor of C major"?

<details>
<summary>Solutions</summary>

1. `VsPattern` refuses "major" when a letter from A to G and a space come before it, and with the case ignored, the "e" of "the" is such a letter. "Major vs minor" starts the question, so nothing comes before "Major". `DifferencePattern` doesn't match either: the question has no "between".
2. An optional article before each word, `(?:the\s+|a\s+)?`, after "between" and after "and". It would also let "Difference between a major and a minor chord" through, to an answer about scales. Worked from the code: the program doesn't run the changed regex.
3. The melodic minor, ascending: it differs from major at the 3rd only. The natural and harmonic minors differ at the 6th too, and the natural minor at the 7th.
4. Its patterns need "relative" or "parallel" followed by "minor of" or "major of", or a key-signature question. "C major vs C minor" has none of these, so it gets the refusal.

</details>

## Key takeaways

- Seven examples written one way prove one phrasing: a fixed answer is only as reachable as the regexes in front of it.
- A comment that hands a question to another component is a claim to test: the skill it names refuses it.
- An answer that suggests a follow-up question should be able to answer it.
- A sentence must agree with the table under it.
- A skill that only embeddings can reach goes silent whenever the embeddings are down.

## Sources

- GuitarAlchemist/ga at [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `Common/GA.Business.ML/Agents/Skills/TheoryComparisonSkill.cs`, `Common/GA.Business.ML/Agents/Skills/RelativeKeySkill.cs`, `state/quality/routing-diagnostic/routing-ambiguity-2026-06-16.md`.
- GuitarAlchemist/ga at [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/tree/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a): the chatbot host `GaMain` starts.
- The course's programs: `code/ga-ai/GaAi/Lesson28.cs`, `code/ga-ai/GaMain/Program.cs`, `code/ga-ai/Shared/ComparisonProbe.cs`.
