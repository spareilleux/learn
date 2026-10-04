---
title: "Lección 26: El catálogo de modos"
description: "La ModesSkill de Guitar Alchemist responde a preguntas sobre modos a partir de Modes.yaml, sin modelo. 36 de los 129 modos con los que responde no son la escala de su familia tocada desde su grado, 8 nombres se cortan en un signo de sostenido que YAML lee como un comentario, 10 modos no se alcanzan por su propio nombre, y la fórmula que calcula por posición es la de un manual solo para 65 de ellos."
sidebar:
  label: 26. El catálogo de modos
  order: 26
---

La [lección 8](../08-the-chatbots-own-exam/) se encontró con `ModesSkill` en un prompt del corpus de GA, y vio que numeraba sus fórmulas por posición en dos escalas, lo que se comunicó como el issue de GA [#765](https://github.com/GuitarAlchemist/ga/issues/765). La skill dice que no contiene teoría musical propia: "Zero hardcoded music-theory content — the skill is a thin adapter that classifies the query, calls the domain, and formats the result" ([`ModesSkill.cs` líneas 8-16](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ModesSkill.cs#L8-L16)). El dominio es `Modes.yaml`, que lee `ModesConfig`. Así que esta lección comprueba el propio catálogo, modo por modo, y después lo que la skill hace con él. No necesita ningún modelo: la skill es determinista.

Todos los enlaces a GA apuntan al commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), el commit fijado del curso. En el `main` de GA en [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/commit/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) (2026-10-01), `ModesSkill.cs`, `Modes.yaml`, `ModesConfig.fs`, `AtonalModalFamiliesConfig.fs` y `skills/modes/SKILL.md` son los mismos archivos, byte a byte, así que el programa solo se ejecuta en el commit fijado. La salida procede de:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l26
```

## Cómo responde la skill

`ExecuteAsync` prueba, por orden: el catálogo atonal, cuando la pregunta nombra un vector de clases de intervalos, un número de Forte o palabras de la atonalidad; una familia, cuando la pregunta pide sus modos; un modo cuyo nombre contiene la pregunta; una familia cuyo nombre contiene; un panorama de todas las familias; y, si no, los modos de la escala mayor ([líneas 152-211](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ModesSkill.cs#L152-L211)). La respuesta sobre un modo dice qué modo de qué familia es, da sus notas sobre C tal como las escribe el catálogo, y añade una fórmula que calcula a partir de esas notas:

```csharp
        var degree = family.Modes.ToList().FindIndex(m => m.Name == mode.Name) + 1;
        sb.Append($"**{mode.Name}** is mode {degree} of the **{StripFamilySuffix(family.Name)}** family");
        if (!string.IsNullOrWhiteSpace(mode.Notes))
        {
            sb.Append($"; on C its notes are `{mode.Notes}`");
            var formula = ComputeFormulaFromNotes(mode.Notes);
            if (!string.IsNullOrEmpty(formula))
                sb.Append($" (formula `{formula}`)");
        }
        sb.Append('.');
