---
title: "Lección 28: Comparar mayor y menor"
description: "La TheoryComparisonSkill de Guitar Alchemist responde a una sola pregunta, la diferencia entre mayor y menor, con un texto fijo cuyas escalas son las de un manual. Sus expresiones regulares leen sus 7 prompts de ejemplo, pero 5 de las 20 formulaciones del curso; su respuesta a un par repetido sugiere una comparación que rechaza, las tonalidades paralelas que deja a RelativeKeySkill reciben el rechazo de esa skill, y sin embeddings el main de GA no le envía ninguno de sus ejemplos."
sidebar:
  label: 28. Comparar mayor y menor
  order: 28
---

El chatbot de GA responde a "What is the difference between major and minor" con `TheoryComparisonSkill`. La skill se escribió el 2026-05-16 porque ese prompt del corpus iba a `RelativeKeySkill`, recibía su texto con confianza 0,1 y luego esperaba a Ollama hasta agotar el tiempo ([`TheoryComparisonSkill.cs` líneas 12-18](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/TheoryComparisonSkill.cs#L12-L18)). Responde sin modelo, y para un solo par: sus observaciones dan como alcance "major vs minor (the broken prompt)" ([líneas 20-25](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/TheoryComparisonSkill.cs#L20-L25)). Esta lección busca qué formulaciones lee, contrasta su respuesta con un manual y pregunta al `main` de GA qué hace su chatbot con los propios ejemplos de la skill cuando nada puede calcular sus embeddings.

Todos los enlaces a GA apuntan al commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), el commit fijado del curso. En el `main` de GA en [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/commit/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) (2026-10-01), `TheoryComparisonSkill.cs` solo marca su rechazo con `Declined`, y `RelativeKeySkill.cs` también, con un nuevo `CanHandle` descrito más abajo: por eso `GaAi` pregunta a las skills en el commit fijado, y `GaMain` al host del chatbot de `main`, arrancado como en la [lección 25](../25-what-reaches-the-transpose-skill/). La salida viene de:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l28
dotnet run --project code/ga-ai/GaMain -c Release -- l28
```

## Cómo lee la skill una pregunta

`CanHandle` siempre dice que no: solo los embeddings del enrutador pueden elegir la skill. `ExecuteAsync` prueba cuatro expresiones regulares una tras otra, cada una en busca de dos de las palabras `major` y `minor`:

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

Dos palabras distintas reciben la comparación, con `major` primero; la misma palabra dos veces recibe una respuesta corta propia; sin coincidencia, un rechazo vacío ([líneas 77-111](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/TheoryComparisonSkill.cs#L77-L111), [líneas 151-165](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/TheoryComparisonSkill.cs#L151-L165)).

## Las formulaciones a las que responde

El programa le hace a la skill sus 7 prompts de ejemplo y 20 formulaciones del curso, y nombra la primera expresión regular que coincide:

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

- **Los 7 prompts de ejemplo reciben la respuesta, y 5 de las 20 formulaciones del curso.** El par puede venir en cualquier orden, y se leen "vs." y "Compare … with".
- **Una palabra de más y la pregunta se pierde.** Nada puede ir entre "between" y la primera palabra, ni entre las palabras y "and": "the major and minor scales" y "a major and a minor chord" se rechazan. También "Majors vs minors", donde una "s" va antes del espacio que esperan las expresiones regulares, y "How are major and minor different". El comentario sobre las expresiones regulares cuenta "X and Y difference" entre las formas que reconocen, pero ninguna la tiene: "Major and minor difference" se rechaza.
- **La aserción hacia atrás de `VsPattern` deja fuera más que tonalidades.** Rechaza una palabra precedida de una letra de la A a la G, una alteración opcional y un espacio, para dejar "C major vs C minor" a otra skill. Como se ignoran mayúsculas y minúsculas, la "e" de "the" y el artículo "a" son esas letras: "Explain the major vs minor difference" y "Which sounds sadder, a major vs minor chord?" se rechazan.
- **No se compara nada más.** "Dorian vs Aeolian", "Harmonic minor vs melodic minor" y "Major pentatonic vs minor pentatonic" se rechazan, como anuncia el alcance de las observaciones.

## La respuesta frente a un manual

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

El programa vuelve a leer las escalas de la respuesta y las compara con las de un manual, y luego comprueba los pares relativos y los acordes que nombra:

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

- **Cada escala de la respuesta es la de un manual,** según sus intervalos como según sus grados, y también sus pares relativos y las calidades de I, IV y V.
- **"The single interval that flips is the third" solo vale para la menor melódica.** La menor natural, la que la respuesta escribe primero, difiere de la mayor en los grados 3, 6 y 7, y la menor armónica en el 3 y el 6. La primera frase de la respuesta lo dice, "secondary differences at the 6th and 7th", y la frase que sigue a las fórmulas dice lo contrario.

## El mismo par dos veces

```text
== The same pair twice: the answer, the comparison it suggests, and the skill's answer to that
question         suggests             answer to the suggestion
Major vs major   major vs dorian      refused
Minor vs minor   minor vs dorian      refused
  | You asked to compare major to itself — there's no difference. Try comparing major to its opposite (major↔minor) or to a specific mode (e.g. "major vs dorian").
```

- **"Major vs major" recibe una sugerencia que la skill rechaza:** "major vs dorian", y "minor vs dorian" para menor. Sus expresiones regulares solo conocen `major` y `minor` ([línea 56](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/TheoryComparisonSkill.cs#L56)).

## Las tonalidades paralelas

El comentario de `VsPattern` dice que "C major vs C minor" es "a parallel-key question handled by RelativeKeySkill" ([líneas 67-69](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/TheoryComparisonSkill.cs#L67-L69)). `RelativeKeySkill` lee "relative" o "parallel" seguidos de "minor of" o "major of", y las armaduras ([`RelativeKeySkill.cs` líneas 52-70](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/RelativeKeySkill.cs#L52-L70)):

```text
== RelativeKeySkill, which VsPattern's comment says handles "C major vs C minor": confidence and the first line of the answer
question                                             confidence   answer
C major vs C minor                                   0.100        Ask about the relative or parallel key of a given major/minor key, or how many sharps/flats a key has.
What's the difference between C major and C minor    0.100        Ask about the relative or parallel key of a given major/minor key, or how many sharps/flats a key has.
Parallel minor of C major                            1.000        The parallel minor of **C major** is **C minor**.
```

- **Ninguna de las dos skills responde a "C major vs C minor".** `RelativeKeySkill` da su rechazo, con confianza 0,1, y solo responde a la pregunta en la forma "Parallel minor of C major".

## Sin embeddings, en main

El enrutador solo llega a la skill por los embeddings. El propio diagnóstico de enrutamiento de GA, del 2026-06-16, la sitúa como la mejor separada de sus 30 intenciones, ya que sus siete ejemplos son siete formulaciones de una misma pregunta, y pone "Major versus minor" lo más cerca de "Relative major of A minor", un ejemplo de `RelativeKeySkill` ([`routing-ambiguity-2026-06-16.md` líneas 53 y 93](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/state/quality/routing-diagnostic/routing-ambiguity-2026-06-16.md?plain=1#L53-L93)). El curso no tiene modelo para calcularlos. Sin modelo, el chatbot fijado respondió HTTP 500 a todas las preguntas de la [lección 25](../25-what-reaches-the-transpose-skill/); el enrutador de `main` pregunta a cada intención si coincide sin embeddings, y luego su enrutador de agentes recurre a palabras clave. El programa le hace al host de `main` los 7 prompts de ejemplo y tres de las formulaciones del curso:

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

- **Ninguno de los 7 prompts de ejemplo llega a la skill.** 6 reciben una búsqueda de voicings, con "major" o "minor" como modo y otras palabras de la pregunta como etiquetas; uno recibe el respaldo, "Our reasoning service is currently unavailable".
- **"Difference between a major and a minor chord" recibe "A minor chord contains A, C, and E."** `ChordInfoSkill` la acepta y lee el artículo "a" como fundamental, como había encontrado la [lección 15](../15-the-notes-of-a-chord/), comunicado en la [#782](https://github.com/GuitarAlchemist/ga/issues/782).
- **`main` le dio el arreglo a otra skill.** El `CanHandle` de `RelativeKeySkill` acepta ahora exactamente las formulaciones que leen sus expresiones regulares: "this predicate only serves the offline keyword fallback" ([líneas 50-63 en `main`](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Agents/Skills/RelativeKeySkill.cs#L50-L63)). El de `TheoryComparisonSkill` sigue siendo `false`.

## Hasta dónde llega el curso

- **No se ejecuta ningún enrutador con embeddings.** Las formulaciones que el chatbot desplegado envía a la skill dependen de sus embeddings.
- **El párrafo "Common associations" de la respuesta no se comprueba.** Él mismo dice que son "cultural shorthand, not absolutes".
- **En `main`, el programa hace 10 preguntas, no 27,** para que su ejecución sea corta.

## Ejercicios

1. ¿Por qué se rechaza "Explain the major vs minor difference", si "Major vs minor" recibe la respuesta?
2. ¿Qué cambio en `DifferencePattern` dejaría pasar "What is the difference between the major and minor scales"? ¿Qué otra formulación rechazada dejaría pasar?
3. ¿Para qué menor vale "the single interval that flips is the third"?
4. ¿Por qué `RelativeKeySkill` rechaza "C major vs C minor", si responde a "Parallel minor of C major"?

<details>
<summary>Soluciones</summary>

1. `VsPattern` rechaza "major" cuando lo preceden una letra de la A a la G y un espacio, y como se ignoran mayúsculas y minúsculas, la "e" de "the" es una de esas letras. "Major vs minor" empieza la pregunta: nada precede a "Major". `DifferencePattern` tampoco coincide: la pregunta no tiene "between".
2. Un artículo opcional delante de cada palabra, `(?:the\s+|a\s+)?`, después de "between" y después de "and". También dejaría pasar "Difference between a major and a minor chord", hacia una respuesta sobre escalas. Razonado a partir del código: el programa no ejecuta la expresión regular modificada.
3. La menor melódica, ascendente: solo difiere de la mayor en el grado 3. Las menores natural y armónica difieren también en el 6, y la menor natural en el 7.
4. Sus patrones exigen "relative" o "parallel" seguidos de "minor of" o "major of", o una pregunta de armadura. "C major vs C minor" no tiene nada de eso: recibe el rechazo.

</details>

## Puntos clave

- Siete ejemplos escritos de la misma forma solo prueban una formulación: una respuesta fija solo es alcanzable en la medida en que lo permiten las expresiones regulares que tiene delante.
- Un comentario que confía una pregunta a otro componente es una afirmación que hay que comprobar: la skill que nombra la rechaza.
- Una respuesta que sugiere una pregunta de seguimiento debería poder responderla.
- Una frase debe concordar con la tabla que tiene debajo.
- Una skill a la que solo llegan los embeddings se calla en cuanto los embeddings no están disponibles.

## Fuentes

- GuitarAlchemist/ga en [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `Common/GA.Business.ML/Agents/Skills/TheoryComparisonSkill.cs`, `Common/GA.Business.ML/Agents/Skills/RelativeKeySkill.cs`, `state/quality/routing-diagnostic/routing-ambiguity-2026-06-16.md`.
- GuitarAlchemist/ga en [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/tree/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a): el host del chatbot que arranca `GaMain`.
- Los programas del curso: `code/ga-ai/GaAi/Lesson28.cs`, `code/ga-ai/GaMain/Program.cs`, `code/ga-ai/Shared/ComparisonProbe.cs`.
