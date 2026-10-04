---
title: "Lesson 25: What reaches the transpose skill"
description: "Before Guitar Alchemist's TransposeSkill can call its closure, the chatbot has to send it the question. Its routing hint misses 3 of the skill's own 13 example prompts and fires on 10 example prompts of other skills, and its CanHandle always says no, so without embeddings GA's main can never pick it: the pin answers 26 transposition questions with HTTP 500, main answers 16 of them with a voicing search."
sidebar:
  label: 25. What reaches transpose
  order: 25
---

[Lesson 10](../10-what-the-model-is-told-to-trust/) called the closure that `TransposeSkill` tells a model to use, with the arguments its SKILL.md prescribes. This lesson asks about the step before: which questions reach the skill. The chatbot's intent router scores each skill by its best match among its description and example prompts, adds +0.06 for each routing hint whose pattern matches, and routes only when the best score reaches `MinConfidence` ([`SemanticIntentRouter.cs` lines 129-257](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Intents/SemanticIntentRouter.cs#L129-L257)). The course has no model to compute the embeddings, so it runs the two parts that need none: the hints, and what the chatbot does with a transposition when nothing can embed it.

All GA links point to commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), the course's pin, unless they name another. On GA's `main` at [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/commit/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) (2026-10-01), `TransposeSkill`, its SKILL.md, the hint rules, `SkillMdPlugin` and the skill registrations are unchanged, but both routers changed for a question they can't embed: the intent router asks each intent whether it matches without embeddings, and the agent router falls back on its keywords instead of throwing. Both came from GA pull requests [#686](https://github.com/GuitarAlchemist/ga/pull/686) and [#688](https://github.com/GuitarAlchemist/ga/pull/688), which fixed findings of this course and of music-theory-ga. `GaMain` now starts `main`'s chatbot host the way `GaAi` starts the pinned one, with the same closed Ollama port, no API key, and lesson 3's index built with `main`'s code. The output comes from:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l25
dotnet run --project code/ga-ai/GaMain -c Release -- l25
```

## How a question reaches the skill

`DefaultRoutingHintProvider` has one rule for transposition: a word that starts with "transpos", or "shift", "bring" or "move" followed, one to six words later, by "up", "down", or "to" and a capital letter:

```csharp
        (new Regex(@"\btranspos\w+\b|\b(shift|bring|move)\b\s+\S+(?:\s+\S+){0,5}?\s+(?:up|down|to\s+(?-i:[A-G]))\b",
            RegexOptions.IgnoreCase | RegexOptions.Compiled),
            "skill.transpose"),
```

`TransposeSkill` hands the question to a model, and the class it derives from answers no to every `CanHandle`:

```csharp
    /// <inheritdoc />
    /// <remarks>
    /// Tool-driven skills only route via the <see cref="Intents.SemanticIntentRouter"/>;
    /// the legacy <c>CanHandle</c> regex shadow is intentionally disabled.
    /// </remarks>
    public bool CanHandle(string message) => false;
```

On `main`, when the question can't be embedded, the intent router gives it to the first intent, in registration order, that matches it without embeddings. For a skill's intent, that is the skill's `CanHandle` ([`OrchestratorSkillIntent.cs` line 29](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.Core.Orchestration/Intents/OrchestratorSkillIntent.cs#L29)):

```csharp
    // Offline degradation: when the embedding backend cannot score the query, the
    // first intent (registration order) whose high-precision keyword predicate
    // matches claims it at the threshold confidence, so deterministic skills still
    // answer without Ollama. Returns null when none matches (LLM path as before).
    private IntentMatch? KeywordFallback(string query, IReadOnlyList<IIntent> intents)
    {
        foreach (var intent in intents)
        {
            if (!intent.MatchesWithoutEmbeddings(query)) continue;

            logger.LogInformation(
                "SemanticIntentRouter: embeddings unavailable; keyword fallback picked {IntentId} for query={Query}",
                intent.Id,
                SanitizeForLog(query));

            return new IntentMatch(intent, MinConfidence, KeywordFallbackSource)
            {
                Ranking = [new RoutingCandidate(intent.Id, MinConfidence, 0f, MinConfidence, KeywordFallbackSource)],
            };
        }

        return null;
    }