```

## El catálogo frente a un manual

"El modo 4 de la escala mayor" es la escala mayor tocada desde su cuarto grado: sobre C, las notas de F mayor de F a F, llevadas a C. El programa conoce, para cada una de las 26 familias, el primer modo de un manual (`Parents` en `Lesson26.cs`), y compara cada modo k de una familia con su modo 1 tocado desde el grado k:

```text
== The families ModesSkill answers from, and whether mode k is the parent scale from its degree k
family                   modes  notes  mode 1     mode k on degree k  the modes that aren't
Major Scale              7      7      textbook   7 of 7              -
Harmonic Minor           7      7      textbook   6 of 7              7
Melodic Minor            7      7      textbook   7 of 7              -
Major Pentatonic         5      5      textbook   2 of 5              3, 4, 5
Whole Tone               1      6      textbook   1 of 1              -
Diminished               2      8      textbook   2 of 2              -
Blues Scale              1      6      textbook   1 of 1              -
Chromatic                1      12     textbook   1 of 1              -
Perfect Fourth           2      2      textbook   2 of 2              -
Major Third              2      2      textbook   2 of 2              -
Minor Third              2      2      textbook   2 of 2              -
Major Second             2      2      textbook   2 of 2              -
Minor Second             2      2      textbook   2 of 2              -
Harmonic Major           7      7      textbook   7 of 7              -
Double Harmonic          7      7      textbook   6 of 7              7
Neapolitan Minor         7      7      textbook   6 of 7              7
Neapolitan Major         7      7      textbook   3 of 7              4, 5, 6, 7
Dominant Bebop           8      8      textbook   5 of 8              6, 7, 8
Major Bebop              8      8      textbook   3 of 8              4, 5, 6, 7, 8
Prometheus               6      6      textbook   3 of 6              4, 5, 6
Enigmatic                7      7      textbook   2 of 7              3, 4, 5, 6, 7
Hungarian Major          7      7      textbook   1 of 7              2, 3, 4, 5, 6, 7
Hirajoshi                5      5      textbook   5 of 5              -
In Sen                   5      5      textbook   1 of 5              2, 3, 4, 5
Diminished (Octatonic)   8      8      textbook   8 of 8              -
Augmented (Hexatonic)    6      6      textbook   6 of 6              -
families 26; Modes.yaml's that the skill leaves out 5: Major Triad Family, Diminished Triad Family, Augmented Triad Family, Major Seventh Chord Family, All Interval Tetrachord Family
modes 129: mode 1 from their own degree 93, from another degree 2, from no degree 34; notes out of order 3
the modes that aren't:
  Harmonic Minor 7, Ultralocrian: C Db Eb Fb Gb Ab Bb; mode 1 from no degree; from degree 7: C Db Eb Fb Gb Ab Bbb
  Major Pentatonic 3, Blues Minor: C Eb F G Bb; mode 1 from degree 5
  Major Pentatonic 4, Blues Major: C E F A Bb; mode 1 from no degree; from degree 4: semitones 0 2 5 7 9
  Major Pentatonic 5, Minor Pentatonic: C D F G A; mode 1 from degree 4
  Double Harmonic 7, Locrian bb3 bb7: C Dbb Ebb F Gb Ab Bbb; mode 1 from no degree; from degree 7: C Db Ebb F Gb Ab Bbb
  Neapolitan Minor 7, Ultralocrian bb3: C Dbb Eb F Gb Ab Bbb; mode 1 from no degree; from degree 7: C Db Ebb Fb Gb Ab Bbb
  Neapolitan Major 4, Lydian Minor (Lydian b3 b7): C D Eb F# G A Bb; mode 1 from no degree; from degree 4: C D E F# G Ab Bb
  Neapolitan Major 5, Major Locrian: C D Eb F Gb Ab Bb; mode 1 from no degree; from degree 5: C D E F Gb Ab Bb
  Neapolitan Major 6, Altered Dominant n2 (Locrian n2 n7): C D Eb F Gb Ab B; mode 1 from no degree; from degree 6: C D Eb Fb Gb Ab Bb
  Neapolitan Major 7, Altered bb3: C Dbb Eb Fb Gb Ab Bb; mode 1 from no degree; from degree 7: C Db Ebb Fb Gb Ab Bb
  Dominant Bebop 6, Dominant Bebop Mode 6: C Db D Eb F G A Bb; mode 1 from no degree; from degree 6: semitones 0 1 2 3 5 7 8 10
  Dominant Bebop 7, Dominant Bebop Mode 7: C C# D E F G A B; mode 1 from no degree; from degree 7: semitones 0 1 2 4 6 7 9 11
  Dominant Bebop 8, Dominant Bebop Mode 8: C C# D# E F# G# A# B; mode 1 from no degree; from degree 8: semitones 0 1 3 5 6 8 10 11
  Major Bebop 4, Major Bebop Mode 4: C D Eb F G Ab A B; mode 1 from no degree; from degree 4: semitones 0 2 3 4 6 7 9 11
  Major Bebop 5, Major Bebop Mode 5: C Db Eb F Gb G Bb B; mode 1 from no degree; from degree 5: semitones 0 1 2 4 5 7 9 10
  Major Bebop 6, Major Bebop Mode 6: C D E F F# A Bb B; mode 1 from no degree; from degree 6: semitones 0 1 3 4 6 8 9 11
  Major Bebop 7, Major Bebop Mode 7: C D Eb E G Ab A Bb; mode 1 from no degree; from degree 7: semitones 0 2 3 5 7 8 10 11
  Major Bebop 8, Major Bebop Mode 8: C Db D F Gb G Ab B; mode 1 from no degree; from degree 8: semitones 0 1 3 5 6 8 9 10
  Prometheus 4, Prometheus Mode 4: C Eb E G A Bb; mode 1 from no degree; from degree 4: semitones 0 3 4 6 8 10
  Prometheus 5, Prometheus Mode 5: C C# E F# G# A; mode 1 from no degree; from degree 5: semitones 0 1 3 5 7 9
  Prometheus 6, Prometheus Mode 6: C D# F G G# B; mode 1 from no degree; from degree 6: semitones 0 2 4 6 8 11
  Enigmatic 3, Enigmatic Mode 3: C D E Gb G Ab Bb; mode 1 from no degree; from degree 3: C D E F# G Ab Bbb
  Enigmatic 4, Enigmatic Mode 4: C D E F Gb Ab B; mode 1 from no degree; from degree 4: C D E F Gb Abb Bb
  Enigmatic 5, Enigmatic Mode 5: C D Eb F G B Bb; mode 1 from no degree; from degree 5: C D Eb Fb Gbb Ab Bb; notes out of order
  Enigmatic 6, Enigmatic Mode 6: C Db Eb F A G# B; mode 1 from no degree; from degree 6: C Db Ebb Fbb Gb Ab Bb; notes out of order
  Enigmatic 7, Enigmatic Mode 7: C D E G# F# A# B; mode 1 from no degree; from degree 7: C Db Ebb F G A B; notes out of order
  Hungarian Major 2, Hungarian Major Mode 2: C Db Eb F Gb Ab A; mode 1 from no degree; from degree 2: C Db Eb Fb Gb Abb Bbb
  Hungarian Major 3, Hungarian Major Mode 3: C D E F G G# B; mode 1 from no degree; from degree 3: C D Eb F Gb Ab B
  Hungarian Major 4, Hungarian Major Mode 4: C D Eb F F# A Bb; mode 1 from no degree; from degree 4: C Db Eb Fb Gb A Bb
  Hungarian Major 5, Hungarian Major Mode 5: C Db Eb E G Ab Bb; mode 1 from no degree; from degree 5: C D Eb F G# A B
  Hungarian Major 6, Hungarian Major Mode 6: C D D# F# G A B; mode 1 from no degree; from degree 6: C Db Eb F# G A Bb
  Hungarian Major 7, Hungarian Major Mode 7: C C# E F G A Bb; mode 1 from no degree; from degree 7: C D E# F# G# A B
  In Sen 2, In Sen Mode 2: C E F Ab Bb; mode 1 from no degree; from degree 2: semitones 0 4 6 9 11
  In Sen 3, In Sen Mode 3: C Db F G A; mode 1 from no degree; from degree 3: semitones 0 2 5 7 8
  In Sen 4, In Sen Mode 4: C E F G B; mode 1 from no degree; from degree 4: semitones 0 3 5 6 10
  In Sen 5, In Sen Mode 5: C Db Eb G Ab; mode 1 from no degree; from degree 5: semitones 0 2 3 7 9
