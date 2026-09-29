---
title: "Lección 8: El propio examen del chatbot"
description: "El corpus de prompts de Guitar Alchemist, los invariantes con los que se pone a prueba su chatbot, ejecutado sin modelo en el host del curso y puesto a prueba a su vez: las comprobaciones de cada prompt, aplicadas a las respuestas de los demás prompts y a su propia respuesta un semitono más arriba. Subcadenas que no distinguen mayúsculas de minúsculas, más de un tercio de ellas de una sola letra, aceptan un mensaje de error, la familia de modos equivocada y una respuesta sobre otra afinación; una lectura más estricta de las mismas cadenas reduce las respuestas ajenas aceptadas de 169 a 69."
sidebar:
  label: 8. El propio examen del chatbot
  order: 8
---

Las lecciones 5 a 7 calificaban las respuestas del chatbot con oráculos que el curso escribió a partir de manuales y estándares. GA tiene un oráculo propio. [`prompts.yaml`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Tests/Apps/GaChatbot.Api.Tests/Corpus/prompts.yaml) enumera preguntas que podría hacer un usuario, cada una con las cadenas que su respuesta debe contener o no debe contener, y [`PromptCorpusTests`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Tests/Apps/GaChatbot.Api.Tests/Corpus/PromptCorpusTests.cs) envía cada una a GaChatbot.Api y comprueba la respuesta. La prueba se presenta a sí misma como "the safety net under ongoing skill refactors" (la red de seguridad bajo las refactorizaciones de skills en curso) y "the oracle for the autonomous improvement loop" (el oráculo del bucle de mejora autónomo); el flujo de trabajo [`chatbot-qa-snapshot.yml`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/.github/workflows/chatbot-qa-snapshot.yml#L43) la ejecuta todos los días a las 06:00 UTC. Esta lección ejecuta el corpus sin modelo, como el curso lo ejecuta todo, y después pone a prueba la prueba: ¿qué tiene que hacer mal una respuesta para que el control lo note?

Todos los enlaces a GA apuntan al commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), el commit fijado del curso. En el `main` de GA, en [`fc76ad6`](https://github.com/GuitarAlchemist/ga/commit/fc76ad63cb70073330b6868d6e3c39307c5e262c), comprobado el 2026-09-29, `PromptCorpusTests.cs` y las skills que cita esta lección siguen sin cambios; el corpus ha pasado de 68 prompts a 75, y las entradas que cita la lección son las mismas. Las salidas proceden de:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l8
```

## El control

Una entrada nombra la pregunta, la intención que debe responderla y las cadenas:

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

`EvaluatePromptAsync` las comprueba en un orden fijo: una respuesta vacía, los marcadores de backend degradado, la longitud mínima, ocho frases prohibidas en todas las respuestas, luego `not_contains`, `contains` y `contains_any`, y por último la ruta, el anclaje y la forma de la traza ([líneas 313-484](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Tests/Apps/GaChatbot.Api.Tests/Corpus/PromptCorpusTests.cs#L313-L484)). Todas las cadenas se buscan de la misma manera ([líneas 367-379](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Tests/Apps/GaChatbot.Api.Tests/Corpus/PromptCorpusTests.cs#L367-L379)):

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

Una subcadena, y las mayúsculas no cuentan. GA conoce el límite: el comentario de la prueba del juez dice que los invariantes de subcadena "stay green even when the chat model is replaced with a bogus one (measured: 50 of 52 still passed)" (siguen en verde aunque el modelo de chat se sustituya por uno falso; medido: 50 de 52 seguían pasando), y los tres prompts cuya respuesta es prosa llevan en su lugar una rúbrica para un modelo juez ([líneas 204-210](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Tests/Apps/GaChatbot.Api.Tests/Corpus/PromptCorpusTests.cs#L204-L210)). Los marcadores de backend degradado también tienen su historia: durante un mes, la instantánea diaria publicó un porcentaje de aprobados del 7,69 % para un chatbot que obtenía un 98,08 % con modelo, porque las respuestas de un backend sin modelo fallaban como discrepancias corrientes ([líneas 54-75](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Tests/Apps/GaChatbot.Api.Tests/Corpus/PromptCorpusTests.cs#L54-L75)). Desde entonces, una respuesta que contiene una de dos frases, "The chatbot can't serve a request right now" o "right now. Please try again.", cuenta como "sin señal" y no como un fallo.

## Sin modelo

El corpus no está en el checkout disperso del curso, así que [`fetch-ga.sh`](https://github.com/spareilleux/learn/blob/main/code/ga-ai/fetch-ga.sh) lo extrae del clon con `git show`, como hace con los archivos de la #749 en la lección 7. `Lesson8.cs` lo lee con YamlDotNet y la misma configuración que la prueba, y porta las comprobaciones de texto, línea por línea, a `Evaluate`.

Sin modelo, el enrutador de intenciones no puede calcular el embedding de una pregunta, y la lección 4 mostró adónde lleva eso: a un HTTP 500. Así que un prompt que nombra su intención en `routes_to` se envía directamente a esa intención, a través del `IIntent` registrado con ese id, y los demás van a `POST /api/chatbot/chat`. En una llamada directa no se aplican las comprobaciones de ruta, de anclaje ni de traza; las de texto, sí.

Al preparar esta lección aparecieron dos carencias en el propio host del curso:

- **Faltaba la carpeta `skills/` de GA.** [`SkillMdPlugin.ResolveSkillsPath`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Plugins/SkillMdPlugin.cs#L113-L151) la busca en la raíz del repositorio git que contiene el programa en ejecución. Subiendo desde el programa del curso, el primer `.git` que encuentra es el del repositorio del curso, no el del clon. Ahora el curso descarga `skills/` y apunta `SKILLMD_SKILLS_PATH` a la copia del clon; el método solo acepta esa ruta alternativa dentro del repositorio que ha encontrado, y el clon está dentro del repositorio del curso. Las salidas de las lecciones 1 a 7 son las mismas con este cambio.
- **Se habría usado una clave presente en el entorno.** Las skills que siguen un SKILL.md llaman a la API de Anthropic en cuanto encuentran una clave, en la configuración o en `ANTHROPIC_API_KEY` ([`AnthropicProvider.cs` líneas 113-114](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Providers.Anthropic/AnthropicProvider.cs#L113-L114)). Con una clave falsa, el host de esta lección envió la petición y recibió `AnthropicUnauthorizedException`. Ahora el host del curso fija `Anthropic:ApiKey` en una cadena vacía, que el proveedor lee primero.

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

Los 22 errores HTTP son el fallo de la lección 4: sin `routes_to`, sin ninguna guarda que capture la pregunta, y con un respaldo que necesita el modelo. La guarda de álgebra responde a dos, el #18 y el #42, sin modelo. De los 39 prompts enviados a una intención, los siete que van a `DiatonicChordsSkill` son los únicos que necesitan un modelo: suman los seis fallos y uno de los aprobados.

## Una skill que necesita un modelo

`DiatonicChordsSkill` es lo que GA llama una skill de Path B: un modelo lee [`skills/diatonic-chords/SKILL.md`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/diatonic-chords/SKILL.md) y se espera que calcule los acordes llamando a la herramienta `ga_dsl_eval` con la closure `domain.diatonicChords`. Su cliente de chat siempre es de Anthropic, sea cual sea el modelo que use el resto del chatbot ([`DefaultChatClientFactory.cs` líneas 45-49](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Extensions/DefaultChatClientFactory.cs#L45-L49)). Sin clave, crear el cliente lanza una excepción:

```text
== #10 What are the diatonic chords in G major: the intent's answer and the skills' log lines
  | I encountered an error processing your request. Please try again.
Error SkillMdDrivenSkill: SkillMdDrivenSkill [diatonic-chords] failed — tools=15, message head="What are the diatonic chords in G major" (InvalidOperationException)
Warning DiatonicChordsSkill: DiatonicChordsSkill: LLM produced an answer without invoking ga_dsl_eval. Closure domain.diatonicChords should have been called. Evidence: (no exception)
```

Dos capas gestionan el fallo, y no se ponen de acuerdo sobre lo que ha pasado:

- La skill interna, [`SkillMdDrivenSkill`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/SkillMdDrivenSkill.cs#L204-L226), captura la excepción, la registra y devuelve "I encountered an error processing your request. Please try again." (he encontrado un error al procesar tu petición; inténtalo de nuevo) con confianza 0.
- El envoltorio, [`SkillMdDrivenWrapperBase`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/SkillMdDrivenWrapperBase.cs#L98-L152), recibe ese texto como una respuesta normal. No encuentra ninguna llamada a `ga_dsl_eval` en la evidencia y registra que el modelo "produced an answer" (produjo una respuesta) sin la herramienta; no se llegó a ningún modelo. Su propio texto de degradación, "I couldn't list the diatonic chords for that key right now. Please try again." (ahora mismo no he podido enumerar los acordes diatónicos de esa tonalidad; inténtalo de nuevo), sale de su bloque catch, que se ejecuta cuando falla la construcción de la skill interna o cuando la skill interna lanza una excepción ([líneas 154-176](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/SkillMdDrivenWrapperBase.cs#L154-L176)); aquí la skill interna ha devuelto su respuesta con normalidad.

Ese texto del envoltorio es justo aquel para el que se escribió el marcador de backend degradado de GA: el comentario de `BackendDegradedMarkers` lo cita como una de sus fuentes. El texto interno no es un marcador, así que el control puntúa los siete prompts como seis fallos y un aprobado en lugar de siete veces "sin señal". Antes de que el curso descargara `skills/`, la construcción de la skill interna fallaba por la falta del SKILL.md, el bloque catch del envoltorio devolvía su propio texto, y los siete se marcaban como degradados; con el archivo en su sitio, el detector no los ve. El flujo de trabajo diario de GA proporciona un endpoint de Ollama y ninguna clave de Anthropic, así que sus ejecuciones deberían tomar el mismo camino con estos prompts (*por verificar*: las instantáneas del 2026-09-25 al 2026-09-29 están todas marcadas como degradadas, y ninguna enumera sus fallos por prompt).

## Qué demuestra un aprobado

El comentario de GA dice lo que los invariantes no ven: la calidad. El curso mide cuánto ven, con dos pruebas del propio control:

- **Otras respuestas.** A cada prompt que pasa se le aplican sus invariantes a las otras 31 respuestas distintas de la ejecución. La respuesta a otra pregunta no siempre es errónea para esta, pero un invariante que acepta muchas de ellas dice poco de la suya.
- **Un semitono más arriba.** Cuando el prompt nombra una nota o un acorde, su respuesta se comprueba de nuevo con cada nombre de nota y cada fundamental de acorde subidos un semitono: `Cmaj7` pasa a ser `C#maj7`, y `Bb`, `B`. El resultado es una respuesta sobre otra altura, errónea para la pregunta que se hizo. Para un prompt que no nombra ninguna altura, como "What is Dorian" (¿qué es el dórico?), la respuesta desplazada seguiría siendo correcta, y la columna dice n/a. El curso solo reconoce un nombre de nota en la pregunta cuando empieza por mayúscula, porque "a" también es una palabra inglesa: el #30, "notes in c major", nombra C mayor en minúsculas y recibe n/a, un caso que se le escapa a la prueba del curso.

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

Algunas aceptaciones son justas. Hijaz, un maqam de la música árabe, suele aproximarse en el temperamento igual de doce notas con la escala que los libros occidentales llaman frigio dominante, y la familia de la menor armónica, la respuesta #3, la incluye. La mayoría no lo son. "What notes are in a C major triad" (¿qué notas tiene una tríada de C mayor?) acepta 24 de las otras 31 respuestas, y "What notes are in a G7 chord" (¿qué notas tiene un acorde de G7?), 17, porque sus listas `contains` son letras de notas, y un `"E"` que no distingue mayúsculas está en "the", un `"D"`, en "and", y un `"F"`, en "of". De las 224 cadenas esperadas del corpus, 84 tienen un solo carácter, y 81 de ellas son letras de notas.

La columna del semitono dice lo mismo desde el otro lado. Las respuestas del #56 al #59 fallan porque sus invariantes contienen un nombre de acorde, de "C major" a "D minor 9". Las demás fallan por pura casualidad ortográfica: subida un semitono, la respuesta de G7 dice "G# dominant 7 chord contains G#, C, D#, and F#", y falla solo porque ninguna de sus palabras contiene una `b`. Y el #51 pasa:

```text
== #51 How do I tune to drop C, the answer a semitone higher: GA pass, strict missing "C"
  | **Drop C# tuning** (low → high): **C# – G# – C# – F# – A# – D#**
  |
  | | String | Note | vs Standard |
```

`"C"` está en `C#`, y `"Drop C"` está en `Drop C#`. Otros cuatro pasan un semitono más arriba porque sus invariantes no nombran ninguna altura: "avoid" y "11" en el #14, una tensión o un 13 en el #15, y "Aeolian" o "arpeggio" en los dos prompts de arpegios. El mensaje de error del #31 no tiene ninguna nota que desplazar.

## Respuestas que el control acepta

Cinco de las respuestas que pasaron, con la cadena que dejó pasar a cada una. Las tres primeras son respuestas erróneas. Las dos últimas dan las notas correctas con una fórmula errónea, y el control solo lee el nombre de la escala.

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

El prompt está en la categoría `typo-tolerance` del corpus, bajo el comentario "Real users misspell. The router should still get them home." (los usuarios reales cometen erratas; aun así, el enrutador debería llevarlos a su destino). `ModesSkill` no reconoce "melodi minor", así que toma su rama por defecto y enumera los modos de la escala mayor, sin decir que no ha reconocido la familia ([`ModesSkill.cs` líneas 202-207](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ModesSkill.cs#L202-L207)). Todas las respuestas sobre una familia terminan con la misma sugerencia, la de preguntar por una familia concreta o por un solo modo: "Ask about a specific family ("modes of melodic minor", "harmonic major modes") or a single mode ("what is Lydian dominant?")" ([línea 449](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ModesSkill.cs#L449)), y esa línea basta para satisfacer el `contains_any` de la entrada ([`prompts.yaml` líneas 270-276](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Tests/Apps/GaChatbot.Api.Tests/Corpus/prompts.yaml#L270-L276)).

```text
== #31 DIATONIC CHORDS IN G MAJOR: pass
  | I encountered an error processing your request. Please try again.
"G" matches "processing" on line 1
```

El texto de error de la sección "Una skill que necesita un modelo", aceptado como los acordes diatónicos de G mayor ([líneas 316-322](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Tests/Apps/GaChatbot.Api.Tests/Corpus/prompts.yaml#L316-L322)).

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

La respuesta ciega a la tonalidad de la [lección 5](../05-improvisation-skill/) y de la issue de GA [#744](https://github.com/GuitarAlchemist/ga/issues/744): F jónico tiene un B♭ y G jónico un F♯, y ninguna de las dos notas está en la tonalidad de la progresión, A menor o C mayor. La entrada también aceptaría "arpeggio", una palabra de la pregunta. En `main`, el corpus ha ganado desde entonces una entrada para "which arpeggio fits C A Dm G" con `not_contains: ["A Aeolian"]`, escrita después de la ejecución del tracer del 2026-09-28 que dio lugar a la #744: una cadena que contiene una respuesta errónea es una comprobación más precisa que una cadena que debería contener una correcta.

```text
== #38 What is the whole tone scale: pass
  | **Whole Tone** is mode 1 of the **Whole Tone** family; on C its notes are `C D E F# G# Bb` (formula `1 2 3 #4 #5 #6`).
"Whole Tone" matches "Whole Tone" on line 1

== #39 What is the diminished scale: pass
  | **Diminished (Half-Whole)** is mode 1 of the **Diminished** family; on C its notes are `C Db Eb E F# G A Bb` (formula `1 b2 b3 b4 b5 bb6 bb7 bb8`).
"Diminished" matches "Diminished" on line 1
```

Nada comprueba si la fórmula concuerda con las notas; el ejercicio 4 sí lo hace.

## Una lectura más estricta

Las mismas cadenas se pueden leer de forma más estricta, sin cambiar el corpus. `StrictContains`, en [`Lesson8.cs`](https://github.com/spareilleux/learn/blob/main/code/ga-ai/GaAi/Lesson8.cs), aplica dos reglas: una cadena que empieza por un nombre de nota, como `G`, `F#`, `Bb`, `Cm` o `C major`, tiene que coincidir respetando las mayúsculas; y toda cadena tiene que aparecer aislada, sin ninguna letra, cifra ni alteración pegada a ninguno de sus extremos, de modo que `"C"` ya no coincide con `C#` ni con `Cmaj7`, y `"G"` ya no coincide con "processing".

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

La lectura estricta cambia un veredicto en las respuestas de la propia ejecución, el del mensaje de error del #31, y ese cambio es correcto. Las respuestas ajenas que acepta bajan de 169 a 69, y la respuesta del #51 subida un semitono ahora falla por la razón correcta: en ella no hay ninguna `C` aislada. El prompt de G7 acepta una respuesta en lugar de 17: la familia de la menor armónica, cuyas notas incluyen G, B, D y F.

Lo que no puede hacer es leer lo que los invariantes no nombran. Los #14, #15, #49 y #50 siguen pasando un semitono más arriba, y el #26 sigue aceptando la familia equivocada, porque sus cadenas no contienen ninguna altura que le falte a una respuesta errónea. El #67 sigue aceptando 12 respuestas: C, E y G aparecen aisladas en cualquier lista de las notas de C mayor. Un invariante que comprueba las notas de un acorde tiene que comparar conjuntos, "la respuesta nombra exactamente C, E y G", algo que las comprobaciones de subcadenas no pueden expresar. Y una lectura estricta tiene sus propios falsos fallos: "tension" ya no coincide con "tensions". En esta ejecución no se produjo ninguno, lo cual es un hecho sobre 41 respuestas, no una garantía.

## Hasta dónde llega el curso

- **No se prueba el enrutamiento.** El curso llama a cada intención directamente, así que `routes_to`, `routing_method`, el anclaje y las comprobaciones de la traza, la mitad del control que detecta los errores de enrutamiento, no se ejercitan. Tampoco los 22 prompts que necesitan el enrutador o un modelo, entre ellos los tres que califica un juez.
- **La prueba del semitono es un solo tipo de respuesta errónea.** Deja las palabras en paz y desplaza las alturas; no dice nada de una respuesta que nombra las notas correctas y saca la conclusión equivocada.
- **"Otras respuestas" mide lo específico que es un invariante, no si una respuesta es correcta.** Una respuesta ajena aceptada puede ser aceptable, como en el caso de Hijaz.
- **La lectura estricta es una propuesta del curso**, medida solo en esta ejecución. Adoptarla supondría un cambio en `EvaluatePromptAsync` y una revisión de las 224 cadenas del corpus.

## Comunicado upstream

- No se habían comunicado upstream cuando se escribió esta lección: el detector de backend degradado que no ve el error de una skill de Path B, la línea de log engañosa del envoltorio, la errata que recibe en silencio la escala mayor, las fórmulas posicionales del #38 y del #39, y las subcadenas que no distinguen mayúsculas de minúsculas. Están listados en el [diario](../journal/).

## Ejercicios

1. Añade "I encountered an error processing your request" a `BackendDegradedMarkers` en la versión portada del curso. ¿Qué imprime la línea de resumen de la primera tabla, y qué le pasa al #31?
2. Reescribe los invariantes del #26 para que la respuesta de la escala mayor falle y la familia de la menor melódica, la respuesta #2, pase. ¿Qué otras respuestas acepta tu versión?
3. El #61 pregunta "Are pitch classes 0,1,4 and 0,1,6 equivalent under inversion" (¿son equivalentes por inversión las clases de altura 0,1,4 y 0,1,6?). Respóndela, y después di qué cadenas de su `contains_any`, `["yes", "no", "Z", "equivalent", "inversion", "transposition", "different", "same", "related"]`, satisfaría una respuesta errónea.
4. Comprueba las fórmulas del #38 y del #39 frente a sus notas, letra por letra. ¿Qué grados no concuerdan, y qué fórmula corresponde a las notas de cada escala tal como están escritas? Lee [`ComputeFormulaFromNotes`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ModesSkill.cs#L779-L811) y di por qué falla con estas dos escalas.

<details>
<summary>Soluciones</summary>

1. `68 prompts: 5 skipped, 22 end in an HTTP error, 41 answered: 34 pass, 7 fail, 7 of them flagged as a degraded backend`. Los siete prompts diatónicos, el #31 incluido, pasan a ser `BACKEND_DEGRADED`, y la ejecución los da por "sin señal" en lugar de contar seis fallos y un aprobado. Comprobado con el programa del curso el 2026-09-29, añadiendo el marcador para una sola ejecución.
2. `contains: ["Melodic Minor", "Lydian Dominant", "Altered"]`, las cadenas del #2, todas obligatorias. La línea de la sugerencia nombra las dos primeras pero no la escala alterada, así que la respuesta de la escala mayor falla con `missing "Altered"`, y la respuesta del #2 pasa. De las otras respuestas de la ejecución, solo pasa la del #2. Comprobado con el programa del curso el 2026-09-29, sustituyendo la entrada para una sola ejecución. Una lectura estricta no ayudaría aquí: la línea de la sugerencia contiene "melodic minor" como palabras completas.
3. No. La inversión de {0,1,4} es {0,11,8}, que, transpuesta, da {0,3,4}; ni ella ni {0,1,4} son una transposición de {0,1,6}. Los dos conjuntos son clases de conjuntos distintas, 3-3 (014) y 3-5 (016) en la lista de Forte, con vectores interválicos <101100> y <100011>. Una respuesta errónea, "Yes, they are equivalent" (sí, son equivalentes), satisface "yes" y "equivalent", y "no" está en "not", "note" y "know", así que es probable que pase cualquier respuesta que alcance el `min_length` de la entrada, 50 caracteres. Resuelto a mano: sin modelo, el prompt termina en HTTP 500, así que el curso no tiene ninguna respuesta que comprobar.
4. #38: `#6` es A♯, y la nota es B♭; las notas tal como están escritas corresponden a `1 2 3 #4 #5 b7`. #39: `b4` es F♭ donde la nota es E, `b5` G♭ donde es F♯, `bb6` A𝄫 donde es G, `bb7` B𝄫 donde es A, y `bb8`, que no es un grado que escriba nadie, C𝄫 donde es B♭. Las clases de altura concuerdan todas; las letras no. Las notas tal como están escritas corresponden a `1 b2 b3 3 #4 5 6 b7`; los textos de jazz suelen escribir el E♭ como D♯, `1 b2 #2 3 #4 5 6 b7`, la fórmula que usa el oráculo de la lección 5. `ComputeFormulaFromNotes` compara la i-ésima nota con el i-ésimo grado de C mayor, por posición: eso funciona para una escala de siete notas escrita sobre siete letras, y da números de grado erróneos a una escala de seis u ocho notas. Derivar cada grado de la letra de la nota daría las fórmulas de arriba. Resuelto a mano a partir de la salida y del código del método; no se ha compilado contra GA (*por verificar*).

</details>

## Puntos clave

- Un conjunto de pruebas es en sí mismo una afirmación sobre el programa, y se puede poner a prueba: aplica sus comprobaciones a respuestas para las que no se escribieron, y a respuestas erróneas a propósito, y cuenta lo que pasa.
- El corpus de GA comprueba subcadenas sin distinguir mayúsculas de minúsculas. Más de un tercio de sus cadenas esperadas tienen un solo carácter, casi siempre una letra de nota, que aparece en la mayoría de las frases en inglés; sus invariantes aceptaron 169 respuestas ajenas, un mensaje de error y la familia de modos equivocada.
- Una respuesta sobre otra altura pasa cuando los invariantes no contienen ninguna altura, o contienen una como subcadena de otra: "C" está en "C#".
- La degradación elegante tiene que reconocerla el control. Una skill de Path B sin modelo responde con un texto que los marcadores de backend degradado de GA no conocen, así que sus fallos se puntúan como si fueran del chatbot.
- Leer las mismas cadenas como tokens completos, con los nombres de nota sensibles a las mayúsculas, reduce las aceptaciones ajenas a 69 sin cambiar aquí ningún veredicto correcto. Lo que las subcadenas no pueden expresar, como "exactamente estas notas", necesita una comprobación que analice la respuesta.

## Fuentes

- GuitarAlchemist/ga en [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `Tests/Apps/GaChatbot.Api.Tests/Corpus/prompts.yaml`, `Tests/Apps/GaChatbot.Api.Tests/Corpus/PromptCorpusTests.cs`, `.github/workflows/chatbot-qa-snapshot.yml`, `Common/GA.Business.ML/Agents/Skills/ModesSkill.cs`, `SkillMdDrivenSkill.cs`, `SkillMdDrivenWrapperBase.cs`, `DiatonicChordsSkill.cs`, `Common/GA.Business.ML/Agents/Plugins/SkillMdPlugin.cs`, `Common/GA.Business.ML/Extensions/DefaultChatClientFactory.cs`, `Common/GA.Providers.Anthropic/AnthropicProvider.cs`.
- El `main` de GA en [`fc76ad6`](https://github.com/GuitarAlchemist/ga/commit/fc76ad63cb70073330b6868d6e3c39307c5e262c) (2026-09-29): las nuevas entradas del corpus, entre ellas "which arpeggio fits C A Dm G", añadida en [`503d70d`](https://github.com/GuitarAlchemist/ga/commit/503d70d3bed961e71fa82c35dd35066a301040d5); la instantánea `state/quality/chatbot-qa/2026-09-29.json`.
- Allen Forte, *The Structure of Atonal Music* (Yale University Press, 1973), para los nombres de las clases de conjuntos del ejercicio 3.
