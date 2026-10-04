---
title: "Leçon 25 : ce qui atteint le skill de transposition"
description: "Avant que le TransposeSkill de Guitar Alchemist puisse appeler sa closure, le chatbot doit lui transmettre la question. Sa règle d'indice manque 3 des 13 prompts d'exemple du skill et se déclenche sur 10 prompts d'exemple d'autres skills, et son CanHandle répond toujours non : sans embeddings, le main de GA ne peut jamais le choisir. Le commit épinglé répond HTTP 500 à 26 questions de transposition, main répond à 16 d'entre elles par une recherche de voicings."
sidebar:
  label: 25. Ce qui atteint la transposition
  order: 25
---

La [leçon 10](../10-what-the-model-is-told-to-trust/) a appelé la closure que `TransposeSkill` dit à un modèle d'utiliser, avec les arguments que prescrit son SKILL.md. Cette leçon s'intéresse à l'étape d'avant : quelles questions atteignent le skill. Le routeur d'intentions du chatbot note chaque skill par sa meilleure correspondance parmi sa description et ses prompts d'exemple, ajoute +0,06 pour chaque indice de routage dont l'expression correspond, et ne route que si la meilleure note atteint `MinConfidence` ([`SemanticIntentRouter.cs` lignes 129-257](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Intents/SemanticIntentRouter.cs#L129-L257)). Le cours n'a pas de modèle pour calculer les embeddings ; il exécute donc les deux parties qui n'en ont pas besoin : les indices, et ce que fait le chatbot d'une transposition quand aucun embedding ne peut être calculé.

Tous les liens vers GA pointent sur le commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), le commit épinglé du cours, sauf ceux qui en nomment un autre. Sur le `main` de GA à [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/commit/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) (2026-10-01), `TransposeSkill`, son SKILL.md, les règles d'indice, `SkillMdPlugin` et l'enregistrement des skills sont inchangés, mais les deux routeurs ont changé pour une question dont ils ne peuvent pas calculer l'embedding : le routeur d'intentions demande à chaque intention si elle correspond sans embeddings, et le routeur d'agents se rabat sur ses mots-clés au lieu de lever une exception. Les deux changements viennent des pull requests de GA [#686](https://github.com/GuitarAlchemist/ga/pull/686) et [#688](https://github.com/GuitarAlchemist/ga/pull/688), qui corrigeaient des constats de ce cours et de music-theory-ga. `GaMain` démarre désormais l'hôte du chatbot de `main` comme `GaAi` démarre celui du commit épinglé, avec le même port Ollama fermé, sans clé d'API, et avec l'index de la leçon 3 construit par le code de `main`. Les sorties viennent de :

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l25
dotnet run --project code/ga-ai/GaMain -c Release -- l25
```

## Comment une question atteint le skill

`DefaultRoutingHintProvider` a une règle pour la transposition : un mot qui commence par « transpos », ou « shift », « bring » ou « move » suivi, un à six mots plus loin, de « up », « down », ou de « to » et d'une majuscule :

```csharp
        (new Regex(@"\btranspos\w+\b|\b(shift|bring|move)\b\s+\S+(?:\s+\S+){0,5}?\s+(?:up|down|to\s+(?-i:[A-G]))\b",
            RegexOptions.IgnoreCase | RegexOptions.Compiled),
            "skill.transpose"),
```

`TransposeSkill` confie la question à un modèle, et la classe dont il dérive répond non à tout `CanHandle` :

```csharp
    /// <inheritdoc />
    /// <remarks>
    /// Tool-driven skills only route via the <see cref="Intents.SemanticIntentRouter"/>;
    /// the legacy <c>CanHandle</c> regex shadow is intentionally disabled.
    /// </remarks>
    public bool CanHandle(string message) => false;
