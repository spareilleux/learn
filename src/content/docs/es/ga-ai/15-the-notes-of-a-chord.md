---
title: "Lección 15: Las notas de un acorde"
description: "El chatbot de Guitar Alchemist deletrea sin modelo las notas de un acorde y nombra el acorde que forma una lista de notas. El curso le hace a su skill los 32 prompts de ejemplo, le pregunta por los 82 sufijos de su vocabulario y por 588 acordes sobre 21 fundamentales, y le devuelve cada uno de esos acordes como lista de notas. La grafía es la de un manual en todos los acordes salvo la dominante alterada. Lo demás lo decide la lectura: el artículo inglés a se lee como la fundamental A, tres prompts de ejemplo y 22 sufijos no se leen, un cifrado leído en parte recibe las notas de un acorde más pequeño, y la skill no reconoce ninguna de las 106 grafías con alteración doble o triple que se le devuelven. La herramienta MCP de la vía del SKILL.md lee 14 de los 51 cifrados."
sidebar:
  label: 15. Las notas de un acorde
  order: 15
---

La [lección 14](../14-what-the-substitution-skill-answers/) le pidió al chatbot un acorde para poner en lugar de otro. Esta lección le hace la pregunta más básica que puede hacerle un guitarrista: qué notas tiene un acorde, y qué acorde forma un conjunto de notas. El enrutador envía las dos a la intención `skill.chordinfo`, que ejecuta `ChordInfoSkill` ([`GaPlugin.cs` línea 36](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs#L36)). La skill no llama a ningún modelo: lee un cifrado de acorde y deletrea sus notas a partir de una fórmula, o lee una lista de notas y busca una fórmula que encaje. Para la vía del modelo, el SKILL.md [`chord-info`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/chord-info/SKILL.md) le da al modelo una sola herramienta MCP, `ga_chord_info`, y le dice que no deletree nunca un acorde de memoria ([`SKILL.md` línea 43](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/chord-info/SKILL.md#L43)); el plugin de GA registra la herramienta ([`GaPlugin.cs` línea 195](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs#L195)). La skill y la herramienta comparten dos archivos: `ChordVocabulary`, que asigna a cada sufijo una cualidad y a cada cualidad su fórmula, y `ChordSpelling`, que pone cada nota en su letra.

Todos los enlaces a GA apuntan al commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), el commit fijado del curso, salvo los que nombran otro. En `main`, en [`5c3a52a`](https://github.com/GuitarAlchemist/ga/commit/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26) (2026-09-30), `ChordInfoSkill.cs`, `ChordVocabulary.cs`, `ChordSpelling.cs`, `ChordMcpTools.cs` y el SKILL.md no han cambiado. Las salidas proceden de:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l15
```

## Los prompts de ejemplo de la propia skill

El programa arranca el host del chatbot como en la lección 12, toma la intención que elegiría el enrutador y le hace cada uno de sus 32 prompts de ejemplo ([`ChordInfoSkill.cs` líneas 29-98](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordInfoSkill.cs#L29-L98)). La skill prueba dos maneras de leer un nombre de acorde y luego una lista de notas, y se rinde cuando fallan las tres ([líneas 114-118](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordInfoSkill.cs#L114-L118), [líneas 154-169](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordInfoSkill.cs#L154-L169)):

```csharp
    private static (string Root, string Quality)? TryParse(string message)
    {
        var chordQuestion = ChordQuestionRegex().Match(message);
        if (chordQuestion.Success)
        {
            return (ChordVocabulary.NormalizeRoot(chordQuestion.Groups["root"].Value), ChordVocabulary.NormalizeQuality(chordQuestion.Groups["quality"].Value));
        }

        var compact = CompactChordRegex().Match(message);
        if (compact.Success)
        {
            return (ChordVocabulary.NormalizeRoot(compact.Groups["root"].Value), ChordVocabulary.NormalizeQuality(compact.Groups["quality"].Value));
        }

        return null;
    }
```

El programa lee lo que ha entendido la skill en las líneas de su evidencia, `Root:`, `Quality:` y `Notes:`, y compara las notas con las que deletrea un manual para cada prompt:

```text
== The skill's own example prompts
skill.chordinfo: ChordInfoSkill, 32 example prompts
"What is a C major chord?"  CanHandle yes
  C major: C E G
"What notes are in Dm7?"  CanHandle yes
  D minor 7: D F A C
"Notes in an F minor chord"  CanHandle yes
  F minor: F Ab C
"What chord contains C E G?"  CanHandle yes
  C major: C E G
"Spell a B7 chord"  CanHandle yes
  B dominant 7: B D# F# A
"What notes are in a Cmaj7?"  CanHandle yes
  C major 7: C E G B
"Tell me the tones in F#m7b5"  CanHandle no
  F# half-diminished: F# A C E
"tell me about Dm7"  CanHandle yes
  D minor 7: D F A C
"tell me about a Cmaj7 chord"  CanHandle yes
  C major 7: C E G B
"what makes a chord a major seventh"  CanHandle yes
  A major: A C# E
  the question names a quality, no root
"what makes a chord diminished"  CanHandle yes
  A major: A C# E
  the question names a quality, no root
"what makes a chord a dominant seventh"  CanHandle yes
  A major: A C# E
  the question names a quality, no root
"What chord is C E G"  CanHandle yes
  C major: C E G
"What chord is F A C E"  CanHandle yes
  F major 7: F A C E
"Which chord contains the notes G B D F"  CanHandle yes
  G dominant 7: G B D F
"What chord is C E G Bb D"  CanHandle yes
  C dominant 9: C E G Bb D
"anatomy of a D7sus4 chord"  CanHandle no
  no chord: "Could not parse a chord name from your question."
  the textbook: D G A C
"break down Gmaj13 for me"  CanHandle no
  G major 13: G B D F# A C E
"what is a C add 9 chord"  CanHandle no
  no chord: "Could not parse a chord name from your question."
  the textbook: C E G D
"give me the notes of an F#m7b5"  CanHandle yes
  F# half-diminished: F# A C E
"tones in a Bb diminished seventh"  CanHandle no
  no chord: "Could not parse a chord name from your question."
  the textbook: Bb Db Fb Abb
"What is C7b9"  CanHandle yes
  C dominant 7 flat 9: C E G Bb Db
"What is Cmaj9"  CanHandle yes
  C major 9: C E G B D
"What is Dm7b5"  CanHandle yes
  D half-diminished: D F Ab C
"What is F#m7"  CanHandle yes
  F# minor 7: F# A C# E
"What is Bbdim7"  CanHandle yes
  Bb diminished 7: Bb Db Fb Abb
"what notes are in a C major triad"  CanHandle yes
  C major: C E G
"what are the notes of an A minor triad"  CanHandle yes
  A minor: A C E
"what notes make up a G7 chord"  CanHandle yes
  G dominant 7: G B D F
"which notes form a B diminished triad"  CanHandle yes
  B diminished: B D F
"spell a G7 chord"  CanHandle yes
  G dominant 7: G B D F
"what notes are in an E major chord"  CanHandle yes
  E major: E G# B
The intent's answer is the skill's Result for 32 of 32
The textbook's notes for 26 of the 29 prompts that name a chord or its notes
CanHandle accepts 27 of 32
```

- **Tres preguntas sobre una cualidad reciben A mayor.** A "what makes a chord diminished" (qué hace que un acorde sea disminuido) se le responde "A major chord contains A, C#, and E", y lo mismo a los otros dos prompts "what makes a chord". La primera expresión regular busca una fundamental, una cualidad opcional y la palabra "chord" ([líneas 302-303](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordInfoSkill.cs#L302-L303)); su clase de caracteres para la fundamental, `[A-Ga-g]`, acepta el artículo "a", y "a chord" es la primera coincidencia de la frase:

```csharp
    [GeneratedRegex(@"\b(?<root>[A-Ga-g][#b]?)\s*(?<quality>major 13|minor 13|dominant 13|major 11|minor 11|dominant 11|major 9|minor 9|dominant 9|major 7|minor 7|dominant 7|major 6|minor 6|half[- ]diminished|altered dominant|major|minor|maj|min|diminished|dim|augmented|aug|sus[24]?|add9|7alt|alt|13|11|9|7|6)?\s*(?:chord|triad)\b", RegexOptions.CultureInvariant)]
    private static partial Regex ChordQuestionRegex();
```

La segunda expresión tropezó con el mismo artículo, y su comentario cuenta cómo se corrigió: la cualidad pasó a ser obligatoria ([líneas 310-314](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordInfoSkill.cs#L310-L314)). La primera conservó su cualidad opcional.

- **Tres prompts no se leen.** "anatomy of a D7sus4 chord" (anatomía de un acorde D7sus4): la expresión de los cifrados no tiene `7sus4`, y detrás de `7` exige un límite de palabra, que la `s` de `sus4` no deja. "what is a C add 9 chord" (qué es un acorde C add 9): la alternativa que existe es `add9`, sin espacio. "tones in a Bb diminished seventh" (notas de un Bb séptima disminuida): falta "chord" o "triad" para la primera expresión, y un cifrado para la segunda. La respuesta es "Could not parse a chord name from your question."
- **Los otros 26 son correctos,** incluidos el D♯ de B7 y el F♭ y el A♭♭ de B♭dim7.
- **`CanHandle` acepta 27 de 32.** Solo acepta un cifrado junto a las palabras "chord", "triad" o "note", o detrás de un inicio de frase como "what is" o "tell me about" ([líneas 100-110](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordInfoSkill.cs#L100-L110), [líneas 267-282](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordInfoSkill.cs#L267-L282)). Además de los tres prompts que la skill no lee, rechaza "Tell me the tones in F#m7b5" y "break down Gmaj13 for me", que la skill responde bien. En el commit fijado, el enrutador no llama a `CanHandle`; en `main`, recurre a este método cuando no puede calcular el embedding de la pregunta ([`SemanticIntentRouter.cs` línea 321 en `main`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Common/GA.Business.ML/Agents/Intents/SemanticIntentRouter.cs#L321)).

## Todos los sufijos que conoce el vocabulario

`ChordVocabulary.NormalizeQuality` hace corresponder 83 grafías de sufijo, incluida la vacía, con las cualidades de `GetFormula` ([`ChordVocabulary.cs` líneas 59-104](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/ChordVocabulary.cs#L59-L104)). Su comentario de documentación explica las dos ramas en mayúscula: `M` es mayor y no debe pasarse a minúsculas, porque se convertiría en `m`, menor:

```csharp
    /// <summary>
    ///     Normalises a quality suffix to its canonical form (the key <see cref="GetFormula"/> switches on).
    /// </summary>
    /// <remarks>
    ///     The uppercase <c>"M"</c> / <c>"M7"</c> arms are matched <b>case-sensitively before</b> the
    ///     lowercase fallback: <c>"M"</c> means major and must not fold through <c>ToLowerInvariant()</c>
    ///     to <c>"m"</c> (minor). This is the PR #80 fix; consolidating it here keeps the skill from
    ///     re-introducing the <c>"CM"</c> → C-minor regression.
    /// </remarks>
    public static string NormalizeQuality(string raw)
    {
        var trimmed = raw.Trim();
        return trimmed switch
        {
            "M"  => "major",
            "M7" => "major 7",
            _    => trimmed.ToLowerInvariant() switch
            {
                "" => "major",
```

El programa le pregunta a la skill por cada uno de los otros 82 sufijos, los 51 cifrados con "What notes are in C…?" y las 31 palabras con "What notes are in a C … chord?", e imprime los que la skill no lee igual que el vocabulario:

```text
== Every suffix the vocabulary knows
"What notes are in C+?"  the vocabulary: augmented, the skill: no chord
"What notes are in C5?"  the vocabulary: power, the skill: no chord
"What notes are in Cno3?"  the vocabulary: power, the skill: no chord
"What notes are in Cdom7?"  the vocabulary: dominant 7, the skill: no chord
"What notes are in Cma7?"  the vocabulary: major 7, the skill: no chord
"What notes are in CΔ7?"  the vocabulary: major, the skill: no chord
"What notes are in C-7?"  the vocabulary: minor 7, the skill: no chord
"What notes are in C°7?"  the vocabulary: diminished 7, the skill: no chord
"What notes are in Cmin7b5?"  the vocabulary: half-diminished, the skill: no chord
"What notes are in Cø?"  the vocabulary: half-diminished, the skill: no chord
"What notes are in Cø7?"  the vocabulary: half-diminished, the skill: no chord
"What notes are in C7+5?"  the vocabulary: dominant 7 sharp 5, the skill: dominant 7
"What notes are in a C power chord?"  the vocabulary: power, the skill: no chord
"What notes are in a C dominant chord?"  the vocabulary: dominant 7, the skill: no chord
"What notes are in a C diminished 7 chord?"  the vocabulary: diminished 7, the skill: no chord
"What notes are in a C diminished7 chord?"  the vocabulary: diminished 7, the skill: no chord
"What notes are in a C minor 7 flat 5 chord?"  the vocabulary: half-diminished, the skill: no chord
"What notes are in a C dominant 7 flat 5 chord?"  the vocabulary: dominant 7 flat 5, the skill: no chord
"What notes are in a C dominant 7 sharp 5 chord?"  the vocabulary: dominant 7 sharp 5, the skill: no chord
"What notes are in a C dominant 7 flat 9 chord?"  the vocabulary: dominant 7 flat 9, the skill: no chord
"What notes are in a C dominant 7 sharp 9 chord?"  the vocabulary: dominant 7 sharp 9, the skill: no chord
"What notes are in a C altered chord?"  the vocabulary: altered dominant, the skill: no chord
The skill reads 60 of 82 suffixes as the vocabulary does (51 symbols, 31 words)
NormalizeQuality("Δ7") returns "δ7", which GetFormula doesn't know
ga_chord_info reads 14 of the 51 symbols: M M7 maj m min dim aug 7 maj7 m7 min7 dim7 m7b5 min7b5
```

- **22 de 82 no se leen, o se leen como otra cualidad.** La expresión de los cifrados, que no distingue mayúsculas de minúsculas, no tiene `5`, `no3`, `dom7`, `ma7`, `-7`, `°7`, `ø`, `ø7` ni `min7b5` ([líneas 305-316](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordInfoSkill.cs#L305-L316)); el vocabulario los reconoce, pero la skill nunca se los pasa. Su comentario incluye `+` y "power 5/no3" entre las formas admitidas. `+` está en la alternancia, pero el `\b` que lo sigue necesita un carácter de palabra a uno de los dos lados, y en la pregunta a `+` le sigue un signo de interrogación. A la fórmula del power chord no se llega de ningún modo, ni con "C5" ni con "a C power chord". Las formas en palabras se detienen en la lista de la primera expresión, a la que le faltan, entre otras, "power", "diminished 7", "dominant 7 flat 5", y "dominant" o "altered" a secas. `7+5` se lee como una séptima de dominante, por la razón que explica la sección siguiente.
- **El `Δ7` del vocabulario no puede coincidir.** `NormalizeQuality` pasa el sufijo a minúsculas antes de su segundo switch, y `ToLowerInvariant` también pasa a minúsculas las letras griegas: la delta mayúscula de `Δ7` se convierte en `δ`, y ninguna rama está escrita `δ7`. El sufijo sale del switch sin cambios, y `GetFormula` le da a una cualidad desconocida una tríada mayor ([línea 140](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/ChordVocabulary.cs#L140)). Ninguna de las dos expresiones lee `Δ`, así que el chatbot ni siquiera llega hasta ahí.

```csharp
                // 7th family
                "7" or "dominant" or "dom7" or "dominant 7" => "dominant 7",
                "maj7" or "major 7" or "ma7" or "Δ7" => "major 7",
                "m7" or "min7" or "minor 7" or "-7" => "minor 7",
```

- **`ga_chord_info` lee 14 de los 51 cifrados,** como muestra la última línea; la sección sobre la herramienta vuelve sobre ello.

## Más allá del vocabulario

El programa pregunta por cifrados que no tienen entrada en el vocabulario, por un acorde con barra, por el signo de bemol `♭` y por dos frases que podría escribir un guitarrista:

```text
== Beyond the vocabulary
"What notes are in Cmaj7#11?"
  C major 7: C E G B
  the textbook: C E G B F#
"What notes are in C7#11?"
  C dominant 7: C E G Bb
  the textbook: C E G Bb F#
"What notes are in C7(b9)?"
  C dominant 7: C E G Bb
  the textbook: C E G Bb Db
"What notes are in Cm(maj7)?"
  C minor: C Eb G
  the textbook: C Eb G B
"What notes are in C6/9?"
  C major 6: C E G A
  the textbook: C E G A D
"What notes are in C7#5#9?"
  C dominant 7 sharp 5: C E G# Bb
  the textbook: C E G# Bb D#
"What notes are in C7sus4?"
  no chord: "Could not parse a chord name from your question."
  the textbook: C F G Bb
"What notes are in C/E?"
  no chord: "Could not parse a chord name from your question."
  the textbook: C E G
"What notes are in B♭7?"
  no chord: "Could not parse a chord name from your question."
  the textbook: Bb D F Ab
"What notes are in an E♭ major chord?"
  no chord: "Could not parse a chord name from your question."
  the textbook: Eb G Bb
"I am learning Cmaj7, what notes are in it?"
  A minor: A C E
  the textbook: C E G B
"Am I right that G7 has an F?"
  A minor: A C E
  the textbook: G B D F
```

- **Seis cifrados reciben las notas de un acorde más pequeño.** Detrás del sufijo, la expresión de los cifrados pide un límite de palabra y ninguna letra ([línea 315](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordInfoSkill.cs#L315)): `#`, `(`, `/` y `+` cumplen las dos condiciones. Cmaj7♯11 se responde como Cmaj7, C7(♭9) como C7, Cm(maj7) como Cm y C6/9 como C6, y nada en la respuesta indica que se haya descartado una parte. La skill de improvisación de la lección 5 leía Cmaj7♯5 como Cmaj7 de la misma manera (fila 23 del [diario](../journal/)).
- **C7sus4, C/E y el signo de bemol no se leen**, y la respuesta lo dice. `♭` no es la letra `b`.
- **"I am" y "Am I" dan A menor.** La expresión de los cifrados no distingue mayúsculas de minúsculas, así que "am" es la fundamental A con el sufijo `m`, y aparece en la frase antes que Cmaj7 o G7.

## Grafía: 21 fundamentales, 28 cualidades

La skill pone cada nota en una letra: la fórmula le da a cada nota su número de letras por encima de la fundamental, y `ChordSpelling.Spell` añade las alteraciones que llevan hasta la altura de la nota ([`ChordSpelling.cs` líneas 52-69](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Mcp/ChordSpelling.cs#L52-L69)):

```csharp
    public static string Spell(string root, int pitchClass, int letterSteps)
    {
        var rootLetter   = char.ToUpperInvariant(root[0]);
        var rootIndex    = Array.IndexOf(NaturalLetters, rootLetter);
        var targetLetter = NaturalLetters[(rootIndex + letterSteps) % NaturalLetters.Length];
        var targetNatural = NaturalPitchClasses[targetLetter];
        var normalized   = ((pitchClass % 12) + 12) % 12;
        var accidental   = ((normalized - targetNatural) % 12 + 12) % 12;

        return accidental switch
        {
            0  => targetLetter.ToString(),
            1  => $"{targetLetter}#",
            2  => $"{targetLetter}##",
            10 => $"{targetLetter}bb",
            11 => $"{targetLetter}b",
            _  => $"{targetLetter}{(accidental < 6 ? new string('#', accidental) : new string('b', 12 - accidental))}",
        };
```

El programa deletrea los mismos acordes a su manera, a partir de grados escritos en `Lesson15.cs`: un 3 está dos letras y cuatro semitonos por encima de la fundamental, y un ♭3, en la misma letra, un semitono más abajo. Le pregunta a la skill por las 28 cualidades que sabe leer, sobre las 21 fundamentales del vocabulario, de C a B más B♯, C♭, E♯ y F♭:

```text
== Spelling: 21 roots, 28 qualities
The skill spells 567 of 588 chords as the textbook does
  C7alt: skill C E F# G# Bb Db D#, textbook C E Gb G# Bb Db D#
  C#7alt: skill C# E# F## G## B D D##, textbook C# E# G G## B D D##
  Db7alt: skill Db F G A Cb Ebb E, textbook Db F Abb A Cb Ebb E
  … and 18 more
The chords that differ: 21 7alt
C7alt: Intervals: root, major third, flat fifth, sharp fifth, minor seventh, flat ninth, sharp ninth
Chords with a double or triple accidental: 175 of 588
```

- **Coinciden 567 de 588.** Los otros 21 son la dominante alterada, en todas las fundamentales. Su fórmula pone la quinta bemol en la letra de la cuarta, tres letras por encima de la fundamental en lugar de cuatro ([`ChordVocabulary.cs` línea 130](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/ChordVocabulary.cs#L130)): F♯ para C, cuando la quinta bemol de C es G♭. F♯ es una grafía habitual de la ♯11 de un acorde alterado, pero la evidencia de la skill llama a esa nota "flat fifth" (quinta bemol).
- **175 grafías tienen una alteración doble o triple,** como el A♭♭ de B♭dim7 o el F♯♯♯ de B♯ aumentado. Son correctas, y la sección siguiente se las devuelve a la skill.

## Las grafías de la propia skill, devueltas como listas de notas

Una pregunta en la que "what chord" o "which chord" va seguido de "is", "contains", "has" o "uses" pasa a la tercera lectura ([línea 322](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordInfoSkill.cs#L322)). La skill recoge todos los nombres de nota de la pregunta, se queda con entre 3 y 5 distintos y prueba cada uno como fundamental frente a 19 fórmulas ([líneas 171-223](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordInfoSkill.cs#L171-L223), [líneas 236-265](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordInfoSkill.cs#L236-L265)). Un nombre de nota es una letra, una alteración opcional y ninguna letra detrás:

```csharp
    [GeneratedRegex(@"(?<![A-Za-z])(?<note>[A-Ga-g][#b]?)(?![A-Za-z])", RegexOptions.CultureInvariant)]
    private static partial Regex NoteTokenRegex();
```

El programa lee por reflexión la lista de las 19 fórmulas de la skill y luego pregunta "What chord is …" con las notas que la skill deletreó para cada uno de los 588 acordes. Una prueba de ida y vuelta no necesita oráculo: una skill que deletrea un acorde debería reconocerlo en su propia grafía. Las últimas líneas preguntan por seis listas de notas elegidas por el programa:

```text
== The skill's own spellings, asked back as notes
It names 19 qualities from notes; not dominant 7 flat 9, dominant 7 sharp 9, altered dominant, dominant 11, major 11, minor 11, dominant 13, major 13, minor 13
a quality it names, single accidentals: 293 chords, named back 293, as another chord 0, not named 0
a quality it names, a double or triple accidental: 106 chords, named back 0, as another chord 58, not named 48
  "What chord is D# F## A#" → D# minor: D# F# A#
a quality it doesn't name, 3 to 5 notes: 42 chords, named back 0, as another chord 12, not named 30
  "What chord is C E G Bb Db" → no chord: "Could not parse a chord name from your question."
6 or 7 notes: 147 chords, named back 0, as another chord 3, not named 144
  "What chord is C E F# G# Bb Db D#" → no chord: "Could not parse a chord name from your question."
```

```text
== Lists of notes
"What chord is C E G# B" → no chord: "Could not parse a chord name from your question."
"What chord is C E G Bb Db" → no chord: "Could not parse a chord name from your question."
"What chord is C Eb Gb Bbb" → C diminished: C Eb Gb
"What chord is F# A# C##" → F# major: F# A# C#
"Which chord has a C, an E and a G?" → A minor 7: A C E G
"What chord is C E G B♭" → C major 7: C E G B
```

- **Alteraciones simples: la skill reconoce los 293.** Todos los acordes de las 19 fórmulas escritos sin doble alteración vuelven como ellos mismos.
- **Alteraciones dobles: ninguno de los 106.** La expresión de las notas admite una sola alteración y rechaza una letra detrás: `Bbb` se descarta, porque a `Bb` le sigue una `b`, y `C##` se lee como C♯, porque `#` no es una letra. "C Eb Gb Bbb", la grafía de Cdim7 que dan tanto la skill como la descripción de la herramienta, recibe el nombre de C disminuido; F♯ aumentado recibe el de F♯ mayor. El signo de bemol se pierde de la misma manera: C E G B♭ da C séptima mayor, la lectura errónea de la [#757](https://github.com/GuitarAlchemist/ga/issues/757).
- **7b9 y 7#9 no están entre las 19.** Tienen cinco notas, dentro del límite, pero "What chord is C E G Bb Db" recibe el rechazo aunque "What is C7b9" deletrea exactamente esas notas, y el corpus de prompts de GA hace los dos tipos de pregunta ([`prompts.yaml` líneas 462-468](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Tests/Apps/GaChatbot.Api.Tests/Corpus/prompts.yaml#L462-L468), [líneas 542-548](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Tests/Apps/GaChatbot.Api.Tests/Corpus/prompts.yaml#L542-L548)). "What chord is C E G# B" es el ejemplo que da el propio comentario de la lista para "7-with-altered-fifth" ([líneas 261-262](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordInfoSkill.cs#L261-L262)); es Cmaj7♯5, y la lista solo tiene la séptima de dominante con la quinta aumentada o disminuida.
- **Seis y siete notas se rechazan a propósito:** el comentario da la razón, un acorde de oncena o de trecena tiene varios nombres ([líneas 184-189](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordInfoSkill.cs#L184-L189)).
- **"Which chord has a C, an E and a G?" (¿qué acorde tiene un C, un E y un G?) da A menor séptima:** la expresión de las notas lee el artículo "a".

## ga_chord_info, la herramienta del SKILL.md

La herramienta lee un cifrado con su propia expresión, anclada y más corta que la de la skill ([`ChordMcpTools.cs` líneas 77-82](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Mcp/ChordMcpTools.cs#L77-L82)):

```csharp
    // Order matters in the alternation: longer prefixes first so `dim7` is
    // tried before `dim` and `m7b5` before `m7`. Without this ordering, input
    // "Cdim7" matches `dim` and leaves "7" unconsumed, failing the ^...$ anchor
    // and the whole regex. Same for "Cm7b5" → matches `m` and fails on "7b5".
    [GeneratedRegex(@"^(?<root>[A-Ga-g][#b]?)(?<quality>maj7|min7b5|min7|m7b5|m7|maj|min|m|dim7|dim|aug|7|M7|M)?$",
        RegexOptions.CultureInvariant)]
```

El programa le pregunta por los cifrados de la tabla de sufijos del SKILL.md ([`SKILL.md` líneas 60-72](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/chord-info/SKILL.md#L60-L72)) y por los cinco ejemplos de su propia descripción:

```text
== ga_chord_info, the tool of the SKILL.md
The SKILL.md's table lists 16 symbols, the tool reads 15
  Cdom7: "Could not parse 'Cdom7' as a chord symbol. Try C, Cm, Cmaj7, F#dim, Bbm7, etc."
The tool returns the notes its description gives for 5 of its 5 examples
```

- **La tabla incluye `Cdom7`,** y la herramienta lo rechaza: su expresión no tiene `dom7`.
- **14 de los 51 cifrados del vocabulario,** como mostró la sección sobre el vocabulario: tríadas, séptimas, `dim7` y `m7b5`. El SKILL.md lo reconoce: los acordes suspendidos y con notas añadidas, las novenas, oncenas y trecenas, los acordes con barra y las dominantes alteradas devuelven un error, y el modelo debe declinar ([líneas 95-102](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/chord-info/SKILL.md#L95-L102)); lo mismo ante una lista de notas, que no lee ninguna herramienta. El mismo chatbot deletrea Cmaj9 por la vía de la skill, y su SKILL.md pide al modelo que lo decline.
- **Donde la herramienta lee, acierta:** sus cinco ejemplos vuelven tal como los da su descripción.

## Hasta dónde llega el curso

- **No se ejecuta el modelo.** Saber si el enrutador semántico envía cada una de estas preguntas a `skill.chordinfo`, "I am learning Cmaj7" incluida, necesita los embeddings, y lo que escribe un modelo a partir de `ga_chord_info` necesita el modelo (*por verificar*).
- **Las grafías de manual son las del curso,** a partir de grados; para la dominante alterada, también se usa una grafía con ♯11.
- **La skill y la herramienta no se ejecutan en `main`.** Sus archivos no han cambiado allí; que respondan lo mismo en `main` se deduce de la lectura del diff.

## Comunicado upstream

- Se comunicaron después de escribir esta lección: en la issue de GA [#782](https://github.com/GuitarAlchemist/ga/issues/782), el artículo y "am" leídos como fundamentales, los prompts de ejemplo y los sufijos que la skill no lee, los cifrados leídos en parte, las alteraciones dobles y las fórmulas que faltan en la lectura de notas; en la [#783](https://github.com/GuitarAlchemist/ga/issues/783), la quinta bemol de la dominante alterada, el `Δ7` del vocabulario y la herramienta que lee 14 cifrados. B♭ leído como B es lo mismo que la [#757](https://github.com/GuitarAlchemist/ga/issues/757). Todos están listados en el [diario](../journal/).

## Ejercicios

1. Cambia la clase de la fundamental de la primera expresión a `[A-G]`. ¿Cuáles de los 32 prompts de ejemplo cambian, y qué responden entonces?
2. Deletrea B♯ aumentado como lo hace la skill y di qué responde a "What chord is" seguido de esa grafía.
3. Añade `7sus4` a la alternancia de la expresión de los cifrados sin cambiar nada más. ¿Qué responde entonces a "anatomy of a D7sus4 chord"?
4. Haz que la expresión de las notas acepte dos alteraciones, `bb` o `##`. ¿Por qué "C Eb Gb Bbb" sigue sin recibir el nombre de C séptima disminuida?

<details>
<summary>Soluciones</summary>

1. Los tres prompts "what makes a chord", y solo ellos: la primera expresión deja de coincidir, la expresión de los cifrados no encuentra ningún cifrado y la pregunta no tiene "what chord" ni "which chord" seguido de "is", "contains", "has" o "uses". Reciben "Could not parse a chord name from your question." en lugar de A mayor. Comprobado con las expresiones regulares de .NET frente a las expresiones compiladas de GA, fuera del programa del curso.
2. B♯ D♯♯ F♯♯♯: la tercera y la quinta están dos y cuatro letras por encima de B. La expresión de las notas lee B♯, D♯ y F♯, clases de altura 0, 3 y 6, y la skill responde "B# diminished chord contains B#, D#, and F#." Comprobado llamando a la skill compilada de GA, fuera del programa del curso.
3. "D major chord contains D, F#, and A.": `NormalizeQuality` no tiene ninguna rama para `7sus4` y lo devuelve sin cambios, y `GetFormula` le da a una cualidad desconocida una tríada mayor. Un sufijo que lee la expresión necesita una entrada en el vocabulario; si no, la respuesta es una tríada. Comprobado llamando al vocabulario compilado de GA, fuera del programa del curso.
4. `ChordVocabulary.PitchClasses` tiene 21 nombres, ninguno con dos alteraciones ([`ChordVocabulary.cs` líneas 23-32](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/ChordVocabulary.cs#L23-L32)), y la skill solo conserva los nombres que encuentra ahí. `Bbb` ya no lo descarta la expresión, sino el paso siguiente, y las otras tres notas siguen formando una tríada disminuida. Comprobado llamando al vocabulario compilado de GA, fuera del programa del curso.

</details>

## Puntos clave

- Una grafía correcta en 567 de 588 acordes no hace correctas las respuestas: lo que lee la skill decide qué acorde deletrea.
- Una clase de caracteres con letras minúsculas lee palabras inglesas: el artículo "a" y "am".
- Una coincidencia que se detiene en un límite de palabra responde por un acorde más pequeño que el que se pidió; una skill debería decir qué ha descartado, o declinar la respuesta.
- Una prueba de ida y vuelta no necesita oráculo: basta con devolverle a una función su propia salida.
- `ToLowerInvariant` no se limita al ASCII: Δ se convierte en δ.
- Recurrir por defecto a una tríada mayor convierte cada cualidad que nadie anotó en una respuesta segura de sí misma.

## Fuentes

- GuitarAlchemist/ga en [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `Common/GA.Business.ML/Agents/Skills/ChordInfoSkill.cs`, `Common/GA.Business.ML/Agents/ChordVocabulary.cs`, `Common/GA.Business.ML/Agents/Mcp/ChordSpelling.cs`, `Common/GA.Business.ML/Agents/Mcp/ChordMcpTools.cs`, `skills/chord-info/SKILL.md`, `Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs`, `Tests/Apps/GaChatbot.Api.Tests/Corpus/prompts.yaml`.
- El `main` de GA en [`5c3a52a`](https://github.com/GuitarAlchemist/ga/commit/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26), con commit del 2026-09-30 en UTC, para la comparación y `SemanticIntentRouter.cs`.
- *Open Music Theory*, los capítulos sobre los cifrados de acorde y los acordes de séptima.