```

- **El modo 1 es la escala del manual en las 26 familias, pero 36 de los demás modos no son el modo 1 desde su grado.** Dos son el modo 1 desde otro grado: el "Blues Minor" de la pentatónica mayor (modo 3) es la escala desde el grado 5, y su "Minor Pentatonic" (modo 5), desde el grado 4. Los otros 34 no son el modo 1 desde ningún grado: sus notas forman otra escala. Son 4 de los 7 modos de la napolitana mayor, 8 de los 16 de las dos escalas bebop, 3 de los 6 de la escala de Prometeo, 5 de los 7 de la escala enigmática, 6 de los 7 de la húngara mayor, 4 de los 5 de la In Sen, el "Blues Major" de la pentatónica mayor, y el séptimo modo de la menor armónica, de la doble armónica y de la napolitana menor.
- **El Ultralocrio tiene las notas de la escala alterada.** El séptimo modo de la menor armónica tiene una séptima disminuida, Bbb sobre C; el catálogo escribe Bb ([`Modes.yaml` líneas 242-243](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Config/Modes.yaml#L242-L243)), con lo que salen las notas de la escala alterada, el modo 7 de la menor melódica.
- **Tres séptimos modos no tienen segundo grado.** "Locrian bb3 bb7", "Ultralocrian bb3" y "Altered bb3" empiezan por `C Dbb`: Dbb vuelve a ser C, y falta el Db con el que estos modos deberían seguir después de C. La napolitana menor lo muestra, junto con otras tres cosas a las que la lección volverá:

```yaml
  - Name: Neapolitan Minor Family
    Modes:
      - Name: Neapolitan Minor
        Notes: C Db Eb F G Ab B
      - Name: Lydian #6
        Notes: C D E F# G A# B
      - Name: Mixolydian Augmented
        Notes: C D E F G# A Bb
      - Name: Aeolian #4 (Lydian Diminished)
        Notes: C D Eb F# G Ab Bb
      - Name: Locrian n3
        Notes: C Db E F Gb Ab Bb
      - Name: Ionian #2
        Notes: C D# E F G A B
      - Name: Ultralocrian bb3
        Notes: C Dbb Eb F Gb Ab Bbb
```

- **La skill responde a partir de 26 de las 31 familias del catálogo.** Descarta las familias cuyo nombre contiene "Chord Family" o "Triad Family", para que los acordes no se mezclen con las respuestas sobre modos:

```csharp
    private static bool IsChordOrTriadFamilyName(string name) =>
        name.Contains("Chord Family", StringComparison.OrdinalIgnoreCase) ||
        name.Contains("Triad Family", StringComparison.OrdinalIgnoreCase);
