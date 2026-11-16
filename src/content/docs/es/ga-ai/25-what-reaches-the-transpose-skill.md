---
title: "Lección 25: Lo que llega a la skill de transposición"
description: "Antes de que la TransposeSkill de Guitar Alchemist pueda llamar a su closure, el chatbot tiene que enviarle la pregunta. Su regla de pistas no se activa con 3 de los 13 prompts de ejemplo de la skill y se activa con 10 prompts de ejemplo de otras skills, y su CanHandle siempre dice que no, así que sin embeddings el main de GA nunca puede elegirla: el commit fijado responde HTTP 500 a 26 preguntas de transposición, main responde a 16 de ellas con una búsqueda de voicings."
sidebar:
  label: 25. Lo que llega a la transposición
  order: 25
---

La [lección 10](../10-what-the-model-is-told-to-trust/) llamó a la closure que `TransposeSkill` le dice a un modelo que use, con los argumentos que prescribe su SKILL.md. Esta lección pregunta por el paso anterior: qué preguntas llegan a la skill. El enrutador de intenciones del chatbot puntúa cada skill por su mejor coincidencia entre su descripción y sus prompts de ejemplo, suma +0,06 por cada pista de enrutamiento cuyo patrón coincide, y solo enruta si la mejor puntuación alcanza `MinConfidence` ([`SemanticIntentRouter.cs` líneas 129-257](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Intents/SemanticIntentRouter.cs#L129-L257)). El curso no tiene un modelo para calcular los embeddings, así que ejecuta las dos partes que no lo necesitan: las pistas, y lo que hace el chatbot con una transposición cuando no se puede calcular ningún embedding.

Todos los enlaces a GA apuntan al commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), el commit fijado del curso, salvo los que nombran otro. En el `main` de GA en [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/commit/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) (2026-10-01), `TransposeSkill`, su SKILL.md, las reglas de pistas, `SkillMdPlugin` y el registro de las skills no han cambiado, pero los dos enrutadores cambiaron para una pregunta cuyo embedding no pueden calcular: el enrutador de intenciones pregunta a cada intención si coincide sin embeddings, y el enrutador de agentes recurre a sus palabras clave en lugar de lanzar una excepción. Los dos cambios vienen de las pull requests de GA [#686](https://github.com/GuitarAlchemist/ga/pull/686) y [#688](https://github.com/GuitarAlchemist/ga/pull/688), que corregían hallazgos de este curso y de music-theory-ga. `GaMain` arranca ahora el host del chatbot de `main` igual que `GaAi` arranca el del commit fijado, con el mismo puerto de Ollama cerrado, sin clave de API y con el índice de la lección 3 construido con el código de `main`. La salida procede de:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l25
dotnet run --project code/ga-ai/GaMain -c Release -- l25
```

## Cómo llega una pregunta a la skill

`DefaultRoutingHintProvider` tiene una regla para la transposición: una palabra que empieza por "transpos", o "shift", "bring" o "move" seguida, entre una y seis palabras después, de "up", "down", o de "to" y una mayúscula:

```csharp
        (new Regex(@"\btranspos\w+\b|\b(shift|bring|move)\b\s+\S+(?:\s+\S+){0,5}?\s+(?:up|down|to\s+(?-i:[A-G]))\b",
            RegexOptions.IgnoreCase | RegexOptions.Compiled),
            "skill.transpose"),
```

`TransposeSkill` le pasa la pregunta a un modelo, y la clase de la que deriva responde que no a todo `CanHandle`:

```csharp
    /// <inheritdoc />
    /// <remarks>
    /// Tool-driven skills only route via the <see cref="Intents.SemanticIntentRouter"/>;
    /// the legacy <c>CanHandle</c> regex shadow is intentionally disabled.
    /// </remarks>
    public bool CanHandle(string message) => false;
```

En `main`, cuando no se puede calcular el embedding de la pregunta, el enrutador de intenciones se la da a la primera intención, en orden de registro, que coincide con ella sin embeddings. Para la intención de una skill, eso es el `CanHandle` de la skill ([`OrchestratorSkillIntent.cs` línea 29](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.Core.Orchestration/Intents/OrchestratorSkillIntent.cs#L29)):

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

## Las pistas que recibe una transposición

El programa le pregunta a `DefaultRoutingHintProvider` por 26 formulaciones: los 13 prompts de ejemplo de la skill, la única formulación de su SKILL.md que no está entre ellos ([línea 80](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/transpose/SKILL.md#L80)), los cuatro prompts de transposición del corpus de GA y ocho del curso. También busca en cada una los disparadores del SKILL.md, como subcadenas en minúsculas, igual que `SkillMdDrivenSkill.CanHandle` ([`SkillMdDrivenSkill.cs` líneas 54-65](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/SkillMdDrivenSkill.cs#L54-L65)):

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

- **La pista de transposición no se activa con 3 de los 13 prompts de ejemplo de la skill.** "What's Dm7 up a whole step?", "raise the key by two semitones" y "lower the key by a half step" no tienen ninguno de sus verbos, y tampoco el "Cmaj7 in the key of G" del SKILL.md. El "Shift the song to the key of E" del curso tiene el verbo, pero termina en "of E", no en "to E".
- **Dos prompts de ejemplo refuerzan a `skill.interval` tanto como a `skill.transpose`.** "Transpose Cmaj7 up a perfect fourth" y "Move this F chord down a minor third" nombran un intervalo, que lee la regla de los intervalos ([líneas 74-76](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Intents/DefaultRoutingHintProvider.cs#L74-L76)); con +0,06 en las dos intenciones, las pistas dejan la distancia entre ellas donde la ponen los embeddings. "Raise Bb7 by a minor third" y "Lower G by a tritone" solo refuerzan a `skill.interval`, y "Play this song a whole step down" solo a `skill.alternatetunings`, cuya regla toma "whole step down" por una afinación ([líneas 159-161](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Intents/DefaultRoutingHintProvider.cs#L159-L161)).

En `main`, la tabla es la misma.

## Lo que la pista y los disparadores también se llevan

El programa pregunta lo mismo con los prompts de ejemplo de todas las demás intenciones:

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

- **La pista de transposición se activa con 10 prompts de ejemplo de otras intenciones.** "transposition" y "transpositionally" en dos prompts de teoría de conjuntos y en "What are modes of limited transposition"; "Transpose", el nombre de un funtor, en cinco de los de la skill de análisis; y "move from G7 to C" y "move from C to G", donde "to" y una mayúscula cierran la frase. Las lecciones [23](../23-harmonic-distance-and-path/) y [24](../24-set-classes-and-the-grothendieck-parser/) imprimieron algunos en sus columnas de pistas.
- **Los disparadores son subcadenas.** "up a" está en "what notes make up a G7 chord" y en "Brighten up a minor key tune", e "in the key of" en "All chords in the key of D".

En `main`, las mismas 13 filas salen de 412 prompts de ejemplo de 35 intenciones.

## Las skills detrás del nombre

`SkillMdPlugin` registra cada SKILL.md que tiene disparadores como una `SkillMdDrivenSkill` ([`SkillMdPlugin.cs` líneas 83-92](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Plugins/SkillMdPlugin.cs#L83-L92)), así que dos skills llevan el nombre:

```text
== The skills registered under the name Transpose, and the intent the router can pick for each (at the pin)
skill                name         intent                 CanHandle accepts
SkillMdDrivenSkill   transpose    none                   18 of the 26 phrasings
TransposeSkill       Transpose    skill.transpose        0 of the 26 phrasings
IOrchestratorSkill registrations 50, of them built from a SKILL.md 18, behind an intent 0
```

- **Solo `TransposeSkill` tiene una intención, y su `CanHandle` no acepta ninguna de las 26 formulaciones.** La skill del SKILL.md acepta 18, pero ninguna de las 18 skills construidas a partir de un SKILL.md está detrás de una intención: el enrutador solo lee intenciones, y el orquestador ya no llama a `CanHandle`, como mostró la [lección 4](../04-chatbot-and-agents/).

En `main`, la tabla es la misma.

## Sin embeddings

Con el puerto de Ollama cerrado, el programa le pide al `SemanticIntentRouter` del host que enrute cada formulación y después la envía a `/api/chatbot/chat`. En el commit fijado:

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

- **Todas las formulaciones terminan en HTTP 500.** El enrutador de intenciones no devuelve nada cuando falla el embedding de la pregunta ([`SemanticIntentRouter.cs` líneas 115-127](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Intents/SemanticIntentRouter.cs#L115-L127)), y el enrutador de agentes que va detrás no captura el fallo de su propio embedding ([`SemanticRouter.cs` líneas 70-73](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/SemanticRouter.cs#L70-L73)), como rastreó la [lección 4](../04-chatbot-and-agents/); tres de los prompts del corpus terminaron igual en la [lección 8](../08-the-chatbots-own-exam/).

En `main`:

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

- **El enrutador de intenciones enruta 3 de las 26, nunca a `skill.transpose`.** "Move this F chord down a minor third" y "What's Dm7 up a whole step?" van a `ChordInfoSkill`, que da las notas del acorde antes de la transposición; "Lower G by a tritone" va a `ChordSubstitutionSkill`, que lista sustitutos de G. El método de enrutamiento de las tres dice `orchestrator-skill-semantic`, que `OrchestratorSkillIntent` escribe en cada respuesta ([línea 54](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.Core.Orchestration/Intents/OrchestratorSkillIntent.cs#L54)), aunque ningún embedding las eligió.
- **Las otras 23 van al enrutador de agentes, que ahora captura el fallo del embedding y recurre a sus palabras clave** ([`SemanticRouter.cs` líneas 72-84](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Agents/SemanticRouter.cs#L72-L84)). Cada agente con una lista de palabras clave puntúa la proporción de sus palabras clave que contiene la pregunta; el agente de voicings no tiene lista y puntúa 0,1:

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

- **16 formulaciones reciben una búsqueda de voicings.** Una pregunta sin ninguna de las palabras clave va al agente de voicings, cuya búsqueda lee "half", "whole" o "fourth" como etiquetas: "Shift Am7 up a fifth" recibe voicings de Am7. Las 7 que contienen "key", "fret" o "play" van a un agente que necesita un modelo, y la respuesta es el "Our reasoning service is currently unavailable" del respaldo. "fret" y "play" llevan al agente de tablaturas o al de técnica por encima de 0,1; "key" solo lleva al agente de teoría a 0,1, la puntuación del agente de voicings, y el agente de teoría gana el empate porque está registrado antes que el agente de voicings ([`ServiceCollectionExtensions.cs` líneas 94-99](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Extensions/ServiceCollectionExtensions.cs#L94-L99)) y la ordenación conserva ese orden entre puntuaciones iguales ([`SemanticRouter.cs` línea 373](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Agents/SemanticRouter.cs#L373)). No se imprime a qué agente llegó cada una; esto se lee en el código.

## La skill en sí

Llamada directamente, sin modelo:

```text
== TransposeSkill called directly with "Transpose Cmaj7 up a perfect fourth" (at the pin)
confidence 0.00
  | I encountered an error processing your request. Please try again.
  evidence: Source: skills/transpose/SKILL.md
  evidence: Closure: domain.transposeChord (via ga_dsl_eval)
  evidence: warning: ga_dsl_eval was NOT invoked — answer is LLM-only, not deterministic
```

- **La respuesta es un error, y la evidencia la presenta como producida solo por el LLM.** `SkillMdDrivenSkill` captura el fallo de la llamada al modelo y responde con su mensaje de error ([`SkillMdDrivenSkill.cs` líneas 204-226](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/SkillMdDrivenSkill.cs#L204-L226)); el envoltorio no encuentra ninguna llamada a `ga_dsl_eval` y añade "answer is LLM-only", la línea engañosa que la [lección 8](../08-the-chatbots-own-exam/) encontró en el registro de `DiatonicChordsSkill`, comunicada en la issue de GA [#764](https://github.com/GuitarAlchemist/ga/issues/764). Aunque se la enrute, la skill no puede transponer sin conexión: sin modelo, la respuesta honesta a una transposición es que ahora no se puede responder.

En `main`, la respuesta y la evidencia son las mismas.

## Hasta dónde llega el curso

- **No se calculan los embeddings.** Una pista vale +0,06 sobre una puntuación coseno; que cambie la skill que elige el enrutador depende de puntuaciones que el curso no puede calcular. La lección mide las pistas y los caminos sin embeddings, no el enrutamiento con ellos.
- **Las formulaciones son una muestra:** las de la skill y de su SKILL.md, los cuatro prompts del corpus de GA y ocho del propio curso.
- **El endpoint de chat se consulta a través de `WebApplicationFactory`,** con la URL de Ollama en un puerto local cerrado y una clave de API vacía, y las tablas imprimen la primera línea de cada respuesta.

## Comunicado upstream

- Se comunicaron después de escribir esta lección, en la issue de GA [#809](https://github.com/GuitarAlchemist/ga/issues/809): los prompts de ejemplo que la pista de transposición no reconoce y los de otras intenciones con los que se activa, el respaldo por palabras clave que no puede llegar a `skill.transpose` y la victoria por defecto del agente de voicings, y los disparadores del SKILL.md hacia los que ninguna intención enruta.

## Ejercicios

1. ¿Por qué "What's Dm7 up a whole step?" no recibe la pista de transposición? Reformúlalo para que la reciba.
2. "best way to move from G7 to C" es un prompt de ejemplo de la conducción de voces. ¿Qué parte de la regla de transposición coincide con él?
3. En `main`, sin embeddings, ¿por qué el enrutador de intenciones nunca puede elegir `skill.transpose`?
4. En `main`, sin embeddings, ¿por qué "Transpose C major to E" recibe una búsqueda de voicings y "Move Am up two frets" recibe "Our reasoning service is currently unavailable"?

<details>
<summary>Soluciones</summary>

1. No tiene ninguna palabra que empiece por "transpos" ni ninguno de "shift", "bring" y "move" (línea 257). "Shift Dm7 up a whole step" la recibiría, como "Shift Am7 up a fifth" en la tabla.
2. "move", después "from" y "G7", después "to C": la regla lee entre una y seis palabras de cualquier tipo tras el verbo, y después "to" y una mayúscula.
3. Pregunta a cada intención si coincide sin embeddings, lo que para la intención de una skill es el `CanHandle` de la skill (`OrchestratorSkillIntent.cs` línea 29), y el de `TransposeSkill` devuelve false (`SkillMdDrivenWrapperBase.cs` línea 85). La skill del SKILL.md, cuyos disparadores aceptan 18 de las 26 formulaciones, no tiene intención.
4. El enrutador de intenciones no elige nada para ninguna de las dos, así que ambas llegan a las palabras clave del enrutador de agentes. "Transpose C major to E" no contiene ninguna de las palabras clave de los cinco agentes que tienen lista, así que cada uno puntúa 0 y el agente de voicings conserva su 0,1. "Move Am up two frets" contiene "fret", una de las nueve palabras clave del agente de tablaturas, que puntúa entonces unos 0,11; ese agente necesita un modelo, y el respaldo que reemplaza su respuesta tampoco tiene. Razonado a partir de las listas de palabras clave; el programa solo imprime el agente que responde.

</details>

## Puntos clave

- Prueba primero una regla de pistas con los propios prompts de ejemplo de la skill: aquí 3 de 13 no reciben nada.
- Un refuerzo que reciben dos intenciones no desempata entre ellas.
- Un disparador por subcadena como "up a" también coincide con "make up a G7 chord".
- Un respaldo por palabras clave solo llega a las skills cuyo `CanHandle` puede decir que sí: una skill que siempre dice que no es inalcanzable sin embeddings.
- Una puntuación por defecto para un agente sin palabras clave lo convierte en la respuesta a toda pregunta sin palabras clave: sin modelo, un "no disponible" claro es mejor que una búsqueda de voicings segura de sí misma.

## Fuentes

- GuitarAlchemist/ga en [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `Common/GA.Business.ML/Agents/Intents/DefaultRoutingHintProvider.cs`, `Common/GA.Business.ML/Agents/Intents/SemanticIntentRouter.cs`, `Common/GA.Business.ML/Agents/SemanticRouter.cs`, `Common/GA.Business.ML/Agents/Skills/TransposeSkill.cs`, `Common/GA.Business.ML/Agents/Skills/SkillMdDrivenWrapperBase.cs`, `Common/GA.Business.ML/Agents/Skills/SkillMdDrivenSkill.cs`, `Common/GA.Business.ML/Agents/Plugins/SkillMdPlugin.cs`, `skills/transpose/SKILL.md`, `Tests/Apps/GaChatbot.Api.Tests/Corpus/prompts.yaml`.
- GuitarAlchemist/ga en [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/tree/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a): `SemanticIntentRouter.cs` con su respaldo por palabras clave, `Common/GA.Business.Core.Orchestration/Intents/OrchestratorSkillIntent.cs`, `SemanticRouter.cs` con el fallo de embedding que captura, y el host del chatbot.
- Los programas del curso: `code/ga-ai/GaAi/Lesson25.cs`, `code/ga-ai/GaMain/Program.cs`, `code/ga-ai/GaMain/MainChatHost.cs`, `code/ga-ai/Shared/TransposeRoutingProbe.cs`.
