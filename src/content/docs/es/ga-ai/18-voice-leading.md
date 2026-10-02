---
title: "Lección 18: La conducción de voces"
description: "El chatbot de Guitar Alchemist responde sin modelo a las preguntas de conducción de voces, probando todos los emparejamientos posibles entre las notas de dos acordes. El curso compara cada total con el movimiento mínimo que encuentra un manual. Entre dos acordes con el mismo número de notas, el total siempre es el mínimo. Cuando el número difiere, la skill duplica la fundamental y mueve más de lo necesario en 1186 de 3072 respuestas, entre ellas uno de sus propios ejemplos, mientras que cada respuesta afirma que cualquier otro voicing mueve más. Solo lee bien 24 de 46 cifrados, pierde el sostenido, el bemol o el signo de disminuido que cierra la pregunta, lee CM7 como C menor séptima, escribe B bemol como A sostenido, y el respaldo sin conexión de GA nunca llega a ella."
sidebar:
  label: 18. La conducción de voces
  order: 18
---

La [lección 17](../17-the-capo-and-the-tunings/) preguntó dónde va la cejilla y cómo están afinadas las cuerdas. Una vez elegidos los acordes, la siguiente pregunta es cómo pasar de uno al siguiente. La responde la conducción de voces: cada nota de un acorde es una voz, y cada voz se mueve a una nota del acorde siguiente, lo menos posible. El enrutador envía "voice leading from C to F" (conducción de voces de C a F) a `skill.voiceleading`, que ejecuta `VoiceLeadingSkill`, registrada entre las skills de cejilla y de afinaciones ([`GaPlugin.cs` líneas 85-88](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs#L85-L88)). Se creó el 2026-05-14, como ellas, para resolver un "dealbreaker" (obstáculo insalvable) del backlog de GA, y no necesita modelo: prueba todos los emparejamientos de las notas de los dos acordes y se queda con el que menos se mueve ([`VoiceLeadingSkill.cs` líneas 6-23](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/VoiceLeadingSkill.cs#L6-L23)).

Todos los enlaces a GA apuntan al commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), el commit fijado del curso, salvo los que nombran otro. `VoiceLeadingSkill.cs` es idéntico en el `main` de GA en [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/commit/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) (2026-10-01), así que el programa solo le pregunta en el commit fijado. La salida procede de:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l18
```

## Qué prompts llegan a la skill

`CanHandle` devuelve `false`, con el comentario "semantic-routing only" (solo enrutamiento semántico) ([línea 49](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/VoiceLeadingSkill.cs#L49)). En `main`, cuando el enrutador no puede calcular el embedding de una pregunta, se la da a la primera intención, en orden de registro, cuya skill la acepta en `CanHandle` ([`SemanticIntentRouter.cs` línea 321](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Agents/Intents/SemanticIntentRouter.cs#L321), [`OrchestratorSkillIntent.cs` línea 29](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.Core.Orchestration/Intents/OrchestratorSkillIntent.cs#L29)). El programa arranca el host del chatbot como en la lección 15 y le pasa al `CanHandle` de cada skill los 10 prompts de ejemplo de la skill de conducción de voces:

```text
== Without embeddings: the first skill, in registration order, whose CanHandle accepts each example prompt
prompt                                       first skill that accepts it
voice leading from C to F                    none
smooth voice leading C to Am                 none
best voicing from G7 to Cmaj7                skill.chordvoicings
how do I voice lead Dm7 to G7                none
voice leading C major to G major             none
smoothest voicing from Em to A7              skill.chordvoicings
voice leading Fmaj7 to Bm7b5                 none
what's the smoothest voicing from D to A     none
voice lead C7 to F                           none
best way to move from G7 to C                none
skill intents 32; CanHandle of skill.voiceleading accepts 0 of its 10 example prompts
```

- **Sin embeddings, la skill nunca responde, aunque no necesita modelo.** Dos de sus ejemplos van a la skill de voicings de la [lección 16](../16-the-voicings-of-a-chord/), porque dicen "voicing": esa skill responde con digitaciones para un solo acorde, no con el paso de un acorde a otro.
- **En `main`, un rechazo puede llevar el indicador `Declined`,** "so a caller may route it to another handler" (para que quien llama pueda enviarlo a otro manejador) ([`GuitarAlchemistAgentBase.cs` líneas 347-352 en `main`](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Agents/GuitarAlchemistAgentBase.cs#L347-L352)). Los dos rechazos de la skill no lo llevan ([líneas 280-294](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/VoiceLeadingSkill.cs#L280-L294)).

## Cómo responde la skill

La skill lee dos cifrados a ambos lados de "to", "→", "->" o ">" ([líneas 51-57](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/VoiceLeadingSkill.cs#L51-L57)):

```csharp
    // Two-chord pattern: <chord A> to/→/-> <chord B>. The chord token allows
    // root + optional accidental + optional quality keyword + optional digit
    // + optional flat/sharp-with-digit modifiers (b5, #9, b9...) + optional
    // ° symbol for diminished.
    private static readonly Regex TwoChordPattern =
        new(@"\b(?<a>[A-Ga-g][b#♭♯]?(?:maj|min|m|dim|aug|sus|add|dom)?\d*(?:[b#♭♯]\d+)*°?)\s+(?:to|→|->|>)\s+(?<b>[A-Ga-g][b#♭♯]?(?:maj|min|m|dim|aug|sus|add|dom)?\d*(?:[b#♭♯]\d+)*°?)\b",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);
```

Convierte cada cifrado en clases de altura y luego empareja las notas de los dos acordes. Cuando un acorde tiene menos notas, repite su fundamental hasta que los dos tienen el mismo número de notas ([líneas 101-110](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/VoiceLeadingSkill.cs#L101-L110), [`Pad`, líneas 185-194](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/VoiceLeadingSkill.cs#L185-L194)):

```csharp
        // For an exhaustive minimum-cost matching, we permute the SHORTER chord
        // against subsets of the larger. To keep the explanation crisp, we pad
        // the smaller chord by repeating its root so |A| = |B| for assignment
        // — this is the standard voice-leading framing when voice counts
        // differ (e.g. triad → 7th chord adds a voice that gets the new tone).
        var n = Math.Max(chordA.Length, chordB.Length);
        var paddedA = Pad(chordA, n);
        var paddedB = Pad(chordB, n);

        var (bestPerm, bestCost) = FindBestAssignment(paddedA, paddedB);
```

`FindBestAssignment` prueba todas las permutaciones y se queda con la primera que da el menor total, con cada voz moviéndose por el camino más corto, de 6 semitonos como máximo ([líneas 139-183](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/VoiceLeadingSkill.cs#L139-L183)). La respuesta da el total, una tabla de las voces y una frase final: "This is the optimal pitch-class assignment — every other voicing of … requires more total semitone movement" (esta es la asignación óptima de clases de altura: cualquier otro voicing de … requiere más movimiento total en semitonos) ([línea 131](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/VoiceLeadingSkill.cs#L131)).

El programa lee el total y la tabla de cada respuesta. Nombra el acorde de partida y el de llegada que muestra la tabla, y compara el total con el **movimiento mínimo**: tantas voces como notas tiene el acorde con más notas, todas las notas de los dos acordes sonando, y la posibilidad de duplicar cualquier nota del acorde con menos notas. También cuenta los emparejamientos que alcanzan el total de la skill dentro de su propio marco, con la fundamental duplicada.

```text
== VoiceLeadingSkill's example prompts: the chords read, the total motion, and the least motion
prompt                                     asks           reads          total   least  best pairings
voice leading from C to F                  C → F          C → F          3       3      1
smooth voice leading C to Am               C → Am         C → Am         2       2      1
best voicing from G7 to Cmaj7              G7 → Cmaj7     G7 → Cmaj7     3       3      1
how do I voice lead Dm7 to G7              Dm7 → G7       Dm7 → G7       3       3      1
voice leading C major to G major           C → G          declined       -       -      -
smoothest voicing from Em to A7            Em → A7        Em → A7        5       4      1
voice leading Fmaj7 to Bm7b5               Fmaj7 → Bm7b5  Fmaj7 → Bm7b5  3       3      1
what's the smoothest voicing from D to A   D → A          D → A          3       3      1
voice lead C7 to F                         C7 → F         C7 → F         4       4      1
best way to move from G7 to C              G7 → C         G7 → C         4       4      1
```

- **Ocho ejemplos reciben el movimiento mínimo.** Entre C y F, la voz que está en C se queda, E sube a F y G sube a A: 3 semitonos.
- **"smoothest voicing from Em to A7" recibe 5 semitonos, cuando bastan 4.** Em tiene tres notas y A7 cuatro, así que la skill duplica E. Duplicar G o B en su lugar mueve 4 semitonos, y aun así la respuesta dice que cualquier otro voicing mueve más.
- **Se rechaza "voice leading C major to G major".** Detrás de un acorde tiene que haber espacios y "to", así que la palabra "major" después de C rompe la expresión.

## El movimiento mínimo, acorde por acorde

El programa pregunta "voice leading C… to …" para las 16 cualidades que construye la skill, sobre C y sobre cada una de las 12 fundamentales, y agrupa las respuestas por el número de notas de los dos acordes:

```text
== "voice leading C<quality> to <root><quality>": the 16 qualities the skill builds, on C and on each of the 12 roots
voices   prompts   read right   least motion   more than the least   most extra   several best pairings
3 → 3    432       432          432            0                     0            54
3 → 4    504       504          266            238                   5            69
3 → 5    216       216          34             182                   7            67
4 → 3    504       504          266            238                   5            69
4 → 4    588       588          588            0                     0            56
4 → 5    252       252          79             173                   5            88
5 → 3    216       216          34             182                   7            67
5 → 4    252       252          79             173                   5            88
5 → 5    108       108          108            0                     0            49
prompts 3072: closing on "every other voicing … requires more total semitone movement" 3072, more motion than the least 1186, several best pairings 607
by how much more: 1 semitone 512, 2 semitones 294, 3 semitones 240, 4 semitones 94, 5 semitones 24, 6 semitones 20, 7 semitones 2
the first answers with the most extra motion:
  Csus2 to Em9: 11 semitones, least 4
  Cm9 to Absus2: 11 semitones, least 4
  Cm to Emaj9: 10 semitones, least 4
  Cm to Em9: 10 semitones, least 4
  Cm to Fm9: 9 semitones, least 3
the first answers with the most best pairings:
  Cmaj9 to Em9: 7 pairings
  Cm9 to Abmaj9: 7 pairings
  Csus2 to Em9: 5 pairings
```

- **Entre dos acordes con el mismo número de notas, el total siempre es el mínimo.** Se prueban todas las permutaciones, y no hace falta duplicar nada.
- **Cuando el número de notas difiere, la fundamental es la nota equivocada para duplicar en 1186 respuestas.** La voz nueva tiene que llegar a la nota que le falta al acorde con menos notas, y hacerla salir de la fundamental puede costar hasta 7 semitonos más que hacerla salir de otra nota. De Csus2 a Em9, las dos voces añadidas salen de C: 11 semitonos, cuando bastan 4. El comentario de la skill llama a la duplicación de la fundamental "the standard voice-leading framing" (el planteamiento estándar de la conducción de voces), y la armonía a cuatro voces sí duplica primero la fundamental de una tríada. Pero entonces la respuesta es el mejor movimiento con la fundamental duplicada, no el movimiento mínimo.
- **La frase final aparece en las 3072 respuestas.** Es falsa en las 1186 en que otra duplicación mueve menos, y en las 607 en que otro emparejamiento dentro del propio marco de la skill mueve igual de poco.

## Los cifrados

`BuildChord` pasa la cualidad a minúsculas y luego la busca en una tabla de 16 cualidades ([líneas 224-252](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/VoiceLeadingSkill.cs#L224-L252)):

```csharp
    private static int[]? BuildChord(int root, string quality)
    {
        var q = quality.ToLowerInvariant().Trim();

        // Tone choices: 1, b3, 3, 4, b5, 5, #5, 6, b7, 7, b9, 9, #9, 11, #11, 13
        int[]? intervals = q switch
        {
            "" or "maj" or "major"           => [0, 4, 7],                     // major triad
            "m" or "min" or "minor" or "-"   => [0, 3, 7],                     // minor triad
            "dim" or "°" or "o"              => [0, 3, 6],                     // dim triad
            "aug" or "+"                     => [0, 4, 8],                     // aug triad
            "7"                              => [0, 4, 7, 10],                 // dom 7
            "m7" or "min7" or "-7"           => [0, 3, 7, 10],                 // min 7
            "maj7" or "major7" or "M7" or "Δ7" or "Δ"
                                             => [0, 4, 7, 11],                 // maj 7
            "m7b5" or "ø" or "ø7" or "half-dim" or "min7b5"
                                             => [0, 3, 6, 10],                 // half-dim
            "dim7" or "°7" or "o7"           => [0, 3, 6, 9],                  // dim 7
            "sus2"                           => [0, 2, 7],
            "sus4" or "sus"                  => [0, 5, 7],
            "6"                              => [0, 4, 7, 9],                  // maj 6
            "m6" or "min6"                   => [0, 3, 7, 9],                  // min 6
            "9"                              => [0, 4, 7, 10, 2],              // dom 9
            "maj9"                           => [0, 4, 7, 11, 2],
            "m9" or "min9"                   => [0, 3, 7, 10, 2],
            // Unknown quality — return null so the caller emits CannotParse
            // instead of pretending the chord is a major triad.
            _                                => null,
        };
```

El programa escribe cada cifrado sobre C, primero como primer acorde y luego como último:

```text
== Each chord symbol on C, as the first chord ("voice leading C<symbol> to F") and as the last ("voice leading F to C<symbol>")
written    means      first                  last
C          C          right                  right
Cmaj       C          right                  right
C major    C          declined               right
Cm         Cm         right                  right
Cmin       Cm         right                  right
C minor    Cm         declined               reads C
C-         Cm         declined               reads C
Cdim       Cdim       right                  right
C°         Cdim       right                  reads C
Co         Cdim       declined               declined
Caug       Caug       right                  right
C+         Caug       declined               reads C
Csus2      Csus2      right                  right
Csus4      Csus4      right                  right
Csus       Csus4      right                  right
C7         C7         right                  right
Cdom7      C7         declined               declined
Cm7        Cm7        right                  right
Cmin7      Cm7        right                  right
C-7        Cm7        declined               reads C
Cmaj7      Cmaj7      right                  right
CM7        Cmaj7      reads Cm7              reads Cm7
CΔ7        Cmaj7      declined               declined
CΔ         Cmaj7      declined               declined
Cmajor7    Cmaj7      declined               declined
Cm7b5      Cm7b5      right                  right
Cmin7b5    Cm7b5      right                  right
Cø         Cm7b5      declined               declined
Cø7        Cm7b5      declined               declined
Cdim7      Cdim7      right                  right
C°7        Cdim7      declined               reads Cdim
Co7        Cdim7      declined               declined
C6         C6         right                  right
Cm6        Cm6        right                  right
Cmin6      Cm6        right                  right
C9         C9         right                  right
Cmaj9      Cmaj9      right                  right
Cm9        Cm9        right                  right
Cmin9      Cm9        right                  right
Cadd9      Cadd9      declined               declined
C7sus4     C7sus4     declined               declined
C7b9       C7b9       declined               declined
C7#9       C7#9       declined               declined
CmMaj7     CmMaj7     declined               declined
C11        C11        declined               declined
C13        C13        declined               declined
symbols 46: read right as the first chord 24, as the last 24
```

- **La tabla lista más cifrados de los que deja pasar la expresión.** Después de la fundamental, la expresión toma una palabra entre `maj`, `min`, `m`, `dim`, `aug`, `sus`, `add` y `dom`, dígitos, alteraciones seguidas de dígitos y un `°` final. `Δ`, `ø`, `+`, `-`, `o`, "major7" y "dom7" nunca llegan a la tabla, o llegan con una forma que no figura en ella. Como primer acorde, se rechazan todos. Como último, `+` y `-` detienen la expresión, que se queda con la letra: "voice leading F to C+" recibe C mayor. Los demás se rechazan.
- **Las palabras que siguen al último acorde se ignoran.** "voice leading F to C minor" recibe C mayor, y "voice leading F to C major" sale bien por casualidad.
- **CM7 se lee como C menor séptima.** La tabla lista `M7`, pero la cualidad se pasa antes a minúsculas, así que `m7` coincide primero. "voice leading CM7 to FM7" mueve Cm7 a Fm7. C menor séptima tiene E♭ y B♭ donde C séptima mayor tiene E y B.
- **Se pierde un `°` final.** La expresión termina en `\b`, un límite de palabra, y `°` no es un carácter de palabra: "voice leading F to C°" recibe C mayor. Como primer acorde, `°` se lee, pero "C°7" se rechaza, porque `°` solo puede cerrar el cifrado.
- **Se rechazan siete acordes comunes:** add9, 7sus4, 7♭9, 7♯9, mMaj7, 11 y 13. El comentario dice que es a propósito: una revisión del 2026-05-14 encontró que las cualidades desconocidas se respondían como tríadas mayores ([líneas 216-223](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/VoiceLeadingSkill.cs#L216-L223)).

## Una fundamental con alteración

El programa escribe las diez fundamentales con alteración, en ASCII y con `♯` y `♭`, como primer acorde y como último:

```text
== A root with an accidental, first ("voice leading <root> to C") and last ("voice leading C to <root>", "… to <root>m")
notation   first    last     last, m   the root first, spelled   the last, misread as
ASCII #    5 of 5   0 of 5   5 of 5    C#, D#, F#, G#, A#        C, D, F, G, A
♯          5 of 5   0 of 5   5 of 5    C#, D#, F#, G#, A#        C, D, F, G, A
ASCII b    5 of 5   5 of 5   5 of 5    Db, Eb, Gb, Ab, A#        -
♭          5 of 5   0 of 5   5 of 5    Db, Eb, Gb, Ab, Bb        D, E, G, A, B
```

- **Al final de la pregunta se pierde un sostenido, o un bemol escrito `♭`.** El mismo `\b` falla detrás de `#`, `♯` y `♭`, y la expresión se queda con la letra: "voice leading from C to F#" recibe C → F. La primera línea de la respuesta nombra el acorde leído, así que un lector atento puede verlo. `b` es una letra, así que "Db" se lee entero, y con una `m` detrás de la alteración el límite cae después de la `m`. Las skills de cejilla y de afinaciones de la lección 17 tienen el mismo fallo.
- **El propio rechazo de la skill sugiere B°,** "Try a chord-symbol like C, Am, G7, Cmaj7, Dm7, F#m7b5, or B°", un cifrado que solo se lee como primer acorde.

## La grafía de las respuestas

La skill escribe las notas con sostenidos, salvo que uno de los dos cifrados lleve un bemol o que la pregunta diga "flat" ([líneas 85-86](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/VoiceLeadingSkill.cs#L85-L86), [líneas 261-266](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/VoiceLeadingSkill.cs#L261-L266)):

```csharp
    private static bool TokenHasFlats(string token) =>
        token.IndexOf('b', StringComparison.OrdinalIgnoreCase) > 0  // 'b' at position 0 is the note B, not a flat
        || token.IndexOf('♭') >= 0;

    private static string Spell(int pc, bool preferFlats) =>
        preferFlats ? FlatNames[((pc % 12) + 12) % 12] : SharpNames[((pc % 12) + 12) % 12];
```

El programa pregunta por ii7 a V7 y por V7 a Imaj7 en las 12 tonalidades mayores, y por V7 a i en las 12 menores, y lista las notas que la skill escribe de otro modo que su acorde:

```text
== Spelling: ii7 to V7 and V7 to Imaj7 in the 12 major keys, the notes spelled otherwise than in their chord
key   ii7 to V7                          V7 to Imaj7
C     as spelled                         as spelled
G     as spelled                         as spelled
D     as spelled                         as spelled
A     as spelled                         as spelled
E     as spelled                         as spelled
B     as spelled                         as spelled
F#    F for E#                           F for E#
F     A# for Bb                          A# for Bb
Bb    D# for Eb, A# for Bb               A# for Bb, D# for Eb
Eb    G# for Ab, A# for Bb, D# for Eb    as spelled
Ab    as spelled                         as spelled
Db    as spelled                         as spelled
```

```text
== Spelling: V7 to i in the 12 minor keys
key   V7 to i
Cm    D# for Eb
Gm    A# for Bb
Dm    as spelled
Am    as spelled
Em    as spelled
Bm    as spelled
F#m   F for E#
C#m   C for B#
G#m   G for F##
Fm    A# for Bb, G# for Ab
Bbm   A# for Bb, D# for Eb, C# for Db
Ebm   as spelled
prompts 36: every note spelled as in its chord 22
```

- **Una fundamental B♭ escrita en ASCII no cuenta como bemol.** `TokenHasFlats` busca una `b` sin distinguir mayúsculas de minúsculas, lo que encuentra la fundamental `B` de "Bb" en la posición 0, y la prueba exige una posición mayor que 0. Así que "F7 to Bbmaj7" da A♯ y D♯, y "Bb" como primer acorde se escribe A♯. Escrita `B♭`, sí cuenta.
- **Sin un bemol en la pregunta, una tonalidad con bemoles recibe sostenidos.** D7 a Gm da A♯ en lugar de B♭: la skill no conoce la tonalidad, solo los dos cifrados.
- **Doce nombres no bastan para escribir todos los acordes.** La skill tiene un nombre por clase de altura. En F♯ mayor, E♯ se escribe F. El B♯ de G♯7 se escribe C, y el F doble sostenido de D♯7 se escribe G.

## Otras formulaciones

```text
== Other phrasings
prompt                                         asks                   reads            verdict
how do I get from G7 to a C chord              G7 → C                 G7 → A           wrong chord
voice leading Dm7 to G7 to Cmaj7               Dm7 → G7 → Cmaj7       Dm7 → G7         reads 2 of 3 chords
voice leading CM7 to FM7                       Cmaj7 → Fmaj7          Cm7 → Fm7        wrong chord
voice leading G7 → C                           G7 → C                 G7 → C           right
voice leading G7 - C                           G7 → C                 declined         declined
voice leading from G7 into C                   G7 → C                 declined         declined
voice leading from C to F#                     C → F#                 C → F            wrong chord
voice leading from G to B°                     G → Bdim               G → B            wrong chord
smooth voice leading from C major to A minor   C → Am                 declined         declined
how do I voice lead Bb to Eb                   Bb → Eb                Bb → Eb          right
```

- **El artículo "a" se lee como el acorde A.** La expresión no distingue mayúsculas de minúsculas, así que en "how do I get from G7 to a C chord" (¿cómo paso de G7 a un acorde de C?) el acorde detrás de "to" es "a": la skill mueve G7 a A mayor.
- **Una progresión de tres acordes solo recibe su primer movimiento.** La expresión lee un solo par, y la respuesta no dice que se ha detenido.
- **"-" e "into" no se leen como "to",** y los acordes escritos con palabras se rechazan.

## Hasta dónde llega el curso

- **No se ejecutan ni el enrutador ni el modelo.** Saber qué intención elige el enrutador para estas preguntas en producción necesita los embeddings (*por verificar*).
- **El movimiento mínimo es la prueba del curso:** todas las notas de los dos acordes sonando, tantas voces como notas tiene el acorde con más notas. Un manual también puede omitir la quinta de un acorde de séptima, lo que movería aún menos, y sitúa las voces en registros. La skill y el curso trabajan los dos con clases de altura, así que aquí un "voicing" no tiene ni octava ni traste.
- **Otra vía de GA mueve voicings reales.** La herramienta MCP `ga_voice_leading_pair` empareja voicings tocables del índice OPTIC-K con "a greedy sorted-pitch matching" (un emparejamiento voraz de alturas ordenadas), "not a formal Hungarian-optimal assignment" (no una asignación formal óptima según el algoritmo húngaro) ([`CompositionTools.cs` líneas 179-186](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L179-L186)). El curso no la ejecuta.

## Comunicado upstream

- Se comunicaron después de escribir esta lección, en la issue de GA [#789](https://github.com/GuitarAlchemist/ga/issues/789): la duplicación de la fundamental y la respuesta que se dice óptima, los cifrados, las alteraciones, la grafía de las notas, las formulaciones y `CanHandle`.

## Ejercicios

1. "voice leading from C to F#" recibe C → F. Da dos maneras de escribir la pregunta para que la skill mueva C a F♯ mayor.
2. La skill mueve Em a A7 con 5 semitonos. ¿Qué nota de Em hay que duplicar para mover solo 4, y cómo?
3. ¿Por qué "voice leading F7 to Bbmaj7" escribe A♯ y D♯, mientras que "voice leading F7 to B♭maj7" escribe B♭ y E♭? Da una tercera manera de obtener bemoles.
4. "voice leading CM7 to FM7" y "voice leading Cmaj7 to Fmaj7" reciben los dos 4 semitonos. ¿Cómo muestra la respuesta que la primera mueve otros acordes?

<details>
<summary>Soluciones</summary>

1. Escribir el bemol, `Gb`: `b` es una letra, así que detrás de ella sí hay límite, y "voice leading from C to Gb" mueve C a G♭ con 6 semitonos, con las notas escritas en bemoles. O añadir una cualidad: "voice leading from C to F#maj" termina en la `j` y recibe los mismos 6 semitonos, con las notas escritas en sostenidos. Comprobado ejecutando la skill del commit fijado, fuera de la salida esperada del curso.
2. G o B. Duplicando B: E se queda, G se queda, B baja a A y el otro B sube a C♯, 0 + 0 + 2 + 2. Duplicando G: E se queda, G se queda, el otro G sube a A, y B sube a C♯, 0 + 0 + 2 + 2. La skill duplica E, que tiene que bajar 3 semitonos hasta C♯ mientras B baja 2 hasta A. Comprobado ejecutando la skill del commit fijado, fuera de la salida esperada del curso.
3. `TokenHasFlats` busca `b` sin distinguir mayúsculas de minúsculas y encuentra la `B` de "Bbmaj7" en la posición 0, que toma por la nota B; `♭` se encuentra directamente. Con "flat" en cualquier parte de la pregunta, por ejemplo "voice leading F7 to Bbmaj7 in flats", la respuesta se escribe con bemoles. Comprobado ejecutando la skill del commit fijado, fuera de la salida esperada del curso.
4. Por sus notas: la tabla de la primera da D♯ y A♯, el E♭ y el B♭ de Cm7, donde Cmaj7 tiene E y B. La primera línea, además, repite "CM7 → FM7", lo que oculta la mala lectura. Comprobado ejecutando la skill del commit fijado, fuera de la salida esperada del curso.

</details>

## Puntos clave

- Una búsqueda óptima solo es óptima sobre lo que busca: probar todas las permutaciones encuentra el mejor emparejamiento, no la mejor duplicación.
- Una respuesta que se dice óptima hace una afirmación que el programa puede comprobar, respuesta a respuesta, contra una búsqueda exhaustiva más lenta.
- Una tabla de cifrados solo promete lo que deja pasar la expresión que tiene delante.
- `\b` detrás de `#`, `♯`, `♭` o `°` falla, y la expresión se queda con la letra: el mismo fallo que en las lecciones 7, 9 y 17.
- Una búsqueda del bemol `b` que no distingue mayúsculas de minúsculas encuentra la nota B.

## Fuentes

- GuitarAlchemist/ga en [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `Common/GA.Business.ML/Agents/Skills/VoiceLeadingSkill.cs`, `Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs`, `GaMcpServer/Tools/CompositionTools.cs`.
- GuitarAlchemist/ga en [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/tree/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a): la misma skill, `Common/GA.Business.ML/Agents/GuitarAlchemistAgentBase.cs`, `Common/GA.Business.ML/Agents/Intents/SemanticIntentRouter.cs`, `Common/GA.Business.Core.Orchestration/Intents/OrchestratorSkillIntent.cs`.
- El programa del curso: `code/ga-ai/GaAi/Lesson18.cs`.