```

  Su comentario cuenta cuatro familias de ese tipo ([líneas 515-516](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ModesSkill.cs#L515-L516)); la quinta es "All Interval Tetrachord Family", cuyo nombre contiene "chord Family", y la comparación no distingue mayúsculas de minúsculas.

## Las fórmulas

Un manual escribe la fórmula de una escala de siete notas con cada grado una vez: sus notas, en orden ascendente, son 1 a 7, y el lidio es `1 2 3 #4 5 6 7`. Para cualquier otro número de notas, cada número sale de la letra de la nota: la pentatónica mayor, C D E G A, es `1 2 3 5 6`. La skill compara la i-ésima nota con el i-ésimo grado de C mayor, volviendo a 1 después de siete, y abandona una alteración que no sabe escribir con dos sostenidos o dos bemoles:

```csharp
        for (var i = 0; i < tokens.Length; i++)
        {
            if (!PitchSemitone.TryGetValue(tokens[i], out var semi))
                return string.Empty;  // unknown token — bail rather than guess
            // For scales of <=7 notes, position maps directly to degree slot.
            // For 8-note (Bebop) or longer scales, modulo 7 keeps the reference
            // sensible — the formula notation is still recognizable.
            var slot = i % 7;
            var expected = DegreeSemitones[slot];
            var diff = semi - expected;
            // Normalize across octave boundary for late notes in 8+-note scales.
            if (diff > 6) diff -= 12;
            if (diff < -6) diff += 12;
            var acc = diff switch
            {
                -2 => "bb",
                -1 => "b",
                  0 => "",
                  1 => "#",
                  2 => "##",
                  _ => string.Empty  // out of expected range — omit accidental rather than emit garbage
            };
            parts.Add($"{acc}{i + 1}");
        }
```

```text
== Each mode's formula: the one ModesSkill computes from the notes by position, and a textbook's
notes  modes  the skill's   the letters'    the first of the skill's that differs: notes, the skill's formula, a textbook's
2      10     2 right       -               Perfect Fourth: C F; `1 2`, `1 4`
5      15     0 right       -               Major Pentatonic: C D E G A; `1 2 3 ##4 ##5`, `1 2 3 5 6`
6      14     3 right       -               Whole Tone: C D E F# G# Bb; `1 2 3 #4 #5 #6`, `1 2 3 #4 #5 b7`
7      63     60 right      52 right        Enigmatic Mode 5: C D Eb F G B Bb; `1 2 b3 4 5 ##6 b7`, `1 2 b3 4 5 #6 7`
8      26     0 right       -               Diminished (Half-Whole): C Db Eb E F# G A Bb; `1 b2 b3 b4 b5 bb6 bb7 bb8`, `1 b2 b3 3 #4 5 6 b7`
12     1      0 right       -               Chromatic: C C# D D# E F F# G G# A A# B; `1 b2 bb3 bb4 5 6 7 8 9 10 11 12`, `1 #1 2 #2 3 4 #4 5 #5 6 #6 7`
modes 129: the skill's formula is a textbook's 65; of the 63 seven-note modes, a formula read from the letters would be 52
the seven-note modes whose letters give another formula than their degrees:
  Enigmatic Mode 2: C D# F G A Bb B; letters `1 #2 4 5 6 b7 7`, degrees `1 #2 #3 ##4 ##5 #6 7`
  Enigmatic Mode 3: C D E Gb G Ab Bb; letters `1 2 3 b5 5 b6 b7`, degrees `1 2 3 #4 5 b6 b7`
  Enigmatic Mode 5: C D Eb F G B Bb; letters `1 2 b3 4 5 7 b7`, degrees `1 2 b3 4 5 #6 7`
  Enigmatic Mode 6: C Db Eb F A G# B; letters `1 b2 b3 4 6 #5 7`, degrees `1 b2 b3 4 #5 6 7`
  Enigmatic Mode 7: C D E G# F# A# B; letters `1 2 3 #5 #4 #6 7`, degrees `1 2 3 #4 #5 #6 7`
  Hungarian Major Mode 2: C Db Eb F Gb Ab A; letters `1 b2 b3 4 b5 b6 6`, degrees `1 b2 b3 4 b5 b6 bb7`
  Hungarian Major Mode 3: C D E F G G# B; letters `1 2 3 4 5 #5 7`, degrees `1 2 3 4 5 b6 7`
  Hungarian Major Mode 4: C D Eb F F# A Bb; letters `1 2 b3 4 #4 6 b7`, degrees `1 2 b3 4 b5 6 b7`
  Hungarian Major Mode 5: C Db Eb E G Ab Bb; letters `1 b2 b3 3 5 b6 b7`, degrees `1 b2 b3 b4 5 b6 b7`
  Hungarian Major Mode 6: C D D# F# G A B; letters `1 2 #2 #4 5 6 7`, degrees `1 2 b3 #4 5 6 7`
  Hungarian Major Mode 7: C C# E F G A Bb; letters `1 #1 3 4 5 6 b7`, degrees `1 b2 3 4 5 6 b7`