```

Sur `main`, quand l'embedding de la question ne peut pas être calculé, le routeur d'intentions la donne à la première intention, dans l'ordre d'enregistrement, qui y correspond sans embeddings. Pour l'intention d'un skill, c'est le `CanHandle` du skill ([`OrchestratorSkillIntent.cs` ligne 29](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.Core.Orchestration/Intents/OrchestratorSkillIntent.cs#L29)) :

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

## Les indices que reçoit une transposition

Le programme interroge `DefaultRoutingHintProvider` sur 26 formulations : les 13 prompts d'exemple du skill, la seule formulation de son SKILL.md qui n'en fait pas partie ([ligne 80](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/transpose/SKILL.md#L80)), les quatre prompts de transposition du corpus de GA, et huit formulations du cours. Il cherche aussi dans chacune les déclencheurs du SKILL.md, comme sous-chaînes en minuscules, à la manière de `SkillMdDrivenSkill.CanHandle` ([`SkillMdDrivenSkill.cs` lignes 54-65](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/SkillMdDrivenSkill.cs#L54-L65)) :

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

- **L'indice de transposition manque 3 des 13 prompts d'exemple du skill.** « What's Dm7 up a whole step? », « raise the key by two semitones » et « lower the key by a half step » n'ont aucun de ses verbes, pas plus que le « Cmaj7 in the key of G » du SKILL.md. Le « Shift the song to the key of E » du cours a le verbe, mais finit sur « of E », et non sur « to E ».
- **Deux prompts d'exemple favorisent `skill.interval` autant que `skill.transpose`.** « Transpose Cmaj7 up a perfect fourth » et « Move this F chord down a minor third » nomment un intervalle, que lit la règle des intervalles ([lignes 74-76](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Intents/DefaultRoutingHintProvider.cs#L74-L76)) ; avec +0,06 sur les deux intentions, les indices laissent l'écart entre elles là où les embeddings le placent. « Raise Bb7 by a minor third » et « Lower G by a tritone » ne favorisent que `skill.interval`, et « Play this song a whole step down » ne favorise que `skill.alternatetunings`, dont la règle prend « whole step down » pour un accordage ([lignes 159-161](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Intents/DefaultRoutingHintProvider.cs#L159-L161)).

Sur `main`, le tableau est le même.

## Ce que l'indice et les déclencheurs attrapent aussi

Le programme pose la même question aux prompts d'exemple de toutes les autres intentions :

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

- **L'indice de transposition se déclenche sur 10 prompts d'exemple d'autres intentions.** « transposition » et « transpositionally » dans deux prompts de théorie des ensembles et dans « What are modes of limited transposition » ; « Transpose », un nom de foncteur, dans cinq prompts du skill d'analyse ; et « move from G7 to C » et « move from C to G », où « to » et une majuscule terminent la phrase. Les leçons [23](../23-harmonic-distance-and-path/) et [24](../24-set-classes-and-the-grothendieck-parser/) en ont affiché certains dans leurs colonnes d'indices.
- **Les déclencheurs sont des sous-chaînes.** « up a » se trouve dans « what notes make up a G7 chord » et dans « Brighten up a minor key tune », et « in the key of » dans « All chords in the key of D ».

Sur `main`, les mêmes 13 lignes sortent de 412 prompts d'exemple de 35 intentions.

## Les skills derrière le nom

`SkillMdPlugin` enregistre chaque SKILL.md qui a des déclencheurs comme un `SkillMdDrivenSkill` ([`SkillMdPlugin.cs` lignes 83-92](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Plugins/SkillMdPlugin.cs#L83-L92)) ; deux skills portent donc le nom :

```text
== The skills registered under the name Transpose, and the intent the router can pick for each (at the pin)
skill                name         intent                 CanHandle accepts
SkillMdDrivenSkill   transpose    none                   18 of the 26 phrasings
TransposeSkill       Transpose    skill.transpose        0 of the 26 phrasings
IOrchestratorSkill registrations 50, of them built from a SKILL.md 18, behind an intent 0
```

- **Seul `TransposeSkill` a une intention, et son `CanHandle` n'accepte aucune des 26 formulations.** Le skill du SKILL.md en accepte 18, mais aucun des 18 skills construits à partir d'un SKILL.md n'est derrière une intention : le routeur ne lit que les intentions, et l'orchestrateur n'appelle plus `CanHandle`, comme l'a montré la [leçon 4](../04-chatbot-and-agents/).

Sur `main`, le tableau est le même.

## Sans embeddings

Avec le port d'Ollama fermé, le programme demande au `SemanticIntentRouter` de l'hôte de router chaque formulation, puis l'envoie à `/api/chatbot/chat`. Au commit épinglé :

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

- **Chaque formulation finit en HTTP 500.** Le routeur d'intentions ne renvoie rien quand l'embedding de la question échoue ([`SemanticIntentRouter.cs` lignes 115-127](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Intents/SemanticIntentRouter.cs#L115-L127)), et le routeur d'agents qui le suit n'intercepte pas l'échec de son propre embedding ([`SemanticRouter.cs` lignes 70-73](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/SemanticRouter.cs#L70-L73)), comme l'a retracé la [leçon 4](../04-chatbot-and-agents/) ; trois des prompts du corpus finissaient de la même façon dans la [leçon 8](../08-the-chatbots-own-exam/).

Sur `main` :

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

- **Le routeur d'intentions route 3 des 26 formulations, jamais vers `skill.transpose`.** « Move this F chord down a minor third » et « What's Dm7 up a whole step? » vont à `ChordInfoSkill`, qui donne les notes de l'accord avant la transposition ; « Lower G by a tritone » va à `ChordSubstitutionSkill`, qui liste des substituts de G. La méthode de routage des trois indique `orchestrator-skill-semantic`, que `OrchestratorSkillIntent` écrit sur chaque réponse ([ligne 54](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.Core.Orchestration/Intents/OrchestratorSkillIntent.cs#L54)), alors qu'aucun embedding ne les a choisies.
- **Les 23 autres vont au routeur d'agents, qui intercepte désormais l'échec de l'embedding et se rabat sur ses mots-clés** ([`SemanticRouter.cs` lignes 72-84](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Agents/SemanticRouter.cs#L72-L84)). Chaque agent qui a une liste de mots-clés reçoit la part de ses mots-clés que contient la question ; l'agent des voicings n'a pas de liste et reçoit 0,1 :

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

- **16 formulations reçoivent une recherche de voicings.** Une question sans aucun des mots-clés va à l'agent des voicings, dont la recherche lit « half », « whole » ou « fourth » comme des étiquettes : « Shift Am7 up a fifth » reçoit des voicings d'Am7. Les 7 qui contiennent « key », « fret » ou « play » vont à un agent qui a besoin d'un modèle, et la réponse est le « Our reasoning service is currently unavailable » du repli. « fret » et « play » font passer l'agent des tablatures ou celui de la technique au-dessus de 0,1 ; « key » n'amène l'agent de théorie qu'à 0,1, le score de l'agent des voicings, et l'agent de théorie l'emporte à égalité parce qu'il est enregistré avant l'agent des voicings ([`ServiceCollectionExtensions.cs` lignes 94-99](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Extensions/ServiceCollectionExtensions.cs#L94-L99)) et que le tri garde les scores égaux dans cet ordre ([`SemanticRouter.cs` ligne 373](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Agents/SemanticRouter.cs#L373)). L'agent atteint par chacune n'est pas affiché ; ceci est lu dans le code.

## Le skill lui-même

Appelé directement, sans modèle :

```text
== TransposeSkill called directly with "Transpose Cmaj7 up a perfect fourth" (at the pin)
confidence 0.00
  | I encountered an error processing your request. Please try again.
  evidence: Source: skills/transpose/SKILL.md
  evidence: Closure: domain.transposeChord (via ga_dsl_eval)
  evidence: warning: ga_dsl_eval was NOT invoked — answer is LLM-only, not deterministic
