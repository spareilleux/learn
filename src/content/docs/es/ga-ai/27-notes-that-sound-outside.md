---
title: "Lección 27: Las notas que suenan fuera"
description: "La OutsideNotesSkill de Guitar Alchemist le dice a un guitarrista si una nota sobre un acorde es una nota del acorde, una tensión disponible o una nota a evitar, sin modelo. Frente a las escalas de acorde de un manual, declara sostenibles 4 notas que ninguna escala habitual contiene y hace de la b9 de un acorde de dominante una nota a evitar; cuenta la oncena entre las notas de los acordes de trecena, lee 27 de las 40 escrituras de acordes que conoce y ningún ♯ ni ♭, y escribe C7 con un A#."
sidebar:
  label: 27. Las notas que suenan fuera
  order: 27
---

El chatbot de GA responde a "why does F sound outside over Cmaj7?" con `OutsideNotesSkill`, escrita para cerrar el elemento del BACKLOG "Why does this sound outside?". Clasifica una nota frente a un acorde como nota del acorde, tensión disponible o nota a evitar, sin modelo, y presenta su regla como "the standard jazz-pedagogy definition and is derived **purely from the chord tones**" ([`OutsideNotesSkill.cs` líneas 12-35](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/OutsideNotesSkill.cs#L12-L35)). Esta lección contrasta esa regla con las escalas que un manual asocia a cinco acordes de séptima, y después examina los acordes a los que la skill la aplica y cómo lee la nota y el acorde en la pregunta.

Todos los enlaces a GA apuntan al commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), el commit fijado del curso. En el `main` de GA en [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/commit/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) (2026-10-01), `OutsideNotesSkill.cs` solo marca su rechazo con `Declined`, y `ChordVocabulary.cs` es el mismo archivo, así que el programa solo se ejecuta en el commit fijado. La salida procede de:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l27
```

## Cómo responde la skill

La skill busca un acorde después de "over", "against" u "on", toma la última palabra con forma de nota que lo precede y calcula el intervalo desde la fundamental del acorde. Una nota de la fórmula del acorde es una nota del acorde; una nota un semitono por encima de una nota del acorde es una nota a evitar; cualquier otra nota es una tensión disponible:

```csharp
        var formula = ChordVocabulary.GetFormula(quality);
        var chordPcs = formula.Intervals.Select(i => ((i % 12) + 12) % 12).ToHashSet();
        var rel = ((notePc - rootPc) % 12 + 12) % 12;

        if (chordPcs.Contains(rel))
        {
            var function = ChordToneFunction(formula, rel);
            return new Verdict(
                RelationKind.ChordTone,
                function,
                $"a chord tone — the {function}",
                $"It's part of the chord itself (the {function}), so it sounds fully consonant — " +
                "as inside as a note can be over this chord.");
        }

        var degree = ExtensionLabel(rel);
        // Avoid note = a semitone above a chord tone (forms a b9 clash with it).
        var clashPc = chordPcs.FirstOrDefault(ct => (ct + 1) % 12 == rel, -1);
```

Sobre un acorde de dominante, una nota a evitar recibe otro consejo: "exactly the kind of altered tension players reach for", "not a note to simply avoid" ([líneas 164-174](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/OutsideNotesSkill.cs#L164-L174)).

## La regla frente a un manual

Un manual no clasifica una nota frente al acorde solo, sino frente a las escalas que se tocan sobre él: jónica o lidia sobre un acorde de séptima mayor, dórica, eólica o frigia sobre una séptima menor, siete escalas sobre una séptima de dominante, locria o locria #2 sobre un acorde semidisminuido, y la escala disminuida tono-semitono sobre una séptima disminuida (`Usual` en `Lesson27.cs`). Una nota que ninguna de ellas contiene no es una tensión del acorde. Una nota un semitono por encima de una nota del acorde es una nota a evitar, salvo la b9 y la b13 de un acorde de dominante, que son sus tensiones alteradas. El programa clasifica las doce notas sobre cada acorde de las dos maneras:

```text
== The rule against a textbook: c chord tone, t available tension, a avoid note, o in none of the chord's usual scales
chord                        1    b9   9    #9   3    11   #11  5    b13  13   b7   7
Cmaj7              skill     c    a    t    t    c    a    t    c    a    t    t    c
                   textbook  c    o    t    o    c    a    t    c    o    t    o    c
Cm7                skill     c    a    t    c    a    t    t    c    a    t    c    a
                   textbook  c    a    t    c    o    t    o    c    a    t    c    o
C7                 skill     c    a    t    t    c    a    t    c    a    t    c    a
                   textbook  c    t    t    t    c    a    t    c    t    t    c    o
Cm7b5              skill     c    a    t    c    a    t    c    a    t    t    c    a
                   textbook  c    a    t    c    o    t    c    o    t    o    c    o
Cdim7              skill     c    a    t    c    a    t    c    a    t    c    a    t
                   textbook  c    o    t    c    o    t    c    o    t    c    o    t
cells 60: the same 42; avoid notes no usual scale holds 12; tensions no usual scale holds 4: #9 over Cmaj7, b7 over Cmaj7, #11 over Cm7, 13 over Cm7b5; avoid notes the textbook makes tensions 2: b9 over C7, b13 over C7
```

- **Las dos coinciden en 42 de las 60 notas, y en la práctica en 12 más.** La skill llama notas a evitar a esas 12 notas, que ninguna escala habitual contiene: en ambos casos, no hay que detenerse en ellas.
- **Cuatro notas que ninguna escala habitual contiene son "an available tension", "Safe to sustain as an extension".** Son la #9 y la b7 sobre Cmaj7, la #11 sobre Cm7 y la 13 sobre Cm7b5. Cada una está un semitono por debajo de una nota del acorde, donde la regla no mira. Eso solo no hace inutilizable una nota: la #11 sobre Cmaj7 está un semitono por debajo de la quinta, y la lidia la contiene. Lo que las cuatro tienen en común es que ninguna escala habitual del acorde las contiene.
- **La skill hace de la b9 y la b13 de C7 notas a evitar.** Para la b9, la respuesta de más abajo lo dice en su titular, y lo contrario en su explicación.

## Algunas respuestas

```text
== A few of OutsideNotesSkill's answers
why does Db sound outside over C7
  | **Db** over **C dominant 7**: an avoid note — the b9 (flat ninth).
  | It's the b9 (flat ninth), sitting a semitone above the root of the chord. That half-step rub is why it sounds outside — but over a dominant chord it's exactly the kind of altered tension players reach for (b9 (flat ninth) on the V), so it's usable if you resolve it, not a note to simply avoid.
why does D# sound outside over Cmaj7
  | **D#** over **C major 7**: an available tension — the #9 (sharp ninth).
  | It's the #9 (sharp ninth) — a non-chord tone, but it isn't a semitone above any chord tone, so it adds colour without clashing. Safe to sustain as an extension.
why does Bb sound outside over Cmaj7
  | **Bb** over **C major 7**: an available tension — the b7 (minor seventh).
  | It's the b7 (minor seventh) — a non-chord tone, but it isn't a semitone above any chord tone, so it adds colour without clashing. Safe to sustain as an extension.
why does A sound outside over Cm7b5
  | **A** over **C half-diminished**: an available tension — the 13 (thirteenth).
  | It's the 13 (thirteenth) — a non-chord tone, but it isn't a semitone above any chord tone, so it adds colour without clashing. Safe to sustain as an extension.
```

- **Db sobre C7 es "an avoid note — the b9", y luego "not a note to simply avoid".**
- **D# y Bb sobre Cmaj7, y A sobre Cm7b5, son "Safe to sustain as an extension".**

## La oncena en los acordes extendidos

```text
== F over C and its extended chords: the first line of the answer, and the chord's notes
chord    answer                                                                        notes
C        **F** over **C**: an avoid note — the 11 (natural eleventh).                  C, E, G
Cmaj7    **F** over **C major 7**: an avoid note — the 11 (natural eleventh).          C, E, G, B
Cmaj9    **F** over **C major 9**: an avoid note — the 11 (natural eleventh).          C, E, G, B, D
Cmaj11   **F** over **C major 11**: a chord tone — the perfect eleventh.               C, E, G, B, D, F
Cmaj13   **F** over **C major 13**: a chord tone — the perfect eleventh.               C, E, G, B, D, F, A
C7       **F** over **C dominant 7**: an avoid note — the 11 (natural eleventh).       C, E, G, A#
C9       **F** over **C dominant 9**: an avoid note — the 11 (natural eleventh).       C, E, G, A#, D
C11      **F** over **C dominant 11**: a chord tone — the perfect eleventh.            C, E, G, A#, D, F
C13      **F** over **C dominant 13**: a chord tone — the perfect eleventh.            C, E, G, A#, D, F, A
Cm7      **F** over **C minor 7**: an available tension — the 11 (natural eleventh).   C, Eb, G, Bb
Cm11     **F** over **C minor 11**: a chord tone — the perfect eleventh.               C, Eb, G, Bb, D, F
```

- **F es una nota a evitar sobre C, Cmaj7, Cmaj9, C7 y C9, un semitono por encima de E.** Sobre Cmaj11, Cmaj13, C11 y C13 pasa a ser "a chord tone — the perfect eleventh", aunque E sigue en el acorde. `ChordVocabulary` construye los acordes de oncena y de trecena apilando terceras hasta la oncena:

```csharp
        "dominant 11" => new("dominant 11", [0, 4, 7, 10, 14, 17], [0, 2, 4, 6, 8, 10], ["root", "major third", "perfect fifth", "minor seventh", "major ninth", "perfect eleventh"]),
        "major 11" => new("major 11", [0, 4, 7, 11, 14, 17], [0, 2, 4, 6, 8, 10], ["root", "major third", "perfect fifth", "major seventh", "major ninth", "perfect eleventh"]),
        "minor 11" => new("minor 11", [0, 3, 7, 10, 14, 17], [0, 2, 4, 6, 8, 10], ["root", "minor third", "perfect fifth", "minor seventh", "major ninth", "perfect eleventh"]),
        "dominant 13" => new("dominant 13", [0, 4, 7, 10, 14, 17, 21], [0, 2, 4, 6, 8, 10, 12], ["root", "major third", "perfect fifth", "minor seventh", "major ninth", "perfect eleventh", "major thirteenth"]),
        "major 13" => new("major 13", [0, 4, 7, 11, 14, 17, 21], [0, 2, 4, 6, 8, 10, 12], ["root", "major third", "perfect fifth", "major seventh", "major ninth", "perfect eleventh", "major thirteenth"]),
```

  En la armonía de jazz, un acorde de trecena de dominante o mayor omite la 11 justamente por ese roce, y un acorde de oncena omite la tercera.
- **Sobre Cm7 y Cm11, F es una tensión y una nota del acorde,** como en un manual: un acorde menor no tiene tercera mayor con la que la 11 pueda rozar.

## La lectura de la nota

```text
== "why does <note> sound outside over Cmaj7": the note the skill reads, for each way to write it
written      notes     read      misread   not read
natural      7         7         0         0
sharp, #     7         7         0         0
flat, b      7         7         0         0
sharp, ♯     7         0         7         0
flat, ♭      7         0         7         0
lowercase    7         0         0         7
not read right: C♯: C; D♯: D; E♯: E; F♯: F; G♯: G; A♯: A; B♯: B; C♭: C; D♭: D; E♭: E; F♭: F; G♭: G; A♭: A; B♭: B; c: no answer; d: no answer; e: no answer; f: no answer; g: no answer; a: no answer; b: no answer
```

- **Toda nota escrita con `#` o `b` se lee bien, incluidas E#, Fb, B# y Cb.**
- **Toda nota escrita con `♯` o `♭` se lee como la nota natural.** La nota es una letra, luego `#` o `b`, no seguida de una letra, un dígito o `#` ([líneas 295-299](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/OutsideNotesSkill.cs#L295-L299)): tras la letra viene `♭`, y la letra sola pasa a ser la nota. La lección 7 encontró lo mismo en los cifrados, comunicado en la [#757](https://github.com/GuitarAlchemist/ga/issues/757).
- **Una nota en minúscula no se lee en absoluto.** La expresión regular de la nota distingue mayúsculas, lo que también impide leer el artículo "a" como A; "why does f sound outside over Cmaj7" recibe el rechazo de la skill.

## La lectura del acorde

El acorde es la fundamental que sigue a la preposición y una serie de `maj`, `min`, `m`, `M`, `dim`, `aug`, `sus`, `add`, `alt`, `ø`, `°`, `Δ`, `+`, dígitos, `#` y `b`, sin distinguir mayúsculas:

```csharp
    // "<prep> <root><quality>" — prep is over/against/on; root is A–G + optional
    // accidental; quality is the trailing chord-symbol run (letters/digits/#/b/°/ø/+).
    [GeneratedRegex(@"(?<prep>\bover\b|\bagainst\b|\bon\b)\s+(?:a\s+|an\s+|the\s+)?(?<root>[A-G][#b]?)(?<qual>(?:maj|min|m|M|dim|aug|sus|add|alt|ø|°|Δ|\+|\d|#|b)*)",
        RegexOptions.IgnoreCase)]
    private static partial Regex ChordAfterPrepRegex();
```

El programa pregunta a la skill por F sobre C escrito de 45 maneras, y lista los acordes que lee de otro modo:

```text
== "why does F sound outside over C<chord>": the chord the skill reads, for each way to write it
written    read as                its notes          the chord's notes
C-         C                      C E G              C Eb G
C°         C °                    C E G              C Eb Gb
Co         C                      C E G              C Eb Gb
Cdom7      C                      C E G              C E G Bb
Cma7       Cm                     C Eb G             C E G B
CΔ7        C δ7                   C E G              C E G B
CΔ         C δ                    C E G              C E G B
C-7        C                      C E G              C Eb G Bb
Cmi7       Cm                     C Eb G             C Eb G Bb
Cm7♭5      C minor 7              C Eb G Bb          C Eb Gb Bb
C-7b5      C                      C E G              C Eb Gb Bb
Co7        C                      C E G              C Eb Gb A
C7♯9       C dominant 7           C E G A#           C Eb E G Bb
C7sus4     C 7sus4                C E G              C F G Bb
CmMaj7     C mmaj7                C E G              C Eb G B
Cm(maj7)   Cm                     C Eb G             C Eb G B
C7#11      C 7#11                 C E G              C E Gb G Bb
Cmaj7#11   C maj7#11              C E G              C E Gb G B
chords written 45: chords ChordVocabulary has 40, read right 27; chords it doesn't have 5, read right 0
```

- **27 de los 40 acordes que tiene `ChordVocabulary` se leen bien, y ninguno de los 5 que no tiene.**
- **La serie se detiene en cualquier otro carácter.** "-" hace leer C-7 como C, "o" hace leer Co7 como C, la "a" de ma7 y la "i" de mi7 hacen leer Cma7 y Cmi7 como Cm, y "(" hace leer Cm(maj7) como Cm. `♭` y `♯` también la detienen: Cm7♭5 queda Cm7 y C7♯9 queda C7. `NormalizeQuality` conoce `dom7`, `ma7` y `-7` ([`ChordVocabulary.cs` líneas 81-83](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/ChordVocabulary.cs#L81-L83)), pero la serie nunca se los pasa.
- **Lo que `NormalizeQuality` no conoce se convierte en C E G.** `°` solo no tiene caso, `Δ` pasa a minúscula y queda `δ`, como comunica la [#783](https://github.com/GuitarAlchemist/ga/issues/783), y 7sus4, mMaj7, 7#11 y maj7#11 no están en el vocabulario. `GetFormula` da una tríada mayor a cualquier calidad desconocida ([línea 140](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/ChordVocabulary.cs#L140)). La respuesta sigue nombrando el acorde por su sufijo, "C 7sus4", mientras clasifica F frente a C E G.
- **Como no se distinguen mayúsculas, "a" y "the" pueden convertirse en la fundamental.** En los prompts de ejemplo de más abajo, "over a minor chord" es A mayor, y "over a dominant chord" D mayor: la expresión toma "a" como artículo, y luego la "d" de "dominant" como fundamental.

## La ortografía de las notas del acorde

La evidencia de la skill lista las notas del acorde. Las nombra a partir de dos tablas de doce nombres, en sostenidos salvo si el acorde es menor o disminuido, o si su fundamental es una de seis tonalidades con bemoles ([líneas 226-241](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/OutsideNotesSkill.cs#L226-L241)), y no usa los pasos de letra que `ChordFormula` lleva para eso ([`ChordVocabulary.cs` líneas 144-156](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/ChordVocabulary.cs#L144-L156)):

```text
== The chord's notes in the skill's evidence, against one letter per chord step, on 12 roots
chord            symbol  right     the first that differs: the skill's, a textbook's
major                    11 of 12  F#: Gb Bb Db; F# A# C#
minor            m       8 of 12   Dbm: Db E Ab; Db Fb Ab
dominant 7       7       9 of 12   C7: C E G A#; C E G Bb
major 7          maj7    11 of 12  F#maj7: Gb Bb Db F; F# A# C# E#
minor 7          m7      8 of 12   Dbm7: Db E Ab B; Db Fb Ab Cb
half-diminished  m7b5    6 of 12   Dbm7b5: Db E G B; Db Fb Abb Cb
diminished 7     dim7    3 of 12   Cdim7: C Eb Gb A; C Eb Gb Bbb
augmented        aug     6 of 12   Eaug: E G# C; E G# B#
```

- **C7 se escribe C E G A#, F# mayor Gb Bb Db, y Cdim7 C Eb Gb A.** La mayoría de las séptimas disminuidas necesitan un doble bemol, un Cb o un Fb, que las tablas no tienen; 3 de 12 salen bien.

## Los prompts de ejemplo

```text
== OutsideNotesSkill's example prompts, and a few other ways to ask: CanHandle, and the first line of the answer
prompt                                             CanHandle  answer
why does F sound outside over Cmaj7                yes        **F** over **C major 7**: an avoid note — the 11 (natural eleventh).
why does that note clash over the chord            yes        Tell me a single note and a single chord and I'll say whether it's a chord tone, a tension, or an avoid note — e.g. "why does F sound outside over Cmaj7" or "is A a tension over Cmaj7".
is F an avoid note over Cmaj7                      yes        **F** over **C major 7**: an avoid note — the 11 (natural eleventh).
what is F over G7                                  no         **F** over **G dominant 7**: a chord tone — the minor seventh.
why does the b9 sound so tense over C7             yes        Tell me a single note and a single chord and I'll say whether it's a chord tone, a tension, or an avoid note — e.g. "why does F sound outside over Cmaj7" or "is A a tension over Cmaj7".
is A a chord tone or a tension over Cmaj7          yes        **A** over **C major 7**: an available tension — the 13 (thirteenth).
why does Bb sound outside over C major             yes        **Bb** over **C**: an available tension — the b7 (minor seventh).
is F# an avoid note or a tension over Cmaj7        yes        **F#** over **C major 7**: an available tension — the #11 (sharp eleventh).
why does F clash over a Cmaj7 chord                yes        **F** over **C major 7**: an avoid note — the 11 (natural eleventh).
why does the note clash over this chord            no         Tell me a single note and a single chord and I'll say whether it's a chord tone, a tension, or an avoid note — e.g. "why does F sound outside over Cmaj7" or "is A a tension over Cmaj7".
why does F sound outside over a minor chord        yes        **F** over **A**: an avoid note — the b13 (flat thirteenth).
why does F sound outside over a dominant chord     yes        **F** over **D**: an available tension — the #9 (sharp ninth).
why does F sound outside on top of Cmaj7           no         Tell me a single note and a single chord and I'll say whether it's a chord tone, a tension, or an avoid note — e.g. "why does F sound outside over Cmaj7" or "is A a tension over Cmaj7".
why does the 11 clash over Cmaj7                   yes        Tell me a single note and a single chord and I'll say whether it's a chord tone, a tension, or an avoid note — e.g. "why does F sound outside over Cmaj7" or "is A a tension over Cmaj7".
example prompts 10: CanHandle accepts 8, the skill refuses 3
```

- **La skill rechaza 3 de sus 10 prompts de ejemplo.** "why does that note clash over the chord" y "why does the note clash over this chord" no nombran ninguna nota, y "why does the b9 sound so tense over C7" nombra un grado: los grados quedan fuera del alcance de la skill ([líneas 31-34](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/OutsideNotesSkill.cs#L31-L34)), pero ese prompt es uno de sus ejemplos. "why does the 11 clash over Cmaj7" también recibe el rechazo.
- **`CanHandle` acepta 8 de los 10.** Necesita una de sus palabras clave, una preposición y un acorde ([líneas 65-86](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/OutsideNotesSkill.cs#L65-L86)): "what is F over G7" no tiene palabra clave, aunque la skill lo responde, y "why does the note clash over this chord" no tiene acorde. En el commit fijado el orquestador no llama a `CanHandle`; en `main`, el enrutador de intenciones lo consulta cuando no puede calcular el embedding de una pregunta ([lección 25](../25-what-reaches-the-transpose-skill/)).
- **"on top of" está en la lista de preposiciones de `CanHandle`, pero no en la expresión regular,** que quiere el acorde justo después de "on": "why does F sound outside on top of Cmaj7" recibe el rechazo.

## Hasta dónde llega el curso

- **Las escalas de acorde son las del curso.** `Usual` en `Lesson27.cs` lista las escalas que los manuales de jazz suelen dar a los cinco acordes. Las tríadas, los acordes de sexta y los acordes sus no se comparan con un manual: lo que se toca sobre ellos depende más de la tonalidad.
- **La regla se comprueba sobre C.** El veredicto de la skill solo depende del intervalo desde la fundamental ([línea 145](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/OutsideNotesSkill.cs#L145)); la ortografía se comprueba sobre 12 fundamentales.
- **No se ejecuta ningún enrutador.** La lección llama a la skill directamente.

## Ejercicios

1. Sobre Cm7, ¿por qué la skill llama a F# una tensión disponible? ¿Cuál de las escalas habituales de Cm7 lo contiene?
2. ¿Qué respondería la skill a "why does E sound outside over C7sus4"? ¿Qué diría un manual?
3. ¿Por qué "why does F sound outside over Cma7" recibiría "an available tension — the 11"?
4. ¿Cómo podría cambiar la regla para que la #9 sobre Cmaj7 deje de ser sostenible, mientras la #11 sigue siendo una tensión?

<details>
<summary>Soluciones</summary>

1. F# no está en Cm7, y no está un semitono por encima de una nota del acorde: F, un semitono por debajo, no está en el acorde. Así que cae en "an available tension". Ninguna de las escalas dórica, eólica y frigia contiene F#: todas tienen F.
2. 7sus4 no está en `ChordVocabulary`, así que `GetFormula` da C E G, y E es una nota del acorde, la tercera mayor. El C7sus4 de un manual es C F G Bb: la cuarta sustituye a la tercera, y E, un semitono por debajo de F, es precisamente la nota que evita el acorde sus. Razonamiento hecho sobre el código: el programa pregunta por F sobre C7sus4, no por E.
3. La serie se detiene en la "a" de "ma7", así que el acorde es Cm. Sobre C Eb G, F está una cuarta por encima de la fundamental, no un semitono por encima de una nota del acorde, así que es una tensión. Razonamiento hecho sobre el código y la tabla de acordes, donde Cma7 se lee Cm.
4. Clasificar la nota frente a las escalas del acorde además de frente a sus notas: una nota ajena al acorde solo es una tensión si alguna escala habitual del acorde la contiene. La #11 sigue siendo una tensión sobre Cmaj7, porque la lidia la contiene, mientras que ninguna escala habitual contiene la #9.

</details>

## Puntos clave

- Una nota a evitar depende de la escala del acorde, no del acorde solo: una regla que solo mira las notas del acorde no distingue una nota inutilizable de una tensión.
- Cuando un titular y su explicación se contradicen, el usuario lee el titular.
- Una fórmula de acorde es una afirmación sobre la práctica: apilar terceras hasta la trecena mete en el acorde el roce que causa la oncena.
- Una expresión regular que captura parte de un símbolo necesita el mismo alfabeto que el vocabulario que lo interpreta.
- Escribe las notas de un acorde a partir de sus letras, no de doce nombres.

## Fuentes

- GuitarAlchemist/ga en [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `Common/GA.Business.ML/Agents/Skills/OutsideNotesSkill.cs`, `Common/GA.Business.ML/Agents/ChordVocabulary.cs`.
- El programa del curso: `code/ga-ai/GaAi/Lesson27.cs`.