the seven-note modes whose formulas differ:
  Enigmatic Mode 5: C D Eb F G B Bb; `1 2 b3 4 5 ##6 b7`, `1 2 b3 4 5 #6 7`
  Enigmatic Mode 6: C Db Eb F A G# B; `1 b2 b3 4 ##5 b6 7`, `1 b2 b3 4 #5 6 7`
  Enigmatic Mode 7: C D E G# F# A# B; `1 2 3 4 b5 #6 7`, `1 2 3 #4 #5 #6 7`
the other differences, one per family:
  Major Pentatonic: C D E G A; `1 2 3 ##4 ##5`, `1 2 3 5 6`
  Whole Tone: C D E F# G# Bb; `1 2 3 #4 #5 #6`, `1 2 3 #4 #5 b7`
  Diminished (Half-Whole): C Db Eb E F# G A Bb; `1 b2 b3 b4 b5 bb6 bb7 bb8`, `1 b2 b3 3 #4 5 6 b7`
  Blues Scale: C Eb F F# G Bb; `1 #2 #3 #4 5 #6`, `1 b3 4 #4 5 b7`
  Chromatic: C C# D D# E F F# G G# A A# B; `1 b2 bb3 bb4 5 6 7 8 9 10 11 12`, `1 #1 2 #2 3 4 #4 5 #5 6 #6 7`
  Perfect Fourth: C F; `1 2`, `1 4`
  Major Third: C E; `1 ##2`, `1 3`
  Minor Third: C Eb; `1 #2`, `1 b3`
  Minor Seventh: C Bb; `1 2`, `1 b7`
  Major Seventh: C B; `1 2`, `1 7`
  Dominant Bebop: C D E F G A Bb B; `1 2 3 4 5 6 b7 b8`, `1 2 3 4 5 6 b7 7`
  Major Bebop: C D E F G G# A B; `1 2 3 4 5 b6 bb7 b8`, `1 2 3 4 5 #5 6 7`
  Prometheus: C D E F# A Bb; `1 2 3 #4 ##5 #6`, `1 2 3 #4 6 b7`
  Hirajoshi: C D Eb G Ab; `1 2 b3 ##4 #5`, `1 2 b3 5 b6`
  In Sen: C Db F G Bb; `1 b2 #3 ##4 5`, `1 b2 4 5 b7`
  Whole-Half Diminished: C D Eb F Gb Ab A B; `1 2 b3 4 b5 b6 bb7 b8`, `1 2 b3 4 b5 b6 6 7`
  Augmented Scale: C Eb E G Ab B; `1 #2 3 ##4 #5 ##6`, `1 b3 3 5 b6 7`
```

- **Las fórmulas son correctas para 60 de los 63 modos de siete notas, y para 5 de los otros 66.** Los tres de siete notas que fallan son modos de la escala enigmática cuyas notas el catálogo no pone en orden ascendente.
- **Todas las escalas de cinco y de ocho notas reciben una fórmula errónea.** La pentatónica mayor queda `1 2 3 ##4 ##5`: G se escribe como una cuarta con doble sostenido. Las escalas de ocho notas terminan en un octavo grado: `b8` para la séptima mayor de la bebop dominante, `bb8` para la séptima menor de la disminuida semitono-tono.
- **Una escala de dos notas puede recibir la nota equivocada.** El catálogo tiene cinco familias de "modos" de dos notas. Para C F, la skill espera D en segundo lugar; F está tres semitonos por encima, así que la alteración se abandona y la fórmula queda `1 2`, que nombra D. Las séptimas menor y mayor, C Bb y C B, también quedan `1 2`.
- **La diferencia en la escala de tonos enteros es solo de ortografía.** `#6` y `b7` son la misma nota; el catálogo la escribe Bb.
- **Leer cada número de la letra, como propone el issue #765, tampoco basta.** Para 52 de los 63 modos de siete notas da la misma fórmula que sus grados. Para los 11 restantes, tal como los deletrea el catálogo, no da cada grado una vez en orden ascendente: la mayoría repite un grado y pierde otro, como el modo 2 de la enigmática, `C D# F G A Bb B`, que sería `1 #2 4 5 6 b7 7`, y los modos 6 y 7 de la enigmática conservan las notas desordenadas del catálogo. La regla de un manual necesita las dos cosas: grados para siete notas, letras en los demás casos.

## Algunas respuestas