```

- **La réponse est une erreur, et les preuves la disent produite par le seul LLM.** `SkillMdDrivenSkill` intercepte l'échec de l'appel au modèle et répond par son message d'erreur ([`SkillMdDrivenSkill.cs` lignes 204-226](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/SkillMdDrivenSkill.cs#L204-L226)) ; l'enveloppe ne trouve aucun appel à `ga_dsl_eval` et ajoute « answer is LLM-only », la ligne trompeuse que la [leçon 8](../08-the-chatbots-own-exam/) avait trouvée dans le journal de `DiatonicChordsSkill`, signalée dans le ticket de GA [#764](https://github.com/GuitarAlchemist/ga/issues/764). Même routé, le skill ne peut pas transposer hors ligne : sans modèle, la réponse honnête à une transposition est qu'on ne peut pas y répondre pour l'instant.

Sur `main`, la réponse et les preuves sont les mêmes.

## Où le cours s'arrête

- **Les embeddings ne sont pas calculés.** Un indice vaut +0,06 sur une note cosinus ; qu'il change le skill choisi par le routeur dépend de notes que le cours ne peut pas calculer. La leçon mesure les indices et les chemins sans embeddings, pas le routage avec.
- **Les formulations sont un échantillon :** celles du skill et de son SKILL.md, les quatre prompts du corpus de GA, et huit formulations du cours.
- **Le point de chat est interrogé par `WebApplicationFactory`,** avec l'URL d'Ollama sur un port local fermé et une clé d'API vide, et les tableaux affichent la première ligne de chaque réponse.

## Exercices

1. Pourquoi « What's Dm7 up a whole step? » ne reçoit-il pas d'indice de transposition ? Reformulez-le pour qu'il en reçoive un.
2. « best way to move from G7 to C » est un prompt d'exemple de la conduite des voix. Quelle partie de la règle de transposition y correspond ?
3. Sur `main`, sans embeddings, pourquoi le routeur d'intentions ne peut-il jamais choisir `skill.transpose` ?
4. Sur `main`, sans embeddings, pourquoi « Transpose C major to E » reçoit-il une recherche de voicings, et « Move Am up two frets » le message « Our reasoning service is currently unavailable » ?

<details>
<summary>Solutions</summary>

1. Il n'a aucun mot qui commence par « transpos », ni « shift », « bring » ou « move » (ligne 257). « Shift Dm7 up a whole step » en recevrait un, comme « Shift Am7 up a fifth » dans le tableau.
2. « move », puis « from » et « G7 », puis « to C » : la règle lit un à six mots de n'importe quelle sorte après le verbe, puis « to » et une majuscule.
3. Il demande à chaque intention si elle correspond sans embeddings, ce qui, pour l'intention d'un skill, est le `CanHandle` du skill (`OrchestratorSkillIntent.cs` ligne 29), et celui de `TransposeSkill` renvoie false (`SkillMdDrivenWrapperBase.cs` ligne 85). Le skill du SKILL.md, dont les déclencheurs acceptent 18 des 26 formulations, n'a pas d'intention.
4. Le routeur d'intentions ne choisit rien pour l'une ni pour l'autre ; les deux arrivent donc aux mots-clés du routeur d'agents. « Transpose C major to E » ne contient aucun des mots-clés des cinq agents qui ont une liste : chacun reçoit 0 et l'agent des voicings garde son 0,1. « Move Am up two frets » contient « fret », l'un des neuf mots-clés de l'agent des tablatures, qui reçoit donc environ 0,11 ; il a besoin d'un modèle, et le repli qui remplace sa réponse n'en a pas non plus. Raisonnement tiré des listes de mots-clés ; le programme n'affiche que l'agent qui répond.

</details>

## À retenir

- Testez d'abord une règle d'indice sur les propres prompts d'exemple du skill : ici, 3 sur 13 ne reçoivent rien.
- Un bonus que reçoivent deux intentions ne départage pas ces deux intentions.
- Un déclencheur en sous-chaîne comme « up a » correspond aussi à « make up a G7 chord ».
- Un repli par mots-clés n'atteint que les skills dont le `CanHandle` peut dire oui : un skill qui dit toujours non est inaccessible sans embeddings.
- Une note par défaut pour un agent sans mots-clés en fait la réponse à toute question sans mots-clés : sans modèle, un « indisponible » clair vaut mieux qu'une recherche de voicings assurée.

## Sources

- GuitarAlchemist/ga au commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6) : `Common/GA.Business.ML/Agents/Intents/DefaultRoutingHintProvider.cs`, `Common/GA.Business.ML/Agents/Intents/SemanticIntentRouter.cs`, `Common/GA.Business.ML/Agents/SemanticRouter.cs`, `Common/GA.Business.ML/Agents/Skills/TransposeSkill.cs`, `Common/GA.Business.ML/Agents/Skills/SkillMdDrivenWrapperBase.cs`, `Common/GA.Business.ML/Agents/Skills/SkillMdDrivenSkill.cs`, `Common/GA.Business.ML/Agents/Plugins/SkillMdPlugin.cs`, `skills/transpose/SKILL.md`, `Tests/Apps/GaChatbot.Api.Tests/Corpus/prompts.yaml`.
- GuitarAlchemist/ga au commit [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/tree/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) : `SemanticIntentRouter.cs` avec son repli par mots-clés, `Common/GA.Business.Core.Orchestration/Intents/OrchestratorSkillIntent.cs`, `SemanticRouter.cs` avec l'échec d'embedding qu'il intercepte, et l'hôte du chatbot.
- Les programmes du cours : `code/ga-ai/GaAi/Lesson25.cs`, `code/ga-ai/GaMain/Program.cs`, `code/ga-ai/GaMain/MainChatHost.cs`, `code/ga-ai/Shared/TransposeRoutingProbe.cs`.
