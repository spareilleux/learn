---
title: "Lección 12: Lo que responden las skills de progresión"
description: "El chatbot de Guitar Alchemist tiene dos skills que reciben una progresión de acordes: una responde con un texto fijo, la otra deja que el modelo sugiera el acorde siguiente a partir de una lista que ella misma calcula. El curso les hace sus propios prompts de ejemplo y pide el acorde siguiente de dos progresiones de manual en las 30 tonalidades: seis prompts que piden más luminosidad reciben la respuesta para oscurecer, G Em C recibe los acordes de C mayor en el commit fijado, y ninguna lista de una tonalidad menor contiene su dominante."
sidebar:
  label: 12. Lo que responden las skills de progresión
  order: 12
---

La [lección 11](../11-the-chords-the-key-skill-reads/) siguió una pregunta sobre la tonalidad. Lo más habitual es que un guitarrista tenga una progresión y quiera hacer algo con ella. El chatbot de GA tiene dos skills para eso. [`ProgressionMoodSkill`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ProgressionMoodSkill.cs) explica cómo hacer una progresión más oscura o más luminosa, con "zero LLM calls" (ninguna llamada al LLM): devuelve uno de dos textos fijos ([línea 7](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ProgressionMoodSkill.cs#L7)). [`ProgressionCompletionSkill`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ProgressionCompletionSkill.cs) sugiere el acorde siguiente: `KeyIdentificationService`, el servicio de la lección 11, "detects the key and diatonic set deterministically; the LLM selects and explains cadence candidates from that pre-computed set" (detecta la tonalidad y el conjunto diatónico de forma determinista; el LLM elige y explica candidatos de cadencia dentro de ese conjunto precalculado) ([líneas 11-12](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ProgressionCompletionSkill.cs#L11-L12)). Cada skill tiene un SKILL.md, [progression-mood](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-mood/SKILL.md) y [progression-completion](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-completion/SKILL.md), la otra superficie: el SKILL.md de ambiente le da al modelo el mismo catálogo, y el de continuación le hace llamar a `ga_key_identify`, una herramienta que ejecuta el mismo servicio. La skill que analizaría una progresión, con su tonalidad, sus números romanos y sus cadencias, es un borrador bloqueado a la espera de una herramienta `ga_analyze_progression` "not yet implemented in Common/GA.Business.ML/Agents/Mcp/" (todavía sin implementar en esa carpeta) ([`skills-dev/_pending-tools/progression-analysis/DRAFT.md` línea 20](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/progression-analysis/DRAFT.md#L20)).

Todos los enlaces a GA apuntan al commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), el commit fijado del curso, salvo los que nombran otro. En `main`, en [`5c3a52a`](https://github.com/GuitarAlchemist/ga/commit/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26) (2026-09-30), `ProgressionMoodSkill.cs`, los dos SKILL.md y el borrador no han cambiado; `ProgressionCompletionSkill.cs` solo difiere del commit fijado en una línea `using` y en un indicador que marca un rechazo. Lo que ha cambiado es el servicio al que llama, que la lección 11 compiló en [`6baf32e`](https://github.com/GuitarAlchemist/ga/commit/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40) contra el dominio fijado; el programa reutiliza ese proyecto, `GaKeysMain`. Las salidas proceden de:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l12
```

## Las dos skills

El programa aloja GaChatbot.Api dentro de su propio proceso, como en la lección 9, y enumera, de entre las intenciones que puede elegir el enrutador, las que llevan "progression" en el nombre:

```text
== The intents that take a chord progression
skill.progressionmood          ProgressionMoodSkill         15 example prompts
skill.progressioncompletion    ProgressionCompletionSkill   5 example prompts
```

La skill de ambiente no necesita modelo, así que el programa la llama como lo hace el chatbot, a través de su intención. La skill de continuación llama al modelo después del servicio; el programa ejecuta los pasos anteriores a la llamada y lee el prompt que construyen, y el modelo no se ejecuta.

## Más luminosa o más oscura

La skill de ambiente elige su texto con una sola prueba ([líneas 58-66](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ProgressionMoodSkill.cs#L58-L66)):

```csharp
    public Task<AgentResponse> ExecuteAsync(string message, CancellationToken cancellationToken = default)
    {
        var lower = message.ToLowerInvariant();
        var brighten = lower.Contains("brighter") || lower.Contains("uplift") || lower.Contains("happier");

        return Task.FromResult(brighten
            ? BrightenAnswer()
            : DarkenAnswer());
    }
```

El programa le hace sus 15 prompts de ejemplo, los que el enrutador compara con las preguntas, y anota lo que pide cada uno:

```text
== ProgressionMoodSkill's example prompts: what each asks for, and the answer it gets
prompt                                                     asks       gets
How do I make this progression sound darker?               darken     darken
Make this progression sound moodier                        darken     darken
How can I make my chords sound sadder?                     darken     darken
What can I do to make a song sound more melancholy?        darken     darken
How to add a darker feel to a chord progression            darken     darken
Techniques to make a major progression minor-sounding      darken     darken
Make my song sound brighter                                brighten   brighten
How to make a progression more uplifting                   brighten   brighten
Brighten up a minor key tune                               brighten   darken
Brighten this minor song                                   brighten   darken
How do I lift the mood of a minor progression?             brighten   darken
How does Mixolydian flavor brighten rock progressions?     brighten   darken
Use Lydian color to brighten a major progression           brighten   darken
Phrygian flavor to darken a progression                    darken     darken
What mode adds the most brightness to a major key tune?    brighten   darken
7 prompts ask to darken: 7 get the darken answer
8 prompts ask to brighten: 2 get the brighten answer
```

"Brighten" y "brightness" no contienen "brighter", y "lift the mood" no es "uplift". Seis de los ocho prompts que piden más luminosidad reciben las cinco maneras de oscurecer. Son los seis prompts de luminosidad añadidos el 2026-05-12 para corregir enrutamientos erróneos, como registran los comentarios de las [líneas 36-53](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ProgressionMoodSkill.cs#L36-L53): ahora el enrutamiento los lleva a la skill, y la skill responde lo contrario. El SKILL.md le da al modelo la misma regla, "pick the **brighten** branch when the query mentions brighter / uplifting / happier" (elige la rama de luminosidad cuando la pregunta menciona esas palabras) ([línea 36](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-mood/SKILL.md#L36)), aunque sus triggers incluyen "brighten" ([línea 17](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-mood/SKILL.md#L17)). Lo que hace un modelo con esa regla no se ejecuta aquí (*por verificar*).

## Los acordes que escriben los dos textos

El programa enumera las progresiones que cada texto escribe entre comillas invertidas y señala todo token que no sea ni un cifrado de acorde ni un número romano:

```text
== The progressions each text writes out
ProgressionMoodSkill, darken answer:
  C F G
  C Fm G
  C bA G   <- bA: neither a chord symbol nor a Roman numeral
  C bB F   <- bB: neither a chord symbol nor a Roman numeral
  C G F
ProgressionMoodSkill, brighten answer:
  I bVII IV I
skills/progression-mood/SKILL.md, the progressions written with chord names:
  C F G
  C Fm G
  C F Gm
  C Am F G
  C Am Ab G
  C Bb F
  C G F
```

`bA` y `bB` no son ninguna de las dos cosas: un cifrado de acorde escribe el bemol detrás de la letra, `Ab` y `Bb`, y un número romano lo escribe delante del numeral, `bVI` y `bVII` ([líneas 74 y 77](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ProgressionMoodSkill.cs#L74-L77)). El SKILL.md escribe `C Am Ab G` y `C Bb F` ([líneas 48](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-mood/SKILL.md#L48) y [51](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-mood/SKILL.md#L51)) y le pide al modelo "Reproduce the technique list verbatim" (reproduce la lista de técnicas al pie de la letra) ([línea 38](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-mood/SKILL.md#L38)). Las dos listas no difieren solo en la grafía. La segunda técnica para oscurecer es `IV → iv`, `vi → bVI` y `V → v` en el texto de C#; el SKILL.md tiene `IV → iv` y `V → v`, añade `bIII`, `bVI` y `bVII` de la tonalidad menor homónima y da tres ejemplos resueltos, uno de los cuales menciona `vi → bVI`. La segunda técnica para dar luminosidad eleva el cuarto grado, "#iv° actually" (en realidad, #iv°), o mantiene un IV con una #11 en el texto de C# ([línea 104](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ProgressionMoodSkill.cs#L104)); el SKILL.md usa un `IVmaj7#11` o un `II` mayor ([línea 60](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-mood/SKILL.md#L60)).

## La prueba de palabras clave

Cada skill tiene además un método `CanHandle`, una prueba sobre las palabras de la pregunta. En el commit fijado, nada lo llama fuera de los tests: el enrutador compara embeddings. En `main`, [`OrchestratorSkillIntent`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Common/GA.Business.Core.Orchestration/Intents/OrchestratorSkillIntent.cs#L29) se lo pasa al enrutador, que recurre a él cuando no puede calcular el embedding de la pregunta y le da la pregunta a la primera intención cuya prueba la acepta ([`SemanticIntentRouter.cs` línea 321](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Common/GA.Business.ML/Agents/Intents/SemanticIntentRouter.cs#L321)). Las pruebas de las dos skills no han cambiado en `main`. El programa pregunta a cada prueba por los prompts de ejemplo de su propia skill:

```text
== CanHandle, the keyword test main's router falls back on when it has no embeddings
ProgressionMoodSkill: 0 of 15 example prompts accepted
ProgressionCompletionSkill: 3 of 5 example prompts accepted
  rejected: What chord comes next after C G Am?
  rejected: Help me end Am F G
```

La prueba de la skill de ambiente devuelve `false` ([línea 56](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ProgressionMoodSkill.cs#L56)), así que sin embeddings `main` nunca llega a ella. El trigger de la skill de continuación ([líneas 35-37](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ProgressionCompletionSkill.cs#L35-L37)) contiene `what\s+comes\s+next`, que no coincide con "What chord comes next", y ningún "help me end", que el SKILL.md incluye entre sus triggers ([línea 17](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-completion/SKILL.md#L17)):

```csharp
    private static readonly Regex CompletionTrigger = new(
        @"\b(finish|complete|end\s+it|end\s+this|what\s+comes\s+next|next\s+chord|help\s+me\s+finish|how\s+(do\s+i|to)\s+end|what\s+should\s+follow|continue|extend)\b",
        RegexOptions.IgnoreCase | RegexOptions.Compiled);
```

## Lo que la skill de continuación le dice al modelo

`ExecuteAsync` lee los acordes con `ExtractChords`, puntúa las tonalidades con `Identify` y le pasa a `BuildPrompt` la primera tonalidad y la lista entera ([líneas 49-67](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ProgressionCompletionSkill.cs#L49-L67)). `BuildPrompt` nombra todas las tonalidades empatadas con la primera, pero toma los acordes que el modelo puede sugerir solo de la primera ([líneas 93-107](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ProgressionCompletionSkill.cs#L93-L107)):

```csharp
        var topTied = all.Where(c => c.MatchCount == top.MatchCount).ToList();
        var keyDesc = topTied.Count == 1
            ? top.Key
            : string.Join(" / ", topTied.Select(c => c.Key));
```

`BuildPrompt` es privado; el programa lo llama por reflexión e imprime lo que lee el modelo para el primer prompt de ejemplo de la skill, desde la progresión hasta las reglas, y después las dos sugerencias del ejemplo JSON con el que termina el prompt:

```text
== What the model reads for "What chord comes next after C G Am?", pinned
  | The input progression is: [C, G, Am]
  | Detected key: A minor / C major / E minor / G major  (3/3 chords diatonic)
  |
  | AVAILABLE DIATONIC CHORDS — you may ONLY suggest chords from this list:
  | Am, Bdim, C, Dm, Em, F, G
  |
  | Task: Suggest 2-3 chord completions (each 1-2 chords) that cadence naturally
  | to end or continue the progression in A minor / C major / E minor / G major.
  |
  | For each suggestion:
  |   - Name the cadence type (authentic, half, deceptive, or plagal)
  |   - Give the Roman numeral(s)
  |   - Write a one-sentence guitarist-friendly explanation
  |
  | IMPORTANT: Every chord you suggest MUST appear in the AVAILABLE DIATONIC CHORDS list.
  | You may substitute the plain V chord with V7 even if only V appears in the diatonic list
  | (this is the standard harmonic minor adjustment).
  |
  | { "chords": ["E7"], "cadence": "authentic", "roman": "V7-i", "explanation": "Strongest resolution back to Am." },
  | { "chords": ["G"],  "cadence": "half",      "roman": "bVII-i", "explanation": "Open loop, floats back to the top." }
```

La tonalidad que va primero decide la lista. En el commit fijado, `Identify` ordena las tonalidades por recuento y después por nombre ([`KeyIdentificationService.cs` líneas 177-178](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/KeyIdentificationService.cs#L177-L178)). En `main`, las ordena por el recuento más un peso para la cadencia final, y después pone primero la tonalidad cuya tríada de tónica abre la progresión, luego la tonalidad mayor y por último el nombre ([líneas 224-227](https://github.com/GuitarAlchemist/ga/blob/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40/Common/GA.Domain.Services/Tonal/KeyIdentificationService.cs#L224-L227)). Para `main`, el programa aplica las líneas de la skill al servicio de `main`; para el commit fijado, contrasta esas líneas con el prompt que escribe el propio `BuildPrompt`, en todas las preguntas de la lección.

## Los ejemplos de la propia skill

El programa hace los cinco prompts de ejemplo de la skill, y después la progresión sola del ejemplo del SKILL.md:

```text
== ProgressionCompletionSkill's example prompts: the key and the chords the model may suggest
"What chord comes next after C G Am?"
  a826864  reads C G Am; key: A minor / C major / E minor / G major (3/3)
           may suggest: Am, Bdim, C, Dm, Em, F, G
  6baf32e  reads C G Am; key: C major / G major / A minor / E minor (3/3)
           may suggest: C, Dm, Em, F, G, Am, Bdim
"How do I finish this progression: Em D C"
  a826864  reads Em D C; key: E minor / G major (3/3)
           may suggest: Em, F#dim, G, Am, Bm, C, D
  6baf32e  reads Em D C; key: E minor / G major (3/3)
           may suggest: Em, F#dim, G, Am, Bm, C, D
"Help me end Am F G"
  a826864  reads Am F G; key: A minor / C major (3/3)
           may suggest: Am, Bdim, C, Dm, Em, F, G
  6baf32e  reads Am F G; key: A minor / C major (3/3)
           may suggest: Am, Bdim, C, Dm, Em, F, G
"What should follow Dm G C?"
  a826864  reads Dm G C; key: A minor / C major (3/3)
           may suggest: Am, Bdim, C, Dm, Em, F, G
  6baf32e  reads Dm G C; key: C major / A minor (3/3)
           may suggest: C, Dm, Em, F, G, Am, Bdim
"Continue this progression: F C G"
  a826864  reads F C G; key: A minor / C major (3/3)
           may suggest: Am, Bdim, C, Dm, Em, F, G
  6baf32e  reads F C G; key: C major / A minor (3/3)
           may suggest: C, Dm, Em, F, G, Am, Bdim
"C G Am"
  a826864  reads C G Am; key: A minor / C major / E minor / G major (3/3)
           may suggest: Am, Bdim, C, Dm, Em, F, G
  6baf32e  reads C G Am; key: C major / G major / A minor / E minor (3/3)
           may suggest: C, Dm, Em, F, G, Am, Bdim
```

C G Am, el primer ejemplo de la skill y el único del SKILL.md, encaja en cuatro tonalidades: C mayor y A menor, y también G mayor y E menor, cuya escala tiene F♯ en lugar de F. En el commit fijado, A menor va primero por nombre; en `main`, C mayor, que abre la progresión. El SKILL.md describe otro resultado: "`TopCandidates: [{ Key: "C major", DiatonicSet: [C, Dm, Em, F, G, Am, B°] }, ...]` (also tied with A minor)" (empatada también con A menor) ([línea 86](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-completion/SKILL.md#L86)). En el commit fijado, A menor va primero, y G mayor y E menor también empatan; la lista escribe `Bdim`, no `B°`. Su respuesta de ejemplo sugiere después `Dm → G7` ([línea 92](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-completion/SKILL.md#L92)): G7 no está en la lista, y la primera restricción estricta del SKILL.md es "Every suggested chord must appear in `DiatonicSet`" (todo acorde sugerido debe estar en el conjunto diatónico) ([línea 96](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-completion/SKILL.md#L96)). Sobre los empates, el SKILL.md dice que las tonalidades relativas comparten el mismo conjunto diatónico y que un empate con otra tonalidad es raro, "very short progressions" (progresiones muy cortas) ([línea 56](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-completion/SKILL.md#L56)).

## El acorde siguiente en treinta tonalidades

El programa pregunta "What chord comes next after …?" (¿qué acorde viene después de…?) para I vi IV en las 15 tonalidades mayores y para i VI VII en las 15 menores, escritas como las escribe el manual, y compara la lista de la que el modelo puede sugerir con las siete tríadas de la tonalidad:

```text
== "What chord comes next after ...?" for two textbook progressions in the 30 keys

I vi IV             Cb Gb Db Ab Eb Bb F  C  G  D  A  E  B  F# C#
           a826864  =  x  e  x  x  =  x  =  x  =  =  x  e  r  r
           6baf32e  e  e  e  =  =  =  =  =  =  =  =  =  =  r  r

i VI VII            Ab Eb Bb F  C  G  D  A  E  B  F# C# G# D# A#
           a826864  =  e  e  =  =  =  =  =  =  =  =  =  r  r  r
           6baf32e  =  e  e  =  =  =  =  =  =  =  =  =  r  r  r

= the chords read as written, and the model may suggest the key's chords as the textbook spells them;
e the same chords, spelled from the enharmonic key; x other chords; r a chord dropped or read as another chord
a826864: 30 questions, = 15, e 4, x 6, r 5; a key of another scale tied at the top in 13 of the 25 read as written
6baf32e: 30 questions, = 20, e 5, x 0, r 5; a key of another scale tied at the top in 13 of the 25 read as written
```

- **`x`, el commit fijado, seis tonalidades mayores.** G Em C es I vi IV en G mayor y V iii I en C mayor, y las cuatro tonalidades de C G Am vuelven a empatar; A menor va primero por nombre, y el modelo solo puede sugerir los acordes de C mayor, sin D, la dominante de G mayor. También en G♭, A♭, E♭, F y E mayor va primero por nombre una tonalidad de la otra escala. En `main`, va primero la tonalidad cuya tríada de tónica abre la progresión: la fila no tiene ninguna `x`, aunque G♭ mayor se convierte en F♯ mayor (`e`).
- **`e`, escrita a partir de la tonalidad enarmónica.** D♭ B♭m G♭ empata ocho tonalidades, los cuatro nombres de la escala de D♭ mayor y los de la de G♭ mayor. En el commit fijado, A♯ menor va primero, y el modelo puede sugerir `A#m, B#dim, C#, D#m, E#m, F#, G#` para una pregunta escrita con bemoles; en `main`, C♯ mayor. Cuatro preguntas en el commit fijado, D♭ y B mayor y E♭ y B♭ menor; cinco en `main`, donde C♭, G♭ y D♭ mayor se convierten en B, F♯ y C♯ mayor, y E♭ y B♭ menor en D♯ y A♯ menor.
- **`r`, un sostenido perdido.** `ExtractChords` pierde el sostenido delante de un espacio o de un signo de interrogación ([#771](https://github.com/GuitarAlchemist/ga/issues/771)): F♯ D♯m B se lee F D♯m B, y en el commit fijado el modelo puede sugerir los acordes de A♭ menor, `Abm, Bbdim, Cb, Dbm, Ebm, Fb, Gb`.
- **Empates con otra escala.** Todo I vi IV leído tal como está escrito empata con la tonalidad una cuarta por encima, donde los tres acordes son V iii I: 13 de las 25 preguntas leídas tal como están escritas, no un caso raro de progresiones muy cortas.

```text
C major, I vi IV: "What chord comes next after C Am F?"
  a826864  reads C Am F; key: A minor / C major / D minor / F major (3/3)
           may suggest: Am, Bdim, C, Dm, Em, F, G
  6baf32e  reads C Am F; key: C major / F major / A minor / D minor (3/3)
           may suggest: C, Dm, Em, F, G, Am, Bdim
G major, I vi IV: "What chord comes next after G Em C?"
  a826864  reads G Em C; key: A minor / C major / E minor / G major (3/3)
           may suggest: Am, Bdim, C, Dm, Em, F, G
  6baf32e  reads G Em C; key: G major / C major / A minor / E minor (3/3)
           may suggest: G, Am, Bm, C, D, Em, F#dim
Db major, I vi IV: "What chord comes next after Db Bbm Gb?"
  a826864  reads Db Bbm Gb; key: A# minor / Bb minor / C# major / D# minor / Db major / Eb minor / F# major / Gb major (3/3)
           may suggest: A#m, B#dim, C#, D#m, E#m, F#, G#
  6baf32e  reads Db Bbm Gb; key: C# major / Db major / F# major / Gb major / A# minor / Bb minor / D# minor / Eb minor (3/3)
           may suggest: C#, D#m, E#m, F#, G#, A#m, B#dim
F# major, I vi IV: "What chord comes next after F# D#m B?"
  a826864  reads F D#m B; key: Ab minor / B major / Cb major / D# minor / Eb minor / F# major / G# minor / Gb major (2/3)
           may suggest: Abm, Bbdim, Cb, Dbm, Ebm, Fb, Gb
  6baf32e  reads F D#m B; key: B major / Cb major / F# major / Gb major / Ab minor / D# minor / Eb minor / G# minor (2/3)
           may suggest: B, C#m, D#m, E, F#, G#m, A#dim
G# minor, i VI VII: "What chord comes next after G#m E F#?"
  a826864  reads G#m E F; key: Ab minor / B major / C# minor / Cb major / E major / G# minor (2/3)
           may suggest: Abm, Bbdim, Cb, Dbm, Ebm, Fb, Gb
  6baf32e  reads G#m E F; key: Ab minor / G# minor / B major / Cb major / E major / C# minor (2/3)
           may suggest: Abm, Bbdim, Cb, Dbm, Ebm, Fb, Gb
```

## La dominante de una tonalidad menor

La lista son las siete tríadas de la tonalidad, las de la menor natural en una tonalidad menor ([líneas 39-45](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/KeyIdentificationService.cs#L39-L45)). El programa busca las tríadas sobre el quinto grado en la propia lista de cada tonalidad:

```text
== The dominant the list holds, in each key's own list
15 major keys: the major triad on the fifth degree in 15, the minor one in 0
15 minor keys: the major triad on the fifth degree in 0, the minor one in 15
A minor: Am, Bdim, C, Dm, Em, F, G
  the prompt's example suggests E7 ("V7-i"): E7 in the list: no; E: no
  and G as a half cadence ("bVII-i"): G is degree 7 of the list; a half cadence ends on degree 5, Em
```

Una cadencia en una tonalidad menor suele tomar la dominante de la menor armónica: E o E7 en A menor, con la sensible G♯. Ninguna lista de una tonalidad menor la contiene. El prompt solo la permite cuando ya está: "You may substitute the plain V chord with V7 even if only V appears in the diatonic list (this is the standard harmonic minor adjustment)" (puedes sustituir el V por V7 aunque en la lista diatónica solo aparezca V; es el ajuste habitual de la menor armónica) ([líneas 117-119](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ProgressionCompletionSkill.cs#L117-L119)); en una tonalidad menor, solo aparece v. Su propio ejemplo sugiere después E7 como V7–i para A menor ([línea 130](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ProgressionCompletionSkill.cs#L130)), un acorde que su lista no contiene, y G como semicadencia, "bVII-i" ([línea 131](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ProgressionCompletionSkill.cs#L131)): una semicadencia termina en V, "anything → V" (cualquier acorde → V) en el catálogo del SKILL.md ([línea 67](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-completion/SKILL.md#L67)), y G es el séptimo grado. El SKILL.md permite V7 en menor "even when only `v` appears" (aunque solo aparezca v) ([línea 71](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-completion/SKILL.md#L71)) y prohíbe cualquier acorde que no esté en la lista ([línea 96](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-completion/SKILL.md#L96)). En una tonalidad menor, el modelo no puede sugerir una cadencia auténtica sin romper una de las dos reglas.

## Hasta dónde llega el curso

- **No se ejecuta el modelo.** Lo que sugiere a partir de estas listas, y si sigue la regla del V7 o la lista, necesita el modelo (*por verificar*).
- **No se prueba el enrutamiento.** Qué preguntas llegan a las dos skills lo decide el modelo de embeddings; a la prueba de palabras clave solo se le pregunta por los propios ejemplos de las skills.
- **La skill de continuación de `main` no se ejecuta.** Sus líneas se aplican al servicio de `main` en `6baf32e`, compilado contra el dominio fijado; para el commit fijado, las mismas líneas se contrastan con `BuildPrompt` en las 36 preguntas.
- **La skill de análisis no existe.** El chatbot no tiene ninguna, ni en el commit fijado ni en `main`. La closure `domain.analyzeProgression` del DSL existe, y la herramienta `GaAnalyzeProgression` de GaMcpServer la llama ([`GaDslTool.cs` líneas 195-197](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GaDslTool.cs#L195-L197)), pero ninguna skill del chatbot lo hace; esta lección no la ejecuta.
- **Dos progresiones de manual**, en tríadas en estado fundamental.

## Comunicado upstream

- Se comunicaron después de escribir esta lección: la prueba de luminosidad, los acordes de los dos textos y la prueba de palabras clave de la skill de ambiente, en la issue de GA [#773](https://github.com/GuitarAlchemist/ga/issues/773); las listas escritas a partir de la tonalidad enarmónica, la dominante que falta en la lista de una tonalidad menor, el ejemplo del prompt, el ejemplo del SKILL.md y la prueba de palabras clave de la skill de continuación, en la [#774](https://github.com/GuitarAlchemist/ga/issues/774). Las listas tomadas de la primera tonalidad por nombre están corregidas en `main` por la [#729](https://github.com/GuitarAlchemist/ga/pull/729). Los sostenidos perdidos son la [#771](https://github.com/GuitarAlchemist/ga/issues/771), y el orden de las tonalidades con las mismas clases de altura tiene la misma causa que la [#772](https://github.com/GuitarAlchemist/ga/issues/772). Todos están listados en el [diario](../journal/).

## Ejercicios

1. Reescribe la prueba de la skill de ambiente para que sus 15 prompts de ejemplo reciban la respuesta que piden. El SKILL.md dice que se responda con la rama de oscurecer cuando aparecen los dos ambientes: ¿qué responde tu prueba a "How do I make a happier song sound darker?" (¿cómo hago que una canción más alegre suene más oscura?)?
2. Para "What chord comes next after G Em C?", la skill fijada ofrece los acordes de C mayor. ¿Qué regla, aplicada antes del nombre, da la lista de G mayor, y qué da para C G Am y para Am F G?
3. Cambia la lista de una tonalidad menor para que el modelo pueda sugerir una cadencia auténtica sin romper las reglas del prompt. ¿Qué acorde añades a la lista de A menor, qué permite entonces la regla del V7 del prompt, y qué tiene que cambiar en el SKILL.md?
4. Con la lista de A menor tal como está, ¿cuáles de las cuatro cadencias del SKILL.md ([líneas 64-69](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-completion/SKILL.md#L64-L69)) puede construir el modelo?

<details>
<summary>Soluciones</summary>

1. Busca primero las palabras de oscurecer, `dark`, `sad`, `moodier`, `melancholy` y `minor-sounding`, y después las raíces `bright`, `lift` y `happ`. "Brighten", "brightness", "lift the mood", "uplifting" y "happier" contienen cada una alguna de las raíces, y ninguno de los ocho prompts de luminosidad contiene una palabra de oscurecer ("lift the mood" contiene "mood", no "moodier"). "How do I make a happier song sound darker?" recibe entonces la respuesta para oscurecer, como pide el SKILL.md; la prueba del commit fijado responde con la de luminosidad, porque la pregunta contiene "happier". Resuelto a mano sobre los 15 prompts.
2. Prefiere la tonalidad cuya tríada de tónica es el primer acorde, como hace `main`. G Em C recibe la lista de G mayor, C G Am la de C mayor y Am F G la de A menor: la salida de arriba muestra que `main` pone primero G mayor, C mayor y A menor. Resuelto a partir de la salida.
3. Añade la tríada de dominante de la menor armónica, E para A menor: el quinto grado de `Key.Notes` como tríada mayor. La regla del prompt funciona entonces en una tonalidad menor igual que en una mayor: aparece V, así que el modelo puede escribir V7, y el ejemplo E7 del prompt se cumple. La restricción estricta del SKILL.md sigue prohibiendo E7, igual que prohíbe G7 en C mayor, que sugiere su propio ejemplo: necesita la misma excepción para V7 que el prompt. Resuelto a mano.
4. Solo la cadencia plagal, como iv–i, Dm–Am: el SKILL.md dice "In a minor key, substitute as needed" (en una tonalidad menor, sustituye según haga falta) ([línea 71](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-completion/SKILL.md#L71)). La cadencia auténtica (V → I) y la rota (V → vi) necesitan el V mayor, que no está en la lista. Una semicadencia termina en V, y la lista solo tiene v, Em, una dominante sin la sensible G♯. Resuelto a mano.

</details>

## Puntos clave

- Una respuesta fija también la elige una prueba: cuando esa prueba no ve "brighten", una pregunta bien enrutada recibe la respuesta contraria, y corregir el enrutamiento llevó la pregunta hasta el error.
- Una skill que restringe el modelo a una lista decide la respuesta con esa lista: en el commit fijado, los empates resueltos por nombre dan a G Em C los acordes de C mayor.
- Una lista y las reglas que hablan de ella tienen que coincidir: el prompt permite V7 cuando aparece V, y en una tonalidad menor nunca aparece.
- El ejemplo de un prompt o de un SKILL.md enseña al modelo: E7 fuera de la lista, una semicadencia que no termina en V, G7 en contra de la restricción estricta.
- Dos textos que deberían decir lo mismo acaban divergiendo: la respuesta de C# escribe `bA` y `bB`, el SKILL.md `Ab` y `Bb`, con técnicas distintas.

## Fuentes

- GuitarAlchemist/ga en [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `Common/GA.Business.ML/Agents/Skills/ProgressionMoodSkill.cs`, `Common/GA.Business.ML/Agents/Skills/ProgressionCompletionSkill.cs`, `Common/GA.Business.ML/Agents/KeyIdentificationService.cs`, `skills/progression-mood/SKILL.md`, `skills/progression-completion/SKILL.md`, `skills-dev/_pending-tools/progression-analysis/DRAFT.md`, `GaMcpServer/Tools/GaDslTool.cs`.
- GA en [`6baf32e`](https://github.com/GuitarAlchemist/ga/commit/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40), con commit del 2026-09-25 en UTC: `Common/GA.Domain.Services/Tonal/KeyIdentificationService.cs`, compilado por el curso. El `main` de GA en [`5c3a52a`](https://github.com/GuitarAlchemist/ga/commit/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26), con commit del 2026-09-30 en UTC: `OrchestratorSkillIntent.cs` y `SemanticIntentRouter.cs`, y la comparación de las dos skills, sus SKILL.md y el borrador.
- *Open Music Theory*, los capítulos sobre las cadencias, la séptima elevada de la escala menor y la mezcla modal.