```text
== A few of ModesSkill's answers, first line
What is Ultralocrian?
  | **Ultralocrian** is mode 7 of the **Harmonic Minor** family; on C its notes are `C Db Eb Fb Gb Ab Bb` (formula `1 b2 b3 b4 b5 b6 b7`).
What is Altered?
  | **Altered** is mode 7 of the **Melodic Minor** family; on C its notes are `C Db Eb Fb Gb Ab Bb` (formula `1 b2 b3 b4 b5 b6 b7`).
What is Major Locrian?
  | **Major Locrian** is mode 5 of the **Neapolitan Major** family; on C its notes are `C D Eb F Gb Ab Bb` (formula `1 2 b3 4 b5 b6 b7`).
What is Major Pentatonic?
  | **Major Pentatonic** is mode 1 of the **Major Pentatonic** family; on C its notes are `C D E G A` (formula `1 2 3 ##4 ##5`).
What is Dominant Bebop?
  | **Dominant Bebop** is mode 1 of the **Dominant Bebop** family; on C its notes are `C D E F G A Bb B` (formula `1 2 3 4 5 6 b7 b8`).
What is Perfect Fourth?
  | **Perfect Fourth** is mode 1 of the **Perfect Fourth** family; on C its notes are `C F` (formula `1 2`).
```

- **El Ultralocrio y la alterada reciben las mismas notas y la misma fórmula.** El locrio mayor recibe las notas del locrio #2, C D Eb F Gb Ab Bb; el locrio mayor de un manual es C D E F Gb Ab Bb.
- **La cuarta justa se convierte en un modo de dos notas, con una fórmula que nombra D.**

## Los nombres

En YAML, un valor termina en un espacio seguido de `#`: lo que sigue es un comentario, salvo que el valor vaya entre comillas. El programa lee los nombres de modos de `Modes.yaml` tal como están escritos, y los compara con los nombres que lee `ModesConfig`:

```text
== The mode names Modes.yaml writes, and the names ModesConfig reads: the ones that differ
written                            read
Lydian Augmented #2                Lydian Augmented
Lydian #2 #6                       Lydian
Ionian Augmented #2                Ionian Augmented
Lydian #6                          Lydian
Aeolian #4 (Lydian Diminished)     Aeolian
Ionian #2                          Ionian
Lydian Augmented #6                Lydian Augmented
Lydian Dominant #5                 Lydian Dominant
mode names written 165, read 165, read otherwise than written 8
```