```

## The hints a transposition gets

The program asks `DefaultRoutingHintProvider` about 26 phrasings: the skill's 13 example prompts, the one phrasing of its SKILL.md that isn't among them ([line 80](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/transpose/SKILL.md#L80)), the four transposition prompts of GA's corpus, and eight of the course's. It also looks for the SKILL.md's triggers in each one, as lowercase substrings, the way `SkillMdDrivenSkill.CanHandle` does ([`SkillMdDrivenSkill.cs` lines 54-65](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/SkillMdDrivenSkill.cs#L54-L65)):

```text
== Transpose phrasings: the intents whose routing hint fires, and the triggers of transpose's SKILL.md they contain (at the pin)
source   phrasing                                     hints, +0.06 each                        SKILL.md triggers
example  transpose this progression down a half step  skill.transpose                          transpose, down a
example  transpose this progression up a whole step   skill.transpose                          transpose, up a
example  transpose C-Am-F-G to G major                skill.transpose                          transpose
example  shift this progression up a half step        skill.transpose                          up a
example  bring D minor down to A minor                skill.transpose                          none
example  Transpose Cmaj7 up a perfect fourth          skill.interval, skill.transpose          transpose, up a
example  Move this F chord down a minor third         skill.interval, skill.transpose          down a
example  What's Dm7 up a whole step?                  none                                     up a
example  Transpose G7 to Eb                           skill.transpose                          transpose
example  Shift Am7 up a fifth                         skill.transpose                          up a
example  raise the key by two semitones               none                                     none
example  lower the key by a half step                 none                                     none
example  transposing the chorus down a tone           skill.transpose                          down a
SKILL.md Cmaj7 in the key of G                        none                                     in the key of
corpus   Transpose C E G to D                         skill.transpose                          transpose
corpus   Transpose C major to E                       skill.transpose                          transpose
corpus   Transpose this progression to capo 3         skill.capo, skill.transpose              transpose
corpus   Transpose A minor to C minor                 skill.transpose                          transpose
course   Transpose Dm7 down a half step               skill.transpose                          transpose, down a
course   Move Am up two frets                         skill.transpose                          none
course   Shift the song to the key of E               none                                     none
course   Put Cmaj7 in the key of A                    none                                     in the key of
course   Raise Bb7 by a minor third                   skill.interval                           none
course   Lower G by a tritone                         skill.interval                           none
course   Play this song a whole step down             skill.alternatetunings                   none
course   Take F#m up a fourth                         none                                     up a
26 phrasings: the transpose hint fires on 16; another intent's hint on 6, 3 of them without the transpose hint; no hint on 7; a SKILL.md trigger in 18
```

- **The transpose hint misses 3 of the skill's 13 example prompts.** "What's Dm7 up a whole step?", "raise the key by two semitones" and "lower the key by a half step" have none of its verbs, and neither has the SKILL.md's "Cmaj7 in the key of G". The course's "Shift the song to the key of E" has the verb, but ends on "of E", not "to E".
- **Two example prompts boost `skill.interval` as much as `skill.transpose`.** "Transpose Cmaj7 up a perfect fourth" and "Move this F chord down a minor third" name an interval, which the interval rule reads ([lines 74-76](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Intents/DefaultRoutingHintProvider.cs#L74-L76)); with +0.06 on both intents, the hints leave the gap between them where the embeddings put it. "Raise Bb7 by a minor third" and "Lower G by a tritone" boost `skill.interval` alone, and "Play this song a whole step down" boosts `skill.alternatetunings` alone, whose rule takes "whole step down" for a tuning ([lines 159-161](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Intents/DefaultRoutingHintProvider.cs#L159-L161)).

On `main`, the table is the same.

## What the hint and the triggers also claim

The program asks the same of every other intent's example prompts:

```text
== The other intents' example prompts that the transpose hint or transpose's SKILL.md triggers claim (at the pin)
intent                     example prompt                                             hint  SKILL.md triggers
skill.chordinfo            what notes make up a G7 chord                              no    up a
skill.modes                What are modes of limited transposition                    yes   none
skill.progressionmood      Brighten up a minor key tune                               no    up a
skill.diatonicchords       All chords in the key of D                                 no    in the key of
skill.settheoryequivalence Are pitch class sets 0,1,3 and 0,2,3 equivalent under tr…  yes   none
skill.settheoryequivalence Are pitch classes 0,2,4 and 1,3,5 transpositionally equi…  yes   none
skill.voiceleading         best way to move from G7 to C                              yes   none
skill.grothendieckdelta    harmonic cost to move from C to G                          yes   none
skill.grothendieckparse    what does Transpose(C ⊗ G) mean                            yes   transpose
skill.grothendieckparse    parse Transpose ∘ Invert                                   yes   transpose
skill.grothendieckparse    parse pullback(Cmaj7, Transpose, Gmaj7)                    yes   transpose
skill.grothendieckparse    parse functor Transpose: Chords -> Chords                  yes   transpose
skill.grothendieckparse    parse equalizer Transpose Invert                           yes   transpose
407 example prompts of 34 other intents: the transpose hint fires on 10, a SKILL.md trigger is in 8
```

- **The transpose hint fires on 10 example prompts of other intents.** "transposition" and "transpositionally" in two set-theory prompts and in "What are modes of limited transposition"; "Transpose", a functor's name, in five of the parse skill's; and "move from G7 to C" and "move from C to G", where "to" and a capital letter end the phrase. Lessons [23](../23-harmonic-distance-and-path/) and [24](../24-set-classes-and-the-grothendieck-parser/) printed some of them in their hint columns.
- **The triggers are substrings.** "up a" is in "what notes make up a G7 chord" and in "Brighten up a minor key tune", and "in the key of" in "All chords in the key of D".

On `main`, the same 13 rows come out of 412 example prompts of 35 intents.

## The skills behind the name

`SkillMdPlugin` registers every SKILL.md that has triggers as a `SkillMdDrivenSkill` ([`SkillMdPlugin.cs` lines 83-92](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Plugins/SkillMdPlugin.cs#L83-L92)), so two skills carry the name:

```text
== The skills registered under the name Transpose, and the intent the router can pick for each (at the pin)
skill                name         intent                 CanHandle accepts
SkillMdDrivenSkill   transpose    none                   18 of the 26 phrasings
TransposeSkill       Transpose    skill.transpose        0 of the 26 phrasings
IOrchestratorSkill registrations 50, of them built from a SKILL.md 18, behind an intent 0
```

- **Only `TransposeSkill` has an intent, and its `CanHandle` accepts none of the 26 phrasings.** The SKILL.md skill accepts 18, but none of the 18 skills built from a SKILL.md is behind an intent: the router reads only intents, and the orchestrator no longer calls `CanHandle`, as [lesson 4](../04-chatbot-and-agents/) showed.

On `main`, the table is the same.

## Without embeddings

With Ollama's port closed, the program asks the host's `SemanticIntentRouter` to route each phrasing, then posts it to `/api/chatbot/chat`. At the pin:

```text
== Without embeddings: the intent SemanticIntentRouter picks for each phrasing, and what POST /api/chatbot/chat answers (at the pin)
phrasing                                     router picks             chat: agent (routing method)                  first line of the answer
transpose this progression down a half step  none                     HTTP 500
transpose this progression up a whole step   none                     HTTP 500
transpose C-Am-F-G to G major                none                     HTTP 500
shift this progression up a half step        none                     HTTP 500
bring D minor down to A minor                none                     HTTP 500
Transpose Cmaj7 up a perfect fourth          none                     HTTP 500
Move this F chord down a minor third         none                     HTTP 500
What's Dm7 up a whole step?                  none                     HTTP 500
Transpose G7 to Eb                           none                     HTTP 500
Shift Am7 up a fifth                         none                     HTTP 500
raise the key by two semitones               none                     HTTP 500
lower the key by a half step                 none                     HTTP 500
transposing the chorus down a tone           none                     HTTP 500
Cmaj7 in the key of G                        none                     HTTP 500
Transpose C E G to D                         none                     HTTP 500
Transpose C major to E                       none                     HTTP 500
Transpose this progression to capo 3         none                     HTTP 500
Transpose A minor to C minor                 none                     HTTP 500
Transpose Dm7 down a half step               none                     HTTP 500
Move Am up two frets                         none                     HTTP 500
Shift the song to the key of E               none                     HTTP 500
Put Cmaj7 in the key of A                    none                     HTTP 500
Raise Bb7 by a minor third                   none                     HTTP 500
Lower G by a tritone                         none                     HTTP 500
Play this song a whole step down             none                     HTTP 500
Take F#m up a fourth                         none                     HTTP 500
26 phrasings; the router picks none 26; the chat endpoint answers with HTTP 500 26
```

- **Every phrasing ends in HTTP 500.** The intent router returns nothing when the question's embedding fails ([`SemanticIntentRouter.cs` lines 115-127](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Intents/SemanticIntentRouter.cs#L115-L127)), and the agent router behind it doesn't catch its own failed embedding ([`SemanticRouter.cs` lines 70-73](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/SemanticRouter.cs#L70-L73)), as [lesson 4](../04-chatbot-and-agents/) traced; three of the corpus prompts ended the same way in [lesson 8](../08-the-chatbots-own-exam/).

On `main`:

```text
== Without embeddings: the intent SemanticIntentRouter picks for each phrasing, and what POST /api/chatbot/chat answers (on main)
phrasing                                     router picks             chat: agent (routing method)                  first line of the answer
transpose this progression down a half step  none                     voicing (keyword)                             Found 10 voicings matching tags [half]:
transpose this progression up a whole step   none                     voicing (keyword)                             Found 10 voicings matching tags [whole]:
transpose C-Am-F-G to G major                none                     voicing (keyword)                             Found 10 voicings matching chord G + mode major +…
shift this progression up a half step        none                     voicing (keyword)                             Found 10 voicings matching tags [half]:
bring D minor down to A minor                none                     voicing (keyword)                             Found 10 voicings matching chord D + mode minor +…
Transpose Cmaj7 up a perfect fourth          none                     voicing (keyword)                             Found 10 voicings matching chord Cmaj7 + tags [fo…
Move this F chord down a minor third         skill.chordinfo          skill.chordinfo (orchestrator-skill-semantic) F major chord contains F, A, and C.
What's Dm7 up a whole step?                  skill.chordinfo          skill.chordinfo (orchestrator-skill-semantic) D minor 7 chord contains D, F, A, and C.
Transpose G7 to Eb                           none                     voicing (keyword)                             Found 10 voicings matching chord G7:
Shift Am7 up a fifth                         none                     voicing (keyword)                             Found 10 voicings matching chord Am7 + tags [fift…
raise the key by two semitones               none                     fallback-direct (error-fallback-unavailable)  Our reasoning service is currently unavailable, s…
lower the key by a half step                 none                     fallback-direct (error-fallback-unavailable)  Our reasoning service is currently unavailable, s…
transposing the chorus down a tone           none                     voicing (keyword)                             Found 10 voicings matching tags [the, tone]:
Cmaj7 in the key of G                        none                     fallback-direct (error-fallback-unavailable)  Our reasoning service is currently unavailable, s…
Transpose C E G to D                         none                     voicing (keyword)                             Found 10 voicings matching chord C:
Transpose C major to E                       none                     voicing (keyword)                             Found 10 voicings matching chord C + mode major:
Transpose this progression to capo 3         none                     voicing (keyword)                             I couldn't find a chord name, mode, or style tag …
Transpose A minor to C minor                 none                     voicing (keyword)                             Found 10 voicings matching chord A + mode minor +…
Transpose Dm7 down a half step               none                     voicing (keyword)                             Found 10 voicings matching chord Dm7 + tags [half…
Move Am up two frets                         none                     fallback-direct (error-fallback-unavailable)  Our reasoning service is currently unavailable, s…
Shift the song to the key of E               none                     fallback-direct (error-fallback-unavailable)  Our reasoning service is currently unavailable, s…
Put Cmaj7 in the key of A                    none                     fallback-direct (error-fallback-unavailable)  Our reasoning service is currently unavailable, s…
Raise Bb7 by a minor third                   none                     voicing (keyword)                             Found 10 voicings matching chord Bb7 + mode minor…
Lower G by a tritone                         skill.chordsubstitution  skill.chordsubstitution (orchestrator-skill-semantic) Harmonic substitutions for **G** (ranked by ICV d…
Play this song a whole step down             none                     fallback-direct (error-fallback-unavailable)  Our reasoning service is currently unavailable, s…
Take F#m up a fourth                         none                     voicing (keyword)                             Found 10 voicings matching chord F#m + tags [four…
26 phrasings; the router picks none 23, skill.chordinfo 2, skill.chordsubstitution 1; the chat endpoint answers with voicing (keyword) 16, fallback-direct (error-fallback-unavailable) 7, skill.chordinfo (orchestrator-skill-semantic) 2, skill.chordsubstitution (orchestrator-skill-semantic) 1
```

- **The intent router routes 3 of the 26, never to `skill.transpose`.** "Move this F chord down a minor third" and "What's Dm7 up a whole step?" go to `ChordInfoSkill`, which gives the notes of the chord before the transposition; "Lower G by a tritone" goes to `ChordSubstitutionSkill`, which lists substitutes for G. The routing method of the three says `orchestrator-skill-semantic`, which `OrchestratorSkillIntent` writes on every answer ([line 54](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.Core.Orchestration/Intents/OrchestratorSkillIntent.cs#L54)), though no embedding chose them.
- **The other 23 go to the agent router, which now catches the failed embedding and falls back on keywords** ([`SemanticRouter.cs` lines 72-84](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Agents/SemanticRouter.cs#L72-L84)). Each agent with a keyword list scores the share of its keywords the question contains; the voicing agent has no list and scores 0.1:

```csharp
        var keywords = new Dictionary<string, string[]>
        {
            [AgentIds.Tab] = ["tab", "tablature", "fret", "string", "ascii", "parse", "e|", "a|", "d|"],
            [AgentIds.Theory] = ["chord", "scale", "key", "mode", "interval", "pitch", "harmonic", "function", "cadence", "theory"],
            [AgentIds.Technique] = ["finger", "position", "play", "technique", "stretch", "barre", "slide", "bend"],
            [AgentIds.Composer] = ["compose", "create", "generate", "reharmonize", "variation", "arrangement"],
            [AgentIds.Critic] = ["evaluate", "critique", "review", "improve", "suggest", "better"]
        };

        var lowerQuery = query.ToLowerInvariant();
        var scores = new List<(GuitarAlchemistAgentBase Agent, float Score)>();

        foreach (var agent in _agents)
        {
            if (keywords.TryGetValue(agent.AgentId, out var agentKeywords))
            {
                var matchCount = agentKeywords.Count(k => lowerQuery.Contains(k));
                var score = (float)matchCount / agentKeywords.Length;
                scores.Add((agent, score));
            }
            else
            {
                scores.Add((agent, 0.1f)); // Default low score
            }
        }
```

- **16 phrasings get a voicing search.** A question with none of the keywords goes to the voicing agent, whose search reads "half", "whole" or "fourth" as tags: "Shift Am7 up a fifth" gets Am7 voicings. The 7 with "key", "fret" or "play" go to an agent that needs a model, and the answer is the fallback's "Our reasoning service is currently unavailable". "fret" and "play" lift the tab or technique agent above 0.1; "key" lifts the theory agent only to 0.1, the voicing agent's score, and the theory agent keeps the tie because it is registered before the voicing agent ([`ServiceCollectionExtensions.cs` lines 94-99](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Extensions/ServiceCollectionExtensions.cs#L94-L99)) and the sort keeps equal scores in that order ([`SemanticRouter.cs` line 373](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Agents/SemanticRouter.cs#L373)). Which agent each one reached isn't printed; this is read from the code.

## The skill itself

Called directly, without a model:

```text
== TransposeSkill called directly with "Transpose Cmaj7 up a perfect fourth" (at the pin)
confidence 0.00
  | I encountered an error processing your request. Please try again.
  evidence: Source: skills/transpose/SKILL.md
  evidence: Closure: domain.transposeChord (via ga_dsl_eval)
  evidence: warning: ga_dsl_eval was NOT invoked — answer is LLM-only, not deterministic
```

- **The answer is an error, and the evidence calls it LLM-only.** `SkillMdDrivenSkill` catches the failed model call and answers with its error message ([`SkillMdDrivenSkill.cs` lines 204-226](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/SkillMdDrivenSkill.cs#L204-L226)); the wrapper finds no `ga_dsl_eval` call and adds "answer is LLM-only", the misleading line [lesson 8](../08-the-chatbots-own-exam/) found in `DiatonicChordsSkill`'s log, reported as GA issue [#764](https://github.com/GuitarAlchemist/ga/issues/764). Even routed, the skill can't transpose offline: the honest answer to a transposition without a model is that it can't be answered now.

On `main`, the answer and the evidence are the same.

## Where the course stops

- **The embeddings aren't computed.** A hint is +0.06 on a cosine score; whether it changes the skill the router picks depends on scores the course can't compute. The lesson measures the hints and the paths without embeddings, not the routing with them.
- **The phrasings are a sample:** the skill's and its SKILL.md's, GA's four corpus prompts, and eight of the course's own.
- **The chat endpoint is asked through `WebApplicationFactory`,** with the Ollama URL on a closed local port and an empty API key, and the tables print the first line of each answer.

## Exercises

1. Why does "What's Dm7 up a whole step?" get no transpose hint? Rewrite it so it gets one.
2. "best way to move from G7 to C" is a voice-leading example prompt. Which part of the transpose rule matches it?
3. On `main`, without embeddings, why can the intent router never pick `skill.transpose`?
4. On `main`, without embeddings, why does "Transpose C major to E" get a voicing search, while "Move Am up two frets" gets "Our reasoning service is currently unavailable"?

<details>
<summary>Solutions</summary>

1. It has no word starting with "transpos" and none of "shift", "bring" and "move" (line 257). "Shift Dm7 up a whole step" would get it, like "Shift Am7 up a fifth" in the table.
2. "move", then "from" and "G7", then "to C": the rule reads one to six words of any kind after the verb, then "to" and a capital letter.
3. It asks each intent whether it matches without embeddings, which for a skill's intent is the skill's `CanHandle` (`OrchestratorSkillIntent.cs` line 29), and `TransposeSkill`'s returns false (`SkillMdDrivenWrapperBase.cs` line 85). The SKILL.md skill, whose triggers accept 18 of the 26 phrasings, has no intent.
4. The intent router picks nothing for either, so both reach the agent router's keywords. "Transpose C major to E" has none of the keywords of the five agents that have a list, so each scores 0 and the voicing agent keeps its 0.1. "Move Am up two frets" contains "fret", one of the tab agent's nine keywords, so the tab agent scores about 0.11; it needs a model, and the fallback that replaces its answer has none either. Worked from the keyword lists; the program prints only the answering agent.

</details>

## Key takeaways

- Test a hint rule on the skill's own example prompts first: here 3 of 13 get nothing.
- A boost that two intents both get breaks no tie between them.
- A substring trigger such as "up a" also matches "make up a G7 chord".
- A keyword fallback reaches only the skills whose `CanHandle` can say yes: a skill that always says no can't be reached without embeddings.
- A default score for an agent with no keywords makes it the answer to every question without keywords: without a model, a clear "unavailable" beats a confident voicing search.

## Sources

- GuitarAlchemist/ga at [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `Common/GA.Business.ML/Agents/Intents/DefaultRoutingHintProvider.cs`, `Common/GA.Business.ML/Agents/Intents/SemanticIntentRouter.cs`, `Common/GA.Business.ML/Agents/SemanticRouter.cs`, `Common/GA.Business.ML/Agents/Skills/TransposeSkill.cs`, `Common/GA.Business.ML/Agents/Skills/SkillMdDrivenWrapperBase.cs`, `Common/GA.Business.ML/Agents/Skills/SkillMdDrivenSkill.cs`, `Common/GA.Business.ML/Agents/Plugins/SkillMdPlugin.cs`, `skills/transpose/SKILL.md`, `Tests/Apps/GaChatbot.Api.Tests/Corpus/prompts.yaml`.
- GuitarAlchemist/ga at [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/tree/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a): `SemanticIntentRouter.cs` with its keyword fallback, `Common/GA.Business.Core.Orchestration/Intents/OrchestratorSkillIntent.cs`, `SemanticRouter.cs` with its caught embedding failure, and the chatbot host.
- The course's programs: `code/ga-ai/GaAi/Lesson25.cs`, `code/ga-ai/GaMain/Program.cs`, `code/ga-ai/GaMain/MainChatHost.cs`, `code/ga-ai/Shared/TransposeRoutingProbe.cs`.