- **Ocho nombres pierden todo a partir de su primer signo de sostenido.** "Lydian #6" se convierte en "Lydian", "Aeolian #4 (Lydian Diminished)" en "Aeolian", y "Lydian Dominant #5" en "Lydian Dominant". Los nombres de la menor armónica van entre comillas, `'Locrian #6'` ([`Modes.yaml` línea 209](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Config/Modes.yaml#L209)); los de la doble armónica, la napolitana menor, la napolitana mayor y la mayor armónica no (líneas 631 a 681).

Después, el programa le hace a la skill la pregunta `What is <name>?` con cada nombre y cada nombre alternativo de modo:

```text
== "What is <name>?" for each mode's name and alternate names: the modes ModesSkill answers with another
asked                            the mode named                                    answered
What is Minor Pentatonic?        Minor Pentatonic (Major Pentatonic 5)             Blues Minor (Major Pentatonic 3)
What is Lydian Augmented?        Lydian Augmented (Harmonic Major 6)               Lydian Augmented (Melodic Minor 3)
What is Lydian?                  Lydian (Double Harmonic 2)                        Lydian (Major Scale 4)
What is Ionian Augmented?        Ionian Augmented (Double Harmonic 6)              Ionian #5 (Harmonic Minor 3)
What is Lydian?                  Lydian (Neapolitan Minor 2)                       Lydian (Major Scale 4)
What is Aeolian?                 Aeolian (Neapolitan Minor 4)                      Aeolian (Major Scale 6)
What is Ionian?                  Ionian (Neapolitan Minor 6)                       Ionian (Major Scale 1)
What is Lydian Augmented?        Lydian Augmented (Neapolitan Major 2)             Lydian Augmented (Melodic Minor 3)
What is Lydian Dominant?         Lydian Dominant (Neapolitan Major 3)              Lydian Dominant (Melodic Minor 4)
What is Whole-Half Diminished?   Whole-Half Diminished (Diminished (Octatonic) 1)  Diminished (Whole-Half) (Diminished 2)
mode names 129: answered with their mode 119, with another 10, CanHandle accepts 129; alternate names 68: answered with their mode 68, with another 0, CanHandle accepts 7
```

- **10 de los 129 modos no se alcanzan por su propio nombre.** Ocho son los nombres cortados: ahora repiten el nombre de un modo de la escala mayor, la menor melódica o la menor armónica, y es ese modo el que responde. Los otros dos nombres están de verdad dos veces en el catálogo: "Minor Pentatonic" es el nombre del modo 5 de la pentatónica mayor y un nombre alternativo de su modo 3, y "Whole-Half Diminished" nombra el modo 1 de la familia octatónica y es un nombre alternativo del modo 2 de la familia disminuida.
- **Gana la primera coincidencia del catálogo.** La skill ordena todos los nombres y nombres alternativos por longitud, del más largo al más corto, y conserva el orden del catálogo entre nombres de la misma longitud; el primero que contiene la pregunta es la respuesta:

```csharp
        var aliasedModes = families
            .SelectMany(f => f.Modes
                .SelectMany(m => GetAllAliasesForMode(m).Select(a => (Alias: a, Family: f, Mode: m))))
            .OrderByDescending(t => t.Alias.Length)
            .ToList();

        foreach (var (alias, family, mode) in aliasedModes)
        {
            if (string.IsNullOrWhiteSpace(alias)) continue;
            if (lowerQuery.Contains(alias))
                return (family, mode);
        }
```

- **`CanHandle` acepta todos los nombres de modos, pero solo 7 de los 68 nombres alternativos.** Compara el resto de la pregunta con los nombres de los modos y de las familias, no con sus nombres alternativos ([líneas 137-144](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ModesSkill.cs#L137-L144)): entre los prompts de ejemplo de más abajo, "Tell me about Hijaz" se rechaza. En el commit fijado el orquestador no llama a `CanHandle`; en `main`, es lo que pregunta el enrutador de intenciones cuando no puede calcular el embedding de una pregunta ([lección 25](../25-what-reaches-the-transpose-skill/), [`SemanticIntentRouter.cs` líneas 313-335](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Agents/Intents/SemanticIntentRouter.cs#L313-L335)). Qué skill responde primero en ese caso depende del orden de registro, que esta lección no ejecuta.

## Los prompts de ejemplo

```text
== ModesSkill's example prompts: what the first line of the answer is about
prompt                                       CanHandle  answer
What are the modes of the major scale        no         the Major Scale family
List the diatonic modes                      no         the Major Scale family
What are other famous modes                  no         The catalog has **26 mode families** total — these are the named scal…
What are the modes of melodic minor          no         the Melodic Minor family
Modes of harmonic minor                      no         the Harmonic Minor family
What is Lydian dominant                      yes        Lydian Dominant (Melodic Minor 4)
What is Phrygian dominant                    yes        Phrygian Dominant (Harmonic Minor 5)
What is the altered scale                    no         Altered (Melodic Minor 7)
Tell me about Hungarian minor                yes        Hungarian Minor (Double Harmonic 4)
What is the whole tone scale                 no         Whole Tone (Whole Tone 1)
What is the diminished scale                 no         Diminished (Half-Whole) (Diminished 1)
What modes are non-diatonic                  no         The catalog has **26 mode families** total — these are the named scal…
Show me all the mode families                no         The catalog has **26 mode families** total — these are the named scal…
What is Hirajoshi                            yes        Hirajoshi (Hirajoshi 1)
What is Dorian                               yes        Dorian (Major Scale 2)
What is Phrygian                             yes        Phrygian (Major Scale 3)
What is Lydian                               yes        Lydian (Major Scale 4)
What is Mixolydian                           yes        Mixolydian (Major Scale 5)
What is Aeolian                              yes        Aeolian (Major Scale 6)
What is Ionian                               yes        Ionian (Major Scale 1)
What is Locrian                              yes        Locrian (Major Scale 7)
Tell me about Hijaz                          no         Phrygian Dominant (Harmonic Minor 5)
What is Maqam Hijaz                          no         Phrygian Dominant (Harmonic Minor 5)
What is Freygish                             no         Phrygian Dominant (Harmonic Minor 5)
What is Bhairavi                             no         Phrygian (Major Scale 3)
What is the Byzantine scale                  no         Double Harmonic (Byzantine) (Double Harmonic 1)
What is the Spanish Gypsy scale              no         Phrygian Dominant (Harmonic Minor 5)
What is Ahava Rabbah                         no         Phrygian Dominant (Harmonic Minor 5)
What modes have a major 7th                  no         the Major Scale family
Mixolydian versus Ionian differences         no         Mixolydian (Major Scale 5)
Characteristics of Locrian                   no         Locrian (Major Scale 7)
What families have ICV <2 5 4 3 6 1>         no         **Major Scale Family** — ICV `<2 5 4 3 6 1>`, 7-note set, 7 distinct …
What is Forte number 7-29                    no         Forte number **7-29** matches 1 family:
List symmetric families                      no         **6 symmetric / modes-of-limited-transposition families** in the aton…
List atonal modal families                   no         The **atonal modal-families catalog** has **200 families** indexed by…
List unnamed modal families                  no         the Major Scale family
What are modes of limited transposition      no         **6 symmetric / modes-of-limited-transposition families** in the aton…
example prompts 37: CanHandle accepts 11
```

- **"List unnamed modal families" recibe los modos de la escala mayor.** La rama atonal busca "unnamed famil" ([línea 606](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ModesSkill.cs#L606)), y el prompt dice "unnamed modal families"; cae en la respuesta por defecto ([líneas 202-207](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ModesSkill.cs#L202-L207)), la que recibió el "melodi minor" de la lección 8.
- **"What modes have a major 7th" también recibe los modos de la escala mayor, y "Mixolydian versus Ionian differences" recibe solo el mixolidio:** gana el nombre más largo de la pregunta, y la skill no sabe comparar.
- **`CanHandle` acepta 11 de los 37.**

## Hasta dónde llega el curso

- **El manual es el del curso.** `Parents` en `Lesson26.cs` da el primer modo de cada familia tal como lo dan las referencias habituales; los nombres de los modos no se comparan con un manual, solo sus notas con el primer modo de su propia familia.
- **La ortografía es la del catálogo.** Las fórmulas se comparan con la regla de un manual aplicada a las propias notas del catálogo, y un sostenido y un bemol que nombran la misma nota solo se distinguen donde la regla lo exige.
- **No se comprueban ni el catálogo atonal ni el enrutamiento.** Las 200 familias atonales no se comparan con una tabla de clases de conjuntos, y no se ejecuta ningún enrutador: la lección llama a la skill directamente.

## Ejercicios

1. ¿Sobre qué grado de C D E G A empieza el "Minor Pentatonic" del catálogo, C D F G A? ¿Cuál de los modos de la familia lleva las notas de la pentatónica menor?
2. ¿Por qué escribe la skill `1 2` para la cuarta justa, C F?
3. `Modes.yaml` llama "Lydian Dominant #5" al tercer modo de la napolitana mayor. ¿Por qué "What is Lydian Dominant?" recibe el modo de la menor melódica, y qué haría falta para que "What is Lydian Dominant #5?" recibiera el de la napolitana mayor?
4. ¿Por qué "List unnamed modal families" recibe los modos de la escala mayor, cuando "List symmetric families" recibe el catálogo atonal?

<details>
<summary>Soluciones</summary>

1. Sobre el grado 4, G: G A C D E, llevado a C, da C D F G A. La pentatónica menor empieza en el grado 5, A: C Eb F G Bb, las notas del modo 3 del catálogo, "Blues Minor", cuyo nombre alternativo es "Minor Pentatonic".
2. F es la segunda nota, así que la skill la compara con D, el segundo grado de C mayor. F está tres semitonos por encima de D, más allá de los dos sostenidos que sabe escribir el `switch`, así que la alteración se abandona (línea 806) y el número se queda en 2.
3. El nombre no va entre comillas, así que YAML lee "Lydian Dominant": el modo 4 de la menor melódica tiene el mismo nombre, aparece antes en el catálogo y gana el empate. Entre comillas, `'Lydian Dominant #5'`, como escriben los suyos las líneas 209 a 280, el nombre conserva su signo de sostenido; entonces es más largo que "lydian dominant", así que la skill lo prueba primero, y "What is Lydian Dominant #5?" lo contiene. Razonamiento hecho sobre el código: el programa no hace la pregunta con los nombres tal como están escritos.
4. "List symmetric families" contiene "symmetric famil", una de las expresiones de la rama atonal (línea 597). "List unnamed modal families" no contiene ninguna: la que necesitaría es "unnamed famil" (línea 606), y la palabra "modal" se interpone. Además, no nombra ninguna familia ni ningún modo que la skill conozca, así que recibe la respuesta por defecto, los modos de la escala mayor (líneas 202-207).

</details>

## Puntos clave

- Una skill sin teoría musical propia es tan correcta como su catálogo: comprueba el catálogo, modo por modo.
- "El modo k" es una afirmación que un programa puede comprobar: el primer modo de la familia, tocado desde el grado k.
- Una fórmula numerada por posición es correcta para una escala de siete notas en orden ascendente; para los demás tamaños, solo si las notas toman las letras en orden, lo que es raro.
- En YAML, pon entre comillas cualquier valor que contenga un espacio seguido de `#`.
- Una búsqueda que se queda con la primera coincidencia necesita nombres que aparezcan una sola vez.

## Fuentes

- GuitarAlchemist/ga en [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `Common/GA.Business.ML/Agents/Skills/ModesSkill.cs`, `Common/GA.Business.Config/Modes.yaml`, `Common/GA.Business.Config/ModesConfig.fs`.
- GuitarAlchemist/ga en [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/tree/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a): `SemanticIntentRouter.cs` con su respaldo por palabras clave.
- El programa del curso: `code/ga-ai/GaAi/Lesson26.cs`.
